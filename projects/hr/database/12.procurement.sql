CREATE TABLE budgets (
	budget_id				serial primary key,
	org_id					integer references orgs,
	fiscal_year_id			varchar(9) references fiscal_years,
	department_id			integer	references departments,
	link_budget_id			integer references budgets,
	entity_id				integer references entitys,
	budget_type				integer default 1 not null,
	budget_name				varchar(50),
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	details					text
);
CREATE INDEX budgets_org_id ON budgets (org_id);
CREATE INDEX budgets_fiscal_year_id ON budgets (fiscal_year_id);
CREATE INDEX budgets_department_id ON budgets (department_id);
CREATE INDEX budgets_link_budget_id ON budgets (link_budget_id);

CREATE TABLE budget_lines (
    budget_line_id 			serial primary key,
	org_id					integer references orgs,
    budget_id	 			integer references budgets,
	period_id				integer references periods,
	account_id				integer references accounts,
	item_id					integer references items,
	transaction_id 			integer references transactions,
	spend_type				integer default 0 not null,
	quantity				integer default 1 not null,
    amount 					real default 0 not null,
	tax_amount				real default 0 not null,
	income_budget			boolean default false not null,
    narrative				varchar(240),
	details					text
);
CREATE INDEX budget_lines_org_id ON budget_lines (org_id);
CREATE INDEX budget_lines_budget_id ON budget_lines (budget_id);
CREATE INDEX budget_lines_period_id ON budget_lines (period_id);
CREATE INDEX budget_lines_account_id ON budget_lines (account_id);
CREATE INDEX budget_lines_item_id ON budget_lines (item_id);
CREATE INDEX budget_lines_transaction_id ON budget_lines (transaction_id);

CREATE TABLE stocks (
	stock_id				serial primary key,
	org_id					integer references orgs,
	store_id				integer references stores,
	stock_name				varchar(50),
	stock_take_date			date,
	details					text
);
CREATE INDEX stocks_org_id ON stocks (org_id);
CREATE INDEX stocks_store_id ON stocks (store_id);

CREATE TABLE stock_lines (
	stock_line_id			serial primary key,
	org_id					integer references orgs,
	stock_id				integer references stocks,
	item_id					integer references items,
	quantity				integer,
	narrative				varchar(240)
);
CREATE INDEX stock_lines_org_id ON stock_lines (org_id);
CREATE INDEX stock_lines_stock_id ON stock_lines (stock_id);
CREATE INDEX stock_lines_item_id ON stock_lines (item_id);

CREATE TABLE tender_types (
	tender_type_id			serial primary key,
	org_id					integer references orgs,
	tender_type_name		varchar(50) unique,
	details					text
);
CREATE INDEX tender_types_org_id ON tender_types (org_id);

CREATE TABLE tenders (
	tender_id				serial primary key,
	org_id					integer references orgs,
	tender_type_id			integer references tender_types,
	tender_name				varchar(320),
	tender_number			varchar(64),
	tender_date				date not null,
	tender_end_date			date,
	is_completed			boolean default false not null,
	details					text
);
CREATE INDEX tenders_org_id ON tenders (org_id);
CREATE INDEX tenders_tender_type_id ON tenders (tender_type_id);

CREATE TABLE bidders (
	bidder_id				serial primary key,
	org_id					integer references orgs,
	tender_id				integer references tenders,
    entity_id 				integer references entitys,
	bidder_name				varchar(120),
	tender_amount			real,
	bind_bond				varchar(120),
	bind_bond_amount		real,
	return_date				date,
	points					real,
	is_awarded				boolean not null,
	award_reference			varchar(32),
	details					text
);
CREATE INDEX bidders_org_id ON bidders (org_id);
CREATE INDEX bidders_tender_id ON bidders (tender_id);
CREATE INDEX bidders_entity_id ON bidders (entity_id);

CREATE TABLE tender_items (
	tender_item_id			serial primary key,
	org_id					integer references orgs,
	bidder_id				integer references bidders,
	tender_item_name		varchar(320) not null,
	quantity				integer,
	item_amount				real,
	item_tax				real,
	details					text
);
CREATE INDEX tender_items_org_id ON tender_items (org_id);
CREATE INDEX tender_items_bidder_id ON tender_items (bidder_id);

CREATE TABLE contracts (
	contract_id				serial primary key,
	org_id					integer references orgs,
	bidder_id				integer references bidders,
	contract_name			varchar(320) not null,
	contract_date			date,
	contract_end			date,
	contract_amount			real,
	contract_tax			real,
	details					text
);
CREATE INDEX contracts_org_id ON contracts (org_id);
CREATE INDEX contracts_bidder_id ON contracts (bidder_id);

