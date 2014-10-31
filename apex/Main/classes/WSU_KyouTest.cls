// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

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
    }

    static testMethod void testOne() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assertEquals(before, after);

        WSU_Kyou_QueueEntryList entries = WSU_Kyou.entries();
        WSU_Kyou_QueueEntry lastEntry = null;
        while (entries.hasNext()) {
            lastEntry = entries.next();
        }
        Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped((String)lastEntry.get('Data__c'));
        System.assertEquals((String)data.get('class'), 'WSU_Kyou_Batchable_Testing');
    }

    static testMethod void testConstructorCoverageOne() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, 26, (ID)null, false);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assertEquals(before, after);

        WSU_Kyou_QueueEntryList entries = WSU_Kyou.entries();
        WSU_Kyou_QueueEntry lastEntry = null;
        while (entries.hasNext()) {
            lastEntry = entries.next();
        }
        Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped((String)lastEntry.get('Data__c'));
        System.assertEquals((String)data.get('class'), 'WSU_Kyou_Batchable_Testing');
    }

    static testMethod void testConstructorCoverageTwo() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, 26, false);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assertEquals(before, after);

        WSU_Kyou_QueueEntryList entries = WSU_Kyou.entries();
        WSU_Kyou_QueueEntry lastEntry = null;
        while (entries.hasNext()) {
            lastEntry = entries.next();
        }
        Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped((String)lastEntry.get('Data__c'));
        System.assertEquals((String)data.get('class'), 'WSU_Kyou_Batchable_Testing');
    }

    static testMethod void testOneWithBatchsize() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, 11);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assertEquals(before, after);

        WSU_Kyou_QueueEntryList entries = WSU_Kyou.entries();
        WSU_Kyou_QueueEntry lastEntry = null;
        while (entries.hasNext()) {
            lastEntry = entries.next();
        }
        Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped((String)lastEntry.get('Data__c'));
        System.assertEquals((String)data.get('class'), 'WSU_Kyou_Batchable_Testing');
        System.assertEquals((Integer)data.get('size'), 11);
    }

    static testMethod void testNonBatchable() {
        Boolean success = true;
        try {
            ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_QueueEntry.class);
        } catch (WSU_Kyou.KyouException e) {
            success = false;
            System.assertEquals(e.getMessage(), 'The submitted Class does not implement Database.Batchable<>');
        }

        System.assert(!success);
    }

    static testMethod void testTryNowOne() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, true);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assert(before >= 5 || before + 1 == after);

        WSU_Kyou_QueueEntryList entries = WSU_Kyou.entries();
        System.assertEquals(entries.size(), 0);
    }

    static testMethod void testTryNowTwoWithBlankArgs() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, 21, null, null, true);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assert(before >= 5 || before + 1 == after);

        WSU_Kyou_QueueEntryList entries = WSU_Kyou.entries();
        System.assertEquals(entries.size(), 0);
    }

    static testMethod void testTryNowTwoWithRealArgs() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, 21, new Map<String, Object>{'someParam' => 'NEWNAME'}, null, true);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assert(before >= 5 || before + 1 == after);

        WSU_Kyou_QueueEntryList entries = WSU_Kyou.entries();
        System.assertEquals(entries.size(), 0);
    }

    static testMethod void testTryNowThreeActuallyRun() {
        Test.startTest();
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, 21, new Map<String, Object>{'someParam' => 'NEWNAME'}, null, true);
        Test.stopTest();

        for (Contact con : [select Id, LastName from Contact]) {
            System.assertEquals(con.LastName, 'NEWNAME');
        }
    }

    static testMethod void testRunOne() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, false);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before, after);

        Set<ID> batchJobIds = WSU_Kyou.run();
        Integer afterRun = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun);
    }

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

    static testMethod void testRunTwo() {
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, 21, null, null, false);

        Test.startTest();
        Set<ID> batchJobIds = WSU_Kyou.run();
        Test.stopTest();
        System.assert(WSU_Kyou.latestImplementation instanceof WSU_Kyou_Batchable_Testing);

        for (Contact con : [select Id, LastName from Contact]) {
            System.assertEquals(con.LastName, 'DEFAULT');
        }
    }

    static testMethod void testNoCommit() {
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, 21, new Map<String, Object>{'names' => new Map<String, Set<String>>{'Contact' => new Set<String>()}}, null, false);
        System.assertEquals(WSU_Kyou.entries().size(), 1);

        WSU_Kyou.refreshEntries();
        System.assertEquals(WSU_Kyou.entries().size(), 0);
    }

    static testMethod void testCommit() {
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class, 21, new Map<String, Object>{'names' => new Map<String, Set<String>>{'Contact' => new Set<String>()}}, null, false);
        System.assertEquals(WSU_Kyou.entries().size(), 1);

        WSU_Kyou.doCommit();
        //System.assertEquals([select count() from WSU_Kyou_QueueEntry__c where Top__c = true], 1);
        WSU_Kyou.refreshEntries();
        System.assertEquals(WSU_Kyou.entries().size(), 1);
    }

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

    static testMethod void testOneStartReturnsList() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_ListBatchable_Testing.class, null, null, null, false, false, true);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assertEquals(before, after);

        WSU_Kyou_QueueEntryList entries = WSU_Kyou.entries();
        WSU_Kyou_QueueEntry lastEntry = null;
        while (entries.hasNext()) {
            lastEntry = entries.next();
        }
        Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped((String)lastEntry.get('Data__c'));
        System.assertEquals((String)data.get('class'), 'WSU_Kyou_ListBatchable_Testing');
        System.assertEquals((Boolean)data.get('list'), true);
    }

    static testMethod void testTryNowOneStartReturnsList() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_ListBatchable_Testing.class, null, null, null, true, false, true);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assert(before >= 5 || before + 1 == after);

        WSU_Kyou_QueueEntryList entries = WSU_Kyou.entries();
        System.assertEquals(entries.size(), 0);
    }

    static testMethod void testRunOneStartReturnsList() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_ListBatchable_Testing.class, null, null, null, false, false, true);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before, after);

        Set<ID> batchJobIds = WSU_Kyou.run();
        Integer afterRun = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun);
    }

    static testMethod void testRunOneStartReturnsObjectList() {
        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_ObjectListBatchable_Testing.class, null, null, null, false, false, false, true);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before, after);

        Set<ID> batchJobIds = WSU_Kyou.run();
        Integer afterRun = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        System.assertEquals(before + 1, afterRun);
    }

    static testMethod void testPerpetuateInRun() {
        WSU_Kyou.setOptions(true, false, false);

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assertEquals(before, after);

        String scheduledQuery = 'select CronJobDetail.Name, State from CronTrigger where CronJobDetail.Name = \'WSU_Kyou\' and State not in (\'Aborted\', \'Completed\', \'Failed\')';
        List<CronTrigger> scheduledBefore = Database.query(scheduledQuery);
        System.assertEquals(scheduledBefore.size(), 0);

        Test.startTest();
        // This will start WSU_Kyou_Batchable_Testing, but it won't complete until stopTest() below
        Set<ID> batchJobIds = WSU_Kyou.run();

        List<AsyncApexJob> afterRun = [select ApexClass.Name, Status from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assertEquals(before + 1, afterRun.size());
        System.assertEquals(afterRun.get(0).ApexClass.Name, 'WSU_Kyou_Batchable');
        System.assertEquals(afterRun.get(0).Status, 'Queued');

        List<CronTrigger> scheduledAfter = Database.query(scheduledQuery);
        System.assertEquals(scheduledAfter.size(), 1);
        System.assertEquals(scheduledAfter.get(0).CronJobDetail.Name, 'WSU_Kyou');
        System.assertEquals(scheduledAfter.get(0).State, 'WAITING');

        // Now WSU_Kyou_Batchable_Testing will complete, making all of the LastNames == 'DEFAULT'.
        Test.stopTest();

        System.assertEquals([select count() from Contact where LastName = 'DEFAULT'], 2);
        System.assertEquals([select count() from Contact where LastName != 'DEFAULT'], 0);

    }

    static testMethod void testPerpetuateInFinish() {
        WSU_Kyou.setOptions(false, true, false);

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assertEquals(before, after);

        String scheduledQuery = 'select CronJobDetail.Name, State from CronTrigger where CronJobDetail.Name = \'WSU_Kyou\' and State not in (\'Aborted\', \'Completed\', \'Failed\')';
        List<CronTrigger> scheduledBefore = Database.query(scheduledQuery);
        System.assertEquals(scheduledBefore.size(), 0);

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
        WSU_Kyou.setOptions(false, true, true);

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assertEquals(before, after);

        String scheduledQuery = 'select CronJobDetail.Name, State from CronTrigger where CronJobDetail.Name = \'WSU_Kyou\' and State not in (\'Aborted\', \'Completed\', \'Failed\')';
        List<CronTrigger> scheduledBefore = Database.query(scheduledQuery);
        System.assertEquals(scheduledBefore.size(), 0);

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
        WSU_Kyou.setOptions(false, true, true, true);

        Integer before = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];
        ID returned = WSU_Kyou.enqueueBatch(WSU_Kyou_Batchable_Testing.class);
        Integer after = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing' or Status = 'Preparing') and JobType = 'BatchApex'];

        System.assertEquals(before, after);

        String scheduledQuery = 'select CronJobDetail.Name, State from CronTrigger where CronJobDetail.Name = \'WSU_Kyou\' and State not in (\'Aborted\', \'Completed\', \'Failed\')';
        List<CronTrigger> scheduledBefore = Database.query(scheduledQuery);
        System.assertEquals(scheduledBefore.size(), 0);

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
        System.assertEquals(afterRunStopTestingClass.size(), 1); // The original batchable testing clas

        System.assertEquals([select count() from Contact where LastName = 'DEFAULT'], 2);
        System.assertEquals([select count() from Contact where LastName != 'DEFAULT'], 0);

    }

    static testMethod void testScheduled() {
        String scheduledQuery = 'select CronJobDetail.Name, State from CronTrigger where CronJobDetail.Name = \'WSU_Kyou\' and State not in (\'Aborted\', \'Completed\', \'Failed\')';
        List<CronTrigger> scheduledBefore = Database.query(scheduledQuery);
        System.assertEquals(scheduledBefore.size(), 0);

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

}
