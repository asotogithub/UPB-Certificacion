--------------------------------------------------------
--  DDL for Package PS_TR_ERROR_LOG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "BANK"."PS_TR_ERROR_LOG" AS
/******************************************************************************
  Implements basic functions of persistent storage for table TR_ERROR_LOG
  Company         My Compay
  Module          Bank Account
  Date            17/10/2017 17:19:20
  Author          First Name Last Name.
  Version         1.1.0  
  Description     My Decription.
******************************************************************************/

 PROCEDURE LOG_INSERT( pi_tran_id       IN  BANK.TR_ERROR_LOG.tran_id%TYPE      ,
                       pi_error_message IN  BANK.TR_ERROR_LOG.error_message%TYPE,
                       pi_error_source  IN  BANK.TR_ERROR_LOG.error_source%TYPE );
END PS_TR_ERROR_LOG;

/
