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

import org.baraza.utils.BLogHandle;

public class BServerThread extends Thread {
	Logger log = Logger.getLogger(BServerThread.class.getName());
	public BServer server;
	Socket socket = null;
	String greeting;
	boolean readFirst;
	String HTML_START = "<html>\n<title>Open Baraza Server</title>\n<body>\n";
	String HTML_END = "</body>\n</html>\n";

	public BServerThread(Socket socket, BServer server, String greeting, BLogHandle logHandle) {
		super("DServerThread");

		logHandle.config(log);
		this.socket = socket;
		this.server = server;
		this.greeting = greeting;
    }

    public void run() {
		log.info("Accepted connection");

		try {
			PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
			BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
			String inputLine = "";
			String outputLine = "";

			if(greeting != null) {
				outputLine = greeting;
				out.println(outputLine);
				log.info("Server : " + outputLine);
			}

			boolean stopserver = false;
			while ((inputLine = in.readLine()) != null) {
				log.info("Server : " + inputLine);
				if (inputLine.equals("stop")) {
					out.println("stopping server");
					log.info("Server : stopping server");
					stopserver = true;
					break;
				} else if (inputLine.equals("close")) {
					out.println("closing client connection");
					log.info("Server : closing client connection");
					break;
				} else if (inputLine.equals("quit")) {
					out.println("closing client connection");
					log.info("Server : closing client connection");
					break;
				} else if (inputLine.toLowerCase().startsWith("get")) {				
					// Read the HTTP complete HTTP Query
					while (in.ready()) {
						inputLine = in.readLine();
						log.info(inputLine);
					}
					out.println(HTML_START);
					out.println("Open Baraza Server");
					out.println(HTML_END);
					break;	
				} else if (inputLine.toLowerCase().startsWith("post")) {
					// Read the HTTP complete HTTP Query
					while (in.ready()) {
						inputLine = in.readLine();
						log.info(inputLine);
						if (inputLine.indexOf("Content-Length:") != -1) break;
					}
					out.println(HTML_START);
					out.println("Open Baraza Server");
					out.println(HTML_END);
					break;
				} else {
					out.println("OK");
					log.info("Server : OK");
				}
			}

			out.close();
			in.close();
			socket.close();

			if(stopserver) {
				out.println("Stopping Server");
				server.close();
			}
        } catch (IOException ex) {
            log.severe("Could not listen on port: 4444 : " + ex);
        }
    }
}
