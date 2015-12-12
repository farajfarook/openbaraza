/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.naming.Context;

import javax.mail.Session;
import javax.mail.Message;
import javax.mail.Transport;
import javax.mail.MessagingException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.AddressException;
import javax.mail.internet.MimeMessage;
import java.util.Enumeration;

public class BWebMail {
	Session session;
	
	public BWebMail() {
		try {
			Context initCtx = new InitialContext();
			Context envCtx = (Context) initCtx.lookup("java:comp/env");
			session = (Session) envCtx.lookup("mail/Session");
        } catch (NamingException ex) {
         	System.err.println("Cannot pick on the name : " + ex);
		}
	}

	public void sendmail(String fromaddr, String toaddr, String subject, String content) {
		System.out.println("Mail sending");
		try {
			Message message = new MimeMessage(session);
			message.setFrom(new InternetAddress(fromaddr));
			InternetAddress to[] = new InternetAddress[1];
			to[0] = new InternetAddress(toaddr);
			message.setRecipients(Message.RecipientType.TO, to);
			message.setSubject(subject);
			message.setContent(content, "text/html");
			Transport.send(message);
        } catch (AddressException ex) {
         	System.err.println("Address Error : " + ex);
        } catch (MessagingException ex) {
         	System.err.println("Messaging Error : " + ex);
		}
	}
}