// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

// The tests here that end up running doCommit() are somewhat crippled by this bug:
// https://success.salesforce.com/issues_view?id=a1p300000008XM1AAM
// Until that bug is fixed, the WSU_Kyou code just skips the actual enqueueJob() call.

@isTest
public class WSU_KyouTest {
    static {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new Contact(
                LastName = 'ORIGINAL1'
            ),
            new Contact(
                LastName = 'ORIGINAL2'
            )
        });

        // Protect tests from platform bug while deploying to production
        WSU_Kyou.setForceAdder(true);
    }

    static testMethod void testEnqueueBatchNoCommit() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, null, null, null, false, false, false, false);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        // Nothing ran
        System.assertEquals(before, after);

        // No commit yet
        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 0);

        List<Map<String, Object>> expectedEntries = new List<Map<String, Object>>{new Map<String, Object>{
            'class' => 'WSU_Kyou_Batchable_Testing',
            'args' => null,
            'size' => null,
            'priority' => null,
            'list' => false,
            'object_list' => false
        }};

        System.assert(WSU_Kyou.entriesReadyToCommit.equals(expectedEntries));
    }

    static testMethod void testEnqueueBatchWithCommit() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, null, null, null, false, false, false, false);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        // Nothing ran
        System.assertEquals(before, after);

        // No commit yet
        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 0);

        Test.startTest();
        WSU_Kyou.doCommit();
        Test.stopTest();

        /* crippled by bug - this does work if you test it separately to avoid the platform bug
        List<WSU_Kyou_QueueEntry__c> entries = [select Data__c, Priority__c from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entries.size(), 1);
        System.assertEquals(entries.get(0).Priority__c.intValue(), 0);

        Map<String, Object> expectedEntries = new Map<String, Object>{
            'class' => 'WSU_Kyou_Batchable_Testing',
            'args' => null,
            'size' => null,
            'list' => false,
            'object_list' => false
        };

        System.assert(expectedEntries.equals((Map<String, Object>)JSON.deserializeUntyped(entries.get(0).Data__c)));
        */
        System.assertEquals(WSU_Kyou.entriesReadyToCommit.size(), 0);
    }

    static testMethod void testEnqueueBatchForcedCommit() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, null, null, null, false, false, false, false);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        // Nothing ran
        System.assertEquals(before, after);

        // No commit yet
        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 0);

        WSU_Kyou.setForceAdder(true);

        //Test.startTest();
        WSU_Kyou.doCommit();
        //Test.stopTest();

        List<WSU_Kyou_QueueEntry__c> entries = [select Data__c, Priority__c from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entries.size(), 1);
        System.assertEquals(entries.get(0).Priority__c.intValue(), 0);

        Map<String, Object> expectedEntries = new Map<String, Object>{
            'class' => 'WSU_Kyou_Batchable_Testing',
            'args' => null,
            'size' => null,
            'list' => false,
            'object_list' => false
        };

        System.assert(expectedEntries.equals((Map<String, Object>)JSON.deserializeUntyped(entries.get(0).Data__c)));
        System.assertEquals(WSU_Kyou.entriesReadyToCommit.size(), 0);
    }

    static testMethod void testEnqueueBatchAutoCommit() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        Test.startTest();
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class);
        Test.stopTest();
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        // Nothing ran
        System.assertEquals(before, after);

        /* crippled by bug
        List<WSU_Kyou_QueueEntry__c> entries = [select Data__c, Priority__c from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entries.size(), 1);
        System.assertEquals(entries.get(0).Priority__c.intValue(), 0);

        Map<String, Object> expectedEntries = new Map<String, Object>{
            'class' => 'WSU_Kyou_Batchable_Testing',
            'args' => null,
            'size' => null,
            'list' => false,
            'object_list' => false
        };

        System.assert(expectedEntries.equals((Map<String, Object>)JSON.deserializeUntyped(entries.get(0).Data__c)));
        */
        System.assertEquals(WSU_Kyou.entriesReadyToCommit.size(), 0);
    }

    static testMethod void testTryNowOne() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = JSON.serialize(new Map<String, Object>{
                    'class' => 'WSU_Kyou_Batchable_Testing',
                    'args' => null,
                    'size' => null,
                    'list' => false,
                    'object_list' => false
                })
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Lowest_Priority__c = 0,
                Highest_Priority__c = 0,
                Locked__c = false
            )
        });

        Integer numScheduledBefore = [select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ];

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        if (before >= 5) {
            throw new WSU_Kyou.KyouException('There must be at least one open Batch Apex slot for this test to run.');
        }

        Test.startTest();
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, null, null, null, true, false, false, false);
        Integer afterRun = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun);

        System.assertEquals([select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ], numScheduledBefore); // Even though we are set to perpetuate, we never get there, because we're just running
                                // right away

        WSU_Kyou_Info__c infoAfter = WSU_Kyou_Info__c.getAll().values().get(0);
        // No change to kyouInfo
        System.assert(!infoAfter.Locked__c);
        System.assertEquals(infoAfter.Highest_Priority__c, 0);
        System.assertEquals(infoAfter.Lowest_Priority__c, 0);

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
        Test.stopTest();

        System.assertEquals([select count() from Contact where LastName = 'DEFAULT'], 2);
        System.assertEquals([select count() from Contact where LastName != 'DEFAULT'], 0);
    }

    static testMethod void testTryNowList() {
        Integer numScheduledBefore = [select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ];

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        if (before >= 5) {
            throw new WSU_Kyou.KyouException('There must be at least one open Batch Apex slot for this test to run.');
        }

        Test.startTest();
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_ListBatchable_Testing.class, null, null, null, true, false, true, false);
        Integer afterRun = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun);

        System.assertEquals([select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ], numScheduledBefore); // Even though we are set to perpetuate, we never get there, because we're just running
                                // right away

        System.assertEquals(WSU_Kyou_Info__c.getAll().values().size(), 0); // Never made one

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
        Test.stopTest();

        // Nothing much to test - the test implementation class doesn't do anything
    }

    static testMethod void testTryNowObjectList() {
        Integer numScheduledBefore = [select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ];

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        if (before >= 5) {
            throw new WSU_Kyou.KyouException('There must be at least one open Batch Apex slot for this test to run.');
        }

        Test.startTest();
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_ObjectListBatchable_Testing.class, null, null, null, true, false, false, true);
        Integer afterRun = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun);

        System.assertEquals([select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ], numScheduledBefore); // Even though we are set to perpetuate, we never get there, because we're just running
                                // right away

        System.assertEquals(WSU_Kyou_Info__c.getAll().values().size(), 0); // Never made one

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
        Test.stopTest();

        // Nothing much to test - the test implementation class doesn't do anything
    }

    static testMethod void testTryNowObjectListBad() {
        Integer numScheduledBefore = [select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ];

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        if (before >= 5) {
            throw new WSU_Kyou.KyouException('There must be at least one open Batch Apex slot for this test to run.');
        }

        Boolean success = true;
        try {
            Test.startTest();
            // Object list flag not set correctly
            ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_ObjectListBatchable_Testing.class, null, null, null, true, false, false, false);
            Test.stopTest();
        } catch (System.TypeException e) {
            success = false;
        }
        System.assert(!success);

        // Nothing much to test - the test implementation class doesn't do anything
    }

    /*
    static testMethod void testRunATon() {
        List<WSU_Kyou_QueueEntry__c> entries = new List<WSU_Kyou_QueueEntry__c>();
        for (Integer i = 0; i < 1000; i++) {
            WSU_Kyou_QueueEntry__c entrySObj = (new WSU_Kyou_QueueEntry()).generateQueueEntry(WSU_Kyou_Batchable_Testing.class, (Integer)null);
            //if (i > 5) {
                //entrySObj.Top__c = true;
            //}
            entries.add(entrySObj);
        }
        for (Integer i = 0; i < entries.size() / 200 + 1; i++) {
            List<WSU_Kyou_QueueEntry__c> toInsert = new List<WSU_Kyou_QueueEntry__c>();
            for (Integer j = 0; j < 200 && i * 200 + j < entries.size(); j++) {
                toInsert.add(entries.get(i*200 + j));
            }
            List<Database.SaveResult> results = Database.insert(toInsert);
        }

        Set<ID> batchJobIds = WSU_Kyou.run();

        // Not asserting anything - this was more to test how many queue entries run() can handle
    }
    */

    /* This test won't run now - the loop to fill up the batch apex slots fails because of the restriction of only one
       Database.executeBatch() call per test method
    @isTest(SeeAllData = true)
    static void testEnqueueFullQueue() {
        //System.assertEquals(WSU_Kyou.entries().size(), 0);
        Integer beforeEntries = WSU_Kyou.entries().size();

        for (Integer i = 0; i < 20; i++) { // Make sure I fill up the queue
            if ([select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'] < 5) {
                Database.executeBatch(new WSU_Kyou_Batchable_Testing());
            }
        }

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, true);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assert(before == 5 && after == 5);

        System.assertEquals(WSU_Kyou.entries().size(), beforeEntries + 1);
    }

    /* LEAVE
    @isTest(SeeAllData = true)
    static void testRunFullQueue() {
        //System.assertEquals(WSU_Kyou.entries().size(), 0);
        Integer beforeEntries = WSU_Kyou.entries().size();

        Integer numOfJobs = 20;
        for (Integer i = 0; i < numOfJobs; i++) { // Make sure I fill up the queue
            ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, false);
        }
        System.assertEquals(WSU_Kyou.entries().size(), numOfJobs + beforeEntries);

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        //System.assertEquals(before, 0);

        //Test.startTest();
        WSU_Kyou.run();
        //Test.stopTest();
        // This is a race, so can't rely on 5 being there.
        //Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing') and JobType = 'BatchApex'];
        //System.assertEquals(after, 5);
        //System.assertEquals(WSU_Kyou.entries().size(), numOfJobs + beforeEntries - (5 - before));
        System.assertEquals(WSU_Kyou.entries().size(), numOfJobs + beforeEntries - (1 - before)); // Gotta only have 1 in testmethod invocation instead of 5
    }
    */

    static testMethod void testScheduled() {
        String scheduledQuery = 'select CronJobDetail.Name, State from CronTrigger where CronJobDetail.Name = \'WSU_Kyou\' and State not in (\'Aborted\', \'Completed\', \'Failed\')';
        List<CronTrigger> scheduledBefore = Database.query(scheduledQuery);
        if (scheduledBefore.size() > 0) {
            throw new WSU_Kyou.KyouException('Please delete all WSU_Kyou_Scheduled Scheduled Apex jobs before running tests.');
        }

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        WSU_Kyou_Scheduled sch = new WSU_Kyou_Scheduled();
        SchedulableContext context = null;
        sch.execute(context);

        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before, after);

        List<CronTrigger> scheduledAfterStop = Database.query(scheduledQuery);
        System.assertEquals(scheduledAfterStop.size(), 1);
        System.assertEquals(scheduledAfterStop.get(0).CronJobDetail.Name, 'WSU_Kyou');
        System.assertEquals(scheduledAfterStop.get(0).State, 'WAITING');
    }

    static testMethod void testRunOne() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = JSON.serialize(new Map<String, Object>{
                    'class' => 'WSU_Kyou_Batchable_Testing',
                    'args' => null,
                    'size' => null,
                    'list' => false,
                    'object_list' => false
                })
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Lowest_Priority__c = 0,
                Highest_Priority__c = 0,
                Locked__c = false
            )
        });

        Integer numScheduledBefore = [select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ];

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        Set<ID> batchJobIds = WSU_Kyou.run();
        Integer afterRun = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun);

        System.assertEquals([select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ], numScheduledBefore); // perpetuateInRun defaults to false

        WSU_Kyou_Info__c infoAfter = WSU_Kyou_Info__c.getAll().values().get(0);
        System.assert(!infoAfter.Locked__c);
        System.assertEquals(infoAfter.Highest_Priority__c, null); // None left
        System.assertEquals(infoAfter.Lowest_Priority__c, null); // None left

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);

        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 0);
    }

    static testMethod void testRunOneWithResults() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = JSON.serialize(new Map<String, Object>{
                    'class' => 'WSU_Kyou_Batchable_Testing',
                    'args' => null,
                    'size' => null,
                    'list' => false,
                    'object_list' => false
                })
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Lowest_Priority__c = 0,
                Highest_Priority__c = 0,
                Locked__c = false
            )
        });

        Integer numScheduledBefore = [select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ];

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        Test.startTest();
        Set<ID> batchJobIds = WSU_Kyou.run();
        Integer afterRun = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun);

        System.assertEquals([select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ], numScheduledBefore); // perpetuateInRun defaults to false

        WSU_Kyou_Info__c infoAfter = WSU_Kyou_Info__c.getAll().values().get(0);
        System.assert(!infoAfter.Locked__c);
        System.assertEquals(infoAfter.Highest_Priority__c, null); // None left
        System.assertEquals(infoAfter.Lowest_Priority__c, null); // None left

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);

        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 0);
        Test.stopTest();
        System.assert(WSU_Kyou.latestImplementation instanceof WSU_Kyou_Batchable_Testing);

        System.assertEquals([select count() from Contact where LastName = 'DEFAULT'], 2);
        System.assertEquals([select count() from Contact where LastName != 'DEFAULT'], 0);
    }

    static testMethod void testRunOneWithParams() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = JSON.serialize(new Map<String, Object>{
                    'class' => 'WSU_Kyou_Batchable_Testing',
                    'args' => (Object)new Map<String, Object>{
                        'someParam' => 'NEWNAME'
                    },
                    'size' => null,
                    'list' => false,
                    'object_list' => false
                })
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Lowest_Priority__c = 0,
                Highest_Priority__c = 0,
                Locked__c = false
            )
        });

        Integer numScheduledBefore = [select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ];

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        Test.startTest();
        Set<ID> batchJobIds = WSU_Kyou.run();
        Integer afterRun = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun);

        System.assertEquals([select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ], numScheduledBefore); // perpetuateInRun defaults to false

        WSU_Kyou_Info__c infoAfter = WSU_Kyou_Info__c.getAll().values().get(0);
        System.assert(!infoAfter.Locked__c);
        System.assertEquals(infoAfter.Highest_Priority__c, null); // None left
        System.assertEquals(infoAfter.Lowest_Priority__c, null); // None left

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);

        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 0);
        Test.stopTest();
        System.assert(WSU_Kyou.latestImplementation instanceof WSU_Kyou_Batchable_Testing);

        System.assertEquals([select count() from Contact where LastName = 'NEWNAME'], 2);
        System.assertEquals([select count() from Contact where LastName != 'NEWNAME'], 0);
    }

    static testMethod void testPerpetuateInRun() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = JSON.serialize(new Map<String, Object>{
                    'class' => 'WSU_Kyou_Batchable_Testing',
                    'args' => null,
                    'size' => null,
                    'list' => false,
                    'object_list' => false
                })
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Lowest_Priority__c = 0,
                Highest_Priority__c = 0,
                Locked__c = false
            )
        });

        WSU_Kyou.setOptions(true, false, false);

        // Ordering lets us grab the one we made later... I guess I could arrange for the ID to come back or to filter
        // them out but this works for now.
        String scheduledQuery = 'select CronJobDetail.Name, State from CronTrigger where CronJobDetail.Name = \'WSU_Kyou\' and State not in (\'Aborted\', \'Completed\', \'Failed\') order by CreatedDate desc';
        // This result doesn't actually matter, because it will go away 
        List<CronTrigger> scheduledBefore = Database.query(scheduledQuery);
        if (scheduledBefore.size() > 0) {
            throw new WSU_Kyou.KyouException('Please delete all WSU_Kyou_Scheduled Scheduled Apex jobs before running tests.');
        }

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        Test.startTest();
        Set<ID> batchJobIds = WSU_Kyou.run();
        List<AsyncApexJob> afterRun = [select ApexClass.Name, Status from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assertEquals(before + 1, afterRun.size());
        System.assertEquals(afterRun.get(0).ApexClass.Name, 'WSU_Kyou_Batchable');
        System.assertEquals(afterRun.get(0).Status, 'Queued');

        List<CronTrigger> scheduledAfter = Database.query(scheduledQuery);
        System.assertEquals(scheduledAfter.size(), 1);
        System.assertEquals(scheduledAfter.get(0).CronJobDetail.Name, 'WSU_Kyou');
        System.assertEquals(scheduledAfter.get(0).State, 'WAITING');

        WSU_Kyou_Info__c infoAfter = WSU_Kyou_Info__c.getAll().values().get(0);
        System.assert(!infoAfter.Locked__c);
        System.assertEquals(infoAfter.Highest_Priority__c, null); // None left
        System.assertEquals(infoAfter.Lowest_Priority__c, null); // None left

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);

        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 0);

        // Now WSU_Kyou_Batchable_Testing will complete, making all of the LastNames == 'DEFAULT'.
        Test.stopTest();

        System.assertEquals([select count() from Contact where LastName = 'DEFAULT'], 2);
        System.assertEquals([select count() from Contact where LastName != 'DEFAULT'], 0);
    }

    static testMethod void testRunLocked() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = JSON.serialize(new Map<String, Object>{
                    'class' => 'WSU_Kyou_Batchable_Testing',
                    'args' => null,
                    'size' => null,
                    'list' => false,
                    'object_list' => false
                })
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Lowest_Priority__c = 0,
                Highest_Priority__c = 0,
                Locked__c = true
            )
        });

        Integer numScheduledBefore = [select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ];

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        Set<ID> kyouInfoId = WSU_Kyou.run();
        Integer afterRun = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before, afterRun); // Locked, so didn't run

        System.assertEquals([select count()
            from CronTrigger
            where CronJobDetail.Name = 'WSU_Kyou' and
            State not in (
                'Aborted',
                'Completed',
                'Failed'
            )
        ], numScheduledBefore); // perpetuateInRun defaults to false

        WSU_Kyou_Info__c infoAfter = WSU_Kyou_Info__c.getAll().values().get(0);
        // No change to kyouInfo
        System.assert(infoAfter.Locked__c);
        System.assertEquals(infoAfter.Highest_Priority__c, 0);
        System.assertEquals(infoAfter.Lowest_Priority__c, 0);
        System.assertEquals(kyouInfoId.size(), 1);
        System.assert(kyouInfoId.contains(infoAfter.Id));

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);

        // Queue Entry is still there
        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 1);
    }

    static testMethod void testPerpetuateInFinish() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = JSON.serialize(new Map<String, Object>{
                    'class' => 'WSU_Kyou_Batchable_Testing',
                    'args' => null,
                    'size' => null,
                    'list' => false,
                    'object_list' => false
                })
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Lowest_Priority__c = 0,
                Highest_Priority__c = 0,
                Locked__c = false
            )
        });

        WSU_Kyou.setOptions(false, true, false);

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        String scheduledQuery = 'select CronJobDetail.Name, State from CronTrigger where CronJobDetail.Name = \'WSU_Kyou\' and State not in (\'Aborted\', \'Completed\', \'Failed\')';
        List<CronTrigger> scheduledBefore = Database.query(scheduledQuery);
        if (scheduledBefore.size() > 0) {
            throw new WSU_Kyou.KyouException('Please delete all WSU_Kyou_Scheduled Scheduled Apex jobs before running tests.');
        }

        Test.startTest();
        // This will start WSU_Kyou_Batchable_Testing, but it won't complete until stopTest() below
        Set<ID> batchJobIds = WSU_Kyou.run();

        List<AsyncApexJob> afterRun = [select ApexClass.Name, Status from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun.size());
        System.assertEquals(afterRun.get(0).ApexClass.Name, 'WSU_Kyou_Batchable');
        System.assertEquals(afterRun.get(0).Status, 'Queued');

        // No perpetuation yet
        List<CronTrigger> scheduledAfter = Database.query(scheduledQuery);
        System.assertEquals(scheduledAfter.size(), 0);

        // Now WSU_Kyou_Batchable_Testing will complete, making all of the LastNames == 'DEFAULT'.
        // The scheduleBatch() inside finish() will also run now
        Test.stopTest();

        List<CronTrigger> scheduledAfterStop = Database.query(scheduledQuery);
        System.assertEquals(scheduledAfterStop.size(), 1);
        System.assertEquals(scheduledAfterStop.get(0).CronJobDetail.Name, 'WSU_Kyou');
        System.assertEquals(scheduledAfterStop.get(0).State, 'WAITING');

        System.assertEquals([select count() from Contact where LastName = 'DEFAULT'], 2);
        System.assertEquals([select count() from Contact where LastName != 'DEFAULT'], 0);

    }

    static testMethod void testDrasticMeasuresNotFull() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = JSON.serialize(new Map<String, Object>{
                    'class' => 'WSU_Kyou_Batchable_Testing',
                    'args' => null,
                    'size' => null,
                    'list' => false,
                    'object_list' => false
                })
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Lowest_Priority__c = 0,
                Highest_Priority__c = 0,
                Locked__c = false
            )
        });

        WSU_Kyou.setOptions(false, true, true);

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        String scheduledQuery = 'select CronJobDetail.Name, State from CronTrigger where CronJobDetail.Name = \'WSU_Kyou\' and State not in (\'Aborted\', \'Completed\', \'Failed\')';
        List<CronTrigger> scheduledBefore = Database.query(scheduledQuery);
        if (scheduledBefore.size() > 0) {
            throw new WSU_Kyou.KyouException('Please delete all WSU_Kyou_Scheduled Scheduled Apex jobs before running tests.');
        }

        Test.startTest();
        // This will start WSU_Kyou_Batchable_Testing, but it won't complete until stopTest() below
        Set<ID> batchJobIds = WSU_Kyou.run();

        List<AsyncApexJob> afterRun = [select ApexClass.Name, Status from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun.size());
        System.assertEquals(afterRun.get(0).ApexClass.Name, 'WSU_Kyou_Batchable');
        System.assertEquals(afterRun.get(0).Status, 'Queued');

        // No perpetuation yet
        List<CronTrigger> scheduledAfter = Database.query(scheduledQuery);
        System.assertEquals(scheduledAfter.size(), 0);

        // Now WSU_Kyou_Batchable_Testing will complete, making all of the LastNames == 'DEFAULT'.
        // The scheduleBatch() inside finish() will also run now
        Test.stopTest();

        List<CronTrigger> scheduledAfterStop = Database.query(scheduledQuery);
        System.assertEquals(scheduledAfterStop.size(), 1);
        System.assertEquals(scheduledAfterStop.get(0).CronJobDetail.Name, 'WSU_Kyou');
        System.assertEquals(scheduledAfterStop.get(0).State, 'WAITING');

        System.assertEquals([select count() from Contact where LastName = 'DEFAULT'], 2);
        System.assertEquals([select count() from Contact where LastName != 'DEFAULT'], 0);
    }

    static testMethod void testDrasticMeasuresFull() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = JSON.serialize(new Map<String, Object>{
                    'class' => 'WSU_Kyou_Batchable_Testing',
                    'args' => null,
                    'size' => null,
                    'list' => false,
                    'object_list' => false
                })
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Lowest_Priority__c = 0,
                Highest_Priority__c = 0,
                Locked__c = false
            )
        });

        WSU_Kyou.setOptions(false, true, true, true);

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        String scheduledQuery = 'select CronJobDetail.Name, State from CronTrigger where CronJobDetail.Name = \'WSU_Kyou\' and State not in (\'Aborted\', \'Completed\', \'Failed\')';
        List<CronTrigger> scheduledBefore = Database.query(scheduledQuery);
        if (scheduledBefore.size() > 0) {
            throw new WSU_Kyou.KyouException('Please delete all WSU_Kyou_Scheduled Scheduled Apex jobs before running tests.');
        }

        Test.startTest();
        // This will start WSU_Kyou_Batchable_Testing, but it won't complete until stopTest() below
        Set<ID> batchJobIds = WSU_Kyou.run();

        List<AsyncApexJob> afterRun = [select ApexClass.Name, Status from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun.size());
        System.assertEquals(afterRun.get(0).ApexClass.Name, 'WSU_Kyou_Batchable');
        System.assertEquals(afterRun.get(0).Status, 'Queued');

        // No perpetuation yet
        List<CronTrigger> scheduledAfter = Database.query(scheduledQuery);
        System.assertEquals(scheduledAfter.size(), 0);

        // Now WSU_Kyou_Batchable_Testing will complete, making all of the LastNames == 'DEFAULT'.
        // drasticMeasures is forced so WSU_Kyou will run again here.
        Test.stopTest();

        List<CronTrigger> scheduledAfterStop = Database.query(scheduledQuery);
        System.assertEquals(scheduledAfterStop.size(), 0);

        List<AsyncApexJob> afterRunStop = [select ApexClass.Name, Status from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(afterRunStop.size(), 0); // No runs are pending

        List<AsyncApexJob> afterRunStopKyou = [select ApexClass.Name, Status from AsyncApexJob where Status = 'Completed' and ApexClass.Name = 'WSU_Kyou' and JobType = 'BatchApex'];
        System.assertEquals(afterRunStopKyou.size(), 1); // The one that ran at stopTest()

        List<AsyncApexJob> afterRunStopTestingClass = [select ApexClass.Name, Status from AsyncApexJob where Status = 'Completed' and ApexClass.Name = 'WSU_Kyou_Batchable' and JobType = 'BatchApex'];
        System.assertEquals(afterRunStopTestingClass.size(), 1); // The original batchable testing class

        System.assertEquals([select count() from Contact where LastName = 'DEFAULT'], 2);
        System.assertEquals([select count() from Contact where LastName != 'DEFAULT'], 0);

    }

    static testMethod void testNonBatchable() {
        Boolean success = true;
        try {
            ID returned = WSU_Kyou.enqueueBatch(WSU_KyouTest.class);
        } catch (WSU_Kyou.KyouException e) {
            success = false;
            System.assertEquals(e.getMessage(), 'The submitted Class does not implement Database.Batchable<>');
        }

        System.assert(!success);
    }


}
