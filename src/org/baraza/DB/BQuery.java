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
import java.math.BigDecimal;
import java.lang.StringBuffer;
import java.text.SimpleDateFormat;
import java.text.NumberFormat;
import java.text.DecimalFormat;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.Vector;
import java.lang.NumberFormatException;
import java.sql.*;

import org.baraza.xml.BElement;
import org.baraza.utils.BCipher;
import org.baraza.utils.Bio;
import org.baraza.utils.BLogHandle;

public class BQuery {
	Logger log = Logger.getLogger(BQuery.class.getName());
	int tableLimit = -1;
	BElement view = null;
	BDB db = null;
	Statement st = null;
	ResultSet rs = null;
	ResultSetMetaData rsmd = null;
	boolean isAddNew = false;
	boolean isEdit = false;
	String tableSelect = null;
	String tableName;
	String updateTable = null;
	int colnum = 0;
	Vector<Vector<Object>> data;
	Vector<String> titles;
	Vector<String> fieldNames;
	Vector<String> keyFieldData;
	Vector<String> autoFields;
	List<Boolean> columnEdit;
	List<BTableLinks> ForeignLinks = null;
	Map<String, String> params;
	Map<String, String> addNewBlock;
	String keyField;
	String mysql = null;
	String auditID = null;
	boolean firstFetch = true;
	boolean noaudit = false;
	boolean readonly = false;
	boolean iforg = false;
	int errCode = 0;
	
	Integer rowStart = null;
	Integer fertchSize = null;

	String orgID = null;
	String userOrg = null;

	public BQuery() {
		init();
	}

	public BQuery(String[] titleArray) {
		init();
		for(String mnName : titleArray) titles.add(mnName);
	}

	public BQuery(BDB db, BElement view, String wheresql, String orderby, boolean ff) {
		firstFetch = ff;
		buildQuery(db, view, wheresql, orderby);
	}
	
	public BQuery(BDB db, BElement view, String wheresql, String orderby, boolean ff, Integer rowStart, Integer fertchSize) {
		this.firstFetch = ff;
		this.rowStart = rowStart;
		this.fertchSize = fertchSize;
		buildQuery(db, view, wheresql, orderby);
	}

	public BQuery(BDB db, BElement view, String wheresql, String orderby) {
		buildQuery(db, view, wheresql, orderby);
	}
	
	public void buildQuery(BDB db, BElement view, String wheresql, String orderby) {
		init();
		this.view = view;
		this.db = db;

		tableName = view.getAttribute("table");
		keyField = view.getAttribute("keyfield");
		String keyFnct = view.getAttribute("key_fnct");
		tableLimit = Integer.valueOf(view.getAttribute("limit", "0"));
		updateTable = view.getAttribute("updatetable");
		auditID = view.getAttribute("auditid");
		String linkField = view.getAttribute("linkfield");
		String hint = view.getAttribute("hint");
		String reportTitle = view.getAttribute("reporttitle");
		String paramStr = view.getAttribute("params");
		String inputParamStr = view.getAttribute("inputparams");
		boolean hasKF = true;
		String colNames = "";
		if(view.getAttribute("noaudit", "false").equals("true")) noaudit = true;
		if(view.getAttribute("readonly", "false").equals("true")) readonly = true;

		for(BElement el : view.getElements()) {
			String colName = el.getValue();

			if(!colName.equals("")) {
				if(!fieldNames.contains(colName)) {
					String function = el.getAttribute("fnct");
					if(el.getName().equals("ACTION")) function = null;
					if(!colNames.equals("")) colNames += ", ";
					if(function != null) colNames += "(" + function + ") as " + colName;
					else colNames += colName;

					fieldNames.add(colName);
				}

				if((el.getAttribute("title") != null) || (el.getAttribute("tab") != null)) {
					titles.add(el.getAttribute("title"));

					if(el.getAttribute("edit", "false").equals("true")) columnEdit.add(true);
					else columnEdit.add(false);
				}
			}
		}

		if((keyField != null) && !fieldNames.contains(keyField)) {
			if(keyFnct == null) colNames += ", " + keyField;
			else colNames += ", (" + keyFnct + ") as " + keyField;
			fieldNames.add(keyField);
		}

		colNames = addField(colNames, linkField);
		colNames = addField(colNames, hint);
		colNames = addField(colNames, reportTitle);
		for(BElement el : view.getElements()) colNames = addField(colNames, el.getAttribute("editkey"));

		if(paramStr != null) {
			String paramArr[] = paramStr.split(",");
			for(String param : paramArr) {
				params.put(param.trim().toLowerCase(), null);
				colNames = addField(colNames, param.trim().toLowerCase());
			}
		}

		if(inputParamStr != null) {
			String paramArr[] = inputParamStr.split(",");
			for(String param : paramArr) {
				String inParamArr[] = param.split("=");
				colNames = addField(colNames, inParamArr[0].trim().toLowerCase());
			}
		}

		orgID = db.getOrgID();
		if((orgID != null) && (view.getAttribute("noorg") == null)) {
			userOrg = db.getUserOrg();
			if(view.getAttribute("orgid") != null) orgID = view.getAttribute("orgid");
			if(view.getAttribute("noorg.query") == null) colNames = addField(colNames, orgID);
		}
		if(view.getAttribute("noorg") == null) iforg = true;
		else iforg = false;

		if(auditID != null) {
			if(view.getName().equals("FORM")) {
				colNames = addField(colNames, auditID);
			}
		}

		tableSelect = "SELECT " + colNames + "\nFROM " + tableName;

		if(tableName != null) {
			// Where clause section
			filterBuild(wheresql, orderby);

			log.fine(mysql);
			makeQuery();

			// Read the data
			if(firstFetch) readData();
		}
	}

	public String addField(String colNames, String colName) {
		if(colName == null) return colNames;
		if(!fieldNames.contains(colName)) {
			colNames += ", " + colName;
			fieldNames.add(colName);
		}
		return colNames;
	}

	public BQuery(BDB db, String myfields, String tableName, int limit) {
		init();
		this.db = db;
		this.tableName = tableName;
		tableLimit = limit;
		
		mysql = "SELECT " + myfields +  "\nFROM " + tableName;
		makeQuery();

		if(tableLimit > 0) ForeignLinks = db.getForeignLinks(tableName);
	}

