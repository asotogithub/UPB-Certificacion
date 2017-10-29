--------------------------------------------------------
--  DDL for Package PS_TR_DAILY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "BANK"."PS_TR_DAILY" AS
/******************************************************************************
  Implements basic functions of persistent storage for table TR_DAILY
  Company         My Compay
  Module          Bank Account
  Date            17/10/2017 17:19:20
  Author          First Name Last Name.
  Version         1.1.0  
  Description     My Decription.
******************************************************************************/

 PROCEDURE DAILY_INSERT( pi_account_origin       IN  BANK.TR_DAILY.ACCOUNT_ID_ORIGIN%TYPE      ,
                           pi_account_destin     IN  BANK.TR_DAILY.ACCOUNT_ID_DESTIN%TYPE      ,
                           pi_ammount            IN  BANK.TR_DAILY.AMOUNT%TYPE      ,
                           pi_type_transaction   IN  BANK.TR_DAILY.TYPE_TRANSACTION%TYPE      ,
                           pi_start_tran_date    IN  BANK.TR_DAILY.START_TRAN_DATE%TYPE,
                           pi_end_tran_date      IN  BANK.TR_DAILY.END_TRAN_DATE%TYPE,
                           pi_start_user_code    IN  BANK.TR_DAILY.START_USER_CODE%TYPE,
                           pi_end_user_code      IN  BANK.TR_DAILY.END_USER_CODE%TYPE,
                           pi_tran_id            IN  BANK.TR_DAILY.TRAN_ID%TYPE,
                           po_daily_id           OUT BANK.TR_DAILY.DAILY_ID%TYPE,
                           po_ok                 OUT VARCHAR2,
                           po_error_message      OUT BANK.TR_ERROR_LOG.error_message%TYPE);
END PS_TR_DAILY;

/
