ALTER TABLE orgs
ADD Bank_Header				text,
ADD Bank_Address			text;

CREATE TABLE disability (
	disability_id			serial primary key,
	org_id					integer references orgs,
	disability_name			varchar(240) not null
);
CREATE INDEX disability_org_id ON disability(org_id);

CREATE TABLE pay_scales (
	pay_scale_id			serial primary key,
	currency_id				integer references currency,
	org_id					integer references orgs,
	pay_scale_name			varchar(32) not null,
	min_pay					real,
	max_pay					real,
	details					text
);
CREATE INDEX pay_scales_org_id ON pay_scales(org_id);
CREATE INDEX pay_scales_currency_id ON pay_scales(currency_id);

CREATE TABLE pay_scale_steps (
	pay_scale_step_id		serial primary key,
	pay_scale_id			integer references pay_scales,
	org_id					integer references orgs,
	pay_step				integer not null,
	pay_amount				real not null
);
CREATE INDEX pay_scale_steps_pay_scale_id ON pay_scale_steps(pay_scale_id);
CREATE INDEX pay_scale_steps_org_id ON pay_scale_steps(org_id);

CREATE TABLE pay_scale_years (
	pay_scale_year_id		serial primary key,
	pay_scale_id			integer references pay_scales,
	org_id					integer references orgs,
	pay_year				integer not null,
	pay_amount				real not null
);
CREATE INDEX pay_scale_years_pay_scale_id ON pay_scale_years(pay_scale_id);
CREATE INDEX pay_scale_years_org_id ON pay_scale_years(org_id);

CREATE TABLE pay_groups (
	pay_group_id			serial primary key,
	org_id					integer references orgs,
	pay_group_name			varchar(50),
	Details					text
);
CREATE INDEX pay_groups_org_id ON pay_groups(org_id);

CREATE TABLE locations ( 
	location_id				serial primary key,
	org_id					integer references orgs,
	location_name			varchar(50),
	details					text
);
CREATE INDEX locations_org_id ON locations(org_id);

CREATE TABLE department_roles (
	department_role_id		serial primary key,
	department_id			integer references departments,
	ln_department_role_id	integer references department_roles,
	org_id					integer references orgs,
	department_role_name	varchar(240) not null,
	active					boolean default true not null,
	job_description			text,
	job_requirements		text,
	duties					text,
	performance_measures	text,
	details					text
);
CREATE INDEX department_roles_department_id ON department_roles (department_id);
CREATE INDEX department_roles_ln_department_role_id ON department_roles (ln_department_role_id);
CREATE INDEX department_roles_org_id ON department_roles(org_id);
INSERT INTO department_roles (org_id, department_role_id, ln_department_role_id, department_id, department_role_name) VALUES (0, 0, 0, 0, 'Chair Person');

CREATE TABLE applicants (
	entity_id				integer references entitys primary key,
	disability_id			integer references disability,
	org_id					integer references orgs,

	person_title			varchar(7),
	surname					varchar(50) not null,
	first_name				varchar(50) not null,
	middle_name				varchar(50),
	applicant_email			varchar(50) not null unique,
	applicant_phone			varchar(50),
	date_of_birth			date,
	gender					varchar(1),
	nationality				char(2) references sys_countrys,
	marital_status 			varchar(2),
	picture_file			varchar(32),
	identity_card			varchar(50),
	language				varchar(320),

	field_of_study			text,
	interests				text,
	objective				text,
	details					text
);
CREATE INDEX applicants_org_id ON applicants(org_id);

CREATE TABLE employees (
	entity_id				integer references entitys primary key,
	department_role_id		integer not null references department_roles,
	bank_branch_id			integer not null references bank_branch,
	disability_id			integer references disability,
	employee_id				varchar(12) not null,
	pay_scale_id			integer references pay_scales,
	pay_scale_step_id		integer references pay_scale_steps,
	pay_group_id			integer references pay_groups,
	location_id				integer references locations,
	currency_id				integer references currency,
	org_id					integer references orgs,

	person_title			varchar(7),
	surname					varchar(50) not null,
	first_name				varchar(50) not null,
	middle_name				varchar(50),
	date_of_birth			date,
	
	gender					varchar(1),
	phone					varchar(120),
	nationality				char(2) not null references sys_countrys,
	
	nation_of_birth			char(2) references sys_countrys,
	place_of_birth			varchar(50),
	
	marital_status 			varchar(2),
	appointment_date		date,
	current_appointment		date,

	exit_date				date,
	contract				boolean default false not null,
	contract_period			integer not null,
	employment_terms		varchar(320),
	identity_card			varchar(50),
	basic_salary			real not null,
	bank_account			varchar(32),
	picture_file			varchar(32),
	active					boolean default true not null,
	language				varchar(320),
	desg_code				varchar(16),
	inc_mth					varchar(16),
	previous_sal_point		varchar(16),
	current_sal_point		varchar(16),
	halt_point				varchar(16),

	height					real, 
	weight					real, 
	blood_group				varchar(3),
	allergies				varchar(320),

	field_of_study			text,
	interests				text,
	objective				text,
	details					text,

	UNIQUE(org_id, employee_id)
);
CREATE INDEX employees_department_role_id ON employees (department_role_id);
CREATE INDEX employees_bank_branch_id ON employees (bank_branch_id);
CREATE INDEX employees_disability_id ON employees (disability_id);
CREATE INDEX employees_pay_scale_id ON employees (pay_scale_id);
CREATE INDEX employees_pay_scale_step_id ON employees (pay_scale_step_id);
CREATE INDEX employees_pay_group_id ON employees (pay_group_id);
CREATE INDEX employees_location_id ON employees (location_id);
CREATE INDEX employees_nationality ON employees (nationality);
CREATE INDEX employees_nation_of_birth ON employees (nation_of_birth);
CREATE INDEX employees_currency_id ON employees (currency_id);
CREATE INDEX employees_org_id ON employees(org_id);

CREATE TABLE education_class (
	education_class_id		serial primary key,
	org_id					integer references orgs,
	education_class_name	varchar(50),
	details					text
);
CREATE INDEX education_class_org_id ON education_class(org_id);

CREATE TABLE education (
	education_id			serial primary key,
	entity_id				integer references entitys,
	education_class_id		integer references education_class,
	org_id					integer references orgs,
	date_from				date not null,
	date_to					date,
	name_of_school			varchar(240),
	examination_taken		varchar(240),
	grades_obtained			varchar(50),
	certificate_number		varchar(50),
	details					text
);
CREATE INDEX education_entity_id ON education (entity_id);
CREATE INDEX education_education_class_id ON education (education_class_id);
CREATE INDEX education_org_id ON education(org_id);

CREATE TABLE employment (
	employment_id			serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	date_from				date not null,
	date_to					date,
	employers_name			varchar(240),
	position_held			varchar(240),
	details					text
);
CREATE INDEX employment_entity_id ON employment (entity_id);
CREATE INDEX employment_org_id ON employment(org_id);

CREATE TABLE kin_types (
	kin_type_id				serial primary key,
	org_id					integer references orgs,
	kin_type_name			varchar(50),
	details					text
);
CREATE INDEX kin_types_org_id ON kin_types(org_id);

CREATE TABLE kins (
	kin_id					serial primary key,
	entity_id				integer references entitys,
	kin_type_id				integer references kin_types,
	org_id					integer references orgs,
	full_names				varchar(120),
	date_of_birth			date,
	identification			varchar(50),
	relation				varchar(50),
	emergency_contact		boolean default false not null,
	beneficiary				boolean default false not null,
	beneficiary_ps			real,
	details					text
);
CREATE INDEX kins_entity_id ON kins (entity_id);
CREATE INDEX kins_kin_type_id ON kins (kin_type_id);
CREATE INDEX kins_org_id ON kins(org_id);

CREATE TABLE cv_seminars (
	cv_seminar_id			serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	cv_seminar_name			varchar(240),
	cv_seminar_date			date not null,
	details					text
);
CREATE INDEX cv_seminars_entity_id ON cv_seminars (entity_id);
CREATE INDEX cv_seminars_org_id ON cv_seminars(org_id);

CREATE TABLE cv_projects (
	cv_projectid			serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	cv_project_name			varchar(240),
	cv_project_date			date not null,
	details					text
);
CREATE INDEX cv_projects_entity_id ON cv_projects (entity_id);
CREATE INDEX cv_projects_org_id ON cv_projects(org_id);

CREATE TABLE skill_category (
	skill_category_id		serial primary key,
	org_id					integer references orgs,
	skill_category_name		varchar(50) not null,
	details					text
);
CREATE INDEX skill_category_org_id ON skill_category(org_id);

CREATE TABLE skill_types (
	skill_type_id			serial primary key,
	skill_category_id		integer references skill_category,
	org_id					integer references orgs,
	skill_type_name			varchar(50) not null,
	basic					varchar(50),
	intermediate 			varchar(50),
	advanced				varchar(50),
	details					text
);
CREATE INDEX skill_types_skill_category_id ON skill_types (skill_category_id);
CREATE INDEX skill_types_org_id ON skill_types(org_id);

CREATE TABLE skills (
	skill_id				serial primary key,
	entity_id				integer references entitys,
	skill_type_id			integer references skill_types,
	org_id					integer references orgs,
	skill_level				integer default 1 not null,
	aquired					boolean default false not null,
	training_date			date,
	trained					boolean default false not null,
	training_institution	varchar(240),
	training_cost			real,
	details					text
);
CREATE INDEX skills_entity_id ON skills (entity_id);
CREATE INDEX skills_skill_type_id ON skills (skill_type_id);
CREATE INDEX skills_org_id ON skills(org_id);

CREATE TABLE identification_types (
	identification_type_id	serial primary key,
	org_id					integer references orgs,
	identification_type_name	varchar(50),
	details					text
);
CREATE INDEX identification_types_org_id ON identification_types(org_id);

CREATE TABLE identifications (
	identification_id		serial primary key,
	entity_id				integer references entitys,
	identification_type_id	integer references identification_types,
	nationality				char(2) not null references sys_countrys,
	org_id					integer references orgs,
	identification			varchar(64),
	is_active				boolean default true not null,
	starting_from			date,
	expiring_at				date,
	place_of_issue			varchar(50),
	details					text
);
CREATE INDEX identifications_entity_id ON identifications(entity_id);
CREATE INDEX identifications_identification_type_id ON identifications(identification_type_id);
CREATE INDEX identifications_org_id ON identifications(org_id);

CREATE TABLE casual_category (
	casual_category_id		serial primary key,
	org_id					integer references orgs,
	casual_category_name	varchar(50),
	details					text
);
CREATE INDEX casual_category_org_id ON casual_category(org_id);

CREATE TABLE casual_application (
	casual_application_id	serial primary key,
	department_id			integer references departments,
	casual_category_id		integer references casual_category,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	position				integer default 1 not null,
	work_duration			integer default 1 not null,
	approved_pay_rate		real,
	
	approve_status			varchar(16) default 'draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	details					text
);
CREATE INDEX casual_application_Department_id ON casual_application (Department_id);
CREATE INDEX casual_application_category_id ON casual_application (casual_category_id);
CREATE INDEX casual_application_entity_id ON casual_application (entity_id);
CREATE INDEX casual_application_org_id ON casual_application(org_id);

