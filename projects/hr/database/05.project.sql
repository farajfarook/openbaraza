
ALTER TABLE entitys ADD	bio_code		varchar(50);

CREATE TABLE project_types (
    project_type_id			serial primary key,
	org_id					integer references orgs,
    project_type_name		varchar(50) not null unique,
    details					text
);
CREATE INDEX project_types_org_id ON project_types(org_id);

CREATE TABLE define_phases (
	define_phase_id			serial primary key,
	project_type_id			integer references project_types,
	entity_type_id			integer references entity_types,
	org_id					integer references orgs,
	define_phase_name		varchar(240),
	define_phase_time		real default 0 not null,
	define_phase_cost		real default 0 not null,
	phase_order				integer default 0 not null,
	details					text
);
CREATE INDEX define_phases_project_type_id ON define_phases (project_type_id);
CREATE INDEX define_phases_entity_type_id ON define_phases (entity_type_id);
CREATE INDEX define_phases_org_id ON define_phases(org_id);

CREATE TABLE define_tasks (
    define_task_id			serial primary key,
    define_phase_id			integer references define_phases,
	org_id					integer references orgs,
    define_task_name		varchar(240) not null,
    narrative				varchar(120),
    details					text
);
CREATE INDEX define_tasks_define_phase_id ON define_tasks (define_phase_id);
CREATE INDEX define_tasks_org_id ON define_tasks(org_id);

CREATE TABLE projects (
    project_id				serial primary key,
    project_type_id			integer references project_types,
	entity_id				integer references entitys,
	org_id					integer references orgs,
    project_name			varchar(240) not null,
    signed					boolean not null default false,
	contract_ref			varchar(120),
    monthly_amount 			real,
    full_amount 			real,
	project_cost			real,
    narrative				varchar(120),
	project_account			varchar(32),
    start_date				date not null,
    ending_date				date,
    details					text,
    UNIQUE(entity_id, project_name)
);
CREATE INDEX projects_project_type_id ON projects (project_type_id);
CREATE INDEX projects_entity_id ON projects (entity_id);
CREATE INDEX projects_org_id ON projects(org_id);

CREATE TABLE project_staff (
	project_staff_id		serial primary key,
	project_id				integer references projects,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	project_role			varchar(240),
	monthly_cost			boolean default true not null,
	is_active				boolean default true not null,
	payroll_ps				real default 0 not null,
	staff_cost				real default 0 not null,
	tax_cost				real default 0 not null,
	details					text,
	UNIQUE(project_id, entity_id)
);
CREATE INDEX project_staff_project_id ON project_staff (project_id);
CREATE INDEX project_staff_entity_id ON project_staff (entity_id);
CREATE INDEX project_staff_org_id ON project_staff(org_id);

CREATE TABLE project_staff_costs (
	project_staff_cost_id	serial primary key,
	project_id				integer references projects not null,
	employee_month_id		integer references employee_month not null,
	org_id					integer references orgs,
	project_role			varchar(240),
	payroll_ps				real default 0 not null,
	staff_cost				real default 0 not null,
	tax_cost				real default 0 not null,
	Details					text
);
CREATE INDEX project_staff_costs_project_id ON project_staff_costs (project_id);
CREATE INDEX project_staff_costs_employee_month_id ON project_staff_costs (employee_month_id);
CREATE INDEX project_staff_costs_org_id ON project_staff_costs(org_id);

CREATE TABLE phases (
	phase_id				serial primary key,
	project_id				integer references projects,
	org_id					integer references orgs,
	phase_name				varchar(240),
	start_date				date not null,
	end_date				date,
	completed				boolean not null default false,
	phase_cost				real default 0 not null,
	details					text
);
CREATE INDEX phases_project_id ON phases (project_id);
CREATE INDEX phases_org_id ON phases(org_id);

CREATE TABLE tasks (
    task_id					serial primary key,
    phase_id				integer references phases,
	entity_id				integer references entitys,
	org_id					integer references orgs,
    task_name				varchar(320) not null,
	start_date				date not null,
    dead_line				date,
	end_date				date,
	hours_taken				integer default 7 not null,
	completed				boolean not null default false,
    details					text
);
CREATE INDEX tasks_phase_id ON tasks (phase_id);
CREATE INDEX tasks_entity_id ON tasks (entity_id);
CREATE INDEX tasks_org_id ON tasks (org_id);

CREATE TABLE timesheet (
	timesheet_id			serial primary key,
	task_id					integer references tasks,
	org_id					integer references orgs,
	ts_date					date not null,
	ts_start_time			time not null,
	ts_end_time				time not null,
	ts_narrative			varchar(320),
	details					text
);
CREATE INDEX timesheet_task_id ON timesheet(task_id);
CREATE INDEX timesheet_org_id ON timesheet(org_id);

