/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.upb.cursoc24.api.model;

import java.io.Serializable;
import java.util.Date;
import javax.xml.bind.annotation.XmlRootElement;

/**
 *
 * @author abel
 */
@XmlRootElement(name = "TrAccout")
public class TrAccount implements Serializable {

    private Long accountId;
    private Double saldAmount;
    private String status;
    private Date startDate;
    private Date endDate;

    public TrAccount() {
    }

    public TrAccount(Long accountId, Double saldAmount, String status, Date startDate, Date endDate) {
        this.accountId = accountId;
        this.saldAmount = saldAmount;
        this.status = status;
        this.startDate = startDate;
        this.endDate = endDate;
    }

    /**
     * @return the accountId
     */
    public Long getAccountId() {
        return accountId;
    }

    /**
     * @param accountId the accountId to set
     */
    public void setAccountId(Long accountId) {
        this.accountId = accountId;
    }

    /**
     * @return the saldAmount
     */
    public Double getSaldAmount() {
        return saldAmount;
    }

    /**
     * @param saldAmount the saldAmount to set
     */
    public void setSaldAmount(Double saldAmount) {
        this.saldAmount = saldAmount;
    }

    /**
     * @return the status
     */
    public String getStatus() {
        return status;
    }

    /**
     * @param status the status to set
     */
    public void setStatus(String status) {
        this.status = status;
    }

    /**
     * @return the startDate
     */
    public Date getStartDate() {
        return startDate;
    }

    /**
     * @param startDate the startDate to set
     */
    public void setStartDate(Date startDate) {
        this.startDate = startDate;
    }

    /**
     * @return the endDate
     */
    public Date getEndDate() {
        return endDate;
    }

    /**
     * @param endDate the endDate to set
     */
    public void setEndDate(Date endDate) {
        this.endDate = endDate;
    }

}
