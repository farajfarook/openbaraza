

ALTER TABLE default_banking ADD bank_account varchar(64);

DROP VIEW vw_employee_banking;
DROP TABLE employee_banking;
CREATE TABLE employee_banking (
	employee_banking_id		serial primary key,
	employee_month_id		integer references employee_month not null,
	bank_branch_id			integer references bank_branch,
	currency_id				integer references currency,
	org_id					integer references orgs,
	
	amount					float default 0 not null,
	exchange_rate			real default 1 not null,
	active					boolean default true,
	
	bank_account			varchar(64),

	Narrative				varchar(240)
);
CREATE INDEX employee_banking_employee_month_id ON employee_banking (employee_month_id);
CREATE INDEX employee_banking_bank_branch_id ON employee_banking (bank_branch_id);
CREATE INDEX employee_banking_currency_id ON employee_banking (currency_id);
CREATE INDEX employee_banking_org_id ON employee_banking(org_id);

CREATE VIEW vw_employee_banking AS
	SELECT eml.employee_month_id, eml.period_id, eml.start_date, 
		eml.month_id, eml.period_year, eml.period_month,
		eml.entity_id, eml.entity_name, eml.employee_id,
		vw_bank_branch.bank_id, vw_bank_branch.bank_name, vw_bank_branch.bank_branch_id, 
		vw_bank_branch.bank_branch_name, vw_bank_branch.bank_branch_code,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		
		employee_banking.org_id, employee_banking.employee_banking_id, employee_banking.amount, 
		employee_banking.exchange_rate, employee_banking.active, employee_banking.narrative,
		(employee_banking.exchange_rate * employee_banking.amount) as base_amount
	FROM employee_banking INNER JOIN vw_employee_month as eml ON employee_banking.employee_month_id = eml.employee_month_id
		INNER JOIN vw_bank_branch ON employee_banking.bank_branch_id = vw_bank_branch.bank_branch_id
		INNER JOIN currency ON employee_banking.currency_id = currency.currency_id;

DROP VIEW vw_reporting;
CREATE VIEW vw_reporting AS
	SELECT entitys.entity_id, entitys.entity_name, rpt.entity_id as rpt_id, rpt.entity_name as rpt_name, 
		reporting.org_id, reporting.reporting_id, reporting.date_from, 
		reporting.date_to, reporting.primary_report, reporting.is_active, reporting.ps_reporting, 
		reporting.reporting_level, reporting.details
	FROM reporting INNER JOIN entitys ON reporting.entity_id = entitys.entity_id
		INNER JOIN entitys as rpt ON reporting.report_to_id = rpt.entity_id;
		
CREATE VIEW vw_review_reporting AS
	SELECT entitys.entity_id, entitys.entity_name, rpt.entity_id as rpt_id, rpt.entity_name as rpt_name, 
		reporting.reporting_id, reporting.date_from, 
		reporting.date_to, reporting.primary_report, reporting.is_active, reporting.ps_reporting, 
		reporting.reporting_level, 
		job_reviews.job_review_id, job_reviews.total_points, 
		job_reviews.org_id, job_reviews.review_date, job_reviews.review_done, 
		job_reviews.approve_status, job_reviews.workflow_table_id, job_reviews.application_date, job_reviews.action_date,
		job_reviews.recomendation, job_reviews.reviewer_comments, job_reviews.pl_comments,
		EXTRACT(YEAR FROM job_reviews.review_date) as review_year
	FROM reporting INNER JOIN entitys ON reporting.entity_id = entitys.entity_id
		INNER JOIN entitys as rpt ON reporting.report_to_id = rpt.entity_id
		INNER JOIN job_reviews ON reporting.entity_id = job_reviews.entity_id;
		
ALTER TABLE pay_scales ADD 	currency_id				integer references currency;
CREATE INDEX pay_scales_currency_id ON pay_scales(currency_id);
UPDATE pay_scales SET currency_id = 1;

CREATE TABLE vw_pay_scales AS
	SELECT currency.currency_id, currency.currency_name, currency.currency_symbol,
		pay_scales.org_id, pay_scales.pay_scale_id, pay_scales.pay_scale_name,
		pay_scales.min_pay, pay_scales.max_pay, pay_scales.details
	FROM pay_scales INNER JOIN currency ON pay_scales.currency_id = currency.currency_id;



CREATE TABLE pay_scale_steps (
	pay_scale_step_id		serial primary key,
	pay_scale_id			integer references pay_scales,
	org_id					integer references orgs,
	pay_step				integer not null,
	pay_amount				real not null
);
CREATE INDEX pay_scale_steps_pay_scale_id ON pay_scale_steps(pay_scale_id);
CREATE INDEX pay_scale_steps_org_id ON pay_scale_steps(org_id);


CREATE VIEW vw_pay_scale_steps AS
	SELECT currency.currency_id, currency.currency_name, currency.currency_symbol,
		pay_scales.pay_scale_id, pay_scales.pay_scale_name, 
		pay_scale_steps.org_id, pay_scale_steps.pay_scale_step_id, pay_scale_steps.pay_step, 
		pay_scale_steps.pay_amount,
		(pay_scales.pay_scale_name || '-' || currency.currency_symbol || '-' || pay_scale_steps.pay_step) as pay_step_name
	FROM pay_scale_steps INNER JOIN pay_scales ON pay_scale_steps.pay_scale_id = pay_scales.pay_scale_id
		INNER JOIN currency ON pay_scales.currency_id = currency.currency_id;
		
ALTER TABLE employees ADD pay_scale_step_id		integer references pay_scale_steps;
CREATE INDEX employees_pay_scale_step_id ON employees (pay_scale_step_id);


