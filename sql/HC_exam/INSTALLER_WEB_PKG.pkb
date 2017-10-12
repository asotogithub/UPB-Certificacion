CREATE OR REPLACE PACKAGE BODY ABEL_S.INSTALLER_WEB_PKG AS

 --NJJ 01/19/08 - CHANGED TO UPDATE THE START TIME OF ALL ORDERS AT THE LOCATION FOR THE TECHNICIAN AT THE SAME TIME
 --             - ALSO CHANGED TO INSERT A SO_CANDIDATE RECORD IN THE CASES WHEN ONE IS NOT ALREADY THERE WHEN ADDING OR ADD PROVISIONING A CABLE BOX.
 --LJH 05/26/10 - CHANGED TO ADD P_SVC_UID_PK TO BOX_MODEM_PKG.PR_ADD_ACCT AND BOX_MODEM_PKG.PR_REMOVE_ACCT PER HD CALL #95137
-- |@W:\Developers\LaWanda_h\Working\INSTALLER_WEB_PKG.pkb
-- MCV 11/16/10 -- changes for Cabble modem assignments- we no longer use broadband/metro tables, but service_assgnmts instead
-- NJJ 12-03-2010 CHANGED THE SWAP_ADSL FUNCTION WHEN CHECKING FOR A VALID DSLAM PORT TO SEND MESSAGE TO CALL PLANT
--                IF THE CURSOR IS NOT FOUND OR THE DSLAM FK IS NULL.  ADDED WHERE IS NOT NULL.
-- AC   03/25/11   For Cable Modem Assignment project.  Mod ADD_BOX, REMOVE_BOX, SWAP_BOX, ADD_BOX_REPROVISION, FN_ADD_EMTA, 
--                   FN_REMOVE_EMTA, FN_SWAP_EMTA, FN_MAC_ADDRESS_CHANGE, FN_SWAP_RSU_FOR_EMTA.  
--                   Add new p_development_action parameter to handle development testing.  Add GET_CELL_NBR
-- MCV 03/07/11 Added pas_opt_network in retreival of assignments
-- AC  10/24/11    Add SET_INSIDE_WIR_TYPE for two pair non twist project
--                 Mod FN_CLOSE_TROUBLE_TICKET to update HighSpeed data from TROUBLE_TICKETS.TRT_INSIDE_WIR_TYPES_UID_FK  To BROADBAND_SERVICES.BBS_INSIDE_WIR_TYPES_UID_FK 
--                 Mod CREATE_CS_ORDER to initialize data from BROADBAND_SERVICES.BBS_INSIDE_WIR_TYPES_UID_FK
-- MCV 12/28/11 adding link to email confirmation for TOS
-- AC  01/13/12 Quickfix to use CABLE_SO_COMMAND_PKG.CABLE_REFRESH_COMMANDS_FUN p_os_type = 'W' in SWAP_BOX, SWAP_BOX_REPROVISION
--                because the command actually gets run on Triad box (Windows)
-- AC  02/22/12 Mod FN_GET_SO_ASSIGNMENTS to include fields for METRO-ETH
-- LJH 04/04/12 Mod FN_CHECK_OTHER_SVC_CS_MS to exclude messages for BUS customer type per HD Call #118945
-- AC  05/29/12 Mod FN_GET_OPEN_SO_BY_TECH to include non scheduled type logic, mun_name, and first worked for Charter project
--              Mod ADD_BOX to skip inventory check if cable modem has CBM_CHARTER_FL = Y 
-- MCV 08/28/12 Adding ONU registration ID to fn_get_so_assgnmts for GPON Project
-- NJJ 09/19/12 ADD GDT_ALPHA18 TO FN_GET_OPEN_SO_BY_TECH FOR SENIOR TECH REPEAT TROUBLE FLAG
-- AC  12/21/12 Mod FN_GET_OPEN_SO_BY_TECH to  mmr_conversion_fl and add mmr_fl info to GDT_ALPHA19, and GDT_ALPHA20
--              Mod FN_GET_SO_ASSIGNMENTS
-- AC  01/07/13 Mod SWAP_BOX, ADD_BOX, and REMOVE_BOX to add optional parameter P_VALIDATE_ONLY_FL and to skip provisioning if an MMR cable box.  
--                Provisioning for this type of box is done through different mechanism 
--                Mod PR_INS_SO_ERROR_LOGS to add optional parameter P_SKIP_LOG_FL 
-- MCV 01/12/13 corrected fn_update_hsd to alos update other SO with same DSLAM port
-- NJJ 07/26/2013 Changes below in FN_GET_BOX_MODEM_QTY to use system_rules_pkg.get_char_value('EQUIPMENT' ...  to not hard code anymore, it used to hard code on the feature code itself
-- MCV 10/25/2013 add box, swap box, remove box should work like MMR now (BPP DNCS TO XML project)
-- MCV 05/20/14 BPP - ISP provisioning correction - Mac address change was loggin swt logs under ISP instead of TRIAD_XML
-- MCV 05/23/14 BPP - remove so wiring info if box marked as deleted in SO
-- NJ  07/11/14 Added logic to include routers
-- MCV 08/08/14 BPP- Revamped code for CableModem/MTA swaps and provisioning
-- NJJ 10/16/14 ADDED CPE equipment logic
-- NJJ 11/03/2014 Changed FN_CHECK_OTHER_SVC_CS_MS to check for CS orders for having to change to a new MTA to require a CS PLNT order for the voice
-- NJJ 01/08/2015 ADDED INSERT INTO CABLE MODEM FUNCTION
-- NJJ 03/31/2015 Changes for GPS Integration
-- MCV 05/13/2015 change to use system rules to email confirmation to customer
-- MCV 06/15/2015 Remove all emails to plantcoordinators@htc.hargray.com and box_modem_issues
-- SVA 12/04/2015 For  FN_ADD_ROUTER function add P_BILL_FL, and  P_TDP_UID_PK  parameters. and business logic.
-- SVA 12/04/2015 For  FN_REMOVE_ROUTER function add P_TDP_UID_PK  parameter and business logic
-- MCV 01/21/2016 FOr Fiber Overbuild project make sure to provision ISP on FIber conversion orders when adding Cable Modem, MTA or ONT and RG scanning of FTTH
-- MCV 03/25/16 Adding functions for commercial wifi controllers, aps and switches
--SVA 05/15/2017 WR-20170306-35468 Schedule Sundays.
                        --  Updated  NO_JOBS_BY_815 procedure

 CURSOR CHECK_PHN_SVC (CP_SLO_UID_PK IN NUMBER, CP_CUS_UID_PK IN NUMBER) IS
   SELECT 'X'
     FROM ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOCATIONS
    WHERE SSL_SERVICE_LOCATIONS_UID_FK = CP_SLO_UID_PK
      AND SVC_UID_PK = SSL_SERVICES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND STY_SYSTEM_CODE = 'PHN'
      AND SVC_END_DATE IS NULL
      AND SSL_END_DATE IS NULL
      AND ACC_CUSTOMERS_UID_FK = CP_CUS_UID_PK
  UNION
   SELECT 'X'
     FROM ACCOUNTS, SO, SO_STATUS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOC_SO
    WHERE SSX_SERVICE_LOCATIONS_UID_FK = CP_SLO_UID_PK
      AND SVO_UID_PK = SSX_SO_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND SVC_UID_PK = SVO_SERVICES_UID_FK
      AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND ACC_CUSTOMERS_UID_FK = CP_CUS_UID_PK
      AND STY_SYSTEM_CODE = 'PHN'
      AND SSX_END_DATE IS NULL
      AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID');
          
CURSOR GET_UNKNOWN_LOC IS
  SELECT IVL_UID_PK
    FROM INVENTORY_LOCATIONS
   WHERE IVL_DESCRIPTION = 'UNKNOWN';

CURSOR check_swt_logs(cp_seq_code IN VARCHAR, cp_date IN VARCHAR, cp_svo_uid_pk IN NUMBER) IS
  SELECT 'X'
  FROM swt_logs, swt_equipment
  WHERE sls_so_uid_fk = CP_SVO_UID_PK
    AND sls_success_fl = 'Y'
    AND sls_swt_equipment_uid_fk = seq_uid_pk
    AND seq_system_code = cp_seq_code
    AND swt_logs.created_date > SYSDATE-5/1440
    AND swt_logs.created_date >= TO_DATE(CP_DATE,'MM-DD-YYYY HH:MI:SS AM');

CURSOR check_swt_logs_error(cp_seq_code IN VARCHAR, cp_date IN VARCHAR, cp_svo_uid_pk IN NUMBER) IS
  SELECT sls_response, swt_logs.created_date
  FROM swt_logs, swt_equipment
  WHERE sls_so_uid_fk = cp_svo_uid_pk
    AND sls_success_fl = 'N'
    AND SLS_SWT_EQUIPMENT_UID_FK = seq_uid_pk
    AND SEQ_SYSTEM_CODE = cp_seq_code
    AND swt_logs.created_date > SYSDATE-5/1440
    AND swt_logs.created_date >= TO_DATE(CP_DATE,'MM-DD-YYYY HH:MI:SS AM')
    ORDER BY swt_logs.created_date;
      
V_ERROR        VARCHAR2(2000);
V_CMTS_MESSAGE VARCHAR2(2000);
V_LTG_MESSAGE  VARCHAR2(2000);
V_LEN_MESSAGE  VARCHAR2(2000);
V_RECALL       VARCHAR2(2000);
v_job_number   VARCHAR2(10);
V_ISP_SUCCESS_FL       VARCHAR2(20);
	v_resp            UTL_HTTP.resp;
	v_result         VARCHAR2 (10000) := NULL;
	v_error_msg       VARCHAR2 (4000);
	tbl_nodes         web_services_pkg.node_tbl;
	
	v_cmd             VARCHAR2(1000);
	   
	v_db VARCHAR2(30);  
	v_url_so           VARCHAR2 (1000)   :=   system_rules_pkg.get_char_value('CABLEBRIDGE','XML_PROV','SO');
	
	v_url_job          VARCHAR2 (1000)   :=   system_rules_pkg.get_char_value('CABLEBRIDGE','XML_PROV','QUERY_JOB');
	
	V_URL_SERVICE      VARCHAR2(1000) := system_rules_pkg.get_char_value('CABLEBRIDGE','XML_PROV','SERVICE');


C_SVC_UID_PK   NUMBER;
C_SVO_UID_PK   NUMBER;

/*-------------------------------------------------------------------------------------------------------------*/

-- Returns Y or N.
FUNCTION IS_PRODUCTION_DATABASE RETURN VARCHAR2 IS
  v_return   varchar2(1);  
BEGIN
  IF GET_DATABASE_FUN IN ('HES1','HES2','HES3','HES','PROD','TEST','TEST1','TEST2','TEST3','LDEV','DEV') THEN
    v_return := 'Y';
  ELSE
    v_return := 'N';
  END IF;
  return(v_return);
END  IS_PRODUCTION_DATABASE;

-- return info about running environment 
PROCEDURE GET_RUN_ENVIRONMENT(p_development_action     in varchar2,
                              p_is_production_database in out varchar2,
                              p_msg_suffix             in out varchar2) is
BEGIN
  p_is_production_database := IS_PRODUCTION_DATABASE;
  if p_is_production_database = 'Y' or (p_is_production_database = 'N' and p_development_action = C_DEV_PRODUCTION) then
    p_msg_suffix  := '';
  else
    p_msg_suffix  := ' (simulated in development)';
  end if;
END GET_RUN_ENVIRONMENT;



FUNCTION provision_triad_so_fun(p_svo_uid_pk IN NUMBER) RETURN VARCHAR2 IS

 v_success_fl VARCHAR2(1) := 'N';
 v_time VARCHAR2(100);
 v_sor_comment VARCHAR2(2000);
 v_char_date VARCHAR2(100);
 v_date DATE;
 
BEGIN
  v_char_date := TO_CHAR(SYSDATE,'MM-DD-YYYY HH:MI:SS AM');
  v_db := get_database_fun;


  IF NOT (v_db NOT IN ('HES','PROD') AND UPPER(v_url_so) LIKE '%PROD%') THEN
      v_cmd := v_url_so||p_svo_uid_pk;
      web_services_pkg.http_request_response (
                        v_cmd,
                        v_resp ,
                        v_result ,
                        v_error_msg,
                         '',
                        60);


     -- DBMS_OUTPUT.PUT_LINE(v_cmd);
     -- DBMS_OUTPUT.PUT_LINE(v_result);
      IF SUBSTR(TRIM(REPLACE(v_result,CHR(10),'')),1,1) = '0' THEN
             v_time := TO_CHAR(SYSDATE + .0015,'MM-DD-YYYY HH:MI:SS AM');
             WHILE SYSDATE < TO_DATE(v_time,'MM-DD-YYYY HH:MI:SS AM') LOOP
   
                  OPEN  check_swt_logs('CABLEBRIDGE',v_char_date , p_svo_uid_pk);
                  FETCH check_swt_logs INTO v_sor_comment;
                  IF check_swt_logs%NOTFOUND THEN
                        CLOSE check_swt_logs;
                        OPEN check_swt_logs_error('CABLEBRIDGE', v_char_date, p_svo_uid_pk);
                        FETCH check_swt_logs_error INTO v_sor_comment, v_date;
                        IF CHECK_SWT_LOGS_ERROR%FOUND THEN   
                            v_success_fl := 'N';
                            EXIT;
                        END IF;
                        CLOSE check_swt_logs_error;                       
                  ELSE
                    CLOSE check_swt_logs;
                    v_success_fl := 'Y';
                    EXIT;
                  END IF;
                  
             END LOOP;
      ELSE
         v_success_fl := 'N';
      END IF;
 ELSE
   v_success_fl := 'Y';
 END IF;
 
 RETURN v_success_fl;
 
END;


FUNCTION provision_triad_service_fun(p_svc_uid_pk NUMBER, p_type VARCHAR2, p_job_number OUT VARCHAR2) RETURN VARCHAR2 IS

 v_success_fl VARCHAR2(20) := 'N';
 v_time VARCHAR2(100);

BEGIN

 v_db := get_database_fun;

 IF NOT (v_db NOT IN ('HES','PROD') AND UPPER(v_url_service) LIKE '%PROD%') THEN
                     
      --dbms_lock.sleep(1);
                         
      v_cmd := REPLACE((v_url_service),'<>', p_svc_uid_pk);
      IF p_type IS NOT NULL THEN 
        v_cmd := v_cmd||p_type;
      END IF;
      web_services_pkg.http_request_response (v_cmd,
                                              v_resp ,
                                              v_result ,
                                              v_error_msg,
                                              '',
                                              60);
                                                                        
                      
      DBMS_OUTPUT.PUT_LINE(v_cmd);
      DBMS_OUTPUT.PUT_LINE(v_result);
      IF SUBSTR(TRIM(REPLACE(v_result,CHR(10),'')),1,1) = '0' THEN
        p_job_number := SUBSTR(v_result,3);
        v_cmd := v_url_job||p_job_number;                    
        v_time := TO_CHAR(SYSDATE + .001,'MM-DD-YYYY HH:MI:SS AM');
        WHILE SYSDATE < TO_DATE(v_time,'MM-DD-YYYY HH:MI:SS AM')
        LOOP
            web_services_pkg.http_request_response (v_cmd,
                         v_resp ,
                         v_result ,
                         v_error_msg,
                         '',
                         60);
     
              IF SUBSTR(TRIM(REPLACE(v_result,CHR(10),'')),1,1) = '1' THEN 
                 v_success_fl := 'SUCCESS';
                 EXIT;
              ELSIF SUBSTR(TRIM(REPLACE(v_result,CHR(10),'')),1,2) = '-1' THEN
                 v_success_fl := 'N';
                 EXIT;
              END IF;
        END LOOP;
     ELSE
       v_success_fl := 'N';
     END IF;
 ELSE
   v_success_fl:='SUCCESS';
 END IF;

 RETURN v_success_fl;
END;

 -- to get list of fields to display on the screen for the tech to see their open orders
FUNCTION FN_GET_OPEN_SO_BY_TECH (P_EMP_UID_PK IN NUMBER)

-- MCV 04/04/2016 adding bundle code and wifi controller flag

RETURN generic_data_table PIPELINED IS

 CURSOR GET_INFO IS
 SELECT CUS_UID_PK,
        CUS_FNAME||DECODE(CUS_FNAME,NULL,'',' ')||CUS_LNAME CUS_NAME,
        SVO_UID_PK,
        SVC_UID_PK,
        SLO_UID_PK,
        SERV_LOCS.GET_SERV_LOC(SLO_UID_PK) LOCATION,
        SOT_CODE,
        STY_CODE,
        TO_DATE(TO_CHAR(SDS_SCHEDULE_TIME,'MM-DD-YYYY HH:MI AM'),'MM-DD-YYYY HH:MI AM') SCHEDULE_TIME,
        EMP_UID_PK,
        EMP_FNAME||' '||EMP_LNAME EMP_NAME,
        CUS_LOGIN,
        SDS_UID_PK,
        SDS_WORK_START_TIME,
        SDS_COMMENT,
        MUN_NAME,
        SDS_FIRST_WORKED_FL,
        ' ' START_DATE
   FROM CUSTOMERS, ACCOUNTS, EMPLOYEES, SO_LOADINGS, SO, SO_STATUS, SO_TYPES, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOC_SO, 
        service_locations,  municipalities
  WHERE SVO_UID_PK = SDS_SO_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SVO_UID_PK = SSX_SO_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND EMP_UID_PK = SDS_EMPLOYEES_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
    AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID')
    AND SDS_COMPLETED_FL = 'N'
    AND SSX_END_DATE IS NULL
    AND SDS_SCHEDULE_DATE = TRUNC(SYSDATE)
    AND SDS_EMPLOYEES_UID_FK IS NOT NULL
    AND SDS_EMPLOYEES_UID_FK = NVL(P_EMP_UID_PK, SDS_EMPLOYEES_UID_FK)
    AND SLO_UID_PK           = SSX_SERVICE_LOCATIONS_UID_FK
    AND MUN_UID_PK           = SLO_MUNICIPALITIES_UID_FK
 UNION
 SELECT CUS_UID_PK,
        CUS_FNAME||DECODE(CUS_FNAME,NULL,'',' ')||CUS_LNAME CUS_NAME,
        SVO_UID_PK,
        SVC_UID_PK,
        SLO_UID_PK,
        SERV_LOCS.GET_SERV_LOC(SLO_UID_PK) LOCATION,
        SOT_CODE,
        STY_CODE,
        TO_DATE(TO_CHAR(SDS_SCHEDULE_TIME,'MM-DD-YYYY HH:MI AM'),'MM-DD-YYYY HH:MI AM') SCHEDULE_TIME,
        EMP_UID_PK,
        EMP_FNAME||' '||EMP_LNAME EMP_NAME,
        CUS_LOGIN,
        SDS_UID_PK,
        SDS_WORK_START_TIME,
        SDS_COMMENT,
        MUN_NAME,
        SDS_FIRST_WORKED_FL,
        ' ' START_DATE
   FROM CUSTOMERS, ACCOUNTS, EMPLOYEES, SO_LOADINGS, SO, SO_STATUS, SO_TYPES, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOCATIONS, 
        service_locations,  municipalities
  WHERE SVO_UID_PK = SDS_SO_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SVC_UID_PK = SSL_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND EMP_UID_PK = SDS_EMPLOYEES_UID_FK
    AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
    AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID')
    AND SDS_COMPLETED_FL = 'N'
    AND SOT_SYSTEM_CODE != 'MS'
    AND SSL_END_DATE IS NULL
    AND SDS_SCHEDULE_DATE = TRUNC(SYSDATE)
    AND SDS_EMPLOYEES_UID_FK IS NOT NULL
    AND SDS_EMPLOYEES_UID_FK = NVL(P_EMP_UID_PK, SDS_EMPLOYEES_UID_FK) 
    AND SLO_UID_PK           = SSL_SERVICE_LOCATIONS_UID_FK
    AND MUN_UID_PK           = SLO_MUNICIPALITIES_UID_FK
  UNION
  SELECT CUS_UID_PK,
         CUS_FNAME||DECODE(CUS_FNAME,NULL,'',' ')||CUS_LNAME CUS_NAME,
         TRT_UID_PK,
         SVC_UID_PK,
         SLO_UID_PK,
         SERV_LOCS.GET_SERV_LOC(SLO_UID_PK) LOCATION,
         NULL SOT_CODE,
         STY_CODE,
         NVL(TDP_SCHEDULE_TIME,TDP_DATE) SCHEDULE_TIME,
         EMP_UID_PK,
         EMP_FNAME||' '||EMP_LNAME EMP_NAME,
         NULL CUS_LOGIN,
         TDP_UID_PK,
         TDP_START_WORK_TIME,
         '' SDS_COMMENT,
         MUN_NAME,
         '' SDS_FIRST_WORKED_FL,
         TO_CHAR(TRT_START_DATE,'MM-DD-YYYY') START_DATE
    FROM CUSTOMERS, ACCOUNTS, SERVICES, EMPLOYEES, TROUBLE_TICKETS, TROUBLE_DISPATCHES, TRBL_DSP_GRPS, TRBL_DSP_TECHS, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOCATIONS, 
        service_locations,  municipalities
   WHERE TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
     AND SVC_UID_PK = TRT_SERVICES_UID_FK
     AND SVC_UID_PK = SSL_SERVICES_UID_FK
     AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
     AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
     AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
     AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
     AND TDT_UID_PK = TDP_TRBL_DSP_TECHS_UID_FK
     AND EMP_UID_PK = TDT_EMPLOYEES_UID_FK
     AND TDG_UID_PK = TDP_TRBL_DSP_GRPS_UID_FK
     AND TDG_CODE NOT IN ('J','M','K')
     AND TDP_END_WORK_TIME IS NULL
     AND SSL_END_DATE IS NULL
     AND TRT_STATUS = 'D'
     AND (TRUNC(TDP_START_WORK_DATE) = TRUNC(SYSDATE) OR TRUNC(TDP_SCHEDULE_DATE) = TRUNC(SYSDATE))
     AND EMP_UID_PK = NVL(P_EMP_UID_PK, EMP_UID_PK)
     AND SLO_UID_PK           = SSL_SERVICE_LOCATIONS_UID_FK
     AND MUN_UID_PK           = SLO_MUNICIPALITIES_UID_FK ;

CURSOR CUS_AGREEMENTS(P_CUS_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER) IS
  SELECT 'Y'
    FROM CUS_AGREEMENTS, CUS_AGR_SERVICES
   WHERE CAM_CUSTOMERS_UID_FK = P_CUS_UID_PK
     AND CAM_UID_PK = CAE_CUS_AGREEMENTS_UID_FK
     AND CAE_SERVICES_UID_FK = P_SVC_UID_PK
     AND CAM_TERMS_ACCEPTED_FL = 'Y';

CURSOR CUS_AGR_NOT_ACCEPT(P_CUS_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER) IS
  SELECT 'Y'
    FROM CUS_AGREEMENTS, CUS_AGR_SERVICES
   WHERE CAM_CUSTOMERS_UID_FK = P_CUS_UID_PK
     AND CAM_UID_PK = CAE_CUS_AGREEMENTS_UID_FK
     AND CAE_SERVICES_UID_FK = P_SVC_UID_PK
     AND CAM_TERMS_ACCEPTED_FL = 'N';

 cursor svt_code(p_svo_uid_pk in number) is
   select svt_code
     from off_serv_subs, serv_sub_types, services, so
    where osb_uid_pk = svo_off_serv_subs_uid_fk
      and svt_uid_pk = osb_serv_sub_types_uid_fk
      and svc_uid_pk = svo_services_uid_fk
      and svo_uid_pk = p_svo_uid_pk;

 cursor svc_svt_code(p_svo_uid_pk in number) is
   select svt_code
     from off_serv_subs, serv_sub_types, services, so
    where osb_uid_pk = svc_off_serv_subs_uid_fk
      and svt_uid_pk = osb_serv_sub_types_uid_fk
      and svc_uid_pk = svo_services_uid_fk
      and svo_uid_pk = p_svo_uid_pk;

 cursor svc_svt_svc(p_svc_uid_pk in number) is
   select svt_code
     from off_serv_subs, serv_sub_types, services
    where osb_uid_pk = svc_off_serv_subs_uid_fk
      and svt_uid_pk = osb_serv_sub_types_uid_fk
      and svc_uid_pk = p_svc_uid_pk;

 CURSOR CONNECTIONS_INCENTIVE(P_CUS_UID_PK IN NUMBER) IS
   SELECT ABS(RTS_AMOUNT)
     FROM SERVICES, SO, RATES, FEATURES, OFFICE_SERV_FEATS, SO_FEATURES, ACCOUNTS
    WHERE OSF_UID_PK = SOF_OFFICE_SERV_FEATS_UID_FK
      AND FTP_UID_PK = OSF_FEATURES_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND SVC_UID_PK = SVO_SERVICES_UID_FK
      AND FTP_UID_PK = RTS_FEATURES_UID_FK
      AND RTS_END_DATE IS NULL
      AND SVO_UID_PK = SOF_SO_UID_FK
      AND ACC_CUSTOMERS_UID_FK = P_CUS_UID_PK
      AND RTRIM(LTRIM(FTP_CODE)) IN ('CXLCR', 'KCXLCR')
      AND SOF_ACTION_FL = 'A';

 CURSOR BBS_SO(P_SVO_UID_PK IN NUMBER) IS
 SELECT 'X'
   FROM SO_ASSGNMTS
  WHERE SON_SO_UID_FK = P_SVO_UID_PK
    AND SON_CABLE_MODEMS_UID_FK IS NOT NULL;

 CURSOR MTA_BOX_FOUND(P_SVC_UID_PK IN NUMBER) IS
   SELECT 'X'
     FROM MTA_SERVICES, SERVICE_ASSGNMTS, MTA_PORTS, MTA_EQUIP_UNITS
    WHERE SVA_SERVICES_UID_FK = P_SVC_UID_PK
      AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
      AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
      AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND MEU_MTA_BOXES_UID_FK IS NOT NULL;

 CURSOR MTA_SO_FOUND(P_SVO_UID_PK IN NUMBER) IS
   SELECT 'X'
     FROM MTA_SO, SO_ASSGNMTS, MTA_PORTS, MTA_EQUIP_UNITS
    WHERE SON_SO_UID_FK = P_SVO_UID_PK
      AND SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
      AND MTP_UID_PK = MTO_MTA_PORTS_UID_FK
      AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK;

  cursor cur_catv_so (p_svo_pk  number) is
    select cts_conversion_fl, cts_mmr_fl
      from catv_so 
     where cts_so_uid_fk = p_svo_pk ;

  cursor cur_catv_svc (p_svc_pk  number) is
    select cbs_mmr_fl 
      from catv_services 
     where cbs_services_uid_fk =  p_svc_pk;
     
  CURSOR get_so_bundle(p_svo_pk NUMBER) IS
   SELECT ftp_code
     FROM features, so
    WHERE ftp_uid_pk = svo_features_uid_fk
      AND svo_uid_pk = p_svo_pk;
      
  CURSOR get_svc_bundle(p_svc_pk NUMBER) IS
   SELECT ftp_code
     FROM features, services
    WHERE ftp_uid_pk = svc_features_uid_fk
      AND svc_uid_pk = p_svc_pk;
  

      
  rec_catv_so     cur_catv_so%rowtype;
  rec_catv_svc    cur_catv_svc%rowtype;
  
  v_bundle_code   VARCHAR2(12);

 v_rec                 generic_data_type;
 rec                   GET_INFO%rowtype;
 v_count               number := 0;
 v_login_found         varchar2(1);
 v_terms_accepted      varchar2(1) := 'N';
 v_contract_end_date   date;
 v_sof_uid_pk          number;
 v_term_amount         number;
 v_char_end_date       varchar2(20);
 v_contract_ftp_uid_pk NUMBER;
 v_contract_ftp_code   varchar2(80);
 V_SVT_SYSTEM_CODE     varchar2(80);
 V_CONNECTION_INC_AMT  NUMBER;
 V_SLO_EMTA_FL         varchar2(1);
 V_EMTA_TYPE_FL        varchar2(1);
 V_DUMMY               VARCHAR2(1);


BEGIN

 OPEN GET_INFO;
 LOOP
    FETCH GET_INFO into rec;
    EXIT WHEN GET_INFO%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_number1    := rec.cus_uid_pk;          -- customers pk
     v_rec.gdt_alpha1     := rec.cus_name;            -- customer name
     v_rec.gdt_number2    := rec.svo_uid_pk;          -- SO pk / or TRT pk in case of trouble tickets
     v_rec.gdt_number3    := rec.slo_uid_pk;          -- service_locations pk
     v_rec.gdt_alpha2     := rec.location;            -- service location
     v_rec.gdt_alpha3     := rec.sot_code;            -- so_types code
     v_rec.gdt_alpha4     := rec.sty_code;            -- service type code
     v_rec.gdt_date2      := rec.schedule_time;       -- schedule time of the appointment
     v_rec.gdt_number4    := rec.emp_uid_pk;          -- employee pk
     v_rec.gdt_number8    := rec.svc_uid_pk;          -- services pk
     v_rec.gdt_alpha5     := rec.emp_name;            -- employee name
     v_rec.gdt_date1      := rec.sds_work_start_time; -- start work time of the appointment or loading

     -- non scheduled type logic.  this field is always null unless SDS_COMMENT in ('TAG', 'HTH', or 'SWING DROP')
     --  it is used in IWP
     IF rec.sds_comment in ('TAG', 'HTH', 'SWING DROP')  then
       v_rec.gdt_alpha15    := rec.sds_comment;
     END IF;
     v_rec.gdt_alpha16    := rec.mun_name;
     v_rec.gdt_alpha17    := rec.sds_first_worked_fl;

     --check for as customer login
     IF rec.cus_login IS NOT NULL THEN
        v_login_found := 'Y';
     ELSE
        v_login_found := 'N';
     END IF;
     v_rec.gdt_alpha6     := v_login_found;

     --job pk
     v_rec.gdt_number5    := rec.sds_uid_pk;

     --Check if the terms and conditions have already been accepted.
     OPEN CUS_AGREEMENTS(rec.cus_uid_pk, rec.svc_uid_pk);
     FETCH CUS_AGREEMENTS INTO v_terms_accepted;
     IF CUS_AGREEMENTS%NOTFOUND THEN
        OPEN CUS_AGR_NOT_ACCEPT(rec.cus_uid_pk, rec.svc_uid_pk);
        FETCH CUS_AGR_NOT_ACCEPT INTO v_terms_accepted;
        IF CUS_AGR_NOT_ACCEPT%NOTFOUND THEN
           v_terms_accepted := NULL;
        ELSE
           v_terms_accepted := 'N';
        END IF;
        CLOSE CUS_AGR_NOT_ACCEPT;
     END IF;
     CLOSE CUS_AGREEMENTS;

     v_rec.gdt_alpha7     := v_terms_accepted;
     --

     --THE FOLLOWING WILL CHECK IF THE TERMS AND CONDITIONS ARE EVEN NEEDED FOR THIS CUSTOMER
     --CURRENTLY THEY ARE IF PART OF THE ORDER REQUIRES NEW SERVICE
     IF INSTALLER_WEB_PKG.TERMS_CONDITIONS_NEEDED(rec.cus_uid_pk) THEN
        v_rec.gdt_alpha8 := 'Y';
     ELSE
        v_rec.gdt_alpha8 := 'N';  --THIS WILL NEED TO BE CHANGED BACK AFTER TESTING
     END IF;
     --

     --THIS WILL GET THE CONTRACT INFORMATION TO PASS THROUGH
     IF INSTALLER_WEB_PKG.CONTRACT_NEEDED(rec.cus_uid_pk, v_contract_end_date, v_sof_uid_pk, v_term_amount, v_contract_ftp_uid_pk, v_contract_ftp_code) THEN
        v_rec.gdt_number6 := v_term_amount;
        v_char_end_date := to_char(v_contract_end_date,'mm-dd-yyyy');
        v_rec.gdt_alpha9 := v_char_end_date;
     ELSE
        v_rec.gdt_number6 := NULL;
        v_rec.gdt_alpha9 := NULL;
     END IF;
     --

     --get the sub type of the service
     OPEN SVT_CODE(rec.svo_uid_pk);
     FETCH SVT_CODE INTO V_SVT_SYSTEM_CODE;
      IF svt_code%NOTFOUND THEN
         open svc_svt_code(rec.svo_uid_pk);
         fetch svc_svt_code into V_SVT_SYSTEM_CODE;
         if svc_svt_code%notfound then
            open svc_svt_svc(rec.svc_uid_pk);
                        fetch svc_svt_svc into V_SVT_SYSTEM_CODE;
            close svc_svt_svc;
         end if;
         close svc_svt_code;
     END IF;
     CLOSE SVT_CODE;

     v_rec.gdt_alpha10 := V_SVT_SYSTEM_CODE;

     --THE FOLLOWING WILL CHECK IF THE CONTRACT SHOULD DISPLAY PRORATED FOR THE TERMINATION AMOUNT
     IF v_contract_ftp_code in ('CXCT1Y','CXCT2Y') THEN
        v_rec.gdt_alpha11 := 'Y';
     ELSE
        v_rec.gdt_alpha11 := 'N';
     END IF;

     --THE FOLLOWING WILL CHECK IF THE CONNECTIONS INCENTIVE SECTION WILL NEED TO DISPLAY ON THE REPORT
     OPEN CONNECTIONS_INCENTIVE(rec.cus_uid_pk);
     FETCH CONNECTIONS_INCENTIVE INTO V_CONNECTION_INC_AMT;
     IF CONNECTIONS_INCENTIVE%NOTFOUND THEN
        V_CONNECTION_INC_AMT := NULL;
     END IF;
     CLOSE CONNECTIONS_INCENTIVE;
     v_rec.gdt_number7 := V_CONNECTION_INC_AMT;
     --

     --SET THE TYPE FIELD TO LET US KNOW IF IT IS A TROUBLE OR SERVICE ORDER
     IF rec.sot_code IS NULL THEN
        v_rec.gdt_alpha12 := 'T';
        IF TROUBLE_TKT_SCHED_PKG.FN_SENIOR_TECH_NEEDED(rec.svc_uid_pk, rec.start_date) = 'Y' THEN
           v_rec.gdt_alpha18 := 'Y';
        ELSE
           v_rec.gdt_alpha18 := 'N';
        END IF;
     ELSE
        v_rec.gdt_alpha12 := 'S';
        v_rec.gdt_alpha18 := 'N';
     END IF;

     --MARK IF THE ORDER COULD REQUIRE EQUIPMENT ADDITIONS/CHANGES/REMOVES
     --IF V_SVT_SYSTEM_CODE != 'IPTV' AND rec.sty_code = 'CABLE TV' THEN
     IF rec.sty_code = 'CABLE TV' THEN
        v_rec.gdt_alpha13 := 'Y'; 
        if V_SVT_SYSTEM_CODE = 'IPTV' then        -- AC  12/21/12  check for iptv / mmr
          -- need to find out conversion and mmr flags

          rec_catv_so    := null;
          rec_catv_svc   := null;
          open  cur_catv_so(rec.svo_uid_pk);
          fetch cur_catv_so into rec_catv_so;
          close cur_catv_so;
          if rec_catv_so.cts_conversion_fl is null then  
            -- if a trouble ticket, get info from service
            open cur_catv_svc(rec.svc_uid_pk);
            fetch cur_catv_svc into rec_catv_svc;
            close cur_catv_svc;
            v_rec.gdt_alpha19  := 'N' ;
            v_rec.gdt_alpha20  := rec_catv_svc.cbs_mmr_fl  ;
          else
            v_rec.gdt_alpha19  := rec_catv_so.cts_conversion_fl ;
            v_rec.gdt_alpha20  := rec_catv_so.cts_mmr_fl  ;
          end if;

        end if;
     ELSE
        IF V_SVT_SYSTEM_CODE IN ('CABLE MODEM','RFOG','ADSL','VDSL') OR rec.sty_code = 'METRO-ETH' THEN
           v_rec.gdt_alpha13 := 'Y';
        ELSE
           V_DUMMY := 'N';
           OPEN BBS_SO(rec.svo_uid_pk);
           FETCH BBS_SO INTO V_DUMMY;
           IF BBS_SO%NOTFOUND THEN
              V_DUMMY := 'N';
           ELSE
              V_DUMMY := 'Y';
           END IF;
           CLOSE BBS_SO;
           --1.  CS/MS ORDER
           --2.  CABLE MODEM FOUND ON THE HIGH SPEED SERVICE, WHICH NEEDS TO BE REMOVED
           --3.  PACKET CABLE WILL BE REPLACING THE CABLE MODEM SO PACKET CABLE IS THE SUB TYPE ON THE ORDER
           IF rec.sot_code IN ('CS','MS') AND V_DUMMY = 'Y' THEN
              v_rec.gdt_alpha13 := 'Y';
           ELSE
              v_rec.gdt_alpha13 := 'N';
           END IF;
        END IF;
     END IF;

     V_SLO_EMTA_FL := FN_EMTA_LOCATION(rec.slo_uid_pk);

     V_EMTA_TYPE_FL := 'N';
     IF rec.sty_code = 'TELEPHONE' AND V_SLO_EMTA_FL = 'Y' THEN
        V_EMTA_TYPE_FL := 'T';
     ELSIF V_SVT_SYSTEM_CODE IN ('PACKET CABLE','CABLE MODEM','RFOG') AND V_SLO_EMTA_FL = 'Y' THEN
        --NJJ 06/10/2010 --MADE A CHANGE T0 THE EMTA_TYPE BEING SET TO 'B' IN ALL CASES BEACUSE OF THE CASE WHEN IT MAY BE SET UP FOR PACKET CABLE BUT AN RSU IS ALSO FOUND AT THE LOCATION
        OPEN CHECK_PHN_SVC(rec.slo_uid_pk, rec.cus_uid_pk);
        FETCH CHECK_PHN_SVC INTO V_DUMMY;
        IF CHECK_PHN_SVC%NOTFOUND THEN
           v_rec.gdt_alpha13 := 'Y';  --also update equipment possible flag to 'Y'
           V_EMTA_TYPE_FL := 'B';
        ELSE
           V_EMTA_TYPE_FL := 'B';
        END IF;
        CLOSE CHECK_PHN_SVC;
     ELSIF rec.sty_code in ('HIGH SPEED','TELEPHONE') THEN
        IF V_SVT_SYSTEM_CODE IN ('PACKET CABLE','RFOG') THEN
           V_EMTA_TYPE_FL := 'N';
           V_SVT_SYSTEM_CODE := 'CABLE MODEM';
           v_rec.gdt_alpha10 := V_SVT_SYSTEM_CODE;
           v_rec.gdt_alpha13 := 'Y';
        END IF;
     ELSE
        V_EMTA_TYPE_FL := 'N';
     END IF;

     --IF FN_RFOG_LOCATION(rec.slo_uid_pk) = 'Y' THEN
        --V_EMTA_TYPE_FL := 'F';
     --END IF;

     IF (V_EMTA_TYPE_FL IN ('H','T') OR (V_EMTA_TYPE_FL = 'B' AND V_SVT_SYSTEM_CODE IN ('CABLE MODEM','RFOG','PACKET CABLE'))) AND rec.sot_code IS NOT NULL THEN --CHECK FOR MTA_SO RECORD AND IF NOT FOUND DO NTO CONSIDER IT FOR A MTA TO BE ADDED
        OPEN MTA_SO_FOUND(rec.svo_uid_pk);
        FETCH MTA_SO_FOUND INTO V_DUMMY;
        IF MTA_SO_FOUND%NOTFOUND THEN
           OPEN MTA_BOX_FOUND(rec.svc_uid_pk);
           FETCH MTA_BOX_FOUND INTO V_DUMMY;
           IF MTA_BOX_FOUND%NOTFOUND THEN 
              V_EMTA_TYPE_FL := 'N';
           END IF;
           CLOSE MTA_BOX_FOUND;
           IF V_SVT_SYSTEM_CODE IN ('RFOG','PACKET CABLE') AND rec.sot_code = 'MS' THEN           
              V_SVT_SYSTEM_CODE := 'CABLE MODEM';
              v_rec.gdt_alpha10 := V_SVT_SYSTEM_CODE;
           END IF;
        END IF;
        CLOSE MTA_SO_FOUND;
     END IF;
     v_rec.gdt_alpha14 := V_EMTA_TYPE_FL;
     
     v_bundle_code := NULL;
     -- MCV 04/04/2016 retrieve bundle code
     IF rec.sot_code IN ('NS','CS','RI','BC','MS','CT') THEN
       OPEN get_so_bundle(rec.svo_uid_pk);
       FETCH get_so_bundle INTO v_bundle_code;
       CLOSE get_so_bundle;    
     ELSE
       OPEN get_svc_bundle(rec.svo_uid_pk);
       FETCH get_svc_bundle INTO v_bundle_code;
       CLOSE get_svc_bundle;       
     END IF;
     
     v_rec.gdt_alpha21 := v_bundle_code;
     
     IF SYSTEM_RULES_PKG.GET_CHAR_VALUE('COMM WIFI','PREM CFG','BUNDLES') LIKE '%'||v_bundle_code||'%' AND v_bundle_code IS NOT NULL THEN
        v_rec.gdt_alpha22 := 'Y'; -- display comm wifi tabs
        v_rec.gdt_alpha23 := 'Y'; -- display controllers
     ELSIF SYSTEM_RULES_PKG.GET_CHAR_VALUE('COMM WIFI','CLOUD CFG','BUNDLES') LIKE '%'||v_bundle_code||'%' AND v_bundle_code IS NOT NULL THEN
        v_rec.gdt_alpha22 := 'Y';
        v_rec.gdt_alpha23 := 'N';
     ELSE
                v_rec.gdt_alpha22 := 'N';
                v_rec.gdt_alpha23 := 'N';   
        
     END IF;

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE GET_INFO;

RETURN;

END FN_GET_OPEN_SO_BY_TECH;

/*-------------------------------------------------------------------------------------------------------------*/

FUNCTION TEST_ADD_ONE(P_NUMBER_IN IN NUMBER)

RETURN NUMBER IS

BEGIN

RETURN P_NUMBER_IN + 1;

END TEST_ADD_ONE;

FUNCTION FN_CLOSE_ROUTE_ORDERS(P_EMP_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_COMMENT IN VARCHAR)

RETURN VARCHAR IS

--ZONE
CURSOR check_zone IS
SELECT zon_code
    FROM services,
             so,
             zones,
             streets,
             service_locations,
             serv_serv_locations
 WHERE svo_services_uid_fk          = svc_uid_pk
     AND str_zones_uid_fk             = zon_uid_pk
     AND slo_streets_uid_fk                     = str_uid_pk
     AND ssl_services_uid_fk          = svc_uid_pk
     AND ssl_service_locations_uid_fk = slo_uid_pk
     AND svo_uid_pk                   = p_svo_uid_pk
UNION
SELECT zon_code
 FROM  services,
             so,
             zones,
             streets,
             serv_serv_loc_so,
             service_locations
 WHERE svo_services_uid_fk          = svc_uid_pk
     AND str_zones_uid_fk             = zon_uid_pk
     AND ssx_service_locations_uid_fk = slo_uid_pk
     AND ssx_so_uid_fk                = svo_uid_pk
     AND slo_streets_uid_fk           = str_uid_pk
     AND svo_uid_pk                   = p_svo_uid_pk;

CURSOR SERV_SUB_TYPE IS
  SELECT OSB_OFFICE_SERV_TYPES_UID_FK, SVT_SYSTEM_CODE
  FROM OFF_SERV_SUBS, SO, SERV_SUB_TYPES
  WHERE OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
    AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;

CURSOR GET_SO_INFO IS
 SELECT BSO_SYSTEM_CODE, SOT_SYSTEM_CODE, STY_SYSTEM_CODE, CUS_UID_PK, SVC_UID_PK, OST_UID_PK, CUS_CLEC_FL
   FROM BUSINESS_OFFICES, CUSTOMERS, ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SO_TYPES, SO
  WHERE BSO_UID_PK = CUS_BUSINESS_OFFICES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;

 cursor get_so_loc is
        select ssx_service_locations_uid_fk
          from service_locations, serv_serv_loc_so
         where ssx_so_uid_fk = p_svo_uid_pk
           and slo_uid_pk = ssx_service_locations_uid_fk
           and ssx_primary_loc_fl = 'Y'
           and ssx_end_date is null;

 cursor get_svc_loc is
        select ssl_service_locations_uid_fk
          from service_locations, serv_serv_locations, services, so
         where ssl_services_uid_fk = svc_uid_pk
           and slo_uid_pk = ssl_service_locations_uid_fk
           and ssl_primary_loc_fl = 'Y'
           and ssl_end_date is null
           and svo_uid_pk = p_svo_uid_pk
           and svo_services_uid_fk = svc_uid_pk;

 cursor already_loaded is
   select 'x'
     from so_loadings
    where sds_completed_fl = 'N'
      and sds_employees_uid_fk = P_EMP_UID_PK
      and trunc(sds_schedule_date) = trunc(sysdate);

 CURSOR CHECK_ADSL IS
   select 'x'
     from so_assgnmts a
    where a.son_adsl_modems_uid_fk is null
      and a.son_so_uid_fk not in (select b.son_so_uid_fk
                                    from so_assgnmts b
                                   where b.son_so_uid_fk = a.son_so_uid_fk
                                     and b.son_adsl_modems_uid_fk is not null)
      and a.son_so_uid_fk = P_SVO_UID_PK
      and a.son_uid_pk in (select PAS_SO_ASSGNMTS_UID_FK
                           from pairs_so
                          where a.son_uid_pk = PAS_SO_ASSGNMTS_UID_FK)
      and a.son_uid_pk not in (select FSO_SO_ASSGNMTS_UID_FK
                               from ftth_so
                              where a.son_uid_pk = FSO_SO_ASSGNMTS_UID_FK);

 CURSOR CHECK_ADSL_SVC (P_SVC_UID_PK IN NUMBER) IS
   select count(distinct sva_adsl_modems_uid_fk)
     from service_assgnmts
    where sva_adsl_modems_uid_fk is not null
      and sva_services_uid_fk = P_SVC_UID_PK;

 CURSOR GET_CABLE_MODEM (P_SVC_UID_PK IN NUMBER) IS
    SELECT SVA_CABLE_MODEMS_UID_FK
    FROM SERVICE_ASSGNMTS
    WHERE SVA_SERVICES_UID_FK = P_SVC_UID_PK;

CURSOR MTA_COUNT (P_SVC_UID_PK IN NUMBER) IS
SELECT COUNT(DISTINCT meu_mta_boxes_uid_fk)
FROM ACCOUNTS, SERVICES, SERVICE_ASSGNMTS, MTA_SERVICES, MTA_PORTS, MTA_EQUIP_UNITS
WHERE ACC_UID_PK = SVC_ACCOUNTS_UID_FK
  AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
  AND SVC_UID_PK = SVA_SERVICES_UID_FK
  AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
  AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
  AND SVC_UID_PK = P_SVC_UID_PK
  and meu_mta_boxes_uid_fk is not null;
  
CURSOR get_mmr_conv(cp_svo_uid_pk NUMBER) IS
SELECT cts_conversion_fl
FROM catv_so
WHERE cts_so_uid_fk = cp_svo_uid_pk;

V_ZONE_CODE           VARCHAR2(80);
V_BSO_SYSTEM_CODE     VARCHAR2(80);
V_STY_SYSTEM_CODE     VARCHAR2(80);
V_SOT_SYSTEM_CODE     VARCHAR2(80);
V_OSB_UID_PK          NUMBER;
V_SVC_UID_PK          NUMBER;
V_CUS_UID_PK          NUMBER;
V_OST_UID_PK          NUMBER;
V_CBM_UID_PK          NUMBER;
V_SVT_CODE            VARCHAR2(40);
V_isr_uid_pk          NUMBER;
V_SLO_UID_PK          NUMBER;
V_current_wfc_uid_pk  NUMBER;
V_defined_wfc_uid_pk  NUMBER;
V_defined_wfc_desc    VARCHAR2(200);
V_isr_exists          VARCHAR2(200);
V_invalid_iptv_svcs   VARCHAR2(200) := 'N';
V_invalid_cbm         VARCHAR2(200) := 'N';
v_display_message     VARCHAR2(2000);
v_cable_modem_message VARCHAR2(2000);
v_dummy               VARCHAR2(1);
v_count_adsl          NUMBER := 0;
v_count_mta           NUMBER := 0;
v_chg_tbl             generate_so_extra_pkg.unreturned_chg_tbl;
v_clec_fl             VARCHAR2(10);
v_adsl_on_service     VARCHAR2(10) := 'N';
v_mmr                 VARCHAR2(1);

V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_CLOSE_ROUTE_ORDERS';

v_return_msg  		VARCHAR2(4000);

v_sls               NUMBER;
v_query             VARCHAR2(32000);
v_prov              VARCHAR2(12);
v_triad_prov        VARCHAR2(1);

TYPE cur_typ IS REF CURSOR;   
q cur_typ;

BEGIN

IF P_TYPE = 'S' THEN

OPEN check_zone;
FETCH check_zone INTO V_ZONE_CODE;
CLOSE check_zone;

OPEN GET_SO_INFO;
FETCH GET_SO_INFO INTO V_BSO_SYSTEM_CODE, V_SOT_SYSTEM_CODE, V_STY_SYSTEM_CODE, V_CUS_UID_PK, V_SVC_UID_PK, V_OST_UID_PK, v_clec_fl;
CLOSE GET_SO_INFO;

OPEN SERV_SUB_TYPE;
FETCH SERV_SUB_TYPE INTO V_OST_UID_PK, V_SVT_CODE;
CLOSE SERV_SUB_TYPE;

IF V_SVT_CODE IN ('ADSL','VDSL') AND V_SOT_SYSTEM_CODE IN ('NS','MS') THEN
   --CHECK FOR PAIRS SO AND IF NO MODEM IS ASSIGNED.
   OPEN CHECK_ADSL;
   FETCH CHECK_ADSL INTO V_DUMMY;
   IF CHECK_ADSL%FOUND THEN
      RETURN 'This order requires an ADSL modem to be added and none have been added yet.  Please correct.';
      
      ---HD 121629 - Add Process to Insert Error Messages into SO_ERROR_LOG Table for Troubleshooting
      v_return_msg:= 'This order requires an ADSL modem to be added and none have been added yet.  Please correct.';
      IF P_SVO_UID_PK IS NOT NULL THEN
      	 IF v_return_msg IS NOT NULL THEN
			   		PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
			   END IF;
			END IF;
      
   END IF;
   CLOSE CHECK_ADSL;
END IF;

-- MCV 01/23/2014
-- BPP item - do not let a user close a MS order if it has not been provisioned in TRIAD
IF  V_SOT_SYSTEM_CODE ='MS' THEN
 -- retrieve facilties type provisioned through TRIAD
 v_query := system_rules_pkg.get_clob_value('CABLEBRIDGE','SVC_PROV','FACILITIES');
 
 v_query := REPLACE(v_query,'<svo_uid_pk>', p_svo_uid_pk);
 
 OPEN q for v_query;
 FETCH q INTO v_prov;
 IF q%FOUND THEN
   v_triad_prov := 'Y';
 ELSE
   v_triad_prov := 'N';
 END IF;
 CLOSE q;
 
 
 IF  system_rules_pkg.get_char_value('CABLEBRIDGE', 'SVC_PROV', V_STY_SYSTEM_CODE) LIKE '%'||v_svt_code||'%'
   OR V_triad_prov = 'Y' THEN
   
   v_sls := 0;
   
   SELECT COUNT(*)
     INTO v_sls
     FROM swt_logs
    WHERE sls_so_uid_fk = p_svo_uid_pk
      AND sls_swt_equipment_uid_fk IN (code_pkg.get_pk('SWT_EQUIPMENT','TRIAD_XML'),code_pkg.get_pk('SWT_EQUIPMENT','CABLEBRIDGE'));
  
   IF NVL(v_sls,0) = 0  THEN
      v_return_msg:= 'This MS order needs to be provisioned before it can be closed. Please provision the order and try again.';
            
      RETURN v_return_msg;
   END IF;   
 END IF;           

END IF;

SO_CLOSING_IVR_PKG.CHECK_ROUTING(P_SVO_UID_PK,
                                 P_EMP_UID_PK,
                                 V_ZONE_CODE,
                                                         V_BSO_SYSTEM_CODE,
                                                         V_SOT_SYSTEM_CODE,
                                                         V_STY_SYSTEM_CODE,
                                               1,
                                               'XXXX',
                                               V_isr_uid_pk,
                                 V_current_wfc_uid_pk,
                                 V_defined_wfc_uid_pk,
                                 V_defined_wfc_desc);

SO_CLOSING_IVR_PKG.CLEAR_SO(P_SVO_UID_PK,
                            P_EMP_UID_PK,
                            V_current_wfc_uid_pk,
                                              V_defined_wfc_uid_pk,
                            V_defined_wfc_desc,
                            V_STY_SYSTEM_CODE,
                            'N',
                            NULL,
                            V_BSO_SYSTEM_CODE,
                                              1,
                                              V_isr_exists,
                                              NULL,
                                              V_invalid_iptv_svcs,
                                              V_invalid_cbm);
                                              
DBMS_OUTPUT.PUT_LINE(NVL(V_invalid_cbm,'N'));

IF NVL(V_invalid_iptv_svcs,'N') = 'Y' THEN
   v_display_message := 'Cannot Clear this Service Order, it is an IPTV service order'||
                        ' and its status is not okay.  Please use the sanity check link to check on the status of this service order';
ELSIF NVL(V_invalid_cbm,'N') = 'Y' THEN
   IF NOT INSTALLER_WEB_PKG.CHECK_CBM_STATUS(P_SVO_UID_PK, v_cable_modem_message) THEN
      v_display_message := v_cable_modem_message;
   ELSE
      v_display_message := NULL;
   END IF;
ELSE
   v_display_message := NULL;
END IF;

IF P_COMMENT IS NOT NULL THEN
   PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, P_COMMENT , P_EMP_UID_PK, P_TYPE);
END IF;

IF NVL(V_invalid_iptv_svcs,'N') != 'Y' and NVL(V_invalid_cbm,'N') != 'Y' THEN

      INSTALLER_WEB_PKG.INS_SIA(P_EMP_UID_PK, P_SVO_UID_PK, 'N', 'CLEAR', NULL);

      --THIS WILL CHECK TO SEE IF A BILLING CHANGE FORM IS NEEDED
      --INSTALLER_WEB_PKG.PR_EMAIL_BC_ORDER_NEEDED(P_SVO_UID_PK);

      GPS_PKG.FN_SDS_STAMP_ADDRESS(P_SVO_UID_PK, P_EMP_UID_PK, TRUNC(SYSDATE), 'C');
      
      --IF WE GET THIS FAR THIS DELETE STATEMENT WILL DELETE ANY MTA_SO RECORDS LINKED TO THE SVO_UID_PK
      --THIS SHOULD ONYL HAPPEN IF THE ORDER WAS FIRST CREATED AT A PACKET CABLE ORDER BUT TECH INSTALLS
      --A CABLE MODEM AND NO TELEPHONE IS INVOLVED.
      IF V_SVT_CODE = 'CABLE MODEM' THEN
         DELETE
           FROM MTA_SO
          WHERE MTO_SO_ASSGNMTS_UID_FK IN (SELECT SON_UID_PK
                                             FROM SO_ASSGNMTS
                                            WHERE SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
                                              AND SON_SO_UID_FK = P_SVO_UID_PK);



      END IF;

      --NJJ I SHOULD BE ABLE TO THE QUANTITY NOT RETURNED BY GETTING THE ACTIVE SERVICE QUANTITY SINCE THIS IS UPDATED
      --NOW ON EVERY ORDER WHEN EQUIPMENT IS REMOVED
      OPEN CHECK_ADSL_SVC(V_SVC_UID_PK);
      FETCH CHECK_ADSL_SVC INTO V_COUNT_ADSL;
      IF CHECK_ADSL_SVC%NOTFOUND THEN
         V_COUNT_ADSL := 0;
      END IF;
      CLOSE CHECK_ADSL_SVC;

      IF V_COUNT_ADSL > 0 THEN
         V_ADSL_ON_SERVICE := 'Y';
      ELSE
         V_ADSL_ON_SERVICE := 'N';
      END IF;

      OPEN GET_CABLE_MODEM(V_SVC_UID_PK);
      FETCH GET_CABLE_MODEM INTO V_CBM_UID_PK;
      IF GET_CABLE_MODEM%NOTFOUND THEN
         V_CBM_UID_PK := NULL;
      END IF;
      CLOSE GET_CABLE_MODEM;

      OPEN MTA_COUNT(V_SVC_UID_PK);
      FETCH MTA_COUNT INTO v_count_mta;
      IF MTA_COUNT%NOTFOUND THEN
         v_count_mta := 0;
      END IF;
      CLOSE MTA_COUNT;

      if V_SOT_SYSTEM_CODE = 'RS' and V_STY_SYSTEM_CODE = 'CTV' THEN
          generate_so_extra_pkg.pr_add_catv_equip_feat(V_CUS_UID_PK,
                                                       V_SVC_UID_PK,
                                                       P_SVO_UID_PK,
                                                       V_OST_UID_PK,
                                                       V_ADSL_ON_SERVICE,  -- adsl
                                                       V_COUNT_ADSL,
                                                       NULL,
                                                       NULL,
                                                       NULL);
      elsif V_SOT_SYSTEM_CODE = 'RS' and v_count_mta > 0 then  --if mta found then call this instead of the one for BBS in found on high speed also call this for telephoe when mta found
              generate_so_extra_pkg.pr_add_mta_equip_feat(V_CUS_UID_PK,
                                                V_SVC_UID_PK,
                                                P_SVO_UID_PK,
                                                V_OST_UID_PK,
                                V_STY_SYSTEM_CODE,
                                                v_count_mta);
          -- if RS on BBS, charge customer for non-returned cable modem
      elsif V_SOT_SYSTEM_CODE = 'RS' and V_STY_SYSTEM_CODE IN ('BBS','METRO-ETH') THEN
          generate_so_extra_pkg.pr_add_bbs_met_equip_feat(V_CUS_UID_PK,
                                                          V_SVC_UID_PK,
                                                          P_SVO_UID_PK,
                                                          V_OST_UID_PK,
                                                          V_CBM_UID_PK,
                                                          V_STY_SYSTEM_CODE,
                                                          V_ADSL_ON_SERVICE,
                                                          V_COUNT_ADSL);
      /* MCV 08/25/2014 Per User Reques Self-fulfillment project 
         do not charge on CS/MS
      elsif V_SOT_SYSTEM_CODE IN ('CS','MS') and V_STY_SYSTEM_CODE = 'CTV' THEN
          --MCV MMR do not charge for Boxes
          OPEN get_mmr_conv(p_svo_uid_pk);
          FETCH get_mmr_conv INTO v_mmr;
          CLOSE get_mmr_conv;
          
          IF NVL(v_mmr,'N') = 'N' THEN
            generate_so_extra_pkg.pr_add_catv_CS_equip_feat (v_clec_fl,
                                                           p_svo_uid_pk,
                                                           V_OST_UID_PK,
                                                           v_chg_tbl);
          END IF;*/
      end if;

END IF;

END IF;

COMMIT;

RETURN v_display_message;

END FN_CLOSE_ROUTE_ORDERS;

/*-------------------------------------------------------------------------------------------------------------*/
--THIS FUNCTION WILL RETURN TRUE/FALSE DEPENDING ON THE STATUS OF THE CABLE MODEM SERVICE
FUNCTION CHECK_CBM_STATUS(p_svo_uid_pk IN NUMBER,
                          p_msg        OUT VARCHAR2,
                          p_svc_uid_pk in number default null) RETURN BOOLEAN IS

--GET CABLE MODEM ASSIGNED TO THE SO
CURSOR get_cbm(cp_svo_uid_pk NUMBER) IS
SELECT cbm_mac_address, 'CBM' , cdt_system_code ---HD 108410 RMC 07/11/2011
  FROM so_assgnmts,
       cable_modems,
       cable_modem_types  ---HD 108410 RMC 07/11/2011
 WHERE son_cable_modems_uid_fk = cbm_uid_pk
   AND cbm_cable_modem_types_uid_fk = cdt_uid_pk ---HD 108410 RMC 07/11/2011
   AND son_so_uid_fk           = cp_svo_uid_pk
 UNION
 SELECT MTA_CMAC_ADDRESS, 'MTA', mty_system_code ---HD 108410 RMC 07/11/2011
   FROM so_assgnmts,
        mta_so,
        mta_ports,
        mta_equip_units,
        mta_types, ---HD 108410 RMC 07/11/2011
        mta_boxes
  WHERE son_so_uid_fk           = cp_svo_uid_pk
    and son_uid_pk = mto_so_assgnmts_uid_fk
    and mtp_uid_pk = mto_mta_ports_uid_fk
    and meu_uid_pk = mtp_mta_equip_units_uid_fk
    and mty_uid_pk = meu_mta_types_uid_fk ---HD 108410 RMC 07/11/2011
    and mta_uid_pk = meu_mta_boxes_uid_fk
    and meu_remove_mta_fl = 'N'
 UNION
SELECT ONU_MAC_ADDRESS, 'MTA', OTP_SYSTEM_CODE  ---HD 108410 RMC 07/11/2011
  FROM OUT_NET_UNITS, ONU_TYPES, ONU_PORTS, FTTH_SO, SO_ASSGNMTS  
 WHERE OTP_UID_PK = ONU_ONU_TYPES_UID_FK  ---HD 108410 RMC 07/11/2011
   AND ONU_UID_PK = ONP_OUT_NET_UNITS_UID_FK
   AND ONP_UID_PK = FSO_ONU_PORTS_UID_FK
   AND SON_UID_PK = FSO_SO_ASSGNMTS_UID_FK
   AND SON_SO_UID_FK = cp_svo_uid_pk
   AND ONU_MAC_ADDRESS IS NOT NULL;
   
--GET CABLE MODEM ASSIGNED TO THE SO
CURSOR get_cbm_svc IS
SELECT cbm_mac_address, 'CBM', cdt_system_code ---HD 108410 RMC 07/11/2011
  FROM service_assgnmts,
       cable_modems,
       cable_modem_types  ---HD 108410 RMC 07/11/2011
 WHERE sva_cable_modems_uid_fk = cbm_uid_pk
   AND cbm_cable_modem_types_uid_fk = cdt_uid_pk ---HD 108410 RMC 07/11/2011
   AND sva_services_uid_fk = p_svc_uid_pk
 UNION
 SELECT MTA_CMAC_ADDRESS, 'MTA', mty_system_code ---HD 108410 RMC 07/11/2011
   FROM service_assgnmts,
        mta_services,
        mta_ports,
        mta_equip_units,
        mta_types, ---HD 108410 RMC 07/11/2011
        mta_boxes
  WHERE sva_services_uid_fk = p_svc_uid_pk
    and sva_uid_pk = mss_service_assgnmts_uid_fk
    and mtp_uid_pk = mss_mta_ports_uid_fk
    and meu_uid_pk = mtp_mta_equip_units_uid_fk
    and mty_uid_pk = meu_mta_types_uid_fk ---HD 108410 RMC 07/11/2011
    and mta_uid_pk = meu_mta_boxes_uid_fk
    and meu_remove_mta_fl = 'N'
 UNION
SELECT ONU_MAC_ADDRESS, 'MTA', OTP_SYSTEM_CODE  ---HD 108410 RMC 07/11/2011
  FROM OUT_NET_UNITS, ONU_TYPES, ONU_PORTS, FTTH_SERVICES, SERVICE_ASSGNMTS
 WHERE OTP_UID_PK = ONU_ONU_TYPES_UID_FK  ---HD 108410 RMC 07/11/2011
   AND ONU_UID_PK = ONP_OUT_NET_UNITS_UID_FK
   AND ONP_UID_PK = FTS_ONU_PORTS_UID_FK
   AND SVA_UID_PK = FTS_SERVICE_ASSGNMTS_UID_FK
   AND SVA_SERVICES_UID_FK = p_svc_uid_pk
   AND ONU_MAC_ADDRESS IS NOT NULL;

v_status                              VARCHAR2(100);
v_cbm_msg                          VARCHAR2(4000);
v_mac_address          VARCHAR2(30);
modem_is_online                 BOOLEAN;
downstream_power_delta NUMBER;
upstream_power_delta   NUMBER;
downstream_snr_delta   NUMBER;
status_overall         VARCHAR2(100);
messages               VARCHAR2(4000);
v_online               VARCHAR2(50);
v_levels                             VARCHAR2(1500);
v_usr_login            VARCHAR2(100);
v_type                 VARCHAR2(50);
v_message              VARCHAR2(100);
v_modem_mta_type       VARCHAR2(50);

BEGIN

IF p_svo_uid_pk is not null then
   OPEN get_cbm(p_svo_uid_pk);
   FETCH get_cbm INTO v_mac_address, v_type, v_modem_mta_type;
   CLOSE get_cbm;
ELSE
   OPEN get_cbm_svc;
   FETCH get_cbm_svc INTO v_mac_address, v_type, v_modem_mta_type;
   CLOSE get_cbm_svc;
END IF;

IF SYSTEM_RULES_PKG.GET_CHAR_VALUE('SERV DIAG','OPTIONS','CM MAC') = 'N' THEN
---IF v_modem_mta_type not in ('780149', '785196', 'SPEEDGTR10') THEN --RMC HD 119404 04-23-2012 - NE changed service diagnostics to handle DOCSIS 3.0 MTAs and Cable Modems 

	 service_diagnostics.troubleshoot_cm_mac(v_mac_address,
                                           modem_is_online,
                                           downstream_power_delta,
                                           upstream_power_delta,
                                           downstream_snr_delta,
                                           status_overall,
                                           messages);

	 IF modem_is_online THEN
      v_online := 'MODEM IS ONLINE';
   ELSE
      v_online := 'MODEM IS NOT ONLINE';
   END IF;

	 IF downstream_power_delta > 0 THEN
      v_levels := 'Downstream power level is too high by '||downstream_power_delta||' dBmV.';
   ELSIF downstream_power_delta < 0 THEN
         v_levels := 'Downstream power level is too low by '||ABS(downstream_power_delta)||' dBmV.';
   ELSE
      v_levels := 'Downstream power level is OK.';
   END IF;

   IF upstream_power_delta > 0 THEN
      v_levels := v_levels||' Upstream power level is too high by '||upstream_power_delta||' dBmV.';
   ELSIF upstream_power_delta < 0 THEN
         v_levels := v_levels||' Upstream power level is too low by '||ABS(upstream_power_delta)||' dBmV.';
   ELSE
      v_levels := v_levels||' Upstream power level is OK.';
   END IF;

   IF downstream_snr_delta < 0 THEN
      v_levels := v_levels||' Downstream SNR is too low by '||ABS(downstream_snr_delta)||' dB.';
   ELSE
      v_levels := v_levels||' Downstream SNR is OK.';
   END IF;

   IF v_type = 'MTA' THEN
      v_message := 'MTA modem status: ';
   ELSE
      v_message := 'Cable modem status: ';
   END IF;

   P_MSG := v_message||v_online||'. '||v_levels;

   IF status_overall IN ('FAILURE','ERROR') THEN

      IF status_overall = 'ERROR' THEN
         P_MSG := messages;
      END IF;

      RETURN(FALSE);

   ELSE

      RETURN(TRUE);

   END IF;
   
ELSE

   service_diagnostics.get_cm_mac(v_mac_address,
                                  modem_is_online,
                                  status_overall,
                                  messages);
                                           
   IF modem_is_online THEN
      v_online := 'MODEM IS ONLINE';
   ELSE
      v_online := NULL;
   END IF;
   
   IF v_type = 'MTA' THEN
      v_message := 'MTA modem status: ';
   ELSE
      v_message := 'Cable modem status: ';
   END IF;

   P_MSG := v_message||v_online||'. '||messages;
   
   IF status_overall IN ('FAILURE','ERROR') THEN

      IF status_overall = 'ERROR' THEN
         P_MSG := messages;
      END IF;

      RETURN(FALSE);

   ELSE

      RETURN(TRUE);

   END IF;
                                           
END IF;

---ELSE ---RMC HD 04-23-2012 - NE changed service diagnostics to handle DOCSIS 3.0 MTAs and Cable Modems 
   ---RETURN(TRUE); ---RMC HD 04-23-2012 - NE changed service diagnostics to handle DOCSIS 3.0 MTAs and Cable Modems 
---END IF; ---END IF for IF v_modem_mta_type not in ('780149'... ---RMC HD 119404 04-23-2012 - NE changed service diagnostics to handle DOCSIS 3.0 MTAs and Cable Modems 

   EXCEPTION

      WHEN OTHERS THEN
           UPDATE so_ivr_activity
                  SET sia_error = ' FAILURE IN CHECK_CBM_STATUS. SVO_UID_PK = '||p_svo_uid_pk
                                                 ||' ERROR MESSAGE OF CABLE/MTA MODEM ='||messages||' STATUS OF MODEM: '||status_overall
                   WHERE sia_so# = p_svo_uid_pk;

END CHECK_CBM_STATUS;

/*-------------------------------------------------------------------------------------------------------------*/
--THIS FUNCTION WILL RETURN TRUE/FALSE DEPENDING ON IF THE SERVICE ORDERS FOR THE CUSTOMER WILL EVEN REQUIRE A TERMS AND CONDITIONS ACCEPTANCE
FUNCTION TERMS_CONDITIONS_NEEDED(p_cus_uid_pk IN NUMBER)

RETURN BOOLEAN IS

CURSOR GET_OPEN_SOS IS
SELECT 'Y'
  FROM SO_TYPES, ACCOUNTS, SERVICES, SO, SO_LOADINGS
 WHERE SDS_COMPLETED_FL = 'N'
   AND SVO_UID_PK = SDS_SO_UID_FK
   AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
   AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
   AND SVC_UID_PK = SVO_SERVICES_UID_FK
   AND SOT_SYSTEM_CODE = 'NS'
   AND SDS_SCHEDULED_FL = 'Y'
   AND NVL(UPPER(SUBSTR(SDS_COMMENT,1,3)),'999999') NOT IN ('SP ','SPT','SPO')
   AND ACC_CUSTOMERS_UID_FK = P_CUS_UID_PK;

V_NEW_ORDER_FOUND   VARCHAR2(1) := 'N';

BEGIN

OPEN GET_OPEN_SOS;
FETCH GET_OPEN_SOS INTO V_NEW_ORDER_FOUND;
IF GET_OPEN_SOS%NOTFOUND THEN
   V_NEW_ORDER_FOUND := 'N';
END IF;
CLOSE GET_OPEN_SOS;

IF V_NEW_ORDER_FOUND = 'Y' THEN
   RETURN TRUE;
ELSE
   RETURN FALSE;
END IF;

END TERMS_CONDITIONS_NEEDED;

/*-------------------------------------------------------------------------------------------------------------*/
--THIS FUNCTION WILL RETURN TRUE/FALSE DEPENDING ON IF THE SERVICE ORDERS FOR THE CUSTOMER WILL EVEN REQUIRE A TERMS AND CONDITIONS ACCEPTANCE
FUNCTION CONTRACT_NEEDED(p_cus_uid_pk IN NUMBER, P_CONTRACT_END_DATE OUT DATE, P_SOF_UID_PK OUT NUMBER, P_TERM_AMOUNT OUT NUMBER, P_FTP_UID_PK OUT NUMBER, P_FTP_CODE OUT VARCHAR)

RETURN BOOLEAN IS

CURSOR GET_OPEN_SOS IS
SELECT SVO_UID_PK, ORG_CLEC_FL
  FROM SO_TYPES, ORGANIZATIONS, BUSINESS_OFFICES, CUSTOMERS, ACCOUNTS, SERVICES, SO, SO_LOADINGS
 WHERE SDS_COMPLETED_FL = 'N'
   AND SVO_UID_PK = SDS_SO_UID_FK
   AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
   AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
   AND SVC_UID_PK = SVO_SERVICES_UID_FK
   AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
   AND BSO_UID_PK = CUS_BUSINESS_OFFICES_UID_FK
   AND ORG_UID_PK = BSO_ORGANIZATIONS_UID_FK
   AND ACC_CUSTOMERS_UID_FK = P_CUS_UID_PK;

 CURSOR CHECK_FOR_CONTRACT(P_SVO_UID_PK IN NUMBER) IS
   SELECT FTP_CODE, FTP_CONTRACT_MONTHS, SOF_UID_PK, FTP_UID_PK
     FROM FEATURES, OFFICE_SERV_FEATS, SO_FEATURES
    WHERE FTP_UID_PK = OSF_FEATURES_UID_FK
      AND OSF_UID_PK = SOF_OFFICE_SERV_FEATS_UID_FK
      AND SOF_SO_UID_FK = P_SVO_UID_PK
      AND SOF_ACTION_FL = 'A'
      AND FTP_CODE IN ('CT1Y','CT2Y','CXCT1Y','CXCT2Y');

 CURSOR GET_TERMINATION_FEE (P_FTP_CODE IN VARCHAR) IS
   SELECT RTS_AMOUNT
     FROM RATES, FEATURES
    WHERE FTP_UID_PK = RTS_FEATURES_UID_FK
      AND RTS_END_DATE IS NULL
      AND FTP_CODE = P_FTP_CODE;

V_CONTRACT_FOUND      VARCHAR2(1) := 'N';
V_FTP_CODE            VARCHAR2(40);
V_FTP_CONTRACT_MONTHS NUMBER;
V_SOF_UID_PK          NUMBER;
V_FTP_UID_PK          NUMBER;
V_SOF_UID_PK_STORE    NUMBER;
V_NEW_WARR_END_DATE   DATE;
V_RTS_AMOUNT          NUMBER;
V_TERM_FTP_CODE       VARCHAR2(20);

BEGIN

FOR REC IN GET_OPEN_SOS LOOP
   OPEN CHECK_FOR_CONTRACT(REC.SVO_UID_PK);
   FETCH CHECK_FOR_CONTRACT INTO V_FTP_CODE, V_FTP_CONTRACT_MONTHS, V_SOF_UID_PK, V_FTP_UID_PK;
   IF CHECK_FOR_CONTRACT%FOUND THEN
      V_CONTRACT_FOUND := 'Y';
      V_SOF_UID_PK_STORE := V_SOF_UID_PK;

      SELECT TRUNC(ADD_MONTHS(SYSDATE - 1,V_FTP_CONTRACT_MONTHS))
        INTO V_NEW_WARR_END_DATE
        FROM DUAL;

      IF V_FTP_CODE = 'CT1Y' THEN
         IF REC.ORG_CLEC_FL = 'Y' THEN --
            V_TERM_FTP_CODE := 'K1ET';
         ELSE
            V_TERM_FTP_CODE := 'ECTF';
         END IF;
      ELSIF V_FTP_CODE = 'CT2Y' THEN
         IF REC.ORG_CLEC_FL = 'Y' THEN --
            V_TERM_FTP_CODE := 'K2ET';
         ELSE
            V_TERM_FTP_CODE := 'ECT2';
         END IF;
      ELSIF V_FTP_CODE IN ('CXCT1Y','CXCT2Y') THEN
         IF REC.ORG_CLEC_FL = 'Y' THEN --
            V_TERM_FTP_CODE := 'CXKET';
         ELSE
            V_TERM_FTP_CODE := 'CXET';
         END IF;
      END IF;

      OPEN GET_TERMINATION_FEE(V_TERM_FTP_CODE);
      FETCH GET_TERMINATION_FEE INTO V_RTS_AMOUNT;
      IF GET_TERMINATION_FEE%NOTFOUND THEN
         V_RTS_AMOUNT := 0;
      END IF;
      CLOSE GET_TERMINATION_FEE;
   END IF;
   CLOSE CHECK_FOR_CONTRACT;
END LOOP;

IF V_CONTRACT_FOUND = 'Y' THEN

   P_CONTRACT_END_DATE := V_NEW_WARR_END_DATE;
   P_SOF_UID_PK        := V_SOF_UID_PK_STORE;
   P_TERM_AMOUNT       := V_RTS_AMOUNT;
   P_FTP_UID_PK        := V_FTP_UID_PK;
   P_FTP_CODE          := V_FTP_CODE;

   RETURN TRUE;
ELSE
   P_CONTRACT_END_DATE := NULL;
   P_SOF_UID_PK        := NULL;
   P_TERM_AMOUNT       := NULL;
   P_FTP_UID_PK        := NULL;
   P_FTP_CODE          := NULL;

   RETURN FALSE;
END IF;

END CONTRACT_NEEDED;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE PR_INSERT_CUS_AGREEMENTS(P_CUS_UID_PK IN NUMBER, P_ACCEPT_FL IN VARCHAR)

IS

CURSOR CHECK_FOR_BUNDLE IS
SELECT DISTINCT SVO_FEATURES_UID_FK
  FROM SO_TYPES, ORGANIZATIONS, BUSINESS_OFFICES, CUSTOMERS, ACCOUNTS, SERVICES, SO, SO_LOADINGS
 WHERE SDS_COMPLETED_FL = 'N'
   AND SVO_UID_PK = SDS_SO_UID_FK
   AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
   AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
   AND SVC_UID_PK = SVO_SERVICES_UID_FK
   AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
   AND BSO_UID_PK = CUS_BUSINESS_OFFICES_UID_FK
   AND ORG_UID_PK = BSO_ORGANIZATIONS_UID_FK
   AND ACC_CUSTOMERS_UID_FK = P_CUS_UID_PK;

CURSOR GET_OPEN_SOS IS
SELECT DISTINCT SVC_UID_PK, SVO_UID_PK
  FROM SO_TYPES, ORGANIZATIONS, BUSINESS_OFFICES, CUSTOMERS, ACCOUNTS, SERVICES, SO, SO_LOADINGS
 WHERE SDS_COMPLETED_FL = 'N'
   AND SVO_UID_PK = SDS_SO_UID_FK
   AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
   AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
   AND SVC_UID_PK = SVO_SERVICES_UID_FK
   AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
   AND BSO_UID_PK = CUS_BUSINESS_OFFICES_UID_FK
   AND ORG_UID_PK = BSO_ORGANIZATIONS_UID_FK
   AND ACC_CUSTOMERS_UID_FK = P_CUS_UID_PK;

 V_CAM_UID_PK          NUMBER;
 v_contract_end_date   date;
 v_sof_uid_pk          number;
 v_term_amount         number;
 v_char_end_date       varchar2(20);
 v_contract_ftp_uid_pk NUMBER;
 v_bundle_ftp_uid_pk   number;
 v_accept_date         date;
 v_non_accept_date     date;
 v_contract_ftp_code   varchar2(80);

BEGIN

IF INSTALLER_WEB_PKG.TERMS_CONDITIONS_NEEDED(P_CUS_UID_PK) THEN
   SELECT CAM_SEQ.NEXTVAL
     INTO V_CAM_UID_PK
     FROM DUAL;

   OPEN CHECK_FOR_BUNDLE;
   FETCH CHECK_FOR_BUNDLE INTO v_bundle_ftp_uid_pk;
   IF CHECK_FOR_BUNDLE%NOTFOUND THEN
      v_bundle_ftp_uid_pk := NULL;
   END IF;
   CLOSE CHECK_FOR_BUNDLE;

   --IF A CONTRACT IS INVOLVED WE NEED TO UPDATE THE SOF_WARR_START_DATE AND SOF_WARR_END_DATE FIELDS THAT WERE SET WHEN THE SO WAS CREATED
   IF INSTALLER_WEB_PKG.CONTRACT_NEEDED(P_CUS_UID_PK, v_contract_end_date, v_sof_uid_pk, v_term_amount, v_contract_ftp_uid_pk, v_contract_ftp_code) THEN
      UPDATE SO_FEATURES
         SET SOF_WARR_START_DATE = TRUNC(SYSDATE),
             SOF_WARR_END_DATE = v_contract_end_date
       WHERE SOF_UID_PK = v_sof_uid_pk;
   END IF;

   IF P_ACCEPT_FL = 'Y' THEN --ACCEPTED THE TERMS AND CONDITIONS
      v_accept_date     := trunc(sysdate);
      v_non_accept_date := null;
   ELSE
      v_non_accept_date := trunc(sysdate);
      v_accept_date     := null;
   END IF;

   INSERT INTO CUS_AGREEMENTS (CAM_UID_PK, CAM_CUSTOMERS_UID_FK, CAM_BUN_FEATURES_UID_FK, CAM_CONTR_FEATURES_UID_FK,
                               CAM_TERMS_ACCEPTED_FL, CAM_TERMS_ACCEPT_DATE, CAM_TERMS_NOT_ACCEPT_DATE)
                        VALUES(V_CAM_UID_PK, P_CUS_UID_PK, v_bundle_ftp_uid_pk, v_contract_ftp_uid_pk,
                               P_ACCEPT_FL, v_accept_date, v_non_accept_date);

   FOR REC IN GET_OPEN_SOS LOOP
      INSERT INTO CUS_AGR_SERVICES (CAE_UID_PK, CAE_CUS_AGREEMENTS_UID_FK, CAE_SERVICES_UID_FK, CAE_SO_UID_FK)
                            VALUES (CAE_SEQ.NEXTVAL, V_CAM_UID_PK, REC.SVC_UID_PK, REC.SVO_UID_PK);
   END LOOP;

   COMMIT;
END IF;

END PR_INSERT_CUS_AGREEMENTS;

FUNCTION GET_EMPLOYEE_PK

RETURN NUMBER IS

--THIS WILL RETURN THE EMPLOYEE PK OF THE USER LOGGED IN
CURSOR GET_EMPLOYEE_PK IS
SELECT USR_EMPLOYEES_UID_FK
  FROM USERS
 WHERE USR_LOGIN = USER;

 V_EMP_UID_PK   NUMBER := NULL;

BEGIN

OPEN GET_EMPLOYEE_PK;
FETCH GET_EMPLOYEE_PK INTO V_EMP_UID_PK;
IF GET_EMPLOYEE_PK%NOTFOUND THEN
   V_EMP_UID_PK := NULL;
END IF;
CLOSE GET_EMPLOYEE_PK;

RETURN V_EMP_UID_PK;

END GET_EMPLOYEE_PK;

/*-------------------------------------------------------------------------------------------------------------*/
--THIS PROCEDURE WILL INSERT NEW RECORD INTO SO_IVR_ACTIVITY
PROCEDURE INS_SIA(p_emp_uid_pk         NUMBER,
                  p_svo_uid_pk         NUMBER,
                  p_xfer_fl         IN VARCHAR,
                  p_sia_action      IN VARCHAR,
                  p_ace_uid_pk      IN NUMBER) IS

--USER LOGIN--
CURSOR get_user(cp_emp_uid_pk NUMBER) IS
SELECT usr_login
    FROM users, employees
 WHERE usr_employees_uid_fk = emp_uid_pk
     AND emp_uid_pk           = cp_emp_uid_pk;

v_usr_login  varchar2(200);

BEGIN

--GET USER LOGIN.
  OPEN get_user(p_emp_uid_pk);
  FETCH get_user INTO v_usr_login;
  CLOSE get_user;
--

INSERT INTO SO_IVR_ACTIVITY(sia_uid_pk,
                                                        sia_user,
                                                        sia_so#,
                                                        sia_action,
                                                        sia_web_ivr_fl,
                                                        sia_transfer_fl,
                                                        sia_access_codes_uid_fk)
                                         VALUES(sia_seq.nextval,
                                                        v_usr_login,
                                                        p_svo_uid_pk,
                                                        p_sia_action,
                                                        'W',
                                                        p_xfer_fl,
                                                        p_ace_uid_pk);

COMMIT;
END INS_SIA;

FUNCTION GET_CURRENT_USER

RETURN VARCHAR IS

--THIS WILL RETURN THE USER

BEGIN

RETURN USER;

END GET_CURRENT_USER;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE PR_UPD_LOADING_START_TIME(P_SDS_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_DATETIME IN TIMESTAMP)

IS

 CURSOR GET_LOCATION IS
 SELECT SSX_SERVICE_LOCATIONS_UID_FK SLO_UID_PK,
        SDS_EMPLOYEES_UID_FK
   FROM SO_LOADINGS, SERV_SERV_LOC_SO
  WHERE SDS_SO_UID_FK = SSX_SO_UID_FK
    AND SDS_COMPLETED_FL = 'N'
    AND SSX_END_DATE IS NULL
    AND SDS_UID_PK = P_SDS_UID_PK
 UNION
 SELECT SSL_SERVICE_LOCATIONS_UID_FK SLO_UID_PK,
        SDS_EMPLOYEES_UID_FK
   FROM SO_LOADINGS, SO, SO_TYPES, SERVICES, SERV_SERV_LOCATIONS
  WHERE SVO_UID_PK = SDS_SO_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SVC_UID_PK = SSL_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SDS_COMPLETED_FL = 'N'
    AND SOT_SYSTEM_CODE != 'MS'
    AND SSL_END_DATE IS NULL
    AND SDS_UID_PK = P_SDS_UID_PK;

CURSOR JOBS (P_EMP_UID_PK IN NUMBER, P_SLO_UID_PK IN NUMBER) IS
 SELECT SDS_UID_PK
   FROM CUSTOMERS, ACCOUNTS, EMPLOYEES, SO_LOADINGS, SO, SO_STATUS, SO_TYPES, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOC_SO
  WHERE SVO_UID_PK = SDS_SO_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SVO_UID_PK = SSX_SO_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND EMP_UID_PK = SDS_EMPLOYEES_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
    AND SSX_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
    AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID')
    AND SDS_COMPLETED_FL = 'N'
    AND SSX_END_DATE IS NULL
    AND SDS_SCHEDULE_DATE = TRUNC(SYSDATE)
    AND SDS_EMPLOYEES_UID_FK = P_EMP_UID_PK
 UNION
 SELECT SDS_UID_PK
   FROM CUSTOMERS, ACCOUNTS, EMPLOYEES, SO_LOADINGS, SO, SO_STATUS, SO_TYPES, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOCATIONS
  WHERE SVO_UID_PK = SDS_SO_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SVC_UID_PK = SSL_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND EMP_UID_PK = SDS_EMPLOYEES_UID_FK
    AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
    AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
    AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID')
    AND SDS_COMPLETED_FL = 'N'
    AND SOT_SYSTEM_CODE != 'MS'
    AND SSL_END_DATE IS NULL
    AND SDS_SCHEDULE_DATE = TRUNC(SYSDATE)
    AND SDS_EMPLOYEES_UID_FK = P_EMP_UID_PK;

V_SLO_UID_PK  NUMBER;
V_EMP_UID_PK  NUMBER;

BEGIN

IF P_SDS_UID_PK IS NOT NULL THEN

   IF P_TYPE = 'S' THEN
      IF P_DATETIME IS NULL THEN
         UPDATE SO_LOADINGS
            SET SDS_WORK_START_TIME = SYSDATE
          WHERE SDS_UID_PK = P_SDS_UID_PK;
      ELSE
         UPDATE SO_LOADINGS
            SET SDS_WORK_START_TIME = P_DATETIME
          WHERE SDS_UID_PK = P_SDS_UID_PK;
      END IF;
   ELSE
      UPDATE TROUBLE_DISPATCHES
         SET TDP_START_WORK_TIME = SYSDATE,
             TDP_START_WORK_DATE = TRUNC(SYSDATE)
       WHERE TDP_UID_PK = P_SDS_UID_PK;
   END IF;

   COMMIT;

   IF P_TYPE = 'S' THEN
      OPEN GET_LOCATION;
      FETCH GET_LOCATION INTO V_SLO_UID_PK, V_EMP_UID_PK;
      IF GET_LOCATION%FOUND THEN
         FOR REC IN JOBS(V_EMP_UID_PK, V_SLO_UID_PK) LOOP
            IF P_DATETIME IS NULL THEN
               UPDATE SO_LOADINGS
                  SET SDS_WORK_START_TIME = SYSDATE
                WHERE SDS_UID_PK = REC.SDS_UID_PK;
            ELSE
               UPDATE SO_LOADINGS
                  SET SDS_WORK_START_TIME = P_DATETIME
                WHERE SDS_UID_PK = REC.SDS_UID_PK;
            END IF;

            COMMIT;
         END LOOP;
      END IF;
      CLOSE GET_LOCATION;
   END IF;
END IF;

END PR_UPD_LOADING_START_TIME;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION GET_CREATED_ORDER_REP(P_SDS_UID_PK IN NUMBER)

RETURN VARCHAR IS

--THIS WILL RETURN THE EMPLOYEE'S EMAIL OF THE REP WHO CREATED THE ORDER

CURSOR GET_REP_EMAIL IS
  SELECT USR_E_MAIL
    FROM USERS, EMPLOYEES, SO, SO_LOADINGS
   WHERE EMP_UID_PK = SVO_EMPLOYEES_UID_FK
     AND EMP_UID_PK = USR_EMPLOYEES_UID_FK
     AND SVO_UID_PK = SDS_SO_UID_FK
     AND SDS_UID_PK = P_SDS_UID_PK;

 V_EMAIL  VARCHAR2(2000) := NULL;

BEGIN

OPEN GET_REP_EMAIL;
FETCH GET_REP_EMAIL INTO V_EMAIL;
CLOSE GET_REP_EMAIL;

RETURN V_EMAIL;

END GET_CREATED_ORDER_REP;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION GET_CREATED_ORDER_SUP(P_SDS_UID_PK IN NUMBER)

RETURN VARCHAR IS

--THIS WILL RETURN THE EMPLOYEE'S EMAIL OF THE REP WHO CREATED THE ORDER

CURSOR GET_REP_EMAIL IS
  SELECT USR_E_MAIL
    FROM USERS, EMPLOYEES, SO, SO_LOADINGS
   WHERE EMP_UID_PK = SVO_EMPLOYEES_UID_FK
     AND EMP_SUPERVISOR = USR_EMPLOYEES_UID_FK
     AND SVO_UID_PK = SDS_SO_UID_FK
     AND SDS_UID_PK = P_SDS_UID_PK;

 V_EMAIL  VARCHAR2(2000) := NULL;

BEGIN

OPEN GET_REP_EMAIL;
FETCH GET_REP_EMAIL INTO V_EMAIL;
CLOSE GET_REP_EMAIL;

RETURN V_EMAIL;

END GET_CREATED_ORDER_SUP;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_RUN_SANITY(P_SVO_UID_PK IN NUMBER, p_svc_uid_pk in number default null)

RETURN VARCHAR IS

--THIS WILL THE MESSAGES WE HAVE IF THE BOXES OR CABLE MODEMS ARE GOOD TO GO OR BAD IN SOME WAY

v_assignments     		BOOLEAN;
v_myrio           		BOOLEAN;
v_stb_count       		BOOLEAN;
v_dslam_ports     		BOOLEAN;
v_stbs_assgnd     		BOOLEAN;
v_myrio_pkg       		BOOLEAN;
v_myrio_stbs      		BOOLEAN;
v_status          		VARCHAR2(100);
v_iptv_msg        		VARCHAR2(4000);
v_cable_modem_msg 		VARCHAR2(4000);
v_id                  VARCHAR2(80);
v_return_msg  		VARCHAR2(4000);
v_sort_by         		VARCHAR2(80);
v_lno_uid_pk      		NUMBER;

V_SEL_PROCEDURE_NAME	VARCHAR2(40):= 'FN_RUN_SANITY';


BEGIN

IF INSTALLER_WEB_PKG.serv_sub_and_so_type(p_svo_uid_pk, 'CTV', 'ADSL', null) THEN

   v_id := SO_CLOSING_IVR_PKG.GET_IPTV_IDENTIFIER(p_svo_uid_pk);

   iptv_diagnostics.iptv_diagnose_service(v_id,
                                          v_assignments,
                                          v_myrio,
                                          v_stb_count,
                                          v_dslam_ports,
                                          v_stbs_assgnd,
                                          v_myrio_pkg,
                                          v_myrio_stbs,
                                          v_status,
                                          v_iptv_msg);

  v_return_msg := 'Status is '||v_status||':  '||v_iptv_msg;

ELSIF INSTALLER_WEB_PKG.serv_sub_and_so_type(p_svo_uid_pk, null, 'CABLE MODEM', null) 
  OR INSTALLER_WEB_PKG.serv_sub_and_so_type(p_svo_uid_pk, null, 'RFOG', null) 
  OR INSTALLER_WEB_PKG.FN_MTA_ON_LOC(P_SVO_UID_PK) = 'Y' OR INSTALLER_WEB_PKG.FN_MTA_ON_LOC(NULL, P_SVC_UID_PK) = 'Y' THEN

   IF p_svo_uid_pk is not null then
      IF INSTALLER_WEB_PKG.CHECK_CBM_STATUS(p_svo_uid_pk, v_cable_modem_msg) THEN
         NULL;
      END IF;
   ELSE
      IF INSTALLER_WEB_PKG.CHECK_CBM_STATUS(NULL, v_cable_modem_msg, P_SVC_UID_PK) THEN
         NULL;
      END IF;
   END IF;

   v_return_msg := v_cable_modem_msg;

ELSE
   v_return_msg := 'This service order should not require a sanity check.';
END IF;

RETURN v_return_msg;

IF P_SVO_UID_PK IS NOT NULL THEN
	 IF v_return_msg IS NOT NULL THEN
   		PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 END IF;
END IF;

END FN_RUN_SANITY;

/*-------------------------------------------------------------------------------------------------------------*/
--SERVICE AND SO TYPE
--THIS FUNCTION WILL RETURN TRUE IF THE SERVICE ORDER PROVIDED IS OF THE SERVICE TYPE AND SO TYPE PROVIDED

FUNCTION SERV_SUB_AND_SO_TYPE(p_svo_uid_pk      IN NUMBER,
                              p_sty_system_code IN VARCHAR2,
                              p_svt_system_code IN VARCHAR2,
                              p_sot_system_code IN VARCHAR2) RETURN BOOLEAN IS

CURSOR sty_svt_sot(cp_svo_uid_pk      NUMBER,
                                     cp_sty_system_code VARCHAR2,
                                     cp_svt_system_code VARCHAR2,
                                     cp_sot_system_code VARCHAR2) IS
SELECT 'X'
  FROM so,
       so_types,
           service_types,
           office_serv_types,
           off_serv_subs,
           serv_sub_types,
           services
WHERE svc_office_serv_types_uid_fk   = ost_uid_pk
  AND ost_service_types_uid_fk       = sty_uid_pk
    AND svo_services_uid_fk            = svc_uid_pk
    AND svo_so_types_uid_fk            = sot_uid_pk
    --AND OSB_OFFICE_SERV_TYPES_UID_FK   = ost_uid_pk
    AND svo_off_serv_subs_uid_fk       = osb_uid_pk
    AND OSB_SERV_SUB_TYPES_UID_FK      = svt_uid_pk
    AND svo_uid_pk                     = cp_svo_uid_pk
    AND sty_system_code                = NVL(cp_sty_system_code,sty_system_code)
    AND svt_system_code                = NVL(cp_svt_system_code,svt_system_code)
    AND sot_system_code                = NVL(cp_sot_system_code,sot_system_code);

v_exists VARCHAR2(1);

BEGIN

  OPEN sty_svt_sot(p_svo_uid_pk,
                                     p_sty_system_code,
                                     p_svt_system_code,
                                     p_sot_system_code);
  FETCH sty_svt_sot INTO v_exists;
    IF sty_svt_sot%FOUND THEN
      RETURN(TRUE);
    ELSE
      RETURN(FALSE);
    END IF;
  CLOSE sty_svt_sot;

 END SERV_SUB_AND_SO_TYPE;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION GET_TERMS_TEXT(p_spanish_english_fl IN VARCHAR2)

RETURN CLOB IS

--THIS WILL RETURN THE TERMS AND CONDITIONS TEXT VALUE TO BE DISPLAYED ON THE WEB SITE

--THIS CURSOR WILL GET THE TEXT VALUE BASED ON WHAT VERSION IS PASSED IN AND WHICH RECORD IS ACTIVE (TAC_END_DATE IS NULL)
CURSOR GET_TEXT IS
SELECT TAC_TEXT
  FROM TERMS_CONTRACTS
 WHERE TAC_LANGUAGE_TYPE = UPPER(p_spanish_english_fl)
   AND TAC_END_DATE IS NULL;

V_TEXT_VALUE  CLOB;


BEGIN

OPEN GET_TEXT;
FETCH GET_TEXT INTO V_TEXT_VALUE;
IF GET_TEXT%NOTFOUND THEN
   V_TEXT_VALUE := NULL;
END IF;
CLOSE GET_TEXT;

RETURN V_TEXT_VALUE;

END GET_TERMS_TEXT;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION GET_EMPLOYEE_PK_USER(P_LOGIN IN VARCHAR)

RETURN NUMBER IS

--THIS WILL RETURN THE EMPLOYEE PK OF THE USER LOGGED IN
CURSOR GET_EMPLOYEE_PK IS
SELECT USR_EMPLOYEES_UID_FK
  FROM USERS
 WHERE USR_LOGIN = UPPER(P_LOGIN);

 V_EMP_UID_PK   NUMBER := NULL;

BEGIN

OPEN GET_EMPLOYEE_PK;
FETCH GET_EMPLOYEE_PK INTO V_EMP_UID_PK;
IF GET_EMPLOYEE_PK%NOTFOUND THEN
   V_EMP_UID_PK := NULL;
END IF;
CLOSE GET_EMPLOYEE_PK;

RETURN V_EMP_UID_PK;

END GET_EMPLOYEE_PK_USER;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE PR_GENERATE_EMAIL_LINK(P_CUS_UID_PK IN NUMBER)

IS

 CURSOR GET_ORDERS IS
 SELECT initcap(CUS_FNAME||DECODE(CUS_FNAME,NULL,'',' ')||CUS_LNAME) CUS_NAME,
        STY_DESCRIPTION,
        GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK) IDENTIFIER,
        TO_CHAR(SDS_SCHEDULE_DATE,'MM/DD/YYYY') SCHEDULE_DATE,
        TO_CHAR(SDS_SCHEDULE_TIME,'HH:MI:SS AM')||' and '||TO_CHAR(SDS_SCHEDULE_TIME + .083333,'HH:MI:SS AM') TIME_PERIOD,
        EMP_FNAME||' '||EMP_LNAME EMP_NAME,
        TO_CHAR(SO_LOADINGS.CREATED_DATE,'MM/DD/YYYY') CREATED_DATE,
        CUS_LOGIN,
        CUS_EMAIL,
        CUS_BUSINESS_OFFICES_UID_FK,
        SVO_UID_PK,
        TO_CHAR(SDS_SCHEDULE_DATE + 1,'MM/DD/YYYY') SCHED_DATE,
        TO_CHAR(SO_LOADINGS.CREATED_DATE,'HH:MI:SS AM') SCHED_TIME,
        SOT_SYSTEM_CODE,
        CSP_SYSTEM_CODE,
        ANT_SYSTEM_CODE
   FROM CUSTOMER_TYPES, ACCOUNT_TYPES, CUSTOMERS, ACCOUNTS, EMPLOYEES, USERS, SO_LOADINGS, SO, SO_TYPES, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES
  WHERE SVO_UID_PK = SDS_SO_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND EMP_UID_PK = USR_EMPLOYEES_UID_FK
    AND USR_LOGIN  = SO_LOADINGS.CREATED_BY
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND SDS_COMPLETED_FL = 'N'
    AND SOT_SYSTEM_CODE != 'CS'
    AND SUBSTR(SDS_COMMENT,1,2) != 'MO'
    AND CSP_UID_PK = CUS_CUSTOMER_TYPES_UID_FK
    AND ANT_UID_PK = ACC_ACCOUNT_TYPES_UID_FK
    AND CUS_UID_PK = P_CUS_UID_PK
    AND TRUNC(SO_LOADINGS.CREATED_DATE) = TRUNC(SYSDATE)
 UNION
 SELECT initcap(CUS_FNAME||DECODE(CUS_FNAME,NULL,'',' ')||CUS_LNAME) CUS_NAME,
        STY_DESCRIPTION,
        GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK) IDENTIFIER,
        TO_CHAR(SDS_SCHEDULE_DATE,'MM/DD/YYYY') SCHEDULE_DATE,
        TO_CHAR(SDS_SCHEDULE_TIME,'HH:MI:SS AM')||' and '||TO_CHAR(SDS_SCHEDULE_TIME + .083333,'HH:MI:SS AM') TIME_PERIOD,
        EMP_FNAME||' '||EMP_LNAME EMP_NAME,
        TO_CHAR(SO_LOADINGS.CREATED_DATE,'MM/DD/YYYY') CREATED_DATE,
        CUS_LOGIN,
        CUS_EMAIL,
        CUS_BUSINESS_OFFICES_UID_FK,
        SVO_UID_PK,
        TO_CHAR(SDS_SCHEDULE_DATE + 1,'MM/DD/YYYY') SCHED_DATE,
        TO_CHAR(SO_LOADINGS.CREATED_DATE,'HH:MI:SS AM') SCHED_TIME,
        SOT_SYSTEM_CODE,
        CSP_SYSTEM_CODE,
        ANT_SYSTEM_CODE
   FROM CUSTOMER_TYPES, ACCOUNT_TYPES, CUSTOMERS, ACCOUNTS, EMPLOYEES, USERS, SO_LOADINGS, SO, SO_TYPES, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES
  WHERE SVO_UID_PK = SDS_SO_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND CSP_UID_PK = CUS_CUSTOMER_TYPES_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND EMP_UID_PK = USR_EMPLOYEES_UID_FK
    AND USR_LOGIN  = SO_LOADINGS.CREATED_BY
    AND SDS_COMPLETED_FL = 'N'
    AND SOT_SYSTEM_CODE != 'MS'
    AND SOT_SYSTEM_CODE != 'CS'
    AND CUS_UID_PK = P_CUS_UID_PK
    AND ANT_UID_PK = ACC_ACCOUNT_TYPES_UID_FK
    AND TRUNC(SO_LOADINGS.CREATED_DATE) = TRUNC(SYSDATE);

 cursor get_so_loc(psvo_uid_pk number) is
        select SERV_LOCS.GET_SERV_LOC(ssx_service_locations_uid_fk)
          from service_locations, serv_serv_loc_so
         where ssx_so_uid_fk = psvo_uid_pk
           and slo_uid_pk = ssx_service_locations_uid_fk
           and ssx_primary_loc_fl = 'Y'
           and ssx_end_date is null;

 cursor get_svc_loc(psvo_uid_pk number) is
        select SERV_LOCS.GET_SERV_LOC(ssl_service_locations_uid_fk)
          from service_locations, serv_serv_locations, services, so
         where ssl_services_uid_fk = svc_uid_pk
           and slo_uid_pk = ssl_service_locations_uid_fk
           and ssl_primary_loc_fl = 'Y'
           and ssl_end_date is null
           and svo_uid_pk = psvo_uid_pk
           and svo_services_uid_fk = svc_uid_pk;

CURSOR CHECK_TOKEN_FOUND IS
  SELECT CSI_UID_PK
    FROM CUS_SECONDARY_INFO
   WHERE CSI_CUSTOMERS_UID_FK = P_CUS_UID_PK;

 V_TERMS_NEEDED        VARCHAR2(1) := 'N';
 V_CONTRACT_NEEDED     VARCHAR2(1) := 'N';
 v_contract_end_date   date;
 v_sof_uid_pk          number;
 v_csi_uid_pk          number;
 v_bso_uid_pk          number;
 v_term_amount         number;
 v_char_end_date       varchar2(20);
 v_contract_ftp_uid_pk NUMBER;
 v_contract_ftp_code   varchar2(80);
 v_svt_description     varchar2(80) := NULL;
 v_message_body        varchar2(10000);
 v_message_terms       varchar2(2000);
 v_message_link        varchar2(2000);
 v_message_end         varchar2(2000);
 v_message_txt         varchar2(2000);
 v_subject_txt         varchar2(80);
 v_services_display    varchar2(2000) := NULL;
 v_schedule_date       varchar2(80);
 v_sched_date          varchar2(80);
 v_sched_time          varchar2(80);
 v_created_date        varchar2(80);
 v_cus_login           varchar2(80);
 v_time_period         varchar2(80);
 v_emp_name            varchar2(80);
 v_cus_name            varchar2(300);
 v_cus_email           varchar2(300);
 crlf                  VARCHAR2(2):= CHR(13) || CHR(10);
 V_LOOP_COUNT          NUMBER := 0;
 v_unix_time           NUMBER;
 v_unix_date           DATE;
 V_INSTANCE_NAME       VARCHAR2(80);
 v_slo_description     VARCHAR2(2000);
 v_new_tos_msg         BOOLEAN := FALSE;
 v_from                VARCHAR2(80);
 v_csp_system_code     VARCHAR2(12);
 

 rec                   system_rules%rowtype;

BEGIN

IF P_CUS_UID_PK IS NOT NULL THEN

   FOR REC IN GET_ORDERS LOOP
     IF rec.sot_system_code in ('NS','RI','MS') AND rec.csp_system_code in ('RES','RESORT') AND rec.ant_system_code = 'RES' THEN
       v_new_tos_msg := TRUE;
     END IF;

     V_LOOP_COUNT := V_LOOP_COUNT + 1;
     IF rec.cus_email is not null AND rec.cus_email != 'N/A' then

        OPEN get_so_loc(rec.svo_uid_pk);
        FETCH get_so_loc INTO v_slo_description;
        IF get_so_loc%NOTFOUND THEN
           OPEN get_svc_loc(rec.svo_uid_pk);
           FETCH get_svc_loc INTO v_slo_description;
           CLOSE get_svc_loc;
        END IF;
        CLOSE get_so_loc;

        IF V_LOOP_COUNT <= 3 THEN  --ONLY DISPLAY FIRST 3
           v_services_display := v_services_display||REC.STY_DESCRIPTION||' '||REC.IDENTIFIER||' AT '||v_slo_description||crlf;
        END IF;

        V_CUS_NAME      := REC.CUS_NAME;
        v_schedule_date := rec.schedule_date;
        v_time_period   := rec.time_period;
        v_emp_name      := rec.emp_name;
        v_cus_login     := rec.cus_login;
        v_created_date  := rec.created_date;
        v_cus_email     := rec.cus_email;
        v_sched_date    := rec.sched_date;
        v_sched_time    := rec.sched_time;
        v_bso_uid_pk    := rec.cus_business_offices_uid_fk;
        v_csp_system_code := rec.csp_system_code ;

        --THE FOLLOWING WILL CHECK IF THE TERMS AND CONDITIONS ARE EVEN NEEDED FOR THIS CUSTOMER
        --CURRENTLY THEY ARE IF PART OF THE ORDER REQUIRES NEW SERVICE
        IF INSTALLER_WEB_PKG.TERMS_CONDITIONS_NEEDED(p_cus_uid_pk) THEN
           v_terms_needed := 'Y';
        ELSE
           v_terms_needed := 'N';
        END IF;
        --

     END IF;

  END LOOP;

  --v_unix_date := TO_DATE(v_sched_date||v_sched_time,'MM/DD/YYYY HH:MI:SS AM');
  --v_unix_time := INSTALLER_WEB_PKG.DATETIME_TO_UNIX_TIME(v_unix_date);

  IF v_services_display IS NOT NULL  THEN --FOUND IN THE LOOP ABOVE
     --create email
     IF v_csp_system_code in ('RES','RESORT') THEN
         v_from := system_rules_pkg.get_char_value('SCHEDULING','CONF_EMAIL','RES_FROM');
         v_subject_txt  := system_rules_pkg.get_char_value('SCHEDULING','CONF_EMAIL','RES_SUBJECT');
         v_message_body := REPLACE(REPLACE(REPLACE(REPLACE(system_rules_pkg.get_clob_value('SCHEDULING','CONF_EMAIL','RES_HEADER'),
                                               '<customer_name>',
                                                v_cus_name),
                                       '<employee_name>',
                                       v_emp_name),
                                   '<date>',
                                   v_created_date),
                                   '<list_of_services>', RTRIM(v_services_display,','));
         IF v_new_tos_msg THEN
           v_message_body := v_message_body||system_rules_pkg.get_clob_value('SCHEDULING','CONF_EMAIL','RES_BODY');
         END IF;
         
         v_message_end := system_rules_pkg.get_clob_value('SCHEDULING','CONF_EMAIL','RES_FOOTER');

       ELSE
         v_from := system_rules_pkg.get_char_value('SCHEDULING','CONF_EMAIL',v_CSP_SYSTEM_CODE||'_FROM');
         v_subject_txt  := system_rules_pkg.get_char_value('SCHEDULING','CONF_EMAIL',V_CSP_SYSTEM_CODE||'_SUBJECT');
         v_message_body := REPLACE(REPLACE(REPLACE(REPLACE(system_rules_pkg.get_clob_value('SCHEDULING','CONF_EMAIL',V_CSP_SYSTEM_CODE||'_HEADER'),
                                               '<customer_name>',
                                               v_cus_name),
                                       '<employee_name>',
                                       v_emp_name),
                                   '<date>',
                                   v_created_date),
                                   '<list_of_services>', RTRIM(v_services_display,','));

         IF v_new_tos_msg THEN
           v_message_body := v_message_body||system_rules_pkg.get_clob_value('SCHEDULING','CONF_EMAIL',V_CSP_SYSTEM_CODE||'_BODY');
         END IF;
         
         v_message_end := system_rules_pkg.get_clob_value('SCHEDULING','CONF_EMAIL',V_CSP_SYSTEM_CODE||'_FOOTER');
         
       END IF;
       
       v_message_txt := v_message_body||v_message_end;

     /*IF v_terms_needed = 'Y' OR v_cus_login is null THEN

        IF v_terms_needed = 'Y' AND v_cus_login is null THEN
           v_message_terms := 'The services you have requested require you '|| crlf ||
                              'to create a login account with Hargray as well as to accept a terms agreement.'|| crlf;
        ELSIF v_terms_needed = 'Y' AND v_cus_login is not null THEN
           v_message_terms := 'The services you have requested require you '|| crlf ||
                              'to accept a terms agreement.'|| crlf ;
        ELSE
           v_message_terms := 'The services you have requested require you '|| crlf ||
                                 'to create a login account with Hargray.'|| crlf ;
        END IF;

        --INSERT OR UPDATE A RECORD INTO THE CUS_SECONDARY_INFO TABLE
        OPEN CHECK_TOKEN_FOUND;
        FETCH CHECK_TOKEN_FOUND INTO v_csi_uid_pk;
        IF CHECK_TOKEN_FOUND%FOUND THEN
           UPDATE CUS_SECONDARY_INFO
              SET CSI_ACTIVATE_TOKEN = TO_DATE(v_sched_date||v_sched_time,'MM/DD/YYYY HH:MI:SS AM')
            WHERE CSI_UID_PK = v_csi_uid_pk;
        ELSE
           INSERT INTO CUS_SECONDARY_INFO(CSI_UID_PK, CSI_CUSTOMERS_UID_FK, CSI_ACTIVATE_TOKEN)
                                   VALUES(CSI_SEQ.NEXTVAL, P_CUS_UID_PK, TO_DATE(v_sched_date||v_sched_time,'MM/DD/YYYY HH:MI:SS AM'));
        END IF;
        CLOSE CHECK_TOKEN_FOUND;
        --

        v_message_link := 'Please select the following link at your convenience to complete this information.'|| crlf ||
             ' '|| crlf ||
             '  https://myaccount.hargray.com/account_activation/sessions/account_info/'||P_CUS_UID_PK||'|'||v_unix_time|| crlf ||
             ' '|| crlf ||
             'If you cannot click this link, just copy and paste the address'|| crlf ||
             'into your Internet browser''s address bar.'|| crlf ||
             ' '|| crlf;
     END IF;*/

   dbms_output.put_line(v_subject_txt);

     IF v_cus_email IS NOT NULL AND v_subject_txt IS NOT NULL THEN
         rec := system_rules_pkg.GET('SCHEDULING',
                                       'SCHEDULING',
                                       'SEND_AUTO');
         IF GET_DATABASE_FUN NOT IN ('HES1','HES2','HES3','HES','PROD') THEN
            v_cus_email := system_rules_pkg.get_char_value('SCHEDULING','CONF_EMAIL',GET_DATABASE_FUN||'_TO');
         END IF;
        IF REC.SRU_CHARACTER_VALUE = 'Y' THEN  --SEND EMAIL
            mailx.ext_send_mail_message(v_cus_email
                                       ,v_subject_txt
                                       ,v_message_txt
                                       ,v_from);
        END IF;


     END IF;
  END IF;

END IF;

END PR_GENERATE_EMAIL_LINK;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_EMAIL_LINK_DATA (P_CUS_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

CURSOR GET_ORDERS_CUR IS
 SELECT TO_DATE(TO_CHAR(SDS_SCHEDULE_DATE,'MM-DD-YYYY')||TO_CHAR(SDS_SCHEDULE_TIME,' HH:MI AM'),'MM-DD-YYYY HH:MI AM') SCHEDULE_TIME,
        SDS_UID_PK,
        CUS_LOGIN,
        SVC_UID_PK,
        SVO_UID_PK,
        SSX_SERVICE_LOCATIONS_UID_FK SLO_UID_PK,
        SERV_LOCS.GET_SERV_LOC(SSX_SERVICE_LOCATIONS_UID_FK) LOCATION,
        SOT_CODE,
        STY_CODE
   FROM CUSTOMERS, ACCOUNTS, EMPLOYEES, USERS, SO_LOADINGS, SO, SO_TYPES, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES,  SERV_SERV_LOC_SO
  WHERE SVO_UID_PK = SDS_SO_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND EMP_UID_PK = USR_EMPLOYEES_UID_FK
    AND USR_LOGIN  = SO_LOADINGS.CREATED_BY
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND SVO_UID_PK = SSX_SO_UID_FK
    AND SDS_COMPLETED_FL = 'N'
    AND SSX_END_DATE IS NULL
    AND CUS_UID_PK = P_CUS_UID_PK
 UNION
 SELECT TO_DATE(TO_CHAR(SDS_SCHEDULE_DATE,'MM-DD-YYYY')||TO_CHAR(SDS_SCHEDULE_TIME,' HH:MI AM'),'MM-DD-YYYY HH:MI AM') SCHEDULE_TIME,
        SDS_UID_PK,
        CUS_LOGIN,
        SVC_UID_PK,
        SVO_UID_PK,
        SSL_SERVICE_LOCATIONS_UID_FK SLO_UID_PK,
        SERV_LOCS.GET_SERV_LOC(SSL_SERVICE_LOCATIONS_UID_FK) LOCATION,
        SOT_CODE,
        STY_CODE
   FROM CUSTOMERS, ACCOUNTS, EMPLOYEES, USERS, SO_LOADINGS, SO, SO_TYPES, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOCATIONS
  WHERE SVO_UID_PK = SDS_SO_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND EMP_UID_PK = USR_EMPLOYEES_UID_FK
    AND SVC_UID_PK = SSL_SERVICES_UID_FK
    AND USR_LOGIN  = SO_LOADINGS.CREATED_BY
    AND SSL_END_DATE IS NULL
    AND SDS_COMPLETED_FL = 'N'

    AND SOT_SYSTEM_CODE != 'MS'
    AND CUS_UID_PK = P_CUS_UID_PK;

CURSOR CUS_AGREEMENTS(P_CUS_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER) IS
  SELECT 'Y'
    FROM CUS_AGREEMENTS, CUS_AGR_SERVICES
   WHERE CAM_CUSTOMERS_UID_FK = P_CUS_UID_PK
     AND CAM_UID_PK = CAE_CUS_AGREEMENTS_UID_FK
     AND CAE_SERVICES_UID_FK = P_SVC_UID_PK
     AND CAM_TERMS_ACCEPTED_FL = 'Y';

CURSOR CUS_AGR_NOT_ACCEPT(P_CUS_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER) IS
  SELECT 'Y'
    FROM CUS_AGREEMENTS, CUS_AGR_SERVICES
   WHERE CAM_CUSTOMERS_UID_FK = P_CUS_UID_PK
     AND CAM_UID_PK = CAE_CUS_AGREEMENTS_UID_FK
     AND CAE_SERVICES_UID_FK = P_SVC_UID_PK
     AND CAM_TERMS_ACCEPTED_FL = 'N';

 CURSOR CONNECTIONS_INCENTIVE(P_CUS_UID_PK IN NUMBER) IS
   SELECT ABS(RTS_AMOUNT)
     FROM ACCOUNTS, SERVICES, SO, RATES, FEATURES, OFFICE_SERV_FEATS, SO_FEATURES
    WHERE FTP_UID_PK = RTS_FEATURES_UID_FK
      AND OSF_UID_PK = SOF_OFFICE_SERV_FEATS_UID_FK
      AND FTP_UID_PK = OSF_FEATURES_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND SVC_UID_PK = SVO_SERVICES_UID_FK
      AND SVO_UID_PK = SOF_SO_UID_FK
      AND ACC_CUSTOMERS_UID_FK = P_CUS_UID_PK
      AND FTP_CODE IN ('CXLCR', 'KCXLCR')
      AND SOF_ACTION_FL = 'A';

 v_rec                 generic_data_type;
 rec                   GET_ORDERS_CUR%rowtype;
 v_count               number := 0;
 v_login_found         varchar2(1);
 v_terms_accepted      varchar2(1) := 'N';
 v_contract_end_date   date;
 v_sof_uid_pk          number;
 v_term_amount         number;
 v_char_end_date       varchar2(20);
 v_contract_ftp_uid_pk NUMBER;
 v_contract_ftp_code   varchar2(80);
 V_SVT_SYSTEM_CODE     varchar2(80);
 V_CONNECTION_INC_AMT  NUMBER;

BEGIN

OPEN GET_ORDERS_CUR;
 LOOP
    FETCH GET_ORDERS_CUR into rec;
    EXIT WHEN GET_ORDERS_CUR%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_number1    := rec.sds_uid_pk;          -- SDS pk
     v_rec.gdt_date1      := rec.schedule_time;       -- schedule time of the appointment
     v_rec.gdt_number4    := rec.svo_uid_pk;          -- SO pk
     v_rec.gdt_number5    := rec.slo_uid_pk;          -- service_locations pk
     v_rec.gdt_alpha6     := rec.location;            -- service location
     v_rec.gdt_alpha7     := rec.sot_code;            -- so_types code
     v_rec.gdt_alpha8     := rec.sty_code;            -- service type code

     --check for as customer login
     IF rec.cus_login IS NOT NULL THEN
        v_login_found := 'Y';
     ELSE
        v_login_found := 'N';
     END IF;
     v_rec.gdt_alpha1     := v_login_found;

     --Check if the terms and conditions have already been accepted.
     OPEN CUS_AGREEMENTS(p_cus_uid_pk, rec.svc_uid_pk);
     FETCH CUS_AGREEMENTS INTO v_terms_accepted;
     IF CUS_AGREEMENTS%NOTFOUND THEN
        OPEN CUS_AGR_NOT_ACCEPT(p_cus_uid_pk, rec.svc_uid_pk);
        FETCH CUS_AGR_NOT_ACCEPT INTO v_terms_accepted;
        IF CUS_AGR_NOT_ACCEPT%NOTFOUND THEN
           v_terms_accepted := NULL;
        ELSE
           v_terms_accepted := 'N';
        END IF;
        CLOSE CUS_AGR_NOT_ACCEPT;
     END IF;
     CLOSE CUS_AGREEMENTS;

     v_rec.gdt_alpha2     := v_terms_accepted;
     --

     --THE FOLLOWING WILL CHECK IF THE TERMS AND CONDITIONS ARE EVEN NEEDED FOR THIS CUSTOMER
     --CURRENTLY THEY ARE IF PART OF THE ORDER REQUIRES NEW SERVICE
     IF INSTALLER_WEB_PKG.TERMS_CONDITIONS_NEEDED(p_cus_uid_pk) THEN
        v_rec.gdt_alpha3 := 'Y';
     ELSE
        v_rec.gdt_alpha3 := 'N';
     END IF;
     --

     --THIS WILL GET THE CONTRACT INFORMATION TO PASS THROUGH
     IF INSTALLER_WEB_PKG.CONTRACT_NEEDED(p_cus_uid_pk, v_contract_end_date, v_sof_uid_pk, v_term_amount, v_contract_ftp_uid_pk, v_contract_ftp_code) THEN
        v_rec.gdt_number2 := v_term_amount;
        v_char_end_date   := to_char(v_contract_end_date,'mm-dd-yyyy');
        v_rec.gdt_alpha4  := v_char_end_date;
     ELSE
        v_rec.gdt_number2 := NULL;
        v_rec.gdt_alpha4  := NULL;
     END IF;
     --


     --THE FOLLOWING WILL CHECK IF THE CONTRACT SHOULD DISPLAY PRORATED FOR THE TERMINATION AMOUNT
     IF v_contract_ftp_code in ('CXCT1Y','CXCT2Y') THEN
        v_rec.gdt_alpha5 := 'Y';
     ELSE
        v_rec.gdt_alpha5 := 'N';
     END IF;

     --THE FOLLOWING WILL CHECK IF THE CONNECTIONS INCENTIVE SECTION WILL NEED TO DISPLAY ON THE REPORT
     OPEN CONNECTIONS_INCENTIVE(p_cus_uid_pk);
     FETCH CONNECTIONS_INCENTIVE INTO V_CONNECTION_INC_AMT;
     IF CONNECTIONS_INCENTIVE%NOTFOUND THEN
        V_CONNECTION_INC_AMT := NULL;
     END IF;
     CLOSE CONNECTIONS_INCENTIVE;
     v_rec.gdt_number3 := V_CONNECTION_INC_AMT;
     --

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE GET_ORDERS_CUR;

RETURN;

END FN_EMAIL_LINK_DATA;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION DATETIME_TO_UNIX_TIME(P_DATETIME IN SO_LOADINGS.CREATED_DATE%TYPE)
RETURN NUMBER IS

v_days      number;
v_hours     number;
v_minutes   number;
v_seconds   number;

BEGIN

  select TRUNC(P_DATETIME) - TRUNC(to_date('01-01-1970 12:00:00 AM','MM-DD-YYYY HH:MI:SS AM'))
    into v_days
    from dual;

  select to_number(to_char(TRUNC(P_DATETIME,'HH24'),'HH24'))
    into v_hours
    from dual;

  select to_number(to_char(TRUNC(P_DATETIME,'MI'),'MI'))
    into v_minutes
    from dual;

  select TO_NUMBER(SUBSTR(TO_CHAR(P_DATETIME,'MM-DD-YYYY HH:MI:SS'),-2))
    into v_seconds
    from dual;

v_days    := v_days * 86400;
v_hours   := v_hours * 3600;
v_minutes := v_minutes * 60;

RETURN v_days + v_hours + v_minutes + v_seconds;

END DATETIME_TO_UNIX_TIME;

/*-------------------------------------------------------------------------------------------------------------*/

-- to add and provision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect

FUNCTION ADD_BOX(P_SERIAL#                  IN VARCHAR, 
                 P_EMP_UID_PK               IN NUMBER, 
                 P_CUS_UID_PK               IN NUMBER, 
                 P_SDS_UID_PK               IN NUMBER,
                 P_TYPE                     IN VARCHAR,    -- AS OF 1/2/13  - DOESN'T DO ANYTHING
                 P_DEVELOPMENT_ACTION       IN VARCHAR2 := 'S',
                 P_VALIDATE_ONLY_FL         IN VARCHAR2 := 'N')
RETURN VARCHAR IS

  CURSOR GET_TECH_LOCATION IS
   SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
     FROM TECH_EMP_LOCATIONS, EMPLOYEES
    WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
      AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
      AND TEO_END_DATE IS NULL;

  CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
    SELECT IVL_UID_PK
      FROM INVENTORY_LOCATIONS
     WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

  CURSOR CHECK_CATV_SERV_BOX_SO(P_SVO_UID_PK IN NUMBER) IS
    SELECT CBX_UID_PK, CBX_END_DATE
    FROM CATV_SERV_BOX_SO, CATV_CONV_BOXES, CATV_SO
    WHERE CCB_UID_PK = CBX_CATV_CONV_BOXES_UID_FK
      AND CTS_UID_PK = CBX_CATV_SO_UID_FK
      AND CTS_SO_UID_FK = P_SVO_UID_PK
      AND CCB_SERIAL# = P_SERIAL#;

  CURSOR GET_CATV_SO(P_SVO_UID_PK IN NUMBER) IS
    SELECT CTS_UID_PK
    FROM CATV_SO
    WHERE CTS_SO_UID_FK = P_SVO_UID_PK;

  CURSOR GET_SVO_PK IS
    SELECT SDS_SO_UID_FK
    FROM SO_LOADINGS
    WHERE SDS_UID_PK = P_SDS_UID_PK;

  CURSOR GET_SVC_PK (P_SVO_UID_PK NUMBER) IS
    SELECT SVO_SERVICES_UID_FK, SOT_SYSTEM_CODE
    FROM SO, SO_TYPES
    WHERE SVO_UID_PK = P_SVO_UID_PK
      AND SOT_UID_PK = SVO_SO_TYPES_UID_FK;

  CURSOR GET_IDENTIFIER IS
    SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_OFFICE_SERV_TYPES_UID_FK, SVC_UID_PK
    FROM SERVICES, SO, SO_LOADINGS
    WHERE SDS_UID_PK = P_SDS_UID_PK
      AND SVC_UID_PK = SVO_SERVICES_UID_FK
      AND SVO_UID_PK = SDS_SO_UID_FK;

  CURSOR SERV_SUB_TYPE(P_SVO_UID_PK IN NUMBER) IS
    SELECT OSB_OFFICE_SERV_TYPES_UID_FK, SVT_SYSTEM_CODE
    FROM OFF_SERV_SUBS, SO, SERV_SUB_TYPES
    WHERE OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
      AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
      AND SVO_UID_PK = P_SVO_UID_PK;

  CURSOR CABLE_MODEM_SUB(P_OST_UID_PK IN NUMBER) IS
    SELECT OSB_UID_PK
    FROM OFF_SERV_SUBS, SERV_SUB_TYPES
    WHERE SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
      AND SVT_SYSTEM_CODE = 'CABLE MODEM'
      AND OSB_OFFICE_SERV_TYPES_UID_FK = P_OST_UID_PK;

  CURSOR CHECK_CABLE_MODEM_SO(P_SVO_UID_PK IN NUMBER) IS
  select 'X'
  from so_assgnmts, cable_modems
  where cbm_uid_pk = son_cable_modems_uid_fk
    and son_so_uid_fk = P_SVO_UID_PK
    and cbm_mac_address = P_SERIAL#;


  CURSOR get_alopa_message(p_svo_uid_pk number) IS
   select 'X'
    from so_messages
   WHERE sog_so_uid_fk = p_svo_uid_pk
     AND sog_text = 'Alopa needs manual provisioning'
     --and created_by = 'PERLUSER'
     and created_by in ('HES','PERLUSER')
     and created_date > sysdate-5/1440;

  -- this is to check if cable modem provisioning is successful
  --   see main function comment on meaning of p_dev_action
  --   return NULL if C_DEV_FAILURE
  CURSOR see_prov_successful(p_svo_uid_pk number, P_DATE IN VARCHAR, p_is_production_db IN VARCHAR2, p_dev_action IN VARCHAR2) IS
    select 'X'
     from swt_logs
    WHERE sls_so_uid_fk = p_svo_uid_pk
      AND sls_success_fl = 'Y'
      and swt_logs.created_date >= to_date(P_DATE,'MM-DD-YYYY HH:MI:SS AM')
      and created_date > sysdate-5/1440
      and (p_is_production_db = 'Y'
           or
           (p_is_production_db = 'N' and p_dev_action = C_DEV_PRODUCTION)
          )
    UNION
    select 'X'
      from DUAL
     WHERE p_is_production_db = 'N'
       and p_dev_action        = C_DEV_SUCCESS;




  CURSOR GET_SEQ IS
   SELECT SEQ_UID_PK
     FROM SWT_EQUIPMENT
    WHERE SEQ_SYSTEM_CODE = 'ISP';

  CURSOR CHECK_EXIST_CANDIDATE(P_SVO_UID_PK IN NUMBER, P_SEQ_CODE IN VARCHAR) IS
   SELECT TO_CHAR(SO_CANDIDATES.MODIFIED_DATE,'MM-DD-YYYY HH:MI:SS AM')
     FROM SO_CANDIDATES, SWT_EQUIPMENT
    WHERE SOC_SO_UID_FK = P_SVO_UID_PK
      AND SEQ_UID_PK = SOC_SWT_EQUIPMENT_UID_FK
      AND SEQ_SYSTEM_CODE = P_SEQ_CODE
    ORDER BY TO_CHAR(SO_CANDIDATES.MODIFIED_DATE,'MM-DD-YYYY HH:MI:SS AM') desc;

   cursor get_bso is
     select cus_business_offices_uid_fk
       from customers
      where cus_uid_pk = p_cus_uid_pk;

   cursor check_if_mta (P_SVO_UID_PK IN NUMBER) IS
     SELECT MEU_UID_PK
       FROM MTA_SO, SO_ASSGNMTS, MTA_PORTS, MTA_EQUIP_UNITS
      WHERE SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
        AND MTP_UID_PK = MTO_MTA_PORTS_UID_FK
        AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
        AND SON_SO_UID_FK = P_SVO_UID_PK;

   cursor get_so_loc(p_svo_uid_pk in number) is
          select ssx_service_locations_uid_fk
            from service_locations, serv_serv_loc_so
           where ssx_so_uid_fk = p_svo_uid_pk
             and slo_uid_pk = ssx_service_locations_uid_fk
             and ssx_primary_loc_fl = 'Y'
             and ssx_end_date is null;

   cursor get_svc_loc(p_svo_uid_pk in number) is
          select ssl_service_locations_uid_fk
            from service_locations, serv_serv_locations, services, so
           where ssl_services_uid_fk = svc_uid_pk
             and slo_uid_pk = ssl_service_locations_uid_fk
             and ssl_primary_loc_fl = 'Y'
             and ssl_end_date is null
             and svo_uid_pk = p_svo_uid_pk
             and svo_services_uid_fk = svc_uid_pk;
             
  CURSOR GET_CABLE_MODEM_SVC(P_SVC_UID_PK IN NUMBER) IS
   SELECT CBM_MAC_ADDRESS, SVA_UID_PK, 'CBM'
     FROM SERVICE_ASSGNMTS, CABLE_MODEMS
    WHERE SVA_SERVICES_UID_FK = P_SVC_UID_PK
      AND CBM_UID_PK = SVA_CABLE_MODEMS_UID_FK
   UNION
    SELECT MTA_CMAC_ADDRESS, MEU_UID_PK, 'MTA'
      FROM MTA_SERVICES, SERVICE_ASSGNMTS, MTA_PORTS, MTA_EQUIP_UNITS, MTA_BOXES
     WHERE SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
       AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
       AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
       AND MTA_UID_PK = MEU_MTA_BOXES_UID_FK
       AND SVA_SERVICES_UID_FK = P_SVC_UID_PK;

  v_alopa_msg            varchar2(1);
  v_type                 varchar2(20);
  V_IVL_UID_PK           NUMBER;
  V_SLO_UID_PK           NUMBER;
  V_TVB_UID_PK           NUMBER;
  V_BSO_UID_PK           NUMBER;
  V_SEQ_UID_PK           NUMBER;
  V_SVO_UID_PK           NUMBER;
  V_SVC_UID_PK           NUMBER;
  V_CTS_UID_PK           NUMBER;
  V_CBX_UID_PK           NUMBER;
  V_ADM_UID_PK           NUMBER;
  V_DSP_UID_PK           NUMBER;
  V_MEU_UID_PK           NUMBER;
  V_BBO_MEO_UID_PK       NUMBER;
  V_LAST_IVL_UID_PK      NUMBER;
  V_OSB_UID_PK           NUMBER;
  V_OST_UID_PK           NUMBER;
  V_SON_UID_PK           NUMBER;
  V_SVT_CODE             VARCHAR2(40);
  V_SOT_CODE             VARCHAR2(40);
  V_EXIST_MAC            VARCHAR2(40);
  V_LAST_IVL_DESCRIPTION VARCHAR2(200);
  V_RETURN_MESSAGE       VARCHAR2(2000);
  V_SUCCESS              VARCHAR2(2000);
  V_EQUIP_TYPE           VARCHAR2(1);
 
  V_CCB_UID_PK           NUMBER;
  V_CBM_UID_PK           NUMBER;
  V_STATUS               VARCHAR2(200);
  V_DUMMY                VARCHAR2(1);
  V_CBX_ACTIVE_FL        VARCHAR2(1);
  V_CABLE_MODEM_TYPE     VARCHAR2(1);
  V_TIME                 VARCHAR2(200);
  V_SOR_COMMENT          VARCHAR2(2000);
  V_IDENTIFIER           VARCHAR2(200);
  V_DESCRIPTION          VARCHAR2(200);
  V_EMP_NAME             VARCHAR2(200);
  V_ACCOUNT              VARCHAR2(200);
  V_CBX_END_DATE         DATE;
  V_DATE                 DATE;
  V_CHAR_DATE            VARCHAR2(40);
  V_SLS_COMMENT          VARCHAR2(2000);
  V_SLS_DATE             VARCHAR2(40);
  V_PC_TO_CBM_FL         VARCHAR2(1);
  V_ISSUE_CHANGE_MAC     VARCHAR2(1);
  V_SAME_MAC             VARCHAR2(1);
  v_is_production_database  VARCHAR2(1);
  v_msg_suffix           VARCHAR2(100);
  rec_cbm                CABLE_MODEMS%ROWTYPE;
  
  V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'ADD_BOX';
  v_return_msg  		 VARCHAR2(4000);
  v_is_ccb_mmr_fl        VARCHAR2(1)  := 'Y';
  v_db VARCHAR2(30); 
BEGIN

  --GET BSO PK
  OPEN get_bso;
  FETCH get_bso INTO V_BSO_UID_PK;
  CLOSE get_bso;

  --GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
  OPEN GET_TECH_LOCATION;
  FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
  CLOSE GET_TECH_LOCATION;

  --GET SVO_UID_PK
  OPEN GET_SVO_PK;
  FETCH GET_SVO_PK INTO V_SVO_UID_PK;
  CLOSE GET_SVO_PK;

  --GET SVC_UID_PK
  OPEN GET_SVC_PK(V_SVO_UID_PK);
  FETCH GET_SVC_PK INTO V_SVC_UID_PK, V_SOT_CODE ;
  CLOSE GET_SVC_PK;

  OPEN GET_IDENTIFIER;
  FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_OST_UID_PK, V_SVC_UID_PK;
  CLOSE GET_IDENTIFIER;
  
  V_ISSUE_CHANGE_MAC := 'N';
  V_SAME_MAC         := 'N';
  IF V_SOT_CODE = 'MS' THEN --CHECK IF MAC IS ALREADY ENTERED
     --check to see if box is already on the service
     OPEN GET_CABLE_MODEM_SVC(V_SVC_UID_PK);
     FETCH GET_CABLE_MODEM_SVC INTO V_EXIST_MAC, V_MEU_UID_PK, V_TYPE;
     IF GET_CABLE_MODEM_SVC%FOUND THEN
        V_ISSUE_CHANGE_MAC := 'Y';
        IF V_EXIST_MAC = P_SERIAL# THEN
           V_SAME_MAC := 'Y';
        END IF;
     END IF;
     CLOSE GET_CABLE_MODEM_SVC;
  END IF;

  OPEN SERV_SUB_TYPE(V_SVO_UID_PK);
  FETCH SERV_SUB_TYPE INTO V_OST_UID_PK, V_SVT_CODE;
  CLOSE SERV_SUB_TYPE;

  --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_SERIAL#, V_CCB_UID_PK);

  --NOT FOUND
  IF V_EQUIP_TYPE  = 'N' THEN
    v_return_msg := 'SERIAL# '|| P_SERIAL# ||' NOT FOUND.  PLEASE MAKE SURE YOU ENTERED IT CORRECTLY.';
    IF V_SVO_UID_PK IS NOT NULL THEN
          PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
          RETURN   v_return_msg;
		 END IF; 

  ELSIF V_EQUIP_TYPE  = 'S' THEN
     V_CCB_UID_PK := V_CCB_UID_PK;
     V_CBM_UID_PK := NULL;
     V_ADM_UID_PK := NULL;
     -- MCV 10/25/2013 DNCS to XML prov project- no longer needed
     --v_is_ccb_mmr_fl  := MMR_INVENTORY_PKG.IS_CCB_MMR_YN( P_SERIAL# ) ;

  ELSIF V_EQUIP_TYPE  = 'E' THEN
    v_return_msg := 'YOU CANNOT SCAN A MTA MAC '|| P_SERIAL# ||' ON THIS ORDER.';
		IF V_SVO_UID_PK IS NOT NULL THEN 
              PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
              RETURN   v_return_msg; 
		END IF;
  ELSIF V_EQUIP_TYPE  = 'M' THEN
     V_CBM_UID_PK := V_CCB_UID_PK;
     V_CCB_UID_PK := NULL;
     V_ADM_UID_PK := NULL;
  ELSIF V_EQUIP_TYPE  = 'A' THEN
     v_return_msg := 'YOU CANNOT SCAN AN ADSL MODEM '|| P_SERIAL# ||' ON THIS ORDER.';
		 IF V_SVO_UID_PK IS NOT NULL THEN
              PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
              RETURN   v_return_msg; 
		 END IF;
  ELSIF V_EQUIP_TYPE  = 'V' THEN
     v_return_msg := 'YOU CANNOT SCAN A VDSL MODEM '|| P_SERIAL# ||' ON THIS ORDER.';
		 IF V_SVO_UID_PK IS NOT NULL THEN 
              PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
              RETURN   v_return_msg; 
		 END IF;
  END IF;

  IF V_IVL_UID_PK IS NULL THEN
     BOX_MODEM_PKG.PR_EXCEPTION(P_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK', P_VALIDATE_ONLY_FL);
     v_return_msg := 'THIS TECH IS NOT SET UP ON A TRUCK';
		 IF V_SVO_UID_PK IS NOT NULL THEN
              PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
              RETURN   v_return_msg; 
		 END IF;
  END IF;

  --CHECK TO SEE IF THE BOX HAS BEEN MARKED AS BEING RECALLED, IF SO THEN IT CANNOT BE USED
  IF V_EQUIP_TYPE  = 'S' THEN
     V_RECALL := FN_CHECK_STB_RECALL(P_SERIAL#,'A');
     IF V_RECALL IS NOT NULL THEN
        v_return_msg := V_RECALL;
			  IF V_SVO_UID_PK IS NOT NULL THEN
                  PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
                  RETURN   v_return_msg; 
		 		END IF;   
     END IF;
  END IF;

  rec_cbm := null;
  IF V_EQUIP_TYPE  = 'M' THEN -- if cable modem, need to see if it's a charter cable modem
    rec_cbm  := charter_inventory_pkg.get_cbm(upper(P_SERIAL#));
  END IF; 

  IF V_SAME_MAC = 'N' and NVL(rec_cbm.cbm_charter_fl, 'N') = 'N' THEN  --if charter cable modem, skip this check.
    --BOX STATUS CHECK
    V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_SERIAL#, V_EQUIP_TYPE, V_DESCRIPTION);
    IF V_STATUS NOT IN ('AN','AU','RT') THEN 
       BOX_MODEM_PKG.PR_EXCEPTION(P_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A BOX/MODEM TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_DESCRIPTION, P_VALIDATE_ONLY_FL);
       V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_SERIAL#);
       --IF V_ACCOUNT IS NOT NULL THEN
          --V_DESCRIPTION := V_DESCRIPTION||' ON '||V_ACCOUNT;
       --END IF;
       v_return_msg := 'BOX/MODEM '|| P_SERIAL# ||' IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
			 IF V_SVO_UID_PK IS NOT NULL THEN
                PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
                RETURN   v_return_msg; 
		 	 END IF;
    END IF;

    --LOCATION CHECK
    IF V_IVL_UID_PK IS NOT NULL THEN
       V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_SERIAL#);
       OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
       FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
       CLOSE LAST_LOCATION;

       IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN

          IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
             BOX_MODEM_PKG.PR_EXCEPTION(P_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A BOX/MODEM TO '||V_IDENTIFIER||' '||P_SERIAL#||' IS NOT FOUND ON THE TECHS TRUCK', P_VALIDATE_ONLY_FL);
          	 v_return_msg := 'BOX/MODEM '|| P_SERIAL# ||' IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
						 IF V_SVO_UID_PK IS NOT NULL THEN
              PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
              RETURN   v_return_msg; 

		 	 			 END IF;
          END IF;
       END IF;
    END IF;
  END IF;



  OPEN get_so_loc(V_SVO_UID_PK);
  FETCH get_so_loc INTO V_SLO_UID_PK;
  IF get_so_loc%NOTFOUND THEN
     OPEN get_svc_loc(V_SVO_UID_PK);
     FETCH get_svc_loc INTO V_SLO_UID_PK;
     CLOSE get_svc_loc;
  END IF;
  CLOSE get_so_loc;

  V_PC_TO_CBM_FL := 'N';
  IF V_SVT_CODE IN ('PACKET CABLE','RFOG') THEN  --ADDING A MTA BOX TO A CABLE MODEM SUB TYPE ORDER SO SWITCH THE SUB TYPE TO 'PACKET CABLE'.
     OPEN CABLE_MODEM_SUB(V_OST_UID_PK);
     FETCH CABLE_MODEM_SUB INTO V_OSB_UID_PK;
     IF CABLE_MODEM_SUB%FOUND THEN
        V_PC_TO_CBM_FL := 'Y';
        UPDATE SO
           SET SVO_OFF_SERV_SUBS_UID_FK = V_OSB_UID_PK
         WHERE SVO_UID_PK = V_SVO_UID_PK;
       
        OPEN check_if_mta(V_SVO_UID_PK);
        FETCH check_if_mta INTO V_MEU_UID_PK;
        IF check_if_mta%FOUND THEN
           DELETE
             FROM MTA_SO
            WHERE MTO_MTA_PORTS_UID_FK IN (SELECT MTP_UID_PK
                                             FROM MTA_PORTS
                                            WHERE MTP_UID_PK = MTO_MTA_PORTS_UID_FK
                                              AND MTP_MTA_EQUIP_UNITS_UID_FK = V_MEU_UID_PK);

           DELETE
             FROM MTA_SERVICES
            WHERE MSS_MTA_PORTS_UID_FK IN (SELECT MTP_UID_PK
                                             FROM MTA_PORTS
                                            WHERE MTP_UID_PK = MSS_MTA_PORTS_UID_FK
                                              AND MTP_MTA_EQUIP_UNITS_UID_FK = V_MEU_UID_PK);

           OPEN CHECK_PHN_SVC(v_slo_uid_pk, P_CUS_UID_PK);
           FETCH CHECK_PHN_SVC INTO V_DUMMY;
           IF CHECK_PHN_SVC%NOTFOUND THEN  --NO VOICE FOUND
              NULL;  --TOOK OUT OLD LOGIC TO DELETE FROM MTA TABLES
           END IF;
           CLOSE CHECK_PHN_SVC;

        END IF;
        CLOSE check_if_mta;
     END IF;
     CLOSE CABLE_MODEM_SUB;
     COMMIT;
  END IF;

  IF P_VALIDATE_ONLY_FL = 'Y' THEN
    RETURN('');   -- if made it here, end of validation, success
  END IF;

  -- set up flag for database and success message to be appended for developemnt
  GET_RUN_ENVIRONMENT(P_DEVELOPMENT_ACTION,
                      v_is_production_database,
                      v_msg_suffix);
                      
  IF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION = C_DEV_FAILURE THEN
    -- simulate wait 
    V_TIME := TO_CHAR(SYSDATE + .0001,'MM-DD-YYYY HH:MI:SS AM');
     WHILE SYSDATE < TO_DATE(V_TIME,'MM-DD-YYYY HH:MI:SS AM') LOOP
         null;
     END LOOP;

     
     v_return_msg := 'SO FAILED PROVISIONING - SUCCESSFUL RESPONSE NOT FOUND' ||v_msg_suffix;
	 IF V_SVO_UID_PK IS NOT NULL THEN
      PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
      RETURN   v_return_msg; 
	 END IF;
                        
  --THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS
  -- MCV 10/25/2013 DNCS to XML prov project- no longer needed
  /*ELSIF V_EQUIP_TYPE = 'S' AND v_is_ccb_mmr_fl  = 'N' THEN
     --CHECK THAT BOX HAS NOT ALREADY BEEN CREATED IN CATV_SERV_BOX_SO
     OPEN CHECK_CATV_SERV_BOX_SO(V_SVO_UID_PK);
     FETCH CHECK_CATV_SERV_BOX_SO INTO V_CBX_UID_PK, V_CBX_END_DATE;
     IF CHECK_CATV_SERV_BOX_SO%NOTFOUND THEN
        --INSERT A RECORD INTO THE CATV_SERV_BOX_SO TABLE
        OPEN GET_CATV_SO(V_SVO_UID_PK);
        FETCH GET_CATV_SO INTO V_CTS_UID_PK;
        IF GET_CATV_SO%FOUND THEN	
           SELECT TVB_SEQ.NEXTVAL
             INTO V_TVB_UID_PK
             FROM DUAL;
           INSERT INTO CATV_SERV_BOX_SO(CBX_UID_PK, CBX_CATV_SO_UID_FK, CBX_CATV_CONV_BOXES_UID_FK, CBX_ACTIVE_FL, CBX_START_DATE, CBX_END_DATE, CBX_CALLER_ID_FL)
                                 VALUES(V_TVB_UID_PK, V_CTS_UID_PK, V_CCB_UID_PK, 'Y', TRUNC(SYSDATE), NULL, 'Y');
           INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                               VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', TRUNC(SYSDATE), SYSDATE, 'The cable box '||P_SERIAL#||' was added by technician '||V_EMP_NAME);
        ELSE

           v_return_msg := 'CATV_SO RECORD NOT FOUND. PLEASE CONTACT PLANT AT 815-1900 WITH THIS MESSAGE.';
					 IF V_SVO_UID_PK IS NOT NULL THEN
            PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
            RETURN   v_return_msg; 
		 			 END IF;
           
        END IF;
        CLOSE GET_CATV_SO;
     ELSE
        IF V_CBX_END_DATE IS NOT NULL THEN
           UPDATE CATV_SERV_BOX_SO
              SET CBX_END_DATE = NULL,
                  CBX_ACTIVE_FL = 'Y'
            WHERE CBX_UID_PK = V_CBX_UID_PK;
        END IF;
     END IF;
     CLOSE CHECK_CATV_SERV_BOX_SO;
  */
  ELSIF V_EQUIP_TYPE = 'M' THEN
     --CHECK THAT MODEM HAS NOT ALREADY BEEN CREATED IN SO_ASSGNMTS TABLES
     OPEN CHECK_CABLE_MODEM_SO(V_SVO_UID_PK);
     FETCH CHECK_CABLE_MODEM_SO INTO V_DUMMY;
     IF CHECK_CABLE_MODEM_SO%NOTFOUND THEN
        --UPDATE THE SO_ASSGNMTS TABLE
        UPDATE SO_ASSGNMTS
                 SET SON_CABLE_MODEMS_UID_FK = V_CBM_UID_PK
               WHERE SON_SO_UID_FK = V_SVO_UID_PK;

           INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                               VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'The modem '||P_SERIAL#||' was added by technician '||V_EMP_NAME);

     END IF;
     CLOSE CHECK_CABLE_MODEM_SO;
  END IF;


  --THIS WILL LAUNCH FOR PROVISIONING  -- note may skip if MMR 
  -- MCV 10/25/2013 DNCS to XML prov project- no longer needed
  /*IF V_EQUIP_TYPE = 'S' and  v_is_ccb_mmr_fl = 'N'  THEN
     OPEN CHECK_EXIST_CANDIDATE(V_SVO_UID_PK, 'CABLEBRIDGE');
     FETCH CHECK_EXIST_CANDIDATE INTO V_SLS_DATE;
     IF CHECK_EXIST_CANDIDATE%NOTFOUND THEN
        INSERT INTO SO_CANDIDATES (SOC_UID_PK, SOC_SO_UID_FK, SOC_SWT_EQUIPMENT_UID_FK, SOC_ACTION_FL, SOC_DISPATCH_FL, SOC_ROUTED_FL, SOC_START_DATE,
                                   SOC_PRIORITY, SOC_WORK_ATTEMPTS, SOC_CABLE_WORK_FL)
                           VALUES (SOC_SEQ.NEXTVAL, V_SVO_UID_PK, 13, 'A', 'N', 'N', SYSDATE, 0, 1, 'N');
     ELSE
        UPDATE SO_CANDIDATES
           SET SOC_CABLE_WORK_FL = 'N',
               SOC_START_DATE = SYSDATE,
               SOC_WORK_ATTEMPTS = 1,
               SOC_PRIORITY = 0
         WHERE SOC_SO_UID_FK = V_SVO_UID_PK;
     END IF;
     CLOSE CHECK_EXIST_CANDIDATE;

     COMMIT;
  
  END IF;*/
 

  IF V_ISSUE_CHANGE_MAC = 'N' THEN
     IF V_LAST_IVL_DESCRIPTION = 'LOCATION NOT FOUND' THEN --ALSO ADD A RECORD TO ISSUE AN AUTO RECEIVE IN, INTO THE TECH TRUCK LOCATION
        BOX_MODEM_PKG.PR_RECEIVE_STB_INTO_INV(P_SERIAL#, V_IVL_UID_PK, V_CCB_UID_PK, V_CBM_UID_PK);
        COMMIT;
     END IF;
     BOX_MODEM_PKG.PR_ADD_ACCT(P_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, 'ADD ACCT WEB');
     COMMIT;
  END IF;
  
  IF V_BSO_UID_PK IS NOT NULL AND V_CCB_UID_PK IS NOT NULL THEN
     UPDATE CATV_CONV_BOXES
        SET CCB_BUSINESS_OFFICES_UID_FK = V_BSO_UID_PK
      WHERE CCB_UID_PK = V_CCB_UID_PK;
  END IF;

  COMMIT;

  V_TIME := TO_CHAR(SYSDATE + .003,'MM-DD-YYYY HH:MI:SS AM');

  -- check for provisioning success/ failure --------
  -- MCV 10/25/2013 DNCS to XML prov project- no longer needed
  /*IF V_EQUIP_TYPE = 'S' and  v_is_ccb_mmr_fl = 'N'  THEN  -- set top boxes
    
   
    WHILE SYSDATE < TO_DATE(V_TIME,'MM-DD-YYYY HH:MI:SS AM') LOOP
   
 
   
      OPEN CHECK_EXIST_CANDIDATE(V_SVO_UID_PK, 'CABLEBRIDGE');
      FETCH CHECK_EXIST_CANDIDATE INTO V_CHAR_DATE;
      CLOSE CHECK_EXIST_CANDIDATE;

      V_SOR_COMMENT := '';
      OPEN  CHECK_SWT_LOGS(V_SVO_UID_PK, V_CHAR_DATE, v_is_production_database, p_development_action);
      FETCH CHECK_SWT_LOGS INTO V_SOR_COMMENT;
      CLOSE CHECK_SWT_LOGS;
             
      IF V_SOR_COMMENT IS NOT NULL THEN 
        v_return_msg := 'Provisioning. Successful' || v_msg_suffix ;
        IF V_SVO_UID_PK IS NOT NULL THEN
          PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
          RETURN   v_return_msg; 
        END IF;
      ELSE

        OPEN CHECK_SWT_LOGS_ERROR('CABLEBRIDGE', V_CHAR_DATE, V_SVO_UID_PK);
        FETCH CHECK_SWT_LOGS_ERROR INTO V_SOR_COMMENT, V_DATE;
        IF CHECK_SWT_LOGS_ERROR%FOUND THEN
          CLOSE CHECK_SWT_LOGS_ERROR;
          v_return_msg := 'Order Updated, but provisioning failed on provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.' ;
          IF V_SVO_UID_PK IS NOT NULL THEN
            PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
            RETURN   v_return_msg; 
          END IF;  
                  
        ELSE
          CLOSE CHECK_SWT_LOGS_ERROR;
        END IF;
             
      END IF;
       
    END LOOP;
				
 
  ELS*/
  
  -- MCV 01/21/16 HSD MTA or Cable Modem on Fiber overbuild. provision ISP
  IF v_equip_type IN ('E','M') AND overbuild_pkg.get_so_fiber_conv_fun(v_svo_uid_pk)=1  THEN
  
    INSERT INTO so_candidates (soc_uid_pk, soc_so_uid_fk, soc_swt_equipment_uid_fk, soc_action_fl, soc_dispatch_fl, soc_routed_fl, soc_start_date, soc_priority, soc_work_attempts)
          VALUES (soc_seq.nextval, v_svo_uid_pk, code_pkg.get_pk('SWT_EQUIPMENT','ISP'),'A','N','N',SYSDATE,1,0);                                    
    COMMIT;
  END IF;
  
  IF V_EQUIP_TYPE = 'M' THEN  -- cable modems
    IF V_ISSUE_CHANGE_MAC = 'N' THEN
             v_isp_success_fl := provision_triad_so_fun(v_svo_uid_pk);
           				
             DBMS_OUTPUT.PUT_LINE(V_ISP_SUCCESS_FL||'    '||SUBSTR(TRIM(v_result),1,1));
             IF V_ISP_SUCCESS_FL = 'N' THEN
			   v_return_msg := 'Order Updated, but provisioning failed on Triad provisioning.';
			   IF V_SVO_UID_PK IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
				    PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
			   END IF;
			   RETURN 'Order Updated, but provisioning failed on Triad provisioning.';
             ELSE
                RETURN 'Triad provisioning successful.';
             END IF;

    
    ELSE
      
      IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
        V_SUCCESS := 'Y'; 
      
      ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
        V_SUCCESS := 'ERROR';
      
      ELSE
        IF V_TYPE = 'MTA' THEN
        
           V_SUCCESS := FN_MAC_ADDRESS_CHANGE(V_EXIST_MAC, P_SERIAL#, NULL,
					                                    V_SVO_UID_PK, P_EMP_UID_PK, V_MEU_UID_PK,
                                              'Y', P_DEVELOPMENT_ACTION);

           v_return_msg := V_SUCCESS  || v_msg_suffix;
		   IF V_SVO_UID_PK IS NOT NULL THEN
            PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
            RETURN   v_return_msg;
		   END IF;
		 	    
        ELSE
           COMMIT;
           C_SVC_UID_PK := NULL;
           C_SVO_UID_PK := V_SVO_UID_PK;
           V_SUCCESS := FN_SAM_MAC_CHANGE(V_EXIST_MAC, P_SERIAL#, NULL);								
           
           IF V_SUCCESS = 'Y' THEN

              BOX_MODEM_PKG.PR_ADD_ACCT(P_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, 'ADD ACCT WEB');
              BOX_MODEM_PKG.PR_REMOVE_ACCT(V_EXIST_MAC, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, 'REMOVE INSTALLATION', V_IVL_UID_PK);
              COMMIT;
              
              v_return_msg := 'Provisioning Successful.';
			  IF V_SVO_UID_PK IS NOT NULL THEN
                PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
                RETURN   v_return_msg;
		 	  END IF;
              
           ELSE
              PR_INSERT_SWT_LOGS(V_SVO_UID_PK, 'TRIAD_XML', 'INSTALLER_WEB_PKG.ADD_BOX NOT SUCCESSFUL', 'CHANGE MAC');
			  PR_INSERT_SO_MESSAGE(V_SVO_UID_PK, V_SUCCESS);
              RETURN 'Order Updated, but provisioning failed on Triad provisioning'  || v_msg_suffix;
           END IF;
        END IF;
      END IF;
    END IF;
  END IF;
  COMMIT;



  v_return_msg := 'SO FAILED PROVISIONING - SUCCESSFUL RESPONSE NOT FOUND WITHIN 5 MINUTES.  PLEASE CALL PLANT AT 815-1900 IF YOU NEED HELP.' || v_msg_suffix; --EMAIL GROUP
  IF V_SVO_UID_PK IS NOT NULL AND v_is_ccb_mmr_fl <> 'Y' THEN
    PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg, P_VALIDATE_ONLY_FL);
    RETURN   v_return_msg;
  ELSE
    RETURN '';
  END IF;
END ADD_BOX;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_GET_BOX_MODEM_QTY(P_SVO_UID_PK IN NUMBER)
RETURN NUMBER IS
--NJJ 07/26/2013 Changes below to use system_rules_pkg.get_char_value('EQUIPMENT' ...  to not hard code anymore, it used to hard code on the feature code itself
 cursor get_digital_features is
   select NVL(sum((NVL(SOF_QUANTITY,0) - NVL(SOF_OLD_QUANTITY,0))),0)
     from features, office_serv_types, office_serv_feats, so, so_types, so_features, system_listings, subsystem_lists, system_rules
    where ftp_uid_pk = osf_features_uid_fk
      --and ftp_code in ('DTSB','DTAB','DTAC','DSTF','DTSS','KVE3','KVE0','KVE1','KVE2','KVE4','KVEA','KVEB','KVEH1','CBOX','KCBOX')   -- MAR 08/24/09 Added new SD box codes, CBOX and KCBOX
      and osf_uid_pk = sof_office_serv_feats_uid_fk
      and ost_uid_pk = osf_office_serv_types_uid_fk
      and svo_uid_pk = sof_so_uid_fk
      and sot_uid_pk = svo_so_types_uid_fk
      and sof_so_uid_fk = p_svo_uid_pk
      AND syb_uid_pk = sru_subsystem_lists_uid_fk
      AND syl_uid_pk = syb_system_listings_uid_fk
      AND ftp_code = sru_system_code
      AND syl_active_fl = 'Y'
      AND syb_active_fl = 'Y'
      AND sru_active_fl = 'Y'
      AND syb_system_code = 'DIGITAL'
      AND SYL_SYSTEM_CODE = 'EQUIPMENT'
      and ((sof_action_fl = 'C' and sof_quantity > sof_old_quantity)
       or (sof_action_fl = 'A')
       or (sof_action_fl = 'N' and sot_system_code = 'MS'));

 cursor get_H_features is
   select NVL(sum((NVL(SOF_QUANTITY,0) - NVL(SOF_OLD_QUANTITY,0))),0)
     from features, office_serv_types, office_serv_feats, so, so_types, so_features, system_listings, subsystem_lists, system_rules
    where ftp_uid_pk = osf_features_uid_fk
      --and ftp_code in ('HDTV','KHDT','DVR1','KDVR','HDVR','KHDR',
      --                 'HDDL','KHDDL','HDTVB','KHDTB','DHDBNC','HDVRB','KHDRB','DVRNC')          -- MAR 08/24/09 Added new HD and DVR box codes
      AND syb_uid_pk = sru_subsystem_lists_uid_fk
      AND syl_uid_pk = syb_system_listings_uid_fk
      AND ftp_code = sru_system_code
      AND syl_active_fl = 'Y'
      AND syb_active_fl = 'Y'
      AND sru_active_fl = 'Y'
      AND syb_system_code IN ('HDTV','HDDVR','HDDTA','DVR','MMR HD','MMR HDDVR')
      AND SYL_SYSTEM_CODE = 'EQUIPMENT'
      and osf_uid_pk = sof_office_serv_feats_uid_fk
      and ost_uid_pk = osf_office_serv_types_uid_fk
      and svo_uid_pk = sof_so_uid_fk
      and sot_uid_pk = svo_so_types_uid_fk
      and sof_so_uid_fk = p_svo_uid_pk
      and ((sof_action_fl = 'C' and sof_quantity > sof_old_quantity)
       or (sof_action_fl = 'A')
       or (sof_action_fl = 'N' and sot_system_code = 'MS'));
       
 cursor get_features_modem_qty is
    select NVL(sum((NVL(SOF_QUANTITY,0) - NVL(SOF_OLD_QUANTITY,0))),0)
      from features, office_serv_types, office_serv_feats, so, so_types, so_features
     where ftp_uid_pk = osf_features_uid_fk
       and ftp_stb_fl = 'Y'
       and osf_uid_pk = sof_office_serv_feats_uid_fk
       and ost_uid_pk = osf_office_serv_types_uid_fk
       and svo_uid_pk = sof_so_uid_fk
       and sot_uid_pk = svo_so_types_uid_fk
       and sof_so_uid_fk = p_svo_uid_pk
       and ((sof_action_fl = 'C' and sof_quantity > sof_old_quantity)
        or (sof_action_fl = 'A')
       or (sof_action_fl = 'N' and sot_system_code = 'MS'));

  v_digital_count   			number;
  v_hd_count        			number;
  v_features_modem_count	number;

BEGIN
   
   ---HD 107970 RMC 06/20/2011 - Selection not to be based on feature codes anymore but check the ftp_stb_fl = 'Y' instead.
   ---                           This will calculate a more accurate count of the number of modems/boxes needed.

      OPEN get_features_modem_qty;
      FETCH get_features_modem_qty INTO v_features_modem_count;
      IF get_features_modem_qty%NOTFOUND THEN
         v_features_modem_count := 0;
      END IF;
      CLOSE get_features_modem_qty; 
      
RETURN v_features_modem_count;

   ---HD 107970 RMC 06/20/2011 - Commented out the opens/fetches to the original cursor used to calculate the quantity.
   
   ---OPEN get_digital_features;
   ---FETCH get_digital_features INTO v_digital_count;
   ---IF get_digital_features%NOTFOUND THEN
      ---v_digital_count := 0;
   ---END IF;
   ---CLOSE get_digital_features;

   ---OPEN get_H_features;
   ---FETCH get_H_features INTO v_hd_count;
   ---IF get_H_features%NOTFOUND THEN
      ---v_hd_count := 0;
   ---END IF;
   ---CLOSE get_H_features;

---RETURN v_digital_count + v_hd_count;

END FN_GET_BOX_MODEM_QTY;

/*-------------------------------------------------------------------------------------------------------------*/
-- to remove and deprovision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            ''            - If run in production, then this parameter has no effect

--  NOTE see code in iwp to determine what conditions P_STRING runs system commands
PROCEDURE REMOVE_BOX(P_SERIAL# IN VARCHAR,
                     P_EMP_UID_PK IN NUMBER, 
                     P_CUS_UID_PK IN NUMBER, 
                     P_SDS_UID_PK IN NUMBER, 
                     P_TYPE       IN VARCHAR, 
                     P_MESSAGE    OUT VARCHAR, 
                     P_STRING     OUT VARCHAR,
                     P_REUSE_FL   IN VARCHAR,
                     P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S',
                     P_VALIDATE_ONLY_FL   IN VARCHAR2 := 'N') IS

  CURSOR GET_TECH_LOCATION IS
   SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
     FROM TECH_EMP_LOCATIONS, EMPLOYEES
    WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
      AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
      AND TEO_END_DATE IS NULL;

  CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
    SELECT IVL_UID_PK
      FROM INVENTORY_LOCATIONS
     WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

  CURSOR CHECK_CATV_SERV_BOX_SO(P_SVO_UID_PK IN NUMBER) IS
    SELECT CBX_UID_PK
    FROM CATV_SERV_BOX_SO, CATV_CONV_BOXES, CATV_SO
    WHERE CCB_UID_PK = CBX_CATV_CONV_BOXES_UID_FK
      AND CTS_UID_PK = CBX_CATV_SO_UID_FK
      AND CTS_SO_UID_FK = P_SVO_UID_PK
      AND CCB_SERIAL# = P_SERIAL#;

  CURSOR GET_CATV_SO(P_SVO_UID_PK IN NUMBER) IS
    SELECT CTS_UID_PK
    FROM CATV_SO
    WHERE CTS_SO_UID_FK = P_SVO_UID_PK;

  CURSOR GET_SVO_PK IS
    SELECT SDS_SO_UID_FK, SOT_CODE
    FROM SO_TYPES, SO, SO_LOADINGS
    WHERE SDS_UID_PK = P_SDS_UID_PK
      AND SVO_UID_PK = SDS_SO_UID_FK
      AND SOT_UID_PK = SVO_SO_TYPES_UID_FK;

  CURSOR GET_IDENTIFIER IS
    SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
    FROM SERVICES, SO, SO_LOADINGS
    WHERE SDS_UID_PK = P_SDS_UID_PK
      AND SVC_UID_PK = SVO_SERVICES_UID_FK
      AND SVO_UID_PK = SDS_SO_UID_FK;

  CURSOR CHECK_CABLE_MODEM_SO(P_SVO_UID_PK IN NUMBER) IS
  select SON_UID_PK
  from so_assgnmts, cable_modems
  where cbm_uid_pk = son_cable_modems_uid_fk
    and son_so_uid_fk = P_SVO_UID_PK
    and cbm_mac_address = P_SERIAL#;

  CURSOR GET_LAST_ROUTING(P_SVO_UID_PK IN NUMBER) IS
    SELECT SOR_COMMENT
      FROM SO_ROUTINGS
     WHERE SOR_SO_UID_FK = P_SVO_UID_PK
       AND CREATED_DATE > SYSDATE - .012
     ORDER BY CREATED_DATE DESC;

   cursor get_so_loc(p_svo_uid_pk in number) is
          select ssx_service_locations_uid_fk
            from service_locations, serv_serv_loc_so
           where ssx_so_uid_fk = p_svo_uid_pk
             and slo_uid_pk = ssx_service_locations_uid_fk
             and ssx_primary_loc_fl = 'Y'
             and ssx_end_date is null;

   cursor get_svc_loc(p_svo_uid_pk in number) is
          select ssl_service_locations_uid_fk
            from service_locations, serv_serv_locations, services, so
           where ssl_services_uid_fk = svc_uid_pk
             and slo_uid_pk = ssl_service_locations_uid_fk
             and ssl_primary_loc_fl = 'Y'
             and ssl_end_date is null
             and svo_uid_pk = p_svo_uid_pk
             and svo_services_uid_fk = svc_uid_pk;


  CURSOR GET_USERNAME(P_SVO_UID_PK2 IN NUMBER) IS
    SELECT ISS_USER_NAME
      FROM INTERNET_SO
     WHERE ISS_SO_UID_FK = P_SVO_UID_PK2;

  V_SAM_SEQ              NUMBER;
  V_SAM_USER_NAME        VARCHAR2(200);
  V_SUCCESS_SAM          VARCHAR2(200) := null;
  V_USERNAME             VARCHAR2(200);
  V_SAM_MESSAGE          VARCHAR2(2000);
  V_SAM_SUCCESS_FL       VARCHAR2(1);

  V_IVL_UID_PK           NUMBER;
  V_SVO_UID_PK           NUMBER;
  V_SVC_UID_PK           NUMBER;
  V_SLO_UID_PK           NUMBER;
  V_CTS_UID_PK           NUMBER;
  V_CBX_UID_PK           NUMBER;
  V_BBO_MEO_UID_PK       NUMBER;
  V_LAST_IVL_UID_PK      NUMBER;
  V_LAST_IVL_DESCRIPTION VARCHAR2(200);
  V_RETURN_MESSAGE       VARCHAR2(2000);
  V_EQUIP_TYPE           VARCHAR2(1);
  V_CCB_UID_PK           NUMBER;
  V_CBM_UID_PK           NUMBER;
  V_ADM_UID_PK           NUMBER;
  V_STATUS               VARCHAR2(200);
  V_DUMMY                VARCHAR2(1);
  V_CABLE_MODEM_TYPE     VARCHAR2(1);
  V_TIME                 VARCHAR2(200);
  V_SOR_COMMENT          VARCHAR2(2000);
  V_IDENTIFIER           VARCHAR2(200);
  V_EMP_NAME             VARCHAR2(200);
  V_STRING               VARCHAR2(2000);
  v_cmdctr               Number(10);
  V_SOT_CODE             VARCHAR2(20);
  V_DEPROV_FL            VARCHAR2(1) := 'N';
  V_COMMUNIGATE_ERR_FL	 VARCHAR2(1) := 'N';
  v_is_production_database  VARCHAR2(1);
  v_msg_suffix           VARCHAR2(100);
  
  v_return_msg  		 VARCHAR2(4000);
  V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'REMOVE_BOX';
  v_is_ccb_mmr_fl        VARCHAR2(1);
BEGIN

  P_MESSAGE := NULL;

  --GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
  OPEN GET_TECH_LOCATION;
  FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
  CLOSE GET_TECH_LOCATION;

  --GET SVO_UID_PK
  OPEN GET_SVO_PK;
  FETCH GET_SVO_PK INTO V_SVO_UID_PK, V_SOT_CODE;
  CLOSE GET_SVO_PK;

  OPEN GET_IDENTIFIER;
  FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
  CLOSE GET_IDENTIFIER;

  --DTERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_SERIAL#, V_CCB_UID_PK);

  IF V_IVL_UID_PK IS NULL THEN
     BOX_MODEM_PKG.PR_EXCEPTION(P_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK',  P_VALIDATE_ONLY_FL);
     P_MESSAGE := 'THIS TECH IS NOT SET UP ON A TRUCK';
  END IF;

  IF P_MESSAGE IS NULL THEN
     --NOT FOUND
     IF V_EQUIP_TYPE  = 'N' THEN
        P_MESSAGE := '1 SERIAL# '|| P_SERIAL# ||' NOT FOUND.  PLEASE MAKE SURE YOU ENTERED IT CORRECTLY.';
     ELSIF V_EQUIP_TYPE  = 'S' THEN
        V_CCB_UID_PK := V_CCB_UID_PK;
        V_CBM_UID_PK := NULL;
        V_ADM_UID_PK := NULL;
        -- MCV 10/25/2013 DNCS to XML prov project- no longer needed
        --v_is_ccb_mmr_fl  := MMR_INVENTORY_PKG.IS_CCB_MMR_YN( P_SERIAL# ) ;
     ELSIF V_EQUIP_TYPE  = 'M' THEN
        V_CBM_UID_PK := V_CCB_UID_PK;
        V_CCB_UID_PK := NULL;
        V_ADM_UID_PK := NULL;
     ELSIF V_EQUIP_TYPE  = 'A' THEN
        V_CBM_UID_PK := NULL;
        V_CCB_UID_PK := NULL;
        V_ADM_UID_PK := V_CCB_UID_PK;
     END IF;
  END IF;

  if P_VALIDATE_ONLY_FL = 'Y' then
    return ;
  end if;

  --THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

  IF P_MESSAGE IS NULL THEN
    -- set up flag for database and success message to be appended for developemnt
    GET_RUN_ENVIRONMENT(P_DEVELOPMENT_ACTION,
                        v_is_production_database,
                        v_msg_suffix);
                        
   -- MCV 10/25/2013 DNCS to XML prov project- no longer needed
   /*IF V_EQUIP_TYPE = 'S' AND  v_is_ccb_mmr_fl = 'N' THEN  -- set top boxes

     --CHECK THAT BOX HAS NOT ALREADY BEEN CREATED IN CATV_SERV_BOX_SO
     OPEN CHECK_CATV_SERV_BOX_SO(V_SVO_UID_PK);
     FETCH CHECK_CATV_SERV_BOX_SO INTO V_CBX_UID_PK;
     IF CHECK_CATV_SERV_BOX_SO%FOUND THEN
        UPDATE CATV_SERV_BOX_SO
           SET CBX_END_DATE = SYSDATE,
               CBX_ACTIVE_FL = 'N'
         WHERE CBX_UID_PK = V_CBX_UID_PK
           AND CBX_END_DATE IS NULL;
     ELSE
        OPEN GET_CATV_SO(V_SVO_UID_PK);
        FETCH GET_CATV_SO INTO V_CTS_UID_PK;
        IF GET_CATV_SO%FOUND THEN
           INSERT INTO CATV_SERV_BOX_SO(CBX_UID_PK, CBX_CATV_SO_UID_FK, CBX_CATV_CONV_BOXES_UID_FK, CBX_ACTIVE_FL, CBX_START_DATE, CBX_END_DATE, CBX_CALLER_ID_FL)
                                 VALUES(TVB_SEQ.NEXTVAL, V_CTS_UID_PK, V_CCB_UID_PK, 'N', TRUNC(SYSDATE), TRUNC(SYSDATE), 'Y');
        END IF;
        CLOSE GET_CATV_SO;
     END IF;
     CLOSE CHECK_CATV_SERV_BOX_SO;
 

     --NJJ added 02/22/2010 per changes Marie and I are making to update the active service as well at time of removal
     update catv_serv_boxes
        set tvb_active_fl='N',
            tvb_end_date = SYSDATE
      where tvb_catv_services_uid_fk in (select cbs_uid_pk from catv_services where cbs_services_uid_fk = v_svc_uid_pk )
        and tvb_catv_conv_boxes_uid_fk = V_CCB_UID_PK
        and tvb_end_date is null;

     update catv_serv_box_so
        set cbx_active_fl='N',
            cbx_end_date = SYSDATE
      where cbx_catv_conv_boxes_uid_fk = V_CCB_UID_PK
        and cbx_end_date is null
        and CBX_CATV_SO_UID_FK IN (SELECT CTS_UID_PK
                                     FROM CATV_SO, SO, SO_STATUS
                                    WHERE SVO_UID_PK = CTS_SO_UID_FK
                                      AND CTS_UID_PK = CBX_CATV_SO_UID_FK
                                      AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                                      AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED')
                                      AND SVO_SERVICES_UID_FK = v_svc_uid_pk);

     INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                         VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE CABLE BOX '||P_SERIAL#||' WAS REMOVED BY TECHNICIAN '||V_EMP_NAME);

     OPEN get_so_loc(V_SVO_UID_PK);
     FETCH get_so_loc INTO V_SLO_UID_PK;
     IF get_so_loc%NOTFOUND THEN
        OPEN get_svc_loc(V_SVO_UID_PK);
        FETCH get_svc_loc INTO V_SLO_UID_PK;
        CLOSE get_svc_loc;
     END IF;
     CLOSE get_so_loc;

     v_cmdctr := Cable_SO_Command_Pkg.GET_SO_SUBSCRIBER_CTR_FUN;

     IF ( v_is_production_database = 'N' and P_DEVELOPMENT_ACTION in (C_DEV_SUCCESS, C_DEV_FAILURE) ) THEN
        v_string := '';  -- pass back null so that IWP code doesn't execute any cable bridge commands
      
     ELSIF v_is_production_database = 'Y' THEN
           --if box is being deleted then take box out of service
           v_string := 'O:\Perlcode\cablebridge_command_new.exe ' || '"' || 'SVCPK=' || V_SVC_UID_PK || '&'||'CMDCTR=' || v_cmdctr || '&' ||
                    v_cmdctr || ',DEL_DEV,' ||P_SERIAL# || '"';
          --v_string := 'O:\Perlcode\cablebridge_command_new.exe ' || '"' || 'SVCPK=' || V_SVC_UID_PK || '&'||'CMDCTR=' || v_cmdctr || '&' ||
                           --v_cmdctr || ',AU_DEV,' ||P_SERIAL# || ',5,1,5,' || v_slo_uid_pk || ',,' || '"';
     ELSIF v_is_production_database = 'N' and GET_DATABASE_FUN IN ('TEST') THEN
      			v_string := 'O:\Perlcode\cablebridge_command_test_incog.exe ' || '"' || 'SVCPK=' || V_SVC_UID_PK || '&'||'CMDCTR=' || v_cmdctr || '&' ||
                    		 v_cmdctr || ',DEL_DEV,' ||P_SERIAL# || '"';		
     ELSE
        v_string := 'O:\Perlcode\cablebridge_command_ldev.exe ' || '"' || 'SVCPK=' || V_SVC_UID_PK || '&'||'CMDCTR=' || v_cmdctr || '&' ||
                     v_cmdctr || ',DEL_DEV,' ||P_SERIAL# || '"';
          --v_string := 'O:\Perlcode\cablebridge_command_ldev.exe ' || '"' || 'SVCPK=' || V_SVC_UID_PK || '&'||'CMDCTR=' || v_cmdctr || '&' ||
                           --v_cmdctr || ',AU_DEV,' ||P_SERIAL# || ',5,1,5,' || v_slo_uid_pk || ',,' || '"';
     END IF;

     P_STRING := v_string; -- this gets returned back to out parameter

   ELS*/
   IF V_EQUIP_TYPE = 'M' THEN -- cable modems
     --CHECK THAT MODEM HAS NOT ALREADY BEEN CREATED IN BROADBAND_SO OR METRO_SO TABLES
     OPEN CHECK_CABLE_MODEM_SO(V_SVO_UID_PK);
     FETCH CHECK_CABLE_MODEM_SO INTO V_BBO_MEO_UID_PK;
     IF CHECK_CABLE_MODEM_SO%FOUND THEN

        --DEPROVISION FROM SAM ----
        IF ( v_is_production_database = 'N' and P_DEVELOPMENT_ACTION = C_DEV_SUCCESS  )  THEN
          V_SUCCESS_SAM    := 'SUCCESS';  -- for running in development OR prod to skip provisioning
        
        ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION =  C_DEV_FAILURE THEN
          V_SUCCESS_SAM    := 'ERROR'||v_msg_suffix;  -- for running in development
        
        ELSE  
          
          IF V_SOT_CODE = 'NS' THEN
              v_success_sam := provision_triad_service_fun(v_cbm_uid_pk,'A', v_job_number);
          END IF;
        END IF;

        IF NVL(V_SUCCESS_SAM,'NOT SUCCESS') != 'SUCCESS' THEN
           PR_INSERT_SWT_LOGS(V_SVO_UID_PK, 'TRIAD_XML', 'Triad Provisioning Unsuccessful to remove cable modem - Job '||v_job_number, 'DEPROVISION HSD');
           PR_INSERT_SO_MESSAGE(V_SVO_UID_PK, 'Triad Provisioning to remove the cable modem failed - Job '||v_job_number);
                 
           P_MESSAGE := 'Triad Provisioning to remove the cable modem failed, please contact the helpdesk.';
        ELSE
				 
              P_MESSAGE := 'Triad Provisioning to remove the cable modem was successful.';
              UPDATE SO_ASSGNMTS
                 SET SON_CABLE_MODEMS_UID_FK = NULL
               WHERE son_cable_modems_uid_fk = V_CBM_UID_PK;

                update service_assgnmts
                   set sva_cable_modems_uid_fk = null
                 where sva_cable_modems_uid_fk = V_CBM_UID_PK;

           INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                               VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE MODEM '||P_SERIAL#||' WAS REMOVED BY TECHNICIAN '||V_EMP_NAME);
        END IF;
     ELSE
        P_MESSAGE := 'SO_ASSGNMTS RECORD RECORD NOT FOUND.  PLEASE CONTACT PLANT AT 815-1900 WITH THIS MESSAGE.'  || v_msg_suffix;
     END IF;
     CLOSE CHECK_CABLE_MODEM_SO;
   END IF;
  END IF;

  COMMIT;
    

  IF P_MESSAGE IS NULL THEN
     IF P_REUSE_FL = 'Y' THEN
        V_STATUS := 'REMOVE INSTALLATION';
     ELSE
        V_STATUS := 'REMOVE INSTALLATION BAD';
     END IF;
     --***
     BOX_MODEM_PKG.PR_REMOVE_ACCT(P_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, V_STATUS, V_IVL_UID_PK);
     COMMIT;

     -- MCV 10/25/2013 DNCS to XML prov project- no longer needed
     /*IF v_is_ccb_mmr_fl <> 'Y' THEN
       IF V_DEPROV_FL = 'Y' THEN
          P_MESSAGE := 'BOX/MODEM SUCESSFULLY REMOVED FROM THE ACCOUNT AND DE-PROVISIONED.';
       ELSE
          P_MESSAGE := 'BOX/MODEM SUCESSFULLY REMOVED FROM THE ACCOUNT.' || v_msg_suffix;
       END IF;
     END IF;*/

  
     IF V_EQUIP_TYPE = 'S' THEN
        -- MCV 05/23/14 BPP Delete so_wiring records
        DELETE FROM so_wiring
          WHERE sow_catv_conv_boxes_uid_fk = v_ccb_uid_pk
            AND sow_so_assgnmts_uid_fk IN (SELECT son_uid_pk FROM so_assgnmts WHERE son_so_uid_fk = v_svo_uid_pk);
            
        --CHECK TO SEE IF THE BOX BEING REMOVED HAS BEEN MARKED AS BEING RECALLED, IF SO THEN NOTIFY TECH
        V_RECALL := FN_CHECK_STB_RECALL(P_SERIAL#,'D');
        IF V_RECALL IS NOT NULL THEN
           P_MESSAGE := P_MESSAGE  || ' ' || V_RECALL;
        END IF;
     END IF;  
  END IF;


END REMOVE_BOX;

/*-------------------------------------------------------------------------------------------------------------*/
-- to swap and deprovision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
 
--  NOTE see code in iwp to determine what conditions P_RETURN_STRING and P_PERL_STRING runs systems commands and P_MESSAGE may run INSTALLER_WEB_PKG.FN_CHECK_REFRESH_SVCS 
PROCEDURE SWAP_BOX(P_OLD_SERIAL#      IN VARCHAR, 
                   P_NEW_SERIAL#      IN VARCHAR,
                   P_EMP_UID_PK       IN NUMBER, 
                   P_CUS_UID_PK       IN NUMBER, 
                   P_TDP_UID_PK       IN NUMBER, 
                   P_TYPE             IN VARCHAR, 
                   P_MESSAGE          OUT VARCHAR, 
                   P_PEARL_STRING     OUT VARCHAR, 
                   P_CMDCTR           OUT NUMBER, 
                   P_RETURN_STRING    OUT VARCHAR, 
                   P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S',
                   P_VALIDATE_ONLY_FL   IN VARCHAR2 := 'N')
IS

  CURSOR GET_TECH_LOCATION IS
   SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
     FROM TECH_EMP_LOCATIONS, EMPLOYEES
    WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
      AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
      AND TEO_END_DATE IS NULL;

  CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
    SELECT IVL_UID_PK
      FROM INVENTORY_LOCATIONS
     WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

  CURSOR GET_IDENTIFIER IS
    SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
           SVC_UID_PK,
           TRT_UID_PK,
           SVC_OFF_SERV_SUBS_UID_FK,
           SVC_FEATURES_UID_FK,
           OST_SERVICE_TYPES_UID_FK,
           OST_BUSINESS_OFFICES_UID_FK
    FROM SERVICES, OFFICE_SERV_TYPES, TROUBLE_TICKETS, TROUBLE_DISPATCHES
    WHERE TDP_UID_PK = P_TDP_UID_PK
      AND TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
      AND SVC_UID_PK = TRT_SERVICES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK;

  CURSOR GET_CATV_SERV_BOX_SVC(P_SVC_UID_PK IN NUMBER, P_SERIAL# IN VARCHAR) IS
    SELECT TVB_UID_PK
    FROM CATV_SERV_BOXES, CATV_CONV_BOXES, CATV_SERVICES
    WHERE CBS_UID_PK = TVB_CATV_SERVICES_UID_FK
      AND CCB_UID_PK = TVB_CATV_CONV_BOXES_UID_FK
      AND CBS_SERVICES_UID_FK = P_SVC_UID_PK
      AND CCB_SERIAL# = P_SERIAL#
      AND TVB_END_DATE IS NULL;

  CURSOR GET_CATV_SERVICES(P_SVC_UID_PK IN NUMBER) IS
    SELECT CBS_UID_PK
    FROM CATV_SERV_BOXES, CATV_SERVICES
    WHERE CBS_UID_PK = TVB_CATV_SERVICES_UID_FK
      AND CBS_SERVICES_UID_FK = P_SVC_UID_PK;

  CURSOR GET_CABLE_MODEM_PK(P_SVC_UID_PK IN NUMBER) IS
   SELECT BBS_UID_PK, 'B', BBS_OPERATING_SYSTEM, 
          BBS_INSIDE_WIR_TYPES_UID_FK  IWT_UID_PK
     FROM BROADBAND_SERVICES, SERVICE_ASSGNMTS, CABLE_MODEMS
    WHERE BBS_SERVICES_UID_FK = P_SVC_UID_PK
      AND CBM_UID_PK = SVA_CABLE_MODEMS_UID_FK
      AND SVA_SERVICES_UID_FK = BBS_SERVICES_UID_FK
   UNION
   SELECT MES_UID_PK, 'M', MES_METRO_ID, 
          NULL  IWT_UID_PK
     FROM METRO_SERVICES, SERVICE_ASSGNMTS, CABLE_MODEMS
    WHERE MES_SERVICES_UID_FK = P_SVC_UID_PK
      AND CBM_UID_PK = SVA_CABLE_MODEMS_UID_FK
      AND SVA_SERVICES_UID_FK = MES_SERVICES_UID_FK;

  CURSOR GET_LAST_ROUTING(P_SVO_UID_PK IN NUMBER) IS
    SELECT SOR_COMMENT
      FROM SO_ROUTINGS
     WHERE SOR_SO_UID_FK = P_SVO_UID_PK
       AND CREATED_DATE > SYSDATE - .012
     ORDER BY CREATED_DATE DESC;

  CURSOR GET_SERVICE_FEATURES(P_SVC_UID_PK IN NUMBER) IS
    SELECT *
      FROM SERVICE_FEATURES
     WHERE SVF_SERVICES_UID_FK = P_SVC_UID_PK
       AND SVF_END_DATE IS NULL;

  CURSOR GET_PLNT_INFO(P_STY_UID_PK IN NUMBER, P_BSO_UID_PK IN NUMBER) IS
  SELECT OSF_UID_PK
    FROM OFFICE_SERV_FEATS, OFFICE_SERV_TYPES, FEATURES
   WHERE OST_UID_PK = OSF_OFFICE_SERV_TYPES_UID_FK
     AND FTP_UID_PK = OSF_FEATURES_UID_FK
     AND FTP_CODE = 'PLNT'
     AND OST_BUSINESS_OFFICES_UID_FK = P_BSO_UID_PK
     AND OST_SERVICE_TYPES_UID_FK = P_STY_UID_PK;
     
  CURSOR GET_CABLE_MODEM_SVC(P_SVC_UID_PK IN NUMBER, P_SERIAL# IN VARCHAR) IS
   SELECT SVA_UID_PK
     FROM SERVICE_ASSGNMTS, CABLE_MODEMS
    WHERE SVA_SERVICES_UID_FK = P_SVC_UID_PK
      AND CBM_UID_PK = SVA_CABLE_MODEMS_UID_FK
      AND CBM_MAC_ADDRESS = P_SERIAL#;

   cursor get_int_details(cpsvc_uid_pk number) is
         select its_user_name,
                its_password,
                its_security_question,
                its_security_answer,
                its_comment,
                its_confirmation_fl,
                its_rad_pending_date,
                its_radius_fl,
                its_training_fl,
                its_pacs_id_no#,
                its_expiration_date
           from internet_services
          where its_services_uid_fk = cpsvc_uid_pk;

 cursor get_slo(p_svc_uid_pk in number) is
        select ssl_service_locations_uid_fk
          from service_locations, serv_serv_locations, services
         where ssl_services_uid_fk = svc_uid_pk
           and slo_uid_pk = ssl_service_locations_uid_fk
           and ssl_primary_loc_fl = 'Y'
           and ssl_end_date is null
           and svc_uid_pk = p_svc_uid_pk;

 cursor get_bso is
   select cus_business_offices_uid_fk
     from customers
    where cus_uid_pk = p_cus_uid_pk;

  V_IVL_UID_PK           NUMBER;
  V_SVO_UID_PK           NUMBER;
  V_SVC_UID_PK           NUMBER;
  V_CTS_UID_PK           NUMBER;
  V_TVB_UID_PK           NUMBER;
  V_TRT_UID_PK           NUMBER;
  V_OSB_UID_PK           NUMBER;
  V_OSF_UID_PK           NUMBER;
  V_SLO_UID_PK           NUMBER;
  V_FTP_BUN_UID_PK       NUMBER;
  V_BBS_MES_UID_PK       NUMBER;
  V_LAST_IVL_UID_PK      NUMBER;
  V_CBS_UID_PK           NUMBER;
  V_STY_UID_PK           NUMBER;
  V_BSO_UID_PK           NUMBER;
  V_MEO_UID_PK           NUMBER;
  V_BBO_UID_PK           NUMBER;
  V_LAST_IVL_DESCRIPTION VARCHAR2(200);
  V_OPERATING_SYSTEM_ID  VARCHAR2(200);
  V_RETURN_MESSAGE       VARCHAR2(2000);
  V_EQUIP_TYPE_OLD       VARCHAR2(1);
  V_EQUIP_TYPE_NEW       VARCHAR2(1);
  V_CCB_UID_PK           NUMBER;
  V_CBM_UID_PK           NUMBER;
  V_CCB_UID_PK_NEW       NUMBER;
  V_CBM_UID_PK_NEW       NUMBER;
  V_STATUS               VARCHAR2(200);
  V_DUMMY                VARCHAR2(1);
  V_CABLE_MODEM_TYPE     VARCHAR2(1);
  V_TIME                 VARCHAR2(200);
  V_SOR_COMMENT          VARCHAR2(2000);
  V_IDENTIFIER           VARCHAR2(200);
  V_DESCRIPTION          VARCHAR2(200);
  V_EMP_NAME             VARCHAR2(200);
  v_string                       Varchar2(5000) := null;
  v_pos                               Number(10);
  v_cmdctr               Number(10);
  V_ACCOUNT              VARCHAR2(200);
  V_MAC_MESSAGE          VARCHAR2(2000);

  v_is_production_database  VARCHAR2(1);
  v_msg_suffix           VARCHAR2(100);
  v_iwt_uid_pk           number;
  v_is_new_ccb_mmr_fl    VARCHAR2(1)   := 'N';
  
BEGIN

  P_MESSAGE       := NULL;
  P_CMDCTR        := NULL;
  P_PEARL_STRING  := NULL;
  P_RETURN_STRING := NULL;

  --GET BSO PK
  OPEN get_bso;
  FETCH get_bso INTO V_BSO_UID_PK;
  CLOSE get_bso;

  --GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
  OPEN GET_TECH_LOCATION;
  FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
  CLOSE GET_TECH_LOCATION;

  OPEN GET_IDENTIFIER;
  FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK, V_TRT_UID_PK, V_OSB_UID_PK, V_FTP_BUN_UID_PK, V_STY_UID_PK, V_BSO_UID_PK;
  CLOSE GET_IDENTIFIER;

  IF V_IVL_UID_PK IS NULL THEN
    BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK', P_VALIDATE_ONLY_FL);
    P_MESSAGE := 'THIS TECH IS NOT SET UP ON A TRUCK';
  END IF;

  --***********************************************
  --CHECK TO REMOVE THE OLD SERIAL/MAC ADDRESS
  --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE_OLD := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_OLD_SERIAL#, V_CCB_UID_PK);


  IF P_MESSAGE IS NULL THEN
     --NOT FOUND
     IF V_EQUIP_TYPE_OLD  = 'N' THEN
        IF P_OLD_SERIAL# IS NOT NULL THEN
          BOX_MODEM_PKG.PR_EXCEPTION(P_OLD_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO REMOVE A BOX/MODEM FROM '||V_IDENTIFIER||' '||P_OLD_SERIAL#||' IS NOT FOUND IN THE SYSTEM', P_VALIDATE_ONLY_FL);
          P_MESSAGE := 'OLD SERIAL# '|| P_OLD_SERIAL# ||' NOT FOUND';
        END IF;
     ELSIF V_EQUIP_TYPE_OLD  = 'S' THEN
        V_CCB_UID_PK := V_CCB_UID_PK;
        V_CBM_UID_PK := NULL;
        -- MCV 10/25/2013 DNCS to XML prov project- no longer needed
        --v_is_new_ccb_mmr_fl  := MMR_INVENTORY_PKG.IS_CCB_MMR_YN( P_NEW_SERIAL# ) ;

     ELSIF V_EQUIP_TYPE_OLD  = 'M' THEN
        V_CBM_UID_PK := V_CCB_UID_PK;
        V_CCB_UID_PK := NULL;
     END IF;
  END IF;


  --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE_NEW := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_NEW_SERIAL#, V_CCB_UID_PK_NEW);

  IF P_MESSAGE IS NULL THEN
     --NOT FOUND
     IF V_EQUIP_TYPE_NEW  = 'N' THEN
       BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A BOX/MODEM TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND IN THE SYSTEM', P_VALIDATE_ONLY_FL);
       P_MESSAGE := '2 SERIAL# '|| P_NEW_SERIAL# ||' NOT FOUND.  PLEASE MAKE SURE YOU ENTERED IT CORRECTLY.';
     ELSIF V_EQUIP_TYPE_NEW  = 'S' THEN
        V_CCB_UID_PK_NEW := V_CCB_UID_PK_NEW;
        V_CBM_UID_PK_NEW := NULL;
     ELSIF V_EQUIP_TYPE_NEW  = 'M' THEN
        V_CBM_UID_PK_NEW := V_CCB_UID_PK_NEW;
        V_CCB_UID_PK_NEW := NULL;
     ELSIF V_EQUIP_TYPE_NEW  = 'E' THEN
        P_MESSAGE := 'MTA MAC SERIAL '|| P_NEW_SERIAL# ||' FOUND AND NOT ALLOWED FOR THIS TYPE OF SWAP.';
     ELSIF V_EQUIP_TYPE_NEW  = 'A' THEN
        P_MESSAGE := 'ADSL MODEM '|| P_NEW_SERIAL# ||' FOUND AND NOT ALLOWED FOR THIS TYPE OF SWAP.';
     ELSIF V_EQUIP_TYPE_NEW  = 'V' THEN
        P_MESSAGE := 'VDSL MODEM '|| P_NEW_SERIAL# ||' FOUND AND NOT ALLOWED FOR THIS TYPE OF SWAP.';
     END IF;
  END IF;

  --CHECK TO SEE IF THE BOX BEING ADDED HAS BEEN MARKED AS BEING RECALLED, IF SO THEN IT CANNOT BE USED
  If V_EQUIP_TYPE_NEW = 'S' THEN
     IF P_MESSAGE IS NULL THEN
        V_RECALL := FN_CHECK_STB_RECALL(P_NEW_SERIAL#,'A');
        IF V_RECALL IS NOT NULL THEN
           P_MESSAGE := V_RECALL;
        END IF;
     END IF;
  END IF;

  IF P_MESSAGE IS NULL THEN
     --BOX STATUS CHECK
     V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_NEW_SERIAL#, V_EQUIP_TYPE_NEW, V_DESCRIPTION);
     IF V_STATUS NOT IN ('AN','AU','RT') THEN
        BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A BOX/MODEM TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_STATUS, P_VALIDATE_ONLY_FL);
        V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_NEW_SERIAL#);
        --IF V_ACCOUNT IS NOT NULL THEN
           --V_DESCRIPTION := V_DESCRIPTION||' ON '||V_ACCOUNT;
        --END IF;
        P_MESSAGE := 'BOX/MODEM '|| P_NEW_SERIAL# ||' IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
     END IF;
  END IF;

  IF P_MESSAGE IS NULL THEN
     --LOCATION CHECK
     IF V_IVL_UID_PK IS NOT NULL THEN
        V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_NEW_SERIAL#);
        OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
        FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
        CLOSE LAST_LOCATION;

        IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
           IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
             BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A BOX/MODEM TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND ON THE TECHS TRUCK', P_VALIDATE_ONLY_FL);
             P_MESSAGE := 'BOX/MODEM '|| P_NEW_SERIAL# ||' IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
           END IF;
        END IF;
     END IF;
  END IF;
  
  if  P_VALIDATE_ONLY_FL  = 'Y' then
    return;
  end if;

  -- set up flag for database and success message to be appended for developemnt
  GET_RUN_ENVIRONMENT(P_DEVELOPMENT_ACTION,
                      v_is_production_database,
                      v_msg_suffix);
                      
  IF P_MESSAGE IS NULL THEN
     --REMOVE THE OLD SERIAL
     -- MCV 10/25/2013 DNCS to XML prov project- no longer needed
     /* IF V_EQUIP_TYPE_OLD = 'S' AND   v_is_new_ccb_mmr_fl = 'N'  THEN
        --INSERT A RECORD INTO THE CATV_SERV_BOX_SO TABLE
        OPEN GET_CATV_SERV_BOX_SVC(V_SVC_UID_PK, P_OLD_SERIAL#);
        FETCH GET_CATV_SERV_BOX_SVC INTO V_TVB_UID_PK;
        IF GET_CATV_SERV_BOX_SVC%FOUND THEN
           UPDATE CATV_SERV_BOXES
              SET TVB_END_DATE = SYSDATE,
                  TVB_ACTIVE_FL = 'N'
            WHERE TVB_CATV_CONV_BOXES_UID_FK = V_CCB_UID_PK;

           --04/07/2009 RMC HD 81770- Added the below to delete active boxes from catv_serv_box_so if there are any pending service orders. The issue is when
           --a CS order is issued it creates rows in CATV_SERV_BOX_SO for each box that is currently active on the account. When the CS SO clears and closes
           --the boxes get added back again ( TVB_ACTIVE_FL='Y' and TVB_END_DATE(s) get nulled). This was wiping out what the Update above had done.
           --Code that Marie added in SOFSVCDT was added here.

           Delete from catv_serv_box_so
                   where cbx_catv_conv_boxes_uid_fk = v_ccb_uid_pk
                     and cbx_catv_so_uid_fk in (select cts_uid_pk from so_status, catv_so, so
                                                  where cts_so_uid_fk = svo_uid_pk
                                                      and svo_services_uid_fk = V_SVC_UID_PK
                                                      and svo_so_status_uid_fk = sos_uid_pk
                                     and sos_system_code NOT IN ('VOID','CLOSED'));

           INSERT INTO SERVICE_MESSAGES(SVM_UID_PK, SVM_SERVICES_UID_FK, SVM_ENTERED_BY, SVM_DATE, SVM_TIME, SVM_TEXT, SVM_ACTIVE_FL)
                               VALUES(SVM_SEQ.NEXTVAL, V_SVC_UID_PK, 'IWP', SYSDATE, SYSDATE, 'The cable box '||P_OLD_SERIAL#||' was removed because of repair on trouble ticket '||V_TRT_UID_PK||' by technician '||V_EMP_NAME, 'Y');

           open get_slo(V_SVC_UID_PK);
           fetch get_slo into v_slo_uid_pk;
           close get_slo;

           v_cmdctr := Cable_SO_Command_Pkg.GET_SO_SUBSCRIBER_CTR_FUN;

             --if box is being deleted then take box out of service
           IF (v_is_production_database = 'N' and P_DEVELOPMENT_ACTION in (C_DEV_SUCCESS, C_DEV_FAILURE))  THEN
             v_string := '';  -- pass back null so that IWP code doesn't execute any cable bridge commands
      
           ELSIF v_is_production_database = 'Y' THEN
              v_string := 'O:\Perlcode\cablebridge_command_new.exe ' || '"' || 'SVCPK=' || V_SVC_UID_PK || '&'||'CMDCTR=' || v_cmdctr || '&' ||
                                   v_cmdctr || ',DEL_DEV,' ||P_OLD_SERIAL# || '"';
           ELSIF v_is_production_database = 'N' and GET_DATABASE_FUN IN ('TEST') THEN
					       			v_string := 'O:\Perlcode\cablebridge_command_test_incog.exe ' || '"' || 'SVCPK=' || V_SVC_UID_PK || '&'||'CMDCTR=' || v_cmdctr || '&' ||
                    		 v_cmdctr || ',DEL_DEV,' ||P_OLD_SERIAL# || '"';	
              --v_string := 'O:\Perlcode\cablebridge_command_new.exe ' || '"' || 'SVCPK=' || V_SVC_UID_PK || '&'||'CMDCTR=' || v_cmdctr || '&' ||
                              --v_cmdctr || ',AU_DEV,' ||P_OLD_SERIAL# || ',5,1,5,' || v_slo_uid_pk || ',,' || '"';
           ELSE
             v_string := 'O:\Perlcode\cablebridge_command_ldev.exe ' || '"' || 'SVCPK=' || V_SVC_UID_PK || '&'||'CMDCTR=' || v_cmdctr || '&' ||
                                v_cmdctr || ',DEL_DEV,' ||P_OLD_SERIAL# || '"';
             --v_string := 'O:\Perlcode\cablebridge_command_ldev.exe ' || '"' || 'SVCPK=' || V_SVC_UID_PK || '&'||'CMDCTR=' || v_cmdctr || '&' ||
                           --v_cmdctr || ',AU_DEV,' ||P_OLD_SERIAL# || ',5,1,5,' || v_slo_uid_pk || ',,' || '"';
           END IF;

           P_RETURN_STRING := v_string;
        ELSE
           IF P_OLD_SERIAL# IS NOT NULL THEN
              P_MESSAGE := 'NO MASTER BOX '|| P_OLD_SERIAL# ||' RECORD FOUND.  PLEASE CONTACT PLANT AT 815-1900 WITH THIS MESSAGE.';
           ELSE
              P_RETURN_STRING := null;
           END IF;
        END IF;
        
        CLOSE GET_CATV_SERV_BOX_SVC;
        
     ELS*/
     IF V_EQUIP_TYPE_OLD = 'M' THEN
     
        --CHECK THAT MODEM HAS NOT ALREADY BEEN CREATED IN BROADBAND_SO OR METRO_SO TABLES
        OPEN GET_CABLE_MODEM_SVC(V_SVC_UID_PK, P_OLD_SERIAL#);
        FETCH GET_CABLE_MODEM_SVC INTO V_BBS_MES_UID_PK;
        IF GET_CABLE_MODEM_SVC%FOUND THEN
           --CHANGE MAC ADDRESS IN SAM
           
           IF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
             V_MAC_MESSAGE := 'Y';
           ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
             V_MAC_MESSAGE := 'ERROR';
           ELSE
             
             C_SVC_UID_PK := V_SVC_UID_PK;
             C_SVO_UID_PK := NULL;
             
             UPDATE SERVICE_ASSGNMTS
                SET SVA_CABLE_MODEMS_UID_FK = V_CBM_UID_PK_NEW
              WHERE SVA_SERVICES_UID_FK = V_SVC_UID_PK;
              
             COMMIT;
             V_MAC_MESSAGE := INSTALLER_WEB_PKG.FN_SAM_MAC_CHANGE(P_OLD_SERIAL#, P_NEW_SERIAL#, NULL);
           END IF;
           
           IF V_MAC_MESSAGE != 'Y' THEN
              P_MESSAGE := V_MAC_MESSAGE || v_msg_suffix;
                     
           ELSE
              INSERT INTO SERVICE_MESSAGES(SVM_UID_PK, SVM_SERVICES_UID_FK, SVM_ENTERED_BY, SVM_DATE, SVM_TIME, SVM_TEXT, SVM_ACTIVE_FL)
                                  VALUES(SVM_SEQ.NEXTVAL, V_SVC_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE CABLE MODEM '||P_OLD_SERIAL#||' WAS REMOVED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' BY TECHNICIAN '||V_EMP_NAME|| v_msg_suffix, 'Y');
           END IF;
        ELSE
           P_MESSAGE := 'NO MASTER MODEM '|| P_OLD_SERIAL# ||' RECORD FOUND.  PLEASE CONTACT PLANT AT 815-1900 WITH THIS MESSAGE.';
        END IF;
        CLOSE GET_CABLE_MODEM_SVC;
     END IF;
  END IF;

  IF P_MESSAGE IS NULL THEN
     BOX_MODEM_PKG.PR_REMOVE_ACCT(P_OLD_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, NULL, 'REPAIR INSTALLATION', V_IVL_UID_PK);
  END IF;
  --********************END WITH THE OLD BOX/MODEM************************--

  --*********************************************
  --check for the addition of the new serial#

  --THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

  IF P_MESSAGE IS NULL THEN

    --ADD THE NEW SERIAL
    IF V_EQUIP_TYPE_NEW = 'S' THEN

       --INSERT A RECORD INTO THE CATV_SERV_BOXES TABLE
       OPEN GET_CATV_SERVICES(V_SVC_UID_PK);
       FETCH GET_CATV_SERVICES INTO V_CBS_UID_PK;
       IF GET_CATV_SERVICES%FOUND THEN
         -- MCV 10/25/2013 DNCS to XML prov project- no longer needed
         /*IF v_is_new_ccb_mmr_fl = 'N' THEN
            INSERT INTO CATV_SERV_BOXES(TVB_UID_PK, TVB_CATV_SERVICES_UID_FK, TVB_CATV_CONV_BOXES_UID_FK, TVB_START_DATE, TVB_ACTIVE_FL, TVB_END_DATE)
                                 VALUES(TVB_SEQ.NEXTVAL, V_CBS_UID_PK, V_CCB_UID_PK_NEW, TRUNC(SYSDATE), 'Y', NULL);

            COMMIT;

            IF (v_is_production_database = 'N' and P_DEVELOPMENT_ACTION in (C_DEV_SUCCESS, C_DEV_FAILURE) ) THEN
               v_string := '';  -- pass back null so that IWP code doesn't execute any cable bridge commands
            ELSIF v_is_production_database = 'Y' THEN
               v_string := Cable_SO_Command_Pkg.Cable_Refresh_Commands_Fun('F',V_SVC_UID_PK, 'PROD', 'W');
            ELSIF v_is_production_database = 'N' and GET_DATABASE_FUN IN ('TEST') THEN
            			v_string := Cable_SO_Command_Pkg.Cable_Refresh_Commands_Fun('F',V_SVC_UID_PK, 'TEST', 'W');
            ELSE
               v_string := Cable_SO_Command_Pkg.Cable_Refresh_Commands_Fun('F',V_SVC_UID_PK, 'LDEV', 'W');
            END IF;

            v_pos      := instr(v_string,'CMDCTR=');
            v_cmdctr   := substr(v_string,v_pos+7,6);
            P_CMDCTR   := v_cmdctr;

            If v_string = 'NONE' Then
                 P_MESSAGE := 'Command to refresh services was not built';
            ELSE
               P_PEARL_STRING := v_string;
            END IF;
          END IF;  --IF v_is_new_ccb_mmr_fl = 'N' THEN*/

          IF V_LAST_IVL_DESCRIPTION = 'LOCATION NOT FOUND' THEN --ALSO ADD A RECORD TO ISSUE AN AUTO RECEIVE IN, INTO THE TECH TRUCK LOCATION
             BOX_MODEM_PKG.PR_RECEIVE_STB_INTO_INV(P_NEW_SERIAL#, V_IVL_UID_PK, V_CCB_UID_PK_NEW, V_CBM_UID_PK_NEW);
          END IF;
          BOX_MODEM_PKG.PR_ADD_ACCT(P_NEW_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, NULL, 'ADD ACCT WEB');

          IF V_BSO_UID_PK IS NOT NULL THEN
             UPDATE CATV_CONV_BOXES
                SET CCB_BUSINESS_OFFICES_UID_FK = V_BSO_UID_PK
              WHERE CCB_UID_PK = V_CCB_UID_PK_NEW;
          END IF;

          INSERT INTO SERVICE_MESSAGES(SVM_UID_PK, SVM_SERVICES_UID_FK, SVM_ENTERED_BY, SVM_DATE, SVM_TIME, SVM_TEXT, SVM_ACTIVE_FL)
                              VALUES(SVM_SEQ.NEXTVAL, V_SVC_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE CABLE BOX '||P_NEW_SERIAL#||' WAS ADDED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' BY TECHNICIAN '||V_EMP_NAME, 'Y');
       ELSE
          P_MESSAGE := 'NO MASTER BOX RECORD FOUND (GET_CATV_SERVICES ' || V_SVC_UID_PK  ||').  PLEASE CONTACT PLANT AT 815-1900 WITH THIS MESSAGE.';
       END IF;
       CLOSE GET_CATV_SERVICES;
    ELSIF V_EQUIP_TYPE_NEW = 'M' THEN
       SELECT SVO_SEQ.NEXTVAL
         INTO V_SVO_UID_PK
         FROM DUAL;
       --CREATE PLANT CS RECORD FOR TRACKING 
       INSERT INTO SO (SVO_UID_PK, SVO_SERVICES_UID_FK, SVO_SO_STATUS_UID_FK, SVO_SO_TYPES_UID_FK, SVO_EMPLOYEES_UID_FK, SVO_CLOSED_BY_EMP_UID_FK, SVO_OFF_SERV_SUBS_UID_FK, SVO_FEATURES_UID_FK, SVO_ADDITIONAL_SERVICE_FL,
                       SVO_NEW_HOUSE_FL, SVO_CONTACT_NAME, SVO_CONTACT_PHONE, SVO_CLOSE_DATE, SVO_CLOSE_TIME)
                VALUES(V_SVO_UID_PK, V_SVC_UID_PK, CODE_PKG.GET_PK('SO_STATUS','CLOSED'), CODE_PKG.GET_PK('SO_TYPES','CS'), P_EMP_UID_PK, P_EMP_UID_PK, V_OSB_UID_PK, V_FTP_BUN_UID_PK,'Y', 'N', V_EMP_NAME, V_EMP_NAME, TRUNC(SYSDATE), SYSDATE);

       --NOT SURE IF THIS IS NEEDED BUT ALL WILL BE SET TO ACTION FLAG OF 'N' FOR ALL EXISTING FEATURES
       FOR SVF_REC IN GET_SERVICE_FEATURES(V_SVC_UID_PK) LOOP
           INSERT INTO SO_FEATURES(SOF_UID_PK, SOF_SO_UID_FK, SOF_OFFICE_SERV_FEATS_UID_FK, SOF_QUANTITY, SOF_COST, SOF_ACTION_FL,
                                   SOF_ANNUAL_CHARGE_FL, SOF_INITIAL_CHARGE_FL, SOF_RECORDS_ONLY_FL, SOF_SERVICE_CHARGE_FL, SOF_EXT_NUM_CHG_FL,
                                   SOF_COMPLETED_FL, SOF_HAND_RATED_AMOUNT, SOF_OLD_QUANTITY, SOF_WARR_START_DATE, SOF_WARR_END_DATE)
                            VALUES(SVF_SEQ.NEXTVAL, V_SVO_UID_PK, SVF_REC.SVF_OFFICE_SERV_FEATS_UID_FK, SVF_REC.SVF_QUANTITY, SVF_REC.SVF_COST,
                                   'N', SVF_REC.SVF_ANNUAL_CHARGE_FL, SVF_REC.SVF_INITIAL_CHARGE_FL, SVF_REC.SVF_RECORDS_ONLY_FL, SVF_REC.SVF_SERVICE_CHARGE_FL,
                                   'N','N', SVF_REC.SVF_HAND_RATED_AMOUNT, SVF_REC.SVF_QUANTITY, SVF_REC.SVF_WARR_START_DATE, SVF_REC.SVF_WARR_END_DATE);
       END LOOP;

       OPEN GET_PLNT_INFO(V_STY_UID_PK, V_BSO_UID_PK);
       FETCH GET_PLNT_INFO INTO V_OSF_UID_PK;
       CLOSE GET_PLNT_INFO;

       --INSERT WITH ACTION FLAG OF 'A' WITH THE PLNT CODE
       INSERT INTO SO_FEATURES(SOF_UID_PK, SOF_SO_UID_FK, SOF_OFFICE_SERV_FEATS_UID_FK, SOF_QUANTITY, SOF_COST, SOF_ACTION_FL,
                               SOF_ANNUAL_CHARGE_FL, SOF_INITIAL_CHARGE_FL, SOF_RECORDS_ONLY_FL, SOF_SERVICE_CHARGE_FL, SOF_EXT_NUM_CHG_FL,
                               SOF_COMPLETED_FL, SOF_HAND_RATED_AMOUNT, SOF_OLD_QUANTITY, SOF_WARR_START_DATE, SOF_WARR_END_DATE)
                        VALUES(SVF_SEQ.NEXTVAL, V_SVO_UID_PK, V_OSF_UID_PK, 1, 0,
                               'A', 'N', 'N', 'N', 'Y','N','N', NULL,0, NULL, NULL);
       --CHECK THAT MODEM HAS NOT ALREADY BEEN CREATED IN BROADBAND_SERVICES OR METRO_SERVICES TABLES
       OPEN GET_CABLE_MODEM_PK(V_SVC_UID_PK);
       FETCH GET_CABLE_MODEM_PK INTO V_BBS_MES_UID_PK, V_CABLE_MODEM_TYPE, V_OPERATING_SYSTEM_ID, v_iwt_uid_pk;
       IF GET_CABLE_MODEM_PK%FOUND THEN
          IF V_CABLE_MODEM_TYPE = 'B' THEN
             SELECT BBS_SEQ.NEXTVAL
               INTO V_BBO_UID_PK
               FROM DUAL;

             INSERT INTO BROADBAND_SO(BBO_UID_PK, BBO_SO_UID_FK, BBO_OPERATING_SYSTEM, BBO_INSIDE_WIR_TYPES_UID_FK)
                               VALUES(V_BBO_UID_PK, V_SVO_UID_PK, V_OPERATING_SYSTEM_ID, v_iwt_uid_pk);


             FOR INT_REC IN get_int_details(V_SVC_UID_PK) LOOP
                INSERT INTO INTERNET_SO(ISS_UID_PK,ISS_SO_UID_FK,ISS_USER_NAME,ISS_PASSWORD,ISS_PACS_ID_NO#,ISS_TRAINING_FL,
                                        ISS_RADIUS_FL,ISS_CONFIRMATION_FL,ISS_SECURITY_QUESTION,ISS_SECURITY_ANSWER,ISS_RAD_PENDING_DATE,
                                        ISS_CONTACT_EMAIL,ISS_COMMENT,CREATED_BY,CREATED_DATE,MODIFIED_BY,MODIFIED_DATE,ISS_EXPIRATION_DATE)
                                 VALUES(its_seq.nextval, V_SVO_UID_PK, INT_REC.its_user_name, INT_REC.its_password, INT_REC.its_pacs_id_no#,
                                        INT_REC.its_training_fl, INT_REC.its_radius_fl, INT_REC.its_confirmation_fl, INT_REC.its_security_question,
                                        INT_REC.its_security_answer, INT_REC.its_rad_pending_date, null, INT_REC.its_comment, user, sysdate,
                                        user, sysdate, INT_REC.ITS_EXPIRATION_DATE);

             END LOOP;

          ELSE
             SELECT MES_SEQ.NEXTVAL
               INTO V_MEO_UID_PK
               FROM DUAL;

             INSERT INTO METRO_SO(MEO_UID_PK, MEO_SO_UID_FK, MEO_METRO_ID)
                               VALUES(V_MEO_UID_PK, V_SVO_UID_PK, V_OPERATING_SYSTEM_ID);


          END IF;
      
          --UPDATE SERVICE_ASSGNMTS
           -- SET SVA_CABLE_MODEMS_UID_FK = V_CBM_UID_PK_NEW
          --WHERE SVA_SERVICES_UID_FK = V_SVC_UID_PK;

          UPDATE SO_ASSGNMTS
                SET SON_CABLE_MODEMS_UID_FK = V_CBM_UID_PK_NEW
              WHERE SON_SO_UID_FK in (SELECT SVO_UID_PK
                                  FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                                 WHERE OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                                   AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                                   AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                                   AND SVO_SERVICES_UID_FK = V_SVC_UID_PK
                                   AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));      

      
          P_MESSAGE := 'SWAP COMPLETED SUCCESSFULLY';

          --CHECK TO SEE IF THE BOX BEING REMOVED HAS BEEN MARKED AS BEING RECALLED, IF SO THEN NOTIFY TECH
          IF V_EQUIP_TYPE_NEW = 'S' THEN
             V_RECALL := FN_CHECK_STB_RECALL(P_OLD_SERIAL#,'D');
             IF V_RECALL IS NOT NULL THEN
                P_MESSAGE := P_MESSAGE  || ' ' || V_RECALL;
             END IF;
          END IF;      
      
          INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
					                              VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE MODEM '||P_NEW_SERIAL#||' WAS ADDED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' BY TECHNICIAN '||V_EMP_NAME);


          IF V_LAST_IVL_DESCRIPTION = 'LOCATION NOT FOUND' THEN --ALSO ADD A RECORD TO ISSUE AN AUTO RECEIVE IN, INTO THE TECH TRUCK LOCATION
             BOX_MODEM_PKG.PR_RECEIVE_STB_INTO_INV(P_NEW_SERIAL#, V_IVL_UID_PK, V_CCB_UID_PK_NEW, V_CBM_UID_PK_NEW);
          END IF;
          BOX_MODEM_PKG.PR_ADD_ACCT(P_NEW_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, 'ADD ACCT WEB');
       ELSE
          P_MESSAGE := 'NO MASTER MODEM RECORD FOUND.  PLEASE CONTACT PLANT AT 815-1900 WITH THIS MESSAGE.';
       END IF;
       CLOSE GET_CABLE_MODEM_PK;

    END IF;

  END IF;

  COMMIT;

END SWAP_BOX;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION TEST_COPY(P_IN_PARM IN VARCHAR, P_OUT1_PARM OUT VARCHAR,P_OUT2_PARM OUT VARCHAR)
RETURN VARCHAR

IS

BEGIN

P_OUT1_PARM := P_IN_PARM;
P_OUT2_PARM := P_IN_PARM||P_IN_PARM;

RETURN 'OK';

END TEST_COPY;

FUNCTION FN_CHECK_REFRESH_SVCS(PSVC_UID_PK IN NUMBER, PCMD_CTR IN NUMBER)
RETURN VARCHAR IS

Cursor get_refresh_services (cpsvc_uid_pk number, cpcmd_ctr number) is
  Select count(*)
  From Refresh_services
  Where rfs_services_uid_fk = cpsvc_uid_pk
    and rfs_command_ctr like cpcmd_ctr
    and rfs_command_success_fl = 'N'
    and trunc(created_date) = trunc(sysdate);

 CURSOR GET_IDENTIFIER IS
   SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK)
     FROM SERVICES
    WHERE SVC_UID_PK = PSVC_UID_PK;

 v_ctr                Number(10) := 0;
 v_message    varchar2(2000);
 V_IDENTIFIER varchar2(2000);
 

BEGIN


  OPEN  get_refresh_services (PSVC_UID_PK, PCMD_CTR);
  FETCH get_refresh_services INTO v_ctr;
  CLOSE get_refresh_services;

  OPEN  GET_IDENTIFIER;
  FETCH GET_IDENTIFIER INTO V_IDENTIFIER;
  CLOSE GET_IDENTIFIER;

  If v_ctr > 0 Then
       Return '*** Refresh was not successful, please contact Plant at 815-1900 ***';
  Else
       Return 'Services have sucessfully been refreshed';
  End If;

 END FN_CHECK_REFRESH_SVCS;

FUNCTION FN_CHECK_EQUIPMENT_RETURNED(P_SERIAL# IN VARCHAR, P_SVC_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER)
RETURN BOOLEAN IS

CURSOR GET_CATV_SERV_BOX_SVC IS
  SELECT TVB_END_DATE
  FROM CATV_SERV_BOXES, CATV_CONV_BOXES, CATV_SERVICES
  WHERE CBS_UID_PK = TVB_CATV_SERVICES_UID_FK
    AND CCB_UID_PK = TVB_CATV_CONV_BOXES_UID_FK
    AND CBS_SERVICES_UID_FK = P_SVC_UID_PK
    AND CCB_SERIAL# = P_SERIAL#;

CURSOR CHECK_CATV_SERV_BOX_SO IS
  SELECT 'X'
  FROM CATV_SERV_BOX_SO, CATV_CONV_BOXES, CATV_SO
  WHERE CCB_UID_PK = CBX_CATV_CONV_BOXES_UID_FK
    AND CTS_UID_PK = CBX_CATV_SO_UID_FK
    AND CTS_SO_UID_FK = P_SVO_UID_PK
    AND CCB_SERIAL# = P_SERIAL#
    AND CBX_END_DATE IS NULL;

CURSOR GET_CABLE_MODEM_SERVICE IS
 SELECT SVA_CABLE_MODEMS_UID_FK
   FROM SERVICE_ASSGNMTS, CABLE_MODEMS
  WHERE SVA_SERVICES_UID_FK = P_SVC_UID_PK
    AND CBM_UID_PK = SVA_CABLE_MODEMS_UID_FK
    AND CBM_MAC_ADDRESS = P_SERIAL#;

 CURSOR CHECK_SO IS
 SELECT 'X'
 FROM SO
 WHERE SVO_UID_PK = P_SVO_UID_PK;

--GET CABLE MODEM ASSIGNED TO THE SO
CURSOR get_cbm_other_so IS
SELECT SON_CABLE_MODEMS_UID_FK
  FROM so_assgnmts,
       so_status,
       so,
       cable_modems
 WHERE son_cable_modems_uid_fk = cbm_uid_pk
   AND svo_uid_pk          = son_so_uid_fk
   AND sos_uid_pk          = svo_so_status_uid_fk
   AND sos_system_code not in ('VOID','CLOSED')
   AND svo_services_uid_fk = P_SVC_UID_PK;

V_CCB_UID_PK     NUMBER;
V_CBM_UID_PK     NUMBER;
V_SO_CBM_UID_PK  NUMBER;
V_EQUIP_TYPE     VARCHAR2(10);
V_END_DATE       DATE := NULL;
V_DUMMY          VARCHAR2(1);

BEGIN

IF P_SERIAL# IS NOT NULL THEN
  --DTERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_SERIAL#, V_CCB_UID_PK);

  IF V_EQUIP_TYPE = 'S' THEN
   OPEN GET_CATV_SERV_BOX_SVC;
   FETCH GET_CATV_SERV_BOX_SVC INTO V_END_DATE;
   IF GET_CATV_SERV_BOX_SVC%FOUND THEN
      IF V_END_DATE IS NOT NULL THEN
         RETURN TRUE;
      ELSE
         OPEN CHECK_CATV_SERV_BOX_SO;
         FETCH CHECK_CATV_SERV_BOX_SO INTO V_DUMMY;
         IF CHECK_CATV_SERV_BOX_SO%FOUND THEN
            RETURN TRUE;
         END IF;
         CLOSE CHECK_CATV_SERV_BOX_SO;
      END IF;
   END IF;
   CLOSE GET_CATV_SERV_BOX_SVC;
  ELSIF V_EQUIP_TYPE = 'M' THEN
   OPEN GET_CABLE_MODEM_SERVICE;
   FETCH GET_CABLE_MODEM_SERVICE INTO V_CBM_UID_PK;
   IF GET_CABLE_MODEM_SERVICE%FOUND THEN
      OPEN CHECK_SO;
      FETCH CHECK_SO INTO V_DUMMY;
      IF CHECK_SO%NOTFOUND THEN
         OPEN get_cbm_other_so;
         FETCH get_cbm_other_so INTO V_SO_CBM_UID_PK;
         IF get_cbm_other_so%FOUND THEN
            IF V_CBM_UID_PK != V_SO_CBM_UID_PK THEN
               RETURN TRUE;
            END IF;
         END IF;
         CLOSE get_cbm_other_so;
      END IF;
      CLOSE CHECK_SO;
   END IF;
   CLOSE GET_CABLE_MODEM_SERVICE;
  END IF;
END IF;

RETURN FALSE;

END FN_CHECK_EQUIPMENT_RETURNED;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_CHECK_BOX_MODEM_PROVISIONED(P_SERIAL# IN VARCHAR, P_SVC_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER, PCMD_CTR IN NUMBER)
RETURN VARCHAR IS

Cursor get_refresh_services (cpsvc_uid_pk number, cpcmd_ctr in number) is
  Select count(*)
  From Refresh_services
  Where rfs_services_uid_fk = cpsvc_uid_pk
    and rfs_command_success_fl = 'Y'
    and rfs_command_ctr like cpcmd_ctr
    and trunc(created_date) = trunc(sysdate);

--not provisioned
Cursor get_refresh_services_np (cpsvc_uid_pk number, cpcmd_ctr in number) is
  Select count(*)
  From Refresh_services
  Where rfs_services_uid_fk = cpsvc_uid_pk
    and rfs_command_success_fl = 'N'
    and rfs_command_ctr like cpcmd_ctr
    and trunc(created_date) = trunc(sysdate);

CURSOR CHECK_CATV_SERV_BOX_SO IS
  SELECT 'X'
  FROM CATV_SERV_BOX_SO, CATV_CONV_BOXES, CATV_SO
  WHERE CCB_UID_PK = CBX_CATV_CONV_BOXES_UID_FK
    AND CTS_UID_PK = CBX_CATV_SO_UID_FK
    AND CTS_SO_UID_FK = P_SVO_UID_PK
    AND CCB_SERIAL# = P_SERIAL#
    AND TRUNC(CATV_SERV_BOX_SO.CREATED_DATE) = TRUNC(SYSDATE)
    AND TRUNC(CBX_START_DATE) = TRUNC(SYSDATE);

CURSOR CHECK_CABLE_MODEM_SO IS
select 'X'
from so_assgnmts, cable_modems
where cbm_uid_pk = son_cable_modems_uid_fk
  and son_so_uid_fk = P_SVO_UID_PK
  and cbm_mac_address = P_SERIAL#
  and TRUNC(so_assgnmts.MODIFIED_DATE) = TRUNC(SYSDATE);

CURSOR CHECK_MTA_SO IS
  SELECT 'X'
  FROM SO_ASSGNMTS, MTA_SO, MTA_BOXES, MTA_PORTS, MTA_EQUIP_UNITS
  WHERE MTO_SO_ASSGNMTS_UID_FK = SON_UID_PK
    AND (MTA_MTAMAC_ADDRESS = P_SERIAL#
     OR MTA_CMAC_ADDRESS = P_SERIAL#)
    AND SON_SO_UID_FK = P_SVO_UID_PK
    AND MTP_UID_PK = MTO_MTA_PORTS_UID_FK
    AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
    AND MTA_UID_PK = MEU_MTA_BOXES_UID_FK
    AND TRUNC(MTA_EQUIP_UNITS.MODIFIED_DATE) = TRUNC(SYSDATE);



CURSOR see_prov_successful IS
 select 'X'
  from swt_logs
 WHERE sls_so_uid_fk = p_svo_uid_pk
   AND sls_success_fl = 'Y'
   and trunc(created_date) = trunc(sysdate);

CURSOR see_prov_successful_np IS
 select 'X'
  from swt_logs
 WHERE sls_so_uid_fk = p_svo_uid_pk
   AND sls_success_fl = 'N'
   and trunc(created_date) = trunc(sysdate);

CURSOR CHK_ADSL IS
  SELECT 'X'
    FROM SO_ASSGNMTS, ADSL_MODEMS
   WHERE SON_SO_UID_FK = P_SVO_UID_PK
     AND ADM_UID_PK = SON_ADSL_MODEMS_UID_FK
     AND ADM_MAC_ADDRESS = P_SERIAL#
      AND ADM_VDSL_FL = 'N';
     
CURSOR CHK_VDSL IS
  SELECT 'X'
    FROM SO_ASSGNMTS, ADSL_MODEMS
   WHERE SON_SO_UID_FK = P_SVO_UID_PK
     AND ADM_UID_PK = SON_ADSL_MODEMS_UID_FK
     AND ADM_MAC_ADDRESS = P_SERIAL#
     AND ADM_VDSL_FL = 'Y';

 v_ctr                          Number(10) := 0;
 v_ctr_np                    Number(10) := 0;
 V_RETURN_MESSAGE       VARCHAR2(2000);
 V_EQUIP_TYPE           VARCHAR2(1);
 V_CCB_UID_PK           NUMBER;
 V_CBM_UID_PK           NUMBER;
 V_MTA_UID_PK           NUMBER;
 V_ADM_UID_PK           NUMBER;
 V_DUMMY                VARCHAR2(1);
 V_SOR_COMMENT          VARCHAR2(2000);

BEGIN


IF P_SERIAL# IS NOT NULL THEN
  ----THIS SECTION WILL CHECK ON THE BOXES ADDED TODAY TO SEE IF THEY PASSED OR FAILED PROVISIONING
  --DTERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_SERIAL#, V_CCB_UID_PK);

  IF V_EQUIP_TYPE  = 'S' THEN
     V_CCB_UID_PK := V_CCB_UID_PK;
     V_CBM_UID_PK := NULL;
     V_MTA_UID_PK := NULL;
     V_ADM_UID_PK := NULL;
  ELSIF V_EQUIP_TYPE  = 'M' THEN
     V_CBM_UID_PK := V_CCB_UID_PK;
     V_CCB_UID_PK := NULL;
     V_MTA_UID_PK := NULL;
     V_ADM_UID_PK := NULL;
  ELSIF V_EQUIP_TYPE  = 'E' THEN
     V_CBM_UID_PK := NULL;
     V_CCB_UID_PK := NULL;
     V_MTA_UID_PK := V_CCB_UID_PK;
     V_ADM_UID_PK := NULL;
  ELSIF V_EQUIP_TYPE  = 'A' THEN
     V_CBM_UID_PK := NULL;
     V_CCB_UID_PK := NULL;
     V_MTA_UID_PK := NULL;
     V_ADM_UID_PK := V_CCB_UID_PK;
  END IF;

  IF V_EQUIP_TYPE = 'M' THEN
   --CHECK THAT MODEM HAS been provisionned
   OPEN CHECK_CABLE_MODEM_SO;
   FETCH CHECK_CABLE_MODEM_SO INTO V_DUMMY;
   IF CHECK_CABLE_MODEM_SO%FOUND THEN
      OPEN see_prov_successful;
      FETCH see_prov_successful INTO V_DUMMY;
      IF see_prov_successful%FOUND THEN
         RETURN 'Y';
      ELSE
         OPEN see_prov_successful_np;
         FETCH see_prov_successful_np INTO V_DUMMY;
         IF see_prov_successful_np%FOUND THEN
            RETURN 'N';
         ELSE
            RETURN 'Y';
         END IF;
         CLOSE see_prov_successful_np;
      END IF;
      CLOSE see_prov_successful;
   ELSE
      RETURN 'Y';
   END IF;
   CLOSE CHECK_CABLE_MODEM_SO;
  ELSIF V_EQUIP_TYPE = 'E' THEN
   --CHECK THAT MTA 
   OPEN CHECK_MTA_SO;
   FETCH CHECK_MTA_SO INTO V_DUMMY;
   IF CHECK_MTA_SO%FOUND THEN
      OPEN see_prov_successful;
      FETCH see_prov_successful INTO V_DUMMY;
      IF see_prov_successful%FOUND THEN
         RETURN 'Y';
      ELSE
         OPEN see_prov_successful_np;
         FETCH see_prov_successful_np INTO V_DUMMY;
         IF see_prov_successful_np%FOUND THEN
            RETURN 'N';
         ELSE
            RETURN 'Y';
         END IF;
         CLOSE see_prov_successful_np;
      END IF;
      CLOSE see_prov_successful;
   ELSE
      RETURN 'Y';
   END IF;
   CLOSE CHECK_MTA_SO;
  ELSIF V_EQUIP_TYPE = 'A' THEN
   OPEN CHK_ADSL ;
   FETCH CHK_ADSL  INTO V_DUMMY;
   IF CHK_ADSL %FOUND THEN
      OPEN see_prov_successful;
      FETCH see_prov_successful INTO V_DUMMY;
      IF see_prov_successful%FOUND THEN
         RETURN 'Y';
      ELSE
         OPEN see_prov_successful_np;
         FETCH see_prov_successful_np INTO V_DUMMY;
         IF see_prov_successful_np%FOUND THEN
            RETURN 'N';
         ELSE
            RETURN 'Y';
         END IF;
         CLOSE see_prov_successful_np;
      END IF;
      CLOSE see_prov_successful;
   ELSE
      RETURN 'Y';
   END IF;
   CLOSE CHK_ADSL ;
  ELSIF V_EQUIP_TYPE = 'V' THEN
     OPEN CHK_VDSL ;
     FETCH CHK_VDSL  INTO V_DUMMY;
     IF CHK_VDSL %FOUND THEN
        OPEN see_prov_successful;
        FETCH see_prov_successful INTO V_DUMMY;
        IF see_prov_successful%FOUND THEN
           RETURN 'Y';
        ELSE
           OPEN see_prov_successful_np;
           FETCH see_prov_successful_np INTO V_DUMMY;
           IF see_prov_successful_np%FOUND THEN
              RETURN 'N';
           ELSE
              RETURN 'Y';
           END IF;
           CLOSE see_prov_successful_np;
        END IF;
        CLOSE see_prov_successful;
     ELSE
        RETURN 'Y';
     END IF;
   CLOSE CHK_VDSL ;
  END IF;

  ----THE FOLLOWING WILL CHECK FOR SWAPS ON CABLE BOXES

  --OPEN  get_refresh_services (P_SVC_UID_PK);
  --FETCH get_refresh_services INTO v_ctr;
  --CLOSE get_refresh_services;

  --If v_ctr > 0 Then
   --RETURN 'Y';
  --Else
  IF PCMD_CTR IS NOT NULL THEN
   OPEN  get_refresh_services_np (P_SVC_UID_PK, PCMD_CTR);
   FETCH get_refresh_services_np INTO v_ctr_np;
   CLOSE get_refresh_services_np;

   If v_ctr_np > 0 Then
        Return 'N';
   else
        Return 'Y';
   end if;
  END IF;
  --End If;
END IF;

Return 'Y';

END FN_CHECK_BOX_MODEM_PROVISIONED;

/*-------------------------------------------------------------------------------------------------------------*/
-- to reprovision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
--  NOTE see code in iwp to determine what conditions P_STRING runs system commands
FUNCTION add_box_reprovision(p_serial# IN VARCHAR, p_emp_uid_pk IN NUMBER, p_cus_uid_pk IN NUMBER, p_sds_uid_pk IN NUMBER, p_type IN VARCHAR, p_development_action IN VARCHAR2 := 'S')
  RETURN VARCHAR IS

  CURSOR get_svo_pk IS
    SELECT sds_so_uid_fk
    FROM so_loadings
    WHERE sds_uid_pk = p_sds_uid_pk;

  CURSOR get_so_type(p_svo_uid_pk IN NUMBER) IS
    SELECT sot_code
    FROM so, so_types
    WHERE svo_uid_pk = p_svo_uid_pk
      AND sot_uid_pk = svo_so_types_uid_fk;

  CURSOR get_identifier IS
    SELECT get_identifier_fun(svc_uid_pk, svc_office_serv_types_uid_fk)
    FROM services, so, so_loadings
    WHERE sds_uid_pk = p_sds_uid_pk
      AND svc_uid_pk = svo_services_uid_fk
      AND svo_uid_pk = sds_so_uid_fk;


  CURSOR see_prov_successful(p_svo_uid_pk number, p_is_production_db IN VARCHAR2, p_dev_action IN VARCHAR2) IS
     select 'X'
      from swt_logs
     WHERE sls_so_uid_fk = p_svo_uid_pk
       AND sls_success_fl = 'Y'
       and created_date > sysdate-5/1440
      and (p_is_production_db = 'Y'
           or
           (p_is_production_db = 'N' and p_dev_action = C_DEV_PRODUCTION)
          )
    UNION
    select 'X'
      from DUAL
     WHERE p_is_production_db = 'N'
       and p_dev_action        = C_DEV_SUCCESS;

  CURSOR see_prov_unsuccessful(p_svo_uid_pk number) IS
   select 'X'
    from swt_logs
   WHERE sls_so_uid_fk = p_svo_uid_pk
     AND sls_success_fl = 'N'
     and sls_response like '%validate username%'
     and created_date > sysdate-5/1440;

  CURSOR get_seq IS
   SELECT seq_uid_pk
     FROM swt_equipment
    WHERE seq_system_code = 'ISP';

  CURSOR get_tech_name IS
   SELECT emp_fname||' '||emp_lname
     FROM employees
    WHERE emp_uid_pk = p_emp_uid_pk;

  CURSOR check_exist_candidate(p_svo_uid_pk IN NUMBER, p_seq_code IN VARCHAR) IS
   SELECT TO_CHAR(so_candidates.modified_date,'MM-DD-YYYY HH:MI:SS AM')
     FROM so_candidates, swt_equipment
    WHERE soc_so_uid_fk = p_svo_uid_pk
      AND seq_uid_pk = soc_swt_equipment_uid_fk
      AND seq_system_code = p_seq_code
    ORDER BY TO_CHAR(so_candidates.modified_date,'MM-DD-YYYY HH:MI:SS AM') DESC;

  CURSOR get_dslam_port(p_svo_uid_pk IN NUMBER) IS
    SELECT son_dslam_ports_uid_fk
      FROM so_assgnmts
     WHERE son_so_uid_fk = p_svo_uid_pk
       AND son_adsl_modems_uid_fk IS NULL;

  v_alopa_msg            VARCHAR2(1);
  v_ivl_uid_pk           NUMBER;
  v_tvb_uid_pk           NUMBER;
  v_seq_uid_pk           NUMBER;
  v_svo_uid_pk           NUMBER;
  v_cts_uid_pk           NUMBER;
  v_bbo_meo_uid_pk       NUMBER;
  v_last_ivl_uid_pk      NUMBER;
  v_last_ivl_description VARCHAR2(200);
  v_return_message       VARCHAR2(2000);
  v_equip_type           VARCHAR2(1);
  v_sot_code             VARCHAR2(200);
  v_ccb_uid_pk           NUMBER;
  v_cbm_uid_pk           NUMBER;
  v_status               VARCHAR2(200);
  v_dummy                VARCHAR2(30);
  v_cable_modem_type     VARCHAR2(1);
  v_time                 VARCHAR2(200);
  v_sor_comment          VARCHAR2(2000);
  v_identifier           VARCHAR2(200);
  v_description          VARCHAR2(200);
  v_emp_name             VARCHAR2(200);
  v_date                 VARCHAR2(40);

  v_is_production_database  VARCHAR2(1);
  v_msg_suffix           VARCHAR2(100);
  
  v_return_msg  		VARCHAR2(4000);
	
	v_sel_procedure_name	 VARCHAR2(40):= 'ADD_BOX_REPROVISION';
  
BEGIN

  OPEN get_tech_name;
  FETCH get_tech_name INTO v_emp_name;
  CLOSE get_tech_name;

  --GET SVO_UID_PK
  OPEN get_svo_pk;
  FETCH get_svo_pk INTO v_svo_uid_pk;
  CLOSE get_svo_pk;

  --GET SOT_CODE
  OPEN get_so_type(v_svo_uid_pk);
  FETCH get_so_type INTO v_sot_code;
  CLOSE get_so_type;

  OPEN get_identifier;
  FETCH get_identifier INTO v_identifier;
  CLOSE get_identifier;

  --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  v_equip_type := box_modem_pkg.fn_determine_type(p_serial#, v_ccb_uid_pk);

  IF v_equip_type  = 'S' THEN
     v_ccb_uid_pk := v_ccb_uid_pk;
     v_cbm_uid_pk := NULL;
  ELSE
     v_cbm_uid_pk := v_ccb_uid_pk;
     v_ccb_uid_pk := NULL;
  END IF;


  v_time := TO_CHAR(SYSDATE + .003,'MM-DD-YYYY HH:MI:SS AM');
  
  
  -- set up flag for database and success message to be appended for developemnt
  get_run_environment(p_development_action,
                      v_is_production_database,
                      v_msg_suffix);

  IF v_is_production_database = 'N' AND P_DEVELOPMENT_ACTION = C_DEV_FAILURE THEN
    -- simulate wait 
    v_time := TO_CHAR(SYSDATE + .0001,'MM-DD-YYYY HH:MI:SS AM');
     WHILE SYSDATE < TO_DATE(V_TIME,'MM-DD-YYYY HH:MI:SS AM') LOOP
         NULL;
     END LOOP;
     
     RETURN 'SO FAILED PROVISIONING - SUCCESSFUL RESPONSE NOT FOUND' ||v_msg_suffix;
     v_return_msg := 'SO FAILED PROVISIONING - SUCCESSFUL RESPONSE NOT FOUND' ||v_msg_suffix;
		 IF v_svo_uid_pk IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 			 pr_ins_so_error_logs(v_svo_uid_pk, v_sel_procedure_name, v_return_msg);
		 		END IF;
		 END IF;
     

  ELSIF v_equip_type = 'M' THEN
  
	  v_isp_success_fl := provision_triad_so_fun(v_svo_uid_pk);				 

       
       IF v_isp_success_fl = 'Y' THEN
          RETURN 'Triad Auto Provisioning Successful';
       ELSE
          RETURN 'Triad Auto Provisioning Failed.  Please contact the helpdesk';
       END IF;


  END IF;

  COMMIT;


  RETURN 'SO FAILED PROVISIONING - SUCCESSFUL RESPONSE NOT FOUND WITHIN 5 MINUTES.  PLEASE CALL PLANT AT 815-1900 IF YOU NEED HELP.' || v_msg_suffix; --EMAIL GROUP


END ADD_BOX_REPROVISION;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE SWAP_BOX_REPROVISION(P_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_CUS_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_PEARL_STRING OUT VARCHAR, P_CMDCTR OUT NUMBER)
IS

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
         SVC_UID_PK,
         TRT_UID_PK,
         SVC_OFF_SERV_SUBS_UID_FK,
         SVC_FEATURES_UID_FK,
         OST_SERVICE_TYPES_UID_FK,
         OST_BUSINESS_OFFICES_UID_FK
  FROM SERVICES, OFFICE_SERV_TYPES, TROUBLE_TICKETS, TROUBLE_DISPATCHES
  WHERE TDP_UID_PK = P_TDP_UID_PK
    AND TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
    AND SVC_UID_PK = TRT_SERVICES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK;

CURSOR GET_TECH_NAME IS
 SELECT EMP_FNAME||' '||EMP_LNAME
   FROM EMPLOYEES
  WHERE EMP_UID_PK = P_EMP_UID_PK;

V_IVL_UID_PK           NUMBER;
V_SVO_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_CTS_UID_PK           NUMBER;
V_TVB_UID_PK           NUMBER;
V_TRT_UID_PK           NUMBER;
V_OSB_UID_PK           NUMBER;
V_OSF_UID_PK           NUMBER;
V_SLO_UID_PK           NUMBER;
V_FTP_BUN_UID_PK       NUMBER;
V_BBS_MES_UID_PK       NUMBER;
V_LAST_IVL_UID_PK      NUMBER;
V_CBS_UID_PK           NUMBER;
V_STY_UID_PK           NUMBER;
V_BSO_UID_PK           NUMBER;
V_MEO_UID_PK           NUMBER;
V_BBO_UID_PK           NUMBER;
V_LAST_IVL_DESCRIPTION VARCHAR2(200);
V_OPERATING_SYSTEM_ID  VARCHAR2(200);
V_RETURN_MESSAGE       VARCHAR2(2000);
V_EQUIP_TYPE           VARCHAR2(1);
V_CCB_UID_PK           NUMBER;
V_CBM_UID_PK           NUMBER;
V_CCB_UID_PK_NEW       NUMBER;
V_CBM_UID_PK_NEW       NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_CABLE_MODEM_TYPE     VARCHAR2(1);
V_TIME                 VARCHAR2(200);
V_SOR_COMMENT          VARCHAR2(2000);
V_IDENTIFIER           VARCHAR2(200);
V_DESCRIPTION          VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);
v_string               Varchar2(5000) := null;
v_pos                  Number(10);
v_cmdctr               Number(10);

BEGIN

P_CMDCTR        := NULL;
P_PEARL_STRING  := NULL;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK, V_TRT_UID_PK, V_OSB_UID_PK, V_FTP_BUN_UID_PK, V_STY_UID_PK, V_BSO_UID_PK;
CLOSE GET_IDENTIFIER;

OPEN GET_TECH_NAME;
FETCH GET_TECH_NAME INTO V_EMP_NAME;
CLOSE GET_TECH_NAME;

--***********************************************
--CHECK TO REMOVE THE OLD SERIAL/MAC ADDRESS
--DTERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_SERIAL#, V_CCB_UID_PK);

--NOT FOUND
IF V_EQUIP_TYPE  = 'S' THEN
   V_CCB_UID_PK := V_CCB_UID_PK;
   V_CBM_UID_PK := NULL;
ELSE
   V_CBM_UID_PK := V_CCB_UID_PK;
   V_CCB_UID_PK := NULL;
END IF;

--*********************************************


--ADD THE NEW SERIAL
IF V_EQUIP_TYPE = 'S' THEN

   COMMIT;

   IF GET_DATABASE_FUN IN ('HES1','HES2','HES3','HES','PROD') THEN
      v_string := Cable_SO_Command_Pkg.Cable_Refresh_Commands_Fun('F',V_SVC_UID_PK, 'PROD', 'W');
   ELSIF  GET_DATABASE_FUN IN ('TEST') THEN ---RMC 08/19/2013 Add Check for TEST Database
   		 v_string := Cable_SO_Command_Pkg.Cable_Refresh_Commands_Fun('F',V_SVC_UID_PK, 'TEST', 'W');---RMC 08/19/2013 Add Check for TEST Database
   ELSE
       v_string := Cable_SO_Command_Pkg.Cable_Refresh_Commands_Fun('F',V_SVC_UID_PK, 'LDEV', 'W');
   END IF;

   v_pos      := instr(v_string,'CMDCTR=');
   v_cmdctr   := substr(v_string,v_pos+7,6);
   P_CMDCTR   := v_cmdctr;

   If v_string = 'NONE' Then
       NULL;
     ELSE
        P_PEARL_STRING := v_string;
     END IF;

ELSIF V_EQUIP_TYPE = 'M' THEN
   NULL;
END IF;

COMMIT;

END SWAP_BOX_REPROVISION;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE PR_EMAIL_BC_ORDER_NEEDED(P_SVO_UID_PK IN NUMBER)

IS

 cursor get_digital_features is
   select NVL(sum((NVL(SOF_QUANTITY,0) - NVL(SOF_OLD_QUANTITY,0))),0)
     from features, office_serv_types, office_serv_feats, so, so_types, so_features
    where ftp_uid_pk = osf_features_uid_fk
      and ftp_code in ('DTSB','DTAB','DTAC','DSTF','DTSS','KVE3','KVE0','KVE1','KVE2','KVE4','KVEA','KVEB','KVEH1','CBOX','KCBOX')    -- MAR 08/24/09 Added new SD box codes, CBOX and KCBOX
      and osf_uid_pk = sof_office_serv_feats_uid_fk
      and ost_uid_pk = osf_office_serv_types_uid_fk
      and svo_uid_pk = sof_so_uid_fk
      and sot_uid_pk = svo_so_types_uid_fk
      and sof_so_uid_fk = p_svo_uid_pk
      and ((sof_action_fl = 'C' and sof_quantity > sof_old_quantity)
       or (sof_action_fl = 'A')
       or (sof_action_fl = 'N' and sot_system_code = 'MS'));

 cursor get_H_features is
   select NVL(sum((NVL(SOF_QUANTITY,0) - NVL(SOF_OLD_QUANTITY,0))),0) CNT, FTP_CODE
     from features, office_serv_types, office_serv_feats, so, so_types, so_features
    where ftp_uid_pk = osf_features_uid_fk
      and ftp_code in ('HDTV','KHDT','DVR1','KDVR','HDVR','KHDR',
                       'HDDL','KHDDL','HDTVB','KHDTB','DHDBNC','HDVRB','KHDRB','DVRNC')       -- MAR 08/24/09 Added new HD and DVR box codes
      and osf_uid_pk = sof_office_serv_feats_uid_fk
      and ost_uid_pk = osf_office_serv_types_uid_fk
      and svo_uid_pk = sof_so_uid_fk
      and sot_uid_pk = svo_so_types_uid_fk
      and sof_so_uid_fk = p_svo_uid_pk
      and ((sof_action_fl = 'C' and sof_quantity > sof_old_quantity)
       or (sof_action_fl = 'A')
       or (sof_action_fl = 'N' and sot_system_code = 'MS'))
     GROUP BY FTP_CODE;

 CURSOR BOXES_ADDED(P_BOX_TYPE IN VARCHAR) IS
 SELECT COUNT(*)
 FROM CATV_SERV_BOX_SO, CATV_SO, CATV_CONV_BOXES, CATV_CV_BX_TYPES
 WHERE CBT_UID_PK = CCB_CATV_CV_BX_TYPES_UID_FK
   AND CTS_UID_PK = CBX_CATV_SO_UID_FK
   AND CCB_UID_PK = CBX_CATV_CONV_BOXES_UID_FK
   AND CTS_SO_UID_FK = p_svo_uid_pk
   AND TRUNC(CBX_START_DATE) = TRUNC(SYSDATE)
   AND CBX_END_DATE IS NULL
   AND CBT_SYSTEM_CODE = P_BOX_TYPE;

  v_digital_count   number;
  v_hd_count        number;
  v_ftp_code        varchar2(2000);
  v_box_added       number := 0;
  v_send_email      varchar2(1) := 'N';
  v_code            varchar2(20);

BEGIN

IF FN_GET_BOX_MODEM_QTY(P_SVO_UID_PK) > 0 THEN --THIS ORDER REQUIRES BOXES TO BE ADDED.


   --these will get what is on the order itself.
   OPEN get_digital_features;
   FETCH get_digital_features INTO v_digital_count;
   IF get_digital_features%NOTFOUND THEN
      v_digital_count := 0;
   END IF;
   CLOSE get_digital_features;

   OPEN BOXES_ADDED('STD DIG');
   FETCH BOXES_ADDED INTO v_box_added;
   IF BOXES_ADDED%NOTFOUND THEN
      v_box_added := 0;
   END IF;
   CLOSE BOXES_ADDED;

   IF v_box_added != v_digital_count then
      v_send_email := 'Y';
   END IF;

   IF v_send_email = 'N' THEN  --CHECK FOR OTHER BOXES
      FOR REC IN get_H_features LOOP
         v_hd_count  := REC.CNT;
         v_ftp_code  := REC.FTP_CODE;
         v_box_added := 0;

         IF REC.FTP_CODE IN ('HDTV','KHDT') THEN
            V_CODE := 'HDTV';
         END IF;

         IF REC.FTP_CODE IN ('DVR1','KDVR') THEN
            V_CODE := 'DVR';
         END IF;

         IF REC.FTP_CODE IN ('HDVR','KHDR') THEN
            V_CODE := 'HDTV/DVR';
         END IF;

         OPEN BOXES_ADDED(V_CODE);
         FETCH BOXES_ADDED INTO v_box_added;
         IF BOXES_ADDED%NOTFOUND THEN
            v_box_added := 0;
         END IF;
         CLOSE BOXES_ADDED;

         IF v_box_added != v_hd_count then
                    v_send_email := 'Y';
         END IF;

      END LOOP;
   END IF;
END IF;

END PR_EMAIL_BC_ORDER_NEEDED;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE PR_INSERT_SO_MESSAGE(P_SVO_UID_PK IN NUMBER, P_COMMENT IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TYPE IN VARCHAR)

IS

CURSOR GET_TECH_NAME IS
 SELECT EMP_FNAME||' '||EMP_LNAME
   FROM EMPLOYEES
  WHERE EMP_UID_PK = P_EMP_UID_PK;

CURSOR LINE_NUMBER IS
 SELECT TRN_LINE_NUMBER
   FROM TROUBLE_NOTES
  WHERE TRN_TROUBLE_TICKETS_UID_FK = P_SVO_UID_PK
  ORDER BY TRN_LINE_NUMBER;

V_EMP_NAME    VARCHAR2(2000);
V_LINE_NUMBER NUMBER := 0;

BEGIN

IF P_SVO_UID_PK IS NOT NULL AND P_COMMENT IS NOT NULL THEN
     OPEN GET_TECH_NAME;
     FETCH GET_TECH_NAME INTO V_EMP_NAME;
     CLOSE GET_TECH_NAME;

   IF P_TYPE = 'S' THEN
        INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                          VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, V_EMP_NAME||'-'||P_COMMENT);
   ELSE
      OPEN LINE_NUMBER;
      FETCH LINE_NUMBER INTO V_LINE_NUMBER;
      IF LINE_NUMBER%NOTFOUND THEN
         V_LINE_NUMBER := 0;
      END IF;
      CLOSE LINE_NUMBER;

      V_LINE_NUMBER := V_LINE_NUMBER + 1;
      INSERT INTO TROUBLE_NOTES (TRN_UID_PK, TRN_EMPLOYEES_UID_FK, TRN_TROUBLE_TICKETS_UID_FK, TRN_LINE_NUMBER, TRN_SERVICE_DATE, TRN_SERVICE_TIME, TRN_LABOR_HOURS,TRN_NOTES)
                          VALUES(TRN_SEQ.NEXTVAL, P_EMP_UID_PK, P_SVO_UID_PK, V_LINE_NUMBER,  TRUNC(SYSDATE), SYSDATE, NULL, V_EMP_NAME||'-'||P_COMMENT);
   END IF;
END IF;

COMMIT;

END PR_INSERT_SO_MESSAGE;

PROCEDURE PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK         IN NUMBER, 
                               P_SEL_PROCEDURE_NAME IN VARCHAR, 
                               P_SEL_MESSAGE        IN VARCHAR,
                               P_SKIP_LOG_FL        IN VARCHAR2 := 'N')  -- to skip this procedure all together  
IS

V_SVO_UID_PK  							NUMBER := P_SVO_UID_PK;
V_SEL_PROCEDURE_NAME				VARCHAR2(40) := P_SEL_PROCEDURE_NAME;
V_SEL_MESSAGE								VARCHAR2(500) := P_SEL_MESSAGE;
V_APPLICATION_NAME					VARCHAR2(40):= 'INSTALLER_WEB_PKG';
V_TABLE_NAME								VARCHAR2(80):= 'SO_ERROR_LOGS';

BEGIN
 	
 	IF V_SVO_UID_PK IS NOT NULL AND V_SEL_MESSAGE	IS NOT NULL AND P_SKIP_LOG_FL <> 'Y' THEN

   	 INSERT INTO SO_ERROR_LOGS
     				(SEL_UID_PK,
     				 SEL_SVO_UID_PK,
     				 SEL_APPLICATION_NAME,
     				 SEL_PROCEDURE_NAME,
     				 SEL_TABLE_NAME,
     				 SEL_SQL_CODE,
     				 SEL_SQL_MSG,
     				 SEL_MESSAGE,
     				 CREATED_BY,
     				 CREATED_DATE)
   		VALUES
     				(sel_seq.NEXTVAL,
     				 v_svo_uid_pk,
     				 v_application_name,
     				 v_sel_procedure_name,
     				 v_table_name,
     				 NULL,
     				 NULL,
     				 v_sel_message,
     				 USER,
     				 SYSDATE);

		COMMIT;
		
	END IF;

END PR_INS_SO_ERROR_LOGS;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_DROP_ORDERS(P_EMP_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_COMMENT IN VARCHAR)

RETURN VARCHAR IS

--ZONE
CURSOR check_zone IS
SELECT zon_code
    FROM services,
             so,
             zones,
             streets,
             service_locations,
             serv_serv_locations
 WHERE svo_services_uid_fk          = svc_uid_pk
     AND str_zones_uid_fk             = zon_uid_pk
     AND slo_streets_uid_fk                     = str_uid_pk
     AND ssl_services_uid_fk          = svc_uid_pk
     AND ssl_service_locations_uid_fk = slo_uid_pk
     AND svo_uid_pk                   = p_svo_uid_pk
UNION
SELECT zon_code
 FROM  services,
             so,
             zones,
             streets,
             serv_serv_loc_so,
             service_locations
 WHERE svo_services_uid_fk          = svc_uid_pk
     AND str_zones_uid_fk             = zon_uid_pk
     AND ssx_service_locations_uid_fk = slo_uid_pk
     AND ssx_so_uid_fk                = svo_uid_pk
     AND slo_streets_uid_fk           = str_uid_pk
     AND svo_uid_pk                   = p_svo_uid_pk;

CURSOR GET_SO_INFO IS
 SELECT BSO_SYSTEM_CODE, SOT_SYSTEM_CODE, STY_SYSTEM_CODE, SVC_UID_PK
   FROM BUSINESS_OFFICES, CUSTOMERS, ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SO_TYPES, SO
  WHERE BSO_UID_PK = CUS_BUSINESS_OFFICES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;

CURSOR GET_CS_ORDERS(P_SVC_UID_PK IN NUMBER) IS
  SELECT SVO_UID_PK
    FROM SO, SO_TYPES
   WHERE SVO_SERVICES_UID_FK = P_SVC_UID_PK
     AND SVO_UID_PK != P_SVO_UID_PK
     AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
     AND SOT_SYSTEM_CODE = 'CS'
     AND SVO_CLOSE_DATE IS NULL;

 cursor already_loaded is
   select 'x'
     from so_loadings
    where sds_completed_fl = 'N'
      and sds_employees_uid_fk = P_EMP_UID_PK
      and trunc(sds_schedule_date) = trunc(sysdate);

V_ZONE_CODE           VARCHAR2(80);
V_BSO_SYSTEM_CODE     VARCHAR2(80);
V_STY_SYSTEM_CODE     VARCHAR2(80);
V_SOT_SYSTEM_CODE     VARCHAR2(80);
V_isr_uid_pk          NUMBER;
V_SLO_UID_PK          NUMBER;
V_SVC_UID_PK          NUMBER;
V_current_wfc_uid_pk  NUMBER;
V_defined_wfc_uid_pk  NUMBER;
V_defined_wfc_desc    VARCHAR2(200);
V_isr_exists          VARCHAR2(200);
V_invalid_iptv_svcs   VARCHAR2(200) := 'N';
V_invalid_cbm         VARCHAR2(200) := 'N';
v_display_message     VARCHAR2(2000);
v_cable_modem_message VARCHAR2(2000);
v_dummy               VARCHAR2(1);
V_SIA_ERROR           VARCHAR2(2000);
v_success             VARCHAR2(2000);
v_xfer_fl             VARCHAR2(200) := 'N';

BEGIN

IF P_TYPE = 'S' THEN

   OPEN check_zone;
   FETCH check_zone INTO V_ZONE_CODE;
   CLOSE check_zone;

   OPEN GET_SO_INFO;
   FETCH GET_SO_INFO INTO V_BSO_SYSTEM_CODE, V_SOT_SYSTEM_CODE, V_STY_SYSTEM_CODE, V_SVC_UID_PK;
   CLOSE GET_SO_INFO;

   SO_CLOSING_IVR_PKG.CHECK_ROUTING(P_SVO_UID_PK,
                                    P_EMP_UID_PK,
                                    V_ZONE_CODE,
                                                            V_BSO_SYSTEM_CODE,
                                                            V_SOT_SYSTEM_CODE,
                                                            V_STY_SYSTEM_CODE,
                                                  3,
                                                  'XXXX',
                                                  V_isr_uid_pk,
                                    V_current_wfc_uid_pk,
                                    V_defined_wfc_uid_pk,
                                    V_defined_wfc_desc);

   SO_CLOSING_IVR_PKG.REPORT_DROP(P_SVO_UID_PK,
                                    P_EMP_UID_PK,
                                    V_current_wfc_uid_pk,
                                    V_defined_wfc_uid_pk,
                                    V_defined_wfc_desc,
                                    V_SUCCESS,
                                    V_SIA_ERROR,
                                    'Y',
                                    V_invalid_iptv_svcs,
                                  V_invalid_cbm);

   IF NVL(V_invalid_iptv_svcs,'N') = 'Y' THEN
      v_display_message := 'Cannot Clear this Service Order, it is an IPTV service order'||
                           ' and its status is not okay.  Please use the seperate web interface to check on the status of this service order';
   ELSIF NVL(V_invalid_cbm,'N') = 'Y' THEN
      IF NOT INSTALLER_WEB_PKG.CHECK_CBM_STATUS(P_SVO_UID_PK, v_cable_modem_message) THEN
         v_display_message := v_cable_modem_message;
      ELSE
         v_display_message := NULL;
      END IF;
   ELSE
      v_display_message := NULL;
   END IF;

   IF NVL(V_invalid_iptv_svcs,'N') != 'Y' and NVL(V_invalid_cbm,'N') != 'Y' THEN
      IF V_SUCCESS != 'Y' THEN
         v_xfer_fl := 'Y';
      ELSE
         v_xfer_fl := 'N';
      END IF;
      INSTALLER_WEB_PKG.INS_SIA(P_EMP_UID_PK, P_SVO_UID_PK, v_xfer_fl, 'DROP', null);

   ---   GPS_PKG.FN_SDS_STAMP_ADDRESS(P_SVO_UID_PK, P_EMP_UID_PK, TRUNC(SYSDATE), 'C');
      
      --THIS WILL CHECK TO SEE IF A BILLING CHANGE FORM IS NEEDED
      --INSTALLER_WEB_PKG.PR_EMAIL_BC_ORDER_NEEDED(P_SVO_UID_PK);
   END IF;
   
   IF P_COMMENT IS NOT NULL THEN
      PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, P_COMMENT , P_EMP_UID_PK, P_TYPE);
   END IF;

   FOR REC IN GET_CS_ORDERS(V_SVC_UID_PK) LOOP
      PR_INSERT_SO_MESSAGE(REC.SVO_UID_PK, P_COMMENT , P_EMP_UID_PK, P_TYPE);
   END LOOP;

END IF;

COMMIT;

RETURN v_display_message;

END FN_DROP_ORDERS;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE PR_ACCESS_CODE_ORDERS(P_EMP_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_ACE_CODE IN VARCHAR, P_PCT IN NUMBER, P_COMMENT IN VARCHAR, P_SDS_UID_PK IN NUMBER)

IS

--ZONE
CURSOR check_zone IS
SELECT zon_code
    FROM services,
             so,
             zones,
             streets,
             service_locations,
             serv_serv_locations
 WHERE svo_services_uid_fk          = svc_uid_pk
     AND str_zones_uid_fk             = zon_uid_pk
     AND slo_streets_uid_fk                     = str_uid_pk
     AND ssl_services_uid_fk          = svc_uid_pk
     AND ssl_service_locations_uid_fk = slo_uid_pk
     AND svo_uid_pk                   = p_svo_uid_pk
UNION
SELECT zon_code
 FROM  services,
             so,
             zones,
             streets,
             serv_serv_loc_so,
             service_locations
 WHERE svo_services_uid_fk          = svc_uid_pk
     AND str_zones_uid_fk             = zon_uid_pk
     AND ssx_service_locations_uid_fk = slo_uid_pk
     AND ssx_so_uid_fk                = svo_uid_pk
     AND slo_streets_uid_fk           = str_uid_pk
     AND svo_uid_pk                   = p_svo_uid_pk;

CURSOR GET_SO_INFO IS
 SELECT BSO_SYSTEM_CODE, SOT_SYSTEM_CODE, STY_SYSTEM_CODE
   FROM BUSINESS_OFFICES, CUSTOMERS, ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SO_TYPES, SO
  WHERE BSO_UID_PK = CUS_BUSINESS_OFFICES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;

 cursor already_loaded is
   select 'x'
     from so_loadings
    where sds_completed_fl = 'N'
      and sds_employees_uid_fk = P_EMP_UID_PK
      and trunc(sds_schedule_date) = trunc(sysdate);

 cursor get_access_pk is
   select ace_uid_pk
     from access_codes
    where ace_system_code = p_ace_code;

 cursor get_sds_comment is
   select sds_comment
     from so_loadings
    where sds_uid_pk = p_sds_uid_pk;

V_ZONE_CODE           VARCHAR2(80);
V_BSO_SYSTEM_CODE     VARCHAR2(80);
V_STY_SYSTEM_CODE     VARCHAR2(80);
V_SOT_SYSTEM_CODE     VARCHAR2(80);
V_isr_uid_pk          NUMBER;
V_ace_uid_pk          NUMBER;
V_SLO_UID_PK          NUMBER;
V_current_wfc_uid_pk  NUMBER;
V_defined_wfc_uid_pk  NUMBER;
V_defined_wfc_desc    VARCHAR2(200);
V_isr_exists          VARCHAR2(200);
V_invalid_iptv_svcs   VARCHAR2(200) := 'N';
V_invalid_cbm         VARCHAR2(200) := 'N';
v_display_message     VARCHAR2(2000);
v_cable_modem_message VARCHAR2(2000);
v_dummy               VARCHAR2(1);
V_SIA_ERROR           VARCHAR2(2000);
v_success             VARCHAR2(2000);
v_xfer_fl             VARCHAR2(200) := 'N';
v_sds_comment         VARCHAR2(2000);
v_already_work_units  NUMBER := 0;
V_ORIG_WORK_UNITS     NUMBER := 0;

BEGIN

IF P_TYPE = 'S' THEN

   OPEN check_zone;
   FETCH check_zone INTO V_ZONE_CODE;
   CLOSE check_zone;

   OPEN GET_SO_INFO;
   FETCH GET_SO_INFO INTO V_BSO_SYSTEM_CODE, V_SOT_SYSTEM_CODE, V_STY_SYSTEM_CODE;
   CLOSE GET_SO_INFO;

   OPEN get_access_pk;
   FETCH get_access_pk INTO V_ace_uid_pk;
   CLOSE get_access_pk;

   SO_CLOSING_IVR_PKG.CHECK_ROUTING(P_SVO_UID_PK,
                                    P_EMP_UID_PK,
                                    V_ZONE_CODE,
                                                            V_BSO_SYSTEM_CODE,
                                                            V_SOT_SYSTEM_CODE,
                                                            V_STY_SYSTEM_CODE,
                                                  2,
                                                  p_ace_code,
                                                  V_isr_uid_pk,
                                    V_current_wfc_uid_pk,
                                    V_defined_wfc_uid_pk,
                                    V_defined_wfc_desc);

   SO_CLOSING_IVR_PKG.REPORT_ACCESS_CODE(P_SVO_UID_PK,
                                         P_EMP_UID_PK,
                                         P_ACE_CODE,
                                           V_current_wfc_uid_pk,
                                           V_defined_wfc_uid_pk,
                                           V_defined_wfc_desc,
                                           'N',
                                           NULL,
                                           V_ZONE_CODE,
                                           V_BSO_SYSTEM_CODE,
                                           2,
                                           V_ISR_EXISTS);


   IF P_PCT IS NOT NULL AND P_PCT != 0 THEN
      open get_sds_comment;
      fetch get_sds_comment into v_sds_comment;
      close get_sds_comment;

      V_ORIG_WORK_UNITS := AUTOMATIC_SCHEDULING_PKG.FN_GET_WORK_UNITS_PER_SVO(P_SVO_UID_PK, 1, v_sds_comment) - 1;

      v_already_work_units := ROUND((V_ORIG_WORK_UNITS * (P_PCT/10)));

      IF v_already_work_units = V_ORIG_WORK_UNITS THEN
         v_already_work_units := v_already_work_units - 1;  --MINUS 1 as the full amount should not be marked
      END IF;

      --UPDATE THE LOADING TO TAKE INTO ACCOUNT THE PERCENTAGE OF WORK UNITS WORKED
      UPDATE SO_LOADINGS
         SET SDS_ALREADY_WRKD_UNITS = v_already_work_units
       WHERE SDS_UID_PK = P_SDS_UID_PK;
   ELSE
      --UPDATE THE LOADING TO MARK IT AS REASSIGNED
      UPDATE SO_LOADINGS
         SET SDS_REASSIGN_TECH_FL = 'Y'
       WHERE SDS_UID_PK = P_SDS_UID_PK;
   END IF;

   INSTALLER_WEB_PKG.INS_SIA(P_EMP_UID_PK, P_SVO_UID_PK, v_xfer_fl, 'ACCESS CODE', V_ace_uid_pk);
   
 --  GPS_PKG.FN_SDS_STAMP_ADDRESS(P_SVO_UID_PK, P_EMP_UID_PK, TRUNC(SYSDATE), 'C');

   IF P_COMMENT IS NOT NULL THEN
      PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, P_COMMENT , P_EMP_UID_PK, P_TYPE);
   END IF;

   COMMIT;

END IF;

END PR_ACCESS_CODE_ORDERS;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE PR_HOLD_ORDER(P_EMP_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_PCT IN NUMBER, P_COMMENT IN VARCHAR, P_SDS_UID_PK IN NUMBER, P_DATETIME IN TIMESTAMP)

IS

 cursor get_sds_comment is
   select sds_comment, sds_workcenters_uid_fk
     from so_loadings
    where sds_uid_pk = p_sds_uid_pk;

CURSOR GET_TECH_NAME IS
 SELECT EMP_FNAME||' '||EMP_LNAME
   FROM EMPLOYEES
  WHERE EMP_UID_PK = P_EMP_UID_PK;

v_sds_comment         VARCHAR2(2000);
v_already_work_units  NUMBER := 0;
V_ORIG_WORK_UNITS     NUMBER := 0;
V_WCR_UID_PK          NUMBER;
V_AM_PM_IND           VARCHAR2(1);
V_EMP_NAME            VARCHAR2(2000);
V_NUM_HOUR            NUMBER;

BEGIN

IF P_TYPE = 'S' THEN

   OPEN GET_TECH_NAME;
   FETCH GET_TECH_NAME INTO V_EMP_NAME;
   CLOSE GET_TECH_NAME;

   IF P_PCT IS NOT NULL AND P_PCT != 0 THEN
      open get_sds_comment;
      fetch get_sds_comment into v_sds_comment, V_WCR_UID_PK;
      close get_sds_comment;

      V_ORIG_WORK_UNITS := AUTOMATIC_SCHEDULING_PKG.FN_GET_WORK_UNITS_PER_SVO(P_SVO_UID_PK, 1, v_sds_comment) - 1;

      v_already_work_units := ROUND((V_ORIG_WORK_UNITS * (P_PCT/10)));

      IF v_already_work_units = V_ORIG_WORK_UNITS THEN
         v_already_work_units := v_already_work_units - 1;  --MINUS 1 as the full amount should not be marked
      END IF;

      --UPDATE THE LOADING TO TAKE INTO ACCOUNT THE PERCENTAGE OF WORK UNITS WORKED
      UPDATE SO_LOADINGS
         SET SDS_COMPLETED_FL = 'Y',
             SDS_COMPLETED_DATE = TRUNC(SYSDATE),
             SDS_COMPLETED_TIME = SYSDATE,
             SDS_ALREADY_WRKD_UNITS = v_already_work_units
       WHERE SDS_UID_PK = P_SDS_UID_PK;
       
   --   GPS_PKG.FN_SDS_STAMP_ADDRESS(P_SVO_UID_PK, P_EMP_UID_PK, TRUNC(P_DATETIME), 'C');

     -- create due_date 
     insert into so_due_dates (sod_uid_pk ,
                               sod_so_uid_fk    ,
                               sod_rev_due_date_types_uid_fk  ,
                               sod_due_date   ,
                               sod_due_time ,
                               created_date ,
                               created_by )
                        values (sod_seq.nextval,
                                P_SVO_UID_PK,
                                code_pkg.get_pk('REV_DUE_DATE_TYPES','LTI'),
                                TRUNC(P_DATETIME),
                                P_DATETIME,
                                sysdate,
                                user);
      
      INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                          VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, V_EMP_NAME||' WORKED '||v_already_work_units||' UNITS AND CHOOSE TO RESCHEDULE THIS ORDER TO THEMSELF FOR '||TO_CHAR(P_DATETIME,'MM-DD-YYYY HH:MI:SS PM'));

      --GET THE HOUR TO GET THE AM_PM_IND VALUE
      SELECT TO_NUMBER(TO_CHAR(P_DATETIME,'HH24'))
        INTO V_NUM_HOUR
        FROM DUAL;

      IF V_NUM_HOUR >= 12 THEN
         V_AM_PM_IND := 'P';
      ELSE
         V_AM_PM_IND := 'A';
      END IF;

      INSERT INTO SO_LOADINGS(SDS_UID_PK, SDS_SO_UID_FK, SDS_WORKCENTERS_UID_FK, SDS_EMPLOYEES_UID_FK, SDS_SCHEDULE_DATE, SDS_SCHEDULE_TIME,
                              SDS_AM_PM_IND, SDS_COMMENT, SDS_SCHEDULED_FL)
                       VALUES(SDS_SEQ.NEXTVAL, P_SVO_UID_PK, V_WCR_UID_PK, P_EMP_UID_PK, TRUNC(P_DATETIME), P_DATETIME, V_AM_PM_IND, 'TECH RESCHEDULED TO FINISH WORK', 'Y');

  --    GPS_PKG.FN_SDS_STAMP_ADDRESS(P_SVO_UID_PK, P_EMP_UID_PK, TRUNC(P_DATETIME), 'A');
      
      COMMIT;
   END IF;

   INSTALLER_WEB_PKG.INS_SIA(P_EMP_UID_PK, P_SVO_UID_PK, 'N', 'HOLD', NULL);

   IF P_COMMENT IS NOT NULL THEN
      PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, P_COMMENT , P_EMP_UID_PK, P_TYPE);
   END IF;

   COMMIT;

END IF;

END PR_HOLD_ORDER;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE NO_JOBS_BY_815

IS

CURSOR GET_DISTRICTS IS
SELECT DISTINCT DIG_DISTRICT_GROUP_NAME
  FROM DISTRICT_GROUPS
 WHERE DIG_ACTIVE_FL = 'Y'
   AND DIG_DISTRICT_GROUP_NAME IN ('HILTON HEAD')
 ORDER BY DIG_DISTRICT_GROUP_NAME DESC;

CURSOR GET_EMPLOYEES (P_DISTRICT_GROUP_NAME IN VARCHAR) IS
 SELECT EMP_UID_PK, EMP_FNAME||' '||EMP_LNAME EMP_NAME, TIP_SAT_DEF_ORDERS
           , TIP_SUN_DEF_ORDERS  --SVA 05/15/2017 WR-20170306-35468 Schedule Sundays
   FROM EMPLOYEES, EMP_DISTRICT_GROUPS, DISTRICT_GROUPS, TIME_PERIODS_EMP_DIST
  WHERE EMP_ACTIVE_FL = 'Y'
    AND EDG_ACTIVE_FL = 'Y'
    AND DIG_ACTIVE_FL = 'Y'
    AND EDG_DEF_CUR_FL = 'C'
    AND DIG_UID_PK = EDG_DISTRICT_GROUPS_UID_FK
    AND EMP_UID_PK = TIP_EMPLOYEES_UID_FK
    AND TIP_BEGIN_TIME_HOUR = 1
    AND TIP_END_TIME_HOUR = 17
    AND NVL(TIP_DEF_ORDERS,0) > 0
    AND EDG_ZONE_GROUPS_UID_FK IS NOT NULL
    AND EMP_UID_PK = EDG_EMPLOYEES_UID_FK
    AND DIG_DISTRICT_GROUP_NAME = P_DISTRICT_GROUP_NAME
    AND EMP_UID_PK NOT IN (SELECT SSC_EMPLOYEES_UID_FK
                             FROM SO_SCHED_CALENDAR
                            WHERE SSC_EMPLOYEES_UID_FK = EMP_UID_PK
                              AND SSC_AVAIL_FL = 'N'
                              AND SSC_BLOCK_TYPE_FL IN ('B','S')
                              AND TRUNC(SSC_START_TIME) = TRUNC(SYSDATE)
                              AND TO_CHAR(TRUNC(SSC_START_TIME,'HH'),'HH') = '08')
    AND AUTOMATIC_SCHEDULING_PKG.FN_CHECK_ALWAYS_BLOCKED(EMP_UID_PK,'S') = 'N';

 CURSOR CHECK_FOR_ORDER(P_EMP_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SO_LOADINGS
   WHERE SDS_SCHEDULE_DATE = TRUNC(SYSDATE)
     AND SDS_EMPLOYEES_UID_FK = P_EMP_UID_PK
     AND SDS_COMPLETED_FL = 'N'
     AND TO_CHAR(SDS_SCHEDULE_TIME,'HH24') < 10
  UNION
  SELECT 'X'
    FROM SO_LOADINGS
   WHERE SDS_SCHEDULE_DATE = TRUNC(SYSDATE)
     AND SDS_EMPLOYEES_UID_FK = P_EMP_UID_PK
     AND SDS_COMPLETED_FL = 'N'
     AND SDS_SCHEDULE_TIME IS NULL
  UNION
  SELECT 'X'
    FROM TROUBLE_TICKETS, TROUBLE_DISPATCHES, TRBL_DSP_TECHS
   WHERE TDT_UID_PK = TDP_TRBL_DSP_TECHS_UID_FK
     AND TDT_EMPLOYEES_UID_FK = P_EMP_UID_PK
     AND TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
     AND TDP_END_WORK_TIME IS NULL
     AND TRT_STATUS = 'D'
     AND TRUNC(TDP_DATE) = TRUNC(SYSDATE);


  V_DUMMY  VARCHAR2(1);
  V_STRING VARCHAR2(8000) := NULL;

BEGIN

--THIS WILL FIRST GET THE DISTRICTS TO LOAD THE ORDERS
FOR REC IN GET_DISTRICTS LOOP

    FOR EMP_TECH_REC IN GET_EMPLOYEES(REC.DIG_DISTRICT_GROUP_NAME) LOOP
        IF (TO_CHAR(SYSDATE,'DAY') = 'SATURDAY' AND EMP_TECH_REC.TIP_SAT_DEF_ORDERS IS NULL)
        --SVA 05/15/2017 WR-20170306-35468 Schedule Sundays
        OR (TO_CHAR(SYSDATE,'DAY') = 'SUNDAY' AND EMP_TECH_REC.TIP_SUN_DEF_ORDERS IS NULL) 
        --SVA 05/15/2017
        THEN
           V_DUMMY := 'N';
        ELSE
           OPEN CHECK_FOR_ORDER(EMP_TECH_REC.EMP_UID_PK);
           FETCH CHECK_FOR_ORDER INTO V_DUMMY;
           IF CHECK_FOR_ORDER%NOTFOUND THEN
              V_STRING := V_STRING||EMP_TECH_REC.EMP_NAME||CHR(13) || CHR(10)||CHR(13) || CHR(10);
           END IF;
           CLOSE CHECK_FOR_ORDER;
        END IF;
    END LOOP;

END LOOP;


END NO_JOBS_BY_815;

PROCEDURE PAST_APPT_NOT_LOADED(P_TIME_PERIOD IN NUMBER)

IS

CURSOR GET_DISTRICTS IS
SELECT DISTINCT DIG_DISTRICT_GROUP_NAME, DIG_UID_PK
  FROM DISTRICT_GROUPS
 WHERE DIG_ACTIVE_FL = 'Y'
   AND DIG_DISTRICT_GROUP_NAME IN ('BLUFFTON/OKATIE','BEAUFORT','HARDEEVILLE/POOLER','RIDGELAND/ESTILL', 'HILTON HEAD','SEA PINES PLANTATION PROMO')
 ORDER BY DIG_DISTRICT_GROUP_NAME DESC;

CURSOR GET_NOT_LOADED_JOBS (P_DIG_UID_PK IN NUMBER) IS
 SELECT 'SO' SO_TT_TYPE, SDS_SO_UID_FK, SDS_COMMENT, TO_CHAR(SDS_SCHEDULE_TIME, 'MM-DD-YYYY HH:MI:SS AM') SDS_TIME, SDS_SCHEDULED_FL
   FROM ZONE_GROUPS, SO_LOADINGS
  WHERE SDS_COMPLETED_FL = 'N'
    AND SDS_SCHEDULE_DATE = TRUNC(SYSDATE)
    AND SDS_SCHEDULED_FL = 'Y'
    AND ZOP_UID_PK = SDS_ZONE_GROUPS_UID_FK
    AND SDS_EMPLOYEES_UID_FK IS NULL
    AND TO_NUMBER(TO_CHAR(SDS_SCHEDULE_TIME,'HH24MI')) < P_TIME_PERIOD
    AND ZOP_DISTRICT_GROUPS_UID_FK = P_DIG_UID_PK
UNION
 SELECT 'SO' SO_TT_TYPE, SDS_SO_UID_FK, SDS_COMMENT, TO_CHAR(SDS_SCHEDULE_TIME, 'MM-DD-YYYY HH:MI:SS AM') SDS_TIME, SDS_SCHEDULED_FL
   FROM ZONE_GROUPS, SO_LOADINGS
  WHERE SDS_COMPLETED_FL = 'N'
    AND SDS_SCHEDULE_DATE = TRUNC(SYSDATE)
    AND SDS_SCHEDULED_FL = 'N'
    AND ZOP_UID_PK = SDS_ZONE_GROUPS_UID_FK
    AND SDS_EMPLOYEES_UID_FK IS NULL
    AND ZOP_DISTRICT_GROUPS_UID_FK = P_DIG_UID_PK
UNION
 SELECT 'TT' SO_TT_TYPE, TDP_TROUBLE_TICKETS_UID_FK, TDP_COMMENT, TO_CHAR(TDP_SCHEDULE_TIME, 'MM-DD-YYYY HH:MI:SS AM') SDS_TIME, TDP_SCHEDULED_FL
   FROM ZONE_GROUPS, TROUBLE_DISPATCHES
  WHERE TDP_END_WORK_DATE IS NULL
    AND TDP_SCHEDULE_DATE = TRUNC(SYSDATE)
    AND TDP_SCHEDULED_FL = 'Y'
    AND TDP_TRBL_DSP_TECHS_UID_FK IS NULL
    AND ZOP_UID_PK = TDP_ZONE_GROUPS_UID_FK
    AND TO_NUMBER(TO_CHAR(TDP_SCHEDULE_TIME,'HH24MI')) < P_TIME_PERIOD
    AND ZOP_DISTRICT_GROUPS_UID_FK = P_DIG_UID_PK
  ORDER BY SDS_SCHEDULED_FL DESC, SDS_TIME;

  V_DUMMY         VARCHAR2(1);
  V_STRING        VARCHAR2(8000) := NULL;
  V_SCHED_STRING  VARCHAR2(40);

BEGIN

--THIS WILL FIRST GET THE DISTRICTS TO LOAD THE ORDERS
FOR REC IN GET_DISTRICTS LOOP

    FOR SO_REC IN GET_NOT_LOADED_JOBS(REC.DIG_UID_PK) LOOP
        IF SO_REC.SDS_SCHEDULED_FL = 'Y' THEN
           V_SCHED_STRING := 'SCHEDULED APPOINTMENT';
        ELSE
           V_SCHED_STRING := 'NON SCHEDULED APPOINTMENT';
        END IF;
        V_STRING := V_STRING||SO_REC.SO_TT_TYPE||'  '||REC.DIG_DISTRICT_GROUP_NAME||'   '||SO_REC.SDS_SO_UID_FK||'    '||SO_REC.SDS_TIME||'    '||V_SCHED_STRING||'    '||SO_REC.SDS_COMMENT||CHR(13) || CHR(10)||CHR(13) || CHR(10);
    END LOOP;

END LOOP;

V_STRING := RTRIM(SUBSTR('THE FOLLOWING ORDERS/TROUBLES HAVE NOT BEEN ASSIGNED TO A TECHNICIAN YET.  PLEASE SEE IF ANY ACTION IS REQUIRED!!!'||CHR(13) || CHR(10)||CHR(13) || CHR(10)||V_STRING,1,2000));


END PAST_APPT_NOT_LOADED;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE DOUBLE_LOADED_JOBS

IS

CURSOR ORDERS IS
select count(distinct sds_employees_uid_fk), sds_so_uid_fk
from so_loadings
where sds_schedule_date = trunc(sysdate)
  and sds_employees_uid_fk is not null
  and sds_completed_fl = 'N'
  and created_date > sysdate-2/1440
group by sds_so_uid_fk
having count(*) > 1;

 cursor get_so_loc(psvo_uid_pk number) is
        select SERV_LOCS.GET_SERV_LOC(ssx_service_locations_uid_fk)
          from service_locations, serv_serv_loc_so
         where ssx_so_uid_fk = psvo_uid_pk
           and slo_uid_pk = ssx_service_locations_uid_fk
           and ssx_primary_loc_fl = 'Y'
           and ssx_end_date is null;

 cursor get_svc_loc(psvo_uid_pk number) is
        select SERV_LOCS.GET_SERV_LOC(ssl_service_locations_uid_fk)
          from service_locations, serv_serv_locations, services, so
         where ssl_services_uid_fk = svc_uid_pk
           and slo_uid_pk = ssl_service_locations_uid_fk
           and ssl_primary_loc_fl = 'Y'
           and ssl_end_date is null
           and svo_uid_pk =psvo_uid_pk
           and svo_services_uid_fk = svc_uid_pk;

   v_location_description   varchar2(2000);
   v_string                 varchar2(8000) := NULL;

BEGIN

FOR REC IN ORDERS LOOP
  OPEN get_so_loc(REC.sds_so_uid_fk);
  FETCH get_so_loc INTO v_location_description;
  IF get_so_loc%NOTFOUND THEN
    OPEN get_svc_loc(REC.sds_so_uid_fk);
    FETCH get_svc_loc INTO v_location_description;
    CLOSE get_svc_loc;
  END IF;
  CLOSE get_so_loc;

  v_string := v_string||REC.sds_so_uid_fk||'   '||v_location_description||CHR(13) || CHR(10);
END LOOP;


END DOUBLE_LOADED_JOBS;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_CUS_LOGIN_UPDATE(P_CUS_UID_PK IN NUMBER, P_CUS_LOGIN IN VARCHAR, P_CUS_PASSWORD IN VARCHAR, P_SEC_UID_PK IN NUMBER, P_SEC_ANSWER IN VARCHAR, P_CUS_EMAIL IN VARCHAR)

RETURN VARCHAR IS

CURSOR GET_SEC_QUESTION IS
  SELECT SCQ_QUESTION
    FROM SEC_QUESTIONS
   WHERE SCQ_UID_PK = P_SEC_UID_PK;

 V_SEC_QUESTION  VARCHAR2(2000);

BEGIN

IF P_SEC_UID_PK IS NOT NULL THEN
   OPEN GET_SEC_QUESTION;
   FETCH GET_SEC_QUESTION INTO V_SEC_QUESTION;
   CLOSE GET_SEC_QUESTION;
END IF;

UPDATE CUSTOMERS
   SET CUS_LOGIN = P_CUS_LOGIN,
       CUS_PASSWORD = P_CUS_PASSWORD,
       CUS_SEC_QUESTIONS_UID_FK = P_SEC_UID_PK,
       CUS_SECURITY_QUESTION = V_SEC_QUESTION,
       CUS_SECURITY_ANSWER = P_SEC_ANSWER,
       CUS_EMAIL = P_CUS_EMAIL
 WHERE CUS_UID_PK = P_CUS_UID_PK;

 COMMIT;

 RETURN NULL;

exception
when others then
   RETURN 'FAILED';

END FN_CUS_LOGIN_UPDATE;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_TECH_STATUS_UPDATE(P_EMP_UID_PK IN NUMBER, P_SERIAL# IN VARCHAR, P_STATUS IN VARCHAR)

RETURN VARCHAR IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
  SELECT IVL_UID_PK
    FROM INVENTORY_LOCATIONS
   WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

 CURSOR AVAIALBLE_CODES(P_CODE IN VARCHAR) IS
   SELECT AVC_UID_PK, AVC_DESCRIPTION
     FROM AVAILABLE_CODES
    WHERE AVC_SYSTEM_CODE = P_CODE;

 CURSOR CBL_MDM_STATUS(P_CODE IN VARCHAR) IS
   SELECT CMS_UID_PK, CMS_DESCRIPTION
     FROM CBL_MDM_STATUS
   WHERE CMS_SYSTEM_CODE = P_CODE;

v_alopa_msg            varchar2(1);
V_IVL_UID_PK           NUMBER;
V_TVB_UID_PK           NUMBER;
V_AVC_UID_PK           NUMBER;
V_SEQ_UID_PK           NUMBER;
V_SVO_UID_PK           NUMBER;
V_CTS_UID_PK           NUMBER;
V_BBO_MEO_UID_PK       NUMBER;
V_LAST_IVL_UID_PK      NUMBER;
V_LAST_IVL_DESCRIPTION VARCHAR2(200);
V_RETURN_MESSAGE       VARCHAR2(2000);
V_EQUIP_TYPE           VARCHAR2(1);
V_CCB_UID_PK           NUMBER;
V_CBM_UID_PK           NUMBER;
V_BOX_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_CABLE_MODEM_TYPE     VARCHAR2(1);
V_TIME                 VARCHAR2(200);
V_SOR_COMMENT          VARCHAR2(2000);
V_IDENTIFIER           VARCHAR2(200);
V_DESCRIPTION          VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);
V_AVC_DESCRIPTION      VARCHAR2(200);

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

--DTERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_SERIAL#, V_BOX_UID_PK);

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'SERIAL# NOT FOUND.  PLEASE MAKE SURE IT IS ENTERED CORRECTLY.';
END IF;

IF V_IVL_UID_PK IS NULL THEN
   RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
END IF;

--BOX STATUS CHECK
V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_SERIAL#, V_EQUIP_TYPE, V_DESCRIPTION);
IF V_STATUS = 'AC' THEN
   RETURN 'THIS BOX/MODEM IS MARKED AS '||V_DESCRIPTION||'.  PLEASE CALL WAREHOUSE TO UPDATE THE STATUS.';
END IF;

--LOCATION CHECK
IF V_IVL_UID_PK IS NOT NULL THEN
   V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_SERIAL#);
   OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
   FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
   CLOSE LAST_LOCATION;

   IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
      RETURN 'THIS BOX/MODEM IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
   END IF;
END IF;


IF V_EQUIP_TYPE  = 'S' THEN

   OPEN AVAIALBLE_CODES(P_STATUS);
   FETCH AVAIALBLE_CODES INTO V_AVC_UID_PK, V_AVC_DESCRIPTION;
   CLOSE AVAIALBLE_CODES;

   UPDATE CATV_CONV_BOXES
      SET CCB_AVAILABLE_CODES_UID_FK = V_AVC_UID_PK
    WHERE CCB_UID_PK = V_BOX_UID_PK;

    BOX_MODEM_PKG.PR_EXCEPTION(P_SERIAL#, NULL, 'STATUS UPDATE', 'STATUS CHANGED TO '||V_AVC_DESCRIPTION);

ELSIF V_EQUIP_TYPE  = 'M' THEN

   OPEN CBL_MDM_STATUS(P_STATUS);
   FETCH CBL_MDM_STATUS INTO V_AVC_UID_PK, V_AVC_DESCRIPTION;
   CLOSE CBL_MDM_STATUS;

   UPDATE CABLE_MODEMS
      SET CBM_CBL_MDM_STATUS_UID_FK = V_AVC_UID_PK
    WHERE CBM_UID_PK = V_BOX_UID_PK;

   BOX_MODEM_PKG.PR_EXCEPTION(P_SERIAL#, NULL, 'STATUS UPDATE', 'STATUS CHANGED TO '||V_AVC_DESCRIPTION);

ELSIF V_EQUIP_TYPE  = 'E' THEN

   OPEN AVAIALBLE_CODES(P_STATUS);
   FETCH AVAIALBLE_CODES INTO V_AVC_UID_PK, V_AVC_DESCRIPTION;
   CLOSE AVAIALBLE_CODES;

   UPDATE MTA_BOXES
      SET MTA_AVAILABLE_CODES_UID_FK = V_AVC_UID_PK
    WHERE MTA_UID_PK = V_BOX_UID_PK;

    BOX_MODEM_PKG.PR_EXCEPTION(P_SERIAL#, NULL, 'STATUS UPDATE', 'STATUS CHANGED TO '||V_AVC_DESCRIPTION);

ELSIF V_EQUIP_TYPE  = 'A' THEN

   OPEN CBL_MDM_STATUS(P_STATUS);
   FETCH CBL_MDM_STATUS INTO V_AVC_UID_PK, V_AVC_DESCRIPTION;
   CLOSE CBL_MDM_STATUS;

   UPDATE ADSL_MODEMS
      SET ADM_CBL_MDM_STATUS_UID_FK = V_AVC_UID_PK,
          ADM_VDSL_FL = 'N' -- MAKE SURE VDSL FLAG IS N FOR ADSL MODEMS 
    WHERE ADM_UID_PK = V_BOX_UID_PK;

   BOX_MODEM_PKG.PR_EXCEPTION(P_SERIAL#, NULL, 'STATUS UPDATE', 'STATUS CHANGED TO '||V_AVC_DESCRIPTION);
   
ELSIF V_EQUIP_TYPE  = 'R' THEN

   OPEN CBL_MDM_STATUS(P_STATUS);
   FETCH CBL_MDM_STATUS INTO V_AVC_UID_PK, V_AVC_DESCRIPTION;
   CLOSE CBL_MDM_STATUS;

   UPDATE ROUTERS
      SET ROU_CBL_MDM_STATUS_UID_FK = V_AVC_UID_PK
    WHERE ROU_UID_PK = V_BOX_UID_PK;

   BOX_MODEM_PKG.PR_EXCEPTION(P_SERIAL#, NULL, 'STATUS UPDATE', 'STATUS CHANGED TO '||V_AVC_DESCRIPTION);
   
ELSIF V_EQUIP_TYPE  = 'L' THEN

   OPEN CBL_MDM_STATUS(P_STATUS);
   FETCH CBL_MDM_STATUS INTO V_AVC_UID_PK, V_AVC_DESCRIPTION;
   CLOSE CBL_MDM_STATUS;

   UPDATE CPE
      SET CPE_CBL_MDM_STATUS_UID_FK = V_AVC_UID_PK
    WHERE CPE_UID_PK = V_BOX_UID_PK;

   BOX_MODEM_PKG.PR_EXCEPTION(P_SERIAL#, NULL, 'STATUS UPDATE', 'STATUS CHANGED TO '||V_AVC_DESCRIPTION);
   
ELSIF V_EQUIP_TYPE = 'V' THEN 

   OPEN CBL_MDM_STATUS(P_STATUS);
   FETCH CBL_MDM_STATUS INTO V_AVC_UID_PK, V_AVC_DESCRIPTION;
   CLOSE CBL_MDM_STATUS;

   UPDATE ADSL_MODEMS
      SET ADM_CBL_MDM_STATUS_UID_FK = V_AVC_UID_PK,
          ADM_VDSL_FL = 'Y' -- MAKE SURE VDSL FLAG IS Y FOR VDSL MODEMS 
    WHERE ADM_UID_PK = V_BOX_UID_PK;

   BOX_MODEM_PKG.PR_EXCEPTION(P_SERIAL#, NULL, 'STATUS UPDATE', 'STATUS CHANGED TO '||V_AVC_DESCRIPTION);

END IF;

COMMIT;
RETURN 'STATUS UPDATED SUCCESSFULLY TO '||V_AVC_DESCRIPTION;

END FN_TECH_STATUS_UPDATE;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION GET_IDENTIFIER_IWP(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER, P_TYPE IN VARCHAR)

RETURN VARCHAR IS

V_LNO_UID_PK  NUMBER;
V_IDENTIFIER  VARCHAR2(80) := NULL;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK)
    FROM SERVICES
   WHERE SVC_UID_PK = P_SVC_UID_PK;

BEGIN

IF P_TYPE = 'S' THEN --SERVICE ORDER

   V_IDENTIFIER := GET_SO_IDENTIFIER_FUN(P_SVO_UID_PK, V_LNO_UID_PK);

ELSE

   OPEN GET_IDENTIFIER;
   FETCH GET_IDENTIFIER INTO V_IDENTIFIER;
   CLOSE GET_IDENTIFIER;

END IF;

RETURN V_IDENTIFIER;

END GET_IDENTIFIER_IWP;

FUNCTION BOX_MODEM_CHANGED(P_SVO_UID_PK IN NUMBER)

RETURN VARCHAR IS

CURSOR CHECK_CHANGE IS
  SELECT 'X'
  FROM CATV_SERV_BOX_SO, CATV_CONV_BOXES, CATV_SO
  WHERE CCB_UID_PK = CBX_CATV_CONV_BOXES_UID_FK
    AND CTS_UID_PK = CBX_CATV_SO_UID_FK
    AND CTS_SO_UID_FK = P_SVO_UID_PK
    AND TRUNC(CATV_SERV_BOX_SO.CREATED_DATE) = TRUNC(SYSDATE)
    AND TRUNC(CBX_START_DATE) = TRUNC(SYSDATE)
UNION
select 'X'
from so_assgnmts, cable_modems
where cbm_uid_pk = son_cable_modems_uid_fk
  and son_so_uid_fk = P_SVO_UID_PK
  and TRUNC(so_assgnmts.MODIFIED_DATE) = TRUNC(SYSDATE)
UNION
select 'X'
from so_assgnmts, mta_so, mta_ports, mta_equip_units, mta_boxes
where mtp_uid_pk = MTO_MTA_PORTS_UID_FK
  and meu_uid_pk = MTP_MTA_EQUIP_UNITS_UID_FK
  and mta_uid_pk = MEU_MTA_BOXES_UID_FK
  and son_uid_pk = MTO_SO_ASSGNMTS_UID_FK
  and son_so_uid_fk = P_SVO_UID_PK
  and TRUNC(mta_so.MODIFIED_DATE) = TRUNC(SYSDATE)
UNION
select 'X'
from so_assgnmts, adsl_modems
where adm_uid_pk = son_adsl_modems_uid_fk
  and son_so_uid_fk = P_SVO_UID_PK
  and TRUNC(so_assgnmts.MODIFIED_DATE) = TRUNC(SYSDATE);

V_DUMMY  VARCHAR2(1);

BEGIN

IF P_SVO_UID_PK IS NOT NULL THEN
   OPEN CHECK_CHANGE;
   FETCH CHECK_CHANGE INTO V_DUMMY;
   IF CHECK_CHANGE%NOTFOUND THEN
      V_DUMMY := NULL;
   END IF;
   CLOSE CHECK_CHANGE;
END IF;

IF V_DUMMY IS NULL THEN
   RETURN 'F';
ELSE
   RETURN 'T';
END IF;

END BOX_MODEM_CHANGED;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_GET_SO_ASSIGNMENTS (P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

  CURSOR ASSIGNMENT_INFO_SVO IS
  select son_uid_pk,
         son_line#,
         son_opx,
         serv_locs.get_serv_loc_without_mun(son_service_locations_uid_fk) location,
         lnt_code,
         son_bonded_fl,
         son_hsd_fl,
         son_pedestal,
         son_protector,
         sai_no#,
         lrt_no#,
         cli_code,
         len_len,
         son_dslam_ports_uid_fk,
         son_adsl_modems_uid_fk,
         son_cable_modems_uid_fk,
         son_fiber_nodes_uid_fk,
         son_pas_opt_networks_uid_fk,
         ara_code,
         svo_services_uid_fk,
         sot_system_code, 
         svo_main_so_fl,   -- HUB Fl for metro
         son_vlan,
         son_delivery_methods_uid_fk,
         son_fac_equip_types_uid_fk,
         GET_IDENTIFIER_FUN(svc_uid_pk, svc_office_serv_types_uid_fk)||'-'||son_line# POINT_ID,
         son_network_number,
         son_adsl_modems_gw_uid_fk
    from so_assgnmts,
         so,
         services,
         so_types,
         areas,
         cllis,
         lens,
         len_types,
         lead_routes,
         sai
   where son_so_uid_fk          = p_svo_uid_pk
     and svc_uid_pk             = svo_services_uid_fk
     and sot_uid_pk             = svo_so_types_uid_fk
     and son_cllis_uid_fk       = cli_uid_pk(+)
     and son_lens_uid_fk        = len_uid_pk(+)
     and len_len_types_uid_fk   = lnt_uid_pk(+)
     and son_sai_uid_fk         = sai_uid_pk(+)
     and son_lead_routes_uid_fk = lrt_uid_pk(+)
     and son_areas_uid_fk       = ara_uid_pk(+)
     and svo_uid_pk             = son_so_uid_fk;

  -- this is for CS order generated on TT for a swap
  CURSOR ASSIGNMENT_INFO_OTHER_SVO IS
  select son_uid_pk,
         son_line#,
         son_opx,
         serv_locs.get_serv_loc_without_mun(son_service_locations_uid_fk) location,
         lnt_code,
         son_bonded_fl,
         son_hsd_fl,
         son_pedestal,
         son_protector,
         sai_no#,
         lrt_no#,
         cli_code,
         len_len,
         son_dslam_ports_uid_fk,
         son_adsl_modems_uid_fk,
         son_cable_modems_uid_fk,
         son_fiber_nodes_uid_fk,
         son_pas_opt_networks_uid_fk,
         ara_code,
         svo_services_uid_fk,
         sot_system_code,
         son_network_number,
         son_adsl_modems_gw_uid_fk
    from so_assgnmts, 
         so,
         so_types,
         areas,
         cllis,
         lens,
         len_types,
         lead_routes,
         sai
   where son_so_uid_fk          = svo_uid_pk
     and svo_services_uid_fk    = p_svc_uid_pk
     and sot_uid_pk             = svo_so_types_uid_fk
     and son_cllis_uid_fk       = cli_uid_pk(+)
     and son_lens_uid_fk        = len_uid_pk(+)
     and len_len_types_uid_fk   = lnt_uid_pk(+)
     and son_sai_uid_fk         = sai_uid_pk(+)
     and son_lead_routes_uid_fk = lrt_uid_pk(+)
     and son_areas_uid_fk       = ara_uid_pk(+)
     and TRUNC(so.CREATED_DATE) = TRUNC(SYSDATE)
     AND svo_close_date IS NULL;

  CURSOR ASSIGNMENT_INFO_SVA(P_SVC_PK IN NUMBER) IS
  select sva_uid_pk,
         sva_line#,
         sva_opx,
         serv_locs.get_serv_loc_without_mun(sva_service_locations_uid_fk) location,
         lnt_code,
         sva_bonded_fl,
         sva_hsd_fl,
         sva_pedestal,
         sva_protector,
         sai_no#,
         lrt_no#,
         cli_code,
         len_len,
         sva_dslam_ports_uid_fk,
         sva_adsl_modems_uid_fk,
         sva_cable_modems_uid_fk,
         sva_fiber_nodes_uid_fk,
         sva_pas_opt_networks_uid_fk,
         ara_code,
         svc_main_service_fl,   -- HUB Fl for metro
         sva_vlan,
         sva_delivery_methods_uid_fk,
         sva_fac_equip_types_uid_fk,
         GET_IDENTIFIER_FUN(svc_uid_pk, svc_office_serv_types_uid_fk)||'-'||sva_line# POINT_ID,
         sva_network_number,
         sva_adsl_modems_gw_uid_fk
    from services,
         service_assgnmts,
         cllis,
         lens,
         len_types,
         lead_routes,
         sai,
         areas
   where svc_uid_pk             = P_SVC_PK
     and svc_uid_pk             = sva_services_uid_fk  
     and sva_cllis_uid_fk       = cli_uid_pk(+)
     and sva_lens_uid_fk        = len_uid_pk(+)
     and len_len_types_uid_fk   = lnt_uid_pk(+)
     and sva_sai_uid_fk         = sai_uid_pk(+)
     and sva_lead_routes_uid_fk = lrt_uid_pk(+)
     and sva_areas_uid_fk       = ara_uid_pk(+);

  CURSOR GET_DSLAM_INFO (p_dsp_uid_pk IN NUMBER) IS
      SELECT dsp_number, dsp_vci, dsp_vpi, dcd_shelf, dcd_cardnum, dcd_description,
             slm_description, cli_code, dsp_degrade_fl, dsp_hold_fl
        FROM dslam_ports, dslam_cards, dslams, cllis
       WHERE dsp_uid_pk = p_dsp_uid_pk
         AND dcd_uid_pk = dsp_dslam_cards_uid_fk
         AND slm_uid_pk = dcd_dslams_uid_fk
         AND cli_uid_pk = slm_cllis_uid_fk;

  CURSOR GET_ADSL_MAC (P_ADM_UID_PK IN NUMBER) IS
    SELECT ADM_MAC_ADDRESS
      FROM ADSL_MODEMS
     WHERE ADM_UID_PK = P_ADM_UID_PK;
       
  CURSOR GET_CBM_MAC(p_cbm_uid_pk NUMBER) IS
   SELECT cbm_mac_address
     FROM cable_modems
    WHERE cbm_uid_pk = p_cbm_uid_pk;
    
CURSOR GET_CBM_MAC_SVC(p_svc_pk in number) IS
  SELECT cbm_mac_address
    FROM service_assgnmts, cable_modems
   WHERE sva_cable_modems_uid_fk = cbm_uid_pk
     AND sva_services_uid_fk = p_svc_pk;
      
  CURSOR get_fbn_data(p_fbn_uid_pk NUMBER) IS
   SELECT fbn_name,
         cmt_code
     FROM fiber_nodes,
         cbl_mdm_trm_sys
    WHERE  fbn_uid_pk = p_fbn_uid_pk
     and fbn_cbl_mdm_trm_sys_uid_fk = cmt_uid_pk(+);

  CURSOR get_pon_data(p_pon_uid_pk NUMBER) IS
   SELECT cha_chassis_no#, pon_no#,
         cmt_code
     FROM chassis, pas_opt_networks,
         cbl_mdm_trm_sys
    WHERE  pon_uid_pk = p_pon_uid_pk
     and pon_chassis_uid_fk = cha_uid_pk
     and pon_cbl_mdm_trm_sys_uid_fk = cmt_uid_pk(+);
       
  CURSOR check_for_cbm(p_svc_pk in number) IS
    SELECT 'X'
      FROM service_assgnmts, cable_modems
     WHERE sva_cable_modems_uid_fk = cbm_uid_pk
       AND sva_services_uid_fk = p_svc_pk
    UNION
    SELECT 'X'
      FROM mta_services, service_assgnmts
     WHERE sva_uid_pk = mss_service_assgnmts_uid_fk
       AND sva_services_uid_fk = p_svc_pk;

  CURSOR get_svt_type IS
     SELECT svt_system_code
       FROM serv_sub_types, off_serv_subs, so
      WHERE osb_uid_pk = svo_off_serv_subs_uid_fk
        AND svt_uid_pk = osb_serv_sub_types_uid_fk
        AND svo_uid_pk = p_svo_uid_pk;
          
  CURSOR cur_delivery_methods(p_dvm_uid_pk    number) is
     SELECT dvm_code
       FROM delivery_methods
      WHERE dvm_uid_pk  = p_dvm_uid_pk; 

  CURSOR cur_fac_equip_types(p_fet_uid_pk    number) is
        SELECT fet_code
         FROM fac_equip_types
       WHERE fet_uid_pk  = p_fet_uid_pk;

        
  CURSOR get_son_onu_data(cp_son_uid_pk number) is 
   SELECT onu_registration_id
     FROM out_net_units, onu_ports, ftth_so
    WHERE onu_uid_pk = onp_out_net_units_uid_fk
      AND onp_uid_pk = fso_onu_ports_uid_fk
      AND fso_so_assgnmts_uid_fk = cp_son_uid_pk
    UNION
   SELECT onu_registration_id
     FROM out_net_units, onu_ports, ds0_ports, ftth_so
    WHERE onu_uid_pk = onp_out_net_units_uid_fk
      AND onp_uid_pk = ds0_onu_ports_uid_fk
      AND ds0_uid_pk = fso_ds0_ports_uid_fk
      AND fso_so_assgnmts_uid_fk = cp_son_uid_pk  ;

  CURSOR get_sva_onu_data(cp_sva_uid_pk number) is 
   SELECT onu_registration_id
     FROM out_net_units, onu_ports, ftth_services
    WHERE onu_uid_pk = onp_out_net_units_uid_fk
      AND onp_uid_pk = fts_onu_ports_uid_fk
      AND fts_service_assgnmts_uid_fk = cp_sva_uid_pk
    UNION
   SELECT onu_registration_id
     FROM out_net_units, onu_ports, ds0_ports, ftth_services
    WHERE onu_uid_pk = onp_out_net_units_uid_fk
      AND onp_uid_pk = ds0_onu_ports_uid_fk
      AND ds0_uid_pk = fts_ds0_ports_uid_fk
      AND fts_service_assgnmts_uid_fk = cp_sva_uid_pk  ;

  v_dummy               varchar2(1);
  v_svt_code            VARCHAR2(20);


  rec                ASSIGNMENT_INFO_SVO%rowtype;
  rec2               ASSIGNMENT_INFO_SVA%rowtype;
  v_rec              generic_data_type;
  v_dsp_number       varchar2(20);
  v_dsp_vci          varchar2(20);
  v_dsp_vpi          varchar2(20);
  v_dcd_shelf        varchar2(20);
  v_dcd_cardnum      varchar2(20);
  v_dcd_description  varchar2(200);
  v_slm_description  varchar2(200);
  v_cli_code         varchar2(20);
  v_dsp_degrade_fl   varchar2(1);
  v_dsp_hold_fl      varchar2(1);
  v_mac_address      varchar2(200);
  v_mlh_message      varchar2(500);
  v_fbn_name         varchar2(20);
  v_pon_no#          number(5);
  v_chassis_no#      number(38);
  v_cmts             varchar2(12);
  v_other_so_found   BOOLEAN;
  v_reg_id            number;
  v_network_number   so_assgnmts.son_network_number%type;
BEGIN

IF P_SVO_UID_PK IS NOT NULL THEN

 OPEN ASSIGNMENT_INFO_SVO;
 LOOP
    FETCH ASSIGNMENT_INFO_SVO into rec;
    EXIT WHEN ASSIGNMENT_INFO_SVO%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_number1    := rec.son_uid_pk;    -- son_uid_pk
     v_rec.gdt_number2    := rec.son_line#;     -- son_line#
     v_rec.gdt_number3    := rec.son_opx;       -- son_opx
     v_rec.gdt_alpha1     := rec.location;      -- service location address
     v_rec.gdt_alpha2     := rec.lnt_code;      -- len type
     v_rec.gdt_alpha3     := rec.son_bonded_fl; -- bondled flag
     v_rec.gdt_alpha4     := rec.son_hsd_fl;    -- HSD flag
     v_rec.gdt_alpha5     := rec.SON_PEDESTAL;  -- Pedestal
     v_rec.gdt_alpha6     := rec.SON_PROTECTOR; -- Protector
     v_rec.gdt_number4    := rec.SAI_NO#;       -- SAI#
     v_rec.gdt_alpha7     := rec.LRT_NO#;       -- LEAD ROUTE#
     v_rec.gdt_alpha8     := rec.CLI_CODE;      -- CLLI
     v_rec.gdt_alpha9     := rec.LEN_LEN;       -- LEN

     OPEN GET_DSLAM_INFO(rec.SON_DSLAM_PORTS_UID_FK);
     FETCH GET_DSLAM_INFO INTO v_dsp_number,
                               v_dsp_vci,
                               v_dsp_vpi,
                               v_dcd_shelf,
                               v_dcd_cardnum,
                               v_dcd_description,
                               v_slm_description,
                               v_cli_code,
                               v_dsp_degrade_fl,
                               v_dsp_hold_fl;
     CLOSE GET_DSLAM_INFO;

     v_rec.gdt_alpha10     := v_cli_code;        -- CLLI CODE
     v_rec.gdt_alpha11     := v_slm_description; -- DSLAM
     v_rec.gdt_alpha12     := v_dsp_number;      -- PORT
     v_rec.gdt_alpha13     := v_dcd_shelf;       -- SHELF
     v_rec.gdt_alpha14     := v_dcd_cardnum;     -- CARD
     v_rec.gdt_alpha15     := v_dcd_description; -- CARD DESC
     v_rec.gdt_alpha16     := v_dsp_vpi;         -- VPI
     v_rec.gdt_alpha17     := v_dsp_vci;         -- VCI
     v_rec.gdt_alpha18     := v_dsp_hold_fl;     -- HOLD FLAG
     v_rec.gdt_alpha19     := v_dsp_degrade_fl;  -- DEGRADE FLAG
     v_rec.gdt_alpha21     := rec.son_line#||' - '||rec.SON_PEDESTAL||'/'||rec.SON_PROTECTOR||'/'||rec.LRT_NO#||' '||rec.CLI_CODE||' '||rec.LEN_LEN;

     --THIS WILL DISPLAY A MESSAGE TO THE TECHNICIAN TO INFORM THEM OF A MULTI LINE HUNT LINE TO CALL THE CO TO WORK
     ---V_MLH_MESSAGE := INSTALLER_WEB_PKG.FN_MLH_CHECK(P_SVO_UID_PK); -- HD 105771 RMC 05/03/2011 - MLH Processing
     ---v_rec.gdt_alpha22 := V_MLH_MESSAGE;  -- HD 105771 RMC 05/03/2011 - MLH Processing
     
     V_MAC_ADDRESS := NULL;
     IF REC.SON_ADSL_MODEMS_UID_FK IS NOT NULL THEN
        OPEN GET_ADSL_MAC(REC.SON_ADSL_MODEMS_UID_FK);
        FETCH GET_ADSL_MAC INTO V_MAC_ADDRESS;
        CLOSE GET_ADSL_MAC;
     END IF;
     v_rec.gdt_alpha20     := V_MAC_ADDRESS;  -- ADSL MODEM MAC ADDRESS
     
     --adsl modem gateway
     V_MAC_ADDRESS := NULL;
     IF REC.SON_ADSL_MODEMS_GW_UID_FK IS NOT NULL THEN
        OPEN GET_ADSL_MAC(REC.SON_ADSL_MODEMS_GW_UID_FK);
        FETCH GET_ADSL_MAC INTO V_MAC_ADDRESS;
        CLOSE GET_ADSL_MAC;
     END IF;
     v_rec.gdt_alpha37     := V_MAC_ADDRESS;  -- ADSL MODEM GATEWAY MAC ADDRESS
     
     OPEN get_svt_type;
     FETCH get_svt_type INTO v_svt_code;
     CLOSE get_svt_type;
     
     V_MAC_ADDRESS := NULL;
     IF REC.SON_CABLE_MODEMS_UID_FK IS NOT NULL THEN
        OPEN GET_CBM_MAC(REC.SON_CABLE_MODEMS_UID_FK);
        FETCH GET_CBM_MAC INTO V_MAC_ADDRESS;
        CLOSE GET_CBM_MAC;
     ELSE
        IF v_svt_code IN ('PACKET CABLE','RFOG') AND REC.SOT_SYSTEM_CODE IN ('CS','MS') THEN
           OPEN GET_CBM_MAC_SVC(rec.svo_services_uid_fk);
           FETCH GET_CBM_MAC_SVC INTO V_MAC_ADDRESS;
           IF GET_CBM_MAC_SVC%NOTFOUND THEN
              V_MAC_ADDRESS := NULL;
           END IF;
           CLOSE GET_CBM_MAC_SVC;
        END IF;
     END IF;
     
     v_rec.gdt_alpha23     := V_MAC_ADDRESS;  -- CABLE MODEM MAC ADDRESS
     
     IF rec.son_fiber_nodes_uid_fk IS NOT NULL THEN 
         OPEN get_fbn_data(rec.son_fiber_nodes_uid_fk);
         FETCH get_fbn_data INTO v_fbn_name, v_cmts;
         CLOSE get_fbn_data;
     END IF;
     IF rec.son_pas_opt_networks_uid_fk IS NOT NULL THEN
         OPEN get_pon_data(rec.son_pas_opt_networks_uid_fk);
         FETCH get_pon_data INTO v_chassis_no#, v_pon_no#, v_cmts;
         CLOSE get_pon_data;
     END IF;
     
     v_rec.gdt_alpha24     := rec.ARA_CODE;    -- area 
     v_rec.gdt_alpha25     := v_fbn_name;      --fiber node
     v_rec.gdt_alpha26     := v_cmts;          -- cmts
     v_rec.gdt_number5     := v_chassis_no#;
     v_rec.gdt_number6     := v_pon_no#;
     
     IF v_mac_address IS NOT NULL THEN
         v_rec.gdt_alpha27    := FN_CHECK_BOX_MODEM_PROVISIONED(v_mac_address,p_svc_uid_pk,p_svo_uid_pk,null);
 
         v_rec.gdt_alpha28 := 'N'; -- remove button display
         v_rec.gdt_alpha29 := 'N'; -- change button display
         OPEN CHECK_FOR_CBM(rec.svo_services_uid_fk);
         FETCH CHECK_FOR_CBM INTO V_DUMMY;
         IF CHECK_FOR_CBM%FOUND THEN
            v_rec.gdt_alpha28 := 'N';
            IF v_svt_code NOT IN ('PACKET CABLE','RFOG') THEN
               v_rec.gdt_alpha29 := 'Y';
            END IF;
         ELSE
            v_rec.gdt_alpha28 := 'Y';
            v_rec.gdt_alpha29 := 'N';
         END IF;
         CLOSE CHECK_FOR_CBM;
     
         IF p_svo_uid_pk IS NOT NULL THEN
            IF v_svt_code NOT IN ('PACKET CABLE','CABLE MODEM','RFOG') THEN
               v_rec.gdt_alpha28 := 'Y';
               v_rec.gdt_alpha29 := 'N';
            END IF;
         END IF;
         
         --njj this will mark if the hit and refresh button can be displayed
         IF v_rec.gdt_alpha27 = 'N' AND rec.sot_system_code = 'NS' THEN
            v_rec.gdt_alpha30 := 'Y';
         -- MCV 01/23/2014 for BPP MS orders need to provision
         ELSIF v_svt_code IN ('PACKET CABLE','CABLE MODEM','RFOG')  AND rec.sot_system_code = 'MS' THEN
            v_rec.gdt_alpha30 := 'Y';
         ELSE
            v_rec.gdt_alpha30 := 'N';
         END IF;
         
         --njj this will mark if the swap button/link can be displayed
         v_rec.gdt_alpha31 := 'N';
         
     ELSE
        NULL;
        /*IF REC.SOT_SYSTEM_CODE = 'MS' THEN
           OPEN ASSIGNMENT_INFO_SVA(REC.svo_services_uid_fk);
           FETCH ASSIGNMENT_INFO_SVA into rec2;
           IF ASSIGNMENT_INFO_SVA%FOUND THEN
              V_MAC_ADDRESS := NULL;
							IF REC2.SVA_CABLE_MODEMS_UID_FK IS NOT NULL THEN
							   OPEN GET_CBM_MAC(REC2.SVA_CABLE_MODEMS_UID_FK);
							   FETCH GET_CBM_MAC INTO V_MAC_ADDRESS;
							   CLOSE GET_CBM_MAC;
							END IF;
              v_rec.gdt_alpha23 := V_MAC_ADDRESS;  -- CABLE MODEM MAC ADDRESS
              v_rec.gdt_alpha27 := 'Y';
							v_rec.gdt_alpha28 := 'N'; -- remove button display
              v_rec.gdt_alpha29 := 'N'; -- change button display
              v_rec.gdt_alpha30 := 'N'; -- hit and refresh button display
              v_rec.gdt_alpha31 := 'N'; -- swap button display
           END IF;
           CLOSE ASSIGNMENT_INFO_SVA;
        END IF;*/
     END IF;

     -- start data for METRO-ETH service type  ------
     v_rec.gdt_alpha32 :=  rec.point_id;   
     v_rec.gdt_alpha33 :=  rec.svo_main_so_fl;  -- hub fl
     if rec.son_delivery_methods_uid_fk is not null then
       open  cur_delivery_methods(rec.son_delivery_methods_uid_fk);
       fetch cur_delivery_methods into  v_rec.gdt_alpha34 ;  -- delivery method
       close cur_delivery_methods ;
     end if;
     v_rec.gdt_alpha35 :=  rec.son_vlan;  -- vlan
     
     if rec.son_fac_equip_types_uid_fk is not null then
        open  cur_fac_equip_types(rec.son_fac_equip_types_uid_fk);
        fetch cur_fac_equip_types into  v_rec.gdt_alpha36 ;  -- fac equip types
        close cur_fac_equip_types ;
     end if;

     -- end fields for METRO-ETH service type  ------
     
     -- MCV 08/28/2012 -- for GPON
     OPEN get_son_onu_data(rec.son_uid_pk);
     FETCH get_son_onu_data into v_reg_id;
     CLOSE get_son_onu_data;
     
     v_rec.gdt_number7     := v_reg_id;

     v_rec.gdt_number8     := rec.son_network_number;
     ----
     
     PIPE ROW (v_rec);
  END LOOP;

  CLOSE ASSIGNMENT_INFO_SVO;

ELSE

     OPEN ASSIGNMENT_INFO_SVA(P_SVC_UID_PK);
     LOOP
        FETCH ASSIGNMENT_INFO_SVA into rec2;
        EXIT WHEN ASSIGNMENT_INFO_SVA%notfound;

        --set the fields
        v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

         v_rec.gdt_number1    := rec2.sva_uid_pk;    -- son_uid_pk
         v_rec.gdt_number2    := rec2.sva_line#;     -- son_line#
         v_rec.gdt_number3    := rec2.sva_opx;       -- son_opx
         v_rec.gdt_alpha1     := rec2.location;      -- service location address
         v_rec.gdt_alpha2     := rec2.lnt_code;      -- len type
         v_rec.gdt_alpha3     := rec2.sva_bonded_fl; -- bondled flag
         v_rec.gdt_alpha4     := rec2.sva_hsd_fl;    -- HSD flag
         v_rec.gdt_alpha5     := rec2.SVA_PEDESTAL;  -- Pedestal
         v_rec.gdt_alpha6     := rec2.SVA_PROTECTOR; -- Protector
         v_rec.gdt_number4    := rec2.SAI_NO#;       -- SAI#
         v_rec.gdt_alpha7     := rec2.LRT_NO#;       -- LEAD ROUTE#
         v_rec.gdt_alpha8     := rec2.CLI_CODE;      -- CLLI
         v_rec.gdt_alpha9     := rec2.LEN_LEN;       -- LEN

         OPEN GET_DSLAM_INFO(rec2.SVA_DSLAM_PORTS_UID_FK);
         FETCH GET_DSLAM_INFO INTO v_dsp_number,
                                   v_dsp_vci,
                                   v_dsp_vpi,
                                   v_dcd_shelf,
                                   v_dcd_cardnum,
                                   v_dcd_description,
                                   v_slm_description,
                                   v_cli_code,
                                   v_dsp_degrade_fl,
                                   v_dsp_hold_fl;
         CLOSE GET_DSLAM_INFO;

         v_rec.gdt_alpha10     := v_cli_code;        -- CLLI CODE
         v_rec.gdt_alpha11     := v_slm_description; -- DSLAM
         v_rec.gdt_alpha12     := v_dsp_number;      -- PORT
         v_rec.gdt_alpha13     := v_dcd_shelf;       -- SHELF
         v_rec.gdt_alpha14     := v_dcd_cardnum;     -- CARD
         v_rec.gdt_alpha15     := v_dcd_description; -- CARD DESC
         v_rec.gdt_alpha16     := v_dsp_vpi;         -- VPI
         v_rec.gdt_alpha17     := v_dsp_vci;         -- VCI
         v_rec.gdt_alpha18     := v_dsp_hold_fl;     -- HOLD FLAG
         v_rec.gdt_alpha19     := v_dsp_degrade_fl;  -- DEGRADE FLAG
         v_rec.gdt_alpha21     := rec2.sva_line#||' - '||rec2.SVA_PEDESTAL||'/'||rec2.SVA_PROTECTOR||'/'||rec2.LRT_NO#||' '||rec2.CLI_CODE||' '||rec2.LEN_LEN;
         v_rec.gdt_alpha22     := NULL;
     
         V_MAC_ADDRESS := NULL;
         IF REC2.SVA_ADSL_MODEMS_UID_FK IS NOT NULL THEN
            OPEN GET_ADSL_MAC(REC2.SVA_ADSL_MODEMS_UID_FK);
            FETCH GET_ADSL_MAC INTO V_MAC_ADDRESS;
            CLOSE GET_ADSL_MAC;
         END IF;
         
         v_rec.gdt_alpha20     := V_MAC_ADDRESS;  -- ADSL MODEM MAC ADDRESS
         
         --adsl modem gateway
         V_MAC_ADDRESS := NULL;
         IF REC2.SVA_ADSL_MODEMS_GW_UID_FK IS NOT NULL THEN
            OPEN GET_ADSL_MAC(REC2.SVA_ADSL_MODEMS_GW_UID_FK);
            FETCH GET_ADSL_MAC INTO V_MAC_ADDRESS;
            CLOSE GET_ADSL_MAC;
         END IF;
         v_rec.gdt_alpha37     := V_MAC_ADDRESS;  -- ADSL MODEM GATEWAY MAC ADDRESS


         V_MAC_ADDRESS := NULL;
         IF REC2.SVA_CABLE_MODEMS_UID_FK IS NOT NULL THEN
            OPEN GET_CBM_MAC(REC2.SVA_CABLE_MODEMS_UID_FK);
            FETCH GET_CBM_MAC INTO V_MAC_ADDRESS;
            CLOSE GET_CBM_MAC;
         END IF;
         v_rec.gdt_alpha23     := V_MAC_ADDRESS;  -- CABLE MODEM MAC ADDRESS
     
     
         IF rec2.sva_fiber_nodes_uid_fk IS NOT NULL THEN
             OPEN get_fbn_data(rec2.sva_fiber_nodes_uid_fk);
             FETCH get_fbn_data INTO v_fbn_name, v_cmts;
             CLOSE get_fbn_data;
         END IF;
         IF rec2.sva_pas_opt_networks_uid_fk IS NOT NULL THEN
             OPEN get_pon_data(rec2.sva_pas_opt_networks_uid_fk);
             FETCH get_pon_data INTO v_chassis_no#, v_pon_no#, v_cmts;
             CLOSE get_pon_data;
         END IF; 
     
         v_rec.gdt_alpha24     := rec2.ARA_CODE;    -- area 
         v_rec.gdt_alpha25     := v_fbn_name;      --fiber node
         v_rec.gdt_alpha26     := v_cmts;          -- cmts
         v_rec.gdt_number5     := v_chassis_no#;
         v_rec.gdt_number6     := v_pon_no#;     
         
         IF v_mac_address IS NOT NULL THEN
            v_rec.gdt_alpha27    := FN_CHECK_BOX_MODEM_PROVISIONED(v_mac_address,p_svc_uid_pk,p_svo_uid_pk,null);   
            v_rec.gdt_alpha31 := 'Y';  --swap button display
         ELSE
            v_rec.gdt_alpha31 := 'N';  --swap button display   
         END IF;
         
         v_rec.gdt_alpha28 := 'N'; -- remove button display
         v_rec.gdt_alpha29 := 'N'; -- change button display
         v_rec.gdt_alpha30 := 'N'; -- hit and refresh button display

         -- start data for METRO-ETH service type  ------
         v_rec.gdt_alpha32 :=  rec2.point_id;    
         v_rec.gdt_alpha33 :=  rec2.svc_main_service_fl;  -- hub fl
         if rec2.sva_delivery_methods_uid_fk is not null then
           open  cur_delivery_methods(rec2.sva_delivery_methods_uid_fk);
           fetch cur_delivery_methods into  v_rec.gdt_alpha34 ;  -- delivery method
           close cur_delivery_methods ;
         end if;
         v_rec.gdt_alpha35 :=  rec2.sva_vlan;  -- vlan
         
         if rec2.sva_fac_equip_types_uid_fk is not null then
           open  cur_fac_equip_types(rec2.sva_fac_equip_types_uid_fk);
           fetch cur_fac_equip_types into  v_rec.gdt_alpha36 ;  -- fac equip types
           close cur_fac_equip_types ;
         end if;

         
     -- end fields for METRO-ETH service type  ------

         -- MCV 08/28/2012 -- for GPON
         OPEN get_sva_onu_data(rec2.sva_uid_pk);
         FETCH get_sva_onu_data into v_reg_id;
         CLOSE get_sva_onu_data;
         
         v_rec.gdt_number7 := v_reg_id;
         ----

         v_rec.gdt_number8     := rec2.sva_network_number;

         PIPE ROW (v_rec);
      END LOOP;

      CLOSE ASSIGNMENT_INFO_SVA;
END IF;

RETURN;

END FN_GET_SO_ASSIGNMENTS;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_EMTA_ASSIGNMENTS (P_SON_UID_PK IN NUMBER, P_SVA_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

CURSOR EMTA_INFO_SON IS
select MTP_LINE_NO#,
       MPT_CODE,
       MST_CODE,
       LRT_NO#,
       MEU_PROTECTOR,
       MEU_PEDESTAL,
       MTA_CMAC_ADDRESS,
       MTA_MTAMAC_ADDRESS,
       MEU_UID_PK,
       MEU_REMOVE_MTA_FL,
       MTA_UID_PK,
       MTY_CODE,
       'SO' TYPE
  from mta_boxes, mta_types, mta_ports, lead_routes, mta_port_types, mta_status, mta_equip_units, mta_so
 where MTO_SO_ASSGNMTS_UID_FK = p_son_uid_pk
   and MTP_UID_PK = MTO_MTA_PORTS_UID_FK
   and MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
   and MPT_UID_PK = MTP_MTA_PORT_TYPES_UID_FK
   and MST_UID_PK = MTP_MTA_STATUS_UID_FK
   and MTY_UID_PK = MEU_MTA_TYPES_UID_FK
   and LRT_UID_PK(+) = MEU_LEAD_ROUTES_UID_FK
   and MTA_UID_PK(+) = MEU_MTA_BOXES_UID_FK
UNION
select MTP_LINE_NO#,
       MPT_CODE,
       MST_CODE,
       LRT_NO#,
       MEU_PROTECTOR,
       MEU_PEDESTAL,
       MTA_CMAC_ADDRESS,
       MTA_MTAMAC_ADDRESS,
       MEU_UID_PK,
       MEU_REMOVE_MTA_FL,
       MTA_UID_PK,
       MTY_CODE,
       'SVC' TYPE
  from so_assgnmts, so, services, service_assgnmts, mta_boxes, mta_types, mta_ports, lead_routes, mta_port_types, mta_status, mta_equip_units, mta_services
 where SON_UID_PK = p_son_uid_pk
   and svo_uid_pk = son_so_uid_fk
   and svc_uid_pk = svo_services_uid_fk
   and svc_uid_pk = sva_services_uid_fk
   and sva_uid_pk = mss_service_assgnmts_uid_fk
   and MTP_UID_PK = MSS_MTA_PORTS_UID_FK
   and MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
   and MPT_UID_PK = MTP_MTA_PORT_TYPES_UID_FK
   and MST_UID_PK = MTP_MTA_STATUS_UID_FK
   and MTY_UID_PK = MEU_MTA_TYPES_UID_FK
   and LRT_UID_PK(+) = MEU_LEAD_ROUTES_UID_FK
   and MTA_UID_PK(+) = MEU_MTA_BOXES_UID_FK
   and SON_UID_PK not in (select MTO_SO_ASSGNMTS_UID_FK
                            from mta_so);

CURSOR EMTA_INFO_SVA IS
select MTP_LINE_NO#,
       MPT_CODE,
       MST_CODE,
       LRT_NO#,
       MEU_PROTECTOR,
       MEU_PEDESTAL,
       MTA_CMAC_ADDRESS,
       MTA_MTAMAC_ADDRESS,
       MEU_UID_PK,
       MEU_REMOVE_MTA_FL,
       MTY_CODE
  from mta_boxes, mta_types, mta_ports, lead_routes, mta_port_types, mta_status, mta_equip_units, mta_services
 where MSS_SERVICE_ASSGNMTS_UID_FK = p_sva_uid_pk
   and MTP_UID_PK = MSS_MTA_PORTS_UID_FK
   and MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
   and MPT_UID_PK = MTP_MTA_PORT_TYPES_UID_FK
   and MST_UID_PK = MTP_MTA_STATUS_UID_FK
   and MTY_UID_PK = MEU_MTA_TYPES_UID_FK
   and LRT_UID_PK(+) = MEU_LEAD_ROUTES_UID_FK
   and MTA_UID_PK(+) = MEU_MTA_BOXES_UID_FK;

CURSOR GET_SLO_SVC IS
  SELECT SSL_SERVICE_LOCATIONS_UID_FK
    FROM SERVICES, SERVICE_ASSGNMTS, SERV_SERV_LOCATIONS
   WHERE SVC_UID_PK = SVA_SERVICES_UID_FK
     AND SVC_UID_PK = SSL_SERVICES_UID_FK
     AND SSL_END_DATE IS NULL
     AND SVA_UID_PK = P_SVA_UID_PK;

CURSOR SO_TYPE IS
  SELECT SOT_SYSTEM_CODE, SSX_SERVICE_LOCATIONS_UID_FK
    FROM SO_TYPES, SO, SERV_SERV_LOC_SO, SO_ASSGNMTS
   WHERE SOT_UID_PK = SVO_SO_TYPES_UID_FK
     AND SVO_UID_PK = SON_SO_UID_FK
     AND SVO_UID_PK = SSX_SO_UID_FK
     AND SSX_END_DATE IS NULL
     AND SON_UID_PK = P_SON_UID_PK;

CURSOR SO_TYPE_MS IS
  SELECT SOT_SYSTEM_CODE, SSX_SERVICE_LOCATIONS_UID_FK
    FROM SO_TYPES, SO, SERV_SERV_LOC_SO, SO_ASSGNMTS
   WHERE SOT_UID_PK = SVO_SO_TYPES_UID_FK
     AND SVO_UID_PK = SON_SO_UID_FK
     AND SVO_UID_PK = SSX_SO_UID_FK
     AND SSX_END_DATE IS NOT NULL
     AND SON_UID_PK = P_SON_UID_PK;

CURSOR CHECK_FOR_CBM (P_SLO_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SERVICE_ASSGNMTS, CABLE_MODEMS, SERVICES
   WHERE SVA_CABLE_MODEMS_UID_FK = CBM_UID_PK
     AND SVC_UID_PK = SVA_SERVICES_UID_FK
     AND SVA_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
     AND SVC_UID_PK NOT IN (SELECT SVO_SERVICES_UID_FK
                              FROM SO, SO_TYPES, SO_STATUS
                             WHERE SVO_SERVICES_UID_FK = SVC_UID_PK
                               AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
                               AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                               AND SOT_SYSTEM_CODE IN ('MS','RS')
                               AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'))
  UNION
  SELECT 'Y'
    FROM MTA_SERVICES, SERVICES, SERV_SERV_LOCATIONS, SERVICE_ASSGNMTS
   WHERE SVC_UID_PK = SSL_SERVICES_UID_FK
     AND SSL_END_DATE IS NULL
     AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
     AND SVC_UID_PK = SVA_SERVICES_UID_FK
     AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
     AND SVC_UID_PK NOT IN (SELECT SVO_SERVICES_UID_FK
                              FROM SO, SO_TYPES, SO_STATUS
                             WHERE SVO_SERVICES_UID_FK = SVC_UID_PK
                               AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
                               AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                               AND SOT_SYSTEM_CODE IN ('MS','RS')
                               AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));

CURSOR CHECK_MTA_SERVICES(P_SLO_UID_PK IN NUMBER) IS
  SELECT MPT_CODE
    FROM SERVICES, SERV_SERV_LOCATIONS, SERVICE_ASSGNMTS, MTA_SERVICES, MTA_PORTS, MTA_PORT_TYPES
   WHERE SVC_UID_PK = SSL_SERVICES_UID_FK
     AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
     AND SSL_END_DATE IS NULL
     AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
     AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
     AND MPT_UID_PK = MTP_MTA_PORT_TYPES_UID_FK
     AND SVC_UID_PK = SVA_SERVICES_UID_FK;

CURSOR CHECK_MTA_SO IS
  SELECT 'X'
    FROM SO_ASSGNMTS, MTA_SO
   WHERE SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
     AND SON_UID_PK = P_SON_UID_PK;

CURSOR GET_SVT IS
  SELECT SVT_SYSTEM_CODE, STY_SYSTEM_CODE
    FROM SO_ASSGNMTS, SO, OFF_SERV_SUBS, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SUB_TYPES
   WHERE SVO_UID_PK = SON_SO_UID_FK
     AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
     AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
     AND OST_UID_PK = OSB_OFFICE_SERV_TYPES_UID_FK
     AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
     AND SON_UID_PK = P_SON_UID_PK;

CURSOR CHECK_FOR_CBM_ONLY (P_SLO_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SERVICE_ASSGNMTS, CABLE_MODEMS, SERVICES
   WHERE SVA_CABLE_MODEMS_UID_FK = CBM_UID_PK
     AND SVC_UID_PK = SVA_SERVICES_UID_FK
     AND SVA_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK;
     
CURSOR GET_SO_CREATE_DATE(P_SON_UID_PK IN NUMBER) IS
	SELECT SO.CREATED_DATE
		FROM SO, SO_ASSGNMTS
	WHERE SVO_UID_PK = SON_SO_UID_FK
	  AND SON_UID_PK = P_SON_UID_PK;
	
CURSOR GET_BOX_HIST_CREATE_DATE (P_MTA_UID_PK IN NUMBER) IS
	SELECT BOX_MODEM_HISTORY.CREATED_DATE
	FROM BOX_MODEM_HISTORY
	WHERE BMH_MTA_BOXES_UID_FK = P_MTA_UID_PK
	ORDER BY BOX_MODEM_HISTORY.CREATED_DATE DESC;
	

rec           EMTA_INFO_SON%rowtype;
rec2          EMTA_INFO_SVA%rowtype;
v_rec         generic_data_type;
V_SOT_CODE    VARCHAR2(20);
V_SVT_CODE    VARCHAR2(20);
V_STY_CODE    VARCHAR2(20);
V_MPT_CODE    VARCHAR2(20);
v_dummy       VARCHAR2(1);
V_SLO_UID_PK  NUMBER;
V_DATA_FL     VARCHAR2(1);
V_PHN_FL      VARCHAR2(1);
v_pipe_record_fl VARCHAR2(1);

V_SO_CREATE_DATE	DATE;

V_BOX_HIST_DATE		DATE;

V_IVL_UID_PK		NUMBER;

BEGIN

IF P_SON_UID_PK IS NOT NULL THEN

 OPEN EMTA_INFO_SON;
 LOOP
    FETCH EMTA_INFO_SON into rec;
    EXIT WHEN EMTA_INFO_SON%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_number1    := rec.MTP_LINE_NO#;       -- port line#
     v_rec.gdt_alpha1     := rec.MPT_CODE;           -- port
     v_rec.gdt_alpha2     := rec.MST_CODE;           -- mta status
     v_rec.gdt_alpha4     := rec.LRT_NO#;            -- lead route
     v_rec.gdt_alpha5     := rec.MEU_PROTECTOR;      -- Protector
     v_rec.gdt_alpha6     := rec.MEU_PEDESTAL;       -- Pedestal

     IF rec.MEU_REMOVE_MTA_FL = 'Y' THEN
        v_rec.gdt_alpha7     := NULL;   -- CMAC ADDRESS
        v_rec.gdt_alpha8     := NULL;   -- MTA MAC ADDRESS
     ELSE
        v_rec.gdt_alpha7     := rec.MTA_CMAC_ADDRESS;   -- CMAC ADDRESS
        v_rec.gdt_alpha8     := rec.MTA_MTAMAC_ADDRESS; -- MTA MAC ADDRESS
     END IF;

     v_rec.gdt_NUMBER2    := rec.MEU_UID_PK;         -- MTA EQUIP UNITS PK
     v_rec.gdt_ALPHA9     := REC.MTY_CODE;           -- MTA TYPE

     v_rec.gdt_ALPHA10 := 'N';
     v_rec.gdt_ALPHA11 := 'N';
     v_rec.gdt_ALPHA12 := 'N'; --ask if they want to remove old MTA
     v_pipe_record_fl := 'Y';
     
     OPEN SO_TYPE;
     FETCH SO_TYPE INTO V_SOT_CODE, V_SLO_UID_PK;
     IF SO_TYPE%FOUND THEN
        IF V_SOT_CODE IN ('CS','NS','RI') THEN
           OPEN CHECK_FOR_CBM(V_SLO_UID_PK);
           FETCH CHECK_FOR_CBM INTO V_DUMMY;
           IF CHECK_FOR_CBM%FOUND THEN
              v_rec.gdt_ALPHA10 := 'N';
              IF V_SOT_CODE = 'CS' THEN
                 v_rec.gdt_ALPHA12 := 'Y'; --ask if they want to remove old MTA
                 IF V_DUMMY = 'Y' THEN --MTA FOUND ON THE SERVICE TO OPEN UO TO ISSUE A SWAP ON A CS ORDER
                    v_rec.gdt_ALPHA11 := 'Y';
                 END IF;
              END IF;
           ELSE
              v_rec.gdt_ALPHA10 := 'Y';
           END IF;
           CLOSE CHECK_FOR_CBM;
        END IF;

        IF V_SOT_CODE = 'MS' THEN
           OPEN CHECK_FOR_CBM(V_SLO_UID_PK);
           FETCH CHECK_FOR_CBM INTO V_DUMMY;
           IF CHECK_FOR_CBM%FOUND THEN
              v_rec.gdt_ALPHA10 := 'N';
              v_rec.gdt_ALPHA11 := 'N';
           ELSE
              OPEN SO_TYPE_MS;  --OLD LOCATION
              FETCH SO_TYPE_MS INTO V_SOT_CODE, V_SLO_UID_PK;
              IF SO_TYPE_MS%FOUND THEN
                 OPEN CHECK_FOR_CBM_ONLY(V_SLO_UID_PK);
                 FETCH CHECK_FOR_CBM_ONLY INTO V_DUMMY;
                 IF CHECK_FOR_CBM_ONLY%FOUND THEN
                    v_rec.gdt_ALPHA10 := 'N';
                    v_rec.gdt_ALPHA11 := 'N';
                    v_rec.gdt_ALPHA12 := 'Y'; --ask if they want to remove old MTA
                 ELSE
                    open CHECK_MTA_SERVICES(v_slo_uid_pk);
                    fetch CHECK_MTA_SERVICES into V_MPT_CODE;
                    if CHECK_MTA_SERVICES%FOUND then
                       IF REC.TYPE = 'SO' THEN
                          v_rec.gdt_ALPHA10 := 'N';
                          v_rec.gdt_ALPHA11 := 'N';
                          v_rec.gdt_ALPHA12 := 'Y'; --ask if they want to remove old MTA
                       ELSE
                          OPEN CHECK_MTA_SO;
                          FETCH CHECK_MTA_SO INTO V_DUMMY;
                          IF CHECK_MTA_SO%FOUND THEN
                             v_pipe_record_fl := 'N';
                          ELSE
                             OPEN GET_SVT;
                             FETCH GET_SVT INTO V_SVT_CODE, V_STY_CODE;
                             IF GET_SVT%FOUND THEN
                                IF V_SVT_CODE IN ('PACKET CABLE','CABLE MODEM','RFOG') THEN --SO IS FOR CABLE MODEM SO WE CANNOT REMOVE AND NEED TO CHANGE MAC
                                   v_rec.gdt_ALPHA10 := 'N';
                                   v_rec.gdt_ALPHA11 := 'N';
                                   v_rec.gdt_ALPHA12 := 'N'; --ask if they want to remove old MTA
                                ELSE --change from MTA TO A SUB TYPE WHERE NO MODEM IS REQUIRED
                                   v_rec.gdt_ALPHA10 := 'Y';
                                   v_rec.gdt_ALPHA11 := 'N';
                                END IF;
                             ELSE
                                v_rec.gdt_ALPHA10 := 'N';
                                v_rec.gdt_ALPHA11 := 'N';
                             END IF;
                             CLOSE GET_SVT;
                          END IF;
                          CLOSE CHECK_MTA_SO;
                       END IF;
                    else
                       v_rec.gdt_ALPHA10 := 'Y';
                    end if;
                    close CHECK_MTA_SERVICES;
                 END IF;
                 CLOSE CHECK_FOR_CBM_ONLY;
              END IF;
              CLOSE SO_TYPE_MS;
           END IF;
           CLOSE CHECK_FOR_CBM;
        END IF;
     END IF;
     CLOSE SO_TYPE;

     OPEN GET_SVT;
     FETCH GET_SVT INTO V_SVT_CODE, V_STY_CODE;
     IF GET_SVT%FOUND THEN
        IF V_STY_CODE = 'PHN' THEN
           v_rec.gdt_ALPHA12 := 'N';
        END IF;
     END IF;
     CLOSE GET_SVT;
     
     ---RMC - HD 133404 08/28/2013 - Break/Fix - Identify and correct Issue with NS orders with MTA already assigned.
     ---			Added the below code to check and Null out the CMAC and MTAMAC fields on the SOFSOWRL MTA assignments 
     ---      page.
		 IF V_SOT_CODE IN ('NS') AND
		 		rec.MTA_CMAC_ADDRESS IS NOT NULL THEN
		 		OPEN GET_SO_CREATE_DATE(P_SON_UID_PK);
		 		FETCH GET_SO_CREATE_DATE INTO V_SO_CREATE_DATE;
		 		CLOSE GET_SO_CREATE_DATE;
		 		
		 		OPEN GET_BOX_HIST_CREATE_DATE(REC.MTA_UID_PK);
		 		FETCH GET_BOX_HIST_CREATE_DATE INTO V_BOX_HIST_DATE;
		 		CLOSE GET_BOX_HIST_CREATE_DATE;
		 		
		 		IF V_SO_CREATE_DATE > V_BOX_HIST_DATE THEN
		 			 v_rec.gdt_alpha7     := NULL; -- CMAC ADDRESS
        	 v_rec.gdt_alpha8     := NULL; -- MTA MAC ADDRESS
        END IF;
     
     END IF;
		 			
     v_rec.gdt_ALPHA13    := 'N';  --SHOW SWAP LINK FOR A TROUBLE TICKET
     v_rec.gdt_ALPHA14    := 'N';  --SHOW CHANGE PORT LINK FOR A TROUBLE TICKET

     IF V_PIPE_RECORD_FL = 'Y' OR rec.TYPE = 'SO' THEN
        PIPE ROW (v_rec);
     END IF;
  END LOOP;

  CLOSE EMTA_INFO_SON;

ELSE

 OPEN EMTA_INFO_SVA;
 LOOP
    FETCH EMTA_INFO_SVA into rec2;
    EXIT WHEN EMTA_INFO_SVA%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_number1    := NULL;       -- port line#
     v_rec.gdt_alpha2     := rec2.MST_CODE;           -- mta status
     v_rec.gdt_alpha4     := rec2.LRT_NO#;            -- lead route
     v_rec.gdt_alpha5     := rec2.MEU_PROTECTOR;      -- Protector
     v_rec.gdt_alpha6     := rec2.MEU_PEDESTAL;       -- Pedestal

     IF rec.MEU_REMOVE_MTA_FL = 'Y' THEN
        v_rec.gdt_alpha7     := NULL;   -- CMAC ADDRESS
        v_rec.gdt_alpha8     := NULL;   -- MTA MAC ADDRESS
     ELSE
        v_rec.gdt_alpha7     := rec2.MTA_CMAC_ADDRESS;   -- CMAC ADDRESS
        v_rec.gdt_alpha8     := rec2.MTA_MTAMAC_ADDRESS; -- MTA MAC ADDRESS
     END IF;

     v_rec.gdt_NUMBER2    := rec2.MEU_UID_PK;         -- MTA EQUIP UNITS PK

     V_DATA_FL := 'N';
     V_PHN_FL  := 'N';
     OPEN GET_SLO_SVC;
     FETCH GET_SLO_SVC INTO V_SLO_UID_PK;
     IF GET_SLO_SVC%FOUND THEN
        FOR MTA_REC IN CHECK_MTA_SERVICES(v_slo_uid_pk) LOOP
           IF MTA_REC.MPT_CODE = 'TEL' THEN
              V_PHN_FL := 'Y';
           ELSIF MTA_REC.MPT_CODE = 'DATA' THEN
              V_DATA_FL := 'Y';
           END IF;
        END LOOP;
     END IF;
     CLOSE GET_SLO_SVC;

     IF V_PHN_FL = 'Y' AND V_DATA_FL = 'Y' THEN
        v_rec.gdt_alpha1 := 'DATA/PHN';
     ELSE
        v_rec.gdt_alpha1 := REC2.MPT_CODE; --PORT TYPE
     END IF;

     v_rec.gdt_ALPHA9     := REC2.MTY_CODE;   --MTA TYPE
     v_rec.gdt_ALPHA10    := 'N';   --SHOW REMOVE BUTTON ON IWP
     v_rec.gdt_ALPHA11    := 'N';
     v_rec.gdt_ALPHA12    := 'N';
     
     IF v_rec.gdt_alpha8 IS NOT NULL THEN --MAC ADDRESS FOUND THEN
        v_rec.gdt_ALPHA13    := 'Y';  --SHOW SWAP LINK FOR A TROUBLE TICKET
        IF V_PHN_FL = 'N' THEN
           v_rec.gdt_ALPHA14    := 'N';  --SHOW CHANGE PORT LINK FOR A TROUBLE TICKET
        ELSE
           v_rec.gdt_ALPHA14    := 'Y';  --SHOW CHANGE PORT LINK FOR A TROUBLE TICKET
        END IF;
     ELSE
        v_rec.gdt_ALPHA13    := 'N';  --SHOW SWAP LINK FOR A TROUBLE TICKET
        v_rec.gdt_ALPHA14    := 'N';  --SHOW CHANGE PORT LINK FOR A TROUBLE TICKET
     END IF;

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE EMTA_INFO_SVA;

END IF;

RETURN;

END FN_EMTA_ASSIGNMENTS;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_GET_PAIR_ASSIGNMENTS (P_SON_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

CURSOR PAIR_INFO IS
select prs_no#,
       prs_txrx,
       (lrt_no# || ' / ' || prs_pedestal ||'.'|| prs_protector) route,
       sai_no#,
       prs_default_dedication,
       prs_primary_fl,
       decode(prs_loading,null,'N','Y') loading_fl,
       prs_hold_fl,
       pro_origin
  from pairs,
       pair_origins,
       pairs_so,
       so_assgnmts,
       sai,
       lead_routes
 where son_uid_pk = p_son_uid_pk
   and pas_so_assgnmts_uid_fk = son_uid_pk
   AND prs_uid_pk = pas_pairs_uid_fk
   and PRO_UID_PK(+) = PRS_PAIR_ORIGINS_UID_FK
   and prs_sai_uid_fk = sai_uid_pk(+)
   and prs_lead_routes_uid_fk = lrt_uid_pk(+)
UNION
select prs_no#,
       prs_txrx,
       (lrt_no# || ' / ' || prs_pedestal ||'.'|| prs_protector) route,
       sai_no#,
       prs_default_dedication,
       prs_primary_fl,
       decode(prs_loading,null,'N','Y') loading_fl,
       prs_hold_fl,
       pro_origin
  from pairs,
       pair_origins,
       service_assgnmts,
       pair_services,
       sai,
       lead_routes
 where sva_uid_pk = p_son_uid_pk
   and PSV_SERVICE_ASSGNMTS_UID_FK = sva_uid_pk
   AND prs_uid_pk = PSV_PAIRS_UID_FK
   and PRO_UID_PK(+) = PRS_PAIR_ORIGINS_UID_FK
   and prs_sai_uid_fk = sai_uid_pk(+)
   and prs_lead_routes_uid_fk = lrt_uid_pk(+);

rec     PAIR_INFO%rowtype;
v_rec   generic_data_type;

BEGIN

 OPEN PAIR_INFO;
 LOOP
    FETCH PAIR_INFO into rec;
    EXIT WHEN PAIR_INFO%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1     := rec.prs_no#;                -- pair#
     v_rec.gdt_alpha2     := rec.prs_txrx;               -- TX/RX
     v_rec.gdt_alpha3     := rec.route;                  -- lead route/pedestal/protector
     v_rec.gdt_alpha4     := rec.sai_no#;                -- sai#
     v_rec.gdt_alpha5     := rec.prs_default_dedication; -- default dedication
     v_rec.gdt_alpha6     := rec.prs_primary_fl;         -- Primary flag
     v_rec.gdt_alpha7     := rec.loading_fl;             -- loading flag
     v_rec.gdt_alpha8     := rec.prs_hold_fl;            -- hold flag
     v_rec.gdt_alpha9     := rec.pro_origin;             -- pair origin

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE PAIR_INFO;

RETURN;

END FN_GET_PAIR_ASSIGNMENTS;


/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_FTTH_ASSIGNMENTS (P_SON_UID_PK IN NUMBER, P_SVA_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

CURSOR FTTH_INFO_SON IS
      SELECT cli_code,
           cha_chassis_no#,
           pon_no#,
           onu_no#,
           otp_code,
           onp_expansion_card,
           onp_line_no#,
           ptt_code,
           null ds0_line_no#,
           lrt_no#,
           onu_pedestal,
           onu_protector,
           onu_range_in_meters,
           OTP_GEN_REG_ID_FL,
           ONU_UID_PK,
           onu_registration_id
       FROM lead_routes, cllis, chassis,onu_types, port_types, pas_opt_networks, out_net_units, onu_ports, ftth_so
      WHERE cli_uid_pk = cha_cllis_uid_fk
       AND cha_uid_pk = pon_chassis_uid_fk
       AND pon_uid_pk = onu_pas_opt_networks_uid_fk
       AND otp_uid_pk = onu_onu_types_uid_fk
       and onu_uid_pk = onp_out_net_units_uid_fk
       AND onp_port_types_uid_fk = ptt_uid_pk
       AND lrt_uid_pk (+) = onu_lead_routes_uid_fk
       AND fso_onu_ports_uid_fk = onp_uid_pk
       AND fso_so_assgnmts_uid_fk = p_son_uid_pk
   UNION
           -- DS0 ports active at location
    SELECT cli_code,
           cha_chassis_no#,
           pon_no#,
           onu_no#,
           otp_code,
           onp_expansion_card,
           onp_line_no#,
           ptt_code,
           ds0_line_no#,
           lrt_no#,
           onu_pedestal,
           onu_protector,
           onu_range_in_meters,
           OTP_GEN_REG_ID_FL,
           ONU_UID_PK,
           onu_registration_id
       FROM lead_routes, cllis, chassis,onu_types, port_types, pas_opt_networks, out_net_units, onu_ports, ds0_ports, ftth_so
      WHERE cli_uid_pk = cha_cllis_uid_fk
       AND cha_uid_pk = pon_chassis_uid_fk
       AND pon_uid_pk = onu_pas_opt_networks_uid_fk
       AND otp_uid_pk = onu_onu_types_uid_fk
       and onu_uid_pk = onp_out_net_units_uid_fk
       AND onp_port_types_uid_fk = ptt_uid_pk
       AND lrt_uid_pk (+) = onu_lead_routes_uid_fk
       AND ds0_onu_ports_uid_fk = onp_uid_pk
       AND fso_ds0_ports_uid_fk = ds0_uid_pk
       AND fso_so_assgnmts_uid_fk = p_son_uid_pk   ;       
 
CURSOR FTTH_INFO_SVA IS
      SELECT cli_code,
           cha_chassis_no#,
           pon_no#,
           onu_no#,
           otp_code,
           onp_expansion_card,
           onp_line_no#,
           ptt_code,
           null ds0_line_no#,
           lrt_no#,
           onu_pedestal,
           onu_protector,
           onu_range_in_meters,
           OTP_GEN_REG_ID_FL,
           ONU_UID_PK,
           onu_registration_id
       FROM lead_routes, cllis, chassis,onu_types, port_types, pas_opt_networks, out_net_units, onu_ports, ftth_services
      WHERE cli_uid_pk = cha_cllis_uid_fk
       AND cha_uid_pk = pon_chassis_uid_fk
       AND pon_uid_pk = onu_pas_opt_networks_uid_fk
       AND otp_uid_pk = onu_onu_types_uid_fk
       and onu_uid_pk = onp_out_net_units_uid_fk
       AND onp_port_types_uid_fk = ptt_uid_pk
       AND lrt_uid_pk (+) = onu_lead_routes_uid_fk
       AND fts_onu_ports_uid_fk = onp_uid_pk
       AND fts_service_assgnmts_uid_fk = p_sva_uid_pk
   UNION
           -- DS0 ports active at location
    SELECT cli_code,
           cha_chassis_no#,
           pon_no#,
           onu_no#,
           otp_code,
           onp_expansion_card,
           onp_line_no#,
           ptt_code,
           ds0_line_no#,
           lrt_no#,
           onu_pedestal,
           onu_protector,
           onu_range_in_meters,
           OTP_GEN_REG_ID_FL,
           ONU_UID_PK,
           onu_registration_id
       FROM lead_routes, cllis, chassis,onu_types, port_types, pas_opt_networks, out_net_units, onu_ports, ds0_ports, ftth_services
      WHERE cli_uid_pk = cha_cllis_uid_fk
       AND cha_uid_pk = pon_chassis_uid_fk
       AND pon_uid_pk = onu_pas_opt_networks_uid_fk
       AND otp_uid_pk = onu_onu_types_uid_fk
       and onu_uid_pk = onp_out_net_units_uid_fk
       AND onp_port_types_uid_fk = ptt_uid_pk
       AND lrt_uid_pk (+) = onu_lead_routes_uid_fk
       AND ds0_onu_ports_uid_fk = onp_uid_pk
       AND fts_ds0_ports_uid_fk = ds0_uid_pk
       AND fts_service_assgnmts_uid_fk = p_sva_uid_pk;
       
CURSOR GET_BOX(P_ONU_UID_PK IN NUMBER) IS
  SELECT ONB_SERIAL_NUMBER
    FROM OUT_NET_UNITS, ONT_BOXES
   WHERE ONB_UID_PK = ONU_ONT_BOXES_UID_FK
     AND ONU_UID_PK = P_ONU_UID_PK;

rec           FTTH_INFO_SON%rowtype;
rec2          FTTH_INFO_SVA%rowtype;
v_rec         generic_data_type;
v_dummy       VARCHAR2(1);
V_MAC_ADDRESS VARCHAR2(30);
V_ONT_FL      VARCHAR2(1);


BEGIN

IF P_SON_UID_PK IS NOT NULL THEN

 OPEN FTTH_INFO_SON;
 LOOP
    FETCH FTTH_INFO_SON into rec;
    EXIT WHEN FTTH_INFO_SON%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);


     v_rec.gdt_alpha1     := rec.CLI_CODE;           --clli
     v_rec.gdt_number1    := rec.CHA_CHASSIS_NO#;    --chassis
     v_rec.gdt_number2    := rec.PON_NO#;            --PON
     v_rec.gdt_number3    := rec.ONU_NO#;            --ONU
     v_rec.gdt_alpha2     := rec.otp_code;           --ONU type
     v_rec.gdt_number4    := rec.onp_expansion_card; --expansion card
     v_rec.gdt_number5    := rec.onp_line_no#;       --onu port
     v_rec.gdt_alpha3     := rec.ptt_code;           --port type
     v_rec.gdt_number6    := rec.ds0_line_no#;       --ds0 port
     v_rec.gdt_alpha4     := rec.lrt_no#;            --lead route
     v_rec.gdt_alpha5     := rec.onu_protector;      --Protector
     v_rec.gdt_alpha6     := rec.onu_pedestal;       --Pedestal
     v_rec.gdt_number7    := rec.onu_range_in_meters;--range
     IF REC.onu_registration_id IS NOT NULL THEN
        V_ONT_FL := 'Y';
     ELSE
        V_ONT_FL := 'N';
     END IF;
     v_rec.gdt_alpha7     := V_ONT_FL;
     
     
     OPEN GET_BOX(REC.ONU_UID_PK);
     FETCH GET_BOX INTO V_MAC_ADDRESS;
     IF GET_BOX%FOUND THEN
        v_rec.gdt_alpha8 := V_MAC_ADDRESS;
     END IF;
     CLOSE GET_BOX;

     PIPE ROW (v_rec);
 
  END LOOP;

  CLOSE FTTH_INFO_SON;

ELSE

 OPEN FTTH_INFO_SVA;
 LOOP
    FETCH FTTH_INFO_SVA into rec2;
    EXIT WHEN FTTH_INFO_SVA%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1      := rec2.CLI_CODE;            --clli
     v_rec.gdt_number1     := rec2.CHA_CHASSIS_NO#;     --chassis
     v_rec.gdt_number2     := rec2.PON_NO#;             --PON
     v_rec.gdt_number3     := rec2.ONU_NO#;             --ONU
     v_rec.gdt_alpha2      := rec2.otp_code;            --ONU type
     v_rec.gdt_number4     := rec2.onp_expansion_card;  --expansion card
     v_rec.gdt_number5     := rec2.onp_line_no#;        --onu port
     v_rec.gdt_alpha3      := rec2.ptt_code;            --port type
     v_rec.gdt_number6     := rec2.ds0_line_no#;        --ds0 port
     v_rec.gdt_alpha4      := rec2.lrt_no#;             --lead route
     v_rec.gdt_alpha5      := rec2.onu_protector;       --Protector
     v_rec.gdt_alpha6      := rec2.onu_pedestal;        --Pedestal
     v_rec.gdt_number7     := rec2.onu_range_in_meters; --range
     IF REC2.onu_registration_id IS NOT NULL THEN
        V_ONT_FL := 'Y';
     ELSE
        V_ONT_FL := 'N';
     END IF;
     v_rec.gdt_alpha7     := V_ONT_FL;

     OPEN GET_BOX(REC2.ONU_UID_PK);
     FETCH GET_BOX INTO V_MAC_ADDRESS;
     IF GET_BOX%FOUND THEN
        v_rec.gdt_alpha8 := V_MAC_ADDRESS;
     END IF;
     CLOSE GET_BOX;
     
     PIPE ROW (v_rec);
  END LOOP;

  CLOSE FTTH_INFO_SVA;

END IF;

RETURN;

END FN_FTTH_ASSIGNMENTS;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_UPDATE_HSD_BONDED (P_SON_UID_PK IN NUMBER, P_HSD_FL VARCHAR, P_BONDED_FL VARCHAR)

RETURN VARCHAR

IS

 CURSOR get_so_assgnmt_info is
   select SON_DSLAM_PORTS_UID_FK, dsp_vpi, son_so_uid_fk, son_line#, slm_uid_pk, dcd_uid_pk,
          son_service_locations_uid_fk, svc_accounts_uid_fk
     from services, so, so_assgnmts, dslam_ports, dslams, dslam_cards
    where svc_uid_pk = svo_services_uid_fk
      and svo_uid_pk = son_so_uid_fk
      and slm_uid_pk = dcd_dslams_uid_fk
      and dcd_uid_pk = dsp_dslam_cards_uid_fk
      and dsp_uid_pk = son_dslam_ports_uid_fk
      and son_uid_pk = P_SON_UID_PK;

 CURSOR get_other_vpi(cp_svo_uid_pk number, cp_line number) is
  select slm_uid_pk, dcd_uid_pk, dsp_vpi, son_hsd_fl
    from dslams, dslam_cards, dslam_ports, so_assgnmts
   where slm_uid_pk = dcd_dslams_uid_fk
     AND dcd_uid_pk = dsp_dslam_cards_uid_fk
     and dsp_uid_pk = son_dslam_ports_uid_fk
     and son_line# =decode(mod(cp_line,2),0, cp_line-1, cp_line+1)
     and son_so_uid_fk = cp_svo_uid_pk;
     
 CURSOR get_ctv_so(cp_acc_uid_pk number, cp_slo_uid_pk number, cp_svo_uid_pk number) IS 
  select son_uid_pk, cts_bonded_networks, cts_unbonded_networks, son_network_number, son_bonded_fl, son_hsd_fl,
         son_Line#, son_opx
    from services, so, so_assgnmts, catv_so, off_serv_subs, serv_sub_types
   where cts_so_uid_fk = svo_uid_pk
     and cts_mmr_fl = 'Y'
     and cts_conversion_fl='Y'
     and son_so_uid_fk = svo_uid_pk
     and svo_services_uid_fk = svc_uid_pk
     and svc_accounts_uid_fk = cp_acc_uid_pk
     and svo_uid_pk != cp_svo_uid_pk
     and son_dslam_ports_uid_fk is not null
     and son_service_locations_uid_fk in
                   (select s2.slo_uid_pk
                   from service_locations s1, service_locations s2
                  where s1.slo_uid_pk = cp_slo_uid_pk
                    and s1.slo_municipalities_uid_fk = s2.slo_municipalities_uid_fk
                    and s1.slo_streets_uid_fk = s2.slo_streets_uid_fk
                    and ((s1.slo_street_nums_uid_fk = s2.slo_street_nums_uid_fk and s1.slo_street_nums_uid_fk is not null)
                     or (s2.slo_street_nums_uid_fk is null and s1.slo_street_nums_uid_fk is null))
                    and ((s1.slo_buildings_uid_fk = s2.slo_buildings_uid_fk and s1.slo_buildings_uid_fk is not null)
                     or (s2.slo_buildings_uid_fk is null and s1.slo_buildings_uid_fk is null))
                    and ((s1.slo_building_units_uid_fk = s2.slo_building_units_uid_fk and s1.slo_building_units_uid_fk is not null)
                     or (s2.slo_building_units_uid_fk is null and s1.slo_building_units_uid_fk is null)))
     and SVO_SO_STATUS_UID_FK not in (code_pkg.get_pk('SO_STATUS','VOID'), code_pkg.get_pk('SO_STATUS','CLOSED'))
     and svo_off_serv_subs_uid_fk = osb_uid_pk
     and osb_serv_sub_types_uid_fk = svt_uid_pk
     and svt_system_code in ('ADSL','VDSL')
   ORDER BY son_hsd_fl desc, son_line#, son_opx;
        

     v_vpi            varchar2(5);
     v_min_range      number;
     v_max_range      number;
     v_dcd_uid_pk     number;
     v_dcd_uid_pk_cur number;
     v_hsd_fl         varchar2(1);
     v_dsd_uid_pk     number;
     v_dsp_vpi        varchar2(20);
     v_slm_uid_pk     number;
     v_slm_uid_pk_cur number;
     v_svo_uid_pk     number;
     v_son_line#      number;
     v_slo_uid_pk     number;
     v_acc_uid_pk     number;
     v_network_number number;
     v_net_for_update number;
     v_bonded_fl      varchar2(1);
     v_rec_updated    number;
     v_rec_to_update  number;
     
     
     v_return_msg  		VARCHAR2(4000);
		 
	 V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_UPDATE_HSD_BONDED';

BEGIN

open get_so_assgnmt_info;
fetch get_so_assgnmt_info into v_dsd_uid_pk, v_dsp_vpi, v_svo_uid_pk,
                                 v_son_line#, v_slm_uid_pk_cur, v_dcd_uid_pk_cur,
                                 v_slo_uid_pk, v_acc_uid_pk;
close get_so_assgnmt_info;

IF P_BONDED_FL = 'Y' THEN

    if v_dsd_uid_pk is not null then

          if to_number(v_dsp_vpi) between 1 and 6 then
              v_min_range := 1;
              v_max_range := 6;
          elsif to_number(v_dsp_vpi) between 7 and 12 then
              v_min_range := 7;
              v_max_range := 12;
          elsif to_number(v_dsp_vpi) between 13 and 18 then
              v_min_range := 13;
              v_max_range := 18;
          elsif to_number(v_dsp_vpi) between 19 and 24 then
              v_min_range :=19;
              v_max_range := 24;
          elsif to_number(v_dsp_vpi) between 25 and 30 then
              v_min_range := 25;
              v_max_range := 30;
          elsif to_number(v_dsp_vpi) between 31 and 36 then
              v_min_range := 31;
              v_max_range := 36;
          elsif to_number(v_dsp_vpi) between 37 and 42 then
              v_min_range := 37;
              v_max_range := 42;
          elsif to_number(v_dsp_vpi) between 43 and 48 then
              v_min_range := 43;
              v_max_range := 48;
          end if;
          --dbms_output.put_line(v_slm_uid_pk_cur||'-'||v_dcd_uid_pk_cur||'-'||v_dsp_vpi||'-'||v_min_range||'-'||v_min_range);
          --dbms_output.put_line(v_slm_uid_pk||'-'||v_dcd_uid_pk||'-'||v_vpi);
            -- select the DSLAM on the consecutive assignment record
            open get_other_vpi(v_svo_uid_pk, v_son_line#);
            fetch get_other_vpi into v_slm_uid_pk, v_dcd_uid_pk, v_vpi, v_hsd_fl;
            close get_other_vpi;
            IF NOT (v_slm_uid_pk = v_slm_uid_pk_cur
                      AND v_dcd_uid_pk = v_dcd_uid_pk_cur
                      AND v_vpi in (to_number(v_dsp_vpi)+1, to_number(v_dsp_vpi)-1)
                      AND v_vpi between v_min_range and v_max_range) THEN
                  RETURN 'DSLAM ports need to be consecutive and in the same Shelf, card and range for bonded assignments. Please call plant to correct 815-1653';
            			v_return_msg := 'DSLAM ports need to be consecutive and in the same Shelf, card and range for bonded assignments. Please call plant to correct 815-1653';
									IF V_SVO_UID_PK IS NOT NULL THEN
										 IF v_return_msg IS NOT NULL THEN
												PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
										 END IF;
		 	  	 				END IF;
            END IF;

    end if;

END IF;

IF V_DSD_UID_PK IS NOT NULL THEN

   UPDATE SO_ASSGNMTS
      SET SON_BONDED_FL = P_BONDED_FL,
          SON_HSD_FL = P_HSD_FL
    WHERE SON_DSLAM_PORTS_UID_FK = V_DSD_UID_PK
      AND SON_SO_UID_FK in (SELECT SVO_UID_PK
                              FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                             WHERE OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                               AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                               AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                               AND SVT_SYSTEM_CODE IN ('ADSL','VDSL')
                               AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));

    -- MMR 01/16/13 MCV update the other CTV SO with netwrok info
    v_rec_updated := 0;
    v_rec_to_update :=1;
    v_net_for_update := 1;
    FOR c in get_ctv_so(v_acc_uid_pk, v_slo_uid_pk, v_svo_uid_pk) LOOP
      dbms_output.put_line(c.son_uid_pk||c.son_hsd_fl||c.son_network_number);
      IF c.son_hsd_fl='Y' THEN
      
         IF c.son_network_number IS NOT NULL THEN
           v_net_for_update := c.son_network_number;
           v_bonded_fl := c.son_bonded_fl;
           if v_bonded_fl='Y' then
            v_rec_to_update := 2;
           else
            v_rec_to_update := 1;
           end if;
           update so_assgnmts
              set son_network_number=null
            where son_uid_pk = c.son_uid_pk;
         END IF;
      ELSE -- hsd flag N
         IF c.son_network_number IS NULL AND c.son_bonded_fl=NVL(v_bonded_fl,c.son_bonded_fl) AND v_net_for_update IS NOT NULL  
            AND v_rec_updated < v_rec_to_update THEN
            update so_assgnmts
               set son_network_number=v_net_for_update
             where son_uid_pk = c.son_uid_pk;
            v_rec_updated := v_rec_updated +1;
         ELSIF c.son_network_number IS NOT NULL THEN
            v_net_for_update := c.son_network_number;
            v_bonded_fl := c.son_bonded_fl;
            v_rec_updated := v_rec_updated +1;
            if v_bonded_fl='Y' then
              v_rec_to_update := 2;
            else
              v_rec_to_update := 1;
            end if;
         END IF;
      END IF;
      
    
    END LOOP;
ELSE

   UPDATE SO_ASSGNMTS
      SET SON_BONDED_FL = P_BONDED_FL,
          SON_HSD_FL = P_HSD_FL
    WHERE SON_UID_PK = P_SON_UID_PK;

END IF;




COMMIT;

RETURN NULL;

END FN_UPDATE_HSD_BONDED;


/*-------------------------------------------------------------------------------------------------------------*/
-- to add and provision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
FUNCTION FN_ADD_EMTA(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_SON_UID_PK IN NUMBER, P_MEU_UID_PK IN NUMBER, P_MTA_MAC IN VARCHAR, P_CMAC_MAC IN VARCHAR, P_EMTA_TYPE IN VARCHAR, P_PORT_LINE# IN NUMBER, P_REMOVE_OLD_FL IN VARCHAR DEFAULT 'N', P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S')
  RETURN VARCHAR IS
  

  CURSOR GET_TECH_LOCATION IS
   SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
     FROM TECH_EMP_LOCATIONS, EMPLOYEES
    WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
      AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
      AND TEO_END_DATE IS NULL;

  CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
    SELECT IVL_UID_PK
      FROM INVENTORY_LOCATIONS
     WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

  CURSOR MTA_ALREADY_ON(P_MTA_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SO_ASSGNMTS, MTA_SO, MTA_PORTS, MTA_EQUIP_UNITS
   WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
     AND MTP_UID_PK = MTO_MTA_PORTS_UID_FK
     AND SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
     AND MEU_MTA_BOXES_UID_FK = P_MTA_UID_PK
     AND SON_SO_UID_FK = P_SVO_UID_PK
     AND MEU_REMOVE_MTA_FL = 'N'
  UNION
  SELECT 'X'
    FROM SO, SERVICES, SERVICE_ASSGNMTS, MTA_SERVICES, MTA_PORTS, MTA_EQUIP_UNITS
   WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
     AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
     AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
     AND SVC_UID_PK = SVO_SERVICES_UID_FK
     AND SVC_UID_PK = SVA_SERVICES_UID_FK
     AND MEU_MTA_BOXES_UID_FK = P_MTA_UID_PK
     AND SVO_UID_PK = P_SVO_UID_PK
     AND MEU_REMOVE_MTA_FL = 'N';

  CURSOR MTA_SO_PK IS
    SELECT MTO_UID_PK
      FROM SO_ASSGNMTS, MTA_SO
     WHERE SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
       AND SON_UID_PK = P_SON_UID_PK;

  CURSOR MTA_ACTIVE_ACCOUNT_CHECK(P_MTA_UID_PK IN NUMBER, P_SLO_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SERVICES, SERV_SERV_LOCATIONS, SERVICE_ASSGNMTS, MTA_SERVICES, MTA_PORTS, MTA_EQUIP_UNITS
   WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
     AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
     AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
     AND SVC_UID_PK = SVA_SERVICES_UID_FK
     AND SVC_UID_PK = SSL_SERVICES_UID_FK
     AND SSL_SERVICE_LOCATIONS_UID_FK != P_SLO_UID_PK
     AND SSL_END_DATE IS NULL
     AND SVC_END_DATE IS NULL
     AND MEU_MTA_BOXES_UID_FK = P_MTA_UID_PK
     AND MEU_REMOVE_MTA_FL = 'N';

  CURSOR GET_PORT(P_PORT_TYPE IN VARCHAR) IS
  SELECT MTP_UID_PK
    FROM MTA_PORTS, MTA_EQUIP_UNITS, MTA_PORT_TYPES
   WHERE MEU_UID_PK = P_MEU_UID_PK
     AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
     AND MTP_LINE_NO# = P_PORT_LINE#
     AND MPT_UID_PK = MTP_MTA_PORT_TYPES_UID_FK
     AND MPT_SYSTEM_CODE = P_PORT_TYPE;

  CURSOR GET_CUR_PORT IS
    SELECT MTP_LINE_NO#
      FROM SO_ASSGNMTS, MTA_SO, MTA_PORTS
     WHERE SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
       AND MTP_UID_PK = MTO_MTA_PORTS_UID_FK
       AND SON_UID_PK = P_SON_UID_PK;

  CURSOR GET_SWT_EQUIPMENT(P_SEQ_CODE IN VARCHAR) IS
    SELECT SEQ_UID_PK
      FROM SWT_EQUIPMENT
     WHERE SEQ_SYSTEM_CODE = P_SEQ_CODE;

  CURSOR GET_MEU_TYPE IS
	  SELECT MTY_SYSTEM_CODE, MTY_UID_PK ---,MEU_MTA_TYPES_UID_FK - HD 99905 RMC 03/09/2011
	    FROM MTA_EQUIP_UNITS, MTA_TYPES
	   WHERE MTY_UID_PK = MEU_MTA_TYPES_UID_FK
     AND MEU_UID_PK = P_MEU_UID_PK;

  CURSOR GET_MTA_TYPE(P_MTA_UID_PK IN NUMBER) IS
	  SELECT MTY_SYSTEM_CODE, MTY_UID_PK ---,MTA_MTA_TYPES_UID_FK - HD 99905 RMC 03/09/2011
	    FROM MTA_BOXES, MTA_TYPES
	   WHERE MTY_UID_PK = MTA_MTA_TYPES_UID_FK
     AND MTA_UID_PK = P_MTA_UID_PK;


  CURSOR OSSGATE_CHECK1(P_DATE IN VARCHAR) IS
  select 'X'
  from swt_logs, swt_equipment
  where sls_so_uid_fk = P_SVO_UID_PK
    and sls_success_fl = 'Y'
    and SLS_SWT_EQUIPMENT_UID_FK = seq_uid_pk
    and SEQ_SYSTEM_CODE = 'OSSGATE'
    AND substr (SLS_RESPONSE,1, 11) = 'XML-SUCCESS'
    and swt_logs.created_date > sysdate-5/1440
    and swt_logs.created_date >= to_date(P_DATE,'MM-DD-YYYY HH:MI:SS AM');

  CURSOR OSSGATE_CHECK2(P_DATE IN VARCHAR) IS
  select 'X'
  from swt_logs, swt_equipment
  where sls_so_uid_fk = P_SVO_UID_PK
    and sls_success_fl = 'Y'
    and SLS_SWT_EQUIPMENT_UID_FK = seq_uid_pk
    and SEQ_SYSTEM_CODE = 'OSSGATE'
    AND SLS_COMMAND_SENT like '%NEW $%'
    and swt_logs.created_date > sysdate-5/1440
    and swt_logs.created_date >= to_date(P_DATE,'MM-DD-YYYY HH:MI:SS AM');

  CURSOR OSSGATE_CHECK3(P_DATE IN VARCHAR) IS
  select 'X'
  from swt_logs, swt_equipment
  where sls_so_uid_fk = P_SVO_UID_PK
    and sls_success_fl = 'N'
    and SLS_SWT_EQUIPMENT_UID_FK = seq_uid_pk
    and SEQ_SYSTEM_CODE = 'OSSGATE'
    AND substr (SLS_RESPONSE,1, 10) = 'CI-SUCCESS'
    and swt_logs.created_date > sysdate-5/1440
    and swt_logs.created_date >= to_date(P_DATE,'MM-DD-YYYY HH:MI:SS AM');

  CURSOR CHECK_EXIST_CANDIDATE(P_SVO_UID_PK IN NUMBER, P_SEQ_CODE IN VARCHAR) IS
   SELECT TO_CHAR(SO_CANDIDATES.MODIFIED_DATE,'MM-DD-YYYY HH:MI:SS AM')
     FROM SO_CANDIDATES, SWT_EQUIPMENT
    WHERE SOC_SO_UID_FK = P_SVO_UID_PK
      AND SEQ_UID_PK = SOC_SWT_EQUIPMENT_UID_FK
      AND SOC_ACTION_FL = 'A'
      AND SEQ_SYSTEM_CODE = P_SEQ_CODE;

  CURSOR GET_EMPLOYEE IS
   SELECT EMP_FNAME||' '||EMP_LNAME
     FROM EMPLOYEES
    WHERE EMP_UID_PK = P_EMP_UID_PK;

  CURSOR GET_IDENTIFIER IS
    SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
           CUS_BUSINESS_OFFICES_UID_FK, SVC_UID_PK, SOT_SYSTEM_CODE, OST_SERVICE_TYPES_UID_FK, STY_SYSTEM_CODE,
           svt_system_code
    FROM CUSTOMERS, ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SO_TYPES, SO,
         off_serv_subs, serv_sub_types
    WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
      AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND SVO_UID_PK = P_SVO_UID_PK
      AND osb_uid_pk(+) = svc_off_serv_subs_uid_fk
      AND svt_uid_pk(+) = osb_serv_sub_types_uid_fk;

  CURSOR SERV_SUB_TYPE IS
    SELECT OSB_OFFICE_SERV_TYPES_UID_FK, SVT_SYSTEM_CODE
    FROM OFF_SERV_SUBS, SO, SERV_SUB_TYPES
    WHERE OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
      AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
      AND SVO_UID_PK = P_SVO_UID_PK;

  CURSOR PACKET_CABLE_SUB(P_OST_UID_PK IN NUMBER, P_SVT_SYSTEM_CODE IN VARCHAR) IS
    SELECT OSB_UID_PK
    FROM OFF_SERV_SUBS, SERV_SUB_TYPES
    WHERE SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
      AND SVT_SYSTEM_CODE = P_SVT_SYSTEM_CODE
      AND OSB_OFFICE_SERV_TYPES_UID_FK = P_OST_UID_PK;

  CURSOR GET_SLO IS
    SELECT SSX_SERVICE_LOCATIONS_UID_FK
      FROM SERV_SERV_LOC_SO
     WHERE SSX_SO_UID_FK = P_SVO_UID_PK
       AND SSX_END_DATE IS NULL;

  CURSOR get_alopa_message(p_svo_uid_pk number, P_DATE IN VARCHAR) IS
   select 'X'
    from so_messages
   WHERE sog_so_uid_fk = p_svo_uid_pk
     AND sog_text = 'Alopa needs manual provisioning'
     --and created_by = 'PERLUSER'
     and created_by in ('HES','PERLUSER','NATHAN_J')
     and created_date > sysdate-5/1440
     and created_date >= to_date(P_DATE,'MM-DD-YYYY HH:MI:SS AM');

  CURSOR GET_WORK_FUNCTION IS
   SELECT WFC_UID_PK
    FROM WORK_FUNCTIONS, FUNCTIONS, WORKCENTERS
    WHERE FTN_UID_PK = WFC_FUNCTIONS_UID_FK
      AND WCR_UID_PK = WFC_WORKCENTERS_UID_FK
      AND WCR_CODE = 'NETO'
      AND FTN_SYSTEM_CODE = 'REVIEW';

  CURSOR GET_PLNT_INFO(P_STY_UID_PK IN NUMBER, P_BSO_UID_PK IN NUMBER, P_FTP_CODE IN VARCHAR) IS
  SELECT OSF_UID_PK
    FROM OFFICE_SERV_FEATS, OFFICE_SERV_TYPES, FEATURES
   WHERE OST_UID_PK = OSF_OFFICE_SERV_TYPES_UID_FK
     AND FTP_UID_PK = OSF_FEATURES_UID_FK
     AND FTP_CODE = P_FTP_CODE
     AND OST_BUSINESS_OFFICES_UID_FK = P_BSO_UID_PK
     AND OST_SERVICE_TYPES_UID_FK = P_STY_UID_PK;

  CURSOR CHECK_FOR_CBM (P_SVC_UID_PK IN NUMBER) IS
    SELECT SVA_CABLE_MODEMS_UID_FK, CBM_MAC_ADDRESS, 'CBM'
      FROM SERVICE_ASSGNMTS, CABLE_MODEMS
     WHERE SVA_CABLE_MODEMS_UID_FK = CBM_UID_PK
       AND SVA_SERVICES_UID_FK = P_SVC_UID_PK
   UNION
    SELECT MEU_UID_PK, MTA_CMAC_ADDRESS, 'MTA'
      FROM MTA_SERVICES, SERVICE_ASSGNMTS, MTA_PORTS, MTA_EQUIP_UNITS, MTA_BOXES
     WHERE SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
       AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
       AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
       AND MTA_UID_PK = MEU_MTA_BOXES_UID_FK
       AND SVA_SERVICES_UID_FK = P_SVC_UID_PK;
       
  cursor get_svc_loc is
	        select ssl_service_locations_uid_fk
	          from service_locations, serv_serv_locations, services, so
	         where ssl_services_uid_fk = svc_uid_pk
	           and slo_uid_pk = ssl_service_locations_uid_fk
	           and ssl_primary_loc_fl = 'Y'
	           and ssl_end_date is null
	           and svo_uid_pk = p_svo_uid_pk
           and svo_services_uid_fk = svc_uid_pk;
       

  V_DUMMY                			VARCHAR2(1);
  V_MTP_UID_PK           			NUMBER;
  V_WFC_UID_PK           			NUMBER;
  V_MEU_MTY_UID_FK       			NUMBER;
  V_MTA_MTY_UID_FK       			NUMBER;
  V_SLO_UID_PK           			NUMBER;
  V_MTO_UID_PK           			NUMBER;
  V_SVC_UID_PK           			NUMBER;
  V_BSO_UID_PK           			NUMBER;
  V_IVL_UID_PK           			NUMBER;
  V_OSB_UID_PK           			NUMBER;
  V_OST_UID_PK           			NUMBER;
  V_OSF_UID_PK           			NUMBER;
  V_STY_UID_PK           			NUMBER;
  V_CBM_UID_PK           			NUMBER;
  V_MTA_TYPE_ASSGNMTS_UID_PK 	NUMBER;
  V_MTA_TYPE_SCANNED_UID_PK		NUMBER;
  V_CBM_MAC_ADDRESS      			VARCHAR2(20);
  V_SEQ_CODE             			VARCHAR2(20);
  V_SOT_SYSTEM_CODE     			VARCHAR2(20);
  V_STY_SYSTEM_CODE      			VARCHAR2(20);
  V_SEQ_UID_PK           			NUMBER;
  V_TIME                 			VARCHAR2(200);
  V_TIME_O                 			VARCHAR2(200);
  V_SVT_CODE             			VARCHAR2(40);
  V_SOR_COMMENT          			VARCHAR2(2000);
  v_svc_svt_code                    VARCHAR2(12);

  V_SUCCESS_FL           			VARCHAR2(40);
  V_MTA_FOUND_FL         			VARCHAR2(1);
  V_IDENTIFIER           			VARCHAR2(300);
  V_DESCRIPTION          			VARCHAR2(300);
  V_EMP_NAME             			VARCHAR2(300);
  V_EQUIP_TYPE           			VARCHAR2(20);
  V_MTA_UID_PK           			NUMBER;
  V_STATUS               			VARCHAR2(200);
  V_LAST_IVL_UID_PK      			NUMBER;
  V_LAST_IVL_DESCRIPTION 			VARCHAR2(200);
  V_ACCOUNT              			VARCHAR2(200);
  V_DATE                 			DATE;
  V_OSS_CHAR_DATE        			VARCHAR2(40);
  V_ISP_CHAR_DATE        			VARCHAR2(40);
  V_ACTION_FL            			VARCHAR2(1);
  V_COUNTER              			NUMBER := 0;
  V_MAC_MESSAGE          			VARCHAR2(2000);
  V_PORT_TYPE            			VARCHAR2(40);
  V_MODEM_TYPE           			VARCHAR2(40);
  V_CUR_PORT#            			NUMBER;
  V_PORT_CHG_FL          			VARCHAR2(1);
  V_NEW_MTA_MAC          			VARCHAR2(20);
  V_OLD_CBM_MAC_ADDRESS  			VARCHAR2(20);
  V_TYPE                 			VARCHAR2(40);

  v_is_production_database  	VARCHAR2(1);
  v_msg_suffix           			VARCHAR2(100);
  
  V_MTA_TYPE_ASSGNMTS         VARCHAR2(40);
  V_MTA_TYPE_SCANNED          VARCHAR2(40);
  
  V_MLH_MESSAGE      					VARCHAR2(500);
	V_MLH_FOUND_FL							VARCHAR2(1) := 'N';
	V_ISS_USER_NAME							VARCHAR2(40);
	V_ISS_USER_NAME_LOWER       VARCHAR2(40);
	
	V_SVC_SLO_UID_PK            NUMBER;
	
	V_CUS_CHARTER_FL						VARCHAR2(1);

	v_return_msg  					VARCHAR2(4000);
	
	V_SEL_PROCEDURE_NAME	 			VARCHAR2(40):= 'FN_ADD_EMTA';

	
	V_ERROR_CODE      VARCHAR2(40)   := NULL;
	




BEGIN
  
  --GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
  OPEN GET_TECH_LOCATION;
  FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
  CLOSE GET_TECH_LOCATION;

  OPEN GET_IDENTIFIER;
  FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_BSO_UID_PK, V_SVC_UID_PK, V_SOT_SYSTEM_CODE, V_STY_UID_PK, V_STY_SYSTEM_CODE,
                            v_svc_svt_code;
  CLOSE GET_IDENTIFIER;
  

  OPEN SERV_SUB_TYPE;
  FETCH SERV_SUB_TYPE INTO V_OST_UID_PK, V_SVT_CODE;
  CLOSE SERV_SUB_TYPE;
 

  --GET SLO PK
  OPEN GET_SLO;
  FETCH GET_SLO INTO V_SLO_UID_PK;
  CLOSE GET_SLO;

  --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MTA_MAC, V_MTA_UID_PK);

  OPEN MTA_ALREADY_ON(V_MTA_UID_PK);
  FETCH MTA_ALREADY_ON INTO V_MTA_FOUND_FL;
  IF MTA_ALREADY_ON%FOUND THEN
     V_MTA_FOUND_FL := 'Y';
  ELSE
     V_MTA_FOUND_FL := 'N';
  END IF;
  CLOSE MTA_ALREADY_ON;
  

  --NOT FOUND
  IF V_EQUIP_TYPE  = 'N' THEN
     RETURN 'SERIAL# '|| P_MTA_MAC||' NOT FOUND.  PLEASE MAKE SURE YOU SCANNED THE MTA OR CMAC MAC ADDRESS';
     v_return_msg := 'SERIAL# '|| P_MTA_MAC||' NOT FOUND.  PLEASE MAKE SURE YOU SCANNED THE MTA OR CMAC MAC ADDRESS';
		 IF P_SVO_UID_PK IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
  ELSIF V_EQUIP_TYPE  = 'S' THEN
     RETURN 'YOU CANNOT SCAN A CABLE BOX IN THE MTA SECTION.';
     v_return_msg := 'YOU CANNOT SCAN A CABLE BOX IN THE MTA SECTION.';
		 IF P_SVO_UID_PK IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
  ELSIF V_EQUIP_TYPE  = 'M' THEN
     RETURN 'YOU CANNOT SCAN A CABLE MODEM IN THE MTA SECTION.';
     v_return_msg := 'YOU CANNOT SCAN A CABLE MODEM IN THE MTA SECTION.';
		 IF P_SVO_UID_PK IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
  ELSIF V_EQUIP_TYPE  = 'A' THEN
     RETURN 'YOU CANNOT SCAN AN ADSL MODEM IN THE MTA SECTION.';
     v_return_msg := 'YOU CANNOT SCAN AN ADSL MODEM IN THE MTA SECTION.';
		 IF P_SVO_UID_PK IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
  ELSIF V_EQUIP_TYPE  = 'V' THEN
   	 RETURN 'YOU CANNOT SCAN A VDSL MODEM IN THE MTA SECTION.';
   	 v_return_msg := 'YOU CANNOT SCAN A VDSL MODEM IN THE MTA SECTION.';
	 	 IF P_SVO_UID_PK IS NOT NULL THEN
	 			IF v_return_msg IS NOT NULL THEN
	 		 	 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 			END IF;
	 	 END IF;
  END IF;

  BEGIN
     --EMTA MAC MUST BE 1 NUMBER GREATER THAN THE CM MAC.
     IF NOT BOX_MODEM_PKG.FN_VALID_CMAC(P_MTA_MAC, P_CMAC_MAC) THEN
        RETURN 'THE MTA MAC '|| P_MTA_MAC||' MUST BE 1 NUMBER HIGHER THAN THE CM MAC';
        v_return_msg := 'THE MTA MAC '|| P_MTA_MAC||' MUST BE 1 NUMBER HIGHER THAN THE CM MAC';
				IF P_SVO_UID_PK IS NOT NULL THEN
					 IF v_return_msg IS NOT NULL THEN
					 		PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 END IF;
	 	 		END IF;
     END IF;

  EXCEPTION  --to catch to_number possible issues
      when others then
        RETURN 'INVALID MAC ADDRESS ENTERED';
        v_return_msg := 'INVALID MAC ADDRESS ENTERED';
				IF P_SVO_UID_PK IS NOT NULL THEN
					 IF v_return_msg IS NOT NULL THEN
							PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 END IF;
	 	 		END IF;
  END;

  OPEN GET_MEU_TYPE;
	FETCH GET_MEU_TYPE INTO V_MTA_TYPE_ASSGNMTS,V_MTA_TYPE_ASSGNMTS_UID_PK; ---,V_MEU_MTY_UID_FK; ---HD 99905 RMC 03/09/2011 
	CLOSE GET_MEU_TYPE;
	
	
	OPEN GET_MTA_TYPE(V_MTA_UID_PK);
	FETCH GET_MTA_TYPE INTO V_MTA_TYPE_SCANNED, V_MTA_TYPE_SCANNED_UID_PK; ---,V_MTA_MTY_UID_FK; ---HD 99905 RMC 03/09/2011 
  CLOSE GET_MTA_TYPE;
  

  --SECTION ONE TO CHECK FOR VALIDATION ISSUES

  IF V_IVL_UID_PK IS NULL THEN
     BOX_MODEM_PKG.PR_EXCEPTION(P_MTA_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
     RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
     v_return_msg := 'THIS TECH IS NOT SET UP ON A TRUCK';
		 IF P_SVO_UID_PK IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
	 	 END IF;
  END IF;
  

  IF V_MTA_FOUND_FL = 'N' THEN --CONTINUE WITH CHECKS BELOW.
  
  ---HD 109289 RMC 07/15/2011 - Verify Status 
  
     V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_MTA_MAC, V_EQUIP_TYPE, V_DESCRIPTION);
    
     
     --BOX STATUS CHECK
     IF V_STATUS NOT IN ('AN','AU','RT') THEN
        BOX_MODEM_PKG.PR_EXCEPTION(P_MTA_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A MTA TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_DESCRIPTION);
        V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_MTA_MAC);
        --IF V_ACCOUNT IS NOT NULL THEN
           --V_DESCRIPTION := V_DESCRIPTION||' ON '||V_ACCOUNT;
        --END IF;
        RETURN 'MTA '|| P_MTA_MAC||' IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
        v_return_msg := 'MTA '|| P_MTA_MAC||' IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
				IF P_SVO_UID_PK IS NOT NULL THEN
					 IF v_return_msg IS NOT NULL THEN
						 	PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
						END IF;
	 	 		END IF;
     END IF;

     --LOCATION CHECK
     IF V_IVL_UID_PK IS NOT NULL THEN
        V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_MTA_MAC);
        OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
        FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
        CLOSE LAST_LOCATION;

        IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
           IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
              BOX_MODEM_PKG.PR_EXCEPTION(P_MTA_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A BOX/MODEM TO '||V_IDENTIFIER||' '||P_MTA_MAC||' IS NOT FOUND ON THE TECHS TRUCK');
              RETURN 'MTA '|| P_MTA_MAC||' IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
           		v_return_msg := 'MTA '|| P_MTA_MAC||' IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
							IF P_SVO_UID_PK IS NOT NULL THEN
								 IF v_return_msg IS NOT NULL THEN
										PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
								 END IF;
	 	 					END IF;
           END IF;
        END IF;
     END IF;

     OPEN MTA_ACTIVE_ACCOUNT_CHECK(V_MTA_UID_PK, V_SLO_UID_PK);
     FETCH MTA_ACTIVE_ACCOUNT_CHECK INTO V_DUMMY;
     IF MTA_ACTIVE_ACCOUNT_CHECK%FOUND THEN
        RETURN 'MTA MAC '|| P_MTA_MAC||' IS FOUND ON AN ACTIVE ACCOUNT';
        v_return_msg := 'MTA MAC '|| P_MTA_MAC||' IS FOUND ON AN ACTIVE ACCOUNT';
				IF P_SVO_UID_PK IS NOT NULL THEN
					 IF v_return_msg IS NOT NULL THEN
							PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 END IF;
	 	 		END IF;
     END IF;
     CLOSE MTA_ACTIVE_ACCOUNT_CHECK;
     
     ---HD 99905 RMC 03/09/2011 - Change to check if the MTA type on the MTA_EQUIP_UNITS  is 728996 and the MTA type scanned in
		 ---                          is 780149 then bypass the check and allow the scanning to continue. The MEU_EQUIP_UNITS
		 ---                          will be updated with the MTA type from the scanned MTA. This was requested because customers are 
		 ---                          upgrading their HSD and requires a DOCSIS 3.0 Box (type = 780149). and the default MTA type is 728996.This stopped 
     ---                          the tech in the field and the HD had to manually change the MTA type.

     ---IF V_MEU_MTY_UID_FK != V_MTA_MTY_UID_FK THEN --- HD 99905 RMC 03/09/2011 Commented out
        ---RETURN 'MTA BOX '|| P_MTA_MAC||' TYPE MUST EQUAL THE TYPE REQUESTED FOR THIS ORDER.';--- HD 99905 RMC 03/09/2011 Commented out
     
     ---HD 109538 RMC 07/18/2011 - No longer need to compare the MTA TYPE in MTA Equipment records to 
     ---                           the MTA TYPE scanned in. The MTA Equipment records will be updated with
     ---                           MTA TYPE from the scanned MTA Modem. Lines commented out.
     
     /*IF V_MTA_TYPE_ASSGNMTS_UID_PK !=  V_MTA_TYPE_SCANNED_UID_PK THEN
		    IF V_MTA_TYPE_ASSGNMTS = '728996' THEN
		       IF V_MTA_TYPE_SCANNED in ('780149','785196') THEN ---HD 109009 RMC 07/06/2011 - Added mta type of '785196' to be checked
		          NULL;
		       ELSE
		          RETURN 'THE MTA BOX TYPE SCANNED '||P_MTA_MAC||' MUST EQUAL THE BOX TYPE ON THE MTA EQUIPMENT UNITS.';
		       END IF;
		    ELSIF V_MTA_TYPE_ASSGNMTS = '780149' THEN
		          IF V_MTA_TYPE_SCANNED in ('728996', '785196') THEN  ---HD 109009 RMC 07/06/2011 - Added mta type of '785196' to be checked
		             NULL;
		          ELSE
		             RETURN 'THE MTA BOX TYPE SCANNED '||P_MTA_MAC||' MUST EQUAL THE BOX TYPE ON THE MTA EQUIPMENT UNITS.';
		          END IF;
		    END IF;
     END IF;*/
   
  END IF;
  
  ---HD 111020- Move the Multi-line Hunt check before checking for the CS Swap and Determining If phone provisioned before HSD.
  
  V_MLH_MESSAGE := INSTALLER_WEB_PKG.FN_MLH_CHECK(P_SVO_UID_PK); 
		IF V_MLH_MESSAGE IS NULL THEN 
			 V_MLH_FOUND_FL := 'N';  
		ELSE  
		   V_MLH_FOUND_FL := 'Y';   
  END IF;
  
  -------------------------------------------------------------------------------------------------------------------------------------
	---HD 108134 - ADDED THIS SECTION TO INSURE THAT IF THERE IS A CS PHONE SO AND THERE IS ALSO A CS HSD SO AND VICE VERSA. BOTH ARE 
	---            NEEDED IF SWAPPING OUT A MTA MODEM.
  -------------------------------------------------------------------------------------------------------------------------------------
  IF V_MLH_FOUND_FL = 'N' THEN ---HD 111020 - Only check if it is NOT a Multi-line Hunt
     IF V_SOT_SYSTEM_CODE IN ('CS') THEN
        IF V_STY_SYSTEM_CODE = 'PHN' THEN
           IF NOT FN_CHECK_FOR_OTHER_SO_TYPE('BBS',V_SVC_UID_PK,P_SVO_UID_PK) THEN
              RETURN 'CS SERVICE ORDER FOR HIGH SPEED NEEDED FOR SWAP. CONTACT PLANT TO HAVE THE CS SERVICE ORDER CREATED.';
           		v_return_msg := 'CS SERVICE ORDER FOR HIGH SPEED NEEDED FOR SWAP. CONTACT PLANT TO HAVE THE CS SERVICE ORDER CREATED.';
							IF P_SVO_UID_PK IS NOT NULL THEN
								 IF v_return_msg IS NOT NULL THEN
										PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
								 END IF;
	 	 					END IF;
           ELSE
              NULL;
           END IF;
           --- HD 126240 - 12/05/2012 Cable Moden Shortage to comment out the below lines to bypass the check
           --- HD 126240 - 12/13/2012 Cable Moden Shortage to comment out the below lines to put the check back in
        ELSIF V_STY_SYSTEM_CODE ='BBS' THEN
  				    IF NOT FN_CHECK_FOR_OTHER_SO_TYPE('PHN',V_SVC_UID_PK,P_SVO_UID_PK) THEN
                 RETURN 'CS SERVICE ORDER FOR PHONE NEEDED FOR SWAP. CONTACT PLANT TO HAVE THE CS SERVICE ORDER CREATED.';
              	 v_return_msg := 'CS SERVICE ORDER FOR PHONE NEEDED FOR SWAP. CONTACT PLANT TO HAVE THE CS SERVICE ORDER CREATED.';
								 IF P_SVO_UID_PK IS NOT NULL THEN
								 	  IF v_return_msg IS NOT NULL THEN
								 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
								 		END IF;
	 	 						 END IF;
              ELSE
                 NULL;
              END IF;   
        END IF;
     END IF;
  END IF;
  
  -------------------------------------------------------------------------------------------------------------------------------------
  ---HD 106390 - ADDED THIS SECTION TO DETEREMINE IF THE PHONE IS BEING PROVISIONED PRIOR TO THE HIGH SPEED BEING ADDED/PROVISIONED
  ---            Call the FNQuery ALOPA if starting with PHONE (V_STY_CODE = 'PHN'). Compare the Scanned CMAC to the CMAC assigned to the user.
  ---            IF the Scanned CMAC does not match the CMAC assigned to that user then the High Speed Service order
  ---            has not been add/provisioned before the phone and return false.

  -------------------------------------------------------------------------------------------------------------------------------------
 /* ---RMC 08/12/2013 - Incognito Project - Replace SO_Candidate Processing witn Web Service - XML Commands to Triad/Incognito
 
  IF V_STY_SYSTEM_CODE = 'PHN' THEN
  
     V_ISS_USER_NAME := FN_GET_ISS_USERNAME(V_SVC_UID_PK);
     
     IF V_ISS_USER_NAME = 'CUSTOMER NOT FOUND' THEN
        RETURN 'NO CUSTOMER FOUND FOR DETERMINING IF HIGH SPEED SERVICE SHOULD BE PROVISIONED BEFORE PHONE';
        v_return_msg := 'NO CUSTOMER FOUND FOR DETERMINING IF HIGH SPEED SERVICE SHOULD BE PROVISIONED BEFORE PHONE';
				IF P_SVO_UID_PK IS NOT NULL THEN
					 IF v_return_msg IS NOT NULL THEN
							PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 END IF;
	 	 		END IF;
     END IF;
     
     IF V_ISS_USER_NAME = 'USER NAME NOT FOUND' THEN
        RETURN 'USER NAME NOT FOUND ON THE HIGH SPEED SERVICE ORDER. PLEASE CONTACT PLANT.';
        v_return_msg := 'USER NAME NOT FOUND ON THE HIGH SPEED SERVICE ORDER. PLEASE CONTACT PLANT.';
				IF P_SVO_UID_PK IS NOT NULL THEN
					 IF v_return_msg IS NOT NULL THEN
							PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 END IF;
	 	 		END IF;
        
     END IF;
     
     IF V_ISS_USER_NAME IN ('NS FOR HSD','NO HSD SO') THEN
        IF V_ISS_USER_NAME IN ('NS FOR HSD') THEN --- HD 121170 06/28/2012 RMC - NS SO for HSD and a NS Phone and it is a Charter customer then disallow the NS HSD from being provisioned first.
        	 IF V_CUS_CHARTER_FL = 'Y' THEN --- HD 121170 06/28/2012 RMC - NS SO for HSD and a NS Phone and it is a Charter customer then disallow the NS HSD from being provisioned first.
        	 		RETURN 'CHARTER CUSTOMER. HIGH SPEED SERVICE ORDER MUST BE ADD/PROVISIONED BEFORE PHONE SERVICE ORDER. PLEASE ADD/PROVISION HIGH SPEED SERVICE ORDER FIRST.'; 
        	 		v_return_msg :='CHARTER CUSTOMER. HIGH SPEED SERVICE ORDER MUST BE ADD/PROVISIONED BEFORE PHONE SERVICE ORDER. PLEASE ADD/PROVISION HIGH SPEED SERVICE ORDER FIRST.'; 
							IF P_SVO_UID_PK IS NOT NULL THEN
								 IF v_return_msg IS NOT NULL THEN
										PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
								 END IF;
	 	 				  END IF;
        	 ELSE
        	 	  NULL;
        	 END IF;
        ELSE
           NULL;
        END IF;
     ELSE
        V_ISS_USER_NAME_LOWER := lower(V_ISS_USER_NAME);
        IF NOT FN_HSD_BEFORE_PHONE (V_ISS_USER_NAME_LOWER, P_CMAC_MAC) THEN
           RETURN 'HIGH SPEED SERVICE ORDER MUST BE ADD/PROVISIONED BEFORE PHONE SERVICE ORDER. PLEASE ADD/PROVISION HIGH SPEED SERVICE ORDER FIRST.'; 
        	 v_return_msg := 'HIGH SPEED SERVICE ORDER MUST BE ADD/PROVISIONED BEFORE PHONE SERVICE ORDER. PLEASE ADD/PROVISION HIGH SPEED SERVICE ORDER FIRST.'; 
					 IF P_SVO_UID_PK IS NOT NULL THEN
					 		IF v_return_msg IS NOT NULL THEN
					 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 		END IF;
	 	 			 END IF;
        ELSE
           NULL; 
        END IF;
     END IF;  
     
  END IF;
  */   
  -------------------------------------------------------------------------------------------------------------------------------------
  
  IF V_SVT_CODE = 'CABLE MODEM' THEN  --ADDING A MTA BOX TO A PACKET CABLE SUB TYPE ORDER SO SWITCH THE SUB TYPE TO 'CABLE MODEM'.
     V_TYPE := FN_MTA_TYPE(V_SLO_UID_PK);
     OPEN PACKET_CABLE_SUB(V_OST_UID_PK, V_TYPE);
     FETCH PACKET_CABLE_SUB INTO V_OSB_UID_PK;
     IF PACKET_CABLE_SUB%FOUND THEN
        UPDATE SO
           SET SVO_OFF_SERV_SUBS_UID_FK = V_OSB_UID_PK
         WHERE SVO_UID_PK = P_SVO_UID_PK;
     END IF;
     CLOSE PACKET_CABLE_SUB;
     COMMIT;
  END IF;
  
  /* HD 111020 - Mods to determine if CS Multi-line Hunt before checking for CS Swap and Determining if Phone provisioned before HSD
                 Move this code up above those two checks and the check for the multi-line hunt.
  
  --- HD 105771 RMC 05/03/2011 - MLH Processing
  V_MLH_MESSAGE := INSTALLER_WEB_PKG.FN_MLH_CHECK(P_SVO_UID_PK); 
	IF V_MLH_MESSAGE IS NULL THEN 
		 V_MLH_FOUND_FL := 'N';  
	ELSE  
	   V_MLH_FOUND_FL := 'Y';   
  END IF;
  
  */

  --SECTION TWO TO UPDATE THE PROPER HES TABLES
  
  IF V_MLH_FOUND_FL = 'N' THEN --- HD 105771 RMC 05/03/2011 - MLH Processing
  		IF V_STY_SYSTEM_CODE = 'PHN' THEN
    		 V_CMTS_MESSAGE := FN_CHECK_VALID_CMTS(V_SLO_UID_PK);
     		 IF V_CMTS_MESSAGE IS NOT NULL THEN
            
        		RETURN V_CMTS_MESSAGE;
        		v_return_msg := V_CMTS_MESSAGE;
						IF P_SVO_UID_PK IS NOT NULL THEN
							 IF v_return_msg IS NOT NULL THEN
								  PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
							 END IF;
	 	 			  END IF;
     		 END IF;
   
     		 V_LTG_MESSAGE := FN_CHECK_VALID_LTG(P_SVO_UID_PK);
         IF V_LTG_MESSAGE IS NOT NULL THEN
      
     
            RETURN V_LTG_MESSAGE;
            v_return_msg := V_LTG_MESSAGE;
						IF P_SVO_UID_PK IS NOT NULL THEN
							 IF v_return_msg IS NOT NULL THEN
									PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
							 END IF;
	 	 			  END IF;
         END IF;
         
         ---HD 107161 - Created function (INSTALLER_WEB_PKG.FN_CHECK_VALID_SVC_LEN) to check that Move out assignments 
         ---            have a Len assigned, Function is called from IWP. The following additional code was added
         ---            as well.
      
         IF V_SOT_SYSTEM_CODE IN ('MS') THEN
            OPEN GET_SVC_LOC;
						FETCH GET_SVC_LOC INTO V_SVC_SLO_UID_PK;
            CLOSE GET_SVC_LOC;
         
            IF V_SVC_SLO_UID_PK IS NOT NULL THEN
               --Check to make sure location is not EMTA or RFOG
               IF INSTALLER_WEB_PKG.FN_EMTA_LOCATION(V_SVC_SLO_UID_PK) = 'N' OR 
                  INSTALLER_WEB_PKG.FN_RFOG_LOCATION(V_SVC_SLO_UID_PK) = 'N' THEN
                  V_LEN_MESSAGE := INSTALLER_WEB_PKG.FN_CHECK_VALID_SVC_LEN(V_SVC_UID_PK);
                
				          IF V_LEN_MESSAGE IS NOT NULL THEN
				             RETURN V_LEN_MESSAGE;
				             v_return_msg := V_LEN_MESSAGE;
										 IF P_SVO_UID_PK IS NOT NULL THEN
										 		IF v_return_msg IS NOT NULL THEN
										 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
										 		END IF;
	 	 								 END IF;
                  END IF;
                  
               END IF;
            END IF;
         END IF;
         
         V_PORT_TYPE := 'TEL';
      ELSE
         V_PORT_TYPE := 'DATA';
      END IF;
 

  --GET CURRENT PORT#
  V_PORT_CHG_FL := 'N';
  OPEN GET_CUR_PORT;
  FETCH GET_CUR_PORT INTO V_CUR_PORT#;
  IF GET_CUR_PORT%FOUND THEN
     IF V_CUR_PORT# != p_port_line# then
        V_PORT_CHG_FL := 'Y';
     END IF;
  END IF;
  CLOSE GET_CUR_PORT;

  --THIS WILL GET THE PORT PK FOR US TO UPDATE FOR THE SO ASSIGNMENT RECORD MTA_SO TABLE
  OPEN GET_PORT(V_PORT_TYPE);
  FETCH GET_PORT INTO V_MTP_UID_PK;
  IF GET_PORT%NOTFOUND THEN --ISSUE
     RETURN 'THE PORT FOR THIS MTA BOX '|| P_MTA_MAC||' IS NOT FOUND';
     v_return_msg := 'THE PORT FOR THIS MTA BOX '|| P_MTA_MAC||' IS NOT FOUND';
		 IF P_SVO_UID_PK IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
	 	 END IF;
  ELSE
     UPDATE MTA_SO
        SET MTO_MTA_PORTS_UID_FK = V_MTP_UID_PK
      WHERE MTO_SO_ASSGNMTS_UID_FK = P_SON_UID_PK;
  END IF;
  CLOSE GET_PORT;
  
  END IF; --- HD 105771 RMC 05/03/2011 - MLH Processing

  --THIS WILL UPDATE THE MTA_EQUIP_UNITS TABLE WITH THE MTA AND CMAC ADDRESSES PASSED IN
  
  --HD 99905 RMC 03/09/2011 - Added MEU_MTA_TYPES_UID_FK = V_MTA_TYPE_SCANNED_UID_PK. The field - V_MTA_TYPE_SCANNED_UID_PK is the PK
	--                          for the MTA Type from the actual MTA box that was scanned in by the tech. The MTA_EQUIP_UNITS table
	--                          will now be reflect that change.
	
	UPDATE MTA_EQUIP_UNITS
	   SET MEU_MTA_BOXES_UID_FK = V_MTA_UID_PK,
	       MEU_MTA_TYPES_UID_FK = V_MTA_TYPE_SCANNED_UID_PK,
	       MEU_REMOVE_MTA_FL = 'N'
  WHERE MEU_UID_PK = P_MEU_UID_PK;



  -- MCV 01/21/16 HSD MTA or Cable Modem on Fiber overbuild. provision ISP
  IF overbuild_pkg.get_so_fiber_conv_fun(p_svo_uid_pk)=1  THEN
  
    INSERT INTO so_candidates (soc_uid_pk, soc_so_uid_fk, soc_swt_equipment_uid_fk, soc_action_fl, soc_dispatch_fl, soc_routed_fl, soc_start_date, soc_priority, soc_work_attempts)
          VALUES (soc_seq.nextval, p_svo_uid_pk, code_pkg.get_pk('SWT_EQUIPMENT','ISP'),'A','N','N',SYSDATE,1,0);                                    
  END IF;

  COMMIT;

  --IF V_STY_SYSTEM_CODE = 'BBS' THEN
     OPEN CHECK_FOR_CBM(V_SVC_UID_PK);
     FETCH CHECK_FOR_CBM INTO V_CBM_UID_PK, V_CBM_MAC_ADDRESS, V_MODEM_TYPE;
     IF CHECK_FOR_CBM%NOTFOUND THEN
        V_CBM_UID_PK      := NULL;
        V_CBM_MAC_ADDRESS := NULL;
        V_MODEM_TYPE      := NULL;
     END IF;
     CLOSE CHECK_FOR_CBM;
  --ELSE
     --V_CBM_UID_PK      := NULL;
     --V_CBM_MAC_ADDRESS := NULL;
     --V_MODEM_TYPE      := NULL;
  --END IF;

  IF V_CBM_MAC_ADDRESS IS NULL AND V_STY_SYSTEM_CODE != 'PHN' THEN  --NO EXISTING MODEM OR MTA TO ISSUE THE CHANGE MAC SO ASK PLANT TO DO MANUALLY.  THIS SHOULD ONLY HAPPEN IF THE OLD EQUIPMENT IS RETURNED PRIOR TO THE TECHNICIAN PROVISIONING THE NEW EQUIPMENT
     IF V_SOT_SYSTEM_CODE IN ('CS','MS') AND v_svc_svt_code IN ('RFOG','PACKETCABLE','CABLE MODEM') THEN
        INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                   VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', TRUNC(SYSDATE), SYSDATE, 'No existing cable modem or MTA found on the customer to issue the change MAC.  Please manually provision');  
        RETURN 'No existing cable modem or MTA found on the customer to issue the change to the new MTA.  Please call plant to manually provision';
     		v_return_msg := 'No existing cable modem or MTA found on the customer to issue the change to the new MTA.  Please call plant to manually provision';
				IF P_SVO_UID_PK IS NOT NULL THEN
					 IF v_return_msg IS NOT NULL THEN
						 	PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 END IF;
	 	 		END IF;
     END IF;
  END IF;
  ----------------------------------------------------------------------

  --SECTION THREE TO UPDATE AN EXISTING SO CANDIDATE RECORD OR CREATE A NEW ONE
  --ALSO TAKE INVENTORY INTO ACCOUNT TO ADD TO ACCOUNT

  V_OLD_CBM_MAC_ADDRESS := NULL;
  

  
  IF V_CBM_MAC_ADDRESS IS NOT NULL THEN ---RMC 08/12/2013 - Incognito Project - adde to replace IF V_CBM_MAC_ADDRESS IS NULL THEN
     IF V_MODEM_TYPE = 'MTA' AND V_STY_SYSTEM_CODE = 'PHN' THEN
        V_OLD_CBM_MAC_ADDRESS := V_CBM_MAC_ADDRESS;
        --V_CBM_UID_PK      := NULL;
        V_CBM_MAC_ADDRESS := NULL;
        V_MODEM_TYPE      := NULL;
     END IF;
  END IF;


  IF V_LAST_IVL_DESCRIPTION = 'LOCATION NOT FOUND' THEN --ALSO ADD A RECORD TO ISSUE AN AUTO RECEIVE IN, INTO THE TECH TRUCK LOCATION
     BOX_MODEM_PKG.PR_RECEIVE_STB_INTO_INV(P_MTA_MAC, V_IVL_UID_PK, NULL, NULL);
  END IF;

  INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                      VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', TRUNC(SYSDATE), SYSDATE, 'The MTA box '||P_MTA_MAC||'/'||P_CMAC_MAC||' was added by technician '||V_EMP_NAME);
  ----------------------------------------------------------------------

  BOX_MODEM_PKG.PR_ADD_ACCT(P_MTA_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'ADD ACCT WEB');

  
  COMMIT;

  --SECTION FOUR TO CHECK THE SWITCH LOGS TO LOOK FOR A SUCCESSFUL RESPONSE

  V_TIME := TO_CHAR(SYSDATE + .002,'MM-DD-YYYY HH:MI:SS AM');
  V_ISP_SUCCESS_FL := 'N';
  -- set up flag for database and success message to be appended for developemnt
  GET_RUN_ENVIRONMENT(P_DEVELOPMENT_ACTION,
                      v_is_production_database,
                      v_msg_suffix);

  IF V_CBM_MAC_ADDRESS IS NULL THEN
  
    IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
      RETURN 'Provisioning Successful Dev Success ' || v_msg_suffix;
      v_return_msg := 'Provisioning Successful Dev Success ' || v_msg_suffix;
			IF P_SVO_UID_PK IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
						PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
	 	 	END IF; 
    ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
      RETURN 'Provisioning Error Dev Failure ' || v_msg_suffix;
      v_return_msg := 'Provisioning Error Dev Failure ' || v_msg_suffix;
			IF P_SVO_UID_PK IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
						PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
	 	 	END IF; 
    
    ELSIF ((V_SOT_SYSTEM_CODE IN ('RI','NS') AND V_STY_SYSTEM_CODE = 'PHN')
          	OR V_STY_SYSTEM_CODE = 'BBS') THEN 

     /* WHILE SYSDATE < TO_DATE(V_TIME,'MM-DD-YYYY HH:MI:SS AM') LOOP*/
        
      IF P_EMTA_TYPE = 'T' THEN
        
             v_isp_char_date := TO_CHAR(SYSDATE,'MM-DD-YYYY HH:MI:SS AM');
             
             v_isp_success_fl := provision_triad_so_fun(p_svo_uid_pk);
           	
           	DBMS_OUTPUT.PUT_LINE('job result 2 is  '||v_result);
           
             IF V_ISP_SUCCESS_FL = 'N' THEN
           		IF V_MLH_FOUND_FL = 'N' THEN
			      v_return_msg := 'Order Updated, but provisioning failed on Triad provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.';
			      IF P_SVO_UID_PK IS NOT NULL THEN
                     IF v_return_msg IS NOT NULL THEN
                        PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
                     END IF;
			      END IF;
			      RETURN 'Order Updated, but provisioning failed on Triad provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.';
			    ELSE
			      v_return_msg := 'Multi line hunt service. Order Updated, but provisioning failed on Triad provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.';
			      IF P_SVO_UID_PK IS NOT NULL THEN
                     IF v_return_msg IS NOT NULL THEN
                        PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
                     END IF;
			      END IF;
			      RETURN 'Multi line hunt service. Order Updated, but provisioning failed on Triad provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.';
                END IF;
             END IF;

           IF V_ISP_SUCCESS_FL = 'Y' THEN --ALSO CHECK FOR OSSGATE SUCCESS
              
              IF V_MLH_FOUND_FL = 'N' THEN --- HD 105771 RMC 05/03/2011 - MLH Processing

                 V_COUNTER := V_COUNTER + 1;

                 IF V_COUNTER = 1 THEN  --CREATE SO_CANDIDATES RECORD FOR OSSGATE
                    V_SEQ_CODE := 'OSSGATE';
                    OPEN GET_SWT_EQUIPMENT(V_SEQ_CODE);
                    FETCH GET_SWT_EQUIPMENT INTO V_SEQ_UID_PK;
                    CLOSE GET_SWT_EQUIPMENT;

                    OPEN CHECK_EXIST_CANDIDATE(P_SVO_UID_PK, V_SEQ_CODE);
                    FETCH CHECK_EXIST_CANDIDATE INTO V_OSS_CHAR_DATE ;
                    IF CHECK_EXIST_CANDIDATE%NOTFOUND THEN
                       INSERT INTO SO_CANDIDATES (SOC_UID_PK, SOC_SO_UID_FK, SOC_SWT_EQUIPMENT_UID_FK, SOC_ACTION_FL, SOC_DISPATCH_FL, SOC_ROUTED_FL, SOC_START_DATE,
                                                  SOC_PRIORITY, SOC_WORK_ATTEMPTS, SOC_CABLE_WORK_FL)
                                          VALUES (SOC_SEQ.NEXTVAL, P_SVO_UID_PK, V_SEQ_UID_PK, 'A', 'N', 'N', SYSDATE, 0, 1, 'N');
                    ELSE
                       UPDATE SO_CANDIDATES
                          SET SOC_CABLE_WORK_FL = 'N',
                              SOC_START_DATE = SYSDATE,
                              SOC_WORK_ATTEMPTS = 1,
                              SOC_PRIORITY = 0,
                              SOC_ROUTED_FL = 'N',
                              SOC_DISPATCH_FL = 'N'
                         WHERE SOC_SO_UID_FK = P_SVO_UID_PK
                         AND SOC_ACTION_FL = 'A'
                         AND SOC_SWT_EQUIPMENT_UID_FK IN (SELECT SEQ_UID_PK
                                                            FROM SWT_EQUIPMENT
                                                          WHERE SEQ_CODE = V_SEQ_CODE);
                    END IF;
                    CLOSE CHECK_EXIST_CANDIDATE;

                    COMMIT;
                 END IF;

               V_TIME_O := TO_CHAR(SYSDATE + .003,'MM-DD-YYYY HH:MI:SS AM');
               WHILE SYSDATE < TO_DATE(V_TIME_O,'MM-DD-YYYY HH:MI:SS AM')
               LOOP
                 OPEN OSSGATE_CHECK1(V_ISP_CHAR_DATE);
                 FETCH OSSGATE_CHECK1 INTO V_SOR_COMMENT;
                 IF OSSGATE_CHECK1%FOUND OR V_SOT_SYSTEM_CODE NOT IN ('NS','RS') OR V_PORT_CHG_FL = 'Y' THEN
                    OPEN OSSGATE_CHECK2(V_ISP_CHAR_DATE);
                    FETCH OSSGATE_CHECK2 INTO V_SOR_COMMENT;
                    IF OSSGATE_CHECK2%FOUND OR V_SOT_SYSTEM_CODE NOT IN ('NS','RI') THEN
                       OPEN OSSGATE_CHECK3(V_ISP_CHAR_DATE);
                       FETCH OSSGATE_CHECK3 INTO V_SOR_COMMENT;
                       IF OSSGATE_CHECK3%NOTFOUND THEN
                          CLOSE OSSGATE_CHECK3;
                          CLOSE OSSGATE_CHECK2;
                          CLOSE OSSGATE_CHECK1;
                          RETURN 'Ossgate Provisioning. Successful';
                          v_return_msg := 'Ossgate Provisioning. Successful';
													IF P_SVO_UID_PK IS NOT NULL THEN
														 IF v_return_msg IS NOT NULL THEN
																PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
														 END IF;
	 	 											END IF;
                          
                       ELSE
                  
                
                          CLOSE OSSGATE_CHECK3;
                          CLOSE OSSGATE_CHECK2;
                          CLOSE OSSGATE_CHECK1;
                          RETURN 'Order Updated, but provisioning failed on OSSGATE provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.';
                       		v_return_msg := 'Order Updated, but provisioning failed on OSSGATE provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.';
													IF P_SVO_UID_PK IS NOT NULL THEN
														 IF v_return_msg IS NOT NULL THEN
																PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
														 END IF;
	 	 											END IF;
                       END IF;
                       CLOSE OSSGATE_CHECK3;
                    ELSE
                       IF V_SOT_SYSTEM_CODE = 'NS' THEN
                          OPEN CHECK_SWT_LOGS_ERROR('OSSGATE',V_ISP_CHAR_DATE, P_SVO_UID_PK);
                          FETCH CHECK_SWT_LOGS_ERROR INTO V_SOR_COMMENT, V_DATE;
                          IF CHECK_SWT_LOGS_ERROR%FOUND THEN
                                 
                             CLOSE OSSGATE_CHECK2;
                             CLOSE OSSGATE_CHECK1;  
                             RETURN 'Order Updated, but provisioning failed on OSSGATE provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.';
                          	 v_return_msg := 'Order Updated, but provisioning failed on OSSGATE provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.';
														 IF P_SVO_UID_PK IS NOT NULL THEN
														 		IF v_return_msg IS NOT NULL THEN
														 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
														 		END IF;
	 	 												 END IF;
                          END IF;
                          CLOSE CHECK_SWT_LOGS_ERROR;
                       END IF;
                    END IF;
                    CLOSE OSSGATE_CHECK2;
                 ELSE
                    IF V_SOT_SYSTEM_CODE = 'NS' THEN
                       OPEN CHECK_SWT_LOGS_ERROR('OSSGATE',V_ISP_CHAR_DATE,P_SVO_UID_PK);
                       FETCH CHECK_SWT_LOGS_ERROR INTO V_SOR_COMMENT, V_DATE;
                       IF CHECK_SWT_LOGS_ERROR%FOUND THEN
                           
                           CLOSE OSSGATE_CHECK1;
                          RETURN 'Order Updated, but provisioning failed on OSSGATE provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.';
                          v_return_msg := 'Order Updated, but provisioning failed on OSSGATE provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.';
													IF P_SVO_UID_PK IS NOT NULL THEN
														 IF v_return_msg IS NOT NULL THEN
																PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
														 END IF;
	 	 										  END IF;
                       END IF;
                       CLOSE CHECK_SWT_LOGS_ERROR;
                 
                    END IF;
                    ---CLOSE OSSGATE_CHECK1; ---- 05/23/2011 - Per Nathan, this needs to be moved to below the END IF
                 END IF;
                 CLOSE OSSGATE_CHECK1; ---- 05/23/2011 - Per Nathan, this needs to be moved her below the END IF
                END LOOP; 
              ELSIF V_MLH_FOUND_FL = 'Y' THEN --- HD 105771 RMC 05/03/2011 - MLH Processing
                    RETURN 'THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR THE CABLE MODEM DEVICE IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.';  
              			v_return_msg := 'THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR THE CABLE MODEM IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.';  
										IF P_SVO_UID_PK IS NOT NULL THEN
											 IF v_return_msg IS NOT NULL THEN
													PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
											 END IF;
	 	 								END IF;
              
                    ---HD 111020 RMC 08/25/2011 - Added the below code to insert message service order is for multi line hunt and call CO to provision the phone portion.
            
             				INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                                     VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR THE CABLE MODEM IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.'); 
                    COMMIT;
              
              END IF; --- HD 105771 RMC 05/03/2011 - MLH Processing
              
           END IF; --- V_ISP_SUCCESS_FL = 'Y'
           
        ELSE ---IF P_EMTA_TYPE = 'T'
        
            
             v_isp_success_fl := provision_triad_so_fun(p_svo_uid_pk);
             
             IF V_ISP_SUCCESS_FL = 'N' THEN
 
			      v_return_msg := 'Order Updated, but provisioning failed on Triad provisioning';
			      IF P_SVO_UID_PK IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
				    PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
			      END IF;
			      RETURN 'Order Updated, but provisioning failed on Triad provisioning';
 
             ELSE
                RETURN 'Triad provisioning successful';
             END IF;
        
           
        END IF;---IF P_EMTA_TYPE = 'T'
      
     /* END LOOP;*/---WHILE SYSDATE < TO_DATE
      
    ELSE ---ELSIF ((V_SOT_SYSTEM_CODE IN ('RI','NS')
    
 
      IF V_OLD_CBM_MAC_ADDRESS IS NULL THEN
         
         /* Add code to call web_services_pkg */

         v_isp_success_fl := provision_triad_so_fun(p_svo_uid_pk);            
            
      ELSE ---IF V_OLD_CBM_MAC_ADDRESS IS NULL
            
           COMMIT;
           ---RMC 08/12/2013 - Incognito Project - Replace SO_Candidate Processing witn web_services_pkg - XML Commands to Triad/Incognito
            
            C_SVC_UID_PK := NULL;
            C_SVO_UID_PK := P_SVO_UID_PK;
            V_MAC_MESSAGE := INSTALLER_WEB_PKG.FN_SAM_MAC_CHANGE(V_OLD_CBM_MAC_ADDRESS, P_CMAC_MAC, P_MTA_MAC);
            IF V_MAC_MESSAGE != 'Y' THEN
               PR_INSERT_SWT_LOGS(P_SVO_UID_PK, 'TRIAD_XML', V_MAC_MESSAGE, 'CHANGE MAC');
               PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, V_MAC_MESSAGE);
          
          
               RETURN 'Error in Triad.  '||V_MAC_MESSAGE||' Please call plant.';
               v_return_msg := 'Error in Triad.  '||V_MAC_MESSAGE||' Please call plant.';
							 IF P_SVO_UID_PK IS NOT NULL THEN
							 		IF v_return_msg IS NOT NULL THEN
							 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
							 		END IF;
	 	 					 END IF;
               
            ELSE 
            	 
            
            /* Add web service and check error and do the following to update mta_equip and set V_ISP_SUCCESS_FL = 'Y'*/
            
           				
               ---RMC 08/12/2013 - Incognito Project - Replace SO_Candidate Processing witn web_services_pkg - XML Commands to Triad/Incognito
               V_ISP_SUCCESS_FL := 'Y';
               PR_INSERT_SWT_LOGS(P_SVO_UID_PK, 'TRIAD_XML', 'SUCCESS', 'CHANGE MAC','Y');
               PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, 'CHANGE MAC WAS ELECTED TO CHANGE FROM MAC '||V_OLD_CBM_MAC_ADDRESS|| ' TO '||P_CMAC_MAC);
               
               
            END IF;---RMC 08/12/2013 - Incognito Project - Replace SO_Candidate Processing witn web_services_pkg - XML Commands to Triad/Incognito
            
         END IF; ---IF V_OLD_CBM_MAC_ADDRESS IS NULL

         IF V_ISP_SUCCESS_FL = 'Y' THEN
            IF V_MLH_FOUND_FL = 'N' THEN --- HD 105771 RMC 05/03/2011 - MLH Processing
               IF NOT FN_NISV_ON_ORDER(P_SVO_UID_PK) THEN
                  --ALSO ADD 'NISV' PER REQUEST FROM RANDALL
                  OPEN GET_PLNT_INFO(V_STY_UID_PK, V_BSO_UID_PK, 'NISV');
                  FETCH GET_PLNT_INFO INTO V_OSF_UID_PK;
                  CLOSE GET_PLNT_INFO;

                  --INSERT WITH ACTION FLAG OF 'A' WITH THE NISVCODE
                  INSERT INTO SO_FEATURES(SOF_UID_PK, SOF_SO_UID_FK, SOF_OFFICE_SERV_FEATS_UID_FK, SOF_QUANTITY, SOF_COST, SOF_ACTION_FL,
                                          SOF_ANNUAL_CHARGE_FL, SOF_INITIAL_CHARGE_FL, SOF_RECORDS_ONLY_FL, SOF_SERVICE_CHARGE_FL, SOF_EXT_NUM_CHG_FL,
                                          SOF_COMPLETED_FL, SOF_HAND_RATED_AMOUNT, SOF_OLD_QUANTITY, SOF_WARR_START_DATE, SOF_WARR_END_DATE)
                                   VALUES(SVF_SEQ.NEXTVAL, P_SVO_UID_PK, V_OSF_UID_PK, 1, 0,
                                          'A', 'N', 'N', 'N', 'Y','N','N', NULL,0, NULL, NULL);

               END IF;


               OPEN MTA_SO_PK;
               FETCH MTA_SO_PK INTO V_MTO_UID_PK;
               IF MTA_SO_PK%FOUND THEN
                  UPDATE MTA_SO
                     SET MTO_COMMENT = P_CMAC_MAC,
                         MTO_UID_# = NULL
                   WHERE MTO_UID_PK = V_MTO_UID_PK;

                  COMMIT;
                  V_SUCCESS_FL := INSTALLER_WEB_PKG.FN_OSSGATE_REPROVISION(P_SVO_UID_PK);
                  IF V_SUCCESS_FL = 'T' THEN
                     V_ERROR := INSTALLER_WEB_PKG.FN_SWT_LOGS_ERROR(P_SVO_UID_PK);
              
            
                     RETURN 'PROVISIONING ERROR OCCURED IN OSSGATE.  ERROR IS: '||V_ERROR;
                     v_return_msg := 'PROVISIONING ERROR OCCURED IN OSSGATE.  ERROR IS: '||V_ERROR;
										 IF P_SVO_UID_PK IS NOT NULL THEN
										 		IF v_return_msg IS NOT NULL THEN
										 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
										 		END IF;
	 	 					 			 END IF;
                  ELSIF V_SUCCESS_FL = 'Y' THEN
                        RETURN 'Ossgate Re-Provisioning Successful';
                        v_return_msg := 'Ossgate Re-Provisioning Successful';
												IF P_SVO_UID_PK IS NOT NULL THEN
													 IF v_return_msg IS NOT NULL THEN
															PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
													 
													 END IF;
	 	 					 			 		END IF;
                        
                  END IF;
               ELSE
                  RETURN 'ASSIGNMENTS ARE NOT SET UP FOR A MTA BOX.';
                  v_return_msg := 'ASSIGNMENTS ARE NOT SET UP FOR A MTA BOX.';
									IF P_SVO_UID_PK IS NOT NULL THEN
										 IF v_return_msg IS NOT NULL THEN
												PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
										 END IF;
	 	 					 		END IF;
               END IF;
               CLOSE MTA_SO_PK;
            
            ELSIF V_MLH_FOUND_FL = 'Y' THEN --- HD 105771 RMC 05/03/2011 - MLH Processing
						      RETURN 'THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR Triad IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.';  
						      v_return_msg := 'THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR THE CABLE MODEM IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.';  
									IF P_SVO_UID_PK IS NOT NULL THEN
										 IF v_return_msg IS NOT NULL THEN
												PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
										 END IF;
	 	 					 		END IF;
						         ---HD 111020 RMC 08/25/2011 - Added the below code to insert message service order is for multi line hunt and call CO to provision the phone portion.
									            
									   INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
									                    VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR Triad IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.'); 
                     COMMIT;
						
						END IF; --- HD 105771 RMC 05/03/2011 - MLH Processing
             
         END IF; --- END IF FOR V_ISP_SUCCESS_FL = 'Y'
      
      /*END LOOP; ----WHILE SYSDATE < TO_DATE(V_TIME,*/
    
    END IF; ---IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION 
    
  ELSE --HIGH SPEED MAC CHANGE  IF V_CBM_MAC_ADDRESS IS NULL THEN
 
     IF V_MODEM_TYPE = 'MTA' THEN
        V_NEW_MTA_MAC := P_MTA_MAC;
     ELSE
        V_NEW_MTA_MAC := NULL;
     END IF;
     
    IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
      V_MAC_MESSAGE := 'Y'; 
      
    ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
      V_MAC_MESSAGE := 'ERROR';
      
    ELSE
        UPDATE SO_ASSGNMTS
           SET SON_CABLE_MODEMS_UID_FK = NULL
         WHERE son_so_uid_fk = P_SVO_UID_PK;
         
         update service_assgnmts
            set sva_cable_modems_uid_fk = null
          where sva_cable_modems_uid_fk = V_CBM_UID_PK;
      COMMIT;	 
      C_SVC_UID_PK := NULL;
      C_SVO_UID_PK := P_SVO_UID_PK;
      V_MAC_MESSAGE := INSTALLER_WEB_PKG.FN_SAM_MAC_CHANGE(V_CBM_MAC_ADDRESS, P_CMAC_MAC, V_NEW_MTA_MAC);
    
    END IF;
       
    IF V_MAC_MESSAGE != 'Y' THEN
        /* Add code here to sent back message that provisioning failed.*/
       
       ----PR_INSERT_SWT_LOGS(P_SVO_UID_PK, 'ISP', V_MAC_MESSAGE, 'CHANGE MAC');--- RMC 08/14/2013 Incognito Project
       ----PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, V_MAC_MESSAGE);--- RMC 08/14/2013 Incognito Project
       
       PR_INSERT_SO_MESSAGE(P_SVO_UID_PK,'Order Updated, but error on change MAC');--- RMC 08/14/2013 Incognito Project
       
      
     
       RETURN 'Error in Triad. Change MAC '||V_MAC_MESSAGE||' Please call plant.'|| v_msg_suffix;
       v_return_msg := 'Error in Triad. Change MAC '||V_MAC_MESSAGE||' Please call plant.'|| v_msg_suffix;
			 IF P_SVO_UID_PK IS NOT NULL THEN
			 		IF v_return_msg IS NOT NULL THEN
			 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
			 		END IF;
	 	 	 END IF;
	 	 
    ELSE
     
      ---PR_INSERT_SWT_LOGS(P_SVO_UID_PK, 'ISP', 'SUCCESS', 'CHANGE MAC', 'Y'); --RMC 08/14/2013 Incognito Project
      PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, 'CHANGE MAC WAS SELECTED TO CHANGE FROM MAC '||V_CBM_MAC_ADDRESS|| ' TO '||P_CMAC_MAC);
      
      
      IF V_MODEM_TYPE = 'CBM' THEN
        UPDATE SO_ASSGNMTS
           SET SON_CABLE_MODEMS_UID_FK = NULL
         WHERE son_cable_modems_uid_fk = V_CBM_UID_PK;

          update service_assgnmts
             set sva_cable_modems_uid_fk = null
           where sva_cable_modems_uid_fk = V_CBM_UID_PK;


      ELSIF V_MODEM_TYPE = 'MTA' THEN
         IF V_CBM_UID_PK IS NOT NULL THEN --UPDATE THE OLD MTA EQUIP UNITS VALUE
            UPDATE MTA_EQUIP_UNITS
               SET MEU_MTA_BOXES_UID_FK = V_MTA_UID_PK
             WHERE MEU_UID_PK = V_CBM_UID_PK;
         END IF;
      END IF;
    
      COMMIT;

      BOX_MODEM_PKG.PR_REMOVE_ACCT(V_CBM_MAC_ADDRESS, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'REMOVE INSTALLATION', V_IVL_UID_PK);
      COMMIT;
      RETURN 'Provisioning Successful.  Please return the old modem into your truck.'|| v_msg_suffix;
      v_return_msg := 'Provisioning Successful.  Please return the old modem into your truck.'|| v_msg_suffix;
			IF P_SVO_UID_PK IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
						PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
	 	 	END IF;

    END IF;---IF V_MAC_MESSAGE != 'Y'
  END IF; ---IF V_CBM_MAC_ADDRESS IS NULL THEN

  COMMIT;
  ----------------------------------------------------------------------

  --SECTION FIVE ERROR MESSAGES

  --MOST MESSAGES ARE HANDLED AND RETURNED IN THE FIRST 4 SECTIONS
  --IF IT GETS TO THIS POINT WE KNOW ALL HAS PASSED EXCEPT A SUCCESSFUL REPONSE IN THE SWITCH LOGS AFTER 5 MINUTES
  --SO WE NEED TO NOTIFTY THE TECHNICIANS OF THIS AND ALSO HELPDESK AS WELL.


  RETURN 'SO FAILED PROVISIONING - SUCCESSFUL RESPONSE NOT FOUND WITHIN 3 MINUTES.  PLEASE CALL PLANT AT 815-1900 IF YOU NEED HELP.'; --EMAIL GROUP
  v_return_msg := 'SO FAILED PROVISIONING - SUCCESSFUL RESPONSE NOT FOUND WITHIN 3 MINUTES.  PLEASE CALL PLANT AT 815-1900 IF YOU NEED HELP.'; --EMAIL GROUP
	IF P_SVO_UID_PK IS NOT NULL THEN
		 IF v_return_msg IS NOT NULL THEN
				PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 END IF;
	END IF;
  ----------------------------------------------------------------------
END FN_ADD_EMTA;

---HD 106390 RMC 05/26/2011 - RETRIEVE USRR NAME TO USE IN DETERMINING IF TECH IS ATTEMPTING TO PROVISION PHONE BEFORE HSD

/*-------------------------------------------------------------------------------------------------------------*/

FUNCTION FN_GET_ISS_USERNAME(P_SVC_UID_PK IN NUMBER)

RETURN VARCHAR IS

CURSOR C_GET_CUSTOMER_NUMBER(P_SVC_UID_PK IN NUMBER) IS
SELECT CUS_UID_PK
  FROM CUSTOMERS,ACCOUNTS,SERVICES
 WHERE CUS_UID_PK = ACC_CUSTOMERS_UID_FK
   AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
   AND SVC_UID_PK = P_SVC_UID_PK;
   
CURSOR C_GET_BBS_SO_NUMBER (P_CUS_UID_PK IN NUMBER) IS
SELECT SVO_UID_PK, SOT_SYSTEM_CODE 
  FROM SO,
       SERVICES,
       ACCOUNTS,
       CUSTOMERS,
       SO_STATUS,
       SO_TYPES,
       OFFICE_SERV_TYPES,
       SERVICE_TYPES,
       BUSINESS_OFFICES
WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
  AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
  AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
  AND CUS_UID_PK = P_CUS_UID_PK 
  AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
  AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID')
  AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
  AND SOT_SYSTEM_CODE IN ('CS','MS','NS')
  AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
  AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
  AND STY_SYSTEM_CODE = 'BBS';
  
       
CURSOR C_GET_SVO_USERNAMES(P_BBS_SO_NUMBER NUMBER) IS
	   SELECT ISS_USER_NAME
	    FROM INTERNET_SO
	   WHERE ISS_SO_UID_FK = P_BBS_SO_NUMBER;
  

V_ISS_USER_NAME							VARCHAR2(40):= NULL;
V_CUS_UID_PK                NUMBER;
V_BBS_SO_NUMBER						  NUMBER;
V_SVC_UID_PK								NUMBER := P_SVC_UID_PK;
V_SOT_SYSTEM_CODE						VARCHAR2(20);

BEGIN

OPEN C_GET_CUSTOMER_NUMBER(V_SVC_UID_PK);
FETCH C_GET_CUSTOMER_NUMBER INTO V_CUS_UID_PK;
CLOSE C_GET_CUSTOMER_NUMBER;

IF V_CUS_UID_PK IS NOT NULL THEN
   OPEN C_GET_BBS_SO_NUMBER(V_CUS_UID_PK) ;
   FETCH C_GET_BBS_SO_NUMBER INTO V_BBS_SO_NUMBER,V_SOT_SYSTEM_CODE;
   IF C_GET_BBS_SO_NUMBER%FOUND THEN
      IF V_SOT_SYSTEM_CODE IN ('NS') THEN
      	 V_ISS_USER_NAME := 'NS FOR HSD';
      ELSE
      	 OPEN C_GET_SVO_USERNAMES(V_BBS_SO_NUMBER);
         FETCH C_GET_SVO_USERNAMES INTO V_ISS_USER_NAME;
         IF C_GET_SVO_USERNAMES%NOTFOUND THEN
			      V_ISS_USER_NAME := 'USER NAME NOT FOUND';
			   END IF; 
         CLOSE C_GET_SVO_USERNAMES;
      END IF;
   ELSE
      V_ISS_USER_NAME := 'NO HSD SO';
   END IF;
   CLOSE C_GET_BBS_SO_NUMBER;
ELSE
   V_ISS_USER_NAME := 'CUSTOMER NOT FOUND'; 
END IF;

RETURN V_ISS_USER_NAME;

END FN_GET_ISS_USERNAME;


---HD 106390 RMC 06/20/2011 - CHECK FOR OTHER CS SO TYPE FOR DETERMINING IF OTHER IS MISSING
---                           SO TYPE (LIKE IF HSD CS SO MISSING, THEN CHECK FOR PHONE CS SO)

/*-------------------------------------------------------------------------------------------------------------*/

FUNCTION FN_CHECK_FOR_OTHER_SO_TYPE(P_STY_SYSTEM_CODE IN VARCHAR, P_SVC_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER) 

RETURN BOOLEAN IS

CURSOR C_GET_CUSTOMER_NUMBER(P_SVC_UID_PK IN NUMBER) IS
SELECT CUS_UID_PK
  FROM CUSTOMERS,ACCOUNTS,SERVICES
 WHERE CUS_UID_PK = ACC_CUSTOMERS_UID_FK
   AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
   AND SVC_UID_PK = P_SVC_UID_PK;
   

--THIS CURSOR WILL CHECK TO SEE IF THE SUB TYPE IS PACKET CABLE FOR THE HIGH SPEED SERVICE ON SO.
CURSOR C_CHECK_FOR_PACKET_CABLE_SO(P_SVO_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SO, OFF_SERV_SUBS, SERV_SUB_TYPES
   WHERE OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
     AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
     AND SVO_UID_PK = P_SVO_UID_PK
     AND SVT_SYSTEM_CODE = 'PACKET CABLE'
  UNION
  SELECT 'X'
    FROM SO, SERVICES, OFF_SERV_SUBS, SERV_SUB_TYPES
   WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
     AND OSB_UID_PK = SVC_OFF_SERV_SUBS_UID_FK
     AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
     AND SVO_UID_PK = P_SVO_UID_PK
     AND SVT_SYSTEM_CODE = 'PACKET CABLE';
     
--THIS CURSOR WILL CHECK TO SEE IF THE SUB TYPE IS PACKET CABLE FOR THE HIGH SPEED SERVICE ON SO.   
CURSOR C_CHECK_FOR_PACKET_CABLE_SVC(P_SVC_UID_PK IN NUMBER) IS
   SELECT 'X'
     FROM OFF_SERV_SUBS, SERV_SUB_TYPES, SERVICES
    WHERE OSB_UID_PK = SVC_OFF_SERV_SUBS_UID_FK
      AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
      AND SVC_UID_PK = P_SVC_UID_PK
      AND SVT_SYSTEM_CODE = 'PACKET CABLE';
 
CURSOR C_CHECK_FOR_OTHER_ACTIVE_SVC(P_CUS_UID_PK IN NUMBER,P_STY_SYSTEM_CODE IN VARCHAR) IS
   SELECT SVC_UID_PK
     FROM ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES
    WHERE ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND ACC_CUSTOMERS_UID_FK = P_CUS_UID_PK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND STY_SYSTEM_CODE = P_STY_SYSTEM_CODE
      AND SVC_END_DATE IS NULL;
 
 
CURSOR C_CHECK_FOR_OTHER_SO(P_CUS_UID_PK IN NUMBER, P_STY_SYSTEM_CODE IN VARCHAR) IS
SELECT SVO_UID_PK, SOT_SYSTEM_CODE 
  FROM SO,
       SERVICES,
       ACCOUNTS,
       CUSTOMERS,
       SO_STATUS,
       SO_TYPES,
       OFFICE_SERV_TYPES,
       SERVICE_TYPES,
       BUSINESS_OFFICES
WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
  AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
  AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
  AND CUS_UID_PK = P_CUS_UID_PK 
  AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
  AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID')
  AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
  AND SOT_SYSTEM_CODE IN ('CS','NS') --- HD 106390 RMC 06/25/2011 - Added to check 'NS'
  AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
  AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
  AND STY_SYSTEM_CODE = P_STY_SYSTEM_CODE;
  
---HD 109249 RMC 07/12/2011
  
CURSOR C_CHECK_FOR_RI_SO(P_CUS_UID_PK IN NUMBER, P_STY_SYSTEM_CODE IN VARCHAR) IS
SELECT SVO_UID_PK, SOT_SYSTEM_CODE 
  FROM SO,
       SERVICES,
       ACCOUNTS,
       CUSTOMERS,
       SO_STATUS,
       SO_TYPES,
       OFFICE_SERV_TYPES,
       SERVICE_TYPES,
       BUSINESS_OFFICES
WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
  AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
  AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
  AND CUS_UID_PK = P_CUS_UID_PK 
  AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
  AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID')
  AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
  AND SOT_SYSTEM_CODE IN ('RI')
  AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
  AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
  AND STY_SYSTEM_CODE = P_STY_SYSTEM_CODE;
  
 
V_CUS_UID_PK                NUMBER;
V_OTHER_SO_NUMBER						NUMBER;
V_RI_SO_NUMBER							NUMBER;
V_SVC_UID_PK								NUMBER := P_SVC_UID_PK;
V_SOT_SYSTEM_CODE						VARCHAR2(20);
V_DUMMY											VARCHAR2(1);
V_STY_SYSTEM_CODE						VARCHAR2(20) := P_STY_SYSTEM_CODE;
V_SVO_UID_PK								NUMBER := P_SVO_UID_PK;
V_OTHER_SVC_UID_PK					NUMBER;


BEGIN

OPEN C_GET_CUSTOMER_NUMBER(V_SVC_UID_PK);
FETCH C_GET_CUSTOMER_NUMBER INTO V_CUS_UID_PK;
CLOSE C_GET_CUSTOMER_NUMBER;

---HD 111659 - MTA/Cable Modem Swap for Phone and HSD Do Not Require CS for HSD 
---            Added code - cursor - C_CHECK_FOR_PACKET_CABLE_SVC and V_STY_SYSTEM_CODE = 'BBS'

IF V_CUS_UID_PK IS NOT NULL THEN
   OPEN C_CHECK_FOR_OTHER_ACTIVE_SVC(V_CUS_UID_PK,V_STY_SYSTEM_CODE);
   FETCH C_CHECK_FOR_OTHER_ACTIVE_SVC INTO V_OTHER_SVC_UID_PK;
   IF C_CHECK_FOR_OTHER_ACTIVE_SVC%FOUND THEN
      OPEN C_CHECK_FOR_OTHER_SO(V_CUS_UID_PK,V_STY_SYSTEM_CODE);
			FETCH C_CHECK_FOR_OTHER_SO INTO V_OTHER_SO_NUMBER,V_SOT_SYSTEM_CODE;
      IF C_CHECK_FOR_OTHER_SO%NOTFOUND THEN
         IF V_STY_SYSTEM_CODE = 'BBS' THEN  
            OPEN C_CHECK_FOR_PACKET_CABLE_SVC(V_OTHER_SVC_UID_PK);
            FETCH C_CHECK_FOR_PACKET_CABLE_SVC INTO V_DUMMY;
            IF C_CHECK_FOR_PACKET_CABLE_SVC%FOUND THEN
               RETURN FALSE;  
            ELSE
               RETURN TRUE;
            END IF;
            CLOSE C_CHECK_FOR_PACKET_CABLE_SVC;
         ELSE
            RETURN FALSE;
         END IF;
         CLOSE C_CHECK_FOR_OTHER_SO;
      ELSE
				 RETURN TRUE; 
		  END IF;
	    CLOSE C_CHECK_FOR_OTHER_SO;
   ELSE
      OPEN C_CHECK_FOR_RI_SO(V_CUS_UID_PK,V_STY_SYSTEM_CODE);
			FETCH C_CHECK_FOR_RI_SO INTO V_RI_SO_NUMBER,V_SOT_SYSTEM_CODE;
			IF C_CHECK_FOR_RI_SO%FOUND THEN
			   RETURN FALSE;  
			ELSE
			   RETURN TRUE;
			END IF;
      CLOSE C_CHECK_FOR_RI_SO;
   END IF;
   CLOSE C_CHECK_FOR_OTHER_ACTIVE_SVC;
END IF;


END FN_CHECK_FOR_OTHER_SO_TYPE;


/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_CHECK_BBS_STATUS(P_SLO_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_MTA_MAC OUT VARCHAR, P_CM_MAC OUT VARCHAR)
RETURN VARCHAR IS

--THIS FUNCTION WILL RETURN AS OUT PARAMETERS THE MTA MAC ADDRESSES TO DEFAULT IF ALRAEDY FOUND ON ANOTHER
--SERVICE/SERVICE ORDER AT THE SAME LOCATION.

CURSOR CHECK_LOC_HAS_MTA(P_SVO_UID_PK IN NUMBER) IS
  SELECT MTA_MTAMAC_ADDRESS, MTA_CMAC_ADDRESS, '1'
    FROM MTA_SO, SERV_SERV_LOC_SO, SO, SO_STATUS, SO_ASSGNMTS, MTA_PORTS, MTA_EQUIP_UNITS, MTA_BOXES
   WHERE SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
     AND MTP_UID_PK = MTO_MTA_PORTS_UID_FK
     AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
     AND SVO_UID_PK = SON_SO_UID_FK
     AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
     AND SVO_UID_PK = SSX_SO_UID_FK
     AND SSX_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
     AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID')
     AND MTA_UID_PK = MEU_MTA_BOXES_UID_FK
  UNION
  SELECT MTA_MTAMAC_ADDRESS, MTA_CMAC_ADDRESS, '2'
    FROM MTA_SERVICES, SERVICES, SERV_SERV_LOCATIONS, SERVICE_ASSGNMTS, MTA_PORTS, MTA_EQUIP_UNITS, MTA_BOXES
   WHERE SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
     AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
     AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
     AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
     AND SVC_UID_PK = SSL_SERVICES_UID_FK
     AND SVC_UID_PK = SVA_SERVICES_UID_FK
     AND MTA_UID_PK = MEU_MTA_BOXES_UID_FK
     AND SVC_END_DATE IS NULL
   ORDER BY 3;

V_SVO_UID_PK          NUMBER;
V_MTA_MTAMAC_ADDRESS  VARCHAR2(25);
V_MTA_CMAC_ADDRESS    VARCHAR2(25);
V_SORT_BY             VARCHAR2(1);

BEGIN

  OPEN CHECK_LOC_HAS_MTA(V_SVO_UID_PK);
  FETCH CHECK_LOC_HAS_MTA INTO V_MTA_MTAMAC_ADDRESS, V_MTA_CMAC_ADDRESS, V_SORT_BY;
  IF CHECK_LOC_HAS_MTA%FOUND THEN
     P_MTA_MAC := V_MTA_MTAMAC_ADDRESS;
     P_CM_MAC  := V_MTA_CMAC_ADDRESS;
  END IF;
  CLOSE CHECK_LOC_HAS_MTA;

RETURN NULL;

END FN_CHECK_BBS_STATUS;

/*-------------------------------------------------------------------------------------------------------------*/
-- to add and provision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
FUNCTION FN_REMOVE_EMTA(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MEU_UID_PK IN NUMBER, P_MTA_MAC IN VARCHAR, P_CMAC_MAC IN VARCHAR, P_REUSE_FL IN VARCHAR, P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S')

  RETURN VARCHAR

  IS

  CURSOR GET_TECH_LOCATION IS
   SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
     FROM TECH_EMP_LOCATIONS, EMPLOYEES
    WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
      AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
      AND TEO_END_DATE IS NULL;

  CURSOR GET_IDENTIFIER IS
    SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK, SOT_CODE, STY_SYSTEM_CODE, ACC_CUSTOMERS_UID_FK,
           STY_UID_PK, OST_BUSINESS_OFFICES_UID_FK
    FROM ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SO, SO_TYPES
    WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
      AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND SVO_UID_PK = P_SVO_UID_PK;

  CURSOR OTHER_SO(P_CUS_UID_PK IN NUMBER, P_MTA_UID_PK IN NUMBER) IS
    SELECT SVO_UID_PK, STY_SYSTEM_CODE, SVC_UID_PK, SOT_CODE
    FROM ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SO, SO_STATUS, SO_TYPES,
         SO_ASSGNMTS, MTA_SO, MTA_PORTS, MTA_EQUIP_UNITS
    WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
      AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
      AND SVO_UID_PK = SON_SO_UID_FK
      AND SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND MTP_UID_PK = MTO_MTA_PORTS_UID_FK
      AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND MEU_MTA_BOXES_UID_FK = P_MTA_UID_PK
      AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID')
      AND SOT_SYSTEM_CODE IN ('RI','NS','MS','CS')
      AND SVO_UID_PK != P_SVO_UID_PK
      AND ACC_CUSTOMERS_UID_FK = P_CUS_UID_PK
   UNION
    SELECT SVO_UID_PK, STY_SYSTEM_CODE, SVC_UID_PK, SOT_CODE
    FROM ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SO, SO_STATUS, SO_TYPES, SERVICE_ASSGNMTS, MTA_SERVICES, MTA_PORTS, MTA_EQUIP_UNITS
    WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
      AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
      AND SVC_UID_PK = SVA_SERVICES_UID_FK
      AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
      AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND MEU_MTA_BOXES_UID_FK = P_MTA_UID_PK
      AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID')
      AND SOT_SYSTEM_CODE IN ('RI','NS','MS','CS')
      AND SVO_UID_PK != P_SVO_UID_PK
      AND ACC_CUSTOMERS_UID_FK = P_CUS_UID_PK;

  CURSOR GET_USERNAME(P_SVO_UID_PK2 IN NUMBER) IS
    SELECT ISS_USER_NAME
      FROM INTERNET_SO
     WHERE ISS_SO_UID_FK = P_SVO_UID_PK2;

  CURSOR GET_PLNT_INFO(P_STY_UID_PK IN NUMBER, P_BSO_UID_PK IN NUMBER, P_FTP_CODE IN VARCHAR) IS
  SELECT OSF_UID_PK
    FROM OFFICE_SERV_FEATS, OFFICE_SERV_TYPES, FEATURES
   WHERE OST_UID_PK = OSF_OFFICE_SERV_TYPES_UID_FK
     AND FTP_UID_PK = OSF_FEATURES_UID_FK
     AND FTP_CODE = P_FTP_CODE
     AND OST_BUSINESS_OFFICES_UID_FK = P_BSO_UID_PK
     AND OST_SERVICE_TYPES_UID_FK = P_STY_UID_PK;

  CURSOR MTA_SO_PK(P_SVO_UID_PK_NEW IN NUMBER) IS
    SELECT MTO_UID_PK
      FROM SO_ASSGNMTS, MTA_SO
     WHERE SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
       AND SON_SO_UID_FK = P_SVO_UID_PK_NEW;

  CURSOR GET_SUB_TYPE(P_SVC_UID_PK IN NUMBER) IS
    SELECT SVT_SYSTEM_CODE
      FROM SERV_SUB_TYPES, OFF_SERV_SUBS, SERVICES
     WHERE SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
       AND OSB_UID_PK = SVC_OFF_SERV_SUBS_UID_FK
       AND SVC_UID_PK = P_SVC_UID_PK;

  V_IVL_UID_PK           NUMBER;
  V_MTO_UID_PK           NUMBER;
  V_SVO_UID_PK           NUMBER;
  V_CUS_UID_PK           NUMBER;
  V_SVC_UID_PK           NUMBER;
  V_STY_UID_PK           NUMBER;
  V_BSO_UID_PK           NUMBER;
  V_OSF_UID_PK           NUMBER;
  V_SAM_SEQ              NUMBER;
  V_SAM_USER_NAME        VARCHAR2(200);
  V_SLO_UID_PK           NUMBER;
  V_RETURN_MESSAGE       VARCHAR2(2000);
  V_EQUIP_TYPE           VARCHAR2(1);
  V_SUCCESS_FL_OSS       VARCHAR2(1);
  V_SUCCESS_SAM          VARCHAR2(200);
  V_USERNAME             VARCHAR2(200);
  V_SAM_MESSAGE          VARCHAR2(2000);
  V_SAM_FQDN             VARCHAR2(200);
  V_MTA_UID_PK           NUMBER;
  V_STATUS               VARCHAR2(200);
  V_DUMMY                VARCHAR2(1);
  V_TIME                 VARCHAR2(200);
  V_SOR_COMMENT          VARCHAR2(2000);
  V_IDENTIFIER           VARCHAR2(200);
  V_EMP_NAME             VARCHAR2(200);
  V_SOT_CODE             VARCHAR2(20);
  V_STY_SYSTEM_CODE      VARCHAR2(20);
  V_SVT_SYSTEM_CODE      VARCHAR2(20);
  V_SVT_SYSTEM_CODE2     VARCHAR2(20);
  V_SAM_SUCCESS_FL       VARCHAR2(1);
  V_DEPROV_FL            VARCHAR2(1) := 'N';
  V_PHN_ALRDY_DEPROV     VARCHAR2(1) := 'N';     

  v_is_production_database  VARCHAR2(1);
  v_msg_suffix           VARCHAR2(100);
  
  v_return_msg  		 VARCHAR2(4000);
	
	V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_REMOVE_EMTA';
  
BEGIN

  --GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
  OPEN GET_TECH_LOCATION;
  FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
  CLOSE GET_TECH_LOCATION;

  OPEN GET_IDENTIFIER;
  FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK, V_SOT_CODE, V_STY_SYSTEM_CODE, V_CUS_UID_PK,
                            V_STY_UID_PK, V_BSO_UID_PK;
  CLOSE GET_IDENTIFIER;

  OPEN GET_SUB_TYPE(V_SVC_UID_PK);
  FETCH GET_SUB_TYPE INTO V_SVT_SYSTEM_CODE;
  IF GET_SUB_TYPE%NOTFOUND THEN
     V_SVT_SYSTEM_CODE := NULL;
  END IF;
  CLOSE GET_SUB_TYPE;

  --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MTA_MAC, V_MTA_UID_PK);

  IF V_IVL_UID_PK IS NULL THEN
     BOX_MODEM_PKG.PR_EXCEPTION(P_MTA_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
     RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
     v_return_msg := 'THIS TECH IS NOT SET UP ON A TRUCK';
		 	IF P_SVO_UID_PK IS NOT NULL THEN
		 		 IF v_return_msg IS NOT NULL THEN
		 				PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		 END IF;
			END IF;
  END IF;

  --NOT FOUND
  IF V_EQUIP_TYPE  = 'N' THEN
     RETURN 'MAC ADDRESS ' ||P_MTA_MAC|| ' NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
     v_return_msg := 'MAC ADDRESS ' ||P_MTA_MAC|| ' NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
		 IF P_SVO_UID_PK IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;  
  END IF;

  -- set up flag for database and success message to be appended for developemnt
  GET_RUN_ENVIRONMENT(P_DEVELOPMENT_ACTION,
                      v_is_production_database,
                      v_msg_suffix);
                      
  --DEPROVISION FROM SAM/OSSGATE
  IF V_STY_SYSTEM_CODE = 'PHN' THEN
     IF NOT FN_NISV_ON_ORDER(P_SVO_UID_PK) THEN
        --ALSO ADD 'NISV' PER REQUEST FROM RANDALL
        OPEN GET_PLNT_INFO(V_STY_UID_PK, V_BSO_UID_PK, 'NISV');
        FETCH GET_PLNT_INFO INTO V_OSF_UID_PK;
        CLOSE GET_PLNT_INFO;

        --INSERT WITH ACTION FLAG OF 'A' WITH THE NISVCODE
        INSERT INTO SO_FEATURES(SOF_UID_PK, SOF_SO_UID_FK, SOF_OFFICE_SERV_FEATS_UID_FK, SOF_QUANTITY, SOF_COST, SOF_ACTION_FL,
                                SOF_ANNUAL_CHARGE_FL, SOF_INITIAL_CHARGE_FL, SOF_RECORDS_ONLY_FL, SOF_SERVICE_CHARGE_FL, SOF_EXT_NUM_CHG_FL,
                                SOF_COMPLETED_FL, SOF_HAND_RATED_AMOUNT, SOF_OLD_QUANTITY, SOF_WARR_START_DATE, SOF_WARR_END_DATE)
                         VALUES(SVF_SEQ.NEXTVAL, P_SVO_UID_PK, V_OSF_UID_PK, 1, 0,
                                'A', 'N', 'N', 'N', 'Y','N','N', NULL,0, NULL, NULL);
     END IF;
     
    IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
      V_SUCCESS_SAM := 'SUCCESS';
      
    ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
      V_SUCCESS_SAM := 'ERROR';
      
    ELSE
     v_success_sam := provision_triad_service_fun(v_mta_uid_pk,'P',v_job_number);
    
    END IF;
    
     IF V_SUCCESS_SAM = 'SUCCESS' THEN
        PR_INSERT_SWT_LOGS(P_SVO_UID_PK, 'TRIAD_XML', 'SUCCESS - Job '||v_job_number, 'DEPROVISION VOICE','Y');
        V_SAM_SUCCESS_FL := 'Y';
        FOR REC IN OTHER_SO(V_CUS_UID_PK, V_MTA_UID_PK) LOOP
            IF REC.STY_SYSTEM_CODE = 'PHN' THEN

               IF NOT FN_NISV_ON_ORDER(REC.SVO_UID_PK) THEN
                   --ALSO ADD 'NISV' PER REQUEST FROM RANDALL
                  OPEN GET_PLNT_INFO(1, V_BSO_UID_PK, 'NISV');
                  FETCH GET_PLNT_INFO INTO V_OSF_UID_PK;
                  CLOSE GET_PLNT_INFO;

                 --INSERT WITH ACTION FLAG OF 'A' WITH THE NISV CODE
                 INSERT INTO SO_FEATURES(SOF_UID_PK, SOF_SO_UID_FK, SOF_OFFICE_SERV_FEATS_UID_FK, SOF_QUANTITY, SOF_COST, SOF_ACTION_FL,
                                SOF_ANNUAL_CHARGE_FL, SOF_INITIAL_CHARGE_FL, SOF_RECORDS_ONLY_FL, SOF_SERVICE_CHARGE_FL, SOF_EXT_NUM_CHG_FL,
                                SOF_COMPLETED_FL, SOF_HAND_RATED_AMOUNT, SOF_OLD_QUANTITY, SOF_WARR_START_DATE, SOF_WARR_END_DATE)
                         VALUES(SVF_SEQ.NEXTVAL, REC.SVO_UID_PK, V_OSF_UID_PK, 1, 0,
                                'A', 'N', 'N', 'N', 'Y','N','N', NULL,0, NULL, NULL);
               END IF;


                  OPEN MTA_SO_PK(REC.SVO_UID_PK);
                  FETCH MTA_SO_PK INTO V_MTO_UID_PK;
                  IF MTA_SO_PK%FOUND THEN
                     UPDATE MTA_SO
                        SET MTO_UID_# = '1'
                      WHERE MTO_UID_PK = V_MTO_UID_PK;
                  END IF;
                  CLOSE MTA_SO_PK;
                  DELETE
                    FROM SO_FEATURES
                   WHERE SOF_OFFICE_SERV_FEATS_UID_FK IN (SELECT OSF_UID_PK
                                                            FROM OFFICE_SERV_FEATS, FEATURES
                                                           WHERE FTP_UID_PK = OSF_FEATURES_UID_FK
                                                             AND FTP_CODE = 'CLEN')
                     AND SOF_SO_UID_FK = REC.SVO_UID_PK;
                     
                  IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
                    V_SUCCESS_FL_OSS := 'Y';
      
                  ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
                    V_SUCCESS_FL_OSS := 'T';
      
                  ELSE 
                    V_SUCCESS_FL_OSS := INSTALLER_WEB_PKG.FN_OSSGATE_DEPROVISION(REC.SVO_UID_PK);  
                  END IF;
                  
                  IF V_SUCCESS_FL_OSS = 'T' THEN --NOT SUCCESSFUL
                     V_ERROR := INSTALLER_WEB_PKG.FN_SWT_LOGS_ERROR(REC.SVO_UID_PK);
                   
                  
                     RETURN 'Ossgate deprovisioning was not successful.  Please call plant.  Error was :'||V_ERROR|| v_msg_suffix;
                  	 v_return_msg := 'Ossgate deprovisioning was not successful.  Please call plant.  Error was :'||V_ERROR|| v_msg_suffix;
										 IF REC.SVO_UID_PK IS NOT NULL THEN
										 	  IF v_return_msg IS NOT NULL THEN
										 			 PR_INS_SO_ERROR_LOGS(REC.SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
										 		END IF;
		 								 END IF; 
                  
                  END IF;



            END IF;
        END LOOP;
        IF V_SAM_SUCCESS_FL = 'Y' THEN
           OPEN MTA_SO_PK(P_SVO_UID_PK);
           FETCH MTA_SO_PK INTO V_MTO_UID_PK;
           IF MTA_SO_PK%FOUND THEN
              UPDATE MTA_SO
                 SET MTO_UID_# = '1'
               WHERE MTO_UID_PK = V_MTO_UID_PK;
              COMMIT;
           END IF;
           CLOSE MTA_SO_PK;

           DELETE
             FROM SO_FEATURES
            WHERE SOF_OFFICE_SERV_FEATS_UID_FK IN (SELECT OSF_UID_PK
                                                     FROM OFFICE_SERV_FEATS, FEATURES
                                                    WHERE FTP_UID_PK = OSF_FEATURES_UID_FK
                                                      AND FTP_CODE = 'CLEN')
              AND SOF_SO_UID_FK = P_SVO_UID_PK;

          IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
            V_SUCCESS_FL_OSS := 'Y';
      
          ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
            V_SUCCESS_FL_OSS := 'T';
      
          ELSE 
            V_SUCCESS_FL_OSS := INSTALLER_WEB_PKG.FN_OSSGATE_DEPROVISION(P_SVO_UID_PK);   
          END IF;
           
           IF V_SUCCESS_FL_OSS = 'T' THEN --NOT SUCCESSFUL
              V_ERROR := INSTALLER_WEB_PKG.FN_SWT_LOGS_ERROR(P_SVO_UID_PK);
            
           
              RETURN 'Sam deprovisioning success. Ossgate deprovisioning was not successful.  Please call plant.  Error was :'||V_ERROR|| v_msg_suffix;
           		v_return_msg := 'Sam deprovisioning success. Ossgate deprovisioning was not successful.  Please call plant.  Error was :'||V_ERROR|| v_msg_suffix;
							IF P_SVO_UID_PK IS NOT NULL THEN
								 IF v_return_msg IS NOT NULL THEN
										PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
								 END IF;
		 					END IF;
           END IF;
        ELSE
           PR_INSERT_SWT_LOGS(P_SVO_UID_PK, 'TRIAD_XML', 'Triad failed Provisioning to remove the MTA', 'DEPROVISION HSD');
           PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, 'Triad failed Provisioning to remove the MTA');
                
         
           RETURN 'This error may be that the HIGH SPEED service has not been provisioned yet.  Please provision that service and then de-provision if needed'||V_SUCCESS_SAM||' '||V_SAM_MESSAGE|| v_msg_suffix;
           v_return_msg := 'This error may be that the HIGH SPEED service has not been provisioned yet.  Please provision that service and then de-provision if needed'||V_SUCCESS_SAM||' '||V_SAM_MESSAGE|| v_msg_suffix;
					 IF P_SVO_UID_PK IS NOT NULL THEN
					 		IF v_return_msg IS NOT NULL THEN
					 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 		END IF;
		 			 END IF;
        END IF;
     ELSE
        PR_INSERT_SWT_LOGS(P_SVO_UID_PK, 'TRIAD_XML', 'Triad failed Provisioning to remove the MTA', 'DEPROVISION VOICE');
        PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, 'Triad failed Provisioning to remove the MTA');
      
        RETURN 'This error may be that some of the services have not been provisioned yet.  Please provision all services and then de-provision if needed'||V_SUCCESS_SAM||' '||V_SAM_MESSAGE|| v_msg_suffix;
     		v_return_msg := 'This error may be that some of the services have not been provisioned yet.  Please provision all services and then de-provision if needed'||V_SUCCESS_SAM||' '||V_SAM_MESSAGE|| v_msg_suffix;
				IF P_SVO_UID_PK IS NOT NULL THEN
					 IF v_return_msg IS NOT NULL THEN
							PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 END IF;
		 		END IF;
     END IF;
  ELSIF V_STY_SYSTEM_CODE = 'BBS' THEN
     OPEN GET_USERNAME(P_SVO_UID_PK);
     FETCH GET_USERNAME INTO V_USERNAME;
     CLOSE GET_USERNAME;
     SELECT SAM_SEQ.NEXTVAL INTO V_SAM_SEQ FROM DUAL;
     V_SAM_USER_NAME     := 'PCMTA'||V_SAM_SEQ;
     IF V_SOT_CODE = 'NS' AND FN_CHECK_USERNAME_NOT_EXISTS(P_SVO_UID_PK,V_SVC_UID_PK) THEN --PREVIOUSLY A CABLE MODEM SO DO NOT DEPROVISION HSD
     
        IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
          V_SUCCESS_SAM := 'SUCCESS';
      
        ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
          V_SUCCESS_SAM := 'ERROR';
      
        ELSE   
          
	     v_success_sam := provision_triad_service_fun(v_mta_uid_pk,'P',v_job_number);
        END IF;
        
        IF V_SUCCESS_SAM = 'SUCCESS' THEN
           PR_INSERT_SWT_LOGS(P_SVO_UID_PK, 'TRIAD_XML', 'SUCCESS - Job '||v_job_number, 'DEPROVISION HSD', 'Y');
  		ELSE
  			PR_INSERT_SWT_LOGS(V_SVO_UID_PK, 'TRIAD_XML', 'Triad failed Provisioning to remove the MTA - Job '||v_job_number, 'DEPROVISION HSD', 'Y');
        END IF;
        V_DEPROV_FL   := 'Y';
     ELSE
        V_SUCCESS_SAM    := 'SUCCESS';
     END IF;

     IF V_SUCCESS_SAM = 'SUCCESS' THEN
        FOR REC IN OTHER_SO(V_CUS_UID_PK, V_MTA_UID_PK) LOOP
            IF REC.STY_SYSTEM_CODE = 'PHN' THEN
               IF NOT FN_NISV_ON_ORDER(REC.SVO_UID_PK) THEN
                   --ALSO ADD 'NISV' PER REQUEST FROM RANDALL
                  OPEN GET_PLNT_INFO(1, V_BSO_UID_PK, 'NISV');
                  FETCH GET_PLNT_INFO INTO V_OSF_UID_PK;
                  CLOSE GET_PLNT_INFO;

                 --INSERT WITH ACTION FLAG OF 'A' WITH THE NISVCODE
                 INSERT INTO SO_FEATURES(SOF_UID_PK, SOF_SO_UID_FK, SOF_OFFICE_SERV_FEATS_UID_FK, SOF_QUANTITY, SOF_COST, SOF_ACTION_FL,
                                SOF_ANNUAL_CHARGE_FL, SOF_INITIAL_CHARGE_FL, SOF_RECORDS_ONLY_FL, SOF_SERVICE_CHARGE_FL, SOF_EXT_NUM_CHG_FL,
                                SOF_COMPLETED_FL, SOF_HAND_RATED_AMOUNT, SOF_OLD_QUANTITY, SOF_WARR_START_DATE, SOF_WARR_END_DATE)
                         VALUES(SVF_SEQ.NEXTVAL, REC.SVO_UID_PK, V_OSF_UID_PK, 1, 0,
                                'A', 'N', 'N', 'N', 'Y','N','N', NULL,0, NULL, NULL);
               END IF;
     
              IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
                V_SUCCESS_SAM := 'SUCCESS';
      
              ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
                V_SUCCESS_SAM := 'ERROR';
      
              ELSE 
                NULL;
                --V_SUCCESS_SAM    := PACKETCABLE_FQDN.deprovision_voice(P_CMAC_MAC, V_SAM_MESSAGE, V_SAM_FQDN);  ----USE WEB SERVICE REFRESH WITH P TYPE
              END IF;
              
                  PR_INSERT_SWT_LOGS(REC.SVO_UID_PK, 'TRIAD_XML', 'SUCCESS', 'DEPROVISION VOICE', 'Y');
                  V_PHN_ALRDY_DEPROV := 'Y';
                  OPEN MTA_SO_PK(REC.SVO_UID_PK);
                  FETCH MTA_SO_PK INTO V_MTO_UID_PK;
                  IF MTA_SO_PK%FOUND THEN
                     UPDATE MTA_SO
                        SET MTO_UID_# = '1'
                      WHERE MTO_UID_PK = V_MTO_UID_PK;
                  END IF;
                  CLOSE MTA_SO_PK;

                  DELETE
                    FROM SO_FEATURES
                   WHERE SOF_OFFICE_SERV_FEATS_UID_FK IN (SELECT OSF_UID_PK
                                                            FROM OFFICE_SERV_FEATS, FEATURES
                                                           WHERE FTP_UID_PK = OSF_FEATURES_UID_FK
                                                             AND FTP_CODE = 'CLEN')
                     AND SOF_SO_UID_FK = REC.SVO_UID_PK;
                     
                  IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
                    V_SUCCESS_FL_OSS := 'Y';
      
                  ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
                    V_SUCCESS_FL_OSS := 'T';
      
                  ELSE 
                    V_SUCCESS_FL_OSS := INSTALLER_WEB_PKG.FN_OSSGATE_DEPROVISION(REC.SVO_UID_PK); 
                  END IF;
                  
                  IF V_SUCCESS_FL_OSS = 'T' THEN --NOT SUCCESSFUL
                     V_ERROR := INSTALLER_WEB_PKG.FN_SWT_LOGS_ERROR(REC.SVO_UID_PK);
                   
                  
                     RETURN 'Ossgate deprovisioning was not successful.  Please call plant.  Error was :'||V_ERROR|| v_msg_suffix;
                  END IF;
            END IF;
        END LOOP;
     ELSE
        PR_INSERT_SWT_LOGS(P_SVO_UID_PK, 'TRIAD_XML', 'Triad failed Provisioning to remove the MTA', 'DEPROVISION HSD');
        PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, V_SUCCESS_SAM||' '||V_SAM_MESSAGE);
      
     
        RETURN 'Triad deprovisioning was not successful. Phone deprovisioning not done.  '||'Triad failed Provisioning to remove the MTA'||' Please call plant.'|| v_msg_suffix;
     		v_return_msg := 'Triad deprovisioning was not successful. Phone deprovisioning not done.  '||'Triad failed Provisioning to remove the MTA'||' Please call plant.'|| v_msg_suffix;
				IF P_SVO_UID_PK IS NOT NULL THEN
					 IF v_return_msg IS NOT NULL THEN
							PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 END IF;
		 		END IF;
     
     END IF;
  END IF;

  --THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

  IF V_EQUIP_TYPE = 'E' THEN
     UPDATE MTA_EQUIP_UNITS
        SET MEU_REMOVE_MTA_FL = 'Y',
            meu_mta_boxes_uid_fk = null
      WHERE MEU_UID_PK = P_MEU_UID_PK;

     INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                         VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE MTA '||P_MTA_MAC||' WAS REMOVED BY TECHNICIAN '||V_EMP_NAME);
  END IF;

  COMMIT;

  IF P_REUSE_FL = 'Y' THEN
     V_STATUS := 'REMOVE INSTALLATION';
  ELSE
     V_STATUS := 'REMOVE INSTALLATION BAD';
  END IF;

  BOX_MODEM_PKG.PR_REMOVE_ACCT(P_MTA_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, V_STATUS, V_IVL_UID_PK);
  COMMIT;

  IF V_DEPROV_FL = 'Y' THEN
     RETURN 'MTA SUCESSFULLY REMOVED FROM THE ACCOUNT AND DE-PROVISIONED'|| v_msg_suffix;
     v_return_msg := 'MTA SUCESSFULLY REMOVED FROM THE ACCOUNT AND DE-PROVISIONED'|| v_msg_suffix;
		 IF P_SVO_UID_PK IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
     
  ELSE
     RETURN 'MTA SUCESSFULLY REMOVED FROM THE ACCOUNT'|| v_msg_suffix;
     v_return_msg := 'MTA SUCESSFULLY REMOVED FROM THE ACCOUNT'|| v_msg_suffix;
		 IF P_SVO_UID_PK IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
     
  END IF;

END FN_REMOVE_EMTA;

/*-------------------------------------------------------------------------------------------------------------*/
-- to add and provision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
FUNCTION FN_SWAP_EMTA(P_OLD_SERIAL# IN VARCHAR, P_NEW_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S')
 
  
  RETURN VARCHAR

  IS

  CURSOR GET_TECH_LOCATION IS
   SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
     FROM TECH_EMP_LOCATIONS, EMPLOYEES
    WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
      AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
      AND TEO_END_DATE IS NULL;

  CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
    SELECT IVL_UID_PK
      FROM INVENTORY_LOCATIONS
     WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

  CURSOR GET_IDENTIFIER IS
    SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
           SVC_UID_PK,
           TRT_UID_PK,
           SVC_OFF_SERV_SUBS_UID_FK,
           SVC_FEATURES_UID_FK,
           OST_SERVICE_TYPES_UID_FK,
           OST_BUSINESS_OFFICES_UID_FK,
           STY_SYSTEM_CODE
    FROM SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, TROUBLE_TICKETS, TROUBLE_DISPATCHES
    WHERE TDP_UID_PK = P_TDP_UID_PK
      AND TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND SVC_UID_PK = TRT_SERVICES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK;

  CURSOR GET_PLNT_INFO(P_STY_UID_PK IN NUMBER, P_BSO_UID_PK IN NUMBER) IS
  SELECT OSF_UID_PK
    FROM OFFICE_SERV_FEATS, OFFICE_SERV_TYPES, FEATURES
   WHERE OST_UID_PK = OSF_OFFICE_SERV_TYPES_UID_FK
     AND FTP_UID_PK = OSF_FEATURES_UID_FK
     AND FTP_CODE = 'PLNT'
     AND OST_BUSINESS_OFFICES_UID_FK = P_BSO_UID_PK
     AND OST_SERVICE_TYPES_UID_FK = P_STY_UID_PK;

   cursor get_slo(p_svc_uid_pk in number) is
          select ssl_service_locations_uid_fk
            from service_locations, serv_serv_locations, services
           where ssl_services_uid_fk = svc_uid_pk
             and slo_uid_pk = ssl_service_locations_uid_fk
             and ssl_primary_loc_fl = 'Y'
             and ssl_end_date is null
             and svc_uid_pk = p_svc_uid_pk;
             
             
   

   cursor get_meu_type (p_svc_uid_pk in number) is
   SELECT DISTINCT MTY_SYSTEM_CODE, MTY_UID_PK ------MEU_MTA_TYPES_UID_FK - HD 104876 RMC 03/31/2011
     FROM MTA_EQUIP_UNITS, MTA_PORTS, MTA_TYPES, MTA_SERVICES, SERVICE_ASSGNMTS
    WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND MTY_UID_PK = MEU_MTA_TYPES_UID_FK
      AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
      AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
      AND SVA_SERVICES_UID_FK = p_svc_uid_pk;
      
  

  CURSOR GET_MTA_TYPE(P_MTA_UID_PK IN NUMBER) IS
    SELECT MTY_SYSTEM_CODE, MTY_UID_PK ---,MTA_MTA_TYPES_UID_FK - HD 104876 RMC 03/31/2011
      FROM MTA_BOXES, MTA_TYPES
     WHERE MTY_UID_PK = MTA_MTA_TYPES_UID_FK
    AND MTA_UID_PK = P_MTA_UID_PK;

   cursor get_svcs_with_box_loc (p_mta_uid_pk in number, p_slo_uid_pk in number) is
   SELECT DISTINCT SVC_UID_PK, GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK) IDENTIFIER, STY_SYSTEM_CODE
     FROM SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOCATIONS, MTA_EQUIP_UNITS, MTA_PORTS, MTA_SERVICES, SERVICE_ASSGNMTS
    WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
      AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
      AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND MEU_MTA_BOXES_UID_FK = p_mta_uid_pk
      AND SVC_UID_PK = SVA_SERVICES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND SVC_UID_PK = SSL_SERVICES_UID_FK
      AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
      AND SSL_END_DATE IS NULL
      AND SSL_PRIMARY_LOC_FL = 'Y';
      
  CURSOR CHECK_EXIST_PEND_CS (P_SVC_UID_PK IN NUMBER) IS
	  SELECT 'X'
	    FROM SO, SO_STATUS, SO_TYPES
	   WHERE SOS_UID_PK = SVO_SO_STATUS_UID_FK
	     AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED')
	     AND SVO_SERVICES_UID_FK = P_SVC_UID_PK
	     AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
       AND SOT_SYSTEM_CODE = 'CS';

  V_IVL_UID_PK           NUMBER;
  V_SVO_UID_PK           NUMBER;
  V_SVC_UID_PK           NUMBER;
  V_MEU_MTY_UID_FK       NUMBER;
  V_MTA_MTY_UID_FK       NUMBER;
  V_TVB_UID_PK           NUMBER;
  V_TRT_UID_PK           NUMBER;
  V_OSB_UID_PK           NUMBER;
  V_OSF_UID_PK           NUMBER;
  V_SLO_UID_PK           NUMBER;
  V_FTP_BUN_UID_PK       NUMBER;
  V_BBS_MES_UID_PK       NUMBER;
  V_STY_UID_PK           NUMBER;
  V_BSO_UID_PK           NUMBER;
  V_MEO_UID_PK           NUMBER;
  V_BBO_UID_PK           NUMBER;
  V_OPERATING_SYSTEM_ID  VARCHAR2(200);
  V_LAST_IVL_UID_PK      NUMBER;
  V_OST_UID_PK           NUMBER;
  V_SVT_CODE             VARCHAR2(40);
  V_OLD_MTA              VARCHAR2(40);
  V_OLD_CMAC             VARCHAR2(40);
  V_NEW_MTA              VARCHAR2(40);
  V_NEW_CMAC             VARCHAR2(40);
  V_LAST_IVL_DESCRIPTION VARCHAR2(200);
  V_EQUIP_TYPE_OLD       VARCHAR2(1);
  V_EQUIP_TYPE_NEW       VARCHAR2(1);
  V_MTA_UID_PK           NUMBER;
  V_MTA_UID_PK_NEW       NUMBER;
  V_STATUS               VARCHAR2(200);
  V_DUMMY                VARCHAR2(1);
  V_SUCCESS_FL           VARCHAR2(1);
  V_CABLE_MODEM_TYPE     VARCHAR2(1);
  V_TIME                 VARCHAR2(200);
  V_RETURN_MESSAGE       VARCHAR2(2000) := NULL;
  V_IDENTIFIER           VARCHAR2(200);
  V_IDENTIFIER_DISPLAY   VARCHAR2(200) := NULL;
  V_DESCRIPTION          VARCHAR2(200);
  V_EMP_NAME             VARCHAR2(200);
  V_ACCOUNT              VARCHAR2(200);
  V_RSU_#                VARCHAR2(40);
  V_STY_SYSTEM_CODE      VARCHAR2(40);
  V_NEW_CM_MAC           VARCHAR2(40);
  V_NEW_MTA_MAC          VARCHAR2(40);
  V_OLD_CM_MAC           VARCHAR2(40);
  V_OLD_MTA_MAC          VARCHAR2(40);
  V_MAC_MESSAGE          VARCHAR2(2000);
  V_PEND_CS_FOUND_FL     VARCHAR2(1);

  v_is_production_database  VARCHAR2(1);
  v_msg_suffix           VARCHAR2(100);
  
  V_MTA_TYPE_ASSGNMTS_UID_PK 	NUMBER;
  V_MTA_TYPE_SCANNED_UID_PK		NUMBER;
  
  V_MTA_TYPE_ASSGNMTS         VARCHAR2(40);
	V_MTA_TYPE_SCANNED          VARCHAR2(40);
	
	V_MLH_MESSAGE      					VARCHAR2(500);
	V_MLH_FOUND_FL							VARCHAR2(1) := 'N';
	
	v_return_msg  		VARCHAR2(4000);

	V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_SWAP_EMTA';

  
BEGIN

  --GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
  OPEN GET_TECH_LOCATION;
  FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
  CLOSE GET_TECH_LOCATION;

  OPEN GET_IDENTIFIER;
  FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK, V_TRT_UID_PK, V_OSB_UID_PK, V_FTP_BUN_UID_PK, V_STY_UID_PK, V_BSO_UID_PK, V_STY_SYSTEM_CODE;
  CLOSE GET_IDENTIFIER;

  open get_slo(V_SVC_UID_PK);
  fetch get_slo into v_slo_uid_pk;
  close get_slo;

  IF V_IVL_UID_PK IS NULL THEN
     BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
     RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
  END IF;

  --***********************************************
  --CHECK TO REMOVE THE OLD SERIAL/MAC ADDRESS
  --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE_OLD := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_OLD_SERIAL#, V_MTA_UID_PK);


  --NOT FOUND
  IF V_EQUIP_TYPE_OLD  = 'N' THEN
     IF P_OLD_SERIAL# IS NOT NULL THEN
        BOX_MODEM_PKG.PR_EXCEPTION(P_OLD_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO REMOVE A BOX/MODEM FROM '||V_IDENTIFIER||' '||P_OLD_SERIAL#||' IS NOT FOUND IN THE SYSTEM');
        RETURN 'OLD SERIAL# '||P_OLD_SERIAL#||' NOT FOUND';
     END IF;
  END IF;

  --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE_NEW := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_NEW_SERIAL#, V_MTA_UID_PK_NEW);

  --NOT FOUND
  IF V_EQUIP_TYPE_NEW  = 'N' THEN
     BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A MTA TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND IN THE SYSTEM');
     RETURN 'SERIAL# '||P_NEW_SERIAL#||' NOT FOUND.  PLEASE MAKE SURE IT WAS ENTERED CORRECTLY.';
  END IF;

  --BOX STATUS CHECK
  V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_NEW_SERIAL#, V_EQUIP_TYPE_NEW, V_DESCRIPTION);
  IF V_STATUS NOT IN ('AN','AU','RT') THEN
     BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A MTA TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_STATUS);
     V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_NEW_SERIAL#);
     --IF V_ACCOUNT IS NOT NULL THEN
        --V_DESCRIPTION := V_DESCRIPTION||' ON '||V_ACCOUNT;
     --END IF;
     RETURN 'MTA '||P_NEW_SERIAL#||' IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
  END IF;

  --LOCATION CHECK
  IF V_IVL_UID_PK IS NOT NULL THEN
     V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_NEW_SERIAL#);
     OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
     FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
     CLOSE LAST_LOCATION;

     IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
        IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
           BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A BOX/MODEM TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND ON THE TECHS TRUCK');
           RETURN 'MTA '||P_NEW_SERIAL#||' IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
        END IF;
     END IF;
  END IF;
  
  

  OPEN GET_MEU_TYPE(V_SVC_UID_PK);
  FETCH GET_MEU_TYPE INTO V_MTA_TYPE_ASSGNMTS,V_MTA_TYPE_ASSGNMTS_UID_PK; ---V_MEU_MTY_UID_FK; ---HD 104876 RMC 03/31/2011
  CLOSE GET_MEU_TYPE;
  
  
  OPEN GET_MTA_TYPE(V_MTA_UID_PK_NEW);
  FETCH GET_MTA_TYPE INTO V_MTA_TYPE_SCANNED, V_MTA_TYPE_SCANNED_UID_PK;---,V_MTA_MTY_UID_FK;---HD 104876 RMC 03/31/2011
  CLOSE GET_MTA_TYPE;
  
  
  ---HD 104876 RMC 03/31/2011 - Change to check if the MTA type on the MTA_EQUIP_UNITS is 728996 and the MTA type scanned in
	---                           is 780149 then bypass the check and allow the scanning to continue. The MEU_EQUIP_UNITS
	---                           will be updated with the MTA type from the scanned MTA. This was requested because customers are 
	---                           upgrading their HSD and requires a DOCSIS 3.0 Box (type = 780149). and the default MTA type is 728996.This stopped 
	---                           the tech in the field and the HD had to manually change the MTA type.
	
	---IF V_MEU_MTY_UID_FK != V_MTA_MTY_UID_FK THEN --- HD 104876 RMC 03/31/2011 Commented out
	      ---RETURN 'THE MTA BOX TYPE MUST EQUAL THE TYPE REQUESTED FOR THIS ORDER.'; --- HD 104876 RMC 03/31/2011 Commented out
	---END IF; --- HD 104876 RMC 03/31/2011 Commented out
	
	
	---HD 109538 RMC 07/18/2011 - No longer need to compare the MTA TYPE in MTA Equipment records to 
  ---                           the MTA TYPE scanned in. The MTA Equipment records will be updated with
  ---                           MTA TYPE from the scanned MTA Modem. Lines commented out.
	 
	    /*IF V_MTA_TYPE_ASSGNMTS_UID_PK !=  V_MTA_TYPE_SCANNED_UID_PK THEN
			   IF V_MTA_TYPE_ASSGNMTS = '728996' THEN
			      IF V_MTA_TYPE_SCANNED in ('780149','785196') THEN ---HD 109009 RMC 07/06/2011 - Added mta type of '785196' to be checked
			         NULL;
			      ELSE
			         RETURN 'THE MTA BOX TYPE SCANNED '||P_NEW_SERIAL#||' MUST EQUAL THE BOX TYPE ON THE MTA EQUIPMENT UNITS.';
			      END IF;
			   ELSIF V_MTA_TYPE_ASSGNMTS = '780149' THEN
			         IF V_MTA_TYPE_SCANNED in ('728996', '785196') THEN  ---HD 109009 RMC 07/06/2011 - Added mta type of '785196' to be checked
			            NULL;
			         ELSE
			            RETURN 'THE MTA BOX TYPE SCANNED '||P_NEW_SERIAL#||' MUST EQUAL THE BOX TYPE ON THE MTA EQUIPMENT UNITS.';
			         END IF;
			   END IF;
      END IF;*/

  INSERT INTO SERVICE_MESSAGES(SVM_UID_PK, SVM_SERVICES_UID_FK, SVM_ENTERED_BY, SVM_DATE, SVM_TIME, SVM_TEXT, SVM_ACTIVE_FL)
                           VALUES(SVM_SEQ.NEXTVAL, V_SVC_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE MTA '||P_OLD_SERIAL#||' WAS REMOVED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' BY TECHNICIAN '||V_EMP_NAME, 'Y');

  --********************END WITH THE OLD BOX/MODEM************************--

  -- set up flag for database and success message to be appended for developemnt
  GET_RUN_ENVIRONMENT(P_DEVELOPMENT_ACTION,
                      v_is_production_database,
                      v_msg_suffix);

  --*********************************************
  --check for the addition of the new serial#

  --THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

  --ADD THE NEW SERIAL
  IF V_EQUIP_TYPE_NEW = 'E' THEN

   --HD 102159 RMC 01/20/2011 - Modification to check for a existing pending CS service order
   --                           and return message to IWP before attempting to change the CMAC
   --                           in ALOPA(INSTALLER_WEB_PKG.FN_SAM_MAC_CHANGE). This will insure that 
   --                           the any open CS SO's will be closed prior to provisioning.

   FOR SVC_REC IN get_svcs_with_box_loc(V_MTA_UID_PK, V_SLO_UID_PK) LOOP
   
     --CHECK FOR EXISTING PENDING CS ORDER
		 OPEN CHECK_EXIST_PEND_CS(SVC_REC.SVC_UID_PK);
		 FETCH CHECK_EXIST_PEND_CS INTO V_PEND_CS_FOUND_FL;
		 IF CHECK_EXIST_PEND_CS%FOUND THEN
		    CLOSE CHECK_EXIST_PEND_CS;
		    RETURN 'A PENDING CS ORDER ALREADY EXISTS FOR THIS SERVICE AND THE SWAP CANNOT BE COMPLETED CONTACT PLANT.';
		 END IF;
		 CLOSE CHECK_EXIST_PEND_CS;
	 
	 END LOOP;
    
    BOX_MODEM_PKG.PR_MTA_MACS(P_OLD_SERIAL#, V_OLD_MTA_MAC, V_OLD_CM_MAC);
    BOX_MODEM_PKG.PR_MTA_MACS(P_NEW_SERIAL#, V_NEW_MTA_MAC, V_NEW_CM_MAC);     
                 
    IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
      V_MAC_MESSAGE := 'Y';
      
    ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
      V_MAC_MESSAGE := 'ERROR';
      
    ELSE 
      PR_UPDATE_MTA(V_SVC_UID_PK, V_MTA_UID_PK_NEW, V_MTA_UID_PK, V_MTA_TYPE_SCANNED_UID_PK); -- HD 104876 RMC 04/1/2011 - added V_MTA_TYPE_SCANNED_UID_PK
      COMMIT;
      C_SVC_UID_PK := V_SVC_UID_PK;
      C_SVO_UID_PK := NULL;
      V_MAC_MESSAGE := INSTALLER_WEB_PKG.FN_SAM_MAC_CHANGE(V_OLD_CM_MAC, V_NEW_CM_MAC, V_NEW_MTA_MAC);  --USE WEB SERVICE REFRESH WITH P TYPE
    END IF;
    
    IF V_MAC_MESSAGE != 'Y' THEN
      
      
       RETURN 'Error in Triad.  '||V_MAC_MESSAGE||' Please call plant.'|| v_msg_suffix;
    END IF;

    FOR SVC_REC IN get_svcs_with_box_loc(V_MTA_UID_PK_NEW, V_SLO_UID_PK) LOOP

      INSTALLER_WEB_PKG.CREATE_CS_ORDER(SVC_REC.SVC_UID_PK, P_EMP_UID_PK, NULL, NULL, V_SVO_UID_PK, V_RSU_#, V_NEW_CM_MAC);

      COMMIT;
      IF V_SVO_UID_PK IS NOT NULL THEN
         PR_INSERT_SWT_LOGS(V_SVO_UID_PK, 'TRIAD_XML', 'SUCCESS', 'CHANGE MAC', 'Y'); 
         
         INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                             VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE MTA '||P_NEW_SERIAL#||' WAS ADDED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' BY TECHNICIAN '||V_EMP_NAME);
         
         ---HD 106376 RMC 07/19/2011 - Added the below code to insert message that CS is for Swap to complete provisioning and do not clear/close
         ---                           until the provisioning is complete.
         INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                             VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'CS SO IS FOR PROVISIONING THE SWAP/MAC ADDRESS CHANGE OF THE MODEM. DO NOT CLEAR/CLOSE UNTIL THE PROVISIONING HAS BEEN COMPLETED.');
         
      ELSE
         RETURN 'A PENDING CS ORDER ALREADY EXISTS FOR THIS SERVICE AND THE SWAP CANNOT BE COMPLETED.  PLEASE CALL PLANT TO LOAD YOU TO THE CS ORDER.'|| v_msg_suffix;
      END IF;

      INSERT INTO SERVICE_MESSAGES (SVM_UID_PK, SVM_SERVICES_UID_FK, SVM_ACTIVE_FL, SVM_DATE,
                                    SVM_TIME, SVM_TEXT, SVM_ENTERED_BY)
                             VALUES(SVM_SEQ.NEXTVAL, SVC_REC.SVC_UID_PK, 'Y', SYSDATE, SYSDATE,
                                    'THE MTA FOR THE SERVICE HAS BEEN REPLACED USING THE SWAP FEATURE ON IWP FOR TROUBLE TICKET '||V_TRT_UID_PK||'.  THE OLD MTA MAC WAS '||P_OLD_SERIAL#||' AND THE NEW MTA MAC IS '||P_NEW_SERIAL#||'.', USER);

      IF SVC_REC.STY_SYSTEM_CODE = 'PHN' THEN
         --CHANGE MAC ADDRESS IN SAM
         IF  v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
           V_SUCCESS_FL := 'Y';
      
         ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
           V_SUCCESS_FL := 'T';
         ELSE 
           
           --- HD 105771 RMC 05/03/2011 - MLH Processing
           V_MLH_MESSAGE := INSTALLER_WEB_PKG.FN_MLH_CHECK(V_SVO_UID_PK); 
					 IF V_MLH_MESSAGE IS NULL THEN 
					    V_MLH_FOUND_FL := 'N';
              V_SUCCESS_FL := INSTALLER_WEB_PKG.FN_OSSGATE_DEPROVISION(V_SVO_UID_PK); 
           ELSE  
              V_MLH_FOUND_FL := 'Y';   
           END IF;  
           
         END IF;
         
         IF V_SUCCESS_FL = 'T' THEN  --OSSGATE DEPROVISIONING SUCCESSFUL
         
            -- HD 104876 RMC 04/1/2011 - added V_MTA_TYPE_SCANNED_UID_PK
            PR_UPDATE_MTA(V_SVC_UID_PK, V_MTA_UID_PK, V_MTA_UID_PK_NEW, V_MTA_TYPE_SCANNED_UID_PK);  --SWITCH BACK IF PROVISIONING FAILED
            COMMIT;
            V_ERROR := INSTALLER_WEB_PKG.FN_SWT_LOGS_ERROR(V_SVO_UID_PK);
            

            RETURN 'PROVISIONING ERROR OCCURED IN OSSGATE.  PLEASE CALL PLANT.  ERROR WAS :'||V_ERROR|| v_msg_suffix;
         		v_return_msg := 'PROVISIONING ERROR OCCURED IN OSSGATE.  PLEASE CALL PLANT.  ERROR WAS :'||V_ERROR|| v_msg_suffix;
						IF V_SVO_UID_PK IS NOT NULL THEN
							 IF v_return_msg IS NOT NULL THEN
								 	PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
							 END IF;
		 				END IF;
         END IF;
      END IF;

      UPDATE SO
         SET SVO_SO_STATUS_UID_FK = (SELECT SOS_UID_PK FROM SO_STATUS WHERE SOS_SYSTEM_CODE = 'RDY TO CLOSE')
       WHERE SVO_UID_PK = V_SVO_UID_PK;

    END LOOP;

  END IF;

  
  --- HD 105771 RMC 05/03/2011 - MLH Processing
  IF V_MLH_FOUND_FL = 'N' THEN
     V_RETURN_MESSAGE := 'SWAP COMPLETED SUCCESSFULLY.'|| v_msg_suffix;
     v_return_msg := 'SWAP COMPLETED SUCCESSFULLY.'|| v_msg_suffix;
		 IF V_SVO_UID_PK IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 			 PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
  ELSE
     V_RETURN_MESSAGE := 'THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR THE CABLE MODEM IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.';
     v_return_msg := 'THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR CABLE MODEM IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.';
		 IF V_SVO_UID_PK IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
     ---HD 111020 RMC 08/25/2011 - Added the below code to insert message service order is for multi line hunt and call CO to provision the phone portion.
		             
		 INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
		                  VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR ALOPA IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.'); 
     COMMIT;
  END IF;
  
  ---V_RETURN_MESSAGE := 'SWAP COMPLETED SUCCESSFULLY.'|| v_msg_suffix; --- HD 105771 RMC 05/03/2011
  
  IF V_LAST_IVL_DESCRIPTION = 'LOCATION NOT FOUND' THEN --ALSO ADD A RECORD TO ISSUE AN AUTO RECEIVE IN, INTO THE TECH TRUCK LOCATION
     BOX_MODEM_PKG.PR_RECEIVE_STB_INTO_INV(P_NEW_SERIAL#, V_IVL_UID_PK, NULL, NULL);
  END IF;

  BOX_MODEM_PKG.PR_REMOVE_ACCT(P_OLD_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, 'REPAIR INSTALLATION', V_IVL_UID_PK);
  BOX_MODEM_PKG.PR_ADD_ACCT(P_NEW_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, 'ADD ACCT WEB');

  COMMIT;

  RETURN V_RETURN_MESSAGE;

END FN_SWAP_EMTA;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE CREATE_CS_ORDER(P_SVC_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_PORT IN NUMBER,
                          P_MTY_UID_PK IN NUMBER, P_SVO_UID_PK OUT NUMBER, P_RSU_# OUT VARCHAR, P_NEW_MTAMAC IN VARCHAR)

IS

CURSOR CHECK_EXIST_PEND_CS IS
  SELECT 'X'
    FROM SO, SO_STATUS, SO_TYPES
   WHERE SOS_UID_PK = SVO_SO_STATUS_UID_FK
     AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED')
     AND SVO_SERVICES_UID_FK = P_SVC_UID_PK
     AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
     AND SOT_SYSTEM_CODE = 'CS';

CURSOR GET_TECH IS
 SELECT EMP_FNAME||' '||EMP_LNAME
   FROM EMPLOYEES
  WHERE EMP_UID_PK = P_EMP_UID_PK;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
         STY_SYSTEM_CODE,
         SVC_OFF_SERV_SUBS_UID_FK,
         SVC_FEATURES_UID_FK,
         OST_SERVICE_TYPES_UID_FK,
         OST_BUSINESS_OFFICES_UID_FK,
         BSO_SYSTEM_CODE,
         SVT_CODE,
         OST_UID_PK
  FROM SERVICES, OFFICE_SERV_TYPES, OFF_SERV_SUBS, SERV_SUB_TYPES, BUSINESS_OFFICES, SERVICE_TYPES
  WHERE svc_UID_PK = P_svc_UID_PK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND BSO_UID_PK = OST_BUSINESS_OFFICES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND OSB_UID_PK = SVC_OFF_SERV_SUBS_UID_FK
    AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK;

CURSOR GET_SERVICE_FEATURES IS
  SELECT *
    FROM SERVICE_FEATURES
   WHERE SVF_SERVICES_UID_FK = P_SVC_UID_PK
     AND SVF_END_DATE IS NULL;

CURSOR GET_SERV_LOCATIONS IS
  SELECT *
    FROM SERV_SERV_LOCATIONS
   WHERE SSL_SERVICES_UID_FK = P_SVC_UID_PK
     AND SSL_END_DATE IS NULL;

CURSOR GET_LATAS IS
  SELECT *
    FROM LATAS
   WHERE LTA_SERVICES_UID_FK = P_SVC_UID_PK
     AND LTA_END_DATE IS NULL;

CURSOR GET_PHONE IS
  SELECT *
    FROM PHONE_SERVICES
   WHERE PHS_SERVICES_UID_FK = P_SVC_UID_PK;

CURSOR GET_LINE# IS
  SELECT *
    FROM LINE#_SERVICES
   WHERE LSV_SERVICES_UID_FK = P_SVC_UID_PK
     AND LSV_END_DATE IS NULL;
     
CURSOR GET_ROUTER IS
  SELECT *
    FROM ROUTER_SERVICES
   WHERE RSV_SERVICES_UID_FK = P_SVC_UID_PK;
   
CURSOR GET_CPE IS
  SELECT *
    FROM CPE_SERVICES
   WHERE CPS_SERVICES_UID_FK = P_SVC_UID_PK;

CURSOR GET_PLNT_INFO(P_STY_UID_PK IN NUMBER, P_BSO_UID_PK IN NUMBER, P_FTP_CODE IN VARCHAR) IS
SELECT OSF_UID_PK
  FROM OFFICE_SERV_FEATS, OFFICE_SERV_TYPES, FEATURES
 WHERE OST_UID_PK = OSF_OFFICE_SERV_TYPES_UID_FK
   AND FTP_UID_PK = OSF_FEATURES_UID_FK
   AND FTP_CODE = P_FTP_CODE
   AND OST_BUSINESS_OFFICES_UID_FK = P_BSO_UID_PK
   AND OST_SERVICE_TYPES_UID_FK = P_STY_UID_PK;

   cursor get_int_details is
         select its_user_name,
                its_password,
                its_security_question,
                its_security_answer,
                its_comment,
                its_confirmation_fl,
                its_rad_pending_date,
                its_radius_fl,
                its_training_fl,
                its_pacs_id_no#,
                its_expiration_date
           from internet_services
          where its_services_uid_fk = p_svc_uid_pk;

CURSOR GET_ASSGN_MTA IS
  SELECT SVA_SERVICE_LOCATIONS_UID_FK,
         SVA_SAI_UID_FK,
         SVA_DSX_CONNECTIONS_UID_FK,
         SVA_LENS_UID_FK,
         SVA_NC_CODES_UID_FK,
         SVA_NCI_CODES_UID_FK,
         SVA_SUBTYPE_CODES_UID_FK,
         SVA_LEAD_ROUTES_UID_FK,
         SVA_CLLIS_UID_FK,
         SVA_AREAS_UID_FK,
         SVA_LINE#,
         SVA_OPX,
         SVA_BNN_PHONE#,
         SVA_BAND,
         SVA_WIRE,
         SVA_REMARKS,
         SVA_PEDESTAL,
         SVA_PROTECTOR,
         SVA_DSLAM_PORTS_UID_FK,
         SVA_ADSL_MODEMS_UID_FK,
         SVA_DSX3_CONNECTIONS_UID_FK,
         SVA_BONDED_FL,
         SVA_HSD_FL,
         SVA_UID_PK,
         MSS_SAM_IDENTIFIER,
         MSS_MTA_PORTS_UID_FK,
         MTP_MTA_EQUIP_UNITS_UID_FK
     FROM SERVICE_ASSGNMTS, MTA_SERVICES, mta_ports
    WHERE SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
      AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
      AND SVA_SERVICES_UID_FK = P_SVC_UID_PK;

CURSOR GET_WORK_FUNCTION (P_BSO_CODE IN VARCHAR) IS
 SELECT WFC_UID_PK
  FROM WORK_FUNCTIONS, FUNCTIONS, WORKCENTERS
  WHERE FTN_UID_PK = WFC_FUNCTIONS_UID_FK
    AND WCR_UID_PK = WFC_WORKCENTERS_UID_FK
    AND WCR_CODE = 'NETO'
    AND FTN_SYSTEM_CODE = 'REVIEW';

CURSOR GET_CABLE_MODEM_PK IS
 SELECT BBS_UID_PK, 'B', BBS_OPERATING_SYSTEM,
        BBS_INSIDE_WIR_TYPES_UID_FK  IWT_UID_PK
   FROM BROADBAND_SERVICES
  WHERE BBS_SERVICES_UID_FK = P_SVC_UID_PK
 UNION
 SELECT MES_UID_PK, 'M', MES_METRO_ID,
        NULL  IWT_UID_PK
   FROM METRO_SERVICES
  WHERE MES_SERVICES_UID_FK = P_SVC_UID_PK;

CURSOR GET_RSU_INFO(P_SLO_UID_PK IN NUMBER) IS
 SELECT RSU_PEDESTAL, RSU_PROTECTOR, RSU_RSU_#, RSU_LEAD_ROUTES_UID_FK, MSG_FIBER_NODES_UID_FK, NULL PON_UID_PK
   FROM REM_SERV_UNITS, RSU_SERVICES, MRF_SHARING_GROUPS
  WHERE RSS_REM_SERV_UNITS_UID_FK = RSU_UID_PK
    AND RSU_SHARING_GROUPS_UID_FK = MSG_UID_PK
    AND RSU_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
    AND RSU_ACTIVE_FL = 'Y';

CURSOR GET_CLLI IS
 SELECT CLI_UID_PK
   FROM CLLIS
  WHERE CLI_CODE = 'PCG1';

cursor get_count_port is
 select mpd_uid_pk
   from mta_prt_typ_divs,mta_types
  where mpd_mta_types_uid_fk = mty_uid_pk
    and mty_uid_pk = p_mty_uid_pk
    and mpd_required_fl='Y';

cursor get_mpd_ports(p_mpd_uid_pk in number) is
 select mpd_#_of_ports, mpt_code, mpt_uid_pk
   from mta_prt_typ_divs,mta_types,mta_port_types
  where mpd_mta_types_uid_fk = mty_uid_pk
    and mpd_mta_port_types_uid_fk = mpt_uid_pk
    and mty_uid_pk = p_mty_uid_pk
    and mpd_uid_pk = p_mpd_uid_pk;

cursor get_mta_status(p_mst_system_code in varchar) is
 select mst_uid_pk
   from mta_status
  where mst_system_code = p_mst_system_code;

CURSOR GET_PORT(P_STY_SYSTEM_CODE IN VARCHAR, P_MEU_UID_PK IN NUMBER) IS
SELECT MTP_UID_PK
  FROM MTA_PORTS, MTA_EQUIP_UNITS, MTA_PORT_TYPES
 WHERE MEU_UID_PK = P_MEU_UID_PK
   AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
   AND MTP_LINE_NO# = P_PORT
   AND MPT_UID_PK = MTP_MTA_PORT_TYPES_UID_FK
   AND DECODE(MPT_SYSTEM_CODE,'DATA','BBS','TEL','PHN') = P_STY_SYSTEM_CODE;

CURSOR GET_EXISTING_MTA_UNIT (P_SLO_UID_PK IN NUMBER) IS
 SELECT MEU_UID_PK
   FROM MTA_EQUIP_UNITS
  WHERE MEU_SERVICE_LOCATIONS_UID_FK in
                   (select s2.slo_uid_pk
                   from service_locations s1, service_locations s2
                  where s1.slo_uid_pk = P_SLO_UID_PK
                    and s1.slo_municipalities_uid_fk = s2.slo_municipalities_uid_fk
                    and s1.slo_streets_uid_fk = s2.slo_streets_uid_fk
                    and ((s1.slo_street_nums_uid_fk = s2.slo_street_nums_uid_fk and s1.slo_street_nums_uid_fk is not null)
                     or (s2.slo_street_nums_uid_fk is null and s1.slo_street_nums_uid_fk is null))
                    and ((s1.slo_buildings_uid_fk = s2.slo_buildings_uid_fk and s1.slo_buildings_uid_fk is not null)
                     or (s2.slo_buildings_uid_fk is null and s1.slo_buildings_uid_fk is null))
                    and ((s1.slo_building_units_uid_fk = s2.slo_building_units_uid_fk and s1.slo_building_units_uid_fk is not null)
                     or (s2.slo_building_units_uid_fk is null and s1.slo_building_units_uid_fk is null)));

CURSOR GET_SLO IS
  SELECT SSL_SERVICE_LOCATIONS_UID_FK
    FROM SERV_SERV_LOCATIONS
   WHERE SSL_SERVICES_UID_FK = P_SVC_UID_PK
     AND SSL_PRIMARY_LOC_FL = 'Y'
     AND SSL_END_DATE IS NULL;

CURSOR PACKET_CABLE_SUB(P_OST_UID_PK IN NUMBER, P_SVT_SYSTEM_CODE IN VARCHAR) IS
  SELECT OSB_UID_PK
  FROM OFF_SERV_SUBS, SERV_SUB_TYPES
  WHERE SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
    AND SVT_SYSTEM_CODE = P_SVT_SYSTEM_CODE
    AND OSB_OFFICE_SERV_TYPES_UID_FK = P_OST_UID_PK;

V_IVL_UID_PK           NUMBER;
V_WFC_UID_PK           NUMBER;
V_SVO_UID_PK           NUMBER;
V_SON_UID_PK           NUMBER;
V_RSU_#                VARCHAR2(40);
V_LRT_UID_PK           NUMBER;
V_CLI_UID_PK           NUMBER;
V_MPD_UID_PK           NUMBER;
V_FBN_UID_PK           NUMBER;
V_MTP_UID_PK           NUMBER;
V_PEDESTAL             rem_serv_units.rsu_pedestal%type;
V_PROTECTOR            rem_serv_units.rsu_protector%type;
V_STY_SYSTEM_CODE      VARCHAR2(20);
V_TVB_UID_PK           NUMBER;
V_OSB_UID_PK           NUMBER;
V_OSF_UID_PK           NUMBER;
V_SLO_UID_PK           NUMBER;
V_FTP_BUN_UID_PK       NUMBER;
V_BBS_MES_UID_PK       NUMBER;
V_STY_UID_PK           NUMBER;
V_BSO_UID_PK           NUMBER;
V_MEO_UID_PK           NUMBER;
V_BBO_UID_PK           NUMBER;
V_MEU_UID_PK           NUMBER;
V_OPERATING_SYSTEM_ID  VARCHAR2(200);
V_IDENTIFIER_DISPLAY   VARCHAR2(200);
V_OST_UID_PK           NUMBER;
V_SVT_CODE             VARCHAR2(40);
V_BSO_CODE             VARCHAR2(40);
V_MTA_UID_PK           NUMBER;
V_PON_UID_PK           NUMBER;
V_MTA_UID_PK_NEW       NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_PEND_CS_FOUND_FL     VARCHAR2(1);
V_CABLE_MODEM_TYPE     VARCHAR2(1);
V_TIME                 VARCHAR2(200);
V_IDENTIFIER           VARCHAR2(200);
V_DESCRIPTION          VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);
V_ASSIGNMENTS_FOUND_FL VARCHAR2(1) := 'N';
v_mpd_#_of_ports       NUMBER;
v_mta_port_type        VARCHAR2(40);
v_mpt_uid_pk           NUMBER;
v_mst_uid_pk           NUMBER;
V_TYPE                 VARCHAR2(40);
v_iwt_uid_pk           number;

BEGIN

--CHECK FOR EXISTING PENDING CS ORDER
OPEN CHECK_EXIST_PEND_CS;
FETCH CHECK_EXIST_PEND_CS INTO V_PEND_CS_FOUND_FL;
IF CHECK_EXIST_PEND_CS%NOTFOUND THEN
   V_PEND_CS_FOUND_FL := NULL;
END IF;
CLOSE CHECK_EXIST_PEND_CS;

OPEN GET_SLO;
FETCH GET_SLO INTO V_SLO_UID_PK;
CLOSE GET_SLO;

IF V_PEND_CS_FOUND_FL IS NULL THEN --CONTINUE AS NO PENDING CS ORDER IS FOUND
  --TECH NAME
  OPEN GET_TECH;
  FETCH GET_TECH INTO V_EMP_NAME;
  CLOSE GET_TECH;

  OPEN GET_IDENTIFIER;
  FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_STY_SYSTEM_CODE, V_OSB_UID_PK, V_FTP_BUN_UID_PK, V_STY_UID_PK, V_BSO_UID_PK, V_BSO_CODE,
                            V_SVT_CODE, V_OST_UID_PK;
  CLOSE GET_IDENTIFIER;

  IF V_SVT_CODE = 'CABLE MODEM' THEN  --ADDING A MTA BOX TO A PACKET CABLE SUB TYPE ORDER SO SWITCH THE SUB TYPE TO 'CABLE MODEM'.
     V_TYPE := FN_MTA_TYPE(V_SLO_UID_PK);
     OPEN PACKET_CABLE_SUB(V_OST_UID_PK, V_TYPE);
     FETCH PACKET_CABLE_SUB INTO V_OSB_UID_PK;
     CLOSE PACKET_CABLE_SUB;
  END IF;

  SELECT SVO_SEQ.NEXTVAL
    INTO V_SVO_UID_PK
    FROM DUAL;

  --CREATE PLANT CS RECORD FOR TRACKING
  INSERT INTO SO (SVO_UID_PK, SVO_SERVICES_UID_FK, SVO_SO_STATUS_UID_FK, SVO_SO_TYPES_UID_FK, SVO_EMPLOYEES_UID_FK, SVO_CLOSED_BY_EMP_UID_FK, SVO_OFF_SERV_SUBS_UID_FK, SVO_FEATURES_UID_FK, SVO_ADDITIONAL_SERVICE_FL,
                  SVO_NEW_HOUSE_FL, SVO_CONTACT_NAME, SVO_CONTACT_PHONE, SVO_CLOSE_DATE, SVO_CLOSE_TIME)
           VALUES(V_SVO_UID_PK, P_SVC_UID_PK, code_pkg.get_pk('SO_STATUS','RTG'), code_pkg.get_pk('SO_TYPES','CS'), P_EMP_UID_PK, P_EMP_UID_PK, V_OSB_UID_PK, V_FTP_BUN_UID_PK,'Y', 'N', V_EMP_NAME, V_EMP_NAME, NULL, NULL);

  -- create due_date record should not need to check for existing SO's as this is wored by a trouble ticket
  insert into so_due_dates (sod_uid_pk ,
                                    sod_so_uid_fk    ,
                                    sod_rev_due_date_types_uid_fk  ,
                                    sod_due_date   ,
                                    sod_due_time ,
                                    created_date ,
                                    created_by )
                        values (sod_seq.nextval,
                                  V_SVO_UID_PK,
                                  code_pkg.get_pk('REV_DUE_DATE_TYPES','ORG'),
                            TRUNC(sysdate),
                            sysdate,
                            sysdate,
                            user);


  --NOT SURE IF THIS IS NEEDED BUT ALL WILL BE SET TO ACTION FLAG OF 'N' FOR ALL EXISTING FEATURES
  FOR SVF_REC IN GET_SERVICE_FEATURES LOOP
      INSERT INTO SO_FEATURES(SOF_UID_PK, SOF_SO_UID_FK, SOF_OFFICE_SERV_FEATS_UID_FK, SOF_QUANTITY, SOF_COST, SOF_ACTION_FL,
                              SOF_ANNUAL_CHARGE_FL, SOF_INITIAL_CHARGE_FL, SOF_RECORDS_ONLY_FL, SOF_SERVICE_CHARGE_FL, SOF_EXT_NUM_CHG_FL,
                              SOF_COMPLETED_FL, SOF_HAND_RATED_AMOUNT, SOF_OLD_QUANTITY, SOF_WARR_START_DATE, SOF_WARR_END_DATE)
                       VALUES(SVF_SEQ.NEXTVAL, V_SVO_UID_PK, SVF_REC.SVF_OFFICE_SERV_FEATS_UID_FK, SVF_REC.SVF_QUANTITY, SVF_REC.SVF_COST,
                              'N', SVF_REC.SVF_ANNUAL_CHARGE_FL, SVF_REC.SVF_INITIAL_CHARGE_FL, SVF_REC.SVF_RECORDS_ONLY_FL, SVF_REC.SVF_SERVICE_CHARGE_FL,
                              'N','N', SVF_REC.SVF_HAND_RATED_AMOUNT, SVF_REC.SVF_QUANTITY, SVF_REC.SVF_WARR_START_DATE, SVF_REC.SVF_WARR_END_DATE);
  END LOOP;

  FOR SSL_REC IN GET_SERV_LOCATIONS LOOP
      INSERT INTO SERV_SERV_LOC_SO(SSX_UID_PK, SSX_SERVICE_LOCATIONS_UID_FK, SSX_SO_UID_FK,
                                   SSX_PRIMARY_LOC_FL, SSX_START_DATE, SSX_END_DATE, SSX_LOCATION_DESC)
                            VALUES(SSL_SEQ.NEXTVAL, SSL_REC.SSL_SERVICE_LOCATIONS_UID_FK, V_SVO_UID_PK,
                                   SSL_REC.SSL_PRIMARY_LOC_FL, SSL_REC.SSL_START_DATE, SSL_REC.SSL_END_DATE, SSL_REC.SSL_LOCATION_DESC);
  END LOOP;

  OPEN GET_PLNT_INFO(V_STY_UID_PK, V_BSO_UID_PK, 'PLNT');
  FETCH GET_PLNT_INFO INTO V_OSF_UID_PK;
  CLOSE GET_PLNT_INFO;

  --INSERT WITH ACTION FLAG OF 'A' WITH THE PLNT CODE
  INSERT INTO SO_FEATURES(SOF_UID_PK, SOF_SO_UID_FK, SOF_OFFICE_SERV_FEATS_UID_FK, SOF_QUANTITY, SOF_COST, SOF_ACTION_FL,
                          SOF_ANNUAL_CHARGE_FL, SOF_INITIAL_CHARGE_FL, SOF_RECORDS_ONLY_FL, SOF_SERVICE_CHARGE_FL, SOF_EXT_NUM_CHG_FL,
                          SOF_COMPLETED_FL, SOF_HAND_RATED_AMOUNT, SOF_OLD_QUANTITY, SOF_WARR_START_DATE, SOF_WARR_END_DATE)
                   VALUES(SVF_SEQ.NEXTVAL, V_SVO_UID_PK, V_OSF_UID_PK, 1, 0,
                          'A', 'N', 'N', 'Y', 'N','N','N', NULL,0, NULL, NULL);

  --ALSO ADD 'NISV' PER REQUEST FROM RANDALL
  OPEN GET_PLNT_INFO(V_STY_UID_PK, V_BSO_UID_PK, 'NISV');
  FETCH GET_PLNT_INFO INTO V_OSF_UID_PK;
  CLOSE GET_PLNT_INFO;

  --INSERT WITH ACTION FLAG OF 'A' WITH THE NISVCODE
  INSERT INTO SO_FEATURES(SOF_UID_PK, SOF_SO_UID_FK, SOF_OFFICE_SERV_FEATS_UID_FK, SOF_QUANTITY, SOF_COST, SOF_ACTION_FL,
                          SOF_ANNUAL_CHARGE_FL, SOF_INITIAL_CHARGE_FL, SOF_RECORDS_ONLY_FL, SOF_SERVICE_CHARGE_FL, SOF_EXT_NUM_CHG_FL,
                          SOF_COMPLETED_FL, SOF_HAND_RATED_AMOUNT, SOF_OLD_QUANTITY, SOF_WARR_START_DATE, SOF_WARR_END_DATE)
                   VALUES(SVF_SEQ.NEXTVAL, V_SVO_UID_PK, V_OSF_UID_PK, 1, 0,
                          'A', 'N', 'N', 'N', 'Y','N','N', NULL,0, NULL, NULL);

  --ADD THE MTA_SO RECORDS FOR THE CS ORDER THAT IS GENERATED
  FOR MSS_REC IN GET_ASSGN_MTA LOOP

     SELECT SON_SEQ.NEXTVAL
       INTO V_SON_UID_PK
       FROM DUAL;
     INSERT INTO SO_ASSGNMTS (SON_UID_PK, SON_SO_UID_FK, SON_SERVICE_LOCATIONS_UID_FK, SON_SAI_UID_FK,
                              SON_DSX_CONNECTIONS_UID_FK, SON_LENS_UID_FK, SON_LEAD_ROUTES_UID_FK,
                              SON_NC_CODES_UID_FK, SON_NCI_CODES_UID_FK, SON_AREAS_UID_FK, SON_SUBTYPE_CODES_UID_FK,
                              SON_CLLIS_UID_FK, SON_LINE#, SON_OPX, SON_BNN_PHONE#, SON_BAND, SON_WIRE,
                              SON_REMARKS, SON_PEDESTAL, SON_PROTECTOR, SON_SVC_ASSGNMT_UID,
                              SON_DSLAM_PORTS_UID_FK, SON_ADSL_MODEMS_UID_FK, SON_DSX3_CONNECTIONS_UID_FK,
                              SON_BONDED_FL, SON_HSD_FL)
                      VALUES (V_SON_UID_PK, V_SVO_UID_PK, MSS_REC.SVA_SERVICE_LOCATIONS_UID_FK, MSS_REC.SVA_SAI_UID_FK,
                              MSS_REC.SVA_DSX_CONNECTIONS_UID_FK, MSS_REC.SVA_LENS_UID_FK, MSS_REC.SVA_LEAD_ROUTES_UID_FK,
                              MSS_REC.SVA_NC_CODES_UID_FK, MSS_REC.SVA_NCI_CODES_UID_FK, MSS_REC.SVA_AREAS_UID_FK, MSS_REC.SVA_SUBTYPE_CODES_UID_FK,
                              MSS_REC.SVA_CLLIS_UID_FK, MSS_REC.SVA_LINE#, MSS_REC.SVA_OPX, MSS_REC.SVA_BNN_PHONE#, MSS_REC.SVA_BAND, MSS_REC.SVA_WIRE,
                              MSS_REC.SVA_REMARKS, MSS_REC.SVA_PEDESTAL, MSS_REC.SVA_PROTECTOR, MSS_REC.SVA_UID_PK,
                              MSS_REC.SVA_DSLAM_PORTS_UID_FK, MSS_REC.SVA_ADSL_MODEMS_UID_FK, MSS_REC.SVA_DSX3_CONNECTIONS_UID_FK,
                              MSS_REC.SVA_BONDED_FL, MSS_REC.SVA_HSD_FL);

     IF P_PORT IS NOT NULL THEN
        OPEN GET_PORT(V_STY_SYSTEM_CODE, MSS_REC.MTP_MTA_EQUIP_UNITS_UID_FK);
        FETCH GET_PORT INTO V_MTP_UID_PK;
        CLOSE GET_PORT;
     ELSE
        V_MTP_UID_PK := MSS_REC.MSS_MTA_PORTS_UID_FK;
     END IF;

     INSERT INTO MTA_SO (MTO_UID_PK, MTO_SO_ASSGNMTS_UID_FK, MTO_SAM_IDENTIFIER, MTO_MTA_PORTS_UID_FK, MTO_COMMENT)
                 VALUES (MTO_SEQ.NEXTVAL, V_SON_UID_PK, MSS_REC.MSS_SAM_IDENTIFIER, V_MTP_UID_PK, P_NEW_MTAMAC);

     V_ASSIGNMENTS_FOUND_FL := 'Y';

  END LOOP;

  IF V_ASSIGNMENTS_FOUND_FL = 'N' THEN
    OPEN GET_RSU_INFO(V_SLO_UID_PK);
    FETCH GET_RSU_INFO INTO V_PEDESTAL, V_PROTECTOR, V_RSU_#, V_LRT_UID_PK, V_FBN_UID_PK, V_PON_UID_PK;
    CLOSE GET_RSU_INFO;

    OPEN GET_CLLI;
    FETCH GET_CLLI INTO V_CLI_UID_PK;
    CLOSE GET_CLLI;

    IF V_FBN_UID_PK IS NOT NULL THEN
       UPDATE FIBER_NODES
          SET FBN_PC_FL = 'Y',
              FBN_CLLIS_UID_FK = V_CLI_UID_PK
        WHERE FBN_UID_PK = V_FBN_UID_PK;
    END IF;

      OPEN GET_EXISTING_MTA_UNIT(V_SLO_UID_PK);
      FETCH GET_EXISTING_MTA_UNIT INTO V_MEU_UID_PK;
      IF GET_EXISTING_MTA_UNIT%NOTFOUND THEN

        SELECT MEU_SEQ.NEXTVAL
          INTO V_MEU_UID_PK
          FROM DUAL;

        insert into mta_equip_units ( meu_uid_pk
                                     ,meu_mta_types_uid_fk
                                     ,meu_fiber_nodes_uid_fk
                                     ,meu_lead_routes_uid_fk
                                     ,meu_service_locations_uid_fk
                                     ,meu_active_fl
                                     ,meu_hold_fl
                                     ,meu_default_dedication
                                     ,meu_cmac_address
                                     ,meu_mtamac_address
                                     ,meu_pedestal
                                     ,meu_protector
                                     ,meu_comment
                                     ,meu_fqd_name
                                     ,meu_pas_opt_networks_uid_fk)
                                 values ( V_MEU_UID_PK
                                     ,P_MTY_UID_PK
                                     ,V_FBN_UID_PK
                                     ,V_LRT_UID_PK
                                     ,V_SLO_UID_PK
                                     ,'Y'
                                     ,'N'
                                     ,'L'
                                     ,NULL
                                     ,NULL
                                     ,V_PEDESTAL
                                     ,V_PROTECTOR
                                     ,NULL
                                     ,NULL
                                     ,v_pon_uid_pk);

       open get_mta_status('AV');
       fetch get_mta_status into v_mst_uid_pk;
       close get_mta_status;

       for rec in get_count_port loop
           open get_mpd_ports(rec.mpd_uid_pk);
           fetch get_mpd_ports into v_mpd_#_of_ports, v_mta_port_type, v_mpt_uid_pk;
           close get_mpd_ports;

           for port_num in 1 .. v_mpd_#_of_ports loop -- loop for number of data, tel, ctv, etc. ports
               insert into mta_ports ( mtp_uid_pk
                                      ,mtp_mta_equip_units_uid_fk
                                      ,mtp_mta_port_types_uid_fk
                                    ,mtp_mta_status_uid_fk
                                    ,mtp_service_locations_uid_fk
                                    ,mtp_default_dedication
                                      ,mtp_line_no#
                                      ,mtp_hold_fl)
                                values ( mtp_seq.nextval
                                      ,v_meu_uid_pk
                                      ,v_mpt_uid_pk
                                      ,v_mst_uid_pk
                                      ,V_SLO_UID_PK
                                      ,'L'
                                      ,port_num
                                      ,'N');
           end loop;
       end loop;

   END IF;
   CLOSE GET_EXISTING_MTA_UNIT;

   SELECT SON_SEQ.NEXTVAL
     INTO V_SON_UID_PK
     FROM DUAL;
   INSERT INTO SO_ASSGNMTS (SON_UID_PK, SON_SO_UID_FK, SON_SERVICE_LOCATIONS_UID_FK, SON_LEAD_ROUTES_UID_FK,
                            SON_CLLIS_UID_FK, SON_LINE#, SON_OPX, SON_PEDESTAL, SON_PROTECTOR)
                    VALUES (V_SON_UID_PK, V_SVO_UID_PK, V_SLO_UID_PK, V_LRT_UID_PK, V_CLI_UID_PK,
                            1, 0, V_PEDESTAL, V_PROTECTOR);


   OPEN GET_PORT(V_STY_SYSTEM_CODE, V_MEU_UID_PK);
   FETCH GET_PORT INTO V_MTP_UID_PK;
   CLOSE GET_PORT;

   open get_mta_status('C');
   fetch get_mta_status into v_mst_uid_pk;
   close get_mta_status;

   UPDATE mta_ports
      SET MTP_MTA_STATUS_UID_FK = v_mst_uid_pk
    WHERE MTP_UID_PK = V_MTP_UID_PK;

   INSERT INTO MTA_SO (MTO_UID_PK, MTO_SO_ASSGNMTS_UID_FK, MTO_SAM_IDENTIFIER, MTO_MTA_PORTS_UID_FK, MTO_COMMENT)
               VALUES (MTO_SEQ.NEXTVAL, V_SON_UID_PK, NULL, V_MTP_UID_PK, P_NEW_MTAMAC);

  END IF;

  IF V_STY_SYSTEM_CODE = 'BBS' THEN
     --CHECK THAT MODEM HAS NOT ALREADY BEEN CREATED IN BROADBAND_SERVICES OR METRO_SERVICES TABLES
     OPEN GET_CABLE_MODEM_PK;
     FETCH GET_CABLE_MODEM_PK INTO V_BBS_MES_UID_PK, V_CABLE_MODEM_TYPE, V_OPERATING_SYSTEM_ID, v_iwt_uid_pk ;
     IF GET_CABLE_MODEM_PK%FOUND THEN
        IF V_CABLE_MODEM_TYPE = 'B' THEN
           SELECT BBS_SEQ.NEXTVAL
             INTO V_BBO_UID_PK
             FROM DUAL;

           INSERT INTO BROADBAND_SO(BBO_UID_PK, BBO_SO_UID_FK,BBO_OPERATING_SYSTEM, BBO_INSIDE_WIR_TYPES_UID_FK)
                             VALUES(V_BBO_UID_PK, V_SVO_UID_PK,V_OPERATING_SYSTEM_ID, v_iwt_uid_pk);

           FOR INT_REC IN get_int_details LOOP
              INSERT INTO INTERNET_SO(ISS_UID_PK,ISS_SO_UID_FK,ISS_USER_NAME,ISS_PASSWORD,ISS_PACS_ID_NO#,ISS_TRAINING_FL,
                                      ISS_RADIUS_FL,ISS_CONFIRMATION_FL,ISS_SECURITY_QUESTION,ISS_SECURITY_ANSWER,ISS_RAD_PENDING_DATE,
                                      ISS_CONTACT_EMAIL,ISS_COMMENT,CREATED_BY,CREATED_DATE,MODIFIED_BY,MODIFIED_DATE,ISS_EXPIRATION_DATE)
                               VALUES(its_seq.nextval, V_SVO_UID_PK, INT_REC.its_user_name, INT_REC.its_password, INT_REC.its_pacs_id_no#,
                                      INT_REC.its_training_fl, INT_REC.its_radius_fl, INT_REC.its_confirmation_fl, INT_REC.its_security_question,
                                      INT_REC.its_security_answer, INT_REC.its_rad_pending_date, null, INT_REC.its_comment, user, sysdate,
                                      user, sysdate, INT_REC.ITS_EXPIRATION_DATE);

           END LOOP;

        ELSE
           SELECT MES_SEQ.NEXTVAL
             INTO V_MEO_UID_PK
             FROM DUAL;

           INSERT INTO METRO_SO(MEO_UID_PK, MEO_SO_UID_FK, MEO_METRO_ID)
                             VALUES(V_MEO_UID_PK, V_SVO_UID_PK, V_OPERATING_SYSTEM_ID);
        END IF;
     END IF;
     CLOSE GET_CABLE_MODEM_PK;

  ELSIF V_STY_SYSTEM_CODE = 'PHN' THEN

     --ADD LATA SOS
     FOR LTA_REC IN GET_LATAS LOOP
         INSERT INTO LATA_SO(LTS_UID_PK, LTS_SO_UID_FK, LTS_LATA_CIC_OCPS_UID_FK, LTS_FREEZE_FL,
                             LTS_START_DATE, LTS_END_DATE)
                      VALUES(LTA_SEQ.NEXTVAL, V_SVO_UID_PK, LTA_REC.LTA_LATA_CIC_OCPS_UID_FK,
                             LTA_REC.LTA_FREEZE_FL, LTA_REC.LTA_START_DATE, LTA_REC.LTA_END_DATE);
     END LOOP;

     --ADD PHONE_SO
     FOR PSS_REC IN GET_PHONE LOOP
         INSERT INTO PHONE_SO(PSS_UID_PK, PSS_SO_UID_FK, PSS_LINE_SERVICE_TYPES_UID_FK, PSS_KEY_EQUIPMENT_FL,
                              PSS_LETTER_OF_AGENCY_FL, PSS_EXPOSED_WIRE_FL, PSS_LIFE_SUPPORT_FL, PSS_HEARING_FL,
                              PSS_VISION_FL, PSS_BASIC_UTILITY_PLAN_FL, PSS_HUNT_GROUP_MEMBER_FL,
                              PSS_DSL_HFC_FL, PSS_LINE_QTY, PSS_COMMENT, PSS_LIFELINE_NUMBER, PSS_CRV#,
                              PSS_VOICE_GATEWAYS_UID_FK, PSS_VM_PASSWORD, PSS_VM_WEB_PASSWORD)
                       VALUES(PHS_SEQ.NEXTVAL, V_SVO_UID_PK, PSS_REC.PHS_LINE_SERVICE_TYPES_UID_FK, PSS_REC.PHS_KEY_EQUIPMENT_FL,
                              PSS_REC.PHS_LETTER_OF_AGENCY_FL, PSS_REC.PHS_EXPOSED_WIRE_FL, PSS_REC.PHS_LIFE_SUPPORT_FL, PSS_REC.PHS_HEARING_FL,
                              PSS_REC.PHS_VISION_FL, PSS_REC.PHS_BASIC_UTILITY_PLAN_FL, PSS_REC.PHS_HUNT_GROUP_MEMBER_FL,
                              PSS_REC.PHS_DSL_HFC_FL, PSS_REC.PHS_LINE_QTY, PSS_REC.PHS_COMMENT, PSS_REC.PHS_LIFELINE_NUMBER, PSS_REC.PHS_CRV#,
                              PSS_REC.PHS_VOICE_GATEWAYS_UID_FK, NULL, NULL);
     END LOOP;

     --ADD LINE#
     FOR LSX_REC IN GET_LINE# LOOP
         INSERT INTO LINE#_SERVICE_SO(LSX_UID_PK, LSX_LINE_NUMBERS_UID_FK, LSX_SO_UID_FK, LSX_LINE#_SERV_TYPES_UID_FK,
                                      LSX_DBN_LINE_TYPES_UID_FK, LSX_ACTIVE_FL, LSX_SDN_PATTERN_CODE)
                               VALUES(LSV_SEQ.NEXTVAL, LSX_REC.LSV_LINE_NUMBERS_UID_FK, V_SVO_UID_PK, LSX_REC.LSV_LINE#_SERV_TYPES_UID_FK,
                                      LSX_REC.LSV_DBN_LINE_TYPES_UID_FK, LSX_REC.LSV_ACTIVE_FL, LSX_REC.LSV_SDN_PATTERN_CODE);
     END LOOP;

  END IF;
  
  --ADD ROUTER SOS
  FOR ROU_REC IN GET_ROUTER LOOP
         INSERT INTO ROUTER_SO(ROS_UID_PK, ROS_SO_UID_FK, ROS_ROUTERS_UID_FK, ROS_ACTIVE_FL, ROS_START_DATE, ROS_END_DATE)
                      VALUES(RSV_SEQ.NEXTVAL, V_SVO_UID_PK, ROU_REC.RSV_ROUTERS_UID_FK, ROU_REC.RSV_ACTIVE_FL, ROU_REC.RSV_START_DATE, ROU_REC.RSV_END_DATE);
  END LOOP;
  
  --ADD CPE SOS
  FOR CPE_REC IN GET_CPE LOOP
         INSERT INTO CPE_SO(CEO_UID_PK, CEO_SO_UID_FK, CEO_CPE_UID_FK, CEO_ACTIVE_FL, CEO_START_DATE, CEO_END_DATE)
                     VALUES(CPS_SEQ.NEXTVAL, V_SVO_UID_PK, CPE_REC.CPS_CPE_UID_FK, CPE_REC.CPS_ACTIVE_FL, CPE_REC.CPS_START_DATE, CPE_REC.CPS_END_DATE);
  END LOOP;

END IF;

P_SVO_UID_PK := V_SVO_UID_PK;
P_RSU_#      := V_RSU_#;

END CREATE_CS_ORDER;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_CHECK_OTHER_SVC_CS_MS(P_SVO_UID_PK IN NUMBER, P_SAME_CUS_FL OUT VARCHAR, P_SVC_UID_PK OUT NUMBER)
RETURN VARCHAR

IS

 -- 04/04/12 LJH ADDED CSP_SYSTEM_CODE PER HD CALL #118945
 cursor get_cus is
   select cus_uid_pk, svc_uid_pk, sty_system_code, sot_system_code, svt_code, acc_uid_pk, csp_system_code
     from customers, so_types, accounts, services,
          office_serv_types, service_types, so, off_serv_subs, serv_sub_types, customer_types
    where cus_uid_pk = acc_customers_uid_fk
      and acc_uid_pk = svc_accounts_uid_fk
      and svc_uid_pk = svo_services_uid_fk
      and ost_uid_pk = svc_office_serv_types_uid_fk
      and sty_uid_pk = ost_service_types_uid_fk
      and sot_uid_pk = svo_so_types_uid_fk
      and osb_uid_pk = svo_off_serv_subs_uid_fk
      and svt_uid_pk = osb_serv_sub_types_uid_fk
      and svo_uid_pk = P_SVO_UID_PK
      and csp_uid_pk = cus_customer_types_uid_fk;

CURSOR GET_SLO IS
  SELECT SSX_SERVICE_LOCATIONS_UID_FK
    FROM SERV_SERV_LOC_SO
   WHERE SSX_SO_UID_FK = P_SVO_UID_PK
     AND SSX_END_DATE IS NULL;

CURSOR GET_SLO_OLD (P_SVC_UID_PK IN NUMBER) IS
  SELECT SSL_SERVICE_LOCATIONS_UID_FK
    FROM SERV_SERV_LOCATIONS
   WHERE SSL_SERVICES_UID_FK = P_SVC_UID_PK
     AND SSL_END_DATE IS NULL;

 CURSOR CHECK_OTHER_SVC (P_SLO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER) IS
   (SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
          STY_SYSTEM_CODE, ACC_CUSTOMERS_UID_FK, SVC_UID_PK, ACC_UID_PK
     FROM ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES,
          SERV_SERV_LOCATIONS, OFF_SERV_SUBS, SERV_SUB_TYPES
    WHERE SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
      AND SVC_UID_PK = SSL_SERVICES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND OSB_UID_PK = SVC_OFF_SERV_SUBS_UID_FK
      AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
      AND SVC_UID_PK != P_SVC_UID_PK
      AND STY_SYSTEM_CODE = 'BBS'
      AND SVT_SYSTEM_CODE IN ('PACKET CABLE','CABLE MODEM','RFOG')
      AND SVC_END_DATE IS NULL
      AND SSL_END_DATE IS NULL
      AND SVC_UID_PK NOT IN (SELECT SVA_SERVICES_UID_FK
                               FROM SERVICE_ASSGNMTS, MTA_SERVICES
                              WHERE SVC_UID_PK = SVA_SERVICES_UID_FK
                                AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK)
   UNION
      SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
               STY_SYSTEM_CODE, ACC_CUSTOMERS_UID_FK, SVC_UID_PK, ACC_UID_PK
          FROM ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES,
               SERV_SERV_LOCATIONS
         WHERE SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
           AND SVC_UID_PK = SSL_SERVICES_UID_FK
           AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
           AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
           AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
           AND SVC_UID_PK != P_SVC_UID_PK
           AND STY_SYSTEM_CODE IN ('PHN')
           AND SVC_END_DATE IS NULL
           AND SVC_UID_PK NOT IN (SELECT SVA_SERVICES_UID_FK
                                    FROM SERVICE_ASSGNMTS, MTA_SERVICES
                                   WHERE SVC_UID_PK = SVA_SERVICES_UID_FK
                                     AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK)
         AND SSL_END_DATE IS NULL)
  MINUS
   (SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), STY_SYSTEM_CODE,
           ACC_CUSTOMERS_UID_FK, SVC_UID_PK, ACC_UID_PK
     FROM ACCOUNTS, SO, SO_TYPES, SO_STATUS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOC_SO
    WHERE SSX_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
      AND SVO_UID_PK = SSX_SO_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND SVC_UID_PK = SVO_SERVICES_UID_FK
      AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
      AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND SOT_SYSTEM_CODE IN ('CS','MS','NS','RI')
      AND STY_SYSTEM_CODE IN ('PHN','BBS')
      AND SSX_END_DATE IS NULL
      AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID')
    UNION
   SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), STY_SYSTEM_CODE,
          ACC_CUSTOMERS_UID_FK, SVC_UID_PK, ACC_UID_PK
     FROM ACCOUNTS, SO, SO_TYPES, SO_STATUS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOCATIONS
    WHERE SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
      AND SVC_UID_PK = SSL_SERVICES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND SVC_UID_PK = SVO_SERVICES_UID_FK
      AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
      AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND SOT_SYSTEM_CODE IN ('RS')
      AND STY_SYSTEM_CODE IN ('PHN','BBS')
      AND SSL_END_DATE IS NULL
      AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID'))
    ORDER BY STY_SYSTEM_CODE;
    
CURSOR check_cs_phn(cp_slo_uid_pk IN NUMBER, cp_acc_uid_pk IN NUMBER) IS
SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
     FROM ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOCATIONS
    WHERE SSL_SERVICE_LOCATIONS_UID_FK = cp_slo_uid_pk
      AND SVC_UID_PK = SSL_SERVICES_UID_FK
      AND SSL_END_DATE IS NULL
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
      AND STY_SYSTEM_CODE = 'PHN'
      AND ACC_UID_PK = cp_acc_uid_pk
      AND SVC_UID_PK NOT IN (SELECT SVO_SERVICES_UID_FK
                               FROM SO, SO_TYPES, SO_STATUS 
                              WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
                                AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                                AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
                                AND SOT_SYSTEM_CODE = 'CS'
                                AND SOS_SYSTEM_CODE NOT IN ('CLOSED','VOID'));

  v_cus_uid_pk       number;
  v_cus_uid_pk_other number;
  v_acc_uid_pk       number;
  v_acc_uid_pk_other number;
  v_svc_uid_pk_other number;
  v_svc_uid_pk       number;
  v_slo_uid_pk       number;
  v_slo_uid_pk_old   number;
  V_SLO_EMTA_FL      VARCHAR2(1);
  V_IDENTIFIER       VARCHAR2(80);
  V_STY_SYSTEM_CODE  VARCHAR2(20);
  V_SOT_SYSTEM_CODE  VARCHAR2(20);
  V_SVT_CODE         VARCHAR2(20);
  V_TYPE             VARCHAR2(40);
  V_CSP_SYSTEM_CODE  VARCHAR2(12); -- 04/04/12 LJH HD CALL #118945
  
  v_return_msg  		VARCHAR2(4000);
  V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_CHECK_OTHER_SVC_CS_MS';
  v_speed          NUMBER;
  v_facilities     VARCHAR2(1000);
  v_fac_type       VARCHAR2(12);

BEGIN

open get_cus;
fetch get_cus into v_cus_uid_pk, v_svc_uid_pk, V_STY_SYSTEM_CODE, V_SOT_SYSTEM_CODE, V_SVT_CODE, v_acc_uid_pk, v_csp_system_code;
close get_cus;

IF V_SOT_SYSTEM_CODE IN ('MS','NS') THEN

  open GET_SLO;
  fetch GET_SLO into v_slo_uid_pk;
  close GET_SLO;

  open GET_SLO_OLD(v_svc_uid_pk);
  fetch GET_SLO_OLD into v_slo_uid_pk_old;
  if GET_SLO_OLD%NOTFOUND THEN
     v_slo_uid_pk_old := null;
  end if;
  close GET_SLO_OLD;

  V_SLO_EMTA_FL := FN_EMTA_LOCATION(v_slo_uid_pk);

  if V_SLO_EMTA_FL = 'Y' AND (V_STY_SYSTEM_CODE = 'PHN' OR V_SVT_CODE IN ('CABLE MODEM','PACKET CABLE','RFOG')) THEN --NEW LOCATION IS PACKET CABLE READY.
     /*IF v_slo_uid_pk_old is not null then
        OPEN CHECK_OTHER_SVC(v_slo_uid_pk_old, v_svc_uid_pk);
        FETCH CHECK_OTHER_SVC INTO V_IDENTIFIER, V_STY_SYSTEM_CODE, v_cus_uid_pk_other, v_svc_uid_pk_other;
        IF CHECK_OTHER_SVC%FOUND THEN
           IF v_cus_uid_pk_other != v_cus_uid_pk THEN
              P_SAME_CUS_FL := 'N';
              P_SVC_UID_PK  := NULL;
              RETURN 'The '||V_IDENTIFIER||' service on this customer# '||v_cus_uid_pk_other||' needs to have a plant CS order created for Packet Cable/RFOG';
           ELSE
              P_SAME_CUS_FL := 'Y';
              P_SVC_UID_PK  := v_svc_uid_pk_other;
              RETURN 'The '||V_IDENTIFIER||' service on this customer needs to have a plant CS order created for Packet Cable/RFOG';
           END IF;
        END IF;
        CLOSE CHECK_OTHER_SVC;

     END IF;*/

     IF v_slo_uid_pk is not null then
        V_IDENTIFIER       := NULL;
        V_STY_SYSTEM_CODE  := NULL;
        v_cus_uid_pk_other := NULL;
        V_TYPE             := FN_MTA_TYPE(V_SLO_UID_PK);
        OPEN CHECK_OTHER_SVC(v_slo_uid_pk, v_svc_uid_pk);  --NEW SLO
        FETCH CHECK_OTHER_SVC INTO V_IDENTIFIER, V_STY_SYSTEM_CODE, v_cus_uid_pk_other, v_svc_uid_pk_other, v_acc_uid_pk_other;
        IF CHECK_OTHER_SVC%FOUND THEN
--           CLOSE CHECK_OTHER_SVC;
           IF v_acc_uid_pk_other != v_acc_uid_pk THEN
              P_SAME_CUS_FL := 'N';
              P_SVC_UID_PK  := NULL;
              IF v_csp_system_code = 'RES' THEN
	              RETURN 'The '||V_IDENTIFIER||' service on customer# '||v_cus_uid_pk_other||' separate account needs to have a plant CS order created for '||V_TYPE;
								v_return_msg := 'The '||V_IDENTIFIER||' service on customer# '||v_cus_uid_pk_other||' separate account needs to have a plant CS order created for '||V_TYPE;
								IF P_SVO_UID_PK IS NOT NULL THEN
									 IF v_return_msg IS NOT NULL THEN
										 	PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
									 END IF;
		 						END IF;
							
							END IF;
           ELSE
              P_SAME_CUS_FL := 'Y';
              P_SVC_UID_PK  := v_svc_uid_pk_other;
              IF v_csp_system_code = 'RES' THEN
	              RETURN 'The '||V_IDENTIFIER||' service on this customer needs to have a plant CS order created for '||V_TYPE;
								v_return_msg := 'The '||V_IDENTIFIER||' service on customer# '||v_cus_uid_pk_other||' separate account needs to have a plant CS order created for '||V_TYPE;
								IF P_SVO_UID_PK IS NOT NULL THEN
									 IF v_return_msg IS NOT NULL THEN
											PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
									 END IF;
		 						END IF;
							END IF;
           END IF;
        END IF;
        CLOSE CHECK_OTHER_SVC;
     END IF;
  end if;

ELSIF V_SOT_SYSTEM_CODE = 'CS' THEN

  open GET_SLO;
  fetch GET_SLO into v_slo_uid_pk;
  close GET_SLO;

  V_SLO_EMTA_FL := FN_EMTA_LOCATION(v_slo_uid_pk);

  IF V_SLO_EMTA_FL = 'Y' AND V_SVT_CODE IN ('PACKET CABLE','RFOG') THEN
  
     IF automatic_scheduling_pkg.fn_determine_if_speed_change(p_svo_uid_pk, v_speed) THEN  --only continue if the customer is actually changing speeds
               
        IF v_slo_uid_pk IS NOT NULL THEN
           v_facilities := catv_streams_pkg.get_slo_facilities_code(NULL ,v_slo_uid_pk, 'GENERIC', v_fac_type, 'N');
        END IF;
        
        IF NOT automatic_scheduling_pkg.FN_DETERMINE_HSD_EQUIPMENT(v_svc_uid_pk, v_fac_type, v_speed, v_slo_uid_pk) THEN
           OPEN check_cs_phn(v_slo_uid_pk, v_acc_uid_pk); 
           FETCH check_cs_phn INTO V_IDENTIFIER, v_svc_uid_pk_other;
           IF check_cs_phn%FOUND THEN
              P_SAME_CUS_FL := 'Y';
              P_SVC_UID_PK  := v_svc_uid_pk_other;
	      RETURN 'The '||V_IDENTIFIER||' service needs to have a plant CS order created for the increase in speed to a new MTA modem.';					
	   END IF;
	   CLOSE check_cs_phn;
        END IF;
     END IF;
  END IF;
END IF;

P_SAME_CUS_FL := 'Y';
P_SVC_UID_PK  := NULL;
RETURN NULL;

END FN_CHECK_OTHER_SVC_CS_MS;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_EMTA_LOCATION(P_SLO_UID_PK IN NUMBER)
RETURN VARCHAR

IS

 CURSOR SLO_EMTA (P_SLO_UID_PK IN NUMBER) IS
   SELECT SLO_EMTA_FL
     FROM SERVICE_LOCATIONS
    WHERE SLO_UID_PK = P_SLO_UID_PK
  UNION
   SELECT 'Y'
     FROM MTA_EQUIP_UNITS
    WHERE MEU_SERVICE_LOCATIONS_UID_FK in
                   (select s2.slo_uid_pk
                   from service_locations s1, service_locations s2
                  where s1.slo_uid_pk = P_SLO_UID_PK
                    and s1.slo_municipalities_uid_fk = s2.slo_municipalities_uid_fk
                    and s1.slo_streets_uid_fk = s2.slo_streets_uid_fk
                    and ((s1.slo_street_nums_uid_fk = s2.slo_street_nums_uid_fk and s1.slo_street_nums_uid_fk is not null)
                     or (s2.slo_street_nums_uid_fk is null and s1.slo_street_nums_uid_fk is null))
                    and ((s1.slo_buildings_uid_fk = s2.slo_buildings_uid_fk and s1.slo_buildings_uid_fk is not null)
                     or (s2.slo_buildings_uid_fk is null and s1.slo_buildings_uid_fk is null))
                    and ((s1.slo_building_units_uid_fk = s2.slo_building_units_uid_fk and s1.slo_building_units_uid_fk is not null)
                     or (s2.slo_building_units_uid_fk is null and s1.slo_building_units_uid_fk is null)))
  UNION
   SELECT 'Y'
     FROM MTA_PORTS
    WHERE MTP_SERVICE_LOCATIONS_UID_FK in
                   (select s2.slo_uid_pk
                   from service_locations s1, service_locations s2
                  where s1.slo_uid_pk = P_SLO_UID_PK
                    and s1.slo_municipalities_uid_fk = s2.slo_municipalities_uid_fk
                    and s1.slo_streets_uid_fk = s2.slo_streets_uid_fk
                    and ((s1.slo_street_nums_uid_fk = s2.slo_street_nums_uid_fk and s1.slo_street_nums_uid_fk is not null)
                     or (s2.slo_street_nums_uid_fk is null and s1.slo_street_nums_uid_fk is null))
                    and ((s1.slo_buildings_uid_fk = s2.slo_buildings_uid_fk and s1.slo_buildings_uid_fk is not null)
                     or (s2.slo_buildings_uid_fk is null and s1.slo_buildings_uid_fk is null))
                    and ((s1.slo_building_units_uid_fk = s2.slo_building_units_uid_fk and s1.slo_building_units_uid_fk is not null)
                     or (s2.slo_building_units_uid_fk is null and s1.slo_building_units_uid_fk is null)))
   ORDER BY 1 DESC;

V_SLO_EMTA_FL   VARCHAR2(1);

BEGIN

  V_SLO_EMTA_FL := 'N';
  OPEN SLO_EMTA(p_slo_uid_pk);
  FETCH SLO_EMTA INTO V_SLO_EMTA_FL;
  IF SLO_EMTA%NOTFOUND THEN
     V_SLO_EMTA_FL := 'N';
  END IF;
  CLOSE SLO_EMTA;

RETURN V_SLO_EMTA_FL;

END FN_EMTA_LOCATION;

FUNCTION FN_MTA_ON_LOC(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER DEFAULT NULL)
RETURN VARCHAR

--THIS WILL RETURN 'Y' IF THE SERVICE ORDER HAS A NOT REMOVED BOX ON THE ORDER
--AND 'N' IF IT DOES NOT

IS

 CURSOR MTA_CUR IS
 SELECT 'x'
   FROM so_assgnmts,
        mta_so,
        mta_ports,
        mta_equip_units,
        mta_boxes
  WHERE son_so_uid_fk           = p_svo_uid_pk
    and son_uid_pk = mto_so_assgnmts_uid_fk
    and mtp_uid_pk = mto_mta_ports_uid_fk
    and meu_uid_pk = mtp_mta_equip_units_uid_fk
    and mta_uid_pk = meu_mta_boxes_uid_fk
    and meu_remove_mta_fl = 'N';

 CURSOR MTA_SVC_CUR IS
 SELECT 'x'
   FROM service_assgnmts,
        mta_services,
        mta_ports,
        mta_equip_units,
        mta_boxes
  WHERE sva_services_uid_fk = p_svc_uid_pk
    and sva_uid_pk = mss_service_assgnmts_uid_fk
    and mtp_uid_pk = mss_mta_ports_uid_fk
    and meu_uid_pk = mtp_mta_equip_units_uid_fk
    and mta_uid_pk = meu_mta_boxes_uid_fk
    and meu_remove_mta_fl = 'N';

  V_DUMMY   VARCHAR2(1);

BEGIN

  IF p_svo_uid_pk is not null then
     OPEN MTA_CUR;
     FETCH MTA_CUR INTO V_DUMMY;
     IF MTA_CUR%FOUND THEN
        V_DUMMY := 'Y';
     ELSE
        V_DUMMY := 'N';
     END IF;
     CLOSE MTA_CUR;
  END IF;

  IF p_svc_uid_pk is not null then
     OPEN MTA_SVC_CUR;
     FETCH MTA_SVC_CUR INTO V_DUMMY;
     IF MTA_SVC_CUR%FOUND THEN
        V_DUMMY := 'Y';
     ELSE
        V_DUMMY := 'N';
     END IF;
     CLOSE MTA_SVC_CUR;
  END IF;

RETURN V_DUMMY;

END FN_MTA_ON_LOC;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_RSU_TO_MTA_DISPLAY(P_SLO_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

--THIS TABLE FUNCTION WILL RETURN THE SERVICES AT A LOCATION PASSED IN IF
--1.  THE LOCATION IS PACKET CABLE READY
--2.  THE LOCATION DOES NOT CURRENTLY HAVE A MTA ATTACHED TO ANY OF THE SERVICES(NO MTA_SERVICES RECORD ACTIVE)
--3.  THERE MAY OR MAY NOT BE AN EXISTING MTA_EQUIP_UNIT RECORD AT THE TABLE

CURSOR ACTIVE_MTA IS
SELECT 'X'
FROM MTA_SERVICES, SERVICE_ASSGNMTS, SERVICES, SERV_SERV_LOCATIONS
WHERE SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
  AND SVC_UID_PK = SVA_SERVICES_UID_FK
  AND SVC_UID_PK = SSL_SERVICES_UID_FK
  AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
  AND SSL_END_DATE IS NULL
  AND SSL_PRIMARY_LOC_FL = 'Y'
  AND SVC_END_DATE IS NULL;

CURSOR RSU_AT_LOC IS
 SELECT RSU_RSU_#
	 FROM REM_SERV_UNITS
	WHERE RSU_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK;
	

CURSOR PHONE_SERVICE_EXISTS IS
SELECT 'X'
  FROM SERVICES,
       OFFICE_SERV_TYPES,
       SERVICE_TYPES,
       OFF_SERV_SUBS,
       SERV_SUB_TYPES,
       SERV_SERV_LOCATIONS
 WHERE SVC_UID_PK = SSL_SERVICES_UID_FK
   AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
   AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
   AND OSB_UID_PK = SVC_OFF_SERV_SUBS_UID_FK
   AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
   AND STY_SYSTEM_CODE = 'PHN'
   AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
   AND SSL_END_DATE IS NULL
   AND SSL_PRIMARY_LOC_FL = 'Y'
   AND SVC_END_DATE IS NULL;

CURSOR GET_SERVICES(P_RSU_RSU IN VARCHAR) IS
SELECT DISTINCT SVC_UID_PK,
       GET_IDENTIFIER_FUN(SVC_UID_PK, OST_UID_PK) IDENTIFIER,
       STY_CODE,
       SVT_CODE
  FROM SERVICES,
       OFFICE_SERV_TYPES,
       SERVICE_TYPES,
       OFF_SERV_SUBS,
       SERV_SUB_TYPES,
       SERV_SERV_LOCATIONS,
       SERVICE_ASSGNMTS
 WHERE SVC_UID_PK = SSL_SERVICES_UID_FK
   AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
   AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
   AND OSB_UID_PK = SVC_OFF_SERV_SUBS_UID_FK
   AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
   AND SVC_UID_PK = SVA_SERVICES_UID_FK
   AND (STY_SYSTEM_CODE = 'PHN' OR SVT_SYSTEM_CODE = 'CABLE MODEM')
   AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
   AND SSL_END_DATE IS NULL
   AND SSL_PRIMARY_LOC_FL = 'Y'
   AND SVC_END_DATE IS NULL
  ORDER BY STY_CODE;

CURSOR GET_MODEM_MAC (P_SVC_UID_PK IN NUMBER) IS
  SELECT CBM_MAC_ADDRESS
    FROM CABLE_MODEMS, SERVICE_ASSGNMTS
   WHERE CBM_UID_PK = SVA_CABLE_MODEMS_UID_FK
     AND SVA_SERVICES_UID_FK = P_SVC_UID_PK;

rec                GET_SERVICES%rowtype;
v_rec              generic_data_type;
v_dummy            varchar2(1);
v_mac_address      varchar2(20);
v_rsu_rsu_#        varchar2(40);

BEGIN

IF P_SLO_UID_PK IS NOT NULL THEN

 OPEN ACTIVE_MTA;
 FETCH ACTIVE_MTA INTO V_DUMMY;
 IF ACTIVE_MTA%NOTFOUND THEN

    OPEN RSU_AT_LOC;
    FETCH RSU_AT_LOC INTO v_rsu_rsu_#;
    IF RSU_AT_LOC%FOUND THEN
       OPEN PHONE_SERVICE_EXISTS;
       FETCH PHONE_SERVICE_EXISTS INTO V_DUMMY;
       IF PHONE_SERVICE_EXISTS%FOUND THEN
          OPEN GET_SERVICES(v_rsu_rsu_#);
          LOOP
             FETCH GET_SERVICES into rec;
             EXIT WHEN GET_SERVICES%notfound;


             v_mac_address := NULL;
             OPEN GET_MODEM_MAC(rec.svc_uid_pk);
             FETCH GET_MODEM_MAC INTO v_mac_address;
             IF GET_MODEM_MAC%NOTFOUND THEN
                v_mac_address := NULL;
             END IF;
             CLOSE GET_MODEM_MAC;

             --set the fields
             v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
       	             NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
    	               NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
    	               NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
    	               NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
    	               NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
    	               NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
    	               NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
    	               NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
    	               NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

             v_rec.gdt_number1    := rec.svc_uid_pk;    -- svc_uid_pk
             v_rec.gdt_alpha1     := rec.identifier;    -- identifier
             v_rec.gdt_alpha2     := rec.sty_code;      -- identifier
             v_rec.gdt_alpha3     := rec.svt_code;      -- identifier
             v_rec.gdt_alpha4     := v_mac_address;     -- modem mac address

             PIPE ROW (v_rec);
          END LOOP;

          CLOSE GET_SERVICES;
       END IF;
       CLOSE PHONE_SERVICE_EXISTS;
    END IF;
    CLOSE RSU_AT_LOC;
 END IF;
 CLOSE ACTIVE_MTA;

END IF;

RETURN;

END FN_RSU_TO_MTA_DISPLAY;

/*-------------------------------------------------------------------------------------------------------------*/
-- to add and provision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
FUNCTION FN_SWAP_RSU_FOR_EMTA(P_OLD_SERIAL# IN VARCHAR, P_NEW_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_REUSABLE_FL IN VARCHAR, P_PORT IN NUMBER,
                              P_RSU_REMOVED_FL IN VARCHAR, P_SVC_UID_PK IN NUMBER, P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S')
  RETURN VARCHAR

  IS

  CURSOR GET_TECH_LOCATION IS
   SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
     FROM TECH_EMP_LOCATIONS, EMPLOYEES
    WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
      AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
      AND TEO_END_DATE IS NULL;

  CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
    SELECT IVL_UID_PK
      FROM INVENTORY_LOCATIONS
     WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

  CURSOR GET_IDENTIFIER IS
    SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
           SVC_UID_PK,
           TRT_UID_PK,
           SVC_OFF_SERV_SUBS_UID_FK,
           SVC_FEATURES_UID_FK,
           OST_SERVICE_TYPES_UID_FK,
           OST_BUSINESS_OFFICES_UID_FK,
           STY_SYSTEM_CODE
    FROM SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, TROUBLE_TICKETS, TROUBLE_DISPATCHES
    WHERE TDP_UID_PK = P_TDP_UID_PK
      AND TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
      AND SVC_UID_PK = TRT_SERVICES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK;

  CURSOR GET_IDENTIFIER_ON_SVC IS
    SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), STY_SYSTEM_CODE, OST_UID_PK
      FROM SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES
     WHERE SVC_UID_PK = P_SVC_UID_PK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK;

  CURSOR GET_PLNT_INFO(P_STY_UID_PK IN NUMBER, P_BSO_UID_PK IN NUMBER) IS
  SELECT OSF_UID_PK
    FROM OFFICE_SERV_FEATS, OFFICE_SERV_TYPES, FEATURES
   WHERE OST_UID_PK = OSF_OFFICE_SERV_TYPES_UID_FK
     AND FTP_UID_PK = OSF_FEATURES_UID_FK
     AND FTP_CODE = 'PLNT'
     AND OST_BUSINESS_OFFICES_UID_FK = P_BSO_UID_PK
     AND OST_SERVICE_TYPES_UID_FK = P_STY_UID_PK;

   cursor get_slo(p_svc_uid_pk in number) is
          select ssl_service_locations_uid_fk
            from service_locations, serv_serv_locations, services
           where ssl_services_uid_fk = svc_uid_pk
             and slo_uid_pk = ssl_service_locations_uid_fk
             and ssl_primary_loc_fl = 'Y'
             and ssl_end_date is null
             and svc_uid_pk = p_svc_uid_pk;

  CURSOR GET_SWT_EQUIPMENT(P_SEQ_CODE IN VARCHAR) IS
    SELECT SEQ_UID_PK
      FROM SWT_EQUIPMENT
     WHERE SEQ_SYSTEM_CODE = P_SEQ_CODE;

   cursor get_meu_type (p_slo_uid_pk in number) is
   SELECT DISTINCT MEU_MTA_TYPES_UID_FK, MEU_MTA_BOXES_UID_FK
     FROM MTA_EQUIP_UNITS
    WHERE MEU_SERVICE_LOCATIONS_UID_FK in
                   (select s2.slo_uid_pk
                   from service_locations s1, service_locations s2
                  where s1.slo_uid_pk = P_SLO_UID_PK
                    and s1.slo_municipalities_uid_fk = s2.slo_municipalities_uid_fk
                    and s1.slo_streets_uid_fk = s2.slo_streets_uid_fk
                    and ((s1.slo_street_nums_uid_fk = s2.slo_street_nums_uid_fk and s1.slo_street_nums_uid_fk is not null)
                     or (s2.slo_street_nums_uid_fk is null and s1.slo_street_nums_uid_fk is null))
                    and ((s1.slo_buildings_uid_fk = s2.slo_buildings_uid_fk and s1.slo_buildings_uid_fk is not null)
                     or (s2.slo_buildings_uid_fk is null and s1.slo_buildings_uid_fk is null))
                    and ((s1.slo_building_units_uid_fk = s2.slo_building_units_uid_fk and s1.slo_building_units_uid_fk is not null)
                     or (s2.slo_building_units_uid_fk is null and s1.slo_building_units_uid_fk is null)));

  CURSOR GET_MTA_TYPE(P_MTA_UID_PK IN NUMBER) IS
    SELECT MTA_MTA_TYPES_UID_FK
      FROM MTA_BOXES
     WHERE MTA_UID_PK = P_MTA_UID_PK;

   cursor get_svcs_with_box_loc (p_mta_uid_pk in number, p_slo_uid_pk in number) is
   SELECT DISTINCT SVC_UID_PK, GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK) IDENTIFIER
     FROM SERVICES, SERV_SERV_LOCATIONS, MTA_EQUIP_UNITS, MTA_PORTS, MTA_SERVICES, SERVICE_ASSGNMTS
    WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
      AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
      AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND MEU_MTA_BOXES_UID_FK = p_mta_uid_pk
      AND SVC_UID_PK = SVA_SERVICES_UID_FK
      AND SVC_UID_PK = SSL_SERVICES_UID_FK
      AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
      AND SSL_END_DATE IS NULL
      AND SSL_PRIMARY_LOC_FL = 'Y';

  CURSOR CHECK_EXIST_CANDIDATE(P_SVO_UID_PK IN NUMBER, P_SEQ_CODE IN VARCHAR) IS
   SELECT TO_CHAR(SO_CANDIDATES.MODIFIED_DATE,'MM-DD-YYYY HH:MI:SS AM')
     FROM SO_CANDIDATES, SWT_EQUIPMENT
    WHERE SOC_SO_UID_FK = P_SVO_UID_PK
      AND SEQ_UID_PK = SOC_SWT_EQUIPMENT_UID_FK
      AND SOC_ACTION_FL = 'A'
      AND SEQ_SYSTEM_CODE = P_SEQ_CODE;
      
CURSOR PACKET_CABLE_SUB(P_OST_UID_PK IN NUMBER, P_SVT_SYSTEM_CODE IN VARCHAR) IS
  SELECT OSB_UID_PK
  FROM OFF_SERV_SUBS, SERV_SUB_TYPES
  WHERE SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
    AND SVT_SYSTEM_CODE = P_SVT_SYSTEM_CODE
    AND OSB_OFFICE_SERV_TYPES_UID_FK = P_OST_UID_PK;

  V_IVL_UID_PK           NUMBER;
  V_SVO_UID_PK           NUMBER;
  V_SVC_UID_PK           NUMBER;
  V_MEU_MTY_UID_FK       NUMBER;
  V_MTA_MTY_UID_FK       NUMBER;
  V_MTA_EXIST_UID_FK     NUMBER;
  V_TVB_UID_PK           NUMBER;
  V_TRT_UID_PK           NUMBER;
  V_OSB_UID_PK           NUMBER;
  V_OSF_UID_PK           NUMBER;
  V_SLO_UID_PK           NUMBER;
  V_FTP_BUN_UID_PK       NUMBER;
  V_BBS_MES_UID_PK       NUMBER;
  V_STY_UID_PK           NUMBER;
  V_BSO_UID_PK           NUMBER;
  V_MEO_UID_PK           NUMBER;
  V_BBO_UID_PK           NUMBER;
  V_OPERATING_SYSTEM_ID  VARCHAR2(200);
  V_LAST_IVL_UID_PK      NUMBER;
  V_OST_UID_PK           NUMBER;
  V_SVT_CODE             VARCHAR2(40);
  V_OLD_MTA              VARCHAR2(40);
  V_OLD_CMAC             VARCHAR2(40);
  V_NEW_MTA              VARCHAR2(40);
  V_NEW_CMAC             VARCHAR2(40);
  V_LAST_IVL_DESCRIPTION VARCHAR2(200);
  V_EQUIP_TYPE_OLD       VARCHAR2(1);
  V_EQUIP_TYPE_NEW       VARCHAR2(1);
  V_MTA_UID_PK           NUMBER;
  V_MTA_UID_PK_NEW       NUMBER;
  V_STATUS               VARCHAR2(200);
  V_DUMMY                VARCHAR2(1);
  V_MTA_EXISTS_FL        VARCHAR2(1) := 'N';
  V_CABLE_MODEM_TYPE     VARCHAR2(1);
  V_TIME                 VARCHAR2(200);
  V_RETURN_MESSAGE       VARCHAR2(2000) := NULL;
  V_IDENTIFIER           VARCHAR2(200);
  V_IDENTIFIER_SVC_PARAM VARCHAR2(200);
  V_IDENTIFIER_DISPLAY   VARCHAR2(200) := NULL;
  V_DESCRIPTION          VARCHAR2(200);
  V_EMP_NAME             VARCHAR2(200);
  V_ACCOUNT              VARCHAR2(200);
  V_RSU_#                VARCHAR2(40);
  V_SUCCESS_FL           VARCHAR2(1);
  V_STY_SYSTEM_CODE      VARCHAR2(40);
  V_DATE                 DATE;
  V_STY_SYSTEM_CODE_SVC  VARCHAR2(40);
  V_MAC_MESSAGE          VARCHAR2(2000) := NULL;
  V_SEQ_CODE             VARCHAR2(20);
  V_ISP_CHAR_DATE        VARCHAR2(40);
  V_SEQ_UID_PK           NUMBER;
  V_SOR_COMMENT          VARCHAR2(2000);
  V_TYPE                 VARCHAR2(40);

  v_is_production_database  VARCHAR2(1);
  v_msg_suffix           VARCHAR2(100);
  
  v_return_msg  		VARCHAR2(4000);
	
	V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_SWAP_RSU_FOR_EMTA';
  
BEGIN

  OPEN GET_IDENTIFIER;
  FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK, V_TRT_UID_PK, V_OSB_UID_PK, V_FTP_BUN_UID_PK, V_STY_UID_PK, V_BSO_UID_PK, V_STY_SYSTEM_CODE;
  CLOSE GET_IDENTIFIER;

  OPEN GET_IDENTIFIER_ON_SVC;
  FETCH GET_IDENTIFIER_ON_SVC INTO V_IDENTIFIER_SVC_PARAM, V_STY_SYSTEM_CODE_SVC, V_OST_UID_PK;
  CLOSE GET_IDENTIFIER_ON_SVC;

  open get_slo(V_SVC_UID_PK);
  fetch get_slo into v_slo_uid_pk;
  close get_slo;
  
  IF P_PORT IS NULL THEN
     RETURN 'THE PORT WAS NOT ENTERED.  PLEASE MAKE SURE THE PORT NUMBER IS ENTERED';
  END IF;  

  OPEN GET_MEU_TYPE(V_SLO_UID_PK);
  FETCH GET_MEU_TYPE INTO V_MEU_MTY_UID_FK, V_MTA_EXIST_UID_FK;
  IF GET_MEU_TYPE%NOTFOUND THEN
     V_MEU_MTY_UID_FK := null;
  END IF;
  CLOSE GET_MEU_TYPE;

  --GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
  OPEN GET_TECH_LOCATION;
  FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
  CLOSE GET_TECH_LOCATION;

  IF V_IVL_UID_PK IS NULL THEN
     BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
     RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
  END IF;

  --***********************************************
  --CHECK TO REMOVE THE OLD SERIAL/MAC ADDRESS
  --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE_OLD := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_OLD_SERIAL#, V_MTA_UID_PK);

  --NOT FOUND
  IF V_EQUIP_TYPE_OLD  = 'N' AND P_OLD_SERIAL# IS NOT NULL THEN
     IF P_OLD_SERIAL# IS NOT NULL THEN
        BOX_MODEM_PKG.PR_EXCEPTION(P_OLD_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO REMOVE A BOX/MODEM FROM '||V_IDENTIFIER||' '||P_OLD_SERIAL#||' IS NOT FOUND IN THE SYSTEM');
        RETURN 'OLD SERIAL# NOT FOUND';
     END IF;
  END IF;

  --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE_NEW := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_NEW_SERIAL#, V_MTA_UID_PK_NEW);

  IF V_MTA_EXIST_UID_FK = V_MTA_UID_PK_NEW THEN --ALREADY ADDED SO DO NOT SEND BACK MESSAGES
     V_MTA_EXISTS_FL := 'Y';
  END IF;

  --NOT FOUND
  IF V_EQUIP_TYPE_NEW  = 'N' THEN
     BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A MTA TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND IN THE SYSTEM');
     RETURN 'SERIAL# NOT FOUND.  PLEASE MAKE SURE IT WAS ENTERED CORRECTLY.';
  END IF;

  IF V_MTA_EXISTS_FL = 'N' THEN
    --BOX STATUS CHECK
    V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_NEW_SERIAL#, V_EQUIP_TYPE_NEW, V_DESCRIPTION);
    IF V_STATUS NOT IN ('AN','AU','RT') THEN
       BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A MTA TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_STATUS);
       V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_NEW_SERIAL#);
       --IF V_ACCOUNT IS NOT NULL THEN
          --V_DESCRIPTION := V_DESCRIPTION||' ON '||V_ACCOUNT;
       --END IF;
       RETURN 'THIS MTA IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
    END IF;

    --LOCATION CHECK
    IF V_IVL_UID_PK IS NOT NULL THEN
       V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_NEW_SERIAL#);
       OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
       FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
       CLOSE LAST_LOCATION;

       IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
          IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
             BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A BOX/MODEM TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND ON THE TECHS TRUCK');
             RETURN 'THIS MTA IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
          END IF;
       END IF;
    END IF;
  END IF;

  OPEN GET_MTA_TYPE(V_MTA_UID_PK_NEW);
  FETCH GET_MTA_TYPE INTO V_MTA_MTY_UID_FK;
  CLOSE GET_MTA_TYPE;

  IF V_MEU_MTY_UID_FK IS NOT NULL AND V_MTA_MTY_UID_FK IS NOT NULL THEN
    IF V_MEU_MTY_UID_FK != V_MTA_MTY_UID_FK THEN
       RETURN 'THE MTA BOX TYPE MUST EQUAL THE TYPE OF BOX LINKED TO THIS SERVICE LOCATION.';
    END IF;
  END IF;

  V_CMTS_MESSAGE := FN_CHECK_VALID_CMTS(V_SLO_UID_PK);
  IF V_CMTS_MESSAGE IS NOT NULL THEN
   
   
     RETURN V_CMTS_MESSAGE;
  END IF;

  --********************END WITH THE OLD BOX/MODEM************************--

  --*********************************************
  --check for the addition of the new serial#

  --THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

  --ADD THE NEW SERIAL
  IF V_EQUIP_TYPE_NEW = 'E' THEN

    BOX_MODEM_PKG.PR_MTA_MACS(P_OLD_SERIAL#, V_OLD_MTA, V_OLD_CMAC);
    BOX_MODEM_PKG.PR_MTA_MACS(P_NEW_SERIAL#, V_NEW_MTA, V_NEW_CMAC);

    INSTALLER_WEB_PKG.CREATE_CS_ORDER(P_SVC_UID_PK, P_EMP_UID_PK, P_PORT, V_MTA_MTY_UID_FK, V_SVO_UID_PK, V_RSU_#, V_NEW_CMAC);

    COMMIT;
    IF V_SVO_UID_PK IS NOT NULL THEN
       
       IF V_STY_SYSTEM_CODE_SVC = 'BBS' THEN
          V_TYPE := FN_MTA_TYPE(V_SLO_UID_PK);
          OPEN PACKET_CABLE_SUB(V_OST_UID_PK, V_TYPE);
          FETCH PACKET_CABLE_SUB INTO V_OSB_UID_PK;
          IF PACKET_CABLE_SUB%FOUND THEN
             UPDATE SO
                SET SVO_OFF_SERV_SUBS_UID_FK = V_OSB_UID_PK
              WHERE SVO_UID_PK = V_SVO_UID_PK;
          END IF;
          CLOSE PACKET_CABLE_SUB;
       END IF;
       
       INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                           VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE MTA '||P_NEW_SERIAL#||' WAS ADDED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' BY TECHNICIAN '||V_EMP_NAME);
       
       ---HD 106376 RMC 07/19/2011 - Added the below code to insert message that CS is for Swap to complete provisioning and do not clear/close
       ---                           until the provisioning is complete.
       INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
			                            VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'CS SO IS FOR PROVISIONING THE SWAP/MAC ADDRESS CHANGE OF THE MODEM. DO NOT CLEAR/CLOSE UNTIL THE PROVISIONING HAS BEEN COMPLETED.');

       UPDATE MTA_EQUIP_UNITS
          SET MEU_MTA_BOXES_UID_FK = V_MTA_UID_PK_NEW
        WHERE MEU_UID_PK IN (SELECT MTP_MTA_EQUIP_UNITS_UID_FK
                               FROM MTA_PORTS, MTA_SO, SO_ASSGNMTS
                              WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
                                AND MTP_UID_PK = MTO_MTA_PORTS_UID_FK
                                AND SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
                                AND SON_SO_UID_FK = V_SVO_UID_PK);
      COMMIT;
    ELSE
       RETURN 'A PENDING CS ORDER ALREADY EXISTS FOR THIS SERVICE AND THE SWAP CANNOT BE COMPLETED.  PLEASE CALL PLANT TO COMPLETE THE CS ORDER BEFORE THE TROUBLE SWAP CAN OCCUR.';
    	 v_return_msg := 'A PENDING CS ORDER ALREADY EXISTS FOR THIS SERVICE AND THE SWAP CANNOT BE COMPLETED.  PLEASE CALL PLANT TO COMPLETE THE CS ORDER BEFORE THE TROUBLE SWAP CAN OCCUR.';
			 IF V_SVO_UID_PK IS NOT NULL THEN
			 		IF v_return_msg IS NOT NULL THEN
			 			 PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
			 		END IF;
		 	 END IF;
    END IF;

    INSERT INTO SERVICE_MESSAGES (SVM_UID_PK, SVM_SERVICES_UID_FK, SVM_ACTIVE_FL, SVM_DATE,
                                  SVM_TIME, SVM_TEXT, SVM_ENTERED_BY)
                           VALUES(SVM_SEQ.NEXTVAL, P_SVC_UID_PK, 'Y', SYSDATE, SYSDATE,
                                  'THE RSU FOR THE SERVICE HAS BEEN REPLACED USING A MTA BOX USING THE SWAP FEATURE ON IWP FOR TROUBLE TICKET '||V_TRT_UID_PK||'.  THE NEW MTA MAC IS '||P_NEW_SERIAL#||'.', USER);
    -- set up flag for database and success message to be appended for developemnt
    GET_RUN_ENVIRONMENT(P_DEVELOPMENT_ACTION,
                        v_is_production_database,
                        v_msg_suffix);
                        
    IF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION = C_DEV_SUCCESS THEN
      V_MAC_MESSAGE  := 'Y';
    ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION = C_DEV_FAILURE THEN
      V_MAC_MESSAGE  := 'ERROR';
    ELSIF P_OLD_SERIAL# IS NOT NULL AND V_STY_SYSTEM_CODE_SVC = 'BBS' THEN
       COMMIT;
       C_SVC_UID_PK := P_SVC_UID_PK;
       C_SVO_UID_PK := NULL;
       V_MAC_MESSAGE := INSTALLER_WEB_PKG.FN_SAM_MAC_CHANGE(P_OLD_SERIAL#, V_NEW_CMAC, NULL);
       IF V_MAC_MESSAGE = 'Y' THEN
          PR_INSERT_SWT_LOGS(V_SVO_UID_PK, 'TRIAD_XML', 'SUCCESS', 'CHANGE MAC', 'Y'); 
          PR_INSERT_SO_MESSAGE(V_SVO_UID_PK, 'CHANGE MAC WAS SELECTED TO CHANGE FROM MAC '||P_OLD_SERIAL#|| ' TO '||V_NEW_CMAC);
       END IF;
    ELSE
       V_MAC_MESSAGE := 'Y';
    END IF;

    IF V_MAC_MESSAGE = 'Y' THEN
      IF V_STY_SYSTEM_CODE_SVC = 'PHN' THEN

        V_SEQ_CODE := 'TRIAD_XML';

        OPEN GET_SWT_EQUIPMENT(V_SEQ_CODE);
        FETCH GET_SWT_EQUIPMENT INTO V_SEQ_UID_PK;
        CLOSE GET_SWT_EQUIPMENT;

        OPEN CHECK_EXIST_CANDIDATE(V_SVO_UID_PK, V_SEQ_CODE);
        FETCH CHECK_EXIST_CANDIDATE INTO V_ISP_CHAR_DATE ;
        IF CHECK_EXIST_CANDIDATE%NOTFOUND THEN
           INSERT INTO SO_CANDIDATES (SOC_UID_PK, SOC_SO_UID_FK, SOC_SWT_EQUIPMENT_UID_FK, SOC_ACTION_FL, SOC_DISPATCH_FL, SOC_ROUTED_FL, SOC_START_DATE,
                                      SOC_PRIORITY, SOC_WORK_ATTEMPTS, SOC_CABLE_WORK_FL)
                              VALUES (SOC_SEQ.NEXTVAL, V_SVO_UID_PK, V_SEQ_UID_PK, 'A', 'N', 'N', SYSDATE, 0, 1, 'N');
        ELSE
           UPDATE SO_CANDIDATES
              SET SOC_CABLE_WORK_FL = 'N',
                  SOC_START_DATE = SYSDATE,
                  SOC_WORK_ATTEMPTS = 1,
                  SOC_PRIORITY = 0,
                  SOC_ROUTED_FL = 'N',
                  SOC_DISPATCH_FL = 'N'
            WHERE SOC_SO_UID_FK = V_SVO_UID_PK
             AND SOC_ACTION_FL = 'A'
             AND SOC_SWT_EQUIPMENT_UID_FK IN (SELECT SEQ_UID_PK
                                                FROM SWT_EQUIPMENT
                                               WHERE SEQ_CODE = V_SEQ_CODE);

        END IF;
        CLOSE CHECK_EXIST_CANDIDATE;

        COMMIT;
        OPEN CHECK_EXIST_CANDIDATE(V_SVO_UID_PK, V_SEQ_CODE);
        FETCH CHECK_EXIST_CANDIDATE INTO V_ISP_CHAR_DATE;
        CLOSE CHECK_EXIST_CANDIDATE;

        IF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION = C_DEV_SUCCESS THEN
          insert into swt_logs (SLS_UID_PK, SLS_SO_UID_FK, SLS_SWT_EQUIPMENT_UID_FK, 
                                SLS_SUCCESS_FL, SLS_COMMAND_SENT, SLS_CREATED_TIME, 
                                SLS_RESPONSE)
                         values(sls_seq.nextval, V_SVO_UID_PK, CODE_PKG.GET_PK('SWT_EQUIPMENT','TRIAD_XML'), 
                               'Y', 'TEST', SYSDATE, 
                               'SUCCESS');
        ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION = C_DEV_FAILURE THEN
          insert into swt_logs (SLS_UID_PK, SLS_SO_UID_FK, SLS_SWT_EQUIPMENT_UID_FK, 
                                SLS_SUCCESS_FL, SLS_COMMAND_SENT, SLS_CREATED_TIME, 
                                SLS_RESPONSE)
                         values(sls_seq.nextval, V_SVO_UID_PK, CODE_PKG.GET_PK('SWT_EQUIPMENT','TRIAD_XML'), 
                               'N', 'TEST', SYSDATE, 
                               'ERROR');
        END IF;
    
        V_TIME := TO_CHAR(SYSDATE + .003,'MM-DD-YYYY HH:MI:SS AM');
        WHILE SYSDATE < TO_DATE(V_TIME,'MM-DD-YYYY HH:MI:SS AM')
        LOOP
           OPEN CHECK_SWT_LOGS('TRIAD_XML', V_ISP_CHAR_DATE, V_SVO_UID_PK);
           FETCH CHECK_SWT_LOGS INTO V_SOR_COMMENT;
           IF CHECK_SWT_LOGS%FOUND THEN
              EXIT;
           ELSE
              OPEN CHECK_SWT_LOGS_ERROR('TRIAD_XML', V_ISP_CHAR_DATE, V_SVO_UID_PK);
              FETCH CHECK_SWT_LOGS_ERROR INTO V_SOR_COMMENT, V_DATE;
              IF CHECK_SWT_LOGS_ERROR%FOUND THEN
                
                
                 CLOSE CHECK_SWT_LOGS_ERROR;
                 CLOSE CHECK_SWT_LOGS;
                 RETURN 'Order updated, but provisioning failed on Triad provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.'|| v_msg_suffix;
              	 v_return_msg := 'Order updated, but provisioning failed on Triad provisioning with an error of '||V_SOR_COMMENT||'.  Please call 815-1900.'|| v_msg_suffix;
								 IF V_SVO_UID_PK IS NOT NULL THEN
								 		IF v_return_msg IS NOT NULL THEN
								 			 PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
								 		END IF;
		 	 					 END IF;
              
              END IF;
              CLOSE CHECK_SWT_LOGS_ERROR;
           END IF;
           CLOSE CHECK_SWT_LOGS;
        END LOOP;
         
        IF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION = C_DEV_SUCCESS THEN 
          V_SUCCESS_FL := 'Y';
        ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION = C_DEV_FAILURE THEN
          V_SUCCESS_FL := 'T';
        ELSE
          --CHANGE MAC ADDRESS IN SAM
          V_SUCCESS_FL := INSTALLER_WEB_PKG.FN_OSSGATE_REPROVISION(V_SVO_UID_PK);
        END IF;
          
        IF V_SUCCESS_FL = 'T' THEN
           V_ERROR := INSTALLER_WEB_PKG.FN_SWT_LOGS_ERROR(V_SVO_UID_PK);
            
            
           UPDATE SO
              SET SVO_SO_STATUS_UID_FK = (SELECT SOS_UID_PK FROM SO_STATUS WHERE SOS_SYSTEM_CODE = 'VOID')
            WHERE SVO_UID_PK = V_SVO_UID_PK;
      
      		 COMMIT;
           
           RETURN 'RE-PROVISIONING ERROR OCCURED IN OSSGATE.  PLEASE CALL PLANT.  ERROR WAS :'||V_ERROR|| v_msg_suffix;
           v_return_msg := 'RE-PROVISIONING ERROR OCCURED IN OSSGATE.  PLEASE CALL PLANT.  ERROR WAS :'||V_ERROR|| v_msg_suffix;
					 IF V_SVO_UID_PK IS NOT NULL THEN
					 		IF v_return_msg IS NOT NULL THEN
					 			 PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 		END IF;
		 	 		 END IF;
        END IF;
      END IF;
    ELSE
      PR_INSERT_SWT_LOGS(V_SVO_UID_PK, 'TRIAD_XML', V_MAC_MESSAGE, 'CHANGE MAC');
      PR_INSERT_SO_MESSAGE(V_SVO_UID_PK, V_MAC_MESSAGE);
      
      
      UPDATE SO
         SET SVO_SO_STATUS_UID_FK = (SELECT SOS_UID_PK FROM SO_STATUS WHERE SOS_SYSTEM_CODE = 'VOID')
       WHERE SVO_UID_PK = V_SVO_UID_PK;
      
      COMMIT;
      RETURN 'Error in Triad.  '||V_MAC_MESSAGE||' Please call plant.'|| v_msg_suffix;
      v_return_msg := 'Error in Triad.  '||V_MAC_MESSAGE||' Please call plant.'|| v_msg_suffix;
			IF V_SVO_UID_PK IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
						PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
		 	END IF;
    END IF;

     /*UPDATE MTA_EQUIP_UNITS
        SET MEU_MTA_BOXES_UID_FK = V_MTA_UID_PK_NEW
      WHERE MEU_UID_PK IN (SELECT MTP_MTA_EQUIP_UNITS_UID_FK
                             FROM MTA_PORTS, MTA_SO, SO_ASSGNMTS
                            WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
                              AND MTP_UID_PK = MTO_MTA_PORTS_UID_FK
                              AND SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
                              AND SON_SO_UID_FK = V_SVO_UID_PK);*/

  END IF;

  IF P_OLD_SERIAL# IS NOT NULL THEN
    IF P_REUSABLE_FL = 'Y' THEN
       V_DESCRIPTION := 'REPAIR INSTALLATION REUSE';
    ELSE
       V_DESCRIPTION := 'REPAIR INSTALLATION';
    END IF;

    INSERT INTO SERVICE_MESSAGES(SVM_UID_PK, SVM_SERVICES_UID_FK, SVM_ENTERED_BY, SVM_DATE, SVM_TIME, SVM_TEXT, SVM_ACTIVE_FL)
                             VALUES(SVM_SEQ.NEXTVAL, P_SVC_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE CABLE MODEM '||P_OLD_SERIAL#||' WAS REMOVED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' BY TECHNICIAN '||V_EMP_NAME, 'Y');

    BOX_MODEM_PKG.PR_REMOVE_ACCT(P_OLD_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, V_DESCRIPTION, V_IVL_UID_PK);

  END IF;

  IF P_RSU_REMOVED_FL = 'Y' AND v_slo_uid_pk IS NOT NULL THEN
     UPDATE REM_SERV_UNITS
        SET RSU_DELETE_FL = 'Y'
      WHERE RSU_RSU_# = V_RSU_#
        AND RSU_SERVICE_LOCATIONS_UID_FK = v_slo_uid_pk;
  ELSE
     UPDATE REM_SERV_UNITS
        SET RSU_DEFAULT_DEDICATION = 'S',
            RSU_SERVICE_LOCATIONS_UID_FK = NULL,
            RSU_RSU_STATUS_UID_FK = (SELECT RST_UID_PK FROM RSU_STATUS WHERE RST_SYSTEM_CODE = 'AV')
      WHERE RSU_RSU_# = V_RSU_#
        AND RSU_SERVICE_LOCATIONS_UID_FK = v_slo_uid_pk;
  END IF;

  
  UPDATE SERVICE_ASSGNMTS
     SET SVA_CABLE_MODEMS_UID_FK = NULL
   WHERE SVA_SERVICES_UID_FK = P_SVC_UID_PK;

  UPDATE SO
     SET SVO_SO_STATUS_UID_FK = (SELECT SOS_UID_PK FROM SO_STATUS WHERE SOS_SYSTEM_CODE = 'RDY TO CLOSE')
   WHERE SVO_UID_PK = V_SVO_UID_PK;

  --TAKEN OUT HANDLED ON THE RAILS SIDE
  --IF V_MTA_EXISTS_FL = 'N' THEN
     V_RETURN_MESSAGE := 'SWAP COMPLETED SUCCESSFULLY.  PLEASE REFRESH YOUR PAGE IN ABOUT A MINUTE TO SEE THE NEW MTA ADDED.'|| v_msg_suffix;
  --END IF;

  IF V_LAST_IVL_DESCRIPTION = 'LOCATION NOT FOUND' THEN --ALSO ADD A RECORD TO ISSUE AN AUTO RECEIVE IN, INTO THE TECH TRUCK LOCATION
     BOX_MODEM_PKG.PR_RECEIVE_STB_INTO_INV(P_NEW_SERIAL#, V_IVL_UID_PK, NULL, NULL);
  END IF;

  BOX_MODEM_PKG.PR_ADD_ACCT(P_NEW_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, 'ADD ACCT WEB');

  COMMIT;

  RETURN V_RETURN_MESSAGE;

END FN_SWAP_RSU_FOR_EMTA;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_ADD_ADSL(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_SON_UID_PK IN NUMBER, P_MAC IN VARCHAR, P_GW_FL IN VARCHAR DEFAULT 'N')
RETURN VARCHAR IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
  SELECT IVL_UID_PK
    FROM INVENTORY_LOCATIONS
   WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

CURSOR GET_EMPLOYEE IS
 SELECT EMP_FNAME||' '||EMP_LNAME
   FROM EMPLOYEES
  WHERE EMP_UID_PK = P_EMP_UID_PK;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
         CUS_BUSINESS_OFFICES_UID_FK, SVC_UID_PK, SOT_SYSTEM_CODE
  FROM CUSTOMERS, ACCOUNTS, SERVICES, SO_TYPES, SO
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;

CURSOR SERV_SUB_TYPE IS
  SELECT OSB_OFFICE_SERV_TYPES_UID_FK, SVT_SYSTEM_CODE
  FROM OFF_SERV_SUBS, SO, SERV_SUB_TYPES
  WHERE OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
    AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;

CURSOR GET_SLO IS
  SELECT SSX_SERVICE_LOCATIONS_UID_FK
    FROM SERV_SERV_LOC_SO
   WHERE SSX_SO_UID_FK = P_SVO_UID_PK
     AND SSX_END_DATE IS NULL;

CURSOR GET_DSLAM_PORT IS
  SELECT SON_DSLAM_PORTS_UID_FK
    FROM SO_ASSGNMTS
   WHERE SON_UID_PK = P_SON_UID_PK
     AND SON_DSLAM_PORTS_UID_FK IS NOT NULL;

CURSOR CHECK_EXISTS (P_ADM_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SO_ASSGNMTS
   WHERE SON_SO_UID_FK = P_SVO_UID_PK
     AND SON_ADSL_MODEMS_UID_FK = P_ADM_UID_PK;

V_DUMMY                VARCHAR2(1);
V_DSP_UID_PK           NUMBER;
V_SLO_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_BSO_UID_PK           NUMBER;
V_IVL_UID_PK           NUMBER;
V_OSB_UID_PK           NUMBER;
V_OST_UID_PK           NUMBER;
V_SOT_SYSTEM_CODE      VARCHAR2(20);
V_SEQ_UID_PK           NUMBER;
V_TIME                 VARCHAR2(200);
V_SVT_CODE             VARCHAR2(40);
V_SOR_COMMENT          VARCHAR2(2000);
V_IDENTIFIER           VARCHAR2(300);
V_DESCRIPTION          VARCHAR2(300);
V_EMP_NAME             VARCHAR2(300);
V_EQUIP_TYPE           VARCHAR2(20);
V_ADM_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_LAST_IVL_UID_PK      NUMBER;
V_LAST_IVL_DESCRIPTION VARCHAR2(200);
V_ACCOUNT              VARCHAR2(200);
V_DATE                 DATE;
V_COUNTER              NUMBER := 0;
V_ADSL_FOUND_FL        VARCHAR2(1) := 'N';
V_ADSL_VDSL            VARCHAR2(4);

v_return_msg  		VARCHAR2(4000);

V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_ADD_ADSL';

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_BSO_UID_PK, V_SVC_UID_PK, V_SOT_SYSTEM_CODE;
CLOSE GET_IDENTIFIER;

OPEN SERV_SUB_TYPE;
FETCH SERV_SUB_TYPE INTO V_OST_UID_PK, V_SVT_CODE;
CLOSE SERV_SUB_TYPE;

--GET SLO PK
OPEN GET_SLO;
FETCH GET_SLO INTO V_SLO_UID_PK;
CLOSE GET_SLO;

--DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_ADM_UID_PK);

IF V_EQUIP_TYPE = 'A' THEN
 V_ADSL_VDSL := 'ADSL';
ELSIF V_EQUIP_TYPE = 'V' THEN
 V_ADSL_VDSL := 'VDSL';
END IF;

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'SERIAL# NOT FOUND.  PLEASE MAKE SURE YOU SCANNED THE ADSL MODEM MAC ADDRESS';
   v_return_msg := 'SERIAL# NOT FOUND.  PLEASE MAKE SURE YOU SCANNED THE ADSL MODEM MAC ADDRESS';
	 IF P_SVO_UID_PK IS NOT NULL THEN
	 		IF v_return_msg IS NOT NULL THEN
	 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 		END IF;
	 END IF;
ELSIF V_EQUIP_TYPE  = 'S' THEN
   RETURN 'YOU CANNOT SCAN A CABLE BOX IN THE '||V_ADSL_VDSL||' SECTION.';
   v_return_msg := 'YOU CANNOT SCAN A CABLE BOX IN THE '||V_ADSL_VDSL||' SECTION.';
	 IF P_SVO_UID_PK IS NOT NULL THEN
	 	 	IF v_return_msg IS NOT NULL THEN
	 	 		 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	 	END IF;
	 END IF;
ELSIF V_EQUIP_TYPE  = 'M' THEN
   RETURN 'YOU CANNOT SCAN A CABLE MODEM IN THE '||V_ADSL_VDSL||' SECTION.';
   v_return_msg := 'YOU CANNOT SCAN A CABLE MODEM IN THE '||V_ADSL_VDSL||' SECTION.';
	 IF P_SVO_UID_PK IS NOT NULL THEN
	 	 	IF v_return_msg IS NOT NULL THEN
	 	 	 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	 	END IF;
	 END IF;
ELSIF V_EQUIP_TYPE  = 'E' THEN
   RETURN 'YOU CANNOT SCAN AN MTA BOX IN THE '||V_ADSL_VDSL||' SECTION.';
   v_return_msg := 'YOU CANNOT SCAN AN MTA BOX IN THE '||V_ADSL_VDSL||' SECTION.';
	 IF P_SVO_UID_PK IS NOT NULL THEN
	 	 	IF v_return_msg IS NOT NULL THEN
	 	 	 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	 	END IF;
	 END IF;
END IF;

OPEN CHECK_EXISTS(V_ADM_UID_PK);
FETCH CHECK_EXISTS INTO V_DUMMY;
IF CHECK_EXISTS%FOUND THEN
   V_ADSL_FOUND_FL := 'Y';
ELSE
   V_ADSL_FOUND_FL := 'N';
END IF;
CLOSE CHECK_EXISTS;

--SECTION ONE TO CHECK FOR VALIDATION ISSUES

IF V_ADSL_FOUND_FL = 'N' THEN
   IF V_IVL_UID_PK IS NULL THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
      RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
      v_return_msg := 'THIS TECH IS NOT SET UP ON A TRUCK';
			IF P_SVO_UID_PK IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
				 	 	PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
	 		END IF;
   END IF;

   --BOX STATUS CHECK
   V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_MAC, V_EQUIP_TYPE, V_DESCRIPTION);
   IF V_STATUS NOT IN ('AN','AU','RT') THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN AN '||V_ADSL_VDSL||' MODEM TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_DESCRIPTION);
      V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_MAC);
      --IF V_ACCOUNT IS NOT NULL THEN
         --V_DESCRIPTION := V_DESCRIPTION||' ON '||V_ACCOUNT;
      --END IF;
      RETURN 'THIS '||V_ADSL_VDSL||' MODEM IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
      v_return_msg := 'THIS '||V_ADSL_VDSL||' MODEM IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
			IF P_SVO_UID_PK IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
						PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
	 		END IF;
   END IF;

   --LOCATION CHECK
   IF V_IVL_UID_PK IS NOT NULL THEN
      V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_MAC);
      OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
      FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
      CLOSE LAST_LOCATION;

      IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
         IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
            BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN AN '||V_ADSL_VDSL||' MODEM TO '||V_IDENTIFIER||' '||P_MAC||' IS NOT FOUND ON THE TECHS TRUCK');
            RETURN 'THIS '||V_ADSL_VDSL||' MODEM IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
         		v_return_msg := 'THIS '||V_ADSL_VDSL||' MODEM IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
						IF P_SVO_UID_PK IS NOT NULL THEN
							 IF v_return_msg IS NOT NULL THEN
									PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
							 END IF;
	 					END IF;
         END IF;
      END IF;
   END IF;
END IF;

----------------------------------------------------------------------

IF V_EQUIP_TYPE = 'A' THEN
   OPEN GET_DSLAM_PORT;
   FETCH GET_DSLAM_PORT INTO V_DSP_UID_PK;
   IF GET_DSLAM_PORT%FOUND THEN
     IF P_GW_FL = 'N' THEN
      UPDATE SO_ASSGNMTS
         SET SON_ADSL_MODEMS_UID_FK = V_ADM_UID_PK
       WHERE SON_DSLAM_PORTS_UID_FK = V_DSP_UID_PK
         AND SON_SO_UID_FK in (SELECT SVO_UID_PK
                                 FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                                WHERE SVO_UID_PK = SON_SO_UID_FK
                                  AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                                  AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                                  AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                                  AND SVT_SYSTEM_CODE IN ('ADSL','VDSL')
                                  AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
     ELSE
      UPDATE SO_ASSGNMTS
         SET SON_ADSL_MODEMS_GW_UID_FK = V_ADM_UID_PK
       WHERE SON_DSLAM_PORTS_UID_FK = V_DSP_UID_PK
         AND SON_SO_UID_FK in (SELECT SVO_UID_PK
                                 FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                                WHERE SVO_UID_PK = SON_SO_UID_FK
                                  AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                                  AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                                  AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                                  AND SVT_SYSTEM_CODE IN ('ADSL','VDSL')
                                  AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
     END IF;
     
                                  

      BOX_MODEM_PKG.PR_ADD_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'ADD ACCT WEB');

      INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                          VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE '||V_ADSL_VDSL||' MODEM '||P_MAC||' WAS ADDED BY TECHNICIAN '||V_EMP_NAME);

      COMMIT;
      CLOSE GET_DSLAM_PORT;
      RETURN 'THE '||V_ADSL_VDSL||' MODEM HAS BEEN SUCCESSFULLY ADDED TO THE ASSIGNMENT RECORD IN HES.';
      v_return_msg := 'THE '||V_ADSL_VDSL||' MODEM HAS BEEN SUCCESSFULLY ADDED TO THE ASSIGNMENT RECORD IN HES.';
			IF P_SVO_UID_PK IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
						PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
 	 		END IF;
   ELSIF P_GW_FL = 'Y' THEN 
   -- MCV 02/04/16 FOR adding gateway on FTTH with no DSLAM port
       UPDATE so_assgnmts
             SET son_adsl_modems_gw_uid_fk = v_adm_uid_pk
           WHERE son_uid_pk = p_son_uid_pk ;   
      
      box_modem_pkg.pr_add_acct(p_mac, v_identifier, v_svc_uid_pk, p_svo_uid_pk, 'ADD ACCT WEB');

      INSERT INTO so_messages(sog_uid_pk, sog_so_uid_fk, sog_entered_by, sog_date, sog_time, sog_text)
                          VALUES(sog_seq.NEXTVAL, p_svo_uid_pk, 'IWP', SYSDATE, SYSDATE, 'THE '||V_ADSL_VDSL||' MODEM '||P_MAC||' WAS ADDED BY TECHNICIAN '||V_EMP_NAME);

      COMMIT;
      
      CLOSE get_dslam_port;
      
      RETURN 'THE '||V_ADSL_VDSL||' MODEM HAS BEEN SUCCESSFULLY ADDED TO THE ASSIGNMENT RECORD IN HES.';
      
      v_return_msg := 'THE '||V_ADSL_VDSL||' MODEM HAS BEEN SUCCESSFULLY ADDED TO THE ASSIGNMENT RECORD IN HES.';
      IF p_svo_uid_pk IS NOT NULL THEN
             IF v_return_msg IS NOT NULL THEN
                    PR_INS_SO_ERROR_LOGS(p_svo_uid_pk, v_sel_procedure_name, v_return_msg);
             END IF;
      END IF;       
        
   END IF;
   CLOSE GET_DSLAM_PORT;


END IF;

RETURN 'NO DSLAM RECORD WAS FOUND ON THE ASSIGNMENT AND THE MODEM WAS NOT ADDED';
v_return_msg := 'THE '||V_ADSL_VDSL||' MODEM HAS BEEN SUCCESSFULLY ADDED TO THE ASSIGNMENT RECORD IN HES.';
IF P_SVO_UID_PK IS NOT NULL THEN
	 IF v_return_msg IS NOT NULL THEN
			PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 END IF;
END IF;

END FN_ADD_ADSL;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_REMOVE_ADSL(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MAC IN VARCHAR, P_REUSE_FL IN VARCHAR, P_TRT_UID_PK IN NUMBER DEFAULT NULL, P_GW_FL IN VARCHAR DEFAULT 'N')

RETURN VARCHAR

IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
  FROM SERVICES, SO, SO_TYPES
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK
 UNION  
 SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
  FROM SERVICES, TROUBLE_TICKETS
  WHERE SVC_UID_PK = TRT_SERVICES_UID_FK
    AND TRT_UID_PK = P_TRT_UID_PK;

V_IVL_UID_PK           NUMBER;
V_SVO_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_SLO_UID_PK           NUMBER;
V_RETURN_MESSAGE       VARCHAR2(2000);
V_EQUIP_TYPE           VARCHAR2(1);
V_ADM_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_TIME                 VARCHAR2(200);
V_SOR_COMMENT          VARCHAR2(2000);
V_IDENTIFIER           VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);
V_TYPE                 VARCHAR2(1);

V_ADSL_VDSL            VARCHAR2(4);

v_return_msg  		VARCHAR2(4000);

V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_REMOVE_ADSL';


BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
CLOSE GET_IDENTIFIER;

--DTERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_ADM_UID_PK);

IF V_EQUIP_TYPE = 'A' THEN
 V_ADSL_VDSL := 'ADSL';
ELSIF V_EQUIP_TYPE = 'V' THEN
 V_ADSL_VDSL := 'VDSL';
END IF;

IF V_IVL_UID_PK IS NULL THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
   RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
   v_return_msg := 'THIS TECH IS NOT SET UP ON A TRUCK';
	 IF P_SVO_UID_PK IS NOT NULL THEN
	 	 IF v_return_msg IS NOT NULL THEN
	 			PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	 END IF;
	 END IF;
END IF;

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
   v_return_msg := 'MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
	 IF P_SVO_UID_PK IS NOT NULL THEN
	 	 	IF v_return_msg IS NOT NULL THEN
	 	 		 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	 	END IF;
	 END IF;
END IF;

--THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

IF V_EQUIP_TYPE = 'A' THEN
  IF P_GW_FL = 'N' THEN
   
   UPDATE SO_ASSGNMTS
      SET SON_ADSL_MODEMS_UID_FK = NULL
    WHERE SON_ADSL_MODEMS_UID_FK = V_ADM_UID_PK
      AND SON_SO_UID_FK in (SELECT SVO_UID_PK
                              FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                             WHERE SVO_UID_PK = SON_SO_UID_FK
                               AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                               AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                               AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                               AND SVT_SYSTEM_CODE IN ('ADSL','VDSL')
                               AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
   update service_assgnmts
      set sva_adsl_modems_uid_fk = null
    where sva_adsl_modems_uid_fk = V_ADM_UID_PK;
    
  ELSE
   UPDATE SO_ASSGNMTS
      SET SON_ADSL_MODEMS_GW_UID_FK = NULL
    WHERE SON_ADSL_MODEMS_GW_UID_FK = V_ADM_UID_PK
      AND SON_SO_UID_FK in (SELECT SVO_UID_PK
                              FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                             WHERE SVO_UID_PK = SON_SO_UID_FK
                               AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                               AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                               AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                               -- MCV 02/16/16 can be on any sub-type AND SVT_SYSTEM_CODE IN ('ADSL','VDSL')
                               AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
   update service_assgnmts
      set sva_adsl_modems_GW_uid_fk = null
    where sva_adsl_modems_GW_uid_fk = V_ADM_UID_PK;
  END IF;
   
  IF P_SVO_UID_PK IS NOT NULL THEN
     V_TYPE := 'S';
  ELSE
     V_TYPE := 'T';
  END IF;
   
  PR_INSERT_SO_MESSAGE(NVL(P_SVO_UID_PK,P_TRT_UID_PK), 'THE '||V_ADSL_VDSL||' MODEM '||P_MAC||' WAS REMOVED BY TECHNICIAN '||V_EMP_NAME, P_EMP_UID_PK, V_TYPE);

END IF;

COMMIT;

IF P_REUSE_FL = 'Y' THEN
   V_STATUS := 'REMOVE INSTALLATION';
ELSE
   V_STATUS := 'REMOVE INSTALLATION BAD';
END IF;

BOX_MODEM_PKG.PR_REMOVE_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, V_STATUS, V_IVL_UID_PK);
COMMIT;

RETURN V_ADSL_VDSL||' MODEM SUCESSFULLY REMOVED FROM THE ACCOUNT AND ADDED TO YOUR INVENTORY.';
v_return_msg := V_ADSL_VDSL||' MODEM SUCESSFULLY REMOVED FROM THE ACCOUNT AND ADDED TO YOUR INVENTORY.';
IF P_SVO_UID_PK IS NOT NULL THEN
	 IF v_return_msg IS NOT NULL THEN
	 	 	PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 END IF;
END IF;

END FN_REMOVE_ADSL;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_SWAP_ADSL(P_OLD_SERIAL# IN VARCHAR, P_NEW_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_SVA_UID_PK IN NUMBER, P_ADD_FL IN VARCHAR, P_GW_FL IN VARCHAR DEFAULT 'N')
RETURN VARCHAR

IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
  SELECT IVL_UID_PK
    FROM INVENTORY_LOCATIONS
   WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
         SVC_UID_PK,
         TRT_UID_PK,
         SVC_OFF_SERV_SUBS_UID_FK,
         SVC_FEATURES_UID_FK,
         OST_SERVICE_TYPES_UID_FK,
         OST_BUSINESS_OFFICES_UID_FK
  FROM SERVICES, OFFICE_SERV_TYPES, TROUBLE_TICKETS, TROUBLE_DISPATCHES
  WHERE TDP_UID_PK = P_TDP_UID_PK
    AND TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
    AND SVC_UID_PK = TRT_SERVICES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK;

CURSOR GET_PLNT_INFO(P_STY_UID_PK IN NUMBER, P_BSO_UID_PK IN NUMBER) IS
SELECT OSF_UID_PK
  FROM OFFICE_SERV_FEATS, OFFICE_SERV_TYPES, FEATURES
 WHERE OST_UID_PK = OSF_OFFICE_SERV_TYPES_UID_FK
   AND FTP_UID_PK = OSF_FEATURES_UID_FK
   AND FTP_CODE = 'PLNT'
   AND OST_BUSINESS_OFFICES_UID_FK = P_BSO_UID_PK
   AND OST_SERVICE_TYPES_UID_FK = P_STY_UID_PK;

 cursor get_slo(p_svc_uid_pk in number) is
        select ssl_service_locations_uid_fk
          from service_locations, serv_serv_locations, services
         where ssl_services_uid_fk = svc_uid_pk
           and slo_uid_pk = ssl_service_locations_uid_fk
           and ssl_primary_loc_fl = 'Y'
           and ssl_end_date is null
           and svc_uid_pk = p_svc_uid_pk;

CURSOR GET_DSLAM_PORT  IS
  SELECT DISTINCT SVA_DSLAM_PORTS_UID_FK, sva_line#
    FROM SERVICE_ASSGNMTS
   WHERE SVA_UID_PK = P_SVA_UID_PK;

CURSOR GET_SVCS (P_DSP_UID_PK IN NUMBER) IS
  SELECT DISTINCT SVA_SERVICES_UID_FK
    FROM SERVICE_ASSGNMTS
   WHERE SVA_DSLAM_PORTS_UID_FK = P_DSP_UID_PK;

CURSOR get_svcs_gw (p_adm_uid_pk IN NUMBER, p_sva_uid_pk NUMBER) IS
  SELECT DISTINCT sva_services_uid_fk
    FROM service_assgnmts
   WHERE sva_adsl_modems_gw_uid_fk = p_adm_uid_pk
  UNION
  SELECT DISTINCT sva_services_uid_fk
    FROM service_assgnmts
   WHERE sva_uid_pk = p_sva_uid_pk  ;


CURSOR GET_ASSGN_ADSL(P_SVC_UID_PK IN NUMBER) IS
  SELECT SVA_SERVICE_LOCATIONS_UID_FK,
         SVA_SAI_UID_FK,
         SVA_DSX_CONNECTIONS_UID_FK,
         SVA_LENS_UID_FK,
         SVA_NC_CODES_UID_FK,
         SVA_NCI_CODES_UID_FK,
         SVA_SUBTYPE_CODES_UID_FK,
         SVA_LEAD_ROUTES_UID_FK,
         SVA_CLLIS_UID_FK,
         SVA_AREAS_UID_FK,
         SVA_LINE#,
         SVA_OPX,
         SVA_BNN_PHONE#,
         SVA_BAND,
         SVA_WIRE,
         SVA_REMARKS,
         SVA_PEDESTAL,
         SVA_PROTECTOR,
         SVA_DSLAM_PORTS_UID_FK,
         SVA_ADSL_MODEMS_UID_FK,
         SVA_DSX3_CONNECTIONS_UID_FK,
         SVA_BONDED_FL,
         SVA_HSD_FL,
         SVA_UID_PK
     FROM SERVICE_ASSGNMTS
    WHERE SVA_SERVICES_UID_FK = P_SVC_UID_PK;

CURSOR CHECK_EXISTS (P_ADM_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SERVICE_ASSGNMTS
   WHERE SVA_ADSL_MODEMS_UID_FK = P_ADM_UID_PK
     AND SVA_SERVICES_UID_FK = P_SVC_UID_PK;

CURSOR CHECK_PENDING_CS (P_SVC_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SO, SO_STATUS, SO_TYPES
   WHERE SOS_UID_PK = SVO_SO_STATUS_UID_FK
     AND SVO_SERVICES_UID_FK = P_SVC_UID_PK
     AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
     AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED')
     AND SOT_SYSTEM_CODE = 'CS';

V_IVL_UID_PK           NUMBER;
V_SVO_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_TVB_UID_PK           NUMBER;
V_TRT_UID_PK           NUMBER;
V_OSB_UID_PK           NUMBER;
V_OSF_UID_PK           NUMBER;
V_SLO_UID_PK           NUMBER;
V_FTP_BUN_UID_PK       NUMBER;
V_STY_UID_PK           NUMBER;
V_BSO_UID_PK           NUMBER;
V_MEO_UID_PK           NUMBER;
V_BBO_UID_PK           NUMBER;
V_SON_UID_PK           NUMBER;
V_DSP_UID_PK           NUMBER;
V_OPERATING_SYSTEM_ID  VARCHAR2(200);
V_LAST_IVL_UID_PK      NUMBER;
V_OST_UID_PK           NUMBER;
V_SVT_CODE             VARCHAR2(40);
V_LAST_IVL_DESCRIPTION VARCHAR2(200);
V_EQUIP_TYPE_OLD       VARCHAR2(1);
V_EQUIP_TYPE_NEW       VARCHAR2(1);
V_ADM_UID_PK           NUMBER;
V_ADM_UID_PK_NEW       NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_TIME                 VARCHAR2(200);
V_RETURN_MESSAGE       VARCHAR2(2000) := NULL;
V_IDENTIFIER           VARCHAR2(200);
V_IDENTIFIER_DISPLAY   VARCHAR2(200) := NULL;
V_DESCRIPTION          VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);
V_ACCOUNT              VARCHAR2(200);
v_error_message        VARCHAR2(2000);
V_ADSL_FOUND_FL        VARCHAR2(1) := 'N';
V_SVA_LINE#            NUMBER;
V_ADSL_VDSL_OLD        VARCHAR2(4);
V_ADSL_VDSL_NEW        VARCHAR2(4);

v_return_msg  		VARCHAR2(4000);

V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_SWAP_ADSL';

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK, V_TRT_UID_PK, V_OSB_UID_PK, V_FTP_BUN_UID_PK, V_STY_UID_PK, V_BSO_UID_PK;
CLOSE GET_IDENTIFIER;

open get_slo(V_SVC_UID_PK);
fetch get_slo into v_slo_uid_pk;
close get_slo;

IF V_IVL_UID_PK IS NULL THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
   RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
END IF;

IF P_OLD_SERIAL# = P_NEW_SERIAL# THEN
   RETURN 'THE OLD MAC ADDRESS CANNOT MATCH THE NEW MAC ADDRESS';
END IF;

IF P_ADD_FL = 'N' THEN
   --***********************************************
   --CHECK TO REMOVE THE OLD SERIAL/MAC ADDRESS
   --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
   V_EQUIP_TYPE_OLD := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_OLD_SERIAL#, V_ADM_UID_PK);
   
   IF V_EQUIP_TYPE_OLD = 'A' THEN
      V_ADSL_VDSL_OLD := 'ADSL';
   ELSIF V_EQUIP_TYPE_OLD = 'V' THEN
         V_ADSL_VDSL_OLD := 'VDSL';
   END IF;

   --NOT FOUND
   IF V_EQUIP_TYPE_OLD = 'N' THEN
      IF P_OLD_SERIAL# IS NOT NULL THEN
         BOX_MODEM_PKG.PR_EXCEPTION(P_OLD_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO REMOVE AN ADSL/VDSL FROM '||V_IDENTIFIER||' '||P_OLD_SERIAL#||' IS NOT FOUND IN THE SYSTEM');
         RETURN 'OLD SERIAL# NOT FOUND';
      ELSE
         RETURN 'OLD SERIAL# NOT FOUND';
      END IF;
   ELSIF V_EQUIP_TYPE_OLD != 'A' THEN
      RETURN 'THE MAC ADDRESS ENTERED FOR THE OLD SERIAL# IS NOT FOR AN ADSL MODEM OR VDSL MODEM.  PLEASE MAKE SURE IT WAS ENTERED CORRECTLY.';
   END IF;
END IF;

--DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE_NEW := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_NEW_SERIAL#, V_ADM_UID_PK_NEW);

IF V_EQUIP_TYPE_NEW = 'A' THEN
  V_ADSL_VDSL_NEW := 'ADSL';
ELSIF V_EQUIP_TYPE_NEW = 'V' THEN
  V_ADSL_VDSL_NEW := 'VDSL';
END IF;

--NOT FOUND
IF V_EQUIP_TYPE_NEW  = 'N' THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN AN ADSL/VDSL MODEM TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND IN THE SYSTEM');
   RETURN 'NEW MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
END IF;

OPEN CHECK_EXISTS(V_ADM_UID_PK_NEW, V_SVC_UID_PK);
FETCH CHECK_EXISTS INTO V_DUMMY;
IF CHECK_EXISTS%FOUND THEN
   V_ADSL_FOUND_FL := 'Y';
ELSE
   V_ADSL_FOUND_FL := 'N';
END IF;
CLOSE CHECK_EXISTS;

IF V_ADSL_FOUND_FL = 'N' THEN

   --BOX STATUS CHECK
   V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_NEW_SERIAL#, V_EQUIP_TYPE_NEW, V_DESCRIPTION);
   IF V_STATUS NOT IN ('AN','AU','RT') THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN AN '||V_ADSL_VDSL_NEW||' MODEM TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_STATUS);
      V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_NEW_SERIAL#);
      --IF V_ACCOUNT IS NOT NULL THEN
         --V_DESCRIPTION := V_DESCRIPTION||' ON '||V_ACCOUNT;
      --END IF;
      RETURN 'THIS '||V_ADSL_VDSL_NEW||' MODEM IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
   END IF;

   --LOCATION CHECK
   IF V_IVL_UID_PK IS NOT NULL THEN
      V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_NEW_SERIAL#);
      OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
      FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
      CLOSE LAST_LOCATION;

      IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
         IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
            BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN AN '||V_ADSL_VDSL_NEW||' MODEM TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND ON THE TECHS TRUCK');
            RETURN 'THIS '||V_ADSL_VDSL_NEW||' MODEM IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
         END IF;
      END IF;
   END IF;
END IF;

IF P_ADD_FL = 'N' THEN
   BOX_MODEM_PKG.PR_REMOVE_ACCT(P_OLD_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, NULL, 'REPAIR INSTALLATION', V_IVL_UID_PK);
END IF;

--********************END WITH THE OLD BOX/MODEM************************--
--NJJ 12-03-2010 CHANGE TO NOT JUST LOOK IF THE CURSOR IS NOT FOUND, BUT ALSO IF THE V_DSP_UID_PK IS NULL
OPEN GET_DSLAM_PORT;
FETCH GET_DSLAM_PORT INTO V_DSP_UID_PK, V_SVA_LINE#;
IF (GET_DSLAM_PORT%NOTFOUND OR V_DSP_UID_PK IS NULL) AND P_GW_FL = 'N' THEN
   CLOSE GET_DSLAM_PORT;
   RETURN 'NO DSLAM PORT FOUND ON THE ASSIGNMENTS RECORDS.  PLEASE CALL PLANT AT 815-1900.';
END IF;
CLOSE GET_DSLAM_PORT;

IF v_dsp_uid_pk IS NOT NULL THEN 
    FOR REC IN GET_SVCS(V_DSP_UID_PK) LOOP

        INSERT INTO SERVICE_MESSAGES(SVM_UID_PK, SVM_SERVICES_UID_FK, SVM_ENTERED_BY, SVM_DATE, SVM_TIME, SVM_TEXT, SVM_ACTIVE_FL)
                                 VALUES(SVM_SEQ.NEXTVAL, REC.SVA_SERVICES_UID_FK, 'IWP', SYSDATE, SYSDATE, 'THE '||V_ADSL_VDSL_OLD||' MODEM '||P_OLD_SERIAL#||' WAS REMOVED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' BY TECHNICIAN '||V_EMP_NAME, 'Y');

        --ADD THE NEW SERIAL
        IF V_EQUIP_TYPE_NEW = 'A' THEN

              if not generate_so_pkg.fn_create_cs_so(REC.SVA_SERVICES_UID_FK,
                                                                                         trunc(sysdate),
                                                                                         sysdate,
                                                                                         'Y',
                                                                         USER,
                                                                         USER,
                                                                         'PLANT_SO',
                                                                         v_svo_uid_pk ,
                                                                         v_error_message) THEN
                    RETURN 'ERROR FOUND WHEN CREATING A CS ORDER TO COMPLETE THE SWAP';
             Else
               --add the plnt feature code to the order.
               if not generate_so_pkg.fn_add_feature_to_so(v_svo_uid_pk,'PLNT',1,v_error_message) THEN
                    RETURN 'ERROR FOUND WHEN CREATING A CS ORDER AND ADDING THE PLNT CODE TO COMPLETE THE SWAP';
                    v_return_msg := 'ERROR FOUND WHEN CREATING A CS ORDER AND ADDING THE PLNT CODE TO COMPLETE THE SWAP';
                                    IF v_svo_uid_pk IS NOT NULL THEN
                                         IF v_return_msg IS NOT NULL THEN
                                                PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
                                         END IF;
                                    END IF;
               else
                    if generate_so_pkg.fn_save_so(v_svo_uid_pk,v_error_message) THEN
                             insert into so_messages(SOG_UID_PK,
                                                                             SOG_SO_UID_FK,
                                                                             SOG_ENTERED_BY,
                                                                             SOG_DATE,
                                                                             SOG_TIME,
                                                                             SOG_TEXT,
                                                                             CREATED_DATE,
                                                                             CREATED_BY)
                                                            values (sog_seq.nextval,
                                                                            v_svo_uid_pk,
                                                                            user,
                                                                            trunc(sysdate),
                                                                            sysdate,
                                                                            'REASON: '|| 'CS ORDER CREATED TO COMPLETE A TROUBLE TICKET SWAP ON AN '||V_ADSL_VDSL_OLD||' MODEM FROM '||P_OLD_SERIAL#||' TO '||P_NEW_SERIAL#,
                                                                            sysdate,
                                                                            user);
                end if;
             end if;
           end if;

           update so
              set svo_so_status_uid_fk = (select sos_uid_pk from so_status where sos_system_code = 'CLOSED'),
                  SVO_CLOSED_BY_EMP_UID_FK = p_emp_uid_pk,
                  svo_close_date = trunc(sysdate),
                  svo_close_time = sysdate
            where svo_uid_pk = v_svo_uid_pk;

           commit;

           IF P_ADD_FL = 'N' THEN
              
            IF P_GW_FL = 'N' THEN
              UPDATE SERVICE_ASSGNMTS
                 SET SVA_ADSL_MODEMS_UID_FK = V_ADM_UID_PK_NEW
               WHERE SVA_ADSL_MODEMS_UID_FK = V_ADM_UID_PK;

              UPDATE SO_ASSGNMTS
                 SET SON_ADSL_MODEMS_UID_FK = V_ADM_UID_PK_NEW
               WHERE SON_ADSL_MODEMS_UID_FK = V_ADM_UID_PK
                 AND SON_SO_UID_FK in (SELECT SVO_UID_PK
                                FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                               WHERE SVO_UID_PK = SON_SO_UID_FK
                                 AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                                 AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                                 AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                                 AND SVO_SERVICES_UID_FK = REC.SVA_SERVICES_UID_FK
                                 AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
            ELSE
              UPDATE SERVICE_ASSGNMTS
                 SET SVA_ADSL_MODEMS_GW_UID_FK = V_ADM_UID_PK_NEW
               WHERE SVA_ADSL_MODEMS_GW_UID_FK = V_ADM_UID_PK;

              UPDATE SO_ASSGNMTS
                 SET SON_ADSL_MODEMS_GW_UID_FK = V_ADM_UID_PK_NEW
               WHERE SON_ADSL_MODEMS_GW_UID_FK = V_ADM_UID_PK
                 AND SON_SO_UID_FK in (SELECT SVO_UID_PK
                                FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                               WHERE SVO_UID_PK = SON_SO_UID_FK
                                 AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                                 AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                                 AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                                 AND SVO_SERVICES_UID_FK = REC.SVA_SERVICES_UID_FK
                                 AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
            END IF;
          ELSE
            IF P_GW_FL = 'N' THEN
              UPDATE SERVICE_ASSGNMTS
                 SET SVA_ADSL_MODEMS_UID_FK = V_ADM_UID_PK_NEW
               WHERE SVA_UID_PK = P_SVA_UID_PK;

              UPDATE SO_ASSGNMTS
                 SET SON_ADSL_MODEMS_UID_FK = V_ADM_UID_PK_NEW
               WHERE SON_LINE# = V_SVA_LINE#
                 AND SON_SO_UID_FK in (SELECT SVO_UID_PK
                                FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                               WHERE SVO_UID_PK = SON_SO_UID_FK
                                 AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                                 AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                                 AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                                 AND SVO_SERVICES_UID_FK = REC.SVA_SERVICES_UID_FK
                                 AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
            ELSE
              UPDATE SERVICE_ASSGNMTS
                 SET SVA_ADSL_MODEMS_GW_UID_FK = V_ADM_UID_PK_NEW
               WHERE SVA_UID_PK = P_SVA_UID_PK;

              UPDATE SO_ASSGNMTS
                 SET SON_ADSL_MODEMS_GW_UID_FK = V_ADM_UID_PK_NEW
               WHERE SON_LINE# = V_SVA_LINE#
                 AND SON_SO_UID_FK in (SELECT SVO_UID_PK
                                FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                               WHERE SVO_UID_PK = SON_SO_UID_FK
                                 AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                                 AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                                 AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                                 AND SVO_SERVICES_UID_FK = REC.SVA_SERVICES_UID_FK
                                 AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
            
            END IF;
          END IF; 
       END IF;

       COMMIT;

    END LOOP;
 -- MCV 02/04/2016 for RG on FTTH    
ELSIF P_GW_FL = 'Y' THEN
    FOR rec IN get_svcs_gw(v_adm_uid_pk, p_sva_uid_pk) LOOP

        INSERT INTO service_messages(svm_uid_pk, svm_services_uid_fk, svm_entered_by, svm_date, svm_time, svm_text, svm_active_fl)
                                 VALUES(svm_seq.NEXTVAL, rec.sva_services_uid_fk, 'IWP', SYSDATE, SYSDATE, 'THE '||V_ADSL_VDSL_OLD||' MODEM '||P_OLD_SERIAL#||' WAS REMOVED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' BY TECHNICIAN '||V_EMP_NAME, 'Y');

        --ADD THE NEW SERIAL
        IF v_equip_type_new = 'A' THEN

              IF NOT generate_so_pkg.fn_create_cs_so(rec.sva_services_uid_fk,
                                                                                         trunc(sysdate),
                                                                                         sysdate,
                                                                                         'Y',
                                                                         USER,
                                                                         USER,
                                                                         'PLANT_SO',
                                                                         v_svo_uid_pk ,
                                                                         v_error_message) THEN
                    RETURN 'ERROR FOUND WHEN CREATING A CS ORDER TO COMPLETE THE SWAP';
             ELSE
               --add the plnt feature code to the order.
               IF NOT generate_so_pkg.fn_add_feature_to_so(v_svo_uid_pk,'PLNT',1,v_error_message) THEN
                    RETURN 'ERROR FOUND WHEN CREATING A CS ORDER AND ADDING THE PLNT CODE TO COMPLETE THE SWAP';
                    v_return_msg := 'ERROR FOUND WHEN CREATING A CS ORDER AND ADDING THE PLNT CODE TO COMPLETE THE SWAP';
                                    IF v_svo_uid_pk IS NOT NULL THEN
                                         IF v_return_msg IS NOT NULL THEN
                                                pr_ins_so_error_logs(v_svo_uid_pk, v_sel_procedure_name, v_return_msg);
                                         END IF;
                                    END IF;
               ELSE
                    IF generate_so_pkg.fn_save_so(v_svo_uid_pk,v_error_message) THEN
                             INSERT INTO so_messages(sog_uid_pk,
                                                                             sog_so_uid_fk,
                                                                             sog_entered_by,
                                                                             sog_date,
                                                                             sog_time,
                                                                             sog_text,
                                                                             created_date,
                                                                             created_by)
                                                            VALUES (sog_seq.NEXTVAL,
                                                                            v_svo_uid_pk,
                                                                            USER,
                                                                            TRUNC(SYSDATE),
                                                                            SYSDATE,
                                                                            'REASON: '|| 'CS ORDER CREATED TO COMPLETE A TROUBLE TICKET SWAP ON AN '||V_ADSL_VDSL_OLD||' MODEM FROM '||P_OLD_SERIAL#||' TO '||P_NEW_SERIAL#,
                                                                            SYSDATE,
                                                                            USER);
                END IF;
             END IF;
           END IF;

           UPDATE so
              SET svo_so_status_uid_fk = (SELECT sos_uid_pk FROM so_status WHERE sos_system_code = 'CLOSED'),
                  SVO_CLOSED_BY_EMP_UID_FK = p_emp_uid_pk,
                  svo_close_date = TRUNC(SYSDATE),
                  svo_close_time = SYSDATE
            WHERE svo_uid_pk = v_svo_uid_pk;

           COMMIT;

           IF p_add_fl = 'N' THEN
              
              UPDATE service_assgnmts
                 SET sva_adsl_modems_gw_uid_fk = v_adm_uid_pk_new
               WHERE sva_adsl_modems_gw_uid_fk = v_adm_uid_pk;

              UPDATE so_assgnmts
                 SET son_adsl_modems_gw_uid_fk = v_adm_uid_pk_new
               WHERE son_adsl_modems_gw_uid_fk = v_adm_uid_pk
                 AND son_so_uid_fk in (SELECT svo_uid_pk
                                FROM so, so_status, off_serv_subs, serv_sub_types
                               WHERE svo_uid_pk = son_so_uid_fk
                                 AND osb_uid_pk = svo_off_serv_subs_uid_fk
                                 AND svt_uid_pk = osb_serv_sub_types_uid_fk
                                 AND sos_uid_pk = svo_so_status_uid_fk
                                 AND svo_services_uid_fk = rec.sva_services_uid_fk
                                 AND sos_system_code NOT IN ('VOID','CLOSED'));
          ELSE
              UPDATE service_assgnmts
                 SET sva_adsl_modems_gw_uid_fk = v_adm_uid_pk_new
               WHERE sva_uid_pk = p_sva_uid_pk;

              UPDATE so_assgnmts
                 SET son_adsl_modems_gw_uid_fk = v_adm_uid_pk_new
               WHERE son_line# = v_sva_line#
                 AND son_so_uid_fk IN (SELECT svo_uid_pk
                                FROM so, so_status, off_serv_subs, serv_sub_types
                               WHERE svo_uid_pk = son_so_uid_fk
                                 AND osb_uid_pk = svo_off_serv_subs_uid_fk
                                 AND svt_uid_pk = osb_serv_sub_types_uid_fk
                                 AND sos_uid_pk = svo_so_status_uid_fk
                                 AND svo_services_uid_fk = rec.sva_services_uid_fk
                                 AND sos_system_code NOT IN ('VOID','CLOSED'));
            
          END IF; 
       END IF;

       COMMIT; 
    END LOOP;
 END IF;

IF P_ADD_FL = 'N' THEN
   V_RETURN_MESSAGE := 'SWAP COMPLETED SUCCESSFULLY.';
ELSE
   V_RETURN_MESSAGE := 'ADD COMPLETED SUCCESSFULLY.';
END IF;

IF V_LAST_IVL_DESCRIPTION = 'LOCATION NOT FOUND' THEN --ALSO ADD A RECORD TO ISSUE AN AUTO RECEIVE IN, INTO THE TECH TRUCK LOCATION
   BOX_MODEM_PKG.PR_RECEIVE_STB_INTO_INV(P_NEW_SERIAL#, V_IVL_UID_PK, NULL, NULL);
END IF;

BOX_MODEM_PKG.PR_ADD_ACCT(P_NEW_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, 'ADD ACCT WEB');

COMMIT;

RETURN V_RETURN_MESSAGE;

END FN_SWAP_ADSL;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_GET_TROUBLE_HISTORY (P_CUS_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

CURSOR TROUBLE_HISTORY IS
select trt_uid_pk,
       get_identifier_fun(svc_uid_pk, ost_uid_pk) identifier,
       sty_code,
       to_char(TRT_START_DATE,'mm-dd-yyyy') trt_date,
       trt_comment,
       tdp_comment,
       emp_fname||' '||emp_lname employee_name,
       TRT_START_DATE,
       'T' TYPE
from accounts, services, office_serv_types, service_types, trouble_tickets, trouble_dispatches, trbl_dsp_techs, employees
where acc_uid_pk = svc_accounts_uid_fk
  and svc_uid_pk = trt_services_uid_fk
  and trt_uid_pk = tdp_trouble_tickets_uid_fk
  and ost_uid_pk = svc_office_serv_types_uid_fk
  and sty_uid_pk = ost_service_types_uid_fk
  and TDT_UID_PK = TDP_TRBL_DSP_TECHS_UID_FK
  and emp_uid_pk = TDT_EMPLOYEES_UID_FK
  and acc_customers_uid_fk = P_CUS_UID_PK
UNION
select svo_uid_pk,
       get_identifier_fun(svc_uid_pk, ost_uid_pk) identifier,
       sty_code,
       to_char(SDS_SCHEDULE_DATE,'mm-dd-yyyy') trt_date,
       sot_code,
       sds_comment,
       emp_fname||' '||emp_lname employee_name,
       SDS_SCHEDULE_DATE,
       'S' TYPE
from accounts, services, office_serv_types, service_types, so, so_types, so_loadings, employees
where acc_uid_pk = svc_accounts_uid_fk
  and svc_uid_pk = svo_services_uid_fk
  and svo_uid_pk = sds_so_uid_fk
  and ost_uid_pk = svc_office_serv_types_uid_fk
  and sty_uid_pk = ost_service_types_uid_fk
  and sot_uid_pk = svo_so_types_uid_fk
  and emp_uid_pk = SDS_EMPLOYEES_UID_FK
  and emp_contractor_company_uid_fk is not null
  and acc_customers_uid_fk = P_CUS_UID_PK;

rec     TROUBLE_HISTORY%rowtype;
v_rec   generic_data_type;

BEGIN

 OPEN TROUBLE_HISTORY;
 LOOP
    FETCH TROUBLE_HISTORY into rec;
    EXIT WHEN TROUBLE_HISTORY%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_number1    := rec.trt_uid_pk;          -- trt_uid_pk
     v_rec.gdt_alpha1     := rec.identifier;          -- service identifier
     v_rec.gdt_alpha2     := rec.sty_code;            -- service type
     v_rec.gdt_alpha3     := rec.trt_date;            -- trouble ticket start date in varchar format
     v_rec.gdt_alpha4     := rec.trt_comment;         -- initial trouble comment
     v_rec.gdt_alpha5     := rec.tdp_comment;         -- dispatch comment
     v_rec.gdt_alpha6     := rec.employee_name;       -- employee name
     v_rec.gdt_date1      := rec.trt_start_date;      -- trouble start date in date format
     v_rec.gdt_alpha7     := rec.type;                -- type

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE TROUBLE_HISTORY;

RETURN;

END FN_GET_TROUBLE_HISTORY;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_GET_STATUS_OPTIONS
RETURN generic_data_table PIPELINED IS

CURSOR CODES IS
SELECT AVC_CODE, AVC_DESCRIPTION
 FROM AVAILABLE_CODES
 WHERE AVC_CODE IN ('AN','AU','RT');

rec     CODES%rowtype;
v_rec   generic_data_type;

BEGIN

 OPEN CODES;
 LOOP
    FETCH CODES into rec;
    EXIT WHEN CODES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1    := rec.avc_code;          -- code
     v_rec.gdt_alpha2    := rec.avc_description;   -- description

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE CODES;

RETURN;

END FN_GET_STATUS_OPTIONS;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_GET_TRUCK_LOCATION(P_EMP_UID_PK IN NUMBER)
RETURN NUMBER

--THIS WILL RETURN THE TRUCK LOCATION PK FOR THE EMPLOYEE LOGGED IN

IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

  V_IVL_UID_PK   NUMBER;

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK;
CLOSE GET_TECH_LOCATION;

RETURN V_IVL_UID_PK;

END FN_GET_TRUCK_LOCATION;

FUNCTION FN_GET_SUP_TRUCK_LOCATIONS(P_EMP_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED

--THIS WILL RETURN THE TRUCK LOCATION PK FOR THE EMPLOYEE LOGGED IN
--NJJ 10/04/10 - Changed to comment out the supervisor param line in the GET_TECH_LOCATION
--cursor per helpdesk call 98829

IS

CURSOR GET_SUPERVISOR IS
 SELECT IVL_SUP_EMP_UID_FK
   FROM TECH_EMP_LOCATIONS, INVENTORY_LOCATIONS
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND IVL_UID_PK = TEO_INV_LOCATIONS_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR GET_TECH_LOCATION(P_SUP_UID_PK IN NUMBER) IS
 SELECT EMP_LNAME||' '||EMP_FNAME||' - '||IVL_DESCRIPTION DISPLAY, IVL_UID_PK
   FROM TECH_EMP_LOCATIONS, INVENTORY_LOCATIONS, EMPLOYEES
  WHERE --IVL_SUP_EMP_UID_FK = P_SUP_UID_PK
    IVL_UID_PK = TEO_INV_LOCATIONS_UID_FK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

V_IVL_UID_PK   NUMBER;
V_SUP_UID_PK   NUMBER;
rec            GET_TECH_LOCATION%rowtype;
v_rec          generic_data_type;

BEGIN

OPEN GET_SUPERVISOR;
FETCH GET_SUPERVISOR INTO V_SUP_UID_PK;
CLOSE GET_SUPERVISOR;

 OPEN GET_TECH_LOCATION(V_SUP_UID_PK);
 LOOP
    FETCH GET_TECH_LOCATION into rec;
    EXIT WHEN GET_TECH_LOCATION%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1    := rec.DISPLAY;         -- tech name and truck#
     v_rec.gdt_alpha2    := rec.ivl_uid_pk;      -- location pk

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE GET_TECH_LOCATION;

RETURN;

END FN_GET_SUP_TRUCK_LOCATIONS;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_TRANSFER_TRUCK_TO_TRUCK(P_IVL_UID_PK IN NUMBER, P_MAC_ADDRESS IN VARCHAR)
RETURN VARCHAR

--THIS WILL TRANSFER FROM ONE TRUCK TO ANOTHER

IS

  V_IVL_UID_PK   NUMBER;
  V_ITI_UID_PK   NUMBER;
  V_IVT_UID_PK   NUMBER;

BEGIN

SELECT IVT_SEQ.NEXTVAL INTO V_IVT_UID_PK FROM DUAL;

SELECT ITI_SEQ.NEXTVAL INTO V_ITI_UID_PK FROM DUAL;

BOX_MODEM_PKG.PR_XFER_STB_INTO_INV(P_IVL_UID_PK, P_MAC_ADDRESS, V_IVT_UID_PK, V_ITI_UID_PK);

commit;

RETURN 'Transfer Successfully Completed';

END FN_TRANSFER_TRUCK_TO_TRUCK;

FUNCTION FN_OSSGATE_DEPROVISION(P_SVO_UID_PK IN NUMBER, P_ACTION_FL IN VARCHAR DEFAULT NULL)
RETURN VARCHAR

IS

--THIS WILL PERFORM THE STEP FOR OSSGATE DE-PROVISIONING

CURSOR GET_SWT_EQUIPMENT(P_SEQ_CODE IN VARCHAR) IS
  SELECT SEQ_UID_PK
    FROM SWT_EQUIPMENT
   WHERE SEQ_SYSTEM_CODE = P_SEQ_CODE;

CURSOR CHECK_EXIST_CANDIDATE(P_SEQ_CODE IN VARCHAR, P_FLAG IN VARCHAR) IS
 SELECT TO_CHAR(SO_CANDIDATES.MODIFIED_DATE,'MM-DD-YYYY HH:MI:SS AM')
   FROM SO_CANDIDATES, SWT_EQUIPMENT
  WHERE SOC_SO_UID_FK = P_SVO_UID_PK
    AND SEQ_UID_PK = SOC_SWT_EQUIPMENT_UID_FK
    AND SEQ_SYSTEM_CODE = P_SEQ_CODE
    AND SOC_ACTION_FL = P_FLAG;

CURSOR OSSGATE_CHECK(P_DATE IN VARCHAR, P_SVO_UID_PK IN NUMBER) IS
select SWT_COMPLETED_FL
from swt_PROV_TRANS, swt_equipment
where swt_so_uid_fk = P_SVO_UID_PK
  and SWT_SWT_EQUIPMENT_UID_FK = seq_uid_pk
  and SEQ_SYSTEM_CODE = 'OSSGATE'
  and swt_type_code = 'SVO'
  and swt_action_code = 'A'
  and swt_PROV_TRANS.created_date > sysdate-5/1440
  and swt_PROV_TRANS.created_date >= to_date(P_DATE,'MM-DD-YYYY HH:MI:SS AM');

V_SUCCESS_FL           VARCHAR2(1);
V_SEQ_CODE             VARCHAR2(20);
V_SOT_SYSTEM_CODE      VARCHAR2(20);
V_SEQ_UID_PK           NUMBER;
V_TIME                 VARCHAR2(200);
V_DATE                 DATE;
V_OSS_CHAR_DATE        VARCHAR2(40);
V_ACTION_FL            VARCHAR2(1);

BEGIN

   IF P_ACTION_FL IS NULL THEN
      V_ACTION_FL := 'X';
   ELSE
      V_ACTION_FL := P_ACTION_FL;
   END IF;

   V_SEQ_CODE := 'OSSGATE';
   OPEN GET_SWT_EQUIPMENT(V_SEQ_CODE);
   FETCH GET_SWT_EQUIPMENT INTO V_SEQ_UID_PK;
   CLOSE GET_SWT_EQUIPMENT;

   OPEN CHECK_EXIST_CANDIDATE(V_SEQ_CODE, V_ACTION_FL);
   FETCH CHECK_EXIST_CANDIDATE INTO V_OSS_CHAR_DATE ;
   IF CHECK_EXIST_CANDIDATE%NOTFOUND THEN
      INSERT INTO SO_CANDIDATES (SOC_UID_PK, SOC_SO_UID_FK, SOC_SWT_EQUIPMENT_UID_FK, SOC_ACTION_FL, SOC_DISPATCH_FL, SOC_ROUTED_FL, SOC_START_DATE,
                                 SOC_PRIORITY, SOC_WORK_ATTEMPTS, SOC_CABLE_WORK_FL)
                         VALUES (SOC_SEQ.NEXTVAL, P_SVO_UID_PK, V_SEQ_UID_PK, V_ACTION_FL, 'N', 'N', SYSDATE, 0, 1, 'N');
      V_OSS_CHAR_DATE := TO_CHAR(SYSDATE,'MM-DD-YYYY HH:MI:SS AM');
   ELSE
      UPDATE SO_CANDIDATES
         SET SOC_CABLE_WORK_FL = 'N',
             SOC_START_DATE = SYSDATE,
             SOC_WORK_ATTEMPTS = 1,
             SOC_PRIORITY = 0,
             SOC_ROUTED_FL = 'N',
             SOC_DISPATCH_FL = 'N'
       WHERE SOC_SO_UID_FK = P_SVO_UID_PK
         AND SOC_ACTION_FL = V_ACTION_FL
         AND SOC_SWT_EQUIPMENT_UID_FK IN (SELECT SEQ_UID_PK
                                            FROM SWT_EQUIPMENT
                                           WHERE SEQ_CODE = V_SEQ_CODE);
   END IF;
   CLOSE CHECK_EXIST_CANDIDATE;

   COMMIT;

   OPEN CHECK_EXIST_CANDIDATE(V_SEQ_CODE, V_ACTION_FL);
   FETCH CHECK_EXIST_CANDIDATE INTO V_OSS_CHAR_DATE;
   CLOSE CHECK_EXIST_CANDIDATE;

   V_TIME := TO_CHAR(SYSDATE + .002,'MM-DD-YYYY HH:MI:SS AM');
   V_SUCCESS_FL := 'T';
   WHILE SYSDATE < TO_DATE(V_TIME,'MM-DD-YYYY HH:MI:SS AM')
   LOOP
      OPEN OSSGATE_CHECK(V_OSS_CHAR_DATE, P_SVO_UID_PK);
      FETCH OSSGATE_CHECK INTO V_SUCCESS_FL;
      IF OSSGATE_CHECK%FOUND THEN
         EXIT;
      END IF;
      CLOSE OSSGATE_CHECK;
   END LOOP;

RETURN V_SUCCESS_FL;

END FN_OSSGATE_DEPROVISION;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_OSSGATE_REPROVISION(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR

IS

--THIS WILL PERFORM THE STEP FOR OSSGATE DE-PROVISIONING

CURSOR GET_SWT_EQUIPMENT(P_SEQ_CODE IN VARCHAR) IS
  SELECT SEQ_UID_PK
    FROM SWT_EQUIPMENT
   WHERE SEQ_SYSTEM_CODE = P_SEQ_CODE;

CURSOR CHECK_EXIST_CANDIDATE(P_SEQ_CODE IN VARCHAR) IS
 SELECT TO_CHAR(SO_CANDIDATES.MODIFIED_DATE,'MM-DD-YYYY HH:MI:SS AM')
   FROM SO_CANDIDATES, SWT_EQUIPMENT
  WHERE SOC_SO_UID_FK = P_SVO_UID_PK
    AND SEQ_UID_PK = SOC_SWT_EQUIPMENT_UID_FK
    AND SEQ_SYSTEM_CODE = P_SEQ_CODE
    AND SOC_ACTION_FL = 'X';

CURSOR OSSGATE_CHECK(P_DATE IN VARCHAR, P_SVO_UID_PK IN NUMBER) IS
select SWT_COMPLETED_FL
from swt_PROV_TRANS, swt_equipment
where swt_so_uid_fk = P_SVO_UID_PK
  and SWT_SWT_EQUIPMENT_UID_FK = seq_uid_pk
  and swt_type_code = 'SVO'
  and swt_action_code = 'A'
  and SEQ_SYSTEM_CODE = 'OSSGATE'
  and swt_PROV_TRANS.created_date > sysdate-5/1440
  and swt_PROV_TRANS.created_date >= to_date(P_DATE,'MM-DD-YYYY HH:MI:SS AM');

V_SUCCESS_FL           VARCHAR2(1);
V_SEQ_CODE             VARCHAR2(20);
V_SOT_SYSTEM_CODE      VARCHAR2(20);
V_SEQ_UID_PK           NUMBER;
V_TIME                 VARCHAR2(200);
V_DATE                 DATE;
V_OSS_CHAR_DATE        VARCHAR2(40);

BEGIN

   V_SEQ_CODE := 'OSSGATE';
   OPEN GET_SWT_EQUIPMENT(V_SEQ_CODE);
   FETCH GET_SWT_EQUIPMENT INTO V_SEQ_UID_PK;
   CLOSE GET_SWT_EQUIPMENT;

   OPEN CHECK_EXIST_CANDIDATE(V_SEQ_CODE);
   FETCH CHECK_EXIST_CANDIDATE INTO V_OSS_CHAR_DATE ;
   IF CHECK_EXIST_CANDIDATE%NOTFOUND THEN
      INSERT INTO SO_CANDIDATES (SOC_UID_PK, SOC_SO_UID_FK, SOC_SWT_EQUIPMENT_UID_FK, SOC_ACTION_FL, SOC_DISPATCH_FL, SOC_ROUTED_FL, SOC_START_DATE,
                                 SOC_PRIORITY, SOC_WORK_ATTEMPTS, SOC_CABLE_WORK_FL)
                         VALUES (SOC_SEQ.NEXTVAL, P_SVO_UID_PK, V_SEQ_UID_PK, 'X', 'N', 'N', SYSDATE, 0, 1, 'N');

      V_OSS_CHAR_DATE := TO_CHAR(SYSDATE,'MM-DD-YYYY HH:MI:SS AM');
   ELSE
      UPDATE SO_CANDIDATES
         SET SOC_CABLE_WORK_FL = 'N',
             SOC_START_DATE = SYSDATE,
             SOC_WORK_ATTEMPTS = 1,
             SOC_PRIORITY = 0,
             SOC_ROUTED_FL = 'N',
             SOC_DISPATCH_FL = 'N'
       WHERE SOC_SO_UID_FK = P_SVO_UID_PK
         AND SOC_ACTION_FL = 'X'
         AND SOC_SWT_EQUIPMENT_UID_FK IN (SELECT SEQ_UID_PK
                                            FROM SWT_EQUIPMENT
                                           WHERE SEQ_CODE = V_SEQ_CODE);
   END IF;
   CLOSE CHECK_EXIST_CANDIDATE;

   COMMIT;

   OPEN CHECK_EXIST_CANDIDATE(V_SEQ_CODE);
   FETCH CHECK_EXIST_CANDIDATE INTO V_OSS_CHAR_DATE;
   CLOSE CHECK_EXIST_CANDIDATE;

   V_TIME := TO_CHAR(SYSDATE + .002,'MM-DD-YYYY HH:MI:SS AM');
   V_SUCCESS_FL := 'T';
   WHILE SYSDATE < TO_DATE(V_TIME,'MM-DD-YYYY HH:MI:SS AM')
   LOOP
      OPEN OSSGATE_CHECK(V_OSS_CHAR_DATE, P_SVO_UID_PK);
      FETCH OSSGATE_CHECK INTO V_SUCCESS_FL;
      IF OSSGATE_CHECK%FOUND THEN
         EXIT;
      END IF;
      CLOSE OSSGATE_CHECK;
   END LOOP;

RETURN V_SUCCESS_FL;

END FN_OSSGATE_REPROVISION;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE PR_EMAIL_HELPDESK(P_MAIL_DIST_LIST_NAME IN VARCHAR, P_MESSAGE IN VARCHAR, P_SUBJ IN VARCHAR DEFAULT NULL)

IS

BEGIN

IF GET_DATABASE_FUN IN ('HES1','HES2','HES3','HES','PROD') THEN
   
   ---HD 99904 RMC 11-04-2010 - Added param for passing in mail distribuition name versus Hard coding name
   
  
   MAILX.SEND_MAIL_MESSAGE(P_MAIL_DIST_LIST_NAME, NVL(P_SUBJ,'MYRIO/HES NOT IN SYNC PLEASE CORRECT'), P_MESSAGE, null,'5');

ELSE
   MAILX.SEND_MAIL_MESSAGE('HES_IWP_TESTING@HTC.HARGRAY.COM', NVL(P_SUBJ,'MYRIO/HES NOT IN SYNC PLEASE CORRECT'), P_MESSAGE, null,'5');
END IF;

END PR_EMAIL_HELPDESK;

FUNCTION FN_BOX_ON_OTHER_ACCT(P_SVC_UID_PK IN NUMBER, P_MAC_ADDRESS IN VARCHAR)
RETURN VARCHAR

IS

CURSOR BOX_CHECK(P_CCB_UID_PK IN NUMBER) IS
    select 'X'
      from catv_services,
           catv_serv_boxes,
           catv_conv_boxes
     where cbs_services_uid_fk != P_SVC_UID_PK
       and cbs_uid_pk = tvb_catv_services_uid_fk
       and ccb_uid_pk = tvb_catv_conv_boxes_uid_fk
       and CCB_UID_PK = P_CCB_UID_PK
       and tvb_end_date is null
UNION
    select 'X'
      from so,
           so_status,
           catv_so,
           catv_serv_box_so,
           catv_conv_boxes
     where SVO_SERVICES_UID_FK != P_SVC_UID_PK
       and SOS_UID_PK = SVO_SO_STATUS_UID_FK
       and SOS_SYSTEM_CODE not in ('VOID','CLOSED')
       and svo_uid_pk = CTS_SO_UID_FK
       and CTS_UID_PK = CBX_CATV_SO_UID_FK
       and CCB_UID_PK = CBX_CATV_CONV_BOXES_UID_FK
       and CCB_UID_PK = P_CCB_UID_PK;

V_DUMMY      VARCHAR2(1);
V_RETURN_FL  VARCHAR2(1);
V_EQUIP_TYPE VARCHAR2(10);
V_CCB_UID_PK NUMBER;

--THIS WILL PERFORM A CHECK TO SEE IF THE MAC ADDRESS FOR THE BOX PASSED IN IS FOUND ON ANOTHER ACCOUNT OTHER THAN
--THE SERVICE PASSED IN, AND IF SO WILL RETURN 'T', IF NOT WILL RETURN 'F'

BEGIN

--THIS SHOULD ALWAYS BE FOUND AS A BOX BECAUSE IT IT PASSED FROM THE IWP AND ONLY CALLED WHEN CHECKING FOR BOXES THAT ARE ALREADY FOUND
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC_ADDRESS, V_CCB_UID_PK);

OPEN BOX_CHECK(V_CCB_UID_PK);
FETCH BOX_CHECK INTO V_DUMMY;
IF BOX_CHECK%FOUND THEN
   V_RETURN_FL := 'T';
ELSE
   V_RETURN_FL := 'F';
END IF;
CLOSE BOX_CHECK;

RETURN V_RETURN_FL;

END FN_BOX_ON_OTHER_ACCT;

FUNCTION FN_TT_PLANT_LIST
RETURN generic_data_table PIPELINED IS

CURSOR CODES IS
SELECT PIT_UID_PK, PIT_CODE||' - '||PIT_DESCRIPTION DESCRIPTION, TO_NUMBER(PIT_CODE)
 FROM PLANT_ITEM_TYPES
 WHERE PIT_ACTIVE_FL = 'Y'
ORDER BY TO_NUMBER(PIT_CODE);

rec     CODES%rowtype;
v_rec   generic_data_type;

BEGIN

 OPEN CODES;
 LOOP
    FETCH CODES into rec;
    EXIT WHEN CODES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1    := rec.description;   -- description
     v_rec.gdt_number1   := rec.pit_uid_pk;    -- pk


     PIPE ROW (v_rec);
  END LOOP;

  CLOSE CODES;

RETURN;

END FN_TT_PLANT_LIST;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_TT_FAULT_LIST
RETURN generic_data_table PIPELINED IS

CURSOR CODES IS
SELECT FAU_UID_PK, FAU_CODE||' - '||FAU_DESCRIPTION DESCRIPTION, TO_NUMBER(FAU_CODE)
 FROM FAULT_TYPES
 WHERE FAU_ACTIVE_FL = 'Y'
ORDER BY TO_NUMBER(FAU_CODE);

rec     CODES%rowtype;
v_rec   generic_data_type;

BEGIN

 OPEN CODES;
 LOOP
    FETCH CODES into rec;
    EXIT WHEN CODES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1    := rec.description;   -- description
     v_rec.gdt_number1   := rec.fau_uid_pk;    -- pk


     PIPE ROW (v_rec);
  END LOOP;

  CLOSE CODES;

RETURN;

END FN_TT_FAULT_LIST;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_TT_CAUSE_LIST
RETURN generic_data_table PIPELINED IS

CURSOR CODES IS
SELECT CAU_UID_PK, CAU_CODE||' - '||CAU_DESCRIPTION DESCRIPTION, TO_NUMBER(CAU_CODE)
 FROM CAUSE_TYPES
 WHERE CAU_ACTIVE_FL = 'Y'
 ORDER BY TO_NUMBER(CAU_CODE);

rec     CODES%rowtype;
v_rec   generic_data_type;

BEGIN

 OPEN CODES;
 LOOP
    FETCH CODES into rec;
    EXIT WHEN CODES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1    := rec.description;   -- description
     v_rec.gdt_number1   := rec.cau_uid_pk;    -- pk


     PIPE ROW (v_rec);
  END LOOP;

  CLOSE CODES;

RETURN;

END FN_TT_CAUSE_LIST;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_TT_ACTION_LIST
RETURN generic_data_table PIPELINED IS

CURSOR CODES IS
SELECT ATP_UID_PK, ATP_CODE||' - '||ATP_DESCRIPTION DESCRIPTION, TO_NUMBER(ATP_CODE)
 FROM ACTION_TYPES
 WHERE ATP_ACTIVE_FL = 'Y'
 ORDER BY TO_NUMBER(ATP_CODE);

rec     CODES%rowtype;
v_rec   generic_data_type;

BEGIN

 OPEN CODES;
 LOOP
    FETCH CODES into rec;
    EXIT WHEN CODES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1    := rec.description;   -- description
     v_rec.gdt_number1   := rec.atp_uid_pk;    -- pk


     PIPE ROW (v_rec);
  END LOOP;

  CLOSE CODES;

RETURN;

END FN_TT_ACTION_LIST;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_TT_RESOLUTION_LIST(P_FIND_VALUE IN VARCHAR DEFAULT NULL)
RETURN generic_data_table PIPELINED IS

CURSOR CODES(P_FIND IN VARCHAR) IS
SELECT REF_UID_PK, REF_CODE||' - '||REF_DESCRIPTION DESCRIPTION, TO_NUMBER(REF_CODE)
 FROM REFERRAL_TYPES
 WHERE REF_ACTIVE_FL = 'Y'
   AND REF_DESCRIPTION LIKE P_FIND
   AND P_FIND IS NOT NULL
UNION
SELECT REF_UID_PK, REF_CODE||' - '||REF_DESCRIPTION DESCRIPTION, TO_NUMBER(REF_CODE)
 FROM REFERRAL_TYPES
 WHERE REF_ACTIVE_FL = 'Y'
   AND P_FIND IS NULL
 ORDER BY 3;

rec     CODES%rowtype;
v_rec   generic_data_type;
V_FIND_VALUE  VARCHAR2(100);

BEGIN

 IF P_FIND_VALUE is not null then
    V_FIND_VALUE := '%'||P_FIND_VALUE||'%';
 END IF;

 OPEN CODES(V_FIND_VALUE);
 LOOP
    FETCH CODES into rec;
    EXIT WHEN CODES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1    := rec.description;   -- description
     v_rec.gdt_number1   := rec.ref_uid_pk;    -- pk


     PIPE ROW (v_rec);
  END LOOP;

  CLOSE CODES;

RETURN;

END FN_TT_RESOLUTION_LIST;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_CLOSE_TROUBLE_TICKET(P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_COMMENT IN VARCHAR, P_PIT_UID_PK IN NUMBER,
                                 P_FAU_UID_PK IN NUMBER, P_CAU_UID_PK IN NUMBER, P_ATP_UID_PK IN NUMBER, P_REF_UID_PK IN NUMBER,
                                 P_TDG_UID_PK IN NUMBER)
RETURN VARCHAR

IS

CURSOR sty_and_svt_by_trt(cp_sty_system_code VARCHAR2,
                                                  cp_svt_system_code VARCHAR2, --ADSL or VDSL
                                                  p_trt_uid_pk in number) IS
SELECT get_identifier_fun(svc_uid_pk, svc_office_serv_types_uid_fk)
  FROM service_types,
             office_serv_types,
             off_serv_subs,
             serv_sub_types,
             services,
             trouble_tickets
WHERE svc_office_serv_types_uid_fk   = ost_uid_pk
  AND ost_service_types_uid_fk       = sty_uid_pk
    AND OSB_OFFICE_SERV_TYPES_UID_FK   = ost_uid_pk
    AND svc_off_serv_subs_uid_fk       = osb_uid_pk
    AND OSB_SERV_SUB_TYPES_UID_FK      = svt_uid_pk
    AND trt_services_uid_fk            = svc_uid_pk
    AND trt_uid_pk                     = p_trt_uid_pk
    AND sty_system_code                = NVL(cp_sty_system_code,sty_system_code)
    AND svt_system_code                = NVL(cp_svt_system_code,svt_system_code)
UNION
 SELECT get_identifier_fun(svc_uid_pk, svc_office_serv_types_uid_fk)
   FROM service_assgnmts,
        services,
        trouble_tickets,
        mta_services,
        mta_ports,
        mta_equip_units,
        mta_boxes
  WHERE sva_uid_pk = mss_service_assgnmts_uid_fk
    and svc_uid_pk = sva_services_uid_fk
    and svc_uid_pk = trt_services_uid_fk
    and trt_uid_pk = p_trt_uid_pk
    and mtp_uid_pk = mss_mta_ports_uid_fk
    and meu_uid_pk = mtp_mta_equip_units_uid_fk
    and mta_uid_pk = meu_mta_boxes_uid_fk
    and meu_remove_mta_fl = 'N'
    AND cp_svt_system_code = 'CABLE MODEM';

CURSOR get_note_line(p_trt_uid_pk in number) IS
SELECT decode(max(trn_line_number) + 1,null,1,max(trn_line_number) + 1)
  FROM trouble_notes,
       trouble_tickets
 WHERE trn_trouble_tickets_uid_fk = trt_uid_pk
   AND trt_uid_pk                 = p_trt_uid_pk;

CURSOR get_cbm(cp_svc_uid_pk NUMBER) IS
SELECT cbm_mac_address
  FROM service_assgnmts,
       cable_modems
 WHERE sva_cable_modems_uid_fk = cbm_uid_pk
   AND sva_services_uid_fk     = cp_svc_uid_pk
  UNION
 SELECT MTA_CMAC_ADDRESS
   FROM service_assgnmts,
        mta_services,
        mta_ports,
        mta_equip_units,
        mta_boxes
  WHERE sva_services_uid_fk  = cp_svc_uid_pk
    and sva_uid_pk = mss_service_assgnmts_uid_fk
    and mtp_uid_pk = mss_mta_ports_uid_fk
    and meu_uid_pk = mtp_mta_equip_units_uid_fk
    and mta_uid_pk = meu_mta_boxes_uid_fk
    and meu_remove_mta_fl = 'N';

CURSOR TROUBLE_INFO IS
  SELECT TRT_UID_PK, SUBSTR(CRP_CODE, LENGTH(CRP_CODE),1), TRT_SERVICES_UID_FK, 
         TRT_INSIDE_WIR_TYPES_UID_FK
    FROM TROUBLE_DISPATCHES, TROUBLE_TICKETS, CST_REPORT_TYPES
   WHERE TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
     AND CRP_UID_PK = TRT_CST_REPORT_TYPES_UID_FK
     AND TDP_UID_PK = P_TDP_UID_PK;

CURSOR GET_REPORT_CODE (P_CRP_CODE IN VARCHAR) IS
  SELECT CRP_UID_PK
    FROM CST_REPORT_TYPES
   WHERE CRP_CODE = P_CRP_CODE;

CURSOR GET_REF_CODE IS
  SELECT REF_CODE
    FROM REFERRAL_TYPES
   WHERE REF_UID_PK = P_REF_UID_PK;

CURSOR GET_GROUP_ID (p_group_code varchar2) IS  -- was get_f_group
  SELECT TDG_UID_PK
    FROM TRBL_DSP_GRPS
   WHERE TDG_CODE = p_group_code;

CURSOR GET_GROUP_CODE IS
  SELECT TDG_CODE
    FROM TRBL_DSP_GRPS
   WHERE TDG_UID_PK = P_TDG_UID_PK;

CURSOR additional_loading(p_trt_uid_pk in NUMBER) IS
SELECT 'X'
  FROM trouble_dispatches,
       trouble_tickets
 WHERE trt_uid_pk   = tdp_trouble_tickets_uid_fk
   AND trt_uid_pk   = p_trt_uid_pk
     AND tdp_uid_pk  != p_tdp_uid_pk
     AND tdp_end_work_date IS NULL;


--  HD# 101600 add Closed email when TT is closed via web

CURSOR GET_HIGH_PROFILE_INFO (cp_svc_uid_pk number) is
	select Cus_uid_pk, sty_code, usr_e_mail, cus_fname, cus_lname, ost_uid_pk  
		from users, high_profile_pocs,  customers, accounts, services,
			OFFICE_SERV_TYPES, SERVICE_TYPES
		where svc_uid_pk = cp_svc_uid_pk
		and svc_accounts_uid_fk = acc_uid_pk
		and cus_uid_pk = acc_customers_uid_fk 
		and hpp_customers_uid_fk = cus_uid_pk
		and svc_office_serv_types_uid_fk = ost_uid_pk
		and STY_UID_PK = OST_SERVICE_TYPES_UID_FK
		and hpp_users_uid_fk = usr_uid_pk
		and hpp_active_fl = 'Y';

CURSOR get_mmr_fl(cp_svc_uid_pk number) IS
 SELECT cbs_mmr_fl
   FROM catv_services
 WHERE cbs_services_uid_fk=cp_svc_uid_pk;
	
	v_cus_uid_pk          number;
    v_mmr_fl              varchar2(1);
	v_service_type        varchar2(12);
  v_usr_e_mail          varchar2(40);
  v_subject_txt 			  VARCHAR2(200);
  v_message_txt         VARCHAR2(500);
	v_email_recipients    VARCHAR2(80);
	v_name                varchar2(81);
	v_identifier          varchar2(40);

V_TRT_UID_PK          NUMBER;
V_TDG_UID_PK          NUMBER;
V_CRP_UID_PK          NUMBER;
V_CRP_LAST_DIGIT      VARCHAR2(1);
V_CRP_CODE            VARCHAR2(20);
V_REF_CODE            VARCHAR2(20);
V_DUMMY               VARCHAR2(1);
V_CLEARING_FL         VARCHAR2(1);
V_GRP_CODE            VARCHAR2(20);
V_REASSIGN_TECH_FL    VARCHAR2(1) := 'N';
V_PASSED              VARCHAR2(20) := '';

--IPTV VARIABLES
v_assignments               BOOLEAN;
v_myrio                             BOOLEAN;
v_stb_count                     BOOLEAN;
v_dslam_ports                 BOOLEAN;
v_stbs_assgnd                 BOOLEAN;
v_myrio_pkg                     BOOLEAN;
v_myrio_stbs                     BOOLEAN;
v_status                             VARCHAR2(100);
v_iptv_msg                         VARCHAR2(4000);
v_trn_line_number     NUMBER;
v_iptv_id             VARCHAR2(12);


--CABLE MODEM VARIABLES
v_mac_address          VARCHAR2(12);
modem_is_online                 BOOLEAN;
downstream_power_delta NUMBER;
upstream_power_delta   NUMBER;
downstream_snr_delta   NUMBER;
status_overall         VARCHAR2(100);
messages               VARCHAR2(4000);
v_online               VARCHAR2(1);
v_cbm_svc              VARCHAR2(300);
v_levels               VARCHAR2(4000);
v_svc_uid_pk           NUMBER;
v_iwt_uid_pk           number;

BEGIN

OPEN TROUBLE_INFO;
FETCH TROUBLE_INFO INTO V_TRT_UID_PK, V_CRP_LAST_DIGIT, V_SVC_UID_PK, v_iwt_uid_pk;
CLOSE TROUBLE_INFO;

OPEN get_note_line(v_trt_uid_pk);
FETCH get_note_line INTO v_trn_line_number;
CLOSE get_note_line;

OPEN GET_REF_CODE;
FETCH GET_REF_CODE INTO V_REF_CODE;
CLOSE GET_REF_CODE;

IF P_TDG_UID_PK IS NOT NULL THEN
   OPEN GET_GROUP_CODE;
   FETCH GET_GROUP_CODE INTO V_GRP_CODE;
   CLOSE GET_GROUP_CODE;
END IF;

--always store p_comment as a trouble_notes record
INSERT INTO trouble_notes(trn_uid_pk,
                          trn_employees_uid_fk ,
                          trn_trouble_tickets_uid_fk,
                          trn_line_number,
                          trn_service_date,
                          trn_service_time,
                          trn_notes)
                   VALUES(trn_seq.nextval,
                          p_emp_uid_pk,
                          v_trt_uid_pk,
                          v_trn_line_number,
                          trunc(sysdate),
                          sysdate,
                          P_COMMENT);
                          
OPEN get_note_line(v_trt_uid_pk);
FETCH get_note_line INTO v_trn_line_number;
CLOSE get_note_line;

IF V_REF_CODE != '94' THEN --NOT NO ACCESS

   --IF THIS TICKET IS ON AN CTV/ADSL SERVICE, VERIFY THE IPTV STATUS BEFORE ALLOWING TO CLEAR
   OPEN sty_and_svt_by_trt('CTV','ADSL',v_trt_uid_pk);
   FETCH sty_and_svt_by_trt INTO v_iptv_id;
   IF sty_and_svt_by_trt%FOUND THEN
        OPEN get_mmr_fl(v_svc_uid_pk);
        FETCH get_mmr_fl INTO v_mmr_fl;
        CLOSE get_mmr_fl;
        IF v_mmr_fl = 'N' THEN
            iptv_diagnostics.iptv_diagnose_service(v_iptv_id,
                                                                                           v_assignments,
                                                                                           v_myrio,
                                                                                           v_stb_count,
                                                                                           v_dslam_ports,
                                                                                           v_stbs_assgnd,
                                                                                           v_myrio_pkg,
                                                                                           v_myrio_stbs,
                                                                                           v_status,
                                                                                           v_iptv_msg);

            --INVALID IPTV
            IF v_status NOT IN('GOOD','ACCEPTABLE') THEN

             INSERT INTO trouble_notes(trn_uid_pk,
                                                                       trn_employees_uid_fk ,
                                                                       trn_trouble_tickets_uid_fk,
                                                                       trn_line_number,
                                                                       trn_service_date,
                                                                       trn_service_time,
                                                                       trn_notes)
                                                        VALUES(trn_seq.nextval,
                                                               p_emp_uid_pk,
                                                               v_trt_uid_pk,
                                                               v_trn_line_number,
                                                               trunc(sysdate),
                                                               sysdate,
                                                               v_iptv_msg);
                 COMMIT;
                 RETURN V_IPTV_MSG;
          ELSE
             V_PASSED := 'Diagnostics passed. ';
          END IF;
       END IF;
   END IF;
   CLOSE sty_and_svt_by_trt;

   --IF THIS TICKET IS ON A CABLE MODEM/MTA SERVICE, VERIFY STATUS OF THE MODEM BEFORE ALLOWING TO ACCESS
   OPEN sty_and_svt_by_trt(null,'CABLE MODEM',v_trt_uid_pk);
   FETCH sty_and_svt_by_trt INTO v_cbm_svc;
   --CABLE MODEM SERVICE
   IF sty_and_svt_by_TRT%FOUND THEN
        OPEN get_cbm(v_svc_uid_pk);
        FETCH get_cbm INTO v_mac_address;
        CLOSE get_cbm;
        
        IF SYSTEM_RULES_PKG.GET_CHAR_VALUE('SERV DIAG','OPTIONS','CM MAC') = 'N' THEN
           if v_mac_address is not null then
           
               service_diagnostics.troubleshoot_cm_mac(v_mac_address,
                                                                                           modem_is_online,
                                                                                           downstream_power_delta,
                                                                                           upstream_power_delta,
                                                                                           downstream_snr_delta,
                                                                                          status_overall,
                                                                                          messages);
           else
              close sty_and_svt_by_trt;
              RETURN 'No MAC Address is active on this service.';
           end if;

           --INVALID CABLE MODEM
           IF status_overall = 'FAILURE' THEN

               IF not modem_is_online THEN
                 v_levels := v_levels||'Modem is off line. ';
               ELSIF modem_is_online THEN
                 v_levels := v_levels||'Modem is on line. ';
               END IF;

               IF downstream_power_delta > 0 THEN
                    v_levels := v_levels||'Downstream power level is too high by '||downstream_power_delta||' dBmV.';
               ELSIF downstream_power_delta < 0 THEN
                    v_levels := v_levels||'Downstream power level is too low by '||ABS(downstream_power_delta)||' dBmV.';
               ELSE
                    v_levels := v_levels||'Downstream power level is OK.';
               END IF;

               IF upstream_power_delta > 0 THEN
                    v_levels := v_levels||' Upstream power level is too high by '||upstream_power_delta||' dBmV.';
               ELSIF upstream_power_delta < 0 THEN
                    v_levels := v_levels||' Upstream power level is too low by '||ABS(upstream_power_delta)||' dBmV.';
               ELSE
                    v_levels := v_levels||' Upstream power level is OK.';
               END IF;

               IF downstream_snr_delta < 0 THEN
                    v_levels := v_levels||' Downstream SNR is too low by '||ABS(downstream_snr_delta)||' dB.';
               ELSE
                    v_levels := v_levels||' Downstream SNR is OK.';
               END IF;

               IF v_levels is null THEN
                       v_levels := v_levels||' Downstream and Upstream levels are ok. Downstream SNR is ok. Please check other areas.';
               END IF;

               INSERT INTO trouble_notes(trn_uid_pk,
                                                                   trn_employees_uid_fk ,
                                                                   trn_trouble_tickets_uid_fk,
                                                                   trn_line_number,
                                                                   trn_service_date,
                                                                   trn_service_time,
                                                                   trn_notes)
                                                       VALUES(trn_seq.nextval,
                                                                   p_emp_uid_pk,
                                                                   v_trt_uid_pk,
                                                                   v_trn_line_number,
                                                                   trunc(sysdate),
                                                                   sysdate,
                                                                   'When closing a ticket from IWP got these levels, '||v_levels);
                COMMIT;
                close sty_and_svt_by_TRT;
                RETURN V_LEVELS;
          ELSE
             V_PASSED := 'Diagnostics passed. ';
          END IF;
             --INVALID CABLE MODEM
       ELSE
       
           if v_mac_address is not null then
              service_diagnostics.get_cm_mac(v_mac_address,
                                             modem_is_online,
                                             status_overall,
                                             messages);
           else
              close sty_and_svt_by_trt;
              RETURN 'No MAC Address is active on this service.';
           end if;
           
           --INVALID CABLE MODEM
           IF status_overall = 'FAILURE' THEN

               IF not modem_is_online THEN
                 v_levels := v_levels||'Modem is off line. ';
               ELSIF modem_is_online THEN
                 v_levels := v_levels||'Modem is on line. ';
               END IF;

               v_levels := messages;

               INSERT INTO trouble_notes(trn_uid_pk,
                                                                   trn_employees_uid_fk ,
                                                                   trn_trouble_tickets_uid_fk,
                                                                   trn_line_number,
                                                                   trn_service_date,
                                                                   trn_service_time,
                                                                   trn_notes)
                                                       VALUES(trn_seq.nextval,
                                                                   p_emp_uid_pk,
                                                                   v_trt_uid_pk,
                                                                   v_trn_line_number,
                                                                   trunc(sysdate),
                                                                   sysdate,
                                                                   'When closing a ticket from IWP got these levels, '||v_levels);
                COMMIT;
                close sty_and_svt_by_TRT;
                RETURN V_LEVELS;
          ELSE
             V_PASSED := 'Diagnostics passed. ';
          END IF;
       END IF;
   END IF;
   CLOSE sty_and_svt_by_trt;
END IF;

IF V_REF_CODE = '94' THEN --NO ACCESS

   --GET LAST DIGIT TO KNOW WHAT REPORT CODE TO GET '0' = 60, '1' = 61, '2' = 62
   IF V_CRP_LAST_DIGIT = '1' THEN
      V_CRP_CODE := '61';
   ELSIF V_CRP_LAST_DIGIT = '2' THEN
      V_CRP_CODE := '62';
   ELSE
      V_CRP_CODE := '60';
   END IF;

   OPEN GET_REPORT_CODE(V_CRP_CODE);
   FETCH GET_REPORT_CODE INTO V_CRP_UID_PK;
   CLOSE GET_REPORT_CODE;

  --GET 'F' GROUP
  OPEN GET_GROUP_ID('F');
  FETCH GET_GROUP_ID INTO V_TDG_UID_PK;
  CLOSE GET_GROUP_ID;

  --INSERT NEW DISPATCH TO 'F' GROUP
  INSERT INTO TROUBLE_DISPATCHES(TDP_UID_PK, TDP_TROUBLE_TICKETS_UID_FK, TDP_EMP_DISPATCHED_UID_FK, TDP_DATE, TDP_TIME, TDP_TRBL_DSP_GRPS_UID_FK)
                          VALUES(TDP_SEQ.NEXTVAL, V_TRT_UID_PK, P_EMP_UID_PK, TRUNC(SYSDATE), SYSDATE, V_TDG_UID_PK);

  --UPDATE TROUBLE TICKET TO CHANGE REPORT CODE TO 60, 61, OR 62
  UPDATE TROUBLE_TICKETS
     SET TRT_CST_REPORT_TYPES_UID_FK = V_CRP_UID_PK
   WHERE TRT_UID_PK = V_TRT_UID_PK;

   V_CLEARING_FL      := 'N';
   V_REASSIGN_TECH_FL := 'Y';
ELSIF V_REF_CODE = system_rules_pkg.get_char_value('TROUBLE_TKTS','NEED DROP',v_ref_code) THEN 
  --GET 'M' GROUP
  OPEN GET_GROUP_id(system_rules_pkg.get_char_value('TROUBLE_TKTS','NEED DROP' , 'DROP DEPT'));
  FETCH GET_GROUP_ID INTO V_TDG_UID_PK;
  CLOSE GET_GROUP_ID;

  --INSERT NEW DISPATCH TO 'M' GROUP
  INSERT INTO TROUBLE_DISPATCHES(TDP_UID_PK, TDP_TROUBLE_TICKETS_UID_FK, TDP_EMP_DISPATCHED_UID_FK, TDP_DATE, TDP_TIME, TDP_TRBL_DSP_GRPS_UID_FK)
                          VALUES(TDP_SEQ.NEXTVAL, V_TRT_UID_PK, P_EMP_UID_PK, TRUNC(SYSDATE), SYSDATE, V_TDG_UID_PK);
  
  v_trn_line_number := v_trn_line_number + 1;
  
  INSERT INTO trouble_notes(trn_uid_pk,
                            trn_employees_uid_fk ,
                            trn_trouble_tickets_uid_fk,
                            trn_line_number,
                            trn_service_date,
                            trn_service_time,
                            trn_notes)
                     VALUES(trn_seq.nextval,
                            p_emp_uid_pk,
                            v_trt_uid_pk,
                            v_trn_line_number,
                            trunc(sysdate),
                            sysdate,
                            'Redirected to the M group from IWP to place a permanent drop');
                            
  V_CLEARING_FL := 'M';                          

ELSIF V_REF_CODE = '95' THEN  --REFERRED TO ANOTHER DEPARTMENT
   IF P_TDG_UID_PK IS NOT NULL THEN
     --INSERT NEW DISPATCH TO GROUP PASSED IN
     INSERT INTO TROUBLE_DISPATCHES(TDP_UID_PK, TDP_TROUBLE_TICKETS_UID_FK, TDP_EMP_DISPATCHED_UID_FK, TDP_DATE, TDP_TIME, TDP_TRBL_DSP_GRPS_UID_FK)
                          VALUES(TDP_SEQ.NEXTVAL, V_TRT_UID_PK, P_EMP_UID_PK, TRUNC(SYSDATE), SYSDATE, P_TDG_UID_PK);
   ELSE
      RETURN 'This type of trouble clearing requires a referred to group to be entered.';
   END IF;

   V_CLEARING_FL := 'R';
ELSE
   OPEN additional_loading(V_TRT_UID_PK);
   FETCH additional_loading INTO V_DUMMY;
   IF additional_loading%FOUND THEN
      --UPDATE DISPATCH BUT DO NOT UPDATE TROUBLE TICKET TO CLOSED
      V_CLEARING_FL := 'D';
   ELSE
      UPDATE TROUBLE_TICKETS
         SET TRT_STATUS            = 'C',
             trt_close_date        = trunc(sysdate),
                         trt_close_time        = sysdate,
                       trt_emp_closed_uid_fk = P_EMP_UID_PK
       WHERE TRT_UID_PK = V_TRT_UID_PK;

      if v_iwt_uid_pk is not null then
        UPDATE BROADBAND_SERVICES
           SET bbs_inside_wir_types_uid_fk = v_iwt_uid_pk
         WHERE bbs_services_uid_fk         = V_SVC_UID_PK;
      end if;

      V_CLEARING_FL := 'C';
      
			begin	

						for ghp in get_high_profile_info (v_svc_uid_pk) loop

								v_name := ltrim(rtrim(ghp.cus_fname)||' '||rtrim(ghp.cus_lname));
								v_cus_uid_pk := ghp.cus_uid_pk;
								v_service_type := ghp.sty_code;

								v_email_recipients :=  ghp.usr_e_mail;
								v_identifier := get_identifier_fun(v_svc_uid_pk,ghp.ost_uid_pk);   

								v_subject_txt  := 'Trouble Ticket '||v_service_type||' for Customer '||v_cus_uid_pk||' - '||v_name;
								v_message_txt := 'Customer '||v_cus_uid_pk ||' - '||v_name||' '||v_identifier||
								' trouble ticket# '|| v_trt_uid_pk ||' has been closed for service type '||
									v_service_type;

								mailx.ext_send_mail_message
									(v_email_recipients
									,substr(v_subject_txt,1,79)
									,v_message_txt,'HighProfCustNotification@htc.hargray.com');

						end loop;
			end;
      
   END IF;
   CLOSE additional_loading;
END IF;

--UPDATE CURRENT DISPATCH
UPDATE TROUBLE_DISPATCHES
   SET TDP_END_WORK_DATE = TRUNC(SYSDATE),
       TDP_END_WORK_TIME = SYSDATE,
       TDP_COMMENT = P_COMMENT,
       TDP_PLANT_ITEM_TYPES_UID_FK = P_PIT_UID_PK,
       TDP_FAULT_TYPES_UID_FK = P_FAU_UID_PK,
       TDP_CAUSE_TYPES_UID_FK = P_CAU_UID_PK,
       TDP_ACTION_TYPES_UID_FK = P_ATP_UID_PK,
       TDP_REFERRAL_TYPES_UID_FK = P_REF_UID_PK,
       TDP_REASSIGN_TECH_FL = V_REASSIGN_TECH_FL
 WHERE TDP_UID_PK = P_TDP_UID_PK;
 
GPS_PKG.FN_TDP_STAMP_ADDRESS(P_TDP_UID_PK, P_EMP_UID_PK, 'C');

COMMIT;

IF V_CLEARING_FL = 'N' THEN --CLEARED WITH NO ACCESS
     INSERT INTO trouble_notes(trn_uid_pk,trn_employees_uid_fk ,trn_trouble_tickets_uid_fk,trn_line_number,trn_service_date,trn_service_time,trn_notes)
                                            VALUES(trn_seq.nextval,p_emp_uid_pk,v_trt_uid_pk,v_trn_line_number,trunc(sysdate),sysdate,
                                                        'The dispatch record has been cleared by IWP as NO ACCESS and referred to the F group.');
   COMMIT;
   RETURN 'Your dispatch record has been cleared by IWP as NO ACCESS and referred to the F group.';
ELSIF V_CLEARING_FL = 'R' THEN --CLEARED WITH REFERRED TO ANOTHER GROUP
     INSERT INTO trouble_notes(trn_uid_pk,trn_employees_uid_fk ,trn_trouble_tickets_uid_fk,trn_line_number,trn_service_date,trn_service_time,trn_notes)
                                            VALUES(trn_seq.nextval,p_emp_uid_pk,v_trt_uid_pk,v_trn_line_number,trunc(sysdate),sysdate,
                                                        'The dispatch record has been cleared by IWP as REFERRED TO ANOTHER GROUP and referred to the '||V_GRP_CODE||' group.');
   COMMIT;
   RETURN 'Your dispatch record has been cleared by IWP as REFERRED TO ANOTHER GROUP and referred to the '||V_GRP_CODE||' group.';
ELSIF V_CLEARING_FL = 'M' THEN --CLEARED WITH REFERRED TO ANOTHER GROUP
   COMMIT;
   RETURN 'Your dispatch record has been cleared by IWP and sent to the M department for a permanant drop to be placed';
ELSIF V_CLEARING_FL = 'D' THEN --CLEARED WITH DISPATCH CLOSED BUT NOT TICKET
     INSERT INTO trouble_notes(trn_uid_pk,trn_employees_uid_fk ,trn_trouble_tickets_uid_fk,trn_line_number,trn_service_date,trn_service_time,trn_notes)
                                            VALUES(trn_seq.nextval,p_emp_uid_pk,v_trt_uid_pk,v_trn_line_number,trunc(sysdate),sysdate,
                                                        'The dispatch record has been cleared by IWP but another dispatch is loaded to someone else leaving the ticket open.');
   COMMIT;
   RETURN 'Your dispatch record has been cleared by IWP but another dispatch is open not allowing the ticket to close.  Please call plant if this is not correct.';
ELSIF V_CLEARING_FL = 'C' THEN --CLEARED WITH DISPATCH CLOSED AND ALSO CLEAR TICKET
     INSERT INTO trouble_notes(trn_uid_pk,trn_employees_uid_fk ,trn_trouble_tickets_uid_fk,trn_line_number,trn_service_date,trn_service_time,trn_notes)
                                            VALUES(trn_seq.nextval,p_emp_uid_pk,v_trt_uid_pk,v_trn_line_number,trunc(sysdate),sysdate,
                                                        'The dispatch record has been cleared by IWP and the ticket has been closed.');
   COMMIT;
   RETURN 'Your dispatch record has been cleared by IWP and the ticket has been closed.';
END IF;

END FN_CLOSE_TROUBLE_TICKET;

FUNCTION FN_TT_GROUPS
RETURN generic_data_table PIPELINED IS

CURSOR CODES IS
SELECT TDG_UID_PK, TDG_CODE||' - '||TDG_DESCRIPTION DESCRIPTION
 FROM TRBL_DSP_GRPS
 WHERE TDG_ACTIVE_FL = 'Y'
 ORDER BY DESCRIPTION;

rec     CODES%rowtype;
v_rec   generic_data_type;

BEGIN

 OPEN CODES;
 LOOP
    FETCH CODES into rec;
    EXIT WHEN CODES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1    := rec.description;   -- description
     v_rec.gdt_number1   := rec.tdg_uid_pk;    -- pk


     PIPE ROW (v_rec);
  END LOOP;

  CLOSE CODES;

RETURN;

END FN_TT_GROUPS;

/*-------------------------------------------------------------------------------------------------------------*/
-- to add and provision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
FUNCTION FN_MAC_ADDRESS_CHANGE(P_OLD_CM_MAC IN VARCHAR, P_NEW_CM_MAC IN VARCHAR, P_NEW_MTA_MAC IN VARCHAR,
                               P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MEU_UID_PK IN NUMBER,
                               P_REMOVE_OLD_FL IN VARCHAR, P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S')
  RETURN VARCHAR

  IS

  CURSOR GET_TECH_LOCATION IS
   SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
     FROM TECH_EMP_LOCATIONS, EMPLOYEES
    WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
      AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
      AND TEO_END_DATE IS NULL;

  CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
    SELECT IVL_UID_PK
      FROM INVENTORY_LOCATIONS
     WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

  CURSOR GET_IDENTIFIER IS
    SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_OFFICE_SERV_TYPES_UID_FK, SVC_UID_PK, STY_SYSTEM_CODE, OST_BUSINESS_OFFICES_UID_FK, STY_UID_PK
    FROM SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SO
    WHERE SVO_UID_PK = P_SVO_UID_PK
      AND SVC_UID_PK = SVO_SERVICES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK;

  CURSOR SERV_SUB_TYPE IS
    SELECT OSB_OFFICE_SERV_TYPES_UID_FK, SVT_SYSTEM_CODE
    FROM OFF_SERV_SUBS, SO, SERV_SUB_TYPES
    WHERE OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
      AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
      AND SVO_UID_PK = P_SVO_UID_PK;

  CURSOR CABLE_MODEM_SUB(P_OST_UID_PK IN NUMBER) IS
    SELECT OSB_UID_PK
    FROM OFF_SERV_SUBS, SERV_SUB_TYPES
    WHERE SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
      AND SVT_SYSTEM_CODE = 'CABLE MODEM'
      AND OSB_OFFICE_SERV_TYPES_UID_FK = P_OST_UID_PK;

  CURSOR CHECK_CABLE_MODEM_SO(P_SERIAL# IN VARCHAR) IS
  select 'X'
  from so_assgnmts, cable_modems
  where cbm_uid_pk = son_cable_modems_uid_fk
    and son_so_uid_fk = P_SVO_UID_PK
    and cbm_mac_address = P_SERIAL#;


   cursor check_if_mta_so(p_svo_uid_pk_in in number) IS
     SELECT MTO_UID_PK
       FROM MTA_SO, SO_ASSGNMTS
      WHERE SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
        AND SON_SO_UID_FK = p_svo_uid_pk_in;


   cursor get_slo is
          select ssl_service_locations_uid_fk, mun_business_offices_uid_fk
            from municipalities, service_locations, serv_serv_locations, so, services
           where ssl_services_uid_fk = svc_uid_pk
             and slo_uid_pk = ssl_service_locations_uid_fk
             and svc_uid_pk = svo_services_uid_fk
             and mun_uid_pk = slo_municipalities_uid_fk
             and ssl_primary_loc_fl = 'Y'
             and ssl_end_date is null
             and svo_uid_pk = p_svo_uid_pk;

   cursor check_if_mta_service(p_svc_uid_pk in number) IS
     SELECT 'X'
       FROM MTA_SERVICES, SERVICE_ASSGNMTS
      WHERE SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
        AND SVA_SERVICES_UID_FK = P_SVC_UID_PK;

  CURSOR GET_PLNT_INFO(P_STY_UID_PK IN NUMBER, P_BSO_UID_PK IN NUMBER, P_FTP_CODE IN VARCHAR) IS
  SELECT OSF_UID_PK
    FROM OFFICE_SERV_FEATS, OFFICE_SERV_TYPES, FEATURES
   WHERE OST_UID_PK = OSF_OFFICE_SERV_TYPES_UID_FK
     AND FTP_UID_PK = OSF_FEATURES_UID_FK
     AND FTP_CODE = P_FTP_CODE
     AND OST_BUSINESS_OFFICES_UID_FK = P_BSO_UID_PK
     AND OST_SERVICE_TYPES_UID_FK = P_STY_UID_PK;

   cursor get_svcs_with_box_loc (p_mta_uid_pk in number, p_slo_uid_pk in number) is
   SELECT DISTINCT SVC_UID_PK, STY_SYSTEM_CODE, STY_UID_PK
     FROM SERVICES, SO_STATUS, SO_TYPES, SO, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOCATIONS, MTA_EQUIP_UNITS, MTA_PORTS, MTA_SERVICES, SERVICE_ASSGNMTS
    WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
      AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
      AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND SVC_UID_PK = SVO_SERVICES_UID_FK
      AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
      AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
      AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED')
      AND SOT_SYSTEM_CODE = 'MS'
      AND MEU_MTA_BOXES_UID_FK = p_mta_uid_pk
      AND STY_SYSTEM_CODE = 'PHN'
      AND SVC_UID_PK = SVA_SERVICES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND SVC_UID_PK = SSL_SERVICES_UID_FK
      AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
      AND SSL_END_DATE IS NULL
      AND SSL_PRIMARY_LOC_FL = 'Y';

  CURSOR CHECK_EXIST_PEND_CS(P_SVC_UID_PK IN NUMBER) IS
    SELECT SVO_UID_PK
      FROM SO, SO_STATUS, SO_TYPES
     WHERE SOS_UID_PK = SVO_SO_STATUS_UID_FK
       AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED')
       AND SVO_SERVICES_UID_FK = P_SVC_UID_PK
       AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
       AND SOT_SYSTEM_CODE IN ('CS','MS');
       
   cursor get_svcs_with_box_loc_mta (p_mta_uid_pk in number, p_slo_uid_pk in number) is
   SELECT DISTINCT SVC_UID_PK, GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK) IDENTIFIER, STY_SYSTEM_CODE, STY_UID_PK
     FROM SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERV_SERV_LOCATIONS, MTA_EQUIP_UNITS, MTA_PORTS, MTA_SERVICES, SERVICE_ASSGNMTS
    WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
      AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
      AND MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
      AND MEU_MTA_BOXES_UID_FK = p_mta_uid_pk
      AND SVC_UID_PK = SVA_SERVICES_UID_FK
      AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
      AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
      AND SVC_UID_PK = SSL_SERVICES_UID_FK
      AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
      AND SSL_END_DATE IS NULL
      AND SSL_PRIMARY_LOC_FL = 'Y';
      
  CURSOR GET_MTA_TYPE(P_MTA_UID_PK IN NUMBER) IS
    SELECT MTY_SYSTEM_CODE, MTY_UID_PK ---,MTA_MTA_TYPES_UID_FK - HD 104876 RMC 03/31/2011
      FROM MTA_BOXES, MTA_TYPES
     WHERE MTY_UID_PK = MTA_MTA_TYPES_UID_FK
    AND MTA_UID_PK = P_MTA_UID_PK;
    
  CURSOR GET_MEU_TYPE IS
	  SELECT MTY_SYSTEM_CODE, MTY_UID_PK ---,MEU_MTA_TYPES_UID_FK - HD 99905 RMC 03/09/2011
	    FROM MTA_EQUIP_UNITS, MTA_TYPES
	   WHERE MTY_UID_PK = MEU_MTA_TYPES_UID_FK
     AND MEU_UID_PK = P_MEU_UID_PK;

  CURSOR GET_MTO_UID_PK(P_SVO_UID_PK IN NUMBER) IS
    SELECT MTO_UID_PK
      FROM MTA_SO, SO_ASSGNMTS
     WHERE SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
       AND SON_SO_UID_FK = P_SVO_UID_PK;
      
  V_IVL_UID_PK           NUMBER;
  V_SLO_UID_PK           NUMBER;
  V_SVO_UID_PK           NUMBER;
  V_BSO_UID_PK           NUMBER;
  V_STY_UID_PK           NUMBER;
  V_OSF_UID_PK           NUMBER;
  V_MTA_UID_PK           NUMBER;
  V_MTO_UID_PK           NUMBER;
  V_DSP_UID_PK           NUMBER;
  V_BBO_MEO_UID_PK       NUMBER;
  V_LAST_IVL_UID_PK      NUMBER;
  V_OSB_UID_PK           NUMBER;
  V_OST_UID_PK           NUMBER;
  V_SVT_CODE             VARCHAR2(40);
  V_LAST_IVL_DESCRIPTION VARCHAR2(200);
  V_RETURN_MESSAGE       VARCHAR2(2000);
  V_EQUIP_TYPE           VARCHAR2(1);
  V_CCB_UID_PK           NUMBER;
  V_CBM_UID_PK           NUMBER;
  V_SVC_UID_PK           NUMBER;
  V_STATUS               VARCHAR2(200);
  V_DUMMY                VARCHAR2(1);
  V_CABLE_MODEM_TYPE     VARCHAR2(1);
  V_TIME                 VARCHAR2(200);
  V_SOR_COMMENT          VARCHAR2(2000);
  V_IDENTIFIER           VARCHAR2(200);
  V_DESCRIPTION          VARCHAR2(200);
  V_EMP_NAME             VARCHAR2(200);
  V_ACCOUNT              VARCHAR2(200);
  V_DATE                 DATE;
  V_SERIAL#              VARCHAR2(40);
  V_STY_SYSTEM_CODE      VARCHAR2(40);
  V_SUCCESS              VARCHAR2(2000);
  V_SUCCESS_FL           VARCHAR2(2000);
  V_FQDN                 VARCHAR2(200);
  V_OLD_MAC              VARCHAR2(40);
  V_OLD_CM_MAC           VARCHAR2(40);
  V_NEW_CM_MAC           VARCHAR2(40);
  V_NEW_MTA_MAC          VARCHAR2(40);
  V_ACTION_FL            VARCHAR2(1) := NULL;
  V_RSU_#                VARCHAR2(40);
  V_EQUIP_TYPE_OLD       VARCHAR2(10);
  V_MTA_OLD_UID_PK       NUMBER;
  v_is_production_database  VARCHAR2(1);
  v_msg_suffix                VARCHAR2(100);
  V_MTA_TYPE_ASSGNMTS_UID_PK 	NUMBER;
  V_MTA_TYPE_SCANNED_UID_PK		NUMBER;
  V_MTA_TYPE_ASSGNMTS         VARCHAR2(40);
  V_MTA_TYPE_SCANNED          VARCHAR2(40);
  V_NEW_CS_CREATED_FL         VARCHAR2(1);
  
  V_MLH_MESSAGE      					VARCHAR2(500);
	V_MLH_FOUND_FL							VARCHAR2(1) := 'N';
	
	v_return_msg  		VARCHAR2(4000);
	
	V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_MAC_ADDRESS_CHANGE';


BEGIN

  V_SERIAL# := NVL(UPPER(P_NEW_MTA_MAC),UPPER(P_NEW_CM_MAC)); --- HD 106740 - Added UPPER for field P_NEW_MTA_MAC and P_NEW_CM_MAC

  --GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
  OPEN GET_TECH_LOCATION;
  FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
  CLOSE GET_TECH_LOCATION;

  OPEN GET_IDENTIFIER;
  FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_OST_UID_PK, V_SVC_UID_PK, V_STY_SYSTEM_CODE, V_BSO_UID_PK, V_STY_UID_PK;
  CLOSE GET_IDENTIFIER;

  OPEN SERV_SUB_TYPE;
  FETCH SERV_SUB_TYPE INTO V_OST_UID_PK, V_SVT_CODE;
  CLOSE SERV_SUB_TYPE;

  open get_slo;
  fetch get_slo into v_slo_uid_pk, V_BSO_UID_PK;
  close get_slo;

  --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
  V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(V_SERIAL#, V_CCB_UID_PK);

  --NOT FOUND
  IF V_EQUIP_TYPE  = 'N' THEN
     RETURN '3 SERIAL# '||V_SERIAL#|| ' NOT FOUND.  PLEASE MAKE SURE YOU ENTERED IT CORRECTLY.';
     v_return_msg := '3 SERIAL# '||V_SERIAL#|| ' NOT FOUND.  PLEASE MAKE SURE YOU ENTERED IT CORRECTLY.';
		 IF p_svo_uid_pk IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
  ELSIF V_EQUIP_TYPE  = 'S' THEN
     RETURN 'YOU CANNOT SCAN A CABLE BOX '||V_SERIAL#|| ' ON THIS ORDER.';
     v_return_msg := 'YOU CANNOT SCAN A CABLE BOX '||V_SERIAL#|| ' ON THIS ORDER.';
		 IF p_svo_uid_pk IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
  ELSIF V_EQUIP_TYPE  = 'E' THEN
     V_MTA_UID_PK := V_CCB_UID_PK;
  ELSIF V_EQUIP_TYPE  = 'M' THEN
     V_CBM_UID_PK := V_CCB_UID_PK;
  ELSIF V_EQUIP_TYPE  = 'A' THEN
     RETURN 'YOU CANNOT SCAN AN ADSL MODEM '||V_SERIAL#|| ' ON THIS ORDER.';
     v_return_msg := 'YOU CANNOT SCAN AN ADSL MODEM '||V_SERIAL#|| ' ON THIS ORDER.';
		 IF p_svo_uid_pk IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
  ELSIF V_EQUIP_TYPE  = 'V' THEN
     RETURN 'YOU CANNOT SCAN A VDSL MODEM '||V_SERIAL#|| ' ON THIS ORDER.';
     v_return_msg := 'YOU CANNOT SCAN A VDSL MODEM '||V_SERIAL#|| ' ON THIS ORDER.';
		 IF p_svo_uid_pk IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
  END IF;

  IF V_EQUIP_TYPE  = 'M' THEN
     BOX_MODEM_PKG.PR_MTA_MACS(P_OLD_CM_MAC, V_OLD_MAC, V_OLD_CM_MAC);
     IF V_OLD_MAC IS NULL THEN
        V_OLD_MAC := P_OLD_CM_MAC;
     END IF;
     V_EQUIP_TYPE_OLD := BOX_MODEM_PKG.FN_DETERMINE_TYPE(V_OLD_MAC, V_MTA_OLD_UID_PK);
  ELSE
     V_EQUIP_TYPE_OLD := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_OLD_CM_MAC, V_MTA_OLD_UID_PK);  
  END IF;
  
  --NJJ ADDED TO NOT ALLOW A CHANGE FROM CABLE MODEM TO MTA IN THIS FUNCTION
  IF V_EQUIP_TYPE_OLD = 'M' AND V_EQUIP_TYPE = 'E' THEN
     RETURN 'YOU CANNOT CHANGE A CABLE MODEM TO A MTA MODEM '||V_SERIAL#|| ' USING THIS CHANGE OPTION.  PLEASE ADD THE MTA MODEM IS THE MTA SECTION';
 		 v_return_msg := 'YOU CANNOT CHANGE A CABLE MODEM TO A MTA MODEM '||V_SERIAL#|| ' USING THIS CHANGE OPTION.  PLEASE ADD THE MTA MODEM IS THE MTA SECTION';
		 IF p_svo_uid_pk IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF; 
  END IF;
  
  --NJJ ADDED TO NOT ALLOW A CHANGE FROM MTA TO MTA IN THIS FUNCTION
  --IF V_EQUIP_TYPE_OLD = 'E' AND V_EQUIP_TYPE = 'E' THEN
     --RETURN 'YOU CANNOT CHANGE A MTA TO ANOTHER MTA '||V_SERIAL#|| ' USING THIS CHANGE OPTION.  PLEASE HAVE PLANT CREATE A TROUBLE TICKET TO SWAP ONE MTA FOR ANOTHER';
  --END IF;

  IF V_IVL_UID_PK IS NULL THEN
     BOX_MODEM_PKG.PR_EXCEPTION(V_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
     RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
     v_return_msg := 'THIS TECH IS NOT SET UP ON A TRUCK';
		 IF p_svo_uid_pk IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
  END IF;

  --BOX STATUS CHECK
  V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(V_SERIAL#, V_EQUIP_TYPE, V_DESCRIPTION);
  IF V_STATUS NOT IN ('AN','AU','RT') THEN
     BOX_MODEM_PKG.PR_EXCEPTION(V_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A BOX/MODEM TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_DESCRIPTION);
     V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(V_SERIAL#);
     RETURN 'BOX/MODEM '||V_SERIAL#|| ' IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
  	 v_return_msg := 'BOX/MODEM '||V_SERIAL#|| ' IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
		 IF p_svo_uid_pk IS NOT NULL THEN
		 		IF v_return_msg IS NOT NULL THEN
		 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
		 		END IF;
		 END IF;
  END IF;

  --LOCATION CHECK
  IF V_IVL_UID_PK IS NOT NULL THEN
     V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(V_SERIAL#);
     OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
     FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
     CLOSE LAST_LOCATION;

     IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
        IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
           BOX_MODEM_PKG.PR_EXCEPTION(V_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A BOX/MODEM TO '||V_IDENTIFIER||' '||V_SERIAL#||' IS NOT FOUND ON THE TECHS TRUCK');
           RETURN 'BOX/MODEM '||V_SERIAL#|| ' IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
        	 v_return_msg := 'BOX/MODEM '||V_SERIAL#|| ' IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
					 IF p_svo_uid_pk IS NOT NULL THEN
					 		IF v_return_msg IS NOT NULL THEN
					 		 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 		END IF;
		 			END IF;
        END IF;
     END IF;
  END IF;

  IF V_EQUIP_TYPE_OLD = 'E' AND V_EQUIP_TYPE = 'E' THEN
     OPEN GET_MEU_TYPE;
	   FETCH GET_MEU_TYPE INTO V_MTA_TYPE_ASSGNMTS,V_MTA_TYPE_ASSGNMTS_UID_PK; ---,V_MEU_MTY_UID_FK; ---HD 99905 RMC 03/09/2011 
	   CLOSE GET_MEU_TYPE;
	
	   OPEN GET_MTA_TYPE(V_MTA_UID_PK);
	   FETCH GET_MTA_TYPE INTO V_MTA_TYPE_SCANNED, V_MTA_TYPE_SCANNED_UID_PK; ---,V_MTA_MTY_UID_FK; ---HD 99905 RMC 03/09/2011 
     CLOSE GET_MTA_TYPE;
     
     ---HD 109538 RMC 07/18/2011 - No longer need to compare the MTA TYPE in MTA Equipment records to 
		 ---                           the MTA TYPE scanned in. The MTA Equipment records will be updated with
     ---                           MTA TYPE from the scanned MTA Modem. Lines commented out.
     
	   /*IF V_MTA_TYPE_ASSGNMTS_UID_PK !=  V_MTA_TYPE_SCANNED_UID_PK THEN
			  IF V_MTA_TYPE_ASSGNMTS = '728996' THEN
			     IF V_MTA_TYPE_SCANNED in ('780149','785196') THEN ---HD 109009 RMC 07/06/2011 - Added mta type of '785196' to be checked
			        NULL;
			     ELSE
			        RETURN 'THE MTA BOX TYPE SCANNED '||V_SERIAL#||' MUST EQUAL THE BOX TYPE ON THE MTA EQUIPMENT UNITS.';
			     END IF;
			  ELSIF V_MTA_TYPE_ASSGNMTS = '780149' THEN
			     IF V_MTA_TYPE_SCANNED in ('728996', '785196') THEN  ---HD 109009 RMC 07/06/2011 - Added mta type of '785196' to be checked
			        NULL;
			     ELSE
			        RETURN 'THE MTA BOX TYPE SCANNED '||V_SERIAL#||' MUST EQUAL THE BOX TYPE ON THE MTA EQUIPMENT UNITS.';
			     END IF;
			  END IF;
     END IF;*/
     
  END IF;

  -- set up flag for database and success message to be appended for developemnt 
  GET_RUN_ENVIRONMENT(P_DEVELOPMENT_ACTION,
                      v_is_production_database,
                      v_msg_suffix);
                      
  IF v_is_production_database = 'N' AND  P_DEVELOPMENT_ACTION = C_DEV_FAILURE THEN                    
    V_SUCCESS := 'ERROR'; 
  ELSE  
    --THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS
    IF V_EQUIP_TYPE = 'M' THEN
       --CHECK THAT MODEM HAS NOT ALREADY BEEN CREATED IN SO_ASSGNMTS
       OPEN CHECK_CABLE_MODEM_SO(V_SERIAL#);
       FETCH CHECK_CABLE_MODEM_SO INTO V_DUMMY;
       IF CHECK_CABLE_MODEM_SO%NOTFOUND THEN
             UPDATE SO_ASSGNMTS
                SET SON_CABLE_MODEMS_UID_FK = V_CBM_UID_PK
              WHERE SON_SO_UID_FK = P_SVO_UID_PK;
                 
             UPDATE SERVICE_ASSGNMTS
                SET SVA_CABLE_MODEMS_UID_FK = V_CBM_UID_PK
              WHERE SVA_SERVICES_UID_FK = V_SVC_UID_PK;

             INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                                 VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'The modem '||V_SERIAL#||' was added by technician '||V_EMP_NAME||' from a MAC change on IWP');
             
       END IF;
       CLOSE CHECK_CABLE_MODEM_SO;
    END IF;
    
    IF v_is_production_database = 'N' AND  P_DEVELOPMENT_ACTION = C_DEV_SUCCESS THEN                       
      V_SUCCESS := 'Y';
    ELSE
      COMMIT;
      IF V_EQUIP_TYPE_OLD = 'E' AND V_EQUIP_TYPE = 'E' THEN
         BOX_MODEM_PKG.PR_MTA_MACS(UPPER(P_NEW_CM_MAC), V_NEW_MTA_MAC, V_NEW_CM_MAC); --- HD 106740 - Added UPPER for field P_NEW_CM_MAC 
         PR_UPDATE_MTA(V_SVC_UID_PK, V_MTA_UID_PK, V_MTA_OLD_UID_PK, V_MTA_TYPE_SCANNED_UID_PK);
         COMMIT;
         C_SVC_UID_PK := NULL;
         C_SVO_UID_PK := P_SVO_UID_PK;
         V_SUCCESS := FN_SAM_MAC_CHANGE(P_OLD_CM_MAC, V_NEW_CM_MAC, V_NEW_MTA_MAC);
      ELSE
         C_SVC_UID_PK := NULL;
         C_SVO_UID_PK := P_SVO_UID_PK;
         V_SUCCESS := FN_SAM_MAC_CHANGE(P_OLD_CM_MAC, UPPER(P_NEW_CM_MAC), NULL); --- HD 106740 - Added UPPER for field P_NEW_CM_MAC 
      END IF;
      
    END IF;
    
  END IF;
  
  IF V_SUCCESS = 'Y' THEN
    IF V_EQUIP_TYPE_OLD = 'E' AND V_EQUIP_TYPE = 'M' THEN
    
      FOR SVC_REC IN get_svcs_with_box_loc(V_MTA_UID_PK, V_SLO_UID_PK) LOOP

        V_SVO_UID_PK := NULL;
        --CHECK FOR EXISTING PENDING CS ORDER
        OPEN CHECK_EXIST_PEND_CS(SVC_REC.SVC_UID_PK);
        FETCH CHECK_EXIST_PEND_CS INTO V_SVO_UID_PK;
        IF CHECK_EXIST_PEND_CS%NOTFOUND THEN
           V_SVO_UID_PK := NULL;
        END IF;
        CLOSE CHECK_EXIST_PEND_CS;

        IF V_SVO_UID_PK IS NULL THEN
           INSTALLER_WEB_PKG.CREATE_CS_ORDER(SVC_REC.SVC_UID_PK, P_EMP_UID_PK, NULL, NULL, V_SVO_UID_PK, V_RSU_#, UPPER(P_NEW_CM_MAC)); --- HD 106740 - Added UPPER for field P_NEW_CM_MAC 
        END IF;

        COMMIT;
        IF NOT FN_NISV_ON_ORDER(V_SVO_UID_PK) THEN
           --ALSO ADD 'NISV' PER REQUEST FROM RANDALL
           OPEN GET_PLNT_INFO(SVC_REC.STY_UID_PK, V_BSO_UID_PK, 'NISV');
           FETCH GET_PLNT_INFO INTO V_OSF_UID_PK;
           CLOSE GET_PLNT_INFO;

           --INSERT WITH ACTION FLAG OF 'A' WITH THE NISVCODE
           INSERT INTO SO_FEATURES(SOF_UID_PK, SOF_SO_UID_FK, SOF_OFFICE_SERV_FEATS_UID_FK, SOF_QUANTITY, SOF_COST, SOF_ACTION_FL,
                                   SOF_ANNUAL_CHARGE_FL, SOF_INITIAL_CHARGE_FL, SOF_RECORDS_ONLY_FL, SOF_SERVICE_CHARGE_FL, SOF_EXT_NUM_CHG_FL,
                                SOF_COMPLETED_FL, SOF_HAND_RATED_AMOUNT, SOF_OLD_QUANTITY, SOF_WARR_START_DATE, SOF_WARR_END_DATE)
                         VALUES(SVF_SEQ.NEXTVAL, V_SVO_UID_PK, V_OSF_UID_PK, 1, 0,
                                'A', 'N', 'N', 'N', 'Y','N','N', NULL,0, NULL, NULL);
        END IF;

        IF V_SVO_UID_PK IS NOT NULL THEN
         
          PR_INSERT_SWT_LOGS(V_SVO_UID_PK, 'TRIAD_XML', 'SUCCESS', 'CHANGE MAC', 'Y'); 
          INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                               VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE MODEM '||UPPER(P_NEW_CM_MAC)||' WAS SWAPPED IN BY TECHNICIAN '||V_EMP_NAME);
        
          ---HD 106376 RMC 07/19/2011 - Added the below code to insert message that CS is for Swap to complete provisioning and do not clear/close
          ---                           until the provisioning is complete.
          INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                               VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE,'CS SO IS FOR PROVISIONING THE SWAP/MAC ADDRESS CHANGE OF THE MODEM. DO NOT CLEAR/CLOSE UNTIL THE PROVISIONING HAS BEEN COMPLETED.'); 
        ELSE
          RETURN 'A PENDING CS/MS ORDER ALREADY EXISTS FOR THIS SERVICE AND THE SWAP CANNOT BE COMPLETED.  PLEASE CALL PLANT TO LOAD YOU TO THE CS ORDER.'||v_msg_suffix;
        	v_return_msg := 'A PENDING CS/MS ORDER ALREADY EXISTS FOR THIS SERVICE AND THE SWAP CANNOT BE COMPLETED.  PLEASE CALL PLANT TO LOAD YOU TO THE CS ORDER.'||v_msg_suffix;
					IF v_svo_uid_pk IS NOT NULL THEN
						 IF v_return_msg IS NOT NULL THEN
								PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
						 END IF;
		 			END IF;
        END IF;

            /*OPEN check_if_mta_so(V_SVO_UID_PK);
            FETCH check_if_mta_so INTO V_MTO_UID_PK;
            IF check_if_mta_so%FOUND THEN
               UPDATE MTA_SO
                  SET MTO_COMMENT = UPPER(P_NEW_CM_MAC) ---HD 106740 - Added UPPER for field P_NEW_CM_MAC 
                WHERE MTO_UID_PK = V_MTO_UID_PK;

               COMMIT;

               OPEN check_if_mta_service(SVC_REC.SVC_UID_PK);
               FETCH check_if_mta_service INTO V_DUMMY;
               IF check_if_mta_service%NOTFOUND THEN
                  V_ACTION_FL := 'P';
               ELSE
                  V_ACTION_FL := NULL;
               END IF;
               CLOSE check_if_mta_service;
            END IF;
            CLOSE check_if_mta_so;*/
             
        IF v_is_production_database = 'N' AND  P_DEVELOPMENT_ACTION = C_DEV_SUCCESS THEN                       
          V_SUCCESS := 'Y';
        ELSIF v_is_production_database = 'N' AND  P_DEVELOPMENT_ACTION = C_DEV_FAILURE THEN                    
          V_SUCCESS := 'T'; 
        ELSE
          --CHANGE MAC ADDRESS IN SAM
          V_SUCCESS_FL := INSTALLER_WEB_PKG.FN_OSSGATE_DEPROVISION(V_SVO_UID_PK, NULL);
        END IF ;
        
        IF V_SUCCESS_FL = 'T' THEN  --OSSGATE DEPROVISIONING SUCCESSFUL
           V_ERROR := INSTALLER_WEB_PKG.FN_SWT_LOGS_ERROR(V_SVO_UID_PK);
           RETURN 'PROVISIONING ERROR OCCURED IN OSSGATE. PLEASE CALL PLANT. ERROR WAS: '||V_ERROR ||v_msg_suffix;
        	 v_return_msg := 'PROVISIONING ERROR OCCURED IN OSSGATE. PLEASE CALL PLANT. ERROR WAS: '||V_ERROR ||v_msg_suffix;
					 IF v_svo_uid_pk IS NOT NULL THEN
					 		IF v_return_msg IS NOT NULL THEN
					 			 PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 		END IF;
		 			 END IF;
        END IF;


        UPDATE SO
           SET SVO_SO_STATUS_UID_FK = (SELECT SOS_UID_PK FROM SO_STATUS WHERE SOS_SYSTEM_CODE = 'RDY TO CLOSE')
         WHERE SVO_UID_PK = V_SVO_UID_PK
           and SVO_UID_PK != P_SVO_UID_PK;

      END LOOP;

      --IF P_REMOVE_OLD_FL = 'Y' THEN
         --THIS WILL UPDATE THE MTA_EQUIP_UNITS TABLE WITH THE MTA AND CMAC ADDRESSES PASSED IN
         UPDATE MTA_EQUIP_UNITS
            SET MEU_MTA_BOXES_UID_FK = NULL,
                MEU_REMOVE_MTA_FL = 'Y'
          WHERE MEU_UID_PK = P_MEU_UID_PK;
         BOX_MODEM_PKG.PR_REMOVE_ACCT(V_OLD_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'REMOVE INSTALLATION', V_IVL_UID_PK);
      --END IF;
      
      OPEN CABLE_MODEM_SUB(V_OST_UID_PK);
      FETCH CABLE_MODEM_SUB INTO V_OSB_UID_PK;
      IF CABLE_MODEM_SUB%FOUND THEN
         UPDATE SO
            SET SVO_OFF_SERV_SUBS_UID_FK = V_OSB_UID_PK
          WHERE SVO_UID_PK = P_SVO_UID_PK;
      END IF;
      CLOSE CABLE_MODEM_SUB;

      BOX_MODEM_PKG.PR_ADD_ACCT(V_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'ADD ACCT WEB');
      COMMIT;
      RETURN 'Change of MAC address completed successfully on all services which had the old MTA.'|| v_msg_suffix;
   		v_return_msg := 'Change of MAC address completed successfully on all services which had the old MTA.'|| v_msg_suffix;
			IF v_svo_uid_pk IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
					  PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
		 	END IF;
   ELSIF V_EQUIP_TYPE_OLD = 'E' AND V_EQUIP_TYPE = 'E' THEN
      
       FOR SVC_REC IN get_svcs_with_box_loc_mta(V_MTA_UID_PK, V_SLO_UID_PK) LOOP

          OPEN CHECK_EXIST_PEND_CS(SVC_REC.SVC_UID_PK);
          FETCH CHECK_EXIST_PEND_CS INTO V_SVO_UID_PK;
          IF CHECK_EXIST_PEND_CS%NOTFOUND THEN
             V_SVO_UID_PK := NULL;
          END IF;
          CLOSE CHECK_EXIST_PEND_CS;
          
          IF V_SVO_UID_PK IS NULL THEN
             INSTALLER_WEB_PKG.CREATE_CS_ORDER(SVC_REC.SVC_UID_PK, P_EMP_UID_PK, NULL, NULL, V_SVO_UID_PK, V_RSU_#, V_NEW_CM_MAC);
             V_NEW_CS_CREATED_FL := 'Y';
          ELSE
             
             OPEN GET_MTO_UID_PK(V_SVO_UID_PK);
             FETCH GET_MTO_UID_PK INTO V_MTO_UID_PK;
             IF GET_MTO_UID_PK%FOUND THEN
                UPDATE MTA_SO
                   SET MTO_COMMENT = V_NEW_CM_MAC,
                       MTO_UID_# = NULL
                 WHERE MTO_UID_PK = V_MTO_UID_PK;
             END IF;
             CLOSE GET_MTO_UID_PK;
             V_NEW_CS_CREATED_FL := 'N';
          END IF;
          
          COMMIT;
          IF V_SVO_UID_PK IS NOT NULL THEN
             PR_INSERT_SWT_LOGS(V_SVO_UID_PK, 'TRIAD_XML', 'SUCCESS', 'CHANGE MAC', 'Y'); 
         
             INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                              VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE MTA '||V_NEW_MTA_MAC||' WAS SWAPPED IN BY TECHNICIAN '||V_EMP_NAME);
             
             ---HD 106376 RMC 07/19/2011 - Added the below code to insert message that CS is for Swap to complete provisioning and do not clear/close
             ---                           until the provisioning is complete.
             INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                              VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'CS SO IS FOR PROVISIONING THE SWAP/MAC ADDRESS CHANGE OF THE MODEM. DO NOT CLEAR/CLOSE UNTIL THE PROVISIONING HAS BEEN COMPLETED.'); 
          
          ELSE
             RETURN 'A PENDING CS ORDER ALREADY EXISTS FOR THIS SERVICE AND THE SWAP CANNOT BE COMPLETED.  PLEASE CALL PLANT TO LOAD YOU TO THE CS ORDER.'|| v_msg_suffix;
          	 v_return_msg := 'A PENDING CS ORDER ALREADY EXISTS FOR THIS SERVICE AND THE SWAP CANNOT BE COMPLETED.  PLEASE CALL PLANT TO LOAD YOU TO THE CS ORDER.'|| v_msg_suffix;
						 IF v_svo_uid_pk IS NOT NULL THEN
						 		IF v_return_msg IS NOT NULL THEN
						 			 PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
						 		END IF;
		 				 END IF;
          END IF;

          IF SVC_REC.STY_SYSTEM_CODE = 'PHN' THEN
             
           --ALSO ADD 'NISV' PER REQUEST FROM RANDALL
           OPEN GET_PLNT_INFO(SVC_REC.STY_UID_PK, V_BSO_UID_PK, 'NISV');
           FETCH GET_PLNT_INFO INTO V_OSF_UID_PK;
           CLOSE GET_PLNT_INFO;

           --INSERT WITH ACTION FLAG OF 'A' WITH THE NISVCODE
           INSERT INTO SO_FEATURES(SOF_UID_PK, SOF_SO_UID_FK, SOF_OFFICE_SERV_FEATS_UID_FK, SOF_QUANTITY, SOF_COST, SOF_ACTION_FL,
                                   SOF_ANNUAL_CHARGE_FL, SOF_INITIAL_CHARGE_FL, SOF_RECORDS_ONLY_FL, SOF_SERVICE_CHARGE_FL, SOF_EXT_NUM_CHG_FL,
                                SOF_COMPLETED_FL, SOF_HAND_RATED_AMOUNT, SOF_OLD_QUANTITY, SOF_WARR_START_DATE, SOF_WARR_END_DATE)
                         VALUES(SVF_SEQ.NEXTVAL, V_SVO_UID_PK, V_OSF_UID_PK, 1, 0,
                                'A', 'N', 'N', 'N', 'Y','N','N', NULL,0, NULL, NULL);
                                
             --CHANGE MAC ADDRESS IN SAM
             IF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_SUCCESS THEN
                V_SUCCESS_FL := 'Y';
      
             ELSIF v_is_production_database = 'N' and P_DEVELOPMENT_ACTION  = C_DEV_FAILURE THEN
                V_SUCCESS_FL := 'T';
      
             ELSE 
                 
                 --- HD 105771 RMC 05/03/2011 - MLH Processing
						    V_MLH_MESSAGE := INSTALLER_WEB_PKG.FN_MLH_CHECK(P_SVO_UID_PK); 
						 		IF V_MLH_MESSAGE IS NULL THEN 
						 			 V_MLH_FOUND_FL := 'N';
						       V_SUCCESS_FL := INSTALLER_WEB_PKG.FN_OSSGATE_DEPROVISION(V_SVO_UID_PK); 
						    ELSE  
						       V_MLH_FOUND_FL := 'Y';   
                END IF; 
              
                ---V_SUCCESS_FL := INSTALLER_WEB_PKG.FN_OSSGATE_DEPROVISION(V_SVO_UID_PK); --- HD 105771 RMC 05/03/2011
                
             END IF;
         
             IF V_SUCCESS_FL = 'T' THEN  --OSSGATE DEPROVISIONING SUCCESSFUL
         
                -- HD 104876 RMC 04/1/2011 - added V_MTA_TYPE_SCANNED_UID_PK
                PR_UPDATE_MTA(V_SVC_UID_PK, V_MTA_OLD_UID_PK, V_MTA_UID_PK, V_MTA_TYPE_SCANNED_UID_PK);  --SWITCH BACK IF PROVISIONING FAILED
                COMMIT;
                V_ERROR := INSTALLER_WEB_PKG.FN_SWT_LOGS_ERROR(V_SVO_UID_PK);
            
            
                RETURN 'PROVISIONING ERROR OCCURED IN OSSGATE.  PLEASE CALL PLANT.  ERROR WAS :'||V_ERROR|| v_msg_suffix;
         				v_return_msg := 'PROVISIONING ERROR OCCURED IN OSSGATE.  PLEASE CALL PLANT.  ERROR WAS :'||V_ERROR|| v_msg_suffix;
						 		IF v_svo_uid_pk IS NOT NULL THEN
						 			 IF v_return_msg IS NOT NULL THEN
						 			 		PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
						 			 END IF;
		 				 		END IF;    
             END IF;
          END IF;

          PR_UPDATE_MTA(V_SVC_UID_PK, V_MTA_UID_PK, V_MTA_OLD_UID_PK, V_MTA_TYPE_SCANNED_UID_PK); -- HD 104876 RMC 04/1/2011 - added V_MTA_TYPE_SCANNED_UID_PK
          BOX_MODEM_PKG.PR_REMOVE_ACCT(P_OLD_CM_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'REMOVE INSTALLATION', V_IVL_UID_PK);
          BOX_MODEM_PKG.PR_ADD_ACCT(V_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'ADD ACCT WEB');
          
          IF V_NEW_CS_CREATED_FL = 'Y' THEN
             UPDATE SO
                SET SVO_SO_STATUS_UID_FK = (SELECT SOS_UID_PK FROM SO_STATUS WHERE SOS_SYSTEM_CODE = 'RDY TO CLOSE')
              WHERE SVO_UID_PK = V_SVO_UID_PK;
          END IF;

        END LOOP;
        
        COMMIT;
        
        --- HD 105771 RMC 05/03/2011 - MLH Processing
				IF V_MLH_FOUND_FL = 'N' THEN
				   RETURN 'Change of MAC address completed successfully on all services which had the old MTA.'|| v_msg_suffix;
					 v_return_msg:= 'Change of MAC address completed successfully on all services which had the old MTA.'|| v_msg_suffix;
					 IF v_svo_uid_pk IS NOT NULL THEN
					 		IF v_return_msg IS NOT NULL THEN
					 			 PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 		END IF;
		 			 END IF; 
				ELSE
				   RETURN 'CHANGE OF MAC ADDRESS. THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR THE CABLE MODEM IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.';
           v_return_msg:= 'CHANGE OF MAC ADDRESS. THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR THE CABLE MODEM IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.';
           IF v_svo_uid_pk IS NOT NULL THEN
					 		IF v_return_msg IS NOT NULL THEN
					 			 PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
					 		END IF;
		 			 END IF; 
           ---HD 111020 RMC 08/25/2011 - Added the below code to insert message service order is for multi line hunt and call CO to provision the phone portion.
					             
					 INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
					                  VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THIS SERVICE ORDER IS FOR A MULTI LINE HUNT SERVICE. THE PROVISIONING FOR THE CABLE MODEM IS COMPLETE. PLEASE CALL THE CO TO WORK THE VOICE PORTION.'); 
           COMMIT;
        
        END IF;
        
        ---RETURN 'Change of MAC address completed successfully on all services which had the old MTA.'|| v_msg_suffix; --- HD 105771 RMC 05/03/2011
    
    ELSIF V_EQUIP_TYPE_OLD = 'M' AND V_EQUIP_TYPE = 'M' THEN
      --IF P_REMOVE_OLD_FL = 'Y' THEN
         BOX_MODEM_PKG.PR_REMOVE_ACCT(V_OLD_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'REMOVE INSTALLATION', V_IVL_UID_PK);
      --END IF;
      BOX_MODEM_PKG.PR_ADD_ACCT(V_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'ADD ACCT WEB');
      COMMIT;
      RETURN 'Change of MAC address completed successfully on the service which had the old cable modem.'|| v_msg_suffix;
    	v_return_msg:= 'Change of MAC address completed successfully on the service which had the old cable modem.'|| v_msg_suffix;
			IF v_svo_uid_pk IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
					  PR_INS_SO_ERROR_LOGS(V_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
		 	END IF;
    END IF;
  ELSE
     PR_INSERT_SWT_LOGS(P_SVO_UID_PK, 'TRIAD_XML', V_SUCCESS, 'CHANGE MAC');
     PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, V_SUCCESS);
     RETURN V_SUCCESS  || v_msg_suffix;
  END IF;

END FN_MAC_ADDRESS_CHANGE;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_SAM_MAC_CHANGE(P_OLD_CM_MAC IN VARCHAR, P_NEW_CM_MAC IN VARCHAR, P_NEW_MTA_MAC IN VARCHAR)
RETURN VARCHAR
--99999
IS

V_OUT_MESSAGE      VARCHAR2(2000);
V_SUCCESS          VARCHAR2(2000);
V_FQDN             VARCHAR2(200);
V_EQUIP_TYPE_OLD   VARCHAR2(5);
V_EQUIP_TYPE_NEW   VARCHAR2(5);
V_BOX_UID_PK_OLD   NUMBER;
V_BOX_UID_PK_NEW   NUMBER;
V_TYPE             VARCHAR2(1);
V_TIME             VARCHAR2(200);

BEGIN


IF P_OLD_CM_MAC IS NOT NULL AND P_NEW_CM_MAC IS NOT NULL THEN
  V_EQUIP_TYPE_OLD := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_OLD_CM_MAC, V_BOX_UID_PK_OLD);
  V_EQUIP_TYPE_NEW := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_NEW_CM_MAC, V_BOX_UID_PK_NEW);
  IF V_EQUIP_TYPE_OLD = 'E' THEN --MTA
     V_TYPE := 'P';
  ELSIF V_EQUIP_TYPE_OLD = 'M' THEN --CABLE MODEM
     V_TYPE := 'A';
  END IF;

  
  v_isp_success_fl := provision_triad_service_fun(v_box_uid_pk_old,v_type, v_job_number);

        
  DBMS_OUTPUT.PUT_LINE('c svo is  '||C_SVO_UID_PK);
  DBMS_OUTPUT.PUT_LINE('c serv is '||C_SVC_UID_PK);
        
    IF V_ISP_SUCCESS_FL = 'SUCCESS' THEN
       V_ISP_SUCCESS_FL := 'N';
       IF C_SVC_UID_PK IS NOT NULL THEN
          v_isp_success_fl := provision_triad_service_fun(c_svc_uid_pk,NULL,v_job_number);
       ELSE
          v_isp_success_fl := provision_triad_so_fun(c_svo_uid_pk);
       END IF;
               
               
       IF V_ISP_SUCCESS_FL IN ('Y','SUCCESS') THEN
          V_SUCCESS := 'SUCCESS';
       END IF;
    ELSE
     V_SUCCESS := 'N';
    END IF;
 
  --V_SUCCESS := PACKETCABLE_FQDN.change_mac(P_OLD_CM_MAC, P_NEW_CM_MAC, P_NEW_MTA_MAC, V_OUT_MESSAGE, V_FQDN);
ELSE
  V_SUCCESS := 'SUCCESS';
END IF;

IF V_SUCCESS = 'SUCCESS' THEN
   RETURN 'Y';
ELSE
   RETURN 'Triad Provisioning Not Successful.  Please contact the helpdesk';
END IF;

END FN_SAM_MAC_CHANGE;

/*-------------------------------------------------------------------------------------------------------------*/
PROCEDURE PR_UPDATE_MTA(P_SVC_UID_PK IN NUMBER, P_MTA_NEW_UID_PK IN NUMBER, P_MTA_OLD_UID_PK IN NUMBER, P_MTA_TYPE_SCANNED_UID_PK IN NUMBER)

IS

BEGIN



  --THIS WILL UPDATE ALL SERVICES WITH THE SAME BOX AT THIS LOCATION
  --THIS SHOULD RESOLVE ISSUE IF TROUBLE TICKET IS ON PHONE OR HIGH SPEED BUT NOT BOTH WHERE
  --IF THE BOX IS BAD AND REPLACED WITH WILL WORK FOR BOTH.
  --UPDATE THE BOX FK ON MTA_EQUIP_UNITS
  UPDATE MTA_EQUIP_UNITS
     SET MEU_MTA_BOXES_UID_FK = P_MTA_NEW_UID_PK,
         MEU_MTA_TYPES_UID_FK = P_MTA_TYPE_SCANNED_UID_PK -- HD 104876 RMC 04/1/2011
   WHERE MEU_MTA_BOXES_UID_FK = P_MTA_OLD_UID_PK
     AND MEU_UID_PK IN (SELECT MTP_MTA_EQUIP_UNITS_UID_FK
                          FROM MTA_PORTS, MTA_SERVICES, SERVICE_ASSGNMTS
                         WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
                           AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
                           AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
                           AND SVA_SERVICES_UID_FK = P_SVC_UID_PK);

  UPDATE MTA_EQUIP_UNITS
     SET MEU_MTA_BOXES_UID_FK = P_MTA_NEW_UID_PK,
     MEU_MTA_TYPES_UID_FK = P_MTA_TYPE_SCANNED_UID_PK -- HD 104876 RMC 04/1/2011
   WHERE MEU_MTA_BOXES_UID_FK = P_MTA_OLD_UID_PK
     AND MEU_UID_PK IN (SELECT MTP_MTA_EQUIP_UNITS_UID_FK
                          FROM MTA_PORTS, MTA_SO, SO_ASSGNMTS, SO, SO_STATUS
                         WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
                           AND MTP_UID_PK = MTO_MTA_PORTS_UID_FK
                           AND SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
                           AND SVO_UID_PK = SON_SO_UID_FK
                           AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                           AND SVO_SERVICES_UID_FK = P_SVC_UID_PK
                           AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));

END PR_UPDATE_MTA;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_NISV_ON_ORDER(P_SVO_UID_PK IN NUMBER)
RETURN BOOLEAN

IS

CURSOR NISV_ON_ORDER IS
 SELECT 'X'
   FROM SO_FEATURES, OFFICE_SERV_FEATS, FEATURES
  WHERE SOF_SO_UID_FK = P_SVO_UID_PK
    AND OSF_UID_PK = SOF_OFFICE_SERV_FEATS_UID_FK
    AND FTP_UID_PK = OSF_FEATURES_UID_FK
    AND FTP_CODE = 'NISV'
    AND SOF_ACTION_FL IN ('A','N');

V_DUMMY  VARCHAR2(1);

BEGIN

OPEN NISV_ON_ORDER;
FETCH NISV_ON_ORDER INTO V_DUMMY;
IF NISV_ON_ORDER%FOUND THEN
   RETURN TRUE;
END IF;
CLOSE NISV_ON_ORDER;

RETURN FALSE;

END FN_NISV_ON_ORDER;

FUNCTION FN_TECHNICIAN_LOADED(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR

IS

CURSOR TECH_LOADED IS
 SELECT 'X'
   FROM SO_LOADINGS, EMPLOYEES, CONTRACTOR_COMPANY
  WHERE SDS_SO_UID_FK = P_SVO_UID_PK
    AND EMP_UID_PK = SDS_EMPLOYEES_UID_FK
    AND COC_UID_PK = EMP_CONTRACTOR_COMPANY_UID_FK
    AND SDS_COMPLETED_FL = 'N';

V_DUMMY  VARCHAR2(1);

BEGIN

OPEN TECH_LOADED;
FETCH TECH_LOADED INTO V_DUMMY;
IF TECH_LOADED%FOUND THEN
   RETURN 'T';
END IF;
CLOSE TECH_LOADED;

RETURN 'F';

END FN_TECHNICIAN_LOADED;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_TT_PORT_CHG_DISPLAY(P_SLO_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

CURSOR ACTIVE_MTA IS
SELECT 'X'
FROM MTA_SERVICES, SERVICE_ASSGNMTS, SERVICES, SERV_SERV_LOCATIONS
WHERE SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
  AND SVC_UID_PK = SVA_SERVICES_UID_FK
  AND SVC_UID_PK = SSL_SERVICES_UID_FK
  AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
  AND SSL_END_DATE IS NULL
  AND SSL_PRIMARY_LOC_FL = 'Y'
  AND SVC_END_DATE IS NULL;

CURSOR PHONE_SERVICE_EXISTS IS
SELECT 'X'
  FROM SERVICES,
       OFFICE_SERV_TYPES,
       SERVICE_TYPES,
       OFF_SERV_SUBS,
       SERV_SUB_TYPES,
       SERV_SERV_LOCATIONS
 WHERE SVC_UID_PK = SSL_SERVICES_UID_FK
   AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
   AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
   AND OSB_UID_PK = SVC_OFF_SERV_SUBS_UID_FK
   AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
   AND STY_SYSTEM_CODE = 'PHN'
   AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
   AND SSL_END_DATE IS NULL
   AND SSL_PRIMARY_LOC_FL = 'Y'
   AND SVC_END_DATE IS NULL;

CURSOR GET_SERVICES IS
SELECT SVC_UID_PK,
       GET_IDENTIFIER_FUN(SVC_UID_PK, OST_UID_PK) IDENTIFIER,
       STY_CODE,
       MTP_LINE_NO#,
       SVA_UID_PK
  FROM SERVICES,
       OFFICE_SERV_TYPES,
       SERVICE_TYPES,
       SERV_SERV_LOCATIONS,
       SERVICE_ASSGNMTS,
       MTA_SERVICES,
       MTA_PORTS
 WHERE SVC_UID_PK = SSL_SERVICES_UID_FK
   AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
   AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
   AND SVC_UID_PK = SVA_SERVICES_UID_FK
   AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
   AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
   AND STY_SYSTEM_CODE = 'PHN'
   AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
   AND SSL_END_DATE IS NULL
   AND SSL_PRIMARY_LOC_FL = 'Y'
   AND SVC_END_DATE IS NULL
  ORDER BY STY_CODE;

rec                GET_SERVICES%rowtype;
v_rec              generic_data_type;
v_dummy            varchar2(1);
v_mac_address      varchar2(20);
v_rsu_rsu_#        varchar2(40);

BEGIN

IF P_SLO_UID_PK IS NOT NULL AND INSTALLER_WEB_PKG.FN_EMTA_LOCATION(P_SLO_UID_PK) = 'Y' THEN

 OPEN ACTIVE_MTA;
 FETCH ACTIVE_MTA INTO V_DUMMY;
 IF ACTIVE_MTA%FOUND THEN
       OPEN PHONE_SERVICE_EXISTS;
       FETCH PHONE_SERVICE_EXISTS INTO V_DUMMY;
       IF PHONE_SERVICE_EXISTS%FOUND THEN
          OPEN GET_SERVICES;
          LOOP
             FETCH GET_SERVICES into rec;
             EXIT WHEN GET_SERVICES%notfound;

             --set the fields
             v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

             v_rec.gdt_number1    := rec.sva_uid_pk;    -- svc_uid_pk
             v_rec.gdt_alpha1     := rec.identifier;    -- identifier
             v_rec.gdt_number2    := rec.MTP_LINE_NO#;  -- port#

             PIPE ROW (v_rec);
          END LOOP;

          CLOSE GET_SERVICES;
       END IF;
       CLOSE PHONE_SERVICE_EXISTS;
 END IF;
 CLOSE ACTIVE_MTA;

END IF;

RETURN;

END FN_TT_PORT_CHG_DISPLAY;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_TT_PORT_CHANGE (P_SVA_UID_PK IN NUMBER, P_PORT IN NUMBER, P_EMP_UID_PK IN NUMBER, P_CMAC IN VARCHAR, P_MTAMAC IN VARCHAR, P_TDP_UID_PK IN NUMBER)
RETURN VARCHAR

IS

CURSOR GET_IDENTIFIER IS
  SELECT TRT_UID_PK,
         EMP_FNAME||' '||EMP_LNAME
  FROM SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, TROUBLE_TICKETS, TROUBLE_DISPATCHES, TRBL_DSP_TECHS, EMPLOYEES
  WHERE TDP_UID_PK = P_TDP_UID_PK
    AND TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
    AND SVC_UID_PK = TRT_SERVICES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND TDT_UID_PK = TDP_TRBL_DSP_TECHS_UID_FK
    AND EMP_UID_PK = TDT_EMPLOYEES_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK;

CURSOR GET_SVC IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
         SVC_UID_PK,
         STY_SYSTEM_CODE
  FROM SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SERVICE_ASSGNMTS
  WHERE SVA_UID_PK = P_SVA_UID_PK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND SVC_UID_PK = SVA_SERVICES_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK;

CURSOR CHECK_EXIST_PORT IS
  SELECT MTP_LINE_NO#
    FROM MTA_PORTS, MTA_SERVICES
   WHERE MTP_UID_PK = MSS_MTA_PORTS_UID_FK
     AND MSS_SERVICE_ASSGNMTS_UID_FK = P_SVA_UID_PK;

V_SVO_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_STY_UID_PK           NUMBER;
V_TRT_UID_PK           NUMBER;
V_PORT#                NUMBER;
V_DUMMY                VARCHAR2(1);
V_SUCCESS_FL           VARCHAR2(1);
V_RETURN_MESSAGE       VARCHAR2(2000) := NULL;
V_IDENTIFIER           VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);
V_RSU_#                VARCHAR2(40);
V_STY_SYSTEM_CODE      VARCHAR2(40);
V_MAC_MESSAGE          VARCHAR2(2000) := NULL;

BEGIN

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_TRT_UID_PK, V_EMP_NAME;
CLOSE GET_IDENTIFIER;

OPEN GET_SVC;
FETCH GET_SVC INTO V_IDENTIFIER, V_SVC_UID_PK, V_STY_SYSTEM_CODE;
CLOSE GET_SVC;

OPEN CHECK_EXIST_PORT;
FETCH CHECK_EXIST_PORT INTO V_PORT#;
IF CHECK_EXIST_PORT%NOTFOUND THEN
   RETURN 'EXISTING PORT ON '||V_IDENTIFIER||' IS NOT FOUND AND THIS CHANGE IN PORTS CANNOT OCCUR.  PLEASE CALL PLANT AT 815-1900';
END IF;
CLOSE CHECK_EXIST_PORT;

IF V_PORT# != P_PORT THEN --THEY ARE DIFFERENT SO IT NEEDS A PORT CHANGE

   INSTALLER_WEB_PKG.CREATE_CS_ORDER(V_SVC_UID_PK, P_EMP_UID_PK, P_PORT, NULL, V_SVO_UID_PK, V_RSU_#, P_CMAC);

   COMMIT;
   IF V_SVO_UID_PK IS NOT NULL THEN
      INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                          VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE MTA '||P_MTAMAC||' WAS ADDED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' TO SWITCH PORTS ON THE EXISTING MTA BOX BY TECHNICIAN '||V_EMP_NAME);

      
      ---HD 106376 RMC 07/19/2011 - Added the below code to insert message that CS is for Swap to complete provisioning and do not clear/close
			---                           until the provisioning is complete.
      INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                          VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE,'CS SO IS FOR PROVISIONING THE SWAP/MAC ADDRESS CHANGE OF THE MODEM. DO NOT CLEAR/CLOSE UNTIL THE PROVISIONING HAS BEEN COMPLETED.');
      COMMIT;
   ELSE
      V_RETURN_MESSAGE := 'A PENDING CS ORDER ALREADY EXISTS FOR IDENTIFIER '||V_IDENTIFIER||' AND THE PORT CHANGE CANNOT BE COMPLETED.  PLEASE CALL PLANT TO SEE IF THE PENDING CS ORDER CAN BE CLEARED.';
   END IF;

   IF V_RETURN_MESSAGE IS NULL THEN
      --CHANGE MAC ADDRESS IN SAM
      V_SUCCESS_FL := INSTALLER_WEB_PKG.FN_OSSGATE_REPROVISION(V_SVO_UID_PK);
      IF V_SUCCESS_FL = 'T' THEN
         V_ERROR := INSTALLER_WEB_PKG.FN_SWT_LOGS_ERROR(V_SVO_UID_PK);
         V_RETURN_MESSAGE := 'RE-PROVISIONING ERROR OCCURED ON IDENTIFIER '||V_IDENTIFIER||' IN OSSGATE.  PLEASE CALL PLANT.  ERROR WAS '||V_ERROR;
      ELSE
         V_RETURN_MESSAGE := 'PORT CHANGE COMPLETED SUCCESSFULLY ON IDENTIFIER '||V_IDENTIFIER||' FROM PORT '||V_PORT#||' TO '||P_PORT;
      END IF;

      UPDATE SO
         SET SVO_SO_STATUS_UID_FK = (SELECT SOS_UID_PK FROM SO_STATUS WHERE SOS_SYSTEM_CODE = 'RDY TO CLOSE')
       WHERE SVO_UID_PK = V_SVO_UID_PK;
   END IF;
ELSE
   V_RETURN_MESSAGE := 'THE IDENTIFIER '||V_IDENTIFIER||' WAS NOT UPDATED TO REQUIRE A PORT CHANGE.';
END IF;

COMMIT;

RETURN V_RETURN_MESSAGE;

END FN_TT_PORT_CHANGE;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_SWT_LOGS_ERROR(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR

IS

CURSOR LAST_CANDIDATE_ERROR IS
 SELECT SLS_RESPONSE
   FROM SWT_LOGS, SWT_EQUIPMENT
  WHERE SLS_SO_UID_FK = P_SVO_UID_PK
    AND SEQ_UID_PK = SLS_SWT_EQUIPMENT_UID_FK
    AND SEQ_CODE = 'OSSGATE'
    AND SLS_SUCCESS_FL = 'N'
  ORDER BY SWT_LOGS.CREATED_DATE DESC;

V_RESPONSE  						VARCHAR2(2000);

v_return_msg  					VARCHAR2(4000);

V_SEL_PROCEDURE_NAME	  VARCHAR2(40):= 'FN_SWT_LOGS_ERROR';


BEGIN

OPEN LAST_CANDIDATE_ERROR;
FETCH LAST_CANDIDATE_ERROR INTO V_RESPONSE;
IF LAST_CANDIDATE_ERROR%FOUND THEN
   RETURN V_RESPONSE;
END IF;
CLOSE LAST_CANDIDATE_ERROR;

RETURN 'NO ERROR FOUND ON SWITCH LOGS';

v_return_msg:= 'NO ERROR FOUND ON SWITCH LOGS';
IF p_svo_uid_pk IS NOT NULL THEN
	 IF v_return_msg IS NOT NULL THEN
			PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 END IF;
END IF;

END FN_SWT_LOGS_ERROR;

PROCEDURE PR_INSERT_SWT_LOGS(P_SVO_UID_PK IN NUMBER, P_SEQ_CODE IN VARCHAR, P_MSG IN VARCHAR, P_COMMAND IN VARCHAR, P_SUCCESS_FL IN VARCHAR DEFAULT 'N')

IS

CURSOR GET_SWT_EQUIPMENT IS
  SELECT SEQ_UID_PK
    FROM SWT_EQUIPMENT
   WHERE SEQ_CODE = P_SEQ_CODE;

V_SEQ_UID_PK   NUMBER;

BEGIN

OPEN GET_SWT_EQUIPMENT;
FETCH GET_SWT_EQUIPMENT INTO V_SEQ_UID_PK;
IF GET_SWT_EQUIPMENT%FOUND THEN
   INSERT INTO SWT_LOGS (SLS_UID_PK, SLS_SO_UID_FK, SLS_SWT_EQUIPMENT_UID_FK, SLS_SUCCESS_FL, SLS_COMMAND_SENT, SLS_CREATED_TIME, SLS_RESPONSE)
                 VALUES (SLS_SEQ.NEXTVAL, P_SVO_UID_PK, V_SEQ_UID_PK, P_SUCCESS_FL, P_COMMAND, SYSDATE, P_MSG);
   COMMIT;
END IF;
CLOSE GET_SWT_EQUIPMENT;

END PR_INSERT_SWT_LOGS;

PROCEDURE PR_INSERT_SO_MESSAGE(P_SVO_UID_PK IN NUMBER, P_MSG IN VARCHAR)

IS

BEGIN

INSERT INTO SO_MESSAGES (SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                 VALUES (SOG_SEQ.NEXTVAL, P_SVO_UID_PK, USER, TRUNC(SYSDATE), SYSDATE, P_MSG);

COMMIT;

END PR_INSERT_SO_MESSAGE;

PROCEDURE PR_INSERT_IWP_REPORTS(P_TITLE IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_MESSAGE IN CLOB, P_URL IN VARCHAR, P_REPORT IN CLOB)

IS

BEGIN

INSERT INTO IWP_REPORTS (IWR_UID_PK, IWR_EMPLOYEES_UID_FK, IWR_ACTIVE_FL, IWR_TITLE, IWR_ERROR_PATH, IWR_CRASH_REPORT, IWR_MESSAGE)
                 VALUES (IWR_SEQ.NEXTVAL, P_EMP_UID_PK, 'Y', P_TITLE, P_URL, P_REPORT, P_MESSAGE);

COMMIT;

END PR_INSERT_IWP_REPORTS;
/*-------------------------------------------------------------------------------------------------------------*/

FUNCTION FN_RFOG_LOCATION(P_SLO_UID_PK IN NUMBER)
RETURN VARCHAR

IS

CURSOR SLO_RFOG IS
    SELECT 'Y'
      FROM out_net_units, onu_types
     WHERE onu_service_locations_uid_fk in
                   (select s2.slo_uid_pk
                   from service_locations s1, service_locations s2
                  where s1.slo_uid_pk = P_SLO_UID_PK
                    and s1.slo_municipalities_uid_fk = s2.slo_municipalities_uid_fk
                    and s1.slo_streets_uid_fk = s2.slo_streets_uid_fk
                    and ((s1.slo_street_nums_uid_fk = s2.slo_street_nums_uid_fk and s1.slo_street_nums_uid_fk is not null)
                     or (s2.slo_street_nums_uid_fk is null and s1.slo_street_nums_uid_fk is null))
                    and ((s1.slo_buildings_uid_fk = s2.slo_buildings_uid_fk and s1.slo_buildings_uid_fk is not null)
                     or (s2.slo_buildings_uid_fk is null and s1.slo_buildings_uid_fk is null))
                    and ((s1.slo_building_units_uid_fk = s2.slo_building_units_uid_fk and s1.slo_building_units_uid_fk is not null)
                     or (s2.slo_building_units_uid_fk is null and s1.slo_building_units_uid_fk is null)))
       and onu_onu_types_uid_fk = otp_uid_pk
       and otp_system_code in ('MTA','EMTA')
    UNION
    SELECT 'Y'
      FROM onu_ports
     WHERE onp_service_locations_uid_fk in
                   (select s2.slo_uid_pk
                   from service_locations s1, service_locations s2
                  where s1.slo_uid_pk = P_SLO_UID_PK
                    and s1.slo_municipalities_uid_fk = s2.slo_municipalities_uid_fk
                    and s1.slo_streets_uid_fk = s2.slo_streets_uid_fk
                    and ((s1.slo_street_nums_uid_fk = s2.slo_street_nums_uid_fk and s1.slo_street_nums_uid_fk is not null)
                     or (s2.slo_street_nums_uid_fk is null and s1.slo_street_nums_uid_fk is null))
                    and ((s1.slo_buildings_uid_fk = s2.slo_buildings_uid_fk and s1.slo_buildings_uid_fk is not null)
                     or (s2.slo_buildings_uid_fk is null and s1.slo_buildings_uid_fk is null))
                    and ((s1.slo_building_units_uid_fk = s2.slo_building_units_uid_fk and s1.slo_building_units_uid_fk is not null)
                     or (s2.slo_building_units_uid_fk is null and s1.slo_building_units_uid_fk is null)))
    UNION
    SELECT 'Y'
      FROM ds0_ports
     WHERE ds0_service_locations_uid_fk in
                   (select s2.slo_uid_pk
                   from service_locations s1, service_locations s2
                  where s1.slo_uid_pk = P_SLO_UID_PK
                    and s1.slo_municipalities_uid_fk = s2.slo_municipalities_uid_fk
                    and s1.slo_streets_uid_fk = s2.slo_streets_uid_fk
                    and ((s1.slo_street_nums_uid_fk = s2.slo_street_nums_uid_fk and s1.slo_street_nums_uid_fk is not null)
                     or (s2.slo_street_nums_uid_fk is null and s1.slo_street_nums_uid_fk is null))
                    and ((s1.slo_buildings_uid_fk = s2.slo_buildings_uid_fk and s1.slo_buildings_uid_fk is not null)
                     or (s2.slo_buildings_uid_fk is null and s1.slo_buildings_uid_fk is null))
                    and ((s1.slo_building_units_uid_fk = s2.slo_building_units_uid_fk and s1.slo_building_units_uid_fk is not null)
                     or (s2.slo_building_units_uid_fk is null and s1.slo_building_units_uid_fk is null)));

V_SLO_RFOG_FL   VARCHAR2(1);

BEGIN

  V_SLO_RFOG_FL := 'N';
  OPEN SLO_RFOG;
  FETCH SLO_RFOG INTO V_SLO_RFOG_FL;
  IF SLO_RFOG%NOTFOUND THEN
     V_SLO_RFOG_FL := 'N';
  END IF;
  CLOSE SLO_RFOG;

RETURN V_SLO_RFOG_FL;

END FN_RFOG_LOCATION;

FUNCTION FN_RFOG_DISPLAY(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

CURSOR GET_SLO IS
  SELECT SSX_SERVICE_LOCATIONS_UID_FK
    FROM SERV_SERV_LOC_SO
   WHERE SSX_SO_UID_FK = P_SVO_UID_PK
     AND SSX_END_DATE IS NULL
UNION
  SELECT SSL_SERVICE_LOCATIONS_UID_FK
    FROM SERV_SERV_LOCATIONS
   WHERE SSL_SERVICES_UID_FK = P_SVC_UID_PK
     AND SSL_END_DATE IS NULL;

CURSOR ACTIVE_MTA(P_SLO_UID_PK IN NUMBER) IS
  SELECT MTA_MTAMAC_ADDRESS, MTA_CMAC_ADDRESS
    FROM MTA_BOXES, BOX_MODEM_HISTORY, INVENTORY_HISTORY_TYPES
   WHERE MTA_UID_PK = BMH_MTA_BOXES_UID_FK
     AND BMH_SO_UID_FK = P_SVO_UID_PK
     AND BMH_END_DATE IS NULL
     AND IHT_SYSTEM_CODE IN ('ADD ACCT WEB','ADD ACCT HES')
     AND IHT_UID_PK = BMH_INV_HIST_TYPES_UID_FK
 UNION
 SELECT MTA_MTAMAC_ADDRESS, MTA_CMAC_ADDRESS
    FROM MTA_BOXES, BOX_MODEM_HISTORY, INVENTORY_HISTORY_TYPES
   WHERE MTA_UID_PK = BMH_MTA_BOXES_UID_FK
     AND BMH_SERVICES_UID_FK = P_SVC_UID_PK
     AND BMH_END_DATE IS NULL
     AND IHT_SYSTEM_CODE IN ('ADD ACCT WEB','ADD ACCT HES')
     AND IHT_UID_PK = BMH_INV_HIST_TYPES_UID_FK
 UNION
  SELECT MTA_MTAMAC_ADDRESS, MTA_CMAC_ADDRESS
    FROM MTA_BOXES, BOX_MODEM_HISTORY, INVENTORY_HISTORY_TYPES, SO, SERV_SERV_LOC_SO
   WHERE MTA_UID_PK = BMH_MTA_BOXES_UID_FK
     AND BMH_SO_UID_FK = SVO_UID_PK
     AND SVO_UID_PK = SSX_SO_UID_FK
     AND SSX_END_DATE IS NULL
     AND SSX_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
     AND BMH_END_DATE IS NULL
     AND IHT_SYSTEM_CODE IN ('ADD ACCT WEB','ADD ACCT HES')
     AND IHT_UID_PK = BMH_INV_HIST_TYPES_UID_FK
 UNION
 SELECT MTA_MTAMAC_ADDRESS, MTA_CMAC_ADDRESS
    FROM MTA_BOXES, BOX_MODEM_HISTORY, INVENTORY_HISTORY_TYPES, SERVICES, SERV_SERV_LOCATIONS
   WHERE MTA_UID_PK = BMH_MTA_BOXES_UID_FK
     AND BMH_SERVICES_UID_FK = SVC_UID_PK
     AND SVC_UID_PK = SSL_SERVICES_UID_FK
     AND SSL_END_DATE IS NULL
     AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
     AND BMH_END_DATE IS NULL
     AND IHT_SYSTEM_CODE IN ('ADD ACCT WEB','ADD ACCT HES')
     AND IHT_UID_PK = BMH_INV_HIST_TYPES_UID_FK;

rec            ACTIVE_MTA%rowtype;
v_rec          generic_data_type;
V_SLO_UID_PK   NUMBER;

BEGIN

--GET SLO PK
OPEN GET_SLO;
FETCH GET_SLO INTO V_SLO_UID_PK;
CLOSE GET_SLO;

          OPEN ACTIVE_MTA(V_SLO_UID_PK);
          FETCH ACTIVE_MTA into rec;
          IF ACTIVE_MTA%FOUND THEN
             --set the fields
             v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

             v_rec.gdt_alpha1    := rec.MTA_MTAMAC_ADDRESS;  -- MTA MAC
             v_rec.gdt_alpha2    := rec.MTA_CMAC_ADDRESS;    -- CM MAC

             PIPE ROW (v_rec);
          END IF;
          CLOSE ACTIVE_MTA;

RETURN;

END FN_RFOG_DISPLAY;

FUNCTION FN_ADD_RFOG(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MTA_MAC IN VARCHAR, P_CMAC_MAC IN VARCHAR)
RETURN VARCHAR IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
  SELECT IVL_UID_PK
    FROM INVENTORY_LOCATIONS
   WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

CURSOR MTA_ALREADY_ON(P_MTA_UID_PK IN NUMBER, P_SLO_UID_PK IN NUMBER) IS
  SELECT 'Y'A
    FROM MTA_BOXES, BOX_MODEM_HISTORY, INVENTORY_HISTORY_TYPES, SO, SERV_SERV_LOC_SO
   WHERE MTA_UID_PK = BMH_MTA_BOXES_UID_FK
     AND SVO_UID_PK = BMH_SO_UID_FK
     AND SVO_UID_PK = SSX_SO_UID_FK
     AND SSX_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
     AND BMH_END_DATE IS NULL
     AND IHT_SYSTEM_CODE IN ('ADD ACCT WEB','ADD ACCT HES')
     AND IHT_UID_PK = BMH_INV_HIST_TYPES_UID_FK
 UNION
 SELECT 'Y'
    FROM MTA_BOXES, BOX_MODEM_HISTORY, INVENTORY_HISTORY_TYPES, SERVICES, SERV_SERV_LOCATIONS
   WHERE MTA_UID_PK = BMH_MTA_BOXES_UID_FK
     AND SVC_UID_PK = BMH_SERVICES_UID_FK
     AND SVC_UID_PK = SSL_SERVICES_UID_FK
     AND SSL_SERVICE_LOCATIONS_UID_FK = P_SLO_UID_PK
     AND BMH_END_DATE IS NULL
     AND IHT_SYSTEM_CODE IN ('ADD ACCT WEB','ADD ACCT HES')
     AND IHT_UID_PK = BMH_INV_HIST_TYPES_UID_FK;

CURSOR GET_EMPLOYEE IS
 SELECT EMP_FNAME||' '||EMP_LNAME
   FROM EMPLOYEES
  WHERE EMP_UID_PK = P_EMP_UID_PK;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
         CUS_BUSINESS_OFFICES_UID_FK, SVC_UID_PK, OST_SERVICE_TYPES_UID_FK, STY_SYSTEM_CODE
  FROM CUSTOMERS, ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SO
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK
 UNION  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
         CUS_BUSINESS_OFFICES_UID_FK, SVC_UID_PK, OST_SERVICE_TYPES_UID_FK, STY_SYSTEM_CODE
  FROM CUSTOMERS, ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES
  WHERE CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND SVC_UID_PK = P_SVC_UID_PK;

CURSOR GET_SLO IS
  SELECT SSX_SERVICE_LOCATIONS_UID_FK
    FROM SERV_SERV_LOC_SO
   WHERE SSX_SO_UID_FK = P_SVO_UID_PK
     AND SSX_END_DATE IS NULL
UNION
  SELECT SSL_SERVICE_LOCATIONS_UID_FK
    FROM SERV_SERV_LOCATIONS
   WHERE SSL_SERVICES_UID_FK = P_SVC_UID_PK
     AND SSL_END_DATE IS NULL;

CURSOR MTA_ACTIVE_ACCOUNT_CHECK(P_MTA_UID_PK IN NUMBER, P_SLO_UID_PK IN NUMBER) IS
SELECT 'X'
  FROM SERVICES, SERV_SERV_LOCATIONS, SERVICE_ASSGNMTS, MTA_SERVICES, MTA_PORTS, MTA_EQUIP_UNITS
 WHERE MEU_UID_PK = MTP_MTA_EQUIP_UNITS_UID_FK
   AND MTP_UID_PK = MSS_MTA_PORTS_UID_FK
   AND SVA_UID_PK = MSS_SERVICE_ASSGNMTS_UID_FK
   AND SVC_UID_PK = SVA_SERVICES_UID_FK
   AND SVC_UID_PK = SSL_SERVICES_UID_FK
   AND SSL_SERVICE_LOCATIONS_UID_FK != P_SLO_UID_PK
   AND SSL_END_DATE IS NULL
   AND SVC_END_DATE IS NULL
   AND MEU_MTA_BOXES_UID_FK = P_MTA_UID_PK
   AND MEU_REMOVE_MTA_FL = 'N';

CURSOR GET_ONU(P_SLO_UID_PK IN NUMBER) IS
  SELECT ONU_UID_PK
    FROM out_net_units, onu_types
   WHERE onu_service_locations_uid_fk in
                   (select s2.slo_uid_pk
                   from service_locations s1, service_locations s2
                  where s1.slo_uid_pk = P_SLO_UID_PK
                    and s1.slo_municipalities_uid_fk = s2.slo_municipalities_uid_fk
                    and s1.slo_streets_uid_fk = s2.slo_streets_uid_fk
                    and ((s1.slo_street_nums_uid_fk = s2.slo_street_nums_uid_fk and s1.slo_street_nums_uid_fk is not null)
                     or (s2.slo_street_nums_uid_fk is null and s1.slo_street_nums_uid_fk is null))
                    and ((s1.slo_buildings_uid_fk = s2.slo_buildings_uid_fk and s1.slo_buildings_uid_fk is not null)
                     or (s2.slo_buildings_uid_fk is null and s1.slo_buildings_uid_fk is null))
                    and ((s1.slo_building_units_uid_fk = s2.slo_building_units_uid_fk and s1.slo_building_units_uid_fk is not null)
                     or (s2.slo_building_units_uid_fk is null and s1.slo_building_units_uid_fk is null)))
     and onu_onu_types_uid_fk = otp_uid_pk
     and otp_system_code in ('MTA','EMTA');

CURSOR CHECK_SO IS
  SELECT 'X'
    FROM SO
   WHERE SVO_UID_PK = P_SVO_UID_PK;

V_DUMMY                VARCHAR2(1);
V_SLO_UID_PK           NUMBER;
V_SVO_UID_PK           NUMBER;
V_MTO_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_BSO_UID_PK           NUMBER;
V_IVL_UID_PK           NUMBER;
V_OSB_UID_PK           NUMBER;
V_OST_UID_PK           NUMBER;
V_OSF_UID_PK           NUMBER;
V_STY_UID_PK           NUMBER;
V_ONU_UID_PK           NUMBER;
V_STY_SYSTEM_CODE      VARCHAR2(20);
V_SVT_CODE             VARCHAR2(40);
V_MTA_FOUND_FL         VARCHAR2(1);
V_IDENTIFIER           VARCHAR2(300);
V_DESCRIPTION          VARCHAR2(300);
V_EMP_NAME             VARCHAR2(300);
V_EQUIP_TYPE           VARCHAR2(20);
V_MTA_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_LAST_IVL_UID_PK      NUMBER;
V_LAST_IVL_DESCRIPTION VARCHAR2(200);
V_ACCOUNT              VARCHAR2(200);
V_DATE                 DATE;
V_ACTION_FL            VARCHAR2(1);
V_COUNTER              NUMBER := 0;
V_MAC_MESSAGE          VARCHAR2(2000);
V_NEW_MTA_MAC          VARCHAR2(20);
V_OLD_CBM_MAC_ADDRESS  VARCHAR2(20);
V_SO_FL                VARCHAR2(1);

v_return_msg  					VARCHAR2(4000);

V_SEL_PROCEDURE_NAME	  VARCHAR2(40):= 'FN_ADD_RFOG';

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_BSO_UID_PK, V_SVC_UID_PK, V_STY_UID_PK, V_STY_SYSTEM_CODE;
CLOSE GET_IDENTIFIER;

--GET SLO PK
OPEN GET_SLO;
FETCH GET_SLO INTO V_SLO_UID_PK;
CLOSE GET_SLO;

OPEN CHECK_SO;
FETCH CHECK_SO INTO V_DUMMY;
IF CHECK_SO%FOUND THEN
   V_SO_FL := 'Y';
   V_SVO_UID_PK := P_SVO_UID_PK;
ELSE
   V_SO_FL := 'N';
   V_SVO_UID_PK := NULL;
END IF;
CLOSE CHECK_SO;

--DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MTA_MAC, V_MTA_UID_PK);

OPEN MTA_ALREADY_ON(V_MTA_UID_PK, V_SLO_UID_PK);
FETCH MTA_ALREADY_ON INTO V_MTA_FOUND_FL;
IF MTA_ALREADY_ON%FOUND THEN
   V_MTA_FOUND_FL := 'Y';
ELSE
   V_MTA_FOUND_FL := 'N';
END IF;
CLOSE MTA_ALREADY_ON;

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'SERIAL# NOT FOUND.  PLEASE MAKE SURE YOU SCANNED THE MTA OR CMAC MAC ADDRESS';
   v_return_msg:= 'SERIAL# NOT FOUND.  PLEASE MAKE SURE YOU SCANNED THE MTA OR CMAC MAC ADDRESS';
	 IF p_svo_uid_pk IS NOT NULL THEN
	 	  IF v_return_msg IS NOT NULL THEN
	 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	  END IF;
	 END IF; 
ELSIF V_EQUIP_TYPE  = 'S' THEN
   RETURN 'YOU CANNOT SCAN A CABLE BOX IN THE MTA SECTION.';
   v_return_msg:= 'YOU CANNOT SCAN A CABLE BOX IN THE MTA SECTION.';
	 IF p_svo_uid_pk IS NOT NULL THEN
	 	 	IF v_return_msg IS NOT NULL THEN
	 	 		 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	 	END IF;
	 END IF;  
ELSIF V_EQUIP_TYPE  = 'M' THEN
   RETURN 'YOU CANNOT SCAN A CABLE MODEM IN THE MTA SECTION.';
   v_return_msg:= 'YOU CANNOT SCAN A CABLE MODEM IN THE MTA SECTION.';
	 IF p_svo_uid_pk IS NOT NULL THEN
	 	 	IF v_return_msg IS NOT NULL THEN
	 	 	 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	 	END IF;
	 END IF; 
ELSIF V_EQUIP_TYPE  = 'A' THEN
   RETURN 'YOU CANNOT SCAN AN ADSL MODEM IN THE MTA SECTION.';
   v_return_msg:= 'YOU CANNOT SCAN AN ADSL MODEM IN THE MTA SECTION.';
	 IF p_svo_uid_pk IS NOT NULL THEN
	 	 	IF v_return_msg IS NOT NULL THEN
	 	 	 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	 	END IF;
	 END IF; 
ELSIF V_EQUIP_TYPE  = 'V' THEN
   RETURN 'YOU CANNOT SCAN A VDSL MODEM IN THE MTA SECTION.';
   v_return_msg:= 'YOU CANNOT SCAN A VDSL MODEM IN THE MTA SECTION.';
	 IF p_svo_uid_pk IS NOT NULL THEN
	 	 	IF v_return_msg IS NOT NULL THEN
	 	 	 	 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	 	END IF;
	 END IF;
END IF;

BEGIN
   --EMTA MAC MUST BE 1 NUMBER GREATER THAN THE CM MAC.
   IF NOT BOX_MODEM_PKG.FN_VALID_CMAC(P_MTA_MAC, P_CMAC_MAC) THEN
      RETURN 'THE MTA MAC MUST BE 1 NUMBER HIGHER THAN THE CM MAC';
      v_return_msg:= 'THE MTA MAC MUST BE 1 NUMBER HIGHER THAN THE CM MAC';
			IF p_svo_uid_pk IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
				 	 	PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
	 		END IF;
   END IF;

EXCEPTION  --to catch to_number possible issues
    when others then
      RETURN 'INVALID MAC ADDRESS ENTERED';
      v_return_msg:= 'INVALID MAC ADDRESS ENTERED';
			IF p_svo_uid_pk IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
				 	 	PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
	 		END IF;
END;

--SECTION ONE TO CHECK FOR VALIDATION ISSUES

IF V_IVL_UID_PK IS NULL THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_MTA_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
   RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
   v_return_msg:= 'THIS TECH IS NOT SET UP ON A TRUCK';
	 IF p_svo_uid_pk IS NOT NULL THEN
	 		IF v_return_msg IS NOT NULL THEN
	 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 		END IF;
	 END IF;
END IF;

IF V_MTA_FOUND_FL = 'N' THEN --CONTINUE WITH CHECKS BELOW.

   --BOX STATUS CHECK
   V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_MTA_MAC, V_EQUIP_TYPE, V_DESCRIPTION);
   IF V_STATUS NOT IN ('AN','AU','RT') THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_MTA_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A MTA TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_DESCRIPTION);
      RETURN 'THIS MTA IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
      v_return_msg:= 'THIS MTA IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
			IF p_svo_uid_pk IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
				 		PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
	 		END IF;
   END IF;

   --LOCATION CHECK
   IF V_IVL_UID_PK IS NOT NULL THEN
      V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_MTA_MAC);
      OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
      FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
      CLOSE LAST_LOCATION;

      IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
         IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
            BOX_MODEM_PKG.PR_EXCEPTION(P_MTA_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A BOX/MODEM TO '||V_IDENTIFIER||' '||P_MTA_MAC||' IS NOT FOUND ON THE TECHS TRUCK');
            RETURN 'THIS MTA IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
         		v_return_msg:= 'THIS MTA IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
						IF p_svo_uid_pk IS NOT NULL THEN
							 IF v_return_msg IS NOT NULL THEN
									PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
							 END IF;
	 					END IF;
         END IF;
      END IF;
   END IF;

   OPEN MTA_ACTIVE_ACCOUNT_CHECK(V_MTA_UID_PK, V_SLO_UID_PK);
   FETCH MTA_ACTIVE_ACCOUNT_CHECK INTO V_DUMMY;
   IF MTA_ACTIVE_ACCOUNT_CHECK%FOUND THEN
      RETURN 'THE EMTA MAC IS FOUND ON AN ACTIVE ACCOUNT';
      v_return_msg:= 'THE EMTA MAC IS FOUND ON AN ACTIVE ACCOUNT';
			IF p_svo_uid_pk IS NOT NULL THEN
				 IF v_return_msg IS NOT NULL THEN
						PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
				 END IF;
	 		END IF;
   END IF;
   CLOSE MTA_ACTIVE_ACCOUNT_CHECK;

END IF;

----------------------------------------------------------------------

OPEN GET_ONU(V_SLO_UID_PK);
FETCH GET_ONU INTO V_ONU_UID_PK;
IF GET_ONU%FOUND THEN
   UPDATE OUT_NET_UNITS
      SET ONU_MAC_ADDRESS = P_CMAC_MAC
    WHERE ONU_UID_PK = V_ONU_UID_PK;
END IF;
CLOSE GET_ONU;

COMMIT;

IF V_LAST_IVL_DESCRIPTION = 'LOCATION NOT FOUND' THEN --ALSO ADD A RECORD TO ISSUE AN AUTO RECEIVE IN, INTO THE TECH TRUCK LOCATION
   BOX_MODEM_PKG.PR_RECEIVE_STB_INTO_INV(P_MTA_MAC, V_IVL_UID_PK, NULL, NULL);
END IF;

IF V_SO_FL = 'Y' THEN
   INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
   	                VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', TRUNC(SYSDATE), SYSDATE, 'The MTA box '||P_MTA_MAC||'/'||P_CMAC_MAC||' was added by technician '||V_EMP_NAME);
   IF V_STY_SYSTEM_CODE = 'PHN' THEN
      INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
   	                   VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', TRUNC(SYSDATE), SYSDATE, 'Please change alopa to include the voice package with MTA MAC, and call CO to provision ossgate.');
   ELSIF V_STY_SYSTEM_CODE = 'BBS' THEN
      INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
   	                   VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', TRUNC(SYSDATE), SYSDATE, 'Please re-submit the order for alopa provisioning.');
   END IF;
END IF;
----------------------------------------------------------------------

BOX_MODEM_PKG.PR_ADD_ACCT(P_MTA_MAC, V_IDENTIFIER, P_SVC_UID_PK, V_SVO_UID_PK, 'ADD ACCT WEB');

COMMIT;
----------------------------------------------------------------------

RETURN 'MTA ADDED TO THE ACCOUNT FOR INVENTORY PURPOSES.  PLEASE CALL PLANT TO TAKE STEPS TO MANUALLY PROVISION THE MTA.';
v_return_msg:= 'MTA ADDED TO THE ACCOUNT FOR INVENTORY PURPOSES.  PLEASE CALL PLANT TO TAKE STEPS TO MANUALLY PROVISION THE MTA.';
IF p_svo_uid_pk IS NOT NULL THEN
	 IF v_return_msg IS NOT NULL THEN
			PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 END IF;
END IF;

----------------------------------------------------------------------
END FN_ADD_RFOG;

FUNCTION FN_REMOVE_RFOG(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MTA_MAC IN VARCHAR, P_CMAC_MAC IN VARCHAR)

RETURN VARCHAR

IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK)
  FROM CUSTOMERS, ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES, SO
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK
 UNION  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK)
  FROM CUSTOMERS, ACCOUNTS, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES
  WHERE CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
    AND SVC_UID_PK = P_SVC_UID_PK;

CURSOR GET_ONU(P_SLO_UID_PK IN NUMBER) IS
  SELECT ONU_UID_PK
    FROM out_net_units, onu_types
   WHERE onu_service_locations_uid_fk in
                   (select s2.slo_uid_pk
                   from service_locations s1, service_locations s2
                  where s1.slo_uid_pk = P_SLO_UID_PK
                    and s1.slo_municipalities_uid_fk = s2.slo_municipalities_uid_fk
                    and s1.slo_streets_uid_fk = s2.slo_streets_uid_fk
                    and ((s1.slo_street_nums_uid_fk = s2.slo_street_nums_uid_fk and s1.slo_street_nums_uid_fk is not null)
                     or (s2.slo_street_nums_uid_fk is null and s1.slo_street_nums_uid_fk is null))
                    and ((s1.slo_buildings_uid_fk = s2.slo_buildings_uid_fk and s1.slo_buildings_uid_fk is not null)
                     or (s2.slo_buildings_uid_fk is null and s1.slo_buildings_uid_fk is null))
                    and ((s1.slo_building_units_uid_fk = s2.slo_building_units_uid_fk and s1.slo_building_units_uid_fk is not null)
                     or (s2.slo_building_units_uid_fk is null and s1.slo_building_units_uid_fk is null)))
     and onu_onu_types_uid_fk = otp_uid_pk
     and otp_system_code in ('MTA','EMTA');

CURSOR CHECK_SO IS
  SELECT 'X'
    FROM SO
   WHERE SVO_UID_PK = P_SVO_UID_PK;

V_IVL_UID_PK           NUMBER;
V_SVO_UID_PK           NUMBER;
V_CUS_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_STY_UID_PK           NUMBER;
V_BSO_UID_PK           NUMBER;
V_OSF_UID_PK           NUMBER;
V_SLO_UID_PK           NUMBER;
V_RETURN_MESSAGE       VARCHAR2(2000);
V_EQUIP_TYPE           VARCHAR2(1);
V_MTA_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_IDENTIFIER           VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);
V_SOT_CODE             VARCHAR2(20);
V_STY_SYSTEM_CODE      VARCHAR2(20);
V_SVT_SYSTEM_CODE      VARCHAR2(20);
V_SVT_SYSTEM_CODE2     VARCHAR2(20);
V_DEPROV_FL            VARCHAR2(1) := 'N';
V_SO_FL                VARCHAR2(1);

v_return_msg  				 VARCHAR2(4000);

V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_REMOVE_RFOG';

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER;
CLOSE GET_IDENTIFIER;

OPEN CHECK_SO;
FETCH CHECK_SO INTO V_DUMMY;
IF CHECK_SO%FOUND THEN
   V_SO_FL := 'Y';
   V_SVO_UID_PK := P_SVO_UID_PK;
ELSE
   V_SO_FL := 'N';
   V_SVO_UID_PK := NULL;
END IF;
CLOSE CHECK_SO;

--DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MTA_MAC, V_MTA_UID_PK);

IF V_IVL_UID_PK IS NULL THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_MTA_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
   RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
   v_return_msg:= 'THIS TECH IS NOT SET UP ON A TRUCK';
	 IF p_svo_uid_pk IS NOT NULL THEN
	 	 IF v_return_msg IS NOT NULL THEN
	 			PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	 END IF;
	 END IF;
END IF;

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
   v_return_msg:= 'MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
	 IF p_svo_uid_pk IS NOT NULL THEN
	 	 	IF v_return_msg IS NOT NULL THEN
	 	 		 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	 	END IF;
	 END IF;
   
END IF;

--THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

IF V_EQUIP_TYPE = 'E' THEN
   UPDATE OUT_NET_UNITS
      SET ONU_MAC_ADDRESS = NULL
    WHERE ONU_MAC_ADDRESS = P_CMAC_MAC;

   IF V_SO_FL = 'Y' THEN
      INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
   	                   VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE MTA '||P_MTA_MAC||' WAS REMOVED BY TECHNICIAN '||V_EMP_NAME);
   END IF;
END IF;

V_STATUS := 'REMOVE INSTALLATION';

BOX_MODEM_PKG.PR_REMOVE_ACCT(P_MTA_MAC, V_IDENTIFIER, P_SVC_UID_PK, V_SVO_UID_PK, V_STATUS, V_IVL_UID_PK);
COMMIT;

RETURN 'MTA SUCESSFULLY REMOVED FROM THE ACCOUNT.  PLEASE CALL PLANT TO DEPROVISION THE MTA';
v_return_msg:= 'MTA SUCESSFULLY REMOVED FROM THE ACCOUNT.  PLEASE CALL PLANT TO DEPROVISION THE MTA';
IF p_svo_uid_pk IS NOT NULL THEN
	 IF v_return_msg IS NOT NULL THEN
	 	 	PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 END IF;
END IF;

END FN_REMOVE_RFOG;

PROCEDURE PR_ADD_SO_WIRING(P_SO_UID_PK IN NUMBER, P_CATV_BOX_PK IN NUMBER, P_CABLE_TYPE_PK IN NUMBER, P_NETWORK_TYPE_PK IN NUMBER, P_PHYSICAL_LOCATION IN VARCHAR) IS

CURSOR SO_FOR_ASSIGNMENT(P_SO_ASSIGN_PK IN NUMBER) IS
  SELECT SON_SO_UID_FK
    FROM SO_ASSGNMTS
   WHERE SON_UID_PK = P_SO_ASSIGN_PK;

CURSOR FLAG_ALREADY_SET(P_SO_UID_PK IN NUMBER, P_CATV_BOX_PK IN NUMBER) IS
  SELECT SOW_UID_PK
    FROM SO_WIRING, SO_ASSGNMTS
   WHERE SON_SO_UID_FK = P_SO_UID_PK
    AND SON_UID_PK = SOW_SO_ASSGNMTS_UID_FK
    AND SOW_CATV_CONV_BOXES_UID_FK = P_CATV_BOX_PK;

V_FLAG_ALREADY_SET    VARCHAR2(1);
V_SO_WIRING_PK        NUMBER(38);
V_SO_UID_PK           NUMBER(38);

BEGIN
    OPEN SO_FOR_ASSIGNMENT(P_SO_UID_PK);
    FETCH SO_FOR_ASSIGNMENT INTO V_SO_UID_PK;
    IF SO_FOR_ASSIGNMENT%FOUND THEN
        OPEN FLAG_ALREADY_SET(V_SO_UID_PK, P_CATV_BOX_PK);
        FETCH FLAG_ALREADY_SET INTO V_SO_WIRING_PK;
        IF FLAG_ALREADY_SET%FOUND THEN
            V_FLAG_ALREADY_SET := 'Y';
        ELSE
            V_FLAG_ALREADY_SET := 'N';
        END IF;
        CLOSE FLAG_ALREADY_SET;
    ELSE
        V_FLAG_ALREADY_SET := 'N';
    END IF;
    CLOSE SO_FOR_ASSIGNMENT;

    if V_FLAG_ALREADY_SET = 'Y' then
        UPDATE SO_WIRING
            set SOW_WIRING_CABLES_UID_FK = P_CABLE_TYPE_PK,
                SOW_SO_ASSGNMTS_UID_FK = P_SO_UID_PK,
                SOW_WIRING_NETWORKS_UID_FK = P_NETWORK_TYPE_PK,
                SOW_PHYSICAL_LOCATIONS = P_PHYSICAL_LOCATION
            where SOW_UID_PK = V_SO_WIRING_PK;
    else
        INSERT INTO SO_WIRING(SOW_UID_PK, SOW_CATV_CONV_BOXES_UID_FK, SOW_SO_ASSGNMTS_UID_FK, SOW_WIRING_CABLES_UID_FK, SOW_WIRING_NETWORKS_UID_FK, SOW_PHYSICAL_LOCATIONS)
                       VALUES(SOW_SEQ.NEXTVAL, P_CATV_BOX_PK, P_SO_UID_PK, P_CABLE_TYPE_PK, P_NETWORK_TYPE_PK, P_PHYSICAL_LOCATION);
    end if;

    commit;
END PR_ADD_SO_WIRING;


PROCEDURE PR_ADD_SERVICE_WIRING(P_SVC_UID_PK IN NUMBER, P_CATV_BOX_PK IN NUMBER, P_CABLE_TYPE_PK IN NUMBER, P_NETWORK_TYPE_PK IN NUMBER, P_PHYSICAL_LOCATION IN VARCHAR) IS

CURSOR SVC_FOR_ASSIGNMENT(P_SVC_ASSIGN_PK IN NUMBER) IS
  SELECT SVA_SERVICES_UID_FK
    FROM SERVICE_ASSGNMTS
   WHERE SVA_UID_PK = P_SVC_ASSIGN_PK;

CURSOR FLAG_ALREADY_SET(P_SVC_UID_PK IN NUMBER, P_CATV_BOX_PK IN NUMBER) IS
  SELECT SRW_UID_PK
    FROM SERVICE_WIRING, SERVICE_ASSGNMTS
   WHERE SVA_SERVICES_UID_FK = P_SVC_UID_PK
    AND SVA_UID_PK = SRW_SERVICE_ASSGNMTS_UID_FK
    AND SRW_CATV_CONV_BOXES_UID_FK = P_CATV_BOX_PK;

V_FLAG_ALREADY_SET    VARCHAR2(1);
V_SVC_WIRING_PK        NUMBER(38);
V_SVC_UID_PK           NUMBER(38);

BEGIN
    OPEN SVC_FOR_ASSIGNMENT(P_SVC_UID_PK);
    FETCH SVC_FOR_ASSIGNMENT INTO V_SVC_UID_PK;
    IF SVC_FOR_ASSIGNMENT%FOUND THEN
        OPEN FLAG_ALREADY_SET(V_SVC_UID_PK, P_CATV_BOX_PK);
        FETCH FLAG_ALREADY_SET INTO V_SVC_WIRING_PK;
        IF FLAG_ALREADY_SET%FOUND THEN
            V_FLAG_ALREADY_SET := 'Y';
        ELSE
            V_FLAG_ALREADY_SET := 'N';
        END IF;
        CLOSE FLAG_ALREADY_SET;
    ELSE
        V_FLAG_ALREADY_SET := 'N';
    END IF;
    CLOSE SVC_FOR_ASSIGNMENT;

    if V_FLAG_ALREADY_SET = 'Y' then
        UPDATE SERVICE_WIRING
            set SRW_WIRING_CABLES_UID_FK = P_CABLE_TYPE_PK,
                SRW_SERVICE_ASSGNMTS_UID_FK = P_SVC_UID_PK,
                SRW_WIRING_NETWORKS_UID_FK = P_NETWORK_TYPE_PK,
                SRW_PHYSICAL_LOCATION = P_PHYSICAL_LOCATION
            where SRW_UID_PK = V_SVC_WIRING_PK;
    else
        INSERT INTO SERVICE_WIRING(SRW_UID_PK, SRW_CATV_CONV_BOXES_UID_FK, SRW_SERVICE_ASSGNMTS_UID_FK, SRW_WIRING_CABLES_UID_FK, SRW_WIRING_NETWORKS_UID_FK, SRW_PHYSICAL_LOCATION)
                       VALUES(SRW_SEQ.NEXTVAL, P_CATV_BOX_PK, P_SVC_UID_PK, P_CABLE_TYPE_PK, P_NETWORK_TYPE_PK, P_PHYSICAL_LOCATION);
    end if;

    commit;
END PR_ADD_SERVICE_WIRING;

PROCEDURE PR_HAS_WIRING_DATA(P_CATV_BOX_PK IN NUMBER, P_JOB_TYPE IN VARCHAR, P_SVC_UID_PK IN NUMBER, P_HAS_DATA_FL OUT VARCHAR, P_WIRING_PK OUT NUMBER) IS

CURSOR SO_FLAG_ALREADY_SET(P_BOX_PK IN NUMBER) IS
  SELECT SOW_UID_PK
    FROM SO_WIRING, SO_ASSGNMTS, SO, SO_STATUS
    WHERE SOW_CATV_CONV_BOXES_UID_FK = P_CATV_BOX_PK
      AND SON_UID_PK = SOW_SO_ASSGNMTS_UID_FK
      AND SVO_UID_PK = SON_SO_UID_FK
      AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
      AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED')
      AND SVO_SERVICES_UID_FK = P_SVC_UID_PK
 UNION
  SELECT SRW_UID_PK
    FROM SERVICE_WIRING, SERVICE_ASSGNMTS
    WHERE SRW_CATV_CONV_BOXES_UID_FK = P_CATV_BOX_PK
      AND SVA_UID_PK = SRW_SERVICE_ASSGNMTS_UID_FK
      AND SVA_SERVICES_UID_FK = P_SVC_UID_PK;

CURSOR SERVICE_FLAG_ALREADY_SET(P_BOX_PK IN NUMBER) IS
  SELECT SRW_UID_PK
    FROM SERVICE_WIRING, SERVICE_ASSGNMTS
    WHERE SRW_CATV_CONV_BOXES_UID_FK = P_CATV_BOX_PK
      AND SVA_UID_PK = SRW_SERVICE_ASSGNMTS_UID_FK
      AND SVA_SERVICES_UID_FK = P_SVC_UID_PK;

V_FLAG_ALREADY_SET    VARCHAR2(1);
V_WIRING_PK        NUMBER(38) := NULL;

BEGIN

    if P_JOB_TYPE = 'S' then
        OPEN SO_FLAG_ALREADY_SET(P_CATV_BOX_PK);
        FETCH SO_FLAG_ALREADY_SET INTO V_WIRING_PK;
        IF SO_FLAG_ALREADY_SET%FOUND THEN
            V_FLAG_ALREADY_SET := 'Y';
        ELSE
            V_FLAG_ALREADY_SET := 'N';
        END IF;
        CLOSE SO_FLAG_ALREADY_SET;
    else
        OPEN SERVICE_FLAG_ALREADY_SET(P_CATV_BOX_PK);
        FETCH SERVICE_FLAG_ALREADY_SET INTO V_WIRING_PK;
        IF SERVICE_FLAG_ALREADY_SET%FOUND THEN
            V_FLAG_ALREADY_SET := 'Y';
        ELSE
            V_FLAG_ALREADY_SET := 'N';
        END IF;
        CLOSE SERVICE_FLAG_ALREADY_SET;
    end if;

    P_HAS_DATA_FL := V_FLAG_ALREADY_SET;
    P_WIRING_PK := V_WIRING_PK;

END PR_HAS_WIRING_DATA;


FUNCTION FN_WIRING_CABLES_LIST
RETURN generic_data_table PIPELINED IS

CURSOR CODES IS
SELECT WCA_UID_PK, WCA_DESCRIPTION DESCRIPTION, WCA_CODE
 FROM WIRING_CABLES
 WHERE WCA_ACTIVE_FL = 'Y'
 ORDER BY WCA_CODE;

rec     CODES%rowtype;
v_rec   generic_data_type;

BEGIN

 OPEN CODES;
 LOOP
    FETCH CODES into rec;
    EXIT WHEN CODES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1    := rec.description;   -- description
     v_rec.gdt_number1   := rec.wca_uid_pk;    -- pk


     PIPE ROW (v_rec);
  END LOOP;

  CLOSE CODES;

RETURN;

END FN_WIRING_CABLES_LIST;


FUNCTION FN_WIRING_NETWORKS_LIST
RETURN generic_data_table PIPELINED IS

CURSOR CODES IS
SELECT WNT_UID_PK, WNT_DESCRIPTION DESCRIPTION, WNT_CODE
 FROM WIRING_NETWORKS
 WHERE WNT_ACTIVE_FL = 'Y'
 ORDER BY WNT_CODE;

rec     CODES%rowtype;
v_rec   generic_data_type;

BEGIN

 OPEN CODES;
 LOOP
    FETCH CODES into rec;
    EXIT WHEN CODES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1    := rec.description;   -- description
     v_rec.gdt_number1   := rec.wnt_uid_pk;    -- pk


     PIPE ROW (v_rec);
  END LOOP;

  CLOSE CODES;

RETURN;

END FN_WIRING_NETWORKS_LIST;

FUNCTION FN_MTA_TYPE(P_SLO_UID_PK IN NUMBER)
RETURN VARCHAR

IS

 CURSOR SLO_EMTA (P_SLO_UID_PK IN NUMBER) IS
   SELECT DECODE(MEU_PAS_OPT_NETWORKS_UID_FK,NULL,'PACKET CABLE','RFOG')
     FROM MTA_EQUIP_UNITS
    WHERE MEU_SERVICE_LOCATIONS_UID_FK in
                   (select s2.slo_uid_pk
                   from service_locations s1, service_locations s2
                  where s1.slo_uid_pk = P_SLO_UID_PK
                    and s1.slo_municipalities_uid_fk = s2.slo_municipalities_uid_fk
                    and s1.slo_streets_uid_fk = s2.slo_streets_uid_fk
                    and ((s1.slo_street_nums_uid_fk = s2.slo_street_nums_uid_fk and s1.slo_street_nums_uid_fk is not null)
                     or (s2.slo_street_nums_uid_fk is null and s1.slo_street_nums_uid_fk is null))
                    and ((s1.slo_buildings_uid_fk = s2.slo_buildings_uid_fk and s1.slo_buildings_uid_fk is not null)
                     or (s2.slo_buildings_uid_fk is null and s1.slo_buildings_uid_fk is null))
                    and ((s1.slo_building_units_uid_fk = s2.slo_building_units_uid_fk and s1.slo_building_units_uid_fk is not null)
                     or (s2.slo_building_units_uid_fk is null and s1.slo_building_units_uid_fk is null)))
   ORDER BY 1 DESC;

V_TYPE   VARCHAR2(20);

BEGIN

  OPEN SLO_EMTA(p_slo_uid_pk);
  FETCH SLO_EMTA INTO V_TYPE;
  IF SLO_EMTA%NOTFOUND THEN
     V_TYPE := 'NON MTA LOCATION';
  END IF;
  CLOSE SLO_EMTA;
  
RETURN V_TYPE;

END FN_MTA_TYPE;

FUNCTION FN_CHECK_USERNAME_NOT_EXISTS(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN BOOLEAN

IS

  CURSOR get_svo_child is
    select svo_Services_uid_fk
      from so
     where svo_master_so_uid_fk = P_SVO_UID_PK;
     
  CURSOR c_get_so_usernames IS
   SELECT ISS_USER_NAME,
          ISS_PASSWORD,
          ISS_TRAINING_FL
     FROM INTERNET_SO
   WHERE ISS_SO_UID_FK = P_SVO_UID_PK;

V_SVC_CHILD   NUMBER;

BEGIN

  OPEN get_svo_child;
  FETCH get_svo_child INTO V_SVC_CHILD;
  IF get_svo_child%NOTFOUND THEN
     V_SVC_CHILD := NULL;
  END IF;
  CLOSE get_svo_child;
  
  /*FOR REC IN c_get_so_usernames LOOP
     IF isp_so_data_pkg.check_if_user_name_exist_fun(NVL(v_svc_child,P_SVC_UID_PK),REC.ISS_USER_NAME) then
        RETURN FALSE;
     END IF;
  END LOOP;*/
  
RETURN TRUE;

END FN_CHECK_USERNAME_NOT_EXISTS;

FUNCTION FN_CHECK_VALID_CMTS(P_SLO_UID_PK IN NUMBER)
RETURN VARCHAR

IS

CURSOR CMTS(P_CMTS IN VARCHAR) IS
  SELECT 'X'
    FROM CBL_MDM_TRM_SYS
   WHERE CMT_CODE = P_CMTS;

V_CMTS    VARCHAR2(20);
V_DUMMY   VARCHAR2(1);

BEGIN

V_CMTS := SERV_LOCS.GET_SLO_CMTS_CODE(P_SLO_UID_PK);

OPEN CMTS(V_CMTS);
FETCH CMTS INTO V_DUMMY;
IF CMTS%NOTFOUND THEN
   CLOSE CMTS;
   RETURN 'THE PEP SERVER '||V_CMTS||' FOUND FOR THIS ORDER WILL NOT PROVISION CORRECTLY.  PLEASE CALL PLANT TO GET WITH FACILITIES ENGINNEERING.';
END IF;
CLOSE CMTS;

RETURN NULL;

END FN_CHECK_VALID_CMTS;

FUNCTION FN_MLH_CHECK(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR

IS

--THIS WAS CREATED TO TRY TO CAPTURE ALL MULTI-LINE-HUNT ORDERS TO MESSAGE THE TECHNICIAN THEY NEED TO CALL THE CO TO WORK THESE
--ORIGINALLY WE WANTED TO DRIVE OFF MLH FEATURE CODES, WE FELT LIKE WE COULD ALSO CAPTURE THESE BY JUST LOOKING AT THE
--NUMBER OF ASSIGNMENTS

CURSOR EMTA_CHECK IS
  SELECT 'X'
    FROM MTA_SO, SO_ASSGNMTS, SO, SERVICES, OFFICE_SERV_TYPES, SERVICE_TYPES
   WHERE SON_SO_UID_FK = P_SVO_UID_PK
     AND SON_UID_PK = MTO_SO_ASSGNMTS_UID_FK
     AND SVO_UID_PK = SON_SO_UID_FK
     AND SVC_UID_PK = SVO_SERVICES_UID_FK
     AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK
     AND STY_UID_PK = OST_SERVICE_TYPES_UID_FK
     AND STY_SYSTEM_CODE = 'PHN';
   
CURSOR ASSIGNMENTS_NUMBER IS
  SELECT COUNT(*)
    FROM SO_ASSGNMTS
   WHERE SON_SO_UID_FK = P_SVO_UID_PK;

V_CMTS            		 VARCHAR2(20);
V_DUMMY           		 VARCHAR2(1);
V_EMTA_TYPE       		 VARCHAR2(1);
V_CNT_ASSIGNMENTS 		 NUMBER;
V_STY_CODE        		 VARCHAR2(40);

v_return_msg  				 VARCHAR2(4000);

V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_MLH_CHECK';

BEGIN

   OPEN EMTA_CHECK;
   FETCH EMTA_CHECK INTO V_DUMMY;
   IF EMTA_CHECK%FOUND THEN
      OPEN ASSIGNMENTS_NUMBER;
      FETCH ASSIGNMENTS_NUMBER INTO V_CNT_ASSIGNMENTS;
      IF ASSIGNMENTS_NUMBER%FOUND THEN
         IF V_CNT_ASSIGNMENTS > 1 THEN  --MORE THAN ONE ASSIGNMENT SO ASSUME IT IS A MULTI LINE HUNT
            CLOSE ASSIGNMENTS_NUMBER;
            CLOSE EMTA_CHECK;
            RETURN 'THIS APPEARS TO BE A MULTI LINE HUNT ORDER.  IF SO PLEASE CALL THE CO TO WORK THE VOICE PORTION.  PLEASE CALL THE HELPDESK WITH ANY QUESTIONS.';
            v_return_msg:= 'THIS APPEARS TO BE A MULTI LINE HUNT ORDER.  IF SO PLEASE CALL THE CO TO WORK THE VOICE PORTION.  PLEASE CALL THE HELPDESK WITH ANY QUESTIONS.';
						IF p_svo_uid_pk IS NOT NULL THEN
							 IF v_return_msg IS NOT NULL THEN
							 	 	PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
							 END IF;
						END IF;
         END IF;
      END IF;
      CLOSE ASSIGNMENTS_NUMBER;
   END IF;
   CLOSE EMTA_CHECK;
   
RETURN NULL;

END FN_MLH_CHECK;

-- HD 106390 RMC 04/1/2011 - Query ALOPA if starting with PHONE (V_STY_CODE = 'PHN'). Compare the Scanned CMAC to the CMAC assigned to the user.
--                           IF the Scanned CMAC does not match the CMAC assigned to that user then the High Speed Service order
--                           has not been add/provisioned before the phone and return false.

FUNCTION FN_HSD_BEFORE_PHONE(P_USER_NAME IN VARCHAR2, P_CMAC_SCANNED IN VARCHAR2)
RETURN BOOLEAN

IS


V_SCANNED_CMAC    		VARCHAR2(20) := P_CMAC_SCANNED;
V_DUMMY           		VARCHAR2(1);
V_CNT_ASSIGNMENTS 		NUMBER;
V_STY_CODE        		VARCHAR2(40);
V_USER_NAME						VARCHAR2(40) := P_USER_NAME;
V_STATUS_OVERALL  		BOOLEAN;
V_STATUS_RADIUS   		BOOLEAN;
V_MESSAGE_RADIUS  		VARCHAR2(200);
V_STATUS_MAIL     		BOOLEAN;
V_MESSAGE_MAIL    		VARCHAR2(200);
V_STATUS_CM       		BOOLEAN;
V_MESSAGE_CM      		VARCHAR2(200);
V_CM_MAC          		VARCHAR2(40);
V_SPEED           		VARCHAR2(40);
V_ERROR_MESSAGE   		VARCHAR2(500);
V_STATUS_OVERALL_Y_N  VARCHAR2(1);
V_IS_CABLE_USER       BOOLEAN :=TRUE;


BEGIN

  HES.ISP_GET_USER_STATUS(V_USER_NAME,V_IS_CABLE_USER, V_STATUS_OVERALL, V_STATUS_RADIUS, V_MESSAGE_RADIUS, V_STATUS_MAIL,
	                         V_MESSAGE_MAIL, V_STATUS_CM, V_MESSAGE_CM, V_CM_MAC, V_SPEED, V_ERROR_MESSAGE);
	 
	 IF V_STATUS_OVERALL THEN
	    V_STATUS_OVERALL_Y_N := 'Y';
	 ELSE
	    V_STATUS_OVERALL_Y_N := 'N';
	 END IF;

	IF V_SCANNED_CMAC != V_CM_MAC THEN
	   RETURN FALSE;
   
  ELSE
     RETURN TRUE;
   
  END IF;

END FN_HSD_BEFORE_PHONE;


FUNCTION FN_CHECK_VALID_LTG(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR

IS

V_LTG    							 VARCHAR2(2000);

v_return_msg  				 VARCHAR2(4000);

V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_CHECK_VALID_LTG';



BEGIN

V_LTG := CUST_INFO_PKG.GET_LTG_FUN(P_SVO_UID_PK, 'Y', 'N');
IF V_LTG IS NULL THEN
   V_LTG := CUST_INFO_PKG.GET_LTG_FUN(P_SVO_UID_PK, 'N', 'Y');
END IF;
IF V_LTG IS NULL THEN
   RETURN 'NO LINE TREATMENT GROUP WAS FOUND FOR PROVISIONING.CONTACT PLANT. MAKE SURE ASSIGNMENTS ARE CORRECT AND ALSO CHECK FOR DUPLICATE TOLL BLOCK FEATURE CODES.';
   v_return_msg:= 'NO LINE TREATMENT GROUP WAS FOUND FOR PROVISIONING.CONTACT PLANT. MAKE SURE ASSIGNMENTS ARE CORRECT AND ALSO CHECK FOR DUPLICATE TOLL BLOCK FEATURE CODES.';
	 IF p_svo_uid_pk IS NOT NULL THEN
	 		IF v_return_msg IS NOT NULL THEN
	 			 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 		END IF;
	 END IF;

END IF;

RETURN NULL;

END FN_CHECK_VALID_LTG;

-- HD 120534 RMC 06/11/2012 -  New Function that will compare the CLLI/LEN assigned in the switch to the CLLI/LEN from 
--                             so_assignments. If they fail to match, then an alert message is passd back to IWP for the tech to see.
--                             Plant will need to correct the LEN in either the SO assignments or the Switch

FUNCTION FN_CHECK_LEN_ASSGMNTS_SWT(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR

IS

CURSOR GET_QDN_LEN (p_qdn_dirnum number) IS
  SELECT QDN_LEN_VAL
		 FROM QDN_CUST_INFO
	 WHERE QDN_DIR_NUM = p_qdn_dirnum
  ORDER BY created_date DESC;

V_DIRNUM		VARCHAR2(200);	

V_QDN_LEN		VARCHAR2(200);

V_LEN    		VARCHAR2(200);

V_QDN_CLLI	VARCHAR2(200);

V_CLLI			VARCHAR2(200);

v_return_msg  				 VARCHAR2(4000);

V_SEL_PROCEDURE_NAME	 VARCHAR2(40):= 'FN_CHECK_LEN_ASSGMNTS_SWT';


BEGIN

V_DIRNUM := CUST_INFO_PKG.GET_DIR_NUM_FUN(P_SVO_UID_PK);

OPEN GET_QDN_LEN (V_DIRNUM);
FETCH GET_QDN_LEN INTO V_QDN_LEN;
CLOSE GET_QDN_LEN;

V_QDN_CLLI := SUBSTR(V_QDN_LEN,1,4);

V_QDN_LEN := SUBSTR(V_QDN_LEN,7,10);

V_LEN := CUST_INFO_PKG.GET_LEN_FUN(P_SVO_UID_PK, 'SON');

V_LEN := SUBSTR(V_LEN,6,10);

V_CLLI := SUBSTR(V_LEN,1,4);

IF V_QDN_LEN != V_LEN THEN
 	 RETURN 'LEN ASSIGNED ON SERVICE ORDER DOES NOT MATCH THE LEN ASSIGNED IN SWITCH. CONTACT PLANT TO CORRECT. ONCE CORRECTED THEN TRY PROVISIONING AGAIN.';
	 v_return_msg:= 'LEN ASSIGNED ON SERVICE ORDER DOES NOT MATCH THE LEN ASSIGNED IN SWITCH. CONTACT PLANT TO CORRECT. ONCE CORRECTED THEN TRY PROVISIONING AGAIN.';
	 IF p_svo_uid_pk IS NOT NULL THEN
	 	  IF v_return_msg IS NOT NULL THEN
	 	 		 PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK, V_SEL_PROCEDURE_NAME, v_return_msg);
	 	  END IF;
	 END IF;

END IF;

RETURN NULL;

END FN_CHECK_LEN_ASSGMNTS_SWT;

FUNCTION FN_CHECK_VALID_SVC_LEN(P_SVC_UID_PK IN NUMBER)
RETURN VARCHAR

IS

V_LEN    VARCHAR2(2000);

BEGIN

V_LEN := CUST_INFO_PKG.GET_SVC_LEN_FUN(P_SVC_UID_PK);
IF V_LEN IS NULL THEN
   RETURN 'THE LEN IS MISSING FROM THE MOVE OUT ASSIGNMENTS. THIS ORDER WILL NOT PROVISION CORRECTLY. PLEASE CONTACT PLANT AND HAVE THEM CHECK THE MOVE OUT ASSIGNMENTS.';
END IF;

RETURN NULL;

END FN_CHECK_VALID_SVC_LEN;

FUNCTION FN_CHECK_STB_RECALL(P_SERIAL# IN VARCHAR, P_ACTION IN VARCHAR)
RETURN VARCHAR

IS

CURSOR GET_RECALL_FL IS
  SELECT CCB_RECALL_FL
  FROM CATV_CONV_BOXES
  WHERE CCB_SERIAL# = P_SERIAL#;
  
V_MSG		VARCHAR2(500) := NULL;
V_RECALL_FL	VARCHAR2(1)   := NULL;

BEGIN    
    
      OPEN GET_RECALL_FL;
      FETCH GET_RECALL_FL INTO V_RECALL_FL;
      CLOSE GET_RECALL_FL;
      
      IF V_RECALL_FL = 'Y' THEN
         IF P_ACTION = 'A' THEN  
            V_MSG := P_SERIAL# || ' CANNOT BE USED. IT IS MARKED AS A DEFECTIVE ENTONE BOX AND IS BEING RECALLED. PLEASE RETURN TO WAREHOUSE';
         ELSIF P_ACTION = 'S' THEN
            V_MSG := '. THIS BOX IS MARKED AS A DEFECTIVE ENTONE BOX AND IS BEING RECALLED. IT SHOULD BE RETURNED TO WAREHOUSE';            
         ELSIF P_ACTION = 'T' THEN
            V_MSG := 'THIS BOX IS MARKED AS A DEFECTIVE ENTONE BOX AND IS BEING RECALLED. IT CANNOT BE ADDED TO A TRUCK'; 
         ELSE
            V_MSG := 'REMOVED STB ' || P_SERIAL# || ' THIS BOX IS MARKED AS A DEFECTIVE ENTONE BOX AND IS BEING RECALLED. PLEASE RETURN TO WAREHOUSE';             
         END IF;            
      END IF;


RETURN V_MSG;

END FN_CHECK_STB_RECALL; 

  -- fn to return tech's cell number so he can be notified by SMS that provisioning jobs are done
  --   used in IWP
  FUNCTION GET_CELL_NBR(p_emp_uid_pk    in number) RETURN VARCHAR2 IS
    CURSOR CUR_PHN (p_emp_pk   number) is
      SELECT PHN_AREA_CODE || PHN_EXCHANGE || PHN_LINE  CELL_NBR
        FROM PHONES, 
             PHONE_TYPES
       WHERE PHN_EMPLOYEES_UID_FK  = p_emp_pk
         AND PHT_UID_PK            = PHN_PHONE_TYPES_UID_FK 
         AND PHT_CODE              = 'CELL';
    v_phone   varchar2(20);

  BEGIN
    OPEN  cur_phn(p_emp_uid_pk);
    FETCH cur_phn INTO v_phone;
    CLOSE cur_phn;
    return (v_phone);
  END GET_CELL_NBR ;


  -- AC  10/10/11  for two pair non-twist project
  PROCEDURE SET_INSIDE_WIR_TYPE (p_so_tt_fl   in varchar2,   -- SO or TT
                                 p_svo_trt_pk  in number,    -- SO or TT PK to set
                                 p_iwt_uid_pk  in number) IS -- inside_wir_type to set
  BEGIN
    IF p_so_tt_fl = 'SO' THEN
      UPDATE BROADBAND_SO
         SET bbo_inside_wir_types_uid_fk = p_iwt_uid_pk 
       WHERE bbo_so_uid_fk               = p_svo_trt_pk;
      COMMIT;

    ELSIF p_so_tt_fl = 'TT' THEN
      UPDATE TROUBLE_TICKETS
         SET trt_inside_wir_types_uid_fk = p_iwt_uid_pk 
       WHERE trt_uid_pk                  = p_svo_trt_pk;
      COMMIT;
    else
      raise_application_error (-20000, 'p_so_tt_fl must be SO or TT'); 

    END IF;

  END  SET_INSIDE_WIR_TYPE;
  
  -- fn return the removal reason for a RS order to be displayed in IWP
  
FUNCTION FN_GET_REMOVAL_REASON(p_svo_uid_pk in number) RETURN VARCHAR2 IS
  
 CURSOR CUR_GET_REASON is
   SELECT RMV_DESCRIPTION
     FROM REMOVAL_REASONS, SO
    WHERE RMV_UID_PK = SVO_REMOVAL_REASONS_UID_FK
      AND SVO_UID_PK = P_SVO_UID_PK;
         
 v_removal_reason   varchar2(200);

BEGIN

 OPEN CUR_GET_REASON;
 FETCH CUR_GET_REASON INTO v_removal_reason;
 IF CUR_GET_REASON%NOTFOUND THEN
    v_removal_reason := NULL;
 END IF;
 CLOSE CUR_GET_REASON;
 
 return v_removal_reason;
    
END FN_GET_REMOVAL_REASON;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_ADD_ROUTER(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, 
                                          P_MAC IN VARCHAR, P_BILL_FL VARCHAR2 , P_TDP_UID_PK NUMBER)
RETURN VARCHAR IS

    CURSOR GET_TECH_LOCATION IS
     SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
       FROM TECH_EMP_LOCATIONS, EMPLOYEES
      WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
        AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
        AND TEO_END_DATE IS NULL;

    CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
      SELECT IVL_UID_PK
        FROM INVENTORY_LOCATIONS
       WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

    CURSOR GET_EMPLOYEE IS
     SELECT EMP_FNAME||' '||EMP_LNAME
       FROM EMPLOYEES
      WHERE EMP_UID_PK = P_EMP_UID_PK;

    CURSOR GET_IDENTIFIER IS
      SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
      FROM CUSTOMERS, ACCOUNTS, SERVICES, SO_TYPES, SO
      WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
        AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
        AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
        AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
        AND SVO_UID_PK = P_SVO_UID_PK
      UNION  
      SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
      FROM CUSTOMERS, ACCOUNTS, SERVICES, TROUBLE_TICKETS, TROUBLE_DISPATCHES
      WHERE SVC_UID_PK = TRT_SERVICES_UID_FK
        AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
        AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
        AND TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
        AND TDP_UID_PK = P_TDP_UID_PK;

    CURSOR CHECK_EXISTS (P_ROU_UID_PK IN NUMBER) IS
      SELECT 'X'
        FROM ROUTER_SO
       WHERE ROS_SO_UID_FK = P_SVO_UID_PK
         AND ROS_ROUTERS_UID_FK = P_ROU_UID_PK
         AND ROS_END_DATE IS NULL;

    V_DUMMY                VARCHAR2(1);
    V_ACCOUNT              VARCHAR2(200);
    V_SVC_UID_PK           NUMBER;
    V_IVL_UID_PK           NUMBER;
    V_OSB_UID_PK           NUMBER;
    V_OST_UID_PK           NUMBER;
    V_IDENTIFIER           VARCHAR2(300);
    V_DESCRIPTION          VARCHAR2(300);
    V_EMP_NAME             VARCHAR2(300);
    V_EQUIP_TYPE           VARCHAR2(20);
    V_ROU_UID_PK           NUMBER;
    V_STATUS               VARCHAR2(200);
    V_LAST_IVL_UID_PK      NUMBER;
    V_LAST_IVL_DESCRIPTION VARCHAR2(200);
    V_ROUTER_FOUND_FL      VARCHAR2(1) := 'N';
    V_SVO_UID_PK          NUMBER;
    V_ERROR_MESSAGE  VARCHAR2(2500);
    V_CHARGE_SO_ROUTER VARCHAR2(1000);

BEGIN

    --GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
    OPEN GET_TECH_LOCATION;
    FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
    CLOSE GET_TECH_LOCATION;

    OPEN GET_IDENTIFIER;
    FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
    CLOSE GET_IDENTIFIER;

    --DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
    V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_ROU_UID_PK);

    --NOT FOUND
    IF V_EQUIP_TYPE  = 'N' THEN
       RETURN 'SERIAL# NOT FOUND.  PLEASE MAKE SURE YOU SCANNED THE ROUTER MAC ADDRESS';
    ELSIF V_EQUIP_TYPE  != 'R' THEN
       RETURN 'PLEASE MAKE SURE A ROUTER IS SCANNED IN, THIS APPEARS TO BE ANOTHER PIECE OF EQUIPMENT .';
    END IF;

    OPEN CHECK_EXISTS(V_ROU_UID_PK);
    FETCH CHECK_EXISTS INTO V_DUMMY;
    IF CHECK_EXISTS%FOUND THEN
       V_ROUTER_FOUND_FL := 'Y';
    ELSE
       V_ROUTER_FOUND_FL := 'N';
    END IF;
    CLOSE CHECK_EXISTS;

    --SECTION ONE TO CHECK FOR VALIDATION ISSUES

    IF V_ROUTER_FOUND_FL = 'N' THEN
       IF V_IVL_UID_PK IS NULL THEN
          BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
          RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
       END IF;

       --BOX STATUS CHECK
       V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_MAC, V_EQUIP_TYPE, V_DESCRIPTION);
       IF V_STATUS NOT IN ('AN','AU','RT') THEN
          BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A ROUTER TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_DESCRIPTION);
          V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_MAC);
          RETURN 'THIS ROUTER IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
       END IF;

       --LOCATION CHECK
       IF V_IVL_UID_PK IS NOT NULL THEN
          V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_MAC);
          OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
          FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
          CLOSE LAST_LOCATION;

          IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
             IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
                BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A ROUTER TO '||V_IDENTIFIER||' '||P_MAC||' IS NOT FOUND ON THE TECHS TRUCK');
                RETURN 'THIS ROUTER IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE ADD THE ROUTER IN IWP TO YOUR TRUCK.';
             END IF;
          END IF;
       END IF;
    END IF;

    ----------------------------------------------------------------------
        IF V_EQUIP_TYPE = 'R' AND V_ROUTER_FOUND_FL = 'N' THEN
          --SVA 12/04/2015 add  CS SO
           IF P_SVO_UID_PK IS NULL and P_TDP_UID_PK IS NOT NULL THEN
              IF NOT generate_so_pkg.fn_create_cs_so(V_SVC_UID_PK,
                                              trunc(sysdate),
                                              sysdate,
                                              'Y',
                                              USER,
                                              USER,
                                              'PLANT_SO',
                                              v_svo_uid_pk ,
                                              v_error_message) THEN
                  RETURN 'ERROR FOUND WHEN CREATING A CS ORDER TO COMPLETE THE ROUTER ADDITION';
              ELSE
                 IF NOT generate_so_pkg.fn_add_feature_to_so(v_svo_uid_pk,'PLNT',1,v_error_message) THEN
                     RETURN 'ERROR FOUND WHEN CREATING A CS ORDER AND ADDING THE PLNT CODE TO COMPLETE THE ROUTER ADDITION';
                 ELSE
                     IF generate_so_pkg.fn_save_so(v_svo_uid_pk,v_error_message) THEN
                          insert into so_messages(SOG_UID_PK,
                                                  SOG_SO_UID_FK,
                                                  SOG_ENTERED_BY,
                                                  SOG_DATE,
                                                  SOG_TIME,
                                                  SOG_TEXT,
                                                  CREATED_DATE,
                                                  CREATED_BY)
                                          values (sog_seq.nextval,
                                                  v_svo_uid_pk,
                                                  user,
                                                  trunc(sysdate),
                                                  sysdate,
                                                  'REASON: '|| 'CS ORDER CREATED TO COMPLETE A TROUBLE TICKET ADDITION OF A ROUTER '||P_MAC,
                                                  sysdate,
                                                   user);
                    END IF;
                 END IF;
              END IF;
           END IF;
           
           --SVA 12/04/2015 add  assign value
           IF p_svo_uid_pk IS NOT NULL THEN 
              v_svo_uid_pk := p_svo_uid_pk;
           END IF;
           
           INSERT INTO ROUTER_SO(ROS_UID_PK, ROS_SO_UID_FK, ROS_ROUTERS_UID_FK, ROS_START_DATE, ROS_END_DATE, ROS_ACTIVE_FL)
                          VALUES(RSV_SEQ.NEXTVAL, V_SVO_UID_PK, V_ROU_UID_PK, TRUNC(SYSDATE), NULL, 'Y');
                                           

           BOX_MODEM_PKG.PR_ADD_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, 'ADD ACCT WEB');

           INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                                  VALUES(SOG_SEQ.NEXTVAL, V_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE ROUTER '||P_MAC||' WAS ADDED BY TECHNICIAN '||V_EMP_NAME);


           --SVA 12/04/2015 add  call function change so router
           v_charge_so_router :=  premium_home_pkg.charge_so_router_fun (v_svo_uid_pk, p_mac, p_bill_fl); 
           
           
           IF p_svo_uid_pk IS NULL and v_svo_uid_pk IS NOT NULL THEN
            UPDATE SO
                 SET svo_so_status_uid_fk = (select sos_uid_pk from so_status where sos_system_code = 'RDY TO CLOSE'),
                      svo_closed_by_emp_uid_fk = p_emp_uid_pk,
                      svo_close_date = trunc(sysdate),
                      svo_close_time = sysdate
                WHERE svo_uid_pk = v_svo_uid_pk;
           END IF;
           
           COMMIT;       
           RETURN 'THE ROUTER HAS BEEN SUCCESSFULLY ADDED TO THE SERVICE.' || v_charge_so_router;
        END IF;

     RETURN 'THERE WAS AN ISSUE WITH ADDING THE ROUTER PLEASE CONTACT THE HELPDESK';

END FN_ADD_ROUTER;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_REMOVE_ROUTER(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, 
                                                P_MAC IN VARCHAR, P_ADD_FL IN VARCHAR, P_TDP_UID_PK NUMBER)
RETURN VARCHAR
IS

    CURSOR GET_TECH_LOCATION IS
     SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
       FROM TECH_EMP_LOCATIONS, EMPLOYEES
      WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
        AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
        AND TEO_END_DATE IS NULL;

    CURSOR GET_IDENTIFIER IS
      SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
      FROM SERVICES, SO, SO_TYPES
      WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
        AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
        AND SVO_UID_PK = P_SVO_UID_PK
    UNION  
    SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
      FROM CUSTOMERS, ACCOUNTS, SERVICES, TROUBLE_TICKETS, TROUBLE_DISPATCHES
      WHERE SVC_UID_PK = TRT_SERVICES_UID_FK
        AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
        AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
        AND TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
     AND TDP_UID_PK = P_TDP_UID_PK;

    V_IVL_UID_PK           NUMBER;
    V_SVC_UID_PK           NUMBER;
    V_EQUIP_TYPE           VARCHAR2(1);
    V_ROU_UID_PK           NUMBER;
    V_STATUS               VARCHAR2(200);
    V_DUMMY                VARCHAR2(1);
    V_TIME                 VARCHAR2(200);
    V_IDENTIFIER           VARCHAR2(200);
    V_EMP_NAME             VARCHAR2(200);
    V_SVO_UID_PK          NUMBER;
    V_ERROR_MESSAGE  VARCHAR2(2500);
    V_CHARGE_SO_ROUTER VARCHAR2(1000);
    
BEGIN

    --GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
    OPEN GET_TECH_LOCATION;
    FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
    CLOSE GET_TECH_LOCATION;

    OPEN GET_IDENTIFIER;
    FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
    CLOSE GET_IDENTIFIER;

    --DTERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
    V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_ROU_UID_PK);

    IF V_IVL_UID_PK IS NULL THEN
       BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
       RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
    END IF;

    --NOT FOUND
    IF V_EQUIP_TYPE  = 'N' THEN
       RETURN 'MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
    END IF;

    --SVA 12/04/2015 add  CS SO
    IF P_SVO_UID_PK IS NULL AND P_TDP_UID_PK IS NOT NULL THEN
        IF NOT generate_so_pkg.fn_create_cs_so(V_SVC_UID_PK,
                                          trunc(sysdate),
                                          sysdate,
                                          'Y',
                                          USER,
                                          USER,
                                          'PLANT_SO',
                                          v_svo_uid_pk ,
                                          v_error_message) THEN
           RETURN 'ERROR FOUND WHEN CREATING A CS ORDER TO COMPLETE THE ROUTER REMOVAL';
        ELSE
           
           IF NOT generate_so_pkg.fn_add_feature_to_so(v_svo_uid_pk,'PLNT',1,v_error_message) THEN
               RETURN 'ERROR FOUND WHEN CREATING A CS ORDER AND ADDING THE PLNT CODE TO COMPLETE THE ROUTER REMOVAL';
           ELSE
               IF generate_so_pkg.fn_save_so(v_svo_uid_pk,v_error_message) THEN
                  insert into so_messages(SOG_UID_PK,
                                          SOG_SO_UID_FK,
                                          SOG_ENTERED_BY,
                                          SOG_DATE,
                                          SOG_TIME,
                                          SOG_TEXT,
                                          CREATED_DATE,
                                          CREATED_BY)
                                  values (sog_seq.nextval,
                                          v_svo_uid_pk,
                                          user,
                                          trunc(sysdate),
                                          sysdate,
                                          'REASON: '|| 'CS ORDER CREATED TO COMPLETE A TROUBLE TICKET REMOVAL OF A ROUTER '||P_MAC,
                                          sysdate,
                                           user);
               END IF;
           END IF;
        END IF;   
    END IF;
    
   --SVA  12/04/2015 add assign value
    IF P_SVO_UID_PK IS NOT NULL THEN
      V_SVO_UID_PK := P_SVO_UID_PK;
    END IF;
        
    --THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

    IF V_EQUIP_TYPE = 'R' THEN
       
       UPDATE ROUTER_SO
          SET ROS_END_DATE = TRUNC(SYSDATE),
              ROS_ACTIVE_FL= 'N'
        WHERE ROS_ROUTERS_UID_FK = V_ROU_UID_PK
          AND ROS_END_DATE IS NULL
          AND ROS_SO_UID_FK in (SELECT SVO_UID_PK
                                  FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                                 WHERE SVO_UID_PK = ROS_SO_UID_FK
                                   AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                                   AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                                   AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                                   AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
                                   
       update router_services
          set rsv_end_date = TRUNC(SYSDATE),
              rsv_active_fl = 'N'
        where rsv_routers_uid_fk = V_ROU_UID_PK
          and rsv_end_date is null;
       
      PR_INSERT_SO_MESSAGE(V_SVO_UID_PK, 'THE ROUTER '||P_MAC||' WAS REMOVED BY TECHNICIAN '||V_EMP_NAME, P_EMP_UID_PK, 'S');

    END IF;

    COMMIT;

    IF P_ADD_FL = 'N' THEN
       OPEN GET_UNKNOWN_LOC;
       FETCH GET_UNKNOWN_LOC INTO V_IVL_UID_PK;
       CLOSE GET_UNKNOWN_LOC;   
    END IF;

    V_STATUS := 'REMOVE INSTALLATION';
    BOX_MODEM_PKG.PR_REMOVE_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, V_STATUS, V_IVL_UID_PK);
    
    --SVA 12/04/2015 add call function remove so
    -- MCV 01/07/2016 router functionality not going live right away - commenting out
    --v_charge_so_router := premium_home_pkg.remove_so_router_fun (v_svo_uid_pk, P_MAC);

   IF p_svo_uid_pk IS NULL and v_svo_uid_pk IS NOT NULL THEN
    UPDATE SO
         SET svo_so_status_uid_fk = (select sos_uid_pk from so_status where sos_system_code = 'RDY TO CLOSE'),
              svo_closed_by_emp_uid_fk = p_emp_uid_pk,
              svo_close_date = trunc(sysdate),
              svo_close_time = sysdate
        WHERE svo_uid_pk = v_svo_uid_pk;
   END IF;
    
    COMMIT;

    IF P_ADD_FL = 'N' THEN
       RETURN 'ROUTER SUCESSFULLY REMOVED FROM THE ACCOUNT.' || v_charge_so_router;
    ELSE
       RETURN 'ROUTER SUCESSFULLY REMOVED FROM THE ACCOUNT AND ADDED TO YOUR INVENTORY.' || v_charge_so_router;
    END IF;

END FN_REMOVE_ROUTER;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_SWAP_ROUTER(P_OLD_SERIAL# IN VARCHAR, P_NEW_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_ADD_FL IN VARCHAR)
RETURN VARCHAR

IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
  SELECT IVL_UID_PK
    FROM INVENTORY_LOCATIONS
   WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
         SVC_UID_PK,
         TRT_UID_PK
  FROM SERVICES, OFFICE_SERV_TYPES, TROUBLE_TICKETS, TROUBLE_DISPATCHES
  WHERE TDP_UID_PK = P_TDP_UID_PK
    AND TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
    AND SVC_UID_PK = TRT_SERVICES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK;

CURSOR GET_PLNT_INFO(P_STY_UID_PK IN NUMBER, P_BSO_UID_PK IN NUMBER) IS
SELECT OSF_UID_PK
  FROM OFFICE_SERV_FEATS, OFFICE_SERV_TYPES, FEATURES
 WHERE OST_UID_PK = OSF_OFFICE_SERV_TYPES_UID_FK
   AND FTP_UID_PK = OSF_FEATURES_UID_FK
   AND FTP_CODE = 'PLNT'
   AND OST_BUSINESS_OFFICES_UID_FK = P_BSO_UID_PK
   AND OST_SERVICE_TYPES_UID_FK = P_STY_UID_PK;

CURSOR CHECK_EXISTS (P_ROU_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM ROUTER_SERVICES
   WHERE RSV_ROUTERS_UID_FK = P_ROU_UID_PK
     AND RSV_SERVICES_UID_FK = P_SVC_UID_PK
     AND RSV_END_DATE IS NULL;

V_IVL_UID_PK           NUMBER;
V_IVL_UID_PK_REMOVE    NUMBER;
V_SVO_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_TVB_UID_PK           NUMBER;
V_TRT_UID_PK           NUMBER;
V_LAST_IVL_UID_PK      NUMBER;
V_OST_UID_PK           NUMBER;
V_SVT_CODE             VARCHAR2(40);
V_LAST_IVL_DESCRIPTION VARCHAR2(200);
V_EQUIP_TYPE_OLD       VARCHAR2(1);
V_EQUIP_TYPE_NEW       VARCHAR2(1);
V_ROU_UID_PK           NUMBER;
V_ROU_UID_PK_NEW       NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_TIME                 VARCHAR2(200);
V_RETURN_MESSAGE       VARCHAR2(2000) := NULL;
V_IDENTIFIER           VARCHAR2(200);
V_IDENTIFIER_DISPLAY   VARCHAR2(200) := NULL;
V_DESCRIPTION          VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);
V_ACCOUNT              VARCHAR2(200);
V_ERROR_MESSAGE        VARCHAR2(2000);
V_ROUTER_FOUND_FL      VARCHAR2(1) := 'N';
v_return_msg  		VARCHAR2(4000);

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK, V_TRT_UID_PK;
CLOSE GET_IDENTIFIER;

IF V_IVL_UID_PK IS NULL THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
   RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
END IF;

IF P_OLD_SERIAL# = P_NEW_SERIAL# THEN
   RETURN 'THE OLD MAC ADDRESS CANNOT MATCH THE NEW MAC ADDRESS';
END IF;

--***********************************************
--CHECK TO REMOVE THE OLD SERIAL/MAC ADDRESS
--DETERMINE IF THE SERIAL# PASSED IN IS A ROUTER
V_EQUIP_TYPE_OLD := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_OLD_SERIAL#, V_ROU_UID_PK);
   
--NOT FOUND
IF V_EQUIP_TYPE_OLD = 'N' THEN
   IF P_OLD_SERIAL# IS NOT NULL THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_OLD_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO REMOVE A ROUTER FROM '||V_IDENTIFIER||' '||P_OLD_SERIAL#||' IS NOT FOUND IN THE SYSTEM');
      RETURN 'OLD SERIAL# NOT FOUND';
   ELSE
      RETURN 'OLD SERIAL# NOT FOUND';
   END IF;
ELSIF V_EQUIP_TYPE_OLD != 'R' THEN
   RETURN 'THE MAC ADDRESS ENTERED FOR THE OLD SERIAL# IS NOT FOR A ROUTER.  PLEASE MAKE SURE IT WAS ENTERED CORRECTLY.';
END IF;

--DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE_NEW := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_NEW_SERIAL#, V_ROU_UID_PK_NEW);

--NOT FOUND
IF V_EQUIP_TYPE_NEW  = 'N' THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A ROUTER TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND IN THE SYSTEM');
   RETURN 'NEW MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
END IF;

OPEN CHECK_EXISTS(V_ROU_UID_PK_NEW, V_SVC_UID_PK);
FETCH CHECK_EXISTS INTO V_DUMMY;
IF CHECK_EXISTS%FOUND THEN
   V_ROUTER_FOUND_FL := 'Y';
ELSE
   V_ROUTER_FOUND_FL := 'N';
END IF;
CLOSE CHECK_EXISTS;

IF V_ROUTER_FOUND_FL = 'N' THEN

   --BOX STATUS CHECK
   V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_NEW_SERIAL#, V_EQUIP_TYPE_NEW, V_DESCRIPTION);
   IF V_STATUS NOT IN ('AN','AU','RT') THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A ROUTER TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_STATUS);
      V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_NEW_SERIAL#);
      RETURN 'THIS ROUTER IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
   END IF;

   --LOCATION CHECK
   IF V_IVL_UID_PK IS NOT NULL THEN
      V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_NEW_SERIAL#);
      OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
      FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
      CLOSE LAST_LOCATION;

      IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
         IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
            BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN A ROUTER TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND ON THE TECHS TRUCK');
            RETURN 'THIS ROUTER IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
         END IF;
      END IF;
   END IF;
END IF;

IF P_ADD_FL = 'N' THEN
   OPEN GET_UNKNOWN_LOC;
   FETCH GET_UNKNOWN_LOC INTO V_IVL_UID_PK_REMOVE;
   CLOSE GET_UNKNOWN_LOC;
ELSE
   V_IVL_UID_PK_REMOVE := V_IVL_UID_PK;
END IF;

UPDATE ROUTER_SERVICES
   SET RSV_END_DATE = TRUNC(SYSDATE),
       RSV_ACTIVE_FL = 'N'
 WHERE RSV_ROUTERS_UID_FK = V_ROU_UID_PK
   AND RSV_END_DATE IS NULL;

UPDATE ROUTER_SO
   SET ROS_END_DATE = TRUNC(SYSDATE),
       ROS_ACTIVE_FL = 'N'
 WHERE ROS_ROUTERS_UID_FK = V_ROU_UID_PK
   AND ROS_END_DATE IS NULL
   AND ROS_SO_UID_FK in (SELECT SVO_UID_PK
                           FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                          WHERE SVO_UID_PK = ROS_SO_UID_FK
                            AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                            AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                            AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                            AND SVO_SERVICES_UID_FK = V_SVC_UID_PK
                            AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));

BOX_MODEM_PKG.PR_REMOVE_ACCT(P_OLD_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, NULL, 'REPAIR INSTALLATION', V_IVL_UID_PK_REMOVE);

--********************END WITH THE OLD BOX/MODEM************************--

INSERT INTO SERVICE_MESSAGES(SVM_UID_PK, SVM_SERVICES_UID_FK, SVM_ENTERED_BY, SVM_DATE, SVM_TIME, SVM_TEXT, SVM_ACTIVE_FL)
                             VALUES(SVM_SEQ.NEXTVAL, V_SVC_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE ROUTER '||P_OLD_SERIAL#||' WAS REMOVED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' BY TECHNICIAN '||V_EMP_NAME, 'Y');

--ADD THE NEW SERIAL
IF V_EQUIP_TYPE_NEW = 'R' AND V_ROUTER_FOUND_FL = 'N' THEN

   if not generate_so_pkg.fn_create_cs_so(V_SVC_UID_PK,
                                          trunc(sysdate),
                                          sysdate,
                                          'Y',
                                          USER,
                                          USER,
                                          'PLANT_SO',
                                          v_svo_uid_pk ,
                                          v_error_message) THEN
       RETURN 'ERROR FOUND WHEN CREATING A CS ORDER TO COMPLETE THE ROUTER SWAP';
   Else
       --add the plnt feature code to the order.
       if not generate_so_pkg.fn_add_feature_to_so(v_svo_uid_pk,'PLNT',1,v_error_message) THEN
           RETURN 'ERROR FOUND WHEN CREATING A CS ORDER AND ADDING THE PLNT CODE TO COMPLETE THE ROUTER SWAP';
       else
           if generate_so_pkg.fn_save_so(v_svo_uid_pk,v_error_message) THEN
              insert into so_messages(SOG_UID_PK,
                                      SOG_SO_UID_FK,
                                      SOG_ENTERED_BY,
                                      SOG_DATE,
                                      SOG_TIME,
                                      SOG_TEXT,
                                      CREATED_DATE,
                                      CREATED_BY)
                              values (sog_seq.nextval,
                                      v_svo_uid_pk,
                                      user,
                                      trunc(sysdate),
                                      sysdate,
                                      'REASON: '|| 'CS ORDER CREATED TO COMPLETE A TROUBLE TICKET SWAP ON A ROUTER FROM '||P_OLD_SERIAL#||' TO '||P_NEW_SERIAL#,
                                      sysdate,
                                       user);
            end if;
       end if;

       update so
          set svo_so_status_uid_fk = (select sos_uid_pk from so_status where sos_system_code = 'CLOSED'),
              SVO_CLOSED_BY_EMP_UID_FK = p_emp_uid_pk,
              svo_close_date = trunc(sysdate),
              svo_close_time = sysdate
        where svo_uid_pk = v_svo_uid_pk;

       commit;
        
       INSERT INTO ROUTER_SERVICES(RSV_UID_PK, RSV_SERVICES_UID_FK, RSV_ROUTERS_UID_FK, RSV_START_DATE, RSV_END_DATE, RSV_ACTIVE_FL)
                            VALUES(RSV_SEQ.NEXTVAL, V_SVC_UID_PK, V_ROU_UID_PK_NEW, TRUNC(SYSDATE), NULL, 'Y');

   END IF;

END IF;

COMMIT;

V_RETURN_MESSAGE := 'SWAP COMPLETED SUCCESSFULLY.';

IF V_LAST_IVL_DESCRIPTION = 'LOCATION NOT FOUND' THEN --ALSO ADD A RECORD TO ISSUE AN AUTO RECEIVE IN, INTO THE TECH TRUCK LOCATION
   BOX_MODEM_PKG.PR_RECEIVE_STB_INTO_INV(P_NEW_SERIAL#, V_IVL_UID_PK, NULL, NULL);
END IF;

BOX_MODEM_PKG.PR_ADD_ACCT(P_NEW_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, 'ADD ACCT WEB');

COMMIT;

RETURN V_RETURN_MESSAGE;

END FN_SWAP_ROUTER;

FUNCTION FN_ROUTER_DISPLAY(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

CURSOR ROUTER_SO IS
SELECT ROU_MAC_ADDRESS, PRD_VEND_CODE
  FROM ROUTER_SO, ROUTERS, PRODUCTS
 WHERE PRD_UID_PK = ROU_PRODUCTS_UID_FK
   AND ROU_UID_PK = ROS_ROUTERS_UID_FK
   AND ROS_SO_UID_FK = P_SVO_UID_PK
   AND ROS_END_DATE IS NULL
 ORDER BY ROU_MAC_ADDRESS;
 
CURSOR ROUTER_SERVICES IS
SELECT ROU_MAC_ADDRESS, PRD_VEND_CODE
  FROM ROUTER_SERVICES, ROUTERS, PRODUCTS
 WHERE PRD_UID_PK = ROU_PRODUCTS_UID_FK
   AND ROU_UID_PK = RSV_ROUTERS_UID_FK
   AND RSV_SERVICES_UID_FK = P_SVC_UID_PK
   AND RSV_END_DATE IS NULL
 ORDER BY ROU_MAC_ADDRESS;

rec     ROUTER_SO%rowtype;
rec2    ROUTER_SERVICES%rowtype;
v_rec   generic_data_type;

BEGIN

IF P_SVO_UID_PK IS NOT NULL THEN

 OPEN ROUTER_SO;
 LOOP
    FETCH ROUTER_SO into rec;
    EXIT WHEN ROUTER_SO%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1  := rec.ROU_MAC_ADDRESS;
     v_rec.gdt_alpha2  := rec.prd_vend_code;

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE ROUTER_SO;
  
ELSIF P_SVC_UID_PK IS NOT NULL THEN

 OPEN ROUTER_SERVICES;
 LOOP
    FETCH ROUTER_SERVICES into rec;
    EXIT WHEN ROUTER_SERVICES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1  := rec.ROU_MAC_ADDRESS;
     v_rec.gdt_alpha2  := rec.prd_vend_code;

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE ROUTER_SERVICES;

END IF;

RETURN;

END FN_ROUTER_DISPLAY;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_ADD_CPE(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MAC IN VARCHAR)
RETURN VARCHAR IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
  SELECT IVL_UID_PK
    FROM INVENTORY_LOCATIONS
   WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

CURSOR GET_EMPLOYEE IS
 SELECT EMP_FNAME||' '||EMP_LNAME
   FROM EMPLOYEES
  WHERE EMP_UID_PK = P_EMP_UID_PK;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
  FROM CUSTOMERS, ACCOUNTS, SERVICES, SO_TYPES, SO
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;

CURSOR CHECK_EXISTS (P_CPE_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM CPE_SO
   WHERE CEO_SO_UID_FK = P_SVO_UID_PK
     AND CEO_CPE_UID_FK = P_CPE_UID_PK
     AND CEO_END_DATE IS NULL;

V_DUMMY                VARCHAR2(1);
V_ACCOUNT              VARCHAR2(200);
V_SVC_UID_PK           NUMBER;
V_IVL_UID_PK           NUMBER;
V_OSB_UID_PK           NUMBER;
V_OST_UID_PK           NUMBER;
V_IDENTIFIER           VARCHAR2(300);
V_DESCRIPTION          VARCHAR2(300);
V_EMP_NAME             VARCHAR2(300);
V_EQUIP_TYPE           VARCHAR2(20);
V_CPE_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_LAST_IVL_UID_PK      NUMBER;
V_LAST_IVL_DESCRIPTION VARCHAR2(200);
V_CPE_FOUND_FL         VARCHAR2(1) := 'N';

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
CLOSE GET_IDENTIFIER;

--DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_CPE_UID_PK);

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'SERIAL# NOT FOUND.  PLEASE MAKE SURE YOU SCANNED THE CPE MAC ADDRESS';
ELSIF V_EQUIP_TYPE  != 'L' THEN
   RETURN 'PLEASE MAKE SURE A CPE IS SCANNED IN, THIS APPEARS TO BE ANOTHER PIECE OF EQUIPMENT .';
END IF;

OPEN CHECK_EXISTS(V_CPE_UID_PK);
FETCH CHECK_EXISTS INTO V_DUMMY;
IF CHECK_EXISTS%FOUND THEN
   V_CPE_FOUND_FL := 'Y';
ELSE
   V_CPE_FOUND_FL := 'N';
END IF;
CLOSE CHECK_EXISTS;

--SECTION ONE TO CHECK FOR VALIDATION ISSUES

IF V_CPE_FOUND_FL = 'N' THEN
   IF V_IVL_UID_PK IS NULL THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
      RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
   END IF;

   --BOX STATUS CHECK
   V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_MAC, V_EQUIP_TYPE, V_DESCRIPTION);
   IF V_STATUS NOT IN ('AN','AU','RT') THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN CPE TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_DESCRIPTION);
      V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_MAC);
      RETURN 'THIS CPE IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
   END IF;

   --LOCATION CHECK
   IF V_IVL_UID_PK IS NOT NULL THEN
      V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_MAC);
      OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
      FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
      CLOSE LAST_LOCATION;

      IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
         IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
            BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN CPE TO '||V_IDENTIFIER||' '||P_MAC||' IS NOT FOUND ON THE TECHS TRUCK');
            RETURN 'THIS CPE IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE ADD THE CPE IN IWP TO YOUR TRUCK.';
         END IF;
      END IF;
   END IF;
END IF;

----------------------------------------------------------------------

IF V_EQUIP_TYPE = 'L' AND V_CPE_FOUND_FL = 'N' THEN

   INSERT INTO CPE_SO(CEO_UID_PK, CEO_SO_UID_FK, CEO_CPE_UID_FK, CEO_START_DATE, CEO_END_DATE, CEO_ACTIVE_FL)
               VALUES(CPS_SEQ.NEXTVAL, P_SVO_UID_PK, V_CPE_UID_PK, TRUNC(SYSDATE), NULL, 'Y');
                                   

   BOX_MODEM_PKG.PR_ADD_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'ADD ACCT WEB');

   INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                          VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE CPE '||P_MAC||' WAS ADDED BY TECHNICIAN '||V_EMP_NAME);

   COMMIT;

   RETURN 'THE CPE HAS BEEN SUCCESSFULLY ADDED TO THE SERVICE.';

END IF;

IF V_EQUIP_TYPE = 'L' AND V_CPE_FOUND_FL = 'Y' THEN
   RETURN 'THE CPE HAS BEEN SUCCESSFULLY ADDED TO THE SERVICE.';
ELSE
   RETURN 'THERE WAS AN ISSUE WITH ADDING THE CPE PLEASE CONTACT THE HELPDESK';
END IF;

END FN_ADD_CPE;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_REMOVE_CPE(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MAC IN VARCHAR, P_ADD_FL IN VARCHAR)

RETURN VARCHAR

IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
  FROM SERVICES, SO, SO_TYPES
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;


V_IVL_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_EQUIP_TYPE           VARCHAR2(1);
V_CPE_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_TIME                 VARCHAR2(200);
V_IDENTIFIER           VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);


BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
CLOSE GET_IDENTIFIER;

--DTERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_CPE_UID_PK);

IF V_IVL_UID_PK IS NULL THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
   RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
END IF;

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
END IF;

--THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

IF V_EQUIP_TYPE = 'L' THEN
   
   UPDATE CPE_SO
      SET CEO_END_DATE = TRUNC(SYSDATE),
          CEO_ACTIVE_FL= 'N'
    WHERE CEO_CPE_UID_FK = V_CPE_UID_PK
      AND CEO_END_DATE IS NULL
      AND CEO_SO_UID_FK in (SELECT SVO_UID_PK
                              FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                             WHERE SVO_UID_PK = CEO_SO_UID_FK
                               AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                               AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                               AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                               AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
                               
   update cpe_services
      set cps_end_date = TRUNC(SYSDATE),
          cps_active_fl = 'N'
    where cps_cpe_uid_fk = V_CPE_UID_PK
      and cps_end_date is null;
   
  PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, 'THE CPE '||P_MAC||' WAS REMOVED BY TECHNICIAN '||V_EMP_NAME, P_EMP_UID_PK, 'S');

END IF;

COMMIT;

IF P_ADD_FL = 'N' THEN
   OPEN GET_UNKNOWN_LOC;
   FETCH GET_UNKNOWN_LOC INTO V_IVL_UID_PK;
   CLOSE GET_UNKNOWN_LOC;   
END IF;

V_STATUS := 'REMOVE INSTALLATION';
BOX_MODEM_PKG.PR_REMOVE_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, V_STATUS, V_IVL_UID_PK);

COMMIT;

IF P_ADD_FL = 'N' THEN
   RETURN 'CPE SUCESSFULLY REMOVED FROM THE ACCOUNT';
ELSE
   RETURN 'CPE SUCESSFULLY REMOVED FROM THE ACCOUNT AND ADDED TO YOUR INVENTORY.';
END IF;

END FN_REMOVE_CPE;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_SWAP_CPE(P_OLD_SERIAL# IN VARCHAR, P_NEW_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_ADD_FL IN VARCHAR)
RETURN VARCHAR

IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
  SELECT IVL_UID_PK
    FROM INVENTORY_LOCATIONS
   WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK),
         SVC_UID_PK,
         TRT_UID_PK
  FROM SERVICES, OFFICE_SERV_TYPES, TROUBLE_TICKETS, TROUBLE_DISPATCHES
  WHERE TDP_UID_PK = P_TDP_UID_PK
    AND TRT_UID_PK = TDP_TROUBLE_TICKETS_UID_FK
    AND SVC_UID_PK = TRT_SERVICES_UID_FK
    AND OST_UID_PK = SVC_OFFICE_SERV_TYPES_UID_FK;

CURSOR GET_PLNT_INFO(P_STY_UID_PK IN NUMBER, P_BSO_UID_PK IN NUMBER) IS
SELECT OSF_UID_PK
  FROM OFFICE_SERV_FEATS, OFFICE_SERV_TYPES, FEATURES
 WHERE OST_UID_PK = OSF_OFFICE_SERV_TYPES_UID_FK
   AND FTP_UID_PK = OSF_FEATURES_UID_FK
   AND FTP_CODE = 'PLNT'
   AND OST_BUSINESS_OFFICES_UID_FK = P_BSO_UID_PK
   AND OST_SERVICE_TYPES_UID_FK = P_STY_UID_PK;

CURSOR CHECK_EXISTS (P_CPE_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM CPE_SERVICES
   WHERE CPS_CPE_UID_FK = P_CPE_UID_PK
     AND CPS_SERVICES_UID_FK = P_SVC_UID_PK
     AND CPS_END_DATE IS NULL;

V_IVL_UID_PK           NUMBER;
V_IVL_UID_PK_REMOVE    NUMBER;
V_SVO_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_TVB_UID_PK           NUMBER;
V_TRT_UID_PK           NUMBER;
V_LAST_IVL_UID_PK      NUMBER;
V_OST_UID_PK           NUMBER;
V_SVT_CODE             VARCHAR2(40);
V_LAST_IVL_DESCRIPTION VARCHAR2(200);
V_EQUIP_TYPE_OLD       VARCHAR2(1);
V_EQUIP_TYPE_NEW       VARCHAR2(1);
V_CPE_UID_PK           NUMBER;
V_CPE_UID_PK_NEW       NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_TIME                 VARCHAR2(200);
V_RETURN_MESSAGE       VARCHAR2(2000) := NULL;
V_IDENTIFIER           VARCHAR2(200);
V_IDENTIFIER_DISPLAY   VARCHAR2(200) := NULL;
V_DESCRIPTION          VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);
V_ACCOUNT              VARCHAR2(200);
V_ERROR_MESSAGE        VARCHAR2(2000);
V_CPE_FOUND_FL         VARCHAR2(1) := 'N';
v_return_msg           VARCHAR2(4000);

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK, V_TRT_UID_PK;
CLOSE GET_IDENTIFIER;

IF V_IVL_UID_PK IS NULL THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
   RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
END IF;

IF P_OLD_SERIAL# = P_NEW_SERIAL# THEN
   RETURN 'THE OLD MAC ADDRESS CANNOT MATCH THE NEW MAC ADDRESS';
END IF;

--***********************************************
--CHECK TO REMOVE THE OLD SERIAL/MAC ADDRESS
--DETERMINE IF THE SERIAL# PASSED IN IS A ROUTER
V_EQUIP_TYPE_OLD := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_OLD_SERIAL#, V_CPE_UID_PK);
   
--NOT FOUND
IF V_EQUIP_TYPE_OLD = 'N' THEN
   IF P_OLD_SERIAL# IS NOT NULL THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_OLD_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO REMOVE CPE FROM '||V_IDENTIFIER||' '||P_OLD_SERIAL#||' IS NOT FOUND IN THE SYSTEM');
      RETURN 'OLD SERIAL# NOT FOUND';
   ELSE
      RETURN 'OLD SERIAL# NOT FOUND';
   END IF;
ELSIF V_EQUIP_TYPE_OLD != 'L' THEN
   RETURN 'THE MAC ADDRESS ENTERED FOR THE OLD SERIAL# IS NOT FOR CPE.  PLEASE MAKE SURE IT WAS ENTERED CORRECTLY.';
END IF;

--DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE_NEW := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_NEW_SERIAL#, V_CPE_UID_PK_NEW);

--NOT FOUND
IF V_EQUIP_TYPE_NEW  = 'N' THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN CPE TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND IN THE SYSTEM');
   RETURN 'NEW MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
END IF;

OPEN CHECK_EXISTS(V_CPE_UID_PK_NEW, V_SVC_UID_PK);
FETCH CHECK_EXISTS INTO V_DUMMY;
IF CHECK_EXISTS%FOUND THEN
   V_CPE_FOUND_FL := 'Y';
ELSE
   V_CPE_FOUND_FL := 'N';
END IF;
CLOSE CHECK_EXISTS;

IF V_CPE_FOUND_FL = 'N' THEN

   --BOX STATUS CHECK
   V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_NEW_SERIAL#, V_EQUIP_TYPE_NEW, V_DESCRIPTION);
   IF V_STATUS NOT IN ('AN','AU','RT') THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN CPE TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_STATUS);
      V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_NEW_SERIAL#);
      RETURN 'THIS CPE IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
   END IF;

   --LOCATION CHECK
   IF V_IVL_UID_PK IS NOT NULL THEN
      V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_NEW_SERIAL#);
      OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
      FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
      CLOSE LAST_LOCATION;

      IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
         IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
            BOX_MODEM_PKG.PR_EXCEPTION(P_NEW_SERIAL#, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN CPE TO '||V_IDENTIFIER||' '||P_NEW_SERIAL#||' IS NOT FOUND ON THE TECHS TRUCK');
            RETURN 'THIS CPE IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE CALL YOUR SUPERVISOR TO ISSUE THE PROPER TRANSFER IF NEEDED.';
         END IF;
      END IF;
   END IF;
END IF;

IF P_ADD_FL = 'N' THEN
   OPEN GET_UNKNOWN_LOC;
   FETCH GET_UNKNOWN_LOC INTO V_IVL_UID_PK_REMOVE;
   CLOSE GET_UNKNOWN_LOC;
ELSE
   V_IVL_UID_PK_REMOVE := V_IVL_UID_PK;
END IF;

UPDATE CPE_SERVICES
   SET CPS_END_DATE = TRUNC(SYSDATE),
       CPS_ACTIVE_FL = 'N'
 WHERE CPS_CPE_UID_FK = V_CPE_UID_PK
   AND CPS_END_DATE IS NULL;

UPDATE CPE_SO
   SET CEO_END_DATE = TRUNC(SYSDATE),
       CEO_ACTIVE_FL = 'N'
 WHERE CEO_CPE_UID_FK = V_CPE_UID_PK
   AND CEO_END_DATE IS NULL
   AND CEO_SO_UID_FK in (SELECT SVO_UID_PK
                           FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                          WHERE SVO_UID_PK = CEO_SO_UID_FK
                            AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                            AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                            AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                            AND SVO_SERVICES_UID_FK = V_SVC_UID_PK
                            AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));

BOX_MODEM_PKG.PR_REMOVE_ACCT(P_OLD_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, NULL, 'REPAIR INSTALLATION', V_IVL_UID_PK_REMOVE);

--********************END WITH THE OLD BOX/MODEM************************--

INSERT INTO SERVICE_MESSAGES(SVM_UID_PK, SVM_SERVICES_UID_FK, SVM_ENTERED_BY, SVM_DATE, SVM_TIME, SVM_TEXT, SVM_ACTIVE_FL)
                             VALUES(SVM_SEQ.NEXTVAL, V_SVC_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE CPE '||P_OLD_SERIAL#||' WAS REMOVED BECAUSE OF REPAIR ON TROUBLE TICKET '||V_TRT_UID_PK||' BY TECHNICIAN '||V_EMP_NAME, 'Y');

--ADD THE NEW SERIAL
IF V_EQUIP_TYPE_NEW = 'L' AND V_CPE_FOUND_FL = 'N' THEN

   if not generate_so_pkg.fn_create_cs_so(V_SVC_UID_PK,
                                          trunc(sysdate),
                                          sysdate,
                                          'Y',
                                          USER,
                                          USER,
                                          'PLANT_SO',
                                          v_svo_uid_pk ,
                                          v_error_message) THEN
       RETURN 'ERROR FOUND WHEN CREATING A CS ORDER TO COMPLETE THE CPE SWAP';
   Else
       --add the plnt feature code to the order.
       if not generate_so_pkg.fn_add_feature_to_so(v_svo_uid_pk,'PLNT',1,v_error_message) THEN
           RETURN 'ERROR FOUND WHEN CREATING A CS ORDER AND ADDING THE PLNT CODE TO COMPLETE THE CPE SWAP';
       else
           if generate_so_pkg.fn_save_so(v_svo_uid_pk,v_error_message) THEN
              insert into so_messages(SOG_UID_PK,
                                      SOG_SO_UID_FK,
                                      SOG_ENTERED_BY,
                                      SOG_DATE,
                                      SOG_TIME,
                                      SOG_TEXT,
                                      CREATED_DATE,
                                      CREATED_BY)
                              values (sog_seq.nextval,
                                      v_svo_uid_pk,
                                      user,
                                      trunc(sysdate),
                                      sysdate,
                                      'REASON: '|| 'CS ORDER CREATED TO COMPLETE A TROUBLE TICKET SWAP ON CPE FROM '||P_OLD_SERIAL#||' TO '||P_NEW_SERIAL#,
                                      sysdate,
                                       user);
            end if;
       end if;

       update so
          set svo_so_status_uid_fk = (select sos_uid_pk from so_status where sos_system_code = 'CLOSED'),
              SVO_CLOSED_BY_EMP_UID_FK = p_emp_uid_pk,
              svo_close_date = trunc(sysdate),
              svo_close_time = sysdate
        where svo_uid_pk = v_svo_uid_pk;

       commit;
        
       INSERT INTO CPE_SERVICES(CPS_UID_PK, CPS_SERVICES_UID_FK, CPS_CPE_UID_FK, CPS_START_DATE, CPS_END_DATE, CPS_ACTIVE_FL)
                         VALUES(CPS_SEQ.NEXTVAL, V_SVC_UID_PK, V_CPE_UID_PK_NEW, TRUNC(SYSDATE), NULL, 'Y');

   END IF;

END IF;

COMMIT;

V_RETURN_MESSAGE := 'SWAP COMPLETED SUCCESSFULLY.';

IF V_LAST_IVL_DESCRIPTION = 'LOCATION NOT FOUND' THEN --ALSO ADD A RECORD TO ISSUE AN AUTO RECEIVE IN, INTO THE TECH TRUCK LOCATION
   BOX_MODEM_PKG.PR_RECEIVE_STB_INTO_INV(P_NEW_SERIAL#, V_IVL_UID_PK, NULL, NULL);
END IF;

BOX_MODEM_PKG.PR_ADD_ACCT(P_NEW_SERIAL#, V_IDENTIFIER, V_SVC_UID_PK, V_SVO_UID_PK, 'ADD ACCT WEB');

COMMIT;

RETURN V_RETURN_MESSAGE;

END FN_SWAP_CPE;

FUNCTION FN_CPE_DISPLAY(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

CURSOR CPE_SO IS
SELECT CPE_MAC_ADDRESS, PRD_VEND_CODE, CEO_UID_PK, CPY_CODE
  FROM CPE_SO, CPE, PRODUCTS, CPE_TYPES
 WHERE PRD_UID_PK = CPE_PRODUCTS_UID_FK
   AND CPY_UID_PK = CPE_CPE_TYPES_UID_FK
   AND CPE_UID_PK = CEO_CPE_UID_FK
   AND CEO_SO_UID_FK = P_SVO_UID_PK
   AND CEO_END_DATE IS NULL
 ORDER BY CPE_MAC_ADDRESS;
 
CURSOR CPE_SERVICES IS
SELECT CPE_MAC_ADDRESS, PRD_VEND_CODE, CPS_UID_PK, CPY_CODE
  FROM CPE_SERVICES, CPE, PRODUCTS, CPE_TYPES
 WHERE PRD_UID_PK = CPE_PRODUCTS_UID_FK
   AND CPY_UID_PK = CPE_CPE_TYPES_UID_FK
   AND CPE_UID_PK = CPS_CPE_UID_FK
   AND CPS_SERVICES_UID_FK = P_SVC_UID_PK
   AND CPS_END_DATE IS NULL
 ORDER BY CPE_MAC_ADDRESS;

rec     CPE_SO%rowtype;
rec2    CPE_SERVICES%rowtype;
v_rec   generic_data_type;

BEGIN

IF P_SVO_UID_PK IS NOT NULL THEN

 OPEN CPE_SO;
 LOOP
    FETCH CPE_SO into rec;
    EXIT WHEN CPE_SO%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1  := rec.CPE_MAC_ADDRESS;
     v_rec.gdt_alpha2  := rec.prd_vend_code;
     v_rec.gdt_alpha3  := rec.CEO_UID_PK;
     v_rec.gdt_alpha4  := rec.cpy_code;

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE CPE_SO;
  
ELSIF P_SVC_UID_PK IS NOT NULL THEN

 OPEN CPE_SERVICES;
 LOOP
    FETCH CPE_SERVICES into rec2;
    EXIT WHEN CPE_SERVICES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1  := rec2.CPE_MAC_ADDRESS;
     v_rec.gdt_alpha2  := rec2.prd_vend_code;
     v_rec.gdt_alpha3  := rec2.CPS_UID_PK;
     v_rec.gdt_alpha4  := rec2.cpy_code;

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE CPE_SERVICES;

END IF;

RETURN;

END FN_CPE_DISPLAY;

FUNCTION FN_SVC_OR_SO_PROV(P_CUS_UID_PK IN NUMBER, P_MAC_ADDRESS IN VARCHAR)

RETURN VARCHAR

IS

CURSOR CHECK_SVC IS
SELECT 'S'
FROM ACCOUNTS, SERVICES, SERVICE_ASSGNMTS, CABLE_MODEMS
WHERE ACC_CUSTOMERS_UID_FK = P_CUS_UID_PK
AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
AND SVC_UID_PK = SVA_SERVICES_UID_fk
AND CBM_UID_PK = SVA_CABLE_MODEMS_UID_FK
AND CBM_MAC_ADDRESS = P_MAC_ADDRESS;

CURSOR CHECK_SO IS
SELECT 'O'
FROM ACCOUNTS, SERVICES, SO, SO_ASSGNMTS, CABLE_MODEMS
WHERE ACC_CUSTOMERS_UID_FK = P_CUS_UID_PK
AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
AND SVC_UID_PK = SVO_SERVICES_UID_FK
AND SVO_UID_PK = SON_SO_UID_FK
AND CBM_UID_PK = SON_CABLE_MODEMS_UID_FK
AND CBM_MAC_ADDRESS = P_MAC_ADDRESS;

V_RETURN_FL VARCHAR2(1) := 'N';

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN CHECK_SVC;
FETCH CHECK_SVC INTO V_RETURN_FL;
IF CHECK_SVC%NOTFOUND THEN
   OPEN CHECK_SO;
   FETCH CHECK_SO INTO V_RETURN_FL;
   IF CHECK_SO%NOTFOUND THEN
      V_RETURN_FL := 'N';
   END IF;
   CLOSE CHECK_SO;
END IF;
CLOSE CHECK_SVC;

RETURN V_RETURN_FL;

END FN_SVC_OR_SO_PROV;

FUNCTION get_cm_mac_min_max RETURN cm_tbl PIPELINED IS

 v_upstream_power_min    NUMBER;
 v_upstream_power_max    NUMBER;
 v_downstream_power_min  NUMBER;
 v_downstream_power_max  NUMBER;
 v_downstream_snr_min    NUMBER;
 v_rec                   installer_web_pkg.cm_rec;
 
BEGIN

v_upstream_power_min   := system_rules_pkg.get_num_value('SANITY','SANITY','UP PWR MIN');
v_upstream_power_max   := system_rules_pkg.get_num_value('SANITY','SANITY','UP PWR MAX');
v_downstream_power_min := system_rules_pkg.get_num_value('SANITY','SANITY','DOWN PWR MIN');
v_downstream_power_max := system_rules_pkg.get_num_value('SANITY','SANITY','DOWN PWR MAX');
v_downstream_snr_min   := system_rules_pkg.get_num_value('SANITY','SANITY','DOWN SNR MIN');

v_rec.upstream_power_min    := v_upstream_power_min;
v_rec.upstream_power_max    := v_upstream_power_max;
v_rec.downstream_power_min  := v_downstream_power_min;
v_rec.downstream_power_max  := v_downstream_power_max;
v_rec.downstream_snr_min    := v_downstream_snr_min;

PIPE ROW (v_rec);

RETURN;
EXCEPTION
 WHEN OTHERS THEN
  RETURN;
END;

PROCEDURE PR_SANITY_CHECK_SO_MSG(P_SVO_UID_PK IN NUMBER, P_MAC_ADDRESS IN VARCHAR) IS

V_STATUS_OVERALL  VARCHAR2(20);
V_MODEM_IS_ONLINE BOOLEAN;
V_ERROR_MESSAGE   VARCHAR2(1000);
V_SO_MESSAGE      VARCHAR2(1000);

BEGIN

SERVICE_DIAGNOSTICS.GET_CM_MAC(P_MAC_ADDRESS, V_MODEM_IS_ONLINE, V_STATUS_OVERALL, V_ERROR_MESSAGE);

IF V_STATUS_OVERALL = 'SUCCESS' THEN
   V_SO_MESSAGE := 'ALL PASSED IN THE SANITY CHECK';
ELSE
   V_SO_MESSAGE := V_ERROR_MESSAGE;
END IF;           
           
INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                 VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, USER, TRUNC(SYSDATE), SYSDATE, V_SO_MESSAGE);
                 
COMMIT;

END PR_SANITY_CHECK_SO_MSG;

FUNCTION INSERT_CABLE_MODEMS (p_mac         IN VARCHAR,
                              p_cdt_uid_pk  IN NUMBER,
                              p_prd_uid_pk  IN NUMBER,
                              p_acq_uid_pk  IN NUMBER) RETURN NUMBER IS
                               
v_cbm_uid_pk    NUMBER;
    
BEGIN

    SELECT CBM_SEQ.NEXTVAL
      INTO v_cbm_uid_pk
      FROM DUAL;
    
    INSERT INTO CABLE_MODEMS
      (CBM_MAC_ADDRESS,
       CBM_CABLE_MODEM_TYPES_UID_FK,
       CBM_CHARTER_FL,
       CBM_EXTERNAL_FL,
       CBM_PRODUCTS_UID_fK,
       CBM_CBL_MDM_STATUS_UID_FK,
       CBM_ACQUIRED_FL,
       CBM_ACQUISITIONS_UID_FK)
      VALUES
      (p_mac,
       p_cdt_uid_pk,
       'N',
       'N',
       p_prd_uid_pk,
       CODE_PKG.GET_PK('CBL_MDM_STATUS', 'AC'),
       'Y',
       p_acq_uid_pk
       );

    RETURN v_cbm_uid_pk;

END INSERT_CABLE_MODEMS;


/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_ADD_CONTROLLER(P_SVO_UID_PK IN NUMBER, P_SOO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MAC IN VARCHAR, p_system_name VARCHAR2)
RETURN VARCHAR IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
  SELECT IVL_UID_PK
    FROM INVENTORY_LOCATIONS
   WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

CURSOR GET_EMPLOYEE IS
 SELECT EMP_FNAME||' '||EMP_LNAME
   FROM EMPLOYEES
  WHERE EMP_UID_PK = P_EMP_UID_PK;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
  FROM CUSTOMERS, ACCOUNTS, SERVICES, SO_TYPES, SO
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;

CURSOR CHECK_EXISTS (P_CPE_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SO_CONTROLLERS
   WHERE SOO_SO_UID_FK = P_SVO_UID_PK
     AND SOO_CPE_UID_FK = P_CPE_UID_PK
     AND SOO_END_DATE IS NULL;
     
CURSOR get_cpe_type (cp_cpe_uid_pk IN NUMBER) IS
 SELECT  cpy_system_code
  FROM cpe, cpe_types
 WHERE cpe_uid_pk = cp_cpe_uid_pk
   AND cpe_cpe_types_uid_fk = cpy_uid_pk;

V_DUMMY                VARCHAR2(1);
V_ACCOUNT              VARCHAR2(200);
V_SVC_UID_PK           NUMBER;
V_IVL_UID_PK           NUMBER;
V_OSB_UID_PK           NUMBER;
V_OST_UID_PK           NUMBER;
V_IDENTIFIER           VARCHAR2(300);
V_DESCRIPTION          VARCHAR2(300);
V_EMP_NAME             VARCHAR2(300);
V_EQUIP_TYPE           VARCHAR2(20);
V_CPE_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_LAST_IVL_UID_PK      NUMBER;
V_LAST_IVL_DESCRIPTION VARCHAR2(200);
V_CPE_FOUND_FL         VARCHAR2(1) := 'N';
v_cpe_type             VARCHAR2(12);

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
CLOSE GET_IDENTIFIER;

--DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_CPE_UID_PK);

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'SERIAL# NOT FOUND.  PLEASE MAKE SURE YOU SCANNED THE CPE MAC ADDRESS';
ELSIF V_EQUIP_TYPE  != 'L' THEN
   RETURN 'PLEASE MAKE SURE A CPE IS SCANNED IN, THIS APPEARS TO BE ANOTHER PIECE OF EQUIPMENT .';
ELSE -- check the type of the CPE
  OPEN get_cpe_type(v_cpe_uid_pk);
  FETCH get_cpe_type INTO v_cpe_type;
  CLOSE get_cpe_type;
  IF v_cpe_type != 'CONTROLLER' THEN
    RETURN 'PLEASE MAKE SURE A CONTROLLER IS SCANNED IN, THIS APPEARS TO BE ANOTHER PIECE OF EQUIPMENT .';
  END IF;
END IF;

OPEN CHECK_EXISTS(V_CPE_UID_PK);
FETCH CHECK_EXISTS INTO V_DUMMY;
IF CHECK_EXISTS%FOUND THEN
   V_CPE_FOUND_FL := 'Y';
ELSE
   V_CPE_FOUND_FL := 'N';
END IF;
CLOSE CHECK_EXISTS;

--SECTION ONE TO CHECK FOR VALIDATION ISSUES

IF V_CPE_FOUND_FL = 'N' THEN
   IF V_IVL_UID_PK IS NULL THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
      RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
   END IF;

   --BOX STATUS CHECK
   V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_MAC, V_EQUIP_TYPE, V_DESCRIPTION);
   IF V_STATUS NOT IN ('AN','AU','RT') THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN CONTROLLER TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_DESCRIPTION);
      V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_MAC);
      RETURN 'THIS CONTROLLER IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
   END IF;

   --LOCATION CHECK
   IF V_IVL_UID_PK IS NOT NULL THEN
      V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_MAC);
      OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
      FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
      CLOSE LAST_LOCATION;

      IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
         IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
            BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN CONTROLLER TO '||V_IDENTIFIER||' '||P_MAC||' IS NOT FOUND ON THE TECHS TRUCK');
            RETURN 'THIS CONTROLLER IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE ADD THE CONTROLLER IN IWP TO YOUR TRUCK.';
         END IF;
      END IF;
   END IF;
END IF;

----------------------------------------------------------------------

IF V_EQUIP_TYPE = 'L' AND V_CPE_FOUND_FL = 'N' THEN

   UPDATE so_controllers SET soo_system_name = p_system_name,
                             soo_CPE_UID_FK =  v_cpe_uid_pk,
                             soo_START_DATE = SYSDATE
                WHERE soo_uid_pk = p_soo_uid_pk;
                                   

   BOX_MODEM_PKG.PR_ADD_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'ADD ACCT WEB');

   INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                          VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE CONTROLLER '||P_MAC||' WAS ADDED BY TECHNICIAN '||V_EMP_NAME);

   COMMIT;

   RETURN 'THE CPE HAS BEEN SUCCESSFULLY ADDED TO THE SERVICE.';

END IF;

IF V_EQUIP_TYPE = 'L' AND V_CPE_FOUND_FL = 'Y' THEN
   RETURN 'THE CONTROLLER HAS BEEN SUCCESSFULLY ADDED TO THE SERVICE.';
ELSE
   RETURN 'THERE WAS AN ISSUE WITH ADDING THE CONTROLLER PLEASE CONTACT THE HELPDESK';
END IF;

END FN_ADD_CONTROLLER;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_REMOVE_CONTROLLER(P_SVO_UID_PK IN NUMBER, P_SOO_UID_PK NUMBER, P_EMP_UID_PK IN NUMBER, P_MAC IN VARCHAR, P_ADD_FL IN VARCHAR)

RETURN VARCHAR

IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
  FROM SERVICES, SO, SO_TYPES
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;


V_IVL_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_EQUIP_TYPE           VARCHAR2(1);
V_CPE_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_TIME                 VARCHAR2(200);
V_IDENTIFIER           VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);


BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
CLOSE GET_IDENTIFIER;

--DTERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_CPE_UID_PK);

IF V_IVL_UID_PK IS NULL THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
   RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
END IF;

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
END IF;

--THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

IF V_EQUIP_TYPE = 'L' THEN
   
   UPDATE SO_CONTROLLERS
      SET SOO_CPE_UID_FK = NULL
    WHERE SOO_CPE_UID_FK = V_CPE_UID_PK
      AND SOO_END_DATE IS NULL
      AND SOO_SO_UID_FK in (SELECT SVO_UID_PK
                              FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                             WHERE SVO_UID_PK = SOO_SO_UID_FK
                               AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                               AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                               AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                               AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
                               
   update service_controllers
      set svn_end_date = TRUNC(SYSDATE),
          svn_active_fl = 'N'
    where svn_cpe_uid_fk = V_CPE_UID_PK
      and svn_end_date is null;
   
  PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, 'THE CONTROLLERS '||P_MAC||' WAS REMOVED BY TECHNICIAN '||V_EMP_NAME, P_EMP_UID_PK, 'S');

END IF;

COMMIT;

IF P_ADD_FL = 'N' THEN
   OPEN GET_UNKNOWN_LOC;
   FETCH GET_UNKNOWN_LOC INTO V_IVL_UID_PK;
   CLOSE GET_UNKNOWN_LOC;   
END IF;

V_STATUS := 'REMOVE INSTALLATION';
BOX_MODEM_PKG.PR_REMOVE_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, V_STATUS, V_IVL_UID_PK);

COMMIT;

IF P_ADD_FL = 'N' THEN
   RETURN 'CONTROLLER SUCESSFULLY REMOVED FROM THE ACCOUNT';
ELSE
   RETURN 'CONTROLLER SUCESSFULLY REMOVED FROM THE ACCOUNT AND ADDED TO YOUR INVENTORY.';
END IF;

END FN_REMOVE_CONTROLLER;

FUNCTION FN_CONTROLLER_DISPLAY(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

CURSOR so_controller IS
SELECT cpe_mac_address, prd_vend_code, soo_uid_pk, cpy_code, soo_system_name, cpe_serial_number, man_name,
       soo_splashpage_url
  FROM so_controllers, cpe, products, cpe_types, manufacturers
 WHERE prd_uid_pk(+) = cpe_products_uid_fk
   AND cpy_uid_pk(+) = cpe_cpe_types_uid_fk
   AND cpe_uid_pk(+) = soo_cpe_uid_fk
   AND soo_so_uid_fk = p_svo_uid_pk
   AND soo_end_date IS NULL
   AND man_uid_pk(+) = cpe_manufacturers_uid_fk
 ORDER BY cpe_mac_address;
 
CURSOR service_controller IS
SELECT cpe_mac_address, prd_vend_code, svn_uid_pk, cpy_code, svn_system_name, cpe_serial_number, man_name,
       svn_splashpage_url
  FROM service_controllers, cpe, products, cpe_types, manufacturers
 WHERE prd_uid_pk(+) = cpe_products_uid_fk
   AND cpy_uid_pk = cpe_cpe_types_uid_fk
   AND cpe_uid_pk = svn_cpe_uid_fk
   AND svn_services_uid_fk = p_svc_uid_pk
   AND man_uid_pk(+) = cpe_manufacturers_uid_fk
   AND svn_end_date IS NULL
 ORDER BY cpe_mac_address;

rec     so_controller%ROWTYPE;
rec2    service_controller%ROWTYPE;
v_rec   generic_data_type;

BEGIN

IF p_svo_uid_pk IS NOT NULL THEN

 OPEN so_controller;
 LOOP
    FETCH so_controller INTO rec;
    EXIT WHEN so_controller%NOTFOUND;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1  := rec.CPE_MAC_ADDRESS;
     v_rec.gdt_alpha2  := rec.prd_vend_code;
     v_rec.gdt_alpha3  := rec.soo_uid_pk;
     v_rec.gdt_alpha4  := rec.cpy_code;
     v_rec.gdt_alpha5  := rec.man_name;
     v_rec.gdt_alpha6  := rec.soo_system_name;
     v_rec.gdt_alpha7  := rec.cpe_serial_number;
     v_rec.gdt_alpha8  := rec.soo_splashpage_url;

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE so_controller;
  
ELSIF p_svc_uid_pk IS NOT NULL THEN

 OPEN service_controller;
 LOOP
    FETCH service_controller into rec2;
    EXIT WHEN service_controller%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1  := rec2.cpe_mac_address;
     v_rec.gdt_alpha2  := rec2.prd_vend_code;
     v_rec.gdt_alpha3  := rec2.svn_uid_pk;
     v_rec.gdt_alpha4  := rec2.cpy_code;
     v_rec.gdt_alpha5  := rec2.man_name;
     v_rec.gdt_alpha6  := rec2.svn_system_name;
     v_rec.gdt_alpha7  := rec2.cpe_serial_number; 
     v_rec.gdt_alpha8  := rec2.svn_splashpage_url;    

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE service_controller;

END IF;

RETURN;

END FN_CONTROLLER_DISPLAY;


FUNCTION FN_ADD_SWITCH(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MAC IN VARCHAR2, P_LOCATION_NAME VARCHAR2, P_MANAGED_FL VARCHAR2)
RETURN VARCHAR IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
  SELECT IVL_UID_PK
    FROM INVENTORY_LOCATIONS
   WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

CURSOR GET_EMPLOYEE IS
 SELECT EMP_FNAME||' '||EMP_LNAME
   FROM EMPLOYEES
  WHERE EMP_UID_PK = P_EMP_UID_PK;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
  FROM CUSTOMERS, ACCOUNTS, SERVICES, SO_TYPES, SO
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;

CURSOR CHECK_EXISTS (P_CPE_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SO_SWITCHES
   WHERE SOI_SO_UID_FK = P_SVO_UID_PK
     AND SOI_CPE_UID_FK = P_CPE_UID_PK
     AND SOI_END_DATE IS NULL;

CURSOR get_cpe_type (cp_cpe_uid_pk IN NUMBER) IS
 SELECT  cpy_system_code
  FROM cpe, cpe_types
 WHERE cpe_uid_pk = cp_cpe_uid_pk
   AND cpe_cpe_types_uid_fk = cpy_uid_pk;


V_DUMMY                VARCHAR2(1);
V_ACCOUNT              VARCHAR2(200);
V_SVC_UID_PK           NUMBER;
V_IVL_UID_PK           NUMBER;
V_OSB_UID_PK           NUMBER;
V_OST_UID_PK           NUMBER;
V_IDENTIFIER           VARCHAR2(300);
V_DESCRIPTION          VARCHAR2(300);
V_EMP_NAME             VARCHAR2(300);
V_EQUIP_TYPE           VARCHAR2(20);
V_CPE_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_LAST_IVL_UID_PK      NUMBER;
V_LAST_IVL_DESCRIPTION VARCHAR2(200);
V_CPE_FOUND_FL         VARCHAR2(1) := 'N';
v_cpe_type             VARCHAR2(12);


BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
CLOSE GET_IDENTIFIER;


--DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_CPE_UID_PK);

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'SERIAL# NOT FOUND.  PLEASE MAKE SURE YOU SCANNED THE CPE MAC ADDRESS';
ELSIF V_EQUIP_TYPE  != 'L' THEN
   RETURN 'PLEASE MAKE SURE A CPE IS SCANNED IN, THIS APPEARS TO BE ANOTHER PIECE OF EQUIPMENT .';
ELSE
  OPEN get_cpe_type(v_cpe_uid_pk);
  FETCH get_cpe_type INTO v_cpe_type;
  CLOSE get_cpe_type;
  IF v_cpe_type != 'SWITCH' THEN
    RETURN 'PLEASE MAKE SURE A SWITCH IS SCANNED IN, THIS APPEARS TO BE ANOTHER PIECE OF EQUIPMENT .';
  END IF;

END IF;

OPEN CHECK_EXISTS(V_CPE_UID_PK);
FETCH CHECK_EXISTS INTO V_DUMMY;
IF CHECK_EXISTS%FOUND THEN
   V_CPE_FOUND_FL := 'Y';
ELSE
   V_CPE_FOUND_FL := 'N';
END IF;
CLOSE CHECK_EXISTS;

--SECTION ONE TO CHECK FOR VALIDATION ISSUES

IF V_CPE_FOUND_FL = 'N' THEN
   IF V_IVL_UID_PK IS NULL THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
      RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
   END IF;

   --BOX STATUS CHECK
   V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_MAC, V_EQUIP_TYPE, V_DESCRIPTION);
   IF V_STATUS NOT IN ('AN','AU','RT') THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN SWITCH TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_DESCRIPTION);
      V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_MAC);
      RETURN 'THIS SWITCH IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
   END IF;

   --LOCATION CHECK
   IF V_IVL_UID_PK IS NOT NULL THEN
      V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_MAC);
      OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
      FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
      CLOSE LAST_LOCATION;

      IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
         IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
            BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN SWITCH TO '||V_IDENTIFIER||' '||P_MAC||' IS NOT FOUND ON THE TECHS TRUCK');
            RETURN 'THIS SWITCH IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE ADD THE SWITCH IN IWP TO YOUR TRUCK.';
         END IF;
      END IF;
   END IF;
END IF;

----------------------------------------------------------------------

IF V_EQUIP_TYPE = 'L' AND V_CPE_FOUND_FL = 'N' THEN

   INSERT INTO SO_SWITCHES(SOI_UID_PK, SOI_SO_UID_FK, SOI_CPE_UID_FK, SOI_START_DATE, SOI_END_DATE, SOI_ACTIVE_FL, SOI_LOCATION_NAME, SOI_MANAGED_FL)
               VALUES(SOI_SEQ.NEXTVAL, P_SVO_UID_PK, V_CPE_UID_PK, TRUNC(SYSDATE), NULL, 'Y', p_location_name, p_managed_fl);
                                   

   BOX_MODEM_PKG.PR_ADD_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'ADD ACCT WEB');

   INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                          VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE SWITCH '||P_MAC||' WAS ADDED BY TECHNICIAN '||V_EMP_NAME);

   COMMIT;

   RETURN 'THE SWITCH HAS BEEN SUCCESSFULLY ADDED TO THE SERVICE.';

END IF;

IF V_EQUIP_TYPE = 'L' AND V_CPE_FOUND_FL = 'Y' THEN
   RETURN 'THE SWITCH HAS BEEN SUCCESSFULLY ADDED TO THE SERVICE.';
ELSE
   RETURN 'THERE WAS AN ISSUE WITH ADDING THE SWITCH PLEASE CONTACT THE HELPDESK';
END IF;

END FN_ADD_SWITCH;

/*-------------------------------------------------------------------------------------------------------------*/
FUNCTION FN_REMOVE_SWITCH(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MAC IN VARCHAR2, P_ADD_FL IN VARCHAR2)

RETURN VARCHAR

IS

CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
  FROM SERVICES, SO, SO_TYPES
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;


V_IVL_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_EQUIP_TYPE           VARCHAR2(1);
V_CPE_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_TIME                 VARCHAR2(200);
V_IDENTIFIER           VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);


BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
CLOSE GET_IDENTIFIER;

--DTERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_CPE_UID_PK);

IF V_IVL_UID_PK IS NULL THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
   RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
END IF;

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
END IF;

--THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

IF V_EQUIP_TYPE = 'L' THEN
   
   UPDATE SO_SWITCHES
      SET SOI_END_DATE = TRUNC(SYSDATE),
          SOI_ACTIVE_FL= 'N'
    WHERE SOI_CPE_UID_FK = V_CPE_UID_PK
      AND SOI_END_DATE IS NULL
      AND SOI_SO_UID_FK in (SELECT SVO_UID_PK
                              FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                             WHERE SVO_UID_PK = SOI_SO_UID_FK
                               AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                               AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                               AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                               AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
                               
   update service_switches
      set svs_end_date = TRUNC(SYSDATE),
          svs_active_fl = 'N'
    where svs_cpe_uid_fk = V_CPE_UID_PK
      and svs_end_date is null;
   
  PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, 'THE SWITCH '||P_MAC||' WAS REMOVED BY TECHNICIAN '||V_EMP_NAME, P_EMP_UID_PK, 'S');

END IF;

COMMIT;

IF P_ADD_FL = 'N' THEN
   OPEN GET_UNKNOWN_LOC;
   FETCH GET_UNKNOWN_LOC INTO V_IVL_UID_PK;
   CLOSE GET_UNKNOWN_LOC;   
END IF;

V_STATUS := 'REMOVE INSTALLATION';
BOX_MODEM_PKG.PR_REMOVE_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, V_STATUS, V_IVL_UID_PK);

COMMIT;

IF P_ADD_FL = 'N' THEN
   RETURN 'SWITCH SUCESSFULLY REMOVED FROM THE ACCOUNT';
ELSE
   RETURN 'SWITCH SUCESSFULLY REMOVED FROM THE ACCOUNT AND ADDED TO YOUR INVENTORY.';
END IF;

END FN_REMOVE_SWITCH;


FUNCTION FN_SWITCH_DISPLAY(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS

CURSOR SWITCH_SO IS
SELECT cpe_mac_address, prd_vend_code, soi_uid_pk, cpy_code, soi_location_name, soi_managed_fl, man_name
  FROM SO_SWITCHES, CPE, PRODUCTS, CPE_TYPES, manufacturers
 WHERE PRD_UID_PK(+) = CPE_PRODUCTS_UID_FK
   AND CPY_UID_PK = CPE_CPE_TYPES_UID_FK
   AND CPE_UID_PK = SOI_CPE_UID_FK
   AND SOI_SO_UID_FK = P_SVO_UID_PK
   AND SOI_END_DATE IS NULL
   AND MAN_UID_PK(+) = CPE_MANUFACTURERS_UID_FK
 ORDER BY CPE_MAC_ADDRESS;
 
CURSOR SWITCH_SERVICES IS
SELECT cpe_mac_address, prd_vend_code, svs_uid_pk, cpy_code, svs_location_name, svs_managed_fl, man_name
  FROM SERVICE_SWITCHES, CPE, PRODUCTS, CPE_TYPES, manufacturers
 WHERE PRD_UID_PK(+) = CPE_PRODUCTS_UID_FK
   AND CPY_UID_PK = CPE_CPE_TYPES_UID_FK
   AND CPE_UID_PK = SVS_CPE_UID_FK
   AND SVS_SERVICES_UID_FK = P_SVC_UID_PK
   AND SVS_END_DATE IS NULL
   AND MAN_UID_PK(+) = CPE_MANUFACTURERS_UID_FK
 ORDER BY CPE_MAC_ADDRESS;
 
 
 CURSOR get_so_feat(cp_svo_uid_pk NUMBER) IS
  SELECT sof_quantity
   FROM so_features, office_serv_feats, features
  WHERE sof_so_uid_fk = cp_svo_uid_pk
    AND sof_action_fl != 'D'
    AND sof_office_serv_feats_uid_fk = osf_uid_pk
    AND osf_features_uid_fk = ftp_uid_pk
    AND INSTR(SYSTEM_RULES_PKG.GET_CHAR_VALUE('COMM WIFI','FTP_CODES','SWITCH'),ftp_code)>0;

rec     SWITCH_SO%rowtype;
rec2    SWITCH_SERVICES%rowtype;
v_rec   generic_data_type;
v_qty   NUMBER;
v_count NUMBER := 0;

BEGIN

IF P_SVO_UID_PK IS NOT NULL THEN

 -- get number of swithes that are supposed to be on SO
 OPEN get_so_feat(p_svo_uid_pk);
 FETCH get_so_feat INTO v_qty;
 CLOSE get_so_feat;

 OPEN switch_SO;
 LOOP
    FETCH switch_SO into rec;
    EXIT WHEN switch_SO%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1  := rec.CPE_MAC_ADDRESS;
     v_rec.gdt_alpha2  := rec.prd_vend_code;
     v_rec.gdt_alpha3  := rec.soi_UID_PK;
     v_rec.gdt_alpha4  := rec.cpy_code;
     v_rec.gdt_alpha5  := rec.man_name;
     v_rec.gdt_alpha6  := rec.soi_location_name;
     v_rec.gdt_alpha7  := rec.soi_managed_fl;
     
     v_count := v_count +1;


     PIPE ROW (v_rec);
  END LOOP;

  CLOSE switch_SO;
  
  IF v_count < v_qty THEN
    FOR i in 1..v_qty-v_count LOOP
     v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
     PIPE ROW (v_rec);
     
    END LOOP;
  
  END IF;
  
ELSIF P_SVC_UID_PK IS NOT NULL THEN

 OPEN switch_SERVICES;
 LOOP
    FETCH switch_SERVICES into rec2;
    EXIT WHEN switch_SERVICES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1  := rec2.CPE_MAC_ADDRESS;
     v_rec.gdt_alpha2  := rec2.prd_vend_code;
     v_rec.gdt_alpha3  := rec2.svs_UID_PK;
     v_rec.gdt_alpha4  := rec2.cpy_code;
     v_rec.gdt_alpha5  := rec2.man_name;
     v_rec.gdt_alpha6  := rec2.svs_location_name;
     v_rec.gdt_alpha7  := rec2.svs_managed_fl;

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE switch_SERVICES;

END IF;

RETURN;

END FN_SWITCH_DISPLAY;

FUNCTION FN_ADD_AP(p_svo_uid_pk IN NUMBER, p_emp_uid_pK IN NUMBER, p_mac IN VARCHAR2, p_ctl_mac VARCHAR2, p_location_name IN VARCHAR2, p_ssid_list VARCHAR2)
RETURN VARCHAR IS


CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR LAST_LOCATION (P_IVL_DESCRIPTION IN VARCHAR) IS
  SELECT IVL_UID_PK
    FROM INVENTORY_LOCATIONS
   WHERE IVL_DESCRIPTION = P_IVL_DESCRIPTION;

CURSOR GET_EMPLOYEE IS
 SELECT EMP_FNAME||' '||EMP_LNAME
   FROM EMPLOYEES
  WHERE EMP_UID_PK = P_EMP_UID_PK;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
  FROM CUSTOMERS, ACCOUNTS, SERVICES, SO_TYPES, SO
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND CUS_UID_PK = ACC_CUSTOMERS_UID_FK
    AND ACC_UID_PK = SVC_ACCOUNTS_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;

CURSOR CHECK_EXISTS (P_CPE_UID_PK IN NUMBER) IS
  SELECT 'X'
    FROM SO_APS
   WHERE SOP_SO_UID_FK = P_SVO_UID_PK
     AND SOP_CPE_UID_FK = P_CPE_UID_PK
     AND SOP_END_DATE IS NULL;

CURSOR get_cpe_type (cp_cpe_uid_pk IN NUMBER) IS
 SELECT  cpy_system_code
  FROM cpe, cpe_types
 WHERE cpe_uid_pk = cp_cpe_uid_pk
   AND cpe_cpe_types_uid_fk = cpy_uid_pk;

CURSOR get_ctl (cp_svo_uid_pk NUMBER, cp_mac VARCHAR2) IS
 SELECT soo_uid_pk
   FROM so_controllers, cpe
  WHERE soo_so_uid_fk = cp_svo_uid_pk
    AND soo_cpe_uid_fk = cpe_uid_pk
    AND cpe_mac_address = UPPER(cp_mac)
    AND soo_end_date IS NULL;

V_DUMMY                VARCHAR2(1);
V_ACCOUNT              VARCHAR2(200);
V_SVC_UID_PK           NUMBER;
V_IVL_UID_PK           NUMBER;
V_OSB_UID_PK           NUMBER;
V_OST_UID_PK           NUMBER;
V_IDENTIFIER           VARCHAR2(300);
V_DESCRIPTION          VARCHAR2(300);
V_EMP_NAME             VARCHAR2(300);
V_EQUIP_TYPE           VARCHAR2(20);
V_CPE_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_LAST_IVL_UID_PK      NUMBER;
V_LAST_IVL_DESCRIPTION VARCHAR2(200);
V_CPE_FOUND_FL         VARCHAR2(1) := 'N';
v_cpe_type             VARCHAR2(12);
v_soo_uid_pk           NUMBER := NULL;
v_ssid_1               VARCHAR2(250);
v_ssid_2               VARCHAR2(250);
v_ssid_3               VARCHAR2(250);
v_ssid_4               VARCHAR2(250);
v_ssid_5               VARCHAR2(250);
v_ssid_6               VARCHAR2(250);
v_ssid_7               VARCHAR2(250);
v_ssid_8               VARCHAR2(250);
v_ssid_9               VARCHAR2(250);
v_ssid_10               VARCHAR2(250);
v_ssid_11              VARCHAR2(250);
v_ssid_12               VARCHAR2(250);
v_ssid_13               VARCHAR2(250);
v_ssid_14               VARCHAR2(250);
v_ssid_15              VARCHAR2(250);
v_ssid_16               VARCHAR2(250);
v_tbl_s                   string_pkg.string_tbl;

BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
CLOSE GET_IDENTIFIER;

--DETERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_CPE_UID_PK);

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'SERIAL# NOT FOUND.  PLEASE MAKE SURE YOU SCANNED THE CPE MAC ADDRESS';
ELSIF V_EQUIP_TYPE  != 'L' THEN
   RETURN 'PLEASE MAKE SURE A CPE IS SCANNED IN, THIS APPEARS TO BE ANOTHER PIECE OF EQUIPMENT .';
ELSE
  OPEN get_cpe_type(v_cpe_uid_pk);
  FETCH get_cpe_type INTO v_cpe_type; 
  CLOSE get_cpe_type;
  IF v_cpe_type != 'ACCESS POINT' THEN
    RETURN 'PLEASE MAKE SURE AN ACCESS POINT IS SCANNED IN, THIS APPEARS TO BE ANOTHER PIECE OF EQUIPMENT .';
  END IF;

END IF;

OPEN CHECK_EXISTS(V_CPE_UID_PK);
FETCH CHECK_EXISTS INTO V_DUMMY;
IF CHECK_EXISTS%FOUND THEN
   V_CPE_FOUND_FL := 'Y';
ELSE
   V_CPE_FOUND_FL := 'N';
END IF;
CLOSE CHECK_EXISTS;

--SECTION ONE TO CHECK FOR VALIDATION ISSUES

IF V_CPE_FOUND_FL = 'N' THEN
   IF V_IVL_UID_PK IS NULL THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
      RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
   END IF;

   --BOX STATUS CHECK
   V_STATUS := BOX_MODEM_PKG.FN_GET_SERIAL_STATUS(P_MAC, V_EQUIP_TYPE, V_DESCRIPTION);
   IF V_STATUS NOT IN ('AN','AU','RT') THEN
      BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN AP TO '||V_IDENTIFIER||' WITH A STATUS OF '||V_DESCRIPTION);
      V_ACCOUNT := BOX_MODEM_PKG.RETURN_ACTIVE_ACCOUNT(P_MAC);
      RETURN 'THIS AP IS MARKED AS '||V_DESCRIPTION||' AND CANNOT BE ASSIGNED TO A CUSTOMER';
   END IF;

   --LOCATION CHECK
   IF V_IVL_UID_PK IS NOT NULL THEN
      V_LAST_IVL_DESCRIPTION := BOX_MODEM_PKG.FN_GET_LAST_LOCATION(P_MAC);
      OPEN LAST_LOCATION(V_LAST_IVL_DESCRIPTION);
      FETCH LAST_LOCATION INTO V_LAST_IVL_UID_PK;
      CLOSE LAST_LOCATION;

      IF NVL(V_LAST_IVL_UID_PK,111111111) != V_IVL_UID_PK THEN
         IF V_LAST_IVL_DESCRIPTION != 'LOCATION NOT FOUND' THEN  --NOT FOUND IN INVENTORY SO AUTO ADD
            BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TRIED TO ASSIGN SWITCH TO '||V_IDENTIFIER||' '||P_MAC||' IS NOT FOUND ON THE TECHS TRUCK');
            RETURN 'THIS SWITCH IS NOT IN YOUR LOCATION AND IS LISTED IN '||V_LAST_IVL_DESCRIPTION||'.  PLEASE ADD THE SWITCH IN IWP TO YOUR TRUCK.';
         END IF;
      END IF;
   END IF;
END IF;

----------------------------------------------------------------------

IF V_EQUIP_TYPE = 'L' AND V_CPE_FOUND_FL = 'N' THEN
   
   IF p_ctl_mac IS NOT NULL AND UPPER(p_ctl_mac) != 'NULL' THEN
     OPEN get_ctl(p_svo_uid_pk, p_ctl_mac);
     FETCH get_ctl INTO v_soo_uid_pk;
     CLOSE get_ctl;
   
     IF v_soo_uid_pk IS NULL THEN
        RETURN 'THE ACCESS POINT COULD NOT BE TIED TO THE CONTROLLER '||p_ctl_mac;
     END IF;
   END IF;

   v_tbl_s := string_pkg.split(p_ssid_list, ',');

   
   FOR i IN 1..v_tbl_s.count LOOP
      IF i =1 THEN
       v_ssid_1 := v_tbl_s(i);
      ELSIF i=2 THEN
       v_ssid_2 := v_tbl_s(i);
      ELSIF i=3 THEN
       v_ssid_3 := v_tbl_s(i); 
      ELSIF i=4 THEN
       v_ssid_4 := v_tbl_s(i); 
      ELSIF i=5 THEN
       v_ssid_5 := v_tbl_s(i); 
      ELSIF i=6 THEN
       v_ssid_6 := v_tbl_s(i); 
      ELSIF i=7 THEN
       v_ssid_7 := v_tbl_s(i); 
      ELSIF i=8 THEN
       v_ssid_8 := v_tbl_s(i); 
      ELSIF i=9 THEN
       v_ssid_9 := v_tbl_s(i); 
      ELSIF i=10 THEN
       v_ssid_10 := v_tbl_s(i); 
      ELSIF i=11 THEN
       v_ssid_11 := v_tbl_s(i); 
      ELSIF i=12 THEN
       v_ssid_12 := v_tbl_s(i); 
      ELSIF i=13 THEN
       v_ssid_13 := v_tbl_s(i); 
      ELSIF i=14 THEN
       v_ssid_14 := v_tbl_s(i); 
      ELSIF i=15 THEN
       v_ssid_15 := v_tbl_s(i); 
      ELSIF i=16 THEN
       v_ssid_16 := v_tbl_s(i); 
      END IF;
     
   END LOOP;

   INSERT INTO SO_APS(SOP_UID_PK, SOP_SO_UID_FK, SOP_CPE_UID_FK, SOP_SO_CONTROLLERS_UID_FK, SOP_LOCATION_NAME, SOP_SSID1, SOP_SSID2, SOP_SSID3, SOP_SSID4, 
                      SOP_SSID5, SOP_SSID6, SOP_SSID7, SOP_SSID8, SOP_SSID9, SOP_SSID10, SOP_SSID11, SOP_SSID12, SOP_SSID13, SOP_SSID14, SOP_SSID15, 
                      SOP_SSID16, SOP_START_DATE, SOP_END_DATE, SOP_ACTIVE_FL)
               VALUES(sop_seq.NEXTVAL, p_svo_uid_pk, v_cpe_uid_pk,v_soo_uid_pk, p_location_name,v_ssid_1,v_ssid_2,v_ssid_3,v_ssid_4,
                      v_ssid_5,v_ssid_6,v_ssid_7,v_ssid_8,v_ssid_9,v_ssid_10,v_ssid_11,v_ssid_12,v_ssid_13,v_ssid_14,v_ssid_15,v_ssid_16,
                      TRUNC(SYSDATE), NULL, 'Y' );
                                   

   BOX_MODEM_PKG.PR_ADD_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, 'ADD ACCT WEB');

   INSERT INTO SO_MESSAGES(SOG_UID_PK, SOG_SO_UID_FK, SOG_ENTERED_BY, SOG_DATE, SOG_TIME, SOG_TEXT)
                          VALUES(SOG_SEQ.NEXTVAL, P_SVO_UID_PK, 'IWP', SYSDATE, SYSDATE, 'THE AP '||P_MAC||' WAS ADDED BY TECHNICIAN '||V_EMP_NAME);

   COMMIT;

   RETURN 'THE ACCESS POINT HAS BEEN SUCCESSFULLY ADDED TO THE SERVICE.';

END IF;

IF V_EQUIP_TYPE = 'L' AND V_CPE_FOUND_FL = 'Y' THEN
   RETURN 'THE ACCESS POINT HAS BEEN SUCCESSFULLY ADDED TO THE SERVICE.';
ELSE
   RETURN 'THERE WAS AN ISSUE WITH ADDING THE ACCESS POINT PLEASE CONTACT THE HELPDESK';
END IF;


END FN_ADD_AP;

FUNCTION FN_REMOVE_AP(p_svo_uid_pk IN NUMBER, p_emp_uid_pk IN NUMBER, p_mac IN VARCHAR2, p_add_fl IN VARCHAR2)
RETURN VARCHAR IS


CURSOR GET_TECH_LOCATION IS
 SELECT TEO_INV_LOCATIONS_UID_FK, EMP_FNAME||' '||EMP_LNAME
   FROM TECH_EMP_LOCATIONS, EMPLOYEES
  WHERE TEO_EMPLOYEES_UID_FK = P_EMP_UID_PK
    AND EMP_UID_PK = TEO_EMPLOYEES_UID_FK
    AND TEO_END_DATE IS NULL;

CURSOR GET_IDENTIFIER IS
  SELECT GET_IDENTIFIER_FUN(SVC_UID_PK, SVC_OFFICE_SERV_TYPES_UID_FK), SVC_UID_PK
  FROM SERVICES, SO, SO_TYPES
  WHERE SVC_UID_PK = SVO_SERVICES_UID_FK
    AND SOT_UID_PK = SVO_SO_TYPES_UID_FK
    AND SVO_UID_PK = P_SVO_UID_PK;


V_IVL_UID_PK           NUMBER;
V_SVC_UID_PK           NUMBER;
V_EQUIP_TYPE           VARCHAR2(1);
V_CPE_UID_PK           NUMBER;
V_STATUS               VARCHAR2(200);
V_DUMMY                VARCHAR2(1);
V_TIME                 VARCHAR2(200);
V_IDENTIFIER           VARCHAR2(200);
V_EMP_NAME             VARCHAR2(200);


BEGIN

--GET LOCATION/TRUCK TO MAKE SURE BOXES/MODEMS ARE AVAILABLE FOR
OPEN GET_TECH_LOCATION;
FETCH GET_TECH_LOCATION INTO V_IVL_UID_PK, V_EMP_NAME;
CLOSE GET_TECH_LOCATION;

OPEN GET_IDENTIFIER;
FETCH GET_IDENTIFIER INTO V_IDENTIFIER, V_SVC_UID_PK;
CLOSE GET_IDENTIFIER;

--DTERMINE IF THE SERIAL# PASSED IN IS A BOX OR MODEM
V_EQUIP_TYPE := BOX_MODEM_PKG.FN_DETERMINE_TYPE(P_MAC, V_CPE_UID_PK);

IF V_IVL_UID_PK IS NULL THEN
   BOX_MODEM_PKG.PR_EXCEPTION(P_MAC, V_IDENTIFIER, 'EXCEPTION', 'TECH IS NOT LINKED TO A TRUCK');
   RETURN 'THIS TECH IS NOT SET UP ON A TRUCK';
END IF;

--NOT FOUND
IF V_EQUIP_TYPE  = 'N' THEN
   RETURN 'MAC ADDRESS NOT FOUND.  PLEASE RETURN BACK TO THE WAREHOUSE.';
END IF;

--THIS WILL MAKE SURE THE BOX TYPE IS ON THE ORDER AND WILL INSERT/UPDATE THE PROPER RECORDS

IF V_EQUIP_TYPE = 'L' THEN
   
   UPDATE SO_APS
      SET SOP_END_DATE = TRUNC(SYSDATE),
          SOP_ACTIVE_FL= 'N'
    WHERE SOP_CPE_UID_FK = V_CPE_UID_PK
      AND SOP_END_DATE IS NULL
      AND SOP_SO_UID_FK in (SELECT SVO_UID_PK
                              FROM SO, SO_STATUS, OFF_SERV_SUBS, SERV_SUB_TYPES
                             WHERE SVO_UID_PK = SOP_SO_UID_FK
                               AND OSB_UID_PK = SVO_OFF_SERV_SUBS_UID_FK
                               AND SVT_UID_PK = OSB_SERV_SUB_TYPES_UID_FK
                               AND SOS_UID_PK = SVO_SO_STATUS_UID_FK
                               AND SOS_SYSTEM_CODE NOT IN ('VOID','CLOSED'));
                               
   update service_aps
      set svp_end_date = TRUNC(SYSDATE),
          svp_active_fl = 'N'
    where svp_cpe_uid_fk = V_CPE_UID_PK
      and svp_end_date is null;
   
  PR_INSERT_SO_MESSAGE(P_SVO_UID_PK, 'THE ACCESS POINT '||P_MAC||' WAS REMOVED BY TECHNICIAN '||V_EMP_NAME, P_EMP_UID_PK, 'S');

END IF;

COMMIT;

IF P_ADD_FL = 'N' THEN
   OPEN GET_UNKNOWN_LOC;
   FETCH GET_UNKNOWN_LOC INTO V_IVL_UID_PK;
   CLOSE GET_UNKNOWN_LOC;   
END IF;

V_STATUS := 'REMOVE INSTALLATION';
BOX_MODEM_PKG.PR_REMOVE_ACCT(P_MAC, V_IDENTIFIER, V_SVC_UID_PK, P_SVO_UID_PK, V_STATUS, V_IVL_UID_PK);

COMMIT;

IF P_ADD_FL = 'N' THEN
   RETURN 'ACCESS POINT SUCESSFULLY REMOVED FROM THE ACCOUNT';
ELSE
   RETURN 'ACCESS POINT SUCESSFULLY REMOVED FROM THE ACCOUNT AND ADDED TO YOUR INVENTORY.';
END IF;
END;

FUNCTION FN_AP_DISPLAY(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED IS 

CURSOR AP_SO IS
SELECT c1.cpe_mac_address, prd_vend_code, sop_uid_pk, cpy_code, sop_location_name, man_name,
       c2.cpe_mac_address ctl_mac, sop_ssid1, sop_ssid2,sop_ssid3,sop_ssid4,sop_ssid5,sop_ssid6,sop_ssid7,
       sop_ssid8,sop_ssid9,sop_ssid10,sop_ssid11,sop_ssid12,sop_ssid13,sop_ssid14,sop_ssid15,sop_ssid16
  FROM SO_APS, CPE c1, PRODUCTS, CPE_TYPES, manufacturers, cpe c2, so_controllers
 WHERE PRD_UID_PK(+) = c1.CPE_PRODUCTS_UID_FK
   AND CPY_UID_PK = c1.CPE_CPE_TYPES_UID_FK
   AND c1.CPE_UID_PK = SOP_CPE_UID_FK
   AND SOP_SO_UID_FK = P_SVO_UID_PK
   AND SOP_END_DATE IS NULL
   AND MAN_UID_PK(+) = c1.CPE_MANUFACTURERS_UID_FK
   AND soo_uid_pk(+) = sop_so_controllers_uid_fk
   AND c2.cpe_uid_pk(+) = soo_cpe_uid_fk
 ORDER BY 1;
 
CURSOR AP_SERVICES IS
SELECT c1.cpe_mac_address, prd_vend_code, svp_uid_pk, cpy_code, svp_location_name, man_name,
       c2.cpe_mac_address ctl_mac, svp_ssid1, svp_ssid2,svp_ssid3,svp_ssid4,svp_ssid5,svp_ssid6,svp_ssid7,
       svp_ssid8,svp_ssid9,svp_ssid10,svp_ssid11,svp_ssid12,svp_ssid13,svp_ssid14,svp_ssid15,svp_ssid16
  FROM SERVICE_APS, CPE c1, PRODUCTS, CPE_TYPES, manufacturers, cpe c2, service_controllers
 WHERE PRD_UID_PK(+) = c1.CPE_PRODUCTS_UID_FK
   AND CPY_UID_PK = c1.CPE_CPE_TYPES_UID_FK
   AND c1.CPE_UID_PK = SVP_CPE_UID_FK
   AND SVP_SERVICES_UID_FK = P_SVC_UID_PK
   AND SVP_END_DATE IS NULL
   AND MAN_UID_PK(+) = c1.CPE_MANUFACTURERS_UID_FK
   AND svn_uid_pk(+) = svp_svc_controllers_uid_fk
   AND c2.cpe_uid_pk(+) = svn_cpe_uid_fk
 ORDER BY 1;

 CURSOR get_so_feat(cp_svo_uid_pk NUMBER) IS
  SELECT sof_quantity
   FROM so_features, office_serv_feats, features
  WHERE sof_so_uid_fk = cp_svo_uid_pk
    AND sof_action_fl != 'D'
    AND sof_office_serv_feats_uid_fk = osf_uid_pk
    AND osf_features_uid_fk = ftp_uid_pk
    AND INSTR(SYSTEM_RULES_PKG.GET_CHAR_VALUE('COMM WIFI','FTP_CODES','AP'),ftp_code)>0;


rec     AP_SO%rowtype;
rec2    AP_SERVICES%rowtype;
v_rec   generic_data_type;
v_qty   NUMBER;
v_count NUMBER := 0;

BEGIN

IF P_SVO_UID_PK IS NOT NULL THEN

 -- get number of swithes that are supposed to be on SO
 OPEN get_so_feat(p_svo_uid_pk);
 FETCH get_so_feat INTO v_qty;
 CLOSE get_so_feat;

 OPEN ap_SO;
 LOOP
    FETCH ap_SO into rec;
    EXIT WHEN ap_SO%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1  := rec.CPE_MAC_ADDRESS;
     v_rec.gdt_alpha2  := rec.prd_vend_code;
     v_rec.gdt_alpha3  := rec.sop_UID_PK;
     v_rec.gdt_alpha4  := rec.cpy_code;
     v_rec.gdt_alpha5  := rec.man_name;
     v_rec.gdt_alpha6  := rec.sop_location_name;
     v_rec.gdt_alpha7  := rec.ctl_mac;
     v_rec.gdt_alpha8  := rec.sop_ssid1||','||rec.sop_ssid2||','||rec.sop_ssid3||','||rec.sop_ssid4||','||rec.sop_ssid5||','||rec.sop_ssid6||','||rec.sop_ssid7
                          ||','||rec.sop_ssid8||','||rec.sop_ssid9||','||rec.sop_ssid10||','||rec.sop_ssid11||','||rec.sop_ssid12||','||rec.sop_ssid13
                          ||','||rec.sop_ssid14||','||rec.sop_ssid15||','||rec.sop_ssid16;


     PIPE ROW (v_rec);
     
     v_count := v_count + 1;
     
  END LOOP;

  CLOSE ap_SO;

  IF v_count < v_qty THEN
    FOR i in 1..v_qty-v_count LOOP
     v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
     PIPE ROW (v_rec);
     
    END LOOP;
  
  END IF;

  
ELSIF P_SVC_UID_PK IS NOT NULL THEN

 OPEN ap_SERVICES;
 LOOP
    FETCH ap_SERVICES into rec2;
    EXIT WHEN ap_SERVICES%notfound;

    --set the fields
    v_rec   := generic_data_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

     v_rec.gdt_alpha1  := rec2.CPE_MAC_ADDRESS;
     v_rec.gdt_alpha2  := rec2.prd_vend_code;
     v_rec.gdt_alpha3  := rec2.svp_UID_PK;
     v_rec.gdt_alpha4  := rec2.cpy_code;
     v_rec.gdt_alpha5  := rec2.man_name;
     v_rec.gdt_alpha6  := rec2.svp_location_name;
     v_rec.gdt_alpha7  := rec2.ctl_mac;
     v_rec.gdt_alpha8  := rec2.svp_ssid1||','||rec2.svp_ssid2||','||rec2.svp_ssid3||','||rec2.svp_ssid4||','||rec2.svp_ssid5||','||rec2.svp_ssid6||','||rec2.svp_ssid7
                          ||','||rec2.svp_ssid8||','||rec2.svp_ssid9||','||rec2.svp_ssid10||','||rec2.svp_ssid11||','||rec2.svp_ssid12||','||rec2.svp_ssid13
                          ||','||rec2.svp_ssid14||','||rec2.svp_ssid15||','||rec2.svp_ssid16; 

     PIPE ROW (v_rec);
  END LOOP;

  CLOSE ap_SERVICES;

END IF;

RETURN;

END;

END;
/