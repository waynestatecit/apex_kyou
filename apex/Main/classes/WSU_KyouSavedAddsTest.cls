// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

// The tests here are split off because of this bug:
// https://success.salesforce.com/issues_view?id=a1p300000008XM1AAM

@isTest
public class WSU_KyouSavedAddsTest {
    static testMethod void testFinishSavedAdds() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_Saved_Add__c(
                Data__c = '[' +
                    '{' +
                        '"class":"WSU_Kyou_Batchable_Testing",' +
                        '"args":null,' +
                        '"size":null,' +
                        '"list":false,' +
                        '"object_list":false,' +
                        '"priority":7' +
                    '}' +
                ']'
            )
        });

        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 0);

        Database.BatchableContext bc = null;
        WSU_Kyou kyou = new WSU_Kyou();
        Test.startTest();
        kyou.finish(bc);
        Test.stopTest();

        System.assertEquals([select count() from WSU_Kyou_QueueEntry__c], 1);
        System.assertEquals([select count() from WSU_Kyou_Saved_Add__c], 0);
        WSU_Kyou_Info__c kyouInfo = WSU_Kyou_Info__c.getAll().values().get(0);
        System.assertEquals(kyouInfo.Highest_Priority__c, 7);
        System.assertEquals(kyouInfo.Lowest_Priority__c, 7);
    }

}
