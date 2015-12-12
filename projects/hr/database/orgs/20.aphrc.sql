


ALTER TABLE objective_details ADD CHECK (ods_points >= 0 AND ods_points < 5);
ALTER TABLE objective_details ADD CHECK (ods_reviewer_points >= 0 AND ods_reviewer_points < 5);

ALTER TABLE evaluation_points ADD CHECK (points >= 0 AND points < 5);
ALTER TABLE evaluation_points ADD CHECK (reviewer_points >= 0 AND reviewer_points < 5);

CREATE OR REPLACE FUNCTION ins_evaluation_points() RETURNS trigger AS $$
BEGIN

		
	IF(NEW.grade is not null)THEN
		IF(NEW.grade <> 'A') AND  (NEW.grade <> 'S') AND (NEW.grade <> 'W') AND (NEW.grade <> 'NA') THEN
			RAISE EXCEPTION 'The grade must be A, S, W, NA';
		END IF;
	END IF;
	IF(NEW.reviewer_grade is not null)THEN
		IF(NEW.reviewer_grade <> 'A') AND  (NEW.reviewer_grade <> 'S') AND (NEW.reviewer_grade <> 'W') AND (NEW.reviewer_grade <> 'NA') THEN
			RAISE EXCEPTION 'The grade must be A, S, W, NA';
		END IF;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ins_evaluation_points AFTER INSERT OR UPDATE ON evaluation_points
    FOR EACH ROW EXECUTE PROCEDURE ins_evaluation_points();
    
    
CREATE OR REPLACE FUNCTION job_review_check(varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
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
$$ LANGUAGE plpgsql;

