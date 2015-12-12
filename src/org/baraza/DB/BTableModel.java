/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.DB;

import org.baraza.xml.BElement;

import java.util.Vector;
import java.util.List;
import java.util.Map;

import javax.swing.table.AbstractTableModel;
import javax.swing.event.TableModelEvent;

public class BTableModel extends AbstractTableModel {
	BQuery query;
	boolean editCell = false;

	public BTableModel() {
		query = new BQuery();
		editCell = true;
	}

	public BTableModel(String[] titleArray) {
		query = new BQuery(titleArray);
		refresh();
		editCell = true;
	}

	public BTableModel(BDB db, BElement desk) {
		query = new BQuery(db, desk, null, null);
	}

	public BTableModel(BDB db, BElement desk, String wherefilter) {
		query = new BQuery(db, desk, wherefilter, null);
	}

	public BTableModel(BDB db, String mysql, int limit) {
		query = new BQuery(db, mysql, limit);
		query.readData(limit);
	}

	public BTableModel(BDB db, String myfields, String tablename, int limit) {
		query = new BQuery(db, myfields, tablename, limit);
		query.readData(limit);
	}

	public void setQuery(BQuery query) {
		this.query = query;
		fireTableChanged(null);
	}	

    public boolean isCellEditable(int aRow, int aCol) {
		editCell = false;

		if(query.getColumnEdits().size() > aCol) {
			editCell = query.getColumnEdits().get(aCol);
		}
		return editCell;
    }

    public void setValueAt(Object value, int aRow, int aCol) {
		query.setValueAt(value, aRow, aCol);

        fireTableCellUpdated(aRow, aCol);
    }

	public void removeRow(int aRow) {
		query.removeRow(aRow);
		refresh();
	}

	public void refresh() { // Get all rows.
		fireTableChanged(null); // Tell the listeners a new table has arrived.
	}

	public void requery() {
		query.refresh();
		query.readData();
		refresh();
	}

	public void filter(String wheresql, String orderby) {
		query.filter(wheresql, orderby);
		query.readData();
		refresh();
	}

	public void clear() { // clear all rows.
		query.clear();
		refresh();
	}

	public int getColumnCount() { return query.getColumnCount(); }
    public int getRowCount() { return query.getRowCount(); }
    public String getColumnName(int aCol) { return query.getColumnName(aCol); }
	public String getFieldName(int aCol) { return query.getFieldName(aCol); }
	public Vector<String> getColumnNames() { return query.getColumnNames(); }
    public Object getValueAt(int aRow, int aCol) { return query.getValueAt(aRow, aCol); }
    public Class getColumnClass(int aCol) { return query.getColumnClass(aCol); }
	public Vector<String> getKeyFieldData() { return query.getKeyFieldData(); }

	public boolean movePos(int pos) { return query.movePos(pos); }
	public String getKeyField() { return query.getKeyField(); }
	public String getKeyFieldName() { return query.getKeyFieldName(); }
	public String readField(String fieldName) { return query.readField(fieldName); }
	public int insertRow() { return query.insertRow(); }
	public int insertRow(Vector<Object> dataRow) { return query.insertRow(dataRow); }
	public List<String> getFields() { return query.getFields(); }
	public String getViewSQL() { return query.getViewSQL(); }	
	public BElement getDeskConfig(int cfg) { return query.getDeskConfig(cfg); }
	public BElement getGridConfig() { return query.getGridConfig(); }
	public BElement getTableConfig() { return query.getTableConfig(); }
	public List<BTableLinks> getLinks() { return query.getLinks(); }
	public List<BTableLinks> getLinks(List<String> linkTables) { return query.getLinks(linkTables); }
	public void importData(Vector<Vector<Object>> newData) { query.importData(newData); }
	public String readDocument(boolean heading, boolean trim) { return query.readDocument(heading, trim); }
	public void recDelete() { query.recDelete(); }
	public void recAudit(String changetype, String recordid) { query.recAudit(changetype, recordid); }
	public String getTableName() {	return query.getTableName(); }
	public void setTitles(String[] titleArray) { query.setTitles(titleArray); }
	public void savecvs(String filename) { query.savecvs(filename); }
	public Map<String, String> getParams() { return query.getParams(); }
	public BQuery getQuery() { return query; }
}

