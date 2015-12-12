/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.utils;

import java.util.logging.Logger;
 
import java.io.FileOutputStream;
import java.io.IOException;
 
import com.itextpdf.text.Document;
import com.itextpdf.text.DocumentException;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.pdf.PdfWriter;
import com.itextpdf.text.pdf.PdfReader;
import com.itextpdf.text.pdf.PdfStamper;
 
public class Bpdf { 
 
    /**
     * Creates a PDF document.
     * @param filename the path to the new PDF document
     * @param passwd the input Password
     * @throws DocumentException 
     * @throws IOException 
     */
    public void createPdf(String filename, String passwd) throws IOException, DocumentException {
		byte[] USER = passwd.getBytes(); 	/** User password. */
		byte[] OWNER = passwd.getBytes();	/** Owner password. */

        // step 1
        Document document = new Document();
        // step 2
        PdfWriter writer = PdfWriter.getInstance(document, new FileOutputStream(filename));
        writer.setEncryption(USER, OWNER, PdfWriter.ALLOW_PRINTING, PdfWriter.STANDARD_ENCRYPTION_128);
        writer.createXmpMetadata();
        // step 3
        document.open();
        // step 4
        document.add(new Paragraph("Hello World"));
        // step 5
        document.close();
    }
 
    /**
     * Manipulates a PDF file src with the file dest as result
     * @param src the original PDF
     * @param dest the resulting PDF
     * @param passwd the input Password
     * @throws IOException
     * @throws DocumentException
     */
    public void decryptPdf(String src, String dest, String passwd) {
		try {
			byte[] USER = passwd.getBytes(); 	/** User password. */
			byte[] OWNER = passwd.getBytes();	/** Owner password. */

			PdfReader reader = new PdfReader(src, OWNER);
			PdfStamper stamper = new PdfStamper(reader, new FileOutputStream(dest));
			stamper.close();
		} catch(DocumentException ex) {
			System.out.println("PDF Conversion error");
		} catch(IOException ex) {
			System.out.println("PDF IO error");
		}
    }
 
    /**
     * Manipulates a PDF file src with the file dest as result
     * @param src the original PDF
     * @param dest the resulting PDF
     * @param passwd the input Password
     * @throws IOException
     * @throws DocumentException
     */
    public void encryptPdf(String src, String dest, String passwd) {
		try {
			byte[] USER = passwd.getBytes(); 	/** User password. */
			byte[] OWNER = passwd.getBytes();	/** Owner password. */

			PdfReader reader = new PdfReader(src);
			PdfStamper stamper = new PdfStamper(reader, new FileOutputStream(dest));
			stamper.setEncryption(USER, OWNER, PdfWriter.ALLOW_PRINTING, PdfWriter.ENCRYPTION_AES_128 | PdfWriter.DO_NOT_ENCRYPT_METADATA);
			stamper.close();
		} catch(DocumentException ex) {
			System.out.println("PDF Conversion error");
		} catch(IOException ex) {
			System.out.println("PDF IO error");
		}
    }
 
}

