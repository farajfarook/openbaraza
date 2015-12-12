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


import com.etz.ws.*;

public class DQuery {

	public static void main(String args[]) {

		// Create a trust manager that does not validate certificate chains
		TrustManager[] trustAllCerts = new TrustManager[] {
			new X509TrustManager() {
				public X509Certificate[] getAcceptedIssuers() { return null; } 
				public void checkClientTrusted(X509Certificate[] certs, String authType) { } 
				public void checkServerTrusted( X509Certificate[] certs, String authType) { }
			}
		}; 

		// Install the all-trusting trust manager
		try {
			SSLContext sc = SSLContext.getInstance("SSL"); 
			sc.init(null, trustAllCerts, new java.security.SecureRandom()); 
			HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
		} catch (NoSuchAlgorithmException ex) {
		} catch (KeyManagementException ex) { }

		String terminalId = "0690000082";
		String transId = "117497";
		

		QueryService qs = new QueryService();
		Query qry = qs.getQueryPort();

		String reponse = qry.query(terminalId, transId);

		System.out.println("Query responce : " + reponse);

	}

}
