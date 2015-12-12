/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import org.apache.poi.poifs.filesystem.*;
import org.apache.poi.hssf.usermodel.*;

import java.util.logging.Logger;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.text.SimpleDateFormat;
import java.text.ParseException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.io.File;
import java.io.InputStream;
import java.io.IOException;
import java.io.PrintWriter;

import java.sql.SQLException;

import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.utils.BNumberFormat;
import org.baraza.utils.BCipher;

public class BForms {
	Logger log = Logger.getLogger(BForms.class.getName());
	Map<String, String> answers;
	Map<String, String> subanswers;
	String fhead, ffoot;

	BDB db = null;
	String access_text = null;

	public BForms(String dbconfig) {
		db = new BDB(dbconfig);
	}

	public BForms(String dbconfig, String at) {
	    db = new BDB(dbconfig);
	    access_text = at;
	}

	public String getForm(String entryformid, Map<String, String[]> sParams) {

		String mystr = "";

		answers = new HashMap<String, String>();
		subanswers = new HashMap<String, String>();

		Map<String, String[]> params = new HashMap<String, String[]>(sParams);

		String action = getParameter(params, "action");
		String approveStatus = "Draft";
		String entityid = null;
		String formid = null;

		if(action == null) action = "ENTRYFORM";

		if(action.equals("ENTRYFORM")) {
			String[] actionArray = {action};
			params.put("action", actionArray);
			if(entryformid == null) {
				entryformid = getParameter(params, "actionvalue");
			} else {
				String[] actionValueArray = {entryformid};
				params.put("actionvalue", actionValueArray);
			}
			Map<String, String> formRS = db.readFields("form_id, entity_id, approve_status", "entry_forms WHERE entry_form_id = " + entryformid);
			formid = formRS.get("form_id");
			entityid = formRS.get("entity_id");
			approveStatus = formRS.get("approve_status");
		} else if(action.equals("FORM")) {
			formid = getParameter(params, "actionvalue");
		}

		String update = getParameter(params, "update");
		String submit = getParameter(params, "submit");
		String disabled = getParameter(params, "disabled");
		String nosave = getParameter(params, "nosave");
		String hidehead = getParameter(params, "hidehead");
		String upload = getParameter(params, "upload");

		if(!"Draft".equals(approveStatus)) nosave = "true";

		// Core data read and process
		String fname = getFormType(formid);						// Read the form type defination
		if(update != null) saveForm(entryformid, params);		// Save data if submit is present
		if(entryformid != null) readClientData(entryformid);	// Read the client database for values

		if ((entryformid != null) && (disabled == null)) {
		    mystr+= "<div class='portlet-body form'>";
			mystr += "<form id='baraza' class='form-horizontal' name='baraza' method='post' action='form.jsp'>\n";
			mystr += "<input type='hidden' name='action' value='ENTRYFORM'/>\n";
			mystr += "<input type='hidden' name='actionvalue' value='" + entryformid + "'/>";
			mystr += "</div>\n";
		}

		if(!"Draft".equals(approveStatus)) mystr += "<fieldset><label>FORM SUBMITTED AND CANNOT BE EDITED</label></fieldset>\n";
        mystr +="<div class='navbar navbar-fixed-top'>";
		mystr += "<fieldset>\n";
		mystr += "<label>" + fname + "</label>\n";
		mystr += "</fieldset>";
		mystr += "</div>\n";

		if(hidehead == null) 
		mystr += fhead;

 		if(submit != null) mystr += "<section>" + submitForm(formid, entryformid) + "</section>\n";

		mystr += "<fieldset>";
		mystr += printForm(formid, disabled, update, true);
		mystr += "</fieldset>";

		if ((entryformid != null) && (disabled == null)) {
			mystr += "<hr>\n";
			if(nosave == null) {
				mystr += "\n<section><input type='submit' name='update' value='Save' class='altProcessButtonFormat'/>";
				mystr += "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
				mystr += "<input type='submit' name='submit' value='Complete and Exit' class='altProcessButtonFormat'/>";
				mystr += "</section>\n";
			}

			String fileStr = printFileUpload(formid);
			if((nosave == null) && (!fileStr.equals(""))) {
				mystr += "<form id='barazafile' name='barazafile' enctype='multipart/form-data' method='post' action='form.jsp'>\n";
				mystr += "<input type='hidden' name='action' value='ENTRYFORM'/>\n";
				mystr += "<input type='hidden' name='actionvalue' value='" + entryformid + "'/>\n";
				mystr += fileStr;
				mystr += "<section>Click <input type='submit' name='upload' value='Here'> to upload the files</section>\n";
				mystr += "</form>\n";
			}
		}
		mystr += "</form>\n";

		if(hidehead == null) mystr += ffoot;

		return mystr;
	}

	public String getParameter(Map<String, String[]> params, String paramName) {
		String paramValue = null;
		if(params.get(paramName) != null) paramValue = params.get(paramName)[0];
		return paramValue;
	}

	public String getFormType(String formid) {
		fhead = "";
		ffoot = "";
		String mystr = "";

		String mysql = "SELECT form_header, form_footer, form_name, form_number ";
		mysql += "FROM forms WHERE form_id = " + formid;
		BQuery rs = new BQuery(db, mysql);
		if(rs.moveNext()) {
			fhead = rs.getString("form_header");
			ffoot = rs.getString("form_footer");
			mystr = rs.getString("form_number") + " : " + rs.getString("form_name");
		}
		rs.close();

		if(fhead == null) fhead = "";
		else fhead = "<section>\n" + fhead + "</section>\n";

		if(ffoot == null) ffoot = "";
		else ffoot = "<section>\n" + ffoot + "</section>\n";

		return mystr;
	}

