CREATE TABLE forms (
	form_id					integer primary key,
	org_id					integer references orgs,
	form_name				varchar(240) not null,
	form_number				varchar(50),
	version					varchar(25),
	completed				char(1) default '0' not null,
	is_active				char(1) default '0' not null,
	form_header				clob,
	form_footer				clob,
	details					clob,
	UNIQUE(form_name, version)
);
CREATE INDEX forms_org_id ON forms (org_id);
CREATE SEQUENCE seq_form_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_forms BEFORE INSERT ON forms
for each row 
begin     
	if inserting then 
		if :NEW.form_id is null then
			SELECT seq_form_id.nextval into :NEW.form_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE fields (
	field_id				integer primary key,
	form_id					integer references forms,
	question				clob,
	field_lookup			clob,
	field_type				varchar(25) not null,
	field_class				varchar(25),
	field_bold				char(1) default '0' not null, 
	field_italics			char(1) default '0' not null,
	field_order				integer default 1,
	share_line				integer,
	field_size				integer default 25 not null,
	manditory				char(1) default '0' not null,
	show					char(1) default '1'
);
CREATE INDEX fields_form_id ON fields (form_id);
CREATE SEQUENCE seq_field_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_fields BEFORE INSERT ON fields
for each row 
begin     
	if inserting then 
		if :NEW.field_id is null then
			SELECT seq_field_id.nextval into :NEW.field_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE sub_fields (
	sub_field_id			integer primary key,
	field_id				integer references fields,
	sub_field_order			integer default 1,
	sub_title_share			varchar(120),
	sub_field_type			varchar(25),
	sub_field_lookup		clob,
	sub_field_size			integer default 10 not null,
	sub_col_spans			integer default 1 not null,
	manditory				char(1) default '0' not null,
	show					char(1) default '1',
	question				clob
);	
CREATE INDEX sub_fields_field_id ON sub_fields (field_id);
CREATE SEQUENCE seq_sub_field_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_sub_fields BEFORE INSERT ON sub_fields
for each row 
begin     
	if inserting then 
		if :NEW.sub_field_id is null then
			SELECT seq_sub_field_id.nextval into :NEW.sub_field_id from dual;
		end if;
	end if; 
end;
/

CREATE TABLE entry_forms (
	entry_form_id			integer primary key,
	entity_id				integer references entitys,
	form_id					integer references forms,
	entered_by_id			integer references entitys,
	application_date		timestamp default current_timestamp not null,
	completion_date			timestamp,
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	narrative				varchar(240),
	answer					clob,
	sub_answer				clob,
	details					clob
);
CREATE INDEX entry_forms_entity_id ON entry_forms (entity_id);
CREATE INDEX entry_forms_form_id ON entry_forms (form_id);
CREATE INDEX entry_forms_entered_by_id ON entry_forms (entered_by_id);
CREATE SEQUENCE seq_entry_form_id MINVALUE 1 INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER trg_entry_forms BEFORE INSERT ON entry_forms
for each row 
begin     
	if inserting then 
		if :NEW.entry_form_id is null then
			SELECT seq_entry_form_id.nextval into :NEW.entry_form_id from dual;
		end if;
	end if; 
end;
/
 
