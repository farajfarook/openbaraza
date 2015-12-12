
ALTER TABLE departments ADD dept_account varchar(25);
ALTER TABLE departments ADD dept_function varchar(25);
ALTER TABLE departments ADD dept_project varchar(25);

INSERT INTO departments(department_id, ln_department_id, org_id, department_name, dept_account, dept_function, dept_project, details)
SELECT departmentid, 0, 0, departmentname, accountnumber, depfunction, deptproject, details
FROM import.departments
ORDER BY departmentid;

INSERT INTO department_roles(department_role_id, department_id, ln_department_role_id, org_id, department_role_name)
SELECT department_id, department_id, 0, org_id, department_name
FROM departments
WHERE department_id <> 0;

INSERT INTO banks(bank_id, sys_country_id, org_id, bank_name)
SELECT bankid, 'KE', 0, bankname
FROM import.banks
ORDER BY bankid;

INSERT INTO bank_branch(bank_branch_id, bank_id, org_id, bank_branch_name, bank_branch_code)
SELECT b.id, b.bankid, 0, a.branchname, b.bankbranchid
FROM import.branch as a INNER JOIN import.bankbranch b ON a.branchid = b.branchid
ORDER BY b.id;


INSERT INTO adjustments(adjustment_id, currency_id, org_id, adjustment_name, adjustment_type)
SELECT allowanceid, 1, 0, allowancename, 1
FROM import.allowances
ORDER BY allowanceid;

INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, in_tax) VALUES (1, 15, 'Tax Allowance', true, true);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, in_tax) VALUES (1, 16, 'NHIF Allowance', true, true);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, in_tax, in_payroll) VALUES (1, 17, 'Value of Quarters .25', false, true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, in_tax, in_payroll) VALUES (1, 18, 'Value of Quarters .50', false, true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, in_tax, in_payroll) VALUES (1, 19, 'Value of Quarters .75', false, true, false);
UPDATE adjustments SET org_id = 0, currency_id = 1;

INSERT INTO adjustments(adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, account_number)
SELECT 20 + deductionid, 1, 0, deductionname, 2, accountnumber
FROM import.deductions
ORDER BY deductionid;

INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 1, 'PAYE', 'Get_Employee_Tax(employee_tax_type_id, 2)', 1162, 1, false, true, true, 0, 0, true, NULL);
INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 2, 'NSSF', 'Get_Employee_Tax(employee_tax_type_id, 1)', 0, 0, true, true, true, 0, 0, true, NULL);
INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 3, 'NHIF', 'Get_Employee_Tax(employee_tax_type_id, 1)', 0, 0, false, false, false, 0, 0, true, NULL);
INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 4, 'FULL PAYE', 'Get_Employee_Tax(employee_tax_type_id, 2)', 0, 0, false, false, false, 0, 0, false, NULL);
SELECT pg_catalog.setval('tax_types_tax_type_id_seq', 4, true);
UPDATE tax_types SET org_id = 0, currency_id = 1;

INSERT INTO tax_rates(tax_type_id, org_id, tax_range, tax_rate)
SELECT 1, 0, upperrange, taxrate
FROM import.taxrates;

INSERT INTO tax_rates(tax_type_id, org_id, tax_range, tax_rate)
SELECT 2 ,0, lowerrange, nssfrate
FROM import.nssfrates;

INSERT INTO tax_rates(tax_type_id, org_id, tax_range, tax_rate)
SELECT 3, 0, upperrange, amount
FROM import.nhifrates
ORDER BY nhisrateid;

ALTER TABLE periods ADD acc_period	varchar(12);

UPDATE import.monthrates SET startdate = '2013-04-01'::date WHERE monthrateid = 144;
INSERT INTO periods(period_id, org_id, start_date, end_date, acc_period)
SELECT monthrateid, 0, startdate, enddate, accperiod
FROM import.monthrates
ORDER BY monthrateid;


INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Wife');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Husband');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Daughter');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Son');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Mother');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Father');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Brother');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Sister');
INSERT INTO kin_types (org_id, kin_type_name) VALUES (0, 'Others');

INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 1, 'Primary School');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 2, 'Secondary School');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 3, 'High School');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 4, 'Certificate');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 5, 'Diploma');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 6, 'Profesional Qualifications');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 7, 'Higher Diploma');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 8, 'Under Graduate');
INSERT INTO education_class (org_id, education_class_id, education_class_name) VALUES (0, 9, 'Post Graduate');
SELECT pg_catalog.setval('education_class_education_class_id_seq', 9, true);

INSERT INTO pay_scales (org_id, pay_scale_id, pay_scale_name, min_pay, max_pay) VALUES (0, 0, 'Basic', 0, 1000000);
INSERT INTO pay_groups (org_id, pay_group_id, pay_group_name) VALUES (0, 0, 'Default');
INSERT INTO locations (org_id, location_id, location_name) VALUES (0, 0, 'Main office');
INSERT INTO disability (org_id, disability_id, disability_name) VALUES (0, 0, 'None');

UPDATE import.employees SET employeename = trim(replace(employeename, '  ',  ''));
UPDATE import.employees SET employeename = trim(replace(employeename, '  ',  ''));
UPDATE import.employees SET employeename = trim(replace(employeename, ',',  ''));
UPDATE import.employees SET employeename = trim(replace(employeename, ',',  ''));

UPDATE import.employees SET employeename = 'Obunga Ernest' WHERE id = 126;
UPDATE import.employees SET employeename = 'Obey Jackie' WHERE id = 289;
UPDATE import.employees SET employeename = 'Musyoki Danson' WHERE id = 629;
UPDATE import.employees SET employeename = 'Kibor David' WHERE id = 798;

