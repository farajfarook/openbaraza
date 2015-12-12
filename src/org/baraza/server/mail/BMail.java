/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.mail;

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

import org.baraza.xml.BElement;
import org.baraza.utils.BLogHandle;

public class BMail {
	Logger log = Logger.getLogger(BMail.class.getName());
	Session session = null;
	Store store = null;
	SMTPTransport trans = null;
	private boolean mailActive = false;
	private String mailfrom = null;
	private String sentbox = null;
	private String inbox = null;
	private String attachFile = null;
	private String attachDir = null;
	private boolean saveAttachments = false;
 	private int attnum = 1;	

	public BMail(BElement root, BLogHandle logHandle) {
		logHandle.config(log);
		String host = root.getAttribute("host", "");
		String imaphost = root.getAttribute("imaphost");
		int imapPort = 143;
		if(imaphost == null) imaphost = host;
		String mailuser = root.getAttribute("mailuser", "");
		String maildomain = root.getAttribute("maildomain");
		if(maildomain != null) mailuser = mailuser + "@" + maildomain;

		String mailpassword = root.getAttribute("mailpassword", "");
		mailfrom = root.getAttribute("mailfrom", "");
		inbox = root.getAttribute("inbox", "");
		sentbox = root.getAttribute("sentbox", "");

		String smtppauth = root.getAttribute("smtpauth", "false");
		smtppauth = root.getAttribute("smtppauth", smtppauth);
		String smtptls = root.getAttribute("smtptls", "false");
		String ntlm = root.getAttribute("ntlm", "false");
		String imapssl = root.getAttribute("imapssl", "false");
		String imapType = "imap";

		try {
    		// Get a Properties object
    		Properties props = System.getProperties();
			props.setProperty("mail.smtp.host", host);
			if (ntlm.equals("true")) {
				props.setProperty("mail.imap.auth.plain.disable", "true");
				props.setProperty("mail.imap.auth.ntlm.disable", "true");
				props.setProperty("mail.imaps.auth.ntlm.domain", "true");
			} else {
				System.clearProperty("mail.imap.auth.plain.disable");
				System.clearProperty("mail.imap.auth.ntlm.disable");
				System.clearProperty("mail.imaps.auth.ntlm.domain");
			}

			if (smtptls.equals("true")) {
				props.setProperty("mail.smtp.starttls.enable", "true");
				props.setProperty("mail.smtp.auth", "true");
				props.setProperty("mail.smtp.port", "587");

				MailSSLSocketFactory smtpSFactory= new MailSSLSocketFactory();
				smtpSFactory.setTrustAllHosts(true);
				props.put("mail.smtp.ssl.socketFactory", smtpSFactory);
			} else {
				System.clearProperty("mail.smtp.starttls.enable");
				System.clearProperty("mail.smtp.auth");
				System.clearProperty("mail.smtp.port");
				System.clearProperty("mail.smtp.ssl.socketFactory");
			}

			if(imapssl.equals("true")) {
				props.setProperty("mail.store.protocol", "imaps");
				props.setProperty("mail.imap.host", host);
				props.setProperty("mail.imap.port", "993");
				props.setProperty("mail.imap.connectiontimeout", "30000");
				props.setProperty("mail.imap.timeout", "30000");
				MailSSLSocketFactory socketFactory= new MailSSLSocketFactory();
				socketFactory.setTrustAllHosts(true);
				props.put("mail.imaps.ssl.socketFactory", socketFactory);

				props.setProperty("mail.imap.auth.plain.disable", "true");
				props.setProperty("mail.imap.starttls.enable", "true");
				imapType = "imaps";
				imapPort = 993;
			} else {
				props.setProperty("mail.store.protocol", "imap");
				props.setProperty("mail.imap.host", host);
				props.setProperty("mail.imap.port", "143");
				props.setProperty("mail.imap.connectiontimeout", "30000");
				props.setProperty("mail.imap.timeout", "30000");
				System.clearProperty("mail.imap.auth.plain.disable");
				System.clearProperty("mail.imap.starttls.enable");
				System.clearProperty("ssl.SocketFactory.provider");
				System.clearProperty("mail.imap.socketFactory.class");
			}

			// Get a Session object			
			session = Session.getInstance(props, null);
			session.setDebug(false);
			store = session.getStore(imapType);
			store.connect(imaphost, imapPort, mailuser, mailpassword);

			trans = (SMTPTransport)session.getTransport("smtp");
			if (smtppauth.equals("true") || smtptls.equals("true")) {
				props.put("mail.smtp.auth", "true");
		    	trans.connect(host, mailuser, mailpassword);
			} else {
				System.clearProperty("mail.smtp.auth");
		    	trans.connect();
			}
			mailActive = true;
		} catch (Exception ex) {
			log.severe("Mail User " + mailuser);
			log.severe("Mail exception! " + ex);
		}
	}

