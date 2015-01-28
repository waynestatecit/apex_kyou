// This file is part of WSU_Kyou, a Salesforce native queue for Batch Apex and Scheduled Apex.

// Copyright 2014, Wayne State University
// License: 3-clause BSD license.  See LICENSE.

@isTest
public class WSU_Kyou_AddTest {
    private static List<Map<String, Object>> initialEntries;

    static {
        initialEntries = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'priority' => 0,
                'list' => false,
                'object_list' => false
            }
        };
    }

    static testMethod void testDetermineMovesOneAndOne() {
        WSU_Kyou_Add adder = new WSU_Kyou_Add(new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'priority' => 0,
                'list' => false,
                'object_list' => false
            }
        });

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = false,
            Highest_Priority__c = 0,
            Lowest_Priority__c = 0
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expected = new Map<Integer, Integer>{
            0 => 1
        };

        System.assert(moves.equals(expected));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 0);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 1);
        System.assert(adder.openSlots.equals(new Set<Integer>()));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesOneAndOneLarger() {
        WSU_Kyou_Add adder = new WSU_Kyou_Add(new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'priority' => 100000,
                'list' => false,
                'object_list' => false
            }
        });

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = false,
            Highest_Priority__c = 100000,
            Lowest_Priority__c = 100000
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expected = new Map<Integer, Integer>{
            100000 => 100001
        };

        System.assert(moves.equals(expected));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 100000);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 100001);
        System.assert(adder.openSlots.equals(new Set<Integer>()));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesOneAndTwo() {
        WSU_Kyou_Add adder = new WSU_Kyou_Add(new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            }
        });

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = false,
            Highest_Priority__c = 10,
            Lowest_Priority__c = 11
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expected = new Map<Integer, Integer>{
            10 => 11,
            11 => 12
        };

        System.assert(moves.equals(expected));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 10);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 12);
        System.assert(adder.openSlots.equals(new Set<Integer>()));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesOneAndTwoGap() {
        WSU_Kyou_Add adder = new WSU_Kyou_Add(new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            }
        });

        Database.SaveResult result = Database.Insert(new WSU_Kyou_Open_Slots__c(
            Data__c = '[11]'
        ));

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = false,
            Highest_Priority__c = 10,
            Lowest_Priority__c = 12
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expected = new Map<Integer, Integer>{
            10 => 11
        };

        System.assert(moves.equals(expected));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 10);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 12);
        System.assert(adder.openSlots.equals(new Set<Integer>()));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesTwoAndTwo() {
        WSU_Kyou_Add adder = new WSU_Kyou_Add(new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            }
        });

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = false,
            Highest_Priority__c = 10,
            Lowest_Priority__c = 11
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expected = new Map<Integer, Integer>{
            10 => 12,
            11 => 13
        };

        System.assert(moves.equals(expected));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 10);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 13);
        System.assert(adder.openSlots.equals(new Set<Integer>()));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesTwoAndTwoSingleGap() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            }
        };
        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        Database.SaveResult result = Database.Insert(new WSU_Kyou_Open_Slots__c(
            Data__c = '[11]'
        ));

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = false,
            Highest_Priority__c = 10,
            Lowest_Priority__c = 12
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expectedMoves = new Map<Integer, Integer>{
            10 => 12,
            12 => 13
        };

        List<Map<String, Object>> expectedToAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 11,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            }
        };
        System.assert(moves.equals(expectedMoves));
        System.assert(toAdd.equals(expectedToAdd));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 10);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 13);
        System.assert(adder.openSlots.equals(new Set<Integer>()));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesTwoAndTwoNoGap() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            }
        };
        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = false,
            Highest_Priority__c = 10,
            Lowest_Priority__c = 12
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expectedMoves = new Map<Integer, Integer>{
            10 => 12,
            11 => 13,
            12 => 14
        };

        List<Map<String, Object>> expectedToAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 11,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            }
        };
        System.assert(moves.equals(expectedMoves));
        System.assert(toAdd.equals(expectedToAdd));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 10);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 14);
        System.assert(adder.openSlots.equals(new Set<Integer>()));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesNewQueue() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            }
        };
        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = true, // This actually doesn't matter for determineMoves()
            Highest_Priority__c = null, // We are empty
            Lowest_Priority__c = null
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expectedMoves = new Map<Integer, Integer>();

        List<Map<String, Object>> expectedToAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 11,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            }
        };
        System.assert(moves.equals(expectedMoves));
        System.assert(toAdd.equals(expectedToAdd));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 10);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 11);
        System.assert(adder.openSlots.equals(new Set<Integer>()));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesNewQueueOne() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 1000,
                'list' => false,
                'object_list' => false
            }
        };
        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = true, // This actually doesn't matter for determineMoves()
            Highest_Priority__c = null, // We are empty
            Lowest_Priority__c = null
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expectedMoves = new Map<Integer, Integer>();

        List<Map<String, Object>> expectedToAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 1000,
                'list' => false,
                'object_list' => false
            }
        };
        System.assert(moves.equals(expectedMoves));
        System.assert(toAdd.equals(expectedToAdd));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 1000);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 1000);
        Set<Integer> expectedOpenSlots = new Set<Integer>();
        System.assert(adder.openSlots.equals(expectedOpenSlots));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesNewQueueOneNullPriority() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => null,
                'list' => false,
                'object_list' => false
            }
        };
        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = true, // This actually doesn't matter for determineMoves()
            Highest_Priority__c = null, // We are empty
            Lowest_Priority__c = null
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expectedMoves = new Map<Integer, Integer>();

        List<Map<String, Object>> expectedToAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 0,
                'list' => false,
                'object_list' => false
            }
        };
        System.assert(moves.equals(expectedMoves));
        System.assert(toAdd.equals(expectedToAdd));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 0);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 0);
        Set<Integer> expectedOpenSlots = new Set<Integer>();
        System.assert(adder.openSlots.equals(expectedOpenSlots));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesNewQueueOneNoPriority() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'list' => false,
                'object_list' => false
            }
        };
        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = true, // This actually doesn't matter for determineMoves()
            Highest_Priority__c = null, // We are empty
            Lowest_Priority__c = null
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expectedMoves = new Map<Integer, Integer>();

        List<Map<String, Object>> expectedToAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 0,
                'list' => false,
                'object_list' => false
            }
        };
        System.assert(moves.equals(expectedMoves));
        System.assert(toAdd.equals(expectedToAdd));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 0);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 0);
        Set<Integer> expectedOpenSlots = new Set<Integer>();
        System.assert(adder.openSlots.equals(expectedOpenSlots));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesNoPriority() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'list' => false,
                'object_list' => false
            }
        };

        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = false,
            Highest_Priority__c = 0,
            Lowest_Priority__c = 0
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expectedMoves = new Map<Integer, Integer>();

        List<Map<String, Object>> expectedToAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'priority' => 1,
                'list' => false,
                'object_list' => false
            }
        };

        System.assert(moves.equals(expectedMoves));
        System.assert(toAdd.equals(expectedToAdd));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 0);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 1);
        System.assert(adder.openSlots.equals(new Set<Integer>()));

        List<WSU_Kyou_Open_Slots__c> expectedOpenSlotsRecords = new List<WSU_Kyou_Open_Slots__c>();

        openSlotsResults = WSU_Kyou.getOpenSlots();
        System.assert(expectedOpenSlotsRecords.equals((List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))));
    }

    static testMethod void testDetermineMovesNewQueueGap() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 1000,
                'list' => false,
                'object_list' => false
            }
        };
        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = true, // This actually doesn't matter for determineMoves()
            Highest_Priority__c = null, // We are empty
            Lowest_Priority__c = null
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expectedMoves = new Map<Integer, Integer>();

        List<Map<String, Object>> expectedToAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 1000,
                'list' => false,
                'object_list' => false
            }
        };
        System.assert(moves.equals(expectedMoves));
        System.assert(toAdd.equals(expectedToAdd));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 10);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 1000);
        Set<Integer> expectedOpenSlots = new Set<Integer>();
        for (Integer i = 11; i < 1000; i++) {
            expectedOpenSlots.add(i);
        }
        System.assert(adder.openSlots.equals(expectedOpenSlots));

        openSlotsResults = WSU_Kyou.getOpenSlots();
        Set<Integer> setFromRecords = new Set<Integer>();
        for (WSU_Kyou_Open_Slots__c openSlotsRecord : (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))) {
            for (Object openSlotObj : (List<Object>)JSON.deserializeUntyped(openSlotsRecord.Data__c)) {
                setFromRecords.add((Integer)openSlotObj);
            }
        }
        System.assert(expectedOpenSlots.equals(setFromRecords));
    }

    static testMethod void testDetermineMovesExistingQueueGap() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 1000,
                'list' => false,
                'object_list' => false
            }
        };
        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        Database.SaveResult result = Database.Insert(new WSU_Kyou_Open_Slots__c(
            Data__c = '[11]'
        ));

        WSU_Kyou_Info__c kyouInfo = new WSU_Kyou_Info__c(
            Locked__c = true, // This actually doesn't matter for determineMoves()
            Highest_Priority__c = 10,
            Lowest_Priority__c = 12
        );

        List<Object> openSlotsResults = WSU_Kyou.getOpenSlots();
        adder.openSlots = (Set<Integer>)(openSlotsResults.get(0));
        adder.openSlotsRecords = (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1));
        Map<Integer, Integer> moves = adder.determineMoves(kyouInfo);

        Map<Integer, Integer> expectedMoves = new Map<Integer, Integer>{
            10 => 11
        };

        List<Map<String, Object>> expectedToAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 1000,
                'list' => false,
                'object_list' => false
            }
        };
        System.assert(moves.equals(expectedMoves));
        System.assert(toAdd.equals(expectedToAdd));
        System.assertEquals(kyouInfo.Highest_Priority__c.intValue(), 10);
        System.assertEquals(kyouInfo.Lowest_Priority__c.intValue(), 1000);
        Set<Integer> expectedOpenSlots = new Set<Integer>();
        for (Integer i = 13; i < 1000; i++) {
            expectedOpenSlots.add(i);
        }
        System.assert(adder.openSlots.equals(expectedOpenSlots));

        openSlotsResults = WSU_Kyou.getOpenSlots();
        Set<Integer> setFromRecords = new Set<Integer>();
        for (WSU_Kyou_Open_Slots__c openSlotsRecord : (List<WSU_Kyou_Open_Slots__c>)(openSlotsResults.get(1))) {
            for (Object openSlotObj : (List<Object>)JSON.deserializeUntyped(openSlotsRecord.Data__c)) {
                setFromRecords.add((Integer)openSlotObj);
            }
        }
        System.assert(expectedOpenSlots.equals(setFromRecords));
    }

    // TODO: test determineMoves() for new *high* priority entries

    static testMethod void testExecuteLocked() {
        WSU_Kyou_Add adder = new WSU_Kyou_Add(new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'priority' => 0,
                'list' => false,
                'object_list' => false
            }
        });

        Database.SaveResult result = Database.Insert(new WSU_Kyou_Info__c(
            Name = 'KyouInfo',
            Locked__c = true,
            Highest_Priority__c = 0,
            Lowest_Priority__c = 0
        ));

        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = '"whatever"'
            )
        });

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c];
        // Locked; nothing was done
        System.assertEquals(entries.size(), 1);
        System.assertEquals(entries.get(0).Priority__c.intValue(), 0);

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 0); // Nothing was done
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 0);
        System.assert(afterInfo.Locked__c);

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
    }

    static testMethod void testExecuteOne() {
        WSU_Kyou_Add adder = new WSU_Kyou_Add(new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'priority' => 0,
                'list' => false,
                'object_list' => false
            }
        });

        Database.SaveResult result = Database.Insert(new WSU_Kyou_Info__c(
            Name = 'KyouInfo',
            Locked__c = false,
            Highest_Priority__c = 0,
            Lowest_Priority__c = 0
        ));

        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = '"whatever"'
            )
        });

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entries.size(), 2);
        Set<Integer> allowedPriorities = new Set<Integer>{0, 1};
        for (WSU_Kyou_QueueEntry__c entry : entries) {
            System.assert(allowedPriorities.contains(entry.Priority__c.intValue()));
            allowedPriorities.remove(entry.Priority__c.intValue());
        }

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 1);
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 0);
        System.assert(!afterInfo.Locked__c);

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
    }

    static testMethod void testExecuteExistingQueueGap() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 1000,
                'list' => false,
                'object_list' => false
            }
        };

        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 10,
                Data__c = '"whatever1"'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 12,
                Data__c = '"whatever2"'
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfoAddTest', // Naming this something else as parallel tests will complain about row
                                          // locking if I don't
                Locked__c = false,
                Highest_Priority__c = 10,
                Lowest_Priority__c = 12
            ),
            new WSU_Kyou_Open_Slots__c(
                Data__c = '[11]'
            )
        });

        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entries.size(), 4);
        Set<Integer> allowedPriorities = new Set<Integer>{10, 11, 12, 1000};
        for (WSU_Kyou_QueueEntry__c entry : entries) {
            System.assert(allowedPriorities.contains(entry.Priority__c.intValue()));
            allowedPriorities.remove(entry.Priority__c.intValue());
        }

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 1000);
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 10);
        System.assert(!afterInfo.Locked__c);

        List<WSU_Kyou_Open_Slots__c> openSlotsRecords = [select Data__c from WSU_Kyou_Open_Slots__c];
        Set<Integer> openSlots = new Set<Integer>();
        for (WSU_Kyou_Open_Slots__c openSlotsRecord : openSlotsRecords) {
            for (Object openSlotObj : (List<Object>)JSON.deserializeUntyped(openSlotsRecord.Data__c)) {
                openSlots.add((Integer)openSlotObj);
            }
        }

        Set<Integer> expectedOpenSlots = new Set<Integer>();
        for (Integer i = 13; i < 1000; i++) {
            expectedOpenSlots.add(i);
        }

        System.assert(expectedOpenSlots.equals(openSlots));
    }

    static testMethod void testExecuteNewQueue() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass1',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            },
            new Map<String, Object>{
                'class' => 'somefakeclass2',
                'args' => null,
                'size' => null,
                'priority' => 10,
                'list' => false,
                'object_list' => false
            }
        };

        // Testing default Kyou Info

        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c];
        System.assertEquals(entries.size(), 2);
        Set<Integer> allowedPriorities = new Set<Integer>{10, 11};
        for (WSU_Kyou_QueueEntry__c entry : entries) {
            System.assert(allowedPriorities.contains(entry.Priority__c.intValue()));
            allowedPriorities.remove(entry.Priority__c.intValue());
        }

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 11);
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 10);
        System.assert(!afterInfo.Locked__c);

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
    }

    /* comment out to avoid platform bug while deploying to production
    static testMethod void testExecuteLockedNoQueueableRoom() {
        List<Map<String, Object>> toAdd = new List<Map<String, Object>>{
            new Map<String, Object>{
                'class' => 'somefakeclass',
                'args' => null,
                'size' => null,
                'priority' => 0,
                'list' => false,
                'object_list' => false
            }
        };

        WSU_Kyou_Add adder = new WSU_Kyou_Add(toAdd);

        Database.SaveResult result = Database.Insert(new WSU_Kyou_Info__c(
            Name = 'KyouInfo',
            Locked__c = true,
            Highest_Priority__c = 0,
            Lowest_Priority__c = 0
        ));

        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = '"whatever"'
            )
        });

        // Fill up the Queueable Job space
        while (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            ID throwaway = System.enqueueJob(adder);
        }

        System.assertEquals([select count() from WSU_Kyou_Saved_Add__c], 0);

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_Saved_Add__c> savedAdds = [select Data__c from WSU_Kyou_Saved_Add__c];
        System.assertEquals(savedAdds.size(), 1);
        System.assert(toAdd.equals((List<Object>)JSON.deserializeUntyped(savedAdds.get(0).Data__c)));

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 0);
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 0);
        System.assert(afterInfo.Locked__c);

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
    }
    */

    static testMethod void testExecuteMoveLocked() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Locked__c = true,
                Highest_Priority__c = 0,
                Lowest_Priority__c = 1
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = '{"whatever0":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 1,
                Data__c = '{"whatever1":true}'
            )
        });

        WSU_Kyou_QueueEntry__c toMove = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :results.get(2).getId()];
        toMove.Priority__c = 0;

        WSU_Kyou_Add adder = new WSU_Kyou_Add(new Map<Integer, WSU_Kyou_QueueEntry__c>{
            1 => toMove
        });

        QueueableContext qc = null;
        Boolean success = true;
        try {
            adder.execute(qc);
        } catch (WSU_Kyou_Add.Kyou_AddException e) {
            success = false;
            System.assertEquals(e.getMessage(), 'Cannot move while locked');
        }
        System.assert(!success);
    }

    static testMethod void testExecuteMoveOne() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Locked__c = false,
                Highest_Priority__c = 0,
                Lowest_Priority__c = 1
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = '{"whatever0":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 1,
                Data__c = '{"whatever1":true}'
            )
        });

        WSU_Kyou_QueueEntry__c toMove = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :results.get(2).getId()];
        toMove.Priority__c = 0;

        WSU_Kyou_Add adder = new WSU_Kyou_Add(new Map<Integer, WSU_Kyou_QueueEntry__c>{
            1 => toMove
        });

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c order by Priority__c];
        System.assertEquals(entries.size(), 2);
        System.assertEquals(entries.get(0).Priority__c.intValue(), 0);
        System.assertEquals(entries.get(0).Data__c, '{"whatever1":true}'); // Swapped
        System.assertEquals(entries.get(1).Priority__c.intValue(), 1);
        System.assertEquals(entries.get(1).Data__c, '{"whatever0":true}'); // Swapped

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 1); // Nothing was done
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 0);
        System.assert(!afterInfo.Locked__c);

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
    }

    static testMethod void testExecuteMoveExistingQueueGap() {
        Set<Integer> openSlots = new Set<Integer>();
        for (Integer i = 13; i < 1000; i++) {
            openSlots.add(i);
        }
        WSU_Kyou.setOpenSlots(openSlots, new List<WSU_Kyou_Open_Slots__c>());

        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 10,
                Data__c = '{"whatever10":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 11,
                Data__c = '{"whatever11":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 12,
                Data__c = '{"whatever12":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 1000,
                Data__c = '{"whatever1000":true}'
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfoAddTest2', // Naming this something else as parallel tests will complain about row
                                           // locking if I don't
                Locked__c = false,
                Highest_Priority__c = 10,
                Lowest_Priority__c = 1000
            )
        });

        WSU_Kyou_QueueEntry__c toMove = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :results.get(2).getId()];
        toMove.Priority__c = 10;

        WSU_Kyou_Add adder = new WSU_Kyou_Add(new Map<Integer, WSU_Kyou_QueueEntry__c>{
            12 => toMove
        });

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c order by Priority__c];

        System.assertEquals(entries.size(), 4);
        Map<Integer, String> allowedPrioritiesToData = new Map<Integer, String>{
            10 => '{"whatever12":true}',
            11 => '{"whatever10":true}',
            12 => '{"whatever11":true}',
            1000 => '{"whatever1000":true}'
        };
        for (WSU_Kyou_QueueEntry__c entry : entries) {
            System.assert(allowedPrioritiesToData.containsKey(entry.Priority__c.intValue()));
            String data = allowedPrioritiestoData.remove(entry.Priority__c.intValue());
            System.assertEquals(data, entry.Data__c);
        }

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 1000);
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 10);
        System.assert(!afterInfo.Locked__c);

        List<WSU_Kyou_Open_Slots__c> afterOpenSlotsRecords = [select Data__c from WSU_Kyou_Open_Slots__c];
        Set<Integer> afterOpenSlots = new Set<Integer>();
        for (WSU_Kyou_Open_Slots__c afterOpenSlotsRecord : afterOpenSlotsRecords) {
            for (Object openSlotObj : (List<Object>)JSON.deserializeUntyped(afterOpenSlotsRecord.Data__c)) {
                afterOpenSlots.add((Integer)openSlotObj);
            }
        }

        Set<Integer> expectedOpenSlots = new Set<Integer>();
        for (Integer i = 13; i < 1000; i++) {
            expectedOpenSlots.add(i);
        }

        System.assert(expectedOpenSlots.equals(afterOpenSlots));
    }

    /* I can't seem to support multiple moves in one call.  The Update() call complains about duplicate values even if
       all of the current rows are getting updated at the same time and there are no duplicates.  Platform bug?
    static testMethod void testExecuteMoveTwoExistingQueueGap() {
        Set<Integer> openSlots = new Set<Integer>();
        for (Integer i = 13; i < 1000; i++) {
            openSlots.add(i);
        }
        WSU_Kyou.setOpenSlots(openSlots, new List<WSU_Kyou_Open_Slots__c>());

        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 10,
                Data__c = '{"whatever10":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 11,
                Data__c = '{"whatever11":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 12,
                Data__c = '{"whatever12":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 1000,
                Data__c = '{"whatever1000":true}'
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfoAddTest2', // Naming this something else as parallel tests will complain about row
                                           // locking if I don't
                Locked__c = false,
                Highest_Priority__c = 10,
                Lowest_Priority__c = 1000
            )
        });

        WSU_Kyou_QueueEntry__c toMove1 = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :results.get(2).getId()];
        toMove1.Priority__c = 10;
        WSU_Kyou_QueueEntry__c toMove2 = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :results.get(3).getId()];
        toMove2.Priority__c = 11;

        WSU_Kyou_Add adder = new WSU_Kyou_Add(new Map<Integer, WSU_Kyou_QueueEntry__c>{
            12 => toMove1,
            1000 => toMove2
        });

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c order by Priority__c];

        System.assertEquals(entries.size(), 4);
        Map<Integer, String> allowedPrioritiesToData = new Map<Integer, String>{
            10 => '{"whatever12":true}',
            11 => '{"whatever1000":true}',
            12 => '{"whatever10":true}',
            13 => '{"whatever11":true}'
        };
        for (WSU_Kyou_QueueEntry__c entry : entries) {
            System.assert(allowedPrioritiesToData.containsKey(entry.Priority__c.intValue()));
            String data = allowedPrioritiestoData.remove(entry.Priority__c.intValue());
            System.assertEquals(data, entry.Data__c);
        }

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 13);
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 10);
        System.assert(!afterInfo.Locked__c);

        List<WSU_Kyou_Open_Slots__c> afterOpenSlotsRecords = [select Data__c from WSU_Kyou_Open_Slots__c];
        Set<Integer> afterOpenSlots = new Set<Integer>();
        for (WSU_Kyou_Open_Slots__c afterOpenSlotsRecord : afterOpenSlotsRecords) {
            for (Object openSlotObj : (List<Object>)JSON.deserializeUntyped(afterOpenSlotsRecord.Data__c)) {
                afterOpenSlots.add((Integer)openSlotObj);
            }
        }

        Set<Integer> expectedOpenSlots = new Set<Integer>(); // Empty!

        System.assert(expectedOpenSlots.equals(afterOpenSlots));
    }
    */

    static testMethod void testExecuteMoveOverExistingQueueGap() {
        Set<Integer> openSlots = new Set<Integer>();
        for (Integer i = 13; i < 1000; i++) {
            openSlots.add(i);
        }
        WSU_Kyou.setOpenSlots(openSlots, new List<WSU_Kyou_Open_Slots__c>());

        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 10,
                Data__c = '{"whatever10":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 11,
                Data__c = '{"whatever11":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 12,
                Data__c = '{"whatever12":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 1000,
                Data__c = '{"whatever1000":true}'
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfoAddTest2', // Naming this something else as parallel tests will complain about row
                                           // locking if I don't
                Locked__c = false,
                Highest_Priority__c = 10,
                Lowest_Priority__c = 1000
            )
        });

        WSU_Kyou_QueueEntry__c toMove = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :results.get(3).getId()];
        toMove.Priority__c = 11;

        WSU_Kyou_Add adder = new WSU_Kyou_Add(new Map<Integer, WSU_Kyou_QueueEntry__c>{
            1000 => toMove
        });

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c order by Priority__c];

        System.assertEquals(entries.size(), 4);
        Map<Integer, String> allowedPrioritiesToData = new Map<Integer, String>{
            10 => '{"whatever10":true}',
            11 => '{"whatever1000":true}',
            12 => '{"whatever11":true}',
            13 => '{"whatever12":true}'
        };
        for (WSU_Kyou_QueueEntry__c entry : entries) {
            System.assert(allowedPrioritiesToData.containsKey(entry.Priority__c.intValue()));
            String data = allowedPrioritiestoData.remove(entry.Priority__c.intValue());
            System.assertEquals(data, entry.Data__c);
        }

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 13);
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 10);
        System.assert(!afterInfo.Locked__c);

        List<WSU_Kyou_Open_Slots__c> afterOpenSlotsRecords = [select Data__c from WSU_Kyou_Open_Slots__c];
        Set<Integer> afterOpenSlots = new Set<Integer>();
        for (WSU_Kyou_Open_Slots__c afterOpenSlotsRecord : afterOpenSlotsRecords) {
            for (Object openSlotObj : (List<Object>)JSON.deserializeUntyped(afterOpenSlotsRecord.Data__c)) {
                afterOpenSlots.add((Integer)openSlotObj);
            }
        }

        Set<Integer> expectedOpenSlots = new Set<Integer>(); // Empty!

        System.assert(expectedOpenSlots.equals(afterOpenSlots));
    }

    static testMethod void testExecuteMoveWayDownExistingQueueGap() {
        Set<Integer> openSlots = new Set<Integer>();
        for (Integer i = 13; i < 1000; i++) {
            openSlots.add(i);
        }
        WSU_Kyou.setOpenSlots(openSlots, new List<WSU_Kyou_Open_Slots__c>());

        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 10,
                Data__c = '{"whatever10":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 11,
                Data__c = '{"whatever11":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 12,
                Data__c = '{"whatever12":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 1000,
                Data__c = '{"whatever1000":true}'
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfoAddTest2', // Naming this something else as parallel tests will complain about row
                                           // locking if I don't
                Locked__c = false,
                Highest_Priority__c = 10,
                Lowest_Priority__c = 1000
            )
        });

        WSU_Kyou_QueueEntry__c toMove = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :results.get(1).getId()];
        toMove.Priority__c = 10001;

        WSU_Kyou_Add adder = new WSU_Kyou_Add(new Map<Integer, WSU_Kyou_QueueEntry__c>{
            11 => toMove
        });

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c order by Priority__c];

        System.assertEquals(entries.size(), 4);
        Map<Integer, String> allowedPrioritiesToData = new Map<Integer, String>{
            10 => '{"whatever10":true}',
            12 => '{"whatever12":true}',
            1000 => '{"whatever1000":true}',
            10001 => '{"whatever11":true}'
        };
        for (WSU_Kyou_QueueEntry__c entry : entries) {
            System.assert(allowedPrioritiesToData.containsKey(entry.Priority__c.intValue()));
            String data = allowedPrioritiestoData.remove(entry.Priority__c.intValue());
            System.assertEquals(data, entry.Data__c);
        }

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 10001);
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 10);
        System.assert(!afterInfo.Locked__c);

        List<WSU_Kyou_Open_Slots__c> afterOpenSlotsRecords = [select Data__c from WSU_Kyou_Open_Slots__c];
        Set<Integer> afterOpenSlots = new Set<Integer>();
        for (WSU_Kyou_Open_Slots__c afterOpenSlotsRecord : afterOpenSlotsRecords) {
            for (Object openSlotObj : (List<Object>)JSON.deserializeUntyped(afterOpenSlotsRecord.Data__c)) {
                afterOpenSlots.add((Integer)openSlotObj);
            }
        }

        Set<Integer> expectedOpenSlots = new Set<Integer>{
            11
        };
        for (Integer i = 13; i < 1000; i++) {
            expectedOpenSlots.add(i);
        }
        for (Integer i = 1001; i < 10001; i++) {
            expectedOpenSlots.add(i);
        }

        System.assert(expectedOpenSlots.equals(afterOpenSlots));
    }

    static testMethod void testExecuteMoveWayUpExistingQueueGap() {
        Set<Integer> openSlots = new Set<Integer>();
        for (Integer i = 13; i < 1000; i++) {
            openSlots.add(i);
        }
        WSU_Kyou.setOpenSlots(openSlots, new List<WSU_Kyou_Open_Slots__c>());

        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 10,
                Data__c = '{"whatever10":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 11,
                Data__c = '{"whatever11":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 12,
                Data__c = '{"whatever12":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 1000,
                Data__c = '{"whatever1000":true}'
            ),
            new WSU_Kyou_Info__c(
                Name = 'KyouInfoAddTest2', // Naming this something else as parallel tests will complain about row
                                           // locking if I don't
                Locked__c = false,
                Highest_Priority__c = 10,
                Lowest_Priority__c = 1000
            )
        });

        WSU_Kyou_QueueEntry__c toMove = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :results.get(3).getId()];
        toMove.Priority__c = 1;

        WSU_Kyou_Add adder = new WSU_Kyou_Add(new Map<Integer, WSU_Kyou_QueueEntry__c>{
            1000 => toMove
        });

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c order by Priority__c];

        System.assertEquals(entries.size(), 4);
        Map<Integer, String> allowedPrioritiesToData = new Map<Integer, String>{
            1 => '{"whatever1000":true}',
            10 => '{"whatever10":true}',
            11 => '{"whatever11":true}',
            12 => '{"whatever12":true}'
        };
        for (WSU_Kyou_QueueEntry__c entry : entries) {
            System.assert(allowedPrioritiesToData.containsKey(entry.Priority__c.intValue()));
            String data = allowedPrioritiestoData.remove(entry.Priority__c.intValue());
            System.assertEquals(data, entry.Data__c);
        }

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 12);
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 1);
        System.assert(!afterInfo.Locked__c);

        List<WSU_Kyou_Open_Slots__c> afterOpenSlotsRecords = [select Data__c from WSU_Kyou_Open_Slots__c];
        Set<Integer> afterOpenSlots = new Set<Integer>();
        for (WSU_Kyou_Open_Slots__c afterOpenSlotsRecord : afterOpenSlotsRecords) {
            for (Object openSlotObj : (List<Object>)JSON.deserializeUntyped(afterOpenSlotsRecord.Data__c)) {
                afterOpenSlots.add((Integer)openSlotObj);
            }
        }

        Set<Integer> expectedOpenSlots = new Set<Integer>();
        for (Integer i = 2; i < 10; i++) {
            expectedOpenSlots.add(i);
        }

        System.assert(expectedOpenSlots.equals(afterOpenSlots));
    }

    static testMethod void testExecuteDeleteOne() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Locked__c = false,
                Highest_Priority__c = 0,
                Lowest_Priority__c = 1
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = '{"whatever0":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 1,
                Data__c = '{"whatever1":true}'
            )
        });

        WSU_Kyou_QueueEntry__c toDelete = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :results.get(1).getId()];

        WSU_Kyou_Add adder = new WSU_Kyou_Add(new Map<Integer, WSU_Kyou_QueueEntry__c>{
            0 => toDelete
        }, true);

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c order by Priority__c];
        System.assertEquals(entries.size(), 1);
        System.assertEquals(entries.get(0).Priority__c.intValue(), 1);
        System.assertEquals(entries.get(0).Data__c, '{"whatever1":true}'); // Swapped

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Lowest_Priority__c.intValue(), 1);
        System.assertEquals(afterInfo.Highest_Priority__c.intValue(), 1);
        System.assert(!afterInfo.Locked__c);

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
    }

    static testMethod void testExecuteDeleteBoth() {
        List<Database.SaveResult> results = Database.Insert(new List<sObject>{
            new WSU_Kyou_Info__c(
                Name = 'KyouInfo',
                Locked__c = false,
                Highest_Priority__c = 0,
                Lowest_Priority__c = 1
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 0,
                Data__c = '{"whatever0":true}'
            ),
            new WSU_Kyou_QueueEntry__c(
                Priority__c = 1,
                Data__c = '{"whatever1":true}'
            )
        });

        WSU_Kyou_QueueEntry__c toDelete0 = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :results.get(1).getId()];
        WSU_Kyou_QueueEntry__c toDelete1 = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = :results.get(2).getId()];

        WSU_Kyou_Add adder = new WSU_Kyou_Add(new Map<Integer, WSU_Kyou_QueueEntry__c>{
            0 => toDelete0,
            1 => toDelete1
        }, true);

        QueueableContext qc = null;
        adder.execute(qc);

        List<WSU_Kyou_QueueEntry__c> entries = [select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c order by Priority__c];
        System.assertEquals(entries.size(), 0);

        List<WSU_Kyou_Info__c> afterInfos = WSU_Kyou_Info__c.getAll().values();
        System.assertEquals(afterInfos.size(), 1);
        WSU_Kyou_Info__c afterInfo = afterInfos.get(0);
        System.assertEquals(afterInfo.Highest_Priority__c, null);
        System.assertEquals(afterInfo.Lowest_Priority__c, null);
        System.assert(!afterInfo.Locked__c);

        System.assertEquals([select count() from WSU_Kyou_Open_Slots__c], 0);
    }

}