CREATE TABLE project_cost (
	project_cost_id			serial primary key,
	phase_id				integer references phases,
	org_id					integer references orgs,
	project_cost_name		varchar(240),
	amount					real not null default 0,
	cost_date				date not null,
	cost_approved			boolean default false,
	details					text
);
CREATE INDEX project_cost_phase_id ON project_cost (phase_id);
CREATE INDEX project_cost_org_id ON project_cost (org_id);

CREATE TABLE attendance (
	attendance_id			serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	attendance_date			date,
	time_in					time,
	time_out				time,
	details					text
);
CREATE INDEX attendance_entity_id ON attendance (entity_id);
CREATE INDEX attendance_org_id ON attendance (org_id);

CREATE TABLE bio_imports1 (
	bio_imports1_id			serial primary key,
	org_id					integer references orgs,
	col1					varchar(50),
	col2					varchar(50),
	col3					varchar(50),
	col4					varchar(50),
	col5					varchar(50),
	col6					varchar(50),
	col7					varchar(50),
	col8					varchar(50),
	col9					varchar(50),
	col10					varchar(50),
	col11					varchar(50),
	is_picked				boolean default false
);
CREATE INDEX bio_imports1_org_id ON bio_imports1 (org_id);

CREATE VIEW vw_define_phases AS
	SELECT entity_types.entity_type_id, entity_types.entity_type_name, project_types.project_type_id,
		project_types.project_type_name, define_phases.define_phase_id, define_phases.define_phase_name,
		define_phases.org_id, define_phases.define_phase_time, define_phases.define_phase_cost, define_phases.phase_order, 
		define_phases.details
	FROM define_phases INNER JOIN entity_types ON define_phases.entity_type_id = entity_types.entity_type_id
		INNER JOIN project_types ON define_phases.project_type_id = project_types.project_type_id;

CREATE VIEW vw_define_tasks AS
	SELECT vw_define_phases.entity_type_id, vw_define_phases.entity_type_name, vw_define_phases.project_type_id,
    	vw_define_phases.project_type_name, vw_define_phases.define_phase_id, vw_define_phases.define_phase_name,
		vw_define_phases.define_phase_time, vw_define_phases.define_phase_cost,
		define_tasks.org_id, define_tasks.define_task_id, define_tasks.define_task_name, define_tasks.narrative, define_tasks.details
	FROM define_tasks INNER JOIN vw_define_phases ON define_tasks.define_phase_id = vw_define_phases.define_phase_id;

CREATE VIEW vw_projects AS
	SELECT entitys.entity_id as client_id, entitys.entity_name as client_name, 
		project_types.project_type_id, project_types.project_type_name, 
		projects.org_id, projects.project_id, projects.project_name, projects.signed, projects.contract_ref, projects.monthly_amount,
		projects.full_amount, projects.project_cost, projects.narrative, projects.start_date, projects.ending_date,
		projects.project_account, projects.details
	FROM projects INNER JOIN entitys ON projects.entity_id = entitys.entity_id
		INNER JOIN project_types ON projects.project_type_id = project_types.project_type_id;

CREATE VIEW vw_project_staff AS
	SELECT vw_projects.client_id, vw_projects.client_name, vw_projects.project_type_id, vw_projects.project_type_name, 
		vw_projects.project_id, vw_projects.project_name, vw_projects.signed, vw_projects.contract_ref, 
		vw_projects.monthly_amount, vw_projects.full_amount, vw_projects.project_cost, vw_projects.narrative, 
		vw_projects.project_account, vw_projects.start_date, vw_projects.ending_date,
		entitys.entity_id as staff_id, entitys.entity_name as staff_name, 
		project_staff.org_id, project_staff.project_staff_id, project_staff.project_role, 
		project_staff.is_active, project_staff.payroll_ps,
		project_staff.monthly_cost, project_staff.staff_cost, project_staff.tax_cost, project_staff.details
	FROM project_staff INNER JOIN entitys ON project_staff.entity_id = entitys.entity_id
		INNER JOIN vw_projects ON project_staff.project_id = vw_projects.project_id;

