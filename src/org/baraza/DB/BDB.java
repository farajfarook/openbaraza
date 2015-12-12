/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.DB;

import java.util.logging.Logger;
import java.util.Date;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;
import java.sql.*;

import org.baraza.xml.BElement;
import org.baraza.utils.BLogHandle;

public class BDB {
	Logger log = Logger.getLogger(BDB.class.getName());
	Connection db = null;
	DatabaseMetaData dbmd = null;
	String dbTemplate = null;
	String dbschema = null;
	int dbType = 1;
	String orgID = null;
	BUser user = null;
	BLogHandle logHandle = null;

	private String lastErrorMsg = null;
	private String lDBclass;
	private String lDBpath;
	private String lDBuser;
	private String lDBpassword;
	private boolean readOnly = false;
	
	public BDB(BElement dbconfig) {
		String dbclass = dbconfig.getAttribute("dbclass", "");
		String dbpath = dbconfig.getAttribute("dbpath", ""); 
		String dbusername = dbconfig.getAttribute("dbusername", "");
		String dbpassword = dbconfig.getAttribute("dbpassword", "");
		dbTemplate = dbconfig.getAttribute("dbtemplate");
		dbschema = dbconfig.getAttribute("dbschema");
		orgID = dbconfig.getAttribute("org");
		if(dbconfig.getAttribute("readonly", "false").equals("true")) readOnly = true;

		connectDB(dbclass, dbpath, dbusername, dbpassword);
	}

	public BDB(BElement dbconfig, String dbuser, String dbpassword) {
		String dbclass = dbconfig.getAttribute("dbclass", "");
		String dbpath = dbconfig.getAttribute("dbpath", ""); 
		dbTemplate = dbconfig.getAttribute("dbtemplate");
		dbschema = dbconfig.getAttribute("dbschema");
		orgID = dbconfig.getAttribute("org");

		connectDB(dbclass, dbpath, dbuser, dbpassword);
	}

	public BDB(String dbclass, String dbpath, String dbuser, String dbpassword) {
		connectDB(dbclass, dbpath, dbuser, dbpassword);
	}

	// initialize the database and web output
	public BDB(String datasource) {
		try {
			InitialContext cxt = new InitialContext();
			DataSource ds = (DataSource) cxt.lookup(datasource);
			db = ds.getConnection();
			dbmd = db.getMetaData();
			String dbtype = dbmd.getDatabaseProductName();
			if(dbtype.toLowerCase().indexOf("oracle") >= 0) dbType = 2;
			if(dbtype.toLowerCase().indexOf("mysql") >= 0) dbType = 3;
		} catch (SQLException ex) {
			log.severe("Cannot connect to this database : " + ex);
        } catch (NamingException ex) {
			log.severe("Cannot pick on the database name : " + ex);
        }
	}

	public void connectDB(String dbclass, String dbpath, String dbuser, String dbpassword) {
		if(dbclass.toLowerCase().indexOf("oracle")>=0) dbType = 2;
		if(dbclass.toLowerCase().indexOf("mysql")>=0) dbType = 3;

		lDBclass = dbclass;
		lDBpath = dbpath;
		lDBuser = dbuser;
		lDBpassword = dbpassword;

		try {
			Class.forName(dbclass);  
			db = DriverManager.getConnection(dbpath, dbuser, dbpassword);
			dbmd = db.getMetaData();

			if(dbschema != null) {
				Statement exst = db.createStatement();
				exst.execute("ALTER session set current_schema=" + dbschema);
				exst.close();
			}
		} catch (ClassNotFoundException ex) {
			log.severe("Cannot find the database driver classes. : " + ex);
		} catch (SQLException ex) {
			log.severe("Database connection SQL Error : " + ex);
		}
	}
	
	public void setSchema(String dbSchema) {
		this.dbschema = dbSchema;

		if(dbschema != null) {
			try {
				Statement exst = db.createStatement();
				exst.execute("ALTER session set current_schema=" + dbschema);
				exst.close();
			} catch (SQLException ex) {
				log.severe("Database connection SQL Error : " + ex);
			}
		}
	}

	public void reconnect() {
		close();
		connectDB(lDBclass, lDBpath, lDBuser, lDBpassword);
	}
	
	public void newUser(String userIP, String userName) {
		user = new BUser(this, userIP, userName, true);
	}

