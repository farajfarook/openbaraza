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
import java.lang.NumberFormatException;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.utils.BLogHandle;

public class BSMSCommands {
	Logger log = Logger.getLogger(BSMSCommands.class.getName());
    BSMSEng smseng;
	BSMSend smsend;
	BSMSMessage smsmsg;
	BDB db;

	// Port status message
    private final int OK = 1;
	private String typeStore = "SM";

	private int messages = 0;
	private int messageMAX = 0;

    public BSMSCommands(BSMSEng smseng, BSMSend smsend, BDB db, BLogHandle logHandle) {
		this.smseng = smseng;
		this.smsend = smsend;
		this.db = db;
		smsmsg =  new BSMSMessage(logHandle);
		logHandle.config(log);
  	}

	public boolean initPhone(String smsStore, String smsNMI) {
		// Check if SMS starts
		smsend.sendMessage("AT\r");
		smseng.getMessage();
		log.info("SMS System started");

		// name of manufacturer 
		smsend.sendMessage("AT+CGMI\r");
		log.info("Manufacturer : " + smseng.getMessage());

		// model number 
		smsend.sendMessage("AT+CGMM\r");
		log.info("Model : " + smseng.getMessage());

		// Set the SIM for storage
		if(smsStore != null) typeStore = smsStore;
		smsend.sendMessage("AT+CPMS=\"" + typeStore + "\"\r");
		smseng.getMessage();

		// Check for valid NMI configuration
		smsend.sendMessage("AT+CNMI=?\r");
		String nmi = smseng.getMessage();
		log.info("NMI? : " + nmi);

		nmi = nmi.replace(")", ":").replace("(", "");
		String nmis[] = nmi.split(":");
		nmi = "";
		int i = 0;
		for(String nis : nmis) {
			if(i==1) nmi += nis.trim().substring(nis.trim().length() - 1);
			else if((i>1) && (i < 6)) nmi += "," + nis.trim().substring(nis.trim().length() - 1);
			i++;
		}
		if(smsNMI != null) nmi = smsNMI;
		log.info("NMI : " + nmi);

		// Configure NMI
		smsend.sendMessage("AT+CNMI=" + nmi + "\r");	
		smseng.getMessage();

		// Tell phone to be in text mode 1, PDU Mode 0
		smsend.sendMessage("AT+CMGF=0\r");
		smseng.getMessage();

		boolean phoneReady = false;
		if(smseng.getPortStatus() == OK) phoneReady = true;
		
		return phoneReady;
	}

	public boolean readSMS(int msgCount, int msgMAX) {
		boolean isreadsms = true;
		smsend.sendMessage("AT\r");
		smseng.getMessage();

		smseng.bufferReset();
		smsend.sendMessage("AT+CMGL=4\r");						// Read all messages
		String msgList = smseng.getMessage();
		log.info("THE MSG LIST " + msgList);

		if(msgList.trim().length()==0) {
			log.info("Message Read error.");
			isreadsms = false;
		}

		String msgnos[] = msgList.split("\n");
		for(String msgno : msgnos) {
			msgno = msgno.replace("+CMGL: ", "");
			if(msgno.trim().length()>4) {
				msgno = msgno.substring(0, msgno.indexOf(",")).trim();
				log.info("Read message : " + msgno);

				readSMS(Integer.valueOf(msgno));	// Read a given phone message
			}
		}

		return isreadsms;
	}

	public void readSMS(int i) {
		smseng.bufferReset();
		smseng.setMessageNum(i);
		smsend.sendMessage("AT\r");
		smseng.getMessage();
		smsend.sendMessage("AT+CMGR=" + String.valueOf(i) + "\r");	// Read a given phone message

		String msg = smseng.getSMSMessage();
		if(smseng.checkMessage() && (smseng.getPortStatus() == OK)) {
			smsmsg.readsms(db, i, msg);
		}
	}

	public void CheckStorage() {
		smsend.sendMessage("AT\r");
		smseng.getMessage();

		smsend.sendMessage("AT+CPMS=?\r");
		smseng.getMessage();

		smsend.sendMessage("AT+CPMS=\"" + typeStore + "\"\r"); 		// Tell phone to use the SIM for SMS storage
		String mynum = smseng.getMessage();
		log.fine("MESSAGE : " + mynum);
	
		mynum = mynum.replaceAll("CPMS: ", ",");
		String val[] = mynum.split(",");
		if(val.length > 2) {
			try {
				messages = Integer.valueOf(val[1]);
				messageMAX = Integer.valueOf(val[2]);
			} catch(NumberFormatException ex) {
				log.severe("ERROR NumberFormatException : " + ex);
			}

			log.info("Messages in SIM : " + messages + ", Last Store Location : " + messageMAX);
		}

		// Tell phone to be in text mode 1, PDU Mode 0
		smsend.sendMessage("AT+CMGF=0\r");
		smseng.getMessage();
	}

