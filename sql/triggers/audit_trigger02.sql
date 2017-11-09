CREATE OR REPLACE TRIGGER AUDIT_TR_ACCOUNT_UPD2
BEFORE UPDATE ON TR_ACCOUNT
FOR EACH ROW
DECLARE
    v_old_values HIS_AUDIT_TABLE.OLD_VALUES%TYPE :=''; 
    v_new_values HIS_AUDIT_TABLE.NEW_VALUES%TYPE :='';
BEGIN
    
    IF :OLD.SALD_AMOUNT != :NEW.SALD_AMOUNT THEN
        v_old_values:= v_old_values ||
                       'SALD_AMOUNT'||:OLD.SALD_AMOUNT;
         v_new_values:= v_new_values ||
                       'SALD_AMOUNT'||:NEW.SALD_AMOUNT;              
    END IF;
    IF :OLD.STATUS != :NEW.STATUS THEN
        v_old_values:= v_old_values ||
                       ', STATUS'||:OLD.STATUS;
         v_new_values:= v_new_values ||
                       ', STATUS'||:NEW.STATUS;              
    END IF;

    INSERT INTO his_audit_table (
    created_date,table_name,action,
    old_values,new_values,user_code) 
    VALUES (SYSDATE, 'TR_ACCOUNT', 'UPDATE', 
    v_old_values, v_new_values, USER);

END AUDIT_TR_ACCOUNT_UPD2;