	public void setUser(String userIP, String userName) {
		user = new BUser(this, userIP, userName);
		String mysql = "INSERT INTO sys_logins (entity_id, login_ip) VALUES ('";
		mysql += user.getUserID() + "', '" + userIP + "')";
		executeQuery(mysql);
	}

	public void setUser(String userIP, String userName, String narrative) {
		user = new BUser(this, userIP, userName);
		String mysql = "INSERT INTO sys_logins (entity_id, login_ip, narrative) VALUES ('";
		mysql += user.getUserID() + "', '" + userIP + "', '" + narrative + "')";
		executeQuery(mysql);
	}

	public void setUser(String tableName, String idCol, String nameCol, String userName) {
		user.setUser(this, tableName, idCol, nameCol, userName);
	}

	public void logConfig(BLogHandle logHandle) {
		this.logHandle = logHandle;
		logHandle.config(log);
	}

	public BLogHandle getLogHandle() {
		return logHandle;
	}

	public ResultSet readQuery(String mysql) {
		return readQuery(mysql, -1);
	}

	public ResultSet readQuery(String mysql, int limit) {
		ResultSet rs = null;

		try {
			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			if(limit > 0) st.setFetchSize(limit);
			rs = st.executeQuery(mysql);
		} catch (SQLException ex) {
			log.severe("Database readQuery error : " + ex);
		}

		return rs;
	}

	public String executeFunction(String mysql) {
		String ans = null;

		try {
			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			ResultSet rs = st.executeQuery(mysql);

			if(rs.next()) ans = rs.getString(1);
			rs.close();
			st.close();
		} catch (SQLException ex) {
			ans = null;
			lastErrorMsg = ex.getMessage();
			log.severe("Database executeFunction error : " + ex);
		}

		return ans;
	}
	
	public String executeFunction(String mysql, boolean readOnly) {
		String ans = null;

		try {
			Statement st = db.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
			ResultSet rs = st.executeQuery(mysql);

			if(rs.next()) ans = rs.getString(1);
			rs.close();
			st.close();
		} catch (SQLException ex) {
			ans = null;
			lastErrorMsg = ex.getMessage();
			log.severe("Database executeFunction error : " + ex);
		}

		return ans;
	}

	public String executeQuery(String mysql) {
		String rst = null;

		try {
			Statement st = db.createStatement();
			st.execute(mysql);
			st.close();
		} catch (SQLException ex) {
			rst = ex.toString();
			lastErrorMsg = ex.toString();
			log.severe("Database executeQuery error : " + ex);
		}

		return rst;
	}

	public String executeAutoKey(String mysql) {
		String rst = null;

		try {
			Statement st = db.createStatement();
			st.execute(mysql, Statement.RETURN_GENERATED_KEYS);

			ResultSet rsa = st.getGeneratedKeys();
			if(rsa.next()) rst = rsa.getString(1);
			rsa.close();

			st.close();
		} catch (SQLException ex) {
			rst = null;
			lastErrorMsg = ex.toString();
			log.severe("Database executeQuery error : " + ex);
		}

		return rst;
	}

	public String executeUpdate(String updsql) {
		String rst = null;

		try {
			Statement stUP = db.createStatement();
			stUP.executeUpdate(updsql);
			stUP.close();
		} catch (SQLException ex) {
			rst = ex.toString();
			lastErrorMsg = ex.getMessage();
			System.err.println("Database transaction get data error : " + ex);
		}

		return rst;
	}

	public String executeBatch(String mysql) {
		String rst = null;

		try {
			Statement st = db.createStatement();
			String[] lines = mysql.split(";");
			for(String line : lines) {
				if(!"".equals(line.trim()))
					st.addBatch(line);
			}
			st.executeBatch();
			st.close();
		} catch (SQLException ex) {
			rst = ex.toString();
			log.severe("Database executeBatch error : " + ex);
		}

		return rst;
	}

	public Clob createClob() {
		Clob clb = null;
		try {
			clb = db.createClob();
		} catch (SQLException ex) {
			log.severe("Clob Creation error : " + ex);
		}

		return clb;
	}

	public Map<String, String> getFieldsData(String fields[], String mysql) {
		Map<String, String> ans = new HashMap<String, String>();

		try {
			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			ResultSet rs = st.executeQuery(mysql);

			if(rs.next()) {
				for(String field : fields) ans.put(field.trim(), rs.getString(field.trim()));
			}
			rs.close();
			st.close();
		} catch (SQLException ex) {
			lastErrorMsg = ex.getMessage();
			log.severe("Database executeFunction error : " + ex);
		}

		return ans;
	}

