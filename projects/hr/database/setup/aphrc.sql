CREATE OR REPLACE FUNCTION ins_employees() RETURNS trigger AS $$
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

			IF(NEW.employee_ID is null) THEN
				NEW.employee_ID := NEW.entity_id;
			END IF;

			v_first_password := first_password();

			v_user_name := lower(substring(NEW.first_name from 1 for 1) || NEW.surname);
			SELECT count(entity_id) INTO v_user_count
			FROM entitys
			WHERE (org_id = NEW.org_id) AND (user_name = v_user_name);
			IF(v_user_count > 0) THEN v_user_name := v_user_name || v_user_count::varchar; END IF;

			INSERT INTO entitys (entity_id, org_id, entity_type_id, entity_name, user_name, function_role, 
				first_password, entity_password, primary_email, primary_telephone)
			VALUES (NEW.entity_id, NEW.org_id, 1, 
				(NEW.Surname || ' ' || NEW.first_name || ' ' || COALESCE(NEW.middle_name, '')),
				v_user_name, 'staff',
				v_first_password, md5(v_first_password),
				v_user_name || '@aphrc.org', NEW.phone);
		END IF;

		v_use_type := 2;
		IF(NEW.gender = 'M')THEN v_use_type := 3; END IF;

		INSERT INTO employee_leave_types (entity_id, org_id, leave_type_id)
		SELECT NEW.entity_id, NEW.org_id, leave_type_id
		FROM leave_types
		WHERE (use_type = 1) OR (use_type = v_use_type);

		INSERT INTO sys_emailed (org_id, sys_email_id, table_id, table_name)
		VALUES (NEW.org_id, 1, NEW.entity_id, 'entitys');
	ELSIF (TG_OP = 'UPDATE') THEN
		UPDATE entitys  SET entity_name = (NEW.Surname || ' ' || NEW.First_name || ' ' || COALESCE(NEW.Middle_name, ''))
		WHERE entity_id = NEW.entity_id;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

INSERT INTO leave_types (leave_type_id, org_id, leave_type_name, allowed_leave_days, leave_days_span)
VALUES (1, 0, 'Prorated annual leave', 21, 7);
INSERT INTO leave_types (leave_type_id, org_id, leave_type_name, allowed_leave_days, leave_days_span, use_type)
VALUES (2, 0, 'Sick Leave', 7, 7, 1);
INSERT INTO leave_types (leave_type_id, org_id, leave_type_name, allowed_leave_days, leave_days_span, use_type)
VALUES (3, 0, 'Compasionate Leave', 7, 7, 1);
INSERT INTO leave_types (leave_type_id, org_id, leave_type_name, allowed_leave_days, leave_days_span, use_type)
VALUES (4, 0, 'Materniry Leave', 60, 60, 2);
INSERT INTO leave_types (leave_type_id, org_id, leave_type_name, allowed_leave_days, leave_days_span, use_type)
VALUES (5, 0, 'Peternity Leave', 10, 10, 3);
INSERT INTO leave_types (leave_type_id, org_id, leave_type_name, allowed_leave_days, leave_days_span, use_type)
VALUES (6, 0, 'Un Paid Leave', 7, 7, 1);
INSERT INTO leave_types (leave_type_id, org_id, leave_type_name, allowed_leave_days, leave_days_span, use_type)
VALUES (7, 0, 'special Leave 1', 7, 7, 0);
SELECT pg_catalog.setval('leave_types_leave_type_id_seq', 7, true);

INSERT INTO objective_types (objective_type_id, org_id, objective_type_name, details) VALUES (1, 0, 'Organisation Objectives', 'Organisation Objectives');
INSERT INTO objective_types (objective_type_id, org_id, objective_type_name, details) VALUES (2, 0, 'Departmental Objectives', 'Department based objectives');
INSERT INTO objective_types (objective_type_id, org_id, objective_type_name, details) VALUES (3, 0, 'Personal Growth', 'Personal Growth');
SELECT pg_catalog.setval('objective_types_objective_type_id_seq', 3, true);

