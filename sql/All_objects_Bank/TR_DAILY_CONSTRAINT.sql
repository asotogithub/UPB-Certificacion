--------------------------------------------------------
--  Constraints for Table TR_DAILY
--------------------------------------------------------

  ALTER TABLE "BANK"."TR_DAILY" ADD CONSTRAINT "PK_DAILY_ID" PRIMARY KEY ("DAILY_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "TBS_BANK_IDX"  ENABLE;
  ALTER TABLE "BANK"."TR_DAILY" MODIFY ("ACCOUNT_ID_DESTIN" NOT NULL ENABLE);
  ALTER TABLE "BANK"."TR_DAILY" MODIFY ("ACCOUNT_ID_ORIGIN" NOT NULL ENABLE);
  ALTER TABLE "BANK"."TR_DAILY" MODIFY ("DAILY_ID" NOT NULL ENABLE);