package com;

import java.util.List;
import java.text.DecimalFormat;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;


public class tegemeo {

	public static void main(String args[]) {
	
		String xmlFile = "tegemeo.xml";
		BXML xml = new BXML(xmlFile, false);
		BElement root = xml.getRoot();
	
		String dbclass = "org.postgresql.Driver";
		String dbpath = "jdbc:postgresql://localhost/hr";
		BDB db = new BDB(dbclass, dbpath, "root", "invent");
		
		for(Integer I = 2; I < 15; I++) {
			System.out.println("Import data for hr" + I.toString());
			
			dbpath = "jdbc:postgresql://localhost/hr" + I.toString();
			BDB rdb = new BDB(dbclass, dbpath, "root", "invent");
			
			migrate(db, rdb, root.copy(), I);
			
			rdb.close();
		}
		
		db.close();
	}
	
	public static void migrate(BDB db, BDB rdb, BElement root, Integer dbNo) {
	
		for(BElement node : root.getElements()) {
			BElement rnode = node.getElementByName("EXPORT");
			for(BElement updateField : rnode.getElements()) {
				String getUp = updateField.getAttribute("fnct");
				if(getUp != null) {
					getUp = getUp.replace("{org_id}", dbNo.toString());
					updateField.setAttribute("fnct", getUp);
				}
			}

			//System.out.println(rnode.toString());

			BQuery rs = new BQuery(db, node, null, node.getAttribute("keyfield"));
			BQuery rrs = new BQuery(rdb, rnode, null, rnode.getAttribute("keyfield"));
			rs.importData(rrs.getData());
			rs.close();
			rrs.close();
		}
	}
	
}

