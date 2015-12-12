import java.sql.*;
import java.util.*;

public class BDBConn {
	Connection db = null;

	public BDBConn(String dbName) {
		try {
			String driver = "org.postgresql.Driver";
			String dbpath = "jdbc:postgresql://localhost/" + dbName;

			Class.forName(driver);
			db = DriverManager.getConnection(dbpath, "root", "invent");
		} catch (ClassNotFoundException ex) {
			System.out.println("Class not found : " + ex);
		} catch (SQLException ex) {
			System.out.println("Database connection error : " + ex);
		}
	}

	public boolean executeQuery(String mysql) {
		boolean isOkay = true;
		try {
			Statement stIns = db.createStatement();
			stIns.execute(mysql);
			stIns.close();
		} catch (SQLException ex) {
			isOkay = false;
			System.out.println("Database connection error : " + ex);
		}
		return isOkay;
	}

	public ResultSet readQuery(String mysql) {
		ResultSet rs = null;

		try {
			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			rs = st.executeQuery(mysql);
		} catch (SQLException ex) {
			System.out.println("Database transaction get data error : " + ex);
		}

		return rs;
	}

	public void migrateEntity(ResultSet rs, String passwd) {
		try {
			String mysql = "INSERT INTO entitys (org_id, entity_type_id, entity_name, user_name, function_role, entity_password, first_password, contact_key, auth_info) ";
			mysql += "VALUES (0, 2, '" + rs.getString("intpostalname").replace("'", "\\'") + "', 'admin@" + rs.getString("name");
			mysql += "', 'client', md5('" + passwd + "'), '" + passwd + "', '" + rs.getString("id");
			mysql += "', '" + rs.getString("authinfopw") + "');\n";

			mysql += "INSERT INTO address (sys_country_id, table_name, table_id, post_office_box, postal_code, premises, ";
			mysql += " town, phone_number, email, is_default) ";
			mysql += "VALUES ('" + rs.getString("intpostalcc") + "', 'entitys', currval('entitys_entity_id_seq'), ";
			if(rs.getString("intpostalstreet3") == null) {
				mysql += "null,";
			} else {
				mysql += "'" + rs.getString("intpostalstreet3") + "',";
			}
			if(rs.getString("intpostalstreet2") == null) {
				mysql += "null, '";
			} else {
				int pos = rs.getString("intpostalstreet2").length(); 
				mysql += "'";
				if(pos>12) mysql += rs.getString("intpostalstreet2").substring(1, 12) + "', '";
				else mysql += rs.getString("intpostalstreet2") + "', '";
			}
			mysql += rs.getString("intpostalstreet1") + "', '" + rs.getString("intpostalcity") + "', '";
			mysql += rs.getString("voice") + "', '" + rs.getString("email") + "', true);\n";

			mysql += "INSERT INTO domains (entity_id, domain_name, auth_info, created_date, expiry_date, updated, google_sync, duration) ";
			mysql += "VALUES (currval('entitys_entity_id_seq'), '" + rs.getString("name") + "', '";
			mysql += rs.getString("domain_authinfopw") + "', '" + rs.getString("createdate") + "', '";
			mysql += rs.getString("exdate") + "', true, true, 1);\n";
			boolean isOkay = executeQuery(mysql);

			if(!isOkay) System.out.println(mysql);
		} catch (SQLException ex) {
			System.out.println("Database transaction get data error : " + ex);
		}
	}

	public void close() {	
		try {
			if(db != null) db.close();
		} catch (SQLException ex) {
			System.out.println("Database connection error : " + ex);
		}
	}

}
