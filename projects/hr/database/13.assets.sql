CREATE TABLE asset_types (
	asset_type_id			serial primary key,
	org_id					integer references orgs,
	asset_type_name			varchar(50) not null,
	depreciation_rate		real default 10 not null,
	asset_account			integer references accounts,
	depreciation_account	integer references accounts,
	accumulated_account		integer references accounts,
	valuation_account		integer references accounts,
	disposal_account		integer references accounts,
	Details					text
);
CREATE INDEX asset_types_asset_account ON asset_types (asset_account);
CREATE INDEX asset_types_depreciation_account ON asset_types (depreciation_account);
CREATE INDEX asset_types_accumulated_account ON asset_types (accumulated_account);
CREATE INDEX asset_types_valuation_account ON asset_types (valuation_account);
CREATE INDEX asset_types_disposal_account ON asset_types (disposal_account);

CREATE TABLE assets (
	asset_id				serial primary key,
	org_id					integer references orgs,
	asset_type_id			integer references asset_types,
	item_id					integer references items,
	asset_name				varchar(50),
	asset_serial			varchar(50),
	purchase_date			date not null,
	purchase_value			real not null,
	disposal_amount			real,
	disposal_date			date,
	disposal_posting		boolean default false not null,
	lost					boolean default false not null,
	stolen					boolean default false not null,
	tag_number				varchar(50),
	asset_location			varchar(50),
	asset_condition			varchar(50),
	asset_acquisition		varchar(50),
	details					text
);
CREATE INDEX assets_asset_type_id ON assets (asset_type_id);
CREATE INDEX assets_item_id ON assets (item_id);

CREATE TABLE asset_valuations (
	asset_valuation_id		serial primary key,
	org_id					integer references orgs,
	asset_id				integer references assets,
	valuation_year			integer,
	asset_value				real default 0 not null,
	value_change			real default 0 not null,
	posted					boolean default false not null,
	details					text,
	unique(asset_id, valuation_year)
);
CREATE INDEX asset_valuations_asset_id ON asset_valuations (asset_id);

CREATE TABLE amortisation (
	amortisation_id			serial primary key,
	org_id					integer references orgs,
	asset_id				integer references assets,
	amortisation_year		integer,
	asset_value				real,
	amount					real,
	posted					boolean default false not null,
	details					text
);
CREATE INDEX amortisation_asset_id ON amortisation (asset_id);

CREATE TABLE asset_movement (
	asset_movement_id		serial primary key,
	org_id					integer references orgs,
	asset_id				integer references assets,
	department_id			integer references departments,
	date_aquired			date,
	date_left				date,
	details					text
);
CREATE INDEX asset_movement_asset_id ON asset_movement (asset_id);
CREATE INDEX asset_movement_department_id ON asset_movement (department_id);

CREATE VIEW vw_assets AS
	SELECT asset_types.asset_type_id, asset_types.asset_type_name, items.item_id, items.item_name, 
		assets.asset_id, assets.org_id, assets.asset_name, assets.asset_serial, assets.purchase_date, assets.purchase_value, 
		assets.disposal_amount, assets.disposal_date, assets.disposal_posting, assets.lost, assets.stolen, 
		assets.tag_number, assets.asset_location, assets.asset_condition, assets.asset_acquisition, assets.details
	FROM assets INNER JOIN asset_types ON assets.asset_type_id = asset_types.asset_type_id
		INNER JOIN items ON assets.item_id = items.item_id;

CREATE VIEW vw_asset_movement AS
	SELECT departments.department_id, departments.department_name, asset_movement.asset_movement_id, 
		asset_movement.asset_id, asset_movement.org_id, asset_movement.date_aquired, asset_movement.date_left, 
		asset_movement.details
	FROM asset_movement	INNER JOIN departments ON asset_movement.department_id = departments.department_id;

CREATE OR REPLACE FUNCTION get_asset_value(assetid integer, valueYear integer) RETURNS real AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION amortise(assetid integer) RETURNS varchar(50) AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION amortise_post(yearid integer) RETURNS varchar(50) AS $$
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
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ins_asset_valuations() RETURNS trigger AS $$
BEGIN
	NEW.value_change = NEW.asset_value - get_asset_value(NEW.asset_id, NEW.valuation_year);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_asset_valuations BEFORE INSERT OR UPDATE ON asset_valuations
    FOR EACH ROW EXECUTE PROCEDURE ins_asset_valuations();