	public void readClientData(String entryformid) {
		answers.clear();	// clear the answer block
		subanswers.clear();	// clear the sub answer block

		String mysql = "SELECT entity_id, form_id, approve_status, answer, sub_answer ";
		mysql += " FROM entry_forms WHERE entry_form_id = " + entryformid;
		BQuery rs = new BQuery(db, mysql);
		if (rs.moveNext()) {
			BElement xmlans = getXMLNode(rs.getString("answer"));
			BElement xmlsans = getXMLNode(rs.getString("sub_answer"));
			BNumberFormat bnf = new BNumberFormat();

			if(xmlans != null) {
				for(BElement el : xmlans.getElements())
					answers.put(el.getName(), el.getValue());
			}
			if(xmlsans != null) {
				for(BElement el : xmlsans.getElements())
					subanswers.put(el.getName(), el.getValue());
			}
		}
		rs.close();
	}

	public BElement getXMLNode(String xmlStr) {
		//log.info("getting XML NODE for " + xmlStr);
		BElement node = null;
		if(xmlStr != null) {
			BXML xml = new BXML(xmlStr, true);
			if(xml.getDocument() == null)  log.severe("XML loading file error");
			else node = xml.getRoot();
		}
		return node;
	}

	public String getAnswer(String fieldid) {
		String answer = answers.get("F" + fieldid);

		if(answer == null) {
			answer = "";
		} else if(answer.trim().equals("")) {
			answer = "";
		} else {
			answer = answer.replaceAll("&", "&amp;").replaceAll("\"", "&quot;");
			answer = " value=\"" + answer + "\" ";
		}

		return answer;
	}

	public String getAnswer(String subfieldid, int answerline) {
		String answer = null;
		String qst = "SF:" + subfieldid + ":" + Integer.toString(answerline);
		answer = subanswers.get(qst);

		if(answer == null) {
			answer = "";
		} else if(answer.trim().equals("")) {
			answer = "";
		} else {
			answer = answer.replaceAll("&", "&amp;").replaceAll("\"", "&quot;");
			answer = " value=\"" + answer + "\" ";
		}

		return answer;
	}

