// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

@isTest
public class WSU_Kyou_QueueEntryTest {
    private static WSU_Kyou_QueueEntry entry1 = null;
    private static ID rawEntryId1 = null;

    /*
    static {
        entry1 = new WSU_Kyou_QueueEntry();
        entry1.generateQueueEntry(WSU_Kyou_ListBatchable_Testing.class, 1, null, null);
        Database.SaveResult result = Database.insert(entry1.sobj);

        result = Database.insert(new WSU_Kyou_QueueEntry__c(
            Next__c = null,
            Data__c = '{"flavor":{flavor},"class":"WSU_Kyou_ListBatchable_Testing","size":15,"args":{}}'
                .replace('{flavor}', String.valueOf(WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE.ordinal()))
        ));
        rawEntryId1 = result.getId();
    }

    static Boolean jsonObjectEquals(String lhs, String rhs) {
        Map<String, Object> lhsObj = (Map<String, Object>)JSON.deserializeUntyped(lhs);
        Map<String, Object> rhsObj = (Map<String, Object>)JSON.deserializeUntyped(rhs);
        if (lhsObj.size() != rhsObj.size()) {
            return false;
        }
        for (String lhsKey : lhsObj.keySet()) {
            if (!rhsObj.containsKey(lhsKey) || lhsObj.get(lhsKey) != rhsObj.get(lhsKey)) {
                return false;
            }
        }
        return true;
    }

    static testMethod void testOne() {
        WSU_Kyou_QueueEntry entry2 = new WSU_Kyou_QueueEntry((WSU_Kyou_QueueEntry__c)entry1.sobj);
        System.assertEquals(entry2.get('Id'), entry2.get('Id'));
        System.assertEquals(entry2.get('Next__c'), entry2.get('Next__c'));
        System.assertEquals(entry2.get('Data__c'), entry2.get('Data__c'));
    }

    static testMethod void testTwo() {
        WSU_Kyou_QueueEntry entry2 = new WSU_Kyou_QueueEntry([select Id, Next__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :rawEntryId1 limit 1]);
        System.assertEquals(entry2.get('Id'), rawEntryId1);
        System.assertEquals(entry2.get('Next__c'), null);
        System.assert(jsonObjectEquals(
            (String)entry2.get('Data__c'),
            '{"flavor":{flavor},"class":"WSU_Kyou_ListBatchable_Testing","size":15,"args":{}}'
                .replace('{flavor}', String.valueOf(WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE.ordinal()))
        ));
    }

    static testMethod void testGenerateOne() {
        WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
        entry.generateQueueEntry(WSU_Kyou_Batchable.class, 17, new Map<String, Object>{'blah' => 'value'});
        System.assertEquals(entry.get('Next__c'), null);
        System.assert(jsonObjectEquals(
            (String)entry.get('Data__c'),
            '{"flavor":{flavor},"class":"WSU_Kyou_Batchable","size":17,"args":{"blah":"value"},"list":false,"object_list":false}'
                .replace('{flavor}', String.valueOf(WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE.ordinal()))
        ));
    }

    static testMethod void testGenerateOneList() {
        WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
        entry.generateQueueEntry(WSU_Kyou_Batchable.class, 17, new Map<String, Object>{'blah' => 'value'}, null, true);
        System.assertEquals(entry.get('Next__c'), null);
        System.assert(jsonObjectEquals(
            (String)entry.get('Data__c'),
            '{"flavor":{flavor},"class":"WSU_Kyou_Batchable","size":17,"args":{"blah":"value"},"list":true,"object_list":false}'
                .replace('{flavor}', String.valueOf(WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE.ordinal()))
        ));
    }

    static testMethod void testGenerateTwo() {
        WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
        entry.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        System.assertEquals(entry.get('Next__c'), null);
        System.assert(jsonObjectEquals(
            (String)entry.get('Data__c'),
            '{"flavor":{flavor},"class":"WSU_Kyou_Batchable","size":17,"args":null,"list":false,"object_list":false}'
                .replace('{flavor}', String.valueOf(WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE.ordinal()))
        ));
    }

    static testMethod void testGenerateThree() {
        WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
        entry.generateQueueEntry(WSU_Kyou_Batchable.class, WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE);
        System.assertEquals(entry.get('Next__c'), null);
        System.assert(jsonObjectEquals(
            (String)entry.get('Data__c'),
            '{"flavor":{flavor},"class":"WSU_Kyou_Batchable","size":null,"args":null,"list":false,"object_list":false}'
                .replace('{flavor}', String.valueOf(WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE.ordinal()))
        ));
    }

    static testMethod void testGenerateFour() {
        WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
        entry.generateQueueEntry(WSU_Kyou_Batchable.class, WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE, 11);
        System.assertEquals(entry.get('Next__c'), null);
        System.assert(jsonObjectEquals(
            (String)entry.get('Data__c'),
            '{"flavor":{flavor},"class":"WSU_Kyou_Batchable","size":11,"args":null,"list":false,"object_list":false}'
                .replace('{flavor}', String.valueOf(WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE.ordinal()))
        ));
    }

    static testMethod void testGenerateFive() {
        WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
        entry.generateQueueEntry(WSU_Kyou_Batchable.class, WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE, 11, new Map<String, Object>());
        System.assertEquals(entry.get('Next__c'), null);
        System.assert(jsonObjectEquals(
            (String)entry.get('Data__c'),
            '{"flavor":{flavor},"class":"WSU_Kyou_Batchable","size":11,"args":{},"list":false,"object_list":false}'
                .replace('{flavor}', String.valueOf(WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE.ordinal()))
        ));
    }

    static testMethod void testGenerateSix() {
        WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
        entry.generateQueueEntry(WSU_Kyou_Batchable.class, 11, new Map<String, Object>(), null, false, true);
        System.assertEquals(entry.get('Next__c'), null);
        System.assert(jsonObjectEquals(
            (String)entry.get('Data__c'),
            '{"flavor":{flavor},"class":"WSU_Kyou_Batchable","size":11,"args":{},"list":false,"object_list":true}'
                .replace('{flavor}', String.valueOf(WSU_Kyou_QueueEntry.JobFlavor.BATCHABLE.ordinal()))
        ));
    }

    static testMethod void testGetterTypeOne() {
        WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
        entry.generateQueueEntry(WSU_Kyou_Batchable.class, 11, new Map<String, Object>());
        System.assertEquals(String.valueOf(entry.batchableType), String.valueOf(WSU_Kyou_Batchable.class));
        System.assertEquals(entry.size, 11);
        System.assertEquals(entry.args, new Map<String, Object>());
    }

    static testMethod void testGetterTypeTwo() {
        WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
        System.assertEquals(entry.batchableType, null);
        System.assertEquals(entry.size, null);
        System.assertEquals(entry.args, null);
        System.assertEquals(entry.startReturnsList, null);
    }

    static testMethod void testGetterTypeThree() {
        WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
        entry.generateQueueEntry(WSU_Kyou_Batchable.class, (Integer)null, (Map<String, Object>)null);
        System.assertEquals(entry.size, null);
        System.assertEquals(entry.args, null);
    }
    */

}
