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
import java.util.Vector;

public class BTableLinks {

	String keyTable;
	String keyColumn;
	String foreignTable;
	String foreignColumn;

	String joinType;
	boolean active = false;
	boolean keyPresent = true;
	boolean foreignPresent = true;

	public BTableLinks(String keyTable, String keyColumn, String foreignTable, String foreignColumn) {
		this.keyTable = keyTable;
		this.keyColumn = keyColumn;
		this.foreignTable = foreignTable;
		this.foreignColumn = foreignColumn;

		joinType = " INNER JOIN ";
	}

	public String getKeyTable() {
		return keyTable;
	}

	public String getKeyColumn() {
		return keyColumn;
	}

	public String getForeignTable() {
		return foreignTable;
	}

	public String getForeignColumn() {
		return foreignColumn;
	}

	public void setActive(List<String> sourceTables) {
		active = false;
		if(!foreignTable.equals(keyTable)) {
			for(String sourceTable : sourceTables) {
				if(sourceTable.equals(foreignTable)) active = true;
			}
		}
	}

	public void setLinked(List<String> sourceTables) {
		for(String sourceTable : sourceTables) {
			if(sourceTable.equals(keyTable)) keyPresent = false;
			if(sourceTable.equals(foreignTable)) foreignPresent = false;
		}
	}

	public boolean isActive() {
		return active;
	}

	public String toString() {
		String mysql = "";
		if(foreignTable.equals(keyTable)) {
			mysql = keyTable;
		} else if(keyPresent && foreignPresent) {
			mysql = foreignTable + joinType + keyTable + " ON ";
			mysql += foreignTable + "."  + foreignColumn + " = " +  keyTable + "."  + keyColumn;
		} else if(keyPresent) {
			mysql = joinType + keyTable  + " ON ";
			mysql += foreignTable + "."  + foreignColumn + " = " +  keyTable + "."  + keyColumn;
		} else if(foreignPresent) {
			mysql = joinType + foreignTable  + " ON ";
			mysql += foreignTable + "."  + foreignColumn + " = " +  keyTable + "."  + keyColumn;
		}
		
		return mysql;
	}

	public Vector<Object> getData() {
		Vector<Object> dataRow = new Vector<Object>();
		dataRow.add(foreignTable);
		dataRow.add(foreignColumn);
		dataRow.add(joinType);
		dataRow.add(keyTable);
		dataRow.add(keyColumn);

		return dataRow;
	}

}