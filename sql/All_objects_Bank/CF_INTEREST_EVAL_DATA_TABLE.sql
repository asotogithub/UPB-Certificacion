REM INSERTING into BANK.CF_INTEREST_EVAL
SET DEFINE OFF;
Insert into BANK.CF_INTEREST_EVAL (INT_EVAL_ID,CODE,INIT_EVAL_DAY,END_EVAL_DAY,AMOUNT,INT_PRIORITY,START_DATE,END_DATE,STATUS,START_USER_CODE,END_USER_CODE,TRAN_ID) values (1,'PAGO_INT_PORC',0,100,1,100,to_date('26-10-2017 00:16:51','DD-MM-RRRR HH24:MI:SS'),to_date('31-12-9999 00:00:00','DD-MM-RRRR HH24:MI:SS'),'A','BANK','BANK',-13);
Insert into BANK.CF_INTEREST_EVAL (INT_EVAL_ID,CODE,INIT_EVAL_DAY,END_EVAL_DAY,AMOUNT,INT_PRIORITY,START_DATE,END_DATE,STATUS,START_USER_CODE,END_USER_CODE,TRAN_ID) values (2,'PAGO_INT_PORC',101,500,1.5,100,to_date('26-10-2017 00:16:51','DD-MM-RRRR HH24:MI:SS'),to_date('31-12-9999 00:00:00','DD-MM-RRRR HH24:MI:SS'),'A','BANK','BANK',-13);
Insert into BANK.CF_INTEREST_EVAL (INT_EVAL_ID,CODE,INIT_EVAL_DAY,END_EVAL_DAY,AMOUNT,INT_PRIORITY,START_DATE,END_DATE,STATUS,START_USER_CODE,END_USER_CODE,TRAN_ID) values (3,'PAGO_INT_PORC',501,9999999999,2,100,to_date('26-10-2017 00:16:51','DD-MM-RRRR HH24:MI:SS'),to_date('31-12-9999 00:00:00','DD-MM-RRRR HH24:MI:SS'),'A','BANK','BANK',-13);
commit;