CREATE VIEW vw_project_staff_costs AS
	SELECT vw_employee_month.employee_month_id, vw_employee_month.period_id, vw_employee_month.start_date, 
		vw_employee_month.month_id, vw_employee_month.period_year, vw_employee_month.period_month,
		vw_employee_month.end_date, vw_employee_month.gl_payroll_account,
		vw_employee_month.entity_id, vw_employee_month.entity_name, vw_employee_month.employee_id,
		projects.project_id, projects.project_name, projects.project_account,
		project_staff_costs.org_id, project_staff_costs.project_staff_cost_id, 
		project_staff_costs.project_role, project_staff_costs.payroll_ps,
		project_staff_costs.staff_cost, project_staff_costs.tax_cost, project_staff_costs.details
	FROM project_staff_costs INNER JOIN vw_employee_month ON project_staff_costs.employee_month_id = vw_employee_month.employee_month_id
		INNER JOIN projects ON project_staff_costs.project_id = projects.project_id;
		
CREATE VIEW vw_project_staff_adjustments AS
	SELECT vw_employee_month.employee_month_id, vw_employee_month.period_id, vw_employee_month.start_date, 
		vw_employee_month.month_id, vw_employee_month.period_year, vw_employee_month.period_month,
		vw_employee_month.end_date, 
		vw_employee_month.entity_id, vw_employee_month.entity_name, vw_employee_month.employee_id,
		adjustments.adjustment_id, adjustments.adjustment_name, adjustments.adjustment_type, adjustments.account_number, 
		adjustments.earning_code,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		employee_adjustments.org_id, employee_adjustments.employee_adjustment_id, employee_adjustments.pay_date, employee_adjustments.amount, 
		employee_adjustments.in_payroll, employee_adjustments.in_tax, employee_adjustments.visible, employee_adjustments.exchange_rate,
		employee_adjustments.paid_amount, employee_adjustments.balance, employee_adjustments.narrative,
		employee_adjustments.tax_relief_amount,
		
		projects.project_id, projects.project_name, projects.project_account,
		project_staff_costs.project_staff_cost_id, 
		project_staff_costs.project_role, project_staff_costs.payroll_ps,
		project_staff_costs.staff_cost, project_staff_costs.tax_cost, 
		
		(employee_adjustments.exchange_rate * employee_adjustments.amount) as base_amount,
		(employee_adjustments.exchange_rate * employee_adjustments.amount * project_staff_costs.payroll_ps / 100) as project_amount
		
	FROM employee_adjustments INNER JOIN adjustments ON employee_adjustments.adjustment_id = adjustments.adjustment_id
		INNER JOIN vw_employee_month ON employee_adjustments.employee_month_id = vw_employee_month.employee_month_id
		INNER JOIN currency ON adjustments.currency_id = currency.currency_id
		INNER JOIN project_staff_costs ON vw_employee_month.employee_month_id = project_staff_costs.employee_month_id
		INNER JOIN projects ON project_staff_costs.project_id = projects.project_id;

CREATE VIEW vw_phases AS
	SELECT vw_projects.client_id, vw_projects.client_name, vw_projects.project_type_id, vw_projects.project_type_name, 
		vw_projects.project_id, vw_projects.project_name, vw_projects.signed, vw_projects.contract_ref, 
		vw_projects.monthly_amount, vw_projects.full_amount, vw_projects.project_cost, vw_projects.narrative, 
		vw_projects.start_date, vw_projects.ending_date, 
		phases.org_id, phases.phase_id, phases.phase_name, phases.start_date as phase_start_date, phases.end_date as phase_end_date, 
		phases.completed as phase_completed, phases.phase_cost, phases.details
	FROM phases INNER JOIN vw_projects ON phases.project_id = vw_projects.project_id;

CREATE VIEW vw_tasks AS
	SELECT vw_phases.client_id, vw_phases.client_name, vw_phases.project_type_id, vw_phases.project_type_name, 
		vw_phases.project_id, vw_phases.project_name, vw_phases.signed, vw_phases.contract_ref, 
		vw_phases.monthly_amount, vw_phases.full_amount, vw_phases.project_cost, vw_phases.narrative, 
		vw_phases.start_date, vw_phases.ending_date,
		vw_phases.phase_id, vw_phases.phase_name, vw_phases.phase_start_date, vw_phases.phase_end_date, 
		vw_phases.phase_completed,  vw_phases.phase_cost, 
		entitys.entity_id, entitys.entity_name, tasks.task_id, tasks.task_name, 
		tasks.org_id, tasks.start_date as task_start_date, tasks.dead_line as task_dead_line, 
		tasks.end_date as task_end_date, tasks.completed as task_completed, 
		tasks.hours_taken, tasks.details as task_details
	FROM tasks INNER JOIN entitys ON tasks.entity_id = entitys.entity_id
		INNER JOIN vw_phases ON tasks.phase_id = vw_phases.phase_id;
		
