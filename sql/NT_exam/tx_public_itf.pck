CREATE OR REPLACE PACKAGE CRU.TX_PUBLIC_ITF IS

   /******************************************************************************
   Implements procedures and functions necessary to process the
   %Company         Trilogy Software Bolivia
   %System          Omega Convergent Billing
   %Date            20/01/2010 10:25:48
   %Control         60079
   %Author          Rosio Teresa Eguivar Estrada
   %Version         1.1.0
   ******************************************************************************/

  FUNCTION GET_VERSION RETURN VARCHAR2;
  
  --Creates a record for table TR_ENTITY_CREDIT_UNIT receiving all columns as parameters
  PROCEDURE COMPONENT_ACTIVATION( pi_component_element_id       IN  CRU.TR_ENTITY_CREDIT_UNIT.component_element_id%TYPE ,
                                  pi_telco_code                 IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE           ,
                                  pi_entity_type_code           IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_type_code%TYPE     ,
                                  pi_entity_id                  IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_id%TYPE            ,
                                  pi_client_id                  IN  NUMBER                                              ,
                                  pi_community_id               IN  NUMBER                                              ,
                                  pi_cen_id                     IN  NUMBER                                              ,
                                  pi_bill_element_code          IN  CRU.TR_ENTITY_CREDIT_UNIT.credit_unit_code%TYPE     ,
                                  pi_bill_element_type_code     IN  VARCHAR2                                            ,
                                  pi_component_currency         IN  VARCHAR2                                            ,
                                  pi_component_amount           IN  NUMBER                                              ,
                                  pi_component_quantity         IN  NUMBER                                              ,
                                  pi_component_quotes           IN  NUMBER                                              ,
                                  pi_client_type_code           IN  VARCHAR2                                            ,
                                  pi_client_segment_code        IN  VARCHAR2                                            ,
                                  pi_community_area_code        IN  VARCHAR2                                            ,
                                  pi_ce_type_code               IN  VARCHAR2                                            ,
                                  pi_ce_area_code               IN  VARCHAR2                                            ,
                                  pi_plan_category_id           IN  NUMBER                                              ,
                                  pi_plan_category_code         IN  VARCHAR2                                            ,
                                  pi_entity_plan_id             IN  NUMBER                                              ,
                                  pi_plan_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.plan_code%TYPE            ,
                                  pi_entity_component_id        IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE  ,
                                  pi_component_code             IN  CRU.TR_ENTITY_CREDIT_UNIT.component_code%TYPE       ,
                                  pi_add_data1                  IN  VARCHAR2                                            ,
                                  pi_add_data2                  IN  VARCHAR2                                            ,
                                  pi_add_data3                  IN  VARCHAR2                                            ,
                                  pi_add_data4                  IN  VARCHAR2                                            ,
                                  pi_add_data5                  IN  VARCHAR2                                            ,
                                  pi_entity_ageing              IN  VARCHAR2                                            ,
                                  pi_billing_community_id       IN  NUMBER                                              ,
                                  pi_activated_date             IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_date%TYPE       ,
                                  pi_activated_tran_code        IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_tran_code%TYPE  ,
                                  pi_deactivated_date           IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_date%TYPE     ,
                                  pi_deactivated_tran_code      IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_tran_code%TYPE,
                                  pi_is_postpaid                IN  VARCHAR2                                            ,
                                  pi_tran_id                    IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_id%TYPE        ,
                                  pi_tran_date                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_date%TYPE      ,
                                  pi_user_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_user_code%TYPE      ,
                                  po_error_code                 OUT VARCHAR2                                            ,
                                  po_error_msg                  OUT VARCHAR2                                            );

  --Deactivation Instance of table TR_ENTITY_CREDIT_UNIT receiving all parameters values
  PROCEDURE COMPONENT_DEACTIVATION( pi_entity_component_id   IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE  ,
                                    pi_telco_code            IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE           ,
                                    pi_deactivated_date      IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_date%TYPE     ,
                                    pi_deactivated_tran_code IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_tran_code%TYPE,
                                    pi_is_postpaid           IN  VARCHAR2                                            ,
                                    pi_tran_id               IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_id%TYPE          ,
                                    pi_tran_date             IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_date%TYPE        ,
                                    pi_user_code             IN  CRU.TR_ENTITY_CREDIT_UNIT.end_user_code%TYPE        ,
                                    po_error_code            OUT VARCHAR2                                            ,
                                    po_error_msg             OUT VARCHAR2                                            );
  --Remove a record for table TR_ENTITY_CREDIT_UNIT receiving all columns as parameters
  PROCEDURE COMPONENT_REMOVE( pi_entity_component_id IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE,
                              pi_telco_code          IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE         ,
                              pi_tran_id             IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_id%TYPE	     ,
                              pi_tran_date           IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_date%TYPE      ,
                              pi_user_code           IN  CRU.TR_ENTITY_CREDIT_UNIT.end_user_code%TYPE      ,
                              po_error_code          OUT VARCHAR2                                          ,
                              po_error_msg           OUT VARCHAR2                                          );

  --CHANGE S status ASYNCHRONOUS for table TR_ENTITY_CREDIT_UNIT receiving all columns as parameters
  PROCEDURE CHANGE_ASYNCHRONOUS_BILLING( pi_tran_id_process     IN  CRU.TR_ENTITY_LOG.end_tran_id%TYPE        ,
                                         pi_telco_code          IN  CRU.TR_ENTITY_LOG.telco_code%TYPE         ,
                                         pi_asynchronous_status IN  CRU.TR_ENTITY_LOG.asynchronous_status%TYPE,
                                         pi_asynchronous_answer IN  CRU.TR_ENTITY_LOG_STATUS.asynchronous_answer%TYPE,
                                         pi_asynchronous_date   IN  CRU.TR_ENTITY_LOG_STATUS.asynchronous_date%TYPE  ,
                                         pi_response_id         IN  CRU.TR_ENTITY_LOG_STATUS.response_id%TYPE        ,
                                         pi_tran_id             IN  CRU.TR_ENTITY_LOG.end_tran_id%TYPE        ,
                                         po_error_code          OUT VARCHAR2                                  ,
                                         po_error_msg           OUT VARCHAR2                                  );

  --QUERY_GET_RATE_AMOUNT of table CF_RATE receiving all columns as parameters
  PROCEDURE QUERY_GET_RATE_AMOUNT( pi_entity_type_code    IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE   ,
                                   pi_telco_code          IN  CRU.TR_ENTITY_LOG.telco_code%TYPE         ,
                                   pi_entity_id           IN  CRU.TR_ENTITY_LOG.entity_id%TYPE          ,
                                   pi_client_type_code    IN  CRU.TR_ENTITY_LOG.client_type_code%TYPE   ,
                                   pi_client_segment_code IN  CRU.TR_ENTITY_LOG.client_segment_code%TYPE,
                                   pi_community_area_code IN  CRU.TR_ENTITY_LOG.community_area_code%TYPE,
                                   pi_ce_type_code        IN  CRU.TR_ENTITY_LOG.ce_type_code%TYPE       ,
                                   pi_ce_area_code        IN  CRU.TR_ENTITY_LOG.ce_area_code%TYPE       ,
                                   pi_entity_ageing       IN  CRU.TR_ENTITY_LOG.entity_ageing%TYPE      ,
                                   pi_plan_category_code  IN  CRU.TR_ENTITY_LOG.plan_category_code%TYPE ,
                                   pi_plan_code           IN  CRU.TR_ENTITY_LOG.plan_code%TYPE          ,
                                   pi_component_code      IN  CRU.TR_ENTITY_LOG.component_code%TYPE     ,
                                   pi_add_data1           IN  CRU.TR_ENTITY_LOG.add_data1%TYPE          ,
                                   pi_add_data2           IN  CRU.TR_ENTITY_LOG.add_data2%TYPE          ,
                                   pi_add_data3           IN  CRU.TR_ENTITY_LOG.add_data3%TYPE          ,
                                   pi_add_data4           IN  CRU.TR_ENTITY_LOG.add_data4%TYPE          ,
                                   pi_add_data5           IN  CRU.TR_ENTITY_LOG.add_data5%TYPE          ,
                                   pi_evaluate_date       IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE   ,
                                   pi_credit_unit_code    IN  CRU.CF_CREDIT_UNIT.CREDIT_UNIT_CODE%TYPE  ,
                                   pi_tran_id             IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE     ,
                                   pi_tran_date           IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE   ,
                                   po_rate_id             OUT CRU.CF_CRU_RATE.cru_rate_id%TYPE          ,
                                   po_rate_quantity       OUT CRU.TR_ENTITY_LOG.quantity%TYPE           ,
                                   po_error_code          OUT VARCHAR2                                  ,
                                   po_error_msg           OUT VARCHAR2                                  );


  --GET END DATE INSTANCE for TR_ENTITY_CREDIT_UNIT receiving all parameters values
  FUNCTION GET_END_DATE_INSTANCE( pi_telco_code       IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE     ,
                                  pi_entity_id        IN CRU.TR_ENTITY_CREDIT_UNIT.entity_id%TYPE       ,
                                  pi_entity_type_code IN CRU.TR_ENTITY_CREDIT_UNIT.entity_type_code%TYPE,
                                  pi_component_code   IN CRU.TR_ENTITY_CREDIT_UNIT.component_code%TYPE  ,
                                  pi_element_code     IN CRU.TR_ENTITY_CREDIT_UNIT.credit_unit_code%TYPE,
                                  pi_tran_id          IN CRU.TR_ENTITY_CREDIT_UNIT.start_tran_id%TYPE   ,
                                  pi_date             IN CRU.TR_ENTITY_CREDIT_UNIT.start_tran_date%TYPE )RETURN DATE ;



   --   Asign CRUs generic in the TR_ENTITY_LOG receiving all parameters
  PROCEDURE PROCESS_GENERIC_FREE( pi_component_element_id       IN  CRU.TR_ENTITY_CREDIT_UNIT.component_element_id%TYPE ,
                                  pi_telco_code                 IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE           ,
                                  pi_entity_type_code           IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_type_code%TYPE     ,
                                  pi_entity_id                  IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_id%TYPE            ,
                                  pi_client_id                  IN  NUMBER                                              ,
                                  pi_community_id               IN  NUMBER                                              ,
                                  pi_cen_id                     IN  NUMBER                                              ,
                                  pi_bill_element_code          IN  CRU.TR_ENTITY_CREDIT_UNIT.credit_unit_code%TYPE     ,
                                  pi_bill_element_type_code     IN  VARCHAR2                                            ,
                                  pi_component_currency         IN  VARCHAR2                                            ,
                                  pi_component_amount           IN  NUMBER                                              ,
                                  pi_component_quantity         IN  NUMBER                                              ,
                                  pi_component_quotes           IN  NUMBER                                              ,
                                  pi_client_type_code           IN  VARCHAR2                                            ,
                                  pi_client_segment_code        IN  VARCHAR2                                            ,
                                  pi_community_area_code        IN  VARCHAR2                                            ,
                                  pi_ce_type_code               IN  VARCHAR2                                            ,
                                  pi_ce_area_code               IN  VARCHAR2                                            ,
                                  pi_plan_category_id           IN  NUMBER                                              ,
                                  pi_plan_category_code         IN  VARCHAR2                                            ,
                                  pi_entity_plan_id             IN  NUMBER                                              ,
                                  pi_plan_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.plan_code%TYPE            ,
                                  pi_entity_component_id        IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE  ,
                                  pi_component_code             IN  CRU.TR_ENTITY_CREDIT_UNIT.component_code%TYPE       ,
                                  pi_add_data1                  IN  VARCHAR2                                            ,
                                  pi_add_data2                  IN  VARCHAR2                                            ,
                                  pi_add_data3                  IN  VARCHAR2                                            ,
                                  pi_add_data4                  IN  VARCHAR2                                            ,
                                  pi_add_data5                  IN  VARCHAR2                                            ,
                                  pi_entity_ageing              IN  VARCHAR2                                            ,
                                  pi_billing_community_id       IN  NUMBER                                              ,
                                  pi_activated_date             IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_date%TYPE       ,
                                  pi_activated_tran_code        IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_tran_code%TYPE  ,
                                  pi_deactivated_date           IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_date%TYPE     ,
                                  pi_deactivated_tran_code      IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_tran_code%TYPE,
                                  pi_is_postpaid                IN  VARCHAR2                                            ,
                                  pi_tran_id                    IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_id%TYPE        ,
                                  pi_tran_date                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_date%TYPE      ,
                                  pi_user_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_user_code%TYPE      ,
                                  po_error_code                 OUT VARCHAR2                                            ,
                                  po_error_msg                  OUT VARCHAR2                                            );

  --Change credit limit a record for table TR_ENTITY_CREDIT_UNIT receiving all columns as parameters
  PROCEDURE CHANGE_CREDIT_LIMIT( pi_entity_component_id IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE,
                                 pi_telco_code          IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE         ,
                                 --<ASV Control:299 Date:30/05/2012 11:27:30 Change in the logic of the process of credit limit>
                                 pi_credit_limit_code   IN  CRU.TR_ENTITY_CREDIT_UNIT.credit_unit_code%TYPE   ,
                                 --<ASV Control:299 Date:30/05/2012 11:27:30>                                 
                                 pi_credit_limit_amount IN  CRU.TR_ENTITY_CREDIT_UNIT.component_amount%TYPE   ,
                                 pi_date                IN  CRU.TR_ENTITY_CREDIT_UNIT.end_date%TYPE           ,
                                 pi_activated_tran_code IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_tran_code%TYPE,
                                 pi_tran_id             IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_id%TYPE      ,
                                 pi_tran_date           IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_date%TYPE    ,
                                 pi_user_code           IN  CRU.TR_ENTITY_CREDIT_UNIT.start_user_code%TYPE    ,
                                 po_error_code          OUT VARCHAR2                                          ,
                                 po_error_msg           OUT VARCHAR2                                          );


  --Gets the message configured for a credit unit
  PROCEDURE GET_CRU_MESSAGE ( pi_credit_unit_code  IN  CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE ,
                              pi_telco_code        IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE               ,
                              pi_language_code     IN  CRU.CF_CRU_MESSAGE.language_code%TYPE    ,
                              pi_entity_type_code  IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE  ,
                              pi_entity_id         IN  CRU.TR_ENTITY_LOG.entity_id%TYPE         ,
                              pi_message_type_code IN  CRU.CF_CRU_CONFIG_MESSAGE.message_type_code%TYPE, -- <REE 24/04/2013 19:00:00 CONTROL:335 Increases the logic for managing messages either by ranges.
                              pi_quantity          IN  cru.tr_entity_log.quantity%TYPE          ,
                              pi_date              IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE  ,
                              pi_tran_id           IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE    ,
                              po_message           OUT CRU.CF_CRU_MESSAGE.message%TYPE          ,
                              po_error_code        OUT VARCHAR2                                 ,
                              po_error_msg         OUT VARCHAR2                                );

  --TRUNCATE change status (I)a record for table TR_ENTITY_LOG receiving all columns as parameters
  PROCEDURE CHANGE_STATUS_CRU( pi_process_id    IN  CRU.TR_ENTITY_LOG.start_tran_id%TYPE,
                               pi_telco_code    IN  CRU.TR_ENTITY_LOG.telco_code%TYPE   ,
                               pi_tran_id       IN  CRU.TR_ENTITY_LOG.end_tran_id%TYPE  ,
                               pi_tran_date     IN  CRU.TR_ENTITY_LOG.end_tran_date%TYPE,
                               po_error_code    OUT VARCHAR2                            ,
                               po_error_msg     OUT VARCHAR2                            );

  FUNCTION GET_DESCRIPTION_ELEMENT( pi_telco_code    IN CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE   ,
                                    pi_element_code  IN CRU.CF_CRU_DESCRIPTION.credit_unit_code%TYPE,
                                    pi_date          IN CRU.CF_CRU_DESCRIPTION.start_date%TYPE      ,
                                    pi_language_code IN CRU.CF_CRU_DESCRIPTION.language_code%TYPE   )RETURN VARCHAR2;



  --COMPONENT CREDIT UNIT CONSULTING for pre-paid or post-paid
  PROCEDURE CREDIT_UNIT_CONSULTING( pi_component_element_id       IN  CRU.TR_ENTITY_CREDIT_UNIT.component_element_id%TYPE ,
                                    pi_telco_code                 IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE           ,
                                    pi_entity_type_code           IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_type_code%TYPE     ,
                                    pi_entity_id                  IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_id%TYPE            ,
                                    pi_client_id                  IN  NUMBER                                              ,
                                    pi_community_id               IN  NUMBER                                              ,
                                    pi_cen_id                     IN  NUMBER                                              ,
                                    pi_bill_element_code          IN  CRU.TR_ENTITY_CREDIT_UNIT.credit_unit_code%TYPE     ,
                                    pi_bill_element_type_code     IN  VARCHAR2                                            ,
                                    pi_component_currency         IN  VARCHAR2                                            ,
                                    pi_component_amount           IN  NUMBER                                              ,
                                    pi_component_quantity         IN  NUMBER                                              ,
                                    pi_component_quotes           IN  NUMBER                                              ,
                                    pi_client_type_code           IN  VARCHAR2                                            ,
                                    pi_client_segment_code        IN  VARCHAR2                                            ,
                                    pi_community_area_code        IN  VARCHAR2                                            ,
                                    pi_ce_type_code               IN  VARCHAR2                                            ,
                                    pi_ce_area_code               IN  VARCHAR2                                            ,
                                    pi_plan_category_id           IN  NUMBER                                              ,
                                    pi_plan_category_code         IN  VARCHAR2                                            ,
                                    pi_entity_plan_id             IN  NUMBER                                              ,
                                    pi_plan_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.plan_code%TYPE            ,
                                    pi_entity_component_id        IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE  ,
                                    pi_component_code             IN  CRU.TR_ENTITY_CREDIT_UNIT.component_code%TYPE       ,
                                    pi_add_data1                  IN  VARCHAR2                                            ,
                                    pi_add_data2                  IN  VARCHAR2                                            ,
                                    pi_add_data3                  IN  VARCHAR2                                            ,
                                    pi_add_data4                  IN  VARCHAR2                                            ,
                                    pi_add_data5                  IN  VARCHAR2                                            ,
                                    pi_entity_ageing              IN  VARCHAR2                                            ,
                                    pi_billing_community_id       IN  NUMBER                                              ,
                                    pi_activated_date             IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_date%TYPE       ,
                                    pi_activated_tran_code        IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_tran_code%TYPE  ,
                                    pi_deactivated_date           IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_date%TYPE     ,
                                    pi_deactivated_tran_code      IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_tran_code%TYPE,
                                    pi_tran_id                    IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_id%TYPE        ,
                                    pi_tran_date                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_date%TYPE      ,
                                    pi_user_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_user_code%TYPE      ,
                                    po_error_code                 OUT VARCHAR2                                            ,
                                    po_error_msg                  OUT VARCHAR2                                            );


  --CHECK PROCESSING RESPONSE for the verification
  PROCEDURE CHECK_PROCESSING_RESPONSE( pi_bill_tran_id     IN  CRU.TR_ENTITY_LOG.start_tran_id%TYPE   ,
                                       pi_telco_code       IN  CRU.TR_ENTITY_LOG.telco_code%TYPE      ,
                                       pi_entity_type_code IN  CRU.TR_ENTITY_LOG.ENTITY_TYPE_CODE%TYPE,
                                       pi_entity_id        IN  CRU.TR_ENTITY_LOG.entity_id%TYPE       ,
                                       pi_tran_id          IN  CRU.TR_ENTITY_LOG.start_tran_id%TYPE   ,
                                       po_resp             OUT VARCHAR2                               ,
                                       po_error_code       OUT VARCHAR2                               ,
                                       po_error_msg        OUT VARCHAR2                               );

  --CHANGE ASYNCHRONOUS STATUS an record for table TR_ENTITY_LOG receiving all columns as parameters
  PROCEDURE CHANGE_ASYNCHRONOUS_STATUS( pi_tran_id_process     IN  CRU.TR_ENTITY_LOG.end_tran_id%TYPE               ,
                                        pi_telco_code          IN  CRU.TR_ENTITY_LOG.telco_code%TYPE                ,
                                        pi_asynchronous_status IN  CRU.TR_ENTITY_LOG.asynchronous_status%TYPE       ,
                                        pi_asynchronous_answer IN  CRU.TR_ENTITY_LOG_STATUS.asynchronous_answer%TYPE,
                                        pi_asynchronous_date   IN  CRU.TR_ENTITY_LOG_STATUS.asynchronous_date%TYPE  ,
                                        pi_response_id         IN  CRU.TR_ENTITY_LOG_STATUS.response_id%TYPE        ,
                                        pi_tran_id             IN  CRU.TR_ENTITY_LOG.end_tran_id%TYPE               ,
                                        po_error_code          OUT VARCHAR2                                         ,
                                        po_error_msg           OUT VARCHAR2                                         ) ;

  --KEY TARIFF MODIFICATION
  PROCEDURE KEY_TARIFF_MODIFICATION( pi_telco_code             IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE         ,
                                     pi_tariff_key_code        IN  ITF.CF_DOMAIN.domain_code%TYPE                    ,
                                     pi_tariff_key_id          IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_id%TYPE          ,
                                     pi_modification_date      IN  CRU.TR_ENTITY_CREDIT_UNIT.start_date%TYPE         ,
                                     pi_modification_tran_code IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_tran_code%TYPE,
                                     pi_tran_id                IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_id%TYPE        ,
                                     pi_tran_date              IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_date%TYPE      ,
                                     pi_user_code              IN  CRU.TR_ENTITY_CREDIT_UNIT.end_user_code%TYPE      ,
                                     po_error_code             OUT VARCHAR2                                          ,
                                     po_error_msg              OUT VARCHAR2                                          );

   -- Returns the error message for any billing scheme
  FUNCTION GET_ERROR_MSG( pi_telco_code    IN  CRU.TR_ERROR_LOG.telco_code%TYPE  ,
                          pi_tran_id       IN  CRU.CF_ERROR.tran_id%TYPE:=NULL   ,
                          pi_error_code    IN  CRU.CF_ERROR.error_code%TYPE:=NULL,
                          pi_language_code IN  CRU.CF_ERROR.language_code%TYPE) RETURN VARCHAR2 ;
