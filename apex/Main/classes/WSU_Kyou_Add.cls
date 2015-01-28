public class WSU_Kyou_Add implements Queueable {
    @TestVisible
    private List<Map<String, Object>> entries = new List<Map<String, Object>>();
    @TestVisible
    private Set<Integer> openSlots = null;
    @TestVisible
    private List<WSU_Kyou_Open_Slots__c> openSlotsRecords = null;

    private Boolean moving = false;
    private Boolean deleting = false;
    private Map<ID, WSU_Kyou_QueueEntry__c> entryObjs = null;
    private Map<Integer, ID> entryOldPriorityToId = null;

    // For adding
    public WSU_Kyou_Add(List<Map<String, Object>> entries) {
        this.entries.addAll(entries);
    }

    public WSU_Kyou_Add(Map<Integer, WSU_Kyou_QueueEntry__c> entryObjs) {
        this(entryObjs, false);
    }

    // For moving and deleting
    // I know this is not ideal for deleting - there should be another constructor that takes a
    // List<WSU_Kyou_QueueEntry__c> alone for deleting. i.e., the Map provides no information.
    public WSU_Kyou_Add(Map<Integer, WSU_Kyou_QueueEntry__c> entryObjs, Boolean deleting) {
        /* I can't seem to support multiple moves in one call.  The Update() call complains about duplicate values even if
           all of the current rows are getting updated at the same time and there are no duplicates.  Platform bug? */
        // So for now, only allow one incoming.
        if (!deleting && entryObjs.size() != 1) {
            throw new Kyou_AddException('Only one move per call for now.  Sorry.');
        }

        // The incoming key is the old priority - we need it here so we can clear up open slots and fix kyouInfo
        this.entryObjs = new Map<ID, WSU_Kyou_QueueEntry__c>();
        entryOldPriorityToId = new Map<Integer, ID>();

        // Make sure there is a deterministic ordering to this
        List<Integer> keyList = new List<Integer>(entryObjs.keySet());
        keyList.sort();
        for (Integer oldPriority : keyList) {
            WSU_Kyou_QueueEntry__c entryObj = entryObjs.get(oldPriority);

            this.entryObjs.put(entryObj.Id, entryObj);

            // Note that the values here aren't used anywhere at the moment
            entryOldPriorityToId.put(oldPriority, entryObj.Id);

            Map<String, Object> entry = new Map<String, Object>{
                'priority' => entryObj.Priority__c.intValue(),
                'Id' => (Object)entryObj.Id
            };
            entry.putAll((Map<String, Object>)JSON.deserializeUntyped(entryObj.Data__c));
            entries.add(entry);
        }

        this.deleting = deleting;
        if (!deleting) {
            moving = true;
        }
    }

    private void saveAdd() {
        // Save in an object for the kicker to find and recover the add later when presumably the Kyou is
        // unlocked.
        // This is the same as the Open Slots insert code below.  I should probably generalize it (in a util
        // class?)
        List<WSU_Kyou_Saved_Add__c> toInsert = new List<WSU_Kyou_Saved_Add__c>();
        Integer dataFieldLength = Schema.sObjectType.WSU_Kyou_Saved_Add__c.fields.Data__c.getLength();
        List<Object> dataList = null;
        Integer dataStringLengthCount = 0;
        for (Map<String, Object> entry : entries) {
            String entryString = JSON.serialize(entry);
            if (
                toInsert.size() == 0 ||
                // The + 1 is for the JSON comma
                dataStringLengthCount + entryString.length() + 1 > dataFieldLength
            ) {
                // Close out old one if it's there
                if (toInsert.size() > 0) {
                    toInsert.get(toInsert.size() - 1).Data__c = JSON.serialize(dataList);
                }

                // Prepare new one
                dataList = new List<Object>();
                toInsert.add(new WSU_Kyou_Saved_Add__c(
                    Data__c = '' // To protect the String.length() call in the above conditional
                ));
                // Note that I'm using this method because I suspect that string concatenation is slow.  I haven't
                // tested it, though.
                dataStringLengthCount = 2; // The square brackets
            }

            dataList.add(entry);
            dataStringLengthCount += entryString.length() + 1; // + 1 for the comma - yes I'm counting one
                                                               // more comma than I should.
        }
        // Close out last one
        if (toInsert.size() > 0) {
            toInsert.get(toInsert.size() - 1).Data__c = JSON.serialize(dataList);
        }
        List<Database.SaveResult> insertResults = Database.Insert(toInsert);
    }

    public void execute(QueueableContext qc) {
        Database.SaveResult saveRes = null;

        // Check if we're locked
        List<WSU_Kyou_Info__c> kyouInfos = WSU_Kyou_Info__c.getAll().values();
        WSU_Kyou_Info__c kyouInfo = null;
        System.assert(kyouInfos.size() <= 1); // FIXME: Sanity check for now
        if (kyouInfos.size() == 1) {
            kyouInfo = kyouInfos.get(0);
            Boolean originalLocked = kyouInfo.Locked__c;
            // Lock right away to reduce races
            kyouInfo.Locked__c = true;
            saveRes = Database.Update(kyouInfo);
            if (originalLocked) {
                if (moving) {
                    throw new Kyou_AddException('Cannot move while locked');
                } else {
                    if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) { // We have room
                        if (!Test.isRunningTest()) { // Can't chain in Test context
                            try {
                                System.enqueueJob(this);
                            } catch (System.AsyncException e) {
                                // Protect from the only 2 deep allowed chain stack for queueables
                                saveAdd();
                            }
                        }
                    } else { // We don't have room
                        saveAdd();
                    }
                    return;
                }
            }
        } else { // empty Kyou, and we assume unlocked
            // Lock right away to reduce races
            kyouInfo = new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Locked__c = true,
                Highest_Priority__c = null, // null means we're still empty - WSU_Kyou.run() knows how to handle this
                Lowest_Priority__c = null
            );
            saveRes = Database.Insert(kyouInfo);
        }

        // Get Open Slots to determine what to query for the purposes of update
        List<Object> openSlotsResult = WSU_Kyou.getOpenSlots();
        openSlots = (Set<Integer>)openSlotsResult.get(0);
        openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)openSlotsResult.get(1);

        // If moving, we have to open up open slots and update local copy of kyouinfo.  This will let
        // the majority of the code (determineMoves() primarily) behave as though they are new adds.
        // Only the DML below will be different if moving.
        if (deleting || moving) {
            if (
                kyouInfo.Lowest_Priority__c == null ||
                kyouInfo.Highest_Priority__c == null ||
                kyouInfo.Highest_Priority__c.intValue() == kyouInfo.Lowest_Priority__c.intValue() // Only one entry
            ) {
                return; // Nothing to do
            }

            for (Integer oldPriority : entryOldPriorityToId.keySet()) {
                System.debug(LoggingLevel.ERROR, 'OP ' + oldPriority);
                System.debug(LoggingLevel.ERROR, 'OP1 ' + entryOldPriorityToId.get(oldPriority));
                System.debug(LoggingLevel.ERROR, 'OP2 ' + entryObjs.get(entryOldPriorityToId.get(oldPriority)));
                System.debug(LoggingLevel.ERROR, 'OP3 ' + kyouInfo);
                if (kyouInfo.Lowest_Priority__c.intValue() == oldPriority) {
                    if (kyouInfo.Highest_Priority__c.intValue() == oldPriority) { // Then this entry is the only one
                                                                                  // left
                        // openSlots will already be empty
                        kyouInfo.Lowest_Priority__c = kyouInfo.Highest_Priority__c = null;
                    } else {
                        // Scan upward in priority for a non open slot, removing any open slots passed on the way
                        do {
                            oldPriority--;
                            if (openSlots.contains(oldPriority)) {
                                openSlots.remove(oldPriority);
                            } else {
                                kyouInfo.Lowest_Priority__c = oldPriority;
                                break;
                            }
                        } while (oldPriority > kyouInfo.Highest_Priority__c.intValue());
                    }
                } else if (kyouInfo.Highest_Priority__c.intValue() == oldPriority) {
                    // Scan downward in priority for a non open slot, removing any open slots passed on the way
                    do {
                        oldPriority++;
                        if (openSlots.contains(oldPriority)) {
                            openSlots.remove(oldPriority);
                        } else {
                            kyouInfo.Highest_Priority__c = oldPriority;
                            break;
                        }
                    } while (oldPriority < kyouInfo.Lowest_Priority__c.intValue());
                } else if (!openSlots.contains(oldPriority)) {
                    openSlots.add(oldPriority);
                } else {
                    throw new Kyou_AddException('We have a problem: bad oldPriority ' + oldPriority + ' with Kyou info ' + kyouInfo);
                }
            }
        }
        System.debug(LoggingLevel.ERROR, 'OP4 ' + kyouInfo);

        Map<Integer, Integer> moves = new Map<Integer, Integer>();
        if (!deleting) {
            moves = determineMoves(kyouInfo);
        }

        // I will have to query for any WSU_Kyou_QueueEntry__c that might need to get moved.
        // This will only happen if an incoming priority wants a priority that's already taken.
        List<WSU_Kyou_QueueEntry__c> existingEntriesToMove = [
            select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Priority__c in :moves.keySet()
        ];

        for (WSU_Kyou_QueueEntry__c entry : existingEntriesToMove) {
            entry.Priority__c = moves.get(entry.Priority__c.intValue());
        }

        // So for some reason if I put existing entries and new entries together for a single Upsert(), I can't have the
        // existing ones update Priority and the new ones grab a Priority that an old one is leaving behind - this
        // causes a DUPLICATE_VALUE exception.  So I have to do separate DML lines for the two modes.

        //List<WSU_Kyou_QueueEntry__c> toUpsert = new List<WSU_Kyou_QueueEntry__c>();
        List<Database.SaveResult> updateResults = null;
        List<Database.UpsertResult> upsertResults = null;
        List<Database.DeleteResult> deleteResults = null;

        if (deleting) {
            deleteResults = Database.Delete(entryObjs.values());
        } else {
            if (moving) {
                List<WSU_Kyou_QueueEntry__c> toUpdate = new List<WSU_Kyou_QueueEntry__c>();

                toUpdate.addAll(existingEntriesToMove);

                for (Map<String, Object> entry : entries) {
                    WSU_Kyou_QueueEntry__c entryObj = entryObjs.get((ID)entry.get('Id'));
                    entryObj.Priority__c = (Integer)entry.remove('priority');
                    toUpdate.add(entryObj);
                }

                if (toUpdate.size() > (Limits.getLimitDMLRows() - Limits.getDMLRows())) {
                    throw new Kyou_AddException(
                        'Too many entries to add or move: ' + toUpdate.size() + ' where the limit allows ' + (Limits.getLimitDMLRows() - Limits.getDMLRows())
                    );
                }

                /* I can't seem to support multiple moves in one call.  The Update() call complains about duplicate values even if
                   all of the current rows are getting updated at the same time and there are no duplicates.  Platform bug? */
                updateResults = Database.Update(toUpdate);
            } else {
                List<WSU_Kyou_QueueEntry__c> toUpsert = new List<WSU_Kyou_QueueEntry__c>();

                updateResults = Database.Update(existingEntriesToMove);

                // Upsert new ones
                for (Map<String, Object> newEntry : entries) {
                    Integer priority = (Integer)newEntry.remove('priority');
                    toUpsert.add(new WSU_Kyou_QueueEntry__c(
                        Data__c = JSON.serialize(newEntry),
                        Priority__c = priority
                    ));
                }

                // For now - there will be code eventually that means this shouldn't happen (see TODO below)
                if (toUpsert.size() > (Limits.getLimitDMLRows() - Limits.getDMLRows())) {
                    throw new Kyou_AddException(
                        'Too many entries to add or move: ' + toUpsert.size() + ' where the limit allows ' + (Limits.getLimitDMLRows() - Limits.getDMLRows())
                    );
                }

                upsertResults = Database.Upsert(toUpsert);
            }
        }

        // TODO: Recall that the plan here is to determine exactly what number of incoming entires I can permit while never
        // hitting the 10k DML row limit.
        // Then for null priorities, accept as many as possible (10k - the number of bookkeeping DML rows done; 2 so far
        // for lock/unlock)

        // Update Info record and unlock (this will take a DML row too)
        kyouInfo.Locked__c = false;
        upsertResults = Database.Upsert(new List<WSU_Kyou_Info__c>{kyouInfo});
    }

    // Note that this has some side effects:
    //     - fixes this.entries elements if they need their priorities changed.
    //     - replaces Open Slots records if needed (doing two DMLs: delete and insert)
    // Also note that this is used by moving code in the VF controller
    public Map<Integer, Integer> determineMoves(WSU_Kyou_Info__c kyouInfo) {
        Map<Integer, Integer> movePriorities = new Map<Integer, Integer>();

        Set<Integer> originalOpenSlots = openSlots.clone();
        Map<Integer, Map<String, Object>> currentPriorityToNewEntry = new Map<Integer, Map<String, Object>>();

        Integer replacementLowestPriority = null;
        for (Map<String, Object> entry : entries) {
            Integer priority = null;
            if (!entry.containsKey('priority') || entry.get('priority') == null) { // Put at the end
                priority = kyouInfo.Lowest_Priority__c == null ? 0 : kyouInfo.Lowest_Priority__c.intValue() + 1;
                entry.put('priority', priority);
            } else {
                priority = (Integer)entry.get('priority');
            }

            List<Integer> previousEntriesToMove = new List<Integer>();

            if (kyouInfo.Highest_Priority__c != null) { // For non empty queue
                Integer highestPriority = kyouInfo.Highest_Priority__c.intValue();
                Integer lowestPriority = kyouInfo.Lowest_Priority__c.intValue();

                if (priority >= highestPriority && priority <= lowestPriority) {
                    // Figure out what needs to move.  Cascade down open slots trying to find one, noting map of
                    // old priority to new priority as you go, and moving already placed new entries as you go.
                    Integer prioritySearch = priority;

                    do {
                        if (openSlots.contains(prioritySearch)) {
                            openSlots.remove(prioritySearch);
                            break;
                        } else {
                            if (!originalOpenSlots.contains(prioritySearch)) {
                                if (currentPriorityToNewEntry.containsKey(prioritySearch)) {
                                    previousEntriesToMove.add(prioritySearch);
                                }

                                Integer targetPriority = null;
                                if (movePriorities.containsKey(prioritySearch)) {
                                    targetPriority = movePriorities.get(prioritySearch) + 1;
                                } else {
                                    targetPriority = prioritySearch + 1;
                                }
                                movePriorities.put(prioritySearch, targetPriority);
                            }
                            prioritySearch++;
                        }
                    } while (prioritySearch < lowestPriority);

                    if (prioritySearch == lowestPriority) { // Then we haven't found any open slots
                        if (movePriorities.containsKey(lowestPriority)) {
                            movePriorities.put(lowestPriority, movePriorities.get(lowestPriority) + 1);
                        } else {
                            movePriorities.put(lowestPriority, lowestPriority + 1);
                        }

                        if (replacementLowestPriority == null) {
                            replacementLowestPriority = lowestPriority + 1;
                        } else {
                            replacementLowestPriority++;
                        }
                    } else if (prioritySearch == lowestPriority + 1) { // can be greater than when the Kyou is size one
                                                                       // (effect of using do-while loop)
                        if (replacementLowestPriority == null) {
                            replacementLowestPriority = lowestPriority + 1;
                        } else {
                            replacementLowestPriority++;
                        }
                    }
                } else if (priority < highestPriority) {
                    for (Integer i = priority + 1; i < highestPriority; i++) {
                        openSlots.add(i);
                    }
                    kyouInfo.Highest_Priority__c = highestPriority = priority;
                } else if (priority > lowestPriority) {
                    for (Integer i = lowestPriority + 1; i < priority; i++) {
                        openSlots.add(i);
                    }
                    kyouInfo.Lowest_Priority__c = lowestPriority = priority;
                }

            } else { // For empty queue
                if (currentPriorityToNewEntry.containsKey(priority)) {
                    previousEntriesToMove.add(priority);
                }
            }

            // Increment priorities for previous new entries that need moving
            // Do this in reverse order so nothing gets clobbered
            for (Integer i = previousEntriesToMove.size() - 1; i >= 0; i--) {
                Integer currentPriority = previousEntriesToMove.get(i);
                Map<String, Object> entryToIncrement = currentPriorityToNewEntry.remove(currentPriority);
                Integer newPriority = (Integer)entryToIncrement.get('priority') + 1;
                entryToIncrement.put('priority', newPriority);
                currentPriorityToNewEntry.put(newPriority, entryToIncrement);
            }

            // We don't need to change the current entry's priority here, but remember it for later iterations
            currentPriorityToNewEntry.put(priority, entry);

        }

        if (replacementLowestPriority != null) {
            kyouInfo.Lowest_Priority__c = replacementLowestPriority;
        } else if (kyouInfo.Highest_Priority__c == null) { // Fixing up after adding to an empty queue
            List<Integer> newPriorities = new List<Integer>(currentPriorityToNewEntry.keySet());
            newPriorities.sort();
            kyouInfo.Highest_Priority__c = newPriorities.get(0);
            kyouInfo.Lowest_Priority__c = newPriorities.get(newPriorities.size() - 1);
            for (Integer i = kyouInfo.Highest_Priority__c.intValue() + 1; i < kyouInfo.Lowest_Priority__c.intValue(); i++) {
                openSlots.add(i);
            }
        }

        // Fix open slots
        WSU_Kyou.setOpenSlots(openSlots, openSlotsRecords);

        return movePriorities;
    }

    // For use by moving code in VF controller
    public Map<Integer, Integer> determineMoves(WSU_Kyou_Info__c kyouInfo, List<Object> openSlotsResult) {
        openSlots = (Set<Integer>)openSlotsResult.get(0);
        openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)openSlotsResult.get(1);

        return determineMoves(kyouInfo);
    }

    public class Kyou_AddException extends Exception {}
}
