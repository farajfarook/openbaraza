package com;

import java.sql.*;
import java.util.*;

public class dbCompare {

	public static void main(String args[]) {

		for(Integer i = 0; i < 15; i++) dbcmp(i);
		
	}

	public static void dbcmp(Integer dbNo) {
		try {
			String driver = "org.postgresql.Driver";
			String dbpath = "jdbc:postgresql://localhost/hr" + dbNo.toString();

			Class.forName(driver);
			Connection db = DriverManager.getConnection(dbpath, "root", "invent2k");

			System.out.println("\nDatabase " + dbNo.toString());
			recRead(db, "SELECT max(adjustment_id) as adj_count FROM adjustments", "adj_count");
			recRead(db, "SELECT max(entity_id) as emp_max FROM employees", "emp_max");
			recRead(db, "SELECT count(entity_id) as emp_count FROM employees", "emp_count");
			recRead(db, "SELECT count(period_id) as period_count FROM periods", "period_count");
			recRead(db, "SELECT max(start_date) as period_max FROM periods", "period_max");
			recRead(db, "SELECT count(employee_month_id) as emp_months_count FROM employee_month", "emp_months_count");
			recRead(db, "SELECT max(employee_month_id) as emp_months_max FROM employee_month", "emp_months_max");
			recRead(db, "SELECT count(employee_adjustment_id) as emp_adjust_count FROM employee_adjustments", "emp_adjust_count");
			recRead(db, "SELECT count(invoice_id) as invoice_count FROM invoices", "invoice_count");
			recRead(db, "SELECT count(project_cost_id) as project_cost_count FROM project_cost", "project_cost_count");
			recRead(db, "SELECT count(employee_leave_id) as emp_leave_count FROM employee_leave", "emp_leave_count");
			recRead(db, "SELECT count(bank_branch_id) as bank_branch_count FROM bank_branch", "bank_branch_count");
			recRead(db, "SELECT count(employee_advance_id) as emp_advance_count FROM employee_advances", "emp_advance_count");
			recRead(db, "SELECT count(employee_overtime_id) as emp_OT_count FROM employee_overtime", "emp_OT_count");
			recRead(db, "SELECT count(employee_per_diem_id) as emp_per_diem_count FROM employee_per_diem", "emp_per_diem_count");
				
			db.close();
		} catch (ClassNotFoundException ex) {
			System.out.println("Class not found : " + ex);
		} catch (SQLException ex) {
			System.out.println("Database connection error : " + ex);
		}
	}

	public static void recRead(Connection db, String mysql, String fieldName) {
		try {
			Statement st = db.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_UPDATABLE);
			ResultSet rs = st.executeQuery(mysql);
			while (rs.next()) System.out.println(fieldName + " : " + rs.getString(fieldName));

			rs.close();
			st.close();
		} catch (SQLException ex) {
			System.out.println("Database connection error : " + ex);
		}
	}

}
