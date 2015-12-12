
ALTER TABLE orgs ADD employee_limit integer default 5 not null;
ALTER TABLE orgs ADD transaction_limit integer default 100 not null;


CREATE TABLE industry (
	industry_id				serial primary key,
	org_id					integer references orgs,
	industry_name			varchar(50) not null,
	details					text
);
CREATE INDEX industry_org_id ON industry(org_id);

CREATE TABLE subscriptions (
	subscription_id			serial primary key,
	industry_id				integer references industry,
	entity_id				integer references entitys,
	account_manager_id		integer references entitys,
	org_id					integer references orgs,

	business_name			varchar(50),
	business_address		varchar(100),
	city					varchar(30),
	state					varchar(50),
	country_id				char(2) references sys_countrys,
	number_of_employees		integer,
	telephone				varchar(50),
	website					varchar(120),
	
	primary_contact			varchar(120),
	job_title				varchar(120),
	primary_email			varchar(120),
	confirm_email			varchar(120),
	
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	details					text
);
CREATE INDEX subscriptions_industry_id ON subscriptions(industry_id);
CREATE INDEX subscriptions_entity_id ON subscriptions(entity_id);
CREATE INDEX subscriptions_account_manager_id ON subscriptions(account_manager_id);
CREATE INDEX subscriptions_country_id ON subscriptions(country_id);
CREATE INDEX subscriptions_org_id ON subscriptions(org_id);

CREATE TABLE products (
	product_id				serial primary key,
	org_id					integer references orgs,
	product_name			varchar(50),
	is_montly_bill			boolean default false not null,
	montly_cost				real default 0 not null,
	is_annual_bill			boolean default true not null,
	annual_cost				real default 0 not null,
	
	transaction_limit		integer not null,
	
	details					text
);
CREATE INDEX products_org_id ON products(org_id);

INSERT INTO products (org_id, product_name, transaction_limit) VALUES (0, 'HCM Hosting', 5);

CREATE TABLE productions (
	production_id			serial primary key,
	subscription_id			integer references subscriptions,
	product_id				integer references products,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	
	approve_status			varchar(16) default 'draft' not null,
	workflow_table_id		integer,
	application_date		timestamp default now(),
	action_date				timestamp,
	
	montly_billing			boolean default false not null,
	is_active				boolean default false not null,
	
	details					text
);
CREATE INDEX productions_subscription_id ON productions(subscription_id);
CREATE INDEX productions_product_id ON productions(product_id);
CREATE INDEX productions_org_id ON productions(org_id);

CREATE VIEW vw_subscriptions AS
	SELECT industry.industry_id, industry.industry_name, sys_countrys.sys_country_id, sys_countrys.sys_country_name,
		entitys.entity_id, entitys.entity_name, 
		account_manager.entity_id as account_manager_id, account_manager.entity_name as account_manager_name,
		orgs.org_id, orgs.org_name, 
		
		subscriptions.subscription_id, subscriptions.business_name, 
		subscriptions.business_address, subscriptions.city, subscriptions.state, subscriptions.country_id, 
		subscriptions.number_of_employees, subscriptions.telephone, subscriptions.website, 
		subscriptions.primary_contact, subscriptions.job_title, subscriptions.primary_email, 
		subscriptions.approve_status, subscriptions.workflow_table_id, subscriptions.application_date, subscriptions.action_date, 
		subscriptions.details
	FROM subscriptions INNER JOIN industry ON subscriptions.industry_id = industry.industry_id
		INNER JOIN sys_countrys ON subscriptions.country_id = sys_countrys.sys_country_id
		LEFT JOIN entitys ON subscriptions.entity_id = entitys.entity_id
		LEFT JOIN entitys as account_manager ON subscriptions.account_manager_id = account_manager.entity_id
		LEFT JOIN orgs ON subscriptions.org_id = orgs.org_id;	
		
CREATE VIEW vw_productions AS
	SELECT orgs.org_id, orgs.org_name, 
		products.product_id, products.product_name, products.transaction_limit,
		subscriptions.subscription_id, subscriptions.business_name, 
		
		productions.production_id, productions.approve_status, productions.workflow_table_id, productions.application_date, 
		productions.action_date, productions.montly_billing, productions.is_active, 
		productions.details
	FROM productions INNER JOIN orgs ON productions.org_id = orgs.org_id
		INNER JOIN products ON productions.product_id = products.product_id
		INNER JOIN subscriptions ON productions.subscription_id = subscriptions.subscription_id;

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON subscriptions
    FOR EACH ROW EXECUTE PROCEDURE upd_action();
    
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON productions
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE OR REPLACE FUNCTION ins_subscriptions() RETURNS trigger AS $$
DECLARE
	v_org_id		integer;
	v_org_suffix    char(2);
	rec 			RECORD;
BEGIN
	IF (TG_OP = 'INSERT') THEN
		
		NEW.entity_id := nextval('entitys_entity_id_seq');
		INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, User_name, primary_email,  function_role)
		VALUES (NEW.entity_id, 0, 5, NEW.primary_contact, lower(trim(NEW.primary_email)), lower(trim(NEW.primary_email)), 'subscription');
		
		INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name)
		VALUES (4, 0, NEW.entity_id, 'subscription');
		
		NEW.approve_status := 'Completed';
		
	ELSIF(NEW.approve_status = 'Approved')THEN

		NEW.org_id := nextval('orgs_org_id_seq');
		INSERT INTO orgs(org_id, currency_id, org_name, org_sufix)
		VALUES(NEW.org_id, 2, NEW.business_name, NEW.org_id);
		
		UPDATE entitys SET org_id = NEW.org_id, function_role='subscription,admin,staff,finance'
		WHERE entity_id = NEW.entity_id;

		INSERT INTO sys_emailed (sys_email_id, org_id, table_id, table_name)
		VALUES (5, NEW.org_id, NEW.entity_id, 'subscription');
			
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_subscriptions BEFORE INSERT OR UPDATE ON subscriptions
    FOR EACH ROW EXECUTE PROCEDURE ins_subscriptions();
 

CREATE OR REPLACE FUNCTION ins_employee_limit() RETURNS trigger AS $$
DECLARE
	v_employee_count	integer;
	v_employee_limit	integer;
BEGIN

	SELECT count(entity_id) INTO v_employee_count
	FROM employees
	WHERE (org_id = NEW.org_id);
	
	SELECT employee_limit INTO v_employee_limit
	FROM orgs
	WHERE (org_id = NEW.org_id);
	
	IF(v_employee_count > v_employee_limit)THEN
		RAISE EXCEPTION 'You have reached the maximum staff limit, request for a quite for more';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_employee_limit BEFORE INSERT ON employees
    FOR EACH ROW EXECUTE PROCEDURE ins_employee_limit();

	
CREATE OR REPLACE FUNCTION ins_transactions_limit() RETURNS trigger AS $$
DECLARE
	v_transaction_count	integer;
	v_transaction_limit	integer;
BEGIN

	SELECT count(transaction_id) INTO v_transaction_count
	FROM transactions
	WHERE (org_id = NEW.org_id);
	
	SELECT transaction_limit INTO v_transaction_limit
	FROM orgs
	WHERE (org_id = NEW.org_id);
	
	IF(v_transaction_count > v_transaction_limit)THEN
		RAISE EXCEPTION 'You have reached the maximum transaction limit, request for a quite for more';
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_transactions_limit BEFORE INSERT ON transactions
    FOR EACH ROW EXECUTE PROCEDURE ins_transactions_limit();
