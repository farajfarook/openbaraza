CREATE TABLE accounts_class (
	accounts_class_id		integer primary key,
	org_id					integer references orgs,
	chat_type_id			integer not null,
	chat_type_name			varchar(50) not null,
	accounts_class_name		varchar(120) not null unique,
	details					text
);
CREATE INDEX accounts_class_org_id ON accounts_class (org_id);
CREATE INDEX accounts_class_chat_type_id ON accounts_class (chat_type_id);

CREATE TABLE account_types (
	account_type_id			integer primary key,
	org_id					integer references orgs,
	accounts_class_id		integer references accounts_class,
	account_type_name		varchar(120) not null,
	details					text
);
CREATE INDEX account_types_org_id ON account_types (org_id);
CREATE INDEX account_types_accounts_class_id ON account_types (accounts_class_id);

CREATE TABLE accounts (
	account_id				integer primary key,
	org_id					integer references orgs,
	account_type_id			integer references account_types,
	account_name			varchar(120) not null,
	is_header				boolean default false not null,
	is_active				boolean default true not null,
	details					text
);
CREATE INDEX accounts_org_id ON accounts (org_id);
CREATE INDEX accounts_account_type_id ON accounts (account_type_id);

CREATE TABLE default_accounts (
	default_account_id		integer primary key,
	org_id					integer references orgs,
	account_id				integer references accounts,
	narrative				varchar(240)
);
CREATE INDEX default_accounts_org_id ON default_accounts (org_id);
CREATE INDEX default_accounts_account_id ON default_accounts (account_id);

CREATE TABLE journals (
	journal_id				serial primary key,
	org_id					integer references orgs,
	period_id				integer not null references periods,
	currency_id				integer references currency,
	department_id			integer	references departments,
	exchange_rate			real default 1 not null,
	journal_date			date not null,
	posted					boolean not null default false,
	year_closing			boolean not null default false,
	narrative				varchar(240),
	details					text
);
CREATE INDEX journals_org_id ON journals (org_id);
CREATE INDEX journals_period_id ON journals (period_id);
CREATE INDEX journals_currency_id ON journals (currency_id);

CREATE TABLE gls (
	gl_id					serial primary key,
	org_id					integer references orgs,
	journal_id				integer not null references journals,
	account_id				integer not null references accounts,
	debit					real not null default 0,
	credit					real not null default 0,
	gl_narrative			varchar(240)
);
CREATE INDEX gls_org_id ON gls (org_id);
CREATE INDEX gls_journal_id ON gls (journal_id);
CREATE INDEX gls_account_id ON gls (account_id);

CREATE TABLE tax_types (
	tax_type_id				serial primary key,
	account_id				integer references accounts,
	currency_id				integer references currency,
	org_id					integer references orgs,
	tax_type_name			varchar(50) not null,
	formural				varchar(320),
	tax_relief				real default 0 not null,
	tax_type_order			integer default 0 not null,
	in_tax					boolean not null default false,
	tax_rate				real default 0 not null,
	tax_inclusive			boolean default false not null,
	linear					boolean default true,
	percentage				boolean default true,
	employer				float default 0 not null,
	employer_ps				float default 0 not null,
	account_number			varchar(32),
	active					boolean default true,
	use_key					integer default 0 not null,
	Details					text,
	
	UNIQUE(tax_type_name, org_id)
);
CREATE INDEX tax_types_account_id ON tax_types (account_id);
CREATE INDEX tax_types_currency_id ON tax_types (currency_id);
CREATE INDEX tax_types_org_id ON tax_types (org_id);

CREATE TABLE tax_rates (
	tax_rate_id				serial primary key,
	tax_type_id				integer references tax_types,
	org_id					integer references orgs,
	tax_range				float not null,
	tax_rate				float not null,
	narrative				varchar(240)
);
CREATE INDEX tax_rates_tax_type_id ON tax_rates (tax_type_id);
CREATE INDEX tax_rates_org_id ON tax_rates(org_id);

