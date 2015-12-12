/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import java.io.OutputStream;
import java.io.InputStream;
import java.io.IOException;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.baraza.reports.BWebReport;

public class BShowReport extends HttpServlet {

	public void doPost(HttpServletRequest request, HttpServletResponse response)  {
		doGet(request, response);
	}

	public void doGet(HttpServletRequest request, HttpServletResponse response) {
		ServletContext context = getServletContext();
		HttpSession session = request.getSession(true);
		String xmlcnf = (String)session.getAttribute("xmlcnf");
		String ps = System.getProperty("file.separator");
		String xmlfile = context.getRealPath("WEB-INF") + ps + "configs" + ps + xmlcnf;
		String dbconfig = "java:/comp/env/jdbc/database";
		String projectDir = context.getInitParameter("projectDir");
		if(projectDir != null) xmlfile = projectDir + ps + "configs" + ps + xmlcnf;

		String userIP = request.getRemoteAddr();
		String userName = request.getRemoteUser();

		BWeb web = new BWeb(dbconfig, xmlfile);
		web.setUser(userIP, userName);
		web.init(request);

		String reportType = request.getParameter("report");
		if(reportType==null) reportType = "pdf";

		BWebReport webreport =  new BWebReport(web.getView(), web.getUserID(), null, request);
		if(reportType.equals("pdf")) webreport.getReport(web.getDB(), request, response, 0);
		if(reportType.equals("excel")) webreport.getReport(web.getDB(), request, response, 1);

		web.close();
	}
}

