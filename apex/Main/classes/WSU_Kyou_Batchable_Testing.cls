// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

public class WSU_Kyou_Batchable_Testing implements Database.Batchable<sObject>, Database.Stateful {
    private Boolean initRun;

    public String someParam {
        private get;
        protected set {
            someParam = value;
            init();
        }
    }

    private void init() {
        if (initRun == null || !initRun) {
            if (someParam == null) {
                someParam = 'DEFAULT';
            }
            initRun = true;
        }
    }

    public WSU_Kyou_Batchable_Testing() {
        init();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('select Id, LastName from Contact');
    }

    public void execute(Database.BatchableContext bc, List<sObject> sobjs) {
        List<Contact> cons = new List<Contact>();
        for (sObject sobj : sobjs) {
            Contact con = (Contact)sobj;
            con.LastName = someParam;
            cons.add(con);
        }
        update cons;
    }

    public void finish(Database.BatchableContext bc) {
    }
}
