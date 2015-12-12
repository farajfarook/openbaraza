/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.ide;

import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;

import java.util.logging.Logger;
import java.io.File;
import java.awt.Font;

import javax.swing.JFileChooser;
import javax.swing.JScrollPane;

import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;

import org.baraza.utils.Bio;
import org.baraza.swing.BTextArea;
import org.baraza.utils.BLogHandle;

public class BFileEdit implements KeyListener{
	Logger log = Logger.getLogger(BFileEdit.class.getName());
	public JScrollPane scrollPanes;
	File dbFile = null;
	String dbDirName = null;
	BTextArea textArea;
	Bio io;

	public BFileEdit(File lfile, BLogHandle logHandle) {
		logHandle.config(log);
		
		dbFile = lfile;
		textArea = new BTextArea(logHandle);
		textArea.setTabSize(4);
		scrollPanes = new JScrollPane(textArea);

		io = new Bio();
		textArea.setText(io.loadFile(dbFile));
		textArea.setCaretPosition(0);
		textArea.addKeyListener(this);
		textArea.setFont(new Font("Monospaced", Font.PLAIN, 12));
		Font font = textArea.getFont(); 
		
		
		//System.out.println(textArea.getTabSize() + " : " + font.getFontName());
	}

	public BFileEdit(String dbDirName, BLogHandle logHandle) {
		this.dbDirName = dbDirName;
		logHandle.config(log);
		
		textArea = new BTextArea(logHandle);
		textArea.addKeyListener(this);
		textArea.setTabSize(4);
		scrollPanes = new JScrollPane(textArea);

		io = new Bio();
	}

	public void saveFile() {
		if(dbFile == null) saveAsFile();
		else io.saveFile(dbFile, textArea.getText());

		log.info("File saved : "  + getCurrentDate("yyyy/MM/dd HH:mm:ss"));
	}

	public void saveAsFile() {
		JFileChooser fc = new JFileChooser(dbDirName);
		int i = fc.showSaveDialog(textArea);
		if (i == JFileChooser.APPROVE_OPTION) {
		  dbFile = fc.getSelectedFile();
		  saveFile();
		}
	}

	public String getName() {
		String flName = "new.sql";
		if(dbFile != null) flName = dbFile.getName();
		return flName;
	}

	public String getText() {
		return textArea.getText();
	}

	public void setText(String mystr) {
		textArea.setText(mystr);
	}

	public void appendText(String mystr) {
		mystr += "\n" + mystr;
		textArea.append(mystr);
	}
	
	public static String getCurrentDate(String format){
		String mydate = "";
		DateFormat dateFormat = new SimpleDateFormat(format);
		Date date = new Date();
	        mydate = ""+dateFormat.format(date);
	   return mydate;
	}
	
	@Override
	public void keyPressed(KeyEvent e) {
	  if (e.isControlDown() && e.getKeyChar() != 's' && e.getKeyCode() == 83) {
	      saveFile();
	  }else if (e.isControlDown() && e.isShiftDown() && e.getKeyChar() != 's' && e.getKeyCode() == 83) {
	      saveAsFile();
	      System.out.println("File Saved As " );
	  }
		
		
	}
	@Override
	public void keyReleased(KeyEvent e) {
		
	}

	@Override
	public void keyTyped(KeyEvent e) {
		
	}

}

