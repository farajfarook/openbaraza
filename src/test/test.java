package test;

import org.baraza.utils.BNumberFormat;

public class test {

	public static void main(String args[]) {
		System.out.println("Entering Test mode");

		BNumberFormat nf = new BNumberFormat();

		System.out.println("Number test");
		nf.getNumber("a254733578156");

		System.out.println("Integer test");
		nf.getInt("254733578156");

		System.out.println("Exiting Test mode");
	}
}
