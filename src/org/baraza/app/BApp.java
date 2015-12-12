/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.app;

import java.util.logging.Logger;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.io.InputStream;
import java.io.IOException;
import java.net.InetAddress;

import java.awt.GridLayout;
import java.awt.BorderLayout;

import javax.swing.JSplitPane;
import javax.swing.JPanel;
import javax.swing.JDesktopPane;
import javax.swing.JSplitPane;
import javax.swing.JScrollPane;

import javax.swing.JLabel;
import javax.swing.JComboBox;
import javax.swing.JTextField;
import javax.swing.JPasswordField;
import javax.swing.JButton;
import javax.swing.JMenuBar;
import javax.swing.JMenu;
import javax.swing.JMenuItem;

import javax.swing.tree.DefaultTreeModel;
import javax.swing.tree.TreeSelectionModel;
import javax.swing.tree.TreePath;
import javax.swing.tree.DefaultTreeCellRenderer;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import javax.swing.event.TreeSelectionListener;
import javax.swing.event.TreeSelectionEvent;

import org.baraza.swing.*;
import org.baraza.DB.BDB;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.xml.BTreeNode;
import org.baraza.utils.BDesEncrypter;
import org.baraza.utils.BLogHandle;

public class BApp extends JPanel implements ActionListener, TreeSelectionListener {
	Logger log = Logger.getLogger(BApp.class.getName());
	BLogHandle logHandle;
	BDB db;
	BElement projectsList, root;
	BElement dKey = null;
	BImageTree tree;
	BAbout about;
	BPasswordChange passwordChange;
	BTreeNode top = null;
	BImagePanel imagePanel;

	JPanel loginPanel;
	JDesktopPane desktop;
	JSplitPane splitPane;
	Map<BElement, BDesk> desks;

	DefaultTreeModel treemodel;
	String reportDir;
	String configDir;
	String configFile;
	String dbpath;
	List<Integer> elementList;

	JMenuBar menuBar;
	JMenu fileMenu;
	JMenuItem menuItem;
	JLabel lPrograms, lUserName, lPassword, clearStatus, loginStatus;
	JComboBox<String> cmbPrograms;
	JTextField tfUserName;
	JPasswordField pwPassword;
	JButton btClear, btOkay;
	JScrollPane treeScroll;

	public BApp(String configDir, String configXmlFile, String dbpath, String encryptionKey) {
		super(new BorderLayout());
		super.setOpaque(false);

		this.dbpath = dbpath;
		this.configDir = configDir;
		BXML xml = null;
		if(encryptionKey == null) {
			xml = new BXML(configDir + configXmlFile, false);
		} else {
			configXmlFile = configXmlFile.substring(0, configXmlFile.length()-3) + "cph";

			// Create encrypter/decrypter class and encrypt
			BDesEncrypter decrypter = new BDesEncrypter(encryptionKey);
			InputStream inXml = decrypter.decrypt(configDir + configXmlFile);

			xml = new BXML(inXml);
		}


		projectsList = xml.getRoot();

		logHandle = new BLogHandle();
		logHandle.setLogLevel(projectsList);
		logHandle.config(log);

		imagePanel = new BImagePanel("/org/baraza/resources/background.jpg");
		loginPanel = new JPanel(new GridLayout(0, 2, 2, 2));
		loginPanel.setOpaque(false);
		imagePanel.add(loginPanel);
		loginPanel.setLocation(250, 200);
		loginPanel.setSize(400, 120);

		lPrograms = new JLabel("Project : ");
		cmbPrograms = new JComboBox<String>();
		loginPanel.add(lPrograms);
		loginPanel.add(cmbPrograms);
		lUserName = new JLabel("User Name : ");
		tfUserName = new JTextField(25);
		loginPanel.add(lUserName);
		loginPanel.add(tfUserName);
		lPassword = new JLabel("Password : ");
		pwPassword = new JPasswordField();
		pwPassword.setActionCommand("Login");
		pwPassword.addActionListener(this);
		loginPanel.add(lPassword);
		loginPanel.add(pwPassword);

		btClear = new JButton("Clear");
		btClear.addActionListener(this);
		btOkay = new JButton("Login");
		btOkay.addActionListener(this);
		loginPanel.add(btClear);
		loginPanel.add(btOkay);

		clearStatus = new JLabel();
		loginStatus = new JLabel();
		loginPanel.add(clearStatus);
		loginPanel.add(loginStatus);

		elementList = new ArrayList<Integer>();
		int i = 0;
		for(BElement el : projectsList.getElements()) {
			if(el.getName().equals("APP")) {
				cmbPrograms.addItem(el.getValue());
				elementList.add(i);
			}
			i++;
		}

		super.add(imagePanel, BorderLayout.CENTER);
		log.info("INFO DESK : SYSTEM STARTED");
	}

	public void login() {
		// Create an application
		desks = new HashMap<BElement, BDesk>();
		BElement el = root.getFirst();
		top = makeMenu(el);

		// Create a menu
		menuBar = new JMenuBar();
		fileMenu = new JMenu("File");
		if(root.getAttribute("password") != null) {
			passwordChange = new BPasswordChange(db, root);
			menuItem = new JMenuItem("Change Password");
			menuItem.addActionListener(this);
			fileMenu.add(menuItem);
		}
		about =  new BAbout("Open Baraza");
		menuItem = new JMenuItem("About ...");
		menuItem.addActionListener(this);
		fileMenu.add(menuItem);
		menuBar.add(fileMenu);
		super.add(menuBar, BorderLayout.PAGE_START);

        // Create a tree that allows one selection at a time.
        treemodel = new DefaultTreeModel(top);
        tree = new BImageTree("/org/baraza/resources/leftpanel.jpg", treemodel, false);
        tree.getSelectionModel().setSelectionMode(TreeSelectionModel.SINGLE_TREE_SELECTION);
    	tree.setCellRenderer(new BCellRenderer());
		tree.addTreeSelectionListener(this);
		treeScroll = new JScrollPane(tree);

		// Create the desktop
		desktop = new BImageDesktop("/org/baraza/resources/background.jpg");
		splitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, treeScroll, desktop);
		splitPane.setOneTouchExpandable(true);
		splitPane.setDividerLocation(200);