	//new printForm() method based on whitelable Tableless
	public String printForm(String formid, String disabled, String process, boolean allowTabs) {

		String myhtml = "";

		int fieldOrder = 0;
		int shareLine = 0;
		int sl = -1;
		int cnt_title = 0;
		int size = 0;
		int table_count = 0;

		String label = "";
		String input = "";
		String fieldType = "TEXTFIELD";
		String fieldclass = "";
		String question = "";
		String details = "";
		String label_position = "";

		if(disabled == null) disabled = "";
		else disabled = " disabled=\"true\" ";

		boolean isTabs = false;
		String tab = "";
		String tab_head = "";
		String tab_body = "";

		String mysql = "SELECT * FROM fields WHERE form_id = " + formid;
		mysql += " ORDER BY field_order, field_id;";
		BQuery rs = new BQuery(db, mysql);

		while(rs.moveNext()) {
			fieldOrder = rs.getInt("field_order");
			shareLine = rs.getInt("share_line");

			fieldType = "TEXTFIELD";
			if(rs.getString("field_type") != null) fieldType = rs.getString("field_type");

			fieldclass = "";
			if(rs.getString("field_class") != null) fieldclass = " class='" + rs.getString("field_class") + "' ";

			question = rs.getString("question");
			if(rs.getString("question") == null) question = "";

			details = rs.getString("details");
			if(rs.getString("details") == null) details = "";

			label_position = rs.getString("label_position");
			if(rs.getString("label_position") == null) label_position = "L";

			size = 10;
			if(rs.getString("field_size") == null) size = rs.getInt("field_size");

			if(rs.getBoolean("field_bold")) question = "<b>" + question + "</b>";
			if(rs.getBoolean("field_italics")) question = "<i>" + question + "</i>";

			//TAB HEADER PROCESSING
			if(rs.getString("tab") != null){
				//if its the first one..
				if(tab.equals("")){
					tab_head = "<fieldset><div id=\"tab\" class=\"tabstrip k-widget k-header k-tabstrip\">";
					tab_head += "<ul class=\"k-tabstrip-items k-reset\">";
					tab_head += "<li class=\"k-item k-state-default k-first k-tab-on-top k-state-active\"><a classx=\"k-link\" hrefx=\"#" + rs.getString("tab").replace(" ","_") + "\">" + rs.getString("tab") + "</a></li>";	//title
					tab_body = "<div class=\"k-content k-state-active\" id=\"" +rs.getString("tab").replace(" ","_") + "\">";
				} else if(!tab.equals("") && !tab.equals(rs.getString("tab"))) {
					//log.info("Tab has changed from " + tab + " to " + rs.getString("tab"));
					tab_head += "<li class=\"k-item k-state-default\"><a classx=\"k-link\" hrefx=\"#" + rs.getString("tab").replace(" ","_") + "\">" + rs.getString("tab") + "</a></li>";	//another tab title
					tab_body += "</div><div class=\"k-content\" id=\"" +rs.getString("tab").replace(" ","_") + "\">";
				} else if(tab.equals(rs.getString("tab"))){
					//log.info("Tab continues...." + tab);
				}
			    tab = rs.getString("tab");
			    isTabs = true;
			} else if(rs.getString("tab") == null && !tab.equals("")) {		//does not contain tab but the immediate previous had a tab
			    log.info("Last Item in tab");
			    tab_head += "</ul>";
			    tab_body += "</div></div>";
			    tab = "";

			    myhtml += tab_head;
			    myhtml += tab_body;

			    isTabs = false;
			}

			label ="<label for='F" + rs.getString("field_id") +  "' class='control-label col-md-3'> " + question + "</label>"; 
           
			if(fieldType.equals("TEXTFIELD")) {
			    input="<div class='col-md-9'>";
				input = "<input " + disabled + " type='text' ";
				input += " name='F" + rs.getString("field_id") +  "'";
				input += " id ='F" + rs.getString("field_id") +  "'";
				input += " class ='form-control'";
				input += getAnswer(rs.getString("field_id"));
				input += " placeholder=\"" + details +"\"";
				input += " class='placeholder fillout' />";
				input+="</div>";
			} else if(fieldType.equals("DATE")) {
			    input="<div class='col-md-9'>";
			    input = "<input " + disabled + " type='text' ";
			    input += " name='F" + rs.getString("field_id") +  "'";
			    input += " id ='F" + rs.getString("field_id") +  "'";
				input += getAnswer(rs.getString("field_id"));
			    input += " class='datepicker' />";
			    input+="</div>";
			} else if(fieldType.equals("TIME")) {
			    input="<div class='col-md-9'>";
				input = "<input " + disabled + " type='text' ";
				input += " name='F" + rs.getString("field_id") +  "'";
				input += " id ='F" + rs.getString("field_id") +  "'";
				input += getAnswer(rs.getString("field_id"));
				input += " class='timepicker' />";
				input+="</div>";
			} else if(fieldType.equals("LIST")) {
			    input="<div class='col-md-9'>";
				input = "<select class='form-control' ";
				input += " name='F" + rs.getString("field_id") +  "'";
				input += " id='F" + rs.getString("field_id") +  "'";
				input+="</div>";
				input += ">\n";

				String lookups = rs.getString("field_lookup");
				String listVal = answers.get("F" + rs.getString("field_id"));
				if(listVal == null) listVal = "";
				else listVal = listVal.replace("\"", "").trim();

				if(lookups != null) {
					String[] lookup = lookups.split("#");
					for(String lps : lookup) {
						if(lps.compareToIgnoreCase(listVal)==0)
							input += "<option selected='selected'>" + lps + "</option>\n";
						else
							input += "<option>" + lps + "</option>\n";
					}
				}

				input += "</select>";
				//input += "<span " + " id='list" + rs.getString("field_id") +  "' " + getAnswer(rs.getString("field_id")) + " class='noscreen'>" + listVal + "</span>";
			} else if(fieldType.equals("SELECT")) {
			    input="<div class='col-md-9'>";
				input = "<select class='form-control' ";
				input += " name='F" + rs.getString("field_id") + "'";
				input += " id='F" + rs.getString("field_id") + "'";
				input+="</div>";
				input += ">\n";

				String lookups = rs.getString("field_lookup");
				String selectVal = answers.get("F" + rs.getString("field_id"));
				if(selectVal == null) selectVal = "";
				else selectVal = selectVal.replace("\"","").trim();
				String spanVal = "";

				if(lookups != null) {
					BQuery lprs = new BQuery(db, lookups);
					int cols = lprs.getColnum();

					while(lprs.moveNext()) {
						if(cols == 1){
							if(lprs.readField(1).trim().compareToIgnoreCase(selectVal)==0) {
								spanVal = lprs.readField(1);
								input += "<option value='" + lprs.readField(1) + "' selected='selected'>" + lprs.readField(1) + "</option>\n";
							} else {
								input += "<option value='" + lprs.readField(1) + "'>" + lprs.readField(1) + "</option>\n";
							}
						} else {
							if(lprs.readField(1).trim().compareToIgnoreCase(selectVal)==0) {
								spanVal = lprs.readField(2);
								input += "<option value='" + lprs.readField(1) + "' selected='selected'>" + lprs.readField(2) + "</option>\n";
							} else {
								input += "<option value='" + lprs.readField(1) + "'>" + lprs.readField(2) + "</option>\n";
							}
						}
					}
					lprs.close();
				}
				input += "</select>";
				//input += "<span " + " id='select" + rs.getString("field_id") +  "' " + getAnswer(rs.getString("field_id")) + " class='noscreen'> " + spanVal + "</span>";
			} else if(fieldType.equals("TITLE")) {
				cnt_title ++;
				input="<div class='col-md-6'>";
				input="<div class='col-md-9'>";
				input = "";
				input+="</div>";
				input+="</div>";

				//myhtml += "\n<fieldset><label class='control-label col-md-3'><strong>"+ "<div class='col-md-6'>" + question +"</div>" + "</strong></label></fieldset>";
			} else if(fieldType.equals("SUBGRID")) {
			   input="<div class='col-md-9'>";
				input = "";
				input+="</div>";
				myhtml += printSubForm(rs.getString("field_id"), disabled);
			} else if(fieldType.equals("TABLE")) {
			    input="<div class='navbar navbar-fixed-top'>";
				input = "";
				//input+="</div>";
			    table_count ++;
			    myhtml += printSubTable(rs.getString("field_id"), disabled, question, table_count);
			}

			// Label position L = left, T = Top, B = Bottom, R = Left
			if(input.equals(""))
			
			input = "";
			else if(label_position.equals("L")) input ="<div class='portlet-body form'>"+ "<div class='col-md-6'>"+ question + " "+"<div class='col-md-9'>" + input + "\n" +"</div>" + "</div>" + "</div>";
			else if(label_position.equals("T"))	input ="<div class='portlet-body form'>"+"<div class='row'>"+"<div class='col-md-6'>"+ "<label class='control-label col-md-3'>" + question +"</label>" + "<br>" + "<div class='col-md-9'>" + input +"</div>"+ "</div>"+ "</div>" + "</div>\n";
			else if(label_position.equals("B"))	input ="<div class='portlet-body form'>"+"<div class='col-md-6'>"+"<div class='col-md-9'>" + input +"</div>" + "<br>" + "<label class='control-label col-md-3'>" + question +"</label>"+ "</div>" + "</div>\n";
			else if(label_position.equals("R"))	input = "<div class='portlet-body form'>"+"<div class='row'>"+ "<div class='col-md-6'>" +"<div class='col-md-9'>"+ input +"</div>" + " " + question + "</div>" +"</div>" + "\n";

			//SHARELINE/SECTION PROCESSING
			if(input.equals("")) {
				input = "";
			} else if (fieldOrder == shareLine) {
				if(isTabs == false){
					if(sl == -1) myhtml += "<section>" + input;		// if coming from an unshared line ..we start a section
					else myhtml += "</section><section>" + input;	// otherwise we close first b4 starting a new section
				} else {
					tab_body += input;
				}
			    sl = shareLine;
			} else if (sl == shareLine ) {		//if still on the shared line.. we continue
				if(isTabs == false){
					myhtml += input;
				} else {
					tab_body += input;
				}
			} else if(shareLine == 0 ) {		//if no line to be shared
				if(isTabs == false) {
					if(sl == -1) myhtml += "<section>" + input + "</section>\n";
					else myhtml += "</section><section>" + input + "</section>\n";
				} else {
					tab_body += "<section>" + input + "</section>";
				}
				sl = -1;
			}
		}

		if(isTabs) myhtml += "</fieldset>\n";

		rs.close();

		return myhtml;
	}

