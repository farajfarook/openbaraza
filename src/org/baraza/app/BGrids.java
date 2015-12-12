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
import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.io.IOException;
import java.sql.Timestamp;
import java.sql.Time;

import javax.swing.JPanel;
import javax.swing.JButton;
import javax.swing.JScrollPane;
import javax.swing.JTabbedPane;
import javax.swing.JTable;
import javax.swing.JCheckBox;
import javax.swing.JEditorPane;
import javax.swing.JTextField;
import javax.swing.JComboBox;
import javax.swing.JFileChooser;
import javax.swing.JOptionPane;
import javax.swing.text.html.HTMLEditorKit;
import javax.swing.text.html.StyleSheet;
import javax.swing.table.TableColumn;

import java.awt.BorderLayout;
import java.awt.GridLayout;
import java.awt.CardLayout;
import java.awt.FlowLayout;
import java.awt.print.PrinterException;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;

import org.baraza.xml.*;
import org.baraza.DB.*;
import org.baraza.swing.BTextIcon;
import org.baraza.reports.BReport;
import org.baraza.swing.BDateTimeRenderer;
import org.baraza.swing.BTimeRenderer;
import org.baraza.utils.BLogHandle;

class BGrids extends JPanel implements ActionListener, MouseListener {
	Logger log = Logger.getLogger(BGrids.class.getName());
	BLogHandle logHandle;
	JScrollPane scrollPane, editScrollPane;
	JTable table;
	JPanel cards, gridCards, gridControls, formControl, filterPanel, gridPanel, formPanel;
	JCheckBox checkAnd, checkOr;
	JButton btAction;
	List<JButton> gridFunct;
	List<BForm> forms;
	List<BGrids> grids;
	List<BReport> reports;
	List<BTabs> tabs;
	List<BBrowser> browsers;
	List<BFiles> files;
	BActions actions = null;

	JEditorPane editorPane, footerPane;
	HTMLEditorKit cssKit;
	StyleSheet styleSheet;
	JTabbedPane formsPane;
	JTextField filterData;
	JComboBox<String> fieldList, filterList, actionList;
	BTableModel tableModel;

	boolean reportMode = false;
	boolean importProcess = false;

	BElement view;
	BDB db;

	Map<String, String> linkParams;
	Map<String, String> params;
	String filterName = "filterid";
	String tableFilter = null;
	String linkFilter = null;
	String linkValue = null;
	String linkField = null;
	String importType = null;
	String updateTable = null;
	String viewFilter[] = new String[2];
	String noDel = null;

