
import java.sql.*;

import javax.swing.*;

import java.awt.*;
import java.util.*;
import java.util.logging.Logger;

public class generateSQL {
	
    static Logger log = Logger.getLogger(generateSQL.class.getName());
   
    public static void main(String[] args) {
		generateSQL gSQL = new generateSQL();
		gSQL.generate();
    }
    
    public void generate() {    	 
    	JFrame frame = new JFrame("Database Metadata");

		try{
			Class.forName("interbase.interclient.Driver");
			
			//Connection con = DriverManager.getConnection("jdbc:mysql://192.168.0.20:3306/acordhr", "root", "");
			Connection con = DriverManager.getConnection("jdbc:interbase://192.168.0.179/C:/Programs/Database/UEABPAYROLL.GDB", "SYSDBA", "masterkey");

			DatabaseMetaData dbmd = con.getMetaData();
			String[] types = {"TABLE"};
			ResultSet rs = dbmd.getTables(null, null, "%", types);

    	    while(rs.next()) {
				String table_schema = rs.getString("TABLE_SCHEM");
				String table_name = rs.getString("TABLE_NAME");
				String inStr = "INSERT INTO " + table_name + "(";
				String invStr = "SELECT ";

				if(table_schema == null) table_schema = "";
				else table_schema += ".";
				Statement stmt = con.createStatement();
				ResultSet rst = stmt.executeQuery("SELECT * FROM " + table_schema + table_name);
				ResultSetMetaData rsmd = rst.getMetaData();
				int numberOfCols = rsmd.getColumnCount();

				String fieldCons = "";				
				System.out.println("CREATE TABLE import." + table_name + " (");
				//System.out.println("CREATE FOREIGN TABLE " + table_name + "_i (");
				System.out.println("	id						serial primary key,");
				for(int i = 1; i <= numberOfCols; i++) {
					String field_name = rsmd.getColumnName(i);
					String column_type = rsmd.getColumnTypeName(i);
					
					if(rsmd.getColumnType(i) == 4) column_type = "integer";
					if(rsmd.getColumnType(i) == 12) {
						if(rsmd.getColumnDisplaySize(i)>10000) column_type = "text";
						else column_type = "varchar(" + rsmd.getColumnDisplaySize(i) + ")";
					}
					if(rsmd.getColumnType(i) == 93) column_type = "timestamp"; // default current_timestamp";
					
					/*if(!field_name.equals("syskey") && !field_name.equals("id")) {
						fieldCons = "\t" + rsmd.getColumnName(i) + "\t\t\t" + column_type;
						if(i != numberOfCols) fieldCons += ",";
					
						System.out.println(fieldCons);
					}*/
					fieldCons = "\t" + rsmd.getColumnName(i) + "\t\t\t" + column_type;
					inStr += rsmd.getColumnName(i);
					invStr += rsmd.getColumnName(i);
					if(i != numberOfCols) {	fieldCons += ", "; inStr += ", "; invStr += ", "; }

					System.out.println(fieldCons);
				}
				System.out.println(");\n");
				//System.out.println(")\nSERVER myserver1 OPTIONS(table_name '" + table_name + "');");
				//System.out.println("\n" + inStr + ")");
				//System.out.println(invStr + "\nFROM " + table_name + "_i;\n");
				
				rst.close();
				stmt.close();
			}
			rs.close();
			
			Vector<String> data =  new Vector<String>();
			Vector<String> columns = new Vector<String>();
    	    columns.add("Table Name");
    	    columns.add("Number of Rows");

			JTable table = new JTable(data, columns);
			table.setAutoCreateRowSorter(true);

			JScrollPane scrollPane = new JScrollPane(table);
			table.setFillsViewportHeight(true);

			JLabel lblHeading = new JLabel("Relations and their row count");
			lblHeading.setFont(new Font("Arial",Font.TRUETYPE_FONT,24));

			frame.getContentPane().setLayout(new BorderLayout());
			frame.getContentPane().add(lblHeading,BorderLayout.PAGE_START);
			frame.getContentPane().add(scrollPane,BorderLayout.CENTER);

			frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
			frame.setSize(550, 200);
			frame.setLocationRelativeTo(null);
			frame.setVisible(true);
		} catch (ClassNotFoundException ex) {
			log.severe("Cannot find the database driver classes. : " + ex);
    	} catch (SQLException ex) {
			log.severe("Error in Query : " + ex.toString());
       	}
      
    }

} 


