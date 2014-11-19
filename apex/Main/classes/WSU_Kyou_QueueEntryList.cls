// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_Kyou_QueueEntryList implements Iterator<WSU_SObject> {
    // Entries are identified by tags.  If an entry has a database ID, this ID is its tag.
    // If not, we make one up while the ID is not yet assigned.
    @TestVisible
    private Map<String, WSU_Kyou_QueueEntry> entries = new Map<String, WSU_Kyou_QueueEntry>();
    @TestVisible
    private Map<String, String> entryTagToNext = new Map<String, String>();
    @TestVisible
    private Map<String, String> entryNextToTag = new Map<String, String>();
    // This is a Map of entry tags to tags for uninserted entries for those entries that must have Next__c updated upon
    // next DML
    @TestVisible
    private Map<String, String> tagsWithNextsToUpdate = new Map<String, String>();
    // This is an inverse of the previous one
    @TestVisible
    private Map<String, String> tagsWithNextsToUpdateRev = new Map<String, String>();
    // In case we have an empty starting list and need to insert the first one
    @TestVisible
    private String startTagToInsert = null;

    private Integer tagCounter = 0;
    @TestVisible
    private String currentTag = null;
    @TestVisible
    private String startTag = null;
    @TestVisible
    private String endTag = null;

    public WSU_Kyou_QueueEntryList() {
    }

    public WSU_Kyou_QueueEntryList(Map<ID, WSU_SObject> incomingEntriesMap) {
        // First, this needs to be able to take data states where there is more than one distinct linked list in the
        // object space.  Somehow order by biggest to smallest?
        // Then, doCommit needs to be able to reconcile these into one.  This is not a big deal for safebatch because
        // this will all get called from finish(), which really don't be doing much work.
        // The idea here is that someone should be able ot add to this without making the whole thing load into their
        // apex invocation - then the whole thing will load correctly when Kyou tries to query for the next jobs.
        if (incomingEntriesMap.size() == 0) {
            return;
        }
        Set<String> ids = new Set<String>();
        Set<String> nexts = new Set<String>();
        for (ID entryId : incomingEntriesMap.keySet()) {
            WSU_SObject entry = incomingEntriesMap.get(entryId);
            String id = (String)entry.get('Id');
            ids.add(id);
            String next = (String)entry.get('Next__c');
            if (next == null) {
                if (endTag == null) {
                    // Save this one as the end
                    endTag = id;
                } else {
                    throw new QueueEntryListException(
                        'Something is wrong - there is more than one Queue Entry with a null Next__c: ' + entries.get(id) + ' ' + entry
                    );
                }
            } else {
                nexts.add(next);
                entryNextToTag.put(next, id);
            }
            entries.put(id, (WSU_Kyou_QueueEntry)entry);
            entryTagToNext.put(id, next);
        }
        Boolean changed = ids.removeAll(nexts);
        System.assertEquals(ids.size(), 1); // Make sure there is only one starting entry (the one to which no Next__c
                                            // points
        startTag = currentTag = new List<String>(ids).get(0);
    }

    private String getTag() {
        String toReturn = String.valueOf(tagCounter);
        tagCounter++;
        return toReturn;
    }

    public Boolean hasNext() {
        return currentTag != null;
    }

    public WSU_Kyou_QueueEntry next() {
        if (currentTag == null) {
            return null;
        }
        WSU_Kyou_QueueEntry toReturn = entries.get(currentTag);
        currentTag = entryTagToNext.get(currentTag); // 'Increment' iteration pointer
        return toReturn;
    }

    public void reset() {
        currentTag = startTag;
    }

    public Integer size() {
        return entries.size();
    }

    public List<Object> popFirst() {
        return popFirst(true);
    }

    public List<Object> popFirst(Boolean doDML) {
        if (startTag == null) {
            return null;
        }
        String originalStartTag = startTag;
        WSU_Kyou_QueueEntry entry = entries.remove(originalStartTag);
        startTag = (String)entry.get('Next__c');
        reset();
        // Map.remove() won't complain if a key isn't there
        entryTagToNext.remove(originalStartTag);
        tagsWithNextsToUpdate.remove(originalStartTag);
        entryNextToTag.remove(startTag);
        tagsWithNextsToUpdateRev.remove(startTag);

        List<Object> toReturn = new List<Object>{
            (Object)entry.batchableType,
            (Object)entry.size,
            (Object)entry.args,
            (Object)entry.startReturnsList,
            (Object)entry.startReturnsObjectList
        };
        if (doDML && entry.sobj.Id != null) {
            delete entry.sobj;
        } else {
            toReturn.add((Object)entry.sobj);
        }
        return toReturn;
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
            String addedTag = null;
            // Add to entries
            if (newEntry.get('Id') == null) {
                addedTag = getTag();
                // entry for the previous end one must get Next__c updated to this new tag - here, we don't have an Id
                // for the new one, so instead we save the tag of the old end one with the tag of the new one for later
                // substituting
                // Keep in mind that this might cascade because we can add lots of next == null in a row
                // What if endTag is null because entries is empty?
                if (endTag != null) { // don't do this for the first entry getting added to an empty list
                    tagsWithNextsToUpdate.put(endTag, addedTag);
                    tagsWithNextsToUpdateRev.put(addedTag, endTag);
                } else {
                    startTagToInsert = addedTag;
                }
            } else {
                addedTag = (String)newEntry.get('Id');
                // entry for the previous end one must get Next__c updated to this new tag - here, it's the Id of the
                // new one
                if (endTag != null) { // don't do this for the first entry getting added to an empty list
                    entries.get(endTag).put('Next__c', (ID)addedTag);
                }
            }
            entries.put(addedTag, newEntry);
            // entryTagToNext for the previous end one must now point to this new one
            if (endTag != null) { // don't do this for the first entry getting added to an empty list
                entryTagToNext.put(endTag, addedTag);
                entryNextToTag.put(addedTag, endTag);
            } else {
                currentTag = startTag = addedTag; // First one!
            }
            // put this new one in entryTagToNext with a null value
            entryTagToNext.put(addedTag, null);
            // endTag must point at this new one
            endTag = addedTag;
        } else {
            // Only allow non-inserted newEntry if appending to end
            if (newEntry.get('Id') == null) {
                throw new QueueEntryListException('There is no Id for the new WSU_Kyou_QueueEntry.');
            }
            String newId = (String)newEntry.get('Id');
            String newNext = (String)newEntry.get('Next__c');
            entries.put(newId, newEntry);

            String leftHandSide = entryNextToTag.get(newNext);
            // Update the left hand side of the insert gap
            entries.get(leftHandSide).put('Next__c', (ID)newId);
            toUpdate.add((WSU_Kyou_QueueEntry__c)entries.get(leftHandSide).sobj);
            // entryTagToNext for the left hand side must now point to this new one
            entryTagToNext.put(leftHandSide, newId);
            // entryNextToTag for this one must point to the left hand side
            entryNextToTag.put(newId, leftHandSide);
            // entryTagToNext for this one must point to the requested next
            entryTagToNext.put(newId, newNext);
            // entryNextToTag for the right hand side must point to this one
            entryNextToTag.put(newNext, newId);
        }

        if (doDML) {
            List<Database.SaveResult> results = Database.Update(toUpdate);
        }

        reset();
    }

    public void doCommit() {
        if (entries.size() == 0) {
            return;
        }

        // The point here is to insert the stuff at the end that was added before inserting
        // and reconcile the Next__c field for those before each newly inserted one
        // And, of course, update the bookkeeping internals so things are consistent

        List<WSU_Kyou_QueueEntry__c> sobjs = new List<WSU_Kyou_QueueEntry__c>();
        List<String> oldTags = new List<String>();
        for (String addedTag : tagsWithNextsToUpdateRev.keySet()) {
            WSU_Kyou_QueueEntry entry = entries.get(addedTag);
            System.assert(entry.sobj.Id == null); // FIXME: Sanity check for now
            sobjs.add((WSU_Kyou_QueueEntry__c)entry.sobj);
            oldTags.add(addedTag);  // To be sure the ordering is preserved
        }

        // Case for adding to empty list
        if (startTagToInsert != null) {
            sobjs.add((WSU_Kyou_QueueEntry__c)entries.get(startTagToInsert).sobj);
            oldTags.add(startTagToInsert);  // To be sure the ordering is preserved
        }

        // Insert them
        List<Database.SaveResult> results = Database.insert(sobjs);

        // Map old tags to new IDs
        Map<String, ID> oldTagToNewId = new Map<String, ID>();
        for (Database.SaveResult result : results) {
            String oldTag = oldTags.remove(0);
            ID newTag = result.getId();
            oldTagToNewId.put(oldTag, newTag);
            // Fix up entryTagToNext
            String nextToMove = entryTagToNext.remove(oldTag);
            entryTagToNext.put((String)newTag, nextToMove);
            if (entryNextToTag.containsKey(oldTag)) {
                // Fix up entryNextToTag
                String tagToMove = entryNextToTag.remove(oldTag);
                entryNextToTag.put((String)newTag, tagToMove);
                // Fix up entryTagToNext
                entryTagToNext.put(tagToMove, (String)newTag);
            }
            // Fix up entryNextToTag
            if (nextToMove != null) {
                entryNextToTag.put(nextToMove, (String)newTag);
            }

            if (oldTag == endTag) {
                endTag = newTag;
            }
            if (oldTag == startTag) {
                startTag = newTag;
            }

            if (entries.containsKey(oldTag)) {
                // Update entries
                entries.put(newTag, entries.get(oldTag));
                entries.remove(oldTag);
            }
            if (tagsWithNextsToUpdate.containsKey(oldTag)) {
                tagsWithNextsToUpdate.put(newTag, tagsWithNextsToUpdate.get(oldTag));
                tagsWithNextsToUpdate.remove(oldTag);

                tagsWithNextsToUpdateRev.put(
                    tagsWithNextsToUpdate.get(newTag),
                    newTag
                );
            }
            if (tagsWithNextsToUpdateRev.containsKey(oldTag)) {
                tagsWithNextsToUpdateRev.put(newTag, tagsWithNextsToUpdateRev.get(oldTag));
                tagsWithNextsToUpdateRev.remove(oldTag);

                tagsWithNextsToUpdate.put(
                    tagsWithNextsToUpdateRev.get(newTag),
                    newTag
                );
            }
        }

        currentTag = startTag;
        startTagToInsert = null;

        // Fix up nexts
        sobjs.clear();
        for (String toUpdateTag : tagsWithNextsToUpdate.keySet()) {
            WSU_Kyou_QueueEntry entry = entries.get(toUpdateTag);
            String newNext = (String)entries.get(tagsWithNextsToUpdate.get(toUpdateTag)).get('Id');
            entry.put('Next__c', (ID)newNext);
            sobjs.add((WSU_Kyou_QueueEntry__c)entry.sobj);
        }
        results = Database.update(sobjs);

        // Clear tagsWithNextsToUpdate
        tagsWithNextsToUpdate.clear();
        // Clear tagsWithNextsToUpdateRev
        tagsWithNextsToUpdateRev.clear();
    }

    public class QueueEntryListException extends Exception {}
}