CREATE TABLE casuals (
	casual_id				serial primary key,
	entity_id				integer references entitys,
	casual_application_id	integer references casual_application,
	org_id					integer references orgs,
	start_date				date,
	end_date				date,
	duration				integer,
	pay_rate				real,
	amount_paid				real,
	paid					boolean default false not null,

	approve_status			varchar(16) default 'draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,

	details					text
);
CREATE INDEX casuals_entity_id ON casuals (entity_id);
CREATE INDEX casuals_casual_application_id ON casuals (casual_application_id);
CREATE INDEX casuals_org_id ON casuals(org_id);

CREATE TABLE leave_types (
	leave_type_id			serial primary key,
	org_id					integer references orgs,
	leave_type_name			varchar(50) not null,
	allowed_leave_days		integer default 1 not null,
	leave_days_span			integer default 1 not null,
	
	use_type				integer default 0 not null,
	month_quota				real default 0 not null,
	initial_days			real default 0 not null,
	maximum_carry			real default 0 not null,
	include_holiday 		boolean default false not null,

	include_mon				boolean default true not null,
	include_tue				boolean default true not null,
	include_wed				boolean default true not null,
	include_thu				boolean default true not null,
	include_fri				boolean default true not null,
	include_sat				boolean default false not null,
	include_sun				boolean default false not null,

	details					text
);
CREATE INDEX leave_types_org_id ON leave_types(org_id);
INSERT INTO leave_types (org_id, leave_type_id, leave_type_name, allowed_leave_days, leave_days_span)
VALUES (0, 0, 'Annual Leave', 21, 7);

CREATE TABLE employee_leave_types (
	employee_leave_type_id	serial primary key,
	entity_id				integer references entitys,
	leave_type_id			integer references leave_types,
	org_id					integer references orgs,
	leave_balance			real default 0 not null,
	leave_starting			date default current_date not null,
	details					text
);
CREATE INDEX employee_leave_types_entity_id ON employee_leave_types (entity_id);
CREATE INDEX employee_leave_types_leave_type_id ON employee_leave_types (leave_type_id);
CREATE INDEX employee_leave_types_org_id ON employee_leave_types (org_id);

CREATE TABLE employee_leave (
	employee_leave_id		serial primary key,
	entity_id				integer references entitys,
	contact_entity_id		integer references entitys,
	leave_type_id			integer references leave_types,
	org_id					integer references orgs,
	leave_from				date not null,
	leave_to				date not null,
	leave_days				real not null,
	start_half_day			boolean default false not null,
	end_half_day			boolean default false not null,

	special_request			boolean default false not null,
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	completed				boolean default false not null,
	narrative				varchar(240),
	details					text
);
CREATE INDEX employee_leave_entity_id ON employee_leave (entity_id);
CREATE INDEX employee_leave_contact_entity_id ON employee_leave (contact_entity_id);
CREATE INDEX employee_leave_leave_type_id ON employee_leave (leave_type_id);
CREATE INDEX employee_leave_org_id ON employee_leave(org_id);

CREATE TABLE leave_work_days (
	leave_work_day_id		serial primary key,
	employee_leave_id		integer references employee_leave,
	entity_id				integer references entitys,
	org_id					integer references orgs,

	work_date				date not null,
	half_day				boolean default false not null,

	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,

	details					text
);
CREATE INDEX leave_work_days_employee_leave_id ON leave_work_days (employee_leave_id);
CREATE INDEX leave_work_days_org_id ON leave_work_days(org_id);

CREATE TABLE intake (
	intake_id				serial primary key,
	department_role_id		integer references department_roles,
	pay_scale_id			integer references pay_scales,
	pay_group_id			integer references pay_groups,
	location_id				integer references locations,
	org_id					integer references orgs,
	opening_date			date not null,
	closing_date			date not null,
	positions				int,
	contract				boolean default false not null,
	contract_period			integer not null,
	details					text
);
CREATE INDEX intake_department_role_id ON intake (department_role_id);
CREATE INDEX intake_pay_scale_id ON intake (pay_scale_id);
CREATE INDEX intake_pay_group_id ON intake (pay_group_id);
CREATE INDEX intake_location_id ON intake (location_id);
CREATE INDEX intake_org_id ON intake(org_id);

CREATE TABLE contract_types (
	contract_type_id		serial primary key,
	org_id					integer references orgs,
	contract_type_name		varchar(50) not null,
	contract_text			text,
	details					text
);
CREATE INDEX contract_types_org_id ON contract_types(org_id);

CREATE TABLE contract_status (
	contract_status_id		serial primary key,
	org_id					integer references orgs,
	contract_status_name	varchar(50) not null,
	details					text
);
CREATE INDEX contract_status_org_id ON contract_status(org_id);

CREATE TABLE applications (
	application_id			serial primary key,
	intake_id				integer references intake,
	contract_type_id		integer references contract_types,
	contract_status_id		integer references contract_status,
	entity_id				integer references entitys,
	employee_id				integer references employees,
	org_id					integer references orgs,

	contract_date			date,
	contract_close			date,
	contract_start			date,
	contract_period			integer,
	contract_terms			text,
	initial_salary			real,

	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	short_listed			integer default 0 not null,
	
	applicant_comments		text,
	review					text
);
CREATE INDEX applications_intake_id ON applications (intake_id);
CREATE INDEX applications_contract_type_id ON applications (contract_type_id);
CREATE INDEX applications_contract_status_id ON applications (contract_status_id);
CREATE INDEX applications_entity_id ON applications (entity_id);
CREATE INDEX applications_employee_id ON applications (employee_id);
CREATE INDEX applications_org_id ON applications(org_id);

CREATE TABLE internships (
	internship_id			serial primary key,
	department_id			integer references departments,
	org_id					integer references orgs,
	opening_date			date not null,
	closing_date			date not null,
	positions				int,
	location				varchar(50),
	details					text
);
CREATE INDEX internships_department_id ON internships (department_id);
CREATE INDEX internships_org_id ON internships(org_id);

CREATE TABLE interns (
	intern_id				serial primary key,
	internship_id			integer references internships,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	payment_amount			real,
	start_date				date,
	end_date				date,
	phone_mobile			varchar(50),

	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,

	applicant_comments		text,
	review					text,
	UNIQUE(internship_id, entity_id)
);
CREATE INDEX interns_internship_id ON interns (internship_id);
CREATE INDEX interns_entity_id ON interns (entity_id);
CREATE INDEX interns_org_id ON interns(org_id);

CREATE TABLE objective_types (
	objective_type_id 		serial primary key,
	org_id					integer references orgs,
	objective_type_name		varchar(320) not null,
	details					text
);
CREATE INDEX objective_types_org_id ON objective_types(org_id);

CREATE TABLE employee_objectives (
	employee_objective_id	serial primary key,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	employee_objective_name	varchar(320) not null,
	objective_date			date not null,

	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	supervisor_comments		text,
	details					text
);
CREATE INDEX employee_objectives_entity_id ON employee_objectives(entity_id);
CREATE INDEX employee_objectives_org_id ON employee_objectives(org_id);

CREATE TABLE objectives (
	objective_id		 	serial primary key,
	employee_objective_id	integer references employee_objectives,
	objective_type_id		integer references objective_types,
	org_id					integer references orgs,
	date_set				date not null,
	objective_ps			real,
	objective_name			varchar(320) not null,
	objective_completed		boolean default false not null,
	
	objective_maditory		boolean default false not null,
	
	supervisor_comments		text,
	details					text
);
CREATE INDEX objectives_employee_objective_id ON objectives(employee_objective_id);
CREATE INDEX objectives_objective_type_id ON objectives(objective_type_id);
CREATE INDEX objectives_org_id ON objectives(org_id);

CREATE TABLE objective_details (
	objective_detail_id		serial primary key,
	objective_id		 	integer references objectives,
	ln_objective_detail_id	integer references objective_details,
	org_id					integer references orgs,
	objective_detail_name	varchar(320) not null,
	success_indicator		text not null,
	achievements			text,
	resources_required		text,
	
	ods_ps					real,				---- ods = objective details
	ods_points				integer default 1 not null,
	ods_reviewer_points		integer default 1 not null,
	
	target_date 			date,
	completed				boolean default false not null,
	completion_date			date,
	target_changes			text,
	
	supervisor_comments		text,
	details					text
);
CREATE INDEX objective_details_objective_id ON objective_details(objective_id);
CREATE INDEX objective_details_ln_objective_detail_id ON objective_details(ln_objective_detail_id);
CREATE INDEX objective_details_org_id ON objective_details(org_id);

CREATE TABLE review_category (
	review_category_id		serial primary key,
	org_id					integer references orgs,
	review_category_name	varchar(320),
	details					text
);
CREATE INDEX review_category_org_id ON review_category(org_id);

CREATE TABLE review_points (
	review_point_id			serial primary key,
	review_category_id		integer references review_category,
	org_id					integer references orgs,
	review_point_name		varchar(50),
	review_points			integer default 1 not null,
	details					text
);
CREATE INDEX review_points_review_category_id ON review_points (review_category_id);
CREATE INDEX review_points_org_id ON review_points(org_id);

CREATE TABLE job_reviews (
	job_review_id			serial primary key,
	entity_id				integer references entitys,
	review_category_id		integer references review_category,
	org_id					integer references orgs,
	total_points			integer,
	self_rating				integer,
	supervisor_rating		integer,
	review_date				date not null,
	review_done				boolean default false not null,
	
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	recomendation			text,
	staff_comments			text,
	reviewer_comments		text,
	pl_comments				text,
	
	details					text
);
CREATE INDEX job_reviews_entity_id ON job_reviews (entity_id);
CREATE INDEX job_reviews_review_category_id ON job_reviews (review_category_id);
CREATE INDEX job_reviews_org_id ON job_reviews(org_id);

CREATE TABLE career_development (
	career_development_id		serial primary key,
	org_id						integer references orgs,
	career_development_name		varchar(50) not null,
	details						text,
	UNIQUE(org_id, career_development_name)
);
CREATE INDEX career_development_org_id ON career_development(org_id);

CREATE TABLE evaluation_points (
	evaluation_point_id		serial primary key,
	job_review_id			integer references job_reviews,
	review_point_id			integer references review_points,
	objective_id			integer references objectives,
	career_development_id	integer references career_development,
	org_id					integer references orgs,

	points					integer default 1 not null,
	grade					varchar(2),
	narrative				text,

	reviewer_points			integer default 1 not null,
	reviewer_grade			varchar(2),
	reviewer_narrative		text,

	details					text,
	UNIQUE(org_id, job_review_id, review_point_id, objective_id, career_development_id)
);
CREATE INDEX evaluation_points_job_review_id ON evaluation_points (job_review_id);
CREATE INDEX evaluation_points_review_point_id ON evaluation_points (review_point_id);
CREATE INDEX evaluation_points_objective_id ON evaluation_points (objective_id);
CREATE INDEX evaluation_points_career_development_id ON evaluation_points(career_development_id);
CREATE INDEX evaluation_points_org_id ON evaluation_points (org_id);

