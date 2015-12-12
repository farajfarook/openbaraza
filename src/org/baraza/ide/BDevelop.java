/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.ide;

import java.util.logging.Logger;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;

import java.awt.GridLayout;
import java.awt.BorderLayout;

import javax.swing.JInternalFrame;
import javax.swing.JTabbedPane;
import javax.swing.JPanel;
import javax.swing.JLabel;
import javax.swing.JTextField;
import javax.swing.JTextArea;
import javax.swing.JCheckBox;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JPasswordField;

import javax.swing.tree.DefaultTreeModel;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import org.baraza.xml.*;
import org.baraza.DB.*;
import org.baraza.app.*;
import org.baraza.utils.Bio;
import org.baraza.swing.*;
import org.baraza.utils.BLogHandle;

public class BDevelop extends JInternalFrame implements ActionListener {
	Logger log = Logger.getLogger(BDevelop.class.getName());
	JTabbedPane tabbedPane;
	JTabbedPane queryTabs;
	JPanel panel;
	JPanel loginPanel = null;

	BDB db = null;
	BElement root;
	BElement desk = null;
	BTreeNode top, node;
	DefaultTreeModel treemodel;
	String configDir;
	String[] dbStr = {"project", "path", "dbname", "dbpath", "xmlfile", "dbusername", "encryption"};
	
	BEdit edit;
	BQBuilder qbuilder;
	BxmlViewer viewer;
	BLogHandle logHandle;

	JLabel[] label;
	JTextField[] textField;
	JLabel ldbClass, lUserName, lPassword, lDisable, lNoAudit, lOrg;
	JTextField ftUserName;
	JPasswordField pwPassword;
	JComboBox<String> dbClassList;
	JCheckBox cbDisable, cbNoAudit, cbOrg;
	JButton btLogin, btEdit, btOkay, btCancel, btCreateDB, btDropDB, btSetup, btDemo;

	public BDevelop(BElement root, BTreeNode top, DefaultTreeModel treemodel, String configDir, BLogHandle logHandle) {
		super("Create a new Project", false, true);
		
		this.root = root;
		this.top = top;
		this.treemodel = treemodel;
		this.configDir = configDir;
		this.logHandle = logHandle;
		logHandle.config(log);

		makeNodePanel();
	}

	public BDevelop(BElement desk, BElement root, BTreeNode node, DefaultTreeModel treemodel, String configDir, BLogHandle logHandle) {
		super(desk.getValue(), true, true, true, true);
	
		this.desk = desk;
		this.root = root;
		this.node = node;
		this.treemodel = treemodel;
		this.configDir = configDir;
		this.logHandle = logHandle;
		logHandle.config(log);

		String dbpassword = desk.getAttribute("dbpassword");
		String dbusername = desk.getAttribute("dbusername");
		makeLogin(dbusername, dbpassword);
	}

