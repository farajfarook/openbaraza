package test;

import javax.comm.*;
import org.baraza.server.sms.*;
import org.baraza.DB.BDB;

public class sms {

	public static void main(String args[]) {
		BSMSConnection smsconn = new BSMSConnection("/dev/ttyUSB1", "9600");
		SerialPort port = smsconn.getPort();

		BDB db = null;

		if(port != null) {
			BSMSEng smseng =  new BSMSEng(port, db);
			smseng.start();

			BSMSCommands comm = new BSMSCommands(smseng);

			//comm.initPhone("ME", "3,1,0,2,0");	
			comm.initPhone(null, "0,0,0,0,0");	// Storage and NMI specification

			//comm.phoneCheck();

			//smseng.sendMessage("AT");
			//String resp = smseng.getMessage();

			String msg = "Simple test message";
			//smseng.sendSMS("+2547xx78xxxx", msg);
			//smseng.sendSMS("+254733578156", msg);

			// Read all SMS
			//comm.readSMS();

			smseng.close();
		}

		smsconn.close();
	}
}
