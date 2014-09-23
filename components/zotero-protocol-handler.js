/*
    ***** BEGIN LICENSE BLOCK *****
    
    Copyright © 2009 Center for History and New Media
                     George Mason University, Fairfax, Virginia, USA
                     http://zotero.org
    
    This file is part of Zotero.
    
    Zotero is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    Zotero is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.
    
    You should have received a copy of the GNU Affero General Public License
    along with Zotero.  If not, see <http://www.gnu.org/licenses/>.
    
	
	Based on nsChromeExtensionHandler example code by Ed Anuff at
	http://kb.mozillazine.org/Dev_:_Extending_the_Chrome_Protocol
	
    ***** END LICENSE BLOCK *****
*/

const ZOTERO_SCHEME = "zotero";
const ZOTERO_PROTOCOL_CID = Components.ID("{9BC3D762-9038-486A-9D70-C997AF848A7C}");
const ZOTERO_PROTOCOL_CONTRACTID = "@mozilla.org/network/protocol;1?name=" + ZOTERO_SCHEME;
const ZOTERO_PROTOCOL_NAME = "Zotero Chrome Extension Protocol";

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cr = Components.results;

Components.utils.import("resource://gre/modules/XPCOMUtils.jsm");

// Dummy chrome URL used to obtain a valid chrome channel
// This one was chosen at random and should be able to be substituted
// for any other well known chrome URL in the browser installation
const DUMMY_CHROME_URL = "chrome://mozapps/content/xpinstall/xpinstallConfirm.xul";

var Zotero = Components.classes["@zotero.org/Zotero;1"]
	.getService(Components.interfaces.nsISupports)
	.wrappedJSObject;

var ioService = Components.classes["@mozilla.org/network/io-service;1"]
	.getService(Components.interfaces.nsIIOService);

