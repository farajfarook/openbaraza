<!DOCTYPE html>
<%@ page import="org.baraza.web.*" %>
<%@ page import="org.baraza.xml.BElement" %>

<%
	ServletContext context = getServletContext();
	String dbconfig = "java:/comp/env/jdbc/database";
	String xmlcnf = request.getParameter("xml");
	if(request.getParameter("logoff") == null) {
		if(xmlcnf == null) xmlcnf = (String)session.getAttribute("xmlcnf");
		if(xmlcnf == null) xmlcnf = context.getInitParameter("init_xml");
		if(xmlcnf == null) xmlcnf = context.getInitParameter("config_file");
		if(xmlcnf != null) session.setAttribute("xmlcnf", xmlcnf);
	} else {
		session.removeAttribute("xmlcnf");
		session.invalidate();
  	}

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
	web.setMainPage("index.jsp");

	String entryformid = null;
	String action = request.getParameter("action");
	String value = request.getParameter("value");
	String post = request.getParameter("post");
	String process = request.getParameter("process");
	String actionprocess = request.getParameter("actionprocess");
	if(actionprocess != null) process = "actionProcess";
	String reportexport = request.getParameter("reportexport");
	String excelexport = request.getParameter("excelexport");
	String actionOp = null;

	String fieldTitles = web.getFieldTitles();
	String auditTable = null;

	String contentType = request.getContentType();
	if(contentType != null) {
		if ((contentType.indexOf("multipart/form-data") >= 0)) {
			web.updateMultiPart(request, context, context.getRealPath("WEB-INF" + ps + "tmp"));
		}
	}

	String opResult = null;
	if(process != null) {
		if(process.equals("actionProcess")) {
			opResult = web.setOperation(actionprocess, request);
		} else if(process.equals("FormAction")) {
			String actionKey = request.getParameter("actionkey");
			opResult = web.setOperation(actionKey, request);
		} else if(process.equals("Update")) {
			web.updateForm(request);
		} else if(process.equals("Delete")) {
			web.deleteForm(request);
		} else if(process.equals("Submit")) {
			web.submitGrid(request);
		} else if(process.equals("Check All")) {
			web.setSelectAll();
		} else if(process.equals("Audit")) {
			auditTable = web.getAudit();
		}
	}

	if(excelexport != null) reportexport = excelexport;
	if(reportexport != null) {
		out.println("	<script>");
		out.println("		window.open('show_report?report=" + reportexport + "');");
		out.println("	</script>");
	}
%>

