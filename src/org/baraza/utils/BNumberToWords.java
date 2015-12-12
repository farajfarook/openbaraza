/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.utils;

import java.text.DecimalFormat;

public class BNumberToWords {

	private static final String[] tensNames = {"", " ten",  " twenty", " thirty", " forty", " fifty", " sixty", 
		" seventy", " eighty", " ninety"};
	private static final String[] numNames = {"",  " one", " two", " three", " four", " five", " six", " seven",
		" eight", " nine", " ten", " eleven", " twelve", " thirteen", " fourteen",	" fifteen",
		" sixteen", " seventeen",	" eighteen",	" nineteen"};

	private static String convertLessThanOneThousand(int number) {
		String soFar;

		if (number % 100 < 20){
			soFar = numNames[number % 100];
			number /= 100;
		} else {
			soFar = numNames[number % 10];
			number /= 10;

			soFar = tensNames[number % 10] + soFar;
			number /= 10;
		}
		if (number == 0) return soFar;
		return numNames[number] + " hundred" + soFar;
	}


	public static String convert(long number) {
		// 0 to 999 999 999 999
		if (number == 0) { return "zero"; }

		String snumber = Long.toString(number);

		// pad with "0"
		String mask = "000000000000";
		DecimalFormat df = new DecimalFormat(mask);
		snumber = df.format(number);

		// XXXnnnnnnnnn 
		int billions = Integer.parseInt(snumber.substring(0,3));
		// nnnXXXnnnnnn
		int millions  = Integer.parseInt(snumber.substring(3,6)); 
		// nnnnnnXXXnnn
		int hundredThousands = Integer.parseInt(snumber.substring(6,9)); 
		// nnnnnnnnnXXX
		int thousands = Integer.parseInt(snumber.substring(9,12));    

		String tradBillions;
		switch (billions) {
		case 0:
			tradBillions = "";
			break;
		case 1 :
			tradBillions = convertLessThanOneThousand(billions) + " billion ";
			break;
		default :
			tradBillions = convertLessThanOneThousand(billions) + " billion ";
		}
		String result =  tradBillions;

		String tradMillions;
		switch (millions) {
		case 0:
			tradMillions = "";
			break;
		case 1 :
			tradMillions = convertLessThanOneThousand(millions) + " million ";
			break;
		default :
			tradMillions = convertLessThanOneThousand(millions) + " million ";
		}
		result =  result + tradMillions;

		String tradHundredThousands;
		switch (hundredThousands) {
		case 0:
			tradHundredThousands = "";
			break;
		case 1 :
			tradHundredThousands = "one thousand ";
			break;
		default :
			tradHundredThousands = convertLessThanOneThousand(hundredThousands) + " thousand ";
		}
		result =  result + tradHundredThousands;

		String tradThousand;
		tradThousand = convertLessThanOneThousand(thousands);
		result = result + tradThousand;
		result = result.replaceAll("^\\s+", "").replaceAll("\\b\\s{2,}\\b", " ");

		// remove extra spaces!
		return result;
	}
}

