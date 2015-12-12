/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.sms;

import java.util.logging.Logger;
import java.util.Date;
import java.text.SimpleDateFormat;
import java.text.ParsePosition;
import java.text.ParseException;
import java.text.DecimalFormat;
import java.io.UnsupportedEncodingException;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.utils.BAmountInWords;
import org.baraza.utils.BLogHandle;

public class BSMSMessage {
	Logger log = Logger.getLogger(BSMSMessage.class.getName());
	String senderAddress = "";
	Date smstime =  null;
	String message = "";
	String msgNumber = "";
	String code;
	String amount;
	String clientid;
	int messageNum;

	BPDUCode pducode;

	public BSMSMessage(BLogHandle logHandle) {
		logHandle.config(log);
		pducode = new BPDUCode();
	}

	public void readsms(BDB db, int msgNum, String smspdu) {
		int smscAddressLength, smscAddressType, smsDeliverCode, senderAddressLength, senderAddressType;
		int tpPid, tpDcs, tpUdl;
		String sms_format = "";
		String smscAddress = "";
		messageNum = msgNum;
		String msg = "";
		clientid = null;
		amount = null;
		log.finer("BASE 100 : " + smspdu);

		int pdulen = smspdu.length();
		smspdu.toUpperCase();
		String tmpstr;
		int i = 0;
		boolean hasSmscInfo = false;

		String octet1str = smspdu.substring(i, 2);
		int octet1 = Integer.parseInt(octet1str, 16);
		i = i + 2;

		String octet2str = smspdu.substring(i, i+2);
		int octet2 = Integer.parseInt(octet2str, 16);
		i = i + 2;
		log.finer("BASE 200");

		// SMSC info included in the PDU.
    	if(octet1 > 0) {
			// get SMSC address length.
			smscAddressLength = octet1;

			// get SMSC address type.
			smscAddressType = octet2;

			// get SMSC address string (minus type len).
			int smsAddrLastIndex = i + (smscAddressLength*2) - 2;
			tmpstr = smspdu.substring(i, smsAddrLastIndex);
			smscAddress = pducode.swapDigits(tmpstr);
			if( smscAddress.indexOf('F') != -1 ) // strip trailing F.
				smscAddress = smscAddress.substring(0, smscAddress.length()-1);
			if((smscAddressType & 0xf0) == 0x90) // international format.
				smscAddress = '+' + smscAddress;
			i = i + (smscAddressLength*2) - 2;

			String smsDeliverStr = smspdu.substring(i, i+2);
			smsDeliverCode = Integer.parseInt(smsDeliverStr, 16);
			i = i + 2;

			if (smsDeliverCode % 2 == 0) {
				sms_format = "incoming"; 
			} else {
				sms_format = "outgoing";
				i = i+2; // +2 because additonal TP reference field in outgoing format
			}

			// get sender address length.
			String addressLenStr = smspdu.substring(i, i+2);
			senderAddressLength = Integer.parseInt(addressLenStr, 16);
			i = i + 2;
		} else { // no SMSC info in the PDU.
			smsDeliverCode = octet2;

			if (smsDeliverCode % 2 == 0) {
				sms_format = "incoming"; }
			else  {
				sms_format = "outgoing";
				i = i + 2; // +2 because additonal TP reference field in outgoing format
			}
			String addressLenStr = smspdu.substring(i, i+2);
			senderAddressLength = Integer.parseInt(addressLenStr, 16);
			i = i + 2;
	    }

		// get sender address type.
		String addressTypeStr = smspdu.substring(i, i+2);
		senderAddressType = Integer.parseInt(addressTypeStr, 16);
		i = i + 2;

		// get sender address.
		int senderLastIndex = i + senderAddressLength + senderAddressLength % 2;
	    tmpstr = smspdu.substring(i, senderLastIndex);
	    senderAddress = pducode.swapDigits(tmpstr);
	    senderAddress = senderAddress.substring(0, senderAddressLength);
	    if((senderAddressType & 0xf0) == 0x90) // 1001xxxx?
			senderAddress = '+' + senderAddress;
		i = i + senderAddressLength + senderAddressLength % 2;

		// get protocol id.
		String protocolStr = smspdu.substring(i, i+2);
		tpPid = Integer.parseInt(protocolStr, 16);
		i = i + 2;

	    // get data encoding scheme.
	    String dataEncStr = smspdu.substring(i, i+2);
	    tpDcs = Integer.parseInt(dataEncStr, 16);
	    i = i + 2;

		if (sms_format.equals("incoming")) {
			// get timestamp.
			String tpScts = smspdu.substring(i, i + 7 * 2);
			smstime = pducode.TimeStampDecode(tpScts);
			i = i + 7*2;
		}

		if (sms_format.equals("outgoing")) {
			// Check different format for VPF field
			if ((smsDeliverCode - 4) % 2 == 1)
				i = i + 7 * 2; // +2 because additonal Validity field
			else if ((smsDeliverCode - 8) % 2 == 1)
				i = i + 2;
		}

		// get message length.
		String msgLenStr = smspdu.substring(i, i+2);
		tpUdl = Integer.parseInt(msgLenStr, 16);
		i = i + 2;

		// Get the number of blocks on an SMS
		int[] tpa = new int[7];      
		for(int j = 0; j<6; j++) {
			tpa[j] = -1;
			if((pdulen - i) > (2 + (j*2)))
				tpa[j] = Integer.parseInt(smspdu.substring(i+(j*2), i+(j*2)+2), 16);
		}

		// calculate encoded message length. tpDcs defines wheter message is 7 bit or 8 bit coded
		int encMsgLen = tpUdl;
		if ((tpDcs & 4) == 0) {
			encMsgLen = (tpUdl * 7) / 8;
			if (((tpUdl * 7) % 8) != 0) encMsgLen++;
		}

		// get message string.
		int subMsgLen = i + encMsgLen * 2;
		if(subMsgLen > smspdu.length()) subMsgLen = smspdu.length();
		String tpUd = smspdu.substring(i, subMsgLen);

		// decode depending on tpDcs settings (7 bit or 8 bit)
		if ((tpDcs & 4) == 0) msg = pducode.sevenBitDecode(tpUd, tpUdl);
		else msg = pducode.eightBitDecode(tpUd);

		// get right message portion
		message = msg;
		if(tpa[1] == 0) {
			message = msg.substring(7, msg.length());
		}

		if(message.length() > 32) {
			int pos = 0;
			int epos = message.indexOf(" ");
			if((epos > 4) && (epos < 16) && (message.length() > epos)) {
				code = message.substring(pos, epos).trim();
			}

			pos = message.toLowerCase().indexOf("ksh");
			if((pos > 0) && (pos+4 < message.length())) epos = message.indexOf(" ", (pos + 4));
			else epos = message.length()-1;
			if((pos > 0) && (epos < 0)) epos = message.length()-1;

			if((pos > 4) && (message.length() > epos)) {
				amount = message.substring(pos, epos).trim();
			}

			pos = message.toLowerCase().indexOf("account number");
			epos = message.indexOf(" ", (pos + 16));
			if((pos > 14) && (message.length() > epos)) {
				clientid = message.substring((pos + 14), epos).trim().toUpperCase();
			}

			pos = message.indexOf("2547");
			epos = pos + 12;
			if((pos > 14) &&  (message.length() > epos)) {
				msgNumber = "+" + message.substring(pos, epos).trim();
			}
		}

		if(amount != null) {
			amount = amount.toLowerCase().trim();
			if(amount.startsWith("ksh")) amount = amount.replaceAll("ksh", "").replaceAll(",", "");
			else amount = null;
			if(amount.endsWith(".")) amount = amount.substring(0, (amount.length()-1));
			amount = amount.trim();
			if("".equals(amount)) amount = null;
		}

		/*System.out.println("PDU SMS : " + smspdu);
		System.out.println("Format : " + sms_format);
		System.out.println("SMS Address : " + smscAddress);
		System.out.println("Sender Address : " + senderAddress);
		System.out.println("Time : " + smstime);
		System.out.println("Message Length : " + tpUdl);
		System.out.println("Block Size : " + encMsgLen);
		System.out.println("Block Start : " + i);
		if(tpa[1] == 0) {
			System.out.println("Part ID : " + tpa[3]);
			System.out.println("Total Parts : " + tpa[4]);
			System.out.println("Part Number : " + tpa[5]);
		}

		System.out.println("CODE : " + code);
		System.out.println("AMOUNT : " + amount);
		System.out.println("Client ID : " + clientid);*/

		try {
			byte[] utf8Bytes = message.getBytes("UTF8");
			String msgstr = new String(utf8Bytes, "UTF-8");
			message = msgstr;
		} catch(UnsupportedEncodingException ex) {
			log.severe("UTF Encode error : " + ex);
		}

		message = message.replace('\0', '@');
		log.info("SMS Message : " + senderAddress + " : " + message);

		if(db != null) {
			addSMS(db, tpa[1], tpa[3], tpa[4], tpa[5]);
		}

	}

