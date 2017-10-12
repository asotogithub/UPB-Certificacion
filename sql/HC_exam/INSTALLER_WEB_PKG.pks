CREATE OR REPLACE PACKAGE ABEL_S.INSTALLER_WEB_PKG AS

-- AC  03/25/11 For Cable Modem Assignment project.  Mod ADD_BOX, REMOVE_BOX, SWAP_BOX, ADD_BOX_REPROVISION, FN_ADD_EMTA, 
--                   FN_REMOVE_EMTA, FN_SWAP_EMTA, FN_MAC_ADDRESS_CHANGE, FN_SWAP_RSU_FOR_EMTA.  
--                   Add new p_development_action parameter to handle development testing.  Add GET_CELL_NBR
-- AC  10/24/11 Add SET_INSIDE_WIR_TYPE for two pair non twist project
-- AC  01/07/13 Mod SWAP_BOX, ADD_BOX, and REMOVE_BOX to add optional parameter P_VALIDATE_ONLY_FL and to skip provisioning if an MMR cable box.  
--                Provisioning for this type of box is done through different mechanism 
--                Mod PR_INS_SO_ERROR_LOGS to add optional parameter P_SKIP_LOG_FL 
-- NJ  07/11/14 Added logic to include routers
-- NJJ 10/16/14 ADDED CPE equipment logic
-- NJJ 01/08/2015 ADDED INSERT INTO CABLE MODEM FUNCTION
-- SVA 12/04/2015 For  FN_ADD_ROUTER function add P_BILL_FL, and  P_TDP_UID_PK  parameters.
-- SVA 12/04/2015 For  FN_REMOVE_ROUTER function add P_TDP_UID_PK  parameter.

-- generic web installer so record
TYPE so_info_rec IS RECORD
    (cus_uid_pk       customers.cus_uid_pk%type,
     cus_name         varchar2(500),
     svo_uid_pk       so.svo_uid_pk%type,
     slo_uid_pk       service_locations.slo_uid_pk%type,
     slo_description  varchar2(500),
     sot_code         so_types.sot_code%type,
     sty_code         service_types.sty_code%type,
     schedule_date    varchar2(20),
     schedule_time    varchar2(20)
    );

TYPE so_info_tbl IS TABLE OF so_info_rec;

-- constants for forcing behavior in development
C_DEV_SUCCESS    CONSTANT VARCHAR2(1)  := 'S';
C_DEV_FAILURE    CONSTANT VARCHAR2(1)  := 'F';
C_DEV_PRODUCTION CONSTANT VARCHAR2(1)  := 'P';

FUNCTION IS_PRODUCTION_DATABASE RETURN VARCHAR2 ;

