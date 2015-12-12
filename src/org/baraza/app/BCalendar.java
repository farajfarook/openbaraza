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

import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.Date;
import java.text.ParseException;
import java.text.SimpleDateFormat;

import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JTable;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.table.DefaultTableCellRenderer;

import java.awt.BorderLayout;
import java.awt.GridLayout;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

public class BCalendar extends JPanel implements ActionListener {
	JButton prevYear, prevMonth, theMonth, nextMonth;
	JSplitPane sp;
	JTable table;
	JScrollPane scrollPane;
	JPanel topPanel, prevPanel;

	String filterName;
	
	GregorianCalendar calendar;
	String[] monthNames = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
	String[] columnNames = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
	String[][] data;

	public BCalendar(BElement fieldDef) {
		super(new BorderLayout());

		calendar = new GregorianCalendar();

		if(calendar.getFirstDayOfWeek() == Calendar.MONDAY) {
			String[] calendardays = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
			columnNames = calendardays;
		} else {
			String[] calendardays = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
			columnNames = calendardays;
		}

		data = new String[6][7];
		for(int j=0;j<6;j++) for(int i=0;i<7;i++) data[j][i] = "";
		
		filterName = fieldDef.getAttribute("filtername", "filterid");

		prevYear = new JButton("<<");
		prevMonth = new JButton("<");
		theMonth = new JButton(">>");
		nextMonth = new JButton(">");

		table = new JTable(data, columnNames);
		table.setCellSelectionEnabled(true);
		table.setRowHeight(21);
		table.setShowGrid(false);
		scrollPane = new JScrollPane(table);

		// Center Align the calendar
		DefaultTableCellRenderer renderer =  new DefaultTableCellRenderer();
		renderer.setVerticalAlignment(DefaultTableCellRenderer.CENTER);
		renderer.setHorizontalAlignment(DefaultTableCellRenderer.CENTER);
		table.setDefaultRenderer(Object.class, renderer);

		prevPanel = new JPanel(new GridLayout(0,2));
		prevPanel.add(prevYear);
		prevPanel.add(prevMonth);
		
		topPanel = new JPanel(new BorderLayout());
		topPanel.add(prevPanel, BorderLayout.LINE_START);
        topPanel.add(theMonth, BorderLayout.CENTER);
        topPanel.add(nextMonth, BorderLayout.LINE_END);

		// Set the background to opaque
		prevYear.setOpaque(true);
		prevMonth.setOpaque(true);
        theMonth.setOpaque(true);
        nextMonth.setOpaque(true);
		topPanel.setOpaque(true);

		prevYear.addActionListener(this);
		prevMonth.addActionListener(this);
		nextMonth.addActionListener(this);
		theMonth.addActionListener(this);

		super.add(topPanel, BorderLayout.PAGE_START);
		super.add(scrollPane, BorderLayout.CENTER);
		
		showCalendar();
	}

	public void setBounds(int x, int y, int w, int h) {
		super.setBounds(x, y, w, h);
	}

	public void showCalendar(String strdate) {
		if(strdate==null) showCalendar();
		if(strdate.length()>0) {
			try {
				Date mydate = new Date();
				SimpleDateFormat dateparse = new SimpleDateFormat("yyyy-MM-dd");
				mydate = dateparse.parse(strdate);
				calendar.setTime(mydate);
				
				showCalendar();
			} catch(ParseException ex) {
				System.out.println("String to date conversion problem : " + ex);
			}
		}
	}
	
	public void showCalendar() {
		calendar.set(Calendar.DAY_OF_MONTH, 1);
		
		theMonth.setText(calendar.get(Calendar.YEAR) + " " + monthNames[calendar.get(Calendar.MONTH)]);
		int maxdays = calendar.getActualMaximum(Calendar.DAY_OF_MONTH);
		for(int j=0;j<6;j++) for(int i=0;i<7;i++)
			table.setValueAt("", j, i);

		int addvalue = 0;
		for(int i = 1; i<=maxdays; i++) {
			int row = calendar.get(Calendar.WEEK_OF_MONTH) - 1;			
			int col = calendar.get(Calendar.DAY_OF_WEEK) - 1;
			if(calendar.getFirstDayOfWeek() == Calendar.MONDAY) col -= 1;
			if(row<0) addvalue = 1;
			row += addvalue; 
			if(col<0) col = 6;
			String myday = Integer.toString(i);

			//System.out.println(myday + ", " + row + ", " + col);
			table.setValueAt(myday, row, col);
			calendar.add(Calendar.DATE, 1);
		}
		calendar.add(Calendar.DATE, -1);	// reverse to be in present month
	}

	public String getFilterName() {
		return filterName;
	}

	public String getKey() {
		int row = table.getSelectedRow();
		int col = table.getSelectedColumn();
		String mydate = "";
		String value = "";
		if((row>=0) && (col>=0)) value = (String)table.getValueAt(row, col);
		
		SimpleDateFormat dateformatter = new SimpleDateFormat("yyyy-MM-dd");
		if(!value.equals("")) {
			int day = Integer.valueOf(value).intValue();
			calendar.set(Calendar.DAY_OF_MONTH, day);
	        mydate = dateformatter.format(calendar.getTime());
		} else {
			GregorianCalendar tmpcalendar = new GregorianCalendar();
        	mydate = dateformatter.format(tmpcalendar.getTime());
		}
	
	   	return mydate;
  	}

	public void setListener(BFilter flt) {
		table.addMouseListener(flt);
	}
	
    public void actionPerformed(ActionEvent e) {
		if(e.getActionCommand().equals("<<")) calendar.add(Calendar.YEAR, -1);
		else if(e.getActionCommand().equals("<")) calendar.add(Calendar.MONTH, -1);
		else if(e.getActionCommand().equals(">")) calendar.add(Calendar.MONTH, 1);
		else calendar.add(Calendar.YEAR, 1);

		showCalendar();
    }
}