END TX_PUBLIC_ITF;
/
grant execute on CRU.TX_PUBLIC_ITF to ITF;


CREATE OR REPLACE PACKAGE BODY CRU.TX_PUBLIC_ITF
IS
   /******************************************************************************
   Implements procedures and functions necessary to process the
   %Company         Trilogy Software Bolivia
   %System          Omega Convergent Billing
   %Date            29/01/2010 10:25:48
   %Control         60079
   %Author          Rosio Teresa Eguivar Estrada
   %Version         1.1.0
   ******************************************************************************/
   VERSION CONSTANT VARCHAR2(15) := '3.0.0';
   v_package   VARCHAR2 (100) := 'CRU.TX_PUBLIC_ITF';

  


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
   Creates a record for table TR_ENTITY_CREDIT_UNIT receiving all columns as parameters
  %Date            01/02/2010 11:29:17
  %Control         60083
  %Author          "Rosio Teresa Eguivar Estrada"
  %Version         1.0.0
      %parama          pi_component_element_id          Component element identifier
      %param           pi_telco_code                    Code of operation
      %param           pi_entity_type_code              Entity type code
      %param           pi_entity_id                     Entity identifier
      %param           pi_client_id                     Client identifier
      %param           pi_community_id                  Community identifier
      %param           pi_cen_id                        Consumption entity identifier
      %param           pi_bill_element_code             Billing element code
      %param           pi_bill_element_type_code        Billing element type code
      %param           pi_component_currency            Component currency
      %param           pi_component_amount              Component amount
      %param           pi_component_quantity            Component quantity
      %param           pi_component_quotes              Component quotes
      %param           pi_client_type_code              Client type code
      %param           pi_client_segment_code           Client segment code
      %param           pi_community_area_code           Community area code
      %param           pi_ce_type_code                  Consumption entity type code
      %param           pi_ce_area_code                  Consumption entity area code
      %param           pi_plan_category_id              Plan category identifier
      %param           pi_plan_category_code            Plan category code
      %param           pi_entity_plan_id                Entity plan identifier
      %param           pi_plan_code                     Plan code
      %param           pi_entity_component_id           Entity component identifier
      %param           pi_component_code                Component code
      %param           pi_add_data1                     Additional data1
      %param           pi_add_data2                     Additional data2
      %param           pi_add_data3                     Additional data3
      %param           pi_add_data4                     Additional data4
      %param           pi_add_data5                     Additional data5
      %param           pi_entity_ageing                 Entity ageing
      %param           pi_billing_community_id          Billing community identifier
      %param           pi_activated_date                Activated date
      %param           pi_activated_tran_code           Activated transaction code
      %param           pi_deactivated_date              Deactivated date
      %param           pi_deactivated_tran_code         Deactivated transaction code
      %param           pi_is_postpaid                   Is postpaid
      %param           pi_tran_id                       Transaction identifier
      %param           pi_tran_date                     Transaction date
      %param           pi_user_code                     User code
      %param           po_err_code                      Output showing one of the next results:
                                                        {*} OK - If procedure executed satisfactorily
                                                        {*} XXX-#### - Error code if any error found
      %param           po_err_msg                       Output showing the error message if any error found
      %raises          ERR_APP                          Application level error

      %Changes
      <hr>
        {*}Date       18/05/2012 17:27:30
        {*}Control    299
        {*}Author     "Abel Soto Vera"
        {*}Note       Was removed fields Credit_limit_amount, credit_limit_currency_code and all functionality with these fields
  */
   PROCEDURE COMPONENT_ACTIVATION( pi_component_element_id       IN  CRU.TR_ENTITY_CREDIT_UNIT.component_element_id%TYPE ,
                                   pi_telco_code                 IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE           ,
                                   pi_entity_type_code           IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_type_code%TYPE     ,
                                   pi_entity_id                  IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_id%TYPE            ,
                                   pi_client_id                  IN  NUMBER                                              ,
                                   pi_community_id               IN  NUMBER                                              ,
                                   pi_cen_id                     IN  NUMBER                                              ,
                                   pi_bill_element_code          IN  CRU.TR_ENTITY_CREDIT_UNIT.credit_unit_code%TYPE     ,
                                   pi_bill_element_type_code     IN  VARCHAR2                                            ,
                                   pi_component_currency         IN  VARCHAR2                                            ,
                                   pi_component_amount           IN  NUMBER                                              ,
                                   pi_component_quantity         IN  NUMBER                                              ,
                                   pi_component_quotes           IN  NUMBER                                              ,
                                   pi_client_type_code           IN  VARCHAR2                                            ,
                                   pi_client_segment_code        IN  VARCHAR2                                            ,
                                   pi_community_area_code        IN  VARCHAR2                                            ,
                                   pi_ce_type_code               IN  VARCHAR2                                            ,
                                   pi_ce_area_code               IN  VARCHAR2                                            ,
                                   pi_plan_category_id           IN  NUMBER                                              ,
                                   pi_plan_category_code         IN  VARCHAR2                                            ,
                                   pi_entity_plan_id             IN  NUMBER                                              ,
                                   pi_plan_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.plan_code%TYPE            ,
                                   pi_entity_component_id        IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE  ,
                                   pi_component_code             IN  CRU.TR_ENTITY_CREDIT_UNIT.component_code%TYPE       ,
                                   pi_add_data1                  IN  VARCHAR2                                            ,
                                   pi_add_data2                  IN  VARCHAR2                                            ,
                                   pi_add_data3                  IN  VARCHAR2                                            ,
                                   pi_add_data4                  IN  VARCHAR2                                            ,
                                   pi_add_data5                  IN  VARCHAR2                                            ,
                                   pi_entity_ageing              IN  VARCHAR2                                            ,
                                   pi_billing_community_id       IN  NUMBER                                              ,
                                   pi_activated_date             IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_date%TYPE       ,
                                   pi_activated_tran_code        IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_tran_code%TYPE  ,
                                   pi_deactivated_date           IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_date%TYPE     ,
                                   pi_deactivated_tran_code      IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_tran_code%TYPE,
                                   pi_is_postpaid                IN  VARCHAR2                                            ,
                                   pi_tran_id                    IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_id%TYPE        ,
                                   pi_tran_date                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_date%TYPE      ,
                                   pi_user_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_user_code%TYPE      ,
                                   po_error_code                 OUT VARCHAR2                                            ,
                                   po_error_msg                  OUT VARCHAR2                                            )
   IS
      -- Mandatory variables for security and logs
      v_package_procedure VARCHAR2 (100) := v_package || '.COMPONENT_ACTIVATION' ;
      v_param_in   VARCHAR2 (4000);
      -- Declare Exceptions
      ERR_APP EXCEPTION;
   BEGIN
      po_error_code := 'OK';
      po_error_msg := '';

      ---------------------------------------- DML Operations -----------------------------------

      CRU.TX_REGISTER_ENTITY_PROCESS.COMPONENT_ACTIVATION( pi_component_element_id       => pi_component_element_id      ,
                                                           pi_telco_code                 => pi_telco_code                ,
                                                           pi_entity_type_code           => pi_entity_type_code          ,
                                                           pi_entity_id                  => pi_entity_id                 ,
                                                           pi_client_id                  => pi_client_id                 ,
                                                           pi_community_id               => pi_community_id              ,
                                                           pi_cen_id                     => pi_cen_id                    ,
                                                           pi_bill_element_code          => pi_bill_element_code         ,
                                                           pi_bill_element_type_code     => pi_bill_element_type_code    ,
                                                           pi_component_currency         => pi_component_currency        ,
                                                           pi_component_amount           => pi_component_amount          ,
                                                           pi_component_quantity         => pi_component_quantity        ,
                                                           pi_component_quotes           => pi_component_quotes          ,
                                                           pi_client_type_code           => pi_client_type_code          ,
                                                           pi_client_segment_code        => pi_client_segment_code       ,
                                                           pi_community_area_code        => pi_community_area_code       ,
                                                           pi_ce_type_code               => pi_ce_type_code              ,
                                                           pi_ce_area_code               => pi_ce_area_code              ,
                                                           pi_plan_category_id           => pi_plan_category_id          ,
                                                           pi_plan_category_code         => pi_plan_category_code        ,
                                                           pi_entity_plan_id             => pi_entity_plan_id            ,
                                                           pi_plan_code                  => pi_plan_code                 ,
                                                           pi_entity_component_id        => pi_entity_component_id       ,
                                                           pi_component_code             => pi_component_code            ,
                                                           pi_add_data1                  => pi_add_data1                 ,
                                                           pi_add_data2                  => pi_add_data2                 ,
                                                           pi_add_data3                  => pi_add_data3                 ,
                                                           pi_add_data4                  => pi_add_data4                 ,
                                                           pi_add_data5                  => pi_add_data5                 ,
                                                           pi_entity_ageing              => pi_entity_ageing             ,
                                                           pi_billing_community_id       => pi_billing_community_id      ,
                                                           pi_activated_date             => pi_activated_date            ,
                                                           pi_activated_tran_code        => pi_activated_tran_code       ,
                                                           pi_deactivated_date           => pi_deactivated_date          ,
                                                           pi_deactivated_tran_code      => pi_deactivated_tran_code     ,
                                                           pi_is_postpaid                => pi_is_postpaid               ,
                                                           pi_tran_id                    => pi_tran_id                   ,
                                                           pi_tran_date                  => pi_tran_date                 ,
                                                           pi_user_code                  => pi_user_code                 ,
                                                           po_error_code                 => po_error_code                ,
                                                           po_error_msg                  => po_error_msg                 );

      IF NVL (po_error_code, 'NOK') <> 'OK' THEN
         RAISE ERR_APP;
      END IF;
   --------------------------------------- End of DML Operations --------------------------------
   EXCEPTION
      WHEN ERR_APP THEN
         v_param_in :=       ---------- variable parameters ------------------
                     'pi_component_element_id:'        || pi_component_element_id    ||
                     '|pi_telco_code:'                 || pi_telco_code              ||
                     '|pi_entity_type_code:'           || pi_entity_type_code        ||
                     '|pi_entity_id:'                  || pi_entity_id               ||
                     '|pi_client_id:'                  || pi_client_id               ||
                     '|pi_community_id:'               || pi_community_id            ||
                     '|pi_cen_id:'                     || pi_cen_id                  ||
                     '|pi_bill_element_code:'          || pi_bill_element_code       ||
                     '|pi_bill_element_type_code:'     || pi_bill_element_type_code  ||
                     '|pi_component_currency:'         || pi_component_currency      ||
                     '|pi_component_amount:'           || pi_component_amount        ||
                     '|pi_component_quantity:'         || pi_component_quantity      ||
                     '|pi_component_quotes:'           || pi_component_quotes        ||
                     '|pi_client_type_code:'           || pi_client_type_code        ||
                     '|pi_client_segment_code:'        || pi_client_segment_code     ||
                     '|pi_community_area_code:'        || pi_community_area_code     ||
                     '|pi_ce_type_code:'               || pi_ce_type_code            ||
                     '|pi_ce_area_code:'               || pi_ce_area_code            ||
                     '|pi_plan_category_id:'           || pi_plan_category_id        ||
                     '|pi_plan_category_code:'         || pi_plan_category_code      ||
                     '|pi_entity_plan_id:'             || pi_entity_plan_id          ||
                     '|pi_plan_code:'                  || pi_plan_code               ||
                     '|pi_entity_component_id:'        || pi_entity_component_id     ||
                     '|pi_component_code:'             || pi_component_code          ||
                     '|pi_add_data1:'                  || pi_add_data1               ||
                     '|pi_add_data2:'                  || pi_add_data2               ||
                     '|pi_add_data3:'                  || pi_add_data3               ||
                     '|pi_add_data4:'                  || pi_add_data4               ||
                     '|pi_add_data5:'                  || pi_add_data5               ||
                     '|pi_entity_ageing:'              || pi_entity_ageing           ||
                     '|pi_billing_community_id:'       || pi_billing_community_id                            ||
                     '|pi_activated_date:'             || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                     '|pi_activated_tran_code:'        || pi_activated_tran_code                             ||
                     '|pi_deactivated_date:'           || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                     '|pi_deactivated_tran_code:'      || pi_activated_tran_code                             ||
                     '|pi_tran_id:'                    || pi_tran_id                                         ||
                     '|pi_tran_date:'                  || TO_CHAR (pi_tran_date,'DD/MM/YYYY HH24:MI:SS')     ||
                     '|pi_user_code:'                  || pi_user_code;

         CRU.TX_TR_ERROR_LOG.RECORD_LOG ( pi_telco_code    => pi_telco_code,
                                          pi_tran_id       => pi_tran_id   ,
                                          pi_error_code    => po_error_code,
                                          pi_error_msg     => po_error_msg ,
                                          pi_error_source  => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));
      WHEN OTHERS THEN
         -- Initiate log variables
         po_error_msg := SUBSTR (SQLERRM, 1, 1000);
         po_error_code := 'CRU-0335';        --Critical error.||Error critico.
         v_param_in :=       ---------- variable parameters ------------------
                     'pi_component_element_id:'        || pi_component_element_id    ||
                     '|pi_telco_code:'                 || pi_telco_code              ||
                     '|pi_entity_type_code:'           || pi_entity_type_code        ||
                     '|pi_entity_id:'                  || pi_entity_id               ||
                     '|pi_client_id:'                  || pi_client_id               ||
                     '|pi_community_id:'               || pi_community_id            ||
                     '|pi_cen_id:'                     || pi_cen_id                  ||
                     '|pi_bill_element_code:'          || pi_bill_element_code       ||
                     '|pi_bill_element_type_code:'     || pi_bill_element_type_code  ||
                     '|pi_component_currency:'         || pi_component_currency      ||
                     '|pi_component_amount:'           || pi_component_amount        ||
                     '|pi_component_quantity:'         || pi_component_quantity      ||
                     '|pi_component_quotes:'           || pi_component_quotes        ||
                     '|pi_client_type_code:'           || pi_client_type_code        ||
                     '|pi_client_segment_code:'        || pi_client_segment_code     ||
                     '|pi_community_area_code:'        || pi_community_area_code     ||
                     '|pi_ce_type_code:'               || pi_ce_type_code            ||
                     '|pi_ce_area_code:'               || pi_ce_area_code            ||
                     '|pi_plan_category_id:'           || pi_plan_category_id        ||
                     '|pi_plan_category_code:'         || pi_plan_category_code      ||
                     '|pi_entity_plan_id:'             || pi_entity_plan_id          ||
                     '|pi_plan_code:'                  || pi_plan_code               ||
                     '|pi_entity_component_id:'        || pi_entity_component_id     ||
                     '|pi_component_code:'             || pi_component_code          ||
                     '|pi_add_data1:'                  || pi_add_data1               ||
                     '|pi_add_data2:'                  || pi_add_data2               ||
                     '|pi_add_data3:'                  || pi_add_data3               ||
                     '|pi_add_data4:'                  || pi_add_data4               ||
                     '|pi_add_data5:'                  || pi_add_data5               ||
                     '|pi_entity_ageing:'              || pi_entity_ageing           ||
                     '|pi_billing_community_id:'       || pi_billing_community_id                            ||
                     '|pi_activated_date:'             || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                     '|pi_activated_tran_code:'        || pi_activated_tran_code                             ||
                     '|pi_deactivated_date:'           || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                     '|pi_deactivated_tran_code:'      || pi_activated_tran_code                             ||
                     '|pi_tran_id:'                    || pi_tran_id                                         ||
                     '|pi_tran_date:'                  || TO_CHAR (pi_tran_date,'DD/MM/YYYY HH24:MI:SS')     ||
                     '|pi_user_code:'                  || pi_user_code;

         CRU.TX_TR_ERROR_LOG.RECORD_LOG ( pi_telco_code    => pi_telco_code,
                                          pi_tran_id      => pi_tran_id   ,
                                          pi_error_code   => po_error_code,
                                          pi_error_msg    => po_error_msg ,
                                          pi_error_source => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));
   END;

   /*
   Deactivation Instance of table TR_ENTITY_CREDIT_UNIT receiving all parameters values
  %Date            01/02/2010 11:29:17
  %Control         60083
  %Author          "Rosio Teresa Eguivar Estrada"
  %Version         1.0.0
      %param           pi_entity_component_id           Entity component identifier
      %param           pi_telco_code                    Code of operation
      %param           pi_deactivated_date              Deactivated date
      %param           pi_deactivated_tran_code         Deactivated transaction code
      %param           pi_is_postpaid                   Is postpaid
      %param           pi_tran_id                       Transaction identifier
      %param           pi_tran_date                     Transaction date
      %param           pi_user_code                     User code
      %param           po_rec_entity_status_id          Output ID the table
      %param           po_err_code                      Output showing one of the next results:
                                                        {*} OK - If procedure executed satisfactorily
                                                        {*} XXX-#### - Error code if any error found
      %param           po_err_msg                       Output showing the error message if any error found
      %raises          ERR_APP                          Application level error
  */

  PROCEDURE COMPONENT_DEACTIVATION( pi_entity_component_id   IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE  ,
                                    pi_telco_code            IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE           ,
                                    pi_deactivated_date      IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_date%TYPE     ,
                                    pi_deactivated_tran_code IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_tran_code%TYPE,
                                    pi_is_postpaid           IN  VARCHAR2                                            ,
                                    pi_tran_id               IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_id%TYPE          ,
                                    pi_tran_date             IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_date%TYPE        ,
                                    pi_user_code             IN  CRU.TR_ENTITY_CREDIT_UNIT.end_user_code%TYPE        ,
                                    po_error_code            OUT VARCHAR2                                            ,
                                    po_error_msg             OUT VARCHAR2                                            ) IS
    -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2 (100) := v_package || '.COMPONENT_DEACTIVATION' ;
    v_param_in   VARCHAR2 (4000);
    -- Declare Exceptions
    ERR_APP EXCEPTION;
  BEGIN
    po_error_code := 'OK';
    po_error_msg := '';

    ---------------------------------------- DML Operations -----------------------------------
    CRU.TX_REGISTER_ENTITY_PROCESS.COMPONENT_DEACTIVATION( pi_entity_component_id   => pi_entity_component_id  ,
                                                           pi_telco_code            => pi_telco_code           ,
                                                           pi_deactivated_date      => pi_deactivated_date     ,
                                                           pi_deactivated_tran_code => pi_deactivated_tran_code,
                                                           pi_is_postpaid           => pi_is_postpaid          ,
                                                           pi_tran_id               => pi_tran_id              ,
                                                           pi_tran_date             => pi_tran_date            ,
                                                           pi_user_code             => pi_user_code            ,
                                                           po_error_code            => po_error_code           ,
                                                           po_error_msg             => po_error_msg            );

    IF NVL (po_error_code, 'NOK') <> 'OK' THEN
       RAISE ERR_APP;
    END IF;
  --------------------------------------- End of DML Operations --------------------------------
  EXCEPTION
    WHEN ERR_APP THEN
      v_param_in :=       ---------- variable parameters ------------------
                  'pi_entity_component_id: '    || pi_entity_component_id                                ||
                  '|pi_telco_code: '            || pi_telco_code                                         ||
                  '|pi_deactivated_date: '      || TO_CHAR (pi_deactivated_date, 'DD/MM/YYYY HH24:MI:SS')||
                  '|pi_deactivated_tran_code: ' || pi_deactivated_tran_code                              ||
                  '|pi_tran_id: '               || pi_tran_id                                            ||
                  '|pi_tran_date: '             || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')       ||
                  '|pi_user_code: '             || pi_user_code;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id   ,
                                      pi_error_code   => po_error_code,
                                      pi_error_msg    => po_error_msg ,
                                      pi_error_source => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));
    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg := SUBSTR (SQLERRM, 1, 1000);
      po_error_code := 'CRU-0336';        --Critical error.||Error critico.
      v_param_in :=       ---------- variable parameters ------------------
                  'pi_entity_component_id: '    || pi_entity_component_id                                ||
                  '|pi_telco_code: '            || pi_telco_code                                         ||
                  '|pi_deactivated_date: '      || TO_CHAR (pi_deactivated_date, 'DD/MM/YYYY HH24:MI:SS')||
                  '|pi_deactivated_tran_code: ' || pi_deactivated_tran_code                              ||
                  '|pi_tran_id: '               || pi_tran_id                                            ||
                  '|pi_tran_date: '             || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')       ||
                  '|pi_user_code: '             || pi_user_code;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id   ,
                                      pi_error_code   => po_error_code,
                                      pi_error_msg    => po_error_msg ,
                                      pi_error_source => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));
  END;

   /*
   Remove a record for table TR_ENTITY_CREDIT_UNIT receiving all columns as parameters
  %Date            09/03/2010 15:29:17
  %Control         60083
  %Author          "Rosio Teresa Eguivar Estrada"
  %Version         1.0.0
      %param           pi_entity_component_id      Entity component identifier
      %param           pi_telco_code               Code of operation
      %param           pi_tran_id                  Transaction identifier
      %param           pi_tran_date                Transaction date
      %param           pi_user_code                User code
      %param           po_rec_entity_status_id     Output ID the table
      %param           po_err_code                 Output showing one of the next results:
                                                   {*} OK - If procedure executed satisfactorily
                                                   {*} XXX-#### - Error code if any error found
      %param           po_err_msg                  Output showing the error message if any error found
      %raises          ERR_APP                     Application level error
*/


  PROCEDURE COMPONENT_REMOVE( pi_entity_component_id IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE,
                              pi_telco_code          IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE         ,
                              pi_tran_id             IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_id%TYPE	       ,
                              pi_tran_date           IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_date%TYPE      ,
                              pi_user_code           IN  CRU.TR_ENTITY_CREDIT_UNIT.end_user_code%TYPE      ,
                              po_error_code          OUT VARCHAR2                                          ,
                              po_error_msg           OUT VARCHAR2                                          )
  IS
     -- Mandatory variables for security and logs
     v_package_procedure VARCHAR2 (100) := v_package || '.COMPONENT_REMOVE' ;
     v_param_in   VARCHAR2 (4000);
     -- Declare Exceptions
     ERR_APP EXCEPTION;
  BEGIN
     po_error_code := 'OK';
     po_error_msg := '';

     ---------------------------------------- DML Operations -----------------------------------
     CRU.TX_REGISTER_ENTITY_PROCESS.COMPONENT_REMOVE( pi_entity_component_id => pi_entity_component_id,
                                                      pi_telco_code          => pi_telco_code         ,
                                                      pi_tran_id             => pi_tran_id            ,
                                                      pi_tran_date           => pi_tran_date          ,
                                                      pi_user_code           => pi_user_code          ,
                                                      po_error_code          => po_error_code         ,
                                                      po_error_msg           => po_error_msg          );

     IF NVL (po_error_code, 'NOK') <> 'OK' THEN
        RAISE ERR_APP;
     END IF;
  --------------------------------------- End of DML Operations --------------------------------
  EXCEPTION
    WHEN ERR_APP THEN
       v_param_in :=       ---------- variable parameters ------------------
                   'pi_entity_component_id: ' || pi_entity_component_id                          ||
                   '|pi_telco_code: '         || pi_telco_code                                   ||
                   '|pi_tran_id: '            || pi_tran_id                                      ||
                   '|pi_tran_date: '          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS') ||
                   '|pi_user_code: '          || pi_user_code;

       CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                       pi_tran_id      => pi_tran_id   ,
                                       pi_error_code   => po_error_code,
                                       pi_error_msg    => po_error_msg ,
                                       pi_error_source => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));

    WHEN OTHERS THEN
       -- Initiate log variables
       po_error_msg  := SUBSTR (SQLERRM, 1, 1000);
       po_error_code := 'CRU-0337';        --Critical error.||Error critico.
       v_param_in    :=       ---------- variable parameters ------------------
                       'pi_entity_component_id: ' || pi_entity_component_id                          ||
                       '|pi_telco_code: '         || pi_telco_code                                   ||
                       '|pi_tran_id: '            || pi_tran_id                                      ||
                       '|pi_tran_date: '          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS') ||
                       '|pi_user_code: '          || pi_user_code;

       CRU.TX_TR_ERROR_LOG.RECORD_LOG ( pi_telco_code   => pi_telco_code,
                                        pi_tran_id      => pi_tran_id   ,
                                        pi_error_code   => po_error_code,
                                        pi_error_msg    => po_error_msg ,
                                        pi_error_source => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));
  END;






   /*
   CHANGE S status ASYNCHRONOUS for table TR_ENTITY_CREDIT_UNIT receiving all columns as parameters
  %Date            09/03/2010 15:29:17
  %Control         60083
  %Author          "Rosio Teresa Eguivar Estrada"
  %Version         1.0.0
      %param           pi_tran_id_process             Transaction identifier process
      %param           pi_telco_code                  Code of operation
      %param           pi_asynchronous_status         Asynchronous status
      %param           pi_asynchronous_answer         Asynchronous answer
      %param           pi_asynchronous_date           Asynchronous date
      %param           pi_tran_id                     Transaction identifier
      %param           po_err_code                    Output showing one of the next results:
                                                      {*} OK - If procedure executed satisfactorily
                                                      {*} XXX-#### - Error code if any error found
      %param           po_err_msg                     Output showing the error message if any error found
      %raises          ERR_APP                        Application level error
  */

  PROCEDURE CHANGE_ASYNCHRONOUS_BILLING( pi_tran_id_process     IN  CRU.TR_ENTITY_LOG.end_tran_id%TYPE        ,
                                         pi_telco_code          IN  CRU.TR_ENTITY_LOG.telco_code%TYPE         ,
                                         pi_asynchronous_status IN  CRU.TR_ENTITY_LOG.asynchronous_status%TYPE,
                                         pi_asynchronous_answer IN  CRU.TR_ENTITY_LOG_STATUS.asynchronous_answer%TYPE,
                                         pi_asynchronous_date   IN  CRU.TR_ENTITY_LOG_STATUS.asynchronous_date%TYPE  ,
                                         pi_response_id         IN  CRU.TR_ENTITY_LOG_STATUS.response_id%TYPE        ,
                                         pi_tran_id             IN  CRU.TR_ENTITY_LOG.end_tran_id%TYPE        ,
                                         po_error_code          OUT VARCHAR2                                  ,
                                         po_error_msg           OUT VARCHAR2                                  ) IS
    -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2 (100) := v_package || '.CHANGE_ASYNCHRONOUS_BILLING';
    v_param_in   VARCHAR2 (4000);
    -- Declare Exceptions
    ERR_APP EXCEPTION;
  BEGIN
    po_error_code := 'OK';
    po_error_msg := '';

    ---------------------------------------- DML Operations -----------------------------------
    CRU.TX_TR_ENTITY_LOG.CHANGE_STATUS_ASYNC_BILLING( pi_tran_id_process      => pi_tran_id_process    ,
                                                      pi_telco_code           => pi_telco_code         ,
                                                      pi_asynchronous_status  => pi_asynchronous_status,
                                                      pi_asynchronous_answer  => pi_asynchronous_answer,
                                                      pi_asynchronous_date    => pi_asynchronous_date  ,
                                                      pi_response_id          => pi_response_id        ,
                                                      pi_tran_id              => pi_tran_id            ,
                                                      po_error_code           => po_error_code         ,
                                                      po_error_msg            => po_error_msg          );

    IF NVL (po_error_code, 'NOK') <> 'OK' THEN
       RAISE ERR_APP;
    END IF;
  --------------------------------------- End of DML Operations --------------------------------
  EXCEPTION
    WHEN ERR_APP THEN
      v_param_in :=       ---------- variable parameters ------------------
                   'pi_tran_id_process: '      || pi_tran_id_process                                      ||
                   '|pi_telco_code: '          || pi_telco_code                                           ||
                   '|pi_asynchronous_status: ' || pi_asynchronous_status                                  ||
                   '|pi_asynchronous_answer: ' || pi_asynchronous_answer                                  ||
                   '|pi_asynchronous_date: '   || TO_CHAR (pi_asynchronous_date, 'DD/MM/YYYY HH24:MI:SS') ||
                   '|pi_response_id: '         || pi_response_id                                          ||
                   '|pi_tran_id: '             || pi_tran_id;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id   ,
                                      pi_error_code   => po_error_code,
                                      pi_error_msg    => po_error_msg ,
                                      pi_error_source => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));
    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg  := SUBSTR (SQLERRM, 1, 1000);
      po_error_code := 'CRU-0338';        --Critical error.||Error critico.
      v_param_in    :=       ---------- variable parameters ------------------
                     'pi_tran_id_process: '      || pi_tran_id_process                                      ||
                     '|pi_telco_code: '          || pi_telco_code                                           ||
                     '|pi_asynchronous_status: ' || pi_asynchronous_status                                  ||
                     '|pi_asynchronous_answer: ' || pi_asynchronous_answer                                  ||
                     '|pi_asynchronous_date: '   || TO_CHAR (pi_asynchronous_date, 'DD/MM/YYYY HH24:MI:SS') ||
                     '|pi_response_id: '         || pi_response_id                                          ||
                     '|pi_tran_id: '             || pi_tran_id;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG ( pi_telco_code   => pi_telco_code,
                                       pi_tran_id      => pi_tran_id   ,
                                       pi_error_code   => po_error_code,
                                       pi_error_msg    => po_error_msg ,
                                       pi_error_source => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));
  END;


   /*
   QUERY_GET_RATE_AMOUNT of table CF_RATE receiving all columns as parameters
  %Date            09/03/2010 15:29:17
  %Control         60083
  %Author          "Rosio Teresa Eguivar Estrada"
  %Version         1.0.0
      %param         pi_entity_type_code        Entity type code
      %param         pi_entity_id               Entity identifier
      %param         pi_client_type_code        Client type code
      %param         pi_client_segment_cod      Client segment code
      %param         pi_community_area_cod      Community area code
      %param         pi_ce_type_code            Consumption entity type code
      %param         pi_ce_area_code            Consumption entity area code
      %param         pi_entity_ageing           Entity ageing
      %param         pi_plan_category_code      Plan category code
      %param         pi_plan_code               Plan code
      %param         pi_component_code          Component code
      %param         pi_add_data1               Additional data1
      %param         pi_add_data2               Additional data2
      %param         pi_add_data3               Additional data3
      %param         pi_add_data4               Additional data4
      %param         pi_add_data5               Additional data5
      %param         pi_evaluate_date           Evaluate date
      %param         pi_credit_unit_code        Credit unit code
      %param         pi_tran_id                 Tran identifier
      %param         pi_tran_date               Tran date
      %param         po_rate_id                 Rate identifier
      %param         po_rate_quantity           Rate quantity
      %param         po_error_code              Output showing one of the next results:
                                                {*} OK - If procedure executed satisfactorily
                                                {*} XXX-#### - Error code if any error found
      %param         po_error_msg               Output showing the error message if any error found
      %raises        ERR_APP                    Application level error
  */


  PROCEDURE QUERY_GET_RATE_AMOUNT( pi_entity_type_code    IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE   ,
                                   pi_telco_code          IN  CRU.TR_ENTITY_LOG.telco_code%TYPE         ,
                                   pi_entity_id           IN  CRU.TR_ENTITY_LOG.entity_id%TYPE          ,
                                   pi_client_type_code    IN  CRU.TR_ENTITY_LOG.client_type_code%TYPE   ,
                                   pi_client_segment_code IN  CRU.TR_ENTITY_LOG.client_segment_code%TYPE,
                                   pi_community_area_code IN  CRU.TR_ENTITY_LOG.community_area_code%TYPE,
                                   pi_ce_type_code        IN  CRU.TR_ENTITY_LOG.ce_type_code%TYPE       ,
                                   pi_ce_area_code        IN  CRU.TR_ENTITY_LOG.ce_area_code%TYPE       ,
                                   pi_entity_ageing       IN  CRU.TR_ENTITY_LOG.entity_ageing%TYPE      ,
                                   pi_plan_category_code  IN  CRU.TR_ENTITY_LOG.plan_category_code%TYPE ,
                                   pi_plan_code           IN  CRU.TR_ENTITY_LOG.plan_code%TYPE          ,
                                   pi_component_code      IN  CRU.TR_ENTITY_LOG.component_code%TYPE     ,
                                   pi_add_data1           IN  CRU.TR_ENTITY_LOG.add_data1%TYPE          ,
                                   pi_add_data2           IN  CRU.TR_ENTITY_LOG.add_data2%TYPE          ,
                                   pi_add_data3           IN  CRU.TR_ENTITY_LOG.add_data3%TYPE          ,
                                   pi_add_data4           IN  CRU.TR_ENTITY_LOG.add_data4%TYPE          ,
                                   pi_add_data5           IN  CRU.TR_ENTITY_LOG.add_data5%TYPE          ,
                                   pi_evaluate_date       IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE   ,
                                   pi_credit_unit_code    IN  CRU.CF_CREDIT_UNIT.CREDIT_UNIT_CODE%TYPE  ,
                                   pi_tran_id             IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE     ,
                                   pi_tran_date           IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE   ,
                                   po_rate_id             OUT CRU.CF_CRU_RATE.cru_rate_id%TYPE          ,
                                   po_rate_quantity       OUT CRU.TR_ENTITY_LOG.quantity%TYPE           ,
                                   po_error_code          OUT VARCHAR2                                  ,
                                   po_error_msg           OUT VARCHAR2                                 ) IS
   -- Mandatory variables for security and logs
  v_package_procedure VARCHAR2(100) := v_package || '.QUERY_GET_RATE_AMOUNT';
  v_param_in          VARCHAR2(4000)                                        ;
  --Variables


  ERR_APP EXCEPTION;
  BEGIN
    po_error_code :='OK';
    po_error_msg  :='';

    CRU.BL_UTILITIES.QUERY_GET_RATE_AMOUNT( pi_telco_code          => pi_telco_code          ,
                                            pi_entity_type_code    => pi_entity_type_code    ,
                                            pi_entity_id           => pi_entity_id           ,
                                            pi_client_type_code    => pi_client_type_code    ,
                                            pi_client_segment_code => pi_client_segment_code ,
                                            pi_community_area_code => pi_community_area_code ,
                                            pi_ce_type_code        => pi_ce_type_code        ,
                                            pi_ce_area_code        => pi_ce_area_code        ,
                                            pi_entity_ageing       => pi_entity_ageing       ,
                                            pi_plan_category_code  => pi_plan_category_code  ,
                                            pi_plan_code           => pi_plan_code           ,
                                            pi_component_code      => pi_component_code      ,
                                            pi_add_data1           => pi_add_data1           ,
                                            pi_add_data2           => pi_add_data2           ,
                                            pi_add_data3           => pi_add_data3           ,
                                            pi_add_data4           => pi_add_data4           ,
                                            pi_add_data5           => pi_add_data5           ,
                                            pi_evaluate_date       => pi_evaluate_date       ,
                                            pi_credit_unit_code    => pi_credit_unit_code    ,
                                            pi_tran_id             => pi_tran_id             ,
                                            pi_tran_date           => pi_tran_date           ,
                                            po_rate_id             => po_rate_id             ,
                                            po_rate_quantity       => po_rate_quantity       ,
                                            po_error_code          => po_error_code          ,
                                            po_error_msg           => po_error_msg           );

    IF nvl(po_error_code,'NOK')!= 'OK' THEN
      RAISE ERR_APP;
    END IF;

  EXCEPTION
    WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in := ------------------------------------ variable parameters ---------------------------------
                    'pi_entity_type_code:'   || pi_entity_type_code                                ||
                    '|pi_telco_code:'         || pi_telco_code                                      ||
                    '|pi_entity_id:'          || pi_entity_id                                       ||
                    '|pi_client_type_code:'   || pi_client_type_code                                ||
                    '|pi_client_segment_code:'|| pi_client_segment_code                             ||
                    '|pi_community_area_code:'|| pi_community_area_code                             ||
                    '|pi_ce_type_code:'       || pi_ce_type_code                                    ||
                    '|pi_ce_area_code:'       || pi_ce_area_code                                    ||
                    '|pi_entity_ageing:'      || pi_entity_ageing                                   ||
                    '|pi_plan_category_code:' || pi_plan_category_code                              ||
                    '|pi_plan_code:'          || pi_plan_code                                       ||
                    '|pi_component_code:'     || pi_component_code                                  ||
                    '|pi_add_data1:'          || pi_add_data1                                       ||
                    '|pi_add_data2:'          || pi_add_data2                                       ||
                    '|pi_add_data3:'          || pi_add_data3                                       ||
                    '|pi_add_data4:'          || pi_add_data4                                       ||
                    '|pi_add_data5:'          || pi_add_data5                                       ||
                    '|pi_evaluate_date:'      || TO_CHAR (pi_evaluate_date, 'DD/MM/YYYY HH24:MI:SS')||
                    '|pi_credit_unit_code:'   || pi_credit_unit_code                                ||
                    '|pi_tran_id:'            || pi_tran_id                                         ||
                    '|pi_tran_date:'          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')     ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code                                            ,
                                      pi_tran_id      => pi_tran_id                                            ,
                                      pi_error_code   => po_error_code                                                 ,
                                      pi_error_msg    => po_error_msg                                                  ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));

    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code := 'CRU-0339';--Critical error.||Error critico.
      v_param_in    := ------------------------------------ variable parameters ---------------------------------
                    'pi_entity_type_code:'   || pi_entity_type_code                                || 
                    '|pi_telco_code:'         || pi_telco_code                                      ||
                    '|pi_entity_id:'          || pi_entity_id                                       || 
                    '|pi_client_type_code:'   || pi_client_type_code                                || 
                    '|pi_client_segment_code:'|| pi_client_segment_code                             || 
                    '|pi_community_area_code:'|| pi_community_area_code                             || 
                    '|pi_ce_type_code:'       || pi_ce_type_code                                    || 
                    '|pi_ce_area_code:'       || pi_ce_area_code                                    || 
                    '|pi_entity_ageing:'      || pi_entity_ageing                                   || 
                    '|pi_plan_category_code:' || pi_plan_category_code                              || 
                    '|pi_plan_code:'          || pi_plan_code                                       || 
                    '|pi_component_code:'     || pi_component_code                                  || 
                    '|pi_add_data1:'          || pi_add_data1                                       || 
                    '|pi_add_data2:'          || pi_add_data2                                       || 
                    '|pi_add_data3:'          || pi_add_data3                                       || 
                    '|pi_add_data4:'          || pi_add_data4                                       || 
                    '|pi_add_data5:'          || pi_add_data5                                       || 
                    '|pi_evaluate_date:'      || TO_CHAR (pi_evaluate_date, 'DD/MM/YYYY HH24:MI:SS')|| 
                    '|pi_credit_unit_code:'   || pi_credit_unit_code                                || 
                    '|pi_tran_id:'            || pi_tran_id                                         || 
                    '|pi_tran_date:'          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')     ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code                                            ,
                                      pi_tran_id      => pi_tran_id                                            ,
                                      pi_error_code   => po_error_code                                                 ,
                                      pi_error_msg    => po_error_msg                                                  ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' ||v_param_in || ')',1,4000));

  END;

  /*
  GET END DATE INSTANCE for TR_ENTITY_CREDIT_UNIT receiving all parameters values
  %Date          08/11/2010 10:24:07
  %Control       20338
  %Author        "Abel Soto"
  %Version       1.0.0
      %param         pi_entity_id               Entity identifier
      %param         pi_entity_type_code        Entity type code
      %param         pi_component_code          Component code
      %param         pi_element_code            Element code
      %param         pi_tran_id                 Transaction identifier
      %param         pi_date                    Date request
  */

  FUNCTION GET_END_DATE_INSTANCE( pi_telco_code       IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE     ,
                                  pi_entity_id        IN CRU.TR_ENTITY_CREDIT_UNIT.entity_id%TYPE       ,
                                  pi_entity_type_code IN CRU.TR_ENTITY_CREDIT_UNIT.entity_type_code%TYPE,
                                  pi_component_code   IN CRU.TR_ENTITY_CREDIT_UNIT.component_code%TYPE  ,
                                  pi_element_code     IN CRU.TR_ENTITY_CREDIT_UNIT.credit_unit_code%TYPE,
                                  pi_tran_id          IN CRU.TR_ENTITY_CREDIT_UNIT.start_tran_id%TYPE   ,
                                  pi_date             IN CRU.TR_ENTITY_CREDIT_UNIT.start_tran_date%TYPE )RETURN DATE IS

    v_end_date_instance DATE;
  BEGIN
    v_end_date_instance := bl_utilities.get_end_date_instance( pi_telco_code       => pi_telco_code      ,
                                                               pi_entity_id        => pi_entity_id       ,
                                                               pi_entity_type_code => pi_entity_type_code,
                                                               pi_component_code   => pi_component_code  ,
                                                               pi_element_code     => pi_element_code    ,
                                                               pi_tran_id          => pi_tran_id         ,
                                                               pi_date             => pi_date            );
    RETURN v_end_date_instance;
  END;

    /*
   Asign CRUs generic in the TR_ENTITY_LOG receiving all parameters
  %Date            01/02/2010 11:29:17
  %Control         60083
  %Author          "Rosio Teresa Eguivar Estrada"
  %Version         1.0.0
      %param           pi_telco_code                        Telco Code
      %parama          pi_component_element_id              Component element identifier
      %param           pi_telco_code                        Code of operation
      %param           pi_entity_type_code                  Entity type code
      %param           pi_entity_id                         Entity identifier
      %param           pi_client_id                         Client identifier
      %param           pi_community_id                      Community identifier
      %param           pi_cen_id                            Consumption entity identifier
      %param           pi_bill_element_code                 Bill element_code
      %param           pi_bill_element_type_code            Bill element type_code
      %param           pi_component_currency                Component currency
      %param           pi_component_amount                  Component amount
      %param           pi_component_quantity                Component quantity
      %param           pi_component_quotes                  Component quotes
      %param           pi_client_type_code                  Client type code
      %param           pi_client_segment_code               Client segment code
      %param           pi_community_area_code               Community area code
      %param           pi_ce_type_code                      Consumption entity type code
      %param           pi_ce_area_code                      Consumption entity area code
      %param           pi_plan_category_id                  Plan category identifier
      %param           pi_plan_category_code                Plan category code
      %param           pi_entity_plan_id                    Entity plan identifier
      %param           pi_plan_code                         Plan code
      %param           pi_entity_component_id               Entity component id
      %param           pi_component_code                    Component code
      %param           pi_add_data1                         Additional data1
      %param           pi_add_data2                         Additional data2
      %param           pi_add_data3                         Additional data3
      %param           pi_add_data4                         Additional data4
      %param           pi_add_data5                         Additional data5
      %param           pi_entity_ageing                     Entity ageing
      %param           pi_billing_community_id              Billing community identifier
      %param           pi_activated_date                    Activated date
      %param           pi_activated_tran_code               Activated transaction code
      %param           pi_deactivated_date                  Deactivated date
      %param           pi_deactivated_tran_code             Deactivated transaction code
      %param           pi_is_postpaid                       Is postpaid
      %param           pi_tran_id                           Transaction identifier
      %param           pi_tran_date                         Transaction date
      %param           pi_user_code                         User code
      %param           po_err_code                          Output showing one of the next results:
                                                            {*} OK - If procedure executed satisfactorily
                                                            {*} XXX-#### - Error code if any error found
      %param           po_err_msg                           Output showing the error message if any error found
      %raises          ERR_APP                              Application level error
  %Changes
      <hr>
        {*}Date       26/09/2013 11:00:00
        {*}Control    160121 
        {*}Author     "Abel Soto Vera"
        {*}Note       Billing - Multi operator custom (Change Management)
  */
  PROCEDURE PROCESS_GENERIC_FREE( pi_component_element_id       IN  CRU.TR_ENTITY_CREDIT_UNIT.component_element_id%TYPE ,
                                  pi_telco_code                 IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE           ,
                                  pi_entity_type_code           IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_type_code%TYPE     ,
                                  pi_entity_id                  IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_id%TYPE            ,
                                  pi_client_id                  IN  NUMBER                                              ,
                                  pi_community_id               IN  NUMBER                                              ,
                                  pi_cen_id                     IN  NUMBER                                              ,
                                  pi_bill_element_code          IN  CRU.TR_ENTITY_CREDIT_UNIT.credit_unit_code%TYPE     ,
                                  pi_bill_element_type_code     IN  VARCHAR2                                            ,
                                  pi_component_currency         IN  VARCHAR2                                            ,
                                  pi_component_amount           IN  NUMBER                                              ,
                                  pi_component_quantity         IN  NUMBER                                              ,
                                  pi_component_quotes           IN  NUMBER                                              ,
                                  pi_client_type_code           IN  VARCHAR2                                            ,
                                  pi_client_segment_code        IN  VARCHAR2                                            ,
                                  pi_community_area_code        IN  VARCHAR2                                            ,
                                  pi_ce_type_code               IN  VARCHAR2                                            ,
                                  pi_ce_area_code               IN  VARCHAR2                                            ,
                                  pi_plan_category_id           IN  NUMBER                                              ,
                                  pi_plan_category_code         IN  VARCHAR2                                            ,
                                  pi_entity_plan_id             IN  NUMBER                                              ,
                                  pi_plan_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.plan_code%TYPE            ,
                                  pi_entity_component_id        IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE  ,
                                  pi_component_code             IN  CRU.TR_ENTITY_CREDIT_UNIT.component_code%TYPE       ,
                                  pi_add_data1                  IN  VARCHAR2                                            ,
                                  pi_add_data2                  IN  VARCHAR2                                            ,
                                  pi_add_data3                  IN  VARCHAR2                                            ,
                                  pi_add_data4                  IN  VARCHAR2                                            ,
                                  pi_add_data5                  IN  VARCHAR2                                            ,
                                  pi_entity_ageing              IN  VARCHAR2                                            ,
                                  pi_billing_community_id       IN  NUMBER                                              ,
                                  pi_activated_date             IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_date%TYPE       ,
                                  pi_activated_tran_code        IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_tran_code%TYPE  ,
                                  pi_deactivated_date           IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_date%TYPE     ,
                                  pi_deactivated_tran_code      IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_tran_code%TYPE,
                                  pi_is_postpaid                IN  VARCHAR2                                            ,
                                  pi_tran_id                    IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_id%TYPE        ,
                                  pi_tran_date                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_date%TYPE      ,
                                  pi_user_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_user_code%TYPE      ,
                                  po_error_code                 OUT VARCHAR2                                            ,
                                  po_error_msg                  OUT VARCHAR2                                            )
  IS
     -- Mandatory variables for security and logs
     v_package_procedure VARCHAR2 (100) := v_package || '.PROCESS_GENERIC_FREE' ;
     v_param_in   VARCHAR2 (4000);
     -- Declare Exceptions
     ERR_APP EXCEPTION;
  BEGIN
    po_error_code := 'OK';
    po_error_msg := '';

    ---------------------------------------- DML Operations -----------------------------------

    CRU.BL_PROCESS.PROCESS_GENERIC_FREE( pi_telco_code            => pi_telco_code          ,
                                         pi_entity_type_code      => pi_entity_type_code    ,
                                         pi_entity_id             => pi_entity_id           ,
                                         pi_entity_component_id   => pi_entity_component_id ,
                                         pi_client_id             => pi_client_id           ,
                                         pi_community_id          => pi_community_id        ,
                                         pi_cen_id                => pi_cen_id              ,
                                         pi_client_type_code      => pi_client_type_code    ,
                                         pi_client_segment_code   => pi_client_segment_code ,
                                         pi_community_area_code   => pi_community_area_code ,
                                         pi_ce_type_code          => pi_ce_type_code        ,
                                         pi_ce_area_code          => pi_ce_area_code        ,
                                         pi_entity_ageing         => pi_entity_ageing       ,
                                         pi_plan_category_code    => pi_plan_category_code  ,
                                         pi_plan_category_id      => pi_plan_category_id    ,
                                         pi_plan_code             => pi_plan_code           ,
                                         pi_entity_plan_id        => pi_entity_plan_id      ,
                                         pi_component_code        => pi_component_code      ,
                                         pi_add_data1             => pi_add_data1           ,
                                         pi_add_data2             => pi_add_data2           ,
                                         pi_add_data3             => pi_add_data3           ,
                                         pi_add_data4             => pi_add_data4           ,
                                         pi_add_data5             => pi_add_data5           ,
                                         pi_activated_date        => pi_activated_date      ,
                                         pi_tran_id               => pi_tran_id             ,
                                         pi_tran_date             => pi_tran_date           ,
                                         po_error_code            => po_error_code          ,
                                         po_error_msg             => po_error_msg           );
    IF NVL (po_error_code, 'NOK') <> 'OK' THEN
       RAISE ERR_APP;
    END IF;
  --------------------------------------- End of DML Operations --------------------------------
  EXCEPTION
    WHEN ERR_APP THEN
      v_param_in :=       ---------- variable parameters ------------------
                  'pi_component_element_id:'        || pi_component_element_id    ||
                  '|pi_telco_code:'                 || pi_telco_code              ||
                  '|pi_entity_type_code:'           || pi_entity_type_code        ||
                  '|pi_entity_id:'                  || pi_entity_id               ||
                  '|pi_client_id:'                  || pi_client_id               ||
                  '|pi_community_id:'               || pi_community_id            ||
                  '|pi_cen_id:'                     || pi_cen_id                  ||
                  '|pi_bill_element_code:'          || pi_bill_element_code       ||
                  '|pi_bill_element_type_code:'     || pi_bill_element_type_code  ||
                  '|pi_component_currency:'         || pi_component_currency      ||
                  '|pi_component_amount:'           || pi_component_amount        ||
                  '|pi_component_quantity:'         || pi_component_quantity      ||
                  '|pi_component_quotes:'           || pi_component_quotes        ||
                  '|pi_client_type_code:'           || pi_client_type_code        ||
                  '|pi_client_segment_code:'        || pi_client_segment_code     ||
                  '|pi_community_area_code:'        || pi_community_area_code     ||
                  '|pi_ce_type_code:'               || pi_ce_type_code            ||
                  '|pi_ce_area_code:'               || pi_ce_area_code            ||
                  '|pi_plan_category_id:'           || pi_plan_category_id        ||
                  '|pi_plan_category_code:'         || pi_plan_category_code      ||
                  '|pi_entity_plan_id:'             || pi_entity_plan_id          ||
                  '|pi_plan_code:'                  || pi_plan_code               ||
                  '|pi_entity_component_id:'        || pi_entity_component_id     ||
                  '|pi_component_code:'             || pi_component_code          ||
                  '|pi_add_data1:'                  || pi_add_data1               ||
                  '|pi_add_data2:'                  || pi_add_data2               ||
                  '|pi_add_data3:'                  || pi_add_data3               ||
                  '|pi_add_data4:'                  || pi_add_data4               ||
                  '|pi_add_data5:'                  || pi_add_data5               ||
                  '|pi_entity_ageing:'              || pi_entity_ageing           ||
                  '|pi_billing_community_id:'       || pi_billing_community_id                            ||
                  '|pi_activated_date:'             || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                  '|pi_activated_tran_code:'        || pi_activated_tran_code                             ||
                  '|pi_deactivated_date:'           || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                  '|pi_deactivated_tran_code:'      || pi_activated_tran_code                             ||
                  '|pi_tran_id:'                    || pi_tran_id                                         ||
                  '|pi_tran_date:'                  || TO_CHAR (pi_tran_date,'DD/MM/YYYY HH24:MI:SS')     ||
                  '|pi_user_code:'                  || pi_user_code;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG ( pi_telco_code    => pi_telco_code   ,
                                       pi_tran_id       => pi_tran_id   ,
                                       pi_error_code    => po_error_code,
                                       pi_error_msg     => po_error_msg ,
                                       pi_error_source  => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));
    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg := SUBSTR (SQLERRM, 1, 1000);
      po_error_code := 'CRU-0340';        --Critical error.||Error critico.
      v_param_in :=       ---------- variable parameters ------------------
                  'pi_component_element_id:'        || pi_component_element_id    ||
                  '|pi_telco_code:'                 || pi_telco_code              ||
                  '|pi_entity_type_code:'           || pi_entity_type_code        ||
                  '|pi_entity_id:'                  || pi_entity_id               ||
                  '|pi_client_id:'                  || pi_client_id               ||
                  '|pi_community_id:'               || pi_community_id            ||
                  '|pi_cen_id:'                     || pi_cen_id                  ||
                  '|pi_bill_element_code:'          || pi_bill_element_code       ||
                  '|pi_bill_element_type_code:'     || pi_bill_element_type_code  ||
                  '|pi_component_currency:'         || pi_component_currency      ||
                  '|pi_component_amount:'           || pi_component_amount        ||
                  '|pi_component_quantity:'         || pi_component_quantity      ||
                  '|pi_component_quotes:'           || pi_component_quotes        ||
                  '|pi_client_type_code:'           || pi_client_type_code        ||
                  '|pi_client_segment_code:'        || pi_client_segment_code     ||
                  '|pi_community_area_code:'        || pi_community_area_code     ||
                  '|pi_ce_type_code:'               || pi_ce_type_code            ||
                  '|pi_ce_area_code:'               || pi_ce_area_code            ||
                  '|pi_plan_category_id:'           || pi_plan_category_id        ||
                  '|pi_plan_category_code:'         || pi_plan_category_code      ||
                  '|pi_entity_plan_id:'             || pi_entity_plan_id          ||
                  '|pi_plan_code:'                  || pi_plan_code               ||
                  '|pi_entity_component_id:'        || pi_entity_component_id     ||
                  '|pi_component_code:'             || pi_component_code          ||
                  '|pi_add_data1:'                  || pi_add_data1               ||
                  '|pi_add_data2:'                  || pi_add_data2               ||
                  '|pi_add_data3:'                  || pi_add_data3               ||
                  '|pi_add_data4:'                  || pi_add_data4               ||
                  '|pi_add_data5:'                  || pi_add_data5               ||
                  '|pi_entity_ageing:'              || pi_entity_ageing           ||
                  '|pi_billing_community_id:'       || pi_billing_community_id                            ||
                  '|pi_activated_date:'             || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                  '|pi_activated_tran_code:'        || pi_activated_tran_code                             ||
                  '|pi_deactivated_date:'           || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                  '|pi_deactivated_tran_code:'      || pi_activated_tran_code                             ||
                  '|pi_tran_id:'                    || pi_tran_id                                         ||
                  '|pi_tran_date:'                  || TO_CHAR (pi_tran_date,'DD/MM/YYYY HH24:MI:SS')     ||
                  '|pi_user_code:'                  || pi_user_code;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG ( pi_telco_code   => pi_telco_code,
                                       pi_tran_id      => pi_tran_id   ,
                                       pi_error_code   => po_error_code,
                                       pi_error_msg    => po_error_msg ,
                                       pi_error_source => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));
  END;


   /*
     Change credit limit a record for table TR_ENTITY_CREDIT_UNIT receiving all columns as parameters
    %Date            05/08/2011 11:29:17
    %Control         60083
    %Author          "Abel Soto"
    %Version         1.0.0
        %parama          pi_entity_component_id        Entity component identifier
        %param           pi_telco_code                 Code of operation
        %param           pi_credit_limit_code          Credit Unit code
        %param           pi_credit_limit_amount        Credit limit amount
        %param           pi_date                       Date request
        %param           pi_activated_tran_code        Activated transaction code
        %param           pi_tran_id                    Transaction identifier
        %param           pi_tran_date                  Transaction date
        %param           pi_user_code                  User code
        %param           po_rec_entity_status_id       Output ID the table
        %param           po_err_code                   Output showing one of the next results:
                                                       {*} OK - If procedure executed satisfactorily
                                                       {*} XXX-#### - Error code if any error found
        %param           po_err_msg                    Output showing the error message if any error found
        %raises          ERR_APP                       Application level error
      %Changes
      <hr>
        {*}Date       18/05/2012 17:27:30
        {*}Control    299
        {*}Author     "Abel Soto Vera"
        {*}Note       Was removed fields Credit_limit_amount, credit_limit_currency_code and all functionality with these fields
      <hr>
        {*}Date       30/05/2012 11:27:30
        {*}Control    299
        {*}Author     "Abel Soto Vera"
        {*}Note       Change in the logic of the process of credit limit

    */

  PROCEDURE CHANGE_CREDIT_LIMIT( pi_entity_component_id IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE,
                                 pi_telco_code          IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE         ,
                                 --<ASV Control:299 Date:30/05/2012 11:27:30 Change in the logic of the process of credit limit>
                                 pi_credit_limit_code   IN  CRU.TR_ENTITY_CREDIT_UNIT.credit_unit_code%TYPE   ,
                                 --<ASV Control:299 Date:30/05/2012 11:27:30>
                                 pi_credit_limit_amount IN  CRU.TR_ENTITY_CREDIT_UNIT.COMPONENT_AMOUNT%TYPE   ,
                                 pi_date                IN  CRU.TR_ENTITY_CREDIT_UNIT.end_date%TYPE           ,
                                 pi_activated_tran_code IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_tran_code%TYPE,
                                 pi_tran_id             IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_id%TYPE      ,
                                 pi_tran_date           IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_date%TYPE    ,
                                 pi_user_code           IN  CRU.TR_ENTITY_CREDIT_UNIT.start_user_code%TYPE    ,
                                 po_error_code          OUT VARCHAR2                                          ,
                                 po_error_msg           OUT VARCHAR2                                          ) IS
  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2 (100) := v_package || '.CHANGE_CREDIT_LIMIT' ;
    v_param_in          VARCHAR2 (4000);
    ERR_APP EXCEPTION;
  BEGIN
    po_error_code := 'OK';
    po_error_msg  := '';

    CRU.TX_REGISTER_ENTITY.MODIFY_CREDIT_LIMIT( pi_entity_component_id => pi_entity_component_id,
                                                pi_telco_code          => pi_telco_code         ,
                                                --<ASV Control:299 Date:30/05/2012 11:27:30 Change in the logic of the process of credit limit>
                                                pi_credit_limit_code   => pi_credit_limit_code  ,
                                                --<ASV Control:299 Date:30/05/2012 11:27:30>
                                                pi_credit_limit_amount => pi_credit_limit_amount,
                                                pi_date                => pi_date               ,
                                                pi_activated_tran_code => pi_activated_tran_code,
                                                pi_tran_id             => pi_tran_id            ,
                                                pi_tran_date           => pi_tran_date          ,
                                                pi_user_code           => pi_user_code          ,
                                                po_error_code          => po_error_code         ,
                                                po_error_msg           => po_error_msg          );
    IF NVL (po_error_code, 'NOK') <> 'OK' THEN
       RAISE ERR_APP;
    END IF;

  EXCEPTION
    WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in  :=       ---------- variable parameters ------------------
                   'pi_entity_component_id:' || pi_entity_component_id                         ||
                   '|pi_telco_code:'         || pi_telco_code                                  ||
                   '|pi_credit_limit_code:'  || pi_credit_limit_code                           ||
                   '|pi_credit_limit_amount:'|| pi_credit_limit_amount                         ||
                   '|pi_date:'               || TO_CHAR (pi_date, 'DD/MM/YYYY HH24:MI:SS')     ||
                   '|pi_activated_tran_code:'|| pi_activated_tran_code                         ||
                   '|pi_tran_id:'            || pi_tran_id                                     ||
                   '|pi_tran_date:'          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')||
                   '|pi_user_code:'          || pi_user_code;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id,
                                      pi_error_code   => po_error_code ,
                                      pi_error_msg    => po_error_msg  ,
                                      pi_error_source => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000) );

    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg  := SUBSTR (SQLERRM, 1, 1000);
      po_error_code := 'CRU-0341';        --Critical error.||Error critico.
      v_param_in    :=       ---------- variable parameters ------------------
                     'pi_entity_component_id:' || pi_entity_component_id                         ||
                     '|pi_telco_code:'         || pi_telco_code                           ||
                     '|pi_credit_limit_code:'  || pi_credit_limit_code                           ||
                     '|pi_credit_limit_amount:'|| pi_credit_limit_amount                         ||
                     '|pi_date:'               || TO_CHAR (pi_date, 'DD/MM/YYYY HH24:MI:SS')     ||
                     '|pi_activated_tran_code:'|| pi_activated_tran_code                         ||
                     '|pi_tran_id:'            || pi_tran_id                                     ||
                     '|pi_tran_date:'          || TO_CHAR (pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')||
                     '|pi_user_code:'          || pi_user_code;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id,
                                      pi_error_code   => po_error_code ,
                                      pi_error_msg    => po_error_msg  ,
                                      pi_error_source => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000) );


  END;


    /*
  Gets the message configured for a credit unit
  %Date          30/06/2011 17:00:00
  %Control       20338
  %Author        "Lizeth Flores"
  %Version       1.0.0
      %param         pi_credit_unit_code          Credit unit code
      %param         pi_telco_code                Code of operation
      %param         pi_language_code             Language code
      %param         pi_entity_type_code          Entity type code
      %param         pi_entity_id                 Entity Identifier (Client ID, Community ID or consumption entity ID)
      %param         pi_message_type_code         Message type code
      %param         pi_quantity                  Quantity
      %param         pi_date                      Date request
      %param         pi_tran_id                   Tran identifier
      %param         po_message                   Return message
      %param         po_error_code                Output showing one of the next results:
                                                  {*} OK - If procedure executed satisfactorily
                                                  {*} XXX-#### - Error code if any error found
      %param         po_error_msg                 Output showing the error message if any error found
      %raises        ERR_APP                      Application level error
  
  %Changes
      <hr>
        {*}Date       24/02/2012 19:00:00
        {*}Control    293.1446
        {*}Author     "Lizeth Flores"
        {*}Note       Changing number parameter input of get_cru_message for comments MTR.
      <hr>
        {*}Date       24/04/2013 19:00:00
        {*}Control    335
        {*}Author     "Rosio Eguivar"
        {*}Note       Increases the logic for managing messages either by ranges.         
  */

  PROCEDURE GET_CRU_MESSAGE ( pi_credit_unit_code  IN  CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE         ,
                              pi_telco_code        IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE               ,
                              pi_language_code     IN  CRU.CF_CRU_MESSAGE.language_code%TYPE            ,
                              pi_entity_type_code  IN  CRU.TR_ENTITY_LOG.entity_type_code%TYPE          ,
                              pi_entity_id         IN  CRU.TR_ENTITY_LOG.entity_id%TYPE                 ,
                              -- <LFR 24/02/2012 19:00:00 CONTROL:293.1446 Modify comments MTR.
                              pi_message_type_code IN  CRU.CF_CRU_CONFIG_MESSAGE.message_type_code%TYPE ,  -- <REE 24/04/2013 19:00:00 CONTROL:335 Increases the logic for managing messages either by ranges.
                              pi_quantity          IN  cru.tr_entity_log.quantity%TYPE                  ,
                              pi_date              IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE          ,
                              pi_tran_id           IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE            ,
                              po_message           OUT CRU.CF_CRU_MESSAGE.message%TYPE                  ,
                              po_error_code        OUT VARCHAR2                                         ,
                              po_error_msg         OUT VARCHAR2                                         ) IS

  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.GET_CRU_MESSAGE';
    v_param_in          VARCHAR2(4000);
  --constant

  -- Declare Exception
  ERR_APP EXCEPTION;

  BEGIN

    po_error_code := 'OK';
    po_error_msg  := ''  ;

    IF pi_credit_unit_code  IS NULL OR
       pi_telco_code        IS NULL OR
       pi_language_code     IS NULL OR
       pi_message_type_code IS NULL OR -- <LFR 24/02/2012 19:00:00 CONTROL:293.1446 Modify comments MTR.
       pi_quantity          IS NULL OR
       pi_date              IS NULL OR
       pi_tran_id           IS NULL THEN
       po_error_code := 'CRU-0342';-- Mandatory parameters are null. || Parámetros obligatorios son nulos.
       RAISE ERR_APP;
    END IF;

    ------------------------------ Bussiness Logic ----------------------------

      po_error_code     := 'OK';
      po_error_msg      := '';

      CRU.BL_UTILITIES.GET_CRU_MESSAGE ( pi_telco_code        => pi_telco_code       ,
                                         pi_credit_unit_code  => pi_credit_unit_code ,
                                         pi_language_code     => pi_language_code    ,
                                         -- <LFR 24/02/2012 19:00:00 CONTROL:293.1446 Modify comments MTR. >
                                         pi_entity_type_code  => pi_entity_type_code , 
                                         pi_entity_id         => pi_entity_id        ,
                                         pi_message_type_code => pi_message_type_code, 
                                         -- <LFR 24/02/2012 19:00:00 CONTROL:293.1446 >
                                         pi_quantity          => pi_quantity         ,
                                         pi_date              => pi_date             ,
                                         pi_tran_id           => pi_tran_id          ,
                                         po_message           => po_message          ,
                                         po_error_code        => po_error_code       ,
                                         po_error_msg         => po_error_msg        );

       IF NVL(po_error_code,'NOK') <> 'OK' THEN
         RAISE ERR_APP;
       END IF;

  EXCEPTION
    WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in :=---- variable parameters ----
                   'pi_credit_unit_code:'  || pi_credit_unit_code                       || 
                   '|pi_telco_code:'       || pi_telco_code                             ||
                   '|pi_language_code:'     || pi_language_code                          ||
                   '|pi_entity_type_code:'  || pi_entity_type_code                       ||
                   '|pi_entity_id:'         || pi_entity_id                              ||
                   '|pi_message_type_code:' || pi_message_type_code                      ||
                   '|pi_quantity:'          || pi_quantity                               ||
                   '|pi_date:'              || TO_CHAR(pi_date, 'DD/MM/YYYY HH24:MI:SS') ||
                   '|pi_tran_id:'           || pi_tran_id                                        ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code    => pi_telco_code                                                       ,
                                      pi_tran_id       => pi_tran_id                                                       ,
                                      pi_error_code    => po_error_code                                                    ,
                                      pi_error_msg     => po_error_msg                                                     ,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));
    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code := 'CRU-0343';--Critical error.||Error critico.
      v_param_in    :=--- variable parameters ----
                       'pi_credit_unit_code:'  || pi_credit_unit_code                       || 
                       '|pi_telco_code:'       || pi_telco_code                             ||
                       '|pi_language_code:'     || pi_language_code                          ||
                       '|pi_entity_type_code:'  || pi_entity_type_code                       ||
                       '|pi_entity_id:'         || pi_entity_id                              ||
                       '|pi_message_type_code:' || pi_message_type_code                      ||
                       '|pi_quantity:'          || pi_quantity                               ||
                       '|pi_date:'              || TO_CHAR(pi_date, 'DD/MM/YYYY HH24:MI:SS') ||
                       '|pi_tran_id:'           || pi_tran_id                                        ;


      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code    => pi_telco_code                                                       ,
                                      pi_tran_id       => pi_tran_id                                                       ,
                                      pi_error_code    => po_error_code                                                    ,
                                      pi_error_msg     => po_error_msg                                                     ,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));
  END;

    /*
  TRUNCATE change status (I)a record for table TR_ENTITY_LOG receiving all columns as parameters
  %Date          30/06/2011 17:00:00
  %Control       20338
  %Author        "Lizeth Flores"
  %Version       1.0.0
      %param         pi_credit_unit_code          Credit unit code
      %param         pi_telco_code                Code of operation
      %param         pi_language_code             Language code
      %param         pi_quantity                  Quantity
      %param         pi_date                      Date request
      %param         pi_tran_id                   Tran identifier
      %param         po_message                   Return message
      %param         po_error_code                Output showing one of the next results:
                                                  {*} OK - If procedure executed satisfactorily
                                                  {*} XXX-#### - Error code if any error found
      %param         po_error_msg                 Output showing the error message if any error found
      %raises        ERR_APP                      Application level error
  */

  PROCEDURE CHANGE_STATUS_CRU( pi_process_id    IN  CRU.TR_ENTITY_LOG.start_tran_id%TYPE,
                               pi_telco_code    IN  CRU.TR_ENTITY_LOG.telco_code%TYPE   ,
                               pi_tran_id       IN  CRU.TR_ENTITY_LOG.end_tran_id%TYPE  ,
                               pi_tran_date     IN  CRU.TR_ENTITY_LOG.end_tran_date%TYPE,
                               po_error_code    OUT VARCHAR2                            ,
                               po_error_msg     OUT VARCHAR2                            ) IS

  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.CHANGE_STATUS_CRU';
    v_param_in          VARCHAR2(4000);
  --constant

  -- Declare Exception
  ERR_APP EXCEPTION;

  BEGIN

    po_error_code := 'OK';
    po_error_msg  := ''  ;

    IF pi_process_id IS NULL OR
       pi_telco_code IS NULL OR
       pi_tran_id    IS NULL OR
       pi_tran_date  IS NULL  THEN
      po_error_code := 'CRU-0444';--Mandatory parameter is Null.||Parametro obligatorio es Nulo.
      RAISE ERR_APP;
    END IF;

    ------------------------------ Bussiness Logic ----------------------------

      CRU.TX_TR_ENTITY_LOG.CHANGE_STATUS_CRU(pi_process_id => pi_process_id,
                                             pi_telco_code => pi_telco_code,
                                             pi_tran_id    => pi_tran_id   ,
                                             pi_tran_date  => pi_tran_date ,
                                             po_error_code => po_error_code,
                                             po_error_msg  => po_error_msg);

       IF NVL(po_error_code,'NOK') <> 'OK' THEN
         RAISE ERR_APP;
       END IF;

  EXCEPTION
    WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in :=---------- variable parameters ------------------
                   'pi_process_id: ' || pi_process_id                                   || 
                   '|pi_telco_code: ' || pi_telco_code                                   || 
                   '|pi_tran_id: '    || pi_tran_id                                      ||
                   '|pi_tran_date: '  || TO_CHAR( pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')         ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code    => pi_telco_code                                                       ,
                                      pi_tran_id       => pi_tran_id                                                       ,
                                      pi_error_code    => po_error_code                                                    ,
                                      pi_error_msg     => po_error_msg                                                     ,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));
    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code := 'CRU-0445';--Critical error.||Error critico.
      v_param_in :=---------- variable parameters ------------------
                   'pi_process_id: ' || pi_process_id                                   || 
                   '|pi_telco_code: ' || pi_telco_code                                   || 
                   '|pi_tran_id: '    || pi_tran_id                                      ||
                   '|pi_tran_date: '  || TO_CHAR( pi_tran_date, 'DD/MM/YYYY HH24:MI:SS')         ;


      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code    => pi_telco_code                                                    ,
                                      pi_tran_id       => pi_tran_id                                                       ,
                                      pi_error_code    => po_error_code                                                    ,
                                      pi_error_msg     => po_error_msg                                                     ,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));
  END;

  /*
  GET_DESCRIPTION_ELEMENT.
  %Date           23/09/2011 11:49:00
  %Control        20281
  %Author         "Lizeth Flores"
  %Version        1.0.0
      %param          pi_element_code              Code associated with the element.
      %param          pi_date                      Evaluate Date.
      %param          pi_language_code             Language Code
      %return The function returns the date on which the component is no longer active

  */
  FUNCTION GET_DESCRIPTION_ELEMENT( pi_telco_code    IN CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE   ,
                                    pi_element_code  IN CRU.CF_CRU_DESCRIPTION.credit_unit_code%TYPE,
                                    pi_date          IN CRU.CF_CRU_DESCRIPTION.start_date%TYPE      ,
                                    pi_language_code IN CRU.CF_CRU_DESCRIPTION.language_code%TYPE   )RETURN VARCHAR2 IS


  v_description       CRU.CF_CRU_DESCRIPTION.description%TYPE;

  BEGIN
    v_description := CRU.BL_UTILITIES.GET_DESCRIPTION_ELEMENT( pi_telco_code   => pi_telco_code     ,
                                                               pi_element_code   => pi_element_code ,
                                                               pi_date           => pi_date         ,
                                                               pi_language_code  => pi_language_code);
    RETURN v_description;
  END;


  
   /*
   COMPONENT CREDIT UNIT CONSULTING for pre-paid or post-paid
  %Date            29/02/2010 11:29:17
  %Control         293
  %Author          "Abel Soto"
  %Version         1.0.0
      %parama          pi_component_element_id          Component element identifier
      %param           pi_telco_code                    Code of operation
      %param           pi_entity_type_code              Entity type code
      %param           pi_entity_id                     Entity identifier
      %param           pi_client_id                     Client identifier
      %param           pi_community_id                  Community identifier
      %param           pi_cen_id                        Consumption entity identifier
      %param           pi_bill_element_code             Billing element code
      %param           pi_bill_element_type_code        Billing element type code
      %param           pi_component_currency            Component currency
      %param           pi_component_amount              Component amount
      %param           pi_component_quantity            Component quantity
      %param           pi_component_quotes              Component quotes
      %param           pi_client_type_code              Client type code
      %param           pi_client_segment_code           Client segment code
      %param           pi_community_area_code           Community area code
      %param           pi_ce_type_code                  Consumption entity type code
      %param           pi_ce_area_code                  Consumption entity area code
      %param           pi_plan_category_id              Plan category identifier
      %param           pi_plan_category_code            Plan category code
      %param           pi_entity_plan_id                Entity plan identifier
      %param           pi_plan_code                     Plan code
      %param           pi_entity_component_id           Entity component identifier
      %param           pi_component_code                Component code
      %param           pi_add_data1                     Additional data1
      %param           pi_add_data2                     Additional data2
      %param           pi_add_data3                     Additional data3
      %param           pi_add_data4                     Additional data4
      %param           pi_add_data5                     Additional data5
      %param           pi_entity_ageing                 Entity ageing
      %param           pi_billing_community_id          Billing community identifier
      %param           pi_activated_date                Activated date
      %param           pi_activated_tran_code           Activated transaction code
      %param           pi_deactivated_date              Deactivated date
      %param           pi_deactivated_tran_code         Deactivated transaction code
      %param           pi_tran_id                       Transaction identifier
      %param           pi_tran_date                     Transaction date
      %param           pi_user_code                     User code
      %param           po_err_code                      Output showing one of the next results:
                                                        {*} OK - If procedure executed satisfactorily
                                                        {*} XXX-#### - Error code if any error found
      %param           po_err_msg                       Output showing the error message if any error found
      %raises          ERR_APP                          Application level error
  */

  PROCEDURE CREDIT_UNIT_CONSULTING( pi_component_element_id       IN  CRU.TR_ENTITY_CREDIT_UNIT.component_element_id%TYPE ,
                                    pi_telco_code                 IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE           ,
                                    pi_entity_type_code           IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_type_code%TYPE     ,
                                    pi_entity_id                  IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_id%TYPE            ,
                                    pi_client_id                  IN  NUMBER                                              ,
                                    pi_community_id               IN  NUMBER                                              ,
                                    pi_cen_id                     IN  NUMBER                                              ,
                                    pi_bill_element_code          IN  CRU.TR_ENTITY_CREDIT_UNIT.credit_unit_code%TYPE     ,
                                    pi_bill_element_type_code     IN  VARCHAR2                                            ,
                                    pi_component_currency         IN  VARCHAR2                                            ,
                                    pi_component_amount           IN  NUMBER                                              ,
                                    pi_component_quantity         IN  NUMBER                                              ,
                                    pi_component_quotes           IN  NUMBER                                              ,
                                    pi_client_type_code           IN  VARCHAR2                                            ,
                                    pi_client_segment_code        IN  VARCHAR2                                            ,
                                    pi_community_area_code        IN  VARCHAR2                                            ,
                                    pi_ce_type_code               IN  VARCHAR2                                            ,
                                    pi_ce_area_code               IN  VARCHAR2                                            ,
                                    pi_plan_category_id           IN  NUMBER                                              ,
                                    pi_plan_category_code         IN  VARCHAR2                                            ,
                                    pi_entity_plan_id             IN  NUMBER                                              ,
                                    pi_plan_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.plan_code%TYPE            ,
                                    pi_entity_component_id        IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_component_id%TYPE  ,
                                    pi_component_code             IN  CRU.TR_ENTITY_CREDIT_UNIT.component_code%TYPE       ,
                                    pi_add_data1                  IN  VARCHAR2                                            ,
                                    pi_add_data2                  IN  VARCHAR2                                            ,
                                    pi_add_data3                  IN  VARCHAR2                                            ,
                                    pi_add_data4                  IN  VARCHAR2                                            ,
                                    pi_add_data5                  IN  VARCHAR2                                            ,
                                    pi_entity_ageing              IN  VARCHAR2                                            ,
                                    pi_billing_community_id       IN  NUMBER                                              ,
                                    pi_activated_date             IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_date%TYPE       ,
                                    pi_activated_tran_code        IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_tran_code%TYPE  ,
                                    pi_deactivated_date           IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_date%TYPE     ,
                                    pi_deactivated_tran_code      IN  CRU.TR_ENTITY_CREDIT_UNIT.deactivated_tran_code%TYPE,
                                    pi_tran_id                    IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_id%TYPE        ,
                                    pi_tran_date                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_tran_date%TYPE      ,
                                    pi_user_code                  IN  CRU.TR_ENTITY_CREDIT_UNIT.start_user_code%TYPE      ,
                                    po_error_code                 OUT VARCHAR2                                            ,
                                    po_error_msg                  OUT VARCHAR2                                            ) IS

     -- Mandatory variables for security and logs
     v_package_procedure VARCHAR2 (100) := v_package || '.CREDIT_UNIT_CONSULTING' ;
     v_param_in   VARCHAR2 (4000);
     -- Declare Exceptions
     ERR_APP EXCEPTION;
   BEGIN
     po_error_code := 'OK';
     po_error_msg := '';

     ---------------------------------------- DML Operations -----------------------------------

     CRU.TX_REGISTER_ENTITY.CREDIT_UNIT_CONSULTING( pi_component_element_id       => pi_component_element_id      ,
                                                    pi_telco_code                 => pi_telco_code                ,
                                                    pi_entity_type_code           => pi_entity_type_code          ,
                                                    pi_entity_id                  => pi_entity_id                 ,
                                                    pi_client_id                  => pi_client_id                 ,
                                                    pi_community_id               => pi_community_id              ,
                                                    pi_cen_id                     => pi_cen_id                    ,
                                                    pi_bill_element_code          => pi_bill_element_code         ,
                                                    pi_bill_element_type_code     => pi_bill_element_type_code    ,
                                                    pi_component_currency         => pi_component_currency        ,
                                                    pi_component_amount           => pi_component_amount          ,
                                                    pi_component_quantity         => pi_component_quantity        ,
                                                    pi_component_quotes           => pi_component_quotes          ,
                                                    pi_client_type_code           => pi_client_type_code          ,
                                                    pi_client_segment_code        => pi_client_segment_code       ,
                                                    pi_community_area_code        => pi_community_area_code       ,
                                                    pi_ce_type_code               => pi_ce_type_code              ,
                                                    pi_ce_area_code               => pi_ce_area_code              ,
                                                    pi_plan_category_id           => pi_plan_category_id          ,
                                                    pi_plan_category_code         => pi_plan_category_code        ,
                                                    pi_entity_plan_id             => pi_entity_plan_id            ,
                                                    pi_plan_code                  => pi_plan_code                 ,
                                                    pi_entity_component_id        => pi_entity_component_id       ,
                                                    pi_component_code             => pi_component_code            ,
                                                    pi_add_data1                  => pi_add_data1                 ,
                                                    pi_add_data2                  => pi_add_data2                 ,
                                                    pi_add_data3                  => pi_add_data3                 ,
                                                    pi_add_data4                  => pi_add_data4                 ,
                                                    pi_add_data5                  => pi_add_data5                 ,
                                                    pi_entity_ageing              => pi_entity_ageing             ,
                                                    pi_billing_community_id       => pi_billing_community_id      ,
                                                    pi_activated_date             => pi_activated_date            ,
                                                    pi_activated_tran_code        => pi_activated_tran_code       ,
                                                    pi_deactivated_date           => pi_deactivated_date          ,
                                                    pi_deactivated_tran_code      => pi_deactivated_tran_code     ,
                                                    pi_tran_id                    => pi_tran_id                   ,
                                                    pi_tran_date                  => pi_tran_date                 ,
                                                    pi_user_code                  => pi_user_code                 ,
                                                    po_error_code                 => po_error_code                ,
                                                    po_error_msg                  => po_error_msg                 );

     IF NVL (po_error_code, 'NOK') <> 'OK' THEN
        RAISE ERR_APP;
     END IF;
   --------------------------------------- End of DML Operations --------------------------------
   EXCEPTION
      WHEN ERR_APP THEN
         v_param_in :=       ---------- variable parameters ------------------
                     'pi_component_element_id:'        || pi_component_element_id    ||
                     '|pi_telco_code:'                 || pi_telco_code              ||
                     '|pi_entity_type_code:'           || pi_entity_type_code        ||
                     '|pi_entity_id:'                  || pi_entity_id               ||
                     '|pi_client_id:'                  || pi_client_id               ||
                     '|pi_community_id:'               || pi_community_id            ||
                     '|pi_cen_id:'                     || pi_cen_id                  ||
                     '|pi_bill_element_code:'          || pi_bill_element_code       ||
                     '|pi_bill_element_type_code:'     || pi_bill_element_type_code  ||
                     '|pi_component_currency:'         || pi_component_currency      ||
                     '|pi_component_amount:'           || pi_component_amount        ||
                     '|pi_component_quantity:'         || pi_component_quantity      ||
                     '|pi_component_quotes:'           || pi_component_quotes        ||
                     '|pi_client_type_code:'           || pi_client_type_code        ||
                     '|pi_client_segment_code:'        || pi_client_segment_code     ||
                     '|pi_community_area_code:'        || pi_community_area_code     ||
                     '|pi_ce_type_code:'               || pi_ce_type_code            ||
                     '|pi_ce_area_code:'               || pi_ce_area_code            ||
                     '|pi_plan_category_id:'           || pi_plan_category_id        ||
                     '|pi_plan_category_code:'         || pi_plan_category_code      ||
                     '|pi_entity_plan_id:'             || pi_entity_plan_id          ||
                     '|pi_plan_code:'                  || pi_plan_code               ||
                     '|pi_entity_component_id:'        || pi_entity_component_id     ||
                     '|pi_component_code:'             || pi_component_code          ||
                     '|pi_add_data1:'                  || pi_add_data1               ||
                     '|pi_add_data2:'                  || pi_add_data2               ||
                     '|pi_add_data3:'                  || pi_add_data3               ||
                     '|pi_add_data4:'                  || pi_add_data4               ||
                     '|pi_add_data5:'                  || pi_add_data5               ||
                     '|pi_entity_ageing:'              || pi_entity_ageing           ||
                     '|pi_billing_community_id:'       || pi_billing_community_id                            ||
                     '|pi_activated_date:'             || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                     '|pi_activated_tran_code:'        || pi_activated_tran_code                             ||
                     '|pi_deactivated_date:'           || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                     '|pi_deactivated_tran_code:'      || pi_activated_tran_code                             ||
                     '|pi_tran_id:'                    || pi_tran_id                                         ||
                     '|pi_tran_date:'                  || TO_CHAR (pi_tran_date,'DD/MM/YYYY HH24:MI:SS')     ||
                     '|pi_user_code:'                  || pi_user_code;

         CRU.TX_TR_ERROR_LOG.RECORD_LOG ( pi_telco_code    => pi_telco_code   ,
                                          pi_tran_id       => pi_tran_id   ,
                                          pi_error_code    => po_error_code,
                                          pi_error_msg     => po_error_msg ,
                                          pi_error_source  => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));
      WHEN OTHERS THEN
         -- Initiate log variables
         po_error_msg := SUBSTR (SQLERRM, 1, 1000);
         po_error_code := 'CRU-0469';        --Critical error.||Error critico.
         v_param_in :=       ---------- variable parameters ------------------
                     'pi_component_element_id:'        || pi_component_element_id    ||
                     '|pi_telco_code:'                 || pi_telco_code              ||
                     '|pi_entity_type_code:'           || pi_entity_type_code        ||
                     '|pi_entity_id:'                  || pi_entity_id               ||
                     '|pi_client_id:'                  || pi_client_id               ||
                     '|pi_community_id:'               || pi_community_id            ||
                     '|pi_cen_id:'                     || pi_cen_id                  ||
                     '|pi_bill_element_code:'          || pi_bill_element_code       ||
                     '|pi_bill_element_type_code:'     || pi_bill_element_type_code  ||
                     '|pi_component_currency:'         || pi_component_currency      ||
                     '|pi_component_amount:'           || pi_component_amount        ||
                     '|pi_component_quantity:'         || pi_component_quantity      ||
                     '|pi_component_quotes:'           || pi_component_quotes        ||
                     '|pi_client_type_code:'           || pi_client_type_code        ||
                     '|pi_client_segment_code:'        || pi_client_segment_code     ||
                     '|pi_community_area_code:'        || pi_community_area_code     ||
                     '|pi_ce_type_code:'               || pi_ce_type_code            ||
                     '|pi_ce_area_code:'               || pi_ce_area_code            ||
                     '|pi_plan_category_id:'           || pi_plan_category_id        ||
                     '|pi_plan_category_code:'         || pi_plan_category_code      ||
                     '|pi_entity_plan_id:'             || pi_entity_plan_id          ||
                     '|pi_plan_code:'                  || pi_plan_code               ||
                     '|pi_entity_component_id:'        || pi_entity_component_id     ||
                     '|pi_component_code:'             || pi_component_code          ||
                     '|pi_add_data1:'                  || pi_add_data1               ||
                     '|pi_add_data2:'                  || pi_add_data2               ||
                     '|pi_add_data3:'                  || pi_add_data3               ||
                     '|pi_add_data4:'                  || pi_add_data4               ||
                     '|pi_add_data5:'                  || pi_add_data5               ||
                     '|pi_entity_ageing:'              || pi_entity_ageing           ||
                     '|pi_billing_community_id:'       || pi_billing_community_id                            ||
                     '|pi_activated_date:'             || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                     '|pi_activated_tran_code:'        || pi_activated_tran_code                             ||
                     '|pi_deactivated_date:'           || TO_CHAR (pi_activated_date,'DD/MM/YYYY HH24:MI:SS')||
                     '|pi_deactivated_tran_code:'      || pi_activated_tran_code                             ||
                     '|pi_tran_id:'                    || pi_tran_id                                         ||
                     '|pi_tran_date:'                  || TO_CHAR (pi_tran_date,'DD/MM/YYYY HH24:MI:SS')     ||
                     '|pi_user_code:'                  || pi_user_code;

         CRU.TX_TR_ERROR_LOG.RECORD_LOG ( pi_telco_code   => pi_telco_code,
                                          pi_tran_id      => pi_tran_id   ,
                                          pi_error_code   => po_error_code,
                                          pi_error_msg    => po_error_msg ,
                                          pi_error_source => SUBSTR (v_package_procedure|| '('|| v_param_in|| ')',1,4000));
   END;

   /*
  Validates that the record exists in TR_INTEGRATION_LOG
  %Date           11/06/2011 13:32:00 p.m.
  %Control        20281
  %Author         "Abel Soto Vera"
  %Version        1.0.0
      %param         pi_bill_tran_id            Unique identifier table TR_INTEGRATION_LOG
      %param         pi_telco_code              Code of operation
      %param         pi_entity_type_code        Entity type code
      %param         pi_entity_id               Entity identifier
      %param         pi_tran_id                 Transaction identifier
      %param         po_resp                    Boolean value(0,1), verify if exist registry in TR_INTEGRATION _LOG
      %param         po_integration_id          Unique identifier
      %param         po_err_code                Output showing one of the next results:
                                                {*} OK - If procedure executed satisfactorily
                                                {*} XXX-#### - Error code if any error found
      %param         po_err_msg                 Output showing the error message if any error found
      %raises        ERR_APP                    Application level error
  */

  PROCEDURE CHECK_PROCESSING_RESPONSE( pi_bill_tran_id     IN  CRU.TR_ENTITY_LOG.start_tran_id%TYPE   ,
                                       pi_telco_code       IN  CRU.TR_ENTITY_LOG.telco_code%TYPE      ,
                                       pi_entity_type_code IN  CRU.TR_ENTITY_LOG.ENTITY_TYPE_CODE%TYPE,
                                       pi_entity_id        IN  CRU.TR_ENTITY_LOG.entity_id%TYPE       ,
                                       pi_tran_id          IN  CRU.TR_ENTITY_LOG.start_tran_id%TYPE   ,
                                       po_resp             OUT VARCHAR2                               ,
                                       po_error_code       OUT VARCHAR2                               ,
                                       po_error_msg        OUT VARCHAR2                               ) IS

  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.CHECK_PROCESSING_RESPONSE';
    v_param_in          VARCHAR2(4000)                                              ;

    ERR_APP EXCEPTION;
  BEGIN
    -- Initiate log variables
    po_error_code := 'OK';
    po_error_msg  := '';
    
    ------------------------------ DML Operations -------------------------
    CRU.TX_TR_ENTITY_LOG.CHECK_PROCESSING_RESPONSE( pi_bill_tran_id     => pi_bill_tran_id    ,
                                                    pi_telco_code       => pi_telco_code      ,
                                                    pi_entity_type_code => pi_entity_type_code,
                                                    pi_entity_id        => pi_entity_id       ,
                                                    pi_tran_id          => pi_tran_id         ,
                                                    po_resp             => po_resp            ,
                                                    po_error_code       => po_error_code      ,
                                                    po_error_msg        => po_error_msg       );
    ------------------------------ END DML Operations -------------------------
    IF NVL (po_error_code, 'NOK') <> 'OK' THEN
        RAISE ERR_APP;
     END IF;
  EXCEPTION
    WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in    :=---------- variable parameters ------------------
                      'pi_bill_tran_id: '      || pi_bill_tran_id     ||
                      '|pi_telco_code: '       || pi_telco_code       ||
                      '|pi_entity_type_code: ' || pi_entity_type_code ||
                      '|pi_entity_id: '        || pi_entity_id        ||
                      '|pi_tran_id: '          || pi_tran_id           ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code                                                      ,
                                      pi_tran_id      => pi_tran_id                                                      ,
                                      pi_error_code   => po_error_code                                                   ,
                                      pi_error_msg    => po_error_msg                                                    ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));

    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_code := 'CRU-0484';--Critical error.||Error critico.
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      v_param_in    :=---------- variable parameters ------------------
                      'pi_bill_tran_id: '      || pi_bill_tran_id     ||
                      '|pi_telco_code: '       || pi_telco_code       ||
                      '|pi_entity_type_code: ' || pi_entity_type_code ||
                      '|pi_entity_id: '        || pi_entity_id        ||
                      '|pi_tran_id: '          || pi_tran_id           ;
      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code                                                      ,
                                      pi_tran_id      => pi_tran_id                                                      ,
                                      pi_error_code   => po_error_code                                                   ,
                                      pi_error_msg    => po_error_msg                                                    ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));


  END CHECK_PROCESSING_RESPONSE;
                                    
   /*
  CHANGE ASYNCHRONOUS STATUS an record for table TR_ENTITY_LOG receiving all columns as parameters
  %Date           05/09/2012 11:30:00 a.m.
  %Control        299
  %Author         "Abel Soto Vera"
  %Version        1.0.0
      %param          pi_tran_id_process             Transaction start identifier, it identifies the transaction whose create the record
      %param          pi_telco_code                  Code of operation
      %param          pi_asynchronous_status         Asynchronous record status
      %param          pi_asynchronous_answer         Asynchronous answer
      %param          pi_asynchronous_date           Is the date whose asynchronous responce
      %param          pi_tran_id                     Transaction identifier
      %param          po_error_code                  Output showing one of the next results:
                                                     {*} OK - If procedure executed satisfactorily
                                                     {*} XXX-#### - Error code if any error found
      %param          po_error_msg                   Output showing the error message if any error found
      %raises         ERR_APP                        Application level error
  */

  PROCEDURE CHANGE_ASYNCHRONOUS_STATUS( pi_tran_id_process     IN  CRU.TR_ENTITY_LOG.end_tran_id%TYPE               ,
                                        pi_telco_code          IN  CRU.TR_ENTITY_LOG.telco_code%TYPE                ,
                                        pi_asynchronous_status IN  CRU.TR_ENTITY_LOG.asynchronous_status%TYPE       ,
                                        pi_asynchronous_answer IN  CRU.TR_ENTITY_LOG_STATUS.asynchronous_answer%TYPE,
                                        pi_asynchronous_date   IN  CRU.TR_ENTITY_LOG_STATUS.asynchronous_date%TYPE  ,
                                        pi_response_id         IN  CRU.TR_ENTITY_LOG_STATUS.response_id%TYPE        ,
                                        pi_tran_id             IN  CRU.TR_ENTITY_LOG.end_tran_id%TYPE               ,
                                        po_error_code          OUT VARCHAR2                                         ,
                                        po_error_msg           OUT VARCHAR2                                         ) IS

  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.CHANGE_ASYNCHRONOUS_STATUS';
    v_param_in          VARCHAR2(4000) ;

    ERR_APP EXCEPTION;
  BEGIN
    po_error_code := 'OK';
    po_error_msg := '';

    CRU.TX_TR_ENTITY_LOG.CHANGE_ASYNCHRONOUS_STATUS( pi_tran_id_process     => pi_tran_id_process    ,
                                                     pi_telco_code          => pi_telco_code         ,
                                                     pi_asynchronous_status => pi_asynchronous_status,
                                                     pi_asynchronous_answer => pi_asynchronous_answer,
                                                     pi_asynchronous_date   => pi_asynchronous_date  ,
                                                     pi_response_id         => pi_response_id        ,       
                                                     pi_tran_id             => pi_tran_id            ,
                                                     po_error_code          => po_error_code         ,
                                                     po_error_msg           => po_error_msg          );                                        
    IF NVL (po_error_code, 'NOK') <> 'OK' THEN
      RAISE ERR_APP;
    END IF;

  EXCEPTION   
    WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in    :=---------- variable parameters ------------------
                      'pi_tran_id_process: '      || pi_tran_id_process     ||
                      '|pi_telco_code: '          || pi_telco_code          ||
                      '|pi_asynchronous_status: ' || pi_asynchronous_status ||
                      '|pi_asynchronous_answer: ' || pi_asynchronous_answer ||
                      '|pi_asynchronous_date: '   || pi_asynchronous_date   ||
                      '|pi_response_id: '         || pi_response_id         ||
                      '|pi_tran_id: '             || pi_tran_id             ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id   ,
                                      pi_error_code   => po_error_code,
                                      pi_error_msg    => po_error_msg ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));

    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_code := 'CRU-0493';--Critical error.||Error critico.
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      v_param_in    :=---------- variable parameters ------------------
                      'pi_tran_id_process: '      || pi_tran_id_process     ||
                      '|pi_telco_code: '          || pi_telco_code          ||
                      '|pi_asynchronous_status: ' || pi_asynchronous_status ||
                      '|pi_asynchronous_answer: ' || pi_asynchronous_answer ||
                      '|pi_asynchronous_date: '   || pi_asynchronous_date   ||
                      '|pi_response_id: '         || pi_response_id         ||
                      '|pi_tran_id: '             || pi_tran_id             ;
      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id   ,
                                      pi_error_code   => po_error_code,
                                      pi_error_msg    => po_error_msg ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));


    
  END CHANGE_ASYNCHRONOUS_STATUS;


  /*
  The procedure KEY TARIFF MODIFICATION
  %Date            29/01/2013 18:29:17
  %Control         299
  %Author          "Abel Soto Vera"
  %Version         1.0.0
      %param           pi_telco_code                  Code of operation
      %param           pi_tariff_key_code             A unique identifier for a component.
      %param           pi_tariff_key_id               A unique identifier for a component.
      %param           pi_modification_date           A unique identifier for a component.
      %param           pi_modification_tran_code      A unique identifier for a component.
      %param           pi_tran_id                     Transaction identifier, identifies the transaction.
      %param           pi_tran_date                   Date of transaction.
      %param           pi_user_code                   User of the transaction.
      %param           po_error_code                  Output showing one of the next results:
                                                      {*} OK - If procedure executed satisfactorily
                                                      {*} XXX-#### - Error code if any error found
      %param           po_error_msg                   Output showing the error message if any error found
      %raises          ERR_APP                        Application level error
  */
  PROCEDURE KEY_TARIFF_MODIFICATION( pi_telco_code             IN  CRU.TR_ENTITY_CREDIT_UNIT.telco_code%TYPE         ,
                                     pi_tariff_key_code        IN  ITF.CF_DOMAIN.domain_code%TYPE                    ,
                                     pi_tariff_key_id          IN  CRU.TR_ENTITY_CREDIT_UNIT.entity_id%TYPE          ,
                                     pi_modification_date      IN  CRU.TR_ENTITY_CREDIT_UNIT.start_date%TYPE         ,
                                     pi_modification_tran_code IN  CRU.TR_ENTITY_CREDIT_UNIT.activated_tran_code%TYPE,
                                     pi_tran_id                IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_id%TYPE        ,
                                     pi_tran_date              IN  CRU.TR_ENTITY_CREDIT_UNIT.end_tran_date%TYPE      ,
                                     pi_user_code              IN  CRU.TR_ENTITY_CREDIT_UNIT.end_user_code%TYPE      ,
                                     po_error_code             OUT VARCHAR2                                          ,
                                     po_error_msg              OUT VARCHAR2                                          ) IS

    -- Mandatory variables for security and logs
    v_package_procedure   VARCHAR2 (100) := v_package || '.KEY_TARIFF_MODIFICATION';
    v_param_in            VARCHAR2 (4000);

    -- Declare Exceptions
    ERR_APP EXCEPTION;
  BEGIN
    po_error_code := 'OK';
    po_error_msg := '';
    --LLAMAR AQUI AL PROCEDIMIENTO QUE REALIZA EL CAMBIO DE LA LLAVE ATRIFARIA  
    CRU.TX_REGISTER_ENTITY.KEY_TARIFF_MODIFICATION( pi_tariff_key_code        => pi_tariff_key_code        ,
                                                    pi_telco_code             => pi_telco_code             ,
                                                    pi_tariff_key_id          => pi_tariff_key_id          , 
                                                    pi_modification_date      => pi_modification_date      ,
                                                    pi_modification_tran_code => pi_modification_tran_code ,
                                                    pi_tran_id                => pi_tran_id                ,
                                                    pi_tran_date              => pi_tran_date              ,
                                                    pi_user_code              => pi_user_code              ,
                                                    po_error_code             => po_error_code             ,
                                                    po_error_msg              => po_error_msg              );
    IF NVL (po_error_code, 'NOK') <> 'OK' THEN
      RAISE ERR_APP;
    END IF;
  EXCEPTION   
    WHEN ERR_APP THEN
      v_param_in :=-------------------------------- variable parameters --------------------------------
                  'pi_tariff_key_code: '         || pi_tariff_key_code                              ||
                  '|pi_telco_code: '             || pi_telco_code                                   ||
                  '|pi_tariff_key_id: '          || pi_tariff_key_id                                ||
                  '|pi_modification_date: '      || pi_modification_date                            ||
                  '|pi_modification_tran_code: ' || pi_modification_tran_code                       ||
                  '|pi_tran_id: '                || pi_tran_id                                      ||
                  '|pi_tran_date: '              || TO_CHAR( pi_tran_date, 'DD/MM/YYYY HH24:MI:SS') ||
                  '|pi_user_code: '              || pi_user_code                                    ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG (pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id   ,
                                      pi_error_code   => po_error_code,
                                      pi_error_msg    => po_error_msg ,
                                       pi_error_source => SUBSTR (v_package_procedure || '(' || v_param_in || ')', 1, 4000));
    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg  := SUBSTR (SQLERRM, 1, 1000);
      po_error_code := 'CRU-0000';--Critical error.||Error critico.
      v_param_in    :=-------------------------------- variable parameters --------------------------------
                    'pi_tariff_key_code: '         || pi_tariff_key_code                              ||
                    '|pi_telco_code: '             || pi_telco_code                                   ||
                    '|pi_tariff_key_id: '          || pi_tariff_key_id                                ||
                    '|pi_modification_date: '      || pi_modification_date                            ||
                    '|pi_modification_tran_code: ' || pi_modification_tran_code                       ||
                    '|pi_tran_id: '                || pi_tran_id                                      ||
                    '|pi_tran_date: '              || TO_CHAR( pi_tran_date, 'DD/MM/YYYY HH24:MI:SS') ||
                    '|pi_user_code: '              || pi_user_code                                    ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG (pi_telco_code   => pi_telco_code,
                                      pi_tran_id      => pi_tran_id   ,
                                      pi_error_code   => po_error_code,
                                      pi_error_msg    => po_error_msg ,
                                      pi_error_source => SUBSTR (v_package_procedure || '(' || v_param_in || ')', 1, 4000));
  
  END KEY_TARIFF_MODIFICATION;                                       

  /*
  Get error messages
  %Date           19/07/2013 10:30:00
  %Control        60220
  %Author         "Abel Soto Vera"
  %Version        1.0.0
      %param          pi_tran_id            Tran identifier.
      %param          pi_error_code         Code represents, for an error.
      %param          pi_language_code      Code associated with the language which requires the message.
      %return The function returns the name of a constant
      %raises         ERR_APP               Application level error
    %Changes
      <hr>
        {*}Date       22/07/2013 10:30:00
        {*}Control    60220
        {*}Author     "Abel Soto Vera"
        {*}Note       Update, modification of function for get error message and trace
  */
  FUNCTION GET_ERROR_MSG( pi_telco_code    IN  CRU.TR_ERROR_LOG.telco_code%TYPE  ,
                          pi_tran_id       IN  CRU.CF_ERROR.tran_id%TYPE:=NULL   , 
                          pi_error_code    IN  CRU.CF_ERROR.error_code%TYPE:=NULL,
                          pi_language_code IN  CRU.CF_ERROR.language_code%TYPE) RETURN VARCHAR2 IS

    v_description VARCHAR2(4000);
  BEGIN

    v_description := CRU.TX_CF_ERROR.GET_ERROR_MSG( pi_telco_code    => pi_telco_code   ,
                                                    pi_tran_id       => pi_tran_id      ,
                                                    pi_error_code    => pi_error_code   ,
                                                    pi_language_code => pi_language_code);
    RETURN v_description;
  END;

END TX_PUBLIC_ITF;
/
grant execute on CRU.TX_PUBLIC_ITF to ITF;


