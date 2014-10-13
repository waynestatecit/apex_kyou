// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

// UI:
//   info on batch jobs waiting
//   info on scheduled jobs
//   change priorities

// Capabilities:
//    fully manage queued stuff (CRUD)
//    logs (another package?)
//    

public class WSU_Kyou {
    public static Database.Batchable<sObject> latestImplementation = null;
    public static Database.Batchable<Object> latestImplementationObject = null;

    private static Integer maxBatchables = 5;

    private static WSU_Kyou_QueueEntryList entries = null;

    static {
        refreshEntries();
    }

    public static void refreshEntries() {
        //Integer numberWithSetNext = [select count() from WSU_Kyou_QueueEntry__c where Next__c != null];
        //Boolean nextsSet = [select count() from WSU_Kyou_QueueEntry__c where Next__c != null] > 0;
        entries = new WSU_Kyou_QueueEntryList(WSU_Soop.query(
            //'select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c ' + (nextsSet ? 'where Next__c != null' : 'where Next__c = null'),
            //'select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c where Top__c = true',
            'select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c limit 5',
            WSU_Kyou_QueueEntry.class
        ));
    }

    public static WSU_Kyou_QueueEntryList entries() {
        return entries;
    }

    public static Integer slotsAvailable() {
        Integer toReturn = maxBatchables - [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        return toReturn;
    }

    public static Set<ID> run() {
        Set<ID> toReturn = new Set<ID>();

        while (slotsAvailable() > 0 && entries.size() > 0) {
            List<Object> entryInfo = entries.popFirst();
            toReturn.add(executeBatch((Type)entryInfo.get(0), (Map<String, Object>)entryInfo.get(2), (Integer)entryInfo.get(1), (Boolean)entryInfo.get(3), (Boolean)entryInfo.get(4)));
            if (Test.isRunningTest()) {
                break;
            }
        }

        return toReturn;
    }

    public static ID enqueueBatch(Type batchable) {
        return enqueueBatch(batchable, null, (ID)null);
    }

    public static ID enqueueBatch(Type batchable, Boolean tryNow) {
        return enqueueBatch(batchable, null, null, null, tryNow);
    }

    public static ID enqueueBatch(Type batchable, Integer batchSize) {
        return enqueueBatch(batchable, batchSize, (ID)null);
    }

    public static ID enqueueBatch(Type batchable, Integer batchSize, Boolean tryNow) {
        return enqueueBatch(batchable, batchSize, null, null, tryNow);
    }

    public static ID enqueueBatch(Type batchable, Integer batchSize, ID next) {
        return enqueueBatch(batchable, batchSize, null, next, false);
    }

    public static ID enqueueBatch(Type batchable, Integer batchSize, ID next, Boolean tryNow) {
        return enqueueBatch(batchable, batchSize, null, next, tryNow);
    }

    public static ID enqueueBatch(Type batchable, Integer batchSize, Map<String, Object> args, ID next, Boolean tryNow) {
        return enqueueBatch(batchable, batchSize, args, next, tryNow, false);
    }

    public static ID enqueueBatch(Type batchable, Integer batchSize, Map<String, Object> args, ID next, Boolean tryNow, Boolean doDML) {
        return enqueueBatch(batchable, batchSize, args, next, tryNow, doDML, false);
    }

    public static ID enqueueBatch(Type batchable, Integer batchSize, Map<String, Object> args, ID next, Boolean tryNow, Boolean doDML, Boolean startReturnsList) {
        // In case you wonder why I need a flag to say whether a return List is over Object or sObject, try instantiating a class
        // that implements Database.Batchable<Object> then do a bunch of instanceof Database.Batchable<anything>.
        // Always comes back true!
        return enqueueBatch(batchable, batchSize, args, next, tryNow, doDML, startReturnsList, false);
    }

    public static ID enqueueBatch(Type batchable, Integer batchSize, Map<String, Object> args, ID next, Boolean tryNow, Boolean doDML, Boolean startReturnsList, Boolean startReturnsObjectList) {
        Object job = batchable.newInstance();
        if (!(job instanceof Database.Batchable<Object>)) {
            throw new KyouException('The submitted Class does not implement Database.Batchable<>');
        }

        if (tryNow && Limits.getQueries() < Limits.getLimitQueries()) {
            if (slotsAvailable() > 0) {
                return executeBatch(batchable, args, batchSize, startReturnsList, startReturnsObjectList);
            }
        }

        WSU_Kyou_QueueEntry newEntry = new WSU_Kyou_QueueEntry();
        newEntry.generateQueueEntry(batchable, batchSize, args, next, startReturnsList, startReturnsObjectList);
        if (doDML) {
            Database.SaveResult result = Database.insert(newEntry.sobj);
        }
        entries.add(newEntry, doDML);

        return null;
    }

    public static void doCommit() {
        entries.doCommit();
    }

    private static ID executeBatch(Type batchableType, Map<String, Object> args, Integer batchSize, Boolean startReturnsList, Boolean startReturnsObjectList) {
        Database.Batchable<sObject> batchable = null;
        Database.Batchable<Object> batchableObject = null;
        Boolean overObject = false; // Just remember the first time
        if (startReturnsObjectList) {
            WSU_Kyou_Batchable_Over_Object_List kyouBatchable = new WSU_Kyou_Batchable_Over_Object_List(batchableType, args);
            latestImplementationObject = kyouBatchable.implementation;
            batchableObject = kyouBatchable;
        } else if (startReturnsList) {
            WSU_Kyou_Batchable_Over_List kyouBatchable = new WSU_Kyou_Batchable_Over_List(batchableType, args);
            latestImplementation = kyouBatchable.implementation;
            batchable = kyouBatchable;
        } else {
            WSU_Kyou_Batchable kyouBatchable = new WSU_Kyou_Batchable(batchableType, args);
            latestImplementation = kyouBatchable.implementation;
            batchable = kyouBatchable;
        }

        if (batchSize == null) {
            return startReturnsObjectList ? Database.executeBatch(batchableObject) : Database.executeBatch(batchable);
        } else {
            return startReturnsObjectList ? Database.executeBatch(batchableObject, batchSize) : Database.executeBatch(batchable, batchSize);
        }
    }

    public class KyouException extends Exception {}
}
