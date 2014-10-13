// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_Kyou_ObjectListBatchable_Testing implements Database.Batchable<Object> {
    public List<Object> start(Database.BatchableContext bc) {
        return new List<Object>{'TESTING'};
    }

    public void execute(Database.BatchableContext bc, List<Object> objs) {
    }

    public void finish(Database.BatchableContext bc) {
    }
}
