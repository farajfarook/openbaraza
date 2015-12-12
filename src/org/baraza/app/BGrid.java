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
import java.util.Vector;
import java.util.List;
import java.util.ArrayList;
import java.sql.Timestamp;
import java.sql.Time;

import javax.swing.JPanel;
import javax.swing.JTable;
import javax.swing.table.TableColumn;
import javax.swing.JScrollPane;
import javax.swing.JComboBox;
import javax.swing.JCheckBox;
import javax.swing.JTextField;
import javax.swing.JTabbedPane;
import javax.swing.JButton;

import java.awt.CardLayout;
import java.awt.BorderLayout;
import java.awt.FlowLayout;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;

import org.baraza.xml.*;
import org.baraza.DB.*;
import org.baraza.reports.BReport;
import org.baraza.swing.BTextIcon;
import org.baraza.swing.BDateTimeRenderer;
import org.baraza.swing.BTimeRenderer;
import org.baraza.utils.BLogHandle;

class BGrid extends JPanel implements ActionListener, MouseListener {
	Logger log = Logger.getLogger(BGrid.class.getName());
	BLogHandle logHandle;
	BTableModel tableModel;
	JTable table;
	JPanel mainPanel, filterPanel;
	JComboBox<String> fieldList, filterList;
	JCheckBox checkAnd, checkOr;
	JTextField filterData;
	JScrollPane scrollPane;
	JTabbedPane gridPane;
	JButton btPrintAll;
	List<BGrid> grids;

	BDB db;
	BElement view;
	String filterName = "filterid";
	String tableFilter = null;
	String linkValue = null;
	String linkField = null;
	String linkFnct = null;
	String update = null;

