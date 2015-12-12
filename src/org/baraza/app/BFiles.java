/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.app;

import java.util.logging.Logger;
import java.io.File;
import java.io.InputStream;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.net.URLConnection;

import javax.swing.JPanel;
import javax.swing.JButton;
import javax.swing.JFileChooser;
import javax.swing.JOptionPane;
import java.awt.BorderLayout;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BElement;
import org.baraza.utils.Bio;
import org.baraza.utils.BWebdav;
import org.baraza.utils.BLogHandle;

class BFiles extends JPanel implements ActionListener {
	Logger log = Logger.getLogger(BFiles.class.getName());

	String linkValue, linkField, fileTable;
	Map<String, String> params;
	BWebdav webdav;
	BGrid grid;
	BQuery query;
	List<JButton> fileFunct;
	JPanel fileControls;

	public BFiles(BLogHandle logHandle, BDB db, BElement view) {
		super(new BorderLayout());

		linkField = view.getAttribute("linkfield");
		fileTable = view.getAttribute("filetable");
		linkValue = null;
		params = new HashMap<String, String>();

		fileFunct = new ArrayList<JButton>();
		fileControls =  new JPanel();
		fileFunct.add(new JButton("Upload File"));
		fileFunct.add(new JButton("Download File"));
		fileFunct.add(new JButton("Delete File"));
		for(JButton btn : fileFunct) { fileControls.add(btn); btn.addActionListener(this); }
		super.add(fileControls, BorderLayout.PAGE_START);

		String repository = view.getAttribute("repository");
		String username = view.getAttribute("username");
		String password = view.getAttribute("password");
		webdav = new BWebdav(repository, username, password);

		query = new BQuery(db, view, null, null, false);
		grid = new BGrid(logHandle, db, view, "");
		grid.showMain();
		super.add(grid, BorderLayout.CENTER);
	}

	public void link(String linkValue, Map<String, String> params) {
		this.linkValue = linkValue;
		this.params = params;
		grid.link(linkValue);
	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("Upload File".equals(aKey)) {
			JFileChooser fc = new JFileChooser();
			int returnVal = fc.showOpenDialog(this);
			if (returnVal == JFileChooser.APPROVE_OPTION) {
				File file = fc.getSelectedFile();
				String contentType = URLConnection.guessContentTypeFromName(file.getName());
				long fs = file.length();
				
				query.recAdd();
				query.updateField("file_name", file.getName());
				if(linkField != null) query.updateField(linkField, linkValue);
				if(fileTable != null) query.updateField("table_name", fileTable);
				if(contentType != null) query.updateField("file_type", contentType);
				query.updateField("file_size", String.valueOf(fs));
				query.recSave();

				String wdfn = query.getKeyField() + "ob.bwd";
				webdav.saveFile(file, wdfn);

				grid.refresh();
			}
		} else if("Download File".equals(aKey)) {
			String wdfn = grid.getKey();
			if(wdfn != null) {
				wdfn += "ob.bwd";
				String fileName = grid.readField("file_name");
				System.out.println("File : " + wdfn);
				JFileChooser fc = new JFileChooser();
				fc.setSelectedFile(new File(fileName));
				int returnVal = fc.showSaveDialog(this);
				if (returnVal == JFileChooser.APPROVE_OPTION) {
					File file = fc.getSelectedFile();
					InputStream is = webdav.getFile(wdfn);
					Bio io = new Bio();
					io.saveFile(file, is);
				}
			}
		} else if("Delete File".equals(aKey)) {
			int n = JOptionPane.showConfirmDialog(this, "Are you sure you want to delete the file?", "Deletion", JOptionPane.YES_NO_OPTION);
			String wdfn = grid.getKey();
			if((wdfn != null) && (n == 0)) {
				query.filter(query.getKeyFieldName() + " = '" + wdfn + "'", null);
				query.moveFirst();
				query.recDelete();

				wdfn += "ob.bwd";
				webdav.delFile(wdfn);
				
				grid.refresh();
			}
		}
	}

}

