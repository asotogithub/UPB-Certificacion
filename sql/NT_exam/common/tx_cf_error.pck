CREATE OR REPLACE PACKAGE CRU.TX_CF_ERROR AS
   /******************************************************************************
    Implements basic functions of persistent storage for table TX_CF_ERROR
    %Company         Trilogy Software Bolivia
    %System          Omega Convergent Billing
    %Date            03/11/2010 9:36:10
    %Control         60079
    %Author          Abel Soto.
    %Version         1.0.0
    ****************************************************************************/

  FUNCTION GET_VERSION RETURN VARCHAR2;

  -- Get error message of table CF_ERROR receiving Code as parameters..
  FUNCTION GET_ERROR_MSG( pi_telco_code    IN  CRU.TR_ERROR_LOG.telco_code%TYPE:=NULL   ,
                          pi_tran_id       IN  CRU.CF_ERROR.tran_id%TYPE:=NULL   ,
                          pi_error_code    IN  CRU.CF_ERROR.error_code%TYPE:=NULL,
                          pi_language_code IN  CRU.CF_ERROR.language_code%TYPE) RETURN VARCHAR2;
END TX_CF_ERROR;
/

CREATE OR REPLACE PACKAGE BODY CRU.TX_CF_ERROR
IS
   /******************************************************************************
   Implements basic functions of persistent storage for table TX_CF_ERROR
   %Company         Trilogy Software Bolivia
   %System          Omega Convergent Billing
   %Date            03/11/2010 9:36:10
   %Control         60079
   %Author          Abel Soto"
   %Version         1.0.0
   ****************************************************************************/

  VERSION CONSTANT VARCHAR2(15) := '3.0.0';
  c_application_code CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_APPLICATION_CODE('APPLICATION_CRU',SYSDATE)  ;
  c_true             CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR('TELCO_GENERIC',c_application_code,'VALUE_BOOLEAN_TRUE',SYSDATE);


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
  Get error message of table CF_ERROR receiving Code as parameters
  %Date           01/06/2011 12:45:00 p.m.
  %Control        20281
  %Author         "Lizeth Flores"
  %Version        1.0.0
      %param          pi_telco_code         Code of operation.
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

  FUNCTION GET_ERROR_MSG( pi_telco_code    IN  CRU.TR_ERROR_LOG.telco_code%TYPE:=NULL   ,
                          pi_tran_id       IN  CRU.CF_ERROR.tran_id%TYPE:=NULL   ,
                          pi_error_code    IN  CRU.CF_ERROR.error_code%TYPE:=NULL,
                          pi_language_code IN  CRU.CF_ERROR.language_code%TYPE) RETURN VARCHAR2 IS

  --Constants
  c_default_language    CONSTANT ITF.CF_DOMAIN.DOMAIN_CODE%TYPE := ITF.TX_PUBLIC_CRU.GET_DOMAIN_VAR(pi_telco_code,c_application_code, 'DEFAULT_LANGUAGE',SYSDATE)        ;
  c_error_debug_mode    CONSTANT ITF.CF_PARAMETRIC.PARAMETRIC_VALUE %TYPE := ITF.TX_PUBLIC_CRU.GET_PARAMETER_VAR(pi_telco_code,c_application_code,'ERROR_DEBUG_MODE',SYSDATE);
  --declare variables
  v_out_error_message VARCHAR2(4000);
  v_error_message     VARCHAR2(1000);
  v_error      CRU.TR_ERROR_LOG%ROWTYPE;   
  v_error_code CRU.CF_ERROR.error_code%TYPE;
  BEGIN
    
    IF pi_language_code IS NOT NULL THEN
      IF pi_tran_id IS NOT NULL AND pi_error_code IS NULL THEN
        BEGIN
        SELECT *
          INTO v_error
          FROM CRU.TR_ERROR_LOG
         WHERE telco_code = pi_telco_code
           AND error_log_id = (SELECT MIN (error_log_id)
                                 FROM CRU.TR_ERROR_LOG
                                WHERE telco_code = pi_telco_code
                                  AND tran_id = pi_tran_id);
         v_error_code:= v_error.error_code;
        END; 
      ELSE
        v_error_code := pi_error_code;
      END IF;
      BEGIN
        SELECT e.error_message
          INTO v_error_message
          FROM CRU.CF_ERROR e
         WHERE e.language_code = pi_language_code
           AND e.error_code     = v_error_code;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            SELECT e.error_message
              INTO v_error_message
              FROM CRU.CF_ERROR e
             WHERE e.language_code = c_default_language
               AND e.error_code     = v_error_code;
      END;
      --trace
      IF pi_tran_id IS NOT NULL AND c_error_debug_mode = c_true THEN
         
        IF v_error.error_code IS NULL THEN
           BEGIN
             SELECT *
               INTO v_error
               FROM CRU.TR_ERROR_LOG
              WHERE error_log_id = (SELECT MIN (error_log_id)
                                       FROM CRU.TR_ERROR_LOG
                                      WHERE tran_id = pi_tran_id
                                        AND telco_code = pi_telco_code);
          END;
        END IF;  
        v_out_error_message := substr( v_error_message || v_error.error_message, 1, 4000);   
      ELSE
        v_out_error_message := substr( v_error_message, 1, 4000) ;
      END IF;
    ELSE  --pi_language_code
      v_out_error_message:= NULL;
    END IF;   
    RETURN v_out_error_message;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;


END TX_CF_ERROR;
/

