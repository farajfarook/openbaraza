CREATE TABLE sys_continents (
	sys_continent_id		char(2) primary key,
	sys_continent_name		varchar(120) unique
);

CREATE TABLE sys_countrys (
	sys_country_id			char(2) primary key,
	sys_continent_id		char(2) references sys_continents,
	sys_country_code		varchar(3),
	sys_country_number		varchar(3),
	sys_phone_code			varchar(3),
	sys_country_name		varchar(120) unique,
	sys_currency_name		varchar(50),
	sys_currency_cents		varchar(50),
	sys_currency_code		varchar(3),
	sys_currency_exchange	real
);
CREATE INDEX sys_countrys_sys_continent_id ON sys_countrys (sys_continent_id);

CREATE TABLE sys_audit_trail (
	sys_audit_trail_id		integer primary key,
	user_id					varchar(50) not null,
	user_ip					varchar(50),
	change_date				timestamp default CURRENT_TIMESTAMP not null,
	table_name				varchar(50) not null,
	record_id				varchar(50) not null,
	change_type				varchar(50) not null,
	narrative				varchar(240)
);
CREATE SEQUENCE seq_sys_audit_trail_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_audit_trail BEFORE INSERT ON sys_audit_trail
for each row 
begin     
	if inserting then 
		if :NEW.sys_audit_trail_id is null then
			SELECT seq_sys_audit_trail_id.nextval into :NEW.sys_audit_trail_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sys_audit_details (
	sys_audit_detail_id		integer primary key,
	sys_audit_trail_id		integer references sys_audit_trail,
	new_value				clob
);
CREATE INDEX sys_audit_sys_audit_trail_id ON sys_audit_details (sys_audit_trail_id);
CREATE SEQUENCE seq_sys_audit_detail_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_audit_details BEFORE INSERT ON sys_audit_details
for each row 
begin     
	if inserting then 
		if :NEW.sys_audit_detail_id is null then
			SELECT seq_sys_audit_detail_id.nextval into :NEW.sys_audit_detail_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sys_queries (
	sys_query_name			varchar(50) primary key,
	query_date				timestamp default CURRENT_TIMESTAMP not null,
	query_text				clob,
	query_params			clob
);

CREATE TABLE sys_errors (
	sys_error_id			integer primary key,
	sys_error				varchar(240) not null,
	error_message			clob not null
);
CREATE SEQUENCE seq_sys_error_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_errors BEFORE INSERT ON sys_errors
for each row 
begin     
	if inserting then 
		if :NEW.sys_error_id is null then
			SELECT seq_sys_error_id.nextval into :NEW.sys_error_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sys_news (
	sys_news_id				integer primary key,
	sys_news_group			integer,
	sys_news_title			varchar(240) not null,
	publish					char(1) default '0' not null,
	details					clob
);
CREATE SEQUENCE seq_sys_news_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_news BEFORE INSERT ON sys_news
for each row 
begin     
	if inserting then 
		if :NEW.sys_news_id is null then
			SELECT seq_sys_news_id.nextval into :NEW.sys_news_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sys_passwords (
	sys_password_id			integer primary key,
	sys_user_name			varchar(240) not null,
	password_sent			char(1) default '0' not null
);
CREATE SEQUENCE seq_sys_password_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_passwords BEFORE INSERT ON sys_passwords
for each row 
begin     
	if inserting then 
		if :NEW.sys_password_id is null then
			SELECT seq_sys_password_id.nextval into :NEW.sys_password_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sys_files (
	sys_file_id				integer primary key,
	table_id				integer,
	table_name				varchar(50),
	file_name				varchar(240),
	file_type				varchar(50),
	details					clob
);
CREATE INDEX sys_files_table_id ON sys_files (table_id);
CREATE SEQUENCE seq_sys_file_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_files BEFORE INSERT ON sys_files
for each row 
begin     
	if inserting then 
		if :NEW.sys_file_id is null then
			SELECT seq_sys_file_id.nextval into :NEW.sys_file_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE address_types (
	address_type_id			integer primary key,
	address_type_name		varchar(50)
);