CREATE VIEW vw_budgets AS
	SELECT departments.department_id, departments.department_name, fiscal_years.fiscal_year_id, fiscal_years.fiscal_year_start,
		fiscal_years.fiscal_year_end, fiscal_years.year_opened, fiscal_years.year_closed,
		budgets.budget_id, budgets.org_id, budgets.budget_type, budgets.budget_name, budgets.application_date, 
		budgets.approve_status, budgets.workflow_table_id, budgets.action_date, budgets.details
	FROM budgets INNER JOIN departments ON budgets.department_id = departments.department_id
		INNER JOIN fiscal_years ON budgets.fiscal_year_id = fiscal_years.fiscal_year_id;

CREATE VIEW vw_budget_lines AS
	SELECT vw_budgets.department_id, vw_budgets.department_name, vw_budgets.fiscal_year_id, vw_budgets.fiscal_year_start,
		vw_budgets.fiscal_year_end, vw_budgets.year_opened, vw_budgets.year_closed,
		vw_budgets.budget_id, vw_budgets.budget_name, vw_budgets.budget_type, vw_budgets.approve_status, 

		periods.period_id, periods.start_date, periods.end_date, periods.opened, periods.activated, periods.closed, 
		periods.overtime_rate, periods.per_diem_tax_limit, periods.is_posted, periods.bank_header, periods.bank_address, 

		date_part('month', periods.start_date) as month_id, to_char(periods.start_date, 'YYYY') as period_year, 
		to_char(periods.start_date, 'Month') as period_month, (trunc((date_part('month', periods.start_date)-1)/3)+1) as quarter, 
		(trunc((date_part('month', periods.start_date)-1)/6)+1) as semister,

		vw_accounts.accounts_class_id, vw_accounts.chat_type_id, vw_accounts.chat_type_name, 
		vw_accounts.accounts_class_name, vw_accounts.account_type_id, vw_accounts.account_type_name,
		vw_accounts.account_id, vw_accounts.account_name, vw_accounts.is_header, vw_accounts.is_active,
		vw_items.item_id, vw_items.item_name, vw_items.tax_type_id, vw_items.tax_account_id, vw_items.tax_type_name, 
		vw_items.tax_rate, vw_items.tax_inclusive, vw_items.sales_account_id, vw_items.purchase_account_id,
		budget_lines.budget_line_id, budget_lines.org_id, budget_lines.transaction_id, budget_lines.spend_type, 
		budget_lines.quantity, budget_lines.amount, budget_lines.tax_amount, budget_lines.narrative, budget_lines.details,
		(CASE WHEN budget_lines.spend_type = 1 THEN 'Monthly' WHEN budget_lines.spend_type = 2 THEN 'Quaterly' ELSE 'Once' END) as spend_type_name,
		budget_lines.income_budget, (CASE WHEN budget_lines.income_budget = true THEN 'Income Budget' ELSE 'Expenditure Budget' END) as income_expense,
		(CASE WHEN budget_lines.income_budget = true THEN budget_lines.amount ELSE 0 END) as dr_budget,
		(CASE WHEN budget_lines.income_budget = false THEN budget_lines.amount ELSE 0 END) as cr_budget
	FROM budget_lines INNER JOIN vw_budgets ON budget_lines.budget_id = vw_budgets.budget_id
		INNER JOIN periods ON budget_lines.period_id = periods.period_id
		INNER JOIN vw_accounts ON budget_lines.account_id = vw_accounts.account_id
		LEFT JOIN vw_items ON budget_lines.item_id = vw_items.item_id;