	public void makeNodePanel() {
        panel = new JPanel(new GridLayout(0, 2, 2, 2));

		String[] dbClasses = {"org.postgresql.Driver", "org.apache.derby.jdbc.EmbeddedDriver", "org.apache.derby.jdbc.ClientDriver", "oracle.jdbc.driver.OracleDriver", "org.hsqldb.jdbc.JDBCDriver", "com.mysql.jdbc.Driver", "sun.jdbc.odbc.JdbcOdbcDriver"};	
		ldbClass = new JLabel("  Database Class :");
		dbClassList = new JComboBox<String>(dbClasses);
		dbClassList.setEditable(true);
		panel.add(ldbClass);
		panel.add(dbClassList);

		String[] str = {"Project Name", "Project Path", "Database Name", "Database Path", "XML File", "User Name", "Encryption"};
        label = new JLabel[str.length];
        textField = new JTextField[str.length];
        for(int i = 0; i < str.length; i++) {
            label[i] = new JLabel("  " + str[i] + " :");
            textField[i] = new JTextField(50);
            panel.add(label[i]);
            panel.add(textField[i]);

			if(desk != null) {
				textField[i].setText(desk.getAttribute(dbStr[i], ""));
				textField[i].setCaretPosition(0);
			}
        }
		textField[0].setActionCommand("Project Name");
		textField[0].addActionListener(this);
		if(desk != null) {
			textField[0].setText(desk.getValue());
			dbClassList.setSelectedItem(desk.getAttribute("dbclass", ""));
		}

		lPassword = new JLabel("  Password : ");
		pwPassword = new JPasswordField(10);
		if(desk != null) pwPassword.setText(desk.getAttribute("dbpassword", ""));
		panel.add(lPassword);
		panel.add(pwPassword);

		lDisable = new JLabel("  Disable : ");
		cbDisable = new JCheckBox();
		cbDisable.setSelected(false);
		panel.add(lDisable);
		panel.add(cbDisable);

		lNoAudit = new JLabel("  No Audit : ");
		cbNoAudit = new JCheckBox();
		cbNoAudit.setSelected(false);
		panel.add(lNoAudit);
		panel.add(cbNoAudit);

		lOrg = new JLabel("  Org : ");
		cbOrg = new JCheckBox();
		cbOrg.setSelected(false);
		panel.add(lOrg);
		panel.add(cbOrg);

		if(desk != null) {
			if(desk.getAttribute("disable", "false").equals("true")) cbDisable.setSelected(true);
			if(desk.getAttribute("noaudit", "false").equals("true")) cbNoAudit.setSelected(true);
			if(desk.getAttribute("org") != null) cbOrg.setSelected(true);
		}

		btSetup = new JButton("New Setup");
		panel.add(btSetup);
		btSetup.addActionListener(this);
		btDemo = new JButton("Demo Setup");
		panel.add(btDemo);
		btDemo.addActionListener(this);

		btCreateDB = new JButton("Create Database");
		btCreateDB.addActionListener(this);
		panel.add(btCreateDB);
		btDropDB = new JButton("Drop Database");
		btDropDB.addActionListener(this);
		panel.add(btDropDB);

		btCancel = new JButton("Template Database");
		panel.add(btCancel);
		btCancel.addActionListener(this);
		btOkay = new JButton("Save Project");
		panel.add(btOkay);
		btOkay.addActionListener(this);

		add(panel);
		setSize(100, 100, 500, 400);
	}

	public void makeLogin(String dbusername, String dbpassword) {
		loginPanel = new JPanel(new GridLayout(1, 7, 2, 2));

		lUserName = new JLabel("User Name : "); 
		loginPanel.add(lUserName);
		ftUserName = new JTextField(25);
		if(dbusername != null) ftUserName.setText(dbusername);
		loginPanel.add(ftUserName);

		lPassword = new JLabel("Password : ");
		loginPanel.add(lPassword);
		if(dbpassword == null) pwPassword = new JPasswordField(10);
		else pwPassword = new JPasswordField(dbpassword, 10);
		loginPanel.add(pwPassword);
		
		btLogin = new JButton("Login");
		btLogin.addActionListener(this);
		loginPanel.add(btLogin);

		btEdit = new JButton("Edit");
		btEdit.addActionListener(this);
		loginPanel.add(btEdit);

		add(loginPanel);
		setSize(100, 100, 700, 55);
	}

	public void makeDesk(String dbusername, String dbpassword) {
		db = new BDB(desk, dbusername, dbpassword);
		
		if(db.getDB() == null) {
			log.severe("Database Login in error");
			if(loginPanel == null) makeLogin("", "");
		} else {
			db.logConfig(logHandle);
			db.setUser("127.0.0.1", dbusername);

			if(loginPanel != null) remove(loginPanel);
			makeDeskItems();
		}
	}