CREATE TABLE address (
	address_id				integer primary key,
	address_name			varchar(120),
	address_type_id			integer references address_types,
	sys_country_id			char(2) references sys_countrys,
	table_name				varchar(32),
	table_id				integer,
	post_office_box			varchar(50),
	postal_code				varchar(12),
	premises_floor			varchar(50),
	premises				varchar(120),
	street					varchar(120),
	town					varchar(50),
	phone_number			varchar(150),
	extension				varchar(15),
	mobile					varchar(150),
	fax						varchar(150),
	email					varchar(120),
	website					varchar(120),
	is_default				char(1),
	first_password			varchar(32),
	details					clob
);
CREATE INDEX address_sys_country_id ON address (sys_country_id);
CREATE INDEX address_address_type_id ON address (address_type_id);
CREATE INDEX address_table_name ON address (table_name);
CREATE INDEX address_table_id ON address (table_id);
CREATE SEQUENCE seq_address_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_address BEFORE INSERT ON address
for each row 
begin     
	if inserting then 
		if :NEW.address_id is null then
			SELECT seq_address_id.nextval into :NEW.address_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE orgs (
	org_id					integer primary key,
	org_name				varchar(50),
	is_default				char(1) default '1' not null,
	is_active				char(1) default '1' not null,
	logo					varchar(50),
	details					clob
);
CREATE SEQUENCE seq_org_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_orgs BEFORE INSERT ON orgs
for each row 
begin     
	if inserting then 
		if :NEW.org_id is null then
			SELECT seq_org_id.nextval into :NEW.org_id from dual;
		end if;
	end if; 
end;
/

INSERT INTO orgs (org_id, org_name, logo) 
VALUES (0, 'default', 'logo.png');

CREATE TABLE entity_types (
	entity_type_id			integer primary key,
	entity_type_name		varchar(50) unique,
	entity_role				varchar(240),
	use_key					integer default 0 not null,
	group_email				varchar(120),
	Description				clob,
	Details					clob
);
CREATE SEQUENCE seq_entity_type_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_entity_types BEFORE INSERT ON entity_types
for each row 
begin     
	if inserting then 
		if :NEW.entity_type_id is null then
			SELECT seq_entity_type_id.nextval into :NEW.entity_type_id from dual;
		end if;
	end if; 
end;
/

INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role) VALUES (0, 'Users', 'user');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role) VALUES (1, 'Staff', 'staff');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role) VALUES (2, 'Client', 'client');
INSERT INTO entity_types (entity_type_id, entity_type_name, entity_role) VALUES (3, 'Supplier', 'supplier');

CREATE TABLE entitys (
	entity_id				integer primary key,
	org_id					integer references orgs,
	entity_type_id			integer references entity_types,
	entity_name				varchar(120) not null,
	user_name				varchar(120),
	primary_email			varchar(120),
	super_user				char(1) default '0' not null,
	entity_leader			char(1) default '0',
	function_role			varchar(240),
	date_enroled			timestamp default CURRENT_TIMESTAMP,
	is_active				char(1) default '1',
	entity_password			varchar(32) default 'enter' not null,
	first_password			varchar(32) default 'enter' not null,
	details					clob,
	UNIQUE(org_id, User_name)
);
CREATE INDEX entitys_org_id ON entitys (org_id);
CREATE SEQUENCE seg_entity_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_entitys BEFORE INSERT ON entitys
for each row 
begin     
	if inserting then 
		if :NEW.entity_id is null then
			SELECT seg_entity_id.nextval into :NEW.entity_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO entitys (entity_id, org_id, entity_type_id, user_name, entity_name, Entity_Leader, Super_User)  
VALUES (0, 0, 0, 'root', 'root', '1', '1');

