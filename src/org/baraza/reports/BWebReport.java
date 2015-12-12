/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.reports;

import java.util.logging.Logger;
import java.io.File;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.io.ByteArrayOutputStream;
import java.sql.Connection;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.ServletOutputStream;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpSession;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JRExporterParameter;
import net.sf.jasperreports.engine.JRRuntimeException;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.JasperExportManager;
import net.sf.jasperreports.engine.export.JRHtmlExporter;
import net.sf.jasperreports.engine.export.JRHtmlExporterParameter;
import net.sf.jasperreports.engine.export.JRXlsExporter;
import net.sf.jasperreports.engine.export.JRXlsExporterParameter;
import net.sf.jasperreports.engine.util.JRLoader;
import net.sf.jasperreports.j2ee.servlets.ImageServlet;

import org.baraza.xml.BElement;
import org.baraza.DB.BDB;

public class BWebReport  {
	Logger log = Logger.getLogger(BWebReport.class.getName());
	String name, reportfile, filterkey, filtervalue;
	boolean showpdf = false;
	String userid, userfilter;
	String groupid, groupfilter;
	String linkField;
	String orgTable = null;
	Map<String, Object> parameters;

	public BWebReport() {
		parameters = new HashMap<String, Object>();
	}

	public BWebReport(BElement view, String userid, String groupid, HttpServletRequest request) {
		this.userid = userid;
		this.groupid = groupid;

		parameters = new HashMap<String, Object>();
		parameters.put("ReportTitle", name);

		name = view.getAttribute("name");
		reportfile = view.getAttribute("reportfile");
		userfilter = view.getAttribute("user", "entity_id");
		groupfilter = view.getAttribute("group");
		filterkey = view.getAttribute("filterkey");
		filtervalue = request.getParameter("filtervalue");
		orgTable = view.getAttribute("org.table");

		linkField = view.getAttribute("linkfield", "filterid");
	}

	public String getReport(BDB db, String linkValue, HttpServletRequest request, String reportPath) {
		StringBuffer sbuffer = new StringBuffer();
		try {
			File reportFile = new File(reportPath + reportfile);
			if (!reportFile.exists()) {
				System.out.println("Report access error");
				sbuffer.append("REPORT ACCESS ERROR");
				return sbuffer.toString();
			}
			JasperReport jasperReport = (JasperReport)JRLoader.loadObjectFromFile(reportFile.getPath());
			
			HttpSession session = request.getSession(true);
			session.setAttribute("reportfile", reportFile.getAbsolutePath());
			session.setAttribute("reportname", name);

			parameters.put("reportpath", reportFile.getParent() + "/");
			parameters.put("SUBREPORT_DIR", reportFile.getParent() + "/");

			parameters.put("orgid", db.getOrgID());
			parameters.put("orgwhere", db.getOrgWhere(orgTable));
			parameters.put("organd", db.getOrgAnd(orgTable));

			session.setAttribute("userfield", "");
			session.setAttribute("groupfield", "");
			if ((userfilter != null) && (userid != null)) {
				log.info(userfilter + " | " + userid);
				parameters.put(userfilter, userid);
				session.setAttribute("userfield", userfilter);
				session.setAttribute("uservalue", userid);
			}
			if ((groupfilter != null) && (groupid != null)) {
				parameters.put(groupfilter, groupid);
				session.setAttribute("groupfield", groupfilter);
				session.setAttribute("groupvalue", groupid);
			}
			JasperPrint jasperPrint = JasperFillManager.fillReport(jasperReport, parameters, db.getDB());
			session.setAttribute(ImageServlet.DEFAULT_JASPER_PRINT_SESSION_ATTRIBUTE, jasperPrint);

			int pageIndex = 0;
			int lastPageIndex = 0;
			if (jasperPrint.getPages() != null)
				lastPageIndex = jasperPrint.getPages().size() - 1;
	
			if(request.getParameter("page") != null)
				pageIndex = Integer.parseInt(request.getParameter("page"));
			if(request.getParameter("reportmove") != null) {
				String reportmove = request.getParameter("reportmove");
				if(reportmove.equals("<<")) pageIndex = 0;;
				if(reportmove.equals("<")) pageIndex--;
				if(reportmove.equals(">")) pageIndex++;
				if(reportmove.equals(">>")) pageIndex = lastPageIndex;
			}

			if (pageIndex < 0) pageIndex = 0;
			if (pageIndex > lastPageIndex) pageIndex = lastPageIndex;

			sbuffer.append("<div id='reports'>\n");
			JRHtmlExporter exporter = new JRHtmlExporter();
			exporter.setParameter(JRExporterParameter.JASPER_PRINT, jasperPrint);
			exporter.setParameter(JRExporterParameter.OUTPUT_STRING_BUFFER, sbuffer);
			exporter.setParameter(JRExporterParameter.PAGE_INDEX, Integer.valueOf(pageIndex));
			exporter.setParameter(JRHtmlExporterParameter.HTML_HEADER, "");
			exporter.setParameter(JRHtmlExporterParameter.BETWEEN_PAGES_HTML, "");
			exporter.setParameter(JRHtmlExporterParameter.HTML_FOOTER, "");
			exporter.setParameter(JRHtmlExporterParameter.IMAGES_URI, "image?image=");
			exporter.exportReport();
			sbuffer.append("\n</div>\n");

			sbuffer.append("<table style='width: 597px; border-collapse: collapse'><tr>\n");
			sbuffer.append("<td width='55'><button class='i_triangle_double_left icon' name='reportmove' type='submit' value='<<'>First</button></td>\n");
			sbuffer.append("<td width='55'><button class='i_triangle_left icon' name='reportmove' type='submit' value='<'>Previous</button></td>\n");
			sbuffer.append("<td width='155'>Page :" + Integer.toString(pageIndex+1) + " of " + Integer.toString(lastPageIndex+1) + "</td>\n");
			sbuffer.append("<input name='page' type='hidden' value='" + Integer.toString(pageIndex) + "'/>\n");
			sbuffer.append("<td width='55'><button class='i_triangle_right icon' name='reportmove' type='submit' value='>'>Next</button></td>\n");
			sbuffer.append("<td width='55'><button class='i_triangle_double_right icon' name='reportmove' type='submit' value='>>'>Last</button></td>\n");
			sbuffer.append("<td width='55'><button class='i_excel_document icon' name='excelexport' type='submit' value='excel'>excel</button></td>\n");
			sbuffer.append("<td width='55'><button class='i_pdf_document icon' name='reportexport' type='submit' value='pdf'>pdf</button></td>\n");
			sbuffer.append("</tr><table>");
		} catch (JRException ex) {
			System.out.println("Jasper exception : " + ex);
		}

		return sbuffer.toString();
	}