CREATE VIEW vw_timesheet AS
		SELECT vw_tasks.client_id, vw_tasks.client_name, vw_tasks.project_type_id, vw_tasks.project_type_name, 
		vw_tasks.project_id, vw_tasks.project_name, vw_tasks.signed, vw_tasks.contract_ref, 
		vw_tasks.monthly_amount, vw_tasks.full_amount, vw_tasks.project_cost, vw_tasks.narrative, 
		vw_tasks.start_date, vw_tasks.ending_date,
		vw_tasks.phase_id, vw_tasks.phase_name, vw_tasks.phase_start_date, vw_tasks.phase_end_date, 
		vw_tasks.phase_completed,  vw_tasks.phase_cost, 
		vw_tasks.entity_id, vw_tasks.entity_name, 
		vw_tasks.task_id, vw_tasks.task_name, 
		vw_tasks.task_start_date, vw_tasks.task_dead_line, vw_tasks.task_end_date, vw_tasks.task_completed, 
		timesheet.org_id, timesheet.timesheet_id, timesheet.ts_date, timesheet.ts_start_time, timesheet.ts_end_time, 
		timesheet.ts_narrative, timesheet.details,
		(EXTRACT(HOURS from timesheet.ts_end_time - timesheet.ts_start_time) +
		EXTRACT(MINUTES from timesheet.ts_end_time - timesheet.ts_start_time) / 60) as ts_hours
	FROM timesheet INNER JOIN vw_tasks ON timesheet.task_id = vw_tasks.task_id;

CREATE VIEW vw_project_cost AS
	SELECT vw_phases.client_id, vw_phases.client_name, vw_phases.project_type_id, vw_phases.project_type_name, 
		vw_phases.project_id, vw_phases.project_name, vw_phases.signed, vw_phases.contract_ref, 
		vw_phases.monthly_amount, vw_phases.full_amount, vw_phases.project_cost, vw_phases.narrative, 
		vw_phases.start_date, vw_phases.ending_date,
		vw_phases.phase_id, vw_phases.phase_name, vw_phases.phase_start_date, vw_phases.phase_end_date, 
		vw_phases.phase_cost, 
		project_cost.org_id, project_cost.project_cost_id, project_cost.project_cost_name, 
		project_cost.amount, project_cost.cost_date, project_cost.cost_approved, project_cost.details
	FROM project_cost INNER JOIN vw_phases ON project_cost.phase_id = vw_phases.phase_id;

CREATE VIEW vw_attendance AS
	SELECT entitys.entity_id, entitys.entity_name, attendance.attendance_id, attendance.attendance_date, 
		attendance.org_id, attendance.time_in, attendance.time_out, attendance.details
	FROM attendance INNER JOIN entitys ON attendance.entity_id = entitys.entity_id;

CREATE OR REPLACE FUNCTION ins_projects() RETURNS trigger AS $$
DECLARE
    myrec RECORD;
	start_days integer;
BEGIN
	start_days := 0;
	FOR myrec IN SELECT entity_type_id, Define_phase_name,  
		CAST(((NEW.ending_date - NEW.start_date) * Define_phase_time / 100) as integer) as date_range, 
		(NEW.project_cost * Define_phase_cost / 100) as phase_cost
		FROM Define_Phases
		WHERE (project_type_id = NEW.project_type_id)
		ORDER BY define_phases.phase_order 
	LOOP

		INSERT INTO Phases (project_id, entity_type_id, phase_name, start_date, end_date, phase_cost)
		VALUES(NEW.project_id, myrec.entity_type_id, myrec.Define_phase_name, 
			NEW.start_date + start_days, 
			NEW.start_date + myrec.date_range + start_days, 
			myrec.phase_cost);
		
		start_days := start_days + myrec.date_range + 1;
	END LOOP;

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_projects AFTER INSERT ON projects
    FOR EACH ROW EXECUTE PROCEDURE ins_projects();


CREATE OR REPLACE FUNCTION add_project_staff(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg		 				varchar(120);
	v_entity_id				integer;
	v_org_id				integer;
BEGIN

	SELECT entity_id INTO v_entity_id
	FROM project_staff WHERE (entity_id = CAST($1 as int)) AND (project_id = CAST($3 as int));
	
	IF(v_entity_id is null)THEN
		SELECT org_id INTO v_org_id
		FROM projects WHERE (project_id = CAST($3 as int));
		
		INSERT INTO  project_staff (project_id, entity_id, org_id)
		VALUES (CAST($3 as int), CAST($1 as int), v_org_id);

		msg := 'Added to project';
	ELSE
		msg := 'Already Added to project';
	END IF;
	
	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION process_bio_imports1(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg		 				varchar(120);
BEGIN

	msg := 'Already Added to project';
	
	return msg;
END;
$$ LANGUAGE plpgsql;

