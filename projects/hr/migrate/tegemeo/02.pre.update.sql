

DELETE FROM items;
DELETE FROM item_category;
DELETE FROM item_units;
DELETE FROM period_tax_rates;
DELETE FROM tax_rates;
DELETE FROM period_tax_types;
DELETE FROM tax_types;
DELETE FROM periods;
DELETE FROM fiscal_years;
DELETE FROM department_roles;
DELETE FROM departments;
DELETE FROM bank_accounts;
DELETE FROM bank_branch;
DELETE FROM banks;
DELETE FROM sys_emails;
DELETE FROM workflow_phases;
DELETE FROM workflows;
DELETE FROM sys_logins;
DELETE FROM currency_rates;
DELETE FROM address;
DELETE FROM entity_subscriptions;
DELETE FROM entitys;
DELETE FROM entity_types;
DELETE FROM subscription_levels;
DELETE FROM shifts;

DELETE FROM default_accounts;
DELETE FROM accounts;
DELETE FROM account_types;
DELETE FROM accounts_class;

DELETE FROM orgs;
DELETE FROM sys_countrys;
DELETE FROM sys_continents;


DROP TRIGGER ins_taxes ON employees;
DROP TRIGGER ins_bf_periods ON periods;
DROP TRIGGER ins_periods ON periods;
DROP TRIGGER ins_period_tax_types ON period_tax_types;
DROP TRIGGER ins_employee_month ON Employee_Month;
DROP TRIGGER ins_applicants ON applicants;
DROP TRIGGER ins_entitys ON entitys;


