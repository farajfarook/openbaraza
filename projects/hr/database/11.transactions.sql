CREATE TABLE stores (
	store_id				serial primary key,
	org_id					integer references orgs,
	store_name				varchar(120),
	details					text
);
CREATE INDEX stores_org_id ON stores (org_id);

CREATE TABLE bank_accounts (
	bank_account_id			serial primary key,
	org_id					integer references orgs,
	bank_branch_id			integer references bank_branch,
	account_id				integer references accounts,
	currency_id				integer references currency,
	bank_account_name		varchar(120),
	bank_account_number		varchar(50),
    narrative				varchar(240),
	is_default				boolean default false not null,
	is_active				boolean default true not null,
    details					text
);
CREATE INDEX bank_accounts_org_id ON bank_accounts (org_id);
CREATE INDEX bank_accounts_bank_branch_id ON bank_accounts (bank_branch_id);
CREATE INDEX bank_accounts_account_id ON bank_accounts (account_id);
CREATE INDEX bank_accounts_currency_id ON bank_accounts (currency_id);

CREATE TABLE item_category (
	item_category_id		serial primary key,
	org_id					integer references orgs,
	item_category_name		varchar(120) not null unique,
	details					text  
);
CREATE INDEX item_category_org_id ON item_category (org_id);
INSERT INTO item_category (org_id, item_category_name) VALUES (0, 'Services');
INSERT INTO item_category (org_id, item_category_name) VALUES (0, 'Goods');
INSERT INTO item_category (org_id, item_category_name) VALUES (0, 'Utilities');

CREATE TABLE item_units (
	item_unit_id			serial primary key,
	org_id					integer references orgs,
	item_unit_name			varchar(50) not null unique,
	details					text
);
CREATE INDEX item_units_org_id ON item_units (org_id);
INSERT INTO item_units (org_id, item_unit_name) VALUES (0, 'Each');
INSERT INTO item_units (org_id, item_unit_name) VALUES (0, 'Man Hours');
INSERT INTO item_units (org_id, item_unit_name) VALUES (0, '100KG');

CREATE TABLE items (
	item_id					serial primary key,
	org_id					integer references orgs,
	item_category_id		integer references item_category,
	tax_type_id				integer references tax_types,
	item_unit_id			integer references item_units,
	sales_account_id		integer references accounts,
	purchase_account_id		integer references accounts,
	item_name				varchar(120),
	bar_code				varchar(32),
	inventory				boolean default false not null,
	for_sale				boolean default true not null,
	for_purchase			boolean default true not null,
	sales_price				real,
	purchase_price			real,
	reorder_level			integer,
	lead_time				integer,
	is_active				boolean default true not null,
	details					text
);
CREATE INDEX items_org_id ON items (org_id);
CREATE INDEX items_item_category_id ON items (item_category_id);
CREATE INDEX items_tax_type_id ON items (tax_type_id);
CREATE INDEX items_item_unit_id ON items (item_unit_id);
CREATE INDEX items_sales_account_id ON items (sales_account_id);
CREATE INDEX items_purchase_account_id ON items (purchase_account_id);

CREATE TABLE quotations (
	quotation_id 			serial primary key,
	org_id					integer references orgs,
	item_id					integer references items,
	entity_id				integer references entitys,
	active					boolean default false not null,
	amount 					real,
	valid_from				date,
	valid_to				date,
	lead_time				integer,
	details					text
);
CREATE INDEX quotations_org_id ON quotations (org_id);
CREATE INDEX quotations_item_id ON quotations (item_id);
CREATE INDEX quotations_entity_id ON quotations (entity_id);

