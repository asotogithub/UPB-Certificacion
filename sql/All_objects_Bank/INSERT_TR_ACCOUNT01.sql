--------------------------------------------------------
--  DDL for Procedure INSERT_TR_ACCOUNT01
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "BANK"."INSERT_TR_ACCOUNT01" (pi_num IN NUMBER) IS
BEGIN
  FOR i IN 1..pi_num LOOP
    po_last_account:= SEQ_ACCOUNT.NEXTVAL;
    INSERT INTO tr_account (
        account_id,
        sald_amount,
        start_date,
        end_date,
        status,
        start_user_code,
        end_user_code
    ) VALUES (
        po_last_account,
        00.00,
        SYSDATE,
        TO_DATE('31-12-9999','DD-MM-YYYY'),
        'A',
        'ASOTO',
        USER
    );
  END LOOP;
  
  --COMMIT;
END;

/
