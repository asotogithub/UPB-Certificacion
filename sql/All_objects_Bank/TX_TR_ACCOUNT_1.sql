--------------------------------------------------------
--  DDL for Package Body TX_TR_ACCOUNT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "BANK"."TX_TR_ACCOUNT" AS
/******************************************************************************
  Implements basic functions of persistent storage for table TR_ACCOUNT
  Company         My Compay
  Module          Bank Account
  Date            19/10/2017 17:19:20
  Author          First Name Last Name.
  Version         1.1.0  
  Description     My Decription.
******************************************************************************/

 v_package VARCHAR2(100):='TX_TR_ACCOUNT';

 PROCEDURE ACCOUNT_SAVE( pi_sald_ammount      IN  BANK.TR_ACCOUNT.SALD_AMOUNT%TYPE      ,
                           pi_start_user_code    IN  BANK.TR_ACCOUNT.START_USER_CODE%TYPE,
                           pi_end_user_code      IN  BANK.TR_ACCOUNT.END_USER_CODE%TYPE,
                           po_account_id         OUT BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE,
                           po_ok                 OUT VARCHAR2,
                           po_error_message      OUT BANK.TR_ERROR_LOG.error_message%TYPE) IS

   v_procedure VARCHAR2(100):= v_package||'.ACCOUNT_SAVE';
   v_param_in VARCHAR2(3000);

  ERR_APP EXCEPTION;
  BEGIN
     po_ok:= 'OK';
     po_error_message:='';
    ----------------------- BUSINESS LOGIC ------------------------ 
     -- VALIDAR PARAMETROS DE ENTRADA
     IF pi_sald_ammount IS NULL OR
        pi_start_user_code IS NULL OR
        pi_end_user_code  IS NULL  THEN
       po_ok:= 'NOK';
       po_error_message:='Existen valores nulos!';
       RAISE ERR_APP;
     END IF;
     -- VALIDAR CONSTANTES UTILIZADAS..

   PS_TR_ACCOUNT.ACCOUNT_INSERT (  PI_SALD_AMMOUNT    => PI_SALD_AMMOUNT,
                                  PI_START_DATE      => SYSDATE,
                                  PI_END_DATE        => SYSDATE,
                                  PI_STATUS          => 'A',
                                  PI_START_USER_CODE => PI_START_USER_CODE,
                                  PI_END_USER_CODE   => PI_END_USER_CODE,
                                  po_account_id      => po_account_id,
                                  PO_OK              => PO_OK,
                                  PO_ERROR_MESSAGE   => PO_ERROR_MESSAGE) ;
    IF PO_OK !='OK' THEN
        RAISE ERR_APP;
    END IF;

    ----------------------- BUSINESS LOGIC ------------------------ 

  EXCEPTION
    WHEN ERR_APP THEN
        v_param_in := 'pi_sald_ammount:'|| pi_sald_ammount ||
                      ', pi_start_user_code:'|| pi_start_user_code||
                      ', pi_end_user_code:'||pi_end_user_code;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => -12,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  

    WHEN OTHERS THEN
        po_ok:= 'NOK'; 
        po_error_message := SQLERRM;
        v_param_in := 'pi_sald_ammount:'|| pi_sald_ammount ||
                      ', pi_start_user_code:'|| pi_start_user_code||
                      ', pi_end_user_code:'||pi_end_user_code;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => -12,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  

   END ACCOUNT_SAVE;
END TX_TR_ACCOUNT;

/
