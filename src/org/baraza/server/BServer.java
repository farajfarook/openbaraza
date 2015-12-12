/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server;

import java.util.logging.Logger;
import java.util.List;
import java.util.ArrayList;
import java.io.IOException;

import java.net.ServerSocket;
import java.net.Socket;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.utils.BLogHandle;

public class BServer extends Thread {
	Logger log = Logger.getLogger(BServer.class.getName());
	boolean listening = true;
	String configDir;
	BElement root;
	ServerSocket serverSocket = null;
	List<BServerTimed> stl = null;
	String greeting;
	Integer portNumber;
	BLogHandle logHandle;

	public BServer(String configDir) {
		this.configDir = configDir;
		BXML xml = new BXML(configDir + "config.xml", false);
		root = xml.getRoot();

		greeting = root.getAttribute("greeting");
		portNumber = new Integer(root.getAttribute("port", "7777"));
		logHandle = new BLogHandle(root);
		logHandle.config(log);

		stl = new ArrayList<BServerTimed>();
		for(BElement el : root.getElements()) {
			if(el.getName().equals("SERVER") && el.getAttribute("disable", "false").equals("false")) {
				BServerTimed st = new BServerTimed(configDir, el, logHandle);
				st.start();
				stl.add(st);
			}
		}
		
		try {
			serverSocket = new ServerSocket(portNumber.intValue());
			log.info("Server started");
		} catch (IOException e) {
			log.severe("Could not listen on port: " + portNumber.toString());
		}
	}

	public void run() {
		try {
			while (listening) {
				Socket socket = serverSocket.accept();
				BServerThread sst = new BServerThread(socket, this, greeting, logHandle);
				sst.start();

				sleep(100);
				
				if(!listening) break;
			}

			if(serverSocket != null) {
				serverSocket.close();
				serverSocket = null;
			}
        } catch (IOException ex) {
            log.severe("Could not connect client on port: 7777. : " + ex);
        } catch (InterruptedException ex) {
			log.severe("Sending sleep error : " + ex);
		}
    }

	public void close() {
		listening = false;

		for(BServerTimed st : stl) st.close();

		try {
			if(serverSocket != null) {
				serverSocket.close();
				serverSocket = null;
			}
		} catch (IOException ex) {
            log.severe("Could not close server on port: 7777. : " + ex);
        }
	}
}
