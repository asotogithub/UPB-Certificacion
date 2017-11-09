/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.upb.cursoc24.api.dao;

import com.upb.cursoc24.api.model.Customer;
import java.util.Date;

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

}
