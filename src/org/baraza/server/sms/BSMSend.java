/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.sms;

import java.util.logging.Logger;
import java.io.OutputStream;
import java.io.IOException;
import java.util.StringTokenizer;
import java.util.TooManyListenersException;

import gnu.io.SerialPort;

import org.baraza.utils.BLogHandle;

public class BSMSend {
	Logger log = Logger.getLogger(BSMSend.class.getName());
	OutputStream outputStream;
	boolean DATA_BUFFER;
	BSMSMessage smsmsg;

	private int bufferOffset = 0;

	// Port status message
    public final int OK = 1;
    public final int CONNERR = 10;
    private int portStatus = OK;

    public BSMSend(SerialPort port, BLogHandle logHandle) {
		outputStream = null;
		logHandle.config(log);

		try {
			outputStream = port.getOutputStream();
		} catch (IOException ex) {
			log.severe("Can't open input stream: write-only : " + ex);
		}
    }

	public void sendMessage(String request) {
		log.fine("Writing : " + request);
		try {
			outputStream.write(request.getBytes());
		} catch (IOException ex) {
			portStatus = CONNERR;
			log.severe("IO Error on writting to output stream : " + ex);
		}

		gotosleep(1000); // delay 100 msec
	}

	public int getPortStatus() { 
		return portStatus; 
	}

	public void gotosleep(int i) {
		try {
		    Thread.sleep(i);
		} catch (InterruptedException e) {
			log.severe("Sending sleep error");
		}
	}

	public void close() {
		try {
			if(outputStream != null) outputStream.close();
		} catch(IOException ex) {
			log.severe("IO Exception on stream close : " + ex);
		}
		gotosleep(100);
	}
}