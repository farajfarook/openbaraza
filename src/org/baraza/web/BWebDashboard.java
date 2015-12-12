/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.naming.Context;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BElement;

public class BWebDashboard {
	BDB db;
	
	public BWebDashboard(BDB db) {
		this.db = db;
	}

	public String getTile(BElement el) {
		String body = "";
		
		BQuery rs = new BQuery(db, el, null, null, false);
		rs.moveFirst();
				
		body += "<div class='col-lg-3 col-md-3 col-sm-6 col-xs-12'>\n";
		body += "	<div class='dashboard-stat2'>\n";
		for(BElement ell : el.getElements()) {
			String val = rs.readField(ell.getValue());
			if(val == null) val = "";
			if(ell.getAttribute("type", "display").equals("display")) {
				body += "		<div class='display'>\n";
				body += "			<div class='number'>\n";
				body += "				<h3 class='" + ell.getAttribute("color", "font-green-sharp") + "'>" + val + "</h3>\n";
				body += "				<small>" + el.getAttribute("name", "Name") + "</small>\n";
				body += "			</div>\n";
				body += "			<div class='icon'>\n";
				body += "				<i class='" + ell.getAttribute("icon", "icon-pie-chart") + "'></i>\n";
				body += "			</div>\n";
				body += "		</div>\n";
			} else if(ell.getAttribute("type", "display").equals("progress")) {
				body += "		<div class='progress-info'>\n";
				body += "			<div class='progress'>\n";
				body += "				<span style='width: " + val + "%;' class='progress-bar progress-bar-success green-sharp'>\n";
				body += "				<span class='sr-only'>" + val + "% progress</span>\n";
				body += "				</span>\n";
				body += "			</div>\n";
				body += "			<div class='status'>\n";
				body += "				<div class='status-title'>progress</div>\n";
				body += "				<div class='status-number'>" + val + "%</div>\n";
				body += "			</div>\n";
				body += "		</div>\n";
			}
		}
		body += "	</div>\n";
		body += "</div>\n";
		
		return body;
	}
	
	public String getTileList(BElement el) {
		String body = "";
		
		body += "<div class='col-md-6 col-sm-12'>\n";
		body += "	<!-- BEGIN PORTLET-->\n";
		body += "	<div class='portlet light tasks-widget'>\n";
		body += "		<div class='portlet-title'>\n";
		body += "			<div class='caption caption-md'>\n";
		body += "				<i class='icon-bar-chart theme-font-color hide'></i>\n";
		body += "				<span class='caption-subject theme-font-color bold uppercase'>" + el.getAttribute("name", "Name") + "</span>\n";
		body += "			</div>\n";
		body += "		</div>\n";
		
		body += "		<div class='portlet-body'>\n";
		body += "			<div class='table-scrollable'>\n";
		BQuery rs = new BQuery(db, el, null, null, false);
		body += rs.readDocument(true, false);
		body += "			</div>\n";
		body += "		</div>\n";

		body += "	</div>\n";
		body += "</div>\n";
		
		return body;
	}
}