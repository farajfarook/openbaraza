import javax.security.auth.callback.*;
import java.io.IOException;
import java.io.BufferedReader;
import java.io.InputStreamReader;

public class SampleCallbackHandler implements CallbackHandler {
	public void handle(Callback[] callbacks) throws java.io.IOException, UnsupportedCallbackException {
		for (int i = 0; i < callbacks.length; i++) {
			if (callbacks[i] instanceof NameCallback) {
				NameCallback cb = (NameCallback)callbacks[i];
				cb.setName(getInput(cb.getPrompt()));
			} else if (callbacks[i] instanceof PasswordCallback) {
				PasswordCallback cb = (PasswordCallback)callbacks[i];

				String pw = getInput(cb.getPrompt());
				char[] passwd = new char[pw.length()];
				pw.getChars(0, passwd.length, passwd, 0);

				cb.setPassword(passwd);
			} else {
				throw new UnsupportedCallbackException(callbacks[i]);
			}
		}
	}

	private String getInput(String prompt) throws IOException {
		System.out.print(prompt);
		BufferedReader in = new BufferedReader(
		new InputStreamReader(System.in));
		return in.readLine();
	}

	public static void main(String[] args) throws IOException, UnsupportedCallbackException {
		// Test handler
		CallbackHandler ch = new SampleCallbackHandler();
		Callback[] callbacks = new Callback[]{
		new NameCallback("user id:"),
		new PasswordCallback("password:", true)};

		ch.handle(callbacks);
	}
}