	public BGrids(BLogHandle logHandle, BDB db, BElement view, String reportDir, boolean nullFilter) {
		super(new BorderLayout());

		this.view = view;
		this.db = db;
		this.logHandle = logHandle;
		logHandle.config(log);

		filterName = view.getAttribute("filtername", "filterid");
		linkField = view.getAttribute("linkfield");
		importType = view.getAttribute("import");
		updateTable = view.getAttribute("update");
		noDel = view.getAttribute("del");
		String nfl = null;
		if(linkField != null) nfl = linkField + " is null";
		if(nullFilter) nfl = view.getAttribute("keyfield") + " is null";

		linkParams = new HashMap<String, String>();
		params = new HashMap<String, String>();

		if(view.getAttribute("linkparams") != null) {
			String paramArr[] = view.getAttribute("linkparams").toLowerCase().split(",");
			for(String param : paramArr) {
				String pItems[] = param.split("=");
				if(pItems.length == 2)
					linkParams.put(pItems[0].trim(), pItems[1].trim());
			}
		}
		if(view.getAttribute("viewfilter") != null) {
			String viewFs[] = view.getAttribute("viewfilter").toLowerCase().split(",");
			for(String vfa : viewFs) {
				String viewF[] = vfa.split("=");
				if(viewF.length == 2) {
					viewFilter[0] = viewF[0];
					viewFilter[1] = viewF[1];
				} else {
					viewFilter[0] = null;
					viewFilter[1] = null;
				}
			}
		} else {
			viewFilter[0] = null;
			viewFilter[1] = null;
		}

		tableModel = new BTableModel(db, view, nfl);
		table = new JTable(tableModel);
		table.setFillsViewportHeight(true);
		table.setAutoCreateRowSorter(true);
		table.addMouseListener(this);

		// change the formater
		table.setDefaultRenderer(Timestamp.class, new BDateTimeRenderer());
		table.setDefaultRenderer(Time.class, new BTimeRenderer());

		if(updateTable == null) {
			if(tableModel.getTableName().toLowerCase().startsWith("vw_")) {
				updateTable = tableModel.getTableName().replace("vw_", "").trim();
				if(!db.getTables().contains(updateTable)) updateTable = null;
			}
		}

		//Create the scroll pane and add the table to it.
		scrollPane = new JScrollPane(table);
		formsPane = new JTabbedPane(JTabbedPane.RIGHT);
		formsPane.addMouseListener(this);
		forms = new ArrayList<BForm>();
		grids = new ArrayList<BGrids>();
		reports = new ArrayList<BReport>();
		tabs = new ArrayList<BTabs>();
		browsers = new ArrayList<BBrowser>();
		files = new ArrayList<BFiles>();
		
		editorPane = new JEditorPane();
		editScrollPane = new JScrollPane(editorPane);
		editorPane.setContentType("text/html");
		editorPane.setEditable(false);
		cssKit = new HTMLEditorKit();
		editorPane.setEditorKit(cssKit);
		StyleSheet styleSheet = cssKit.getStyleSheet();
		styleSheet.addRule("h1 {color: blue;}\n");
		styleSheet.addRule("table{border-spacing: 0px; border-collapse: collapse; width: 100%; }\n");
		styleSheet.addRule("th {text-align: left; font-weight: bold; padding: 1px; border: 1px solid #FFFFFF; background: #4a70aa; color: #FFFFFF; }\n");
		styleSheet.addRule("th {border-color: #FFFFFF;border-width: 1px 1px 0 0; border-style; solid thin;}\n");
		styleSheet.addRule("tr {text-align: left; padding: 1px; border: 1px solid #FFFFFF; background: #e3f0f7; }\n");
		styleSheet.addRule("tr.alt {background: #f7f7f7; }\n");
		styleSheet.addRule("td {border-color: #FFFFFF;border-width: 1px 1px 0 0; border-style; solid thin; }\n");

		for(BElement el : view.getElements()) {
			if(el.getName().equals("FORM")) {
				forms.add(new BForm(logHandle, db, el));
				tabs.add(new BTabs(1, forms.size()-1));

				String paneName = el.getAttribute("name");
				BTextIcon textIcon = new BTextIcon(formsPane, paneName, BTextIcon.ROTATE_RIGHT);
				formsPane.addTab("", textIcon, forms.get(forms.size()-1));
			} else if(el.getName().equals("GRID")) {
				grids.add(new BGrids(logHandle, db, el, reportDir, nullFilter));
				tabs.add(new BTabs(2, grids.size()-1));

				String paneName = el.getAttribute("name");
				BTextIcon textIcon = new BTextIcon(formsPane, paneName, BTextIcon.ROTATE_RIGHT);
				formsPane.addTab("", textIcon, grids.get(grids.size()-1));
			} else if(el.getName().equals("JASPER")) {
				reports.add(new BReport(logHandle, db, el, reportDir));
				tabs.add(new BTabs(3, reports.size()-1));

				String paneName = el.getAttribute("name");
				BTextIcon textIcon = new BTextIcon(formsPane, paneName, BTextIcon.ROTATE_RIGHT);
				formsPane.addTab("", textIcon, reports.get(reports.size()-1));
			} else if(el.getName().equals("BROWSER")) {
				browsers.add(new BBrowser(el));
				tabs.add(new BTabs(4, browsers.size()-1));

				String paneName = el.getAttribute("name");
				if(paneName == null) paneName = el.getAttribute("title");
				BTextIcon textIcon = new BTextIcon(formsPane, paneName, BTextIcon.ROTATE_RIGHT);
				formsPane.addTab("", textIcon, browsers.get(browsers.size()-1));
			} else if(el.getName().equals("FILES")) {
				files.add(new BFiles(logHandle, db, el));
				tabs.add(new BTabs(4, files.size()-1));

				String paneName = el.getAttribute("name");
				BTextIcon textIcon = new BTextIcon(formsPane, paneName, BTextIcon.ROTATE_RIGHT);
				formsPane.addTab("", textIcon, files.get(files.size()-1));
			} else if(el.getName().equals("ACTIONS")) {
				actions = new BActions(logHandle, el, db);
			}
		}

		// create filter panel on grid
		filterPanel = new JPanel(new FlowLayout()); //GridLayout(1, 0));
		filterData = new JTextField(15);
		filterData.setActionCommand("Filter");
		filterData.addActionListener(this);
		String[] filterstr = {"ILIKE", "LIKE", "=", ">", "<", "<=", ">="};	
		fieldList = new JComboBox<String>(tableModel.getColumnNames());
		filterList = new JComboBox<String>(filterstr);
		checkAnd = new JCheckBox("And"); 
		checkOr = new JCheckBox("Or");

		filterPanel.add(fieldList);
		filterPanel.add(filterList);
		filterPanel.add(filterData);
		filterPanel.add(checkAnd);
		filterPanel.add(checkOr);

		if(actions != null) {
			btAction = new JButton("Action");
			btAction.addActionListener(this);
			actionList = new JComboBox<String>(actions.getActions());

			filterPanel.add(btAction);
			filterPanel.add(actionList);
		}
		
		boolean canDel = true;
		if(view.getAttribute("del") != null) canDel = false;
		if(view.getAttribute("delete") != null) canDel = false;

		gridFunct = new ArrayList<JButton>();
		gridControls =  new JPanel();
		gridFunct.add(new JButton("New"));
		gridFunct.add(new JButton("Refresh"));
		if(canDel) gridFunct.add(new JButton("Delete"));
		gridFunct.add(new JButton("Export"));

		BElement impEl = view.getElementByName("IMPORT");
		if(impEl != null) gridFunct.add(new JButton("Import"));
		if(importType != null) gridFunct.add(new JButton("Import"));

		gridFunct.add(new JButton("Report"));
		gridFunct.add(new JButton("Print"));
		for(JButton btn : gridFunct) { gridControls.add(btn); btn.addActionListener(this); }

		gridCards = new JPanel(new CardLayout());
		gridCards.add(scrollPane, "grid");
		gridCards.add(editScrollPane, "report");

		gridPanel = new JPanel(new BorderLayout());
		gridPanel.add(gridControls, BorderLayout.PAGE_START);
		gridPanel.add(gridCards, BorderLayout.CENTER);
		gridPanel.add(filterPanel, BorderLayout.PAGE_END);

		footerPane = new JEditorPane();
		footerPane.setContentType("text/html");
		footerPane.setEditorKit(cssKit);

		formPanel = new JPanel(new BorderLayout());
		formPanel.add(formsPane, BorderLayout.CENTER);
		formPanel.add(footerPane, BorderLayout.PAGE_END);

		cards = new JPanel(new CardLayout());
		cards.add(gridPanel, "grid");
		cards.add(formPanel, "form");

		super.add(cards, BorderLayout.CENTER);
		adjustWidth();
	}

