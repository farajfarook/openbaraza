
import java.util.*;
import java.io.*;
import javax.naming.*;
import javax.naming.directory.*;
import javax.naming.ldap.LdapContext;

public class BKemsa {

	//String ldapServer = "ldap://jumbo.dewcis.com:389"; //"ldap://192.168.100.44:389";
	//String ldapPassword = "Simba9gk"; //"Daw@KE2014";

	String ldapServer = "ldap://192.168.100.44:389";
	String ldapPassword = "Daw@KE2014";

	public static void main (String[] args) {
		BKemsa kemsa = new BKemsa();
		kemsa.readDA();
	}

	public void readDA() {
		try {
			System.out.println("Active Directory, pulling");

			Map<String, String> userMap = new HashMap<String, String>();
			Hashtable<String, String> ldapEnv = new Hashtable<String, String>(11);
			ldapEnv.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			//ldapEnv.put(Context.PROVIDER_URL,  "ldap://NYATI.DEWCIS.COM:389");
			ldapEnv.put(Context.PROVIDER_URL,  "ldap://192.168.100.5:389");
			ldapEnv.put(Context.SECURITY_AUTHENTICATION, "simple");
			//ldapEnv.put(Context.SECURITY_PRINCIPAL, "CN=Administrator,CN=Users,DC=dewcis,DC=com");
			//ldapEnv.put(Context.SECURITY_CREDENTIALS, "Simba9gk");
			ldapEnv.put(Context.SECURITY_PRINCIPAL, "CN=test user,CN=Users,DC=kemsa,DC=co,DC=ke");
			ldapEnv.put(Context.SECURITY_CREDENTIALS, "Password2000");
			ldapEnv.put(Context.SECURITY_PROTOCOL, "simple");
			DirContext ldapContext = new InitialDirContext(ldapEnv);

			// Create the search controls         
			SearchControls searchCtls = new SearchControls();

			//Specify the attributes to return
			String returnedAtts[] = {"cn", "givenName", "icscalendar", "mail", "psroot", "sn", "samAccountName", "userPassword", "unicodePwd", "userAccountControl", "member", "distinguishedName"};
			searchCtls.setReturningAttributes(returnedAtts);

			//Specify the search scope
			searchCtls.setSearchScope(SearchControls.SUBTREE_SCOPE);

			//specify the LDAP search filter
			String groupFilter = "(&(objectClass=group))";
			String userFilter = "(&(objectClass=user))";

			//Specify the Base for the search
			String searchBase = "DC=kemsa,DC=co,DC=ke";
			//String searchBase = "dc=dewcis,dc=com";
			//initialize counter to total the results
			int totalResults = 0;

			// Search for groups
			NamingEnumeration<SearchResult> groupSearch = ldapContext.search(searchBase, groupFilter, searchCtls);
			while (groupSearch.hasMoreElements()) {
				SearchResult sr = (SearchResult)groupSearch.next();
				Attributes attrs = sr.getAttributes();
				if(attrs.get("mail") != null) {
					String email = (String)attrs.get("mail").get();
					String uid = (String)attrs.get("samAccountName").get();
					String disName = (String)attrs.get("distinguishedName").get();

					System.out.println(">>>>>>" + sr.getName());
					System.out.println("\t uid : " + uid); 
					System.out.println("\t Mail : " + email);
					System.out.println("\tdistinguishedName : " + disName);
					
					// Add to the user MAP
					//userMap.put(disName, uid);
				}
			}

			// Add users to to LDAP
			System.out.println("\n------------- USERS");
			NamingEnumeration<SearchResult> answer = ldapContext.search(searchBase, userFilter, searchCtls);
			while (answer.hasMoreElements()) {
				SearchResult sr = (SearchResult)answer.next();
				Attributes attrs = sr.getAttributes();

				if(attrs.get("mail") != null) {
					String email = (String)attrs.get("mail").get();
					String uid = (String)attrs.get("samAccountName").get();
					String disName = (String)attrs.get("distinguishedName").get();
					
					//if(email.equals("abraham.gumba@kemsa.co.ke")) {
					if(!attrs.get("userAccountControl").get().equals("514")) {
						System.out.println(">>>>>>" + sr.getName());
						System.out.println("\t" + attrs.get("samAccountName")); 
						System.out.println("\t Mail : " + email);
						System.out.println("\t" + attrs.get("distinguishedName"));
						System.out.println("\t" + attrs.get("userPassword"));
						System.out.println("\t" + attrs.get("unicodePwd"));
						System.out.println("\t" + attrs.get("cn"));
						System.out.println("\tdavuniqueid : " + UUID.randomUUID().toString());
						System.out.println("\t" + attrs.get("givenName"));
						System.out.println("\t" + attrs.get("icscalendar"));
						System.out.println("\t" + attrs.get("psroot"));
						System.out.println("\t" + attrs.get("sn"));
						System.out.println("\t" + attrs.get("userAccountControl"));

						// Delete the user first
						deleteEntry("uid=" + uid + ",ou=People,o=kemsa.co.ke,dc=kemsa,dc=co,dc=ke");

						// Add to the user MAP
						userMap.put(disName, uid);

						boolean is_succeded = makeUser("kemsa-common.ldif", attrs);
						if(is_succeded = false) System.exit(-1);

						totalResults++;
					}
				}
			}

			// Add Groups to to LDAP
			System.out.println("\n------------- GROUPS");
			NamingEnumeration<SearchResult> answerGroup = ldapContext.search(searchBase, groupFilter, searchCtls);
			while (answerGroup.hasMoreElements()) {
				SearchResult sr = (SearchResult)answerGroup.next();
				Attributes attrs = sr.getAttributes();

				if(attrs.get("mail") != null) {
					String email = (String)attrs.get("mail").get();
					String uid = (String)attrs.get("samAccountName").get();
					String cn = (String)attrs.get("cn").get();
					String disName = (String)attrs.get("distinguishedName").get();
					
					System.out.println(">>>>>>" + sr.getName());
					System.out.println("\t" + attrs.get("samAccountName")); 
					System.out.println("\t Mail : " + email);
					System.out.println("\t" + attrs.get("distinguishedName"));
					System.out.println("\t" + attrs.get("cn"));
					System.out.println("\tdavuniqueid : " + UUID.randomUUID().toString());
					System.out.println("\t" + attrs.get("givenName"));
					System.out.println("\t" + attrs.get("psroot"));
					System.out.println("\t" + attrs.get("sn"));

					// Delete the group first
					deleteEntry("cn=" + cn + ",ou=Groups,o=kemsa.co.ke,dc=kemsa,dc=co,dc=ke");

					boolean is_succeded = makeGroup("kemsa-group.ldif", attrs, userMap);
					if(is_succeded = false) System.exit(-1);
				}
			}

			System.out.println("Total results: " + totalResults); 
			ldapContext.close();
		} catch (NamingException ex) {
			System.out.println(" Search error: " + ex);
			ex.printStackTrace();
			System.exit(-1);
		}
	}