function ZoteroProtocolHandler() {
	this.wrappedJSObject = this;
	this._principal = null;
	this._extensions = {};
	
	
	/**
	 * zotero://data/library/collection/ABCD1234/items?sort=itemType&direction=desc
	 * zotero://data/groups/12345/collection/ABCD1234/items?sort=title&direction=asc
	 */
	var DataExtension = {
		loadAsChrome: false,
		
		newChannel: function (uri) {
			return new AsyncChannel(uri, function* () {
				this.contentType = 'text/plain';
				
				path = uri.spec.match(/zotero:\/\/[^/]+(.*)/)[1];
				
				try {
					return Zotero.Utilities.Internal.getAsyncInputStream(
						Zotero.API.Data.getGenerator(path)
					);
				}
				catch (e if e instanceof Zotero.Router.InvalidPathException) {
					return "URL could not be parsed";
				}
			});
		}
	};
	
	
	/*
	 * Report generation extension for Zotero protocol
	 */
	var ReportExtension = {
		loadAsChrome: false,
		
		newChannel: function (uri) {
			return new AsyncChannel(uri, function* () {
				var path = uri.path;
				if (!path) {
					return 'Invalid URL';
				}
				// Strip leading '/'
				path = path.substr(1);
				
				// Proxy CSS files
				if (path.endsWith('.css')) {
					var chromeURL = 'chrome://zotero/skin/report/' + path;
					Zotero.debug(chromeURL);
					var ios = Components.classes["@mozilla.org/network/io-service;1"]
						.getService(Components.interfaces.nsIIOService);
					let uri = ios.newURI(chromeURL, null, null);
					var chromeReg = Components.classes["@mozilla.org/chrome/chrome-registry;1"]
						.getService(Components.interfaces.nsIChromeRegistry);
					return chromeReg.convertChromeURL(uri);
				}
				
				var params = {
					objectType: 'item',
					format: 'html',
					sort: 'title'
				};
				var router = new Zotero.Router(params);
				
				// Items within a collection or search
				router.add('library/:scopeObject/:scopeObjectKey/items/report.html', function () {
					params.libraryID = 0;
				});
				router.add('groups/:groupID/:scopeObject/:scopeObjectKey/items/report.html');
				
				// All items
				router.add('library/items/report.html', function () {
					params.libraryID = 0;
				});
				router.add('groups/:groupID/items/report.html');
				
				// Old-style URLs
				router.add('collection/:id/html/report.html', function () {
					params.scopeObject = 'collections';
					var lkh = Zotero.Collections.parseLibraryKeyHash(params.id);
					if (lkh) {
						params.libraryID = lkh.libraryID;
						params.scopeObjectKey = lkh.key;
					}
					else {
						params.scopeObjectID = params.id;
					}
					delete params.id;
				});
				router.add('search/:id/html/report.html', function () {
					params.scopeObject = 'searches';
					var lkh = Zotero.Searches.parseLibraryKeyHash(this.id);
					if (lkh) {
						params.libraryID = lkh.libraryID;
						params.scopeObjectKey = lkh.key;
					}
					else {
						params.scopeObjectID = this.id;
					}
					delete params.id;
				});
				router.add('items/:ids/html/report.html', function () {
					var ids = this.ids.split('-');
					params.libraryID = ids[0].split('_')[0];
					params.itemKey = ids.map(x => x.split('_')[1]);
					delete params.ids;
				});
				
				var parsed = router.run(path);
				if (!parsed) {
					return "URL could not be parsed";
				}
				
				// TODO: support old URLs
				// collection
				// search
				// items
				// item
				if (params.sort.contains('/')) {
					let parts = params.sort.split('/');
					params.sort = parts[0];
					params.direction = parts[1] == 'd' ? 'desc' : 'asc';
				}
				
				try {
					Zotero.API.parseParams(params);
					var results = yield Zotero.API.getResultsFromParams(params);
				}
				catch (e) {
					Zotero.debug(e, 1);
					return e.toString();
				}
				
				var mimeType, content = '';
				var items = [];
				var itemsHash = {}; // key = itemID, val = position in |items|
				var searchItemIDs = {}; // hash of all selected items
				var searchParentIDs = {}; // hash of parents of selected child items
				var searchChildIDs = {}; // hash of selected chlid items
				
				var includeAllChildItems = Zotero.Prefs.get('report.includeAllChildItems');
				var combineChildItems = Zotero.Prefs.get('report.combineChildItems');
				
				var unhandledParents = {};
				for (var i=0; i<results.length; i++) {
					// Don't add child items directly
					// (instead mark their parents for inclusion below)
					var parentItemID = results[i].parentItemID;
					if (parentItemID) {
						searchParentIDs[parentItemID] = true;
						searchChildIDs[results[i].id] = true;
						
						// Don't include all child items if any child
						// items were selected
						includeAllChildItems = false;
					}
					// If combining children or standalone note/attachment, add matching parents
					else if (combineChildItems || !results[i].isRegularItem()
							|| results[i].numChildren() == 0) {
						itemsHash[results[i].id] = [items.length];
						items.push(yield results[i].toJSON({ mode: 'full' }));
						// Flag item as a search match
						items[items.length - 1].reportSearchMatch = true;
					}
					else {
						unhandledParents[i] = true;
					}
					searchItemIDs[results[i].id] = true;
				}
				
				// If including all child items, add children of all matched
				// parents to the child array
				if (includeAllChildItems) {
					for (var id in searchItemIDs) {
						if (!searchChildIDs[id]) {
							var children = [];
							var item = yield Zotero.Items.getAsync(id);
							if (!item.isRegularItem()) {
								continue;
							}
							var func = function (ids) {
								if (ids) {
									for (var i=0; i<ids.length; i++) {
										searchChildIDs[ids[i]] = true;
									}
								}
							};
							yield item.loadChildItems();
							func(item.getNotes());
							func(item.getAttachments());
						}
					}
				}
				// If not including all children, add matching parents,
				// in case they don't have any matching children below
				else {
					for (var i in unhandledParents) {
						itemsHash[results[i].id] = [items.length];
						items.push(yield results[i].toJSON({ mode: 'full' }));
						// Flag item as a search match
						items[items.length - 1].reportSearchMatch = true;
					}
				}
				
				if (combineChildItems) {
					// Add parents of matches if parents aren't matches themselves
					for (var id in searchParentIDs) {
						if (!searchItemIDs[id] && !itemsHash[id]) {
							var item = yield Zotero.Items.getAsync(id);
							itemsHash[id] = items.length;
							items.push(yield item.toJSON({ mode: 'full' }));
						}
					}
					
					// Add children to reportChildren property of parents
					for (var id in searchChildIDs) {
						var item = yield Zotero.Items.getAsync(id);
						var parentID = item.parentID;
						if (!items[itemsHash[parentID]].reportChildren) {
							items[itemsHash[parentID]].reportChildren = {
								notes: [],
								attachments: []
							};
						}
						if (item.isNote()) {
							items[itemsHash[parentID]].reportChildren.notes.push(yield item.toJSON({ mode: 'full' }));
						}
						if (item.isAttachment()) {
							items[itemsHash[parentID]].reportChildren.attachments.push(yield item.toJSON({ mode: 'full' }));
						}
					}
				}
				// If not combining children, add a parent/child pair
				// for each matching child
				else {
					for (var id in searchChildIDs) {
						var item = yield Zotero.Items.getAsync(id);
						var parentID = item.parentID;
						var parentItem = Zotero.Items.get(parentID);
						
						if (!itemsHash[parentID]) {
							// If parent is a search match and not yet added,
							// add on its own
							if (searchItemIDs[parentID]) {
								itemsHash[parentID] = [items.length];
								items.push(yield parentItem.toJSON({ mode: 'full' }));
								items[items.length - 1].reportSearchMatch = true;
							}
							else {
								itemsHash[parentID] = [];
							}
						}
						
						// Now add parent and child
						itemsHash[parentID].push(items.length);
						items.push(parentItem.toJSON({ mode: 'full' }));
						if (item.isNote()) {
							items[items.length - 1].reportChildren = {
								notes: [yield item.toJSON({ mode: 'full' })],
								attachments: []
							};
						}
						else if (item.isAttachment()) {
							items[items.length - 1].reportChildren = {
								notes: [],
								attachments: [yield item.toJSON({ mode: 'full' })]
							};
						}
					}
				}
				
				// Sort items
				// TODO: restore multiple sort fields
				var sorts = [{
					field: params.sort,
					order: params.direction != 'desc' ? 1 : -1
				}];
				
				
				var collation = Zotero.getLocaleCollation();
				var compareFunction = function(a, b) {
					var index = 0;
					
					// Multidimensional sort
					do {
						// In combineChildItems, use note or attachment as item
						if (!combineChildItems) {
							if (a.reportChildren) {
								if (a.reportChildren.notes.length) {
									a = a.reportChildren.notes[0];
								}
								else {
									a = a.reportChildren.attachments[0];
								}
							}
							
							if (b.reportChildren) {
								if (b.reportChildren.notes.length) {
									b = b.reportChildren.notes[0];
								}
								else {
									b = b.reportChildren.attachments[0];
								}
							}
						}
						
						var valA, valB;
						
						if (sorts[index].field == 'title') {
							// For notes, use content for 'title'
							if (a.itemType == 'note') {
								valA = a.note;
							}
							else {
								valA = a.title; 
							}
							
							if (b.itemType == 'note') {
								valB = b.note;
							}
							else {
								valB = b.title; 
							}
							
							valA = Zotero.Items.getSortTitle(valA);
							valB = Zotero.Items.getSortTitle(valB);
						}
						else if (sorts[index].field == 'date') {
							var itemA = Zotero.Items.getByLibraryAndKey(a.libraryID, a.key);
							var itemB = Zotero.Items.getByLibraryAndKey(b.libraryID, b.key);
							valA = itemA.getField('date', true, true);
							valB = itemB.getField('date', true, true);
						}
						// TEMP: This is an ugly hack to make creator sorting
						// slightly less broken. To do this right, real creator
						// sorting needs to be abstracted from itemTreeView.js.
						else if (sorts[index].field == 'firstCreator') {
							var itemA = Zotero.Items.getByLibraryAndKey(a.libraryID, a.key);
							var itemB = Zotero.Items.getByLibraryAndKey(b.libraryID, b.key);
							valA = itemA.getField('firstCreator');
							valB = itemB.getField('firstCreator');
						}
						else {
							valA = a[sorts[index].field];
							valB = b[sorts[index].field];
						}
						
						// Put empty values last
						if (!valA && valB) {
							var cmp = 1;
						}
						else if (valA && !valB) {
							var cmp = -1;
						}
						else {
							var cmp = collation.compareString(0, valA, valB);
						}
						
						var result = 0;
						if (cmp != 0) {
							result = cmp * sorts[index].order;
						}
						index++;
					}
					while (result == 0 && sorts[index]);
					
					return result;
				};
				
				items.sort(compareFunction);
				for (var i in items) {
					if (items[i].reportChildren) {
						items[i].reportChildren.notes.sort(compareFunction);
						items[i].reportChildren.attachments.sort(compareFunction);
					}
				}
				
				// Pass off to the appropriate handler
				switch (params.format) {
					case 'rtf':
						this.contentType = 'text/rtf';
						return '';
						
					case 'csv':
						this.contentType = 'text/plain';
						return '';
					
					default:
						this.contentType = 'text/html';
						return Zotero.Utilities.Internal.getAsyncInputStream(
							Zotero.Report.HTML.listGenerator(items, combineChildItems),
							function () {
								return '<span style="color: red; font-weight: bold">Error generating report</span>';
							}
						);
				}
			});
		}
	};
	
	/**
	 * Generate MIT SIMILE Timeline
	 *
	 * Query string key abbreviations: intervals = i
	 *                                 dateType = t
	 *                                 timelineDate = d
	 * 
	 * interval abbreviations:  day = d  |  month = m  |  year = y  |  decade = e  |  century = c  |  millennium = i
	 * dateType abbreviations:  date = d  |  dateAdded = da  |  dateModified = dm
	 * timelineDate format:  shortMonthName.day.year  (year is positive for A.D. and negative for B.C.)
	 * 
	 * Defaults: intervals = month, year, decade
	 *           dateType = date
	 *           timelineDate = today's date
	 */
	var TimelineExtension = {
		loadAsChrome: true,
		
		newChannel: function (uri) {
			return new AsyncChannel(uri, function* () {
				path = uri.spec.match(/zotero:\/\/[^/]+(.*)/)[1];
				if (!path) {
					this.contentType = 'text/html';
					return 'Invalid URL';
				}
				
				var params = {};
				var router = new Zotero.Router(params);
				
				// HTML
				router.add('library/:scopeObject/:scopeObjectKey', function () {
					params.libraryID = 0;
					params.controller = 'html';
				});
				router.add('groups/:groupID/:scopeObject/:scopeObjectKey', function () {
					params.controller = 'html';
				});
				router.add('library', function () {
					params.libraryID = 0;
					params.controller = 'html';
				});
				router.add('groups/:groupID', function () {
					params.controller = 'html';
				});
				
				// Data
				router.add('data/library/:scopeObject/:scopeObjectKey', function () {
					params.libraryID = 0;
					params.controller = 'data';
				});
				router.add('data/groups/:groupID/:scopeObject/:scopeObjectKey', function () {
					params.controller = 'data';
				});
				router.add('data/library', function () {
					params.libraryID = 0;
					params.controller = 'data';
				});
				router.add('data/groups/:groupID', function () {
					params.controller = 'data';
				});
				
				// Old-style HTML URLs
				router.add('collection/:id', function () {
					params.controller = 'html';
					params.scopeObject = 'collections';
					var lkh = Zotero.Collections.parseLibraryKeyHash(params.id);
					if (lkh) {
						params.libraryID = lkh.libraryID;
						params.scopeObjectKey = lkh.key;
					}
					else {
						params.scopeObjectID = params.id;
					}
					delete params.id;
				});
				router.add('search/:id', function () {
					params.controller = 'html';
					params.scopeObject = 'searches';
					var lkh = Zotero.Searches.parseLibraryKeyHash(params.id);
					if (lkh) {
						params.libraryID = lkh.libraryID;
						params.scopeObjectKey = lkh.key;
					}
					else {
						params.scopeObjectID = params.id;
					}
					delete params.id;
				});
				router.add('/', function () {
					params.controller = 'html';
					params.libraryID = 0;
				});
				
				var parsed = router.run(path);
				if (!parsed) {
					this.contentType = 'text/html';
					return "URL could not be parsed";
				}
				if (params.groupID) {
					params.libraryID = Zotero.Groups.getLibraryIDFromGroupID(params.groupID);
				}
				
				var intervals = params.i ? params.i : '';
				var timelineDate = params.d ? params.d : '';
				var dateType = params.t ? params.t : '';
				
				// Get the collection or search object
				var collection, search;
				switch (params.scopeObject) {
					case 'collections':
						if (params.scopeObjectKey) {
							collection = yield Zotero.Collections.getByLibraryAndKeyAsync(
								params.libraryID, params.scopeObjectKey
							);
						}
						else {
							collection = yield Zotero.Collections.getAsync(params.scopeObjectID);
						}
						if (!collection) {
							this.contentType = 'text/html';
							return 'Invalid collection ID or key';
						}
						break;
					
					case 'searches':
						if (params.scopeObjectKey) {
							var s = yield Zotero.Searches.getByLibraryAndKeyAsync(
								params.libraryID, params.scopeObjectKey
							);
						}
						else {
							var s = yield Zotero.Searches.getAsync(params.scopeObjectID);
						}
						if (!s) {
							return 'Invalid search ID or key';
						}
						
						// FIXME: Hack to exclude group libraries for now
						var search = new Zotero.Search();
						search.setScope(s);
						var groups = yield Zotero.Groups.getAll();
						for each(var group in groups) {
							yield search.addCondition('libraryID', 'isNot', group.libraryID);
						}
						break;
				}
				
				//
				// Create XML file
				//
				if (params.controller == 'data') {
					switch (params.scopeObject) {
						case 'collections':
							yield collection.loadChildItems();
							var results = collection.getChildItems();
							break;
						
						case 'searches':
							var ids = yield search.search();
							var results = yield Zotero.Items.getAsync(ids);
							break;
						
						default:
							if (params.scopeObject) {
								return "Invalid scope object '" + params.scopeObject + "'";
							}
							
							let s = new Zotero.Search();
							yield s.addCondition('libraryID', 'is', params.libraryID);
							yield s.addCondition('noChildren', 'true');
							var ids = yield s.search();
							var results = yield Zotero.Items.getAsync(ids);
					}
					
					var items = [];
					// Only include parent items
					for (let i=0; i<results.length; i++) {
						if (!results[i].parentItemID) {
							items.push(results[i]);
						}
					}
					
					var dateTypes = {
						d: 'date',
						da: 'dateAdded',
						dm: 'dateModified'
					};
					
					//default dateType = date
					if (!dateType || !dateTypes[dateType]) {
						dateType = 'd';
					}
					
					this.contentType = 'application/xml';
					return Zotero.Utilities.Internal.getAsyncInputStream(
						Zotero.Timeline.generateXMLDetails(items, dateTypes[dateType])
					);
				}
				
				//
				// Generate main HTML page
				//
				content = Zotero.File.getContentsFromURL('chrome://zotero/skin/timeline/timeline.html');
				this.contentType = 'text/html';
				
				if(!timelineDate){
					timelineDate=Date();
					var dateParts=timelineDate.toString().split(' ');
					timelineDate=dateParts[1]+'.'+dateParts[2]+'.'+dateParts[3];
				}
				Zotero.debug('=');
				Zotero.debug(params.i);
				Zotero.debug(intervals);
				if (!intervals || intervals.length < 3) {
					intervals += "mye".substr(intervals.length);
				}
				
				var theIntervals = {
					d: 'Timeline.DateTime.DAY',
					m: 'Timeline.DateTime.MONTH',
					y: 'Timeline.DateTime.YEAR',
					e: 'Timeline.DateTime.DECADE',
					c: 'Timeline.DateTime.CENTURY',
					i: 'Timeline.DateTime.MILLENNIUM'
				};
				
				//sets the intervals of the timeline bands
				var tempStr = '<body onload="onLoad(';
				var a = (theIntervals[intervals[0]]) ? theIntervals[intervals[0]] : 'Timeline.DateTime.MONTH';
				var b = (theIntervals[intervals[1]]) ? theIntervals[intervals[1]] : 'Timeline.DateTime.YEAR';
				var c = (theIntervals[intervals[2]]) ? theIntervals[intervals[2]] : 'Timeline.DateTime.DECADE';
				content = content.replace(tempStr, tempStr + a + ',' + b + ',' + c + ',\'' + timelineDate + '\'');
				
				tempStr = 'document.write("<title>';
				if (params.scopeObject == 'collections') {
					content = content.replace(tempStr, tempStr + collection.name + ' - ');
				}
				else if (params.scopeObject == 'searches') {
					content = content.replace(tempStr, tempStr + search.name + ' - ');
				}
				else {
					content = content.replace(tempStr, tempStr + Zotero.getString('pane.collections.library') + ' - ');
				}
				
				tempStr = 'Timeline.loadXML("zotero://timeline/data/';
				var d = '';
				if (params.groupID) {
					d += 'groups/' + params.groupID + '/';
				}
				else {
					d += 'library/';
				}
				if (params.scopeObject) {
					d += params.scopeObject + "/" + params.scopeObjectKey;
				}
				if (dateType) {
					d += '?t=' + dateType;
				}
				return content.replace(tempStr, tempStr + d);
			});
		}
	};
	
	
	/*
		zotero://attachment/[id]/
	*/
	var AttachmentExtension = {
		loadAsChrome: false,
		
		newChannel: function (uri) {
			var self = this;
			
			return new AsyncChannel(uri, function* () {
				try {
					var errorMsg;
					var [id, fileName] = uri.path.substr(1).split('/');
					
					if (parseInt(id) != id) {
						// Proxy annotation icons
						if (id.match(/^annotation.*\.(png|html|css|gif)$/)) {
							var chromeURL = 'chrome://zotero/skin/' + id;
							var ios = Components.classes["@mozilla.org/network/io-service;1"].
										getService(Components.interfaces.nsIIOService);
							let uri = ios.newURI(chromeURL, null, null);
							var chromeReg = Components.classes["@mozilla.org/chrome/chrome-registry;1"]
									.getService(Components.interfaces.nsIChromeRegistry);
							var fileURI = chromeReg.convertChromeURL(uri);
						}
						else {
							return self._errorChannel("Attachment id not an integer");
						}
					}
					
					if (!fileURI) {
						var item = yield Zotero.Items.getAsync(id);
						if (!item) {
							return self._errorChannel("Item not found");
						}
						var file = item.getFile();
						if (!file) {
							return self._errorChannel("File not found");
						}
						if (fileName) {
							file = file.parent;
							file.append(fileName);
							if (!file.exists()) {
								return self._errorChannel("File not found");
							}
						}
					}
					
					//set originalURI so that it seems like we're serving from zotero:// protocol
					//this is necessary to allow url() links to work from within css files
					//otherwise they try to link to files on the file:// protocol, which is not allowed
					this.originalURI = uri;
					
					return file;
				}
				catch (e) {
					Zotero.debug(e);
					throw (e);
				}
			});
		},
		
		
		_errorChannel: function (msg) {
			this.status = Components.results.NS_ERROR_FAILURE;
			this.contentType = 'text/plain';
			return msg;
		}
	};
	
	
	/**
	 * zotero://select/[type]/0_ABCD1234
	 * zotero://select/[type]/1234 (not consistent across synced machines)
	 */
	var SelectExtension = {
		newChannel: function (uri) {
			return new AsyncChannel(uri, function* () {
				var path = uri.path;
				if (!path) {
					return 'Invalid URL';
				}
				// Strip leading '/'
				path = path.substr(1);
				var mimeType, content = '';
				
				var params = {
					objectType: 'item'
				};
				var router = new Zotero.Router(params);
				
				// Item within a collection or search
				router.add('library/:scopeObject/:scopeObjectKey/items/:objectKey', function () {
					params.libraryID = 0;
				});
				router.add('groups/:groupID/:scopeObject/:scopeObjectKey/items/:objectKey');
				
				// All items
				router.add('library/items/:objectKey', function () {
					params.libraryID = 0;
				});
				router.add('groups/:groupID/items/:objectKey');
				
				// Old-style URLs
				router.add('item/:id', function () {
					var lkh = Zotero.Items.parseLibraryKeyHash(params.id);
					if (lkh) {
						params.libraryID = lkh.libraryID;
						params.objectKey = lkh.key;
					}
					else {
						params.objectID = params.id;
					}
					delete params.id;
				});
				router.run(path);
				
				try {
					Zotero.API.parseParams(params);
					var results = yield Zotero.API.getResultsFromParams(params);
				}
				catch (e) {
					Zotero.debug(e, 1);
					return e.toString();
				}
				
				
				if (!results.length) {
					var msg = "Selected items not found";
					Zotero.debug(msg, 2);
					Components.utils.reportError(msg);
					return;
				}
				
				var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"]
					.getService(Components.interfaces.nsIWindowMediator);
				var win = wm.getMostRecentWindow("navigator:browser");
				
				// TODO: Currently only able to select one item
				yield win.ZoteroPane.selectItem(results[0].id);
			});
		}
	};
	
	/*
		zotero://fullscreen
	*/
	var FullscreenExtension = {
		loadAsChrome: false,
		
		newChannel: function (uri) {
			return new AsyncChannel(uri, function* () {
				try {
					var window = Components.classes["@mozilla.org/embedcomp/window-watcher;1"]
						.getService(Components.interfaces.nsIWindowWatcher)
						.openWindow(null, 'chrome://zotero/content/standalone/standalone.xul', '',
							'chrome,centerscreen,resizable', null);
				}
				catch (e) {
					Zotero.debug(e, 1);
					throw e;
				}
			});
		}
	};
	
	
	/*
		zotero://debug/
	*/
	var DebugExtension = {
		loadAsChrome: false,
		
		newChannel: function () {
			return new AsyncChannel(uri, function* () {
				var ioService = Components.classes["@mozilla.org/network/io-service;1"]
					.getService(Components.interfaces.nsIIOService);
				
				try {
					return Zotero.Debug.get();
				}
				catch (e) {
					Zotero.debug(e, 1);
					throw e;
				}
			});
		}
	};
	
	var ConnectorChannel = function(uri, data) {
		var secMan = Components.classes["@mozilla.org/scriptsecuritymanager;1"]
			.getService(Components.interfaces.nsIScriptSecurityManager);
		var ioService = Components.classes["@mozilla.org/network/io-service;1"]
			.getService(Components.interfaces.nsIIOService);
		
		this.name = uri;
		this.URI = ioService.newURI(uri, "UTF-8", null);
		this.owner = (secMan.getCodebasePrincipal || secMan.getSimpleCodebasePrincipal)(this.URI);
		this._isPending = true;
		
		var converter = Components.classes["@mozilla.org/intl/scriptableunicodeconverter"].
			createInstance(Components.interfaces.nsIScriptableUnicodeConverter);
		converter.charset = "UTF-8";
		this._stream = converter.convertToInputStream(data);
		this.contentLength = this._stream.available();
	}
	
	ConnectorChannel.prototype.contentCharset = "UTF-8";
	ConnectorChannel.prototype.contentType = "text/html";
	ConnectorChannel.prototype.notificationCallbacks = null;
	ConnectorChannel.prototype.securityInfo = null;
	ConnectorChannel.prototype.status = 0;
	ConnectorChannel.prototype.loadGroup = null;
	ConnectorChannel.prototype.loadFlags = 393216;
	
	ConnectorChannel.prototype.__defineGetter__("originalURI", function() { return this.URI });
	ConnectorChannel.prototype.__defineSetter__("originalURI", function() { });
	
	ConnectorChannel.prototype.asyncOpen = function(streamListener, context) {
		if(this.loadGroup) this.loadGroup.addRequest(this, null);
		streamListener.onStartRequest(this, context);
		streamListener.onDataAvailable(this, context, this._stream, 0, this.contentLength);
		streamListener.onStopRequest(this, context, this.status);
		this._isPending = false;
		if(this.loadGroup) this.loadGroup.removeRequest(this, null, 0);
	}
	
	ConnectorChannel.prototype.isPending = function() {
		return this._isPending;
	}
	
	ConnectorChannel.prototype.cancel = function(status) {
		this.status = status;
		this._isPending = false;
		if(this._stream) this._stream.close();
	}
	
	ConnectorChannel.prototype.suspend = function() {}
	
	ConnectorChannel.prototype.resume = function() {}
	
	ConnectorChannel.prototype.open = function() {
		return this._stream;
	}
	
	ConnectorChannel.prototype.QueryInterface = function(iid) {
		if (!iid.equals(Components.interfaces.nsIChannel) && !iid.equals(Components.interfaces.nsIRequest) &&
				!iid.equals(Components.interfaces.nsISupports)) {
			throw Components.results.NS_ERROR_NO_INTERFACE;
		}
		return this;
	}
	
	/**
	 * zotero://connector/
	 *
	 * URI spoofing for transferring page data across boundaries
	 */
	var ConnectorExtension = new function() {
		this.loadAsChrome = false;
		
		this.newChannel = function(uri) {
			var ioService = Components.classes["@mozilla.org/network/io-service;1"]
				.getService(Components.interfaces.nsIIOService);
			var secMan = Components.classes["@mozilla.org/scriptsecuritymanager;1"]
				.getService(Components.interfaces.nsIScriptSecurityManager);
			var Zotero = Components.classes["@zotero.org/Zotero;1"]
				.getService(Components.interfaces.nsISupports)
				.wrappedJSObject;
			
			try {
				var originalURI = uri.path;
				originalURI = decodeURIComponent(originalURI.substr(originalURI.indexOf("/")+1));
				if(!Zotero.Server.Connector.Data[originalURI]) {
					return null;
				} else {
					return new ConnectorChannel(originalURI, Zotero.Server.Connector.Data[originalURI]);
				}
			} catch(e) {
				Zotero.debug(e);
				throw e;
			}
		}
	};
	
	this._extensions[ZOTERO_SCHEME + "://data"] = DataExtension;
	this._extensions[ZOTERO_SCHEME + "://report"] = ReportExtension;
	this._extensions[ZOTERO_SCHEME + "://timeline"] = TimelineExtension;
	this._extensions[ZOTERO_SCHEME + "://attachment"] = AttachmentExtension;
	this._extensions[ZOTERO_SCHEME + "://select"] = SelectExtension;
	this._extensions[ZOTERO_SCHEME + "://fullscreen"] = FullscreenExtension;
	this._extensions[ZOTERO_SCHEME + "://debug"] = DebugExtension;
	this._extensions[ZOTERO_SCHEME + "://connector"] = ConnectorExtension;
}


