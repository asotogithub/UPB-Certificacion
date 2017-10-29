--------------------------------------------------------
--  DDL for Package Body TX_TR_ERROR_LOG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "BANK"."TX_TR_ERROR_LOG" AS
/******************************************************************************
  Implements basic functions of persistent storage for table TR_ERROR_LOG
  Company         My Compay
  Module          Bank Account
  Date            17/10/2017 17:19:20
  Author          First Name Last Name.
  Version         1.1.0  
  Description     My Decription.
******************************************************************************/
 PROCEDURE SAVE_LOG( pi_tran_id      IN  BANK.TR_ERROR_LOG.tran_id%TYPE      ,
                     pi_error_msg    IN  BANK.TR_ERROR_LOG.error_message%TYPE,
                     pi_error_source IN  BANK.TR_ERROR_LOG.error_source%TYPE) IS

     PRAGMA AUTONOMOUS_TRANSACTION;
     BEGIN
        BANK.PS_TR_ERROR_LOG.LOG_INSERT(pi_tran_id,pi_error_msg, pi_error_source);
     COMMIT;
     END;

END TX_TR_ERROR_LOG;

/
