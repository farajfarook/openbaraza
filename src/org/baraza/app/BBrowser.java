/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.app;

import java.awt.BorderLayout;
import java.io.IOException;
import java.net.URL;
import java.net.MalformedURLException;

import java.net.CookieManager;
import java.net.CookieHandler;
import java.net.CookiePolicy;

import javax.swing.JScrollPane;
import javax.swing.JPanel;
import javax.swing.JEditorPane;
import javax.swing.text.html.HTMLEditorKit;
import javax.swing.event.HyperlinkListener;
import javax.swing.event.HyperlinkEvent;

import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.utils.BCipher;
import org.baraza.utils.BLogHandle;

public class BBrowser extends JPanel implements HyperlinkListener {
	JEditorPane editorPane;
	HTMLEditorKit kit;
	CookieManager cm;
	String baseURL, linkfield, blankpage, disabled, access_cipher;
	URL myurl;
	JScrollPane editorScrollPane;

	public BBrowser(BElement view) {
		super(new BorderLayout());

		baseURL = view.getAttribute("baseurl");
		blankpage = view.getAttribute("blankpage");
		disabled = view.getAttribute("disabled");
		linkfield = view.getAttribute("linkfield", "actionvalue");
		access_cipher = view.getAttribute("access_cipher");

		if(access_cipher != null) {
			BCipher cipher = new BCipher("ToWeRs20");
			access_cipher = cipher.encrypt(access_cipher);
		}

		cm = new java.net.CookieManager();
		cm.setCookiePolicy(CookiePolicy.ACCEPT_ALL);
		CookieHandler.setDefault(cm);

		editorPane = new JEditorPane();
		editorPane.setEditable(false);
		kit = new HTMLEditorKit();
        editorPane.setEditorKit(kit);

		editorPane.addHyperlinkListener(this);

		//Put the editor pane in a scroll pane.
		editorScrollPane = new JScrollPane(editorPane);
		editorScrollPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);

		super.add(editorScrollPane, BorderLayout.CENTER);
	}

	public void setPage(String key) {
		String myws = baseURL + "&" + linkfield + "=" + key;
		if(blankpage != null) myws += "&blankpage=" + blankpage;
		if(disabled != null) myws += "&disabled=" + disabled;
		if(access_cipher != null) myws += "&_access_cipher=" + access_cipher;

		setURL(myws);
	}

	public void setURL(String strURL) {
		try {
			URL lURL = new URL(strURL);
			setURL(lURL);
		} catch(MalformedURLException ex) {
			System.err.println("Attempted to read a bad URL: " + ex);
		}
	}

	public void setURL(URL myurl) {
		try {
			if (myurl != null) editorPane.setPage(myurl);
			else System.err.println("Couldn't find file: mhealth");
		} catch (IOException ex) {
			System.err.println("Attempted to read a bad URL: " + ex);
		}
	}

	public void hyperlinkUpdate(HyperlinkEvent ev) {
		if (ev.getEventType() == HyperlinkEvent.EventType.ACTIVATED) {
			System.out.println(ev.getURL());
			setURL(ev.getURL());
		}
	}

}
