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
import java.util.Date;
import java.util.Locale;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.text.NumberFormat;

import javax.swing.JLabel;
import javax.swing.JTextField;
import javax.swing.JTextArea;
import javax.swing.JScrollPane;
import javax.swing.JCheckBox;
import javax.swing.JSpinner;
import javax.swing.JSpinner.DateEditor;
import javax.swing.SpinnerModel;
import javax.swing.SpinnerDateModel;
import javax.swing.JPanel;
import javax.swing.JFormattedTextField;

import java.awt.event.ActionListener;
import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;

import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.utils.BAmountInWords;
import org.baraza.utils.BLogHandle;

class BField implements MouseListener {
	Logger log = Logger.getLogger(BField.class.getName());
	BLogHandle logHandle;
	JLabel label;
	JScrollPane scrollPane;
	JTextField textField;
	JTextArea textArea;
	JCheckBox checkBox;
	JSpinner spinner;
	JFormattedTextField textDecimal;
	BComboList comboList;
	BComboBox comboBox;
	BCalendar calendar;
	BGridBox gridBox;
	BPicture picture;
	String defaultField;
	String errMsg = "";
	BEditor editor;
	BDB db;

	int type;
	int x, y, h, w, lw, lh, ph;
	String name, title, defaultValue, format, function, filter;
	boolean ischar = false;
	boolean showcal = false;

	public BField(BLogHandle logHandle, BDB db, BElement view) {
		this.db = db;
		this.logHandle = logHandle;
		logHandle.config(log);

		name = view.getValue();
		title = view.getAttribute("title", "");
		defaultValue = view.getAttribute("default", "");
		filter = view.getAttribute("filter");
		format = view.getAttribute("format");
		function = view.getAttribute("function");

		String default_fnct = view.getAttribute("default_fnct");
		if(default_fnct != null) defaultValue = db.executeFunction("SELECT " + default_fnct + "('" + db.getUserID() + "')");

		x = Integer.valueOf(view.getAttribute("x", "10"));
		y = Integer.valueOf(view.getAttribute("y", "10"));
		h = Integer.valueOf(view.getAttribute("h", "20")) + 4;
		w = Integer.valueOf(view.getAttribute("w", "150"));
		lw = Integer.valueOf(view.getAttribute("lw", "120"));
		lh = Integer.valueOf(view.getAttribute("lh", "20"));
		ph = Integer.valueOf(view.getAttribute("ph", "120"));

		if(view.getAttribute("ischar") != null) ischar = true;

		boolean disabled = false;
		if(view.getAttribute("disabled", "false").equals("true")) disabled = true;
		if(view.getAttribute("enabled", "true").equals("false")) disabled = true;

		label = new JLabel(title);

		if(view.getName().equals("TEXTFIELD")) type = 0;
		else if(view.getName().equals("TEXTAREA")) type = 1;
		else if(view.getName().equals("CHECKBOX")) type = 2;
		else if(view.getName().equals("TEXTTIME")) type = 3;
		else if(view.getName().equals("TEXTDATE")) type = 4;
		else if(view.getName().equals("TEXTTIMESTAMP")) type = 5;
		else if(view.getName().equals("SPINTIME")) type = 6;
		else if(view.getName().equals("SPINDATE")) type = 7;
		else if(view.getName().equals("SPINTIMESTAMP")) type = 8;
		else if(view.getName().equals("TEXTDECIMAL")) type = 9;
		else if(view.getName().equals("COMBOLIST")) type = 10;
		else if(view.getName().equals("COMBOBOX")) type = 11;
		else if(view.getName().equals("GRIDBOX")) type = 12;
		else if(view.getName().equals("DEFAULT")) type = 13;
		else if(view.getName().equals("EDITOR")) type = 14;
		else if(view.getName().equals("FUNCTION")) type = 15;
		else if(view.getName().equals("USERFIELD")) type = 16;
		else if(view.getName().equals("USERNAME")) type = 17;
		else if(view.getName().equals("PICTURE")) type = 18;

		SpinnerModel datemodel = new SpinnerDateModel();

		switch (type) {
			case 0:	// TextField
				textField = new JTextField();
				if(disabled) textField.setEnabled(false);
				break;
			case 1: // TextArea
				textArea = new JTextArea();
				if(disabled) textArea.setEnabled(false);
				textArea.setLineWrap(true);
				textArea.setWrapStyleWord(true);
				scrollPane = new JScrollPane(textArea);
				break;
			case 2: // CheckBox
				checkBox = new JCheckBox();
				if(disabled) checkBox.setEnabled(false);
				break;
			case 3:	// TextTime
				textField = new JTextField();
				if(disabled) textField.setEnabled(false);
				break;
			case 4:	// TextDate
			case 5:	// TextTimeStamp
				textField = new JTextField();
				calendar = new BCalendar(view);
				if(disabled) textField.setEnabled(false);
				else textField.addMouseListener(this);
				calendar.table.addMouseListener(this);
				break;
			case 6: // Spin Time
				spinner = new JSpinner(datemodel);
				spinner.setEditor(new JSpinner.DateEditor(spinner, "hh:mm a"));
				if(disabled) spinner.setEnabled(false);
				break;
			case 7: // Spin Date
				spinner = new JSpinner(datemodel);
				spinner.setEditor(new JSpinner.DateEditor(spinner, "dd-MMM-yyyy"));
				if(disabled) spinner.setEnabled(false);
				break;
			case 8: // Spin TimeStamp
				spinner = new JSpinner(datemodel);
				spinner.setEditor(new JSpinner.DateEditor(spinner, "dd-MMM-yyyy hh:mm a"));
				if(disabled) spinner.setEnabled(false);
				break;
			case 9: // Text Decimal
				NumberFormat numberformat = NumberFormat.getNumberInstance();
				textDecimal = new JFormattedTextField(numberformat);
				if(disabled) textDecimal.setEnabled(false);
				if(defaultValue.equals("")) defaultValue = "0";
				break;
			case 10: // Combo List
				comboList = new BComboList(view);
				break;
			case 11: // Combo Box
				comboBox = new BComboBox(db, view);
				break;
			case 12: // Grid Box
				gridBox = new BGridBox(logHandle, db, view);
				break;
			case 14: // Editor
				editor = new BEditor(view);
				break;
			case 18: // Picture
				picture = new BPicture(db, view);
				break;
		}

		setBounds();
	}

