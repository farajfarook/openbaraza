/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.app;

import java.util.logging.Logger;
import java.util.Vector;

import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.utils.BLogHandle;

public class BActions {
	Logger log = Logger.getLogger(BActions.class.getName());
	BLogHandle logHandle;
	BDB db;
	BElement node;

	public BActions(BLogHandle logHandle, BElement fielddef, BDB db) {
		this.db = db;
		this.node = fielddef;
		this.logHandle = logHandle;
		logHandle.config(log);
	}

	public void execproc(int action, String aKey, String linkdata) {
		BElement el = node.getElement(action);

		String autoKeyID = db.insAudit(el.getAttribute("fnct"), aKey, "FUNCTION");

		String mysql = "SELECT " + el.getAttribute("fnct") + "('" + aKey + "','" + db.getUserID();
		if(el.getAttribute("approval") != null) mysql += "', '" + el.getAttribute("approval");
		if(el.getAttribute("phase") != null) mysql +=  "','" + el.getAttribute("phase");
		else mysql += "', '" + linkdata;
		if(el.getAttribute("auditid") != null) mysql += "', '" + autoKeyID;
		mysql += "') ";

		if(el.getAttribute("from") != null) mysql += " " + el.getAttribute("from");

System.out.println("BASE : " + mysql);
		log.info(mysql);

		// Execute the procedure
     	String err = db.executeFunction(mysql);
		log.info(err);
	}

	public Vector<String> getActions() {
		Vector<String> actionTitle = new Vector<String>();

		for(BElement el : node.getElements()) 
			actionTitle.add(el.getValue());
		
		return actionTitle;
	}
}

