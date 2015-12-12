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

public class BUserInfo implements UserInfo {
	String passwd;
	public String getPassword(){ return passwd; }
	public boolean promptYesNo(String str) {  return true; }
    public String getPassphrase(){ return null; }
    public boolean promptPassphrase(String message){ return true; }
    public boolean promptPassword(String message){ return true;  }
    public void showMessage(String message) { System.out.println("Loging Error"); }
	public void setPassword(String passwd) { this.passwd = passwd; }
}