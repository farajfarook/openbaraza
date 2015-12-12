/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.web;

import java.io.OutputStream;
import java.io.InputStream;
import java.io.IOException;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.utils.BWebdav;

public class BWebPictures extends HttpServlet {
	BDB db = null;
	BWebdav webdav = null;
	String photo_access;

	public void doPost(HttpServletRequest request, HttpServletResponse response)  {
		doGet(request, response);
	}

	public void doGet(HttpServletRequest request, HttpServletResponse response) {
		String dbconfig = "java:/comp/env/jdbc/database";
		db = new BDB(dbconfig);

		ServletContext config = this.getServletContext();
		photo_access = config.getInitParameter("photo_access");
		if(photo_access == null) photo_access = "";
		String repository = config.getInitParameter("repository_url");
		String username = config.getInitParameter("rep_username");
		String password = config.getInitParameter("rep_password");
System.out.println("repository : " + repository);
		webdav = new BWebdav(repository, username, password);
		
		String sp = request.getServletPath();
		if(sp.equals("/barazapictures")) showPhoto(request, response);
		if(sp.equals("/delbarazapictures")) delPhoto(request, response);

		db.close();
	}

	public void showPhoto(HttpServletRequest request, HttpServletResponse response) {
		String pictureFile = request.getParameter("picture");
		String access = request.getParameter("access");
		InputStream in = webdav.getFile(pictureFile);

		int dot = pictureFile.lastIndexOf(".");
        String ext = pictureFile.substring(dot + 1);

		if((photo_access.equals(access)) && (in != null)) {
			try {
				response.setContentType("image/" + ext);  
				OutputStream out = response.getOutputStream();

				int bufferSize = 1024;
				byte[] buffer = new byte[bufferSize];
				int c = 0;
				while ((c = in.read(buffer)) != -1) out.write(buffer, 0, c);

				in.close();
				out.flush(); 
			} catch(IOException ex) {
				System.out.println("IO Error : " + ex);
			}
		}
	}

	public void delPhoto(HttpServletRequest request, HttpServletResponse response) {
		String pictureFile = request.getParameter("picture");
		String access = request.getParameter("access");

		if(photo_access.equals(access))
			webdav.delFile(pictureFile);
	}

}