<%@ page import="org.baraza.web.*" %>

<%
	String formid = request.getParameter("formid");
	String startdate = request.getParameter("startdate");
	String enddate = request.getParameter("enddate");
	String reportLevel = request.getParameter("reportlevel");

	BForms forms = new BForms("java:/comp/env/jdbc/database");
	forms.getReport(request, response);
	forms.close(); 
%>


