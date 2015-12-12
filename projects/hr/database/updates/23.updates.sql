
ALTER TABLE period_tax_types ADD use_key	integer default 1;


DROP VIEW vw_period_tax_types;
CREATE VIEW vw_period_tax_types AS
	SELECT vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.overtime_rate,  
		vw_periods.activated, vw_periods.closed, vw_periods.month_id, vw_periods.period_year, vw_periods.period_month,
		vw_periods.quarter, vw_periods.semister,
		tax_types.tax_type_id, tax_types.tax_type_name, period_tax_types.period_tax_type_id, period_tax_types.Period_Tax_Type_Name, tax_types.use_key,
		period_tax_types.org_id, period_tax_types.Pay_Date, period_tax_types.tax_relief, period_tax_types.linear, period_tax_types.percentage, 
		period_tax_types.formural, period_tax_types.details
	FROM period_tax_types INNER JOIN vw_periods ON period_tax_types.period_id = vw_periods.period_id
		INNER JOIN tax_types ON period_tax_types.tax_type_id = tax_types.tax_type_id;


UPDATE tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 2)' WHERE tax_type_id = 1;
UPDATE tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 1)' WHERE tax_type_id = 2;
UPDATE tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 1)' WHERE tax_type_id = 3;
UPDATE tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 2)' WHERE tax_type_id = 4;

UPDATE period_tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 2)' WHERE tax_type_id = 1;
UPDATE period_tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 1)' WHERE tax_type_id = 2;
UPDATE period_tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 1)' WHERE tax_type_id = 3;
UPDATE period_tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 2)' WHERE tax_type_id = 4;


CREATE OR REPLACE FUNCTION getAdjustment(int, int, int) RETURNS float AS $$
DECLARE
	adjustment float;