CREATE TABLE transaction_types (
	transaction_type_id		integer primary key,
	transaction_type_name	varchar(50) not null,
	document_prefix			varchar(16) default 'D' not null,
	document_number			integer default 1 not null,
	for_sales				boolean default true not null,
	for_posting				boolean default true not null
);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (16, 'Requisitions', false, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (14, 'Sales Quotation', true, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (15, 'Purchase Quotation', false, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (1, 'Sales Order', true, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (2, 'Sales Invoice', true, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (3, 'Sales Template', true, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (4, 'Purchase Order', false, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (5, 'Purchase Invoice', false, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (6, 'Purchase Template', false, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (7, 'Receipts', true, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (8, 'Payments', false, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (9, 'Credit Note', true, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (10, 'Debit Note', false, true);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (11, 'Delivery Note', true, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (12, 'Receipt Note', false, false);
INSERT INTO transaction_types (transaction_type_id, transaction_type_name, for_sales, for_posting) VALUES (17, 'Work Use', true, false);

CREATE TABLE transaction_status (
	transaction_status_id	integer primary key,
	transaction_status_name	varchar(50) not null
);
INSERT INTO transaction_status (transaction_status_id, transaction_status_name) VALUES (1, 'Draft');
INSERT INTO transaction_status (transaction_status_id, transaction_status_name) VALUES (2, 'Completed');
INSERT INTO transaction_status (transaction_status_id, transaction_status_name) VALUES (3, 'Processed');
INSERT INTO transaction_status (transaction_status_id, transaction_status_name) VALUES (4, 'Archive');

CREATE TABLE transactions (
    transaction_id 			serial primary key,
    entity_id 				integer references entitys,
	transaction_type_id		integer references transaction_types,
	bank_account_id			integer references bank_accounts,
	journal_id				integer references journals,
	transaction_status_id	integer references transaction_status default 1,
	currency_id				integer references currency,
	department_id			integer references departments,
	org_id					integer references orgs,
	exchange_rate			real default 1 not null,
	transaction_date		date not null,
	transaction_amount		real default 0 not null,
	document_number			integer default 1 not null,
	payment_number			varchar(50),
	order_number			varchar(50),
	payment_terms			varchar(50),
	job						varchar(240),
	point_of_use			varchar(240),
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
    narrative				varchar(120),
    details					text
);
CREATE INDEX transactions_entity_id ON transactions (entity_id);
CREATE INDEX transactions_transaction_type_id ON transactions (transaction_type_id);
CREATE INDEX transactions_bank_account_id ON transactions (bank_account_id);
CREATE INDEX transactions_journal_id ON transactions (journal_id);
CREATE INDEX transactions_transaction_status_id ON transactions (transaction_status_id);
CREATE INDEX transactions_currency_id ON transactions (currency_id);
CREATE INDEX transactions_department_id ON transactions (department_id);
CREATE INDEX transactions_workflow_table_id ON transactions (workflow_table_id);
CREATE INDEX transactions_org_id ON transactions (org_id);

CREATE TABLE transaction_details (
	transaction_detail_id 	serial primary key,
	transaction_id 			integer references transactions,
	account_id				integer references accounts,
	item_id					integer references items,
	store_id				integer references stores,
	org_id					integer references orgs,
	quantity				integer not null,
    amount 					real default 0 not null,
	tax_amount				real default 0 not null,
	narrative				varchar(240),
	purpose					varchar(320),
	details					text
);
CREATE INDEX transaction_details_transaction_id ON transaction_details (transaction_id);
CREATE INDEX transaction_details_account_id ON transaction_details (account_id);
CREATE INDEX transaction_details_item_id ON transaction_details (item_id);
CREATE INDEX transaction_details_org_id ON transaction_details (org_id);

CREATE TABLE transaction_links (
	transaction_link_id		serial primary key,
	org_id					integer references orgs,
	transaction_id			integer references transactions,
	transaction_to			integer references transactions,
	transaction_detail_id	integer references transaction_details,
	transaction_detail_to	integer references transaction_details,
	amount					real default 0 not null,
	quantity				integer default 0  not null,
	narrative				varchar(240)
);
CREATE INDEX transaction_links_org_id ON transaction_links (org_id);
CREATE INDEX transaction_links_transaction_id ON transaction_links (transaction_id);
CREATE INDEX transaction_links_transaction_to ON transaction_links (transaction_to);
CREATE INDEX transaction_links_transaction_detail_id ON transaction_links (transaction_detail_id);
CREATE INDEX transaction_links_transaction_detail_to ON transaction_links (transaction_detail_to);

CREATE TABLE day_ledgers (
    day_ledger_id 			serial primary key,
    entity_id 				integer references entitys,
	transaction_type_id		integer references transaction_types,
	bank_account_id			integer references bank_accounts,
	journal_id				integer references journals,
	transaction_status_id	integer references transaction_status default 1,
	currency_id				integer references currency,
	department_id			integer references departments,
	item_id					integer references items,
	store_id				integer references stores,
	org_id					integer references orgs,

	exchange_rate			real default 1 not null,
	day_ledger_date			date not null,
	day_ledger_quantity		integer not null,
    day_ledger_amount 		real default 0 not null,
	day_ledger_tax_amount	real default 0 not null,
	
	document_number			integer default 1 not null,
	payment_number			varchar(50),
	order_number			varchar(50),
	payment_terms			varchar(50),
	job						varchar(240),
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
    narrative				varchar(120),
    details					text
);
CREATE INDEX day_ledgers_entity_id ON day_ledgers (entity_id);
CREATE INDEX day_ledgers_transaction_type_id ON day_ledgers (transaction_type_id);
CREATE INDEX day_ledgers_bank_account_id ON day_ledgers (bank_account_id);
CREATE INDEX day_ledgers_journal_id ON day_ledgers (journal_id);
CREATE INDEX day_ledgers_transaction_status_id ON day_ledgers (transaction_status_id);
CREATE INDEX day_ledgers_currency_id ON day_ledgers (currency_id);
CREATE INDEX day_ledgers_department_id ON day_ledgers (department_id);
CREATE INDEX day_ledgers_item_id ON day_ledgers (item_id);
CREATE INDEX day_ledgers_store_id ON day_ledgers (store_id);
CREATE INDEX day_ledgers_workflow_table_id ON day_ledgers (workflow_table_id);
CREATE INDEX day_ledgers_org_id ON day_ledgers (org_id);

CREATE VIEW vw_bank_accounts AS
	SELECT vw_bank_branch.bank_id, vw_bank_branch.bank_name, vw_bank_branch.bank_branch_id, vw_bank_branch.bank_branch_name, 
		vw_accounts.account_type_id, vw_accounts.account_type_name, vw_accounts.account_id, vw_accounts.account_name,
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		bank_accounts.bank_account_id, bank_accounts.org_id, bank_accounts.bank_account_name, bank_accounts.bank_account_number, 
		bank_accounts.narrative, bank_accounts.is_active, bank_accounts.details
	FROM bank_accounts INNER JOIN vw_bank_branch ON bank_accounts.bank_branch_id = vw_bank_branch.bank_branch_id
		INNER JOIN vw_accounts ON bank_accounts.account_id = vw_accounts.account_id
		INNER JOIN currency ON bank_accounts.currency_id = currency.currency_id;

CREATE VIEW vw_items AS
	SELECT sales_account.account_id as sales_account_id, sales_account.account_name as sales_account_name, 
		purchase_account.account_id as purchase_account_id, purchase_account.account_name as purchase_account_name, 
		item_category.item_category_id, item_category.item_category_name, item_units.item_unit_id, item_units.item_unit_name, 
		tax_types.tax_type_id, tax_types.tax_type_name,
		tax_types.account_id as tax_account_id, tax_types.tax_rate, tax_types.tax_inclusive,
		items.item_id, items.org_id, items.item_name, items.inventory, items.bar_code,
		items.for_sale, items.for_purchase, items.sales_price, items.purchase_price, items.reorder_level, items.lead_time, 
		items.is_active, items.details
	FROM items INNER JOIN accounts as sales_account ON items.sales_account_id = sales_account.account_id
		INNER JOIN accounts as purchase_account ON items.purchase_account_id = purchase_account.account_id
		INNER JOIN item_category ON items.item_category_id = item_category.item_category_id
		INNER JOIN item_units ON items.item_unit_id = item_units.item_unit_id
		INNER JOIN tax_types ON items.tax_type_id = tax_types.tax_type_id;

CREATE VIEW vw_quotations AS
	SELECT entitys.entity_id, entitys.entity_name, items.item_id, items.item_name, 
		quotations.quotation_id, quotations.org_id, quotations.active, quotations.amount, quotations.valid_from, 
		quotations.valid_to, quotations.lead_time, quotations.details
	FROM quotations	INNER JOIN entitys ON quotations.entity_id = entitys.entity_id
		INNER JOIN items ON quotations.item_id = items.item_id;

CREATE VIEW vw_transactions AS
	SELECT transaction_types.transaction_type_id, transaction_types.transaction_type_name, 
		transaction_types.document_prefix, transaction_types.for_posting, transaction_types.for_sales, 
		entitys.entity_id, entitys.entity_name, entitys.account_id as entity_account_id, 
		currency.currency_id, currency.currency_name,
		vw_bank_accounts.bank_id, vw_bank_accounts.bank_name, vw_bank_accounts.bank_branch_name, vw_bank_accounts.account_id as gl_bank_account_id, 
		vw_bank_accounts.bank_account_id, vw_bank_accounts.bank_account_name, vw_bank_accounts.bank_account_number, 
		departments.department_id, departments.department_name,
		transaction_status.transaction_status_id, transaction_status.transaction_status_name, transactions.journal_id, 
		transactions.transaction_id, transactions.org_id, transactions.transaction_date, transactions.transaction_amount,
		transactions.application_date, transactions.approve_status, transactions.workflow_table_id, transactions.action_date, 
		transactions.narrative, transactions.document_number, transactions.payment_number, transactions.order_number,
		transactions.exchange_rate, transactions.payment_terms, transactions.job, transactions.details,
		(CASE WHEN transactions.journal_id is null THEN 'Not Posted' ELSE 'Posted' END) as posted,
		(CASE WHEN (transactions.transaction_type_id = 2) or (transactions.transaction_type_id = 8) or (transactions.transaction_type_id = 10) 
			THEN transactions.transaction_amount ELSE 0 END) as debit_amount,
		(CASE WHEN (transactions.transaction_type_id = 5) or (transactions.transaction_type_id = 7) or (transactions.transaction_type_id = 9) 
			THEN transactions.transaction_amount ELSE 0 END) as credit_amount
	FROM transactions INNER JOIN transaction_types ON transactions.transaction_type_id = transaction_types.transaction_type_id
		INNER JOIN transaction_status ON transactions.transaction_status_id = transaction_status.transaction_status_id
		INNER JOIN currency ON transactions.currency_id = currency.currency_id
		LEFT JOIN entitys ON transactions.entity_id = entitys.entity_id
		LEFT JOIN vw_bank_accounts ON vw_bank_accounts.bank_account_id = transactions.bank_account_id
		LEFT JOIN departments ON transactions.department_id = departments.department_id;

CREATE VIEW vw_trx AS
	SELECT vw_orgs.org_id, vw_orgs.org_name, vw_orgs.is_default as org_is_default, vw_orgs.is_active as org_is_active, 
		vw_orgs.logo as org_logo, vw_orgs.cert_number as org_cert_number, vw_orgs.pin as org_pin, 
		vw_orgs.vat_number as org_vat_number, vw_orgs.invoice_footer as org_invoice_footer,
		vw_orgs.sys_country_id as org_sys_country_id, vw_orgs.sys_country_name as org_sys_country_name, 
		vw_orgs.address_id as org_address_id, vw_orgs.table_name as org_table_name,
		vw_orgs.post_office_box as org_post_office_box, vw_orgs.postal_code as org_postal_code, 
		vw_orgs.premises as org_premises, vw_orgs.street as org_street, vw_orgs.town as org_town, 
		vw_orgs.phone_number as org_phone_number, vw_orgs.extension as org_extension, 
		vw_orgs.mobile as org_mobile, vw_orgs.fax as org_fax, vw_orgs.email as org_email, vw_orgs.website as org_website,
		vw_entitys.address_id, vw_entitys.address_name,
		vw_entitys.sys_country_id, vw_entitys.sys_country_name, vw_entitys.table_name, vw_entitys.is_default,
		vw_entitys.post_office_box, vw_entitys.postal_code, vw_entitys.premises, vw_entitys.street, vw_entitys.town, 
		vw_entitys.phone_number, vw_entitys.extension, vw_entitys.mobile, vw_entitys.fax, vw_entitys.email, vw_entitys.website,
		vw_entitys.entity_id, vw_entitys.entity_name, vw_entitys.User_name, vw_entitys.Super_User, vw_entitys.attention, 
		vw_entitys.Date_Enroled, vw_entitys.Is_Active, vw_entitys.entity_type_id, vw_entitys.entity_type_name,
		vw_entitys.entity_role, vw_entitys.use_key,
		transaction_types.transaction_type_id, transaction_types.transaction_type_name, 
		transaction_types.document_prefix, transaction_types.for_sales, transaction_types.for_posting,
		transaction_status.transaction_status_id, transaction_status.transaction_status_name, 
		currency.currency_id, currency.currency_name, currency.currency_symbol,
		departments.department_id, departments.department_name,
		transactions.journal_id, transactions.bank_account_id,
		transactions.transaction_id, transactions.transaction_date, transactions.transaction_amount,
		transactions.application_date, transactions.approve_status, transactions.workflow_table_id, transactions.action_date, 
		transactions.narrative, transactions.document_number, transactions.payment_number, transactions.order_number,
		transactions.exchange_rate, transactions.payment_terms, transactions.job, transactions.details,
		(CASE WHEN transactions.journal_id is null THEN 'Not Posted' ELSE 'Posted' END) as posted,
		(CASE WHEN (transactions.transaction_type_id = 2) or (transactions.transaction_type_id = 8) or (transactions.transaction_type_id = 10) 
			THEN transactions.transaction_amount ELSE 0 END) as debit_amount,
		(CASE WHEN (transactions.transaction_type_id = 5) or (transactions.transaction_type_id = 7) or (transactions.transaction_type_id = 9) 
			THEN transactions.transaction_amount ELSE 0 END) as credit_amount
	FROM transactions INNER JOIN transaction_types ON transactions.transaction_type_id = transaction_types.transaction_type_id
		INNER JOIN vw_orgs ON transactions.org_id = vw_orgs.org_id
		INNER JOIN transaction_status ON transactions.transaction_status_id = transaction_status.transaction_status_id
		INNER JOIN currency ON transactions.currency_id = currency.currency_id
		LEFT JOIN vw_entitys ON transactions.entity_id = vw_entitys.entity_id
		LEFT JOIN departments ON transactions.department_id = departments.department_id;

CREATE VIEW vw_trx_sum AS
	SELECT transaction_details.transaction_id, 
		SUM(transaction_details.quantity * transaction_details.amount) as total_amount,
		SUM(transaction_details.quantity * transaction_details.tax_amount) as total_tax_amount,
		SUM(transaction_details.quantity * (transaction_details.amount + transaction_details.tax_amount)) as total_sale_amount
	FROM transaction_details
	GROUP BY transaction_details.transaction_id;

CREATE VIEW vw_transaction_details AS
	SELECT vw_transactions.department_id, vw_transactions.department_name, vw_transactions.transaction_type_id, 
		vw_transactions.transaction_type_name, vw_transactions.document_prefix, vw_transactions.transaction_id, 
		vw_transactions.transaction_date, vw_transactions.entity_id, vw_transactions.entity_name,
		vw_transactions.approve_status, vw_transactions.workflow_table_id,
		vw_transactions.currency_name, vw_transactions.exchange_rate,
		accounts.account_id, accounts.account_name, vw_items.item_id, vw_items.item_name,
		vw_items.tax_type_id, vw_items.tax_account_id, vw_items.tax_type_name, vw_items.tax_rate, vw_items.tax_inclusive,
		vw_items.sales_account_id, vw_items.purchase_account_id,
		stores.store_id, stores.store_name, 
		transaction_details.transaction_detail_id, transaction_details.org_id, transaction_details.quantity, 
		transaction_details.amount, transaction_details.tax_amount, transaction_details.narrative, transaction_details.details,
		COALESCE(transaction_details.narrative, vw_items.item_name) as item_description,
		(transaction_details.quantity * transaction_details.amount) as full_amount,
		(transaction_details.quantity * transaction_details.tax_amount) as full_tax_amount,
		(transaction_details.quantity * (transaction_details.amount + transaction_details.tax_amount)) as full_total_amount,
		(CASE WHEN (vw_transactions.transaction_type_id = 5) or (vw_transactions.transaction_type_id = 9) 
			THEN (transaction_details.quantity * transaction_details.tax_amount) ELSE 0 END) as tax_debit_amount,
		(CASE WHEN (vw_transactions.transaction_type_id = 2) or (vw_transactions.transaction_type_id = 10) 
			THEN (transaction_details.quantity * transaction_details.tax_amount) ELSE 0 END) as tax_credit_amount,
		(CASE WHEN (vw_transactions.transaction_type_id = 5) or (vw_transactions.transaction_type_id = 9) 
			THEN (transaction_details.quantity * transaction_details.amount) ELSE 0 END) as full_debit_amount,
		(CASE WHEN (vw_transactions.transaction_type_id = 2) or (vw_transactions.transaction_type_id = 10) 
			THEN (transaction_details.quantity * transaction_details.amount)  ELSE 0 END) as full_credit_amount,
		(CASE WHEN (vw_transactions.transaction_type_id = 2) or (vw_transactions.transaction_type_id = 9) 
			THEN vw_items.sales_account_id ELSE vw_items.purchase_account_id END) as trans_account_id
	FROM transaction_details INNER JOIN vw_transactions ON transaction_details.transaction_id = vw_transactions.transaction_id
		LEFT JOIN vw_items ON transaction_details.item_id = vw_items.item_id
		LEFT JOIN accounts ON transaction_details.account_id = accounts.account_id
		LEFT JOIN stores ON transaction_details.store_id = stores.store_id;

CREATE VIEW vw_day_ledgers AS
	SELECT currency.currency_id, currency.currency_name, departments.department_id, departments.department_name, 
		entitys.entity_id, entitys.entity_name, items.item_id, items.item_name,  orgs.org_id, orgs.org_name, 
		transaction_status.transaction_status_id, transaction_status.transaction_status_name, 
		transaction_types.transaction_type_id, transaction_types.transaction_type_name, 
		vw_bank_accounts.bank_id, vw_bank_accounts.bank_name, vw_bank_accounts.bank_branch_name, vw_bank_accounts.account_id as gl_bank_account_id, 
		vw_bank_accounts.bank_account_id, vw_bank_accounts.bank_account_name, vw_bank_accounts.bank_account_number, 
		stores.store_id, stores.store_name,

		day_ledgers.journal_id, day_ledgers.day_ledger_id, day_ledgers.exchange_rate, day_ledgers.day_ledger_date, 
		day_ledgers.day_ledger_quantity, day_ledgers.day_ledger_amount, day_ledgers.day_ledger_tax_amount, 
		day_ledgers.document_number, day_ledgers.payment_number, day_ledgers.order_number, 
		day_ledgers.payment_terms, day_ledgers.job, day_ledgers.application_date, day_ledgers.approve_status, 
		day_ledgers.workflow_table_id, day_ledgers.action_date, day_ledgers.narrative, day_ledgers.details

	FROM day_ledgers INNER JOIN currency ON day_ledgers.currency_id = currency.currency_id
		INNER JOIN departments ON day_ledgers.department_id = departments.department_id
		INNER JOIN entitys ON day_ledgers.entity_id = entitys.entity_id
		INNER JOIN items ON day_ledgers.item_id = items.item_id
		INNER JOIN orgs ON day_ledgers.org_id = orgs.org_id
		INNER JOIN transaction_status ON day_ledgers.transaction_status_id = transaction_status.transaction_status_id
		INNER JOIN transaction_types ON day_ledgers.transaction_type_id = transaction_types.transaction_type_id
		INNER JOIN vw_bank_accounts ON day_ledgers.bank_account_id = vw_bank_accounts.bank_account_id
		LEFT JOIN stores ON day_ledgers.store_id = stores.store_id;

CREATE OR REPLACE FUNCTION upd_transaction_details() RETURNS trigger AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_transaction_details BEFORE INSERT OR UPDATE ON transaction_details
    FOR EACH ROW EXECUTE PROCEDURE upd_transaction_details();

CREATE OR REPLACE FUNCTION af_upd_transaction_details() RETURNS trigger AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER af_upd_transaction_details AFTER INSERT OR UPDATE OR DELETE ON transaction_details
    FOR EACH ROW EXECUTE PROCEDURE af_upd_transaction_details();

CREATE OR REPLACE FUNCTION upd_transactions() RETURNS trigger AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER upd_transactions BEFORE INSERT OR UPDATE ON transactions
    FOR EACH ROW EXECUTE PROCEDURE upd_transactions();

CREATE OR REPLACE FUNCTION get_period(date) RETURNS INTEGER AS $$
	SELECT period_id FROM periods WHERE (start_date <= $1) AND (end_date >= $1); 
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_open_period(date) RETURNS INTEGER AS $$
	SELECT period_id FROM periods WHERE (start_date <= $1) AND (end_date >= $1)
		AND (opened = true) AND (closed = false); 
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION complete_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION copy_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION post_transaction(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_tx_link(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
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
$$ LANGUAGE plpgsql;


------------Hooks to approval trigger
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON transactions
    FOR EACH ROW EXECUTE PROCEDURE upd_action();


CREATE OR REPLACE FUNCTION get_budgeted(integer, date, integer) RETURNS real AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upd_approvals(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
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
$$ LANGUAGE plpgsql;

