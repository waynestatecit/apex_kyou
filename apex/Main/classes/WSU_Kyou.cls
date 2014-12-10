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

    @TestVisible
    private static List<Map<String, Object>> entriesReadyToCommit = new List<Map<String, Object>>();

    private static Boolean perpetuateInRun = false;
    private static Boolean perpetuateInFinish = false;
    private static Boolean drasticMeasures = false;
    private static Boolean forceDrasticMeasures = false;
    private static Integer waitMinutes = 5; // The default is to schedule the batch in 5 minutes

    public WSU_Kyou() {
    }

    public WSU_Kyou(Integer waitMinutesArg) {
        setOptions(waitMinutesArg);
    }

    public WSU_Kyou(Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg) {
        setOptions(perpetuateInRunArg, perpetuateInFinishArg, drasticMeasuresArg);
    }

    public WSU_Kyou(Integer waitMinutesArg, Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg) {
        setOptions(waitMinutesArg, perpetuateInRunArg, perpetuateInFinishArg, drasticMeasuresArg);
    }

    public WSU_Kyou(Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg, Boolean forceDrasticMeasuresArg) {
        setOptions(perpetuateInRunArg, perpetuateInFinishArg, drasticMeasuresArg, forceDrasticMeasuresArg);
    }

    public WSU_Kyou(Integer waitMinutesArg, Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg, Boolean forceDrasticMeasuresArg) {
        setOptions(waitMinutesArg, perpetuateInRunArg, perpetuateInFinishArg, drasticMeasuresArg, forceDrasticMeasuresArg);
    }

    public static void setOptions(Integer waitMinutesArg) {
        setOptions(waitMinutesArg, perpetuateInRun, perpetuateInFinish, drasticMeasures, forceDrasticMeasures);
    }

    public static void setOptions(Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg) {
        setOptions(waitMinutes, perpetuateInRunArg, perpetuateInFinishArg, drasticMeasuresArg, forceDrasticMeasures);
    }

    public static void setOptions(Integer waitMinutesArg, Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg) {
        setOptions(waitMinutesArg, perpetuateInRunArg, perpetuateInFinishArg, drasticMeasuresArg, forceDrasticMeasures);
    }

    public static void setOptions(Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg, Boolean forceDrasticMeasuresArg) {
        setOptions(waitMinutes, perpetuateInRunArg, perpetuateInFinishArg, drasticMeasuresArg, forceDrasticMeasuresArg);
    }

    public static void setOptions(Integer waitMinutesArg, Boolean perpetuateInRunArg, Boolean perpetuateInFinishArg, Boolean drasticMeasuresArg, Boolean forceDrasticMeasuresArg) {
        waitMinutes = waitMinutesArg;
        perpetuateInRun = perpetuateInRunArg;
        perpetuateInFinish = perpetuateInFinishArg;
        drasticMeasures = drasticMeasuresArg;
        forceDrasticMeasures = forceDrasticMeasuresArg;
    }

    public static Integer slotsAvailable() {
        Integer toReturn = maxBatchables - [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        return toReturn;
    }

    public static List<Object> getOpenSlots() {
        Set<Integer> openSlots = new Set<Integer>();
        List<WSU_Kyou_Open_Slots__c> openSlotsRecords = [select Data__c from WSU_Kyou_Open_Slots__c];
        for (WSU_Kyou_Open_Slots__c openSlotsRecord : openSlotsRecords) {
            for (Object openSlotObj : (List<Object>)JSON.deserializeUntyped(openSlotsRecord.Data__c)) {
                openSlots.add((Integer)openSlotObj);
            }
        }
        return new List<Object>{(Object)openSlots, (Object)openSlotsRecords};
    }

    public static void setOpenSlots(Set<Integer> openSlots, List<WSU_Kyou_Open_Slots__c> openSlotsRecords) {
        List<Database.DeleteResult> delResults = Database.Delete(openSlotsRecords);
        List<WSU_Kyou_Open_Slots__c> toInsert = new List<WSU_Kyou_Open_Slots__c>();
        Integer dataFieldLength = Schema.sObjectType.WSU_Kyou_Open_Slots__c.fields.Data__c.getLength();
        List<Object> dataList = null;
        Integer dataStringLengthCount = 0;
        for (Integer openSlot : openSlots) {
            String openSlotString = String.valueOf(openSlot);
            if (
                toInsert.size() == 0 ||
                // The + 1 is for the JSON comma
                dataStringLengthCount + openSlotString.length() + 1 > dataFieldLength
            ) {
                // Close out old one if it's there
                if (toInsert.size() > 0) {
                    toInsert.get(toInsert.size() - 1).Data__c = JSON.serialize(dataList);
                }

                // Prepare new one
                dataList = new List<Object>();
                toInsert.add(new WSU_Kyou_Open_Slots__c(
                    Data__c = '' // To protect the String.length() call in the above conditional
                ));
                // Note that I'm using this method because I suspect that string concatenation is slow.  I haven't
                // tested it, though.
                dataStringLengthCount = 2; // The square brackets
            }

            dataList.add(openSlot);
            dataStringLengthCount += openSlotString.length() + 1; // + 1 for the comma - yes I'm counting one
                                                                  // more comma than I should.
        }
        // Close out last one
        if (toInsert.size() > 0) {
            toInsert.get(toInsert.size() - 1).Data__c = JSON.serialize(dataList);
        }
        List<Database.SaveResult> insertResults = Database.Insert(toInsert);
    }

    // run() shouldn't be run directly.  It only gets run via the WSU_Kyou.finish() method.  All other ways to invoke
    // involve System.scheduleBatch() of WSU_Kyou or directly Database.executeBatch() of WSU_Kyou when drasticMeasures
    // is true.
    @TestVisible
    private static Set<ID> run() {
        Set<ID> toReturn = new Set<ID>();

        // Get Info and Open Slots records to determine what to query
        List<WSU_Kyou_Info__c> kyouInfos = WSU_Kyou_Info__c.getAll().values();
        System.assert(kyouInfos.size() <= 1); // FIXME: Sanity check for now

        WSU_Kyou_Info__c kyouInfo = null;
        if (kyouInfos.size() == 1) {
            kyouInfo = kyouInfos.get(0);
        } else { // empty Kyou
            kyouInfo = new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Highest_Priority__c = null,
                Lowest_Priority__c = null,
                Locked__c = false
            );
        }

        // If it's locked, just skip and let it perpetuate
        if (!kyouInfo.Locked__c) {
            // Lock it
            kyouInfo.Locked__c = true;
            Database.UpsertResult upsResult = Database.Upsert(kyouInfo);

            List<Object> openSlotsResults = getOpenSlots();
            Set<Integer> openSlots = (Set<Integer>)openSlotsResults.get(0);
            List<WSU_Kyou_Open_Slots__c> openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)openSlotsResults.get(1);

            List<Integer> foundEntries = new List<Integer>();
            if (kyouInfo.Highest_Priority__c != null) {
                // Use openSlots to decide which priorities you want to grab
                Integer i = kyouInfo.Highest_Priority__c.intValue() + 1;
                foundEntries.add(kyouInfo.Highest_Priority__c.intValue());
                while (foundEntries.size() < maxBatchables + 1 && i <= kyouInfo.Lowest_Priority__c.intValue()) {
                    // We know the max we can run is maxBatchables, so grab maxBatchables + 1 now and check slotsAvailable() later
                    // We grab maxBatchables + 1 so if we use all maxBatchables, we can set the new Highest_Priority__c to the sixth
                    if (!openSlots.contains(i)) {
                        foundEntries.add(i);
                    }
                    i++;
                }
            } // else this is a locked, empty Kyou
            // foundEntries is now ordered from highest to lowest priority

            List<WSU_Kyou_QueueEntry__c> entries = [select Id, Data__c, Priority__c from WSU_Kyou_QueueEntry__c where Priority__c in :foundEntries order by Priority__c];

            while (slotsAvailable() > 0 && entries.size() > 0) {
                WSU_Kyou_QueueEntry__c entry = entries.remove(0);
                Map<String, Object> entryData = (Map<String, Object>)JSON.deserializeUntyped(entry.Data__c);
                toReturn.add(executeBatch(
                    Type.forName((String)entryData.get('class')),
                    (Map<String, Object>)entryData.get('args'),
                    (Integer)entryData.get('size'),
                    (Boolean)entryData.get('list'),
                    (Boolean)entryData.get('object_list')
                ));
                // edit kyouinfo
                if (entries.size() > 0) {
                    kyouInfo.Highest_Priority__c = entries.get(0).Priority__c;
                } else {
                    // if makes queue empty, null out kyouinfo priority fields
                    kyouInfo.Highest_Priority__c = null;
                    kyouInfo.Lowest_Priority__c = null;
                }
                if (Test.isRunningTest()) { // test context only allows one Database.executeBatch() call
                    break;
                }
            }

            // Save new open slots
            if (kyouInfo.Highest_Priority__c == null) {
                openSlots.clear();
            } else {
                List<Integer> openSlotsList = new List<Integer>(openSlots);
                openSlotsList.sort();
                for (Integer openSlot : openSlotsList) {
                    if (openSlot <= kyouInfo.Highest_Priority__c) {
                        openSlots.remove(openSlot);
                    } else {
                        break;
                    }
                }
            }
            setOpenSlots(openSlots, openSlotsRecords);

            // Unlock it and save kyouInfo
            kyouInfo.Locked__c = false;
            Database.SaveResult result = Database.Update(kyouInfo);

        } else { // Send back the kyouInfo ID in case a caller wants to check - but this isn't happening right now
            toReturn.add(kyouInfo.Id);
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
                    toReturn = Database.executeBatch(new WSU_Kyou(waitMinutes, perpetuateInRun, perpetuateInFinish, drasticMeasures));
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
            try {
                // The constructor args inside ScheduleBatch() seem to get lost when the batch finally runs
                // So save them here and recall them in WSU_Kyou.start()
                List<Database.DeleteResult> deleteResults = Database.Delete(WSU_Kyou_Options__c.getAll().values());
                Database.SaveResult result = Database.Insert(new WSU_Kyou_Options__c(
                    Name = 'options',
                    Wait_Minutes__c = waitMinutes,
                    Perpetuate_In_Run__c = perpetuateInRun,
                    Perpetuate_In_Finish__c = perpetuateInFinish,
                    Drastic_Measures__c = drasticMeasures
                ));
                if (forceDrasticMeasures) {
                    throw new KyouException('You have exceeded the maximum number of Apex scheduled jobs.');
                }
                returnId = System.ScheduleBatch(new WSU_Kyou(waitMinutes, perpetuateInRun, perpetuateInFinish, drasticMeasures), 'WSU_Kyou', waitMinutes);
            } catch (System.AsyncException e) {
                returnId = errorHandler(e);
            } catch (KyouException e) {
                returnId = errorHandler(e);
            }
        }
        return returnId; // Not used anywhere right now
    }

    public static ID enqueueBatch(Type batchable) {
        return enqueueBatch(batchable, null, null, (Integer)null, false, true, false, false);
    }

    // There used do be some more overloaded enqueueBatch() calls here, but it's not entirely clear they're that useful for callers.

    public static ID enqueueBatch(Type batchable, Integer batchSize, Map<String, Object> args, Integer priority, Boolean tryNow, Boolean commitNow, Boolean startReturnsList, Boolean startReturnsObjectList) {

        // In case you wonder why I need a flag to say whether a return List is over Object or sObject, try instantiating a class
        // that implements Database.Batchable<Object> then do a bunch of instanceof Database.Batchable<anything>.
        // Always comes back true!

        Object job = batchable.newInstance();
        if (!(job instanceof Database.Batchable<Object>)) {
            throw new KyouException('The submitted Class does not implement Database.Batchable<>');
        }

        if (tryNow && Limits.getQueries() < Limits.getLimitQueries()) {
            if (slotsAvailable() > 0) {
                return executeBatch(batchable, args, batchSize, startReturnsList, startReturnsObjectList);
            }
        }

        Map<String, Object> entry = new Map<String, Object>{
            'class' => batchable.getName(),
            'args' => args,
            'size' => batchSize,
            'priority' => priority,
            'list' => startReturnsList,
            'object_list' => startReturnsObjectList
        };
        if (commitNow) {
            return doCommit(new List<Map<String, Object>>{
                entry
            });
        } else {
            entriesReadyToCommit.add(entry);
        }
        return null;
    }

    public static ID doCommit() {
        ID toReturn = doCommit(entriesReadyToCommit);
        entriesReadyToCommit.clear();
        return toReturn;
    }
    public static ID doCommit(List<Map<String, Object>> entries) {
        ID toReturn = null;
        if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) { // We're not at the limit
            if (entries.size() > 0) {
                // This condition is because of the bug here:
                // https://success.salesforce.com/issues_view?id=a1p300000008XM1AAM
                // If this bug gets fixed, remove this condition.
                if (!Test.isRunningTest()) {
                    toReturn = System.enqueueJob(new WSU_Kyou_Add(entries));
                }
            }
        } else {
            // FIXME: add a flag for running the add code anyway in this invocation space if we're at the Queueable
            // limit
            throw new KyouException('The org Queueable Job limit of ' + Limits.getLimitQueueableJobs() + ' has been reached.  Try again later.');
        }

        return toReturn;
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
        // Check Saved Adds for something that needs to be added before running.  If found, just submit the queueable
        // and skip the run().
        List<WSU_Kyou_Saved_Add__c> savedAdds = [select Data__c from WSU_Kyou_Saved_Add__c];
        if (savedAdds.size() > 0) {
            List<Map<String, Object>> entries = new List<Map<String, Object>>();
            for (WSU_Kyou_Saved_Add__c savedAdd : savedAdds) {
                for (Object entryObj : (List<Object>)JSON.deserializeUntyped(savedAdd.Data__c)) {
                    entries.add((Map<String, Object>)entryObj);
                }
            }
            ID ignore = System.enqueueJob(new WSU_Kyou_Add(entries));
            List<Database.DeleteResult> delResults = Database.Delete(savedAdds);
        } else {
            WSU_Kyou_Options__c options = WSU_Kyou_Options__c.getInstance('options');
            setOptions(options.Wait_Minutes__c.intValue(), options.Perpetuate_In_Run__c, options.Perpetuate_In_Finish__c, options.Drastic_Measures__c);
            Database.DeleteResult result = Database.Delete(options);
            Set<ID> ignore = run();
        }

    }

    public class KyouException extends Exception {}
}
