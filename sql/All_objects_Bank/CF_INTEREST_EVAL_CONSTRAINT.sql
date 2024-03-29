--------------------------------------------------------
--  Constraints for Table CF_INTEREST_EVAL
--------------------------------------------------------

  ALTER TABLE "BANK"."CF_INTEREST_EVAL" ADD CONSTRAINT "PK_INTEREST_EVAL_ID" PRIMARY KEY ("INT_EVAL_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "TBS_BANK_IDX"  ENABLE;
  ALTER TABLE "BANK"."CF_INTEREST_EVAL" MODIFY ("CODE" NOT NULL ENABLE);
  ALTER TABLE "BANK"."CF_INTEREST_EVAL" MODIFY ("INT_EVAL_ID" NOT NULL ENABLE);