	public Map<String, String> readFields(String myFields, String mysource) {
		String fields[] = myFields.split(",");
		Map<String, String> ans = getFieldsData(fields, "SELECT " + myFields + " FROM " + mysource);

		return ans;
	}

	// Get the table names
	public List<String> getTables() {
		List<String> tableList = new ArrayList<String>();
		try {
			String[] types = {"TABLE"};
        	ResultSet rs = dbmd.getTables(null, dbschema, "%", types);
    		while (rs.next()) {
				String tableName = rs.getString(3);
				if(tableName.indexOf("$")<0)
					tableList.add(tableName);
			}
		} catch (SQLException ex) {
			log.severe("Table Listing error : " + ex);
		}

		return tableList;
	}

	// Get the view names
	public List<String> getViews() {
		List<String> viewList = new ArrayList<String>();
		try {
			String[] types = {"VIEW"};
        	ResultSet rs = dbmd.getTables(null, dbschema, "%", types);
    		while (rs.next()) viewList.add(rs.getString(3));
		} catch (SQLException ex) {
			log.severe("Table Listing error : " + ex);
		}

		return viewList;
	}

    public List<BTableLinks> getForeignLinks(String tablename) {
		List<BTableLinks> fkList = new ArrayList<BTableLinks>();

   		try {
			ResultSet tablemd = dbmd.getImportedKeys(null, null, tablename);

			while(tablemd.next()) {
				fkList.add(new BTableLinks(tablemd.getString(7), tablemd.getString(8), tablemd.getString(3), tablemd.getString(4)));
				//System.out.println(tablemd.getString(7) + "." + tablemd.getString(8) + " = " + tablemd.getString(3) + "." + tablemd.getString(4));
			}
		} catch (SQLException ex) {
			log.severe("Table Listing error : " + ex);
		}

		return fkList;
	}

	public BElement getAppConfig(BElement root) {
		try {
			String[] types = {"TABLE"};
        	ResultSet rs = dbmd.getTables(null, null, "%", types);
			
			// Make the menu
			Integer i = 1;
			BElement menu = new BElement("MENU");
			menu.setAttribute("name", root.getAttribute("name"));
    		while (rs.next()) {
				String tableName = rs.getString(3);
				if(!tableName.toLowerCase().startsWith("sys_")) {
					BElement mel = new BElement("MENU");
					mel.setAttribute("name", initCap(tableName));
					mel.setValue((i++).toString());
					menu.addNode(mel);
				}
			}
			root.addNode(menu);

			i = 1;
			rs = dbmd.getTables(null, null, "%", types);
			while (rs.next()) {
				String tableName = rs.getString(3);
				BQuery query = new BQuery(this, "*", tableName, 2);

				if(!tableName.toLowerCase().startsWith("sys_")) {
					BElement del = new BElement("DESK");
					del.setAttribute("h", "500");
					del.setAttribute("w", "700");
					del.setAttribute("name", initCap(tableName));
					del.setAttribute("key", (i++).toString());
					del.addNode(query.getDeskConfig(0));
					root.addNode(del);
				}

				query.close();
			}
		} catch (SQLException ex) {
			log.severe("App Config Creation error : " + ex);
		}

		return root;
	}

	public void createdb(String dbName) {
		String mysql = "CREATE DATABASE " + dbName;
		if(dbTemplate != null) mysql += " TEMPLATE " + dbTemplate;
		
		executeQuery(mysql);
	}

	public void dropdb(String dbName) {	
		String mysql = "DROP DATABASE " + dbName;
		
		executeQuery(mysql);
	}

	public String getViewSQL() {	
		String views = "";
		try {
			// Get the table name
			String[] tabletypes = {"TABLE"};
        	ResultSet tablers = dbmd.getTables(null, dbschema, "%", tabletypes);			
    		while (tablers.next()) {
            	String tableName = tablers.getString(3);
				views += getViewSQL(tableName);
        	}

			tablers.close();
        } catch (SQLException ex) {
        	log.severe("SQL Error : " + ex);
        }

		return views;	
	}

