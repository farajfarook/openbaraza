CREATE TABLE dc_users (
	dc_user_id			serial primary key not null,
	ad_client_id		character varying(32),
	ad_org_id			character varying(32),
	isactive			character(1) not null default 'y'::bpchar,
	created				timestamp without time zone not null default now(),	
	createdby			character varying(32),
	updated				timestamp without time zone not null default now(),
	updatedby			character varying(32), 

	isready				character(1) not null default 'y'::bpchar,
	ispicked			character(1) not null default 'n'::bpchar,

	dc_entity_id		integer,
	dc_user_name		character varying(32),
	dc_full_name		character varying(32),
	dc_first_name		character varying(32),
	dc_last_name		character varying(32),
	dc_primary_email	character varying(120),
	dc_password			character varying(32)
);

CREATE TABLE dc_ledger (
	dc_ledger_id		integer primary key,
	ad_client_id		character varying(32),
	ad_org_id			character varying(32),
	isactive			character(1) not null default 'y'::bpchar,
	created				timestamp without time zone not null default now(),	
	createdby			character varying(32),
	updated				timestamp without time zone not null default now(),
	updatedby			character varying(32), 

	isready				character(1) not null default 'n'::bpchar,
	ispicked			character(1) not null default 'n'::bpchar,

	period_id			integer,
	ledger_id			integer,
	posting_date		date, 
	description			varchar(240), 
	payroll_account		varchar(16), 
	dr_amt				numeric(12, 2), 
	cr_amt				numeric(12, 2)
);

CREATE OR REPLACE FUNCTION dc_ins_users() RETURNS trigger AS $$
DECLARE
	rec RECORD;
BEGIN
	SELECT ad_user_id INTO rec
	FROM ad_user WHERE (ad_user_id = NEW.dc_user_id);

	NEW.ad_client_id := '0';
	NEW.ad_org_id := '0';
	NEW.createdby := '0';
	NEW.updatedby := '0';

	IF(rec.ad_user_id is null) THEN
		INSERT INTO ad_user (ad_user_id, ad_client_id, ad_org_id, default_ad_client_id, default_ad_org_id, default_ad_language,
			createdby, updatedby, "name", "password", email, 
			firstname, lastname, username)
		VALUES (NEW.dc_user_id, NEW.ad_client_id, NEW.ad_org_id, NEW.ad_client_id, NEW.ad_org_id, 'en_US',
			NEW.createdby, NEW.updatedby, NEW.dc_full_name, NEW.dc_password, NEW.dc_primary_email,
			NEW.dc_primary_email, NEW.dc_last_name, NEW.dc_user_name);
	ELSE
		UPDATE ad_user SET "password" = NEW.dc_password WHERE (ad_user_id = NEW.dc_user_id);
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---CREATE TRIGGER dc_ins_users BEFORE INSERT OR UPDATE ON dc_users
---    FOR EACH ROW EXECUTE PROCEDURE dc_ins_users();

CREATE OR REPLACE FUNCTION dc_ins_ledger() RETURNS trigger AS $$
DECLARE
	reca		RECORD;

	pid			varchar(32);
	glbid		varchar(32);
	glid		varchar(32);
	cvid		varchar(32);
	lgid		varchar(32);
	pdesc		varchar(320);
	lnno		INTEGER;