	public String printSubTable(String fieldid, String disabled, String caption, int num) {
		String myhtml = "";

		String mysql = "SELECT sub_field_id, sub_field_type, sub_field_size, sub_field_lookup, question ";
		mysql += " FROM vw_sub_fields WHERE field_id = " + fieldid;
		mysql += " ORDER BY sub_field_order";
		BQuery rs = new BQuery(db, mysql);

		String mytitle = "";
		String titleshare = "";
		String sharetitle = "";

		Map<String, String> subFields = new HashMap<String, String>();
		Map<String, String> subFieldLookups = new HashMap<String, String>();
		Map<String, String> subFieldSize = new HashMap<String, String>();
		List<String> subFieldOrder = new ArrayList<String>();

		String filltb = "";			// declares an array of String responce
		String tableRows = "";
		String ans = "";
		String sub_field_type = "TEXTFIELD";
		String sub_field_size = "";

		while(rs.moveNext()) {
			subFieldOrder.add(rs.getString("sub_field_id"));
			subFields.put(rs.getString("sub_field_id"), rs.getString("sub_field_type"));
			subFieldSize.put(rs.getString("sub_field_id"), rs.getString("sub_field_size"));
			subFieldLookups.put(rs.getString("sub_field_id"), rs.getString("sub_field_lookup"));

			mytitle += "<td>" + rs.getString("question") + "</td>";
		}

		int j = 1;
		boolean printRow = true;

		while(printRow) {
			filltb = "<tr>";
			boolean hasData = false;

			//search:
			for(String subFieldID : subFieldOrder) {
				ans = getAnswer(subFieldID, j);
				String answer = subanswers.get("SF:" + subFieldID + ":" + Integer.toString(j));

				if(answer == null) answer = "";
				else hasData = true;

				sub_field_type = subFields.get(subFieldID);
				sub_field_size = subFieldSize.get(subFieldID);

				if(sub_field_type.equals("TEXTFIELD")) {
					filltb += "<td><input" + disabled + " class='mytableinput' type='text' size='25'";
					filltb += " style='width:" + sub_field_size + "0px' ";
					filltb += " id='SF:" + subFieldID + "'";
					filltb += " name='SF:" + subFieldID + "'";
					filltb += ans + "/></td>\n";
				} else if(sub_field_type.equals("LIST")) {
					filltb += "<td><select classx='formcombobox'";
					filltb += " id='SF:" + subFieldID + "'";
					filltb += " name='SF:" + subFieldID + "'";
					filltb += ">\n";
					String lookups = subFieldLookups.get(subFieldID);
					if(lookups != null) {
						String[] lookup = lookups.split("#");
						for(String lps : lookup) {
							if(lps.equals(answer)) filltb += "<option selected='selected'>" + lps + "</option>\n";
							else filltb += "<option>" + lps + "</option>\n";
						}
					}
					filltb += "</select></td>\n";
				} else if(sub_field_type.equals("SELECT")) {
					filltb += "<td><select classx='formcombobox' ";
					filltb += " id='SF:" + subFieldID + "'";
					filltb += " name='SF:" + subFieldID + "'";
					filltb += ">\n";
					String lookups = subFieldLookups.get(subFieldID);
					String spn = "";
					if(lookups != null) {
						BQuery lprs = new BQuery(db, lookups);
						int cols = lprs.getColnum();
						while(lprs.moveNext()) {
							if(cols == 1){
								if(lprs.readField(1).equals(answer)) {
									spn = lprs.readField(1);
									filltb += "<option value='" + lprs.readField(1) + "' selected='selected'>" + lprs.readField(1) + "</option>\n";
								} else {
									filltb += "<option value='" + lprs.readField(1) + "'>" + lprs.readField(1) + "</option>\n";
								}
							} else {
								if(lprs.readField(1).equals(answer)) {
									spn = lprs.readField(2);
									filltb += "<option value='" + lprs.readField(1) + "' selected='selected'>" + lprs.readField(2) + "</option>\n";
								} else {
									filltb += "<option value='" + lprs.readField(1) + "'>" + lprs.readField(2) + "</option>\n";
								}
							}
						}
						lprs.close();
					}
					filltb += "</select>";
					filltb += "<span " + " id='tableselect" + subFieldID +  "' " + " class='noscreen'> " + spn + "</span></td>\n";
				}
			}

			if(hasData)
				filltb += "<td><input type='button' class='deleteThisRow' name='" + num + "' value='Delete'/></td>";
			filltb += "</tr>\n";

			if(hasData) tableRows += filltb;
			else printRow = false;

			j++;
		}

		if(j == 2) tableRows += filltb;

		myhtml += "<fieldset>\n";
		myhtml += "<div class='subTable" + num + " g8' id='subTable" + num + "'>\n";
		myhtml += "<table class='innerTable'>\n";
		myhtml += "<tr>" + mytitle + "<td></td></tr>\n";
		myhtml += tableRows;

		myhtml += "</table>\n";
		myhtml += "<input type='button' class='btnAddMore' value='Add Row' name='" + num + "'/>\n";
		myhtml += "</div>\n";
		myhtml += "</fieldset>";

		rs.close();

		return myhtml;
	}

