/**
 * @author      Dennis W. Gichangi <dennis.dichangi@dewcis.com>
 * @version     2011.03.29
 * @since       1.6
 * website		www.dewcis.com
 * The contents of this file are subject to the Dew CIS Solutions License
 * The file should only be shared to OpenBravo.
 */
package org.baraza.com;

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
import java.awt.BorderLayout;
import java.awt.Toolkit;
import java.awt.EventQueue;
import javax.swing.JFrame;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.reports.BReportViewer;

public class BScreenReports extends Thread {
	Logger log = Logger.getLogger(BScreenReports.class.getName());
	BReportViewer rp;
	JasperPrint rd;

	int lastPage = 0;
	int currentPage = 0;
	int currentCycle = 0;
	int pageDelay = 1000;
	int pageRefresh = 10;

	String keyData = null;
	public boolean isCreated = false;

	public static void main(String args[]) {
		if(args.length == 1) {
			BScreenReports sr = new BScreenReports(args[0]);
			sr.start();

			Toolkit tk = Toolkit.getDefaultToolkit();
			JFrame frame = new JFrame("Baraza Report Screen");
			frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

			if(sr.isCreated) frame.getContentPane().add(sr.getReportPanel(), BorderLayout.CENTER);

			frame.setBounds(0, 0, tk.getScreenSize().width + 10, tk.getScreenSize().height + 10);
			frame.setVisible(true);

		} else {
			System.out.println("USAGE : java -cp baraza.jar org.baraza.com.BScreenReports screenreports.xml");
		}
	}

	public void run() {
		boolean isRunning = true;

		while(isRunning) {
			try {
				Thread.sleep(pageDelay);
			} catch (InterruptedException e) {
				System.out.println("I wasn't done");
			}
			turnPage();
		}
    }

	public BScreenReports(String xmlFile) {
		BXML xml = new BXML(xmlFile, false);
		BElement root = xml.getRoot();
		BDB db = new BDB(root);
		Connection conn = db.getDB();
		String jasperfile = root.getAttribute("reportpath") + root.getAttribute("report");
		if(root.getAttribute("pagedelay") != null) pageDelay = Integer.parseInt(root.getAttribute("pagedelay"));
		if(root.getAttribute("pagerefresh") != null) pageRefresh = Integer.parseInt(root.getAttribute("pagerefresh"));
		if(root.getAttribute("keydata") != null) keyData = root.getAttribute("keydata");
		
		Map<String, Object> parameters = new HashMap<String, Object>();
		parameters.put("reportpath", root.getAttribute("reportpath"));
		parameters.put("SUBREPORT_DIR", root.getAttribute("reportpath"));

		String auditTable = null;

		try {
			// Reab from http and from file
			if(jasperfile.startsWith("http")) {
        		URL url = new URL(jasperfile);
            	InputStream in = url.openStream();
				rd = JasperFillManager.fillReport(in, parameters, conn);
				if(rd.getPages() != null) lastPage = rd.getPages().size();
			} else {
				rd = JasperFillManager.fillReport(jasperfile, parameters, db.getDB());
				if(rd.getPages() != null) lastPage = rd.getPages().size();
			}

			rp = new BReportViewer(rd, db, auditTable, keyData);
			isCreated = true;
		} catch (JRException ex) {
            log.severe("Jasper Compile error : " + ex);
		} catch (MalformedURLException ex) {
			log.severe("HTML Error : " + ex);
        } catch (IOException ex) {
			log.severe("IO Error : " + ex);
        }
	}

	public BReportViewer getReportPanel() {
		return rp;
	}

	public void turnPage() {
		if(currentPage < lastPage) {
			currentPage++;
		} else {
			currentPage = 0;
			currentCycle++;
		}

		if(pageRefresh == currentCycle) {
			currentCycle = 0;
			rp.loadReport(rd, keyData);
		}

		rp.setPageIndex(currentPage);
		rp.refreshPage();
	}

}
