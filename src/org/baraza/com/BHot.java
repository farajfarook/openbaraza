/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.com;

import java.io.File;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;

public class BHot {

	int lnk = 0;

	public static void main(String args[]) {
		String dbclass = "org.postgresql.Driver"; 
		String dbpath = "jdbc:postgresql://localhost/hot"; 
		BDB db =  new BDB(dbclass, dbpath, "root", "invent");

		BHot hot = new BHot(db);
		db.close();
	}

	public BHot(BDB db) {
		System.out.println("HOT Proccesing");

		try {
			File aFile = new File("/root/backup/database/KE.HOT.B.100315.402");
			BufferedReader input =  new BufferedReader(new FileReader(aFile));
			String line = null;
			String mysql = "SELECT max(fld0) as maxfld FROM bkt06";
			BQuery rs = new BQuery(db, mysql);
			if(rs.moveNext()) {
				lnk = rs.getInt("maxfld");
			}

			while ((line = input.readLine()) != null) {				
				process(db, line);
			}
			input.close();
		} catch (IOException ex) {
			System.out.println("IO Error : " + ex);
		}
	}

	public void process (BDB db, String line) {
		String code = line.substring(0, 3) + line.substring(11, 13);
		String linenum = line.substring(3, 11);

		if(code.equals("BKT06")) lnk++;

		String mysql = "SELECT headers.description as hdef, elements.code, elements.el, elements.pos, ";
		mysql += "elements.element, elements.description ";
		mysql += "FROM headers INNER JOIN elements ON headers.code = elements.code ";
		mysql += "WHERE elements.code = '" + code + "' ";
		mysql += "ORDER BY pos";
		BQuery rs = new BQuery(db, mysql);

		int pos = 0;
		int epos = 0;
		int lnl = line.length();
		String data = "";
		String l1 = "";
		String l2 = "";		

		boolean fl = true;
		while(rs.moveNext()) {
			if(fl) {
				fl = false;

				System.out.println();
				System.out.println(rs.getString("hdef") + "\r");
				System.out.println(line + "\r");
			}

			pos = rs.getInt("pos") - 1;
			if(!rs.isLast()) {
				rs.moveNext();
				epos = rs.getInt("pos") - 1;
				rs.movePrevious();
			} else {
				epos = lnl;
			}
			if(pos > lnl) pos = lnl;
			if(epos > lnl) epos = lnl;

			String elType = rs.getString("element");
			if(elType == null) elType = "";
			elType = elType.replace(" ", "").trim();

			data = line.substring(pos, epos).trim();
			if(!data.equals("")) {
				if(l1.equals("")) l1 += "FLD" + rs.getString("el");
				else l1 += ", FLD" + rs.getString("el");

				if(elType.equals("11N")) {
					if(data.indexOf("}")>0) data = "-" + data.substring(0, 10).trim();
					else data = data.substring(0, 10).trim();
				}

				if(l2.equals("")) l2 += "'" + data + "'";
				else l2 += ",'" + data + "'";

				//System.out.println(rs.getString("description") + ":" + data + "\r");
			}
		}
		l1 += ", LNK";
		l2 += ",'" + lnk + "'";
		mysql = "INSERT INTO " + code + " (" + l1 + ") VALUES (" + l2 + ");";
		db.executeQuery(mysql);
		rs.close();

		//System.out.println(mysql);
	}

	public void genDB(BDB db) {
		String mysql = "SELECT headerid, code FROM headers ORDER BY headerid";
		String mytable = "";
		BQuery rs1 = new BQuery(db, mysql);
		while(rs1.moveNext()) {
			mysql = "SELECT el, description FROM elements WHERE code = '" + rs1.getString("code") + "' ";
			mysql += "ORDER BY el";
			BQuery rs2 = new BQuery(db, mysql);

			mytable += "CREATE TABLE " + rs1.getString("code") + " (\n";
			mytable += "\tFLD0\t\t\tserial primary key,\n";
			while(rs2.moveNext()) {
				mytable += "\tFLD" + rs2.getString("el") + "\t\t\tvarchar(50),\n";
			}
			mytable += "\tLNK\t\tinteger,\n";
			mytable += "\tnarrative\t\tvarchar(240)\n);\n\n";
			rs2.close();
		}
		rs1.close();
	}
}