	public String printSubForm(String fieldid, String disabled) {
		String myhtml = "";

		String mysql = "SELECT * FROM vw_sub_fields WHERE field_id = " + fieldid;
		mysql += " ORDER BY sub_field_order";
		BQuery rs = new BQuery(db, mysql);

		String mytitle = "";
		String titleshare = "";
		String sharetitle = "";

		Map<String, String> subFields = new HashMap<String, String>();
		Map<String, String> subFieldLookups = new HashMap<String, String>();
		List<String> subFieldOrder = new ArrayList<String>();

		while(rs.moveNext()) {
			if (rs.getString("sub_title_share") != null) {
				if(!sharetitle.equals(rs.getString("sub_title_share")))
					titleshare += "<td colspan=" + rs.getString("sub_col_spans") + ">" + rs.getString("sub_title_share") + "</td>";
				mytitle += "<td>" + rs.getString("question") + "</td>";
				sharetitle = rs.getString("sub_title_share");
			} else {
				titleshare += "<td rowspan=\"2\">" + rs.getString("question") + "</td>";
			}

			subFieldOrder.add(rs.getString("sub_field_id"));
			subFields.put(rs.getString("sub_field_id"), rs.getString("sub_field_type"));
			subFieldLookups.put(rs.getString("sub_field_id"), rs.getString("sub_field_lookup"));
		}

		String filltb = "";			// declares an array of String responce
		String ans = "";
		String sub_field_type;
		int j = 1;
		boolean printRow = true;

		while(printRow) {
			filltb += "<tr>";
			boolean hasData = false;
			for(String subFieldID : subFieldOrder) {
				ans = getAnswer(subFieldID, j);
				if(!ans.equals("")) hasData = true;

				sub_field_type = subFields.get(subFieldID);
				log.info("SUB FIELD TYPE = " + sub_field_type);

				if(sub_field_type.equals("TEXTFIELD")){
					log.info("BUILDING textfield");
					filltb += "<td><input" + disabled + " class=\"mytableinput\" type=\"text\" size=\"25\" ";
					filltb += "name=\"SF:" + subFieldID + ":" + Integer.toString(j) + "\"";
					filltb += ans + "/></td>";
				} else if(sub_field_type.equals("TITLE")){
					log.info("BUILDING title");
					filltb = "<td></td>";
				} else {
					log.info("UNKNOWN TYPE");
					filltb += "<td><input" + disabled + " class=\"mytableinput\" type=\"text\" size=\"25\" ";
					filltb += "name=\"SF:" + subFieldID + ":" + Integer.toString(j) + "\"";
					filltb += ans + "/></td>";
				}
			}
			filltb += "</tr>\n";
			if(!hasData) printRow = false;
			j++;
		}

		myhtml = "<tr><td><table width=\"790\" border=\"5\">";
		myhtml += "<tr>" + titleshare + "</tr>\n";
		myhtml += "<tr>" + mytitle + "</tr>\n";
		myhtml += filltb;
		myhtml += "</table></td></tr>\n";
		rs.close();

		return myhtml;
	}

	public String printFileUpload(String formid) {
		String responce = "";
		String mysql = "SELECT * FROM fields WHERE (field_type = 'SUBGRID') AND (form_id = " + formid + ") ";
		mysql += "ORDER BY field_order, field_id";

		BQuery rs = new BQuery(db, mysql);
		while(rs.moveNext()) {
			String q = " the file ";
			if(rs.getString("question") != null)
			    q = rs.getString("question");
			responce += "<tr><td>Upload: " + q + "<input type='file' name='" + rs.getString("field_id") + "'></td></tr>\n";
		}
		return responce;
	}

	public void saveForm(String entryformid, Map<String, String[]> webparams) {
		Map<String, String[]> params = new HashMap<String, String[]>(webparams);

		params.remove("action");
		params.remove("actionvalue");
		params.remove("update");
		params.remove("submit");
		params.remove("hidehead");
		params.remove("blankpage");

		String ans = "";

		readClientData(entryformid);				// read answers put in

		String mkey = "";
		String formXML = "<FORM>";
		String subFormXML = "<SUBFORM>";
		String subTableXML = "<TABLE>";

		for (String key : params.keySet()) {
			ans = params.get(key)[0];
			ans = ans.replace("&", "and");
			ans = ans.replace("'", "\\\\'").replaceAll("<", "&lt;");
			//log.info("FOUND param key = " + key + " ans = " + ans);

			if(key.startsWith("F")) {
				formXML += "<" + key + ">" + ans + "</" + key + ">";
			} else if(key.startsWith("SF")) {
				Integer i = 1;
				for(String subans : params.get(key)) {
					mkey = key + ":" + i.toString();
					subFormXML += "<" + mkey + ">" + subans + "</" + mkey + ">";
					i++;
				}
			} else if(key.startsWith("T")) {
				subTableXML += "<" + key + ">" + ans + "</" + key + ">";
			}
		}

		formXML += "</FORM>";
		subFormXML += "</SUBFORM>";
		subTableXML += "</TABLE>";

		//log.info("formXML = " + formXML);
		log.info("subFormXML = " + subFormXML);

		String mysql = "UPDATE entry_forms SET answer = '" + formXML + "', ";
		mysql += "sub_answer = '" + subFormXML + "' ";
		mysql += "WHERE entry_form_id = " + entryformid;
		db.executeQuery(mysql);
	}

	public String submitForm(String formid, String entryformid) {
		String myhtml = "<table width='790' border='1'>";
		String mysql = "SELECT * FROM fields WHERE (form_id = " + formid;
		mysql += ") AND (manditory = '1') ";
		mysql += "ORDER BY field_order, field_id;";
		BQuery rs = new BQuery(db, mysql);

		String ans = "";
		boolean verified = true;
		while(rs.moveNext()) {
			String fieldType = "TEXTFIELD";
			if(rs.getString("field_type") != null) fieldType = rs.getString("field_type");

			String question = rs.getString("question");
			if(rs.getString("question") == null) question = "";

			if(fieldType.equals("TEXTFIELD") || fieldType.equals("DATE") || fieldType.equals("TIME")) {
				ans = getAnswer(rs.getString("field_id"));
				if(ans.trim().equals("")) {
					verified = false;
					myhtml += "<tr><td><div style='color:#FF0000; font-weight:bold;'>* You need to answer : " + question + "</div></td></tr>";
				}
			}
		}
		rs.close();

		if(verified) {
			if(saveTable(formid, entryformid) != null) {
				verified = false;
				myhtml += "<tr><td><b>You need to ensure you have made the selection properly</b></td></tr>";
			}
		}
		
		if(verified) {
			mysql = "UPDATE entry_forms SET approve_status = 'Completed', completion_date = now() WHERE (entry_form_id = ";
			mysql += entryformid + ")";
			db.executeQuery(mysql);
			myhtml += "<tr><td><b>The form has been submitted successfully</b></td></tr>";	
		}

		myhtml += "</table>\n";

		if(verified) myhtml += "<script>window.close();</script>\n";
		else myhtml = "<div style='color:#FF0000; font-weight:bold;'>\n" + myhtml + "\n</div>";

		return myhtml;
	}