CREATE TABLE case_types (
	case_type_id			serial primary key,
	org_id					integer references orgs,
	case_type_name			varchar(50),
	details					text
);
CREATE INDEX case_types_org_id ON case_types(org_id);

CREATE TABLE employee_cases (
	employee_case_id		serial primary key,
	case_type_id			integer references case_types,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	narrative				varchar(240),
	case_date				date,
	complaint				text,
	case_action				text,
	completed				boolean default false not null,
	details					text
);
CREATE INDEX employee_cases_case_type_id ON employee_cases (case_type_id);
CREATE INDEX employee_cases_entity_id ON employee_cases (entity_id);
CREATE INDEX employee_cases_org_id ON employee_cases(org_id);

CREATE TABLE trainings (
	training_id				serial primary key,
	org_id					integer references orgs,
	training_name			varchar(50),
	start_date				date,
	end_date				date,
	training_cost			real,
	completed				boolean default false not null,
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	details					text
);
CREATE INDEX trainings_org_id ON trainings(org_id);

CREATE TABLE employee_trainings (
	employee_training_id	serial primary key,
	training_id				integer references trainings,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	narrative				varchar(240),
	completed				boolean default false not null,
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	details					text
);
CREATE INDEX employee_trainings_training_id ON employee_trainings (training_id);
CREATE INDEX employee_trainings_entity_id ON employee_trainings (entity_id);
CREATE INDEX employee_trainings_org_id ON employee_trainings(org_id);

ALTER TABLE address	ADD company_name	varchar(50);
ALTER TABLE address	ADD position_held	varchar(50);

----------- Views 
CREATE VIEW vw_referees AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name, address.address_id, address.org_id, address.address_name, 
		address.table_name, address.table_id, address.post_office_box, address.postal_code, address.premises, address.street, address.town, 
		address.phone_number, address.extension, address.mobile, address.fax, address.email, address.is_default, address.website, 
		address.company_name, address.position_held, address.details
	FROM address INNER JOIN sys_countrys ON address.sys_country_id = sys_countrys.sys_country_id
	WHERE (address.table_name = 'referees');

CREATE VIEW vw_department_roles AS
	SELECT departments.department_id, departments.department_name, departments.description as department_description, 
		departments.duties as department_duties, ln_department_roles.department_role_name as parent_role_name, 
		department_roles.org_id, department_roles.department_role_id, department_roles.ln_department_role_id, 
		department_roles.department_role_name, department_roles.job_description, department_roles.job_requirements, 
		department_roles.duties, department_roles.performance_measures, department_roles.active, department_roles.details
	FROM department_roles INNER JOIN departments ON department_roles.department_id = departments.department_id
		LEFT JOIN department_roles as ln_department_roles ON department_roles.ln_department_role_id = ln_department_roles.department_role_id;
		
CREATE VIEW vw_pay_scales AS
	SELECT currency.currency_id, currency.currency_name, currency.currency_symbol,
		pay_scales.org_id, pay_scales.pay_scale_id, pay_scales.pay_scale_name,
		pay_scales.min_pay, pay_scales.max_pay, pay_scales.details
	FROM pay_scales INNER JOIN currency ON pay_scales.currency_id = currency.currency_id;
	
CREATE VIEW vw_pay_scale_steps AS
	SELECT currency.currency_id, currency.currency_name, currency.currency_symbol,
		pay_scales.pay_scale_id, pay_scales.pay_scale_name, 
		pay_scale_steps.org_id, pay_scale_steps.pay_scale_step_id, pay_scale_steps.pay_step, 
		pay_scale_steps.pay_amount,
		(pay_scales.pay_scale_name || '-' || currency.currency_symbol || '-' || pay_scale_steps.pay_step) as pay_step_name
	FROM pay_scale_steps INNER JOIN pay_scales ON pay_scale_steps.pay_scale_id = pay_scales.pay_scale_id
		INNER JOIN currency ON pay_scales.currency_id = currency.currency_id;

CREATE VIEW vw_education_max AS
	SELECT education_class.education_class_id, education_class.education_class_name, 
		education.org_id, education.education_id, education.entity_id, education.date_from, education.date_to, 
		education.name_of_school, education.examination_taken,
		education.grades_obtained, education.certificate_number
	FROM (education_class INNER JOIN education ON education_class.education_class_id = education.education_class_id)
	INNER JOIN 
		(SELECT education.entity_id, max(education.education_id) as max_education_id
		FROM education INNER JOIN 
			(SELECT entity_id, max(education_class_id) as max_education_class_id
			FROM education
			GROUP BY entity_id) as a
			ON (education.entity_id = a.entity_id) AND (education.education_class_id = a.max_education_class_id)
		GROUP BY education.entity_id) as b
	ON (education.education_id = b.max_education_id);

CREATE VIEW vw_employment_max AS
	SELECT employment.employment_id, employment.entity_id, employment.date_from, employment.date_to, 
		employment.org_id, employment.employers_name, employment.position_held,
		age(COALESCE(employment.date_to, current_date), employment.date_from) as employment_duration,
		c.employment_experince
	FROM employment INNER JOIN 
		(SELECT max(employment_id) as max_employment_id FROM employment INNER JOIN
		(SELECT entity_id, max(date_from) as max_date_from FROM employment GROUP BY entity_id) as a
		ON (employment.entity_id = a.entity_id) AND (employment.date_from = a.max_date_from)
		GROUP BY employment.entity_id) as b
	ON employment.employment_id = b.max_employment_id
		INNER JOIN
	(SELECT entity_id, sum(age(COALESCE(employment.date_to, current_date), employment.date_from)) as employment_experince
		FROM employment GROUP BY entity_id) as c
	ON employment.entity_id = c.entity_id;

CREATE VIEW vw_applicants AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name, applicants.entity_id, applicants.surname, 
		applicants.org_id, applicants.first_name, applicants.middle_name, applicants.date_of_birth, applicants.nationality, 
		applicants.identity_card, applicants.language, applicants.objective, applicants.interests, applicants.picture_file, applicants.details,
		applicants.person_title, applicants.field_of_study, applicants.applicant_email, applicants.applicant_phone, 
		(applicants.Surname || ' ' || applicants.First_name || ' ' || COALESCE(applicants.Middle_name, '')) as applicant_name,
		to_char(age(applicants.date_of_birth), 'YY') as applicant_age,
		(CASE WHEN applicants.gender = 'M' THEN 'Male' ELSE 'Female' END) as gender_name,
		(CASE WHEN applicants.marital_status = 'M' THEN 'Married' ELSE 'Single' END) as marital_status_name,

		vw_education_max.education_class_id, vw_education_max.education_class_name, 
		vw_education_max.education_id, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken,
		vw_education_max.grades_obtained, vw_education_max.certificate_number,
		
		vw_employment_max.employers_name, vw_employment_max.position_held,
		vw_employment_max.date_from as emp_date_from, vw_employment_max.date_to as emp_date_to, 
		vw_employment_max.employment_duration, vw_employment_max.employment_experince,
		round((date_part('year', vw_employment_max.employment_duration) + date_part('month', vw_employment_max.employment_duration)/12)::numeric, 1) as emp_duration,
		round((date_part('year', vw_employment_max.employment_experince) + date_part('month', vw_employment_max.employment_experince)/12)::numeric, 1) as emp_experince
		
	FROM applicants INNER JOIN sys_countrys ON applicants.nationality = sys_countrys.sys_country_id
		LEFT JOIN vw_education_max ON applicants.entity_id = vw_education_max.entity_id
		LEFT JOIN vw_employment_max ON applicants.entity_id = vw_employment_max.entity_id;

CREATE VIEW vw_employees AS
	SELECT vw_bank_branch.bank_id, vw_bank_branch.bank_name, vw_bank_branch.bank_branch_id, vw_bank_branch.bank_branch_name, 
		vw_bank_branch.bank_branch_code, vw_department_roles.department_id, vw_department_roles.department_name, 
		vw_department_roles.department_role_id, vw_department_roles.department_role_name, 
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		sys_countrys.sys_country_name, nob.sys_country_name as birth_nation_name,  
		disability.disability_id, disability.disability_name,		
		employees.org_id, employees.entity_id, employees.employee_id, employees.surname, employees.first_name, employees.middle_name, 
		employees.person_title, employees.field_of_study,
		(employees.Surname || ' ' || employees.First_name || ' ' || COALESCE(employees.Middle_name, '')) as employee_name,
		employees.date_of_birth, employees.place_of_birth, employees.gender, 
		employees.nationality, employees.nation_of_birth, 
		employees.marital_status, employees.appointment_date, 
		employees.exit_date, employees.contract, employees.contract_period, employees.employment_terms, employees.identity_card, 
		employees.basic_salary, employees.bank_account, employees.language, employees.picture_file, employees.active, 
		employees.height, employees.weight, employees.blood_group, employees.allergies,
		employees.phone, employees.objective, employees.interests, employees.details, 
		to_char(age(employees.date_of_birth), 'YY') as employee_age,
		(CASE WHEN employees.gender = 'M' THEN 'Male' ELSE 'Female' END) as gender_name,
		(CASE WHEN employees.marital_status = 'M' THEN 'Married' ELSE 'Single' END) as marital_status_name,

		vw_education_max.education_class_name, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken, 
		vw_education_max.grades_obtained, vw_education_max.certificate_number
	FROM employees INNER JOIN vw_bank_branch ON employees.bank_branch_id = vw_bank_branch.bank_branch_id
		INNER JOIN vw_department_roles ON employees.department_role_id = vw_department_roles.department_role_id
		INNER JOIN currency ON employees.currency_id = currency.currency_id
		INNER JOIN sys_countrys ON employees.nationality = sys_countrys.sys_country_id		
		LEFT JOIN sys_countrys as nob ON employees.nation_of_birth = nob.sys_country_id
		LEFT JOIN disability ON employees.disability_id = disability.disability_id
		LEFT JOIN vw_education_max ON employees.entity_id = vw_education_max.entity_id;

CREATE VIEW vw_entity_employees AS
	SELECT entitys.entity_id, entitys.org_id, entitys.entity_type_id, entitys.entity_name, entitys.user_name,
		entitys.primary_email, entitys.super_user, entitys.entity_leader, entitys.function_role,
		entitys.date_enroled, entitys.is_active, entitys.entity_password, entitys.first_password, entitys.is_picked,
		employees.employee_id, employees.surname, employees.first_name, employees.middle_name,
		employees.date_of_birth, employees.gender, employees.nationality, employees.marital_status, employees.appointment_date, 
		employees.exit_date, employees.contract, employees.contract_period, employees.employment_terms, employees.identity_card, 
		employees.basic_salary, employees.bank_account, employees.language, employees.objective, employees.Active
	FROM entitys INNER JOIN employees ON entitys.entity_id = employees.entity_id;