	public BQuery(BDB db, String mysql) {
		init();
		this.db = db;
		this.mysql = mysql;

		makeQuery();
	}

	public BQuery(BDB db, String mysql, int limit) {
		init();
		this.db = db;
		this.mysql = mysql;
		tableLimit = limit;

		makeQuery();
	}

	public void init() {
		titles = new Vector<String>();
		fieldNames = new Vector<String>();
		keyFieldData = new Vector<String>();
		autoFields = new Vector<String>();
		data = new Vector<Vector<Object>>();
		columnEdit = new ArrayList<Boolean>();

		params = new HashMap<String, String>();
		addNewBlock = new HashMap<String, String>();
	}

	public void makeQuery() {
		if(db != null) {
			BLogHandle lh = db.getLogHandle();
			if(lh != null) lh.config(log);
		}
		
		if(db.getReadOnly()) readonly = true;

		try {
			if(readonly) st = db.getDB().createStatement();
			else st = db.getDB().createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			if(tableLimit > 0) st.setFetchSize(tableLimit);
			else if(tableLimit == 0) st.setFetchSize(1000);

			rs = st.executeQuery(mysql);
            rsmd = rs.getMetaData();
            colnum = rsmd.getColumnCount();    // Get column numbers
		} catch (SQLException ex) {
			rs = null;
			log.severe("Get Table read and Metadata Error : " + ex);
			log.severe("SQL " + mysql);
		}

		if(view == null) {
			titles = new Vector<String>(getFields());
			fieldNames = new Vector<String>(getFields());
		}

		// Get Auto Field
		getAutoFields();
	}

	public void refresh() {
		try {
			rs = st.executeQuery(mysql);
		} catch (SQLException ex) {
			log.severe("Get Table refresh Error : " + ex);
		}
	}

	public void filter(String wheresql, String orderby) {
		if(tableSelect != null) {
			filterBuild(wheresql, orderby);

			log.fine(mysql);
			makeQuery();
		}
	}

	public void filterBuild(String wheresql, String orderby) {
		mysql = tableSelect;

		// where sql
		if(wheresql != null) wheresql = "\nWHERE " + wheresql;
		if(view != null) {
			if(view.getAttribute("where") != null) {
				if(wheresql == null) wheresql = "\nWHERE " + view.getAttribute("where");
				else wheresql += " AND " + view.getAttribute("where");
			}
			if(view.getAttribute("user") != null) {
				String userFilter = "(" + view.getAttribute("user") + " = '" + db.getUserID() + "')";
				if(wheresql == null) wheresql = "\nWHERE " + userFilter;
				else wheresql += " AND " + userFilter;
			}
			if((view.getAttribute("noorg") == null) && (db.getOrgID() != null) && (db.getUserOrg() != null)) {
				String qorgID = db.getOrgID();
				if(view.getAttribute("orgid") != null) qorgID = view.getAttribute("orgid");
				String orgFilter = "(" + qorgID + " = '" + db.getUserOrg() + "')";
				if(wheresql == null) wheresql = "\nWHERE " + orgFilter;
				else wheresql += " AND " + orgFilter;
			}
			if((view.getAttribute("user_fnct") != null) && (view.getAttribute("user_field") != null)) {
				String userFnct = "SELECT " + view.getAttribute("user_fnct") + "('" + db.getUserID() + "')";
				userFnct = db.executeFunction(userFnct);
				userFnct = "(" + view.getAttribute("user_field") + " = '" + userFnct + "')";

				if(wheresql == null) wheresql = "\nWHERE " + userFnct;
				else wheresql += " AND " + userFnct;
			}
		}
		if(wheresql != null) mysql += wheresql;
		// SQL view debug point
		//System.out.println("SQL : " + wheresql);

		// Group by
		if(view != null) {
			if(view.getAttribute("groupby") != null)
				mysql += "\nGROUP BY " + view.getAttribute("groupby");
		}

		// order by section
		if(orderby != null) orderby = "\nORDER BY " + orderby;
		if(view != null) {
			if(view.getAttribute("orderby") != null) {
				if(orderby == null) orderby = "\nORDER BY " + view.getAttribute("orderby");
				else orderby += ", " + view.getAttribute("orderby");
			}
			if((keyField != null) && (orderby == null))
				orderby = "\nORDER BY " + keyField;
		}
		if(orderby != null) mysql += orderby;
		
		/*if((rowStart != null) && (fertchSize != null)) {
			mysql += "\nOFFSET " + rowStart.toString() + " LIMIT " + fertchSize.toString();
		}*/

		// SQL view debug point
		//System.out.println("SQL : " + mysql);
	}

	public void setSQL(String lsql) {
		mysql = lsql;
	}

	public boolean moveNext() {
		boolean ans = false;

		try {
			if(rs != null) ans = rs.next();
		} catch (SQLException ex) {
			log.severe("Table move next error : " + ex);
		}

		return ans;
	}

	public boolean movePrevious() {
		boolean ans = false;

		try {
			if(rs != null) ans = rs.previous();
		} catch (SQLException ex) {
			log.severe("Table move previous error : " + ex);
		}

		return ans;
	}

	public int getRow() {
		int ans = -1;

		try {
			if(rs != null) ans = rs.getRow();
		} catch (SQLException ex) {
			log.severe("Table move to row error : " + ex);
		}

		return ans;
	}

	public boolean moveFirst() {
		boolean ans = false;

		try {
			if(rs != null) ans = rs.first();
		} catch (SQLException ex) {
			log.severe("Table move first error : " + ex);
		}

		return ans;
	}

	public boolean moveLast() {
		boolean ans = false;

		try {
			if(rs != null) ans = rs.last();
		} catch (SQLException ex) {
			log.severe("Table move last error : " + ex);
		}

		return ans;
	}

	public void beforeFirst() {
		try {
			if(rs != null) rs.beforeFirst();
		} catch (SQLException ex) {
			log.severe("Table move first error : " + ex);
		}
	}


	public boolean isLast() {
		boolean ans = false;
		try {
			if(rs != null) ans = rs.isLast();
		} catch (SQLException ex) {
			log.severe("Table islast check error : " + ex);
		}
		return ans;
	}

