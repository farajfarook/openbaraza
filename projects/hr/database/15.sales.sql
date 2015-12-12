CREATE TABLE leads (
	lead_id					serial primary key,
	entity_id				integer references entitys,
	sale_person_id			integer references entitys,
	org_id					integer references orgs,
	contact_date			date,
	details					text
);
CREATE INDEX leads_entity_id ON leads (entity_id);
CREATE INDEX leads_sale_person_id ON leads (sale_person_id);
CREATE INDEX leads_org_id ON leads (org_id);

CREATE TABLE lead_items (
	lead_item				serial primary key,
	entity_id				integer references entitys,
	item_id					integer references items,
	org_id					integer references orgs,
	pitch_date				date,
	units					integer,
	price					real,
	narrative				varchar(320),
	details					text
);
CREATE INDEX lead_items_entity_id ON lead_items (entity_id);
CREATE INDEX lead_items_item_id ON lead_items (item_id);
CREATE INDEX lead_items_org_id ON lead_items (org_id);


