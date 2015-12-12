/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.xml;

import java.util.logging.Logger;
import javax.xml.parsers.DocumentBuilder; 
import javax.xml.parsers.DocumentBuilderFactory;  
import javax.xml.parsers.FactoryConfigurationError;  
import javax.xml.parsers.ParserConfigurationException;

import org.xml.sax.SAXException;  
import org.xml.sax.SAXParseException;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.io.IOException;

import org.w3c.dom.Document;
import org.w3c.dom.DOMException;

import org.baraza.utils.Bio;

public class BXML {
	Logger log = Logger.getLogger(BXML.class.getName());
	String xmlFile = null;
	BElement root = null;

	public BXML(String xml, boolean isText) {
        try {
			// initialise Specifications from a Local Property file
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			DocumentBuilder builder = factory.newDocumentBuilder();
			Document document = null;
			if(isText) {
				InputStream in = new ByteArrayInputStream(xml.getBytes("UTF-8"));
				document = builder.parse(in);
			} else {
				document = builder.parse(xml);
				xmlFile = xml;
			}
			root = new BElement(document);
        } catch (SAXParseException ex) {
        	log.severe("XML Error : " + ex.getMessage());
        } catch (ParserConfigurationException ex) {
            log.severe("File IO error : " + ex);
        } catch (SAXException ex) {
            log.severe("File IO error : " + ex);
        } catch (IOException ex) {
            log.severe("File IO error : " + ex);
        } catch(Exception ex) {
			log.severe("File createtion error");
		}
	}

	public BXML(InputStream inXml) {
        try {
			// initialise Specifications from a Local Property file
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			DocumentBuilder builder = factory.newDocumentBuilder();
			Document document = builder.parse(inXml);
			root = new BElement(document);
        } catch (SAXParseException ex) {
        	log.severe("XML Error : " + ex.getMessage());
        } catch (ParserConfigurationException ex) {
            log.severe("File IO error : " + ex);
        } catch (SAXException ex) {
            log.severe("File IO error : " + ex);
        } catch (IOException ex) {
            log.severe("File IO error : " + ex);
        } catch(Exception ex) {
			log.severe("File createtion error");
		}
	}

	public BElement getDocument() {
		return root;
	}

	public BElement getRoot() {
		return root.getFirst();
	}

	public void saveFile() {
		if(xmlFile != null) {
			BElement el = root.getFirst();
			Bio io = new Bio();
			io.saveFile(xmlFile, el.toString());
		}
	}
}
