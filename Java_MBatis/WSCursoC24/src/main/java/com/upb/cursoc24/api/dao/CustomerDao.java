/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.upb.cursoc24.api.dao;

import com.upb.cursoc24.api.model.Customer;
import com.upb.cursoc24.api.model.TrAccount;
import com.upb.cursoc24.api.mybatis.MyBatisUtils;
import java.util.Date;
import org.apache.ibatis.session.SqlSession;

/**
 *
 * @author abel
 */
public class CustomerDao {

    public Customer getCustomerByName(String name) {
        return customerFactory();
    }

    protected Customer customerFactory() {
        Customer cus = new Customer("Abel", "Soto", "Obrajes 777", Long.MIN_VALUE, new Date());
        return cus;
    }
    
    
    public String getSysdate() throws Exception{
        SqlSession session = null;
        session = MyBatisUtils.beginTransaction();
        String resp =  (String) MyBatisUtils.selectOne("getSysdate", session);
        return resp;
    }
    
     public TrAccount getAccoutById(Long id) throws Exception{
        SqlSession session = null;
        session = MyBatisUtils.beginTransaction();
        TrAccount resp =  (TrAccount) MyBatisUtils.selectOne("getAccountById", id ,session);
        return resp;
    }

}
