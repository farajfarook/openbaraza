/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.ide;

import java.awt.BorderLayout;
import java.awt.GridLayout;
import javax.swing.JLabel;
import javax.swing.JTextField;
import javax.swing.JButton;
import javax.swing.JPanel;
import javax.swing.JOptionPane;
import javax.swing.JFrame;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import org.baraza.utils.Bio;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;

public class BSetup implements ActionListener {

	JPanel panel;
	JTextField ftUserName, ftPassword;
	JLabel lbStatus;
	String ps;
	BXML xml;
	BElement root;

	public BSetup() {
		ps = System.getProperty("file.separator");
		String setupXML = "projects" + ps + "setup.xml";
		xml = new BXML(setupXML, false);
		root = xml.getRoot();

		String dbusername = root.getAttribute("dbusername");
		String dbpassword = root.getAttribute("dbpassword");

		panel = new JPanel(new GridLayout(0, 2, 2, 2));

		lbStatus = new JLabel("Baraza Setup");
		JLabel lbUserName = new JLabel("User Name : ");
		ftUserName = new JTextField(dbusername);

		JLabel lbPassword = new JLabel("Password : ");
		ftPassword = new JTextField(dbpassword);

		JButton btTest = new JButton("Test Connection");
		JButton btSave = new JButton("Save Configuration");
		JButton btDemo = new JButton("Create Demo");
		JButton btNew = new JButton("Create New");

		btTest.addActionListener(this);
		btSave.addActionListener(this);
		btDemo.addActionListener(this);
		btNew.addActionListener(this);

		panel.add(lbUserName);
		panel.add(ftUserName);
		panel.add(lbPassword);
		panel.add(ftPassword);

		panel.add(btTest);
		panel.add(btSave);
		panel.add(btDemo);
		panel.add(btNew);

		JFrame frame = new JFrame("Baraza Setup");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frame.getContentPane().add(panel, BorderLayout.CENTER);
		frame.getContentPane().add(lbStatus, BorderLayout.PAGE_END);
		frame.setLocation(200, 200);
		frame.setSize(400, 150);
		frame.setVisible(true);
	}

	public void saveConfigs() {
		root.setAttribute("dbusername", ftUserName.getText());
		root.setAttribute("dbpassword", ftPassword.getText());
		xml.saveFile();

		String configXML = "projects" + ps + "config.xml";
		BXML cfgxml = new BXML(configXML, false);
		BElement cfg = cfgxml.getRoot();
		cfg.setAttribute("dbusername", ftUserName.getText());
		cfg.setAttribute("dbpassword", ftPassword.getText());
		for(BElement cel : cfg.getElements()) {
			cel.setAttribute("dbusername", ftUserName.getText());
			cel.setAttribute("dbpassword", ftPassword.getText());
		}
		cfgxml.saveFile();

		String webXML = "..";
		if(root.getAttribute("web") == null) webXML = "webapps" + ps + root.getAttribute("path");
		webXML += ps + "META-INF" + ps + "context.xml";
		BXML webxml = new BXML(webXML, false);
		BElement web = webxml.getRoot();
		for(BElement wel : web.getElements()) {
			if("org.apache.catalina.realm.JDBCRealm".equals(wel.getAttribute("className"))) {
				wel.setAttribute("connectionName", ftUserName.getText());
				wel.setAttribute("connectionPassword", ftPassword.getText());
			}
			if("jdbc/database".equals(wel.getAttribute("name"))) {
				wel.setAttribute("username", ftUserName.getText());
				wel.setAttribute("password", ftPassword.getText());
			}
		}
		webxml.saveFile();
	}

	public String createDB(String filename) {
		String err = null;

		BDB db = new BDB(root, ftUserName.getText(), ftPassword.getText());
		if(db.getDB() != null) {
			db.executeQuery("CREATE ROLE root LOGIN;");
			db.executeQuery("DROP DATABASE " + root.getAttribute("dbname"));
			err = db.executeQuery("CREATE DATABASE " + root.getAttribute("dbname"));
		}
		db.close();

		BDB ndb = new BDB(root.getAttribute("dbclass"), root.getAttribute("newdbpath"), ftUserName.getText(), ftPassword.getText());
		if((ndb.getDB() != null) && (err == null)) {
			String ps = System.getProperty("file.separator");
			String fpath = "projects" + ps + root.getAttribute("path") + ps + "database" + ps + "setup" + ps + filename;

			Bio io = new Bio();
			String mysql = io.loadFile(fpath);
			ndb.executeQuery("CREATE LANGUAGE plpgsql;");
			err = ndb.executeQuery(mysql);
		}
		ndb.close();
	
		if(err != null) lbStatus.setText(err);
		else lbStatus.setText("Database creation successfull.");

		return err;
	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("Test Connection".equals(aKey)) {
			BDB db = new BDB(root, ftUserName.getText(), ftPassword.getText());
			if(db.getDB() == null) lbStatus.setText("Connection Error");
			else lbStatus.setText("Connection Successfull");
			db.close();
		} else if("Save Configuration".equals(aKey)) {
			saveConfigs();
			lbStatus.setText("Configurations Saved");
		} else if("Create Demo".equals(aKey)) {
			lbStatus.setText("The process will take a while to complete.");
			int n = JOptionPane.showConfirmDialog(panel, "This will delete existing database, are you sure you want to proceed?", "Demo Database", JOptionPane.YES_NO_OPTION);
			if(n == 0) createDB("demo.sql");
			else lbStatus.setText("Baraza Setup");
		} else if("Create New".equals(aKey)) {
			lbStatus.setText("The process will take a while to complete.");
			int n = JOptionPane.showConfirmDialog(panel, "This will delete existing database, are you sure you want to proceed?", "New Database", JOptionPane.YES_NO_OPTION);
			if(n == 0) createDB("setup.sql");
			else lbStatus.setText("Baraza Setup");
		}
	}

	public static void main(String args[]) {
		BSetup st = new BSetup();
	}
}

 
