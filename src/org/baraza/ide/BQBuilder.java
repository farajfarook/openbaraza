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
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.awt.BorderLayout;

import javax.swing.JTextField;
import javax.swing.JLabel;
import javax.swing.JButton;
import javax.swing.JPanel;
import javax.swing.JSplitPane;
import javax.swing.JList;
import javax.swing.DefaultListModel;
import javax.swing.JDesktopPane;
import javax.swing.JTabbedPane;
import javax.swing.JTextArea;
import javax.swing.JTable;
import javax.swing.JOptionPane;
import javax.swing.JScrollPane;
import javax.swing.JFileChooser;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;

import org.baraza.DB.*;
import org.baraza.app.*;
import org.baraza.utils.Bio;
import org.baraza.swing.BImageDesktop;
import org.baraza.reports.BReportMaker;
import org.baraza.reports.BCompileReport;
import org.baraza.utils.BLogHandle;

public class BQBuilder extends JPanel implements ActionListener, MouseListener {
	Logger log = Logger.getLogger(BQBuilder.class.getName());
	BLogHandle logHandle;
	BDB db;
	JPanel controls, reportPanel, reportControls;
	JButton[] button;
	JSplitPane splitPane, mainPane;
	DefaultListModel<String> listModel;
	JList<String> tableList;
	BImageDesktop desktop;
	JTable table, defTable, joinTable;
	JTextArea sqlText, xmlText, reportText;
	JScrollPane scrollPane, defPane, joinPane, tablesPane, sqlPane, xmlPane, reportPane;
	JTabbedPane tabbedPane;
	Map<String, BTableViewer> tableViews;
	BTableModel tableModel = null;
	BTableModel defModel = null;
	BTableModel joinModel = null;
	String activeTable = null;
	String reportDir = null;
	JTextField txtReportName;

	public BQBuilder(BLogHandle logHandle, BDB db, String reportDir) {
		super(new BorderLayout());
		this.db = db;
		this.reportDir = reportDir;
		this.logHandle = logHandle;
		logHandle.config(log);

		tableViews =  new HashMap<String, BTableViewer>();
		controls = new JPanel();
		super.add(controls, BorderLayout.PAGE_START);

		String[] btArray = {"New", "Delete Field", "Reload", "Refresh", "View", "Execute", "Export", "Linked XML", 
			"Portrait Report", "Landscape Report", "Sub Report", "Save Report"};
		button = new JButton[btArray.length];		
		for(int i = 0; i < 8; i++) {
			button[i] = new JButton(btArray[i]);
			button[i].addActionListener(this);
			controls.add(button[i]);
		}

		listModel = new DefaultListModel<String>();
		listTables();

		tableList = new JList<String>(listModel);
		tableList.addMouseListener(this);
		tablesPane = new JScrollPane(tableList);
		desktop = new BImageDesktop("/org/baraza/resources/bg_small.png");

		splitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, tablesPane, desktop);
		splitPane.setOneTouchExpandable(true);
		splitPane.setDividerLocation(150);

		defModel = new BTableModel(new String[]{"Table Name", "Field Name", "Filter Type", "Filter Value", "Visible", "Group Function"});
		defTable = new JTable(defModel);
		defPane = new JScrollPane(defTable);

		joinModel = new BTableModel(new String[]{"Table Name", "Field Name", "Link", "Foreign Table", "Foreign Field"});
		joinTable = new JTable(joinModel);
		joinPane = new JScrollPane(joinTable);

		table = new JTable();
		scrollPane = new JScrollPane(table);

		sqlText = new JTextArea();
		sqlPane = new JScrollPane(sqlText);
		xmlText = new JTextArea();
		xmlPane = new JScrollPane(xmlText);
		tabbedPane = new JTabbedPane();
		tabbedPane.add("Columns", defPane);
		tabbedPane.add("Join", joinPane);
		tabbedPane.add("SQL", sqlPane);
		tabbedPane.add("Results", scrollPane);
		tabbedPane.add("XML", xmlPane);

