/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.xml;

import java.util.Map;
import java.util.HashMap;

public class BXMLQuery {
	
	Map<String, String> dataFields;

	public BXMLQuery() {
		dataFields = new HashMap<String, String>();
	}

	public String getInsert(BElement node) {
		String tn = "INSERT INTO " + node.getName() + " (";
		String tv = "";
		String etn = "";
		boolean fi = true;
		for(BElement el : node.getElements()) {
			if(el.isLeaf()) {
				if(fi) {
					fi = false; 
					tn += el.getName();
					tv += "'" + el.getValue() + "'";
				} else {
					tn += ", " + el.getName();
					tv += ", '" + el.getValue() + "'";
				}
			} else {
				etn += "\n" + getInsert(el);
			}
		}

		for (String dataKey : dataFields.keySet()) {
			tn += ", " + dataKey;
			tv += ", '" + dataFields.get(dataKey) + "'";
		}

		tn += ")\n VALUES ("  + tv + ");";
		tn += etn;
		if(fi) tn = etn;
	
		return tn;
	}

	public void setData(String key, String value) {
		dataFields.put(key, value);
	}
}