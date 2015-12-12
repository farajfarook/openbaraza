/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.xml;

import java.util.Map;
import java.util.TreeMap;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.Collections;

import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.NamedNodeMap;

public class BElement {
	Map<String, String> attributes;
	List<BElement> elements;
	
	int type = 0;
	String name = "";
	String value = "";

	public BElement(String nodeName) {
		type = 1;
        name = nodeName;
	
		attributes = new HashMap<String, String>();
		elements = new ArrayList<BElement>();
	}

	public BElement(Node node) {
		type = node.getNodeType();
        name = node.getNodeName();
	
		attributes = new HashMap<String, String>();
		if(node.hasAttributes()) setAttibutes(node);

		elements = new ArrayList<BElement>();
		if(node.hasChildNodes()) setNodes(node.getChildNodes());
	}

	public void setNodes(NodeList elementlist) {
		for(int i=0; i < elementlist.getLength(); i++) {
			switch (elementlist.item(i).getNodeType()) {
            case Node.TEXT_NODE:
				if(elementlist.item(i).getNodeValue()!=null)
					value += elementlist.item(i).getNodeValue().trim();
				break;
			case Node.CDATA_SECTION_NODE:
				if(elementlist.item(i).getNodeValue()!=null)
					value += elementlist.item(i).getNodeValue().trim();
				break;
            default: 
				elements.add(new BElement(elementlist.item(i)));
				break;
			}
        }
	}

	public void setAttibutes(Node node) {
		NamedNodeMap attmap = node.getAttributes();
		for(int i=0; i<attmap.getLength(); i++) 
			attributes.put(attmap.item(i).getNodeName(), attmap.item(i).getNodeValue());
	}

	public BElement getElement(int index) {
		if(elements.size()>index) return elements.get(index);
		return null;
	}

	public BElement getElement(String nodeValue) {
		for(BElement el : elements) {
			if(el.getValue().equals(nodeValue))
				return el;
		}

		return null;
	}

	public BElement getElementByName(String nodeName) {
		for(BElement el : elements) {
			if(el.getName().equals(nodeName))
				return el;
		}

		return null;
	}

	public BElement getElementByKey(String keyValue) {
		for(BElement el : elements) {
			if(el.getAttribute("key", "").equals(keyValue))
				return el;
		}

		return null;
	}

	public int elementIndex(BElement element) {
		return elements.indexOf(element);
	}

	public BElement getFirst() {
		return getElement(0);
	}

	public List<BElement> getElements() {
		return elements;
	}

	public int getNodeNumber() {
		return elements.size();
	}

	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}

	public String getName() {
		return name;
	}

	public void setName(String nodeName) {
		name = nodeName;
	}

	public String getValue() {
		return value;
	}

	public String getValue(String nval) {
		if(value != null) nval = value;

		return nval;
	}

	public void setValue(String nodeValue) {
		value = nodeValue;
	}

	public int getSize() {
		return attributes.size();
	}

	public int getNodeSize() {
		return elements.size();
	}

	public boolean isLeaf() {
		boolean isl = true;

		if(elements.size() > 0)  isl = false;

		return isl;
	}

	public String getValueAt(int aRow, int aCol) {
		String mystr = "";
		if(aRow == 0) {
			if(aCol == 0) mystr = name;
			else mystr = value;
		} else {
			List<String> ml = new ArrayList<String>(attributes.keySet());
			mystr = ml.get(aRow-1);
			if(aCol == 1) mystr = attributes.get(mystr);
		}
		
		return mystr;
	}

	public void setValueAt(String cellValue, int aRow, int aCol) {
		if(aRow == 0) {
			if(aCol == 0) name = cellValue;
			else value = cellValue;
		} else {
			List<String> ml = new ArrayList<String>(attributes.keySet());
			String ky = ml.get(aRow-1);
			if(aCol == 0) {
				String kvl = attributes.get(ky);
				attributes.remove(ky);
				attributes.put(cellValue, kvl);
			} else {
				attributes.put(ky, cellValue);
			}
		}
	}

	public void insertAttribute(String key, String value) {
		attributes.put(key, value);
	}

	public Map<String, String> getAttributes() {
		return attributes;
	}

	public String getAttribute(String attributeName) {
		return attributes.get(attributeName);
	}

	public String getAttribute(String attributeName, String defaultValue) {
		String mystr = attributes.get(attributeName);
		if(mystr == null) mystr = defaultValue;
	
		return mystr;
	}

	public void replaceAttribute(String oldAttribute, String newAttribute) {
		if(getAttribute(oldAttribute) != null) {
			setAttribute(newAttribute, getAttribute(oldAttribute));
			delAttribute(oldAttribute);
		}
	}

	public void setAttribute(String attributeName, String attributeValue) {
		if(attributeName != null) {
			if(attributeValue != null)
				attributes.put(attributeName, attributeValue);
			else
				attributes.remove(attributeName);
		}
	}

	public void delAttribute(String attributeName) {
		if(attributeName != null) attributes.remove(attributeName);
	}

	public void addNode(BElement newNode) {
		elements.add(newNode);
	}

	public void addNode(BElement newNode, int nodePos) {
		elements.add(nodePos, newNode);
	}

	public void delNode(BElement oldNode) {
		elements.remove(oldNode);
	}

	public void clearNodes() {
		elements.clear();
	}

	public void delNode(int nodePos) {
		elements.remove(nodePos);
	}

	public String getString() {
		String mystr = "<" + name;
		for (String key : attributes.keySet()) {
			mystr += " " + key + "=\"" + attributes.get(key).replaceAll("<", "&lt;") + "\"";
		}
		mystr += ">" + value;
		if(elements.size()>0) mystr += "\n";
		
		for(BElement element : elements)
			mystr += indentStr(element.getString());

		mystr += "</" + name + ">\n";

		return mystr;
	}

	public String toString() {
		return getString();
	}

	public String indentStr(String mystr) {
		String[] mylines = mystr.split("\n");
		mystr = "";
		for (String myline : mylines)
			mystr += "\t" + myline + "\n";

		return mystr;
	}

	public BElement copy() {
		BElement newEl = new BElement(new String(name));
		newEl.setValue(new String(value));
		newEl.setType(type);
		for(String key : attributes.keySet())
			newEl.setAttribute(new String(key), new String(attributes.get(key)));
			
		for(BElement element : elements)
			newEl.addNode(element.copy());

		return newEl;
	}

}
