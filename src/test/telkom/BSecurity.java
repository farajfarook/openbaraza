import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.AlgorithmParameterSpec;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.CipherOutputStream;
import javax.crypto.SecretKey;
import javax.crypto.KeyGenerator;
import java.io.UnsupportedEncodingException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileInputStream; 
import java.io.FileOutputStream;

public class BSecurity {

    Cipher ecipher;
    Cipher dcipher;
    byte[] buf = new byte[1024];

	public String MD5(String mystr) {
		String hstr = "";
		try {
			MessageDigest digest = MessageDigest.getInstance("MD5");
			digest.update(mystr.getBytes("UTF8"));
			byte[] hash = digest.digest();
			hstr = hexToString(hash);
		} catch(NoSuchAlgorithmException ex) {
			System.out.println("Security Exception : " + ex);
		} catch(UnsupportedEncodingException ex) {
			System.out.println("Encoding Exception : " + ex);
		}

		return hstr;
	}

	public String randomMD5() {
		String hstr = "";
		try {
			SecureRandom random = new SecureRandom();
			byte rb[] = new byte[20];
			random.nextBytes(rb);

			MessageDigest digest = MessageDigest.getInstance("MD5");
			digest.update(rb);
			byte[] hash = digest.digest();
			hstr = hexToString(hash);
		} catch(NoSuchAlgorithmException ex) {
			System.out.println("Security Exception : " + ex);
		}

		return hstr;
	}

	public String hexToString(byte[] arr) {
		StringBuffer sb = new StringBuffer();
		for (int i = 0; i < arr.length; ++i) {
			sb.append(Integer.toHexString((arr[i] & 0xFF) | 0x100).substring(1,3));
		}
		return sb.toString();
	}

	public void encriptFile() {
		try {
			// Generate a temporary key. In practice, you would save this key.
			// See also Encrypting with DES Using a Pass Phrase.
			SecretKey key = KeyGenerator.getInstance("DES").generateKey();

			// Create encrypter/decrypter class
			DesEncrypter(key);

			// Encrypt
			encrypt(new FileInputStream("cleartext1"), new FileOutputStream("ciphertext"));

			// Decrypt
			decrypt(new FileInputStream("ciphertext"), new FileOutputStream("cleartext2"));
		} catch (Exception e) {
		}
	}

	public void DesEncrypter(SecretKey key) {
		// Create an 8-byte initialization vector
		byte[] iv = new byte[]{(byte)0x8E, 0x12, 0x39, (byte)0x9C, 0x07, 0x72, 0x6F, 0x5A};
		AlgorithmParameterSpec paramSpec = new IvParameterSpec(iv);
		try {
			ecipher = Cipher.getInstance("DES/CBC/PKCS5Padding");
			dcipher = Cipher.getInstance("DES/CBC/PKCS5Padding");

			// CBC requires an initialization vector
			ecipher.init(Cipher.ENCRYPT_MODE, key, paramSpec);
			dcipher.init(Cipher.DECRYPT_MODE, key, paramSpec);
		} catch (java.security.InvalidAlgorithmParameterException ex) {
		} catch (javax.crypto.NoSuchPaddingException ex) {
		} catch (java.security.NoSuchAlgorithmException ex) {
		} catch (java.security.InvalidKeyException ex) {
		}
	}

	public void encrypt(InputStream in, OutputStream out) {
		try {
			// Bytes written to out will be encrypted
			out = new CipherOutputStream(out, ecipher);

			// Read in the cleartext bytes and write to out to encrypt
			int numRead = 0;
			while ((numRead = in.read(buf)) >= 0) {
				out.write(buf, 0, numRead);
			}
			out.close();
		} catch (java.io.IOException e) {
		}
	}

	public void decrypt(InputStream in, OutputStream out) {
		try {
			// Bytes read from in will be decrypted
			in = new CipherInputStream(in, dcipher);

			// Read in the decrypted bytes and write the cleartext to out
			int numRead = 0;
			while ((numRead = in.read(buf)) >= 0) {
				out.write(buf, 0, numRead);
			}
			out.close();
		} catch (java.io.IOException e) {
		}
	}

}

