import java.sql.*;

public class BMigration {

	public static void main(String args[]) {
		BMigration dm = new BMigration();
		dm.migrateDomains();
	}

	public void migrateDomains() {
		BVirtualMin virtualMin = new BVirtualMin();
		BLDAP ldap = new BLDAP();
		BSecurity sec = new BSecurity();
		BDBConn epp = new BDBConn("epp");
		BDBConn obs = new BDBConn("obs");

		try {
			String mysql = "SELECT contact.id, contact.intpostalname, contact.authinfopw, contact.intpostalcc, ";
			mysql += "contact.intpostalstreet1, contact.intpostalstreet2, contact.intpostalstreet3, ";
			mysql += "contact.intpostalcity, contact.voice, contact.email, ";
			mysql += "domain.name, domain.authinfopw as domain_authinfopw, domain.createdate, domain.exdate ";
			mysql += "FROM contact INNER JOIN domain ON contact.id = domain.registrant ";
			mysql += "WHERE domain.clid = 'JTL'";

			ResultSet rs = epp.readQuery(mysql);
			int j = 0;
			while(rs.next()) {
				String domainName = rs.getString("name");
				String passwd = sec.randomMD5().substring(10, 22);
				String email = "admin@" + domainName;

				System.out.println(domainName);

				ldap.migrateDomain(domainName);
				virtualMin.createDomain(domainName, passwd, email);
				obs.migrateEntity(rs, passwd);

				j++;
				if(j>10) break;
			}
			rs.close();

			mysql = "UPDATE domains SET zone_id = zones.zone_id FROM zones ";
			mysql += "WHERE substring(domains.domain_name from '......$') = zones.zone_name";
			obs.executeQuery(mysql);

			mysql = "UPDATE address SET email = null ";
			mysql += "WHERE email = 'UNKNOWN';";
			obs.executeQuery(mysql);
		} catch(SQLException ex) {
			System.out.println("Database transaction get data error : " + ex);
		}

		obs.close();
		epp.close();
	}

}