/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.app;

public class BTabs {

	int type, index;

	public BTabs(int type, int index) {
		this.type = type;
		this.index = index;
	}

	public int getType() { return type; }
	public int getIndex() { return index; }
		
}
