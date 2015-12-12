ALTER TABLE entity_types ADD start_view varchar(120);
ALTER TABLE entitys ADD no_org boolean default true not null;

DELETE FROM sys_logins;
UPDATE employees SET bank_branch_id = 0 WHERE bank_branch_id is null;

UPDATE employee_leave SET leave_days = 0 WHERE leave_days is null;

CREATE OR REPLACE FUNCTION get_phase_status(boolean, boolean) RETURNS varchar(32) AS $$
DECLARE
	ps		varchar(32);
BEGIN
	ps := 'Draft';
	IF ($1 = true) THEN
		ps := 'Approved';
	END IF;
	IF ($2 = true) THEN
		ps := 'Rejected';
	END IF;

	return ps;
END;
$$ LANGUAGE plpgsql;

DELETE FROM default_adjustments WHERE entity_id is null;

DELETE FROM employee_adjustments WHERE (employee_month_id IN (SELECT employee_month_id FROM employee_month WHERE entity_id is null));

DELETE FROM employee_tax_types WHERE (employee_month_id IN (SELECT employee_month_id FROM employee_month WHERE entity_id is null));

DELETE FROM employee_month WHERE bank_branch_id is null;
DELETE FROM employee_month WHERE entity_id is null;

