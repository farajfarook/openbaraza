/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.sms;

import java.lang.Math;

public class BSMSOut {

	private int smscAddressType = 0x91;
	private int tpMsgRef = 0;
	private int recipientAddressType = 0x91;
	private int tpValidity = 0xAA;
	private int tpPid = 0x00;
	private int tpDcs = 0x00;
	String pdu = "";

	public BSMSOut(String recipientAddress, String msg, int msgno, int msgcount) {
		BPDUCode pducode = new BPDUCode();
		StringBuffer sb = new StringBuffer(1024);

        // Internal smsc Adress settings taken from mobile
        // if other add smscAddressType and smscAddressType to sb.
		String smscAddress = "";
		if(smscAddress.startsWith("+"))
			smscAddress = smscAddress.substring(1);
		String smscAddressEnc = "";
		int smscAddressLength = smscAddress.length();
		if(smscAddressLength == 0) {
			sb.append("00");
		} else  {
			// add smscAddressType and smscAddressType to sb.
			sb.append(pducode.toHexString(0x07));

			if((smscAddressLength%2) == 1) smscAddressEnc = pducode.swapDigits(smscAddress + "F");
			else smscAddressEnc = pducode.swapDigits(smscAddress);

			sb.append(pducode.toHexString(smscAddressType));
			sb.append(smscAddressEnc);
        }

		if(msgcount > 0) sb.append(pducode.toHexString(0x41));
		else sb.append(pducode.toHexString(0x01));
		
		sb.append(pducode.toHexString(tpMsgRef));

		// recipientAddress
		String recipientAddressEnc = "";
		if(recipientAddress.startsWith("+"))
			recipientAddress = recipientAddress.substring(1);
		int recipientAddressLength = recipientAddress.length();
		if ((recipientAddress.length() % 2) == 1 )
			recipientAddressEnc = pducode.swapDigits(recipientAddress+"F");
		else
			recipientAddressEnc = pducode.swapDigits(recipientAddress);

		sb.append(pducode.toHexString(recipientAddressLength));
		sb.append(pducode.toHexString(recipientAddressType));
		sb.append(recipientAddressEnc);
		sb.append(pducode.toHexString(tpPid));
		sb.append(pducode.toHexString(tpDcs));

		// encode message and calculate message length.
		String tpUd = "";
		int tpUdl = 0;
		if ((tpDcs & 4) == 0) {
			if(msgcount > 0) {
				msgcount++;
				msgno++;
				tpUd = "05" + "00" + "03" + "00";
				tpUd += pducode.toHexString(msgcount) + pducode.toHexString(msgno) + pducode.sevenBitEncode(msg, 1);
				tpUdl = msg.length() + 7;
			} else {
				tpUd = pducode.sevenBitEncode(msg);
				tpUdl = msg.length();
			}
		} else {
			tpUd = msg;
			tpUdl = msg.length() / 2;
        }
		sb.append(pducode.toHexString(tpUdl));
		sb.append(tpUd);

		pdu = sb.toString().toUpperCase();
    }

	public String toString() {
		return pdu;
	}

	public int length() {
		if ((pdu.substring(0,2)).equals("00")) return (pdu.length()-2)/2;
		else return (pdu.length()-16)/2;
	}

}
