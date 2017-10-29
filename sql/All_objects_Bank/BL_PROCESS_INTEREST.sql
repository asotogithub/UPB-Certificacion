--------------------------------------------------------
--  DDL for Package BL_PROCESS_INTEREST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "BANK"."BL_PROCESS_INTEREST" AS

   
   
   
   PROCEDURE PAY_INTEREST (pi_account_id    IN BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE,
                           pi_date          IN DATE,
                           pi_tran_id       IN NUMBER,
                           po_ok            OUT VARCHAR2,
                           po_error_message OUT TR_ERROR_LOG.ERROR_MESSAGE%TYPE);

   PROCEDURE PAY_INTEREST (pi_date          IN DATE,
                           pi_tran_id       IN NUMBER,
                           po_ok            OUT VARCHAR2,
                           po_error_message OUT TR_ERROR_LOG.ERROR_MESSAGE%TYPE);

    PROCEDURE PAY_INTEREST (pi_date IN DATE);
   
   PROCEDURE INTEREST_EVAL_DAYS (pi_account_id IN BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE,
                                 pi_date        IN DATE,
                                 po_type_evaluation OUT CF_INTERESTS.TYPE_EVALUATION%TYPE,
                                 po_type_interest OUT CF_INTERESTS.TYPE_INTEREST%TYPE,
                                 po_amount OUT CF_INTEREST_EVAL.AMOUNT%TYPE,
                                 po_sald_amout OUT TR_ACCOUNT.SALD_AMOUNT%TYPE,
                                 po_ok OUT VARCHAR2,
                                 po_error_message OUT TR_ERROR_LOG.ERROR_MESSAGE%TYPE
   ) ;
   
   PROCEDURE CALC_AMOUNT ( pi_type_evaluation IN CF_INTERESTS.TYPE_EVALUATION%TYPE,
                           pi_amount IN CF_INTEREST_EVAL.AMOUNT%TYPE,
                           pi_sald_amout IN TR_ACCOUNT.SALD_AMOUNT%TYPE,
                           po_amout_calc OUT TR_ACCOUNT.SALD_AMOUNT%TYPE,
                           po_ok OUT VARCHAR2,
                           po_error_message OUT TR_ERROR_LOG.ERROR_MESSAGE%TYPE
   
   );


END BL_PROCESS_INTEREST;

/
