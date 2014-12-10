// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

// Data looks like this:
// {"flavor":enumint,"class":classname,"size":batchsizeint,"args":{object of args}}
// size and args are optional

public class WSU_Kyou_QueueEntry extends WSU_SObject {
    //public enum JobFlavor {BATCHABLE, SCHEDULABLE}
    public enum JobFlavor {BATCHABLE}
    private JobFlavor flavor = null;

    public Type batchableType {
        public get {
            if (sobj == null || sobj.get('Data__c') == null) {
                return null;
            }
            String typeName = (String)((Map<String, Object>)(JSON.deserializeUntyped((String)sobj.get('Data__c')))).get('class');
            return Type.forName(typeName);
        }
    }

    public Integer size {
        public get {
            if (sobj == null || sobj.get('Data__c') == null) {
                return null;
            }
            return (Integer)((Map<String, Object>)(JSON.deserializeUntyped((String)sobj.get('Data__c')))).get('size');
        }
    }

    public Map<String, Object> args {
        public get {
            if (sobj == null || sobj.get('Data__c') == null) {
                return null;
            }
            return (Map<String, Object>)((Map<String, Object>)(JSON.deserializeUntyped((String)sobj.get('Data__c')))).get('args');
        }
    }

    public Boolean startReturnsList {
        public get {
            if (sobj == null || sobj.get('Data__c') == null) {
                return null;
            }
            return (Boolean)((Map<String, Object>)(JSON.deserializeUntyped((String)sobj.get('Data__c')))).get('list');
        }
    }

    public Boolean startReturnsObjectList {
        public get {
            if (sobj == null || sobj.get('Data__c') == null) {
                return null;
            }
            return (Boolean)((Map<String, Object>)(JSON.deserializeUntyped((String)sobj.get('Data__c')))).get('object_list');
        }
    }

    public WSU_Kyou_QueueEntry() {
    }

    public WSU_Kyou_QueueEntry(WSU_Kyou_QueueEntry__c entry) {
        super(entry);
        if (sobj.get('Data__c') != null) {
            Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped((String)sobj.get('Data__c'));
            Integer flavorInt = (Integer)data.get('flavor');
            for (JobFlavor loopType : JobFlavor.values()) {
                if (loopType.ordinal() == flavorInt) {
                    flavor = loopType;
                    break;
                }
            }
        }
    }

    public WSU_Kyou_QueueEntry__c generateQueueEntry(Type jobType, JobFlavor forceFlavor) {
        return generateQueueEntry(jobType, forceFlavor, null, null, null);
    }

    public WSU_Kyou_QueueEntry__c generateQueueEntry(Type jobType, JobFlavor forceFlavor, Integer batchSize) {
        return generateQueueEntry(jobType, forceFlavor, batchSize, null, null);
    }

    public WSU_Kyou_QueueEntry__c generateQueueEntry(Type jobType, JobFlavor forceFlavor, Integer batchSize, Map<String, Object> args) {
        return generateQueueEntry(jobType, forceFlavor, batchSize, args, null);
    }

    public WSU_Kyou_QueueEntry__c generateQueueEntry(Type jobType, JobFlavor forceFlavor, Integer batchSize, Map<String, Object> args, ID inFrontOf) {
        flavor = forceFlavor;
        return generateQueueEntry(jobType, batchSize, args, inFrontOf);
    }

    public WSU_Kyou_QueueEntry__c generateQueueEntry(Type jobType, Integer batchSize) {
        return generateQueueEntry(jobType, batchSize, null, null);
    }

    public WSU_Kyou_QueueEntry__c generateQueueEntry(Type jobType, Integer batchSize, Map<String, Object> args) {
        return generateQueueEntry(jobType, batchSize, args, null);
    }

    public WSU_Kyou_QueueEntry__c generateQueueEntry(Type jobType, Integer batchSize, Map<String, Object> args, ID inFrontOf) {
        return generateQueueEntry(jobType, batchSize, args, inFrontOf, false);
    }

    public WSU_Kyou_QueueEntry__c generateQueueEntry(Type jobType, Integer batchSize, Map<String, Object> args, ID inFrontOf, Boolean startReturnsList) {
        return generateQueueEntry(jobType, batchSize, args, inFrontOf, startReturnsList, false);
    }

    public WSU_Kyou_QueueEntry__c generateQueueEntry(Type jobType, Integer batchSize, Map<String, Object> args, ID inFrontOf, Boolean startReturnsList, Boolean startReturnsObjectList) {
        if (flavor == null) {
            Object job = jobType.newInstance();
            if (job instanceof Database.Batchable<Object>) {
                flavor = JobFlavor.BATCHABLE;
            //} else if (job instanceof Schedulable) {
                //flavor = JobFlavor.SCHEDULABLE;
            } else {
                //throw new QueueEntryException('The submitted Class implements neither Database.Batchable<sObject> nor Schedulable');
                throw new QueueEntryException('The submitted Class does not implement Database.Batchable<>');
            }
        }

        Map<String, Object> newData = new Map<String, Object>{
            'class' => jobType.getName(),
            'size' => batchSize,
            'args' => args,
            'flavor' => flavor.ordinal(),
            'list' => startReturnsList,
            'object_list' => startReturnsObjectList
        };

        //sobj = new WSU_Kyou_QueueEntry__c(
            //Data__c = JSON.serialize(newData),
            //Next__c = inFrontOf == null ? null : inFrontOf
        //);

        //return (WSU_Kyou_QueueEntry__c)sobj;
        return null;
    }

    public class QueueEntryException extends Exception {}
}
