/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import java.text.SimpleDateFormat;
import java.text.ParseException;
import java.util.Enumeration;

import java.io.PrintWriter;
import java.io.OutputStream;
import java.io.InputStream;
import java.io.IOException;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.baraza.DB.BDB;
import org.baraza.xml.BElement;

public class Bajax extends HttpServlet {

	BWeb web = null;
	BDB db = null;

	public void doPost(HttpServletRequest request, HttpServletResponse response)  {
		doGet(request, response);
	}

	public void doGet(HttpServletRequest request, HttpServletResponse response) { 
		ServletContext context = getServletContext();
		HttpSession session = request.getSession(true);
		String xmlcnf = (String)session.getAttribute("xmlcnf");
		String ps = System.getProperty("file.separator");
		String xmlfile = context.getRealPath("WEB-INF") + ps + "configs" + ps + xmlcnf;
		String projectDir = context.getInitParameter("projectDir");
		if(projectDir != null) xmlfile = projectDir + ps + "configs" + ps + xmlcnf;
		String dbconfig = "java:/comp/env/jdbc/database";
		
		Enumeration e = request.getParameterNames();
        while (e.hasMoreElements()) {
			String ce = (String)e.nextElement();
			System.out.println(ce + ":" + request.getParameter(ce));
		}

        response.setContentType("text/html");
		PrintWriter out = null;
		try { out = response.getWriter(); } catch(IOException ex) {}
		String resp = "";

		String userIP = request.getRemoteAddr();
		String userName = request.getRemoteUser();

		web = new BWeb(dbconfig, xmlfile);
		web.init(request);
		web.setUser(userIP, userName);
		
		db = web.getDB();
		
		String sp = request.getServletPath();
		if(sp.equals("/ajaxupdate")) {
			if("edit".equals(request.getParameter("oper"))) {
				resp = updateGrid(request);
			}
		}

		System.out.println("AJAX Reached : " + request.getParameter("fnct"));		
		
		String function = request.getParameter("ajaxfunction");			// function to execute
		String params = request.getParameter("ajaxparams");				// function params
		String from = request.getParameter("from");						// from function
		if((function != null) && (params != null)) resp = executeSQLFxn(function, params, from);

		String fnct = request.getParameter("fnct");
		String id = request.getParameter("id");
		String ids = request.getParameter("ids");
		String startDate = request.getParameter("startdate");
		String startTime = request.getParameter("starttime");
		String endDate = request.getParameter("enddate");
		String endTime = request.getParameter("endtime");

		if("calresize".equals(fnct)) resp = calResize(id, endDate, endTime);
		if("calmove".equals(fnct)) resp = calMove(id, startDate, startTime, endDate, endTime);
		if("operation".equals(fnct)) resp = calOperation(id, ids, request);
		if("filter".equals(fnct)) resp = filterJSON(request);
		
		if("password".equals(fnct)) { 
			resp = changePassword(request.getParameter("oldpass"), request.getParameter("newpass"));
			response.setContentType("application/json;charset=\"utf-8\"");
		}
		
		web.close();	// close DB commections
		out.println(resp);
	}
	
	public String updateGrid(HttpServletRequest request) {
		String resp = "";
		
		boolean hasEdit = false;
		BElement view = web.getView();
		String upSql = "UPDATE " + view.getAttribute("updatetable") + " SET ";
		for(BElement el : view.getElements()) {
			if(el.getName().equals("EDITFIELD")) {
				if(hasEdit) upSql += ", ";
				upSql += el.getValue() + " = '" + request.getParameter(el.getValue()) + "'";
				hasEdit = true;
			}
		}
		
		if(hasEdit) {
			String editKey = view.getAttribute("keyfield");
			String id = request.getParameter("id");
			String autoKeyID = db.insAudit(view.getAttribute("updatetable"), id, "EDIT");
			
			if(view.getAttribute("auditid") != null) upSql += ", " + view.getAttribute("auditid") + " = " + autoKeyID;
			upSql += " WHERE " + editKey + " = '" + id + "'";
			
			resp = db.executeQuery(upSql);
			
			System.out.println("BASE GRID UPDATE : " + upSql);
		}
		
		if(resp == null) resp = "OK";
		
		return resp;
	}

