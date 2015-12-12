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

import java.io.PrintWriter;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;

import java.net.Socket;
import java.net.UnknownHostException;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;

public class BClient {

    public BClient(String comm, boolean readFirst, String configDir) {
		Logger log = Logger.getLogger(BClient.class.getName());
		Socket kkSocket = null;
		PrintWriter out = null;
		BufferedReader in = null;
		BufferedReader stdIn = null;

		String fromServer;
		String fromClient;
        
		BXML xml = new BXML(configDir + "config.xml", false);
		BElement root = xml.getRoot();
		Integer portNumber = new Integer(root.getAttribute("port", "7777"));
        
		try {
			kkSocket = new Socket("localhost", portNumber.intValue());
			out = new PrintWriter(kkSocket.getOutputStream(), true);
			in = new BufferedReader(new InputStreamReader(kkSocket.getInputStream()));
			stdIn = new BufferedReader(new InputStreamReader(System.in));

			if(readFirst) {
				fromServer = in.readLine();
				log.info("Server : " + fromServer);
			}

			fromClient = comm;
			out.println(fromClient);
			log.info("Client : " + fromClient);

			fromServer = in.readLine();
			log.info("Server : " + fromServer);

			out.close();
			in.close();
			stdIn.close();
			kkSocket.close();
        } catch (UnknownHostException ex) {
            log.severe("Don't know about host: " + ex);
            System.exit(1);
        } catch (IOException ex) {
            log.severe("Couldn't get I/O for the connection to host : " + ex);
        }
    }
}
