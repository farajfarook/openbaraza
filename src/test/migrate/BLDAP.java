import java.util.*;
import java.io.*;
import javax.naming.*;
import javax.naming.directory.*;
import javax.naming.ldap.LdapContext;
import java.util.Hashtable;

public class BLDAP {

	public static void main(String args[]) {
		BLDAP ldap = new BLDAP();
		//ldap.migrateDomains();
		ldap.readData("import");
	}

	public void migrateDomains() {
		try {
			FileReader fr = new FileReader("domains.txt");
			BufferedReader br = new BufferedReader(fr);
			String s;
			while((s = br.readLine()) != null) {
				System.out.println(s);
				readData(s);
			}
			br.close();
			fr.close();
		} catch (IOException ex) {
			System.out.println("File Read error : " + ex);
		}
	}

	public void readData(String domainName) {
		String fileContent = "";
		String estr[] = {"givenname", "sn", "cn", "uid", "userpassword", "mail", "mailalternate", "departmentnumber", "title", "description", "telephonenumber", "street", "facsimiletelephonenumber", "postalcode", "postofficebox", "l", "st", "nswmextendeduserprefs", "nswmextendeduserprefs", "mailsieverulesource", "maildeliveryoption", "mailforwardingaddress", "userpassword", "mailautoreplytext", "mailautoreplysubject", "vacationstartdate", "vacationenddate"};
		List<String> eList = Arrays.asList(estr);

		System.out.println("Reading domain : " + domainName);
		
		try {
			Hashtable<String, String> env = new Hashtable<String, String>();
			env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			env.put(Context.PROVIDER_URL, "ldap://192.168.0.6:389");
			env.put(Context.SECURITY_PRINCIPAL, "cn=Directory Manager");
			env.put(Context.SECURITY_CREDENTIALS, "Simba9gk");
			Context ctx = new InitialContext(env);

			String searchStr = "o=" + domainName + ",dc=ardhi,dc=go,dc=ke";
			LdapContext ln = (LdapContext)ctx.lookup(searchStr);
			//makeDomain("org_migration.ldif", domainName);

			NamingEnumeration list = ln.list("ou=People");
			LdapContext pln = (LdapContext)ctx.lookup("ou=People," + searchStr);

			while (list.hasMore()) {
				NameClassPair nc = (NameClassPair)list.next();
				System.out.println("=================================================");
				System.out.println(nc.getName());

				Attributes attrs = new BasicAttributes(true); // case-ignore
				Attributes answer = ln.getAttributes(nc.getName() + ",ou=People");
				for (NamingEnumeration ae = answer.getAll(); ae.hasMore();) {
					Attribute attr = (Attribute)ae.next();
					String attrID = attr.getID();
					if(eList.contains(attrID.toLowerCase())) {
						System.out.println("attribute: " + attrID);
						Attribute objclass = new BasicAttribute(attrID);

						// Print each value 
						for (NamingEnumeration e = attr.getAll(); e.hasMore();) {
							Object objVal = e.next();
							System.out.println("value: " + objVal.toString());
							objclass.add(objVal);
						}
						attrs.put(objclass);
					}
				}

				makePerson("sysadmin.ldif", "ardhi.go.ke", nc.getName(), answer);
			}
		} catch(NamingException ex) {
			System.out.println("Namming Exception : " + ex);
		}
	}
	
	public void makeDomain(String fileName, String domainName) {
		try {
			Hashtable<String, String> env = new Hashtable<String, String>();
			env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			env.put(Context.PROVIDER_URL, "ldap://192.168.0.6:389");
			env.put(Context.SECURITY_PRINCIPAL, "cn=Directory Manager");
			env.put(Context.SECURITY_CREDENTIALS, "Simba9gk");
			String searchStr = "o=jamboProviderDomainsRoot,o=business,dc=orange-business,dc=co,dc=ke";
			Context ctx = new InitialContext(env);
			LdapContext ln = (LdapContext)ctx.lookup(searchStr);
			Attributes attrs = new BasicAttributes(true); // case-ignore
			Attribute objclass = new BasicAttribute("objectclass");
			Attribute sunAvailableServices = new BasicAttribute("sunAvailableServices");
			Attribute sunRegisteredServiceName = new BasicAttribute("sunRegisteredServiceName");

			FileReader fr = new FileReader(fileName);
			BufferedReader br = new BufferedReader(fr);
			String s;
			while((s = br.readLine()) != null) {
				String sl[] = s.split(":");
				if(sl.length > 1) {
					String nt = sl[0].trim();
					String nv = s.substring(s.indexOf(":")+1, s.length()).trim().replace("domain.co.ke", domainName);

					if(nt.equals("dn")) {
						System.out.println("Create the node : " + nv);
						attrs.put(objclass);
						if(sunAvailableServices.size()>0) attrs.put(sunAvailableServices);
						if(sunRegisteredServiceName.size()>0) attrs.put(sunRegisteredServiceName);
						Context result = ln.createSubcontext(nv, attrs);

						attrs = new BasicAttributes(true); // case-ignore
						objclass = new BasicAttribute("objectclass");
						sunAvailableServices = new BasicAttribute("sunAvailableServices");
						sunRegisteredServiceName = new BasicAttribute("sunRegisteredServiceName");
					} else if(nt.equals("objectClass")) {
						objclass.add(nv);
					} else if(nt.equals("sunAvailableServices")) {
						sunAvailableServices.add(nv);
					} else if(nt.equals("sunRegisteredServiceName")) {
						sunRegisteredServiceName.add(nv);
					} else {
						//System.out.println(nt + " : " + nv);
						attrs.put(nt, nv);
					}
				}
			}
			br.close();
			fr.close();

			if(ln != null) ln.close();
			if(ctx != null) ctx.close();
		} catch (IOException ex) {
			System.out.println("File Read error : " + ex);
		} catch(NamingException ex) {
			System.out.println("Namming Exception : " + ex);
		}
	}