	public boolean makeUser(String fileName, Attributes personAttrs) {
		boolean is_succeded = true;

		try {
			Hashtable<String, String> env = new Hashtable<String, String>();
			env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			env.put(Context.PROVIDER_URL, ldapServer);
			env.put(Context.SECURITY_PRINCIPAL, "cn=Directory Manager");
			env.put(Context.SECURITY_CREDENTIALS, ldapPassword);
			String searchStr = "ou=People,o=kemsa.co.ke,dc=kemsa,dc=co,dc=ke";
			Context ctx = new InitialContext(env);
			LdapContext ln = (LdapContext)ctx.lookup(searchStr);
			Attributes attrs = new BasicAttributes(true); // case-ignore
			Attribute objclass = new BasicAttribute("objectclass");
			Attribute icsextendeduserprefs = new BasicAttribute("icsextendeduserprefs");
			Attribute nswmextendeduserprefs = new BasicAttribute("nswmextendeduserprefs");

			String uid = (String)personAttrs.get("samAccountName").get();
			String email = (String)personAttrs.get("mail").get();

			System.out.println("\nCreate the node : " + uid);
			attrs.put("cn", (String)personAttrs.get("cn").get());
			attrs.put("davuniqueid", UUID.randomUUID().toString());
			if(personAttrs.get("givenname") != null) attrs.put("givenname", (String)personAttrs.get("givenname").get());
			attrs.put("icscalendar", uid + "@kemsa.co.ke");
			attrs.put("mail", email);
			attrs.put("psroot", "ldap://mail.kemsa.co.ke:389/piPStoreOwner=" + uid + ",o=kemsa.co.ke,o=PiServerDb");
			attrs.put("uid", uid);
			attrs.put("userpassword", "Kemsa1!");
			if(personAttrs.get("sn") != null) attrs.put("sn", (String)personAttrs.get("sn").get());
			else attrs.put("sn", "kemsa");

			FileReader fr = new FileReader(fileName);
			BufferedReader br = new BufferedReader(fr);
			String s;
			while((s = br.readLine()) != null) {
				String sl[] = s.split(":");
				if(sl.length > 1) {
					String nt = sl[0].trim();
					String nv = s.substring(s.indexOf(":")+1, s.length()).trim();

System.out.println(nt + " : " + nv);

					if(nt.equals("objectclass")) {
						objclass.add(nv);
					} else if(nt.equals("icsextendeduserprefs")) {
						icsextendeduserprefs.add(nv);
					} else if(nt.equals("nswmextendeduserprefs")) {
						nswmextendeduserprefs.add(nv);
					} else {
						attrs.put(nt, nv);
					}
				}
			}
			br.close();
			fr.close();

			attrs.put(objclass);
			if(icsextendeduserprefs.size()>0) attrs.put(icsextendeduserprefs);
			if(nswmextendeduserprefs.size()>0) attrs.put(nswmextendeduserprefs);
			Context result = ln.createSubcontext("uid=" + uid, attrs);

			if(ln != null) ln.close();
			if(ctx != null) ctx.close();
		} catch (IOException ex) {
			System.out.println("File Read error : " + ex);
			is_succeded = false;
		} catch(NamingException ex) {
			System.out.println("Namming Exception : " + ex);
			is_succeded = false;
		}

		return is_succeded;
	}

