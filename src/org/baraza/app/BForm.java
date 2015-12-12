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
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;

import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JButton;
import javax.swing.JOptionPane;
import javax.swing.JTabbedPane;
import javax.swing.JTable;
import javax.swing.JScrollPane;

import java.awt.BorderLayout;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.DB.BTableModel;
import org.baraza.utils.BLogHandle;

class BForm extends JPanel implements ActionListener {
	Logger log = Logger.getLogger(BForm.class.getName());
	BLogHandle logHandle;
	BQuery query;
	BTableModel auditModel;
	JTable auditTable;
	JScrollPane auditScrollPane;
	BDB db = null;
	
	List<BField> fields;
	Map<String, Integer> fieldMap;
	Map<String, JPanel> tabList;
	Map<String, String> inputParams;
	Map<String, String> params;

	
	JTabbedPane tabs;
	JPanel auditPanel;
	JButton btNew, btUpdate, btCancel, btDel, btFilter, btAudit;
	JLabel lblErr;
	String linkField = null;
	String linkValue = null;
	boolean isStarting = true;
	boolean canAdd = true;
	boolean canEdit = true;
	boolean canDel = true;
	boolean canAudit = true;
	boolean isFirst = true;
	boolean isLoading = true;

	public BForm(BLogHandle logHandle, BDB db, BElement view) {
		super(null);

		this.db = db;
		this.logHandle = logHandle;
		logHandle.config(log);

		linkField = view.getAttribute("linkfield");
		if(view.getName().equals("FORM")) {
			String formFilter = null;
			if(linkField != null) formFilter = linkField + " is null";
			query = new BQuery(db, view, formFilter, null);
		}

		params = new HashMap<String, String>();
		inputParams = new HashMap<String, String>();
		fieldMap = new HashMap<String, Integer>();
		if(view.getAttribute("inputparams") != null) {
			String paramArr[] = view.getAttribute("inputparams").toLowerCase().split(",");
			for(String param : paramArr) {
				String pItems[] = param.split("=");
				if(pItems.length == 2)
					inputParams.put(pItems[0].trim(), pItems[1].trim());
			}
		}

		fields = new ArrayList<BField>();
		tabList = new HashMap<String, JPanel>();
		tabs = new JTabbedPane();
		int i = 0;
		int lh = 10;
		for(BElement el : view.getElements()) {
			if(!el.getValue().equals("")) {
				fields.add(new BField(logHandle, db, el));
				String tabName = el.getAttribute("tab");
				if(tabName == null) {
					lh = fields.get(i).getY() + fields.get(i).getH();
					fields.get(i).addToPanel(this);
				} else {
					if(!tabList.containsKey(tabName)) {
						tabList.put(tabName, new JPanel(null));
						tabs.add(tabName, tabList.get(tabName));
					}
					fields.get(i).addToPanel(tabList.get(tabName));
				}
				fieldMap.put(el.getValue().trim(), i);
				
				// Addding an action listener
				if(fields.get(i).hadListener()) {
					fields.get(i).addActionListener(this);
				}
				i++;
			}
		}

		int tw = Integer.valueOf(view.getAttribute("tw", "700"));
		int th = Integer.valueOf(view.getAttribute("th", "300"));

		if(tabList.size()>0) {
			tabs.setBounds(0, lh+2, tw, th+8);
			lh += th + 10;
			super.add(tabs);
		}

		lh += 2;
		if(view.getName().equals("FORM")) {
			if(view.getAttribute("del") != null) canDel = false;
			if(view.getAttribute("delete") != null) canDel = false;
			if(view.getAttribute("audit") != null) canAudit = false;

			if(view.getAttribute("new") != null) {
				canAdd = false;
			} else {
				btNew = new JButton("New");
				btNew.addActionListener(this);
				btNew.setBounds(10, lh, 100, 20);
				super.add(btNew);
			}
			if(view.getAttribute("edit") != null) canEdit = false;

			if(canAdd || canEdit) {
				btUpdate = new JButton("Save");
				btUpdate.addActionListener(this);
				btUpdate.setBounds(125, lh, 100, 20);
				super.add(btUpdate);

				btCancel = new JButton("Cancel");
				btCancel.addActionListener(this);
				btCancel.setBounds(240, lh, 100, 20);
				super.add(btCancel);
			}

			if(canDel) {
				btDel = new JButton("Delete");
				btDel.addActionListener(this);
				btDel.setBounds(350, lh, 100, 20);
				super.add(btDel);
			}

			if(canAudit) {
				btAudit = new JButton("Audit");
				btAudit.addActionListener(this);
				btAudit.setBounds(470, lh, 100, 20);
				super.add(btAudit);
			}

			lh += 22;
			lblErr = new JLabel("");
			lblErr.setOpaque(true);
			lblErr.setBounds(10, lh, 500, 20);
			super.add(lblErr);

			lh += 22;
			auditPanel = new JPanel(new BorderLayout());
			auditPanel.setOpaque(true);
			auditPanel.setBounds(10, lh, 500, 100);
			super.add(auditPanel);

			auditModel = new BTableModel();
			auditTable = new JTable(auditModel);
			auditScrollPane = new JScrollPane(auditTable);
			auditPanel.add(auditScrollPane, BorderLayout.CENTER);
		} else if(view.getName().equals("FILTERFORM")) {
			btFilter = new JButton("Filter");
			btFilter.setBounds(10, lh, 100, 20);
			super.add(btFilter);
		}
	}

