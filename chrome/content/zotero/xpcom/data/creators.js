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
    
    ***** END LICENSE BLOCK *****
*/


Zotero.Creators = new function() {
	this.fields = ['firstName', 'lastName', 'fieldMode'];
	this.totes = 0;
	
	var _cache = {};
	
	this.init = Zotero.Promise.coroutine(function* () {
		var sql = "SELECT * FROM creators";
		var rows = yield Zotero.DB.queryAsync(sql);
		for (let i = 0; i < rows.length; i++) {
			let row = rows[i];
			_cache[row.creatorID] = this.cleanData({
				// Avoid "DB column 'name' not found" warnings from the DB row Proxy
				firstName: row.firstName,
				lastName: row.lastName,
				fieldMode: row.fieldMode
			});
		}
	});
	
	/*
	 * Returns creator data in internal format for a given creatorID
	 */
	this.get = function (creatorID) {
		if (!creatorID) {
			throw new Error("creatorID not provided");
		}
		
		if (!_cache[creatorID]) {
			throw new Error("Creator " + creatorID + " not found");
		}
		
		// Return copy of data
		return this.cleanData(_cache[creatorID]);
	};
	
	
	this.getItemsWithCreator = function (creatorID) {
		var sql = "SELECT DISTINCT itemID FROM itemCreators AS IC,itemCreatorsAlt AS ICA WHERE IC.creatorID=? OR ICA.creatorID=?";
		return Zotero.DB.columnQueryAsync(sql, creatorID, creatorID);
	}
	
	
	this.countItemAssociations = function (creatorID) {
		var sql = "SELECT COUNT(*) FROM itemCreators AS IC,itemCreatorsAlt AS ICA WHERE IC.creatorID=? OR ICA.creatorID=?";
		return Zotero.DB.valueQueryAsync(sql, creatorID, creatorID);
	}
	
	
	/**
	 * Returns the creatorID matching given fields, or creates a new creator and returns its id
	 *
	 * @requireTransaction
	 * @param {Object} data  Creator data in API JSON format
	 * @param {Boolean} [create=false]  If no matching creator, create one
	 * @return {Promise<Integer>}  creatorID
	 */
	this.getIDFromData = Zotero.Promise.coroutine(function* (data, create) {
		Zotero.DB.requireTransaction();
		data = this.cleanData(data);
		var sql = "SELECT creatorID FROM creators WHERE "
			+ "firstName=? AND lastName=? AND fieldMode=?";
		var id = yield Zotero.DB.valueQueryAsync(
			sql, [data.firstName, data.lastName, data.fieldMode]
		);
		if (!id && create) {
			id = Zotero.ID.get('creators');
			let sql = "INSERT INTO creators (creatorID, firstName, lastName, fieldMode) "
				+ "VALUES (?, ?, ?, ?)";
			yield Zotero.DB.queryAsync(
				sql, [id, data.firstName, data.lastName, data.fieldMode]
			);
			_cache[id] = data;
		}
		return id;
	});
	
	
	this.updateCreator = Zotero.Promise.coroutine(function* (creatorID, creatorData) {
		var creator = yield this.get(creatorID);
		if (!creator) {
			throw new Error("Creator " + creatorID + " doesn't exist");
		}
		creator.fieldMode = creatorData.fieldMode;
		creator.firstName = creatorData.firstName;
		creator.lastName = creatorData.lastName;
		return creator.save();
	});
	
	
	/**
	 * Delete obsolete creator rows from database and clear internal cache entries
	 *
	 * @return {Promise}
	 */
	this.purge = Zotero.Promise.coroutine(function* () {
		if (!Zotero.Prefs.get('purge.creators')) {
			return;
		}
		
		Zotero.debug("Purging creator tables");
		
		var sql = 'SELECT creatorID FROM creators WHERE creatorID NOT IN '
			+ '(SELECT creatorID FROM itemCreators) AND creatorID NOT IN '
			+ '(SELECT creatorID FROM itemCreatorsAlt)';
		var toDelete = yield Zotero.DB.columnQueryAsync(sql);
		if (toDelete.length) {
			// Clear creator entries in internal array
			for (let i=0; i<toDelete.length; i++) {
				delete _cache[toDelete[i]];
			}
			
			var sql = "DELETE FROM creators WHERE creatorID NOT IN "
				+ "(SELECT creatorID FROM itemCreators) AND creatorID NOT IN "
				+ "(SELECT creatorID FROM itemCreatorsAlt)";
			yield Zotero.DB.queryAsync(sql);
			
			// Purge unused itemCreatorMain rows
			var sql = 'DELETE FROM itemCreatorsMain WHERE creatorID NOT IN '
				+ '(SELECT creatorID FROM creators)';
			yield Zotero.DB.queryAsync(sql);
		}
		
		Zotero.Prefs.set('purge.creators', false);
	});
	
	
	this.equals = function (data1, data2) {
		data1 = this.cleanData(data1);
		data2 = this.cleanData(data2);
		//return data1.lastName === data2.lastName
		//	&& data1.firstName === data2.firstName
		//	&& data1.fieldMode === data2.fieldMode
		//	&& data1.creatorTypeID === data2.creatorTypeID;
		return Zotero.DataObjectUtilities.equals(data1, data2);
	},
	
<<<<<<< HEAD
	this.cleanData = function (data, includeDependents) {
		var me = this;
		function _cleanData(data) {
			// Validate data
			if (data.name === undefined && data.lastName === undefined) {
				throw new Error("Creator data must contain either 'name' or 'firstName'/'lastName' properties");
			}
			if (data.name !== undefined && (data.firstName !== undefined || data.lastName !== undefined)) {
				throw new Error("Creator data cannot contain both 'name' and 'firstName'/'lastName' properties");
			}
			if (data.name !== undefined && data.fieldMode === 0) {
				throw new Error("'fieldMode' cannot be 0 with 'name' property");
			}
			if (data.fieldMode === 1
				&& !(data.firstName === undefined || data.firstName === "" || data.firstName === null)) {
				throw new Error("'fieldMode' cannot be 1 with 'firstName' property");
			}
			if (data.name !== undefined && typeof data.name != 'string') {
				throw new Error("'name' must be a string");
			}
			if (data.firstName !== undefined && data.firstName !== null && typeof data.firstName != 'string') {
				throw new Error("'firstName' must be a string");
			}
			if (data.lastName !== undefined && typeof data.lastName != 'string') {
				throw new Error("'lastName' must be a string");
			}
			
			var cleanedData = {
				fieldMode: 0,
				firstName: '',
				lastName: ''
			};
			for (let i=0; i<me.fields.length; i++) {
				let field = me.fields[i];
				let val = data[field];
				switch (field) {
				case 'firstName':
				case 'lastName':
					if (val === undefined || val === null) continue;
					cleanedData[field] = val.trim().normalize();
					break;
					
				case 'fieldMode':
					cleanedData[field] = val ? parseInt(val) : 0;
					break;
				}
			}
			
			// Handle API JSON .name
			if (data.name !== undefined) {
				cleanedData.lastName = data.name.trim().normalize();
				cleanedData.fieldMode = 1;
			}
			
			var creatorType = data.creatorType || data.creatorTypeID;
			if (creatorType) {
				cleanedData.creatorTypeID = Zotero.CreatorTypes.getID(creatorType);
				if (!cleanedData.creatorTypeID) {
					let msg = "'" + creatorType + "' isn't a valid creator type";
					Zotero.debug(msg, 2);
					Components.utils.reportError(msg);
				}
			}
			
			return cleanedData;
		}
		var cleanedData = _cleanData(data);
		if (data.multi && includeDependents) {
			cleanedData.multi = {
				_key: {}
			}
			if (data.multi.main) {
				cleanedData.multi.main = data.multi.main;
			}
			for (let lang in data.multi._key) {
				cleanedData.multi._key[lang] = _cleanData(data.multi._key[lang]);
			}
		}
		return cleanedData;
	}
	
	
	this.internalToJSON = function (fields) {
		function _internalToJSON(fields, masterCreator) {
			var obj = {};
			if (fields.fieldMode == 1) {
				obj.name = fields.lastName;
			}
			else {
				obj.firstName = fields.firstName;
				obj.lastName = fields.lastName;
			}
			if (masterCreator) {
				obj.creatorType = Zotero.CreatorTypes.getName(fields.creatorTypeID);
				obj.multi = {
					_key: {}
				}
				if (fields.multi.main) {
					obj.multi.main = fields.multi.main;
				}
			}
			return obj;
		}
		var obj = _internalToJSON(fields, true);
		for (let lang in fields.multi._key) {
			obj.multi._key[lang] = _internalToJSON(fields.multi._key[lang]);
		}
		return obj;
	}
}