		reportText = new JTextArea();
		reportPane = new JScrollPane(reportText);
		reportPanel = new JPanel(new BorderLayout());
		reportControls = new JPanel();
		reportPanel.add(reportControls, BorderLayout.PAGE_START);
		reportPanel.add(reportPane, BorderLayout.CENTER);
		tabbedPane.add("Report Maker", reportPanel);
		txtReportName = new JTextField(15);
		reportControls.add(new JLabel("Report Name : "));
		reportControls.add(txtReportName);
		for(int i = 8; i < 12; i++) {
			button[i] = new JButton(btArray[i]);
			button[i].addActionListener(this);
			reportControls.add(button[i]);
		}

		mainPane  = new JSplitPane(JSplitPane.VERTICAL_SPLIT, splitPane, tabbedPane);
		mainPane.setOneTouchExpandable(true);
		mainPane.setDividerLocation(250);
		super.add(mainPane, BorderLayout.CENTER);
	}

	public void showTable() {
		String dKey = tableList.getSelectedValue();
		activeTable = dKey;

		if(tableViews.get(dKey) == null) {
			tableViews.put(dKey, new BTableViewer(db, dKey));
			tableViews.get(dKey).list.addMouseListener(this);
		}
		
		if(!tableViews.get(dKey).isVisible()) {
			tableViews.get(dKey).setVisible(true);
			desktop.add(tableViews.get(dKey));
			try {
				tableViews.get(dKey).setSelected(true);
			} catch (java.beans.PropertyVetoException ex) {
				log.severe("Desktop show error : " + ex);
			}
		} else {
			try {
				tableViews.get(dKey).setSelected(true);
				if(tableViews.get(dKey).isIcon())
					tableViews.get(dKey).setIcon(false);
			} catch (java.beans.PropertyVetoException ex) {
				log.severe("Desktop show error : " + ex);
			}
		}

		table.setModel(tableViews.get(dKey).getTableModel());
		table.setFillsViewportHeight(true);
		table.setAutoCreateRowSorter(true);

		xmlText.setText(tableViews.get(dKey).getDeskConfig(0).getString());
		txtReportName.setText(activeTable);
	}

	public void addFields() {
		BTableViewer tv = (BTableViewer)desktop.getSelectedFrame();
		if(tv != null) activeTable = tv.getName();
		if(activeTable != null) {
			String dKey = tableViews.get(activeTable).getFieldName();
			int i = defModel.insertRow() - 1;
			defModel.setValueAt(activeTable, i, 0);
			defModel.setValueAt(dKey, i, 1);
			defModel.setValueAt("=", i, 2);
			defModel.setValueAt("Y", i, 4);
			defModel.refresh();

			buildQuery();
		}
	}

	public void buildQuery() {
		String selectSQL = null;
		String whereSQL = null;
		Map<String, Boolean> tblst = new HashMap<String, Boolean>();
		for(int i=0; i<defModel.getRowCount(); i++) {
			String tbName = defModel.getValueAt(i, 0).toString();
			String fldName = defModel.getValueAt(i, 1).toString();
			String filterType = defModel.getValueAt(i, 2).toString();
			String filterValue = defModel.getValueAt(i, 3).toString();
			String visible = defModel.getValueAt(i, 4).toString();
			if("Y".equals(visible)) {
				if(selectSQL == null) selectSQL = "SELECT ";
				else selectSQL += ", ";
				selectSQL += tbName + "." + fldName;
			}
			if(!"".equals(filterValue)) {
				if(whereSQL == null) whereSQL = "WHERE (";
				else whereSQL += " AND (" + tbName + "." + fldName;
				whereSQL += tbName + "." + fldName + filterType + "'" + filterValue + "')";
			}

			tblst.put(tbName, true);
		}

		// List all active links
		List<String> tbList = new ArrayList<String>(tblst.keySet());
		List<BTableLinks> tableLinks = new ArrayList<BTableLinks>();
		for(String tb : tblst.keySet()) {
			for(BTableLinks tl : tableViews.get(tb).getLinks(tbList)) {
				if(tl.isActive()) tableLinks.add(tl);
			}
		}

		// Get tables which are not linked
		for(String tb : tblst.keySet()) {
			for(BTableLinks tl : tableLinks) {
				if(tb.equals(tl.getKeyTable())) tblst.put(tb, false);
				if(tb.equals(tl.getForeignTable())) tblst.put(tb, false);
			}
		}

		// Get the sql list for non-linked tables 
		String fromSQL = null;
		for(String tb : tblst.keySet()) {
			if(tblst.get(tb)) {
				if(fromSQL == null) fromSQL = "\nFROM " + tb;
				else fromSQL += ", " + tb;
			}
		}

		// Get the sql list for linked tables 
		tbList = new ArrayList<String>();
		joinModel.clear();
		for(BTableLinks tl : tableLinks) {
			tl.setLinked(tbList);
			if(fromSQL == null) fromSQL = "\nFROM " + tl.toString();
			else fromSQL += "\n " + tl.toString();

			joinModel.insertRow(tl.getData());

			tbList.add(tl.getKeyTable());
			tbList.add(tl.getForeignTable());
		}

		selectSQL += fromSQL;
		if(whereSQL!=null) selectSQL += "\n" + whereSQL;
		sqlText.setText(selectSQL);
	}

	public void executeQuery() {
		String mysql =  sqlText.getText().trim();
		if(mysql.toUpperCase().startsWith("SELECT")) {
			tableModel = new BTableModel(db, mysql, -1);
			table.setModel(tableModel);
			table.setFillsViewportHeight(true);
			table.setAutoCreateRowSorter(true);

			xmlText.setText(tableModel.getTableConfig().toString());
		}
	}

	public void listTables() {
		List<String> tblist = db.getTables();
		List<String> vwlist = db.getViews();
		listModel.clear();
		for(String lst : tblist) listModel.addElement(lst);
		for(String lst : vwlist) listModel.addElement(lst);
	}

	public void exportData() {
		JFileChooser fc = new JFileChooser();
		int returnVal = fc.showSaveDialog(this);
		if ((tableModel != null) && (returnVal == JFileChooser.APPROVE_OPTION)) {
			String filename = fc.getSelectedFile().getAbsolutePath() + ".csv";
			tableModel.savecvs(filename);
		}
	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("Execute".equals(aKey)) {
			executeQuery();
		} else if("Export".equals(aKey)) {
			exportData();
		} else if ("New".equals(aKey)) {			
			defModel.clear();
		} else if ("Delete Field".equals(aKey)) {
			defModel.removeRow(defTable.getSelectedRow());
		} else if ("Refresh".equals(aKey)) {
			buildQuery();
		} else if ("Reload".equals(aKey)) {
			listTables();
		} else if ("View".equals(aKey)) {
			BTableViewer tv = (BTableViewer)desktop.getSelectedFrame();
			sqlText.setText(tv.getViewSQL());
		} else if ("Linked XML".equals(aKey)) {
			xmlText.setText(tableViews.get(activeTable).getDeskConfig(1).getString());
		} else if ("Portrait Report".equals(aKey)) {
			executeQuery();
			BReportMaker reportMaker = new BReportMaker();
			reportText.setText(reportMaker.makeReport(txtReportName.getText(), sqlText.getText(), tableModel.getQuery()));
			reportText.setCaretPosition(0);
		} else if ("Landscape Report".equals(aKey)) {
			executeQuery();
			BReportMaker reportMaker = new BReportMaker();
			reportText.setText(reportMaker.makeLandscapeReport(txtReportName.getText(), sqlText.getText(), tableModel.getQuery()));
			reportText.setCaretPosition(0);
		} else if("Sub Report".equals(aKey)) {
			executeQuery();
			BReportMaker reportMaker = new BReportMaker();
			reportText.setText(reportMaker.makeSubReport(txtReportName.getText(), sqlText.getText(), tableModel.getQuery()));
			reportText.setCaretPosition(0);
		} else if("Save Report".equals(aKey)) {
			String reportName = reportDir + txtReportName.getText() + ".jrxml";
			Bio io =  new Bio();
			int n = 0;
			if(io.FileExists(reportName)) {
				n = JOptionPane.showConfirmDialog(this, "You will overwrite and extisting report?", "Report overwrite", JOptionPane.YES_NO_OPTION);
			}
			if(n == 0) {
				io.saveFile(reportName, reportText.getText());
				BCompileReport cr = new BCompileReport(reportName);
			}
		}
	}

	public void mousePressed(MouseEvent ev) {}
	public void mouseReleased(MouseEvent ev) {}
	public void mouseEntered(MouseEvent ev) {}
	public void mouseExited(MouseEvent ev) {}
	public void mouseClicked(MouseEvent ev) {
		if (ev.getClickCount() == 2) {
			if(ev.getComponent() == tableList) showTable();
			else addFields();
		}
	}
}
	