BEGIN

	IF ($3 = 1) THEN
		SELECT SUM(Amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (adjustment_type = $2);
	ELSIF ($3 = 2) THEN
		SELECT SUM(Amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (adjustment_type = $2) AND (In_payroll = true) AND (Visible = true);
	ELSIF ($3 = 3) THEN
		SELECT SUM(Amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (adjustment_type = $2) AND (In_Tax = true);
	ELSIF ($3 = 4) THEN
		SELECT SUM(Amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (adjustment_type = $2) AND (In_payroll = true);
	ELSIF ($3 = 5) THEN
		SELECT SUM(Amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (adjustment_type = $2) AND (Visible = true);
	ELSIF ($3 = 11) THEN
		SELECT SUM(Amount) INTO adjustment
		FROM Employee_Tax_Types
		WHERE (Employee_Month_ID = $1);
	ELSIF ($3 = 12) THEN
		SELECT SUM(Amount) INTO adjustment
		FROM Employee_Tax_Types
		WHERE (Employee_Month_ID = $1) AND (In_Tax = true);
	ELSIF ($3 = 14) THEN
		SELECT SUM(Amount) INTO adjustment
		FROM Employee_Tax_Types
		WHERE (Employee_Month_ID = $1) AND (Tax_Type_ID = $2);
	ELSIF ($3 = 21) THEN
		SELECT SUM(Amount * adjustment_factor) INTO adjustment
		FROM employee_adjustments
		WHERE (employee_month_id = $1) AND (in_tax = true);
	ELSIF ($3 = 22) THEN
		SELECT SUM(Amount * adjustment_factor) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (In_payroll = true) AND (Visible = true);
	ELSIF ($3 = 23) THEN
		SELECT SUM(Amount * adjustment_factor) INTO adjustment
		FROM employee_adjustments
		WHERE (employee_month_id = $1) AND (in_tax = true) AND (adjustment_factor = 1);
	ELSIF ($3 = 24) THEN
		SELECT SUM(tax_reduction_amount) INTO adjustment
		FROM employee_adjustments
		WHERE (employee_month_id = $1) AND (in_tax = true) AND (adjustment_factor = -1);
	ELSIF ($3 = 25) THEN
		SELECT SUM(tax_relief_amount) INTO adjustment
		FROM employee_adjustments
		WHERE (employee_month_id = $1) AND (in_tax = true) AND (adjustment_factor = -1);
	ELSIF ($3 = 31) THEN
		SELECT SUM(OverTime * OverTime_Rate) INTO adjustment
		FROM Employee_Overtime
		WHERE (Employee_Month_ID = $1) AND (approve_status = 'Approved');
	ELSIF ($3 = 32) THEN
		SELECT SUM(tax_amount) INTO adjustment
		FROM Employee_Per_Diem
		WHERE (Employee_Month_ID = $1) AND (approve_status = 'Approved');
	ELSIF ($3 = 33) THEN
		SELECT SUM(full_amount -  Cash_paid) INTO adjustment
		FROM Employee_Per_Diem
		WHERE (Employee_Month_ID = $1) AND (approve_status = 'Approved');
	ELSIF ($3 = 34) THEN
		SELECT SUM(Amount) INTO adjustment
		FROM Employee_Advances
		WHERE (Employee_Month_ID = $1) AND (in_payroll = true);
	ELSIF ($3 = 35) THEN
		SELECT SUM(Amount) INTO adjustment
		FROM Advance_Deductions
		WHERE (Employee_Month_ID = $1) AND (In_payroll = true);
	ELSIF ($3 = 36) THEN
		SELECT SUM(paid_amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (In_payroll = true) AND (Visible = true);
	ELSIF ($3 = 37) THEN
		SELECT SUM(tax_relief_amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1);

		IF(adjustment IS NULL)THEN
			adjustment := 0;
		END IF;
	ELSE
		adjustment := 0;
	END IF;

	IF(adjustment is null) THEN
		adjustment := 0;
	END IF;

	RETURN adjustment;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getAdjustment(int, int) RETURNS float AS $$
DECLARE
	adjustment float;
BEGIN

	IF ($2 = 1) THEN
		SELECT (Basic_Pay + getAdjustment(Employee_Month_ID, 4, 31) + getAdjustment(Employee_Month_ID, 4, 23) 
			+ getAdjustment(Employee_Month_ID, 4, 32)) INTO adjustment
		FROM Employee_Month
		WHERE (Employee_Month_ID = $1);
	ELSIF ($2 = 2) THEN
		SELECT (Basic_Pay + getAdjustment(Employee_Month_ID, 4, 31) + getAdjustment(Employee_Month_ID, 4, 32) 
			+ getAdjustment(Employee_Month_ID, 4, 23)			
			- getAdjustment(Employee_Month_ID, 4, 12) - getAdjustment(Employee_Month_ID, 4, 24)) INTO adjustment
		FROM Employee_Month
		WHERE (Employee_Month_ID = $1);
	ELSE
		adjustment := 0;
	END IF;

	IF(adjustment is null) THEN
		adjustment := 0;
	END IF;

	RETURN adjustment;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getAdvanceBalance(int, date) RETURNS float AS $$
DECLARE
	advance FLOAT;
	paid 	FLOAT;
BEGIN
	SELECT SUM(Amount) INTO advance
	FROM vw_employee_advances
	WHERE (entity_id = $1) AND (start_date <= $2) AND (approve_status = 'Approved');
	IF (advance is null) THEN advance := 0; END IF;
	
	SELECT SUM(Amount) INTO paid
	FROM vw_advance_deductions
	WHERE (entity_id = $1) AND (start_date <= $2);
	IF (paid is null) THEN paid := 0; END IF;

	advance := advance - paid;

	RETURN advance;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION gettax(float, int) RETURNS float AS $$
DECLARE
	reca		RECORD;
	tax			REAL;
BEGIN
	SELECT period_tax_type_id, Formural, tax_relief, percentage, linear, In_Tax, Employer, Employer_PS INTO reca
	FROM period_tax_types
	WHERE (period_tax_type_id = $2);

	IF(reca.linear = true) THEN
		SELECT SUM(CASE WHEN tax_range < $1 
		THEN (tax_rate / 100) * (tax_range - getTaxMin(tax_range, reca.period_tax_type_id)) 
		ELSE (tax_rate / 100) * ($1 - getTaxMin(tax_range, reca.period_tax_type_id)) END) INTO tax
		FROM period_tax_rates 
		WHERE (getTaxMin(tax_range, reca.period_tax_type_id) <= $1) AND (period_tax_type_id = reca.period_tax_type_id);
	ELSIF(reca.linear = false) THEN 
		SELECT max(tax_rate) INTO tax
		FROM period_tax_rates 
		WHERE (getTaxMin(tax_range, reca.period_tax_type_id) < $1) AND (tax_range >= $1) 
			AND (period_tax_type_id = reca.period_tax_type_id);
	END IF;

	IF (tax is null) THEN
		tax := 0;
	END IF;

	IF (tax > reca.tax_relief) THEN
		tax := tax - reca.tax_relief;
	ELSE
		tax := 0;
	END IF;

	RETURN tax;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Get_Employee_Tax(int, int) RETURNS float AS $$
DECLARE
	v_employee_month_id		integer;
	v_period_tax_type_id		integer;
	v_income				float;
	v_tax					float;
BEGIN

	SELECT employee_tax_types.employee_month_id, period_tax_types.period_tax_type_id
		INTO v_employee_month_id, v_period_tax_type_id
	FROM employee_tax_types INNER JOIN employee_month ON employee_tax_types.employee_month_id = employee_month.employee_month_id
		INNER JOIN period_tax_types ON (employee_month.period_id = period_tax_types.period_id)
			AND (employee_tax_types.tax_type_id = period_tax_types.tax_type_id)
	WHERE (employee_tax_types.employee_tax_type_id	= $1);

	IF ($2 = 1) THEN
		v_income := getAdjustment(v_employee_month_id, 1);
		v_tax := getTax(v_income, v_period_tax_type_id);

	ELSIF ($2 = 2) THEN
		v_income := getAdjustment(v_employee_month_id, 2);
		v_tax := getTax(v_income, v_period_tax_type_id) - getAdjustment(v_employee_month_id, 4, 25);

	ELSE
		v_tax := 0;
	END IF;

	IF(v_tax is null) THEN
		v_tax := 0;
	END IF;

	RETURN v_tax;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updtax(int, int) RETURNS float AS $$
DECLARE
	reca 				RECORD;
	income 				REAL;
	tax 				REAL;
	InsuranceRelief 	REAL;
BEGIN

	FOR reca IN SELECT employee_tax_types.employee_tax_type_id, employee_tax_types.tax_type_id, period_tax_types.formural,
			 period_tax_types.employer, period_tax_types.employer_ps
		FROM employee_tax_types INNER JOIN period_tax_types ON (employee_tax_types.tax_type_id = period_tax_types.tax_type_id)
		WHERE (employee_month_id = $1) AND (Period_Tax_Types.Period_ID = $2)
		ORDER BY Period_Tax_Types.Tax_Type_order LOOP

		UPDATE employee_adjustments SET tax_reduction_amount = 0 WHERE (employee_month_id = $1);

		EXECUTE 'SELECT ' || reca.Formural || ' FROM employee_tax_types WHERE employee_tax_type_id = ' || reca.employee_tax_type_id 
		INTO tax;

		UPDATE employee_tax_types SET amount = tax, employer = reca.employer + (tax * reca.employer_ps / 100)
		WHERE employee_tax_type_id = reca.employee_tax_type_id;
	END LOOP;

	RETURN tax;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_payroll(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec 		RECORD;
	msg 		varchar(120);
BEGIN
	IF ($3 = '1') THEN
		PERFORM updTax(employee_month_id, period_id)
		FROM employee_month
		WHERE (period_id = CAST($1 as int));

		msg := 'Payroll Processed';
	ELSIF ($3 = '2') THEN
		UPDATE periods SET entity_id = CAST($2 as int), approve_status = 'Completed'
		WHERE (period_id = CAST($1 as int));

		msg := 'Application for approval';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_employee_adjustments() RETURNS trigger AS $$
DECLARE
	v_tax_relief_ps				float;
	v_tax_reduction_ps			float;
	v_tax_max_allowed			float;
BEGIN
	IF((NEW.Amount = 0) AND (NEW.paid_amount <> 0))THEN
		NEW.Amount = NEW.paid_amount / 0.7;
	END IF;

	IF(NEW.in_tax = true)THEN
		SELECT tax_reduction_ps, tax_relief_ps, tax_max_allowed INTO v_tax_reduction_ps, v_tax_relief_ps, v_tax_max_allowed
		FROM adjustments
		WHERE (adjustments.adjustment_id = NEW.adjustment_id);

		IF(v_tax_reduction_ps is null)THEN
			NEW.tax_reduction_amount := 0;
		ELSE
			NEW.tax_reduction_amount := NEW.amount * v_tax_reduction_ps / 100;
		END IF;

		IF(v_tax_relief_ps is null)THEN
			NEW.tax_relief_amount := 0;
		ELSE
			NEW.tax_relief_amount := NEW.amount * v_tax_relief_ps / 100;
		END IF;

		IF(v_tax_max_allowed is not null)THEN
			IF(NEW.tax_reduction_amount > v_tax_max_allowed)THEN
				NEW.tax_reduction_amount := v_tax_max_allowed;
			END IF;
			IF(NEW.tax_relief_amount > v_tax_max_allowed)THEN
				NEW.tax_relief_amount := v_tax_max_allowed;
			END IF;
		END IF;
	ELSE
		NEW.tax_relief_amount := 0;
		NEW.tax_reduction_amount := 0;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION upd_employee_adjustments() RETURNS trigger AS $$
DECLARE
	rec 		RECORD;
	entityid 	integer;
	periodid 	integer;
BEGIN
	SELECT monthly_update, running_balance INTO rec
	FROM adjustments WHERE adjustment_id = NEW.Adjustment_ID;

	SELECT entity_id, period_id INTO entityid, periodid
	FROM employee_month WHERE employee_month_id = NEW.employee_month_id;

	IF(rec.running_balance = true) AND (NEW.balance is not null)THEN
		UPDATE default_adjustments SET balance = NEW.balance
		WHERE (entity_id = entityid) AND (adjustment_id = NEW.adjustment_id);
	END IF;

	IF(TG_OP = 'UPDATE')THEN
		IF (OLD.amount <> NEW.amount)THEN
			IF(rec.monthly_update = true)THEN
				UPDATE default_adjustments SET amount = NEW.amount 
				WHERE (entity_id = entityid) AND (adjustment_id = NEW.adjustment_id);
			END IF;

			PERFORM updTax(employee_month_id, Period_id)
			FROM employee_month
			WHERE (period_id = periodid);
		END IF;
	ELSE
		PERFORM updTax(employee_month_id, Period_id)
		FROM employee_month
		WHERE (period_id = periodid);
	END IF;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

