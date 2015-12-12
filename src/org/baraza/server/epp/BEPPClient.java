/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.epp;

import java.util.logging.Logger;
import java.util.List;
import java.io.FileInputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.IOException; 

import java.net.SocketAddress; 
import java.net.InetSocketAddress; 
import java.security.KeyStore; 
import java.security.NoSuchAlgorithmException;
import java.security.KeyStoreException;
import java.security.cert.CertificateException;
import java.security.KeyManagementException;
import javax.security.cert.X509Certificate;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.utils.BLogHandle;

public class BEPPClient { 
	Logger log = Logger.getLogger(BEPPClient.class.getName());
	private BElement root, root2;
	List<BElement> children;

	private BufferedReader stdin = new BufferedReader(new InputStreamReader(System.in)); 
	private SSLSocket socket; 
	private DataInputStream  dis; 
	private DataOutputStream dos;
	public int intAvail = 0;
	public String strAvail = null;
	
	public static void main(String[] args) { 
		BEPPClient client = new BEPPClient(); 
		client.domainCheck("example1.co.ke");
		client.close();
	}

	public BEPPClient() { 
		String configFile = "/root/baraza/projects/baraza/configs/epp.xml";
		BXML xml = new BXML(configFile, false);
		root = xml.getRoot();

		String server = root.getAttribute("server");

		int port = Integer.valueOf(root.getAttribute("port", "700"));
		int timeout = Integer.valueOf(root.getAttribute("timeout", "3000"));

		try {
			SSLSocketFactory factory = null; 
			SSLContext ctx = SSLContext.getInstance("TLS"); 

			// add KeyManagers if server checks client certificates    
			ctx.init(null, getTrustManagers(root), null); 
			factory = ctx.getSocketFactory();
	
			socket = (SSLSocket)factory.createSocket(); 
			socket.setSoTimeout(timeout); 
			SocketAddress addr = new InetSocketAddress(server, port); 
			socket.connect(addr, timeout); 
			System.out.println("Connected to " + socket.getRemoteSocketAddress()); 

			dis = new DataInputStream(socket.getInputStream()); 
			dos = new DataOutputStream(socket.getOutputStream()); 
			X509Certificate chain[] = socket.getSession().getPeerCertificateChain(); 
			for (int i = 0; i < chain.length; i++) { 
				System.out.println("peer-certificate " + i); 
				System.out.println(" Subject : " + chain[i].getSubjectDN().getName()); 
				System.out.println(" Issuer  : " + chain[i].getIssuerDN().getName()); 
			}
		} catch(NoSuchAlgorithmException ex) {
			System.out.println("Algorithm Error : " + ex);
		} catch(IOException ex) {
			System.out.println("IO Error : " + ex);
		} catch(KeyManagementException ex) {
			System.out.println("Key Management Error : " + ex);
		}

		System.out.println("\n\n");
		readEppString();

		BElement login = root.getElementByName("LOGIN");
		writeEppString(login.getFirst().toString());
		readEppString();
	}

	public String domainCheck(String domainname) {
		BElement check = root.getElementByName("CHECK");
		System.out.println("BASE 100 ");
		BElement node = new BElement("domain:name");
		node.setValue(domainname);
//		BElement node1 = new BElement("domain:name");
//		node1.setValue("sex.me.ke");
		check.getFirst().getFirst().getFirst().getFirst().addNode(node);
//		check.getFirst().getFirst().getFirst().getFirst().addNode(node1);

		System.out.println("BASE 110 " + check.getFirst().getFirst().getFirst().getFirst().toString());
		System.out.println("BASE 120 ");

		writeEppString(check.getFirst().toString());

		String rtn = readEppString();

		BXML xml2 = new BXML(rtn, true);
		root2 = xml2.getRoot();

		BElement rst = root2.getFirst().getElementByName("result");
		System.out.println(rst);

		BElement resData = root2.getFirst().getElementByName("resData").getFirst();
		System.out.println(resData);

		String domName = null;

		for(BElement el1 : resData.getElements()) {
			BElement dname = el1.getElementByName("domain:name");
			System.out.println("Status for : " + dname.getValue() + " : " + dname.getAttribute("avail"));
			intAvail = Integer.parseInt(dname.getAttribute("avail"));
			domName = dname.getValue().toString();

			if (Integer.valueOf(dname.getAttribute("avail")) < 1) {
//				domName = null;
				BElement dnameR = el1.getElementByName("domain:reason");
				strAvail = dnameR.getValue();
				System.out.println("Reason : " + dnameR.getValue());
			}
		}
		return domName;
	}

	public int getAvailable(){
		return intAvail;
	}

	public String getReason() {
		return strAvail;
	}

	public String domainRegister(String domainname) {
		BElement regs = root.getElementByName("REGISTER");
		System.out.println("BASE 300 ");
		BElement node2 = new BElement("domain:name");
		node2.setValue(domainname);
		regs.getFirst().getFirst().getFirst().getFirst().addNode(node2);

		System.out.println("BASE 310 " + regs.getFirst().getFirst().getFirst().getFirst().toString());
		System.out.println("BASE 320 ");

		writeEppString(regs.getFirst().toString());

		String rtn = readEppString();

		return rtn;
	}


	public void close() {
		System.out.println("closing the connection"); 

		BElement logout = root.getElementByName("LOGOUT");
		writeEppString(logout.getFirst().toString());
		readEppString();

		try {
			socket.close(); 		
		} catch(IOException ex) {
			System.out.println("IO Error : " + ex);
		}
	}

	private TrustManager[] getTrustManagers(BElement node) { 
		TrustManagerFactory tmf = null;
		String filename = node.getAttribute("keystore"); 
		String password = node.getAttribute("keypassword"); 
		try {
			KeyStore keyStore = KeyStore.getInstance("JKS"); 
			keyStore.load(new FileInputStream(filename), password.toCharArray()); 
			tmf = TrustManagerFactory.getInstance("SunX509"); 
			tmf.init(keyStore); 
		} catch(KeyStoreException ex) {
			System.out.println("Key Store error " + ex);
		} catch(NoSuchAlgorithmException ex) {
			System.out.println("Algorithim error " + ex);
		} catch(IOException ex) {
			System.out.println("IO error " + ex);
		} catch(CertificateException ex) {
			System.out.println("Certificate error " + ex);
		}

		return tmf.getTrustManagers(); 
	} 

	private String readEppString () { 
		String input = null;
		try {
			int len = dis.readInt(); 
			if (len > 4000) { 
				throw new IOException ("Indicated length is unlikely long: " + len); 
			} 
			//System.out.println("length of input: " + len + " bytes"); 
			len = len - 4; 
			byte bytes[] = new byte[len]; 
			dis.readFully(bytes,0,len); 

			input = new String(bytes,"UTF-8"); 
			//System.out.println("=========================================\n"); 
			//System.out.print (input); 
		} catch(IOException ex) {
			System.out.println("System error " + ex);
		}
		return input; 
	} 

	private void writeEppString (String output) { 
		try {
			byte[] bytes = output.getBytes("UTF-8"); 
			int len = bytes.length + 4; 
			System.out.println("==================================="); 
			System.out.println("sending " + len + " bytes"); 
			System.out.print(output); 
			dos.writeInt(len); 
			dos.write(bytes); 
		} catch(IOException ex) {
			System.out.println("System error " + ex);
		}
	} 

} 