	public String calResize(String id, String endDate, String endTime) {
		String resp = "";

		String sql = "UPDATE case_activity SET finish_time = '" + endTime + "' ";
		sql += "WHERE case_activity_id = " + id;
		System.out.println(sql);

		web.executeQuery(sql);

		return resp;
	}

	public String calMove(String id, String startDate, String startTime, String endDate, String endTime) {
		String resp = "";

		if("".equals(endDate)) {
			resp = calResize(id, endDate, endTime);
		} else {
			String sql = "UPDATE case_activity SET activity_date = '"  + endDate + "', activity_time = '" + startTime;
			sql += "', finish_time = '" + endTime + "' ";
			sql += "WHERE case_activity_id = " + id;
			System.out.println(sql);

			web.executeQuery(sql);
		}

		return resp;
	}

	public String executeSQLFxn(String fxn, String prms, String from) {
		String query = "";

		if(from == null) query = "SELECT " + fxn + "('" + prms + "')";
		else query = "SELECT " + fxn + "('" + prms + "') from " + from;
		System.out.println("SQL function = " + query);

		String str = "";
		if(!prms.trim().equals("")) str = web.executeFunction(query);

		return str;
	}

	public String escapeSQL(String str){				
		String escaped = str.replaceAll("'","\'");						
		return escaped;
	}
	
	public String calOperation(String id, String ids, HttpServletRequest request) {
		String resp = web.setOperations(id, ids, request);
		
		return resp;
	}
	
	public String filterJSON(HttpServletRequest request) {
		String filterName = request.getParameter("filtername");
		String filterType = request.getParameter("filtertype");
		String filterValue = request.getParameter("filtervalue");
		String filterAnd = request.getParameter("filterand");
		String filterOr = request.getParameter("filteror");
		
		if(filterValue == null) return "";
		if(filterValue.equals("")) return "";
		if(filterAnd == null) filterAnd = "false";
		if(filterOr == null) filterOr = "false";
		
		// Only postgres supports ilike so for the others turn to like
		String wheresql = "";
		if((db.getDBType()!=1) && (filterType.startsWith("ilike"))) filterType = "like";

		if(filterType.startsWith("like"))
			if(db.getDBType()==1) wheresql += "(cast(" + filterName + " as varchar) " + filterType + " '%" + filterValue + "%')";
			else wheresql += "(lower(" + filterName + ") " + filterType + " lower('%" + filterValue + "%'))";
		else if(filterType.startsWith("ilike"))
			wheresql += "(cast(" + filterName + " as varchar) " + filterType + " '%" + filterValue + "%')";
		else
			wheresql += "(" + filterName + " " + filterType + " '" + filterValue + "')";
		
		HttpSession webSession = request.getSession(true);
		if(webSession.getAttribute("JSONfilter2") != null) {
			if(filterAnd.equals("true")) {
				wheresql = (String)webSession.getAttribute("JSONfilter2") + " AND " + wheresql;
			} else if(filterOr.equals("true")) {
				wheresql = (String)webSession.getAttribute("JSONfilter2") + " OR " + wheresql;
			}
		}
		webSession.setAttribute("JSONfilter1", wheresql);
		webSession.setAttribute("JSONfilter2", wheresql);	
		
		System.out.println(wheresql + " : " + filterAnd);
		
		return wheresql;
	}
	
	public String changePassword(String oldPass, String newPass) {
		String resp = "";
				
		String fnct = web.getRoot().getAttribute("password");
		if(fnct == null) return "{\"success\": 0, \"message\": \"Cannot change Password\"}";
		
		String mysql = "SELECT " + fnct + "('" + web.getUserID() + "', '" + oldPass + "','" + newPass + "')";
		String myoutput = web.executeFunction(mysql);
		
		if(myoutput == null) resp = "{\"success\": 0, \"message\": \"Old Password Is incorrect\"}";
		else resp = "{\"success\": 1, \"message\": \"Password Changed Successfully\"}";
		
		return resp;
	}
 
}