/*
 * Implements nsIProtocolHandler
 */
ZoteroProtocolHandler.prototype = {
	scheme: ZOTERO_SCHEME,
	
	defaultPort : -1,
	
	protocolFlags :
		Components.interfaces.nsIProtocolHandler.URI_NORELATIVE |
		Components.interfaces.nsIProtocolHandler.URI_NOAUTH |
		// DEBUG: This should be URI_IS_LOCAL_FILE, and MUST be if any
		// extensions that modify data are added
		//  - https://www.zotero.org/trac/ticket/1156
		//
		Components.interfaces.nsIProtocolHandler.URI_IS_LOCAL_FILE,
		//Components.interfaces.nsIProtocolHandler.URI_LOADABLE_BY_ANYONE,
		
	allowPort : function(port, scheme) {
		return false;
	},
	
	newURI : function(spec, charset, baseURI) {
		var newURL = Components.classes["@mozilla.org/network/standard-url;1"]
			.createInstance(Components.interfaces.nsIStandardURL);
		newURL.init(1, -1, spec, charset, baseURI);
		return newURL.QueryInterface(Components.interfaces.nsIURI);
	},
	
	newChannel : function(uri) {
		var ioService = Components.classes["@mozilla.org/network/io-service;1"]
			.getService(Components.interfaces.nsIIOService);
		
		var chromeService = Components.classes["@mozilla.org/network/protocol;1?name=chrome"]
			.getService(Components.interfaces.nsIProtocolHandler);
		
		var newChannel = null;
		
		try {
			var uriString = uri.spec.toLowerCase();
			
			for (var extSpec in this._extensions) {
				var ext = this._extensions[extSpec];
				
				if (uriString.indexOf(extSpec) == 0) {
					if (!this._principal) {
						if (ext.loadAsChrome) {
							var chromeURI = chromeService.newURI(DUMMY_CHROME_URL, null, null);
							var chromeChannel = chromeService.newChannel(chromeURI);
							
							// Cache System Principal from chrome request
							// so proxied pages load with chrome privileges
							this._principal = chromeChannel.owner;
							
							var chromeRequest = chromeChannel.QueryInterface(Components.interfaces.nsIRequest);
							chromeRequest.cancel(0x804b0002); // BINDING_ABORTED
						}
					}
					
					var extChannel = ext.newChannel(uri);
					// Extension returned null, so cancel request
					if (!extChannel) {
						var chromeURI = chromeService.newURI(DUMMY_CHROME_URL, null, null);
						var extChannel = chromeService.newChannel(chromeURI);
						var chromeRequest = extChannel.QueryInterface(Components.interfaces.nsIRequest);
						chromeRequest.cancel(0x804b0002); // BINDING_ABORTED
					}
					
					// Apply cached principal to extension channel
					if (this._principal) {
						extChannel.owner = this._principal;
					}
					
					if(!extChannel.originalURI) extChannel.originalURI = uri;
					
					return extChannel;
				}
			}
			
			// pass request through to ZoteroProtocolHandler::newChannel
			if (uriString.indexOf("chrome") != 0) {
				uriString = uri.spec;
				uriString = "chrome" + uriString.substring(uriString.indexOf(":"));
				uri = chromeService.newURI(uriString, null, null);
			}
			
			newChannel = chromeService.newChannel(uri);
		}
		catch (e) {
			Components.utils.reportError(e);
			Zotero.debug(e, 1);
			throw Components.results.NS_ERROR_FAILURE;
		}
		
		return newChannel;
	},
	
	contractID: ZOTERO_PROTOCOL_CONTRACTID,
	classDescription: ZOTERO_PROTOCOL_NAME,
	classID: ZOTERO_PROTOCOL_CID,
	QueryInterface: XPCOMUtils.generateQI([Components.interfaces.nsISupports,
	                                       Components.interfaces.nsIProtocolHandler])
};


