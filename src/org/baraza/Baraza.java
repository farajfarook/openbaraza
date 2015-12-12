/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza;

import java.io.InputStream;

import java.awt.BorderLayout;
import java.awt.event.WindowListener;
import java.awt.event.WindowEvent;

import java.util.logging.Logger;
import javax.swing.JFrame;
import javax.swing.JApplet;
import javax.swing.UIManager;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.utils.BDesEncrypter;
import org.baraza.app.BApp;
import org.baraza.ide.BIDE;
import org.baraza.server.BServer;
import org.baraza.server.BClient;

public class Baraza extends JApplet implements WindowListener {
	Logger log = Logger.getLogger(Baraza.class.getName());
	BApp app = null;
	BIDE ide = null;
	BServer server = null;
	BClient client = null;	

	JFrame frame;

	/**
	* Main class call
	*/
	public static void main(String args[]) {
		String mode = "run";
		String configDir = "./projects/";
		String dbpath = null;
		String configFile = null;
		String encryptionKey = null;
		if (args.length > 0) mode = args[0].trim();
		if (args.length > 1) configDir = args[1];
		if (args.length > 2) dbpath = args[2];
		if (args.length > 3) configFile = args[3];
		if (args.length > 4) encryptionKey = args[4];
		if(mode == null) mode = "run";

		Baraza baraza = null;
		if (args.length < 2) {
			System.out.println("Enter the proper comman arguments");
		} else if(mode.equals("server")) {
			BServer lserver = new BServer(configDir);
			lserver.start();
		} else if(mode.equals("stop")) {
			BClient lclient =  new BClient("stop", true, configDir);
		} else {
			baraza = new Baraza();
			baraza.run(configDir, mode, dbpath, configFile, encryptionKey);
		}
	}

	/**
	* Run the application - desktop mode
	* Use {@link #run(String, String, String)} run
	* 
	* @param configDir 		Directory where the configs are at
	* @param mode 			The running mode {client, ide, server }
	* @param dbpath 		override the xml database path
	*/
	public void run(String configDir, String mode, String dbpath, String configFile, String encryptionKey) {
		int sm = start(configDir, mode, dbpath, configFile, encryptionKey);
		if(sm < 2) {
			frame = new JFrame("Baraza Project");
			frame.addWindowListener(this);
			frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

			if(sm == 0) frame.getContentPane().add(app);
			else if(sm == 1) frame.getContentPane().add(ide);

			frame.setSize(1000, 800);
			frame.setVisible(true);
		}
	}

	/**
	* Run an applet
	*/
	public void init() {
		String config = getParameter("config");
		String mode = getParameter("mode");
		String dbpath = getParameter("dbpath");
		String configFile = getParameter("configfile");
		String encryptionKey = getParameter("encryptionkey");

		int sm = start(config, mode, dbpath, configFile, encryptionKey);
		if(sm == 0) getContentPane().add(app);
		else if(sm == 1) getContentPane().add(ide);
	}

	/**
	* Get start up parametrs and determine how the application starts
	* 
	* Use {@link #start(String, String, String)} start
	* 
	* @param configDir 		Directory where the configs are at
	* @param mode 			The running mode {client, ide, server }
	* @param dbpath 		override the xml database path
	* @return       		returns the selected run mode
	*/
	public int start(String configDir, String mode, String dbpath, String configFile, String encryptionKey) {
		int sm = 0;
		BXML xml = null;
		
		if(encryptionKey == null) {
			if(configFile == null) configFile = "config.xml";
			xml = new BXML(configDir + configFile, false);
		} else {
			if(configFile == null) configFile = "config.cph";

			// Create encrypter/decrypter class and encrypt
			BDesEncrypter decrypter = new BDesEncrypter(encryptionKey);
			InputStream inXml = decrypter.decrypt(configDir + configFile);

			xml = new BXML(inXml);
		}

		BElement root = xml.getRoot();
		if(mode != null) {
			if(mode.equals("run")) sm = 0;
			else if(mode.equals("develop")) sm = 1;
			else if(mode.equals("server")) sm = 2;
			else if(mode.equals("stop")) sm = 3;
		} else if(root.getAttribute("mode") != null) {
			if(root.getAttribute("mode").equals("run")) sm = 0; 
			else if(root.getAttribute("mode").equals("develop")) sm = 1;
			else if(root.getAttribute("mode").equals("server")) sm = 2;
		}

		try {
			UIManager.setLookAndFeel("com.sun.java.swing.plaf.nimbus.NimbusLookAndFeel");
			//UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
		} catch (Exception ex) {
			System.out.println("Error Loading the look : " + ex);
		}

		switch (sm) {
			case 0:			// Load the application
				app = new BApp(configDir, configFile, dbpath, encryptionKey);
				break;
            case 1:			// Load the IDE
				ide = new BIDE(configDir);
				break;
			case 2:
				server = new BServer(configDir);
				server.start();
				break;
			case 3:
				client =  new BClient("stop", true, configDir);
				break;
		}

		return sm;
	}

	public void windowDeactivated(WindowEvent ev) {}
	public void windowActivated(WindowEvent ev) {}
	public void windowDeiconified(WindowEvent ev) {}
	public void windowIconified(WindowEvent ev) {}
	public void windowOpened(WindowEvent ev) {}
	public void windowClosed(WindowEvent ev) {}
	public void windowClosing(WindowEvent ev) {
		close();
		frame.dispose();
		System.exit(0);
	}
	public void destroy() {
		close();
	}

	/**
	* Close application handles
	*/
	public void close() {
		if(app != null) app.close();
		if(ide != null) ide.close();
	}
}