	public boolean isFirst() {
		boolean ans = false;
		try {
			if(rs != null) ans = rs.isFirst();
		} catch (SQLException ex) {
			log.severe("Table isFirst check error : " + ex);
		}
		return ans;
	}

	public boolean movePos(int pos) {
		boolean ans = false;

		try {
			if(rs != null) ans = rs.absolute(pos);
		} catch (SQLException ex) {
			log.severe("Table absolute move error : " + ex);
		}

		return ans;
	}

	public void reset() {
		try {
			if(rs != null) rs.beforeFirst();
		} catch (SQLException ex) {
			log.severe("Table move before first data error : " + ex);
		}
	}

	public int rowNumber() {
		int ans = 0;

		try {
			if(rs != null) ans = rs.getRow();
		} catch (SQLException ex) {
			log.severe("Table get row number error : " + ex);
		}

		return ans;
	}

	public String readField(String fieldName) {
		String ans = null;

		try {
			ans = rs.getString(fieldName);
		} catch (SQLException ex) {
			log.severe("Data field read error : " + ex);
		}

		return ans;
	}

	public String readField(int fieldPos) {
		String ans = null;

		try {
			ans = rs.getString(fieldPos);
		} catch (SQLException ex) {
			log.severe("Data field read error : " + ex);
		}

		return ans;
	}

	public String getString(String fieldName) {
		return readField(fieldName);
	}

	public int getInt(String fieldName) {
		int ans = 0;

		try {
			ans = rs.getInt(fieldName);
		} catch (SQLException ex) {
			log.severe("Data field read error : " + ex);
		}

		return ans;
	}

	public Float getFloat(String fieldName) {
		Float ans = new Float("0.0");

		try {
			ans = rs.getFloat(fieldName);
		} catch (SQLException ex) {
			log.severe("Data field read error : " + ex);
		}

		return ans;
	}

	public Double getDouble(String fieldName) {
		Double ans = new Double("0.0");

		try {
			ans = rs.getDouble(fieldName);
		} catch (SQLException ex) {
			log.severe("Data field read error : " + ex);
		}

		return ans;
	}

	public Date getDate(String fieldName) {
		Date ans = null;

		try {
			ans = rs.getDate(fieldName);
		} catch (SQLException ex) {
			log.severe("Data field read error : " + ex);
		}

		return ans;
	}

	public Time getTime(String fieldName) {
		Time ans = null;

		try {
			ans = rs.getTime(fieldName);
		} catch (SQLException ex) {
			log.severe("Data field read error : " + ex);
		}

		return ans;
	}

	public Boolean getBoolean(String fieldName) {
		Boolean ans = false;

		try {
			ans = rs.getBoolean(fieldName);
		} catch (SQLException ex) {
			log.severe("Data field read error : " + ex);
		}

		return ans;
	}

	public String getFormatField(int fieldPos) {
		String ans = "";
		int fldPos = fieldPos + 1;
		try {
			int type = getFieldType(fldPos);
			if((type == Types.DATE) || (type == Types.TIME) || (type == Types.TIMESTAMP)) {
				SimpleDateFormat dateParse = new SimpleDateFormat("dd-MMM-yyyy");
				if(rs.getString(fldPos)!=null)
					ans = dateParse.format(rs.getDate(fldPos));
			} else {
				ans = rs.getString(fldPos);
			}

			if(ans == null) ans = "";
		} catch (SQLException ex) {
			log.severe("Data field read error : " + ex);
		}

		return ans;
	}

	public String updateField(String fname, String fvalue) {
		String errMsg = "";
		if(isAddNew) { 
			if(fvalue != null) {
				if(fvalue.length()>0)
					addNewBlock.put(fname, fvalue);
			}
		} else {
			errMsg = updateRecField(fname, fvalue);
		}
		return errMsg;
	}

	public String updateRecField(String fname, String fvalue) {
		int type;
		String errMsg = "";

		if(isEdit) {
			String oldvalue = readField(fname);
			if(oldvalue == null) {
				if (fvalue == null) return errMsg;
			} else {
				if (oldvalue.equals(fvalue)) return errMsg;
			}
		}
		
        try {
			int columnindex = rs.findColumn(fname);
			if(fvalue == null) {
				rs.updateNull(fname);
		    } else if(fvalue.length()<1) {
				rs.updateNull(fname);
		    } else {
				type = getFieldType(columnindex);
	
				//System.out.println("BASE 4010 : " + fname + " = " + fvalue + " type = " + type);
				switch(type) {
        			case Types.CHAR:
        			case Types.VARCHAR:
        			case Types.LONGVARCHAR:
            			rs.updateString(fname, fvalue);
						break;
       				case Types.BIT:
						if(fvalue.equals("true")) rs.updateBoolean(fname, true);
						else rs.updateBoolean(fname, false);
						break;
        			case Types.TINYINT:
        			case Types.SMALLINT:
        			case Types.INTEGER:
						int ivalue = Integer.valueOf(fvalue).intValue();
						rs.updateInt(fname, ivalue);
						break;
					case Types.NUMERIC:
						BigDecimal bdValue = new BigDecimal(fvalue);
						rs.updateBigDecimal(fname, bdValue);
						break;
		        	case Types.BIGINT:
						long lvalue = Long.valueOf(fvalue).longValue();
						rs.updateLong(fname, lvalue);
						break;
		        	case Types.FLOAT:
		        	case Types.DOUBLE:
					case Types.REAL:
						double dvalue = Double.valueOf(fvalue).doubleValue();
						rs.updateDouble(fname, dvalue);
						break;
		        	case Types.DATE:
						java.sql.Date dtvalue = java.sql.Date.valueOf(fvalue);
						rs.updateDate(fname, dtvalue);
						break;
		        	case Types.TIME:
						java.sql.Time tvalue = Time.valueOf(fvalue);
						rs.updateTime(fname, tvalue);
						break;
					case Types.TIMESTAMP:
						java.sql.Timestamp tsvalue = java.sql.Timestamp.valueOf(fvalue);
						rs.updateTimestamp(fname, tsvalue);
						break;
					case Types.CLOB:
						Clob clb = db.createClob();
						clb.setString(1, fvalue);
						rs.updateClob(fname, clb);
						break;
				}
		   	}
        } catch (SQLException ex) {
			errMsg = fname + " : " + ex.getMessage() + "\n";
        	log.severe("The SQL Exeption on update field " + fname + " : " + ex);
        } catch (NumberFormatException ex) {
			errMsg = fname + " : " + ex.getMessage() + "\n";
        	log.severe("Number format exception on field = " + fname + " : value = " + fvalue + " : " + ex);
		}

		return errMsg;
	}

