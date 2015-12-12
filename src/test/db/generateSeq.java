import java.sql.*;
import java.util.*;

public class generateSeq {
   
    public static void main(String[] args) {
		generateSeq gSeq = new generateSeq();
		gSeq.generate();
    }
    
    public void generate() {  
		try{
			//Connection con = DriverManager.getConnection("jdbc:mysql://192.168.0.20:3306/acordhr", "root", "");
			Connection con = DriverManager.getConnection("jdbc:postgresql://192.168.0.3/hr", "root", "invent2k");
			
			DatabaseMetaData dbmd = con.getMetaData();
			String[] types = {"TABLE"};
			ResultSet rs = dbmd.getTables(null, null,"%",types);
			
    	    while(rs.next()) {
				String table_schema = rs.getString("TABLE_SCHEM");
				String table_name = rs.getString("TABLE_NAME");
				
				ResultSet pkRs = dbmd.getPrimaryKeys(null, table_schema, table_name);
				if(pkRs.next()) {
					Statement stmt = con.createStatement();
					String seqSql = "SELECT max(" + pkRs.getString("COLUMN_NAME") + ") as max_key ";
					seqSql += "FROM " + table_schema + "." + table_name;
					ResultSet rst = stmt.executeQuery(seqSql);
					
					if(rst.next()) {
						if(rst.getString("max_key") != null) {
							seqSql = "SELECT setval('";
							seqSql += table_schema + "." + table_name + "_" + pkRs.getString("COLUMN_NAME") + "_seq";
							seqSql += "', " + rst.getString("max_key") + ");";
							System.out.println(seqSql);
						}
					}
					
					rst.close();
					stmt.close();
				}				
			}
			rs.close();
			

    	} catch (SQLException e) {
			System.out.println("Error in Query : " + e.toString());
       	}
      
    }

} 


