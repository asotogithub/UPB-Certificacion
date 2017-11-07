--------------------------------------------------------
--  DDL for Procedure GET_SUM_TOTAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "BANK"."GET_SUM_TOTAL" IS
  v_sum_total NUMBER;  
BEGIN
    SELECT SUM(SALD_AMOUNT) INTO v_sum_total 
      FROM TR_ACCOUNT
     WHERE STATUS = 'A';
   DBMS_OUTPUT.PUT_LINE('v_sum_total: '||v_sum_total);  
END;

/
