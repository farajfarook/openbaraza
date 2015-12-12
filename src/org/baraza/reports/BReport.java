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
import java.net.URL;
import java.net.MalformedURLException;
import java.io.InputStream;
import java.io.IOException;

import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperPrintManager;
import net.sf.jasperreports.engine.JasperPrint;

import java.sql.Connection;
import java.util.Map;
import java.util.HashMap;

import javax.swing.JOptionPane;
import javax.swing.JPanel;
import java.awt.GridLayout;

import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.utils.BLogHandle;

public class BReport extends JPanel {
	Logger log = Logger.getLogger(BReport.class.getName());
	BLogHandle logHandle;
	BReportViewer rp;
	JasperPrint rd;

	boolean iscreated = false;
	boolean ischild = false;
	int linkkey;

	BDB db = null;
	Connection conn;
	String reportname;
	String jasperfile;
	String auditTable;
	int printcopies;
	Map<String, Object> parameters;
	String viewFilter[] = new String[2];

	public BReport(BDB db, String reportpath, String reportfile) {
		super(new GridLayout(1,0));
		this.db = db;
		conn = db.getDB();

        jasperfile = reportpath + reportfile;

		parameters = new HashMap<String, Object>();
		parameters.put("reportpath", reportpath);
		parameters.put("SUBREPORT_DIR", reportpath);

		parameters.put("orgid", db.getOrgID());
		parameters.put("orgwhere", db.getOrgWhere(null));
		parameters.put("organd", db.getOrgAnd(null));

		viewFilter[0] = null;
		viewFilter[1] = null;

		printcopies = 1;
  	}

	public BReport(BLogHandle logHandle, BDB db, BElement fielddef, String reportpath) {
		super(new GridLayout(1,0));
		this.db = db;
		conn = db.getDB();

        jasperfile = reportpath + fielddef.getAttribute("reportfile");
		reportname = fielddef.getAttribute("name", "");
		auditTable = fielddef.getAttribute("audit");

		parameters = new HashMap<String, Object>();
        parameters.put("reporttitle", reportname);
		parameters.put("reportpath", reportpath);
		parameters.put("SUBREPORT_DIR", reportpath);

		parameters.put("orgid", db.getOrgID());
		parameters.put("orgwhere", db.getOrgWhere(fielddef.getAttribute("org.table")));
		parameters.put("organd", db.getOrgAnd(fielddef.getAttribute("org.table")));

		if(fielddef.getAttribute("user") != null)
			parameters.put(fielddef.getAttribute("user"), db.getUserID());

		ischild = false;
		linkkey = 0;
        if(!fielddef.getAttribute("linkkey", "").equals("")) {
			ischild = true;
			linkkey = Integer.valueOf(fielddef.getAttribute("linkkey")).intValue();
		}

		iscreated = false;
		if(fielddef.getAttribute("filtered", "").equals("true")) ischild = true;

		if(fielddef.getAttribute("viewfilter") != null) {
			String viewF[] = fielddef.getAttribute("viewfilter").toLowerCase().split("=");
			if(viewF.length == 2) {
				viewFilter[0] = viewF[0];
				viewFilter[1] = viewF[1];
			} else {
				viewFilter[0] = null;
				viewFilter[1] = null;
			}
		} else {
			viewFilter[0] = null;
			viewFilter[1] = null;
		}

		printcopies = Integer.valueOf(fielddef.getAttribute("printcopies", "1")).intValue();
  	}

	public void showReport() {
		if(!ischild) {
			try {
				// Reab from http and from file
				if(jasperfile.startsWith("http")) {
            		URL url = new URL(jasperfile);
                	InputStream in = url.openStream();
					rd = JasperFillManager.fillReport(in, parameters, conn);
				} else {
					rd = JasperFillManager.fillReport(jasperfile, parameters, conn);
				}
				String keyData = "";
				if(parameters.get("filterid") != null) keyData = parameters.get("filterid").toString();

				if(iscreated) {
                    rp.loadReport(rd, keyData);
					rp.refreshPage();
				} else {
					rp = new BReportViewer(rd, db, auditTable, keyData);
					super.add(rp);
					iscreated = true;
				}
			} catch (JRException ex) {
                log.severe("Jasper Compile error : " + ex);
			} catch (MalformedURLException ex) {
				log.severe("HTML Error : " + ex);
            } catch (IOException ex) {
				log.severe("IO Error : " + ex);
            } 
		}
	}

	public boolean printReport(String filtername, String filterid) {
		boolean printed = false;
		log.fine("Filter = " + filtername + " key = " + filterid);
		parameters.put(filtername, filterid);
		try {
			// Reab from http and from file
			if(jasperfile.startsWith("http")) {
				URL url = new URL(jasperfile);
				InputStream in = url.openStream();
				rd = JasperFillManager.fillReport(in, parameters, conn);
			} else {
				rd = JasperFillManager.fillReport(jasperfile, parameters, conn);
			}
			
			for(int i=0; i<printcopies; i++) {
				JasperPrintManager.printReport(rd, false);

				if(auditTable != null) {
					String insSQL = "INSERT INTO " + auditTable + "(entity_id, ip_address, link_key) VALUES ('";
					insSQL += db.getUserID() + "', '" + db.getUserIP() + "', '" + parameters.get("filterid") + "');";
					db.executeQuery(insSQL);
				}
			}

			log.fine("Printed : " + filterid);
			printed = true;
		} catch (JRException ex) {
			log.severe("Jasper Compile error : " + ex);
		} catch (MalformedURLException ex) {
			log.severe("HTML Error : " + ex);
		} catch (IOException ex) {
			log.severe("IO Error : " + ex);
		}		

		return printed;
	}

	public void	putparams(String filtername, String filterid) {
    	parameters.put(filtername, filterid);
		log.fine("Filter = " + filtername + " key = " + filterid);
	}

	public void	putparams(Map<String, String> param) {
    	parameters.putAll(param);
		drillReport();
		log.fine("Param filter Done Filter.");
	}

	public void drillReport() {

    	try {
			// Read from http and from file
            if(jasperfile.startsWith("http")) {
            	URL url = new URL(jasperfile);
                InputStream in = url.openStream();
				rd = JasperFillManager.fillReport(in, parameters, conn);
         	} else {
				rd = JasperFillManager.fillReport(jasperfile, parameters, conn);
			}
			String keyData = "";
			if(parameters.get("filterid") != null) keyData = parameters.get("filterid").toString();

			if(iscreated) {
				rp.loadReport(rd, keyData);
            	rp.refreshPage();
			} else {
				rp = new BReportViewer(rd, db, auditTable, keyData);
				add(rp);
				rp.setVisible(false);
				rp.setVisible(true);
				iscreated = true;
			}
		} catch (JRException ex) {
        	log.severe("Jasper Compile error : " + ex);
		} catch (MalformedURLException ex) {
			log.severe("HTML Error : " + ex);
        } catch (IOException ex) {
			log.severe("IO Error : " + ex);
        } 
	}

	public String[] getViewFilter() {
		return viewFilter;
	}
}
