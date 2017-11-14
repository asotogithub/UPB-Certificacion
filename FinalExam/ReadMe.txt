
------------------------------------------------------------
1. Se debe adicionar el siguiente bloque que invoca al procedimiento almacenado
------------------------------------------------------------

<update id="accountSave" statementType="CALLABLE" 
            parameterType="java.util.Map">
        { CALL BANK.TX_PUBLIC_WEB.ACCOUNT_SAVE(
        #{pi_sald_ammount,jdbcType=NUMERIC,mode=IN},
        #{pi_start_user_code,jdbcType=VARCHAR,mode=IN},
        #{pi_end_user_code,jdbcType=VARCHAR,mode=IN},
        #{po_account_id,jdbcType=NUMERIC,mode=OUT, javaType=java.lang.Long},
        #{po_ok,jdbcType=VARCHAR,mode=OUT, javaType=java.lang.String},
        #{po_error_message,jdbcType=VARCHAR,mode=OUT, javaType=java.lang.String}
        ) }
    </update>


------------------------------------------------------------
2. En el DAO java file, se debe crear un metodo que devuelba el valor de la ctta adicionada.
------------------------------------------------------------

public Long accountSave(String userName) throws Exception {
        SqlSession session;
        session = MyBatisUtils.beginTransaction();
        Long resul;
        HashMap parameter = new HashMap<String, Object>();
        parameter.put("pi_sald_ammount", 101L);
        parameter.put("pi_start_user_code", userName);
        parameter.put("pi_end_user_code", userName);

        MyBatisUtils.callProcedurePlsql("accountSave", parameter, session);

        if (parameter.get("po_ok").equals("OK")) {
            resul = (Long) parameter.get("po_account_id");
            MyBatisUtils.commitTransaction(session);
        } else {
            MyBatisUtils.rollbackTransaction(session);
            return null;
        }

        return resul;

    }

------------------------------------------------------------
3. Implementar el servicio REST (endPoint) para consumir el servicio.
------------------------------------------------------------
@POST
    @Path("/CreateAccount/{userName}")
    @Produces({MediaType.APPLICATION_JSON, MediaType.TEXT_XML})
    @Consumes({MediaType.APPLICATION_JSON, MediaType.TEXT_XML})
    public Response createAccount(@PathParam("userName") String user, Customer customer) throws Exception{
        Long accountId = dao.accountSave(user);
        customer.setAccountId(accountId);
        return Response.status(Response.Status.OK).entity(customer).build();
    }

------------------------------------------------------------
4. Prueba de funcionamiento.
------------------------------------------------------------
4.1. mvn clean install
4.2. mvn tomcat7:redeploy
POST service.
url: http://localhost:8080/WSCursoC24-1.0/Customers/CreateAccount/[Student_account]

body
{
"address": "Obrajes 777",
"firstName": "Name 1",
"lastName": "Name 2",
"startDate": "2017-11-14T19:40:50.690-04:00"
}



