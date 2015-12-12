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
import java.util.Map;
import java.util.HashMap;

import javax.swing.JSplitPane;
import javax.swing.JTabbedPane;

import javax.swing.event.TreeSelectionListener;
import javax.swing.event.TreeSelectionEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import org.baraza.xml.BElement;
import java.util.Vector;
import org.baraza.DB.BDB;
import org.baraza.reports.BReport;
import org.baraza.utils.BLogHandle;

class BFilter extends JSplitPane implements TreeSelectionListener, MouseListener, ActionListener {
	Logger log = Logger.getLogger(BFilter.class.getName());
	BLogHandle logHandle;
	BDB db;

	Map<String, String> progarationParams;
	Map<String, String> params;

	List<BGrids> grids;
	List<BDrillDown> drilldown;
	List<BCalendar> calendar;
	List<BReport> reports;
	List<BTabs> tabs;
	List<BGrid> filterGrids;
	List<BForm> filterForms;
	JTabbedPane topPanes, bottomPanes;
	JSplitPane splitPane;

	public BFilter(BLogHandle logHandle, BDB db, BElement view, String reportDir) {
		super(JSplitPane.HORIZONTAL_SPLIT);
		this.db = db;
		this.logHandle = logHandle;
		logHandle.config(log);

		grids = new ArrayList<BGrids>();
		drilldown = new ArrayList<BDrillDown>();
		calendar = new ArrayList<BCalendar>();
		reports = new ArrayList<BReport>();
		tabs = new ArrayList<BTabs>();
		filterGrids = new ArrayList<BGrid>();
		filterForms = new ArrayList<BForm>();

		progarationParams = new HashMap<String, String>();
		params = new HashMap<String, String>();

		int location = Integer.valueOf(view.getAttribute("split", "150"));
		super.setOneTouchExpandable(true);
		super.setDividerLocation(location);

		topPanes = new JTabbedPane();
		bottomPanes = new JTabbedPane();
		topPanes.addMouseListener(this);
		if(view.getAttribute("type", "vert").equals("vert")) {
			super.setOrientation(JSplitPane.VERTICAL_SPLIT);

			super.addImpl(topPanes, JSplitPane.TOP, 1);
			super.addImpl(bottomPanes, JSplitPane.BOTTOM, 2);
		} else {
			super.addImpl(topPanes, JSplitPane.LEFT, 1);
			super.addImpl(bottomPanes, JSplitPane.RIGHT, 2);
		}

		for(BElement el : view.getElements()) {
			if(el.getName().equals("GRID")) {
				grids.add(new BGrids(logHandle, db, el, reportDir, true));
				int gs = grids.size() -1;

				bottomPanes.addTab(el.getAttribute("name"), grids.get(gs));
			} else if(el.getName().equals("JASPER")) {
				reports.add(new BReport(logHandle, db, el, reportDir));
				bottomPanes.addTab(el.getAttribute("name"), reports.get(reports.size() -1));
			} else if(el.getName().equals("DRILLDOWN")) {
				drilldown.add(new BDrillDown(logHandle, db, el, reportDir));
				int gs = drilldown.size() -1;
				topPanes.addTab(el.getAttribute("name"), drilldown.get(gs));

				drilldown.get(gs).setListener(this);
				tabs.add(new BTabs(4, drilldown.size()-1));
			} else if(el.getName().equals("CALENDAR")) {
				calendar.add(new BCalendar(el));
				int cs = calendar.size() -1;				
				topPanes.addTab(el.getAttribute("name"), calendar.get(cs));

				calendar.get(cs).setListener(this);
				tabs.add(new BTabs(5, cs));
			} else if(el.getName().equals("FILTERGRID")) {
				filterGrids.add(new BGrid(logHandle, db, el, reportDir));
				int gs = filterGrids.size() -1;
				topPanes.addTab(el.getAttribute("name"), filterGrids.get(gs));

				filterGrids.get(gs).setListener(this);
				tabs.add(new BTabs(7, gs));
			} else if(el.getName().equals("FILTERFORM")) {
				filterForms.add(new BForm(logHandle, db, el));
				int gs = filterForms.size() -1;
				topPanes.addTab(el.getAttribute("name"), filterForms.get(gs));

				filterForms.get(gs).setListener(this);
				tabs.add(new BTabs(8, gs));
			}
		}
	}

