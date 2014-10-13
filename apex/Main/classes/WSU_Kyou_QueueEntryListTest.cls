// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

@isTest
public class WSU_Kyou_QueueEntryListTest {
    static {
        ID previousInsertedID = null;
        for (Integer i = 0; i < 20; i++) {
            WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
            entry.generateQueueEntry(WSU_Kyou_Batchable.class, i, null, previousInsertedID);
            Database.SaveResult result = Database.insert(entry.sobj);
            previousInsertedID = result.getId();
        }
    }

    static testMethod void testTestDataSanityBareSOQL() {
        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Next__c from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entries.size(), 20);
        Integer nullNexts = 0;
        Set<ID> nextsSeen = new Set<ID>();
        for (WSU_Kyou_QueueEntry__c entry : entries) {
            if (entry.Next__c == null) {
                nullNexts++;
            } else {
                System.assert(!nextsSeen.contains(entry.Next__c));
                nextsSeen.add(entry.Next__c);
            }
        }
        System.assertEquals(nullNexts, 1);
    }

    static testMethod void testTestDataSanitySoop() {
        List<WSU_SObject> entries = WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class);
        System.assertEquals(entries.size(), 20);
        Integer nullNexts = 0;
        Set<ID> nextsSeen = new Set<ID>();
        for (WSU_SObject entry : entries) {
            if (entry.get('Next__c') == null) {
                nullNexts++;
            } else {
                System.assert(!nextsSeen.contains((ID)entry.get('Next__c')));
                nextsSeen.add((ID)entry.get('Next__c'));
            }
        }
        System.assertEquals(nullNexts, 1);
    }

    static testMethod void testOne() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        Integer total = 0;
        WSU_Kyou_QueueEntry previous = null;
        while (entries.hasNext()) {
            WSU_Kyou_QueueEntry entry = entries.next();
            total++;
            if (previous != null) {
                //System.assertEquals((ID)entry.get('Id'), (ID)previous.get('Next__c'));
            }
            previous = entry;
        }
        System.assertEquals(total, 20);
    }

    static testMethod void testTwice() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        Integer total = 0;
        WSU_Kyou_QueueEntry previous = null;
        while (entries.hasNext()) {
            WSU_Kyou_QueueEntry entry = entries.next();
            total++;
            if (previous != null) {
                //System.assertEquals((ID)entry.get('Id'), (ID)previous.get('Next__c'));
            }
            previous = entry;
        }
        System.assertEquals(total, 20);

        entries.reset();
        Integer total2 = 0;
        WSU_Kyou_QueueEntry previous2 = null;
        while (entries.hasNext()) {
            WSU_Kyou_QueueEntry entry = entries.next();
            total2++;
            if (previous2 != null) {
                //System.assertEquals((ID)entry.get('Id'), (ID)previous2.get('Next__c'));
            }
            previous2 = entry;
        }
        System.assertEquals(total2, 20);
    }

    static testMethod void testAddOne() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        ID next = null;
        for (Integer i = 0; i < 4; i++) {
            next = (ID)entries.next().get('Id');
        }
        //toAdd.put('Next__c', next);
        Boolean success = true;
        try {
            entries.add(toAdd, false);
        } catch (WSU_Kyou_QueueEntryList.QueueEntryListException e) {
            success = false;
            System.assertEquals(e.getMessage(), 'There is no Id for the new WSU_Kyou_QueueEntry.');
        }

        //System.assert(!success);
    }

    static testMethod void testAddOneEmpty() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(new List<WSU_SObject>());

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        entries.add(toAdd);

        System.assertEquals(entries.size(), 1);
        System.assert(entries.next().get('Id') != null);
    }

    static testMethod void testAddOneEmptyNoDML() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(new List<WSU_SObject>());

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        entries.add(toAdd, false);

        entries.doCommit();

        entries.reset();

        System.assertEquals(entries.size(), 1);
        System.assert(entries.next().get('Id') != null);
    }

    static testMethod void testAddOneEmptyNoDMLTwo() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(new List<WSU_SObject>());

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        entries.add(toAdd, false);

        System.assertEquals(entries.size(), 1);
        System.assert(entries.next().get('Id') == null);
    }

    /*
    static testMethod void testAddTwo() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<String> datas = new List<String>();
        while (entries.hasNext()) {
            datas.add((String)entries.next().get('Data__c'));
        }
        entries.reset();

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        ID next = null;
        for (Integer i = 0; i < 4; i++) {
            next = (ID)entries.next().get('Id');
        }
        toAdd.put('Next__c', next);
        entries.add(toAdd);

        System.assertEquals(datas.size() + 1, entries.size());

        entries.reset();
        for (Integer i = 0; i < 3; i++) {
            WSU_Kyou_QueueEntry fromNew = entries.next();
            System.assertEquals((String)fromNew.get('Data__c'), datas.get(i));
        }

        WSU_Kyou_QueueEntry newQueueEntry = entries.next();
        System.assertEquals(newQueueEntry.sobj, toAdd.sobj);

        for (Integer i = 4; i < entries.size(); i++) {
            WSU_Kyou_QueueEntry fromNew = entries.next();
            System.assertEquals((String)fromNew.get('Data__c'), datas.get(i - 1));
        }
    }
    */

    static testMethod void testAddThree() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<String> datas = new List<String>();
        while (entries.hasNext()) {
            datas.add((String)entries.next().get('Data__c'));
        }
        entries.reset();

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        entries.add(toAdd);

        System.assertEquals(datas.size() + 1, entries.size());

        entries.reset();
        for (Integer i = 0; i < entries.size() - 1; i++) {
            WSU_Kyou_QueueEntry fromNew = entries.next();
            System.assertEquals((String)fromNew.get('Data__c'), datas.get(i));
        }

        WSU_Kyou_QueueEntry newQueueEntry = entries.next();
        System.assertEquals(newQueueEntry.sobj, toAdd.sobj);

    }

    static testMethod void testAddFour() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<String> datas = new List<String>();
        while (entries.hasNext()) {
            datas.add((String)entries.next().get('Data__c'));
        }
        entries.reset();

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        Database.SaveResult result = Database.insert(new Contact(LastName = 'LASTNAME1'));
        ID conId = result.getId();
        toAdd.put('Next__c', conId);
        Boolean success = true;
        try {
            entries.add(toAdd);
        } catch (System.DmlException e) {
            success = false;
            System.assertEquals(e.getDmlFields(0).get(0), WSU_Kyou_QueueEntry__c.Next__c);
        }

        System.assert(!success);
    }

    static testMethod void testAddNoDMLOne() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<String> datas = new List<String>();
        while (entries.hasNext()) {
            datas.add((String)entries.next().get('Data__c'));
        }
        entries.reset();

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        ID next = null;
        for (Integer i = 0; i < 4; i++) {
            next = (ID)entries.next().get('Id');
        }
        entries.add(toAdd, false);

        System.assertEquals(datas.size() + 1, entries.size());

        entries.reset();
        for (Integer i = 0; i < entries.size() - 1; i++) {
            WSU_Kyou_QueueEntry entry = entries.next();
            System.assertEquals((String)entry.get('Data__c'), datas.get(i));
        }

        WSU_Kyou_QueueEntry newQueueEntry = entries.next();
        System.assertEquals(newQueueEntry.sobj, toAdd.sobj);

        WSU_Kyou_QueueEntryList newEntries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        System.assertEquals(datas.size(), newEntries.size());

        for (Integer i = 0; i < newEntries.size(); i++) {
            WSU_Kyou_QueueEntry fromNew = newEntries.next();
            System.assertEquals((String)fromNew.get('Data__c'), datas.get(i));
        }
    }

    static testMethod void testAddNoDMLWithCommitTwo() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<String> datas = new List<String>();
        while (entries.hasNext()) {
            datas.add((String)entries.next().get('Data__c'));
        }
        entries.reset();

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        entries.add(toAdd, false);

        System.assertEquals(datas.size() + 1, entries.size());

        entries.reset();
        for (Integer i = 0; i < entries.size() - 1; i++) {
            WSU_Kyou_QueueEntry entry = entries.next();
            System.assertEquals((String)entry.get('Data__c'), datas.get(i));
        }

        WSU_Kyou_QueueEntry newQueueEntry = entries.next();
        System.assertEquals(newQueueEntry.sobj, toAdd.sobj);

        entries.doCommit();

        // It looks like the old WSU_Kyou_QueueEntryList gets the new data upon doCommit(), but I'll make a new one just in case.
        WSU_Kyou_QueueEntryList newEntries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        System.assertEquals(entries.size(), newEntries.size());

        entries.reset();
        for (Integer i = 0; i < newEntries.size() - 2; i++) {
            WSU_Kyou_QueueEntry entry = entries.next();
            WSU_Kyou_QueueEntry fromNew = newEntries.next();
            System.assertEquals((String)entry.get('Data__c'), (String)fromNew.get('Data__c'));
            //System.assertEquals((ID)entry.get('Next__c'), (ID)fromNew.get('Next__c'));
            System.assertEquals((ID)entry.get('Id'), (ID)fromNew.get('Id'));
        }

        WSU_Kyou_QueueEntry nextToLastEntry = entries.next();
        WSU_Kyou_QueueEntry nextToLastFromNew = newEntries.next();
        WSU_Kyou_QueueEntry lastEntry = entries.next();
        WSU_Kyou_QueueEntry lastFromNew = newEntries.next();
        System.assertEquals((String)nextToLastEntry.get('Data__c'), (String)nextToLastFromNew.get('Data__c'));
        System.assertEquals((String)lastEntry.get('Data__c'), (String)lastFromNew.get('Data__c'));
        //System.assertEquals((ID)nextToLastFromNew.get('Next__c'), (ID)lastFromNew.get('Id'));
        System.assert((ID)lastFromNew.get('Id') != null);
    }

    static testMethod void testAddNoDMLWithCommitThree() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<String> datas = new List<String>();
        while (entries.hasNext()) {
            datas.add((String)entries.next().get('Data__c'));
        }
        entries.reset();

        for (Integer i = 100; i < 115; i++) {
            WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
            toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, i);
            entries.add(toAdd, false);
        }

        System.assertEquals(datas.size() + 15, entries.size()); // I've added 15 above, so omit them from this check

        for (Integer i = 0; i < entries.size() - 15; i++) { // I've added 15 above, so omit them from this check
            WSU_Kyou_QueueEntry entry = entries.next();
            System.assertEquals((String)entry.get('Data__c'), datas.get(i));
        }

        entries.doCommit();

        // It looks like the old WSU_Kyou_QueueEntryList gets the new data upon doCommit(), but I'll make a new one just in case.
        WSU_Kyou_QueueEntryList newEntries = new WSU_Kyou_QueueEntryList(WSU_Soop.query('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        System.assertEquals(entries.size(), newEntries.size());

        entries.reset();
        newEntries.reset();
        WSU_Kyou_QueueEntry previous = null;
        for (Integer i = 0; i < newEntries.size() - 15; i++) {
            WSU_Kyou_QueueEntry entry = entries.next();
            WSU_Kyou_QueueEntry fromNew = newEntries.next();
            System.assertEquals((String)entry.get('Data__c'), (String)fromNew.get('Data__c'));
            //System.assertEquals((ID)entry.get('Next__c'), (ID)fromNew.get('Next__c'));
            System.assertEquals((ID)entry.get('Id'), (ID)fromNew.get('Id'));
            previous = fromNew; // For subsequent while loop
        }

        Integer count = 0;
        while (newEntries.hasNext()) {
            count++;
            WSU_Kyou_QueueEntry entry = newEntries.next();
            System.assert((ID)entry.get('Id') != null);
            if (count < 15) {
                //System.assertEquals((ID)previous.get('Next__c'), (ID)entry.get('Id'));
            }
            previous = entry;
        }
        //System.assertEquals(previous.get('Next__c'), null);
    }

}
