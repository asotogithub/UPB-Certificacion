--------------------------------------------------------
--  DDL for Package BL_PROCESS_ACCOUNT_SVA
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "BANK"."BL_PROCESS_ACCOUNT_SVA" AS

    PROCEDURE ACCOUNT_INIT( pi_sald_amount         IN BANK.TR_ACCOUNT.SALD_AMOUNT%TYPE,
                            pi_tran_id            IN  BANK.TR_DAILY.TRAN_ID%TYPE,
                            po_ok                  OUT VARCHAR2, 
                            po_error_message       OUT BANK.TR_ERROR_LOG.ERROR_MESSAGE%TYPE);

    PROCEDURE ACCOUNT_TRANS_MONEY (	pi_amount     	        IN BANK.TR_ACCOUNT.SALD_AMOUNT%TYPE,
                                    pi_account_id_origin    IN BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE,
                                    pi_account_id_destin    IN BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE,
                                    pi_type_transaction		IN BANK.TR_DAILY.TYPE_TRANSACTION%TYPE,
                                    pi_tran_id              IN BANK.TR_DAILY.TRAN_ID%TYPE,
                                    po_ok               	OUT VARCHAR2,
                                    po_error_message     	OUT BANK.TR_ERROR_LOG.error_message%TYPE );

END BL_PROCESS_ACCOUNT_SVA;

/
