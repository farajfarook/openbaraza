/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.ide;

import java.util.logging.Logger;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;
import java.io.File;
import java.awt.BorderLayout;

import javax.swing.JTabbedPane;
import javax.swing.JPanel;
import javax.swing.JTextArea;
import javax.swing.JButton;
import javax.swing.JScrollPane;
import javax.swing.JFileChooser;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import org.baraza.xml.*;
import org.baraza.DB.*;
import org.baraza.utils.Bio;
import org.baraza.utils.BLogHandle;

public class BEdit implements ActionListener {
	Logger log = Logger.getLogger(BEdit.class.getName());
	public JPanel panel;
	JPanel controls;
	JButton[] button;
	JTabbedPane tabFileView;
	List<BFileEdit> fileEdit;
	String dbDirName;
	BDB db;
    BLogHandle logHandle;
    
	public BEdit(String dbDirName, BDB db, BLogHandle logHandle) {
		this.db = db;
		this.dbDirName = dbDirName;
		panel = new JPanel(new BorderLayout());
		tabFileView = new JTabbedPane();
		panel.add(tabFileView, BorderLayout.CENTER);
        this.logHandle = logHandle;
		logHandle.config(log);
		controls = new JPanel();
		String[] btArray = {"New", "Open", "Save", "Save As", "Close", "Execute", "Batch Execute", "Execute All", "Views", "Tables"};
		button = new JButton[btArray.length];		
		for(int i = 0; i < btArray.length; i++) {
			button[i] = new JButton(btArray[i]);
			button[i].addActionListener(this);
			controls.add(button[i]);
		}
		panel.add(controls, BorderLayout.PAGE_START);

		File dbDir = null;
		if(!dbDirName.startsWith("http")) dbDir = new File(dbDirName);

		if(dbDir != null) {
			if(dbDir.exists()) {
				File[] dbFiles = dbDir.listFiles();
				Arrays.sort(dbFiles);
				fileEdit = new ArrayList<BFileEdit>();
				for (int i = 0; i<dbFiles.length; i++) {
					if(dbFiles[i].isFile()) {
						if(!dbFiles[i].getName().startsWith(".")) {
							fileEdit.add(new BFileEdit(dbFiles[i], logHandle));
							tabFileView.add(dbFiles[i].getName(), fileEdit.get(fileEdit.size()-1).scrollPanes);
						}
					}
				}
			}
		}
	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		int i = tabFileView.getSelectedIndex();
		if("New".equals(aKey)) {
			fileEdit.add(new BFileEdit(dbDirName, logHandle));
			tabFileView.add("new.sql", fileEdit.get(fileEdit.size()-1).scrollPanes);
		} else if("Open".equals(aKey)) {
			JFileChooser fc = new JFileChooser(dbDirName);
			int j = fc.showOpenDialog(panel);
			if (j == JFileChooser.APPROVE_OPTION) {
				fileEdit.add(new BFileEdit(fc.getSelectedFile(), logHandle));
				tabFileView.add(fc.getSelectedFile().getName(), fileEdit.get(fileEdit.size()-1).scrollPanes);
			}
		} else if("Save As".equals(aKey)) {
			fileEdit.get(i).saveAsFile();
			tabFileView.setTitleAt(i, fileEdit.get(i).getName());
		} else if("Save".equals(aKey)) {
			fileEdit.get(i).saveFile();
			tabFileView.setTitleAt(i, fileEdit.get(i).getName());
		} else if("Close".equals(aKey)) {
			tabFileView.remove(i);
			fileEdit.remove(i);
		} else if("Execute".equals(aKey)) {
			log.info("Preparing Excecution...");
			String err = db.executeQuery(fileEdit.get(i).getText());
			if(err == null) log.info("Excecuted Successfully");
		} else if("Batch Execute".equals(aKey)) {
			log.info("Preparing Excecution...");
			String err = db.executeBatch(fileEdit.get(i).getText());
			if(err == null) log.info("Excecuted Successfully");
		} else if("Execute All".equals(aKey)) {
			executeAll();
		} else if("Views".equals(aKey)) {
			fileEdit.get(i).appendText(db.getViewSQL());
		} else if("Tables".equals(aKey)) {
			fileEdit.get(i).appendText(getTables());
		}
	}
	
	public void executeAll() {
		String err = null;
		int i = 0;
		log.info("Preparing Excecution...");
		for(BFileEdit fe : fileEdit) {
			if(err == null) {
				err = db.executeQuery(fe.getText());
				tabFileView.setSelectedIndex(i);
				i++;
			}
			if(err == null) log.info("Excecuted Successfully");
			
		}
	}

	public String getTables() {
		String tbn = "";
		int i = tabFileView.getSelectedIndex();
		String tbs[] = fileEdit.get(i).getText().split("\n");
		for(String tb : tbs) {
			if(tb.trim().toUpperCase().startsWith("CREATE TABLE"))
				tbn += "\n" + tb.replace("CREATE TABLE", "").replace("(", "").trim();
		}
		return tbn;
	}
}