	public BGrid(BLogHandle logHandle, BDB db, BElement view, String reportDir) {
		super(new CardLayout());
		mainPanel = new JPanel(new BorderLayout());

		this.db = db;
		this.view = view;
		this.logHandle = logHandle;
		logHandle.config(log);

		filterName = view.getAttribute("filter", "filterid");
		linkField = view.getAttribute("linkfield");
		linkFnct = view.getAttribute("linkfnct");
		update = view.getAttribute("update");		
		tableFilter = null;
		if(linkField != null) tableFilter = linkField + " = null";

		tableModel = new BTableModel(db, view, tableFilter);
		table = new JTable(tableModel);
		table.addMouseListener(this);
		table.setFillsViewportHeight(true);
		table.setAutoCreateRowSorter(true);

		// change the formater
		table.setDefaultRenderer(Timestamp.class, new BDateTimeRenderer());
		table.setDefaultRenderer(Time.class, new BTimeRenderer());

		scrollPane = new JScrollPane(table);
		mainPanel.add(scrollPane, BorderLayout.CENTER);

		// create filter panel on grid
		filterPanel = new JPanel(new FlowLayout()); //GridLayout(1, 0));

		if(view.getName().equals("FILTERGRID")) {
			btPrintAll =  new JButton("Print All");
			filterPanel.add(btPrintAll);
		}

		filterData = new JTextField(25);
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
		mainPanel.add(filterPanel, BorderLayout.PAGE_END);

		gridPane = new JTabbedPane(JTabbedPane.RIGHT);
		gridPane.addMouseListener(this);
		grids = new ArrayList<BGrid>();
		for(BElement el : view.getElements()) {
			if(el.getName().equals("FILTERGRID")) {
				grids.add(new BGrid(logHandle, db, el, reportDir));

				String paneName = el.getAttribute("name");
				BTextIcon textIcon = new BTextIcon(gridPane, paneName, BTextIcon.ROTATE_RIGHT);
				gridPane.addTab("", textIcon, grids.get(grids.size()-1));
			}
		}

		super.add(mainPanel, "main");
		super.add(gridPane, "grid");
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

	public String getKey() {
		String key = null;
		if(grids.size() == 0) {
			int aRow = table.getSelectedRow();
			if (aRow != -1) {
				int index = table.convertRowIndexToModel(aRow) + 1;
				tableModel.movePos(index);
				key = tableModel.getKeyField();
			}
		} else {
			int i = gridPane.getSelectedIndex();
			key = grids.get(i).getKey();
		}

		return key;
	}

	public String readField(String fieldName) {
		return tableModel.readField(fieldName);
	}

	public Vector<String> getKeys() {
		Vector<String> keys = new Vector<String>();
		if(grids.size() == 0) {
			keys = tableModel.getKeyFieldData();
		} else {
			int i = gridPane.getSelectedIndex();
			keys = grids.get(i).getKeys();
		}

		return keys;
	}

	public String getFilterName() { return filterName; }
	public String getUpdate() { return update; }

	public void refresh() {
		if((linkField != null) && (linkValue != null)) {
			if(linkFnct == null) {
				tableFilter = linkField + " = '" + linkValue + "'";
			} else {
				String updSQL = "SELECT " + linkFnct + "('" + linkValue + "')";
				tableFilter = linkField + " = '" + db.executeFunction(updSQL) + "'";
			}
		}

		tableModel.filter(tableFilter, null);
		adjustWidth();
	}

	public void setLinkData(String lkdata) {
		linkValue = lkdata;
	}

	public void actionPerformed(ActionEvent ev) {
		String wheresql = null;
		if(tableFilter == null) wheresql = "";
		else if(checkAnd.isSelected()) wheresql = tableFilter + " AND ";
		else if(checkOr.isSelected()) wheresql = tableFilter + " OR ";
		else wheresql = "";

		wheresql += tableModel.getFieldName(fieldList.getSelectedIndex());
		wheresql += " " + filterList.getSelectedItem();
		if(filterList.getSelectedIndex() < 2) wheresql += " '%" + filterData.getText() + "%'";
		else wheresql += " '" + filterData.getText() + "'";
		tableFilter = wheresql;

		wheresql = null;
		if((linkField != null) && (linkValue != null)) {
			if(linkFnct == null) {
				wheresql = linkField + " = '" + linkValue + "'";
			} else {
				String updSQL = "SELECT " + linkFnct + "('" + linkValue + "')";
				wheresql = linkField + " = '" + db.executeFunction(updSQL) + "'";
			}
		}
		if(wheresql == null) wheresql = tableFilter;
		else wheresql = "(" + wheresql + ") AND " + tableFilter;

		tableModel.filter(wheresql, null);
		adjustWidth();
	}

	public void link(String linkValue) {
		tableModel.filter(linkField + " = '" + linkValue + "'", null);
		this.linkValue = linkValue;
	}

	public void showMain() {
		CardLayout cl = (CardLayout)(this.getLayout());
		cl.show(this, "main");
	}

	public void setListener(BFilter flt) {
		table.addMouseListener(flt);
		for(BGrid grid : grids) grid.setListener(flt);

		btPrintAll.addActionListener(flt);
	}

	public void setListener(BGridBox bgb) {
		table.addMouseListener(bgb);
		for(BGrid grid : grids) grid.setListener(bgb);
	}

	public void mousePressed(MouseEvent ev) {}
	public void mouseReleased(MouseEvent ev) {}
	public void mouseEntered(MouseEvent ev) {}
	public void mouseExited(MouseEvent ev) {}
	public void mouseClicked(MouseEvent ev) {
		if(ev.getComponent().equals(table)) {
			int aRow = table.getSelectedRow();
			if ((aRow != -1) && (ev.getClickCount() == 2) && (grids.size() >0)) {
				int index = table.convertRowIndexToModel(aRow) + 1;
				tableModel.movePos(index);
				String key = tableModel.getKeyField();
				if(key != null) {
					for(BGrid grid : grids) grid.link(key);

					CardLayout cl = (CardLayout)(this.getLayout());
					cl.show(this, "grid");
				}
			}
		} else if(ev.getComponent().equals(gridPane)) {
			showMain();
		}
	}

}