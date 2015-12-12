package epp;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.openrtk.idl.epprtk.epp_AuthInfo;
import org.openrtk.idl.epprtk.epp_AuthInfoType;
import org.openrtk.idl.epprtk.epp_CheckResult;
import org.openrtk.idl.epprtk.epp_Command;
import org.openrtk.idl.epprtk.epp_Exception;
import org.openrtk.idl.epprtk.epp_TransferOpType;
import org.openrtk.idl.epprtk.epp_TransferRequest;
import org.openrtk.idl.epprtk.epp_XMLException;
import org.openrtk.idl.epprtk.domain.epp_DomainCheckReq;
import org.openrtk.idl.epprtk.domain.epp_DomainContact;
import org.openrtk.idl.epprtk.domain.epp_DomainContactType;
import org.openrtk.idl.epprtk.domain.epp_DomainCreateReq;
import org.openrtk.idl.epprtk.domain.epp_DomainCreateRsp;
import org.openrtk.idl.epprtk.domain.epp_DomainDeleteReq;
import org.openrtk.idl.epprtk.domain.epp_DomainDeleteRsp;
import org.openrtk.idl.epprtk.domain.epp_DomainInfoReq;
import org.openrtk.idl.epprtk.domain.epp_DomainInfoRsp;
import org.openrtk.idl.epprtk.domain.epp_DomainPeriod;
import org.openrtk.idl.epprtk.domain.epp_DomainPeriodUnitType;
import org.openrtk.idl.epprtk.domain.epp_DomainRenewReq;
import org.openrtk.idl.epprtk.domain.epp_DomainRenewRsp;
import org.openrtk.idl.epprtk.domain.epp_DomainTransferReq;
import org.openrtk.idl.epprtk.domain.epp_DomainTransferRsp;
import org.openrtk.idl.epprtk.domain.epp_DomainUpdateAddRemove;
import org.openrtk.idl.epprtk.domain.epp_DomainUpdateChange;
import org.openrtk.idl.epprtk.domain.epp_DomainUpdateReq;
import org.openrtk.idl.epprtk.domain.epp_DomainUpdateRsp;

import com.tucows.oxrs.epprtk.rtk.EPPClient;
import com.tucows.oxrs.epprtk.rtk.RTKBase;
import com.tucows.oxrs.epprtk.rtk.xml.EPPDomainCheck;
import com.tucows.oxrs.epprtk.rtk.xml.EPPDomainCreate;
import com.tucows.oxrs.epprtk.rtk.xml.EPPDomainDelete;
import com.tucows.oxrs.epprtk.rtk.xml.EPPDomainInfo;
import com.tucows.oxrs.epprtk.rtk.xml.EPPDomainRenew;
import com.tucows.oxrs.epprtk.rtk.xml.EPPDomainTransfer;
import com.tucows.oxrs.epprtk.rtk.xml.EPPDomainUpdate;
import com.tucows.oxrs.epprtk.rtk.xml.EPPXMLBase;

public class BEppDomains {

	private EPPClient client;

	public BEppDomains() { 
		this.client = client;
	}

	/**
	 * Checks a list of domains to see if they exist.
	 * 
	 * @param domainNames
	 * @return Map with domain name as key and boolean value indicating whether it exists.
	 * 
	 * @throws epp_XMLException
	 * @throws epp_Exception
	 * @throws Exception
	 */
	public Map<String, Boolean> checkDomains(List<String> domainNames) throws epp_XMLException, epp_Exception, Exception {
		Map<String, Boolean> domainsAvail = new HashMap<String, Boolean>();
		
		epp_DomainCheckReq domain_check_request = new epp_DomainCheckReq();
		
		epp_Command command = new epp_Command();
		
		command.setClientTrid(getClientTrid(client.getEPPClientID()));
		
		domain_check_request.setCmd(command);
		domain_check_request.setNames(EPPXMLBase.convertListToStringArray(domainNames));
		
		EPPDomainCheck domain_check = new EPPDomainCheck();
		domain_check.setRequestData(domain_check_request);

		// Send request to server...
		domain_check = (EPPDomainCheck) client.processAction(domain_check);

		// Process response from server...
		epp_CheckResult[] check_results = domain_check.getResponseData().getResults();

		for (String domainName : domainNames) {
		    Boolean domainAvail = EPPXMLBase.getAvailResultFor(check_results, domainName);    
		    domainsAvail.put(domainName, domainAvail);
		}
		
		return domainsAvail;
	}

