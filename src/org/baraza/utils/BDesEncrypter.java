/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.utils;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;

import java.security.spec.AlgorithmParameterSpec; 
import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.CipherInputStream;
import javax.crypto.CipherOutputStream;
import javax.crypto.spec.SecretKeySpec;
import javax.crypto.spec.IvParameterSpec;

public class BDesEncrypter {
	Cipher ecipher;
	Cipher dcipher;

	public static void main(String args[]) {
		// Create encrypter/decrypter class
		BDesEncrypter encrypter = new BDesEncrypter("access");

		// Encrypt
		encrypter.encrypt("keys.txt", "keys.cph");

		// Decrypt
		encrypter.decrypt("keys.cph", "keys.new.txt");
	}
    
	public BDesEncrypter(String secret) {
		// See also Encrypting with DES Using a Pass Phrase.
		secret = secret + "123456789";
		secret = secret.substring(0, 8);
		SecretKey key = new SecretKeySpec(secret.getBytes(), "DES");

		// Create an 8-byte initialization vector
		byte[] iv = new byte[]{0x0a, 0x01, 0x02, 0x03, 0x04, 0x0b, 0x0c, 0x0d};
		AlgorithmParameterSpec paramSpec = new IvParameterSpec(iv);
		try {
			ecipher = Cipher.getInstance("DES/CBC/PKCS5Padding");
			dcipher = Cipher.getInstance("DES/CBC/PKCS5Padding");

			// CBC requires an initialization vector
			ecipher.init(Cipher.ENCRYPT_MODE, key, paramSpec);
			dcipher.init(Cipher.DECRYPT_MODE, key, paramSpec);
		} catch (java.security.InvalidAlgorithmParameterException ex) {
			System.out.println("Error : " + ex);
		} catch (javax.crypto.NoSuchPaddingException ex) {
			System.out.println("Error : " + ex);
		} catch (java.security.NoSuchAlgorithmException ex) {
			System.out.println("Error : " + ex);
		} catch (java.security.InvalidKeyException ex) {
			System.out.println("Error : " + ex);
		}
	}

	public void encrypt(String inFileName, String outFileName) {
		try {
			// Encrypt
			encrypt(new FileInputStream(inFileName), new FileOutputStream(outFileName));
		} catch (Exception ex) {
			System.out.println("Error : " + ex);
		}
	}

	public void encrypt(InputStream in, OutputStream out) {
		byte[] buf = new byte[1024];
		try {
			// Bytes written to out will be encrypted
			out = new CipherOutputStream(out, ecipher);

			// Read in the cleartext bytes and write to out to encrypt
			int numRead = 0;
			while ((numRead = in.read(buf)) >= 0) {
				out.write(buf, 0, numRead);
			}
			out.close();
			in.close();
		} catch (java.io.IOException ex) {
			System.out.println("IO Error : " + ex);
		}
	}

	public void decrypt(String inFileName, String outFileName) {
		try {
			// Decrypter file by name
			decrypt(new FileInputStream(inFileName), new FileOutputStream(outFileName));
		} catch (Exception ex) {
			System.out.println("Error : " + ex);
		}
	}

	public void decrypt(InputStream in, OutputStream out) {
		byte[] buf = new byte[1024];
		try {
			// Bytes read from in will be decrypted
			in = new CipherInputStream(in, dcipher);

			// Read in the decrypted bytes and write the cleartext to out
			int numRead = 0;
			while ((numRead = in.read(buf)) >= 0) {
				out.write(buf, 0, numRead);
			}
			out.close();
			in.close();
		} catch (java.io.IOException ex) {
			System.out.println("IO Error : " + ex);
		}
	}

	public InputStream decrypt(String inFileName) {
		InputStream in = null;
		try {
			// Decrypter file by name
			in = decrypt(new FileInputStream(inFileName));
		} catch (Exception ex) {
			System.out.println("Error : " + ex);
		}
		return in;
	}

	public InputStream decrypt(InputStream in) {
		// Bytes read from in will be decrypted
		in = new CipherInputStream(in, dcipher);
		return in;
	}

}

