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
import java.awt.BorderLayout;

import javax.swing.JTabbedPane;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTable;
import javax.swing.JScrollPane;
//import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.JButton;
import javax.swing.JSplitPane;
import javax.swing.JTree;
import javax.swing.JComboBox;
import javax.swing.tree.DefaultTreeModel;
import javax.swing.tree.TreeSelectionModel;
import javax.swing.tree.TreePath;

import java.awt.GridLayout;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import javax.swing.event.TreeSelectionListener;
import javax.swing.event.TreeSelectionEvent;

import org.baraza.DB.*;
import org.baraza.app.*;
import org.baraza.xml.*;
import org.baraza.swing.*;
import org.baraza.utils.Bio;
import org.baraza.utils.BLogHandle;

public class BxmlViewer extends JTabbedPane implements ActionListener, TreeSelectionListener {
	Logger log = Logger.getLogger(BxmlViewer.class.getName());
	BLogHandle logHandle;
	JPanel controls, nodeControls;
	JTable table;
	JScrollPane scrollPane, textScroll, xmlScroll;
	//JTextArea textArea;
    BTextArea textArea;
	JButton[] button;
	JButton btNewDesk, btNewLink, btNewNode, btMoveUp, btMoveDown, btRefresh;
	JPanel xmlpanel;
	JLabel lblTableList, lblComponent, lblNewDesk, lblNewReport;
	JTextField txtNewDesk, txtNewReport;
	JTabbedPane nodePane;
	JComboBox<String> tableList, componentList;
	BImageDesktop desktop;
	JSplitPane splitPane;
	JTree tree;
	DefaultTreeModel treemodel;
	BXMLTable xmlTable;
	BTreeNode top = null;
	BElement root;
	BDB db;
	String xmlFile;
	String projectName;

	public BxmlViewer(BLogHandle logHandle, BDB db, String myFile, String projectName) {
		super();
		this.db = db;
		this.projectName = projectName;
		this.logHandle = logHandle;
		logHandle.config(log);
		xmlFile = myFile;

		BXML xml = new BXML(xmlFile, false);
		if(xml.getDocument() == null) root = new BElement("APP");
		else root = xml.getRoot();

		controls = new JPanel(new GridLayout(2, 0));
		String[] btArray = {"Save", "Reload", "Find", "Add Attribute", "Delete Attribute", "Web Migration", "App Migration", "Web Cleanup", "Preview", "New XML",};
		button = new JButton[btArray.length];		
		for(int i = 0; i < btArray.length; i++) {
			button[i] = new JButton(btArray[i]);
			button[i].addActionListener(this);
			controls.add(button[i]);
		}

		top = makeNode(root);
		treemodel = new DefaultTreeModel(top);
        tree = new BImageTree("/org/baraza/resources/leftpanel.jpg", treemodel, true);
		tree.setCellRenderer(new BCellRenderer());
        tree.getSelectionModel().setSelectionMode(TreeSelectionModel.SINGLE_TREE_SELECTION);
		tree.addTreeSelectionListener(this);
		xmlScroll = new JScrollPane(tree);

		// Create the pannel that has the XML, attributes, new components and design
		nodePane = new JTabbedPane();
		//textArea = new JTextArea();
        textArea = new BTextArea(logHandle);
		textArea.setTabSize(4);
		textScroll = new JScrollPane(textArea);
		nodePane.add(textScroll, "XML");
		table = new JTable();
		scrollPane = new JScrollPane(table);
		nodePane.add(scrollPane, "Attributes");
		nodeControls = new JPanel(null);
		nodePane.add(nodeControls, "New Components");

		lblTableList = new JLabel("Table : ");	
		nodeControls.add(lblTableList);
		lblTableList.setBounds(10, 5, 100, 25);
		tableList = new JComboBox<String>();
		nodeControls.add(tableList);
		tableList.setBounds(110, 5, 250, 25);
		for(String tn : db.getTables()) {
			if(!tn.startsWith("sys_")) tableList.addItem(tn);
		}
		btNewDesk = new JButton("New Desk");
		nodeControls.add(btNewDesk);
		btNewDesk.setBounds(360, 5, 100, 25);
		btNewDesk.addActionListener(this);
		btNewLink = new JButton("New Link");
		nodeControls.add(btNewLink);
		btNewLink.setBounds(470, 5, 100, 25);
		btNewLink.addActionListener(this);

		lblComponent = new JLabel("Component : ");
		nodeControls.add(lblComponent);
		lblComponent.setBounds(10, 30, 100, 25);

		String[] componentNames = {"DESK", "GRID", "REPORT DESK"};
		componentList = new JComboBox<String>(componentNames);
		nodeControls.add(componentList);
		componentList.setBounds(110, 30, 250, 25);
		btNewNode = new JButton("New Node");
		nodeControls.add(btNewNode);
		btNewNode.setBounds(360, 30, 100, 25);
		btNewNode.addActionListener(this);

		lblNewDesk = new JLabel("Name : ");
		txtNewDesk = new JTextField(50);
		nodeControls.add(lblNewDesk);
		lblNewDesk.setBounds(10, 55, 100, 25);
		nodeControls.add(txtNewDesk);
		txtNewDesk.setBounds(110, 55, 250, 25);

		lblNewReport = new JLabel("Report Name : ");
		txtNewReport = new JTextField(50);
		nodeControls.add(lblNewReport);
		lblNewReport.setBounds(10, 80, 100, 25);
		nodeControls.add(txtNewReport);
		txtNewReport.setBounds(110, 80, 250, 25);

		btMoveUp = new JButton("Move Up");
		nodeControls.add(btMoveUp);
		btMoveUp.setBounds(10, 105, 100, 25);
		btMoveUp.addActionListener(this);
		btMoveDown = new JButton("Move Down");
		nodeControls.add(btMoveDown);
		btMoveDown.setBounds(110, 105, 100, 25);
		btMoveDown.addActionListener(this);
		btRefresh = new JButton("Refresh");
		nodeControls.add(btRefresh);
		btRefresh.setBounds(210, 105, 100, 25);
		btRefresh.addActionListener(this);

		splitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, xmlScroll, nodePane);
		splitPane.setOneTouchExpandable(true);
		splitPane.setDividerLocation(200);

