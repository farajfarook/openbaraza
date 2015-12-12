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
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.JPanel;

import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;

import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.DB.BTableModel;
import org.baraza.utils.BLogHandle;

public class BGridBox extends JTextField implements MouseListener {
	Logger log = Logger.getLogger(BGridBox.class.getName());
	BLogHandle logHandle;
	BGrid grid;
	BDB db;
	boolean showgrid = false;
	String sql;
	String name, lpkey, lptable, lpfield;
	String linkData;
	String datakey = null;

    public BGridBox(BLogHandle logHandle, BDB db, BElement el) {
		this.db = db;
		this.logHandle = logHandle;
		logHandle.config(log);

		super.setHorizontalAlignment(JTextField.LEADING);
		super.setCaretPosition(0);
		super.setEnabled(false);
		super.addMouseListener(this);

		lptable = el.getAttribute("lptable", "");
		lpfield = el.getAttribute("lpfield", "");

		name = el.getValue();
		if(el.getAttribute("lpkey") == null) lpkey = name;
		else lpkey = el.getAttribute("lpkey");

		grid = new BGrid(logHandle, db, el.getFirst(), "");
		grid.setListener(this);
		grid.setVisible(false);
	}

	public void refresh() {
		grid.refresh();
	}

    public void setBounds(int x, int y, int w, int h, int lw, int ph) {
        super.setBounds(x+lw, y, w, h);
		grid.setBounds(x, y+h, lw+w, ph);
    }

	public void setLinkData(String lkdata) {
		grid.setLinkData(lkdata);
		grid.refresh();
		System.out.println(lkdata);
	}

	public void setText(String ldata) {
		sql = "SELECT (" + lpfield + ") as lpfield  FROM " + lptable + " WHERE " + lpkey + " = ";
		if(ldata == null) sql += ldata;
		else if(ldata.trim().length() == 0) sql += "null";
 		else sql += "'" + ldata + "'";

		String rsd = db.executeFunction(sql);

		datakey = ldata;		// Set the key data
		super.setText(rsd);
		super.moveCaretPosition(0);
	}

	public String getText() {
		return datakey;
	}

	public JPanel getGrid() {
		return grid;
	}

	// Get the grid listening mode
	public void mousePressed(MouseEvent e) {}
	public void mouseReleased(MouseEvent e) {}
	public void mouseEntered(MouseEvent e) {}
	public void mouseExited(MouseEvent e) {}
	public void mouseClicked(MouseEvent e) {
		if(!showgrid) {
			grid.setVisible(true);
			grid.refresh();

			showgrid = true;
		} else {
			grid.setVisible(false);
			datakey = grid.getKey();
			setText(datakey);

			showgrid = false;
		}
	}
}
