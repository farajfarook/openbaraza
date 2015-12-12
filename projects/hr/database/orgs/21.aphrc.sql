
CREATE OR REPLACE FUNCTION get_leave_balance(integer, integer) RETURNS real AS $$
DECLARE
	reca					RECORD;
	v_months				integer;
	v_leave_starting		date;
	v_leave_carryover		real;
	v_leave_balance			real;
	v_leave_days			real;
	v_leave_work_days		real;
	v_leave_initial			real;
	v_year_leave			real;
BEGIN

	SELECT allowed_leave_days, month_quota, initial_days, maximum_carry 
		INTO reca
	FROM leave_types
	WHERE (leave_type_id = $2);

	SELECT leave_balance, leave_starting INTO v_leave_carryover, v_leave_starting
	FROM employee_leave_types
	WHERE (entity_id = $1) AND (leave_type_id = $2);
	IF(v_leave_carryover is null) THEN v_leave_carryover := 0; END IF;
	IF(v_leave_carryover > reca.maximum_carry) THEN v_leave_carryover := reca.maximum_carry; END IF;
	IF(v_leave_starting is null) THEN v_leave_starting := current_date; END IF;

	v_months := EXTRACT(MONTH FROM CURRENT_TIMESTAMP) - 1;
	v_leave_balance := reca.initial_days + reca.month_quota * v_months;
	if(reca.month_quota = 0)THEN v_leave_balance := reca.allowed_leave_days; END IF;

	IF(reca.maximum_carry = 0)THEN
		SELECT sum(employee_leave.leave_days) INTO v_leave_days
		FROM employee_leave 
		WHERE (entity_id = $1) AND (leave_type_id = $2)
			AND (approve_status <> 'Rejected') AND (approve_status <> 'Draft')
			AND (EXTRACT(YEAR FROM leave_from) = EXTRACT(YEAR FROM now()));
		IF(v_leave_days is null) THEN v_leave_days := 0; END IF;

		SELECT SUM(CASE WHEN leave_work_days.half_day = true THEN 0.5 ELSE 1 END) INTO v_leave_work_days
		FROM leave_work_days INNER JOIN employee_leave ON leave_work_days.employee_leave_id = employee_leave.employee_leave_id
		WHERE (employee_leave.entity_id = $1) AND (employee_leave.leave_type_id = $2)
			AND (leave_work_days.approve_status = 'Approved')
			AND (EXTRACT(YEAR FROM employee_leave.leave_from) = EXTRACT(YEAR FROM now()));
		IF(v_leave_work_days is null) THEN v_leave_work_days := 0; END IF;
		v_leave_days := v_leave_days - v_leave_work_days;

		IF(v_leave_balance > reca.allowed_leave_days) THEN v_leave_balance := reca.allowed_leave_days; END IF;
		v_leave_balance := v_leave_balance - v_leave_days;
	ELSE
		SELECT sum(employee_leave.leave_days) INTO v_leave_days
		FROM employee_leave 
		WHERE (entity_id = $1) AND (leave_type_id = $2)
			AND (approve_status <> 'Rejected') AND (approve_status <> 'Draft');
		IF(v_leave_days is null) THEN v_leave_days := 0; END IF;
		
		SELECT sum(employee_leave.leave_days) INTO v_year_leave
		FROM employee_leave 
		WHERE (entity_id = $1) AND (leave_type_id = $2)
			AND (approve_status <> 'Rejected') AND (approve_status <> 'Draft')
			AND (EXTRACT(YEAR FROM leave_from) = EXTRACT(YEAR FROM now()));
		IF(v_year_leave is null) THEN v_year_leave := 0; END IF;

		SELECT SUM(CASE WHEN leave_work_days.half_day = true THEN 0.5 ELSE 1 END) INTO v_leave_work_days
		FROM leave_work_days INNER JOIN employee_leave ON leave_work_days.employee_leave_id = employee_leave.employee_leave_id
		WHERE (employee_leave.entity_id = $1) AND (employee_leave.leave_type_id = $2)
			AND (leave_work_days.approve_status = 'Approved');
		IF(v_leave_work_days is null) THEN v_leave_work_days := 0; END IF;
		v_leave_days := v_leave_days - v_leave_work_days;
		
		v_leave_initial := v_leave_carryover + (EXTRACT(YEAR FROM now()) - EXTRACT(YEAR FROM v_leave_starting)) * reca.allowed_leave_days;
		IF(EXTRACT(MONTH FROM v_leave_starting) > 1)THEN
			v_leave_initial := v_leave_carryover + (EXTRACT(YEAR FROM now()) - EXTRACT(YEAR FROM v_leave_starting) - 1) * reca.allowed_leave_days;
			IF(reca.month_quota = 0)THEN v_leave_initial := v_leave_initial + (13 - EXTRACT(MONTH FROM v_leave_starting)) * reca.month_quota;
			ELSE v_leave_initial := v_leave_initial + reca.allowed_leave_days;
			END IF;
		END IF;
		v_leave_initial := v_leave_initial - (v_leave_days - v_year_leave);
		IF(v_leave_initial > reca.maximum_carry) THEN v_leave_initial := reca.maximum_carry; END IF;		
		v_leave_balance := v_leave_initial + v_leave_balance - v_year_leave;
	END IF;

	RETURN v_leave_balance;
END;
$$ LANGUAGE plpgsql;


