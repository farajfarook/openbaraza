import java.sql.*;
import java.util.*;

public class oracle {

	public static void main(String args[]) {
		if(args.length > 1) {
			System.out.println(Types.ARRAY + " : ARRAY");
			System.out.println(Types.BIGINT + " : BIGINT");
			System.out.println(Types.BINARY + " : BINARY");
			System.out.println(Types.BIT + " : BIT");
			System.out.println(Types.BLOB + " : BLOB");
			System.out.println(Types.BOOLEAN + " : BOOLEAN");
			System.out.println(Types.CHAR + " : CHAR");
			System.out.println(Types.CLOB + " : CLOB");
			System.out.println(Types.DATALINK + " : DATALINK");
			System.out.println(Types.DATE + " : DATE");
			System.out.println(Types.DECIMAL + " : DECIMAL");
			System.out.println(Types.DISTINCT + " : DISTINCT");
			System.out.println(Types.DOUBLE + " : DOUBLE");
			System.out.println(Types.FLOAT + " : FLOAT");
			System.out.println(Types.INTEGER + " : INTEGER");
			System.out.println(Types.JAVA_OBJECT + " : JAVA_OBJECT");
			System.out.println(Types.LONGNVARCHAR + " : LONGNVARCHAR");
			System.out.println(Types.LONGVARBINARY + " : LONGVARBINARY");
			System.out.println(Types.LONGVARCHAR + " : LONGVARCHAR");
			System.out.println(Types.NCHAR + " : NCHAR");
			System.out.println(Types.NCLOB + " : NCLOB");
			System.out.println(Types.NULL + " : NULL");
			System.out.println(Types.NUMERIC + " : NUMERIC");
			System.out.println(Types.NVARCHAR + " : NVARCHAR");
			System.out.println(Types.REAL + " : REAL");
			System.out.println(Types.REF + " : REF");
			System.out.println(Types.ROWID + " : ROWID");
			System.out.println(Types.SMALLINT + " : SMALLINT");
			System.out.println(Types.SQLXML + " : XML");
			System.out.println(Types.STRUCT + " : STRUCT");
			System.out.println(Types.TIME + " : TIME");
			System.out.println(Types.TIMESTAMP + " : TIMESTAMP");
			System.out.println(Types.TINYINT + " : TINYINT");
			System.out.println(Types.VARBINARY + " : VARBINARY");
			System.out.println(Types.VARCHAR + " : VARCHAR");
		}

		try {
			String driver = "org.postgresql.Driver";
			String dbpath = "jdbc:postgresql://localhost/baraza";

			//String driver = "oracle.jdbc.driver.OracleDriver";
			//String dbpath = "jdbc:oracle:thin:@localhost:1521:crm";

			Class.forName(driver);
			Connection db = DriverManager.getConnection(dbpath, "root", "invent2k");
			//Connection db = DriverManager.getConnection(dbpath, "cck", "invent2k");
			DatabaseMetaData dbmd = db.getMetaData();
			System.out.println("DB Name : " + dbmd.getDatabaseProductName());

			/*String usql = "CREATE TABLE sys_errors (sys_error_id IDENTITY, sys_error varchar(50), error_message varchar(1000));";
			Statement ust = db.createStatement();
			ust.execute(usql);
			ust.close();*/

			String mysql = "SELECT sys_error_id, sys_error, error_message FROM sys_errors";

			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			ResultSet rs = st.executeQuery(mysql);
			ResultSetMetaData rsmd = rs.getMetaData();
			while (rs.next()) {
				System.out.println(rs.getString("sys_error_id")  + " : " + rs.getString("sys_error"));
			}

System.out.println("BASE 100 " + rsmd.getSchemaName(1));
			
			if(args.length > 0) {
				rs.moveToInsertRow();
				rs.updateString("sys_error", "sys error 4");
				rs.updateString("error_message", "System generated test error");
				rs.insertRow();
				rs.moveToCurrentRow();

System.out.println("BASE 200");
				//System.out.println(rs.getString("sys_error_id")  + " : " + rs.getString("sys_error"));

				/*mysql = "INSERT INTO sys_errors (sys_error, error_message) ";
				mysql += "VALUES ('" + args[0] + "', 'Test error')";
				Statement stIns = db.createStatement();
				stIns.execute(mysql, Statement.RETURN_GENERATED_KEYS);*/

				//ResultSet rsa = st.getGeneratedKeys();
				//if(rsa.next()) System.out.println(rsa.getString(1));

System.out.println("BASE 300");

				mysql = "INSERT INTO sys_errors (sys_error, error_message) VALUES (?, ?)";
				PreparedStatement ps = db.prepareStatement(mysql, Statement.RETURN_GENERATED_KEYS);
				ps.setString(1, "Light-Williams 14");
				ps.setString(2, "Corwin 12");
				ps.executeUpdate();

				ResultSet rsb = ps.getGeneratedKeys();
				while(rsb.next()) System.out.println(rsb.getString(1));

System.out.println("BASE 400");
				//stIns.close();
			}
			rs.close();
			st.close();
			db.close();
		} catch (ClassNotFoundException ex) {
			System.out.println("Class not found : " + ex);
		} catch (SQLException ex) {
			System.out.println("Database connection error : " + ex);
		}
	}
}
