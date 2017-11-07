--------------------------------------------------------
--  DDL for Table TR_ACCOUNT
--------------------------------------------------------

  CREATE TABLE "BANK"."TR_ACCOUNT" 
   (	"ACCOUNT_ID" NUMBER(15,0), 
	"SALD_AMOUNT" NUMBER(15,2), 
	"START_DATE" DATE, 
	"END_DATE" DATE, 
	"STATUS" VARCHAR2(1 BYTE), 
	"START_USER_CODE" VARCHAR2(50 BYTE), 
	"END_USER_CODE" VARCHAR2(50 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "TBS_BANK_DATA" ;