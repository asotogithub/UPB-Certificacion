--------------------------------------------------------
--  DDL for Package GLOBAL_VARIABLE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "BANK"."GLOBAL_VARIABLE" AS
    k_status_active CONSTANT TR_ACCOUNT.STATUS%TYPE := 'A';
    k_status_inactive CONSTANT TR_ACCOUNT.STATUS%TYPE := 'I';
    k_end_date        CONSTANT TR_ACCOUNT.END_DATE%TYPE := TO_DATE('31-12-9999','DD-MM-YYYY');

    k_tran_type_deposit CONSTANT TR_DAILY.TYPE_TRANSACTION%TYPE := 'DEPOSITO';
    k_tran_type_tranfer CONSTANT TR_DAILY.TYPE_TRANSACTION%TYPE := 'TRANSFERENCIA';
    k_tran_type_withdraw CONSTANT TR_DAILY.TYPE_TRANSACTION%TYPE := 'RETIRO';
    k_tran_type_init     CONSTANT TR_DAILY.TYPE_TRANSACTION%TYPE := 'APERTURA';


    g_param_in VARCHAR2(3000);

END;

/
