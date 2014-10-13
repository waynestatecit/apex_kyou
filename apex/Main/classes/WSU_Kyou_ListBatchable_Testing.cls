// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_Kyou_ListBatchable_Testing implements Database.Batchable<sObject> {
    public List<sObject> start(Database.BatchableContext bc) {
        return new List<sObject>{new Contact(LastName = 'LASTNAME1')};
    }

    public void execute(Database.BatchableContext bc, List<sObject> sobjs) {
    }

    public void finish(Database.BatchableContext bc) {
    }
}
