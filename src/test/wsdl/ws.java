
import javax.xml.ws.WebServiceRef;

import babcock.ws.*;

public class ws {

	public static void main(String args[]) {

		NibssServicePorts port = new NibssServicePorts();
		NibssService service = port.getNibssService();
		
		DNibssInputApplicant ni = new DNibssInputApplicant();
		ni.setApplicationId("16");
		ni.setProductId(300);
		BNibssQueryApplicant applicant = service.queryApplicant(ni);

		System.out.println("Retrieving the port from the following service: " + applicant.getApplicantName());

		DNibssInputPayment nip = new DNibssInputPayment();
		nip.setApplicationId("16");
		nip.setProductId(300);
		nip.setAmount(6000.0);
		nip.setPaymentReference("kjhkjhkjhjk");
		BNibssPostPayment payment = service.paymentUpdate(nip);

		System.out.println("Retrieving the port from the following service: " + payment.getPaymentUpdateCode());	
	}

}