	/**
	 * Checks a domain to see if it exists.
	 * 
	 * @param domainName
	 * @return Boolean indicating whether it exists.
	 * 
	 * @throws epp_XMLException
	 * @throws epp_Exception
	 * @throws Exception
	 */
	public Boolean checkDomain(String domainName) throws epp_XMLException, epp_Exception, Exception {
		List<String> domainNames = new ArrayList<String>();
		domainNames.add(domainName);
		
		Map<String, Boolean> domainsAvail = checkDomains(domainNames);
		
		return domainsAvail.get(domainName);
	}
	
	/**
	 * Creates a domain.
	 * 
	 * @param domainName
	 * @param period
	 * @param nameServers
	 * @param authInfo
	 * @param registrantId
	 * @param adminContactId
	 * @param billingContactId
	 * @param techContactId
	 * @return 
	 * @throws epp_XMLException
	 * @throws epp_Exception
	 * @throws Exception
	 */
	public epp_DomainCreateRsp createDomain(String domainName, int period, List nameServers,
		String authInfo, String registrantId, String adminContactId, String billingContactId,
		String techContactId) throws epp_XMLException, epp_Exception, Exception {

		epp_DomainCreateReq domain_create_request = new epp_DomainCreateReq();
		
		epp_Command command = new epp_Command();
		
		command.setClientTrid(getClientTrid(client.getEPPClientID()));
		domain_create_request.setCmd(command);

		domain_create_request.setName(domainName);
		
		epp_DomainPeriod domainPeriod = new epp_DomainPeriod();
		domainPeriod.setUnit(epp_DomainPeriodUnitType.YEAR);
		domainPeriod.setValue(period);
		domain_create_request.setPeriod(domainPeriod);

		domain_create_request.setNameServers(EPPXMLBase.convertListToStringArray(nameServers));
		                
		epp_AuthInfo domain_auth_info = new epp_AuthInfo();
		domain_auth_info.setValue(authInfo);
		
		domain_auth_info.setType(epp_AuthInfoType.PW);
		domain_create_request.setAuthInfo(domain_auth_info);

		Vector<epp_DomainContact> contacts = new Vector<epp_DomainContact>();
		contacts.add(new epp_DomainContact(epp_DomainContactType.TECH, techContactId));
		contacts.add(new epp_DomainContact(epp_DomainContactType.ADMIN, adminContactId));
		contacts.add(new epp_DomainContact(epp_DomainContactType.BILLING, billingContactId));
		domain_create_request.setContacts(contacts.toArray(new epp_DomainContact[1]));

		domain_create_request.setRegistrant(registrantId);
		               
		EPPDomainCreate domain_create = new EPPDomainCreate();
		domain_create.setRequestData(domain_create_request);

		// Send request to server...
		domain_create = (EPPDomainCreate) client.processAction(domain_create);

		// Process response from server...
		return domain_create.getResponseData();
	}

	/**
	 * Returns information about a domain.
	 * 
	 * @param domainName
	 * @return
	 * @throws epp_XMLException
	 * @throws epp_Exception
	 * @throws Exception
	 */
	public epp_DomainInfoRsp infoDomain(String domainName) throws epp_XMLException, epp_Exception, Exception {
		epp_DomainInfoReq domain_info_request = new epp_DomainInfoReq();

		epp_Command command_data = new epp_Command();
		
		command_data.setClientTrid(getClientTrid(client.getEPPClientID()));
		domain_info_request.setCmd(command_data);

		// The only domain-specific parameter is the domain name itself.
		domain_info_request.setName(domainName);
		
		EPPDomainInfo domain_info = new EPPDomainInfo();
		domain_info.setRequestData(domain_info_request);

		// Send request to server...
		domain_info = (EPPDomainInfo) client.processAction(domain_info);

		// Process response from server...
		return domain_info.getResponseData();
	}

	/**
	 * Renews a domain for a number of years.
	 * 
	 * @param domainName
	 * @param period number of years
	 * @param expiryDate current expiry date
	 */
	public epp_DomainRenewRsp renewDomain(String domainName, int period, Date expiryDate) throws epp_XMLException, epp_Exception, Exception {
		epp_DomainRenewReq domain_renew_request = new epp_DomainRenewReq();
		
		epp_Command command_data = new epp_Command();
		// The client trid is optional by EPP.  it's main use
		// is for registrar tracking and logging of requests,
		// especially for data creation or modification requests.
		// Some registries make it mandatory and unique per session.
		command_data.setClientTrid(getClientTrid(client.getEPPClientID()));
		domain_renew_request.setCmd(command_data);

		domain_renew_request.setName(domainName);

		// As in the domain create operation, the domain period
		// may be specified here also.		
		epp_DomainPeriod domainPeriod = new epp_DomainPeriod();
		domainPeriod.setUnit(epp_DomainPeriodUnitType.YEAR);
		domainPeriod.setValue(period);        
		domain_renew_request.setPeriod(domainPeriod);
		
		// Must also specify current expiry date in YYYY-MM-DD format to prevent 
		// multiple renew requests from succeeding.
		domain_renew_request.setCurrentExpirationDate(RTKBase.DATE_FMT.format(expiryDate));
		
		EPPDomainRenew domain_renew = new EPPDomainRenew();
		domain_renew.setRequestData(domain_renew_request);

		// Send request to server...
		domain_renew = (EPPDomainRenew) client.processAction(domain_renew);

		// Process response from server...
		return domain_renew.getResponseData();
	}
	