	public String recDelete() {
		String errMsg = null;
		errCode = 0;
		try {
			String recordid = getKeyField();
			rs.deleteRow();
			recAudit("DELETE", recordid);
		} catch (SQLException ex) {
			errMsg = getErrMessage(ex.getMessage()) + "\n";
			errCode = ex.getErrorCode();
       		log.severe("Delete row error : " + ex);
		}

		return errMsg;
	}

	public boolean recAdd() {
		addNewBlock = new HashMap<String, String>();
		isAddNew = true;
		errCode = 0;

		return isAddNew;
	}

	public boolean recEdit() {
		errCode = 0;
		if(!isAddNew) isEdit = true;
		return isEdit;
	}

	public String recSave() {
		String errMsg = "";
		errCode = 0;
		try {
			if(isAddNew) {
				errMsg = saveNewRec();

				if(errMsg == null) {
					recAudit("INSERT", null);
					isAddNew = false;
				}
			} else if(isEdit) {
				if(auditID != null) {
					String autoKeyID = db.insAudit(tableName, getString(keyField), "PREPARE");
					rs.updateInt(auditID,  Integer.valueOf(autoKeyID));
				}

				rs.updateRow();
				rs.moveToCurrentRow();
				recAudit("EDIT", null);
				isEdit = false;
			}
 		} catch (SQLException ex) {
			errCode = ex.getErrorCode();
			errMsg = getErrMessage(null);
			if(errMsg == null) errMsg = ex.getMessage() + "\n";
			else errMsg += "\n";

         	log.severe("Update record error : " + ex);
			log.severe("The error code " + errCode);
        }

		if(errMsg == null) errMsg = "";

		return errMsg;
	}

	public String saveNewRec() {
		String errMsg = null;
		String fname = "";
		String fvalue = "";
		String newKeyField = null;

		if(auditID != null) {
			String autoKeyID = db.insAudit(tableName, "NEW", "PREPARE");
			addNewBlock.put(auditID, autoKeyID);
		}

		if((iforg) && (orgID != null)) {
			if(!addNewBlock.containsKey(orgID)) {
				if(userOrg != null) addNewBlock.put(orgID, userOrg);
				else addNewBlock.put(orgID, "0");
			}
		}
		
		

		String usql = "INSERT INTO " + tableName + " (";
		if(db.getDBSchema() != null) usql = "INSERT INTO " + db.getDBSchema() + "." + tableName + " (";
		String psql = ") VALUES (";
		boolean ff = true;
		for (String field : addNewBlock.keySet()) {
			if(ff) { ff = false; }
			else { usql += ", "; psql += ", ";}

			usql += field;
			psql += "?";
		}
		usql += psql + ")";
		log.fine("BASE 100 : " + usql);

        try {
			PreparedStatement ps = db.getDB().prepareStatement(usql, Statement.RETURN_GENERATED_KEYS);
			int col = 1;
			for (String field : addNewBlock.keySet()) {
				fname = field;
				fvalue = addNewBlock.get(field);
				int type = getFieldType(rs.findColumn(field));
				log.fine("BASE 1010 : " + col + " : " + fname + " : " + fvalue + " : " + type);

				switch(type) {
        			case Types.CHAR:
        			case Types.VARCHAR:
        			case Types.LONGVARCHAR:
            			ps.setString(col, fvalue);
						break;
       				case Types.BIT:
						if(fvalue.equals("true")) ps.setBoolean(col, true);
						else ps.setBoolean(col, false);
						break;
        			case Types.TINYINT:
        			case Types.SMALLINT:
        			case Types.INTEGER:
						int ivalue = Integer.valueOf(fvalue).intValue();
						ps.setInt(col, ivalue);
						break;
					case Types.NUMERIC:
						BigDecimal bdValue = new BigDecimal(fvalue);
						ps.setBigDecimal(col, bdValue);
						break;
		        	case Types.BIGINT:
						long lvalue = Long.valueOf(fvalue).longValue();
						ps.setLong(col, lvalue);
						break;
		        	case Types.FLOAT:
		        	case Types.DOUBLE:
					case Types.REAL:
						double dvalue = Double.valueOf(fvalue).doubleValue();
						ps.setDouble(col, dvalue);
						break;
		        	case Types.DATE:
						java.sql.Date dtvalue = java.sql.Date.valueOf(fvalue);
						ps.setDate(col, dtvalue);
						break;
		        	case Types.TIME:
						java.sql.Time tvalue = Time.valueOf(fvalue);
						ps.setTime(col, tvalue);
						break;
					case Types.TIMESTAMP:
						java.sql.Timestamp tsvalue = java.sql.Timestamp.valueOf(fvalue);
						ps.setTimestamp(col, tsvalue);
						break;
					case Types.CLOB:
						Clob clb = db.createClob();
						clb.setString(1, fvalue);
						ps.setClob(col, clb);
						break;
					default:
            			ps.setString(col, fvalue);
						break;
				}
				col++;
			}
			ps.executeUpdate();

			ResultSet rsb = ps.getGeneratedKeys();
			if(rsb.next()) {
				newKeyField = rsb.getString(1);
				//System.out.println(db.getDBType() + " : rowid = '" + newKeyField + "'");

				if(db.getDBType() == 2) filter("rowid = '" + newKeyField + "'", null);
				else filter(getKeyFieldName() + " = '" + newKeyField + "'", null);
				moveFirst();
			}
        } catch (SQLException ex) {
			errCode = ex.getErrorCode();
			errMsg = getErrMessage(null);
			if(errMsg == null) errMsg = fname + " : " + ex.getMessage() + "\n";
			else errMsg = fname + " : " + errMsg + "\n";

        	log.severe("The SQL Exeption on update field " + fname + " : " + ex);
			log.severe("The error code " + errCode);
        } catch (NumberFormatException ex) {
			errMsg = fname + " : " + ex.getMessage() + "\n";
        	log.severe("Number format exception on field = " + fname + " : value = " + fvalue + " : " + ex);
		}

		return errMsg;
	}