<!--[if IE 8]> <html lang="en" class="ie8 no-js"> <![endif]-->
<!--[if IE 9]> <html lang="en" class="ie9 no-js"> <![endif]-->
<!--[if !IE]><!-->
<html lang="en" class="no-js">
<!--<![endif]-->
<!-- BEGIN HEAD -->
<head>
	<meta charset="utf-8"/>
	<title><%= pageContext.getServletContext().getInitParameter("web_title") %></title>
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta content="width=device-width, initial-scale=1" name="viewport"/>
	<meta content="Open Baraza Framework" name="description"/>
	<meta content="Open Baraza" name="author"/>

	<!-- BEGIN GLOBAL MANDATORY STYLES -->
	<link href="http://fonts.googleapis.com/css?family=Open+Sans:400,300,600,700&subset=all" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/font-awesome/css/font-awesome.min.css"  rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/simple-line-icons/simple-line-icons.min.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/bootstrap/css/bootstrap.min.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/uniform/css/uniform.default.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/bootstrap-switch/css/bootstrap-switch.min.css" rel="stylesheet" type="text/css"/>
	<!-- END GLOBAL MANDATORY STYLES -->
	<!-- BEGIN PAGE LEVEL PLUGIN STYLES -->
	<link href="./assets/global/plugins/bootstrap-daterangepicker/daterangepicker-bs3.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/fullcalendar/fullcalendar.min.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/jqvmap/jqvmap/jqvmap.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/morris/morris.css" rel="stylesheet" type="text/css">
	<!-- END PAGE LEVEL PLUGIN STYLES -->
	<!-- BEGIN PAGE STYLES -->
	<link href="./assets/admin/pages/css/tasks.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/plugins/clockface/css/clockface.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/bootstrap-datepicker/css/bootstrap-datepicker3.min.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/bootstrap-timepicker/css/bootstrap-timepicker.min.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/bootstrap-colorpicker/css/colorpicker.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/bootstrap-daterangepicker/daterangepicker-bs3.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/bootstrap-datetimepicker/css/bootstrap-datetimepicker.min.css" rel="stylesheet" type="text/css" />
	<link href="./assets/global/plugins/jquery-tags-input/jquery.tagsinput.css" rel="stylesheet" type="text/css"/>
    <link href="./assets/global/plugins/select2/select2.css" rel="stylesheet" type="text/css" />
    <link href="./assets/global/plugins/jquery-multi-select/css/multi-select.css" rel="stylesheet" type="text/css" />
    <link href="./assets/global/plugins/fullcalendar/fullcalendar.min.css" rel="stylesheet"/>

    <link href="./assets/global/plugins/bootstrap-fileinput/bootstrap-fileinput.css" rel="stylesheet" type="text/css"/>
    <link href="./assets/admin/pages/css/profile.css" rel="stylesheet" type="text/css"/>

	<link href="./assets/global/plugins/jstree/dist/themes/default/style.min.css" rel="stylesheet" type="text/css"/>


    <!-- CSS to style the file input field as button and adjust the Bootstrap progress bars -->
    <link href="./assets/global/plugins/jquery-file-upload/css/jquery.fileupload.css" rel="stylesheet">

	<!-- END PAGE STYLES -->
	<!-- BEGIN THEME STYLES -->
	<!-- DOC: To use 'rounded corners' style just load 'components-rounded.css' stylesheet instead of 'components.css' in the below style tag -->

    <% if(web.isMaterial()) { %>
        <script >console.info("Material Design") </script>
        <link href="./assets/global/css/components-md.css" id="style_components" rel="stylesheet" type="text/css"/>
        <link href="./assets/global/css/plugins-md.css" rel="stylesheet" type="text/css"/>

    <% } else { %>
        <script >console.info("Default Design") </script>
        <link href="./assets/global/css/components-rounded.css" id="style_components" rel="stylesheet" type="text/css"/>
	    <link href="./assets/global/css/plugins.css" rel="stylesheet" type="text/css"/>
    <% } %>

	<link href="./assets/admin/layout4/css/layout.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/admin/layout4/css/themes/light.css" rel="stylesheet" type="text/css" id="style_color"/>

	<!-- END THEME STYLES -->
	<link rel="shortcut icon" href="./assets/logos/favicon.png"/>

	<link href="./assets/global/plugins/jquery-ui/jquery-ui-1.10.3.custom.min.css" rel="stylesheet" type="text/css" media="screen" />
    <link href="./assets/jqgrid/css/ui.jqgrid.css" rel="stylesheet" type="text/css" media="screen" />

    <link href="./assets/admin/layout4/css/custom.css" rel="stylesheet" type="text/css"/>

        <style type="text/css">

        </style>

</head>
<!-- END HEAD -->
<!-- BEGIN BODY -->
<!-- DOC: Apply "page-header-fixed-mobile" and "page-footer-fixed-mobile" class to body element to force fixed header or footer in mobile devices -->
<!-- DOC: Apply "page-sidebar-closed" class to the body and "page-sidebar-menu-closed" class to the sidebar menu element to hide the sidebar by default -->
<!-- DOC: Apply "page-sidebar-hide" class to the body to make the sidebar completely hidden on toggle -->
<!-- DOC: Apply "page-sidebar-closed-hide-logo" class to the body element to make the logo hidden on sidebar toggle -->
<!-- DOC: Apply "page-sidebar-hide" class to body element to completely hide the sidebar on sidebar toggle -->
<!-- DOC: Apply "page-sidebar-fixed" class to have fixed sidebar -->
<!-- DOC: Apply "page-footer-fixed" class to the body element to have fixed footer -->
<!-- DOC: Apply "page-sidebar-reversed" class to put the sidebar on the right side -->
<!-- DOC: Apply "page-full-width" class to the body element to have full width page without the sidebar menu -->
<body class="page-header-fixed page-sidebar-closed-hide-logo page-sidebar-closed-hide-logo page-footer-fixed">