    public String getViewSQL(String tablename) {
		String mystr = "\n\nCREATE VIEW vw_" + tablename + " AS";
		mystr += "\n\tSELECT ";
   		try {
			String mysql = "SELECT * FROM " + tablename;
			ResultSet tablemd = dbmd.getImportedKeys(null, null, tablename);
            Statement st = db.createStatement();
			st.setFetchSize(50);
            ResultSet rs = st.executeQuery(mysql);
            ResultSetMetaData rsmd = rs.getMetaData();
			int colnum = rsmd.getColumnCount();    // Get column numbers
            boolean linked = false;

			List<String> fieldNames = new ArrayList<String>();

			String strfrom = "\n\tFROM " + tablename; 
			while(tablemd.next()) {
				if(linked) mystr += ", ";
				mystr += tablemd.getString(3) + "." + tablemd.getString(4) + ", ";
				mystr += tablemd.getString(3) + "." + tablemd.getString(4).replaceFirst("id", "name");
				fieldNames.add(tablemd.getString(4));

				strfrom += "\n\tINNER JOIN " + tablemd.getString(3);
				strfrom += " ON " + tablename + "." + tablemd.getString(8);
				strfrom += " = " + tablemd.getString(3) + "." + tablemd.getString(4);
								
				linked = true;
			}
			
			if(linked) {
				for (int column=1; column <= colnum; column++) {
					if(!fieldNames.contains(rsmd.getColumnLabel(column)))
						mystr += ", " + tablename + "." + rsmd.getColumnLabel(column);
				}

				mystr += strfrom + ";";
			} else {
				for (int column=1; column <= colnum; column++) {
					if(column > 1) mystr += ", ";
					mystr += tablename + "." + rsmd.getColumnLabel(column);
				}
				mystr += strfrom + ";";
			}

			rs.close();
			st.close();
			tablemd.close();			
        } catch (SQLException ex) {
        	log.severe("Function getViewSQL Error : " + ex);
        }

		return mystr;
	}

	public String initCap(String mystr) {
		if(mystr != null) {
			String[] mylines = mystr.toLowerCase().split("_");
			mystr = "";
			for(String myline : mylines) {
				if(myline.length()>0)
					myline = myline.replaceFirst(myline.substring(0, 1), myline.substring(0, 1).toUpperCase());
				mystr += myline + " ";
			}
			mystr = mystr.trim();
		}
		return mystr;
	}

	public boolean isValid() {
		boolean dbv = false;
		try {
			if(db != null) {
				Statement tst = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
				ResultSet trs = tst.executeQuery("SELECT 1;");
				trs.close();
				tst.close();
				dbv = true;
			}
		} catch (SQLException ex) {
			log.severe("DB Validation Error : " + ex);
		}
		return dbv;
	}

	public String insAudit(String tableName, String recordID, String functionType) {
		String inssql = "INSERT INTO sys_audit_trail (user_id, user_ip, table_name, record_id, change_type) VALUES('";
		inssql += getUserID() + "', '" + getUserIP() + "', '" + tableName + "', '" + recordID  + "', '" + functionType + "')";
		String autoKeyID = executeAutoKey(inssql);

		return autoKeyID;
	}

	public Connection getDB() { return db; }
	public DatabaseMetaData getDBMetaData() { return dbmd; }
	public int getDBType() { return dbType; }
	public BUser getUser() { return user; }
	public String getUserID() { return user.getUserID(); }
	public String getUserIP() { return user.getUserIP(); }
	public String getUserOrg() { return user.getUserOrg(); }
	public String getUserName() { return user.getUserName(); }
	public boolean getSuperUser() { return user.getSuperUser(); }
	public List<String> getUserRoles() { return user.getUserRoles(); }
	public List<String> getGroupRoles() { return user.getGroupRoles(); }

	public String getOrgID() { return orgID; }
	public void setOrgID(String orgID) { this.orgID = orgID; }
	public String getOrgWhere(String orgTable) { return user.getOrgWhere(orgTable); }
	public String getOrgAnd(String orgTable) { return user.getOrgAnd(orgTable); }
	public String getDBSchema() { return dbschema; }

	public String getStartView() { return user.getStartView(); }

	public String getLastErrorMsg() { return lastErrorMsg; }
	
	public void setReadOnly(boolean readOnly) { this.readOnly = readOnly; }
	public boolean getReadOnly() { return readOnly; }

	public void close() {
		try {
			if(db != null) db.close();
			db = null;
		} catch (SQLException ex) {
			log.severe("SQL Error : " + ex);
		}
	}

}
