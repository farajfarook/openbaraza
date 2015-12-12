package org.baraza.swing;



import java.awt.Color;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.swing.AbstractAction;
import javax.swing.JButton;
import javax.swing.JComponent;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.KeyStroke;
import javax.swing.text.BadLocationException;
import javax.swing.text.DefaultHighlighter;
import javax.swing.text.Document;
import javax.swing.text.Highlighter;
import javax.swing.text.JTextComponent;

public class BFindReplaceDialog extends JDialog{
	JPanel panel = new JPanel();
	JTextField txtFind,txtReplace;;
	JButton btnFind,btnReplace,btnReplaceAll,btnClose;
	JTextComponent pTextComponent;
	JLabel lblResults;
	String findtext, replacetext;
	String fileStr;
	Highlighter.HighlightPainter myHighlightPainter ;
	int lastSearch = 0;
	int pos;
	int matches = 0;
	Document doc;
	Highlighter highlighter;
	
	
	public BFindReplaceDialog(final JTextComponent ptextComponent) {
		
		this.pTextComponent = ptextComponent;	
		
		myHighlightPainter = new MyHighlightPainter(Color.CYAN);
		getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(
		        KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE , 0), "close");
	    getRootPane().getActionMap().put("close", new AbstractAction() {
	        public void actionPerformed(ActionEvent e) {
	        	closeDialog();
	        }
	    });
		
		
		
		
		JPanel panel = new JPanel();
		txtFind = new JTextField(20);
		txtReplace = new JTextField(20);
		btnFind = new JButton("Find");
		btnReplace = new JButton("Replace");
		btnReplaceAll = new JButton("Replace All");
		btnClose = new JButton("Exit");
		lblResults = new JLabel();
		btnFind.addActionListener(new ActionListener() {
			
			@Override
			public void actionPerformed(ActionEvent e) {
				findtext = txtFind.getText().toString();
				if(findtext.equals("") || findtext == null){
					lblResults.setText("Enter Text To Find.");
					txtFind.requestFocus();
				}else{
					try {
						doc = pTextComponent.getDocument();
						highlighter = pTextComponent.getHighlighter();
						fileStr = doc.getText(0, doc.getLength());
						
						Pattern p = Pattern.compile(findtext.toUpperCase());
					    Matcher m = p.matcher(fileStr.toUpperCase());
					    int count = 0;
					    while (m.find()){
					    	count +=1;
					    }
						lblResults.setText(count+ " Matches Found.");
					
						pos = fileStr.toUpperCase().indexOf(findtext.toUpperCase(), lastSearch);
						
						
						if(pos>=0) {
							lastSearch = pos + findtext.length();
							try {
								highlighter.removeAllHighlights();
								DefaultHighlighter.DefaultHighlightPainter highlightPainter = new DefaultHighlighter.DefaultHighlightPainter(Color.YELLOW);
								highlighter.addHighlight(pos, pos + findtext.length(), highlightPainter);
								
								pTextComponent.setCaretPosition(pos);
								pTextComponent.requestFocus();
							} catch(BadLocationException ex) {
								System.out.println("Highlighter error : " + ex);
							}
						} else {
							lastSearch = 0;
							lblResults.setText("No Match Found");
						}			
						
					} catch (BadLocationException e1) {
						e1.printStackTrace();
					}
					
				}
			}
		});
		btnReplace.addActionListener(new ActionListener() {
			
			@Override
			public void actionPerformed(ActionEvent e) {
				replacetext = txtReplace.getText().toString();
				if(findtext.equals("") || findtext == null){
					lblResults.setText("Enter Text To Find.");
					txtFind.requestFocus();
				}else if(replacetext.equals("") || replacetext == null){
					lblResults.setText("Enter Text To Replace With.");
					txtFind.requestFocus();
				}else{
					if(pos == -1){
						lblResults.setText("No Match Found");
					}else{
						pTextComponent.select(pos, pos+findtext.length());
						pTextComponent.replaceSelection(replacetext);//replaceRange(findtext,pos,pos+findtext.length());
						lblResults.setText("Replace Successfull.");
					}
				}
				
				
			}
		});
		
		btnReplaceAll.addActionListener(new ActionListener() {
			
			@Override
			public void actionPerformed(ActionEvent e) {
				Document doc = pTextComponent.getDocument();
				highlighter = pTextComponent.getHighlighter();
				findtext = txtFind.getText().toString();
				replacetext = txtReplace.getText().toString();
				if(!findtext.equals("") && !replacetext.equals("")){
					try {
						fileStr = doc.getText(0, doc.getLength());
						if(pos == -1){
							lblResults.setText("No Match Found");
						}else{
							int countReplaced = 0;
							while(pos >= 0){
								pTextComponent.select(pos, pos+findtext.length());
								pTextComponent.replaceSelection(replacetext);
								countReplaced +=1;
							}
							lblResults.setText(countReplaced + "Replaced");
						}
						
						
					} catch (BadLocationException e1) {
						
						e1.printStackTrace();
					}
					
				}else{
					lblResults.setText("Both Fields Required");
				}
				
				
				
			}
		});
		
		btnClose.addActionListener(new ActionListener() {
			
			@Override
			public void actionPerformed(ActionEvent e) {
				closeDialog();
			}
		});
		
		
	    panel.add(new JLabel("Find"));
	    panel.add(txtFind);
	    panel.add(new JLabel("Replace"));
	    panel.add(txtReplace);
	    panel.add(btnFind);
	    panel.add(btnReplace);
	    panel.add(btnReplaceAll);
	    panel.add(btnClose);
	    panel.add(lblResults);
	    
		add(panel);
		pack();
		setAlwaysOnTop(true);
		setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
		setTitle("Find Replace");
		
		setLocation(20, 50);
		setSize(250, 230);
		
		
	}
	
	class MyHighlightPainter extends DefaultHighlighter.DefaultHighlightPainter{
		public MyHighlightPainter(Color color) {
			super(color);
		}		
	} 
	
	public void closeDialog(){
		removeHighlight(this.pTextComponent);
    	BFindReplaceDialog.this.dispose();
	}
	
	public void removeHighlight(JTextComponent textComponent){
		try {
			Highlighter hilite = textComponent.getHighlighter();
			Highlighter.Highlight[] hilites = hilite.getHighlights();
			for(int i = 0; i < hilites.length; i++){
				if(hilites[i].getPainter() instanceof MyHighlightPainter){
					hilite.removeHighlight(hilites[i]);
				}
			}	
			
		} catch (Exception e) {
			e.printStackTrace();
		}
		
	}

}
