package epp;

import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;

import org.openrtk.idl.epprtk.contact.epp_ContactAddress;
import org.openrtk.idl.epprtk.contact.epp_ContactCheckReq;
import org.openrtk.idl.epprtk.contact.epp_ContactCheckRsp;
import org.openrtk.idl.epprtk.contact.epp_ContactCreateReq;
import org.openrtk.idl.epprtk.contact.epp_ContactCreateRsp;
import org.openrtk.idl.epprtk.contact.epp_ContactNameAddress;
import org.openrtk.idl.epprtk.contact.epp_ContactPhone;
import org.openrtk.idl.epprtk.contact.epp_ContactPostalInfoType;

import org.openrtk.idl.epprtk.domain.epp_DomainCheckReq;
import org.openrtk.idl.epprtk.domain.epp_DomainCheckRsp;

import org.openrtk.idl.epprtk.epp_CheckResult;
import org.openrtk.idl.epprtk.epp_Greeting;
import org.openrtk.idl.epprtk.epp_Command;
import org.openrtk.idl.epprtk.epp_Response;
import org.openrtk.idl.epprtk.epp_Result;
import com.tucows.oxrs.epprtk.rtk.EPPClient;
import com.tucows.oxrs.epprtk.rtk.xml.EPPXMLBase;
import com.tucows.oxrs.epprtk.rtk.xml.EPPContactCheck;
import com.tucows.oxrs.epprtk.rtk.xml.EPPContactCreate;
import com.tucows.oxrs.epprtk.rtk.xml.EPPDomainCheck;

import java.io.IOException;
import org.openrtk.idl.epprtk.epp_Exception;
import org.openrtk.idl.epprtk.epp_XMLException;
import com.tucows.oxrs.epprtk.rtk.transport.EPPTransportException;

public class BEpp {
	EPPClient epp_client = null;
	epp_Command command_data;
	String epp_client_id;
	
	public static void main(String[] args) {
		BEpp epp = new BEpp();

		if(epp.epp_connected()) {
			List<String> contact_list = new ArrayList<String>();
			contact_list.add("tamsh-GzuSIfE2DX");
			contact_list.add("C102-LRMS");
			contact_list.add("C999-LRMS");
			epp.checkContact(contact_list);

			List<String> domain_list = new ArrayList<String>();
			domain_list.add("dennis.me.ke");
			domain_list.add("kirinyaga.info.ke");
			epp.checkDomains(domain_list);

			// Close the connection
			epp.close();
		}
	}

	public BEpp() {
		String epp_contact_name = "regsys.kenic.or.ke";
		int epp_contact_port = 700;
		epp_client_id = "ESL";
		String epp_password = "DewCIS9WEB";

		command_data = new epp_Command();
		command_data.setClientTrid(getClientTrid());

		try {
  			System.setProperty("javax.net.ssl.trustStoreType", "jks");
  			System.setProperty("javax.net.ssl.trustStore", "/root/baraza/src/test/epp/conf/epp.keystore");
  			System.setProperty("javax.net.ssl.trustStorePassword", "invent");
			System.setProperty("ssl.props.location", "/root/baraza/src/test/epp/conf");

			epp_client = new EPPClient(epp_contact_name, epp_contact_port, epp_client_id, epp_password);
			epp_client.setLang("en");

			System.out.println("Connecting to EPP Server...");
			epp_Greeting greeting = epp_client.connectAndGetGreeting();
			epp_client.login(getClientTrid());
		} catch(epp_Exception ex) {
			System.out.println("EPP Exception : " + ex);
		} catch(IOException ex) {
			System.out.println("IO Exception : " + ex);
		} catch(epp_XMLException ex) {
			System.out.println("EPP XML Exception : " + ex);
		} catch(EPPTransportException ex) {
			System.out.println("EPP Transport Exception : " + ex);
		}
	}

	public void checkContact(List<String> contact_list) {
		try {
			System.out.println("Creating the Contact Check command");
			epp_ContactCheckReq contact_check_request = new epp_ContactCheckReq();

			contact_check_request.setCmd(command_data);
			contact_check_request.m_ids = EPPXMLBase.convertListToStringArray(contact_list);

			EPPContactCheck contact_check = new EPPContactCheck();
			contact_check.setRequestData(contact_check_request);             
            contact_check.fromXML(epp_client.processXML(contact_check.toXML()));

			epp_ContactCheckRsp contact_check_response = contact_check.getResponseData();
			epp_Response response = contact_check_response.m_rsp;
			epp_Result[] results = response.m_results;
			System.out.println("ContactCheck results: ["+results[0].m_code+"] ["+results[0].m_msg+"]");
			epp_CheckResult[] check_results = contact_check_response.m_results;
			System.out.println("Contact Check results: contact [tamsh-GzuSIfE2DX] available? ["+EPPXMLBase.getAvailResultFor(check_results, "tamsh-GzuSIfE2DX")+"]");
			System.out.println("Contact Check results: contact [C102-LRMS] available? ["+EPPXMLBase.getAvailResultFor(check_results, "C102-LRMS")+"]");
			System.out.println("Contact Check results: contact [C999-LRMS] available? ["+EPPXMLBase.getAvailResultFor(check_results, "C999-LRMS")+"]");
		} catch(epp_Exception ex) {
			System.out.println("EPP Exception : " + ex);
		} catch(epp_XMLException ex) {
			System.out.println("EPP XML Exception : " + ex);
		}
	}