<!-- BEGIN HEADER -->
<div class="page-header navbar navbar-fixed-top">
	<!-- BEGIN HEADER INNER -->
	<div class="page-header-inner">
		<!-- BEGIN LOGO -->
		<div class="page-logo">
			<a href="index.jsp">
			<img src="./assets/logos/logo_header.png" alt="logo" style="margin: 20px 10px 0 10px; width: 107px;" class="logo-default"/>
			</a>
			<div class="menu-toggler sidebar-toggler">
				<!-- DOC: Remove the above "hide" to enable the sidebar toggler button on header -->
			</div>
		</div>
		<!-- END LOGO -->
		<!-- BEGIN RESPONSIVE MENU TOGGLER -->
		<a href="javascript:;" class="menu-toggler responsive-toggler" data-toggle="collapse" data-target=".navbar-collapse">
		</a>
		<!-- END RESPONSIVE MENU TOGGLER -->

		<!-- BEGIN PAGE TOP -->
		<div class="page-top">

			<!-- BEGIN TOP NAVIGATION MENU -->
			<div class="top-menu">
				<ul class="nav navbar-nav pull-right">
					<!-- BEGIN USER LOGIN DROPDOWN -->
					<!-- DOC: Apply "dropdown-dark" class after below "dropdown-extended" to change the dropdown styte -->
					<li class="dropdown dropdown-user dropdown-dark">
						<a href="javascript:;" class="dropdown-toggle" data-toggle="dropdown" data-hover="dropdown" data-close-others="true">
						<span class="username username-hide-on-mobile">
						<%= web.getOrgName() %> | <%= web.getEntityName() %>  </span>
						<!-- DOC: Do not remove below empty space(&nbsp;) as its purposely used -->
						<img alt="" class="img-circle" src="./assets/admin/layout4/img/avatar.png"/>
						</a>
						<ul class="dropdown-menu dropdown-menu-default">
							<li>
								<a href="index.jsp?view=83:0">
								<i class="icon-rocket"></i> My Tasks
								</a>
							</li>
					<% if(web.hasPasswordChange()) { %>
							<li class="divider"></li>
							<li>
								<a data-toggle="modal" href="#basic">
									<i class="icon-rocket"></i> Change Password
								</a>
							</li>
					<% } %>
							<li class="divider"></li>
							<li>
								<a href="logout.jsp?logoff=yes">
								<i class="icon-key"></i> Log Out </a>
							</li>
						</ul>
					</li>
					<!-- END USER LOGIN DROPDOWN -->
				</ul>
			</div>
			<!-- END TOP NAVIGATION MENU -->
		</div>
		<!-- END PAGE TOP -->
	</div>
	<!-- END HEADER INNER -->
</div>

<!-- END HEADER -->

<div class="clearfix"></div>