FUNCTION FN_GET_OPEN_SO_BY_TECH (P_EMP_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;

FUNCTION TEST_ADD_ONE(P_NUMBER_IN IN NUMBER)
RETURN NUMBER;

FUNCTION FN_CLOSE_ROUTE_ORDERS(P_EMP_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_COMMENT IN VARCHAR)

RETURN VARCHAR;

FUNCTION CHECK_CBM_STATUS(p_svo_uid_pk IN NUMBER,
                          p_msg        OUT VARCHAR2,
                          p_svc_uid_pk in number default null)
RETURN BOOLEAN;

FUNCTION TERMS_CONDITIONS_NEEDED(P_CUS_UID_PK IN NUMBER)
RETURN BOOLEAN;

FUNCTION CONTRACT_NEEDED(p_cus_uid_pk IN NUMBER, P_CONTRACT_END_DATE OUT DATE, P_SOF_UID_PK OUT NUMBER, P_TERM_AMOUNT OUT NUMBER, P_FTP_UID_PK OUT NUMBER, P_FTP_CODE OUT VARCHAR)

RETURN BOOLEAN;

PROCEDURE PR_INSERT_CUS_AGREEMENTS(P_CUS_UID_PK IN NUMBER, P_ACCEPT_FL IN VARCHAR);

FUNCTION GET_EMPLOYEE_PK
RETURN NUMBER;

PROCEDURE INS_SIA(p_emp_uid_pk IN NUMBER, p_svo_uid_pk IN NUMBER, P_xfer_fl IN VARCHAR, p_sia_action IN VARCHAR, p_ace_uid_pk IN NUMBER);

FUNCTION GET_CURRENT_USER
RETURN VARCHAR;

PROCEDURE PR_UPD_LOADING_START_TIME(P_SDS_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_DATETIME IN TIMESTAMP);

FUNCTION GET_CREATED_ORDER_REP(P_SDS_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION GET_CREATED_ORDER_SUP(P_SDS_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_RUN_SANITY(P_SVO_UID_PK IN NUMBER, p_svc_uid_pk in number default null)
RETURN VARCHAR;

FUNCTION SERV_SUB_AND_SO_TYPE(p_svo_uid_pk      IN NUMBER,
                              p_sty_system_code IN VARCHAR2,
                              p_svt_system_code IN VARCHAR2,
                              p_sot_system_code IN VARCHAR2) RETURN BOOLEAN;

FUNCTION GET_TERMS_TEXT(p_spanish_english_fl IN VARCHAR2)
RETURN CLOB;

FUNCTION GET_EMPLOYEE_PK_USER(P_LOGIN IN VARCHAR)
RETURN NUMBER;

PROCEDURE PR_GENERATE_EMAIL_LINK(P_CUS_UID_PK IN NUMBER);

FUNCTION FN_EMAIL_LINK_DATA (P_CUS_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;

FUNCTION DATETIME_TO_UNIX_TIME(P_DATETIME IN SO_LOADINGS.CREATED_DATE%TYPE)
RETURN NUMBER;

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
RETURN VARCHAR;

FUNCTION FN_GET_BOX_MODEM_QTY(P_SVO_UID_PK IN NUMBER)
RETURN NUMBER;

-- to remove and deprovision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect

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
                     P_VALIDATE_ONLY_FL   IN VARCHAR2 := 'N' );

-- to swap and deprovision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
--
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
                   P_VALIDATE_ONLY_FL   IN VARCHAR2 := 'N');

FUNCTION TEST_COPY(P_IN_PARM IN VARCHAR, P_OUT1_PARM OUT VARCHAR, P_OUT2_PARM OUT VARCHAR)
RETURN VARCHAR;

FUNCTION FN_CHECK_REFRESH_SVCS(PSVC_UID_PK IN NUMBER, PCMD_CTR IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_CHECK_EQUIPMENT_RETURNED(P_SERIAL# IN VARCHAR, P_SVC_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER)
RETURN BOOLEAN;

FUNCTION FN_CHECK_BOX_MODEM_PROVISIONED(P_SERIAL# IN VARCHAR, P_SVC_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER, PCMD_CTR IN NUMBER)
RETURN VARCHAR;


-- to reprovision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
--  NOTE see code in iwp to determine what conditions P_STRING runs system commands
FUNCTION ADD_BOX_REPROVISION(P_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_CUS_UID_PK IN NUMBER, P_SDS_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S')
  RETURN VARCHAR;

PROCEDURE SWAP_BOX_REPROVISION(P_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_CUS_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_PEARL_STRING OUT VARCHAR, P_CMDCTR OUT NUMBER);

PROCEDURE PR_EMAIL_BC_ORDER_NEEDED(P_SVO_UID_PK IN NUMBER);

PROCEDURE PR_INSERT_SO_MESSAGE(P_SVO_UID_PK IN NUMBER, P_COMMENT IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TYPE IN VARCHAR);

FUNCTION FN_DROP_ORDERS(P_EMP_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_COMMENT IN VARCHAR)

RETURN VARCHAR;

PROCEDURE PR_ACCESS_CODE_ORDERS(P_EMP_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_ACE_CODE IN VARCHAR, P_PCT IN NUMBER, P_COMMENT IN VARCHAR, P_SDS_UID_PK IN NUMBER);

PROCEDURE PR_HOLD_ORDER(P_EMP_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_PCT IN NUMBER, P_COMMENT IN VARCHAR, P_SDS_UID_PK IN NUMBER, P_DATETIME IN TIMESTAMP);

PROCEDURE NO_JOBS_BY_815;

PROCEDURE PAST_APPT_NOT_LOADED(P_TIME_PERIOD IN NUMBER);

PROCEDURE DOUBLE_LOADED_JOBS;

FUNCTION FN_CUS_LOGIN_UPDATE(P_CUS_UID_PK IN NUMBER, P_CUS_LOGIN IN VARCHAR, P_CUS_PASSWORD  IN VARCHAR, P_SEC_UID_PK IN NUMBER, P_SEC_ANSWER IN VARCHAR, P_CUS_EMAIL IN VARCHAR)
RETURN VARCHAR;

FUNCTION FN_TECH_STATUS_UPDATE(P_EMP_UID_PK IN NUMBER, P_SERIAL# IN VARCHAR, P_STATUS IN VARCHAR)
RETURN VARCHAR;

FUNCTION GET_IDENTIFIER_IWP(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER, P_TYPE IN VARCHAR)
RETURN VARCHAR;

FUNCTION BOX_MODEM_CHANGED(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_GET_SO_ASSIGNMENTS (P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;

FUNCTION FN_EMTA_ASSIGNMENTS (P_SON_UID_PK IN NUMBER, P_SVA_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;

FUNCTION FN_GET_PAIR_ASSIGNMENTS (P_SON_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;

FUNCTION FN_FTTH_ASSIGNMENTS (P_SON_UID_PK IN NUMBER, P_SVA_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;


FUNCTION FN_UPDATE_HSD_BONDED (P_SON_UID_PK IN NUMBER, P_HSD_FL VARCHAR, P_BONDED_FL VARCHAR)
RETURN VARCHAR;

-- to add and provision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
FUNCTION FN_ADD_EMTA(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_SON_UID_PK IN NUMBER, P_MEU_UID_PK IN NUMBER, P_MTA_MAC IN VARCHAR, P_CMAC_MAC IN VARCHAR, P_EMTA_TYPE IN VARCHAR, P_PORT_LINE# IN NUMBER, P_REMOVE_OLD_FL IN VARCHAR DEFAULT 'N', P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S')
RETURN VARCHAR;

FUNCTION FN_CHECK_BBS_STATUS(P_SLO_UID_PK IN NUMBER, P_TYPE IN VARCHAR, P_MTA_MAC OUT VARCHAR, P_CM_MAC OUT VARCHAR)
RETURN VARCHAR;

-- to add and provision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
FUNCTION FN_REMOVE_EMTA(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MEU_UID_PK IN NUMBER, P_MTA_MAC IN VARCHAR, P_CMAC_MAC IN VARCHAR, P_REUSE_FL IN VARCHAR, P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S')
RETURN VARCHAR;

-- to add and provision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
FUNCTION FN_SWAP_EMTA(P_OLD_SERIAL# IN VARCHAR, P_NEW_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S')
RETURN VARCHAR;

PROCEDURE CREATE_CS_ORDER(P_SVC_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_PORT IN NUMBER,
                          P_MTY_UID_PK IN NUMBER, P_SVO_UID_PK OUT NUMBER, P_RSU_# OUT VARCHAR, P_NEW_MTAMAC IN VARCHAR);

FUNCTION FN_CHECK_OTHER_SVC_CS_MS(P_SVO_UID_PK IN NUMBER, P_SAME_CUS_FL OUT VARCHAR, P_SVC_UID_PK OUT NUMBER)
RETURN VARCHAR;

FUNCTION FN_EMTA_LOCATION(P_SLO_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_MTA_ON_LOC(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER DEFAULT NULL)
RETURN VARCHAR;

FUNCTION FN_RSU_TO_MTA_DISPLAY(P_SLO_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;


-- to add and provision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
FUNCTION FN_SWAP_RSU_FOR_EMTA(P_OLD_SERIAL# IN VARCHAR, P_NEW_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_REUSABLE_FL IN VARCHAR, P_PORT IN NUMBER, P_RSU_REMOVED_FL IN VARCHAR,
                              P_SVC_UID_PK IN NUMBER, P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S')
RETURN VARCHAR;

FUNCTION FN_ADD_ADSL(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_SON_UID_PK IN NUMBER, P_MAC IN VARCHAR, P_GW_FL IN VARCHAR DEFAULT 'N')
RETURN VARCHAR;

FUNCTION FN_REMOVE_ADSL(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MAC IN VARCHAR, P_REUSE_FL IN VARCHAR, P_TRT_UID_PK IN NUMBER DEFAULT NULL, P_GW_FL IN VARCHAR DEFAULT 'N')
RETURN VARCHAR;

FUNCTION FN_SWAP_ADSL(P_OLD_SERIAL# IN VARCHAR, P_NEW_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_SVA_UID_PK IN NUMBER, P_ADD_FL IN VARCHAR, P_GW_FL IN VARCHAR DEFAULT 'N')
RETURN VARCHAR;

FUNCTION FN_GET_TROUBLE_HISTORY (P_CUS_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;

FUNCTION FN_GET_STATUS_OPTIONS
RETURN generic_data_table PIPELINED;

FUNCTION FN_GET_TRUCK_LOCATION(P_EMP_UID_PK IN NUMBER)
RETURN NUMBER;

FUNCTION FN_GET_SUP_TRUCK_LOCATIONS(P_EMP_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;

FUNCTION FN_TRANSFER_TRUCK_TO_TRUCK(P_IVL_UID_PK IN NUMBER, P_MAC_ADDRESS IN VARCHAR)
RETURN VARCHAR;

FUNCTION FN_OSSGATE_DEPROVISION(P_SVO_UID_PK IN NUMBER, P_ACTION_FL IN VARCHAR DEFAULT NULL)
RETURN VARCHAR;

FUNCTION FN_OSSGATE_REPROVISION(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR;

PROCEDURE PR_EMAIL_HELPDESK(P_MAIL_DIST_LIST_NAME IN VARCHAR, P_MESSAGE IN VARCHAR, P_SUBJ IN VARCHAR DEFAULT NULL);

FUNCTION FN_BOX_ON_OTHER_ACCT(P_SVC_UID_PK IN NUMBER, P_MAC_ADDRESS IN VARCHAR)
RETURN VARCHAR;

FUNCTION FN_TT_PLANT_LIST
RETURN generic_data_table PIPELINED;

FUNCTION FN_TT_FAULT_LIST
RETURN generic_data_table PIPELINED;

FUNCTION FN_TT_CAUSE_LIST
RETURN generic_data_table PIPELINED;

FUNCTION FN_TT_ACTION_LIST
RETURN generic_data_table PIPELINED;

FUNCTION FN_TT_RESOLUTION_LIST(P_FIND_VALUE IN VARCHAR  DEFAULT NULL)
RETURN generic_data_table PIPELINED;

FUNCTION FN_CLOSE_TROUBLE_TICKET(P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_COMMENT IN VARCHAR, P_PIT_UID_PK IN NUMBER,
                                 P_FAU_UID_PK IN NUMBER, P_CAU_UID_PK IN NUMBER, P_ATP_UID_PK IN NUMBER, P_REF_UID_PK IN NUMBER,
                                 P_TDG_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_TT_GROUPS
RETURN generic_data_table PIPELINED;

-- to add and provision two types of boxes:  1)  cable modem (equip_type = M) or 2)  set top (cable tv) box (equip_type = S) .   Called from IWP
--    p_development_action    'S' (default) - if run in development db, force to return successful result - skip provisioning code
--                            'F'           - if run in development db, force to return failure result - skip provisioning code
--                            'P'           - if run in development db, force to run the exact same way as production code (not sure why we'd ever use this, but leave open as possibility)
--                            'If run in production, then this parameter has no effect
FUNCTION FN_MAC_ADDRESS_CHANGE(P_OLD_CM_MAC IN VARCHAR, P_NEW_CM_MAC IN VARCHAR, P_NEW_MTA_MAC IN VARCHAR,
                               P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MEU_UID_PK IN NUMBER,
                               P_REMOVE_OLD_FL IN VARCHAR, P_DEVELOPMENT_ACTION IN VARCHAR2 := 'S')
RETURN VARCHAR;

FUNCTION FN_SAM_MAC_CHANGE(P_OLD_CM_MAC IN VARCHAR, P_NEW_CM_MAC IN VARCHAR, P_NEW_MTA_MAC IN VARCHAR)
RETURN VARCHAR;

PROCEDURE PR_UPDATE_MTA(P_SVC_UID_PK IN NUMBER, P_MTA_NEW_UID_PK IN NUMBER, P_MTA_OLD_UID_PK IN NUMBER, P_MTA_TYPE_SCANNED_UID_PK IN NUMBER);

FUNCTION FN_NISV_ON_ORDER(P_SVO_UID_PK IN NUMBER)
RETURN BOOLEAN;

FUNCTION FN_TECHNICIAN_LOADED(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_TT_PORT_CHG_DISPLAY(P_SLO_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;

FUNCTION FN_TT_PORT_CHANGE(P_SVA_UID_PK IN NUMBER, P_PORT IN NUMBER, P_EMP_UID_PK IN NUMBER, P_CMAC IN VARCHAR, P_MTAMAC IN VARCHAR, P_TDP_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_SWT_LOGS_ERROR(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR;

PROCEDURE PR_INSERT_SWT_LOGS(P_SVO_UID_PK IN NUMBER, P_SEQ_CODE IN VARCHAR, P_MSG IN VARCHAR, P_COMMAND IN VARCHAR, P_SUCCESS_FL IN VARCHAR DEFAULT 'N');

PROCEDURE PR_INSERT_SO_MESSAGE(P_SVO_UID_PK IN NUMBER, P_MSG IN VARCHAR);

PROCEDURE PR_INSERT_IWP_REPORTS(P_TITLE IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_MESSAGE IN CLOB, P_URL IN VARCHAR, P_REPORT IN CLOB);

FUNCTION FN_RFOG_LOCATION(P_SLO_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_RFOG_DISPLAY(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;

FUNCTION FN_ADD_RFOG(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MTA_MAC IN VARCHAR, P_CMAC_MAC IN VARCHAR)
RETURN VARCHAR;

FUNCTION FN_REMOVE_RFOG(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MTA_MAC IN VARCHAR, P_CMAC_MAC IN VARCHAR)
RETURN VARCHAR;

PROCEDURE PR_ADD_SO_WIRING(P_SO_UID_PK IN NUMBER, P_CATV_BOX_PK IN NUMBER, P_CABLE_TYPE_PK IN NUMBER, P_NETWORK_TYPE_PK IN NUMBER, P_PHYSICAL_LOCATION IN VARCHAR);

PROCEDURE PR_ADD_SERVICE_WIRING(P_SVC_UID_PK IN NUMBER, P_CATV_BOX_PK IN NUMBER, P_CABLE_TYPE_PK IN NUMBER, P_NETWORK_TYPE_PK IN NUMBER, P_PHYSICAL_LOCATION IN VARCHAR);

PROCEDURE PR_HAS_WIRING_DATA(P_CATV_BOX_PK IN NUMBER, P_JOB_TYPE IN VARCHAR, P_SVC_UID_PK IN NUMBER, P_HAS_DATA_FL OUT VARCHAR, P_WIRING_PK OUT NUMBER);

FUNCTION FN_WIRING_CABLES_LIST
RETURN generic_data_table PIPELINED;

FUNCTION FN_WIRING_NETWORKS_LIST
RETURN generic_data_table PIPELINED;

FUNCTION FN_MTA_TYPE(P_SLO_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_CHECK_USERNAME_NOT_EXISTS(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN BOOLEAN;

FUNCTION FN_CHECK_VALID_CMTS(P_SLO_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_MLH_CHECK(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_HSD_BEFORE_PHONE(P_USER_NAME IN VARCHAR2, P_CMAC_SCANNED IN VARCHAR2)
RETURN BOOLEAN;

FUNCTION FN_CHECK_VALID_LTG(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_CHECK_LEN_ASSGMNTS_SWT(P_SVO_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_CHECK_VALID_SVC_LEN(P_SVC_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_CHECK_STB_RECALL(P_SERIAL# IN VARCHAR, P_ACTION IN VARCHAR)
RETURN VARCHAR;

FUNCTION FN_GET_ISS_USERNAME(P_SVC_UID_PK IN NUMBER)
RETURN VARCHAR;

FUNCTION FN_CHECK_FOR_OTHER_SO_TYPE(P_STY_SYSTEM_CODE IN VARCHAR, P_SVC_UID_PK IN NUMBER, P_SVO_UID_PK IN NUMBER) 
RETURN BOOLEAN;

PROCEDURE PR_INS_SO_ERROR_LOGS(P_SVO_UID_PK         IN NUMBER, 
                               P_SEL_PROCEDURE_NAME IN VARCHAR, 
                               P_SEL_MESSAGE        IN VARCHAR,
                               P_SKIP_LOG_FL        IN VARCHAR2 := 'N');  -- to skip this procedure all together  
  															 
  -- fn to return tech's cell number so he can be notified by SMS that provisioning jobs are done
  --   used in IWP
  FUNCTION GET_CELL_NBR(p_emp_uid_pk    in number) RETURN VARCHAR2 ;


  -- AC  10/10/11  for two pair non-twist project
  PROCEDURE SET_INSIDE_WIR_TYPE (p_so_tt_fl   in varchar2,   -- SO or TT
                                 p_svo_trt_pk  in number,    -- SO or TT PK to set
                                 p_iwt_uid_pk  in number); -- inside_wir_type to set
                                 
FUNCTION FN_GET_REMOVAL_REASON(p_svo_uid_pk in number) RETURN VARCHAR2;

FUNCTION FN_ADD_ROUTER(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, 
                                          P_MAC IN VARCHAR, P_BILL_FL VARCHAR2 , P_TDP_UID_PK NUMBER)
RETURN VARCHAR;

FUNCTION FN_REMOVE_ROUTER(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, 
                                                P_MAC IN VARCHAR, P_ADD_FL IN VARCHAR, P_TDP_UID_PK NUMBER)
RETURN VARCHAR;

FUNCTION FN_SWAP_ROUTER(P_OLD_SERIAL# IN VARCHAR, P_NEW_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_ADD_FL IN VARCHAR)
RETURN VARCHAR;

FUNCTION FN_ROUTER_DISPLAY(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;

FUNCTION FN_ADD_CPE(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MAC IN VARCHAR)
RETURN VARCHAR;

FUNCTION FN_REMOVE_CPE(P_SVO_UID_PK IN NUMBER, P_EMP_UID_PK IN NUMBER, P_MAC IN VARCHAR, P_ADD_FL IN VARCHAR)
RETURN VARCHAR;

FUNCTION FN_SWAP_CPE(P_OLD_SERIAL# IN VARCHAR, P_NEW_SERIAL# IN VARCHAR, P_EMP_UID_PK IN NUMBER, P_TDP_UID_PK IN NUMBER, P_ADD_FL IN VARCHAR)
RETURN VARCHAR;

FUNCTION FN_CPE_DISPLAY(P_SVO_UID_PK IN NUMBER, P_SVC_UID_PK IN NUMBER)
RETURN generic_data_table PIPELINED;

FUNCTION FN_SVC_OR_SO_PROV(P_CUS_UID_PK IN NUMBER, P_MAC_ADDRESS IN VARCHAR)
RETURN VARCHAR;

TYPE cm_rec IS RECORD
    (upstream_power_min    NUMBER,
     upstream_power_max    NUMBER,
     downstream_power_min  NUMBER,
     downstream_power_max  NUMBER,
     downstream_snr_min    NUMBER
    );

TYPE cm_tbl IS TABLE OF cm_rec;

FUNCTION get_cm_mac_min_max RETURN cm_tbl PIPELINED;

PROCEDURE PR_SANITY_CHECK_SO_MSG(P_SVO_UID_PK IN NUMBER, P_MAC_ADDRESS IN VARCHAR);

FUNCTION INSERT_CABLE_MODEMS (p_mac         IN VARCHAR,
                              p_cdt_uid_pk  IN NUMBER,
                              p_prd_uid_pk  IN NUMBER,
                              p_acq_uid_pk  IN NUMBER) RETURN NUMBER;

end;
/