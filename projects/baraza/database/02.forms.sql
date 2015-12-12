CREATE TABLE forms (
	form_id					serial primary key,
	org_id					integer references orgs,
	form_name				varchar(240) not null,
	form_number				varchar(50),
	table_name				varchar(50),
	version					varchar(25),
	completed				char(1) default '0' not null,
	is_active				char(1) default '0' not null,
	use_key					integer default 0,
	form_header				text,
	form_footer				text,
	default_values			text,
	default_sub_values		text,
	details					text,
	UNIQUE(form_name, version)
);
CREATE INDEX forms_org_id ON forms (org_id);

CREATE TABLE fields (
	field_id				serial primary key,
	org_id					integer references orgs,
	form_id					integer references forms,
	field_name				varchar(50),
	question				text,
	field_lookup			text,
	field_type				varchar(25) not null,
	field_class				varchar(25),
	field_bold				char(1) default '0' not null, 
	field_italics			char(1) default '0' not null,
	field_order				integer not null,
	share_line				integer,
	field_size				integer not null default 25,
	label_position			char(1) default 'L',
	field_fnct				varchar(120),
	manditory				char(1) default '0' not null,
	show					char(1) default '1',
	tab						varchar(25),
	details					text
);
CREATE INDEX fields_org_id ON fields (org_id);
CREATE INDEX fields_form_id ON fields (form_id);

CREATE TABLE sub_fields (
	sub_field_id			serial primary key,
	org_id					integer references orgs,
	field_id				integer references fields,
	sub_field_order			integer not null,
	sub_title_share			varchar(120),
	sub_field_type			varchar(25),
	sub_field_lookup		text,
	sub_field_size			integer not null,
	sub_col_spans			integer not null default 1,
	manditory				char(1) default '0' not null,
	show					char(1) default '1',
	question				text
);
CREATE INDEX sub_fields_org_id ON sub_fields (org_id);
CREATE INDEX sub_fields_field_id ON sub_fields (field_id);

CREATE TABLE entry_forms (
	entry_form_id			serial primary key,
	org_id					integer references orgs,
	entity_id				integer references entitys,
	form_id					integer references forms,
	entered_by_id			integer references entitys,
	application_date		timestamp default now() not null,
	completion_date			timestamp,
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	narrative				varchar(240),
	answer					text,
	sub_answer				text,
	details					text
);
CREATE INDEX entry_forms_org_id ON entry_forms (org_id);
CREATE INDEX entry_forms_entity_id ON entry_forms (entity_id);
CREATE INDEX entry_forms_form_id ON entry_forms (form_id);
CREATE INDEX entry_forms_entered_by_id ON entry_forms (entered_by_id);

CREATE VIEW vw_fields AS
	SELECT forms.form_id, forms.form_name, fields.field_id, fields.org_id, fields.question, fields.field_lookup, 
		fields.field_type, fields.field_order, fields.share_line, fields.field_size, 
		fields.field_fnct, fields.manditory, fields.field_bold, fields.field_italics
	FROM fields INNER JOIN forms ON fields.form_id = forms.form_id;

CREATE VIEW vw_sub_fields AS
	SELECT vw_fields.form_id, vw_fields.form_name, vw_fields.field_id, sub_fields.sub_field_id, sub_fields.org_id,
		sub_fields.sub_field_order, sub_fields.sub_title_share, sub_fields.sub_field_type, sub_fields.sub_field_lookup, 
		sub_fields.sub_field_size, sub_fields.sub_col_spans, sub_fields.manditory, sub_fields.question
	FROM sub_fields INNER JOIN vw_fields ON sub_fields.field_id = vw_fields.field_id;

CREATE VIEW vw_entry_forms AS
	SELECT entitys.entity_id, entitys.entity_name, forms.form_id, forms.form_name, entry_forms.entry_form_id,
		entry_forms.org_id, entry_forms.approve_status, entry_forms.application_date, 
		entry_forms.completion_date, entry_forms.action_date, entry_forms.narrative, 
		entry_forms.answer, entry_forms.workflow_table_id, entry_forms.details
	FROM entry_forms INNER JOIN entitys ON entry_forms.entity_id = entitys.entity_id
	INNER JOIN forms ON entry_forms.form_id = forms.form_id;

CREATE OR REPLACE FUNCTION Ins_Entry_Form(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec 		RECORD;
	vorgid		integer;
	formName 	varchar(120);
	msg 		varchar(120);
BEGIN
	SELECT entry_form_id, org_id INTO rec
	FROM entry_forms 
	WHERE (form_id = CAST($1 as int)) AND (entity_ID = CAST($2 as int))
		AND (approve_status = 'Draft');

	SELECT form_name, org_id INTO formName, vorgid
	FROM forms WHERE (form_id = CAST($1 as int));

	IF rec.entry_form_id is null THEN
		INSERT INTO entry_forms (form_id, entity_id, org_id) 
		VALUES (CAST($1 as int), CAST($2 as int), vorgid);
		msg := 'Added Form : ' || formName;
	ELSE
		msg := 'There is an incomplete form : ' || formName;
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Upd_Complete_Form(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	msg varchar(120);
BEGIN
	IF ($3 = '1') THEN
		UPDATE entry_forms SET approve_status = 'Completed', completion_date = now()
		WHERE (entry_form_id = CAST($1 as int));
		msg := 'Completed the form';
	ELSIF ($3 = '2') THEN
		UPDATE entry_forms SET approve_status = 'Approved', action_date = now()
		WHERE (entry_form_id = CAST($1 as int));
		msg := 'Approved the form';
	ELSIF ($3 = '3') THEN
		UPDATE entry_forms SET approve_status = 'Rejected', action_date = now()
		WHERE (entry_form_id = CAST($1 as int));
		msg := 'Rejected the form';
	END IF;

	return msg;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON entry_forms
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE OR REPLACE FUNCTION ins_fields() RETURNS trigger AS $$
DECLARE
	v_ord	integer;
BEGIN
	IF(NEW.field_order is null) THEN
		SELECT max(field_order) INTO v_ord
		FROM fields
		WHERE (form_id = NEW.form_id);

		IF (v_ord is null) THEN
			NEW.field_order := 10;
		ELSE
			NEW.field_order := v_ord + 10;
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_fields BEFORE INSERT ON fields
    FOR EACH ROW EXECUTE PROCEDURE ins_fields();

CREATE OR REPLACE FUNCTION ins_sub_fields() RETURNS trigger AS $$
DECLARE
	v_ord	integer;
BEGIN
	IF(NEW.sub_field_order is null) THEN
		SELECT max(sub_field_order) INTO v_ord
		FROM sub_fields
		WHERE (field_id = NEW.field_id);

		IF (v_ord is null) THEN
			NEW.sub_field_order := 10;
		ELSE
			NEW.sub_field_order := v_ord + 10;
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_sub_fields BEFORE INSERT ON sub_fields
    FOR EACH ROW EXECUTE PROCEDURE ins_sub_fields();

CREATE OR REPLACE FUNCTION ins_entry_forms() RETURNS trigger AS $$
DECLARE
	reca		RECORD;
BEGIN
	
	SELECT default_values, default_sub_values INTO reca
	FROM forms
	WHERE (form_id = NEW.form_id);
	
	NEW.answer := reca.default_values;
	NEW.sub_answer := reca.default_sub_values;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_entry_forms BEFORE INSERT ON entry_forms
    FOR EACH ROW EXECUTE PROCEDURE ins_entry_forms();