	public String getName() {
		return name;
	}

	public int getX() { return x; }
	public int getY() { return y; }
	public int getH() { return h; }
	public int getW() { return w; }

	public void addToPanel(JPanel panel) {
		if(title.length() > 0) panel.add(label);

		switch (type) {
			case 0:	
			case 3:
				panel.add(textField); 
				break;
			case 1: 
				panel.add(scrollPane); 
				break;
			case 2: 
				panel.add(checkBox); 
				break;
			case 4:
			case 5:
				panel.add(textField); 
				panel.add(calendar);
				calendar.setVisible(false);
				break;
			case 6:
			case 7:
			case 8:
				panel.add(spinner); 
				break;
			case 9:
				panel.add(textDecimal); 
				break;
			case 10:
				panel.add(comboList); 
				break;
			case 11:
				panel.add(comboBox); 
				break;
			case 12: // Grid Box
				panel.add(gridBox);
				panel.add(gridBox.getGrid());
				break;
			case 14: // Editor
				panel.add(editor);
				break;
			case 18: // Picture
				panel.add(picture);
				break;
		}
	}

  	public void setBounds() {
		if(title.length() > 0) label.setBounds(x, y, lw, lh);
		else lw = 0;

		switch (type) {
			case 0:	
			case 3:	textField.setBounds(x+lw, y, w, h); break;
			case 1: scrollPane.setBounds(x+lw, y, w, h); break;
			case 2: checkBox.setBounds(x+lw, y, w, h); break;
			case 4:
			case 5:
				textField.setBounds(x+lw, y, w, h);
				calendar.setBounds(x, y+h, w+lw, h+ph);  
				break;
			case 6:
			case 7:
			case 8:
				spinner.setBounds(x+lw, y, w, h);
				break;
			case 9:
				textDecimal.setBounds(x+lw, y, w, h);
				break;
			case 10:
				comboList.setBounds(x+lw, y, w, h);
				break;
			case 11:
				comboBox.setBounds(x+lw, y, w, h);
				break;
			case 12: // Grid Box
				gridBox.setBounds(x, y, w, h, lw, ph);
				break;
			case 14: // Editor
				editor.setBounds(x+lw, y, w, h);
				break;
			case 18: // Picture
				picture.setBounds(x+lw, y, w, h);
				break;
		}
 	}

	public void setNew() {
		switch (type) {
			case 10: // Combo List
				comboList.setText(defaultValue);
				setText(defaultValue);
				break;
			case 11: // Combo Box
				comboBox.getList();
				setText(defaultValue);
				break;
			case 12: // Grid Box
				gridBox.refresh();
				setText(defaultValue);
				break;
			default:
				setText(defaultValue);
				break;
		}
	}