CREATE VIEW vw_education AS
	SELECT education_class.education_class_id, education_class.education_class_name, entitys.entity_id, entitys.entity_name, 
		education.org_id, education.education_id, education.date_from, education.date_to, education.name_of_school, education.examination_taken,
		education.grades_obtained, education.certificate_number, education.details
	FROM education INNER JOIN education_class ON education.education_class_id = education_class.education_class_id
		INNER JOIN entitys ON education.entity_id = entitys.entity_id;

CREATE VIEW vw_employment AS
	SELECT entitys.entity_id, entitys.entity_name, employment.employment_id, employment.date_from, employment.date_to, 
		employment.org_id, employment.employers_name, employment.position_held, employment.details,
		age(COALESCE(employment.date_to, current_date), employment.date_from) as employment_duration
	FROM employment INNER JOIN entitys ON employment.entity_id = entitys.entity_id;

CREATE VIEW vw_kins AS
	SELECT entitys.entity_id, entitys.entity_name, kin_types.kin_type_id, kin_types.kin_type_name, 
		kins.org_id, kins.kin_id, kins.full_names, kins.date_of_birth, kins.identification, kins.relation, 
		kins.emergency_contact, kins.beneficiary, kins.beneficiary_ps, kins.details
	FROM kins INNER JOIN entitys ON kins.entity_id = entitys.entity_id
	INNER JOIN kin_types ON kins.kin_type_id = kin_types.kin_type_id;

CREATE VIEW vw_cv_seminars AS
	SELECT entitys.entity_id, entitys.entity_name, cv_seminars.cv_seminar_id, cv_seminars.cv_seminar_name, 
		cv_seminars.org_id, cv_seminars.cv_seminar_date, cv_seminars.details
	FROM cv_seminars INNER JOIN entitys ON cv_seminars.entity_id = entitys.entity_id;

CREATE VIEW vw_cv_projects AS
	SELECT entitys.entity_id, entitys.entity_name, cv_projects.cv_projectid, cv_projects.cv_project_name, 
		cv_projects.org_id, cv_projects.cv_project_date, cv_projects.details
	FROM cv_projects INNER JOIN entitys ON cv_projects.entity_id = entitys.entity_id;

CREATE VIEW vw_skill_types AS
	SELECT skill_category.skill_category_id, skill_category.skill_category_name, skill_types.skill_type_id, 
		skill_types.org_id, skill_types.skill_type_name, skill_types.basic, skill_types.intermediate, 
		skill_types.advanced, skill_types.details
	FROM skill_types INNER JOIN skill_category ON skill_types.skill_category_id = skill_category.skill_category_id;

CREATE VIEW vw_skills AS
	SELECT vw_skill_types.skill_category_id, vw_skill_types.skill_category_name, vw_skill_types.skill_type_id, 
		vw_skill_types.skill_type_name, vw_skill_types.basic, vw_skill_types.intermediate, vw_skill_types.advanced, 
		entitys.entity_id, entitys.entity_name, skills.skill_id, skills.skill_level, skills.aquired, skills.training_date, 
		skills.org_id, skills.trained, skills.training_institution, skills.training_cost, skills.details,
		(CASE WHEN skill_level = 1 THEN 'Basic' WHEN skill_level = 2 THEN 'Intermediate' 
			WHEN skill_level = 3 THEN 'Advanced' ELSE 'None' END) as skill_level_name,
		(CASE WHEN skill_level = 1 THEN vw_skill_types.Basic WHEN skill_level = 2 THEN vw_skill_types.Intermediate 
			WHEN skill_level = 3 THEN vw_skill_types.Advanced ELSE 'None' END) as skill_level_details
	FROM skills INNER JOIN entitys ON skills.entity_id = entitys.entity_id
		INNER JOIN vw_skill_types ON skills.skill_type_id = vw_skill_types.skill_type_id;

CREATE VIEW vw_identifications AS
	SELECT entitys.entity_id, entitys.entity_name, identification_types.identification_type_id, identification_types.identification_type_name, 
		identifications.org_id, identifications.identification_id, identifications.identification, identifications.is_active, 
		identifications.starting_from, identifications.expiring_at, identifications.place_of_issue, identifications.details
	FROM identifications INNER JOIN entitys ON identifications.entity_id = entitys.entity_id
	INNER JOIN identification_types ON identifications.identification_type_id = identification_types.identification_type_id;

CREATE VIEW vw_casual_application AS
	SELECT casual_category.casual_category_id, casual_category.casual_category_name, departments.department_id, 
		departments.department_name, casual_application.casual_application_id, casual_application.position,
		casual_application.org_id, casual_application.application_date, casual_application.approved_pay_rate, 
		casual_application.approve_status, casual_application.action_date, casual_application.work_duration, 
		casual_application.details
	FROM casual_application INNER JOIN casual_category ON casual_application.casual_category_id = casual_category.casual_category_id
		INNER JOIN departments ON casual_application.department_id = departments.department_id;

CREATE VIEW vw_casuals AS
	SELECT vw_casual_application.casual_category_id, vw_casual_application.casual_category_name, vw_casual_application.department_id, 
		vw_casual_application.department_name, vw_casual_application.casual_application_id, vw_casual_application.position, 
		vw_casual_application.application_date, vw_casual_application.approved_pay_rate, 
		vw_casual_application.approve_status as application_approve_status, 
		vw_casual_application.action_date as application_action_date, vw_casual_application.work_duration,
		entitys.entity_id, entitys.entity_name, 
		casuals.org_id, casuals.casual_id, casuals.start_date, casuals.end_date, casuals.duration, casuals.pay_rate, 
		casuals.amount_paid, casuals.approve_status, casuals.action_date, casuals.paid, casuals.details
	FROM casuals INNER JOIN vw_casual_application ON casuals.casual_application_id = vw_casual_application.casual_application_id
		INNER JOIN entitys ON casuals.entity_id = entitys.entity_id;

CREATE VIEW vw_employee_leave_types AS
	SELECT entitys.entity_id, entitys.entity_name, leave_types.leave_type_id, leave_types.leave_type_name, 
		leave_types.allowed_leave_days, leave_types.leave_days_span, leave_types.use_type,
		leave_types.month_quota, leave_types.initial_days, leave_types.maximum_carry, leave_types.include_holiday,
		employee_leave_types.org_id, employee_leave_types.employee_leave_type_id, employee_leave_types.leave_balance, 
		employee_leave_types.leave_starting, employee_leave_types.details
	FROM employee_leave_types INNER JOIN entitys ON employee_leave_types.entity_id = entitys.entity_id
		INNER JOIN leave_types ON employee_leave_types.leave_type_id = leave_types.leave_type_id;

CREATE VIEW vw_employee_leave AS
	SELECT entitys.entity_id, entitys.entity_name, leave_types.leave_type_id, leave_types.leave_type_name, 
		contact_entity.entity_name as contact_name,
		employee_leave.org_id, employee_leave.employee_leave_id, 
		employee_leave.leave_from, employee_leave.leave_to, employee_leave.Start_Half_Day, employee_leave.End_Half_Day,
		employee_leave.approve_status, employee_leave.action_date, employee_leave.workflow_table_id,
		employee_leave.completed, employee_leave.Leave_days, employee_leave.narrative, employee_leave.details,
		employee_leave.special_request,
		(CASE WHEN employee_leave.Start_Half_Day = true THEN '02:00 PM'::time ELSE '08:00 AM'::time END) as activity_time,
		(CASE WHEN employee_leave.End_Half_Day = true THEN '02:00 PM'::time ELSE '05:00 PM'::time END) as finish_time,
		date_part('month', employee_leave.leave_from) as leave_month, to_char(employee_leave.leave_from, 'YYYY') as leave_year 
	FROM employee_leave INNER JOIN entitys ON employee_leave.entity_id = entitys.entity_id
	INNER JOIN leave_types ON employee_leave.leave_type_id = leave_types.leave_type_id
	LEFT JOIN entitys as contact_entity ON employee_leave.contact_entity_id = contact_entity.entity_id;

CREATE VIEW vw_leave_work_days AS
	SELECT vw_employee_leave.entity_id, vw_employee_leave.entity_name, vw_employee_leave.leave_type_id, 
		vw_employee_leave.leave_type_name, vw_employee_leave.employee_leave_id, 
		vw_employee_leave.leave_from, vw_employee_leave.leave_to, vw_employee_leave.Start_Half_Day, vw_employee_leave.End_Half_Day,
		leave_work_days.org_id, leave_work_days.leave_work_day_id, leave_work_days.work_date, leave_work_days.half_day, 
		leave_work_days.application_date, leave_work_days.approve_status, leave_work_days.workflow_table_id,
		leave_work_days.action_date, leave_work_days.details
	FROM leave_work_days INNER JOIN vw_employee_leave ON leave_work_days.employee_leave_id = vw_employee_leave.employee_leave_id;

CREATE VIEW vw_intake AS
	SELECT vw_department_roles.department_id, vw_department_roles.department_name, vw_department_roles.department_description, 
		vw_department_roles.department_duties, vw_department_roles.department_role_id, vw_department_roles.department_role_name,
		vw_department_roles.parent_role_name,
		vw_department_roles.job_description, vw_department_roles.job_requirements, vw_department_roles.duties, 
		vw_department_roles.performance_measures, 
		
		locations.location_id, locations.location_name, pay_groups.pay_group_id, pay_groups.pay_group_name, 
		pay_scales.pay_scale_id, pay_scales.pay_scale_name, 
		
		intake.org_id, intake.intake_id, intake.opening_date, intake.closing_date, intake.positions, intake.contract, 
		intake.contract_period, intake.details				
	FROM intake INNER JOIN vw_department_roles ON intake.department_role_id = vw_department_roles.department_role_id
		INNER JOIN locations ON intake.location_id = locations.location_id
		INNER JOIN pay_groups ON intake.pay_group_id = pay_groups.pay_group_id
		INNER JOIN pay_scales ON intake.pay_scale_id = pay_scales.pay_scale_id;

CREATE VIEW vw_applications AS
	SELECT vw_intake.department_id, vw_intake.department_name, vw_intake.department_description, vw_intake.department_duties,
		vw_intake.department_role_id, vw_intake.department_role_name, vw_intake.parent_role_name,
		vw_intake.job_description, vw_intake.job_requirements, vw_intake.duties, vw_intake.performance_measures, 
		vw_intake.intake_id, vw_intake.opening_date, vw_intake.closing_date, vw_intake.positions, 
		entitys.entity_id, entitys.entity_name, 
		
		applications.application_id, applications.employee_id, applications.contract_date, applications.contract_close, 
		applications.contract_start, applications.contract_period, applications.contract_terms, applications.initial_salary, 
		applications.application_date, applications.approve_status, applications.workflow_table_id, applications.action_date, 
		applications.applicant_comments, applications.review, applications.short_listed,
		applications.org_id,

		vw_education_max.education_class_name, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken, 
		vw_education_max.grades_obtained, vw_education_max.certificate_number,

		vw_employment_max.employment_id, vw_employment_max.employers_name, vw_employment_max.position_held,
		vw_employment_max.date_from as emp_date_from, vw_employment_max.date_to as emp_date_to, 
		vw_employment_max.employment_duration, vw_employment_max.employment_experince,
		round((date_part('year', vw_employment_max.employment_duration) + date_part('month', vw_employment_max.employment_duration)/12)::numeric, 1) as emp_duration,
		round((date_part('year', vw_employment_max.employment_experince) + date_part('month', vw_employment_max.employment_experince)/12)::numeric, 1) as emp_experince
		
	FROM applications INNER JOIN entitys ON applications.entity_id = entitys.entity_id
		INNER JOIN vw_intake ON applications.intake_id = vw_intake.intake_id
		LEFT JOIN vw_education_max ON entitys.entity_id = vw_education_max.entity_id
		LEFT JOIN vw_employment_max ON entitys.entity_id = vw_employment_max.entity_id;
		
