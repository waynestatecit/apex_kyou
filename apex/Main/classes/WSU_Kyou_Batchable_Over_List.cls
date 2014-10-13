// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_Kyou_Batchable_Over_List implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public Database.Batchable<sObject> implementation = null;
    private Map<String, Object> args = null;

    //public WSU_Kyou_Batchable_Over_List(Type implementation) {
        //setImplementation(implementation);
    //}

    public WSU_Kyou_Batchable_Over_List(Type implementation, Map<String, Object> args) {
        this.args = args;
        setImplementation(implementation);
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

    public List<sObject> start(Database.BatchableContext bc) {
        return (List<sObject>)implementation.start(bc);
    }

    public void execute(Database.BatchableContext bc, List<sObject> sobjs) {
        implementation.execute(bc, sobjs);
    }

    public void finish(Database.BatchableContext bc) {
        implementation.finish(bc);
    }

    public class Kyou_BatchableException extends Exception {}
}
