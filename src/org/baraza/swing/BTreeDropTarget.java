/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.swing;

import org.baraza.xml.BTreeNode;

import java.awt.Point;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.Transferable;

import java.awt.dnd.DropTargetListener;
import java.awt.dnd.DropTarget;
import java.awt.dnd.DropTargetEvent;
import java.awt.dnd.DropTargetDropEvent;
import java.awt.dnd.DropTargetDragEvent;
import java.awt.dnd.DropTargetContext;

import javax.swing.JTree;
import javax.swing.tree.TreePath;
import javax.swing.tree.TreeNode;
import javax.swing.tree.DefaultTreeModel;

public class BTreeDropTarget implements DropTargetListener {

	DropTarget target;
	JTree targetTree;

	public BTreeDropTarget(JTree tree) {
		targetTree = tree;
		target = new DropTarget(targetTree, this);
	}

	public void drop(DropTargetDropEvent dtde) {
		Point pt = dtde.getLocation();
		DropTargetContext dtc = dtde.getDropTargetContext();
		JTree tree = (JTree) dtc.getComponent();
		TreePath parentpath = tree.getClosestPathForLocation(pt.x, pt.y);
		BTreeNode parent = (BTreeNode) parentpath.getLastPathComponent();

		/*if (parent.isLeaf()) {
			dtde.rejectDrop();
			return;
		}*/

		try {
			Transferable tr = dtde.getTransferable();
			DataFlavor[] flavors = tr.getTransferDataFlavors();
			for (int i = 0; i < flavors.length; i++) {
				if (tr.isDataFlavorSupported(flavors[i])) {
					dtde.acceptDrop(dtde.getDropAction());
					TreePath p = (TreePath) tr.getTransferData(flavors[i]);
					BTreeNode node = (BTreeNode) p.getLastPathComponent();
					DefaultTreeModel model = (DefaultTreeModel) tree.getModel();
					model.insertNodeInto(node, parent, 0);
					dtde.dropComplete(true);
					return;
				}
			}
			dtde.rejectDrop();
		} catch (Exception e) {
			e.printStackTrace();
			dtde.rejectDrop();
		}
	}

	public void dragExit(DropTargetEvent dte) { }

	public void dropActionChanged(DropTargetDragEvent dtde) { }

	public void dragOver(DropTargetDragEvent dtde) {
		BTreeNode node = getNodeForEvent(dtde);

		//if (node.isLeaf()) {
		//	dtde.rejectDrag();
		//} else {
			dtde.acceptDrag(dtde.getDropAction());
		//}
	}

	public void dragEnter(DropTargetDragEvent dtde) {
		BTreeNode node = getNodeForEvent(dtde);
		//if (node.isLeaf()) {
		//	dtde.rejectDrag();
		//} else {
			dtde.acceptDrag(dtde.getDropAction());
		//}
	}

	private BTreeNode getNodeForEvent(DropTargetDragEvent dtde) {
		Point p = dtde.getLocation();
		DropTargetContext dtc = dtde.getDropTargetContext();
		JTree tree = (JTree) dtc.getComponent();
		TreePath path = tree.getClosestPathForLocation(p.x, p.y);
		return (BTreeNode) path.getLastPathComponent();
  }
}
