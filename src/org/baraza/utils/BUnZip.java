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

import java.io.*;
import java.util.zip.*;

public class BUnZip {
	Logger log = Logger.getLogger(BUnZip.class.getName());

	public BUnZip(String zipfile, String outputdir, String owner) {
		final int BUFFER = 2048;
		
		try {
			BufferedOutputStream dest = null;
			FileInputStream fis = new FileInputStream(zipfile);
			ZipInputStream zis = new ZipInputStream(new BufferedInputStream(fis));
			ZipEntry entry;
			
			while((entry = zis.getNextEntry()) != null) {
				log.fine("Extracting: " + entry);
				int count;
				byte data[] = new byte[BUFFER];
				
				/* write the files to the disk */
				if(!entry.isDirectory()) {				
					File a = new File(outputdir + entry.getName());
					File b = new File(a.getParent());
					log.fine("Parent : " + a.getParent());
					if(!b.exists()) b.mkdirs();
	
					FileOutputStream fos = new FileOutputStream(outputdir + entry.getName());
					dest = new BufferedOutputStream(fos, BUFFER);
					while ((count = zis.read(data, 0, BUFFER)) != -1) {
						dest.write(data, 0, count);
					}
					dest.flush();
					dest.close(); 

					String command = "chown " + owner + " " + a.getAbsolutePath();
					Runtime r = Runtime.getRuntime();
					Process p = r.exec(command);
				}
			}
			zis.close();
		} catch(Exception ex) {
			log.severe("ZIP Error : " + ex.getMessage());
		}
	}
}
