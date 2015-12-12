import java.net.InetAddress;
import java.net.Authenticator;
import java.net.PasswordAuthentication;

public class MyAuthenticator extends Authenticator {
    // This method is called when a password-protected URL is accessed
    protected PasswordAuthentication getPasswordAuthentication() {
        // Get information about the request
        String promptString = getRequestingPrompt();
        String hostname = getRequestingHost();
        InetAddress ipaddr = getRequestingSite();
        int port = getRequestingPort();

        // Get the username from the user...
        String username = "root";

        // Get the password from the user...
        String password = "keJ@mb01";

        // Return the information
        return new PasswordAuthentication(username, password.toCharArray());
    }
}
