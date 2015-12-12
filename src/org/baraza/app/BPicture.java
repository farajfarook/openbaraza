/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.app;

import java.io.File;

import javax.swing.Icon;
import javax.swing.ImageIcon;
import javax.swing.JLabel;
import javax.swing.JFileChooser;
import java.net.URL;

import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;

import org.baraza.xml.BElement;
import org.baraza.swing.BFileDialogueFilter;
import org.baraza.utils.BWebdav;
import org.baraza.DB.BDB;

public class BPicture extends JLabel implements MouseListener {

	String pictureFile = null;
	String pictureURL, pictureAccess;
	BDB db = null;	
	BWebdav webdav = null;

	public BPicture(BDB db, BElement el) {
		super();
		this.db = db;
		this.addMouseListener(this);

		pictureURL = el.getAttribute("pictures");
		pictureAccess = el.getAttribute("access");
		String repository = el.getAttribute("repository");
		String username = el.getAttribute("username");
		String password = el.getAttribute("password");
		webdav = new BWebdav(repository, username, password);
	}

	public void setPicture(String value) {
		pictureFile = value;
		String mypic = pictureURL + "?access=" + pictureAccess + "&picture=" + pictureFile;
		String html = "<html>\n<body>\n<div style=\"text-align: center;\">\n";
        html += "<img src='" + mypic + "'>\n";
        html += "</div>\n</body>\n</html>";

		this.setText(html);
	}

	public String getPicture() {
		return pictureFile;
	}

	public void readimage() {
		JFileChooser fc = new JFileChooser();
		String[] ffa = {"jpg", "jpeg", "gif"};
		BFileDialogueFilter ff = new BFileDialogueFilter(ffa, "Picure Images");
		fc.setFileFilter(ff);
		fc.setAcceptAllFileFilterUsed(false);
		int returnVal = fc.showOpenDialog(this);

        if (returnVal == JFileChooser.APPROVE_OPTION) {
			File file = fc.getSelectedFile();

			pictureFile = db.executeFunction("SELECT nextval('picture_id_seq')");
			pictureFile += "pic." + ff.getExtension(file);
			webdav.saveFile(file, pictureFile);

 			Icon icon = new ImageIcon(file.getPath());
			this.setIcon(icon);
		}
	}

    protected ImageIcon createImageIcon(String path, String description) {
        URL imgURL = getClass().getResource(path);
        if (imgURL != null) {
            return new ImageIcon(imgURL, description);
        } else {
            System.err.println("Couldn't find file: " + path);
            return null;
        }
    }

	public void mousePressed(MouseEvent ev) {}
	public void mouseReleased(MouseEvent ev) {}
	public void mouseEntered(MouseEvent ev) {}
	public void mouseExited(MouseEvent ev) {}
	public void mouseClicked(MouseEvent ev) {
		if (ev.getClickCount() == 2) {
			readimage();
		}
	}

}
