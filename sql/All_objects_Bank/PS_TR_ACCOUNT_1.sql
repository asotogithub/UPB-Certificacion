--------------------------------------------------------
--  DDL for Package Body PS_TR_ACCOUNT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "BANK"."PS_TR_ACCOUNT" AS
/******************************************************************************
  Implements basic functions of persistent storage for table PS_TR_ACCOUNT
  Company         My Compay
  Module          Bank Account
  Date            17/10/2017 17:19:20
  Author          First Name Last Name.
  Version         1.1.0  
  Description     My Decription.
******************************************************************************/
 --- LOCAL VARIABLES
    v_package VARCHAR2(100):='PS_TR_ACCOUNT';


 PROCEDURE ACCOUNT_INSERT( pi_sald_ammount      IN  BANK.TR_ACCOUNT.SALD_AMOUNT%TYPE      ,
                          pi_start_date         IN  BANK.TR_ACCOUNT.START_DATE%TYPE,
                          pi_end_date           IN  BANK.TR_ACCOUNT.END_DATE%TYPE,
                          pi_status             IN  BANK.TR_ACCOUNT.STATUS%TYPE,
                          pi_start_user_code    IN  BANK.TR_ACCOUNT.START_USER_CODE%TYPE,
                          pi_end_user_code      IN  BANK.TR_ACCOUNT.END_USER_CODE%TYPE,
                          po_account_id         OUT BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE,
                          po_ok                 OUT VARCHAR2,
                          po_error_message      OUT BANK.TR_ERROR_LOG.error_message%TYPE) IS

    v_procedure VARCHAR2(100):= v_package||'.ACCOUNT_INSERT';
    v_param_in VARCHAR2(3000);
    ERR_APP EXCEPTION;
  BEGIN

     po_ok:= 'OK';
     po_error_message:='';
    ----------------------- BUSINESS LOGIC ------------------------   
      INSERT INTO tr_account (
        account_id,
        sald_amount,
        start_date,
        end_date,
        status,
        start_user_code,
        end_user_code
        ) VALUES (
         BANK.SEQ_ACCOUNT.NEXTVAL,
        pi_sald_ammount,
        pi_start_date,
        pi_end_date,
        pi_status,
        pi_start_user_code,
        pi_end_user_code )
        RETURNING account_id INTO po_account_id;

        IF SQL%ROWCOUNT = 0 THEN
          po_ok:= 'NOK';
          po_error_message:='Insert fail!'; 
          RAISE ERR_APP;
        END IF;

  EXCEPTION
    WHEN ERR_APP THEN
        v_param_in := 'pi_sald_ammount:'|| pi_sald_ammount ||
                      ', pi_start_date:'|| TO_CHAR(pi_start_date, 'DD/MM/YYYY HH24:MI:SS')||
                      ', pi_end_date:'|| TO_CHAR(pi_end_date, 'DD/MM/YYYY HH24:MI:SS')||
                      ', pi_status:'||pi_status;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => -12,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  

    WHEN OTHERS THEN
        po_ok:= 'NOK'; 
        po_error_message := SQLERRM;
        v_param_in := 'pi_sald_ammount:'|| pi_sald_ammount ||
                      ', pi_start_date:'|| TO_CHAR(pi_start_date, 'DD/MM/YYYY HH24:MI:SS')||
                      ', pi_end_date:'|| TO_CHAR(pi_end_date, 'DD/MM/YYYY HH24:MI:SS')||
                      ', pi_status:'||pi_status;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => -12,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  

  END ACCOUNT_INSERT;
END PS_TR_ACCOUNT;

/
