CREATE TABLE pc_category (
	pc_category_id			serial primary key,
	org_id					integer references orgs,
	pc_category_name		varchar(50) not null unique,
	details					text
);
CREATE INDEX pc_category_org_id ON pc_category (org_id);

CREATE TABLE pc_items (
	pc_item_id				serial primary key,
	pc_category_id			integer references pc_category,	
	org_id					integer references orgs,
	pc_item_name			varchar(50) not null unique,
	default_price			float not null,
	default_units			integer not null,
	details					text
);
CREATE INDEX pc_items_pc_category_id ON pc_items (pc_category_id);
CREATE INDEX pc_items_org_id ON pc_items (org_id);

CREATE TABLE pc_types (
	pc_type_id				serial primary key,
	org_id					integer references orgs,
	pc_type_name			varchar(50) not null,
	details					text
);
CREATE INDEX pc_types_org_id ON pc_types (org_id);

CREATE TABLE pc_allocations (
	pc_allocation_id		serial primary key,
	period_id				integer references periods,
	department_id			integer references departments,
	entity_id				integer	references entitys,
	org_id					integer references orgs,
	narrative				varchar(320),
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	details					text,
	UNIQUE (period_id, department_id)
);
CREATE INDEX pc_allocations_period_id ON pc_allocations (period_id);
CREATE INDEX pc_allocations_department_id ON pc_allocations (department_id);
CREATE INDEX pc_allocations_entity_id ON pc_allocations (entity_id);
CREATE INDEX pc_allocations_org_id ON pc_allocations (org_id);

CREATE TABLE pc_budget (
	pc_budget_id			serial primary key,
	pc_allocation_id		integer references pc_allocations,
	pc_item_id				integer	references pc_items,
	org_id					integer references orgs,
	budget_units			integer not null,
	budget_price			float not null,
	details					text,
	UNIQUE (pc_allocation_id, pc_item_id)
);
CREATE INDEX pc_budget_pc_allocation_id ON pc_budget (pc_allocation_id);
CREATE INDEX pc_budget_pc_item_id ON pc_budget (pc_item_id);
CREATE INDEX pc_budget_org_id ON pc_budget (org_id);

CREATE TABLE pc_expenditure (
	pc_expenditure_id		serial primary key,
	pc_allocation_id		integer references pc_allocations,
	pc_item_id				integer	references pc_items,
	pc_type_id				integer	references pc_types,
	entity_id				integer	references entitys,
	org_id					integer references orgs,
	
	is_request				boolean default true not null,
	request_date			timestamp default current_timestamp,
	
	application_date		timestamp default now(),
	approve_status			varchar(16) default 'Draft' not null,
	workflow_table_id		integer,
	action_date				timestamp,
	
	units					integer not null,
	unit_price				float not null,
	receipt_number			varchar(50),
	exp_date				date,
	
	details					text
);
CREATE INDEX pc_expenditure_pc_allocation_id ON pc_expenditure (pc_allocation_id);
CREATE INDEX pc_expenditure_pc_item_id ON pc_expenditure (pc_item_id);
CREATE INDEX pc_expenditure_org_id ON pc_expenditure (org_id);

CREATE TABLE pc_banking (
	pc_banking_id			serial primary key,
	pc_allocation_id		integer references pc_allocations,
	org_id					integer references orgs,
	banking_date			date not null,
	amount					float not null,
	narrative				varchar(320) not null,
	details					text
);
CREATE INDEX pc_banking_pc_allocation_id ON pc_banking (pc_allocation_id);
CREATE INDEX pc_banking_org_id ON pc_banking (org_id);

CREATE VIEW vw_pc_items AS
	SELECT pc_category.pc_category_id, pc_category.pc_category_name, 
		pc_items.org_id, pc_items.pc_item_id, pc_items.pc_item_name, pc_items.default_price, 
		pc_items.default_units, pc_items.details,
		(pc_items.default_price * pc_items.default_units) as default_cost
	FROM pc_items INNER JOIN pc_category ON pc_items.pc_category_id = pc_category.pc_category_id;