	public void refresh() {
		switch (type) {
			case 11: // Combo Box
				comboBox.getList();
				break;
			case 12: // Grid Box
				gridBox.refresh();
				break;
		}
	}

	public void setText(String value) {
		switch (type) {
			case 0:	// Text Field
				textField.setText(value);
				textField.moveCaretPosition(0);
				break;
			case 1: // Text Area
				textArea.setText(value);
				textArea.moveCaretPosition(0);
				break;
			case 2:	// Check Box
				if(ischar) {
					if(value == null) checkBox.setSelected(false);
					else if(value.equals("1")) checkBox.setSelected(true);
					else checkBox.setSelected(false);
				} else {
					if(value == null) checkBox.setSelected(false);
					else if(value.equals("t")) checkBox.setSelected(true);
					else if(value.equals("true")) checkBox.setSelected(true);
					else checkBox.setSelected(false);
				}
				break;
			case 3:	// Text Time
			case 4:	// Text Date
			case 5:	// Text TimeStamp
				textField.setText(decodeDate(value));
				textField.moveCaretPosition(0);
				break;
			case 6: // Time Spin
			case 7: // Date Spin
			case 8: // Time Stamp Spin
				if(value != null) setSpinDateTime(value);
				break;
			case 9: // Text Decimal
				setDecimal(value);
				break;
			case 10: // Combo List
				comboList.setText(value);
				break;
			case 11: // Combo Box
				comboBox.setText(value);
				break;
			case 12: // Grid Box
				gridBox.setText(value);
				break;
			case 13: // Default Value
				defaultField = value;
				break;
			case 14: // Editor
				editor.setText(value);
				break;
			case 18: // Picture
				picture.setPicture(value);
				break;
		}
	}

	public String getText() {
		errMsg = "";
		switch (type) {
			case 0: return textField.getText();
			case 1: return textArea.getText();
			case 2: 
				String ldata = "false";
				if(ischar) ldata = "0";
				if(checkBox.isSelected()) {
					ldata = "true";
					if(ischar) ldata = "1";
				}
				return ldata;
			case 3:
			case 4:
			case 5: return encodeDate(textField.getText());
			case 6:
			case 7:
			case 8: return getSpinDateTime();
			case 9: return getDecimal();
			case 10: return comboList.getText();
			case 11: return comboBox.getText();
			case 12: return gridBox.getText();
			case 13: return defaultValue;
			case 14: return editor.getText();
			case 15: return db.executeFunction(function);
			case 16: return db.getUserID();
			case 17: return db.getUserName();
			case 18: return picture.getPicture();
		}
		return null;
	}

	public void setLinkData(String lkdata) {
		switch (type) {
			case 11: comboBox.setLinkData(lkdata); break;
			case 12: gridBox.setLinkData(lkdata); break;
		}
	}

	public String decodeDate(String ldata) {
		if(ldata == null) return "";

		if(ldata.length()>0) {
			try {
				Date mydate = new Date();
				Locale locale = Locale.getDefault();

				SimpleDateFormat dateParse = new SimpleDateFormat();
				if(type == 3) {
					dateParse.applyPattern("HH:mm:ss");
					if(ldata.equals("now")) mydate = new Date();
					else mydate = dateParse.parse(ldata);
					dateParse.applyPattern("hh:mm a");
				} else if(type == 4) {
					dateParse.applyPattern("yyyy-MM-dd");
					if(ldata.equals("today")) mydate = new Date();
					else if(ldata.equals("now")) mydate = new Date();
					else mydate = dateParse.parse(ldata);
					dateParse.applyPattern("MMM dd, yyyy");
				} else if(type == 5) {
					dateParse.applyPattern("yyyy-MM-dd HH:mm:ss");
					if(ldata.equals("today")) mydate = new Date();
					else if(ldata.equals("now")) mydate = new Date();
					else mydate = dateParse.parse(ldata);
					dateParse.applyPattern("MMM dd, yyyy hh:mm a");
				}

				ldata = dateParse.format(mydate);
			} catch(ParseException ex) {
				ldata = "";
				errMsg = ex.getMessage() + "\n";
				log.severe("Date to String format conversion problem : " + ex);
			}
		}

		return ldata;
	}

