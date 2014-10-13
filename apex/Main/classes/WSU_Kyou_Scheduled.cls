// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

global class WSU_Kyou_Scheduled implements Schedulable {
    global void execute(SchedulableContext sc) {
        WSU_Kyou.run();
    }
}