CREATE TABLE subscription_levels (
	subscription_level_id	integer primary key,
	subscription_level_name	varchar(50),
	details					clob
);
INSERT INTO subscription_levels (subscription_level_id, subscription_level_name) VALUES (0, 'Basic');
INSERT INTO subscription_levels (subscription_level_id, subscription_level_name) VALUES (1, 'Manager');
INSERT INTO subscription_levels (subscription_level_id, subscription_level_name) VALUES (2, 'Consumer');

CREATE TABLE entity_subscriptions (
	entity_subscription_id	integer primary key,
	entity_type_id			integer references entity_types,
	entity_id				integer references entitys,
	subscription_level_id	integer references subscription_levels,
	details					clob,
	UNIQUE(entity_id, entity_type_id)
);
CREATE INDEX entity_sub_entity_type_id ON entity_subscriptions (entity_type_id);
CREATE INDEX entity_sub_entity_id ON entity_subscriptions (entity_id);
CREATE INDEX entity_sub_sub_level_id ON entity_subscriptions (subscription_level_id);
CREATE SEQUENCE seq_entity_subscription_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_entity_subscriptions BEFORE INSERT ON entity_subscriptions
for each row 
begin     
	if inserting then 
		if :NEW.entity_subscription_id is null then
			SELECT seq_entity_subscription_id.nextval into :NEW.entity_subscription_id from dual;
		end if;
	end if; 
end;
/
INSERT INTO Entity_subscriptions (Entity_subscription_id, entity_type_id, entity_id, subscription_level_id)  
VALUES (0, 0, 0, 0);