	public void makeDeskItems() {
		String ps = System.getProperty("file.separator");
		String dbDirName = configDir + desk.getAttribute("path") + ps + "database" + ps;
		String configFile = configDir + desk.getAttribute("path") + ps + "configs" + ps + desk.getAttribute("xmlfile");
		String reportDir = configDir + desk.getAttribute("path") + ps + "reports" + ps;

		tabbedPane = new JTabbedPane(JTabbedPane.TOP);
		queryTabs = new JTabbedPane();
		qbuilder =  new BQBuilder(logHandle, db, reportDir);
		viewer = new BxmlViewer(logHandle, db, configFile, desk.getValue());

		tabbedPane.add("Query Builder", queryTabs);
		tabbedPane.add("XML Viewer", viewer);
		queryTabs.add("Query", qbuilder);

		if(!dbDirName.startsWith("http")) {
			edit = new BEdit(dbDirName, db, logHandle);
			queryTabs.add("Database Files", edit.panel);
		}

		add(tabbedPane);

		setSize(10, 10, 800, 700);
	}

	public void saveProject() {
		String ps = System.getProperty("file.separator");
		String projectName = textField[0].getText().trim();
		String path = textField[1].getText().trim();
		String xmlfile = textField[4].getText().trim();
		String mypassword = new String(pwPassword.getPassword());

		boolean isNew = false;
		if(desk == null) { 
			desk = new BElement("APP");
			isNew = true;
		}
		if(desk.getName().equals("APP")) desk.setValue(projectName);
		for(int i = 1; i < dbStr.length; i++) {
			if(textField[i].getText().length()>0)
				desk.setAttribute(dbStr[i], textField[i].getText());
		}
		desk.setAttribute("dbclass", dbClassList.getSelectedItem().toString());
		if(!"".equals(mypassword)) desk.setAttribute("dbpassword", mypassword);

		if(cbDisable.isSelected()) desk.setAttribute("disable", "true");
		else desk.delAttribute("disable");

		if(cbNoAudit.isSelected()) desk.setAttribute("noaudit", "true");
		else desk.delAttribute("noaudit");

		if(cbOrg.isSelected()) desk.setAttribute("org", "org_id");
		else desk.delAttribute("org");

		Bio fl = new Bio();
		if(isNew) {
			root.addNode(desk);
			top.add(new BTreeNode(desk, projectName));
			treemodel.reload(top);

			String projectPath = configDir +  path.toLowerCase() + ps;
			BElement newtel = new BElement("APP");
			newtel.setAttribute("name", projectName);
			BElement newtelmn = new BElement("MENU");
			newtelmn.setAttribute("name", projectName);
			newtel.addNode(newtelmn);
			fl.create(configDir, path, xmlfile, newtel.getString());
			this.dispose();
		} else {
			node.setUserObject(projectName);
			node.setKey(desk);
			treemodel.reload(node);
			
			remove(panel);
			String myusername = textField[dbStr.length-2].getText().trim();
			makeLogin(myusername, mypassword);
		}		
		fl.saveFile(configDir + "config.xml", root.getString());
	}

