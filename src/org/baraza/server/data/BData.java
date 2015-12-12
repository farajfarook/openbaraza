/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.data;

import java.util.logging.Logger;
import java.util.List;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.utils.BLogHandle;

public class BData {
	Logger log = Logger.getLogger(BData.class.getName());
	BDB db;
	BDB rdb = null;
	BElement root;

	boolean executing = false;
	boolean runserver = true;
	int processdelay = 10000;

	public BData(BDB db, BElement root, BLogHandle logHandle) {
		this.db = db;
		this.root = root;
		logHandle.config(log);

		processdelay = Integer.valueOf(root.getAttribute("processdelay", "1")).intValue()*60*1000;
		rdb = new BDB(root);
		rdb.logConfig(logHandle);
	}

	public int process() {
		log.info("---------- Transfer Thread Started");
		executing = true;

		// Create the data transfer class
		System.out.println("BASE is valid : " + rdb.isValid());
		
		// validate the databases then run process
		if(!db.isValid()) {
			db.reconnect();
		} else if(!rdb.isValid()) {
			rdb.reconnect();
		} else {
			for(BElement el : root.getElements()) {
				if(el.getName().equals("EXPORT")) process(el);
				else if (el.getName().equals("FUNCTION")) function(el);
			}		
		}

		log.info("---------- Transfer Thread completed");

		executing = false;
		return processdelay;
	}

	public void process(BElement el) {
		BElement rel = el.getElementByName("INTO");
		String where = el.getAttribute("marker");		
		BQuery rs = new BQuery(db, el, where, el.getAttribute("keyfield"));
		BQuery rrs = new BQuery(rdb, rel, null, null);

		rrs.importData(rs.getData());

		rs.beforeFirst();
		while(rs.moveNext()) {
			String update = el.getAttribute("update");
			if(update == null) update = el.getAttribute("table");

			String mysql = el.getAttribute("psql", "");
			mysql += "\nUPDATE " + update + " SET " +  el.getAttribute("marked");
			mysql += " WHERE (" +  el.getAttribute("marker") + ") AND (";
			mysql += rs.getKeyFieldName() + " = '" + rs.getKeyField() + "');";
			db.executeQuery(mysql);
		}

		rs.close();
		rrs.close();
	}

	public void function(BElement el) {
		String lsql = el.getAttribute("lsql");
		if(lsql != null) db.executeQuery(lsql);

		String rsql = el.getAttribute("rsql");
		if(rsql != null) rdb.executeQuery(rsql);
	}

	public boolean isExecuting() {
		return executing;
	}

	public void close() {
		// Close the connections
		db.close();
		rdb.close();
	}

}
