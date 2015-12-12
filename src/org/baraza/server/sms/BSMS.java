/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.sms;

import java.util.logging.Logger;
import java.util.List;
import java.util.ArrayList;
import java.io.IOException;
import gnu.io.SerialPort;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.server.comm.BComm;
import org.baraza.utils.BLogHandle;

public class BSMS extends Thread {
	Logger log = Logger.getLogger(BSMS.class.getName());
	SerialPort port = null;
	BSMSConnection smsconn = null;
	BDB db = null;
	BSMSEng smseng = null;
	BSMSend smsend = null;
	BSMSCommands smscomm = null;
	BElement root = null;
	BLogHandle logHandle;
	List<BComm> qcomms;
	boolean listening = false;
	boolean connected = false;
	boolean readonly = false;

	public BSMS(BDB db, BElement root, BLogHandle logHandle) {
		this.db = db;
		this.root = root;
		this.logHandle = logHandle;
		logHandle.config(log);

		qcomms = new ArrayList<BComm>();
		for(BElement node : root.getElements()) {
			if(node.getName().equals("COMM"))
				qcomms.add(new BComm(db, node, logHandle));
		}

		if(root.getAttribute("readonly","false").equals("true")) readonly = true;

		int portcount = Integer.valueOf(root.getAttribute("portcount", "0"));
		int duration = Integer.valueOf(root.getAttribute("duration", "10000"));
		if(portcount == 0) {
			connected = connect(root.getAttribute("port"));
		} else {
			for(int p = 0; p <= portcount; p++) {
				if(!connected) connected = connect(root.getAttribute("port") + Integer.toString(p));
			}
		}

		if(connected) this.start();
	}

	public int getDelay() {
		int duration = Integer.valueOf(root.getAttribute("duration", "10000"));
		return duration;
	}

	public boolean connect(String commPort) {
		try {
			port = null;
			smsconn = new BSMSConnection(commPort, root.getAttribute("datarate"), logHandle);
			port = smsconn.getPort();
		} catch(IOException ex) {
			log.severe("COMM connection error : " + ex);
		} catch(RuntimeException ex) {
			log.severe("Runtime connection error : " + ex);
		} catch(Exception ex) {
			log.severe("Exception connection error : " + ex);
		}
 
		if(port != null) {
			log.info("Connected to " + commPort + ". Attempting AT");
			smsend = new BSMSend(port, logHandle);
			smseng = new BSMSEng(port, logHandle);
			smseng.start();
			smsend.sendMessage("AT\r");
			String resp = smseng.getMessage();
			smsend.sendMessage("AT\r");
			resp = smseng.getMessage();

			// Start the SMS System
			if("AT".equals(resp)) {
				connected = true;
				listening = true;
				smscomm =  new BSMSCommands(smseng, smsend, db, logHandle);
				smscomm.initPhone(root.getAttribute("store"), root.getAttribute("nmi"));
			} else {	
				smseng.close();
				smsconn.close();
				smsend.close();
				smseng = null;
			}
		}

		return connected;
	}

	public void run() {
		int duration = Integer.valueOf(root.getAttribute("duration", "10000"));

		while (listening) {
			// Check if the device exists
			int i = isActive();
			smsend.close();
			smsend = new BSMSend(port, logHandle);

			boolean dbValid = db.isValid();
			if(!dbValid) db.reconnect();
			
			if(i != smsend.OK) {
				smseng.close();
				smsconn.close();
				smsend.close();

				listening = false;
				duration = 1;
				log.severe("COMM Device Error.");
			}

			if(listening) {
				log.info("The Device is connected.");
				// Read messages
				listening = readMessages();
				
				if(listening) {
					if(dbValid) {
						// Process query SMS
						for(BComm qcomm : qcomms) qcomm.process();

						// Sent messages
						if(!readonly) sendMessage();
					}
				} else {
					duration = 1;
				}
			}

			try {
				sleep(duration);
			} catch(InterruptedException ex) { 
				if(listening) log.severe("Sleep Interrupted : " + ex);
				else log.severe("Stopping SMS Engine");
			}
		}

		close();
	}

	public boolean readMessages() {
		boolean isreadsms = true;
		if(smseng != null) {
			// delete messages stored on the database
			smscomm.CheckStorage();
			int msglist = smscomm.getMessagesList();
			int msgMAX = smscomm.getMessageMAX();
			if(msglist > 0)
				smscomm.delSMS(db);

			// read all messages and add them on the database
			smscomm.CheckStorage();
			msglist = smscomm.getMessagesList();
			msgMAX = smscomm.getMessageMAX();
			if(msglist > 0)
				isreadsms = smscomm.readSMS(msglist, msgMAX);
		}

		return isreadsms;
	}