  	public void setSize(int x, int y, int h, int w) {
        super.setLocation(x, y);
        super.setSize(h, w);
 	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("Save Project".equals(aKey)) {
			saveProject();
		} else if("Login".equals(aKey)) {
			String mypassword = new String(pwPassword.getPassword());
			makeDesk(ftUserName.getText(), mypassword);
		} else if("Edit".equals(aKey)) {
			remove(loginPanel);
			makeNodePanel();
		} else if("Create Database".equals(aKey)) {
			BDB rootDB = new BDB(root);
			rootDB.logConfig(logHandle);
			String mysql = "CREATE DATABASE " + textField[2].getText();
			String err = rootDB.executeQuery(mysql);
			rootDB.close();

			if(err == null) {
				if(desk != null) {
					BDB deskDB = new BDB(desk);
					deskDB.executeQuery("CREATE LANGUAGE plpgsql;");
					deskDB.close();
				}
				log.info("Database Created");
			} else {
				log.severe(err);
			}
		} else if("Template Database".equals(aKey)) {
			BDB rootDB = new BDB(root);
			rootDB.logConfig(logHandle);
			String mysql = "CREATE DATABASE " + textField[2].getText();
			if(root.getAttribute("dbtemplate") != null) mysql += " TEMPLATE " + root.getAttribute("dbtemplate");
			String err = rootDB.executeQuery(mysql);
			rootDB.close();

			if(err == null) log.info("Database Created");
			else log.severe(err);
		} else if("Drop Database".equals(aKey)) {
			BDB rootDB = new BDB(root);
			rootDB.logConfig(logHandle);
			String mysql = "DROP DATABASE " + textField[2].getText();
			String err = rootDB.executeQuery(mysql);			
			rootDB.close();

			if(err == null) log.info("Database Dropped");
			else log.severe("Database is not Dropped : " + err);
		} else if("Project Name".equals(aKey)) {
			String[] dbPath = {"jdbc:postgresql://localhost/", "jdbc:derby:", "jdbc:derby:", "jdbc:oracle:thin:@localhost:1521:", "jdbc:hsqldb:file:", "jdbc:mysql://localhost/", "jdbc:odbc:"};
			String projectName = textField[0].getText().trim().toLowerCase().replace(" ", "");
			textField[1].setText(projectName);
			textField[2].setText(projectName);
			if(dbClassList.getSelectedIndex() > -1)
				textField[3].setText(dbPath[dbClassList.getSelectedIndex()] + projectName);
			textField[4].setText(projectName + ".xml");
			textField[5].setText("postgres");
		} else if("New Setup".equals(aKey)) {
			log.info("Starting database setup");
			BDB rootDB = new BDB(root);
			rootDB.logConfig(logHandle);
			String mysql = "DROP DATABASE " + textField[2].getText();
			String err = rootDB.executeQuery(mysql);

			mysql = "CREATE DATABASE " + textField[2].getText();
			err = rootDB.executeQuery(mysql);
			rootDB.executeQuery("CREATE ROLE root LOGIN;");
			rootDB.close();

			if((err == null) && (desk != null)) {
				String ps = System.getProperty("file.separator");
				String myfile = configDir + textField[1].getText().trim() + ps + "database" + ps + "setup" + ps + "setup.sql";
				Bio io = new Bio();
				BDB deskDB = new BDB(desk);
				deskDB.logConfig(logHandle);
				deskDB.executeQuery("CREATE LANGUAGE plpgsql;");
				mysql = io.loadFile(myfile);				
				err = deskDB.executeQuery(mysql);
				deskDB.close();
			}

			if(err == null) log.info("Database Setup Completed");
			else log.severe(err);
		} else if("Demo Setup".equals(aKey)) {
			log.info("Demo Database Setup Starting");
			BDB rootDB = new BDB(root);
			rootDB.logConfig(logHandle);
			String mysql = "DROP DATABASE " + textField[2].getText();
			String err = rootDB.executeQuery(mysql);

			mysql = "CREATE DATABASE " + textField[2].getText();
			err = rootDB.executeQuery(mysql);
			rootDB.executeQuery("CREATE ROLE root LOGIN;");
			rootDB.close();

			if((err == null) && (desk != null)) {
				String ps = System.getProperty("file.separator");
				String myfile = configDir + textField[1].getText().trim() + ps + "database" + ps + "setup" + ps + "demo.sql";
				Bio io = new Bio();
				BDB deskDB = new BDB(desk);
				deskDB.logConfig(logHandle);
				deskDB.executeQuery("CREATE LANGUAGE plpgsql;");
				mysql = io.loadFile(myfile);				
				err = deskDB.executeQuery(mysql);
				deskDB.close();
			}

			if(err == null) log.info("Demo Database Setup Completed");
			else log.severe("Demo creation error : " + err);
		}
	}

	public void close() {
		if(db != null) db.close();
		dispose();
	}

}
