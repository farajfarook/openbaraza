/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.swing;

import java.awt.Color;
import java.awt.Toolkit;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.ClipboardOwner;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.StringSelection;
import java.awt.datatransfer.Transferable;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.io.IOException;
import java.util.logging.Logger;

import javax.swing.JMenuItem;
import javax.swing.JPopupMenu;
import javax.swing.JTextArea;
import javax.swing.SwingUtilities;
import javax.swing.event.UndoableEditEvent;
import javax.swing.event.UndoableEditListener;
import javax.swing.undo.CannotRedoException;
import javax.swing.undo.CannotUndoException;
import javax.swing.undo.UndoManager;

import org.baraza.utils.BLogHandle;

public class BTextArea extends JTextArea implements KeyListener,MouseListener,ClipboardOwner,UndoableEditListener,ActionListener{
	UndoManager undo;
	JPopupMenu contextMenu;
	JMenuItem mnuCopy, mnuPaste, mnuCut,mnuUndo, mnuRedo;
	Logger log = Logger.getLogger(BTextArea.class.getName());
	
	int undoCounter;
	//TODO - add find   http://www.youtube.com/watch?v=o7noU1io1BE
	
	
	
	
	public BTextArea(BLogHandle logHandle){
		this.undo = new UndoManager();
		this.getDocument().addUndoableEditListener(this);
		this.addKeyListener(this);
		this.addMouseListener(this);
		this.undoCounter = 0;
		logHandle.config(this.log);
	}
	
	
	
	@Override
	public void undoableEditHappened(UndoableEditEvent e) {
		undo.addEdit(e.getEdit());
		undoCounter +=1;
		
	}
	
	public void BUndo(){
		if(undoCounter <=0){
			log.info("Cannot Undo Further : " + undoCounter);
		}else{
			try {
				this.undo.undo();
				this.undoCounter -=1;
			} catch (CannotUndoException ex) {
				log.info("Unable to undo: " + ex);
				ex.printStackTrace();
			}
		}
		
	}
	
	public void BRedo(){
		if(undoCounter >= undo.getLimit()){
			log.info("Cannot ReDo Further : " + undoCounter + "\nLimit : " + undo.getLimit());
		}else{
			try {
			    this.undo.redo();
			    this.undoCounter +=1;
			} catch (CannotRedoException ex) {
				log.info("Unable to redo:Counter " + undoCounter+ "\nLimit : " + undo.getLimit()+"\nUnable to redo: " + ex);
			    ex.printStackTrace();
			}
		}
		
	}

	@Override
	public void keyPressed(KeyEvent e) {
	 if (e.isControlDown() && e.getKeyCode() == 90) {//undo ctrl+z
	      BUndo();	      
	  }else if (e.isControlDown() && e.getKeyCode() == 89) {//redo ctrl+y
	      BRedo();		
	  }else if(e.isControlDown() && e.getKeyCode() == 70){//find ctrl+f
		  findReplace();
	  }
		
		
	}
	
	public void findReplace(){
		BFindReplaceDialog fr = new BFindReplaceDialog(this);
		fr.setVisible(true);
		fr.setLocationRelativeTo(this);
	}
	
	@Override
	public void mouseClicked(MouseEvent e) {
		
		if(SwingUtilities.isRightMouseButton(e)){
			contextMenu = new JPopupMenu();
			contextMenu.setBackground(Color.LIGHT_GRAY);
			
			mnuCopy = new JMenuItem("Copy");
			mnuPaste = new JMenuItem("Paste");
			mnuCut = new JMenuItem("Cut");
			mnuUndo = new JMenuItem("Undo");
			mnuRedo = new JMenuItem("Redo");
			
			
			mnuCopy.addActionListener(this); 
			mnuPaste.addActionListener(this);
			mnuCut.addActionListener(this);
			mnuUndo.addActionListener(this);
			mnuRedo.addActionListener(this);
			
			contextMenu.add(mnuCopy);
			contextMenu.add(mnuPaste);
			contextMenu.add(mnuCut);
			contextMenu.add(mnuUndo);
			contextMenu.add(mnuRedo);
			contextMenu.show(e.getComponent(), e.getX(), e.getY());
			
			
		}
		
	}
	@Override
	public void actionPerformed(ActionEvent e) {
		log.info("ACTION : "+ e.getActionCommand());
		if(e.getActionCommand().equals(mnuCopy.getActionCommand())){
			String toCopy = getSelectedText();
			setClipboardContents(toCopy);
			
		}else if(e.getActionCommand().equals(mnuPaste.getActionCommand())){
			insert(getClipboardContents(),getCaretPosition());				
			
		}else if(e.getActionCommand().equals(mnuCut.getActionCommand())){
			setClipboardContents(getSelectedText());
			replaceSelection("");
		}else if(e.getActionCommand().equals(mnuUndo.getActionCommand())){
			BUndo();
		}else if(e.getActionCommand().equals(mnuRedo.getActionCommand())){
			BRedo();
		}		
	}
	
	
	public void setClipboardContents(String aString){
	    StringSelection stringSelection = new StringSelection(aString);
	    Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
	    clipboard.setContents(stringSelection, this);
	}
	
	 public String getClipboardContents() {
	    String result = "";
	    Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
	    //odd: the Object param of getContents is not currently used
	    Transferable contents = clipboard.getContents(null);
	    boolean hasTransferableText =  (contents != null) &&  contents.isDataFlavorSupported(DataFlavor.stringFlavor) ;
	    if (hasTransferableText) {
	      try {
	        result = (String)contents.getTransferData(DataFlavor.stringFlavor);
	      }
	      catch (UnsupportedFlavorException | IOException ex){
	    	  log.info(" : "+ ex);
	        ex.printStackTrace();
	      }
	    }
	    return result;
	  }


	
	@Override
	public void keyReleased(KeyEvent e) {}
	@Override
	public void keyTyped(KeyEvent e) {}
	@Override
	public void mouseEntered(MouseEvent e) {}
	@Override
	public void mouseExited(MouseEvent e) {}
	@Override
	public void mousePressed(MouseEvent e) {}
	@Override
	public void mouseReleased(MouseEvent e) {}
	@Override
	public void lostOwnership(Clipboard clipboard, Transferable contents) {}
}