CREATE TABLE sys_logins (
	sys_login_id			integer primary key,
	entity_id				integer references entitys,
	login_time				timestamp default CURRENT_TIMESTAMP,
	login_ip				varchar(64),
	narrative				varchar(240)
);
CREATE INDEX sys_logins_entity_id ON sys_logins (entity_id);
CREATE SEQUENCE seq_sys_login_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_logins BEFORE INSERT ON sys_logins
for each row 
begin     
	if inserting then 
		if :NEW.sys_login_id is null then
			SELECT seq_sys_login_id.nextval into :NEW.sys_login_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sys_emails (
	sys_email_id			integer primary key,
	sys_email_name			varchar(50),
	title					varchar(240) not null,
	details					clob
);
CREATE SEQUENCE seq_sys_email_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_emails BEFORE INSERT ON sys_emails
for each row 
begin     
	if inserting then 
		if :NEW.sys_email_id is null then
			SELECT seq_sys_email_id.nextval into :NEW.sys_email_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sys_emailed (
	sys_emailed_id			integer primary key,
	sys_email_id			integer references sys_emails,
	table_id				integer,
	table_name				varchar(50),
	email_type				integer default 1 not null,
	emailed					char(1) default '0' not null,
	narrative				varchar(240)
);
CREATE INDEX sys_emailed_sys_email_id ON sys_emailed (sys_email_id);
CREATE INDEX sys_emailed_table_id ON sys_emailed (table_id);
CREATE SEQUENCE seq_sys_emailed_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sys_emailed BEFORE INSERT ON sys_emailed
for each row 
begin     
	if inserting then 
		if :NEW.sys_emailed_id is null then
			SELECT seq_sys_emailed_id.nextval into :NEW.sys_emailed_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE workflows (
	workflow_id				integer primary key,
	source_entity_id		integer references entity_types,
	workflow_name			varchar(240) not null,
	table_name				varchar(64),
	table_link_field		varchar(64),
	table_link_id			integer,
	approve_email			clob,
	reject_email			clob,
	details					clob
);
CREATE INDEX wf_source_entity_id ON workflows (source_entity_id);
CREATE SEQUENCE seq_workflow_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_workflows BEFORE INSERT ON workflows
for each row 
begin     
	if inserting then 
		if :NEW.workflow_id is null then
			SELECT seq_workflow_id.nextval into :NEW.workflow_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE workflow_phases (
	workflow_phase_id		integer primary key,
	workflow_id				integer references workflows,
	approval_entity_id		integer references entity_types,
	approval_level			integer default 1 not null,
	return_level			integer default 1 not null,
	escalation_days			integer default 0 not null,
	escalation_hours		integer default 3 not null,
	required_approvals		integer default 1 not null,
	notice					char(1) default '0' not null,
	advice					char(1) default '0' not null,
	phase_narrative			varchar(240),
	notice_email			clob,
	advice_email			clob,
	details					clob
);
CREATE INDEX wf_phases_workflow_id ON workflow_phases (workflow_id);
CREATE INDEX wf_phases_approval_entity_id ON workflow_phases (approval_entity_id);
CREATE SEQUENCE seq_workflow_phase_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_workflow_phases BEFORE INSERT ON workflow_phases
for each row 
begin     
	if inserting then 
		if :NEW.workflow_phase_id is null then
			SELECT seq_workflow_phase_id.nextval into :NEW.workflow_phase_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE checklists (
	checklist_id			integer primary key,
	workflow_phase_id		integer references workflow_phases,
	checklist_number		integer,
	manditory				char(1) default '0' not null,
	requirement				clob,
	details					clob
);
CREATE INDEX cl_workflow_phase_id ON checklists (workflow_phase_id);
CREATE SEQUENCE seq_checklist_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_checklists BEFORE INSERT ON checklists
for each row 
begin     
	if inserting then 
		if :NEW.checklist_id is null then
			SELECT seq_checklist_id.nextval into :NEW.checklist_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE approvals (
	approval_id				integer primary key,
	workflow_phase_id		integer references workflow_phases,
	org_entity_id			integer references entitys,
	app_entity_id			integer references entitys,
	approval_level			integer default 1 not null,
	forward_id				integer,
	table_name				varchar(64),
	table_id				integer,
	escalation_days			integer default 0 not null,
	escalation_hours		integer default 3 not null,
	escalation_time			integer default 3 not null,
	application_date		timestamp default CURRENT_TIMESTAMP not null,
	completion_date			timestamp,
	action_date				timestamp,
	approve_status			varchar(16) default 'Draft' not null,
	approval_narrative		varchar(240),
	to_be_done				clob,
	what_is_done			clob,
	review_advice			clob,
	details					clob
);
CREATE INDEX a_workflow_phase_id ON approvals (workflow_phase_id);
CREATE INDEX a_org_entity_id ON approvals (org_entity_id);
CREATE INDEX a_app_entity_id ON approvals (app_entity_id);
CREATE INDEX a_forward_id ON approvals (forward_id);
CREATE INDEX a_table_id ON approvals (table_id);
CREATE INDEX a_approve_status ON approvals (approve_status);
CREATE SEQUENCE seq_approval_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_approvals BEFORE INSERT ON approvals
for each row 
begin     
	if inserting then 
		if :NEW.approval_id is null then
			SELECT seq_approval_id.nextval into :NEW.approval_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE approval_checklists (
	approval_checklist_id	integer primary key,
	approval_id				integer references approvals,
	checklist_id			integer references checklists,
	requirement				text,
	manditory				char(1) default '0' not null,
	done					char(1) default '0' not null,
	narrative				varchar(320)
);
CREATE INDEX ac_approval_id ON approval_checklists (approval_id);
CREATE INDEX ac_checklist_id ON approval_checklists (checklist_id);
CREATE SEQUENCE seq_approval_checklist_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_approval_checklists BEFORE INSERT ON approval_checklists
for each row 
begin     
	if inserting then 
		if :NEW.approval_checklist_id is null then
			SELECT seq_approval_checklist_id.nextval into :NEW.approval_checklist_id from dual;
		end if;
	end if; 
end;
/

CREATE SEQUENCE workflow_table_id_seq;

CREATE VIEW vw_sys_emailed AS
	SELECT sys_emails.sys_email_id, sys_emails.sys_email_name, sys_emails.title, sys_emails.details,
		sys_emailed.sys_emailed_id, sys_emailed.table_id, sys_emailed.table_name, sys_emailed.email_level,
		sys_emailed.emailed, sys_emailed.narrative
	FROM sys_emails INNER JOIN sys_emailed ON sys_emails.sys_email_id = sys_emailed.sys_email_id;