	public void link(String key, String linkValue) {
		this.linkValue = linkValue;
		for(BField field : fields) {
			field.setLinkData(linkValue);
			field.refresh();
		}

		filter(query.getKeyFieldName() + " = '" + key + "'", null);
		query.cancel();
		query.recEdit();
		lblErr.setText("");

		if(canAdd) btNew.setVisible(false);
		if(canDel) btDel.setVisible(true);
		if(canAudit) btAudit.setVisible(true);
		auditPanel.setVisible(false);
	}

	public void filter(String wheresql, String orderby) {
		isLoading = true;
		query.filter(wheresql, orderby);
		if(query.moveNext()) {
			for(BField field : fields) {
				field.setText(query.readField(field.getName()));
				if(field.hadListener()) {
					int fIdx = fieldMap.get(field.getComboLink());
					fields.get(fIdx).setLinkData(field.getText());
				}
			}
		}
		isLoading = false;
	}

	public void newRecord(String linkField, String linkValue, Map<String, String> passParams) {
		if(this.linkField == null) this.linkField = linkField;
		this.linkValue = linkValue;

		params.putAll(passParams);

		isLoading = true;
		for(BField field : fields) field.setLinkData(linkValue);
		isLoading = false;
		
		newRecord();
	}

	public void newRecord() {
		isLoading = true;
		for(BField field : fields) field.setNew();
		isLoading = false;
		
		query.cancel();
		query.recAdd();
		lblErr.setText("");

		if(linkField != null) query.updateField(linkField, linkValue);

		for (String param : inputParams.keySet()) {
			String inputParam = inputParams.get(param);
			query.updateField(param, params.get(inputParam));
		}

		if(canAdd) {
			btNew.setVisible(true);
			btUpdate.setVisible(true);
		}
		btDel.setVisible(false);
		if(canAudit) {
			btAudit.setVisible(false);
			auditPanel.setVisible(false);
		}
	}

	public void updateRecord() {
		String errMsg = "";
		for(BField field : fields) {
			errMsg += query.updateField(field.getName(), field.getText());
			errMsg += field.getErrMsg();
		}
		errMsg += query.recSave();
		if("".equals(errMsg)) errMsg = "Record is Updated";
		lblErr.setText(errMsg);
		query.moveFirst();
	}

	public void moveFirst() {
		query.moveFirst();
	}

	public void cancel() {
		query.cancel();
	}

	public void setData() {
		for(BField field : fields) field.setText(query.readField(field.getName()));
	}

	public void setListener(BFilter flt) {
		btFilter.addActionListener(flt);
	}

	public Map<String, String> getParam() {
		Map<String, String> param = new HashMap<String, String>();
		for(BField field : fields) param.put(field.getName(), field.getText());
		return param;
	}

	public String getWhere() {
		isFirst = true;
		String mystr = "";

		for(BField field : fields) mystr += makewhere(field.getName(), field.getText(), field.getFilter());

		return mystr;
	}

	private String makewhere(String name, String text, String filter) {
		String mystr = "";
		if(!text.equals("")) {
			if(isFirst) {isFirst = false; }
			else { mystr += " AND "; }

			if(filter == null) mystr += "(" + name + " ILIKE '%" + text + "%')";
			else mystr += "(" + name + " " + filter + " '" + text + "')";
		}

		return mystr;
	}

	public void showAudit() {
		String mysql = "SELECT entitys.entity_name, sys_audit_trail.user_id, sys_audit_trail.change_date, ";
		mysql += "sys_audit_trail.change_type, sys_audit_trail.user_ip ";
		if(db.getDBType() == 1) mysql += "FROM sys_audit_trail LEFT JOIN entitys ON sys_audit_trail.user_id  = CAST(entitys.entity_id as varchar) ";
		else mysql += "FROM sys_audit_trail LEFT JOIN entitys ON sys_audit_trail.user_id  = entitys.entity_id ";
		mysql += "WHERE (sys_audit_trail.table_name = '" + query.getTableName() + "') ";
		mysql += "AND (sys_audit_trail.record_id = '" + query.getKeyField() + "')";
		String mytitles[] = {"Done By", "ID", "Done On", "Change", "Source"};

		auditModel = new BTableModel(db, mysql, -1);
		auditModel.setTitles(mytitles);
		auditTable.setModel(auditModel);
		auditTable.setFillsViewportHeight(true);
		auditTable.setAutoCreateRowSorter(true);

		if(auditPanel.isVisible()) auditPanel.setVisible(false);
		else auditPanel.setVisible(true);
	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("New".equals(aKey)) {
			newRecord();
		} else if("Save".equals(aKey)) {
			updateRecord();
		} else if("Cancel".equals(aKey)) {
			cancel();
		} else if("Delete".equals(aKey)) {
			if(canDel) {
				int n = JOptionPane.showConfirmDialog(this, "Are you sure you want to delete the record?", "Deletion", JOptionPane.YES_NO_OPTION);
				if(n == 0) {
					String err = query.recDelete();
					if(err == null) {
						for(BField field : fields) field.setNew();
						lblErr.setText("The record is deleted.");

						if(canAdd) btNew.setVisible(true);
						btUpdate.setVisible(false);
						btDel.setVisible(false);
						btAudit.setVisible(false);
						auditPanel.setVisible(false);
					} else {
						lblErr.setText(err);
					}
				}
			}
		} else if("Audit".equals(aKey)) {
			showAudit();
		} else if(!isLoading && ("comboBoxChanged".equals(aKey))) {
			for(BField field : fields) {
				if(field.hadListener()) {
					int fIdx = fieldMap.get(field.getComboLink());
					fields.get(fIdx).setLinkData(field.getText());
				}
			}
		}
	}

	public boolean allowNew() { return canAdd; }
	public boolean allowEdit() { return canEdit; }
	
}
