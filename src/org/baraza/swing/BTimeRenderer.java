/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.swing;

import javax.swing.table.DefaultTableCellRenderer;
import java.text.DateFormat;

public class BTimeRenderer extends DefaultTableCellRenderer {
    
	DateFormat formatter;
    
	public BTimeRenderer() {
		super();
	}

    public void setValue(Object value) {
        if (formatter==null) {
            formatter = DateFormat.getTimeInstance();
        }
		if(value==null) setText("");
		else setText(formatter.format(value));
    }
}
