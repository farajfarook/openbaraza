/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */

import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.io.File;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.IOException;
import javax.xml.namespace.QName;

import com.googlecode.sardine.Sardine;
import com.googlecode.sardine.DavResource;
import com.googlecode.sardine.SardineFactory;

public class webdav {

	public static void main(String args[]) {
		String path = "http://kangaroo.dewcis.com:8082/alfresco/webdav/Sites/cases/documentLibrary/";
		webdav wd = new webdav(path, "admin", "Invent2k");
		wd.listDir("CS000001");
	
		File nf = new File("muhia.xls");
		wd.saveFile(nf, "muhia.xls");
	}

	Sardine sardine = null;
	String basePath = null;

	public webdav(String path, String userName, String passWord) {
		sardine = SardineFactory.begin(userName, passWord);
		basePath = path;
	}

	public void setPath(String path) {
		basePath = path;
	}

	public List<DavResource> listDir(String path) {
		List<DavResource> resources = new ArrayList<DavResource>();
		try {
			resources = sardine.list(basePath + path);
			for (DavResource res : resources)
				System.out.println(res); // calls the .toString() method.
		} catch(IOException ex) {
			System.out.println("File list error : " + ex);
		}
		return resources;
	}

	public InputStream getFile(String fileName) {
		InputStream is = null;
		try {
			is = sardine.get(basePath + fileName);
		} catch(IOException ex) {
			System.out.println("File read error : " + ex);
		}
		return is;
	}

	public boolean saveFile(File file, String saveName) {
		boolean isv = true;
		try {
System.out.println("BASE 2010 : " + basePath + saveName);
			InputStream fis = new FileInputStream(file);
			sardine.put(basePath + saveName, fis);
		} catch(IOException ex) {
			System.out.println("File write error : " + ex);
			isv = false;
		}
		return isv;
	}

	public boolean saveFile(InputStream fis, String saveName) {
		boolean isv = true;
		try {
System.out.println("BASE 2010 : " + basePath + saveName);
			sardine.put(basePath + saveName, fis);
		} catch(IOException ex) {
			System.out.println("File write error : " + ex);
			isv = false;
		}
		return isv;
	}

	public boolean delFile(String fileName) {
		boolean isv = true;
		try {
			sardine.delete(basePath + fileName);
		} catch(IOException ex) {
			System.out.println("File delete error : " + ex);
			isv = false;
		}
		return isv;
	}

	public boolean createDir(String dirName) {
		boolean isv = true;
		try {
			sardine.createDirectory(basePath + dirName);
		} catch(IOException ex) {
			System.out.println("Directory create error : " + ex);
			isv = false;
		}
		return isv;
	}

	public boolean fileMove(String srcName, String dstName) {
		boolean isv = true;
		try {
			sardine.move(basePath + srcName, basePath + dstName);
		} catch(IOException ex) {
			System.out.println("File move error : " + ex);
			isv = false;
		}
		return isv;
	}

	public boolean fileCopy(String srcName, String dstName) {
		boolean isv = true;
		try {
			sardine.copy(basePath + srcName, basePath + dstName);
		} catch(IOException ex) {
			System.out.println("File copy error : " + ex);
			isv = false;
		}
		return isv;
	}

	public boolean fileExists(String fileName) {
		boolean isv = true;
		try {
			isv = sardine.exists(basePath + fileName);
		} catch(IOException ex) {
			System.out.println("File Exists error : " + ex);
			isv = false;
		}
		return isv;
	}

	public boolean setProperties(String fileName, Map<QName,String> addProps, List<QName> removeProps) {
		boolean isv = true;
		try {
			sardine.patch(basePath + fileName, addProps, removeProps);
		} catch(IOException ex) {
			System.out.println("Set properties error : " + ex);
			isv = false;
		}
		return isv;
	}

	public Map<String,String> getProperties(DavResource resource) {
		Map<String,String> customProps = resource.getCustomProps();
		return customProps;
	}

}