<!-- BEGIN CONTAINER -->
<div class="page-container">
	<!-- BEGIN SIDEBAR -->
	<div class="page-sidebar-wrapper">
		<!-- DOC: Set data-auto-scroll="false" to disable the sidebar from auto scrolling/focusing -->
		<!-- DOC: Change data-auto-speed="200" to adjust the sub menu slide up/down speed -->
		<div class="page-sidebar navbar-collapse collapse">
			<!-- BEGIN SIDEBAR MENU -->
			<!-- DOC: Apply "page-sidebar-menu-light" class right after "page-sidebar-menu" to enable light sidebar menu style(without borders) -->
			<!-- DOC: Apply "page-sidebar-menu-hover-submenu" class right after "page-sidebar-menu" to enable hoverable(hover vs accordion) sub menu mode -->
			<!-- DOC: Apply "page-sidebar-menu-closed" class right after "page-sidebar-menu" to collapse("page-sidebar-closed" class must be applied to the body element) the sidebar sub menu mode -->
			<!-- DOC: Set data-auto-scroll="false" to disable the sidebar from auto scrolling/focusing -->
			<!-- DOC: Set data-keep-expand="true" to keep the submenues expanded -->
			<!-- DOC: Set data-auto-speed="200" to adjust the sub menu slide up/down speed -->

			<%= web.getMenu() %>

			<!-- END SIDEBAR MENU -->
		</div>
	</div>
	<!-- END SIDEBAR -->
	<!-- BEGIN CONTENT -->
	<div class="page-content-wrapper">
		<div class="page-content">

<% if(web.getViewType().equals("DASHBOARD")) { %>

		<%= web.getDashboard() %>

<% } else { %>

			<!-- BEGIN PAGE CONTENT-->
			<form id="baraza" name="baraza" method="post" action="index.jsp" data-confirm-send="false" data-ajax="false" <%= web.getEncType() %> >
				<%= web.getHiddenValues() %>
			<div class="row">
				<div class="col-md-12" >
					<div class="tabbable tabbable-tabdrop"><%= web.getTabs() %></div>
					<% if(opResult != null) out.println("<div style='color:#FF0000'>" + opResult + "</div>"); %>
					<%= web.getSaveMsg() %>

					<div class="portlet box <%= web.getViewColour() %>">
						<div class="portlet-title">
							<div class="caption">
								<i class="<%= web.getViewIcon() %>"></i><%= web.getViewName() %>
							</div>
							<div class="tools">
								<!--<a href="javascript:;" class="collapse">
								</a>
								<a href="javascript:;" class="reload">
								</a>
								<a href="javascript:;" class="remove">
								</a>-->
							</div>
							<%= web.getButtons() %>
						</div>

						<div class="portlet-body" style="min-height:360px;">
								<%= web.getBody(request, reportPath) %>
						</div>

						<%= web.getFilters() %>

						<% actionOp = web.getOperations();
						if(actionOp != null) {	%>
                            <div class="row" style="">
                                <div class="col-md-2" >
                                    <%= actionOp %>
                                </div>

                                <div class="col-md-1" >
                                    <button type="button" id="btnAction" name="process" value="Action" class="btn btn-sm green">Action</button>
                                </div>
                            </div>
						<%	} %>

						<% if(fieldTitles != null) { %>
							<table class="table" style="margin-bottom:0px;"><tr>
								<td ><%= fieldTitles %></td>
								<td >
									<select class='fnctcombobox form-control' name='filtertype' id='filtertype'>
										<option value='ilike'>Contains (case insensitive)</option>
										<option value='like'>Contains (case sensitive)</option>
										<option value='='>Equal to</option>
										<option value='>'>Greater than</option>
										<option value='<'>Less than</option>
										<option value='<='>Less or Equal</option>
										<option value='>='>Greater or Equal</option>
									</select>
								</td>
								<td ><input class="form-control" name="filtervalue" type="text" id="filtervalue" /></td>
								<td ><input class="form-control" name='filterand' id='filterand' type='checkbox'/> And</td>
								<td ><input class="form-control" name='filteror' id='filteror' type='checkbox' /> Or</td>
								<td ><button type="button" class="form-control" name="btSearch" id="btSearch" value="Search">Search</button></td>
								<td ></td>
							</tr></table>
						<% } %>

						<%= web.showFooter() %>
					</div>
				</div>
            
			    <% if(web.getViewType().equals("FILES")){ %>
                    <div class="row"> <!-- file upload row -->
                        <div class="col-md-12">
                            <span class="btn green fileinput-button">
                                <i class="glyphicon glyphicon-plus"></i>
                            <span>Add files...</span>
                            <!-- The file input field used as target for the file upload widget -->
                                <input id="fileupload" type="file" name="files[]" multiple>
                            </span>
                            <br>
                            <br>
                            <div id="progress" class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100">
                                <div class="progress-bar progress-bar-success" style="width:0%;">
                                </div>
                            </div>
                            <!-- The container for the uploaded files -->
                            <div id="files" class="files"></div>
                            <br>
                        </div>
                    </div><!-- end file upload row -->
                <% } %>
			</form>
<% } %>


		</div>
	</div>
	<!-- END CONTENT -->