	public String getErrMessage(String err) {
		String errCheck =  err;
		if(err == null) errCheck = Integer.toString(errCode);
		String errSql = "SELECT error_message FROM sys_errors WHERE sys_error = '" + errCheck + "';";
		String errAns = db.executeFunction(errSql);
		if(errAns == null) errAns = err;
		return errAns;
	}

	public void cancel() {
		isAddNew = false;
		isEdit = false;
	}

	public void recAudit(String changetype, String oldRecordid) {
		if(noaudit) return;
		if(keyField == null) return;

		String recordid = oldRecordid;
		if(oldRecordid == null) recordid = getString(keyField);

		if(recordid == null) {
			try {
				String pksql = "SELECT " + keyField + " FROM " + tableName;
				ResultSet pkrs = db.readQuery(pksql);
				pkrs.last();
				recordid = pkrs.getString(keyField);
				pkrs.close();
			} catch (SQLException ex) {}
		}
		if(db.getUser() != null) {
			String inssql = "INSERT INTO sys_audit_trail (user_id, user_ip, table_name, record_id, change_type) VALUES('";
			inssql += db.getUserID() + "', '" + db.getUserIP() + "', '" + tableName + "', '" + recordid  + "', '" + changetype + "')";
			log.fine(inssql);
			db.executeQuery(inssql);
		}
	}

	// Get the table fields
	public List<String> getFields() {
		List<String> fieldList = new ArrayList<String>();
		try {
			for(int column=1; column<=colnum; column++)
				fieldList.add(rsmd.getColumnLabel(column));
 		} catch (SQLException ex) {
			log.severe("Field Name read error : " + ex);
		}

		return fieldList;
	}

	// Get the table fields
	public Vector<String> getAutoFields() {
		autoFields = new Vector<String>();
		try {
			for(int column=1; column<=colnum; column++) {
				if(rsmd.isAutoIncrement(column)) {
					autoFields.add(rsmd.getColumnLabel(column));
				}
			}
 		} catch (SQLException ex) {
			log.severe("Field Name read error : " + ex);
		}

		return autoFields;
	}

	// Get the table fields
	public int getFieldSize(int column) {
		int fieldSize = -1;
		try {
			if (column<=colnum)
				fieldSize = rsmd.getColumnDisplaySize(column);
 		} catch (SQLException ex) {
			log.severe("Field size error : " + ex);
		}
 		
		return fieldSize;
	}

	public int getFieldType(String columnName) {
		int fieldType = -1;
		try {
			int column = rs.findColumn(columnName);
			if (column<=colnum)
				fieldType = rsmd.getColumnType(column);
 		} catch (SQLException ex) {
			log.severe("Field type read error : " + ex);
		}

		return fieldType;
	}

	public int getFieldType(int column) {
		int fieldType = -1;

		try {
			if (column<=colnum)
				fieldType = rsmd.getColumnType(column);
 		} catch (SQLException ex) {
			log.severe("Field type read error : " + ex);
		}

		return fieldType;
	}

	public void readData() {
		readData(-1);
	}

	public void readData(int limit) {
		if(rs == null) return;

		try {
			if(!readonly) rs.beforeFirst();
			int i = 0;
			data.clear();
			keyFieldData.clear();
			BCipher cp = new BCipher("12345678");

           	while (rs.next()) {
				Vector<Object> newRow = new Vector<Object>();
				for(int column=1; column<=titles.size(); column++) {
					if(view == null) {
						newRow.addElement(rs.getObject(column));
					} else {
						String fldName = view.getElement(column-1).getValue();
						if (view.getElement(column-1).getName().equals("CHECKBOX")) {
							newRow.addElement(rs.getBoolean(fieldNames.get(column-1)));
						} else if(view.getElement(column-1).getAttribute("java") != null) {
							String javaCall = view.getElement(column-1).getAttribute("java");
							if(javaCall.equals("password")) {
								newRow.addElement(cp.password(rs.getString(fldName)));
							}
						} else {
							newRow.addElement(rs.getObject(fldName));
						}
					}
				}

				if(keyField != null) keyFieldData.addElement(rs.getString(keyField));

				data.addElement(newRow);
				if((limit>0) & (limit<i)) break;
				i++;
      		}
 		} catch (SQLException ex) {
			log.severe("Field data read error : " + ex);
		}
	}

	public String readDocument(boolean heading, boolean trim) {
		StringBuffer mystr = new StringBuffer();
		try {
			rs.beforeFirst();
			if(heading) {
				mystr.append("<table class='table table-hover'>\n");
				mystr.append("<thead><tr>");
				if(view == null) {
					for(int column=0; column<titles.size(); column++)
						mystr.append("<th>" + titles.get(column) + "</th>");
				} else {
					for(BElement el : view.getElements()) {
						if(!el.getValue().equals("")) mystr.append("<th>" + el.getAttribute("title") + "</th>");
					}
				}
				mystr.append("</tr></thead>");
			}
			mystr.append("\n<tbody>");

			boolean alt = true;
           	while (rs.next()) {
				if(alt) {mystr.append("<tr>"); alt = false;}
				else {mystr.append("<tr>"); alt = true;}
				if(view == null) {
					for(int column=1; column<=titles.size(); column++) {
						String cd = rs.getString(column);
						if(cd == null) mystr.append("<td></td>");
						else {
							mystr.append("<td>");
							if(trim && (cd.length()>25)) mystr.append(cd.substring(0, 24));
							else mystr.append(cd);
							mystr.append("</td>");
						}
					}
				} else {
					for(BElement el : view.getElements()) {
						if(!el.getValue().equals("")) {
							String cd = formatData(el);
							mystr.append("<td>");
							if(trim && (cd.length()>25)) mystr.append(cd.substring(0, 24));
							else mystr.append(cd);
							mystr.append("</td>");
						}
					}
				}
				mystr.append("</tr>\n");
      		}
			mystr.append("</tbody>");
			if(heading) mystr.append("\n</table>");
 		} catch (SQLException ex) {
			log.severe("Field read data error : " + ex);
		}

		return mystr.toString();
	}

