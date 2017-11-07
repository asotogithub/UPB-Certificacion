--------------------------------------------------------
--  DDL for Package Body PS_TR_ERROR_LOG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "BANK"."PS_TR_ERROR_LOG" AS
  /******************************************************************************
  Implements basic functions of persistent storage for table TR_ERROR_LOG
  Company         My Compay
  Module          Bank Account
  Date            17/10/2017 17:19:20
  Author          First Name Last Name.
  Version         1.1.0  
  Description     My Decription.
  ******************************************************************************/

 /*
  Inserts a record in table TR_ERROR_LOG receiving some columns as parameters
  Date          01/07/2009 17:19:20
  Author        First Name Last Name.
  Version       1.0.0
  param         pi_tran_id 
  param         pi_error_message
  param         pi_error_source
  */
  PROCEDURE LOG_INSERT( pi_tran_id       IN  BANK.TR_ERROR_LOG.tran_id%TYPE      ,
                                pi_error_message  IN  BANK.TR_ERROR_LOG.error_message%TYPE,
                                pi_error_source  IN  BANK.TR_ERROR_LOG.error_source%TYPE ) IS
  BEGIN
    ------------------------Busness Logic ------------------------------------
    INSERT INTO TR_ERROR_LOG
              ( error_log_id,
                tran_id,
                error_line   ,
                error_message,
                error_source,
                process_date)
        VALUES( BANK.SEQ_ERROR_LOG.NEXTVAL,
                pi_tran_id      ,
                1, --UPPER(RTRIM(SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), INSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), ' ', -1) + 1, 10), ' ' || CHR(10))),
                UPPER( pi_error_message )    ,
                UPPER( pi_error_source ) ,
                SYSDATE);
  EXCEPTION 
    WHEN OTHERS THEN
      NULL;                         

  END LOG_INSERT;

  PROCEDURE RETRIEVE_( pi_error_log_id IN  BANK.TR_ERROR_LOG.error_log_id%TYPE,
									     po_tr_error_log_rec  OUT BANK.TR_ERROR_LOG%ROWTYPE     ) IS
  BEGIN
     ------------------------Busness Logic ------------------------------------
    SELECT *
    INTO po_tr_error_log_rec
    FROM BANK.TR_ERROR_LOG
    WHERE error_log_id = pi_error_log_id;

  EXCEPTION 
    WHEN OTHERS THEN
        NULL;   
  END RETRIEVE_;     
END PS_TR_ERROR_LOG;

/
