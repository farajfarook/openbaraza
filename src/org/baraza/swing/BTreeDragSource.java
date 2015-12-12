/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.swing;

import java.awt.dnd.DnDConstants;
import java.awt.dnd.DragGestureListener;
import java.awt.dnd.DragSourceListener;
import java.awt.dnd.DragSource;
import java.awt.dnd.DragGestureEvent;
import java.awt.dnd.DragGestureRecognizer;
import java.awt.dnd.DragSourceDragEvent;
import java.awt.dnd.DragSourceDropEvent;
import java.awt.dnd.DragSourceEvent;

import javax.swing.JTree;
import javax.swing.tree.DefaultMutableTreeNode;
import javax.swing.tree.DefaultTreeModel;
import javax.swing.tree.TreePath;

public class BTreeDragSource implements DragSourceListener, DragGestureListener {

	DragSource source;
	DragGestureRecognizer recognizer;
	BTransferableTreeNode transferable;
	DefaultMutableTreeNode oldNode;

	JTree sourceTree;

	public BTreeDragSource(JTree tree, int actions) {
		sourceTree = tree;
		source = new DragSource();
		recognizer = source.createDefaultDragGestureRecognizer(sourceTree, actions, this);
	}

	public void dragEnter(DragSourceDragEvent dsde) { }
	public void dragExit(DragSourceEvent dse) { }
	public void dragOver(DragSourceDragEvent dsde) { }

	public void dropActionChanged(DragSourceDragEvent dsde) {
		System.out.println("Action: " + dsde.getDropAction());
		System.out.println("Target Action: " + dsde.getTargetActions());
		System.out.println("User Action: " + dsde.getUserAction());
	}

	public void dragDropEnd(DragSourceDropEvent dsde) {
		System.out.println("Drop Action: " + dsde.getDropAction());
		if (dsde.getDropSuccess() && (dsde.getDropAction() == DnDConstants.ACTION_MOVE)) {
			((DefaultTreeModel)sourceTree.getModel()).removeNodeFromParent(oldNode);
		}
	}

	public void dragGestureRecognized(DragGestureEvent dge) {
		TreePath path = sourceTree.getSelectionPath();
		if ((path == null) || (path.getPathCount() <= 1)) return;

		oldNode = (DefaultMutableTreeNode) path.getLastPathComponent();
		transferable = new BTransferableTreeNode(path);
		source.startDrag(dge, DragSource.DefaultMoveNoDrop, transferable, this);
	}
}