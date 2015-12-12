package test.xml;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;

public class fare {

	public static void main(String args[]) {

		BXML xml = new BXML("./test/xml/fare.xml", false);

		BElement root = xml.getRoot().getFirst();

		BElement fare = root.getElementByName("GenQuoteDetails");

		System.out.println(fare.toString());
		System.out.println("------------------------------------");

		for(BElement el : fare.getElements()) {
			System.out.println(el.getName() + " : " + el.getValue());
		}
	}
}
