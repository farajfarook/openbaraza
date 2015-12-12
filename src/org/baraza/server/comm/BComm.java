/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.comm;

import java.util.logging.Logger;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.utils.BNumberFormat;
import org.baraza.utils.BLogHandle;

public class BComm {
	Logger log = Logger.getLogger(BComm.class.getName());
	BElement node;
	BDB db = null;
	BDB rdb = null;
	boolean newDB = false;
	String orgID = null;

	public BComm(BDB db, BElement node, BLogHandle logHandle) {
		this.node = node;
		this.db = db;
		this.orgID = node.getAttribute("orgid");
		
		logHandle.config(log);
	}

	public void process() {
		newDB = false;
		if(node.getAttribute("dbpath") == null) rdb = db;
		else {newDB = true; rdb = new BDB(node);}
		
		// validate the databases then run process
		if(!db.isValid()) {
			db.reconnect();
		} else if(!rdb.isValid()) {
			rdb.reconnect();
		} else {
			for(BElement el : node.getElements()) {
				if(el.getName().equals("PROCESS")) process(el);
			}
		}
		
		// Close the DB
		close();
	}

	public void process(BElement el) {
		String mysql = el.getAttribute("sql");
		String where = el.getAttribute("where");
		String orderby = el.getAttribute("orderby");
		String update = el.getAttribute("update");
		String errorSQL = el.getAttribute("error");
		
		if(where != null) mysql += " WHERE " + where;
		if(orderby != null) mysql += " ORDER BY " + orderby;
		
		BQuery rs = new BQuery(rdb, mysql);
		while(rs.moveNext()) {
			String smsNumber = rs.readField(2);
			if(smsNumber == null) smsNumber = "";
			smsNumber = smsNumber.replace(" ", "").replace("-", "").replace(",", "").trim();
			int sNl = smsNumber.length();

			if((sNl==10) && smsNumber.startsWith("0")) smsNumber = "254" + smsNumber.substring(1, 10);
			BNumberFormat nf = new BNumberFormat();
			nf.getNumber(smsNumber);
			sNl = smsNumber.length();
			
			String msg = rs.readField(3);
			if(msg == null) msg = "";
			else msg = msg.replace("'", "''");
			
System.out.println("BASE 3040 : " + sNl + " : " + nf.getError());
			
			// Insert the SMS
			if((sNl == 12) && (nf.getError() == 0)) {
				mysql = "INSERT INTO sms (message_ready, folder_id, org_id, link_id, sms_number, message) VALUES (";
				mysql += "true, 0, " + orgID + ", ";
				mysql += rs.readField(1) + ", '" + smsNumber + "',  '" + msg + "');";
				db.executeQuery(mysql);				
System.out.println("BASE 3050 : " + mysql);
	
				// Update SMS
				mysql = update + rs.readField(1);
				rdb.executeQuery(mysql);
System.out.println("BASE 3070 : " + mysql);
			} else {
				// Update error SMS
				mysql = errorSQL + rs.readField(1);
				rdb.executeQuery(mysql);

System.out.println("BASE 4070 : SMS Import error : " + smsNumber);			
			}
		}

		rs.close();
	}

	public void close() {
		if(newDB) { rdb.close(); rdb = null; }
	}

}
