--------------------------------------------------------
--  DDL for Package TX_TR_ACCOUNT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "BANK"."TX_TR_ACCOUNT" AS
/******************************************************************************
  Implements basic functions of persistent storage for table TR_ACCOUNT
  Company         My Compay
  Module          Bank Account
  Date            19/10/2017 17:19:20
  Author          First Name Last Name.
  Version         1.1.0  
  Description     My Decription.
******************************************************************************/

 PROCEDURE ACCOUNT_SAVE( pi_sald_ammount      IN  BANK.TR_ACCOUNT.SALD_AMOUNT%TYPE      ,
                           pi_start_user_code    IN  BANK.TR_ACCOUNT.START_USER_CODE%TYPE,
                           pi_end_user_code      IN  BANK.TR_ACCOUNT.END_USER_CODE%TYPE,
                           po_account_id         OUT BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE,
                           po_ok                 OUT VARCHAR2,
                           po_error_message      OUT BANK.TR_ERROR_LOG.error_message%TYPE);
END TX_TR_ACCOUNT;

/