	public void getReport(BDB db, HttpServletRequest request, HttpServletResponse response, int reportType) {
		try {
			HttpSession session = request.getSession(true);
			reportfile = (String)session.getAttribute("reportfile");
			name = (String)session.getAttribute("reportname");

			File reportFile = new File(reportfile);
			if (!reportFile.exists()) {
				log.severe("Report access error : " + reportfile);
				return;
			}
			JasperReport jasperReport = (JasperReport)JRLoader.loadObjectFromFile(reportFile.getPath());

			parameters.put("reportpath", reportFile.getParent() + "/");
			parameters.put("SUBREPORT_DIR", reportFile.getParent() + "/");

			parameters.put("orgid", db.getOrgID());
			parameters.put("orgwhere", db.getOrgWhere(orgTable));
			parameters.put("organd", db.getOrgAnd(orgTable));

			String reportFilters = (String)session.getAttribute("reportfilters");
			String reportFilter[] = reportFilters.split(",");
			for(int i = 0; i < reportFilter.length; i++) {
				String filterValue = (String)session.getAttribute(reportFilter[i]);
				parameters.put(reportFilter[i], filterValue);
			}
		
			String linkField = (String)session.getAttribute("linkfield");
			String linkValue = (String)session.getAttribute("linkvalue");
			if ((linkField != null) && (linkValue != null)) {
				parameters.put(linkField, linkValue);
				log.info(linkField + " | " + linkValue);
			}
			userfilter = (String)session.getAttribute("userfield");
			userid = (String)session.getAttribute("uservalue");
			if ((userfilter != null) && (userid != null)) {
				parameters.put(userfilter, userid);
				log.info(userfilter + " | " + userid);
			}
			groupfilter = (String)session.getAttribute("groupfield");
			groupid = (String)session.getAttribute("groupvalue");
			if ((groupfilter != null) && (groupid != null)) {
				parameters.put(groupfilter, groupid);
			}

			JasperPrint jasperPrint = JasperFillManager.fillReport(jasperReport, parameters, db.getDB());
			if(reportType == 0) {
				byte[] pdfdata = JasperExportManager.exportReportToPdf(jasperPrint);

				response.setCharacterEncoding("ISO-8859-1");
				response.setContentType("application/pdf");
				response.setHeader("Content-Disposition", "attachment; filename=report.pdf");
				response.setContentLength(pdfdata.length);
				response.getOutputStream().write(pdfdata);
				response.getOutputStream().flush();
			}
			if(reportType == 1) {
				ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();  
				JRXlsExporter exporterXls = new JRXlsExporter ();  
				exporterXls.setParameter(JRXlsExporterParameter.JASPER_PRINT, jasperPrint);  
				exporterXls.setParameter(JRXlsExporterParameter.IGNORE_PAGE_MARGINS, false);  
				exporterXls.setParameter(JRXlsExporterParameter.IS_COLLAPSE_ROW_SPAN, true);  
				exporterXls.setParameter(JRXlsExporterParameter.IS_WHITE_PAGE_BACKGROUND, false);  
				exporterXls.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_COLUMNS, true);  
				exporterXls.setParameter(JRXlsExporterParameter.IS_REMOVE_EMPTY_SPACE_BETWEEN_ROWS, true);  
				exporterXls.setParameter(JRXlsExporterParameter.IS_DETECT_CELL_TYPE, true);  
				exporterXls.setParameter(JRExporterParameter.OUTPUT_FILE_NAME, "report.xls");  
				exporterXls.setParameter(JRXlsExporterParameter.OUTPUT_STREAM, byteArrayOutputStream);  
				exporterXls.exportReport();                               
					
				response.setContentType("application/vnd.ms-excel");  
				response.setHeader("Content-Disposition", "attachment;filename=report.xls");  
				ServletOutputStream servletOutputStream = response.getOutputStream();  
				servletOutputStream.write(byteArrayOutputStream.toByteArray());  
				servletOutputStream.flush();  
				servletOutputStream.close(); 
			}
		} catch (JRException ex) {
			log.severe("jasper exception " + ex);
		} catch (IOException ex) {
			log.severe("Web Print Writer Error : " + ex);
		}
	}

	public void getDirectReport(BDB db, HttpServletRequest request, HttpServletResponse response, String reportPath, String reportName) {
		try {
			reportfile = reportPath + reportName + ".jasper";
			name = reportName;

			File reportFile = new File(reportfile);
			if (!reportFile.exists()) log.info("Report access error : " + reportfile);
			JasperReport jasperReport = (JasperReport)JRLoader.loadObjectFromFile(reportFile.getPath());

			parameters.put("reportpath", reportPath);
			parameters.put("SUBREPORT_DIR", reportPath);

			parameters.put("orgid", db.getOrgID());
			parameters.put("orgwhere", db.getOrgWhere(orgTable));
			parameters.put("organd", db.getOrgAnd(orgTable));

			String reportFilters = request.getParameter("reportfilters");
			String reportFilter[] = reportFilters.split(",");
			for(int i = 0; i < reportFilter.length; i++) {
				String filterValue = request.getParameter(reportFilter[i]);
				parameters.put(reportFilter[i], filterValue);
			}
		
			JasperPrint jasperPrint = JasperFillManager.fillReport(jasperReport, parameters, db.getDB());
			byte[] pdfdata = JasperExportManager.exportReportToPdf(jasperPrint);

			response.setCharacterEncoding("ISO-8859-1");
			response.setContentType("application/pdf");
			response.setHeader("Content-Disposition", "attachment; filename=report.pdf");
			response.setContentLength(pdfdata.length);
			response.getOutputStream().write(pdfdata);
			response.getOutputStream().flush();
		} catch (JRException ex) {
			log.severe("jasper exception " + ex);
		} catch (IOException ex) {
			log.severe("Web Print Writer Error : " + ex);
		}
	}

	public void	setParams(HttpSession session, String filterName, String filterValue) {
		if(filterValue == null) {
			filterValue = (String)session.getAttribute(filterName);
		} else {
			session.setAttribute(filterName, filterValue);
		}
    	parameters.put(filterName, filterValue);
		log.info("Filter = " + filterName + " key = " + filterValue);
	}

	public void	setParams(String filterName, String filterValue) {
    	parameters.put(filterName, filterName);
		log.info("Filter = " + filterName + " key = " + filterValue);
	}

	public void	setParams(Map<String, String> params) {
    	parameters.putAll(params);
		log.info("Param filter Done Filter.");
	}
}
