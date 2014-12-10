// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

@isTest
public class WSU_Kyou_QueueEntryListTest {
    private static ID initialStartTag = null;
    private static ID initialEndTag = null;
    private static ID intermediateTag = null;

    private static Map<String, String> initialEntryTagToNext = new Map<String, String>();
    private static Map<String, String> initialEntryNextToTag = new Map<String, String>();

    /*
    static {
        // The first one inserted will have a null next, so is the end of the list.
        // The last one inserted will have nothing pointing to it, so is the start of the list.
        ID previousInsertedID = null;
        for (Integer i = 0; i < 20; i++) {
            WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
            entry.generateQueueEntry(WSU_Kyou_Batchable.class, i, null, previousInsertedID);
            Database.SaveResult result = Database.insert(entry.sobj);
            initialEntryTagToNext.put(result.getId(), previousInsertedID);
            if (i != 0) {
                initialEntryNextToTag.put(previousInsertedID, result.getId());
            }
            previousInsertedID = result.getId();
            if (i == 0) {
                initialEndTag = result.getId();
            } else if (i == 4) {
                intermediateTag = result.getId();
            } else if (i == 19) {
                initialStartTag = result.getId();
            }
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
        Map<ID, WSU_SObject> entries = WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class);
        System.assertEquals(entries.size(), 20);
        Integer nullNexts = 0;
        Set<ID> nextsSeen = new Set<ID>();
        for (ID entryId : entries.keySet()) {
            WSU_SObject entry = entries.get(entryId);
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
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        System.assertEquals(entries.startTag, initialStartTag);
        System.assertEquals(entries.currentTag, initialStartTag);
        System.assertEquals(entries.endTag, initialEndTag);
        System.assertEquals(entries.startTagToInsert, null);

        System.assert(entries.entryTagToNext.equals(initialEntryTagToNext));
        System.assert(entries.entryNextToTag.equals(initialEntryNextToTag));
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);

        Integer total = 0;
        WSU_Kyou_QueueEntry previous = null;
        while (entries.hasNext()) {
            WSU_Kyou_QueueEntry entry = entries.next();
            total++;
            if (previous != null) {
                System.assertEquals((ID)entry.get('Id'), (ID)previous.get('Next__c'));
            }
            previous = entry;
        }
        System.assertEquals(total, 20);

        System.assertEquals(entries.startTag, initialStartTag);
        System.assertEquals(entries.currentTag, null);
        System.assertEquals(entries.endTag, initialEndTag);
        System.assertEquals(entries.startTagToInsert, null);
        // These shouldn't change
        System.assert(entries.entryTagToNext.equals(initialEntryTagToNext));
        System.assert(entries.entryNextToTag.equals(initialEntryNextToTag));
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);

        System.assertEquals(entries.next(), null); // Test extra call to next()
    }

    static testMethod void testTwice() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        Integer total = 0;
        WSU_Kyou_QueueEntry previous = null;
        while (entries.hasNext()) {
            WSU_Kyou_QueueEntry entry = entries.next();
            total++;
            if (previous != null) {
                System.assertEquals((ID)entry.get('Id'), (ID)previous.get('Next__c'));
            }
            previous = entry;
        }
        System.assertEquals(total, 20);

        entries.reset();

        System.assertEquals(entries.startTag, initialStartTag);
        System.assertEquals(entries.currentTag, initialStartTag);
        System.assertEquals(entries.endTag, initialEndTag);

        System.assert(entries.entryTagToNext.equals(initialEntryTagToNext));
        System.assert(entries.entryNextToTag.equals(initialEntryNextToTag));
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);

        Integer total2 = 0;
        WSU_Kyou_QueueEntry previous2 = null;
        while (entries.hasNext()) {
            WSU_Kyou_QueueEntry entry = entries.next();
            total2++;
            if (previous2 != null) {
                System.assertEquals((ID)entry.get('Id'), (ID)previous2.get('Next__c'));
            }
            previous2 = entry;
        }
        System.assertEquals(total2, 20);

        System.assertEquals(entries.startTag, initialStartTag);
        System.assertEquals(entries.currentTag, null);
        System.assertEquals(entries.endTag, initialEndTag);
        // These shouldn't change
        System.assert(entries.entryTagToNext.equals(initialEntryTagToNext));
        System.assert(entries.entryNextToTag.equals(initialEntryNextToTag));
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);

    }

    static testMethod void testAddOneNoDMLNotInsertedButNextSpecified() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        ID next = null;
        for (Integer i = 0; i < 4; i++) {
            next = (ID)entries.next().get('Id');
        }
        toAdd.put('Next__c', next);
        Boolean success = true;
        try {
            entries.add(toAdd, false);
        } catch (WSU_Kyou_QueueEntryList.QueueEntryListException e) {
            success = false;
            System.assertEquals(e.getMessage(), 'There is no Id for the new WSU_Kyou_QueueEntry.');
        }

        System.assert(!success);
    }

    static testMethod void testAddOneEmpty() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList();

        System.assertEquals(entries.startTag, null);
        System.assertEquals(entries.currentTag, null);
        System.assertEquals(entries.endTag, null);

        System.assertEquals(entries.entryTagToNext.size(), 0);
        System.assertEquals(entries.entryNextToTag.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        entries.add(toAdd);

        WSU_Kyou_QueueEntry justAdded = entries.next();

        System.assertEquals(entries.startTag, (String)justAdded.get('Id'));
        System.assertEquals(entries.currentTag, null);
        System.assertEquals(entries.endTag, (String)justAdded.get('Id'));

        System.assertEquals(entries.size(), 1);

        System.assert(justAdded.get('Id') != null);

        System.assert(entries.entryTagToNext.equals(new Map<String, String>{
            (String)justAdded.get('Id') => null
        }));
        System.assertEquals(entries.entryNextToTag.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);
    }

    static testMethod void testAddOneEmptyNoDML() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList();

        // testAddOneEmpty() does the empty list sanity checking

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        entries.add(toAdd, false); // A string '0' tag will get generated

        System.assertEquals(entries.startTag, '0');
        System.assertEquals(entries.currentTag, '0');
        System.assertEquals(entries.endTag, '0');

        System.assert(entries.entryTagToNext.equals(new Map<String, String>{
            '0' => null
        }));
        System.assertEquals(entries.entryNextToTag.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);

        entries.doCommit();
        System.assertEquals(entries.size(), 1);

        WSU_Kyou_QueueEntry justAdded = entries.next();
        ID justAddedId = (ID)justAdded.get('Id');

        System.assert(justAddedId != null);

        System.assertEquals(entries.startTag, justAddedId);
        System.assertEquals(entries.currentTag, null);
        System.assertEquals(entries.endTag, justAddedId);

        System.assert(entries.entryTagToNext.equals(new Map<String, String>{
            justAddedId => null
        }));
        System.assertEquals(entries.entryNextToTag.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);
    }

    static testMethod void testAddInTheMiddle() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<String> datas = new List<String>();
        Map<String, String> expectedEntryTagToNext = new Map<String, String>();
        Map<String, String> expectedEntryNextToTag = new Map<String, String>();
        while (entries.hasNext()) {
            WSU_Kyou_QueueEntry entry = entries.next();
            datas.add((String)entry.get('Data__c'));
            expectedEntryTagToNext.put((String)entry.get('Id'), (String)entry.get('Next__c'));
            if (entry.get('Next__c') != null) {
                expectedEntryNextToTag.put((String)entry.get('Next__c'), (String)entry.get('Id'));
            }
        }
        entries.reset();

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        ID next = null;
        ID inFrontOf = null;
        for (Integer i = 0; i < 4; i++) {
            WSU_Kyou_QueueEntry entry = entries.next();
            next = (ID)entry.get('Id');
            if (i == 2) { // After add, this one will point to the new one's Id
                inFrontOf = next;
            }
        }
        toAdd.put('Next__c', next);
        entries.add(toAdd);

        System.assertEquals(entries.startTag, initialStartTag);
        System.assertEquals(entries.currentTag, initialStartTag); // add() calls reset()
        System.assertEquals(entries.endTag, initialEndTag);

        expectedEntryTagToNext.put((String)toAdd.get('Id'), (String)next);
        expectedEntryTagToNext.put((String)inFrontOf, (String)toAdd.get('Id'));
        expectedEntryNextToTag.put((String)next, (String)toAdd.get('Id'));
        expectedEntryNextToTag.put((String)toAdd.get('Id'), (String)inFrontOf);

        System.assert(entries.entryTagToNext.equals(expectedEntryTagToNext));
        System.assert(entries.entryNextToTag.equals(expectedEntryNextToTag));
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);

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

    static testMethod void testAddAtEnd() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<String> datas = new List<String>();
        Map<String, String> expectedEntryTagToNext = new Map<String, String>();
        Map<String, String> expectedEntryNextToTag = new Map<String, String>();
        ID next = null;
        Integer entriessize = entries.size();
        Integer count = 0;
        ID inFrontOf = null;
        while (entries.hasNext()) {
            WSU_Kyou_QueueEntry entry = entries.next();
            datas.add((String)entry.get('Data__c'));
            expectedEntryTagToNext.put((String)entry.get('Id'), (String)entry.get('Next__c'));
            if (entry.get('Next__c') != null) {
                expectedEntryNextToTag.put((String)entry.get('Next__c'), (String)entry.get('Id'));
            }
            next = (ID)entry.get('Next__c');
            if (count == entriessize - 2) { // After add, this one will point to the new one's Id
                inFrontOf = next;
            }
            count++;
        }
        entries.reset();

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        entries.add(toAdd);

        System.assertEquals(entries.startTag, initialStartTag);
        System.assertEquals(entries.currentTag, initialStartTag); // add() calls reset()
        System.assertEquals(entries.endTag, (String)toAdd.get('Id'));

        expectedEntryTagToNext.put((String)toAdd.get('Id'), null);
        expectedEntryTagToNext.put((String)inFrontOf, (String)toAdd.get('Id'));
        expectedEntryNextToTag.put((String)toAdd.get('Id'), (String)inFrontOf);

        System.assert(entries.entryTagToNext.equals(expectedEntryTagToNext));
        System.assert(entries.entryNextToTag.equals(expectedEntryNextToTag));
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);

        System.assertEquals(datas.size() + 1, entries.size());

        entries.reset();
        for (Integer i = 0; i < entries.size() - 1; i++) {
            WSU_Kyou_QueueEntry fromNew = entries.next();
            System.assertEquals((String)fromNew.get('Data__c'), datas.get(i));
        }

        WSU_Kyou_QueueEntry newQueueEntry = entries.next();
        System.assertEquals(newQueueEntry.sobj, toAdd.sobj);
    }

    static testMethod void testAddBadNext() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
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

    static testMethod void testAddNoDMLAtTheEnd() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<String> datas = new List<String>();
        Map<String, String> expectedEntryTagToNext = new Map<String, String>();
        Map<String, String> expectedEntryNextToTag = new Map<String, String>();
        ID inFrontOf = null;
        Integer entriessize = entries.size();
        Integer count = 0;
        while (entries.hasNext()) {
            WSU_Kyou_QueueEntry entry = entries.next();
            datas.add((String)entry.get('Data__c'));
            expectedEntryTagToNext.put((String)entry.get('Id'), (String)entry.get('Next__c'));
            if (entry.get('Next__c') != null) {
                expectedEntryNextToTag.put((String)entry.get('Next__c'), (String)entry.get('Id'));
            }
            if (count == entriessize - 2) { // After add, this one will point to the new one's Id
                inFrontOf = (ID)entry.get('Next__c');
            }
            count++;
        }
        entries.reset();

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        entries.add(toAdd, false);

        System.assertEquals(entries.startTag, initialStartTag);
        System.assertEquals(entries.currentTag, initialStartTag); // add() calls reset()
        System.assertEquals(entries.endTag, '0');

        expectedEntryTagToNext.put('0', null);
        expectedEntryTagToNext.put((String)inFrontOf, '0');
        expectedEntryNextToTag.put('0', (String)inFrontOf);

        System.assert(entries.entryTagToNext.equals(expectedEntryTagToNext));
        System.assert(entries.entryNextToTag.equals(expectedEntryNextToTag));
        System.assert(entries.tagsWithNextsToUpdate.equals(new Map<String, String>{
            (String)inFrontOf => '0'
        }));
        System.assert(entries.tagsWithNextsToUpdateRev.equals(new Map<String, String>{
            '0' => (String)inFrontOf
        }));

        System.assertEquals(datas.size() + 1, entries.size());

        entries.reset();
        for (Integer i = 0; i < entries.size() - 1; i++) {
            WSU_Kyou_QueueEntry entry = entries.next();
            System.assertEquals((String)entry.get('Data__c'), datas.get(i));
        }

        WSU_Kyou_QueueEntry newQueueEntry = entries.next();
        System.assertEquals(newQueueEntry.sobj, toAdd.sobj);

        WSU_Kyou_QueueEntryList newEntries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        System.assertEquals(datas.size(), newEntries.size());

        for (Integer i = 0; i < newEntries.size(); i++) {
            WSU_Kyou_QueueEntry fromNew = newEntries.next();
            System.assertEquals((String)fromNew.get('Data__c'), datas.get(i));
        }
    }

    static testMethod void testAddNoDMLWithCommit() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<String> datas = new List<String>();
        Map<String, String> expectedEntryTagToNext = new Map<String, String>();
        Map<String, String> expectedEntryNextToTag = new Map<String, String>();
        ID inFrontOf = null;
        Integer entriessize = entries.size();
        Integer count = 0;
        while (entries.hasNext()) {
            WSU_Kyou_QueueEntry entry = entries.next();
            datas.add((String)entry.get('Data__c'));
            expectedEntryTagToNext.put((String)entry.get('Id'), (String)entry.get('Next__c'));
            if (entry.get('Next__c') != null) {
                expectedEntryNextToTag.put((String)entry.get('Next__c'), (String)entry.get('Id'));
            }
            if (count == entriessize - 2) { // After add, this one will point to the new one's Id
                inFrontOf = (ID)entry.get('Next__c');
            }
            count++;
        }
        entries.reset();

        WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
        toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, 17);
        entries.add(toAdd, false);

        System.assertEquals(datas.size() + 1, entries.size());

        entries.reset();
        System.assertEquals(entries.size(), 21);
        for (Integer i = 0; i < entries.size() - 1; i++) {
            WSU_Kyou_QueueEntry entry = entries.next();
            System.assertEquals((String)entry.get('Data__c'), datas.get(i));
        }

        WSU_Kyou_QueueEntry newQueueEntry = entries.next();
        System.assertEquals(newQueueEntry.sobj, toAdd.sobj);

        // Up until now, this case is tested in the last test

        entries.doCommit();

        System.assertEquals(entries.startTag, initialStartTag);
        System.assert((String)toAdd.get('Id') != null);
        System.assertEquals(entries.currentTag, initialStartTag); // doCommit() effectively resets the looper
        System.assertEquals(entries.endTag, (String)toAdd.get('Id'));

        expectedEntryTagToNext.put((String)toAdd.get('Id'), null);
        expectedEntryTagToNext.put((String)inFrontOf, (String)toAdd.get('Id'));
        expectedEntryNextToTag.put((String)toAdd.get('Id'), (String)inFrontOf);

        System.assert(entries.entryTagToNext.equals(expectedEntryTagToNext));
        System.assert(entries.entryNextToTag.equals(expectedEntryNextToTag));
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);

        // It looks like the old WSU_Kyou_QueueEntryList gets the new data upon doCommit(), but I'll make a new one just in case.
        WSU_Kyou_QueueEntryList newEntries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        System.assertEquals(entries.size(), newEntries.size());

        entries.reset();
        for (Integer i = 0; i < newEntries.size() - 2; i++) {
            WSU_Kyou_QueueEntry entry = entries.next();
            WSU_Kyou_QueueEntry fromNew = newEntries.next();
            System.assertEquals((String)entry.get('Data__c'), (String)fromNew.get('Data__c'));
            System.assertEquals((ID)entry.get('Next__c'), (ID)fromNew.get('Next__c'));
            System.assertEquals((ID)entry.get('Id'), (ID)fromNew.get('Id'));
        }

        WSU_Kyou_QueueEntry nextToLastEntry = entries.next();
        WSU_Kyou_QueueEntry nextToLastFromNew = newEntries.next();
        WSU_Kyou_QueueEntry lastEntry = entries.next();
        WSU_Kyou_QueueEntry lastFromNew = newEntries.next();
        System.assertEquals((String)nextToLastEntry.get('Data__c'), (String)nextToLastFromNew.get('Data__c'));
        System.assertEquals((String)lastEntry.get('Data__c'), (String)lastFromNew.get('Data__c'));
        System.assertEquals((ID)nextToLastFromNew.get('Next__c'), (ID)lastFromNew.get('Id'));
        System.assert((ID)lastFromNew.get('Id') != null);
    }

    static testMethod void testAddNoDMLWithCommitThree() {
        WSU_Kyou_QueueEntryList entries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<String> datas = new List<String>();
        Map<String, String> expectedEntryTagToNext = new Map<String, String>();
        Map<String, String> expectedEntryNextToTag = new Map<String, String>();
        Integer entriessize = entries.size();
        ID inFrontOf = null;
        Integer count = 0;
        while (entries.hasNext()) {
            WSU_Kyou_QueueEntry entry = entries.next();
            datas.add((String)entry.get('Data__c'));
            expectedEntryTagToNext.put((String)entry.get('Id'), (String)entry.get('Next__c'));
            if (entry.get('Next__c') != null) {
                expectedEntryNextToTag.put((String)entry.get('Next__c'), (String)entry.get('Id'));
            }
            if (count == entriessize - 2) { // After add, this one will point to the new one's Id
                inFrontOf = (ID)entry.get('Next__c');
            }
            count++;
        }
        entries.reset();

        List<WSU_Kyou_QueueEntry> additionals = new List<WSU_Kyou_QueueEntry>();
        for (Integer i = 100; i < 115; i++) {
            WSU_Kyou_QueueEntry toAdd = new WSU_Kyou_QueueEntry();
            toAdd.generateQueueEntry(WSU_Kyou_Batchable.class, i);
            entries.add(toAdd, false);
            additionals.add(toAdd);
        }

        System.assertEquals(datas.size() + 15, entries.size()); // I've added 15 above, so omit them from this check

        for (Integer i = 0; i < entries.size() - 15; i++) { // I've added 15 above, so omit them from this check
            WSU_Kyou_QueueEntry entry = entries.next();
            System.assertEquals((String)entry.get('Data__c'), datas.get(i));
        }

        System.assertEquals(entries.startTag, initialStartTag);
        System.assertEquals(entries.currentTag, '0'); // beginning of the entries added just above
        System.assertEquals(entries.endTag, '14');

        Map<String, String> preCommitExpectedEntryTagToNext = expectedEntryTagToNext.clone();
        Map<String, String> preCommitExpectedEntryNextToTag = expectedEntryNextToTag.clone();
        preCommitExpectedEntryTagToNext.put('14', null);
        preCommitExpectedEntryTagToNext.put((String)inFrontOf, '0');
        preCommitExpectedEntryNextToTag.put('0', (String)inFrontOf);
        for (Integer i = 0; i < 14; i++) {
            preCommitExpectedEntryTagToNext.put(String.valueOf(i), String.valueOf(i + 1));
            preCommitExpectedEntryNextToTag.put(String.valueOf(i + 1), String.valueOf(i));
        }

        System.assert(entries.entryTagToNext.equals(preCommitExpectedEntryTagToNext));
        System.assert(entries.entryNextToTag.equals(preCommitExpectedEntryNextToTag));
        Map<String, String> expectedTagsWithNextsToUpdate = new Map<String, String>{
            (String)inFrontOf => '0'
        };
        Map<String, String> expectedTagsWithNextsToUpdateRev = new Map<String, String>{
            '0' => (String)inFrontOf
        };
        for (Integer i = 0; i < 14; i++) {
            expectedTagsWithNextsToUpdate.put(String.valueOf(i), String.valueOf(i + 1));
            expectedTagsWithNextsToUpdateRev.put(String.valueOf(i + 1), String.valueOf(i));
        }
        System.assert(entries.tagsWithNextsToUpdate.equals(expectedTagsWithNextsToUpdate));
        System.assert(entries.tagsWithNextsToUpdateRev.equals(expectedTagsWithNextsToUpdateRev));

        entries.doCommit();

        System.assertEquals(entries.startTag, initialStartTag);
        System.assertEquals(entries.currentTag, initialStartTag);
        System.assertEquals(entries.endTag, (String)(additionals.get(additionals.size() - 1).get('Id')));

        Map<String, String> postCommitExpectedEntryTagToNext = expectedEntryTagToNext.clone();
        Map<String, String> postCommitExpectedEntryNextToTag = expectedEntryNextToTag.clone();
        postCommitExpectedEntryTagToNext.put(inFrontOf, (String)additionals.get(0).get('Id'));
        postCommitExpectedEntryNextToTag.put((String)additionals.get(0).get('Id'), inFrontOf);
        for (Integer i = 0; i < additionals.size() - 1; i++) {
            postCommitExpectedEntryTagToNext.put((String)(additionals.get(i).get('Id')), (String)(additionals.get(i + 1).get('Id')));
            postCommitExpectedEntryNextToTag.put((String)(additionals.get(i + 1).get('Id')), (String)(additionals.get(i).get('Id')));
        }
        postCommitExpectedEntryTagToNext.put((String)additionals.get(additionals.size() - 1).get('Id'), null);
        System.assert(entries.entryTagToNext.equals(postCommitExpectedEntryTagToNext));
        System.assert(entries.entryNextToTag.equals(postCommitExpectedEntryNextToTag));
        System.assertEquals(entries.tagsWithNextsToUpdate.size(), 0);
        System.assertEquals(entries.tagsWithNextsToUpdateRev.size(), 0);

        // It looks like the old WSU_Kyou_QueueEntryList gets the new data upon doCommit(), but I'll make a new one just in case.
        WSU_Kyou_QueueEntryList newEntries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        System.assertEquals(entries.size(), newEntries.size());

        entries.reset();
        newEntries.reset();
        WSU_Kyou_QueueEntry previous = null;
        for (Integer i = 0; i < newEntries.size() - 15; i++) {
            WSU_Kyou_QueueEntry entry = entries.next();
            WSU_Kyou_QueueEntry fromNew = newEntries.next();
            System.assertEquals((String)entry.get('Data__c'), (String)fromNew.get('Data__c'));
            System.assertEquals((ID)entry.get('Next__c'), (ID)fromNew.get('Next__c'));
            System.assertEquals((ID)entry.get('Id'), (ID)fromNew.get('Id'));
            previous = fromNew; // For subsequent while loop
        }

        count = 0;
        while (newEntries.hasNext()) {
            count++;
            WSU_Kyou_QueueEntry entry = newEntries.next();
            System.assert((ID)entry.get('Id') != null);
            if (count < 15) {
                System.assertEquals((ID)previous.get('Next__c'), (ID)entry.get('Id'));
            }
            previous = entry;
        }
        System.assertEquals(previous.get('Next__c'), null);
    }

    // This limit is kind of complicated.  I'm not really testing the limit here (it's typically a CPU limit that gets
    // hit, and the number you can insert depends on how many are already in the list).
    static testMethod void testNumQueueEntryLimit() {
        // Get the ones that are already there
        WSU_Kyou_QueueEntryList existingEntries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        WSU_Kyou_QueueEntry existingEntry = null;
        while (existingEntries.hasNext()) {
            existingEntry = existingEntries.next();
        }
        // Insert a ton more
        List<WSU_Kyou_QueueEntry__c> sobjsToInsert = new List<WSU_Kyou_QueueEntry__c>();
        Integer numToMake = 4000;

        for (Integer i = 0; i < numToMake; i++) {
            WSU_Kyou_QueueEntry entry = new WSU_Kyou_QueueEntry();
            entry.generateQueueEntry(WSU_Kyou_Batchable.class, i + 20);
            existingEntries.add(entry, false);
        }
        existingEntries.doCommit();

        System.assertEquals(existingEntries.size(), numToMake + 20);
    }

    static testMethod void testPopFirst() {
        WSU_Kyou_QueueEntryList existingEntries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<Object> result = existingEntries.popFirst();
        System.assertEquals(result.size(), 5);

        System.assertEquals(result.get(0), WSU_Kyou_Batchable.class);
        System.assertEquals(result.get(1), 19);
        System.assertEquals(result.get(2), null);
        System.assertEquals(result.get(3), false);
        System.assertEquals(result.get(4), false);
    }

    static testMethod void testPopFirstNoDML() {
        WSU_Kyou_QueueEntryList existingEntries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        List<Object> result = existingEntries.popFirst(false);
        System.assertEquals(result.size(), 6);

        System.assertEquals(result.get(0), WSU_Kyou_Batchable.class);
        System.assertEquals(result.get(1), 19);
        System.assertEquals(result.get(2), null);
        System.assertEquals(result.get(3), false);
        System.assertEquals(result.get(4), false);
        SObject sobj = (SObject)result.get(5);
    }

    static testMethod void testPopAllTheThings() {
        WSU_Kyou_QueueEntryList existingEntries = new WSU_Kyou_QueueEntryList(WSU_Soop.queryMap('select Id, Data__c, Next__c from WSU_Kyou_QueueEntry__c', WSU_Kyou_QueueEntry.class));
        Integer originalSize = existingEntries.size();
        for (Integer i = 0; i < originalSize; i++) {
            List<Object> result = existingEntries.popFirst(false);
            System.assertEquals(result.size(), 6);

            System.assertEquals(result.get(0), WSU_Kyou_Batchable.class);
            System.assertEquals(result.get(1), originalSize - (i + 1));
            System.assertEquals(result.get(2), null);
            System.assertEquals(result.get(3), false);
            System.assertEquals(result.get(4), false);
            SObject sobj = (SObject)result.get(5);
        }

        // Make sure the any more calls return null
        System.assertEquals(existingEntries.popFirst(false), null);
    }
    */
}