CREATE VIEW vw_sys_countrys AS
	SELECT sys_continents.sys_continent_id, sys_continents.sys_continent_name,
		sys_countrys.sys_country_id, sys_countrys.sys_country_code, sys_countrys.sys_country_number, 
		sys_countrys.sys_phone_code, sys_countrys.sys_country_name
	FROM sys_continents INNER JOIN sys_countrys ON sys_continents.sys_continent_id = sys_countrys.sys_continent_id;

CREATE VIEW vw_address AS
	SELECT sys_countrys.sys_country_id, sys_countrys.sys_country_name, address.address_id, address.address_name, address.table_name,
		address.table_id, address.post_office_box, address.postal_code, address.premises, address.street, address.town, 
		address.phone_number, address.extension, address.mobile, address.fax, address.email, address.is_default, address.website, address.details
	FROM address INNER JOIN sys_countrys ON address.sys_country_id = sys_countrys.sys_country_id;

CREATE VIEW vw_orgs AS
	SELECT orgs.org_id, orgs.org_name, orgs.is_default, orgs.is_active, orgs.logo, orgs.details,
		vw_address.sys_country_id, vw_address.sys_country_name, vw_address.address_id, vw_address.table_name,
		vw_address.post_office_box, vw_address.postal_code, vw_address.premises, vw_address.street, vw_address.town, 
		vw_address.phone_number, vw_address.extension, vw_address.mobile, vw_address.fax, vw_address.email, vw_address.website
	FROM orgs LEFT JOIN vw_address ON (orgs.org_id = vw_address.table_id)
	WHERE (vw_address.table_name = 'orgs') OR (vw_address.table_name is null);

CREATE VIEW vw_entitys AS
	SELECT orgs.org_id, orgs.org_name, vw_address.address_id, vw_address.address_name,
		vw_address.sys_country_id, vw_address.sys_country_name, vw_address.table_name, vw_address.is_default,
		vw_address.post_office_box, vw_address.postal_code, vw_address.premises, vw_address.street, vw_address.town, 
		vw_address.phone_number, vw_address.extension, vw_address.mobile, vw_address.fax, vw_address.email, vw_address.website,
		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.Super_User, entitys.Entity_Leader, 
		entitys.Date_Enroled, entitys.Is_Active, entitys.entity_password, entitys.first_password, entitys.Details,
		entity_types.entity_type_id, entity_types.entity_type_name, entitys.primary_email,
		entity_types.entity_role, entity_types.group_email, entity_types.use_key
	FROM (entitys LEFT JOIN vw_address ON entitys.entity_id = vw_address.table_id)
		INNER JOIN orgs ON entitys.org_id = orgs.org_id
		INNER JOIN entity_types ON entitys.entity_type_id = entity_types.entity_type_id 
	WHERE ((vw_address.table_name = 'entitys') OR (vw_address.table_name is null));

CREATE VIEW vw_entity_subscriptions AS
	SELECT entity_types.entity_type_id, entity_types.entity_type_name, entitys.entity_id, entitys.entity_name, 
		entity_subscriptions.entity_subscription_id, entity_subscriptions.details
	FROM entity_subscriptions INNER JOIN entity_types ON entity_subscriptions.entity_type_id = entity_types.entity_type_id
	INNER JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id;

CREATE VIEW vw_workflows AS
	SELECT entity_types.entity_type_id as source_entity_id, entity_types.entity_type_name as source_entity_name, 
		workflows.workflow_id, workflows.workflow_name, workflows.table_name, workflows.table_link_field, 
		workflows.table_link_id, workflows.approve_email, workflows.reject_email, workflows.details
	FROM workflows INNER JOIN entity_types ON workflows.source_entity_id = entity_types.entity_type_id;

