/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.app;

import org.baraza.xml.BElement;
import org.baraza.DB.BDB;

import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JInternalFrame;
import javax.swing.JPasswordField;
import javax.swing.JButton;
import javax.swing.JLabel;

import java.awt.GridLayout;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

public class BPasswordChange extends JInternalFrame implements ActionListener {
	BDB db;
	String fnct;

	private JPanel panel;
	private JButton btnok, btncls;
	private JLabel lbloldpass, lblnewpass, lblconfpass;
	private JPasswordField oldpass;
	private JPasswordField newpass;
	private JPasswordField confpass;

	public BPasswordChange(BDB db, BElement root) {
		super("Change Password", false, true);

		this.db = db;
		fnct = root.getAttribute("password");

		lbloldpass = new JLabel("Old Password : ");
		lblnewpass = new JLabel("New Password : ");
		lblconfpass = new JLabel("Confirm Password : ");

		oldpass = new JPasswordField();
		newpass = new JPasswordField();
		confpass = new JPasswordField();

		btnok = new JButton("Update");
		btncls = new JButton("Clear");
		
		panel = new JPanel(new GridLayout(4, 2));
		panel.add(lbloldpass);
		panel.add(oldpass);
		panel.add(lblnewpass);
		panel.add(newpass);
		panel.add(lblconfpass);
		panel.add(confpass);
		panel.add(btnok);
		panel.add(btncls);
		
		add(panel);

 		// Set the default size
       	setSize();

		btnok.addActionListener(this);
		btncls.addActionListener(this);
	}

  	public void setSize() {
        super.setLocation(10, 10);
        super.setSize(300, 150);
 	}

    public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();
		String oldpassword = new String(oldpass.getPassword());
		String newpassword = new String(newpass.getPassword());
		String confpassword = new String(confpass.getPassword());

		// Execute the procedure
		if("Clear".equals(aKey)) {
			oldpass.setText("");
			newpass.setText("");
			confpass.setText("");
		} else if("Update".equals(aKey)) {
			if(newpassword.equals(confpassword)) {
				String mysql = "SELECT " + fnct + "('" + db.getUserID() + "', '" + oldpassword + "','";
				mysql += newpassword + "')";
				mysql = db.executeFunction(mysql);
				
				JOptionPane.showMessageDialog(panel, mysql, mysql, JOptionPane.ERROR_MESSAGE);
			} else {
				JOptionPane.showMessageDialog(panel, "Mismatch on new and confirmed password.", "Password Error.", JOptionPane.ERROR_MESSAGE);
			}
		}
	}
}
