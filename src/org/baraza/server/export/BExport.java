/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.export;

import java.util.logging.Logger;
import java.util.List;
import java.util.Date;
import java.io.File;
import java.io.Writer;
import java.io.FileWriter;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;

import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;
import org.baraza.xml.BElement;
import org.baraza.server.ssh.Bssh;
import org.baraza.utils.BLogHandle;

public class BExport {
	Logger log = Logger.getLogger(BExport.class.getName());
	BElement root;
	BDB db;
	int delay;
	String delimeter;

	public BExport(BDB db, BElement root, BLogHandle logHandle) {
		this.root = root;
		this.db = db;
		logHandle.config(log);
	}

	public int process() {
		delimeter = root.getAttribute("delimeter", "\t");

		String shost = root.getAttribute("shost");
		String sftp = root.getAttribute("sftp");
		String suser = root.getAttribute("suser");
		String spasswd = root.getAttribute("spasswd");
		
		for(BElement el : root.getElements()) {
			String lfile = tableExport(el);
			if((sftp != null) && (lfile != null)) {
				Bssh sf = new Bssh(shost, sftp, suser, spasswd, lfile);
			}
		}

		delay = Integer.valueOf(root.getAttribute("delay", "30")) * 60 * 1000;

		log.info(new Date() + " Export : Done");

		return delay;
	}

	public String tableExport(BElement el) {
		String mysql = "";
		String mydata = "";
		String myfile = null;

		for(BElement ell : el.getElements()) {
			if(ell.getName().equals("TEXTFIELD")) {
				if(!mysql.equals("")) mysql += ", ";
				if(ell.getAttribute("basetable") != null) mysql +=  ell.getAttribute("basetable") + ".";
				mysql += ell.getValue();
			} else if(ell.getName().equals("TEXTFUNC")) {
				if(!mysql.equals("")) mysql += ", ";
				mysql += ell.getAttribute("function") + " as " + ell.getValue();
			}
		}

		mysql = "SELECT " + mysql + " FROM " + el.getAttribute("table");
		if(el.getAttribute("wheresql") != null) mysql += " WHERE " + el.getAttribute("wheresql");
		if(el.getAttribute("ordersql") != null) mysql += " ORDER BY " + el.getAttribute("ordersql");
		log.fine(mysql);

		BQuery rs = new BQuery(db, mysql);
		int linecount = 1;
		while(rs.moveNext()) {
			String myln = "";
			for(BElement ell : el.getElements()) {
				if(!myln.equals("")) myln += delimeter;

				String tag = ell.getAttribute("tag");
				if(tag != null) tag = "\"";
				else tag = "";

				if(ell.getName().equals("TEXTFIELD") || ell.getName().equals("TEXTFUNC") || ell.getName().equals("SELECTED")) {
					if(rs.getString(ell.getValue()) == null) myln += tag + tag;
					else myln += tag + rs.getString(ell.getValue()) + tag;
				} else if(ell.getName().equals("TEXTDATA")) {
					String repeat = ell.getAttribute("repeat");
					int rcount = 1;
					if(repeat != null) rcount = Integer.valueOf(repeat);
					for(int i = 0; i < rcount; i++)	{
						if(i != 0) myln += delimeter;
						myln += ell.getValue("");
					}
				} else if(ell.getName().equals("NEWLINE")) {
					mydata += myln + "\n";
					myln = "";
				} else if(ell.getName().equals("LINECOUNT")) {
					myln += Integer.toString(linecount);
				}
			}
			linecount++;
			mydata += myln + "\n";
		}
		rs.close();
		
		//System.out.println(mydata);
		if(!mydata.equals("")) {
			try {
				Date cdate = new Date();
				SimpleDateFormat dateformatter = new SimpleDateFormat("yyyy-MM-dd-HH-mm-");
				myfile = dateformatter.format(cdate) + el.getAttribute("exportpath");
				

				Writer output = new BufferedWriter(new FileWriter(myfile));
				String headerlines = el.getAttribute("pageheader");
				
				if(headerlines != null) {
					File hlf = new File(headerlines);
					BufferedReader input =  new BufferedReader(new FileReader(hlf));
					int len = (int) hlf.length();
					char[] cbuf = new char[len];

					input.read(cbuf, 0, len);
					output.write(cbuf, 0, len);
					input.close();
				}

				output.write(mydata);
				output.close();
			} catch (IOException ex) {
				log.severe("IO Error : " + ex);
			}

			String updfunct = el.getAttribute("updfunct");
			if(updfunct != null) {
				updfunct = "SELECT " + updfunct;
				db.executeQuery(updfunct);
			}
		}

		return myfile;
	}

	public int getDelay() {
		return delay;
	}

	public void close() {
		db.close();
	}
}