	public void exportData() {
		JFileChooser fc = new JFileChooser();
		int returnVal = fc.showSaveDialog(this);
		if (returnVal == JFileChooser.APPROVE_OPTION) {
			String filename = fc.getSelectedFile().getAbsolutePath() + ".csv";
			tableModel.savecvs(filename);
		}
	}

	public void showForms() {
		CardLayout cl = (CardLayout)(cards.getLayout());
        cl.show(cards, "form");
	}

	public void hideForms() {
		CardLayout cl = (CardLayout)(cards.getLayout());
        cl.show(cards, "grid");
	}

	public void showReport() {
		int j = 0;
		for(JButton button : gridFunct)
			if((j++) < 3) button.setEnabled(reportMode);

		if(reportMode) {
			CardLayout cl = (CardLayout)(gridCards.getLayout());
			cl.show(gridCards, "grid");
			reportMode = false;
		} else {
			CardLayout cl = (CardLayout)(gridCards.getLayout());
			cl.show(gridCards, "report");
			reportMode = true;

			String mypage = "<html><body>" + tableModel.readDocument(true, false) + "</body></html>";
			editorPane.setText(mypage);
			editorPane.setCaretPosition(0);
		}
	}

	public void deleteRecords() {
		int n = JOptionPane.showConfirmDialog(this, "Are you sure you want to delete the record?", "Deletion", JOptionPane.YES_NO_OPTION);
		if(n == 0) {
			int[] selection = table.getSelectedRows();
			Arrays.sort(selection);
			int i = 1;
			for(int sel : selection) {
				int index = table.convertRowIndexToModel(sel) + i;
				i--;
				tableModel.movePos(index);
				if(updateTable == null) { 
					tableModel.recDelete();
				} else {
					tableModel.recAudit("DELETE", tableModel.getKeyField());
					String mysql = "DELETE FROM " + updateTable;
					mysql += " WHERE " + tableModel.getKeyFieldName() + " = '" +  tableModel.getKeyField() + "'";
					db.executeQuery(mysql);
				}
			}
			tableModel.requery();
		}
	}

