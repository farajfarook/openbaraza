/**
 * @author      Dennis W. Gichangi <dennis@openbaraza.org>
 * @version     2011.0329
 * @since       1.6
 * website		www.openbaraza.org
 * The contents of this file are subject to the GNU Lesser General Public License
 * Version 3.0 ; you may use this file in compliance with the License.
 */

import java.util.List;
import java.util.ArrayList;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.IOException;

import java.sql.Types;
import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import org.apache.poi.poifs.filesystem.*;
import org.apache.poi.hssf.usermodel.*;

public class BExcel {

	Connection db = null;

	public static void main(String args[]) {
		BExcel ex = new BExcel();
		ex.dbConnect();
		ex.getExcelData(args[0], args[1]);
		ex.dbClose();
	}

	public void getExcelData(String fileName, String worksheet) {
		int colCount = 0;
		HSSFWorkbook wb = null;
		try {
			InputStream stream = new FileInputStream(fileName);
			POIFSFileSystem fs = new POIFSFileSystem(stream);
			DirectoryEntry rootdir = fs.getRoot();
			wb = new HSSFWorkbook(fs);
		} catch (IOException ex) {
			System.out.println("an I/O error occurred, or the InputStream did not provide a compatible POIFS data structure : " + ex);
		}

		HSSFSheet sheet = wb.getSheetAt(Integer.valueOf(worksheet));
		HSSFRow row = sheet.getRow(0);
		List<String> tbTitles = new ArrayList<String>();
		String title = "";
		String ctSql = "CREATE TABLE " + fileName.substring(0, fileName.indexOf(".")) + " ( ";
		String insSql = "INSERT INTO " + fileName.substring(0, fileName.indexOf(".")) + " (is_uploaded";
		String valSql = ") VALUES (?";
		ctSql += "\n\t" + fileName.substring(0, fileName.indexOf(".")) + "_id \t\tserial primary key,";
		ctSql += "\n\tis_uploaded \t\tboolean default false not null";
		while(title != null) {
			title = getstrvalue(row, colCount);
			if(title != null) {
				tbTitles.add(title);
				ctSql += ",\n\t" + title.replace(" ", "_") + "\t\tvarchar(256)";
				insSql += ", " + title.replace(" ", "_");
				valSql += ", ?";
				colCount++;
			}
		}
		ctSql += "\n)";

System.out.println("BS 20 : " + ctSql);
System.out.println("BS 40 : " + insSql + valSql + ")");

		// Create the table
		executeQuery(ctSql);

        try {
			PreparedStatement ps = db.prepareStatement(insSql + valSql + ")");

			String myline = "";
			for(int i = 1; i <= sheet.getLastRowNum(); i++) {
				row = sheet.getRow(i);
				if(row != null)  {
					myline = getstrvalue(row, 0);
					if(myline == null) myline = "";
					System.out.println(i + " : " + myline);

					if(!myline.equals("")) {
						ps.setBoolean(1, false);
						for (int j=0; j<colCount; j++) {
							String fvalue = getstrvalue(row, j);
							if(fvalue == null) ps.setNull(j+2, Types.VARCHAR);
							else ps.setString(j+2, fvalue);
						}
						ps.executeUpdate();
					}
				}
			}
		} catch (SQLException ex) {
			System.out.println("Database executeQuery error : " + ex);
		}
	}

	public String getstrvalue(HSSFRow row, int column) {
		String mystr = null;

		HSSFCell cell = row.getCell(column);
		if (cell == null) cell = row.createCell(column);
		if (cell.getCellType()==cell.CELL_TYPE_STRING) {
			if(cell.getStringCellValue()!=null) mystr = cell.getStringCellValue().trim();
		} else if (cell.getCellType()==cell.CELL_TYPE_NUMERIC) {
			mystr = String.valueOf(cell.getNumericCellValue());
		}

		return mystr;
	}

	public void dbConnect() {
		try {
			db = DriverManager.getConnection("jdbc:postgresql://localhost/cases", "root", "invent");
		} catch (SQLException ex) {
			System.out.println("DB connection Error : " + ex);
		}
	}

	public String executeQuery(String mysql) {
		String rst = null;

		try {
			Statement st = db.createStatement();
			st.execute(mysql);
			st.close();
		} catch (SQLException ex) {
			rst = ex.toString();
			System.out.println("Database executeQuery error : " + ex);
		}

		return rst;
	}

	public void dbClose() {
		try {
			if(db != null) db.close();
			db = null;
		} catch (SQLException ex) {
			System.out.println("DB Close Error : " + ex);
		}
	}
 
}