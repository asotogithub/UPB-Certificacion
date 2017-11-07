--------------------------------------------------------
--  Constraints for Table TR_ACCOUNT
--------------------------------------------------------

  ALTER TABLE "BANK"."TR_ACCOUNT" ADD CONSTRAINT "PK_ACCOUNT_ID" PRIMARY KEY ("ACCOUNT_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "TBS_BANK_IDX"  ENABLE;
  ALTER TABLE "BANK"."TR_ACCOUNT" MODIFY ("ACCOUNT_ID" NOT NULL ENABLE);