	public void filter() {
		String wheresql = "(";
		String filterStr = null;
		if(linkField != null) filterStr = "(" + linkField + " = '" + linkValue + "')";
		for(String param : linkParams.keySet()) {
			if(filterStr == null) filterStr = "(";
			else filterStr += " AND (";
			if(params.get(param) == null) filterStr += linkParams.get(param) + " = null)";
			else filterStr += linkParams.get(param) + " = '" + params.get(param) + "')";
		}

		if(tableFilter != null) {
			if(checkOr.isSelected()) wheresql = tableFilter + " OR (";
			if(checkAnd.isSelected()) wheresql = tableFilter + " AND (";
		}

		wheresql += tableModel.getFieldName(fieldList.getSelectedIndex());
		wheresql += " " + filterList.getSelectedItem();
		if(filterList.getSelectedIndex() < 2) wheresql += " '%" + filterData.getText() + "%')";
		else wheresql += " '" + filterData.getText() + "')";
		tableFilter = wheresql;

		if(filterStr != null) wheresql = "(" + filterStr + ") AND (" + wheresql + ")";

		tableModel.filter(wheresql, null);
		if(reportMode) {
			String mypage = "<html><body>" + tableModel.readDocument(true, false) + "</body></html>";
			editorPane.setText(mypage);
			editorPane.setCaretPosition(0);
		}
		adjustWidth();
	}

	public void link(String linkValue, Map<String, String> passParams, Map<String, String> queryParams) {
		this.linkValue = linkValue;

		params.putAll(passParams);
		params.putAll(queryParams);

		hideForms();
		filter(null);
	}

	public void filter(String wheresql) {
		String filterStr = wheresql;
		if(linkField != null) {
			if(filterStr == null) filterStr = "(";
			else filterStr += " AND (";
			filterStr += linkField + " = '" + linkValue + "')";
		}

		for(String param : linkParams.keySet()) {
			if(filterStr == null) filterStr = "(";
			else filterStr += " AND (";
			if(params.get(param) == null) filterStr += linkParams.get(param) + " = null)";
			else filterStr += linkParams.get(param) + " = '" + params.get(param) + "')";
		}

		tableModel.filter(filterStr, null);
		tableModel.refresh();
	}

