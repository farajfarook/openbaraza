/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.swing;

import javax.swing.JLabel;
import javax.swing.JTree;
import javax.swing.tree.TreeCellRenderer;
import javax.swing.tree.DefaultTreeCellRenderer;

import javax.swing.UIManager;

import java.awt.Color;
import java.awt.Component;

public class BCellRenderer extends JLabel implements TreeCellRenderer {

	public BCellRenderer() {
		setOpaque(false);
		setBackground(null);
	}

	public Component getTreeCellRendererComponent(JTree tree, Object value, boolean sel, boolean expanded, boolean leaf, int row, boolean hasFocus) {
		setFont(tree.getFont());
		String stringValue = tree.convertValueToText(value, sel, expanded, leaf, row, hasFocus);
	
		setEnabled(tree.isEnabled());
		setText(stringValue);
		if(sel) setForeground(Color.blue);
		else setForeground(Color.black);

		if (leaf) {
		    setIcon(UIManager.getIcon("Tree.leafIcon"));
		} else if (expanded) {
		    setIcon(UIManager.getIcon("Tree.openIcon"));
		} else {
		    setIcon(UIManager.getIcon("Tree.closedIcon"));
		}

		return this;
	}
}