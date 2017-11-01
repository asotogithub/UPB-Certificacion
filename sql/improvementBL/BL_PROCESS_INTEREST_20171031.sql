create or replace PACKAGE BODY BL_PROCESS_INTEREST AS
/******************************************************************************
  Business Logic for Month calculate interests 
  Company         My Compay
  Module          Bank Account
  Date            17/10/2017 17:19:20
  Author          First Name Last Name.
  Version         1.1.0  
  Description     My Decription.
******************************************************************************/

  v_package VARCHAR2(100):='BL_PROCESS_INTEREST';

   
   PROCEDURE INTEREST_EVAL_DAYS (pi_account_id    IN BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE,
                                 pi_date          IN DATE,
                                 pi_tran_id       IN  BANK.TR_DAILY.TRAN_ID%TYPE,
                                 po_type_evaluation OUT CF_INTERESTS.TYPE_EVALUATION%TYPE,
                                 po_type_interest OUT CF_INTERESTS.TYPE_INTEREST%TYPE,
                                 po_amount OUT CF_INTEREST_EVAL.AMOUNT%TYPE,
                                 po_sald_amout OUT TR_ACCOUNT.SALD_AMOUNT%TYPE,
                                 po_ok OUT VARCHAR2,
                                 po_error_message OUT TR_ERROR_LOG.ERROR_MESSAGE%TYPE
   ) IS
   
   CURSOR c_get_data_eval (cp_days NUMBER, cp_date DATE) IS
   SELECT I.TYPE_INTEREST, I.TYPE_EVALUATION, IV.AMOUNT
   FROM CF_INTERESTS  I, CF_INTEREST_EVAL IV
   WHERE I.CODE = IV.CODE
     AND I.STATUS ='A'
     AND cp_date BETWEEN I.START_DATE AND I.END_DATE
     AND  IV.STATUS ='A'
     AND cp_date BETWEEN IV.START_DATE AND IV.END_DATE
     AND cp_days BETWEEN IV.INIT_EVAL_DAY AND IV.END_EVAL_DAY
     ORDER BY IV.INT_PRIORITY ASC;
    
    v_procedure VARCHAR2(100):= v_package||'.INTEREST_EVAL_DAYS';
    v_param_in VARCHAR2(3000);
    v_days NUMBER;
   ERR_APP EXCEPTION; 
   BEGIN
       po_ok := 'OK';
       po_error_message := '';
       BEGIN
          SELECT CEIL(SYSDATE - START_DATE), sald_amount INTO v_days, po_sald_amout
          FROM TR_ACCOUNT 
          WHERE ACCOUNT_ID = pi_account_id--1000000
            AND STATUS ='A'
            AND pi_date BETWEEN START_DATE AND END_DATE;
       EXCEPTION    
           WHEN NO_DATA_FOUND THEN
                po_ok := 'NOK';
               po_error_message :='LA CUENTA NO EXISTE!';
               RAISE ERR_APP;
           WHEN OTHERS THEN
               po_ok := 'NOK';
               po_error_message := SQLERRM;
            RAISE ERR_APP;
       END;
      OPEN c_get_data_eval(v_days, pi_date);
      FETCH c_get_data_eval INTO  po_type_interest, po_type_evaluation, po_amount;
      CLOSE c_get_data_eval;

   EXCEPTION
     WHEN ERR_APP THEN
        v_param_in := 'pi_account_id:'|| pi_account_id ||
                      ', pi_date:'|| TO_CHAR(pi_date, 'DD/MM/YYYY HH24:MI:SS')||
                      ', pi_tran_id:'||pi_tran_id;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => pi_tran_id,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  
   END INTEREST_EVAL_DAYS;

   
   
   PROCEDURE CALC_AMOUNT ( pi_type_evaluation IN CF_INTERESTS.TYPE_EVALUATION%TYPE,
                           pi_amount IN CF_INTEREST_EVAL.AMOUNT%TYPE,
                           pi_sald_amout IN TR_ACCOUNT.SALD_AMOUNT%TYPE,
                           pi_tran_id       IN  BANK.TR_DAILY.TRAN_ID%TYPE,
                           po_amout_calc OUT TR_ACCOUNT.SALD_AMOUNT%TYPE,
                           po_ok OUT VARCHAR2,
                           po_error_message OUT TR_ERROR_LOG.ERROR_MESSAGE%TYPE
   
   ) IS
    v_procedure VARCHAR2(100):= v_package||'.CALC_AMOUNT';
    v_param_in VARCHAR2(3000);

   BEGIN
      po_ok := 'OK';
      po_error_message :='';
       
       IF  pi_type_evaluation = 'PORCENTAGE' THEN
         po_amout_calc := (pi_sald_amout * (pi_amount/100));
       ELSIF pi_type_evaluation = 'MONTO_FIJO' THEN
         po_amout_calc :=  pi_amount;
       END IF;
   EXCEPTION
    WHEN OTHERS THEN
       po_amout_calc :=0.0;
       po_ok := 'NOK';
       po_error_message := SQLERRM;
    v_param_in := 'pi_type_evaluation:'|| pi_type_evaluation ||
                   ', pi_amount:'|| pi_amount||
                   ', pi_sald_amout:'||pi_sald_amout||
                    ', pi_tran_id:'||pi_tran_id;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => pi_tran_id,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;     
   END;
   
   
   PROCEDURE PAY_INTEREST (pi_account_id    IN BANK.TR_ACCOUNT.ACCOUNT_ID%TYPE,
                           pi_date          IN DATE,
                           pi_tran_id       IN NUMBER,
                           po_ok            OUT VARCHAR2,
                           po_error_message OUT TR_ERROR_LOG.ERROR_MESSAGE%TYPE) IS
   
   v_type_evaluation CF_INTERESTS.TYPE_EVALUATION%TYPE;
   v_type_interest   CF_INTERESTS.TYPE_INTEREST%TYPE;
   v_amount          CF_INTEREST_EVAL.AMOUNT%TYPE;
   v_sald_amount     TR_ACCOUNT.SALD_AMOUNT%TYPE;
   v_amount_calc     TR_ACCOUNT.SALD_AMOUNT%TYPE;
    v_procedure VARCHAR2(100):= v_package||'.PAY_INTEREST';
    v_param_in VARCHAR2(3000);
   
   ERR_APP EXCEPTION;
   BEGIN
     po_ok := 'OK';
     po_error_message := '';
     
     BL_PROCESS_INTEREST.INTEREST_EVAL_DAYS (  PI_ACCOUNT_ID        => pi_account_id,
                                                PI_DATE             => pi_date,
                                                pi_tran_id          => pi_tran_id,
                                                PO_TYPE_EVALUATION  => v_type_evaluation,
                                                PO_TYPE_INTEREST    => v_type_interest,
                                                PO_AMOUNT           => v_amount,
                                                PO_SALD_AMOUT       => v_sald_amount,
                                                PO_OK               => PO_OK,
                                                PO_ERROR_MESSAGE    => PO_ERROR_MESSAGE) ; 
     IF po_ok !='OK' THEN
        RAISE ERR_APP;
     END IF;
     
     BL_PROCESS_INTEREST.CALC_AMOUNT ( pi_type_evaluation => v_type_evaluation,
                                       pi_amount          => v_amount,
                                       pi_sald_amout      => v_sald_amount,
                                       pi_tran_id         => pi_tran_id,
                                       po_amout_calc      => v_amount_calc,
                                       po_ok              => po_ok,
                                       po_error_message   => po_error_message);
     IF po_ok !='OK' THEN
        RAISE ERR_APP;
     END IF;
     
     IF v_type_interest = 'PAGO' THEN
         BL_PROCESS_ACCOUNT.ACCOUNT_TRANS_MONEY (  PI_AMOUNT => v_amount_calc,
                                                PI_ACCOUNT_ID_ORIGIN => 1000000, --CTTA BNB
                                                PI_ACCOUNT_ID_DESTIN => pi_account_id,
                                                PI_TYPE_TRANSACTION => GLOBAL_VARIABLE.k_tran_type_tranfer,
                                                PI_TRAN_ID => PI_TRAN_ID,
                                                PO_OK => PO_OK,
                                                PO_ERROR_MESSAGE => PO_ERROR_MESSAGE) ; 
     
         IF po_ok !='OK' THEN
            RAISE ERR_APP;
         END IF;
     ELSIF v_type_interest = 'COBRO' THEN
        BL_PROCESS_ACCOUNT.ACCOUNT_TRANS_MONEY (  PI_AMOUNT => v_amount_calc,
                                                PI_ACCOUNT_ID_ORIGIN => pi_account_id, 
                                                PI_ACCOUNT_ID_DESTIN => 1000000,--CTTA BNB
                                                PI_TYPE_TRANSACTION => GLOBAL_VARIABLE.k_tran_type_deposit,
                                                PI_TRAN_ID => PI_TRAN_ID,
                                                PO_OK => PO_OK,
                                                PO_ERROR_MESSAGE => PO_ERROR_MESSAGE) ; 
         IF po_ok !='OK' THEN
            RAISE ERR_APP;
         END IF;

     END IF;
     
   EXCEPTION
      WHEN ERR_APP THEN
        v_param_in := 'pi_account_id:'|| pi_account_id ||
                   ', pi_date:'|| TO_CHAR(pi_date,'DD-MM-YYYY HH24:MI:SS')||
                   ', pi_tran_id:'||pi_tran_id;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => pi_tran_id,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  
      WHEN OTHERS THEN
       po_ok := 'NOK';
       po_error_message := SUBSTR(SQLERRM,1,1000);
    v_param_in := 'pi_account_id:'|| pi_account_id ||
                   ', pi_date:'|| TO_CHAR(pi_date,'DD-MM-YYYY HH24:MI:SS')||
                   ', pi_tran_id:'||pi_tran_id;

        TX_TR_ERROR_LOG.SAVE_LOG (  PI_TRAN_ID => pi_tran_id,
                                    PI_ERROR_MSG => po_error_message,
                                    PI_ERROR_SOURCE => v_procedure||'('||v_param_in||')') ;  
   END PAY_INTEREST;
   
   PROCEDURE PAY_INTEREST (pi_date          IN DATE,
                           pi_tran_id       IN NUMBER,
                           po_ok            OUT VARCHAR2,
                           po_error_message OUT TR_ERROR_LOG.ERROR_MESSAGE%TYPE) IS
   
    CURSOR c_get_all_account (cp_date DATE) IS
        SELECT * 
          FROM BANK.TR_ACCOUNT
          WHERE status = GLOBAL_VARIABLE.k_status_active
            AND cp_date BETWEEN start_date and end_date
            AND ACCOUNT_ID != 1000000;
   
   ERR_APP_FOR EXCEPTION;
   BEGIN
      po_ok:='OK';
      po_error_message:='';
      
    FOR rec IN c_get_all_account(pi_date)  LOOP
      BEGIN  
         BL_PROCESS_INTEREST.PAY_INTEREST ( PI_ACCOUNT_ID    => rec.account_id,
                                            PI_DATE          => PI_DATE,
                                            PI_TRAN_ID       => PI_TRAN_ID,
                                            PO_OK            => PO_OK,
                                            PO_ERROR_MESSAGE => PO_ERROR_MESSAGE) ; 
         IF PO_OK !='OK' THEN
            RAISE ERR_APP_FOR;
         END IF;
         
      EXCEPTION
        WHEN ERR_APP_FOR THEN
           NULL;
            --TODO: guardar todas las cttas q no hayan concluido su proceso..
      END;                                      
    END LOOP;
   
   EXCEPTION
    WHEN OTHERS THEN
        NULL; --- TODO: lanzar la exception con mensajes.......
   
   END PAY_INTEREST;
   
   
   
   PROCEDURE PAY_INTEREST (pi_date IN DATE) IS
   
    v_tran_id NUMBER;
    v_ok VARCHAR2(50);
    v_error_message TR_ERROR_LOG.ERROR_MESSAGE%TYPE;
   BEGIN
   
        v_tran_id := SEQ_TRAN_ID.NEXTVAL;
        BL_PROCESS_INTEREST.PAY_INTEREST (  PI_DATE => pi_date,
                                        PI_TRAN_ID => v_tran_id,
                                        PO_OK => v_ok,
                                        PO_ERROR_MESSAGE => v_error_message) ; 
                                        
        BEGIN
            INSERT INTO tr_audit_bank ( created_date,created_by,tran_id, error_message,source_bank
              ) VALUES ( SYSDATE, USER, v_tran_id, v_error_message, 'EXEC JOB');
        END;
   COMMIT;
   
   END;
   
 

END BL_PROCESS_INTEREST;