	public void importData() {
		System.out.println("Import Data");

		if(importProcess) {
			if(view.getAttribute("process") != null) {
				String updSQL = "SELECT " + view.getAttribute("process");
				updSQL += "('" + db.getOrgID() + "', '" + db.getUserID() + "', '" + db.getUserIP() + "')";
				System.out.println(updSQL);
				db.executeQuery(updSQL);
			}

			refresh();
			gridFunct.get(4).setText("Import");
			importProcess = false;
		} else {
			BElement impEl = view.getElementByName("IMPORT");
			if(impEl != null) {
				BDB impDB = new BDB(impEl);
				BQuery impQuery = new BQuery(impDB, impEl, null, null);

				tableModel.importData(impQuery.getData());
				tableModel.requery();
				impQuery.close();
				impDB.close();
			} else if(importType != null) {
				if(importType.equals("excel")) {
					BImportModel impExcel = new BImportModel(view);
					String worksheet = view.getAttribute("worksheet", "0");
					impExcel.getExcelData(this, worksheet);

					tableModel.importData(impExcel.getData());
					tableModel.requery();
					impExcel.close();
				} else if(importType.equals("text")) {
					BImportModel impcsv = new BImportModel(view);
					impcsv.getTextData(this, view.getAttribute("delimiter"));

					tableModel.importData(impcsv.getData());
					tableModel.requery();
					impcsv.close();
				} else if(importType.equals("record")) {
					BImportModel imprec = new BImportModel(view);
					imprec.getRecordData(this);

					tableModel.importData(imprec.getData());
					tableModel.requery();
					imprec.close();
				}
			}

			refresh();
			gridFunct.get(4).setText("Process");
			importProcess = true;
		}

	}

	public void refresh() {
		filter(null);

		if(reportMode) {
			String mypage = "<html><body>" + tableModel.readDocument(true, false) + "</body></html>";
			editorPane.setText(mypage);
			editorPane.setCaretPosition(0);
		}
		adjustWidth();
	}

	public void adjustWidth() {
		// adjust column width
		int i = 0;
		for(BElement el : view.getElements()) {
			if(!el.getValue().equals("")) {
				int w = Integer.valueOf(el.getAttribute("w", "40"));
				TableColumn column = table.getColumnModel().getColumn(i);
				column.setPreferredWidth(w);
				i++;
			}
		}
	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("New".equals(aKey)) {
			if(forms.size() > 0) {
				for(BForm form : forms) {
					if(form.allowNew())
						form.newRecord(linkField, linkValue, params);
				}
				int i = 0; 
				for(BTabs tab : tabs) {
					if(tab.getType() == 1) {
						if(tab.getIndex() == 0) formsPane.setSelectedIndex(i);
					} else {
						formsPane.setEnabledAt(i, false);
					}
					i++;
				}
		
				showForms();
			}
		} else if("Refresh".equals(aKey)) {
			refresh();
		} else if("Delete".equals(aKey)) {
			if(noDel == null) deleteRecords();
		} else if("Export".equals(aKey)) {
			exportData();
		} else if("Filter".equals(aKey)) {
			filter();
		} else if("Import".equals(aKey)) {
			importData();
		} else if("Process".equals(aKey)) {
			importData();
		} else if("Action".equals(aKey)) {
			actions.execproc(actionList.getSelectedIndex(), getKey(), linkValue);
			tableModel.requery();
		} else if("Report".equals(aKey)) {
			showReport();
		} else if("Print".equals(aKey)) {
			showReport();
			try {
				editorPane.print();
			} catch(PrinterException ex) {
				log.severe("Report Printing Error : " + ex);
			}
		}
	}

	public JTable getTable() {
		return table;
	}