	public void addSMS(BDB db, int tpb, int tpd, int tpe, int tpf) {
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		String stime = sdf.format(smstime);

		String mysql = "SELECT sms_trans_id, origin, sms_time, code, client_id, amount, sms_id, message, ";
		mysql += "in_words, sms_deleted, msg_number, part_id, part_no, part_message, part_count ";
		mysql += "FROM sms_trans ";
		mysql += "WHERE (origin = '" + senderAddress + "') AND (sms_time = '" + stime + "')";
		log.fine(mysql);
		BQuery rs = new BQuery(db, mysql);
		rs.setTableName("sms_trans");

		if(rs.moveNext()) {
			System.out.println("Data in the database.");
			rs.recEdit();
			rs.updateField("sms_id", Integer.toString(messageNum));
			rs.updateField("sms_deleted", "false");
			rs.recSave();
		} else {
			rs.recAdd();
			rs.updateField("origin", senderAddress);
			rs.updateField("sms_time", stime);
			rs.updateField("sms_id", Integer.toString(messageNum));
			rs.updateField("msg_number", msgNumber);
			if(code != null) rs.updateField("code", code);
			if(clientid != null) rs.updateField("client_id", clientid);
			if(amount != null) {
				try {
					DecimalFormat df = new DecimalFormat();
					Number d = df.parse(amount);
					rs.updateField("amount", d.toString());
					BAmountInWords dw = new BAmountInWords(d.intValue());
					rs.updateField("in_words", dw.getAmountInWords());
				} catch(NumberFormatException ex) {
					log.severe("Number error : " + ex);
				} catch(ParseException ex) {
					log.severe("Amount Conversion error : " + ex);
				}
			}
			if(message != null) {
				rs.updateField("message", message);
				if(tpb == 0) rs.updateField("part_message", message);
			}
			if(tpb == 0) {
				rs.updateField("part_id", Integer.toString(tpd));
				rs.updateField("part_no", Integer.toString(tpf));
				rs.updateField("part_count", Integer.toString(tpe));
			} else {
				rs.updateField("part_no", "1");
				rs.updateField("part_count", "1");
			}
			rs.recSave();
		}
		rs.close();
	}

	public String getSenderAddress() { return senderAddress; }
	public Date getSMSTime() { return smstime; }
	public String getMessage() { return message; }

}