</div>
<!-- END CONTAINER -->
<!-- BEGIN FOOTER -->
<div class="page-footer">
	<div class="page-footer-inner">
		2015 &copy; Open Baraza. <a href="http://dewcis.com">Dew Cis Solutions Ltd.</a> All Rights Reserved
	</div>
	<div class="scroll-to-top">
		<i class="icon-arrow-up"></i>
	</div>
</div>

<!-- END FOOTER -->
<!-- BEGIN JAVASCRIPTS(Load javascripts at bottom, this will reduce page load time) -->
<!-- BEGIN CORE PLUGINS -->
<!--[if lt IE 9]>
<script src="./assets/global/plugins/respond.min.js"></script>
<script src="./assets/global/plugins/excanvas.min.js"></script>
<![endif]-->
<script src="./assets/global/plugins/jquery.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery-migrate.min.js" type="text/javascript"></script>
<!-- IMPORTANT! Load jquery-ui.min.js before bootstrap.min.js to fix bootstrap tooltip conflict with jquery ui tooltip -->
<script src="./assets/global/plugins/jquery-ui/jquery-ui.min.js" type="text/javascript"></script>
<!--<script src="./jquery-ui-1.11.4.custom/jquery-ui.min.js"  type="text/javascript"></script>-->
<script src="./assets/global/plugins/bootstrap/js/bootstrap.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/bootstrap-hover-dropdown/bootstrap-hover-dropdown.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery-slimscroll/jquery.slimscroll.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery.blockui.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery.cokie.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/uniform/jquery.uniform.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/bootstrap-switch/js/bootstrap-switch.min.js" type="text/javascript"></script>
<!-- END CORE PLUGINS -->
<!-- BEGIN PAGE LEVEL PLUGINS -->
<script src="./assets/global/plugins/jqvmap/jqvmap/jquery.vmap.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.russia.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.world.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.europe.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.germany.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/maps/jquery.vmap.usa.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jqvmap/jqvmap/data/jquery.vmap.sampledata.js" type="text/javascript"></script>
<script src="./assets/global/plugins/bootstrap-datetimepicker/js/bootstrap-datetimepicker.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/bootstrap-datepicker/js/bootstrap-datepicker.min.js" type="text/javascript" ></script>
<script src="./assets/global/plugins/ckeditor/ckeditor.js" type="text/javascript" ></script>

<script src="./assets/global/plugins/jquery-inputmask/jquery.inputmask.bundle.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/select2/select2.min.js" type="text/javascript"></script>

