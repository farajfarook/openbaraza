
import java.net.URL;
import java.net.MalformedURLException;
import java.util.Calendar;
import java.util.List;
import java.text.SimpleDateFormat;

import ipn.*;

public class BMPesa {
	
	public static void main(String[] args) {
		try {
			IpnWebRetrieval service = new IpnWebRetrieval();
			System.out.println("Retrieving the port from the following service: " + service);

			Calendar cal = Calendar.getInstance();
			SimpleDateFormat dateParse = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");
			System.out.println("Running MPESA Web service : " + dateParse.format(cal.getTime()));

			RetrieveData port = service.getRetrieveDataPort();

			List<Tblmpesa> pts = port.retrieveTransactionsByDate("254708850080", "2013-10-01", "#Jud1ci@71");
			
			System.out.println("Size : " + pts.size());
			for(Tblmpesa pt : pts) {
				System.out.println("Message ID : " + pt.getMessageId());
				System.out.println("Message ID : " + pt.getMpesaAccountnumber());
				System.out.println("Message ID : " + pt.getMpesaAllocated());
				System.out.println("Message ID : " + pt.getMpesaAmount());
				System.out.println("Message ID : " + pt.getMpesaBalance());
				System.out.println("Message ID : " + pt.getMpesaDatetime());
				System.out.println("Message ID : " + pt.getMpesaId());
				System.out.println("Message ID : " + pt.getMpesaOriginaltext());
				System.out.println("Message ID : " + pt.getMpesaSendermobile());
				System.out.println("Message ID : " + pt.getMpesaSendername());
				System.out.println("Message ID : " + pt.getMpesaTerminal());
				System.out.println("Message ID : " + pt.getMpesaTxcode());
				System.out.println("Message ID : " + pt.getMpesaTxdate());
				System.out.println("");
			}

		} catch(InvalidCredentialsFault_Exception ex) {
			System.out.println("Credential error : " + ex);
		}
	}
}
