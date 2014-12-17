// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_Kyou_Maintainer implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    private Integer nextPriority = null;
    private List<Integer> newOpenSlots = new List<Integer>();
    private Integer highestPriority = null;
    private Boolean wasLocked = false;

    public WSU_Kyou_Maintainer() {
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<WSU_Kyou_Info__c> kyouInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(kyouInfos.size(), 1); // FIXME  Sanity check
        WSU_Kyou_Info__c kyouInfo = kyouInfos.get(0);
        if (kyouInfo.Locked__c) {
            wasLocked = true;
            return Database.getQueryLocator('select Id from User where Id =\'000000000000000000\''); // Do nothing
        } else {
            // Lock it
            kyouInfo.Locked__c = true;
            Database.SaveResult result = Database.Update(kyouInfo);
            return Database.getQueryLocator(
                'select Id, Data__c, Priority__c from WSU_Kyou_QueueEntry__c order by Priority__c'
            );
        }
    }

    public void execute(Database.BatchableContext bc, List<sObject> sobjs) {
        for (sObject entrysobj : sobjs) {
            WSU_Kyou_QueueEntry__c entry = (WSU_Kyou_QueueEntry__c)entrysobj;
            if (nextPriority == null) {
                nextPriority = 0; //  Default starting point
            }
            entry.Priority__c = nextPriority;
            if (highestPriority == null) {
                highestPriority = nextPriority;
            }
            newOpenSlots.add(nextPriority + 1);
            nextPriority += 2;
        }
        newOpenSlots.remove(newOpenSlots.size() - 1); // Remove the extra one on the end
        List<Database.SaveResult> results = Database.Update(sobjs);
    }

    public void finish(Database.BatchableContext bc) {
        if (!wasLocked) {
            WSU_Kyou.setOpenSlots(new Set<Integer>(newOpenSlots), [select Id from WSU_Kyou_Open_Slots__c]);

            List<WSU_Kyou_Info__c> kyouInfos = WSU_Kyou_Info__c.getAll().values();
            System.assertEquals(kyouInfos.size(), 1); // FIXME  sanity check
            WSU_Kyou_Info__c kyouInfo = kyouInfos.get(0);
            System.assert(kyouInfo.Locked__c); // FIXME: sanity check

            kyouInfo.Highest_Priority__c = highestPriority;
            kyouInfo.Lowest_Priority__c = nextPriority == null ? null : nextPriority - 2;

            // Unlock
            kyouInfo.Locked__c = false;

            Database.SaveResult result = Database.Update(kyouInfo);
        }
    }

    public class Kyou_MaintainerException extends Exception {}
}