CREATE VIEW vw_pc_allocations AS
	SELECT vw_periods.fiscal_year_id, vw_periods.fiscal_year_start, vw_periods.fiscal_year_end,
		vw_periods.year_opened, vw_periods.year_closed,
		vw_periods.period_id, vw_periods.start_date, vw_periods.end_date, vw_periods.opened, vw_periods.closed, 
		vw_periods.month_id, vw_periods.period_year, vw_periods.period_month, vw_periods.quarter, vw_periods.semister,
		departments.department_id, departments.department_name, 
		pc_allocations.org_id, pc_allocations.pc_allocation_id, pc_allocations.narrative, 
		pc_allocations.approve_status, pc_allocations.details, 
		(SELECT sum(pc_budget.budget_units * pc_budget.budget_price) FROM pc_budget 
			WHERE (pc_budget.pc_allocation_id = pc_allocations.pc_allocation_id)) as sum_budget,
		(SELECT sum(pc_expenditure.units * pc_expenditure.unit_price) FROM pc_expenditure 
			WHERE (pc_expenditure.pc_allocation_id = pc_allocations.pc_allocation_id)) as sum_expenditure,
		(SELECT sum(pc_banking.amount) FROM pc_banking
			WHERE (pc_banking.pc_allocation_id = pc_allocations.pc_allocation_id)) as sum_banking
	FROM pc_allocations INNER JOIN vw_periods ON pc_allocations.period_id = vw_periods.period_id
		INNER JOIN departments ON pc_allocations.department_id = departments.department_id;

CREATE VIEW vw_pc_budget AS
	SELECT vw_pc_allocations.fiscal_year_id, vw_pc_allocations.fiscal_year_start, 
		vw_pc_allocations.fiscal_year_end, vw_pc_allocations.year_opened, 
		vw_pc_allocations.year_closed, vw_pc_allocations.period_id, vw_pc_allocations.start_date, 
		vw_pc_allocations.end_date, vw_pc_allocations.opened, vw_pc_allocations.closed, 
		vw_pc_allocations.month_id, vw_pc_allocations.period_year, vw_pc_allocations.period_month, 
		vw_pc_allocations.quarter, vw_pc_allocations.semister,
		vw_pc_allocations.department_id, vw_pc_allocations.department_name,
		vw_pc_allocations.pc_allocation_id, vw_pc_allocations.narrative, vw_pc_allocations.approve_status,
		vw_pc_items.pc_category_id, vw_pc_items.pc_category_name, 
		vw_pc_items.pc_item_id, vw_pc_items.pc_item_name, vw_pc_items.default_price, 
		vw_pc_items.default_units, vw_pc_items.default_cost,
		pc_budget.org_id, pc_budget.pc_budget_id, pc_budget.budget_units, pc_budget.budget_price, 
		(pc_budget.budget_units * pc_budget.budget_price) as budget_cost, pc_budget.details
	FROM pc_budget INNER JOIN vw_pc_allocations ON pc_budget.pc_allocation_id = vw_pc_allocations.pc_allocation_id
		INNER JOIN vw_pc_items ON pc_budget.pc_item_id = vw_pc_items.pc_item_id;

