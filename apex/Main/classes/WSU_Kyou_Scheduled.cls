// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2013-2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

global class WSU_Kyou_Scheduled implements Schedulable {
    private Integer waitMinutes = null;

    global WSU_Kyou_Scheduled() {
    }

    global WSU_Kyou_Scheduled(Integer waitMinutes) {
        this.waitMinutes = waitMinutes;
    }

    global void execute(SchedulableContext sc) {
        if (waitMinutes == null) {
            WSU_Kyou.setOptions(true, false, true);
        } else {
            WSU_Kyou.setOptions(waitMinutes, true, false, true);
        }
        ID schId = WSU_Kyou.scheduleSelf();
    }
}