	public String getFooter() {
		StringBuffer mystr = new StringBuffer();
		try {
			rs.beforeFirst();
           	while (rs.next()) {
				if(view == null) {
					for(int column=1; column<=titles.size(); column++) {
						String cd = rs.getString(column);
						if(cd != null) {
							if(cd.length()>25) mystr.append(cd.substring(0, 24));
							else mystr.append(cd);
							mystr.append(", ");
						}
						if(column > 2) break;
					}
				} else {
					int column=1;
					for(BElement el : view.getElements()) {
						if(!el.getValue().equals("")) {
							String cd = formatData(el);
							if(cd.length()>25) mystr.append(cd.substring(0, 24));
							else mystr.append(cd);
							mystr.append(",");
						}
						if(column > 2) break;
						column++;
					}
				}
      		}
 		} catch (SQLException ex) {
			log.severe("Field read data error : " + ex);
		}

		return mystr.toString();
	}


	public Vector<Vector<Object>> getData() {
		return data;
	}

	public void importData(Vector<Vector<Object>> newData)  {
		for(int j = 0; j<newData.size(); j++) {
			Vector<Object> newRow = newData.get(j);
			if(!keyFieldData.contains(newRow.get(0).toString())) {
				recAdd();
				int i = 0;
				for(BElement el : view.getElements()) {
					if(!el.getValue().equals("") && (newRow.get(i) != null)) {
						String errStr = updateField(el.getValue(), newRow.get(i).toString());
						//log.info("Add " + el.getValue() + " : " + newRow.get(i).toString());

						if(!errStr.equals("")) log.severe(newRow.get(0).toString());
					}
					i++;
				}

				String errStr = recSave();
				if(!errStr.equals("")) log.severe(newRow.get(0).toString());
			}
		}
	}

    public int getColumnCount() {
        return titles.size();
    }

    public int getRowCount() {
        return data.size();
    }

	public void removeRow(int aRow) {
		if(aRow >= 0) data.remove(aRow);
	}

	public String getTableName() { return tableName; }

    public String getColumnName(int aCol) { return titles.get(aCol); }

	public Vector<String> getFieldNames() { return fieldNames; }

    public String getFieldName(int aCol) { return fieldNames.get(aCol); }

	public Vector<String> getColumnNames() { return titles; }

	public Vector<String> getKeyFieldData() { return keyFieldData; }

    public void addColumnName(String title) {
		titles.add(title);
    }

    public Object getValueAt(int aRow, int aCol) {
        return data.get(aRow).get(aCol);
    }

	public String getKeyFieldName() {
		return keyField;
	}

	public String getKeyField() {
		String key = null;
		if(keyField != null) key = readField(keyField);

		return key;
	}

	public int insertRow() {
		Vector<Object> dataRow = new Vector<Object>();
		for(int i = 0; i < getColumnCount(); i++) dataRow.add("");
		data.add(dataRow);

		return data.size();
	}

	public int insertRow(Vector<Object> dataRow) {
		data.add(dataRow);

		return data.size();
	}

    public void setValueAt(Object value, int aRow, int aCol) {
		Vector<Object> dataRow = data.elementAt(aRow);
        dataRow.setElementAt(value, aCol);

		// Update database
		if(updateTable != null) {
			String autoKeyID = db.insAudit(tableName, keyFieldData.get(aRow), "EDIT");

			String sql = "UPDATE " + updateTable + " SET " + fieldNames.get(aCol);
			if(value == null) sql += " = null";
			else {
				if(view.getElement(aCol).getAttribute("ischar", "false").equals("true")) {
					if(value.equals("true")) sql += " = '1'";
					else sql += " = '0'";
				} else {
					sql += " = '" + value.toString() + "'";
				}
			}

			if(auditID != null) sql += ", " + auditID + " = " + autoKeyID;
			sql += " WHERE " + getKeyFieldName() + " = '" +  keyFieldData.get(aRow) + "'";
			log.fine(sql);
			db.executeQuery(sql);
		}
	}

	public String getViewSQL() {
		return db.getViewSQL(tableName);
	}

	public void clear() { // Get all rows.
		data.clear();
	}

	public BElement getDeskConfig(int cfg) {
		BElement tel = null;
		ForeignLinks = db.getForeignLinks(tableName);
		if(ForeignLinks.size() > 0) {
			if(db.getViews().contains("vw_" + tableName)) {
				String lsql = "SELECT * FROM vw_" + tableName;
				BQuery newquery = new BQuery(db, lsql);
				tel = newquery.getGridConfig();
				tel.setAttribute("name", initCap(tableName));
				tel.setAttribute("keyfield", getColumnName(0));
				tel.setAttribute("table", "vw_" + tableName);
				newquery.close();
			} else {
				tel = getGridConfig();
			}
		} else {
			tel = getGridConfig();
		}

		if(cfg == 1)
			tel.setAttribute("linkfield", getFieldName(1));
		tel.addNode(getFormConfig(cfg));

		return tel;
	}

	public BElement getTableConfig() {
		BElement tel = getGridConfig();
		tel.addNode(getFormConfig(0));

		return tel;
	}

	public BElement getGridConfig() {
		BElement tel = new BElement("GRID");
		if(rs == null) return tel;
		try {
			tel.setAttribute("name", initCap(tableName));
			tel.setAttribute("keyfield", rsmd.getColumnLabel(1));
			tel.setAttribute("table", tableName);

			for(int column=1; column<=colnum; column++) {
				String colType = getFormField(column);
				int fieldSize = rsmd.getColumnDisplaySize(column);
				if(colType.equals("TEXTFIELD") && (fieldSize == 1)) colType = "CHECKBOX";

				BElement fel = new BElement(colType);
				String fieldname = rsmd.getColumnLabel(column);

				fel.setAttribute("title", initCap(fieldname));
				fel.setAttribute("w", "75");
				fel.setValue(fieldname);

				if(fieldSize < 500) tel.addNode(fel);
			}
 		} catch (SQLException ex) {
			log.severe("Gid configs read error : " + ex);
		}

		return tel;
	}

