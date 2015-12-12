UPDATE tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 1)';
UPDATE tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 2)' WHERE tax_type_id = 1;
UPDATE tax_types SET formural = 'Get_Employee_Tax(employee_tax_type_id, 2)' WHERE tax_type_id = 4;

UPDATE period_tax_types SET formural = tax_types.formural FROM tax_types
WHERE period_tax_types.tax_type_id = tax_types.tax_type_id;

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

		EXECUTE 'SELECT ' || reca.Formural || ' FROM employee_tax_types WHERE employee_tax_type_id = ' || reca.employee_tax_type_id 
		INTO tax;

		UPDATE employee_tax_types SET amount = tax, employer = reca.employer + (tax * reca.employer_ps / 100)
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