BEGIN
	SELECT c_acctschema.c_acctschema_id, c_elementvalue.c_elementvalue_id, c_elementvalue.ad_client_id, c_elementvalue.ad_org_id, 
		 c_elementvalue.createdby, c_elementvalue.updatedby INTO reca
	FROM c_acctschema INNER JOIN c_elementvalue ON c_acctschema.ad_org_id = c_elementvalue.ad_org_id
	WHERE (c_elementvalue."value" = NEW.payroll_account) AND (c_elementvalue.ad_org_id = 'E3F7A3865F594647A5594F01E4CCC9C6');

	SELECT c_period_id INTO pid FROM c_period
	WHERE (CAST(startdate as date) <= NEW.posting_date) AND (CAST(enddate as date) >= NEW.posting_date) AND (ad_org_id = reca.ad_org_id);

	SELECT gl_journalbatch_id INTO glbid FROM gl_journalbatch 
	WHERE (documentno = CAST(NEW.ledger_id as varchar(32))) AND (ad_org_id = reca.ad_org_id);

	SELECT gl_journal_id INTO glid FROM gl_journal 
	WHERE (documentno = CAST(NEW.ledger_id as varchar(32))) AND (ad_org_id = reca.ad_org_id);

	SELECT c_validcombination_id INTO cvid
	FROM c_validcombination
	WHERE (alias = NEW.payroll_account) AND (ad_org_id = reca.ad_org_id);

	NEW.ad_client_id := reca.ad_org_id;
	NEW.ad_org_id := reca.ad_org_id;
	NEW.createdby := reca.createdby;
	NEW.updatedby := reca.updatedby;

	IF (glbid is null) THEN
		glbid := get_uuid();
		glid := get_uuid();
		pdesc := 'Payroll Posting for ' || to_char(NEW.posting_date, 'Month YYYY');
		INSERT INTO gl_journalbatch (gl_journalbatch_id, ad_client_id, ad_org_id, createdby, updatedby, documentno, 
			description, postingtype, gl_category_id, datedoc, dateacct, c_period_id, c_currency_id)
		VALUES(glbid, reca.ad_client_id, reca.ad_org_id, reca.createdby, reca.updatedby, CAST(NEW.ledger_id as varchar(32)),
			pdesc, 'A', 'FC670B83E59C4E7CBD6B999D3F28B251', NEW.posting_date, NEW.posting_date, pid, '266'); 

		INSERT INTO gl_journal(gl_journal_id, ad_client_id, ad_org_id, createdby, updatedby, c_acctschema_id, c_doctype_id, documentno, 
			docstatus, docaction, description, postingtype, gl_category_id, datedoc, dateacct, c_period_id, c_currency_id, 
			currencyratetype, currencyrate, gl_journalbatch_id, processing)
		VALUES(glid, reca.ad_client_id, reca.ad_org_id, reca.createdby, reca.updatedby, reca.c_acctschema_id, '51005B2C07EB41C5A2E7C25A4640ACD7', CAST(NEW.ledger_id as varchar(32)),
			'DR', 'CO', pdesc, 'A', 'FC670B83E59C4E7CBD6B999D3F28B251', NEW.posting_date, NEW.posting_date, pid, '266',
			'S', 1, glbid, 'N');

		lnno := 10;
	ELSE
		SELECT max(line) INTO lnno
		FROM gl_journalline
		WHERE (gl_journal_id = glid);
	END IF;
	
	SELECT gl_journalline_id INTO lgid
	FROM gl_journalline
	WHERE (gl_journalline_id = CAST(NEW.dc_ledger_id as varchar(32)));

	IF (lgid is null) THEN
		INSERT INTO gl_journalline (gl_journalline_id, ad_client_id, ad_org_id, createdby, updatedby, gl_journal_id,
			line, description, amtsourcedr, amtsourcecr, c_currency_id, currencyratetype, currencyrate,
			dateacct, amtacctdr, amtacctcr, c_uom_id, qty, c_validcombination_id)
		VALUES(NEW.dc_ledger_id, reca.ad_client_id, reca.ad_org_id, reca.createdby, reca.updatedby, glid,
			lnno, NEW.description, NEW.dr_amt, NEW.cr_amt, '266', 'S', 1, 
			NEW.posting_date, NEW.dr_amt, NEW.cr_amt, '100', 0, cvid);
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER dc_ins_ledger BEFORE INSERT OR UPDATE ON dc_ledger
    FOR EACH ROW EXECUTE PROCEDURE dc_ins_ledger();

CREATE FUNCTION get_alert_email(varchar(32)) RETURNS varchar(320) AS $$
DECLARE
    myrec	RECORD;
	myemail	varchar(320);
BEGIN
	myemail := null;
	FOR myrec IN SELECT ad_user.email
		FROM ad_user INNER JOIN ad_user_roles ON ad_user.ad_user_id = ad_user_roles.ad_user_id
			INNER JOIN ad_alertrecipient ON ad_user_roles.ad_role_id = ad_alertrecipient.ad_role_id
		WHERE (ad_user.email is not null) AND (ad_alertrecipient.ad_alertrule_id = $1) LOOP

		IF (myemail is null) THEN
			myemail := myrec.email;
		ELSE
			myemail := myemail || ', ' || myrec.email;
		END IF;

	END LOOP;

	RETURN myemail;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION dc_emailed(integer, varchar(64)) RETURNS void AS $$
    UPDATE ad_alert SET status = 'SENT' WHERE (ad_alert_id = $2);
$$ LANGUAGE SQL;

CREATE VIEW dc_alerts AS
	SELECT ad_alertrule.ad_alertrule_id, ad_alertrule.name, 
		ad_alert.ad_alert_id, ad_alert.description, ad_alert.status
	FROM ad_alertrule INNER JOIN ad_alert ON ad_alertrule.ad_alertrule_id = ad_alert.ad_alertrule_id;


