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
import java.util.StringTokenizer;
import java.util.TooManyListenersException;
import java.io.IOException;
import java.io.InputStream;

import gnu.io.SerialPort;
import gnu.io.SerialPortEventListener;
import gnu.io.SerialPortEvent;

import org.baraza.utils.BLogHandle;

public class BSMSEng extends Thread implements SerialPortEventListener {
	Logger log = Logger.getLogger(BSMSEng.class.getName());
    InputStream	inputStream;
	boolean DATA_BUFFER;
	int messageNum = 0;

	private byte[] readBuffer = new byte[65536];
	private int bufferOffset = 0;

	// Port status message
    public final int OK = 1;
    public final int WAIT = 2;
    public final int ERROR = 3;
    public final int WMSG = 4;
    public final int RMSG = 5;
	public final int MSGL = 6;
	public final int PHOB = 7;
    public final int ECHO = 8;
    public final int TIMEOUT = 9;
    public final int CONNERR = 10;
	
	private boolean hasMessage = false;
    private int portStatus = OK;
    private String portStatusMsg = "";
	private String message = "";
	private String smspdu = "";
	BLogHandle logHandle;

    public BSMSEng(SerialPort port, BLogHandle logHandle) {
		inputStream = null;
		DATA_BUFFER = false;
		this.logHandle = logHandle;
		logHandle.config(log);

		try {
			inputStream = port.getInputStream();

			port.addEventListener(this);
			port.notifyOnDataAvailable(true);
			port.notifyOnBreakInterrupt(true);
		} catch(TooManyListenersException ex) {
			log.severe("Too many listners : " + ex);
		} catch (IOException ex) {
			log.severe("Can't open input stream: write-only : " + ex);
		}
    }

    public void run() {
		gotosleep(100);
    }

	public void gotosleep(int i) {
		try {
		    sleep(i);
		} catch (InterruptedException e) {
			log.severe("Sending sleep error");
		}
	}

    public void serialEvent(SerialPortEvent event) {
		if(portStatus == CONNERR) return;

		switch (event.getEventType()) {
		case SerialPortEvent.OE:
		case SerialPortEvent.FE:
		case SerialPortEvent.PE:
		case SerialPortEvent.CD:
		case SerialPortEvent.CTS:
		case SerialPortEvent.DSR:
		case SerialPortEvent.RI:
		case SerialPortEvent.OUTPUT_BUFFER_EMPTY:
			DATA_BUFFER = false;
			break;
		case SerialPortEvent.BI:
			System.out.println("DEBUG: BREAK RECEIVED");
			DATA_BUFFER = false;
			break;
		case SerialPortEvent.DATA_AVAILABLE:
			DATA_BUFFER = true;
			
			int n = 0;
			try {
				log.fine("DEBUG: Data Available : " + inputStream.available());

				while((n = inputStream.available()) > 0) {
					n = inputStream.read(readBuffer, bufferOffset, n);
					bufferOffset += n;
				}

				//if (((readBuffer[bufferOffset - 1] == '\n') && (readBuffer[bufferOffset - 2] == '\r'))) { // lfcr detected, line ready
				if(bufferOffset > 0) {
					if (readBuffer[bufferOffset - 1] == '\n') {
						String sbuf = new String(readBuffer, 0, bufferOffset, "ISO-8859-1"); // bufferOffset-2
						sbuf = sbuf.replace("\r", "");
						lineReceived(sbuf);
						bufferOffset = 0;
					} else {
						String sbuf = new String(readBuffer, 0, bufferOffset, "ISO-8859-1"); // bufferOffset-2
						log.finer("DATA BUFF : " + sbuf);
					}
				}
			} catch (IOException ex) {
				log.severe("IO Exception of data read : " + ex);
				portStatus = CONNERR;
				this.interrupt();
			}

			gotosleep(50); // delay 50 msec
			break;
		default: break;
		}
    }