CREATE VIEW vw_contracting AS
	SELECT vw_intake.department_id, vw_intake.department_name, vw_intake.department_description, vw_intake.department_duties,
		vw_intake.department_role_id, vw_intake.department_role_name, 
		vw_intake.job_description, vw_intake.parent_role_name,
		vw_intake.job_requirements, vw_intake.duties, vw_intake.performance_measures, 
		vw_intake.intake_id, vw_intake.opening_date, vw_intake.closing_date, vw_intake.positions, 
		entitys.entity_id, entitys.entity_name, 
		
		orgs.org_id, orgs.org_name,
		
		contract_types.contract_type_id, contract_types.contract_type_name, contract_types.contract_text,
		contract_status.contract_status_id, contract_status.contract_status_name,
		
		applications.application_id, applications.employee_id, applications.contract_date, applications.contract_close, 
		applications.contract_start, applications.contract_period, applications.contract_terms, applications.initial_salary, 
		applications.application_date, applications.approve_status, applications.workflow_table_id, applications.action_date, 
		applications.applicant_comments, applications.review, 

		vw_education_max.education_class_name, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken, 
		vw_education_max.grades_obtained, vw_education_max.certificate_number,

		vw_employment_max.employment_id, vw_employment_max.employers_name, vw_employment_max.position_held,
		vw_employment_max.date_from as emp_date_from, vw_employment_max.date_to as emp_date_to, 
		
		vw_employment_max.employment_duration, vw_employment_max.employment_experince,
		round((date_part('year', vw_employment_max.employment_duration) + date_part('month', vw_employment_max.employment_duration)/12)::numeric, 1) as emp_duration,
		round((date_part('year', vw_employment_max.employment_experince) + date_part('month', vw_employment_max.employment_experince)/12)::numeric, 1) as emp_experince

	FROM applications INNER JOIN entitys ON applications.employee_id = entitys.entity_id
		INNER JOIN orgs ON applications.org_id = orgs.org_id
		LEFT JOIN vw_intake ON applications.intake_id = vw_intake.intake_id
		LEFT JOIN contract_types ON applications.contract_type_id = contract_types.contract_type_id
		LEFT JOIN contract_status ON applications.contract_status_id = contract_status.contract_status_id
		LEFT JOIN vw_education_max ON entitys.entity_id = vw_education_max.entity_id
		LEFT JOIN vw_employment_max ON entitys.entity_id = vw_employment_max.entity_id;

CREATE VIEW vw_internships AS
	SELECT departments.department_id, departments.department_name, internships.internship_id, internships.opening_date, 
		internships.org_id, internships.closing_date, internships.positions, internships.location, internships.details
	FROM internships INNER JOIN departments ON internships.department_id = departments.department_id;

CREATE VIEW vw_interns AS
	SELECT entitys.entity_id, entitys.entity_name, entitys.primary_email, entitys.primary_telephone, 
		vw_internships.department_id, vw_internships.department_name,
		vw_internships.internship_id, vw_internships.positions, vw_internships.opening_date, vw_internships.closing_date,
		interns.org_id, interns.intern_id, interns.payment_amount, interns.start_date, interns.end_date, 
		interns.application_date, interns.approve_status, interns.action_date, interns.workflow_table_id,
		interns.phone_mobile,
		interns.applicant_comments, interns.review,

		vw_education_max.education_class_name, vw_education_max.date_from, vw_education_max.date_to, 
		vw_education_max.name_of_school, vw_education_max.examination_taken, 
		vw_education_max.grades_obtained, vw_education_max.certificate_number
	FROM interns INNER JOIN entitys ON interns.entity_id = entitys.entity_id
		INNER JOIN vw_internships ON interns.internship_id = vw_internships.internship_id
		LEFT JOIN vw_education_max ON entitys.entity_id = vw_education_max.entity_id;

CREATE VIEW vw_employee_objectives AS
	SELECT entitys.entity_id, entitys.entity_name, 
		employee_objectives.org_id, employee_objectives.employee_objective_id, employee_objectives.employee_objective_name, 
		employee_objectives.objective_date, employee_objectives.approve_status, employee_objectives.workflow_table_id, 
		employee_objectives.application_date, employee_objectives.action_date, employee_objectives.supervisor_comments, 
		employee_objectives.details,
		EXTRACT(YEAR FROM employee_objectives.objective_date) as objective_year
	FROM employee_objectives INNER JOIN entitys ON employee_objectives.entity_id = entitys.entity_id;

CREATE VIEW vw_objective_year AS
	SELECT vw_employee_objectives.org_id, vw_employee_objectives.objective_year
	FROM vw_employee_objectives
	GROUP BY vw_employee_objectives.org_id, vw_employee_objectives.objective_year;

CREATE VIEW vw_objectives AS
	SELECT vw_employee_objectives.entity_id, vw_employee_objectives.entity_name, 
		vw_employee_objectives.employee_objective_id, vw_employee_objectives.employee_objective_name, 
		vw_employee_objectives.objective_date, vw_employee_objectives.approve_status, vw_employee_objectives.workflow_table_id, 
		vw_employee_objectives.application_date, vw_employee_objectives.action_date, vw_employee_objectives.supervisor_comments, 

		objective_types.objective_type_id, objective_types.objective_type_name, 
		objectives.org_id, objectives.objective_id, objectives.date_set, objectives.objective_ps, objectives.objective_name, 
		objectives.objective_completed, objectives.details
	FROM objectives INNER JOIN vw_employee_objectives ON objectives.employee_objective_id = vw_employee_objectives.employee_objective_id
		INNER JOIN objective_types ON objectives.objective_type_id = objective_types.objective_type_id;

CREATE VIEW vw_objective_details AS
	SELECT vw_objectives.entity_id, vw_objectives.entity_name, 
		vw_objectives.employee_objective_id, vw_objectives.employee_objective_name, 
		vw_objectives.objective_date, vw_objectives.approve_status, vw_objectives.workflow_table_id, 
		vw_objectives.application_date, vw_objectives.action_date, vw_objectives.supervisor_comments, 
		vw_objectives.objective_type_id, vw_objectives.objective_type_name, vw_objectives.objective_id, 
		vw_objectives.date_set, vw_objectives.objective_ps, vw_objectives.objective_name, vw_objectives.objective_completed, 

		objective_details.org_id, objective_details.objective_detail_id, objective_details.ln_objective_detail_id, 
		objective_details.objective_detail_name, 
		objective_details.success_indicator, objective_details.achievements, objective_details.resources_required, 
		objective_details.target_date, objective_details.completed, objective_details.completion_date, 
		objective_details.ods_ps, objective_details.ods_points, objective_details.ods_reviewer_points,
		objective_details.details
	FROM objective_details INNER JOIN vw_objectives ON objective_details.objective_id = vw_objectives.objective_id;

CREATE VIEW vw_review_points AS
	SELECT review_category.review_category_id, review_category.review_category_name, 
		review_category.details as review_category_details,
		review_points.org_id, review_points.review_point_id, review_points.review_point_name, 
		review_points.review_points, review_points.details
	FROM review_points INNER JOIN review_category ON review_points.review_category_id = review_category.review_category_id;

CREATE VIEW vw_job_reviews AS
	SELECT entitys.entity_id, entitys.entity_name, job_reviews.job_review_id, job_reviews.total_points, 
		job_reviews.org_id, job_reviews.review_date, job_reviews.review_done, 
		job_reviews.approve_status, job_reviews.workflow_table_id, job_reviews.application_date, job_reviews.action_date,
		job_reviews.recomendation, job_reviews.reviewer_comments, job_reviews.pl_comments, job_reviews.details,
		EXTRACT(YEAR FROM job_reviews.review_date) as review_year
	FROM job_reviews INNER JOIN entitys ON job_reviews.entity_id = entitys.entity_id;

CREATE VIEW vw_review_year AS
	SELECT vw_job_reviews.org_id, vw_job_reviews.review_year
	FROM vw_job_reviews
	GROUP BY vw_job_reviews.org_id, vw_job_reviews.review_year;

CREATE VIEW vw_evaluation_points AS
	SELECT vw_job_reviews.entity_id, vw_job_reviews.entity_name, vw_job_reviews.job_review_id, vw_job_reviews.total_points, 
		vw_job_reviews.review_date, vw_job_reviews.review_done, vw_job_reviews.recomendation, vw_job_reviews.reviewer_comments,
		vw_job_reviews.pl_comments,
		vw_job_reviews.approve_status, vw_job_reviews.workflow_table_id, vw_job_reviews.application_date, vw_job_reviews.action_date,
		vw_review_points.review_category_id, vw_review_points.review_category_name, vw_review_points.review_point_id, 
		vw_review_points.review_point_name, vw_review_points.review_points,	
		
		evaluation_points.org_id, evaluation_points.evaluation_point_id, evaluation_points.points, evaluation_points.grade,  
		evaluation_points.reviewer_points, evaluation_points.reviewer_grade, evaluation_points.reviewer_narrative,
		evaluation_points.narrative, evaluation_points.details
	FROM evaluation_points INNER JOIN vw_job_reviews ON evaluation_points.job_review_id = vw_job_reviews.job_review_id
		INNER JOIN vw_review_points ON evaluation_points.review_point_id = vw_review_points.review_point_id;

CREATE VIEW vw_evaluation_objectives AS
	SELECT vw_job_reviews.entity_id, vw_job_reviews.entity_name, vw_job_reviews.job_review_id, vw_job_reviews.total_points, 
		vw_job_reviews.review_date, vw_job_reviews.review_done, vw_job_reviews.recomendation, vw_job_reviews.reviewer_comments,
		vw_job_reviews.pl_comments,
		vw_job_reviews.approve_status, vw_job_reviews.workflow_table_id, vw_job_reviews.application_date, vw_job_reviews.action_date,
		
		vw_objectives.objective_type_id, vw_objectives.objective_type_name, 
		vw_objectives.objective_id, vw_objectives.date_set, vw_objectives.objective_ps, vw_objectives.objective_name, 
		vw_objectives.objective_completed, vw_objectives.details as objective_details,

		evaluation_points.org_id, evaluation_points.evaluation_point_id, evaluation_points.points,
		evaluation_points.reviewer_points, evaluation_points.reviewer_narrative,
		evaluation_points.narrative, evaluation_points.details
	FROM evaluation_points INNER JOIN vw_job_reviews ON evaluation_points.job_review_id = vw_job_reviews.job_review_id
		INNER JOIN vw_objectives ON evaluation_points.objective_id = vw_objectives.objective_id;
		
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
		
