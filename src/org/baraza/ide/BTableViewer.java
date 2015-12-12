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
import java.util.Vector;

import javax.swing.JInternalFrame;
import javax.swing.JList;
import javax.swing.JScrollPane;

import org.baraza.DB.*;
import org.baraza.xml.BElement;

public class BTableViewer extends JInternalFrame {
	Logger log = Logger.getLogger(BTableViewer.class.getName());
	String name;
	BTableModel tableModel;
	public JList<String> list;
	JScrollPane scrollPane;

	public BTableViewer(BDB db, String tableName) {
		super(tableName, true, true, false, false);

		name = tableName;
		tableModel =  new BTableModel(db, "*", tableName, 10);

		Vector<String> tbv = new Vector<String>(tableModel.getFields());
		list = new JList<String>(tbv);
		scrollPane = new JScrollPane(list);
		add(scrollPane);
		setSize();
	}

	public String getFieldName() {
		return list.getSelectedValue().toString();
	}

	public String getName() {
		return name;
	}

	public BTableModel getTableModel() {
		return tableModel;
	}

  	public void setSize() {
        super.setLocation(10, 10);
        super.setSize(175, 200);
 	}

	public List<BTableLinks> getLinks() { return tableModel.getLinks(); }
	public List<BTableLinks> getLinks(List<String> linkTables) { return tableModel.getLinks(linkTables); }
	public BElement getDeskConfig(int cfg) { return tableModel.getDeskConfig(cfg); }
	public BElement getGridConfig() { return tableModel.getGridConfig(); }
	public String getViewSQL() { return tableModel.getViewSQL(); }

}