		imagePanel.setVisible(false);
		super.remove(imagePanel);
		super.add(splitPane, BorderLayout.CENTER);
		super.add(logHandle.getStatusBar(), BorderLayout.PAGE_END);
		super.repaint();
	}

	public BTreeNode makeMenu(BElement sbn) {
		BTreeNode firstNode = new BTreeNode(root.getElementByKey(sbn.getValue()), sbn.getAttribute("name"));

		for(BElement el : sbn.getElements()) {
			boolean access = false;

			if(el.getAttribute("role") == null) {
				access = true;
			} else {
				String mRoles[] = el.getAttribute("role").split(",");
				for(String mRole : mRoles) {
					if(db.getGroupRoles().contains(mRole.trim())) access = true;
					if(db.getUserRoles().contains(mRole.trim())) access = true;
					if(db.getSuperUser()) access = true;
				}
			}
			if(el.getAttribute("xml") != null) access = false;

			if(access) firstNode.add(makeMenu(el));
		}

		return firstNode;
	}

	public void valueChanged(TreeSelectionEvent ev) {
		BTreeNode node = (BTreeNode)tree.getLastSelectedPathComponent();
		
		if (node != null) {
			dKey = node.getKey();

			if (node.isLeaf() && (dKey != null)) {
				if(desks.get(dKey) == null)
					desks.put(dKey, new BDesk(logHandle, db, dKey, reportDir));

				if(!desks.get(dKey).isVisible()) {
					desks.get(dKey).setVisible(true);
					desktop.add(desks.get(dKey));
					try {
						desks.get(dKey).setSelected(true);
					} catch (java.beans.PropertyVetoException ex) {
						System.out.println("Desktop show error : " + ex);
					}
				} else {
					try {
						desks.get(dKey).setSelected(true);
						if(desks.get(dKey).isIcon())
							desks.get(dKey).setIcon(false);
					} catch (java.beans.PropertyVetoException ex) {
						System.out.println("Desktop show error : " + ex);
					}
				}
			}
		}
	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("Clear".equals(aKey)) {
			tfUserName.setText("");
			pwPassword.setText("");
		} else if("Login".equals(aKey)) {
			int elemenrtPos = elementList.get(cmbPrograms.getSelectedIndex());
			BElement prog = projectsList.getElement(elemenrtPos);
			String ps = System.getProperty("file.separator");
			if(configDir.startsWith("http")) ps = "/";

			configFile = configDir + prog.getAttribute("path") + ps + "configs" + ps + prog.getAttribute("xmlfile");
			reportDir = prog.getAttribute("reports");
			if(reportDir == null)
				reportDir = configDir + prog.getAttribute("path") + ps + "reports" + ps;
			BXML xml = new BXML(configFile, false);
			boolean noauth = false;
			String auth = prog.getAttribute("auth", "db");
			String mypassword = new String(pwPassword.getPassword());
			if((dbpath != null) && (prog.getAttribute("fixed")==null)) prog.setAttribute("dbpath", dbpath);

			if(auth.equals("db")) {				
				db = new BDB(prog, tfUserName.getText(), mypassword);
				if(db.getDB() == null) noauth = true;
			} if(auth.equals("entity")) {
				db = new BDB(prog);
				String mysql = "SELECT entity_id FROM entitys WHERE (User_name = '" + tfUserName.getText() + "')";
				mysql += " AND (Entity_password = md5('" + mypassword + "'))";
				mysql += " AND (is_active = true)";
				if(db.getDB() == null) {
					noauth = true;
				} else {
					if(db.executeFunction(mysql) == null) noauth = true;
				}
			}

			if(noauth) {
				clearStatus.setText("Login error");
				loginStatus.setText("Invalid credentials");
			} else if(xml.getDocument() == null) {
				loginStatus.setText("XML loading file error");
			} else {
				root = xml.getRoot();
				String ipaddress = "";
				try {
					InetAddress i = InetAddress.getLocalHost();
					ipaddress = i.toString();
				} catch(java.net.UnknownHostException ex) { }

				db.setUser(ipaddress, tfUserName.getText());
				login();
			}
		} else if("About ...".equals(aKey)) {
			if(!about.isVisible()) {
				about.setVisible(true);
				desktop.add(about);
				try {
					about.setSelected(true);
				} catch (java.beans.PropertyVetoException ex) {
					System.out.println("Desktop show error : " + ex);
				}
			}
		} else if("Change Password".equals(aKey)) {
			if(!passwordChange.isVisible()) {
				passwordChange.setVisible(true);
				desktop.add(passwordChange);
				try {
					passwordChange.setSelected(true);
				} catch (java.beans.PropertyVetoException ex) {
					System.out.println("Desktop show error : " + ex);
				}
			}
		} 
	}

	public void close() {
		if(db != null) db.close();
	}

}