<!-- IMPORTANT! fullcalendar depends on jquery-ui.min.js for drag & drop support -->
<script src="./assets/global/plugins/morris/morris.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/morris/raphael-min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery.sparkline.min.js" type="text/javascript"></script>
<!-- END PAGE LEVEL PLUGINS -->
<script src="./assets/global/plugins/jquery-file-upload/js/vendor/jquery.ui.widget.js"></script>
<!-- The Load Image plugin is included for the preview images and image resizing functionality -->
<!--<script src="//blueimp.github.io/JavaScript-Load-Image/js/load-image.all.min.js"></script>-->
<script src="./assets/global/plugins/jquery-file-upload/js/vendor/load-image.min.js"></script>
<!-- The Canvas to Blob plugin is included for image resizing functionality -->
<script src="./assets/global/plugins/jquery-file-upload/js/vendor/canvas-to-blob.min.js"></script>
<!-- The Iframe Transport is required for browsers without support for XHR file uploads -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.iframe-transport.js"></script>
<!-- The basic File Upload plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload.js"></script>
<!-- The File Upload processing plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload-process.js"></script>
<!-- The File Upload image preview & resize plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload-image.js"></script>
<!-- The File Upload audio preview plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload-audio.js"></script>
<!-- The File Upload video preview plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload-video.js"></script>
<!-- The File Upload validation plugin -->
<script src="./assets/global/plugins/jquery-file-upload/js/jquery.fileupload-validate.js"></script>

<!-- BEGIN PAGE LEVEL SCRIPTS -->
<script src="./assets/global/plugins/bootstrap-fileinput/bootstrap-fileinput.js" type="text/javascript"></script>
<script src="./assets/global/scripts/metronic.js" type="text/javascript"></script>
<script src="./assets/admin/layout4/scripts/layout.js" type="text/javascript"></script>
<script src="./assets/admin/layout4/scripts/demo.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/index3.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/tasks.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/components-pickers.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery-multi-select/js/jquery.multi-select.js" type="text/javascript" ></script>
<script src="./assets/global/plugins/jquery-multi-select/js/jquery.quicksearch.js" type="text/javascript"></script>

<script src="./assets/global/plugins/jstree/dist/jstree.min.js"></script>
<script src="./assets/admin/pages/scripts/ui-tree.js"></script>

<!-- END PAGE LEVEL SCRIPTS -->

<script type="text/javascript" src="./assets/jqgrid/js/i18n/grid.locale-en.js"></script>
<script type="text/javascript" src="./assets/jqgrid/js/jquery.jqGrid.min.js"></script>

<!-- calendar-->
<!-- IMPORTANT! fullcalendar depends on jquery-ui.min.js for drag & drop support -->
<script src="./assets/global/plugins/moment.min.js"></script>
<script src="./assets/global/plugins/fullcalendar/fullcalendar.min.js"></script>

<script>
    jQuery(document).ready(function() {
        Metronic.init(); // init metronic core componets
        Layout.init(); // init layout
        Calendar.init();
        $('.date-picker').datepicker({
            autoclose: true
        });

        $('.select2me').select2({
            placeholder: "Select an option",
            allowClear: true
        });

		UITree.init();

        //alert('<%= web.getView().getName().equals("FILES") %>');
    });
</script>