CREATE TABLE period_tax_types (
	period_tax_type_id		serial primary key,
	period_id				integer references periods,
	tax_type_id				integer references tax_types,
	account_id				integer references accounts,
	org_id					integer references orgs,
	period_tax_type_name	varchar(50) not null,
	pay_date				date default current_date not null,
	formural				varchar(320),
	tax_relief				real default 0 not null,
	percentage				boolean default true not null,
	linear					boolean default true not null,
	tax_type_order			integer default 0 not null,
	in_tax					boolean not null default false,
	employer				float not null,
	employer_ps				float not null,
	account_number			varchar(32),
	details					text,
	
	UNIQUE(period_id, tax_type_id)
);
CREATE INDEX period_tax_types_tax_type_id ON period_tax_types (tax_type_id);
CREATE INDEX period_tax_types_period_id ON period_tax_types (period_id);
CREATE INDEX period_tax_types_account_id ON period_tax_types (account_id);
CREATE INDEX period_tax_types_org_id ON period_tax_types(org_id);

CREATE TABLE period_tax_rates (
	period_tax_rate_id		serial primary key,
	period_tax_type_id		integer references period_tax_types,
	tax_rate_id				integer references tax_rates,
	org_id					integer references orgs,
	tax_range				float not null,
	tax_rate				float not null,
	narrative				varchar(240),
	
	UNIQUE(period_tax_type_id, tax_rate_id)
);
CREATE INDEX period_tax_rates_period_tax_type_id ON period_tax_rates (period_tax_type_id);
CREATE INDEX period_tax_rates_org_id ON period_tax_rates(org_id);

CREATE TABLE default_tax_types (
	default_tax_type_id		serial primary key,
	entity_id				integer references entitys,
	tax_type_id				integer references tax_types,
	org_id					integer references orgs,
	tax_identification		varchar(50),
	narrative				varchar(240),
	additional				float default 0 not null,
	active					boolean default true,
	UNIQUE(entity_id, tax_type_id)
);
CREATE INDEX default_tax_types_entity_id ON default_tax_types (entity_id);
CREATE INDEX default_tax_types_tax_type_id ON default_tax_types (tax_type_id);
CREATE INDEX default_tax_types_org_id ON default_tax_types(org_id);

ALTER TABLE entitys ADD	account_id		integer references accounts;
CREATE INDEX entitys_account_id ON entitys (account_id);

CREATE VIEW vw_account_types AS
	SELECT accounts_class.accounts_class_id, accounts_class.accounts_class_name, accounts_class.chat_type_id, accounts_class.chat_type_name, 
		account_types.account_type_id, account_types.org_id, account_types.account_type_name, account_types.details
	FROM account_types INNER JOIN accounts_class ON account_types.accounts_class_id = accounts_class.accounts_class_id;

CREATE VIEW vw_accounts AS
	SELECT vw_account_types.accounts_class_id, vw_account_types.chat_type_id, vw_account_types.chat_type_name, 
		vw_account_types.accounts_class_name, vw_account_types.account_type_id, vw_account_types.account_type_name,
		accounts.account_id, accounts.org_id, accounts.account_name, accounts.is_header, accounts.is_active, accounts.details,
		(accounts.account_id || ' : ' || vw_account_types.accounts_class_name || ' : ' || vw_account_types.account_type_name
		|| ' : ' || accounts.account_name) as account_description
	FROM accounts INNER JOIN vw_account_types ON accounts.account_type_id = vw_account_types.account_type_id;

CREATE VIEW vw_default_accounts AS
	SELECT vw_accounts.accounts_class_id, vw_accounts.chat_type_id, vw_accounts.chat_type_name, 
		vw_accounts.accounts_class_name, vw_accounts.account_type_id, vw_accounts.account_type_name,
		vw_accounts.account_id, vw_accounts.account_name, vw_accounts.is_header, vw_accounts.is_active,
		default_accounts.default_account_id, default_accounts.org_id, default_accounts.narrative
	FROM vw_accounts INNER JOIN default_accounts ON vw_accounts.account_id = default_accounts.account_id;
	
CREATE VIEW vw_journals AS
	SELECT vw_periods.fiscal_year_id, vw_periods.fiscal_year_start, vw_periods.fiscal_year_end,
		vw_periods.year_opened, vw_periods.year_closed,
		vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.opened, vw_periods.closed, 
		vw_periods.month_id, vw_periods.period_year, vw_periods.period_month, vw_periods.quarter, vw_periods.semister,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		departments.department_id, departments.department_name,
		journals.journal_id, journals.org_id, journals.journal_date, journals.posted, journals.year_closing, journals.narrative, 
		journals.exchange_rate, journals.details
	FROM journals INNER JOIN vw_periods ON journals.period_id = vw_periods.period_id
		INNER JOIN currency ON journals.currency_id = currency.currency_id
		INNER JOIN departments ON journals.department_id = departments.department_id;

