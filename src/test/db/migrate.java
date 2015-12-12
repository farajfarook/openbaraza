import java.sql.*;
import java.util.*;

public class migrate {

	public static void main(String args[]) {

		Map<String, String> tables = new HashMap<String, String>();
		List<String> orderTables = new ArrayList<String>();

		try {
			String driver = "org.postgresql.Driver";
			String dbpath = "jdbc:postgresql://localhost/baraza";

			Class.forName(driver);
			Connection db = DriverManager.getConnection(dbpath, "root", "invent2k");
			DatabaseMetaData dbmd = db.getMetaData();

			String[] types = {"TABLE"};
        	ResultSet dbmdr = dbmd.getTables(null, null, "%", types);
    		while (dbmdr.next()) {
				String tableName = dbmdr.getString(3);
				String foreignTables = "";

				ResultSet ikrs = dbmd.getImportedKeys(null, null, tableName);
				while (ikrs.next()) foreignTables += ikrs.getString(3) + ",";

				if(foreignTables.equals("")) orderTables.add(tableName);

				System.out.println(tableName + " : " + foreignTables);
				tables.put(tableName, foreignTables);

				ikrs.close();
			}

			db.close();
		} catch (ClassNotFoundException ex) {
			System.out.println("Class not found : " + ex);
		} catch (SQLException ex) {
			System.out.println("Database connection error : " + ex);
		}

		while(tables.size() != orderTables.size()) {
			for(String tableName : tables.keySet()) {
				if(!orderTables.contains(tableName)) {
					String[] foreignTables = tables.get(tableName).split(",");
					boolean allTables = true;
					for(String foreignTable : foreignTables) {
						if(!orderTables.contains(foreignTable)) allTables = false;
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

	}
}