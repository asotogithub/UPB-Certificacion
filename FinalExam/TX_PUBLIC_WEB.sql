CREATE OR REPLACE PACKAGE TX_PUBLIC_WEB AS
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
END TX_PUBLIC_WEB;
/


CREATE OR REPLACE PACKAGE BODY TX_PUBLIC_WEB AS
/******************************************************************************
  Implements basic functions of persistent storage for table TR_ACCOUNT
  Company         My Compay
  Module          Bank Account
  Date            19/10/2017 17:19:20
  Author          First Name Last Name.
  Version         1.1.0  
  Description     My Decription.
******************************************************************************/
  v_package VARCHAR2(100):='TX_PUBLIC_WEB';


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
    BANK.TX_TR_ACCOUNT.ACCOUNT_SAVE (PI_SALD_AMMOUNT => PI_SALD_AMMOUNT,
                                PI_START_USER_CODE => PI_START_USER_CODE,
                                PI_END_USER_CODE => PI_END_USER_CODE,
                                PO_ACCOUNT_ID => PO_ACCOUNT_ID,
                                PO_OK => PO_OK,
                                PO_ERROR_MESSAGE => PO_ERROR_MESSAGE) ;
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




END TX_PUBLIC_WEB;
/
