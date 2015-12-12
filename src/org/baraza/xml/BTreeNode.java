/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.xml;

import javax.swing.tree.DefaultMutableTreeNode;

public class BTreeNode extends DefaultMutableTreeNode {
	
	BElement key = null;
	String sKey = null;

	public BTreeNode(String name) {
		super(name);
	}

	public BTreeNode(String sKey, String name) {
		super(name);
		this.sKey = sKey;
	}

	public BTreeNode(BElement key, String name) {
		super(name);
		this.key = key;
	}

	public BElement getKey() {
		return key;
	}

	public String getString() {
		if(key != null) return key.toString();
		return sKey;
	}

	public void setKey(BElement key) {
		this.key = key;
	}

	public void setKey(String sKey) {
		this.sKey = sKey;
	}
}
