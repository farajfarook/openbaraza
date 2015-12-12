
import java.util.*;
import java.io.*;
import javax.naming.*;
import javax.naming.directory.*;
import javax.naming.ldap.LdapContext;

public class BPurge {

	String ldapServer = "ldap://jumbo.dewcis.com:389"; 
	String ldapPrincipals = "cn=Directory Manager";
	String ldapPassword = "Simba9gk"; 
	String searchBase = "o=testdelete.co.ke,dc=dewcis,dc=com";
	String searchScope = "ou=People";

	public static void main (String[] args) {
		BPurge purge = new BPurge();
		purge.readDA();
	}

	public void readDA() {
		try {
			System.out.println("Active Directory, pulling");

			Map<String, String> userMap = new HashMap<String, String>();
			Hashtable<String, String> ldapEnv = new Hashtable<String, String>(11);
			ldapEnv.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			ldapEnv.put(Context.PROVIDER_URL,  ldapServer);
			ldapEnv.put(Context.SECURITY_PRINCIPAL, ldapPrincipals);
			ldapEnv.put(Context.SECURITY_CREDENTIALS, ldapPassword);
			ldapEnv.put(Context.SECURITY_PROTOCOL, "simple");
			Context ctx = new InitialContext(ldapEnv);

			LdapContext ln = (LdapContext)ctx.lookup(searchBase);
			NamingEnumeration list = ln.list(searchScope);
			while (list.hasMore()) {
				NameClassPair nc = (NameClassPair)list.next();
				System.out.println("=================================================");
				System.out.println(nc.getName());

				boolean deleteUser = false;
				String uid = null;
				Attributes answer = ln.getAttributes(nc.getName() + "," + searchScope);
				for (NamingEnumeration ae = answer.getAll(); ae.hasMore();) {
					Attribute attr = (Attribute)ae.next();
					String attrID = attr.getID();
					System.out.println("\t" + attrID + " = " + attr.get());
					if(attrID.equals("uid")) uid = attr.get().toString();
					if(attrID.equals("inetUserStatus")) {
						if(attr != null) {
							if(attr.get().toString().equals("deleted")) deleteUser = true;
						}
					}
				}
				
				// clear user on LDAP marked for deletetion
				if(deleteUser) deleteEntry("uid=" + uid + "," + searchScope + "," + searchBase);

			}

			ln.close();
		} catch (NamingException ex) {
			System.out.println(" Search error: " + ex);
			ex.printStackTrace();
			System.exit(-1);
		}
	}
	
	public void deleteEntry(String entryName) {

		try {
			Hashtable<String, String> env = new Hashtable<String, String>();
			env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			env.put(Context.PROVIDER_URL, ldapServer);
			env.put(Context.SECURITY_PRINCIPAL, ldapPrincipals);
			env.put(Context.SECURITY_CREDENTIALS, ldapPassword);
			Context ctx = new InitialContext(env);
			
			System.out.println("Deleteting : " + entryName);
			ctx.destroySubcontext(entryName);

			ctx.close();
		} catch(NamingException ex) {
			System.out.println("Namming Exception : " + ex);
		}
	}


}