		desktop = new BImageDesktop("/org/baraza/resources/bg_small.png");

		xmlpanel =  new JPanel(new BorderLayout());
		xmlpanel.add(controls, BorderLayout.PAGE_START);
		xmlpanel.add(splitPane, BorderLayout.CENTER);

		super.addTab("XML", xmlpanel);
		super.addTab("Preview", desktop);
	}

	public BTreeNode makeNode(BElement sbn) {
		String title = sbn.getName() + " : ";
		if(sbn.getAttribute("title") != null) title += sbn.getAttribute("title");
		else if (sbn.getAttribute("name") != null) title += sbn.getAttribute("name");
		
		BTreeNode firstNode = new BTreeNode(sbn, title);
		for(BElement el : sbn.getElements())
			firstNode.add(makeNode(el));

		return firstNode;
	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("New XML".equals(aKey)) {
			root = new BElement("APP");
			root.setAttribute("name", projectName);
			root = db.getAppConfig(root);
			top = makeNode(root);
			treemodel.setRoot(top);
		} else if ("Save".equals(aKey)) {
			Bio io = new Bio();
			io.saveFile(xmlFile, root.toString());
		} else if ("Reload".equals(aKey)) {
			String xmltext = textArea.getText();
			BXML xmlNode = new BXML(xmltext, true);
			BTreeNode node = (BTreeNode)tree.getLastSelectedPathComponent();

			if ((xmlNode.getDocument() != null) && (node != null)) {
				BTreeNode parentNode = (BTreeNode)node.getParent();
				if(parentNode == null) {
					root = xmlNode.getRoot();
					top = makeNode(root);
					treemodel.setRoot(top);
				} else {
					BTreeNode newNode = makeNode(xmlNode.getRoot());
					int i = parentNode.getIndex(node);

					parentNode.getKey().addNode(newNode.getKey(), i);
					parentNode.getKey().delNode(node.getKey());

					parentNode.insert(newNode, i);
					parentNode.remove(node);

					treemodel.reload(parentNode);
				}
			}
		} else if ("Find".equals(aKey)) {
			BTreeNode node = (BTreeNode)tree.getLastSelectedPathComponent();
			if(node != null) {
				BElement menu = node.getKey();
				if(menu != null) {
					String menuKey = menu.getAttribute("key");
					if(menuKey == null) menuKey = menu.getValue();
					int i = root.elementIndex(root.getElementByKey(menuKey));
					tree.collapseRow(1);
					tree.setSelectionRow(i+1);
				}
			}
		} else if ("Add Attribute".equals(aKey)) {
			xmlTable.insertRow();
		} else if ("Delete Attribute".equals(aKey)) {
			int i = table.getSelectedRow();
			if(i>0) xmlTable.removeRow(i);
		} else if ("Web Migration".equals(aKey)) {
			migrateWeb();
		} else if ("App Migration".equals(aKey)) {
			migrateApp();
		} else if ("Web Cleanup".equals(aKey)) {
			webCleanUp();
		} else if ("Preview".equals(aKey)) {
			showPreview();
		} else if ("New Desk".equals(aKey)) {
			newDesk();
		} else if ("New Link".equals(aKey)) {
			newLink();
		} else if ("New Node".equals(aKey)) {
			newNode();
		} else if ("Move Up".equals(aKey)) {
			moveNode(true);
		} else if ("Move Down".equals(aKey)) {
			moveNode(false);
		} else if("Refresh".equals(aKey)) {
			refreshTable();
		}
	}

	public void showPreview() {
		BTreeNode node = (BTreeNode)tree.getLastSelectedPathComponent();
		
		if (node != null) {
           	BElement dKey = node.getKey();
			String reportDir = "";

			if(dKey.getName().equals("DESK")) {
				BDesk desk = new BDesk(logHandle, db, dKey, reportDir);

				desk.setVisible(true);
				desktop.add(desk);
				try {
					desk.setSelected(true);
				} catch (java.beans.PropertyVetoException ex) {
					System.out.println("Desktop show error : " + ex);
				}
			}
		}
	}

	public void valueChanged(TreeSelectionEvent ev) {
		BTreeNode node = (BTreeNode)tree.getLastSelectedPathComponent();
		
		if (node != null) {
			xmlTable = new BXMLTable(node, treemodel);
			table.setModel(xmlTable);
			table.setFillsViewportHeight(true);

			textArea.setText(node.getKey().toString());
			textArea.setCaretPosition(0);
		}
	}

	public void migrateWeb() {
		BElement menu = root.getElement(0).copy();
		for(BElement subMenu : menu.getElements()) {
			subMenu.setName("MENU");
			if(!subMenu.isLeaf()) {
				subMenu.delAttribute("key");
				for(BElement itemMenu : subMenu.getElements()) {
					itemMenu.setName("MENU");
					itemMenu.setValue(itemMenu.getAttribute("key"));
					itemMenu.delAttribute("key");
				}
			}
		}
		
		BElement app = new BElement("APP");
		app.addNode(menu);

		BElement desks = root.getElement(1).copy();
		for(BElement desk : desks.getElements()) {
			BElement node = new BElement("DESK");
			node.setAttribute("h", "500"); 
			node.setAttribute("w", "700");
			node.setAttribute("key", desk.getAttribute("key"));
			node.setAttribute("name", desk.getAttribute("name"));
			desk.delAttribute("key");
			if(desk.getName().equals("REPORT")) desk.setName("GRID");
			if(desk.getAttribute("ordersql") != null) {
				desk.setAttribute("orderby", desk.getAttribute("ordersql"));
				desk.delAttribute("ordersql");
			}
			if(desk.getAttribute("wheresql") != null) {
				desk.setAttribute("where", desk.getAttribute("wheresql"));
				desk.delAttribute("wheresql");
			}
			if(desk.getAttribute("primaryfield") != null)
				desk.replaceAttribute("primaryfield", "keyfield");

			if(desk.getAttribute("approvals") != null) {
				BElement actions = new BElement("ACTIONS");
				String approvals[] = desk.getAttribute("approvals").split(":");
				for(String approval : approvals) {
					BElement action = new BElement("ACTION");
					action.setValue(approval);
					action.setAttribute("fnct", desk.getAttribute("functioncheck"));
					action.setAttribute("approval", approval);
					if(desk.getAttribute("phase") == null) action.setAttribute("phase", "1");
					else action.setAttribute("phase", desk.getAttribute("phase"));
					action.setAttribute("from", "from dual");
					actions.addNode(action);

					//desk.delAttribute("approvals");
					//desk.delAttribute("functioncheck");
				}
				desk.addNode(actions);	
			}

			for(BElement field : desk.getElements()) {
				if(field.getName().equals("FIELD")) field.setName("TEXTFIELD");
				field.replaceAttribute("type", "format");
				field.replaceAttribute("defaultvalue", "default");
				field.replaceAttribute("lookupfield", "lpfield");
				field.replaceAttribute("lookupkey", "lpkey");
				field.replaceAttribute("lookuptable", "lptable");
				field.replaceAttribute("wheresql", "where");

				if(field.getAttribute("typeid") != null) {
					int typeid = Integer.valueOf(field.getAttribute("typeid")).intValue();
					switch (typeid) {
						case 1: field.setName("TEXTFIELD"); break;
						case 2: field.setName("TEXTAREA"); break;
						case 3: field.setName("PASSWORD"); break;
						case 4: field.setName("COMBOBOX"); break;
						case 5: field.setName("CHECKBOX"); break;
						case 6: field.setName("COMBOLIST"); break;
						case 8: field.setName("FILE"); break;
						case 9: field.setName("TEXTDATE"); break;
						case 10: field.setName("DEFAULT"); break;
						case 15: field.setName("CHECKBOX"); field.setAttribute("ischar", "true"); break;
					}
					field.delAttribute("typeid");
				}

				if(field.getAttribute("editkey") != null)
					field.setName("EDITFIELD");
			}

			BElement tmpdesk = desk.copy();
			int i = 0;
			for(BElement field : tmpdesk.getElements()) {
				if(field.getAttribute("subreport") != null) {
					BElement subreport = desks.getElementByKey(field.getAttribute("subreport"));
					if(subreport != null) {
						//subreport.delAttribute("key");
						subreport.replaceAttribute("filterkey", "linkfield");

						desk.addNode(subreport);
						desk.setAttribute("keyfield", field.getValue().toLowerCase());
						desk.delNode(i);
						i--;
					}
				} else if(field.getAttribute("entrylink") != null) {
					BElement subreport = desks.getElementByKey(field.getAttribute("entrylink"));
					if(subreport != null) {
						//subreport.delAttribute("key");
						subreport.replaceAttribute("filterfield", "linkfield");
						subreport.replaceAttribute("primaryfield", "keyfield");
						if(subreport.getAttribute("user") != null) {
							BElement user = new BElement("USERFIELD");
							user.setValue(subreport.getAttribute("user"));
							subreport.addNode(user);
							subreport.delAttribute("user");
						}

						desk.addNode(subreport);
						desk.setAttribute("keyfield", field.getValue().toLowerCase());
						desk.delNode(i);
						i--;
					}
				} else if(field.getAttribute("selectrow") != null) {
					desk.setAttribute("keyfield", field.getValue().toLowerCase());
					desk.delNode(i);
					i--;
				}
				i++;
			}

			node.addNode(desk);

			app.addNode(node);
		}

		// Write migrated xml to file
		Bio io = new Bio();
		io.saveFile(xmlFile + ".new", app.toString());
	}

	public void migrateApp() {
		BElement app = new BElement("APP");
		boolean first = true;

		for(BElement node : root.getElements()) {
			if(first) {
				app.addNode(migrateMenu(node)); 
				first = false;
			} else {
				app.addNode(migrateDesk(node));
			}
		}

		// Write migrated xml to file
		Bio io = new Bio();
		io.saveFile(xmlFile + ".new", app.toString());

		System.out.println(app.toString());
	}

	public BElement migrateMenu(BElement menu) {
		BElement newMenu = new BElement("MENU");
		newMenu.setAttribute("name", menu.getAttribute("name"));
		if(menu.getAttribute("key") != null) newMenu.setValue(menu.getAttribute("key"));
		if(menu.getAttribute("role") != null) newMenu.setAttribute("role", menu.getAttribute("role"));

		for(BElement itemMenu : menu.getElements()) 
			newMenu.addNode(migrateMenu(itemMenu));

		return newMenu;
	}

	public BElement migrateDesk(BElement oldDesk) {
		BElement desk = new BElement("DESK");
		boolean hasFilters = false;
		desk.setAttribute("h", oldDesk.getAttribute("h")); 
		desk.setAttribute("w", oldDesk.getAttribute("w"));
		desk.setAttribute("key", oldDesk.getAttribute("key"));
		desk.setAttribute("name", oldDesk.getAttribute("name"));
		desk.setAttribute("type", oldDesk.getAttribute("splittype"));

		for(BElement view : oldDesk.getElements()) {
			if(view.getAttribute("linkkey") == null) {
				desk.addNode(view);
			} else {
				BElement linkView = oldDesk.getElementByKey(view.getAttribute("linkkey"));
				if(linkView == null) desk.addNode(view);
				else linkView.addNode(view);
			}
			view.replaceAttribute("jasperfile", "reportfile");
			view.replaceAttribute("wheresql", "where");
			view.replaceAttribute("ordersql", "orderby");
			view.replaceAttribute("sortfield", "orderby");

			if(view.getAttribute("keyfield") == null) view.replaceAttribute("autofield", "keyfield");
			if((view.getAttribute("keyfield") == null) && (view.getAttribute("keyfield") == null)) view.replaceAttribute("linkfield", "keyfield");
			if(view.getAttribute("inputfield") != null) view.replaceAttribute("inputfield", "linkfield");
			if(view.getAttribute("keyfield", "").equals(view.getAttribute("linkfield"))) view.delAttribute("linkfield");
			if(view.getName().equals("REPORT")) view.setName("JASPER");

			view.delAttribute("gridfilter");
			view.delAttribute("linkkey");
			view.delAttribute("pos");

			for(BElement field : view.getElements()) {
				if(field.getName().equals("TEXTLOOKUP")) field.setName("GRIDBOX");
				field.replaceAttribute("sortfield", "orderby");

				for(BElement subfield : field.getElements()) {
					subfield.replaceAttribute("sortfield", "orderby");
				}
			}
			if(view.getName().equals("DRILLDOWN")) hasFilters = true;
			if(view.getName().equals("CALENDAR")) hasFilters = true;
		}

		if(hasFilters) {
			BElement filter = new BElement("FILTER");
			filter.setAttribute("name", desk.getAttribute("name"));
			filter.setAttribute("location", "250");
			filter.setAttribute("type", "horl");

			for(BElement view : desk.getElements()) {
				filter.addNode(view);
			}
			desk.clearNodes();
			desk.addNode(filter);
		}

		return desk;
	}

	public void webCleanUp() {
		for(BElement node : root.getElements()) {
			webCleanUp(node);
		}

		// Write migrated xml to file
		Bio io = new Bio();
		io.saveFile(xmlFile + ".new", root.toString());

		//System.out.println(root.toString());
	}

	public void webCleanUp(BElement node) {
		for(BElement el : node.getElements()) {
			String format = el.getAttribute("format", "");
			if(format.equals("boolean")) {
				el.insertAttribute("ischar", "true");
				el.setName("CHECKBOX");
			}
			if(!el.getName().equals("DESK")) el.delAttribute("key");

			if(el.getAttribute("form") != null) {
				el.setAttribute("display", "form");
				el.delAttribute("form");
			}

			if(el.getAttribute("editor") != null) {
				el.delAttribute("editor");
				el.setName("EDITOR");
			}

			if((el.getAttribute("keyfield") == null) & (el.getAttribute("autofield") != null))
				el.replaceAttribute("autofield", "keyfield");

			el.replaceAttribute("selectvalue", "action");
			if(el.getAttribute("action") != null) {
				if(node.getAttribute("keyfield") == null)
					node.setAttribute("keyfield", el.getValue());

				BElement action = new BElement("ACTION");
				action.setAttribute("fnct", el.getAttribute("action"));
				action.setValue(el.getAttribute("title"));
				el.addNode(action);
				el.setName("ACTIONS");
				el.setValue("");

				el.delAttribute("action");
				el.delAttribute("title");
				el.delAttribute("w");
			}

			webCleanUp(el);
		}
	}

	public void newDesk() {
		int ik = 5;
		for(BElement nel : root.getElements()) {
			String iks = nel.getAttribute("key");
			int i = 0;
			if(iks != null) i = Integer.valueOf(iks);
			if(i >= ik) ik = i + 5;
		}

		String tableName = tableList.getSelectedItem().toString();
		BElement mel = new BElement("MENU");
		mel.setAttribute("name", db.initCap(tableName));
		mel.setValue(String.valueOf(ik));
		BTreeNode mnNode = makeNode(mel);
		top.add(mnNode);
		root.addNode(mel);

		BQuery query = new BQuery(db, "*", tableName, 2);
		BElement del = new BElement("DESK");
		del.setAttribute("h", "550");
		del.setAttribute("w", "700");
		del.setAttribute("name", db.initCap(tableName));
		del.setAttribute("key", String.valueOf(ik));
		del.addNode(query.getDeskConfig(0));
		BTreeNode deskNode = makeNode(del);
		top.add(deskNode);
		root.addNode(del);
		treemodel.reload(top);
		query.close();
	}

	public void newReportDesk() {
		int ik = 5;
		for(BElement nel : root.getElements()) {
			String iks = nel.getAttribute("key");
			int i = 0;
			if(iks != null) i = Integer.valueOf(iks);
			if(i >= ik) ik = i + 5;
		}

		String tableName = tableList.getSelectedItem().toString();
		BElement mel = new BElement("MENU");
		mel.setAttribute("name", db.initCap(tableName));
		mel.setValue(String.valueOf(ik));
		BTreeNode mnNode = makeNode(mel);
		top.add(mnNode);
		root.addNode(mel);

		BElement jsr = new BElement("JASPER");
		jsr.setAttribute("name", txtNewDesk.getText());
		jsr.setAttribute("reportfile", txtNewReport.getText() + ".jasper");

		BElement del = new BElement("DESK");
		del.setAttribute("h", "550");
		del.setAttribute("w", "700");
		del.setAttribute("name", txtNewDesk.getText());
		del.setAttribute("key", String.valueOf(ik));
		del.addNode(jsr);

		BTreeNode deskNode = makeNode(del);
		top.add(deskNode);
		root.addNode(del);
		treemodel.reload(top);
	}

	public void newLink() {
		String tableName = tableList.getSelectedItem().toString();
		BTreeNode node = (BTreeNode)tree.getLastSelectedPathComponent();
		BQuery query = new BQuery(db, "*", tableName, 2);
		BElement del = query.getDeskConfig(1);
		node.getKey().addNode(del);
		BTreeNode deskNode = makeNode(del);
		node.add(deskNode);
		treemodel.reload(node);

		query.close();
	}

	public void newNode() {
		String cmpName = componentList.getSelectedItem().toString();
		if("REPORT DESK".equals(cmpName)) {
			newReportDesk();
		}
	}

	public void moveNode(boolean direction) {
		TreePath currentSelection = tree.getSelectionPath();
		if(currentSelection != null) {
			BTreeNode node = (BTreeNode)(currentSelection.getLastPathComponent());
			if(node != null) {
				BTreeNode parent = (BTreeNode)(node.getParent());
				int x = parent.getIndex(node);
				int y = x;
				if(direction && (x>0)) y = x - 1;
				if(!direction && (x<(parent.getChildCount()-1))) y = x + 1;

				if(x!=y) {
					parent.insert(node, y);
					parent.getKey().addNode(node.getKey(), y);
					if(direction) x++;
					parent.getKey().delNode(x);
					treemodel.reload(parent);
					tree.setSelectionPath(currentSelection);
				}
			}
		}
    }

	public void refreshTable() {
		tableList.removeAllItems();

		for(String tn : db.getTables()) {
			if(!tn.startsWith("sys_")) tableList.addItem(tn);
		}
	}

}