/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2012.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.DB;

import java.util.Vector;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;

public class BMigration {
	BDB db = null;

	public static void main(String args[]) {
		if(args.length == 1) {
			BMigration migration = new BMigration(args[0]);
			migration.close();
		} else {
			System.out.println("java -cp ./baraza.jar org.baraza.DB.BMigration <xmlFile>");
		}
	}

	public BMigration(String xmlFile) {
		//System.out.println("Baraza Migration - Processing : " + xmlFile);
		
		BXML xml = new BXML(xmlFile, false);
		BElement root = xml.getRoot();
		db = new BDB(root);
		db.setUser("127.0.0.1", "root");
		
		if(root.getName().equals("MIGRATE_TABLES")) getTableNames();
		for(BElement node : root.getElements()) {
			if(root.getName().equals("MIGRATE_GEN")) getMigrate(node);
			if(root.getName().equals("COMPARE")) compareTable(node);
			if(root.getName().equals("MIGRATE")) migrateDB(node);
			if(root.getName().equals("MIGRATE_SEQ")) getMigrateSeq(node);
		}
	}
	
	public void compareTable(BElement node) {
		BDB rdb = new BDB(node);
		rdb.setUser("127.0.0.1", "root");
		for(BElement el : node.getElements()) {
			System.out.println(el.getAttribute("table"));

			BElement rel = el.getElementByName("EXPORT");
			BQuery rs = new BQuery(db, el, null, el.getAttribute("keyfield"), false);
			BQuery rrs = new BQuery(rdb, rel, null, el.getAttribute("keyfield"), false);
			
			while(rs.moveNext()) {
				if(rrs.moveNext()) {
					for(BElement field : rel.getElements()) {
						String fieldName = field.getValue();
						if((rs.readField(fieldName) == null) && (rrs.readField(fieldName) == null)) {
						} else if((rs.readField(fieldName) == null) || (rrs.readField(fieldName) == null)) {
							System.out.println("MM : " + fieldName);
						} else if(!rs.readField(fieldName).equals(rs.readField(fieldName))) {
							System.out.println("MM : " + fieldName);
						}
					}
				}
			}

			rs.close();
			rrs.close();			
		}
		rdb.close();	
	}

	public BElement getMigrate(BElement node) {
		BElement migrate = new BElement("MIGRATE");
		BElement source = new BElement("SOURCE");
		migrate.addNode(source);

		BDB sdb = new BDB(node);
		if(!node.getAttribute("noaudit", "false").equals("true")) sdb.setUser("127.0.0.1", "root");
		
		for(BElement el : node.getElements()) {
			BQuery rs = new BQuery(sdb, "*", el.getValue(), 1);
			source.addNode(rs.getMigrateConfig());
			rs.close();
		}
		sdb.close();

		System.out.println(migrate.toString());
		return migrate;
	}

	public void migrateDB(BElement node) {
		BDB rdb = new BDB(node);
		if(!node.getAttribute("noaudit", "false").equals("true")) rdb.setUser("127.0.0.1", "root");

		for(BElement el : node.getElements()) {
			migrateTable(rdb, el);
		}
		rdb.close();
	}

	public void migrateTable(BDB rdb, BElement el) {
		System.out.println(el.getAttribute("table"));

		BElement rel = el.getElementByName("EXPORT");
		BQuery rs = new BQuery(db, el, null, null);
		BQuery rrs = new BQuery(rdb, rel, null, null);
		rs.importData(rrs.getData());
		rs.close();
		rrs.close();
	}

	public void getMigrateSeq(BElement node) {
		String myans = "";
		String myseq = "";
		String seqSql = "";
		BDB rdb = new BDB(node);
		for(BElement el : node.getElements()) {
			BQuery rs = new BQuery(rdb, "*", el.getValue(), 1);
			Vector<String> autoFields = rs.getAutoFields();

			for(String autoField : autoFields) {
				myseq = el.getValue() + "_" + autoField + "_seq";
				seqSql = "SELECT max(" + autoField + ") FROM " + el.getValue();
				seqSql = db.executeFunction(seqSql);
				if(el.getAttribute("seq") != null) myseq = el.getAttribute("seq");
				if(seqSql != null) myans += "SELECT setval('" + myseq + "', " + seqSql + ");\n";

				//System.out.println(myseq + " = " + seqSql);
			}
			rs.close();
		}
		rdb.close();
		System.out.println(myans);
	}

	public void getTableNames() {
		Map<String, String> tables = new HashMap<String, String>();
		List<String> orderTables = new ArrayList<String>();

		try {
			DatabaseMetaData dbmd = db.getDBMetaData();
			String[] types = {"TABLE"};
        	ResultSet dbmdr = dbmd.getTables(null, null, "%", types);
    		while (dbmdr.next()) {
				String tableName = dbmdr.getString(3);
				String foreignTables = "";

				ResultSet ikrs = dbmd.getImportedKeys(null, null, tableName);
				while (ikrs.next()) foreignTables += ikrs.getString(3) + ",";
				ikrs.close();

				if(foreignTables.equals("")) orderTables.add(tableName);

				System.out.println(tableName + " : " + foreignTables);
				tables.put(tableName, foreignTables);
			}
		} catch (SQLException ex) {
			System.out.println("Database access error : " + ex);
		}

		while(tables.size() != orderTables.size()) {
			for(String tableName : tables.keySet()) {
				if(!orderTables.contains(tableName)) {
					String[] foreignTables = tables.get(tableName).split(",");
					boolean allTables = true;
					for(String foreignTable : foreignTables) {
						if(!orderTables.contains(foreignTable) && !tableName.equals(foreignTable)) allTables = false;
					}
					if(allTables) orderTables.add(tableName);
				} 
			}
		}

		// Print ordered tables
		System.out.println("\n\nOrdered Tables");
		for(String tableName : orderTables) {
			System.out.println(tableName + " : " + tables.get(tableName));
		}

		// Print XML ordered tables
		System.out.println("\n\n");
		for(String tableName : orderTables) {
			System.out.println("<TABLE>" + tableName + "</TABLE>");
		}
	}

	public void close() {
		if(db != null) db.close();
	}

}