DELETE FROM entity_subscriptions WHERE entity_id = 1;
DELETE FROM entitys WHERE entity_id = 1;

INSERT INTO entitys(entity_id, entity_type_id, org_id, entity_name, user_name, function_role)
SELECT employeeid, 1, 0, employeename, accountno, 'staff'
FROM import.employees
ORDER BY employeeid;

INSERT INTO employees(entity_id, department_role_id, bank_branch_id, disability_id, 
	employee_id, pay_scale_id, pay_group_id, location_id, 
	currency_id, org_id, person_title, surname, first_name, middle_name, 
	date_of_birth, gender, phone, nationality,
	identity_card, basic_salary, bank_account, contract_period, 
	active, contract)
SELECT e.employeeid, e.departmentid, COALESCE(b.id, 0), 0, e.accountno, 0, 0, 0, 1, 0, '',
	trim(split_part(employeename, ' ', 1)), trim(split_part(employeename, ' ', 2)),
	trim(split_part(employeename, ' ', 3)),
	birthdate, employeesex, telephone, 'KE', idnumber, basicsalary, bankaccount, 36, 
	iscurrent::boolean, not ispermanent::boolean
FROM import.employees as e LEFT JOIN import.bankbranch as b
	ON (e.bankid = b.bankid) AND (e.branchid = b.branchid);
	
DELETE FROM default_tax_types;

INSERT INTO default_tax_types(entity_id, tax_type_id, org_id, tax_identification)
SELECT employeeid, 1, 0, pin
FROM import.employees
WHERE pin is not null;

INSERT INTO default_tax_types(entity_id, tax_type_id, org_id, tax_identification)
SELECT employeeid, 2, 0, nssf
FROM import.employees
WHERE nssf is not null;

INSERT INTO default_tax_types(entity_id, tax_type_id, org_id, tax_identification)
SELECT employeeid, 3, 0, nhif
FROM import.employees
WHERE nhif is not null;


INSERT INTO employee_month(employee_month_id, entity_id, period_id, bank_branch_id, pay_group_id, 
	department_role_id, currency_id, org_id, exchange_rate, basic_pay)
SELECT employeemonthid, employeeid, monthrateid, COALESCE(b.id, 0), 0,
	departmentid, 1, 0, 1, basicpay
FROM import.employeemonth as e LEFT JOIN import.bankbranch as b
	ON (e.bankid = b.bankid) AND (e.branchid = b.branchid)
ORDER BY employeemonthid;


ALTER TABLE employee_adjustments DISABLE TRIGGER upd_employee_adjustments;

INSERT INTO default_adjustments(entity_id, adjustment_id, org_id, amount)
SELECT employeeid, allowanceid, 0, amount
FROM import.allowdefault;

INSERT INTO employee_adjustments(employee_month_id, adjustment_id, org_id, pay_date, amount, adjustment_type, adjustment_factor)
SELECT employeemonthid, allowanceid, 0, paydate, amount, 1, 1
FROM import.employeeallow;

INSERT INTO employee_adjustments(employee_month_id, adjustment_id, org_id, pay_date, amount, adjustment_type, adjustment_factor)
SELECT a.employeemonthid, 15, 0, b.enddate, a.taxallow, 1, 1
FROM import.employeemonth as a INNER JOIN import.monthrates as b ON a.monthrateid = b.monthrateid
WHERE (a.taxallow > 0)
ORDER BY a.employeemonthid;

INSERT INTO employee_adjustments(employee_month_id, adjustment_id, org_id, pay_date, amount, adjustment_type, adjustment_factor)
SELECT a.employeemonthid, 15, 0, b.enddate, nhifallow, 1, 1
FROM import.employeemonth as a INNER JOIN import.monthrates as b ON a.monthrateid = b.monthrateid
WHERE (nhifallow > 0)
ORDER BY a.employeemonthid;

INSERT INTO default_adjustments(entity_id, adjustment_id, org_id, amount)
SELECT employeeid, 20 + deductionid, 0, amount
FROM import.deductdefault;

INSERT INTO employee_adjustments(employee_month_id, adjustment_id, org_id, pay_date, amount, adjustment_type, adjustment_factor)
SELECT employeemonthid, 20 + deductionid, 0, paydate, amount, 2, -1
FROM import.employeededuct;

ALTER TABLE employee_adjustments ENABLE TRIGGER upd_employee_adjustments;

DELETE FROM employee_tax_types;

INSERT INTO employee_tax_types(employee_month_id, tax_type_id, org_id, amount, exchange_rate, tax_identification)
SELECT a.employeemonthid, 1, 0, a.tax, 1, b.pin
FROM import.employeemonth as a INNER JOIN import.employees  as b ON 
	a.employeeid = b.employeeid
WHERE (a.tax > 0)
ORDER BY a.employeemonthid;

INSERT INTO employee_tax_types(employee_month_id, tax_type_id, org_id, amount, employer, exchange_rate, tax_identification)
SELECT a.employeemonthid, 2, 0, a.nssf, a.nssf, 1, b.nssf
FROM import.employeemonth as a INNER JOIN import.employees  as b ON 
	a.employeeid = b.employeeid
WHERE (a.nssf > 0) AND (a.isnssf = 'Yes')
ORDER BY a.employeemonthid;

INSERT INTO employee_tax_types(employee_month_id, tax_type_id, org_id, amount, exchange_rate, tax_identification)
SELECT a.employeemonthid, 3, 0, a.nhif, 1, b.nhif
FROM import.employeemonth as a INNER JOIN import.employees  as b ON 
	a.employeeid = b.employeeid
WHERE (a.nhif > 0) AND (a.isnhif = 'Yes')
ORDER BY a.employeemonthid;


