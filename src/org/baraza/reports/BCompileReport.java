/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.reports;

import net.sf.jasperreports.engine.JasperCompileManager;
import net.sf.jasperreports.engine.JRException;

public class BCompileReport {

	public BCompileReport(String filename) {
		try {
			JasperCompileManager.compileReportToFile(filename);
			System.out.println("report compiled : " + filename);  
		} catch (JRException ex) {
			System.out.println("Jasper Compile error : " + filename);
			ex.printStackTrace(System.out);
		}
	}
}
