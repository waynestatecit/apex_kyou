// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

@isTest
public class WSU_Kyou_MaintainerTest {
    static {
    }

    static testMethod void testLocked() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Locked__c = true,
                Highest_Priority__c = 0, // Doesn't matter here
                Lowest_Priority__c = 2// Doesn't matter here
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = '{}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 1,
                Data__c = '{}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 2,
                Data__c = '{}'
            )
        });

        Test.startTest();
        if (WSU_Kyou.slotsAvailable() > 0) {
            ID ignore = Database.executeBatch(new WSU_Kyou_Maintainer());
        } else {
            throw new WSU_Kyou_Maintainer.Kyou_MaintainerException(
                'There must be at least one available Batchable Apex slot to run this test.'
            );
        }
        Test.stopTest();

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 3);
        List<WSU_Kyou_Info__c> kyouInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(kyouInfos.size(), 1);
        WSU_Kyou_Info__c kyouInfo = kyouInfos.get(0);
        System.assertEquals(kyouInfo.Highest_Priority__c, 0);
        System.assertEquals(kyouInfo.Lowest_Priority__c, 2);
        System.assert(kyouInfo.Locked__c); // Still locked
    }

    static testMethod void testEmpty() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Locked__c = false,
                Highest_Priority__c = null,
                Lowest_Priority__c = null
            )
        });

        Test.startTest();
        if (WSU_Kyou.slotsAvailable() > 0) {
            ID ignore = Database.executeBatch(new WSU_Kyou_Maintainer());
        } else {
            throw new WSU_Kyou_Maintainer.Kyou_MaintainerException(
                'There must be at least one available Batchable Apex slot to run this test.'
            );
        }
        Test.stopTest();

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 0);
        List<WSU_Kyou_Info__c> kyouInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(kyouInfos.size(), 1);
        WSU_Kyou_Info__c kyouInfo = kyouInfos.get(0);
        System.assertEquals(kyouInfo.Highest_Priority__c, null);
        System.assertEquals(kyouInfo.Lowest_Priority__c, null);
        System.assert(!kyouInfo.Locked__c);
    }

    static testMethod void testOne() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Locked__c = false,
                Highest_Priority__c = null,
                Lowest_Priority__c = null
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 10,
                Data__c = '{}'
            )

        });

        Test.startTest();
        if (WSU_Kyou.slotsAvailable() > 0) {
            ID ignore = Database.executeBatch(new WSU_Kyou_Maintainer());
        } else {
            throw new WSU_Kyou_Maintainer.Kyou_MaintainerException(
                'There must be at least one available Batchable Apex slot to run this test.'
            );
        }
        Test.stopTest();

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);

        List<WSU_Kyou_QueueEntry__c> entries = [select Data__c, Priority__c from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entries.size(), 1);
        WSU_Kyou_QueueEntry__c entry = entries.get(0);
        System.assertEquals(entry.Priority__c, 0);

        List<WSU_Kyou_Info__c> kyouInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(kyouInfos.size(), 1);
        WSU_Kyou_Info__c kyouInfo = kyouInfos.get(0);
        System.assertEquals(kyouInfo.Highest_Priority__c, 0);
        System.assertEquals(kyouInfo.Lowest_Priority__c, 0);
        System.assert(!kyouInfo.Locked__c);
    }

    static testMethod void testTwo() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Locked__c = false,
                Highest_Priority__c = null,
                Lowest_Priority__c = null
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = '{"initial":0}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 1,
                Data__c = '{"initial":1}'
            )

        });

        Test.startTest();
        if (WSU_Kyou.slotsAvailable() > 0) {
            ID ignore = Database.executeBatch(new WSU_Kyou_Maintainer());
        } else {
            throw new WSU_Kyou_Maintainer.Kyou_MaintainerException(
                'There must be at least one available Batchable Apex slot to run this test.'
            );
        }
        Test.stopTest();

        List<WSU_Kyou_Open_Slots__c> openSlotsRecords = [select Data__c from WSU_Kyou_Open_Slots__c];
        System.assertEquals(openSlotsRecords.size(), 1);
        WSU_Kyou_Open_Slots__c openSlotsRecord = openSlotsRecords.get(0);
        System.assert(((List<Object>)JSON.deserializeUntyped(openSlotsRecord.Data__c)).equals(new List<Object>{
            1
        }));

        List<WSU_Kyou_QueueEntry__c> entries = [select Data__c, Priority__c from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entries.size(), 2);
        for (WSU_Kyou_QueueEntry__c entry : entries) {
            Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(entry.Data__c);
            if ((Integer)data.get('initial') == 0) {
                System.assertEquals(entry.Priority__c, 0);
            } else if ((Integer)data.get('initial') == 1) {
                System.assertEquals(entry.Priority__c, 2);
            }
        }

        List<WSU_Kyou_Info__c> kyouInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(kyouInfos.size(), 1);
        WSU_Kyou_Info__c kyouInfo = kyouInfos.get(0);
        System.assertEquals(kyouInfo.Highest_Priority__c, 0);
        System.assertEquals(kyouInfo.Lowest_Priority__c, 2);
        System.assert(!kyouInfo.Locked__c);
    }

    static testMethod void testABunch() {
        List<sObject> toInsert = new List<sObject>();

        // Make a bunch of them
        Integer toMake = 200;
        Integer highestPriority = null;
        Integer lowestPriority = null;
        Set<Integer> usedPriorities = new Set<Integer>();
        List<Integer> orderedPriorities = new List<Integer>();
        for (Integer i = 0; i < toMake; i++) {
            Integer priority = null;
            do {
                priority = Crypto.getRandomInteger();
            } while (usedPriorities.contains(priority) || priority < 0);
            usedPriorities.add(priority);
            orderedPriorities.add(priority);

            if (highestPriority == null || priority < highestPriority) {
                highestPriority = priority;
            }
            if (lowestPriority == null || priority > lowestPriority) {
                lowestPriority = priority;
            }

            toInsert.add(new WSU_Kyou_QueueEntry__c(
                Priority__c = priority,
                Data__c = '{"initial":' + String.valueOf(priority) + '}'
            ));
        }
        orderedPriorities.sort();

        toInsert.add(new WSU_Kyou_Info__c(
            Name = 'KyouInfo',
            Locked__c = false,
            Highest_Priority__c = highestPriority,
            Lowest_Priority__c = lowestPriority
        ));

        List<Database.SaveResult> results = Database.Insert(toInsert);

        Test.startTest();
        if (WSU_Kyou.slotsAvailable() > 0) {
            ID ignore = Database.executeBatch(new WSU_Kyou_Maintainer());
        } else {
            throw new WSU_Kyou_Maintainer.Kyou_MaintainerException(
                'There must be at least one available Batchable Apex slot to run this test.'
            );
        }
        Test.stopTest();

        List<WSU_Kyou_Open_Slots__c> openSlotsRecords = [select Data__c from WSU_Kyou_Open_Slots__c];
        Set<Integer> openSlots = new Set<Integer>();
        for (WSU_Kyou_Open_Slots__c openSlotsRecord : openSlotsRecords) {
            for (Object openSlotObj : (List<Object>)JSON.deserializeUntyped(openSlotsRecord.Data__c)) {
                openSlots.add((Integer)openSlotObj);
            }
        }
        Set<Integer> expectedOpenSlots = new Set<Integer>();
        for (Integer i = 1; i < (toMake * 2) - 2; i += 2) { // e.g.: 200 entries will cause the 200th entry to be at
                                                            // priority 398 = (200 * 2) - 2
            expectedOpenSlots.add(i);
        }
        System.assert(expectedOpenSlots.equals(openSlots));

        List<WSU_Kyou_QueueEntry__c> entries = [
            select Data__c, Priority__c from WSU_Kyou_QueueEntry__c order by Priority__c
        ];
        System.assertEquals(entries.size(), toMake);
        Integer expectedPriority = 0;
        for (WSU_Kyou_QueueEntry__c entry : entries) {
            System.assertEquals(entry.Priority__c, expectedPriority);

            Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(entry.Data__c);
            // Tests that ordering didn't change
            System.assertEquals((Integer)data.get('initial'), orderedPriorities.remove(0));

            expectedPriority += 2;
        }

        List<WSU_Kyou_Info__c> kyouInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(kyouInfos.size(), 1);
        WSU_Kyou_Info__c kyouInfo = kyouInfos.get(0);
        System.assertEquals(kyouInfo.Highest_Priority__c, 0);
        System.assertEquals(kyouInfo.Lowest_Priority__c, (toMake * 2) - 2);
        System.assert(!kyouInfo.Locked__c);
    }

}
