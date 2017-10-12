CREATE OR REPLACE PACKAGE CRU.BL_CREDIT_LIMIT_PROCESS is

  /**************************************************************************
  Implements utility procedures and functions for the CREDIT LIMIT process
  %Company         Trilogy Software Bolivia
  %System          Omega Convergent Billing
  %Date            06/09/2011 17:15:00
  %Control         20281
  %Author          "Marleny Patsi Tapia"
  %Version         1.0.0
  **************************************************************************/

  FUNCTION GET_VERSION RETURN VARCHAR2;

  PROCEDURE EXECUTE_MASIVE;

  PROCEDURE LAUNCH_JOB_PROC_CREDIT_LIMIT( pi_tran_id    IN  CRU.TR_ERROR_LOG.tran_id%TYPE,
                                          po_error_code OUT VARCHAR2                     ,
                                          po_error_msg  OUT VARCHAR2                     );

END BL_CREDIT_LIMIT_PROCESS;
/

CREATE OR REPLACE PACKAGE BODY CRU.BL_CREDIT_LIMIT_PROCESS IS
  /**************************************************************************
  Implements utility procedures and functions for the CREDIT LIMIT process
  %Company         Trilogy Software Bolivia
  %System          Omega Convergent Billing
  %Date            06/09/2011 17:15:00
  %Control         20281
  %Author          "Marleny Patsi Tapia"
  %Version         1.0.0
  **************************************************************************/

  VERSION CONSTANT VARCHAR2(15) := '3.0.0';
  
  v_package VARCHAR2(100) := 'CRU.BL_CREDIT_LIMIT_PROCESS';

  c_application_code   CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_APPLICATION_CODE('APPLICATION_CRU',SYSDATE)  ;
  c_inactive           CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(c_application_code, 'SYSTEM_STATUS_INACTIVE',SYSDATE);
  c_true               CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(c_application_code, 'VALUE_BOOLEAN_TRUE',SYSDATE)  ;
  c_false              CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(c_application_code, 'VALUE_BOOLEAN_FALSE',SYSDATE)  ;

  /*
  Returns the version of the package
  %Date            17/04/2013 16:16:20
  %Control         Automatic Process
  %Author          Automatic Process
  %Version         1.0.0
  */


  FUNCTION GET_VERSION RETURN VARCHAR2 IS
  BEGIN
    return VERSION;
  END GET_VERSION;

   /*
    Process controls credit limit
    %Date          06/09/2011 17:15:00
    %Control       20281
    %Author        "Marleny Patsi Tapia"
    %Version       1.0.0
       %param         po_error_code Output showing one of the next results:
                         {*} OK - If procedure executed satisfactorily
                         {*} XXX-#### - Error code if any error found
       %param         po_error_msg Output showing the error message if any error found
       %raises        ERR_APP Application level error

       %Changes
       <hr>
          {*}Date       08/06/2012 11:27:30
          {*}Control    299
          {*}Author     "Abel Soto Vera"
          {*}Note       Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity
      <hr>
        {*}Date       15/01/2013 15:00:00
        {*}Control    299 
        {*}Author     "Rosio Eguivar"
        {*}Note       Modification of CRU, to support Credit unit whit rollover.
                
 
  */


  PROCEDURE EXECUTE_MASIVE IS

  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.EXECUTE_MASIVE';
    v_param_in          VARCHAR2(4000)                               ;
    v_error_code        CRU.TR_ERROR_LOG.error_code%TYPE;
    v_error_msg         CRU.TR_ERROR_LOG.error_message%TYPE;

  --constant
  c_cru_behavior_limit   CONSTANT ITF.CF_DOMAIN.domain_code%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(c_application_code, 'CRU_BEHAVIOR_TYPE_CREDIT_LIMIT',SYSDATE);
  c_eval_amount_limit    CONSTANT ITF.CF_DOMAIN.domain_code%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(c_application_code, 'CRU_EVALUATION_CRITERIA_TYPE_AMOUNT',SYSDATE);
  c_eval_duration_limit  CONSTANT ITF.CF_DOMAIN.domain_code%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(c_application_code, 'CRU_EVALUATION_CRITERIA_TYPE_DUR',SYSDATE);
  c_eval_quantity_limit  CONSTANT ITF.CF_DOMAIN.domain_code%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(c_application_code, 'CRU_EVALUATION_CRITERIA_TYPE_QUANTITY',SYSDATE);
  c_async_stat_dlv       CONSTANT ITF.CF_DOMAIN.domain_code%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(c_application_code, 'INITIAL_INTEGRATION_STATUS',SYSDATE)   ;
  c_async_stat_reg       CONSTANT ITF.CF_DOMAIN.domain_code%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(c_application_code, 'REGISTER_INTEGRATION_STATUS',SYSDATE)   ;
  c_bill_user_id         CONSTANT NUMBER := ITF.TX_PUBLIC_CRU.GET_PARAMETER_NUM(c_application_code,'BILLING_PROCESS_USER_ID',SYSDATE);

  --Cursors of procedure
  --<REE Control: 299 15/01/2013 15:00:00 Modification of CRU, to support Credit unit whit rollover>
  /*
  CURSOR cur_credit_limits_instan( v_eval_date   DATE ) IS
                                  SELECT ec.*, cu.credit_unit_id, cu.credit_unit_type_code, cu.behavior_type_code, cu.date_expiration_type_code,
                                        cu.round_method_code, cu.is_reseteable, cu.is_include_invoice, cu.is_currency
                                        --ew.eval_criteria_type_code, ew.usage_type_code, ew.jurisdiction_type_code
                                    FROM CRU.TR_ENTITY_CREDIT_UNIT ec, CRU.CF_CREDIT_UNIT cu
                                   WHERE ec.credit_unit_code  = cu.credit_unit_code
                                     AND cu.behavior_type_code = c_cru_behavior_limit
                                     AND ec.status <> c_inactive
                                     AND v_eval_date BETWEEN ec.start_date AND ec.end_date
                                     AND cu.status <> c_inactive
                                     AND v_eval_date BETWEEN cu.start_date AND cu.end_date
                                   ORDER BY ec.credit_unit_code, ec.entity_type_code, ec.entity_id;*/

  CURSOR cur_credit_limits_instan( v_eval_date   DATE ) IS
                                  SELECT ec.*, cu.credit_unit_id, cu.credit_unit_type_code, cu.behavior_type_code, rat.date_expiration_type_code,
                                        cu.round_method_code, rat.is_reseteable, cu.is_currency, cu.integration_other_system
                                        --ew.eval_criteria_type_code, ew.usage_type_code, ew.jurisdiction_type_code
                                    FROM CRU.TR_ENTITY_CREDIT_UNIT ec, CRU.CF_CREDIT_UNIT cu, CRU.CF_CRU_RATE RAT
                                   WHERE ec.credit_unit_code  = cu.credit_unit_code
                                     AND cu.behavior_type_code = c_cru_behavior_limit
                                     AND rat.credit_unit_code = cu.credit_unit_code   
                                     AND rat.plan_code = ec.plan_code
                                     AND rat.component_code = ec.component_code                              
                                     AND ec.status <> c_inactive
                                     AND v_eval_date BETWEEN ec.start_date AND ec.end_date
                                     AND cu.status <> c_inactive
                                     AND v_eval_date BETWEEN cu.start_date AND cu.end_date
                                     AND rat.status <> c_inactive
                                     AND v_eval_date BETWEEN rat.start_date AND rat.end_date
                                   ORDER BY ec.credit_unit_code, ec.entity_type_code, ec.entity_id;  
  --<REE Control: 299 15/01/2013 15:00:00 >                                                                   
  --cru evaluates
  CURSOR cur_evaluate_cru (p_credit_unit_code CRU.CF_CRU_EVALUATE_USG.credit_unit_code%TYPE,
                           v_eval_date       DATE)  IS
                             SELECT *
                               FROM cru.cf_cru_evaluate_usg
                              WHERE credit_unit_code = p_credit_unit_code
                                AND status <> c_inactive
                                AND v_eval_date BETWEEN start_date AND end_date ;


  --Variables procedure
  v_tran_id               CRU.TR_ERROR_LOG.tran_id%TYPE;
  v_cycle_code            BIL.CF_CYCLE_INTERVAL.cycle_code%TYPE;
  v_cycle_start_date      BIL.CF_CYCLE_INTERVAL.cycle_start_date%TYPE;
  v_cycle_end_date        BIL.CF_CYCLE_INTERVAL.cycle_end_date%TYPE;
  v_cycle_id              BIL.CF_CYCLE_INTERVAL.cycle_id%TYPE;

  v_usg_duration          CRU.CF_CRU_RANGE.start_duration%TYPE;
  v_usg_amount            CRU.CF_CRU_RANGE.start_amount%TYPE;
  v_usg_quantity          NUMBER;
  v_total_usg_amount      CRU.CF_CRU_RANGE.start_amount%TYPE;
  v_total_usg_duration    CRU.CF_CRU_RANGE.start_duration%TYPE;
  v_total_usg_quantity    NUMBER;
  v_usg_data_eval         NUMBER;

  v_eval_type_code        CRU.CF_CRU_EVALUATE_USG.eval_criteria_type_code%TYPE; --<REE Control: 299 15/01/2013 15:00:00 Modification of CRU, to support Credit unit whit rollover>
  v_entity_log_id         CRU.TR_ENTITY_LOG.entity_log_id%TYPE;
  v_entity_log_status_id  CRU.TR_ENTITY_LOG_STATUS.entity_log_status_id%TYPE;

  v_date_execution     DATE  ;
  v_ag_action_prog_id  NUMBER;
  v_process_id         NUMBER;
  v_error_code_log     CRU.TR_ERROR_LOG.error_code%TYPE;
  v_error_msg_log      CRU.TR_ERROR_LOG.error_message%TYPE;

  ---- declared exceptions
  ERR_APP          EXCEPTION;
  ERR_CREDIT_LIMIT EXCEPTION;

  BEGIN

    v_tran_id := ITF.TX_PUBLIC_CRU.GET_TRAN_ID;

    IF c_cru_behavior_limit   IS NULL OR
       c_inactive             IS NULL OR
       c_true                 IS NULL OR
       c_false                IS NULL OR
       c_eval_amount_limit    IS NULL OR
       c_eval_duration_limit  IS NULL OR
       c_eval_quantity_limit  IS NULL OR
       c_async_stat_dlv       IS NULL OR
       c_async_stat_reg       IS NULL OR
       c_bill_user_id         IS NULL THEN
      v_error_code := 'CRU-0425';--Constants value is null.||Valor de las constantes es nulo.
      v_error_msg  := 'c_cru_behavior_limit: '   || c_cru_behavior_limit  || '|' ||
                       'c_inactive: '            || c_inactive            || '|' ||
                       'c_true: '                || c_true                || '|' ||
                       'c_false: '               || c_false               || '|' ||
                       'c_eval_amount_limit: '   || c_eval_amount_limit   || '|' ||
                       'c_eval_duration_limit: ' || c_eval_duration_limit || '|' ||
                       'c_eval_quantity_limit: ' || c_eval_quantity_limit || '|' ||
                       'c_async_stat_dlv: '      || c_async_stat_dlv      || '|' ||
                       'c_async_stat_reg: '      || c_async_stat_reg      || '|' ||
                       'c_bill_user_id: '        || c_bill_user_id                ;
      RAISE ERR_APP;
    END IF;

    v_error_code     := 'OK';
    v_error_msg      := '';
    v_date_execution := SYSDATE;

    --All instantiations for this credit unit
    FOR r_credit_limit_instan IN cur_credit_limits_instan(v_date_execution) LOOP
    BEGIN
      v_error_code_log := 'OK';
      v_error_msg_log  := '';

      --Verifies that evaluation_type_code is configured for process and is unique for a date process
      CRU.BL_UTILITIES.CHECK_EVAL_TYPE_FOR_PROCESS( pi_credit_unit_code => r_credit_limit_instan.credit_unit_code,
                                                    pi_domain_attribute => 'CREDIT_LIMIT_EVALUATION'             ,
                                                    pi_eval_date        => v_date_execution                      ,
                                                    pi_tran_id          => v_tran_id                             ,
                                                    po_eval_type_code   => v_eval_type_code                      ,
                                                    po_error_code       => v_error_code                          ,
                                                    po_error_msg        => v_error_msg                           );
      IF NVL(v_error_code,'NOK') <> 'OK' THEN
        RAISE ERR_CREDIT_LIMIT;
      END IF;

      --Obtain the cycle for entity_component_id --> billing_community_id
      CUS.TX_PUBLIC_CRU.GET_CYCLE_FOR_ENTITY_COMP_ID( pi_entity_comp_id => r_credit_limit_instan.entity_component_id,
                                                      pi_eval_date      => v_date_execution                         ,
                                                      pi_tran_id        => v_tran_id                                ,
                                                      po_cycle_code     => v_cycle_code                             ,
                                                      po_error_code     => v_error_code                             ,
                                                      po_error_msg      => v_error_msg                              );
      IF NVL(v_error_code,'NOK') <> 'OK' THEN
        RAISE ERR_CREDIT_LIMIT;
      END IF;

      --Obtains the data interval for this cycle, in execution date
      BIL.TX_PUBLIC_CRU.GET_DATA_INTERVAL( pi_cycle_code       => v_cycle_code      ,
                                           pi_date             => v_date_execution  ,
                                           pi_tran_id          => v_tran_id         ,
                                           po_cycle_id         => v_cycle_id        ,
                                           po_cycle_start_date => v_cycle_start_date,
                                           po_cycle_end_date   => v_cycle_end_date  ,
                                           po_error_code       => v_error_code      ,
                                           po_error_msg        => v_error_msg       );

      IF NVL(v_error_code,'NOK') <> 'OK' THEN
        RAISE ERR_CREDIT_LIMIT;
      END IF;

      v_total_usg_amount   := 0;
      v_total_usg_duration := 0;
      v_total_usg_quantity := 0;

      FOR r_evaluate_cru IN cur_evaluate_cru( r_credit_limit_instan.credit_unit_code,v_date_execution) LOOP

        --Usg provides data of traffic in that dates
        USG.TX_PUBLIC_CRU.GET_DATA_USAGE_RATED( pi_entity_id         => r_credit_limit_instan.entity_id       ,
                                                pi_entity_type_code  => r_credit_limit_instan.entity_type_code,
                                                pi_usage_type_code   => r_evaluate_cru.usage_type_code        ,
                                                pi_jurisdiction_code => r_evaluate_cru.jurisdiction_type_code ,
                                                pi_plan_code         => r_credit_limit_instan.plan_code       ,
                                                pi_component_code    => r_credit_limit_instan.component_code  ,
                                                pi_cycle_id          => v_cycle_id                            ,
                                                pi_start_date        => v_cycle_start_date                    ,
                                                pi_end_date          => v_date_execution                      ,
                                                pi_tran_id           => v_tran_id                             ,
                                                po_quantity_usage    => v_usg_quantity                        ,
                                                po_quantity_duration => v_usg_duration                        ,
                                                po_total_amount      => v_usg_amount                          ,
                                                po_error_code        => v_error_code                          ,
                                                po_error_msg         => v_error_msg                           );

        IF NVL(v_error_code,'NOK') <> 'OK' THEN
          RAISE ERR_CREDIT_LIMIT;
        END IF;

        v_total_usg_amount   := v_total_usg_amount   + v_usg_amount;
        v_total_usg_duration := v_total_usg_duration + v_usg_duration;
        v_total_usg_quantity := v_total_usg_quantity + v_usg_quantity;

      END LOOP;

      --Evaluate which usg data to use?
      IF v_eval_type_code = c_eval_amount_limit THEN
        v_usg_data_eval := v_total_usg_amount;
      ELSIF v_eval_type_code = c_eval_duration_limit THEN
        v_usg_data_eval := v_total_usg_duration;
      ELSIF v_eval_type_code = c_eval_quantity_limit THEN
        v_usg_data_eval := v_total_usg_quantity;
      ELSE
        v_error_code := 'CRU-0427'; --It does not configured this criteria evaluation type for this process.||No esta configurado este criterio de tipo de evaluación para este proceso.
        RAISE ERR_CREDIT_LIMIT;
      END IF;

      IF v_usg_data_eval >= r_credit_limit_instan.component_amount THEN

        --Creates a record for process in CRU.TR_ENTITY_LOG table
        CRU.TX_TR_ENTITY_LOG.CREATE_( pi_entity_type_code         => r_credit_limit_instan.entity_type_code   ,
                                      pi_entity_id                => r_credit_limit_instan.entity_id          ,
                                      pi_entity_type_code_process => r_credit_limit_instan.entity_type_code   ,
                                      pi_entity_id_process        => r_credit_limit_instan.entity_id          ,
                                      pi_credit_unit_id           => r_credit_limit_instan.credit_unit_id     ,
                                      pi_credit_unit_code         => r_credit_limit_instan.credit_unit_code   ,
                                      pi_client_id                => 0                                        ,
                                      pi_client_type_code         => 'NAP'                                    ,
                                      pi_client_segment_code      => 'NAP'                                    ,
                                      pi_community_id             => 0                                        ,
                                      pi_community_area_code      => 'NAP'                                    ,
                                      pi_ce_id                    => 0                                        ,
                                      pi_service_identifier       => NULL                                     ,
                                      pi_entity_plan_id           => 0                                        ,
                                      pi_entity_component_id      => r_credit_limit_instan.entity_component_id,
                                      pi_ce_type_code             => 'NAP'                                    ,
                                      pi_ce_area_code             => 'NAP'                                    ,
                                      pi_entity_ageing            => 'NAP'                                    ,
                                      pi_plan_category_id         => 0                                        ,
                                      pi_plan_category_code       => 'NAP'                                    ,
                                      pi_plan_code                => r_credit_limit_instan.plan_code          ,
                                      pi_component_code           => r_credit_limit_instan.component_code     ,
                                      pi_add_data1                => 'NA'                                     ,
                                      pi_add_data2                => 'NA'                                     ,
                                      pi_add_data3                => 'NA'                                     ,
                                      pi_add_data4                => 'NA'                                     ,
                                      pi_add_data5                => 'NA'                                     ,
                                      pi_cru_rate_id              => 0                                        ,
                                      pi_cru_range_id             => NULL                                     ,
                                      pi_usg_duration             => v_total_usg_duration                     ,
                                      pi_usg_amount               => v_total_usg_amount                       ,
                                      pi_quantity                 => v_total_usg_quantity                     ,
                                      pi_time_rate                => NULL                                     ,
                                      pi_cycle_id                 => v_cycle_id                               ,
                                      pi_start_billing_date       => v_cycle_start_date                       ,
                                      pi_end_billing_date         => v_date_execution                         ,
                                      pi_expiration_date          => v_date_execution                         ,
                                      pi_request_date             => v_date_execution                         ,
                                      pi_process_date             => v_date_execution                         ,
                                      pi_billing_type_code        => NULL                                     ,
                                      pi_billing_class_code       => NULL                                     ,
                                      --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                      pi_billing_tran_id          => v_tran_id                                ,
                                      --<ASV Control:299 Date:08/06/2012 11:27:30>
                                      pi_integration_other_system => r_credit_limit_instan.integration_other_system  , --<REE Control: 299 15/01/2013 15:00:00 Modification of CRU, to support Credit unit whit rollover>
                                      pi_unique_transaction_id    => seq_unique_transaction.nextval           , --<REE Control: 299 15/01/2013 15:00:00 Modification of CRU, to support Credit unit whit rollover>
                                      pi_start_tran_id            => v_tran_id                                ,
                                      pi_start_tran_date          => v_date_execution                         ,
                                      pi_asynchronous_status      => c_async_stat_dlv                         ,
                                      pi_asynchronous_answer      => NULL                                     ,
                                      pi_schedule_tran_id         => NULL                                     ,
                                      pi_response_id              => NULL                                     ,
                                      po_entity_log_id            => v_entity_log_id                          ,
                                      po_error_code               => v_error_code                             ,
                                      po_error_msg                => v_error_msg                              );

          IF NVL(v_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_CREDIT_LIMIT;
          END IF;

          --Calls API of INTEGRATION for SUSPENSION of entity_component
          CUS.TX_PUBLIC_CRU.SUSP_COMPONENT( pi_entity_component_id => r_credit_limit_instan.entity_component_id,
                                            pi_programmed_date     => v_date_execution                         ,
                                            pi_user_code           => c_bill_user_id                           ,
                                            pi_tran_id             => v_tran_id                                ,
                                            po_ag_action_prog_id   => v_ag_action_prog_id                      ,
                                            po_process_id          => v_process_id                             ,
                                            po_error_code          => v_error_code_log                         ,
                                            po_error_msg           => v_error_msg_log                          );

          --It Saves response of INTEGRATION procedure
          CRU.TX_TR_ENTITY_LOG_STATUS.CREATE_( pi_entity_log_id        => v_entity_log_id       ,
                                               pi_asynchronous_status  => c_async_stat_reg      ,
                                               pi_asynchronous_answer  => v_error_code_log      ,
                                               pi_asynchronous_date    => SYSDATE               ,
                                               pi_schedule_tran_id     => NULL                  ,
                                               pi_response_id          => v_ag_action_prog_id   ,
                                               pi_tran_id              => v_tran_id             ,
                                               po_entity_log_status_id => v_entity_log_status_id,
                                               po_error_code           => v_error_code          ,
                                               po_error_msg            => v_error_msg           );
          COMMIT;
          IF NVL(v_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_CREDIT_LIMIT;
          END IF;

          IF NVL(v_error_code_log,'NOK') <> 'OK' THEN
            v_error_code := v_error_code_log;
            v_error_msg  := v_error_msg_log;
            ROLLBACK;
            RAISE ERR_CREDIT_LIMIT;
          END IF;

      END IF;

    EXCEPTION
      WHEN ERR_CREDIT_LIMIT THEN
      -- Initiate log variables
      v_param_in := ---------- variable parameters ------------------
                     'entity_credit_unit_id: '     || r_credit_limit_instan.entity_credit_unit_id                            || '|' ||
                     'entity_type_code: '          || r_credit_limit_instan.entity_type_code                                 || '|' ||
                     'entity_id: '                 || r_credit_limit_instan.entity_id                                        || '|' ||
                     'credit_unit_code: '          || r_credit_limit_instan.credit_unit_code                                 || '|' ||
                     'credit_unit_type_code: '     || r_credit_limit_instan.credit_unit_type_code                            || '|' ||
                     'behavior_type_code: '        || r_credit_limit_instan.behavior_type_code                               || '|' ||
                     'entity_component_id: '       || r_credit_limit_instan.entity_component_id                              || '|' ||
                     'component_code: '            || r_credit_limit_instan.component_code                                   || '|' ||
                     'plan_code: '                 || r_credit_limit_instan.plan_code                                        || '|' ||
                     'credit_limit_amount: '       || r_credit_limit_instan.component_amount                                 || '|' ||
                     'start_date: '                || TO_CHAR(r_credit_limit_instan.start_date,'DD/MM/YYYY HH24:MI:SS')      || '|' ||
                     'end_date: '                  || TO_CHAR(r_credit_limit_instan.end_date,'DD/MM/YYYY HH24:MI:SS')        || '|' ||
                     'activated_date: '            || TO_CHAR(r_credit_limit_instan.activated_date,'DD/MM/YYYY HH24:MI:SS')  || '|' ||
                     'deactivated_date: '          || TO_CHAR(r_credit_limit_instan.deactivated_date,'DD/MM/YYYY HH24:MI:SS')|| '|' ||
                     'tran_id: '                   || v_tran_id                                                              || '|' ||
                     'process_date: '              || TO_CHAR(v_date_execution, 'DD/MM/YYYY HH24:MI:SS')                             ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_tran_id       => v_tran_id                                                    ,
                                      pi_error_code    => v_error_code                                                 ,
                                      pi_error_msg     => v_error_msg                                                  ,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));
    END;
    END LOOP;

  EXCEPTION
    WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in := ---------- variable parameters ------------------
                     'v_tran_id: '       || v_tran_id                                         || '|' ||
                     'v_process_date: '  || TO_CHAR(v_date_execution, 'DD/MM/YYYY HH24:MI:SS')         ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_tran_id       => v_tran_id                                                    ,
                                      pi_error_code    => v_error_code                                                 ,
                                      pi_error_msg     => v_error_msg                                                  ,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));

    WHEN OTHERS THEN
      -- Initiate log variables
      v_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      v_error_code := 'CRU-0428'; --Critical error.||Error critico.
      v_param_in := ---------- variable parameters ------------------
                     'v_tran_id: '       || v_tran_id                                          || '|' ||
                     'v_process_date: '  || TO_CHAR(v_date_execution, 'DD/MM/YYYY HH24:MI:SS')         ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_tran_id       => v_tran_id                                                    ,
                                      pi_error_code    => v_error_code                                                 ,
                                      pi_error_msg     => v_error_msg                                                  ,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));

  END;

  /*
  It LAUNCHES a job which will run every X time. receiving parameter value
  %Date          08/09/2011 10:00:00
  %Control       20281
  %Author        "Marleny Patsi Tapia"
  %Version       1.0.0
      %param         pi_tran_id              Transaction Identifier
      %param         po_error_code           Output showing one of the next results:
                                             {*} OK - If procedure executed satisfactorily
                                             {*} XXX-#### - Error code if any error found
      %param         po_error_msg            Output showing the error message if any error found
  */

  PROCEDURE LAUNCH_JOB_PROC_CREDIT_LIMIT( pi_tran_id    IN  CRU.TR_ERROR_LOG.tran_id%TYPE,
                                          po_error_code OUT VARCHAR2                     ,
                                          po_error_msg  OUT VARCHAR2                     ) IS

  PRAGMA AUTONOMOUS_TRANSACTION;

  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.LAUNCH_JOB_PROC_CREDIT_LIMIT';
    v_param_in          VARCHAR2(4000);

    c_time_exe_credit_limit CONSTANT NUMBER := ITF.TX_PUBLIC_CRU.GET_PARAMETER_NUM(c_application_code,'TIME_MIN_EXECUTE_PROC_CREDIT_LIMIT', SYSDATE );

  -- Variables procedure
    v_call_process   VARCHAR2(4000);
    v_job_number     NUMBER;
    v_quantity_jobs  NUMBER;

  -- Declare exceptions
    ERR_APP EXCEPTION;

  BEGIN

    IF c_time_exe_credit_limit IS NULL THEN
      po_error_code := 'CRU-0429';--The Constant value is null||El valor de la cosntante es null
      po_error_msg  :=  'c_time_exe_credit_limit: '  || c_time_exe_credit_limit   ;
      RAISE ERR_APP;
    END IF;

    po_error_code := 'OK';
    po_error_msg := '';

    IF pi_tran_id IS NULL THEN
      po_error_code := 'CRU-0430'; --Mandatory parameter is null||Parametro obligatorio es null
      RAISE ERR_APP;
    END IF;

    v_call_process := 'CRU.BL_CREDIT_LIMIT_PROCESS.EXECUTE_MASIVE;';

    SELECT COUNT(job)
      INTO v_quantity_jobs
      FROM ALL_JOBS
     WHERE UPPER(what) = v_call_process
       AND next_date <= SYSDATE + (c_time_exe_credit_limit/1440)
       AND broken = 'N';

    IF v_quantity_jobs > 1 THEN
      po_error_code := 'CRU-0431'; --Too many jobs are executing in this moment.||Demasiados jobs se estan ejecutando en este momento.
      RAISE ERR_APP;
    ELSIF v_quantity_jobs = 1 THEN
      po_error_code := 'CRU-0432'; --Already a job exists in execution for this process.||Ya existe un job en ejecución para este proceso.
      RAISE ERR_APP;
    ELSE--0

      SELECT COUNT(job), MAX(job)
        INTO v_quantity_jobs, v_job_number
        FROM ALL_JOBS
       WHERE UPPER(what) = v_call_process
         AND broken = 'Y';

      IF v_quantity_jobs > 1 THEN
        po_error_code := 'CRU-0433'; --Too many jobs are broken. || Demasiados jobs estan como broken.
        RAISE ERR_APP;
      ELSIF v_quantity_jobs = 1 THEN --1 JOB broken lanzarlo
        SYS.DBMS_JOB.BROKEN( job    => v_job_number,
                             broken => FALSE      );
        COMMIT;
      ELSE-- = 0 no hay jobs lanzar uno nuevo
        SYS.DBMS_JOB.SUBMIT( JOB       => v_job_number  ,
                             WHAT      => v_call_process,
                             NEXT_DATE => SYSDATE  + c_time_exe_credit_limit/1440      ,
                             INTERVAL  => 'SYSDATE+'||c_time_exe_credit_limit||'/1440' );
        COMMIT;

      END IF;

    END IF;

  EXCEPTION
    WHEN ERR_APP THEN

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_tran_id      => pi_tran_id                                                      ,
                                      pi_error_code   => po_error_code                                                   ,
                                      pi_error_msg    => po_error_msg                                                    ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));

    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_code := 'CRU-0434';--Critical error.||Error critico.
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      v_param_in    :=---------- variable parameters ------------------
                      'process_date: '              || TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS') ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_tran_id      => pi_tran_id                                                      ,
                                      pi_error_code   => po_error_code                                                   ,
                                      pi_error_msg    => po_error_msg                                                    ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));

  END;

END BL_CREDIT_LIMIT_PROCESS;
/

