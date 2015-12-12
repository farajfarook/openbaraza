/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.swing;

import org.baraza.utils.Bio;
import org.baraza.xml.BTreeNode;
import org.baraza.xml.BElement;

import javax.swing.JTree;
import javax.swing.tree.DefaultTreeModel;
import javax.swing.tree.TreePath;
import javax.swing.JPopupMenu;
import javax.swing.JMenuItem;
import javax.swing.JComponent;

import java.awt.Insets;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.dnd.Autoscroll;
import java.awt.Graphics;
import java.awt.Dimension;
import java.awt.image.BufferedImage;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;

public class BImageTree extends JTree implements Autoscroll, ActionListener, MouseListener {

	JPopupMenu popup;
    JMenuItem mi;
	DefaultTreeModel treeModel;
	BTreeNode oldNode = null;
	BTreeNode oldParentNode = null;
	int nodeStatus = 0;
	private BufferedImage img = null;
	private int iw, ih;
	private int margin = 12;

	public BImageTree(String imgFileName, DefaultTreeModel treeModel, boolean hasMenu) {
		super(treeModel);
		super.setOpaque(false);

		this.treeModel = treeModel;

		Bio io = new Bio();
		img = io.loadImage(imgFileName);

		iw = img.getWidth();
		ih = img.getHeight();


        popup = new JPopupMenu();
		if(hasMenu) {
			String[] mnArray = {"Copy", "Cut", "Insert", "Paste", "New", "Delete"};
			for(int i = 0; i < mnArray.length; i++) {
				mi = new JMenuItem(mnArray[i]);
				mi.addActionListener(this);
				popup.add(mi);
			}
			popup.setOpaque(true);
			popup.setLightWeightPopupEnabled(true);
		}

		super.addMouseListener(this);
	}

	public void actionPerformed(ActionEvent ev) {
        
        TreePath path = this.getSelectionPath();
		if(path != null) {
			if (ev.getActionCommand().equals("Copy")) {
				oldNode = (BTreeNode)path.getLastPathComponent();
				nodeStatus = 1;
			} else if (ev.getActionCommand().equals("Cut")) {
				oldNode = (BTreeNode)path.getLastPathComponent();
				oldParentNode = (BTreeNode)path.getParentPath().getLastPathComponent();
				nodeStatus = 2;
			} else if (ev.getActionCommand().equals("Insert")) {
				BTreeNode parentNode = (BTreeNode)path.getParentPath().getLastPathComponent();
				BTreeNode selectedNode = (BTreeNode)path.getLastPathComponent();
				int i = parentNode.getIndex(selectedNode);
				if(nodeStatus == 1) {
					BElement newEl = oldNode.getKey().copy();
					BTreeNode newNode = makeNode(newEl);

					parentNode.insert(newNode, i);
					parentNode.getKey().addNode(newNode.getKey(), i);
				} else if(nodeStatus == 2) {
					if(oldParentNode != null) oldParentNode.getKey().delNode(oldNode.getKey());

					parentNode.insert(oldNode, i);
					parentNode.getKey().addNode(oldNode.getKey(), i);

					if(oldParentNode != null) treeModel.reload(oldParentNode);
				}

				treeModel.reload(parentNode);
			} else if (ev.getActionCommand().equals("Paste")) {
				if(nodeStatus == 1) {
					BElement newEl = oldNode.getKey().copy();
					BTreeNode newNode = makeNode(newEl);
					BTreeNode selectedNode = (BTreeNode)path.getLastPathComponent();

					selectedNode.add(newNode);
					selectedNode.getKey().addNode(newNode.getKey());

					treeModel.reload(selectedNode);
				} else if(nodeStatus == 2) {
					BTreeNode selectedNode = (BTreeNode)path.getLastPathComponent();

					if(oldParentNode != null) oldParentNode.getKey().delNode(oldNode.getKey());

					selectedNode.add(oldNode);
					selectedNode.getKey().addNode(oldNode.getKey());

					treeModel.reload(selectedNode);
					if(oldParentNode != null) treeModel.reload(oldParentNode);
				}
			} else if (ev.getActionCommand().equals("New")) {
				BTreeNode selectedNode = (BTreeNode)path.getLastPathComponent();
				if(selectedNode != null) {
					BTreeNode newNode = makeNode(new BElement("NODE"));

					selectedNode.add(newNode);
					selectedNode.getKey().addNode(newNode.getKey());

					treeModel.reload(selectedNode);
				}
			} else if (ev.getActionCommand().equals("Delete")) {
				BTreeNode selectedNode = (BTreeNode)path.getLastPathComponent();
				BTreeNode parentNode = (BTreeNode)path.getParentPath().getLastPathComponent();
				if(parentNode != null) {
					parentNode.getKey().delNode(selectedNode.getKey());
					parentNode.remove(selectedNode);
					treeModel.reload(parentNode);
				}
			}
		}
	}

	public BTreeNode makeNode(BElement sbn) {
		String title = sbn.getName() + " : ";
		if(sbn.getAttribute("title") != null) title += sbn.getAttribute("title");
		else if (sbn.getAttribute("name") != null) title += sbn.getAttribute("name");
		
		BTreeNode firstNode = new BTreeNode(sbn, title);
		for(BElement el : sbn.getElements())
			firstNode.add(makeNode(el));

		return firstNode;
	}

	public void mousePressed(MouseEvent ev) {
		if(ev.isPopupTrigger())
			popup.show((JComponent)ev.getSource(), ev.getX(), ev.getY());
	}

	public void mouseExited(MouseEvent ev) {}
	public void mouseEntered(MouseEvent ev) {}
	public void mouseClicked(MouseEvent ev) {}
	public void mouseReleased(MouseEvent ev) {}

	public void autoscroll(Point p) {
		int realrow = getRowForLocation(p.x, p.y);
		Rectangle outer = getBounds();
		realrow = (p.y + outer.y <= margin ? realrow < 1 ? 0 : realrow - 1 : realrow < getRowCount() - 1 ? realrow + 1 : realrow);
		scrollRowToVisible(realrow);
	}

	public Insets getAutoscrollInsets() {
		Rectangle outer = getBounds();
		Rectangle inner = getParent().getBounds();
		return new Insets(inner.y - outer.y + margin, inner.x - outer.x
			+ margin, outer.height - inner.height - inner.y + outer.y
			+ margin, outer.width - inner.width - inner.x + outer.x + margin);
	}

	protected void paintComponent(Graphics g) {
		if(img != null) {
			Dimension d = getSize();
			int w = (int)d.getWidth();
			int h = (int)d.getHeight();

			g.drawImage(img, 0, 0, w, h, 0, 0, iw, ih, null);
		}

		super.paintComponent(g);
	}
}
