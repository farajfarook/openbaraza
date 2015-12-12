

CREATE OR REPLACE FUNCTION upd_employee_month() RETURNS trigger AS $$
BEGIN
	INSERT INTO employee_tax_types (org_id, employee_month_id, tax_type_id, tax_identification, additional, amount, employer, in_tax, exchange_rate)
	SELECT NEW.org_id, NEW.employee_month_id, default_tax_types.tax_type_id, default_tax_types.tax_identification, 
		Default_Tax_Types.Additional, 0, 0, Tax_Types.In_Tax,
		(CASE WHEN Tax_Types.currency_id = NEW.currency_id THEN 1 ELSE 1 / NEW.exchange_rate END)
	FROM Default_Tax_Types INNER JOIN Tax_Types ON Default_Tax_Types.Tax_Type_id = Tax_Types.Tax_Type_id
	WHERE (Default_Tax_Types.active = true) AND (Default_Tax_Types.entity_ID = NEW.entity_ID);

	INSERT INTO employee_adjustments (org_id, employee_month_id, adjustment_id, amount, adjustment_type, in_payroll, in_tax, visible, adjustment_factor, 
		balance, tax_relief_amount, exchange_rate, narrative)
	SELECT NEW.org_id, NEW.employee_month_id, default_adjustments.adjustment_id, default_adjustments.amount,
		adjustments.adjustment_type, adjustments.in_payroll, adjustments.in_tax, adjustments.visible,
		(CASE WHEN adjustments.adjustment_type = 2 THEN -1 ELSE 1 END),
		(CASE WHEN (adjustments.running_balance = true) AND (adjustments.reduce_balance = false) THEN (default_adjustments.balance + default_adjustments.amount)
			WHEN (adjustments.running_balance = true) AND (adjustments.reduce_balance = true) THEN (default_adjustments.balance - default_adjustments.amount) END),
		(default_adjustments.amount * adjustments.tax_relief_ps / 100),
		(CASE WHEN adjustments.currency_id = NEW.currency_id THEN 1 ELSE 1 / NEW.exchange_rate END),
		narrative
	FROM default_adjustments INNER JOIN adjustments ON default_adjustments.adjustment_id = adjustments.adjustment_id
	WHERE ((default_adjustments.final_date is null) OR (default_adjustments.final_date > current_date))
		AND (default_adjustments.active = true) AND (default_adjustments.entity_id = NEW.entity_id);

	INSERT INTO advance_deductions (org_id, amount, employee_month_id)
	SELECT NEW.org_id, (Amount / Pay_Period), NEW.Employee_Month_ID
	FROM Employee_Advances INNER JOIN Employee_Month ON Employee_Advances.Employee_Month_ID = Employee_Month.Employee_Month_ID
	WHERE (entity_ID = NEW.entity_ID) AND (Pay_Period > 0) AND (completed = false)
		AND (Pay_upto >= current_date);
		
	INSERT INTO project_staff_costs (employee_month_id, org_id, project_id, project_role, payroll_ps, staff_cost, tax_cost)
	SELECT NEW.org_id, NEW.employee_month_id, 
		project_staff.project_id, project_staff.project_role, project_staff.payroll_ps, project_staff.staff_cost, project_staff.tax_cost
	FROM project_staff
	WHERE (project_staff.entity_id = NEW.entity_id) AND (project_staff.monthly_cost = true);
	
	INSERT INTO employee_banking (org_id, employee_month_id, bank_branch_id, currency_id, 
		bank_account, amount, 
		exchange_rate)
	SELECT NEW.org_id, NEW.employee_month_id, bank_branch_id, currency_id,
		bank_account, amount,
		(CASE WHEN default_banking.currency_id = NEW.currency_id THEN 1 ELSE 1 / NEW.exchange_rate END)
	FROM default_banking 
	WHERE (default_banking.entity_id = NEW.entity_id) AND (default_banking.active = true)
		AND (amount > 0);

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;


DROP VIEW vw_employee_tax_types;
		
CREATE VIEW vw_employee_tax_types AS
	SELECT eml.employee_month_id, eml.period_id, eml.start_date, 
		eml.month_id, eml.period_year, eml.period_month,
		eml.end_date, eml.gl_payroll_account,
		eml.entity_id, eml.entity_name, eml.employee_id, eml.identity_card,
		tax_types.tax_type_id, tax_types.tax_type_name, tax_types.account_id, 
		employee_tax_types.org_id, employee_tax_types.employee_tax_type_id, employee_tax_types.tax_identification, 
		employee_tax_types.amount, 
		employee_tax_types.additional, employee_tax_types.employer, employee_tax_types.narrative,
		currency.currency_id, currency.currency_name, currency.currency_symbol, employee_tax_types.exchange_rate,
		
		(employee_tax_types.exchange_rate * employee_tax_types.amount) as base_amount,
		(employee_tax_types.exchange_rate * employee_tax_types.employer) as base_employer,
		(employee_tax_types.exchange_rate * employee_tax_types.additional) as base_additional
		
	FROM employee_tax_types INNER JOIN vw_employee_month_list as eml ON employee_tax_types.employee_month_id = eml.employee_month_id
		INNER JOIN tax_types ON (employee_tax_types.tax_type_id = Tax_Types.tax_type_id)
		INNER JOIN currency ON tax_types.currency_id = currency.currency_id;		
		
		
		