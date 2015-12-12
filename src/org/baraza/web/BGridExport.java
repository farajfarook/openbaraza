/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import java.io.PrintWriter;
import java.io.IOException;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.baraza.xml.BElement;

public class BGridExport extends HttpServlet {

	public void doPost(HttpServletRequest request, HttpServletResponse response)  {
		doGet(request, response);
	}

	public void doGet(HttpServletRequest request, HttpServletResponse response) {
		ServletContext context = getServletContext();
		HttpSession session = request.getSession(true);
		String xmlcnf = (String)session.getAttribute("xmlcnf");
		session.setAttribute("xmlcnf", xmlcnf);
		String dbconfig = "java:/comp/env/jdbc/database";

		String ps = System.getProperty("file.separator");
		String xmlfile = context.getRealPath("WEB-INF") + ps + "configs" + ps + xmlcnf;
		String reportPath = context.getRealPath("reports") + ps;
		String projectDir = context.getInitParameter("projectDir");
		if(projectDir != null) {
			xmlfile = projectDir + ps + "configs" + ps + xmlcnf;
			reportPath = projectDir + ps + "reports" + ps;
		}

		String userIP = request.getRemoteAddr();
		String userName = request.getRemoteUser();

		BWeb web = new BWeb(dbconfig, xmlfile);
		web.setUser(userIP, userName);
		web.init(request);
		BElement root = web.getRoot();

		String entryformid = null;
		String action = request.getParameter("action");
		String value = request.getParameter("value");
		String post = request.getParameter("post");
		String process = request.getParameter("process");
		String reportexport = request.getParameter("reportexport");

		response.setContentType("text/x-csv");
		response.setHeader("Content-Disposition", "attachment; filename=report.csv");

		try {
			PrintWriter out = response.getWriter();
			out.println(web.getcsv(request, response));
		} catch(IOException ex) {
			System.out.println("IO Exception : " + ex);
		}

		web.close(); 
	}
}

