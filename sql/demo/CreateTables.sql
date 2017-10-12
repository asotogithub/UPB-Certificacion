CREATE TABLE BANK.TR_ACCOUNT
( ACCOUNT_ID      NUMBER(15)     NOT NULL,
  SALD_AMOUNT	  NUMBER(15,2),	
  START_DATE      DATE,
  END_DATE        DATE,
  STATUS          VARCHAR2(1)
  )
TABLESPACE TBS_BANK_DAT ;

alter table BANK.TR_ACCOUNT
  add constraint PK_ACCOUNT_ID primary key (ACCOUNT_ID)
  using index 
  tablespace TBS_BANK_IDX;
  
CREATE TABLE BANK.TR_DAILY
(
  DAILY_ID   		 NUMBER(15)  NOT NULL,
  ACCOUNT_ID 		 NUMBER(15)  NOT NULL,
  AMOUNT	 		 NUMBER(15,2)     ,	
  TYPE_TRANSACTION 	 VARCHAR2(50),   --Tipo T= Traspaso, D debito  H haber
  START_TRAN_DATE    DATE,
  START_USER_CODE    VARCHAR2(50),
  END_TRAN_DATE      DATE,
  END_USER_CODE      VARCHAR2(50),
  TRAN_ID            NUMBER(15)
)
TABLESPACE TBS_BANK_DAT;
alter table BANK.TR_DAILY
  add constraint PK_DAILY_ID primary key (DAILY_ID)
  using index 
  tablespace TBS_BANK_IDX;

  
  --sequences
  
create sequence BANK.SEQ_ACCOUNT
minvalue 1000000
maxvalue 999999999999999
start with 1000000
increment by 1
cache 20
order;

create sequence BANK.SEQ_DAILY
minvalue 1
maxvalue 999999999999999
start with 1
increment by 1
cache 20
order;
  
create sequence BANK.SEQ_TRAN_ID
minvalue 1
maxvalue 999999999999999
start with 1
increment by 1
cache 20
order;
  
  