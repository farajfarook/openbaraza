CREATE OR REPLACE FUNCTION generate_payroll(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_period_id		integer;
	v_org_id		integer;

	msg 			varchar(120);
BEGIN
	SELECT period_id, org_id INTO v_period_id, v_org_id
	FROM periods
	WHERE (period_id = CAST($1 as integer));

	INSERT INTO period_tax_types (org_id, period_id, tax_type_id, period_tax_type_name, formural, tax_relief, percentage, linear, employer, employer_ps, tax_type_order, in_tax, account_id)
	SELECT v_org_id, v_period_id, tax_type_id, tax_type_name, formural, tax_relief, percentage, linear, employer, employer_ps, tax_type_order, in_tax, account_id
	FROM Tax_Types
	WHERE (active = true);

	INSERT INTO employee_month (org_id, period_id, pay_group_id, entity_id, bank_branch_id, department_role_id, bank_account, basic_pay)
	SELECT v_org_id, v_period_id, pay_group_id, entity_id, bank_branch_id, department_role_id, bank_account, basic_salary
	FROM employees
	WHERE (employees.active = true) and (employees.org_id = v_org_id);

	INSERT INTO project_staff_costs (org_id, period_id, pay_group_id, entity_id, bank_branch_id, bank_account, 
		project_id, staff_cost, tax_cost)
	SELECT v_org_id, v_period_id, employees.pay_group_id, employees.entity_id, employees.bank_branch_id, employees.bank_account,
		project_staff.project_id, project_staff.staff_cost, project_staff.tax_cost
	FROM employees INNER JOIN project_staff ON employees.entity_id = project_staff.entity_id
	WHERE (project_staff.monthly_cost = true);

	INSERT INTO loan_monthly (org_id, period_id, loan_id, repayment, interest_amount, interest_paid)
	SELECT v_org_id, v_Period_ID, loan_id, monthly_repayment, (loan_balance * interest / 1200), (loan_balance * interest / 1200)
	FROM vw_loans WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  true);

	INSERT INTO loan_monthly (org_id, period_id, loan_id, repayment, interest_amount, interest_paid)
	SELECT v_org_id, v_period_id, loan_id, monthly_repayment, (principle * interest / 1200), 0
	FROM vw_loans WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  false);

	PERFORM updTax(employee_month_id, Period_id)
	FROM employee_month
	WHERE (period_id = v_period_id);

	msg := 'Payroll Generated';

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

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

		EXECUTE 'SELECT ' || reca.Formural || ' FROM Employee_Month WHERE Employee_Month_ID = ' || $1 
		INTO income;

		tax := getTax(income, $2, reca.Tax_Type_ID) - getAdjustment($1, 4, 25);

		UPDATE employee_tax_types SET amount = tax,
			employer = reca.employer + (tax * reca.employer_ps / 100)
		WHERE employee_tax_type_id = reca.employee_tax_type_id;
	END LOOP;

	RETURN tax;
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

CREATE TRIGGER ins_Employee_Adjustments BEFORE INSERT OR UPDATE ON Employee_Adjustments
    FOR EACH ROW EXECUTE PROCEDURE ins_Employee_Adjustments();

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

CREATE TRIGGER upd_employee_adjustments AFTER INSERT OR UPDATE ON employee_adjustments
    FOR EACH ROW EXECUTE PROCEDURE upd_employee_adjustments();

UPDATE employee_adjustments SET narrative =  'Done';

