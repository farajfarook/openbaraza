/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.xml;

import java.util.Vector;

import javax.swing.table.AbstractTableModel;
import javax.swing.tree.DefaultTreeModel;
import javax.swing.event.TableModelEvent;

public class BXMLTable extends AbstractTableModel {
	BElement element;
	BTreeNode node;
	DefaultTreeModel treemodel;
	Vector<String> titles;

	public BXMLTable(BTreeNode node, DefaultTreeModel treemodel) {
		this.node = node;
		this.treemodel = treemodel;
		element = node.getKey();

		titles = new Vector<String>();
		titles.add("Name");
		titles.add("Value");
	}

    public int getColumnCount() {
        return titles.size();
    }

    public int getRowCount() {
        return element.getSize() + 1;
    }

    public String getColumnName(int aCol) {
        return titles.get(aCol);
    }

    public Object getValueAt(int aRow, int aCol) {
        return element.getValueAt(aRow, aCol);
    }

    public Class getColumnClass(int aCol) {
        return String.class;
    }

    public boolean isCellEditable(int aRow, int aCol) {
           return true;
    }

	public void refresh() { // Get all rows.
		fireTableChanged(null); // Tell the listeners a new table has arrived.
	}

	public void insertRow() {
		element.insertAttribute("", "");
		refresh();
	}

	public void removeRow(int aRow) {
		String key = element.getValueAt(aRow, 0);
		element.delAttribute(key);

		refresh();
	}


    public void setValueAt(Object value, int aRow, int aCol) {
		element.setValueAt(value.toString().replaceAll("<", "&lt;"), aRow, aCol);

		String title = element.getName() + " : ";
		if(element.getAttribute("title") != null) title += element.getAttribute("title");
		else if (element.getAttribute("name") != null) title += element.getAttribute("name");
		node.setUserObject(title);
		treemodel.reload(node);

        fireTableCellUpdated(aRow, aCol);
    }

}