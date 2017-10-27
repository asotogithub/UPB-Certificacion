INSERT INTO cf_interests (
    code,int_description,type_interest,type_evaluation,start_date,end_date,status,start_user_code,
    end_user_code,tran_id
) VALUES (
    'PAGO_INT_PORC',
    'INTERES PAGADO POR MANTENIMIENTO DE CTTA DEL CLIENTE',
    'PAGO',
    'PORCENTAGE',
    SYSDATE,
    TO_DATE('12-31-9999','MM-DD-YYYY'),
    'A',
    USER,
    USER,
    -13
);

INSERT INTO cf_interests (
    code,int_description,type_interest,type_evaluation,start_date,end_date,status,start_user_code,
    end_user_code,tran_id
) VALUES (
    'COBRO_INT_PORC',
    'INTERES COBRADO POR MANTENIMIENTO DE CTTA',
    'COBRO',
    'PORCENTAGE',
    SYSDATE,
    TO_DATE('12-31-9999','MM-DD-YYYY'),
    'A',
    USER,
    USER,
    -13
);