	public String uploadFile(HttpServletRequest request) {
		String response = "";

		int MaxMemorySize = 2048576;
		File TempDirectory = new File("/opt/tomcat/temp/baraza.tmp");

		// Create a factory for disk-based file items
		DiskFileItemFactory factory = new DiskFileItemFactory(MaxMemorySize, TempDirectory);

		// Create a new file upload handler
		ServletFileUpload upload = new ServletFileUpload(factory);

		// Parse the request
		//List<FileItem> items = new ArrayList<FileItem>();
		List items;
		try {
			items = upload.parseRequest(request);
		} catch(FileUploadException ex) {
			log.severe("File upload exception");
			return "File Upload error, ensure you have a correct excel format 97 version.";
		}

		String entryformid = "";
		for(int i = 0; i < items.size(); i++) {
			FileItem item = (FileItem)items.get(i);
			if (item.isFormField()) {
				String name = item.getFieldName();
				String value = item.getString();
				if(name.equals("actionvalue")) entryformid = value;
				System.out.println(name + " = " + value);
			}
		}
		for(int i = 0; i < items.size(); i++) {
			FileItem item = (FileItem)items.get(i);
			if (!item.isFormField()) {
				String contentType = item.getContentType();
				String fieldName = item.getFieldName();
				String fileName = item.getName();
				long fs = item.getSize();
				long maxfs = MaxMemorySize;

				if(fs > maxfs) {
					response = "<div class=\"style33\">The file is too big<br/>";
					response += "maximum size allowed is " + String.valueOf(maxfs) + " bytes</div>";
				} else if (fs > 0) {
					getExcelData(fieldName, entryformid, item);
				}
				System.out.println(contentType + " : " + fieldName + " = " + fileName);
			}
		}

		return entryformid;
	}

	public void getExcelData(String fieldid, String entryformid, FileItem item) { // Get all rows.
		POIFSFileSystem fs = null;
		HSSFWorkbook wb = null;
		DirectoryEntry rootdir = null;
		List<String> sub_fields = new ArrayList<String>();

		String mysql = "SELECT sub_field_id FROM sub_fields WHERE field_id = " + fieldid;
		BQuery rs = new BQuery(db, mysql);
		while(rs.moveNext()) {
			sub_fields.add(rs.getString("sub_field_id"));
		}
		rs.close();

		try {
			fs = new POIFSFileSystem(item.getInputStream());
			rootdir = fs.getRoot();
			wb = new HSSFWorkbook(fs);
		} catch (IOException e) {
   			log.severe("an I/O error occurred, or the InputStream did not provide a compatible POIFS data structure");
			return;
		}

		HSSFSheet sheet = wb.getSheetAt(0);
		HSSFRow row = null;
		int i = 0;
		for(i = sheet.getFirstRowNum(); i <= sheet.getLastRowNum(); i++) {
			row = sheet.getRow(i);
			if(row!=null)  {
				mysql = "INSERT INTO entry_sub_fields(entry_form_id, sub_field_id, answer_line, answer) VALUES ";
				for (int j=0; j<sub_fields.size(); j++) {
					//mysql = "INSERT INTO entry_sub_fields(entry_form_id, sub_field_id, answer_line, answer) VALUES (";
					if(j != 0) mysql += ",";
					mysql += "\n(" + entryformid + ", " + sub_fields.get(j) + ", " + Integer.toString(i+1) + ", '";
					mysql += getCellValue(row, j) + "')";
				}

				//db.executeQuery(mysql);
			}
		}
	}

	public String getCellValue(HSSFRow row, int column) {
		String mystr = "";

		HSSFCell cell = row.getCell(column);
		if (cell == null) cell = row.createCell(column);
		if (cell.getCellType()==cell.CELL_TYPE_STRING) {
			if(cell.getStringCellValue()!=null)
				mystr += cell.getStringCellValue().trim();
		} else if (cell.getCellType()==cell.CELL_TYPE_NUMERIC) {
			mystr += cell.getNumericCellValue();
		}
		mystr = mystr.replaceAll("\"", "").replaceAll("'", "").trim();

		return mystr;
	}

	public String getFormField(String formid) {
		String ans = null;
		String mysql = "SELECT field_id, question FROM fields WHERE (field_type = 'SUBGRID')";
		mysql += " AND (form_id = " + formid + ")";
		BQuery rs = new BQuery(db, mysql);
		while(rs.moveNext()) {
			if(ans == null) ans = "";
			ans += "<option value='" + rs.readField(1) + "'>" + rs.readField(2) + "</option>\n";
		}
		rs.close();


		if(ans == null) ans = "";
		else ans = "<td>Field : <select name='reportfield'>" + ans + "</select></td>";

		return ans;
	}

	public String getFormReportSQL(String formid, String startDate, String endDate, String reportLevel) {
		String mysql = "SELECT vw_entry_forms.entry_form_id, vw_entry_forms.form_name, vw_entry_forms.entity_name, ";
		mysql += "vw_entry_forms.application_date, vw_entry_forms.completion_date, vw_entry_forms.narrative, ";
		mysql += "vw_entry_forms.action_date, vw_entry_forms.answer ";
		mysql += "FROM vw_entry_forms ";
		mysql += "WHERE (vw_entry_forms.approve_status='Approved') ";
		mysql += "AND (vw_entry_forms.form_id = " + formid + ")";
		startDate = getConvDate(startDate);
		if(startDate != null)
			mysql += " AND (vw_entry_forms.completion_date >= '" + startDate + "')";
		endDate = getConvDate(endDate);
		if(endDate != null)
			mysql += " AND (vw_entry_forms.completion_date <= '" + endDate + "')";

		return mysql;
	}


