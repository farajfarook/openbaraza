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

import javax.security.auth.login.LoginContext;
import javax.security.auth.login.LoginException;
import javax.security.auth.callback.Callback;
import javax.security.auth.callback.PasswordCallback;
import javax.security.auth.callback.NameCallback;
import javax.security.auth.callback.TextOutputCallback;
import javax.security.auth.callback.CallbackHandler;

public class BAuth implements CallbackHandler {
	Logger log = Logger.getLogger(BAuth.class.getName());
	String username;
	char[] password;

	public boolean doLogin() {
		boolean mylogin = false;

		try {
			BAuth auth = new BAuth();
			auth.setAuth(username, password);
			LoginContext lc = new LoginContext("baraza", auth);
			lc.login();
			mylogin = true;
		} catch(LoginException ex) {
			log.severe("Login error : " + ex);
		}

		return mylogin;
	}

	public void setAuth(String uname, char[] passwd) {
		username = uname;
		password = passwd;
	}

	public void handle(Callback[] callbacks) {
		for (int i = 0; i < callbacks.length; i++) {
			if (callbacks[i] instanceof TextOutputCallback) {	// display the message according to the specified type
				TextOutputCallback toc = (TextOutputCallback)callbacks[i];
				switch (toc.getMessageType()) {
				case TextOutputCallback.INFORMATION:
					log.severe(toc.getMessage());
					break;
				case TextOutputCallback.ERROR:
					log.severe("ERROR: " + toc.getMessage());
					break;
				case TextOutputCallback.WARNING:
					log.severe("WARNING: " + toc.getMessage());
					break;
				default:
					log.severe("Unsupported message type: " + toc.getMessageType());
					break;
				}
			} else if (callbacks[i] instanceof NameCallback) { 		// prompt the user for a username
				NameCallback nc = (NameCallback)callbacks[i];
				nc.setName(username);
			} else if (callbacks[i] instanceof PasswordCallback) { 			// prompt the user for sensitive information
				PasswordCallback pc = (PasswordCallback)callbacks[i];
				pc.setPassword(password);
			} else {
				log.severe("Unrecognized Callback" + callbacks[i]);
			}
 	    }
	}
}

