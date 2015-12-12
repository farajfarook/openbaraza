/**
 * @author      Dennis W. Gichangi <dennis.dichangi@dewcis.com>
 * @version     2011.03.29
 * @since       1.6
 * website		www.dewcis.com
 * The contents of this file are subject to the Dew CIS Solutions License
 * The file should only be shared to OpenBravo.
 */
package org.baraza.com;

import java.util.Vector;

import javax.swing.table.AbstractTableModel;
import javax.swing.event.TableModelEvent;

class BOBChequeTable extends AbstractTableModel {
	public Vector<Vector<String>> cheques;
	public Vector<String> titles;

	public BOBChequeTable() {
		cheques = new Vector<Vector<String>>();
		titles = new Vector<String>();

		titles.add("Number");
		titles.add("Date");
		titles.add("Name");
		titles.add("Amount");
		titles.add("In Words");
	}

    public int getColumnCount() {
        return titles.size();
    }

    public int getRowCount() {
        return cheques.size();
    }

    public String getColumnName(int col) {
        return titles.get(col);
    }

    public Object getValueAt(int row, int col) {
        return cheques.get(row).get(col);
    }

    public Class getColumnClass(int c) {
        return getValueAt(0, c).getClass();
    }

    public boolean isCellEditable(int row, int col) {
           return false;
    }

    public void setValueAt(Object value, int row, int col) {
		Vector<String> dataRow = cheques.elementAt(row);
        dataRow.setElementAt((String)value, col);

        fireTableCellUpdated(row, col);
    }

	public void clear() {
		cheques.clear();
	}

	public void refresh() { // Get all rows.
		fireTableChanged(null); // Tell the listeners a new table has arrived.
	}

}

