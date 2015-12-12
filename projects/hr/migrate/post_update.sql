UPDATE entity_subscriptions SET subscription_level_id = 0;
UPDATE employees SET pay_group_id = 0 WHERE pay_group_id is null;;

CREATE TRIGGER ins_Taxes AFTER INSERT ON Employees
    FOR EACH ROW EXECUTE PROCEDURE ins_Taxes();

CREATE TRIGGER ins_bf_Periods BEFORE INSERT ON Periods
    FOR EACH ROW EXECUTE PROCEDURE ins_bf_Periods();

CREATE TRIGGER ins_Periods AFTER INSERT ON Periods
    FOR EACH ROW EXECUTE PROCEDURE ins_Periods();

CREATE TRIGGER ins_Period_Tax_Types AFTER INSERT ON Period_Tax_Types
    FOR EACH ROW EXECUTE PROCEDURE ins_Period_Tax_Types();

CREATE TRIGGER ins_payroll_periods AFTER INSERT ON periods
  FOR EACH ROW EXECUTE PROCEDURE ins_payroll_periods();

CREATE TRIGGER ins_Employee_Month AFTER INSERT ON Employee_Month
    FOR EACH ROW EXECUTE PROCEDURE ins_Employee_Month();

CREATE TRIGGER ins_entitys AFTER INSERT ON entitys
  FOR EACH ROW EXECUTE PROCEDURE ins_entitys();
  


