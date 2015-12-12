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
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.Date;

import javax.swing.JTextArea;

import org.baraza.xml.BElement;

public class BLogHandle extends Handler {
	JTextArea statusBar = null;
	String logFile = null;
	Level logLevel = Level.INFO;

	public BLogHandle() {
		statusBar = new JTextArea();
	}

	public BLogHandle(JTextArea statusBar) {
		this.statusBar = statusBar;
	}

	public BLogHandle(BElement root) {
		logFile = root.getAttribute("logfile");
		setLogLevel(root);
	}

	public BLogHandle(String logFile) {
		super();
		this.logFile = logFile;
	}

	public void setLogLevel(BElement root) {
		logLevel = Level.parse(root.getAttribute("loglevel", "INFO").toUpperCase());
	}

	public void setLogLevel(Level logLevel) {
		this.logLevel = logLevel;
	}

	public void config(Logger logger) {
		removeHandle(logger);
		if(statusBar != null) {
			BLogHandle nlgh = new BLogHandle(statusBar);
			nlgh.setLogLevel(logLevel);
			logger.addHandler(nlgh);
		} else {
			BLogHandle nlgh = new BLogHandle(logFile);
			nlgh.setLogLevel(logLevel);
			logger.addHandler(nlgh);
		}

		logger.setUseParentHandlers(false);
		logger.setLevel(logLevel);
	}

	public void removeHandle(Logger logger) {
		Handler[] myha = logger.getHandlers();
		for(Handler myh : myha) {
			logger.removeHandler(myh);
		}
	}

	public JTextArea getStatusBar() {
		return statusBar;
	}

	public void publish(LogRecord logRecord) {
		Date date = new Date();
		String errDf = date.toString() + " " + logRecord.getSourceClassName() + " ";
		errDf += logRecord.getSourceMethodName() + "\n";
		String errMsg = logRecord.getLevel() + " : " + logRecord.getMessage();

		if(logFile != null) {
			Bio io = new Bio();
			errMsg = errDf + errMsg + "\n";
			io.saveFile(logFile, errMsg, true);
		} else if(statusBar != null) {
			statusBar.setText(errMsg);
		} else {
			System.out.println(errDf + errMsg);
		}
	}

	public void flush() {}
	public void close() {}

}
 
 