	public void copyPerson(String fileName, String domainName, String userName, Attributes attrs) {
		try {
			Hashtable<String, String> env = new Hashtable<String, String>();
			env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			env.put(Context.PROVIDER_URL, "ldap://192.168.0.6:389");
			env.put(Context.SECURITY_PRINCIPAL, "cn=Directory Manager");
			env.put(Context.SECURITY_CREDENTIALS, "Simba9gk");
			Context ctx = new InitialContext(env);
			String searchStr = "o=" + domainName + ",dc=ardhi,dc=go,dc=ke";
			LdapContext ln = (LdapContext)ctx.lookup(searchStr);
			Attribute objclass = new BasicAttribute("objectclass");

			FileReader fr = new FileReader(fileName);
			BufferedReader br = new BufferedReader(fr);
			String s;
			while((s = br.readLine()) != null) {
				String sl[] = s.split(":");
				if(sl.length > 1) {
					String nt = sl[0].trim();
					String nv = s.substring(s.indexOf(":")+1, s.length()).trim();

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
			Context result = ln.createSubcontext(userName + ",ou=People", attrs);

			if(ln != null) ln.close();
			if(ctx != null) ctx.close();
		} catch (IOException ex) {
			System.out.println("File Read error : " + ex);
		} catch(NamingException ex) {
			System.out.println("Namming Exception : " + ex);
		}
	}

	public void makePerson(String fileName, String domainName, String userName, Attributes attrs) {
		try {
			Hashtable<String, String> env = new Hashtable<String, String>();
			env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			env.put(Context.PROVIDER_URL, "ldap://192.168.0.6:389");
			env.put(Context.SECURITY_PRINCIPAL, "cn=Directory Manager");
			env.put(Context.SECURITY_CREDENTIALS, "Simba9gk");
			Context ctx = new InitialContext(env);
			String searchStr = "o=" + domainName + ",dc=ardhi,dc=go,dc=ke";
			LdapContext ln = (LdapContext)ctx.lookup(searchStr);

			Attribute objclass = new BasicAttribute("objectClass");
			Attribute icsE = new BasicAttribute("icsExtendedUserPrefs");
			Attribute nswmE = new BasicAttribute("nswmExtendedUserPrefs");

			FileReader fr = new FileReader(fileName);
			BufferedReader br = new BufferedReader(fr);
			String s;
			while((s = br.readLine()) != null) {
				String sl[] = s.split(":");
				if(sl.length > 1) {
					String nt = sl[0].trim();
					String nv = s.substring(s.indexOf(":") + 1, s.length()).trim();

					if(nt.equals("objectClass")) {
						objclass.add(nv);
					} else if(nt.equals("icsExtendedUserPrefs")) {
						icsE.add(nv);
					} else if(nt.equals("nswmExtendedUserPrefs")) {
						nswmE.add(nv);
					} else {
						attrs.put(new BasicAttribute(nt, nv));
					}
				}
			}
			br.close();
			fr.close();

			String mailName = userName.replace("uid=", "").trim();
			attrs.put(new BasicAttribute("icsCalendar", mailName + "@ardhi.go.ke"));
			attrs.put(new BasicAttribute("mail", mailName + "@ardhi.go.ke"));
			attrs.put(new BasicAttribute("psRoot", "ldap://mail.ardhi.go.ke:389/piPStoreOwner=" + mailName + ",o=ardhi.go.ke,o=PiServerDb"));

			attrs.put(objclass);
			attrs.put(icsE);
			attrs.put(nswmE);

			attrs.remove("uidNumber");
			attrs.remove("gidNumber");
			attrs.remove("loginShell");
			attrs.remove("gecos");
			attrs.remove("homeDirectory");

			Context result = ln.createSubcontext(userName + ",ou=People", attrs);

			if(ln != null) ln.close();
			if(ctx != null) ctx.close();
		} catch (IOException ex) {
			System.out.println("File Read error : " + ex);
		} catch(NamingException ex) {
			System.out.println("Namming Exception : " + ex);
		}
	}
}

