/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import java.util.List;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BElement;

public class BDrillWeb {
	String filterName;

	public String getDrillDown(BDB db, BElement view) {
		filterName = view.getAttribute("filter", "filterid");

		String mymenu = "<input type='hidden' name='" + filterName + "' id='" + filterName + "' value='0'/>\n";
		mymenu += "<div id='" + filterName + "_1' class='ui-tree'>\n";
		mymenu += "<ul>\n";
		mymenu += getSubDrill(db, view, null);
		mymenu += "</ul>\n";
		mymenu += "</div>\n";

		return mymenu;
	} 

	public String getSubDrill(BDB db, BElement fielddef, String wherekey) {
		String subdrill = "";
		String bodypage = "";
        String keyfield = fielddef.getAttribute("keyfield");
		String listfield = fielddef.getAttribute("listfield");
		String orderby = fielddef.getAttribute("orderby");
		if(orderby == null) orderby = listfield;
		String wheresql = fielddef.getAttribute("where");
		String wherefield = fielddef.getAttribute("wherefield");

        String sql = "SELECT " + keyfield + ", " + listfield;
        sql += " FROM " + fielddef.getAttribute("table");

		String orgID = db.getOrgID();		
		String userOrg = db.getUserOrg();
		if((fielddef.getAttribute("noorg") == null) && (orgID != null) && (userOrg != null)) {
			if(wheresql == null) wheresql = " (";
			else wheresql += " AND (";
			wheresql += orgID + "=" + userOrg + ")";
		}

		if(wheresql == null) {
			if(wherefield != null) sql += " WHERE " + wherefield + " = '" + wherekey + "'";
		} else {
			sql += " WHERE " + wheresql;
			if(wherefield != null) sql += " AND " + wherefield + " = '" + wherekey + "'";
		}
		sql += " ORDER BY " + orderby;

		BQuery query = new BQuery(db, sql);
		while(query.moveNext()) {
			if(fielddef.isLeaf()) {
				subdrill += "<li>";
				subdrill += "<a href='#' OnClick=\"updateField('" + filterName + "', '" + query.getString(keyfield) + "')\">";
				subdrill += query.getString(listfield) + "</a>";
				subdrill += "</span></li>\n";
			} else {
				// Add the sub tree elements
				for(BElement el : fielddef.getElements()) {
					subdrill += "<li>" + query.getString(listfield) + "\n<ul>\n";
					subdrill += getSubDrill(db, el, query.getString(keyfield));
					subdrill += "\n</ul>\n</li>";
				}
			}
		}
		query.close();

		return subdrill;
	}

}