	public String encodeDate(String ldata) {
		if(ldata == null) return "";

		if(ldata.length()>0) {
    		try {
                Date psdate = new Date();
				SimpleDateFormat dateParse = new SimpleDateFormat();
				if(type == 3) {
					dateParse.applyPattern("hh:mm a");
					psdate = dateParse.parse(ldata);
					dateParse.applyPattern("HH:mm:ss");
				} else if(type == 4) {
					if(ldata.indexOf('/')>0) dateParse.applyPattern("dd/MM/yyyy");
					else if(ldata.indexOf('-')>0) dateParse.applyPattern("dd-MM-yyyy");
					else if(ldata.indexOf('.')>0) dateParse.applyPattern("dd.MM.yyyy");
					else if(ldata.indexOf(' ')>0) dateParse.applyPattern("MMM dd, yyyy");

					psdate = dateParse.parse(ldata);
					dateParse.applyPattern("yyyy-MM-dd");
				} else if(type == 5) {
					if(ldata.indexOf('/')>0) dateParse.applyPattern("dd/MM/yyyy hh:mm a");
					else if(ldata.indexOf('-')>0) dateParse.applyPattern("dd-MM-yyyy hh:mm a");
					else if(ldata.indexOf('.')>0) dateParse.applyPattern("dd.MM.yyyy hh:mm a");
					else if(ldata.indexOf(' ')>0) dateParse.applyPattern("MMM dd, yyyy hh:mm a");

					psdate = dateParse.parse(ldata);
					dateParse.applyPattern("yyyy-MM-dd HH:mm:ss");
				}
        		ldata = dateParse.format(psdate);
            } catch(ParseException ex) {
				ldata = "";
				errMsg = ex.getMessage() + "\n";
                log.severe("String to date conversion problem : " + ex);
            }
		}
      
		return ldata;
	}

	public void setSpinDateTime(String ldata) {
		if(ldata.length()>0) {
			try {
				Date mydate = new Date();

				SimpleDateFormat dateFormatter = new SimpleDateFormat();
				if(type == 6) dateFormatter.applyPattern("HH:mm:ss");
				else if(type == 7) dateFormatter.applyPattern("yyyy-MM-dd");
				else if(type == 8) dateFormatter.applyPattern("yyyy-MM-dd HH:mm:ss");

				mydate = dateFormatter.parse(ldata);
				SpinnerModel datemodel = spinner.getModel();
				spinner.setValue(mydate);
			} catch(ParseException ex) {
				log.severe("String to date conversion problem : " + ex);
			}
		}
	}

	public String getSpinDateTime() {
		SpinnerModel datemodel = spinner.getModel();

		SimpleDateFormat dateFormatter = new SimpleDateFormat();
		if(type == 6) dateFormatter.applyPattern("HH:mm:ss");
		else if(type == 7) dateFormatter.applyPattern("yyyy-MM-dd");
		else if(type == 8) dateFormatter.applyPattern("yyyy-MM-dd HH:mm:ss");

        String mydate = dateFormatter.format(((SpinnerDateModel)datemodel).getDate());
      
		return mydate;
	}

	public void setDecimal(String ldata) {
		if(ldata == null) ldata = "0";

		if(ldata.length() > 0) {
			Double myvalue = Double.valueOf(ldata).doubleValue();
			textDecimal.setValue(myvalue);
		}
	}

	public String getDecimal() {
		String myvalue = "";

		if(textDecimal.getText().length()>0) {
 			Double d = ((Number)textDecimal.getValue()).doubleValue();
			myvalue = d.toString();
		}
      
		return myvalue;
	}

	public String getFilter() {
		return filter;
	}

	public String getInWords() {
		String myvs = getText();
		if(myvs.length()>0) {
			Double d = Double.valueOf(myvs);
			BAmountInWords aiw = new BAmountInWords(d.intValue());
			myvs = aiw.getAmountInWords();
		}

		return myvs;
	}

	public String getErrMsg() { return errMsg; }
	
	public boolean hadListener() {
		switch (type) {
			case 11: return comboBox.hadListener();
			default: return false;
		}
	}
	
	public String getComboLink() {
		switch (type) {
			case 11: return comboBox.getComboLink();
			default: return null;
		}
	}
	
	public void addActionListener(BForm form) {
		if(hadListener()) comboBox.addActionListener(form);
	}

	// Get the grid listening mode
	public void mousePressed(MouseEvent e) {}
	public void mouseReleased(MouseEvent e) {}
	public void mouseEntered(MouseEvent e) {}
	public void mouseExited(MouseEvent e) {}
	public void mouseClicked(MouseEvent e) {
		if(showcal) {
			if(type == 4) setText(calendar.getKey());
			else if (type == 5) setText(calendar.getKey() + " 12:00:00");

			calendar.setVisible(false);
			showcal = false;
		} else if(e.getClickCount()==2) {
			calendar.showCalendar(getText());
			calendar.setVisible(true);
			showcal = true;
		}
	}
}
