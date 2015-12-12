
DELETE FROM adjustments;
DELETE FROM tax_rates;
DELETE FROM tax_types;

INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (1, 1, 'Sacco Allowance', true, true);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (1, 2, 'Bonus', true, true);

INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (2, 11, 'SACCO', true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (2, 12, 'HELB', true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (2, 13, 'Rent Payment', true, false);

INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 21, 'Travel', true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 22, 'Communcation', true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 23, 'Tools', true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 24, 'Payroll Cost', true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 25, 'Health Insurance', false, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 26, 'GPA Insurance', false, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 27, 'Accomodation', true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 28, 'Avenue Health Care', false, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 29, 'Maternety Cost', true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 30, 'Health care claims', true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 31, 'Trainining', true, false);
INSERT INTO adjustments (adjustment_type, adjustment_id, adjustment_Name, Visible, In_Tax) VALUES (3, 32, 'per diem', true, false);
SELECT pg_catalog.setval('adjustments_adjustment_id_seq', 32, true);
UPDATE adjustments SET org_id = 0, currency_id = 1;

INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 1, 'PAYE', 'Get_Employee_Tax(employee_tax_type_id, 2)', 1162, 1, false, true, true, 0, 0, true, NULL);
INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 2, 'NSSF', 'Get_Employee_Tax(employee_tax_type_id, 1)', 0, 0, true, true, true, 0, 0, true, NULL);
INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 3, 'NHIF', 'Get_Employee_Tax(employee_tax_type_id, 1)', 0, 0, false, false, false, 0, 0, true, NULL);
INSERT INTO tax_types (use_key, tax_type_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, linear, percentage, employer, employer_ps, active, details) VALUES (1, 4, 'FULL PAYE', 'Get_Employee_Tax(employee_tax_type_id, 2)', 0, 0, false, false, false, 0, 0, false, NULL);
SELECT pg_catalog.setval('tax_types_tax_type_id_seq', 4, true);
UPDATE tax_types SET org_id = 0, currency_id = 1;

INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (1, 10164, 10);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (1, 19740, 15);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (1, 29316, 20);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (1, 38892, 25);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (1, 10000000, 30);

INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (2, 4000, 5);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (2, 10000000, 0);

INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 999, 0);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 1499, 30);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 1999, 40);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 2999, 60);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 3999, 80);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 4999, 100);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 5999, 120);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 6999, 140);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 7999, 160);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 8999, 180);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 9999, 200);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 10999, 220);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 11999, 240);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 12999, 260);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 13999, 280);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 14999, 300);
INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (3, 1000000, 320);

INSERT INTO Tax_Rates (Tax_Type_ID, Tax_Range, Tax_Rate) VALUES (4, 10000000, 30);

UPDATE Tax_Rates SET org_id = 0;