	public BElement getFormConfig(int cfg) {
		BElement tel = new BElement("FORM");
		if(rs == null) return tel;
		try {
			tel.setAttribute("name", initCap(tableName));
			tel.setAttribute("table", tableName);
			tel.setAttribute("keyfield", rsmd.getColumnLabel(1));

			int y = 10;
			int x = 10;
			int w = 150;
			int h = 20;
			int startCol = 1;
			ForeignLinks = db.getForeignLinks(tableName);
			if(cfg == 1) tel.setAttribute("linkfield", getFieldName(1));
			
			for(int column=startCol; column<=colnum; column++) {
				String fieldName = rsmd.getColumnLabel(column);
				int fieldSize = rsmd.getColumnDisplaySize(column);
				String colType = getFormField(column);
				boolean ischar = false;
				boolean fieldShow = true;
				if (rsmd.isAutoIncrement(column)) fieldShow = false;
				if ((cfg == 1) && (column == 2)) fieldShow = false;
				if (fieldName.equals("org_id")) fieldShow = false;
				if (fieldShow) {
					// Combobox check
					BTableLinks tbLink = null;
					for(BTableLinks tbLinks : ForeignLinks) {
						if(tbLinks.getKeyColumn().equals(fieldName)) {
							tbLink = tbLinks;
							colType = "COMBOBOX";
							fieldSize = 250;
						}
					}

					w = 150;
					if(colType.equals("TEXTFIELD") && (fieldSize == 1)) {colType = "CHECKBOX"; ischar = true; }
					if(fieldSize > 1000) colType = "TEXTAREA";
					if(fieldSize > 110) {
						w = 430;
						if(x == 290) { y += h; x = 10; }
					}
					h = 20;
					if(colType.equals("TEXTAREA")) h = 70;
					
					BElement fel = new BElement(colType);
					fel.setValue(fieldName);
					fel.setAttribute("title", initCap(fieldName));
					fel.setAttribute("x", Integer.toString(x));
					fel.setAttribute("y", Integer.toString(y));
					fel.setAttribute("w", Integer.toString(w));
					fel.setAttribute("h", Integer.toString(h));
					if(ischar) fel.setAttribute("ischar", "true");
					if(tbLink != null) {
						fel.setAttribute("lptable", tbLink.getForeignTable());
						String mysql = "SELECT " + tbLink.getForeignColumn().replace("_id", "_name") + " FROM " + tbLink.getForeignTable();
						ResultSet lrs = db.readQuery(mysql, 1);
						if(lrs == null) fel.setAttribute("lpfield", tbLink.getForeignColumn());
						else fel.setAttribute("lpfield", tbLink.getForeignColumn().replace("_id", "_name"));
						if(lrs != null) lrs.close();
						if(!fieldName.equals(tbLink.getForeignColumn()))
							fel.setAttribute("lpkey", tbLink.getForeignColumn());
					}
					tel.addNode(fel);

					if(x == 10) {
						if(w == 430) y += h;
						else x = 290;
					} else {
						x = 10;
						y += h;
					}
				}
			}
 		} catch (SQLException ex) {
			log.severe("Form config read error : " + ex);
		}

		return tel;
	}

	public BElement getMigrateConfig() {
		BElement imp = new BElement("IMPORT");
		BElement exp = new BElement("EXPORT");
		if(rs == null) return imp;
		try {
			imp.setAttribute("name", initCap(tableName));
			imp.setAttribute("keyfield", rsmd.getColumnLabel(1));
			imp.setAttribute("noaudit", "true");
			imp.setAttribute("table", tableName);

			exp.setAttribute("name", initCap(tableName));
			exp.setAttribute("keyfield", rsmd.getColumnLabel(1));
			exp.setAttribute("table", tableName);
			
			for(int column=1; column<=colnum; column++) {
				String colType = getFormField(column);
				BElement fel = new BElement(colType);
				String fieldname = rsmd.getColumnLabel(column);

				fel.setAttribute("title", initCap(fieldname));
				fel.setAttribute("w", "75");
				fel.setValue(fieldname);
				imp.addNode(fel);
				exp.addNode(fel);
			}
			imp.addNode(exp);
 		} catch (SQLException ex) {
			log.severe("Gid configs read error : " + ex);
		}

		return imp;
	}

    public Class getColumnClass(int aCol) {
        int type = Types.VARCHAR;
		if(db != null) type = getFieldType(aCol + 1);

		if(view != null) {
			if(view.getElement(aCol).getName().equals("CHECKBOX")) return Boolean.class; 
		}

        switch(type) {
			case Types.CHAR:
			case Types.VARCHAR:
			case Types.LONGVARCHAR: return String.class;
			case Types.BIT: return Boolean.class; 
			case Types.TINYINT:
			case Types.SMALLINT:
			case Types.INTEGER: return Integer.class;
			case Types.BIGINT: return Long.class;
			case Types.FLOAT:
			case Types.REAL:
			case Types.DOUBLE: return Double.class;
			case Types.TIME: return Time.class;
			case Types.TIMESTAMP: return Timestamp.class;
			case Types.DATE: return Date.class;
			default: return Object.class;
        }
    }

	public String getFormField(int aCol) {
		String coltype = "TEXTFIELD";

		switch(getFieldType(aCol)) {
			case Types.CHAR:
			case Types.VARCHAR:
				coltype = "TEXTFIELD";
				break;
			case Types.LONGVARCHAR:
			case Types.CLOB:
				coltype = "TEXTAREA";
				break;
			case Types.BIT:
				coltype = "CHECKBOX";
				break;
			case Types.TINYINT:
			case Types.SMALLINT:
			case Types.INTEGER:
				coltype = "TEXTFIELD";
				break;
			case Types.BIGINT:
				coltype = "TEXTFIELD";
				break;
			case Types.FLOAT:
			case Types.DOUBLE:
			case Types.REAL:
				coltype = "TEXTDECIMAL";
				break;
			case Types.DATE:
				coltype = "TEXTDATE";
				break;
			case Types.TIME:
				coltype = "SPINTIME";
				break;
			case Types.TIMESTAMP:
				coltype = "TEXTTIMESTAMP";
				break;
		}

		return coltype;
	}

