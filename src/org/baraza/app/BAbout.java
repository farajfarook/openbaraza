/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.app;

import javax.swing.JInternalFrame;
import javax.swing.JLabel;
import java.awt.BorderLayout;

public class BAbout extends JInternalFrame {
	private JLabel lbl;

	public BAbout(String appname) {	
		super("About Box", false, true);
		super.setLayout(new BorderLayout());

		String mystr = "<html><body><p><b>";
		mystr += appname + " - Application<br/>\n";
		mystr += "Based on Open Baraza Frame Work.<br/>\n";
		mystr += "GNU License.<br/>\n";
		mystr += "Open Baraza.<br/>\n";
		mystr += "DEW CIS Solutions Ltd<br/>\n";
		mystr += "P.O. Box 45689 - 00100<br/>\n";
		mystr += "16th Floor, View Park Towers, Utalii Lane<br/>\n";
		mystr += "Nairobi<br/>\n Kenya<br/>\n";
		mystr += "Tel : +254 - 20 - 2243097<br/>\n";
		mystr += "Email : info@openbaraza.org<br/>\n";
		mystr += "Web : <a href=\"www.openbaraza.org\">www.openbaraza.org</a><br/>\n";
		mystr += "Web : <a href=\"www.dewcis.com\">www.dewcis.com</a><br/>\n";
		mystr += "</b></p></body></html>";

		lbl = new JLabel(mystr);
		super.add(lbl, BorderLayout.CENTER);

 		// Set the default size
       	setSize();
	}

  	public void setSize() {
        super.setLocation(150, 50);
        super.setSize(400, 250);
 	}
}