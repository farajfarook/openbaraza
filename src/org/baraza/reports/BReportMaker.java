/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.reports;

import org.baraza.xml.BElement;
import org.baraza.DB.BQuery;

public class BReportMaker {

	public String makeReport(String reportname, String mysql, BQuery query) {
		String myReport = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
		myReport += "<jasperReport xmlns=\"http://jasperreports.sourceforge.net/jasperreports\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://jasperreports.sourceforge.net/jasperreports http://jasperreports.sourceforge.net/xsd/jasperreport.xsd\" ";
		myReport += "name=\"" + reportname + "\" language=\"groovy\" pageWidth=\"595\" pageHeight=\"842\" whenNoDataType=\"BlankPage\" columnWidth=\"535\" leftMargin=\"20\" rightMargin=\"20\" topMargin=\"20\" bottomMargin=\"20\">\n";
		myReport += "	<property name=\"ireport.zoom\" value=\"1.0\"/>\n";
		myReport += "	<property name=\"ireport.x\" value=\"0\"/>\n";
		myReport += "	<property name=\"ireport.y\" value=\"0\"/>\n";
		myReport += "	<style name=\"Title\" fontName=\"Times New Roman\" fontSize=\"50\" isBold=\"true\" pdfFontName=\"Times-Bold\"/>\n";
		myReport += "	<style name=\"SubTitle\" forecolor=\"#736343\" fontName=\"Arial\" fontSize=\"18\"/>\n";
		myReport += "	<style name=\"Column header\" forecolor=\"#666666\" fontName=\"Arial\" fontSize=\"12\" isBold=\"true\"/>\n";
		myReport += "	<style name=\"Detail\" fontName=\"Arial\" fontSize=\"12\"/>\n";
		myReport += "	<style name=\"Row\" mode=\"Transparent\">\n";
		myReport += "		<conditionalStyle>\n";
		myReport += "			<conditionExpression><![CDATA[$V{REPORT_COUNT}%2 == 0]]></conditionExpression>\n";
		myReport += "			<style backcolor=\"#E6DAC3\"/>\n";
		myReport += "		</conditionalStyle>\n";
		myReport += "	</style>\n";
		myReport += "	<parameter name=\"filterid\" class=\"java.lang.String\">\n";
		myReport += "		<defaultValueExpression><![CDATA[\"1\"]]></defaultValueExpression>\n";
		myReport += "	</parameter>\n";
		myReport += "	<parameter name=\"orgid\" class=\"java.lang.String\">\n";
		myReport += "		<defaultValueExpression><![CDATA[\"0\"]]></defaultValueExpression>\n";
		myReport += "	</parameter>\n";
		myReport += "	<parameter name=\"orgwhere\" class=\"java.lang.String\">\n";
		myReport += "		<defaultValueExpression><![CDATA[\"\"]]></defaultValueExpression>\n";
		myReport += "	</parameter>\n";
		myReport += "	<parameter name=\"organd\" class=\"java.lang.String\">\n";
		myReport += "		<defaultValueExpression><![CDATA[\"\"]]></defaultValueExpression>\n";
		myReport += "	</parameter>\n";
		myReport += "	<queryString language=\"SQL\">\n";
		myReport += "		<![CDATA[" + mysql + "]]>\n";
		myReport += "	</queryString>\n";

		for(int i = 0; i < query.getColumnCount(); i++) {
			myReport += "	<field name=\"" + query.getFieldName(i);
			myReport += "\" class=\"" +  query.getColumnClass(i).toString().replace("class ", "") + "\"/>\n";
		}

		myReport += "	<background>\n";
		myReport += "		<band splitType=\"Stretch\"/>\n";
		myReport += "	</background>\n";
		myReport += "	<title>\n";
		myReport += "		<band height=\"71\" splitType=\"Stretch\">\n";
		myReport += "			<staticText>\n";
		myReport += "				<reportElement style=\"Title\" x=\"66\" y=\"0\" width=\"446\" height=\"62\"/>\n";
		myReport += "				<textElement verticalAlignment=\"Middle\">\n";
		myReport += "					<font fontName=\"Times New Roman\" size=\"24\" pdfFontName=\"Times-Roman\"/>\n";
		myReport += "				</textElement>\n";
		myReport += "				<text><![CDATA[" + query.initCap(reportname.replace("vw_", "")) + " Report]]></text>\n";
		myReport += "			</staticText>\n";
		myReport += "		</band>\n";
		myReport += "	</title>\n";
		myReport += "	<pageHeader>\n";
		myReport += "		<band splitType=\"Stretch\"/>\n";
		myReport += "	</pageHeader>\n";
		myReport += "	<columnHeader>\n";
		myReport += "		<band height=\"16\" splitType=\"Stretch\">\n";
		myReport += "			<line>\n";
		myReport += "				<reportElement positionType=\"FixRelativeToBottom\" x=\"0\" y=\"15\" width=\"555\" height=\"1\"/>\n";
		myReport += "				<graphicElement>\n";
		myReport += "					<pen lineWidth=\"0.5\" lineColor=\"#999999\"/>\n";
		myReport += "				</graphicElement>\n";
		myReport += "			</line>\n";

		int w = 525 / query.getColumnCount();
		int x = 0;
		for(int i = 0; i < query.getColumnCount(); i++) {
			x = 1 + (i * w);
			myReport += "			<staticText>\n";
			myReport += "				<reportElement style=\"Column header\" x=\"" + Integer.toString(x) + "\"";
			myReport += " y=\"0\" width=\"" + Integer.toString(w) + "\" height=\"15\" forecolor=\"#000000\"/>\n";
			myReport += "				<textElement>\n";
			myReport += "					<font fontName=\"Times New Roman\"/>\n";
			myReport += "				</textElement>\n";
			myReport += "				<text><![CDATA[" + query.initCap(query.getFieldName(i)) + "]]></text>\n";
			myReport += "			</staticText>\n";
		}

		myReport += "		</band>\n";
		myReport += "	</columnHeader>\n";
		myReport += "	<detail>\n";
		myReport += "		<band height=\"15\" splitType=\"Stretch\">\n";
		myReport += "			<frame>\n";
		myReport += "				<reportElement style=\"Row\" mode=\"Opaque\" x=\"0\" y=\"0\" width=\"555\" height=\"15\"/>\n";

		for(int i = 0; i < query.getColumnCount(); i++) {
			x = 1 + (i * w);
			myReport += "				<textField isStretchWithOverflow=\"true\" isBlankWhenNull=\"true\">\n";
			myReport += "					<reportElement style=\"Detail\" x=\"" + Integer.toString(x) + "\" y=\"0\"";
			myReport += " width=\"" + Integer.toString(w) + "\" height=\"15\"/>\n";
			myReport += "					<textElement>\n";
			myReport += "						<font fontName=\"Times New Roman\"/>\n";
			myReport += "					</textElement>\n";
			myReport += "					<textFieldExpression class=\"";
 			myReport +=  query.getColumnClass(i).toString().replace("class ", "").replace("java.sql.Date", "java.util.Date") + "\">";
			myReport += "<![CDATA[$F{" + query.getFieldName(i) + "}]]></textFieldExpression>\n";
			myReport += "				</textField>\n";
		}

		myReport += "			</frame>\n";
		myReport += "		</band>\n";
		myReport += "	</detail>\n";
		myReport += "	<columnFooter>\n";
		myReport += "		<band height=\"15\" splitType=\"Stretch\">\n";
		myReport += "			<line>\n";
		myReport += "				<reportElement positionType=\"FixRelativeToBottom\" x=\"0\" y=\"3\" width=\"555\" height=\"1\"/>\n";
		myReport += "				<graphicElement>\n";
		myReport += "					<pen lineWidth=\"0.5\" lineColor=\"#999999\"/>\n";
		myReport += "				</graphicElement>\n";
		myReport += "			</line>\n";
		myReport += "		</band>\n";
		myReport += "	</columnFooter>\n";
		myReport += "	<pageFooter>\n";
		myReport += "		<band height=\"25\" splitType=\"Stretch\">\n";
		myReport += "			<frame>\n";
		myReport += "				<reportElement mode=\"Opaque\" x=\"-21\" y=\"1\" width=\"597\" height=\"24\" forecolor=\"#D0B48E\" backcolor=\"#F2EBDF\"/>\n";
		myReport += "				<textField evaluationTime=\"Report\">\n";
		myReport += "					<reportElement style=\"Column header\" x=\"533\" y=\"0\" width=\"40\" height=\"20\" forecolor=\"#736343\"/>\n";
		myReport += "					<textElement verticalAlignment=\"Middle\">\n";
		myReport += "						<font fontName=\"Times New Roman\" size=\"10\" isBold=\"false\"/>\n";
		myReport += "					</textElement>\n";
		myReport += "					<textFieldExpression class=\"java.lang.String\"><![CDATA[\" \" + $V{PAGE_NUMBER}]]></textFieldExpression>\n";
		myReport += "				</textField>\n";
		myReport += "				<textField>\n";
		myReport += "					<reportElement style=\"Column header\" x=\"453\" y=\"0\" width=\"80\" height=\"20\" forecolor=\"#736343\"/>\n";
		myReport += "					<textElement textAlignment=\"Right\" verticalAlignment=\"Middle\">\n";
		myReport += "						<font fontName=\"Times New Roman\" size=\"10\" isBold=\"false\"/>\n";
		myReport += "					</textElement>\n";
		myReport += "					<textFieldExpression class=\"java.lang.String\"><![CDATA[\"Page \"+$V{PAGE_NUMBER}+\" of\"]]></textFieldExpression>\n";
		myReport += "				</textField>\n";
		myReport += "				<textField pattern=\"EEEEE, d MMMMM yyyy HH:mm:ss Z\">\n";
		myReport += "					<reportElement style=\"Column header\" x=\"22\" y=\"1\" width=\"197\" height=\"20\" forecolor=\"#736343\"/>\n";
		myReport += "					<textElement verticalAlignment=\"Middle\">\n";
		myReport += "						<font fontName=\"Times New Roman\" size=\"10\" isBold=\"false\"/>\n";
		myReport += "					</textElement>\n";
		myReport += "					<textFieldExpression class=\"java.util.Date\"><![CDATA[new java.util.Date()]]></textFieldExpression>\n";
		myReport += "				</textField>\n";
		myReport += "			</frame>\n";
		myReport += "		</band>\n";
		myReport += "	</pageFooter>\n";
		myReport += "	<summary>\n";
		myReport += "		<band splitType=\"Stretch\"/>\n";
		myReport += "	</summary>\n";
		myReport += "</jasperReport>\n";
				
		return myReport;
	}