	public void setAttachFile(String fileDir, String fileName) {
		attachDir = fileDir;
		attachFile = fileName;
	}

	public boolean sendMail(String messageto, String subject, String mymail, boolean infile, Map<String, String> headers, Map<String, String> reports) {
		boolean sent = false;
		
		try { 
			Message message = new MimeMessage(session);

			Multipart mp = new MimeMultipart();
			MimeBodyPart eheader = new MimeBodyPart();
			eheader.setContent(mymail, "text/html");
			mp.addBodyPart(eheader);

			if (infile == true) {
				MimeBodyPart attachreport = new MimeBodyPart();
				if(attachFile == null) attachFile = "report.pdf";
				if(attachDir == null) attachDir = "./";
				attachreport.attachFile(attachDir + attachFile);
				attachreport.setFileName(attachFile);
				mp.addBodyPart(attachreport);
			}

			for(String report : reports.keySet()) {
				MimeBodyPart attachreport = new MimeBodyPart();
				if(attachFile == null) attachFile = report + ".pdf";
				if(attachDir == null) attachDir = "./";
				attachreport.attachFile(attachDir + attachFile);
				attachreport.setFileName(attachFile);
				mp.addBodyPart(attachreport);
			}
			
			Address fromAddress = new InternetAddress(mailfrom);
			message.setFrom(fromAddress);
			message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(messageto, false));

			message.setSubject(subject);
			//message.setContent(mymail, "text/html");
			message.setContent(mp);

			message.setHeader("X-Mailer", "Baraza Java Mailer");
			for (String key : headers.keySet()) {
				message.setHeader(key, headers.get(key));
			}
			message.setSentDate(new Date());

			log.fine("Sending Message to : " + messageto);
			trans.sendMessage(message, message.getAllRecipients());

			// Get record Folder.  Create if it does not exist.
			Folder folder = store.getFolder(sentbox);
			if (folder == null) {
		    	log.severe("Can't get record folder.");
		    	return false;
			}
			if (!folder.exists()) folder.create(Folder.HOLDS_MESSAGES);
			Message[] messages = new Message[1];
			messages[0] = message;
			folder.appendMessages(messages);

			log.fine("Mail was recorded successfully.");
			sent = true;
		} catch (Exception ex) {
	    	if (ex instanceof SendFailedException) {
				MessagingException sfe = (MessagingException)ex;
				if (sfe instanceof SMTPSendFailedException) {
					SMTPSendFailedException ssfe = (SMTPSendFailedException)sfe;
					String errMsg = "SMTP SEND FAILED : "+ ssfe.toString();
					errMsg += "\n  Command: " + ssfe.getCommand();
					errMsg += "\n  RetCode: " + ssfe.getReturnCode();
					errMsg += "\n  Response: " + ssfe.getMessage();
					log.severe(errMsg);
				} else {
					log.severe("Send failed: " + sfe.toString());
				}

				Exception ne = sfe.getNextException();
				if ((ne != null) && (ne instanceof MessagingException)) {
					sfe = (MessagingException)ne;
					if (sfe instanceof SMTPAddressFailedException) {
						SMTPAddressFailedException ssfe = (SMTPAddressFailedException)sfe;
						String errMsg = "ADDRESS FAILED : "+ ssfe.toString();
						errMsg += "\n  Address: " + ssfe.getAddress();
						errMsg += "\n  Command: " + ssfe.getCommand();
						errMsg += "\n  RetCode: " + ssfe.getReturnCode();
						errMsg += "\n  Response: " + ssfe.getMessage();
						log.severe(errMsg);
					} else if (sfe instanceof SMTPAddressSucceededException) {
						SMTPAddressSucceededException ssfe = (SMTPAddressSucceededException)sfe;
						String errMsg = "ADDRESS SUCCEEDED : " + ssfe.toString();
						errMsg += "\n  Address: " + ssfe.getAddress();
						errMsg += "\n  Command: " + ssfe.getCommand();
						errMsg += "\n  RetCode: " + ssfe.getReturnCode();
						errMsg += "\n  Response: " + ssfe.getMessage();
						log.fine(errMsg);
					}
				}
	    	} else {
				log.severe("Got Exception: " + ex);
	    	}
		}

