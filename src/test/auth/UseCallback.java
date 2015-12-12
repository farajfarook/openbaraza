import javax.naming.*;
import javax.naming.directory.*;

import java.util.Hashtable;

/**
 * Demonstrates how to create an initial context to an LDAP server
 * using CRAM-MD5 authentication and a callback to supply the
 * authentication ID and credentials. Uses SampleCallbackHandler.
 *
 * usage: java UseCallback
 */
class UseCallback {
	public static void main(String[] args) throws java.io.IOException {

		// Set up environment for creating initial context
		Hashtable env = new Hashtable();
		env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
		env.put(Context.PROVIDER_URL, "ldap://172.100.3.35:389/o=cck.go.ke,dc=cck,dc=go,dc=ke");

		// Authenticate as C. User and password "mysecret"
		env.put(Context.SECURITY_AUTHENTICATION, "simple");
		env.put(Context.SECURITY_PRINCIPAL, "cn=Directory Manager");
		env.put(Context.SECURITY_CREDENTIALS, "Imis1goke");

		// Specify callback to use for fetching authentication id/password
		env.put("java.naming.security.sasl.callback",  new SampleCallbackHandler());

		try {
			// Create initial context
			DirContext ctx = new InitialDirContext(env);

			System.out.println(ctx.lookup("ou=People"));

			// do something useful with ctx

			// Close the context when we're done
			ctx.close();
		} catch (NamingException e) {
			e.printStackTrace();
		}
	}
}


