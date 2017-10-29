--------------------------------------------------------
--  DDL for Package Body PS_TR_DAILY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "BANK"."PS_TR_DAILY" AS
/******************************************************************************
  Implements basic functions of persistent storage for table TR_DAILY
  Company         My Compay
  Module          Bank Account
  Date            17/10/2017 17:19:20
  Author          First Name Last Name.
  Version         1.1.0  
  Description     My Decription.
******************************************************************************/


 v_package VARCHAR2(100):='PS_TR_DAILY';
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
                           po_error_message      OUT BANK.TR_ERROR_LOG.error_message%TYPE) IS

    v_procedure VARCHAR2(100):= v_package||'.DAILY_INSERT';
    v_param_in VARCHAR2(3000);
    ERR_APP EXCEPTION;

  BEGIN
     po_ok:= 'OK';
     po_error_message:='';
    ----------------------- BUSINESS LOGIC ------------------------ 

      INSERT INTO tr_daily (
        daily_id,
        account_id_origin,
        account_id_destin,
        amount,
        type_transaction,
        start_tran_date,
        start_user_code,
        end_tran_date,
        end_user_code,
        tran_id
    ) VALUES (
        SEQ_DAILY.NEXTVAL,
        pi_account_origin,
        pi_account_destin,
        pi_ammount,
        pi_type_transaction,
        pi_start_tran_date,
        pi_start_user_code,
        pi_end_tran_date,
        pi_end_user_code,
        pi_tran_id
    )
    RETURNING  daily_id INTO po_daily_id;

       IF SQL%ROWCOUNT = 0 THEN
          po_ok:= 'NOK';
          po_error_message:='Insert fail!'; 
          RAISE ERR_APP;
        END IF;

  EXCEPTION
    WHEN ERR_APP THEN
        v_param_in := 'pi_account_origin:'|| pi_account_origin ||
                      ', pi_account_destin:'|| pi_account_destin ||
                      ', pi_ammount:'|| pi_ammount ||
                      ', pi_type_transaction:'|| pi_type_transaction ||
                      ', pi_start_tran_date:'|| TO_CHAR(pi_start_tran_date, 'DD/MM/YYYY HH24:MI:SS')||
                      ', pi_start_user_code:'|| pi_start_user_code ||
                      ', pi_end_tran_date:'|| TO_CHAR(pi_end_tran_date, 'DD/MM/YYYY HH24:MI:SS')||
                      ', pi_end_user_code:'|| pi_end_user_code ||
                      ', pi_tran_id:'||pi_tran_id;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => pi_tran_id,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  

    WHEN OTHERS THEN
        po_ok:= 'NOK'; 
        po_error_message := SQLERRM;
        v_param_in := 'pi_account_origin:'|| pi_account_origin ||
                      ', pi_account_destin:'|| pi_account_destin ||
                      ', pi_ammount:'|| pi_ammount ||
                      ', pi_type_transaction:'|| pi_type_transaction ||
                      ', pi_start_tran_date:'|| TO_CHAR(pi_start_tran_date, 'DD/MM/YYYY HH24:MI:SS')||
                      ', pi_start_user_code:'|| pi_start_user_code ||
                      ', pi_end_tran_date:'|| TO_CHAR(pi_end_tran_date, 'DD/MM/YYYY HH24:MI:SS')||
                      ', pi_end_user_code:'|| pi_end_user_code ||
                      ', pi_tran_id:'||pi_tran_id;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => pi_tran_id,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  

  END;



END PS_TR_DAILY;

/