CREATE VIEW vw_workflow_phases AS
	SELECT vw_workflows.source_entity_id, vw_workflows.source_entity_name, vw_workflows.workflow_id, 
		vw_workflows.workflow_name, vw_workflows.table_name, vw_workflows.table_link_field, vw_workflows.table_link_id, 
		vw_workflows.approve_email, vw_workflows.reject_email,
		entity_types.entity_type_id as approval_entity_id, entity_types.entity_type_name as approval_entity_name, 
		workflow_phases.workflow_phase_id, workflow_phases.approval_level, 
		workflow_phases.return_level, workflow_phases.escalation_days, workflow_phases.escalation_hours, 
		workflow_phases.notice, workflow_phases.notice_email,
		workflow_phases.advice, workflow_phases.advice_email,
		workflow_phases.required_approvals, workflow_phases.phase_narrative, workflow_phases.details
	FROM (workflow_phases INNER JOIN vw_workflows ON workflow_phases.workflow_id = vw_workflows.workflow_id)
		INNER JOIN entity_types ON workflow_phases.approval_entity_id = entity_types.entity_type_id;

CREATE VIEW vw_workflow_entitys AS
	SELECT vw_workflow_phases.workflow_id, vw_workflow_phases.workflow_name, vw_workflow_phases.table_name,
		vw_workflow_phases.table_link_id, vw_workflow_phases.source_entity_id, vw_workflow_phases.source_entity_name, 
		vw_workflow_phases.approval_entity_id, vw_workflow_phases.approval_entity_name, 
		vw_workflow_phases.workflow_phase_id, vw_workflow_phases.approval_level, vw_workflow_phases.notice_email,
		vw_workflow_phases.return_level, vw_workflow_phases.escalation_days, vw_workflow_phases.escalation_hours, 
		vw_workflow_phases.required_approvals, vw_workflow_phases.phase_narrative, vw_workflow_phases.notice,
		entity_subscriptions.entity_subscription_id, entity_subscriptions.entity_id, entity_subscriptions.subscription_level_id
	FROM vw_workflow_phases INNER JOIN entity_subscriptions ON vw_workflow_phases.source_entity_id = entity_subscriptions.entity_type_id;

CREATE VIEW vw_approvals AS
	SELECT vw_workflow_phases.workflow_id, vw_workflow_phases.workflow_name, 
		vw_workflow_phases.approve_email, vw_workflow_phases.reject_email,
		vw_workflow_phases.source_entity_id, vw_workflow_phases.source_entity_name, 
		vw_workflow_phases.approval_entity_id, vw_workflow_phases.approval_entity_name,
		vw_workflow_phases.workflow_phase_id, vw_workflow_phases.approval_level, vw_workflow_phases.phase_narrative,
		vw_workflow_phases.return_level, vw_workflow_phases.required_approvals, 
		vw_workflow_phases.notice, vw_workflow_phases.notice_email,
		vw_workflow_phases.advice, vw_workflow_phases.advice_email,
		approvals.approval_id, approvals.forward_id, approvals.table_name, approvals.table_id,
		approvals.completion_date, approvals.escalation_days, approvals.escalation_hours,
		approvals.escalation_time, approvals.application_date, approvals.approve_status, approvals.action_date,
		approvals.approval_narrative, approvals.to_be_done, approvals.what_is_done, approvals.review_advice, approvals.details,
		oe.entity_id as org_entity_id, oe.entity_name as org_entity_name, oe.user_name as org_user_name, oe.primary_email as org_primary_email,
		ae.entity_id as app_entity_id, ae.entity_name as app_entity_name, ae.user_name as app_user_name, ae.primary_email as app_primary_email
	FROM (vw_workflow_phases INNER JOIN approvals ON vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id)
		INNER JOIN entitys oe ON approvals.org_entity_id = oe.entity_id
		LEFT JOIN entitys ae ON approvals.app_entity_id = ae.entity_id;

