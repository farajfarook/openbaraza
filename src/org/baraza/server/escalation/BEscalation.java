/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.escalation;

import java.util.logging.Logger;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.text.SimpleDateFormat;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.reports.BReportFile;
import org.baraza.server.mail.BMail;
import org.baraza.utils.BLogHandle;

public class BEscalation {
	Logger log = Logger.getLogger(BEscalation.class.getName());
	BDB db;
	BElement root;
	BLogHandle logHandle;
	String testemail;
	String title = "";

	boolean executing = false;
	boolean runserver = true;
	int processdelay = 10000;

	public BEscalation(BDB db, BElement root, BLogHandle logHandle) {
		this.db = db;
		this.root = root;
		this.logHandle = logHandle;
		logHandle.config(log);

		// Get the main XMl configs
		testemail = root.getAttribute("testemail");
		title = root.getAttribute("title", "");
		processdelay = Integer.valueOf(root.getAttribute("processdelay", "2")).intValue()*60*1000;
	}

	public int getDelay() {
		return processdelay;
	}

	public int process() {
		// Create the mail class
		BMail mail = new BMail(root, logHandle);
		if(mail.getActive()) task(mail);
		mail.close();

		return processdelay;
	}

	public void task(BMail mail) {
		log.info("---------- Escalation Client Run for : " + title);

		executing = true;

		for(BElement ell : root.getElements()) {
			String keyfield = ell.getAttribute("keyfield");
			String colNames = keyfield;
			for(BElement el : ell.getElements()) {
				String basetable = el.getAttribute("basetable");
				String function = el.getAttribute("function");
				if(function == null) function = el.getAttribute("fnct");

				colNames += ", ";
				if(basetable != null) colNames += basetable + "." + el.getValue();
				else if(function != null) colNames += "(" + function + ")";
				else colNames += el.getValue();
				
				if(el.getName().equals("ADDRESS")) colNames += " as emailaddress";
				else if(el.getName().equals("SUBJECT")) colNames += " as emailsubject";
				else if(function != null) colNames += " as " + el.getValue();
			}
			String mysql = "SELECT " + colNames + " FROM " + ell.getAttribute("table") + " ";
			if(ell.getAttribute("where") != null) mysql += " WHERE " + ell.getAttribute("where");
			log.info(mysql);

			BQuery rs = new BQuery(db, mysql);
			while(rs.moveNext()) {
				Map<String, String> params = new HashMap<String, String>();
				Map<String, String> rptParams = new HashMap<String, String>();
				Map<String, String> headers = new HashMap<String, String>();
				Map<String, String> reports = new HashMap<String, String>();

				String subject = rs.getString("emailsubject");
				String msg = "<HTML>\n<HEAD></HEAD>\n<BODY>\n";
				
				for(BElement el : ell.getElements()) {
					if(el.getName().equals("FIELD")) {
						if(rs.getString(el.getValue())!=null)
							msg += "<p>" + rs.getString(el.getValue()) + "</p>\n";
					} else if(el.getName().equals("BODYFIELD")) {
						String reference = el.getAttribute("reference");
						if(rs.getString(el.getValue())!=null)
							params.put(reference, rs.getString(el.getValue()));
						else
							params.put(reference, "");
					} else if(el.getName().equals("HEADER")) {
						String reference = el.getAttribute("reference");
						if(rs.getString(el.getValue())!=null)
							headers.put(reference, rs.getString(el.getValue()));
					} else if(el.getName().equals("PARAM")) {
						if(rs.getString(el.getValue())!=null)
							rptParams.put(el.getValue(), rs.getString(el.getValue()));
					} else if(el.getName().equals("REPORT")) {
						if(rs.getString(el.getValue())!=null)
							reports.put(el.getValue(), rs.getString(el.getValue()));
					}
				}
				msg += "\n</BODY>\n</HTML>\n";

				for (String key : params.keySet()) {
					log.finest(key + " : " + params.get(key));
					msg = msg.replace(key, params.get(key));
					subject = subject.replace(key, params.get(key));
				}

				String emailaddress = rs.getString("emailaddress");
				log.info("To : " + emailaddress + "\nSubject : " + subject);
				if(testemail != null) emailaddress = testemail;

				boolean gotreport = false;
				if(ell.getAttribute("attachment") != null) {
					BReportFile rf =  new BReportFile(db, logHandle);
					gotreport = rf.getReport(root.getAttribute("reportpath"), ell.getAttribute("attachment"), rs.getString(keyfield), rptParams);
				}

				for(String report : reports.keySet()) {
					String reportFile = reports.get(report);
					BReportFile rf =  new BReportFile(db, logHandle);
					rf.setOutput(report);
					rf.getReport(root.getAttribute("reportpath"), reportFile, rs.getString(keyfield), rptParams);
				}

				if(emailaddress != null) {
					if(emailaddress.indexOf("@")>1)
						mail.sendMail(emailaddress, subject, msg, gotreport, headers, reports);
				}
										
				/* Close the problem log */
				String functable = root.getAttribute("functable");
				String actioncount = ell.getAttribute("actioncount");
				if(actioncount == null) {
					mysql = "SELECT " + ell.getAttribute("action") + " ('" + rs.getString(keyfield) + "')";
				} else {
					mysql = "SELECT " + ell.getAttribute("action") + " ('" + actioncount;
					mysql += "', '" + rs.getString(keyfield) + "')";
				}

				if(functable != null) mysql += " FROM " + functable;
				db.executeQuery(mysql);
				if(db.getDBType() == 2) db.executeQuery("COMMIT");
			}
			rs.close();
		}

		executing = false;
	}

	public String fmtdate(Date dt) {
		SimpleDateFormat sdf = new SimpleDateFormat("dd MMMM yyyy, hh:mm a");
		return sdf.format(dt);
	}

	public boolean isExecuting() {
		return executing;
	}

	public void close() {
		// Close the connections
		db.close();
	}

}