	public String getFilterName() {
		return filterName;
	}

	public String getKey() {
		String key = null;
		int aRow = table.getSelectedRow();
		if (aRow != -1) {
			int index = table.convertRowIndexToModel(aRow) + 1;
			tableModel.movePos(index);
			key = tableModel.getKeyField();
		}

		return key;
	}

	public String[] getViewFilter() {
		return viewFilter;
	}

	public void mousePressed(MouseEvent ev) {}
	public void mouseReleased(MouseEvent ev) {}
	public void mouseEntered(MouseEvent ev) {}
	public void mouseExited(MouseEvent ev) {}
	public void mouseClicked(MouseEvent ev) {
		if(ev.getComponent().equals(table)) {
			int aRow = table.getSelectedRow();
			if ((aRow != -1) && (ev.getClickCount() == 2) && (tabs.size() > 0)) {
				int index = table.convertRowIndexToModel(aRow) + 1;
				tableModel.movePos(index);
				String key = tableModel.getKeyField();
				String keyField = tableModel.getKeyFieldName();

				if(key != null) {
					for(BForm form : forms) {
						if(form.allowEdit()) form.link(key, linkValue);
					}
					for(BGrids grid : grids) grid.link(key, params, tableModel.getParams());
					for(BReport report : reports) {
						report.putparams(filterName, key);
						report.drillReport();
					}
					for(BBrowser browser : browsers) browser.setPage(key);
					for(BFiles file : files) file.link(key, tableModel.getParams());

					BQuery ft = new BQuery(db, view, keyField + " = '" + key + "'", null);
					footerPane.setText("<html><body><table>" + ft.readDocument(false, true) + "</table></html>");
					footerPane.setCaretPosition(0);
					ft.close();
				}

				int i = 0;
				int j = -1;
				boolean showTabs = false;
				for(BTabs tab : tabs) {
					if(tab.getType() == 1) {
						if(!forms.get(tab.getIndex()).allowEdit()) {
							formsPane.setEnabledAt(i, false);
						} else {
							formsPane.setEnabledAt(i, true);
							showTabs = true;
						}
					} else if(tab.getType() == 2) {
						String vft = grids.get(tab.getIndex()).getViewFilter()[0];
						String vfv = grids.get(tab.getIndex()).getViewFilter()[1];
						if((vft != null) && (vfv != null)) {
							if(vfv.equals(tableModel.getParams().get(vft))) {
								formsPane.setEnabledAt(i, true);
								showTabs = true;
							} else {
								formsPane.setEnabledAt(i, false);
							}	
						} else {
							formsPane.setEnabledAt(i, true);
							showTabs = true;
						}
					} else if(tab.getType() == 3) {
						String vft = reports.get(tab.getIndex()).getViewFilter()[0];
						String vfv = reports.get(tab.getIndex()).getViewFilter()[1];
						if((vft != null) && (vfv != null)) {
							if(vfv.equals(tableModel.getParams().get(vft))) {
								formsPane.setEnabledAt(i, true);
								showTabs = true;
							} else {
								formsPane.setEnabledAt(i, false);
							}	
						} else {
							formsPane.setEnabledAt(i, true);
							showTabs = true;
						}
					} else {
						formsPane.setEnabledAt(i, true);
						showTabs = true;
					}
					if(showTabs && (j==-1)) j = i;
					i++;
				}
				if(j==-1) j = 0;
				formsPane.setSelectedIndex(j);

				if(showTabs) showForms();
			}
		} else if(ev.getComponent().equals(formsPane)) {
			int i = formsPane.getSelectedIndex();

			if(tabs.get(i).getType() == 2) {
				int j = tabs.get(i).getIndex();
				grids.get(j).hideForms();
				grids.get(j).refresh();
			}

			if(tabs.get(i).getType() == 3) {
				int j = tabs.get(i).getIndex();
				reports.get(j).drillReport();
			}
		}
	}

}
