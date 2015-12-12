/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.deploy;

import java.util.logging.Logger;

import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.Date;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BElement;
import org.baraza.utils.BUnZip;
import org.baraza.utils.BLogHandle;

public class BDeploy {
	Logger log = Logger.getLogger(BDeploy.class.getName());
	BDB db = null;
	BElement root = null;
	int delay = 10000;

	public BDeploy(BDB db, BElement root, BLogHandle logHandle) {
		this.root = root;
		this.db = db;
		logHandle.config(log);
	}

	public int process() {
		log.info("--------------- Starting Deployed.");
		String mysql = "";
		Map<String, String> attr = new HashMap<String, String>();
		for(BElement el : root.getElements()) {
			if(el.getAttribute("function") == null) mysql = "SELECT " + el.getValue(); 
			else mysql = "SELECT " + el.getAttribute("function")  + " as " + el.getValue();
			mysql += " FROM " + el.getAttribute("table");
			if(el.getAttribute("wheresql") != null) mysql += " WHERE " + el.getAttribute("wheresql");
			String atv = db.executeFunction(mysql);
			attr.put(el.getName(), atv);
		}
		delay = Integer.valueOf(attr.get("INCREMENT")) * 60 * 1000;

		String namedvar = root.getAttribute("namedvar");
		String owner = root.getAttribute("owner");

		BUnZip us = new BUnZip(attr.get("ZONEDIR") + attr.get("GENERATION"), namedvar, owner);
	
		String command = root.getAttribute("command");
		if(command != null) {
			try {
				Runtime r = Runtime.getRuntime();
				Process p = r.exec(command);
			} catch(Exception ex) {
				log.severe("Command run error : " + ex.getMessage());
			}
		}

		log.info("---------- Deployed : " + attr.get("GENERATION"));

		return delay;
	}

	public int getDelay() {
		return delay;
	}

	public void close() {
		db.close();
	}

}