	public void createContact(Map<String, String> rmap) {
		try {
			epp_ContactCreateReq contact_create_request = new epp_ContactCreateReq();
			contact_create_request.setCmd(command_data);
			contact_create_request.setId("contact2953");
    
			epp_ContactNameAddress[] name_address = new epp_ContactNameAddress[1];
			name_address[0] = new epp_ContactNameAddress();
			name_address[0].setType(epp_ContactPostalInfoType.INT);
			name_address[0].setName(rmap.get("full_name"));

			epp_ContactAddress address = new epp_ContactAddress();
			address.setStreet1("P.O Box " + rmap.get("post_office_box"));
			address.setStreet2(rmap.get("street"));
			address.setCity(rmap.get("town"));
			address.setPostalCode(rmap.get("postal_code"));
			address.setCountryCode(rmap.get("sys_country_id"));
			name_address[0].setAddress( address );

			contact_create_request.setAddresses(name_address);
			contact_create_request.setVoice( new epp_ContactPhone(rmap.get("extension"), rmap.get("phone_number")));
			contact_create_request.setFax( new epp_ContactPhone(null, rmap.get("mobile")) );
			contact_create_request.setEmail(rmap.get("email"));

			EPPContactCreate contact_create = new EPPContactCreate();
			contact_create.setRequestData(contact_create_request);

			contact_create = (EPPContactCreate)epp_client.processAction(contact_create);
			epp_ContactCreateRsp contact_create_response = contact_create.getResponseData();
			epp_Response response = contact_create_response.getRsp();
			System.out.println(response.toString());
		} catch(epp_XMLException ex) {
			System.out.println("EPP XML Exception : " + ex);
		} catch(epp_Exception ex) {
			System.out.println("EPP Exception : " + ex);
		}
	}

	public Map<String, Boolean> checkDomains(List<String> domain_list) {
		Map<String, Boolean> results = new HashMap<String, Boolean>();

		try {
			System.out.println("Creating the Domain Check command");
			epp_Command command_data = new epp_Command();
			command_data.setClientTrid(getClientTrid());

			epp_DomainCheckReq domain_check_request = new epp_DomainCheckReq();
			domain_check_request.setCmd(command_data);
			domain_check_request.setNames(EPPXMLBase.convertListToStringArray(domain_list));

			EPPDomainCheck domain_check = new EPPDomainCheck();
			domain_check.setRequestData(domain_check_request);
			domain_check.fromXML(epp_client.processXML(domain_check.toXML()));

			epp_DomainCheckRsp domain_check_response = domain_check.getResponseData();
			epp_Response response = domain_check_response.getRsp();
			epp_CheckResult[] check_results = domain_check_response.getResults();

			for(String domainName : domain_list) {
				System.out.println("Domain Check results: " + domainName + " available? ["+EPPXMLBase.getAvailResultFor(check_results, domainName)+"]");
				results.put(domainName, EPPXMLBase.getAvailResultFor(check_results, domainName));
			}
		} catch(epp_Exception ex) {
			System.out.println("EPP Exception : " + ex);
		} catch(epp_XMLException ex) {
			System.out.println("EPP XML Exception : " + ex);
		}

		return results;
	}

	protected String getClientTrid() {
		return "ABC:" + epp_client_id + ":" + System.currentTimeMillis();
	}

	public boolean epp_connected() {
		boolean connected = true;
		if(epp_client == null) connected = false;
		return connected;
	}

	public void close() {
		try {
			System.out.println("Logging out from the EPP Server");
			epp_client.logout(getClientTrid());
				
			System.out.println("Disconnecting from the EPP Server");
			epp_client.disconnect();
		} catch(epp_Exception ex) {
			System.out.println("EPP Exception : " + ex);
		} catch(epp_XMLException ex) {
			System.out.println("EPP XML Exception : " + ex);
		} catch(IOException ex) {
			System.out.println("IO Exception : " + ex);
		}
	}

}
