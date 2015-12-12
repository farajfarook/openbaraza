--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: add_employee(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION add_employee(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.add_employee(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: add_project_staff(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION add_project_staff(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.add_project_staff(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: add_shortlist(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION add_shortlist(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.add_shortlist(character varying, character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: add_tx_link(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION add_tx_link(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
BEGIN
	
	INSERT INTO transaction_details (transaction_id, org_id, item_id, quantity, amount, tax_amount, narrative, details)
	SELECT CAST($3 as integer), org_id, item_id, quantity, amount, tax_amount, narrative, details
	FROM transaction_details
	WHERE (transaction_detail_id = CAST($1 as integer));

	INSERT INTO transaction_links (org_id, transaction_detail_id, transaction_detail_to, quantity, amount)
	SELECT org_id, transaction_detail_id, currval('transaction_details_transaction_detail_id_seq'), quantity, amount
	FROM transaction_details
	WHERE (transaction_detail_id = CAST($1 as integer));

	return 'DONE';
END;
$_$;


ALTER FUNCTION public.add_tx_link(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: af_upd_transaction_details(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION af_upd_transaction_details() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	tamount REAL;
BEGIN

	IF(TG_OP = 'DELETE')THEN
		SELECT SUM(quantity * (amount + tax_amount)) INTO tamount
		FROM transaction_details WHERE (transaction_id = OLD.transaction_id);
		UPDATE transactions SET transaction_amount = tamount WHERE (transaction_id = OLD.transaction_id);	
	ELSE
		SELECT SUM(quantity * (amount + tax_amount)) INTO tamount
		FROM transaction_details WHERE (transaction_id = NEW.transaction_id);
		UPDATE transactions SET transaction_amount = tamount WHERE (transaction_id = NEW.transaction_id);	
	END IF;

	RETURN NULL;
END;
$$;


ALTER FUNCTION public.af_upd_transaction_details() OWNER TO postgres;

--
-- Name: amortise(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION amortise(assetid integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
	periodid 		int;
	rate 			real;
	pvalue 			real;
	cvalue 			real;
	depreciation	real;
BEGIN
	SELECT asset_types.Depreciation_rate, assets.purchase_value, YEAR(assets.purchase_date) INTO rate, pvalue, periodid
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
	WHERE asset_id = assetid;

	DELETE FROM amortisation WHERE (asset_id = assetid);

	cvalue := pvalue;
	depreciation := pvalue * rate / 100;
	LOOP
		IF (cvalue <= 0) THEN EXIT; END IF; -- exit loop

		pvalue := 0;
		SELECT asset_value INTO pvalue
		FROM asset_valuations
		WHERE (asset_id = assetid) AND (valuation_year = periodid);
		IF(pvalue > 1) THEN
			cvalue := pvalue;
			depreciation := pvalue * rate / 100;
		END IF;

		IF (cvalue < depreciation) THEN
			depreciation := cvalue;
		END IF;
		IF(depreciation > 1) THEN
			INSERT INTO amortisation (asset_id, amortisation_year, asset_value, amount)
			VALUES (assetid, periodid, cvalue, depreciation);
		END IF;

		periodid := periodid + 1;
		cvalue := cvalue - depreciation;
	END LOOP;

	RETURN 'Done';
END;
$$;


ALTER FUNCTION public.amortise(assetid integer) OWNER TO postgres;

--
-- Name: amortise_post(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION amortise_post(yearid integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
	cur1	RECORD;
	cur2	RECORD;
	cur3	RECORD;

	j_id 	integer;
BEGIN
	INSERT INTO journals (period_id, journal_date)
	SELECT period_id, CURRENT_DATE
	FROM periods
	WHERE (period_start <= CURRENT_DATE) AND (period_end >= CURRENT_DATE);

	j_id := currval('journals_journal_id_seq');

	-- Depreciation posting
	FOR cur1 IN SELECT asset_types.depreciation_account as a_a, asset_types.accumulated_account as a_b, 
		amortisation.amortisation_id as a_id, amortisation.amount as da
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
		INNER JOIN amortisation ON assets.asset_id = amortisation.asset_id
	WHERE (amortisation.posted = false) AND (amortisation_year = yearid) LOOP
		INSERT INTO gls (journal_id, account_id, debit, credit)
		VALUES (j_id, cur1.a_a, cur1.da, 0); 

		INSERT INTO gls (journal_id, account_id, debit, credit)
		VALUES (j_id, cur1.a_b, 0, cur1.da); 

		UPDATE amortisation SET posted = true WHERE amortisation_id = cur1.a_id;
	END LOOP;

	-- Open cursor
	FOR cur2 IN SELECT asset_types.asset_account as a_a, asset_types.valuation_account as a_b, 
		asset_valuations.asset_valuation_id as a_id, asset_valuations.value_change as da
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
		INNER JOIN asset_valuations ON assets.asset_id = asset_valuations.asset_id
	WHERE (asset_valuations.posted = false) AND (asset_valuations.valuation_year = yearid) LOOP
		INSERT INTO gls (journal_id, account_id, debit, credit)
		VALUES (j_id, cur2.a_a, cur2.da, 0);

		INSERT INTO gls (journal_id, account_id, debit, credit)
		VALUES (j_id, cur2.a_b, 0, cur2.da);

		UPDATE asset_valuations SET posted = true WHERE asset_valuation_id = cur2.a_id;
	END LOOP;

	-- Open cursor
	FOR cur3 IN SELECT asset_types.asset_account as a_a, asset_types.accumulated_account as a_b, 
		asset_types.disposal_account as a_c, assets.asset_id as a_id,
		assets.disposal_amount as da, assets.purchase_value as pc,
		COALESCE(sum(asset_valuations.value_change), 0) as vc
	FROM asset_types INNER JOIN assets ON asset_types.asset_type_id = assets.asset_type_id
		LEFT JOIN asset_valuations ON assets.asset_id = asset_valuations.asset_id
	WHERE (assets.inactive = true) AND (assets.disposal_posting = false) AND (YEAR(disposal_date) = yearid)
	GROUP BY asset_types.asset_account, asset_types.accumulated_account, 
		asset_types.disposal_account, assets.disposal_amount, assets.purchase_value LOOP

			INSERT INTO gls (journal_id, account_id, debit, credit)
			VALUES (j_id, cur3.a_a, 0, (cur3.pv + cur3.vc));

			INSERT INTO gls (journal_id, account_id, debit, credit)
			VALUES (j_id, cur3.a_c, cur3.da, 0);

			INSERT INTO gls (journal_id, account_id, debit, credit)
			VALUES (j_id, cur3.a_b, (cur3.pv + cur3.vc - cur3.da), 0);

			UPDATE assets SET disposal_posting = true WHERE asset_id = a_id;
		END LOOP;

	RETURN 'Done';
END;
$$;


ALTER FUNCTION public.amortise_post(yearid integer) OWNER TO postgres;

--
-- Name: budget_process(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION budget_process(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	rec 	RECORD;
	recb 	RECORD;

	nb_id 	INTEGER;
	ntrx	INTEGER;
	msg 	varchar(120);
BEGIN
	SELECT budget_id, org_id, fiscal_year_id, department_id, link_budget_id, budget_type, budget_name, approve_status INTO rec
	FROM budgets
	WHERE (budget_id = CAST($1 as integer));
	
	IF($3 = '1') THEN
		IF(rec.approve_status = 'Draft') THEN
			UPDATE budgets SET approve_status = 'Completed', entity_id = CAST($2 as integer)
			WHERE budget_id = rec.budget_id;
		END IF;
		msg := 'Transaction completed.';
	ELSIF (($3 = '2') OR ($3 = '3')) THEN
		IF(rec.approve_status = 'Approved') THEN
			IF(rec.link_budget_id is null) THEN
				nb_id := create_budget(rec.budget_id, rec.fiscal_year_id, CAST($3 as int));
				UPDATE budgets SET link_budget_id = nb_id WHERE budget_id = rec.budget_id;
				msg := 'The budget created.';
			ELSE
				msg := 'Another budget has already been created';
			END IF;
		ELSE
			msg := 'The budget needs to be aprroved first';
		END IF;
	ELSIF (($3 = '4')) THEN
		SELECT transaction_id, approve_status INTO recb 
		FROM vw_budget_lines WHERE (budget_line_id = CAST($1 as integer));

		IF(recb.approve_status != 'Approved') THEN
			msg := 'The budget neets approval first.';
		ELSIF(recb.transaction_id is null) THEN
			INSERT INTO transactions (org_id, currency_id, entity_id, department_id, transaction_type_id, transaction_date)
			SELECT orgs.org_id, orgs.currency_id, CAST($2 as integer), vw_budget_lines.department_id, 16, current_date
			FROM vw_budget_lines INNER JOIN orgs ON vw_budget_lines.org_id = orgs.org_id
			WHERE (budget_line_id = CAST($1 as integer));

			ntrx := currval('transactions_transaction_id_seq');

			INSERT INTO transaction_details (org_id, transaction_id, account_id, item_id, quantity, amount, tax_amount, narrative, details)
			SELECT org_id, ntrx, account_id, item_id, quantity, amount, tax_amount, narrative, details
			FROM vw_budget_lines
			WHERE (budget_line_id = CAST($1 as integer));

			UPDATE budget_lines SET transaction_id = ntrx WHERE (budget_line_id = CAST($1 as integer));

			msg := 'Requisition Created.';
		ELSE
			msg := 'Requisition had been created from this budget.';
		END IF;
	ELSE
		msg := 'Transaction alerady completed.';
	END IF;

	return msg;
END;
$_$;


ALTER FUNCTION public.budget_process(character varying, character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: change_password(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION change_password(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	old_password 	varchar(64);
	passchange 		varchar(120);
	entityID		integer;
BEGIN
	passchange := 'Password Error';
	entityID := CAST($1 AS INT);
	SELECT Entity_password INTO old_password
	FROM entitys WHERE (entity_id = entityID);

	IF ($2 = '0') THEN
		passchange := first_password();
		UPDATE entitys SET first_password = passchange, Entity_password = md5(passchange) WHERE (entity_id = entityID);
		passchange := 'Password Changed';
	ELSIF (old_password = md5($2)) THEN
		UPDATE entitys SET Entity_password = md5($3) WHERE (entity_id = entityID);
		passchange := 'Password Changed';
	ELSE
		passchange := 'Password Changing Error Ensure you have correct details';
	END IF;

	return passchange;
END;
$_$;


ALTER FUNCTION public.change_password(character varying, character varying, character varying) OWNER TO root;

--
-- Name: close_year(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION close_year(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	trx_date		DATE;
	periodid		INTEGER;
	journalid		INTEGER;
	profit_acct		INTEGER;
	retain_acct		INTEGER;
	rec				RECORD;
	msg				varchar(120);
BEGIN
	SELECT fiscal_year_id, fiscal_year_start, fiscal_year_end, year_opened, year_closed INTO rec
	FROM fiscal_years
	WHERE (fiscal_year_id = CAST($1 as integer));

	SELECT account_id INTO profit_acct FROM default_accounts WHERE default_account_id = 1;
	SELECT account_id INTO retain_acct FROM default_accounts WHERE default_account_id = 2;
	
	trx_date := CAST($1 || '-12-31' as date);
	periodid := get_open_period(trx_date);
	IF(periodid is null) THEN
		msg := 'Cannot post. No active period to post.';
	ELSIF(rec.year_opened = false)THEN
		msg := 'Cannot post. The year is not opened.';
	ELSIF(rec.year_closed = true)THEN
		msg := 'Cannot post. The year is closed.';
	ELSE
		INSERT INTO journals (period_id, journal_date, narrative, year_closing)
		VALUES (periodid, trx_date, 'End of year closing', false);
		journalid := currval('journals_journal_id_seq');

		INSERT INTO gls (journal_id, account_id, debit, credit, gl_narrative)
		SELECT journalid, account_id, dr_amount, cr_amount, 'Account Balance'
		FROM ((SELECT account_id, sum(bal_credit) as dr_amount, sum(bal_debit) as cr_amount
		FROM vw_ledger
		WHERE (chat_type_id > 3) AND (fiscal_year_id = rec.fiscal_year_id) AND (acc_balance <> 0)
		GROUP BY account_id)
		UNION
		(SELECT profit_acct, (CASE WHEN sum(bal_debit) > sum(bal_credit) THEN sum(bal_debit - bal_credit) ELSE 0 END),
		(CASE WHEN sum(bal_debit) < sum(bal_credit) THEN sum(bal_credit - bal_debit) ELSE 0 END)
		FROM vw_ledger
		WHERE (chat_type_id > 3) AND (fiscal_year_id = rec.fiscal_year_id) AND (acc_balance <> 0))) as a;

		msg := process_journal(CAST(journalid as varchar),'0','0');

		INSERT INTO journals (period_id, journal_date, narrative, year_closing)
		VALUES (periodid, trx_date, 'Retained Earnings', false);
		journalid := currval('journals_journal_id_seq');

		INSERT INTO gls (journal_id, account_id, debit, credit, gl_narrative)
		SELECT journalid, profit_acct, (CASE WHEN sum(bal_debit) < sum(bal_credit) THEN sum(bal_credit - bal_debit) ELSE 0 END),
			(CASE WHEN sum(bal_debit) > sum(bal_credit) THEN sum(bal_debit - bal_credit) ELSE 0 END), 'Retained Earnings'
		FROM vw_ledger
		WHERE (account_id = profit_acct) AND (fiscal_year_id = rec.fiscal_year_id) AND (acc_balance <> 0);

		INSERT INTO gls (journal_id, account_id, debit, credit, gl_narrative)
		SELECT journalid, retain_acct, (CASE WHEN sum(bal_debit) > sum(bal_credit) THEN sum(bal_debit - bal_credit) ELSE 0 END),
			(CASE WHEN sum(bal_debit) < sum(bal_credit) THEN sum(bal_credit - bal_debit) ELSE 0 END), 'Retained Earnings'
		FROM vw_ledger
		WHERE (account_id = profit_acct) AND (fiscal_year_id = rec.fiscal_year_id) AND (acc_balance <> 0);

		msg := process_journal(CAST(journalid as varchar),'0','0');

		UPDATE fiscal_years SET year_closed = true WHERE fiscal_year_id = rec.fiscal_year_id;
		UPDATE periods SET period_closed = true WHERE fiscal_year_id = rec.fiscal_year_id;
	END IF;

	return msg;
END;
$_$;


ALTER FUNCTION public.close_year(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: complete_transaction(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION complete_transaction(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	rec RECORD;
	bankacc INTEGER;
	msg varchar(120);
BEGIN
	SELECT transaction_id, transaction_type_id, transaction_status_id INTO rec
	FROM transactions
	WHERE (transaction_id = CAST($1 as integer));

	IF($3 = '2') THEN
		UPDATE transactions SET transaction_status_id = 4 
		WHERE transaction_id = rec.transaction_id;
		msg := 'Transaction Archived';
	ELSIF(rec.transaction_status_id = 1) THEN
		IF($3 = '1') THEN
			UPDATE transactions SET transaction_status_id = 2, approve_status = 'Completed'
			WHERE transaction_id = rec.transaction_id;
		END IF;
		msg := 'Transaction completed.';
	ELSE
		msg := 'Transaction alerady completed.';
	END IF;

	return msg;
END;
$_$;


ALTER FUNCTION public.complete_transaction(character varying, character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: copy_transaction(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION copy_transaction(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	msg varchar(120);
BEGIN

	INSERT INTO transactions (org_id, department_id, entity_id, currency_id, transaction_type_id, transaction_date, order_number, payment_terms, job, narrative, details)
	SELECT org_id, department_id, entity_id, currency_id, transaction_type_id, CURRENT_DATE, order_number, payment_terms, job, narrative, details
	FROM transactions
	WHERE (transaction_id = CAST($1 as integer));

	INSERT INTO transaction_details (org_id, transaction_id, account_id, item_id, quantity, amount, tax_amount, narrative, details)
	SELECT org_id, currval('transactions_transaction_id_seq'), account_id, item_id, quantity, amount, tax_amount, narrative, details
	FROM transaction_details
	WHERE (transaction_id = CAST($1 as integer));

	msg := 'Transaction Copied';

	return msg;
END;
$_$;


ALTER FUNCTION public.copy_transaction(character varying, character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: create_budget(integer, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_budget(integer, character varying, integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
	rec 	RECORD;
	
	nb_id 	INTEGER;
	p_id	INTEGER;
	p_date	DATE;
BEGIN
	INSERT INTO budgets (budget_type, org_id, fiscal_year_id, department_id, entity_id, budget_name)
	SELECT $3, org_id, fiscal_year_id, department_id, entity_id, budget_name
	FROM budgets
	WHERE (budget_id = $1);

	nb_id := currval('budgets_budget_id_seq');

	FOR rec IN SELECT org_id, period_id, account_id, item_id, spend_type, quantity, amount, tax_amount, income_budget, narrative
	FROM budget_lines WHERE (budget_id =  $1) ORDER BY period_id LOOP
		IF(rec.spend_type = 1)THEN
			INSERT INTO budget_lines (budget_id, period_id, org_id, account_id, item_id, quantity, amount, tax_amount, income_budget, narrative)
			SELECT nb_id, period_id, rec.org_id, rec.account_id, rec.item_id, rec.quantity, rec.amount, rec.tax_amount, rec.income_budget, rec.narrative
			FROM periods
			WHERE (fiscal_year_id = $2);
		ELSIF(rec.spend_type = 2)THEN
			FOR i IN 0..3 LOOP
				SELECT start_date + (i*3 || ' month')::INTERVAL INTO p_date 
				FROM periods WHERE (period_id = rec.period_id);
				SELECT period_id INTO p_id
				FROM periods WHERE (start_date <= p_date) AND (end_date >= p_date);

				IF(p_id is not null)THEN
					INSERT INTO budget_lines (budget_id, period_id, org_id, account_id, item_id, quantity, amount, tax_amount, income_budget, narrative)
					VALUES(nb_id, p_id, rec.org_id, rec.account_id, rec.item_id, rec.quantity, rec.amount, rec.tax_amount, rec.income_budget, rec.narrative);
				END IF;
			END LOOP;
		ELSE
			INSERT INTO budget_lines (budget_id, period_id, org_id, account_id, item_id, quantity, amount, tax_amount, income_budget, narrative)
			VALUES(nb_id, rec.period_id, rec.org_id, rec.account_id, rec.item_id, rec.quantity, rec.amount, rec.tax_amount, rec.income_budget, rec.narrative);
		END IF;
	END LOOP;

	RETURN nb_id;
END;
$_$;


ALTER FUNCTION public.create_budget(integer, character varying, integer) OWNER TO postgres;

--
-- Name: curr_base_returns(date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION curr_base_returns(date, date) RETURNS real
    LANGUAGE sql
    AS $_$
    SELECT COALESCE(sum(base_credit - base_debit), 0)
	FROM vw_gls
	WHERE (chat_type_id > 3) AND (posted = true) AND (year_closing = false)
		AND (journal_date >= $1) AND (journal_date <= $2);
$_$;


ALTER FUNCTION public.curr_base_returns(date, date) OWNER TO postgres;

--
-- Name: curr_returns(date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION curr_returns(date, date) RETURNS real
    LANGUAGE sql
    AS $_$
    SELECT COALESCE(sum(credit - debit), 0)
	FROM vw_gls
	WHERE (chat_type_id > 3) AND (posted = true) AND (year_closing = false)
		AND (journal_date >= $1) AND (journal_date <= $2);
$_$;


ALTER FUNCTION public.curr_returns(date, date) OWNER TO postgres;

--
-- Name: default_currency(character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION default_currency(character varying) RETURNS integer
    LANGUAGE sql
    AS $_$
	SELECT orgs.currency_id
	FROM orgs INNER JOIN entitys ON orgs.org_id = entitys.org_id
	WHERE (entitys.entity_id = CAST($1 as integer));
$_$;


ALTER FUNCTION public.default_currency(character varying) OWNER TO root;

--
-- Name: del_period(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION del_period(integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	msg 		varchar(120);
BEGIN
	DELETE FROM loan_monthly WHERE period_id = $1;
	
	DELETE FROM employee_adjustments WHERE (employee_month_id IN (SELECT employee_month_id FROM employee_month WHERE period_id = $1));
	DELETE FROM employee_tax_types WHERE (employee_month_id IN (SELECT employee_month_id FROM employee_month WHERE period_id = $1));
	DELETE FROM period_tax_rates WHERE (period_tax_type_id IN (SELECT period_tax_type_id FROM period_tax_types WHERE period_id = $1));
	DELETE FROM period_tax_types WHERE period_id = $1;

	DELETE FROM employee_month WHERE period_id = $1;
	DELETE FROM periods WHERE period_id = $1;

	msg := 'Period Deleted';

	return msg;
END;
$_$;


ALTER FUNCTION public.del_period(integer) OWNER TO postgres;

--
-- Name: emailed(integer, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION emailed(integer, character varying) RETURNS void
    LANGUAGE sql
    AS $_$
    UPDATE sys_emailed SET emailed = true WHERE (sys_emailed_id = CAST($2 as int));
$_$;


ALTER FUNCTION public.emailed(integer, character varying) OWNER TO root;

--
-- Name: first_password(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION first_password() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
	rnd integer;
	passchange varchar(12);
BEGIN
	passchange := trunc(random()*1000);
	rnd := trunc(65+random()*25);
	passchange := passchange || chr(rnd);
	passchange := passchange || trunc(random()*1000);
	rnd := trunc(65+random()*25);
	passchange := passchange || chr(rnd);
	rnd := trunc(65+random()*25);
	passchange := passchange || chr(rnd);

	return passchange;
END;
$$;


ALTER FUNCTION public.first_password() OWNER TO root;

--
-- Name: generate_payroll(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION generate_payroll(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	v_period_id		integer;
	v_org_id		integer;

	msg 			varchar(120);
BEGIN
	SELECT period_id, org_id INTO v_period_id, v_org_id
	FROM periods
	WHERE (period_id = CAST($1 as integer));

	INSERT INTO period_tax_types (org_id, period_id, tax_type_id, period_tax_type_name, formural, tax_relief, percentage, linear, employer, employer_ps, tax_type_order, in_tax, account_id)
	SELECT v_org_id, v_period_id, tax_type_id, tax_type_name, formural, tax_relief, percentage, linear, employer, employer_ps, tax_type_order, in_tax, account_id
	FROM Tax_Types
	WHERE (active = true);

	INSERT INTO employee_month (org_id, period_id, pay_group_id, entity_id, bank_branch_id, department_role_id, currency_id, bank_account, basic_pay)
	SELECT v_org_id, v_period_id, pay_group_id, entity_id, bank_branch_id, department_role_id, currency_id, bank_account, basic_salary
	FROM employees
	WHERE (employees.active = true) and (employees.org_id = v_org_id);

	INSERT INTO project_staff_costs (org_id, period_id, pay_group_id, entity_id, bank_branch_id, bank_account, 
		project_id, staff_cost, tax_cost)
	SELECT v_org_id, v_period_id, employees.pay_group_id, employees.entity_id, employees.bank_branch_id, employees.bank_account,
		project_staff.project_id, project_staff.staff_cost, project_staff.tax_cost
	FROM employees INNER JOIN project_staff ON employees.entity_id = project_staff.entity_id
	WHERE (project_staff.monthly_cost = true);

	INSERT INTO loan_monthly (org_id, period_id, loan_id, repayment, interest_amount, interest_paid)
	SELECT v_org_id, v_Period_ID, loan_id, monthly_repayment, (loan_balance * interest / 1200), (loan_balance * interest / 1200)
	FROM vw_loans WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  true);

	INSERT INTO loan_monthly (org_id, period_id, loan_id, repayment, interest_amount, interest_paid)
	SELECT v_org_id, v_period_id, loan_id, monthly_repayment, (principle * interest / 1200), 0
	FROM vw_loans WHERE (loan_balance > 0) AND (approve_status = 'Approved') AND (reducing_balance =  false);

	PERFORM updTax(employee_month_id, Period_id)
	FROM employee_month
	WHERE (period_id = v_period_id);

	msg := 'Payroll Generated';

	RETURN msg;
END;
$_$;


ALTER FUNCTION public.generate_payroll(character varying, character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: get_acct(integer, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_acct(integer, date, date) RETURNS real
    LANGUAGE sql
    AS $_$
    SELECT sum(gls.debit - gls.credit)
	FROM gls INNER JOIN journals ON gls.journal_id = journals.journal_id
	WHERE (gls.account_id = $1) AND (journals.posted = true) AND (journals.year_closing = false)
		AND (journals.journal_date >= $2) AND (journals.journal_date <= $3);
$_$;


ALTER FUNCTION public.get_acct(integer, date, date) OWNER TO postgres;

--
-- Name: get_approval_date(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_approval_date(integer) RETURNS date
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.get_approval_date(integer) OWNER TO postgres;

--
-- Name: get_approver(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_approver(integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.get_approver(integer) OWNER TO postgres;

--
-- Name: get_asset_value(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_asset_value(assetid integer, valueyear integer) RETURNS real
    LANGUAGE plpgsql
    AS $$
DECLARE
	vperiod 		int;
	pvalue 			real;
	depreciation 	real;
BEGIN
	pvalue := 0;

	SELECT assets.purchase_value INTO pvalue
	FROM assets
	WHERE (asset_id = assetid) AND (YEAR(assets.purchase_date) <= valueYear);

	SELECT sum(amount) INTO depreciation
	FROM amortisation
	WHERE (asset_id	 = assetid) AND (amortisation_year < valueYear);
	IF(pvalue > depreciation) THEN
		pvalue := pvalue - depreciation;
	END IF;

	SELECT max(valuation_year) INTO vperiod
	FROM asset_valuations
	WHERE (asset_id = assetid) AND (valuation_year <= valueYear);

	SELECT asset_value INTO pvalue
	FROM asset_valuations
	WHERE (asset_id = assetid) AND (valuation_year = vperiod);

	SELECT sum(amount) INTO depreciation
	FROM amortisation
	WHERE (asset_id	 = assetid) AND (amortisation_year >= vperiod) AND (amortisation_year < valueYear);
	IF(pvalue > depreciation) THEN
		pvalue := pvalue - depreciation;
	END IF;

	RETURN pvalue;
END;
$$;


ALTER FUNCTION public.get_asset_value(assetid integer, valueyear integer) OWNER TO postgres;

--
-- Name: get_base_acct(integer, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_base_acct(integer, date, date) RETURNS real
    LANGUAGE sql
    AS $_$
    SELECT sum(gls.debit * journals.exchange_rate - gls.credit * journals.exchange_rate) 
	FROM gls INNER JOIN journals ON gls.journal_id = journals.journal_id
	WHERE (gls.account_id = $1) AND (journals.posted = true) AND (journals.year_closing = false)
		AND (journals.journal_date >= $2) AND (journals.journal_date <= $3);
$_$;


ALTER FUNCTION public.get_base_acct(integer, date, date) OWNER TO postgres;

--
-- Name: get_budgeted(integer, date, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_budgeted(integer, date, integer) RETURNS real
    LANGUAGE plpgsql
    AS $_$
DECLARE
	reca		RECORD;
	app_id		Integer;
	v_bill		real;
	v_variance	real;
BEGIN

	FOR reca IN SELECT transaction_detail_id, account_id, amount 
		FROM transaction_details WHERE (transaction_id = $1) LOOP

		SELECT sum(amount) INTO v_bill
		FROM transactions INNER JOIN transaction_details ON transactions.transaction_id = transaction_details.transaction_id
		WHERE (transactions.department_id = $3) AND (transaction_details.account_id = reca.account_id)
			AND (transactions.journal_id is null) AND (transaction_details.transaction_detail_id <> reca.transaction_detail_id);
		IF(v_bill is null)THEN
			v_bill := 0;
		END IF;

		SELECT sum(budget_lines.amount) INTO v_variance
		FROM fiscal_years INNER JOIN budgets ON fiscal_years.fiscal_year_id = budgets.fiscal_year_id
			INNER JOIN budget_lines ON budgets.budget_id = budget_lines.budget_id
		WHERE (budgets.department_id = $3) AND (budget_lines.account_id = reca.account_id)
			AND (budgets.approve_status = 'Approved')
			AND (fiscal_years.fiscal_year_start <= $2) AND (fiscal_years.fiscal_year_end >= $2);
		IF(v_variance is null)THEN
			v_variance := 0;
		END IF;

		v_variance := v_variance - (reca.amount + v_bill);

		IF(v_variance < 0)THEN
			RETURN v_variance;
		END IF;
	END LOOP;

	RETURN v_variance;
END;
$_$;


ALTER FUNCTION public.get_budgeted(integer, date, integer) OWNER TO postgres;

--
-- Name: get_employee_tax(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_employee_tax(integer, integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
DECLARE
	v_employee_month_id			integer;
	v_period_tax_type_id		integer;
	v_exchange_rate				real;
	v_income					real;
	v_tax						real;
BEGIN

	SELECT employee_tax_types.employee_month_id, period_tax_types.period_tax_type_id, employee_tax_types.exchange_rate
		INTO v_employee_month_id, v_period_tax_type_id, v_exchange_rate
	FROM employee_tax_types INNER JOIN employee_month ON employee_tax_types.employee_month_id = employee_month.employee_month_id
		INNER JOIN period_tax_types ON (employee_month.period_id = period_tax_types.period_id)
			AND (employee_tax_types.tax_type_id = period_tax_types.tax_type_id)
	WHERE (employee_tax_types.employee_tax_type_id	= $1);
	
	IF(v_exchange_rate = 0) THEN v_exchange_rate := 1; END IF;

	IF ($2 = 1) THEN
		v_income := getAdjustment(v_employee_month_id, 1) / v_exchange_rate;
		v_tax := getTax(v_income, v_period_tax_type_id);

	ELSIF ($2 = 2) THEN
		v_income := getAdjustment(v_employee_month_id, 2) / v_exchange_rate;
		v_tax := getTax(v_income, v_period_tax_type_id) - getAdjustment(v_employee_month_id, 4, 25) / v_exchange_rate;

	ELSE
		v_tax := 0;
	END IF;

	IF(v_tax is null) THEN
		v_tax := 0;
	END IF;

	RETURN v_tax;
END;
$_$;


ALTER FUNCTION public.get_employee_tax(integer, integer) OWNER TO postgres;

--
-- Name: get_formula_adjustment(integer, integer, real); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_formula_adjustment(integer, integer, real) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
DECLARE
	v_employee_month_id		integer;
	v_basic_pay				float;
	v_adjustment			float;
BEGIN

	SELECT employee_month.employee_month_id, employee_month.basic_pay INTO v_employee_month_id, v_basic_pay
	FROM employee_month
	WHERE (employee_month.employee_month_id = $1);

	IF ($2 = 1) THEN
		v_adjustment := v_basic_pay * $3;
	ELSE
		v_adjustment := 0;
	END IF;

	IF(v_adjustment is null) THEN
		v_adjustment := 0;
	END IF;

	RETURN v_adjustment;
END;
$_$;


ALTER FUNCTION public.get_formula_adjustment(integer, integer, real) OWNER TO postgres;

--
-- Name: get_intrest_repayment(integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_intrest_repayment(integer, date) RETURNS real
    LANGUAGE sql
    AS $_$
	SELECT CASE WHEN sum(interest_paid) is null THEN 0 ELSE sum(interest_paid) END
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$_$;


ALTER FUNCTION public.get_intrest_repayment(integer, date) OWNER TO postgres;

--
-- Name: get_leave_balance(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_leave_balance(integer, integer) RETURNS real
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.get_leave_balance(integer, integer) OWNER TO postgres;

--
-- Name: get_leave_days(date, date, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_leave_days(date, date, integer) RETURNS real
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.get_leave_days(date, date, integer) OWNER TO postgres;

--
-- Name: get_loan_period(real, real, integer, real); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_loan_period(real, real, integer, real) RETURNS real
    LANGUAGE plpgsql
    AS $_$
DECLARE
	loanbalance real;
	ri real;
BEGIN
	ri := 1 + ($2/1200);
	IF (ri = 1) THEN
		loanbalance := $1;
	ELSE
		loanbalance := $1 * (ri ^ $3) - ($4 * ((ri ^ $3)  - 1) / (ri - 1));
	END IF;
	RETURN loanbalance;
END;
$_$;


ALTER FUNCTION public.get_loan_period(real, real, integer, real) OWNER TO postgres;

--
-- Name: get_open_period(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_open_period(date) RETURNS integer
    LANGUAGE sql
    AS $_$
	SELECT period_id FROM periods WHERE (start_date <= $1) AND (end_date >= $1)
		AND (opened = true) AND (closed = false); 
$_$;


ALTER FUNCTION public.get_open_period(date) OWNER TO postgres;

--
-- Name: get_payment_period(real, real, real); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_payment_period(real, real, real) RETURNS real
    LANGUAGE plpgsql
    AS $_$
DECLARE
	paymentperiod real;
	q real;
BEGIN
	q := $3/1200;
	
	IF ($2 = 0) OR (q = -1) OR (($2 - (q * $1)) = 0) THEN
		paymentperiod := 1;
	ELSIF (log(q + 1) = 0) THEN
		paymentperiod := 1;
	ELSE
		paymentperiod := (log($2) - log($2 - (q * $1))) / log(q + 1);
	END IF;

	RETURN paymentperiod;
END;
$_$;


ALTER FUNCTION public.get_payment_period(real, real, real) OWNER TO postgres;

--
-- Name: get_penalty(integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_penalty(integer, date) RETURNS real
    LANGUAGE sql
    AS $_$
	SELECT CASE WHEN sum(penalty) is null THEN 0 ELSE sum(penalty) END
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$_$;


ALTER FUNCTION public.get_penalty(integer, date) OWNER TO postgres;

--
-- Name: get_period(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_period(date) RETURNS integer
    LANGUAGE sql
    AS $_$
	SELECT period_id FROM periods WHERE (start_date <= $1) AND (end_date >= $1); 
$_$;


ALTER FUNCTION public.get_period(date) OWNER TO postgres;

--
-- Name: get_phase_email(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION get_phase_email(integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
    myrec	RECORD;
	myemail	varchar(320);
BEGIN
	myemail := null;
	FOR myrec IN SELECT entitys.primary_email
		FROM entitys INNER JOIN entity_subscriptions ON entitys.entity_id = entity_subscriptions.entity_id
		WHERE (entity_subscriptions.entity_type_id = $1) LOOP

		IF (myemail is null) THEN
			IF (myrec.primary_email is not null) THEN
				myemail := myrec.primary_email;
			END IF;
		ELSE
			IF (myrec.primary_email is not null) THEN
				myemail := myemail || ', ' || myrec.primary_email;
			END IF;
		END IF;

	END LOOP;

	RETURN myemail;
END;
$_$;


ALTER FUNCTION public.get_phase_email(integer) OWNER TO root;

--
-- Name: get_phase_status(boolean, boolean); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION get_phase_status(boolean, boolean) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	ps		varchar(16);
BEGIN
	ps := 'Draft';
	IF ($1 = true) THEN
		ps := 'Approved';
	END IF;
	IF ($2 = true) THEN
		ps := 'Rejected';
	END IF;

	RETURN ps;
END;
$_$;


ALTER FUNCTION public.get_phase_status(boolean, boolean) OWNER TO root;

--
-- Name: get_repayment(real, real, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_repayment(real, real, integer) RETURNS real
    LANGUAGE plpgsql
    AS $_$
DECLARE
	repayment real;
	ri real;
BEGIN
	ri := 1 + ($2/1200);
	IF ((ri ^ $3) = 1) THEN
		repayment := $1;
	ELSE
		repayment := $1 * (ri ^ $3) * (ri - 1) / ((ri ^ $3) - 1);
	END IF;
	RETURN repayment;
END;
$_$;


ALTER FUNCTION public.get_repayment(real, real, integer) OWNER TO postgres;

--
-- Name: get_review_category(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_review_category(character varying) RETURNS integer
    LANGUAGE sql
    AS $_$
    SELECT review_category_id
	FROM job_reviews
	WHERE (job_review_id = CAST($1 as int));
$_$;


ALTER FUNCTION public.get_review_category(character varying) OWNER TO postgres;

--
-- Name: get_review_entity(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_review_entity(character varying) RETURNS integer
    LANGUAGE sql
    AS $_$
    SELECT entity_id
	FROM job_reviews
	WHERE (job_review_id = CAST($1 as int));
$_$;


ALTER FUNCTION public.get_review_entity(character varying) OWNER TO postgres;

--
-- Name: get_total_interest(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_total_interest(integer) RETURNS real
    LANGUAGE sql
    AS $_$
	SELECT CASE WHEN sum(interest_amount) is null THEN 0 ELSE sum(interest_amount) END 
	FROM loan_monthly
	WHERE (loan_id = $1);
$_$;


ALTER FUNCTION public.get_total_interest(integer) OWNER TO postgres;

--
-- Name: get_total_interest(integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_total_interest(integer, date) RETURNS real
    LANGUAGE sql
    AS $_$
	SELECT CASE WHEN sum(interest_amount) is null THEN 0 ELSE sum(interest_amount) END 
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$_$;


ALTER FUNCTION public.get_total_interest(integer, date) OWNER TO postgres;

--
-- Name: get_total_repayment(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_total_repayment(integer) RETURNS real
    LANGUAGE sql
    AS $_$
	SELECT CASE WHEN sum(repayment + interest_paid + penalty_paid) is null THEN 0 
		ELSE sum(repayment + interest_paid + penalty_paid) END
	FROM loan_monthly
	WHERE (loan_id = $1);
$_$;


ALTER FUNCTION public.get_total_repayment(integer) OWNER TO postgres;

--
-- Name: get_total_repayment(integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_total_repayment(integer, date) RETURNS real
    LANGUAGE sql
    AS $_$
	SELECT CASE WHEN sum(repayment + interest_paid + penalty_paid) is null THEN 0 
		ELSE sum(repayment + interest_paid + penalty_paid) END
	FROM loan_monthly INNER JOIN periods ON loan_monthly.period_id = periods.period_id
	WHERE (loan_monthly.loan_id = $1) AND (periods.start_date < $2);
$_$;


ALTER FUNCTION public.get_total_repayment(integer, date) OWNER TO postgres;

--
-- Name: get_total_repayment(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_total_repayment(integer, integer) RETURNS double precision
    LANGUAGE sql
    AS $_$
	SELECT sum(monthly_repayment + loan_intrest)
	FROM vw_loan_payments 
	WHERE (loan_id = $1) and (months <= $2);
$_$;


ALTER FUNCTION public.get_total_repayment(integer, integer) OWNER TO postgres;

--
-- Name: getadjustment(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION getadjustment(integer, integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
DECLARE
	adjustment float;
BEGIN

	IF ($2 = 1) THEN
		SELECT (Basic_Pay + getAdjustment(Employee_Month_ID, 4, 31) + getAdjustment(Employee_Month_ID, 4, 23) 
			+ getAdjustment(Employee_Month_ID, 4, 32)) INTO adjustment
		FROM Employee_Month
		WHERE (Employee_Month_ID = $1);
	ELSIF ($2 = 2) THEN
		SELECT (Basic_Pay + getAdjustment(Employee_Month_ID, 4, 31) + getAdjustment(Employee_Month_ID, 4, 32) 
			+ getAdjustment(Employee_Month_ID, 4, 23)
			- getAdjustment(Employee_Month_ID, 4, 12) - getAdjustment(Employee_Month_ID, 4, 24)) INTO adjustment
		FROM Employee_Month
		WHERE (Employee_Month_ID = $1);
	ELSE
		adjustment := 0;
	END IF;

	IF(adjustment is null) THEN
		adjustment := 0;
	END IF;

	RETURN adjustment;
END;
$_$;


ALTER FUNCTION public.getadjustment(integer, integer) OWNER TO postgres;

--
-- Name: getadjustment(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION getadjustment(integer, integer, integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
DECLARE
	adjustment float;
BEGIN

	IF ($3 = 1) THEN
		SELECT SUM(exchange_rate * amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (adjustment_type = $2);
	ELSIF ($3 = 2) THEN
		SELECT SUM(exchange_rate * amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (adjustment_type = $2) AND (In_payroll = true) AND (Visible = true);
	ELSIF ($3 = 3) THEN
		SELECT SUM(exchange_rate * amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (adjustment_type = $2) AND (In_Tax = true);
	ELSIF ($3 = 4) THEN
		SELECT SUM(exchange_rate * amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (adjustment_type = $2) AND (In_payroll = true);
	ELSIF ($3 = 5) THEN
		SELECT SUM(exchange_rate * amount) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (adjustment_type = $2) AND (Visible = true);
	ELSIF ($3 = 11) THEN
		SELECT SUM(exchange_rate * amount) INTO adjustment
		FROM Employee_Tax_Types
		WHERE (Employee_Month_ID = $1);
	ELSIF ($3 = 12) THEN
		SELECT SUM(exchange_rate * amount) INTO adjustment
		FROM Employee_Tax_Types
		WHERE (Employee_Month_ID = $1) AND (In_Tax = true);
	ELSIF ($3 = 14) THEN
		SELECT SUM(exchange_rate * amount) INTO adjustment
		FROM Employee_Tax_Types
		WHERE (Employee_Month_ID = $1) AND (Tax_Type_ID = $2);
	ELSIF ($3 = 21) THEN
		SELECT SUM(exchange_rate * amount * adjustment_factor) INTO adjustment
		FROM employee_adjustments
		WHERE (employee_month_id = $1) AND (in_tax = true);
	ELSIF ($3 = 22) THEN
		SELECT SUM(exchange_rate * amount * adjustment_factor) INTO adjustment
		FROM Employee_Adjustments
		WHERE (Employee_Month_ID = $1) AND (In_payroll = true) AND (Visible = true);
	ELSIF ($3 = 23) THEN
		SELECT SUM(exchange_rate * amount * adjustment_factor) INTO adjustment
		FROM employee_adjustments
		WHERE (employee_month_id = $1) AND (in_tax = true) AND (adjustment_factor = 1);
	ELSIF ($3 = 24) THEN
		SELECT SUM(exchange_rate * tax_reduction_amount) INTO adjustment
		FROM employee_adjustments
		WHERE (employee_month_id = $1) AND (in_tax = true) AND (adjustment_factor = -1);
	ELSIF ($3 = 25) THEN
		SELECT SUM(exchange_rate * tax_relief_amount) INTO adjustment
		FROM employee_adjustments
		WHERE (employee_month_id = $1) AND (in_tax = true) AND (adjustment_factor = -1);
	ELSIF ($3 = 31) THEN
		SELECT SUM(overtime * overtime_rate) INTO adjustment
		FROM employee_overtime
		WHERE (Employee_Month_ID = $1) AND (approve_status = 'Approved');
	ELSIF ($3 = 32) THEN
		SELECT SUM(exchange_rate * tax_amount) INTO adjustment
		FROM employee_per_diem
		WHERE (Employee_Month_ID = $1) AND (approve_status = 'Approved');
	ELSIF ($3 = 33) THEN
		SELECT SUM(exchange_rate * (full_amount -  cash_paid)) INTO adjustment
		FROM Employee_Per_Diem
		WHERE (Employee_Month_ID = $1) AND (approve_status = 'Approved');
	ELSIF ($3 = 34) THEN
		SELECT SUM(exchange_rate * amount) INTO adjustment
		FROM employee_advances
		WHERE (Employee_Month_ID = $1) AND (in_payroll = true);
	ELSIF ($3 = 35) THEN
		SELECT SUM(exchange_rate * amount) INTO adjustment
		FROM advance_deductions
		WHERE (Employee_Month_ID = $1) AND (In_payroll = true);
	ELSIF ($3 = 36) THEN
		SELECT SUM(exchange_rate * paid_amount) INTO adjustment
		FROM employee_adjustments
		WHERE (Employee_Month_ID = $1) AND (In_payroll = true) AND (Visible = true);
	ELSIF ($3 = 37) THEN
		SELECT SUM(exchange_rate * tax_relief_amount) INTO adjustment
		FROM employee_adjustments
		WHERE (Employee_Month_ID = $1);

		IF(adjustment IS NULL)THEN
			adjustment := 0;
		END IF;
	ELSIF ($3 = 41) THEN
		SELECT SUM(exchange_rate * amount) INTO adjustment
		FROM employee_banking
		WHERE (Employee_Month_ID = $1);
	ELSE
		adjustment := 0;
	END IF;

	IF(adjustment is null) THEN
		adjustment := 0;
	END IF;

	RETURN adjustment;
END;
$_$;


ALTER FUNCTION public.getadjustment(integer, integer, integer) OWNER TO postgres;

--
-- Name: getadvancebalance(integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION getadvancebalance(integer, date) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
DECLARE
	advance FLOAT;
	paid 	FLOAT;
BEGIN
	SELECT SUM(Amount) INTO advance
	FROM vw_employee_advances
	WHERE (entity_id = $1) AND (start_date <= $2) AND (approve_status = 'Approved');
	IF (advance is null) THEN advance := 0; END IF;
	
	SELECT SUM(Amount) INTO paid
	FROM vw_advance_deductions
	WHERE (entity_id = $1) AND (start_date <= $2);
	IF (paid is null) THEN paid := 0; END IF;

	advance := advance - paid;

	RETURN advance;
END;
$_$;


ALTER FUNCTION public.getadvancebalance(integer, date) OWNER TO postgres;

--
-- Name: gettax(double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gettax(double precision, integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
DECLARE
	reca		RECORD;
	tax			REAL;
BEGIN
	SELECT period_tax_type_id, formural, tax_relief, percentage, linear, in_tax, employer, employer_ps INTO reca
	FROM period_tax_types
	WHERE (period_tax_type_id = $2);

	IF(reca.linear = true) THEN
		SELECT SUM(CASE WHEN tax_range < $1 
		THEN (tax_rate / 100) * (tax_range - getTaxMin(tax_range, reca.period_tax_type_id)) 
		ELSE (tax_rate / 100) * ($1 - getTaxMin(tax_range, reca.period_tax_type_id)) END) INTO tax
		FROM period_tax_rates 
		WHERE (getTaxMin(tax_range, reca.period_tax_type_id) <= $1) AND (period_tax_type_id = reca.period_tax_type_id);
	ELSIF(reca.linear = false) THEN 
		SELECT max(tax_rate) INTO tax
		FROM period_tax_rates 
		WHERE (getTaxMin(tax_range, reca.period_tax_type_id) < $1) AND (tax_range >= $1) 
			AND (period_tax_type_id = reca.period_tax_type_id);
	END IF;

	IF (tax is null) THEN
		tax := 0;
	END IF;

	IF (tax > reca.tax_relief) THEN
		tax := tax - reca.tax_relief;
	ELSE
		tax := 0;
	END IF;

	RETURN tax;
END;
$_$;


ALTER FUNCTION public.gettax(double precision, integer) OWNER TO postgres;

--
-- Name: gettaxmin(double precision, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION gettaxmin(double precision, integer) RETURNS double precision
    LANGUAGE sql
    AS $_$
	SELECT CASE WHEN max(tax_range) is null THEN 0 ELSE max(tax_range) END 
	FROM period_tax_rates WHERE (tax_range < $1) AND (period_tax_type_id = $2);
$_$;


ALTER FUNCTION public.gettaxmin(double precision, integer) OWNER TO postgres;

--
-- Name: ins_address(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_address() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	v_address_id		integer;
BEGIN
	SELECT address_id INTO v_address_id
	FROM address WHERE (is_default = true)
		AND (table_name = NEW.table_name) AND (table_id = NEW.table_id) AND (address_id <> NEW.address_id);

	IF(NEW.is_default = true) AND (v_address_id is not null) THEN
		RAISE EXCEPTION 'Only one default Address allowed.';
	ELSIF (NEW.is_default = false) AND (v_address_id is null) THEN
		NEW.is_default := true;
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.ins_address() OWNER TO root;

--
-- Name: ins_applicants(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_applicants() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_applicants() OWNER TO postgres;

--
-- Name: ins_applications(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_applications(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.ins_applications(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: ins_approvals(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_approvals() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	reca	RECORD;
BEGIN

	IF (NEW.forward_id is not null) THEN
		SELECT workflow_phase_id, org_entity_id, app_entity_id, approval_level, table_name, table_id INTO reca
		FROM approvals 
		WHERE (approval_id = NEW.forward_id);

		NEW.workflow_phase_id := reca.workflow_phase_id;
		NEW.approval_level := reca.approval_level;
		NEW.table_name := reca.table_name;
		NEW.table_id := reca.table_id;
		NEW.approve_status := 'Completed';
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.ins_approvals() OWNER TO root;

--
-- Name: ins_asset_valuations(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_asset_valuations() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	NEW.value_change = NEW.asset_value - get_asset_value(NEW.asset_id, NEW.valuation_year);
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.ins_asset_valuations() OWNER TO postgres;

--
-- Name: ins_bf_periods(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_bf_periods() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	rec RECORD;
BEGIN
	SELECT bank_header, bank_address INTO rec
	FROM orgs
	WHERE (org_id = NEW.org_id);

	NEW.bank_header = rec.bank_header;
	NEW.bank_address = rec.bank_address;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.ins_bf_periods() OWNER TO postgres;

--
-- Name: ins_budget(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_budget() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	INSERT INTO pc_allocations (period_id, department_id, org_id)
	SELECT NEW.period_id, department_id, org_id
	FROM departments
	WHERE (departments.active = true) AND (departments.petty_cash = true) AND (departments.org_id = NEW.org_id);

	INSERT INTO pc_budget (	pc_allocation_id, org_id, pc_item_id, budget_units, budget_price)
	SELECT pc_allocations.pc_allocation_id, pc_allocations.org_id,
		pc_items.pc_item_id, pc_items.default_units, pc_items.default_price
	FROM pc_allocation CROSS JOIN pc_items
	WHERE (pc_allocation.period_id = NEW.period_id) AND (pc_allocation.org_id = NEW.org_id)
		AND (pc_items.default_units > 0);
	
	RETURN NULL;
END;
$$;


ALTER FUNCTION public.ins_budget() OWNER TO postgres;

--
-- Name: ins_employee_adjustments(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_employee_adjustments() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	v_formural					varchar(430);
	v_tax_relief_ps				float;
	v_tax_reduction_ps			float;
	v_tax_max_allowed			float;
BEGIN
	IF((NEW.Amount = 0) AND (NEW.paid_amount <> 0))THEN
		NEW.Amount = NEW.paid_amount / 0.7;
	END IF;
	
	IF(NEW.exchange_rate is null) THEN NEW.exchange_rate = 1; END IF;
	IF(NEW.exchange_rate = 0) THEN NEW.exchange_rate = 1; END IF;
	
	IF(NEW.Amount = 0)THEN
		SELECT formural INTO v_formural
		FROM adjustments
		WHERE (adjustments.adjustment_id = NEW.adjustment_id);
		IF(v_formural is not null)THEN
			EXECUTE 'SELECT ' || v_formural || ' FROM employee_month WHERE employee_month_id = ' || NEW.employee_month_id
			INTO NEW.Amount;
			NEW.Amount := NEW.Amount / NEW.exchange_rate;
		END IF;
	END IF;

	IF(NEW.in_tax = true)THEN
		SELECT tax_reduction_ps, tax_relief_ps, tax_max_allowed INTO v_tax_reduction_ps, v_tax_relief_ps, v_tax_max_allowed
		FROM adjustments
		WHERE (adjustments.adjustment_id = NEW.adjustment_id);

		IF(v_tax_reduction_ps is null)THEN
			NEW.tax_reduction_amount := 0;
		ELSE
			NEW.tax_reduction_amount := NEW.amount * v_tax_reduction_ps / 100;
			NEW.tax_reduction_amount := NEW.tax_reduction_amount;
		END IF;

		IF(v_tax_relief_ps is null)THEN
			NEW.tax_relief_amount := 0;
		ELSE
			NEW.tax_relief_amount := NEW.amount * v_tax_relief_ps / 100;
			NEW.tax_relief_amount := NEW.tax_relief_amount;
		END IF;

		IF(v_tax_max_allowed is not null)THEN
			IF(NEW.tax_reduction_amount > v_tax_max_allowed)THEN
				NEW.tax_reduction_amount := v_tax_max_allowed;
			END IF;
			IF(NEW.tax_relief_amount > v_tax_max_allowed)THEN
				NEW.tax_relief_amount := v_tax_max_allowed;
			END IF;
		END IF;
	ELSE
		NEW.tax_relief_amount := 0;
		NEW.tax_reduction_amount := 0;
	END IF;
	
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.ins_employee_adjustments() OWNER TO postgres;

--
-- Name: ins_employee_leave(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_employee_leave() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_employee_leave() OWNER TO postgres;

--
-- Name: ins_employee_leave_types(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_employee_leave_types() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_employee_leave_types() OWNER TO postgres;

--
-- Name: ins_employee_month(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_employee_month() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	SELECT exchange_rate INTO NEW.exchange_rate
	FROM currency_rates
	WHERE (currency_rate_id = 
		(SELECT MAX(currency_rate_id)
		FROM currency_rates
		WHERE (currency_id = NEW.currency_id) AND (org_id = NEW.org_id)
			AND (exchange_date < CURRENT_DATE)));
		
	IF(NEW.exchange_rate is null)THEN NEW.exchange_rate := 1; END IF;	

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.ins_employee_month() OWNER TO postgres;

--
-- Name: ins_employees(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_employees() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_employees() OWNER TO postgres;

--
-- Name: ins_entitys(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_entitys() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN	
	IF(NEW.entity_type_id is not null) THEN
		INSERT INTO Entity_subscriptions (org_id, entity_type_id, entity_id, subscription_level_id)
		VALUES (NEW.org_id, NEW.entity_type_id, NEW.entity_id, 0);
	END IF;

	RETURN NULL;
END;
$$;


ALTER FUNCTION public.ins_entitys() OWNER TO root;

--
-- Name: ins_entry_form(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_entry_form(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.ins_entry_form(character varying, character varying, character varying) OWNER TO root;

--
-- Name: ins_entry_forms(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_entry_forms() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_entry_forms() OWNER TO root;

--
-- Name: ins_fields(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_fields() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_fields() OWNER TO root;

--
-- Name: ins_fiscal_years(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_fiscal_years() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO periods (fiscal_year_id, org_id, start_date, end_date)
	SELECT NEW.fiscal_year_id, NEW.org_id, period_start, CAST(period_start + CAST('1 month' as interval) as date) - 1
	FROM (SELECT CAST(generate_series(fiscal_year_start, fiscal_year_end, '1 month') as date) as period_start
		FROM fiscal_years WHERE fiscal_year_id = NEW.fiscal_year_id) as a;

	RETURN NULL;
END;
$$;


ALTER FUNCTION public.ins_fiscal_years() OWNER TO postgres;

--
-- Name: ins_interns(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_interns(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.ins_interns(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: ins_job_reviews(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_job_reviews() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_job_reviews() OWNER TO postgres;

--
-- Name: ins_leave_work_days(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_leave_work_days() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	SELECT entity_id INTO NEW.entity_id
	FROM employee_leave
	WHERE (employee_leave_id = NEW.employee_leave_id);

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.ins_leave_work_days() OWNER TO postgres;

--
-- Name: ins_objective_details(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_objective_details() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_objective_details() OWNER TO postgres;

--
-- Name: ins_objectives(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_objectives() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_objectives() OWNER TO postgres;

--
-- Name: ins_password(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_password() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF(NEW.first_password is null) AND (TG_OP = 'INSERT') THEN
		NEW.first_password := first_password();
	END IF;
	IF(TG_OP = 'INSERT') THEN
		IF (NEW.Entity_password is null) THEN
			NEW.Entity_password := md5(NEW.first_password);
		END IF;
	ELSIF(OLD.first_password <> NEW.first_password) THEN
		NEW.Entity_password := md5(NEW.first_password);
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.ins_password() OWNER TO root;

--
-- Name: ins_period_tax_types(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_period_tax_types() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO period_tax_rates (org_id, period_tax_type_id, tax_range, tax_rate)
	SELECT NEW.org_id, NEW.period_tax_type_id, tax_range, tax_rate
	FROM tax_rates
	WHERE (tax_type_id = NEW.tax_type_id);

	RETURN NULL;
END;
$$;


ALTER FUNCTION public.ins_period_tax_types() OWNER TO postgres;

--
-- Name: ins_periods(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_periods() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	year_close 		BOOLEAN;
BEGIN
	SELECT year_closed INTO year_close
	FROM fiscal_years
	WHERE (fiscal_year_id = NEW.fiscal_year_id);

	IF (NEW.approve_status = 'Approved') THEN
		NEW.opened = false;
		NEW.activated = false;
		NEW.closed = true;
	END IF;

	IF(year_close = true)THEN
		RAISE EXCEPTION 'The year is closed not transactions are allowed.';
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.ins_periods() OWNER TO postgres;

--
-- Name: ins_projects(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_projects() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_projects() OWNER TO postgres;

--
-- Name: ins_sub_fields(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_sub_fields() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.ins_sub_fields() OWNER TO root;

--
-- Name: ins_sys_reset(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION ins_sys_reset() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	v_entity_id			integer;
	v_org_id			integer;
	v_password			varchar(32);
BEGIN	
	SELECT entity_id, org_id INTO v_entity_id, v_org_id
	FROM entitys
	WHERE (lower(trim(primary_email)) = lower(trim(NEW.request_email)));

	IF(v_entity_id is not null) THEN
		v_password := upper(substring(md5(random()::text) from 3 for 9));

		UPDATE entitys SET first_password = v_password, entity_password = md5(v_password)
		WHERE entity_id = v_entity_id;

		INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name)
		VALUES(v_org_id, 3, v_entity_id, 'entitys');
	END IF;

	RETURN NULL;
END;
$$;


ALTER FUNCTION public.ins_sys_reset() OWNER TO root;

--
-- Name: ins_taxes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION ins_taxes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO default_tax_types (org_id, entity_id, tax_type_id)
	SELECT NEW.org_id, NEW.entity_id, tax_type_id
	FROM tax_types
	WHERE (active = true) AND (use_key = 1) AND (org_id = NEW.org_id);

	RETURN NULL;
END;
$$;


ALTER FUNCTION public.ins_taxes() OWNER TO postgres;

--
-- Name: job_review_check(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION job_review_check(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.job_review_check(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: leave_aplication(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION leave_aplication(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.leave_aplication(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: leave_special(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION leave_special(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.leave_special(character varying, character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: objectives_review(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION objectives_review(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.objectives_review(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: post_transaction(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION post_transaction(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	rec RECORD;
	periodid INTEGER;
	journalid INTEGER;
	msg varchar(120);
BEGIN
	SELECT org_id, department_id, transaction_id, transaction_type_id, transaction_type_name as tx_name, 
		transaction_status_id, journal_id, gl_bank_account_id, currency_id, exchange_rate,
		transaction_date, transaction_amount, document_number, credit_amount, debit_amount,
		entity_account_id, entity_name, approve_status INTO rec
	FROM vw_transactions
	WHERE (transaction_id = CAST($1 as integer));

	periodid := get_open_period(rec.transaction_date);
	IF(periodid is null) THEN
		msg := 'No active period to post.';
	ELSIF(rec.journal_id is not null) THEN
		msg := 'Transaction previously Posted.';
	ELSIF(rec.transaction_status_id = 1) THEN
		msg := 'Transaction needs to be completed first.';
	ELSIF(rec.approve_status != 'Approved') THEN
		msg := 'Transaction is not yet approved.';
	ELSE
		INSERT INTO journals (org_id, department_id, currency_id, period_id, exchange_rate, journal_date, narrative)
		VALUES (rec.org_id, rec.department_id, rec.currency_id, periodid, rec.exchange_rate, rec.transaction_date, rec.tx_name || ' - posting for ' || rec.document_number);
		journalid := currval('journals_journal_id_seq');

		INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
		VALUES (rec.org_id, journalid, rec.entity_account_id, rec.debit_amount, rec.credit_amount, rec.tx_name || ' - ' || rec.entity_name);

		IF((rec.transaction_type_id = 7) or (rec.transaction_type_id = 8)) THEN
			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			VALUES (rec.org_id, journalid, rec.gl_bank_account_id, rec.credit_amount, rec.debit_amount, rec.tx_name || ' - ' || rec.entity_name);
		ELSE
			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			SELECT org_id, journalid, trans_account_id, full_debit_amount, full_credit_amount, rec.tx_name || ' - ' || item_name
			FROM vw_transaction_details
			WHERE (transaction_id = rec.transaction_id) AND (full_amount > 0);

			INSERT INTO gls (org_id, journal_id, account_id, debit, credit, gl_narrative)
			SELECT org_id, journalid, tax_account_id, tax_debit_amount, tax_credit_amount, rec.tx_name || ' - ' || item_name
			FROM vw_transaction_details
			WHERE (transaction_id = rec.transaction_id) AND (full_tax_amount > 0);
		END IF;

		UPDATE transactions SET journal_id = journalid WHERE (transaction_id = rec.transaction_id);
		msg := process_journal(CAST(journalid as varchar),'0','0');
	END IF;

	return msg;
END;
$_$;


ALTER FUNCTION public.post_transaction(character varying, character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: prev_acct(integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION prev_acct(integer, date) RETURNS real
    LANGUAGE sql
    AS $_$
    SELECT sum(gls.debit - gls.credit)
	FROM gls INNER JOIN journals ON gls.journal_id = journals.journal_id
	WHERE (gls.account_id = $1) AND (journals.posted = true) 
		AND (journals.journal_date < $2);
$_$;


ALTER FUNCTION public.prev_acct(integer, date) OWNER TO postgres;

--
-- Name: prev_base_acct(integer, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION prev_base_acct(integer, date) RETURNS real
    LANGUAGE sql
    AS $_$
    SELECT sum(gls.debit * journals.exchange_rate - gls.credit * journals.exchange_rate) 
	FROM gls INNER JOIN journals ON gls.journal_id = journals.journal_id
	WHERE (gls.account_id = $1) AND (journals.posted = true) 
		AND (journals.journal_date < $2);
$_$;


ALTER FUNCTION public.prev_base_acct(integer, date) OWNER TO postgres;

--
-- Name: prev_base_returns(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION prev_base_returns(date) RETURNS real
    LANGUAGE sql
    AS $_$
    SELECT COALESCE(sum(base_credit - base_debit), 0)
	FROM vw_gls
	WHERE (chat_type_id > 3) AND (posted = true) AND (journal_date < $1);
$_$;


ALTER FUNCTION public.prev_base_returns(date) OWNER TO postgres;

--
-- Name: prev_returns(date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION prev_returns(date) RETURNS real
    LANGUAGE sql
    AS $_$
    SELECT COALESCE(sum(credit - debit), 0)
	FROM vw_gls
	WHERE (chat_type_id > 3) AND (posted = true) AND (journal_date < $1);
$_$;


ALTER FUNCTION public.prev_returns(date) OWNER TO postgres;

--
-- Name: process_bio_imports1(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION process_bio_imports1(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
	msg		 				varchar(120);
BEGIN

	msg := 'Already Added to project';
	
	return msg;
END;
$$;


ALTER FUNCTION public.process_bio_imports1(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: process_journal(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION process_journal(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	rec RECORD;
	msg varchar(120);
BEGIN
	SELECT periods.start_date, periods.end_date, periods.opened, periods.closed, journals.journal_date, journals.posted, 
		sum(debit) as sum_debit, sum(credit) as sum_credit INTO rec
	FROM (periods INNER JOIN journals ON periods.period_id = journals.period_id)
		INNER JOIN gls ON journals.journal_id = gls.journal_id
	WHERE (journals.journal_id = CAST($1 as integer))
	GROUP BY periods.start_date, periods.end_date, periods.opened, periods.closed, journals.journal_date, journals.posted;

	IF(rec.posted = true) THEN
		msg := 'Journal previously Processed.';
	ELSIF((rec.start_date > rec.journal_date) OR (rec.end_date < rec.journal_date)) THEN
		msg := 'Journal date has to be within periods date.';
	ELSIF((rec.opened = false) OR (rec.closed = true)) THEN
		msg := 'Transaction period has to be opened and not closed.';
	ELSIF(rec.sum_debit <> rec.sum_credit) THEN
		msg := 'Cannot process Journal because credits do not equal debits.';
	ELSE
		UPDATE journals SET posted = true WHERE (journals.journal_id = CAST($1 as integer));
		msg := 'Journal Processed.';
	END IF;

	return msg;
END;
$_$;


ALTER FUNCTION public.process_journal(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: process_ledger(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION process_ledger(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	isposted boolean;
	ledger_diff real;
	msg varchar(120);
BEGIN

	SELECT is_posted INTO isposted
	FROM Periods
	WHERE (period_id = CAST($1 as int));

	SELECT abs(sum(dr_amt) - sum(cr_amt)) INTO ledger_diff
	FROM vw_payroll_ledger
	WHERE (period_id = CAST($1 as int));

	msg := 'Payroll Ledger not posted';
	IF((isposted = false) AND (ledger_diff < 5)) THEN
		INSERT INTO payroll_ledger (period_id, posting_date, description, payroll_account, dr_amt, cr_amt)
		SELECT period_id, end_date, description, gl_payroll_account, ROUND(CAST(dr_amt as numeric), 2), ROUND(CAST(cr_amt as numeric), 2)
		FROM vw_payroll_ledger
		WHERE (period_id = CAST($1 as int));

		UPDATE Periods SET is_posted = true
		WHERE (period_id = CAST($1 as int));

		msg := 'Payroll Ledger Processed';
	END IF;

	return msg;
END;
$_$;


ALTER FUNCTION public.process_ledger(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: process_loans(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION process_loans(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	rec					RECORD;
	v_exchange_rate		real;
	msg					varchar(120);
BEGIN
	
	FOR rec IN SELECT vw_loan_monthly.loan_month_id, vw_loan_monthly.loan_id, vw_loan_monthly.entity_id, vw_loan_monthly.period_id, 
		vw_loan_monthly.employee_adjustment_id, vw_loan_monthly.adjustment_id, vw_loan_monthly.loan_balance, 
		vw_loan_monthly.repayment, (vw_loan_monthly.interest_paid + vw_loan_monthly.penalty_paid) as total_interest,
		(vw_loan_monthly.repayment + vw_loan_monthly.interest_paid + vw_loan_monthly.penalty_paid) as total_deduction,
		employee_month.employee_month_id, employee_month.org_id, 
		employee_month.currency_id, employee_month.exchange_rate,
		adjustments.currency_id as adj_currency_id
	FROM vw_loan_monthly INNER JOIN employee_month ON (vw_loan_monthly.entity_id = employee_month.entity_id) AND (vw_loan_monthly.period_id = employee_month.period_id)
		INNER JOIN adjustments ON vw_loan_monthly.adjustment_id = adjustments.adjustment_id
	WHERE (vw_loan_monthly.period_id = CAST($1 as int)) LOOP
	
		IF(rec.currency_id = rec.adj_currency_id)THEN
			v_exchange_rate := 1;
		ELSE
			v_exchange_rate := 1 / rec.exchange_rate;
		END IF;

		IF(rec.employee_adjustment_id is null)THEN
			INSERT INTO employee_adjustments (employee_month_id, adjustment_id, adjustment_type, adjustment_factor,
				amount, balance, in_tax, org_id, exchange_rate)
			VALUES (rec.employee_month_id, rec.adjustment_id, 2, -1,
				rec.total_deduction, rec.loan_balance, false, rec.org_id, v_exchange_rate);

			UPDATE loan_monthly SET employee_adjustment_id = currval('employee_adjustments_employee_adjustment_id_seq') 
			WHERE (loan_month_id = rec.loan_month_id);
		ELSE
			UPDATE employee_adjustments SET amount = rec.total_deduction, balance = rec.loan_balance, exchange_rate = v_exchange_rate
			WHERE (employee_adjustment_id = rec.employee_adjustment_id);
		END IF;

	END LOOP;

	msg := 'Payroll Processed';

	return msg;
END;
$_$;


ALTER FUNCTION public.process_loans(character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: process_payroll(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION process_payroll(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	rec 		RECORD;
	msg 		varchar(120);
BEGIN
	IF ($3 = '1') THEN
		UPDATE employee_adjustments SET tax_reduction_amount = 0 
		FROM employee_month 
		WHERE (employee_adjustments.employee_month_id = employee_month.employee_month_id) 
			AND (employee_month.period_id = CAST($1 as int));
	
		PERFORM updTax(employee_month_id, period_id)
		FROM employee_month
		WHERE (period_id = CAST($1 as int));

		msg := 'Payroll Processed';
	ELSIF ($3 = '2') THEN
		UPDATE periods SET entity_id = CAST($2 as int), approve_status = 'Completed'
		WHERE (period_id = CAST($1 as int));

		msg := 'Application for approval';
	END IF;

	return msg;
END;
$_$;


ALTER FUNCTION public.process_payroll(character varying, character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: process_transaction(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION process_transaction(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	rec RECORD;
	bankacc INTEGER;
	msg varchar(120);
BEGIN
	SELECT org_id, transaction_id, transaction_type_id, transaction_status_id, transaction_amount INTO rec
	FROM transactions
	WHERE (transaction_id = CAST($1 as integer));

	IF(rec.transaction_status_id = 1) THEN
		msg := 'Transaction needs to be completed first.';
	ELSIF(rec.transaction_status_id = 2) THEN
		IF (($3 = '7') AND ($3 = '8')) THEN
			SELECT max(bank_account_id) INTO bankacc
			FROM bank_accounts WHERE (is_default = true);

			INSERT INTO transactions (org_id, department_id, entity_id, currency_id, transaction_type_id, transaction_date, bank_account_id, transaction_amount)
			SELECT transactions.org_id, transactions.department_id, transactions.entity_id, transactions.currency_id, 1, CURRENT_DATE, bankacc, 
				SUM(transaction_details.quantity * (transaction_details.amount + transaction_details.tax_amount))
			FROM transactions INNER JOIN transaction_details ON transactions.transaction_id = transaction_details.transaction_id
			WHERE (transactions.transaction_id = rec.transaction_id)
			GROUP BY transactions.transaction_id, transactions.entity_id;

			INSERT INTO transaction_links (org_id, transaction_id, transaction_to, amount)
			VALUES (rec.org_id, currval('transactions_transaction_id_seq'), rec.transaction_id, rec.transaction_amount);
		
			UPDATE transactions SET transaction_status_id = 3 WHERE transaction_id = rec.transaction_id;
		ELSE
			INSERT INTO transactions (org_id, department_id, entity_id, currency_id, transaction_type_id, transaction_date, order_number, payment_terms, job, narrative, details)
			SELECT org_id, department_id, entity_id, currency_id, CAST($3 as integer), CURRENT_DATE, order_number, payment_terms, job, narrative, details
			FROM transactions
			WHERE (transaction_id = rec.transaction_id);

			INSERT INTO transaction_details (org_id, transaction_id, account_id, item_id, quantity, amount, tax_amount, narrative, details)
			SELECT org_id, currval('transactions_transaction_id_seq'), account_id, item_id, quantity, amount, tax_amount, narrative, details
			FROM transaction_details
			WHERE (transaction_id = rec.transaction_id);

			INSERT INTO transaction_links (org_id, transaction_id, transaction_to, amount)
			VALUES (REC.org_id, currval('transactions_transaction_id_seq'), rec.transaction_id, rec.transaction_amount);

			UPDATE transactions SET transaction_status_id = 3 WHERE transaction_id = rec.transaction_id;
		END IF;
		msg := 'Transaction proccesed';
	ELSE
		msg := 'Transaction previously Processed.';
	END IF;

	return msg;
END;
$_$;


ALTER FUNCTION public.process_transaction(character varying, character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: upd_action(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION upd_action() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.upd_action() OWNER TO root;

--
-- Name: upd_applications(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_applications() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	typeid	integer;
BEGIN
	
	IF (NEW.approve_status = 'Approved') THEN
		NEW.action_date := now();
		
		SELECT entity_type_id INTO typeid
		FROM entitys WHERE entity_id = NEW.entity_id;

		IF (typeid = 4) THEN
			SELECT Department_Role_id INTO typeid
			FROM intake WHERE intake_ID = NEW.intake_ID;

			INSERT INTO employees (org_id, department_role_id, entity_id, surname, first_name, middle_name, date_of_birth, gender,
				nationality, marital_status, appointment_date, contract_period, employment_terms, identity_card, basic_salary,
				bank_branch_id, language, interests, objective, details)
			SELECT org_id, typeid, entity_id, surname, first_name, middle_name, date_of_birth, gender,
				nationality, marital_status, current_date, 3, 'Probation', identity_card, 10000, 0, 
				language, interests, objective, details
			FROM applicant
			WHERE entity_id = NEW.entity_id;

			UPDATE entitys SET entity_type_id  = 1 WHERE entity_id = NEW.entity_id;
			UPDATE entity_subscriptions SET entity_type_id  = 1 WHERE entity_id = NEW.entity_id;
		END IF;
	END IF;
	IF (NEW.approve_status = 'Rejected') THEN
		NEW.action_date := now();
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.upd_applications() OWNER TO postgres;

--
-- Name: upd_approvals(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION upd_approvals() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	reca	RECORD;
	wfid	integer;
	vorgid	integer;
	vnotice	boolean;
	vadvice	boolean;
BEGIN

	SELECT notice, advice, org_id INTO vnotice, vadvice, vorgid
	FROM workflow_phases
	WHERE (workflow_phase_id = NEW.workflow_phase_id);

	IF (NEW.approve_status = 'Completed') THEN
		INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
		VALUES (NEW.approval_id, TG_TABLE_NAME, 1, vorgid);
	END IF;
	IF (NEW.approve_status = 'Approved') AND (vadvice = true) AND (NEW.forward_id is null) THEN
		INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
		VALUES (NEW.approval_id, TG_TABLE_NAME, 1, vorgid);
	END IF;
	IF (NEW.approve_status = 'Approved') AND (vnotice = true) AND (NEW.forward_id is null) THEN
		INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
		VALUES (NEW.approval_id, TG_TABLE_NAME, 2, vorgid);
	END IF;

	IF(TG_OP = 'INSERT') AND (NEW.forward_id is null) THEN
		INSERT INTO approval_checklists (approval_id, checklist_id, requirement, manditory, org_id)
		SELECT NEW.approval_id, checklist_id, requirement, manditory, org_id
		FROM checklists 
		WHERE (workflow_phase_id = NEW.workflow_phase_id)
		ORDER BY checklist_number;
	END IF;

	RETURN NULL;
END;
$$;


ALTER FUNCTION public.upd_approvals() OWNER TO root;

--
-- Name: upd_approvals(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION upd_approvals(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	app_id		Integer;
	reca 		RECORD;
	recb		RECORD;
	recc		RECORD;
	recd		RECORD;

	min_level	Integer;
	mysql		varchar(240);
	msg 		varchar(120);
BEGIN
	app_id := CAST($1 as int);
	SELECT approvals.approval_id, approvals.org_id, approvals.table_name, approvals.table_id, approvals.review_advice,
		workflow_phases.workflow_phase_id, workflow_phases.workflow_id, workflow_phases.return_level INTO reca
	FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
	WHERE (approvals.approval_id = app_id);

	SELECT count(approval_checklist_id) as cl_count INTO recc
	FROM approval_checklists
	WHERE (approval_id = app_id) AND (manditory = true) AND (done = false);

	SELECT transaction_type_id, get_budgeted(transaction_id, transaction_date, department_id) as budget_var INTO recd
	FROM transactions
	WHERE (workflow_table_id = reca.table_id);

	IF ($3 = '1') THEN
		UPDATE approvals SET approve_status = 'Completed', completion_date = now()
		WHERE approval_id = app_id;
		msg := 'Completed';
	ELSIF ($3 = '2') AND (recc.cl_count <> 0) THEN
		msg := 'There are manditory checklist that must be checked first.';
	ELSIF (recd.transaction_type_id = 5) AND (recd.budget_var < 0) THEN
		msg := 'You need a budget to approve the expenditure.';
	ELSIF ($3 = '2') AND (recc.cl_count = 0) THEN
		UPDATE approvals SET approve_status = 'Approved', action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		SELECT min(approvals.approval_level) INTO min_level
		FROM approvals INNER JOIN workflow_phases ON approvals.workflow_phase_id = workflow_phases.workflow_phase_id
		WHERE (approvals.table_id = reca.table_id) AND (approvals.approve_status = 'Draft')
			AND (workflow_phases.advice = false) AND (workflow_phases.notice = false);
		
		IF(min_level is null)THEN
			mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Approved') 
			|| ', action_date = now()'
			|| ' WHERE workflow_table_id = ' || reca.table_id;
			EXECUTE mysql;

			INSERT INTO sys_emailed (table_id, table_name, email_type)
			VALUES (reca.table_id, 'vw_workflow_approvals', 1);
		ELSE
			FOR recb IN SELECT workflow_phase_id, advice
			FROM workflow_phases
			WHERE (workflow_id = reca.workflow_id) AND (approval_level = min_level) LOOP
				IF (recb.advice = true) THEN
					UPDATE approvals SET approve_status = 'Approved', action_date = now(), completion_date = now()
					WHERE (workflow_phase_id = recb.workflow_phase_id) AND (table_id = reca.table_id);
				ELSE
					UPDATE approvals SET approve_status = 'Completed', completion_date = now()
					WHERE (workflow_phase_id = recb.workflow_phase_id) AND (table_id = reca.table_id);
				END IF;
			END LOOP;
		END IF;
		msg := 'Approved';
	ELSIF ($3 = '3') THEN
		UPDATE approvals SET approve_status = 'Rejected',  action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;

		mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Rejected') 
		|| ', action_date = now()'
		|| ' WHERE workflow_table_id = ' || reca.table_id;
		EXECUTE mysql;

		INSERT INTO sys_emailed (table_id, table_name, email_type, org_id)
		VALUES (reca.table_id, 'vw_workflow_approvals', 2, reca.org_id);
		msg := 'Rejected';
	ELSIF ($3 = '4') AND (reca.return_level = 0) THEN
		UPDATE approvals SET approve_status = 'Review',  action_date = now(), app_entity_id = CAST($2 as int)
		WHERE approval_id = app_id;
		
		mysql := 'UPDATE ' || reca.table_name || ' SET approve_status = ' || quote_literal('Draft') 
		|| ', action_date = now()'
		|| ' WHERE workflow_table_id = ' || reca.table_id;
		EXECUTE mysql;
		
		msg := 'Forwarded for review';
	ELSIF ($3 = '4') AND (reca.return_level <> 0) THEN
		INSERT INTO approvals (org_id, workflow_phase_id, table_name, table_id, org_entity_id, escalation_days, escalation_hours, approval_level, approval_narrative, to_be_done, approve_status)
		SELECT org_id, workflow_phase_id, reca.table_name, reca.table_id, CAST($2 as int), escalation_days, escalation_hours, approval_level, phase_narrative, reca.review_advice, 'Completed'
		FROM vw_workflow_entitys
		WHERE (workflow_id = reca.workflow_id) AND (approval_level = reca.return_level)
		ORDER BY workflow_phase_id;
		msg := 'Forwarded to owner for review';
	END IF;

	RETURN msg;
END;
$_$;


ALTER FUNCTION public.upd_approvals(character varying, character varying, character varying, character varying) OWNER TO root;

--
-- Name: upd_budget_lines(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_budget_lines() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	accountid 	INTEGER;
BEGIN

	IF(NEW.income_budget = true)THEN
		SELECT sales_account_id INTO accountid
		FROM items
		WHERE (item_id = NEW.item_id);
	ELSE
		SELECT purchase_account_id INTO accountid
		FROM items
		WHERE (item_id = NEW.item_id);
	END IF;

	IF(NEW.account_id is null) THEN
		NEW.account_id = accountid;
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.upd_budget_lines() OWNER TO postgres;

--
-- Name: upd_checklist(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION upd_checklist(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
	cl_id		Integer;
	reca 		RECORD;
	recc 		RECORD;
	msg 		varchar(120);
BEGIN
	cl_id := CAST($1 as int);
	
	SELECT approval_checklist_id, approval_id, checklist_id, requirement, manditory, done INTO reca
	FROM approval_checklists
	WHERE (approval_checklist_id = cl_id);

	IF ($3 = '1') THEN
		UPDATE approval_checklists SET done = true WHERE (approval_checklist_id = cl_id);

		SELECT count(approval_checklist_id) as cl_count INTO recc
		FROM approval_checklists
		WHERE (approval_id = reca.approval_id) AND (manditory = true) AND (done = false);
		msg := 'Checklist done.';

		IF(recc.cl_count = 0) THEN
			msg := upd_approvals(CAST(reca.approval_id as varchar(12)), $2, '2');
		END IF;
	ELSIF ($3 = '2') THEN
		UPDATE approval_checklists SET done = false WHERE (approval_checklist_id = cl_id);
		msg := 'Checklist not done.';
	END IF;

	RETURN msg;
END;
$_$;


ALTER FUNCTION public.upd_checklist(character varying, character varying, character varying) OWNER TO root;

--
-- Name: upd_complete_form(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION upd_complete_form(character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.upd_complete_form(character varying, character varying, character varying) OWNER TO root;

--
-- Name: upd_employee_adjustments(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_employee_adjustments() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	rec 		RECORD;
	entityid 	integer;
	periodid 	integer;
BEGIN
	SELECT monthly_update, running_balance INTO rec
	FROM adjustments WHERE adjustment_id = NEW.Adjustment_ID;

	SELECT entity_id, period_id INTO entityid, periodid
	FROM employee_month WHERE employee_month_id = NEW.employee_month_id;

	IF(rec.running_balance = true) AND (NEW.balance is not null)THEN
		UPDATE default_adjustments SET balance = NEW.balance
		WHERE (entity_id = entityid) AND (adjustment_id = NEW.adjustment_id);
	END IF;

	IF(TG_OP = 'UPDATE')THEN
		IF (OLD.amount <> NEW.amount)THEN
			IF(rec.monthly_update = true)THEN
				UPDATE default_adjustments SET amount = NEW.amount 
				WHERE (entity_id = entityid) AND (adjustment_id = NEW.adjustment_id);
			END IF;

			PERFORM updTax(employee_month_id, Period_id)
			FROM employee_month
			WHERE (period_id = periodid);
		END IF;
	ELSE
		PERFORM updTax(employee_month_id, Period_id)
		FROM employee_month
		WHERE (period_id = periodid);
	END IF;

	RETURN NULL;
END;
$$;


ALTER FUNCTION public.upd_employee_adjustments() OWNER TO postgres;

--
-- Name: upd_employee_month(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_employee_month() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO employee_tax_types (org_id, employee_month_id, tax_type_id, tax_identification, additional, amount, employer, in_tax, exchange_rate)
	SELECT NEW.org_id, NEW.employee_month_id, default_tax_types.tax_type_id, default_tax_types.tax_identification, 
		Default_Tax_Types.Additional, 0, 0, Tax_Types.In_Tax,
		(CASE WHEN Tax_Types.currency_id = NEW.currency_id THEN 1 ELSE 1 / NEW.exchange_rate END)
	FROM Default_Tax_Types INNER JOIN Tax_Types ON Default_Tax_Types.Tax_Type_id = Tax_Types.Tax_Type_id
	WHERE (Default_Tax_Types.active = true) AND (Default_Tax_Types.entity_ID = NEW.entity_ID);

	INSERT INTO employee_adjustments (org_id, employee_month_id, adjustment_id, amount, adjustment_type, in_payroll, in_tax, visible, adjustment_factor, balance, tax_relief_amount, exchange_rate)
	SELECT NEW.org_id, NEW.employee_month_id, default_adjustments.adjustment_id, default_adjustments.amount,
		adjustments.adjustment_type, adjustments.in_payroll, adjustments.in_tax, adjustments.visible,
		(CASE WHEN adjustments.adjustment_type = 2 THEN -1 ELSE 1 END),
		(CASE WHEN (adjustments.running_balance = true) AND (adjustments.reduce_balance = false) THEN (default_adjustments.balance + default_adjustments.amount)
			WHEN (adjustments.running_balance = true) AND (adjustments.reduce_balance = true) THEN (default_adjustments.balance - default_adjustments.amount) END),
		(default_adjustments.amount * adjustments.tax_relief_ps / 100),
		(CASE WHEN adjustments.currency_id = NEW.currency_id THEN 1 ELSE 1 / NEW.exchange_rate END)
	FROM default_adjustments INNER JOIN adjustments ON default_adjustments.adjustment_id = adjustments.adjustment_id
	WHERE ((default_adjustments.final_date is null) OR (default_adjustments.final_date > current_date))
		AND (default_adjustments.active = true) AND (default_adjustments.entity_id = NEW.entity_id);

	INSERT INTO advance_deductions (org_id, amount, employee_month_id)
	SELECT NEW.org_id, (Amount / Pay_Period), NEW.Employee_Month_ID
	FROM Employee_Advances INNER JOIN Employee_Month ON Employee_Advances.Employee_Month_ID = Employee_Month.Employee_Month_ID
	WHERE (entity_ID = NEW.entity_ID) AND (Pay_Period > 0) AND (completed = false)
		AND (Pay_upto >= current_date);

	RETURN NULL;
END;
$$;


ALTER FUNCTION public.upd_employee_month() OWNER TO postgres;

--
-- Name: upd_employee_per_diem(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_employee_per_diem() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	periodid integer;
	taxLimit real;
BEGIN
	SELECT Periods.Period_ID, Periods.Per_Diem_tax_limit INTO periodid, taxLimit
	FROM Employee_Month INNER JOIN Periods ON Employee_Month.Period_id = Periods.Period_id
	WHERE Employee_Month_ID = NEW.Employee_Month_ID;

	IF(NEW.Cash_paid = 0) THEN
		NEW.Cash_paid := NEW.Per_Diem;
	END IF;
	IF(NEW.tax_amount = 0) THEN
		NEW.full_amount := (NEW.Per_Diem - (taxLimit * NEW.days_travelled * 0.3)) / 0.7;
		NEW.tax_amount := NEW.full_amount - (taxLimit * NEW.days_travelled);
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.upd_employee_per_diem() OWNER TO postgres;

--
-- Name: upd_gls(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_gls() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	isposted BOOLEAN;
BEGIN
	SELECT posted INTO isposted
	FROM journals 
	WHERE (journal_id = NEW.journal_id);

	IF (isposted = true) THEN
		RAISE EXCEPTION '% Journal is already posted no changes are allowed.', NEW.journal_id;
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.upd_gls() OWNER TO postgres;

--
-- Name: upd_objective_details(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_objective_details() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.upd_objective_details() OWNER TO postgres;

--
-- Name: upd_reviews(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_reviews(character varying, character varying, character varying, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.upd_reviews(character varying, character varying, character varying, character varying) OWNER TO postgres;

--
-- Name: upd_transaction_details(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_transaction_details() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	statusID 	INTEGER;
	journalID 	INTEGER;
	v_for_sale	BOOLEAN;
	accountid 	INTEGER;
	taxrate 	REAL;
BEGIN
	SELECT transactions.transaction_status_id, transactions.journal_id, transaction_types.for_sales
		INTO statusID, journalID, v_for_sale
	FROM transaction_types INNER JOIN transactions ON transaction_types.transaction_type_id = transactions.transaction_type_id
	WHERE (transaction_id = NEW.transaction_id);

	IF ((statusID > 1) OR (journalID is not null)) THEN
		RAISE EXCEPTION 'Transaction is already posted no changes are allowed.';
	END IF;

	IF(v_for_sale = true)THEN
		SELECT items.sales_account_id, tax_types.tax_rate INTO accountid, taxrate
		FROM tax_types INNER JOIN items ON tax_types.tax_type_id = items.tax_type_id
		WHERE (items.item_id = NEW.item_id);
	ELSE
		SELECT items.purchase_account_id, tax_types.tax_rate INTO accountid, taxrate
		FROM tax_types INNER JOIN items ON tax_types.tax_type_id = items.tax_type_id
		WHERE (items.item_id = NEW.item_id);
	END IF;

	NEW.tax_amount := NEW.amount * taxrate / 100;
	IF(accountid is not null)THEN
		NEW.account_id := accountid;
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.upd_transaction_details() OWNER TO postgres;

--
-- Name: upd_transactions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION upd_transactions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	transid 	INTEGER;
	currid		INTEGER;
BEGIN

	IF(TG_OP = 'INSERT') THEN
		SELECT document_number INTO transid
		FROM transaction_types WHERE (transaction_type_id = NEW.transaction_type_id);
		UPDATE transaction_types SET document_number = transid + 1 WHERE (transaction_type_id = NEW.transaction_type_id);

		NEW.document_number := transid;
		IF(NEW.currency_id is null)THEN
			SELECT currency_id INTO NEW.currency_id
			FROM orgs
			WHERE (org_id = NEW.org_id);
		END IF;
	ELSE
		IF (OLD.journal_id is null) AND (NEW.journal_id is not null) THEN
		ELSIF ((OLD.approve_status = 'Completed') AND (NEW.approve_status != 'Completed')) THEN
		ELSIF ((OLD.journal_id is not null) AND (OLD.transaction_status_id = NEW.transaction_status_id)) THEN
			RAISE EXCEPTION 'Transaction % is already posted no changes are allowed.', NEW.transaction_id;
		ELSIF ((OLD.transaction_status_id > 1) AND (OLD.transaction_status_id = NEW.transaction_status_id)) THEN
			RAISE EXCEPTION 'Transaction % is already completed no changes are allowed.', NEW.transaction_id;
		END IF;
	END IF;

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.upd_transactions() OWNER TO postgres;

--
-- Name: updtax(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION updtax(integer, integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $_$
DECLARE
	reca 				RECORD;
	income 				REAL;
	tax 				REAL;
	InsuranceRelief 	REAL;
BEGIN

	FOR reca IN SELECT employee_tax_types.employee_tax_type_id, employee_tax_types.tax_type_id, period_tax_types.formural,
			 period_tax_types.employer, period_tax_types.employer_ps
		FROM employee_tax_types INNER JOIN period_tax_types ON (employee_tax_types.tax_type_id = period_tax_types.tax_type_id)
		WHERE (employee_month_id = $1) AND (Period_Tax_Types.Period_ID = $2)
		ORDER BY Period_Tax_Types.Tax_Type_order LOOP

		EXECUTE 'SELECT ' || reca.Formural || ' FROM employee_tax_types WHERE employee_tax_type_id = ' || reca.employee_tax_type_id 
		INTO tax;

		UPDATE employee_tax_types SET amount = tax, employer = reca.employer + (tax * reca.employer_ps / 100)
		WHERE employee_tax_type_id = reca.employee_tax_type_id;
	END LOOP;

	RETURN tax;
END;
$_$;


ALTER FUNCTION public.updtax(integer, integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE account_types (
    account_type_id integer NOT NULL,
    org_id integer,
    accounts_class_id integer,
    account_type_name character varying(120) NOT NULL,
    details text
);


ALTER TABLE public.account_types OWNER TO postgres;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE accounts (
    account_id integer NOT NULL,
    org_id integer,
    account_type_id integer,
    account_name character varying(120) NOT NULL,
    is_header boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    details text
);


ALTER TABLE public.accounts OWNER TO postgres;

--
-- Name: accounts_class; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE accounts_class (
    accounts_class_id integer NOT NULL,
    org_id integer,
    chat_type_id integer NOT NULL,
    chat_type_name character varying(50) NOT NULL,
    accounts_class_name character varying(120) NOT NULL,
    details text
);


ALTER TABLE public.accounts_class OWNER TO postgres;

--
-- Name: address; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE address (
    address_id integer NOT NULL,
    address_type_id integer,
    sys_country_id character(2),
    org_id integer,
    address_name character varying(120),
    table_name character varying(32),
    table_id integer,
    post_office_box character varying(50),
    postal_code character varying(12),
    premises character varying(120),
    street character varying(120),
    town character varying(50),
    phone_number character varying(150),
    extension character varying(15),
    mobile character varying(150),
    fax character varying(150),
    email character varying(120),
    website character varying(120),
    is_default boolean,
    first_password character varying(32),
    details text,
    company_name character varying(50),
    position_held character varying(50)
);


ALTER TABLE public.address OWNER TO root;

--
-- Name: address_address_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE address_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.address_address_id_seq OWNER TO root;

--
-- Name: address_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE address_address_id_seq OWNED BY address.address_id;


--
-- Name: address_types; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE address_types (
    address_type_id integer NOT NULL,
    org_id integer,
    address_type_name character varying(50)
);


ALTER TABLE public.address_types OWNER TO root;

--
-- Name: address_types_address_type_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE address_types_address_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.address_types_address_type_id_seq OWNER TO root;

--
-- Name: address_types_address_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE address_types_address_type_id_seq OWNED BY address_types.address_type_id;


--
-- Name: adjustments; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE adjustments (
    adjustment_id integer NOT NULL,
    currency_id integer,
    org_id integer,
    adjustment_name character varying(50) NOT NULL,
    adjustment_type integer NOT NULL,
    adjustment_order integer DEFAULT 0 NOT NULL,
    earning_code integer,
    formural character varying(430),
    monthly_update boolean DEFAULT true NOT NULL,
    in_payroll boolean DEFAULT true NOT NULL,
    in_tax boolean DEFAULT true NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    running_balance boolean DEFAULT false NOT NULL,
    reduce_balance boolean DEFAULT false NOT NULL,
    tax_reduction_ps double precision DEFAULT 0 NOT NULL,
    tax_relief_ps double precision DEFAULT 0 NOT NULL,
    tax_max_allowed double precision DEFAULT 0 NOT NULL,
    account_number character varying(32),
    details text
);


ALTER TABLE public.adjustments OWNER TO postgres;

--
-- Name: adjustments_adjustment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE adjustments_adjustment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.adjustments_adjustment_id_seq OWNER TO postgres;

--
-- Name: adjustments_adjustment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE adjustments_adjustment_id_seq OWNED BY adjustments.adjustment_id;


--
-- Name: advance_deductions; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE advance_deductions (
    advance_deduction_id integer NOT NULL,
    employee_month_id integer NOT NULL,
    org_id integer,
    pay_date date DEFAULT ('now'::text)::date NOT NULL,
    amount double precision NOT NULL,
    exchange_rate real DEFAULT 1 NOT NULL,
    in_payroll boolean DEFAULT true NOT NULL,
    narrative character varying(240)
);


ALTER TABLE public.advance_deductions OWNER TO postgres;

--
-- Name: advance_deductions_advance_deduction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE advance_deductions_advance_deduction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.advance_deductions_advance_deduction_id_seq OWNER TO postgres;

--
-- Name: advance_deductions_advance_deduction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE advance_deductions_advance_deduction_id_seq OWNED BY advance_deductions.advance_deduction_id;


--
-- Name: amortisation; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE amortisation (
    amortisation_id integer NOT NULL,
    org_id integer,
    asset_id integer,
    amortisation_year integer,
    asset_value real,
    amount real,
    posted boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.amortisation OWNER TO postgres;

--
-- Name: amortisation_amortisation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE amortisation_amortisation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.amortisation_amortisation_id_seq OWNER TO postgres;

--
-- Name: amortisation_amortisation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE amortisation_amortisation_id_seq OWNED BY amortisation.amortisation_id;


--
-- Name: applicants; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE applicants (
    entity_id integer NOT NULL,
    disability_id integer,
    org_id integer,
    person_title character varying(7),
    surname character varying(50) NOT NULL,
    first_name character varying(50) NOT NULL,
    middle_name character varying(50),
    applicant_email character varying(50) NOT NULL,
    applicant_phone character varying(50),
    date_of_birth date,
    gender character varying(1),
    nationality character(2),
    marital_status character varying(2),
    picture_file character varying(32),
    identity_card character varying(50),
    language character varying(320),
    field_of_study text,
    interests text,
    objective text,
    details text
);


ALTER TABLE public.applicants OWNER TO postgres;

--
-- Name: applications; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE applications (
    application_id integer NOT NULL,
    intake_id integer,
    contract_type_id integer,
    contract_status_id integer,
    entity_id integer,
    employee_id integer,
    org_id integer,
    contract_date date,
    contract_close date,
    contract_start date,
    contract_period integer,
    contract_terms text,
    initial_salary real,
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    short_listed integer DEFAULT 0 NOT NULL,
    applicant_comments text,
    review text
);


ALTER TABLE public.applications OWNER TO postgres;

--
-- Name: applications_application_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE applications_application_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.applications_application_id_seq OWNER TO postgres;

--
-- Name: applications_application_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE applications_application_id_seq OWNED BY applications.application_id;


--
-- Name: approval_checklists; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE approval_checklists (
    approval_checklist_id integer NOT NULL,
    approval_id integer NOT NULL,
    checklist_id integer NOT NULL,
    org_id integer,
    requirement text,
    manditory boolean DEFAULT false NOT NULL,
    done boolean DEFAULT false NOT NULL,
    narrative character varying(320)
);


ALTER TABLE public.approval_checklists OWNER TO root;

--
-- Name: approval_checklists_approval_checklist_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE approval_checklists_approval_checklist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.approval_checklists_approval_checklist_id_seq OWNER TO root;

--
-- Name: approval_checklists_approval_checklist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE approval_checklists_approval_checklist_id_seq OWNED BY approval_checklists.approval_checklist_id;


--
-- Name: approvals; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE approvals (
    approval_id integer NOT NULL,
    workflow_phase_id integer NOT NULL,
    org_entity_id integer NOT NULL,
    app_entity_id integer,
    org_id integer,
    approval_level integer DEFAULT 1 NOT NULL,
    escalation_days integer DEFAULT 0 NOT NULL,
    escalation_hours integer DEFAULT 3 NOT NULL,
    escalation_time timestamp without time zone DEFAULT now() NOT NULL,
    forward_id integer,
    table_name character varying(64),
    table_id integer,
    application_date timestamp without time zone DEFAULT now() NOT NULL,
    completion_date timestamp without time zone,
    action_date timestamp without time zone,
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    approval_narrative character varying(240),
    to_be_done text,
    what_is_done text,
    review_advice text,
    details text
);


ALTER TABLE public.approvals OWNER TO root;

--
-- Name: approvals_approval_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE approvals_approval_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.approvals_approval_id_seq OWNER TO root;

--
-- Name: approvals_approval_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE approvals_approval_id_seq OWNED BY approvals.approval_id;


--
-- Name: asset_movement; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE asset_movement (
    asset_movement_id integer NOT NULL,
    org_id integer,
    asset_id integer,
    department_id integer,
    date_aquired date,
    date_left date,
    details text
);


ALTER TABLE public.asset_movement OWNER TO postgres;

--
-- Name: asset_movement_asset_movement_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE asset_movement_asset_movement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.asset_movement_asset_movement_id_seq OWNER TO postgres;

--
-- Name: asset_movement_asset_movement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE asset_movement_asset_movement_id_seq OWNED BY asset_movement.asset_movement_id;


--
-- Name: asset_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE asset_types (
    asset_type_id integer NOT NULL,
    org_id integer,
    asset_type_name character varying(50) NOT NULL,
    depreciation_rate real DEFAULT 10 NOT NULL,
    asset_account integer,
    depreciation_account integer,
    accumulated_account integer,
    valuation_account integer,
    disposal_account integer,
    details text
);


ALTER TABLE public.asset_types OWNER TO postgres;

--
-- Name: asset_types_asset_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE asset_types_asset_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.asset_types_asset_type_id_seq OWNER TO postgres;

--
-- Name: asset_types_asset_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE asset_types_asset_type_id_seq OWNED BY asset_types.asset_type_id;


--
-- Name: asset_valuations; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE asset_valuations (
    asset_valuation_id integer NOT NULL,
    org_id integer,
    asset_id integer,
    valuation_year integer,
    asset_value real DEFAULT 0 NOT NULL,
    value_change real DEFAULT 0 NOT NULL,
    posted boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.asset_valuations OWNER TO postgres;

--
-- Name: asset_valuations_asset_valuation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE asset_valuations_asset_valuation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.asset_valuations_asset_valuation_id_seq OWNER TO postgres;

--
-- Name: asset_valuations_asset_valuation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE asset_valuations_asset_valuation_id_seq OWNED BY asset_valuations.asset_valuation_id;


--
-- Name: assets; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE assets (
    asset_id integer NOT NULL,
    org_id integer,
    asset_type_id integer,
    item_id integer,
    asset_name character varying(50),
    asset_serial character varying(50),
    purchase_date date NOT NULL,
    purchase_value real NOT NULL,
    disposal_amount real,
    disposal_date date,
    disposal_posting boolean DEFAULT false NOT NULL,
    lost boolean DEFAULT false NOT NULL,
    stolen boolean DEFAULT false NOT NULL,
    tag_number character varying(50),
    asset_location character varying(50),
    asset_condition character varying(50),
    asset_acquisition character varying(50),
    details text
);


ALTER TABLE public.assets OWNER TO postgres;

--
-- Name: assets_asset_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE assets_asset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assets_asset_id_seq OWNER TO postgres;

--
-- Name: assets_asset_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE assets_asset_id_seq OWNED BY assets.asset_id;


--
-- Name: attendance; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE attendance (
    attendance_id integer NOT NULL,
    entity_id integer,
    org_id integer,
    attendance_date date,
    time_in time without time zone,
    time_out time without time zone,
    details text
);


ALTER TABLE public.attendance OWNER TO postgres;

--
-- Name: attendance_attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE attendance_attendance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attendance_attendance_id_seq OWNER TO postgres;

--
-- Name: attendance_attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE attendance_attendance_id_seq OWNED BY attendance.attendance_id;


--
-- Name: bank_accounts; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bank_accounts (
    bank_account_id integer NOT NULL,
    org_id integer,
    bank_branch_id integer,
    account_id integer,
    currency_id integer,
    bank_account_name character varying(120),
    bank_account_number character varying(50),
    narrative character varying(240),
    is_default boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    details text
);


ALTER TABLE public.bank_accounts OWNER TO postgres;

--
-- Name: bank_accounts_bank_account_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE bank_accounts_bank_account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bank_accounts_bank_account_id_seq OWNER TO postgres;

--
-- Name: bank_accounts_bank_account_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE bank_accounts_bank_account_id_seq OWNED BY bank_accounts.bank_account_id;


--
-- Name: bank_branch; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bank_branch (
    bank_branch_id integer NOT NULL,
    bank_id integer,
    org_id integer,
    bank_branch_name character varying(50) NOT NULL,
    bank_branch_code character varying(50),
    narrative character varying(240)
);


ALTER TABLE public.bank_branch OWNER TO postgres;

--
-- Name: bank_branch_bank_branch_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE bank_branch_bank_branch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bank_branch_bank_branch_id_seq OWNER TO postgres;

--
-- Name: bank_branch_bank_branch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE bank_branch_bank_branch_id_seq OWNED BY bank_branch.bank_branch_id;


--
-- Name: banks; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE banks (
    bank_id integer NOT NULL,
    sys_country_id character(2),
    org_id integer,
    bank_name character varying(50) NOT NULL,
    bank_code character varying(25),
    swift_code character varying(25),
    sort_code character varying(25),
    narrative character varying(240)
);


ALTER TABLE public.banks OWNER TO postgres;

--
-- Name: banks_bank_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE banks_bank_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.banks_bank_id_seq OWNER TO postgres;

--
-- Name: banks_bank_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE banks_bank_id_seq OWNED BY banks.bank_id;


--
-- Name: bidders; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bidders (
    bidder_id integer NOT NULL,
    org_id integer,
    tender_id integer,
    entity_id integer,
    bidder_name character varying(120),
    tender_amount real,
    bind_bond character varying(120),
    bind_bond_amount real,
    return_date date,
    points real,
    is_awarded boolean NOT NULL,
    award_reference character varying(32),
    details text
);


ALTER TABLE public.bidders OWNER TO postgres;

--
-- Name: bidders_bidder_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE bidders_bidder_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bidders_bidder_id_seq OWNER TO postgres;

--
-- Name: bidders_bidder_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE bidders_bidder_id_seq OWNED BY bidders.bidder_id;


--
-- Name: bio_imports1; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bio_imports1 (
    bio_imports1_id integer NOT NULL,
    org_id integer,
    col1 character varying(50),
    col2 character varying(50),
    col3 character varying(50),
    col4 character varying(50),
    col5 character varying(50),
    col6 character varying(50),
    col7 character varying(50),
    col8 character varying(50),
    col9 character varying(50),
    col10 character varying(50),
    col11 character varying(50),
    is_picked boolean DEFAULT false
);


ALTER TABLE public.bio_imports1 OWNER TO postgres;

--
-- Name: bio_imports1_bio_imports1_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE bio_imports1_bio_imports1_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bio_imports1_bio_imports1_id_seq OWNER TO postgres;

--
-- Name: bio_imports1_bio_imports1_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE bio_imports1_bio_imports1_id_seq OWNED BY bio_imports1.bio_imports1_id;


--
-- Name: budget_lines; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE budget_lines (
    budget_line_id integer NOT NULL,
    org_id integer,
    budget_id integer,
    period_id integer,
    account_id integer,
    item_id integer,
    transaction_id integer,
    spend_type integer DEFAULT 0 NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    amount real DEFAULT 0 NOT NULL,
    tax_amount real DEFAULT 0 NOT NULL,
    income_budget boolean DEFAULT false NOT NULL,
    narrative character varying(240),
    details text
);


ALTER TABLE public.budget_lines OWNER TO postgres;

--
-- Name: budget_lines_budget_line_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE budget_lines_budget_line_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.budget_lines_budget_line_id_seq OWNER TO postgres;

--
-- Name: budget_lines_budget_line_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE budget_lines_budget_line_id_seq OWNED BY budget_lines.budget_line_id;


--
-- Name: budgets; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE budgets (
    budget_id integer NOT NULL,
    org_id integer,
    fiscal_year_id character varying(9),
    department_id integer,
    link_budget_id integer,
    entity_id integer,
    budget_type integer DEFAULT 1 NOT NULL,
    budget_name character varying(50),
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    details text
);


ALTER TABLE public.budgets OWNER TO postgres;

--
-- Name: budgets_budget_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE budgets_budget_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.budgets_budget_id_seq OWNER TO postgres;

--
-- Name: budgets_budget_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE budgets_budget_id_seq OWNED BY budgets.budget_id;


--
-- Name: career_development; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE career_development (
    career_development_id integer NOT NULL,
    org_id integer,
    career_development_name character varying(50) NOT NULL,
    details text
);


ALTER TABLE public.career_development OWNER TO postgres;

--
-- Name: career_development_career_development_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE career_development_career_development_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.career_development_career_development_id_seq OWNER TO postgres;

--
-- Name: career_development_career_development_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE career_development_career_development_id_seq OWNED BY career_development.career_development_id;


--
-- Name: case_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE case_types (
    case_type_id integer NOT NULL,
    org_id integer,
    case_type_name character varying(50),
    details text
);


ALTER TABLE public.case_types OWNER TO postgres;

--
-- Name: case_types_case_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE case_types_case_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.case_types_case_type_id_seq OWNER TO postgres;

--
-- Name: case_types_case_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE case_types_case_type_id_seq OWNED BY case_types.case_type_id;


--
-- Name: casual_application; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE casual_application (
    casual_application_id integer NOT NULL,
    department_id integer,
    casual_category_id integer,
    entity_id integer,
    org_id integer,
    "position" integer DEFAULT 1 NOT NULL,
    work_duration integer DEFAULT 1 NOT NULL,
    approved_pay_rate real,
    approve_status character varying(16) DEFAULT 'draft'::character varying NOT NULL,
    workflow_table_id integer,
    application_date timestamp without time zone DEFAULT now(),
    action_date timestamp without time zone,
    details text
);


ALTER TABLE public.casual_application OWNER TO postgres;

--
-- Name: casual_application_casual_application_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE casual_application_casual_application_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.casual_application_casual_application_id_seq OWNER TO postgres;

--
-- Name: casual_application_casual_application_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE casual_application_casual_application_id_seq OWNED BY casual_application.casual_application_id;


--
-- Name: casual_category; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE casual_category (
    casual_category_id integer NOT NULL,
    org_id integer,
    casual_category_name character varying(50),
    details text
);


ALTER TABLE public.casual_category OWNER TO postgres;

--
-- Name: casual_category_casual_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE casual_category_casual_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.casual_category_casual_category_id_seq OWNER TO postgres;

--
-- Name: casual_category_casual_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE casual_category_casual_category_id_seq OWNED BY casual_category.casual_category_id;


--
-- Name: casuals; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE casuals (
    casual_id integer NOT NULL,
    entity_id integer,
    casual_application_id integer,
    org_id integer,
    start_date date,
    end_date date,
    duration integer,
    pay_rate real,
    amount_paid real,
    paid boolean DEFAULT false NOT NULL,
    approve_status character varying(16) DEFAULT 'draft'::character varying NOT NULL,
    workflow_table_id integer,
    application_date timestamp without time zone DEFAULT now(),
    action_date timestamp without time zone,
    details text
);


ALTER TABLE public.casuals OWNER TO postgres;

--
-- Name: casuals_casual_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE casuals_casual_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.casuals_casual_id_seq OWNER TO postgres;

--
-- Name: casuals_casual_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE casuals_casual_id_seq OWNED BY casuals.casual_id;


--
-- Name: checklists; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE checklists (
    checklist_id integer NOT NULL,
    workflow_phase_id integer NOT NULL,
    org_id integer,
    checklist_number integer,
    manditory boolean DEFAULT false NOT NULL,
    requirement text,
    details text
);


ALTER TABLE public.checklists OWNER TO root;

--
-- Name: checklists_checklist_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE checklists_checklist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.checklists_checklist_id_seq OWNER TO root;

--
-- Name: checklists_checklist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE checklists_checklist_id_seq OWNED BY checklists.checklist_id;


--
-- Name: claim_details; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE claim_details (
    claim_detail_id integer NOT NULL,
    claim_id integer,
    currency_id integer,
    org_id integer,
    nature_of_expence character varying(50),
    receipt_number character varying(50),
    amount real NOT NULL,
    exchange_rate real DEFAULT 1 NOT NULL,
    expense_code character varying(50),
    details text
);


ALTER TABLE public.claim_details OWNER TO postgres;

--
-- Name: claim_details_claim_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE claim_details_claim_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.claim_details_claim_detail_id_seq OWNER TO postgres;

--
-- Name: claim_details_claim_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE claim_details_claim_detail_id_seq OWNED BY claim_details.claim_detail_id;


--
-- Name: claim_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE claim_types (
    claim_type_id integer NOT NULL,
    adjustment_id integer,
    org_id integer,
    claim_type_name character varying(50),
    details text
);


ALTER TABLE public.claim_types OWNER TO postgres;

--
-- Name: claim_types_claim_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE claim_types_claim_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.claim_types_claim_type_id_seq OWNER TO postgres;

--
-- Name: claim_types_claim_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE claim_types_claim_type_id_seq OWNED BY claim_types.claim_type_id;


--
-- Name: claims; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE claims (
    claim_id integer NOT NULL,
    claim_type_id integer,
    entity_id integer,
    employee_adjustment_id integer,
    org_id integer,
    claim_date date NOT NULL,
    in_payroll boolean DEFAULT false NOT NULL,
    narrative character varying(250),
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    details text
);


ALTER TABLE public.claims OWNER TO postgres;

--
-- Name: claims_claim_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE claims_claim_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.claims_claim_id_seq OWNER TO postgres;

--
-- Name: claims_claim_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE claims_claim_id_seq OWNED BY claims.claim_id;


--
-- Name: contract_status; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE contract_status (
    contract_status_id integer NOT NULL,
    org_id integer,
    contract_status_name character varying(50) NOT NULL,
    details text
);


ALTER TABLE public.contract_status OWNER TO postgres;

--
-- Name: contract_status_contract_status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE contract_status_contract_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contract_status_contract_status_id_seq OWNER TO postgres;

--
-- Name: contract_status_contract_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE contract_status_contract_status_id_seq OWNED BY contract_status.contract_status_id;


--
-- Name: contract_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE contract_types (
    contract_type_id integer NOT NULL,
    org_id integer,
    contract_type_name character varying(50) NOT NULL,
    details text
);


ALTER TABLE public.contract_types OWNER TO postgres;

--
-- Name: contract_types_contract_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE contract_types_contract_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contract_types_contract_type_id_seq OWNER TO postgres;

--
-- Name: contract_types_contract_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE contract_types_contract_type_id_seq OWNED BY contract_types.contract_type_id;


--
-- Name: contracts; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE contracts (
    contract_id integer NOT NULL,
    org_id integer,
    bidder_id integer,
    contract_name character varying(320) NOT NULL,
    contract_date date,
    contract_end date,
    contract_amount real,
    contract_tax real,
    details text
);


ALTER TABLE public.contracts OWNER TO postgres;

--
-- Name: contracts_contract_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE contracts_contract_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contracts_contract_id_seq OWNER TO postgres;

--
-- Name: contracts_contract_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE contracts_contract_id_seq OWNED BY contracts.contract_id;


--
-- Name: currency; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE currency (
    currency_id integer NOT NULL,
    currency_name character varying(50),
    currency_symbol character varying(3),
    org_id integer
);


ALTER TABLE public.currency OWNER TO root;

--
-- Name: currency_currency_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE currency_currency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.currency_currency_id_seq OWNER TO root;

--
-- Name: currency_currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE currency_currency_id_seq OWNED BY currency.currency_id;


--
-- Name: currency_rates; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE currency_rates (
    currency_rate_id integer NOT NULL,
    currency_id integer,
    org_id integer,
    exchange_date date DEFAULT ('now'::text)::date NOT NULL,
    exchange_rate real DEFAULT 1 NOT NULL
);


ALTER TABLE public.currency_rates OWNER TO root;

--
-- Name: currency_rates_currency_rate_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE currency_rates_currency_rate_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.currency_rates_currency_rate_id_seq OWNER TO root;

--
-- Name: currency_rates_currency_rate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE currency_rates_currency_rate_id_seq OWNED BY currency_rates.currency_rate_id;


--
-- Name: cv_projects; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE cv_projects (
    cv_projectid integer NOT NULL,
    entity_id integer,
    org_id integer,
    cv_project_name character varying(240),
    cv_project_date date NOT NULL,
    details text
);


ALTER TABLE public.cv_projects OWNER TO postgres;

--
-- Name: cv_projects_cv_projectid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE cv_projects_cv_projectid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cv_projects_cv_projectid_seq OWNER TO postgres;

--
-- Name: cv_projects_cv_projectid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE cv_projects_cv_projectid_seq OWNED BY cv_projects.cv_projectid;


--
-- Name: cv_seminars; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE cv_seminars (
    cv_seminar_id integer NOT NULL,
    entity_id integer,
    org_id integer,
    cv_seminar_name character varying(240),
    cv_seminar_date date NOT NULL,
    details text
);


ALTER TABLE public.cv_seminars OWNER TO postgres;

--
-- Name: cv_seminars_cv_seminar_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE cv_seminars_cv_seminar_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cv_seminars_cv_seminar_id_seq OWNER TO postgres;

--
-- Name: cv_seminars_cv_seminar_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE cv_seminars_cv_seminar_id_seq OWNED BY cv_seminars.cv_seminar_id;


--
-- Name: day_ledgers; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE day_ledgers (
    day_ledger_id integer NOT NULL,
    entity_id integer,
    transaction_type_id integer,
    bank_account_id integer,
    journal_id integer,
    transaction_status_id integer DEFAULT 1,
    currency_id integer,
    department_id integer,
    item_id integer,
    store_id integer,
    org_id integer,
    exchange_rate real DEFAULT 1 NOT NULL,
    day_ledger_date date NOT NULL,
    day_ledger_quantity integer NOT NULL,
    day_ledger_amount real DEFAULT 0 NOT NULL,
    day_ledger_tax_amount real DEFAULT 0 NOT NULL,
    document_number integer DEFAULT 1 NOT NULL,
    payment_number character varying(50),
    order_number character varying(50),
    payment_terms character varying(50),
    job character varying(240),
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    narrative character varying(120),
    details text
);


ALTER TABLE public.day_ledgers OWNER TO postgres;

--
-- Name: day_ledgers_day_ledger_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE day_ledgers_day_ledger_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.day_ledgers_day_ledger_id_seq OWNER TO postgres;

--
-- Name: day_ledgers_day_ledger_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE day_ledgers_day_ledger_id_seq OWNED BY day_ledgers.day_ledger_id;


--
-- Name: default_accounts; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE default_accounts (
    default_account_id integer NOT NULL,
    org_id integer,
    account_id integer,
    narrative character varying(240)
);


ALTER TABLE public.default_accounts OWNER TO postgres;

--
-- Name: default_adjustments; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE default_adjustments (
    default_adjustment_id integer NOT NULL,
    entity_id integer,
    adjustment_id integer,
    org_id integer,
    amount double precision DEFAULT 0 NOT NULL,
    balance double precision DEFAULT 0 NOT NULL,
    final_date date,
    active boolean DEFAULT true,
    narrative character varying(240)
);


ALTER TABLE public.default_adjustments OWNER TO postgres;

--
-- Name: default_adjustments_default_adjustment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE default_adjustments_default_adjustment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.default_adjustments_default_adjustment_id_seq OWNER TO postgres;

--
-- Name: default_adjustments_default_adjustment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE default_adjustments_default_adjustment_id_seq OWNED BY default_adjustments.default_adjustment_id;


--
-- Name: default_banking; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE default_banking (
    default_banking_id integer NOT NULL,
    entity_id integer,
    bank_branch_id integer,
    currency_id integer,
    org_id integer,
    amount double precision DEFAULT 0 NOT NULL,
    ps_amount double precision DEFAULT 0 NOT NULL,
    final_date date,
    active boolean DEFAULT true,
    narrative character varying(240)
);


ALTER TABLE public.default_banking OWNER TO postgres;

--
-- Name: default_banking_default_banking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE default_banking_default_banking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.default_banking_default_banking_id_seq OWNER TO postgres;

--
-- Name: default_banking_default_banking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE default_banking_default_banking_id_seq OWNED BY default_banking.default_banking_id;


--
-- Name: default_tax_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE default_tax_types (
    default_tax_type_id integer NOT NULL,
    entity_id integer,
    tax_type_id integer,
    org_id integer,
    tax_identification character varying(50),
    narrative character varying(240),
    additional double precision DEFAULT 0 NOT NULL,
    active boolean DEFAULT true
);


ALTER TABLE public.default_tax_types OWNER TO postgres;

--
-- Name: default_tax_types_default_tax_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE default_tax_types_default_tax_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.default_tax_types_default_tax_type_id_seq OWNER TO postgres;

--
-- Name: default_tax_types_default_tax_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE default_tax_types_default_tax_type_id_seq OWNED BY default_tax_types.default_tax_type_id;


--
-- Name: define_phases; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE define_phases (
    define_phase_id integer NOT NULL,
    project_type_id integer,
    entity_type_id integer,
    org_id integer,
    define_phase_name character varying(240),
    define_phase_time real DEFAULT 0 NOT NULL,
    define_phase_cost real DEFAULT 0 NOT NULL,
    phase_order integer DEFAULT 0 NOT NULL,
    details text
);


ALTER TABLE public.define_phases OWNER TO postgres;

--
-- Name: define_phases_define_phase_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE define_phases_define_phase_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.define_phases_define_phase_id_seq OWNER TO postgres;

--
-- Name: define_phases_define_phase_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE define_phases_define_phase_id_seq OWNED BY define_phases.define_phase_id;


--
-- Name: define_tasks; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE define_tasks (
    define_task_id integer NOT NULL,
    define_phase_id integer,
    org_id integer,
    define_task_name character varying(240) NOT NULL,
    narrative character varying(120),
    details text
);


ALTER TABLE public.define_tasks OWNER TO postgres;

--
-- Name: define_tasks_define_task_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE define_tasks_define_task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.define_tasks_define_task_id_seq OWNER TO postgres;

--
-- Name: define_tasks_define_task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE define_tasks_define_task_id_seq OWNED BY define_tasks.define_task_id;


--
-- Name: department_roles; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE department_roles (
    department_role_id integer NOT NULL,
    department_id integer,
    ln_department_role_id integer,
    org_id integer,
    department_role_name character varying(240) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    job_description text,
    job_requirements text,
    duties text,
    performance_measures text,
    details text
);


ALTER TABLE public.department_roles OWNER TO postgres;

--
-- Name: department_roles_department_role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE department_roles_department_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.department_roles_department_role_id_seq OWNER TO postgres;

--
-- Name: department_roles_department_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE department_roles_department_role_id_seq OWNED BY department_roles.department_role_id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE departments (
    department_id integer NOT NULL,
    ln_department_id integer,
    org_id integer,
    department_name character varying(120),
    active boolean DEFAULT true NOT NULL,
    petty_cash boolean DEFAULT false NOT NULL,
    description text,
    duties text,
    reports text,
    details text
);


ALTER TABLE public.departments OWNER TO postgres;

--
-- Name: departments_department_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE departments_department_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.departments_department_id_seq OWNER TO postgres;

--
-- Name: departments_department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE departments_department_id_seq OWNED BY departments.department_id;


--
-- Name: disability; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE disability (
    disability_id integer NOT NULL,
    org_id integer,
    disability_name character varying(240) NOT NULL
);


ALTER TABLE public.disability OWNER TO postgres;

--
-- Name: disability_disability_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE disability_disability_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.disability_disability_id_seq OWNER TO postgres;

--
-- Name: disability_disability_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE disability_disability_id_seq OWNED BY disability.disability_id;


--
-- Name: education; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE education (
    education_id integer NOT NULL,
    entity_id integer,
    education_class_id integer,
    org_id integer,
    date_from date NOT NULL,
    date_to date,
    name_of_school character varying(240),
    examination_taken character varying(240),
    grades_obtained character varying(50),
    certificate_number character varying(50),
    details text
);


ALTER TABLE public.education OWNER TO postgres;

--
-- Name: education_class; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE education_class (
    education_class_id integer NOT NULL,
    org_id integer,
    education_class_name character varying(50),
    details text
);


ALTER TABLE public.education_class OWNER TO postgres;

--
-- Name: education_class_education_class_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE education_class_education_class_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.education_class_education_class_id_seq OWNER TO postgres;

--
-- Name: education_class_education_class_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE education_class_education_class_id_seq OWNED BY education_class.education_class_id;


--
-- Name: education_education_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE education_education_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.education_education_id_seq OWNER TO postgres;

--
-- Name: education_education_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE education_education_id_seq OWNED BY education.education_id;


--
-- Name: employee_adjustments; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_adjustments (
    employee_adjustment_id integer NOT NULL,
    employee_month_id integer NOT NULL,
    adjustment_id integer NOT NULL,
    org_id integer,
    adjustment_type integer,
    adjustment_factor integer DEFAULT 1 NOT NULL,
    pay_date date DEFAULT ('now'::text)::date NOT NULL,
    amount double precision NOT NULL,
    balance double precision,
    paid_amount double precision DEFAULT 0 NOT NULL,
    exchange_rate real DEFAULT 1 NOT NULL,
    tax_reduction_amount double precision DEFAULT 0 NOT NULL,
    tax_relief_amount double precision DEFAULT 0 NOT NULL,
    in_payroll boolean DEFAULT true NOT NULL,
    in_tax boolean DEFAULT true NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    narrative character varying(240)
);


ALTER TABLE public.employee_adjustments OWNER TO postgres;

--
-- Name: employee_adjustments_employee_adjustment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_adjustments_employee_adjustment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_adjustments_employee_adjustment_id_seq OWNER TO postgres;

--
-- Name: employee_adjustments_employee_adjustment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_adjustments_employee_adjustment_id_seq OWNED BY employee_adjustments.employee_adjustment_id;


--
-- Name: employee_advances; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_advances (
    employee_advance_id integer NOT NULL,
    employee_month_id integer NOT NULL,
    currency_id integer,
    org_id integer,
    pay_date date DEFAULT ('now'::text)::date NOT NULL,
    pay_upto date NOT NULL,
    pay_period integer DEFAULT 3 NOT NULL,
    amount double precision NOT NULL,
    payment_amount double precision NOT NULL,
    exchange_rate real DEFAULT 1 NOT NULL,
    in_payroll boolean DEFAULT false NOT NULL,
    completed boolean DEFAULT false NOT NULL,
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    narrative character varying(240)
);


ALTER TABLE public.employee_advances OWNER TO postgres;

--
-- Name: employee_advances_employee_advance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_advances_employee_advance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_advances_employee_advance_id_seq OWNER TO postgres;

--
-- Name: employee_advances_employee_advance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_advances_employee_advance_id_seq OWNED BY employee_advances.employee_advance_id;


--
-- Name: employee_banking; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_banking (
    default_banking_id integer NOT NULL,
    employee_month_id integer NOT NULL,
    bank_branch_id integer,
    currency_id integer,
    org_id integer,
    amount double precision DEFAULT 0 NOT NULL,
    exchange_rate real DEFAULT 1 NOT NULL,
    active boolean DEFAULT true,
    narrative character varying(240)
);


ALTER TABLE public.employee_banking OWNER TO postgres;

--
-- Name: employee_banking_default_banking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_banking_default_banking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_banking_default_banking_id_seq OWNER TO postgres;

--
-- Name: employee_banking_default_banking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_banking_default_banking_id_seq OWNED BY employee_banking.default_banking_id;


--
-- Name: employee_cases; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_cases (
    employee_case_id integer NOT NULL,
    case_type_id integer,
    entity_id integer,
    org_id integer,
    narrative character varying(240),
    case_date date,
    complaint text,
    case_action text,
    completed boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.employee_cases OWNER TO postgres;

--
-- Name: employee_cases_employee_case_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_cases_employee_case_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_cases_employee_case_id_seq OWNER TO postgres;

--
-- Name: employee_cases_employee_case_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_cases_employee_case_id_seq OWNED BY employee_cases.employee_case_id;


--
-- Name: employee_leave; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_leave (
    employee_leave_id integer NOT NULL,
    entity_id integer,
    contact_entity_id integer,
    leave_type_id integer,
    org_id integer,
    leave_from date NOT NULL,
    leave_to date NOT NULL,
    leave_days real NOT NULL,
    start_half_day boolean DEFAULT false NOT NULL,
    end_half_day boolean DEFAULT false NOT NULL,
    special_request boolean DEFAULT false NOT NULL,
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    completed boolean DEFAULT false NOT NULL,
    narrative character varying(240),
    details text
);


ALTER TABLE public.employee_leave OWNER TO postgres;

--
-- Name: employee_leave_employee_leave_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_leave_employee_leave_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_leave_employee_leave_id_seq OWNER TO postgres;

--
-- Name: employee_leave_employee_leave_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_leave_employee_leave_id_seq OWNED BY employee_leave.employee_leave_id;


--
-- Name: employee_leave_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_leave_types (
    employee_leave_type_id integer NOT NULL,
    entity_id integer,
    leave_type_id integer,
    org_id integer,
    leave_balance real DEFAULT 0 NOT NULL,
    leave_starting date DEFAULT ('now'::text)::date NOT NULL,
    details text
);


ALTER TABLE public.employee_leave_types OWNER TO postgres;

--
-- Name: employee_leave_types_employee_leave_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_leave_types_employee_leave_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_leave_types_employee_leave_type_id_seq OWNER TO postgres;

--
-- Name: employee_leave_types_employee_leave_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_leave_types_employee_leave_type_id_seq OWNED BY employee_leave_types.employee_leave_type_id;


--
-- Name: employee_month; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_month (
    employee_month_id integer NOT NULL,
    entity_id integer NOT NULL,
    period_id integer NOT NULL,
    bank_branch_id integer NOT NULL,
    pay_group_id integer NOT NULL,
    department_role_id integer NOT NULL,
    currency_id integer,
    org_id integer,
    exchange_rate real DEFAULT 1 NOT NULL,
    bank_account character varying(32),
    basic_pay double precision DEFAULT 0 NOT NULL,
    details text
);


ALTER TABLE public.employee_month OWNER TO postgres;

--
-- Name: employee_month_employee_month_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_month_employee_month_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_month_employee_month_id_seq OWNER TO postgres;

--
-- Name: employee_month_employee_month_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_month_employee_month_id_seq OWNED BY employee_month.employee_month_id;


--
-- Name: employee_objectives; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_objectives (
    employee_objective_id integer NOT NULL,
    entity_id integer,
    org_id integer,
    employee_objective_name character varying(320) NOT NULL,
    objective_date date NOT NULL,
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    application_date timestamp without time zone DEFAULT now(),
    action_date timestamp without time zone,
    supervisor_comments text,
    details text
);


ALTER TABLE public.employee_objectives OWNER TO postgres;

--
-- Name: employee_objectives_employee_objective_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_objectives_employee_objective_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_objectives_employee_objective_id_seq OWNER TO postgres;

--
-- Name: employee_objectives_employee_objective_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_objectives_employee_objective_id_seq OWNED BY employee_objectives.employee_objective_id;


--
-- Name: employee_overtime; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_overtime (
    employee_overtime_id integer NOT NULL,
    employee_month_id integer NOT NULL,
    org_id integer,
    overtime_date date NOT NULL,
    overtime double precision NOT NULL,
    overtime_rate double precision NOT NULL,
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    narrative character varying(240),
    details text
);


ALTER TABLE public.employee_overtime OWNER TO postgres;

--
-- Name: employee_overtime_employee_overtime_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_overtime_employee_overtime_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_overtime_employee_overtime_id_seq OWNER TO postgres;

--
-- Name: employee_overtime_employee_overtime_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_overtime_employee_overtime_id_seq OWNED BY employee_overtime.employee_overtime_id;


--
-- Name: employee_per_diem; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_per_diem (
    employee_per_diem_id integer NOT NULL,
    employee_month_id integer NOT NULL,
    currency_id integer,
    org_id integer,
    travel_date date NOT NULL,
    return_date date NOT NULL,
    days_travelled integer NOT NULL,
    per_diem double precision DEFAULT 0 NOT NULL,
    cash_paid double precision DEFAULT 0 NOT NULL,
    tax_amount double precision DEFAULT 0 NOT NULL,
    full_amount double precision DEFAULT 0 NOT NULL,
    exchange_rate real DEFAULT 1 NOT NULL,
    travel_to character varying(240),
    post_account character varying(32),
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    completed boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.employee_per_diem OWNER TO postgres;

--
-- Name: employee_per_diem_employee_per_diem_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_per_diem_employee_per_diem_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_per_diem_employee_per_diem_id_seq OWNER TO postgres;

--
-- Name: employee_per_diem_employee_per_diem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_per_diem_employee_per_diem_id_seq OWNED BY employee_per_diem.employee_per_diem_id;


--
-- Name: employee_tax_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_tax_types (
    employee_tax_type_id integer NOT NULL,
    employee_month_id integer NOT NULL,
    tax_type_id integer NOT NULL,
    org_id integer,
    tax_identification character varying(50),
    in_tax boolean DEFAULT false NOT NULL,
    amount double precision DEFAULT 0 NOT NULL,
    additional double precision DEFAULT 0 NOT NULL,
    employer double precision DEFAULT 0 NOT NULL,
    exchange_rate real DEFAULT 1 NOT NULL,
    narrative character varying(240)
);


ALTER TABLE public.employee_tax_types OWNER TO postgres;

--
-- Name: employee_tax_types_employee_tax_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_tax_types_employee_tax_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_tax_types_employee_tax_type_id_seq OWNER TO postgres;

--
-- Name: employee_tax_types_employee_tax_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_tax_types_employee_tax_type_id_seq OWNED BY employee_tax_types.employee_tax_type_id;


--
-- Name: employee_trainings; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employee_trainings (
    employee_training_id integer NOT NULL,
    training_id integer,
    entity_id integer,
    org_id integer,
    narrative character varying(240),
    completed boolean DEFAULT false NOT NULL,
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    details text
);


ALTER TABLE public.employee_trainings OWNER TO postgres;

--
-- Name: employee_trainings_employee_training_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_trainings_employee_training_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_trainings_employee_training_id_seq OWNER TO postgres;

--
-- Name: employee_trainings_employee_training_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_trainings_employee_training_id_seq OWNED BY employee_trainings.employee_training_id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employees (
    entity_id integer NOT NULL,
    department_role_id integer NOT NULL,
    bank_branch_id integer NOT NULL,
    disability_id integer,
    employee_id character varying(12) NOT NULL,
    pay_scale_id integer,
    pay_scale_step_id integer,
    pay_group_id integer,
    location_id integer,
    currency_id integer,
    org_id integer,
    person_title character varying(7),
    surname character varying(50) NOT NULL,
    first_name character varying(50) NOT NULL,
    middle_name character varying(50),
    date_of_birth date,
    gender character varying(1),
    phone character varying(120),
    nationality character(2) NOT NULL,
    nation_of_birth character(2),
    place_of_birth character varying(50),
    marital_status character varying(2),
    appointment_date date,
    current_appointment date,
    exit_date date,
    contract boolean DEFAULT false NOT NULL,
    contract_period integer NOT NULL,
    employment_terms character varying(320),
    identity_card character varying(50),
    basic_salary real NOT NULL,
    bank_account character varying(32),
    picture_file character varying(32),
    active boolean DEFAULT true NOT NULL,
    language character varying(320),
    desg_code character varying(16),
    inc_mth character varying(16),
    previous_sal_point character varying(16),
    current_sal_point character varying(16),
    halt_point character varying(16),
    height real,
    weight real,
    blood_group character varying(3),
    allergies character varying(320),
    field_of_study text,
    interests text,
    objective text,
    details text
);


ALTER TABLE public.employees OWNER TO postgres;

--
-- Name: employment; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE employment (
    employment_id integer NOT NULL,
    entity_id integer,
    org_id integer,
    date_from date NOT NULL,
    date_to date,
    employers_name character varying(240),
    position_held character varying(240),
    details text
);


ALTER TABLE public.employment OWNER TO postgres;

--
-- Name: employment_employment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employment_employment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employment_employment_id_seq OWNER TO postgres;

--
-- Name: employment_employment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employment_employment_id_seq OWNED BY employment.employment_id;


--
-- Name: entity_subscriptions; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE entity_subscriptions (
    entity_subscription_id integer NOT NULL,
    entity_type_id integer NOT NULL,
    entity_id integer NOT NULL,
    subscription_level_id integer NOT NULL,
    org_id integer,
    details text
);


ALTER TABLE public.entity_subscriptions OWNER TO root;

--
-- Name: entity_subscriptions_entity_subscription_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE entity_subscriptions_entity_subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entity_subscriptions_entity_subscription_id_seq OWNER TO root;

--
-- Name: entity_subscriptions_entity_subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE entity_subscriptions_entity_subscription_id_seq OWNED BY entity_subscriptions.entity_subscription_id;


--
-- Name: entity_types; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE entity_types (
    entity_type_id integer NOT NULL,
    org_id integer,
    entity_type_name character varying(50),
    entity_role character varying(240),
    use_key integer DEFAULT 0 NOT NULL,
    start_view character varying(120),
    group_email character varying(120),
    description text,
    details text
);


ALTER TABLE public.entity_types OWNER TO root;

--
-- Name: entity_types_entity_type_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE entity_types_entity_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entity_types_entity_type_id_seq OWNER TO root;

--
-- Name: entity_types_entity_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE entity_types_entity_type_id_seq OWNED BY entity_types.entity_type_id;


--
-- Name: entitys; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE entitys (
    entity_id integer NOT NULL,
    entity_type_id integer NOT NULL,
    org_id integer NOT NULL,
    entity_name character varying(120) NOT NULL,
    user_name character varying(120),
    primary_email character varying(120),
    primary_telephone character varying(50),
    super_user boolean DEFAULT false NOT NULL,
    entity_leader boolean DEFAULT false NOT NULL,
    no_org boolean DEFAULT false NOT NULL,
    function_role character varying(240),
    date_enroled timestamp without time zone DEFAULT now(),
    is_active boolean DEFAULT true,
    entity_password character varying(64) DEFAULT md5('baraza'::text) NOT NULL,
    first_password character varying(64) DEFAULT 'baraza'::character varying NOT NULL,
    new_password character varying(64),
    start_url character varying(64),
    is_picked boolean DEFAULT false NOT NULL,
    details text,
    attention character varying(50),
    account_id integer,
    bio_code character varying(50)
);


ALTER TABLE public.entitys OWNER TO root;

--
-- Name: entitys_entity_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE entitys_entity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entitys_entity_id_seq OWNER TO root;

--
-- Name: entitys_entity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE entitys_entity_id_seq OWNED BY entitys.entity_id;


--
-- Name: entry_forms; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE entry_forms (
    entry_form_id integer NOT NULL,
    org_id integer,
    entity_id integer,
    form_id integer,
    entered_by_id integer,
    application_date timestamp without time zone DEFAULT now() NOT NULL,
    completion_date timestamp without time zone,
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    narrative character varying(240),
    answer text,
    sub_answer text,
    details text
);


ALTER TABLE public.entry_forms OWNER TO root;

--
-- Name: entry_forms_entry_form_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE entry_forms_entry_form_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entry_forms_entry_form_id_seq OWNER TO root;

--
-- Name: entry_forms_entry_form_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE entry_forms_entry_form_id_seq OWNED BY entry_forms.entry_form_id;


--
-- Name: evaluation_points; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE evaluation_points (
    evaluation_point_id integer NOT NULL,
    job_review_id integer,
    review_point_id integer,
    objective_id integer,
    career_development_id integer,
    org_id integer,
    points integer DEFAULT 1 NOT NULL,
    grade character varying(2),
    narrative text,
    reviewer_points integer DEFAULT 1 NOT NULL,
    reviewer_grade character varying(2),
    reviewer_narrative text,
    details text
);


ALTER TABLE public.evaluation_points OWNER TO postgres;

--
-- Name: evaluation_points_evaluation_point_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE evaluation_points_evaluation_point_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.evaluation_points_evaluation_point_id_seq OWNER TO postgres;

--
-- Name: evaluation_points_evaluation_point_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE evaluation_points_evaluation_point_id_seq OWNED BY evaluation_points.evaluation_point_id;


--
-- Name: fields; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE fields (
    field_id integer NOT NULL,
    org_id integer,
    form_id integer,
    field_name character varying(50),
    question text,
    field_lookup text,
    field_type character varying(25) NOT NULL,
    field_class character varying(25),
    field_bold character(1) DEFAULT '0'::bpchar NOT NULL,
    field_italics character(1) DEFAULT '0'::bpchar NOT NULL,
    field_order integer NOT NULL,
    share_line integer,
    field_size integer DEFAULT 25 NOT NULL,
    label_position character(1) DEFAULT 'L'::bpchar,
    field_fnct character varying(120),
    manditory character(1) DEFAULT '0'::bpchar NOT NULL,
    show character(1) DEFAULT '1'::bpchar,
    tab character varying(25),
    details text
);


ALTER TABLE public.fields OWNER TO root;

--
-- Name: fields_field_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE fields_field_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fields_field_id_seq OWNER TO root;

--
-- Name: fields_field_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE fields_field_id_seq OWNED BY fields.field_id;


--
-- Name: fiscal_years; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE fiscal_years (
    fiscal_year_id character varying(9) NOT NULL,
    org_id integer,
    fiscal_year_start date NOT NULL,
    fiscal_year_end date NOT NULL,
    year_opened boolean DEFAULT true NOT NULL,
    year_closed boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.fiscal_years OWNER TO postgres;

--
-- Name: forms; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE forms (
    form_id integer NOT NULL,
    org_id integer,
    form_name character varying(240) NOT NULL,
    form_number character varying(50),
    table_name character varying(50),
    version character varying(25),
    completed character(1) DEFAULT '0'::bpchar NOT NULL,
    is_active character(1) DEFAULT '0'::bpchar NOT NULL,
    use_key integer DEFAULT 0,
    form_header text,
    form_footer text,
    default_values text,
    default_sub_values text,
    details text
);


ALTER TABLE public.forms OWNER TO root;

--
-- Name: forms_form_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE forms_form_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.forms_form_id_seq OWNER TO root;

--
-- Name: forms_form_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE forms_form_id_seq OWNED BY forms.form_id;


--
-- Name: gls; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gls (
    gl_id integer NOT NULL,
    org_id integer,
    journal_id integer NOT NULL,
    account_id integer NOT NULL,
    debit real DEFAULT 0 NOT NULL,
    credit real DEFAULT 0 NOT NULL,
    gl_narrative character varying(240)
);


ALTER TABLE public.gls OWNER TO postgres;

--
-- Name: gls_gl_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE gls_gl_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gls_gl_id_seq OWNER TO postgres;

--
-- Name: gls_gl_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE gls_gl_id_seq OWNED BY gls.gl_id;


--
-- Name: holidays; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE holidays (
    holiday_id integer NOT NULL,
    org_id integer,
    holiday_name character varying(50) NOT NULL,
    holiday_date date,
    details text
);


ALTER TABLE public.holidays OWNER TO postgres;

--
-- Name: holidays_holiday_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE holidays_holiday_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.holidays_holiday_id_seq OWNER TO postgres;

--
-- Name: holidays_holiday_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE holidays_holiday_id_seq OWNED BY holidays.holiday_id;


--
-- Name: identification_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE identification_types (
    identification_type_id integer NOT NULL,
    org_id integer,
    identification_type_name character varying(50),
    details text
);


ALTER TABLE public.identification_types OWNER TO postgres;

--
-- Name: identification_types_identification_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE identification_types_identification_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.identification_types_identification_type_id_seq OWNER TO postgres;

--
-- Name: identification_types_identification_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE identification_types_identification_type_id_seq OWNED BY identification_types.identification_type_id;


--
-- Name: identifications; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE identifications (
    identification_id integer NOT NULL,
    entity_id integer,
    identification_type_id integer,
    nationality character(2) NOT NULL,
    org_id integer,
    identification character varying(64),
    is_active boolean DEFAULT true NOT NULL,
    starting_from date,
    expiring_at date,
    place_of_issue character varying(50),
    details text
);


ALTER TABLE public.identifications OWNER TO postgres;

--
-- Name: identifications_identification_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE identifications_identification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.identifications_identification_id_seq OWNER TO postgres;

--
-- Name: identifications_identification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE identifications_identification_id_seq OWNED BY identifications.identification_id;


--
-- Name: intake; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE intake (
    intake_id integer NOT NULL,
    department_role_id integer,
    pay_scale_id integer,
    pay_group_id integer,
    location_id integer,
    org_id integer,
    opening_date date NOT NULL,
    closing_date date NOT NULL,
    positions integer,
    contract boolean DEFAULT false NOT NULL,
    contract_period integer NOT NULL,
    details text
);


ALTER TABLE public.intake OWNER TO postgres;

--
-- Name: intake_intake_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE intake_intake_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.intake_intake_id_seq OWNER TO postgres;

--
-- Name: intake_intake_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE intake_intake_id_seq OWNED BY intake.intake_id;


--
-- Name: interns; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE interns (
    intern_id integer NOT NULL,
    internship_id integer,
    entity_id integer,
    org_id integer,
    payment_amount real,
    start_date date,
    end_date date,
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    applicant_comments text,
    review text
);


ALTER TABLE public.interns OWNER TO postgres;

--
-- Name: interns_intern_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE interns_intern_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.interns_intern_id_seq OWNER TO postgres;

--
-- Name: interns_intern_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE interns_intern_id_seq OWNED BY interns.intern_id;


--
-- Name: internships; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE internships (
    internship_id integer NOT NULL,
    department_id integer,
    org_id integer,
    opening_date date NOT NULL,
    closing_date date NOT NULL,
    positions integer,
    location character varying(50),
    details text
);


ALTER TABLE public.internships OWNER TO postgres;

--
-- Name: internships_internship_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE internships_internship_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.internships_internship_id_seq OWNER TO postgres;

--
-- Name: internships_internship_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE internships_internship_id_seq OWNED BY internships.internship_id;


--
-- Name: item_category; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE item_category (
    item_category_id integer NOT NULL,
    org_id integer,
    item_category_name character varying(120) NOT NULL,
    details text
);


ALTER TABLE public.item_category OWNER TO postgres;

--
-- Name: item_category_item_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE item_category_item_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.item_category_item_category_id_seq OWNER TO postgres;

--
-- Name: item_category_item_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE item_category_item_category_id_seq OWNED BY item_category.item_category_id;


--
-- Name: item_units; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE item_units (
    item_unit_id integer NOT NULL,
    org_id integer,
    item_unit_name character varying(50) NOT NULL,
    details text
);


ALTER TABLE public.item_units OWNER TO postgres;

--
-- Name: item_units_item_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE item_units_item_unit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.item_units_item_unit_id_seq OWNER TO postgres;

--
-- Name: item_units_item_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE item_units_item_unit_id_seq OWNED BY item_units.item_unit_id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE items (
    item_id integer NOT NULL,
    org_id integer,
    item_category_id integer,
    tax_type_id integer,
    item_unit_id integer,
    sales_account_id integer,
    purchase_account_id integer,
    item_name character varying(120),
    bar_code character varying(32),
    inventory boolean DEFAULT false NOT NULL,
    for_sale boolean DEFAULT true NOT NULL,
    for_purchase boolean DEFAULT true NOT NULL,
    sales_price real,
    purchase_price real,
    reorder_level integer,
    lead_time integer,
    is_active boolean DEFAULT true NOT NULL,
    details text
);


ALTER TABLE public.items OWNER TO postgres;

--
-- Name: items_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE items_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.items_item_id_seq OWNER TO postgres;

--
-- Name: items_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE items_item_id_seq OWNED BY items.item_id;


--
-- Name: job_reviews; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE job_reviews (
    job_review_id integer NOT NULL,
    entity_id integer,
    review_category_id integer,
    org_id integer,
    total_points integer,
    review_date date NOT NULL,
    review_done boolean DEFAULT false NOT NULL,
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    application_date timestamp without time zone DEFAULT now(),
    action_date timestamp without time zone,
    recomendation text,
    staff_comments text,
    reviewer_comments text,
    pl_comments text,
    details text
);


ALTER TABLE public.job_reviews OWNER TO postgres;

--
-- Name: job_reviews_job_review_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE job_reviews_job_review_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.job_reviews_job_review_id_seq OWNER TO postgres;

--
-- Name: job_reviews_job_review_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE job_reviews_job_review_id_seq OWNED BY job_reviews.job_review_id;


--
-- Name: journals; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE journals (
    journal_id integer NOT NULL,
    org_id integer,
    period_id integer NOT NULL,
    currency_id integer,
    department_id integer,
    exchange_rate real DEFAULT 1 NOT NULL,
    journal_date date NOT NULL,
    posted boolean DEFAULT false NOT NULL,
    year_closing boolean DEFAULT false NOT NULL,
    narrative character varying(240),
    details text
);


ALTER TABLE public.journals OWNER TO postgres;

--
-- Name: journals_journal_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE journals_journal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.journals_journal_id_seq OWNER TO postgres;

--
-- Name: journals_journal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE journals_journal_id_seq OWNED BY journals.journal_id;


--
-- Name: kin_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE kin_types (
    kin_type_id integer NOT NULL,
    org_id integer,
    kin_type_name character varying(50),
    details text
);


ALTER TABLE public.kin_types OWNER TO postgres;

--
-- Name: kin_types_kin_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE kin_types_kin_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.kin_types_kin_type_id_seq OWNER TO postgres;

--
-- Name: kin_types_kin_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE kin_types_kin_type_id_seq OWNED BY kin_types.kin_type_id;


--
-- Name: kins; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE kins (
    kin_id integer NOT NULL,
    entity_id integer,
    kin_type_id integer,
    org_id integer,
    full_names character varying(120),
    date_of_birth date,
    identification character varying(50),
    relation character varying(50),
    emergency_contact boolean DEFAULT false NOT NULL,
    beneficiary boolean DEFAULT false NOT NULL,
    beneficiary_ps real,
    details text
);


ALTER TABLE public.kins OWNER TO postgres;

--
-- Name: kins_kin_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE kins_kin_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.kins_kin_id_seq OWNER TO postgres;

--
-- Name: kins_kin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE kins_kin_id_seq OWNED BY kins.kin_id;


--
-- Name: lead_items; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE lead_items (
    lead_item integer NOT NULL,
    entity_id integer,
    item_id integer,
    org_id integer,
    pitch_date date,
    units integer,
    price real,
    narrative character varying(320),
    details text
);


ALTER TABLE public.lead_items OWNER TO postgres;

--
-- Name: lead_items_lead_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE lead_items_lead_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_items_lead_item_seq OWNER TO postgres;

--
-- Name: lead_items_lead_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE lead_items_lead_item_seq OWNED BY lead_items.lead_item;


--
-- Name: leads; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE leads (
    lead_id integer NOT NULL,
    entity_id integer,
    sale_person_id integer,
    org_id integer,
    contact_date date,
    details text
);


ALTER TABLE public.leads OWNER TO postgres;

--
-- Name: leads_lead_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE leads_lead_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.leads_lead_id_seq OWNER TO postgres;

--
-- Name: leads_lead_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE leads_lead_id_seq OWNED BY leads.lead_id;


--
-- Name: leave_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE leave_types (
    leave_type_id integer NOT NULL,
    org_id integer,
    leave_type_name character varying(50) NOT NULL,
    allowed_leave_days integer DEFAULT 1 NOT NULL,
    leave_days_span integer DEFAULT 1 NOT NULL,
    use_type integer DEFAULT 0 NOT NULL,
    month_quota real DEFAULT 0 NOT NULL,
    initial_days real DEFAULT 0 NOT NULL,
    maximum_carry real DEFAULT 0 NOT NULL,
    include_holiday boolean DEFAULT false NOT NULL,
    include_mon boolean DEFAULT true NOT NULL,
    include_tue boolean DEFAULT true NOT NULL,
    include_wed boolean DEFAULT true NOT NULL,
    include_thu boolean DEFAULT true NOT NULL,
    include_fri boolean DEFAULT true NOT NULL,
    include_sat boolean DEFAULT false NOT NULL,
    include_sun boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.leave_types OWNER TO postgres;

--
-- Name: leave_types_leave_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE leave_types_leave_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.leave_types_leave_type_id_seq OWNER TO postgres;

--
-- Name: leave_types_leave_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE leave_types_leave_type_id_seq OWNED BY leave_types.leave_type_id;


--
-- Name: leave_work_days; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE leave_work_days (
    leave_work_day_id integer NOT NULL,
    employee_leave_id integer,
    entity_id integer,
    org_id integer,
    work_date date NOT NULL,
    half_day boolean DEFAULT false NOT NULL,
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    application_date timestamp without time zone DEFAULT now(),
    action_date timestamp without time zone,
    details text
);


ALTER TABLE public.leave_work_days OWNER TO postgres;

--
-- Name: leave_work_days_leave_work_day_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE leave_work_days_leave_work_day_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.leave_work_days_leave_work_day_id_seq OWNER TO postgres;

--
-- Name: leave_work_days_leave_work_day_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE leave_work_days_leave_work_day_id_seq OWNED BY leave_work_days.leave_work_day_id;


--
-- Name: loan_monthly; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE loan_monthly (
    loan_month_id integer NOT NULL,
    loan_id integer,
    period_id integer,
    employee_adjustment_id integer,
    org_id integer,
    interest_amount real DEFAULT 0 NOT NULL,
    repayment real DEFAULT 0 NOT NULL,
    interest_paid real DEFAULT 0 NOT NULL,
    penalty real DEFAULT 0 NOT NULL,
    penalty_paid real DEFAULT 0 NOT NULL,
    details text
);


ALTER TABLE public.loan_monthly OWNER TO postgres;

--
-- Name: loan_monthly_loan_month_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE loan_monthly_loan_month_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.loan_monthly_loan_month_id_seq OWNER TO postgres;

--
-- Name: loan_monthly_loan_month_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE loan_monthly_loan_month_id_seq OWNED BY loan_monthly.loan_month_id;


--
-- Name: loan_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE loan_types (
    loan_type_id integer NOT NULL,
    adjustment_id integer,
    org_id integer,
    loan_type_name character varying(50) NOT NULL,
    default_interest real,
    reducing_balance boolean DEFAULT true NOT NULL,
    details text
);


ALTER TABLE public.loan_types OWNER TO postgres;

--
-- Name: loan_types_loan_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE loan_types_loan_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.loan_types_loan_type_id_seq OWNER TO postgres;

--
-- Name: loan_types_loan_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE loan_types_loan_type_id_seq OWNED BY loan_types.loan_type_id;


--
-- Name: loans; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE loans (
    loan_id integer NOT NULL,
    loan_type_id integer NOT NULL,
    entity_id integer NOT NULL,
    org_id integer,
    principle real NOT NULL,
    interest real NOT NULL,
    monthly_repayment real NOT NULL,
    loan_date date,
    initial_payment real DEFAULT 0 NOT NULL,
    reducing_balance boolean DEFAULT true NOT NULL,
    repayment_period integer NOT NULL,
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    details text,
    CONSTRAINT loans_repayment_period_check CHECK ((repayment_period > 0))
);


ALTER TABLE public.loans OWNER TO postgres;

--
-- Name: loans_loan_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE loans_loan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.loans_loan_id_seq OWNER TO postgres;

--
-- Name: loans_loan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE loans_loan_id_seq OWNED BY loans.loan_id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE locations (
    location_id integer NOT NULL,
    org_id integer,
    location_name character varying(50),
    details text
);


ALTER TABLE public.locations OWNER TO postgres;

--
-- Name: locations_location_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE locations_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.locations_location_id_seq OWNER TO postgres;

--
-- Name: locations_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE locations_location_id_seq OWNED BY locations.location_id;


--
-- Name: objective_details; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE objective_details (
    objective_detail_id integer NOT NULL,
    objective_id integer,
    ln_objective_detail_id integer,
    org_id integer,
    objective_detail_name character varying(320) NOT NULL,
    success_indicator text NOT NULL,
    achievements text,
    resources_required text,
    ods_ps real,
    ods_points integer DEFAULT 1 NOT NULL,
    ods_reviewer_points integer DEFAULT 1 NOT NULL,
    target_date date,
    completed boolean DEFAULT false NOT NULL,
    completion_date date,
    target_changes text,
    supervisor_comments text,
    details text
);


ALTER TABLE public.objective_details OWNER TO postgres;

--
-- Name: objective_details_objective_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE objective_details_objective_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.objective_details_objective_detail_id_seq OWNER TO postgres;

--
-- Name: objective_details_objective_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE objective_details_objective_detail_id_seq OWNED BY objective_details.objective_detail_id;


--
-- Name: objective_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE objective_types (
    objective_type_id integer NOT NULL,
    org_id integer,
    objective_type_name character varying(320) NOT NULL,
    details text
);


ALTER TABLE public.objective_types OWNER TO postgres;

--
-- Name: objective_types_objective_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE objective_types_objective_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.objective_types_objective_type_id_seq OWNER TO postgres;

--
-- Name: objective_types_objective_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE objective_types_objective_type_id_seq OWNED BY objective_types.objective_type_id;


--
-- Name: objectives; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE objectives (
    objective_id integer NOT NULL,
    employee_objective_id integer,
    objective_type_id integer,
    org_id integer,
    date_set date NOT NULL,
    objective_ps real,
    objective_name character varying(320) NOT NULL,
    objective_completed boolean DEFAULT false NOT NULL,
    supervisor_comments text,
    details text
);


ALTER TABLE public.objectives OWNER TO postgres;

--
-- Name: objectives_objective_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE objectives_objective_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.objectives_objective_id_seq OWNER TO postgres;

--
-- Name: objectives_objective_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE objectives_objective_id_seq OWNED BY objectives.objective_id;


--
-- Name: orgs; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE orgs (
    org_id integer NOT NULL,
    currency_id integer,
    parent_org_id integer,
    org_name character varying(50) NOT NULL,
    org_sufix character varying(4) NOT NULL,
    is_default boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    logo character varying(50),
    pin character varying(50),
    details text,
    cert_number character varying(50),
    vat_number character varying(50),
    fixed_budget boolean DEFAULT true,
    invoice_footer text,
    bank_header text,
    bank_address text
);


ALTER TABLE public.orgs OWNER TO root;

--
-- Name: orgs_org_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE orgs_org_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orgs_org_id_seq OWNER TO root;

--
-- Name: orgs_org_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE orgs_org_id_seq OWNED BY orgs.org_id;


--
-- Name: pay_groups; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE pay_groups (
    pay_group_id integer NOT NULL,
    org_id integer,
    pay_group_name character varying(50),
    details text
);


ALTER TABLE public.pay_groups OWNER TO postgres;

--
-- Name: pay_groups_pay_group_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pay_groups_pay_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pay_groups_pay_group_id_seq OWNER TO postgres;

--
-- Name: pay_groups_pay_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pay_groups_pay_group_id_seq OWNED BY pay_groups.pay_group_id;


--
-- Name: pay_scale_steps; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE pay_scale_steps (
    pay_scale_step_id integer NOT NULL,
    pay_scale_id integer,
    org_id integer,
    pay_step integer NOT NULL,
    pay_amount real NOT NULL
);


ALTER TABLE public.pay_scale_steps OWNER TO postgres;

--
-- Name: pay_scale_steps_pay_scale_step_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pay_scale_steps_pay_scale_step_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pay_scale_steps_pay_scale_step_id_seq OWNER TO postgres;

--
-- Name: pay_scale_steps_pay_scale_step_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pay_scale_steps_pay_scale_step_id_seq OWNED BY pay_scale_steps.pay_scale_step_id;


--
-- Name: pay_scale_years; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE pay_scale_years (
    pay_scale_year_id integer NOT NULL,
    pay_scale_id integer,
    org_id integer,
    pay_year integer NOT NULL,
    pay_amount real NOT NULL
);


ALTER TABLE public.pay_scale_years OWNER TO postgres;

--
-- Name: pay_scale_years_pay_scale_year_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pay_scale_years_pay_scale_year_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pay_scale_years_pay_scale_year_id_seq OWNER TO postgres;

--
-- Name: pay_scale_years_pay_scale_year_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pay_scale_years_pay_scale_year_id_seq OWNED BY pay_scale_years.pay_scale_year_id;


--
-- Name: pay_scales; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE pay_scales (
    pay_scale_id integer NOT NULL,
    currency_id integer,
    org_id integer,
    pay_scale_name character varying(32) NOT NULL,
    min_pay real,
    max_pay real,
    details text
);


ALTER TABLE public.pay_scales OWNER TO postgres;

--
-- Name: pay_scales_pay_scale_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pay_scales_pay_scale_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pay_scales_pay_scale_id_seq OWNER TO postgres;

--
-- Name: pay_scales_pay_scale_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pay_scales_pay_scale_id_seq OWNED BY pay_scales.pay_scale_id;


--
-- Name: payroll_ledger; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE payroll_ledger (
    payroll_ledger_id integer NOT NULL,
    currency_id integer,
    org_id integer,
    period_id integer,
    posting_date date,
    description character varying(240),
    payroll_account character varying(16),
    dr_amt numeric(12,2),
    cr_amt numeric(12,2),
    exchange_rate real DEFAULT 1 NOT NULL,
    posted boolean DEFAULT false
);


ALTER TABLE public.payroll_ledger OWNER TO postgres;

--
-- Name: payroll_ledger_payroll_ledger_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE payroll_ledger_payroll_ledger_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payroll_ledger_payroll_ledger_id_seq OWNER TO postgres;

--
-- Name: payroll_ledger_payroll_ledger_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE payroll_ledger_payroll_ledger_id_seq OWNED BY payroll_ledger.payroll_ledger_id;


--
-- Name: pc_allocations; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE pc_allocations (
    pc_allocation_id integer NOT NULL,
    period_id integer,
    department_id integer,
    org_id integer,
    narrative character varying(320),
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    details text
);


ALTER TABLE public.pc_allocations OWNER TO postgres;

--
-- Name: pc_allocations_pc_allocation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pc_allocations_pc_allocation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pc_allocations_pc_allocation_id_seq OWNER TO postgres;

--
-- Name: pc_allocations_pc_allocation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pc_allocations_pc_allocation_id_seq OWNED BY pc_allocations.pc_allocation_id;


--
-- Name: pc_banking; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE pc_banking (
    pc_banking_id integer NOT NULL,
    pc_allocation_id integer,
    org_id integer,
    banking_date date NOT NULL,
    amount double precision NOT NULL,
    narrative character varying(320) NOT NULL,
    details text
);


ALTER TABLE public.pc_banking OWNER TO postgres;

--
-- Name: pc_banking_pc_banking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pc_banking_pc_banking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pc_banking_pc_banking_id_seq OWNER TO postgres;

--
-- Name: pc_banking_pc_banking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pc_banking_pc_banking_id_seq OWNED BY pc_banking.pc_banking_id;


--
-- Name: pc_budget; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE pc_budget (
    pc_budget_id integer NOT NULL,
    pc_allocation_id integer,
    pc_item_id integer,
    org_id integer,
    budget_units integer NOT NULL,
    budget_price double precision NOT NULL,
    details text
);


ALTER TABLE public.pc_budget OWNER TO postgres;

--
-- Name: pc_budget_pc_budget_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pc_budget_pc_budget_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pc_budget_pc_budget_id_seq OWNER TO postgres;

--
-- Name: pc_budget_pc_budget_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pc_budget_pc_budget_id_seq OWNED BY pc_budget.pc_budget_id;


--
-- Name: pc_category; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE pc_category (
    pc_category_id integer NOT NULL,
    org_id integer,
    pc_category_name character varying(50) NOT NULL,
    details text
);


ALTER TABLE public.pc_category OWNER TO postgres;

--
-- Name: pc_category_pc_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pc_category_pc_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pc_category_pc_category_id_seq OWNER TO postgres;

--
-- Name: pc_category_pc_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pc_category_pc_category_id_seq OWNED BY pc_category.pc_category_id;


--
-- Name: pc_expenditure; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE pc_expenditure (
    pc_expenditure_id integer NOT NULL,
    pc_allocation_id integer,
    pc_item_id integer,
    pc_type_id integer,
    entity_id integer,
    org_id integer,
    is_request boolean DEFAULT true NOT NULL,
    request_date timestamp without time zone DEFAULT now(),
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    units integer NOT NULL,
    unit_price double precision NOT NULL,
    receipt_number character varying(50),
    exp_date date,
    details text
);


ALTER TABLE public.pc_expenditure OWNER TO postgres;

--
-- Name: pc_expenditure_pc_expenditure_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pc_expenditure_pc_expenditure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pc_expenditure_pc_expenditure_id_seq OWNER TO postgres;

--
-- Name: pc_expenditure_pc_expenditure_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pc_expenditure_pc_expenditure_id_seq OWNED BY pc_expenditure.pc_expenditure_id;


--
-- Name: pc_items; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE pc_items (
    pc_item_id integer NOT NULL,
    pc_category_id integer,
    org_id integer,
    pc_item_name character varying(50) NOT NULL,
    default_price double precision NOT NULL,
    default_units integer NOT NULL,
    details text
);


ALTER TABLE public.pc_items OWNER TO postgres;

--
-- Name: pc_items_pc_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pc_items_pc_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pc_items_pc_item_id_seq OWNER TO postgres;

--
-- Name: pc_items_pc_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pc_items_pc_item_id_seq OWNED BY pc_items.pc_item_id;


--
-- Name: pc_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE pc_types (
    pc_type_id integer NOT NULL,
    org_id integer,
    pc_type_name character varying(50) NOT NULL,
    details text
);


ALTER TABLE public.pc_types OWNER TO postgres;

--
-- Name: pc_types_pc_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE pc_types_pc_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pc_types_pc_type_id_seq OWNER TO postgres;

--
-- Name: pc_types_pc_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE pc_types_pc_type_id_seq OWNED BY pc_types.pc_type_id;


--
-- Name: period_tax_rates; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE period_tax_rates (
    period_tax_rate_id integer NOT NULL,
    period_tax_type_id integer,
    tax_rate_id integer,
    org_id integer,
    tax_range double precision NOT NULL,
    tax_rate double precision NOT NULL,
    narrative character varying(240)
);


ALTER TABLE public.period_tax_rates OWNER TO postgres;

--
-- Name: period_tax_rates_period_tax_rate_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE period_tax_rates_period_tax_rate_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.period_tax_rates_period_tax_rate_id_seq OWNER TO postgres;

--
-- Name: period_tax_rates_period_tax_rate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE period_tax_rates_period_tax_rate_id_seq OWNED BY period_tax_rates.period_tax_rate_id;


--
-- Name: period_tax_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE period_tax_types (
    period_tax_type_id integer NOT NULL,
    period_id integer,
    tax_type_id integer,
    account_id integer,
    org_id integer,
    period_tax_type_name character varying(50) NOT NULL,
    pay_date date DEFAULT ('now'::text)::date NOT NULL,
    formural character varying(320),
    tax_relief real DEFAULT 0 NOT NULL,
    percentage boolean DEFAULT true NOT NULL,
    linear boolean DEFAULT true NOT NULL,
    tax_type_order integer DEFAULT 0 NOT NULL,
    in_tax boolean DEFAULT false NOT NULL,
    employer double precision NOT NULL,
    employer_ps double precision NOT NULL,
    account_number character varying(32),
    details text
);


ALTER TABLE public.period_tax_types OWNER TO postgres;

--
-- Name: period_tax_types_period_tax_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE period_tax_types_period_tax_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.period_tax_types_period_tax_type_id_seq OWNER TO postgres;

--
-- Name: period_tax_types_period_tax_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE period_tax_types_period_tax_type_id_seq OWNED BY period_tax_types.period_tax_type_id;


--
-- Name: periods; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE periods (
    period_id integer NOT NULL,
    fiscal_year_id character varying(9),
    org_id integer,
    start_date date NOT NULL,
    end_date date NOT NULL,
    opened boolean DEFAULT false NOT NULL,
    activated boolean DEFAULT false NOT NULL,
    closed boolean DEFAULT false NOT NULL,
    overtime_rate double precision DEFAULT 1 NOT NULL,
    per_diem_tax_limit double precision DEFAULT 2000 NOT NULL,
    is_posted boolean DEFAULT false NOT NULL,
    loan_approval boolean DEFAULT false NOT NULL,
    gl_payroll_account character varying(32),
    gl_bank_account character varying(32),
    bank_header text,
    bank_address text,
    entity_id integer,
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    details text
);


ALTER TABLE public.periods OWNER TO postgres;

--
-- Name: periods_period_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE periods_period_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.periods_period_id_seq OWNER TO postgres;

--
-- Name: periods_period_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE periods_period_id_seq OWNED BY periods.period_id;


--
-- Name: phases; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE phases (
    phase_id integer NOT NULL,
    project_id integer,
    org_id integer,
    phase_name character varying(240),
    start_date date NOT NULL,
    end_date date,
    completed boolean DEFAULT false NOT NULL,
    phase_cost real DEFAULT 0 NOT NULL,
    details text
);


ALTER TABLE public.phases OWNER TO postgres;

--
-- Name: phases_phase_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE phases_phase_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.phases_phase_id_seq OWNER TO postgres;

--
-- Name: phases_phase_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE phases_phase_id_seq OWNED BY phases.phase_id;


--
-- Name: picture_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE picture_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.picture_id_seq OWNER TO root;

--
-- Name: project_cost; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE project_cost (
    project_cost_id integer NOT NULL,
    phase_id integer,
    org_id integer,
    project_cost_name character varying(240),
    amount real DEFAULT 0 NOT NULL,
    cost_date date NOT NULL,
    cost_approved boolean DEFAULT false,
    details text
);


ALTER TABLE public.project_cost OWNER TO postgres;

--
-- Name: project_cost_project_cost_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE project_cost_project_cost_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_cost_project_cost_id_seq OWNER TO postgres;

--
-- Name: project_cost_project_cost_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE project_cost_project_cost_id_seq OWNED BY project_cost.project_cost_id;


--
-- Name: project_locations; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE project_locations (
    job_location_id integer NOT NULL,
    project_id integer,
    org_id integer,
    job_location_name character varying(50),
    details text
);


ALTER TABLE public.project_locations OWNER TO postgres;

--
-- Name: project_locations_job_location_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE project_locations_job_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_locations_job_location_id_seq OWNER TO postgres;

--
-- Name: project_locations_job_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE project_locations_job_location_id_seq OWNED BY project_locations.job_location_id;


--
-- Name: project_staff; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE project_staff (
    project_staff_id integer NOT NULL,
    project_id integer,
    entity_id integer,
    org_id integer,
    project_role character varying(240),
    monthly_cost boolean DEFAULT true NOT NULL,
    staff_cost real DEFAULT 0 NOT NULL,
    tax_cost real DEFAULT 0 NOT NULL,
    details text
);


ALTER TABLE public.project_staff OWNER TO postgres;

--
-- Name: project_staff_costs; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE project_staff_costs (
    project_staff_cost_id integer NOT NULL,
    project_id integer NOT NULL,
    entity_id integer NOT NULL,
    period_id integer NOT NULL,
    bank_branch_id integer NOT NULL,
    pay_group_id integer NOT NULL,
    org_id integer,
    bank_account character varying(32),
    staff_cost real DEFAULT 0 NOT NULL,
    tax_cost real DEFAULT 0 NOT NULL,
    details text
);


ALTER TABLE public.project_staff_costs OWNER TO postgres;

--
-- Name: project_staff_costs_project_staff_cost_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE project_staff_costs_project_staff_cost_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_staff_costs_project_staff_cost_id_seq OWNER TO postgres;

--
-- Name: project_staff_costs_project_staff_cost_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE project_staff_costs_project_staff_cost_id_seq OWNED BY project_staff_costs.project_staff_cost_id;


--
-- Name: project_staff_project_staff_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE project_staff_project_staff_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_staff_project_staff_id_seq OWNER TO postgres;

--
-- Name: project_staff_project_staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE project_staff_project_staff_id_seq OWNED BY project_staff.project_staff_id;


--
-- Name: project_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE project_types (
    project_type_id integer NOT NULL,
    org_id integer,
    project_type_name character varying(50) NOT NULL,
    details text
);


ALTER TABLE public.project_types OWNER TO postgres;

--
-- Name: project_types_project_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE project_types_project_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_types_project_type_id_seq OWNER TO postgres;

--
-- Name: project_types_project_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE project_types_project_type_id_seq OWNED BY project_types.project_type_id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE projects (
    project_id integer NOT NULL,
    project_type_id integer,
    entity_id integer,
    org_id integer,
    project_name character varying(240) NOT NULL,
    signed boolean DEFAULT false NOT NULL,
    contract_ref character varying(120),
    monthly_amount real,
    full_amount real,
    project_cost real,
    narrative character varying(120),
    project_account character varying(32),
    start_date date NOT NULL,
    ending_date date,
    details text
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: projects_project_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE projects_project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_project_id_seq OWNER TO postgres;

--
-- Name: projects_project_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE projects_project_id_seq OWNED BY projects.project_id;


--
-- Name: quotations; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE quotations (
    quotation_id integer NOT NULL,
    org_id integer,
    item_id integer,
    entity_id integer,
    active boolean DEFAULT false NOT NULL,
    amount real,
    valid_from date,
    valid_to date,
    lead_time integer,
    details text
);


ALTER TABLE public.quotations OWNER TO postgres;

--
-- Name: quotations_quotation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE quotations_quotation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.quotations_quotation_id_seq OWNER TO postgres;

--
-- Name: quotations_quotation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE quotations_quotation_id_seq OWNED BY quotations.quotation_id;


--
-- Name: reporting; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE reporting (
    reporting_id integer NOT NULL,
    entity_id integer,
    report_to_id integer,
    org_id integer,
    date_from date,
    date_to date,
    reporting_level integer DEFAULT 1 NOT NULL,
    primary_report boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    ps_reporting real,
    details text
);


ALTER TABLE public.reporting OWNER TO root;

--
-- Name: reporting_reporting_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE reporting_reporting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reporting_reporting_id_seq OWNER TO root;

--
-- Name: reporting_reporting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE reporting_reporting_id_seq OWNED BY reporting.reporting_id;


--
-- Name: review_category; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE review_category (
    review_category_id integer NOT NULL,
    org_id integer,
    review_category_name character varying(320),
    details text
);


ALTER TABLE public.review_category OWNER TO postgres;

--
-- Name: review_category_review_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE review_category_review_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.review_category_review_category_id_seq OWNER TO postgres;

--
-- Name: review_category_review_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE review_category_review_category_id_seq OWNED BY review_category.review_category_id;


--
-- Name: review_points; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE review_points (
    review_point_id integer NOT NULL,
    review_category_id integer,
    org_id integer,
    review_point_name character varying(50),
    review_points integer DEFAULT 1 NOT NULL,
    details text
);


ALTER TABLE public.review_points OWNER TO postgres;

--
-- Name: review_points_review_point_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE review_points_review_point_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.review_points_review_point_id_seq OWNER TO postgres;

--
-- Name: review_points_review_point_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE review_points_review_point_id_seq OWNED BY review_points.review_point_id;


--
-- Name: shift_schedule; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE shift_schedule (
    shift_schedule_id integer NOT NULL,
    shift_id integer,
    entity_id integer,
    org_id integer,
    day_of_week integer,
    time_in time without time zone,
    time_out time without time zone,
    details text
);


ALTER TABLE public.shift_schedule OWNER TO postgres;

--
-- Name: shift_schedule_shift_schedule_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE shift_schedule_shift_schedule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shift_schedule_shift_schedule_id_seq OWNER TO postgres;

--
-- Name: shift_schedule_shift_schedule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE shift_schedule_shift_schedule_id_seq OWNED BY shift_schedule.shift_schedule_id;


--
-- Name: shifts; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE shifts (
    shift_id integer NOT NULL,
    org_id integer,
    shift_name character varying(50),
    shift_hours integer DEFAULT 8 NOT NULL,
    details text
);


ALTER TABLE public.shifts OWNER TO postgres;

--
-- Name: shifts_shift_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE shifts_shift_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.shifts_shift_id_seq OWNER TO postgres;

--
-- Name: shifts_shift_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE shifts_shift_id_seq OWNED BY shifts.shift_id;


--
-- Name: skill_category; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE skill_category (
    skill_category_id integer NOT NULL,
    org_id integer,
    skill_category_name character varying(50) NOT NULL,
    details text
);


ALTER TABLE public.skill_category OWNER TO postgres;

--
-- Name: skill_category_skill_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE skill_category_skill_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.skill_category_skill_category_id_seq OWNER TO postgres;

--
-- Name: skill_category_skill_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE skill_category_skill_category_id_seq OWNED BY skill_category.skill_category_id;


--
-- Name: skill_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE skill_types (
    skill_type_id integer NOT NULL,
    skill_category_id integer,
    org_id integer,
    skill_type_name character varying(50) NOT NULL,
    basic character varying(50),
    intermediate character varying(50),
    advanced character varying(50),
    details text
);


ALTER TABLE public.skill_types OWNER TO postgres;

--
-- Name: skill_types_skill_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE skill_types_skill_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.skill_types_skill_type_id_seq OWNER TO postgres;

--
-- Name: skill_types_skill_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE skill_types_skill_type_id_seq OWNED BY skill_types.skill_type_id;


--
-- Name: skills; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE skills (
    skill_id integer NOT NULL,
    entity_id integer,
    skill_type_id integer,
    org_id integer,
    skill_level integer DEFAULT 1 NOT NULL,
    aquired boolean DEFAULT false NOT NULL,
    training_date date,
    trained boolean DEFAULT false NOT NULL,
    training_institution character varying(240),
    training_cost real,
    details text
);


ALTER TABLE public.skills OWNER TO postgres;

--
-- Name: skills_skill_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE skills_skill_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.skills_skill_id_seq OWNER TO postgres;

--
-- Name: skills_skill_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE skills_skill_id_seq OWNED BY skills.skill_id;


--
-- Name: stock_lines; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE stock_lines (
    stock_line_id integer NOT NULL,
    org_id integer,
    stock_id integer,
    item_id integer,
    quantity integer,
    narrative character varying(240)
);


ALTER TABLE public.stock_lines OWNER TO postgres;

--
-- Name: stock_lines_stock_line_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE stock_lines_stock_line_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.stock_lines_stock_line_id_seq OWNER TO postgres;

--
-- Name: stock_lines_stock_line_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE stock_lines_stock_line_id_seq OWNED BY stock_lines.stock_line_id;


--
-- Name: stocks; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE stocks (
    stock_id integer NOT NULL,
    org_id integer,
    store_id integer,
    stock_name character varying(50),
    stock_take_date date,
    details text
);


ALTER TABLE public.stocks OWNER TO postgres;

--
-- Name: stocks_stock_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE stocks_stock_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.stocks_stock_id_seq OWNER TO postgres;

--
-- Name: stocks_stock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE stocks_stock_id_seq OWNED BY stocks.stock_id;


--
-- Name: stores; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE stores (
    store_id integer NOT NULL,
    org_id integer,
    store_name character varying(120),
    details text
);


ALTER TABLE public.stores OWNER TO postgres;

--
-- Name: stores_store_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE stores_store_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.stores_store_id_seq OWNER TO postgres;

--
-- Name: stores_store_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE stores_store_id_seq OWNED BY stores.store_id;


--
-- Name: sub_fields; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sub_fields (
    sub_field_id integer NOT NULL,
    org_id integer,
    field_id integer,
    sub_field_order integer NOT NULL,
    sub_title_share character varying(120),
    sub_field_type character varying(25),
    sub_field_lookup text,
    sub_field_size integer NOT NULL,
    sub_col_spans integer DEFAULT 1 NOT NULL,
    manditory character(1) DEFAULT '0'::bpchar NOT NULL,
    show character(1) DEFAULT '1'::bpchar,
    question text
);


ALTER TABLE public.sub_fields OWNER TO root;

--
-- Name: sub_fields_sub_field_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sub_fields_sub_field_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sub_fields_sub_field_id_seq OWNER TO root;

--
-- Name: sub_fields_sub_field_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sub_fields_sub_field_id_seq OWNED BY sub_fields.sub_field_id;


--
-- Name: subscription_levels; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE subscription_levels (
    subscription_level_id integer NOT NULL,
    org_id integer,
    subscription_level_name character varying(50),
    details text
);


ALTER TABLE public.subscription_levels OWNER TO root;

--
-- Name: subscription_levels_subscription_level_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE subscription_levels_subscription_level_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.subscription_levels_subscription_level_id_seq OWNER TO root;

--
-- Name: subscription_levels_subscription_level_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE subscription_levels_subscription_level_id_seq OWNED BY subscription_levels.subscription_level_id;


--
-- Name: sys_audit_details; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_audit_details (
    sys_audit_detail_id integer NOT NULL,
    sys_audit_trail_id integer,
    new_value text
);


ALTER TABLE public.sys_audit_details OWNER TO root;

--
-- Name: sys_audit_details_sys_audit_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_audit_details_sys_audit_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_audit_details_sys_audit_detail_id_seq OWNER TO root;

--
-- Name: sys_audit_details_sys_audit_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_audit_details_sys_audit_detail_id_seq OWNED BY sys_audit_details.sys_audit_detail_id;


--
-- Name: sys_audit_trail; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_audit_trail (
    sys_audit_trail_id integer NOT NULL,
    user_id character varying(50) NOT NULL,
    user_ip character varying(50),
    change_date timestamp without time zone DEFAULT now() NOT NULL,
    table_name character varying(50) NOT NULL,
    record_id character varying(50) NOT NULL,
    change_type character varying(50) NOT NULL,
    narrative character varying(240)
);


ALTER TABLE public.sys_audit_trail OWNER TO root;

--
-- Name: sys_audit_trail_sys_audit_trail_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_audit_trail_sys_audit_trail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_audit_trail_sys_audit_trail_id_seq OWNER TO root;

--
-- Name: sys_audit_trail_sys_audit_trail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_audit_trail_sys_audit_trail_id_seq OWNED BY sys_audit_trail.sys_audit_trail_id;


--
-- Name: sys_continents; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_continents (
    sys_continent_id character(2) NOT NULL,
    sys_continent_name character varying(120)
);


ALTER TABLE public.sys_continents OWNER TO root;

--
-- Name: sys_countrys; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_countrys (
    sys_country_id character(2) NOT NULL,
    sys_continent_id character(2),
    sys_country_code character varying(3),
    sys_country_number character varying(3),
    sys_phone_code character varying(3),
    sys_country_name character varying(120),
    sys_currency_name character varying(50),
    sys_currency_cents character varying(50),
    sys_currency_code character varying(3),
    sys_currency_exchange real
);


ALTER TABLE public.sys_countrys OWNER TO root;

--
-- Name: sys_dashboard; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_dashboard (
    sys_dashboard_id integer NOT NULL,
    entity_id integer,
    org_id integer,
    narrative character varying(240),
    details text
);


ALTER TABLE public.sys_dashboard OWNER TO root;

--
-- Name: sys_dashboard_sys_dashboard_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_dashboard_sys_dashboard_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_dashboard_sys_dashboard_id_seq OWNER TO root;

--
-- Name: sys_dashboard_sys_dashboard_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_dashboard_sys_dashboard_id_seq OWNED BY sys_dashboard.sys_dashboard_id;


--
-- Name: sys_emailed; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_emailed (
    sys_emailed_id integer NOT NULL,
    sys_email_id integer,
    org_id integer,
    table_id integer,
    table_name character varying(50),
    email_type integer DEFAULT 1 NOT NULL,
    emailed boolean DEFAULT false NOT NULL,
    narrative character varying(240)
);


ALTER TABLE public.sys_emailed OWNER TO root;

--
-- Name: sys_emailed_sys_emailed_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_emailed_sys_emailed_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_emailed_sys_emailed_id_seq OWNER TO root;

--
-- Name: sys_emailed_sys_emailed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_emailed_sys_emailed_id_seq OWNED BY sys_emailed.sys_emailed_id;


--
-- Name: sys_emails; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_emails (
    sys_email_id integer NOT NULL,
    org_id integer,
    sys_email_name character varying(50),
    default_email character varying(120),
    title character varying(240) NOT NULL,
    details text
);


ALTER TABLE public.sys_emails OWNER TO root;

--
-- Name: sys_emails_sys_email_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_emails_sys_email_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_emails_sys_email_id_seq OWNER TO root;

--
-- Name: sys_emails_sys_email_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_emails_sys_email_id_seq OWNED BY sys_emails.sys_email_id;


--
-- Name: sys_errors; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_errors (
    sys_error_id integer NOT NULL,
    sys_error character varying(240) NOT NULL,
    error_message text NOT NULL
);


ALTER TABLE public.sys_errors OWNER TO root;

--
-- Name: sys_errors_sys_error_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_errors_sys_error_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_errors_sys_error_id_seq OWNER TO root;

--
-- Name: sys_errors_sys_error_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_errors_sys_error_id_seq OWNED BY sys_errors.sys_error_id;


--
-- Name: sys_files; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_files (
    sys_file_id integer NOT NULL,
    org_id integer,
    table_id integer,
    table_name character varying(50),
    file_name character varying(320),
    file_type character varying(320),
    file_size integer,
    narrative character varying(320),
    details text
);


ALTER TABLE public.sys_files OWNER TO root;

--
-- Name: sys_files_sys_file_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_files_sys_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_files_sys_file_id_seq OWNER TO root;

--
-- Name: sys_files_sys_file_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_files_sys_file_id_seq OWNED BY sys_files.sys_file_id;


--
-- Name: sys_logins; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_logins (
    sys_login_id integer NOT NULL,
    entity_id integer,
    login_time timestamp without time zone DEFAULT now(),
    login_ip character varying(64),
    narrative character varying(240)
);


ALTER TABLE public.sys_logins OWNER TO root;

--
-- Name: sys_logins_sys_login_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_logins_sys_login_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_logins_sys_login_id_seq OWNER TO root;

--
-- Name: sys_logins_sys_login_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_logins_sys_login_id_seq OWNED BY sys_logins.sys_login_id;


--
-- Name: sys_menu_msg; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_menu_msg (
    sys_menu_msg_id integer NOT NULL,
    menu_id integer NOT NULL,
    menu_name character varying(50) NOT NULL,
    msg text
);


ALTER TABLE public.sys_menu_msg OWNER TO root;

--
-- Name: sys_menu_msg_sys_menu_msg_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_menu_msg_sys_menu_msg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_menu_msg_sys_menu_msg_id_seq OWNER TO root;

--
-- Name: sys_menu_msg_sys_menu_msg_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_menu_msg_sys_menu_msg_id_seq OWNED BY sys_menu_msg.sys_menu_msg_id;


--
-- Name: sys_news; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_news (
    sys_news_id integer NOT NULL,
    org_id integer,
    sys_news_group integer,
    sys_news_title character varying(240) NOT NULL,
    publish boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.sys_news OWNER TO root;

--
-- Name: sys_news_sys_news_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_news_sys_news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_news_sys_news_id_seq OWNER TO root;

--
-- Name: sys_news_sys_news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_news_sys_news_id_seq OWNED BY sys_news.sys_news_id;


--
-- Name: sys_queries; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_queries (
    sys_queries_id integer NOT NULL,
    org_id integer,
    sys_query_name character varying(50),
    query_date timestamp without time zone DEFAULT now() NOT NULL,
    query_text text,
    query_params text
);


ALTER TABLE public.sys_queries OWNER TO root;

--
-- Name: sys_queries_sys_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_queries_sys_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_queries_sys_queries_id_seq OWNER TO root;

--
-- Name: sys_queries_sys_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_queries_sys_queries_id_seq OWNED BY sys_queries.sys_queries_id;


--
-- Name: sys_reset; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE sys_reset (
    sys_reset_id integer NOT NULL,
    entity_id integer,
    org_id integer,
    request_email character varying(320),
    request_time timestamp without time zone DEFAULT now(),
    login_ip character varying(64),
    narrative character varying(240)
);


ALTER TABLE public.sys_reset OWNER TO root;

--
-- Name: sys_reset_sys_reset_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE sys_reset_sys_reset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_reset_sys_reset_id_seq OWNER TO root;

--
-- Name: sys_reset_sys_reset_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE sys_reset_sys_reset_id_seq OWNED BY sys_reset.sys_reset_id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tasks (
    task_id integer NOT NULL,
    phase_id integer,
    entity_id integer,
    org_id integer,
    task_name character varying(320) NOT NULL,
    start_date date NOT NULL,
    dead_line date,
    end_date date,
    hours_taken integer DEFAULT 7 NOT NULL,
    completed boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.tasks OWNER TO postgres;

--
-- Name: tasks_task_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tasks_task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tasks_task_id_seq OWNER TO postgres;

--
-- Name: tasks_task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tasks_task_id_seq OWNED BY tasks.task_id;


--
-- Name: tax_rates; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tax_rates (
    tax_rate_id integer NOT NULL,
    tax_type_id integer,
    org_id integer,
    tax_range double precision NOT NULL,
    tax_rate double precision NOT NULL,
    narrative character varying(240)
);


ALTER TABLE public.tax_rates OWNER TO postgres;

--
-- Name: tax_rates_tax_rate_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tax_rates_tax_rate_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tax_rates_tax_rate_id_seq OWNER TO postgres;

--
-- Name: tax_rates_tax_rate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tax_rates_tax_rate_id_seq OWNED BY tax_rates.tax_rate_id;


--
-- Name: tax_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tax_types (
    tax_type_id integer NOT NULL,
    account_id integer,
    currency_id integer,
    org_id integer,
    tax_type_name character varying(50) NOT NULL,
    formural character varying(320),
    tax_relief real DEFAULT 0 NOT NULL,
    tax_type_order integer DEFAULT 0 NOT NULL,
    in_tax boolean DEFAULT false NOT NULL,
    tax_rate real DEFAULT 0 NOT NULL,
    tax_inclusive boolean DEFAULT false NOT NULL,
    linear boolean DEFAULT true,
    percentage boolean DEFAULT true,
    employer double precision DEFAULT 0 NOT NULL,
    employer_ps double precision DEFAULT 0 NOT NULL,
    account_number character varying(32),
    active boolean DEFAULT true,
    use_key integer DEFAULT 0 NOT NULL,
    details text
);


ALTER TABLE public.tax_types OWNER TO postgres;

--
-- Name: tax_types_tax_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tax_types_tax_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tax_types_tax_type_id_seq OWNER TO postgres;

--
-- Name: tax_types_tax_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tax_types_tax_type_id_seq OWNED BY tax_types.tax_type_id;


--
-- Name: tender_items; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tender_items (
    tender_item_id integer NOT NULL,
    org_id integer,
    bidder_id integer,
    tender_item_name character varying(320) NOT NULL,
    quantity integer,
    item_amount real,
    item_tax real,
    details text
);


ALTER TABLE public.tender_items OWNER TO postgres;

--
-- Name: tender_items_tender_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tender_items_tender_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tender_items_tender_item_id_seq OWNER TO postgres;

--
-- Name: tender_items_tender_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tender_items_tender_item_id_seq OWNED BY tender_items.tender_item_id;


--
-- Name: tender_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tender_types (
    tender_type_id integer NOT NULL,
    org_id integer,
    tender_type_name character varying(50),
    details text
);


ALTER TABLE public.tender_types OWNER TO postgres;

--
-- Name: tender_types_tender_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tender_types_tender_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tender_types_tender_type_id_seq OWNER TO postgres;

--
-- Name: tender_types_tender_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tender_types_tender_type_id_seq OWNED BY tender_types.tender_type_id;


--
-- Name: tenders; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE tenders (
    tender_id integer NOT NULL,
    org_id integer,
    tender_type_id integer,
    tender_name character varying(320),
    tender_number character varying(64),
    tender_date date NOT NULL,
    tender_end_date date,
    is_completed boolean DEFAULT false NOT NULL,
    details text
);


ALTER TABLE public.tenders OWNER TO postgres;

--
-- Name: tenders_tender_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tenders_tender_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tenders_tender_id_seq OWNER TO postgres;

--
-- Name: tenders_tender_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tenders_tender_id_seq OWNED BY tenders.tender_id;


--
-- Name: timesheet; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE timesheet (
    timesheet_id integer NOT NULL,
    task_id integer,
    org_id integer,
    ts_date date NOT NULL,
    ts_start_time time without time zone NOT NULL,
    ts_end_time time without time zone NOT NULL,
    ts_narrative character varying(320),
    details text
);


ALTER TABLE public.timesheet OWNER TO postgres;

--
-- Name: timesheet_timesheet_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE timesheet_timesheet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.timesheet_timesheet_id_seq OWNER TO postgres;

--
-- Name: timesheet_timesheet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE timesheet_timesheet_id_seq OWNED BY timesheet.timesheet_id;


--
-- Name: tomcat_users; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW tomcat_users AS
 SELECT entitys.user_name,
    entitys.entity_password,
    entity_types.entity_role
   FROM ((entity_subscriptions
     JOIN entitys ON ((entity_subscriptions.entity_id = entitys.entity_id)))
     JOIN entity_types ON ((entity_subscriptions.entity_type_id = entity_types.entity_type_id)))
  WHERE (entitys.is_active = true);


ALTER TABLE public.tomcat_users OWNER TO root;

--
-- Name: trainings; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE trainings (
    training_id integer NOT NULL,
    org_id integer,
    training_name character varying(50),
    start_date date,
    end_date date,
    training_cost real,
    completed boolean DEFAULT false NOT NULL,
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    details text
);


ALTER TABLE public.trainings OWNER TO postgres;

--
-- Name: trainings_training_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE trainings_training_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.trainings_training_id_seq OWNER TO postgres;

--
-- Name: trainings_training_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE trainings_training_id_seq OWNED BY trainings.training_id;


--
-- Name: transaction_details; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE transaction_details (
    transaction_detail_id integer NOT NULL,
    transaction_id integer,
    account_id integer,
    item_id integer,
    store_id integer,
    org_id integer,
    quantity integer NOT NULL,
    amount real DEFAULT 0 NOT NULL,
    tax_amount real DEFAULT 0 NOT NULL,
    narrative character varying(240),
    purpose character varying(320),
    details text
);


ALTER TABLE public.transaction_details OWNER TO postgres;

--
-- Name: transaction_details_transaction_detail_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE transaction_details_transaction_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transaction_details_transaction_detail_id_seq OWNER TO postgres;

--
-- Name: transaction_details_transaction_detail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE transaction_details_transaction_detail_id_seq OWNED BY transaction_details.transaction_detail_id;


--
-- Name: transaction_links; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE transaction_links (
    transaction_link_id integer NOT NULL,
    org_id integer,
    transaction_id integer,
    transaction_to integer,
    transaction_detail_id integer,
    transaction_detail_to integer,
    amount real DEFAULT 0 NOT NULL,
    quantity integer DEFAULT 0 NOT NULL,
    narrative character varying(240)
);


ALTER TABLE public.transaction_links OWNER TO postgres;

--
-- Name: transaction_links_transaction_link_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE transaction_links_transaction_link_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transaction_links_transaction_link_id_seq OWNER TO postgres;

--
-- Name: transaction_links_transaction_link_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE transaction_links_transaction_link_id_seq OWNED BY transaction_links.transaction_link_id;


--
-- Name: transaction_status; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE transaction_status (
    transaction_status_id integer NOT NULL,
    transaction_status_name character varying(50) NOT NULL
);


ALTER TABLE public.transaction_status OWNER TO postgres;

--
-- Name: transaction_types; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE transaction_types (
    transaction_type_id integer NOT NULL,
    transaction_type_name character varying(50) NOT NULL,
    document_prefix character varying(16) DEFAULT 'D'::character varying NOT NULL,
    document_number integer DEFAULT 1 NOT NULL,
    for_sales boolean DEFAULT true NOT NULL,
    for_posting boolean DEFAULT true NOT NULL
);


ALTER TABLE public.transaction_types OWNER TO postgres;

--
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE transactions (
    transaction_id integer NOT NULL,
    entity_id integer,
    transaction_type_id integer,
    bank_account_id integer,
    journal_id integer,
    transaction_status_id integer DEFAULT 1,
    currency_id integer,
    department_id integer,
    org_id integer,
    exchange_rate real DEFAULT 1 NOT NULL,
    transaction_date date NOT NULL,
    transaction_amount real DEFAULT 0 NOT NULL,
    document_number integer DEFAULT 1 NOT NULL,
    payment_number character varying(50),
    order_number character varying(50),
    payment_terms character varying(50),
    job character varying(240),
    point_of_use character varying(240),
    application_date timestamp without time zone DEFAULT now(),
    approve_status character varying(16) DEFAULT 'Draft'::character varying NOT NULL,
    workflow_table_id integer,
    action_date timestamp without time zone,
    narrative character varying(120),
    details text
);


ALTER TABLE public.transactions OWNER TO postgres;

--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE transactions_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.transactions_transaction_id_seq OWNER TO postgres;

--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE transactions_transaction_id_seq OWNED BY transactions.transaction_id;


--
-- Name: vw_account_types; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_account_types AS
 SELECT accounts_class.accounts_class_id,
    accounts_class.accounts_class_name,
    accounts_class.chat_type_id,
    accounts_class.chat_type_name,
    account_types.account_type_id,
    account_types.org_id,
    account_types.account_type_name,
    account_types.details
   FROM (account_types
     JOIN accounts_class ON ((account_types.accounts_class_id = accounts_class.accounts_class_id)));


ALTER TABLE public.vw_account_types OWNER TO postgres;

--
-- Name: vw_accounts; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_accounts AS
 SELECT vw_account_types.accounts_class_id,
    vw_account_types.chat_type_id,
    vw_account_types.chat_type_name,
    vw_account_types.accounts_class_name,
    vw_account_types.account_type_id,
    vw_account_types.account_type_name,
    accounts.account_id,
    accounts.org_id,
    accounts.account_name,
    accounts.is_header,
    accounts.is_active,
    accounts.details,
    ((((((accounts.account_id || ' : '::text) || (vw_account_types.accounts_class_name)::text) || ' : '::text) || (vw_account_types.account_type_name)::text) || ' : '::text) || (accounts.account_name)::text) AS account_description
   FROM (accounts
     JOIN vw_account_types ON ((accounts.account_type_id = vw_account_types.account_type_id)));


ALTER TABLE public.vw_accounts OWNER TO postgres;

--
-- Name: vw_address; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_address AS
 SELECT sys_countrys.sys_country_id,
    sys_countrys.sys_country_name,
    address.address_id,
    address.org_id,
    address.address_name,
    address.table_name,
    address.table_id,
    address.post_office_box,
    address.postal_code,
    address.premises,
    address.street,
    address.town,
    address.phone_number,
    address.extension,
    address.mobile,
    address.fax,
    address.email,
    address.is_default,
    address.website,
    address.details,
    address_types.address_type_id,
    address_types.address_type_name
   FROM ((address
     JOIN sys_countrys ON ((address.sys_country_id = sys_countrys.sys_country_id)))
     LEFT JOIN address_types ON ((address.address_type_id = address_types.address_type_id)));


ALTER TABLE public.vw_address OWNER TO root;

--
-- Name: vw_adjustments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_adjustments AS
 SELECT currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    adjustments.org_id,
    adjustments.adjustment_id,
    adjustments.adjustment_name,
    adjustments.adjustment_type,
    adjustments.adjustment_order,
    adjustments.earning_code,
    adjustments.formural,
    adjustments.monthly_update,
    adjustments.in_payroll,
    adjustments.in_tax,
    adjustments.visible,
    adjustments.running_balance,
    adjustments.reduce_balance,
    adjustments.tax_reduction_ps,
    adjustments.tax_relief_ps,
    adjustments.tax_max_allowed,
    adjustments.account_number,
    adjustments.details
   FROM (adjustments
     JOIN currency ON ((adjustments.currency_id = currency.currency_id)));


ALTER TABLE public.vw_adjustments OWNER TO postgres;

--
-- Name: vw_bank_branch; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_bank_branch AS
 SELECT sys_countrys.sys_country_id,
    sys_countrys.sys_country_code,
    sys_countrys.sys_country_name,
    banks.bank_id,
    banks.bank_name,
    banks.bank_code,
    banks.swift_code,
    banks.sort_code,
    bank_branch.bank_branch_id,
    bank_branch.org_id,
    bank_branch.bank_branch_name,
    bank_branch.bank_branch_code,
    bank_branch.narrative
   FROM ((bank_branch
     JOIN banks ON ((bank_branch.bank_id = banks.bank_id)))
     LEFT JOIN sys_countrys ON ((banks.sys_country_id = sys_countrys.sys_country_id)));


ALTER TABLE public.vw_bank_branch OWNER TO postgres;

--
-- Name: vw_department_roles; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_department_roles AS
 SELECT departments.department_id,
    departments.department_name,
    departments.description AS department_description,
    departments.duties AS department_duties,
    ln_department_roles.department_role_name AS parent_role_name,
    department_roles.org_id,
    department_roles.department_role_id,
    department_roles.ln_department_role_id,
    department_roles.department_role_name,
    department_roles.job_description,
    department_roles.job_requirements,
    department_roles.duties,
    department_roles.performance_measures,
    department_roles.active,
    department_roles.details
   FROM ((department_roles
     JOIN departments ON ((department_roles.department_id = departments.department_id)))
     LEFT JOIN department_roles ln_department_roles ON ((department_roles.ln_department_role_id = ln_department_roles.department_role_id)));


ALTER TABLE public.vw_department_roles OWNER TO postgres;

--
-- Name: vw_periods; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_periods AS
 SELECT fiscal_years.fiscal_year_id,
    fiscal_years.fiscal_year_start,
    fiscal_years.fiscal_year_end,
    fiscal_years.year_opened,
    fiscal_years.year_closed,
    periods.period_id,
    periods.org_id,
    periods.start_date,
    periods.end_date,
    periods.opened,
    periods.activated,
    periods.closed,
    periods.overtime_rate,
    periods.per_diem_tax_limit,
    periods.is_posted,
    periods.bank_header,
    periods.gl_payroll_account,
    periods.gl_bank_account,
    periods.bank_address,
    periods.details,
    date_part('month'::text, periods.start_date) AS month_id,
    to_char((periods.start_date)::timestamp with time zone, 'YYYY'::text) AS period_year,
    to_char((periods.start_date)::timestamp with time zone, 'Month'::text) AS period_month,
    (trunc(((date_part('month'::text, periods.start_date) - (1)::double precision) / (3)::double precision)) + (1)::double precision) AS quarter,
    (trunc(((date_part('month'::text, periods.start_date) - (1)::double precision) / (6)::double precision)) + (1)::double precision) AS semister,
    to_char((periods.start_date)::timestamp with time zone, 'YYYYMM'::text) AS period_code
   FROM (periods
     LEFT JOIN fiscal_years ON (((periods.fiscal_year_id)::text = (fiscal_years.fiscal_year_id)::text)))
  ORDER BY periods.start_date;


ALTER TABLE public.vw_periods OWNER TO postgres;

--
-- Name: vw_employee_month; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_month AS
 SELECT vw_periods.period_id,
    vw_periods.start_date,
    vw_periods.end_date,
    vw_periods.overtime_rate,
    vw_periods.activated,
    vw_periods.closed,
    vw_periods.month_id,
    vw_periods.period_year,
    vw_periods.period_month,
    vw_periods.quarter,
    vw_periods.semister,
    vw_periods.bank_header,
    vw_periods.bank_address,
    vw_periods.gl_payroll_account,
    vw_periods.gl_bank_account,
    vw_periods.is_posted,
    vw_bank_branch.bank_id,
    vw_bank_branch.bank_name,
    vw_bank_branch.bank_branch_id,
    vw_bank_branch.bank_branch_name,
    vw_bank_branch.bank_branch_code,
    pay_groups.pay_group_id,
    pay_groups.pay_group_name,
    vw_department_roles.department_id,
    vw_department_roles.department_name,
    vw_department_roles.department_role_id,
    vw_department_roles.department_role_name,
    entitys.entity_id,
    entitys.entity_name,
    employees.employee_id,
    employees.surname,
    employees.first_name,
    employees.middle_name,
    employees.date_of_birth,
    employees.gender,
    employees.nationality,
    employees.marital_status,
    employees.appointment_date,
    employees.exit_date,
    employees.contract,
    employees.contract_period,
    employees.employment_terms,
    employees.identity_card,
    (((((employees.surname)::text || ' '::text) || (employees.first_name)::text) || ' '::text) || (COALESCE(employees.middle_name, ''::character varying))::text) AS employee_name,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    employee_month.exchange_rate,
    employee_month.org_id,
    employee_month.employee_month_id,
    employee_month.bank_account,
    employee_month.basic_pay,
    employee_month.details,
    getadjustment(employee_month.employee_month_id, 4, 31) AS overtime,
    getadjustment(employee_month.employee_month_id, 1, 1) AS full_allowance,
    getadjustment(employee_month.employee_month_id, 1, 2) AS payroll_allowance,
    getadjustment(employee_month.employee_month_id, 1, 3) AS tax_allowance,
    getadjustment(employee_month.employee_month_id, 2, 1) AS full_deduction,
    getadjustment(employee_month.employee_month_id, 2, 2) AS payroll_deduction,
    getadjustment(employee_month.employee_month_id, 2, 3) AS tax_deduction,
    getadjustment(employee_month.employee_month_id, 3, 1) AS full_expense,
    getadjustment(employee_month.employee_month_id, 3, 2) AS payroll_expense,
    getadjustment(employee_month.employee_month_id, 3, 3) AS tax_expense,
    getadjustment(employee_month.employee_month_id, 4, 11) AS payroll_tax,
    getadjustment(employee_month.employee_month_id, 4, 12) AS tax_tax,
    getadjustment(employee_month.employee_month_id, 4, 22) AS net_adjustment,
    getadjustment(employee_month.employee_month_id, 4, 33) AS per_diem,
    getadjustment(employee_month.employee_month_id, 4, 34) AS advance,
    getadjustment(employee_month.employee_month_id, 4, 35) AS advance_deduction,
    ((((employee_month.basic_pay + getadjustment(employee_month.employee_month_id, 4, 31)) + getadjustment(employee_month.employee_month_id, 4, 22)) + getadjustment(employee_month.employee_month_id, 4, 33)) - getadjustment(employee_month.employee_month_id, 4, 11)) AS net_pay,
    ((((((((employee_month.basic_pay + getadjustment(employee_month.employee_month_id, 4, 31)) + getadjustment(employee_month.employee_month_id, 4, 22)) + getadjustment(employee_month.employee_month_id, 4, 33)) + getadjustment(employee_month.employee_month_id, 4, 34)) - getadjustment(employee_month.employee_month_id, 4, 11)) - getadjustment(employee_month.employee_month_id, 4, 35)) - getadjustment(employee_month.employee_month_id, 4, 36)) - getadjustment(employee_month.employee_month_id, 4, 41)) AS banked,
    ((((employee_month.basic_pay + getadjustment(employee_month.employee_month_id, 4, 31)) + getadjustment(employee_month.employee_month_id, 1, 1)) + getadjustment(employee_month.employee_month_id, 3, 1)) + getadjustment(employee_month.employee_month_id, 4, 33)) AS cost
   FROM (((((((employee_month
     JOIN vw_bank_branch ON ((employee_month.bank_branch_id = vw_bank_branch.bank_branch_id)))
     JOIN vw_periods ON ((employee_month.period_id = vw_periods.period_id)))
     JOIN pay_groups ON ((employee_month.pay_group_id = pay_groups.pay_group_id)))
     JOIN entitys ON ((employee_month.entity_id = entitys.entity_id)))
     JOIN vw_department_roles ON ((employee_month.department_role_id = vw_department_roles.department_role_id)))
     JOIN employees ON ((employee_month.entity_id = employees.entity_id)))
     JOIN currency ON ((employee_month.currency_id = currency.currency_id)));


ALTER TABLE public.vw_employee_month OWNER TO postgres;

--
-- Name: vw_advance_deductions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_advance_deductions AS
 SELECT vw_employee_month.employee_month_id,
    vw_employee_month.period_id,
    vw_employee_month.start_date,
    vw_employee_month.month_id,
    vw_employee_month.period_year,
    vw_employee_month.period_month,
    vw_employee_month.entity_id,
    vw_employee_month.entity_name,
    vw_employee_month.employee_id,
    advance_deductions.org_id,
    advance_deductions.advance_deduction_id,
    advance_deductions.pay_date,
    advance_deductions.amount,
    advance_deductions.in_payroll,
    advance_deductions.narrative
   FROM (advance_deductions
     JOIN vw_employee_month ON ((advance_deductions.employee_month_id = vw_employee_month.employee_month_id)));


ALTER TABLE public.vw_advance_deductions OWNER TO postgres;

--
-- Name: vw_advance_statement; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_advance_statement AS
 SELECT vw_employee_month.employee_month_id,
    vw_employee_month.period_id,
    vw_employee_month.start_date,
    vw_employee_month.month_id,
    vw_employee_month.period_year,
    vw_employee_month.period_month,
    vw_employee_month.entity_id,
    vw_employee_month.entity_name,
    vw_employee_month.employee_id,
    employee_advances.org_id,
    employee_advances.pay_date,
    employee_advances.in_payroll,
    employee_advances.narrative,
    employee_advances.amount,
    (0)::real AS recovery
   FROM (employee_advances
     JOIN vw_employee_month ON ((employee_advances.employee_month_id = vw_employee_month.employee_month_id)))
  WHERE ((employee_advances.approve_status)::text = 'Approved'::text)
UNION
 SELECT vw_employee_month.employee_month_id,
    vw_employee_month.period_id,
    vw_employee_month.start_date,
    vw_employee_month.month_id,
    vw_employee_month.period_year,
    vw_employee_month.period_month,
    vw_employee_month.entity_id,
    vw_employee_month.entity_name,
    vw_employee_month.employee_id,
    advance_deductions.org_id,
    advance_deductions.pay_date,
    advance_deductions.in_payroll,
    advance_deductions.narrative,
    (0)::real AS amount,
    advance_deductions.amount AS recovery
   FROM (advance_deductions
     JOIN vw_employee_month ON ((advance_deductions.employee_month_id = vw_employee_month.employee_month_id)));


ALTER TABLE public.vw_advance_statement OWNER TO postgres;

--
-- Name: vw_education_max; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_education_max AS
 SELECT education_class.education_class_id,
    education_class.education_class_name,
    education.org_id,
    education.education_id,
    education.entity_id,
    education.date_from,
    education.date_to,
    education.name_of_school,
    education.examination_taken,
    education.grades_obtained,
    education.certificate_number
   FROM ((education_class
     JOIN education ON ((education_class.education_class_id = education.education_class_id)))
     JOIN ( SELECT education_1.entity_id,
            max(education_1.education_id) AS max_education_id
           FROM (education education_1
             JOIN ( SELECT education_2.entity_id,
                    max(education_2.education_class_id) AS max_education_class_id
                   FROM education education_2
                  GROUP BY education_2.entity_id) a ON (((education_1.entity_id = a.entity_id) AND (education_1.education_class_id = a.max_education_class_id))))
          GROUP BY education_1.entity_id) b ON ((education.education_id = b.max_education_id)));


ALTER TABLE public.vw_education_max OWNER TO postgres;

--
-- Name: vw_employment_max; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employment_max AS
 SELECT employment.employment_id,
    employment.entity_id,
    employment.date_from,
    employment.date_to,
    employment.org_id,
    employment.employers_name,
    employment.position_held,
    age((COALESCE(employment.date_to, ('now'::text)::date))::timestamp with time zone, (employment.date_from)::timestamp with time zone) AS employment_duration,
    c.employment_experince
   FROM ((employment
     JOIN ( SELECT max(employment_1.employment_id) AS max_employment_id
           FROM (employment employment_1
             JOIN ( SELECT employment_2.entity_id,
                    max(employment_2.date_from) AS max_date_from
                   FROM employment employment_2
                  GROUP BY employment_2.entity_id) a ON (((employment_1.entity_id = a.entity_id) AND (employment_1.date_from = a.max_date_from))))
          GROUP BY employment_1.entity_id) b ON ((employment.employment_id = b.max_employment_id)))
     JOIN ( SELECT employment_1.entity_id,
            sum(age((COALESCE(employment_1.date_to, ('now'::text)::date))::timestamp with time zone, (employment_1.date_from)::timestamp with time zone)) AS employment_experince
           FROM employment employment_1
          GROUP BY employment_1.entity_id) c ON ((employment.entity_id = c.entity_id)));


ALTER TABLE public.vw_employment_max OWNER TO postgres;

--
-- Name: vw_applicants; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_applicants AS
 SELECT sys_countrys.sys_country_id,
    sys_countrys.sys_country_name,
    applicants.entity_id,
    applicants.surname,
    applicants.org_id,
    applicants.first_name,
    applicants.middle_name,
    applicants.date_of_birth,
    applicants.nationality,
    applicants.identity_card,
    applicants.language,
    applicants.objective,
    applicants.interests,
    applicants.picture_file,
    applicants.details,
    applicants.person_title,
    applicants.field_of_study,
    applicants.applicant_email,
    applicants.applicant_phone,
    (((((applicants.surname)::text || ' '::text) || (applicants.first_name)::text) || ' '::text) || (COALESCE(applicants.middle_name, ''::character varying))::text) AS applicant_name,
    to_char(age((applicants.date_of_birth)::timestamp with time zone), 'YY'::text) AS applicant_age,
        CASE
            WHEN ((applicants.gender)::text = 'M'::text) THEN 'Male'::text
            ELSE 'Female'::text
        END AS gender_name,
        CASE
            WHEN ((applicants.marital_status)::text = 'M'::text) THEN 'Married'::text
            ELSE 'Single'::text
        END AS marital_status_name,
    vw_education_max.education_class_id,
    vw_education_max.education_class_name,
    vw_education_max.education_id,
    vw_education_max.date_from,
    vw_education_max.date_to,
    vw_education_max.name_of_school,
    vw_education_max.examination_taken,
    vw_education_max.grades_obtained,
    vw_education_max.certificate_number,
    vw_employment_max.employers_name,
    vw_employment_max.position_held,
    vw_employment_max.date_from AS emp_date_from,
    vw_employment_max.date_to AS emp_date_to,
    vw_employment_max.employment_duration,
    vw_employment_max.employment_experince,
    round(((date_part('year'::text, vw_employment_max.employment_duration) + (date_part('month'::text, vw_employment_max.employment_duration) / (12)::double precision)))::numeric, 1) AS emp_duration,
    round(((date_part('year'::text, vw_employment_max.employment_experince) + (date_part('month'::text, vw_employment_max.employment_experince) / (12)::double precision)))::numeric, 1) AS emp_experince
   FROM (((applicants
     JOIN sys_countrys ON ((applicants.nationality = sys_countrys.sys_country_id)))
     LEFT JOIN vw_education_max ON ((applicants.entity_id = vw_education_max.entity_id)))
     LEFT JOIN vw_employment_max ON ((applicants.entity_id = vw_employment_max.entity_id)));


ALTER TABLE public.vw_applicants OWNER TO postgres;

--
-- Name: vw_intake; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_intake AS
 SELECT vw_department_roles.department_id,
    vw_department_roles.department_name,
    vw_department_roles.department_description,
    vw_department_roles.department_duties,
    vw_department_roles.department_role_id,
    vw_department_roles.department_role_name,
    vw_department_roles.job_description,
    vw_department_roles.job_requirements,
    vw_department_roles.duties,
    vw_department_roles.performance_measures,
    locations.location_id,
    locations.location_name,
    pay_groups.pay_group_id,
    pay_groups.pay_group_name,
    pay_scales.pay_scale_id,
    pay_scales.pay_scale_name,
    intake.org_id,
    intake.intake_id,
    intake.opening_date,
    intake.closing_date,
    intake.positions,
    intake.contract,
    intake.contract_period,
    intake.details
   FROM ((((intake
     JOIN vw_department_roles ON ((intake.department_role_id = vw_department_roles.department_role_id)))
     JOIN locations ON ((intake.location_id = locations.location_id)))
     JOIN pay_groups ON ((intake.pay_group_id = pay_groups.pay_group_id)))
     JOIN pay_scales ON ((intake.pay_scale_id = pay_scales.pay_scale_id)));


ALTER TABLE public.vw_intake OWNER TO postgres;

--
-- Name: vw_applications; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_applications AS
 SELECT vw_intake.department_id,
    vw_intake.department_name,
    vw_intake.department_description,
    vw_intake.department_duties,
    vw_intake.department_role_id,
    vw_intake.department_role_name,
    vw_intake.job_description,
    vw_intake.job_requirements,
    vw_intake.duties,
    vw_intake.performance_measures,
    vw_intake.intake_id,
    vw_intake.opening_date,
    vw_intake.closing_date,
    vw_intake.positions,
    entitys.entity_id,
    entitys.entity_name,
    applications.application_id,
    applications.employee_id,
    applications.contract_date,
    applications.contract_close,
    applications.contract_start,
    applications.contract_period,
    applications.contract_terms,
    applications.initial_salary,
    applications.application_date,
    applications.approve_status,
    applications.workflow_table_id,
    applications.action_date,
    applications.applicant_comments,
    applications.review,
    applications.short_listed,
    applications.org_id,
    vw_education_max.education_class_name,
    vw_education_max.date_from,
    vw_education_max.date_to,
    vw_education_max.name_of_school,
    vw_education_max.examination_taken,
    vw_education_max.grades_obtained,
    vw_education_max.certificate_number,
    vw_employment_max.employment_id,
    vw_employment_max.employers_name,
    vw_employment_max.position_held,
    vw_employment_max.date_from AS emp_date_from,
    vw_employment_max.date_to AS emp_date_to,
    vw_employment_max.employment_duration,
    vw_employment_max.employment_experince,
    round(((date_part('year'::text, vw_employment_max.employment_duration) + (date_part('month'::text, vw_employment_max.employment_duration) / (12)::double precision)))::numeric, 1) AS emp_duration,
    round(((date_part('year'::text, vw_employment_max.employment_experince) + (date_part('month'::text, vw_employment_max.employment_experince) / (12)::double precision)))::numeric, 1) AS emp_experince
   FROM ((((applications
     JOIN entitys ON ((applications.entity_id = entitys.entity_id)))
     JOIN vw_intake ON ((applications.intake_id = vw_intake.intake_id)))
     LEFT JOIN vw_education_max ON ((entitys.entity_id = vw_education_max.entity_id)))
     LEFT JOIN vw_employment_max ON ((entitys.entity_id = vw_employment_max.entity_id)));


ALTER TABLE public.vw_applications OWNER TO postgres;

--
-- Name: workflows; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE workflows (
    workflow_id integer NOT NULL,
    source_entity_id integer NOT NULL,
    org_id integer,
    workflow_name character varying(240) NOT NULL,
    table_name character varying(64),
    table_link_field character varying(64),
    table_link_id integer,
    approve_email text,
    reject_email text,
    approve_file character varying(320),
    reject_file character varying(320),
    details text
);


ALTER TABLE public.workflows OWNER TO root;

--
-- Name: vw_workflows; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_workflows AS
 SELECT entity_types.entity_type_id AS source_entity_id,
    entity_types.entity_type_name AS source_entity_name,
    workflows.workflow_id,
    workflows.org_id,
    workflows.workflow_name,
    workflows.table_name,
    workflows.table_link_field,
    workflows.table_link_id,
    workflows.approve_email,
    workflows.reject_email,
    workflows.approve_file,
    workflows.reject_file,
    workflows.details
   FROM (workflows
     JOIN entity_types ON ((workflows.source_entity_id = entity_types.entity_type_id)));


ALTER TABLE public.vw_workflows OWNER TO root;

--
-- Name: workflow_phases; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE workflow_phases (
    workflow_phase_id integer NOT NULL,
    workflow_id integer NOT NULL,
    approval_entity_id integer NOT NULL,
    org_id integer,
    approval_level integer DEFAULT 1 NOT NULL,
    return_level integer DEFAULT 1 NOT NULL,
    escalation_days integer DEFAULT 0 NOT NULL,
    escalation_hours integer DEFAULT 3 NOT NULL,
    required_approvals integer DEFAULT 1 NOT NULL,
    reporting_level integer DEFAULT 1 NOT NULL,
    use_reporting boolean DEFAULT false NOT NULL,
    advice boolean DEFAULT false NOT NULL,
    notice boolean DEFAULT false NOT NULL,
    phase_narrative character varying(240),
    advice_email text,
    notice_email text,
    advice_file character varying(320),
    notice_file character varying(320),
    details text
);


ALTER TABLE public.workflow_phases OWNER TO root;

--
-- Name: vw_workflow_phases; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_workflow_phases AS
 SELECT vw_workflows.source_entity_id,
    vw_workflows.source_entity_name,
    vw_workflows.workflow_id,
    vw_workflows.workflow_name,
    vw_workflows.table_name,
    vw_workflows.table_link_field,
    vw_workflows.table_link_id,
    vw_workflows.approve_email,
    vw_workflows.reject_email,
    vw_workflows.approve_file,
    vw_workflows.reject_file,
    entity_types.entity_type_id AS approval_entity_id,
    entity_types.entity_type_name AS approval_entity_name,
    workflow_phases.workflow_phase_id,
    workflow_phases.org_id,
    workflow_phases.approval_level,
    workflow_phases.return_level,
    workflow_phases.escalation_days,
    workflow_phases.escalation_hours,
    workflow_phases.notice,
    workflow_phases.notice_email,
    workflow_phases.notice_file,
    workflow_phases.advice,
    workflow_phases.advice_email,
    workflow_phases.advice_file,
    workflow_phases.required_approvals,
    workflow_phases.use_reporting,
    workflow_phases.reporting_level,
    workflow_phases.phase_narrative,
    workflow_phases.details
   FROM ((workflow_phases
     JOIN vw_workflows ON ((workflow_phases.workflow_id = vw_workflows.workflow_id)))
     JOIN entity_types ON ((workflow_phases.approval_entity_id = entity_types.entity_type_id)));


ALTER TABLE public.vw_workflow_phases OWNER TO root;

--
-- Name: vw_approvals; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_approvals AS
 SELECT vw_workflow_phases.workflow_id,
    vw_workflow_phases.workflow_name,
    vw_workflow_phases.approve_email,
    vw_workflow_phases.reject_email,
    vw_workflow_phases.source_entity_id,
    vw_workflow_phases.source_entity_name,
    vw_workflow_phases.approval_entity_id,
    vw_workflow_phases.approval_entity_name,
    vw_workflow_phases.workflow_phase_id,
    vw_workflow_phases.approval_level,
    vw_workflow_phases.phase_narrative,
    vw_workflow_phases.return_level,
    vw_workflow_phases.required_approvals,
    vw_workflow_phases.notice,
    vw_workflow_phases.notice_email,
    vw_workflow_phases.notice_file,
    vw_workflow_phases.advice,
    vw_workflow_phases.advice_email,
    vw_workflow_phases.advice_file,
    approvals.approval_id,
    approvals.org_id,
    approvals.forward_id,
    approvals.table_name,
    approvals.table_id,
    approvals.completion_date,
    approvals.escalation_days,
    approvals.escalation_hours,
    approvals.escalation_time,
    approvals.application_date,
    approvals.approve_status,
    approvals.action_date,
    approvals.approval_narrative,
    approvals.to_be_done,
    approvals.what_is_done,
    approvals.review_advice,
    approvals.details,
    oe.entity_id AS org_entity_id,
    oe.entity_name AS org_entity_name,
    oe.user_name AS org_user_name,
    oe.primary_email AS org_primary_email,
    ae.entity_id AS app_entity_id,
    ae.entity_name AS app_entity_name,
    ae.user_name AS app_user_name,
    ae.primary_email AS app_primary_email
   FROM (((vw_workflow_phases
     JOIN approvals ON ((vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id)))
     JOIN entitys oe ON ((approvals.org_entity_id = oe.entity_id)))
     LEFT JOIN entitys ae ON ((approvals.app_entity_id = ae.entity_id)));


ALTER TABLE public.vw_approvals OWNER TO root;

--
-- Name: vw_approvals_entitys; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_approvals_entitys AS
 SELECT vw_workflow_phases.workflow_id,
    vw_workflow_phases.workflow_name,
    vw_workflow_phases.source_entity_id,
    vw_workflow_phases.source_entity_name,
    vw_workflow_phases.approval_entity_id,
    vw_workflow_phases.approval_entity_name,
    vw_workflow_phases.workflow_phase_id,
    vw_workflow_phases.approval_level,
    vw_workflow_phases.notice,
    vw_workflow_phases.notice_email,
    vw_workflow_phases.notice_file,
    vw_workflow_phases.advice,
    vw_workflow_phases.advice_email,
    vw_workflow_phases.advice_file,
    vw_workflow_phases.return_level,
    vw_workflow_phases.required_approvals,
    vw_workflow_phases.phase_narrative,
    approvals.approval_id,
    approvals.org_id,
    approvals.forward_id,
    approvals.table_name,
    approvals.table_id,
    approvals.completion_date,
    approvals.escalation_days,
    approvals.escalation_hours,
    approvals.escalation_time,
    approvals.application_date,
    approvals.approve_status,
    approvals.action_date,
    approvals.approval_narrative,
    approvals.to_be_done,
    approvals.what_is_done,
    approvals.review_advice,
    approvals.details,
    oe.entity_id AS org_entity_id,
    oe.entity_name AS org_entity_name,
    oe.user_name AS org_user_name,
    oe.primary_email AS org_primary_email,
    entitys.entity_id,
    entitys.entity_name,
    entitys.user_name,
    entitys.primary_email
   FROM ((((vw_workflow_phases
     JOIN approvals ON ((vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id)))
     JOIN entitys oe ON ((approvals.org_entity_id = oe.entity_id)))
     JOIN entity_subscriptions ON ((vw_workflow_phases.approval_entity_id = entity_subscriptions.entity_type_id)))
     JOIN entitys ON ((entity_subscriptions.entity_id = entitys.entity_id)))
  WHERE ((approvals.forward_id IS NULL) AND (vw_workflow_phases.use_reporting = false))
UNION
 SELECT vw_workflow_phases.workflow_id,
    vw_workflow_phases.workflow_name,
    vw_workflow_phases.source_entity_id,
    vw_workflow_phases.source_entity_name,
    vw_workflow_phases.approval_entity_id,
    vw_workflow_phases.approval_entity_name,
    vw_workflow_phases.workflow_phase_id,
    vw_workflow_phases.approval_level,
    vw_workflow_phases.notice,
    vw_workflow_phases.notice_email,
    vw_workflow_phases.notice_file,
    vw_workflow_phases.advice,
    vw_workflow_phases.advice_email,
    vw_workflow_phases.advice_file,
    vw_workflow_phases.return_level,
    vw_workflow_phases.required_approvals,
    vw_workflow_phases.phase_narrative,
    approvals.approval_id,
    approvals.org_id,
    approvals.forward_id,
    approvals.table_name,
    approvals.table_id,
    approvals.completion_date,
    approvals.escalation_days,
    approvals.escalation_hours,
    approvals.escalation_time,
    approvals.application_date,
    approvals.approve_status,
    approvals.action_date,
    approvals.approval_narrative,
    approvals.to_be_done,
    approvals.what_is_done,
    approvals.review_advice,
    approvals.details,
    oe.entity_id AS org_entity_id,
    oe.entity_name AS org_entity_name,
    oe.user_name AS org_user_name,
    oe.primary_email AS org_primary_email,
    entitys.entity_id,
    entitys.entity_name,
    entitys.user_name,
    entitys.primary_email
   FROM ((((vw_workflow_phases
     JOIN approvals ON ((vw_workflow_phases.workflow_phase_id = approvals.workflow_phase_id)))
     JOIN entitys oe ON ((approvals.org_entity_id = oe.entity_id)))
     JOIN reporting ON (((approvals.org_entity_id = reporting.entity_id) AND (vw_workflow_phases.reporting_level = reporting.reporting_level))))
     JOIN entitys ON ((reporting.report_to_id = entitys.entity_id)))
  WHERE ((((approvals.forward_id IS NULL) AND (reporting.primary_report = true)) AND (reporting.is_active = true)) AND (vw_workflow_phases.use_reporting = true));


ALTER TABLE public.vw_approvals_entitys OWNER TO root;

--
-- Name: vw_asset_movement; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_asset_movement AS
 SELECT departments.department_id,
    departments.department_name,
    asset_movement.asset_movement_id,
    asset_movement.asset_id,
    asset_movement.org_id,
    asset_movement.date_aquired,
    asset_movement.date_left,
    asset_movement.details
   FROM (asset_movement
     JOIN departments ON ((asset_movement.department_id = departments.department_id)));


ALTER TABLE public.vw_asset_movement OWNER TO postgres;

--
-- Name: vw_assets; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_assets AS
 SELECT asset_types.asset_type_id,
    asset_types.asset_type_name,
    items.item_id,
    items.item_name,
    assets.asset_id,
    assets.org_id,
    assets.asset_name,
    assets.asset_serial,
    assets.purchase_date,
    assets.purchase_value,
    assets.disposal_amount,
    assets.disposal_date,
    assets.disposal_posting,
    assets.lost,
    assets.stolen,
    assets.tag_number,
    assets.asset_location,
    assets.asset_condition,
    assets.asset_acquisition,
    assets.details
   FROM ((assets
     JOIN asset_types ON ((assets.asset_type_id = asset_types.asset_type_id)))
     JOIN items ON ((assets.item_id = items.item_id)));


ALTER TABLE public.vw_assets OWNER TO postgres;

--
-- Name: vw_attendance; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_attendance AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    attendance.attendance_id,
    attendance.attendance_date,
    attendance.org_id,
    attendance.time_in,
    attendance.time_out,
    attendance.details
   FROM (attendance
     JOIN entitys ON ((attendance.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_attendance OWNER TO postgres;

--
-- Name: vw_bank_accounts; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_bank_accounts AS
 SELECT vw_bank_branch.bank_id,
    vw_bank_branch.bank_name,
    vw_bank_branch.bank_branch_id,
    vw_bank_branch.bank_branch_name,
    vw_accounts.account_type_id,
    vw_accounts.account_type_name,
    vw_accounts.account_id,
    vw_accounts.account_name,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    bank_accounts.bank_account_id,
    bank_accounts.org_id,
    bank_accounts.bank_account_name,
    bank_accounts.bank_account_number,
    bank_accounts.narrative,
    bank_accounts.is_active,
    bank_accounts.details
   FROM (((bank_accounts
     JOIN vw_bank_branch ON ((bank_accounts.bank_branch_id = vw_bank_branch.bank_branch_id)))
     JOIN vw_accounts ON ((bank_accounts.account_id = vw_accounts.account_id)))
     JOIN currency ON ((bank_accounts.currency_id = currency.currency_id)));


ALTER TABLE public.vw_bank_accounts OWNER TO postgres;

--
-- Name: vw_budgets; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_budgets AS
 SELECT departments.department_id,
    departments.department_name,
    fiscal_years.fiscal_year_id,
    fiscal_years.fiscal_year_start,
    fiscal_years.fiscal_year_end,
    fiscal_years.year_opened,
    fiscal_years.year_closed,
    budgets.budget_id,
    budgets.org_id,
    budgets.budget_type,
    budgets.budget_name,
    budgets.application_date,
    budgets.approve_status,
    budgets.workflow_table_id,
    budgets.action_date,
    budgets.details
   FROM ((budgets
     JOIN departments ON ((budgets.department_id = departments.department_id)))
     JOIN fiscal_years ON (((budgets.fiscal_year_id)::text = (fiscal_years.fiscal_year_id)::text)));


ALTER TABLE public.vw_budgets OWNER TO postgres;

--
-- Name: vw_items; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_items AS
 SELECT sales_account.account_id AS sales_account_id,
    sales_account.account_name AS sales_account_name,
    purchase_account.account_id AS purchase_account_id,
    purchase_account.account_name AS purchase_account_name,
    item_category.item_category_id,
    item_category.item_category_name,
    item_units.item_unit_id,
    item_units.item_unit_name,
    tax_types.tax_type_id,
    tax_types.tax_type_name,
    tax_types.account_id AS tax_account_id,
    tax_types.tax_rate,
    tax_types.tax_inclusive,
    items.item_id,
    items.org_id,
    items.item_name,
    items.inventory,
    items.bar_code,
    items.for_sale,
    items.for_purchase,
    items.sales_price,
    items.purchase_price,
    items.reorder_level,
    items.lead_time,
    items.is_active,
    items.details
   FROM (((((items
     JOIN accounts sales_account ON ((items.sales_account_id = sales_account.account_id)))
     JOIN accounts purchase_account ON ((items.purchase_account_id = purchase_account.account_id)))
     JOIN item_category ON ((items.item_category_id = item_category.item_category_id)))
     JOIN item_units ON ((items.item_unit_id = item_units.item_unit_id)))
     JOIN tax_types ON ((items.tax_type_id = tax_types.tax_type_id)));


ALTER TABLE public.vw_items OWNER TO postgres;

--
-- Name: vw_budget_lines; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_budget_lines AS
 SELECT vw_budgets.department_id,
    vw_budgets.department_name,
    vw_budgets.fiscal_year_id,
    vw_budgets.fiscal_year_start,
    vw_budgets.fiscal_year_end,
    vw_budgets.year_opened,
    vw_budgets.year_closed,
    vw_budgets.budget_id,
    vw_budgets.budget_name,
    vw_budgets.budget_type,
    vw_budgets.approve_status,
    periods.period_id,
    periods.start_date,
    periods.end_date,
    periods.opened,
    periods.activated,
    periods.closed,
    periods.overtime_rate,
    periods.per_diem_tax_limit,
    periods.is_posted,
    periods.bank_header,
    periods.bank_address,
    date_part('month'::text, periods.start_date) AS month_id,
    to_char((periods.start_date)::timestamp with time zone, 'YYYY'::text) AS period_year,
    to_char((periods.start_date)::timestamp with time zone, 'Month'::text) AS period_month,
    (trunc(((date_part('month'::text, periods.start_date) - (1)::double precision) / (3)::double precision)) + (1)::double precision) AS quarter,
    (trunc(((date_part('month'::text, periods.start_date) - (1)::double precision) / (6)::double precision)) + (1)::double precision) AS semister,
    vw_accounts.accounts_class_id,
    vw_accounts.chat_type_id,
    vw_accounts.chat_type_name,
    vw_accounts.accounts_class_name,
    vw_accounts.account_type_id,
    vw_accounts.account_type_name,
    vw_accounts.account_id,
    vw_accounts.account_name,
    vw_accounts.is_header,
    vw_accounts.is_active,
    vw_items.item_id,
    vw_items.item_name,
    vw_items.tax_type_id,
    vw_items.tax_account_id,
    vw_items.tax_type_name,
    vw_items.tax_rate,
    vw_items.tax_inclusive,
    vw_items.sales_account_id,
    vw_items.purchase_account_id,
    budget_lines.budget_line_id,
    budget_lines.org_id,
    budget_lines.transaction_id,
    budget_lines.spend_type,
    budget_lines.quantity,
    budget_lines.amount,
    budget_lines.tax_amount,
    budget_lines.narrative,
    budget_lines.details,
        CASE
            WHEN (budget_lines.spend_type = 1) THEN 'Monthly'::text
            WHEN (budget_lines.spend_type = 2) THEN 'Quaterly'::text
            ELSE 'Once'::text
        END AS spend_type_name,
    budget_lines.income_budget,
        CASE
            WHEN (budget_lines.income_budget = true) THEN 'Income Budget'::text
            ELSE 'Expenditure Budget'::text
        END AS income_expense,
        CASE
            WHEN (budget_lines.income_budget = true) THEN budget_lines.amount
            ELSE (0)::real
        END AS dr_budget,
        CASE
            WHEN (budget_lines.income_budget = false) THEN budget_lines.amount
            ELSE (0)::real
        END AS cr_budget
   FROM ((((budget_lines
     JOIN vw_budgets ON ((budget_lines.budget_id = vw_budgets.budget_id)))
     JOIN periods ON ((budget_lines.period_id = periods.period_id)))
     JOIN vw_accounts ON ((budget_lines.account_id = vw_accounts.account_id)))
     LEFT JOIN vw_items ON ((budget_lines.item_id = vw_items.item_id)));


ALTER TABLE public.vw_budget_lines OWNER TO postgres;

--
-- Name: vw_budget_ads; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_budget_ads AS
 SELECT vw_budget_lines.department_id,
    vw_budget_lines.department_name,
    vw_budget_lines.fiscal_year_id,
    vw_budget_lines.fiscal_year_start,
    vw_budget_lines.fiscal_year_end,
    vw_budget_lines.year_opened,
    vw_budget_lines.year_closed,
    vw_budget_lines.budget_type,
    vw_budget_lines.accounts_class_id,
    vw_budget_lines.chat_type_id,
    vw_budget_lines.chat_type_name,
    vw_budget_lines.accounts_class_name,
    vw_budget_lines.account_type_id,
    vw_budget_lines.account_type_name,
    vw_budget_lines.account_id,
    vw_budget_lines.account_name,
    vw_budget_lines.is_header,
    vw_budget_lines.is_active,
    vw_budget_lines.item_id,
    vw_budget_lines.item_name,
    vw_budget_lines.tax_type_id,
    vw_budget_lines.tax_account_id,
    vw_budget_lines.org_id,
    vw_budget_lines.spend_type,
    vw_budget_lines.spend_type_name,
    vw_budget_lines.income_budget,
    vw_budget_lines.income_expense,
    sum(vw_budget_lines.quantity) AS s_quantity,
    sum(vw_budget_lines.amount) AS s_amount,
    sum(vw_budget_lines.tax_amount) AS s_tax_amount,
    sum(vw_budget_lines.dr_budget) AS s_dr_budget,
    sum(vw_budget_lines.cr_budget) AS s_cr_budget,
    sum((vw_budget_lines.dr_budget - vw_budget_lines.cr_budget)) AS budget_diff
   FROM vw_budget_lines
  WHERE ((vw_budget_lines.approve_status)::text = 'Approved'::text)
  GROUP BY vw_budget_lines.department_id, vw_budget_lines.department_name, vw_budget_lines.fiscal_year_id, vw_budget_lines.fiscal_year_start, vw_budget_lines.fiscal_year_end, vw_budget_lines.year_opened, vw_budget_lines.year_closed, vw_budget_lines.budget_type, vw_budget_lines.accounts_class_id, vw_budget_lines.chat_type_id, vw_budget_lines.chat_type_name, vw_budget_lines.accounts_class_name, vw_budget_lines.account_type_id, vw_budget_lines.account_type_name, vw_budget_lines.account_id, vw_budget_lines.account_name, vw_budget_lines.is_header, vw_budget_lines.is_active, vw_budget_lines.item_id, vw_budget_lines.item_name, vw_budget_lines.tax_type_id, vw_budget_lines.tax_account_id, vw_budget_lines.org_id, vw_budget_lines.spend_type, vw_budget_lines.spend_type_name, vw_budget_lines.income_budget, vw_budget_lines.income_expense;


ALTER TABLE public.vw_budget_ads OWNER TO postgres;

--
-- Name: vw_budget_ledger; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_budget_ledger AS
 SELECT journals.org_id,
    periods.fiscal_year_id,
    journals.department_id,
    gls.account_id,
    sum((journals.exchange_rate * gls.debit)) AS bl_debit,
    sum((journals.exchange_rate * gls.credit)) AS bl_credit,
    sum((journals.exchange_rate * (gls.debit - gls.credit))) AS bl_diff
   FROM ((journals
     JOIN gls ON ((journals.journal_id = gls.journal_id)))
     JOIN periods ON ((journals.period_id = periods.period_id)))
  WHERE (journals.posted = true)
  GROUP BY journals.org_id, periods.fiscal_year_id, journals.department_id, gls.account_id;


ALTER TABLE public.vw_budget_ledger OWNER TO postgres;

--
-- Name: vw_budget_pdc; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_budget_pdc AS
 SELECT vw_budget_ads.department_id,
    vw_budget_ads.department_name,
    vw_budget_ads.fiscal_year_id,
    vw_budget_ads.fiscal_year_start,
    vw_budget_ads.fiscal_year_end,
    vw_budget_ads.year_opened,
    vw_budget_ads.year_closed,
    vw_budget_ads.budget_type,
    vw_budget_ads.accounts_class_id,
    vw_budget_ads.chat_type_id,
    vw_budget_ads.chat_type_name,
    vw_budget_ads.accounts_class_name,
    vw_budget_ads.account_type_id,
    vw_budget_ads.account_type_name,
    vw_budget_ads.account_id,
    vw_budget_ads.account_name,
    vw_budget_ads.is_header,
    vw_budget_ads.is_active,
    vw_budget_ads.item_id,
    vw_budget_ads.item_name,
    vw_budget_ads.tax_type_id,
    vw_budget_ads.tax_account_id,
    vw_budget_ads.org_id,
    vw_budget_ads.spend_type,
    vw_budget_ads.spend_type_name,
    vw_budget_ads.income_budget,
    vw_budget_ads.income_expense,
    vw_budget_ads.s_quantity,
    vw_budget_ads.s_amount,
    vw_budget_ads.s_tax_amount,
    vw_budget_ads.s_dr_budget,
    vw_budget_ads.s_cr_budget,
    vw_budget_ledger.bl_debit,
    vw_budget_ledger.bl_credit,
        CASE
            WHEN (vw_budget_ads.income_budget = true) THEN COALESCE((((-1))::double precision * vw_budget_ledger.bl_diff), (0)::double precision)
            ELSE (COALESCE(vw_budget_ledger.bl_diff, (0)::real))::double precision
        END AS amount_used,
        CASE
            WHEN (vw_budget_ads.income_budget = true) THEN (vw_budget_ads.s_amount + COALESCE(vw_budget_ledger.bl_diff, (0)::real))
            ELSE (vw_budget_ads.s_amount - COALESCE(vw_budget_ledger.bl_diff, (0)::real))
        END AS budget_balance
   FROM (vw_budget_ads
     LEFT JOIN vw_budget_ledger ON ((((vw_budget_ads.department_id = vw_budget_ledger.department_id) AND (vw_budget_ads.account_id = vw_budget_ledger.account_id)) AND ((vw_budget_ads.fiscal_year_id)::text = (vw_budget_ledger.fiscal_year_id)::text))));


ALTER TABLE public.vw_budget_pdc OWNER TO postgres;

--
-- Name: vw_budget_pds; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_budget_pds AS
 SELECT vw_budget_lines.department_id,
    vw_budget_lines.department_name,
    vw_budget_lines.fiscal_year_id,
    vw_budget_lines.fiscal_year_start,
    vw_budget_lines.fiscal_year_end,
    vw_budget_lines.year_opened,
    vw_budget_lines.year_closed,
    vw_budget_lines.period_id,
    vw_budget_lines.start_date,
    vw_budget_lines.end_date,
    vw_budget_lines.opened,
    vw_budget_lines.closed,
    vw_budget_lines.month_id,
    vw_budget_lines.period_year,
    vw_budget_lines.period_month,
    vw_budget_lines.quarter,
    vw_budget_lines.semister,
    vw_budget_lines.budget_type,
    vw_budget_lines.accounts_class_id,
    vw_budget_lines.chat_type_id,
    vw_budget_lines.chat_type_name,
    vw_budget_lines.accounts_class_name,
    vw_budget_lines.account_type_id,
    vw_budget_lines.account_type_name,
    vw_budget_lines.account_id,
    vw_budget_lines.account_name,
    vw_budget_lines.is_header,
    vw_budget_lines.is_active,
    vw_budget_lines.item_id,
    vw_budget_lines.item_name,
    vw_budget_lines.tax_type_id,
    vw_budget_lines.tax_account_id,
    vw_budget_lines.tax_type_name,
    vw_budget_lines.tax_rate,
    vw_budget_lines.tax_inclusive,
    vw_budget_lines.sales_account_id,
    vw_budget_lines.purchase_account_id,
    vw_budget_lines.budget_line_id,
    vw_budget_lines.org_id,
    vw_budget_lines.transaction_id,
    vw_budget_lines.spend_type,
    vw_budget_lines.spend_type_name,
    vw_budget_lines.income_budget,
    vw_budget_lines.income_expense,
    sum(vw_budget_lines.quantity) AS s_quantity,
    sum(vw_budget_lines.amount) AS s_amount,
    sum(vw_budget_lines.tax_amount) AS s_tax_amount,
    sum(vw_budget_lines.dr_budget) AS s_dr_budget,
    sum(vw_budget_lines.cr_budget) AS s_cr_budget,
    sum((vw_budget_lines.dr_budget - vw_budget_lines.cr_budget)) AS budget_diff
   FROM vw_budget_lines
  WHERE ((vw_budget_lines.approve_status)::text = 'Approved'::text)
  GROUP BY vw_budget_lines.department_id, vw_budget_lines.department_name, vw_budget_lines.fiscal_year_id, vw_budget_lines.fiscal_year_start, vw_budget_lines.fiscal_year_end, vw_budget_lines.year_opened, vw_budget_lines.year_closed, vw_budget_lines.period_id, vw_budget_lines.start_date, vw_budget_lines.end_date, vw_budget_lines.opened, vw_budget_lines.closed, vw_budget_lines.month_id, vw_budget_lines.period_year, vw_budget_lines.period_month, vw_budget_lines.quarter, vw_budget_lines.semister, vw_budget_lines.budget_type, vw_budget_lines.accounts_class_id, vw_budget_lines.chat_type_id, vw_budget_lines.chat_type_name, vw_budget_lines.accounts_class_name, vw_budget_lines.account_type_id, vw_budget_lines.account_type_name, vw_budget_lines.account_id, vw_budget_lines.account_name, vw_budget_lines.is_header, vw_budget_lines.is_active, vw_budget_lines.item_id, vw_budget_lines.item_name, vw_budget_lines.tax_type_id, vw_budget_lines.tax_account_id, vw_budget_lines.tax_type_name, vw_budget_lines.tax_rate, vw_budget_lines.tax_inclusive, vw_budget_lines.sales_account_id, vw_budget_lines.purchase_account_id, vw_budget_lines.budget_line_id, vw_budget_lines.org_id, vw_budget_lines.transaction_id, vw_budget_lines.spend_type, vw_budget_lines.spend_type_name, vw_budget_lines.income_budget, vw_budget_lines.income_expense;


ALTER TABLE public.vw_budget_pds OWNER TO postgres;

--
-- Name: vw_job_reviews; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_job_reviews AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    job_reviews.job_review_id,
    job_reviews.total_points,
    job_reviews.org_id,
    job_reviews.review_date,
    job_reviews.review_done,
    job_reviews.approve_status,
    job_reviews.workflow_table_id,
    job_reviews.application_date,
    job_reviews.action_date,
    job_reviews.recomendation,
    job_reviews.reviewer_comments,
    job_reviews.pl_comments,
    job_reviews.details,
    date_part('year'::text, job_reviews.review_date) AS review_year
   FROM (job_reviews
     JOIN entitys ON ((job_reviews.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_job_reviews OWNER TO postgres;

--
-- Name: vw_career_development; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_career_development AS
 SELECT vw_job_reviews.entity_id,
    vw_job_reviews.entity_name,
    vw_job_reviews.job_review_id,
    vw_job_reviews.total_points,
    vw_job_reviews.review_date,
    vw_job_reviews.review_done,
    vw_job_reviews.recomendation,
    vw_job_reviews.reviewer_comments,
    vw_job_reviews.pl_comments,
    vw_job_reviews.approve_status,
    vw_job_reviews.workflow_table_id,
    vw_job_reviews.application_date,
    vw_job_reviews.action_date,
    career_development.career_development_id,
    career_development.career_development_name,
    career_development.details AS career_development_details,
    evaluation_points.org_id,
    evaluation_points.evaluation_point_id,
    evaluation_points.points,
    evaluation_points.reviewer_points,
    evaluation_points.reviewer_narrative,
    evaluation_points.narrative,
    evaluation_points.details
   FROM ((evaluation_points
     JOIN vw_job_reviews ON ((evaluation_points.job_review_id = vw_job_reviews.job_review_id)))
     JOIN career_development ON ((evaluation_points.career_development_id = career_development.career_development_id)));


ALTER TABLE public.vw_career_development OWNER TO postgres;

--
-- Name: vw_casual_application; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_casual_application AS
 SELECT casual_category.casual_category_id,
    casual_category.casual_category_name,
    departments.department_id,
    departments.department_name,
    casual_application.casual_application_id,
    casual_application."position",
    casual_application.org_id,
    casual_application.application_date,
    casual_application.approved_pay_rate,
    casual_application.approve_status,
    casual_application.action_date,
    casual_application.work_duration,
    casual_application.details
   FROM ((casual_application
     JOIN casual_category ON ((casual_application.casual_category_id = casual_category.casual_category_id)))
     JOIN departments ON ((casual_application.department_id = departments.department_id)));


ALTER TABLE public.vw_casual_application OWNER TO postgres;

--
-- Name: vw_casuals; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_casuals AS
 SELECT vw_casual_application.casual_category_id,
    vw_casual_application.casual_category_name,
    vw_casual_application.department_id,
    vw_casual_application.department_name,
    vw_casual_application.casual_application_id,
    vw_casual_application."position",
    vw_casual_application.application_date,
    vw_casual_application.approved_pay_rate,
    vw_casual_application.approve_status AS application_approve_status,
    vw_casual_application.action_date AS application_action_date,
    vw_casual_application.work_duration,
    entitys.entity_id,
    entitys.entity_name,
    casuals.org_id,
    casuals.casual_id,
    casuals.start_date,
    casuals.end_date,
    casuals.duration,
    casuals.pay_rate,
    casuals.amount_paid,
    casuals.approve_status,
    casuals.action_date,
    casuals.paid,
    casuals.details
   FROM ((casuals
     JOIN vw_casual_application ON ((casuals.casual_application_id = vw_casual_application.casual_application_id)))
     JOIN entitys ON ((casuals.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_casuals OWNER TO postgres;

--
-- Name: vw_claims; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_claims AS
 SELECT claim_types.claim_type_id,
    claim_types.claim_type_name,
    entitys.entity_id,
    entitys.entity_name,
    claims.org_id,
    claims.claim_id,
    claims.claim_date,
    claims.narrative,
    claims.in_payroll,
    claims.application_date,
    claims.approve_status,
    claims.workflow_table_id,
    claims.action_date,
    claims.details
   FROM ((claims
     JOIN claim_types ON ((claims.claim_type_id = claim_types.claim_type_id)))
     JOIN entitys ON ((claims.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_claims OWNER TO postgres;

--
-- Name: vw_claim_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_claim_details AS
 SELECT vw_claims.claim_type_id,
    vw_claims.claim_type_name,
    vw_claims.entity_id,
    vw_claims.entity_name,
    vw_claims.claim_id,
    vw_claims.claim_date,
    vw_claims.narrative,
    vw_claims.application_date,
    vw_claims.approve_status,
    vw_claims.workflow_table_id,
    vw_claims.action_date,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    claim_details.org_id,
    claim_details.claim_detail_id,
    claim_details.nature_of_expence,
    claim_details.receipt_number,
    claim_details.amount,
    claim_details.exchange_rate,
    claim_details.expense_code,
    claim_details.details
   FROM ((claim_details
     JOIN vw_claims ON ((claim_details.claim_id = vw_claims.claim_id)))
     JOIN currency ON ((claim_details.currency_id = currency.currency_id)));


ALTER TABLE public.vw_claim_details OWNER TO postgres;

--
-- Name: vw_claim_types; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_claim_types AS
 SELECT adjustments.adjustment_id,
    adjustments.adjustment_name,
    claim_types.org_id,
    claim_types.claim_type_id,
    claim_types.claim_type_name,
    claim_types.details
   FROM (claim_types
     JOIN adjustments ON ((claim_types.adjustment_id = adjustments.adjustment_id)));


ALTER TABLE public.vw_claim_types OWNER TO postgres;

--
-- Name: vw_contracting; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_contracting AS
 SELECT vw_intake.department_id,
    vw_intake.department_name,
    vw_intake.department_description,
    vw_intake.department_duties,
    vw_intake.department_role_id,
    vw_intake.department_role_name,
    vw_intake.job_description,
    vw_intake.job_requirements,
    vw_intake.duties,
    vw_intake.performance_measures,
    vw_intake.intake_id,
    vw_intake.opening_date,
    vw_intake.closing_date,
    vw_intake.positions,
    entitys.entity_id,
    entitys.entity_name,
    contract_types.contract_type_id,
    contract_types.contract_type_name,
    contract_status.contract_status_id,
    contract_status.contract_status_name,
    applications.application_id,
    applications.employee_id,
    applications.contract_date,
    applications.contract_close,
    applications.contract_start,
    applications.contract_period,
    applications.contract_terms,
    applications.initial_salary,
    applications.application_date,
    applications.approve_status,
    applications.workflow_table_id,
    applications.action_date,
    applications.applicant_comments,
    applications.review,
    applications.org_id,
    vw_education_max.education_class_name,
    vw_education_max.date_from,
    vw_education_max.date_to,
    vw_education_max.name_of_school,
    vw_education_max.examination_taken,
    vw_education_max.grades_obtained,
    vw_education_max.certificate_number,
    vw_employment_max.employment_id,
    vw_employment_max.employers_name,
    vw_employment_max.position_held,
    vw_employment_max.date_from AS emp_date_from,
    vw_employment_max.date_to AS emp_date_to,
    vw_employment_max.employment_duration,
    vw_employment_max.employment_experince,
    round(((date_part('year'::text, vw_employment_max.employment_duration) + (date_part('month'::text, vw_employment_max.employment_duration) / (12)::double precision)))::numeric, 1) AS emp_duration,
    round(((date_part('year'::text, vw_employment_max.employment_experince) + (date_part('month'::text, vw_employment_max.employment_experince) / (12)::double precision)))::numeric, 1) AS emp_experince
   FROM ((((((applications
     JOIN entitys ON ((applications.employee_id = entitys.entity_id)))
     LEFT JOIN vw_intake ON ((applications.intake_id = vw_intake.intake_id)))
     LEFT JOIN contract_types ON ((applications.contract_type_id = contract_types.contract_type_id)))
     LEFT JOIN contract_status ON ((applications.contract_status_id = contract_status.contract_status_id)))
     LEFT JOIN vw_education_max ON ((entitys.entity_id = vw_education_max.entity_id)))
     LEFT JOIN vw_employment_max ON ((entitys.entity_id = vw_employment_max.entity_id)));


ALTER TABLE public.vw_contracting OWNER TO postgres;

--
-- Name: vw_curr_orgs; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_curr_orgs AS
 SELECT currency.currency_id AS base_currency_id,
    currency.currency_name AS base_currency_name,
    currency.currency_symbol AS base_currency_symbol,
    orgs.org_id,
    orgs.org_name,
    orgs.is_default,
    orgs.is_active,
    orgs.logo,
    orgs.cert_number,
    orgs.pin,
    orgs.vat_number,
    orgs.invoice_footer,
    orgs.details
   FROM (orgs
     JOIN currency ON ((orgs.currency_id = currency.currency_id)));


ALTER TABLE public.vw_curr_orgs OWNER TO postgres;

--
-- Name: vw_cv_projects; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_cv_projects AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    cv_projects.cv_projectid,
    cv_projects.cv_project_name,
    cv_projects.org_id,
    cv_projects.cv_project_date,
    cv_projects.details
   FROM (cv_projects
     JOIN entitys ON ((cv_projects.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_cv_projects OWNER TO postgres;

--
-- Name: vw_cv_seminars; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_cv_seminars AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    cv_seminars.cv_seminar_id,
    cv_seminars.cv_seminar_name,
    cv_seminars.org_id,
    cv_seminars.cv_seminar_date,
    cv_seminars.details
   FROM (cv_seminars
     JOIN entitys ON ((cv_seminars.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_cv_seminars OWNER TO postgres;

--
-- Name: vw_day_ledgers; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_day_ledgers AS
 SELECT currency.currency_id,
    currency.currency_name,
    departments.department_id,
    departments.department_name,
    entitys.entity_id,
    entitys.entity_name,
    items.item_id,
    items.item_name,
    orgs.org_id,
    orgs.org_name,
    transaction_status.transaction_status_id,
    transaction_status.transaction_status_name,
    transaction_types.transaction_type_id,
    transaction_types.transaction_type_name,
    vw_bank_accounts.bank_id,
    vw_bank_accounts.bank_name,
    vw_bank_accounts.bank_branch_name,
    vw_bank_accounts.account_id AS gl_bank_account_id,
    vw_bank_accounts.bank_account_id,
    vw_bank_accounts.bank_account_name,
    vw_bank_accounts.bank_account_number,
    stores.store_id,
    stores.store_name,
    day_ledgers.journal_id,
    day_ledgers.day_ledger_id,
    day_ledgers.exchange_rate,
    day_ledgers.day_ledger_date,
    day_ledgers.day_ledger_quantity,
    day_ledgers.day_ledger_amount,
    day_ledgers.day_ledger_tax_amount,
    day_ledgers.document_number,
    day_ledgers.payment_number,
    day_ledgers.order_number,
    day_ledgers.payment_terms,
    day_ledgers.job,
    day_ledgers.application_date,
    day_ledgers.approve_status,
    day_ledgers.workflow_table_id,
    day_ledgers.action_date,
    day_ledgers.narrative,
    day_ledgers.details
   FROM (((((((((day_ledgers
     JOIN currency ON ((day_ledgers.currency_id = currency.currency_id)))
     JOIN departments ON ((day_ledgers.department_id = departments.department_id)))
     JOIN entitys ON ((day_ledgers.entity_id = entitys.entity_id)))
     JOIN items ON ((day_ledgers.item_id = items.item_id)))
     JOIN orgs ON ((day_ledgers.org_id = orgs.org_id)))
     JOIN transaction_status ON ((day_ledgers.transaction_status_id = transaction_status.transaction_status_id)))
     JOIN transaction_types ON ((day_ledgers.transaction_type_id = transaction_types.transaction_type_id)))
     JOIN vw_bank_accounts ON ((day_ledgers.bank_account_id = vw_bank_accounts.bank_account_id)))
     LEFT JOIN stores ON ((day_ledgers.store_id = stores.store_id)));


ALTER TABLE public.vw_day_ledgers OWNER TO postgres;

--
-- Name: vw_default_accounts; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_default_accounts AS
 SELECT vw_accounts.accounts_class_id,
    vw_accounts.chat_type_id,
    vw_accounts.chat_type_name,
    vw_accounts.accounts_class_name,
    vw_accounts.account_type_id,
    vw_accounts.account_type_name,
    vw_accounts.account_id,
    vw_accounts.account_name,
    vw_accounts.is_header,
    vw_accounts.is_active,
    default_accounts.default_account_id,
    default_accounts.org_id,
    default_accounts.narrative
   FROM (vw_accounts
     JOIN default_accounts ON ((vw_accounts.account_id = default_accounts.account_id)));


ALTER TABLE public.vw_default_accounts OWNER TO postgres;

--
-- Name: vw_default_adjustments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_default_adjustments AS
 SELECT vw_adjustments.adjustment_id,
    vw_adjustments.adjustment_name,
    vw_adjustments.adjustment_type,
    vw_adjustments.currency_id,
    vw_adjustments.currency_name,
    vw_adjustments.currency_symbol,
    entitys.entity_id,
    entitys.entity_name,
    default_adjustments.org_id,
    default_adjustments.default_adjustment_id,
    default_adjustments.amount,
    default_adjustments.active,
    default_adjustments.final_date,
    default_adjustments.narrative
   FROM ((default_adjustments
     JOIN vw_adjustments ON ((default_adjustments.adjustment_id = vw_adjustments.adjustment_id)))
     JOIN entitys ON ((default_adjustments.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_default_adjustments OWNER TO postgres;

--
-- Name: vw_default_banking; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_default_banking AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    vw_bank_branch.bank_id,
    vw_bank_branch.bank_name,
    vw_bank_branch.bank_branch_id,
    vw_bank_branch.bank_branch_name,
    vw_bank_branch.bank_branch_code,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    default_banking.org_id,
    default_banking.default_banking_id,
    default_banking.amount,
    default_banking.ps_amount,
    default_banking.final_date,
    default_banking.active,
    default_banking.narrative
   FROM (((default_banking
     JOIN entitys ON ((default_banking.entity_id = entitys.entity_id)))
     JOIN vw_bank_branch ON ((default_banking.bank_branch_id = vw_bank_branch.bank_branch_id)))
     JOIN currency ON ((default_banking.currency_id = currency.currency_id)));


ALTER TABLE public.vw_default_banking OWNER TO postgres;

--
-- Name: vw_tax_types; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_tax_types AS
 SELECT vw_accounts.account_type_id,
    vw_accounts.account_type_name,
    vw_accounts.account_id,
    vw_accounts.account_name,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    tax_types.org_id,
    tax_types.tax_type_id,
    tax_types.tax_type_name,
    tax_types.formural,
    tax_types.tax_relief,
    tax_types.tax_type_order,
    tax_types.in_tax,
    tax_types.tax_rate,
    tax_types.tax_inclusive,
    tax_types.linear,
    tax_types.percentage,
    tax_types.employer,
    tax_types.employer_ps,
    tax_types.account_number,
    tax_types.active,
    tax_types.use_key,
    tax_types.details
   FROM ((tax_types
     JOIN currency ON ((tax_types.currency_id = currency.currency_id)))
     LEFT JOIN vw_accounts ON ((tax_types.account_id = vw_accounts.account_id)));


ALTER TABLE public.vw_tax_types OWNER TO postgres;

--
-- Name: vw_default_tax_types; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_default_tax_types AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    vw_tax_types.tax_type_id,
    vw_tax_types.tax_type_name,
    vw_tax_types.currency_id,
    vw_tax_types.currency_name,
    vw_tax_types.currency_symbol,
    default_tax_types.default_tax_type_id,
    default_tax_types.org_id,
    default_tax_types.tax_identification,
    default_tax_types.active,
    default_tax_types.narrative
   FROM ((default_tax_types
     JOIN entitys ON ((default_tax_types.entity_id = entitys.entity_id)))
     JOIN vw_tax_types ON ((default_tax_types.tax_type_id = vw_tax_types.tax_type_id)));


ALTER TABLE public.vw_default_tax_types OWNER TO postgres;

--
-- Name: vw_define_phases; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_define_phases AS
 SELECT entity_types.entity_type_id,
    entity_types.entity_type_name,
    project_types.project_type_id,
    project_types.project_type_name,
    define_phases.define_phase_id,
    define_phases.define_phase_name,
    define_phases.org_id,
    define_phases.define_phase_time,
    define_phases.define_phase_cost,
    define_phases.phase_order,
    define_phases.details
   FROM ((define_phases
     JOIN entity_types ON ((define_phases.entity_type_id = entity_types.entity_type_id)))
     JOIN project_types ON ((define_phases.project_type_id = project_types.project_type_id)));


ALTER TABLE public.vw_define_phases OWNER TO postgres;

--
-- Name: vw_define_tasks; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_define_tasks AS
 SELECT vw_define_phases.entity_type_id,
    vw_define_phases.entity_type_name,
    vw_define_phases.project_type_id,
    vw_define_phases.project_type_name,
    vw_define_phases.define_phase_id,
    vw_define_phases.define_phase_name,
    vw_define_phases.define_phase_time,
    vw_define_phases.define_phase_cost,
    define_tasks.org_id,
    define_tasks.define_task_id,
    define_tasks.define_task_name,
    define_tasks.narrative,
    define_tasks.details
   FROM (define_tasks
     JOIN vw_define_phases ON ((define_tasks.define_phase_id = vw_define_phases.define_phase_id)));


ALTER TABLE public.vw_define_tasks OWNER TO postgres;

--
-- Name: vw_departments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_departments AS
 SELECT departments.ln_department_id,
    p_departments.department_name AS ln_department_name,
    departments.department_id,
    departments.org_id,
    departments.department_name,
    departments.active,
    departments.description,
    departments.duties,
    departments.reports,
    departments.details
   FROM (departments
     LEFT JOIN departments p_departments ON ((departments.ln_department_id = p_departments.department_id)));


ALTER TABLE public.vw_departments OWNER TO postgres;

--
-- Name: vw_education; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_education AS
 SELECT education_class.education_class_id,
    education_class.education_class_name,
    entitys.entity_id,
    entitys.entity_name,
    education.org_id,
    education.education_id,
    education.date_from,
    education.date_to,
    education.name_of_school,
    education.examination_taken,
    education.grades_obtained,
    education.certificate_number,
    education.details
   FROM ((education
     JOIN education_class ON ((education.education_class_id = education_class.education_class_id)))
     JOIN entitys ON ((education.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_education OWNER TO postgres;

--
-- Name: vw_employee_adjustments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_adjustments AS
 SELECT vw_employee_month.employee_month_id,
    vw_employee_month.period_id,
    vw_employee_month.start_date,
    vw_employee_month.month_id,
    vw_employee_month.period_year,
    vw_employee_month.period_month,
    vw_employee_month.end_date,
    vw_employee_month.entity_id,
    vw_employee_month.entity_name,
    vw_employee_month.employee_id,
    adjustments.adjustment_id,
    adjustments.adjustment_name,
    adjustments.adjustment_type,
    adjustments.account_number,
    adjustments.earning_code,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    employee_adjustments.org_id,
    employee_adjustments.employee_adjustment_id,
    employee_adjustments.pay_date,
    employee_adjustments.amount,
    employee_adjustments.in_payroll,
    employee_adjustments.in_tax,
    employee_adjustments.visible,
    employee_adjustments.exchange_rate,
    employee_adjustments.paid_amount,
    employee_adjustments.balance,
    employee_adjustments.narrative,
    employee_adjustments.tax_relief_amount,
    (employee_adjustments.exchange_rate * employee_adjustments.amount) AS base_amount
   FROM (((employee_adjustments
     JOIN adjustments ON ((employee_adjustments.adjustment_id = adjustments.adjustment_id)))
     JOIN vw_employee_month ON ((employee_adjustments.employee_month_id = vw_employee_month.employee_month_id)))
     JOIN currency ON ((adjustments.currency_id = currency.currency_id)));


ALTER TABLE public.vw_employee_adjustments OWNER TO postgres;

--
-- Name: vw_employee_advances; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_advances AS
 SELECT vw_employee_month.employee_month_id,
    vw_employee_month.period_id,
    vw_employee_month.start_date,
    vw_employee_month.month_id,
    vw_employee_month.period_year,
    vw_employee_month.period_month,
    vw_employee_month.entity_id,
    vw_employee_month.entity_name,
    vw_employee_month.employee_id,
    employee_advances.org_id,
    employee_advances.employee_advance_id,
    employee_advances.pay_date,
    employee_advances.pay_period,
    employee_advances.pay_upto,
    employee_advances.amount,
    employee_advances.in_payroll,
    employee_advances.completed,
    employee_advances.approve_status,
    employee_advances.action_date,
    employee_advances.narrative
   FROM (employee_advances
     JOIN vw_employee_month ON ((employee_advances.employee_month_id = vw_employee_month.employee_month_id)));


ALTER TABLE public.vw_employee_advances OWNER TO postgres;

--
-- Name: vw_employee_banking; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_banking AS
 SELECT vw_employee_month.employee_month_id,
    vw_employee_month.period_id,
    vw_employee_month.start_date,
    vw_employee_month.month_id,
    vw_employee_month.period_year,
    vw_employee_month.period_month,
    vw_employee_month.entity_id,
    vw_employee_month.entity_name,
    vw_employee_month.employee_id,
    vw_bank_branch.bank_id,
    vw_bank_branch.bank_name,
    vw_bank_branch.bank_branch_id,
    vw_bank_branch.bank_branch_name,
    vw_bank_branch.bank_branch_code,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    employee_banking.org_id,
    employee_banking.default_banking_id,
    employee_banking.amount,
    employee_banking.exchange_rate,
    employee_banking.active,
    employee_banking.narrative,
    (employee_banking.exchange_rate * employee_banking.amount) AS base_amount
   FROM (((employee_banking
     JOIN vw_employee_month ON ((employee_banking.employee_month_id = vw_employee_month.employee_month_id)))
     JOIN vw_bank_branch ON ((employee_banking.bank_branch_id = vw_bank_branch.bank_branch_id)))
     JOIN currency ON ((employee_banking.currency_id = currency.currency_id)));


ALTER TABLE public.vw_employee_banking OWNER TO postgres;

--
-- Name: vw_employee_cases; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_cases AS
 SELECT case_types.case_type_id,
    case_types.case_type_name,
    entitys.entity_id,
    entitys.entity_name,
    employee_cases.org_id,
    employee_cases.employee_case_id,
    employee_cases.narrative,
    employee_cases.case_date,
    employee_cases.complaint,
    employee_cases.case_action,
    employee_cases.completed,
    employee_cases.details
   FROM ((employee_cases
     JOIN case_types ON ((employee_cases.case_type_id = case_types.case_type_id)))
     JOIN entitys ON ((employee_cases.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_employee_cases OWNER TO postgres;

--
-- Name: vw_employee_leave; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_leave AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    leave_types.leave_type_id,
    leave_types.leave_type_name,
    contact_entity.entity_name AS contact_name,
    employee_leave.org_id,
    employee_leave.employee_leave_id,
    employee_leave.leave_from,
    employee_leave.leave_to,
    employee_leave.start_half_day,
    employee_leave.end_half_day,
    employee_leave.approve_status,
    employee_leave.action_date,
    employee_leave.workflow_table_id,
    employee_leave.completed,
    employee_leave.leave_days,
    employee_leave.narrative,
    employee_leave.details,
    employee_leave.special_request,
        CASE
            WHEN (employee_leave.start_half_day = true) THEN '14:00:00'::time without time zone
            ELSE '08:00:00'::time without time zone
        END AS activity_time,
        CASE
            WHEN (employee_leave.end_half_day = true) THEN '14:00:00'::time without time zone
            ELSE '17:00:00'::time without time zone
        END AS finish_time,
    date_part('month'::text, employee_leave.leave_from) AS leave_month,
    to_char((employee_leave.leave_from)::timestamp with time zone, 'YYYY'::text) AS leave_year
   FROM (((employee_leave
     JOIN entitys ON ((employee_leave.entity_id = entitys.entity_id)))
     JOIN leave_types ON ((employee_leave.leave_type_id = leave_types.leave_type_id)))
     LEFT JOIN entitys contact_entity ON ((employee_leave.contact_entity_id = contact_entity.entity_id)));


ALTER TABLE public.vw_employee_leave OWNER TO postgres;

--
-- Name: vw_employee_leave_types; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_leave_types AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    leave_types.leave_type_id,
    leave_types.leave_type_name,
    leave_types.allowed_leave_days,
    leave_types.leave_days_span,
    leave_types.use_type,
    leave_types.month_quota,
    leave_types.initial_days,
    leave_types.maximum_carry,
    leave_types.include_holiday,
    employee_leave_types.org_id,
    employee_leave_types.employee_leave_type_id,
    employee_leave_types.leave_balance,
    employee_leave_types.leave_starting,
    employee_leave_types.details
   FROM ((employee_leave_types
     JOIN entitys ON ((employee_leave_types.entity_id = entitys.entity_id)))
     JOIN leave_types ON ((employee_leave_types.leave_type_id = leave_types.leave_type_id)));


ALTER TABLE public.vw_employee_leave_types OWNER TO postgres;

--
-- Name: vw_employee_objectives; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_objectives AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    employee_objectives.org_id,
    employee_objectives.employee_objective_id,
    employee_objectives.employee_objective_name,
    employee_objectives.objective_date,
    employee_objectives.approve_status,
    employee_objectives.workflow_table_id,
    employee_objectives.application_date,
    employee_objectives.action_date,
    employee_objectives.supervisor_comments,
    employee_objectives.details,
    date_part('year'::text, employee_objectives.objective_date) AS objective_year
   FROM (employee_objectives
     JOIN entitys ON ((employee_objectives.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_employee_objectives OWNER TO postgres;

--
-- Name: vw_employee_overtime; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_overtime AS
 SELECT vw_employee_month.employee_month_id,
    vw_employee_month.period_id,
    vw_employee_month.start_date,
    vw_employee_month.month_id,
    vw_employee_month.period_year,
    vw_employee_month.period_month,
    vw_employee_month.entity_id,
    vw_employee_month.entity_name,
    vw_employee_month.employee_id,
    employee_overtime.org_id,
    employee_overtime.employee_overtime_id,
    employee_overtime.overtime_date,
    employee_overtime.overtime,
    employee_overtime.overtime_rate,
    employee_overtime.narrative,
    employee_overtime.approve_status,
    employee_overtime.action_date,
    employee_overtime.details
   FROM (employee_overtime
     JOIN vw_employee_month ON ((employee_overtime.employee_month_id = vw_employee_month.employee_month_id)));


ALTER TABLE public.vw_employee_overtime OWNER TO postgres;

--
-- Name: vw_employee_per_diem; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_per_diem AS
 SELECT vw_employee_month.employee_month_id,
    vw_employee_month.period_id,
    vw_employee_month.start_date,
    vw_employee_month.month_id,
    vw_employee_month.period_year,
    vw_employee_month.period_month,
    vw_employee_month.entity_id,
    vw_employee_month.entity_name,
    vw_employee_month.employee_id,
    employee_per_diem.org_id,
    employee_per_diem.employee_per_diem_id,
    employee_per_diem.travel_date,
    employee_per_diem.return_date,
    employee_per_diem.days_travelled,
    employee_per_diem.per_diem,
    employee_per_diem.cash_paid,
    employee_per_diem.tax_amount,
    employee_per_diem.full_amount,
    employee_per_diem.travel_to,
    employee_per_diem.approve_status,
    employee_per_diem.action_date,
    employee_per_diem.completed,
    employee_per_diem.post_account,
    employee_per_diem.details,
    (employee_per_diem.exchange_rate * employee_per_diem.tax_amount) AS base_tax_amount,
    (employee_per_diem.exchange_rate * employee_per_diem.full_amount) AS base_full_amount
   FROM (employee_per_diem
     JOIN vw_employee_month ON ((employee_per_diem.employee_month_id = vw_employee_month.employee_month_id)));


ALTER TABLE public.vw_employee_per_diem OWNER TO postgres;

--
-- Name: vw_employee_per_diem_ledger; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_per_diem_ledger AS
 SELECT vw_employee_per_diem.org_id,
    vw_employee_per_diem.period_id,
    vw_employee_per_diem.travel_date,
    'Transport'::text AS description,
    vw_employee_per_diem.post_account,
    vw_employee_per_diem.entity_name,
    vw_employee_per_diem.full_amount AS dr_amt,
    0.0 AS cr_amt
   FROM vw_employee_per_diem
  WHERE ((vw_employee_per_diem.approve_status)::text = 'Approved'::text)
UNION
 SELECT vw_employee_per_diem.org_id,
    vw_employee_per_diem.period_id,
    vw_employee_per_diem.travel_date,
    'Travel Petty Cash'::text AS description,
    '3305'::character varying AS post_account,
    vw_employee_per_diem.entity_name,
    0.0 AS dr_amt,
    vw_employee_per_diem.cash_paid AS cr_amt
   FROM vw_employee_per_diem
  WHERE ((vw_employee_per_diem.approve_status)::text = 'Approved'::text)
UNION
 SELECT vw_employee_per_diem.org_id,
    vw_employee_per_diem.period_id,
    vw_employee_per_diem.travel_date,
    'Transport PAYE'::text AS description,
    '4045'::character varying AS post_account,
    vw_employee_per_diem.entity_name,
    0.0 AS dr_amt,
    (vw_employee_per_diem.full_amount - vw_employee_per_diem.cash_paid) AS cr_amt
   FROM vw_employee_per_diem
  WHERE ((vw_employee_per_diem.approve_status)::text = 'Approved'::text);


ALTER TABLE public.vw_employee_per_diem_ledger OWNER TO postgres;

--
-- Name: vw_employee_tax_types; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_tax_types AS
 SELECT vw_employee_month.employee_month_id,
    vw_employee_month.period_id,
    vw_employee_month.start_date,
    vw_employee_month.month_id,
    vw_employee_month.period_year,
    vw_employee_month.period_month,
    vw_employee_month.end_date,
    vw_employee_month.gl_payroll_account,
    vw_employee_month.entity_id,
    vw_employee_month.entity_name,
    vw_employee_month.employee_id,
    tax_types.tax_type_id,
    tax_types.tax_type_name,
    tax_types.account_id,
    employee_tax_types.org_id,
    employee_tax_types.employee_tax_type_id,
    employee_tax_types.tax_identification,
    employee_tax_types.amount,
    employee_tax_types.additional,
    employee_tax_types.employer,
    employee_tax_types.narrative,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    employee_tax_types.exchange_rate,
    (employee_tax_types.exchange_rate * employee_tax_types.amount) AS base_amount
   FROM (((employee_tax_types
     JOIN vw_employee_month ON ((employee_tax_types.employee_month_id = vw_employee_month.employee_month_id)))
     JOIN tax_types ON ((employee_tax_types.tax_type_id = tax_types.tax_type_id)))
     JOIN currency ON ((tax_types.currency_id = currency.currency_id)));


ALTER TABLE public.vw_employee_tax_types OWNER TO postgres;

--
-- Name: vw_employee_trainings; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employee_trainings AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    trainings.training_id,
    trainings.training_name,
    trainings.training_cost,
    employee_trainings.org_id,
    employee_trainings.employee_training_id,
    employee_trainings.narrative,
    employee_trainings.completed,
    employee_trainings.application_date,
    employee_trainings.approve_status,
    employee_trainings.action_date,
    employee_trainings.details
   FROM ((employee_trainings
     JOIN entitys ON ((employee_trainings.entity_id = entitys.entity_id)))
     JOIN trainings ON ((employee_trainings.training_id = trainings.training_id)));


ALTER TABLE public.vw_employee_trainings OWNER TO postgres;

--
-- Name: vw_employees; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employees AS
 SELECT vw_bank_branch.bank_id,
    vw_bank_branch.bank_name,
    vw_bank_branch.bank_branch_id,
    vw_bank_branch.bank_branch_name,
    vw_bank_branch.bank_branch_code,
    vw_department_roles.department_id,
    vw_department_roles.department_name,
    vw_department_roles.department_role_id,
    vw_department_roles.department_role_name,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    sys_countrys.sys_country_name,
    nob.sys_country_name AS birth_nation_name,
    disability.disability_id,
    disability.disability_name,
    employees.org_id,
    employees.entity_id,
    employees.employee_id,
    employees.surname,
    employees.first_name,
    employees.middle_name,
    employees.person_title,
    employees.field_of_study,
    (((((employees.surname)::text || ' '::text) || (employees.first_name)::text) || ' '::text) || (COALESCE(employees.middle_name, ''::character varying))::text) AS employee_name,
    employees.date_of_birth,
    employees.place_of_birth,
    employees.gender,
    employees.nationality,
    employees.nation_of_birth,
    employees.marital_status,
    employees.appointment_date,
    employees.exit_date,
    employees.contract,
    employees.contract_period,
    employees.employment_terms,
    employees.identity_card,
    employees.basic_salary,
    employees.bank_account,
    employees.language,
    employees.picture_file,
    employees.active,
    employees.height,
    employees.weight,
    employees.blood_group,
    employees.allergies,
    employees.phone,
    employees.objective,
    employees.interests,
    employees.details,
    to_char(age((employees.date_of_birth)::timestamp with time zone), 'YY'::text) AS employee_age,
        CASE
            WHEN ((employees.gender)::text = 'M'::text) THEN 'Male'::text
            ELSE 'Female'::text
        END AS gender_name,
        CASE
            WHEN ((employees.marital_status)::text = 'M'::text) THEN 'Married'::text
            ELSE 'Single'::text
        END AS marital_status_name,
    vw_education_max.education_class_name,
    vw_education_max.date_from,
    vw_education_max.date_to,
    vw_education_max.name_of_school,
    vw_education_max.examination_taken,
    vw_education_max.grades_obtained,
    vw_education_max.certificate_number
   FROM (((((((employees
     JOIN vw_bank_branch ON ((employees.bank_branch_id = vw_bank_branch.bank_branch_id)))
     JOIN vw_department_roles ON ((employees.department_role_id = vw_department_roles.department_role_id)))
     JOIN currency ON ((employees.currency_id = currency.currency_id)))
     JOIN sys_countrys ON ((employees.nationality = sys_countrys.sys_country_id)))
     LEFT JOIN sys_countrys nob ON ((employees.nation_of_birth = nob.sys_country_id)))
     LEFT JOIN disability ON ((employees.disability_id = disability.disability_id)))
     LEFT JOIN vw_education_max ON ((employees.entity_id = vw_education_max.entity_id)));


ALTER TABLE public.vw_employees OWNER TO postgres;

--
-- Name: vw_employment; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_employment AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    employment.employment_id,
    employment.date_from,
    employment.date_to,
    employment.org_id,
    employment.employers_name,
    employment.position_held,
    employment.details,
    age((COALESCE(employment.date_to, ('now'::text)::date))::timestamp with time zone, (employment.date_from)::timestamp with time zone) AS employment_duration
   FROM (employment
     JOIN entitys ON ((employment.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_employment OWNER TO postgres;

--
-- Name: vw_entity_address; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_entity_address AS
 SELECT vw_address.address_id,
    vw_address.address_name,
    vw_address.sys_country_id,
    vw_address.sys_country_name,
    vw_address.table_id,
    vw_address.table_name,
    vw_address.is_default,
    vw_address.post_office_box,
    vw_address.postal_code,
    vw_address.premises,
    vw_address.street,
    vw_address.town,
    vw_address.phone_number,
    vw_address.extension,
    vw_address.mobile,
    vw_address.fax,
    vw_address.email,
    vw_address.website
   FROM vw_address
  WHERE (((vw_address.table_name)::text = 'entitys'::text) AND (vw_address.is_default = true));


ALTER TABLE public.vw_entity_address OWNER TO root;

--
-- Name: vw_entity_employees; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_entity_employees AS
 SELECT entitys.entity_id,
    entitys.org_id,
    entitys.entity_type_id,
    entitys.entity_name,
    entitys.user_name,
    entitys.primary_email,
    entitys.super_user,
    entitys.entity_leader,
    entitys.function_role,
    entitys.date_enroled,
    entitys.is_active,
    entitys.entity_password,
    entitys.first_password,
    entitys.is_picked,
    employees.employee_id,
    employees.surname,
    employees.first_name,
    employees.middle_name,
    employees.date_of_birth,
    employees.gender,
    employees.nationality,
    employees.marital_status,
    employees.appointment_date,
    employees.exit_date,
    employees.contract,
    employees.contract_period,
    employees.employment_terms,
    employees.identity_card,
    employees.basic_salary,
    employees.bank_account,
    employees.language,
    employees.objective,
    employees.active
   FROM (entitys
     JOIN employees ON ((entitys.entity_id = employees.entity_id)));


ALTER TABLE public.vw_entity_employees OWNER TO postgres;

--
-- Name: vw_entity_subscriptions; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_entity_subscriptions AS
 SELECT entity_types.entity_type_id,
    entity_types.entity_type_name,
    entitys.entity_id,
    entitys.entity_name,
    subscription_levels.subscription_level_id,
    subscription_levels.subscription_level_name,
    entity_subscriptions.entity_subscription_id,
    entity_subscriptions.org_id,
    entity_subscriptions.details
   FROM (((entity_subscriptions
     JOIN entity_types ON ((entity_subscriptions.entity_type_id = entity_types.entity_type_id)))
     JOIN entitys ON ((entity_subscriptions.entity_id = entitys.entity_id)))
     JOIN subscription_levels ON ((entity_subscriptions.subscription_level_id = subscription_levels.subscription_level_id)));


ALTER TABLE public.vw_entity_subscriptions OWNER TO root;

--
-- Name: vw_orgs; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_orgs AS
 SELECT orgs.org_id,
    orgs.org_name,
    orgs.is_default,
    orgs.is_active,
    orgs.logo,
    orgs.details,
    orgs.cert_number,
    orgs.pin,
    orgs.vat_number,
    orgs.invoice_footer,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    vw_address.sys_country_id,
    vw_address.sys_country_name,
    vw_address.address_id,
    vw_address.table_name,
    vw_address.post_office_box,
    vw_address.postal_code,
    vw_address.premises,
    vw_address.street,
    vw_address.town,
    vw_address.phone_number,
    vw_address.extension,
    vw_address.mobile,
    vw_address.fax,
    vw_address.email,
    vw_address.website
   FROM ((orgs
     JOIN vw_address ON ((orgs.org_id = vw_address.table_id)))
     JOIN currency ON ((orgs.currency_id = currency.currency_id)))
  WHERE ((((vw_address.table_name)::text = 'orgs'::text) AND (vw_address.is_default = true)) AND (orgs.is_active = true));


ALTER TABLE public.vw_orgs OWNER TO postgres;

--
-- Name: vw_entitys; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_entitys AS
 SELECT vw_orgs.org_id,
    vw_orgs.org_name,
    vw_orgs.is_default AS org_is_default,
    vw_orgs.is_active AS org_is_active,
    vw_orgs.logo AS org_logo,
    vw_orgs.cert_number AS org_cert_number,
    vw_orgs.pin AS org_pin,
    vw_orgs.vat_number AS org_vat_number,
    vw_orgs.invoice_footer AS org_invoice_footer,
    vw_orgs.sys_country_id AS org_sys_country_id,
    vw_orgs.sys_country_name AS org_sys_country_name,
    vw_orgs.address_id AS org_address_id,
    vw_orgs.table_name AS org_table_name,
    vw_orgs.post_office_box AS org_post_office_box,
    vw_orgs.postal_code AS org_postal_code,
    vw_orgs.premises AS org_premises,
    vw_orgs.street AS org_street,
    vw_orgs.town AS org_town,
    vw_orgs.phone_number AS org_phone_number,
    vw_orgs.extension AS org_extension,
    vw_orgs.mobile AS org_mobile,
    vw_orgs.fax AS org_fax,
    vw_orgs.email AS org_email,
    vw_orgs.website AS org_website,
    vw_address.address_id,
    vw_address.address_name,
    vw_address.sys_country_id,
    vw_address.sys_country_name,
    vw_address.table_name,
    vw_address.is_default,
    vw_address.post_office_box,
    vw_address.postal_code,
    vw_address.premises,
    vw_address.street,
    vw_address.town,
    vw_address.phone_number,
    vw_address.extension,
    vw_address.mobile,
    vw_address.fax,
    vw_address.email,
    vw_address.website,
    entitys.entity_id,
    entitys.entity_name,
    entitys.user_name,
    entitys.super_user,
    entitys.entity_leader,
    entitys.date_enroled,
    entitys.is_active,
    entitys.entity_password,
    entitys.first_password,
    entitys.function_role,
    entitys.attention,
    entitys.primary_email,
    entitys.primary_telephone,
    entity_types.entity_type_id,
    entity_types.entity_type_name,
    entity_types.entity_role,
    entity_types.use_key
   FROM (((entitys
     LEFT JOIN vw_address ON ((entitys.entity_id = vw_address.table_id)))
     JOIN vw_orgs ON ((entitys.org_id = vw_orgs.org_id)))
     JOIN entity_types ON ((entitys.entity_type_id = entity_types.entity_type_id)))
  WHERE (((vw_address.table_name)::text = 'entitys'::text) OR (vw_address.table_name IS NULL));


ALTER TABLE public.vw_entitys OWNER TO postgres;

--
-- Name: vw_entry_forms; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_entry_forms AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    forms.form_id,
    forms.form_name,
    entry_forms.entry_form_id,
    entry_forms.org_id,
    entry_forms.approve_status,
    entry_forms.application_date,
    entry_forms.completion_date,
    entry_forms.action_date,
    entry_forms.narrative,
    entry_forms.answer,
    entry_forms.workflow_table_id,
    entry_forms.details
   FROM ((entry_forms
     JOIN entitys ON ((entry_forms.entity_id = entitys.entity_id)))
     JOIN forms ON ((entry_forms.form_id = forms.form_id)));


ALTER TABLE public.vw_entry_forms OWNER TO root;

--
-- Name: vw_objectives; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_objectives AS
 SELECT vw_employee_objectives.entity_id,
    vw_employee_objectives.entity_name,
    vw_employee_objectives.employee_objective_id,
    vw_employee_objectives.employee_objective_name,
    vw_employee_objectives.objective_date,
    vw_employee_objectives.approve_status,
    vw_employee_objectives.workflow_table_id,
    vw_employee_objectives.application_date,
    vw_employee_objectives.action_date,
    vw_employee_objectives.supervisor_comments,
    objective_types.objective_type_id,
    objective_types.objective_type_name,
    objectives.org_id,
    objectives.objective_id,
    objectives.date_set,
    objectives.objective_ps,
    objectives.objective_name,
    objectives.objective_completed,
    objectives.details
   FROM ((objectives
     JOIN vw_employee_objectives ON ((objectives.employee_objective_id = vw_employee_objectives.employee_objective_id)))
     JOIN objective_types ON ((objectives.objective_type_id = objective_types.objective_type_id)));


ALTER TABLE public.vw_objectives OWNER TO postgres;

--
-- Name: vw_evaluation_objectives; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_evaluation_objectives AS
 SELECT vw_job_reviews.entity_id,
    vw_job_reviews.entity_name,
    vw_job_reviews.job_review_id,
    vw_job_reviews.total_points,
    vw_job_reviews.review_date,
    vw_job_reviews.review_done,
    vw_job_reviews.recomendation,
    vw_job_reviews.reviewer_comments,
    vw_job_reviews.pl_comments,
    vw_job_reviews.approve_status,
    vw_job_reviews.workflow_table_id,
    vw_job_reviews.application_date,
    vw_job_reviews.action_date,
    vw_objectives.objective_type_id,
    vw_objectives.objective_type_name,
    vw_objectives.objective_id,
    vw_objectives.date_set,
    vw_objectives.objective_ps,
    vw_objectives.objective_name,
    vw_objectives.objective_completed,
    vw_objectives.details AS objective_details,
    evaluation_points.org_id,
    evaluation_points.evaluation_point_id,
    evaluation_points.points,
    evaluation_points.reviewer_points,
    evaluation_points.reviewer_narrative,
    evaluation_points.narrative,
    evaluation_points.details
   FROM ((evaluation_points
     JOIN vw_job_reviews ON ((evaluation_points.job_review_id = vw_job_reviews.job_review_id)))
     JOIN vw_objectives ON ((evaluation_points.objective_id = vw_objectives.objective_id)));


ALTER TABLE public.vw_evaluation_objectives OWNER TO postgres;

--
-- Name: vw_review_points; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_review_points AS
 SELECT review_category.review_category_id,
    review_category.review_category_name,
    review_category.details AS review_category_details,
    review_points.org_id,
    review_points.review_point_id,
    review_points.review_point_name,
    review_points.review_points,
    review_points.details
   FROM (review_points
     JOIN review_category ON ((review_points.review_category_id = review_category.review_category_id)));


ALTER TABLE public.vw_review_points OWNER TO postgres;

--
-- Name: vw_evaluation_points; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_evaluation_points AS
 SELECT vw_job_reviews.entity_id,
    vw_job_reviews.entity_name,
    vw_job_reviews.job_review_id,
    vw_job_reviews.total_points,
    vw_job_reviews.review_date,
    vw_job_reviews.review_done,
    vw_job_reviews.recomendation,
    vw_job_reviews.reviewer_comments,
    vw_job_reviews.pl_comments,
    vw_job_reviews.approve_status,
    vw_job_reviews.workflow_table_id,
    vw_job_reviews.application_date,
    vw_job_reviews.action_date,
    vw_review_points.review_category_id,
    vw_review_points.review_category_name,
    vw_review_points.review_point_id,
    vw_review_points.review_point_name,
    vw_review_points.review_points,
    evaluation_points.org_id,
    evaluation_points.evaluation_point_id,
    evaluation_points.points,
    evaluation_points.grade,
    evaluation_points.reviewer_points,
    evaluation_points.reviewer_grade,
    evaluation_points.reviewer_narrative,
    evaluation_points.narrative,
    evaluation_points.details
   FROM ((evaluation_points
     JOIN vw_job_reviews ON ((evaluation_points.job_review_id = vw_job_reviews.job_review_id)))
     JOIN vw_review_points ON ((evaluation_points.review_point_id = vw_review_points.review_point_id)));


ALTER TABLE public.vw_evaluation_points OWNER TO postgres;

--
-- Name: vw_fields; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_fields AS
 SELECT forms.form_id,
    forms.form_name,
    fields.field_id,
    fields.org_id,
    fields.question,
    fields.field_lookup,
    fields.field_type,
    fields.field_order,
    fields.share_line,
    fields.field_size,
    fields.field_fnct,
    fields.manditory,
    fields.field_bold,
    fields.field_italics
   FROM (fields
     JOIN forms ON ((fields.form_id = forms.form_id)));


ALTER TABLE public.vw_fields OWNER TO root;

--
-- Name: vw_journals; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_journals AS
 SELECT vw_periods.fiscal_year_id,
    vw_periods.fiscal_year_start,
    vw_periods.fiscal_year_end,
    vw_periods.year_opened,
    vw_periods.year_closed,
    vw_periods.period_id,
    vw_periods.start_date,
    vw_periods.end_date,
    vw_periods.opened,
    vw_periods.closed,
    vw_periods.month_id,
    vw_periods.period_year,
    vw_periods.period_month,
    vw_periods.quarter,
    vw_periods.semister,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    departments.department_id,
    departments.department_name,
    journals.journal_id,
    journals.org_id,
    journals.journal_date,
    journals.posted,
    journals.year_closing,
    journals.narrative,
    journals.exchange_rate,
    journals.details
   FROM (((journals
     JOIN vw_periods ON ((journals.period_id = vw_periods.period_id)))
     JOIN currency ON ((journals.currency_id = currency.currency_id)))
     JOIN departments ON ((journals.department_id = departments.department_id)));


ALTER TABLE public.vw_journals OWNER TO postgres;

--
-- Name: vw_gls; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_gls AS
 SELECT vw_accounts.accounts_class_id,
    vw_accounts.chat_type_id,
    vw_accounts.chat_type_name,
    vw_accounts.accounts_class_name,
    vw_accounts.account_type_id,
    vw_accounts.account_type_name,
    vw_accounts.account_id,
    vw_accounts.account_name,
    vw_accounts.is_header,
    vw_accounts.is_active,
    vw_journals.fiscal_year_id,
    vw_journals.fiscal_year_start,
    vw_journals.fiscal_year_end,
    vw_journals.year_opened,
    vw_journals.year_closed,
    vw_journals.period_id,
    vw_journals.start_date,
    vw_journals.end_date,
    vw_journals.opened,
    vw_journals.closed,
    vw_journals.month_id,
    vw_journals.period_year,
    vw_journals.period_month,
    vw_journals.quarter,
    vw_journals.semister,
    vw_journals.currency_id,
    vw_journals.currency_name,
    vw_journals.currency_symbol,
    vw_journals.exchange_rate,
    vw_journals.journal_id,
    vw_journals.journal_date,
    vw_journals.posted,
    vw_journals.year_closing,
    vw_journals.narrative,
    gls.gl_id,
    gls.org_id,
    gls.debit,
    gls.credit,
    gls.gl_narrative,
    (gls.debit * vw_journals.exchange_rate) AS base_debit,
    (gls.credit * vw_journals.exchange_rate) AS base_credit
   FROM ((gls
     JOIN vw_accounts ON ((gls.account_id = vw_accounts.account_id)))
     JOIN vw_journals ON ((gls.journal_id = vw_journals.journal_id)));


ALTER TABLE public.vw_gls OWNER TO postgres;

--
-- Name: vw_identifications; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_identifications AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    identification_types.identification_type_id,
    identification_types.identification_type_name,
    identifications.org_id,
    identifications.identification_id,
    identifications.identification,
    identifications.is_active,
    identifications.starting_from,
    identifications.expiring_at,
    identifications.place_of_issue,
    identifications.details
   FROM ((identifications
     JOIN entitys ON ((identifications.entity_id = entitys.entity_id)))
     JOIN identification_types ON ((identifications.identification_type_id = identification_types.identification_type_id)));


ALTER TABLE public.vw_identifications OWNER TO postgres;

--
-- Name: vw_internships; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_internships AS
 SELECT departments.department_id,
    departments.department_name,
    internships.internship_id,
    internships.opening_date,
    internships.org_id,
    internships.closing_date,
    internships.positions,
    internships.location,
    internships.details
   FROM (internships
     JOIN departments ON ((internships.department_id = departments.department_id)));


ALTER TABLE public.vw_internships OWNER TO postgres;

--
-- Name: vw_intern_evaluations; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_intern_evaluations AS
 SELECT vw_applicants.entity_id,
    vw_applicants.sys_country_name,
    vw_applicants.applicant_name,
    vw_applicants.applicant_age,
    vw_applicants.gender_name,
    vw_applicants.marital_status_name,
    vw_applicants.language,
    vw_applicants.objective,
    vw_applicants.interests,
    education.date_from,
    education.date_to,
    education.name_of_school,
    education.examination_taken,
    vw_internships.department_id,
    vw_internships.department_name,
    vw_internships.internship_id,
    vw_internships.positions,
    vw_internships.opening_date,
    vw_internships.closing_date,
    interns.intern_id,
    interns.payment_amount,
    interns.start_date,
    interns.end_date,
    interns.application_date,
    interns.approve_status,
    interns.action_date,
    interns.workflow_table_id,
    interns.applicant_comments,
    interns.review
   FROM ((((vw_applicants
     JOIN education ON ((vw_applicants.entity_id = education.entity_id)))
     JOIN interns ON ((interns.entity_id = vw_applicants.entity_id)))
     JOIN vw_internships ON ((interns.internship_id = vw_internships.internship_id)))
     JOIN ( SELECT education_1.entity_id,
            max(education_1.education_class_id) AS mx_class_id
           FROM education education_1
          WHERE (education_1.entity_id IS NOT NULL)
          GROUP BY education_1.entity_id) a ON (((education.entity_id = a.entity_id) AND (education.education_class_id = a.mx_class_id))))
  WHERE (education.education_class_id > 6)
  ORDER BY vw_applicants.entity_id;


ALTER TABLE public.vw_intern_evaluations OWNER TO postgres;

--
-- Name: vw_interns; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_interns AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    entitys.primary_email,
    entitys.primary_telephone,
    vw_internships.department_id,
    vw_internships.department_name,
    vw_internships.internship_id,
    vw_internships.positions,
    vw_internships.opening_date,
    vw_internships.closing_date,
    interns.org_id,
    interns.intern_id,
    interns.payment_amount,
    interns.start_date,
    interns.end_date,
    interns.application_date,
    interns.approve_status,
    interns.action_date,
    interns.workflow_table_id,
    interns.applicant_comments,
    interns.review,
    vw_education_max.education_class_name,
    vw_education_max.date_from,
    vw_education_max.date_to,
    vw_education_max.name_of_school,
    vw_education_max.examination_taken,
    vw_education_max.grades_obtained,
    vw_education_max.certificate_number
   FROM (((interns
     JOIN entitys ON ((interns.entity_id = entitys.entity_id)))
     JOIN vw_internships ON ((interns.internship_id = vw_internships.internship_id)))
     LEFT JOIN vw_education_max ON ((entitys.entity_id = vw_education_max.entity_id)));


ALTER TABLE public.vw_interns OWNER TO postgres;

--
-- Name: vw_kins; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_kins AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    kin_types.kin_type_id,
    kin_types.kin_type_name,
    kins.org_id,
    kins.kin_id,
    kins.full_names,
    kins.date_of_birth,
    kins.identification,
    kins.relation,
    kins.emergency_contact,
    kins.beneficiary,
    kins.beneficiary_ps,
    kins.details
   FROM ((kins
     JOIN entitys ON ((kins.entity_id = entitys.entity_id)))
     JOIN kin_types ON ((kins.kin_type_id = kin_types.kin_type_id)));


ALTER TABLE public.vw_kins OWNER TO postgres;

--
-- Name: vw_leave_work_days; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_leave_work_days AS
 SELECT vw_employee_leave.entity_id,
    vw_employee_leave.entity_name,
    vw_employee_leave.leave_type_id,
    vw_employee_leave.leave_type_name,
    vw_employee_leave.employee_leave_id,
    vw_employee_leave.leave_from,
    vw_employee_leave.leave_to,
    vw_employee_leave.start_half_day,
    vw_employee_leave.end_half_day,
    leave_work_days.org_id,
    leave_work_days.leave_work_day_id,
    leave_work_days.work_date,
    leave_work_days.half_day,
    leave_work_days.application_date,
    leave_work_days.approve_status,
    leave_work_days.workflow_table_id,
    leave_work_days.action_date,
    leave_work_days.details
   FROM (leave_work_days
     JOIN vw_employee_leave ON ((leave_work_days.employee_leave_id = vw_employee_leave.employee_leave_id)));


ALTER TABLE public.vw_leave_work_days OWNER TO postgres;

--
-- Name: vw_sm_gls; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_sm_gls AS
 SELECT vw_gls.org_id,
    vw_gls.accounts_class_id,
    vw_gls.chat_type_id,
    vw_gls.chat_type_name,
    vw_gls.accounts_class_name,
    vw_gls.account_type_id,
    vw_gls.account_type_name,
    vw_gls.account_id,
    vw_gls.account_name,
    vw_gls.is_header,
    vw_gls.is_active,
    vw_gls.fiscal_year_id,
    vw_gls.fiscal_year_start,
    vw_gls.fiscal_year_end,
    vw_gls.year_opened,
    vw_gls.year_closed,
    vw_gls.period_id,
    vw_gls.start_date,
    vw_gls.end_date,
    vw_gls.opened,
    vw_gls.closed,
    vw_gls.month_id,
    vw_gls.period_year,
    vw_gls.period_month,
    vw_gls.quarter,
    vw_gls.semister,
    sum(vw_gls.debit) AS acc_debit,
    sum(vw_gls.credit) AS acc_credit,
    sum(vw_gls.base_debit) AS acc_base_debit,
    sum(vw_gls.base_credit) AS acc_base_credit
   FROM vw_gls
  WHERE (vw_gls.posted = true)
  GROUP BY vw_gls.org_id, vw_gls.accounts_class_id, vw_gls.chat_type_id, vw_gls.chat_type_name, vw_gls.accounts_class_name, vw_gls.account_type_id, vw_gls.account_type_name, vw_gls.account_id, vw_gls.account_name, vw_gls.is_header, vw_gls.is_active, vw_gls.fiscal_year_id, vw_gls.fiscal_year_start, vw_gls.fiscal_year_end, vw_gls.year_opened, vw_gls.year_closed, vw_gls.period_id, vw_gls.start_date, vw_gls.end_date, vw_gls.opened, vw_gls.closed, vw_gls.month_id, vw_gls.period_year, vw_gls.period_month, vw_gls.quarter, vw_gls.semister
  ORDER BY vw_gls.account_id;


ALTER TABLE public.vw_sm_gls OWNER TO postgres;

--
-- Name: vw_ledger; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_ledger AS
 SELECT vw_sm_gls.org_id,
    vw_sm_gls.accounts_class_id,
    vw_sm_gls.chat_type_id,
    vw_sm_gls.chat_type_name,
    vw_sm_gls.accounts_class_name,
    vw_sm_gls.account_type_id,
    vw_sm_gls.account_type_name,
    vw_sm_gls.account_id,
    vw_sm_gls.account_name,
    vw_sm_gls.is_header,
    vw_sm_gls.is_active,
    vw_sm_gls.fiscal_year_id,
    vw_sm_gls.fiscal_year_start,
    vw_sm_gls.fiscal_year_end,
    vw_sm_gls.year_opened,
    vw_sm_gls.year_closed,
    vw_sm_gls.period_id,
    vw_sm_gls.start_date,
    vw_sm_gls.end_date,
    vw_sm_gls.opened,
    vw_sm_gls.closed,
    vw_sm_gls.month_id,
    vw_sm_gls.period_year,
    vw_sm_gls.period_month,
    vw_sm_gls.quarter,
    vw_sm_gls.semister,
    vw_sm_gls.acc_debit,
    vw_sm_gls.acc_credit,
    (vw_sm_gls.acc_debit - vw_sm_gls.acc_credit) AS acc_balance,
    COALESCE(
        CASE
            WHEN (vw_sm_gls.acc_debit > vw_sm_gls.acc_credit) THEN (vw_sm_gls.acc_debit - vw_sm_gls.acc_credit)
            ELSE (0)::real
        END, (0)::real) AS bal_debit,
    COALESCE(
        CASE
            WHEN (vw_sm_gls.acc_debit < vw_sm_gls.acc_credit) THEN (vw_sm_gls.acc_credit - vw_sm_gls.acc_debit)
            ELSE (0)::real
        END, (0)::real) AS bal_credit,
    vw_sm_gls.acc_base_debit,
    vw_sm_gls.acc_base_credit,
    (vw_sm_gls.acc_base_debit - vw_sm_gls.acc_base_credit) AS acc_base_balance,
    COALESCE(
        CASE
            WHEN (vw_sm_gls.acc_base_debit > vw_sm_gls.acc_base_credit) THEN (vw_sm_gls.acc_base_debit - vw_sm_gls.acc_base_credit)
            ELSE (0)::real
        END, (0)::real) AS bal_base_debit,
    COALESCE(
        CASE
            WHEN (vw_sm_gls.acc_base_debit < vw_sm_gls.acc_base_credit) THEN (vw_sm_gls.acc_base_credit - vw_sm_gls.acc_base_debit)
            ELSE (0)::real
        END, (0)::real) AS bal_base_credit
   FROM vw_sm_gls;


ALTER TABLE public.vw_ledger OWNER TO postgres;

--
-- Name: vw_loan_types; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_loan_types AS
 SELECT adjustments.adjustment_id,
    adjustments.adjustment_name,
    loan_types.loan_type_id,
    loan_types.loan_type_name,
    loan_types.org_id,
    loan_types.default_interest,
    loan_types.reducing_balance,
    loan_types.details
   FROM (loan_types
     JOIN adjustments ON ((loan_types.adjustment_id = adjustments.adjustment_id)));


ALTER TABLE public.vw_loan_types OWNER TO postgres;

--
-- Name: vw_loans; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_loans AS
 SELECT vw_loan_types.adjustment_id,
    vw_loan_types.adjustment_name,
    vw_loan_types.loan_type_id,
    vw_loan_types.loan_type_name,
    entitys.entity_id,
    entitys.entity_name,
    loans.org_id,
    loans.loan_id,
    loans.principle,
    loans.interest,
    loans.monthly_repayment,
    loans.reducing_balance,
    loans.repayment_period,
    loans.application_date,
    loans.approve_status,
    loans.initial_payment,
    loans.loan_date,
    loans.action_date,
    loans.details,
    get_repayment(loans.principle, loans.interest, loans.repayment_period) AS repayment_amount,
    (loans.initial_payment + get_total_repayment(loans.loan_id)) AS total_repayment,
    get_total_interest(loans.loan_id) AS total_interest,
    (((loans.principle + get_total_interest(loans.loan_id)) - loans.initial_payment) - get_total_repayment(loans.loan_id)) AS loan_balance,
    get_payment_period(loans.principle, loans.monthly_repayment, loans.interest) AS calc_repayment_period
   FROM ((loans
     JOIN entitys ON ((loans.entity_id = entitys.entity_id)))
     JOIN vw_loan_types ON ((loans.loan_type_id = vw_loan_types.loan_type_id)));


ALTER TABLE public.vw_loans OWNER TO postgres;

--
-- Name: vw_loan_monthly; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_loan_monthly AS
 SELECT vw_loans.adjustment_id,
    vw_loans.adjustment_name,
    vw_loans.loan_type_id,
    vw_loans.loan_type_name,
    vw_loans.entity_id,
    vw_loans.entity_name,
    vw_loans.loan_date,
    vw_loans.loan_id,
    vw_loans.principle,
    vw_loans.interest,
    vw_loans.monthly_repayment,
    vw_loans.reducing_balance,
    vw_loans.repayment_period,
    vw_periods.period_id,
    vw_periods.start_date,
    vw_periods.end_date,
    vw_periods.activated,
    vw_periods.closed,
    loan_monthly.org_id,
    loan_monthly.loan_month_id,
    loan_monthly.interest_amount,
    loan_monthly.repayment,
    loan_monthly.interest_paid,
    loan_monthly.employee_adjustment_id,
    loan_monthly.penalty,
    loan_monthly.penalty_paid,
    loan_monthly.details,
    get_total_interest(vw_loans.loan_id, vw_periods.start_date) AS total_interest,
    get_total_repayment(vw_loans.loan_id, vw_periods.start_date) AS total_repayment,
    ((((vw_loans.principle + get_total_interest(vw_loans.loan_id, (vw_periods.start_date + 1))) + get_penalty(vw_loans.loan_id, (vw_periods.start_date + 1))) - vw_loans.initial_payment) - get_total_repayment(vw_loans.loan_id, (vw_periods.start_date + 1))) AS loan_balance
   FROM ((loan_monthly
     JOIN vw_loans ON ((loan_monthly.loan_id = vw_loans.loan_id)))
     JOIN vw_periods ON ((loan_monthly.period_id = vw_periods.period_id)));


ALTER TABLE public.vw_loan_monthly OWNER TO postgres;

--
-- Name: vw_loan_payments; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_loan_payments AS
 SELECT vw_loans.adjustment_id,
    vw_loans.adjustment_name,
    vw_loans.loan_type_id,
    vw_loans.loan_type_name,
    vw_loans.entity_id,
    vw_loans.entity_name,
    vw_loans.loan_date,
    vw_loans.loan_id,
    vw_loans.principle,
    vw_loans.interest,
    vw_loans.monthly_repayment,
    vw_loans.reducing_balance,
    vw_loans.repayment_period,
    vw_loans.application_date,
    vw_loans.approve_status,
    vw_loans.initial_payment,
    vw_loans.org_id,
    vw_loans.action_date,
    generate_series(1, vw_loans.repayment_period) AS months,
    get_loan_period(vw_loans.principle, vw_loans.interest, generate_series(1, vw_loans.repayment_period), vw_loans.repayment_amount) AS loan_balance,
    (get_loan_period(vw_loans.principle, vw_loans.interest, (generate_series(1, vw_loans.repayment_period) - 1), vw_loans.repayment_amount) * (vw_loans.interest / (1200)::double precision)) AS loan_intrest
   FROM vw_loans;


ALTER TABLE public.vw_loan_payments OWNER TO postgres;

--
-- Name: vw_loan_projection; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_loan_projection AS
 SELECT vw_loans.org_id,
    vw_loans.loan_id,
    vw_loans.loan_type_name,
    vw_loans.entity_name,
    vw_loans.principle,
    vw_loans.monthly_repayment,
    vw_loans.loan_date,
    ((date_part('year'::text, age((('now'::text)::date)::timestamp with time zone, '2010-05-01 00:00:00+03'::timestamp with time zone)) * (12)::double precision) + date_part('month'::text, age((('now'::text)::date)::timestamp with time zone, (vw_loans.loan_date)::timestamp with time zone))) AS loan_months,
    get_total_repayment(vw_loans.loan_id, (((date_part('year'::text, age((('now'::text)::date)::timestamp with time zone, '2010-05-01 00:00:00+03'::timestamp with time zone)) * (12)::double precision) + date_part('month'::text, age((('now'::text)::date)::timestamp with time zone, (vw_loans.loan_date)::timestamp with time zone))))::integer) AS loan_paid
   FROM vw_loans;


ALTER TABLE public.vw_loan_projection OWNER TO postgres;

--
-- Name: vw_objective_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_objective_details AS
 SELECT vw_objectives.entity_id,
    vw_objectives.entity_name,
    vw_objectives.employee_objective_id,
    vw_objectives.employee_objective_name,
    vw_objectives.objective_date,
    vw_objectives.approve_status,
    vw_objectives.workflow_table_id,
    vw_objectives.application_date,
    vw_objectives.action_date,
    vw_objectives.supervisor_comments,
    vw_objectives.objective_type_id,
    vw_objectives.objective_type_name,
    vw_objectives.objective_id,
    vw_objectives.date_set,
    vw_objectives.objective_ps,
    vw_objectives.objective_name,
    vw_objectives.objective_completed,
    objective_details.org_id,
    objective_details.objective_detail_id,
    objective_details.ln_objective_detail_id,
    objective_details.objective_detail_name,
    objective_details.success_indicator,
    objective_details.achievements,
    objective_details.resources_required,
    objective_details.target_date,
    objective_details.completed,
    objective_details.completion_date,
    objective_details.ods_ps,
    objective_details.ods_points,
    objective_details.ods_reviewer_points,
    objective_details.details
   FROM (objective_details
     JOIN vw_objectives ON ((objective_details.objective_id = vw_objectives.objective_id)));


ALTER TABLE public.vw_objective_details OWNER TO postgres;

--
-- Name: vw_objective_year; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_objective_year AS
 SELECT vw_employee_objectives.org_id,
    vw_employee_objectives.objective_year
   FROM vw_employee_objectives
  GROUP BY vw_employee_objectives.org_id, vw_employee_objectives.objective_year;


ALTER TABLE public.vw_objective_year OWNER TO postgres;

--
-- Name: vw_org_address; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_org_address AS
 SELECT vw_address.sys_country_id AS org_sys_country_id,
    vw_address.sys_country_name AS org_sys_country_name,
    vw_address.address_id AS org_address_id,
    vw_address.table_id AS org_table_id,
    vw_address.table_name AS org_table_name,
    vw_address.post_office_box AS org_post_office_box,
    vw_address.postal_code AS org_postal_code,
    vw_address.premises AS org_premises,
    vw_address.street AS org_street,
    vw_address.town AS org_town,
    vw_address.phone_number AS org_phone_number,
    vw_address.extension AS org_extension,
    vw_address.mobile AS org_mobile,
    vw_address.fax AS org_fax,
    vw_address.email AS org_email,
    vw_address.website AS org_website
   FROM vw_address
  WHERE (((vw_address.table_name)::text = 'orgs'::text) AND (vw_address.is_default = true));


ALTER TABLE public.vw_org_address OWNER TO root;

--
-- Name: vw_pay_scale_steps; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_pay_scale_steps AS
 SELECT currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    pay_scales.pay_scale_id,
    pay_scales.pay_scale_name,
    pay_scale_steps.org_id,
    pay_scale_steps.pay_scale_step_id,
    pay_scale_steps.pay_step,
    pay_scale_steps.pay_amount,
    (((((pay_scales.pay_scale_name)::text || '-'::text) || (currency.currency_symbol)::text) || '-'::text) || pay_scale_steps.pay_step) AS pay_step_name
   FROM ((pay_scale_steps
     JOIN pay_scales ON ((pay_scale_steps.pay_scale_id = pay_scales.pay_scale_id)))
     JOIN currency ON ((pay_scales.currency_id = currency.currency_id)));


ALTER TABLE public.vw_pay_scale_steps OWNER TO postgres;

--
-- Name: vw_pay_scales; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE vw_pay_scales (
    currency_id integer,
    currency_name character varying(50),
    currency_symbol character varying(3),
    org_id integer,
    pay_scale_id integer,
    pay_scale_name character varying(32),
    min_pay real,
    max_pay real,
    details text
);


ALTER TABLE public.vw_pay_scales OWNER TO postgres;

--
-- Name: vw_payroll_ledger; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_payroll_ledger AS
 SELECT a.org_id,
    a.period_id,
    a.end_date,
    a.description,
    a.gl_payroll_account,
    a.dr_amt,
    a.cr_amt
   FROM ( SELECT vw_employee_month.org_id,
            vw_employee_month.period_id,
            vw_employee_month.end_date,
            'BASIC SALARY'::text AS description,
            vw_employee_month.gl_payroll_account,
            sum(vw_employee_month.basic_pay) AS dr_amt,
            0.0 AS cr_amt
           FROM vw_employee_month
          GROUP BY vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, vw_employee_month.gl_payroll_account
        UNION
         SELECT vw_employee_month.org_id,
            vw_employee_month.period_id,
            vw_employee_month.end_date,
            'SALARY PAYMENTS'::text,
            vw_employee_month.gl_bank_account,
            0.0 AS sum_basic_pay,
            sum(vw_employee_month.banked) AS sum_banked
           FROM vw_employee_month
          WHERE ((vw_employee_month.bank_branch_id <> 0) AND (vw_employee_month.banked <> (0)::double precision))
          GROUP BY vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, vw_employee_month.gl_bank_account
        UNION
         SELECT vw_employee_month.org_id,
            vw_employee_month.period_id,
            vw_employee_month.end_date,
            'PETTY CASH PAYMENTS'::text,
            '3305'::character varying,
            0.0 AS sum_basic_pay,
            sum(vw_employee_month.banked) AS sum_banked
           FROM vw_employee_month
          WHERE ((vw_employee_month.bank_branch_id = 0) AND (vw_employee_month.banked <> (0)::double precision))
          GROUP BY vw_employee_month.org_id, vw_employee_month.period_id, vw_employee_month.end_date, vw_employee_month.gl_bank_account
        UNION
         SELECT vw_employee_tax_types.org_id,
            vw_employee_tax_types.period_id,
            vw_employee_tax_types.end_date,
            vw_employee_tax_types.tax_type_name,
            (vw_employee_tax_types.account_id)::character varying(32) AS account_id,
            0.0,
            sum(((vw_employee_tax_types.amount + vw_employee_tax_types.additional) + vw_employee_tax_types.employer)) AS sum
           FROM vw_employee_tax_types
          GROUP BY vw_employee_tax_types.org_id, vw_employee_tax_types.period_id, vw_employee_tax_types.end_date, vw_employee_tax_types.tax_type_name, vw_employee_tax_types.account_id
        UNION
         SELECT vw_employee_tax_types.org_id,
            vw_employee_tax_types.period_id,
            vw_employee_tax_types.end_date,
            ('Employer - '::text || (vw_employee_tax_types.tax_type_name)::text),
            '8025'::character varying,
            sum(vw_employee_tax_types.employer) AS sum,
            0.0
           FROM vw_employee_tax_types
          WHERE (vw_employee_tax_types.employer <> (0)::double precision)
          GROUP BY vw_employee_tax_types.org_id, vw_employee_tax_types.period_id, vw_employee_tax_types.end_date, vw_employee_tax_types.tax_type_name
        UNION
         SELECT vw_employee_adjustments.org_id,
            vw_employee_adjustments.period_id,
            vw_employee_adjustments.end_date,
            vw_employee_adjustments.adjustment_name,
            vw_employee_adjustments.account_number,
            sum(
                CASE
                    WHEN (vw_employee_adjustments.adjustment_type = 1) THEN (vw_employee_adjustments.amount - vw_employee_adjustments.paid_amount)
                    ELSE (0)::double precision
                END) AS dr_amt,
            sum(
                CASE
                    WHEN (vw_employee_adjustments.adjustment_type = 2) THEN (vw_employee_adjustments.amount - vw_employee_adjustments.paid_amount)
                    ELSE (0)::double precision
                END) AS cr_amt
           FROM vw_employee_adjustments
          WHERE (((vw_employee_adjustments.in_payroll = true) AND (vw_employee_adjustments.visible = true)) AND (vw_employee_adjustments.adjustment_type < 3))
          GROUP BY vw_employee_adjustments.org_id, vw_employee_adjustments.period_id, vw_employee_adjustments.end_date, vw_employee_adjustments.adjustment_name, vw_employee_adjustments.account_number, vw_employee_adjustments.adjustment_type
        UNION
         SELECT vw_employee_per_diem.org_id,
            vw_employee_per_diem.period_id,
            vw_employee_per_diem.travel_date,
            'Transport'::text AS description,
            vw_employee_per_diem.post_account,
            sum((vw_employee_per_diem.full_amount - vw_employee_per_diem.cash_paid)) AS dr_amt,
            0.0 AS cr_amt
           FROM vw_employee_per_diem
          WHERE ((vw_employee_per_diem.approve_status)::text = 'Approved'::text)
          GROUP BY vw_employee_per_diem.org_id, vw_employee_per_diem.period_id, vw_employee_per_diem.travel_date, vw_employee_per_diem.post_account) a
  ORDER BY a.gl_payroll_account DESC, a.dr_amt DESC, a.cr_amt DESC;


ALTER TABLE public.vw_payroll_ledger OWNER TO postgres;

--
-- Name: vw_payroll_ledger_trx; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_payroll_ledger_trx AS
 SELECT a.org_id,
    a.period_id,
    a.end_date,
    a.description,
    a.gl_payroll_account,
    a.entity_name,
    a.dr_amt,
    a.cr_amt
   FROM ( SELECT vw_employee_month.org_id,
            vw_employee_month.period_id,
            vw_employee_month.end_date,
            'BASIC SALARY'::text AS description,
            vw_employee_month.gl_payroll_account,
            vw_employee_month.entity_name,
            vw_employee_month.basic_pay AS dr_amt,
            0.0 AS cr_amt
           FROM vw_employee_month
        UNION
         SELECT vw_employee_month.org_id,
            vw_employee_month.period_id,
            vw_employee_month.end_date,
            'SALARY PAYMENTS'::text,
            vw_employee_month.gl_bank_account,
            vw_employee_month.entity_name,
            0.0 AS sum_basic_pay,
            vw_employee_month.banked AS sum_banked
           FROM vw_employee_month
          WHERE ((vw_employee_month.bank_branch_id <> 0) AND (vw_employee_month.banked <> (0)::double precision))
        UNION
         SELECT vw_employee_month.org_id,
            vw_employee_month.period_id,
            vw_employee_month.end_date,
            'PETTY CASH PAYMENTS'::text,
            '3305'::character varying,
            vw_employee_month.entity_name,
            0.0 AS sum_basic_pay,
            vw_employee_month.banked AS sum_banked
           FROM vw_employee_month
          WHERE ((vw_employee_month.bank_branch_id = 0) AND (vw_employee_month.banked <> (0)::double precision))
        UNION
         SELECT vw_employee_tax_types.org_id,
            vw_employee_tax_types.period_id,
            vw_employee_tax_types.end_date,
            vw_employee_tax_types.tax_type_name,
            (vw_employee_tax_types.account_id)::character varying(32) AS account_id,
            vw_employee_tax_types.entity_name,
            0.0,
            ((vw_employee_tax_types.amount + vw_employee_tax_types.additional) + vw_employee_tax_types.employer)
           FROM vw_employee_tax_types
        UNION
         SELECT vw_employee_tax_types.org_id,
            vw_employee_tax_types.period_id,
            vw_employee_tax_types.end_date,
            ('Employer - '::text || (vw_employee_tax_types.tax_type_name)::text),
            '8025'::character varying,
            vw_employee_tax_types.entity_name,
            vw_employee_tax_types.employer,
            0.0
           FROM vw_employee_tax_types
          WHERE (vw_employee_tax_types.employer <> (0)::double precision)
        UNION
         SELECT vw_employee_adjustments.org_id,
            vw_employee_adjustments.period_id,
            vw_employee_adjustments.end_date,
            vw_employee_adjustments.adjustment_name,
            vw_employee_adjustments.account_number,
            vw_employee_adjustments.entity_name,
            sum(
                CASE
                    WHEN (vw_employee_adjustments.adjustment_type = 1) THEN (vw_employee_adjustments.amount - vw_employee_adjustments.paid_amount)
                    ELSE (0)::double precision
                END) AS dr_amt,
            sum(
                CASE
                    WHEN (vw_employee_adjustments.adjustment_type = 2) THEN (vw_employee_adjustments.amount - vw_employee_adjustments.paid_amount)
                    ELSE (0)::double precision
                END) AS cr_amt
           FROM vw_employee_adjustments
          WHERE ((vw_employee_adjustments.visible = true) AND (vw_employee_adjustments.adjustment_type < 3))
          GROUP BY vw_employee_adjustments.org_id, vw_employee_adjustments.period_id, vw_employee_adjustments.end_date, vw_employee_adjustments.adjustment_name, vw_employee_adjustments.account_number, vw_employee_adjustments.entity_name
        UNION
         SELECT vw_employee_per_diem.org_id,
            vw_employee_per_diem.period_id,
            vw_employee_per_diem.travel_date,
            'Transport'::text AS description,
            vw_employee_per_diem.post_account,
            vw_employee_per_diem.entity_name,
            (vw_employee_per_diem.full_amount - vw_employee_per_diem.cash_paid) AS dr_amt,
            0.0 AS cr_amt
           FROM vw_employee_per_diem
          WHERE ((vw_employee_per_diem.approve_status)::text = 'Approved'::text)) a
  ORDER BY a.gl_payroll_account DESC, a.dr_amt DESC, a.cr_amt DESC;


ALTER TABLE public.vw_payroll_ledger_trx OWNER TO postgres;

--
-- Name: vw_pc_allocations; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_pc_allocations AS
 SELECT vw_periods.fiscal_year_id,
    vw_periods.fiscal_year_start,
    vw_periods.fiscal_year_end,
    vw_periods.year_opened,
    vw_periods.year_closed,
    vw_periods.period_id,
    vw_periods.start_date,
    vw_periods.end_date,
    vw_periods.opened,
    vw_periods.closed,
    vw_periods.month_id,
    vw_periods.period_year,
    vw_periods.period_month,
    vw_periods.quarter,
    vw_periods.semister,
    departments.department_id,
    departments.department_name,
    pc_allocations.org_id,
    pc_allocations.pc_allocation_id,
    pc_allocations.narrative,
    pc_allocations.approve_status,
    pc_allocations.details,
    ( SELECT sum(((pc_budget.budget_units)::double precision * pc_budget.budget_price)) AS sum
           FROM pc_budget
          WHERE (pc_budget.pc_allocation_id = pc_allocations.pc_allocation_id)) AS sum_budget,
    ( SELECT sum(((pc_expenditure.units)::double precision * pc_expenditure.unit_price)) AS sum
           FROM pc_expenditure
          WHERE (pc_expenditure.pc_allocation_id = pc_allocations.pc_allocation_id)) AS sum_expenditure,
    ( SELECT sum(pc_banking.amount) AS sum
           FROM pc_banking
          WHERE (pc_banking.pc_allocation_id = pc_allocations.pc_allocation_id)) AS sum_banking
   FROM ((pc_allocations
     JOIN vw_periods ON ((pc_allocations.period_id = vw_periods.period_id)))
     JOIN departments ON ((pc_allocations.department_id = departments.department_id)));


ALTER TABLE public.vw_pc_allocations OWNER TO postgres;

--
-- Name: vw_pc_items; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_pc_items AS
 SELECT pc_category.pc_category_id,
    pc_category.pc_category_name,
    pc_items.org_id,
    pc_items.pc_item_id,
    pc_items.pc_item_name,
    pc_items.default_price,
    pc_items.default_units,
    pc_items.details,
    (pc_items.default_price * (pc_items.default_units)::double precision) AS default_cost
   FROM (pc_items
     JOIN pc_category ON ((pc_items.pc_category_id = pc_category.pc_category_id)));


ALTER TABLE public.vw_pc_items OWNER TO postgres;

--
-- Name: vw_pc_budget; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_pc_budget AS
 SELECT vw_pc_allocations.fiscal_year_id,
    vw_pc_allocations.fiscal_year_start,
    vw_pc_allocations.fiscal_year_end,
    vw_pc_allocations.year_opened,
    vw_pc_allocations.year_closed,
    vw_pc_allocations.period_id,
    vw_pc_allocations.start_date,
    vw_pc_allocations.end_date,
    vw_pc_allocations.opened,
    vw_pc_allocations.closed,
    vw_pc_allocations.month_id,
    vw_pc_allocations.period_year,
    vw_pc_allocations.period_month,
    vw_pc_allocations.quarter,
    vw_pc_allocations.semister,
    vw_pc_allocations.department_id,
    vw_pc_allocations.department_name,
    vw_pc_allocations.pc_allocation_id,
    vw_pc_allocations.narrative,
    vw_pc_allocations.approve_status,
    vw_pc_items.pc_category_id,
    vw_pc_items.pc_category_name,
    vw_pc_items.pc_item_id,
    vw_pc_items.pc_item_name,
    vw_pc_items.default_price,
    vw_pc_items.default_units,
    vw_pc_items.default_cost,
    pc_budget.org_id,
    pc_budget.pc_budget_id,
    pc_budget.budget_units,
    pc_budget.budget_price,
    ((pc_budget.budget_units)::double precision * pc_budget.budget_price) AS budget_cost,
    pc_budget.details
   FROM ((pc_budget
     JOIN vw_pc_allocations ON ((pc_budget.pc_allocation_id = vw_pc_allocations.pc_allocation_id)))
     JOIN vw_pc_items ON ((pc_budget.pc_item_id = vw_pc_items.pc_item_id)));


ALTER TABLE public.vw_pc_budget OWNER TO postgres;

--
-- Name: vw_pc_expenditure; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_pc_expenditure AS
 SELECT vw_pc_allocations.fiscal_year_id,
    vw_pc_allocations.fiscal_year_start,
    vw_pc_allocations.fiscal_year_end,
    vw_pc_allocations.year_opened,
    vw_pc_allocations.year_closed,
    vw_pc_allocations.period_id,
    vw_pc_allocations.start_date,
    vw_pc_allocations.end_date,
    vw_pc_allocations.opened,
    vw_pc_allocations.closed,
    vw_pc_allocations.month_id,
    vw_pc_allocations.period_year,
    vw_pc_allocations.period_month,
    vw_pc_allocations.quarter,
    vw_pc_allocations.semister,
    vw_pc_allocations.department_id,
    vw_pc_allocations.department_name,
    vw_pc_allocations.pc_allocation_id,
    vw_pc_allocations.narrative,
    vw_pc_items.pc_category_id,
    vw_pc_items.pc_category_name,
    vw_pc_items.pc_item_id,
    vw_pc_items.pc_item_name,
    vw_pc_items.default_price,
    vw_pc_items.default_units,
    vw_pc_items.default_cost,
    pc_types.pc_type_id,
    pc_types.pc_type_name,
    entitys.entity_id,
    entitys.entity_name,
    pc_expenditure.org_id,
    pc_expenditure.pc_expenditure_id,
    pc_expenditure.units,
    pc_expenditure.unit_price,
    pc_expenditure.receipt_number,
    pc_expenditure.exp_date,
    pc_expenditure.is_request,
    pc_expenditure.request_date,
    ((pc_expenditure.units)::double precision * pc_expenditure.unit_price) AS items_cost,
    pc_expenditure.application_date,
    pc_expenditure.approve_status,
    pc_expenditure.workflow_table_id,
    pc_expenditure.action_date,
    pc_expenditure.details
   FROM ((((pc_expenditure
     JOIN vw_pc_allocations ON ((pc_expenditure.pc_allocation_id = vw_pc_allocations.pc_allocation_id)))
     JOIN vw_pc_items ON ((pc_expenditure.pc_item_id = vw_pc_items.pc_item_id)))
     JOIN pc_types ON ((pc_expenditure.pc_type_id = pc_types.pc_type_id)))
     LEFT JOIN entitys ON ((pc_expenditure.entity_id = entitys.entity_id)));


ALTER TABLE public.vw_pc_expenditure OWNER TO postgres;

--
-- Name: vw_period_loans; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_period_loans AS
 SELECT vw_loan_monthly.org_id,
    vw_loan_monthly.period_id,
    sum(vw_loan_monthly.interest_amount) AS sum_interest_amount,
    sum(vw_loan_monthly.repayment) AS sum_repayment,
    sum(vw_loan_monthly.penalty) AS sum_penalty,
    sum(vw_loan_monthly.penalty_paid) AS sum_penalty_paid,
    sum(vw_loan_monthly.interest_paid) AS sum_interest_paid,
    sum(vw_loan_monthly.loan_balance) AS sum_loan_balance
   FROM vw_loan_monthly
  GROUP BY vw_loan_monthly.org_id, vw_loan_monthly.period_id;


ALTER TABLE public.vw_period_loans OWNER TO postgres;

--
-- Name: vw_period_month; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_period_month AS
 SELECT vw_periods.org_id,
    vw_periods.month_id,
    vw_periods.period_year,
    vw_periods.period_month
   FROM vw_periods
  GROUP BY vw_periods.org_id, vw_periods.month_id, vw_periods.period_year, vw_periods.period_month
  ORDER BY vw_periods.month_id, vw_periods.period_year, vw_periods.period_month;


ALTER TABLE public.vw_period_month OWNER TO postgres;

--
-- Name: vw_period_quarter; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_period_quarter AS
 SELECT vw_periods.org_id,
    vw_periods.quarter
   FROM vw_periods
  GROUP BY vw_periods.org_id, vw_periods.quarter
  ORDER BY vw_periods.quarter;


ALTER TABLE public.vw_period_quarter OWNER TO postgres;

--
-- Name: vw_period_semister; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_period_semister AS
 SELECT vw_periods.org_id,
    vw_periods.semister
   FROM vw_periods
  GROUP BY vw_periods.org_id, vw_periods.semister
  ORDER BY vw_periods.semister;


ALTER TABLE public.vw_period_semister OWNER TO postgres;

--
-- Name: vw_period_tax_rates; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_period_tax_rates AS
 SELECT period_tax_types.period_tax_type_id,
    period_tax_types.period_tax_type_name,
    period_tax_types.tax_type_id,
    period_tax_types.period_id,
    period_tax_rates.period_tax_rate_id,
    gettaxmin(period_tax_rates.tax_range, period_tax_types.period_tax_type_id) AS min_range,
    period_tax_rates.org_id,
    period_tax_rates.tax_range AS max_range,
    period_tax_rates.tax_rate,
    period_tax_rates.narrative
   FROM (period_tax_rates
     JOIN period_tax_types ON ((period_tax_rates.period_tax_type_id = period_tax_types.period_tax_type_id)));


ALTER TABLE public.vw_period_tax_rates OWNER TO postgres;

--
-- Name: vw_period_tax_types; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_period_tax_types AS
 SELECT vw_periods.period_id,
    vw_periods.start_date,
    vw_periods.end_date,
    vw_periods.overtime_rate,
    vw_periods.activated,
    vw_periods.closed,
    vw_periods.month_id,
    vw_periods.period_year,
    vw_periods.period_month,
    vw_periods.quarter,
    vw_periods.semister,
    tax_types.tax_type_id,
    tax_types.tax_type_name,
    period_tax_types.period_tax_type_id,
    period_tax_types.period_tax_type_name,
    tax_types.use_key,
    period_tax_types.org_id,
    period_tax_types.pay_date,
    period_tax_types.tax_relief,
    period_tax_types.linear,
    period_tax_types.percentage,
    period_tax_types.formural,
    period_tax_types.details
   FROM ((period_tax_types
     JOIN vw_periods ON ((period_tax_types.period_id = vw_periods.period_id)))
     JOIN tax_types ON ((period_tax_types.tax_type_id = tax_types.tax_type_id)));


ALTER TABLE public.vw_period_tax_types OWNER TO postgres;

--
-- Name: vw_period_year; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_period_year AS
 SELECT vw_periods.org_id,
    vw_periods.period_year
   FROM vw_periods
  GROUP BY vw_periods.org_id, vw_periods.period_year
  ORDER BY vw_periods.period_year;


ALTER TABLE public.vw_period_year OWNER TO postgres;

--
-- Name: vw_projects; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_projects AS
 SELECT entitys.entity_id AS client_id,
    entitys.entity_name AS client_name,
    project_types.project_type_id,
    project_types.project_type_name,
    projects.org_id,
    projects.project_id,
    projects.project_name,
    projects.signed,
    projects.contract_ref,
    projects.monthly_amount,
    projects.full_amount,
    projects.project_cost,
    projects.narrative,
    projects.start_date,
    projects.ending_date,
    projects.project_account,
    projects.details
   FROM ((projects
     JOIN entitys ON ((projects.entity_id = entitys.entity_id)))
     JOIN project_types ON ((projects.project_type_id = project_types.project_type_id)));


ALTER TABLE public.vw_projects OWNER TO postgres;

--
-- Name: vw_phases; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_phases AS
 SELECT vw_projects.client_id,
    vw_projects.client_name,
    vw_projects.project_type_id,
    vw_projects.project_type_name,
    vw_projects.project_id,
    vw_projects.project_name,
    vw_projects.signed,
    vw_projects.contract_ref,
    vw_projects.monthly_amount,
    vw_projects.full_amount,
    vw_projects.project_cost,
    vw_projects.narrative,
    vw_projects.start_date,
    vw_projects.ending_date,
    phases.org_id,
    phases.phase_id,
    phases.phase_name,
    phases.start_date AS phase_start_date,
    phases.end_date AS phase_end_date,
    phases.completed AS phase_completed,
    phases.phase_cost,
    phases.details
   FROM (phases
     JOIN vw_projects ON ((phases.project_id = vw_projects.project_id)));


ALTER TABLE public.vw_phases OWNER TO postgres;

--
-- Name: vw_project_cost; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_project_cost AS
 SELECT vw_phases.client_id,
    vw_phases.client_name,
    vw_phases.project_type_id,
    vw_phases.project_type_name,
    vw_phases.project_id,
    vw_phases.project_name,
    vw_phases.signed,
    vw_phases.contract_ref,
    vw_phases.monthly_amount,
    vw_phases.full_amount,
    vw_phases.project_cost,
    vw_phases.narrative,
    vw_phases.start_date,
    vw_phases.ending_date,
    vw_phases.phase_id,
    vw_phases.phase_name,
    vw_phases.phase_start_date,
    vw_phases.phase_end_date,
    vw_phases.phase_cost,
    project_cost.org_id,
    project_cost.project_cost_id,
    project_cost.project_cost_name,
    project_cost.amount,
    project_cost.cost_date,
    project_cost.cost_approved,
    project_cost.details
   FROM (project_cost
     JOIN vw_phases ON ((project_cost.phase_id = vw_phases.phase_id)));


ALTER TABLE public.vw_project_cost OWNER TO postgres;

--
-- Name: vw_project_staff; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_project_staff AS
 SELECT vw_projects.client_id,
    vw_projects.client_name,
    vw_projects.project_type_id,
    vw_projects.project_type_name,
    vw_projects.project_id,
    vw_projects.project_name,
    vw_projects.signed,
    vw_projects.contract_ref,
    vw_projects.monthly_amount,
    vw_projects.full_amount,
    vw_projects.project_cost,
    vw_projects.narrative,
    vw_projects.project_account,
    vw_projects.start_date,
    vw_projects.ending_date,
    entitys.entity_id AS staff_id,
    entitys.entity_name AS staff_name,
    project_staff.org_id,
    project_staff.project_staff_id,
    project_staff.project_role,
    project_staff.monthly_cost,
    project_staff.staff_cost,
    project_staff.tax_cost,
    project_staff.details
   FROM ((project_staff
     JOIN entitys ON ((project_staff.entity_id = entitys.entity_id)))
     JOIN vw_projects ON ((project_staff.project_id = vw_projects.project_id)));


ALTER TABLE public.vw_project_staff OWNER TO postgres;

--
-- Name: vw_project_staff_costs; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_project_staff_costs AS
 SELECT vw_bank_branch.bank_id,
    vw_bank_branch.bank_name,
    vw_bank_branch.bank_branch_id,
    vw_bank_branch.bank_branch_name,
    entitys.entity_id,
    entitys.entity_name,
    pay_groups.pay_group_id,
    pay_groups.pay_group_name,
    vw_periods.period_id,
    vw_periods.start_date,
    vw_periods.end_date,
    vw_periods.overtime_rate,
    vw_periods.activated,
    vw_periods.closed,
    vw_periods.month_id,
    vw_periods.period_year,
    vw_periods.period_month,
    projects.project_id,
    projects.project_name,
    projects.project_account,
    project_staff_costs.org_id,
    project_staff_costs.project_staff_cost_id,
    project_staff_costs.bank_account,
    project_staff_costs.staff_cost,
    project_staff_costs.tax_cost,
    project_staff_costs.details
   FROM (((((project_staff_costs
     JOIN vw_bank_branch ON ((project_staff_costs.bank_branch_id = vw_bank_branch.bank_branch_id)))
     JOIN entitys ON ((project_staff_costs.entity_id = entitys.entity_id)))
     JOIN pay_groups ON ((project_staff_costs.pay_group_id = pay_groups.pay_group_id)))
     JOIN vw_periods ON ((project_staff_costs.period_id = vw_periods.period_id)))
     JOIN projects ON ((project_staff_costs.project_id = projects.project_id)));


ALTER TABLE public.vw_project_staff_costs OWNER TO postgres;

--
-- Name: vw_quotations; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_quotations AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    items.item_id,
    items.item_name,
    quotations.quotation_id,
    quotations.org_id,
    quotations.active,
    quotations.amount,
    quotations.valid_from,
    quotations.valid_to,
    quotations.lead_time,
    quotations.details
   FROM ((quotations
     JOIN entitys ON ((quotations.entity_id = entitys.entity_id)))
     JOIN items ON ((quotations.item_id = items.item_id)));


ALTER TABLE public.vw_quotations OWNER TO postgres;

--
-- Name: vw_referees; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_referees AS
 SELECT sys_countrys.sys_country_id,
    sys_countrys.sys_country_name,
    address.address_id,
    address.org_id,
    address.address_name,
    address.table_name,
    address.table_id,
    address.post_office_box,
    address.postal_code,
    address.premises,
    address.street,
    address.town,
    address.phone_number,
    address.extension,
    address.mobile,
    address.fax,
    address.email,
    address.is_default,
    address.website,
    address.company_name,
    address.position_held,
    address.details
   FROM (address
     JOIN sys_countrys ON ((address.sys_country_id = sys_countrys.sys_country_id)))
  WHERE ((address.table_name)::text = 'referees'::text);


ALTER TABLE public.vw_referees OWNER TO postgres;

--
-- Name: vw_reporting; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_reporting AS
 SELECT entitys.entity_id,
    entitys.entity_name,
    rpt.entity_id AS rpt_id,
    rpt.entity_name AS rpt_name,
    reporting.org_id,
    reporting.reporting_id,
    reporting.date_from,
    reporting.date_to,
    reporting.primary_report,
    reporting.is_active,
    reporting.ps_reporting,
    reporting.details
   FROM ((reporting
     JOIN entitys ON ((reporting.entity_id = entitys.entity_id)))
     JOIN entitys rpt ON ((reporting.report_to_id = rpt.entity_id)));


ALTER TABLE public.vw_reporting OWNER TO root;

--
-- Name: vw_review_year; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_review_year AS
 SELECT vw_job_reviews.org_id,
    vw_job_reviews.review_year
   FROM vw_job_reviews
  GROUP BY vw_job_reviews.org_id, vw_job_reviews.review_year;


ALTER TABLE public.vw_review_year OWNER TO postgres;

--
-- Name: vw_skill_types; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_skill_types AS
 SELECT skill_category.skill_category_id,
    skill_category.skill_category_name,
    skill_types.skill_type_id,
    skill_types.org_id,
    skill_types.skill_type_name,
    skill_types.basic,
    skill_types.intermediate,
    skill_types.advanced,
    skill_types.details
   FROM (skill_types
     JOIN skill_category ON ((skill_types.skill_category_id = skill_category.skill_category_id)));


ALTER TABLE public.vw_skill_types OWNER TO postgres;

--
-- Name: vw_skills; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_skills AS
 SELECT vw_skill_types.skill_category_id,
    vw_skill_types.skill_category_name,
    vw_skill_types.skill_type_id,
    vw_skill_types.skill_type_name,
    vw_skill_types.basic,
    vw_skill_types.intermediate,
    vw_skill_types.advanced,
    entitys.entity_id,
    entitys.entity_name,
    skills.skill_id,
    skills.skill_level,
    skills.aquired,
    skills.training_date,
    skills.org_id,
    skills.trained,
    skills.training_institution,
    skills.training_cost,
    skills.details,
        CASE
            WHEN (skills.skill_level = 1) THEN 'Basic'::text
            WHEN (skills.skill_level = 2) THEN 'Intermediate'::text
            WHEN (skills.skill_level = 3) THEN 'Advanced'::text
            ELSE 'None'::text
        END AS skill_level_name,
        CASE
            WHEN (skills.skill_level = 1) THEN vw_skill_types.basic
            WHEN (skills.skill_level = 2) THEN vw_skill_types.intermediate
            WHEN (skills.skill_level = 3) THEN vw_skill_types.advanced
            ELSE 'None'::character varying
        END AS skill_level_details
   FROM ((skills
     JOIN entitys ON ((skills.entity_id = entitys.entity_id)))
     JOIN vw_skill_types ON ((skills.skill_type_id = vw_skill_types.skill_type_id)));


ALTER TABLE public.vw_skills OWNER TO postgres;

--
-- Name: vw_stocks; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_stocks AS
 SELECT stores.store_id,
    stores.store_name,
    stocks.stock_id,
    stocks.org_id,
    stocks.stock_name,
    stocks.stock_take_date,
    stocks.details
   FROM (stocks
     JOIN stores ON ((stocks.store_id = stores.store_id)));


ALTER TABLE public.vw_stocks OWNER TO postgres;

--
-- Name: vw_stock_lines; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_stock_lines AS
 SELECT vw_stocks.stock_id,
    vw_stocks.stock_name,
    vw_stocks.stock_take_date,
    vw_stocks.store_id,
    vw_stocks.store_name,
    items.item_id,
    items.item_name,
    stock_lines.stock_line_id,
    stock_lines.org_id,
    stock_lines.quantity,
    stock_lines.narrative
   FROM ((stock_lines
     JOIN vw_stocks ON ((stock_lines.stock_id = vw_stocks.stock_id)))
     JOIN items ON ((stock_lines.item_id = items.item_id)));


ALTER TABLE public.vw_stock_lines OWNER TO postgres;

--
-- Name: vw_sub_fields; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_sub_fields AS
 SELECT vw_fields.form_id,
    vw_fields.form_name,
    vw_fields.field_id,
    sub_fields.sub_field_id,
    sub_fields.org_id,
    sub_fields.sub_field_order,
    sub_fields.sub_title_share,
    sub_fields.sub_field_type,
    sub_fields.sub_field_lookup,
    sub_fields.sub_field_size,
    sub_fields.sub_col_spans,
    sub_fields.manditory,
    sub_fields.question
   FROM (sub_fields
     JOIN vw_fields ON ((sub_fields.field_id = vw_fields.field_id)));


ALTER TABLE public.vw_sub_fields OWNER TO root;

--
-- Name: vw_sys_countrys; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_sys_countrys AS
 SELECT sys_continents.sys_continent_id,
    sys_continents.sys_continent_name,
    sys_countrys.sys_country_id,
    sys_countrys.sys_country_code,
    sys_countrys.sys_country_number,
    sys_countrys.sys_phone_code,
    sys_countrys.sys_country_name
   FROM (sys_continents
     JOIN sys_countrys ON ((sys_continents.sys_continent_id = sys_countrys.sys_continent_id)));


ALTER TABLE public.vw_sys_countrys OWNER TO root;

--
-- Name: vw_sys_emailed; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_sys_emailed AS
 SELECT sys_emails.sys_email_id,
    sys_emails.org_id,
    sys_emails.sys_email_name,
    sys_emails.title,
    sys_emails.details,
    sys_emailed.sys_emailed_id,
    sys_emailed.table_id,
    sys_emailed.table_name,
    sys_emailed.email_type,
    sys_emailed.emailed,
    sys_emailed.narrative
   FROM (sys_emails
     RIGHT JOIN sys_emailed ON ((sys_emails.sys_email_id = sys_emailed.sys_email_id)));


ALTER TABLE public.vw_sys_emailed OWNER TO root;

--
-- Name: vw_tasks; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_tasks AS
 SELECT vw_phases.client_id,
    vw_phases.client_name,
    vw_phases.project_type_id,
    vw_phases.project_type_name,
    vw_phases.project_id,
    vw_phases.project_name,
    vw_phases.signed,
    vw_phases.contract_ref,
    vw_phases.monthly_amount,
    vw_phases.full_amount,
    vw_phases.project_cost,
    vw_phases.narrative,
    vw_phases.start_date,
    vw_phases.ending_date,
    vw_phases.phase_id,
    vw_phases.phase_name,
    vw_phases.phase_start_date,
    vw_phases.phase_end_date,
    vw_phases.phase_completed,
    vw_phases.phase_cost,
    entitys.entity_id,
    entitys.entity_name,
    tasks.task_id,
    tasks.task_name,
    tasks.org_id,
    tasks.start_date AS task_start_date,
    tasks.dead_line AS task_dead_line,
    tasks.end_date AS task_end_date,
    tasks.completed AS task_completed,
    tasks.hours_taken,
    tasks.details AS task_details
   FROM ((tasks
     JOIN entitys ON ((tasks.entity_id = entitys.entity_id)))
     JOIN vw_phases ON ((tasks.phase_id = vw_phases.phase_id)));


ALTER TABLE public.vw_tasks OWNER TO postgres;

--
-- Name: vw_tax_rates; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_tax_rates AS
 SELECT tax_types.tax_type_id,
    tax_types.tax_type_name,
    tax_types.tax_relief,
    tax_types.linear,
    tax_types.percentage,
    tax_rates.org_id,
    tax_rates.tax_rate_id,
    tax_rates.tax_range,
    tax_rates.tax_rate,
    tax_rates.narrative
   FROM (tax_rates
     JOIN tax_types ON ((tax_rates.tax_type_id = tax_types.tax_type_id)));


ALTER TABLE public.vw_tax_rates OWNER TO postgres;

--
-- Name: vw_timesheet; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_timesheet AS
 SELECT vw_tasks.client_id,
    vw_tasks.client_name,
    vw_tasks.project_type_id,
    vw_tasks.project_type_name,
    vw_tasks.project_id,
    vw_tasks.project_name,
    vw_tasks.signed,
    vw_tasks.contract_ref,
    vw_tasks.monthly_amount,
    vw_tasks.full_amount,
    vw_tasks.project_cost,
    vw_tasks.narrative,
    vw_tasks.start_date,
    vw_tasks.ending_date,
    vw_tasks.phase_id,
    vw_tasks.phase_name,
    vw_tasks.phase_start_date,
    vw_tasks.phase_end_date,
    vw_tasks.phase_completed,
    vw_tasks.phase_cost,
    vw_tasks.entity_id,
    vw_tasks.entity_name,
    vw_tasks.task_id,
    vw_tasks.task_name,
    vw_tasks.task_start_date,
    vw_tasks.task_dead_line,
    vw_tasks.task_end_date,
    vw_tasks.task_completed,
    timesheet.org_id,
    timesheet.timesheet_id,
    timesheet.ts_date,
    timesheet.ts_start_time,
    timesheet.ts_end_time,
    timesheet.ts_narrative,
    timesheet.details,
    (date_part('hours'::text, (timesheet.ts_end_time - timesheet.ts_start_time)) + (date_part('minutes'::text, (timesheet.ts_end_time - timesheet.ts_start_time)) / (60)::double precision)) AS ts_hours
   FROM (timesheet
     JOIN vw_tasks ON ((timesheet.task_id = vw_tasks.task_id)));


ALTER TABLE public.vw_timesheet OWNER TO postgres;

--
-- Name: vw_transactions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_transactions AS
 SELECT transaction_types.transaction_type_id,
    transaction_types.transaction_type_name,
    transaction_types.document_prefix,
    transaction_types.for_posting,
    transaction_types.for_sales,
    entitys.entity_id,
    entitys.entity_name,
    entitys.account_id AS entity_account_id,
    currency.currency_id,
    currency.currency_name,
    vw_bank_accounts.bank_id,
    vw_bank_accounts.bank_name,
    vw_bank_accounts.bank_branch_name,
    vw_bank_accounts.account_id AS gl_bank_account_id,
    vw_bank_accounts.bank_account_id,
    vw_bank_accounts.bank_account_name,
    vw_bank_accounts.bank_account_number,
    departments.department_id,
    departments.department_name,
    transaction_status.transaction_status_id,
    transaction_status.transaction_status_name,
    transactions.journal_id,
    transactions.transaction_id,
    transactions.org_id,
    transactions.transaction_date,
    transactions.transaction_amount,
    transactions.application_date,
    transactions.approve_status,
    transactions.workflow_table_id,
    transactions.action_date,
    transactions.narrative,
    transactions.document_number,
    transactions.payment_number,
    transactions.order_number,
    transactions.exchange_rate,
    transactions.payment_terms,
    transactions.job,
    transactions.details,
        CASE
            WHEN (transactions.journal_id IS NULL) THEN 'Not Posted'::text
            ELSE 'Posted'::text
        END AS posted,
        CASE
            WHEN (((transactions.transaction_type_id = 2) OR (transactions.transaction_type_id = 8)) OR (transactions.transaction_type_id = 10)) THEN transactions.transaction_amount
            ELSE (0)::real
        END AS debit_amount,
        CASE
            WHEN (((transactions.transaction_type_id = 5) OR (transactions.transaction_type_id = 7)) OR (transactions.transaction_type_id = 9)) THEN transactions.transaction_amount
            ELSE (0)::real
        END AS credit_amount
   FROM ((((((transactions
     JOIN transaction_types ON ((transactions.transaction_type_id = transaction_types.transaction_type_id)))
     JOIN transaction_status ON ((transactions.transaction_status_id = transaction_status.transaction_status_id)))
     JOIN currency ON ((transactions.currency_id = currency.currency_id)))
     LEFT JOIN entitys ON ((transactions.entity_id = entitys.entity_id)))
     LEFT JOIN vw_bank_accounts ON ((vw_bank_accounts.bank_account_id = transactions.bank_account_id)))
     LEFT JOIN departments ON ((transactions.department_id = departments.department_id)));


ALTER TABLE public.vw_transactions OWNER TO postgres;

--
-- Name: vw_transaction_details; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_transaction_details AS
 SELECT vw_transactions.department_id,
    vw_transactions.department_name,
    vw_transactions.transaction_type_id,
    vw_transactions.transaction_type_name,
    vw_transactions.document_prefix,
    vw_transactions.transaction_id,
    vw_transactions.transaction_date,
    vw_transactions.entity_id,
    vw_transactions.entity_name,
    vw_transactions.approve_status,
    vw_transactions.workflow_table_id,
    vw_transactions.currency_name,
    vw_transactions.exchange_rate,
    accounts.account_id,
    accounts.account_name,
    vw_items.item_id,
    vw_items.item_name,
    vw_items.tax_type_id,
    vw_items.tax_account_id,
    vw_items.tax_type_name,
    vw_items.tax_rate,
    vw_items.tax_inclusive,
    vw_items.sales_account_id,
    vw_items.purchase_account_id,
    stores.store_id,
    stores.store_name,
    transaction_details.transaction_detail_id,
    transaction_details.org_id,
    transaction_details.quantity,
    transaction_details.amount,
    transaction_details.tax_amount,
    transaction_details.narrative,
    transaction_details.details,
    COALESCE(transaction_details.narrative, vw_items.item_name) AS item_description,
    ((transaction_details.quantity)::double precision * transaction_details.amount) AS full_amount,
    ((transaction_details.quantity)::double precision * transaction_details.tax_amount) AS full_tax_amount,
    ((transaction_details.quantity)::double precision * (transaction_details.amount + transaction_details.tax_amount)) AS full_total_amount,
        CASE
            WHEN ((vw_transactions.transaction_type_id = 5) OR (vw_transactions.transaction_type_id = 9)) THEN ((transaction_details.quantity)::double precision * transaction_details.tax_amount)
            ELSE (0)::double precision
        END AS tax_debit_amount,
        CASE
            WHEN ((vw_transactions.transaction_type_id = 2) OR (vw_transactions.transaction_type_id = 10)) THEN ((transaction_details.quantity)::double precision * transaction_details.tax_amount)
            ELSE (0)::double precision
        END AS tax_credit_amount,
        CASE
            WHEN ((vw_transactions.transaction_type_id = 5) OR (vw_transactions.transaction_type_id = 9)) THEN ((transaction_details.quantity)::double precision * transaction_details.amount)
            ELSE (0)::double precision
        END AS full_debit_amount,
        CASE
            WHEN ((vw_transactions.transaction_type_id = 2) OR (vw_transactions.transaction_type_id = 10)) THEN ((transaction_details.quantity)::double precision * transaction_details.amount)
            ELSE (0)::double precision
        END AS full_credit_amount,
        CASE
            WHEN ((vw_transactions.transaction_type_id = 2) OR (vw_transactions.transaction_type_id = 9)) THEN vw_items.sales_account_id
            ELSE vw_items.purchase_account_id
        END AS trans_account_id
   FROM ((((transaction_details
     JOIN vw_transactions ON ((transaction_details.transaction_id = vw_transactions.transaction_id)))
     LEFT JOIN vw_items ON ((transaction_details.item_id = vw_items.item_id)))
     LEFT JOIN accounts ON ((transaction_details.account_id = accounts.account_id)))
     LEFT JOIN stores ON ((transaction_details.store_id = stores.store_id)));


ALTER TABLE public.vw_transaction_details OWNER TO postgres;

--
-- Name: vw_trx; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_trx AS
 SELECT vw_orgs.org_id,
    vw_orgs.org_name,
    vw_orgs.is_default AS org_is_default,
    vw_orgs.is_active AS org_is_active,
    vw_orgs.logo AS org_logo,
    vw_orgs.cert_number AS org_cert_number,
    vw_orgs.pin AS org_pin,
    vw_orgs.vat_number AS org_vat_number,
    vw_orgs.invoice_footer AS org_invoice_footer,
    vw_orgs.sys_country_id AS org_sys_country_id,
    vw_orgs.sys_country_name AS org_sys_country_name,
    vw_orgs.address_id AS org_address_id,
    vw_orgs.table_name AS org_table_name,
    vw_orgs.post_office_box AS org_post_office_box,
    vw_orgs.postal_code AS org_postal_code,
    vw_orgs.premises AS org_premises,
    vw_orgs.street AS org_street,
    vw_orgs.town AS org_town,
    vw_orgs.phone_number AS org_phone_number,
    vw_orgs.extension AS org_extension,
    vw_orgs.mobile AS org_mobile,
    vw_orgs.fax AS org_fax,
    vw_orgs.email AS org_email,
    vw_orgs.website AS org_website,
    vw_entitys.address_id,
    vw_entitys.address_name,
    vw_entitys.sys_country_id,
    vw_entitys.sys_country_name,
    vw_entitys.table_name,
    vw_entitys.is_default,
    vw_entitys.post_office_box,
    vw_entitys.postal_code,
    vw_entitys.premises,
    vw_entitys.street,
    vw_entitys.town,
    vw_entitys.phone_number,
    vw_entitys.extension,
    vw_entitys.mobile,
    vw_entitys.fax,
    vw_entitys.email,
    vw_entitys.website,
    vw_entitys.entity_id,
    vw_entitys.entity_name,
    vw_entitys.user_name,
    vw_entitys.super_user,
    vw_entitys.attention,
    vw_entitys.date_enroled,
    vw_entitys.is_active,
    vw_entitys.entity_type_id,
    vw_entitys.entity_type_name,
    vw_entitys.entity_role,
    vw_entitys.use_key,
    transaction_types.transaction_type_id,
    transaction_types.transaction_type_name,
    transaction_types.document_prefix,
    transaction_types.for_sales,
    transaction_types.for_posting,
    transaction_status.transaction_status_id,
    transaction_status.transaction_status_name,
    currency.currency_id,
    currency.currency_name,
    currency.currency_symbol,
    departments.department_id,
    departments.department_name,
    transactions.journal_id,
    transactions.bank_account_id,
    transactions.transaction_id,
    transactions.transaction_date,
    transactions.transaction_amount,
    transactions.application_date,
    transactions.approve_status,
    transactions.workflow_table_id,
    transactions.action_date,
    transactions.narrative,
    transactions.document_number,
    transactions.payment_number,
    transactions.order_number,
    transactions.exchange_rate,
    transactions.payment_terms,
    transactions.job,
    transactions.details,
        CASE
            WHEN (transactions.journal_id IS NULL) THEN 'Not Posted'::text
            ELSE 'Posted'::text
        END AS posted,
        CASE
            WHEN (((transactions.transaction_type_id = 2) OR (transactions.transaction_type_id = 8)) OR (transactions.transaction_type_id = 10)) THEN transactions.transaction_amount
            ELSE (0)::real
        END AS debit_amount,
        CASE
            WHEN (((transactions.transaction_type_id = 5) OR (transactions.transaction_type_id = 7)) OR (transactions.transaction_type_id = 9)) THEN transactions.transaction_amount
            ELSE (0)::real
        END AS credit_amount
   FROM ((((((transactions
     JOIN transaction_types ON ((transactions.transaction_type_id = transaction_types.transaction_type_id)))
     JOIN vw_orgs ON ((transactions.org_id = vw_orgs.org_id)))
     JOIN transaction_status ON ((transactions.transaction_status_id = transaction_status.transaction_status_id)))
     JOIN currency ON ((transactions.currency_id = currency.currency_id)))
     LEFT JOIN vw_entitys ON ((transactions.entity_id = vw_entitys.entity_id)))
     LEFT JOIN departments ON ((transactions.department_id = departments.department_id)));


ALTER TABLE public.vw_trx OWNER TO postgres;

--
-- Name: vw_trx_sum; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_trx_sum AS
 SELECT transaction_details.transaction_id,
    sum(((transaction_details.quantity)::double precision * transaction_details.amount)) AS total_amount,
    sum(((transaction_details.quantity)::double precision * transaction_details.tax_amount)) AS total_tax_amount,
    sum(((transaction_details.quantity)::double precision * (transaction_details.amount + transaction_details.tax_amount))) AS total_sale_amount
   FROM transaction_details
  GROUP BY transaction_details.transaction_id;


ALTER TABLE public.vw_trx_sum OWNER TO postgres;

--
-- Name: vw_workflow_approvals; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_workflow_approvals AS
 SELECT vw_approvals.workflow_id,
    vw_approvals.org_id,
    vw_approvals.workflow_name,
    vw_approvals.approve_email,
    vw_approvals.reject_email,
    vw_approvals.source_entity_id,
    vw_approvals.source_entity_name,
    vw_approvals.table_name,
    vw_approvals.table_id,
    vw_approvals.org_entity_id,
    vw_approvals.org_entity_name,
    vw_approvals.org_user_name,
    vw_approvals.org_primary_email,
    rt.rejected_count,
        CASE
            WHEN (rt.rejected_count IS NULL) THEN ((vw_approvals.workflow_name)::text || ' Approved'::text)
            ELSE ((vw_approvals.workflow_name)::text || ' declined'::text)
        END AS workflow_narrative
   FROM (vw_approvals
     LEFT JOIN ( SELECT approvals.table_id,
            count(approvals.approval_id) AS rejected_count
           FROM approvals
          WHERE (((approvals.approve_status)::text = 'Rejected'::text) AND (approvals.forward_id IS NULL))
          GROUP BY approvals.table_id) rt ON ((vw_approvals.table_id = rt.table_id)))
  GROUP BY vw_approvals.workflow_id, vw_approvals.org_id, vw_approvals.workflow_name, vw_approvals.approve_email, vw_approvals.reject_email, vw_approvals.source_entity_id, vw_approvals.source_entity_name, vw_approvals.table_name, vw_approvals.table_id, vw_approvals.org_entity_id, vw_approvals.org_entity_name, vw_approvals.org_user_name, vw_approvals.org_primary_email, rt.rejected_count;


ALTER TABLE public.vw_workflow_approvals OWNER TO root;

--
-- Name: vw_workflow_entitys; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW vw_workflow_entitys AS
 SELECT vw_workflow_phases.workflow_id,
    vw_workflow_phases.org_id,
    vw_workflow_phases.workflow_name,
    vw_workflow_phases.table_name,
    vw_workflow_phases.table_link_id,
    vw_workflow_phases.source_entity_id,
    vw_workflow_phases.source_entity_name,
    vw_workflow_phases.approval_entity_id,
    vw_workflow_phases.approval_entity_name,
    vw_workflow_phases.workflow_phase_id,
    vw_workflow_phases.approval_level,
    vw_workflow_phases.return_level,
    vw_workflow_phases.escalation_days,
    vw_workflow_phases.escalation_hours,
    vw_workflow_phases.notice,
    vw_workflow_phases.notice_email,
    vw_workflow_phases.notice_file,
    vw_workflow_phases.advice,
    vw_workflow_phases.advice_email,
    vw_workflow_phases.advice_file,
    vw_workflow_phases.required_approvals,
    vw_workflow_phases.use_reporting,
    vw_workflow_phases.phase_narrative,
    entity_subscriptions.entity_subscription_id,
    entity_subscriptions.entity_id,
    entity_subscriptions.subscription_level_id
   FROM (vw_workflow_phases
     JOIN entity_subscriptions ON ((vw_workflow_phases.source_entity_id = entity_subscriptions.entity_type_id)));


ALTER TABLE public.vw_workflow_entitys OWNER TO root;

--
-- Name: vws_pc_expenditure; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vws_pc_expenditure AS
 SELECT a.period_id,
    a.period_year,
    a.period_month,
    a.department_id,
    a.department_name,
    a.pc_allocation_id,
    a.pc_category_id,
    a.pc_category_name,
    a.pc_item_id,
    a.pc_item_name,
    a.sum_units,
    a.avg_unit_price,
    a.sum_items_cost,
    pc_budget.budget_units,
    pc_budget.budget_price,
    ((pc_budget.budget_units)::double precision * pc_budget.budget_price) AS budget_cost,
    (COALESCE(pc_budget.budget_units, 0) - a.sum_units) AS unit_diff,
    (COALESCE(((pc_budget.budget_units)::double precision * pc_budget.budget_price), (0)::double precision) - a.sum_items_cost) AS budget_diff
   FROM (( SELECT vw_pc_expenditure.period_id,
            vw_pc_expenditure.period_year,
            vw_pc_expenditure.period_month,
            vw_pc_expenditure.department_id,
            vw_pc_expenditure.department_name,
            vw_pc_expenditure.pc_allocation_id,
            vw_pc_expenditure.pc_category_id,
            vw_pc_expenditure.pc_category_name,
            vw_pc_expenditure.pc_item_id,
            vw_pc_expenditure.pc_item_name,
            sum(vw_pc_expenditure.units) AS sum_units,
            avg(vw_pc_expenditure.unit_price) AS avg_unit_price,
            sum(((vw_pc_expenditure.units)::double precision * vw_pc_expenditure.unit_price)) AS sum_items_cost
           FROM vw_pc_expenditure
          GROUP BY vw_pc_expenditure.period_id, vw_pc_expenditure.period_year, vw_pc_expenditure.period_month, vw_pc_expenditure.department_id, vw_pc_expenditure.department_name, vw_pc_expenditure.pc_allocation_id, vw_pc_expenditure.pc_category_id, vw_pc_expenditure.pc_category_name, vw_pc_expenditure.pc_item_id, vw_pc_expenditure.pc_item_name) a
     LEFT JOIN pc_budget ON (((a.pc_allocation_id = pc_budget.pc_allocation_id) AND (a.pc_item_id = pc_budget.pc_item_id))));


ALTER TABLE public.vws_pc_expenditure OWNER TO postgres;

--
-- Name: vws_pc_budget_diff; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vws_pc_budget_diff AS
 SELECT a.period_id,
    a.period_year,
    a.period_month,
    a.department_id,
    a.department_name,
    a.pc_allocation_id,
    a.pc_category_id,
    a.pc_category_name,
    a.pc_item_id,
    a.pc_item_name,
    a.sum_units,
    a.avg_unit_price,
    a.sum_items_cost,
    a.budget_units,
    a.budget_price,
    a.budget_cost,
    a.unit_diff,
    a.budget_diff
   FROM vws_pc_expenditure a
UNION
 SELECT a.period_id,
    a.period_year,
    a.period_month,
    a.department_id,
    a.department_name,
    a.pc_allocation_id,
    a.pc_category_id,
    a.pc_category_name,
    a.pc_item_id,
    a.pc_item_name,
    0 AS sum_units,
    0 AS avg_unit_price,
    0 AS sum_items_cost,
    a.budget_units,
    a.budget_price,
    a.budget_cost,
    a.budget_units AS unit_diff,
    a.budget_cost AS budget_diff
   FROM (vw_pc_budget a
     LEFT JOIN pc_expenditure ON (((a.pc_allocation_id = pc_expenditure.pc_allocation_id) AND (a.pc_item_id = pc_expenditure.pc_item_id))))
  WHERE (pc_expenditure.pc_item_id IS NULL);


ALTER TABLE public.vws_pc_budget_diff OWNER TO postgres;

--
-- Name: workflow_logs; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE workflow_logs (
    workflow_log_id integer NOT NULL,
    org_id integer,
    table_name character varying(64),
    table_id integer,
    table_old_id integer
);


ALTER TABLE public.workflow_logs OWNER TO root;

--
-- Name: workflow_logs_workflow_log_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE workflow_logs_workflow_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.workflow_logs_workflow_log_id_seq OWNER TO root;

--
-- Name: workflow_logs_workflow_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE workflow_logs_workflow_log_id_seq OWNED BY workflow_logs.workflow_log_id;


--
-- Name: workflow_phases_workflow_phase_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE workflow_phases_workflow_phase_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.workflow_phases_workflow_phase_id_seq OWNER TO root;

--
-- Name: workflow_phases_workflow_phase_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE workflow_phases_workflow_phase_id_seq OWNED BY workflow_phases.workflow_phase_id;


--
-- Name: workflow_sql; Type: TABLE; Schema: public; Owner: root; Tablespace: 
--

CREATE TABLE workflow_sql (
    workflow_sql_id integer NOT NULL,
    workflow_phase_id integer NOT NULL,
    org_id integer,
    workflow_sql_name character varying(50),
    is_condition boolean DEFAULT false,
    is_action boolean DEFAULT false,
    message_number character varying(32),
    ca_sql text
);


ALTER TABLE public.workflow_sql OWNER TO root;

--
-- Name: workflow_table_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE workflow_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.workflow_table_id_seq OWNER TO root;

--
-- Name: workflows_workflow_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE workflows_workflow_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.workflows_workflow_id_seq OWNER TO root;

--
-- Name: workflows_workflow_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE workflows_workflow_id_seq OWNED BY workflows.workflow_id;


--
-- Name: address_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY address ALTER COLUMN address_id SET DEFAULT nextval('address_address_id_seq'::regclass);


--
-- Name: address_type_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY address_types ALTER COLUMN address_type_id SET DEFAULT nextval('address_types_address_type_id_seq'::regclass);


--
-- Name: adjustment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY adjustments ALTER COLUMN adjustment_id SET DEFAULT nextval('adjustments_adjustment_id_seq'::regclass);


--
-- Name: advance_deduction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY advance_deductions ALTER COLUMN advance_deduction_id SET DEFAULT nextval('advance_deductions_advance_deduction_id_seq'::regclass);


--
-- Name: amortisation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY amortisation ALTER COLUMN amortisation_id SET DEFAULT nextval('amortisation_amortisation_id_seq'::regclass);


--
-- Name: application_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY applications ALTER COLUMN application_id SET DEFAULT nextval('applications_application_id_seq'::regclass);


--
-- Name: approval_checklist_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY approval_checklists ALTER COLUMN approval_checklist_id SET DEFAULT nextval('approval_checklists_approval_checklist_id_seq'::regclass);


--
-- Name: approval_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY approvals ALTER COLUMN approval_id SET DEFAULT nextval('approvals_approval_id_seq'::regclass);


--
-- Name: asset_movement_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_movement ALTER COLUMN asset_movement_id SET DEFAULT nextval('asset_movement_asset_movement_id_seq'::regclass);


--
-- Name: asset_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_types ALTER COLUMN asset_type_id SET DEFAULT nextval('asset_types_asset_type_id_seq'::regclass);


--
-- Name: asset_valuation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_valuations ALTER COLUMN asset_valuation_id SET DEFAULT nextval('asset_valuations_asset_valuation_id_seq'::regclass);


--
-- Name: asset_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY assets ALTER COLUMN asset_id SET DEFAULT nextval('assets_asset_id_seq'::regclass);


--
-- Name: attendance_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attendance ALTER COLUMN attendance_id SET DEFAULT nextval('attendance_attendance_id_seq'::regclass);


--
-- Name: bank_account_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bank_accounts ALTER COLUMN bank_account_id SET DEFAULT nextval('bank_accounts_bank_account_id_seq'::regclass);


--
-- Name: bank_branch_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bank_branch ALTER COLUMN bank_branch_id SET DEFAULT nextval('bank_branch_bank_branch_id_seq'::regclass);


--
-- Name: bank_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY banks ALTER COLUMN bank_id SET DEFAULT nextval('banks_bank_id_seq'::regclass);


--
-- Name: bidder_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bidders ALTER COLUMN bidder_id SET DEFAULT nextval('bidders_bidder_id_seq'::regclass);


--
-- Name: bio_imports1_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bio_imports1 ALTER COLUMN bio_imports1_id SET DEFAULT nextval('bio_imports1_bio_imports1_id_seq'::regclass);


--
-- Name: budget_line_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budget_lines ALTER COLUMN budget_line_id SET DEFAULT nextval('budget_lines_budget_line_id_seq'::regclass);


--
-- Name: budget_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budgets ALTER COLUMN budget_id SET DEFAULT nextval('budgets_budget_id_seq'::regclass);


--
-- Name: career_development_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY career_development ALTER COLUMN career_development_id SET DEFAULT nextval('career_development_career_development_id_seq'::regclass);


--
-- Name: case_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY case_types ALTER COLUMN case_type_id SET DEFAULT nextval('case_types_case_type_id_seq'::regclass);


--
-- Name: casual_application_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY casual_application ALTER COLUMN casual_application_id SET DEFAULT nextval('casual_application_casual_application_id_seq'::regclass);


--
-- Name: casual_category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY casual_category ALTER COLUMN casual_category_id SET DEFAULT nextval('casual_category_casual_category_id_seq'::regclass);


--
-- Name: casual_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY casuals ALTER COLUMN casual_id SET DEFAULT nextval('casuals_casual_id_seq'::regclass);


--
-- Name: checklist_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY checklists ALTER COLUMN checklist_id SET DEFAULT nextval('checklists_checklist_id_seq'::regclass);


--
-- Name: claim_detail_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claim_details ALTER COLUMN claim_detail_id SET DEFAULT nextval('claim_details_claim_detail_id_seq'::regclass);


--
-- Name: claim_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claim_types ALTER COLUMN claim_type_id SET DEFAULT nextval('claim_types_claim_type_id_seq'::regclass);


--
-- Name: claim_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claims ALTER COLUMN claim_id SET DEFAULT nextval('claims_claim_id_seq'::regclass);


--
-- Name: contract_status_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY contract_status ALTER COLUMN contract_status_id SET DEFAULT nextval('contract_status_contract_status_id_seq'::regclass);


--
-- Name: contract_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY contract_types ALTER COLUMN contract_type_id SET DEFAULT nextval('contract_types_contract_type_id_seq'::regclass);


--
-- Name: contract_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY contracts ALTER COLUMN contract_id SET DEFAULT nextval('contracts_contract_id_seq'::regclass);


--
-- Name: currency_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY currency ALTER COLUMN currency_id SET DEFAULT nextval('currency_currency_id_seq'::regclass);


--
-- Name: currency_rate_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY currency_rates ALTER COLUMN currency_rate_id SET DEFAULT nextval('currency_rates_currency_rate_id_seq'::regclass);


--
-- Name: cv_projectid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cv_projects ALTER COLUMN cv_projectid SET DEFAULT nextval('cv_projects_cv_projectid_seq'::regclass);


--
-- Name: cv_seminar_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cv_seminars ALTER COLUMN cv_seminar_id SET DEFAULT nextval('cv_seminars_cv_seminar_id_seq'::regclass);


--
-- Name: day_ledger_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY day_ledgers ALTER COLUMN day_ledger_id SET DEFAULT nextval('day_ledgers_day_ledger_id_seq'::regclass);


--
-- Name: default_adjustment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_adjustments ALTER COLUMN default_adjustment_id SET DEFAULT nextval('default_adjustments_default_adjustment_id_seq'::regclass);


--
-- Name: default_banking_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_banking ALTER COLUMN default_banking_id SET DEFAULT nextval('default_banking_default_banking_id_seq'::regclass);


--
-- Name: default_tax_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_tax_types ALTER COLUMN default_tax_type_id SET DEFAULT nextval('default_tax_types_default_tax_type_id_seq'::regclass);


--
-- Name: define_phase_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY define_phases ALTER COLUMN define_phase_id SET DEFAULT nextval('define_phases_define_phase_id_seq'::regclass);


--
-- Name: define_task_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY define_tasks ALTER COLUMN define_task_id SET DEFAULT nextval('define_tasks_define_task_id_seq'::regclass);


--
-- Name: department_role_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY department_roles ALTER COLUMN department_role_id SET DEFAULT nextval('department_roles_department_role_id_seq'::regclass);


--
-- Name: department_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY departments ALTER COLUMN department_id SET DEFAULT nextval('departments_department_id_seq'::regclass);


--
-- Name: disability_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY disability ALTER COLUMN disability_id SET DEFAULT nextval('disability_disability_id_seq'::regclass);


--
-- Name: education_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY education ALTER COLUMN education_id SET DEFAULT nextval('education_education_id_seq'::regclass);


--
-- Name: education_class_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY education_class ALTER COLUMN education_class_id SET DEFAULT nextval('education_class_education_class_id_seq'::regclass);


--
-- Name: employee_adjustment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_adjustments ALTER COLUMN employee_adjustment_id SET DEFAULT nextval('employee_adjustments_employee_adjustment_id_seq'::regclass);


--
-- Name: employee_advance_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_advances ALTER COLUMN employee_advance_id SET DEFAULT nextval('employee_advances_employee_advance_id_seq'::regclass);


--
-- Name: default_banking_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_banking ALTER COLUMN default_banking_id SET DEFAULT nextval('employee_banking_default_banking_id_seq'::regclass);


--
-- Name: employee_case_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_cases ALTER COLUMN employee_case_id SET DEFAULT nextval('employee_cases_employee_case_id_seq'::regclass);


--
-- Name: employee_leave_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_leave ALTER COLUMN employee_leave_id SET DEFAULT nextval('employee_leave_employee_leave_id_seq'::regclass);


--
-- Name: employee_leave_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_leave_types ALTER COLUMN employee_leave_type_id SET DEFAULT nextval('employee_leave_types_employee_leave_type_id_seq'::regclass);


--
-- Name: employee_month_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_month ALTER COLUMN employee_month_id SET DEFAULT nextval('employee_month_employee_month_id_seq'::regclass);


--
-- Name: employee_objective_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_objectives ALTER COLUMN employee_objective_id SET DEFAULT nextval('employee_objectives_employee_objective_id_seq'::regclass);


--
-- Name: employee_overtime_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_overtime ALTER COLUMN employee_overtime_id SET DEFAULT nextval('employee_overtime_employee_overtime_id_seq'::regclass);


--
-- Name: employee_per_diem_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_per_diem ALTER COLUMN employee_per_diem_id SET DEFAULT nextval('employee_per_diem_employee_per_diem_id_seq'::regclass);


--
-- Name: employee_tax_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_tax_types ALTER COLUMN employee_tax_type_id SET DEFAULT nextval('employee_tax_types_employee_tax_type_id_seq'::regclass);


--
-- Name: employee_training_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_trainings ALTER COLUMN employee_training_id SET DEFAULT nextval('employee_trainings_employee_training_id_seq'::regclass);


--
-- Name: employment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employment ALTER COLUMN employment_id SET DEFAULT nextval('employment_employment_id_seq'::regclass);


--
-- Name: entity_subscription_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY entity_subscriptions ALTER COLUMN entity_subscription_id SET DEFAULT nextval('entity_subscriptions_entity_subscription_id_seq'::regclass);


--
-- Name: entity_type_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY entity_types ALTER COLUMN entity_type_id SET DEFAULT nextval('entity_types_entity_type_id_seq'::regclass);


--
-- Name: entity_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY entitys ALTER COLUMN entity_id SET DEFAULT nextval('entitys_entity_id_seq'::regclass);


--
-- Name: entry_form_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY entry_forms ALTER COLUMN entry_form_id SET DEFAULT nextval('entry_forms_entry_form_id_seq'::regclass);


--
-- Name: evaluation_point_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY evaluation_points ALTER COLUMN evaluation_point_id SET DEFAULT nextval('evaluation_points_evaluation_point_id_seq'::regclass);


--
-- Name: field_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY fields ALTER COLUMN field_id SET DEFAULT nextval('fields_field_id_seq'::regclass);


--
-- Name: form_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY forms ALTER COLUMN form_id SET DEFAULT nextval('forms_form_id_seq'::regclass);


--
-- Name: gl_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gls ALTER COLUMN gl_id SET DEFAULT nextval('gls_gl_id_seq'::regclass);


--
-- Name: holiday_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY holidays ALTER COLUMN holiday_id SET DEFAULT nextval('holidays_holiday_id_seq'::regclass);


--
-- Name: identification_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY identification_types ALTER COLUMN identification_type_id SET DEFAULT nextval('identification_types_identification_type_id_seq'::regclass);


--
-- Name: identification_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY identifications ALTER COLUMN identification_id SET DEFAULT nextval('identifications_identification_id_seq'::regclass);


--
-- Name: intake_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY intake ALTER COLUMN intake_id SET DEFAULT nextval('intake_intake_id_seq'::regclass);


--
-- Name: intern_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY interns ALTER COLUMN intern_id SET DEFAULT nextval('interns_intern_id_seq'::regclass);


--
-- Name: internship_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY internships ALTER COLUMN internship_id SET DEFAULT nextval('internships_internship_id_seq'::regclass);


--
-- Name: item_category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY item_category ALTER COLUMN item_category_id SET DEFAULT nextval('item_category_item_category_id_seq'::regclass);


--
-- Name: item_unit_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY item_units ALTER COLUMN item_unit_id SET DEFAULT nextval('item_units_item_unit_id_seq'::regclass);


--
-- Name: item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY items ALTER COLUMN item_id SET DEFAULT nextval('items_item_id_seq'::regclass);


--
-- Name: job_review_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job_reviews ALTER COLUMN job_review_id SET DEFAULT nextval('job_reviews_job_review_id_seq'::regclass);


--
-- Name: journal_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY journals ALTER COLUMN journal_id SET DEFAULT nextval('journals_journal_id_seq'::regclass);


--
-- Name: kin_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kin_types ALTER COLUMN kin_type_id SET DEFAULT nextval('kin_types_kin_type_id_seq'::regclass);


--
-- Name: kin_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kins ALTER COLUMN kin_id SET DEFAULT nextval('kins_kin_id_seq'::regclass);


--
-- Name: lead_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY lead_items ALTER COLUMN lead_item SET DEFAULT nextval('lead_items_lead_item_seq'::regclass);


--
-- Name: lead_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leads ALTER COLUMN lead_id SET DEFAULT nextval('leads_lead_id_seq'::regclass);


--
-- Name: leave_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_types ALTER COLUMN leave_type_id SET DEFAULT nextval('leave_types_leave_type_id_seq'::regclass);


--
-- Name: leave_work_day_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_work_days ALTER COLUMN leave_work_day_id SET DEFAULT nextval('leave_work_days_leave_work_day_id_seq'::regclass);


--
-- Name: loan_month_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loan_monthly ALTER COLUMN loan_month_id SET DEFAULT nextval('loan_monthly_loan_month_id_seq'::regclass);


--
-- Name: loan_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loan_types ALTER COLUMN loan_type_id SET DEFAULT nextval('loan_types_loan_type_id_seq'::regclass);


--
-- Name: loan_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loans ALTER COLUMN loan_id SET DEFAULT nextval('loans_loan_id_seq'::regclass);


--
-- Name: location_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY locations ALTER COLUMN location_id SET DEFAULT nextval('locations_location_id_seq'::regclass);


--
-- Name: objective_detail_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY objective_details ALTER COLUMN objective_detail_id SET DEFAULT nextval('objective_details_objective_detail_id_seq'::regclass);


--
-- Name: objective_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY objective_types ALTER COLUMN objective_type_id SET DEFAULT nextval('objective_types_objective_type_id_seq'::regclass);


--
-- Name: objective_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY objectives ALTER COLUMN objective_id SET DEFAULT nextval('objectives_objective_id_seq'::regclass);


--
-- Name: org_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY orgs ALTER COLUMN org_id SET DEFAULT nextval('orgs_org_id_seq'::regclass);


--
-- Name: pay_group_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pay_groups ALTER COLUMN pay_group_id SET DEFAULT nextval('pay_groups_pay_group_id_seq'::regclass);


--
-- Name: pay_scale_step_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pay_scale_steps ALTER COLUMN pay_scale_step_id SET DEFAULT nextval('pay_scale_steps_pay_scale_step_id_seq'::regclass);


--
-- Name: pay_scale_year_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pay_scale_years ALTER COLUMN pay_scale_year_id SET DEFAULT nextval('pay_scale_years_pay_scale_year_id_seq'::regclass);


--
-- Name: pay_scale_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pay_scales ALTER COLUMN pay_scale_id SET DEFAULT nextval('pay_scales_pay_scale_id_seq'::regclass);


--
-- Name: payroll_ledger_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY payroll_ledger ALTER COLUMN payroll_ledger_id SET DEFAULT nextval('payroll_ledger_payroll_ledger_id_seq'::regclass);


--
-- Name: pc_allocation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_allocations ALTER COLUMN pc_allocation_id SET DEFAULT nextval('pc_allocations_pc_allocation_id_seq'::regclass);


--
-- Name: pc_banking_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_banking ALTER COLUMN pc_banking_id SET DEFAULT nextval('pc_banking_pc_banking_id_seq'::regclass);


--
-- Name: pc_budget_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_budget ALTER COLUMN pc_budget_id SET DEFAULT nextval('pc_budget_pc_budget_id_seq'::regclass);


--
-- Name: pc_category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_category ALTER COLUMN pc_category_id SET DEFAULT nextval('pc_category_pc_category_id_seq'::regclass);


--
-- Name: pc_expenditure_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_expenditure ALTER COLUMN pc_expenditure_id SET DEFAULT nextval('pc_expenditure_pc_expenditure_id_seq'::regclass);


--
-- Name: pc_item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_items ALTER COLUMN pc_item_id SET DEFAULT nextval('pc_items_pc_item_id_seq'::regclass);


--
-- Name: pc_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_types ALTER COLUMN pc_type_id SET DEFAULT nextval('pc_types_pc_type_id_seq'::regclass);


--
-- Name: period_tax_rate_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY period_tax_rates ALTER COLUMN period_tax_rate_id SET DEFAULT nextval('period_tax_rates_period_tax_rate_id_seq'::regclass);


--
-- Name: period_tax_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY period_tax_types ALTER COLUMN period_tax_type_id SET DEFAULT nextval('period_tax_types_period_tax_type_id_seq'::regclass);


--
-- Name: period_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY periods ALTER COLUMN period_id SET DEFAULT nextval('periods_period_id_seq'::regclass);


--
-- Name: phase_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY phases ALTER COLUMN phase_id SET DEFAULT nextval('phases_phase_id_seq'::regclass);


--
-- Name: project_cost_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_cost ALTER COLUMN project_cost_id SET DEFAULT nextval('project_cost_project_cost_id_seq'::regclass);


--
-- Name: job_location_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_locations ALTER COLUMN job_location_id SET DEFAULT nextval('project_locations_job_location_id_seq'::regclass);


--
-- Name: project_staff_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_staff ALTER COLUMN project_staff_id SET DEFAULT nextval('project_staff_project_staff_id_seq'::regclass);


--
-- Name: project_staff_cost_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_staff_costs ALTER COLUMN project_staff_cost_id SET DEFAULT nextval('project_staff_costs_project_staff_cost_id_seq'::regclass);


--
-- Name: project_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_types ALTER COLUMN project_type_id SET DEFAULT nextval('project_types_project_type_id_seq'::regclass);


--
-- Name: project_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY projects ALTER COLUMN project_id SET DEFAULT nextval('projects_project_id_seq'::regclass);


--
-- Name: quotation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY quotations ALTER COLUMN quotation_id SET DEFAULT nextval('quotations_quotation_id_seq'::regclass);


--
-- Name: reporting_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY reporting ALTER COLUMN reporting_id SET DEFAULT nextval('reporting_reporting_id_seq'::regclass);


--
-- Name: review_category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY review_category ALTER COLUMN review_category_id SET DEFAULT nextval('review_category_review_category_id_seq'::regclass);


--
-- Name: review_point_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY review_points ALTER COLUMN review_point_id SET DEFAULT nextval('review_points_review_point_id_seq'::regclass);


--
-- Name: shift_schedule_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shift_schedule ALTER COLUMN shift_schedule_id SET DEFAULT nextval('shift_schedule_shift_schedule_id_seq'::regclass);


--
-- Name: shift_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shifts ALTER COLUMN shift_id SET DEFAULT nextval('shifts_shift_id_seq'::regclass);


--
-- Name: skill_category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY skill_category ALTER COLUMN skill_category_id SET DEFAULT nextval('skill_category_skill_category_id_seq'::regclass);


--
-- Name: skill_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY skill_types ALTER COLUMN skill_type_id SET DEFAULT nextval('skill_types_skill_type_id_seq'::regclass);


--
-- Name: skill_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY skills ALTER COLUMN skill_id SET DEFAULT nextval('skills_skill_id_seq'::regclass);


--
-- Name: stock_line_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stock_lines ALTER COLUMN stock_line_id SET DEFAULT nextval('stock_lines_stock_line_id_seq'::regclass);


--
-- Name: stock_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stocks ALTER COLUMN stock_id SET DEFAULT nextval('stocks_stock_id_seq'::regclass);


--
-- Name: store_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stores ALTER COLUMN store_id SET DEFAULT nextval('stores_store_id_seq'::regclass);


--
-- Name: sub_field_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sub_fields ALTER COLUMN sub_field_id SET DEFAULT nextval('sub_fields_sub_field_id_seq'::regclass);


--
-- Name: subscription_level_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY subscription_levels ALTER COLUMN subscription_level_id SET DEFAULT nextval('subscription_levels_subscription_level_id_seq'::regclass);


--
-- Name: sys_audit_detail_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_audit_details ALTER COLUMN sys_audit_detail_id SET DEFAULT nextval('sys_audit_details_sys_audit_detail_id_seq'::regclass);


--
-- Name: sys_audit_trail_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_audit_trail ALTER COLUMN sys_audit_trail_id SET DEFAULT nextval('sys_audit_trail_sys_audit_trail_id_seq'::regclass);


--
-- Name: sys_dashboard_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_dashboard ALTER COLUMN sys_dashboard_id SET DEFAULT nextval('sys_dashboard_sys_dashboard_id_seq'::regclass);


--
-- Name: sys_emailed_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_emailed ALTER COLUMN sys_emailed_id SET DEFAULT nextval('sys_emailed_sys_emailed_id_seq'::regclass);


--
-- Name: sys_email_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_emails ALTER COLUMN sys_email_id SET DEFAULT nextval('sys_emails_sys_email_id_seq'::regclass);


--
-- Name: sys_error_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_errors ALTER COLUMN sys_error_id SET DEFAULT nextval('sys_errors_sys_error_id_seq'::regclass);


--
-- Name: sys_file_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_files ALTER COLUMN sys_file_id SET DEFAULT nextval('sys_files_sys_file_id_seq'::regclass);


--
-- Name: sys_login_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_logins ALTER COLUMN sys_login_id SET DEFAULT nextval('sys_logins_sys_login_id_seq'::regclass);


--
-- Name: sys_menu_msg_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_menu_msg ALTER COLUMN sys_menu_msg_id SET DEFAULT nextval('sys_menu_msg_sys_menu_msg_id_seq'::regclass);


--
-- Name: sys_news_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_news ALTER COLUMN sys_news_id SET DEFAULT nextval('sys_news_sys_news_id_seq'::regclass);


--
-- Name: sys_queries_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_queries ALTER COLUMN sys_queries_id SET DEFAULT nextval('sys_queries_sys_queries_id_seq'::regclass);


--
-- Name: sys_reset_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_reset ALTER COLUMN sys_reset_id SET DEFAULT nextval('sys_reset_sys_reset_id_seq'::regclass);


--
-- Name: task_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tasks ALTER COLUMN task_id SET DEFAULT nextval('tasks_task_id_seq'::regclass);


--
-- Name: tax_rate_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tax_rates ALTER COLUMN tax_rate_id SET DEFAULT nextval('tax_rates_tax_rate_id_seq'::regclass);


--
-- Name: tax_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tax_types ALTER COLUMN tax_type_id SET DEFAULT nextval('tax_types_tax_type_id_seq'::regclass);


--
-- Name: tender_item_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tender_items ALTER COLUMN tender_item_id SET DEFAULT nextval('tender_items_tender_item_id_seq'::regclass);


--
-- Name: tender_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tender_types ALTER COLUMN tender_type_id SET DEFAULT nextval('tender_types_tender_type_id_seq'::regclass);


--
-- Name: tender_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tenders ALTER COLUMN tender_id SET DEFAULT nextval('tenders_tender_id_seq'::regclass);


--
-- Name: timesheet_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY timesheet ALTER COLUMN timesheet_id SET DEFAULT nextval('timesheet_timesheet_id_seq'::regclass);


--
-- Name: training_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY trainings ALTER COLUMN training_id SET DEFAULT nextval('trainings_training_id_seq'::regclass);


--
-- Name: transaction_detail_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_details ALTER COLUMN transaction_detail_id SET DEFAULT nextval('transaction_details_transaction_detail_id_seq'::regclass);


--
-- Name: transaction_link_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_links ALTER COLUMN transaction_link_id SET DEFAULT nextval('transaction_links_transaction_link_id_seq'::regclass);


--
-- Name: transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions ALTER COLUMN transaction_id SET DEFAULT nextval('transactions_transaction_id_seq'::regclass);


--
-- Name: workflow_log_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY workflow_logs ALTER COLUMN workflow_log_id SET DEFAULT nextval('workflow_logs_workflow_log_id_seq'::regclass);


--
-- Name: workflow_phase_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY workflow_phases ALTER COLUMN workflow_phase_id SET DEFAULT nextval('workflow_phases_workflow_phase_id_seq'::regclass);


--
-- Name: workflow_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY workflows ALTER COLUMN workflow_id SET DEFAULT nextval('workflows_workflow_id_seq'::regclass);


--
-- Data for Name: account_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (100, 0, 10, 'COST', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (110, 0, 10, 'ACCUMULATED DEPRECIATION', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (200, 0, 20, 'COST', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (210, 0, 20, 'ACCUMULATED AMORTISATION', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (300, 0, 30, 'DEBTORS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (310, 0, 30, 'INVESTMENTS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (320, 0, 30, 'CURRENT BANK ACCOUNTS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (330, 0, 30, 'CASH ON HAND', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (340, 0, 30, 'PRE-PAYMMENTS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (400, 0, 40, 'CREDITORS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (410, 0, 40, 'ADVANCED BILLING', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (420, 0, 40, 'VAT', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (430, 0, 40, 'WITHHOLDING TAX', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (500, 0, 50, 'LOANS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (600, 0, 60, 'CAPITAL GRANTS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (610, 0, 60, 'ACCUMULATED SURPLUS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (700, 0, 70, 'SALES REVENUE', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (710, 0, 70, 'OTHER INCOME', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (800, 0, 80, 'COST OF REVENUE', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (900, 0, 90, 'STAFF COSTS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (905, 0, 90, 'COMMUNICATIONS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (910, 0, 90, 'DIRECTORS ALLOWANCES', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (915, 0, 90, 'TRANSPORT', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (920, 0, 90, 'TRAVEL', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (925, 0, 90, 'POSTAL and COURIER', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (930, 0, 90, 'ICT PROJECT', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (935, 0, 90, 'STATIONERY', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (940, 0, 90, 'SUBSCRIPTION FEES', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (945, 0, 90, 'REPAIRS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (950, 0, 90, 'PROFESSIONAL FEES', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (955, 0, 90, 'OFFICE EXPENSES', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (960, 0, 90, 'MARKETING EXPENSES', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (965, 0, 90, 'STRATEGIC PLANNING', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (970, 0, 90, 'DEPRECIATION', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (975, 0, 90, 'CORPORATE SOCIAL INVESTMENT', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (980, 0, 90, 'FINANCE COSTS', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (985, 0, 90, 'TAXES', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (990, 0, 90, 'INSURANCE', NULL);
INSERT INTO account_types (account_type_id, org_id, accounts_class_id, account_type_name, details) VALUES (995, 0, 90, 'OTHER EXPENSES', NULL);


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (10000, 0, 100, 'COMPUTERS and EQUIPMENT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (10005, 0, 100, 'FURNITURE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (11000, 0, 110, 'COMPUTERS and EQUIPMENT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (11005, 0, 110, 'FURNITURE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (20000, 0, 200, 'INTANGIBLE ASSETS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (20005, 0, 200, 'NON CURRENT ASSETS: DEFFERED TAX', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (20010, 0, 200, 'INTANGIBLE ASSETS: ACCOUNTING PACKAGE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (21000, 0, 210, 'ACCUMULATED AMORTISATION', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (30000, 0, 300, 'TRADE DEBTORS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (30005, 0, 300, 'STAFF DEBTORS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (30010, 0, 300, 'OTHER DEBTORS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (30015, 0, 300, 'DEBTORS PROMPT PAYMENT DISCOUNT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (30020, 0, 300, 'INVENTORY', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (30025, 0, 300, 'INVENTORY WORK IN PROGRESS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (30030, 0, 300, 'GOODS RECEIVED CLEARING ACCOUNT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (31005, 0, 310, 'UNIT TRUST INVESTMENTS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (32000, 0, 320, 'COMMERCIAL BANK', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (32005, 0, 320, 'MPESA', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (33000, 0, 330, 'CASH ACCOUNT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (33005, 0, 330, 'PETTY CASH', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (34000, 0, 340, 'PREPAYMENTS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (34005, 0, 340, 'DEPOSITS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (34010, 0, 340, 'TAX RECOVERABLE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (34015, 0, 340, 'TOTAL REGISTRAR DEPOSITS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (40000, 0, 400, 'CREDITORS- ACCRUALS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (40005, 0, 400, 'ADVANCE BILLING', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (40010, 0, 400, 'LEAVE - ACCRUALS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (40015, 0, 400, 'ACCRUED LIABILITIES: CORPORATE TAX', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (40020, 0, 400, 'OTHER ACCRUALS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (40025, 0, 400, 'PROVISION FOR CREDIT NOTES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (40030, 0, 400, 'NSSF', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (40035, 0, 400, 'NHIF', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (40040, 0, 400, 'HELB', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (40045, 0, 400, 'PAYE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (40050, 0, 400, 'PENSION', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (41000, 0, 410, 'ADVANCED BILLING', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (42000, 0, 420, 'INPUT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (42005, 0, 420, 'OUTPUT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (42010, 0, 420, 'REMITTANCE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (43000, 0, 430, 'WITHHOLDING TAX', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (50000, 0, 500, 'BANK LOANS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (60000, 0, 600, 'CAPITAL GRANTS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (60005, 0, 600, 'ACCUMULATED AMORTISATION OF CAPITAL GRANTS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (60010, 0, 600, 'DIVIDEND', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (61000, 0, 610, 'RETAINED EARNINGS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (61005, 0, 610, 'ACCUMULATED SURPLUS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (61010, 0, 610, 'ASSET REVALUATION GAIN / LOSS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (70005, 0, 700, 'GOODS SALES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (70010, 0, 700, 'SERVICE SALES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (70015, 0, 700, 'SALES DISCOUNT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (71000, 0, 710, 'FAIR VALUE GAIN/LOSS IN INVESTMENTS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (71005, 0, 710, 'DONATION', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (71010, 0, 710, 'EXCHANGE GAIN(LOSS)', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (71015, 0, 710, 'REGISTRAR TRAINING FEES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (71020, 0, 710, 'DISPOSAL OF ASSETS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (71025, 0, 710, 'DIVIDEND INCOME', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (71030, 0, 710, 'INTEREST INCOME', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (71035, 0, 710, 'TRAINING, FORUM, MEETINGS and WORKSHOPS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (80000, 0, 800, 'COST OF GOODS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90000, 0, 900, 'BASIC SALARY', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90005, 0, 900, 'LEAVE ALLOWANCES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90010, 0, 900, 'AIRTIME ', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90012, 0, 900, 'TRANSPORT ALLOWANCE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90015, 0, 900, 'REMOTE ACCESS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90020, 0, 900, 'ICEA EMPLOYER PENSION CONTRIBUTION', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90025, 0, 900, 'NSSF EMPLOYER CONTRIBUTION', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90035, 0, 900, 'CAPACITY BUILDING - TRAINING', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90040, 0, 900, 'INTERNSHIP ALLOWANCES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90045, 0, 900, 'BONUSES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90050, 0, 900, 'LEAVE ACCRUAL', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90055, 0, 900, 'WELFARE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90056, 0, 900, 'STAFF WELLFARE: WATER', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90057, 0, 900, 'STAFF WELLFARE: TEA', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90058, 0, 900, 'STAFF WELLFARE: OTHER CONSUMABLES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90060, 0, 900, 'MEDICAL INSURANCE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90065, 0, 900, 'GROUP PERSONAL ACCIDENT AND WIBA', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90070, 0, 900, 'STAFF SATISFACTION SURVEY', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90075, 0, 900, 'GROUP LIFE INSURANCE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90500, 0, 905, 'FIXED LINES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90505, 0, 905, 'CALLING CARDS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90510, 0, 905, 'LEASE LINES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90515, 0, 905, 'REMOTE ACCESS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (90520, 0, 905, 'LEASE LINE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (91000, 0, 910, 'SITTING ALLOWANCES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (91005, 0, 910, 'HONORARIUM', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (91010, 0, 910, 'WORKSHOPS and SEMINARS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (91500, 0, 915, 'CAB FARE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (91505, 0, 915, 'FUEL', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (91510, 0, 915, 'BUS FARE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (91515, 0, 915, 'POSTAGE and BOX RENTAL', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (92000, 0, 920, 'TRAINING', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (92005, 0, 920, 'BUSINESS PROSPECTING', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (92505, 0, 925, 'DIRECTORY LISTING', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (92510, 0, 925, 'COURIER', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (93000, 0, 930, 'IP TRAINING', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (93010, 0, 930, 'COMPUTER SUPPORT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (93500, 0, 935, 'PRINTED MATTER', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (93505, 0, 935, 'PAPER', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (93510, 0, 935, 'OTHER CONSUMABLES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (93515, 0, 935, 'TONER and CATRIDGE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (93520, 0, 935, 'COMPUTER ACCESSORIES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (94010, 0, 940, 'LICENSE FEE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (94015, 0, 940, 'SYSTEM SUPPORT FEES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (94500, 0, 945, 'FURNITURE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (94505, 0, 945, 'COMPUTERS and EQUIPMENT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (94510, 0, 945, 'JANITORIAL', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95000, 0, 950, 'AUDIT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95005, 0, 950, 'MARKETING AGENCY', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95010, 0, 950, 'ADVERTISING', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95015, 0, 950, 'CONSULTANCY', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95020, 0, 950, 'TAX CONSULTANCY', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95025, 0, 950, 'MARKETING CAMPAIGN', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95030, 0, 950, 'PROMOTIONAL MATERIALS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95035, 0, 950, 'RECRUITMENT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95040, 0, 950, 'ANNUAL GENERAL MEETING', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95045, 0, 950, 'SEMINARS, WORKSHOPS and MEETINGS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95500, 0, 955, 'OFFICE RENT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95505, 0, 955, 'CLEANING', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95510, 0, 955, 'NEWSPAPERS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95515, 0, 955, 'OTHER CONSUMABLES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (95520, 0, 955, 'ADMINISTRATIVE EXPENSES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (96005, 0, 960, 'WEBSITE REVAMPING COSTS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (96505, 0, 965, 'STRATEGIC PLANNING', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (96510, 0, 965, 'MONITORING and EVALUATION', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (97000, 0, 970, 'COMPUTERS and EQUIPMENT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (97005, 0, 970, 'FURNITURE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (97010, 0, 970, 'AMMORTISATION OF INTANGIBLE ASSETS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (97500, 0, 975, 'CORPORATE SOCIAL INVESTMENT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (97505, 0, 975, 'DONATION', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98000, 0, 980, 'LEDGER FEES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98005, 0, 980, 'BOUNCED CHEQUE CHARGES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98010, 0, 980, 'OTHER FEES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98015, 0, 980, 'SALARY TRANSFERS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98020, 0, 980, 'UPCOUNTRY CHEQUES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98025, 0, 980, 'SAFETY DEPOSIT BOX', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98030, 0, 980, 'MPESA TRANSFERS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98035, 0, 980, 'CUSTODY FEES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98040, 0, 980, 'PROFESSIONAL FEES: MANAGEMENT FEES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98500, 0, 985, 'EXCISE DUTY', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98505, 0, 985, 'FINES and PENALTIES', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98510, 0, 985, 'CORPORATE TAX', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (98515, 0, 985, 'FRINGE BENEFIT TAX', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (99000, 0, 990, 'ALL RISKS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (99005, 0, 990, 'FIRE and PERILS', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (99010, 0, 990, 'BURGLARY', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (99015, 0, 990, 'COMPUTER POLICY', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (99500, 0, 995, 'BAD DEBTS WRITTEN OFF', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (99505, 0, 995, 'PURCHASE DISCOUNT', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (99510, 0, 995, 'COST OF GOODS SOLD (COGS)', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (99515, 0, 995, 'PURCHASE PRICE VARIANCE', false, true, NULL);
INSERT INTO accounts (account_id, org_id, account_type_id, account_name, is_header, is_active, details) VALUES (99999, 0, 995, 'SURPLUS/DEFICIT', false, true, NULL);


--
-- Data for Name: accounts_class; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO accounts_class (accounts_class_id, org_id, chat_type_id, chat_type_name, accounts_class_name, details) VALUES (10, 0, 1, 'ASSETS', 'FIXED ASSETS', NULL);
INSERT INTO accounts_class (accounts_class_id, org_id, chat_type_id, chat_type_name, accounts_class_name, details) VALUES (20, 0, 1, 'ASSETS', 'INTANGIBLE ASSETS', NULL);
INSERT INTO accounts_class (accounts_class_id, org_id, chat_type_id, chat_type_name, accounts_class_name, details) VALUES (30, 0, 1, 'ASSETS', 'CURRENT ASSETS', NULL);
INSERT INTO accounts_class (accounts_class_id, org_id, chat_type_id, chat_type_name, accounts_class_name, details) VALUES (40, 0, 2, 'LIABILITIES', 'CURRENT LIABILITIES', NULL);
INSERT INTO accounts_class (accounts_class_id, org_id, chat_type_id, chat_type_name, accounts_class_name, details) VALUES (50, 0, 2, 'LIABILITIES', 'LONG TERM LIABILITIES', NULL);
INSERT INTO accounts_class (accounts_class_id, org_id, chat_type_id, chat_type_name, accounts_class_name, details) VALUES (60, 0, 3, 'EQUITY', 'EQUITY AND RESERVES', NULL);
INSERT INTO accounts_class (accounts_class_id, org_id, chat_type_id, chat_type_name, accounts_class_name, details) VALUES (70, 0, 4, 'REVENUE', 'REVENUE AND OTHER INCOME', NULL);
INSERT INTO accounts_class (accounts_class_id, org_id, chat_type_id, chat_type_name, accounts_class_name, details) VALUES (80, 0, 5, 'COST OF REVENUE', 'COST OF REVENUE', NULL);
INSERT INTO accounts_class (accounts_class_id, org_id, chat_type_id, chat_type_name, accounts_class_name, details) VALUES (90, 0, 6, 'EXPENSES', 'EXPENSES', NULL);


--
-- Data for Name: address; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO address (address_id, address_type_id, sys_country_id, org_id, address_name, table_name, table_id, post_office_box, postal_code, premises, street, town, phone_number, extension, mobile, fax, email, website, is_default, first_password, details, company_name, position_held) VALUES (1, NULL, 'KE', NULL, NULL, 'orgs', 0, '45689', '00100', '16th Floor, view park towers', 'Utalii Lane', 'Nairobi', '+254 (20) 2227100/2243097', NULL, '+254 725 819505 or +254 738 819505', NULL, 'accounts@dewcis.com', 'www.dewcis.com', true, NULL, NULL, NULL, NULL);


--
-- Name: address_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('address_address_id_seq', 1, false);


--
-- Data for Name: address_types; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: address_types_address_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('address_types_address_type_id_seq', 1, false);


--
-- Data for Name: adjustments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (1, 1, 0, 'Sacco Allowance', 1, 0, NULL, NULL, true, true, true, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (2, 1, 0, 'Bonus', 1, 0, NULL, NULL, true, true, true, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (11, 1, 0, 'SACCO', 2, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (12, 1, 0, 'HELB', 2, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (13, 1, 0, 'Rent Payment', 2, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (21, 1, 0, 'Travel', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (22, 1, 0, 'Communcation', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (23, 1, 0, 'Tools', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (24, 1, 0, 'Payroll Cost', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (25, 1, 0, 'Health Insurance', 3, 0, NULL, NULL, true, true, false, false, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (26, 1, 0, 'GPA Insurance', 3, 0, NULL, NULL, true, true, false, false, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (27, 1, 0, 'Accomodation', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (28, 1, 0, 'Avenue Health Care', 3, 0, NULL, NULL, true, true, false, false, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (29, 1, 0, 'Maternety Cost', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (30, 1, 0, 'Health care claims', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (31, 1, 0, 'Trainining', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);
INSERT INTO adjustments (adjustment_id, currency_id, org_id, adjustment_name, adjustment_type, adjustment_order, earning_code, formural, monthly_update, in_payroll, in_tax, visible, running_balance, reduce_balance, tax_reduction_ps, tax_relief_ps, tax_max_allowed, account_number, details) VALUES (32, 1, 0, 'per diem', 3, 0, NULL, NULL, true, true, false, true, false, false, 0, 0, 0, NULL, NULL);


--
-- Name: adjustments_adjustment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('adjustments_adjustment_id_seq', 32, true);


--
-- Data for Name: advance_deductions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: advance_deductions_advance_deduction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('advance_deductions_advance_deduction_id_seq', 1, false);


--
-- Data for Name: amortisation; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: amortisation_amortisation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('amortisation_amortisation_id_seq', 1, false);


--
-- Data for Name: applicants; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO applicants (entity_id, disability_id, org_id, person_title, surname, first_name, middle_name, applicant_email, applicant_phone, date_of_birth, gender, nationality, marital_status, picture_file, identity_card, language, field_of_study, interests, objective, details) VALUES (8, NULL, 0, NULL, 'Joseph', 'Kamau', 'Karanja', 'joseph.kamau@gmail.com', NULL, '1974-07-05', 'M', 'KE', 'M', NULL, '79798797998', 'English', NULL, 'Programming, study, novels', 'Career development', NULL);
INSERT INTO applicants (entity_id, disability_id, org_id, person_title, surname, first_name, middle_name, applicant_email, applicant_phone, date_of_birth, gender, nationality, marital_status, picture_file, identity_card, language, field_of_study, interests, objective, details) VALUES (9, NULL, 0, NULL, 'Gichangi', 'Dennis', 'Wachira', 'dennis.aaron@gmail.com', NULL, '1979-03-29', 'M', 'KE', 'M', NULL, '7878787', 'English', NULL, NULL, NULL, NULL);


--
-- Data for Name: applications; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: applications_application_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('applications_application_id_seq', 1, false);


--
-- Data for Name: approval_checklists; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: approval_checklists_approval_checklist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('approval_checklists_approval_checklist_id_seq', 1, false);


--
-- Data for Name: approvals; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: approvals_approval_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('approvals_approval_id_seq', 1, false);


--
-- Data for Name: asset_movement; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: asset_movement_asset_movement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('asset_movement_asset_movement_id_seq', 1, false);


--
-- Data for Name: asset_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: asset_types_asset_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('asset_types_asset_type_id_seq', 1, false);


--
-- Data for Name: asset_valuations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: asset_valuations_asset_valuation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('asset_valuations_asset_valuation_id_seq', 1, false);


--
-- Data for Name: assets; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: assets_asset_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('assets_asset_id_seq', 1, false);


--
-- Data for Name: attendance; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: attendance_attendance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('attendance_attendance_id_seq', 1, false);


--
-- Data for Name: bank_accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO bank_accounts (bank_account_id, org_id, bank_branch_id, account_id, currency_id, bank_account_name, bank_account_number, narrative, is_default, is_active, details) VALUES (0, 0, 0, 33000, 1, 'Cash Account', NULL, NULL, true, true, NULL);


--
-- Name: bank_accounts_bank_account_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('bank_accounts_bank_account_id_seq', 1, false);


--
-- Data for Name: bank_branch; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO bank_branch (bank_branch_id, bank_id, org_id, bank_branch_name, bank_branch_code, narrative) VALUES (0, 0, 0, 'Cash', NULL, NULL);


--
-- Name: bank_branch_bank_branch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('bank_branch_bank_branch_id_seq', 1, false);


--
-- Data for Name: banks; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO banks (bank_id, sys_country_id, org_id, bank_name, bank_code, swift_code, sort_code, narrative) VALUES (0, NULL, 0, 'Cash', NULL, NULL, NULL, NULL);


--
-- Name: banks_bank_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('banks_bank_id_seq', 1, false);


--
-- Data for Name: bidders; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: bidders_bidder_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('bidders_bidder_id_seq', 1, false);


--
-- Data for Name: bio_imports1; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: bio_imports1_bio_imports1_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('bio_imports1_bio_imports1_id_seq', 1, false);


--
-- Data for Name: budget_lines; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: budget_lines_budget_line_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('budget_lines_budget_line_id_seq', 1, false);


--
-- Data for Name: budgets; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: budgets_budget_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('budgets_budget_id_seq', 1, false);


--
-- Data for Name: career_development; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: career_development_career_development_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('career_development_career_development_id_seq', 1, false);


--
-- Data for Name: case_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: case_types_case_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('case_types_case_type_id_seq', 1, false);


--
-- Data for Name: casual_application; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: casual_application_casual_application_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('casual_application_casual_application_id_seq', 1, false);


--
-- Data for Name: casual_category; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: casual_category_casual_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('casual_category_casual_category_id_seq', 1, false);


--
-- Data for Name: casuals; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: casuals_casual_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('casuals_casual_id_seq', 1, false);


--
-- Data for Name: checklists; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: checklists_checklist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('checklists_checklist_id_seq', 1, false);


--
-- Data for Name: claim_details; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: claim_details_claim_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('claim_details_claim_detail_id_seq', 1, false);


--
-- Data for Name: claim_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: claim_types_claim_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('claim_types_claim_type_id_seq', 1, false);


--
-- Data for Name: claims; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: claims_claim_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('claims_claim_id_seq', 1, false);


--
-- Data for Name: contract_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO contract_status (contract_status_id, org_id, contract_status_name, details) VALUES (1, NULL, 'Active', NULL);
INSERT INTO contract_status (contract_status_id, org_id, contract_status_name, details) VALUES (2, NULL, 'Resigned', NULL);
INSERT INTO contract_status (contract_status_id, org_id, contract_status_name, details) VALUES (3, NULL, 'Deceased', NULL);
INSERT INTO contract_status (contract_status_id, org_id, contract_status_name, details) VALUES (4, NULL, 'Terminated', NULL);
INSERT INTO contract_status (contract_status_id, org_id, contract_status_name, details) VALUES (5, NULL, 'Transferred', NULL);


--
-- Name: contract_status_contract_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('contract_status_contract_status_id_seq', 5, true);


--
-- Data for Name: contract_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: contract_types_contract_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('contract_types_contract_type_id_seq', 1, false);


--
-- Data for Name: contracts; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: contracts_contract_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('contracts_contract_id_seq', 1, false);


--
-- Data for Name: currency; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO currency (currency_id, currency_name, currency_symbol, org_id) VALUES (1, 'Kenya Shillings', 'KES', 0);
INSERT INTO currency (currency_id, currency_name, currency_symbol, org_id) VALUES (2, 'US Dollar', 'USD', 0);
INSERT INTO currency (currency_id, currency_name, currency_symbol, org_id) VALUES (3, 'British Pound', 'BPD', 0);
INSERT INTO currency (currency_id, currency_name, currency_symbol, org_id) VALUES (4, 'Euro', 'ERO', 0);


--
-- Name: currency_currency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('currency_currency_id_seq', 4, true);


--
-- Data for Name: currency_rates; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO currency_rates (currency_rate_id, currency_id, org_id, exchange_date, exchange_rate) VALUES (0, 1, 0, '2015-04-07', 1);


--
-- Name: currency_rates_currency_rate_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('currency_rates_currency_rate_id_seq', 1, false);


--
-- Data for Name: cv_projects; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: cv_projects_cv_projectid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('cv_projects_cv_projectid_seq', 1, false);


--
-- Data for Name: cv_seminars; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: cv_seminars_cv_seminar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('cv_seminars_cv_seminar_id_seq', 1, false);


--
-- Data for Name: day_ledgers; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: day_ledgers_day_ledger_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('day_ledgers_day_ledger_id_seq', 1, false);


--
-- Data for Name: default_accounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO default_accounts (default_account_id, org_id, account_id, narrative) VALUES (1, 0, 99999, 'SURPLUS/DEFICIT ACCOUNT');
INSERT INTO default_accounts (default_account_id, org_id, account_id, narrative) VALUES (2, 0, 61000, 'RETAINED EARNINGS ACCOUNT');


--
-- Data for Name: default_adjustments; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: default_adjustments_default_adjustment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('default_adjustments_default_adjustment_id_seq', 1, false);


--
-- Data for Name: default_banking; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: default_banking_default_banking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('default_banking_default_banking_id_seq', 1, false);


--
-- Data for Name: default_tax_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (1, 2, 3, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (2, 2, 2, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (3, 2, 1, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (4, 3, 3, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (5, 3, 2, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (6, 3, 1, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (7, 4, 3, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (8, 4, 2, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (9, 4, 1, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (10, 5, 3, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (11, 5, 2, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (12, 5, 1, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (13, 6, 3, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (14, 6, 2, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (15, 6, 1, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (16, 7, 3, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (17, 7, 2, 0, NULL, NULL, 0, true);
INSERT INTO default_tax_types (default_tax_type_id, entity_id, tax_type_id, org_id, tax_identification, narrative, additional, active) VALUES (18, 7, 1, 0, NULL, NULL, 0, true);


--
-- Name: default_tax_types_default_tax_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('default_tax_types_default_tax_type_id_seq', 18, true);


--
-- Data for Name: define_phases; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: define_phases_define_phase_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('define_phases_define_phase_id_seq', 1, false);


--
-- Data for Name: define_tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: define_tasks_define_task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('define_tasks_define_task_id_seq', 1, false);


--
-- Data for Name: department_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO department_roles (department_role_id, department_id, ln_department_role_id, org_id, department_role_name, active, job_description, job_requirements, duties, performance_measures, details) VALUES (0, 0, 0, 0, 'Chair Person', true, NULL, NULL, NULL, NULL, NULL);
INSERT INTO department_roles (department_role_id, department_id, ln_department_role_id, org_id, department_role_name, active, job_description, job_requirements, duties, performance_measures, details) VALUES (1, 0, 0, 0, 'Chief Executive Officer', true, '- Defining short term and long term corporate strategies and objectives
- Direct overall company operations ', NULL, '- Develop and control strategic relationships with third-party companies
- Guide the development of client specific systems
- Provide leadership and monitor team performance and individual staff performance ', NULL, NULL);
INSERT INTO department_roles (department_role_id, department_id, ln_department_role_id, org_id, department_role_name, active, job_description, job_requirements, duties, performance_measures, details) VALUES (2, 1, 0, 0, 'Director, Human Resources', true, '- To direct and guide projects support services
- Train end client users 
- Provide leadership and monitor team performance and individual staff performance ', NULL, NULL, NULL, NULL);
INSERT INTO department_roles (department_role_id, department_id, ln_department_role_id, org_id, department_role_name, active, job_description, job_requirements, duties, performance_measures, details) VALUES (3, 2, 0, 0, 'Director, Sales and Marketing', true, '- To direct and guide in systems and products development.
- Provide leadership and monitor team performance and individual staff performance ', NULL, NULL, NULL, NULL);
INSERT INTO department_roles (department_role_id, department_id, ln_department_role_id, org_id, department_role_name, active, job_description, job_requirements, duties, performance_measures, details) VALUES (4, 3, 0, 0, 'Director, Finance', true, '- To direct and guide projects implementation
- Train end client users 
- Provide leadership and monitor team performance and individual staff performance ', NULL, NULL, NULL, NULL);


--
-- Name: department_roles_department_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('department_roles_department_role_id_seq', 9, true);


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO departments (department_id, ln_department_id, org_id, department_name, active, petty_cash, description, duties, reports, details) VALUES (0, 0, 0, 'Board of Directors', true, false, NULL, NULL, NULL, NULL);
INSERT INTO departments (department_id, ln_department_id, org_id, department_name, active, petty_cash, description, duties, reports, details) VALUES (1, 0, 0, 'Human Resources and Administration', true, false, NULL, NULL, NULL, NULL);
INSERT INTO departments (department_id, ln_department_id, org_id, department_name, active, petty_cash, description, duties, reports, details) VALUES (2, 0, 0, 'Sales and Marketing', true, false, NULL, NULL, NULL, NULL);
INSERT INTO departments (department_id, ln_department_id, org_id, department_name, active, petty_cash, description, duties, reports, details) VALUES (3, 0, 0, 'Finance', true, false, NULL, NULL, NULL, NULL);
INSERT INTO departments (department_id, ln_department_id, org_id, department_name, active, petty_cash, description, duties, reports, details) VALUES (4, 4, 0, 'Procurement', true, false, NULL, NULL, NULL, NULL);


--
-- Name: departments_department_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('departments_department_id_seq', 5, true);


--
-- Data for Name: disability; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: disability_disability_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('disability_disability_id_seq', 1, false);


--
-- Data for Name: education; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: education_class; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO education_class (education_class_id, org_id, education_class_name, details) VALUES (1, 0, 'Primary School', NULL);
INSERT INTO education_class (education_class_id, org_id, education_class_name, details) VALUES (2, 0, 'Secondary School', NULL);
INSERT INTO education_class (education_class_id, org_id, education_class_name, details) VALUES (3, 0, 'High School', NULL);
INSERT INTO education_class (education_class_id, org_id, education_class_name, details) VALUES (4, 0, 'Certificate', NULL);
INSERT INTO education_class (education_class_id, org_id, education_class_name, details) VALUES (5, 0, 'Diploma', NULL);
INSERT INTO education_class (education_class_id, org_id, education_class_name, details) VALUES (6, 0, 'Profesional Qualifications', NULL);
INSERT INTO education_class (education_class_id, org_id, education_class_name, details) VALUES (7, 0, 'Higher Diploma', NULL);
INSERT INTO education_class (education_class_id, org_id, education_class_name, details) VALUES (8, 0, 'Under Graduate', NULL);
INSERT INTO education_class (education_class_id, org_id, education_class_name, details) VALUES (9, 0, 'Post Graduate', NULL);


--
-- Name: education_class_education_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('education_class_education_class_id_seq', 9, true);


--
-- Name: education_education_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('education_education_id_seq', 1, false);


--
-- Data for Name: employee_adjustments; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_adjustments_employee_adjustment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_adjustments_employee_adjustment_id_seq', 1, false);


--
-- Data for Name: employee_advances; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_advances_employee_advance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_advances_employee_advance_id_seq', 1, false);


--
-- Data for Name: employee_banking; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_banking_default_banking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_banking_default_banking_id_seq', 1, false);


--
-- Data for Name: employee_cases; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_cases_employee_case_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_cases_employee_case_id_seq', 1, false);


--
-- Data for Name: employee_leave; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_leave_employee_leave_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_leave_employee_leave_id_seq', 1, false);


--
-- Data for Name: employee_leave_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_leave_types_employee_leave_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_leave_types_employee_leave_type_id_seq', 1, false);


--
-- Data for Name: employee_month; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_month_employee_month_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_month_employee_month_id_seq', 1, false);


--
-- Data for Name: employee_objectives; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_objectives_employee_objective_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_objectives_employee_objective_id_seq', 1, false);


--
-- Data for Name: employee_overtime; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_overtime_employee_overtime_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_overtime_employee_overtime_id_seq', 1, false);


--
-- Data for Name: employee_per_diem; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_per_diem_employee_per_diem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_per_diem_employee_per_diem_id_seq', 1, false);


--
-- Data for Name: employee_tax_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_tax_types_employee_tax_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_tax_types_employee_tax_type_id_seq', 1, false);


--
-- Data for Name: employee_trainings; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employee_trainings_employee_training_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_trainings_employee_training_id_seq', 1, false);


--
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO employees (entity_id, department_role_id, bank_branch_id, disability_id, employee_id, pay_scale_id, pay_scale_step_id, pay_group_id, location_id, currency_id, org_id, person_title, surname, first_name, middle_name, date_of_birth, gender, phone, nationality, nation_of_birth, place_of_birth, marital_status, appointment_date, current_appointment, exit_date, contract, contract_period, employment_terms, identity_card, basic_salary, bank_account, picture_file, active, language, desg_code, inc_mth, previous_sal_point, current_sal_point, halt_point, height, weight, blood_group, allergies, field_of_study, interests, objective, details) VALUES (2, 2, 0, NULL, '5628', 0, NULL, 0, 0, 1, 0, NULL, 'Patibandla', 'Ramya', 'sree', '1990-10-15', 'F', NULL, 'IN', NULL, NULL, 'S', '2012-02-09', NULL, NULL, true, 2, 'Full Time', 'Passport', 5000, '1234567890', NULL, true, 'English', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO employees (entity_id, department_role_id, bank_branch_id, disability_id, employee_id, pay_scale_id, pay_scale_step_id, pay_group_id, location_id, currency_id, org_id, person_title, surname, first_name, middle_name, date_of_birth, gender, phone, nationality, nation_of_birth, place_of_birth, marital_status, appointment_date, current_appointment, exit_date, contract, contract_period, employment_terms, identity_card, basic_salary, bank_account, picture_file, active, language, desg_code, inc_mth, previous_sal_point, current_sal_point, halt_point, height, weight, blood_group, allergies, field_of_study, interests, objective, details) VALUES (3, 3, 0, NULL, '5513', 0, NULL, 0, 0, 1, 0, NULL, 'Pusapati', 'Varma', 'Narasimha', '1973-10-12', 'M', NULL, 'IN', NULL, NULL, 'M', '2011-08-29', NULL, NULL, true, 2, 'Full Time', 'Passport', 35000, '1234567890', '4pic.png', true, 'English', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO employees (entity_id, department_role_id, bank_branch_id, disability_id, employee_id, pay_scale_id, pay_scale_step_id, pay_group_id, location_id, currency_id, org_id, person_title, surname, first_name, middle_name, date_of_birth, gender, phone, nationality, nation_of_birth, place_of_birth, marital_status, appointment_date, current_appointment, exit_date, contract, contract_period, employment_terms, identity_card, basic_salary, bank_account, picture_file, active, language, desg_code, inc_mth, previous_sal_point, current_sal_point, halt_point, height, weight, blood_group, allergies, field_of_study, interests, objective, details) VALUES (4, 4, 0, NULL, '2512', 0, NULL, 0, 0, 1, 0, NULL, 'Kamanda', 'Edwin', 'Geke', '1982-05-06', 'M', NULL, 'KE', NULL, NULL, 'S', '2013-02-08', NULL, '2013-08-10', false, 12, NULL, 'erweewr', 20000, '22365336142', NULL, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO employees (entity_id, department_role_id, bank_branch_id, disability_id, employee_id, pay_scale_id, pay_scale_step_id, pay_group_id, location_id, currency_id, org_id, person_title, surname, first_name, middle_name, date_of_birth, gender, phone, nationality, nation_of_birth, place_of_birth, marital_status, appointment_date, current_appointment, exit_date, contract, contract_period, employment_terms, identity_card, basic_salary, bank_account, picture_file, active, language, desg_code, inc_mth, previous_sal_point, current_sal_point, halt_point, height, weight, blood_group, allergies, field_of_study, interests, objective, details) VALUES (5, 4, 0, NULL, '2592', 0, NULL, 0, 0, 1, 0, NULL, 'Kamau', 'Joseph', 'Wanjoki', '1977-10-16', 'M', NULL, 'KE', NULL, NULL, 'M', '2012-10-16', NULL, '2012-11-01', false, 0, NULL, '8098098098', 30000, '980809809', NULL, true, 'English', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO employees (entity_id, department_role_id, bank_branch_id, disability_id, employee_id, pay_scale_id, pay_scale_step_id, pay_group_id, location_id, currency_id, org_id, person_title, surname, first_name, middle_name, date_of_birth, gender, phone, nationality, nation_of_birth, place_of_birth, marital_status, appointment_date, current_appointment, exit_date, contract, contract_period, employment_terms, identity_card, basic_salary, bank_account, picture_file, active, language, desg_code, inc_mth, previous_sal_point, current_sal_point, halt_point, height, weight, blood_group, allergies, field_of_study, interests, objective, details) VALUES (6, 2, 0, NULL, '8783', 0, NULL, 0, 0, 1, 0, NULL, 'blackshamrat', 'Sazzadur ', 'Rahman', '1993-10-08', 'M', NULL, 'BD', NULL, NULL, 'S', '2013-10-08', NULL, NULL, false, 0, NULL, '269250', 116500, '101-105-12270', NULL, true, 'English , Bangla', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO employees (entity_id, department_role_id, bank_branch_id, disability_id, employee_id, pay_scale_id, pay_scale_step_id, pay_group_id, location_id, currency_id, org_id, person_title, surname, first_name, middle_name, date_of_birth, gender, phone, nationality, nation_of_birth, place_of_birth, marital_status, appointment_date, current_appointment, exit_date, contract, contract_period, employment_terms, identity_card, basic_salary, bank_account, picture_file, active, language, desg_code, inc_mth, previous_sal_point, current_sal_point, halt_point, height, weight, blood_group, allergies, field_of_study, interests, objective, details) VALUES (7, 2, 0, NULL, '7551', 0, NULL, 0, 0, 1, 0, NULL, 'Ondero', 'Stanley', 'Makori', '2012-11-03', 'M', NULL, 'KE', NULL, NULL, 'M', '2013-05-01', NULL, NULL, false, 0, 'Parmanent and pensionable', '25145552', 100000, '0510191137356', NULL, false, 'English', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: employment; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: employment_employment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employment_employment_id_seq', 1, false);


--
-- Data for Name: entity_subscriptions; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO entity_subscriptions (entity_subscription_id, entity_type_id, entity_id, subscription_level_id, org_id, details) VALUES (0, 0, 0, 0, 0, NULL);
INSERT INTO entity_subscriptions (entity_subscription_id, entity_type_id, entity_id, subscription_level_id, org_id, details) VALUES (1, 0, 1, 0, 0, NULL);
INSERT INTO entity_subscriptions (entity_subscription_id, entity_type_id, entity_id, subscription_level_id, org_id, details) VALUES (2, 1, 2, 0, 0, NULL);
INSERT INTO entity_subscriptions (entity_subscription_id, entity_type_id, entity_id, subscription_level_id, org_id, details) VALUES (3, 1, 3, 0, 0, NULL);
INSERT INTO entity_subscriptions (entity_subscription_id, entity_type_id, entity_id, subscription_level_id, org_id, details) VALUES (4, 1, 4, 0, 0, NULL);
INSERT INTO entity_subscriptions (entity_subscription_id, entity_type_id, entity_id, subscription_level_id, org_id, details) VALUES (5, 1, 5, 0, 0, NULL);
INSERT INTO entity_subscriptions (entity_subscription_id, entity_type_id, entity_id, subscription_level_id, org_id, details) VALUES (6, 1, 6, 0, 0, NULL);
INSERT INTO entity_subscriptions (entity_subscription_id, entity_type_id, entity_id, subscription_level_id, org_id, details) VALUES (7, 1, 7, 0, 0, NULL);
INSERT INTO entity_subscriptions (entity_subscription_id, entity_type_id, entity_id, subscription_level_id, org_id, details) VALUES (8, 4, 8, 0, 0, NULL);
INSERT INTO entity_subscriptions (entity_subscription_id, entity_type_id, entity_id, subscription_level_id, org_id, details) VALUES (9, 4, 9, 0, 0, NULL);


--
-- Name: entity_subscriptions_entity_subscription_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('entity_subscriptions_entity_subscription_id_seq', 9, true);


--
-- Data for Name: entity_types; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO entity_types (entity_type_id, org_id, entity_type_name, entity_role, use_key, start_view, group_email, description, details) VALUES (0, 0, 'Users', 'user', 0, NULL, NULL, NULL, NULL);
INSERT INTO entity_types (entity_type_id, org_id, entity_type_name, entity_role, use_key, start_view, group_email, description, details) VALUES (1, 0, 'Staff', 'staff', 0, NULL, NULL, NULL, NULL);
INSERT INTO entity_types (entity_type_id, org_id, entity_type_name, entity_role, use_key, start_view, group_email, description, details) VALUES (2, 0, 'Client', 'client', 0, NULL, NULL, NULL, NULL);
INSERT INTO entity_types (entity_type_id, org_id, entity_type_name, entity_role, use_key, start_view, group_email, description, details) VALUES (3, 0, 'Supplier', 'supplier', 0, NULL, NULL, NULL, NULL);
INSERT INTO entity_types (entity_type_id, org_id, entity_type_name, entity_role, use_key, start_view, group_email, description, details) VALUES (4, 0, 'Applicant', 'applicant', 0, '10:0', NULL, NULL, NULL);


--
-- Name: entity_types_entity_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('entity_types_entity_type_id_seq', 3, true);


--
-- Data for Name: entitys; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO entitys (entity_id, entity_type_id, org_id, entity_name, user_name, primary_email, primary_telephone, super_user, entity_leader, no_org, function_role, date_enroled, is_active, entity_password, first_password, new_password, start_url, is_picked, details, attention, account_id, bio_code) VALUES (0, 0, 0, 'root', 'root', 'root@localhost', NULL, true, true, false, NULL, '2015-04-07 10:15:20.55013', true, 'b6f0038dfd42f8aa6ca25354cd2e3660', 'baraza', NULL, NULL, false, NULL, NULL, NULL, NULL);
INSERT INTO entitys (entity_id, entity_type_id, org_id, entity_name, user_name, primary_email, primary_telephone, super_user, entity_leader, no_org, function_role, date_enroled, is_active, entity_password, first_password, new_password, start_url, is_picked, details, attention, account_id, bio_code) VALUES (1, 0, 0, 'repository', 'repository', 'repository@localhost', NULL, false, true, false, NULL, '2015-04-07 10:15:20.55013', true, 'b6f0038dfd42f8aa6ca25354cd2e3660', 'baraza', NULL, NULL, false, NULL, NULL, NULL, NULL);
INSERT INTO entitys (entity_id, entity_type_id, org_id, entity_name, user_name, primary_email, primary_telephone, super_user, entity_leader, no_org, function_role, date_enroled, is_active, entity_password, first_password, new_password, start_url, is_picked, details, attention, account_id, bio_code) VALUES (2, 1, 0, 'Patibandla Ramya sree', 'dc.ramya.patibandla', NULL, NULL, false, false, false, 'staff', '2015-04-20 11:37:21.620761', true, 'b6f0038dfd42f8aa6ca25354cd2e3660', 'baraza', NULL, NULL, false, NULL, NULL, NULL, NULL);
INSERT INTO entitys (entity_id, entity_type_id, org_id, entity_name, user_name, primary_email, primary_telephone, super_user, entity_leader, no_org, function_role, date_enroled, is_active, entity_password, first_password, new_password, start_url, is_picked, details, attention, account_id, bio_code) VALUES (3, 1, 0, 'Pusapati Varma Narasimha', 'dc.varma.pusapati', NULL, NULL, false, false, false, 'staff', '2015-04-20 11:37:21.683656', true, 'b6f0038dfd42f8aa6ca25354cd2e3660', 'baraza', NULL, NULL, false, NULL, NULL, NULL, NULL);
INSERT INTO entitys (entity_id, entity_type_id, org_id, entity_name, user_name, primary_email, primary_telephone, super_user, entity_leader, no_org, function_role, date_enroled, is_active, entity_password, first_password, new_password, start_url, is_picked, details, attention, account_id, bio_code) VALUES (4, 1, 0, 'Kamanda Edwin Geke', 'dc.edwin.kamanda', NULL, NULL, false, false, false, 'staff', '2015-04-20 11:37:21.694698', true, 'b6f0038dfd42f8aa6ca25354cd2e3660', 'baraza', NULL, NULL, false, NULL, NULL, NULL, NULL);
INSERT INTO entitys (entity_id, entity_type_id, org_id, entity_name, user_name, primary_email, primary_telephone, super_user, entity_leader, no_org, function_role, date_enroled, is_active, entity_password, first_password, new_password, start_url, is_picked, details, attention, account_id, bio_code) VALUES (5, 1, 0, 'Kamau Joseph Wanjoki', 'dc.joseph.kamau', NULL, NULL, false, false, false, 'staff', '2015-04-20 11:37:21.705952', true, 'b6f0038dfd42f8aa6ca25354cd2e3660', 'baraza', NULL, NULL, false, NULL, NULL, NULL, NULL);
INSERT INTO entitys (entity_id, entity_type_id, org_id, entity_name, user_name, primary_email, primary_telephone, super_user, entity_leader, no_org, function_role, date_enroled, is_active, entity_password, first_password, new_password, start_url, is_picked, details, attention, account_id, bio_code) VALUES (6, 1, 0, 'blackshamrat Sazzadur  Rahman', 'dc.sazzadur .blackshamrat', NULL, NULL, false, false, false, 'staff', '2015-04-20 11:37:21.717123', true, 'b6f0038dfd42f8aa6ca25354cd2e3660', 'baraza', NULL, NULL, false, NULL, NULL, NULL, NULL);
INSERT INTO entitys (entity_id, entity_type_id, org_id, entity_name, user_name, primary_email, primary_telephone, super_user, entity_leader, no_org, function_role, date_enroled, is_active, entity_password, first_password, new_password, start_url, is_picked, details, attention, account_id, bio_code) VALUES (7, 1, 0, 'Ondero Stanley Makori', 'dc.stanley.ondero', NULL, NULL, false, false, false, 'staff', '2015-04-20 11:37:21.728216', true, 'b6f0038dfd42f8aa6ca25354cd2e3660', 'baraza', NULL, NULL, false, NULL, NULL, NULL, NULL);
INSERT INTO entitys (entity_id, entity_type_id, org_id, entity_name, user_name, primary_email, primary_telephone, super_user, entity_leader, no_org, function_role, date_enroled, is_active, entity_password, first_password, new_password, start_url, is_picked, details, attention, account_id, bio_code) VALUES (8, 4, 0, 'Joseph Kamau Karanja', 'joseph.kamau@gmail.com', 'joseph.kamau@gmail.com', NULL, false, false, false, 'applicant', '2015-04-20 11:37:21.750954', true, 'b6f0038dfd42f8aa6ca25354cd2e3660', 'baraza', NULL, NULL, false, NULL, NULL, NULL, NULL);
INSERT INTO entitys (entity_id, entity_type_id, org_id, entity_name, user_name, primary_email, primary_telephone, super_user, entity_leader, no_org, function_role, date_enroled, is_active, entity_password, first_password, new_password, start_url, is_picked, details, attention, account_id, bio_code) VALUES (9, 4, 0, 'Gichangi Dennis Wachira', 'dennis.aaron@gmail.com', 'dennis.aaron@gmail.com', NULL, false, false, false, 'applicant', '2015-04-20 11:37:21.761723', true, 'b6f0038dfd42f8aa6ca25354cd2e3660', 'baraza', NULL, NULL, false, NULL, NULL, NULL, NULL);


--
-- Name: entitys_entity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('entitys_entity_id_seq', 9, true);


--
-- Data for Name: entry_forms; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: entry_forms_entry_form_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('entry_forms_entry_form_id_seq', 1, false);


--
-- Data for Name: evaluation_points; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: evaluation_points_evaluation_point_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('evaluation_points_evaluation_point_id_seq', 1, false);


--
-- Data for Name: fields; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: fields_field_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('fields_field_id_seq', 1, false);


--
-- Data for Name: fiscal_years; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: forms; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: forms_form_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('forms_form_id_seq', 1, false);


--
-- Data for Name: gls; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: gls_gl_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('gls_gl_id_seq', 1, false);


--
-- Data for Name: holidays; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: holidays_holiday_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('holidays_holiday_id_seq', 1, false);


--
-- Data for Name: identification_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: identification_types_identification_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('identification_types_identification_type_id_seq', 1, false);


--
-- Data for Name: identifications; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: identifications_identification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('identifications_identification_id_seq', 1, false);


--
-- Data for Name: intake; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: intake_intake_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('intake_intake_id_seq', 1, false);


--
-- Data for Name: interns; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: interns_intern_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('interns_intern_id_seq', 1, false);


--
-- Data for Name: internships; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: internships_internship_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('internships_internship_id_seq', 1, false);


--
-- Data for Name: item_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO item_category (item_category_id, org_id, item_category_name, details) VALUES (1, 0, 'Services', NULL);
INSERT INTO item_category (item_category_id, org_id, item_category_name, details) VALUES (2, 0, 'Goods', NULL);
INSERT INTO item_category (item_category_id, org_id, item_category_name, details) VALUES (3, 0, 'Utilities', NULL);


--
-- Name: item_category_item_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('item_category_item_category_id_seq', 3, true);


--
-- Data for Name: item_units; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO item_units (item_unit_id, org_id, item_unit_name, details) VALUES (1, 0, 'Each', NULL);
INSERT INTO item_units (item_unit_id, org_id, item_unit_name, details) VALUES (2, 0, 'Man Hours', NULL);
INSERT INTO item_units (item_unit_id, org_id, item_unit_name, details) VALUES (3, 0, '100KG', NULL);


--
-- Name: item_units_item_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('item_units_item_unit_id_seq', 3, true);


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: items_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('items_item_id_seq', 1, false);


--
-- Data for Name: job_reviews; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: job_reviews_job_review_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('job_reviews_job_review_id_seq', 1, false);


--
-- Data for Name: journals; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: journals_journal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('journals_journal_id_seq', 1, false);


--
-- Data for Name: kin_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO kin_types (kin_type_id, org_id, kin_type_name, details) VALUES (1, 0, 'Wife', NULL);
INSERT INTO kin_types (kin_type_id, org_id, kin_type_name, details) VALUES (2, 0, 'Husband', NULL);
INSERT INTO kin_types (kin_type_id, org_id, kin_type_name, details) VALUES (3, 0, 'Daughter', NULL);
INSERT INTO kin_types (kin_type_id, org_id, kin_type_name, details) VALUES (4, 0, 'Son', NULL);
INSERT INTO kin_types (kin_type_id, org_id, kin_type_name, details) VALUES (5, 0, 'Mother', NULL);
INSERT INTO kin_types (kin_type_id, org_id, kin_type_name, details) VALUES (6, 0, 'Father', NULL);
INSERT INTO kin_types (kin_type_id, org_id, kin_type_name, details) VALUES (7, 0, 'Brother', NULL);
INSERT INTO kin_types (kin_type_id, org_id, kin_type_name, details) VALUES (8, 0, 'Sister', NULL);
INSERT INTO kin_types (kin_type_id, org_id, kin_type_name, details) VALUES (9, 0, 'Others', NULL);


--
-- Name: kin_types_kin_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('kin_types_kin_type_id_seq', 9, true);


--
-- Data for Name: kins; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: kins_kin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('kins_kin_id_seq', 1, false);


--
-- Data for Name: lead_items; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: lead_items_lead_item_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('lead_items_lead_item_seq', 1, false);


--
-- Data for Name: leads; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: leads_lead_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('leads_lead_id_seq', 1, false);


--
-- Data for Name: leave_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO leave_types (leave_type_id, org_id, leave_type_name, allowed_leave_days, leave_days_span, use_type, month_quota, initial_days, maximum_carry, include_holiday, include_mon, include_tue, include_wed, include_thu, include_fri, include_sat, include_sun, details) VALUES (0, 0, 'Annual Leave', 21, 7, 0, 0, 0, 0, false, true, true, true, true, true, false, false, NULL);


--
-- Name: leave_types_leave_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('leave_types_leave_type_id_seq', 1, false);


--
-- Data for Name: leave_work_days; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: leave_work_days_leave_work_day_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('leave_work_days_leave_work_day_id_seq', 1, false);


--
-- Data for Name: loan_monthly; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: loan_monthly_loan_month_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('loan_monthly_loan_month_id_seq', 1, false);


--
-- Data for Name: loan_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: loan_types_loan_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('loan_types_loan_type_id_seq', 1, false);


--
-- Data for Name: loans; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: loans_loan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('loans_loan_id_seq', 1, false);


--
-- Data for Name: locations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO locations (location_id, org_id, location_name, details) VALUES (0, 0, 'Main office', NULL);


--
-- Name: locations_location_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('locations_location_id_seq', 1, false);


--
-- Data for Name: objective_details; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: objective_details_objective_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('objective_details_objective_detail_id_seq', 1, false);


--
-- Data for Name: objective_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: objective_types_objective_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('objective_types_objective_type_id_seq', 1, false);


--
-- Data for Name: objectives; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: objectives_objective_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('objectives_objective_id_seq', 1, false);


--
-- Data for Name: orgs; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO orgs (org_id, currency_id, parent_org_id, org_name, org_sufix, is_default, is_active, logo, pin, details, cert_number, vat_number, fixed_budget, invoice_footer, bank_header, bank_address) VALUES (0, 1, NULL, 'Dew CIS Solutions Ltd', 'dc', true, true, 'logo.png', 'P051165288J', NULL, 'C.102554', '0142653A', true, 'Make all payments to : Dew CIS Solutions ltd
Thank you for your Business
We Turn your information into profitability', NULL, NULL);


--
-- Name: orgs_org_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('orgs_org_id_seq', 1, false);


--
-- Data for Name: pay_groups; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO pay_groups (pay_group_id, org_id, pay_group_name, details) VALUES (0, 0, 'Default', NULL);


--
-- Name: pay_groups_pay_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pay_groups_pay_group_id_seq', 1, false);


--
-- Data for Name: pay_scale_steps; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: pay_scale_steps_pay_scale_step_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pay_scale_steps_pay_scale_step_id_seq', 1, false);


--
-- Data for Name: pay_scale_years; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: pay_scale_years_pay_scale_year_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pay_scale_years_pay_scale_year_id_seq', 1, false);


--
-- Data for Name: pay_scales; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO pay_scales (pay_scale_id, currency_id, org_id, pay_scale_name, min_pay, max_pay, details) VALUES (0, NULL, 0, 'Basic', 0, 1000000, NULL);


--
-- Name: pay_scales_pay_scale_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pay_scales_pay_scale_id_seq', 1, false);


--
-- Data for Name: payroll_ledger; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: payroll_ledger_payroll_ledger_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('payroll_ledger_payroll_ledger_id_seq', 1, false);


--
-- Data for Name: pc_allocations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: pc_allocations_pc_allocation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pc_allocations_pc_allocation_id_seq', 1, false);


--
-- Data for Name: pc_banking; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: pc_banking_pc_banking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pc_banking_pc_banking_id_seq', 1, false);


--
-- Data for Name: pc_budget; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: pc_budget_pc_budget_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pc_budget_pc_budget_id_seq', 1, false);


--
-- Data for Name: pc_category; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: pc_category_pc_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pc_category_pc_category_id_seq', 1, false);


--
-- Data for Name: pc_expenditure; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: pc_expenditure_pc_expenditure_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pc_expenditure_pc_expenditure_id_seq', 1, false);


--
-- Data for Name: pc_items; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: pc_items_pc_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pc_items_pc_item_id_seq', 1, false);


--
-- Data for Name: pc_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: pc_types_pc_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('pc_types_pc_type_id_seq', 1, false);


--
-- Data for Name: period_tax_rates; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: period_tax_rates_period_tax_rate_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('period_tax_rates_period_tax_rate_id_seq', 1, false);


--
-- Data for Name: period_tax_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: period_tax_types_period_tax_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('period_tax_types_period_tax_type_id_seq', 1, false);


--
-- Data for Name: periods; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: periods_period_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('periods_period_id_seq', 1, false);


--
-- Data for Name: phases; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: phases_phase_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('phases_phase_id_seq', 1, false);


--
-- Name: picture_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('picture_id_seq', 1, false);


--
-- Data for Name: project_cost; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: project_cost_project_cost_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('project_cost_project_cost_id_seq', 1, false);


--
-- Data for Name: project_locations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: project_locations_job_location_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('project_locations_job_location_id_seq', 1, false);


--
-- Data for Name: project_staff; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: project_staff_costs; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: project_staff_costs_project_staff_cost_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('project_staff_costs_project_staff_cost_id_seq', 1, false);


--
-- Name: project_staff_project_staff_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('project_staff_project_staff_id_seq', 1, false);


--
-- Data for Name: project_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: project_types_project_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('project_types_project_type_id_seq', 1, false);


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: projects_project_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('projects_project_id_seq', 1, false);


--
-- Data for Name: quotations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: quotations_quotation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('quotations_quotation_id_seq', 1, false);


--
-- Data for Name: reporting; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: reporting_reporting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('reporting_reporting_id_seq', 1, false);


--
-- Data for Name: review_category; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: review_category_review_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('review_category_review_category_id_seq', 1, false);


--
-- Data for Name: review_points; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: review_points_review_point_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('review_points_review_point_id_seq', 1, false);


--
-- Data for Name: shift_schedule; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: shift_schedule_shift_schedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('shift_schedule_shift_schedule_id_seq', 1, false);


--
-- Data for Name: shifts; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO shifts (shift_id, org_id, shift_name, shift_hours, details) VALUES (1, 0, 'Day', 8, NULL);
INSERT INTO shifts (shift_id, org_id, shift_name, shift_hours, details) VALUES (2, 0, 'Night', 8, NULL);


--
-- Name: shifts_shift_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('shifts_shift_id_seq', 1, false);


--
-- Data for Name: skill_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO skill_category (skill_category_id, org_id, skill_category_name, details) VALUES (1, 0, 'Hardware', NULL);
INSERT INTO skill_category (skill_category_id, org_id, skill_category_name, details) VALUES (2, 0, 'Operating System', NULL);
INSERT INTO skill_category (skill_category_id, org_id, skill_category_name, details) VALUES (3, 0, 'Software', NULL);
INSERT INTO skill_category (skill_category_id, org_id, skill_category_name, details) VALUES (4, 0, 'Networking', NULL);
INSERT INTO skill_category (skill_category_id, org_id, skill_category_name, details) VALUES (6, 0, 'Servers', NULL);
INSERT INTO skill_category (skill_category_id, org_id, skill_category_name, details) VALUES (8, 0, 'Communication/Messaging Suite', NULL);
INSERT INTO skill_category (skill_category_id, org_id, skill_category_name, details) VALUES (9, 0, 'Voip', NULL);
INSERT INTO skill_category (skill_category_id, org_id, skill_category_name, details) VALUES (10, 0, 'Development', NULL);


--
-- Name: skill_category_skill_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('skill_category_skill_category_id_seq', 10, true);


--
-- Data for Name: skill_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (1, 1, 0, 'Personal Computer', 'Identify the different components of a computer', 'Understand the working of each component', 'Troubleshoot, Diagonize and Repair', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (2, 1, 0, 'Dot Matrix Printer', 'Identify the different components of a computer', 'Understand the working of each component', 'Troubleshoot, Diagonize and Repair', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (3, 1, 0, 'Ticket Printer', 'Identify the different components of a computer', 'Understand the working of each component', 'Troubleshoot, Diagonize and Repair', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (4, 1, 0, 'Hp Printer', 'Identify the different components of a computer', 'Understand the working of each component', 'Troubleshoot, Diagonize and Repair', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (5, 2, 0, 'Dos', 'Installation', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (6, 2, 0, 'Windowsxp', 'Installation', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (7, 2, 0, 'Linux', 'Installation', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (8, 2, 0, 'Solaris Unix', 'Installation', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (10, 3, 0, 'Office', 'Installation, Backup and Recovery', 'Application and Usage', 'Advanced Usage', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (11, 3, 0, 'Browsing', 'Setup ', 'Usage ', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (12, 3, 0, 'Galileo Products', 'Setup ', 'Usage ', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (13, 3, 0, 'Antivirus', 'Setup ', 'Updates and Support', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (9, 3, 0, 'Dialup', 'Installation', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (21, 4, 0, 'Dialup', 'Dialup', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (22, 4, 0, 'Lan', 'Installation ', 'Configuration', 'Troubleshooting and Support', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (23, 4, 0, 'Wan', 'Installation', 'Configuration', 'Configuration', NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (29, 6, 0, 'Samba', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (30, 6, 0, 'Mail', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (31, 6, 0, 'Web', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (32, 6, 0, 'Application ', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (33, 6, 0, 'Identity Management', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (34, 6, 0, 'Network Management   ', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (36, 6, 0, 'Backup And Storage Services', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (37, 8, 0, 'Groupware', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (38, 9, 0, 'Asterix', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (39, 10, 0, 'Database', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (40, 10, 0, 'Design', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (41, 10, 0, 'Baraza', NULL, NULL, NULL, NULL);
INSERT INTO skill_types (skill_type_id, skill_category_id, org_id, skill_type_name, basic, intermediate, advanced, details) VALUES (42, 10, 0, 'Coding Java', NULL, NULL, NULL, NULL);


--
-- Name: skill_types_skill_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('skill_types_skill_type_id_seq', 42, true);


--
-- Data for Name: skills; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: skills_skill_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('skills_skill_id_seq', 1, false);


--
-- Data for Name: stock_lines; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: stock_lines_stock_line_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('stock_lines_stock_line_id_seq', 1, false);


--
-- Data for Name: stocks; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: stocks_stock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('stocks_stock_id_seq', 1, false);


--
-- Data for Name: stores; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: stores_store_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('stores_store_id_seq', 1, false);


--
-- Data for Name: sub_fields; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: sub_fields_sub_field_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sub_fields_sub_field_id_seq', 1, false);


--
-- Data for Name: subscription_levels; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO subscription_levels (subscription_level_id, org_id, subscription_level_name, details) VALUES (0, 0, 'Basic', NULL);
INSERT INTO subscription_levels (subscription_level_id, org_id, subscription_level_name, details) VALUES (1, 0, 'Manager', NULL);
INSERT INTO subscription_levels (subscription_level_id, org_id, subscription_level_name, details) VALUES (2, 0, 'Consumer', NULL);


--
-- Name: subscription_levels_subscription_level_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('subscription_levels_subscription_level_id_seq', 1, false);


--
-- Data for Name: sys_audit_details; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: sys_audit_details_sys_audit_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_audit_details_sys_audit_detail_id_seq', 1, false);


--
-- Data for Name: sys_audit_trail; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: sys_audit_trail_sys_audit_trail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_audit_trail_sys_audit_trail_id_seq', 1, false);


--
-- Data for Name: sys_continents; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO sys_continents (sys_continent_id, sys_continent_name) VALUES ('AF', 'Africa');
INSERT INTO sys_continents (sys_continent_id, sys_continent_name) VALUES ('AS', 'Asia');
INSERT INTO sys_continents (sys_continent_id, sys_continent_name) VALUES ('EU', 'Europe');
INSERT INTO sys_continents (sys_continent_id, sys_continent_name) VALUES ('NA', 'North America');
INSERT INTO sys_continents (sys_continent_id, sys_continent_name) VALUES ('SA', 'South America');
INSERT INTO sys_continents (sys_continent_id, sys_continent_name) VALUES ('OC', 'Oceania');
INSERT INTO sys_continents (sys_continent_id, sys_continent_name) VALUES ('AN', 'Antarctica');


--
-- Data for Name: sys_countrys; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AF', 'AS', 'AFG', '004', NULL, 'Afghanistan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AX', 'EU', 'ALA', '248', NULL, 'Aland Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AL', 'EU', 'ALB', '008', NULL, 'Albania', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('DZ', 'AF', 'DZA', '012', NULL, 'Algeria', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AS', 'OC', 'ASM', '016', NULL, 'American Samoa', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AD', 'EU', 'AND', '020', NULL, 'Andorra', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AO', 'AF', 'AGO', '024', NULL, 'Angola', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AI', 'NA', 'AIA', '660', NULL, 'Anguilla', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AQ', 'AN', 'ATA', '010', NULL, 'Antarctica', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AG', 'NA', 'ATG', '028', NULL, 'Antigua and Barbuda', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AR', 'SA', 'ARG', '032', NULL, 'Argentina', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AM', 'AS', 'ARM', '051', NULL, 'Armenia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AW', 'NA', 'ABW', '533', NULL, 'Aruba', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AU', 'OC', 'AUS', '036', NULL, 'Australia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AT', 'EU', 'AUT', '040', NULL, 'Austria', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AZ', 'AS', 'AZE', '031', NULL, 'Azerbaijan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BS', 'NA', 'BHS', '044', NULL, 'Bahamas', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BH', 'AS', 'BHR', '048', NULL, 'Bahrain', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BD', 'AS', 'BGD', '050', NULL, 'Bangladesh', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BB', 'NA', 'BRB', '052', NULL, 'Barbados', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BY', 'EU', 'BLR', '112', NULL, 'Belarus', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BE', 'EU', 'BEL', '056', NULL, 'Belgium', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BZ', 'NA', 'BLZ', '084', NULL, 'Belize', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BJ', 'AF', 'BEN', '204', NULL, 'Benin', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BM', 'NA', 'BMU', '060', NULL, 'Bermuda', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BT', 'AS', 'BTN', '064', NULL, 'Bhutan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BO', 'SA', 'BOL', '068', NULL, 'Bolivia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BA', 'EU', 'BIH', '070', NULL, 'Bosnia and Herzegovina', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BW', 'AF', 'BWA', '072', NULL, 'Botswana', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BV', 'AN', 'BVT', '074', NULL, 'Bouvet Island', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BR', 'SA', 'BRA', '076', NULL, 'Brazil', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('IO', 'AS', 'IOT', '086', NULL, 'British Indian Ocean Territory', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('VG', 'NA', 'VGB', '092', NULL, 'British Virgin Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BN', 'AS', 'BRN', '096', NULL, 'Brunei Darussalam', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BG', 'EU', 'BGR', '100', NULL, 'Bulgaria', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BF', 'AF', 'BFA', '854', NULL, 'Burkina Faso', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BI', 'AF', 'BDI', '108', NULL, 'Burundi', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('KH', 'AS', 'KHM', '116', NULL, 'Cambodia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CM', 'AF', 'CMR', '120', NULL, 'Cameroon', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CA', 'NA', 'CAN', '124', NULL, 'Canada', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CV', 'AF', 'CPV', '132', NULL, 'Cape Verde', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('KY', 'NA', 'CYM', '136', NULL, 'Cayman Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CF', 'AF', 'CAF', '140', NULL, 'Central African Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TD', 'AF', 'TCD', '148', NULL, 'Chad', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CL', 'SA', 'CHL', '152', NULL, 'Chile', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CN', 'AS', 'CHN', '156', NULL, 'China', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CX', 'AS', 'CXR', '162', NULL, 'Christmas Island', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CC', 'AS', 'CCK', '166', NULL, 'Cocos Keeling Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CO', 'SA', 'COL', '170', NULL, 'Colombia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('KM', 'AF', 'COM', '174', NULL, 'Comoros', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CD', 'AF', 'COD', '180', NULL, 'Democratic Republic of Congo', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CG', 'AF', 'COG', '178', NULL, 'Republic of Congo', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CK', 'OC', 'COK', '184', NULL, 'Cook Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CR', 'NA', 'CRI', '188', NULL, 'Costa Rica', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CI', 'AF', 'CIV', '384', NULL, 'Cote d Ivoire', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('HR', 'EU', 'HRV', '191', NULL, 'Croatia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CU', 'NA', 'CUB', '192', NULL, 'Cuba', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CY', 'AS', 'CYP', '196', NULL, 'Cyprus', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CZ', 'EU', 'CZE', '203', NULL, 'Czech Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('DK', 'EU', 'DNK', '208', NULL, 'Denmark', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('DJ', 'AF', 'DJI', '262', NULL, 'Djibouti', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('DM', 'NA', 'DMA', '212', NULL, 'Dominica', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('DO', 'NA', 'DOM', '214', NULL, 'Dominican Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('EC', 'SA', 'ECU', '218', NULL, 'Ecuador', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('EG', 'AF', 'EGY', '818', NULL, 'Egypt', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SV', 'NA', 'SLV', '222', NULL, 'El Salvador', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GQ', 'AF', 'GNQ', '226', NULL, 'Equatorial Guinea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('ER', 'AF', 'ERI', '232', NULL, 'Eritrea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('EE', 'EU', 'EST', '233', NULL, 'Estonia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('ET', 'AF', 'ETH', '231', NULL, 'Ethiopia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('FO', 'EU', 'FRO', '234', NULL, 'Faroe Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('FK', 'SA', 'FLK', '238', NULL, 'Falkland Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('FJ', 'OC', 'FJI', '242', NULL, 'Fiji', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('FI', 'EU', 'FIN', '246', NULL, 'Finland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('FR', 'EU', 'FRA', '250', NULL, 'France', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GF', 'SA', 'GUF', '254', NULL, 'French Guiana', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PF', 'OC', 'PYF', '258', NULL, 'French Polynesia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TF', 'AN', 'ATF', '260', NULL, 'French Southern Territories', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GA', 'AF', 'GAB', '266', NULL, 'Gabon', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GM', 'AF', 'GMB', '270', NULL, 'Gambia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GE', 'AS', 'GEO', '268', NULL, 'Georgia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('DE', 'EU', 'DEU', '276', NULL, 'Germany', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GH', 'AF', 'GHA', '288', NULL, 'Ghana', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GI', 'EU', 'GIB', '292', NULL, 'Gibraltar', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GR', 'EU', 'GRC', '300', NULL, 'Greece', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GL', 'NA', 'GRL', '304', NULL, 'Greenland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GD', 'NA', 'GRD', '308', NULL, 'Grenada', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GP', 'NA', 'GLP', '312', NULL, 'Guadeloupe', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GU', 'OC', 'GUM', '316', NULL, 'Guam', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GT', 'NA', 'GTM', '320', NULL, 'Guatemala', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GG', 'EU', 'GGY', '831', NULL, 'Guernsey', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GN', 'AF', 'GIN', '324', NULL, 'Guinea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GW', 'AF', 'GNB', '624', NULL, 'Guinea-Bissau', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GY', 'SA', 'GUY', '328', NULL, 'Guyana', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('HT', 'NA', 'HTI', '332', NULL, 'Haiti', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('HM', 'AN', 'HMD', '334', NULL, 'Heard Island and McDonald Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('VA', 'EU', 'VAT', '336', NULL, 'Vatican City State', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('HN', 'NA', 'HND', '340', NULL, 'Honduras', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('HK', 'AS', 'HKG', '344', NULL, 'Hong Kong', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('HU', 'EU', 'HUN', '348', NULL, 'Hungary', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('IS', 'EU', 'ISL', '352', NULL, 'Iceland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('IN', 'AS', 'IND', '356', NULL, 'India', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('ID', 'AS', 'IDN', '360', NULL, 'Indonesia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('IR', 'AS', 'IRN', '364', NULL, 'Iran', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('IQ', 'AS', 'IRQ', '368', NULL, 'Iraq', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('IE', 'EU', 'IRL', '372', NULL, 'Ireland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('IM', 'EU', 'IMN', '833', NULL, 'Isle of Man', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('IL', 'AS', 'ISR', '376', NULL, 'Israel', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('IT', 'EU', 'ITA', '380', NULL, 'Italy', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('JM', 'NA', 'JAM', '388', NULL, 'Jamaica', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('JP', 'AS', 'JPN', '392', NULL, 'Japan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('JE', 'EU', 'JEY', '832', NULL, 'Bailiwick of Jersey', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('JO', 'AS', 'JOR', '400', NULL, 'Jordan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('KZ', 'AS', 'KAZ', '398', NULL, 'Kazakhstan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('KE', 'AF', 'KEN', '404', NULL, 'Kenya', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('KI', 'OC', 'KIR', '296', NULL, 'Kiribati', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('KP', 'AS', 'PRK', '408', NULL, 'North Korea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('KR', 'AS', 'KOR', '410', NULL, 'South Korea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('KW', 'AS', 'KWT', '414', NULL, 'Kuwait', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('KG', 'AS', 'KGZ', '417', NULL, 'Kyrgyz Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('LA', 'AS', 'LAO', '418', NULL, 'Lao Peoples Democratic Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('LV', 'EU', 'LVA', '428', NULL, 'Latvia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('LB', 'AS', 'LBN', '422', NULL, 'Lebanon', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('LS', 'AF', 'LSO', '426', NULL, 'Lesotho', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('LR', 'AF', 'LBR', '430', NULL, 'Liberia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('LY', 'AF', 'LBY', '434', NULL, 'Libyan Arab Jamahiriya', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('LI', 'EU', 'LIE', '438', NULL, 'Liechtenstein', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('LT', 'EU', 'LTU', '440', NULL, 'Lithuania', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('LU', 'EU', 'LUX', '442', NULL, 'Luxembourg', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MO', 'AS', 'MAC', '446', NULL, 'Macao', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MK', 'EU', 'MKD', '807', NULL, 'Macedonia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MG', 'AF', 'MDG', '450', NULL, 'Madagascar', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MW', 'AF', 'MWI', '454', NULL, 'Malawi', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MY', 'AS', 'MYS', '458', NULL, 'Malaysia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MV', 'AS', 'MDV', '462', NULL, 'Maldives', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('ML', 'AF', 'MLI', '466', NULL, 'Mali', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MT', 'EU', 'MLT', '470', NULL, 'Malta', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MH', 'OC', 'MHL', '584', NULL, 'Marshall Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MQ', 'NA', 'MTQ', '474', NULL, 'Martinique', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MR', 'AF', 'MRT', '478', NULL, 'Mauritania', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MU', 'AF', 'MUS', '480', NULL, 'Mauritius', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('YT', 'AF', 'MYT', '175', NULL, 'Mayotte', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MX', 'NA', 'MEX', '484', NULL, 'Mexico', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('FM', 'OC', 'FSM', '583', NULL, 'Micronesia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MD', 'EU', 'MDA', '498', NULL, 'Moldova', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MC', 'EU', 'MCO', '492', NULL, 'Monaco', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MN', 'AS', 'MNG', '496', NULL, 'Mongolia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('ME', 'EU', 'MNE', '499', NULL, 'Montenegro', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MS', 'NA', 'MSR', '500', NULL, 'Montserrat', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MA', 'AF', 'MAR', '504', NULL, 'Morocco', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MZ', 'AF', 'MOZ', '508', NULL, 'Mozambique', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MM', 'AS', 'MMR', '104', NULL, 'Myanmar', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NA', 'AF', 'NAM', '516', NULL, 'Namibia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NR', 'OC', 'NRU', '520', NULL, 'Nauru', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NP', 'AS', 'NPL', '524', NULL, 'Nepal', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AN', 'NA', 'ANT', '530', NULL, 'Netherlands Antilles', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NL', 'EU', 'NLD', '528', NULL, 'Netherlands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NC', 'OC', 'NCL', '540', NULL, 'New Caledonia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NZ', 'OC', 'NZL', '554', NULL, 'New Zealand', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NI', 'NA', 'NIC', '558', NULL, 'Nicaragua', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NE', 'AF', 'NER', '562', NULL, 'Niger', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NG', 'AF', 'NGA', '566', NULL, 'Nigeria', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NU', 'OC', 'NIU', '570', NULL, 'Niue', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NF', 'OC', 'NFK', '574', NULL, 'Norfolk Island', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MP', 'OC', 'MNP', '580', NULL, 'Northern Mariana Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('NO', 'EU', 'NOR', '578', NULL, 'Norway', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('OM', 'AS', 'OMN', '512', NULL, 'Oman', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PK', 'AS', 'PAK', '586', NULL, 'Pakistan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PW', 'OC', 'PLW', '585', NULL, 'Palau', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PS', 'AS', 'PSE', '275', NULL, 'Palestinian Territory', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PA', 'NA', 'PAN', '591', NULL, 'Panama', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PG', 'OC', 'PNG', '598', NULL, 'Papua New Guinea', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PY', 'SA', 'PRY', '600', NULL, 'Paraguay', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PE', 'SA', 'PER', '604', NULL, 'Peru', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PH', 'AS', 'PHL', '608', NULL, 'Philippines', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PN', 'OC', 'PCN', '612', NULL, 'Pitcairn Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PL', 'EU', 'POL', '616', NULL, 'Poland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PT', 'EU', 'PRT', '620', NULL, 'Portugal', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PR', 'NA', 'PRI', '630', NULL, 'Puerto Rico', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('QA', 'AS', 'QAT', '634', NULL, 'Qatar', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('RE', 'AF', 'REU', '638', NULL, 'Reunion', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('RO', 'EU', 'ROU', '642', NULL, 'Romania', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('RU', 'EU', 'RUS', '643', NULL, 'Russian Federation', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('RW', 'AF', 'RWA', '646', NULL, 'Rwanda', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('BL', 'NA', 'BLM', '652', NULL, 'Saint Barthelemy', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SH', 'AF', 'SHN', '654', NULL, 'Saint Helena', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('KN', 'NA', 'KNA', '659', NULL, 'Saint Kitts and Nevis', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('LC', 'NA', 'LCA', '662', NULL, 'Saint Lucia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('MF', 'NA', 'MAF', '663', NULL, 'Saint Martin', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('PM', 'NA', 'SPM', '666', NULL, 'Saint Pierre and Miquelon', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('VC', 'NA', 'VCT', '670', NULL, 'Saint Vincent and the Grenadines', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('WS', 'OC', 'WSM', '882', NULL, 'Samoa', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SM', 'EU', 'SMR', '674', NULL, 'San Marino', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('ST', 'AF', 'STP', '678', NULL, 'Sao Tome and Principe', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SA', 'AS', 'SAU', '682', NULL, 'Saudi Arabia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SN', 'AF', 'SEN', '686', NULL, 'Senegal', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('RS', 'EU', 'SRB', '688', NULL, 'Serbia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SC', 'AF', 'SYC', '690', NULL, 'Seychelles', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SL', 'AF', 'SLE', '694', NULL, 'Sierra Leone', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SG', 'AS', 'SGP', '702', NULL, 'Singapore', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SK', 'EU', 'SVK', '703', NULL, 'Slovakia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SI', 'EU', 'SVN', '705', NULL, 'Slovenia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SB', 'OC', 'SLB', '090', NULL, 'Solomon Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SO', 'AF', 'SOM', '706', NULL, 'Somalia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('ZA', 'AF', 'ZAF', '710', NULL, 'South Africa', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GS', 'AN', 'SGS', '239', NULL, 'South Georgia and the South Sandwich Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('ES', 'EU', 'ESP', '724', NULL, 'Spain', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('LK', 'AS', 'LKA', '144', NULL, 'Sri Lanka', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SD', 'AF', 'SDN', '736', NULL, 'Sudan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SS', 'AF', 'SSN', '737', NULL, 'South Sudan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SR', 'SA', 'SUR', '740', NULL, 'Suriname', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SJ', 'EU', 'SJM', '744', NULL, 'Svalbard & Jan Mayen Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SZ', 'AF', 'SWZ', '748', NULL, 'Swaziland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SE', 'EU', 'SWE', '752', NULL, 'Sweden', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('CH', 'EU', 'CHE', '756', NULL, 'Switzerland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('SY', 'AS', 'SYR', '760', NULL, 'Syrian Arab Republic', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TW', 'AS', 'TWN', '158', NULL, 'Taiwan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TJ', 'AS', 'TJK', '762', NULL, 'Tajikistan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TZ', 'AF', 'TZA', '834', NULL, 'Tanzania', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TH', 'AS', 'THA', '764', NULL, 'Thailand', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TL', 'AS', 'TLS', '626', NULL, 'Timor-Leste', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TG', 'AF', 'TGO', '768', NULL, 'Togo', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TK', 'OC', 'TKL', '772', NULL, 'Tokelau', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TO', 'OC', 'TON', '776', NULL, 'Tonga', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TT', 'NA', 'TTO', '780', NULL, 'Trinidad and Tobago', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TN', 'AF', 'TUN', '788', NULL, 'Tunisia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TR', 'AS', 'TUR', '792', NULL, 'Turkey', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TM', 'AS', 'TKM', '795', NULL, 'Turkmenistan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TC', 'NA', 'TCA', '796', NULL, 'Turks and Caicos Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('TV', 'OC', 'TUV', '798', NULL, 'Tuvalu', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('UG', 'AF', 'UGA', '800', NULL, 'Uganda', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('UA', 'EU', 'UKR', '804', NULL, 'Ukraine', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('AE', 'AS', 'ARE', '784', NULL, 'United Arab Emirates', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('GB', 'EU', 'GBR', '826', NULL, 'United Kingdom of Great Britain & Northern Ireland', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('US', 'NA', 'USA', '840', NULL, 'United States of America', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('UM', 'OC', 'UMI', '581', NULL, 'United States Minor Outlying Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('VI', 'NA', 'VIR', '850', NULL, 'United States Virgin Islands', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('UY', 'SA', 'URY', '858', NULL, 'Uruguay', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('UZ', 'AS', 'UZB', '860', NULL, 'Uzbekistan', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('VU', 'OC', 'VUT', '548', NULL, 'Vanuatu', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('VE', 'SA', 'VEN', '862', NULL, 'Venezuela', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('VN', 'AS', 'VNM', '704', NULL, 'Vietnam', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('WF', 'OC', 'WLF', '876', NULL, 'Wallis and Futuna', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('EH', 'AF', 'ESH', '732', NULL, 'Western Sahara', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('YE', 'AS', 'YEM', '887', NULL, 'Yemen', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('ZM', 'AF', 'ZMB', '894', NULL, 'Zambia', NULL, NULL, NULL, NULL);
INSERT INTO sys_countrys (sys_country_id, sys_continent_id, sys_country_code, sys_country_number, sys_phone_code, sys_country_name, sys_currency_name, sys_currency_cents, sys_currency_code, sys_currency_exchange) VALUES ('ZW', 'AF', 'ZWE', '716', NULL, 'Zimbabwe', NULL, NULL, NULL, NULL);


--
-- Data for Name: sys_dashboard; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: sys_dashboard_sys_dashboard_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_dashboard_sys_dashboard_id_seq', 1, false);


--
-- Data for Name: sys_emailed; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO sys_emailed (sys_emailed_id, sys_email_id, org_id, table_id, table_name, email_type, emailed, narrative) VALUES (1, 1, NULL, 8, 'applicant', 1, false, NULL);
INSERT INTO sys_emailed (sys_emailed_id, sys_email_id, org_id, table_id, table_name, email_type, emailed, narrative) VALUES (2, 1, NULL, 9, 'applicant', 1, false, NULL);


--
-- Name: sys_emailed_sys_emailed_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_emailed_sys_emailed_id_seq', 2, true);


--
-- Data for Name: sys_emails; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details) VALUES (1, 0, 'Application', NULL, 'Thank you for your Application', 'Thank you {{name}} for your application.<br><br>
Your user name is {{username}}<br> 
Your password is {{password}}<br><br>
Regards<br>
Human Resources Manager<br>
');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details) VALUES (2, 0, 'New Staff', NULL, 'HR Your credentials ', 'Hello {{name}},<br><br>
Your credentials to the HR system have been created.<br>
Your user name is {{username}}<br> 
Your password is {{password}}<br><br>
Regards<br>
Human Resources Manager<br>
');
INSERT INTO sys_emails (sys_email_id, org_id, sys_email_name, default_email, title, details) VALUES (3, 0, 'Password reset', NULL, 'Password reset', 'Hello {{name}},<br><br>
Your password has been reset to:<br><br>
Your user name is {{username}}<br> 
Your password is {{password}}<br><br>
Regards<br>
Human Resources Manager<br>
');


--
-- Name: sys_emails_sys_email_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_emails_sys_email_id_seq', 3, true);


--
-- Data for Name: sys_errors; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: sys_errors_sys_error_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_errors_sys_error_id_seq', 1, false);


--
-- Data for Name: sys_files; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: sys_files_sys_file_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_files_sys_file_id_seq', 1, false);


--
-- Data for Name: sys_logins; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO sys_logins (sys_login_id, entity_id, login_time, login_ip, narrative) VALUES (1, 0, '2015-04-20 11:28:27.163131', '127.0.0.1', NULL);


--
-- Name: sys_logins_sys_login_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_logins_sys_login_id_seq', 1, true);


--
-- Data for Name: sys_menu_msg; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: sys_menu_msg_sys_menu_msg_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_menu_msg_sys_menu_msg_id_seq', 1, false);


--
-- Data for Name: sys_news; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: sys_news_sys_news_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_news_sys_news_id_seq', 1, false);


--
-- Data for Name: sys_queries; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: sys_queries_sys_queries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_queries_sys_queries_id_seq', 1, false);


--
-- Data for Name: sys_reset; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: sys_reset_sys_reset_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('sys_reset_sys_reset_id_seq', 1, false);


--
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: tasks_task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tasks_task_id_seq', 1, false);


--
-- Data for Name: tax_rates; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (26, 1, 0, 10164, 10, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (27, 1, 0, 19740, 15, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (28, 1, 0, 29316, 20, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (29, 1, 0, 38892, 25, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (30, 1, 0, 10000000, 30, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (31, 2, 0, 4000, 5, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (32, 2, 0, 10000000, 0, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (33, 3, 0, 999, 0, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (34, 3, 0, 1499, 30, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (35, 3, 0, 1999, 40, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (36, 3, 0, 2999, 60, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (37, 3, 0, 3999, 80, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (38, 3, 0, 4999, 100, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (39, 3, 0, 5999, 120, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (40, 3, 0, 6999, 140, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (41, 3, 0, 7999, 160, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (42, 3, 0, 8999, 180, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (43, 3, 0, 9999, 200, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (44, 3, 0, 10999, 220, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (45, 3, 0, 11999, 240, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (46, 3, 0, 12999, 260, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (47, 3, 0, 13999, 280, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (48, 3, 0, 14999, 300, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (49, 3, 0, 1000000, 320, NULL);
INSERT INTO tax_rates (tax_rate_id, tax_type_id, org_id, tax_range, tax_rate, narrative) VALUES (50, 4, 0, 10000000, 30, NULL);


--
-- Name: tax_rates_tax_rate_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tax_rates_tax_rate_id_seq', 50, true);


--
-- Data for Name: tax_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tax_types (tax_type_id, account_id, currency_id, org_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, tax_rate, tax_inclusive, linear, percentage, employer, employer_ps, account_number, active, use_key, details) VALUES (1, NULL, 1, 0, 'PAYE', 'Get_Employee_Tax(employee_tax_type_id, 2)', 1162, 1, false, 0, false, true, true, 0, 0, NULL, true, 1, NULL);
INSERT INTO tax_types (tax_type_id, account_id, currency_id, org_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, tax_rate, tax_inclusive, linear, percentage, employer, employer_ps, account_number, active, use_key, details) VALUES (2, NULL, 1, 0, 'NSSF', 'Get_Employee_Tax(employee_tax_type_id, 1)', 0, 0, true, 0, false, true, true, 0, 0, NULL, true, 1, NULL);
INSERT INTO tax_types (tax_type_id, account_id, currency_id, org_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, tax_rate, tax_inclusive, linear, percentage, employer, employer_ps, account_number, active, use_key, details) VALUES (3, NULL, 1, 0, 'NHIF', 'Get_Employee_Tax(employee_tax_type_id, 1)', 0, 0, false, 0, false, false, false, 0, 0, NULL, true, 1, NULL);
INSERT INTO tax_types (tax_type_id, account_id, currency_id, org_id, tax_type_name, formural, tax_relief, tax_type_order, in_tax, tax_rate, tax_inclusive, linear, percentage, employer, employer_ps, account_number, active, use_key, details) VALUES (4, NULL, 1, 0, 'FULL PAYE', 'Get_Employee_Tax(employee_tax_type_id, 2)', 0, 0, false, 0, false, false, false, 0, 0, NULL, false, 1, NULL);


--
-- Name: tax_types_tax_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tax_types_tax_type_id_seq', 4, true);


--
-- Data for Name: tender_items; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: tender_items_tender_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tender_items_tender_item_id_seq', 1, false);


--
-- Data for Name: tender_types; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: tender_types_tender_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tender_types_tender_type_id_seq', 1, false);


--
-- Data for Name: tenders; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: tenders_tender_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tenders_tender_id_seq', 1, false);


--
-- Data for Name: timesheet; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: timesheet_timesheet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('timesheet_timesheet_id_seq', 1, false);


--
-- Data for Name: trainings; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: trainings_training_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('trainings_training_id_seq', 1, false);


--
-- Data for Name: transaction_details; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: transaction_details_transaction_detail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('transaction_details_transaction_detail_id_seq', 1, false);


--
-- Data for Name: transaction_links; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: transaction_links_transaction_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('transaction_links_transaction_link_id_seq', 1, false);


--
-- Data for Name: transaction_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO transaction_status (transaction_status_id, transaction_status_name) VALUES (1, 'Draft');
INSERT INTO transaction_status (transaction_status_id, transaction_status_name) VALUES (2, 'Completed');
INSERT INTO transaction_status (transaction_status_id, transaction_status_name) VALUES (3, 'Processed');
INSERT INTO transaction_status (transaction_status_id, transaction_status_name) VALUES (4, 'Archive');


--
-- Data for Name: transaction_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (16, 'Requisitions', 'D', 10001, false, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (14, 'Sales Quotation', 'D', 10001, true, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (15, 'Purchase Quotation', 'D', 10001, false, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (1, 'Sales Order', 'D', 10001, true, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (2, 'Sales Invoice', 'D', 10001, true, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (3, 'Sales Template', 'D', 10001, true, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (4, 'Purchase Order', 'D', 10001, false, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (5, 'Purchase Invoice', 'D', 10001, false, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (6, 'Purchase Template', 'D', 10001, false, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (7, 'Receipts', 'D', 10001, true, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (8, 'Payments', 'D', 10001, false, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (9, 'Credit Note', 'D', 10001, true, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (10, 'Debit Note', 'D', 10001, false, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (11, 'Delivery Note', 'D', 10001, true, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (12, 'Receipt Note', 'D', 10001, false, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, document_prefix, document_number, for_sales, for_posting) VALUES (17, 'Work Use', 'D', 10001, true, false);


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('transactions_transaction_id_seq', 1, false);


--
-- Data for Name: vw_pay_scales; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: workflow_logs; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: workflow_logs_workflow_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('workflow_logs_workflow_log_id_seq', 1, false);


--
-- Data for Name: workflow_phases; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO workflow_phases (workflow_phase_id, workflow_id, approval_entity_id, org_id, approval_level, return_level, escalation_days, escalation_hours, required_approvals, reporting_level, use_reporting, advice, notice, phase_narrative, advice_email, notice_email, advice_file, notice_file, details) VALUES (1, 1, 0, 0, 1, 0, 0, 3, 1, 1, false, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL);
INSERT INTO workflow_phases (workflow_phase_id, workflow_id, approval_entity_id, org_id, approval_level, return_level, escalation_days, escalation_hours, required_approvals, reporting_level, use_reporting, advice, notice, phase_narrative, advice_email, notice_email, advice_file, notice_file, details) VALUES (2, 2, 0, 0, 1, 0, 0, 3, 1, 1, false, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL);
INSERT INTO workflow_phases (workflow_phase_id, workflow_id, approval_entity_id, org_id, approval_level, return_level, escalation_days, escalation_hours, required_approvals, reporting_level, use_reporting, advice, notice, phase_narrative, advice_email, notice_email, advice_file, notice_file, details) VALUES (3, 3, 0, 0, 1, 0, 0, 3, 1, 1, false, false, false, 'Approve', 'For your approval', 'Phase approved', NULL, NULL, NULL);


--
-- Name: workflow_phases_workflow_phase_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('workflow_phases_workflow_phase_id_seq', 2, true);


--
-- Data for Name: workflow_sql; Type: TABLE DATA; Schema: public; Owner: root
--



--
-- Name: workflow_table_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('workflow_table_id_seq', 1, false);


--
-- Data for Name: workflows; Type: TABLE DATA; Schema: public; Owner: root
--

INSERT INTO workflows (workflow_id, source_entity_id, org_id, workflow_name, table_name, table_link_field, table_link_id, approve_email, reject_email, approve_file, reject_file, details) VALUES (1, 0, 0, 'Budget', 'budgets', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL);
INSERT INTO workflows (workflow_id, source_entity_id, org_id, workflow_name, table_name, table_link_field, table_link_id, approve_email, reject_email, approve_file, reject_file, details) VALUES (2, 0, 0, 'Requisition', 'transactions', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL);
INSERT INTO workflows (workflow_id, source_entity_id, org_id, workflow_name, table_name, table_link_field, table_link_id, approve_email, reject_email, approve_file, reject_file, details) VALUES (3, 3, 0, 'Transactions', 'transactions', NULL, NULL, 'Request approved', 'Request rejected', NULL, NULL, NULL);


--
-- Name: workflows_workflow_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('workflows_workflow_id_seq', 2, true);


--
-- Name: account_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY account_types
    ADD CONSTRAINT account_types_pkey PRIMARY KEY (account_type_id);


--
-- Name: accounts_class_accounts_class_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY accounts_class
    ADD CONSTRAINT accounts_class_accounts_class_name_key UNIQUE (accounts_class_name);


--
-- Name: accounts_class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY accounts_class
    ADD CONSTRAINT accounts_class_pkey PRIMARY KEY (accounts_class_id);


--
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (account_id);


--
-- Name: address_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY address
    ADD CONSTRAINT address_pkey PRIMARY KEY (address_id);


--
-- Name: address_types_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY address_types
    ADD CONSTRAINT address_types_pkey PRIMARY KEY (address_type_id);


--
-- Name: adjustments_adjustment_name_org_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY adjustments
    ADD CONSTRAINT adjustments_adjustment_name_org_id_key UNIQUE (adjustment_name, org_id);


--
-- Name: adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY adjustments
    ADD CONSTRAINT adjustments_pkey PRIMARY KEY (adjustment_id);


--
-- Name: advance_deductions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY advance_deductions
    ADD CONSTRAINT advance_deductions_pkey PRIMARY KEY (advance_deduction_id);


--
-- Name: amortisation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY amortisation
    ADD CONSTRAINT amortisation_pkey PRIMARY KEY (amortisation_id);


--
-- Name: applicants_applicant_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY applicants
    ADD CONSTRAINT applicants_applicant_email_key UNIQUE (applicant_email);


--
-- Name: applicants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY applicants
    ADD CONSTRAINT applicants_pkey PRIMARY KEY (entity_id);


--
-- Name: applications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (application_id);


--
-- Name: approval_checklists_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY approval_checklists
    ADD CONSTRAINT approval_checklists_pkey PRIMARY KEY (approval_checklist_id);


--
-- Name: approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY approvals
    ADD CONSTRAINT approvals_pkey PRIMARY KEY (approval_id);


--
-- Name: asset_movement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY asset_movement
    ADD CONSTRAINT asset_movement_pkey PRIMARY KEY (asset_movement_id);


--
-- Name: asset_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY asset_types
    ADD CONSTRAINT asset_types_pkey PRIMARY KEY (asset_type_id);


--
-- Name: asset_valuations_asset_id_valuation_year_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY asset_valuations
    ADD CONSTRAINT asset_valuations_asset_id_valuation_year_key UNIQUE (asset_id, valuation_year);


--
-- Name: asset_valuations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY asset_valuations
    ADD CONSTRAINT asset_valuations_pkey PRIMARY KEY (asset_valuation_id);


--
-- Name: assets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (asset_id);


--
-- Name: attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (attendance_id);


--
-- Name: bank_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bank_accounts
    ADD CONSTRAINT bank_accounts_pkey PRIMARY KEY (bank_account_id);


--
-- Name: bank_branch_bank_id_bank_branch_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bank_branch
    ADD CONSTRAINT bank_branch_bank_id_bank_branch_name_key UNIQUE (bank_id, bank_branch_name);


--
-- Name: bank_branch_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bank_branch
    ADD CONSTRAINT bank_branch_pkey PRIMARY KEY (bank_branch_id);


--
-- Name: banks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY banks
    ADD CONSTRAINT banks_pkey PRIMARY KEY (bank_id);


--
-- Name: bidders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bidders
    ADD CONSTRAINT bidders_pkey PRIMARY KEY (bidder_id);


--
-- Name: bio_imports1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bio_imports1
    ADD CONSTRAINT bio_imports1_pkey PRIMARY KEY (bio_imports1_id);


--
-- Name: budget_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY budget_lines
    ADD CONSTRAINT budget_lines_pkey PRIMARY KEY (budget_line_id);


--
-- Name: budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY budgets
    ADD CONSTRAINT budgets_pkey PRIMARY KEY (budget_id);


--
-- Name: career_development_org_id_career_development_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY career_development
    ADD CONSTRAINT career_development_org_id_career_development_name_key UNIQUE (org_id, career_development_name);


--
-- Name: career_development_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY career_development
    ADD CONSTRAINT career_development_pkey PRIMARY KEY (career_development_id);


--
-- Name: case_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY case_types
    ADD CONSTRAINT case_types_pkey PRIMARY KEY (case_type_id);


--
-- Name: casual_application_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY casual_application
    ADD CONSTRAINT casual_application_pkey PRIMARY KEY (casual_application_id);


--
-- Name: casual_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY casual_category
    ADD CONSTRAINT casual_category_pkey PRIMARY KEY (casual_category_id);


--
-- Name: casuals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY casuals
    ADD CONSTRAINT casuals_pkey PRIMARY KEY (casual_id);


--
-- Name: checklists_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY checklists
    ADD CONSTRAINT checklists_pkey PRIMARY KEY (checklist_id);


--
-- Name: claim_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY claim_details
    ADD CONSTRAINT claim_details_pkey PRIMARY KEY (claim_detail_id);


--
-- Name: claim_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY claim_types
    ADD CONSTRAINT claim_types_pkey PRIMARY KEY (claim_type_id);


--
-- Name: claims_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY claims
    ADD CONSTRAINT claims_pkey PRIMARY KEY (claim_id);


--
-- Name: contract_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY contract_status
    ADD CONSTRAINT contract_status_pkey PRIMARY KEY (contract_status_id);


--
-- Name: contract_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY contract_types
    ADD CONSTRAINT contract_types_pkey PRIMARY KEY (contract_type_id);


--
-- Name: contracts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (contract_id);


--
-- Name: currency_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (currency_id);


--
-- Name: currency_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY currency_rates
    ADD CONSTRAINT currency_rates_pkey PRIMARY KEY (currency_rate_id);


--
-- Name: cv_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY cv_projects
    ADD CONSTRAINT cv_projects_pkey PRIMARY KEY (cv_projectid);


--
-- Name: cv_seminars_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY cv_seminars
    ADD CONSTRAINT cv_seminars_pkey PRIMARY KEY (cv_seminar_id);


--
-- Name: day_ledgers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY day_ledgers
    ADD CONSTRAINT day_ledgers_pkey PRIMARY KEY (day_ledger_id);


--
-- Name: default_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY default_accounts
    ADD CONSTRAINT default_accounts_pkey PRIMARY KEY (default_account_id);


--
-- Name: default_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY default_adjustments
    ADD CONSTRAINT default_adjustments_pkey PRIMARY KEY (default_adjustment_id);


--
-- Name: default_banking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY default_banking
    ADD CONSTRAINT default_banking_pkey PRIMARY KEY (default_banking_id);


--
-- Name: default_tax_types_entity_id_tax_type_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY default_tax_types
    ADD CONSTRAINT default_tax_types_entity_id_tax_type_id_key UNIQUE (entity_id, tax_type_id);


--
-- Name: default_tax_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY default_tax_types
    ADD CONSTRAINT default_tax_types_pkey PRIMARY KEY (default_tax_type_id);


--
-- Name: define_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY define_phases
    ADD CONSTRAINT define_phases_pkey PRIMARY KEY (define_phase_id);


--
-- Name: define_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY define_tasks
    ADD CONSTRAINT define_tasks_pkey PRIMARY KEY (define_task_id);


--
-- Name: department_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY department_roles
    ADD CONSTRAINT department_roles_pkey PRIMARY KEY (department_role_id);


--
-- Name: departments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- Name: disability_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY disability
    ADD CONSTRAINT disability_pkey PRIMARY KEY (disability_id);


--
-- Name: education_class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY education_class
    ADD CONSTRAINT education_class_pkey PRIMARY KEY (education_class_id);


--
-- Name: education_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY education
    ADD CONSTRAINT education_pkey PRIMARY KEY (education_id);


--
-- Name: employee_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_adjustments
    ADD CONSTRAINT employee_adjustments_pkey PRIMARY KEY (employee_adjustment_id);


--
-- Name: employee_advances_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_advances
    ADD CONSTRAINT employee_advances_pkey PRIMARY KEY (employee_advance_id);


--
-- Name: employee_banking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_banking
    ADD CONSTRAINT employee_banking_pkey PRIMARY KEY (default_banking_id);


--
-- Name: employee_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_cases
    ADD CONSTRAINT employee_cases_pkey PRIMARY KEY (employee_case_id);


--
-- Name: employee_leave_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_leave
    ADD CONSTRAINT employee_leave_pkey PRIMARY KEY (employee_leave_id);


--
-- Name: employee_leave_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_leave_types
    ADD CONSTRAINT employee_leave_types_pkey PRIMARY KEY (employee_leave_type_id);


--
-- Name: employee_month_entity_id_period_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_month
    ADD CONSTRAINT employee_month_entity_id_period_id_key UNIQUE (entity_id, period_id);


--
-- Name: employee_month_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_month
    ADD CONSTRAINT employee_month_pkey PRIMARY KEY (employee_month_id);


--
-- Name: employee_objectives_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_objectives
    ADD CONSTRAINT employee_objectives_pkey PRIMARY KEY (employee_objective_id);


--
-- Name: employee_overtime_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_overtime
    ADD CONSTRAINT employee_overtime_pkey PRIMARY KEY (employee_overtime_id);


--
-- Name: employee_per_diem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_per_diem
    ADD CONSTRAINT employee_per_diem_pkey PRIMARY KEY (employee_per_diem_id);


--
-- Name: employee_tax_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_tax_types
    ADD CONSTRAINT employee_tax_types_pkey PRIMARY KEY (employee_tax_type_id);


--
-- Name: employee_trainings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employee_trainings
    ADD CONSTRAINT employee_trainings_pkey PRIMARY KEY (employee_training_id);


--
-- Name: employees_org_id_employee_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_org_id_employee_id_key UNIQUE (org_id, employee_id);


--
-- Name: employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (entity_id);


--
-- Name: employment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY employment
    ADD CONSTRAINT employment_pkey PRIMARY KEY (employment_id);


--
-- Name: entity_subscriptions_entity_id_entity_type_id_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entity_subscriptions
    ADD CONSTRAINT entity_subscriptions_entity_id_entity_type_id_key UNIQUE (entity_id, entity_type_id);


--
-- Name: entity_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entity_subscriptions
    ADD CONSTRAINT entity_subscriptions_pkey PRIMARY KEY (entity_subscription_id);


--
-- Name: entity_types_entity_type_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entity_types
    ADD CONSTRAINT entity_types_entity_type_name_key UNIQUE (entity_type_name);


--
-- Name: entity_types_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entity_types
    ADD CONSTRAINT entity_types_pkey PRIMARY KEY (entity_type_id);


--
-- Name: entitys_org_id_user_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entitys
    ADD CONSTRAINT entitys_org_id_user_name_key UNIQUE (org_id, user_name);


--
-- Name: entitys_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entitys
    ADD CONSTRAINT entitys_pkey PRIMARY KEY (entity_id);


--
-- Name: entry_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY entry_forms
    ADD CONSTRAINT entry_forms_pkey PRIMARY KEY (entry_form_id);


--
-- Name: evaluation_points_org_id_job_review_id_review_point_id_obje_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY evaluation_points
    ADD CONSTRAINT evaluation_points_org_id_job_review_id_review_point_id_obje_key UNIQUE (org_id, job_review_id, review_point_id, objective_id, career_development_id);


--
-- Name: evaluation_points_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY evaluation_points
    ADD CONSTRAINT evaluation_points_pkey PRIMARY KEY (evaluation_point_id);


--
-- Name: fields_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY fields
    ADD CONSTRAINT fields_pkey PRIMARY KEY (field_id);


--
-- Name: fiscal_years_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY fiscal_years
    ADD CONSTRAINT fiscal_years_pkey PRIMARY KEY (fiscal_year_id);


--
-- Name: forms_form_name_version_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY forms
    ADD CONSTRAINT forms_form_name_version_key UNIQUE (form_name, version);


--
-- Name: forms_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY forms
    ADD CONSTRAINT forms_pkey PRIMARY KEY (form_id);


--
-- Name: gls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gls
    ADD CONSTRAINT gls_pkey PRIMARY KEY (gl_id);


--
-- Name: holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (holiday_id);


--
-- Name: identification_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY identification_types
    ADD CONSTRAINT identification_types_pkey PRIMARY KEY (identification_type_id);


--
-- Name: identifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY identifications
    ADD CONSTRAINT identifications_pkey PRIMARY KEY (identification_id);


--
-- Name: intake_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY intake
    ADD CONSTRAINT intake_pkey PRIMARY KEY (intake_id);


--
-- Name: interns_internship_id_entity_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY interns
    ADD CONSTRAINT interns_internship_id_entity_id_key UNIQUE (internship_id, entity_id);


--
-- Name: interns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY interns
    ADD CONSTRAINT interns_pkey PRIMARY KEY (intern_id);


--
-- Name: internships_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY internships
    ADD CONSTRAINT internships_pkey PRIMARY KEY (internship_id);


--
-- Name: item_category_item_category_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY item_category
    ADD CONSTRAINT item_category_item_category_name_key UNIQUE (item_category_name);


--
-- Name: item_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY item_category
    ADD CONSTRAINT item_category_pkey PRIMARY KEY (item_category_id);


--
-- Name: item_units_item_unit_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY item_units
    ADD CONSTRAINT item_units_item_unit_name_key UNIQUE (item_unit_name);


--
-- Name: item_units_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY item_units
    ADD CONSTRAINT item_units_pkey PRIMARY KEY (item_unit_id);


--
-- Name: items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (item_id);


--
-- Name: job_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY job_reviews
    ADD CONSTRAINT job_reviews_pkey PRIMARY KEY (job_review_id);


--
-- Name: journals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT journals_pkey PRIMARY KEY (journal_id);


--
-- Name: kin_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY kin_types
    ADD CONSTRAINT kin_types_pkey PRIMARY KEY (kin_type_id);


--
-- Name: kins_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY kins
    ADD CONSTRAINT kins_pkey PRIMARY KEY (kin_id);


--
-- Name: lead_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY lead_items
    ADD CONSTRAINT lead_items_pkey PRIMARY KEY (lead_item);


--
-- Name: leads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (lead_id);


--
-- Name: leave_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY leave_types
    ADD CONSTRAINT leave_types_pkey PRIMARY KEY (leave_type_id);


--
-- Name: leave_work_days_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY leave_work_days
    ADD CONSTRAINT leave_work_days_pkey PRIMARY KEY (leave_work_day_id);


--
-- Name: loan_monthly_loan_id_period_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY loan_monthly
    ADD CONSTRAINT loan_monthly_loan_id_period_id_key UNIQUE (loan_id, period_id);


--
-- Name: loan_monthly_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY loan_monthly
    ADD CONSTRAINT loan_monthly_pkey PRIMARY KEY (loan_month_id);


--
-- Name: loan_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY loan_types
    ADD CONSTRAINT loan_types_pkey PRIMARY KEY (loan_type_id);


--
-- Name: loans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (loan_id);


--
-- Name: locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (location_id);


--
-- Name: objective_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY objective_details
    ADD CONSTRAINT objective_details_pkey PRIMARY KEY (objective_detail_id);


--
-- Name: objective_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY objective_types
    ADD CONSTRAINT objective_types_pkey PRIMARY KEY (objective_type_id);


--
-- Name: objectives_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY objectives
    ADD CONSTRAINT objectives_pkey PRIMARY KEY (objective_id);


--
-- Name: orgs_org_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY orgs
    ADD CONSTRAINT orgs_org_name_key UNIQUE (org_name);


--
-- Name: orgs_org_sufix_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY orgs
    ADD CONSTRAINT orgs_org_sufix_key UNIQUE (org_sufix);


--
-- Name: orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY orgs
    ADD CONSTRAINT orgs_pkey PRIMARY KEY (org_id);


--
-- Name: pay_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pay_groups
    ADD CONSTRAINT pay_groups_pkey PRIMARY KEY (pay_group_id);


--
-- Name: pay_scale_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pay_scale_steps
    ADD CONSTRAINT pay_scale_steps_pkey PRIMARY KEY (pay_scale_step_id);


--
-- Name: pay_scale_years_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pay_scale_years
    ADD CONSTRAINT pay_scale_years_pkey PRIMARY KEY (pay_scale_year_id);


--
-- Name: pay_scales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pay_scales
    ADD CONSTRAINT pay_scales_pkey PRIMARY KEY (pay_scale_id);


--
-- Name: payroll_ledger_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY payroll_ledger
    ADD CONSTRAINT payroll_ledger_pkey PRIMARY KEY (payroll_ledger_id);


--
-- Name: pc_allocations_period_id_department_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pc_allocations
    ADD CONSTRAINT pc_allocations_period_id_department_id_key UNIQUE (period_id, department_id);


--
-- Name: pc_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pc_allocations
    ADD CONSTRAINT pc_allocations_pkey PRIMARY KEY (pc_allocation_id);


--
-- Name: pc_banking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pc_banking
    ADD CONSTRAINT pc_banking_pkey PRIMARY KEY (pc_banking_id);


--
-- Name: pc_budget_pc_allocation_id_pc_item_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pc_budget
    ADD CONSTRAINT pc_budget_pc_allocation_id_pc_item_id_key UNIQUE (pc_allocation_id, pc_item_id);


--
-- Name: pc_budget_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pc_budget
    ADD CONSTRAINT pc_budget_pkey PRIMARY KEY (pc_budget_id);


--
-- Name: pc_category_pc_category_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pc_category
    ADD CONSTRAINT pc_category_pc_category_name_key UNIQUE (pc_category_name);


--
-- Name: pc_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pc_category
    ADD CONSTRAINT pc_category_pkey PRIMARY KEY (pc_category_id);


--
-- Name: pc_expenditure_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pc_expenditure
    ADD CONSTRAINT pc_expenditure_pkey PRIMARY KEY (pc_expenditure_id);


--
-- Name: pc_items_pc_item_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pc_items
    ADD CONSTRAINT pc_items_pc_item_name_key UNIQUE (pc_item_name);


--
-- Name: pc_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pc_items
    ADD CONSTRAINT pc_items_pkey PRIMARY KEY (pc_item_id);


--
-- Name: pc_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY pc_types
    ADD CONSTRAINT pc_types_pkey PRIMARY KEY (pc_type_id);


--
-- Name: period_tax_rates_period_tax_type_id_tax_rate_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY period_tax_rates
    ADD CONSTRAINT period_tax_rates_period_tax_type_id_tax_rate_id_key UNIQUE (period_tax_type_id, tax_rate_id);


--
-- Name: period_tax_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY period_tax_rates
    ADD CONSTRAINT period_tax_rates_pkey PRIMARY KEY (period_tax_rate_id);


--
-- Name: period_tax_types_period_id_tax_type_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY period_tax_types
    ADD CONSTRAINT period_tax_types_period_id_tax_type_id_key UNIQUE (period_id, tax_type_id);


--
-- Name: period_tax_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY period_tax_types
    ADD CONSTRAINT period_tax_types_pkey PRIMARY KEY (period_tax_type_id);


--
-- Name: periods_org_id_start_date_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY periods
    ADD CONSTRAINT periods_org_id_start_date_key UNIQUE (org_id, start_date);


--
-- Name: periods_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY periods
    ADD CONSTRAINT periods_pkey PRIMARY KEY (period_id);


--
-- Name: phases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY phases
    ADD CONSTRAINT phases_pkey PRIMARY KEY (phase_id);


--
-- Name: project_cost_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY project_cost
    ADD CONSTRAINT project_cost_pkey PRIMARY KEY (project_cost_id);


--
-- Name: project_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY project_locations
    ADD CONSTRAINT project_locations_pkey PRIMARY KEY (job_location_id);


--
-- Name: project_staff_costs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY project_staff_costs
    ADD CONSTRAINT project_staff_costs_pkey PRIMARY KEY (project_staff_cost_id);


--
-- Name: project_staff_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY project_staff
    ADD CONSTRAINT project_staff_pkey PRIMARY KEY (project_staff_id);


--
-- Name: project_staff_project_id_entity_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY project_staff
    ADD CONSTRAINT project_staff_project_id_entity_id_key UNIQUE (project_id, entity_id);


--
-- Name: project_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY project_types
    ADD CONSTRAINT project_types_pkey PRIMARY KEY (project_type_id);


--
-- Name: project_types_project_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY project_types
    ADD CONSTRAINT project_types_project_type_name_key UNIQUE (project_type_name);


--
-- Name: projects_entity_id_project_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_entity_id_project_name_key UNIQUE (entity_id, project_name);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project_id);


--
-- Name: quotations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY quotations
    ADD CONSTRAINT quotations_pkey PRIMARY KEY (quotation_id);


--
-- Name: reporting_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY reporting
    ADD CONSTRAINT reporting_pkey PRIMARY KEY (reporting_id);


--
-- Name: review_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY review_category
    ADD CONSTRAINT review_category_pkey PRIMARY KEY (review_category_id);


--
-- Name: review_points_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY review_points
    ADD CONSTRAINT review_points_pkey PRIMARY KEY (review_point_id);


--
-- Name: shift_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY shift_schedule
    ADD CONSTRAINT shift_schedule_pkey PRIMARY KEY (shift_schedule_id);


--
-- Name: shifts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY shifts
    ADD CONSTRAINT shifts_pkey PRIMARY KEY (shift_id);


--
-- Name: skill_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY skill_category
    ADD CONSTRAINT skill_category_pkey PRIMARY KEY (skill_category_id);


--
-- Name: skill_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY skill_types
    ADD CONSTRAINT skill_types_pkey PRIMARY KEY (skill_type_id);


--
-- Name: skills_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (skill_id);


--
-- Name: stock_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY stock_lines
    ADD CONSTRAINT stock_lines_pkey PRIMARY KEY (stock_line_id);


--
-- Name: stocks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY stocks
    ADD CONSTRAINT stocks_pkey PRIMARY KEY (stock_id);


--
-- Name: stores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY stores
    ADD CONSTRAINT stores_pkey PRIMARY KEY (store_id);


--
-- Name: sub_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sub_fields
    ADD CONSTRAINT sub_fields_pkey PRIMARY KEY (sub_field_id);


--
-- Name: subscription_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY subscription_levels
    ADD CONSTRAINT subscription_levels_pkey PRIMARY KEY (subscription_level_id);


--
-- Name: sys_audit_details_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_audit_details
    ADD CONSTRAINT sys_audit_details_pkey PRIMARY KEY (sys_audit_detail_id);


--
-- Name: sys_audit_trail_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_audit_trail
    ADD CONSTRAINT sys_audit_trail_pkey PRIMARY KEY (sys_audit_trail_id);


--
-- Name: sys_continents_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_continents
    ADD CONSTRAINT sys_continents_pkey PRIMARY KEY (sys_continent_id);


--
-- Name: sys_continents_sys_continent_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_continents
    ADD CONSTRAINT sys_continents_sys_continent_name_key UNIQUE (sys_continent_name);


--
-- Name: sys_countrys_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_countrys
    ADD CONSTRAINT sys_countrys_pkey PRIMARY KEY (sys_country_id);


--
-- Name: sys_countrys_sys_country_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_countrys
    ADD CONSTRAINT sys_countrys_sys_country_name_key UNIQUE (sys_country_name);


--
-- Name: sys_dashboard_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_dashboard
    ADD CONSTRAINT sys_dashboard_pkey PRIMARY KEY (sys_dashboard_id);


--
-- Name: sys_emailed_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_emailed
    ADD CONSTRAINT sys_emailed_pkey PRIMARY KEY (sys_emailed_id);


--
-- Name: sys_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_emails
    ADD CONSTRAINT sys_emails_pkey PRIMARY KEY (sys_email_id);


--
-- Name: sys_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_errors
    ADD CONSTRAINT sys_errors_pkey PRIMARY KEY (sys_error_id);


--
-- Name: sys_files_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_files
    ADD CONSTRAINT sys_files_pkey PRIMARY KEY (sys_file_id);


--
-- Name: sys_logins_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_logins
    ADD CONSTRAINT sys_logins_pkey PRIMARY KEY (sys_login_id);


--
-- Name: sys_menu_msg_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_menu_msg
    ADD CONSTRAINT sys_menu_msg_pkey PRIMARY KEY (sys_menu_msg_id);


--
-- Name: sys_news_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_news
    ADD CONSTRAINT sys_news_pkey PRIMARY KEY (sys_news_id);


--
-- Name: sys_queries_org_id_sys_query_name_key; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_queries
    ADD CONSTRAINT sys_queries_org_id_sys_query_name_key UNIQUE (org_id, sys_query_name);


--
-- Name: sys_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_queries
    ADD CONSTRAINT sys_queries_pkey PRIMARY KEY (sys_queries_id);


--
-- Name: sys_reset_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY sys_reset
    ADD CONSTRAINT sys_reset_pkey PRIMARY KEY (sys_reset_id);


--
-- Name: tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (task_id);


--
-- Name: tax_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tax_rates
    ADD CONSTRAINT tax_rates_pkey PRIMARY KEY (tax_rate_id);


--
-- Name: tax_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tax_types
    ADD CONSTRAINT tax_types_pkey PRIMARY KEY (tax_type_id);


--
-- Name: tax_types_tax_type_name_org_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tax_types
    ADD CONSTRAINT tax_types_tax_type_name_org_id_key UNIQUE (tax_type_name, org_id);


--
-- Name: tender_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tender_items
    ADD CONSTRAINT tender_items_pkey PRIMARY KEY (tender_item_id);


--
-- Name: tender_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tender_types
    ADD CONSTRAINT tender_types_pkey PRIMARY KEY (tender_type_id);


--
-- Name: tender_types_tender_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tender_types
    ADD CONSTRAINT tender_types_tender_type_name_key UNIQUE (tender_type_name);


--
-- Name: tenders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tenders
    ADD CONSTRAINT tenders_pkey PRIMARY KEY (tender_id);


--
-- Name: timesheet_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY timesheet
    ADD CONSTRAINT timesheet_pkey PRIMARY KEY (timesheet_id);


--
-- Name: trainings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY trainings
    ADD CONSTRAINT trainings_pkey PRIMARY KEY (training_id);


--
-- Name: transaction_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY transaction_details
    ADD CONSTRAINT transaction_details_pkey PRIMARY KEY (transaction_detail_id);


--
-- Name: transaction_links_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY transaction_links
    ADD CONSTRAINT transaction_links_pkey PRIMARY KEY (transaction_link_id);


--
-- Name: transaction_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY transaction_status
    ADD CONSTRAINT transaction_status_pkey PRIMARY KEY (transaction_status_id);


--
-- Name: transaction_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY transaction_types
    ADD CONSTRAINT transaction_types_pkey PRIMARY KEY (transaction_type_id);


--
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: workflow_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY workflow_logs
    ADD CONSTRAINT workflow_logs_pkey PRIMARY KEY (workflow_log_id);


--
-- Name: workflow_phases_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY workflow_phases
    ADD CONSTRAINT workflow_phases_pkey PRIMARY KEY (workflow_phase_id);


--
-- Name: workflow_sql_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY workflow_sql
    ADD CONSTRAINT workflow_sql_pkey PRIMARY KEY (workflow_sql_id);


--
-- Name: workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: root; Tablespace: 
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (workflow_id);


--
-- Name: account_types_accounts_class_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX account_types_accounts_class_id ON account_types USING btree (accounts_class_id);


--
-- Name: account_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX account_types_org_id ON account_types USING btree (org_id);


--
-- Name: accounts_account_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX accounts_account_type_id ON accounts USING btree (account_type_id);


--
-- Name: accounts_class_chat_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX accounts_class_chat_type_id ON accounts_class USING btree (chat_type_id);


--
-- Name: accounts_class_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX accounts_class_org_id ON accounts_class USING btree (org_id);


--
-- Name: accounts_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX accounts_org_id ON accounts USING btree (org_id);


--
-- Name: address_address_type_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX address_address_type_id ON address USING btree (address_type_id);


--
-- Name: address_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX address_org_id ON address USING btree (org_id);


--
-- Name: address_sys_country_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX address_sys_country_id ON address USING btree (sys_country_id);


--
-- Name: address_table_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX address_table_id ON address USING btree (table_id);


--
-- Name: address_table_name; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX address_table_name ON address USING btree (table_name);


--
-- Name: address_types_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX address_types_org_id ON address_types USING btree (org_id);


--
-- Name: adjustments_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX adjustments_currency_id ON adjustments USING btree (currency_id);


--
-- Name: adjustments_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX adjustments_org_id ON adjustments USING btree (org_id);


--
-- Name: advance_deductions_employee_month_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX advance_deductions_employee_month_id ON advance_deductions USING btree (employee_month_id);


--
-- Name: advance_deductions_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX advance_deductions_org_id ON advance_deductions USING btree (org_id);


--
-- Name: amortisation_asset_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX amortisation_asset_id ON amortisation USING btree (asset_id);


--
-- Name: applicants_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX applicants_org_id ON applicants USING btree (org_id);


--
-- Name: applications_contract_status_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX applications_contract_status_id ON applications USING btree (contract_status_id);


--
-- Name: applications_contract_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX applications_contract_type_id ON applications USING btree (contract_type_id);


--
-- Name: applications_employee_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX applications_employee_id ON applications USING btree (employee_id);


--
-- Name: applications_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX applications_entity_id ON applications USING btree (entity_id);


--
-- Name: applications_intake_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX applications_intake_id ON applications USING btree (intake_id);


--
-- Name: applications_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX applications_org_id ON applications USING btree (org_id);


--
-- Name: approval_checklists_approval_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approval_checklists_approval_id ON approval_checklists USING btree (approval_id);


--
-- Name: approval_checklists_checklist_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approval_checklists_checklist_id ON approval_checklists USING btree (checklist_id);


--
-- Name: approval_checklists_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approval_checklists_org_id ON approval_checklists USING btree (org_id);


--
-- Name: approvals_app_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approvals_app_entity_id ON approvals USING btree (app_entity_id);


--
-- Name: approvals_approve_status; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approvals_approve_status ON approvals USING btree (approve_status);


--
-- Name: approvals_forward_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approvals_forward_id ON approvals USING btree (forward_id);


--
-- Name: approvals_org_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approvals_org_entity_id ON approvals USING btree (org_entity_id);


--
-- Name: approvals_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approvals_org_id ON approvals USING btree (org_id);


--
-- Name: approvals_table_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approvals_table_id ON approvals USING btree (table_id);


--
-- Name: approvals_workflow_phase_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX approvals_workflow_phase_id ON approvals USING btree (workflow_phase_id);


--
-- Name: asset_movement_asset_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX asset_movement_asset_id ON asset_movement USING btree (asset_id);


--
-- Name: asset_movement_department_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX asset_movement_department_id ON asset_movement USING btree (department_id);


--
-- Name: asset_types_accumulated_account; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX asset_types_accumulated_account ON asset_types USING btree (accumulated_account);


--
-- Name: asset_types_asset_account; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX asset_types_asset_account ON asset_types USING btree (asset_account);


--
-- Name: asset_types_depreciation_account; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX asset_types_depreciation_account ON asset_types USING btree (depreciation_account);


--
-- Name: asset_types_disposal_account; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX asset_types_disposal_account ON asset_types USING btree (disposal_account);


--
-- Name: asset_types_valuation_account; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX asset_types_valuation_account ON asset_types USING btree (valuation_account);


--
-- Name: asset_valuations_asset_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX asset_valuations_asset_id ON asset_valuations USING btree (asset_id);


--
-- Name: assets_asset_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX assets_asset_type_id ON assets USING btree (asset_type_id);


--
-- Name: assets_item_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX assets_item_id ON assets USING btree (item_id);


--
-- Name: attendance_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX attendance_entity_id ON attendance USING btree (entity_id);


--
-- Name: attendance_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX attendance_org_id ON attendance USING btree (org_id);


--
-- Name: bank_accounts_account_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX bank_accounts_account_id ON bank_accounts USING btree (account_id);


--
-- Name: bank_accounts_bank_branch_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX bank_accounts_bank_branch_id ON bank_accounts USING btree (bank_branch_id);


--
-- Name: bank_accounts_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX bank_accounts_currency_id ON bank_accounts USING btree (currency_id);


--
-- Name: bank_accounts_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX bank_accounts_org_id ON bank_accounts USING btree (org_id);


--
-- Name: bank_branch_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX bank_branch_org_id ON bank_branch USING btree (org_id);


--
-- Name: banks_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX banks_org_id ON banks USING btree (org_id);


--
-- Name: bidders_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX bidders_entity_id ON bidders USING btree (entity_id);


--
-- Name: bidders_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX bidders_org_id ON bidders USING btree (org_id);


--
-- Name: bidders_tender_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX bidders_tender_id ON bidders USING btree (tender_id);


--
-- Name: bio_imports1_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX bio_imports1_org_id ON bio_imports1 USING btree (org_id);


--
-- Name: branch_bankid; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX branch_bankid ON bank_branch USING btree (bank_id);


--
-- Name: budget_lines_account_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX budget_lines_account_id ON budget_lines USING btree (account_id);


--
-- Name: budget_lines_budget_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX budget_lines_budget_id ON budget_lines USING btree (budget_id);


--
-- Name: budget_lines_item_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX budget_lines_item_id ON budget_lines USING btree (item_id);


--
-- Name: budget_lines_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX budget_lines_org_id ON budget_lines USING btree (org_id);


--
-- Name: budget_lines_period_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX budget_lines_period_id ON budget_lines USING btree (period_id);


--
-- Name: budget_lines_transaction_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX budget_lines_transaction_id ON budget_lines USING btree (transaction_id);


--
-- Name: budgets_department_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX budgets_department_id ON budgets USING btree (department_id);


--
-- Name: budgets_fiscal_year_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX budgets_fiscal_year_id ON budgets USING btree (fiscal_year_id);


--
-- Name: budgets_link_budget_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX budgets_link_budget_id ON budgets USING btree (link_budget_id);


--
-- Name: budgets_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX budgets_org_id ON budgets USING btree (org_id);


--
-- Name: career_development_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX career_development_org_id ON career_development USING btree (org_id);


--
-- Name: case_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX case_types_org_id ON case_types USING btree (org_id);


--
-- Name: casual_application_category_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX casual_application_category_id ON casual_application USING btree (casual_category_id);


--
-- Name: casual_application_department_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX casual_application_department_id ON casual_application USING btree (department_id);


--
-- Name: casual_application_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX casual_application_entity_id ON casual_application USING btree (entity_id);


--
-- Name: casual_application_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX casual_application_org_id ON casual_application USING btree (org_id);


--
-- Name: casual_category_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX casual_category_org_id ON casual_category USING btree (org_id);


--
-- Name: casuals_casual_application_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX casuals_casual_application_id ON casuals USING btree (casual_application_id);


--
-- Name: casuals_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX casuals_entity_id ON casuals USING btree (entity_id);


--
-- Name: casuals_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX casuals_org_id ON casuals USING btree (org_id);


--
-- Name: checklists_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX checklists_org_id ON checklists USING btree (org_id);


--
-- Name: checklists_workflow_phase_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX checklists_workflow_phase_id ON checklists USING btree (workflow_phase_id);


--
-- Name: claim_details_claim_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX claim_details_claim_id ON claim_details USING btree (claim_id);


--
-- Name: claim_details_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX claim_details_currency_id ON claim_details USING btree (currency_id);


--
-- Name: claim_details_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX claim_details_org_id ON claim_details USING btree (org_id);


--
-- Name: claim_types_adjustment_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX claim_types_adjustment_id ON claim_types USING btree (adjustment_id);


--
-- Name: claim_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX claim_types_org_id ON claim_types USING btree (org_id);


--
-- Name: claims_claim_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX claims_claim_type_id ON claims USING btree (claim_type_id);


--
-- Name: claims_employee_adjustment_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX claims_employee_adjustment_id ON claims USING btree (employee_adjustment_id);


--
-- Name: claims_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX claims_entity_id ON claims USING btree (entity_id);


--
-- Name: claims_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX claims_org_id ON claims USING btree (org_id);


--
-- Name: contract_status_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX contract_status_org_id ON contract_status USING btree (org_id);


--
-- Name: contract_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX contract_types_org_id ON contract_types USING btree (org_id);


--
-- Name: contracts_bidder_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX contracts_bidder_id ON contracts USING btree (bidder_id);


--
-- Name: contracts_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX contracts_org_id ON contracts USING btree (org_id);


--
-- Name: currency_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX currency_org_id ON currency USING btree (org_id);


--
-- Name: currency_rates_currency_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX currency_rates_currency_id ON currency_rates USING btree (currency_id);


--
-- Name: currency_rates_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX currency_rates_org_id ON currency_rates USING btree (org_id);


--
-- Name: cv_projects_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX cv_projects_entity_id ON cv_projects USING btree (entity_id);


--
-- Name: cv_projects_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX cv_projects_org_id ON cv_projects USING btree (org_id);


--
-- Name: cv_seminars_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX cv_seminars_entity_id ON cv_seminars USING btree (entity_id);


--
-- Name: cv_seminars_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX cv_seminars_org_id ON cv_seminars USING btree (org_id);


--
-- Name: day_ledgers_bank_account_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX day_ledgers_bank_account_id ON day_ledgers USING btree (bank_account_id);


--
-- Name: day_ledgers_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX day_ledgers_currency_id ON day_ledgers USING btree (currency_id);


--
-- Name: day_ledgers_department_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX day_ledgers_department_id ON day_ledgers USING btree (department_id);


--
-- Name: day_ledgers_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX day_ledgers_entity_id ON day_ledgers USING btree (entity_id);


--
-- Name: day_ledgers_item_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX day_ledgers_item_id ON day_ledgers USING btree (item_id);


--
-- Name: day_ledgers_journal_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX day_ledgers_journal_id ON day_ledgers USING btree (journal_id);


--
-- Name: day_ledgers_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX day_ledgers_org_id ON day_ledgers USING btree (org_id);


--
-- Name: day_ledgers_store_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX day_ledgers_store_id ON day_ledgers USING btree (store_id);


--
-- Name: day_ledgers_transaction_status_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX day_ledgers_transaction_status_id ON day_ledgers USING btree (transaction_status_id);


--
-- Name: day_ledgers_transaction_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX day_ledgers_transaction_type_id ON day_ledgers USING btree (transaction_type_id);


--
-- Name: day_ledgers_workflow_table_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX day_ledgers_workflow_table_id ON day_ledgers USING btree (workflow_table_id);


--
-- Name: default_accounts_account_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_accounts_account_id ON default_accounts USING btree (account_id);


--
-- Name: default_accounts_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_accounts_org_id ON default_accounts USING btree (org_id);


--
-- Name: default_adjustments_adjustment_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_adjustments_adjustment_id ON default_adjustments USING btree (adjustment_id);


--
-- Name: default_adjustments_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_adjustments_entity_id ON default_adjustments USING btree (entity_id);


--
-- Name: default_adjustments_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_adjustments_org_id ON default_adjustments USING btree (org_id);


--
-- Name: default_banking_bank_branch_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_banking_bank_branch_id ON default_banking USING btree (bank_branch_id);


--
-- Name: default_banking_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_banking_currency_id ON default_banking USING btree (currency_id);


--
-- Name: default_banking_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_banking_entity_id ON default_banking USING btree (entity_id);


--
-- Name: default_banking_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_banking_org_id ON default_banking USING btree (org_id);


--
-- Name: default_tax_types_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_tax_types_entity_id ON default_tax_types USING btree (entity_id);


--
-- Name: default_tax_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_tax_types_org_id ON default_tax_types USING btree (org_id);


--
-- Name: default_tax_types_tax_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX default_tax_types_tax_type_id ON default_tax_types USING btree (tax_type_id);


--
-- Name: define_phases_entity_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX define_phases_entity_type_id ON define_phases USING btree (entity_type_id);


--
-- Name: define_phases_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX define_phases_org_id ON define_phases USING btree (org_id);


--
-- Name: define_phases_project_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX define_phases_project_type_id ON define_phases USING btree (project_type_id);


--
-- Name: define_tasks_define_phase_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX define_tasks_define_phase_id ON define_tasks USING btree (define_phase_id);


--
-- Name: define_tasks_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX define_tasks_org_id ON define_tasks USING btree (org_id);


--
-- Name: department_roles_department_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX department_roles_department_id ON department_roles USING btree (department_id);


--
-- Name: department_roles_ln_department_role_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX department_roles_ln_department_role_id ON department_roles USING btree (ln_department_role_id);


--
-- Name: department_roles_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX department_roles_org_id ON department_roles USING btree (org_id);


--
-- Name: departments_ln_department_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX departments_ln_department_id ON departments USING btree (ln_department_id);


--
-- Name: departments_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX departments_org_id ON departments USING btree (org_id);


--
-- Name: disability_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX disability_org_id ON disability USING btree (org_id);


--
-- Name: education_class_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX education_class_org_id ON education_class USING btree (org_id);


--
-- Name: education_education_class_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX education_education_class_id ON education USING btree (education_class_id);


--
-- Name: education_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX education_entity_id ON education USING btree (entity_id);


--
-- Name: education_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX education_org_id ON education USING btree (org_id);


--
-- Name: employee_adjustments_adjustment_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_adjustments_adjustment_id ON employee_adjustments USING btree (adjustment_id);


--
-- Name: employee_adjustments_employee_month_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_adjustments_employee_month_id ON employee_adjustments USING btree (employee_month_id);


--
-- Name: employee_adjustments_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_adjustments_org_id ON employee_adjustments USING btree (org_id);


--
-- Name: employee_advances_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_advances_currency_id ON employee_advances USING btree (currency_id);


--
-- Name: employee_advances_employee_month_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_advances_employee_month_id ON employee_advances USING btree (employee_month_id);


--
-- Name: employee_advances_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_advances_org_id ON employee_advances USING btree (org_id);


--
-- Name: employee_banking_bank_branch_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_banking_bank_branch_id ON employee_banking USING btree (bank_branch_id);


--
-- Name: employee_banking_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_banking_currency_id ON employee_banking USING btree (currency_id);


--
-- Name: employee_banking_employee_month_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_banking_employee_month_id ON employee_banking USING btree (employee_month_id);


--
-- Name: employee_banking_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_banking_org_id ON employee_banking USING btree (org_id);


--
-- Name: employee_cases_case_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_cases_case_type_id ON employee_cases USING btree (case_type_id);


--
-- Name: employee_cases_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_cases_entity_id ON employee_cases USING btree (entity_id);


--
-- Name: employee_cases_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_cases_org_id ON employee_cases USING btree (org_id);


--
-- Name: employee_leave_contact_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_leave_contact_entity_id ON employee_leave USING btree (contact_entity_id);


--
-- Name: employee_leave_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_leave_entity_id ON employee_leave USING btree (entity_id);


--
-- Name: employee_leave_leave_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_leave_leave_type_id ON employee_leave USING btree (leave_type_id);


--
-- Name: employee_leave_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_leave_org_id ON employee_leave USING btree (org_id);


--
-- Name: employee_leave_types_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_leave_types_entity_id ON employee_leave_types USING btree (entity_id);


--
-- Name: employee_leave_types_leave_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_leave_types_leave_type_id ON employee_leave_types USING btree (leave_type_id);


--
-- Name: employee_leave_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_leave_types_org_id ON employee_leave_types USING btree (org_id);


--
-- Name: employee_month_bank_branch_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_month_bank_branch_id ON employee_month USING btree (bank_branch_id);


--
-- Name: employee_month_bank_pay_group_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_month_bank_pay_group_id ON employee_month USING btree (pay_group_id);


--
-- Name: employee_month_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_month_currency_id ON employee_month USING btree (currency_id);


--
-- Name: employee_month_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_month_entity_id ON employee_month USING btree (entity_id);


--
-- Name: employee_month_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_month_org_id ON employee_month USING btree (org_id);


--
-- Name: employee_month_period_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_month_period_id ON employee_month USING btree (period_id);


--
-- Name: employee_objectives_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_objectives_entity_id ON employee_objectives USING btree (entity_id);


--
-- Name: employee_objectives_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_objectives_org_id ON employee_objectives USING btree (org_id);


--
-- Name: employee_overtime_employee_month_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_overtime_employee_month_id ON employee_overtime USING btree (employee_month_id);


--
-- Name: employee_overtime_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_overtime_org_id ON employee_overtime USING btree (org_id);


--
-- Name: employee_per_diem_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_per_diem_currency_id ON employee_per_diem USING btree (currency_id);


--
-- Name: employee_per_diem_employee_month_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_per_diem_employee_month_id ON employee_per_diem USING btree (employee_month_id);


--
-- Name: employee_per_diem_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_per_diem_org_id ON employee_per_diem USING btree (org_id);


--
-- Name: employee_tax_types_employee_month_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_tax_types_employee_month_id ON employee_tax_types USING btree (employee_month_id);


--
-- Name: employee_tax_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_tax_types_org_id ON employee_tax_types USING btree (org_id);


--
-- Name: employee_tax_types_tax_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_tax_types_tax_type_id ON employee_tax_types USING btree (tax_type_id);


--
-- Name: employee_trainings_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_trainings_entity_id ON employee_trainings USING btree (entity_id);


--
-- Name: employee_trainings_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_trainings_org_id ON employee_trainings USING btree (org_id);


--
-- Name: employee_trainings_training_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employee_trainings_training_id ON employee_trainings USING btree (training_id);


--
-- Name: employees_bank_branch_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employees_bank_branch_id ON employees USING btree (bank_branch_id);


--
-- Name: employees_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employees_currency_id ON employees USING btree (currency_id);


--
-- Name: employees_department_role_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employees_department_role_id ON employees USING btree (department_role_id);


--
-- Name: employees_disability_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employees_disability_id ON employees USING btree (disability_id);


--
-- Name: employees_location_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employees_location_id ON employees USING btree (location_id);


--
-- Name: employees_nation_of_birth; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employees_nation_of_birth ON employees USING btree (nation_of_birth);


--
-- Name: employees_nationality; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employees_nationality ON employees USING btree (nationality);


--
-- Name: employees_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employees_org_id ON employees USING btree (org_id);


--
-- Name: employees_pay_group_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employees_pay_group_id ON employees USING btree (pay_group_id);


--
-- Name: employees_pay_scale_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employees_pay_scale_id ON employees USING btree (pay_scale_id);


--
-- Name: employees_pay_scale_step_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employees_pay_scale_step_id ON employees USING btree (pay_scale_step_id);


--
-- Name: employment_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employment_entity_id ON employment USING btree (entity_id);


--
-- Name: employment_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX employment_org_id ON employment USING btree (org_id);


--
-- Name: entity_subscriptions_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entity_subscriptions_entity_id ON entity_subscriptions USING btree (entity_id);


--
-- Name: entity_subscriptions_entity_type_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entity_subscriptions_entity_type_id ON entity_subscriptions USING btree (entity_type_id);


--
-- Name: entity_subscriptions_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entity_subscriptions_org_id ON entity_subscriptions USING btree (org_id);


--
-- Name: entity_subscriptions_subscription_level_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entity_subscriptions_subscription_level_id ON entity_subscriptions USING btree (subscription_level_id);


--
-- Name: entity_types_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entity_types_org_id ON entity_types USING btree (org_id);


--
-- Name: entitys_account_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entitys_account_id ON entitys USING btree (account_id);


--
-- Name: entitys_entity_type_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entitys_entity_type_id ON entitys USING btree (entity_type_id);


--
-- Name: entitys_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entitys_org_id ON entitys USING btree (org_id);


--
-- Name: entitys_user_name; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entitys_user_name ON entitys USING btree (user_name);


--
-- Name: entry_forms_entered_by_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entry_forms_entered_by_id ON entry_forms USING btree (entered_by_id);


--
-- Name: entry_forms_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entry_forms_entity_id ON entry_forms USING btree (entity_id);


--
-- Name: entry_forms_form_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entry_forms_form_id ON entry_forms USING btree (form_id);


--
-- Name: entry_forms_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX entry_forms_org_id ON entry_forms USING btree (org_id);


--
-- Name: evaluation_points_career_development_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX evaluation_points_career_development_id ON evaluation_points USING btree (career_development_id);


--
-- Name: evaluation_points_job_review_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX evaluation_points_job_review_id ON evaluation_points USING btree (job_review_id);


--
-- Name: evaluation_points_objective_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX evaluation_points_objective_id ON evaluation_points USING btree (objective_id);


--
-- Name: evaluation_points_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX evaluation_points_org_id ON evaluation_points USING btree (org_id);


--
-- Name: evaluation_points_review_point_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX evaluation_points_review_point_id ON evaluation_points USING btree (review_point_id);


--
-- Name: fields_form_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX fields_form_id ON fields USING btree (form_id);


--
-- Name: fields_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX fields_org_id ON fields USING btree (org_id);


--
-- Name: fiscal_years_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fiscal_years_org_id ON fiscal_years USING btree (org_id);


--
-- Name: forms_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX forms_org_id ON forms USING btree (org_id);


--
-- Name: gls_account_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX gls_account_id ON gls USING btree (account_id);


--
-- Name: gls_journal_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX gls_journal_id ON gls USING btree (journal_id);


--
-- Name: gls_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX gls_org_id ON gls USING btree (org_id);


--
-- Name: holidays_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX holidays_org_id ON holidays USING btree (org_id);


--
-- Name: identification_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX identification_types_org_id ON identification_types USING btree (org_id);


--
-- Name: identifications_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX identifications_entity_id ON identifications USING btree (entity_id);


--
-- Name: identifications_identification_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX identifications_identification_type_id ON identifications USING btree (identification_type_id);


--
-- Name: identifications_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX identifications_org_id ON identifications USING btree (org_id);


--
-- Name: intake_department_role_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX intake_department_role_id ON intake USING btree (department_role_id);


--
-- Name: intake_location_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX intake_location_id ON intake USING btree (location_id);


--
-- Name: intake_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX intake_org_id ON intake USING btree (org_id);


--
-- Name: intake_pay_group_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX intake_pay_group_id ON intake USING btree (pay_group_id);


--
-- Name: intake_pay_scale_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX intake_pay_scale_id ON intake USING btree (pay_scale_id);


--
-- Name: interns_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX interns_entity_id ON interns USING btree (entity_id);


--
-- Name: interns_internship_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX interns_internship_id ON interns USING btree (internship_id);


--
-- Name: interns_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX interns_org_id ON interns USING btree (org_id);


--
-- Name: internships_department_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX internships_department_id ON internships USING btree (department_id);


--
-- Name: internships_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX internships_org_id ON internships USING btree (org_id);


--
-- Name: item_category_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX item_category_org_id ON item_category USING btree (org_id);


--
-- Name: item_units_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX item_units_org_id ON item_units USING btree (org_id);


--
-- Name: items_item_category_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX items_item_category_id ON items USING btree (item_category_id);


--
-- Name: items_item_unit_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX items_item_unit_id ON items USING btree (item_unit_id);


--
-- Name: items_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX items_org_id ON items USING btree (org_id);


--
-- Name: items_purchase_account_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX items_purchase_account_id ON items USING btree (purchase_account_id);


--
-- Name: items_sales_account_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX items_sales_account_id ON items USING btree (sales_account_id);


--
-- Name: items_tax_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX items_tax_type_id ON items USING btree (tax_type_id);


--
-- Name: job_reviews_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX job_reviews_entity_id ON job_reviews USING btree (entity_id);


--
-- Name: job_reviews_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX job_reviews_org_id ON job_reviews USING btree (org_id);


--
-- Name: job_reviews_review_category_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX job_reviews_review_category_id ON job_reviews USING btree (review_category_id);


--
-- Name: journals_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX journals_currency_id ON journals USING btree (currency_id);


--
-- Name: journals_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX journals_org_id ON journals USING btree (org_id);


--
-- Name: journals_period_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX journals_period_id ON journals USING btree (period_id);


--
-- Name: kin_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX kin_types_org_id ON kin_types USING btree (org_id);


--
-- Name: kins_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX kins_entity_id ON kins USING btree (entity_id);


--
-- Name: kins_kin_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX kins_kin_type_id ON kins USING btree (kin_type_id);


--
-- Name: kins_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX kins_org_id ON kins USING btree (org_id);


--
-- Name: lead_items_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX lead_items_entity_id ON lead_items USING btree (entity_id);


--
-- Name: lead_items_item_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX lead_items_item_id ON lead_items USING btree (item_id);


--
-- Name: lead_items_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX lead_items_org_id ON lead_items USING btree (org_id);


--
-- Name: leads_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX leads_entity_id ON leads USING btree (entity_id);


--
-- Name: leads_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX leads_org_id ON leads USING btree (org_id);


--
-- Name: leads_sale_person_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX leads_sale_person_id ON leads USING btree (sale_person_id);


--
-- Name: leave_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX leave_types_org_id ON leave_types USING btree (org_id);


--
-- Name: leave_work_days_employee_leave_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX leave_work_days_employee_leave_id ON leave_work_days USING btree (employee_leave_id);


--
-- Name: leave_work_days_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX leave_work_days_org_id ON leave_work_days USING btree (org_id);


--
-- Name: loan_monthly_loan_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX loan_monthly_loan_id ON loan_monthly USING btree (loan_id);


--
-- Name: loan_monthly_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX loan_monthly_org_id ON loan_monthly USING btree (org_id);


--
-- Name: loan_monthly_period_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX loan_monthly_period_id ON loan_monthly USING btree (period_id);


--
-- Name: loan_types_adjustment_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX loan_types_adjustment_id ON loan_types USING btree (adjustment_id);


--
-- Name: loan_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX loan_types_org_id ON loan_types USING btree (org_id);


--
-- Name: loans_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX loans_entity_id ON loans USING btree (entity_id);


--
-- Name: loans_loan_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX loans_loan_type_id ON loans USING btree (loan_type_id);


--
-- Name: loans_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX loans_org_id ON loans USING btree (org_id);


--
-- Name: locations_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX locations_org_id ON locations USING btree (org_id);


--
-- Name: objective_details_ln_objective_detail_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX objective_details_ln_objective_detail_id ON objective_details USING btree (ln_objective_detail_id);


--
-- Name: objective_details_objective_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX objective_details_objective_id ON objective_details USING btree (objective_id);


--
-- Name: objective_details_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX objective_details_org_id ON objective_details USING btree (org_id);


--
-- Name: objective_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX objective_types_org_id ON objective_types USING btree (org_id);


--
-- Name: objectives_employee_objective_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX objectives_employee_objective_id ON objectives USING btree (employee_objective_id);


--
-- Name: objectives_objective_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX objectives_objective_type_id ON objectives USING btree (objective_type_id);


--
-- Name: objectives_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX objectives_org_id ON objectives USING btree (org_id);


--
-- Name: orgs_currency_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX orgs_currency_id ON orgs USING btree (currency_id);


--
-- Name: orgs_parent_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX orgs_parent_org_id ON orgs USING btree (parent_org_id);


--
-- Name: pay_groups_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pay_groups_org_id ON pay_groups USING btree (org_id);


--
-- Name: pay_scale_steps_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pay_scale_steps_org_id ON pay_scale_steps USING btree (org_id);


--
-- Name: pay_scale_steps_pay_scale_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pay_scale_steps_pay_scale_id ON pay_scale_steps USING btree (pay_scale_id);


--
-- Name: pay_scale_years_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pay_scale_years_org_id ON pay_scale_years USING btree (org_id);


--
-- Name: pay_scale_years_pay_scale_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pay_scale_years_pay_scale_id ON pay_scale_years USING btree (pay_scale_id);


--
-- Name: pay_scales_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pay_scales_currency_id ON pay_scales USING btree (currency_id);


--
-- Name: pay_scales_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pay_scales_org_id ON pay_scales USING btree (org_id);


--
-- Name: payroll_ledger_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX payroll_ledger_currency_id ON payroll_ledger USING btree (currency_id);


--
-- Name: payroll_ledger_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX payroll_ledger_org_id ON payroll_ledger USING btree (org_id);


--
-- Name: pc_allocations_department_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_allocations_department_id ON pc_allocations USING btree (department_id);


--
-- Name: pc_allocations_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_allocations_org_id ON pc_allocations USING btree (org_id);


--
-- Name: pc_allocations_period_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_allocations_period_id ON pc_allocations USING btree (period_id);


--
-- Name: pc_banking_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_banking_org_id ON pc_banking USING btree (org_id);


--
-- Name: pc_banking_pc_allocation_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_banking_pc_allocation_id ON pc_banking USING btree (pc_allocation_id);


--
-- Name: pc_budget_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_budget_org_id ON pc_budget USING btree (org_id);


--
-- Name: pc_budget_pc_allocation_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_budget_pc_allocation_id ON pc_budget USING btree (pc_allocation_id);


--
-- Name: pc_budget_pc_item_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_budget_pc_item_id ON pc_budget USING btree (pc_item_id);


--
-- Name: pc_category_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_category_org_id ON pc_category USING btree (org_id);


--
-- Name: pc_expenditure_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_expenditure_org_id ON pc_expenditure USING btree (org_id);


--
-- Name: pc_expenditure_pc_allocation_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_expenditure_pc_allocation_id ON pc_expenditure USING btree (pc_allocation_id);


--
-- Name: pc_expenditure_pc_item_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_expenditure_pc_item_id ON pc_expenditure USING btree (pc_item_id);


--
-- Name: pc_items_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_items_org_id ON pc_items USING btree (org_id);


--
-- Name: pc_items_pc_category_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_items_pc_category_id ON pc_items USING btree (pc_category_id);


--
-- Name: pc_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pc_types_org_id ON pc_types USING btree (org_id);


--
-- Name: period_tax_rates_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX period_tax_rates_org_id ON period_tax_rates USING btree (org_id);


--
-- Name: period_tax_rates_period_tax_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX period_tax_rates_period_tax_type_id ON period_tax_rates USING btree (period_tax_type_id);


--
-- Name: period_tax_types_account_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX period_tax_types_account_id ON period_tax_types USING btree (account_id);


--
-- Name: period_tax_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX period_tax_types_org_id ON period_tax_types USING btree (org_id);


--
-- Name: period_tax_types_period_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX period_tax_types_period_id ON period_tax_types USING btree (period_id);


--
-- Name: period_tax_types_tax_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX period_tax_types_tax_type_id ON period_tax_types USING btree (tax_type_id);


--
-- Name: periods_fiscal_year_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX periods_fiscal_year_id ON periods USING btree (fiscal_year_id);


--
-- Name: periods_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX periods_org_id ON periods USING btree (org_id);


--
-- Name: phases_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX phases_org_id ON phases USING btree (org_id);


--
-- Name: phases_project_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX phases_project_id ON phases USING btree (project_id);


--
-- Name: project_cost_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_cost_org_id ON project_cost USING btree (org_id);


--
-- Name: project_cost_phase_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_cost_phase_id ON project_cost USING btree (phase_id);


--
-- Name: project_locations_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_locations_org_id ON project_locations USING btree (org_id);


--
-- Name: project_locations_project_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_locations_project_id ON project_locations USING btree (project_id);


--
-- Name: project_staff_costs_bank_branch_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_staff_costs_bank_branch_id ON project_staff_costs USING btree (bank_branch_id);


--
-- Name: project_staff_costs_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_staff_costs_entity_id ON project_staff_costs USING btree (entity_id);


--
-- Name: project_staff_costs_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_staff_costs_org_id ON project_staff_costs USING btree (org_id);


--
-- Name: project_staff_costs_pay_group_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_staff_costs_pay_group_id ON project_staff_costs USING btree (pay_group_id);


--
-- Name: project_staff_costs_period_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_staff_costs_period_id ON project_staff_costs USING btree (period_id);


--
-- Name: project_staff_costs_project_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_staff_costs_project_id ON project_staff_costs USING btree (project_id);


--
-- Name: project_staff_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_staff_entity_id ON project_staff USING btree (entity_id);


--
-- Name: project_staff_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_staff_org_id ON project_staff USING btree (org_id);


--
-- Name: project_staff_project_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_staff_project_id ON project_staff USING btree (project_id);


--
-- Name: project_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX project_types_org_id ON project_types USING btree (org_id);


--
-- Name: projects_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX projects_entity_id ON projects USING btree (entity_id);


--
-- Name: projects_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX projects_org_id ON projects USING btree (org_id);


--
-- Name: projects_project_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX projects_project_type_id ON projects USING btree (project_type_id);


--
-- Name: quotations_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX quotations_entity_id ON quotations USING btree (entity_id);


--
-- Name: quotations_item_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX quotations_item_id ON quotations USING btree (item_id);


--
-- Name: quotations_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX quotations_org_id ON quotations USING btree (org_id);


--
-- Name: reporting_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX reporting_entity_id ON reporting USING btree (entity_id);


--
-- Name: reporting_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX reporting_org_id ON reporting USING btree (org_id);


--
-- Name: reporting_report_to_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX reporting_report_to_id ON reporting USING btree (report_to_id);


--
-- Name: review_category_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX review_category_org_id ON review_category USING btree (org_id);


--
-- Name: review_points_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX review_points_org_id ON review_points USING btree (org_id);


--
-- Name: review_points_review_category_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX review_points_review_category_id ON review_points USING btree (review_category_id);


--
-- Name: shift_schedule_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX shift_schedule_entity_id ON shift_schedule USING btree (entity_id);


--
-- Name: shift_schedule_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX shift_schedule_org_id ON shift_schedule USING btree (org_id);


--
-- Name: shift_schedule_shift_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX shift_schedule_shift_id ON shift_schedule USING btree (shift_id);


--
-- Name: shifts_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX shifts_org_id ON shifts USING btree (org_id);


--
-- Name: skill_category_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX skill_category_org_id ON skill_category USING btree (org_id);


--
-- Name: skill_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX skill_types_org_id ON skill_types USING btree (org_id);


--
-- Name: skill_types_skill_category_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX skill_types_skill_category_id ON skill_types USING btree (skill_category_id);


--
-- Name: skills_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX skills_entity_id ON skills USING btree (entity_id);


--
-- Name: skills_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX skills_org_id ON skills USING btree (org_id);


--
-- Name: skills_skill_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX skills_skill_type_id ON skills USING btree (skill_type_id);


--
-- Name: stock_lines_item_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX stock_lines_item_id ON stock_lines USING btree (item_id);


--
-- Name: stock_lines_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX stock_lines_org_id ON stock_lines USING btree (org_id);


--
-- Name: stock_lines_stock_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX stock_lines_stock_id ON stock_lines USING btree (stock_id);


--
-- Name: stocks_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX stocks_org_id ON stocks USING btree (org_id);


--
-- Name: stocks_store_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX stocks_store_id ON stocks USING btree (store_id);


--
-- Name: stores_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX stores_org_id ON stores USING btree (org_id);


--
-- Name: sub_fields_field_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sub_fields_field_id ON sub_fields USING btree (field_id);


--
-- Name: sub_fields_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sub_fields_org_id ON sub_fields USING btree (org_id);


--
-- Name: subscription_levels_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX subscription_levels_org_id ON subscription_levels USING btree (org_id);


--
-- Name: sys_audit_details_sys_audit_trail_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_audit_details_sys_audit_trail_id ON sys_audit_details USING btree (sys_audit_trail_id);


--
-- Name: sys_countrys_sys_continent_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_countrys_sys_continent_id ON sys_countrys USING btree (sys_continent_id);


--
-- Name: sys_dashboard_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_dashboard_entity_id ON sys_dashboard USING btree (entity_id);


--
-- Name: sys_dashboard_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_dashboard_org_id ON sys_dashboard USING btree (org_id);


--
-- Name: sys_emailed_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_emailed_org_id ON sys_emailed USING btree (org_id);


--
-- Name: sys_emailed_sys_email_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_emailed_sys_email_id ON sys_emailed USING btree (sys_email_id);


--
-- Name: sys_emailed_table_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_emailed_table_id ON sys_emailed USING btree (table_id);


--
-- Name: sys_emails_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_emails_org_id ON sys_emails USING btree (org_id);


--
-- Name: sys_files_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_files_org_id ON sys_files USING btree (org_id);


--
-- Name: sys_files_table_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_files_table_id ON sys_files USING btree (table_id);


--
-- Name: sys_logins_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_logins_entity_id ON sys_logins USING btree (entity_id);


--
-- Name: sys_news_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_news_org_id ON sys_news USING btree (org_id);


--
-- Name: sys_queries_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_queries_org_id ON sys_queries USING btree (org_id);


--
-- Name: sys_reset_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_reset_entity_id ON sys_reset USING btree (entity_id);


--
-- Name: sys_reset_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX sys_reset_org_id ON sys_reset USING btree (org_id);


--
-- Name: tasks_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tasks_entity_id ON tasks USING btree (entity_id);


--
-- Name: tasks_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tasks_org_id ON tasks USING btree (org_id);


--
-- Name: tasks_phase_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tasks_phase_id ON tasks USING btree (phase_id);


--
-- Name: tax_rates_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tax_rates_org_id ON tax_rates USING btree (org_id);


--
-- Name: tax_rates_tax_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tax_rates_tax_type_id ON tax_rates USING btree (tax_type_id);


--
-- Name: tax_types_account_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tax_types_account_id ON tax_types USING btree (account_id);


--
-- Name: tax_types_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tax_types_currency_id ON tax_types USING btree (currency_id);


--
-- Name: tax_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tax_types_org_id ON tax_types USING btree (org_id);


--
-- Name: tender_items_bidder_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tender_items_bidder_id ON tender_items USING btree (bidder_id);


--
-- Name: tender_items_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tender_items_org_id ON tender_items USING btree (org_id);


--
-- Name: tender_types_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tender_types_org_id ON tender_types USING btree (org_id);


--
-- Name: tenders_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tenders_org_id ON tenders USING btree (org_id);


--
-- Name: tenders_tender_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX tenders_tender_type_id ON tenders USING btree (tender_type_id);


--
-- Name: timesheet_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX timesheet_org_id ON timesheet USING btree (org_id);


--
-- Name: timesheet_task_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX timesheet_task_id ON timesheet USING btree (task_id);


--
-- Name: trainings_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX trainings_org_id ON trainings USING btree (org_id);


--
-- Name: transaction_details_account_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transaction_details_account_id ON transaction_details USING btree (account_id);


--
-- Name: transaction_details_item_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transaction_details_item_id ON transaction_details USING btree (item_id);


--
-- Name: transaction_details_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transaction_details_org_id ON transaction_details USING btree (org_id);


--
-- Name: transaction_details_transaction_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transaction_details_transaction_id ON transaction_details USING btree (transaction_id);


--
-- Name: transaction_links_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transaction_links_org_id ON transaction_links USING btree (org_id);


--
-- Name: transaction_links_transaction_detail_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transaction_links_transaction_detail_id ON transaction_links USING btree (transaction_detail_id);


--
-- Name: transaction_links_transaction_detail_to; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transaction_links_transaction_detail_to ON transaction_links USING btree (transaction_detail_to);


--
-- Name: transaction_links_transaction_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transaction_links_transaction_id ON transaction_links USING btree (transaction_id);


--
-- Name: transaction_links_transaction_to; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transaction_links_transaction_to ON transaction_links USING btree (transaction_to);


--
-- Name: transactions_bank_account_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transactions_bank_account_id ON transactions USING btree (bank_account_id);


--
-- Name: transactions_currency_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transactions_currency_id ON transactions USING btree (currency_id);


--
-- Name: transactions_department_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transactions_department_id ON transactions USING btree (department_id);


--
-- Name: transactions_entity_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transactions_entity_id ON transactions USING btree (entity_id);


--
-- Name: transactions_journal_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transactions_journal_id ON transactions USING btree (journal_id);


--
-- Name: transactions_org_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transactions_org_id ON transactions USING btree (org_id);


--
-- Name: transactions_transaction_status_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transactions_transaction_status_id ON transactions USING btree (transaction_status_id);


--
-- Name: transactions_transaction_type_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transactions_transaction_type_id ON transactions USING btree (transaction_type_id);


--
-- Name: transactions_workflow_table_id; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX transactions_workflow_table_id ON transactions USING btree (workflow_table_id);


--
-- Name: workflow_logs_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX workflow_logs_org_id ON workflow_logs USING btree (org_id);


--
-- Name: workflow_phases_approval_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX workflow_phases_approval_entity_id ON workflow_phases USING btree (approval_entity_id);


--
-- Name: workflow_phases_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX workflow_phases_org_id ON workflow_phases USING btree (org_id);


--
-- Name: workflow_phases_workflow_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX workflow_phases_workflow_id ON workflow_phases USING btree (workflow_id);


--
-- Name: workflow_sql_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX workflow_sql_org_id ON workflow_sql USING btree (org_id);


--
-- Name: workflow_sql_workflow_phase_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX workflow_sql_workflow_phase_id ON workflow_sql USING btree (workflow_phase_id);


--
-- Name: workflows_org_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX workflows_org_id ON workflows USING btree (org_id);


--
-- Name: workflows_source_entity_id; Type: INDEX; Schema: public; Owner: root; Tablespace: 
--

CREATE INDEX workflows_source_entity_id ON workflows USING btree (source_entity_id);


--
-- Name: af_upd_transaction_details; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER af_upd_transaction_details AFTER INSERT OR DELETE OR UPDATE ON transaction_details FOR EACH ROW EXECUTE PROCEDURE af_upd_transaction_details();


--
-- Name: ins_address; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER ins_address BEFORE INSERT OR UPDATE ON address FOR EACH ROW EXECUTE PROCEDURE ins_address();


--
-- Name: ins_applicants; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_applicants BEFORE INSERT OR UPDATE ON applicants FOR EACH ROW EXECUTE PROCEDURE ins_applicants();


--
-- Name: ins_approvals; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER ins_approvals BEFORE INSERT ON approvals FOR EACH ROW EXECUTE PROCEDURE ins_approvals();


--
-- Name: ins_asset_valuations; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_asset_valuations BEFORE INSERT OR UPDATE ON asset_valuations FOR EACH ROW EXECUTE PROCEDURE ins_asset_valuations();


--
-- Name: ins_bf_periods; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_bf_periods BEFORE INSERT ON periods FOR EACH ROW EXECUTE PROCEDURE ins_bf_periods();


--
-- Name: ins_employee_adjustments; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_employee_adjustments BEFORE INSERT OR UPDATE ON employee_adjustments FOR EACH ROW EXECUTE PROCEDURE ins_employee_adjustments();


--
-- Name: ins_employee_leave; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_employee_leave BEFORE INSERT OR UPDATE ON employee_leave FOR EACH ROW EXECUTE PROCEDURE ins_employee_leave();


--
-- Name: ins_employee_leave_types; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_employee_leave_types BEFORE INSERT ON employee_leave_types FOR EACH ROW EXECUTE PROCEDURE ins_employee_leave_types();


--
-- Name: ins_employee_month; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_employee_month BEFORE INSERT ON employee_month FOR EACH ROW EXECUTE PROCEDURE ins_employee_month();


--
-- Name: ins_employees; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_employees BEFORE INSERT OR UPDATE ON employees FOR EACH ROW EXECUTE PROCEDURE ins_employees();


--
-- Name: ins_entitys; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER ins_entitys AFTER INSERT ON entitys FOR EACH ROW EXECUTE PROCEDURE ins_entitys();


--
-- Name: ins_entry_forms; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER ins_entry_forms BEFORE INSERT ON entry_forms FOR EACH ROW EXECUTE PROCEDURE ins_entry_forms();


--
-- Name: ins_fields; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER ins_fields BEFORE INSERT ON fields FOR EACH ROW EXECUTE PROCEDURE ins_fields();


--
-- Name: ins_fiscal_years; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_fiscal_years AFTER INSERT ON fiscal_years FOR EACH ROW EXECUTE PROCEDURE ins_fiscal_years();


--
-- Name: ins_job_reviews; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_job_reviews AFTER INSERT ON job_reviews FOR EACH ROW EXECUTE PROCEDURE ins_job_reviews();


--
-- Name: ins_leave_work_days; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_leave_work_days BEFORE INSERT ON leave_work_days FOR EACH ROW EXECUTE PROCEDURE ins_leave_work_days();


--
-- Name: ins_objective_details; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_objective_details BEFORE INSERT OR UPDATE ON objective_details FOR EACH ROW EXECUTE PROCEDURE ins_objective_details();


--
-- Name: ins_objectives; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_objectives AFTER INSERT OR UPDATE ON objectives FOR EACH ROW EXECUTE PROCEDURE ins_objectives();


--
-- Name: ins_password; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER ins_password BEFORE INSERT OR UPDATE ON entitys FOR EACH ROW EXECUTE PROCEDURE ins_password();


--
-- Name: ins_period_tax_types; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_period_tax_types AFTER INSERT ON period_tax_types FOR EACH ROW EXECUTE PROCEDURE ins_period_tax_types();


--
-- Name: ins_periods; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_periods BEFORE INSERT OR UPDATE ON periods FOR EACH ROW EXECUTE PROCEDURE ins_periods();


--
-- Name: ins_projects; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_projects AFTER INSERT ON projects FOR EACH ROW EXECUTE PROCEDURE ins_projects();


--
-- Name: ins_sub_fields; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER ins_sub_fields BEFORE INSERT ON sub_fields FOR EACH ROW EXECUTE PROCEDURE ins_sub_fields();


--
-- Name: ins_sys_reset; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER ins_sys_reset AFTER INSERT ON sys_reset FOR EACH ROW EXECUTE PROCEDURE ins_sys_reset();


--
-- Name: ins_taxes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ins_taxes AFTER INSERT ON employees FOR EACH ROW EXECUTE PROCEDURE ins_taxes();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON entry_forms FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON periods FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON employee_leave FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON leave_work_days FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON casual_application FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON casuals FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON interns FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON employee_objectives FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON job_reviews FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON employee_overtime FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON employee_per_diem FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON claims FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON transactions FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON budgets FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON pc_allocations FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_action; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON pc_expenditure FOR EACH ROW EXECUTE PROCEDURE upd_action();


--
-- Name: upd_applications; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_applications BEFORE UPDATE ON applications FOR EACH ROW EXECUTE PROCEDURE upd_applications();


--
-- Name: upd_approvals; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER upd_approvals AFTER INSERT OR UPDATE ON approvals FOR EACH ROW EXECUTE PROCEDURE upd_approvals();


--
-- Name: upd_budget_lines; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_budget_lines BEFORE INSERT OR UPDATE ON budget_lines FOR EACH ROW EXECUTE PROCEDURE upd_budget_lines();


--
-- Name: upd_employee_adjustments; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_employee_adjustments AFTER INSERT OR UPDATE ON employee_adjustments FOR EACH ROW EXECUTE PROCEDURE upd_employee_adjustments();


--
-- Name: upd_employee_month; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_employee_month AFTER INSERT ON employee_month FOR EACH ROW EXECUTE PROCEDURE upd_employee_month();


--
-- Name: upd_employee_per_diem; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_employee_per_diem BEFORE INSERT OR UPDATE ON employee_per_diem FOR EACH ROW EXECUTE PROCEDURE upd_employee_per_diem();


--
-- Name: upd_gls; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_gls BEFORE INSERT OR UPDATE ON gls FOR EACH ROW EXECUTE PROCEDURE upd_gls();


--
-- Name: upd_objective_details; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_objective_details AFTER INSERT OR UPDATE ON objective_details FOR EACH ROW EXECUTE PROCEDURE upd_objective_details();


--
-- Name: upd_transaction_details; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_transaction_details BEFORE INSERT OR UPDATE ON transaction_details FOR EACH ROW EXECUTE PROCEDURE upd_transaction_details();


--
-- Name: upd_transactions; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upd_transactions BEFORE INSERT OR UPDATE ON transactions FOR EACH ROW EXECUTE PROCEDURE upd_transactions();


--
-- Name: account_types_accounts_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY account_types
    ADD CONSTRAINT account_types_accounts_class_id_fkey FOREIGN KEY (accounts_class_id) REFERENCES accounts_class(accounts_class_id);


--
-- Name: account_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY account_types
    ADD CONSTRAINT account_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: accounts_account_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_account_type_id_fkey FOREIGN KEY (account_type_id) REFERENCES account_types(account_type_id);


--
-- Name: accounts_class_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY accounts_class
    ADD CONSTRAINT accounts_class_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: accounts_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: address_address_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY address
    ADD CONSTRAINT address_address_type_id_fkey FOREIGN KEY (address_type_id) REFERENCES address_types(address_type_id);


--
-- Name: address_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY address
    ADD CONSTRAINT address_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: address_sys_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY address
    ADD CONSTRAINT address_sys_country_id_fkey FOREIGN KEY (sys_country_id) REFERENCES sys_countrys(sys_country_id);


--
-- Name: address_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY address_types
    ADD CONSTRAINT address_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: adjustments_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY adjustments
    ADD CONSTRAINT adjustments_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: adjustments_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY adjustments
    ADD CONSTRAINT adjustments_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: advance_deductions_employee_month_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY advance_deductions
    ADD CONSTRAINT advance_deductions_employee_month_id_fkey FOREIGN KEY (employee_month_id) REFERENCES employee_month(employee_month_id);


--
-- Name: advance_deductions_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY advance_deductions
    ADD CONSTRAINT advance_deductions_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: amortisation_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY amortisation
    ADD CONSTRAINT amortisation_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES assets(asset_id);


--
-- Name: amortisation_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY amortisation
    ADD CONSTRAINT amortisation_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: applicants_disability_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY applicants
    ADD CONSTRAINT applicants_disability_id_fkey FOREIGN KEY (disability_id) REFERENCES disability(disability_id);


--
-- Name: applicants_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY applicants
    ADD CONSTRAINT applicants_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: applicants_nationality_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY applicants
    ADD CONSTRAINT applicants_nationality_fkey FOREIGN KEY (nationality) REFERENCES sys_countrys(sys_country_id);


--
-- Name: applicants_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY applicants
    ADD CONSTRAINT applicants_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: applications_contract_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_contract_status_id_fkey FOREIGN KEY (contract_status_id) REFERENCES contract_status(contract_status_id);


--
-- Name: applications_contract_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_contract_type_id_fkey FOREIGN KEY (contract_type_id) REFERENCES contract_types(contract_type_id);


--
-- Name: applications_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES employees(entity_id);


--
-- Name: applications_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: applications_intake_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_intake_id_fkey FOREIGN KEY (intake_id) REFERENCES intake(intake_id);


--
-- Name: applications_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY applications
    ADD CONSTRAINT applications_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: approval_checklists_approval_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY approval_checklists
    ADD CONSTRAINT approval_checklists_approval_id_fkey FOREIGN KEY (approval_id) REFERENCES approvals(approval_id);


--
-- Name: approval_checklists_checklist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY approval_checklists
    ADD CONSTRAINT approval_checklists_checklist_id_fkey FOREIGN KEY (checklist_id) REFERENCES checklists(checklist_id);


--
-- Name: approval_checklists_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY approval_checklists
    ADD CONSTRAINT approval_checklists_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: approvals_app_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY approvals
    ADD CONSTRAINT approvals_app_entity_id_fkey FOREIGN KEY (app_entity_id) REFERENCES entitys(entity_id);


--
-- Name: approvals_org_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY approvals
    ADD CONSTRAINT approvals_org_entity_id_fkey FOREIGN KEY (org_entity_id) REFERENCES entitys(entity_id);


--
-- Name: approvals_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY approvals
    ADD CONSTRAINT approvals_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: approvals_workflow_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY approvals
    ADD CONSTRAINT approvals_workflow_phase_id_fkey FOREIGN KEY (workflow_phase_id) REFERENCES workflow_phases(workflow_phase_id);


--
-- Name: asset_movement_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_movement
    ADD CONSTRAINT asset_movement_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES assets(asset_id);


--
-- Name: asset_movement_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_movement
    ADD CONSTRAINT asset_movement_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(department_id);


--
-- Name: asset_movement_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_movement
    ADD CONSTRAINT asset_movement_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: asset_types_accumulated_account_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_types
    ADD CONSTRAINT asset_types_accumulated_account_fkey FOREIGN KEY (accumulated_account) REFERENCES accounts(account_id);


--
-- Name: asset_types_asset_account_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_types
    ADD CONSTRAINT asset_types_asset_account_fkey FOREIGN KEY (asset_account) REFERENCES accounts(account_id);


--
-- Name: asset_types_depreciation_account_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_types
    ADD CONSTRAINT asset_types_depreciation_account_fkey FOREIGN KEY (depreciation_account) REFERENCES accounts(account_id);


--
-- Name: asset_types_disposal_account_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_types
    ADD CONSTRAINT asset_types_disposal_account_fkey FOREIGN KEY (disposal_account) REFERENCES accounts(account_id);


--
-- Name: asset_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_types
    ADD CONSTRAINT asset_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: asset_types_valuation_account_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_types
    ADD CONSTRAINT asset_types_valuation_account_fkey FOREIGN KEY (valuation_account) REFERENCES accounts(account_id);


--
-- Name: asset_valuations_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_valuations
    ADD CONSTRAINT asset_valuations_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES assets(asset_id);


--
-- Name: asset_valuations_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asset_valuations
    ADD CONSTRAINT asset_valuations_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: assets_asset_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY assets
    ADD CONSTRAINT assets_asset_type_id_fkey FOREIGN KEY (asset_type_id) REFERENCES asset_types(asset_type_id);


--
-- Name: assets_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY assets
    ADD CONSTRAINT assets_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(item_id);


--
-- Name: assets_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY assets
    ADD CONSTRAINT assets_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: attendance_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attendance
    ADD CONSTRAINT attendance_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: attendance_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY attendance
    ADD CONSTRAINT attendance_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: bank_accounts_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bank_accounts
    ADD CONSTRAINT bank_accounts_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(account_id);


--
-- Name: bank_accounts_bank_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bank_accounts
    ADD CONSTRAINT bank_accounts_bank_branch_id_fkey FOREIGN KEY (bank_branch_id) REFERENCES bank_branch(bank_branch_id);


--
-- Name: bank_accounts_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bank_accounts
    ADD CONSTRAINT bank_accounts_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: bank_accounts_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bank_accounts
    ADD CONSTRAINT bank_accounts_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: bank_branch_bank_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bank_branch
    ADD CONSTRAINT bank_branch_bank_id_fkey FOREIGN KEY (bank_id) REFERENCES banks(bank_id);


--
-- Name: bank_branch_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bank_branch
    ADD CONSTRAINT bank_branch_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: banks_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY banks
    ADD CONSTRAINT banks_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: banks_sys_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY banks
    ADD CONSTRAINT banks_sys_country_id_fkey FOREIGN KEY (sys_country_id) REFERENCES sys_countrys(sys_country_id);


--
-- Name: bidders_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bidders
    ADD CONSTRAINT bidders_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: bidders_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bidders
    ADD CONSTRAINT bidders_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: bidders_tender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bidders
    ADD CONSTRAINT bidders_tender_id_fkey FOREIGN KEY (tender_id) REFERENCES tenders(tender_id);


--
-- Name: bio_imports1_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bio_imports1
    ADD CONSTRAINT bio_imports1_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: budget_lines_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budget_lines
    ADD CONSTRAINT budget_lines_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(account_id);


--
-- Name: budget_lines_budget_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budget_lines
    ADD CONSTRAINT budget_lines_budget_id_fkey FOREIGN KEY (budget_id) REFERENCES budgets(budget_id);


--
-- Name: budget_lines_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budget_lines
    ADD CONSTRAINT budget_lines_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(item_id);


--
-- Name: budget_lines_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budget_lines
    ADD CONSTRAINT budget_lines_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: budget_lines_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budget_lines
    ADD CONSTRAINT budget_lines_period_id_fkey FOREIGN KEY (period_id) REFERENCES periods(period_id);


--
-- Name: budget_lines_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budget_lines
    ADD CONSTRAINT budget_lines_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id);


--
-- Name: budgets_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budgets
    ADD CONSTRAINT budgets_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(department_id);


--
-- Name: budgets_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budgets
    ADD CONSTRAINT budgets_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: budgets_fiscal_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budgets
    ADD CONSTRAINT budgets_fiscal_year_id_fkey FOREIGN KEY (fiscal_year_id) REFERENCES fiscal_years(fiscal_year_id);


--
-- Name: budgets_link_budget_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budgets
    ADD CONSTRAINT budgets_link_budget_id_fkey FOREIGN KEY (link_budget_id) REFERENCES budgets(budget_id);


--
-- Name: budgets_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY budgets
    ADD CONSTRAINT budgets_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: career_development_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY career_development
    ADD CONSTRAINT career_development_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: case_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY case_types
    ADD CONSTRAINT case_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: casual_application_casual_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY casual_application
    ADD CONSTRAINT casual_application_casual_category_id_fkey FOREIGN KEY (casual_category_id) REFERENCES casual_category(casual_category_id);


--
-- Name: casual_application_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY casual_application
    ADD CONSTRAINT casual_application_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(department_id);


--
-- Name: casual_application_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY casual_application
    ADD CONSTRAINT casual_application_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: casual_application_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY casual_application
    ADD CONSTRAINT casual_application_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: casual_category_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY casual_category
    ADD CONSTRAINT casual_category_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: casuals_casual_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY casuals
    ADD CONSTRAINT casuals_casual_application_id_fkey FOREIGN KEY (casual_application_id) REFERENCES casual_application(casual_application_id);


--
-- Name: casuals_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY casuals
    ADD CONSTRAINT casuals_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: casuals_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY casuals
    ADD CONSTRAINT casuals_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: checklists_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY checklists
    ADD CONSTRAINT checklists_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: checklists_workflow_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY checklists
    ADD CONSTRAINT checklists_workflow_phase_id_fkey FOREIGN KEY (workflow_phase_id) REFERENCES workflow_phases(workflow_phase_id);


--
-- Name: claim_details_claim_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claim_details
    ADD CONSTRAINT claim_details_claim_id_fkey FOREIGN KEY (claim_id) REFERENCES claims(claim_id);


--
-- Name: claim_details_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claim_details
    ADD CONSTRAINT claim_details_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: claim_details_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claim_details
    ADD CONSTRAINT claim_details_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: claim_types_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claim_types
    ADD CONSTRAINT claim_types_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES adjustments(adjustment_id);


--
-- Name: claim_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claim_types
    ADD CONSTRAINT claim_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: claims_claim_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claims
    ADD CONSTRAINT claims_claim_type_id_fkey FOREIGN KEY (claim_type_id) REFERENCES claim_types(claim_type_id);


--
-- Name: claims_employee_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claims
    ADD CONSTRAINT claims_employee_adjustment_id_fkey FOREIGN KEY (employee_adjustment_id) REFERENCES employee_adjustments(employee_adjustment_id);


--
-- Name: claims_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claims
    ADD CONSTRAINT claims_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: claims_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY claims
    ADD CONSTRAINT claims_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: contract_status_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY contract_status
    ADD CONSTRAINT contract_status_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: contract_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY contract_types
    ADD CONSTRAINT contract_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: contracts_bidder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY contracts
    ADD CONSTRAINT contracts_bidder_id_fkey FOREIGN KEY (bidder_id) REFERENCES bidders(bidder_id);


--
-- Name: contracts_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY contracts
    ADD CONSTRAINT contracts_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: currency_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY currency
    ADD CONSTRAINT currency_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: currency_rates_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY currency_rates
    ADD CONSTRAINT currency_rates_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: currency_rates_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY currency_rates
    ADD CONSTRAINT currency_rates_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: cv_projects_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cv_projects
    ADD CONSTRAINT cv_projects_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: cv_projects_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cv_projects
    ADD CONSTRAINT cv_projects_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: cv_seminars_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cv_seminars
    ADD CONSTRAINT cv_seminars_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: cv_seminars_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cv_seminars
    ADD CONSTRAINT cv_seminars_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: day_ledgers_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY day_ledgers
    ADD CONSTRAINT day_ledgers_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(bank_account_id);


--
-- Name: day_ledgers_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY day_ledgers
    ADD CONSTRAINT day_ledgers_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: day_ledgers_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY day_ledgers
    ADD CONSTRAINT day_ledgers_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(department_id);


--
-- Name: day_ledgers_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY day_ledgers
    ADD CONSTRAINT day_ledgers_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: day_ledgers_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY day_ledgers
    ADD CONSTRAINT day_ledgers_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(item_id);


--
-- Name: day_ledgers_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY day_ledgers
    ADD CONSTRAINT day_ledgers_journal_id_fkey FOREIGN KEY (journal_id) REFERENCES journals(journal_id);


--
-- Name: day_ledgers_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY day_ledgers
    ADD CONSTRAINT day_ledgers_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: day_ledgers_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY day_ledgers
    ADD CONSTRAINT day_ledgers_store_id_fkey FOREIGN KEY (store_id) REFERENCES stores(store_id);


--
-- Name: day_ledgers_transaction_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY day_ledgers
    ADD CONSTRAINT day_ledgers_transaction_status_id_fkey FOREIGN KEY (transaction_status_id) REFERENCES transaction_status(transaction_status_id);


--
-- Name: day_ledgers_transaction_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY day_ledgers
    ADD CONSTRAINT day_ledgers_transaction_type_id_fkey FOREIGN KEY (transaction_type_id) REFERENCES transaction_types(transaction_type_id);


--
-- Name: default_accounts_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_accounts
    ADD CONSTRAINT default_accounts_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(account_id);


--
-- Name: default_accounts_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_accounts
    ADD CONSTRAINT default_accounts_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: default_adjustments_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_adjustments
    ADD CONSTRAINT default_adjustments_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES adjustments(adjustment_id);


--
-- Name: default_adjustments_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_adjustments
    ADD CONSTRAINT default_adjustments_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: default_adjustments_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_adjustments
    ADD CONSTRAINT default_adjustments_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: default_banking_bank_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_banking
    ADD CONSTRAINT default_banking_bank_branch_id_fkey FOREIGN KEY (bank_branch_id) REFERENCES bank_branch(bank_branch_id);


--
-- Name: default_banking_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_banking
    ADD CONSTRAINT default_banking_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: default_banking_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_banking
    ADD CONSTRAINT default_banking_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: default_banking_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_banking
    ADD CONSTRAINT default_banking_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: default_tax_types_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_tax_types
    ADD CONSTRAINT default_tax_types_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: default_tax_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_tax_types
    ADD CONSTRAINT default_tax_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: default_tax_types_tax_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY default_tax_types
    ADD CONSTRAINT default_tax_types_tax_type_id_fkey FOREIGN KEY (tax_type_id) REFERENCES tax_types(tax_type_id);


--
-- Name: define_phases_entity_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY define_phases
    ADD CONSTRAINT define_phases_entity_type_id_fkey FOREIGN KEY (entity_type_id) REFERENCES entity_types(entity_type_id);


--
-- Name: define_phases_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY define_phases
    ADD CONSTRAINT define_phases_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: define_phases_project_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY define_phases
    ADD CONSTRAINT define_phases_project_type_id_fkey FOREIGN KEY (project_type_id) REFERENCES project_types(project_type_id);


--
-- Name: define_tasks_define_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY define_tasks
    ADD CONSTRAINT define_tasks_define_phase_id_fkey FOREIGN KEY (define_phase_id) REFERENCES define_phases(define_phase_id);


--
-- Name: define_tasks_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY define_tasks
    ADD CONSTRAINT define_tasks_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: department_roles_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY department_roles
    ADD CONSTRAINT department_roles_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(department_id);


--
-- Name: department_roles_ln_department_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY department_roles
    ADD CONSTRAINT department_roles_ln_department_role_id_fkey FOREIGN KEY (ln_department_role_id) REFERENCES department_roles(department_role_id);


--
-- Name: department_roles_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY department_roles
    ADD CONSTRAINT department_roles_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: departments_ln_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY departments
    ADD CONSTRAINT departments_ln_department_id_fkey FOREIGN KEY (ln_department_id) REFERENCES departments(department_id);


--
-- Name: departments_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY departments
    ADD CONSTRAINT departments_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: disability_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY disability
    ADD CONSTRAINT disability_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: education_class_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY education_class
    ADD CONSTRAINT education_class_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: education_education_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY education
    ADD CONSTRAINT education_education_class_id_fkey FOREIGN KEY (education_class_id) REFERENCES education_class(education_class_id);


--
-- Name: education_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY education
    ADD CONSTRAINT education_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: education_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY education
    ADD CONSTRAINT education_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_adjustments_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_adjustments
    ADD CONSTRAINT employee_adjustments_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES adjustments(adjustment_id);


--
-- Name: employee_adjustments_employee_month_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_adjustments
    ADD CONSTRAINT employee_adjustments_employee_month_id_fkey FOREIGN KEY (employee_month_id) REFERENCES employee_month(employee_month_id);


--
-- Name: employee_adjustments_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_adjustments
    ADD CONSTRAINT employee_adjustments_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_advances_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_advances
    ADD CONSTRAINT employee_advances_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: employee_advances_employee_month_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_advances
    ADD CONSTRAINT employee_advances_employee_month_id_fkey FOREIGN KEY (employee_month_id) REFERENCES employee_month(employee_month_id);


--
-- Name: employee_advances_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_advances
    ADD CONSTRAINT employee_advances_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_banking_bank_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_banking
    ADD CONSTRAINT employee_banking_bank_branch_id_fkey FOREIGN KEY (bank_branch_id) REFERENCES bank_branch(bank_branch_id);


--
-- Name: employee_banking_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_banking
    ADD CONSTRAINT employee_banking_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: employee_banking_employee_month_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_banking
    ADD CONSTRAINT employee_banking_employee_month_id_fkey FOREIGN KEY (employee_month_id) REFERENCES employee_month(employee_month_id);


--
-- Name: employee_banking_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_banking
    ADD CONSTRAINT employee_banking_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_cases_case_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_cases
    ADD CONSTRAINT employee_cases_case_type_id_fkey FOREIGN KEY (case_type_id) REFERENCES case_types(case_type_id);


--
-- Name: employee_cases_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_cases
    ADD CONSTRAINT employee_cases_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: employee_cases_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_cases
    ADD CONSTRAINT employee_cases_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_leave_contact_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_leave
    ADD CONSTRAINT employee_leave_contact_entity_id_fkey FOREIGN KEY (contact_entity_id) REFERENCES entitys(entity_id);


--
-- Name: employee_leave_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_leave
    ADD CONSTRAINT employee_leave_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: employee_leave_leave_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_leave
    ADD CONSTRAINT employee_leave_leave_type_id_fkey FOREIGN KEY (leave_type_id) REFERENCES leave_types(leave_type_id);


--
-- Name: employee_leave_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_leave
    ADD CONSTRAINT employee_leave_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_leave_types_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_leave_types
    ADD CONSTRAINT employee_leave_types_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: employee_leave_types_leave_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_leave_types
    ADD CONSTRAINT employee_leave_types_leave_type_id_fkey FOREIGN KEY (leave_type_id) REFERENCES leave_types(leave_type_id);


--
-- Name: employee_leave_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_leave_types
    ADD CONSTRAINT employee_leave_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_month_bank_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_month
    ADD CONSTRAINT employee_month_bank_branch_id_fkey FOREIGN KEY (bank_branch_id) REFERENCES bank_branch(bank_branch_id);


--
-- Name: employee_month_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_month
    ADD CONSTRAINT employee_month_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: employee_month_department_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_month
    ADD CONSTRAINT employee_month_department_role_id_fkey FOREIGN KEY (department_role_id) REFERENCES department_roles(department_role_id);


--
-- Name: employee_month_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_month
    ADD CONSTRAINT employee_month_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: employee_month_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_month
    ADD CONSTRAINT employee_month_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_month_pay_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_month
    ADD CONSTRAINT employee_month_pay_group_id_fkey FOREIGN KEY (pay_group_id) REFERENCES pay_groups(pay_group_id);


--
-- Name: employee_month_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_month
    ADD CONSTRAINT employee_month_period_id_fkey FOREIGN KEY (period_id) REFERENCES periods(period_id);


--
-- Name: employee_objectives_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_objectives
    ADD CONSTRAINT employee_objectives_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: employee_objectives_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_objectives
    ADD CONSTRAINT employee_objectives_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_overtime_employee_month_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_overtime
    ADD CONSTRAINT employee_overtime_employee_month_id_fkey FOREIGN KEY (employee_month_id) REFERENCES employee_month(employee_month_id);


--
-- Name: employee_overtime_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_overtime
    ADD CONSTRAINT employee_overtime_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_per_diem_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_per_diem
    ADD CONSTRAINT employee_per_diem_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: employee_per_diem_employee_month_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_per_diem
    ADD CONSTRAINT employee_per_diem_employee_month_id_fkey FOREIGN KEY (employee_month_id) REFERENCES employee_month(employee_month_id);


--
-- Name: employee_per_diem_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_per_diem
    ADD CONSTRAINT employee_per_diem_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_tax_types_employee_month_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_tax_types
    ADD CONSTRAINT employee_tax_types_employee_month_id_fkey FOREIGN KEY (employee_month_id) REFERENCES employee_month(employee_month_id);


--
-- Name: employee_tax_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_tax_types
    ADD CONSTRAINT employee_tax_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_tax_types_tax_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_tax_types
    ADD CONSTRAINT employee_tax_types_tax_type_id_fkey FOREIGN KEY (tax_type_id) REFERENCES tax_types(tax_type_id);


--
-- Name: employee_trainings_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_trainings
    ADD CONSTRAINT employee_trainings_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: employee_trainings_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_trainings
    ADD CONSTRAINT employee_trainings_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employee_trainings_training_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_trainings
    ADD CONSTRAINT employee_trainings_training_id_fkey FOREIGN KEY (training_id) REFERENCES trainings(training_id);


--
-- Name: employees_bank_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_bank_branch_id_fkey FOREIGN KEY (bank_branch_id) REFERENCES bank_branch(bank_branch_id);


--
-- Name: employees_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: employees_department_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_department_role_id_fkey FOREIGN KEY (department_role_id) REFERENCES department_roles(department_role_id);


--
-- Name: employees_disability_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_disability_id_fkey FOREIGN KEY (disability_id) REFERENCES disability(disability_id);


--
-- Name: employees_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: employees_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_location_id_fkey FOREIGN KEY (location_id) REFERENCES locations(location_id);


--
-- Name: employees_nation_of_birth_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_nation_of_birth_fkey FOREIGN KEY (nation_of_birth) REFERENCES sys_countrys(sys_country_id);


--
-- Name: employees_nationality_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_nationality_fkey FOREIGN KEY (nationality) REFERENCES sys_countrys(sys_country_id);


--
-- Name: employees_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: employees_pay_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_pay_group_id_fkey FOREIGN KEY (pay_group_id) REFERENCES pay_groups(pay_group_id);


--
-- Name: employees_pay_scale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_pay_scale_id_fkey FOREIGN KEY (pay_scale_id) REFERENCES pay_scales(pay_scale_id);


--
-- Name: employees_pay_scale_step_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_pay_scale_step_id_fkey FOREIGN KEY (pay_scale_step_id) REFERENCES pay_scale_steps(pay_scale_step_id);


--
-- Name: employment_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employment
    ADD CONSTRAINT employment_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: employment_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employment
    ADD CONSTRAINT employment_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: entity_subscriptions_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entity_subscriptions
    ADD CONSTRAINT entity_subscriptions_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: entity_subscriptions_entity_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entity_subscriptions
    ADD CONSTRAINT entity_subscriptions_entity_type_id_fkey FOREIGN KEY (entity_type_id) REFERENCES entity_types(entity_type_id);


--
-- Name: entity_subscriptions_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entity_subscriptions
    ADD CONSTRAINT entity_subscriptions_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: entity_subscriptions_subscription_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entity_subscriptions
    ADD CONSTRAINT entity_subscriptions_subscription_level_id_fkey FOREIGN KEY (subscription_level_id) REFERENCES subscription_levels(subscription_level_id);


--
-- Name: entity_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entity_types
    ADD CONSTRAINT entity_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: entitys_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entitys
    ADD CONSTRAINT entitys_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(account_id);


--
-- Name: entitys_entity_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entitys
    ADD CONSTRAINT entitys_entity_type_id_fkey FOREIGN KEY (entity_type_id) REFERENCES entity_types(entity_type_id);


--
-- Name: entitys_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entitys
    ADD CONSTRAINT entitys_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: entry_forms_entered_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entry_forms
    ADD CONSTRAINT entry_forms_entered_by_id_fkey FOREIGN KEY (entered_by_id) REFERENCES entitys(entity_id);


--
-- Name: entry_forms_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entry_forms
    ADD CONSTRAINT entry_forms_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: entry_forms_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entry_forms
    ADD CONSTRAINT entry_forms_form_id_fkey FOREIGN KEY (form_id) REFERENCES forms(form_id);


--
-- Name: entry_forms_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY entry_forms
    ADD CONSTRAINT entry_forms_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: evaluation_points_career_development_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY evaluation_points
    ADD CONSTRAINT evaluation_points_career_development_id_fkey FOREIGN KEY (career_development_id) REFERENCES career_development(career_development_id);


--
-- Name: evaluation_points_job_review_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY evaluation_points
    ADD CONSTRAINT evaluation_points_job_review_id_fkey FOREIGN KEY (job_review_id) REFERENCES job_reviews(job_review_id);


--
-- Name: evaluation_points_objective_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY evaluation_points
    ADD CONSTRAINT evaluation_points_objective_id_fkey FOREIGN KEY (objective_id) REFERENCES objectives(objective_id);


--
-- Name: evaluation_points_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY evaluation_points
    ADD CONSTRAINT evaluation_points_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: evaluation_points_review_point_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY evaluation_points
    ADD CONSTRAINT evaluation_points_review_point_id_fkey FOREIGN KEY (review_point_id) REFERENCES review_points(review_point_id);


--
-- Name: fields_form_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY fields
    ADD CONSTRAINT fields_form_id_fkey FOREIGN KEY (form_id) REFERENCES forms(form_id);


--
-- Name: fields_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY fields
    ADD CONSTRAINT fields_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: fiscal_years_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY fiscal_years
    ADD CONSTRAINT fiscal_years_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: forms_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY forms
    ADD CONSTRAINT forms_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: gls_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gls
    ADD CONSTRAINT gls_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(account_id);


--
-- Name: gls_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gls
    ADD CONSTRAINT gls_journal_id_fkey FOREIGN KEY (journal_id) REFERENCES journals(journal_id);


--
-- Name: gls_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY gls
    ADD CONSTRAINT gls_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: holidays_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY holidays
    ADD CONSTRAINT holidays_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: identification_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY identification_types
    ADD CONSTRAINT identification_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: identifications_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY identifications
    ADD CONSTRAINT identifications_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: identifications_identification_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY identifications
    ADD CONSTRAINT identifications_identification_type_id_fkey FOREIGN KEY (identification_type_id) REFERENCES identification_types(identification_type_id);


--
-- Name: identifications_nationality_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY identifications
    ADD CONSTRAINT identifications_nationality_fkey FOREIGN KEY (nationality) REFERENCES sys_countrys(sys_country_id);


--
-- Name: identifications_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY identifications
    ADD CONSTRAINT identifications_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: intake_department_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY intake
    ADD CONSTRAINT intake_department_role_id_fkey FOREIGN KEY (department_role_id) REFERENCES department_roles(department_role_id);


--
-- Name: intake_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY intake
    ADD CONSTRAINT intake_location_id_fkey FOREIGN KEY (location_id) REFERENCES locations(location_id);


--
-- Name: intake_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY intake
    ADD CONSTRAINT intake_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: intake_pay_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY intake
    ADD CONSTRAINT intake_pay_group_id_fkey FOREIGN KEY (pay_group_id) REFERENCES pay_groups(pay_group_id);


--
-- Name: intake_pay_scale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY intake
    ADD CONSTRAINT intake_pay_scale_id_fkey FOREIGN KEY (pay_scale_id) REFERENCES pay_scales(pay_scale_id);


--
-- Name: interns_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY interns
    ADD CONSTRAINT interns_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: interns_internship_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY interns
    ADD CONSTRAINT interns_internship_id_fkey FOREIGN KEY (internship_id) REFERENCES internships(internship_id);


--
-- Name: interns_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY interns
    ADD CONSTRAINT interns_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: internships_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY internships
    ADD CONSTRAINT internships_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(department_id);


--
-- Name: internships_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY internships
    ADD CONSTRAINT internships_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: item_category_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY item_category
    ADD CONSTRAINT item_category_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: item_units_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY item_units
    ADD CONSTRAINT item_units_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: items_item_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_item_category_id_fkey FOREIGN KEY (item_category_id) REFERENCES item_category(item_category_id);


--
-- Name: items_item_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_item_unit_id_fkey FOREIGN KEY (item_unit_id) REFERENCES item_units(item_unit_id);


--
-- Name: items_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: items_purchase_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_purchase_account_id_fkey FOREIGN KEY (purchase_account_id) REFERENCES accounts(account_id);


--
-- Name: items_sales_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_sales_account_id_fkey FOREIGN KEY (sales_account_id) REFERENCES accounts(account_id);


--
-- Name: items_tax_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_tax_type_id_fkey FOREIGN KEY (tax_type_id) REFERENCES tax_types(tax_type_id);


--
-- Name: job_reviews_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job_reviews
    ADD CONSTRAINT job_reviews_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: job_reviews_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job_reviews
    ADD CONSTRAINT job_reviews_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: job_reviews_review_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job_reviews
    ADD CONSTRAINT job_reviews_review_category_id_fkey FOREIGN KEY (review_category_id) REFERENCES review_category(review_category_id);


--
-- Name: journals_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT journals_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: journals_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT journals_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(department_id);


--
-- Name: journals_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT journals_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: journals_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT journals_period_id_fkey FOREIGN KEY (period_id) REFERENCES periods(period_id);


--
-- Name: kin_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kin_types
    ADD CONSTRAINT kin_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: kins_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kins
    ADD CONSTRAINT kins_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: kins_kin_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kins
    ADD CONSTRAINT kins_kin_type_id_fkey FOREIGN KEY (kin_type_id) REFERENCES kin_types(kin_type_id);


--
-- Name: kins_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY kins
    ADD CONSTRAINT kins_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: lead_items_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY lead_items
    ADD CONSTRAINT lead_items_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: lead_items_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY lead_items
    ADD CONSTRAINT lead_items_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(item_id);


--
-- Name: lead_items_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY lead_items
    ADD CONSTRAINT lead_items_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: leads_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leads
    ADD CONSTRAINT leads_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: leads_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leads
    ADD CONSTRAINT leads_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: leads_sale_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leads
    ADD CONSTRAINT leads_sale_person_id_fkey FOREIGN KEY (sale_person_id) REFERENCES entitys(entity_id);


--
-- Name: leave_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_types
    ADD CONSTRAINT leave_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: leave_work_days_employee_leave_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_work_days
    ADD CONSTRAINT leave_work_days_employee_leave_id_fkey FOREIGN KEY (employee_leave_id) REFERENCES employee_leave(employee_leave_id);


--
-- Name: leave_work_days_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_work_days
    ADD CONSTRAINT leave_work_days_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: leave_work_days_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY leave_work_days
    ADD CONSTRAINT leave_work_days_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: loan_monthly_employee_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loan_monthly
    ADD CONSTRAINT loan_monthly_employee_adjustment_id_fkey FOREIGN KEY (employee_adjustment_id) REFERENCES employee_adjustments(employee_adjustment_id);


--
-- Name: loan_monthly_loan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loan_monthly
    ADD CONSTRAINT loan_monthly_loan_id_fkey FOREIGN KEY (loan_id) REFERENCES loans(loan_id);


--
-- Name: loan_monthly_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loan_monthly
    ADD CONSTRAINT loan_monthly_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: loan_monthly_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loan_monthly
    ADD CONSTRAINT loan_monthly_period_id_fkey FOREIGN KEY (period_id) REFERENCES periods(period_id);


--
-- Name: loan_types_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loan_types
    ADD CONSTRAINT loan_types_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES adjustments(adjustment_id);


--
-- Name: loan_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loan_types
    ADD CONSTRAINT loan_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: loans_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: loans_loan_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_loan_type_id_fkey FOREIGN KEY (loan_type_id) REFERENCES loan_types(loan_type_id);


--
-- Name: loans_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: locations_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY locations
    ADD CONSTRAINT locations_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: objective_details_ln_objective_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY objective_details
    ADD CONSTRAINT objective_details_ln_objective_detail_id_fkey FOREIGN KEY (ln_objective_detail_id) REFERENCES objective_details(objective_detail_id);


--
-- Name: objective_details_objective_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY objective_details
    ADD CONSTRAINT objective_details_objective_id_fkey FOREIGN KEY (objective_id) REFERENCES objectives(objective_id);


--
-- Name: objective_details_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY objective_details
    ADD CONSTRAINT objective_details_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: objective_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY objective_types
    ADD CONSTRAINT objective_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: objectives_employee_objective_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY objectives
    ADD CONSTRAINT objectives_employee_objective_id_fkey FOREIGN KEY (employee_objective_id) REFERENCES employee_objectives(employee_objective_id);


--
-- Name: objectives_objective_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY objectives
    ADD CONSTRAINT objectives_objective_type_id_fkey FOREIGN KEY (objective_type_id) REFERENCES objective_types(objective_type_id);


--
-- Name: objectives_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY objectives
    ADD CONSTRAINT objectives_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: orgs_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY orgs
    ADD CONSTRAINT orgs_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: orgs_parent_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY orgs
    ADD CONSTRAINT orgs_parent_org_id_fkey FOREIGN KEY (parent_org_id) REFERENCES orgs(org_id);


--
-- Name: pay_groups_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pay_groups
    ADD CONSTRAINT pay_groups_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: pay_scale_steps_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pay_scale_steps
    ADD CONSTRAINT pay_scale_steps_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: pay_scale_steps_pay_scale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pay_scale_steps
    ADD CONSTRAINT pay_scale_steps_pay_scale_id_fkey FOREIGN KEY (pay_scale_id) REFERENCES pay_scales(pay_scale_id);


--
-- Name: pay_scale_years_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pay_scale_years
    ADD CONSTRAINT pay_scale_years_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: pay_scale_years_pay_scale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pay_scale_years
    ADD CONSTRAINT pay_scale_years_pay_scale_id_fkey FOREIGN KEY (pay_scale_id) REFERENCES pay_scales(pay_scale_id);


--
-- Name: pay_scales_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pay_scales
    ADD CONSTRAINT pay_scales_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: pay_scales_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pay_scales
    ADD CONSTRAINT pay_scales_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: payroll_ledger_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY payroll_ledger
    ADD CONSTRAINT payroll_ledger_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: payroll_ledger_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY payroll_ledger
    ADD CONSTRAINT payroll_ledger_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: pc_allocations_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_allocations
    ADD CONSTRAINT pc_allocations_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(department_id);


--
-- Name: pc_allocations_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_allocations
    ADD CONSTRAINT pc_allocations_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: pc_allocations_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_allocations
    ADD CONSTRAINT pc_allocations_period_id_fkey FOREIGN KEY (period_id) REFERENCES periods(period_id);


--
-- Name: pc_banking_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_banking
    ADD CONSTRAINT pc_banking_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: pc_banking_pc_allocation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_banking
    ADD CONSTRAINT pc_banking_pc_allocation_id_fkey FOREIGN KEY (pc_allocation_id) REFERENCES pc_allocations(pc_allocation_id);


--
-- Name: pc_budget_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_budget
    ADD CONSTRAINT pc_budget_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: pc_budget_pc_allocation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_budget
    ADD CONSTRAINT pc_budget_pc_allocation_id_fkey FOREIGN KEY (pc_allocation_id) REFERENCES pc_allocations(pc_allocation_id);


--
-- Name: pc_budget_pc_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_budget
    ADD CONSTRAINT pc_budget_pc_item_id_fkey FOREIGN KEY (pc_item_id) REFERENCES pc_items(pc_item_id);


--
-- Name: pc_category_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_category
    ADD CONSTRAINT pc_category_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: pc_expenditure_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_expenditure
    ADD CONSTRAINT pc_expenditure_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: pc_expenditure_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_expenditure
    ADD CONSTRAINT pc_expenditure_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: pc_expenditure_pc_allocation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_expenditure
    ADD CONSTRAINT pc_expenditure_pc_allocation_id_fkey FOREIGN KEY (pc_allocation_id) REFERENCES pc_allocations(pc_allocation_id);


--
-- Name: pc_expenditure_pc_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_expenditure
    ADD CONSTRAINT pc_expenditure_pc_item_id_fkey FOREIGN KEY (pc_item_id) REFERENCES pc_items(pc_item_id);


--
-- Name: pc_expenditure_pc_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_expenditure
    ADD CONSTRAINT pc_expenditure_pc_type_id_fkey FOREIGN KEY (pc_type_id) REFERENCES pc_types(pc_type_id);


--
-- Name: pc_items_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_items
    ADD CONSTRAINT pc_items_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: pc_items_pc_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_items
    ADD CONSTRAINT pc_items_pc_category_id_fkey FOREIGN KEY (pc_category_id) REFERENCES pc_category(pc_category_id);


--
-- Name: pc_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY pc_types
    ADD CONSTRAINT pc_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: period_tax_rates_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY period_tax_rates
    ADD CONSTRAINT period_tax_rates_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: period_tax_rates_period_tax_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY period_tax_rates
    ADD CONSTRAINT period_tax_rates_period_tax_type_id_fkey FOREIGN KEY (period_tax_type_id) REFERENCES period_tax_types(period_tax_type_id);


--
-- Name: period_tax_rates_tax_rate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY period_tax_rates
    ADD CONSTRAINT period_tax_rates_tax_rate_id_fkey FOREIGN KEY (tax_rate_id) REFERENCES tax_rates(tax_rate_id);


--
-- Name: period_tax_types_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY period_tax_types
    ADD CONSTRAINT period_tax_types_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(account_id);


--
-- Name: period_tax_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY period_tax_types
    ADD CONSTRAINT period_tax_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: period_tax_types_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY period_tax_types
    ADD CONSTRAINT period_tax_types_period_id_fkey FOREIGN KEY (period_id) REFERENCES periods(period_id);


--
-- Name: period_tax_types_tax_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY period_tax_types
    ADD CONSTRAINT period_tax_types_tax_type_id_fkey FOREIGN KEY (tax_type_id) REFERENCES tax_types(tax_type_id);


--
-- Name: periods_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY periods
    ADD CONSTRAINT periods_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: periods_fiscal_year_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY periods
    ADD CONSTRAINT periods_fiscal_year_id_fkey FOREIGN KEY (fiscal_year_id) REFERENCES fiscal_years(fiscal_year_id);


--
-- Name: periods_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY periods
    ADD CONSTRAINT periods_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: phases_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY phases
    ADD CONSTRAINT phases_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: phases_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY phases
    ADD CONSTRAINT phases_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(project_id);


--
-- Name: project_cost_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_cost
    ADD CONSTRAINT project_cost_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: project_cost_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_cost
    ADD CONSTRAINT project_cost_phase_id_fkey FOREIGN KEY (phase_id) REFERENCES phases(phase_id);


--
-- Name: project_locations_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_locations
    ADD CONSTRAINT project_locations_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: project_locations_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_locations
    ADD CONSTRAINT project_locations_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(project_id);


--
-- Name: project_staff_costs_bank_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_staff_costs
    ADD CONSTRAINT project_staff_costs_bank_branch_id_fkey FOREIGN KEY (bank_branch_id) REFERENCES bank_branch(bank_branch_id);


--
-- Name: project_staff_costs_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_staff_costs
    ADD CONSTRAINT project_staff_costs_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: project_staff_costs_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_staff_costs
    ADD CONSTRAINT project_staff_costs_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: project_staff_costs_pay_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_staff_costs
    ADD CONSTRAINT project_staff_costs_pay_group_id_fkey FOREIGN KEY (pay_group_id) REFERENCES pay_groups(pay_group_id);


--
-- Name: project_staff_costs_period_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_staff_costs
    ADD CONSTRAINT project_staff_costs_period_id_fkey FOREIGN KEY (period_id) REFERENCES periods(period_id);


--
-- Name: project_staff_costs_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_staff_costs
    ADD CONSTRAINT project_staff_costs_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(project_id);


--
-- Name: project_staff_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_staff
    ADD CONSTRAINT project_staff_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: project_staff_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_staff
    ADD CONSTRAINT project_staff_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: project_staff_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_staff
    ADD CONSTRAINT project_staff_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(project_id);


--
-- Name: project_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project_types
    ADD CONSTRAINT project_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: projects_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: projects_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: projects_project_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_project_type_id_fkey FOREIGN KEY (project_type_id) REFERENCES project_types(project_type_id);


--
-- Name: quotations_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY quotations
    ADD CONSTRAINT quotations_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: quotations_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY quotations
    ADD CONSTRAINT quotations_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(item_id);


--
-- Name: quotations_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY quotations
    ADD CONSTRAINT quotations_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: reporting_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY reporting
    ADD CONSTRAINT reporting_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: reporting_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY reporting
    ADD CONSTRAINT reporting_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: reporting_report_to_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY reporting
    ADD CONSTRAINT reporting_report_to_id_fkey FOREIGN KEY (report_to_id) REFERENCES entitys(entity_id);


--
-- Name: review_category_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY review_category
    ADD CONSTRAINT review_category_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: review_points_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY review_points
    ADD CONSTRAINT review_points_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: review_points_review_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY review_points
    ADD CONSTRAINT review_points_review_category_id_fkey FOREIGN KEY (review_category_id) REFERENCES review_category(review_category_id);


--
-- Name: shift_schedule_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shift_schedule
    ADD CONSTRAINT shift_schedule_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: shift_schedule_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shift_schedule
    ADD CONSTRAINT shift_schedule_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: shift_schedule_shift_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shift_schedule
    ADD CONSTRAINT shift_schedule_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES shifts(shift_id);


--
-- Name: shifts_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY shifts
    ADD CONSTRAINT shifts_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: skill_category_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY skill_category
    ADD CONSTRAINT skill_category_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: skill_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY skill_types
    ADD CONSTRAINT skill_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: skill_types_skill_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY skill_types
    ADD CONSTRAINT skill_types_skill_category_id_fkey FOREIGN KEY (skill_category_id) REFERENCES skill_category(skill_category_id);


--
-- Name: skills_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY skills
    ADD CONSTRAINT skills_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: skills_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY skills
    ADD CONSTRAINT skills_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: skills_skill_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY skills
    ADD CONSTRAINT skills_skill_type_id_fkey FOREIGN KEY (skill_type_id) REFERENCES skill_types(skill_type_id);


--
-- Name: stock_lines_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stock_lines
    ADD CONSTRAINT stock_lines_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(item_id);


--
-- Name: stock_lines_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stock_lines
    ADD CONSTRAINT stock_lines_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: stock_lines_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stock_lines
    ADD CONSTRAINT stock_lines_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stocks(stock_id);


--
-- Name: stocks_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stocks
    ADD CONSTRAINT stocks_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: stocks_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stocks
    ADD CONSTRAINT stocks_store_id_fkey FOREIGN KEY (store_id) REFERENCES stores(store_id);


--
-- Name: stores_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stores
    ADD CONSTRAINT stores_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: sub_fields_field_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sub_fields
    ADD CONSTRAINT sub_fields_field_id_fkey FOREIGN KEY (field_id) REFERENCES fields(field_id);


--
-- Name: sub_fields_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sub_fields
    ADD CONSTRAINT sub_fields_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: subscription_levels_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY subscription_levels
    ADD CONSTRAINT subscription_levels_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: sys_audit_details_sys_audit_trail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_audit_details
    ADD CONSTRAINT sys_audit_details_sys_audit_trail_id_fkey FOREIGN KEY (sys_audit_trail_id) REFERENCES sys_audit_trail(sys_audit_trail_id);


--
-- Name: sys_countrys_sys_continent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_countrys
    ADD CONSTRAINT sys_countrys_sys_continent_id_fkey FOREIGN KEY (sys_continent_id) REFERENCES sys_continents(sys_continent_id);


--
-- Name: sys_dashboard_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_dashboard
    ADD CONSTRAINT sys_dashboard_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: sys_dashboard_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_dashboard
    ADD CONSTRAINT sys_dashboard_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: sys_emailed_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_emailed
    ADD CONSTRAINT sys_emailed_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: sys_emailed_sys_email_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_emailed
    ADD CONSTRAINT sys_emailed_sys_email_id_fkey FOREIGN KEY (sys_email_id) REFERENCES sys_emails(sys_email_id);


--
-- Name: sys_emails_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_emails
    ADD CONSTRAINT sys_emails_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: sys_files_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_files
    ADD CONSTRAINT sys_files_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: sys_logins_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_logins
    ADD CONSTRAINT sys_logins_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: sys_news_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_news
    ADD CONSTRAINT sys_news_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: sys_queries_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_queries
    ADD CONSTRAINT sys_queries_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: sys_reset_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_reset
    ADD CONSTRAINT sys_reset_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: sys_reset_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY sys_reset
    ADD CONSTRAINT sys_reset_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: tasks_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: tasks_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: tasks_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_phase_id_fkey FOREIGN KEY (phase_id) REFERENCES phases(phase_id);


--
-- Name: tax_rates_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tax_rates
    ADD CONSTRAINT tax_rates_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: tax_rates_tax_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tax_rates
    ADD CONSTRAINT tax_rates_tax_type_id_fkey FOREIGN KEY (tax_type_id) REFERENCES tax_types(tax_type_id);


--
-- Name: tax_types_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tax_types
    ADD CONSTRAINT tax_types_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(account_id);


--
-- Name: tax_types_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tax_types
    ADD CONSTRAINT tax_types_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: tax_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tax_types
    ADD CONSTRAINT tax_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: tender_items_bidder_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tender_items
    ADD CONSTRAINT tender_items_bidder_id_fkey FOREIGN KEY (bidder_id) REFERENCES bidders(bidder_id);


--
-- Name: tender_items_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tender_items
    ADD CONSTRAINT tender_items_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: tender_types_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tender_types
    ADD CONSTRAINT tender_types_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: tenders_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tenders
    ADD CONSTRAINT tenders_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: tenders_tender_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tenders
    ADD CONSTRAINT tenders_tender_type_id_fkey FOREIGN KEY (tender_type_id) REFERENCES tender_types(tender_type_id);


--
-- Name: timesheet_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY timesheet
    ADD CONSTRAINT timesheet_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: timesheet_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY timesheet
    ADD CONSTRAINT timesheet_task_id_fkey FOREIGN KEY (task_id) REFERENCES tasks(task_id);


--
-- Name: trainings_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY trainings
    ADD CONSTRAINT trainings_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: transaction_details_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_details
    ADD CONSTRAINT transaction_details_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(account_id);


--
-- Name: transaction_details_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_details
    ADD CONSTRAINT transaction_details_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(item_id);


--
-- Name: transaction_details_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_details
    ADD CONSTRAINT transaction_details_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: transaction_details_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_details
    ADD CONSTRAINT transaction_details_store_id_fkey FOREIGN KEY (store_id) REFERENCES stores(store_id);


--
-- Name: transaction_details_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_details
    ADD CONSTRAINT transaction_details_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id);


--
-- Name: transaction_links_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_links
    ADD CONSTRAINT transaction_links_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: transaction_links_transaction_detail_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_links
    ADD CONSTRAINT transaction_links_transaction_detail_id_fkey FOREIGN KEY (transaction_detail_id) REFERENCES transaction_details(transaction_detail_id);


--
-- Name: transaction_links_transaction_detail_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_links
    ADD CONSTRAINT transaction_links_transaction_detail_to_fkey FOREIGN KEY (transaction_detail_to) REFERENCES transaction_details(transaction_detail_id);


--
-- Name: transaction_links_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_links
    ADD CONSTRAINT transaction_links_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id);


--
-- Name: transaction_links_transaction_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaction_links
    ADD CONSTRAINT transaction_links_transaction_to_fkey FOREIGN KEY (transaction_to) REFERENCES transactions(transaction_id);


--
-- Name: transactions_bank_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(bank_account_id);


--
-- Name: transactions_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES currency(currency_id);


--
-- Name: transactions_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_department_id_fkey FOREIGN KEY (department_id) REFERENCES departments(department_id);


--
-- Name: transactions_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entitys(entity_id);


--
-- Name: transactions_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_journal_id_fkey FOREIGN KEY (journal_id) REFERENCES journals(journal_id);


--
-- Name: transactions_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: transactions_transaction_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_transaction_status_id_fkey FOREIGN KEY (transaction_status_id) REFERENCES transaction_status(transaction_status_id);


--
-- Name: transactions_transaction_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_transaction_type_id_fkey FOREIGN KEY (transaction_type_id) REFERENCES transaction_types(transaction_type_id);


--
-- Name: workflow_logs_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY workflow_logs
    ADD CONSTRAINT workflow_logs_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: workflow_phases_approval_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY workflow_phases
    ADD CONSTRAINT workflow_phases_approval_entity_id_fkey FOREIGN KEY (approval_entity_id) REFERENCES entity_types(entity_type_id);


--
-- Name: workflow_phases_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY workflow_phases
    ADD CONSTRAINT workflow_phases_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: workflow_phases_workflow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY workflow_phases
    ADD CONSTRAINT workflow_phases_workflow_id_fkey FOREIGN KEY (workflow_id) REFERENCES workflows(workflow_id);


--
-- Name: workflow_sql_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY workflow_sql
    ADD CONSTRAINT workflow_sql_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: workflow_sql_workflow_phase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY workflow_sql
    ADD CONSTRAINT workflow_sql_workflow_phase_id_fkey FOREIGN KEY (workflow_phase_id) REFERENCES workflow_phases(workflow_phase_id);


--
-- Name: workflows_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT workflows_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(org_id);


--
-- Name: workflows_source_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT workflows_source_entity_id_fkey FOREIGN KEY (source_entity_id) REFERENCES entity_types(entity_type_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

