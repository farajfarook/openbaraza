import java.util.*;
import java.io.*;
import javax.naming.*;
import javax.naming.directory.*;
import javax.naming.ldap.LdapContext;

public class BLands {

	public static void main(String args[]) {
		BLands lands = new BLands();
		lands.userList();
	}

	public void userList() {
		List<String> userList = readData("ardhi.go.ke");
		Map<String, String> userMap = new HashMap<String, String>();

		try {
			FileReader fr = new FileReader("users.txt");
			BufferedReader br = new BufferedReader(fr);
			String s;
			while((s = br.readLine()) != null) {
				String st[] = s.split(":");
				String et[] = st[1].split("@");
				String emailUser = et[0].trim().toLowerCase();
				if(!userList.contains(emailUser)) {
					System.out.println(s);
					userMap.put(emailUser, st[0].trim());
				}
			}
			br.close();
			fr.close();
		} catch (IOException ex) {
			System.out.println("File Read error : " + ex);
		}

		for (String key : userMap.keySet()) {
			makePerson("user.ldif", "ardhi.go.ke", key, userMap.get(key));
		}
	}

	public List<String> readData(String domainName) {
		List<String> userList = new ArrayList<String>();
		
		try {
			Hashtable<String, String> env = new Hashtable<String, String>();
			env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			env.put(Context.PROVIDER_URL, "ldap://192.168.0.6:389");
			env.put(Context.SECURITY_PRINCIPAL, "cn=Directory Manager");
			env.put(Context.SECURITY_CREDENTIALS, "Simba9gk");
			Context ctx = new InitialContext(env);

			String searchStr = "o=" + domainName + ",dc=ardhi,dc=go,dc=ke";
			LdapContext ln = (LdapContext)ctx.lookup(searchStr);

			NamingEnumeration list = ln.list("ou=People");
			LdapContext pln = (LdapContext)ctx.lookup("ou=People," + searchStr);

			while (list.hasMore()) {
				NameClassPair nc = (NameClassPair)list.next();
				String uidName = nc.getName();
				userList.add(uidName.replace("uid=", "").trim().toLowerCase());
			}

			if(ln != null) ln.close();
			if(ctx != null) ctx.close();
		} catch(NamingException ex) {
			System.out.println("Namming Exception : " + ex);
		}

		return userList;
	}

	public void makePerson(String fileName, String domainName, String userName, String fullName) {
		try {
			Hashtable<String, String> env = new Hashtable<String, String>();
			env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
			env.put(Context.PROVIDER_URL, "ldap://192.168.0.6:389");
			env.put(Context.SECURITY_PRINCIPAL, "cn=Directory Manager");
			env.put(Context.SECURITY_CREDENTIALS, "Simba9gk");
			Context ctx = new InitialContext(env);
			String searchStr = "o=" + domainName + ",dc=ardhi,dc=go,dc=ke";
			LdapContext ln = (LdapContext)ctx.lookup(searchStr);

			Attributes attrs = new BasicAttributes(true); // case-ignore
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

			String unt[] = fullName.split(",");

			attrs.put(new BasicAttribute("givenName", unt[1].replace(",", "").trim()));
			attrs.put(new BasicAttribute("sn", unt[0].replace(",", "").trim()));
			attrs.put(new BasicAttribute("cn", fullName));

			attrs.put(new BasicAttribute("icsCalendar", userName + "@ardhi.go.ke"));
			attrs.put(new BasicAttribute("mail", userName + "@ardhi.go.ke"));
			attrs.put(new BasicAttribute("psRoot", "ldap://mail.ardhi.go.ke:389/piPStoreOwner=" + userName + ",o=ardhi.go.ke,o=PiServerDb"));

			attrs.put(objclass);
			attrs.put(icsE);
			attrs.put(nswmE);

			attrs.remove("uidNumber");
			attrs.remove("gidNumber");
			attrs.remove("loginShell");
			attrs.remove("gecos");
			attrs.remove("homeDirectory");

			Context result = ln.createSubcontext("uid=" + userName + ",ou=People", attrs);

			if(ln != null) ln.close();
			if(ctx != null) ctx.close();
		} catch (IOException ex) {
			System.out.println("File Read error : " + ex);
		} catch(NamingException ex) {
			System.out.println("Namming Exception : " + ex);
		}
	}
}