CREATE VIEW vw_gls AS
	SELECT vw_accounts.accounts_class_id, vw_accounts.chat_type_id, vw_accounts.chat_type_name, 
		vw_accounts.accounts_class_name, vw_accounts.account_type_id, vw_accounts.account_type_name,
		vw_accounts.account_id, vw_accounts.account_name, vw_accounts.is_header, vw_accounts.is_active,
		vw_journals.fiscal_year_id, vw_journals.fiscal_year_start, vw_journals.fiscal_year_end,
		vw_journals.year_opened, vw_journals.year_closed,
		vw_journals.period_id, vw_journals.start_date, vw_journals.end_date, vw_journals.opened, vw_journals.closed, 
		vw_journals.month_id, vw_journals.period_year, vw_journals.period_month, vw_journals.quarter, vw_journals.semister,
		vw_journals.currency_id, vw_journals.currency_name, vw_journals.currency_symbol, vw_journals.exchange_rate,
		vw_journals.journal_id, vw_journals.journal_date, vw_journals.posted, vw_journals.year_closing, vw_journals.narrative,
		gls.gl_id, gls.org_id, gls.debit, gls.credit, gls.gl_narrative,
		(gls.debit * vw_journals.exchange_rate) as base_debit, (gls.credit * vw_journals.exchange_rate) as base_credit
	FROM gls INNER JOIN vw_accounts ON gls.account_id = vw_accounts.account_id
		INNER JOIN vw_journals ON gls.journal_id = vw_journals.journal_id;

CREATE VIEW vw_sm_gls AS
	SELECT vw_gls.org_id, vw_gls.accounts_class_id, vw_gls.chat_type_id, vw_gls.chat_type_name, 
		vw_gls.accounts_class_name, vw_gls.account_type_id, vw_gls.account_type_name, 
		vw_gls.account_id, vw_gls.account_name, vw_gls.is_header, vw_gls.is_active, 
		vw_gls.fiscal_year_id, vw_gls.fiscal_year_start, vw_gls.fiscal_year_end, 
		vw_gls.year_opened, vw_gls.year_closed, vw_gls.period_id, vw_gls.start_date, 
		vw_gls.end_date, vw_gls.opened, vw_gls.closed, vw_gls.month_id, 
		vw_gls.period_year, vw_gls.period_month, vw_gls.quarter, vw_gls.semister, 
		sum(vw_gls.debit) as acc_debit, sum(vw_gls.credit) as acc_credit,
		sum(vw_gls.base_debit) as acc_base_debit, sum(vw_gls.base_credit) as acc_base_credit
	FROM vw_gls
	WHERE (vw_gls.posted = true)
	GROUP BY vw_gls.org_id, vw_gls.accounts_class_id, vw_gls.chat_type_id, vw_gls.chat_type_name, 
		vw_gls.accounts_class_name, vw_gls.account_type_id, vw_gls.account_type_name, 
		vw_gls.account_id, vw_gls.account_name, vw_gls.is_header, vw_gls.is_active, 
		vw_gls.fiscal_year_id, vw_gls.fiscal_year_start, vw_gls.fiscal_year_end, 
		vw_gls.year_opened, vw_gls.year_closed, vw_gls.period_id, vw_gls.start_date,
		vw_gls.end_date, vw_gls.opened, vw_gls.closed, vw_gls.month_id, 
		vw_gls.period_year, vw_gls.period_month, vw_gls.quarter, vw_gls.semister
	ORDER BY vw_gls.account_id;

