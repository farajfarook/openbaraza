/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.swing;

import java.awt.*;
import java.lang.*;
import javax.swing.*;
import java.beans.*;

public class BTextIcon implements Icon, PropertyChangeListener {
	String fLabel;
	String[] fCharStrings;		// for efficiency, break the fLabel into one-char strings to be passed to drawString
	int[] fCharWidths;			// Roman characters should be centered when not rotated (Japanese fonts are monospaced)
	int fWidth, fHeight, fCharHeight, fDescent; // Cached for speed
	int fRotation;
	Component fComponent;
	
	static final int POSITION_NORMAL = 0;
	static final int POSITION_TOP_RIGHT = 1;
	static final int POSITION_FAR_TOP_RIGHT = 2;
	
	public static final int ROTATE_DEFAULT = 0x00;
	public static final int ROTATE_NONE = 0x01;
	public static final int ROTATE_LEFT = 0x02;
	public static final int ROTATE_RIGHT = 0x04;
	
 	public BTextIcon(Component component, String label, int rotateHint) {
		fComponent = component;
		fLabel = label;
		fRotation = rotateHint;
		calcDimensions();
		fComponent.addPropertyChangeListener(this);
	}
	
	public void setLabel(String label) {
		fLabel = label;
		recalcDimensions();
	}	

    public void propertyChange(PropertyChangeEvent e) {
		String prop = e.getPropertyName();
		if("font".equals(prop)) {
			recalcDimensions();
		}
	}

	void recalcDimensions() {
		int wOld = getIconWidth();
		int hOld = getIconHeight();
		calcDimensions();
		if (wOld != getIconWidth() || hOld != getIconHeight())
			fComponent.invalidate();
	}
	
    void calcDimensions() {
		FontMetrics fm = fComponent.getFontMetrics(fComponent.getFont());
		fCharHeight = fm.getAscent() + fm.getDescent();
		fDescent = fm.getDescent();
		if (fRotation == ROTATE_NONE) {
			int len = fLabel.length();
			char data[] = new char[len];
			fLabel.getChars(0, len, data, 0);

			// if not rotated, width is that of the widest char in the string
			fWidth = 0;

			// we need an array of one-char strings for drawString
			fCharStrings = new String[len];
			fCharWidths = new int[len];
			char ch;
			for (int i = 0; i < len; i++) {
				ch = data[i];
				fCharWidths[i] = fm.charWidth(ch);
				if (fCharWidths[i] > fWidth)
					fWidth = fCharWidths[i];
				fCharStrings[i] = new String(data, i, 1);
			}

			fHeight = fCharHeight * len + fDescent;
		}		
		else {
			fWidth = fCharHeight;
			fHeight = fm.stringWidth(fLabel) + 2*kBufferSpace;
		}
	}

    public void paintIcon(Component c, Graphics g, int x, int y) {
		// We don't insist that it be on the same Component
		g.setColor(c.getForeground());
		g.setFont(c.getFont());
		if (fRotation == ROTATE_NONE) {
			int yPos = y + fCharHeight;
			for (int i = 0; i < fCharStrings.length; i++) {
				int tweak;
				g.drawString(fCharStrings[i], x+((fWidth-fCharWidths[i])/2), yPos);
				yPos += fCharHeight;
			}
		}
		else if (fRotation == ROTATE_LEFT) {
			g.translate(x+fWidth,y+fHeight);
			((Graphics2D)g).rotate(-NINETY_DEGREES);
			g.drawString(fLabel, kBufferSpace, -fDescent);
			((Graphics2D)g).rotate(NINETY_DEGREES);
			g.translate(-(x+fWidth),-(y+fHeight));
		} 
		else if (fRotation == ROTATE_RIGHT) {
			g.translate(x,y);
			((Graphics2D)g).rotate(NINETY_DEGREES);
			g.drawString(fLabel, kBufferSpace, -fDescent);
			((Graphics2D)g).rotate(-NINETY_DEGREES);
			g.translate(-x,-y);
		} 
	
	}
    
    public int getIconWidth() {
		return fWidth;
	}
	
    public int getIconHeight() {
		return fHeight;
	}
	
	static final int DEFAULT_CJK = ROTATE_NONE;
	static final int LEGAL_ROMAN = ROTATE_NONE | ROTATE_LEFT | ROTATE_RIGHT;
	static final int DEFAULT_ROMAN = ROTATE_RIGHT; 
	static final int LEGAL_MUST_ROTATE = ROTATE_LEFT | ROTATE_RIGHT;
	static final int DEFAULT_MUST_ROTATE = ROTATE_LEFT;

	static final double NINETY_DEGREES = Math.toRadians(90.0);
	static final int kBufferSpace = 5;
}

