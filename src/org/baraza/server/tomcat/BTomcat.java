/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.tomcat;

import java.util.logging.Logger;
import java.io.File;
import java.io.IOException;
import javax.servlet.ServletException;
import java.net.MalformedURLException;

import org.apache.catalina.startup.Tomcat;
import org.apache.catalina.core.StandardServer;
import org.apache.catalina.core.AprLifecycleListener;
import org.apache.catalina.Context;
import org.apache.catalina.LifecycleException;
import org.apache.catalina.deploy.ApplicationParameter;

import org.baraza.DB.BDB;
import org.baraza.xml.BElement;
import org.baraza.utils.BLogHandle;

public class BTomcat extends Thread {
	Logger log = Logger.getLogger(BTomcat.class.getName());
	Tomcat tomcat = null;

	public BTomcat(BDB db, BElement root, BLogHandle logHandle, String projectDir) {
		String ps = System.getProperty("file.separator");
		String basePath = root.getAttribute("base.path", getCurrentDir());
		String baseDir = basePath + ps + root.getAttribute("base.dir") + ps;
		String appBase = baseDir + root.getAttribute("app.base") + ps;
		String repository = root.getAttribute("repository") + ps;
		String contextPath = root.getAttribute("contextPath");
		Integer port = new Integer(root.getAttribute("port", "9876"));

		try {
			tomcat = new Tomcat();
			tomcat.setPort(port);
			tomcat.setBaseDir(baseDir);
			tomcat.enableNaming();

			// Add AprLifecycleListener
			StandardServer server = (StandardServer)tomcat.getServer();
			AprLifecycleListener listener = new AprLifecycleListener();
			server.addLifecycleListener(listener);

			Context context = tomcat.addWebapp(contextPath, appBase);
			String contextFile = appBase + "META-INF" + ps + "context.xml";
			if(root.getAttribute("context") != null) contextFile = projectDir + ps + "configs" + ps + root.getAttribute("context");
			File configFile = new File(contextFile);
			context.setConfigFile(configFile.toURI().toURL());
			context.addParameter("projectDir", projectDir);
			if(root.getAttribute("init.xml") != null) 
				context.addParameter("init_xml", root.getAttribute("init.xml"));
			
			if(repository != null) {
				Context rpContext = tomcat.addWebapp("/repository", baseDir + repository);
				File rpConfigFile = new File(baseDir + repository + "META-INF" + ps + "context.xml");
				rpContext.setConfigFile(rpConfigFile.toURI().toURL());
			}

			tomcat.start();
		} catch(javax.servlet.ServletException ex) {
			log.severe("Tomcat startuo error : " + ex);
		} catch(MalformedURLException ex) {
			log.severe("Tomcat URL Malformation : " + ex);
		} catch(LifecycleException ex) {
			log.severe("Tomcat Life cycle error : " + ex);
		}
		
		this.start();
	}

	public String getCurrentDir() {
		File directory = new File (".");
		String dirName = null;
		try {
			dirName = directory.getCanonicalPath();
		} catch(IOException ex) {
			log.severe("Current directory get error : " + ex);
		}
		return dirName;
	}

	public void run() {
		tomcat.getServer().await();
	}

	public void close() {
		try {
			tomcat.stop();
		} catch(LifecycleException ex) {
			log.severe("Tomcat Life cycle error : " + ex);
		}
	}
}

