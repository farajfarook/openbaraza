/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.utils;

import java.security.MessageDigest;
import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.apache.commons.codec.binary.Base64;

public class BCipher {
	SecretKey key;
	Cipher cipher;
	Base64 coder;
	byte[] linebreak = {};

	public BCipher(String secret) {
		try {
			key = new SecretKeySpec(secret.getBytes(), "DES");
			cipher = Cipher.getInstance("DES");
			coder = new Base64(32,linebreak,true);
		} catch(java.security.NoSuchAlgorithmException ex) {
			System.out.println("Error; No such Algorithim : " + ex);
		} catch(javax.crypto.NoSuchPaddingException ex) {
			System.out.println("Error; no such padding : " + ex);
		}
	}

	public String encrypt(String plainText) {
		String codedText = "";

		try {
			cipher.init(Cipher.ENCRYPT_MODE, key);
			byte[] cipherText = cipher.doFinal(plainText.getBytes());
			codedText = new String(coder.encode(cipherText));
		} catch(java.security.InvalidKeyException ex) {
			System.out.println("Error; invalid key : " + ex);
		} catch(javax.crypto.IllegalBlockSizeException ex) {
			System.out.println("Error; Illegal block : " + ex);
		} catch(javax.crypto.BadPaddingException ex) {
			System.out.println("Error; Bad padding : " + ex);
		}

		return codedText;
	}

	public String decrypt(String codedText) {
		String decodedText = "";

		try {
			byte[] encypted = coder.decode(codedText.getBytes());
			cipher.init(Cipher.DECRYPT_MODE, key);
			byte[] decrypted = cipher.doFinal(encypted); 
			decodedText = new String(decrypted);
		} catch(java.security.InvalidKeyException ex) {
			System.out.println("Error; invalid key : " + ex);
		} catch(javax.crypto.IllegalBlockSizeException ex) {
			System.out.println("Error; Illegal block : " + ex);
		} catch(javax.crypto.BadPaddingException ex) {
			System.out.println("Error; Bad padding : " + ex);
		}

		return decodedText;
	}

	public String password(String  planpw) {
		String hash = null;
		try {
			MessageDigest md = MessageDigest.getInstance("SHA"); 	// SHA-1 generator instance
			md.update(planpw.getBytes("UTF-8")); 				// Message summary generation
			Base64 coder = new Base64(32);
			byte raw[] = md.digest(); 								// Message summary reception
			hash = new String(coder.encode(raw)); 					// Encoding to BASE64
			hash = hash.replace("\n", "");
		} catch(java.security.NoSuchAlgorithmException ex) {
			System.out.println("No algorithim : " + ex.getMessage());
		} catch(java.io.UnsupportedEncodingException ex) {
			System.out.println("Unsupported Encoding : " + ex.getMessage());
		}

		return hash;
	}
}