	// Delete the message and update database
	public void delSMS(BDB db) {
		String mysql = "SELECT sms_id, sms_trans_id, sms_deleted FROM sms_trans ";
		mysql += "WHERE (sms_deleted = false)";
		log.fine(mysql);

		BQuery rs = new BQuery(db, mysql);
		while(rs.moveNext()) {
			smsend.sendMessage("AT\r");
			smsend.sendMessage("AT+CMGD=" + rs.getString("sms_id") + "\r");
			smseng.getMessage();

			rs.recEdit();
			rs.updateField("sms_deleted", "true");
			rs.recSave();
		}
		rs.close();
	}

	public int getMessagesList() { return messages; }
	public int getMessageMAX() { return messageMAX; }

	public void phoneCheck() {
		// Check AT
		smsend.sendMessage("AT\r");
		log.info("AT : " + smseng.getMessage());

		// Check the device manufacturer
		smsend.sendMessage("AT+CGMI\r");
		log.info("device manufacturer : " + smseng.getMessage());

		// model number 
		smsend.sendMessage("AT+CGMM\r");
		log.info("model number : " + smseng.getMessage());

		// IMEI number (International Mobile Equipment Identity) 
		smsend.sendMessage("AT+CGSN\r");
		log.info("IMEI number : " + smseng.getMessage());

		// software version 
		smsend.sendMessage("AT+CGMR\r");
		log.info("software version : " + smseng.getMessage());

		// mobile phone activity status 
		smsend.sendMessage("AT+CPAS\r");
		log.info("phone activity status : " + smseng.getMessage());

		// mobile network registration status 
		smsend.sendMessage("AT+CREG\r");
		log.info("network registration status : " + smseng.getMessage());

		// radio signal strength 
		smsend.sendMessage("AT+CSQ\r");
		log.info("radio signal strength : " + smseng.getMessage());

		// battery charge level and battery charging status 
		smsend.sendMessage("AT+CBC\r");
		log.info("battery charge level : " + smseng.getMessage());

		// check whether mobile-originated SMS messages are supported.
		smsend.sendMessage("AT+CSMS?\r");
		log.info("mobile-originated SMS messages : " + smseng.getMessage());

		// Perform test operations to check whether Send Message is supported.
		smsend.sendMessage("AT+CMGS=?\r");
		log.info("check whether Send Message : " + smseng.getMessage());

		// Perform test operations to check whether Send Message from Storage are supported.
		smsend.sendMessage("AT+CMSS=?\r");
		log.info("check whether Send Message from Storage : " + smseng.getMessage());

		// Check Write Message to Memory
		smsend.sendMessage("AT+CMGW=?\r");
		log.info("Write Message to Memory : " + smseng.getMessage());

		// Check Delete memory
		smsend.sendMessage("AT+CMGD=?\r");
		log.info("Delete memory CMGD : " + smseng.getMessage());

		smsend.sendMessage("AT+CMSS=?\r");
		log.info("Delete memory CMSS : " + smseng.getMessage());

		// Check Select Message Service to check whether mobile-terminated SMS messages are supported.
		smsend.sendMessage("AT+CSMS=?\r"); 
		log.info("mobile-terminated SMS messages : " + smseng.getMessage());

		// Perform test operations to check whether New Message Indications to TE
		smsend.sendMessage("AT+CNMI?\r");
		log.info("New Message Indications : " + smseng.getMessage());

		// Check Read Message
		smsend.sendMessage("AT+CMGR=?\r");
		log.info("Read Message : " + smseng.getMessage());

		// Operational mode
		smsend.sendMessage("AT+CMGF=?\r");
		log.info("Operational mode : " + smseng.getMessage());

		// Finding available storage
		smsend.sendMessage("AT+CPMS=?\r");
		log.info("available storage : " + smseng.getMessage());

		// Check sms list
		smsend.sendMessage("AT+CMGL=?\r");
		log.info("sms list : " + smseng.getMessage());
	}

}