	public void sendMessage() {
		String mysql = "SELECT sms_id, sms_number, message, folder_id, sent FROM sms ";
		mysql += "WHERE (folder_id = 0) AND (message_ready = true) AND (sent = false)";
		BQuery rs = new BQuery(db, mysql);

		while(rs.moveNext()) {
			boolean isSent = true;
			String number = rs.getString("sms_number");
			if(number == null) number = "";
			if(number.length() > 2)
				isSent = sendMessage(number.trim(),  rs.getString("message"));

			mysql = "SELECT sms_address.sms_address_id, address.mobile ";
			mysql += "FROM address INNER JOIN sms_address ON address.address_id = sms_address.address_id ";
			mysql += "WHERE (sms_address.sms_id	= " + rs.getString("sms_id") + ")";
			BQuery rsa = new BQuery(db, mysql);
			while(rsa.moveNext()) {
				number = rsa.getString("mobile");
				if(number == null) number = "";
				if(number.length() > 2)
					isSent = sendMessage(number.trim(),  rs.getString("message"));
			}
			rsa.close();

			mysql = "SELECT sms_groups.sms_groups_id, address.mobile ";
			mysql += "FROM address INNER JOIN entity_subscriptions ON address.table_id = entity_subscriptions.entity_id ";
			mysql += "INNER JOIN sms_groups ON sms_groups.entity_type_id = entity_subscriptions.entity_type_id ";
			mysql += "WHERE (address.table_name = 'entitys') AND (sms_groups.sms_id = " + rs.getString("sms_id") + ") ";
			BQuery rsg = new BQuery(db, mysql);
			while(rsg.moveNext()) {
				number = rsg.getString("mobile");
				if(number == null) number = "";
				if(number.length() > 2)
					isSent = sendMessage(number.trim(),  rs.getString("message"));
			}
			rsg.close();

			if(isSent) {
				rs.recEdit();		
				rs.updateField("sent", "true");
				rs.updateField("folder_id", "2");
				rs.recSave();
			}
		}
		rs.close();
	}

	public void sendMessage(String message) {
		String msg[] = message.split(" ");
		String mymsg = 	message.replace(msg[0].trim() + " " + msg[1].trim(), "");

		if(msg.length > 2) sendMessage(msg[1], mymsg.trim());
	}

	public boolean sendMessage(String number, String message) {
		if(message == null) return true;
		if(message.equals("null")) return true;
		if(number == null) return true;
		if(number.equals("null")) return true;

		log.info(number + " : " + message);
		return sendSMS(number, message);
	}

	public String sendMessage(String number, String message, String accesscode) {
		String st = "OK";

		if(accesscode.equals(root.getAttribute("accesscode")))
			if(!sendSMS(number, message)) st = "ERROR SENDING";
		else 
			st = "ERROR ACCESS";

		return st;
	}

	public boolean sendSMS(String msgaddr, String msg) {
		char cntrlZ = (char)26;
		char cr = (char)13;
		char lf = (char)10;
		int msglen = msg.length();
		int msgcount = (msglen -1) / 154;
		int msgno = 0;

		smseng.bufferReset();
		smsend.sendMessage("AT\r");
		smseng.getMessage();

		if(smseng.getPortStatus() != smseng.OK) {
			log.info("System not ready to send message");
		} else if(msglen < 155) {
			BSMSOut smsout = new BSMSOut(msgaddr, msg, msgno, msgcount);
			log.fine(smsout.length() + " : " + smsout.toString());

			smseng.bufferReset();
			smsend.sendMessage("AT+CMGS=" + smsout.length() + "\r");
			smsend.sendMessage(smsout.toString() + cntrlZ);
			smseng.getMessage();

			for(int j = 0; j < 5; j++) {
				try { sleep(2500); } catch(InterruptedException ex) { }
				if(smseng.getPortStatus() != smseng.OK) smseng.getMessage();
				else break;
			}
		} else {
			for(int i = 0; i <= msgcount; i++) {
				if(smseng.getPortStatus() == smseng.OK) {
					int sml = ((i+1) * 153);
					if(msglen < sml) sml = msglen;
					String submsg = msg.substring(i*153, sml);

					BSMSOut subout = new BSMSOut(msgaddr, msg.substring(i*153, sml), i, msgcount);

					log.info(i + " : " + submsg);
					log.fine(subout.length() + " : " + subout.toString().length() + " : " + subout.toString());

					smseng.bufferReset();
					smsend.sendMessage("AT\r");
					smseng.getMessage();

					smsend.sendMessage("AT+CMGS=" + subout.length() + "\r");
					smsend.sendMessage(subout.toString() + cntrlZ);
					smseng.getMessage();

					for(int j = 0; j < 5; j++) {
						try { sleep(2500); } catch(InterruptedException ex) { }
						if(smseng.getPortStatus() != smseng.OK) smseng.getMessage();
						else break;
					}
				}
			}
		}

		boolean isSent = false;
		if(smseng.getPortStatus() == smseng.OK) isSent = true;

		return isSent;
	}

	public int isActive() {
		smseng.bufferReset();
		smsend.sendMessage("AT\r");
		smseng.getMessage();

		return smsend.getPortStatus();
	}


	public boolean isRunning() {
		return listening;
	}

	public boolean isConnected() {
		return connected;
	}

	public void close() {
		// Close the connections
		listening = false;

		if(smseng != null) smseng.close();
		if(smsconn != null) smsconn.close();
		for(BComm qcomm : qcomms) qcomm.close();

		interrupt();
		connected = false;

		log.info("Closing SMS Server.");
	}
}
