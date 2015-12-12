/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.reports;

import java.util.logging.Logger;
import java.io.InputStream;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Map;
import java.util.HashMap;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperExportManager;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BElement;
import org.baraza.utils.BLogHandle;

public class BReportFile {
	Logger log = Logger.getLogger(BReportFile.class.getName());
	int processdelay = 10000;
	String outputPath = "";
	Map<String, Object> parameters;

	BDB db;
	BElement root;

	public BReportFile(BDB db, BLogHandle logHandle) {
		this.db = db;
		logHandle.config(log);

		outputPath = "./report.pdf";
		parameters = new HashMap<String, Object>();
	}

	public BReportFile(BDB db, BElement root, BLogHandle logHandle) {
		this.db = db;
		this.root = root;
		logHandle.config(log);

		parameters = new HashMap<String, Object>();
		parameters.put("reportpath", root.getAttribute("reportpath"));
		parameters.put("SUBREPORT_DIR", root.getAttribute("reportpath"));

		parameters.put("orgid", db.getOrgID());

		// Get the main XMl configs
		processdelay = Integer.valueOf(root.getAttribute("delay", "1")).intValue()*60*1000;
	}

	public int getDelay() {
		return processdelay;
	}

	public int process() {
		// Create the report files
		log.info("---------- Report Thread Running.");
		for(BElement el : root.getElements()) {
			boolean isPdf = true;
			if(el.getAttribute("html", "false").equals("true")) isPdf = false;
		
			if(el.getName().equals("JASPER")) {
				outputPath = root.getAttribute("output") + el.getAttribute("output");
				parameters.put("orgwhere", db.getOrgWhere(el.getAttribute("org.table")));
				parameters.put("organd", db.getOrgAnd(el.getAttribute("org.table")));

				getReport(root.getAttribute("reportpath"), el.getAttribute("reportfile"), isPdf);
			} else if(el.getName().equals("GRID")) {
				String where = "(" + el.getAttribute("marker") + " = false)";
				BQuery rs = new BQuery(db, el, where, el.getAttribute("keyfield"), false);
				while(rs.moveNext()) {
					for(BElement ell : el.getElements()) {
						parameters.put(ell.getAttribute("filtername", "filterid"), rs.getString(ell.getValue()));
						outputPath = root.getAttribute("output") + rs.getString(ell.getValue()) + ".pdf";
					}
					getReport(root.getAttribute("reportpath"), el.getAttribute("reportfile"), isPdf);
				}

				String mysql = el.getAttribute("psql", "");
				mysql += "\nUPDATE " + el.getAttribute("table") + " SET " +  el.getAttribute("marker") + " = true";
				mysql += " WHERE " +  el.getAttribute("marker") + " = false;";
				db.executeQuery(mysql);
			}
		}

		log.info("---------- Report Thread Completed.");

		return processdelay;
	}

	public void setOutput(String reportOutput) {
		outputPath = "./" + reportOutput + ".pdf";
	}

	public boolean getReport(String reportpath, String reportname, String keyfield, Map<String, String> rptParams) {
		parameters.put("reportpath", reportpath);
		parameters.put("SUBREPORT_DIR", reportpath);
		parameters.put("filterid", keyfield);

		parameters.put("orgid", db.getOrgID());
		parameters.put("orgwhere", db.getOrgWhere(null));
		parameters.put("organd", db.getOrgAnd(null));

		for(String rptParam : rptParams.keySet()) parameters.put(rptParam, rptParams.get(rptParam));

		return getReport(reportpath, reportname, true);
	}

	public boolean getReport(String reportpath, String reportname, boolean isPdf) {
		JasperPrint rd = null;
		boolean gotreport = false;
		
		try {
			if(reportpath.startsWith("http")) {
            	URL url = new URL(reportpath + reportname);
               	InputStream in = url.openStream();
				rd = JasperFillManager.fillReport(in, parameters, db.getDB());
			} else {
				rd = JasperFillManager.fillReport(reportpath + reportname, parameters,  db.getDB());
			}

			if (rd != null) {
				if(isPdf) JasperExportManager.exportReportToPdfFile(rd, outputPath);
				else JasperExportManager.exportReportToHtmlFile(rd, outputPath);
			}

			gotreport = true;
			log.info("Report generation - Done");
		} catch (JRException ex) { System.out.println("Jasper Compile error : " + ex + "\n");
		} catch (MalformedURLException ex) { System.out.println("HTML Error : " + ex + "\n");
		} catch (IOException ex) { System.out.println("IO Error : " + ex + "\n"); }

		return gotreport;
	}

	public void close() {
		// Close the connections
		db.close();
	}
}
