CREATE OR REPLACE PACKAGE CRU.TX_CF_CREDIT_UNIT IS

 /**************************************************************************
  Implements basic functions of persistent storage for table CF_CREDIT_UNIT
  %Company         Trilogy Software Bolivia
  %System          Omega Convergent Billing
  %Date            03/11/2010 11:53:23
  %Control         60079
  %Author          "Abel Soto"
  %Version         1.0.0
  **************************************************************************/

  FUNCTION GET_VERSION RETURN VARCHAR2;
  
  --Inserts a record for table CF_CREDIT_UNIT receiving all columns as parameters
  PROCEDURE CREATE_( pi_telco_code                 IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE                ,
                     pi_credit_unit_code           IN  CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE          ,
                     pi_credit_unit_type_code      IN  CRU.CF_CREDIT_UNIT.credit_unit_type_code%TYPE     ,
                     pi_behavior_type_code         IN  CRU.CF_CREDIT_UNIT.behavior_type_code%TYPE        ,
                     --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
                     --pi_date_expiration_type_code  IN  CRU.CF_CREDIT_UNIT.date_expiration_type_code%TYPE ,
                     pi_round_method_code          IN  CRU.CF_CREDIT_UNIT.round_method_code%TYPE         ,
                     --pi_is_reseteable              IN  CRU.CF_CREDIT_UNIT.is_reseteable%TYPE             ,
                     --pi_is_include_invoice         IN  CRU.CF_CREDIT_UNIT.is_include_invoice%TYPE        ,
                     --pi_cycles_quantity_expiration IN  CRU.CF_CREDIT_UNIT.cycles_quantity_expiration%TYPE,
                     --pi_day_calendar_expiration    IN  CRU.CF_CREDIT_UNIT.day_calendar_expiration%TYPE   ,
                     --pi_expiration_days_quantity   IN  CRU.CF_CREDIT_UNIT.expiration_days_quantity%TYPE  ,
                     --pi_is_prorrateable            IN  CRU.CF_CREDIT_UNIT.is_prorrateable%TYPE           ,
                     pi_is_currency                IN  CRU.CF_CREDIT_UNIT.is_currency%TYPE               ,
                     pi_integration_other_system   IN  CRU.CF_CREDIT_UNIT.integration_other_system%TYPE  ,
                     pi_rollover_order             IN  CRU.CF_CREDIT_UNIT.rollover_order%TYPE            ,
                     --<ASV Control: 299 11/01/2013 11:00:00>
                     pi_start_date                 IN  CRU.CF_CREDIT_UNIT.start_date%TYPE                ,
                     pi_start_tran_id              IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE             ,
                     pi_start_tran_date            IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE           ,
                     pi_start_user_code            IN  CRU.CF_CREDIT_UNIT.start_user_code%TYPE           ,
                     po_credit_unit_id             OUT CRU.CF_CREDIT_UNIT.credit_unit_id%TYPE            ,
                     po_error_code                 OUT VARCHAR2                                          ,
                     po_error_msg                  OUT VARCHAR2                                          );

  -- Update end Date a record for table CF_CREDIT_UNIT receiving all columns as parameters
  PROCEDURE UPDATE_END_DATE_( pi_credit_unit_id  IN  CRU.CF_CREDIT_UNIT.credit_unit_id%TYPE ,
                              pi_telco_code      IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE     ,
                              pi_end_date        IN  CRU.CF_CREDIT_UNIT.end_date%TYPE       ,
                              pi_end_tran_id     IN  CRU.CF_CREDIT_UNIT.end_tran_id%TYPE    ,
                              pi_end_tran_date   IN  CRU.CF_CREDIT_UNIT.end_tran_date%TYPE  ,
                              pi_end_user_code   IN  CRU.CF_CREDIT_UNIT.end_user_code%TYPE  ,
                              po_error_code      OUT VARCHAR2                               ,
                              po_error_msg       OUT VARCHAR2                               );

  -- TRUNCATE end Date a record for table CF_CREDIT_UNIT receiving all columns as parameters
  PROCEDURE TRUNCATE_( pi_credit_unit_id  IN  CRU.CF_CREDIT_UNIT.credit_unit_id%TYPE ,
                       pi_telco_code      IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE     ,
                       pi_end_tran_id     IN  CRU.CF_CREDIT_UNIT.end_tran_id%TYPE    ,
                       pi_end_tran_date   IN  CRU.CF_CREDIT_UNIT.end_tran_date%TYPE  ,
                       pi_end_user_code   IN  CRU.CF_CREDIT_UNIT.end_user_code%TYPE  ,
                       po_error_code      OUT VARCHAR2                               ,
                       po_error_msg       OUT VARCHAR2                               );

END TX_CF_CREDIT_UNIT;
/

