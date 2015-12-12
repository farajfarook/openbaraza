<%@ page import="org.baraza.web.*" %>
<%@ page import="org.baraza.xml.BElement" %>

<%@ include file="/resources/include/init.jsp" %>

<%
	ServletContext context = getServletContext();
	String dbconfig = "java:/comp/env/jdbc/database";
	String xmlcnf = request.getParameter("xml");
	if(request.getParameter("logoff") == null) {
		if(xmlcnf == null) xmlcnf = (String)session.getAttribute("xmlcnf");
		if(xmlcnf == null) xmlcnf = context.getInitParameter("config_file");
		if(xmlcnf != null) session.setAttribute("xmlcnf", xmlcnf);
	} else {
		session.removeAttribute("xmlcnf");
		session.invalidate();
  	}

	String ps = System.getProperty("file.separator");
	String xmlfile = context.getRealPath("WEB-INF") + ps + "configs" + ps + xmlcnf;
	String reportPath = context.getRealPath("reports") + ps;

	String userIP = request.getRemoteAddr();
	String userName = request.getRemoteUser();

	BWeb web = new BWeb(dbconfig, xmlfile);
	web.setUser(userIP, userName);
	web.init(request);
	web.setMainPage("index.jsp");

	BForms forms = new BForms("java:/comp/env/jdbc/database");

	String action = request.getParameter("action");
	String formid = request.getParameter("actionvalue");
	String startdate = request.getParameter("startdate");
	String enddate = request.getParameter("enddate");
	String reportLevel = request.getParameter("reportlevel");
	String reportField = request.getParameter("reportfield");
	String sdv = ""; String sdva = ""; String edv = ""; String edva = "";
	String rla = ""; String rfa = "";

	if(action == null) action = "FORMREPORT";
	if(startdate != null) {sdv = "value='" + startdate + "'"; sdva = "&startdate=" + startdate; }
	if(enddate != null) {edv = "value='" + enddate + "'"; edva = "&enddate=" + enddate; }
	if(reportLevel != null) rla = "&reportlevel=" + reportLevel;
	if(reportField  != null) rfa = "&reportfield=" + reportField;
%>

</head>

<body>

	<div id="pageoptions">
		<ul>
			<li><%= web.getOrgName() %> | </li>
			<li><%= web.getEntityName() %> | </li>
			<li><a href="b_passwordchange.jsp">Change Password</a> | </li>
			<li><a href="logout.jsp?logoff=yes">Logout | </a></li>
			<li><a href="http://www.openbaraza.org" target='_blank'>Made On Baraza  |  </a></li>
			<li><a href="http://www.dewcis.com" target='_blank'>Made by Dew CIS Solutions Ltd</a></li>

		</ul>
	</div>

	<header>
		<div id="logo">
		</div>
		<div id="header">
		</div>
	</header>

	<nav>
		<div id="main-menu">
	           	<%= web.getMenu() %>

	            <div id="bottom"></div>
		</div>
	</nav>
	
	<section id="content">

		<form id="baraza" name="baraza" method="post" action="form.report.jsp">
		<div id='header_contents'>
			<table><tr>
			<td>Level : <select name='reportlevel'><option>Basic</option><option>Detailed</option><option>Sub Field</option></select></td>
			<td>Starting from : 
			<a href="#" onclick="cal.select(document.forms[0].startdate,'anchor1','dd/MM/yyyy'); return false;" name="anchor1" id="anchor1"> select </a>
			<input type='text' name='startdate' size='15' <%= sdv %>/>
			</td>
			<td>Ending at : 
			<a href="#" onclick="cal.select(document.forms[0].enddate,'anchor1','dd/MM/yyyy'); return false;" name="anchor1" id="anchor1"> select </a>
			<input type='text' name='enddate' size='15' <%= edv %>/>
			</td>
			<%= forms.getFormField(formid) %>
			<td><input type="submit" name="filter" value="Filter" class="altProcessButtonFormat"/></td>
			<td><a href="form.exel.jsp?formid=<%=formid + sdva + edva + rla + rfa %>">Export</a></td>
			</tr></table>
		</div>

		<input type="hidden" name="action" value="<%= action %>"/>
		<input type="hidden" name="actionvalue" value="<%= formid %>"/>

		</form>

	<% if(action.equals("FORMREPORT")) { %>

		<div id='body_content'>
			<%=	forms.getFormReport(formid, startdate, enddate, reportLevel, reportField) %>
		</div>

	<% } %>

<% 	forms.close(); %>
<% 	web.close(); %>
	
<%@ include file="/resources/include/footer.jsp" %>