CREATE VIEW vw_workflow_approvals AS
	SELECT vw_approvals.workflow_id, vw_approvals.workflow_name, vw_approvals.approve_email, vw_approvals.reject_email,
		vw_approvals.source_entity_id, vw_approvals.source_entity_name, vw_approvals.table_name, vw_approvals.table_id,
		vw_approvals.org_entity_id, vw_approvals.org_entity_name, vw_approvals.org_user_name, 
		vw_approvals.org_primary_email, rt.rejected_count,
		(CASE WHEN rt.rejected_count is null THEN vw_approvals.workflow_name || ' Approved'
			ELSE vw_approvals.workflow_name || ' Rejected' END) as workflow_narrative
	FROM vw_approvals LEFT JOIN 
		(SELECT table_id, count(approval_id) as rejected_count FROM approvals WHERE (approve_status = 'Rejected') AND (approvals.forward_id is null)
		GROUP BY table_id) rt ON vw_approvals.table_id = rt.table_id
	GROUP BY vw_approvals.workflow_id, vw_approvals.workflow_name, vw_approvals.approve_email, vw_approvals.reject_email,
		vw_approvals.source_entity_id, vw_approvals.source_entity_name, vw_approvals.table_name, vw_approvals.table_id,
		vw_approvals.org_entity_id, vw_approvals.org_entity_name, vw_approvals.org_user_name, 
		vw_approvals.org_primary_email, rt.rejected_count;

CREATE VIEW vw_approvals_entitys AS
	SELECT vw_workflow_phases.workflow_id, vw_workflow_phases.workflow_name, 
		vw_workflow_phases.source_entity_id, vw_workflow_phases.source_entity_name, 
		vw_workflow_phases.approval_entity_id, vw_workflow_phases.approval_entity_name,
		vw_workflow_phases.workflow_phase_id, vw_workflow_phases.approval_level, vw_workflow_phases.notice_email,
		vw_workflow_phases.return_level, vw_workflow_phases.required_approvals,
		vw_workflow_phases.notice, vw_workflow_phases.phase_narrative,
		approvals.approval_id, approvals.forward_id, approvals.table_name, approvals.table_id,
		approvals.completion_date, approvals.escalation_days, approvals.escalation_hours,
		approvals.escalation_time, approvals.application_date, approvals.approve_status, approvals.action_date,
		approvals.approval_narrative, approvals.to_be_done, approvals.what_is_done, approvals.review_advice, approvals.details,
		oe.entity_id as org_entity_id, oe.entity_name as org_entity_name, oe.user_name as org_user_name, oe.primary_email as org_primary_email,
		entity_subscriptions.entity_subscription_id, entity_subscriptions.subscription_level_id,
		entitys.entity_id, entitys.entity_name, entitys.user_name, entitys.primary_email
	FROM ((vw_workflow_phases INNER JOIN approvals ON vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id)
		INNER JOIN entitys as oe  ON approvals.org_entity_id = oe.entity_id)
		INNER JOIN entity_subscriptions ON vw_workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id
		INNER JOIN entitys ON entity_subscriptions.entity_id = entitys.entity_id
	WHERE (approvals.forward_id is null);

CREATE VIEW tomcat_users AS 
	SELECT entitys.user_name, entitys.Entity_password, entity_types.entity_role
	FROM (Entity_subscriptions 
		INNER JOIN entitys ON Entity_subscriptions.entity_id = entitys.entity_id)
		INNER JOIN entity_types ON Entity_subscriptions.entity_type_id = entity_types.entity_type_id
	WHERE entitys.is_active = '1';

CREATE OR REPLACE FUNCTION md5(p_password  IN  VARCHAR2) RETURN VARCHAR2 AS
BEGIN
	RETURN DBMS_OBFUSCATION_TOOLKIT.MD5(input_string => p_password);
END;
/

CREATE OR REPLACE FUNCTION first_password RETURN varchar2 IS
	r RAW(256);
	mypass varchar2(16);
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	r := utl_raw.cast_to_raw(dbms_random.random);	
	r := utl_encode.base64_encode(r);
	mypass := substr(r, 2, 9);

	RETURN mypass;
END;
/