/**
 * nsIChannel implementation that takes a promise-yielding generator that returns a
 * string, nsIAsyncInputStream, or file
 */
function AsyncChannel(uri, gen) {
	this._generator = gen;
	this._isPending = true;
	
	// nsIRequest
	this.name = uri;
	this.loadFlags = 0;
	this.loadGroup = null;
	this.status = 0;
	
	// nsIChannel
	this.contentLength = -1;
	this.contentType = "text/html";
	this.contentCharset = "utf-8";
	this.URI = uri;
	this.originalURI = uri;
	this.owner = null;
	this.notificationCallbacks = null;
	this.securityInfo = null;
}

AsyncChannel.prototype = {
	asyncOpen: function (streamListener, context) {
		if (this.loadGroup) this.loadGroup.addRequest(this, null);
		
		var channel = this;
		
		var resolve;
		var reject;
		var promise = new Zotero.Promise(function () {
			resolve = arguments[0];
			reject = arguments[1];
		});
		
		var listenerWrapper = {
			onStartRequest: function (request, context) {
				Zotero.debug("Starting request");
				streamListener.onStartRequest(channel, context);
			},
			onDataAvailable: function (request, context, inputStream, offset, count) {
				//Zotero.debug("onDataAvailable");
				streamListener.onDataAvailable(channel, context, inputStream, offset, count);
			},
			onStopRequest: function (request, context, status) {
				Zotero.debug("Stopping request");
				streamListener.onStopRequest(channel, context, status);
				channel._isPending = false;
				if (status == 0) {
					resolve();
				}
				else {
					reject(new Error("AsyncChannel request failed with status " + status));
				}
			}
		};
		
		Zotero.debug("AsyncChannel's asyncOpen called");
		var t = new Date;
		
		let channel = this;
		
		// Proxy requests to other zotero:// URIs
		let uri2 = this.URI.clone();
		if (uri2.path.startsWith('/proxy/')) {
			let re = new RegExp(uri2.scheme + '://' + uri2.host + '/proxy/([^/]+)(.*)');
			let matches = uri2.spec.match(re);
			uri2.spec = uri2.scheme + '://' + matches[1] + '/' + (matches[2] ? matches[2] : '');
			var data = Zotero.File.getContentsFromURL(uri2.spec);
		}
		Zotero.Promise.try(function () {
			return data ? data : Zotero.spawn(channel._generator, channel);
		})
		.then(function (data) {
			if (typeof data == 'string') {
				Zotero.debug("AsyncChannel: Got string from generator");
				
				listenerWrapper.onStartRequest(this, context);
				
				let converter = Components.classes["@mozilla.org/intl/scriptableunicodeconverter"]
					.createInstance(Components.interfaces.nsIScriptableUnicodeConverter);
				converter.charset = "UTF-8";
				let inputStream = converter.convertToInputStream(data);
				listenerWrapper.onDataAvailable(this, context, inputStream, 0, data.length);
				
				listenerWrapper.onStopRequest(this, context, this.status);
				return promise;
			}
			// If an async input stream is given, pass the data asynchronously to the stream listener
			else if (data instanceof Ci.nsIAsyncInputStream) {
				Zotero.debug("AsyncChannel: Got input stream from generator");
				
				var pump = Cc["@mozilla.org/network/input-stream-pump;1"].createInstance(Ci.nsIInputStreamPump);
				pump.init(data, -1, -1, 0, 0, true);
				pump.asyncRead(listenerWrapper, context);
				return promise;
			}
			else if (data instanceof Ci.nsIFile || data instanceof Ci.nsIURI) {
				if (data instanceof Ci.nsIFile) {
					Zotero.debug("AsyncChannel: Got file from generator");
					data = ioService.newFileURI(data);
				}
				else {
					Zotero.debug("AsyncChannel: Got URI from generator");
				}
				
				let uri = data;
				uri.QueryInterface(Ci.nsIURL);
				this.contentType = Zotero.MIME.getMIMETypeFromExtension(uri.fileExtension);
				
				Components.utils.import("resource://gre/modules/NetUtil.jsm");
				NetUtil.asyncFetch(data, function (inputStream, status) {
					if (!Components.isSuccessCode(status)) {
						reject();
						return;
					}
					
					listenerWrapper.onStartRequest(channel, context);
					try {
						listenerWrapper.onDataAvailable(channel, context, inputStream, 0, inputStream.available());
					}
					catch (e) {
						reject(e);
					}
					listenerWrapper.onStopRequest(channel, context, status);
				});
				return promise;
			}
			else if (data === undefined) {
				this.cancel(0x804b0002); // BINDING_ABORTED
			}
			else {
				throw new Error("Invalid return type (" + typeof data + ") from generator passed to AsyncChannel");
			}
		}.bind(this))
		.then(function () {
			if (this._isPending) {
				Zotero.debug("AsyncChannel request succeeded in " + (new Date - t) + " ms");
				channel._isPending = false;
			}
		})
		.catch(function (e) {
			Zotero.debug(e, 1);
			if (channel._isPending) {
				streamListener.onStopRequest(channel, context, Components.results.NS_ERROR_FAILURE);
				channel._isPending = false;
			}
			throw e;
		})
		.finally(function () {
			if (channel.loadGroup) channel.loadGroup.removeRequest(channel, null, 0);
		});
	},
	
	// nsIRequest
	isPending: function () {
		return this._isPending;
	},
	
	cancel: function (status) {
		Zotero.debug("Cancelling");
		this.status = status;
		this._isPending = false;
	},
	
	resume: function () {
		Zotero.debug("Resuming");
	},
	
	suspend: function () {
		Zotero.debug("Suspending");
	},
	
	// nsIWritablePropertyBag
	setProperty: function (prop, val) {
		this[prop] = val;
	},
	
	
	deleteProperty: function (prop) {
		delete this[prop];
	},
	
	
	QueryInterface: function (iid) {
		if (iid.equals(Components.interfaces.nsISupports)
				|| iid.equals(Components.interfaces.nsIRequest)
				|| iid.equals(Components.interfaces.nsIChannel)
				// pdf.js wants this
				|| iid.equals(Components.interfaces.nsIWritablePropertyBag)) {
			return this;
		}
		throw Components.results.NS_ERROR_NO_INTERFACE;
	}
};


var NSGetFactory = XPCOMUtils.generateNSGetFactory([ZoteroProtocolHandler]);