CREATE VIEW vw_ledger AS
	SELECT vw_sm_gls.org_id, vw_sm_gls.accounts_class_id, vw_sm_gls.chat_type_id, vw_sm_gls.chat_type_name, 
		vw_sm_gls.accounts_class_name, vw_sm_gls.account_type_id, vw_sm_gls.account_type_name, 
		vw_sm_gls.account_id, vw_sm_gls.account_name, vw_sm_gls.is_header, vw_sm_gls.is_active, 
		vw_sm_gls.fiscal_year_id, vw_sm_gls.fiscal_year_start, vw_sm_gls.fiscal_year_end, 
		vw_sm_gls.year_opened, vw_sm_gls.year_closed, vw_sm_gls.period_id, vw_sm_gls.start_date,
		vw_sm_gls.end_date, vw_sm_gls.opened, vw_sm_gls.closed, vw_sm_gls.month_id, 
		vw_sm_gls.period_year, vw_sm_gls.period_month, vw_sm_gls.quarter, vw_sm_gls.semister, 
		vw_sm_gls.acc_debit, vw_sm_gls.acc_credit, (vw_sm_gls.acc_debit - vw_sm_gls.acc_credit) as acc_balance,
		COALESCE((CASE WHEN vw_sm_gls.acc_debit > vw_sm_gls.acc_credit THEN vw_sm_gls.acc_debit - vw_sm_gls.acc_credit ELSE 0 END), 0) as bal_debit,
		COALESCE((CASE WHEN vw_sm_gls.acc_debit < vw_sm_gls.acc_credit THEN vw_sm_gls.acc_credit - vw_sm_gls.acc_debit ELSE 0 END), 0) as bal_credit,
		vw_sm_gls.acc_base_debit, vw_sm_gls.acc_base_credit, (vw_sm_gls.acc_base_debit - vw_sm_gls.acc_base_credit) as acc_base_balance,
		COALESCE((CASE WHEN vw_sm_gls.acc_base_debit > vw_sm_gls.acc_base_credit THEN vw_sm_gls.acc_base_debit - vw_sm_gls.acc_base_credit ELSE 0 END), 0) as bal_base_debit,
		COALESCE((CASE WHEN vw_sm_gls.acc_base_debit < vw_sm_gls.acc_base_credit THEN vw_sm_gls.acc_base_credit - vw_sm_gls.acc_base_debit ELSE 0 END), 0) as bal_base_credit
	FROM vw_sm_gls;

CREATE VIEW vw_budget_ledger AS
	SELECT journals.org_id, periods.fiscal_year_id, journals.department_id, gls.account_id,
		sum(journals.exchange_rate * gls.debit) as bl_debit, sum(journals.exchange_rate * gls.credit) as bl_credit,
		sum(journals.exchange_rate * (gls.debit - gls.credit)) as bl_diff
	FROM journals INNER JOIN gls ON journals.journal_id = gls.journal_id
		INNER JOIN periods ON journals.period_id = periods.period_id
	WHERE (journals.posted = true)
	GROUP BY journals.org_id, periods.fiscal_year_id, journals.department_id, gls.account_id;
		
CREATE VIEW vw_tax_types AS
	SELECT vw_accounts.account_type_id, vw_accounts.account_type_name, vw_accounts.account_id, vw_accounts.account_name, 
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		tax_types.org_id, tax_types.tax_type_id, tax_types.tax_type_name, tax_types.formural, tax_types.tax_relief, 
		tax_types.tax_type_order, tax_types.in_tax, tax_types.tax_rate, tax_types.tax_inclusive, tax_types.linear, 
		tax_types.percentage, tax_types.employer, tax_types.employer_ps, tax_types.account_number, tax_types.active, 
		tax_types.use_key, tax_types.details
	FROM tax_types INNER JOIN currency ON tax_types.currency_id = currency.currency_id
		LEFT JOIN vw_accounts ON tax_types.account_id = vw_accounts.account_id;

CREATE VIEW vw_tax_rates AS
	SELECT tax_types.tax_type_id, tax_types.tax_type_name, tax_types.tax_relief, tax_types.linear, tax_types.percentage,
		tax_rates.org_id, tax_rates.tax_rate_id, tax_rates.tax_range, tax_rates.tax_rate, tax_rates.narrative
	FROM tax_rates INNER JOIN tax_types ON tax_rates.tax_type_id = tax_types.tax_type_id;

CREATE VIEW vw_period_tax_types AS
	SELECT vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.overtime_rate,  
		vw_periods.activated, vw_periods.closed, vw_periods.month_id, vw_periods.period_year, vw_periods.period_month,
		vw_periods.quarter, vw_periods.semister,
		tax_types.tax_type_id, tax_types.tax_type_name, period_tax_types.period_tax_type_id, period_tax_types.Period_Tax_Type_Name, tax_types.use_key,
		period_tax_types.org_id, period_tax_types.Pay_Date, period_tax_types.tax_relief, period_tax_types.linear, period_tax_types.percentage, 
		period_tax_types.formural, period_tax_types.details
	FROM period_tax_types INNER JOIN vw_periods ON period_tax_types.period_id = vw_periods.period_id
		INNER JOIN tax_types ON period_tax_types.tax_type_id = tax_types.tax_type_id;

CREATE OR REPLACE FUNCTION getTaxMin(float, int) RETURNS float AS $$
	SELECT CASE WHEN max(tax_range) is null THEN 0 ELSE max(tax_range) END 
	FROM period_tax_rates WHERE (tax_range < $1) AND (period_tax_type_id = $2);
