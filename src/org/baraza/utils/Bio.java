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

import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.BufferedReader;

import java.net.URL;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;

public class Bio {
	Logger log = Logger.getLogger(Bio.class.getName());

	public boolean create(String configDir, String path, String xmlfile, String xmldata) {
		String ps = System.getProperty("file.separator");
		String projectDir = configDir + path;
		boolean success = mkdir(projectDir);
		
		if(success) {
			projectDir += ps;
			mkdir(projectDir + "configs");
			mkdir(projectDir + "database");
			mkdir(projectDir + "database" + ps + "setup");		
			mkdir(projectDir + "reports");
			mkdir(projectDir + "docs");

			saveFile(projectDir + "configs" + ps + xmlfile, xmldata);
			saveFile(projectDir + "database" + ps + path + ".sql", "---Project Database File");
			saveFile(projectDir + "docs" + ps + "TODO", "TODO");
		}

		return success;
	}

	public String getCurrentDir() {
		File directory = new File (".");
		String dirName = null;
		try {
			dirName = directory.getCanonicalPath();
		} catch(IOException ex) {
			log.severe("Current directory get error : " + ex);
		}
		return dirName;
	}

	public boolean mkdir(String dirName) {
		File dir = new File(dirName);
		return dir.mkdirs();
	}

	public boolean FileExists(String fileName) {
		File fl = new File(fileName);
		boolean flExists = fl.exists();
		return flExists;
	}

	public String loadFile(File file) {
		String fileContent = "";
		try {
			FileReader fr = new FileReader(file);
			fileContent = loadFile(fr);
			fr.close();
		} catch (IOException ex) {
			log.severe("File Read error : " + ex);
		}

		return fileContent;
	}

	public String loadFile(String fileName) {
		String fileContent = "";
		try {
			FileReader fr = new FileReader(fileName);
			fileContent = loadFile(fr);
			fr.close();
		} catch (IOException ex) {
			log.severe("File Read error : " + ex);
		}

		return fileContent;
	}

	public String loadFile(FileReader fr) {
		String fileContent = "";
		try {
			BufferedReader br = new BufferedReader(fr);
			String s;
			while((s = br.readLine()) != null) {
				fileContent += s + "\n";
			}
			br.close();
			fr.close();
		} catch (IOException ex) {
			log.severe("File Read error : " + ex);
		}
		return fileContent;
	}

	public void saveFile(String fileName, String mystr, boolean append) {
		try {
			FileWriter output = new FileWriter(fileName, append);
			output.write(mystr);
			output.close();
		} catch (IOException ex) {
			log.severe("File Write error : " + ex);
		}
	}

	public void saveFile(String fileName, String mystr) {
		saveFile(fileName, mystr, false);
	}

	public void saveFile(File file, String mystr) {
		try {
			FileWriter output = new FileWriter(file);
			output.write(mystr);
			output.close();
		} catch (IOException ex) {
			log.severe("File Write error : " + ex);
		}
	}

	public void saveFile(File file, InputStream in) {
		try {
			OutputStream out = new FileOutputStream(file);
			byte buf[]=new byte[1024];
			int len;
			while((len=in.read(buf))>0) out.write(buf,0,len);
			out.close();
		} catch (IOException ex) {
			log.severe("File Write error : " + ex);
		}
	}

	// Load an icon image
    public BufferedImage loadImage(String path) {
		URL imgURL = Bio.class.getResource(path);
        if (imgURL != null) {
			try {
				return ImageIO.read(imgURL);
			} catch (IOException ex) {
				log.severe("Icon loading error : " + ex);
			}
		} else {
            log.severe("Couldn't find file : " + path);
		}

		return null;
    }
}