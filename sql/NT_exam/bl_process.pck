CREATE OR REPLACE PACKAGE CRU.BL_PROCESS IS
  /**************************************************************************
  Implements utility procedures and functions for the billing process
  %Company         Trilogy Software Bolivia
  %System          Omega Convergent Billing
  %Date            08/11/2010 15:24:07
  %Control         60079
  %Author          "Abel Soto"
  %Version         1.0.0
  
  **************************************************************************/

  FUNCTION GET_VERSION RETURN VARCHAR2;

  -- Process CREDIT UNIT PROCESS BILLING receiving all parameters values
  PROCEDURE CREDIT_UNIT_PROCESS_BILLING( pi_telco_code          IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE        ,
                                         pi_entity_type_code    IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE   ,
                                         pi_entity_id           IN  CRU.TR_ENTITY_LOG.entity_id%TYPE          ,
                                         pi_cycle_id            IN  CRU.TR_ENTITY_LOG.cycle_id%TYPE           ,
                                         pi_cycle_start_date    IN  DATE                                      ,
                                         pi_cycle_end_date      IN  DATE                                      ,
                                         pi_billing_start_date  IN  CRU.TR_ENTITY_LOG.start_billing_date%TYPE ,
                                         pi_billing_end_date    IN  CRU.TR_ENTITY_LOG.end_billing_date%TYPE   ,
                                         pi_billing_type_code   IN  CRU.TR_ENTITY_LOG.billing_type_code %TYPE ,
                                         pi_billing_class_code  IN  CRU.TR_ENTITY_LOG.billing_class_code %TYPE,
                                         pi_billing_tran_id     IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE     ,
                                         pi_tran_date           IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE   ,
                                         po_error_code          OUT VARCHAR2                                  ,
                                         po_error_msg           OUT VARCHAR2                                  );

  --Process CREDIT UNIT PROCESS GENERIC receiving all parameters values
  PROCEDURE CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code                IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE             ,
                                         pi_entity_type_code          IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE        ,
                                         pi_entity_id                 IN  CRU.TR_ENTITY_LOG.entity_id%TYPE               ,
                                         pi_entity_type_code_process  IN  CRU.TR_ENTITY_LOG.entity_type_code_process%TYPE,
                                         pi_entity_id_process         IN  CRU.TR_ENTITY_LOG.entity_id_process%TYPE       ,
                                         pi_entity_component_id       IN  CRU.TR_ENTITY_LOG.entity_component_id%TYPE     ,
                                         pi_client_id                 IN  CRU.TR_ENTITY_LOG.client_id%TYPE               ,
                                         pi_community_id              IN  CRU.TR_ENTITY_LOG.community_id%TYPE            ,
                                         pi_cen_id                    IN  CRU.TR_ENTITY_LOG.ce_id%TYPE                   ,
                                             -- Tariff Keys
                                         pi_client_type_code          IN  CRU.TR_ENTITY_LOG.client_type_code%TYPE        ,
                                         pi_client_segment_code       IN  CRU.TR_ENTITY_LOG.client_segment_code%TYPE     ,
                                         pi_community_area_code       IN  CRU.TR_ENTITY_LOG.community_area_code%TYPE     ,
                                         pi_ce_type_code              IN  CRU.TR_ENTITY_LOG.ce_type_code%TYPE            ,
                                         pi_ce_area_code              IN  CRU.TR_ENTITY_LOG.ce_area_code%TYPE            ,
                                         pi_entity_ageing             IN  CRU.TR_ENTITY_LOG.entity_ageing%TYPE           ,
                                         pi_plan_category_code        IN  CRU.TR_ENTITY_LOG.plan_category_code%TYPE      ,
                                         pi_plan_category_id          IN  CRU.TR_ENTITY_LOG.plan_category_id%TYPE        ,
                                         pi_plan_code                 IN  CRU.TR_ENTITY_LOG.plan_code%TYPE               ,
                                         pi_entity_plan_id            IN  CRU.TR_ENTITY_LOG.entity_plan_id%TYPE          ,
                                         pi_component_code            IN  CRU.TR_ENTITY_LOG.component_code%TYPE          ,
                                         pi_add_data1                 IN  CRU.TR_ENTITY_LOG.add_data1%TYPE               ,
                                         pi_add_data2                 IN  CRU.TR_ENTITY_LOG.add_data2%TYPE               ,
                                         pi_add_data3                 IN  CRU.TR_ENTITY_LOG.add_data3%TYPE               ,
                                         pi_add_data4                 IN  CRU.TR_ENTITY_LOG.add_data4%TYPE               ,
                                         pi_add_data5                 IN  CRU.TR_ENTITY_LOG.add_data5%TYPE               ,
                                         --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                         pi_component_amount          IN  CRU.TR_ENTITY_CREDIT_UNIT.component_amount%TYPE,
                                         --<ASV Control: 299 25/04/2012 17:02:00>
                                         pi_start_date                IN  DATE                                           ,
                                         pi_end_date                  IN  DATE                                           ,
                                         ---cycle data
                                         pi_cycle_id                  IN  CRU.TR_ENTITY_LOG.cycle_id%TYPE                ,
                                         pi_cycle_start_date          IN  DATE                                           ,
                                         pi_cycle_end_date            IN  DATE                                           ,
                                         pi_credit_unit_code          IN  CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE       ,
                                         pi_billing_start_date        IN  DATE                                           ,
                                         pi_billing_end_date          IN  DATE                                           ,
                                         pi_billing_type_code         IN  VARCHAR2                                       ,
                                         pi_billing_class_code        IN  VARCHAR2                                       ,
                                         --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                         pi_billing_tran_id           IN CRU.TR_ENTITY_LOG.billing_tran_id%TYPE          ,
                                         --<ASV Control:299 Date:08/06/2012 11:27:30>
                                         pi_tran_id                   IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE          ,
                                         pi_tran_date                 IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE        ,
                                         pi_asynchronous_status       IN  CRU.TR_ENTITY_LOG.ASYNCHRONOUS_STATUS%TYPE     ,
                                         po_error_code                OUT VARCHAR2                                       ,
                                         po_error_msg                 OUT VARCHAR2                                       );



 -- Process PROCESS CREDIT_UNIT_PROCESS ESB receiving all parameters values
  PROCEDURE CREDIT_UNIT_PROCESS_ESB( pi_telco_code          IN  CRU.TR_ENTITY_LOG.telco_code%TYPE             ,
                                     pi_entity_type_code    IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE       ,
                                     pi_entity_id           IN  CRU.TR_ENTITY_LOG.entity_id%TYPE              ,
                                     pi_entity_component_id IN  CRU.TR_ENTITY_LOG.entity_component_id%TYPE    ,
                                     pi_client_id           IN  CRU.TR_ENTITY_LOG.client_id%TYPE              ,
                                     pi_community_id        IN  CRU.TR_ENTITY_LOG.community_id%TYPE           ,
                                     pi_cen_id              IN  CRU.TR_ENTITY_LOG.ce_id%TYPE                  ,
                                         -- Tariff Keys
                                     pi_client_type_code    IN  CRU.TR_ENTITY_LOG.client_type_code%TYPE       ,
                                     pi_client_segment_code IN  CRU.TR_ENTITY_LOG.client_segment_code%TYPE    ,
                                     pi_community_area_code IN  CRU.TR_ENTITY_LOG.community_area_code%TYPE    ,
                                     pi_ce_type_code        IN  CRU.TR_ENTITY_LOG.ce_type_code%TYPE           ,
                                     pi_ce_area_code        IN  CRU.TR_ENTITY_LOG.ce_area_code%TYPE           ,
                                     pi_entity_ageing       IN  CRU.TR_ENTITY_LOG.entity_ageing%TYPE          ,
                                     pi_plan_category_code  IN  CRU.TR_ENTITY_LOG.plan_category_code%TYPE     ,
                                     pi_plan_category_id    IN  CRU.TR_ENTITY_LOG.plan_category_id%TYPE       ,  --value_id of plan_category_code
                                     pi_plan_code           IN  CRU.TR_ENTITY_LOG.plan_code%TYPE              ,
                                     pi_entity_plan_id      IN  CRU.TR_ENTITY_LOG.entity_plan_id%TYPE         ,   --value_id of plan_code
                                     pi_component_code      IN  CRU.TR_ENTITY_LOG.component_code%TYPE         ,
                                     pi_add_data1           IN  CRU.TR_ENTITY_LOG.add_data1%TYPE              ,
                                     pi_add_data2           IN  CRU.TR_ENTITY_LOG.add_data2%TYPE              ,
                                     pi_add_data3           IN  CRU.TR_ENTITY_LOG.add_data3%TYPE              ,
                                     pi_add_data4           IN  CRU.TR_ENTITY_LOG.add_data4%TYPE              ,
                                     pi_add_data5           IN  CRU.TR_ENTITY_LOG.add_data5%TYPE              ,
                                     pi_activated_date      IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE       ,
                                     pi_credit_unit_code    IN  CRU.CF_CREDIT_UNIT.CREDIT_UNIT_CODE%TYPE      ,
                                     --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                     pi_component_amount    IN  CRU.TR_ENTITY_CREDIT_UNIT.component_amount%TYPE,
                                     --<ASV Control: 299 25/04/2012 17:02:00>
                                     pi_tran_id             IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE          ,
                                     pi_tran_date           IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE        ,
                                     po_error_code          OUT VARCHAR2                                       ,
                                     po_error_msg           OUT VARCHAR2                                       );


  --Process PROCESS CREDIT_UNIT_PROCESS_GENERIC receiving all parameters values
  PROCEDURE PROCESS_GENERIC_FREE( pi_telco_code          IN  CRU.TR_ENTITY_LOG.telco_code%TYPE         ,
                                  pi_entity_type_code    IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE   ,
                                  pi_entity_id           IN  CRU.TR_ENTITY_LOG.entity_id%TYPE          ,
                                  pi_entity_component_id IN  CRU.TR_ENTITY_LOG.entity_component_id%TYPE,
                                  pi_client_id           IN  CRU.TR_ENTITY_LOG.client_id%TYPE          ,
                                  pi_community_id        IN  CRU.TR_ENTITY_LOG.community_id%TYPE       ,
                                  pi_cen_id              IN  CRU.TR_ENTITY_LOG.ce_id%TYPE              ,
                                      -- Tariff Keys
                                  pi_client_type_code    IN  CRU.TR_ENTITY_LOG.client_type_code%TYPE   ,
                                  pi_client_segment_code IN  CRU.TR_ENTITY_LOG.client_segment_code%TYPE,
                                  pi_community_area_code IN  CRU.TR_ENTITY_LOG.community_area_code%TYPE,
                                  pi_ce_type_code        IN  CRU.TR_ENTITY_LOG.ce_type_code%TYPE       ,
                                  pi_ce_area_code        IN  CRU.TR_ENTITY_LOG.ce_area_code%TYPE       ,
                                  pi_entity_ageing       IN  CRU.TR_ENTITY_LOG.entity_ageing%TYPE      ,
                                  pi_plan_category_code  IN  CRU.TR_ENTITY_LOG.plan_category_code%TYPE ,
                                  pi_plan_category_id    IN  CRU.TR_ENTITY_LOG.plan_category_id%TYPE   ,  --value_id of plan_category_code
                                  pi_plan_code           IN  CRU.TR_ENTITY_LOG.plan_code%TYPE          ,
                                  pi_entity_plan_id      IN  CRU.TR_ENTITY_LOG.entity_plan_id%TYPE     ,   --value_id of plan_code
                                  pi_component_code      IN  CRU.TR_ENTITY_LOG.component_code%TYPE     ,
                                  pi_add_data1           IN  CRU.TR_ENTITY_LOG.add_data1%TYPE          ,
                                  pi_add_data2           IN  CRU.TR_ENTITY_LOG.add_data2%TYPE          ,
                                  pi_add_data3           IN  CRU.TR_ENTITY_LOG.add_data3%TYPE          ,
                                  pi_add_data4           IN  CRU.TR_ENTITY_LOG.add_data4%TYPE          ,
                                  pi_add_data5           IN  CRU.TR_ENTITY_LOG.add_data5%TYPE          ,
                                  pi_activated_date      IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE   ,
                                  pi_tran_id             IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE     ,
                                  pi_tran_date           IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE   ,
                                  po_error_code          OUT VARCHAR2                                  ,
                                  po_error_msg           OUT VARCHAR2                                  );

END BL_PROCESS;
/