		return sent;
	}

	public boolean getmail(boolean readmail) {
		return getmail(inbox, readmail);
	}

	public boolean getmail(String mailbox, boolean readmail) {
		boolean mailstatus = false;
		try {
			Folder folder = store.getDefaultFolder();
			if (folder != null) {
    			folder = folder.getFolder(mailbox);
			
				// try to open read/write and if that fails try read-only
				try {
    				folder.open(Folder.READ_WRITE);
				} catch (MessagingException ex) {
    				folder.open(Folder.READ_ONLY);
				}
				int totalMessages = folder.getMessageCount();
				int newMessages = folder.getNewMessageCount();
				mailstatus = true;

				if (readmail) readmail(folder);
				folder.close(false);
			}
		} catch (Exception ex) {
			log.severe("Oops, got mail exception! " + ex.getMessage());
    		ex.printStackTrace();
		}

		return mailstatus;
	}

	public void readmail(Folder folder) {
		try {
			// Attributes & Flags for all messages ..
			Message[] msgs = folder.getMessages();

			// Use a suitable FetchProfile
			FetchProfile fp = new FetchProfile();
			fp.add(FetchProfile.Item.ENVELOPE);
			fp.add(FetchProfile.Item.FLAGS);
			fp.add("X-Mailer");
			folder.fetch(msgs, fp);

			for (int i = 0; i < msgs.length; i++) {
				log.info("MESSAGE #" + (i + 1) + ":");
				dumpEnvelope(msgs[i]);	// Read the headers
				dumpPart(msgs[i]);		// read the message
		    }
		} catch (Exception ex) {
			log.severe("Oops, got mail exception! " + ex.getMessage());
    		ex.printStackTrace();
		}
	}

	public void dumpEnvelope(Message m) {
		try {
			log.info("This is the message envelope");
	
			// FROM 
			Address[] a = m.getFrom();		
			if (a != null) {
				for (int j = 0; j < a.length; j++)
					System.out.println("FROM: " + a[j].toString());
			}
	
			// TO
			a = m.getRecipients(Message.RecipientType.TO);
			if (a != null) {
				for (int j = 0; j < a.length; j++) {
					System.out.println("TO: " + a[j].toString());
					InternetAddress ia = (InternetAddress)a[j];
					if (ia.isGroup()) {
						InternetAddress[] aa = ia.getGroup(false);
						for (int k = 0; k < aa.length; k++)
							System.out.println("  GROUP: " + aa[k].toString());
					}
				}
			}
	
			// SUBJECT
			System.out.println("SUBJECT: " + m.getSubject());
	
			// DATE
			Date d = m.getSentDate();
			if(d!=null) System.out.println("SendDate: " + d.toString());
	
			// FLAGS
			Flags flags = m.getFlags();
			StringBuffer sb = new StringBuffer();
			Flags.Flag[] sf = flags.getSystemFlags(); // get the system flags
	
			boolean first = true;
			for (int i = 0; i < sf.length; i++) {
				String s;
				Flags.Flag f = sf[i];
				if (f == Flags.Flag.ANSWERED) s = "\\Answered";
				else if (f == Flags.Flag.DELETED) s = "\\Deleted";
				else if (f == Flags.Flag.DRAFT) s = "\\Draft";
				else if (f == Flags.Flag.FLAGGED) s = "\\Flagged";
				else if (f == Flags.Flag.RECENT) s = "\\Recent";
				else if (f == Flags.Flag.SEEN) s = "\\Seen";
				else continue;	// skip it
	
				if (first) first = false;
				else sb.append(' ');
				sb.append(s);
			}
	
			// get the user flag strings
			String[] uf = flags.getUserFlags();
			for (int i = 0; i < uf.length; i++) {
				if (first) first = false;
				else sb.append(' ');
				sb.append(uf[i]);
			}
			System.out.println("FLAGS: " + sb.toString());
	
			// X-MAILER
			String[] hdrs = m.getHeader("X-Mailer");
			if (hdrs != null)
				System.out.println("X-Mailer: " + hdrs[0]);
			else
				System.out.println("X-Mailer NOT available");
		} catch (MessagingException ex) {
			System.out.println("Message reading error " + ex);
		}
    }

	public void dumpPart(Part p) {
		try {
			if (p instanceof Message) dumpEnvelope((Message)p);
			String ct = p.getContentType();
	
			try {
				System.out.println("CONTENT-TYPE: " + (new ContentType(ct)).toString());
			} catch (ParseException pex) {
				System.out.println("BAD CONTENT-TYPE: " + ct);
			}
			String filename = p.getFileName();
			if (filename != null) System.out.println("FILENAME: " + filename);
	
			/** Using isMimeType to determine the content type avoids
			* fetching the actual content data until we need it. */
			if (p.isMimeType("text/plain")) {
				System.out.println("This is plain text");
				System.out.println("---------------------------");
				if (!saveAttachments) System.out.println((String)p.getContent());
			} else if (p.isMimeType("multipart/*")) {
				System.out.println("This is a Multipart");
				System.out.println("---------------------------");
				Multipart mp = (Multipart)p.getContent();
				int count = mp.getCount();
				for (int i = 0; i < count; i++) dumpPart(mp.getBodyPart(i));
			} else if (p.isMimeType("message/rfc822")) {
				System.out.println("This is a Nested Message");
				System.out.println("---------------------------");
				dumpPart((Part)p.getContent());
			} else {
				if (saveAttachments) {
					/** If we actually want to see the data, and it's not a
					* MIME type we know, fetch it and check its Java type. */
					Object o = p.getContent();
					if (o instanceof String) {
						System.out.println("This is a string");
						System.out.println("---------------------------");
						System.out.println((String)o);
					} else if (o instanceof InputStream) {
						System.out.println("This is just an input stream");
						System.out.println("---------------------------");
						InputStream is = (InputStream)o;
						int c;
						while ((c = is.read()) != -1) System.out.write(c);
					} else {
						System.out.println("This is an unknown type");
						System.out.println("---------------------------");
						System.out.println(o.toString());
					}
				} else { // just a separator
					System.out.println("---------------------------");
				}
			}
	
			/** If we're saving attachments, write out anything that
			* looks like an attachment into an appropriately named
			* file.  Don't overwrite existing files to prevent mistakes. */
			if (saveAttachments && !p.isMimeType("multipart/*")) {
				String disp = p.getDisposition();
				// many mailers don't include a Content-Disposition
				if (disp == null || disp.equalsIgnoreCase(Part.ATTACHMENT)) {
					if (filename == null) filename = "Attachment" + attnum++;
					System.out.println("Saving attachment to file " + filename);
					try {
						File f = new File(filename);
						if (f.exists())		// XXX - could try a series of names
							throw new IOException("file exists");
						((MimeBodyPart)p).saveFile(f);
					} catch (IOException ex) {
						System.out.println("Failed to save attachment: " + ex);
					}
					System.out.println("---------------------------");
				}
			}
		} catch (Exception ex) {
			System.out.println("Read message error " + ex);
		}
	}

	public boolean getActive() {
		return mailActive;
	}

	public void close() {
		try {
			if(trans != null) trans.close();
			if(store != null) store.close();
		} catch(MessagingException ex) {
			log.severe("Mail System closing error : " + ex);
		}
	}
}