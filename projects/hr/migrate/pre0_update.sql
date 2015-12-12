DELETE FROM sys_logins;
UPDATE employees SET bank_branch_id = 0 WHERE bank_branch_id is null;

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

ALTER TABLE sys_countrys ADD sys_currency_code varchar(32);
ALTER TABLE sys_countrys ADD sys_currency_name varchar(32);
ALTER TABLE sys_countrys ADD sys_currency_cents varchar(32);
ALTER TABLE sys_countrys ADD sys_currency_exchange real default 1;
ALTER TABLE address ADD first_password varchar(32);
ALTER TABLE phases ADD entity_type_id integer;
ALTER TABLE entity_types ADD use_key integer;
ALTER TABLE adjustments ADD earning_code integer;
ALTER TABLE default_adjustments ADD balance real default 0;
ALTER TABLE employees ADD pay_scale_id integer;
ALTER TABLE employees ADD current_appointment		date;
ALTER TABLE employees ADD desg_code				varchar(16);
ALTER TABLE employees ADD inc_mth					varchar(16);
ALTER TABLE employees ADD previous_sal_point		varchar(16);
ALTER TABLE employees ADD current_sal_point		varchar(16);
ALTER TABLE employees ADD halt_point				varchar(16);
ALTER TABLE employee_adjustments ADD paid_amount real default 0;
ALTER TABLE employee_adjustments ADD balance real default 0;
ALTER TABLE employee_per_diem ADD post_account varchar(32);


