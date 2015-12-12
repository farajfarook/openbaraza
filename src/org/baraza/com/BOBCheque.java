/**
 * @author      Dennis W. Gichangi <dennis.dichangi@dewcis.com>
 * @version     2011.03.29
 * @since       1.6
 * website		www.dewcis.com
 * The contents of this file are subject to the Dew CIS Solutions License
 * The file should only be shared to OpenBravo.
 */
package org.baraza.com;

import java.util.Date;
import java.util.List;
import java.util.ArrayList;
import java.util.Vector;
import java.text.SimpleDateFormat;
import java.text.DecimalFormat;

import java.awt.FontMetrics;
import java.awt.Font;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.Graphics;
import java.awt.BorderLayout;
import java.awt.print.Printable;
import java.awt.print.PageFormat;
import java.awt.print.PrinterJob;
import java.awt.print.PrinterException;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.event.WindowListener;

import javax.swing.UIManager;
import javax.swing.JApplet;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JTabbedPane;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JButton;
import javax.swing.JPasswordField;
import javax.swing.JTable;
import javax.swing.JLabel;
import javax.swing.JFileChooser;
import javax.swing.ListSelectionModel;
import javax.swing.event.ListSelectionListener;
import javax.swing.event.ListSelectionEvent;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.DB.BTableModel;
import org.baraza.reports.BReport;
import org.baraza.utils.BAmountInWords;

public class BOBCheque extends JApplet implements Printable, ActionListener, ListSelectionListener, WindowListener {
	List<String> prnline;
	List<Integer> prnx;
	List<Integer> prny;

	BDB db;
	BReport rpt;

	BOBCheque a_prn;
	BOBChequeTable tbdef;
	BTableModel eftTModel;

	JFrame frame;
	JPanel panel;
	JButton bt, expBT, clearBT;
	JPasswordField pF;
	JTable table, eftTable;
	JLabel label;
	JScrollPane asp;
	JSplitPane splitPane;

	public static void main(String args[]) {
		BOBCheque prn = new BOBCheque();
		prn.addFrame();
	}

	public void init() {		// Run an applet
		a_prn = new BOBCheque();
		getContentPane().add(a_prn.splitPane);
	}

	public void destroy() {
		a_prn.close();
	}

	public void addFrame() {
		a_prn = new BOBCheque();

		frame = new JFrame("Cheque Printing");
		frame.addWindowListener(this);
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frame.getContentPane().add(a_prn.splitPane);
		frame.setLocation(50, 50);
		frame.setSize(1100, 500);
		frame.setVisible(true);
	}

	public BOBCheque() {
		try {
			UIManager.setLookAndFeel("com.sun.java.swing.plaf.nimbus.NimbusLookAndFeel");
		} catch (Exception ex) {
			System.out.println("Error Loading the look : " + ex);
		}

		boolean orcl = true;
		String dbclass = "org.postgresql.Driver";
		String dbpath = "jdbc:postgresql://192.168.0.2/finance";
		if(orcl) {
			dbclass = "oracle.jdbc.driver.OracleDriver";
			dbpath = "jdbc:oracle:thin:@172.100.3.22:1524:erp";
			db = new BDB(dbclass, dbpath, "erpdbuser", "Imis2goke");
		} else {
			db = new BDB(dbclass, dbpath, "tegemeo", "tegeme0");
		}

		tbdef = new BOBChequeTable();
		makeCheque();
		makeEFT();

		prnline = new ArrayList<String>();
		prnx = new ArrayList<Integer>();
		prny = new ArrayList<Integer>();

		bt = new JButton("Print Cheques");
		bt.addActionListener(this);
		expBT = new JButton("Export EFT");
		expBT.addActionListener(this);
		clearBT = new JButton("Clear EFT");
		clearBT.addActionListener(this);

		pF = new JPasswordField(10);
		label = new JLabel("Enter Security Code :");

		table =  new JTable(tbdef);
		table.setFillsViewportHeight(true);
		table.setAutoCreateRowSorter(true);
		table.getSelectionModel().addListSelectionListener(this);
		asp = new JScrollPane(table);
		asp.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);

