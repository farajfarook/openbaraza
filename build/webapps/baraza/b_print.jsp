<%@ page import="org.baraza.web.*" %>
<%@ page import="org.baraza.xml.BElement" %>

<%
	ServletContext context = getServletContext();
	String xmlcnf = (String)session.getAttribute("xmlcnf");
	String dbconfig = "java:/comp/env/jdbc/database";

	String ps = System.getProperty("file.separator");
	String xmlfile = context.getRealPath("WEB-INF") + ps + "configs" + ps + xmlcnf;
	String reportPath = context.getRealPath("reports") + ps;

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
%>


<%@ include file="/resources/include/init.jsp" %>

</head>

<body>

	<header>
		<div id="logo">
		</div>
		<div id="header">
		</div>
	</header>

<%= web.getBody(request, reportPath) %>

<% 	web.close(); %>
	
<%@ include file="/resources/include/footer.jsp" %>