INSERT INTO pay_scale_steps (pay_scale_id, org_id, pay_step, pay_amount)
SELECT pay_scale_id, org_id, pay_year, pay_amount
FROM pay_scale_years
ORDER BY pay_scale_id, pay_year;


ALTER TABLE job_reviews ADD		self_rating				integer;
ALTER TABLE job_reviews ADD		supervisor_rating		integer;

ALTER TABLE contract_types ADD contract_text			text;

DROP VIEW vw_contracting;
CREATE VIEW vw_contracting AS
	SELECT vw_intake.department_id, vw_intake.department_name, vw_intake.department_description, vw_intake.department_duties,
		vw_intake.department_role_id, vw_intake.department_role_name, vw_intake.job_description, 
		vw_intake.job_requirements, vw_intake.duties, vw_intake.performance_measures, 
		vw_intake.intake_id, vw_intake.opening_date, vw_intake.closing_date, vw_intake.positions, 
		entitys.entity_id, entitys.entity_name, 
		
		contract_types.contract_type_id, contract_types.contract_type_name, contract_types.contract_text,
		contract_status.contract_status_id, contract_status.contract_status_name,
		
		applications.application_id, applications.employee_id, applications.contract_date, applications.contract_close, 
		applications.contract_start, applications.contract_period, applications.contract_terms, applications.initial_salary, 
		applications.application_date, applications.approve_status, applications.workflow_table_id, applications.action_date, 
		applications.applicant_comments, applications.review, applications.org_id,

		vw_education_max.education_class_name, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken, 
		vw_education_max.grades_obtained, vw_education_max.certificate_number,

		vw_employment_max.employment_id, vw_employment_max.employers_name, vw_employment_max.position_held,
		vw_employment_max.date_from as emp_date_from, vw_employment_max.date_to as emp_date_to, 
		
		vw_employment_max.employment_duration, vw_employment_max.employment_experince,
		round((date_part('year', vw_employment_max.employment_duration) + date_part('month', vw_employment_max.employment_duration)/12)::numeric, 1) as emp_duration,
		round((date_part('year', vw_employment_max.employment_experince) + date_part('month', vw_employment_max.employment_experince)/12)::numeric, 1) as emp_experince

	FROM applications INNER JOIN entitys ON applications.employee_id = entitys.entity_id
		LEFT JOIN vw_intake ON applications.intake_id = vw_intake.intake_id
		LEFT JOIN contract_types ON applications.contract_type_id = contract_types.contract_type_id
		LEFT JOIN contract_status ON applications.contract_status_id = contract_status.contract_status_id
		LEFT JOIN vw_education_max ON entitys.entity_id = vw_education_max.entity_id
		LEFT JOIN vw_employment_max ON entitys.entity_id = vw_employment_max.entity_id;

CREATE OR REPLACE FUNCTION increment_payroll(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_entity_id		integer;
	v_pay_step_id	integer;
	v_pay_step		integer;
	v_next_step_id	integer;
	v_pay_scale_id	integer;
	v_currency_id	integer;
	v_pay_amount	real;
	msg 			varchar(120);
BEGIN

	v_entity_id := CAST($1 as int);
	
	IF ($3 = '1') THEN
		SELECT pay_scale_steps.pay_scale_step_id, pay_scale_steps.pay_amount, pay_scales.currency_id
			INTO v_pay_step_id, v_pay_amount, v_currency_id
		FROM employees INNER JOIN pay_scale_steps ON employees.pay_scale_step_id = pay_scale_steps.pay_scale_step_id
			INNER JOIN pay_scales ON pay_scale_steps.pay_scale_id = pay_scales.pay_scale_id
		WHERE employees.entity_id = v_entity_id;
		
		IF((v_pay_amount is not null) AND (v_currency_id is not null))THEN
			UPDATE employees SET basic_salary = v_pay_amount, currency_id = v_currency_id
			WHERE entity_id = v_entity_id;
		END IF;

		msg := 'Updated the pay';
	ELSIF ($3 = '2') THEN
		SELECT pay_scale_steps.pay_scale_step_id, pay_scale_steps.pay_scale_id, pay_scale_steps.pay_step
			INTO v_pay_step_id, v_pay_scale_id, v_pay_step
		FROM employees INNER JOIN pay_scale_steps ON employees.pay_scale_step_id = pay_scale_steps.pay_scale_step_id
		WHERE employees.entity_id = v_entity_id;
		
		SELECT pay_scale_steps.pay_scale_step_id INTO v_next_step_id
		FROM pay_scale_steps
		WHERE (pay_scale_steps.pay_scale_id = v_pay_scale_id) AND (pay_scale_steps.pay_step = v_pay_step + 1);
		
		IF(v_next_step_id is not null)THEN
			UPDATE employees SET pay_scale_step_id = v_next_step_id
			WHERE entity_id = v_entity_id;
		END IF;

		msg := 'Pay step incremented';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;


ALTER TABLE objectives ADD objective_maditory		boolean default false not null;


CREATE OR REPLACE FUNCTION insa_employee_objectives() RETURNS trigger AS $$
BEGIN

	INSERT INTO objectives (employee_objective_id, org_id, objective_type_id,
		date_set, objective_ps, objective_name, objective_maditory)
	VALUES (NEW.employee_objective_id, NEW.org_id, 1,
		current_date, 0, 'Community service', true);

	RETURN null;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insa_employee_objectives AFTER INSERT ON employee_objectives
    FOR EACH ROW EXECUTE PROCEDURE insa_employee_objectives();
    
    
    