CREATE OR REPLACE PACKAGE BODY CRU.TX_CF_CREDIT_UNIT IS

 /**************************************************************************
  Implements basic functions of persistent storage for table CF_DOMAIN
  %Company         Trilogy Software Bolivia
  %System          Omega Convergent Billing
  %Date            03/11/2010 15:01:55
  %Control         60079
  %Author          "Abel Soto"
  %Version         1.0.0
  **************************************************************************/
  
  VERSION CONSTANT VARCHAR2(15) := '3.0.0';
  
  v_package VARCHAR2(100) := 'CRU.TX_CF_CREDIT_UNIT';

  c_application_code    CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_APPLICATION_CODE('APPLICATION_CRU',SYSDATE)                     ;
  c_end_date            CONSTANT  DATE                          := ITF.TX_PUBLIC_CRU.GET_END_DATE(SYSDATE)                                               ;
  c_inactive            CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC',c_application_code, 'SYSTEM_STATUS_INACTIVE',SYSDATE);
  c_active              CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC',c_application_code, 'SYSTEM_STATUS_ACTIVE',SYSDATE)  ;
  c_true                CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC',c_application_code, 'VALUE_BOOLEAN_TRUE',SYSDATE)    ;
  c_false               CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC',c_application_code, 'VALUE_BOOLEAN_FALSE',SYSDATE)   ;




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
  Inserts a record for table CF_CREDIT_UNIT receiving all columns as parameters
  %Date           03/11/2010 15:01:55
  %Control        60079
  %Author         "Abel Soto"
  %Version        1.0.0
      %param         pi_telco_code                    Code of operation
      %param         pi_credit_unit_code              Alpha-numeric Credit Unit code
      %param         pi_credit_unit_type_code         (GENER=Generic, or PROVIS = Provisioned)
      %param         pi_behavior_type_code            (FREE ,or WON)
      --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
      --%param         pi_date_expiration_type_code     Expiration Date Type
      %param         pi_round_method_code             Rounding method
      --%param         pi_is_reseteable                 Resettable (1= Yes, 0 = No)
      --%param         pi_is_include_invoice            Include in the bill (1 = Yes, 0 = No)
      --%param         pi_cycles_quantity_expiration    Quantity of expiration cycles
      --%param         pi_day_calendar_expiration       Calendar Day for expiration
      --%param         pi_expiration_days_quantity      Number of expiration days
      --%param         pi_is_prorrateable               Proratable (1 = Yes, 0 = No)
      %param         pi_is_currency                   Monetary unit (1 = Yes, 0 = No)
      %param         pi_integration_other_system      Integration Other System (1 = Yes, 0 = No)
      %param         pi_rollover_order                Rollover Order (FIFO or LIFO)      
      --<ASV Control: 299 11/01/2013 11:00:00>
      %param         pi_start_date                    Date on which Credit Unit starts
      %param         pi_start_tran_id                 Transaction start identifier, it identifies the transaction whose create the record
      %param         pi_start_tran_date               Transaction initial date;   is the date whose creates the record
      %param         pi_start_user_code               Start user identifier, It is the person or system who creates the record
      %param         po_credit_unit_id                Return Unique Identifier
      %param         po_error_code                    Output showing one of the next results:
                                                      {*} OK - If procedure executed satisfactorily
                                                      {*} XXX-#### - Error code if any error found
      %param         po_error_msg                     Output showing the error message if any error found
      %raises        ERR_APP                          Application level error

  %Changes
      <hr>
        {*}Date       11/01/2013 11:00:00
        {*}Control    299 
        {*}Author     "Abel Soto Vera"
        {*}Note       Modification of CRU, to support both the dosage and consumption of credit units, that for payment Post.
  %Changes
      <hr>
        {*}Date       23/07/2013 11:00:00
        {*}Control    60220 
        {*}Author     "Abel Soto Vera"
        {*}Note       Modification of CRU, drop of the start_tran_period and end_tran_perdiod, remove all UPPER().

  */


  PROCEDURE CREATE_( pi_telco_code                 IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE                ,
                     pi_credit_unit_code           IN  CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE          ,
                     pi_credit_unit_type_code      IN  CRU.CF_CREDIT_UNIT.credit_unit_type_code%TYPE     ,
                     pi_behavior_type_code         IN  CRU.CF_CREDIT_UNIT.behavior_type_code%TYPE        ,
                     --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
                     --pi_date_expiration_type_code  IN  CRU.CF_CREDIT_UNIT.date_expiration_type_code%TYPE ,
                     pi_round_method_code          IN  CRU.CF_CREDIT_UNIT.round_method_code%TYPE         ,
                     --pi_is_reseteable              IN  CRU.CF_CREDIT_UNIT.is_reseteable%TYPE             ,
                     --pi_is_include_invoice         IN  CRU.CF_CREDIT_UNIT.is_include_invoice%TYPE        ,
                     --pi_cycles_quantity_expiration IN  CRU.CF_CREDIT_UNIT.cycles_quantity_expiration%TYPE,
                     --pi_day_calendar_expiration    IN  CRU.CF_CREDIT_UNIT.day_calendar_expiration%TYPE   ,
                     --pi_expiration_days_quantity   IN  CRU.CF_CREDIT_UNIT.expiration_days_quantity%TYPE  ,
                     --pi_is_prorrateable            IN  CRU.CF_CREDIT_UNIT.is_prorrateable%TYPE           ,
                     pi_is_currency                IN  CRU.CF_CREDIT_UNIT.is_currency%TYPE               ,
                     pi_integration_other_system   IN  CRU.CF_CREDIT_UNIT.integration_other_system%TYPE  ,
                     pi_rollover_order             IN  CRU.CF_CREDIT_UNIT.rollover_order%TYPE            ,
                     --<ASV Control: 299 11/01/2013 11:00:00>
                     pi_start_date                 IN  CRU.CF_CREDIT_UNIT.start_date%TYPE                ,
                     pi_start_tran_id              IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE             ,
                     pi_start_tran_date            IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE           ,
                     pi_start_user_code            IN  CRU.CF_CREDIT_UNIT.start_user_code%TYPE           ,
                     po_credit_unit_id             OUT CRU.CF_CREDIT_UNIT.credit_unit_id%TYPE            ,
                     po_error_code                 OUT VARCHAR2                                          ,
                     po_error_msg                  OUT VARCHAR2                                          ) IS

  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.CREATE_';
    v_param_in          VARCHAR2(4000)                          ;

    c_both                     CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC',c_application_code, 'CRU_EVALUATION_CRITERIA_TYPE_BOTH',SYSDATE);
    c_expiration_no_expiration CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC',c_application_code, 'DATE_EXPIRATION_CRU_NO_EXPIRATION', SYSDATE);

  --Procedures variable
    v_min_date     CRU.CF_CREDIT_UNIT.start_date%TYPE;
    v_cru_rec      CRU.CF_CREDIT_UNIT%ROWTYPE;

  -- declare Exceptions
  ERR_APP EXCEPTION;
  BEGIN

    po_error_code := 'OK';
    po_error_msg  := ''  ;

    -- Validate domain values
    IF c_end_date                 IS NULL OR
       c_active                   IS NULL OR
       c_inactive                 IS NULL OR
       c_true                     IS NULL OR
       c_false                    IS NULL OR
       c_expiration_no_expiration IS NULL OR
       c_both                     IS NULL THEN
      po_error_code := 'CRU-0191';--Domain value is null.||Valor de dominio nulo.
      po_error_msg  := 'c_end_date:'                     || TO_CHAR(c_end_date,'DD/MM/YYYY HH24:MI:SS')||
                       '|c_active: '                     || c_active                                   ||
                       '|c_inactive:'                    || c_inactive                                 ||
                       '|c_true: '                       || c_true                                     ||
                       '|c_false: '                      || c_false                                    ||
                       '|c_expiration_no_expiration: '   || c_expiration_no_expiration                 ||
                       '|c_both: '                       || c_both                                      ;
      RAISE ERR_APP;
    END IF;

    -- Validate mandatory input parameters
    IF pi_telco_code                 IS NULL OR
       pi_credit_unit_code           IS NULL OR
       pi_credit_unit_type_code      IS NULL OR
       pi_behavior_type_code         IS NULL OR
       pi_round_method_code          IS NULL OR
       pi_is_currency                IS NULL OR
       --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
       --pi_date_expiration_type_code  IS NULL OR
       --pi_is_reseteable              IS NULL OR
       --pi_is_prorrateable            IS NULL 
       --<ASV Control: 299 11/01/2013 11:00:00>
       pi_integration_other_system   IS NULL OR
       pi_rollover_order             IS NULL THEN
      po_error_code := 'CRU-0192';  --Mandatory parameters are null.||Parametros obligatorios son nulo.
      RAISE ERR_APP;
    END IF;
    
   -- Validation of the consistency of data
   
   IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN('TELCO_GENERIC', 'TELCO_OPERATIONS_CODE', pi_telco_code, SYSDATE) IS NULL THEN
      po_error_code:= 'CRU-0000'; --Domain telco code operation value is null||Valor de dominio telco code operation es nulo
      po_error_msg:= 'pi_telco_code: ' || pi_telco_code ;
      RAISE ERR_APP;
    END IF;
   
    IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN(pi_telco_code,'CREDIT_UNIT_TYPE', pi_credit_unit_type_code, pi_start_date) IS NULL THEN
      po_error_code:= 'CRU-0193'; --Domain credit_unit_type_code value is null||Valor de dominio credit_unit_type_code es nulo
      RAISE ERR_APP;
    END IF;

    IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN(pi_telco_code,'CRU_BEHAVIOR_TYPE', pi_behavior_type_code, pi_start_date) IS NULL THEN
      po_error_code:= 'CRU-0194'; --Domain behavior_type_code value is null||Valor de dominio behavior_type_code es nulo
      RAISE ERR_APP;
    END IF;
    --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
    /*IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN('DATE_EXPIRATION_CRU', pi_date_expiration_type_code, pi_start_date) IS NULL THEN
      po_error_code:= 'CRU-0195'; --Domain pi_date_expiration_type_code value is null||Valor de dominio pi_date_expiration_type_code es nulo
      RAISE ERR_APP;
    END IF;*/
    --<ASV Control: 299 11/01/2013 11:00:00>
    IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN(pi_telco_code,'ROUND_METHOD_CRU', pi_round_method_code, pi_start_date) IS NULL THEN
      po_error_code:= 'CRU-0196'; --Domain pi_round_method_code value is null||Valor de dominio pi_round_method_code es nulo
      RAISE ERR_APP;
    END IF;
    --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
    /*IF (pi_date_expiration_type_code = c_expiration_no_expiration) AND
       (pi_cycles_quantity_expiration IS NOT NULL OR
        pi_day_calendar_expiration    IS NOT NULL OR
        pi_expiration_days_quantity   IS NOT NULL) THEN
      po_error_code := 'CRU-0423'; --If the type of expiration is NO EXPIRATION, the values ?should not be configured.||Si el tipo de fecha de expiración es SIN EXPIRACIÓN, los valores no deben ser configurados.
      RAISE ERR_APP;
    END IF;*/
    --<ASV Control: 299 11/01/2013 11:00:00>
    ------------------------------ Bussines Logic ------------------------------
    BEGIN
      SELECT *
        INTO v_cru_rec
        FROM CRU.CF_CREDIT_UNIT
       WHERE credit_unit_code   = pi_credit_unit_code
         AND pi_start_date   BETWEEN start_date AND end_date
         AND status             <> c_inactive
         AND telco_code = pi_telco_code;

      po_error_code := 'CRU-0197'; --Code already in use in the interval of dates entered.|| Código ya en uso en el intervalo de fechas introducidas.
      RAISE ERR_APP;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN

      SELECT MIN(start_date)
        INTO v_min_date
        FROM CRU.CF_CREDIT_UNIT
       WHERE credit_unit_code = pi_credit_unit_code
         AND start_date        > pi_start_date
         AND status           <> c_inactive
         AND telco_code = pi_telco_code;

      IF v_min_date IS NULL THEN

         CRU.CC_CF_CREDIT_UNIT.CREATE_( pi_telco_code                   =>  pi_telco_code               ,
                                        pi_credit_unit_code             =>  pi_credit_unit_code         ,
                                        pi_credit_unit_type_code        =>  pi_credit_unit_type_code    ,
                                        pi_behavior_type_code           =>  pi_behavior_type_code       ,
                                        --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
                                        --pi_date_expiration_type_code    =>  pi_date_expiration_type_code,
                                        pi_round_method_code            =>  pi_round_method_code        ,
                                        --pi_is_reseteable                =>  pi_is_reseteable            ,
                                        --pi_is_include_invoice           =>  pi_is_include_invoice       ,
                                        --pi_cycles_quantity_expiration   =>  pi_cycles_quantity_expiration,
                                        --pi_day_calendar_expiration      =>  pi_day_calendar_expiration  ,
                                        --pi_expiration_days_quantity     =>  pi_expiration_days_quantity ,
                                        --pi_is_prorrateable              =>  pi_is_prorrateable          ,
                                        pi_is_currency                  =>  pi_is_currency              ,
                                        pi_integration_other_system     =>  pi_integration_other_system ,
                                        pi_rollover_order               =>  pi_rollover_order           ,
                                        --<ASV Control: 299 11/01/2013 11:00:00>
                                        pi_start_date                   =>  pi_start_date               ,
                                        pi_end_date                     =>  c_end_date                  ,
                                        pi_status                       =>  c_active                    ,
                                        pi_start_tran_id                =>  pi_start_tran_id            ,
                                        pi_start_tran_date              =>  pi_start_tran_date          ,
                                        pi_start_user_code              =>  pi_start_user_code          ,
                                        pi_end_tran_id                  =>  NULL,
                                        pi_end_tran_date                =>  NULL,
                                        pi_end_user_code                =>  NULL,
                                        po_credit_unit_id               =>  po_credit_unit_id           ,
                                        po_error_code                   =>  po_error_code               ,
                                        po_error_msg                    =>  po_error_msg                );

        IF NVL(po_error_code,'NOK') <> 'OK' THEN
           RAISE ERR_APP;
        END IF;

      END IF;

      IF pi_start_date < v_min_date THEN

         CRU.CC_CF_CREDIT_UNIT.CREATE_( pi_telco_code                   =>  pi_telco_code               ,
                                        pi_credit_unit_code             =>  pi_credit_unit_code         ,
                                        pi_credit_unit_type_code        =>  pi_credit_unit_type_code    ,
                                        pi_behavior_type_code           =>  pi_behavior_type_code       ,
                                        --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
                                        --pi_date_expiration_type_code    =>  pi_date_expiration_type_code,
                                        pi_round_method_code            =>  pi_round_method_code        ,
                                        --pi_is_reseteable                =>  pi_is_reseteable            ,
                                        --pi_is_include_invoice           =>  pi_is_include_invoice       ,
                                        --pi_cycles_quantity_expiration   =>  pi_cycles_quantity_expiration,
                                        --pi_day_calendar_expiration      =>  pi_day_calendar_expiration  ,
                                        --pi_expiration_days_quantity     =>  pi_expiration_days_quantity ,
                                        --pi_is_prorrateable              =>  pi_is_prorrateable          ,
                                        pi_is_currency                  =>  pi_is_currency              ,
                                        pi_integration_other_system     =>  pi_integration_other_system ,
                                        pi_rollover_order               =>  pi_rollover_order           ,
                                        --<ASV Control: 299 11/01/2013 11:00:00>
                                        pi_start_date                   =>  pi_start_date               ,
                                        pi_end_date                     =>  v_min_date - NUMTODSINTERVAL(1,'SECOND'),
                                        pi_status                       =>  c_active                    ,
                                        pi_start_tran_id                =>  pi_start_tran_id            ,
                                        pi_start_tran_date              =>  pi_start_tran_date          ,
                                        pi_start_user_code              =>  pi_start_user_code          ,
                                        pi_end_tran_id                  =>  NULL,
                                        pi_end_tran_date                =>  NULL,
                                        pi_end_user_code                =>  NULL,
                                        po_credit_unit_id               =>  po_credit_unit_id           ,
                                        po_error_code                   =>  po_error_code               ,
                                        po_error_msg                    =>  po_error_msg                );

        IF NVL(po_error_code,'NOK') <> 'OK' THEN
           RAISE ERR_APP;
        END IF;

      END IF;

    END;

    ------------------------------ End of Bussiness Logic ---------------------

  EXCEPTION
    WHEN ERR_APP THEN
      -- Initiate log variables
      v_param_in    :=------------------------------- variable parameters -------------------------------
                    'pi_telco_code: '                   || pi_telco_code                    ||
                    '|pi_credit_unit_code: '             || pi_credit_unit_code              ||
                    '|pi_credit_unit_type_code: '        || pi_credit_unit_type_code         ||
                    '|pi_behavior_type_code: '           || pi_behavior_type_code            ||
                    --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
                    --'pi_date_expiration_type_code: '    || pi_date_expiration_type_code     || '|' ||
                    '|pi_round_method_code: '            || pi_round_method_code             || 
                    --'pi_is_reseteable: '                || pi_is_reseteable                 || '|' ||
                    --'pi_is_include_invoice: '           || pi_is_include_invoice            || '|' ||
                    --'pi_cycles_quantity_expiration: '   || pi_cycles_quantity_expiration    || '|' ||
                    --'pi_day_calendar_expiration: '      || pi_day_calendar_expiration       || '|' ||
                    --'pi_expiration_days_quantity: '     || pi_expiration_days_quantity      || '|' ||
                    --'pi_is_prorrateable: '              || pi_is_prorrateable               || '|' ||
                    '|pi_is_currency: '                  || pi_is_currency                   ||
                    '|pi_integration_other_system: '     || pi_integration_other_system      ||
                    '|pi_rollover_order: '               || pi_rollover_order                ||
                    --<ASV Control: 299 11/01/2013 11:00:00>
                    '|pi_start_date: '                   || TO_CHAR(pi_start_date,'DD/MM/YYYY HH24:MI:SS')  ||
                    '|pi_start_tran_id: '                || pi_start_tran_id                 ||
                    '|pi_start_tran_date: '              || TO_CHAR(pi_start_tran_date,'DD/MM/YYYY HH24:MI:SS')||
                    '|pi_start_user_code: '              || pi_start_user_code  ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code   ,
                                      pi_tran_id      => pi_start_tran_id,
                                      pi_error_code   => po_error_code   ,
                                      pi_error_msg    => po_error_msg    ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));

    WHEN OTHERS THEN

      -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code := 'CRU-0198';--Critical error.||Error critico.
      v_param_in    :=------------------------------- variable parameters -------------------------------
                      'pi_telco_code: '                    || pi_telco_code                    ||
                      '|pi_credit_unit_code: '             || pi_credit_unit_code              ||
                      '|pi_credit_unit_type_code: '        || pi_credit_unit_type_code         ||
                      '|pi_behavior_type_code: '           || pi_behavior_type_code            ||
                      --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
                      --'pi_date_expiration_type_code: '    || pi_date_expiration_type_code     || '|' ||
                      '|pi_round_method_code: '            || pi_round_method_code             || 
                      --'pi_is_reseteable: '                || pi_is_reseteable                 || '|' ||
                      --'pi_is_include_invoice: '           || pi_is_include_invoice            || '|' ||
                      --'pi_cycles_quantity_expiration: '   || pi_cycles_quantity_expiration    || '|' ||
                      --'pi_day_calendar_expiration: '      || pi_day_calendar_expiration       || '|' ||
                      --'pi_expiration_days_quantity: '     || pi_expiration_days_quantity      || '|' ||
                      --'pi_is_prorrateable: '              || pi_is_prorrateable               || '|' ||
                      '|pi_is_currency: '                  || pi_is_currency                   ||
                      '|pi_integration_other_system: '     || pi_integration_other_system      ||
                      '|pi_rollover_order: '               || pi_rollover_order                ||
                      --<ASV Control: 299 11/01/2013 11:00:00>
                      '|pi_start_date: '                   || TO_CHAR(pi_start_date,'DD/MM/YYYY HH24:MI:SS')  ||
                      '|pi_start_tran_id: '                || pi_start_tran_id                 ||
                      '|pi_start_tran_date: '              || TO_CHAR(pi_start_tran_date,'DD/MM/YYYY HH24:MI:SS')||
                      '|pi_start_user_code: '              || pi_start_user_code  ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code   ,
                                      pi_tran_id      => pi_start_tran_id,
                                      pi_error_code   => po_error_code   ,
                                      pi_error_msg    => po_error_msg    ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));


  END;


   /*
  Update end Date a record for table CF_CREDIT_UNIT receiving all columns as parameters
  %Date           03/11/2010 15:01:55
  %Control        60079
  %Author         "Abel Soto"
  %Version        1.0.0
      %param          pi_credit_unit_id         Unique Identifier
      %param          pi_telco_code             Code of operation
      %param          pi_end_date               Date the Credit Unit ends
      %param          pi_end_tran_id            Transaction end identifier; it identifies the transaction whose modifies the record
      %param          pi_end_tran_date          Transaction end date; is the date whose modifies the record by last time
      %param          pi_end_user_code          End user identifier, it identifies to the person or system who modified the record by last time
      %param          po_error_code             Output showing one of the next results:
                                                {*} OK - If procedure executed satisfactorily
                                                {*} XXX-#### - Error code if any error found
      %param          po_error_msg              Output showing the error message if any error found
      %raises         ERR_APP                   Application level error
  %Changes
      <hr>
        {*}Date       23/07/2013 11:00:00
        {*}Control    60220 
        {*}Author     "Abel Soto Vera"
        {*}Note       Modification of CRU, drop of the start_tran_period and end_tran_perdiod, remove all UPPER().

    */

  PROCEDURE UPDATE_END_DATE_( pi_credit_unit_id  IN  CRU.CF_CREDIT_UNIT.credit_unit_id%TYPE ,
                              pi_telco_code      IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE     ,
                              pi_end_date        IN  CRU.CF_CREDIT_UNIT.end_date%TYPE       ,
                              pi_end_tran_id     IN  CRU.CF_CREDIT_UNIT.end_tran_id%TYPE    ,
                              pi_end_tran_date   IN  CRU.CF_CREDIT_UNIT.end_tran_date%TYPE  ,
                              pi_end_user_code   IN  CRU.CF_CREDIT_UNIT.end_user_code%TYPE  ,
                              po_error_code      OUT VARCHAR2                               ,
                              po_error_msg       OUT VARCHAR2                               )IS

  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.UPDATE_END_DATE_';
    v_param_in          VARCHAR2(4000);
    v_cru_rec      CRU.CF_CREDIT_UNIT%ROWTYPE;

  -- Declare Exceptions
    ERR_APP EXCEPTION;
  BEGIN
    -- Initiate log variables
    po_error_code := 'OK';
    po_error_msg  := ''  ;

    -- Validate domain values
    IF c_inactive IS NULL THEN
       po_error_code := 'CRU-0199';--Constants value is null.||Valor de las constantes es nulo.
       po_error_msg  := 'c_inactive: ' || c_inactive;
      RAISE ERR_APP;
    END IF;

    -- Validate mandatory input parameters
    IF pi_credit_unit_id   IS NULL OR
       pi_telco_code       IS NULL OR
       pi_end_date         IS NULL OR
       pi_end_tran_id      IS NULL OR
       pi_end_tran_date    IS NULL OR
       pi_end_user_code    IS NULL THEN
       po_error_code := 'CRU-0200'; --Mandatory parameter is null||Parametro obligatorio es null
       RAISE ERR_APP;
    END IF;
    
    IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN('TELCO_GENERIC', 'TELCO_OPERATIONS_CODE', pi_telco_code, SYSDATE) IS NULL THEN
      po_error_code:= 'CRU-0000'; --Domain credit_unit_type_code value is null||Valor de dominio credit_unit_type_code es nulo
      po_error_msg:= 'pi_telco_code: ' || pi_telco_code ;
      RAISE ERR_APP;
    END IF;

    IF pi_end_date < SYSDATE THEN
       po_error_code:= 'CRU-0201'; --Input date is not valid.||Fecha ingresada no válida.
       RAISE ERR_APP;
    END IF;

    ------------------------------ Bussiness Logic -------------------------
    BEGIN

      SELECT *
      INTO v_cru_rec
      FROM CRU.CF_CREDIT_UNIT
      WHERE credit_unit_id  = pi_credit_unit_id
        AND status         <> c_inactive
        AND telco_code      = pi_telco_code;

      IF pi_end_date > v_cru_rec.start_date AND
         pi_end_date < v_cru_rec.end_date   THEN

         CRU.CC_CF_CREDIT_UNIT.UPDATE_END_DATE_( pi_credit_unit_id   => pi_credit_unit_id ,
                                                 pi_telco_code       => pi_telco_code     ,
                                                 pi_end_date         => pi_end_date       ,
                                                 pi_end_tran_id      => pi_end_tran_id    ,
                                                 pi_end_tran_date    => pi_end_tran_date  ,
                                                 pi_end_user_code    => pi_end_user_code  ,
                                                 po_error_code       => po_error_code     ,
                                                 po_error_msg        => po_error_msg      );
        IF NVL(po_error_code,'NOK') <> 'OK' THEN
           RAISE ERR_APP;
        END IF;

      ELSE
        po_error_code := 'CRU-0202'; --The end date is beyond the duration of the record||La fecha fin esta fuera de la vigencia del registro
        RAISE ERR_APP;
      END IF;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      po_error_code:= 'CRU-0203'; --Error not exists record to update||Error no existe el registro a actualizar
      RAISE ERR_APP;
    END;
   ------------------------------ End of Bussiness Logic ---------------------

    po_error_code := 'OK';
    po_error_msg  := ''  ;

  EXCEPTION
    WHEN ERR_APP THEN
                -- Initiate log variables
      v_param_in :=---------- variable parameters ------------------
                  'pi_credit_unit_id:'    || pi_credit_unit_id                                   ||
                  '|pi_telco_code:'       || pi_telco_code                                       ||
                  '|pi_end_date:'         || TO_CHAR(pi_end_date,'DD/MM/YYYY HH24:MI:SS')        ||
                  '|pi_end_tran_id: '     || pi_end_tran_id                                      ||
                  '|pi_end_tran_date: '   || TO_CHAR( pi_end_tran_date, 'DD/MM/YYYY HH24:MI:SS') ||
                  '|pi_end_user_code: '   || pi_end_user_code                                     ;

     CRU.TX_TR_ERROR_LOG.RECORD_LOG(  pi_telco_code   => pi_telco_code   ,
                                      pi_tran_id        => pi_end_tran_id,
                                      pi_error_code    => po_error_code,
                                      pi_error_msg     => po_error_msg,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));
    WHEN OTHERS THEN
    -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code:= 'CRU-0204'; --Uncontrolled Error.||Error no controlado.
      v_param_in :=---------- variable parameters ------------------
                  'pi_credit_unit_id:'    || pi_credit_unit_id                                   ||
                  '|pi_telco_code:'       || pi_telco_code                                       ||
                  '|pi_end_date:'         || TO_CHAR(pi_end_date,'DD/MM/YYYY HH24:MI:SS')        ||
                  '|pi_end_tran_id: '     || pi_end_tran_id                                      ||
                  '|pi_end_tran_date: '   || TO_CHAR( pi_end_tran_date, 'DD/MM/YYYY HH24:MI:SS') ||
                  '|pi_end_user_code: '   || pi_end_user_code                                     ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code   ,
                                      pi_tran_id       => pi_end_tran_id,
                                      pi_error_code    => po_error_code,
                                      pi_error_msg     => po_error_msg,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));


  END ;

   /*
  TRUNCATE end Date a record for table CF_CREDIT_UNIT receiving all columns as parameters
  %Date           03/11/2010 15:01:55
  %Control        60079
  %Author         "Abel Soto"
  %Version        1.0.0
      %param          pi_credit_unit_id       Unique Identifier
      %param          pi_telco_code           Code of operation
      %param          pi_end_tran_id          Transaction end identifier; it identifies the transaction whose modifies the record
      %param          pi_end_tran_date        Transaction end date; is the date whose modifies the record by last time
      %param          pi_end_user_code        End user identifier, it identifies to the person or system who modified the record by last time
      %param          po_error_code           Output showing one of the next results:
                                              {*} OK - If procedure executed satisfactorily
                                              {*} XXX-#### - Error code if any error found
      %param          po_error_msg            Output showing the error message if any error found
      %raises         ERR_APP                 Application level error
  %Changes
      <hr>
        {*}Date       23/07/2013 11:00:00
        {*}Control    60220 
        {*}Author     "Abel Soto Vera"
        {*}Note       Modification of CRU, drop of the start_tran_period and end_tran_perdiod, remove all UPPER().

  */

  PROCEDURE TRUNCATE_( pi_credit_unit_id  IN  CRU.CF_CREDIT_UNIT.credit_unit_id%TYPE ,
                       pi_telco_code      IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE     ,
                       pi_end_tran_id     IN  CRU.CF_CREDIT_UNIT.end_tran_id%TYPE    ,
                       pi_end_tran_date   IN  CRU.CF_CREDIT_UNIT.end_tran_date%TYPE  ,
                       pi_end_user_code   IN  CRU.CF_CREDIT_UNIT.end_user_code%TYPE  ,
                       po_error_code      OUT VARCHAR2                               ,
                       po_error_msg       OUT VARCHAR2                               )IS


  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.TRUNCATE_';
    v_param_in          VARCHAR2(4000);

 -- Procedure variables
    v_count_rec        NUMBER := 0                                       ;
    v_credit_unit_code  CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE         ;

 -- Cursor
  CURSOR cur_cru_description (p_credit_unit_code CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE)IS
    SELECT cru_description_id
      FROM CRU.CF_CRU_DESCRIPTION
     WHERE credit_unit_code = p_credit_unit_code
       AND status <> c_inactive;

  CURSOR cur_cru_entity_status (p_credit_unit_code CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE)IS
    SELECT cru_entity_status_id
      FROM CRU.CF_CRU_ENTITY_STATUS
     WHERE credit_unit_code = p_credit_unit_code
       AND status <> c_inactive;

  CURSOR cur_cru_applicability (p_credit_unit_code CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE)IS
    SELECT cru_applicability_id
      FROM CRU.CF_CRU_APPLICABILITY
     WHERE credit_unit_code = p_credit_unit_code
       AND status <> c_inactive;

  CURSOR cur_cru_rate (p_credit_unit_code CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE)IS
    SELECT cru_rate_id
      FROM CRU.CF_CRU_RATE
     WHERE credit_unit_code = p_credit_unit_code
       AND status <> c_inactive;

  CURSOR cur_cru_exclude (p_credit_unit_code CRU.CF_CREDIT_UNIT.credit_unit_code%TYPE)IS
    SELECT cru_exclude_id
      FROM CRU.CF_CRU_EXCLUDE
     WHERE credit_unit_code = p_credit_unit_code
       AND status <> c_inactive;

  -- Declare Exceptions
    ERR_APP EXCEPTION;
  BEGIN
    -- Initiate log variables
    po_error_code := 'OK';
    po_error_msg  := '';
    -- Validate domain values
    IF c_inactive IS NULL THEN
      po_error_code := 'CRU-0205';--Constants value is null.||Valor de las constantes es nulo.
      po_error_msg  := 'c_inactive: ' || c_inactive ;
      RAISE ERR_APP;
    END IF;

    -- Validate mandatory input parameters
    IF pi_credit_unit_id  IS NULL OR
       pi_telco_code      IS NULL OR
       pi_end_tran_id     IS NULL OR
       pi_end_tran_date   IS NULL OR
       pi_end_user_code   IS NULL THEN
       po_error_code := 'CRU-0206'; --Mandatory parameter is null||Parametro obligatorio es null
       RAISE ERR_APP;
    END IF;
    
    IF ITF.TX_PUBLIC_CRU.VERIFY_DOMAIN('TELCO_GENERIC', 'TELCO_OPERATIONS_CODE', pi_telco_code, SYSDATE) IS NULL THEN
      po_error_code:= 'CRU-0000'; --Domain credit_unit_type_code value is null||Valor de dominio credit_unit_type_code es nulo
      po_error_msg:= 'pi_telco_code: ' || pi_telco_code ;
      RAISE ERR_APP;
    END IF;

    ------------------------------ Bussiness Logic -------------------------
    BEGIN
      SELECT COUNT(credit_unit_code), credit_unit_code
        INTO v_count_rec, v_credit_unit_code
        FROM CRU.CF_CREDIT_UNIT
       WHERE credit_unit_id =  pi_credit_unit_id
         AND status        <> c_inactive
         AND telco_code = pi_telco_code
         GROUP BY credit_unit_code ;

      IF v_count_rec <= 0 THEN

        po_error_code := 'CRU-0207';--Credit Unit is already inactive||La Unidad de Credit ya se encuentra inactivo
        po_error_msg  := 'pi_credit_unit_id: ' || pi_credit_unit_id;
        RAISE ERR_APP;

      END IF;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        po_error_code:= 'CRU-0208'; --Error not exists record to delete||Error no existe el registro a eliminar
        RAISE ERR_APP;
    END;

       -- Truncate CF_REC_DESCRIPTION
       FOR v_cru_id IN cur_cru_description (v_credit_unit_code) LOOP

           CRU.TX_CF_CRU_DESCRIPTION.TRUNCATE_( pi_cru_description_id => v_cru_id.cru_description_id,
                                                pi_telco_code         => pi_telco_code              ,
                                                pi_end_tran_id        => pi_end_tran_id             ,
                                                pi_end_tran_date      => pi_end_tran_date           ,
                                                pi_end_user_code      => pi_end_user_code           ,
                                                po_error_code         => po_error_code              ,
                                                po_error_msg          => po_error_msg               );

           IF NVL(po_error_code,'NOK') <> 'OK' THEN
               RAISE ERR_APP;
           END IF;

       END LOOP;
       --Truncate CF_REC_ENTITY_STATUS
       FOR v_cru_id IN cur_cru_entity_status (v_credit_unit_code) LOOP

           CRU.TX_CF_CRU_ENTITY_STATUS.TRUNCATE_( pi_cru_entity_status_id => v_cru_id.cru_entity_status_id,
                                                  pi_telco_code           => pi_telco_code                ,
                                                  pi_end_tran_id          => pi_end_tran_id               ,
                                                  pi_end_tran_date        => pi_end_tran_date             ,
                                                  pi_end_user_code        => pi_end_user_code             ,
                                                  po_error_code           => po_error_code                ,
                                                  po_error_msg            => po_error_msg                 );

           IF NVL(po_error_code,'NOK') <> 'OK' THEN
               RAISE ERR_APP;
           END IF;

       END LOOP;

       --Truncate CF_REC_APPLICABILITY
       FOR v_cru_id IN cur_cru_applicability (v_credit_unit_code) LOOP

           CRU.TX_CF_CRU_APPLICABILITY.TRUNCATE_( pi_cru_applicability_id => v_cru_id.cru_applicability_id,
                                                  pi_telco_code           => pi_telco_code                ,
                                                  pi_end_tran_id          => pi_end_tran_id               ,
                                                  pi_end_tran_date        => pi_end_tran_date             ,
                                                  pi_end_user_code        => pi_end_user_code             ,
                                                  po_error_code           => po_error_code                ,
                                                  po_error_msg            => po_error_msg                 );

           IF NVL(po_error_code,'NOK') <> 'OK' THEN
               RAISE ERR_APP;
           END IF;

       END LOOP;

       -- Truncate CF_REC_RATE
       FOR v_cru_id IN cur_cru_rate (v_credit_unit_code) LOOP

           CRU.TX_CF_CRU_RATE.TRUNCATE_( pi_cru_rate_id     => v_cru_id.cru_rate_id,
                                         pi_telco_code      => pi_telco_code       ,
                                         pi_end_tran_id     => pi_end_tran_id      ,
                                         pi_end_tran_date   => pi_end_tran_date    ,
                                         pi_end_user_code   => pi_end_user_code    ,
                                         po_error_code      => po_error_code       ,
                                         po_error_msg       => po_error_msg        );

           IF NVL(po_error_code,'NOK') <> 'OK' THEN
               RAISE ERR_APP;
           END IF;

       END LOOP;

       -- Truncate CF_REC_EXCLUDE
       FOR v_cru_id IN cur_cru_exclude (v_credit_unit_code) LOOP

           CRU.TX_CF_CRU_EXCLUDE.TRUNCATE_( pi_cru_exclude_id  => v_cru_id.cru_exclude_id,
                                            pi_telco_code      => pi_telco_code          ,
                                            pi_end_tran_id     => pi_end_tran_id         ,
                                            pi_end_tran_date   => pi_end_tran_date       ,
                                            pi_end_user_code   => pi_end_user_code       ,
                                            po_error_code      => po_error_code          ,
                                            po_error_msg       => po_error_msg           );

           IF NVL(po_error_code,'NOK') <> 'OK' THEN
               RAISE ERR_APP;
           END IF;

       END LOOP;

      --change status of credit unit
      CRU.CC_CF_CREDIT_UNIT.CHANGE_STATUS_(pi_credit_unit_id   => pi_credit_unit_id ,
                                           pi_telco_code       => pi_telco_code     ,
                                           pi_status           => c_inactive        ,
                                           pi_end_tran_id      => pi_end_tran_id    ,
                                           pi_end_tran_date    => pi_end_tran_date  ,
                                           pi_end_user_code    => pi_end_user_code  ,
                                           po_error_code       => po_error_code     ,
                                           po_error_msg        => po_error_msg      );

        IF NVL(po_error_code,'NOK') <> 'OK' THEN
           RAISE ERR_APP;
        END IF;

    ------------------------------ End of Bussiness Logic ---------------------

    po_error_code := 'OK';
    po_error_msg  := ''  ;

  EXCEPTION
    WHEN ERR_APP THEN
                -- Initiate log variables
      v_param_in :=---------- variable parameters ------------------
                   'pi_credit_unit_id:'  || pi_credit_unit_id                                  ||
                   '|pi_telco_code:'     || pi_telco_code                                      ||
                   '|pi_end_tran_id: '   || pi_end_tran_id                                     ||
                   '|pi_end_tran_date: ' || TO_CHAR( pi_end_tran_date,'DD/MM/YYYY HH24:MI:SS') ||
                   '|pi_end_user_code: ' || pi_end_user_code                                    ;

     CRU.TX_TR_ERROR_LOG.RECORD_LOG(  pi_telco_code   => pi_telco_code   ,
                                      pi_tran_id        => pi_end_tran_id,
                                      pi_error_code    => po_error_code,
                                      pi_error_msg     => po_error_msg,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));
    WHEN OTHERS THEN
    -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code:= 'CRU-0209'; --Uncontrolled Error.||Error no controlado.
      v_param_in :=---------- variable parameters ------------------
                   'pi_credit_unit_id:'  || pi_credit_unit_id                                 ||
                   '|pi_telco_code:'     || pi_telco_code                                     ||
                   '|pi_end_tran_id: '   || pi_end_tran_id                                    ||
                   '|pi_end_tran_date: ' || TO_CHAR( pi_end_tran_date,'DD/MM/YYYY HH24:MI:SS')||
                   '|pi_end_user_code: ' || pi_end_user_code                                   ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code  ,
                                      pi_tran_id       => pi_end_tran_id,
                                      pi_error_code    => po_error_code ,
                                      pi_error_msg     => po_error_msg  ,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));

  END ;


END TX_CF_CREDIT_UNIT;
/

