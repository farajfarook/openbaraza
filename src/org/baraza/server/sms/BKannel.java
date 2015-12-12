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

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;
import java.net.URL;
import java.net.MalformedURLException;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BElement;
import org.baraza.server.comm.BComm;
import org.baraza.utils.BLogHandle;

public class BKannel {
	Logger log = Logger.getLogger(BKannel.class.getName());

	BLogHandle logHandle;
	List<BComm> qcomms;

	String url, username, password;

	BDB db = null; 
	BElement root = null;
	int processdelay = 10000;
	boolean executing = false;

	public BKannel(BDB db, BElement root, BLogHandle logHandle) {
		this.db = db;
		this.root = root;
		this.logHandle = logHandle;
		logHandle.config(log);

		qcomms = new ArrayList<BComm>();
		for(BElement node : root.getElements()) {
			if(node.getName().equals("COMM"))
				qcomms.add(new BComm(db, node, logHandle));
		}

		processdelay = Integer.valueOf(root.getAttribute("duration", "10000"));
		url = root.getAttribute("url", "http://localhost/kannel/");
		username = root.getAttribute("username", "root");
		password = root.getAttribute("password", "invent");

		log.info("Starting Kannel SMS Server.");
	}

	public int getDelay() { return processdelay; }

	public int process() {
		log.info("Kannel SMS Processing...");
		executing = true;

		boolean dbValid = db.isValid();
		if(dbValid) {
			for(BComm qcomm : qcomms) qcomm.process();
			sendMessage();
		} else {
			db.reconnect();
		}

		executing = false;
		return processdelay;
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

	public boolean sendMessage(String number, String message) {
		log.info(number + " : " + message);
		if(message == null) return true;
		if(message.equals("null")) return true;
		if(number == null) return true;
		if(number.equals("null")) return true;

		boolean msgsent = false;

		message = message.replace("%", "%25");
		message = message.replace("&", "%26");
		message = message.replace("+", "%2B");
		message = message.replace("#", "%23");
		message = message.replace("=", "%3D");
		message = message.replace("^", "%5E");
		message = message.replace("~", "%7E");
		message = message.replace(" ", "+");
		message = message.replace('@', (char)161);

		String murl = url + "?username=" + username + "&password=" + password + "&to=" + number;
		murl += "&text=" + message;
		System.out.println(murl);

		try {
			URL kurl = new URL(murl);
			BufferedReader in = new BufferedReader(new InputStreamReader(kurl.openStream()));

			String inputLine;
			while ((inputLine = in.readLine()) != null) {
				if(inputLine.trim().equals("0: Accepted for delivery")) msgsent = true;
				else if(inputLine.trim().equals("3: Queued for later delivery")) msgsent = true;

				System.out.println(inputLine);
			}
		} catch(MalformedURLException ex) {
			log.severe("URL Malformed Exception : " + ex);
		} catch(IOException ex) {
			log.severe("IO Error : " + ex);
		}

		if(msgsent) System.out.println("Message sent");
		else System.out.println("Message not sent");

		return msgsent;
	}

	public boolean isExecuting() {
		return executing;
	}

	public void close() {
		log.info("Closing Kannel SMS Server.");
	}
}

