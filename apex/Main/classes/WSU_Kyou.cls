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

public class WSU_Kyou implements Database.Batchable<Object> {
    public static Database.Batchable<sObject> latestImplementation = null;
    public static Database.Batchable<Object> latestImplementationObject = null;

    private static Integer maxBatchables = 5;

    private static WSU_Kyou_QueueEntryList entries = null;

    private static Boolean perpetuateInRun = false;
    private static Boolean perpetuateInFinish = false;
    private static Boolean drasticMeasures = false;
    private static Boolean forceDrasticMeasures = false;

    public WSU_Kyou() {
    }

    public WSU_Kyou(Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg) {
        setOptions(perpetuateInRunArg, perpetuateInFinishArg, drasticMeasuresArg);
    }

    public WSU_Kyou(Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg, Boolean forceDrasticMeasuresArg) {
        setOptions(perpetuateInRunArg, perpetuateInFinishArg, drasticMeasuresArg, forceDrasticMeasuresArg);
    }

    public static void setOptions(Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg) {
        setOptions(perpetuateInRunArg, perpetuateInFinishArg, drasticMeasuresArg, false);
    }

    public static void setOptions(Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg, Boolean forceDrasticMeasuresArg) {
        perpetuateInRun = perpetuateInRunArg;
        perpetuateInFinish = perpetuateInFinishArg;
        drasticMeasures = drasticMeasuresArg;
        forceDrasticMeasures = forceDrasticMeasuresArg;
    }

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

    // run() shouldn't be run directly.  It only gets run via the WSU_Kyou.finish() method.  All other ways to invoke
    // involve System.scheduleBatch() of WSU_Kyou or directly Database.executeBatch() of WSU_Kyou when drasticMeasures
    // is true.
    @TestVisible
    private static Set<ID> run() {
        Set<ID> toReturn = new Set<ID>();

        while (slotsAvailable() > 0 && entries.size() > 0) {
            List<Object> entryInfo = entries.popFirst();
            toReturn.add(executeBatch((Type)entryInfo.get(0), (Map<String, Object>)entryInfo.get(2), (Integer)entryInfo.get(1), (Boolean)entryInfo.get(3), (Boolean)entryInfo.get(4)));
            if (Test.isRunningTest()) {
                break;
            }
        }

        if (perpetuateInRun) {
            scheduleSelf();
        }

        return toReturn;
    }

    private static ID errorHandler(System.Exception e) {
        String errorMessage = e.getMessage();
        ID toReturn = null;
        if (
            errorMessage.startsWith('You have exceeded the maximum number ') &&
            errorMessage.endsWith('of Apex scheduled jobs.')
        ) {
            if (drasticMeasures) {
                // respawn myself as a batch job
                if (slotsAvailable() > 0) {
                    toReturn = Database.executeBatch(new WSU_Kyou(perpetuateInRun, perpetuateInFinish, drasticMeasures));
                }
            } else {
                // just die
                throw new KyouException('There are no Scheduled Apex slots left, so Kyou will not perpetuate.');
            }
        } else {
            throw e;
        }
        return toReturn;
    }

    public static ID scheduleSelf() {
        Integer numScheduled = [select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ];

        ID returnId = null;
        if (numScheduled == 0) {
            Integer waitMinutes = 5;
            try {
                if (forceDrasticMeasures) {
                    throw new KyouException('You have exceeded the maximum number of Apex scheduled jobs.');
                }
                returnId = System.ScheduleBatch(new WSU_Kyou(), 'WSU_Kyou', waitMinutes);
            } catch (System.AsyncException e) {
                returnId = errorHandler(e);
            } catch (KyouException e) {
                returnId = errorHandler(e);
            }
        }
        return returnId; // Not used anywhere right now
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
        Boolean overObject = false; // Just remember the first time - unused?
        if (startReturnsObjectList) {
            WSU_Kyou_Batchable_Over_Object_List kyouBatchable = new WSU_Kyou_Batchable_Over_Object_List(batchableType, args, perpetuateInFinish);
            latestImplementationObject = kyouBatchable.implementation;
            batchableObject = kyouBatchable;
        } else if (startReturnsList) {
            WSU_Kyou_Batchable_Over_List kyouBatchable = new WSU_Kyou_Batchable_Over_List(batchableType, args, perpetuateInFinish);
            latestImplementation = kyouBatchable.implementation;
            batchable = kyouBatchable;
        } else {
            WSU_Kyou_Batchable kyouBatchable = new WSU_Kyou_Batchable(batchableType, args, perpetuateInFinish);
            latestImplementation = kyouBatchable.implementation;
            batchable = kyouBatchable;
        }

        if (batchSize == null) {
            return startReturnsObjectList ? Database.executeBatch(batchableObject) : Database.executeBatch(batchable);
        } else {
            return startReturnsObjectList ? Database.executeBatch(batchableObject, batchSize) : Database.executeBatch(batchable, batchSize);
        }
    }

    // For perpetuation
    public List<Object> start(Database.BatchableContext bc) {
        return new List<Object>();
    }

    public void execute(Database.BatchableContext bc, List<Object> ignore) {
    }

    public void finish(Database.BatchableContext bc) {
        Set<ID> ignore = run();
    }

    public class KyouException extends Exception {}
}