CREATE OR REPLACE PACKAGE BODY CRU.BL_PROCESS IS
  /**************************************************************************
  Implements utility procedures and functions for the billing process
  %Company         Trilogy Software Bolivia
  %System          Omega Convergent Billing
  %Date            08/11/2010 15:24:07
  %Control         60079
  %Author          "Abel Soto"
  %Version         1.0.0
  **************************************************************************/

  VERSION CONSTANT VARCHAR2(15) := '3.0.0';

  v_package VARCHAR2(100) := 'CRU.BL_PROCESS';

  c_application_code   CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_APPLICATION_CODE('APPLICATION_CRU',SYSDATE)  ;
  c_inactive           CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC', c_application_code, 'SYSTEM_STATUS_INACTIVE',SYSDATE);
  c_active             CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC', c_application_code, 'SYSTEM_STATUS_ACTIVE',SYSDATE)  ;
  c_true               CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC', c_application_code, 'VALUE_BOOLEAN_TRUE',SYSDATE)  ;
  c_false              CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC', c_application_code, 'VALUE_BOOLEAN_FALSE',SYSDATE)  ;
  c_cru_generic        CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC', c_application_code, 'GENERIC_CREDIT_UNIT',SYSDATE);
  c_behavior_free      CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC', c_application_code, 'CRU_BEHAVIOR_TYPE_FREE',SYSDATE);
  c_delivered          CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC', c_application_code, 'INITIAL_INTEGRATION_STATUS', SYSDATE);
  c_completed          CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC', c_application_code, 'FINAL_INTEGRATION_STATUS', SYSDATE);

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
  Process CREDIT UNIT PROCESS BILLING receiving all parameters values
  %Date          08/11/2010 10:24:07
  %Control       60083
  %Author        "Abel Soto"
  %Version       1.0.0
      %param         pi_telco_code              Telco Code
      %param         pi_entity_type_code        Entity type code
      %param         pi_entity_id               Entity identifier
      %param         pi_cycle_id                Cycle identifier
      %param         pi_cycle_start_date        Cycle start date
      %param         pi_cycle_end_date          Cycle end date
      %param         pi_billing_start_date      Billing start date
      %param         pi_billing_end_date        Billing end date
      %param         pi_billing_type_code       Billing type code
      %param         pi_billing_class_code      Billing class code
      %param         pi_billing_tran_id         Billing tran identifier
      %param         pi_tran_date               Transaction date
      %param         po_error_code              Output showing one of the next results:
                                                {*} OK - If procedure executed satisfactorily
                                                {*} XXX-#### - Error code if any error found
      %param         po_error_msg               Output showing the error message if any error found
      %raises        ERR_APP                    Application level error
      %Changes
        <hr>
          {*}Date       17/04/2012 10:00:00
          {*}Control    299
          {*}Author     "Abel Soto Vera"
          {*}Note       Change in the process of integration with ESB, now being notified that there is credit units, and not send the CRU's.      
  
        <hr>
          {*}Date       2012-04-16
          {*}Control    299.1484
          {*}Author     Guido R. Guillen Roman
          {*}Note       He add new parameter pi_community_type_code when call store procedure GET_RECORDS_COMMUNITY  
        <hr>
          {*}Date       25/04/2012 17:02:00
          {*}Control    299
          {*}Author     "Abel Soto Vera"
          {*}Note       Modify procedure for included parameter type XMLtype for overwrite data of the billing elements.
        <hr>
          {*}Date       18/05/2012 17:27:30
          {*}Control    299
          {*}Author     "Abel Soto Vera"
          {*}Note       Was removed fields Credit_limit_amount, credit_limit_currency_code and all functionality with these fields
        <hr>
          {*}Date       08/06/2012 11:27:30
          {*}Control    299
          {*}Author     "Abel Soto Vera"
          {*}Note       Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity
        <hr>
          {*}Date       12/11/2012 10:27:30
          {*}Control    299
          {*}Author     "Abel Soto Vera"
          {*}Note       Update process CRUS genericas, for the consulting first if exists rate for the CRU before processing
        <hr>
          {*}Date       26/09/2013 11:00:00
          {*}Control    160121 
          {*}Author     "Abel Soto Vera"
          {*}Note       Billing - Multi operator custom (Change Management)
  */

  PROCEDURE CREDIT_UNIT_PROCESS_BILLING( pi_telco_code          IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE        ,
                                         pi_entity_type_code    IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE   ,
                                         pi_entity_id           IN  CRU.TR_ENTITY_LOG.entity_id%TYPE          ,
                                         pi_cycle_id            IN  CRU.TR_ENTITY_LOG.cycle_id%TYPE           ,
                                         pi_cycle_start_date    IN  DATE                                      ,
                                         pi_cycle_end_date      IN  DATE                                      ,
                                         pi_billing_start_date  IN  CRU.TR_ENTITY_LOG.start_billing_date%TYPE ,
                                         pi_billing_end_date    IN  CRU.TR_ENTITY_LOG.end_billing_date%TYPE   ,
                                         pi_billing_type_code   IN  CRU.TR_ENTITY_LOG.billing_type_code %TYPE ,
                                         pi_billing_class_code  IN  CRU.TR_ENTITY_LOG.billing_class_code %TYPE,
                                         pi_billing_tran_id     IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE     ,
                                         pi_tran_date           IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE   ,
                                         po_error_code          OUT VARCHAR2                                  ,
                                         po_error_msg           OUT VARCHAR2                                  ) IS

    -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.CREDIT_UNIT_PROCESS_BILLING';
    v_param_in          VARCHAR2(4000)                                              ;

    --constant
    c_billing_real              CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'BILLING_REAL',SYSDATE)  ;
    c_entity_type_client        CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'ENTITY_TYPE_CLIENT',pi_billing_end_date)        ;
    c_entity_type_community     CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'ENTITY_TYPE_COMMUNITY',pi_billing_end_date)        ;
    c_entity_type_comsup_entity CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'ENTITY_TYPE_COMSUPTION_ENTITY',pi_billing_end_date);
    -- <GGR 24/04/2012 17:02:00 CONTROL:299.1484 Constant declaration for call method GET_RECORDS_COMMUNITY 
    c_community_type_billing    CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE  := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'COM_TYPE_BILLING',SYSDATE);
    -- <GGR 24/04/2012>
    --declare type
    v_credits_unit_assign ITF.TYPE_COL_CREDIT_UNIT;

    ---CUSOR de instanciaciones de CRUs.
    CURSOR tcur_entity( v_entity_id        CRU.TR_ENTITY_CREDIT_UNIT.entity_id%TYPE,
                        v_entity_type_code CRU.TR_ENTITY_CREDIT_UNIT.entity_type_code%TYPE,
                        v_telco_code       CRU.CF_CREDIT_UNIT.telco_code%TYPE             ) IS
    --<ASV Control:299 Date:30/05/2012 11:27:30 Change in the logic of the process of credit limit>
    SELECT ecre.*
      FROM CRU.TR_ENTITY_CREDIT_UNIT ecre, CRU.CF_CREDIT_UNIT cru
     WHERE ecre.credit_unit_code  = cru.credit_unit_code
       AND ecre.telco_code        = v_telco_code
       AND ecre.telco_code        = cru.telco_code
       AND cru.behavior_type_code = c_behavior_free
       AND ecre.entity_id         = v_entity_id
       AND ecre.entity_type_code  = v_entity_type_code
       AND ecre.status           <> c_inactive
       AND (ecre.start_date <= pi_billing_end_date AND pi_billing_start_date <= ecre.end_date )
     ORDER BY ecre.entity_type_code, ecre.entity_id, ecre.entity_component_id, ecre.activated_date, ecre.start_date;
     --<ASV Control:299 Date:30/05/2012 11:27:30>

      --Para listar todos los CRUs GENERIC and FREE
    CURSOR tcur_credit_unit_free( v_date_cru_generic DATE, v_telco_code CRU.CF_CREDIT_UNIT.telco_code%TYPE ) IS
    SELECT *
      FROM CRU.CF_CREDIT_UNIT
     WHERE telco_code            = pi_telco_code
       AND credit_unit_type_code = c_cru_generic
       AND behavior_type_code    = c_behavior_free
       AND status <> c_inactive
       AND v_date_cru_generic BETWEEN start_date AND end_date;

   -- Own procedure variables
    v_list_community           CUS.TYPE_COL_CLIENT_COMMUNITY   ;
    v_list_consumption_entity  CUS.TYPE_COL_COMMUNITY_CONS_ENT ;
    v_list_entity_component    CUS.TYPE_COL_ENTITY_COMP_BILLING;
    v_tr_entity                CRU.TR_ENTITY_LOG%ROWTYPE;
    v_check_client_type        ITF.CF_PARAMETRIC.parametric_code%TYPE := 0;
    v_entity_component_id      NUMBER;
    --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
    v_tran_id                  CRU.TR_ENTITY_LOG.start_tran_id%TYPE;
    --<ASV Control:299 Date:08/06/2012 11:27:30>
    --<ASV Control:299 Date:12/11/2012 10:27:30 Update process CRUS genericas, for the consulting first if exists rate for the CRU before processing>
    v_rate_id        CRU.CF_CRU_RATE.cru_rate_id%TYPE;
    v_rate_quantity  CRU.CF_CRU_RATE.quantity%TYPE;
    --<ASV Control:299 Date:12/11/2012 10:27:30>    
    ERR_APP EXCEPTION;

  BEGIN
    po_error_code := 'OK';
    po_error_msg  := ''  ;

    IF c_inactive IS NULL OR
       c_active   IS NULL OR
       c_true     IS NULL OR
       c_false    IS NULL THEN
       po_error_code := 'CRU-0001';--The Constant value is null||El valor de la constante es null
       po_error_msg  := 'c_inactive: '  || c_inactive  || '|' ||
                        'c_active: '    || c_active    || '|' ||
                        'c_true: '      || c_true      || '|' ||
                        'c_false: '     || c_false             ;
      RAISE ERR_APP;
    END IF;
    
     -- Validation of the consistency of data
    IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN('TELCO_GENERIC', 'TELCO_OPERATIONS_CODE', pi_telco_code, pi_billing_end_date) IS NULL THEN
      po_error_code:= 'CRU-0000'; --Domain telco code operation value is null||Valor de dominio telco code operation es nulo
      po_error_msg:= 'pi_telco_code: ' || pi_telco_code ;
      RAISE ERR_APP;
    END IF; 
     
    IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN(pi_telco_code, 'ENTITY_TYPE', pi_entity_type_code  , pi_billing_end_date ) IS NULL OR
       ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN(pi_telco_code, 'BILL_CLASS' , pi_billing_class_code, pi_billing_end_date ) IS NULL OR
       ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN(pi_telco_code, 'BILL_TYPE'  , pi_billing_type_code , pi_billing_end_date ) IS NULL THEN
      po_error_code := 'CRU-0002';--Domain language value is null||Valor de dominio language es nulo
      po_error_msg  := 'pi_entity_type_code: '   || pi_entity_type_code   || '|' ||
                       'pi_billing_class_code: ' || pi_billing_class_code || '|' ||
                       'pi_billing_type_code: '  || pi_billing_type_code          ;
      RAISE ERR_APP;
    END IF;

    IF pi_telco_code         IS NULL OR 
       pi_entity_type_code   IS NULL OR
       pi_entity_id          IS NULL OR
       pi_cycle_id           IS NULL OR
       pi_cycle_start_date   IS NULL OR
       pi_cycle_end_date     IS NULL OR
       pi_billing_start_date IS NULL OR
       pi_billing_end_date   IS NULL OR
       pi_billing_type_code  IS NULL OR
       pi_billing_class_code IS NULL OR
       pi_billing_tran_id    IS NULL THEN
      po_error_code := 'CRU-0003';--Mandatory parameter is null||Parametro obligatorio es null
      RAISE ERR_APP;
    END IF;

    IF pi_billing_end_date < pi_billing_start_date THEN
      po_error_code := 'CRU-0004';--Billing range dates are not valid||El rango de fechas de facturacion no es valido
      RAISE ERR_APP;
    END IF;

    po_error_code := 'OK';
    po_error_msg  := ''  ;

    ----------bussiness logic-----------------------

    IF pi_entity_type_code = c_entity_type_comsup_entity THEN

      --Asignacion de CRUs a instanciaciones..
      FOR v_entity IN tcur_entity(pi_entity_id, pi_entity_type_code, pi_telco_code)LOOP

        IF v_entity.entity_type_code = pi_entity_type_code AND

          v_entity.entity_id        = pi_entity_id        THEN
          v_entity_component_id := v_entity.entity_component_id; --para ayudar en los datos de las CRUs genericas

          /*obtenemos los keys*/
          CUS.TX_PUBLIC_CRU.GET_TARIFF_KEY_ALL( pi_telco_code           => pi_telco_code                  ,
                                                pi_entity_type_code     => pi_entity_type_code            ,
                                                pi_entity_id            => pi_entity_id                   ,
                                                pi_date                 => pi_billing_end_date            , --OJO fecha de entrada
                                                pi_entity_component_id  => v_entity.entity_component_id   ,---se manda un dato null
                                                pi_tran_id              => pi_billing_tran_id             ,
                                                po_client_id            => v_tr_entity.client_id          ,
                                                po_community_id         => v_tr_entity.community_id       ,
                                                po_cen_id               => v_tr_entity.ce_id              ,
                                                -- Tariff Keys
                                                po_client_type_code     => v_tr_entity.client_type_code   ,
                                                po_client_segment_code  => v_tr_entity.client_segment_code,
                                                po_community_area_code  => v_tr_entity.community_area_code,
                                                po_ce_type_code         => v_tr_entity.ce_type_code       ,
                                                po_ce_area_code         => v_tr_entity.ce_area_code       ,
                                                po_entity_ageing        => v_tr_entity.entity_ageing      ,
                                                po_plan_category_code   => v_tr_entity.plan_category_code ,
                                                po_plan_category_id     => v_tr_entity.plan_category_id   ,  --value_id of plan_category_code
                                                po_plan_code            => v_tr_entity.plan_code          ,
                                                po_entity_plan_id       => v_tr_entity.entity_plan_id     ,   --value_id of plan_code
                                                po_component_code       => v_tr_entity.component_code     ,
                                                po_add_data1            => v_tr_entity.add_data1          ,
                                                po_add_data2            => v_tr_entity.add_data2          ,
                                                po_add_data3            => v_tr_entity.add_data3          ,
                                                po_add_data4            => v_tr_entity.add_data4          ,
                                                po_add_data5            => v_tr_entity.add_data5          ,
                                                -- Tariff Keys END
                                                po_error_code           => po_error_code                  ,
                                                po_error_msg            => po_error_msg                   );

          IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
          END IF;

          /* Verificamos si el cliente es corporativo*/
          CRU.BL_UTILITIES.CHECK_VALID_CLIENT_TYPE( pi_telco_code       => pi_telco_code               ,
                                                    pi_client_type_code => v_tr_entity.client_type_code,
                                                    pi_date             =>  pi_billing_end_date        ,
                                                    pi_tran_id          => pi_billing_tran_id          ,
                                                    po_chekeable        => v_check_client_type         ,
                                                    po_error_code       => po_error_code               ,
                                                    po_error_msg        => po_error_msg                );
          IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
          END IF;

          /* Si el cliente es corporativo */
          IF v_check_client_type = c_true  THEN
            /* llamamos al  proceso generico de asignacion de datos */
            CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                  ,
                                                        pi_entity_type_code         => v_entity.entity_type_code      ,
                                                        pi_entity_id                => v_entity.entity_id             ,
                                                        pi_entity_type_code_process => pi_entity_type_code            ,
                                                        pi_entity_id_process        => pi_entity_id                   ,
                                                        pi_entity_component_id      => v_entity.entity_component_id   ,
                                                        pi_client_id                => v_tr_entity.client_id          ,
                                                        pi_community_id             => v_tr_entity.community_id       ,
                                                        pi_cen_id                   => v_tr_entity.ce_id              ,
                                                        -- Tariff Keys
                                                        pi_client_type_code         => v_tr_entity.client_type_code   ,
                                                        pi_client_segment_code      => v_tr_entity.client_segment_code,
                                                        pi_community_area_code      => v_tr_entity.community_area_code,
                                                        pi_ce_type_code             => v_tr_entity.ce_type_code       ,
                                                        pi_ce_area_code             => v_tr_entity.ce_area_code       ,
                                                        pi_entity_ageing            => v_tr_entity.entity_ageing      ,
                                                        pi_plan_category_code       => v_tr_entity.plan_category_code ,
                                                        pi_plan_category_id         => v_tr_entity.plan_category_id   ,  --value_id of plan_category_code
                                                        pi_plan_code                => v_tr_entity.plan_code          ,
                                                        pi_entity_plan_id           => v_tr_entity.entity_plan_id     ,   --value_id of plan_code
                                                        pi_component_code           => v_tr_entity.component_code     ,
                                                        pi_add_data1                => v_tr_entity.add_data1          ,
                                                        pi_add_data2                => v_tr_entity.add_data2          ,
                                                        pi_add_data3                => v_tr_entity.add_data3          ,
                                                        pi_add_data4                => v_tr_entity.add_data4          ,
                                                        pi_add_data5                => v_tr_entity.add_data5          ,
                                                        --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                        pi_component_amount         => v_entity.component_amount      ,
                                                        --<ASV Control: 299 25/04/2012 17:02:00>
                                                        pi_start_date               => v_entity.start_date            ,
                                                        pi_end_date                 => v_entity.end_date              ,
                                                        ---data cycle
                                                        pi_cycle_id                 => pi_cycle_id                    ,
                                                        pi_cycle_start_date         => pi_cycle_start_date            ,
                                                        pi_cycle_end_date           => pi_cycle_end_date              ,
                                                        pi_credit_unit_code         => v_entity.credit_unit_code      ,
                                                        pi_billing_start_date       => pi_billing_start_date          ,
                                                        pi_billing_end_date         => pi_billing_end_date            ,
                                                        ---billing data
                                                        pi_billing_type_code        => pi_billing_type_code           ,
                                                        pi_billing_class_code       => pi_billing_class_code          ,
                                                        --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                        pi_billing_tran_id          => pi_billing_tran_id             ,
                                                        pi_tran_id                  => pi_billing_tran_id             ,
                                                        --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                        pi_tran_date                => pi_tran_date                   ,
                                                        pi_asynchronous_status      => c_delivered                    ,
                                                        po_error_code               => po_error_code                  ,
                                                        po_error_msg                => po_error_msg                   );

            IF NVL(po_error_code,'NOK') <> 'OK' THEN
              RAISE ERR_APP;
            END IF;
          END IF;
        END IF;
      END LOOP;

      /*------------Inicio para las CRUS genericas---------------*/
      IF v_entity_component_id IS NOT NULL AND v_tr_entity.ce_id     IS NOT NULL THEN
        FOR v_rec_cru_generic IN tcur_credit_unit_free(pi_billing_end_date, pi_telco_code) LOOP
          --<ASV Control:299 Date:12/11/2012 10:27:30 Update process CRUS genericas, for the consulting first if exists rate for the CRU before processing>
          --COnsulting if exists rate for CRU.
          CRU.BL_UTILITIES.QUERY_GET_RATE_AMOUNT( pi_telco_code          => pi_telco_code                     ,
                                                  pi_entity_type_code    => pi_entity_type_code               ,
                                                  pi_entity_id           => pi_entity_id                      ,
                                                  pi_client_type_code    => v_tr_entity.client_type_code      ,
                                                  pi_client_segment_code => v_tr_entity.client_segment_code   ,
                                                  pi_community_area_code => v_tr_entity.community_area_code   ,
                                                  pi_ce_type_code        => v_tr_entity.ce_type_code          ,
                                                  pi_ce_area_code        => v_tr_entity.ce_area_code          ,
                                                  pi_entity_ageing       => v_tr_entity.entity_ageing         ,
                                                  pi_plan_category_code  => v_tr_entity.plan_category_code    ,
                                                  pi_plan_code           => v_tr_entity.plan_code             ,
                                                  pi_component_code      => v_tr_entity.component_code        ,
                                                  pi_add_data1           => v_tr_entity.add_data1             ,
                                                  pi_add_data2           => v_tr_entity.add_data2             ,
                                                  pi_add_data3           => v_tr_entity.add_data3             ,
                                                  pi_add_data4           => v_tr_entity.add_data4             ,
                                                  pi_add_data5           => v_tr_entity.add_data5             ,
                                                  pi_evaluate_date       => pi_tran_date                      ,
                                                  pi_credit_unit_code    => v_rec_cru_generic.credit_unit_code,
                                                  pi_tran_id             => pi_billing_tran_id                ,
                                                  pi_tran_date           => pi_tran_date                      ,
                                                  po_rate_id             => v_rate_id                         ,
                                                  po_rate_quantity       => v_rate_quantity                   ,
                                                  po_error_code          => po_error_code                     ,
                                                  po_error_msg           => po_error_msg                      );
          
          IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
          END IF;
          
          IF (v_rate_quantity IS NOT NULL AND v_rate_quantity > 0) THEN 
             /* llamamos al  proceso generico de asignacion de datos */
            CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                     ,
                                                        pi_entity_type_code         => pi_entity_type_code               ,
                                                        pi_entity_id                => pi_entity_id                      ,
                                                        pi_entity_type_code_process => pi_entity_type_code               ,
                                                        pi_entity_id_process        => pi_entity_id                      ,
                                                        pi_entity_component_id      => v_entity_component_id             ,
                                                        pi_client_id                => v_tr_entity.client_id             ,
                                                        pi_community_id             => v_tr_entity.community_id          ,
                                                        pi_cen_id                   => v_tr_entity.ce_id                 ,
                                                        -- Tariff Keys
                                                        pi_client_type_code         => v_tr_entity.client_type_code      ,
                                                        pi_client_segment_code      => v_tr_entity.client_segment_code   ,
                                                        pi_community_area_code      => v_tr_entity.community_area_code   ,
                                                        pi_ce_type_code             => v_tr_entity.ce_type_code          ,
                                                        pi_ce_area_code             => v_tr_entity.ce_area_code          ,
                                                        pi_entity_ageing            => v_tr_entity.entity_ageing         ,
                                                        pi_plan_category_code       => v_tr_entity.plan_category_code    ,
                                                        pi_plan_category_id         => v_tr_entity.plan_category_id      ,  --value_id of plan_category_code
                                                        pi_plan_code                => v_tr_entity.plan_code             ,
                                                        pi_entity_plan_id           => v_tr_entity.entity_plan_id        ,   --value_id of plan_code
                                                        pi_component_code           => v_tr_entity.component_code        ,
                                                        pi_add_data1                => v_tr_entity.add_data1             ,
                                                        pi_add_data2                => v_tr_entity.add_data2             ,
                                                        pi_add_data3                => v_tr_entity.add_data3             ,
                                                        pi_add_data4                => v_tr_entity.add_data4             ,
                                                        pi_add_data5                => v_tr_entity.add_data5             ,
                                                        --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                        pi_component_amount         => NULL                              ,
                                                        --<ASV Control: 299 25/04/2012 17:02:00>
                                                        pi_start_date               => pi_billing_start_date             ,
                                                        pi_end_date                 => pi_billing_end_date               ,
                                                        ---data cycle
                                                        pi_cycle_id                 => pi_cycle_id                       ,
                                                        pi_cycle_start_date         => pi_cycle_start_date               ,
                                                        pi_cycle_end_date           => pi_cycle_end_date                 ,
                                                        pi_credit_unit_code         => v_rec_cru_generic.credit_unit_code,
                                                        pi_billing_start_date       => pi_billing_start_date             ,
                                                        pi_billing_end_date         => pi_billing_end_date               ,
                                                        ---billing data
                                                        pi_billing_type_code        => pi_billing_type_code              ,
                                                        pi_billing_class_code       => pi_billing_class_code             ,
                                                        --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                        pi_billing_tran_id          => pi_billing_tran_id                ,
                                                        pi_tran_id                  => pi_billing_tran_id                ,
                                                        --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                        pi_tran_date                => pi_tran_date                      ,
                                                        pi_asynchronous_status      => c_delivered                       ,
                                                        po_error_code               => po_error_code                     ,
                                                        po_error_msg                => po_error_msg                      );
                                                        
            IF NVL(po_error_code,'NOK') <> 'OK' THEN
              RAISE ERR_APP;
            END IF;
          END IF;
          --<ASV Control:299 Date:12/11/2012 10:27:30>
        END LOOP;
      END IF;
      
      --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>      
      IF c_billing_real = pi_billing_type_code THEN
        --This notify exists credit unit for dosage
        v_credits_unit_assign := CRU.BL_UTILITIES.GET_CREDIT_UNIT_ASSIGN(pi_telco_code, pi_cycle_start_date, pi_cycle_end_date,pi_billing_tran_id, pi_tran_date);

        IF v_credits_unit_assign.count > 0 THEN
          --
          --INSERT INTO CRU.test_svar(tran_id, TIMESTAMP)
          --   VALUES (pi_billing_tran_id, current_TIMESTAMP);
          --
          ITF.TX_PUBLIC_CRU.NOTIFY_EXISTS_CREDIT_UNIT( pi_telco_code     => pi_telco_code        ,
                                                       pi_scheduled_date => pi_billing_end_date +( NUMTODSINTERVAL(1,'SECOND')),
                                                       pi_tran_id        => pi_billing_tran_id   ,
                                                       pi_date           => pi_tran_date         ,
                                                       po_error_code     => po_error_code        ,
                                                       po_error_msg      => po_error_msg         );
          --
          --INSERT INTO CRU.test_svar(tran_id, TIMESTAMP)
          --   VALUES (pi_billing_tran_id, current_TIMESTAMP);
          --
          IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
          END IF;
        END IF;
      END IF;
      --<ASV Control:299 Date:08/06/2012 11:27:30>
      
    ELSIF pi_entity_type_code = c_entity_type_community THEN

      v_list_entity_component := CUS.TX_PUBLIC_CRU.GET_RECORDS_ENTITY_COMPONENT( pi_telco_code, c_entity_type_community, pi_entity_id,pi_billing_end_date);

      IF v_list_entity_component.COUNT > 0 THEN
        --iteramos todos los componentes que esten a nivel de Comunidad
        FOR indx IN v_list_entity_component.FIRST .. v_list_entity_component.LAST LOOP
           --iteramos las COmunidades
          v_tr_entity:= NULL;

          FOR v_entity IN tcur_entity(pi_entity_id, c_entity_type_community, pi_telco_code)LOOP
            --verificamos si el entity_component_id esta instanciado..
            IF v_entity.entity_component_id = v_list_entity_component(indx).entity_component_id THEN

              v_tr_entity.entity_component_id := v_entity.entity_component_id;
              v_entity_component_id:= v_entity.entity_component_id;--para ayudar en los datos de las CRUs genericas
               
              /*obtenemos los keys*/
              CUS.TX_PUBLIC_CRU.GET_TARIFF_KEY_ALL( pi_telco_code           => pi_telco_code                  ,
                                                    pi_entity_type_code     => pi_entity_type_code            ,
                                                    pi_entity_id            => pi_entity_id                   ,
                                                    pi_date                 => pi_billing_end_date            , --OJO fecha de entrada
                                                    pi_entity_component_id  => v_entity.entity_component_id   ,
                                                    pi_tran_id              => pi_billing_tran_id             ,
                                                    po_client_id            => v_tr_entity.client_id          ,
                                                    po_community_id         => v_tr_entity.community_id       ,
                                                    po_cen_id               => v_tr_entity.ce_id              ,
                                                    -- Tariff Keys
                                                    po_client_type_code     => v_tr_entity.client_type_code   ,
                                                    po_client_segment_code  => v_tr_entity.client_segment_code,
                                                    po_community_area_code  => v_tr_entity.community_area_code,
                                                    po_ce_type_code         => v_tr_entity.ce_type_code       ,
                                                    po_ce_area_code         => v_tr_entity.ce_area_code       ,
                                                    po_entity_ageing        => v_tr_entity.entity_ageing      ,
                                                    po_plan_category_code   => v_tr_entity.plan_category_code ,
                                                    po_plan_category_id     => v_tr_entity.plan_category_id   ,  --value_id of plan_category_code
                                                    po_plan_code            => v_tr_entity.plan_code          ,
                                                    po_entity_plan_id       => v_tr_entity.entity_plan_id     ,   --value_id of plan_code
                                                    po_component_code       => v_tr_entity.component_code     ,
                                                    po_add_data1            => v_tr_entity.add_data1          ,
                                                    po_add_data2            => v_tr_entity.add_data2          ,
                                                    po_add_data3            => v_tr_entity.add_data3          ,
                                                    po_add_data4            => v_tr_entity.add_data4          ,
                                                    po_add_data5            => v_tr_entity.add_data5          ,
                                                    -- Tariff Keys END
                                                    po_error_code           => po_error_code                  ,
                                                    po_error_msg            => po_error_msg                   );

              IF NVL(po_error_code,'NOK') <> 'OK' THEN
                RAISE ERR_APP;
              END IF;

              /* Verificamos si el cliente es corporativo*/
              CRU.BL_UTILITIES.CHECK_VALID_CLIENT_TYPE( pi_telco_code       => pi_telco_code               ,
                                                        pi_client_type_code => v_tr_entity.client_type_code,
                                                        pi_date             => pi_billing_end_date         ,
                                                        pi_tran_id          => pi_billing_tran_id          ,
                                                        po_chekeable        => v_check_client_type         ,
                                                        po_error_code       => po_error_code               ,
                                                        po_error_msg        => po_error_msg                );
              IF NVL(po_error_code,'NOK') <> 'OK' THEN
                RAISE ERR_APP;
              END IF;
              /* Si el cliente es corporativo */
              IF v_check_client_type = c_true  THEN
                 
                CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                  ,
                                                            pi_entity_type_code         => v_entity.entity_type_code      ,
                                                            pi_entity_id                => v_entity.entity_id             ,
                                                            pi_entity_type_code_process => pi_entity_type_code            ,
                                                            pi_entity_id_process        => pi_entity_id                   ,
                                                            pi_entity_component_id      => v_tr_entity.entity_component_id,
                                                            pi_client_id                => v_tr_entity.client_id          ,
                                                            pi_community_id             => v_tr_entity.community_id       ,
                                                            pi_cen_id                   => v_tr_entity.ce_id              ,
                                                            -- Tariff Keys
                                                            pi_client_type_code         => v_tr_entity.client_type_code   ,
                                                            pi_client_segment_code      => v_tr_entity.client_segment_code,
                                                            pi_community_area_code      => v_tr_entity.community_area_code,
                                                            pi_ce_type_code             => v_tr_entity.ce_type_code       ,
                                                            pi_ce_area_code             => v_tr_entity.ce_area_code       ,
                                                            pi_entity_ageing            => v_tr_entity.entity_ageing      ,
                                                            pi_plan_category_code       => v_tr_entity.plan_category_code ,
                                                            pi_plan_category_id         => v_tr_entity.plan_category_id   ,  --value_id of plan_category_code
                                                            pi_plan_code                => v_tr_entity.plan_code          ,
                                                            pi_entity_plan_id           => v_tr_entity.entity_plan_id     ,   --value_id of plan_code
                                                            pi_component_code           => v_tr_entity.component_code     ,
                                                            pi_add_data1                => v_tr_entity.add_data1          ,
                                                            pi_add_data2                => v_tr_entity.add_data2          ,
                                                            pi_add_data3                => v_tr_entity.add_data3          ,
                                                            pi_add_data4                => v_tr_entity.add_data4          ,
                                                            pi_add_data5                => v_tr_entity.add_data5          ,
                                                            --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                            pi_component_amount         => v_entity.component_amount      ,
                                                            --<ASV Control: 299 25/04/2012 17:02:00>
                                                            pi_start_date               => v_entity.start_date            ,
                                                            pi_end_date                 => v_entity.end_date              ,
                                                            --cycle data
                                                            pi_cycle_id                 => pi_cycle_id                    ,
                                                            pi_cycle_start_date         => pi_cycle_start_date            ,
                                                            pi_cycle_end_date           => pi_cycle_end_date              ,
                                                            pi_credit_unit_code         => v_entity.credit_unit_code      ,
                                                            pi_billing_start_date       => pi_billing_start_date          ,
                                                            pi_billing_end_date         => pi_billing_end_date            ,
                                                            pi_billing_type_code        => pi_billing_type_code           ,
                                                            pi_billing_class_code       => pi_billing_class_code          ,
                                                            --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                            pi_billing_tran_id          => pi_billing_tran_id             ,
                                                            pi_tran_id                  => pi_billing_tran_id             ,
                                                            --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                            pi_tran_date                => pi_tran_date                   ,
                                                            pi_asynchronous_status      => c_delivered                    ,
                                                            po_error_code               => po_error_code                  ,
                                                            po_error_msg                => po_error_msg                   );

                IF NVL(po_error_code,'NOK') <> 'OK' THEN
                  RAISE ERR_APP;
                END IF;
              END IF;
            END IF;
          END LOOP;

          /*------------Inicio para las CRUS genericas---------------*/
          IF v_entity_component_id IS NOT NULL AND v_tr_entity.ce_id IS NOT NULL THEN
            FOR v_rec_cru_generic IN tcur_credit_unit_free(pi_billing_end_date, pi_telco_code) LOOP
              --<ASV Control:299 Date:12/11/2012 10:27:30 Update process CRUS genericas, for the consulting first if exists rate for the CRU before processing>
              --COnsulting if exists rate for CRU.
              CRU.BL_UTILITIES.QUERY_GET_RATE_AMOUNT( pi_telco_code          => pi_telco_code                     ,
                                                      pi_entity_type_code    => pi_entity_type_code               ,
                                                      pi_entity_id           => pi_entity_id                      ,
                                                      pi_client_type_code    => v_tr_entity.client_type_code      ,
                                                      pi_client_segment_code => v_tr_entity.client_segment_code   ,
                                                      pi_community_area_code => v_tr_entity.community_area_code   ,
                                                      pi_ce_type_code        => v_tr_entity.ce_type_code          ,
                                                      pi_ce_area_code        => v_tr_entity.ce_area_code          ,
                                                      pi_entity_ageing       => v_tr_entity.entity_ageing         ,
                                                      pi_plan_category_code  => v_tr_entity.plan_category_code    ,
                                                      pi_plan_code           => v_tr_entity.plan_code             ,
                                                      pi_component_code      => v_tr_entity.component_code        ,
                                                      pi_add_data1           => v_tr_entity.add_data1             ,
                                                      pi_add_data2           => v_tr_entity.add_data2             ,
                                                      pi_add_data3           => v_tr_entity.add_data3             ,
                                                      pi_add_data4           => v_tr_entity.add_data4             ,
                                                      pi_add_data5           => v_tr_entity.add_data5             ,
                                                      pi_evaluate_date       => pi_tran_date                      ,
                                                      pi_credit_unit_code    => v_rec_cru_generic.credit_unit_code,
                                                      pi_tran_id             => pi_billing_tran_id                ,
                                                      pi_tran_date           => pi_tran_date                      ,
                                                      po_rate_id             => v_rate_id                         ,
                                                      po_rate_quantity       => v_rate_quantity                   ,
                                                      po_error_code          => po_error_code                     ,
                                                      po_error_msg           => po_error_msg                      );
          
              IF NVL(po_error_code,'NOK') <> 'OK' THEN
                RAISE ERR_APP;
              END IF;              
              
              IF ( v_rate_quantity IS NOT NULL AND v_rate_quantity > 0 ) THEN
                /* llamamos al  proceso generico de asignacion de datos */
                CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                     ,
                                                            pi_entity_type_code         => pi_entity_type_code               ,
                                                            pi_entity_id                => pi_entity_id                      ,
                                                            pi_entity_type_code_process => pi_entity_type_code               ,
                                                            pi_entity_id_process        => pi_entity_id                      ,
                                                            pi_entity_component_id      => v_entity_component_id             ,
                                                            pi_client_id                => v_tr_entity.client_id             ,
                                                            pi_community_id             => v_tr_entity.community_id          ,
                                                            pi_cen_id                   => v_tr_entity.ce_id                 ,
                                                            -- Tariff Keys
                                                            pi_client_type_code         => v_tr_entity.client_type_code      ,
                                                            pi_client_segment_code      => v_tr_entity.client_segment_code   ,
                                                            pi_community_area_code      => v_tr_entity.community_area_code   ,
                                                            pi_ce_type_code             => v_tr_entity.ce_type_code          ,
                                                            pi_ce_area_code             => v_tr_entity.ce_area_code          ,
                                                            pi_entity_ageing            => v_tr_entity.entity_ageing         ,
                                                            pi_plan_category_code       => v_tr_entity.plan_category_code    ,
                                                            pi_plan_category_id         => v_tr_entity.plan_category_id      ,  --value_id of plan_category_code
                                                            pi_plan_code                => v_tr_entity.plan_code             ,
                                                            pi_entity_plan_id           => v_tr_entity.entity_plan_id        ,   --value_id of plan_code
                                                            pi_component_code           => v_tr_entity.component_code        ,
                                                            pi_add_data1                => v_tr_entity.add_data1             ,
                                                            pi_add_data2                => v_tr_entity.add_data2             ,
                                                            pi_add_data3                => v_tr_entity.add_data3             ,
                                                            pi_add_data4                => v_tr_entity.add_data4             ,
                                                            pi_add_data5                => v_tr_entity.add_data5             ,
                                                            --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                            pi_component_amount         => NULL                              ,
                                                            --<ASV Control: 299 25/04/2012 17:02:00>
                                                            pi_start_date               => pi_billing_start_date             ,
                                                            pi_end_date                 => pi_billing_end_date               ,
                                                            ---data cycle
                                                            pi_cycle_id                 => pi_cycle_id                       ,
                                                            pi_cycle_start_date         => pi_cycle_start_date               ,
                                                            pi_cycle_end_date           => pi_cycle_end_date                 ,
                                                            pi_credit_unit_code         => v_rec_cru_generic.credit_unit_code,
                                                            pi_billing_start_date       => pi_billing_start_date             ,
                                                            pi_billing_end_date         => pi_billing_end_date               ,
                                                            ---billing data
                                                            pi_billing_type_code        => pi_billing_type_code              ,
                                                            pi_billing_class_code       => pi_billing_class_code             ,
                                                            --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                            pi_billing_tran_id          => pi_billing_tran_id                ,
                                                            pi_tran_id                  => pi_billing_tran_id                ,
                                                            --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                            pi_tran_date                => pi_tran_date                      ,
                                                            pi_asynchronous_status      => c_delivered                       ,
                                                            po_error_code               => po_error_code                     ,
                                                            po_error_msg                => po_error_msg                      );

                IF NVL(po_error_code,'NOK') <> 'OK' THEN
                  RAISE ERR_APP;
                END IF;
              END IF;
              --<ASV Control:299 Date:12/11/2012 10:27:30>
            END LOOP;
          END IF;

        END LOOP;
      END IF;
      --PROCESAR A NIVEL INFERIOR DE COMUNIDAD --> (a nivela de Entidad de cosumo)
      v_list_consumption_entity := CUS.TX_PUBLIC_CRU.GET_RECORDS_EC( pi_telco_code   => pi_telco_code      ,
                                                                     pi_community_id => pi_entity_id       ,
                                                                     pi_date         => pi_billing_end_date);
      IF v_list_consumption_entity.COUNT > 0 THEN

        FOR indx IN v_list_consumption_entity.FIRST .. v_list_consumption_entity.LAST LOOP
          
          v_tr_entity:= NULL;

          --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity> 
          v_tran_id := ITF.TX_PUBLIC_CRU.GET_TRAN_ID;
          --<ASV Control:299 Date:08/06/2012 11:27:30>

          FOR v_entity IN tcur_entity(v_list_consumption_entity(indx).consumption_entity_id, c_entity_type_comsup_entity, pi_telco_code)LOOP

            v_entity_component_id:= v_entity.entity_component_id;--para ayudar en los datos de las CRUs genericas

            /*obtenemos los keys*/
            CUS.TX_PUBLIC_CRU.GET_TARIFF_KEY_ALL( pi_telco_code           => pi_telco_code                   ,
                                                  pi_entity_type_code     => c_entity_type_comsup_entity     ,--ingresa como entidad de consumo
                                                  pi_entity_id            => v_list_consumption_entity(indx).consumption_entity_id, ---es igual al entity_id
                                                  pi_date                 => pi_billing_end_date             , --OJO fecha de entrada
                                                  pi_entity_component_id  => v_entity.entity_component_id    , 
                                                  pi_tran_id              => v_tran_id                       ,
                                                  po_client_id            => v_tr_entity.client_id           ,
                                                  po_community_id         => v_tr_entity.community_id        ,
                                                  po_cen_id               => v_tr_entity.ce_id               ,
                                                  -- Tariff Keys
                                                  po_client_type_code     => v_tr_entity.client_type_code    ,
                                                  po_client_segment_code  => v_tr_entity.client_segment_code ,
                                                  po_community_area_code  => v_tr_entity.community_area_code ,
                                                  po_ce_type_code         => v_tr_entity.ce_type_code        ,
                                                  po_ce_area_code         => v_tr_entity.ce_area_code        ,
                                                  po_entity_ageing        => v_tr_entity.entity_ageing       ,
                                                  po_plan_category_code   => v_tr_entity.plan_category_code  ,
                                                  po_plan_category_id     => v_tr_entity.plan_category_id    ,  --value_id of plan_category_code
                                                  po_plan_code            => v_tr_entity.plan_code           ,
                                                  po_entity_plan_id       => v_tr_entity.entity_plan_id      ,   --value_id of plan_code
                                                  po_component_code       => v_tr_entity.component_code      ,
                                                  po_add_data1            => v_tr_entity.add_data1           ,
                                                  po_add_data2            => v_tr_entity.add_data2           ,
                                                  po_add_data3            => v_tr_entity.add_data3           ,
                                                  po_add_data4            => v_tr_entity.add_data4           ,
                                                  po_add_data5            => v_tr_entity.add_data5           ,
                                                  -- Tariff Keys END
                                                  po_error_code           => po_error_code                   ,
                                                  po_error_msg            => po_error_msg                    );

            IF NVL(po_error_code,'NOK') <> 'OK' THEN
              RAISE ERR_APP;
            END IF;

            /* Verificamos si el cliente es corporativo*/
            CRU.BL_UTILITIES.CHECK_VALID_CLIENT_TYPE( pi_telco_code       => pi_telco_code               ,
                                                      pi_client_type_code => v_tr_entity.client_type_code,
                                                      pi_date             => pi_billing_end_date         ,
                                                      pi_tran_id          => v_tran_id                   ,
                                                      po_chekeable        => v_check_client_type         ,
                                                      po_error_code       => po_error_code               ,
                                                      po_error_msg        => po_error_msg                );
            IF NVL(po_error_code,'NOK') <> 'OK' THEN
              RAISE ERR_APP;
            END IF;
            /* Si el cliente es corporativo */
            IF v_check_client_type = c_true  THEN

              CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                    ,
                                                          pi_entity_type_code         => c_entity_type_comsup_entity      , --ojo esto procesa a nivel de community o tiene q ser / c_entity_type_comsup_entity
                                                          pi_entity_id                => v_list_consumption_entity(indx).consumption_entity_id,
                                                          pi_entity_type_code_process => pi_entity_type_code              ,
                                                          pi_entity_id_process        => pi_entity_id                     ,
                                                          --se saca del cursor
                                                          pi_entity_component_id      => v_entity.entity_component_id     ,
                                                          pi_client_id                => v_tr_entity.client_id            ,
                                                          pi_community_id             => v_tr_entity.community_id         ,
                                                          pi_cen_id                   => v_tr_entity.ce_id                ,
                                                          -- Tariff Keys
                                                          pi_client_type_code         => v_tr_entity.client_type_code     ,
                                                          pi_client_segment_code      => v_tr_entity.client_segment_code  ,
                                                          pi_community_area_code      => v_tr_entity.community_area_code  ,
                                                          pi_ce_type_code             => v_tr_entity.ce_type_code         ,
                                                          pi_ce_area_code             => v_tr_entity.ce_area_code         ,
                                                          pi_entity_ageing            => v_tr_entity.entity_ageing        ,
                                                          pi_plan_category_code       => v_tr_entity.plan_category_code   ,
                                                          pi_plan_category_id         => v_tr_entity.plan_category_id     ,  --value_id of plan_category_code
                                                          pi_plan_code                => v_tr_entity.plan_code            ,
                                                          pi_entity_plan_id           => v_tr_entity.entity_plan_id       ,   --value_id of plan_code
                                                          pi_component_code           => v_tr_entity.component_code       ,
                                                          pi_add_data1                => v_tr_entity.add_data1            ,
                                                          pi_add_data2                => v_tr_entity.add_data2            ,
                                                          pi_add_data3                => v_tr_entity.add_data3            ,
                                                          pi_add_data4                => v_tr_entity.add_data4            ,
                                                          pi_add_data5                => v_tr_entity.add_data5            ,
                                                          --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                          pi_component_amount         => v_entity.component_amount        ,
                                                          --<ASV Control: 299 25/04/2012 17:02:00>
                                                          pi_start_date               => v_entity.start_date              ,
                                                          pi_end_date                 => v_entity.end_date                ,
                                                          ---data cycle
                                                          pi_cycle_id                 => pi_cycle_id                      ,
                                                          pi_cycle_start_date         => pi_cycle_start_date              ,
                                                          pi_cycle_end_date           => pi_cycle_end_date                ,
                                                          pi_credit_unit_code         => v_entity.credit_unit_code        ,
                                                          pi_billing_start_date       => pi_billing_start_date            ,
                                                          pi_billing_end_date         => pi_billing_end_date              ,
                                                          ---billing data
                                                          pi_billing_type_code        => pi_billing_type_code             ,
                                                          pi_billing_class_code       => pi_billing_class_code            ,
                                                          --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                          pi_billing_tran_id          => pi_billing_tran_id               ,
                                                          pi_tran_id                  => v_tran_id                        ,
                                                          --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                          pi_tran_date                => pi_tran_date                     ,
                                                          pi_asynchronous_status      => c_delivered                      ,
                                                          po_error_code               => po_error_code                    ,
                                                          po_error_msg                => po_error_msg                     );

              IF NVL(po_error_code,'NOK') <> 'OK' THEN
                RAISE ERR_APP;
              END IF;
            END IF;
          END LOOP;

          /*------------Inicio para las CRUS genericas---------------*/
          IF v_entity_component_id IS NOT NULL AND v_tr_entity.ce_id      IS NOT NULL THEN

            FOR v_rec_cru_generic IN tcur_credit_unit_free(pi_billing_end_date, pi_telco_code) LOOP
              --<ASV Control:299 Date:12/11/2012 10:27:30 Update process CRUS genericas, for the consulting first if exists rate for the CRU before processing>
              --COnsulting if exists rate for CRU.
              CRU.BL_UTILITIES.QUERY_GET_RATE_AMOUNT( pi_telco_code          => pi_telco_code                     ,
                                                      pi_entity_type_code    => c_entity_type_comsup_entity       ,
                                                      pi_entity_id           => v_list_consumption_entity(indx).consumption_entity_id,
                                                      pi_client_type_code    => v_tr_entity.client_type_code      ,
                                                      pi_client_segment_code => v_tr_entity.client_segment_code   ,
                                                      pi_community_area_code => v_tr_entity.community_area_code   ,
                                                      pi_ce_type_code        => v_tr_entity.ce_type_code          ,
                                                      pi_ce_area_code        => v_tr_entity.ce_area_code          ,
                                                      pi_entity_ageing       => v_tr_entity.entity_ageing         ,
                                                      pi_plan_category_code  => v_tr_entity.plan_category_code    ,
                                                      pi_plan_code           => v_tr_entity.plan_code             ,
                                                      pi_component_code      => v_tr_entity.component_code        ,
                                                      pi_add_data1           => v_tr_entity.add_data1             ,
                                                      pi_add_data2           => v_tr_entity.add_data2             ,
                                                      pi_add_data3           => v_tr_entity.add_data3             ,
                                                      pi_add_data4           => v_tr_entity.add_data4             ,
                                                      pi_add_data5           => v_tr_entity.add_data5             ,
                                                      pi_evaluate_date       => pi_tran_date                      ,
                                                      pi_credit_unit_code    => v_rec_cru_generic.credit_unit_code,
                                                      pi_tran_id             => pi_billing_tran_id                ,
                                                      pi_tran_date           => pi_tran_date                      ,
                                                      po_rate_id             => v_rate_id                         ,
                                                      po_rate_quantity       => v_rate_quantity                   ,
                                                      po_error_code          => po_error_code                     ,
                                                      po_error_msg           => po_error_msg                      );
          
              IF NVL(po_error_code,'NOK') <> 'OK' THEN
                RAISE ERR_APP;
              END IF;              
              
              IF ( v_rate_quantity IS NOT NULL AND v_rate_quantity > 0 ) THEN
                /* llamamos al  proceso generico de asignacion de datos */
                CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                     ,
                                                            pi_entity_type_code         => c_entity_type_comsup_entity       ,
                                                            pi_entity_id                => v_list_consumption_entity(indx).consumption_entity_id, --pi_entity_id                      ,
                                                            pi_entity_type_code_process => pi_entity_type_code               ,
                                                            pi_entity_id_process        => pi_entity_id                      ,
                                                            pi_entity_component_id      => v_entity_component_id             ,
                                                            pi_client_id                => v_tr_entity.client_id             ,
                                                            pi_community_id             => v_tr_entity.community_id          ,
                                                            pi_cen_id                   => v_tr_entity.ce_id                 ,
                                                            -- Tariff Keys
                                                            pi_client_type_code         => v_tr_entity.client_type_code      ,
                                                            pi_client_segment_code      => v_tr_entity.client_segment_code   ,
                                                            pi_community_area_code      => v_tr_entity.community_area_code   ,
                                                            pi_ce_type_code             => v_tr_entity.ce_type_code          ,
                                                            pi_ce_area_code             => v_tr_entity.ce_area_code          ,
                                                            pi_entity_ageing            => v_tr_entity.entity_ageing         ,
                                                            pi_plan_category_code       => v_tr_entity.plan_category_code    ,
                                                            pi_plan_category_id         => v_tr_entity.plan_category_id      ,  --value_id of plan_category_code
                                                            pi_plan_code                => v_tr_entity.plan_code             ,
                                                            pi_entity_plan_id           => v_tr_entity.entity_plan_id        ,   --value_id of plan_code
                                                            pi_component_code           => v_tr_entity.component_code        ,
                                                            pi_add_data1                => v_tr_entity.add_data1             ,
                                                            pi_add_data2                => v_tr_entity.add_data2             ,
                                                            pi_add_data3                => v_tr_entity.add_data3             ,
                                                            pi_add_data4                => v_tr_entity.add_data4             ,
                                                            pi_add_data5                => v_tr_entity.add_data5             ,
                                                            --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                            pi_component_amount         => NULL                              ,
                                                            --<ASV Control: 299 25/04/2012 17:02:00>
                                                            pi_start_date               => pi_billing_start_date             ,
                                                            pi_end_date                 => pi_billing_end_date               ,
                                                            ---data cycle
                                                            pi_cycle_id                 => pi_cycle_id                       ,
                                                            pi_cycle_start_date         => pi_cycle_start_date               ,
                                                            pi_cycle_end_date           => pi_cycle_end_date                 ,
                                                            pi_credit_unit_code         => v_rec_cru_generic.credit_unit_code,
                                                            pi_billing_start_date       => pi_billing_start_date             ,
                                                            pi_billing_end_date         => pi_billing_end_date               ,
                                                            ---billing data
                                                            pi_billing_type_code        => pi_billing_type_code              ,
                                                            pi_billing_class_code       => pi_billing_class_code             ,
                                                            --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                            pi_billing_tran_id          => pi_billing_tran_id                ,
                                                            pi_tran_id                  => v_tran_id                         ,
                                                            --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                            pi_tran_date                => pi_tran_date                      ,
                                                            pi_asynchronous_status      => c_delivered                       ,
                                                            po_error_code               => po_error_code                     ,
                                                            po_error_msg                => po_error_msg                      );

                IF NVL(po_error_code,'NOK') <> 'OK' THEN
                  RAISE ERR_APP;
                END IF;
              END IF;
              --<ASV Control:299 Date:12/11/2012 10:27:30>
            END LOOP;

          END IF; --si hay datos para realizar la asignacionde CRUs genericas
        END LOOP;
      END IF;
      
      --Mandamos todo en bulk
      
      --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
      IF c_billing_real = pi_billing_type_code THEN
        FOR v_rec IN (SELECT DISTINCT l.start_tran_id
                        FROM CRU.TR_ENTITY_LOG l
                       WHERE l.telco_code      = pi_telco_code
                         AND l.billing_tran_id = pi_billing_tran_id
                         AND l.start_tran_date = pi_tran_date
                         AND l.status         <>c_inactive)LOOP
          v_credits_unit_assign := CRU.BL_UTILITIES.GET_CREDIT_UNIT_ASSIGN(pi_telco_code, pi_cycle_start_date, pi_cycle_end_date,v_rec.start_tran_id, pi_tran_date);
          IF v_credits_unit_assign.count > 0 THEN

              ITF.TX_PUBLIC_CRU.NOTIFY_EXISTS_CREDIT_UNIT( pi_telco_code     => pi_telco_code       ,
                                                           pi_scheduled_date => pi_billing_end_date +( NUMTODSINTERVAL(1,'SECOND')),
                                                           pi_tran_id        => v_rec.start_tran_id ,
                                                           pi_date           => pi_tran_date        ,
                                                           po_error_code     => po_error_code       ,
                                                           po_error_msg      => po_error_msg        );

            IF NVL(po_error_code,'NOK') <> 'OK' THEN
              RAISE ERR_APP;
            END IF;
          END IF;
        END LOOP;  
      END IF;

      --<ASV Control:299 Date:08/06/2012 11:27:30>
      
    --fin de proceso a nivel de entidad de consumo
    ELSIF pi_entity_type_code = c_entity_type_client THEN

      v_tr_entity:=NULL;

      FOR v_entity IN tcur_entity(pi_entity_id, pi_entity_type_code, pi_telco_code)LOOP

        IF v_entity.entity_type_code = pi_entity_type_code AND v_entity.entity_id = pi_entity_id THEN

          v_entity_component_id := v_entity.entity_component_id;
          /*obtenemos los keys*/
          CUS.TX_PUBLIC_CRU.GET_TARIFF_KEY_ALL( pi_telco_code           => pi_telco_code                  ,
                                                pi_entity_type_code     => pi_entity_type_code            ,
                                                pi_entity_id            => pi_entity_id                   ,
                                                pi_date                 => pi_billing_end_date            , --OJO fecha de entrada
                                                pi_entity_component_id  => v_entity.entity_component_id   ,
                                                pi_tran_id              => pi_billing_tran_id             ,
                                                po_client_id            => v_tr_entity.client_id          ,
                                                po_community_id         => v_tr_entity.community_id       ,
                                                po_cen_id               => v_tr_entity.ce_id              ,
                                                -- Tariff Keys
                                                po_client_type_code     => v_tr_entity.client_type_code   ,
                                                po_client_segment_code  => v_tr_entity.client_segment_code,
                                                po_community_area_code  => v_tr_entity.community_area_code,
                                                po_ce_type_code         => v_tr_entity.ce_type_code       ,
                                                po_ce_area_code         => v_tr_entity.ce_area_code       ,
                                                po_entity_ageing        => v_tr_entity.entity_ageing      ,
                                                po_plan_category_code   => v_tr_entity.plan_category_code ,
                                                po_plan_category_id     => v_tr_entity.plan_category_id   ,  --value_id of plan_category_code
                                                po_plan_code            => v_tr_entity.plan_code          ,
                                                po_entity_plan_id       => v_tr_entity.entity_plan_id     ,   --value_id of plan_code
                                                po_component_code       => v_tr_entity.component_code     ,
                                                po_add_data1            => v_tr_entity.add_data1          ,
                                                po_add_data2            => v_tr_entity.add_data2          ,
                                                po_add_data3            => v_tr_entity.add_data3          ,
                                                po_add_data4            => v_tr_entity.add_data4          ,
                                                po_add_data5            => v_tr_entity.add_data5          ,
                                                -- Tariff Keys END
                                                po_error_code           => po_error_code                  ,
                                                po_error_msg            => po_error_msg                   );

          IF NVL(po_error_code,'NOK') <> 'OK' THEN
              RAISE ERR_APP;
          END IF;
          /* Verificamos si el cliente esta habilitado para tener CRUs*/
          CRU.BL_UTILITIES.CHECK_VALID_CLIENT_TYPE( pi_telco_code       => pi_telco_code               ,
                                                    pi_client_type_code => v_tr_entity.client_type_code,
                                                    pi_date             =>  pi_billing_end_date        ,
                                                    pi_tran_id          => pi_billing_tran_id          ,
                                                    po_chekeable        => v_check_client_type         ,
                                                    po_error_code       => po_error_code               ,
                                                    po_error_msg        => po_error_msg                );
          IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
          END IF;
          /* Si el cliente es corporativo */
          IF v_check_client_type = c_true  THEN

            /* llamamos al  proceso generico de asignacion de datos */
            CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                  ,
                                                        pi_entity_type_code         => v_entity.entity_type_code      ,
                                                        pi_entity_id                => v_entity.entity_id             ,
                                                        pi_entity_type_code_process => pi_entity_type_code            ,
                                                        pi_entity_id_process        => pi_entity_id                   ,
                                                        pi_entity_component_id      => v_entity.entity_component_id   ,
                                                        pi_client_id                => v_tr_entity.client_id          ,
                                                        pi_community_id             => v_tr_entity.community_id       ,
                                                        pi_cen_id                   => v_tr_entity.ce_id              ,
                                                        -- Tariff Keys
                                                        pi_client_type_code         => v_tr_entity.client_type_code   ,
                                                        pi_client_segment_code      => v_tr_entity.client_segment_code,
                                                        pi_community_area_code      => v_tr_entity.community_area_code,
                                                        pi_ce_type_code             => v_tr_entity.ce_type_code       ,
                                                        pi_ce_area_code             => v_tr_entity.ce_area_code       ,
                                                        pi_entity_ageing            => v_tr_entity.entity_ageing      ,
                                                        pi_plan_category_code       => v_tr_entity.plan_category_code ,
                                                        pi_plan_category_id         => v_tr_entity.plan_category_id   ,  --value_id of plan_category_code
                                                        pi_plan_code                => v_tr_entity.plan_code          ,
                                                        pi_entity_plan_id           => v_tr_entity.entity_plan_id     ,   --value_id of plan_code
                                                        pi_component_code           => v_tr_entity.component_code     ,
                                                        pi_add_data1                => v_tr_entity.add_data1          ,
                                                        pi_add_data2                => v_tr_entity.add_data2          ,
                                                        pi_add_data3                => v_tr_entity.add_data3          ,
                                                        pi_add_data4                => v_tr_entity.add_data4          ,
                                                        pi_add_data5                => v_tr_entity.add_data5          ,
                                                        --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                        pi_component_amount         => v_entity.component_amount      ,
                                                        --<ASV Control: 299 25/04/2012 17:02:00>
                                                        pi_start_date               => v_entity.start_date            ,
                                                        pi_end_date                 => v_entity.end_date              ,
                                                        ---data cycle
                                                        pi_cycle_id                 => pi_cycle_id                    ,
                                                        pi_cycle_start_date         => pi_cycle_start_date            ,
                                                        pi_cycle_end_date           => pi_cycle_end_date              ,
                                                        pi_credit_unit_code         => v_entity.credit_unit_code      ,
                                                        pi_billing_start_date       => pi_billing_start_date          ,
                                                        pi_billing_end_date         => pi_billing_end_date            ,
                                                        ---billing data
                                                        pi_billing_type_code        => pi_billing_type_code           ,
                                                        pi_billing_class_code       => pi_billing_class_code          ,
                                                        --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                        pi_billing_tran_id            => pi_billing_tran_id           ,
                                                        pi_tran_id                    => pi_billing_tran_id           ,
                                                        --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                        pi_tran_date                => pi_tran_date                   ,
                                                        pi_asynchronous_status      => c_delivered                    ,
                                                        po_error_code               => po_error_code                  ,
                                                        po_error_msg                => po_error_msg                   );

            IF NVL(po_error_code,'NOK') <> 'OK' THEN
              RAISE ERR_APP;
            END IF;
          END IF;
        END IF;
      END LOOP;

      --para las CRUs Genericas----------------------------------------------------------------------------
      IF v_entity_component_id IS NOT NULL AND v_tr_entity.ce_id IS NOT NULL THEN

        FOR v_rec_cru_generic IN tcur_credit_unit_free(pi_billing_end_date, pi_telco_code) LOOP
          --<ASV Control:299 Date:12/11/2012 10:27:30 Update process CRUS genericas, for the consulting first if exists rate for the CRU before processing>
          --COnsulting if exists rate for CRU.
          CRU.BL_UTILITIES.QUERY_GET_RATE_AMOUNT( pi_telco_code          => pi_telco_code                     ,
                                                  pi_entity_type_code    => pi_entity_type_code               ,
                                                  pi_entity_id           => pi_entity_id                      ,
                                                  pi_client_type_code    => v_tr_entity.client_type_code      ,
                                                  pi_client_segment_code => v_tr_entity.client_segment_code   ,
                                                  pi_community_area_code => v_tr_entity.community_area_code   ,
                                                  pi_ce_type_code        => v_tr_entity.ce_type_code          ,
                                                  pi_ce_area_code        => v_tr_entity.ce_area_code          ,
                                                  pi_entity_ageing       => v_tr_entity.entity_ageing         ,
                                                  pi_plan_category_code  => v_tr_entity.plan_category_code    ,
                                                  pi_plan_code           => v_tr_entity.plan_code             ,
                                                  pi_component_code      => v_tr_entity.component_code        ,
                                                  pi_add_data1           => v_tr_entity.add_data1             ,
                                                  pi_add_data2           => v_tr_entity.add_data2             ,
                                                  pi_add_data3           => v_tr_entity.add_data3             ,
                                                  pi_add_data4           => v_tr_entity.add_data4             ,
                                                  pi_add_data5           => v_tr_entity.add_data5             ,
                                                  pi_evaluate_date       => pi_tran_date                      ,
                                                  pi_credit_unit_code    => v_rec_cru_generic.credit_unit_code,
                                                  pi_tran_id             => pi_billing_tran_id                ,
                                                  pi_tran_date           => pi_tran_date                      ,
                                                  po_rate_id             => v_rate_id                         ,
                                                  po_rate_quantity       => v_rate_quantity                   ,
                                                  po_error_code          => po_error_code                     ,
                                                  po_error_msg           => po_error_msg                      );
          
          IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
          END IF;              
          
          IF ( v_rate_quantity IS NOT NULL AND v_rate_quantity > 0 ) THEN
            /* llamamos al  proceso generico de asignacion de datos */
            CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                     ,
                                                        pi_entity_type_code         => pi_entity_type_code               ,
                                                        pi_entity_id                => pi_entity_id                      ,
                                                        pi_entity_type_code_process => pi_entity_type_code               ,
                                                        pi_entity_id_process        => pi_entity_id                      ,
                                                        pi_entity_component_id      => v_entity_component_id             ,
                                                        pi_client_id                => v_tr_entity.client_id             ,
                                                        pi_community_id             => v_tr_entity.community_id          ,
                                                        pi_cen_id                   => v_tr_entity.ce_id                 ,
                                                        -- Tariff Keys
                                                        pi_client_type_code         => v_tr_entity.client_type_code      ,
                                                        pi_client_segment_code      => v_tr_entity.client_segment_code   ,
                                                        pi_community_area_code      => v_tr_entity.community_area_code   ,
                                                        pi_ce_type_code             => v_tr_entity.ce_type_code          ,
                                                        pi_ce_area_code             => v_tr_entity.ce_area_code          ,
                                                        pi_entity_ageing            => v_tr_entity.entity_ageing         ,
                                                        pi_plan_category_code       => v_tr_entity.plan_category_code    ,
                                                        pi_plan_category_id         => v_tr_entity.plan_category_id      ,  --value_id of plan_category_code
                                                        pi_plan_code                => v_tr_entity.plan_code             ,
                                                        pi_entity_plan_id           => v_tr_entity.entity_plan_id        ,   --value_id of plan_code
                                                        pi_component_code           => v_tr_entity.component_code        ,
                                                        pi_add_data1                => v_tr_entity.add_data1             ,
                                                        pi_add_data2                => v_tr_entity.add_data2             ,
                                                        pi_add_data3                => v_tr_entity.add_data3             ,
                                                        pi_add_data4                => v_tr_entity.add_data4             ,
                                                        pi_add_data5                => v_tr_entity.add_data5             ,
                                                        --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                        pi_component_amount         => NULL                              ,
                                                        --<ASV Control: 299 25/04/2012 17:02:00>
                                                        pi_start_date               => pi_billing_start_date             ,
                                                        pi_end_date                 => pi_billing_end_date               ,
                                                        ---data cycle
                                                        pi_cycle_id                 => pi_cycle_id                       ,
                                                        pi_cycle_start_date         => pi_cycle_start_date               ,
                                                        pi_cycle_end_date           => pi_cycle_end_date                 ,
                                                        pi_credit_unit_code         => v_rec_cru_generic.credit_unit_code,
                                                        pi_billing_start_date       => pi_billing_start_date             ,
                                                        pi_billing_end_date         => pi_billing_end_date               ,
                                                        ---billing data
                                                        pi_billing_type_code        => pi_billing_type_code              ,
                                                        pi_billing_class_code       => pi_billing_class_code             ,
                                                        --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                        pi_billing_tran_id          => pi_billing_tran_id                ,
                                                        pi_tran_id                  => pi_billing_tran_id                ,
                                                        --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                        pi_tran_date                => pi_tran_date                      ,
                                                        pi_asynchronous_status      => c_delivered                       ,
                                                        po_error_code               => po_error_code                     ,
                                                        po_error_msg                => po_error_msg                      );

            IF NVL(po_error_code,'NOK') <> 'OK' THEN
              RAISE ERR_APP;
            END IF;
          END IF;
          --<ASV Control:299 Date:12/11/2012 10:27:30>
        END LOOP;
      END IF;   --fin de Genericos para CLIENT
      
      ----------------- LEVEL COMMUNITY   ---------------------
      -- <GGR 24/04/2012 17:02:00 CONTROL:299.1484 add parameter community_type_billing to procedure GET_RECORDS_COMMUNITY whit constant billing value of itf,
      v_list_community := CUS.TX_PUBLIC_CRU.GET_RECORDS_COMMUNITY(pi_telco_code, pi_entity_id,c_community_type_billing,pi_billing_end_date);
      -- <GGR 24/04/2012 17:02:00 CONTROL:299.1484
      
      IF v_list_community.COUNT > 0 THEN

        FOR indy IN v_list_community.FIRST .. v_list_community.LAST LOOP

          v_list_entity_component := CUS.TX_PUBLIC_CRU.GET_RECORDS_ENTITY_COMPONENT(pi_telco_code, pi_entity_type_code, v_list_community(indy).community_id,pi_billing_end_date);

          IF v_list_entity_component.COUNT > 0 THEN

            FOR indx IN v_list_entity_component.FIRST .. v_list_entity_component.LAST LOOP

              v_tr_entity:=NULL;

              --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity> 
              v_tran_id := ITF.TX_PUBLIC_CRU.GET_TRAN_ID;
              --<ASV Control:299 Date:08/06/2012 11:27:30>

              --FOR v_entity IN tcur_entity(pi_entity_id, c_entity_type_community)LOOP
              FOR v_entity IN tcur_entity(v_list_community(indy).community_id, c_entity_type_community, pi_telco_code)LOOP

                IF v_entity.entity_component_id = v_list_entity_component(indx).entity_component_id THEN

                  v_tr_entity.entity_component_id := v_entity.entity_component_id;
                  v_entity_component_id := v_tr_entity.entity_component_id;--para CRUs genericas a nivel COMMUNITY
                  
                  /*obtenemos los keys*/
                  CUS.TX_PUBLIC_CRU.GET_TARIFF_KEY_ALL( pi_telco_code           => pi_telco_code                      ,
                                                        pi_entity_type_code     => c_entity_type_community            ,--pi_entity_type_code            ,
                                                        pi_entity_id            => v_list_community(indy).community_id,--pi_entity_id                   ,
                                                        pi_date                 => pi_billing_end_date                , --OJO fecha de entrada
                                                        pi_entity_component_id  => v_tr_entity.entity_component_id    ,
                                                        pi_tran_id              => v_tran_id                          ,
                                                        po_client_id            => v_tr_entity.client_id              ,
                                                        po_community_id         => v_tr_entity.community_id           ,
                                                        po_cen_id               => v_tr_entity.ce_id                  ,
                                                        -- Tariff Keys
                                                        po_client_type_code     => v_tr_entity.client_type_code       ,
                                                        po_client_segment_code  => v_tr_entity.client_segment_code    ,
                                                        po_community_area_code  => v_tr_entity.community_area_code    ,
                                                        po_ce_type_code         => v_tr_entity.ce_type_code           ,
                                                        po_ce_area_code         => v_tr_entity.ce_area_code           ,
                                                        po_entity_ageing        => v_tr_entity.entity_ageing          ,
                                                        po_plan_category_code   => v_tr_entity.plan_category_code     ,
                                                        po_plan_category_id     => v_tr_entity.plan_category_id       ,  --value_id of plan_category_code
                                                        po_plan_code            => v_tr_entity.plan_code              ,
                                                        po_entity_plan_id       => v_tr_entity.entity_plan_id         ,   --value_id of plan_code
                                                        po_component_code       => v_tr_entity.component_code         ,
                                                        po_add_data1            => v_tr_entity.add_data1              ,
                                                        po_add_data2            => v_tr_entity.add_data2              ,
                                                        po_add_data3            => v_tr_entity.add_data3              ,
                                                        po_add_data4            => v_tr_entity.add_data4              ,
                                                        po_add_data5            => v_tr_entity.add_data5              ,
                                                        -- Tariff Keys END
                                                        po_error_code           => po_error_code                      ,
                                                        po_error_msg            => po_error_msg                       );

                  IF NVL(po_error_code,'NOK') <> 'OK' THEN
                    RAISE ERR_APP;
                  END IF;
                  
                  /* Verificamos si el cliente es corporativo*/
                  CRU.BL_UTILITIES.CHECK_VALID_CLIENT_TYPE( pi_telco_code       => pi_telco_code               ,
                                                            pi_client_type_code => v_tr_entity.client_type_code,
                                                            pi_date             =>  pi_billing_end_date        ,
                                                            pi_tran_id          => pi_billing_tran_id          ,
                                                            po_chekeable        => v_check_client_type         ,
                                                            po_error_code       => po_error_code               ,
                                                            po_error_msg        => po_error_msg                );
                  IF NVL(po_error_code,'NOK') <> 'OK' THEN
                    RAISE ERR_APP;
                  END IF;
                  /* Si el cliente es corporativo */
                  IF v_check_client_type = c_true  THEN
                  
                    CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                      ,
                                                                pi_entity_type_code         => c_entity_type_community            ,
                                                                pi_entity_id                => v_list_community(indy).community_id,
                                                                pi_entity_type_code_process => pi_entity_type_code                ,
                                                                pi_entity_id_process        => pi_entity_id                       ,
                                                                pi_entity_component_id      => v_tr_entity.entity_component_id    ,
                                                                pi_client_id                => v_tr_entity.client_id              ,
                                                                pi_community_id             => v_tr_entity.community_id           ,
                                                                pi_cen_id                   => v_tr_entity.ce_id                  ,
                                                                -- Tariff Keys
                                                                pi_client_type_code         => v_tr_entity.client_type_code       ,
                                                                pi_client_segment_code      => v_tr_entity.client_segment_code    ,
                                                                pi_community_area_code      => v_tr_entity.community_area_code    ,
                                                                pi_ce_type_code             => v_tr_entity.ce_type_code           ,
                                                                pi_ce_area_code             => v_tr_entity.ce_area_code           ,
                                                                pi_entity_ageing            => v_tr_entity.entity_ageing          ,
                                                                pi_plan_category_code       => v_tr_entity.plan_category_code     ,
                                                                pi_plan_category_id         => v_tr_entity.plan_category_id       ,   --value_id of plan_category_code
                                                                pi_plan_code                => v_tr_entity.plan_code              ,
                                                                pi_entity_plan_id           => v_tr_entity.entity_plan_id         ,   --value_id of plan_code
                                                                pi_component_code           => v_tr_entity.component_code         ,
                                                                pi_add_data1                => v_tr_entity.add_data1              ,
                                                                pi_add_data2                => v_tr_entity.add_data2              ,
                                                                pi_add_data3                => v_tr_entity.add_data3              ,
                                                                pi_add_data4                => v_tr_entity.add_data4              ,
                                                                pi_add_data5                => v_tr_entity.add_data5              ,
                                                                --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                                pi_component_amount         => v_entity.component_amount          ,
                                                                --<ASV Control: 299 25/04/2012 17:02:00>
                                                                pi_start_date               => v_entity.start_date                ,
                                                                pi_end_date                 => v_entity.end_date                  ,
                                                                --cycle data
                                                                pi_cycle_id                 => pi_cycle_id                        ,
                                                                pi_cycle_start_date         => pi_cycle_start_date                ,
                                                                pi_cycle_end_date           => pi_cycle_end_date                  ,
                                                                pi_credit_unit_code         => v_entity.credit_unit_code          ,
                                                                pi_billing_start_date       => pi_billing_start_date              ,
                                                                pi_billing_end_date         => pi_billing_end_date                ,
                                                                pi_billing_type_code        => pi_billing_type_code               ,
                                                                pi_billing_class_code       => pi_billing_class_code              ,
                                                                --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                                pi_billing_tran_id          => pi_billing_tran_id                 ,
                                                                pi_tran_id                  => v_tran_id                          ,
                                                                --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                                pi_tran_date                => pi_tran_date                       ,
                                                                pi_asynchronous_status      => c_delivered                        ,
                                                                po_error_code               => po_error_code                      ,
                                                                po_error_msg                => po_error_msg                       );

                    IF NVL(po_error_code,'NOK') <> 'OK' THEN
                      RAISE ERR_APP;
                    END IF;
                  END IF;  
                END IF;
              END LOOP;
              --Aqui llamamos a las CRUs genericas a nivel de COMMUNITY
              --para las CRUs Genericas
              IF v_entity_component_id IS NOT NULL AND v_tr_entity.ce_id IS NOT NULL THEN

                FOR v_rec_cru_generic IN tcur_credit_unit_free(pi_billing_end_date, pi_telco_code) LOOP
                  --<ASV Control:299 Date:12/11/2012 10:27:30 Update process CRUS genericas, for the consulting first if exists rate for the CRU before processing>
                  --COnsulting if exists rate for CRU.
                  CRU.BL_UTILITIES.QUERY_GET_RATE_AMOUNT( pi_telco_code          => pi_telco_code                     ,
                                                          pi_entity_type_code    => c_entity_type_community           ,
                                                          pi_entity_id           => v_list_community(indy).community_id,
                                                          pi_client_type_code    => v_tr_entity.client_type_code      ,
                                                          pi_client_segment_code => v_tr_entity.client_segment_code   ,
                                                          pi_community_area_code => v_tr_entity.community_area_code   ,
                                                          pi_ce_type_code        => v_tr_entity.ce_type_code          ,
                                                          pi_ce_area_code        => v_tr_entity.ce_area_code          ,
                                                          pi_entity_ageing       => v_tr_entity.entity_ageing         ,
                                                          pi_plan_category_code  => v_tr_entity.plan_category_code    ,
                                                          pi_plan_code           => v_tr_entity.plan_code             ,
                                                          pi_component_code      => v_tr_entity.component_code        ,
                                                          pi_add_data1           => v_tr_entity.add_data1             ,
                                                          pi_add_data2           => v_tr_entity.add_data2             ,
                                                          pi_add_data3           => v_tr_entity.add_data3             ,
                                                          pi_add_data4           => v_tr_entity.add_data4             ,
                                                          pi_add_data5           => v_tr_entity.add_data5             ,
                                                          pi_evaluate_date       => pi_tran_date                      ,
                                                          pi_credit_unit_code    => v_rec_cru_generic.credit_unit_code,
                                                          pi_tran_id             => pi_billing_tran_id                ,
                                                          pi_tran_date           => pi_tran_date                      ,
                                                          po_rate_id             => v_rate_id                         ,
                                                          po_rate_quantity       => v_rate_quantity                   ,
                                                          po_error_code          => po_error_code                     ,
                                                          po_error_msg           => po_error_msg                      );
                  
                  IF NVL(po_error_code,'NOK') <> 'OK' THEN
                    RAISE ERR_APP;
                  END IF;              
                  
                  IF ( v_rate_quantity IS NOT NULL AND v_rate_quantity > 0 ) THEN
                    /* llamamos al  proceso generico de asignacion de datos */
                    CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                      ,
                                                                pi_entity_type_code         => c_entity_type_community            ,
                                                                pi_entity_id                => v_list_community(indy).community_id,
                                                                pi_entity_type_code_process => pi_entity_type_code                ,
                                                                pi_entity_id_process        => pi_entity_id                       ,
                                                                pi_entity_component_id      => v_entity_component_id              ,
                                                                pi_client_id                => v_tr_entity.client_id              ,
                                                                pi_community_id             => v_tr_entity.community_id           ,
                                                                pi_cen_id                   => v_tr_entity.ce_id                  ,
                                                                -- Tariff Keys
                                                                pi_client_type_code         => v_tr_entity.client_type_code       ,
                                                                pi_client_segment_code      => v_tr_entity.client_segment_code    ,
                                                                pi_community_area_code      => v_tr_entity.community_area_code    ,
                                                                pi_ce_type_code             => v_tr_entity.ce_type_code           ,
                                                                pi_ce_area_code             => v_tr_entity.ce_area_code           ,
                                                                pi_entity_ageing            => v_tr_entity.entity_ageing          ,
                                                                pi_plan_category_code       => v_tr_entity.plan_category_code     ,
                                                                pi_plan_category_id         => v_tr_entity.plan_category_id       ,  --value_id of plan_category_code
                                                                pi_plan_code                => v_tr_entity.plan_code              ,
                                                                pi_entity_plan_id           => v_tr_entity.entity_plan_id         ,   --value_id of plan_code
                                                                pi_component_code           => v_tr_entity.component_code         ,
                                                                pi_add_data1                => v_tr_entity.add_data1              ,
                                                                pi_add_data2                => v_tr_entity.add_data2              ,
                                                                pi_add_data3                => v_tr_entity.add_data3              ,
                                                                pi_add_data4                => v_tr_entity.add_data4              ,
                                                                pi_add_data5                => v_tr_entity.add_data5              ,
                                                                --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                                pi_component_amount         => NULL                               ,
                                                                --<ASV Control: 299 25/04/2012 17:02:00>
                                                                pi_start_date               => pi_billing_start_date              ,
                                                                pi_end_date                 => pi_billing_end_date                ,
                                                                ---data cycle
                                                                pi_cycle_id                 => pi_cycle_id                        ,
                                                                pi_cycle_start_date         => pi_cycle_start_date                ,
                                                                pi_cycle_end_date           => pi_cycle_end_date                  ,
                                                                pi_credit_unit_code         => v_rec_cru_generic.credit_unit_code ,
                                                                pi_billing_start_date       => pi_billing_start_date              ,
                                                                pi_billing_end_date         => pi_billing_end_date                ,
                                                                ---billing data
                                                                pi_billing_type_code        => pi_billing_type_code               ,
                                                                pi_billing_class_code       => pi_billing_class_code              ,
                                                                --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                                pi_billing_tran_id          => pi_billing_tran_id                 ,
                                                                pi_tran_id                  => v_tran_id                          ,
                                                                --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                                pi_tran_date                => pi_tran_date                       ,
                                                                pi_asynchronous_status      => c_delivered                        ,
                                                                po_error_code               => po_error_code                      ,
                                                                po_error_msg                => po_error_msg                       );

                    IF NVL(po_error_code,'NOK') <> 'OK' THEN
                      RAISE ERR_APP;
                    END IF;
                  END IF;
                  --<ASV Control:299 Date:12/11/2012 10:27:30>
                END LOOP;
              END IF;   --fin de Genericos para COMMUNITY
              -- Fin de CRU genericas a nivel de COMMUNITY
            END LOOP;
          END IF;
          ------- desde aqui procesamos para cen
          --PROCESAR A NIVEL INFERIOR DE COMUNIDAD --> (a nivela de Entidad de cosumo)
          v_list_consumption_entity := CUS.TX_PUBLIC_CRU.GET_RECORDS_EC( pi_telco_code   => pi_telco_code,
                                                                         pi_community_id => v_list_community(indy).community_id,--pi_entity_id       ,
                                                                         pi_date         => pi_billing_end_date);
          IF v_list_consumption_entity.COUNT > 0 THEN

            FOR indx IN v_list_consumption_entity.FIRST .. v_list_consumption_entity.LAST LOOP

              v_tr_entity := NULL;
              
              --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity> 
              v_tran_id := ITF.TX_PUBLIC_CRU.GET_TRAN_ID;
              --<ASV Control:299 Date:08/06/2012 11:27:30>
              
              FOR v_entity IN tcur_entity(v_list_consumption_entity(indx).consumption_entity_id, c_entity_type_comsup_entity, pi_telco_code)LOOP
                v_entity_component_id := v_entity.entity_component_id;
                
                /*obtenemos los keys*/
                CUS.TX_PUBLIC_CRU.GET_TARIFF_KEY_ALL( pi_telco_code           => pi_telco_code                   ,
                                                      pi_entity_type_code     => c_entity_type_comsup_entity     ,--ingresa como entidad de consumo
                                                      pi_entity_id            => v_list_consumption_entity(indx).consumption_entity_id, ---es igual al entity_id
                                                      pi_date                 => pi_billing_end_date             , --OJO fecha de entrada
                                                      pi_entity_component_id  => v_entity.entity_component_id    ,
                                                      pi_tran_id              => v_tran_id                       ,
                                                      po_client_id            => v_tr_entity.client_id           ,
                                                      po_community_id         => v_tr_entity.community_id        ,
                                                      po_cen_id               => v_tr_entity.ce_id               ,
                                                      -- Tariff Keys
                                                      po_client_type_code     => v_tr_entity.client_type_code    ,
                                                      po_client_segment_code  => v_tr_entity.client_segment_code ,
                                                      po_community_area_code  => v_tr_entity.community_area_code ,
                                                      po_ce_type_code         => v_tr_entity.ce_type_code        ,
                                                      po_ce_area_code         => v_tr_entity.ce_area_code        ,
                                                      po_entity_ageing        => v_tr_entity.entity_ageing       ,
                                                      po_plan_category_code   => v_tr_entity.plan_category_code  ,
                                                      po_plan_category_id     => v_tr_entity.plan_category_id    ,  --value_id of plan_category_code
                                                      po_plan_code            => v_tr_entity.plan_code           ,
                                                      po_entity_plan_id       => v_tr_entity.entity_plan_id      ,   --value_id of plan_code
                                                      po_component_code       => v_tr_entity.component_code      ,
                                                      po_add_data1            => v_tr_entity.add_data1           ,
                                                      po_add_data2            => v_tr_entity.add_data2           ,
                                                      po_add_data3            => v_tr_entity.add_data3           ,
                                                      po_add_data4            => v_tr_entity.add_data4           ,
                                                      po_add_data5            => v_tr_entity.add_data5           ,
                                                      -- Tariff Keys END
                                                      po_error_code           => po_error_code                   ,
                                                      po_error_msg            => po_error_msg                    );

                IF NVL(po_error_code,'NOK') <> 'OK' THEN
                  RAISE ERR_APP;
                END IF;

                /* Verificamos si el cliente es corporativo*/
                CRU.BL_UTILITIES.CHECK_VALID_CLIENT_TYPE( pi_telco_code       => pi_telco_code               ,
                                                          pi_client_type_code => v_tr_entity.client_type_code,
                                                          pi_date             => pi_billing_end_date	       ,
                                                          pi_tran_id          => v_tran_id                   ,
                                                          po_chekeable        => v_check_client_type         ,
                                                          po_error_code       => po_error_code               ,
                                                          po_error_msg        => po_error_msg                );
                IF NVL(po_error_code,'NOK') <> 'OK' THEN
                  RAISE ERR_APP;
                END IF;
                /* Si el cliente es corporativo */
                IF v_check_client_type = c_true  THEN

                  CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                   ,
                                                              pi_entity_type_code         => c_entity_type_comsup_entity     , --ojo esto procesa a nivel de community o tiene q ser / c_entity_type_comsup_entity
                                                              pi_entity_id                => v_list_consumption_entity(indx).consumption_entity_id,
                                                              pi_entity_type_code_process => pi_entity_type_code             ,
                                                              pi_entity_id_process        => pi_entity_id                    ,
                                                              pi_entity_component_id      => v_entity.entity_component_id    ,
                                                              pi_client_id                => v_tr_entity.client_id           ,
                                                              pi_community_id             => v_tr_entity.community_id        ,
                                                              pi_cen_id                   => v_tr_entity.ce_id               ,
                                                              -- Tariff Keys
                                                              pi_client_type_code         => v_tr_entity.client_type_code    ,
                                                              pi_client_segment_code      => v_tr_entity.client_segment_code ,
                                                              pi_community_area_code      => v_tr_entity.community_area_code ,
                                                              pi_ce_type_code             => v_tr_entity.ce_type_code        ,
                                                              pi_ce_area_code             => v_tr_entity.ce_area_code        ,
                                                              pi_entity_ageing            => v_tr_entity.entity_ageing       ,
                                                              pi_plan_category_code       => v_tr_entity.plan_category_code  ,
                                                              pi_plan_category_id         => v_tr_entity.plan_category_id    ,  --value_id of plan_category_code
                                                              pi_plan_code                => v_tr_entity.plan_code           ,
                                                              pi_entity_plan_id           => v_tr_entity.entity_plan_id      ,   --value_id of plan_code
                                                              pi_component_code           => v_tr_entity.component_code      ,
                                                              pi_add_data1                => v_tr_entity.add_data1           ,
                                                              pi_add_data2                => v_tr_entity.add_data2           ,
                                                              pi_add_data3                => v_tr_entity.add_data3           ,
                                                              pi_add_data4                => v_tr_entity.add_data4           ,
                                                              pi_add_data5                => v_tr_entity.add_data5           ,
                                                              --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                              pi_component_amount         => v_entity.component_amount      ,
                                                              --<ASV Control: 299 25/04/2012 17:02:00>
                                                              pi_start_date               => v_entity.start_date             ,
                                                              pi_end_date                 => v_entity.end_date               ,
                                                              ---data cycle
                                                              pi_cycle_id                 => pi_cycle_id                     ,
                                                              pi_cycle_start_date         => pi_cycle_start_date             ,
                                                              pi_cycle_end_date           => pi_cycle_end_date               ,
                                                              pi_credit_unit_code         => v_entity.credit_unit_code       ,
                                                              pi_billing_start_date       => pi_billing_start_date           ,
                                                              pi_billing_end_date         => pi_billing_end_date             ,
                                                              ---billing data
                                                              pi_billing_type_code        => pi_billing_type_code            ,
                                                              pi_billing_class_code       => pi_billing_class_code           ,
                                                              --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                              pi_billing_tran_id          => pi_billing_tran_id              ,
                                                              pi_tran_id                  => v_tran_id                       ,
                                                              --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                              pi_tran_date                => pi_tran_date                    ,
                                                              pi_asynchronous_status      => c_delivered                     ,
                                                              po_error_code               => po_error_code                   ,
                                                              po_error_msg                => po_error_msg                    );

                  IF NVL(po_error_code,'NOK') <> 'OK' THEN
                    RAISE ERR_APP;
                  END IF;
                END IF;
              END LOOP;--Fin de las Instanciacion de CONSUMPTION_ENTITY
              ---Asignacion de CRUs Genericas a nivel de CONSUMPTION_ENTITY
              IF v_entity_component_id IS NOT NULL AND v_tr_entity.ce_id IS NOT NULL THEN

                FOR v_rec_cru_generic IN tcur_credit_unit_free(pi_billing_end_date, pi_telco_code) LOOP
                  --<ASV Control:299 Date:12/11/2012 10:27:30 Update process CRUS genericas, for the consulting first if exists rate for the CRU before processing>
                  --COnsulting if exists rate for CRU.
                  CRU.BL_UTILITIES.QUERY_GET_RATE_AMOUNT( pi_telco_code          => pi_telco_code                     ,
                                                          pi_entity_type_code    => c_entity_type_comsup_entity       ,
                                                          pi_entity_id           => v_list_consumption_entity(indx).consumption_entity_id,
                                                          pi_client_type_code    => v_tr_entity.client_type_code      ,
                                                          pi_client_segment_code => v_tr_entity.client_segment_code   ,
                                                          pi_community_area_code => v_tr_entity.community_area_code   ,
                                                          pi_ce_type_code        => v_tr_entity.ce_type_code          ,
                                                          pi_ce_area_code        => v_tr_entity.ce_area_code          ,
                                                          pi_entity_ageing       => v_tr_entity.entity_ageing         ,
                                                          pi_plan_category_code  => v_tr_entity.plan_category_code    ,
                                                          pi_plan_code           => v_tr_entity.plan_code             ,
                                                          pi_component_code      => v_tr_entity.component_code        ,
                                                          pi_add_data1           => v_tr_entity.add_data1             ,
                                                          pi_add_data2           => v_tr_entity.add_data2             ,
                                                          pi_add_data3           => v_tr_entity.add_data3             ,
                                                          pi_add_data4           => v_tr_entity.add_data4             ,
                                                          pi_add_data5           => v_tr_entity.add_data5             ,
                                                          pi_evaluate_date       => pi_tran_date                      ,
                                                          pi_credit_unit_code    => v_rec_cru_generic.credit_unit_code,
                                                          pi_tran_id             => pi_billing_tran_id                ,
                                                          pi_tran_date           => pi_tran_date                      ,
                                                          po_rate_id             => v_rate_id                         ,
                                                          po_rate_quantity       => v_rate_quantity                   ,
                                                          po_error_code          => po_error_code                     ,
                                                          po_error_msg           => po_error_msg                      );
                  
                  IF NVL(po_error_code,'NOK') <> 'OK' THEN
                    RAISE ERR_APP;
                  END IF;              
                  
                  IF ( v_rate_quantity IS NOT NULL AND v_rate_quantity > 0 ) THEN
                    /* llamamos al  proceso generico de asignacion de datos */
                    CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code               => pi_telco_code                      ,
                                                                pi_entity_type_code         => c_entity_type_comsup_entity        ,
                                                                pi_entity_id                => v_list_consumption_entity(indx).consumption_entity_id,
                                                                pi_entity_type_code_process => pi_entity_type_code                ,
                                                                pi_entity_id_process        => pi_entity_id                       ,
                                                                pi_entity_component_id      => v_entity_component_id              ,
                                                                pi_client_id                => v_tr_entity.client_id              ,
                                                                pi_community_id             => v_tr_entity.community_id           ,
                                                                pi_cen_id                   => v_tr_entity.ce_id                  ,
                                                                -- Tariff Keys
                                                                pi_client_type_code         => v_tr_entity.client_type_code       ,
                                                                pi_client_segment_code      => v_tr_entity.client_segment_code    ,
                                                                pi_community_area_code      => v_tr_entity.community_area_code    ,
                                                                pi_ce_type_code             => v_tr_entity.ce_type_code           ,
                                                                pi_ce_area_code             => v_tr_entity.ce_area_code           ,
                                                                pi_entity_ageing            => v_tr_entity.entity_ageing          ,
                                                                pi_plan_category_code       => v_tr_entity.plan_category_code     ,
                                                                pi_plan_category_id         => v_tr_entity.plan_category_id       ,  --value_id of plan_category_code
                                                                pi_plan_code                => v_tr_entity.plan_code              ,
                                                                pi_entity_plan_id           => v_tr_entity.entity_plan_id         ,   --value_id of plan_code
                                                                pi_component_code           => v_tr_entity.component_code         ,
                                                                pi_add_data1                => v_tr_entity.add_data1              ,
                                                                pi_add_data2                => v_tr_entity.add_data2              ,
                                                                pi_add_data3                => v_tr_entity.add_data3              ,
                                                                pi_add_data4                => v_tr_entity.add_data4              ,
                                                                pi_add_data5                => v_tr_entity.add_data5              ,
                                                                --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                                pi_component_amount         => NULL                               ,
                                                                --<ASV Control: 299 25/04/2012 17:02:00>
                                                                pi_start_date               => pi_billing_start_date              ,
                                                                pi_end_date                 => pi_billing_end_date                ,
                                                                ---data cycle
                                                                pi_cycle_id                 => pi_cycle_id                        ,
                                                                pi_cycle_start_date         => pi_cycle_start_date                ,
                                                                pi_cycle_end_date           => pi_cycle_end_date                  ,
                                                                pi_credit_unit_code         => v_rec_cru_generic.credit_unit_code ,
                                                                pi_billing_start_date       => pi_billing_start_date              ,
                                                                pi_billing_end_date         => pi_billing_end_date                ,
                                                                ---billing data
                                                                pi_billing_type_code        => pi_billing_type_code               ,
                                                                pi_billing_class_code       => pi_billing_class_code              ,
                                                               --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                                pi_billing_tran_id          => pi_billing_tran_id                 ,
                                                                pi_tran_id                  => v_tran_id                          ,
                                                                --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                                pi_tran_date                => pi_tran_date                       ,
                                                                pi_asynchronous_status      => c_delivered                        ,
                                                                po_error_code               => po_error_code                      ,
                                                                po_error_msg                => po_error_msg                       );

                    IF NVL(po_error_code,'NOK') <> 'OK' THEN
                      RAISE ERR_APP;
                    END IF;
                  END IF;
                  --<ASV Control:299 Date:12/11/2012 10:27:30>
                END LOOP;
              END IF;   --fin de Genericos para CONSUMPTION_ENTITY
              ---FIN de CRUs Genericas a nivel de CONSUMPTION_ENTITY
            END LOOP; --Fin del cursor de CONSUMPTION_ENTITY

          END IF;  --Fin de SI existe entity_component
        END LOOP; --Fin del cursor de COMMUNITY
      END IF;
      
      --Mandamos todo en bulk
      --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
      IF c_billing_real = pi_billing_type_code THEN
        FOR v_rec IN (SELECT DISTINCT l.start_tran_id
                        FROM CRU.TR_ENTITY_LOG l
                       WHERE l.telco_code      = pi_telco_code
                         AND l.billing_tran_id = pi_billing_tran_id
                         AND l.start_tran_date = pi_tran_date
                         AND l.status         <> c_inactive)LOOP
          v_credits_unit_assign := CRU.BL_UTILITIES.GET_CREDIT_UNIT_ASSIGN(pi_telco_code, pi_cycle_start_date, pi_cycle_end_date,v_rec.start_tran_id, pi_tran_date);
          IF v_credits_unit_assign.count > 0 THEN

              ITF.TX_PUBLIC_CRU.NOTIFY_EXISTS_CREDIT_UNIT( pi_telco_code     => pi_telco_code       ,
                                                           pi_scheduled_date => pi_billing_end_date +( NUMTODSINTERVAL(1,'SECOND')),
                                                           pi_tran_id        => v_rec.start_tran_id ,
                                                           pi_date           => pi_tran_date        ,
                                                           po_error_code     => po_error_code       ,
                                                           po_error_msg      => po_error_msg        );

            IF NVL(po_error_code,'NOK') <> 'OK' THEN
              RAISE ERR_APP;
            END IF;
          END IF;
        END LOOP;  
      END IF;
      --<ASV Control:299 Date:08/06/2012 11:27:30>
      
    ELSE
      po_error_code := 'CRU-0005'; --This process is not realized actions for the entity_type value.||Este proceso no realiza acciones para el valor del entity_type.
      RAISE ERR_APP;
    END IF;
    
    --<ASV Control:299 17/04/2012 10:00:00 Change in the process of integration with ESB> 
    /*IF c_billing_real = pi_billing_type_code THEN
    --This notify exists credit unit os dosage
      v_credits_unit_assign := CRU.BL_UTILITIES.GET_CREDIT_UNIT_ASSIGN(pi_cycle_start_date, pi_cycle_end_date,pi_billing_tran_id, pi_tran_date);

      IF v_credits_unit_assign.count > 0 THEN
        --
        INSERT INTO CRU.test_svar(tran_id, TIMESTAMP)
             VALUES (pi_billing_tran_id, current_TIMESTAMP);
        --
        ITF.TX_PUBLIC_CRU.NOTIFY_EXISTS_CREDIT_UNIT( pi_scheduled_date => pi_billing_end_date +( NUMTODSINTERVAL(1,'SECOND')),
                                                     pi_tran_id        => pi_billing_tran_id   ,
                                                     pi_date           => pi_tran_date         ,
                                                     po_error_code     => po_error_code        ,
                                                     po_error_msg      => po_error_msg         );
        --
        INSERT INTO CRU.test_svar(tran_id, TIMESTAMP)
             VALUES (pi_billing_tran_id, current_TIMESTAMP);
        --
        IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
        END IF;
      END IF;
    END IF; */
    --<ASV Control:299 17/04/2012 10:00:00>
    
  EXCEPTION
      WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in := ------------------------------------ variable parameters ---------------------------------
                  'pi_telco_code:'          || pi_telco_code                                           ||
                  '|pi_entity_type_code:'   || pi_entity_type_code                                     ||
                  '|pi_entity_id:'          || pi_entity_id                                            ||
                  '|pi_cycle_id:'           || pi_cycle_id                                             ||
                  '|pi_cycle_start_date:'   || TO_CHAR (pi_cycle_start_date, 'DD/MM/YYYY HH24:MI:SS')  ||
                  '|pi_cycle_end_date:'     || TO_CHAR (pi_cycle_end_date, 'DD/MM/YYYY HH24:MI:SS')    ||
                  '|pi_billing_start_date:' || TO_CHAR (pi_billing_start_date, 'DD/MM/YYYY HH24:MI:SS')||
                  '|pi_billing_end_date:'   || TO_CHAR (pi_billing_end_date, 'DD/MM/YYYY HH24:MI:SS')  ||
                  '|pi_billing_type_code:'  || pi_billing_type_code                                    ||
                  '|pi_billing_class_code:' || pi_billing_class_code                                   ||
                  '|pi_billing_tran_id:'    || pi_billing_tran_id                                      ||
                  '|pi_tran_date:'          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')          ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code     ,
                                      pi_tran_id      => pi_billing_tran_id,
                                      pi_error_code   => po_error_code     ,
                                      pi_error_msg    => po_error_msg      ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));
    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code := 'CRU-0006';--Critical error.||Error critico.
      v_param_in    := ------------------------------------ variable parameters ---------------------------------
                    'pi_telco_code:'          || pi_telco_code                                           ||
                    '|pi_entity_type_code:'   || pi_entity_type_code                                     ||
                    '|pi_entity_id:'          || pi_entity_id                                            ||
                    '|pi_cycle_id:'           || pi_cycle_id                                             ||
                    '|pi_cycle_start_date:'   || TO_CHAR (pi_cycle_start_date, 'DD/MM/YYYY HH24:MI:SS')  ||
                    '|pi_cycle_end_date:'     || TO_CHAR (pi_cycle_end_date, 'DD/MM/YYYY HH24:MI:SS')    ||
                    '|pi_billing_start_date:' || TO_CHAR (pi_billing_start_date, 'DD/MM/YYYY HH24:MI:SS')||
                    '|pi_billing_end_date:'   || TO_CHAR (pi_billing_end_date, 'DD/MM/YYYY HH24:MI:SS')  ||
                    '|pi_billing_type_code:'  || pi_billing_type_code                                    ||
                    '|pi_billing_class_code:' || pi_billing_class_code                                   ||
                    '|pi_billing_tran_id:'    || pi_billing_tran_id                                      ||
                    '|pi_tran_date:'          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')          ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code     ,
                                      pi_tran_id      => pi_billing_tran_id,
                                      pi_error_code   => po_error_code     ,
                                      pi_error_msg    => po_error_msg      ,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));

  END;

   /*
    Process CREDIT UNIT PROCESS GENERIC receiving all parameters values
  %Date          08/11/2010 10:24:07
  %Control       60083
  %Author        "Abel Soto"
  %Version       1.0.0
      %param         pi_telco_code                    Telco Code
      %param         pi_entity_type_code              Entity type code
      %param         pi_entity_id                     Entity identifier
      %param         pi_entity_type_code_process      Entity type code process
      %param         pi_entity_id_process             Entity identifier process
      %param         pi_entity_component_id           Entity component identifier
      %param         pi_client_id                     Client iddentifier
      %param         pi_community_id                  Community identifier
      %param         pi_cen_id                        Consumption entity identifier
      %param         pi_client_type_code              Client type code
      %param         pi_client_segment_code           Client segment code
      %param         pi_community_area_code           Community area code
      %param         pi_ce_type_code                  Consumption entity type code
      %param         pi_ce_area_code                  Consumption entity area code
      %param         pi_entity_ageing                 Entity ageing
      %param         pi_plan_category_code            Plan category code
      %param         pi_plan_category_id              Plan category identifier
      %param         pi_plan_code                     Plan code
      %param         pi_entity_plan_id                Entity plan identifier
      %param         pi_component_code                Component code
      %param         pi_add_data1                     Additional data1
      %param         pi_add_data2                     Additional data2
      %param         pi_add_data3                     Additional data3
      %param         pi_add_data4                     Additional data4
      %param         pi_add_data5                     Additional data5
      %param         pi_start_date                    Start date
      %param         pi_end_date                      End date
      %param         pi_cycle_id                      Cycle identifier
      %param         pi_cycle_start_date              Cycle start date
      %param         pi_cycle_end_date                Cycle end date
      %param         pi_credit_unit_code              Credit unit code
      %param         pi_billing_start_date            Billing start date
      %param         pi_billing_end_date              Billing end date
      %param         pi_billing_type_code             Billing type code       Real or Estimate
      %param         pi_billing_class_code            Billing class code      On demand
      %param         pi_billing_tran_id               Billing tran identifier
      %param         pi_tran_id                       Transaction identifier
      %param         pi_tran_date                     Transaction date
      %param         pi_asynchronous_status           Asynchronous status (1) true or (0) false
      %param         po_error_code                    Output showing one of the next results:
                                                      {*} OK - If procedure executed satisfactorily
                                                      {*} XXX-#### - Error code if any error found
      %param         po_error_msg                     Output showing the error message if any error found
      %raises        ERR_APP                          Application level error

  %Changes
      <hr>
        {*}Date       23/03/2012 12:00:00
        {*}Control    299 
        {*}Author     "Abel Soto Vera"
        {*}Note       Addition of functionality to calculate the expiration date, taking into account 
                      that the calculation starts from the cycle start date and adding a number 
                      of days configured in cf_credit_unit.
      <hr>
        {*}Date       19/04/2012 12:00:00
        {*}Control    299 
        {*}Author     "Abel Soto Vera"
        {*}Note       Modification of the process generic, change in the obtainment of device data.
      <hr>
        {*}Date       25/04/2012 17:02:00
        {*}Control    299
        {*}Author     "Abel Soto Vera"
        {*}Note       Modify procedure for included parameter type XMLtype for overwrite data of the billing elements.
      <hr>
        {*}Date       08/06/2012 11:27:30
        {*}Control    299
        {*}Author     "Abel Soto Vera"
        {*}Note       Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity
        
      <hr>
        {*}Date       14/01/2013 11:00:00
        {*}Control    299 
        {*}Author     "Abel Soto Vera"
        {*}Note       Modification of CRU, to support both the dosage and consumption of credit units, that for payment Post.
      <hr>
        {*}Date       26/09/2013 11:00:00
        {*}Control    160121 
        {*}Author     "Abel Soto Vera"
        {*}Note       Billing - Multi operator custom (Change Management)
  */


  PROCEDURE CREDIT_UNIT_PROCESS_GENERIC( pi_telco_code                IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE             ,
                                         pi_entity_type_code          IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE        ,
                                         pi_entity_id                 IN  CRU.TR_ENTITY_LOG.entity_id%TYPE               ,
                                         pi_entity_type_code_process  IN  CRU.TR_ENTITY_LOG.entity_type_code_process%TYPE,
                                         pi_entity_id_process         IN  CRU.TR_ENTITY_LOG.entity_id_process%TYPE       ,
                                         pi_entity_component_id       IN  CRU.TR_ENTITY_LOG.entity_component_id%TYPE     ,
                                         pi_client_id                 IN  CRU.TR_ENTITY_LOG.client_id%TYPE               ,
                                         pi_community_id              IN  CRU.TR_ENTITY_LOG.community_id%TYPE            ,
                                         pi_cen_id                    IN  CRU.TR_ENTITY_LOG.ce_id%TYPE                   ,
                                             -- Tariff Keys
                                         pi_client_type_code          IN  CRU.TR_ENTITY_LOG.client_type_code%TYPE        ,
                                         pi_client_segment_code       IN  CRU.TR_ENTITY_LOG.client_segment_code%TYPE     ,
                                         pi_community_area_code       IN  CRU.TR_ENTITY_LOG.community_area_code%TYPE     ,
                                         pi_ce_type_code              IN  CRU.TR_ENTITY_LOG.ce_type_code%TYPE            ,
                                         pi_ce_area_code              IN  CRU.TR_ENTITY_LOG.ce_area_code%TYPE            ,
                                         pi_entity_ageing             IN  CRU.TR_ENTITY_LOG.entity_ageing%TYPE           ,
                                         pi_plan_category_code        IN  CRU.TR_ENTITY_LOG.plan_category_code%TYPE      ,
                                         pi_plan_category_id          IN  CRU.TR_ENTITY_LOG.plan_category_id%TYPE        ,  --value_id of plan_category_code
                                         pi_plan_code                 IN  CRU.TR_ENTITY_LOG.plan_code%TYPE               ,
                                         pi_entity_plan_id            IN  CRU.TR_ENTITY_LOG.entity_plan_id%TYPE          ,   --value_id of plan_code
                                         pi_component_code            IN  CRU.TR_ENTITY_LOG.component_code%TYPE          ,
                                         pi_add_data1                 IN  CRU.TR_ENTITY_LOG.add_data1%TYPE               ,
                                         pi_add_data2                 IN  CRU.TR_ENTITY_LOG.add_data2%TYPE               ,
                                         pi_add_data3                 IN  CRU.TR_ENTITY_LOG.add_data3%TYPE               ,
                                         pi_add_data4                 IN  CRU.TR_ENTITY_LOG.add_data4%TYPE               ,
                                         pi_add_data5                 IN  CRU.TR_ENTITY_LOG.add_data5%TYPE               ,
                                         --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                         pi_component_amount          IN  CRU.TR_ENTITY_CREDIT_UNIT.component_amount%TYPE,
                                         --<ASV Control: 299 25/04/2012 17:02:00>
                                         pi_start_date                IN  DATE                                           ,
                                         pi_end_date                  IN  DATE                                           ,
                                         ---cycle data
                                         pi_cycle_id                  IN  CRU.TR_ENTITY_LOG.cycle_id%TYPE                ,
                                         pi_cycle_start_date          IN  DATE                                           ,
                                         pi_cycle_end_date            IN  DATE                                           ,
                                         pi_credit_unit_code          IN  CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE       ,
                                         pi_billing_start_date        IN  DATE                                           ,
                                         pi_billing_end_date          IN  DATE                                           ,
                                         pi_billing_type_code         IN  VARCHAR2                                       ,
                                         pi_billing_class_code        IN  VARCHAR2                                       ,
                                         --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                         pi_billing_tran_id           IN CRU.TR_ENTITY_LOG.billing_tran_id%TYPE          ,
                                         --<ASV Control:299 Date:08/06/2012 11:27:30>
                                         pi_tran_id                   IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE          ,
                                         pi_tran_date                 IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE        ,
                                         pi_asynchronous_status       IN  CRU.TR_ENTITY_LOG.ASYNCHRONOUS_STATUS%TYPE     ,
                                         po_error_code                OUT VARCHAR2                                       ,
                                         po_error_msg                 OUT VARCHAR2                                       ) IS

  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.CREDIT_UNIT_PROCESS_GENERIC';
    v_param_in          VARCHAR2(4000)                                              ;

 
  --constant
    c_expiration_end_cycle     CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'DATE_EXPIRATION_CRU_END_CYCLE', SYSDATE);
    --<ASV 23/03/2012 12:00:00 CONTROL:299  Obtain domain code expiration START cycle>
    c_expiration_start_cycle   CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'DATE_EXPIRATION_CRU_START_CYCLE', SYSDATE);
    --<ASV 23/03/2012 12:00:00 CONTROL:299>
    c_expiration_current       CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'DATE_EXPIRATION_CRU_CURRENT', SYSDATE);
    c_expiration_process       CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'DATE_EXPIRATION_CRU_PROCESS', SYSDATE);
    c_expiration_no_expiration CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'DATE_EXPIRATION_CRU_NO_EXPIRATION', SYSDATE);
    c_level_client             CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'ENTITY_TYPE_CLIENT',SYSDATE);
    c_end_date                 CONSTANT DATE                           := ITF.TX_PUBLIC_CRU.GET_END_DATE(SYSDATE);
    
    v_entity_log_id              NUMBER;
    v_chekeable                  VARCHAR2(1);
    v_entity_status_code         VARCHAR2(50);
    v_cf_credit_unit             CRU.CF_CREDIT_UNIT%ROWTYPE; --CRU.BL_UTILITIES.TR_DATA_CRU;
    v_tr_entity                  CRU.TR_ENTITY_LOG%ROWTYPE;
    v_community_cycle            CUS.COMMUNITY_CYCLE%ROWTYPE;
    v_cycle_interval             BIL.CF_CYCLE_INTERVAL%ROWTYPE;
    v_cycle_code                 VARCHAR2(50);
    v_expiration_date            DATE;
    v_expiration_date_balance    DATE;
    --<ASV 19/04/2012 12:00:00  Control:299 Change in the obtainment of device data>
    v_balance_name               CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE;
    v_balance_amount             CRU.CF_CRU_RATE.quantity%TYPE;
    --<ASV 19/04/2012 12:00:00  Control:299>
    v_start_date_calc_expiration DATE;
    v_prorrateable_start_date    DATE;
    v_prorrateable_end_date      DATE;
    v_date_process               DATE;
    --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
    v_exists                     VARCHAR2(5);
    --<ASV Control:299 Date:08/06/2012 11:27:30>   
    --<ASV Control: 299 14/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
    vr_rate                     CRU.CF_CRU_RATE%ROWTYPE   ;
    v_jurisdiction_type_code    CRU.CF_CRU_EVALUATE_USG.jurisdiction_type_code%TYPE;
    v_entity_spend_master_id    CRU.TR_ENTITY_SPEND_MASTER.entity_spend_master_id%TYPE;
    v_usg_duration              CRU.TR_ENTITY_SPEND_MASTER.usg_duration%TYPE;
    v_usg_amount                CRU.TR_ENTITY_SPEND_MASTER.usg_amount%TYPE;
    v_balance                   CRU.TR_ENTITY_SPEND_MASTER.balance%TYPE;
    --<ASV Control: 299 14/01/2013 11:00:00> 
  ERR_APP EXCEPTION;

  BEGIN

    po_error_code := 'OK';
    po_error_msg  := ''  ;
    v_date_process := SYSDATE;

    -- Validate values nulls of constants
    IF c_expiration_end_cycle     IS NULL OR
       c_expiration_current       IS NULL OR
       c_expiration_process       IS NULL OR
       c_expiration_no_expiration IS NULL OR
       --<ASV 23/03/2012 12:00:00 CONTROL:299  valdity constant>
       c_expiration_start_cycle   IS NULL OR 
       --<ASV 23/03/2012 12:00:00 CONTROL:299>
       c_end_date                 IS NULL OR
       c_level_client             IS NULL THEN
      po_error_code := 'CRU-0007'; --The constants value is null.||Valor de las constantes es nulo.
      po_error_msg  := 'c_expiration_end_cycle: '      || c_expiration_end_cycle                      || '|' ||
                       'c_expiration_current: '        || c_expiration_current                        || '|' ||
                       'c_expiration_process: '        || c_expiration_process                        || '|' ||
                       'c_expiration_no_expiration: '  || c_expiration_no_expiration                  || '|' ||
                       --<ASV 23/03/2012 12:00:00 CONTROL:299  Aditing to string into message>
                       'c_expiration_start_cycle: '    || c_expiration_start_cycle                    || '|' ||
                       --<ASV 23/03/2012 12:00:00 CONTROL:299>
                       'c_end_date: '                  || TO_CHAR(c_end_date,'DD/MM/YYYY HH24:MI:SS') || '|' ||
                       'c_level_client: '              || c_level_client                                      ;
      RAISE ERR_APP;
    END IF;

    IF pi_telco_code               IS NULL OR 
       pi_entity_type_code         IS NULL OR
       pi_entity_id                IS NULL OR
       pi_entity_type_code_process IS NULL OR
       pi_entity_id_process        IS NULL OR
       pi_entity_component_id      IS NULL OR
       pi_client_id                IS NULL OR
       pi_community_id             IS NULL OR
       pi_cen_id                   IS NULL OR
       pi_client_type_code         IS NULL OR
       pi_client_segment_code      IS NULL OR
       pi_community_area_code      IS NULL OR
       pi_ce_type_code             IS NULL OR
       pi_ce_area_code             IS NULL OR
       pi_entity_ageing            IS NULL OR
       pi_plan_category_code       IS NULL OR
       pi_plan_category_id         IS NULL OR
       pi_plan_code                IS NULL OR
       pi_entity_plan_id           IS NULL OR
       pi_component_code           IS NULL OR
       pi_add_data1                IS NULL OR
       pi_add_data2                IS NULL OR
       pi_add_data3                IS NULL OR
       pi_add_data4                IS NULL OR
       pi_add_data5                IS NULL OR
       pi_start_date               IS NULL OR
       pi_end_date                 IS NULL OR
       pi_cycle_id                 IS NULL OR
       pi_cycle_start_date         IS NULL OR
       pi_cycle_end_date           IS NULL OR
       pi_credit_unit_code         IS NULL OR
       pi_billing_start_date       IS NULL OR
       pi_billing_end_date         IS NULL OR
       pi_tran_date                IS NULL OR
       pi_asynchronous_status      IS NULL OR
       pi_billing_type_code        IS NULL OR
       pi_billing_class_code       IS NULL OR
       pi_billing_tran_id          IS NULL OR
       pi_tran_id                  IS NULL THEN
      po_error_code := 'CRU-0008';--Mandatory parameter is null||Parametro obligatorio es null
      RAISE ERR_APP;
    END IF;
    
    IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN('TELCO_GENERIC', 'TELCO_OPERATIONS_CODE', pi_telco_code, pi_start_date) IS NULL THEN
      po_error_code:= 'CRU-0000'; --Domain telco code operation value is null||Valor de dominio telco code operation es nulo
      po_error_msg:= 'pi_telco_code: ' || pi_telco_code ;
      RAISE ERR_APP;
    END IF;

    
    --Verificamos si existe ya el proceso para esta entity_id y cycle_id
    --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
    CRU.BL_UTILITIES.CHECKED_EXISTS_PROCESS( pi_telco_code               => pi_telco_code              ,
                                             pi_entity_type_code         => pi_entity_type_code        ,
                                             pi_entity_id                => pi_entity_id               ,
                                             pi_entity_type_code_process => pi_entity_type_code_process,
                                             pi_entity_id_process        => pi_entity_id_process       ,
                                             pi_entity_component_id      => pi_entity_component_id     ,
                                             pi_credit_unit_code         => pi_credit_unit_code        ,
                                             pi_cycle_id                 => pi_cycle_id                ,
                                             pi_tran_id                  => pi_tran_id                 ,
                                             po_exists                   => v_exists                   ,
                                             po_error_code               => po_error_code              ,
                                             po_error_msg                => po_error_msg               );
    
    IF NVL(po_error_code,'NOK') <> 'OK' THEN
      RAISE ERR_APP;
    END IF;
    --<ASV Control:299 Date:08/06/2012 11:27:30>
    
    IF v_exists = c_false THEN
    
      --verificamos si existe Credit_unit configurado
      CRU.BL_UTILITIES.CHECK_CREDIT_UNIT( pi_telco_code        => pi_telco_code        ,
                                          pi_credit_unit_code  => pi_credit_unit_code  ,
                                          pi_evaluate_date     => pi_billing_start_date,
                                          pi_billing_tran_id   => pi_tran_id           ,
                                          po_credit_unit       => v_cf_credit_unit     ,
                                          po_error_code        => po_error_code        ,
                                          po_error_msg         => po_error_msg         );

      IF NVL(po_error_code,'NOK') <> 'OK' THEN
        RAISE ERR_APP;
      END IF;

      IF v_cf_credit_unit.behavior_type_code = c_behavior_free  THEN

        v_tr_entity.credit_unit_id   :=  v_cf_credit_unit.credit_unit_id;
        v_tr_entity.credit_unit_code :=  v_cf_credit_unit.credit_unit_code;

        v_chekeable := c_true;

        -- Check the status of the entity.
        IF v_chekeable = c_true THEN
          CRU.BL_UTILITIES.CHECK_ENTITY_STATUS( pi_telco_code         => pi_telco_code       ,
                                                pi_entity_type_code   => pi_entity_type_code ,
                                                pi_entity_id          => pi_entity_id        ,
                                                pi_credit_unit_code   => pi_credit_unit_code ,
                                                pi_evaluate_date      => pi_billing_end_date ,  ---OJO con esta fecha
                                                pi_billing_tran_id    => pi_tran_id          ,
                                                po_chekeable          => v_chekeable         ,---OJO esta variable
                                                po_entity_status_code => v_entity_status_code,---OJO esta variable
                                                po_error_code         => po_error_code       ,
                                                po_error_msg          => po_error_msg        );
          IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
          END IF;
        END IF;

        /*Assignation of data in v_tr_entity*/
        v_tr_entity.client_id           := pi_client_id            ;
        v_tr_entity.community_id        := pi_community_id         ;
        v_tr_entity.ce_id               := pi_cen_id               ;
        -- Tariff Keys
        v_tr_entity.client_type_code    := pi_client_type_code     ;
        v_tr_entity.client_segment_code := pi_client_segment_code  ;
        v_tr_entity.community_area_code := pi_community_area_code  ;
        v_tr_entity.ce_type_code        := pi_ce_type_code         ;
        v_tr_entity.ce_area_code        := pi_ce_area_code         ;
        v_tr_entity.entity_ageing       := pi_entity_ageing        ;
        v_tr_entity.plan_category_code  := pi_plan_category_code   ;
        v_tr_entity.plan_category_id    := pi_plan_category_id     ;  --value_id of plan_category_code
        v_tr_entity.plan_code           := pi_plan_code            ;
        v_tr_entity.entity_plan_id      := pi_entity_plan_id       ;   --value_id of plan_code
        v_tr_entity.component_code      := pi_component_code       ;
        v_tr_entity.add_data1           := pi_add_data1            ;
        v_tr_entity.add_data2           := pi_add_data2            ;
        v_tr_entity.add_data3           := pi_add_data3            ;
        v_tr_entity.add_data4           := pi_add_data4            ;
        v_tr_entity.add_data5           := pi_add_data5            ;

        /*fin de assign of data*/
        
        --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
        
        CRU.BL_UTILITIES.GET_RATE_AMOUNT( pi_telco_code               => pi_telco_code                      ,
                                          pi_entity_type_code         => pi_entity_type_code                ,
                                          pi_entity_id                => pi_entity_id                       ,
                                          pi_evaluate_date            => pi_billing_end_date                ,
                                          pi_behavior_type_code       => v_cf_credit_unit.behavior_type_code,
                                          pi_evaluate_amount          => NULL, --VERIFICAR QUE ESTOS VALORES SEAN CORRECTOS
                                          pi_evaluate_duration        => NULL,--VERIFICAR QUE ESTOS VALORES SEAN CORRECTOS
                                          pi_entity_log               => v_tr_entity                        ,
                                          pi_eval_criteria_type_code  => NULL,--v_cf_credit_unit.eval_criteria_type_code,
                                          pi_apply_criteria_type_code => NULL,--v_cf_credit_unit.apply_criteria_type_code,
                                          pi_tran_id                  => pi_tran_id                         ,
                                          po_rate_id                  => v_tr_entity.cru_rate_id            ,
                                          po_rate_quantity            => v_tr_entity.quantity               ,
                                          po_range_id                 => v_tr_entity.cru_range_id           ,
                                          --<ASV Control: 299 14/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
                                          po_vec_rate                 => vr_rate                            ,
                                          --<ASV Control: 299 14/01/2013 11:00:00>
                                          po_error_code               => po_error_code                      ,
                                          po_error_msg                => po_error_msg                       );

        IF NVL(po_error_code,'NOK') <> 'OK' THEN
          RAISE ERR_APP;
        END IF;
        
        IF  pi_component_amount IS NOT NULL AND pi_component_amount <> v_tr_entity.quantity THEN
          --<ASV Control: 160121 26/09/2013 11:00:00 Se comenta esta linea, para no perder la config de tarifa, a pesar q sea sobrescrita>
          --v_tr_entity.cru_rate_id  := 0;
          --<ASV>
          v_tr_entity.quantity     := pi_component_amount;
          v_tr_entity.cru_range_id := NULL;
        END IF;  
        --<ASV Control: 299 25/04/2012 17:02:00>
        
        

         ----PROCESO DE PRORRATEO DEL VALOR QUANTITY
        --<ASV Control: 299 14/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
        --IF v_cf_credit_unit.is_prorrateable = c_true THEN
        IF vr_rate.is_prorrateable = c_true THEN
        --<ASV Control: 299 14/01/2013 11:00:00>  

          CRU.BL_UTILITIES.GET_PRORRATEABLE_TIME_QUANTITY( pi_telco_code              => pi_telco_code             ,
                                                           pi_start_cycle_date        => pi_cycle_start_date       ,
                                                           pi_end_cycle_date          => pi_cycle_end_date         ,
                                                           pi_target_start_date       => pi_start_date             ,--fecha inicio de instanciacion
                                                           pi_target_end_date         => pi_end_date               ,--fecha fin de instanciacion
                                                           pi_quantity                => v_tr_entity.quantity      ,
                                                           pi_end_billing_date        => pi_billing_end_date       ,
                                                           pi_round_method_code       => v_cf_credit_unit.round_method_code,
                                                           pi_billing_tran_id         => pi_tran_id                ,
                                                           po_prorrateable_time       => v_tr_entity.time_rate     ,
                                                           po_prorrateable_quantity   => v_tr_entity.quantity      ,
                                                           po_prorrateable_start_date => v_prorrateable_start_date ,
                                                           po_prorrateable_end_date   => v_prorrateable_end_date   ,
                                                           po_error_code              => po_error_code             ,
                                                           po_error_msg               => po_error_msg              );

          IF NVL(po_error_code,'NOK')!= 'OK'  THEN
            RAISE ERR_APP;
          END IF;
        END IF;
        
        -- Validation of the consistency of data   v_cf_credit_unit by vr_rate
        --<ASV Control: 299 14/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units "v_cf_credit_unit --> vr_rate">
        IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN_ATTRIBUTE(pi_telco_code, 'DATE_EXPIRATION_CRU', vr_rate.date_expiration_type_code, 'BIL_EXPIRATION_DATE',SYSDATE) IS NULL THEN

          po_error_code := 'CRU-0009';--Domain attribute is incorrect or does not exist for the process.||Valor del Dominio atributo es incorrecto o no existe para el proceso.
          po_error_msg  := 'date_expiration_type_code: ' || vr_rate.date_expiration_type_code ;
          RAISE ERR_APP;
        END IF;
        --<ASV Control: 299 14/01/2013 11:00:00>
         ----------------------------------------------------------------
        IF pi_entity_type_code = c_level_client THEN

          BIL.TX_PUBLIC_CRU.GET_DATA_CYCLE_INTERVAL( pi_telco_code          => pi_telco_code     ,
                                                     pi_cycle_id            => pi_cycle_id       ,
                                                     pi_tran_id             => pi_billing_tran_id,
                                                     po_data_cycle_interval => v_cycle_interval  ,
                                                     po_error_code          => po_error_code     ,
                                                     po_error_msg           => po_error_msg      );

          IF NVL(po_error_code,'NOK') <> 'OK' THEN
                  RAISE ERR_APP;
          END IF;

          v_cycle_code:= v_cycle_interval.cycle_code ;

        ELSE
          ---sacamos el cycle_code de la communidad para calcular la fecha de expiracion
          CUS.TX_PUBLIC_CRU.GET_DATA_COMMUNITY_CYCLE( pi_telco_code           => pi_telco_code      ,
                                                      pi_community_id         => pi_community_id    ,
                                                      pi_date                 => pi_billing_end_date,
                                                      pi_tran_id              => pi_tran_id         ,
                                                      po_data_community_cycle => v_community_cycle  ,
                                                      po_error_code           => po_error_code      ,
                                                      po_error_msg            => po_error_msg       );

          IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
          END IF;

          v_cycle_code:= v_community_cycle.cycle_code ;
        END IF ;

        --<ASV Control: 299 14/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units "v_cf_credit_unit --> vr_rate">
        IF vr_rate.date_expiration_type_code = c_expiration_no_expiration THEN
          v_expiration_date := c_end_date;
        --<ASV Control: 299 14/01/2013 11:00:00>  
        ELSE
        
          IF vr_rate.date_expiration_type_code = c_expiration_end_cycle THEN
            --Iniciamos v_start_date_calc_expiration en pi_billing_end_date para el calculo de fecha expiracion
            v_start_date_calc_expiration := pi_cycle_end_date;
          ELSIF vr_rate.date_expiration_type_code = c_expiration_current THEN
            --<ASV 19/04/2012 12:00:00  Control:299 Change in the obtainment of device data>
            ITF.TX_PUBLIC_CRU.GET_CREDIT_UNIT_BALANCE( pi_telco_code        => pi_telco_code                    ,
                                                       pi_credit_unit_code  => v_cf_credit_unit.credit_unit_code,
                                                       pi_entity_id         => pi_entity_id                     ,
                                                       pi_entity_type_code  => pi_entity_type_code              ,
                                                       pi_tran_id           => pi_tran_id                       ,
                                                       pi_date              => pi_billing_end_date              ,
                                                       po_balance           => v_balance_name                   ,
                                                       po_amount            => v_balance_amount                 ,
                                                       po_expire_date       => v_expiration_date_balance        ,
                                                       po_error_code        => po_error_code                    ,
                                                       po_error_msg         => po_error_msg                     );
                                          
            IF NVL(po_error_code,'NOK') <> 'OK' THEN
              RAISE ERR_APP;
            END IF;
            v_start_date_calc_expiration := v_expiration_date_balance;
            --<ASV 19/04/2012 12:00:00  Control:299>
          
          ELSIF vr_rate.date_expiration_type_code = c_expiration_process THEN
            v_start_date_calc_expiration := v_date_process;
          
          --<ASV 23/03/2012 12:00:00 CONTROL:299  add the condition if satisfied date_expiration_type_code equals expiration start cycle >
          ELSIF vr_rate.date_expiration_type_code = c_expiration_start_cycle THEN
            --Iniciamos v_start_date_calc_expiration en pi_billing_start_date para el calculo de fecha expiracion
            v_start_date_calc_expiration := pi_cycle_start_date; 
          --<ASV 23/03/2012 12:00:00 CONTROL:299>
          
          ELSE
            po_error_code := 'CRU-0010'; --The date_expiration_type_code does not configured for this process.||El date_expiration_type_code no esta configurado para le proceso.
            po_error_msg := 'date_expiration_type_code: ' || vr_rate.date_expiration_type_code ;
            RAISE ERR_APP;
          END IF;

          --GENERACION DE LA FECHA DE EXPIRACION
          CRU.BL_UTILITIES.CALCULATE_EXPIRATION_DATE( pi_telco_code                 => pi_telco_code                      ,
                                                      pi_cycle_code                 => v_cycle_code                       ,
                                                      pi_date                       => v_start_date_calc_expiration       , --fecha de inicion de calculo de fecha expiracion
                                                      --<ASV Control: 299 14/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units "v_cf_credit_unit --> vr_rate">
                                                      pi_cycles_quantity_expiration => vr_rate.cycles_quantity_expiration ,
                                                      pi_day_calendar_expiration    => vr_rate.day_calendar_expiration    ,
                                                      pi_expiration_days_quantity   => vr_rate.expiration_days_quantity   ,
                                                      --<ASV Control: 299 14/01/2013 11:00:00>
                                                      pi_tran_id                    => pi_tran_id                         ,
                                                      po_expiration_date            => v_expiration_date                  ,
                                                      po_error_code                 => po_error_code                      ,
                                                      po_error_msg                  => po_error_msg                       );
          IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
          END IF;

        END IF;


        --ALMACENAR LOS DATOS EN TR_ENTITY_LOG
        CRU.TX_TR_ENTITY_LOG.CREATE_( pi_telco_code               => pi_telco_code                     ,
                                      pi_entity_type_code         => pi_entity_type_code               ,
                                      pi_entity_id                => pi_entity_id                      ,
                                      pi_entity_type_code_process => pi_entity_type_code_process       ,
                                      pi_entity_id_process        => pi_entity_id_process              ,
                                      pi_credit_unit_id           => v_tr_entity.credit_unit_id        ,
                                      pi_credit_unit_code         => v_tr_entity.credit_unit_code      ,
                                      pi_client_id                => v_tr_entity.client_id             ,
                                      pi_client_type_code         => v_tr_entity.client_type_code      ,
                                      pi_client_segment_code      => v_tr_entity.client_segment_code   ,
                                      pi_community_id             => v_tr_entity.community_id          ,
                                      pi_community_area_code      => v_tr_entity.ce_area_code          ,
                                      pi_ce_id                    => v_tr_entity.ce_id                 ,
                                      pi_service_identifier       => v_tr_entity.service_identifier    ,
                                      pi_entity_plan_id           => v_tr_entity.entity_plan_id        ,
                                      pi_entity_component_id      => pi_entity_component_id            ,
                                      pi_ce_type_code             => v_tr_entity.ce_type_code          ,
                                      pi_ce_area_code             => v_tr_entity.ce_area_code          ,
                                      pi_entity_ageing            => v_tr_entity.entity_ageing         ,
                                      pi_plan_category_id         => v_tr_entity.plan_category_id      ,
                                      pi_plan_category_code       => v_tr_entity.plan_category_code    ,
                                      pi_plan_code                => v_tr_entity.plan_code             ,
                                      pi_component_code           => v_tr_entity.component_code        ,
                                      pi_add_data1                => v_tr_entity.add_data1             ,
                                      pi_add_data2                => v_tr_entity.add_data2             ,
                                      pi_add_data3                => v_tr_entity.add_data3             ,
                                      pi_add_data4                => v_tr_entity.add_data4             ,
                                      pi_add_data5                => v_tr_entity.add_data5             ,
                                      pi_cru_rate_id              => v_tr_entity.cru_rate_id           ,
                                      pi_cru_range_id             => v_tr_entity.cru_range_id          ,
                                      pi_usg_duration             => NULL                              ,
                                      pi_usg_amount               => NULL                              ,
                                      pi_quantity                 => v_tr_entity.quantity              ,
                                      pi_time_rate                => v_tr_entity.time_rate             ,
                                      pi_cycle_id                 => pi_cycle_id                       ,
                                      pi_start_billing_date       => pi_billing_start_date             ,--pi_start_billing_date,
                                      pi_end_billing_date         => pi_billing_end_date               ,--pi_end_billing_date,
                                      pi_expiration_date          => v_expiration_date                 ,
                                      pi_request_date             => pi_billing_end_date               ,
                                      pi_process_date             => pi_tran_date                      , --pi_billing_end_date,--pi_process_date,
                                      pi_billing_type_code        => pi_billing_type_code              ,
                                      pi_billing_class_code       => pi_billing_class_code             ,
                                      --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                      pi_billing_tran_id          => pi_billing_tran_id                ,
                                      --<ASV Control:299 Date:08/06/2012 11:27:30>
                                      --<ASV Control: 299 14/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
                                      pi_integration_other_system => v_cf_credit_unit.integration_other_system,
                                      pi_unique_transaction_id    => 0                                 ,--MEJORAR ESTO asignar el calor q le correspondoe
                                      --<ASV Control: 299 14/01/2013 11:00:00>
                                      pi_start_tran_id            => pi_tran_id                        ,
                                      pi_start_tran_date          => pi_tran_date                      ,--pi_start_tran_date,
                                      pi_asynchronous_status      => pi_asynchronous_status            ,
                                      pi_asynchronous_answer      => NULL                              ,
                                      pi_schedule_tran_id         => pi_tran_id                        ,-- => pi_schedule_tran_id
                                      pi_response_id              => NULL                              ,
                                      po_entity_log_id            => v_entity_log_id                   ,
                                      po_error_code               => po_error_code                     ,
                                      po_error_msg                => po_error_msg                      );

        IF NVL(po_error_code,'NOK') <> 'OK' THEN
          RAISE ERR_APP;
        END IF;
        
        --Preguntamos si la CRU debe ser Almacenada en la TR_ENTITY_SPEND_MASTER
        --<ASV Control: 299 15/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
        IF v_cf_credit_unit.integration_other_system = c_false  THEN
          
          --sacamos el valor de jurisdiccion
          CRU.BL_UTILITIES.GET_EVAL_USG_JURISDICTION( pi_telco_code             => pi_telco_code            ,
                                                      pi_credit_unit_code       => pi_credit_unit_code      ,
                                                      pi_date                   => pi_tran_date             ,
                                                      pi_tran_id                => pi_tran_id               ,
                                                      po_jurisdiction_type_code => v_jurisdiction_type_code ,
                                                      po_error_code             => po_error_code            ,
                                                      po_error_msg              => po_error_msg             );
          IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
          END IF;                     
          
          IF v_cf_credit_unit.is_currency = c_true THEN
            v_usg_duration:= 0;
            v_usg_amount  := v_tr_entity.quantity;
            v_balance     := v_tr_entity.quantity;
          ELSE
            v_usg_duration:= v_tr_entity.quantity;
            v_usg_amount  := 0;
            v_balance     := v_tr_entity.quantity;
          END IF;    
          --INSERTAMOS EN LA TR_ENTITY_SPEND_MASTER
          CRU.TX_TR_ENTITY_SPEND_MASTER.CREATE_( pi_entity_log_id          => v_entity_log_id             ,
                                                 pi_telco_code             => pi_telco_code               ,
                                                 pi_entity_type_code       => pi_entity_type_code         ,
                                                 pi_entity_id              => pi_entity_id                ,
                                                 pi_credit_unit_code       => v_tr_entity.credit_unit_code,
                                                 pi_credit_unit_id         => v_tr_entity.credit_unit_id  ,
                                                 pi_cru_rate_id            => v_tr_entity.cru_rate_id     ,
                                                 pi_cru_range_id           => v_tr_entity.cru_range_id    ,
                                                 pi_jurisdiction_code      => v_jurisdiction_type_code    ,
                                                 pi_client_id              => pi_client_id                ,
                                                 pi_client_type_code       => pi_client_type_code         ,
                                                 pi_client_segment_code    => pi_client_segment_code      ,
                                                 pi_community_id           => pi_community_id             ,
                                                 pi_community_area_code    => pi_community_area_code      ,
                                                 pi_ce_id                  => v_tr_entity.ce_id           ,
                                                 pi_ce_type_code           => pi_ce_type_code             ,
                                                 pi_ce_area_code           => pi_ce_area_code             ,
                                                 pi_plan_category_code     => pi_plan_category_code       ,
                                                 pi_plan_code              => pi_plan_code                ,
                                                 pi_component_code         => pi_component_code           ,
                                                 pi_entity_component_id    => pi_entity_component_id      ,
                                                 pi_add_data1              => pi_add_data1                ,
                                                 pi_add_data2              => pi_add_data2                ,
                                                 pi_add_data3              => pi_add_data3                ,
                                                 pi_add_data4              => pi_add_data4                ,
                                                 pi_add_data5              => pi_add_data5                ,
                                                 pi_usg_duration           => v_usg_duration              ,
                                                 pi_usg_amount             => v_usg_amount                ,
                                                 pi_balance                => v_balance                   ,
                                                 pi_cycle_generation_id    => pi_cycle_id                 ,
                                                 pi_cycle_id               => pi_cycle_id                 ,
                                                 pi_expiration_date        => v_expiration_date           ,
                                                 pi_start_tran_id          => pi_tran_id                  ,
                                                 pi_start_tran_date        => pi_tran_date                ,
                                                 po_entity_spend_master_id => v_entity_spend_master_id    ,
                                                 po_error_code             => po_error_code               ,
                                                 po_error_msg              => po_error_msg                );
          IF NVL(po_error_code,'NOK') <> 'OK' THEN
            RAISE ERR_APP;
          END IF;                                       
        END IF;  
        --<ASV Control: 299 15/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
        
        
      END IF;
    END IF;
    
  EXCEPTION
      WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in := ------------------------------------ variable parameters ---------------------------------
                    'pi_telco_code:'            || pi_telco_code                                          ||
                    '|pi_entity_type_code:'     || pi_entity_type_code                                    ||
                    '|pi_entity_id:'            || pi_entity_id                                           ||
                    '|pi_client_type_code:'     || pi_client_type_code                                    ||
                    '|pi_client_segment_code:'  || pi_client_segment_code                                 ||
                    '|pi_community_area_code:'  || pi_community_area_code                                 ||
                    '|pi_ce_type_code:'         || pi_ce_type_code                                        ||
                    '|pi_ce_area_code:'         || pi_ce_area_code                                        ||
                    '|pi_entity_ageing:'        || pi_entity_ageing                                       ||
                    '|pi_plan_category_code:'   || pi_plan_category_code                                  ||
                    '|pi_plan_category_id:'     || pi_plan_category_id                                    ||
                    '|pi_plan_code:'            || pi_plan_code                                           ||
                    '|pi_entity_plan_id:'       || pi_entity_plan_id                                      ||
                    '|pi_component_code:'       || pi_component_code                                      ||
                    '|pi_add_data1:'            || pi_add_data1                                           ||
                    '|pi_add_data2:'            || pi_add_data2                                           ||
                    '|pi_add_data3:'            || pi_add_data3                                           ||
                    '|pi_add_data4:'            || pi_add_data4                                           ||
                    '|pi_add_data5:'            || pi_add_data5                                           ||
                    '|pi_component_amount:'     || pi_component_amount                                    ||
                    '|pi_start_date:'           || TO_CHAR(pi_start_date,'DD/MM/YYYY HH24:MI:SS')         ||
                    '|pi_end_date:'             || TO_CHAR(pi_end_date,'DD/MM/YYYY HH24:MI:SS')           ||
                    '|pi_cycle_id:'             || pi_cycle_id                                            ||
                    '|pi_cycle_start_date:'     || TO_CHAR(pi_cycle_start_date,'DD/MM/YYYY HH24:MI:SS')   ||
                    '|pi_cycle_end_date:'       || TO_CHAR(pi_cycle_end_date,'DD/MM/YYYY HH24:MI:SS')     ||
                    '|pi_credit_unit_code:'     || pi_credit_unit_code                                    ||
                    '|pi_billing_start_date:'   || TO_CHAR(pi_billing_start_date,'DD/MM/YYYY HH24:MI:SS') ||
                    '|pi_billing_end_date:'     || TO_CHAR(pi_billing_end_date,'DD/MM/YYYY HH24:MI:SS')   ||
                    '|pi_billing_type_code:'    || pi_billing_type_code                                   ||
                    '|pi_billing_class_code:'   || pi_billing_class_code                                  ||
                    '|pi_billing_tran_id:'      || pi_billing_tran_id                                     ||
                    '|pi_tran_id:'              || pi_tran_id                                             ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code     ,
                                      pi_tran_id      => pi_billing_tran_id,
                                      pi_error_code   => po_error_code     ,
                                      pi_error_msg    => po_error_msg      ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));
    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code := 'CRU-0011';--Critical error.||Error critico.
      v_param_in    := ------------------------------------ variable parameters ---------------------------------
                    'pi_telco_code:'            || pi_telco_code                                          ||
                    '|pi_entity_type_code:'     || pi_entity_type_code                                    ||
                    '|pi_entity_id:'            || pi_entity_id                                           ||
                    '|pi_client_type_code:'     || pi_client_type_code                                    ||
                    '|pi_client_segment_code:'  || pi_client_segment_code                                 ||
                    '|pi_community_area_code:'  || pi_community_area_code                                 ||
                    '|pi_ce_type_code:'         || pi_ce_type_code                                        ||
                    '|pi_ce_area_code:'         || pi_ce_area_code                                        ||
                    '|pi_entity_ageing:'        || pi_entity_ageing                                       ||
                    '|pi_plan_category_code:'   || pi_plan_category_code                                  ||
                    '|pi_plan_category_id:'     || pi_plan_category_id                                    ||
                    '|pi_plan_code:'            || pi_plan_code                                           ||
                    '|pi_entity_plan_id:'       || pi_entity_plan_id                                      ||
                    '|pi_component_code:'       || pi_component_code                                      ||
                    '|pi_add_data1:'            || pi_add_data1                                           ||
                    '|pi_add_data2:'            || pi_add_data2                                           ||
                    '|pi_add_data3:'            || pi_add_data3                                           ||
                    '|pi_add_data4:'            || pi_add_data4                                           ||
                    '|pi_add_data5:'            || pi_add_data5                                           ||
                    '|pi_component_amount:'     || pi_component_amount                                    ||
                    '|pi_start_date:'           || TO_CHAR(pi_start_date,'DD/MM/YYYY HH24:MI:SS')         ||
                    '|pi_end_date:'             || TO_CHAR(pi_end_date,'DD/MM/YYYY HH24:MI:SS')           ||
                    '|pi_cycle_id:'             || pi_cycle_id                                            ||
                    '|pi_cycle_start_date:'     || TO_CHAR(pi_cycle_start_date,'DD/MM/YYYY HH24:MI:SS')   ||
                    '|pi_cycle_end_date:'       || TO_CHAR(pi_cycle_end_date,'DD/MM/YYYY HH24:MI:SS')     ||
                    '|pi_credit_unit_code:'     || pi_credit_unit_code                                    ||
                    '|pi_billing_start_date:'   || TO_CHAR(pi_billing_start_date,'DD/MM/YYYY HH24:MI:SS') ||
                    '|pi_billing_end_date:'     || TO_CHAR(pi_billing_end_date,'DD/MM/YYYY HH24:MI:SS')   ||
                    '|pi_billing_type_code:'    || pi_billing_type_code                                   ||
                    '|pi_billing_class_code:'   || pi_billing_class_code                                  ||
                    '|pi_billing_tran_id:'      || pi_billing_tran_id                                     ||
                    '|pi_tran_id:'              || pi_tran_id                                             ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code     ,
                                      pi_tran_id      => pi_billing_tran_id,
                                      pi_error_code   => po_error_code     ,
                                      pi_error_msg    => po_error_msg      ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));


  END;

  /*
  Process PROCESS CREDIT_UNIT_PROCESS ESB receiving all parameters values
  %Date          08/11/2010 10:24:07
  %Control       60083
  %Author        "Abel Soto"
  %Version       1.0.0
      %param         pi_telco_code                         Telco Code
      %param         pi_entity_type_code                   Entity type code
      %param         pi_entity_id                          Entity identifier
      %param         pi_entity_component_id                Entity component identifier
      %param         pi_client_id                          Client identifier
      %param         pi_community_id                       Community identifier
      %param         pi_cen_id                             Consumption entity identifier
      %param         pi_client_type_code                   Client type code
      %param         pi_client_segment_code                Client segment code
      %param         pi_community_area_code                Community area code
      %param         pi_ce_type_code                       Consumption entity type code
      %param         pi_ce_area_code                       Consumption entity area code
      %param         pi_entity_ageing                      Entity ageing
      %param         pi_plan_category_code                 Plan category code
      %param         pi_plan_category_id                   Plan category identifier
      %param         pi_plan_code                          Plan code
      %param         pi_entity_plan_id                     Entity plan identifier
      %param         pi_component_code                     Component code
      %param         pi_add_data1                          Additional data1
      %param         pi_add_data2                          Additional data2
      %param         pi_add_data3                          Additional data3
      %param         pi_add_data4                          Additional data4
      %param         pi_add_data5                          Additional data5
      %param         pi_activated_date                     Activated date
      %param         pi_credit_unit_code                   Credit unit code
      %param         pi_tran_id                            Transaction identifier
      %param         pi_tran_date                          Transaction date
      %param         po_error_code                         Output showing one of the next results:
                                                           {*} OK - If procedure executed satisfactorily
                                                           {*} XXX-#### - Error code if any error found
      %param         po_error_msg                          Output showing the error message if any error found
      %raises        ERR_APP                               Application level error
      <hr>
        {*}Date       25/04/2012 17:02:00
        {*}Control    299
        {*}Author     "Abel Soto Vera"
        {*}Note       Modify procedure for included parameter type XMLtype for overwrite data of the billing elements.
      <hr>
        {*}Date       05/09/2012 11:30:00
        {*}Control    299
        {*}Author     "Abel Soto Vera"
        {*}Note       They change the state that sends the query through CRUs, to improve the process, with The realization of CRUs dosed in other systems
      <hr>
        {*}Date       26/09/2013 11:00:00
        {*}Control    160121 
        {*}Author     "Abel Soto Vera"
        {*}Note       Billing - Multi operator custom (Change Management)
  */

  PROCEDURE CREDIT_UNIT_PROCESS_ESB( pi_telco_code          IN  CRU.TR_ENTITY_LOG.telco_code%TYPE             ,
                                     pi_entity_type_code    IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE       ,
                                     pi_entity_id           IN  CRU.TR_ENTITY_LOG.entity_id%TYPE              ,
                                     pi_entity_component_id IN  CRU.TR_ENTITY_LOG.entity_component_id%TYPE    ,
                                     pi_client_id           IN  CRU.TR_ENTITY_LOG.client_id%TYPE              ,
                                     pi_community_id        IN  CRU.TR_ENTITY_LOG.community_id%TYPE           ,
                                     pi_cen_id              IN  CRU.TR_ENTITY_LOG.ce_id%TYPE                  ,
                                         -- Tariff Keys
                                     pi_client_type_code    IN  CRU.TR_ENTITY_LOG.client_type_code%TYPE       ,
                                     pi_client_segment_code IN  CRU.TR_ENTITY_LOG.client_segment_code%TYPE    ,
                                     pi_community_area_code IN  CRU.TR_ENTITY_LOG.community_area_code%TYPE    ,
                                     pi_ce_type_code        IN  CRU.TR_ENTITY_LOG.ce_type_code%TYPE           ,
                                     pi_ce_area_code        IN  CRU.TR_ENTITY_LOG.ce_area_code%TYPE           ,
                                     pi_entity_ageing       IN  CRU.TR_ENTITY_LOG.entity_ageing%TYPE          ,
                                     pi_plan_category_code  IN  CRU.TR_ENTITY_LOG.plan_category_code%TYPE     ,
                                     pi_plan_category_id    IN  CRU.TR_ENTITY_LOG.plan_category_id%TYPE       ,  --value_id of plan_category_code
                                     pi_plan_code           IN  CRU.TR_ENTITY_LOG.plan_code%TYPE              ,
                                     pi_entity_plan_id      IN  CRU.TR_ENTITY_LOG.entity_plan_id%TYPE         ,   --value_id of plan_code
                                     pi_component_code      IN  CRU.TR_ENTITY_LOG.component_code%TYPE         ,
                                     pi_add_data1           IN  CRU.TR_ENTITY_LOG.add_data1%TYPE              ,
                                     pi_add_data2           IN  CRU.TR_ENTITY_LOG.add_data2%TYPE              ,
                                     pi_add_data3           IN  CRU.TR_ENTITY_LOG.add_data3%TYPE              ,
                                     pi_add_data4           IN  CRU.TR_ENTITY_LOG.add_data4%TYPE              ,
                                     pi_add_data5           IN  CRU.TR_ENTITY_LOG.add_data5%TYPE              ,
                                     pi_activated_date      IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE       ,
                                     pi_credit_unit_code    IN  CRU.CF_CREDIT_UNIT.CREDIT_UNIT_CODE%TYPE      ,
                                     --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                     pi_component_amount    IN  CRU.TR_ENTITY_CREDIT_UNIT.component_amount%TYPE,
                                     --<ASV Control: 299 25/04/2012 17:02:00>
                                     pi_tran_id             IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE          ,
                                     pi_tran_date           IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE        ,
                                     po_error_code          OUT VARCHAR2                                       ,
                                     po_error_msg           OUT VARCHAR2                                       ) IS

  --constan
    c_billing_estimated  CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'BILLING_ESTIMATED',SYSDATE)  ;
    c_billing_demand     CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code, c_application_code, 'BILLING_DEMAND',SYSDATE)  ;

   -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.CREDIT_UNIT_PROCESS_ESB';
    v_param_in          VARCHAR2(4000)                                           ;
    v_data_community_cycle CUS.COMMUNITY_CYCLE%ROWTYPE;
    v_data_interval     BIL.CF_CYCLE_INTERVAL%ROWTYPE;