	private void lineReceived(String buffer) {
		String response = "";
		String msg = null;
		StringTokenizer st = new StringTokenizer(buffer, "\n\n");

		while (st.hasMoreTokens()) {
			response = st.nextToken().trim();
			log.fine("RESP : " + response);

			if (response.startsWith("OK")) {
				if(portStatus == RMSG) {
					log.fine("SMS Message " + msg);
					smspdu = msg;
					hasMessage = true;
				}
				portStatus = OK;
			} else if (response.startsWith(">")) {
				portStatus = WMSG;
				portStatusMsg = response;
			} else if (response.startsWith("ERROR")) {
				portStatus = ERROR;
				portStatusMsg = response;
			} else if (response.startsWith("+CME") || response.startsWith("+CMS")) {	// Message error
				portStatus = ERROR;
				portStatusMsg = response;
			} else if (response.startsWith("07") || response.startsWith("00")) {		// receiving an SMS
				if(portStatus == RMSG) msg = response;
			} else if (response.startsWith("AT+CPMS")) { 			// list sms SM, ME or MT
			} else if (response.startsWith("+CPMS")) { 				// list sms SM, ME or MT
				portStatus = MSGL;
				portStatusMsg = response;
				message += response;
			} else if (response.startsWith("AT+CGMI")) {			// Reading to the phone manufacturer
			} else if (response.startsWith("AT+CGMM")) {			// Reading to the phone model
			} else if (response.startsWith("AT+CNMI")) {			// MNI Query
			} else if (response.startsWith("AT+CMGL")) {			// Message list response
			} else if (response.startsWith("+CMGL")) {				// Read all Messages received
				message += "\n" + response;
			} else if (response.startsWith("+CMTI")) {				// new Messages received
				log.info("Message received : " + response);
				portStatusMsg = response;
				portStatus = OK;
			} else if (response.startsWith("+CMGR")) {				// read sms OK +CMGR
				portStatus = RMSG;
				msg = "";
				portStatusMsg = response;
			} else if (response.startsWith("+CMGS")) {				// write sms OK +CMGS
				log.info("MESSAGE SENT");
			} else if (response.startsWith("+CPBR")) { 				// read index phonebook OK
				portStatus = PHOB;
				portStatusMsg = response;
			} else if (response.startsWith("+CPBS")) {				// read current phonebook memory OK
				portStatus = PHOB;
				portStatusMsg = response;
			} else if (response.startsWith("+CPBF")) {				// read find phonebook OK
				portStatus = PHOB;
				portStatusMsg = response;
			} else if (response.startsWith("ATE0")) {				// snoop echo
				portStatus = ECHO;
				portStatusMsg = response;
			} else {												// pick any other message
				if(portStatus == RMSG) msg += "\n" + response;
				message += response;
			}
		}
	}

	public void setMessageNum(int i) {
		messageNum = i;
	}

	public boolean checkMessage() {
		boolean hm = hasMessage;
		hasMessage = false;
		return hm;
	}

	public int getPortStatus() { 
		return portStatus; 
	}

	public void bufferReset() {
		bufferOffset = 0;
		portStatus = WAIT;
		portStatusMsg = "";
		message = "";
	}

	public String getMessage() { 
		int i = 0;
		while(portStatus != OK) {
			gotosleep(250); 
			i++; 
			if(i>50) {portStatus = ERROR; break;} 
			if(portStatus == ERROR) break;
		}
		if(portStatus == ERROR) {
			log.severe("SMS ERROR : " + portStatusMsg);
		}
		
		String nmsg = message;
		message = "";

		return nmsg; 
	}

	public String getSMSMessage() {
		getMessage();
		return smspdu;
	}

	public void close() {
		try {
			if(inputStream != null) inputStream.close();
		} catch(IOException ex) {
			log.severe("IO Exception on stream close : " + ex);
		}

		this.interrupt();
	}
}