	public String getFormReport(String formid, String startDate, String endDate, String reportLevel, String reportField) {
		StringBuffer myhtml = new StringBuffer();
		List<String> lstq = new ArrayList<String>();
		String mysql = "";
		String ans;

		if(reportLevel == null) reportLevel = "Basic";
		if(reportLevel.equals("Sub Field")) {
			mysql = "SELECT sub_field_id, question FROM sub_fields WHERE (show = '1') AND (field_id = " + reportField + ")\n";
			mysql += "ORDER BY sub_field_order";
			BQuery fldrs = new BQuery(db, mysql);

			myhtml.append("<table cellpadding='0' cellspacing='0' border='0' class='display' id='thetable'>\n");
			myhtml.append("<thead><tr>\n");
			myhtml.append("<th>Client</th>");
			while(fldrs.moveNext()) {
				myhtml.append("<th>" + fldrs.getString("question") + "</th>");
				lstq.add(fldrs.getString("sub_field_id"));
			}
			myhtml.append("\n</tr></thead>\n");
			fldrs.close();

			myhtml.append("<tbody>\n");
			mysql = "SELECT entry_form_id, entity_name FROM vw_entry_forms WHERE form_id = " + formid;
			mysql += " AND (approve_status = 'Completed') ";
			startDate = getConvDate(startDate);
			if(startDate != null)
				mysql += " AND (completion_date >= '" + startDate + "')";
			endDate = getConvDate(endDate);
			if(endDate != null)
				mysql += " AND (completion_date <= '" + endDate + "')";
			mysql += " ORDER BY completion_date";
			BQuery rsa = new BQuery(db, mysql);

			while(rsa.moveNext()) {
				int i = 1;
				if(lstq.size() == 0) i = -1;

				while(i > 0) {
					boolean fd = true;
					for(String stq : lstq) {
						mysql = "SELECT entry_sub_fields.answer FROM entry_sub_fields INNER JOIN sub_fields ";
						mysql += "ON entry_sub_fields.sub_field_id = sub_fields.sub_field_id";
						mysql += " WHERE (sub_fields.field_id = " + reportField + ") ";
						mysql += " AND (entry_sub_fields.entry_form_id = " + rsa.getString("entry_form_id") + ") ";
						mysql += " AND (entry_sub_fields.sub_field_id = " + stq + ") ";
						mysql += " AND (entry_sub_fields.answer_line = " + Integer.toString(i) + ")";
						ans = db.executeFunction(mysql);

						if(ans == null) {i = -1; ans = "";}
						else {
							if(fd) {myhtml.append("<tr><td>" + rsa.getString("entity_name") + "</td>"); fd = false; }
							myhtml.append("<td>" + ans + "</td>");
						}
					}
					if(i > 0) {myhtml.append("</tr>\n"); i++;}
				}
			}
			myhtml.append("</tbody>\n");
			myhtml.append("</table>\n");
		} else {
			return getFormReport(formid, startDate, endDate, reportLevel);
		}

		return myhtml.toString();
	}

	public String getFormReport(String formid, String startDate, String endDate, String reportLevel) {
		StringBuffer myhtml = new StringBuffer();
		List<String> lstq = new ArrayList<String>();
		if(reportLevel == null) reportLevel = "Basic";

		String mysql = getFormReportSQL(formid, startDate, endDate, reportLevel);
		BQuery rs = new BQuery(db, mysql);
		int cols = rs.getColumnCount();
		int col = 0;
		String ans = "";

		myhtml.append("<table cellpadding='0' cellspacing='0' border='0' class='display' id='thetable'>\n");
		myhtml.append("<thead><tr>\n");
		for(col = 1; col < cols-1; col++) {
			myhtml.append("<th>" + rs.initCap(rs.getColumnName(col)) + "</th>");
		}

		if(reportLevel.equals("Detailed")) {
			mysql = "SELECT field_id, question";
			mysql += " FROM fields";
			mysql += " WHERE (show = '1') AND (field_type != 'TITLE') AND (field_type != 'SUBGRID') ";
			mysql += " AND (form_id = " + formid + ")";
			mysql += " ORDER BY field_order";
			BQuery fldrs = new BQuery(db, mysql);
			while(fldrs.moveNext()) {
				myhtml.append("<th>" + fldrs.getString("question") + "</th>");
				lstq.add(fldrs.getString("field_id"));
			}
			fldrs.close();
		}
		myhtml.append("</tr></thead>\n");

		myhtml.append("<tbody>\n");
		rs.beforeFirst();
		while(rs.moveNext()) {
			myhtml.append("<tr>");
			for(col = 1; col < cols; col++) {
				myhtml.append("<td>" + rs.getFormatField(col) + "</td>");
			}

			myhtml.append("</tr>\n");
		}
		myhtml.append("</tbody>\n");
		myhtml.append("</table>\n");

		rs.close();

		return myhtml.toString();
	}

