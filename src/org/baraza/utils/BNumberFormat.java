/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.utils;

import java.util.logging.Logger;
import java.text.NumberFormat;
import java.text.ParseException;
import java.lang.Number;

public class BNumberFormat {

	Logger log = Logger.getLogger(BNumberFormat.class.getName());
	int error = 0;

	public int getError() {
		return error;
	}

	public Number getNumber(String myNumber) {
		Number myNum = 0;
		error = 0;

		try {
			NumberFormat nf = NumberFormat.getInstance();
			myNum = nf.parse(myNumber);
		} catch(NumberFormatException ex) {
			error = 1;
			log.info("Number error : " + ex);
		} catch(ParseException ex) {
			error = 2;
			log.info("Number Parse error : " + ex);
		}

		return myNum;
	}
	
	public int getInt(String myNumber) {
		int myNum = 0;
		error = 0;

		try {
			NumberFormat nf = NumberFormat.getInstance();
			Number pnum = nf.parse(myNumber);
			 
			myNum = Integer.parseInt(myNumber);
		} catch(NumberFormatException ex) {
			error = 1;
			log.info("Number error : " + ex);
		} catch(ParseException ex) {
			error = 2;
			log.info("Number Parse error : " + ex);
		}

		return myNum;
	}
}