CREATE VIEW vw_budget_pds AS
	SELECT vw_budget_lines.department_id, vw_budget_lines.department_name, vw_budget_lines.fiscal_year_id, 
		vw_budget_lines.fiscal_year_start, vw_budget_lines.fiscal_year_end, vw_budget_lines.year_opened, vw_budget_lines.year_closed,
		vw_budget_lines.period_id, vw_budget_lines.start_date, vw_budget_lines.end_date, vw_budget_lines.opened, 
		vw_budget_lines.closed, vw_budget_lines.month_id, vw_budget_lines.period_year, vw_budget_lines.period_month, 
		vw_budget_lines.quarter, vw_budget_lines.semister, vw_budget_lines.budget_type,
		vw_budget_lines.accounts_class_id, vw_budget_lines.chat_type_id, vw_budget_lines.chat_type_name, 
		vw_budget_lines.accounts_class_name, vw_budget_lines.account_type_id, vw_budget_lines.account_type_name,
		vw_budget_lines.account_id, vw_budget_lines.account_name, vw_budget_lines.is_header, vw_budget_lines.is_active,
		vw_budget_lines.item_id, vw_budget_lines.item_name, vw_budget_lines.tax_type_id, vw_budget_lines.tax_account_id, 
		vw_budget_lines.tax_type_name, vw_budget_lines.tax_rate, vw_budget_lines.tax_inclusive, vw_budget_lines.sales_account_id, 
		vw_budget_lines.purchase_account_id,
		vw_budget_lines.budget_line_id, vw_budget_lines.org_id, vw_budget_lines.transaction_id, vw_budget_lines.spend_type, 
		vw_budget_lines.spend_type_name, vw_budget_lines.income_budget, vw_budget_lines.income_expense,
		sum(vw_budget_lines.quantity) as s_quantity, sum(vw_budget_lines.amount) as s_amount, 
		sum(vw_budget_lines.tax_amount) as s_tax_amount, 
		sum(vw_budget_lines.dr_budget) as s_dr_budget, sum(vw_budget_lines.cr_budget) as s_cr_budget,
		sum(vw_budget_lines.dr_budget - vw_budget_lines.cr_budget) as budget_diff
	FROM vw_budget_lines
	WHERE (vw_budget_lines.approve_status = 'Approved')
	GROUP BY vw_budget_lines.department_id, vw_budget_lines.department_name, vw_budget_lines.fiscal_year_id, 
		vw_budget_lines.fiscal_year_start, vw_budget_lines.fiscal_year_end, vw_budget_lines.year_opened, vw_budget_lines.year_closed,
		vw_budget_lines.period_id, vw_budget_lines.start_date, vw_budget_lines.end_date, vw_budget_lines.opened, 
		vw_budget_lines.closed, vw_budget_lines.month_id, vw_budget_lines.period_year, vw_budget_lines.period_month, 
		vw_budget_lines.quarter, vw_budget_lines.semister, vw_budget_lines.budget_type,
		vw_budget_lines.accounts_class_id, vw_budget_lines.chat_type_id, vw_budget_lines.chat_type_name, 
		vw_budget_lines.accounts_class_name, vw_budget_lines.account_type_id, vw_budget_lines.account_type_name,
		vw_budget_lines.account_id, vw_budget_lines.account_name, vw_budget_lines.is_header, vw_budget_lines.is_active,
		vw_budget_lines.item_id, vw_budget_lines.item_name, vw_budget_lines.tax_type_id, vw_budget_lines.tax_account_id, 
		vw_budget_lines.tax_type_name, vw_budget_lines.tax_rate, vw_budget_lines.tax_inclusive, vw_budget_lines.sales_account_id, 
		vw_budget_lines.purchase_account_id,
		vw_budget_lines.budget_line_id, vw_budget_lines.org_id, vw_budget_lines.transaction_id, vw_budget_lines.spend_type, 
		vw_budget_lines.spend_type_name, vw_budget_lines.income_budget, vw_budget_lines.income_expense;

CREATE VIEW vw_budget_ads AS
	SELECT vw_budget_lines.department_id, vw_budget_lines.department_name, vw_budget_lines.fiscal_year_id, 
		vw_budget_lines.fiscal_year_start, vw_budget_lines.fiscal_year_end, vw_budget_lines.year_opened, vw_budget_lines.year_closed,
		vw_budget_lines.budget_type,
		vw_budget_lines.accounts_class_id, vw_budget_lines.chat_type_id, vw_budget_lines.chat_type_name, 
		vw_budget_lines.accounts_class_name, vw_budget_lines.account_type_id, vw_budget_lines.account_type_name,
		vw_budget_lines.account_id, vw_budget_lines.account_name, vw_budget_lines.is_header, vw_budget_lines.is_active,
		vw_budget_lines.item_id, vw_budget_lines.item_name, vw_budget_lines.tax_type_id, vw_budget_lines.tax_account_id, 
		vw_budget_lines.org_id, vw_budget_lines.spend_type, vw_budget_lines.spend_type_name,  
		vw_budget_lines.income_budget, vw_budget_lines.income_expense,
		sum(vw_budget_lines.quantity) as s_quantity, sum(vw_budget_lines.amount) as s_amount, 
		sum(vw_budget_lines.tax_amount) as s_tax_amount, 
		sum(vw_budget_lines.dr_budget) as s_dr_budget, sum(vw_budget_lines.cr_budget) as s_cr_budget,
		sum(vw_budget_lines.dr_budget - vw_budget_lines.cr_budget) as budget_diff
	FROM vw_budget_lines
	WHERE (vw_budget_lines.approve_status = 'Approved')
	GROUP BY vw_budget_lines.department_id, vw_budget_lines.department_name, vw_budget_lines.fiscal_year_id, 
		vw_budget_lines.fiscal_year_start, vw_budget_lines.fiscal_year_end, vw_budget_lines.year_opened, vw_budget_lines.year_closed,
		vw_budget_lines.budget_type,
		vw_budget_lines.accounts_class_id, vw_budget_lines.chat_type_id, vw_budget_lines.chat_type_name, 
		vw_budget_lines.accounts_class_name, vw_budget_lines.account_type_id, vw_budget_lines.account_type_name,
		vw_budget_lines.account_id, vw_budget_lines.account_name, vw_budget_lines.is_header, vw_budget_lines.is_active,
		vw_budget_lines.item_id, vw_budget_lines.item_name, vw_budget_lines.tax_type_id, vw_budget_lines.tax_account_id, 
		vw_budget_lines.org_id, vw_budget_lines.spend_type, vw_budget_lines.spend_type_name,
		vw_budget_lines.income_budget, vw_budget_lines.income_expense;