	public String makeLandscapeReport(String reportname, String mysql, BQuery query) {
		String myReport = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
		myReport += "<jasperReport xmlns=\"http://jasperreports.sourceforge.net/jasperreports\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://jasperreports.sourceforge.net/jasperreports http://jasperreports.sourceforge.net/xsd/jasperreport.xsd\" ";
		myReport += "name=\"" + reportname + "\" language=\"groovy\" pageWidth=\"842\" pageHeight=\"595\" orientation=\"Landscape\" whenNoDataType=\"BlankPage\" columnWidth=\"802\" leftMargin=\"20\" rightMargin=\"20\" topMargin=\"20\" bottomMargin=\"20\">\n";
		myReport += "	<property name=\"ireport.zoom\" value=\"0.75\"/>\n";
		myReport += "	<property name=\"ireport.x\" value=\"0\"/>\n";
		myReport += "	<property name=\"ireport.y\" value=\"0\"/>\n";
		myReport += "	<style name=\"Title\" fontName=\"Times New Roman\" fontSize=\"50\" isBold=\"true\" pdfFontName=\"Times-Bold\"/>\n";
		myReport += "	<style name=\"SubTitle\" forecolor=\"#736343\" fontName=\"Arial\" fontSize=\"18\"/>\n";
		myReport += "	<style name=\"Column header\" forecolor=\"#666666\" fontName=\"Arial\" fontSize=\"12\" isBold=\"true\"/>\n";
		myReport += "	<style name=\"Detail\" fontName=\"Arial\" fontSize=\"12\"/>\n";
		myReport += "	<style name=\"Row\" mode=\"Transparent\">\n";
		myReport += "		<conditionalStyle>\n";
		myReport += "			<conditionExpression><![CDATA[$V{REPORT_COUNT}%2 == 0]]></conditionExpression>\n";
		myReport += "			<style backcolor=\"#E6DAC3\"/>\n";
		myReport += "		</conditionalStyle>\n";
		myReport += "	</style>\n";
		myReport += "	<parameter name=\"filterid\" class=\"java.lang.String\">\n";
		myReport += "		<defaultValueExpression><![CDATA[\"1\"]]></defaultValueExpression>\n";
		myReport += "	</parameter>\n";
		myReport += "	<queryString language=\"SQL\">\n";
		myReport += "		<![CDATA[" + mysql + "]]>\n";
		myReport += "	</queryString>\n";

		for(int i = 0; i < query.getColumnCount(); i++) {
			myReport += "	<field name=\"" + query.getFieldName(i);
			myReport += "\" class=\"" +  query.getColumnClass(i).toString().replace("class ", "") + "\"/>\n";
		}

		myReport += "	<background>\n";
		myReport += "		<band splitType=\"Stretch\"/>\n";
		myReport += "	</background>\n";
		myReport += "	<title>\n";
		myReport += "		<band height=\"71\" splitType=\"Stretch\">\n";
		myReport += "			<staticText>\n";
		myReport += "				<reportElement style=\"Title\" x=\"66\" y=\"0\" width=\"446\" height=\"62\"/>\n";
		myReport += "				<textElement verticalAlignment=\"Middle\">\n";
		myReport += "					<font fontName=\"Times New Roman\" size=\"24\" pdfFontName=\"Times-Roman\"/>\n";
		myReport += "				</textElement>\n";
		myReport += "				<text><![CDATA[" + query.initCap(reportname.replace("vw_", "")) + " Report]]></text>\n";
		myReport += "			</staticText>\n";
		myReport += "		</band>\n";
		myReport += "	</title>\n";
		myReport += "	<pageHeader>\n";
		myReport += "		<band splitType=\"Stretch\"/>\n";
		myReport += "	</pageHeader>\n";
		myReport += "	<columnHeader>\n";
		myReport += "		<band height=\"16\" splitType=\"Stretch\">\n";
		myReport += "			<line>\n";
		myReport += "				<reportElement positionType=\"FixRelativeToBottom\" x=\"0\" y=\"15\" width=\"802\" height=\"1\"/>\n";
		myReport += "				<graphicElement>\n";
		myReport += "					<pen lineWidth=\"0.5\" lineColor=\"#999999\"/>\n";
		myReport += "				</graphicElement>\n";
		myReport += "			</line>\n";

		int w = 770 / query.getColumnCount();
		int x = 0;
		for(int i = 0; i < query.getColumnCount(); i++) {
			x = 1 + (i * w);
			myReport += "			<staticText>\n";
			myReport += "				<reportElement style=\"Column header\" x=\"" + Integer.toString(x) + "\"";
			myReport += " y=\"0\" width=\"" + Integer.toString(w) + "\" height=\"15\" forecolor=\"#000000\"/>\n";
			myReport += "				<textElement>\n";
			myReport += "					<font fontName=\"Times New Roman\"/>\n";
			myReport += "				</textElement>\n";
			myReport += "				<text><![CDATA[" + query.initCap(query.getFieldName(i)) + "]]></text>\n";
			myReport += "			</staticText>\n";
		}

		myReport += "		</band>\n";
		myReport += "	</columnHeader>\n";
		myReport += "	<detail>\n";
		myReport += "		<band height=\"15\" splitType=\"Stretch\">\n";
		myReport += "			<frame>\n";
		myReport += "				<reportElement style=\"Row\" mode=\"Opaque\" x=\"0\" y=\"0\" width=\"802\" height=\"15\"/>\n";

		for(int i = 0; i < query.getColumnCount(); i++) {
			x = 1 + (i * w);
			myReport += "				<textField isStretchWithOverflow=\"true\" isBlankWhenNull=\"true\">\n";
			myReport += "					<reportElement style=\"Detail\" x=\"" + Integer.toString(x) + "\" y=\"0\"";
			myReport += " width=\"" + Integer.toString(w) + "\" height=\"15\"/>\n";
			myReport += "					<textElement>\n";
			myReport += "						<font fontName=\"Times New Roman\"/>\n";
			myReport += "					</textElement>\n";
			myReport += "					<textFieldExpression class=\"";
			myReport +=  query.getColumnClass(i).toString().replace("class ", "").replace("java.sql.Date", "java.util.Date") + "\">";
			myReport += "<![CDATA[$F{" + query.getFieldName(i) + "}]]></textFieldExpression>\n";
			myReport += "				</textField>\n";
		}

		myReport += "			</frame>\n";
		myReport += "		</band>\n";
		myReport += "	</detail>\n";
		myReport += "	<columnFooter>\n";
		myReport += "		<band height=\"15\" splitType=\"Stretch\">\n";
		myReport += "			<line>\n";
		myReport += "				<reportElement positionType=\"FixRelativeToBottom\" x=\"0\" y=\"3\" width=\"802\" height=\"1\"/>\n";
		myReport += "				<graphicElement>\n";
		myReport += "					<pen lineWidth=\"0.5\" lineColor=\"#999999\"/>\n";
		myReport += "				</graphicElement>\n";
		myReport += "			</line>\n";
		myReport += "		</band>\n";
		myReport += "	</columnFooter>\n";
		myReport += "	<pageFooter>\n";
		myReport += "		<band height=\"25\" splitType=\"Stretch\">\n";
		myReport += "			<frame>\n";
		myReport += "				<reportElement mode=\"Opaque\" x=\"-21\" y=\"1\" width=\"841\" height=\"24\" forecolor=\"#D0B48E\" backcolor=\"#F2EBDF\"/>\n";
		myReport += "				<textField evaluationTime=\"Report\">\n";
		myReport += "					<reportElement style=\"Column header\" x=\"771\" y=\"1\" width=\"40\" height=\"20\" forecolor=\"#736343\"/>\n";
		myReport += "					<textElement verticalAlignment=\"Middle\">\n";
		myReport += "						<font fontName=\"Times New Roman\" size=\"10\" isBold=\"false\"/>\n";
		myReport += "					</textElement>\n";
		myReport += "					<textFieldExpression class=\"java.lang.String\"><![CDATA[\" \" + $V{PAGE_NUMBER}]]></textFieldExpression>\n";
		myReport += "				</textField>\n";
		myReport += "				<textField>\n";
		myReport += "					<reportElement style=\"Column header\" x=\"691\" y=\"1\" width=\"80\" height=\"20\" forecolor=\"#736343\"/>\n";
		myReport += "					<textElement textAlignment=\"Right\" verticalAlignment=\"Middle\">\n";
		myReport += "						<font fontName=\"Times New Roman\" size=\"10\" isBold=\"false\"/>\n";
		myReport += "					</textElement>\n";
		myReport += "					<textFieldExpression class=\"java.lang.String\"><![CDATA[\"Page \"+$V{PAGE_NUMBER}+\" of\"]]></textFieldExpression>\n";
		myReport += "				</textField>\n";
		myReport += "				<textField pattern=\"EEEEE, d MMMMM yyyy HH:mm:ss Z\">\n";
		myReport += "					<reportElement style=\"Column header\" x=\"22\" y=\"1\" width=\"197\" height=\"20\" forecolor=\"#736343\"/>\n";
		myReport += "					<textElement verticalAlignment=\"Middle\">\n";
		myReport += "						<font fontName=\"Times New Roman\" size=\"10\" isBold=\"false\"/>\n";
		myReport += "					</textElement>\n";
		myReport += "					<textFieldExpression class=\"java.util.Date\"><![CDATA[new java.util.Date()]]></textFieldExpression>\n";
		myReport += "				</textField>\n";
		myReport += "			</frame>\n";
		myReport += "		</band>\n";
		myReport += "	</pageFooter>\n";
		myReport += "	<summary>\n";
		myReport += "		<band splitType=\"Stretch\"/>\n";
		myReport += "	</summary>\n";
		myReport += "</jasperReport>\n";

		return myReport;
	}

