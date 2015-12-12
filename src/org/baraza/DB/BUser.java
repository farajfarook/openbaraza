/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.DB;

import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;

public class BUser {
	String userIP = null;
	String userName = null;
	String userID = null;
	String orgID = null;
	String orgName = null;
	String entityName = null;
	String entityType = null;
	String startView = null;
	List<String> groupRole;
	List<String> userRole;
	boolean superUser = false;
	
	public BUser(BDB db, String userIP, String userName, boolean newUser) {
		this.userIP = userIP;
		this.userName = userName;
		groupRole = new ArrayList<String>();
		userRole = new ArrayList<String>();

		userID = "0";
		orgID = "0";
		orgName = "default";
		entityName = "root";
		entityType = "0";
	}

	public BUser(BDB db, String userIP, String userName) {
		this.userIP = userIP;
		this.userName = userName;
		groupRole = new ArrayList<String>();
		userRole = new ArrayList<String>();

		String mysql = "SELECT entity_id, entity_type_id, org_id, no_org, entity_name, Super_User, Entity_Leader, Function_Role ";
		mysql += "FROM entitys WHERE User_name = '" + userName + "'";
		BQuery rs = new BQuery(db, mysql);

		if(rs.moveNext()) {
			entityName = rs.readField("entity_name");
			entityType = rs.readField("entity_type_id");
			userID = rs.readField("entity_id");
			orgID = rs.readField("org_id");
			if(rs.getBoolean("no_org")) orgID = null;

			superUser = rs.getBoolean("Super_User");
			String functionRole = rs.readField("Function_Role");
			if(functionRole != null) {
				String functionRoles[] = functionRole.split(",");
				userRole = Arrays.asList(functionRoles);
			}
		} else {
			userID = "0";
		}
		rs.close();

		startView = db.executeFunction("SELECT start_view FROM entity_types WHERE entity_type_id = " + entityType);
		if(startView == null) startView = "1:0";

		if(orgID != null) {
			orgName = db.executeFunction("SELECT org_name FROM orgs WHERE org_id = " + orgID);
		}

		if(userID != null) {
			mysql = "SELECT entity_types.entity_type_id, entity_types.entity_role ";
			mysql += "FROM entity_types INNER JOIN Entity_subscriptions ON entity_types.entity_type_id = Entity_subscriptions.entity_type_id ";
			mysql += "WHERE Entity_subscriptions.entity_id = '" + userID + "'";
			rs = new BQuery(db, mysql);
			while(rs.moveNext()) groupRole.add(rs.readField("entity_role"));
			rs.close();
		}

		if(userID == null) userID = "0";
	}

	public void setUser(BDB db, String tableName, String idCol, String nameCol, String userName) {
		String mysql = "SELECT " + idCol + " FROM " +  tableName;
		mysql += " WHERE " + nameCol + " = '" + userName + "'";
		BQuery rs = new BQuery(db, mysql);
		if(rs.moveNext()) userID = rs.readField(idCol);

		if(userID == null) userID = "0";
	}

	public String getOrgWhere(String orgTable) {
		String ow = "";
		if(orgTable == null) orgTable = "";
		else orgTable = orgTable + ".";
		if(orgID != null) {
			ow = " WHERE (" + orgTable + "org_id = " + orgID + ")";
		}
		return ow;
	}

	public String getOrgAnd(String orgTable) {
		String ow = "";
		if(orgTable == null) orgTable = "";
		else orgTable = orgTable + ".";
		if(orgID != null) {
			ow = " AND (" + orgTable + "org_id = " + orgID + ")";
		}
		return ow;
	}

	public String getUserID() { return userID; }
	public String getUserIP() { return userIP; }
	public String getUserOrg() { return orgID; }
	public String getUserOrgName() { return orgName; }
	public String getUserName() { return userName; }
	public String getEntityName() { return entityName; }
	public String getStartView() { return startView; }
	public boolean getSuperUser() { return superUser; }
	public List<String> getUserRoles() { return userRole; }
	public List<String> getGroupRoles() { return groupRole; }
	
}