CREATE VIEW vw_budget_pdc AS
	SELECT vw_budget_ads.department_id, vw_budget_ads.department_name, vw_budget_ads.fiscal_year_id, 
		vw_budget_ads.fiscal_year_start, vw_budget_ads.fiscal_year_end, vw_budget_ads.year_opened, vw_budget_ads.year_closed,
		vw_budget_ads.budget_type,
		vw_budget_ads.accounts_class_id, vw_budget_ads.chat_type_id, vw_budget_ads.chat_type_name, 
		vw_budget_ads.accounts_class_name, vw_budget_ads.account_type_id, vw_budget_ads.account_type_name,
		vw_budget_ads.account_id, vw_budget_ads.account_name, vw_budget_ads.is_header, vw_budget_ads.is_active,
		vw_budget_ads.item_id, vw_budget_ads.item_name, vw_budget_ads.tax_type_id, vw_budget_ads.tax_account_id, 
		vw_budget_ads.org_id, vw_budget_ads.spend_type, 
		vw_budget_ads.spend_type_name, vw_budget_ads.income_budget, vw_budget_ads.income_expense,
		vw_budget_ads.s_quantity, vw_budget_ads.s_amount, vw_budget_ads.s_tax_amount, 
		vw_budget_ads.s_dr_budget, vw_budget_ads.s_cr_budget,
		vw_budget_ledger.bl_debit, vw_budget_ledger.bl_credit,
		(CASE WHEN vw_budget_ads.income_budget = true THEN COALESCE(-1 * vw_budget_ledger.bl_diff, 0)
			ELSE COALESCE(vw_budget_ledger.bl_diff, 0) END) as amount_used,
		(CASE WHEN vw_budget_ads.income_budget = true THEN (vw_budget_ads.s_amount + COALESCE(vw_budget_ledger.bl_diff, 0))
			ELSE (vw_budget_ads.s_amount - COALESCE(vw_budget_ledger.bl_diff, 0)) END) as budget_balance
	FROM vw_budget_ads LEFT JOIN vw_budget_ledger ON 
		(vw_budget_ads.department_id = vw_budget_ledger.department_id) AND (vw_budget_ads.account_id = vw_budget_ledger.account_id)
		AND (vw_budget_ads.fiscal_year_id = vw_budget_ledger.fiscal_year_id);

CREATE VIEW vw_stocks AS
	SELECT stores.store_id, stores.store_name,
		stocks.stock_id, stocks.org_id, stocks.stock_name, stocks.stock_take_date, stocks.details
	FROM stocks INNER JOIN stores ON stocks.store_id = stores.store_id;

CREATE VIEW vw_stock_lines AS
	SELECT vw_stocks.stock_id, vw_stocks.stock_name, vw_stocks.stock_take_date, 
		vw_stocks.store_id, vw_stocks.store_name, items.item_id, items.item_name, 
		stock_lines.stock_line_id, stock_lines.org_id, stock_lines.quantity, stock_lines.narrative
	FROM stock_lines INNER JOIN vw_stocks ON stock_lines.stock_id = vw_stocks.stock_id
		INNER JOIN items ON stock_lines.item_id = items.item_id;

CREATE OR REPLACE FUNCTION upd_budget_lines() RETURNS trigger AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_budget_lines BEFORE INSERT OR UPDATE ON budget_lines
    FOR EACH ROW EXECUTE PROCEDURE upd_budget_lines();

CREATE OR REPLACE FUNCTION budget_process(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_budget(integer, varchar(9), integer) RETURNS integer AS $$
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
$$ LANGUAGE plpgsql;



------------Hooks to approval trigger
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON budgets
    FOR EACH ROW EXECUTE PROCEDURE upd_action();



