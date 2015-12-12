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
import java.util.List;
import java.util.ArrayList;

import javax.swing.JInternalFrame;
import javax.swing.JTabbedPane;
import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;

import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.reports.BReport;
import org.baraza.utils.BLogHandle;

public class BDesk extends JInternalFrame implements MouseListener {
	Logger log = Logger.getLogger(BDesk.class.getName());
	BLogHandle logHandle;
	String name;
	String key;	
	int w;
	int h;
	List<BGrids> grids;
	List<BReport> reports;
	List<BForm> forms;
	List<BFilter> filters;
	List<BTabs> tabs;
	JTabbedPane tabbedPane;

	public BDesk(BLogHandle logHandle, BDB db, BElement desk, String reportDir) {
		super(desk.getAttribute("name"), true, true, true, true);
		this.logHandle = logHandle;
		logHandle.config(log);

		name = desk.getAttribute("name");
		key = desk.getAttribute("key");
		w = Integer.valueOf(desk.getAttribute("w")).intValue();
		h = Integer.valueOf(desk.getAttribute("h")).intValue();

		tabbedPane = new JTabbedPane();
		grids = new ArrayList<BGrids>();
		reports = new ArrayList<BReport>();
		forms = new ArrayList<BForm>();
		filters = new ArrayList<BFilter>();
		tabs = new ArrayList<BTabs>();

		for(BElement el : desk.getElements()) {
			if(el.getName().equals("FORM")) {
				forms.add(new BForm(logHandle, db, el));
				forms.get(forms.size() -1).moveFirst();
				tabbedPane.addTab(el.getAttribute("name"), forms.get(forms.size() -1));

				tabs.add(new BTabs(1, forms.size()-1));
			} else if(el.getName().equals("GRID")) {
				grids.add(new BGrids(logHandle, db, el, reportDir, false));
				tabbedPane.addTab(el.getAttribute("name"), grids.get(grids.size() -1));

				tabs.add(new BTabs(2, grids.size()-1));
			} else if(el.getName().equals("JASPER")) {
				reports.add(new BReport(logHandle, db, el, reportDir));
				tabbedPane.addTab(el.getAttribute("name"), reports.get(reports.size() -1));
				reports.get(reports.size() -1).showReport();

				tabs.add(new BTabs(3, reports.size()-1));
			} else if(el.getName().equals("FILTER")) {
				filters.add(new BFilter(logHandle, db, el, reportDir));
				tabbedPane.addTab(el.getAttribute("name"), filters.get(filters.size() -1));

				tabs.add(new BTabs(4, filters.size()-1));
			}
		}
		add(tabbedPane);
		tabbedPane.addMouseListener(this);

		setSize();
	}

  	public void setSize() {
        super.setLocation(10, 10);
        super.setSize(w, h);
 	}

	public void mousePressed(MouseEvent ev) {}
	public void mouseReleased(MouseEvent ev) {}
	public void mouseEntered(MouseEvent ev) {}
	public void mouseExited(MouseEvent ev) {}
	public void mouseClicked(MouseEvent ev) {
		int i = tabbedPane.getSelectedIndex();

		if(tabs.get(i).getType() == 2) {
			i = tabs.get(i).getIndex();
			grids.get(i).hideForms();
			grids.get(i).refresh();
		}

		if(tabs.get(i).getType() == 3) {
			int j = tabs.get(i).getIndex();
			reports.get(j).drillReport();
		}
	}

}