CREATE VIEW vw_career_development AS
	SELECT vw_job_reviews.entity_id, vw_job_reviews.entity_name, vw_job_reviews.job_review_id, vw_job_reviews.total_points, 
		vw_job_reviews.review_date, vw_job_reviews.review_done, vw_job_reviews.recomendation, vw_job_reviews.reviewer_comments,
		vw_job_reviews.pl_comments,
		vw_job_reviews.approve_status, vw_job_reviews.workflow_table_id, vw_job_reviews.application_date, vw_job_reviews.action_date,
		
		career_development.career_development_id, career_development.career_development_name, 
		career_development.details as career_development_details,

		evaluation_points.org_id, evaluation_points.evaluation_point_id, evaluation_points.points,
		evaluation_points.reviewer_points, evaluation_points.reviewer_narrative,
		evaluation_points.narrative, evaluation_points.details
	FROM evaluation_points INNER JOIN vw_job_reviews ON evaluation_points.job_review_id = vw_job_reviews.job_review_id
		INNER JOIN career_development ON evaluation_points.career_development_id = career_development.career_development_id;

CREATE VIEW vw_employee_cases AS
	SELECT case_types.case_type_id, case_types.case_type_name, entitys.entity_id, entitys.entity_name, 
		employee_cases.org_id, employee_cases.employee_case_id, employee_cases.narrative, employee_cases.case_date, 
		employee_cases.complaint, employee_cases.case_action, employee_cases.Completed, employee_cases.details
	FROM employee_cases INNER JOIN case_types ON employee_cases.case_type_id = case_types.case_type_id
		INNER JOIN entitys ON employee_cases.entity_id = entitys.entity_id;

CREATE VIEW vw_employee_trainings AS
	SELECT entitys.entity_id, entitys.entity_name, trainings.training_id, trainings.training_name, trainings.training_cost,
		employee_trainings.org_id, employee_trainings.employee_training_id, employee_trainings.narrative, 
		employee_trainings.completed, employee_trainings.application_date, employee_trainings.approve_status, 
		employee_trainings.action_date, employee_trainings.details
	FROM employee_trainings INNER JOIN entitys ON employee_trainings.entity_id = entitys.entity_id
		INNER JOIN trainings ON employee_trainings.training_id = trainings.training_id;

CREATE VIEW vw_intern_evaluations AS 
	SELECT vw_applicants.entity_id, vw_applicants.sys_country_name, vw_applicants.applicant_name, 
		vw_applicants.applicant_age, vw_applicants.gender_name, vw_applicants.marital_status_name, vw_applicants.language, 
		vw_applicants.objective, vw_applicants.interests, education.date_from, education.date_to, education.name_of_school, 
		education.examination_taken, vw_internships.department_id, vw_internships.department_name, 
		vw_internships.internship_id, vw_internships.positions, vw_internships.opening_date, vw_internships.closing_date, 

		interns.intern_id, interns.payment_amount, interns.start_date, interns.end_date, interns.application_date, 
		interns.approve_status, interns.action_date, interns.workflow_table_id, interns.applicant_comments, interns.review
	FROM vw_applicants JOIN education ON vw_applicants.entity_id = education.entity_id
		JOIN interns ON interns.entity_id = vw_applicants.entity_id
		JOIN vw_internships ON interns.internship_id = vw_internships.internship_id
		JOIN (SELECT education.entity_id, max(education.education_class_id) AS mx_class_id FROM education
			WHERE education.entity_id IS NOT NULL
			GROUP BY education.entity_id) a ON education.entity_id = a.entity_id AND education.education_class_id = a.mx_class_id
		WHERE education.education_class_id > 6
		ORDER BY vw_applicants.entity_id;

------- Functions
INSERT INTO entity_types (org_id, entity_type_id, entity_type_name, entity_role, start_view) VALUES (0, 4, 'Applicant', 'applicant', '10:0');
SELECT pg_catalog.setval('entity_types_entity_type_id_seq', 3, true);

CREATE OR REPLACE FUNCTION get_review_entity(varchar(16)) RETURNS integer AS $$
    SELECT entity_id
	FROM job_reviews
	WHERE (job_review_id = CAST($1 as int));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_review_category(varchar(16)) RETURNS integer AS $$
    SELECT review_category_id
	FROM job_reviews
	WHERE (job_review_id = CAST($1 as int));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION ins_applicants() RETURNS trigger AS $$
DECLARE
	rec RECORD;
BEGIN
	IF (TG_OP = 'INSERT') THEN
		IF(NEW.entity_id IS NULL) THEN
			SELECT org_id INTO rec
			FROM orgs WHERE (is_default = true);

			NEW.entity_id := nextval('entitys_entity_id_seq');

			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, User_name, 
				primary_email, primary_telephone, function_role)
			VALUES (NEW.entity_id, rec.org_id, 4, 
				(NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, '')),
				lower(NEW.Applicant_EMail), lower(NEW.Applicant_EMail), NEW.applicant_phone, 'applicant');
		END IF;

		INSERT INTO sys_emailed (sys_email_id, table_id, table_name)
		VALUES (1, NEW.entity_id, 'applicant');
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE entitys  SET entity_name = (NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, ''))
		WHERE entity_id = NEW.entity_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_applicants BEFORE INSERT OR UPDATE ON applicants
    FOR EACH ROW EXECUTE PROCEDURE ins_applicants();

CREATE OR REPLACE FUNCTION ins_employees() RETURNS trigger AS $$
DECLARE
	v_use_type			integer;
	v_org_sufix 		varchar(4);
	v_first_password	varchar(12);
	v_user_count		integer;
	v_user_name			varchar(120);
BEGIN
	IF (TG_OP = 'INSERT') THEN
		IF(NEW.entity_id IS NULL) THEN
			SELECT org_sufix INTO v_org_sufix
			FROM orgs WHERE (org_id = NEW.org_id);
			
			IF(v_org_sufix is null)THEN v_org_sufix := ''; END IF;

			NEW.entity_id := nextval('entitys_entity_id_seq');

			IF(NEW.Employee_ID is null) THEN
				NEW.Employee_ID := NEW.entity_id;
			END IF;

			v_first_password := first_password();
			v_user_name := lower(v_org_sufix || '.' || NEW.First_name || '.' || NEW.Surname);

			SELECT count(entity_id) INTO v_user_count
			FROM entitys
			WHERE (org_id = NEW.org_id) AND (user_name = v_user_name);
			IF(v_user_count > 0) THEN v_user_name := v_user_name || v_user_count::varchar; END IF;

			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, user_name, function_role, 
				first_password, entity_password)
			VALUES (NEW.entity_id, NEW.org_id, 1, 
				(NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, '')),
				v_user_name, 'staff',
				v_first_password, md5(v_first_password));
		END IF;

		v_use_type := 2;
		IF(NEW.gender = 'M')THEN v_use_type := 3; END IF;

		INSERT INTO employee_leave_types (entity_id, org_id, leave_type_id)
		SELECT NEW.entity_id, NEW.org_id, leave_type_id
		FROM leave_types
		WHERE (use_type = 1) OR (use_type = v_use_type);
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE entitys  SET entity_name = (NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, ''))
		WHERE entity_id = NEW.entity_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_employees BEFORE INSERT OR UPDATE ON employees
    FOR EACH ROW EXECUTE PROCEDURE ins_employees();

CREATE OR REPLACE FUNCTION ins_employee_leave() RETURNS trigger AS $$
BEGIN
	
	IF(NEW.leave_to < NEW.leave_from)THEN
		RAISE EXCEPTION 'Check on your leave dates.';
	END IF;
	IF(NEW.start_half_day = true) AND (NEW.end_half_day = true) AND (NEW.leave_to = NEW.leave_from)THEN
		RAISE EXCEPTION 'The leave half days cannot be done on the same day';
	END IF;

	IF(NEW.approve_status = 'Draft') OR (NEW.leave_days is null)THEN
		NEW.leave_days := get_leave_days(NEW.leave_from, NEW.leave_to, NEW.leave_type_id);

		IF(NEW.start_half_day = true)THEN NEW.leave_days := NEW.leave_days - 0.5; END IF;
		IF(NEW.end_half_day = true)THEN NEW.leave_days := NEW.leave_days - 0.5; END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_employee_leave BEFORE INSERT OR UPDATE ON employee_leave
    FOR EACH ROW EXECUTE PROCEDURE ins_employee_leave();

CREATE OR REPLACE FUNCTION ins_leave_work_days() RETURNS trigger AS $$
BEGIN

	SELECT entity_id INTO NEW.entity_id
	FROM employee_leave
	WHERE (employee_leave_id = NEW.employee_leave_id);

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_leave_work_days BEFORE INSERT ON leave_work_days
    FOR EACH ROW EXECUTE PROCEDURE ins_leave_work_days();
    
CREATE OR REPLACE FUNCTION ins_employee_leave_types() RETURNS trigger AS $$
DECLARE
	reca					RECORD;
	v_months				integer;
BEGIN

	SELECT allowed_leave_days, month_quota, initial_days, maximum_carry INTO reca
	FROM leave_types
	WHERE (leave_type_id = NEW.leave_type_id);

	IF(reca.month_quota > 0)THEN
		v_months := EXTRACT(MONTH FROM NEW.leave_starting) - 1;
		NEW.leave_balance := reca.month_quota * v_months * -1;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_employee_leave_types BEFORE INSERT ON employee_leave_types
    FOR EACH ROW EXECUTE PROCEDURE ins_employee_leave_types();

CREATE OR REPLACE FUNCTION ins_job_reviews() RETURNS trigger AS $$
BEGIN

	INSERT INTO evaluation_points (job_review_id, org_id, review_point_id)
	SELECT NEW.job_review_id, NEW.org_id, review_point_id
	FROM review_points
	WHERE (review_category_id = NEW.review_category_id);

	INSERT INTO evaluation_points (job_review_id, org_id, objective_id)
	SELECT NEW.job_review_id, NEW.org_id, objectives.objective_id
	FROM objectives INNER JOIN employee_objectives ON objectives.employee_objective_id = employee_objectives.employee_objective_id
	WHERE (employee_objectives.entity_id = NEW.entity_id)
		AND (objectives.objective_completed = false);

	INSERT INTO evaluation_points (job_review_id, org_id, career_development_id)
	SELECT NEW.job_review_id, NEW.org_id, career_development_id
	FROM career_development
	WHERE (org_id = NEW.org_id);

	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_job_reviews AFTER INSERT ON job_reviews
    FOR EACH ROW EXECUTE PROCEDURE ins_job_reviews();

