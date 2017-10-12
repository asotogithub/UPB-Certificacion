CREATE OR REPLACE PACKAGE CRU.CC_CF_CREDIT_UNIT  IS
   /**************************************************************************
    Implements basic functions of persistent storage for table CF_CREDIT_UNIT
    %Company         Trilogy Software Bolivia
    %System          Omega Convergent Billing
    %Date            03/11/2010 8:56:41
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
                     pi_end_date                   IN  CRU.CF_CREDIT_UNIT.end_date%TYPE                  ,
                     pi_status                     IN  CRU.CF_CREDIT_UNIT.status%TYPE                    ,
                     pi_start_tran_id              IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE             ,
                     pi_start_tran_date            IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE           ,
                     pi_start_user_code            IN  CRU.CF_CREDIT_UNIT.start_user_code%TYPE           ,
                     pi_end_tran_id                IN  CRU.CF_CREDIT_UNIT.end_tran_id%TYPE               ,
                     pi_end_tran_date              IN  CRU.CF_CREDIT_UNIT.end_tran_date%TYPE             ,
                     pi_end_user_code              IN  CRU.CF_CREDIT_UNIT.end_user_code%TYPE             ,
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

   -- Change status a record receiving ID as parameter
  PROCEDURE CHANGE_STATUS_( pi_credit_unit_id  IN  CRU.CF_CREDIT_UNIT.credit_unit_id%TYPE ,
                            pi_telco_code      IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE     ,
                            pi_status          IN  CRU.CF_CREDIT_UNIT.status%TYPE         ,
                            pi_end_tran_id     IN  CRU.CF_CREDIT_UNIT.end_tran_id%TYPE    ,
                            pi_end_tran_date   IN  CRU.CF_CREDIT_UNIT.end_tran_date%TYPE  ,
                            pi_end_user_code   IN  CRU.CF_CREDIT_UNIT.end_user_code%TYPE  ,
                            po_error_code      OUT VARCHAR2                               ,
                            po_error_msg       OUT VARCHAR2                               );
END CC_CF_CREDIT_UNIT;
/

CREATE OR REPLACE PACKAGE BODY CRU.CC_CF_CREDIT_UNIT IS

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

  v_package VARCHAR2(100) := 'CRU.CC_CF_CREDIT_UNIT';

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
      %param         pi_end_date                      Date the Credit Unit ends
      %param         pi_status                        Credit unit status Active (A) or Inactive (I)
      %param         pi_start_tran_id                 Transaction start identifier, it identifies the transaction whose create the record
      %param         pi_start_tran_date               Transaction initial date;   is the date whose creates the record
      %param         pi_start_user_code               Start user identifier, It is the person or system who creates the record
      %param         pi_end_tran_id                   Transaction end identifier; it identifies the transaction whose modifies the record
      %param         pi_end_tran_date                 Transaction end date; is the date whose modifies the record by last time
      %param         pi_end_user_code                 End user identifier, it identifies to the person or system who modified the record by last time
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

  PROCEDURE CREATE_( pi_telco_code                 IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE          ,
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
                     pi_end_date                   IN  CRU.CF_CREDIT_UNIT.end_date%TYPE                  ,
                     pi_status                     IN  CRU.CF_CREDIT_UNIT.status%TYPE                    ,
                     pi_start_tran_id              IN  CRU.CF_CREDIT_UNIT.start_tran_id%TYPE             ,
                     pi_start_tran_date            IN  CRU.CF_CREDIT_UNIT.start_tran_date%TYPE           ,
                     pi_start_user_code            IN  CRU.CF_CREDIT_UNIT.start_user_code%TYPE           ,
                     pi_end_tran_id                IN  CRU.CF_CREDIT_UNIT.end_tran_id%TYPE               ,
                     pi_end_tran_date              IN  CRU.CF_CREDIT_UNIT.end_tran_date%TYPE             ,
                     pi_end_user_code              IN  CRU.CF_CREDIT_UNIT.end_user_code%TYPE             ,
                     po_credit_unit_id             OUT CRU.CF_CREDIT_UNIT.credit_unit_id%TYPE            ,
                     po_error_code                 OUT VARCHAR2                                          ,
                     po_error_msg                  OUT VARCHAR2                                          )IS

  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.CREATE_';
    v_param_in          VARCHAR2(4000)                          ;

  BEGIN

    po_error_code := 'OK';
    po_error_msg  := ''  ;
          ------------------------------ Bussiness Logic -------------------------

    INSERT INTO CRU.CF_CREDIT_UNIT(
                credit_unit_id            ,
                telco_code                ,
                credit_unit_code          ,
                credit_unit_type_code     ,
                behavior_type_code        ,
                --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
                --date_expiration_type_code ,
                round_method_code         ,
                --is_reseteable             ,
                --is_include_invoice        ,
                --cycles_quantity_expiration,
                --day_calendar_expiration   ,
                --expiration_days_quantity  ,
                --is_prorrateable           ,
                --<ASV Control: 299 11/01/2013 11:00:00>
                is_currency               ,
                integration_other_system  ,
                rollover_order            ,
                start_date                ,
                end_date                  ,
                status                    ,
                start_tran_id             ,
                start_tran_date           ,
                start_user_code           ,
                end_tran_id               ,
                end_tran_date             ,
                end_user_code             )
            VALUES (
                CRU.SEQ_CREDIT_UNIT.NEXTVAL ,
                pi_telco_code               ,
                pi_credit_unit_code         ,
                pi_credit_unit_type_code    ,
                pi_behavior_type_code       ,
                --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
                --UPPER(pi_date_expiration_type_code),
                pi_round_method_code        ,
                --UPPER(pi_is_reseteable)            ,
                --UPPER(pi_is_include_invoice)       ,
                --pi_cycles_quantity_expiration      ,
                --pi_day_calendar_expiration         ,
                --pi_expiration_days_quantity        ,
                --UPPER(pi_is_prorrateable)          ,
                --<ASV Control: 299 11/01/2013 11:00:00>
                pi_is_currency              ,
                pi_integration_other_system ,
                pi_rollover_order           ,
                --<ASV Control: 299 11/01/2013 11:00:00>
                pi_start_date               ,
                pi_end_date                 ,
                pi_status                   ,
                pi_start_tran_id            ,
                pi_start_tran_date          ,
                pi_start_user_code          ,
                pi_end_tran_id              ,
                pi_end_tran_date            ,
               pi_end_user_code             )
     RETURNING credit_unit_id INTO po_credit_unit_id ;

    ------------------------------ End of Bussiness Logic ---------------------
    po_error_code := 'OK';
    po_error_msg  := ''  ;

  EXCEPTION
    WHEN OTHERS THEN
      -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code := 'CRU-0106';--Critical error.||Error critico.
      v_param_in    :=------------------------------- variable parameters -------------------------------
                    'pi_telco_code: '                  || pi_telco_code                                      ||
                    '|pi_credit_unit_code: '           || pi_credit_unit_code                                ||
                    '|pi_credit_unit_type_code: '      || pi_credit_unit_type_code                           ||
                    '|pi_behavior_type_code: '         || pi_behavior_type_code                              ||
                    --<ASV Control: 299 11/01/2013 11:00:00 Modification of CRU, to dosage and consumption of credit units>
                    --'pi_date_expiration_type_code: '  || pi_date_expiration_type_code                       || '|' ||
                    '|pi_round_method_code: '          || pi_round_method_code                               ||
                    --'pi_is_reseteable: '              || pi_is_reseteable                                   || '|' ||
                    --'pi_is_include_invoice: '         || pi_is_include_invoice                              || '|' ||
                    --'pi_cycles_quantity_expiration: ' || pi_cycles_quantity_expiration                      || '|' ||
                    --'pi_day_calendar_expiration: '    || pi_day_calendar_expiration                         || '|' ||
                    --'pi_expiration_days_quantity: '   || pi_expiration_days_quantity                        || '|' ||
                    --'pi_is_prorrateable: '            || pi_is_prorrateable                                 || '|' ||
                    '|pi_is_currency: '                || pi_is_currency                                     ||
                    '|pi_integration_other_system: '   || pi_integration_other_system                        ||
                    '|pi_rollover_order: '             || pi_rollover_order                                  ||
                    --<ASV Control: 299 11/01/2013 11:00:00>
                    '|pi_start_date:'                  || TO_CHAR(pi_start_date,'DD/MM/YYYY HH24:MI:SS')     ||
                    '|pi_end_date:'                    || TO_CHAR(pi_end_date,'DD/MM/YYYY HH24:MI:SS')       ||
                    '|pi_status:'                      || pi_status                                          ||
                    '|pi_start_tran_id:'               || pi_start_tran_id                                   ||
                    '|pi_start_tran_date:'             || TO_CHAR(pi_start_tran_date,'DD/MM/YYYY HH24:MI:SS')||
                    '|pi_start_user_code:'             || pi_start_user_code                                 ||
                    '|pi_end_tran_id:'                 || pi_end_tran_id                                     ||
                    '|pi_end_tran_date:'               || TO_CHAR(pi_end_tran_date,'DD/MM/YYYY HH24:MI:SS')  ||
                    '|pi_end_user_code:'               || pi_end_user_code                                           ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code                                                   ,
                                      pi_tran_id      => pi_start_tran_id                                                ,
                                      pi_error_code   => po_error_code                                                   ,
                                      pi_error_msg    => po_error_msg                                                    ,
                                      pi_error_source => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));

  END CREATE_;


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
    v_package_procedure VARCHAR2(100) := v_package || '.UPDATE_END_DATE';
    v_param_in          VARCHAR2(4000);

  -- Declare Exceptions
    ERR_APP EXCEPTION;
  BEGIN
    -- Initiate log variables
    po_error_code := 'OK';
    po_error_msg  := ''  ;
    ------------------------------ Bussiness Logic -------------------------
    UPDATE CRU.CF_CREDIT_UNIT
    SET
        end_date        = pi_end_date     ,
        end_tran_id     = pi_end_tran_id  ,
        end_tran_date   = pi_end_tran_date,
        end_user_code   = pi_end_user_code
    WHERE credit_unit_id = pi_credit_unit_id 
      AND telco_code     = pi_telco_code  ;

   ------------------------------ End of Bussiness Logic ---------------------
    IF SQL%ROWCOUNT = 0 THEN

       po_error_code := 'CRU-0107';--Do not update any records||No se actualizo ningun registro
       RAISE ERR_APP;

    ELSIF SQL%ROWCOUNT = 1 THEN

       po_error_code := 'OK';
       po_error_msg  := '';

    ELSIF SQL%ROWCOUNT > 1 THEN

       po_error_code := 'CRU-0108';--Update is more than one records||Se actualizo mas de un registro
       RAISE ERR_APP;

    END IF;


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
                  '|pi_end_user_code: '   || pi_end_user_code                                    ;

     CRU.TX_TR_ERROR_LOG.RECORD_LOG(  pi_telco_code   => pi_telco_code                                                   ,
                                      pi_tran_id        => pi_end_tran_id,
                                      pi_error_code    => po_error_code,
                                      pi_error_msg     => po_error_msg,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));
    WHEN OTHERS THEN
    -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code:= 'CRU-0109'; --Uncontrolled Error.||Error no controlado.
      v_param_in :=---------- variable parameters ------------------
                  'pi_credit_unit_id:'    || pi_credit_unit_id                                   ||
                  '|pi_telco_code:'       || pi_telco_code                                       ||
                  '|pi_end_date:'         || TO_CHAR(pi_end_date,'DD/MM/YYYY HH24:MI:SS')        ||
                  '|pi_end_tran_id: '     || pi_end_tran_id                                      ||
                  '|pi_end_tran_date: '   || TO_CHAR( pi_end_tran_date, 'DD/MM/YYYY HH24:MI:SS') ||
                  '|pi_end_user_code: '   || pi_end_user_code                                    ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code                                                   ,
                                      pi_tran_id       => pi_end_tran_id,
                                      pi_error_code    => po_error_code,
                                      pi_error_msg     => po_error_msg,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));

  END UPDATE_END_DATE_;

   /*
  change Status a record for table CF_CREDIT_UNIT receiving all columns as parameters
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

  PROCEDURE CHANGE_STATUS_ ( pi_credit_unit_id   IN  CRU.CF_CREDIT_UNIT.credit_unit_id%TYPE   ,
                             pi_telco_code       IN  CRU.CF_CREDIT_UNIT.telco_code%TYPE       ,
                             pi_status           IN  CRU.CF_CREDIT_UNIT.status%TYPE           ,
                             pi_end_tran_id      IN  CRU.CF_CREDIT_UNIT.end_tran_id%TYPE      ,
                             pi_end_tran_date    IN  CRU.CF_CREDIT_UNIT.end_tran_date%TYPE    ,
                             pi_end_user_code    IN  CRU.CF_CREDIT_UNIT.end_user_code%TYPE    ,
                             po_error_code       OUT VARCHAR2                                 ,
                             po_error_msg        OUT VARCHAR2                                 )IS


  -- Mandatory variables for security and logs
    v_package_procedure VARCHAR2(100) := v_package || '.CHANGE_STATUS_';
    v_param_in          VARCHAR2(4000);
  -- Declare Exceptions
    ERR_APP EXCEPTION;
  BEGIN
    -- Initiate log variables
    po_error_code := 'OK';
    po_error_msg  := '';

    ------------------------------ Bussiness Logic -------------------------
    UPDATE CRU.CF_CREDIT_UNIT
    SET
        status          = pi_status         ,
        end_tran_id     = pi_end_tran_id    ,
        end_tran_date   = pi_end_tran_date  ,
        end_user_code   = pi_end_user_code
    WHERE credit_unit_id = pi_credit_unit_id 
      AND telco_code     = pi_telco_code;

   IF SQL%ROWCOUNT = 0 THEN

       po_error_code := 'CRU-0110';--Do not update any records||No se actualizo ningun registro
       RAISE ERR_APP;

    ELSIF SQL%ROWCOUNT = 1 THEN

       po_error_code := 'OK';
       po_error_msg  := '';

    ELSIF SQL%ROWCOUNT > 1 THEN

       po_error_code := 'CRU-0111';--Update is more than one records||Se actualizo mas de un registro
       RAISE ERR_APP;

    END IF;

    ------------------------------ End of Bussiness Logic ---------------------

    po_error_code := 'OK';
    po_error_msg  := ''  ;

  EXCEPTION
    WHEN ERR_APP THEN
                -- Initiate log variables
      v_param_in :=---------- variable parameters ------------------
                   'pi_credit_unit_id:'    || pi_credit_unit_id                                   ||
                   '|pi_telco_code:'       || pi_telco_code                                       ||
                   '|pi_status:'           || pi_status                                           ||
                   '|pi_end_tran_id: '     || pi_end_tran_id                                      ||
                   '|pi_end_tran_date: '   || TO_CHAR( pi_end_tran_date, 'DD/MM/YYYY HH24:MI:SS') ||
                   '|pi_end_user_code: '   || pi_end_user_code                                     ;

     CRU.TX_TR_ERROR_LOG.RECORD_LOG(  pi_telco_code   => pi_telco_code                                                   ,
                                      pi_tran_id        => pi_end_tran_id,
                                      pi_error_code    => po_error_code,
                                      pi_error_msg     => po_error_msg,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));
    WHEN OTHERS THEN
    -- Initiate log variables
      po_error_msg  := SUBSTR(SQLERRM, 1, 1000);
      po_error_code:= 'CRU-0112'; --Uncontrolled Error.||Error no controlado.
      v_param_in :=---------- variable parameters ------------------
                   'pi_credit_unit_id:'    || pi_credit_unit_id                                   ||
                   '|pi_telco_code:'       || pi_telco_code                                       ||
                   '|pi_status:'           || pi_status                                           ||
                   '|pi_end_tran_id: '     || pi_end_tran_id                                      ||
                   '|pi_end_tran_date: '   || TO_CHAR( pi_end_tran_date, 'DD/MM/YYYY HH24:MI:SS') ||
                   '|pi_end_user_code: '   || pi_end_user_code                                     ;

      CRU.TX_TR_ERROR_LOG.RECORD_LOG( pi_telco_code   => pi_telco_code                                                   ,
                                      pi_tran_id       => pi_end_tran_id,
                                      pi_error_code    => po_error_code ,
                                      pi_error_msg     => po_error_msg  ,
                                      pi_error_source  => SUBSTR(v_package_procedure || '(' || v_param_in || ')', 1, 4000));

  END CHANGE_STATUS_;

END CC_CF_CREDIT_UNIT;
/

