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
import org.baraza.DB.BQuery;

import javax.swing.JComboBox;

import java.util.List;
import java.util.ArrayList;

public class BComboBox extends JComboBox<String> {
	BQuery query;
	String sql;
	String name, cmb_fnct, lptable, lpfield, lpkey, wheresql, ordersql, defaultValue, linkCombo;
	String linkField, linkFnct;
	String linkValue = null;
	List<String> lplist;

    public BComboBox(BDB db, BElement el) {
		super();
	
		lplist = new ArrayList<String>();		
		
		name = el.getValue();
		lpkey = el.getAttribute("lpkey", "");
		if(lpkey.equals("")) lpkey = name;

		cmb_fnct = el.getAttribute("cmb_fnct");
		lptable = el.getAttribute("lptable");
		lpfield = el.getAttribute("lpfield");
		wheresql = el.getAttribute("where");
		ordersql = el.getAttribute("orderby");
		linkField = el.getAttribute("linkfield");
		linkFnct = el.getAttribute("linkfnct");
		defaultValue = el.getAttribute("default");
		linkCombo = el.getAttribute("linkcombo");

		if(lpkey.equals(lpfield)) sql = "SELECT " + lpfield + " FROM " + lptable;
		else if (cmb_fnct == null) sql = "SELECT " + lpkey + ", " + lpfield + " FROM " + lptable;
		else sql = "SELECT " + lpkey + ", (" + cmb_fnct + ") as " + lpfield + " FROM " + lptable;

		if(el.getAttribute("noorg") == null) {
			String orgID = db.getOrgID(); 
			String userOrg = db.getUserOrg(); 
			if((orgID != null) && (userOrg != null)) {
				if(wheresql == null) wheresql = "(";
				else wheresql += " AND (";
				wheresql += orgID + "=" + userOrg + ")";
			}
		}

		if(el.getAttribute("user") != null) {
			String userFilter = "(" + el.getAttribute("user") + " = '" + db.getUserID() + "')";
			if(wheresql == null) wheresql = userFilter;
			else wheresql += " AND " + userFilter;
		}

		if(wheresql != null) sql += " WHERE " + wheresql;
		if(ordersql != null) sql += " ORDER BY " + ordersql;  
		else sql += " ORDER BY " + lpfield;

		query = new BQuery(db, sql);
		getList();

		if (el.getAttribute("editable") != null) super.setEditable(true);
		if (el.getAttribute("disabled") != null) super.setEnabled(false);
 	}

	public void setBounds(int x, int y, int w, int h) {
		super.setBounds(x, y, w, h);
	}

	public void setLinkData(String lkdata) {
		if(lpkey.equals(lpfield)) sql = "SELECT " + lpfield + " FROM " + lptable;
		else if (cmb_fnct == null) sql = "SELECT " + lpkey + ", " + lpfield + " FROM " + lptable;
		else sql = "SELECT " + lpkey + ", (" + cmb_fnct + ") as " + lpfield + " FROM " + lptable;

		String tableFilter = null;
		linkValue = lkdata;
		if((linkField != null) && (linkValue != null)) {
			if(linkFnct == null) tableFilter = linkField + " = '" + linkValue + "'";
			else tableFilter = linkField + " = " + linkFnct + "('" + linkValue + "')";
		}

		if(wheresql != null) {
			sql += " WHERE (" + wheresql + ")";
			if (tableFilter != null) sql += " AND (" + tableFilter + ")";
		} else if (tableFilter != null) {
			sql += " WHERE (" + tableFilter + ")";
		}
		if(ordersql != null) sql += " ORDER BY " + ordersql;  
		else sql += " ORDER BY " + lpfield;
		
		query.setSQL(sql);

		// Get filtered list
		getList();
	}

	public void getList() {
		super.removeAllItems();
		lplist.clear();

		query.refresh();
		while(query.moveNext()) {
			lplist.add(query.getString(lpkey));
			super.addItem(query.getString(lpfield));
		}

		if(defaultValue != null) setText(defaultValue);
	}
	
	public void setText(String ldata) {
		if(ldata==null) ldata = "";

		if (super.isEditable()) {
			super.setSelectedItem(ldata);
		} else  {
			int lp = lplist.indexOf(ldata);
			super.setSelectedIndex(lp);
		}
	}

	public String getText() {
		String combovalue = "";
		if(super.getSelectedIndex() == -1) {
			combovalue = "";
		} else if (super.isEditable()) {
			combovalue = super.getSelectedItem().toString();
		} else {
			int lp = super.getSelectedIndex();
			combovalue = lplist.get(lp);
		}
		
		return combovalue;
	}
	
	public boolean hadListener() {
		boolean isListener = false;
		if(linkCombo != null) {
			isListener = true;
		}
		
		return isListener;
	}
	
	public String getComboLink() { return linkCombo; }

}