	public List<BTableLinks> getLinks() {
		return ForeignLinks;
	}

	public List<BTableLinks> getLinks(List<String> linkTables) {
		for(BTableLinks  tbl : ForeignLinks) {
			tbl.setActive(linkTables);
		}

		return ForeignLinks;
	}

	public String initCap(String mystr) {
		if(mystr != null) {
			mystr = mystr.toLowerCase();
			String[] mylines = mystr.split("_");
			mystr = "";
			for(String myline : mylines) {
				String newline = "";
				if(myline.length()>0) {
					newline = myline.replaceFirst(myline.substring(0, 1), myline.substring(0, 1).toUpperCase());
					if(myline.trim().toUpperCase().equals("ID")) newline = "ID";
					if(myline.trim().toUpperCase().equals("IS")) newline = null;
				}
				if(newline != null) mystr += newline + " ";
			}
			mystr = mystr.trim();
		}
		return mystr;
	}

	public String formatData(BElement el) {
		String response = "";
		String format = el.getAttribute("format");
		String pattern = el.getAttribute("pattern");
		if(format == null) {
			if(el.getName().equals("TEXTDATE")) format = "date";
			if(el.getName().equals("TEXTTIMESTAMP")) format = "timestamp";
			if(el.getName().equals("CHECKBOX")) format = "boolean";
			if(el.getName().equals("TEXTDECIMAL")) format = "double";
		}
		try {
			if(rs.getString(el.getValue()) == null) {
				response = "";
			} else if(format == null) {
				response = rs.getString(el.getValue());
			} else if(format.equals("clob")) {
				Clob cl = rs.getClob(el.getValue());
				if(cl != null) response = cl.getSubString((long)1, (int)cl.length());
			} else if(format.equals("boolean")) {
				if(rs.getBoolean(el.getValue())) response = "Yes";
				else response = "No";
			} else if(format.equals("boolcolor")) {
				if(rs.getBoolean(el.getValue())) response = "*";
				else response = "&nbsp;";
			} else if(format.equals("date")) {
				SimpleDateFormat dateformatter = new SimpleDateFormat("dd-MMM-yyyy");
				String mydate = dateformatter.format(rs.getDate(el.getValue()));				
				response = mydate;
			} else if(format.equals("time")) {
				SimpleDateFormat dateformatter = new SimpleDateFormat("HH:mm");
				String mydate = dateformatter.format(rs.getTime(el.getValue()));				
				response = mydate;
			} else if(format.equals("timestamp")) {
				SimpleDateFormat dateformatter = new SimpleDateFormat("MMM dd, yyyy hh:mm a");
				String mydate = dateformatter.format(rs.getTimestamp(el.getValue()));				
				response = mydate;
			} else if(format.equals("double")) {
				if(pattern == null) {
					NumberFormat numberFormatter = NumberFormat.getNumberInstance();
					response = numberFormatter.format(rs.getDouble(el.getValue()));
				} else {
					DecimalFormat myFormatter = new DecimalFormat(pattern);
					response = myFormatter.format(rs.getDouble(el.getValue()));
				}
			}
		} catch(SQLException ex) {
			log.severe("Query data field formating error : " + ex);
		}

		return response;
	}

	public void savecvs(String filename) {
		int i, j;
		String mystr = "";

    	for(i=0; i<getRowCount(); i++) {
			int colcount = getColumnCount()-1;
			for(j=0;j<=colcount;j++) {
				if(j==colcount) mystr += getcvsValueAt(i, j) + "\r\n";
				else mystr += getcvsValueAt(i, j) + ",";
			}
		}

		Bio io = new Bio();
		io.saveFile(filename, mystr);
	}

	public String getcvs() {
		int i, j;
		String mystr = "";

		boolean isTitle = true;
		if(view != null) {
			if(view.getAttribute("notitle","false").equals("true")) isTitle = false;
		}

		if(isTitle) {
			for(String title : titles) mystr += title + ",";
			mystr += "\r\n";
		}

    	for(i=0; i<getRowCount(); i++) {
			int colcount = getColumnCount()-1;
			for(j=0;j<=colcount;j++) {
				if(j==colcount) mystr += getcvsValueAt(i, j) + "\r\n";
				else mystr += getcvsValueAt(i, j) + ",";
			}
		}

		return mystr;
	}


    public String getcvsValueAt(int aRow, int aColumn) {
        Vector row = (Vector)data.elementAt(aRow);
        Object myobj = row.elementAt(aColumn);
		Class myclass = getColumnClass(aColumn);

		String mystr = "";
		if(myobj!=null) {
			if(myclass==String.class) {
				if(myobj.toString().startsWith("0")) mystr = "\"'" + myobj.toString() + "\"";
				else mystr = "\"" + myobj.toString() + "\"";
			}
			else mystr = myobj.toString();
		}

		return mystr;
    }

	public String getTableXml(String ifNull) {
		BElement tableXml = new BElement(view.getAttribute("name"));

		if(moveFirst()) {
			for(BElement el : view.getElements()) {
				BElement xel = new BElement(el.getAttribute("xmlName"));
				String elValue = getString(el.getValue());
				if(elValue == null) elValue = ifNull;
				xel.setValue(elValue);
				tableXml.addNode(xel);
			}
		}

		return tableXml.toString();
	}

	public int getDBType() {
		return db.getDBType();
	}

	public List<Boolean> getColumnEdits() {
		return columnEdit;
	}

	public Map<String, String> getParams() {
		for(String param : params.keySet()) params.put(param, readField(param));

		return params;
	}

	public void setTitles(String[] titleArray) {
		titles.clear();
		for(String mnName : titleArray) titles.add(mnName);
	}

	public void setTableName(String tableName) {
		this.tableName = tableName;
	}

	public int getColnum() {
		return colnum;
	}

	public void close() {
		try {
			if(rs != null) rs.close();
			if(st != null) st.close();
			data.clear();
			data = null;
		} catch (SQLException ex) {
			log.severe("SQL Close Error : " + ex);
		}
	}

}
