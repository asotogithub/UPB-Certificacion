/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.upb.cursoc24.api.mybatis;

import java.io.Reader;
import java.util.HashMap;
import java.util.List;
import org.apache.ibatis.io.Resources;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;

/**
 *
 * @author abel
 */
public class MyBatisBusinessLogic {

    private String resource;
    private SqlSessionFactory sqlSessionFactory;

    public MyBatisBusinessLogic() {
        this(Constants.MY_BATIS_PATH);

    }

    public MyBatisBusinessLogic(String resource) {
        this.resource = resource;
        initSessionFactory();
    }

    private void initSessionFactory() {
        try {
            Reader reader = Resources.getResourceAsReader(this.resource);
            SqlSessionFactoryBuilder sqlSessionFactoryBuilder = new SqlSessionFactoryBuilder();
            sqlSessionFactory = sqlSessionFactoryBuilder.build(reader);
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    public SqlSession beginTransaction() throws Exception {
        return sqlSessionFactory.openSession();
    }

    public void commitTransaction(SqlSession session) throws Exception {
        session.commit(true);
        session.close();
    }

    public void rollbackTransaction(SqlSession session) throws Exception {
        session.rollback();
        session.close();
    }

    public void endTransaction(SqlSession session) throws Exception {
        session.close();
    }

    public List<?> selecList(String xmlMethod) throws Exception {
        List<?> result = null;
        SqlSession session = this.beginTransaction();
        result = session.selectList(xmlMethod);
        this.endTransaction(session);
        return result;
    }

    public List<?> selecList(String xmlMethod, Object paramenter) throws Exception {
        List<?> result = null;
        SqlSession session = this.beginTransaction();
        result = session.selectList(xmlMethod, paramenter);
        this.endTransaction(session);
        return result;
    }

    public Object selectOne(String xmlMethod) throws Exception {
        Object result = null;
        SqlSession session = this.beginTransaction();
        result = session.selectOne(xmlMethod);
        this.endTransaction(session);
        return result;
    }

    public Object selectOne(String xmlMethod, Object parameter) throws Exception {
        Object result = null;
        SqlSession session = this.beginTransaction();
        result = session.selectOne(xmlMethod, parameter);
        this.endTransaction(session);
        return result;
    }

    public List<?> selecList(String xmlMethod, SqlSession session) throws Exception {
        return session.selectList(xmlMethod);
    }

    public List<?> selecList(String xmlMethod, Object parameter, SqlSession session) throws Exception {
        return session.selectList(xmlMethod, parameter);
    }

    public Object selecOne(String xmlMethod, SqlSession session) throws Exception {
        return session.selectOne(xmlMethod);
    }

    public Object selecOne(String xmlMethod, Object parameter, SqlSession session) throws Exception {
        return session.selectOne(xmlMethod, parameter);

    }

    public void callPLSqlStoredProcedure(String xmlMethod, HashMap<String, Object> parameterMap, SqlSession session) throws Exception {
        session.selectOne(xmlMethod, parameterMap);
    }

    public void callPLSqlStoredProcedure(String xmlMethod, HashMap<String, Object> parameterMap) throws Exception {
        SqlSession session = this.beginTransaction();
        session.selectOne(xmlMethod, parameterMap);
        this.commitTransaction(session);
    }

}