$$ LANGUAGE SQL;

CREATE VIEW vw_period_tax_rates AS
	SELECT period_tax_types.period_tax_type_id, period_tax_types.period_tax_type_name, period_tax_types.tax_type_id, 
		period_tax_types.period_id, period_tax_rates.period_tax_rate_id, 
		getTaxMin(period_tax_rates.tax_range, period_tax_types.period_tax_type_id) as min_range, 
		period_tax_rates.org_id, period_tax_rates.tax_range as max_range, period_tax_rates.tax_rate, period_tax_rates.narrative
	FROM period_tax_rates INNER JOIN period_tax_types ON period_tax_rates.period_tax_type_id = period_tax_types.period_tax_type_id;
	
CREATE VIEW vw_default_tax_types AS
	SELECT entitys.entity_id, entitys.entity_name, 
		vw_tax_types.tax_type_id, vw_tax_types.tax_type_name, 
		vw_tax_types.currency_id, vw_tax_types.currency_name, vw_tax_types.currency_symbol,
		default_tax_types.default_tax_type_id, 
		default_tax_types.org_id, default_tax_types.tax_identification, default_tax_types.active, default_tax_types.narrative
	FROM default_tax_types INNER JOIN entitys ON default_tax_types.entity_id = entitys.entity_id
		INNER JOIN vw_tax_types ON default_tax_types.tax_type_id = vw_tax_types.tax_type_id;
	
CREATE OR REPLACE FUNCTION prev_acct(integer, date) RETURNS real AS $$
    SELECT sum(gls.debit - gls.credit)
	FROM gls INNER JOIN journals ON gls.journal_id = journals.journal_id
	WHERE (gls.account_id = $1) AND (journals.posted = true) 
		AND (journals.journal_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_acct(integer, date, date) RETURNS real AS $$
    SELECT sum(gls.debit - gls.credit)
	FROM gls INNER JOIN journals ON gls.journal_id = journals.journal_id
	WHERE (gls.account_id = $1) AND (journals.posted = true) AND (journals.year_closing = false)
		AND (journals.journal_date >= $2) AND (journals.journal_date <= $3);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION prev_returns(date) RETURNS real AS $$
    SELECT COALESCE(sum(credit - debit), 0)
	FROM vw_gls
	WHERE (chat_type_id > 3) AND (posted = true) AND (journal_date < $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION curr_returns(date, date) RETURNS real AS $$
    SELECT COALESCE(sum(credit - debit), 0)
	FROM vw_gls
	WHERE (chat_type_id > 3) AND (posted = true) AND (year_closing = false)
		AND (journal_date >= $1) AND (journal_date <= $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION prev_base_acct(integer, date) RETURNS real AS $$
    SELECT sum(gls.debit * journals.exchange_rate - gls.credit * journals.exchange_rate) 
	FROM gls INNER JOIN journals ON gls.journal_id = journals.journal_id
	WHERE (gls.account_id = $1) AND (journals.posted = true) 
		AND (journals.journal_date < $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_base_acct(integer, date, date) RETURNS real AS $$
    SELECT sum(gls.debit * journals.exchange_rate - gls.credit * journals.exchange_rate) 
	FROM gls INNER JOIN journals ON gls.journal_id = journals.journal_id
	WHERE (gls.account_id = $1) AND (journals.posted = true) AND (journals.year_closing = false)
		AND (journals.journal_date >= $2) AND (journals.journal_date <= $3);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION prev_base_returns(date) RETURNS real AS $$
    SELECT COALESCE(sum(base_credit - base_debit), 0)
	FROM vw_gls
	WHERE (chat_type_id > 3) AND (posted = true) AND (journal_date < $1);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION curr_base_returns(date, date) RETURNS real AS $$
    SELECT COALESCE(sum(base_credit - base_debit), 0)
	FROM vw_gls
	WHERE (chat_type_id > 3) AND (posted = true) AND (year_closing = false)
		AND (journal_date >= $1) AND (journal_date <= $2);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION process_journal(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
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
$$ LANGUAGE plpgsql;

CREATE FUNCTION upd_gls() RETURNS trigger AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_gls BEFORE INSERT OR UPDATE ON gls
    FOR EACH ROW EXECUTE PROCEDURE upd_gls();

CREATE OR REPLACE FUNCTION close_year(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
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
$$ LANGUAGE plpgsql;


