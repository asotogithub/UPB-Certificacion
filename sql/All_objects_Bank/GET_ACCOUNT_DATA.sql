--------------------------------------------------------
--  DDL for Procedure GET_ACCOUNT_DATA
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "BANK"."GET_ACCOUNT_DATA" (i_acc_id TR_ACCOUNT.ACCOUNT_ID%TYPE) IS
 
 CURSOR get_data (cp_id TR_ACCOUNT.ACCOUNT_ID%TYPE) IS
    SELECT * 
      FROM TR_ACCOUNT
     WHERE STATUS = 'A'
        AND account_id = cp_id;

 rec_account TR_ACCOUNT%ROWTYPE;  
 v_sw BOOLEAN := FALSE;
BEGIN

  OPEN get_data(i_acc_id);
  FETCH get_data INTO rec_account;
    IF get_data%FOUND THEN
        v_sw:= TRUE;
    END IF;
  CLOSE get_data;
   IF v_sw THEN 
      DBMS_OUTPUT.PUT_LINE('v_sum_total: '||rec_account.ACCOUNT_ID); 
   ELSE
      DBMS_OUTPUT.PUT_LINE('NO EXISTE!! '); 
   END IF;
END;

/
