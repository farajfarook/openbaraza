package epp;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.openrtk.idl.epprtk.epp_CheckResult;
import org.openrtk.idl.epprtk.epp_Command;
import org.openrtk.idl.epprtk.epp_Exception;
import org.openrtk.idl.epprtk.epp_XMLException;
import org.openrtk.idl.epprtk.host.epp_HostAddress;
import org.openrtk.idl.epprtk.host.epp_HostAddressType;
import org.openrtk.idl.epprtk.host.epp_HostCheckReq;
import org.openrtk.idl.epprtk.host.epp_HostCreateReq;
import org.openrtk.idl.epprtk.host.epp_HostCreateRsp;
import org.openrtk.idl.epprtk.host.epp_HostDeleteReq;
import org.openrtk.idl.epprtk.host.epp_HostDeleteRsp;

import com.tucows.oxrs.epprtk.rtk.EPPClient;
import com.tucows.oxrs.epprtk.rtk.xml.EPPHostCheck;
import com.tucows.oxrs.epprtk.rtk.xml.EPPHostCreate;
import com.tucows.oxrs.epprtk.rtk.xml.EPPHostDelete;
import com.tucows.oxrs.epprtk.rtk.xml.EPPXMLBase;

public class BEppHosts {

	private EPPClient client;

	public BEppHosts() {
		this.client = client;
	}

	/**
	 * Checks if each host is available.
	 *  
	 * @param hostNames
	 * @return Boolean Map confirming whether each host is available.
	 * 
	 * @throws epp_XMLException
	 * @throws epp_Exception
	 * @throws Exception
	 */
	public Map<String, Boolean> checkHosts(List<String> hostNames) throws epp_XMLException, epp_Exception, Exception {
		Map<String, Boolean> hostsAvail = new HashMap<String, Boolean>();
		
		epp_HostCheckReq host_check_request = new epp_HostCheckReq();
		
		epp_Command command = new epp_Command();
		
		command.setClientTrid(getClientTrid(client.getEPPClientID()));
		host_check_request.setCmd(command);

		host_check_request.setNames(EPPXMLBase.convertListToStringArray(hostNames));
		
		EPPHostCheck host_check = new EPPHostCheck();
		host_check.setRequestData(host_check_request);
		
		host_check = (EPPHostCheck) client.processAction(host_check);

		epp_CheckResult[] check_results = host_check.getResponseData().getResults();
		
		for (String hostName : hostNames) {
			Boolean hostAvail = EPPXMLBase.getAvailResultFor(check_results, hostName);
			hostsAvail.put(hostName, hostAvail);
		}
		
		return hostsAvail;
	}

	/**
	 * Checks a host to see if it exists.
	 * 
	 * @param hostName
	 * @return Boolean confirm whether specified host exists.
	 * 
	 * @throws epp_XMLException
	 * @throws epp_Exception
	 * @throws Exception
	 */
	public Boolean checkHost(String hostName) throws epp_XMLException, epp_Exception, Exception {
		List<String> hostNames = new ArrayList<String>();
		hostNames.add(hostName);
		
		Map<String, Boolean> hostsAvail = checkHosts(hostNames);
		
		return hostsAvail.get(hostName);
	}

	public epp_HostCreateRsp createHost(String hostName, List<String> ipAddresses) throws epp_XMLException, epp_Exception, Exception {
		epp_HostCreateReq host_create_request = new epp_HostCreateReq();
		
		epp_Command command_data = new epp_Command();
		
		command_data.setClientTrid(getClientTrid(client.getEPPClientID()));
		host_create_request.setCmd(command_data);

		if (ipAddresses != null) {
			List<epp_HostAddress> hostAddresses = new ArrayList<epp_HostAddress>();
			
			for (String ipAddress : ipAddresses) {
				hostAddresses.add(new epp_HostAddress(epp_HostAddressType.IPV4, ipAddress));
			}

			host_create_request.setAddresses((epp_HostAddress[])EPPXMLBase.convertListToArray((new epp_HostAddress()).getClass(), hostAddresses));
		}
		
		host_create_request.setName(hostName);

		EPPHostCreate host_create = new EPPHostCreate();
		host_create.setRequestData(host_create_request);

		// Send request to server...
		host_create = (EPPHostCreate) client.processAction(host_create);

		// Process response from server...
		return host_create.getResponseData();
	}

	/**
	 * Deletes a host.
	 * 
	 * @param hostName
	 * @return
	 * @throws epp_XMLException
	 * @throws epp_Exception
	 * @throws Exception
	 */
	public epp_HostDeleteRsp deleteHost(String hostName) throws epp_XMLException, epp_Exception, Exception {
		epp_HostDeleteReq host_delete_request = new epp_HostDeleteReq();
		
		epp_Command command_data = new epp_Command();
		command_data.setClientTrid(getClientTrid(client.getEPPClientID()));
		host_delete_request.setCmd(command_data);

		host_delete_request.setName(hostName);
		
		EPPHostDelete host_delete = new EPPHostDelete();
		host_delete.setRequestData(host_delete_request);

		// Send request to server...
		host_delete = (EPPHostDelete) client.processAction(host_delete);

		// Process response from server...
		return host_delete.getResponseData();
	}
	
	protected String getClientTrid(String epp_client_id) {
		return "ABC:"+epp_client_id+":"+System.currentTimeMillis();
	}
}