	public boolean makeGroup(String fileName, Attributes personAttrs, Map<String, String> userMap) {
		boolean is_succeded = true;

		try {
			Hashtable<String, String> env = new Hashtable<String, String>();
			env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			env.put(Context.PROVIDER_URL, ldapServer);
			env.put(Context.SECURITY_PRINCIPAL, "cn=Directory Manager");
			env.put(Context.SECURITY_CREDENTIALS, ldapPassword);
			String searchStr = "ou=Groups,o=kemsa.co.ke,dc=kemsa,dc=co,dc=ke";
			Context ctx = new InitialContext(env);
			LdapContext ln = (LdapContext)ctx.lookup(searchStr);
			Attributes attrs = new BasicAttributes(true); // case-ignore
			Attribute objclass = new BasicAttribute("objectclass");
			Attribute uniqueMember = new BasicAttribute("uniqueMember");

			String uid = (String)personAttrs.get("samAccountName").get();
			String email = (String)personAttrs.get("mail").get();

			System.out.println("\nCreate the node : " + uid);
			attrs.put("cn", (String)personAttrs.get("cn").get());
			attrs.put("groupid", (String)personAttrs.get("cn").get());
			attrs.put("mail", email);
			attrs.put("nsUniqueId", UUID.randomUUID().toString());

			if(personAttrs.get("member") != null) {
				String member = null;
				for (NamingEnumeration members = personAttrs.get("member").getAll(); members.hasMore(); member = (String)members.next()) {
					if(userMap.get(member) != null) {
						System.out.println("uid=" + userMap.get(member) + ",ou=People,o=kemsa.co.ke,dc=kemsa,dc=co,dc=ke");
						uniqueMember.add("uid=" + userMap.get(member) + ",ou=People,o=kemsa.co.ke,dc=kemsa,dc=co,dc=ke");
					}
				}
			}

			FileReader fr = new FileReader(fileName);
			BufferedReader br = new BufferedReader(fr);
			String s;
			while((s = br.readLine()) != null) {
				String sl[] = s.split(":");
				if(sl.length > 1) {
					String nt = sl[0].trim();
					String nv = s.substring(s.indexOf(":")+1, s.length()).trim();

System.out.println(nt + " : " + nv);

					if(nt.equals("objectClass")) {
						objclass.add(nv);
					} else {
						attrs.put(nt, nv);
					}
				}
			}

			br.close();
			fr.close();

			attrs.put(objclass);
			if(uniqueMember.size()>0) attrs.put(uniqueMember);
			Context result = ln.createSubcontext("cn=" + uid, attrs);

			if(ln != null) ln.close();
			if(ctx != null) ctx.close();
		} catch (IOException ex) {
			System.out.println("File Read error : " + ex);
			is_succeded = false;
		} catch(NamingException ex) {
			System.out.println("Namming Exception : " + ex);
			is_succeded = false;
		}

		return is_succeded;
	}
	
	public void deleteEntry(String entryName) {

		try {
			Hashtable<String, String> env = new Hashtable<String, String>();
			env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			env.put(Context.PROVIDER_URL, ldapServer);
			env.put(Context.SECURITY_PRINCIPAL, "cn=Directory Manager");
			env.put(Context.SECURITY_CREDENTIALS, ldapPassword);
			Context ctx = new InitialContext(env);
			
			ctx.destroySubcontext(entryName);
			
		} catch(NamingException ex) {
			System.out.println("Namming Exception : " + ex);
		}
	}


}