INSERT INTO review_category (review_category_id, org_id, review_category_name, details) VALUES (2, 0, 'Core Competencies/Core Skills', 'In addition to your specific contributions to APHRC, equally important are competencies/core skills that contributed to your success in accomplishing your goals. Core skills are those skills and behaviors that all APHRC staff are expected to demonstrate in a fully effective manner or better.  These skills are not generally job specific but rather are considered important to the overall success of APHRCs mission; thus supervisors will rate staff on their ability in these respects during the appraisal process.  Use some of the descriptions listed next to the competencies as your guide to assess yourself.  Assessment should indicate whether this is an area of particular strength (S), satisfactory or average (A) or an area of weakness (W). Provide specific examples of your demonstrated capabilities in each area listed as strength. Specify NA wherever competencies are not applicable.  Please note that this data should be incorporated in the Career Development Planning section (Section VI).');
SELECT pg_catalog.setval('review_category_review_category_id_seq', 3, true);

INSERT INTO review_points (review_point_id, review_category_id, org_id, review_point_name, review_points, details) VALUES (4, 2, 0, 'Team/Interpersonal Skills', 4, 'Ability to get along with co-workers throughout the organization and to collaborate in a team approach to work.');
INSERT INTO review_points (review_point_id, review_category_id, org_id, review_point_name, review_points, details) VALUES (5, 2, 0, 'Communication', 4, 'Takes personal responsibility for open, clear and concise communication, both oral and written. And has ability to communicate effectively with diverse individuals and groups; adjusts style as necessary maintaining confidentiality as appropriate.');
INSERT INTO review_points (review_point_id, review_category_id, org_id, review_point_name, review_points, details) VALUES (1, 2, 0, 'Leadership', 4, 'Ability to supervise staff effectively and to create a cohesive work team. This includes demonstrated accountability for staff, proper delegation, monitoring and appraisal of staff performance.');
INSERT INTO review_points (review_point_id, review_category_id, org_id, review_point_name, review_points, details) VALUES (2, 2, 0, 'Initiative and Judgement', 4, 'Has a self starters attitude, discovers or creates new opportunities that will enhance organizational results, seeks and takes on new challenges with enthusiasm. This includes
assuming complete ownership and accountability for accomplishing tasks. It also includes the ability to anticipate and prepare for unforeseen problems or bottlenecks in the future and seeking help in removing them, wherever necessary.');
INSERT INTO review_points (review_point_id, review_category_id, org_id, review_point_name, review_points, details) VALUES (3, 2, 0, 'Problem Resolution', 4, 'Ability to present case, persuade others and identify mutually acceptable resolutions in situations of differing interests--includes use of informal networks for conflict resolution.                                                                                   
');
INSERT INTO review_points (review_point_id, review_category_id, org_id, review_point_name, review_points, details) VALUES (7, 2, 0, 'Use of Technical/ Functional Expertise', 4, 'Has ongoing mastery of discipline specific knowledge and skills and exhibits broad understanding and application of expertise to Centers advantage. Monitors field and shares new knowledge across groups. ');
INSERT INTO review_points (review_point_id, review_category_id, org_id, review_point_name, review_points, details) VALUES (8, 2, 0, 'Quality & Quantity of work', 4, 'Works efficiently and balances volume and quality of own work with the work of others focusing on detail, quality and accuracy in all outputs');
INSERT INTO review_points (review_point_id, review_category_id, org_id, review_point_name, review_points, details) VALUES (9, 2, 0, 'Pursues Excellence', 4, 'Works to build on professional skills and personal strengths
improving on weaknesses and contributes to improving APHRCs practices and effectiveness. Has the ability to persists with tasks until objectives are achieved
');
INSERT INTO review_points (review_point_id, review_category_id, org_id, review_point_name, review_points, details) VALUES (10, 2, 0, 'Adaptability', 4, 'Openness to change and new ways of working; ability to initiate change and to modify approach to different people and situations.');
INSERT INTO review_points (review_point_id, review_category_id, org_id, review_point_name, review_points, details) VALUES (6, 2, 0, 'Creativity and Innovativeness', 4, 'Generates imaginative solutions to address problems and introduces innovative approaches to work');
SELECT pg_catalog.setval('review_points_review_point_id_seq', 11, true);


