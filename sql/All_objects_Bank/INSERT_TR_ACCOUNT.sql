--------------------------------------------------------
--  DDL for Procedure INSERT_TR_ACCOUNT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "BANK"."INSERT_TR_ACCOUNT" IS
  v_num NUMBER := 10000;
BEGIN
  FOR i IN 1..v_num LOOP
    INSERT INTO tr_account (
        account_id,
        sald_amount,
        start_date,
        end_date,
        status,
        start_user_code,
        end_user_code
    ) VALUES (
        SEQ_ACCOUNT.NEXTVAL,
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