	/**
	 * Transfers a domain.
	 * 
	 * @param domainName
	 * @param operation
	 * @param authInfo
	 * @return
	 * @throws epp_XMLException
	 * @throws epp_Exception
	 * @throws Exception
	 */
	public epp_DomainTransferRsp transferDomain(String domainName, 
		    epp_TransferOpType operation, String authInfo) throws epp_XMLException, epp_Exception, Exception {

		epp_DomainTransferReq domain_transfer_request = new epp_DomainTransferReq();		
		epp_Command command_data = new epp_Command();
		
		command_data.setClientTrid(getClientTrid(client.getEPPClientID()));
		domain_transfer_request.setCmd(command_data);

		epp_TransferRequest transfer_request = new epp_TransferRequest();
		transfer_request.setOp(operation);
		
		// domain_auth_info is REQUIRED            
		epp_AuthInfo domain_auth_info = new epp_AuthInfo();
		domain_auth_info.setValue(authInfo);

		transfer_request.setAuthInfo(domain_auth_info);
		
		domain_transfer_request.setTrans(transfer_request);
		domain_transfer_request.setName(domainName);
		
		EPPDomainTransfer domain_transfer = new EPPDomainTransfer();
		domain_transfer.setRequestData(domain_transfer_request);

		// Send request to server...
		domain_transfer = (EPPDomainTransfer) client.processAction(domain_transfer);

		// Process response from server...
		return domain_transfer.getResponseData();
	}

	/**
	 * Updates a domain.
	 * 
	 * @param domainName
	 * @param add
	 * @param remove
	 * @param change
	 * @param removeNameServers
	 * @param expiryDate
	 * @return
	 * @throws epp_XMLException
	 * @throws epp_Exception
	 * @throws Exception
	 */
	public epp_DomainUpdateRsp updateDomain(String domainName, epp_DomainUpdateAddRemove add,
		epp_DomainUpdateAddRemove remove, epp_DomainUpdateChange change) throws epp_XMLException, epp_Exception, Exception {

		epp_DomainUpdateReq domain_update_request = new epp_DomainUpdateReq();
		
		epp_Command command_data = new epp_Command();
		
		command_data.setClientTrid(getClientTrid(client.getEPPClientID()));
		domain_update_request.setCmd(command_data);

		domain_update_request.setName(domainName);
		
		// Set info to be added...
		domain_update_request.setAdd(add);
		
		// Set info to be removed...
		domain_update_request.setRemove(remove);

		// Set info to be changed...
		domain_update_request.setChange(change);
		
		EPPDomainUpdate domain_update = new EPPDomainUpdate();
		domain_update.setRequestData(domain_update_request);

		// Send request to server...
		domain_update = (EPPDomainUpdate) client.processAction(domain_update);

		// Process response from server...
		return domain_update.getResponseData();
	}
	
	/**
	 * Deletes a domain.
	 * 
	 * @param domainName
	 * @return
	 * @throws epp_XMLException
	 * @throws epp_Exception
	 * @throws Exception
	 */
	public epp_DomainDeleteRsp deleteDomain(String domainName) throws epp_XMLException, epp_Exception, Exception {
		epp_DomainDeleteReq domain_delete_request = new epp_DomainDeleteReq();
		
		epp_Command command_data = new epp_Command();
		
		command_data.m_client_trid = getClientTrid(client.getEPPClientID());
		
		domain_delete_request.m_cmd = command_data;
		domain_delete_request.m_name = domainName;
		
		EPPDomainDelete domain_delete = new EPPDomainDelete();
		domain_delete.setRequestData(domain_delete_request);

		// Send request to server...
		domain_delete = (EPPDomainDelete) client.processAction(domain_delete);

		// Process response from server...
		return domain_delete.getResponseData();
	}
	
	public String getClientTrid(String epp_client_id) {
		return "ABC:"+epp_client_id+":"+System.currentTimeMillis();
	}    
}
