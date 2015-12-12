DELETE FROM department_roles;

INSERT INTO department_roles(org_id, department_id, department_role_id, department_role_name)
SELECT 0, 0, Desig_id, Desig_name
FROM tblDesignation
ORDER BY Desig_id;


---- New version 1


UPDATE tblEmployee SET emp_last_name = emp_middle_name WHERE emp_last_name is null;
UPDATE tblEmployee SET emp_middle_name = null WHERE emp_last_name = emp_middle_name;
UPDATE tblEmployee SET emp_first_name = initcap(trim(emp_first_name)), emp_last_name = initcap(trim(emp_last_name)), emp_middle_name = initcap(trim(emp_middle_name)); 

INSERT INTO employees (bank_branch_id, pay_scale_id, pay_group_id, location_id, currency_id, org_id,
	employee_id, department_role_id, person_title, first_name, middle_name, surname,
	gender, nationality, appointment_date)
SELECT 0, 0, 0, 0, 1, 0,
	emp_payroll_no, emp_desig_id, emp_title, emp_first_name, emp_middle_name, emp_last_name,
	(CASE WHEN emp_gender = 1 THEN 'M' ELSE 'F' END), 'KE', emp_join_date
FROM tblEmployee
WHERE emp_id <> 173
ORDER BY emp_id;




