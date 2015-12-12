<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<c:set var="contextPath" value="${pageContext.request.contextPath}" />

<!-- pageContext -->
<!DOCTYPE html>

<!--[if IE 8]> <html lang="en" class="ie8 no-js"> <![endif]-->
<!--[if IE 9]> <html lang="en" class="ie9 no-js"> <![endif]-->
<!--[if !IE]><!-->
<html lang="en">
<!--<![endif]-->
<!-- BEGIN HEAD -->
<head>
<meta charset="utf-8"/>

<title><%= pageContext.getServletContext().getInitParameter("web_title") %></title>
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<meta http-equiv="Content-type" content="text/html; charset=utf-8">
<meta content="" name="description"/>
<meta content="" name="author"/>
<!-- BEGIN GLOBAL MANDATORY STYLES -->
<!-- <link href="http://fonts.googleapis.com/css?family=Open+Sans:400,300,600,700&subset=all" rel="stylesheet" type="text/css"/> -->
<link href="${contextPath}/assets/global/plugins/font-awesome/css/font-awesome.min.css" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/global/plugins/simple-line-icons/simple-line-icons.min.css" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/global/plugins/bootstrap/css/bootstrap.min.css" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/global/plugins/uniform/css/uniform.default.css" rel="stylesheet" type="text/css"/>
<!-- END GLOBAL MANDATORY STYLES -->
<!-- BEGIN PAGE LEVEL STYLES -->
<link href="${contextPath}/assets/global/plugins/select2/select2.css" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/admin/pages/css/login-soft.css" rel="stylesheet" type="text/css"/>
<!-- END PAGE LEVEL SCRIPTS -->
<!-- BEGIN THEME STYLES -->
<link href="${contextPath}/assets/global/css/components-md.css" id="style_components" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/global/css/plugins-md.css" rel="stylesheet" type="text/css"/>
<link href="${contextPath}/assets/admin/layout4/css/layout.css" rel="stylesheet" type="text/css"/>
<link id="style_color" href="${contextPath}/assets/admin/layout4/css/themes/default.css" rel="stylesheet" type="text/css"/>
    
<link href="${contextPath}/assets/admin/layout4/css/custom.css" rel="stylesheet" type="text/css"/>
    
    
    
<!-- END THEME STYLES -->
<link rel="shortcut icon" href="favicon.ico"/>
</head>
<!-- END HEAD -->
<!-- BEGIN BODY -->
<body class="page-md login" id="login">
<!-- BEGIN LOGO -->
<div class="logo">
	<a href="index.jsp">
    <img src="${contextPath}/assets/logos/logo.png" alt=""/>
	</a>
