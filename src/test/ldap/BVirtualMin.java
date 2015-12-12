import java.io.InputStreamReader;
import java.io.Reader;
import java.io.IOException;
import java.net.URL;
import java.net.URLConnection;
import java.net.MalformedURLException; 
import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import java.security.cert.X509Certificate;
import java.security.NoSuchAlgorithmException;
import java.security.KeyManagementException; 
import java.net.Authenticator;
 
public class BVirtualMin {

    public boolean createDomain(String domainName, String passwd, String email) {
		boolean domainCreated = true;

		try {
			// Create a trust manager that does not validate certificate chains
			TrustManager[] trustAllCerts = new TrustManager[] {new X509TrustManager() {
					public java.security.cert.X509Certificate[] getAcceptedIssuers() {
						return null;
					}
					public void checkClientTrusted(X509Certificate[] certs, String authType) {
					}
					public void checkServerTrusted(X509Certificate[] certs, String authType) {
					}
				}
			};
	
			// Install the all-trusting trust manager
			SSLContext sc = SSLContext.getInstance("SSL");
			sc.init(null, trustAllCerts, new java.security.SecureRandom());
			HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
	
			// Create all-trusting host name verifier
			HostnameVerifier allHostsValid = new HostnameVerifier() {
				public boolean verify(String hostname, SSLSession session) {
					return true;
				}
			};
	
			// Install the all-trusting host verifier
			HttpsURLConnection.setDefaultHostnameVerifier(allHostsValid);

			Authenticator.setDefault(new MyAuthenticator());	 
			String cmd = "program=create-domain&domain=" + domainName + "&pass=" + passwd;
			cmd += "&desc=" + domainName + "&unix=&dir=&webmin=&web=&dns=&mail=";
			cmd += "&mysql=&limits-from-plan=&features-from-plan=";
			cmd += "&email=" + email;
			cmd += "&plan=Standard_WebHosting&template=Standard_WebHostingTPL";
			runCMD(cmd);

		} catch(NoSuchAlgorithmException ex) {
			System.out.println("Algorithim Error : " + ex);
			domainCreated = false;
		} catch(KeyManagementException ex) {
			System.out.println("Key Management Error : " + ex);
			domainCreated = false;
		}

		return domainCreated;
    }

	public boolean runCMD(String cmd) {
		boolean domainCreated = true;
		try {
			URL url = new URL("https://webhost.orange-business.co.ke:8443/virtual-server/remote.cgi?" + cmd);
			URLConnection con = url.openConnection();
			Reader reader = new InputStreamReader(con.getInputStream());
			while (true) {
				int ch = reader.read();
				if (ch==-1) {
					break;
				}
				System.out.print((char)ch);
			}
		} catch(MalformedURLException ex) {
			System.out.println("Malformed URL Error : " + ex);
			domainCreated = false;
		} catch(IOException ex) {
			System.out.println("IO Error : " + ex);
			domainCreated = false;
		}

		return domainCreated;
	}
}
