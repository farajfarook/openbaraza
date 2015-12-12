import java.sql.*;
//import java.util.*;

public class keys {

	public static void main(String args[]) {

		try {
			Connection db = DriverManager.getConnection("jdbc:postgresql://localhost/hr", "root", "invent2k");
			DatabaseMetaData dbmd = db.getMetaData();
			System.out.println("DB Name : " + dbmd.getDatabaseProductName());

			String mysql = "SELECT sys_error_id, sys_error, error_message FROM sys_errors";

			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			ResultSet rs = st.executeQuery(mysql);
			ResultSetMetaData rsmd = rs.getMetaData();
			while (rs.next()) {
				System.out.println(rs.getString("sys_error_id")  + " : " + rs.getString("sys_error"));
			}

System.out.println("BASE 100 " + rsmd.getSchemaName(1));
			
			//System.out.println(rs.getString("sys_error_id")  + " : " + rs.getString("sys_error"));

			mysql = "INSERT INTO sys_errors (sys_error, error_message) ";
			mysql += "VALUES ('1', 'Test error')";
			Statement stIns = db.createStatement();
			stIns.execute(mysql, Statement.RETURN_GENERATED_KEYS);

			ResultSet rsa = stIns.getGeneratedKeys();
			if(rsa.next()) System.out.println(rsa.getString(1));

			rsa.close();
			stIns.close();

System.out.println("BASE 400");
			
			rs.close();
			st.close();
			db.close();
		} catch (SQLException ex) {
			System.out.println("Database connection error : " + ex);
		}
	}
}
