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

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<%-- <%@ include file="resources/include/init.jsp" %> --%>


<style type="text/css" media="print">

<%--
@media print {

.fillout {
    width: 300pt;
    background-color: #ffffff;
    border: solid #000;
    border-width: 0 0 1px 0;
    }

input, textarea {
    border: 0px none;
    font-family: monospace;
    overflow: visible;
    width: 100%;
    }

p {
    font-family: fantasy;
    font-size: 20px;
    font-style: italic;
    font-weight: bold;
    }

} --%>
</style>

<style type="text/css" media="print">
<%--
select {
  display: none;
  }

.postselect {
  display: block;
  width: 300pt;
  height: 1em;
  border: none;
  border-bottom: 1px solid #000;
  }

 * {
  background-color: white !important;
  background-image: none !important;
  }

body {
  color : #000000;
  background : #ffffff;
  font-family : "Times New Roman", Times, serif;
  font-size : 12pt;
}
a {
  text-decoration : underline;
  color : #0000ff;
}
div#tab, #advertising, #other {
  display : none;
}  --%>
</style>

<style type="text/css" media="screen">

body {
    color : #000000;
    background : #ffffff;
    font-family : "Times New Roman", Times, serif;
    font-size : 12pt;
  }

fieldset{
  border: none;
  }

.k-tabstrip-items, .k-reset{
    display: none;
    }

input[type="text"] {
    width: 300pt;
    background-color: #ffffff;
    border: solid #000;
    border-width: 0 0 1px 0;
    font-family : "Times New Roman", Times, serif;
    font-size : 12pt;
    }

input[type="submit"] {
    display: none;
    }

<%-- td [text="DELETE"]{
    visibility: hidden;
    } --%>

select {
    display: none:
    }

input[type="button"] {
    display: none;
    }

</style>

<body>


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



  <label for="fname">First Name</label>
  <input class="fillout" name="fname" type="text" id="fname" />

  <label for="bitem">Breakfast Item</label>
  <select name="bitem" size="1">
      <option selected="selected">Select</option>
      <option>Milk</option>
      <option>Eggs</option>
      <option>Orange Juice</option>
      <option>Newspaper</option>
  </select>
  <span class="postselect">  </span>

</body>
</html>