CREATE OR REPLACE FUNCTION ins_applications(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_org_id 				integer;
	v_application_id		integer;
	msg 					varchar(120);
BEGIN
	SELECT application_id, org_id INTO v_application_id
	FROM applications 
	WHERE (intake_ID = CAST($1 as int)) AND (entity_ID = CAST($2 as int));

	SELECT org_id INTO v_org_id
	FROM intake 
	WHERE (intake_ID = CAST($1 as int));

	IF v_application_id is null THEN
		INSERT INTO applications (org_id, intake_id, entity_id, approve_status)
		VALUES (v_org_id, CAST($1 as int), CAST($2 as int), 'Completed');
		msg := 'Added Job application';
	ELSE
		msg := 'There is another application for the post.';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ins_interns(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec RECORD;
	msg varchar(120);
BEGIN
	SELECT intern_id, org_id INTO rec
	FROM interns 
	WHERE (internship_ID = CAST($1 as int)) AND (entity_ID = CAST($2 as int));

	IF rec.intern_id is null THEN
		INSERT INTO interns (org_id, internship_id, entity_id, approve_status)
		VALUES (rec.org_id, CAST($1 as int), CAST($2 as int), 'Completed');
		msg := 'Added internship application';
	ELSE
		msg := 'There is another application for the internship.';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upd_applications() RETURNS trigger AS $$
DECLARE
	typeid	integer;
BEGIN
	
	IF (NEW.approve_status = 'Approved') THEN
		NEW.action_date := now();
	END IF;
	IF (NEW.approve_status = 'Rejected') THEN
		NEW.action_date := now();
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON employee_leave
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON leave_work_days
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE TRIGGER upd_applications BEFORE UPDATE ON applications
    FOR EACH ROW EXECUTE PROCEDURE upd_applications();

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON casual_application
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON casuals
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON interns
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON employee_objectives
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON job_reviews
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE OR REPLACE FUNCTION upd_action() RETURNS trigger AS $$
DECLARE
	wfid		INTEGER;
	reca		RECORD;
	tbid		INTEGER;
	iswf		BOOLEAN;
	add_flow	BOOLEAN;
BEGIN

	add_flow := false;
	IF(TG_OP = 'INSERT')THEN
		IF (NEW.approve_status = 'Completed')THEN
			add_flow := true;
		END IF;
	ELSE
		IF(OLD.approve_status = 'Draft') AND (NEW.approve_status = 'Completed')THEN
			add_flow := true;
		END IF;
	END IF;
	
	IF(add_flow = true)THEN
		wfid := nextval('workflow_table_id_seq');
		NEW.workflow_table_id := wfid;

		IF(TG_OP = 'UPDATE')THEN
			IF(OLD.workflow_table_id is not null)THEN
				INSERT INTO workflow_logs (org_id, table_name, table_id, table_old_id)
				VALUES (NEW.org_id, TG_TABLE_NAME, wfid, OLD.workflow_table_id);
			END IF;
		END IF;

		FOR reca IN SELECT workflows.workflow_id, workflows.table_name, workflows.table_link_field, workflows.table_link_id
		FROM workflows INNER JOIN entity_subscriptions ON workflows.source_entity_id = entity_subscriptions.entity_type_id
		WHERE (workflows.table_name = TG_TABLE_NAME) AND (entity_subscriptions.entity_id= NEW.entity_id) LOOP
			iswf := false;
			IF(reca.table_link_field is null)THEN
				iswf := true;
			ELSE
				IF(TG_TABLE_NAME = 'entry_forms')THEN
					tbid := NEW.form_id;
				ELSIF(TG_TABLE_NAME = 'employee_leave')THEN
					tbid := NEW.leave_type_id;
				END IF;
				IF(tbid = reca.table_link_id)THEN
					iswf := true;
				END IF;
			END IF;

			IF(iswf = true)THEN
				INSERT INTO approvals (org_id, workflow_phase_id, table_name, table_id, org_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done)
				SELECT org_id, workflow_phase_id, tg_table_name, wfid, new.entity_id, escalation_days, escalation_hours, approval_level, phase_narrative, 'Approve - ' || phase_narrative
				FROM vw_workflow_entitys
				WHERE (table_name = TG_TABLE_NAME) AND (entity_id = NEW.entity_id) AND (workflow_id = reca.workflow_id)
				ORDER BY approval_level, workflow_phase_id;

				UPDATE approvals SET approve_status = 'Completed' 
				WHERE (table_id = wfid) AND (approval_level = 1);
			END IF;
		END LOOP;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

CREATE OR REPLACE FUNCTION leave_aplication(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_leave_balance		real;
	v_leave_overlap		integer;
	v_approve_status	varchar(16);
	v_table_id			integer;
	rec					RECORD;
	msg 				varchar(120);
BEGIN
	msg := 'Leave applied';

	SELECT leave_types.leave_days_span, employee_leave.entity_id, employee_leave.leave_type_id,
		employee_leave.leave_days, employee_leave.leave_from, employee_leave.leave_to,
		employee_leave.contact_entity_id, employee_leave.narrative
		INTO rec
	FROM leave_types INNER JOIN employee_leave ON leave_types.leave_type_id = employee_leave.leave_type_id
	WHERE (employee_leave.employee_leave_id = CAST($1 as int));

	v_leave_balance := get_leave_balance(rec.entity_id, rec.leave_type_id);

	SELECT count(employee_leave_id) INTO v_leave_overlap
	FROM employee_leave
	WHERE (entity_id = rec.entity_id) AND ((approve_status = 'Completed') OR (approve_status = 'Approved'))
		AND (((leave_from, leave_to) OVERLAPS (rec.leave_from, rec.leave_to)) = true);

	SELECT approve_status INTO v_approve_status
	FROM employee_leave
	WHERE (employee_leave_id = CAST($1 as int));
	
	IF(rec.contact_entity_id is null)THEN
		RAISE EXCEPTION 'You must enter a contact person.';
	ELSIF(v_approve_status <> 'Draft')THEN
		msg := 'Your application is not a draft.';
		RAISE EXCEPTION '%', msg;
	ELSIF(rec.leave_days > rec.leave_days_span)THEN
		msg := 'Days applied for excced the span allowed';
		RAISE EXCEPTION '%', msg;
	ELSIF(v_leave_balance <= 0) THEN
		msg := 'You do not have enough days to apply for this leave';
		RAISE EXCEPTION '%', msg;
	ELSIF(v_leave_overlap > 0) THEN
		msg := 'You have applied for overlaping leave days';
		RAISE EXCEPTION '%', msg;
	ELSE
		UPDATE employee_leave SET approve_status = 'Completed'
		WHERE (employee_leave_id = CAST($1 as int));
		
		SELECT workflow_table_id INTO v_table_id
		FROM employee_leave
		WHERE (employee_leave_id = CAST($1 as int));
		
		UPDATE approvals SET approval_narrative = rec.narrative
		WHERE (table_name = 'employee_leave') AND (table_id = v_table_id);
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION leave_special(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_leave_overlap		integer;
	v_approve_status	varchar(16);
	rec					RECORD;
	msg 				varchar(120);
BEGIN

	SELECT approve_status INTO v_approve_status
	FROM employee_leave
	WHERE (employee_leave_id = CAST($1 as int));

	SELECT leave_types.leave_days_span, employee_leave.entity_id, employee_leave.leave_type_id,
		employee_leave.leave_days, employee_leave.leave_from, employee_leave.leave_to
		INTO rec
	FROM leave_types INNER JOIN employee_leave ON leave_types.leave_type_id = employee_leave.leave_type_id
	WHERE (employee_leave.employee_leave_id = CAST($1 as int));

	IF(v_approve_status <> 'Draft')THEN
		msg := 'Your application is not a draft.';
		RAISE EXCEPTION '%', msg;
	ELSIF($3 = '1') THEN
		SELECT count(employee_leave_id) INTO v_leave_overlap
		FROM employee_leave
		WHERE (entity_id = rec.entity_id) AND ((approve_status = 'Completed') OR (approve_status = 'Approved'))
			AND (((leave_from, leave_to) OVERLAPS (rec.leave_from, rec.leave_to)) = true);

		IF(v_leave_overlap > 0) THEN
			msg := 'You have applied for overlaping leave days';
			RAISE EXCEPTION '%', msg;
		ELSE
			UPDATE employee_leave SET special_request = true
			WHERE (employee_leave_id = CAST($1 as int));

			msg := 'Special request send to HR';
		END IF;
	ELSIF($3 = '2') THEN
		UPDATE employee_leave SET approve_status = 'Completed'
		WHERE (employee_leave_id = CAST($1 as int));

		msg := 'Leave applied';
	ELSIF($3 = '3') THEN
		UPDATE employee_leave SET approve_status = 'Rejected', action_date = now()
		WHERE (employee_leave_id = CAST($1 as int));

		msg := 'Leave rejected';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION job_review_check(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_objective_ps		real;
	sum_ods_ps			real;
	v_point_check		integer;
	rec					RECORD;
	msg 				varchar(120);
BEGIN
	
	SELECT sum(objectives.objective_ps) INTO v_objective_ps
	FROM objectives INNER JOIN evaluation_points ON evaluation_points.objective_id = objectives.objective_id
	WHERE (evaluation_points.job_review_id = CAST($1 as int));
	SELECT sum(ods_ps) INTO sum_ods_ps
	FROM objective_details INNER JOIN evaluation_points ON evaluation_points.objective_id = objective_details.objective_id
	WHERE (evaluation_points.job_review_id = CAST($1 as int));
	
	SELECT evaluation_points.evaluation_point_id INTO v_point_check
	FROM objectives INNER JOIN evaluation_points ON evaluation_points.objective_id = objectives.objective_id
	WHERE (evaluation_points.job_review_id = CAST($1 as int))
		AND (objectives.objective_ps > 0) AND (evaluation_points.points = 0);
	
	IF(sum_ods_ps is null)THEN
		sum_ods_ps := 100;
	END IF;
	IF(sum_ods_ps = 0)THEN
		sum_ods_ps := 100;
	END IF;

	IF(v_objective_ps = 100) AND (sum_ods_ps = 100)THEN
		UPDATE job_reviews SET approve_status = 'Completed'
		WHERE (job_review_id = CAST($1 as int));

		msg := 'Review Applied';
	ELSIF(sum_ods_ps <> 100)THEN
		msg := 'Objective details % must add up to 100';
		RAISE EXCEPTION '%', msg;
	ELSIF(v_point_check is not null)THEN
		msg := 'All objective evaluations points must be between 1 to 4';
		RAISE EXCEPTION '%', msg;
	ELSE
		msg := 'Objective % must add up to 100';
		RAISE EXCEPTION '%', msg;
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION objectives_review(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_objective_ps		real;
	sum_ods_ps			real;
	rec					RECORD;
	msg 				varchar(120);
BEGIN

	SELECT sum(objectives.objective_ps) INTO v_objective_ps
	FROM objectives
	WHERE (objectives.employee_objective_id = CAST($1 as int));
	SELECT sum(objective_details.ods_ps) INTO sum_ods_ps
	FROM objective_details INNER JOIN objectives ON objective_details.objective_id = objectives.objective_id
	WHERE (objectives.employee_objective_id = CAST($1 as int));
	
	IF(sum_ods_ps is null)THEN
		sum_ods_ps := 100;
	END IF;
	IF(sum_ods_ps = 0)THEN
		sum_ods_ps := 100;
	END IF;

	IF(v_objective_ps = 100) AND (sum_ods_ps = 100)THEN
		UPDATE employee_objectives SET approve_status = 'Completed'
		WHERE (employee_objective_id = CAST($1 as int));

		msg := 'Objectives Review Applied';	
	ELSIF(sum_ods_ps <> 100)THEN
		msg := 'Objective details % must add up to 100';
		RAISE EXCEPTION '%', msg;
	ELSE
		msg := 'Objective % must add up to 100';
		RAISE EXCEPTION '%', msg;
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_leave_days(date, date, integer) RETURNS real AS $$
DECLARE
	v_day			date;
	v_holiday		integer;
	v_holidays		integer;
	rec 			RECORD;
	ans 			real;
BEGIN
	ans := 0.0;
	v_day := $1;

	SELECT leave_type_id, allowed_leave_days, leave_days_span, month_quota, initial_days, 
		maximum_carry, include_holiday, 
		include_mon, include_tue, include_wed, include_thu, include_fri, include_sat, include_sun
		INTO rec
	FROM leave_types 
	WHERE (leave_type_id = $3);

	v_holidays := 0;

	LOOP
		IF(EXTRACT(isodow FROM v_day)::integer = 1) AND (rec.include_mon = true) THEN ans := ans + 1; END IF;
		IF(EXTRACT(isodow FROM v_day)::integer = 2) AND (rec.include_tue = true) THEN ans := ans + 1; END IF;
		IF(EXTRACT(isodow FROM v_day)::integer = 3) AND (rec.include_wed = true) THEN ans := ans + 1; END IF;
		IF(EXTRACT(isodow FROM v_day)::integer = 4) AND (rec.include_thu = true) THEN ans := ans + 1; END IF;
		IF(EXTRACT(isodow FROM v_day)::integer = 5) AND (rec.include_fri = true) THEN ans := ans + 1; END IF;
		IF(EXTRACT(isodow FROM v_day)::integer = 6) AND (rec.include_sat = true) THEN ans := ans + 1; END IF;
		IF(EXTRACT(isodow FROM v_day)::integer = 7) AND (rec.include_sun = true) THEN ans := ans + 1; END IF;

		IF(rec.include_holiday = false)THEN
			SELECT count(holiday_id) INTO v_holiday
			FROM holidays
			WHERE (holiday_date = v_day);
			v_holidays := v_holidays + v_holiday;
		END IF;

		v_day := v_day + 1;
		EXIT WHEN $2 < v_day;
	END LOOP;

	ans := ans - CAST(v_holidays as real);

	return ans;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_shortlist(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg		 				varchar(120);
BEGIN

	IF ($3 = '1') THEN
		UPDATE applications SET short_listed = 1
		WHERE application_id = CAST($1 as int);
		msg := 'Added to short list';
	ELSIF ($3 = '2') THEN
		UPDATE applications SET short_listed = o
		WHERE application_id = CAST($1 as int);
		msg := 'Removed from short list';
	END IF;
	
	return msg;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION add_employee(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_application_id		integer;
	v_entity_id				integer;
	v_employee_id			integer;
	msg		 				varchar(120);
BEGIN

	v_application_id := CAST($1 as int);
	SELECT employees.entity_id, applications.employee_id INTO v_entity_id, v_employee_id
	FROM applications LEFT JOIN employees ON applications.entity_id = employees.entity_id
	WHERE (application_id = v_application_id);

	IF(v_employee_id is null) AND (v_entity_id is null)THEN
		INSERT INTO employees (org_id, currency_id, bank_branch_id,
			department_role_id, pay_scale_id, pay_group_id, location_id,  
			person_title, surname, first_name, middle_name,
			date_of_birth, gender, nationality, marital_status,
			picture_file, identity_card, language, interests, objective,
			contract, appointment_date, current_appointment, contract_period,
			basic_salary)

		SELECT orgs.org_id, orgs.currency_id, 0,
			intake.department_role_id, intake.pay_scale_id, intake.pay_group_id, intake.location_id,
			applicants.person_title, applicants.surname, applicants.first_name, applicants.middle_name,  
			applicants.date_of_birth, applicants.gender, applicants.nationality, applicants.marital_status, 
			applicants.picture_file, applicants.identity_card, applicants.language, applicants.interests, applicants.objective,
			
			
			intake.contract, applications.contract_date, applications.contract_start, 
			applications.contract_period, applications.initial_salary
		FROM orgs INNER JOIN applicants ON orgs.org_id = applicants.org_id
			INNER JOIN applications ON applicants.entity_id = applications.entity_id
			INNER JOIN intake ON applications.intake_id = intake.intake_id
			
		WHERE (applications.application_id = v_application_id);
		
		UPDATE applications SET employee_id = currval('entitys_entity_id_seq'), approve_status = 'Approved'
		WHERE (application_id = v_application_id);
			
		msg := 'Employee added';
	ELSIF(v_employee_id is null)THEN
		UPDATE applications SET employee_id = v_employee_id, 
			department_role_id = intake.department_role_id, pay_scale_id = intake.pay_scale_id, 
			pay_group_id = intake.pay_group_id, location_id = intake.location_id
		FROM intake  
		WHERE (applications.intake_id = intake.intake_id) AND (applications.application_id = v_application_id);
		
		msg := 'Employee details updated';
	ELSE
		msg := 'Employeed already added to the system';
	END IF;
	

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_approval_date(integer) RETURNS date AS $$
DECLARE
	v_workflow_table_id		integer;
	v_date					date;
BEGIN
	v_workflow_table_id := $1;

	SELECT action_date INTO v_date
	FROM approvals 
	WHERE (approvals.table_id = v_workflow_table_id) AND (approvals.workflow_phase_id = 6);

	return v_date;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_approver(integer) RETURNS varchar(120) AS $$
DECLARE
	v_workflow_table_id		integer;
	v_approver				varchar(120);
BEGIN
	v_approver :='';
	v_workflow_table_id := $1;

	SELECT entitys.entity_name INTO v_approver
	FROM entitys 
	INNER JOIN approvals ON entitys.entity_id = approvals.app_entity_id
	WHERE (approvals.table_id = v_workflow_table_id) AND (approvals.workflow_phase_id = 6);

	return v_approver;
END;
$$ LANGUAGE plpgsql;

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

CREATE OR REPLACE FUNCTION ins_objectives() RETURNS trigger AS $$
DECLARE
	sum_objective_ps			real;
	sum_ods_ps					real;
BEGIN

	SELECT sum(objective_ps) INTO sum_objective_ps
	FROM objectives
	WHERE (employee_objective_id = NEW.employee_objective_id);
	SELECT sum(ods_ps) INTO sum_ods_ps
	FROM objective_details
	WHERE (objective_id = NEW.objective_id) AND (ods_ps is not null);
	
	IF(sum_objective_ps > 100)THEN
		RAISE EXCEPTION 'Your % objectives are more than 100', '%';
	END IF;
	IF(sum_ods_ps > NEW.objective_ps)THEN
		RAISE EXCEPTION 'The % objective details are more than the overall objective details', '%';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_objectives AFTER INSERT OR UPDATE ON objectives
    FOR EACH ROW EXECUTE PROCEDURE ins_objectives();
    
CREATE OR REPLACE FUNCTION ins_objective_details() RETURNS trigger AS $$
DECLARE
	v_objective_ps				real;
	sum_ods_ps					real;
BEGIN

	IF(NEW.ln_objective_detail_id is not null)THEN
		SELECT objective_id INTO NEW.objective_id
		FROM objective_details
		WHERE objective_detail_id = NEW.ln_objective_detail_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
	
CREATE TRIGGER ins_objective_details BEFORE INSERT OR UPDATE ON objective_details
    FOR EACH ROW EXECUTE PROCEDURE ins_objective_details();
    
CREATE OR REPLACE FUNCTION upd_objective_details() RETURNS trigger AS $$
DECLARE
	v_objective_ps				real;
	sum_ods_ps					real;
BEGIN
	
	SELECT objective_ps INTO v_objective_ps
	FROM objectives
	WHERE (objective_id = NEW.objective_id);
	SELECT sum(ods_ps) INTO sum_ods_ps
	FROM objective_details
	WHERE (objective_id = NEW.objective_id) AND (ods_ps is not null) AND (ln_objective_detail_id is null);
		
	IF(sum_ods_ps > v_objective_ps)THEN
		RAISE EXCEPTION 'The % objective details are more than the overall objective details', '%';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_objective_details AFTER INSERT OR UPDATE ON objective_details
    FOR EACH ROW EXECUTE PROCEDURE upd_objective_details();

CREATE OR REPLACE FUNCTION upd_reviews(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	v_approve_status	varchar(16);
	v_eo_id				integer;
	v_jr_id				integer;
	v_ep_id				integer;

	msg 				varchar(120);
BEGIN

	IF($3 = '1') THEN
		UPDATE employee_objectives SET approve_status = 'Draft'
		WHERE employee_objective_id	= CAST($1 as integer);

		msg := 'Objective Reviews opened';
	ELSIF($3 = '2') THEN
		UPDATE job_reviews SET approve_status = 'Draft'
		WHERE job_review_id	= CAST($1 as integer);

		msg := 'Perfomance Reviews opened';
	ELSIF($3 = '3') THEN
		v_eo_id := CAST($1 as int);
		SELECT approve_status INTO v_approve_status
		FROM employee_objectives WHERE employee_objective_id = v_eo_id;
		
		SELECT evaluation_point_id INTO v_ep_id
		FROM evaluation_points INNER JOIN objectives ON evaluation_points.objective_id = objectives.objective_id
		WHERE (objectives.employee_objective_id = v_eo_id);
		
		IF(v_ep_id is not null)THEN
			msg := 'You need to delete the objectives linked to the review';
		ELSIF(v_approve_status = 'Draft')THEN
			DELETE FROM objective_details WHERE objective_id IN
			(SELECT objective_id FROM objectives WHERE employee_objective_id = v_eo_id);
			DELETE FROM objectives WHERE employee_objective_id = v_eo_id;
			DELETE FROM employee_objectives WHERE employee_objective_id = v_eo_id;
		
			msg := 'Delete objective defination';
		ELSE
			msg := 'You can only delete a draft objective defination.';
		END IF;
	ELSIF($3 = '4') THEN
		v_jr_id := CAST($1 as int);
		SELECT approve_status INTO v_approve_status
		FROM job_reviews WHERE job_review_id = v_jr_id;
		
		IF(v_approve_status = 'Draft')THEN
			DELETE FROM evaluation_points WHERE job_review_id = v_jr_id;
			DELETE FROM job_reviews WHERE job_review_id = v_jr_id;
		
			msg := 'Delete job review';
		ELSE
			msg := 'You can only delete a draft job review.';
		END IF;
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;