CREATE VIEW vw_pc_expenditure AS
	SELECT vw_pc_allocations.fiscal_year_id, vw_pc_allocations.fiscal_year_start, 
		vw_pc_allocations.fiscal_year_end, vw_pc_allocations.year_opened, 
		vw_pc_allocations.year_closed, vw_pc_allocations.period_id, vw_pc_allocations.start_date, 
		vw_pc_allocations.end_date, vw_pc_allocations.opened, vw_pc_allocations.closed, 
		vw_pc_allocations.month_id, vw_pc_allocations.period_year, vw_pc_allocations.period_month, 
		vw_pc_allocations.quarter, vw_pc_allocations.semister,
		vw_pc_allocations.department_id, vw_pc_allocations.department_name,
		vw_pc_allocations.pc_allocation_id, vw_pc_allocations.narrative, 
		vw_pc_items.pc_category_id, vw_pc_items.pc_category_name, 
		vw_pc_items.pc_item_id, vw_pc_items.pc_item_name, vw_pc_items.default_price, 
		vw_pc_items.default_units, vw_pc_items.default_cost,
		pc_types.pc_type_id, pc_types.pc_type_name,
		entitys.entity_id, entitys.entity_name,
		pc_expenditure.org_id, pc_expenditure.pc_expenditure_id, pc_expenditure.units, 
		pc_expenditure.unit_price, pc_expenditure.receipt_number, pc_expenditure.exp_date, 
		pc_expenditure.is_request, pc_expenditure.request_date,
		(pc_expenditure.units * pc_expenditure.unit_price) as items_cost, 
		pc_expenditure.application_date, pc_expenditure.approve_status,
		pc_expenditure.workflow_table_id, pc_expenditure.action_date,
		pc_expenditure.details
	FROM pc_expenditure INNER JOIN vw_pc_allocations ON pc_expenditure.pc_allocation_id = vw_pc_allocations.pc_allocation_id
		INNER JOIN vw_pc_items ON pc_expenditure.pc_item_id = vw_pc_items.pc_item_id
		INNER JOIN pc_types ON pc_expenditure.pc_type_id = pc_types.pc_type_id
		LEFT JOIN entitys ON pc_expenditure.entity_id = entitys.entity_id;

CREATE VIEW vws_pc_expenditure AS
	SELECT a.period_id, a.period_year, a.period_month, a.department_id, a.department_name,
		a.pc_allocation_id, a.pc_category_id, a.pc_category_name, a.pc_item_id, a.pc_item_name, 
		a.sum_units, a.avg_unit_price, a.sum_items_cost,
		pc_budget.budget_units, pc_budget.budget_price, 
		(pc_budget.budget_units * pc_budget.budget_price) as budget_cost,
		(COALESCE(pc_budget.budget_units, 0) - a.sum_units) as unit_diff,
		(COALESCE(pc_budget.budget_units * pc_budget.budget_price, 0) - a.sum_items_cost) as budget_diff
	FROM (SELECT period_id, period_year, period_month, department_id, department_name,
		pc_allocation_id, pc_category_id, pc_category_name, pc_item_id, pc_item_name, 
		sum(units) as sum_units, avg(unit_price) as avg_unit_price, 
		sum(units * unit_price) as sum_items_cost
	FROM vw_pc_expenditure 
	GROUP BY period_id, period_year, period_month, department_id, department_name,
		pc_allocation_id, pc_category_id, pc_category_name, pc_item_id, pc_item_name) as a
	LEFT JOIN pc_budget ON (a.pc_allocation_id = pc_budget.pc_allocation_id)
		AND (a.pc_item_id = pc_budget.pc_item_id);

CREATE VIEW vws_pc_budget_diff AS
	(SELECT a.period_id, a.period_year, a.period_month, a.department_id, a.department_name,
		a.pc_allocation_id, a.pc_category_id, a.pc_category_name, a.pc_item_id, a.pc_item_name, 
		a.sum_units, a.avg_unit_price, a.sum_items_cost,
		a.budget_units, a.budget_price, a.budget_cost,
		a.unit_diff, a.budget_diff
	FROM vws_pc_expenditure as a)
	UNION
	(SELECT a.period_id, a.period_year, a.period_month, a.department_id, a.department_name,
		a.pc_allocation_id, a.pc_category_id, a.pc_category_name, a.pc_item_id, a.pc_item_name, 
		0, 0, 0,
		a.budget_units, a.budget_price, a.budget_cost,
		a.budget_units, a.budget_cost
	FROM vw_pc_budget as a LEFT JOIN pc_expenditure ON (a.pc_allocation_id = pc_expenditure.pc_allocation_id)
		AND (a.pc_item_id = pc_expenditure.pc_item_id)
	WHERE (pc_expenditure.pc_item_id is null));

CREATE OR REPLACE FUNCTION ins_budget() RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;



------------Hooks to approval trigger
CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON pc_allocations
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

CREATE TRIGGER upd_action BEFORE INSERT OR UPDATE ON pc_expenditure
    FOR EACH ROW EXECUTE PROCEDURE upd_action();

    