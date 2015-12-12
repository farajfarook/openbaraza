/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.swing;

import java.awt.datatransfer.Transferable;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.UnsupportedFlavorException;
import javax.swing.tree.TreePath;

class BTransferableTreeNode implements Transferable {

	public static DataFlavor TREE_PATH_FLAVOR = new DataFlavor(TreePath.class, "Tree Path");
	DataFlavor flavors[] = { TREE_PATH_FLAVOR };
	TreePath path;

	public BTransferableTreeNode(TreePath tp) {
		path = tp;
	}

	public synchronized DataFlavor[] getTransferDataFlavors() {
		return flavors;
	}

	public boolean isDataFlavorSupported(DataFlavor flavor) {
		return (flavor.getRepresentationClass() == TreePath.class);
	}

	public synchronized Object getTransferData(DataFlavor flavor) throws UnsupportedFlavorException {
		if (isDataFlavorSupported(flavor)) {
			return (Object) path;
		} else {
			throw new UnsupportedFlavorException(flavor);
		}
	}

}
