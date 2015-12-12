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
import java.util.Enumeration;
import java.io.IOException;
import gnu.io.SerialPort;
import gnu.io.CommPortIdentifier;
import gnu.io.CommPortOwnershipListener;
import gnu.io.PortInUseException;
import gnu.io.UnsupportedCommOperationException;

import org.baraza.utils.BLogHandle;

public class BSMSConnection implements CommPortOwnershipListener {
	Logger log = Logger.getLogger(BSMSConnection.class.getName());
	SerialPort port;

	public BSMSConnection(String wantedPortName, String datarate, BLogHandle logHandle) throws IOException, RuntimeException, Exception {
		port = null;
		logHandle.config(log);

		// Get a list of available ports and search for required port
		Enumeration portIdentifiers = CommPortIdentifier.getPortIdentifiers();
		CommPortIdentifier portId = null;
		while (portIdentifiers.hasMoreElements()) {
			CommPortIdentifier cpid = (CommPortIdentifier) portIdentifiers.nextElement();
			if(cpid.getName().equals(wantedPortName)) {
				CommPortIdentifier pid = CommPortIdentifier.getPortIdentifier(wantedPortName);
				if(pid.getPortType() == CommPortIdentifier.PORT_SERIAL) { //&& pid.getName().equals(wantedPortName)) {
					portId = pid;
					log.info("Connected : " + pid.getName());
				}
			}
		}

		// connect to the required port
		if(portId != null) {
			int rd = Integer.valueOf(datarate);

			try {
				port = (SerialPort)portId.open(this.getClass().getName(), 100);
				port.setSerialPortParams(rd, SerialPort.DATABITS_8, SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);
			} catch(PortInUseException ex) {
				log.severe("Port already in use : " + ex);
			} catch(UnsupportedCommOperationException ex) {
				log.severe("Port error: " + ex);
			}
		} else {
			log.info("Could not find serial port " + wantedPortName);
		}
	}

	public SerialPort getPort() {
		return port;
	}

	public void close() {
		sleep(2000);  // Be sure data is xferred before closing
		if (port != null) port.close();
		sleep(2000);
	}

	public void sleep(int st) {
		try {
			Thread.sleep(st);  // Be sure data is xferred before closing
		} catch (Exception e) {}
	}

    public void ownershipChange(int type) {
		if (type == CommPortOwnershipListener.PORT_OWNERSHIP_REQUESTED) {
			log.info("PORT_OWNERSHIP_REQUESTED received : Your port has been requested by an other application...");
		} else if (type == CommPortOwnershipListener.PORT_OWNED) {
			log.info("PORT_OWNED received!");
		} else if (type == CommPortOwnershipListener.PORT_UNOWNED) {
			log.info("PORT_UNOWNED received!");
		}
    }

}