	public void getReport(HttpServletRequest request, HttpServletResponse response) {
		String formid = request.getParameter("formid");
		String startDate = request.getParameter("startdate");
		String endDate = request.getParameter("enddate");
		String reportLevel = request.getParameter("reportlevel");
		String reportField = request.getParameter("reportfield");
		if(reportLevel == null) reportLevel = "Basic";

		List<String> lstq = new ArrayList<String>();
		StringBuffer csvhtml = new StringBuffer();
		String ans = "";
		String mysql = "";

		if(reportLevel.equals("Basic") || reportLevel.equals("Detailed")) {
			mysql = getFormReportSQL(formid, startDate, endDate, reportLevel);
			BQuery rs = new BQuery(db, mysql);
			int cols = rs.getColumnCount();
			int col = 0;

			csvhtml.append("Form ID");
			for(col = 1; col < cols; col++)
				csvhtml.append("," + rs.initCap(rs.getColumnName(col)));

			if(reportLevel.equals("Detailed")) {
				mysql = "SELECT field_id, question FROM fields";
				mysql += " WHERE (show = '1') AND (field_type = 'TEXTFIELD') ";
				mysql += " AND (form_id = " + formid + ")";
				mysql += " ORDER BY field_order";

				BQuery fldrs = new BQuery(db, mysql);
				while(fldrs.moveNext()) {
					String question = fldrs.getString("question");
					if(question != null) {
						if(question.indexOf(",") > 0) csvhtml.append(",\"" + question + "\"");
						else csvhtml.append("," + question);
						lstq.add(fldrs.getString("field_id"));
					}
				}
				fldrs.close();
			}
			csvhtml.append("\n");

			rs.beforeFirst();
			while(rs.moveNext()) {
				csvhtml.append(rs.getString("entry_form_id"));
				for(col = 1; col < cols-1; col++)
					csvhtml.append("," + rs.getFormatField(col));

				for(String fld : lstq) {
				}
				csvhtml.append("\n");
			}
			rs.close();
		} else if(reportLevel.equals("Sub Field")) {
			mysql = "SELECT sub_field_id, question FROM sub_fields WHERE (show = '1') AND (field_id = " + reportField + ")\n";
			mysql += "ORDER BY sub_field_order";
			BQuery fldrs = new BQuery(db, mysql);

			csvhtml.append("Form ID, Client");
			while(fldrs.moveNext()) {
				ans = fldrs.getString("question");
				csvhtml.append("," + csvFormat(fldrs.getString("question")));

				lstq.add(fldrs.getString("sub_field_id"));
			}
			csvhtml.append("\n");
			fldrs.close();

			mysql = "SELECT entry_form_id, entity_name FROM vw_entry_forms WHERE form_id = " + formid;
			mysql += " AND (approve_status = 'Completed') ";
			startDate = getConvDate(startDate);
			if(startDate != null)
				mysql += " AND (completion_date >= '" + startDate + "')";
			endDate = getConvDate(endDate);
			if(endDate != null)
				mysql += " AND (completion_date <= '" + endDate + "')";
			mysql += " ORDER BY completion_date";
			BQuery rsa = new BQuery(db, mysql);

			while(rsa.moveNext()) {
				int i = 1;

				while(i > 0) {
					boolean fd = true;
					for(String stq : lstq) {
						mysql = "SELECT entry_sub_fields.answer FROM entry_sub_fields INNER JOIN sub_fields ";
						mysql += "ON entry_sub_fields.sub_field_id = sub_fields.sub_field_id";
						mysql += " WHERE (sub_fields.field_id = " + reportField + ") ";
						mysql += " AND (entry_sub_fields.entry_form_id = " + rsa.getString("entry_form_id") + ") ";
						mysql += " AND (entry_sub_fields.sub_field_id = " + stq + ") ";
						mysql += " AND (entry_sub_fields.answer_line = " + Integer.toString(i) + ")";
						ans = db.executeFunction(mysql);

						if(ans == null) {i = -1; ans = "";}
						else {
							if(fd) {
								csvhtml.append(csvFormat(rsa.getString("entry_form_id")));
								csvhtml.append("," + csvFormat(rsa.getString("entity_name")));
								fd = false;
							}
							csvhtml.append("," + csvFormat(ans));
						}
					}
					if(i > 0) {csvhtml.append("\n"); i++;}
				}
			}
		}

		response.setContentType("text/x-csv");
		response.setHeader("Content-Disposition", "attachment; filename=report.csv");

		try {
			PrintWriter hpw = response.getWriter();
			hpw.println(csvhtml.toString());
			hpw.close();
		} catch (IOException ex) {
			log.severe("IO Error : " + ex);
		}
	}

	public String csvFormat(String lans) {
		String ans = "";
		if(lans != null) {
			if(lans.indexOf(",")>=0) ans = "\"" + lans + "\"";
			else ans = lans;
		}
		return ans;
	}

	public String getConvDate(String mydate) {
		String ans = null;
		if(mydate != null) {
			if(mydate.length()>7) {
				try {
				    SimpleDateFormat dp1 = new SimpleDateFormat("dd/MM/yyyy");
				    SimpleDateFormat dp2 = new SimpleDateFormat("yyyy-MM-dd");
				    ans = dp2.format(dp1.parse(mydate));
				    }
				catch(ParseException ex) {
				    log.severe("Date format error");
				    }
			}
		}

		return ans;
	}

	public String saveTable(String formid, String entryformid) {
		String dbErr = null;
		String mysql = "SELECT table_name FROM forms WHERE form_id = " + formid;
		String tableName = db.executeFunction(mysql);

		if(tableName != null) {
			mysql = "SELECT field_name, field_id, field_fnct FROM fields WHERE form_id = " + formid;
			mysql += " ORDER BY field_order, field_id;";
			BQuery rs = new BQuery(db, mysql);

			mysql = "INSERT INTO " + tableName + " (entry_form_id";
			String values = ") VALUES (" + entryformid;
			while(rs.moveNext()) {
				String fieldName = rs.getString("field_name");
				String fieldFnct = rs.getString("field_fnct");
				String ans = answers.get("F" + rs.getString("field_id"));
				String ansa = "'" + ans + "'";
				if(ans == null) { ansa = "null"; ans = ""; }

				if((fieldFnct != null) && (ans != null)) {
					ansa = fieldFnct.replace("#", ans);
				}

				if((fieldName != null) && (!ans.equals(""))) {
					mysql += ", " + fieldName;
					values += ", " + ansa;
				}
			}
			mysql +=   values + ")";
			dbErr = db.executeQuery(mysql);

			System.out.println("\n\nBASE 1010 : " + mysql);
		}

		return dbErr;
	}

	public void close() {
		if(db != null) db.close();
	}

}
