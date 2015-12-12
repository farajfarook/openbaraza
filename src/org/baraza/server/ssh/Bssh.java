/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.server.ssh;

import java.util.logging.Logger;

import com.jcraft.jsch.*;
import java.io.*;

public class Bssh {
	Logger log = Logger.getLogger(Bssh.class.getName());

	public Bssh(String shost, String sftp, String suser, String spasswd, String lfile) {
		try {
			JSch jsch = new JSch();
			jsch.setKnownHosts(shost);

			Session session = jsch.getSession(suser, sftp, 22);

			// username and password will be given via UserInfo interface.
			BUserInfo ui = new BUserInfo();
			ui.setPassword(spasswd);
			session.setUserInfo(ui);
			session.connect();

			FileInputStream fis = null;

			// exec 'scp -t rfile' remotely
			String command="scp -p -t " + lfile;
			Channel channel = session.openChannel("exec");
			((ChannelExec)channel).setCommand(command);

			// get I/O streams for remote scp
			OutputStream out = channel.getOutputStream();
			InputStream in = channel.getInputStream();

			channel.connect();

			if(checkAck(in)!=0) System.exit(0);

			// send "C0644 filesize filename", where filename should not include '/'
			long filesize=(new File(lfile)).length();
			command = "C0644 "+filesize+" ";
			if(lfile.lastIndexOf('/')>0) {
				command += lfile.substring(lfile.lastIndexOf('/')+1);
			} else {
				command += lfile;
			}
			command+="\n";
			out.write(command.getBytes());
			out.flush();

			if(checkAck(in)!=0) {
				System.exit(0);
			}

			// send a content of lfile
			fis = new FileInputStream(lfile);
			byte[] buf=new byte[1024];
			while(true) {
				int len=fis.read(buf, 0, buf.length);
				if(len<=0) break;
				out.write(buf, 0, len); //out.flush();
			}
			fis.close();
			fis = null;

			// send '\0'
			buf[0]=0; out.write(buf, 0, 1); out.flush();
			if(checkAck(in)!=0) System.exit(0);
			out.close();

			channel.disconnect();
			session.disconnect();
		} catch (JSchException ex) {
			log.severe("Session Error : " + ex);
		} catch (IOException ex) {
			log.severe("IO Error : " + ex);
		}
	}

	int checkAck(InputStream in) {
		int b = 1;

		try {
			b = in.read();
			// b may be 0 for success,
			//          1 for error,
			//          2 for fatal error,
			//          -1
			if(b==0) return b;
			if(b==-1) return b;

			if(b==1 || b==2){
				StringBuffer sb = new StringBuffer();
				int c;
				do {
					c = in.read();
					sb.append((char)c);
				} while(c!='\n');

				if(b==1) log.severe(sb.toString()); // error
				if(b==2) log.severe(sb.toString()); // fatal error
			}
		} catch (IOException ex) {
			log.severe("IO Error : " + ex);
		}
		
		return b;
	}

}

