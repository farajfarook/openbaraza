/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server;

import java.util.logging.Logger;
import java.net.InetAddress;

import org.baraza.DB.BDB;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;

import org.baraza.server.escalation.BEscalation;
import org.baraza.server.sms.BSMS;
import org.baraza.server.sms.BKannel;
import org.baraza.server.sms.BSoapSMS;
import org.baraza.server.data.BData;
import org.baraza.server.export.BExport;
import org.baraza.server.deploy.BDeploy;
import org.baraza.server.tomcat.BTomcat;
import org.baraza.server.sqlcron.BSQLCron;
import org.baraza.reports.BReportFile;
import org.baraza.utils.BLogHandle;

public class BServerTimed extends Thread {
	Logger log = Logger.getLogger(BServerTimed.class.getName());
	boolean listening;
	String type = null;
	int delay = 2000;
	BLogHandle logHandle;

	BDB db = null;
	BElement root = null;

	BEscalation escalation = null;
	BData data = null;
	BReportFile reportFile = null;
	BExport export = null;
	BDeploy deploy = null;
	BSMS sms = null;
	BKannel kannel = null;
	BSoapSMS soapSMS = null;
	BTomcat tomcat = null;
	BSQLCron sqlcron = null;

	public BServerTimed(String configDir, BElement el, BLogHandle logHandle) {
		listening = true;
		this.logHandle = logHandle;
		logHandle.config(log);

		String ps = System.getProperty("file.separator");
		String xmlfile = configDir + el.getAttribute("path") + ps + "configs" + ps + el.getAttribute("xmlfile");

		db = new BDB(el);
		db.logConfig(logHandle);

		BXML xml = new BXML(xmlfile, false);
		root = xml.getRoot();
		type = root.getName();

		if(el.getAttribute("noaudit") == null) {
			String ipaddress = "";
			try {
				InetAddress i = InetAddress.getLocalHost();
				ipaddress = i.toString();
			} catch(java.net.UnknownHostException ex) { }

			db.setUser(ipaddress, el.getAttribute("dbusername"), type);
		}

		if(type.equals("ESCALATION")) escalation = new BEscalation(db, root, logHandle);
		if(type.equals("DATA")) data = new BData(db, root, logHandle);
		if(type.equals("EXPORT")) export = new BExport(db, root, logHandle);
		if(type.equals("DEPLOY")) deploy = new BDeploy(db, root, logHandle);
		if(type.equals("REPORTS")) reportFile = new BReportFile(db, root, logHandle);
		if(type.equals("SMS")) sms = new BSMS(db, root, logHandle);
		if(type.equals("KANNEL")) kannel = new BKannel(db, root, logHandle);
		if(type.equals("SOAPSMS")) soapSMS = new BSoapSMS(db, root, logHandle);
		if(type.equals("TOMCAT")) tomcat = new BTomcat(db, root, logHandle, configDir + el.getAttribute("path"));
		if(type.equals("SQLCRON")) sqlcron = new BSQLCron(db, root, logHandle);
	}

	public String getType() {
		return type;
	}

	public void sendMessage(String inputLine) {
		if(sms != null) sms.sendMessage(inputLine);
	}

	public String sendMessage(String number, String message, String accesscode) {
		String st = null;
		if(sms != null) st = sms.sendMessage(number, message, accesscode);

		return st;
	}

	public void run() {
		while (listening) {

			if(escalation != null) {
				if(!escalation.isExecuting()) delay = escalation.process();
			}
			if(data != null) {
				if(!data.isExecuting()) delay = data.process();
			}
			if(kannel != null) {
				if(!kannel.isExecuting()) delay = kannel.process();
			}
			if(soapSMS != null) delay = soapSMS.process();
			
			if(export != null) delay = export.process();
			if(deploy != null) delay = deploy.process();
			if(reportFile != null) delay = reportFile.process();
			if(sqlcron != null) delay = sqlcron.process();
			if(sms != null) {
				if(!sms.isRunning()) {
					delay = sms.getDelay();
					if(!sms.isConnected()) {
						log.info("SMS System attempting a restart");
						sms = new BSMS(db, root, logHandle);
					}
				}
			}

			try {
				sleep(delay);
			} catch(InterruptedException ex) {
				log.info(type + " Servers Stopped");
			}
		}
	}

	public void close() {
		// Close the connections
		listening = false;

		if(escalation != null) escalation.close();
		if(data != null) data.close();
		if(export != null) export.close();
		if(deploy != null) deploy.close();
		if(reportFile != null) reportFile.close();
		if(sms != null) sms.close();
		if(kannel != null) kannel.close();
		if(soapSMS != null) soapSMS.close();
		if(tomcat != null) tomcat.close();
		if(sqlcron != null) sqlcron.close();

		if(db != null) db.close();

		interrupt();
	}

}
