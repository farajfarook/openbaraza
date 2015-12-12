/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.utils;

import java.io.File;
import java.io.FileFilter;
import java.io.FilenameFilter;

public class BFileFilter implements FileFilter, FilenameFilter {

	String filter = "";

	public BFileFilter(String filter) {
		this.filter = filter;
	}

	public boolean accept(File dir, String name) {
		return (name.contains(filter));
	}

	public boolean accept(File file) {
		return (file.getName().contains(filter));
	}
}
