CREATE OR REPLACE PACKAGE CRU.TX_TR_ERROR_LOG AS
   /******************************************************************************
     Implements basic functions of persistent storage for table TR_ERROR_LOG
     %Company         Trilogy Software Bolivia
     %System          Omega Convergent Billing
     %Date            03/11/2010 9:36:10
     %Control         60079
     %Author          Abel Soto.
     %Version         1.1.0
   ******************************************************************************/

  FUNCTION GET_VERSION RETURN VARCHAR2;

  --Inserts a record in table TR_ERROR_LOG receiving all columns as parameters
  PROCEDURE RECORD_LOG( pi_telco_code   IN CRU.TR_ERROR_LOG.telco_code%TYPE   ,
                        pi_tran_id      IN CRU.TR_ERROR_LOG.tran_id%TYPE      ,
                        pi_error_code   IN CRU.TR_ERROR_LOG.ERROR_CODE%TYPE   ,
                        pi_error_msg    IN CRU.TR_ERROR_LOG.error_message%TYPE,
                        pi_error_source IN CRU.TR_ERROR_LOG.error_source%TYPE );

END TX_TR_ERROR_LOG;
/

CREATE OR REPLACE PACKAGE BODY CRU.TX_TR_ERROR_LOG
AS
   /******************************************************************************
      Implements basic functions of persistent storage for table TR_ERROR_LOG
     %Company         Trilogy Software Bolivia
     %System          Omega Convergent Billing
     %Date            03/11/2010 9:36:10
     %Control         60079
     %Author          Abel Soto.
     %Version         1.1.0
   ******************************************************************************/

  VERSION CONSTANT VARCHAR2(15) := '3.0.0';
  
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
  Inserts a record in table TR_ERROR_LOG receiving all columns as parameters
  %Date            03/11/2010 9:03:36
  %Control         60079
  %Author        "Abel Soto Vera"
  %Version       1.0.0
      %param         pi_telco_code       Code of operation
      %param         pi_tran_id          Transaction identifier
      %param         pi_error_code       Alphanumeric error code
      %param         pi_error_msg        Error Description
      %param         pi_error_source     Source where error was generated (function, procedure, package)
  */

  PROCEDURE RECORD_LOG( pi_telco_code   IN CRU.TR_ERROR_LOG.telco_code%TYPE   ,
                        pi_tran_id      IN CRU.TR_ERROR_LOG.tran_id%TYPE      ,
                        pi_error_code   IN CRU.TR_ERROR_LOG.ERROR_CODE%TYPE   ,
                        pi_error_msg    IN CRU.TR_ERROR_LOG.error_message%TYPE,
                        pi_error_source IN CRU.TR_ERROR_LOG.error_source%TYPE )  IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    CRU.CC_TR_ERROR_LOG.CREATE_(pi_telco_code  ,
                                pi_tran_id     ,
                                pi_error_code  ,
                                pi_error_msg   ,
                                pi_error_source);
    COMMIT;
  END;
END TX_TR_ERROR_LOG;
/

