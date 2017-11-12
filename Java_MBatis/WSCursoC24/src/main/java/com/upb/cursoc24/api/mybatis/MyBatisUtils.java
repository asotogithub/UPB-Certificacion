/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.upb.cursoc24.api.mybatis;

import java.util.HashMap;
import java.util.List;
import org.apache.ibatis.session.SqlSession;

/**
 *
 * @author abel
 */
public class MyBatisUtils {

    private static final MyBatisBusinessLogic MY_BATIS_BUSINESS_LOGIC = new MyBatisBusinessLogic();

    public static List<?> selectList(String xmlMethod) throws Exception {
        return MY_BATIS_BUSINESS_LOGIC.selecList(xmlMethod);
    }

    public static List<?> selectList(String xmlMethod, Object parameter) throws Exception {
        return MY_BATIS_BUSINESS_LOGIC.selecList(xmlMethod, parameter);
    }

    public static Object selectOne(String xmlMethod) throws Exception {
        return MY_BATIS_BUSINESS_LOGIC.selectOne(xmlMethod);
    }

    public static Object selectOne(String xmlMethod, Object parameter) throws Exception {
        return MY_BATIS_BUSINESS_LOGIC.selectOne(xmlMethod, parameter);
    }

    public static List<?> selectList(String xmlMethod, SqlSession session) throws Exception {
        return MY_BATIS_BUSINESS_LOGIC.selecList(xmlMethod, session);
    }

    public static List<?> selectList(String xmlMethod, Object parameter, SqlSession session) throws Exception {
        return MY_BATIS_BUSINESS_LOGIC.selecList(xmlMethod, parameter, session);
    }

    public static Object selectOne(String xmlMethod, SqlSession session) throws Exception {
        return MY_BATIS_BUSINESS_LOGIC.selecOne(xmlMethod, session);
    }

    public static Object selectOne(String xmlMethod, Object parameter, SqlSession session) throws Exception {
        return MY_BATIS_BUSINESS_LOGIC.selecOne(xmlMethod, parameter, session);
    }

    public static void callProcedurePlsql(String xmlMethod, HashMap<String, Object> parameterMap) throws Exception {
        MY_BATIS_BUSINESS_LOGIC.callPLSqlStoredProcedure(xmlMethod, parameterMap);
    }

    public static void callProcedurePlsql(String xmlMethod, HashMap<String, Object> parameterMap, SqlSession session) throws Exception {
        MY_BATIS_BUSINESS_LOGIC.callPLSqlStoredProcedure(xmlMethod, parameterMap, session);
    }

    public static SqlSession beginTransaction() throws Exception {
        return MY_BATIS_BUSINESS_LOGIC.beginTransaction();
    }

    public static void commitTransaction(SqlSession session) throws Exception {
        MY_BATIS_BUSINESS_LOGIC.commitTransaction(session);
    }

    public static void rollbackTransaction(SqlSession session) throws Exception {
        MY_BATIS_BUSINESS_LOGIC.rollbackTransaction(session);
    }

    public static void endTransaction(SqlSession session) throws Exception {
        MY_BATIS_BUSINESS_LOGIC.endTransaction(session);
    }

}
