/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.sqlcron;

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

public class BSQLCron {
	Logger log = Logger.getLogger(BSQLCron.class.getName());
	BDB db = null;
	BElement root = null;
	int delay = 10000;

	public BSQLCron(BDB db, BElement root, BLogHandle logHandle) {
		this.root = root;
		this.db = db;
		logHandle.config(log);
		
		delay = Integer.valueOf(root.getAttribute("delay", "1")).intValue()*60*1000;
	}

	public int process() {
		log.info("--------------- Processing SQL Cron");
		String mysql = "";
		Map<String, String> attr = new HashMap<String, String>();
		for(BElement el : root.getElements()) {
			if(el.getAttribute("fnct") == null) mysql = "SELECT " + el.getValue(); 
			else mysql = "SELECT " + el.getAttribute("fnct")  + " as " + el.getValue();
			
			if(el.getAttribute("table") != null) mysql += " FROM " + el.getAttribute("table");
			
			if(el.getAttribute("wheresql") != null) mysql += " WHERE " + el.getAttribute("wheresql");
			
			db.executeQuery(mysql);
		}


		return delay;
	}

	public int getDelay() {
		return delay;
	}

	public void close() {
		db.close();
	}

}