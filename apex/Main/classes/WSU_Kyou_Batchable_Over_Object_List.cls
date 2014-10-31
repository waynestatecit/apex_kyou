// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_Kyou_Batchable_Over_Object_List implements Database.Batchable<Object>, Database.Stateful, Database.AllowsCallouts {
    public Database.Batchable<Object> implementation = null;
    private Map<String, Object> args = null;
    private Boolean perpetuateInFinish = false;

    public WSU_Kyou_Batchable_Over_Object_List(Type implementation, Map<String, Object> args, Boolean perpetuateInFinish) {
        this.args = args;
        setImplementation(implementation);
        this.perpetuateInFinish = perpetuateInFinish;
    }

    public void setImplementation(Type implementation) {
        if (implementation != null && implementation.newInstance() instanceof Database.Batchable<Object>) {
            if (args == null) {
                this.implementation = (Database.Batchable<Object>)implementation.newInstance();
            } else {
                this.implementation = (Database.Batchable<Object>)JSON.deserialize(JSON.serialize(args), implementation);
            }
        } else {
            throw new Kyou_BatchableException('Implementation is not of type Database.Batchable<Object>.');
        }
    }

    public List<Object> start(Database.BatchableContext bc) {
        return (List<Object>)implementation.start(bc);
    }

    public void execute(Database.BatchableContext bc, List<Object> objs) {
        implementation.execute(bc, objs);
    }

    public void finish(Database.BatchableContext bc) {
        implementation.finish(bc);
        if (perpetuateInFinish) {
            WSU_Kyou.scheduleSelf();
        }
    }

    public class Kyou_BatchableException extends Exception {}
}
