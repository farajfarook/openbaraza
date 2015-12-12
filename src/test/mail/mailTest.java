import java.util.Properties;
import java.util.Map;
import java.util.Date;
import java.util.logging.Logger;
import java.io.File;
import java.io.InputStream;
import java.io.IOException;
import java.net.InetAddress;
import javax.mail.*;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;
import javax.mail.internet.ParseException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.ContentType;
import javax.mail.internet.MimeBodyPart;
import com.sun.mail.util.MailSSLSocketFactory;
import com.sun.mail.smtp.SMTPTransport;
import com.sun.mail.smtp.SMTPSendFailedException;
import com.sun.mail.smtp.SMTPAddressFailedException;
import com.sun.mail.smtp.SMTPAddressSucceededException;

public class mailTest {

	public static void main(String args[]) {
		String host = "192.168.100.4";
		String imaphost = "192.168.100.4";
		String imapPort = "143";
		String mailuser = "david.laisa";
		String mailpassword = "Techno9%";
		String imapType = "imap";

		Properties props = System.getProperties();
		props.setProperty("mail.smtp.host", host);

		props.setProperty("mail.store.protocol", "imap");
		props.setProperty("mail.imap.host", host);
		props.setProperty("mail.imap.port", "143");
		props.setProperty("mail.imap.connectiontimeout", "30000");
		props.setProperty("mail.imap.timeout", "30000");

		// Get a Session object
		try {
			Session session = Session.getInstance(props, null);
			session.setDebug(false);
			Store store = session.getStore(imapType);
			store.connect(imaphost, imapPort, mailuser, mailpassword);			
		} catch (Exception ex) {
			System.out.println("Mail exception :  " + ex);
		}
	}
}


