/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;


import java.util.List;
import java.util.ArrayList;
import java.util.logging.Logger;
import javax.jws.WebService;
import javax.jws.WebMethod;
import javax.servlet.ServletContext;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.naming.Context;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;

@WebService
public class BWebService {
	Logger log = Logger.getLogger(BWebService.class.getName());
	
	List<String> allowedTables;
	
	
	public BWebService() {
		try {
			Context initCtx = new InitialContext();
			Context envCtx = (Context) initCtx.lookup("java:comp/env");
        } catch (NamingException ex) {
         	System.err.println("Cannot pick on the name : " + ex);
		}
	}

	@WebMethod
	public String addWsData(String xmldata, String verification) {
System.out.println("WEB SERVICE GET DATA : " + verification);
System.out.println(xmldata);

		allowedTables = new ArrayList<String>();
		String key = "baratonElections";		
		if(key.equals(verification)) return addData(xmldata);
		else return("<ERROR>100</ERROR>");
	}
	
	@WebMethod
	public String getWsData(String xmldata, String verification) {

System.out.println("WEB SERVICE GET DATA : " + verification);
System.out.println(xmldata);

		allowedTables = new ArrayList<String>();
		allowedTables.add("ws_students");
		allowedTables.add("ws_qstudents");
		String key = "baratonElections";		
		if(key.equals(verification)) return getData(xmldata);
		else return("<ERROR>100</ERROR>");
	}
	
	String addData(String xmldata) {
		BXML xml = new BXML(xmldata, true);
		BElement root = xml.getRoot();
		String result = "0";

		BDB db = new BDB("java:/comp/env/jdbc/database");

		for(BElement el : root.getElements()) {
			if(allowedTables.contains(el.getAttribute("table"))) {
				if(el.getName().equals("TRANSFER")) result = getTransfer(db, el);
				else if (el.getName().equals("FUNCTION")) result = getFunction(db, el);
			}
		}

		db.close();

		return result;
	}
	
	String getData(String xmldata) {
		BXML xml = new BXML(xmldata, true);
		BElement root = xml.getRoot();
		String result = "<transaction>\n";
		String mysql = "";

		BDB db = new BDB("java:/comp/env/jdbc/database");

		for(BElement el : root.getElements()) {
			if(allowedTables.contains(el.getAttribute("table"))) {
				BQuery query =  new BQuery(db, el, null, null, false);

				int ColNum = query.getColumnCount();
				int i = 1;
				int j = 1;
				String cname;
				result += "\t<transfer name=\"" + el.getAttribute("name") + "\">\n";

				while(query.moveNext()) {
					result += "\t\t<record item=\"" + cleanData(query.getString(el.getAttribute("keyfield"))) + "\">\n";
					for(BElement ell : el.getElements()) {
						cname = ell.getValue();
						result += "\t\t\t<" + cname + ">" + cleanData(query.getString(cname)) + "</" + cname + ">\n";
					}
					result += "\t\t</record>\n";
				}
				result += "\t</transfer>\n";
				query.close();
			}
		}

		result += "</transaction>";
		log.fine(result);

		db.close();

		return result;
	}

	String getTransfer(BDB db , BElement el) {
		String result = "2";
		String mysql = "SELECT " + el.getAttribute("keyfield") + " FROM " + el.getAttribute("table");
		mysql += " WHERE " + el.getAttribute("keyfield") + " = '" + el.getFirst().getValue() + "'";
		log.info("Check for duplicate record : " + mysql);
		String dataExists = db.executeFunction(mysql);

		if(dataExists == null) {
			mysql = "INSERT INTO " + el.getAttribute("table") + " (";
			String mydata = "";
			String a = "";
			for(BElement ell : el.getElements()) {
				mysql += a + ell.getName();
				if(ell.getValue().equals("")) mydata += a + "null";
				else mydata += a + "'" + ell.getValue() + "'";
				a = ", ";
			}
			mysql += ") VALUES (" + mydata + ")";
			log.fine(mysql);

			result = db.executeQuery(mysql);
			if(result == null) result = "0";
		} else {
			result = "1";
		}

		return result;
	}
	
	String getFunction(BDB db , BElement el) {
		String result = "0";

		String mysql = el.getValue();
		System.out.println(mysql);
		db.executeQuery(mysql);
		
		return result;
	}

	String cleanData(String mydata) {
		if(mydata == null) return mydata;

		String sa = mydata.trim();
		sa = sa.replaceAll("&", "&amp;");
		sa = sa.replaceAll("\"", "&quot;");
		sa = sa.replaceAll("'", "&apos;");
		sa = sa.replaceAll("<", "&lt;");
		sa = sa.replaceAll(">", "&gt;");
		return sa;
	}
} 