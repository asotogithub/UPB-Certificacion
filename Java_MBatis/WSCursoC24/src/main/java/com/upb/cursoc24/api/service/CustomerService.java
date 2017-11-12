/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.upb.cursoc24.api.service;

import com.upb.cursoc24.api.dao.CustomerDao;
import com.upb.cursoc24.api.model.Customer;
import com.upb.cursoc24.api.model.TrAccount;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

/**
 *
 * @author abel
 */
@Path("/Customers")
public class CustomerService {

    CustomerDao dao;

    public CustomerService() {
        dao = new CustomerDao();
    }

    @GET
    @Path("/hello/{name}")
    @Produces({MediaType.APPLICATION_JSON, MediaType.TEXT_XML})
    public Response getHello(@PathParam("name") String nameImput) throws Exception {
        String fechaActual = dao.getSysdate();
        String resp = "Hello !!  " + nameImput + "  " + fechaActual;
        return Response.status(Response.Status.OK).entity(resp).build();
    }

    @GET
    @Path("/{id}")
    @Produces({MediaType.APPLICATION_JSON, MediaType.TEXT_XML})
    public Response getCustomerByName(@PathParam("id") Long id) throws Exception {
        TrAccount account = dao.getAccoutById(id);
        return Response.status(Response.Status.OK).entity(account).build();
    }
    
    @POST
    @Path("/Create")
    @Produces({MediaType.APPLICATION_JSON, MediaType.TEXT_XML})
    @Consumes({MediaType.APPLICATION_JSON, MediaType.TEXT_XML})
    public Response createCustomer(Customer customer) {
        customer.setAccountId(new Long("123456789"));
        //Customer cusResp = dao.getCustomerByName(nameImput);
        return Response.status(Response.Status.OK).entity(customer).build();
    }
    

}
