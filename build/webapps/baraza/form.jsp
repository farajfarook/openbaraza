<%@ page import="org.baraza.web.*" %>

<%
	String dbconfig = "java:/comp/env/jdbc/database";
	String entryformid = null;
	String action = request.getParameter("action");
	String value = request.getParameter("value");
	String post = request.getParameter("post");
	String process = request.getParameter("process");
	String reportexport = request.getParameter("reportexport");

	String contentType = request.getContentType();
	if (contentType != null) {
		if (contentType.indexOf("multipart/form-data") >= 0) {
			BForms uploadForms = new BForms(dbconfig);
			entryformid = uploadForms.uploadFile(request);
			uploadForms.close();

			action = "ENTRYFORM";
		}
	}

	BForms forms = new BForms(dbconfig);
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
	<meta content="" name="description"/>
	<meta content="" name="author"/>
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


	<!-- END PAGE STYLES -->
	<!-- BEGIN THEME STYLES -->
	<!-- DOC: To use 'rounded corners' style just load 'components-rounded.css' stylesheet instead of 'components.css' in the below style tag -->
	<link href="./assets/global/css/components-rounded.css" id="style_components" rel="stylesheet" type="text/css"/>
	<link href="./assets/global/css/plugins.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/admin/layout4/css/layout.css" rel="stylesheet" type="text/css"/>
	<link href="./assets/admin/layout4/css/themes/light.css" rel="stylesheet" type="text/css" id="style_color"/>
	
	<!-- END THEME STYLES -->
	<link rel="shortcut icon" href="favicon.ico"/>

	<link rel="stylesheet" type="text/css" media="screen" href="assets/global/plugins/jquery-ui/jquery-ui-1.10.3.custom.min.css" />
    <link href="./jquery-ui-1.11.4.custom/jquery-ui.theme.min.css" rel="search" type="text/css" />
    <link rel="stylesheet" type="text/css" media="screen" href="assets/jqgrid/css/ui.jqgrid.css" />

    <link href="./assets/admin/layout4/css/custom.css" rel="stylesheet" type="text/css"/>

</head>

<body class="page-header-fixed page-sidebar-closed-hide-logo page-sidebar-closed-hide-logo page-footer-fixed">

<% if(action.equals("FORM")) { %>

	<div class="widget" id="form_widget">

		<FORM>
		<INPUT TYPE="button" onClick="window.print()" value="PRINT">
		</FORM>

		<div>
		    <%= forms.getForm(null, request.getParameterMap()) %>
		</div>
	</div>



<% } else if(action.equals("ENTRYFORM")) { %>
	<div id="content">
		<%= forms.getForm(entryformid, request.getParameterMap()) %>
	</div>

<% }

	forms.close();
%>

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

<script src="./assets/global/plugins/jquery-inputmask/jquery.inputmask.bundle.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/select2/select2.min.js" type="text/javascript"></script>

<!-- IMPORTANT! fullcalendar depends on jquery-ui.min.js for drag & drop support -->
<script src="./assets/global/plugins/morris/morris.min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/morris/raphael-min.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery.sparkline.min.js" type="text/javascript"></script>
<!-- END PAGE LEVEL PLUGINS -->
<!-- BEGIN PAGE LEVEL SCRIPTS -->
<script src="./assets/global/scripts/metronic.js" type="text/javascript"></script>
<script src="./assets/admin/layout4/scripts/layout.js" type="text/javascript"></script>
<script src="./assets/admin/layout4/scripts/demo.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/index3.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/tasks.js" type="text/javascript"></script>
<script src="./assets/admin/pages/scripts/components-pickers.js" type="text/javascript"></script>
<script src="./assets/global/plugins/jquery-multi-select/js/jquery.multi-select.js" type="text/javascript" ></script>

<!-- END PAGE LEVEL SCRIPTS -->

<script type="text/javascript" src="./assets/jqgrid/js/i18n/grid.locale-en.js"></script>
<script type="text/javascript" src="./assets/jqgrid/js/jquery.jqGrid.min.js"></script>

	<script type="text/javascript">

      $(document).ready(function(){

	    $('.btnAddMore').live('click',function(){

		var clonedRow = $(".subTable" + this.getAttribute("name") + " tr:last").clone().html();
		var appendRow = '<tr class = "row">' + clonedRow + '</tr>';

		$('.subTable' + this.getAttribute("name") + ' tr:last').after(appendRow);
		});

	    //when you click on the button called "delete", the function inside will be triggered.
	    $('.deleteThisRow').live('click',function(){

		var num = this.getAttribute("name");
		var rowLength = $('#subTable' + num + ' tr').length;


		//this line makes sure that we don't ever run out of rows.
		if(rowLength > 2){
		    deleteRow(this);
		    }
		else{
		    $('.subTable tr:last').after(appendRow);
		    deleteRow(this);
		    }
	      });

		function deleteRow(currentNode){
			  $(currentNode).parent().parent().remove();
			  }
		  });

	</script>

	<script>
		jQuery(document).ready(function() {    
            
		   Metronic.init(); // init metronic core componets
		   Layout.init(); // init layout
		   //Demo.init(); // init demo features 
		   //Index.init(); // init index page
		   //Tasks.initDashboardWidget(); // init tash dashboard widget  
		   //ComponentsPickers.init();
            
            $('.date-picker').datepicker();
            
            //alert($(".mask_currency").length);
            
            $('.multi-select').multiSelect();
            
            /*$(".mask_currency").each(function(i, obj){
                var mask = $(this).attr('data-mask');
                $(this).inputmask(mask, {
                    numericInput: true
                });
            });*/

            $('.select2me').select2({
                placeholder: "Select an option",
                allowClear: true
            });
		});
	</script>

<!-- END JAVASCRIPTS -->

</body>
</html>


