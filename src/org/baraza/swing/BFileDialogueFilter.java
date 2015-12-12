/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.swing;

import java.io.File;
import java.util.List;
import java.util.ArrayList;
import javax.swing.filechooser.FileFilter;

public class BFileDialogueFilter extends FileFilter {

    private List<String> filters = null;
    private String description = "";

    public BFileDialogueFilter(String[] filterArray, String description) {
		filters = new ArrayList<String>();
		for (String filter : filterArray) filters.add(filter);
		
		if(description != null) this.description = description;
		else this.description = "";
    }

    public boolean accept(File f) {
		if(f != null) {
		    if(f.isDirectory()) return true;
	    
	    	String extension = getExtension(f);
			if (extension == null) {
				return false;
			} else {
				if(filters.contains(extension)) return true;
			}
	    }
	
		return false;
    }

	public String getExtension(File f) {
		if(f != null) {
		    String filename = f.getName();
		    int i = filename.lastIndexOf('.');
		    if(i>0 && i<filename.length()-1) {
				return filename.substring(i+1).toLowerCase();
		    }
		}

		return null;
    }

    public String getDescription() {
		String fullDescription = description;
		for(String filter : filters) fullDescription += ", ." + filter;
		return fullDescription;
    }

}

