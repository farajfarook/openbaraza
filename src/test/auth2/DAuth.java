import javax.security.auth.login.*;
import javax.security.auth.callback.*;

public class DAuth implements CallbackHandler {
	String username;
	char[] password;

	public static void main(String args[]) {
		String jaas = "jaas.config";
		System.setProperty("java.security.auth.login.config", jaas);

		String pw = "Imis1go";
		char[] passwd = new char[pw.length()];
		pw.getChars(0, passwd.length, passwd, 0);

		DAuth auth = new DAuth();
		auth.setAuth("imisadmin", passwd);
		boolean loggedin = auth.doLogin();

		System.out.println("BASE 1010 : " + loggedin);
	}

	public boolean doLogin() {
		boolean mylogin = false;

		try {
			DAuth auth = new DAuth();
			auth.setAuth(username, password);
			LoginContext lc = new LoginContext("cck", auth);
			lc.login();
			mylogin = true;
		} catch(LoginException ex) {
			System.out.println("Login error : " + ex);
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
					System.out.println(toc.getMessage());
					break;
				case TextOutputCallback.ERROR:
					System.out.println("ERROR: " + toc.getMessage());
					break;
				case TextOutputCallback.WARNING:
					System.out.println("WARNING: " + toc.getMessage());
					break;
				default:
					System.out.println("Unsupported message type: " + toc.getMessageType());
					break;
				}
			} else if (callbacks[i] instanceof NameCallback) { 		// prompt the user for a username
				NameCallback nc = (NameCallback)callbacks[i];
				nc.setName(username);
			} else if (callbacks[i] instanceof PasswordCallback) { 			// prompt the user for sensitive information
				PasswordCallback pc = (PasswordCallback)callbacks[i];
				pc.setPassword(password);
			} else {
				System.err.println("Unrecognized Callback" + callbacks[i]);
			}
 	    }
	}
}

