
CREATE TABLE project_locations (
	job_location_id			serial primary key,
	project_id				integer references projects,
	org_id					integer references orgs,
	job_location_name		varchar(50),
	details					text
);
CREATE INDEX project_locations_project_id ON project_locations (project_id);
CREATE INDEX project_locations_org_id ON project_locations (org_id);

CREATE TABLE shifts (
	shift_id				serial primary key,
	org_id					integer references orgs,	
	shift_name				varchar(50),
	shift_hours				integer not null default 8,
	details					text
);
CREATE INDEX shifts_org_id ON shifts (org_id);
INSERT INTO shifts(shift_id, org_id, shift_name, shift_hours) VALUES(1, 0, 'Day', 8);
INSERT INTO shifts(shift_id, org_id, shift_name, shift_hours) VALUES(2, 0, 'Night', 8);

CREATE TABLE shift_schedule (
	shift_schedule_id		serial primary key,
	shift_id				integer references shifts,
	entity_id				integer references entitys,
	org_id					integer references orgs,
	day_of_week				integer,
	time_in					time,
	time_out				time,
	details					text
);
CREATE INDEX shift_schedule_shift_id ON shift_schedule (shift_id);
CREATE INDEX shift_schedule_entity_id ON shift_schedule (entity_id);
CREATE INDEX shift_schedule_org_id ON shift_schedule (org_id);