--    v_cycle_id NUMBER;
--    v_cycle_start_date DATE;
--    v_cycle_end_date   DATE;
  ERR_APP EXCEPTION;

  BEGIN
    po_error_code := 'OK';
    po_error_msg  := ''  ;
    
    IF c_billing_estimated IS NULL OR
       c_billing_demand    IS NULL THEN
       po_error_code := 'CRU-0000';--The Constant value is null||El valor de la constante es null
       po_error_msg  := 'c_billing_estimated: ' || c_billing_estimated ||
                        '|c_billing_demand: '   || c_billing_demand     ;
      RAISE ERR_APP;
    END IF;
        
    IF pi_telco_code          IS NULL OR
      pi_entity_type_code     IS NULL OR
      pi_entity_id            IS NULL OR
      pi_entity_component_id  IS NULL OR
      pi_client_id            IS NULL OR
      pi_community_id         IS NULL OR
      pi_cen_id               IS NULL OR
      pi_client_type_code     IS NULL OR
      pi_client_segment_code  IS NULL OR
      pi_community_area_code  IS NULL OR
      pi_ce_type_code         IS NULL OR
      pi_ce_area_code         IS NULL OR
      pi_entity_ageing        IS NULL OR
      pi_plan_category_code   IS NULL OR
      pi_plan_category_id     IS NULL OR
      pi_plan_code            IS NULL OR
      pi_entity_plan_id       IS NULL OR
      pi_component_code       IS NULL OR
      pi_add_data1            IS NULL OR
      pi_add_data2            IS NULL OR
      pi_add_data3            IS NULL OR
      pi_add_data4            IS NULL OR
      pi_add_data5            IS NULL OR 
      pi_activated_date       IS NULL OR
      pi_credit_unit_code     IS NULL THEN
      po_error_code := 'CRU-0000';--Mandatory parameter is null||Parametro obligatorio es null
      RAISE ERR_APP;
    END IF;  
    IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN('TELCO_GENERIC', 'TELCO_OPERATIONS_CODE', pi_telco_code, pi_activated_date) IS NULL THEN
      po_error_code:= 'CRU-0000'; --Domain telco code operation value is null||Valor de dominio telco code operation es nulo
      po_error_msg:= 'pi_telco_code: ' || pi_telco_code ;
      RAISE ERR_APP;
    END IF; 
    
    CUS.TX_PUBLIC_CRU.GET_DATA_COMMUNITY_CYCLE( pi_telco_code           => pi_telco_code         ,
                                                pi_community_id         => pi_community_id       ,
                                                pi_date                 => pi_activated_date     ,
                                                pi_tran_id              => pi_tran_id            ,
                                                po_data_community_cycle => v_data_community_cycle,
                                                po_error_code           => po_error_code         ,
                                                po_error_msg            => po_error_msg          );

    IF NVL(po_error_code,'NOK') <> 'OK' THEN
      RAISE ERR_APP;
    END IF;

    BIL.TX_PUBLIC_CRU.GET_DATA_INTERVAL( pi_telco_code       => pi_telco_code                    ,
                                         pi_cycle_code       => v_data_community_cycle.cycle_code,
                                         pi_date             => pi_activated_date                ,
                                         pi_tran_id          => pi_tran_id                       ,
                                         po_data_interval    => v_data_interval                  ,
                                         po_error_code       => po_error_code                    ,
                                         po_error_msg        => po_error_msg                     );

    IF NVL(po_error_code,'NOK') <> 'OK' THEN
      RAISE ERR_APP;
    END IF;

    CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_GENERIC(  pi_telco_code               => pi_telco_code                   ,
                                                 pi_entity_type_code         => pi_entity_type_code             ,
                                                 pi_entity_id                => pi_entity_id                    ,
                                                 pi_entity_type_code_process => pi_entity_type_code             ,
                                                 pi_entity_id_process        => pi_entity_id                    ,
                                                 pi_entity_component_id      => pi_entity_component_id          ,
                                                 pi_client_id                => pi_client_id                    ,
                                                 pi_community_id             => pi_community_id                 ,
                                                 pi_cen_id                   => pi_cen_id                       ,
                                                 -- Tariff Keys          
                                                 pi_client_type_code         => pi_client_type_code             ,
                                                 pi_client_segment_code      => pi_client_segment_code          ,
                                                 pi_community_area_code      => pi_community_area_code          ,
                                                 pi_ce_type_code             => pi_ce_type_code                 ,
                                                 pi_ce_area_code             => pi_ce_area_code                 ,
                                                 pi_entity_ageing            => pi_entity_ageing                ,
                                                 pi_plan_category_code       => pi_plan_category_code           ,
                                                 pi_plan_category_id         => pi_plan_category_id             ,  --value_id of plan_category_code
                                                 pi_plan_code                => pi_plan_code                    ,
                                                 pi_entity_plan_id           => pi_entity_plan_id               ,   --value_id of plan_code
                                                 pi_component_code           => pi_component_code               ,
                                                 pi_add_data1                => pi_add_data1                    ,
                                                 pi_add_data2                => pi_add_data2                    ,
                                                 pi_add_data3                => pi_add_data3                    ,
                                                 pi_add_data4                => pi_add_data4                    ,
                                                 pi_add_data5                => pi_add_data5                    ,
                                                 --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                                 pi_component_amount         => pi_component_amount             ,
                                                 --<ASV Control: 299 25/04/2012 17:02:00>
                                                 pi_start_date               => pi_activated_date               ,
                                                 pi_end_date                 => v_data_interval.cycle_end_date  ,
                                                 ---data cycle
                                                 pi_cycle_id                 => v_data_interval.cycle_id        ,
                                                 pi_cycle_start_date         => v_data_interval.cycle_start_date,
                                                 pi_cycle_end_date           => v_data_interval.cycle_end_date  ,
                                                 pi_credit_unit_code         => pi_credit_unit_code             ,
                                                 pi_billing_start_date       => pi_activated_date               ,
                                                 pi_billing_end_date         => v_data_interval.cycle_end_date  ,--BILLING_END_DATE?  ,--
                                                 pi_billing_type_code        => c_billing_estimated             ,
                                                 pi_billing_class_code       => c_billing_demand                ,
                                                 --<ASV Control:299 Date:08/06/2012 11:27:30 Addition field billing_tran_id so you can make the sending of notification to ESB always at the level Consumption Entity>
                                                 pi_billing_tran_id          => pi_tran_id                      ,
                                                 pi_tran_id                  => pi_tran_id                      ,
                                                 --<ASV Control:299 Date:08/06/2012 11:27:30>
                                                 pi_tran_date                => pi_tran_date                    ,
                                                 --<ASV Control:299 05/09/2012 11:30:00 They change the state that sends the query through CRUs, to improve the process>
                                                 pi_asynchronous_status      => c_delivered                     ,--c_completed,
                                                 --<ASV Control:299 05/09/2012 11:30:00>
                                                 po_error_code               => po_error_code                   ,
                                                 po_error_msg                => po_error_msg                    );

    IF NVL(po_error_code,'NOK') <> 'OK' THEN
      RAISE ERR_APP;
    END IF;

  EXCEPTION
    WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in := ------------------------------------ variable parameters ---------------------------------
                   'pi_telco_code:'          || pi_telco_code                                        ||
                   '|pi_entity_type_code:'   || pi_entity_type_code                                  ||
                   '|pi_entity_id:'          || pi_entity_id                                         ||
                   '|pi_entity_component_id:'|| pi_entity_component_id                               ||
                   '|pi_client_id:'          || pi_client_id                                         ||
                   '|pi_community_id:'       || pi_community_id                                      ||
                   '|pi_cen_id:'             || pi_cen_id                                            ||
                   '|pi_client_type_code:'   || pi_client_type_code                                  ||
                   '|pi_client_segment_code:'|| pi_client_segment_code                               ||
                   '|pi_community_area_code:'|| pi_community_area_code                               ||
                   '|pi_ce_type_code:'       || pi_ce_type_code                                      ||
                   '|pi_ce_area_code:'       || pi_ce_area_code                                      ||
                   '|pi_entity_ageing:'      || pi_entity_ageing                                     ||
                   '|pi_plan_category_code:' || pi_plan_category_code                                ||
                   '|pi_plan_category_id:'   || pi_plan_category_id                                  ||
                   '|pi_plan_code:'          || pi_plan_code                                         ||
                   '|pi_entity_plan_id:'     || pi_entity_plan_id                                    ||
                   '|pi_component_code:'     || pi_component_code                                    ||
                   '|pi_add_data1:'          || pi_add_data1                                         ||
                   '|pi_add_data2:'          || pi_add_data2                                         ||
                   '|pi_add_data3:'          || pi_add_data3                                         ||
                   '|pi_add_data4:'          || pi_add_data4                                         ||
                   '|pi_add_data5:'          || pi_add_data5                                         ||
                   '|pi_component_amount:'   || pi_component_amount                                  ||
                   '|pi_activated_date:'     || TO_CHAR (pi_activated_date, 'DD/MM/YYYY HH24:MI:SS') ||
                   '|pi_credit_unit_code:'   || pi_credit_unit_code                                  ||
                   '|pi_component_amount:'   || pi_component_amount                                  ||
                   '|pi_tran_id:'            || pi_tran_id                                           ||
                   '|pi_tran_date:'          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')      ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id   ,
                                      pi_error_code   => po_error_code,
                                      pi_error_msg    => po_error_msg ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));

    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code := 'CRU-0012';--Critical error.||Error critico.
      v_param_in    := ------------------------------------ variable parameters ---------------------------------
                    'pi_telco_code:'          || pi_telco_code                                        ||
                    '|pi_entity_type_code:'   || pi_entity_type_code                                  ||
                    '|pi_entity_id:'          || pi_entity_id                                         ||
                    '|pi_entity_component_id:'|| pi_entity_component_id                               ||
                    '|pi_client_id:'          || pi_client_id                                         ||
                    '|pi_community_id:'       || pi_community_id                                      ||
                    '|pi_cen_id:'             || pi_cen_id                                            ||
                    '|pi_client_type_code:'   || pi_client_type_code                                  ||
                    '|pi_client_segment_code:'|| pi_client_segment_code                               ||
                    '|pi_community_area_code:'|| pi_community_area_code                               ||
                    '|pi_ce_type_code:'       || pi_ce_type_code                                      ||
                    '|pi_ce_area_code:'       || pi_ce_area_code                                      ||
                    '|pi_entity_ageing:'      || pi_entity_ageing                                     ||
                    '|pi_plan_category_code:' || pi_plan_category_code                                ||
                    '|pi_plan_category_id:'   || pi_plan_category_id                                  ||
                    '|pi_plan_code:'          || pi_plan_code                                         ||
                    '|pi_entity_plan_id:'     || pi_entity_plan_id                                    ||
                    '|pi_component_code:'     || pi_component_code                                    ||
                    '|pi_add_data1:'          || pi_add_data1                                         ||
                    '|pi_add_data2:'          || pi_add_data2                                         ||
                    '|pi_add_data3:'          || pi_add_data3                                         ||
                    '|pi_add_data4:'          || pi_add_data4                                         ||
                    '|pi_add_data5:'          || pi_add_data5                                         ||
                    '|pi_component_amount:'   || pi_component_amount                                  ||
                    '|pi_activated_date:'     || TO_CHAR (pi_activated_date, 'DD/MM/YYYY HH24:MI:SS') ||
                    '|pi_credit_unit_code:'   || pi_credit_unit_code                                  ||
                    '|pi_component_amount:'   || pi_component_amount                                  ||
                    '|pi_tran_id:'            || pi_tran_id                                           ||
                    '|pi_tran_date:'          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')      ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id   ,
                                      pi_error_code   => po_error_code,
                                      pi_error_msg    => po_error_msg ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));

  END;

   /*
  Process PROCESS CREDIT_UNIT_PROCESS_GENERIC receiving all parameters values
  %Date          08/11/2010 10:24:07
  %Control       60083
  %Author        "Abel Soto"
  %Version       1.0.0
      %param         pi_telco_code                        Telco Code
      %param         pi_entity_type_code                  Entity type code
      %param         pi_entity_id                         Entity identifier
      %param         pi_entity_component_id               Entity component identifier
      %param         pi_client_id                         Client identifier
      %param         pi_community_id                      Community identifier
      %param         pi_cen_id                            Consumption entity identifier
      %param         pi_client_type_code                  Client type code
      %param         pi_client_segment_code               Client segment code
      %param         pi_community_area_code               Community area code
      %param         pi_ce_type_code                      Consumption entity type code
      %param         pi_ce_area_code                      Consumption entity area code
      %param         pi_entity_ageing                     Entity ageing
      %param         pi_plan_category_code                Plan category code
      %param         pi_plan_category_id                  Plan category identifier
      %param         pi_plan_code                         Plan code
      %param         pi_entity_plan_id                    Entity plan identifier
      %param         pi_component_code                    Component code
      %param         pi_add_data1                         Additional data1
      %param         pi_add_data2                         Additional data2
      %param         pi_add_data3                         Additional data3
      %param         pi_add_data4                         Additional data4
      %param         pi_add_data5                         Additional data5
      %param         pi_activated_date                    Activated date
      %param         pi_tran_id                           Transaction identifier
      %param         pi_tran_date                         Transaction date
      %param         po_error_code Output showing one of the next results:
                       {*} OK - If procedure executed satisfactorily
                       {*} XXX-#### - Error code if any error found
      %param         po_error_msg Output showing the error message if any error found
      %raises        ERR_APP Application level error
      <hr>
        {*}Date       25/04/2012 17:02:00
        {*}Control    299
        {*}Author     "Abel Soto Vera"
        {*}Note       Modify procedure for included parameter type XMLtype for overwrite data of the billing elements.
      <hr>
        {*}Date       26/09/2013 11:00:00
        {*}Control    160121 
        {*}Author     "Abel Soto Vera"
        {*}Note       Billing - Multi operator custom (Change Management)
  */

  PROCEDURE PROCESS_GENERIC_FREE( pi_telco_code          IN  CRU.TR_ENTITY_LOG.telco_code%TYPE         ,
                                  pi_entity_type_code    IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE   ,
                                  pi_entity_id           IN  CRU.TR_ENTITY_LOG.entity_id%TYPE          ,
                                  pi_entity_component_id IN  CRU.TR_ENTITY_LOG.entity_component_id%TYPE,
                                  pi_client_id           IN  CRU.TR_ENTITY_LOG.client_id%TYPE          ,
                                  pi_community_id        IN  CRU.TR_ENTITY_LOG.community_id%TYPE       ,
                                  pi_cen_id              IN  CRU.TR_ENTITY_LOG.ce_id%TYPE              ,
                                      -- Tariff Keys
                                  pi_client_type_code    IN  CRU.TR_ENTITY_LOG.client_type_code%TYPE   ,
                                  pi_client_segment_code IN  CRU.TR_ENTITY_LOG.client_segment_code%TYPE,
                                  pi_community_area_code IN  CRU.TR_ENTITY_LOG.community_area_code%TYPE,
                                  pi_ce_type_code        IN  CRU.TR_ENTITY_LOG.ce_type_code%TYPE       ,
                                  pi_ce_area_code        IN  CRU.TR_ENTITY_LOG.ce_area_code%TYPE       ,
                                  pi_entity_ageing       IN  CRU.TR_ENTITY_LOG.entity_ageing%TYPE      ,
                                  pi_plan_category_code  IN  CRU.TR_ENTITY_LOG.plan_category_code%TYPE ,
                                  pi_plan_category_id    IN  CRU.TR_ENTITY_LOG.plan_category_id%TYPE   ,  --value_id of plan_category_code
                                  pi_plan_code           IN  CRU.TR_ENTITY_LOG.plan_code%TYPE          ,
                                  pi_entity_plan_id      IN  CRU.TR_ENTITY_LOG.entity_plan_id%TYPE     ,   --value_id of plan_code
                                  pi_component_code      IN  CRU.TR_ENTITY_LOG.component_code%TYPE     ,
                                  pi_add_data1           IN  CRU.TR_ENTITY_LOG.add_data1%TYPE          ,
                                  pi_add_data2           IN  CRU.TR_ENTITY_LOG.add_data2%TYPE          ,
                                  pi_add_data3           IN  CRU.TR_ENTITY_LOG.add_data3%TYPE          ,
                                  pi_add_data4           IN  CRU.TR_ENTITY_LOG.add_data4%TYPE          ,
                                  pi_add_data5           IN  CRU.TR_ENTITY_LOG.add_data5%TYPE          ,
                                  pi_activated_date      IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE   ,
                                  pi_tran_id             IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE     ,
                                  pi_tran_date           IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE   ,
                                  po_error_code          OUT VARCHAR2                                  ,
                                  po_error_msg           OUT VARCHAR2                                  ) IS

    -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.PROCESS_GENERIC_FREE';
    v_param_in          VARCHAR2(4000)                                       ;
    --Para listar todos los CRUs GENERIC and FREE
    CURSOR tcur_credit_unit_free( v_date_cru_generic DATE, v_telco_code CRU.TR_ENTITY_LOG.telco_code%TYPE) IS
      SELECT *
        FROM CRU.CF_CREDIT_UNIT
       WHERE telco_code            = v_telco_code 
         AND credit_unit_type_code = c_cru_generic
         AND behavior_type_code    = c_behavior_free
         AND status               <> c_inactive
         AND v_date_cru_generic BETWEEN start_date AND end_date;

    ERR_APP EXCEPTION;
  BEGIN
    po_error_code :='OK';
    po_error_msg  :='';
    
    IF pi_telco_code         IS NULL OR
      pi_entity_type_code    IS NULL OR 
      pi_entity_id           IS NULL OR
      pi_entity_component_id IS NULL OR
      pi_client_id           IS NULL OR
      pi_community_id        IS NULL OR
      pi_cen_id              IS NULL OR
      pi_client_type_code    IS NULL OR
      pi_client_segment_code IS NULL OR
      pi_community_area_code IS NULL OR
      pi_ce_type_code        IS NULL OR
      pi_ce_area_code        IS NULL OR
      pi_entity_ageing       IS NULL OR
      pi_plan_category_code  IS NULL OR
      pi_plan_category_id    IS NULL OR
      pi_plan_code           IS NULL OR
      pi_entity_plan_id      IS NULL OR
      pi_component_code      IS NULL OR
      pi_add_data1           IS NULL OR
      pi_add_data2           IS NULL OR
      pi_add_data3           IS NULL OR
      pi_add_data4           IS NULL OR
      pi_add_data5           IS NULL OR
      pi_activated_date      IS NULL OR
      pi_tran_id             IS NULL OR
      pi_tran_date           IS NULL THEN
      po_error_code := 'CRU-0000';--Mandatory parameter is null||Parametro obligatorio es null
      RAISE ERR_APP;      
    END IF;  
    
    FOR v_rec_cru_generic IN tcur_credit_unit_free(pi_activated_date, pi_telco_code)   LOOP
      CRU.BL_PROCESS.CREDIT_UNIT_PROCESS_ESB( pi_telco_code          => pi_telco_code         ,
                                              pi_entity_type_code    => pi_entity_type_code   ,
                                              pi_entity_id           => pi_entity_id          ,
                                              pi_entity_component_id => pi_entity_component_id,
                                              pi_client_id           => pi_client_id          ,
                                              pi_community_id        => pi_community_id       ,
                                              pi_cen_id              => pi_cen_id             ,
                                              pi_client_type_code    => pi_client_type_code   ,
                                              pi_client_segment_code => pi_client_segment_code,
                                              pi_community_area_code => pi_community_area_code,
                                              pi_ce_type_code        => pi_ce_type_code       ,
                                              pi_ce_area_code        => pi_ce_area_code       ,
                                              pi_entity_ageing       => pi_entity_ageing      ,
                                              pi_plan_category_code  => pi_plan_category_code ,
                                              pi_plan_category_id    => pi_plan_category_id   ,
                                              pi_plan_code           => pi_plan_code          ,
                                              pi_entity_plan_id      => pi_entity_plan_id     ,
                                              pi_component_code      => pi_component_code     ,
                                              pi_add_data1           => pi_add_data1          ,
                                              pi_add_data2           => pi_add_data2          ,
                                              pi_add_data3           => pi_add_data3          ,
                                              pi_add_data4           => pi_add_data4          ,
                                              pi_add_data5           => pi_add_data5          ,
                                              pi_activated_date      => pi_activated_date     ,
                                              pi_credit_unit_code    => v_rec_cru_generic.credit_unit_code,
                                              --<ASV Control: 299 25/04/2012 17:02:00 Modify for overwrite data of the billing elements>
                                              pi_component_amount    => NULL                  ,
                                              --<ASV Control: 299 25/04/2012 17:02:00>
                                              pi_tran_id             => pi_tran_id            ,
                                              pi_tran_date           => pi_tran_date          ,
                                              po_error_code          => po_error_code         ,
                                              po_error_msg           => po_error_msg          );

      IF NVL(po_error_code, 'NOK')!='OK' THEN
        RAISE ERR_APP;
      END IF;

    END LOOP;

  EXCEPTION
    WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in := ------------------------------------ variable parameters ---------------------------------
                    'pi_telco_code:'          || pi_telco_code                                        ||
                    '|pi_entity_type_code:'   || pi_entity_type_code                                  ||
                    '|pi_entity_id:'          || pi_entity_id                                         ||
                    '|pi_entity_component_id:'|| pi_entity_component_id                               ||
                    '|pi_client_id:'          || pi_client_id                                         ||
                    '|pi_community_id:'       || pi_community_id                                      ||
                    '|pi_cen_id:'             || pi_cen_id                                            ||
                    '|pi_client_type_code:'   || pi_client_type_code                                  ||
                    '|pi_client_segment_code:'|| pi_client_segment_code                               ||
                    '|pi_community_area_code:'|| pi_community_area_code                               ||
                    '|pi_ce_type_code:'       || pi_ce_type_code                                      ||
                    '|pi_ce_area_code:'       || pi_ce_area_code                                      ||
                    '|pi_entity_ageing:'      || pi_entity_ageing                                     ||
                    '|pi_plan_category_code:' || pi_plan_category_code                                ||
                    '|pi_plan_category_id:'   || pi_plan_category_id                                  ||
                    '|pi_plan_code:'          || pi_plan_code                                         ||
                    '|pi_entity_plan_id:'     || pi_entity_plan_id                                    ||
                    '|pi_component_code:'     || pi_component_code                                    ||
                    '|pi_add_data1:'          || pi_add_data1                                         ||
                    '|pi_add_data2:'          || pi_add_data2                                         ||
                    '|pi_add_data3:'          || pi_add_data3                                         ||
                    '|pi_add_data4:'          || pi_add_data4                                         ||
                    '|pi_add_data5:'          || pi_add_data5                                         ||
                    '|pi_activated_date:'     || TO_CHAR (pi_activated_date, 'DD/MM/YYYY HH24:MI:SS') ||
                    '|pi_tran_id:'            || pi_tran_id                                           ||
                    '|pi_tran_date:'          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')      ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id   ,
                                      pi_error_code   => po_error_code,
                                      pi_error_msg    => po_error_msg ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));

    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code := 'CRU-0013';--Critical error.||Error critico.
      v_param_in    := ------------------------------------ variable parameters ---------------------------------
                    'pi_telco_code:'          || pi_telco_code                                        ||
                    '|pi_entity_type_code:'   || pi_entity_type_code                                  ||
                    '|pi_entity_id:'          || pi_entity_id                                         ||
                    '|pi_entity_component_id:'|| pi_entity_component_id                               ||
                    '|pi_client_id:'          || pi_client_id                                         ||
                    '|pi_community_id:'       || pi_community_id                                      ||
                    '|pi_cen_id:'             || pi_cen_id                                            ||
                    '|pi_client_type_code:'   || pi_client_type_code                                  ||
                    '|pi_client_segment_code:'|| pi_client_segment_code                               ||
                    '|pi_community_area_code:'|| pi_community_area_code                               ||
                    '|pi_ce_type_code:'       || pi_ce_type_code                                      ||
                    '|pi_ce_area_code:'       || pi_ce_area_code                                      ||
                    '|pi_entity_ageing:'      || pi_entity_ageing                                     ||
                    '|pi_plan_category_code:' || pi_plan_category_code                                ||
                    '|pi_plan_category_id:'   || pi_plan_category_id                                  ||
                    '|pi_plan_code:'          || pi_plan_code                                         ||
                    '|pi_entity_plan_id:'     || pi_entity_plan_id                                    ||
                    '|pi_component_code:'     || pi_component_code                                    ||
                    '|pi_add_data1:'          || pi_add_data1                                         ||
                    '|pi_add_data2:'          || pi_add_data2                                         ||
                    '|pi_add_data3:'          || pi_add_data3                                         ||
                    '|pi_add_data4:'          || pi_add_data4                                         ||
                    '|pi_add_data5:'          || pi_add_data5                                         ||
                    '|pi_activated_date:'     || TO_CHAR (pi_activated_date, 'DD/MM/YYYY HH24:MI:SS') ||
                    '|pi_tran_id:'            || pi_tran_id                                           ||
                    '|pi_tran_date:'          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')      ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id   ,
                                      pi_error_code   => po_error_code,
                                      pi_error_msg    => po_error_msg ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));

  END;

END BL_PROCESS;
/

