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
import java.text.ParseException;
import java.lang.NumberFormatException;

public class BAmountInWords {  
      
	protected String amountInWords;  
	protected String words = "";  
	final static String units[] = {"","One ", "Two ", "Three ", "Four ", "Five ", "Six ", "Seven ", "Eight ", "Nine ", "Ten ", "Eleven ", "Twelve ", "Thirteen ", "Fourteen ", "Fifteen ", "Sixteen ", "Seventeen ", "Eighteen ", "Nineteen "};
    final static String tens[] = {"", "Ten ", "Twenty ", "Thirty ", "Forty ", "Fifty ", "Sixty ", "Seventy ", "Eighty ", "Ninety "};  

	public BAmountInWords() { }

	public BAmountInWords(int amount) {
		this.amountInWords = convert(amount);    
	}
	
	public BAmountInWords(String amount) {
		try {
			DecimalFormat df = new DecimalFormat();
			Number d = df.parse(amount);
			
			this.amountInWords = convert(d.intValue());
		} catch(NumberFormatException ex) {
			System.out.println("Number error : " + ex);
		} catch(ParseException ex) {
			System.out.println("Amount Conversion error : " + ex);
		}
	}

	public String convert(int amount) {  
		int millions = amount / 1000000;   
		String tword = threeDigits(millions);  
		if(tword.length()>1) words = tword + "Million ";  

		amount -= millions*1000000;  
		int thousands = amount / 1000;  
		tword = threeDigits(thousands);  
		if(tword.length()>1) words += tword + "Thousand ";  

		amount -= thousands*1000;  
		words += threeDigits(amount);

		return words;
    }

    public String threeDigits(int digits) {  
		String digWord = "";  
		int hnd = digits / 100;  
		if(hnd > 0) digWord += units[hnd] + "Hundred ";  
		int ten = digits - hnd *100;  
		if(ten < 20) {
			digWord += units[ten];  
       } else {  
			int tenth = ten / 10;  
			digWord +=tens[tenth];  
			int last = ten - tenth * 10;  
			digWord += units[last];
       }  

       return digWord;  
    }  
         
	public String getAmountInWords() {  
		return amountInWords;  
	}  
  
	public void setAmountInWords(String amountInWords) {  
		this.amountInWords = amountInWords;  
	}  
}



