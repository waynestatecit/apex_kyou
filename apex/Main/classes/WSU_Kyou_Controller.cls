global class WSU_Kyou_Controller {
    private static Integer defaultPageSize = 50;

    public List<WSU_Kyou_QueueEntry__c> getSamples() {
        return [select Priority__c from WSU_Kyou_QueueEntry__c limit 1];
    }

    @RemoteAction
    global static Map<String, Object> getEntries(Integer page, Integer pageSize) {
        Map<String, Object> toReturn = new Map<String, Object>();

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        Set<Integer> openSlots = (Set<Integer>)openSlotsResults.get(0);

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

        // Assuming page is coming in as 1 start instead of 0 start
        if (page == 0) {
            return toReturn;
        }
        if (pageSize == null) {
            pageSize = defaultPageSize;
        }

        Map<String, Object> prioritiesResult = WSU_Kyou.determinePriorities(kyouInfo, openSlots, page - 1, pageSize);
        List<Integer> foundEntries = (List<Integer>)prioritiesResult.get('priorities');
        Boolean more = (Boolean)prioritiesResult.get('more');

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Data__c, Priority__c from WSU_Kyou_QueueEntry__c where Priority__c in :foundEntries order by Priority__c];

        toReturn.put('entries', entries);
        System.debug(LoggingLevel.ERROR, 'MORE ' + more);

        // query CronTrigger to see if we're perpetuating, put in the return payload
        String scheduledQuery = 'select CronJobDetail.Name, State, NextFireTime from CronTrigger where CronJobDetail.Name = \'WSU_Kyou\' and State not in (\'Aborted\', \'Completed\', \'Failed\')';
        List<CronTrigger> cts = Database.query(scheduledQuery);
        if (cts.size() > 0) {
            toReturn.put('perpetuating', cts.get(0).NextFireTime);
        }

        toReturn.put('more', more);

        toReturn.put('locked', kyouInfo.Locked__c);

        return toReturn;
    }

    @RemoteAction
    global static Boolean move(ID entryId, Integer newPriority) {
        WSU_Kyou_QueueEntry__c entry = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :entryId];
        Integer oldPriority = entry.Priority__c.intValue();
        entry.Priority__c = newPriority;
        WSU_Kyou_Add adder = new WSU_Kyou_Add(new Map<Integer, WSU_Kyou_QueueEntry__c>{oldPriority => entry});
        QueueableContext qc = null;
        adder.execute(qc);
        System.debug(LoggingLevel.ERROR, 'DONE MOVING ' + entryId + ' ' + newPriority);
        return true; // Not really meaningful right now
    }

    @RemoteAction
    global static Boolean del(ID entryId) {
        WSU_Kyou_QueueEntry__c entry = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :entryId];
        WSU_Kyou_Add adder = new WSU_Kyou_Add(
            new Map<Integer, WSU_Kyou_QueueEntry__c>{entry.Priority__c.intValue() => entry},
            true
        );
        QueueableContext qc = null;
        adder.execute(qc);
        System.debug(LoggingLevel.ERROR, 'DONE DELETING ' + entryId + ' ' + entry.Priority__c.intValue());
        return true; // Not really meaningful right now
    }

    public PageReference doNothing() {
        return null;
    }
}