		eftTable =  new JTable(eftTModel);
		eftTable.setFillsViewportHeight(true);
		eftTable.setAutoCreateRowSorter(true);
		eftTable.getSelectionModel().addListSelectionListener(this);
		JScrollPane eftSP = new JScrollPane(eftTable);
		eftSP.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);

		//rpt = new BReport(db, "http://172.100.3.34:8080/cheques/reports/", "EM_bankpaymentadvise.jasper");
		rpt = new BReport(db, "/root/baraza/projects/ob/reports/", "EM_bankpaymentadvise.jasper");

		JPanel btPanel = new JPanel();
		btPanel.add(label);
		btPanel.add(pF);
		btPanel.add(bt);

		JPanel ebtPanel = new JPanel();
		ebtPanel.add(expBT);
		ebtPanel.add(clearBT);

		panel = new JPanel(new BorderLayout());
		panel.add(asp, BorderLayout.CENTER);
		panel.add(btPanel, BorderLayout.PAGE_END);

		JPanel ePanel = new JPanel(new BorderLayout());
		ePanel.add(eftSP, BorderLayout.CENTER);
		ePanel.add(ebtPanel, BorderLayout.PAGE_END);

		JTabbedPane tabbedPane = new JTabbedPane();
		tabbedPane.addTab("Cheque Printing", panel);
		tabbedPane.addTab("EFT", ePanel);

		splitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, tabbedPane, rpt);
        splitPane.setDividerLocation(800);
        splitPane.setOneTouchExpandable(true);
        splitPane.setContinuousLayout(true);
	}

	public int print(Graphics g, PageFormat pf, int page) {
		if (page > 0) { /* We have only one page, and 'page' is zero-based */
			return NO_SUCH_PAGE;
		}

		Graphics2D g2d = (Graphics2D)g;
		g2d.translate(pf.getImageableX(), pf.getImageableY());

        Font font = new Font("Serif", Font.PLAIN, 10);
        FontMetrics metrics = g.getFontMetrics(font);
        int lineHeight = metrics.getHeight();

		/* Now we perform our rendering */
		for (int i=0; i < prnline.size(); i++) {
			g.drawString(prnline.get(i), prnx.get(i), prny.get(i));
		}
		/* tell the caller that this page is part of the printed document */
		return PAGE_EXISTS;
	}

	public void addLine(String ln, int x, int y) {
		prnline.add(ln);
		prnx.add(x);
		prny.add(y);
	}

	// Public process the pay cheques
	public void makeCheque() {
		String mysql = "SELECT c_bpartner.name, fin_payment.fin_payment_id, fin_payment.paymentdate, fin_payment.amount, fin_payment.referenceno ";
		mysql += "FROM (c_bpartner INNER JOIN fin_payment ON c_bpartner.c_bpartner_id = fin_payment.c_bpartner_id) ";
		mysql += "	INNER JOIN fin_paymentmethod ON fin_payment.fin_paymentmethod_id = fin_paymentmethod.fin_paymentmethod_id ";
		mysql += "WHERE (fin_payment.processed = 'Y')  AND (fin_payment.isreceipt = 'N') AND (fin_paymentmethod.name = 'Cheque') AND (fin_payment.em_dc2_is_printed = 'N')";
		BQuery rs = new BQuery(db, mysql);
		
		tbdef.clear();
		while(rs.moveNext()) {
			Vector<String> cl = new Vector<String>();
			String ref = rs.getString("referenceno");
			if(ref == null) ref = "";
			Date cdate = rs.getDate("paymentdate");
			String cname = rs.getString("name");
			float camount = rs.getFloat("amount");
			int cba = (int) camount;
			int cbc = (int) (100 * (camount % cba));
			BAmountInWords aiw = new BAmountInWords(cba);
			BAmountInWords aiwc = new BAmountInWords(cbc);
			SimpleDateFormat dateformatter = new SimpleDateFormat("dd.MMM.yyyy");
			String mydate = dateformatter.format(cdate);
			DecimalFormat dformatter = new DecimalFormat("###,###,###.00");
			String s = dformatter.format(camount);
			String sfs = aiw.getAmountInWords();
			if(cbc>5) sfs += " " + aiwc.getAmountInWords() + " cents\n";

			cl.add(ref);
			cl.add(mydate);
			cl.add(cname);
			cl.add(s);
			cl.add(sfs);
			cl.add(rs.getString("fin_payment_id"));
			tbdef.cheques.add(cl);

			//System.out.println(mydate + ", " + cname + ", " + ":" + camount + ": " + cba + ", " + cbc);
			//System.out.println(aiw.getAmountInWords() + " and " + aiwc.getAmountInWords() + " cents\n");
		}

		tbdef.refresh();
	}

	// Public process the pay cheques
	public void makeEFT() {
		String mysql = "SELECT c_bpartner.name, fin_payment.paymentdate, fin_payment.amount, fin_payment.referenceno, ";
		mysql += "c_bp_bankaccount.routingno, c_bp_bankaccount.accountno, c_bp_bankaccount.swiftcode, fin_payment.fin_payment_id ";
		mysql += "FROM ((c_bpartner INNER JOIN fin_payment ON c_bpartner.c_bpartner_id = fin_payment.c_bpartner_id) ";
		mysql += "INNER JOIN fin_paymentmethod ON fin_payment.fin_paymentmethod_id = fin_paymentmethod.fin_paymentmethod_id) ";
		mysql += "INNER JOIN c_bp_bankaccount ON c_bpartner.c_bpartner_id = c_bp_bankaccount.c_bpartner_id ";
		mysql += "WHERE (fin_payment.processed = 'Y') AND (fin_payment.isreceipt = 'N') AND (fin_paymentmethod.name = 'EFT') AND (fin_payment.em_dc2_is_printed = 'N') ";

		String[] titles = {"Supplier", "Payment Date", "Amount", "Reference Number", "Bank Code", "Account Number", "Swift Code", "Payment ID"};

		eftTModel = new BTableModel(db, mysql, -1);
		eftTModel.setTitles(titles);
	}

	public void printCheque() {
		PrinterJob printJob = PrinterJob.getPrinterJob();
		printJob.setPrintable(this);

		if (printJob.printDialog()) {
			int[] selection = table.getSelectedRows();
			for (int i = 0; i < selection.length; i++) {
				Vector<String> s = tbdef.cheques.get(table.convertRowIndexToModel(selection[i]));

				prnline.clear();
				prnx.clear();
				prny.clear();

				// Get the cheque number
				String mysql = "SELECT c_bpartner.name, fin_payment.fin_payment_id, fin_payment.paymentdate, fin_payment.amount, fin_payment.referenceno ";
				mysql += "FROM (c_bpartner INNER JOIN fin_payment ON c_bpartner.c_bpartner_id = fin_payment.c_bpartner_id) ";
				mysql += "	INNER JOIN fin_paymentmethod ON fin_payment.fin_paymentmethod_id = fin_paymentmethod.fin_paymentmethod_id ";
				mysql += "WHERE fin_payment.fin_payment_id = '" + s.get(5) + "'";
				BQuery rs = new BQuery(db, mysql);

				try {
					if(rs.moveNext()) {
						// Write cheque details to be printed
						addLine(s.get(1), 420, 75);
						addLine(s.get(2), 80, 195);
						addLine(s.get(3), 420, 180);

						String aiw = s.get(4);
						int lenAiw = aiw.length();
						if(lenAiw < 32) {
							addLine(s.get(4), 130, 220);
						} else {
							int lenPost = aiw.indexOf(" ", 30);
							addLine(aiw.substring(0, lenPost), 130, 220);
							addLine(aiw.substring(lenPost, lenAiw-1), 80, 245);
						}

						// Do the actual printing
						printJob.print();

						// Print Remitance
						rpt.printReport("filterid", s.get(5));

						// clear the remitance
						mysql = "UPDATE fin_payment SET em_dc2_is_printed = 'Y' "; 
						mysql += "WHERE fin_payment_id = '" + rs.getString("fin_payment_id") + "'";
						db.executeQuery(mysql);
					}
				} catch(PrinterException pe) {
					System.out.println("Error printing: " + pe);
				}
			}
		}

		makeCheque();
	}

	public void exportData() {
		JFileChooser fc = new JFileChooser();
		int returnVal = fc.showSaveDialog(this);
		if (returnVal == JFileChooser.APPROVE_OPTION) {
			String filename = fc.getSelectedFile().getAbsolutePath() + ".csv";
			eftTModel.savecvs(filename);
		}
	}

	public void clearEFT() {
		String mysql = "UPDATE (SELECT fin_payment.em_dc2_is_printed ";
		mysql += "FROM fin_payment INNER JOIN fin_paymentmethod ON fin_payment.fin_paymentmethod_id = fin_paymentmethod.fin_paymentmethod_id ";
		mysql += "WHERE (fin_payment.processed = 'Y') AND (fin_paymentmethod.name = 'EFT') AND (fin_payment.em_dc2_is_printed = 'N')) t ";
		mysql += "SET t.em_dc2_is_printed = 'Y'";
		db.executeQuery(mysql);
	}

	// Tool bar button listening
	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("Print Cheques".equals(aKey)) {
			String password = new String(pF.getPassword());
			if(password.equals("bankpassword")) printCheque();
			else label.setText("Wrong bank code");
		} else if("Export EFT".equals(aKey)) {
			exportData();
		} else if("Clear EFT".equals(aKey)) {
			clearEFT();
		}
	}

	public void valueChanged(ListSelectionEvent e) {
		ListSelectionModel lsm = (ListSelectionModel)e.getSource();

		int selectionindex = table.getSelectionModel().getLeadSelectionIndex();
		if((selectionindex >= 0) && (selectionindex < tbdef.cheques.size())) {
			Vector<String> s = tbdef.cheques.get(selectionindex);

			rpt.putparams("filterid", s.get(4));
			rpt.showReport();
		}
	}

	public void windowDeactivated(java.awt.event.WindowEvent e) {}
	public void windowActivated(java.awt.event.WindowEvent e) {}
	public void windowDeiconified(java.awt.event.WindowEvent e) {}
	public void windowIconified(java.awt.event.WindowEvent e) {}
	public void windowOpened(java.awt.event.WindowEvent e) {}
	public void windowClosed(java.awt.event.WindowEvent e) {}
	public void windowClosing(java.awt.event.WindowEvent e) {
	
	a_prn.close();
	}

	public void close() {
		db.close();
	}

}

