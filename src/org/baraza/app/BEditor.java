/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.app;

import org.baraza.xml.BElement;

import java.util.logging.Logger;

import javax.swing.JEditorPane;
import javax.swing.JScrollPane;
import javax.swing.JPanel;
import javax.swing.JFileChooser;
import javax.swing.JInternalFrame;
import javax.swing.JButton;

import javax.swing.text.StyledEditorKit;
import javax.swing.Action;

import java.awt.BorderLayout;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

import java.net.URL;
import java.net.MalformedURLException;

public class BEditor extends JPanel implements ActionListener { 
	Logger log = Logger.getLogger(BEditor.class.getName());
	JPanel buttonPanel;
	JEditorPane editorPane;
	JScrollPane scrollPane;
	String imageserver;
	JButton[] b;
	String mydata;

	public BEditor(BElement el) {
		editorPane = new JEditorPane();
		editorPane.setContentType("text/html");

		super.setLayout(new BorderLayout());
		buttonPanel = new JPanel();
		scrollPane = new JScrollPane(editorPane);
		super.add(scrollPane, BorderLayout.CENTER);
		super.add(buttonPanel, BorderLayout.PAGE_END);

		b = new JButton[4];
		Action action = null;
		action = new StyledEditorKit.UnderlineAction();
		action.putValue(Action.NAME, "<html><u>u</u></html>");
		b[0] = new JButton(action);
		action = new StyledEditorKit.BoldAction();
    	action.putValue(Action.NAME, "<html><b>b</b></html>");
	    b[1] = new JButton(action);
        action = new StyledEditorKit.ItalicAction();
        action.putValue(Action.NAME, "<html><i>i</i></html>");
        b[2] = new JButton(action);
		for(int j = 0; j<3; j++) {
			buttonPanel.add(b[j]);
		}
	}

	public void setText(String ldata) {
		mydata = ldata;
		editorPane.setText(ldata);
	}

	public String getText() {
		mydata = editorPane.getText();
		return mydata;
	}

    public void actionPerformed(ActionEvent e) {
		String ac = e.getActionCommand();
    }
}
