/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.app;

import org.baraza.xml.BElement;

import java.util.Map;
import java.util.HashMap;
import javax.swing.JComboBox;

public class BComboList extends JComboBox<String> {

	Map<String, String> vList;
	Map<String, String> kList;

    public BComboList(BElement el) {
		super();

		if (el.getAttribute("editable") != null) super.setEditable(true);
		if (el.getAttribute("disabled") != null) super.setEnabled(false);

		vList = new HashMap<String, String>();
		kList = new HashMap<String, String>();
		for(BElement lel : el.getElements()) {
			super.addItem(lel.getValue());
			if(lel.getAttribute("key") == null) {
				vList.put(lel.getValue(), lel.getValue());
				kList.put(lel.getValue(), lel.getValue());
			} else {
				vList.put(lel.getValue(), lel.getAttribute("key"));
				kList.put(lel.getAttribute("key"), lel.getValue());
			}
		}
 	}

	public void setBounds(int x, int y, int w, int h) {
		super.setBounds(x, y, w, h);
	}

	public void setText(String ldata) {
		super.setSelectedItem(kList.get(ldata));
	}

	public String getText() {
		String ldata = super.getSelectedItem().toString();
		ldata = vList.get(ldata);
		return ldata;
	}		
}
