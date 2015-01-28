require([
    'jquery',
    'underscorejs/underscoremin',
    'backbonejs/backbonemin',
    'sforce',
    'spin',
    'jqueryui',
    'jquery-cometd',
], function(
    $,
    _,
    Backbone,
    sforce,
    Spinner
) {
    var defaults = {
    };
    var apiVersion = '32.0';
    var Kyou = Backbone.View.extend({
        events: {
            'click .kyou-args': function(ev) {
                var target = $(ev.target);
                var popup = $('<div>' + target.data('content') + '</div>');
                this.$el.append(popup);
                popup.dialog({
                    modal: true,
                    title: 'Arguments for Job with Priority ' + parseInt(target.parent().siblings('td[data-api-name=Priority__c]').text()),
                });
            },
        },

        currentPopups: [],

        sampleTr: null,
        columns: {},

        movingTr: null,

        entryTableSelector: '[id$="kyou-entry-table"]',

        initialize: function() {
            // HEREHERE FIXME: paginate, other ways to sort? (take explicit priority number in; elevate
            // to top; move to bottom);

            $.cometd.unregisterTransport('websocket'); // Server side complains, and it looks like the library doesn't
                                                       // recover quite right
            $.cometd.init({
                url: window.location.protocol + '//' + window.location.hostname +'/cometd/' + apiVersion + '/',
                //url: 'https://cs11.salesforce.com/cometd/' + apiVersion + '/',
                requestHeaders: {
                    'Authorization': 'OAuth ' + sforceSessionId,
                },
            });

            console.log('KYOUVIEWINIT');
            sforce.connection.sessionId = sforceSessionId;
            $.ajaxSetup({
                headers: {
                    'Authorization': 'Bearer ' + sforceSessionId,
                },
            });

            /*
            this.sampleTr = this.$(this.entryTableSelector + ' tbody tr').remove();
            var sampleTrTds = this.sampleTr.children('td');
            this.$(this.entryTableSelector + ' thead tr th').each($.proxy(function(idx, thEl) {
                thEl = $(thEl);
                this.columns[thEl.children('div').text()] = $(sampleTrTds[idx]).data('apiName');
            }, this));
            */
            this.extractTableSample();

            dispatcher.on('kyou:reRenderEntryTable', $.proxy(function(msg) {
                this.extractTableSample();
            }, this));

            // Make sortable
            this.$(this.entryTableSelector + ' tbody').sortable({
                start: $.proxy(function(ev, ui) {
                    //console.log('START');
                    this.movingTr = ui.item.index();
                }, this),
                stop: $.proxy(function(ev, ui) {
                    // Try to reorder, call sortable.cancel() if locked
                    // ui.item.parent().sortable('cancel')
                    //console.log('STOP');

                    // Disable while we handle this
                    ui.item.parent().sortable('disable');

                    if (ui.item.index() !== this.movingTr) { // We actually moved
                        var newPriority = null;
                        if (_.size(ui.item.next()) > 0) {
                            newPriority = parseInt(ui.item.next().children('td[data-api-name=Priority__c]').text());
                        } else {
                            newPriority = parseInt(ui.item.prev().children('td[data-api-name=Priority__c]').text());
                        }

                        //if (newPriority != parseInt(ui.item.children('td[data-api-name=Priority__c]').text())) {
                        console.log('CHANGING TO ' + newPriority);
                        // HEREHERE FIXME FIXME: add streaming api stuff to add/remove rows; fix drag down bug; why
                        // doesn't lock flag in ui change when i sort?

                        // FIXME: this doesn't stick around for long enough!
                        var spinner = new Spinner({
                            lines: 10,
                            length: 3,
                            width: 2,
                            radius: 2,
                            top: 0,
                            left: 0,
                            className: 'spinner',
                            color: '#333',
                        });
                        spinner.spin();
                        this.$('[id$=kyou_entries] .mainTitle').append(spinner.el);

                        Visualforce.remoting.Manager.invokeAction(
                            //'{!$RemoteAction.WSU_Kyou_Controller.getEntries}',
                            'WSU_Kyou_Controller.move',
                            ui.item.data('sfId'),
                            newPriority,
                            $.proxy(function(result, metadata) {
                                console.log('MOVED! ' + result);
                                if (!metadata.status && metadata.type === 'exception') {
                                    if (metadata.message === 'Cannot move while locked') {
                                        ui.item.parent().sortable('cancel');
                                        // FIXME: show some kind of failure indicator
                                    }
                                }

                                ui.item.parent().sortable('enable');
                                spinner.el.remove(); // Memory leak?  Will var spinner ever go out of scope?
                            }, this)
                        );
                        //}
                    } else {
                        ui.item.parent().sortable('enable');
                    }

                    this.fixClasses();
                }, this),
            });

            Visualforce.remoting.Manager.invokeAction(
                //'{!$RemoteAction.WSU_Kyou_Controller.getEntries}',
                'WSU_Kyou_Controller.getEntries',
                1,
                null,
                $.proxy(function(result) {
                    console.log('RESULT ' + result);
                    if (_.has(result, 'perpetuating')) {
                        var nextRun = new Date(result.perpetuating);
                        this.$('#kyou-status-next-run').text('Next run scheduled at ' + nextRun.toLocaleString());
                    } else {
                        this.$('#kyou-status-next-run').text('Kyou is not perpetuating');
                    }

                    this.lockHandler(result.locked);

                    _.each(result.entries, function(entry) {
                        // add this.sampleTr copy to this.$('tbody')
                        /*
                        var newTr = this.sampleTr.clone();

                        var entryData = JSON.parse(_.unescape(entry.Data__c));

                        newTr.children('td').each(function(idx, tdEl) {
                            tdEl = $(tdEl);
                            var apiName = tdEl.data('apiName');
                            var dotLocation = apiName.indexOf('.');
                            if (dotLocation < 0) { // Not found
                                tdEl.text(entry[apiName]);
                            } else {
                                var components = apiName.split('.');
                                // Note I don't check that the leftmost part is "Data__c" - I just assume that's the
                                // intent
                                var newText = entryData[components[1]];
                                if (tdEl.data('popup')) {
                                    if (newText == null) {
                                        tdEl.text('');
                                    } else {
                                        var toAppend = $('<a href="#" class="kyou-args">Show arguments</a>');
                                        toAppend.data('content', JSON.stringify(newText, undefined, 4));
                                        tdEl.append(toAppend);
                                    }
                                } else {
                                    tdEl.text(newText == null ? '' : newText);
                                }
                            }
                        });

                        newTr.data('sfId', entry.Id);
                        */

                        var newTr = this.makeNewTr(entry);

                        this.$(this.entryTableSelector + ' tbody').append(newTr);
                    }, this);
                    this.fixClasses();
                }, this)
            );

            $.cometd.subscribe('/topic/KyouQueueEntries', $.proxy(function(message) {
                console.log('PUSH! ' + message);
                var tbodyEl = this.$(this.entryTableSelector + ' tbody');

                if (message.data.event.type === 'updated') {
                    // I'm not 100% convinced that everything comes back via the streaming API, so I can't rely on any
                    // kind of mechanism to avoid reordering when I know I've just done a drag sort.

                    var trToUpdate = $(_.find(tbodyEl.children('tr'), function(trEl) {
                        return message.data.sobject.Id === $(trEl).data('sfId');
                    }));
                    var priorityTd = trToUpdate.children('td[data-api-name=Priority__c]');

                    priorityTd.text(message.data.sobject.Priority__c);

                    var originalBackgroundColor = trToUpdate.css('backgroundColor');
                    var originalFontWeight = trToUpdate.css('fontWeight');
                    priorityTd.css({
                        fontWeight: 'bold',
                    });
                    trToUpdate.animate({
                        backgroundColor: '#69c',
                    }, 1000, function() {
                        trToUpdate.animate({
                            backgroundColor: originalBackgroundColor,
                        }, 2000, function() {
                            priorityTd.css({
                                fontWeight: originalFontWeight,
                            });
                        });
                    });

                    this.placeTr(trToUpdate, tbodyEl);
                } else if (message.data.event.type === 'created') {
                    // FIXME: adding a job with an empty kyou doesn't work
                    if (_.size(tbodyEl.children('tr')) === 0) {
                        window.reRenderEntries();
                        //this.extractTableSample();
                    } else {
                        //this.addTr(message.data.sobject.Id, tbodyEl);
                        var entry = sforce.connection.query(
                            'select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = \'' +
                                message.data.sobject.Id +
                                '\' limit 1'
                        ).getArray('records')[0];

                        entry.Priority__c = Math.floor(entry.Priority__c);

                        var newTr = this.makeNewTr(entry);

                        this.placeTr(newTr, tbodyEl);
                    }
                    /*
                    var entry = sforce.connection.query(
                        'select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = \'' +
                            message.data.sobject.Id +
                            '\' limit 1'
                    ).getArray('records')[0];

                    entry.Priority__c = Math.floor(entry.Priority__c);

                    var newTr = this.makeNewTr(entry);

                    this.placeTr(newTr, tbodyEl);
                    */
                } else if (message.data.event.type === 'deleted') {
                    var trToDelete = $(_.find(this.$(this.entryTableSelector + ' tbody tr'), function(trEl) {
                        return message.data.sobject.Id === $(trEl).data('sfId');
                    }));
                    trToDelete.animate({
                        backgroundColor: '#69e640',
                    }, 2000, function() {
                        trToDelete.remove();
                    });
                } else {
                    console.log('PUSH SOMETHING ELSE ' + message.data.event.type);
                }

            }, this));

            $.cometd.subscribe('/topic/KyouInfo', $.proxy(function(message) {
                console.log('PUSHINFO! ' + message);
                if (message.data.event.type === 'updated' || message.data.event.type === 'created') {
                    this.lockHandler(message.data.sobject.Locked__c);
                } else {
                    console.log('PUSHINFO SOMETHING ELSE ' + message.data.event.type);
                }
            }, this));
        },

        extractTableSample: function() {
            this.sampleTr = this.$(this.entryTableSelector + ' tbody tr').remove();
            var sampleTrTds = this.sampleTr.children('td');
            this.$(this.entryTableSelector + ' thead tr th').each($.proxy(function(idx, thEl) {
                thEl = $(thEl);
                this.columns[thEl.children('div').text()] = $(sampleTrTds[idx]).data('apiName');
            }, this));
        },

        addTr: function(entryId, tbodyEl) {
            var entry = sforce.connection.query(
                'select Id, Priority__c, Data__c from WSU_Kyou_QueueEntry__c where Id = \'' +
                    entryId +
                    '\' limit 1'
            ).getArray('records')[0];

            entry.Priority__c = Math.floor(entry.Priority__c);

            var newTr = this.makeNewTr(entry);

            this.placeTr(newTr, tbodyEl);
        },

        placeTr: function(trToPlace, tbodyEl) {
            var trToPrecede = _.find(tbodyEl.children('tr'), function(trEl) {
                //return message.data.sobject.Priority__c < parseInt($(trEl).children('td[data-api-name=Priority__c]').text());
                return parseInt(trToPlace.children('td[data-api-name=Priority__c]').text()) < parseInt($(trEl).children('td[data-api-name=Priority__c]').text());
            });
            if (_.isUndefined(trToPrecede)) {
                // FIXME: this will change during pagination
                tbodyEl.append(trToPlace); // Move to end of table
            } else {
                trToPlace.insertBefore(trToPrecede);
            }
        },

        makeNewTr: function(entry) {
            var newTr = this.sampleTr.clone();

            var entryData = JSON.parse(_.unescape(entry.Data__c));

            newTr.children('td').each(function(idx, tdEl) {
                tdEl = $(tdEl);
                var apiName = tdEl.data('apiName');
                if (!_.isUndefined(apiName)) { // This seems weird.
                    var dotLocation = apiName.indexOf('.');
                    if (dotLocation < 0) { // Not found
                        tdEl.text(entry[apiName]);
                    } else {
                        var components = apiName.split('.');
                        // Note I don't check that the leftmost part is "Data__c" - I just assume that's the
                        // intent
                        var newText = entryData[components[1]];
                        if (tdEl.data('popup')) {
                            if (newText == null) {
                                tdEl.text('');
                            } else {
                                var toAppend = $('<a href="#" class="kyou-args">Show arguments</a>');
                                toAppend.data('content', JSON.stringify(newText, undefined, 4));
                                tdEl.append(toAppend);
                            }
                        } else {
                            tdEl.text(newText == null ? '' : newText);
                        }
                    }
                }
            });

            newTr.data('sfId', entry.Id);

            return newTr;
        },

        lockHandler: function(locked) {
            if (locked) {
                this.$('#kyou-status-locked').text('Yes');
                this.$('#kyou-status-locked').addClass('locked');
                // Disable sorting
                this.$(this.entryTableSelector + ' tbody').sortable('disable');
            } else {
                this.$('#kyou-status-locked').text('No');
                this.$('#kyou-status-locked').removeClass('locked');
                // Enable sorting
                this.$(this.entryTableSelector + ' tbody').sortable('enable');
            }
        },

        fixClasses: function() {
            var trs = this.$(this.entryTableSelector + ' tbody tr');
            trs.removeClass('first last even odd');
            trs.addClass(function(index, current) {
                var toReturn = '';
                if (index === 0) {
                    toReturn += 'first ';
                }
                if (index === trs.length - 1) {
                    toReturn += 'last ';
                }
                if (index % 2 === 0) {
                    toReturn += 'even ';
                }
                if (index % 2 === 1) {
                    toReturn += 'odd ';
                }
                return toReturn.substring(0, toReturn.length - 1);
            });
        },

    });

    $(function() {
        $('div[id$=kyou]').each(function() {
            // A pageBlock's pbBody div is the meat and potatoes.
            //var kyou = new Kyou({el: $(this).children('.pbBody')});
            var kyou = new Kyou({el: $(this)});
        });
    });
});
