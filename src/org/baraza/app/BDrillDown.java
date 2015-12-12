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
import java.awt.GridLayout;

import javax.swing.JTree;
import javax.swing.tree.DefaultTreeModel;
import javax.swing.tree.TreeSelectionModel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;

import org.baraza.swing.BImageTree;
import org.baraza.swing.BCellRenderer;
import org.baraza.xml.BTreeNode;
import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.utils.BLogHandle;


public class BDrillDown extends JPanel {
	Logger log = Logger.getLogger(BDrillDown.class.getName());
	BLogHandle logHandle;
	BImageTree tree;	
	JScrollPane treeScroll;
	BTreeNode topNode;
	DefaultTreeModel treeModel;
	String filterName;

	BElement view;
	BDB db;

	public BDrillDown(BLogHandle logHandle, BDB db, BElement view, String reportDir) {
		super(new GridLayout(1,0));
		this.db = db;
		this.view = view;
		this.logHandle = logHandle;
		logHandle.config(log);

		topNode = new BTreeNode(view.getAttribute("name"));		
		treeModel = new DefaultTreeModel(topNode);
		filterName = view.getAttribute("filter");
		if(filterName == null) filterName = view.getAttribute("filtername", "filterid");

        tree = new BImageTree("/org/baraza/resources/leftpanel.jpg", treeModel, false);
        tree.getSelectionModel().setSelectionMode(TreeSelectionModel.SINGLE_TREE_SELECTION);
    	tree.setCellRenderer(new BCellRenderer());

    	treeScroll = new JScrollPane(tree);
		super.add(treeScroll);

		createtree();
	}

	public void createtree() {
		topNode.removeAllChildren();
		addNode(topNode, view, null);
		treeModel.reload();
	}

	public void addNode(BTreeNode lnode, BElement fielddef, String wherekey) {
		filterName = fielddef.getAttribute("filter");
		if(filterName == null) filterName = fielddef.getAttribute("filtername", "filterid");

        String keyfield = fielddef.getAttribute("keyfield");
		String listfield = fielddef.getAttribute("listfield");
		String orderby = fielddef.getAttribute("orderby");
		if(orderby == null) orderby = listfield;
		String wheresql = fielddef.getAttribute("where");
		String wherefield = fielddef.getAttribute("wherefield");

        String sql = "SELECT " + keyfield + ", " + listfield;
        sql += " FROM " + fielddef.getAttribute("table");

		if(wheresql == null) {
			if(wherefield != null) wheresql = " WHERE " + wherefield + " = '" + wherekey + "'";
		} else {
			wheresql = " WHERE " + wheresql;
			if(wherefield != null) wheresql += " AND " + wherefield + " = '" + wherekey + "'";
		}

		if(fielddef.getAttribute("noorg") == null) {
			String orgID = db.getOrgID(); 
			String userOrg = db.getUserOrg(); 
			if((orgID != null) && (userOrg != null)) {
				if(wheresql == null) wheresql = " WHERE (";
				else wheresql += " AND (";

				wheresql += orgID + "=" + userOrg + ")";
			}
		}

		if(wheresql != null) sql += wheresql;
		sql += " ORDER BY " + orderby;


		BQuery query = new BQuery(db, sql);
		while(query.moveNext()) {
			BTreeNode subnode = new BTreeNode(query.getString(keyfield), query.getString(listfield));
			lnode.add(subnode);

			// Add the sub tree elements
			for(BElement el : fielddef.getElements()) {
				if(el.getName().equals("DRILLDOWN")) {
					addNode(subnode, el, query.getString(keyfield));
				}
			}
		}
		query.close();
	}

	public String getKey() {
		BTreeNode node = (BTreeNode)tree.getLastSelectedPathComponent();

		if (node == null) return null;
		if (!node.isLeaf()) return null;

		return node.getString();
	}

	public String getFilterName() {
		return filterName;
	}

	public void setListener(BFilter flt) {
		tree.addTreeSelectionListener(flt);
	}
}