<script>
   	function updateField(valueid, valuename) {
		document.getElementsByName(valueid)[0].value = valuename;
	}

    <% if(web.isGrid()) { %>
	var lastsel2;

    var jqcf = <%= web.getJSONHeader() %>;

    jqcf.rowNum = 30;
    jqcf.height = 300;
    jqcf.rowList=[10,20,30,40,50];
    jqcf.datatype = "json";
    jqcf.pgbuttons = true;
	jqcf.loadonce = true;
	jqcf.autoencode = false;
	jqcf.editurl = "ajaxupdate";

    jqcf.jsonReader = {
        repeatitems: false,
        root: function (obj) { return obj; },
        page: function (obj) { return jQuery("#jqlist").jqGrid('getGridParam', 'page'); },
        total: function (obj) { return Math.ceil(obj.length / jQuery("#jqlist").jqGrid('getGridParam', 'rowNum')); },
        records: function (obj) { return obj.length; }
    }

    <% if(actionOp != null) {	%>
      jqcf.multiselect = true;
    <% } %>

	/* check if user is using mobile*/
    var isMobile = false; //initiate as false
    // device detection
    if(/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|ipad|iris|kindle|Android|Silk|lge |maemo|midp|mmp|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.test(navigator.userAgent)
        || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(navigator.userAgent.substr(0,4))) isMobile = true;

<% if(web.hasChildren()) { %>
    if(isMobile){
        jqcf.onSelectRow = function(rowid) {
            console.log(rowid);
            var data = jQuery("#jqlist").jqGrid('getRowData',rowid);
            location.replace(data.CL);
        };

    }else{
		jqcf.ondblClickRow = function(rowid) {
		    console.log(rowid);
		    var data = jQuery("#jqlist").jqGrid('getRowData',rowid);
		    location.replace(data.CL);
		};

	  <% if(web.isEditField()) { %>
        jqcf.onSelectRow = function(id){
          if(id && id!==lastsel2){
            jQuery('#jqlist').restoreRow(lastsel2);
            jQuery('#jqlist').editRow(id,true);
            lastsel2=id;
          }
        };
	  <% } %>
    }
<% } %>
    //console.log(jqcf);

    jQuery("#jqlist").jqGrid(jqcf);
    jQuery("#jqlist").jqGrid("navGrid", "#jqpager", {edit:false, add:false, del:false, search:false});

    $('#btSearch').click(function(){
        var filtername = $("#filtername").val();
        var filtertype = $("#filtertype").val();
        var filtervalue = $("#filtervalue").val();
        var filterand = $("#filterand").is(':checked');
        var filteror = $("#filteror").is(':checked');

        $.post("ajax?fnct=filter", {filtername: filtername, filtertype: filtertype, filtervalue: filtervalue, filterand: filterand, filteror: filteror}, function(data){
            $('#jqlist').setGridParam({datatype:'json', page:1}).trigger('reloadGrid');
        });
    });

    $('.reload').click(function(){
        $('#jqlist').trigger('reloadGrid');
    });

	$('#btnAction').click(function(){
	    var operation = $("#operation").val();

	    var $grid = $("#jqlist"), selIds = $grid.jqGrid("getGridParam", "selarrrow"), i, n, cellValues = [];
	    for (i = 0, n = selIds.length; i < n; i++) {
	        var coldata = $grid.jqGrid("getCell", selIds[i], "CL");
	        var begin = coldata.lastIndexOf("=");
	        var end = coldata.length;
	        var id = coldata.substring(begin + 1, end);
	        cellValues.push(id);
	    }
	    if(cellValues.join(",") == ""){
	        alert('No row Selected');
	    } else {
	        $.post("ajax?fnct=operation&id=" + operation, {ids: cellValues.join(",")}, function(data) {
	            $('#jqlist').setGridParam({datatype:'json', page:1}).trigger('reloadGrid');
	        });
	    }
	});

    <% } %>

    // MULTISELECT INITIALIZE
    $('.multi-select').multiSelect({
            selectableHeader: "<input type='text' class='search-input form-control' autocomplete='off' placeholder='Search Address'>",
            selectionHeader: "<input type='text' class='search-input form-control' autocomplete='off' placeholder='Search Address'>",
            selectableFooter: "<div style='text-align: center;padding: 3px;color: #fff;' class='list-group-item bg-blue'>Selectable Items</div>",
            selectionFooter: "<div style='text-align: center;padding: 3px;color: #fff;' class='list-group-item bg-green'>Selected</div>",
            afterInit: function(ms){
            var that = this,
                $selectableSearch = that.$selectableUl.prev(),
                $selectionSearch = that.$selectionUl.prev(),
                selectableSearchString = '#'+that.$container.attr('id')+' .ms-elem-selectable:not(.ms-selected)',
                selectionSearchString = '#'+that.$container.attr('id')+' .ms-elem-selection.ms-selected';

            that.qs1 = $selectableSearch.quicksearch(selectableSearchString)
            .on('keydown', function(e){
              if (e.which === 40){
                that.$selectableUl.focus();
                return false;
              }
            });

            that.qs2 = $selectionSearch.quicksearch(selectionSearchString)
            .on('keydown', function(e){
              if (e.which == 40){
                that.$selectionUl.focus();
                return false;
              }
            });
            },
            afterSelect: function(){
                this.qs1.cache();
                this.qs2.cache();
            },
            afterDeselect: function(){
                this.qs1.cache();
                this.qs2.cache();
            }
        });


        CKEDITOR.config.toolbar = [
           ['Styles','Format','Font','FontSize'],
           '/',
           ['Bold','Italic','Underline','StrikeThrough','-','Undo','Redo','-','Cut','Copy','Paste','Find','Replace','-','Outdent','Indent','-','Print'],
           '/',
           ['NumberedList','BulletedList','-','JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
           ['Image','Table','-','Link','Flash','Smiley','TextColor','BGColor','Source']
        ] ;


</script>
<script>
/*jslint unparam: true, regexp: true */
/*global window, $ */
$(function () {
    'use strict';

    $('#fileupload').fileupload({
        url: 'putbarazafiles',
        dataType: 'json',
        autoUpload: true,
        acceptFileTypes: /(\.|\/)(gif|jpe?g|png)$/i,
        maxFileSize: 999000,
        // Enable image resizing, except for Android and Opera,
        // which actually support image resizing, but fail to
        // send Blob objects via XHR requests:
        disableImageResize: /Android(?!.*Chrome)|Opera/
            .test(window.navigator.userAgent),
        previewMaxWidth: 100,
        previewMaxHeight: 100,
        previewCrop: true
    }).on('fileuploadadd', function (e, data) {
        data.context = $('<div/>').appendTo('#files');
        $.each(data.files, function (index, file) {
            var node = $('<p/>')
                    .append($('<span/>').text(file.name));
            if (!index) {
                node
                    .append('<br>')
                   // .append(uploadButton.clone(true).data(data));
            }
            node.appendTo(data.context);
        });
    }).on('fileuploadprocessalways', function (e, data) {
        var index = data.index,
            file = data.files[index],
            node = $(data.context.children()[index]);
        if (file.preview) {
            node
                .prepend('<br>')
                .prepend(file.preview);
        }
        if (file.error) {
            node
                .append('<br>')
                .append($('<span class="text-danger"/>').text(file.error));
        }
        if (index + 1 === data.files.length) {
            data.context.find('button')
                .text('Upload')
                .prop('disabled', !!data.files.error);
        }
    }).on('fileuploadprogressall', function (e, data) {
        var progress = parseInt(data.loaded / data.total * 100, 10);
        $('#progress .progress-bar').css(
            'width',
            progress + '%'
        );
    }).on('fileuploaddone', function (e, data) {
        $.each(data.result.files, function (index, file) {
            if (file.url) {
                var link = $('<a>')
                    .attr('target', '_blank')
                    .prop('href', file.url);
                $(data.context.children()[index])
                    .wrap(link);
            } else if (file.error) {
                var error = $('<span class="text-danger"/>').text(file.error);
                $(data.context.children()[index])
                    .append('<br>')
                    .append(error);
            }
            $('#jqlist').trigger('reloadGrid');
        });
    }).on('fileuploadfail', function (e, data) {
        $.each(data.files, function (index) {
            var error = $('<span class="text-danger"/>').text('File upload failed.');
            $(data.context.children()[index])
                .append('<br>')
                .append(error);
        });
    }).prop('disabled', !$.support.fileInput)
        .parent().addClass($.support.fileInput ? undefined : 'disabled');
});
</script>
<!-- END JAVASCRIPTS -->
<% if(web.getViewType().equals("DIARY")){ 
	String diaryJSON = web.getCalendar();
%>
	<%@ include file="./assets/include/calendar.jsp" %>
<% } %>
<% if(web.hasPasswordChange()) { %>
	<%@ include file="./assets/include/password_change.jsp" %>
<% } %>
</body>
<!-- END BODY -->
</html>

<% 	web.close(); %>
