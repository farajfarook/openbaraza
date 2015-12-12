/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.ide;

import java.io.File;
import java.util.logging.Logger;
import java.util.Map;
import java.util.HashMap;

import java.awt.BorderLayout;
import java.awt.GridLayout;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import javax.swing.JDesktopPane;
import javax.swing.JSplitPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JOptionPane;
import javax.swing.JMenuBar;
import javax.swing.JMenu;
import javax.swing.JMenuItem;
import javax.swing.JFileChooser;

import javax.swing.event.TreeSelectionListener;
import javax.swing.event.TreeSelectionEvent;
import javax.swing.tree.DefaultTreeModel;
import javax.swing.tree.TreeSelectionModel;
import javax.swing.tree.TreePath;

import org.baraza.xml.*;
import org.baraza.swing.*;
import org.baraza.app.BAbout;
import org.baraza.utils.BDesEncrypter;
import org.baraza.utils.Bio;
import org.baraza.utils.BLogHandle;

public class BIDE extends JPanel implements TreeSelectionListener, ActionListener {
	Logger log = Logger.getLogger(BIDE.class.getName());
	String configDir, configFile;
	BElement root;

	Map<BElement, BDevelop> develop;
	BTreeNode top = null;
	BImageTree tree;
	DefaultTreeModel treemodel;
	BLogHandle logHandle;

	JSplitPane splitPane;
	JDesktopPane desktop;
	JScrollPane treeScroll;
	JPanel treePanel, mainPanel;

	public BIDE(String configDir) {
		super(new BorderLayout());

		this.configDir = configDir;
		configFile = "config.xml";
		BXML xml = new BXML(configDir + configFile, false);
		root = xml.getRoot();
		logHandle = new BLogHandle();
		logHandle.config(log);

		// Create an application list
		develop = new HashMap<BElement, BDevelop>();
		mainPanel = new JPanel(new BorderLayout());
		treePanel = new JPanel(new BorderLayout());

        //Create a tree that allows one selection at a time.
		top = new BTreeNode(root, "APP");
		for(BElement el : root.getElements())
			top.add(new BTreeNode(el, el.getValue()));

		treemodel = new DefaultTreeModel(top);
        tree = new BImageTree("/org/baraza/resources/leftpanel.jpg", treemodel, true);
        tree.getSelectionModel().setSelectionMode(TreeSelectionModel.SINGLE_TREE_SELECTION);
		tree.setCellRenderer(new BCellRenderer());
		tree.addTreeSelectionListener(this);
		treeScroll = new JScrollPane(tree);
		treePanel.add(treeScroll, BorderLayout.CENTER);

		String menuStrs[] = {"New Project", "Close Project", "Delete Project", "Save Projects", "Encrypt File", "Open Applications", "About"};
		JMenuBar menuBar = new JMenuBar();
		JMenu fileMenu = new JMenu("File");
		JMenuItem menuItem = null;
		for(String menuStr : menuStrs) {
			menuItem = new JMenuItem(menuStr);
			menuItem.addActionListener(this);
			fileMenu.add(menuItem);
		}
		menuBar.add(fileMenu);
		super.add(menuBar, BorderLayout.PAGE_START);

		desktop = new BImageDesktop("/org/baraza/resources/background.jpg");
		mainPanel.add(desktop, BorderLayout.CENTER);
		mainPanel.add(logHandle.getStatusBar(), BorderLayout.PAGE_END);

		splitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, treePanel, mainPanel);
		splitPane.setOneTouchExpandable(true);
		splitPane.setDividerLocation(150);

		super.add(splitPane, BorderLayout.CENTER);
		log.info("Status : Running");
	}

	public void valueChanged(TreeSelectionEvent ev) {
		BTreeNode node = (BTreeNode)tree.getLastSelectedPathComponent();
		
		if (node != null) {
			BElement dKey = node.getKey();

			if(develop.get(dKey) == null)		// Create a new IDE if one is not one the MAP
				develop.put(dKey, new BDevelop(dKey, root, node, treemodel, configDir, logHandle));
		
			try {
				if(develop.get(dKey).isVisible()) {
					develop.get(dKey).setSelected(true);
					if(develop.get(dKey).isIcon())
						develop.get(dKey).setIcon(false);
				} else {
					develop.get(dKey).setVisible(true);
					desktop.add(develop.get(dKey));
					develop.get(dKey).setSelected(true);
				}
			} catch (java.beans.PropertyVetoException ex) {
				log.severe("Desktop show error : " + ex);
			}
		}
	}

	public void closeProject(boolean delNode) {
		BTreeNode node = (BTreeNode)tree.getLastSelectedPathComponent();
		if (node != null) {
			BTreeNode parent = (BTreeNode)(node.getParent());
			if (node.isLeaf()) {
				BElement dKey = node.getKey();
				if(develop.get(dKey) != null) {
					develop.get(dKey).close();
					develop.remove(dKey);
					tree.removeSelectionPath(tree.getSelectionPath());
				}
 
				if ((delNode) && (parent != null)) {
					int n = JOptionPane.showConfirmDialog(treePanel, "Are you sure you want to delete the project?", "Project Deletion", JOptionPane.YES_NO_OPTION);
					if(n == 0) {
						treemodel.removeNodeFromParent(node);
						root.delNode(dKey);
						Bio io = new Bio();
						io.saveFile(configDir + "config.xml", root.toString());
	
						log.info("Project deleted");
					}
				}
			}
		} else {
			log.info("Select a project first");
		}
	}
	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("New Project".equals(aKey)) {
			BDevelop newdevdesk = new BDevelop(root, top, treemodel, configDir, logHandle);
			newdevdesk.setVisible(true);
			desktop.add(newdevdesk);
			try {
				newdevdesk.setSelected(true);
			} catch (java.beans.PropertyVetoException ex) {
				log.severe("Desktop show error : " + ex);
			}
		} else if("Close Project".equals(aKey)) {
			closeProject(false);
		} else if("Delete Project".equals(aKey)) {
			closeProject(true);
		} else if("Save Projects".equals(aKey)) {
			Bio io = new Bio();
			io.saveFile(configDir + configFile, root.toString());
		} else if("Encrypt File".equals(aKey)) {
			// Create encrypter/decrypter class and encrypt
			String encryFile = configFile.substring(0, configFile.length()-3) + "cph";
			BDesEncrypter encrypter = new BDesEncrypter(root.getAttribute("encryption"));
			encrypter.encrypt(configDir + configFile, configDir + encryFile);
		} else if("Open Applications".equals(aKey)) {
			//Create a file chooser
			JFileChooser fc = new JFileChooser(configDir);
			int returnVal = fc.showOpenDialog(this);
			if (returnVal == JFileChooser.APPROVE_OPTION) {
				File cnFile = fc.getSelectedFile();
				configDir = cnFile.getParent() + "/";
				configFile = cnFile.getName();

				BXML xml = new BXML(configDir + configFile, false);
				root = xml.getRoot();
				top = new BTreeNode(root, "APP");
				for(BElement el : root.getElements())
					top.add(new BTreeNode(el, el.getValue()));

				treemodel.setRoot(top);
				treemodel.reload();
			}
		} else if("About".equals(aKey)) {
			BAbout about = new BAbout("IDE");
			about.setVisible(true);
			desktop.add(about);
			try {
				about.setSelected(true);
			} catch (java.beans.PropertyVetoException ex) {
				log.severe("Desktop show error : " + ex);
			}
		}
	}

	public void close() {
		for(BElement dev : develop.keySet()) develop.get(dev).close();
	}

}