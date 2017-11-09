create or replace TRIGGER AUDIT_TR_ACCOUNT_UPD3
BEFORE INSERT OR UPDATE OR DELETE ON TR_ACCOUNT
FOR EACH ROW
DECLARE
    v_old_values HIS_AUDIT_TABLE.OLD_VALUES%TYPE :=''; 
    v_new_values HIS_AUDIT_TABLE.NEW_VALUES%TYPE :='';
    v_action     HIS_AUDIT_TABLE.ACTION%TYPE :='';
BEGIN

    IF INSERTING THEN
        v_action:='INSET';
        v_new_values:= 
                'ACCOUNT_ID: '||:NEW.ACCOUNT_ID
                ||', SALD_AMOUNT'||:NEW.SALD_AMOUNT
                ||', START_DATE'||:NEW.START_DATE
                ||', END_DATE'||:NEW.END_DATE
                ||', STATUS'||:NEW.STATUS
                ||', START_USER_CODE'||:NEW.START_USER_CODE
                ||', END_USER_CODE'||:NEW.END_USER_CODE ;

    ELSIF DELETING THEN
        v_action:='DELETE';
        v_old_values:= 
                'ACCOUNT_ID: '||:OLD.ACCOUNT_ID
                ||', SALD_AMOUNT'||:OLD.SALD_AMOUNT
                ||', START_DATE'||:OLD.START_DATE
                ||', END_DATE'||:OLD.END_DATE
                ||', STATUS'||:OLD.STATUS
                ||', START_USER_CODE'||:OLD.START_USER_CODE
                ||', END_USER_CODE'||:OLD.END_USER_CODE ;

    ELSIF UPDATING THEN
        v_action:='UPDATE';
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
    END IF;

    INSERT INTO his_audit_table (
    created_date,table_name,action,
    old_values,new_values,user_code) 
    VALUES (SYSDATE, 'TR_ACCOUNT', v_action, 
    v_old_values, v_new_values, USER);

END AUDIT_TR_ACCOUNT_UPD3;



