/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.reports;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.view.JRViewer;
import net.sf.jasperreports.engine.JasperPrint;

import org.baraza.DB.BDB;

public class BReportViewer extends JRViewer implements ActionListener {
	BDB db = null;
	String auditTable = null;
	String linkKey = null;

	public BReportViewer(JasperPrint jrPrint, BDB db, String auditTable, String keyData) throws JRException {
		super(jrPrint);

		this.db = db;
		this.auditTable = auditTable;
		linkKey = keyData;

		btnPrint.setActionCommand("PRINT");
		btnPrint.addActionListener(this);
	}

	public void loadReport(JasperPrint jrPrint, String keyData) {
		super.loadReport(jrPrint);
		linkKey = keyData;
	}

	public void refreshPage() {
		super.refreshPage();
	}

	public void setPageIndex(int index) {
		super.setPageIndex(index);
	}
	
	public void btnPrintActionPerformed() {
		if(auditTable != null) {
			String insSQL = "INSERT INTO " + auditTable + "(entity_id, ip_address, link_key) VALUES ('";
			insSQL += db.getUserID() + "', '" + db.getUserIP() + "', '" + linkKey + "');";
			db.executeQuery(insSQL);
		}
	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();
		if("PRINT".equals(aKey)) btnPrintActionPerformed();
	}
}
