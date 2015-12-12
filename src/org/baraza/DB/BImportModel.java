/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */
package org.baraza.DB;

import java.util.logging.Logger;
import java.util.List;
import java.util.ArrayList;
import java.util.Vector;

import java.io.FileReader;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.IOException;

import javax.swing.JPanel;
import javax.swing.JFileChooser;

import javax.swing.table.AbstractTableModel;
import javax.swing.event.TableModelEvent;

import org.apache.poi.poifs.filesystem.*;
import org.apache.poi.hssf.usermodel.*;

import org.baraza.xml.BElement;

public class BImportModel extends AbstractTableModel {
	Logger log = Logger.getLogger(BImportModel.class.getName());
	List<String> columnTitle;
	List<Integer> columnWidth;
	List<Integer> dataWidth;
	Vector<Vector<Object>> rows;

	String sql;

	String keyfield;
	List<String> keylist;

	public BImportModel(BElement fielddef) {
		columnTitle = new ArrayList<String>();
		columnWidth = new ArrayList<Integer>();
		dataWidth = new ArrayList<Integer>();
		rows = new Vector<Vector<Object>>();

		for(BElement el : fielddef.getElements()) {
			if(el.getAttribute("title") != null) {
				columnTitle.add(el.getAttribute("title"));
				columnWidth.add(Integer.valueOf(el.getAttribute("w")));
				dataWidth.add(Integer.valueOf(el.getAttribute("dw", "0")));
			}
       	}
	}

 	public String getColumnName(int col) {
		return columnTitle.get(col);
	}

	public int getRowCount() {
		return rows.size();
	}

	public int getColumnCount() {
		return columnTitle.size();
	}

    public Object getValueAt(int aRow, int aColumn) {
        Vector<Object> row = rows.elementAt(aRow);
        return row.elementAt(aColumn);
    }

	public boolean isCellEditable(int row, int col) {
		return false;
	}

	public void setValueAt(Object value, int row, int col) {
		Vector<Object> dataRow = rows.elementAt(row);
		dataRow.setElementAt(value.toString(), col);
	}

	public void getTextData(JPanel panel, String delimiter) { // Get all rows.
		FileReader input = null;
		String filename = "";		
		rows.removeAllElements();

		if(delimiter==null) delimiter = ",";

		JFileChooser fc = new JFileChooser();
		int returnVal = fc.showOpenDialog(panel);
       	if (returnVal == JFileChooser.APPROVE_OPTION) {
 			filename = fc.getSelectedFile().getAbsolutePath();

			try {
				input = new FileReader(filename);
				BufferedReader reader = new BufferedReader(input);

				String myline = "";
				do {
					myline = reader.readLine();
					if(myline != null) {
						int x = myline.indexOf("\"");
						while (x >= 0) {
							x = myline.indexOf("\"");
							int l = myline.length();
							int y = -1;
							if (x>=0) { 
								y = myline.indexOf("\"", x + 1);
								if(y>x) {
									String newline = myline.substring(0, x) + myline.substring(x+1, y).replace(",", "") + myline.substring(y+1, l);
									//System.out.println(newline);
									myline = newline;
								}
							}
						}
						
						String[] mytokens = myline.split(delimiter);
						
						if(mytokens.length>0) {
							Vector<Object> myvec = new Vector<Object>();
							for (int j=0;j<getColumnCount();j++) {
								if(j < mytokens.length) myvec.add(getstrvalue(mytokens[j]));
								else myvec.add("");
							}
							rows.add(myvec);
						}
					}
				} while (myline != null);

				if (input != null) input.close();
			} catch (IOException ex) {
				System.out.println("File error.");
			}
		}

       	fireTableChanged(null); // Tell the listeners a new table has arrived.		
	}

	public void getRecordData(JPanel panel) { // Get all rows.
		FileReader input = null;
		String filename = "";
		rows.removeAllElements();

		JFileChooser fc = new JFileChooser();
		int returnVal = fc.showOpenDialog(panel);
       	if (returnVal == JFileChooser.APPROVE_OPTION) {
 			filename = fc.getSelectedFile().getAbsolutePath();

			try {
				input = new FileReader(filename);
				BufferedReader reader = new BufferedReader(input);
				int mdw = 0;
				for(Integer dw : dataWidth) mdw += dw;

				String myline = "";
				do {
					myline = reader.readLine();
					if(myline != null) {
						if (myline.length()==mdw) {
							int sp = 0;
							Vector<Object> myvec = new Vector<Object>();
							for(Integer dw : dataWidth) {
								String mytoken = myline.substring(sp, sp+dw);
								sp += dw;
								myvec.add(mytoken.trim());
							}
							rows.add(myvec);
						}
					}
				} while (myline != null);

				if (input != null) input.close();
			} catch (IOException ex) {
				log.severe("File error : " + ex);
			}
		}

       	fireTableChanged(null); // Tell the listeners a new table has arrived.		
	}

	public void getExcelData(JPanel panel, String worksheet) { // Get all rows.
		String filename = "";
		rows.removeAllElements();

		JFileChooser fc = new JFileChooser();
		int returnVal = fc.showOpenDialog(panel);
       	if (returnVal == JFileChooser.APPROVE_OPTION) {
 			filename = fc.getSelectedFile().getAbsolutePath();

			POIFSFileSystem fs = null;
			HSSFWorkbook wb = null;
			DirectoryEntry rootdir = null;
			try {
				InputStream stream = new FileInputStream(filename);
				fs = new POIFSFileSystem(stream);
				rootdir = fs.getRoot();
				wb = new HSSFWorkbook(fs);
			} catch (IOException ex) {
    			log.severe("an I/O error occurred, or the InputStream did not provide a compatible POIFS data structure : " + ex);
			}

			HSSFSheet sheet = wb.getSheetAt(Integer.valueOf(worksheet));
			HSSFRow row = null;
			int i = 0;			
			String myline = "";
			for(i = sheet.getFirstRowNum(); i <= sheet.getLastRowNum(); i++) {
				Vector<Object> myvec = new Vector<Object>();
				row = sheet.getRow(i);
				if(row!=null)  {
					myline = getstrvalue(row, 0);

					//System.out.println(myline);
					for (int j=0;j<getColumnCount();j++)
						myvec.add(getstrvalue(row, j));
					if(!myline.equals(""))
						rows.add(myvec);
				} else myline = "";
			}
		}

       	fireTableChanged(null); // Tell the listeners a new table has arrived.		
	}

	public void clearupload() {
		rows.removeAllElements();
		fireTableChanged(null); // Tell the listeners a new table has arrived.		
	}

	public String getstrvalue(String mystr) {
		String newstr = mystr.replaceAll("\"", "").trim();

		return newstr;
	}

	public String getstrvalue(HSSFRow row, int column) {
		String mystr = "";

		HSSFCell cell = row.getCell(column);
		if (cell == null) cell = row.createCell(column);
		if (cell.getCellType()==cell.CELL_TYPE_STRING) {
			if(cell.getStringCellValue()!=null)
				mystr += cell.getStringCellValue().trim();
		} else if (cell.getCellType()==cell.CELL_TYPE_NUMERIC) {
			mystr += cell.getNumericCellValue();
		}

		return mystr;
	}

	public Vector<Vector<Object>> getData() {
		return rows;
	}

	public void close() {}
}
