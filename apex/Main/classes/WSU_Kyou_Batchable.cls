// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_Kyou_Batchable implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public Database.Batchable<sObject> implementation = null;
    private Map<String, Object> args = null;
    private Boolean perpetuateInFinish = false;

    //public WSU_Kyou_Batchable(Type implementation) {
        //setImplementation(implementation);
    //}

    public WSU_Kyou_Batchable() { // This is mostly for testing
    }

    public WSU_Kyou_Batchable(Type implementation, Map<String, Object> args, Boolean perpetuateInFinish) {
        this.args = args;
        setImplementation(implementation);
        this.perpetuateInFinish = perpetuateInFinish;
    }

    public void setImplementation(Type implementation) {
        if (implementation != null && implementation.newInstance() instanceof Database.Batchable<sObject>) {
            if (args == null) {
                this.implementation = (Database.Batchable<sObject>)implementation.newInstance();
            } else {
                this.implementation = (Database.Batchable<sObject>)JSON.deserialize(JSON.serialize(args), implementation);
            }
        } else {
            throw new Kyou_BatchableException('Implementation is not of type Database.Batchable<sObject>.');
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return (Database.QueryLocator)implementation.start(bc);
    }

    public void execute(Database.BatchableContext bc, List<sObject> sobjs) {
        implementation.execute(bc, sobjs);
    }

    public void finish(Database.BatchableContext bc) {
        implementation.finish(bc);
        if (perpetuateInFinish) {
            WSU_Kyou.scheduleSelf();
        }
    }

    public class Kyou_BatchableException extends Exception {}
}