	public String makeSubReport(String reportname, String mysql, BQuery query) {
		String myReport = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
		myReport += "<jasperReport xmlns=\"http://jasperreports.sourceforge.net/jasperreports\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://jasperreports.sourceforge.net/jasperreports http://jasperreports.sourceforge.net/xsd/jasperreport.xsd\" ";
		myReport += "name=\"" + reportname + "\" language=\"groovy\" pageWidth=\"595\" pageHeight=\"842\" whenNoDataType=\"BlankPage\" columnWidth=\"535\" leftMargin=\"20\" rightMargin=\"20\" topMargin=\"0\" bottomMargin=\"0\">\n";
		myReport += "	<property name=\"ireport.zoom\" value=\"1.0\"/>\n";
		myReport += "	<property name=\"ireport.x\" value=\"0\"/>\n";
		myReport += "	<property name=\"ireport.y\" value=\"0\"/>\n";
		myReport += "	<style name=\"Title\" fontName=\"Times New Roman\" fontSize=\"50\" isBold=\"true\" pdfFontName=\"Times-Bold\"/>\n";
		myReport += "	<style name=\"SubTitle\" forecolor=\"#736343\" fontName=\"Arial\" fontSize=\"18\"/>\n";
		myReport += "	<style name=\"Column header\" forecolor=\"#666666\" fontName=\"Arial\" fontSize=\"12\" isBold=\"true\"/>\n";
		myReport += "	<style name=\"Detail\" fontName=\"Arial\" fontSize=\"12\"/>\n";
		myReport += "	<style name=\"Row\" mode=\"Transparent\">\n";
		myReport += "		<conditionalStyle>\n";
		myReport += "			<conditionExpression><![CDATA[$V{REPORT_COUNT}%2 == 0]]></conditionExpression>\n";
		myReport += "			<style backcolor=\"#E6DAC3\"/>\n";
		myReport += "		</conditionalStyle>\n";
		myReport += "	</style>\n";
		myReport += "	<parameter name=\"filterid\" class=\"java.lang.String\">\n";
		myReport += "		<defaultValueExpression><![CDATA[\"1\"]]></defaultValueExpression>\n";
		myReport += "	</parameter>\n";
		myReport += "	<queryString language=\"SQL\">\n";
		myReport += "		<![CDATA[" + mysql + "]]>\n";
		myReport += "	</queryString>\n";

		for(int i = 0; i < query.getColumnCount(); i++) {
			myReport += "	<field name=\"" + query.getFieldName(i);
			myReport += "\" class=\"" +  query.getColumnClass(i).toString().replace("class ", "") + "\"/>\n";
		}

		myReport += "	<background>\n";
		myReport += "		<band splitType=\"Stretch\"/>\n";
		myReport += "	</background>\n";
		myReport += "	<title>\n";
		myReport += "		<band height=\"21\" splitType=\"Stretch\">\n";
		myReport += "			<staticText>\n";
		myReport += "				<reportElement style=\"Title\" x=\"1\" y=\"0\" width=\"446\" height=\"20\"/>\n";
		myReport += "				<textElement verticalAlignment=\"Middle\">\n";
		myReport += "					<font fontName=\"Times New Roman\" size=\"12\" pdfFontName=\"Times-Roman\"/>\n";
		myReport += "				</textElement>\n";
		myReport += "				<text><![CDATA[" + query.initCap(reportname.replace("vw_", "")) + "]]></text>\n";
		myReport += "			</staticText>\n";
		myReport += "		</band>\n";		
		myReport += "	</title>\n";
		myReport += "	<pageHeader>\n";
		myReport += "		<band splitType=\"Stretch\"/>\n";
		myReport += "	</pageHeader>\n";
		myReport += "	<columnHeader>\n";
		myReport += "		<band height=\"16\" splitType=\"Stretch\">\n";

		int w = 525 / query.getColumnCount();
		int x = 0;
		for(int i = 0; i < query.getColumnCount(); i++) {
			x = 1 + (i * w);
			myReport += "			<staticText>\n";
			myReport += "				<reportElement style=\"Column header\" x=\"" + Integer.toString(x) + "\"";
			myReport += " y=\"0\" width=\"" + Integer.toString(w) + "\" height=\"15\" forecolor=\"#000000\"/>\n";
			myReport += "				<textElement>\n";
			myReport += "					<font fontName=\"Times New Roman\"/>\n";
			myReport += "				</textElement>\n";
			myReport += "				<text><![CDATA[" + query.initCap(query.getFieldName(i)) + "]]></text>\n";
			myReport += "			</staticText>\n";
		}

		myReport += "		</band>\n";
		myReport += "	</columnHeader>\n";
		myReport += "	<detail>\n";
		myReport += "		<band height=\"15\" splitType=\"Stretch\">\n";

		for(int i = 0; i < query.getColumnCount(); i++) {
			x = 1 + (i * w);
			myReport += "				<textField isStretchWithOverflow=\"true\" isBlankWhenNull=\"true\">\n";
			myReport += "					<reportElement style=\"Detail\" x=\"" + Integer.toString(x) + "\" y=\"0\"";
			myReport += " width=\"" + Integer.toString(w) + "\" height=\"15\"/>\n";
			myReport += "					<textElement>\n";
			myReport += "						<font fontName=\"Times New Roman\"/>\n";
			myReport += "					</textElement>\n";
			myReport += "					<textFieldExpression class=\"";
 			myReport +=  query.getColumnClass(i).toString().replace("class ", "").replace("java.sql.Date", "java.util.Date") + "\">";
			myReport += "<![CDATA[$F{" + query.getFieldName(i) + "}]]></textFieldExpression>\n";
			myReport += "				</textField>\n";
		}

		myReport += "		</band>\n";
		myReport += "	</detail>\n";
		myReport += "</jasperReport>\n";

		return myReport;
	}

}
