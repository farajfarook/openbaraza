<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<c:set var="contextPath" value="${pageContext.request.contextPath}" />
<%
	session.removeAttribute("xmlcnf");
	session.invalidate();
%>
<!DOCTYPE html>

<!--[if IE 8]> <html lang="en" class="ie8 no-js"> <![endif]-->
<!--[if IE 9]> <html lang="en" class="ie9 no-js"> <![endif]-->
<!--[if !IE]><!-->
<html lang="en">
<!--<![endif]-->
<!-- BEGIN HEAD -->
<head>
<meta charset="utf-8"/>
<title><%= pageContext.getServletContext().getInitParameter("login_title") %></title>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<meta http-equiv="Content-type" content="text/html; charset=utf-8">
<meta content="" name="description"/>
<meta content="" name="author"/>
<!-- BEGIN GLOBAL MANDATORY STYLES -->
<link href="http://fonts.googleapis.com/css?family=Open+Sans:400,300,600,700&subset=all" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/global/plugins/font-awesome/css/font-awesome.min.css" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/global/plugins/simple-line-icons/simple-line-icons.min.css" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/global/plugins/bootstrap/css/bootstrap.min.css" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/global/plugins/uniform/css/uniform.default.css" rel="stylesheet" type="text/css"/>
<!-- END GLOBAL MANDATORY STYLES -->
<!-- BEGIN PAGE LEVEL STYLES -->
<link href="${contextPath}/assets/admin/pages/css/login-soft.css" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/admin/pages/css/lock2.css" rel="stylesheet" type="text/css" />
<!-- END PAGE LEVEL STYLES -->
<!-- BEGIN THEME STYLES -->
<link href="${contextPath}/assets/global/css/components-rounded.css" id="style_components" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/global/css/plugins.css" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/admin/layout/css/layout.css" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/admin/layout/css/themes/default.css" rel="stylesheet" type="text/css" id="style_color"/>
<link href="${contextPath}/assets/admin/layout/css/custom.css" rel="stylesheet" type="text/css"/>
<!-- END THEME STYLES -->
<link rel="shortcut icon" href="favicon.ico"/>
</head>
    
<!-- END HEAD -->
<!-- BEGIN BODY -->
<body>
<div class="page-lock">
	<div class="page-logo">
		<a class="brand" href="index.html">
        <img src="${contextPath}/assets/logos/logo.png" alt=""/>
        
            <!--<img src="${contextPath}/assets/admin/layout4/img/logo-big.png" alt="logo"/>-->

		</a>
	</div>
	<div class="page-body">
        
        <div class="row">
            <div class="col-md-12 text-center">
                <div class="login-form text-left">
                    <h3 class="form-title"><%= pageContext.getServletContext().getInitParameter("login_title") %></h3>
                </div>
                
                <div class="Metronic-alerts alert alert-danger fade in">
                    <h4>Invalid Username Or Password</h4>
                </div>
                <div class="form-group">
                    <a class="btn green" href="index.jsp"><i class="icon-login"></i>&nbsp;Try Again</a>
                </div>
                <div class="form-group">
                    <a class="btn blue" href="application.jsp?view=2:0"><i class="icon-key"></i>&nbsp;Recover Lost Password</a>
                </div>
                <div class="form-group">
                    <a class="btn default" href="application.jsp?view=1:0"><i class="icon-user-follow"></i> &nbsp;Register New Account</a>
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-md-4 col-md-offset-1">
                
            </div>
        </div>
        
        <div class="row">
            <div class="col-md-4 col-md-offset-3">
                
            </div>
        </div>
        
        
        
        
		<!--<img class="page-lock-img" src="./assets/admin/pages/media/profile/profile.jpg" alt="">-->
        <!--<img class="page-lock-img" src="./assets/admin/pages/media/profile/avatar.png" alt="">
        
		<div class="page-lock-info"> 
			<h1>Bob Nilson</h1> 
			<span class="email">
			bob@keenthemes.com </span>
			<span class="locked"> 
			Locked </span>
			<form class="form-inline" action="index.html">
				<div class="input-group input-medium">
					<input type="text" class="form-control" placeholder="Password">
					<span class="input-group-btn">
					<button type="submit" class="btn blue icn-only"><i class="m-icon-swapright m-icon-white"></i></button>
					</span>
				</div>
				
				<div class="relogin">
					<a href="login.html">
					Not Bob Nilson ? </a>
				</div>
			</form>
		</div>-->
	</div>
	<div class="page-footer-custom">
		 2015 &copy; Open Baraza. <a href="http://dewcis.com">Dew Cis Solutions Ltd.</a> All Rights Reserved
	</div>
</div>
<!-- BEGIN JAVASCRIPTS(Load javascripts at bottom, this will reduce page load time) -->
<!-- BEGIN CORE PLUGINS -->
<!--[if lt IE 9]>
<script src="../../assets/global/plugins/respond.min.js"></script>
<script src="../../assets/global/plugins/excanvas.min.js"></script> 
<![endif]-->
<script src="${contextPath}/assets/global/plugins/jquery.min.js" type="text/javascript"></script>
<script src="${contextPath}/assets/global/plugins/jquery-migrate.min.js" type="text/javascript"></script>
<script src="${contextPath}/assets/global/plugins/bootstrap/js/bootstrap.min.js" type="text/javascript"></script>
<script src="${contextPath}/assets/global/plugins/jquery.blockui.min.js" type="text/javascript"></script>
<script src="${contextPath}/assets/global/plugins/uniform/jquery.uniform.min.js" type="text/javascript"></script>
<script src="${contextPath}/assets/global/plugins/jquery.cokie.min.js" type="text/javascript"></script>
<!-- END CORE PLUGINS -->
<!-- BEGIN PAGE LEVEL PLUGINS -->
<script src="${contextPath}/assets/global/plugins/backstretch/jquery.backstretch.min.js" type="text/javascript"></script>
<!-- END PAGE LEVEL PLUGINS -->
<script src="${contextPath}/assets/global/scripts/metronic.js" type="text/javascript"></script>
<script src="${contextPath}/assets/admin/layout/scripts/layout.js" type="text/javascript"></script>
<script src="${contextPath}/assets/admin/layout/scripts/demo.js" type="text/javascript"></script>
<script>
jQuery(document).ready(function() {    
    Metronic.init(); // init metronic core components
    Layout.init(); // init current layout
    //Lock.init();
    //Demo.init();
    $.backstretch([
        "${contextPath}/assets/admin/pages/media/bg/1.jpg",
        "${contextPath}/assets/admin/pages/media/bg/2.jpg",
        "${contextPath}/assets/admin/pages/media/bg/3.jpg",
        "${contextPath}/assets/admin/pages/media/bg/4.jpg"
        ], {
          fade: 1000,
          duration: 8000
    }
    );
});
</script>
<!-- END JAVASCRIPTS -->
</body>
<!-- END BODY -->
</html>