</div>
<!-- END LOGO -->
<!-- BEGIN SIDEBAR TOGGLER BUTTON -->
<div class="menu-toggler sidebar-toggler">
</div>
<!-- END SIDEBAR TOGGLER BUTTON -->
<!-- BEGIN LOGIN -->
<div class="content">
	<!-- BEGIN LOGIN FORM -->
	<form class="login-form" method="POST" action="j_security_check" method="post">
		<h3 class="form-title"><%= pageContext.getServletContext().getInitParameter("login_title") %></h3>
		<div class="alert alert-danger display-hide">
			<button class="close" data-close="alert"></button>
			<span>
			Enter  username and password. </span>
		</div>
		<div class="form-group">
			<!--ie8, ie9 does not support html5 placeholder, so we just show field title for that-->
			<label class="control-label visible-ie8 visible-ie9">Username</label>
			<div class="input-icon">
				<i class="fa fa-user"></i>
				<input class="form-control placeholder-no-fix" type="text" autocomplete="off" placeholder="Username" 
				id="j_username" name="j_username" autofocus required
				/>
			</div>
		</div>
		<div class="form-group">
			<label class="control-label visible-ie8 visible-ie9">Password</label>
			<div class="input-icon">
				<i class="fa fa-lock"></i>
				<input class="form-control placeholder-no-fix" type="password" autocomplete="off" placeholder="Password" 
				id="j_password" name="j_password" required/>
			</div>
		</div>
		<div class="form-actions">
			<label class="checkbox">
			<input type="checkbox" name="remember" value="1"/> Remember me </label>
			<button type="submit" class="btn blue pull-right">
			Login <i class="m-icon-swapright m-icon-white"></i>
			</button>
		</div>
		<a class="" href="application.jsp?view=1:0" style="color:#0088cc; font-size:18px">Register New Account</a> 
		<div class="forget-password">
			<h4>Forgot your password ?</h4>
			<p>
				 no worries, click <a class="" href="application.jsp?view=2:0" style="color:#0088cc;">Recover Lost Password</a>
				to reset your password.
			</p>
		</div>
        
		
	</form>
	<!-- END LOGIN FORM -->
	<!-- BEGIN FORGOT PASSWORD FORM -->
	<form class="forget-form" action="index.html" method="post">
		<h3>Forget Password ?</h3>
		<p>
			 Enter your e-mail address below to reset your password.
		</p>
		<div class="form-group">
			<div class="input-icon">
				<i class="fa fa-envelope"></i>
				<input class="form-control placeholder-no-fix" type="text" autocomplete="off" placeholder="Email" name="email"/>
			</div>
		</div>
		<div class="form-actions">
			<button type="button" id="back-btn" class="btn">
			<i class="m-icon-swapleft"></i> Back </button>
			<button type="submit" class="btn blue pull-right">
			Submit <i class="m-icon-swapright m-icon-white"></i>
			</button>
		</div>
	</form>
	<!-- END FORGOT PASSWORD FORM -->
</div>
<!-- END LOGIN -->
<!-- BEGIN COPYRIGHT -->
<div class="copyright">
	 2015 &copy; Open Baraza
</div>
<!-- END COPYRIGHT -->
<!-- BEGIN JAVASCRIPTS(Load javascripts at bottom, this will reduce page load time) -->
<!-- BEGIN CORE PLUGINS -->
<!--[if lt IE 9]>
<script src="${contextPath}/assets/global/plugins/respond.min.js"></script>
<script src="${contextPath}/assets/global/plugins/excanvas.min.js"></script> 
<![endif]-->
<script src="${contextPath}/assets/global/plugins/jquery.min.js" type="text/javascript"></script>
<script src="${contextPath}/assets/global/plugins/jquery-migrate.min.js" type="text/javascript"></script>
<script src="${contextPath}/assets/global/plugins/bootstrap/js/bootstrap.min.js" type="text/javascript"></script>
<script src="${contextPath}/assets/global/plugins/jquery.blockui.min.js" type="text/javascript"></script>
<script src="${contextPath}/assets/global/plugins/uniform/jquery.uniform.min.js" type="text/javascript"></script>
<script src="${contextPath}/assets/global/plugins/jquery.cokie.min.js" type="text/javascript"></script>
<!-- END CORE PLUGINS -->
<!-- BEGIN PAGE LEVEL PLUGINS -->
<script src="${contextPath}/assets/global/plugins/jquery-validation/js/jquery.validate.min.js" type="text/javascript"></script>
<script src="${contextPath}/assets/global/plugins/backstretch/jquery.backstretch.min.js" type="text/javascript"></script>
<script type="text/javascript" src="${contextPath}/assets/global/plugins/select2/select2.min.js"></script>
<!-- END PAGE LEVEL PLUGINS -->
<!-- BEGIN PAGE LEVEL SCRIPTS -->
<script src="${contextPath}/assets/global/scripts/metronic.js" type="text/javascript"></script>


<script src="${contextPath}/assets/admin/pages/scripts/login-soft.js" type="text/javascript"></script>
<!-- END PAGE LEVEL SCRIPTS -->
<script>
jQuery(document).ready(function() {     
  Metronic.init(); // init metronic core components
  Metronic.setAssetsPath('assets/'); // Set the assets folder path

  Login.init();
       // init background slide images
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
