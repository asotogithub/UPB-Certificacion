--------------------------------------------------------
--  DDL for Package Body BL_PROCESS_ACCOUNT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "BANK"."BL_PROCESS_ACCOUNT" AS


    
   v_package VARCHAR2(100):='BL_PROCESS_ACCOUNT_SVA';  
  PROCEDURE ACCOUNT_INIT( pi_sald_amount        IN BANK.TR_ACCOUNT.SALD_AMOUNT%TYPE,
                          pi_tran_id            IN  BANK.TR_DAILY.TRAN_ID%TYPE,
                          po_ok                 OUT VARCHAR2, 
                          po_error_message      OUT BANK.TR_ERROR_LOG.ERROR_MESSAGE%TYPE) IS

   v_procedure VARCHAR2(100):= v_package||'.ACCOUNT_INIT';
   v_param_in VARCHAR2(3000);
   v_account_id  BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE;
   v_daily_id  BANK.TR_DAILY.DAILY_ID%TYPE;


  ERR_APP EXCEPTION;
  BEGIN
     po_ok:= 'OK';
     po_error_message:='';
    ----------------------- BUSINESS LOGIC ------------------------ 
     -- VALIDAR PARAMETROS DE ENTRADA
     IF pi_sald_amount IS NULL THEN
       po_ok:= 'NOK';
       po_error_message:='Existen valores nulos!';
       RAISE ERR_APP;
     END IF;
     IF pi_sald_amount < 0 THEN
       po_ok:= 'NOK';
       po_error_message:='La cantidad es menor a 0';
       RAISE ERR_APP;
     END IF;
     -- VALIDAR CONSTANTES UTILIZADAS..
    -- Ctta Origen 1000000 
    TX_TR_ACCOUNT.ACCOUNT_SAVE (PI_SALD_AMMOUNT     => pi_sald_amount,
                                PI_START_USER_CODE  => USER,
                                PI_END_USER_CODE    => USER,
                                PO_ACCOUNT_ID       => v_account_id,
                                PO_OK               => PO_OK,
                                PO_ERROR_MESSAGE    => PO_ERROR_MESSAGE) ;

    IF PO_OK !='OK' THEN
        RAISE ERR_APP;
    END IF;

    TX_TR_DAILY.DAILY_SAVE (  PI_ACCOUNT_ORIGIN     => 1000000,  --Ctta gral de BANK
                            PI_ACCOUNT_DESTIN       => v_account_id,
                            PI_AMMOUNT              => pi_sald_amount,
                            PI_TYPE_TRANSACTION     => 'INI',
                            PI_START_TRAN_DATE      => SYSDATE,
                            PI_END_TRAN_DATE        => SYSDATE,
                            PI_START_USER_CODE      => USER,
                            PI_END_USER_CODE        => USER,
                            PI_TRAN_ID              => PI_TRAN_ID,
                            PO_DAILY_ID             => v_daily_id,
                            PO_OK                   => PO_OK,
                            PO_ERROR_MESSAGE        => PO_ERROR_MESSAGE) ;  
    IF PO_OK !='OK' THEN
        RAISE ERR_APP;
    END IF;

    BEGIN
      UPDATE BANK.TR_ACCOUNT
         SET SALD_AMOUNT = SALD_AMOUNT - pi_sald_amount
       WHERE
        account_id =1000000;
    EXCEPTION
       WHEN OTHERS THEN
         po_ok:= 'NOK';
         po_error_message:='Problemas al Modificar la ctta 1000000';
         RAISE ERR_APP;
    END;

    --BORRAR ESTO
    DBMS_OUTPUT.PUT_LINE ('CTTA: ' ||v_account_id ||' MONTO:'||pi_sald_amount);
    ----------------------- BUSINESS LOGIC ------------------------ 

  EXCEPTION
    WHEN ERR_APP THEN
        v_param_in := 'pi_sald_amount:'|| pi_sald_amount ||
                      ', pi_tran_id:'|| pi_tran_id;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => pi_tran_id,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  

    WHEN OTHERS THEN
        po_ok:= 'NOK'; 
        po_error_message := SQLERRM;
        v_param_in := 'pi_sald_amount:'|| pi_sald_amount ||
                      ', pi_tran_id:'|| pi_tran_id;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => pi_tran_id,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  

   END ACCOUNT_INIT;







   PROCEDURE ACCOUNT_TRANS_MONEY (	pi_amount     	        IN BANK.TR_ACCOUNT.SALD_AMOUNT%TYPE,
                                    pi_account_id_origin    IN BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE,
                                    pi_account_id_destin    IN BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE,
                                    pi_type_transaction		IN BANK.TR_DAILY.TYPE_TRANSACTION%TYPE,
                                    pi_tran_id              IN BANK.TR_DAILY.TRAN_ID%TYPE,
                                    po_ok               	OUT VARCHAR2,
                                    po_error_message     	OUT BANK.TR_ERROR_LOG.error_message%TYPE ) IS
      v_procedure VARCHAR2(100):= v_package||'.ACCOUNT_TRANS_MONEY';
   v_param_in VARCHAR2(3000);
   v_daily_id  BANK.TR_DAILY.DAILY_ID%TYPE;


  ERR_APP EXCEPTION;
  BEGIN
     po_ok:= 'OK';
     po_error_message:='';
    ----------------------- BUSINESS LOGIC ------------------------ 
     -- VALIDAR PARAMETROS DE ENTRADA
     IF pi_amount IS NULL OR
        pi_account_id_origin IS NULL OR
        pi_account_id_destin IS NULL OR
        pi_type_transaction IS NULL OR
        pi_tran_id IS NULL THEN
       po_ok:= 'NOK';
       po_error_message:='Existen valores nulos!';
       RAISE ERR_APP;
     END IF;
     IF pi_amount < 0 THEN
       po_ok:= 'NOK';
       po_error_message:='La cantidad es menor a 0';
       RAISE ERR_APP;
     END IF;
     -- VALIDAR CONSTANTES UTILIZADAS..


    IF pi_type_transaction = GLOBAL_VARIABLE.k_tran_type_deposit THEN
      --Para el deposito, la cta origen es la cta de la cajera o personal de banco.
      --cta destino es la cta del acreedor del dinero
        TX_TR_DAILY.DAILY_SAVE (  PI_ACCOUNT_ORIGIN     => pi_account_id_origin,
                                PI_ACCOUNT_DESTIN       => pi_account_id_destin,
                                PI_AMMOUNT              => pi_amount,
                                PI_TYPE_TRANSACTION     => pi_type_transaction,
                                PI_START_TRAN_DATE      => SYSDATE,
                                PI_END_TRAN_DATE        => SYSDATE,
                                PI_START_USER_CODE      => USER,
                                PI_END_USER_CODE        => USER,
                                PI_TRAN_ID              => PI_TRAN_ID,
                                PO_DAILY_ID             => v_daily_id,
                                PO_OK                   => PO_OK,
                                PO_ERROR_MESSAGE        => PO_ERROR_MESSAGE) ;  
        IF PO_OK !='OK' THEN
            RAISE ERR_APP;
        END IF; 
         ----actualizar ctta origin
        BEGIN
          UPDATE BANK.TR_ACCOUNT
             SET SALD_AMOUNT = SALD_AMOUNT - pi_amount
           WHERE
            account_id =pi_account_id_origin;
        EXCEPTION
           WHEN OTHERS THEN
             po_ok:= 'NOK';
             po_error_message:='Problemas al Modificar la ctta '||pi_account_id_origin;
             RAISE ERR_APP;
        END;
         ----actualizar ctta destino
        BEGIN
          UPDATE BANK.TR_ACCOUNT
             SET SALD_AMOUNT = SALD_AMOUNT + pi_amount
           WHERE
            account_id =pi_account_id_destin;
        EXCEPTION
           WHEN OTHERS THEN
             po_ok:= 'NOK';
             po_error_message:='Problemas al Modificar la ctta '||pi_account_id_destin;
             RAISE ERR_APP;
        END;

    ELSIF pi_type_transaction IN (GLOBAL_VARIABLE.k_tran_type_withdraw,GLOBAL_VARIABLE.k_tran_type_tranfer) THEN
        --La cuenta origen. = a la cuenta que vamos a sacar el dinero
        -- cuenta destino es la cta de cajera o persona q realiza la operacion y lo almacena en una ctta especial
        -- esta cuenta debe ser introducida por teclado y designado por usuario por ejm, 1000001

        TX_TR_DAILY.DAILY_SAVE (  PI_ACCOUNT_ORIGIN     => pi_account_id_origin,
                                PI_ACCOUNT_DESTIN       => pi_account_id_destin,
                                PI_AMMOUNT              => pi_amount,
                                PI_TYPE_TRANSACTION     => pi_type_transaction,  --Retiro
                                PI_START_TRAN_DATE      => SYSDATE,
                                PI_END_TRAN_DATE        => SYSDATE,
                                PI_START_USER_CODE      => USER,
                                PI_END_USER_CODE        => USER,
                                PI_TRAN_ID              => PI_TRAN_ID,
                                PO_DAILY_ID             => v_daily_id,
                                PO_OK                   => PO_OK,
                                PO_ERROR_MESSAGE        => PO_ERROR_MESSAGE) ;  
        IF PO_OK !='OK' THEN
            RAISE ERR_APP;
        END IF; 
         ----actualizar ctta origin
        BEGIN
          UPDATE BANK.TR_ACCOUNT
             SET SALD_AMOUNT = SALD_AMOUNT - pi_amount
           WHERE
            account_id =pi_account_id_origin;
        EXCEPTION
           WHEN OTHERS THEN
             po_ok:= 'NOK';
             po_error_message:='Problemas al Modificar la ctta '||pi_account_id_origin;
             RAISE ERR_APP;
        END;
         ----actualizar ctta destino
        BEGIN
          UPDATE BANK.TR_ACCOUNT
             SET SALD_AMOUNT = SALD_AMOUNT + pi_amount
           WHERE
            account_id =pi_account_id_destin;
        EXCEPTION
           WHEN OTHERS THEN
             po_ok:= 'NOK';
             po_error_message:='Problemas al Modificar la ctta '||pi_account_id_destin;
             RAISE ERR_APP;
        END;

    END IF;

    ----------------------- BUSINESS LOGIC ------------------------ 
  EXCEPTION
    WHEN ERR_APP THEN
        v_param_in := 'pi_amount:'|| pi_amount ||
                      ', pi_account_id_origin:'|| pi_account_id_origin ||
                      ', pi_account_id_destin:'|| pi_account_id_destin ||
                      ', pi_type_transaction:'|| pi_type_transaction ||
                      ', pi_tran_id:'|| pi_tran_id;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => pi_tran_id,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  

    WHEN OTHERS THEN
        po_ok:= 'NOK'; 
        po_error_message := SQLERRM;
        v_param_in := 'pi_amount:'|| pi_amount ||
                      ', pi_account_id_origin:'|| pi_account_id_origin ||
                      ', pi_account_id_destin:'|| pi_account_id_destin ||
                      ', pi_type_transaction:'|| pi_type_transaction ||
                      ', pi_tran_id:'|| pi_tran_id;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => pi_tran_id,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  
  END;                                  


END BL_PROCESS_ACCOUNT;

/