	// Get the grid listening mode
	public void valueChanged(TreeSelectionEvent ev) {
		int i = topPanes.getSelectedIndex();
		if(tabs.get(i).getType() == 4) {
			i = tabs.get(i).getIndex();
			String filterName = drilldown.get(i).getFilterName();
			String filterKey = drilldown.get(i).getKey();
			if(filterKey != null) {
				for(BReport report : reports) {
					report.putparams(filterName, filterKey);
					report.drillReport();
				}
			}
		}
	}

	public void mousePressed(MouseEvent ev) {}
	public void mouseReleased(MouseEvent ev) {}
	public void mouseEntered(MouseEvent ev) {}
	public void mouseExited(MouseEvent ev) {}
	public void mouseClicked(MouseEvent ev) {
		int i = topPanes.getSelectedIndex();

		if(ev.getComponent().equals(topPanes)) {
			i = tabs.get(i).getIndex();
			if(tabs.get(i).getType() == 4) 
				drilldown.get(i).createtree();
			if(tabs.get(i).getType() == 7) 
				filterGrids.get(i).showMain();
		} else {
			if(tabs.get(i).getType() == 4) {
				i = tabs.get(i).getIndex();
				drilldown.get(i).createtree();
			}
			if(tabs.get(i).getType() == 7) {
				i = tabs.get(i).getIndex();
				String filterName = filterGrids.get(i).getFilterName();
				String filterKey = filterGrids.get(i).getKey();
				if(filterKey != null) {
					for(BReport report : reports) {
						report.putparams(filterName, filterKey);
						report.drillReport();
					}
					for(BGrids grid : grids) {grid.link(filterKey, params, progarationParams); grid.hideForms();}
				}
			}
			if(tabs.get(i).getType() == 5) {
				i = tabs.get(i).getIndex();
				String filterName = calendar.get(i).getFilterName();
				String filterKey = calendar.get(i).getKey();
				if(filterKey != null) {
					for(BReport report : reports) {
						report.putparams(filterName, filterKey);
						report.drillReport();
					}
					for(BGrids grid : grids) {grid.link(filterKey, params, progarationParams); grid.hideForms();}
				}
			}
		}
	}

	public void actionPerformed(ActionEvent ev) {
		String aKey = ev.getActionCommand();

		if("Filter".equals(aKey)) {
			int i = topPanes.getSelectedIndex();
			i = tabs.get(i).getIndex();
			System.out.println(i);

			for(BReport report : reports) {
				report.putparams(filterForms.get(i).getParam());
			}
			for(BGrids grid : grids) {
				grid.filter(filterForms.get(i).getWhere());
				grid.hideForms();
			}
		} else if("Print All".equals(aKey)) {
			int i = topPanes.getSelectedIndex();
			i = tabs.get(i).getIndex();
			//System.out.println(i);
			String filterName = filterGrids.get(i).getFilterName();
			String update = filterGrids.get(i).getUpdate();
			Vector<String> keys = filterGrids.get(i).getKeys();

			for(String key : keys) {
				//System.out.println(key);
				boolean printed = true;
				for(BReport report : reports) {
					if(!report.printReport(filterName, key)) printed = false;
				}
				if(printed && (update != null)) {
					String updSql = "SELECT " + update + "('" + db.getUserID() + "', '" + db.getUserIP();
					updSql += "', '" + key + "')";
					System.out.println(updSql);
					db.executeQuery(updSql);
				}
			}

			// Go to the main page and refresh
			filterGrids.get(i).showMain();
			filterGrids.get(i).refresh();
		}
	}
}