// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_Kyou_QueueEntryList implements Iterator<WSU_SObject> {
    private List<WSU_Kyou_QueueEntry> entries = new List<WSU_Kyou_QueueEntry>();
    private Integer i = 0;
    private Map<ID, Integer> entryIdToListIndex = new Map<ID, Integer>();

    //public WSU_Kyou_QueueEntryList(List<WSU_SObject> entries) {
        //this(entries, true); // FIXME; This isn't really tested.
    //}

    /*
    public WSU_Kyou_QueueEntryList(List<WSU_SObject> entries) {
        Map<ID, ID> entryIdToNextId = new Map<ID, ID>();
        for (WSU_SObject entry : entries) {
            entryIdToNextId.put(entry.sobj.Id, (ID)entry.sobj.get('Next__c'));
        }
        // The goal is to populate this.entries in the right order.
    }
    */

    //public WSU_Kyou_QueueEntryList(List<WSU_SObject> entries, Boolean ignoreOrdering) {
    //}
    public WSU_Kyou_QueueEntryList(List<WSU_SObject> entries) {
        for (WSU_SObject entry : entries) {
            addAndRecord((WSU_Kyou_QueueEntry)entry);
        }
        //Integer count = 0;
        /*
        while (entries.size() > 0) {
            //System.assertEquals(count, 0);
            //count++;
            List<Integer> toRemove = new List<Integer>();
            for (Integer j = 0; j < entries.size(); j++) { // For each new entry
                ID next = (ID)((WSU_Kyou_QueueEntry)entries.get(j)).sobj.get('Next__c');
                //ID next = (ID)((WSU_Kyou_QueueEntry)entries.get(j)).get('Next__c');
                if (next == null) { // If Next__c is null
                //if (entries.get(j).sobj.get('Next__c') == null) { // If Next__c is null
                //}
                    //this.entries.add((WSU_Kyou_QueueEntry)entries.get(j)); // Put this new entry at end of this.entries
                    addAndRecord((WSU_Kyou_QueueEntry)entries.get(j)); // Put this new entry at end of this.entries
                    if (toRemove.size() > 0) { // and prepend index to list for removal.
                        toRemove.add(0, j);
                    } else {
                        toRemove.add(j);
                    }
                } else {  // If Next__c is not null
                    //if (entryIdToListIndex.containsKey((ID)((WSU_Kyou_QueueEntry)entries.get(j)).get('Next__c'))) {
                    //}
                    if (entryIdToListIndex.containsKey(next)) {
                        addAndRecord(
                            (WSU_Kyou_QueueEntry)entries.get(j),
                            entryIdToListIndex.get(next)
                            //entryIdToListIndex.get((ID)((WSU_Kyou_QueueEntry)entries.get(j)).get('Next__c'))
                        );

                        if (toRemove.size() > 0) {
                            toRemove.add(0, j);
                        } else {
                            toRemove.add(j);
                        }
                    }
                    //for (Integer k = 0; k < this.entries.size(); k++) { // Look through this.entries
                        //if ((ID)((WSU_Kyou_QueueEntry)entries.get(j)).get('Next__c') == (ID)this.entries.get(k).get('Id')) {  // For the this.entry that the new entry is before
                            //// Then this one goes before the other one
                            ////this.entries.add(k, (WSU_Kyou_QueueEntry)entries.get(j));
                            //addAndRecord((WSU_Kyou_QueueEntry)entries.get(j), k);
                            //if (toRemove.size() > 0) {
                                //toRemove.add(0, j);
                            //} else {
                                //toRemove.add(j);
                            //}
                            //break;
                        //}
                    //}
                }
            }
            for (Integer remove : toRemove) {
                entries.remove(remove);
            }
        }
        */
    }

    public Boolean hasNext() {
        return i < entries.size();
    }

    public WSU_Kyou_QueueEntry next() {
        WSU_Kyou_QueueEntry toReturn = entries.get(i);
        i++;
        return toReturn;
    }

    public void reset() {
        i = 0;
    }

    public Integer size() {
        return entries.size();
    }

    public List<Object> popFirst() {
        WSU_Kyou_QueueEntry entry = entries.remove(0);
        if (entry.sobj.Id != null) {
            delete entry.sobj;
        }
        return new List<Object>{
            (Object)entry.batchableType,
            (Object)entry.size,
            (Object)entry.args,
            (Object)entry.startReturnsList,
            (Object)entry.startReturnsObjectList
        };
    }

    private void addAndRecord(WSU_Kyou_QueueEntry newEntry) {
        entries.add(newEntry);
        ID newEntryId = newEntry.sobj.Id;
        if (newEntryId != null) {
            entryIdToListIndex.put(newEntryId, entries.size() - 1);
        }
        //if (newEntry.get('Id') != null) {
            //entryIdToListIndex.put((ID)newEntry.get('Id'), entries.size() - 1);
        //}
    }

    private void addAndRecord(WSU_Kyou_QueueEntry newEntry, Integer index) {
        entries.add(index, newEntry);
        ID newEntryId = newEntry.sobj.Id;
        if (newEntryId != null) {
            entryIdToListIndex.put(newEntryId, index);
        }
    }

    public void add(WSU_Kyou_QueueEntry newEntry) {
        add(newEntry, true);
    }

    public void add(WSU_Kyou_QueueEntry newEntry, Boolean doDML) {
        List<WSU_Kyou_QueueEntry__c> toUpdate = new List<WSU_Kyou_QueueEntry__c>();
        if (doDML) {
            insert newEntry.sobj;
        }
        if (newEntry.get('Next__c') == null) { // We want this on the end
            if (newEntry.get('Id') != null) {
                if (entries.size() > 0) {
                    // These two are commented out while I fix the prioritization of jobs
                    //entries.get(entries.size() - 1).put('Next__c', newEntry.get('Id'));
                    //toUpdate.add((WSU_Kyou_QueueEntry__c)entries.get(entries.size() - 1).sobj);
                }
            }
            addAndRecord(newEntry);
        } else { // This block should never run while I'm assuming unorderness until I fix the prioritization of jobs
            System.assert(false);
            // Only allow non-inserted newEntry if appending to end
            if (newEntry.get('Id') == null) {
                throw new QueueEntryListException('There is no Id for the new WSU_Kyou_QueueEntry.');
            }
            for (Integer j = 0; j < entries.size(); j++) {
                WSU_Kyou_QueueEntry entry = entries.get(j);
                if (entry.get('Id') == newEntry.get('Next__c')) { // Found the next one
                    entries.get(j - 1).put('Next__c', newEntry.get('Id'));
                    addAndRecord(newEntry, j);
                    toUpdate.add((WSU_Kyou_QueueEntry__c)entries.get(j - 1).sobj);
                    break;
                }
            }
        }

        if (doDML) {
            List<Database.SaveResult> results = Database.Update(toUpdate);
        }
    }

    public void doCommit() {
        // Loop through looking for first null next not at end
        // Grab them, making sure Ids are null
        Integer firstOne = null;
        List<WSU_Kyou_QueueEntry__c> sobjs = new List<WSU_Kyou_QueueEntry__c>();
        for (Integer j = 0; j < entries.size(); j++) {
            if (entries.get(j).get('Id') == null) {
                /*
                if (j > 0 && entries.get(j - 1).get('Next__c') != null) { // I don't even think this is possible
                    throw new QueueEntryListException('Wrong ordering problem in doCommit(): ' + j + ' ' + entries.get(j - 1).sobj + ' ' + entries.get(j).sobj);
                }
                */
                sobjs.add((WSU_Kyou_QueueEntry__c)entries.get(j).sobj);
                if (firstOne == null) {
                    firstOne = j == 0 ? 0 : j - 1;
                }
            } else {
                if (firstOne != null) { // I don't even think this is possible
                    throw new QueueEntryListException('Null Next__c not at end problem in doCommit(): ' + j + ' ' + entries.get(j - 1).sobj + ' ' + entries.get(j).sobj);
                }
            }
        }

        // Insert them
        List<Database.SaveResult> results = Database.insert(sobjs);
        /*
        // Fix up nexts
        sobjs.clear();
        for (Integer j = firstOne; j < entries.size() - 1; j++) {
            entries.get(j).put('Next__c', entries.get(j + 1).get('Id'));
            sobjs.add((WSU_Kyou_QueueEntry__c)entries.get(j).sobj);
        }
        // Update them
        results = Database.update(sobjs);
        */

        //// Mark the top 5
        //sobjs.clear();
        //for (Integer j = 0; j < 5 && j < entries.size(); j++) {
            //entries.get(j).sobj.put('Top__c', true);
            //sobjs.add((WSU_Kyou_QueueEntry__c)entries.get(j).sobj);
        //}
        //// Update them
        //results = Database.update(sobjs);
    }

    public class QueueEntryListException extends Exception {}
}
