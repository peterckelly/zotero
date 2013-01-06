-- 31

-- Copyright (c) 2009 Center for History and New Media
--                    George Mason University, Fairfax, Virginia, USA
--                    http://zotero.org
--
-- This file is part of Zotero.
-- 
-- Zotero is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- Zotero is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License
-- along with Zotero.  If not, see <http://www.gnu.org/licenses/>.


-- This file creates system tables that can be safely wiped and reinitialized
-- at any time, as long as existing ids are preserved.


-- Valid item types ("book," "journalArticle," etc.)
DROP TABLE IF EXISTS itemTypes;
CREATE TABLE itemTypes (
    itemTypeID INTEGER PRIMARY KEY,
    typeName TEXT,
    templateItemTypeID INT,
    display INT DEFAULT 1 -- 0 == hide, 1 == display, 2 == primary
);

-- Populated at startup from itemTypes and customItemTypes
DROP TABLE IF EXISTS itemTypesCombined;
CREATE TABLE itemTypesCombined (
    itemTypeID INT NOT NULL,
    typeName TEXT NOT NULL,
    display INT DEFAULT 1 NOT NULL,
    custom INT NOT NULL,
    PRIMARY KEY (itemTypeID)
);

-- Describes various types of fields and their format restrictions,
-- and indicates whether data should be stored as strings or integers
--
-- unused
DROP TABLE IF EXISTS fieldFormats;
CREATE TABLE fieldFormats (
    fieldFormatID INTEGER PRIMARY KEY,
    regex TEXT,
    isInteger INT
);

-- Field types for item metadata
DROP TABLE IF EXISTS fields;
CREATE TABLE fields (
    fieldID INTEGER PRIMARY KEY,
    fieldName TEXT,
    fieldFormatID INT,
    FOREIGN KEY (fieldFormatID) REFERENCES fieldFormats(fieldFormatID)
);

-- Populated at startup from fields and customFields
DROP TABLE IF EXISTS fieldsCombined;
CREATE TABLE fieldsCombined (
    fieldID INT NOT NULL,
    fieldName TEXT NOT NULL,
    label TEXT,
    fieldFormatID INT,
    custom INT NOT NULL,
    PRIMARY KEY (fieldID)
);

-- Defines valid fields for each itemType, their display order, and their default visibility
DROP TABLE IF EXISTS itemTypeFields;
CREATE TABLE itemTypeFields (
    itemTypeID INT,
    fieldID INT,
    hide INT,
    orderIndex INT,
    PRIMARY KEY (itemTypeID, orderIndex),
    UNIQUE (itemTypeID, fieldID),
    FOREIGN KEY (itemTypeID) REFERENCES itemTypes(itemTypeID),
    FOREIGN KEY (fieldID) REFERENCES fields(fieldID)
);
CREATE INDEX itemTypeFields_fieldID ON itemTypeFields(fieldID);

-- Populated at startup from itemTypeFields and customItemTypeFields
DROP TABLE IF EXISTS itemTypeFieldsCombined;
CREATE TABLE itemTypeFieldsCombined (
    itemTypeID INT NOT NULL,
    fieldID INT NOT NULL,
    hide INT,
    orderIndex INT NOT NULL,
    PRIMARY KEY (itemTypeID, orderIndex),
    UNIQUE (itemTypeID, fieldID)
);
CREATE INDEX itemTypeFieldsCombined_fieldID ON itemTypeFieldsCombined(fieldID);

-- Maps base fields to type-specific fields (e.g. publisher to label in audioRecording)
DROP TABLE IF EXISTS baseFieldMappings;
CREATE TABLE baseFieldMappings (
    itemTypeID INT,
    baseFieldID INT,
    fieldID INT,
    PRIMARY KEY (itemTypeID, baseFieldID, fieldID),
    FOREIGN KEY (itemTypeID) REFERENCES itemTypes(itemTypeID),
    FOREIGN KEY (baseFieldID) REFERENCES fields(fieldID),
    FOREIGN KEY (fieldID) REFERENCES fields(fieldID)
);
CREATE INDEX baseFieldMappings_baseFieldID ON baseFieldMappings(baseFieldID);
CREATE INDEX baseFieldMappings_fieldID ON baseFieldMappings(fieldID);

-- Populated at startup from baseFieldMappings and customBaseFieldMappings
DROP TABLE IF EXISTS baseFieldMappingsCombined;
CREATE TABLE baseFieldMappingsCombined (
    itemTypeID INT,
    baseFieldID INT,
    fieldID INT,
    PRIMARY KEY (itemTypeID, baseFieldID, fieldID)
);
CREATE INDEX baseFieldMappingsCombined_baseFieldID ON baseFieldMappingsCombined(baseFieldID);
CREATE INDEX baseFieldMappingsCombined_fieldID ON baseFieldMappingsCombined(fieldID);

DROP TABLE IF EXISTS charsets;
CREATE TABLE charsets (
    charsetID INTEGER PRIMARY KEY,
    charset TEXT UNIQUE
);
CREATE INDEX charsets_charset ON charsets(charset);

DROP TABLE IF EXISTS fileTypes;
CREATE TABLE fileTypes (
    fileTypeID INTEGER PRIMARY KEY,
    fileType TEXT UNIQUE
);
CREATE INDEX fileTypes_fileType ON fileTypes(fileType);

DROP TABLE IF EXISTS fileTypeMimeTypes;
CREATE TABLE fileTypeMimeTypes (
    fileTypeID INT,
    mimeType TEXT,
    PRIMARY KEY (fileTypeID, mimeType),
    FOREIGN KEY (fileTypeID) REFERENCES fileTypes(fileTypeID)
);
CREATE INDEX fileTypeMimeTypes_mimeType ON fileTypeMimeTypes(mimeType);

-- Defines the possible creator types (contributor, editor, author)
DROP TABLE IF EXISTS creatorTypes;
CREATE TABLE creatorTypes (
    creatorTypeID INTEGER PRIMARY KEY,
    creatorType TEXT
);
    
DROP TABLE IF EXISTS itemTypeCreatorTypes;
CREATE TABLE itemTypeCreatorTypes (
    itemTypeID INT,
    creatorTypeID INT,
    primaryField INT,
    PRIMARY KEY (itemTypeID, creatorTypeID),
    FOREIGN KEY (itemTypeID) REFERENCES itemTypes(itemTypeID),
    FOREIGN KEY (creatorTypeID) REFERENCES creatorTypes(creatorTypeID)
);
CREATE INDEX itemTypeCreatorTypes_creatorTypeID ON itemTypeCreatorTypes(creatorTypeID);

DROP TABLE IF EXISTS syncObjectTypes;
CREATE TABLE syncObjectTypes (
    syncObjectTypeID INTEGER PRIMARY KEY,
    name TEXT
);
CREATE INDEX syncObjectTypes_name ON syncObjectTypes(name);

DROP TABLE IF EXISTS transactionSets;
CREATE TABLE transactionSets (
    transactionSetID INTEGER PRIMARY KEY,
    event TEXT,
    id INT
);

DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
    transactionID INTEGER PRIMARY KEY,
    transactionSetID INT,
    context TEXT,
    action TEXT
);
CREATE INDEX transactions_transactionSetID ON transactions(transactionSetID);

DROP TABLE IF EXISTS transactionLog;
CREATE TABLE transactionLog (
    transactionID INT,
    field TEXT,
    value NONE,
    PRIMARY KEY (transactionID, field, value),
    FOREIGN KEY (transactionID) REFERENCES transactions(transactionID)
);

-- unused
INSERT INTO "fieldFormats" VALUES(1, '.*', 0);
INSERT INTO "fieldFormats" VALUES(2, '[0-9]*', 1);
INSERT INTO "fieldFormats" VALUES(3, '[0-9]{4}', 1);

INSERT INTO itemTypes VALUES (1,'note',NULL,0);
INSERT INTO itemTypes VALUES (2,'book',NULL,2);
INSERT INTO itemTypes VALUES (3,'bookSection',2,2);
INSERT INTO itemTypes VALUES (4,'journalArticle',NULL,2);
INSERT INTO itemTypes VALUES (5,'magazineArticle',NULL,2);
INSERT INTO itemTypes VALUES (6,'newspaperArticle',NULL,2);
INSERT INTO itemTypes VALUES (7,'thesis',NULL,1);
INSERT INTO itemTypes VALUES (8,'letter',NULL,1);
INSERT INTO itemTypes VALUES (9,'manuscript',NULL,1);
INSERT INTO itemTypes VALUES (10,'interview',NULL,1);
INSERT INTO itemTypes VALUES (11,'film',NULL,1);
INSERT INTO itemTypes VALUES (12,'artwork',NULL,1);
INSERT INTO itemTypes VALUES (13,'webpage',NULL,0);
INSERT INTO itemTypes VALUES (14,'attachment',NULL,0);
INSERT INTO itemTypes VALUES (15,'report',NULL,1);
INSERT INTO itemTypes VALUES (16,'bill',NULL,1);
INSERT INTO itemTypes VALUES (17,'case',NULL,1);
INSERT INTO itemTypes VALUES (18,'hearing',NULL,1);
INSERT INTO itemTypes VALUES (19,'patent',NULL,1);
INSERT INTO itemTypes VALUES (20,'statute',NULL,1);
INSERT INTO itemTypes VALUES (21,'email',NULL,1);
INSERT INTO itemTypes VALUES (22,'map',NULL,1);
INSERT INTO itemTypes VALUES (23,'blogPost',NULL,1);
INSERT INTO itemTypes VALUES (24,'instantMessage',NULL,1);
INSERT INTO itemTypes VALUES (25,'forumPost',NULL,1);
INSERT INTO itemTypes VALUES (26,'audioRecording',NULL,1);
INSERT INTO itemTypes VALUES (27,'presentation',NULL,1);
INSERT INTO itemTypes VALUES (28,'videoRecording',NULL,1);
INSERT INTO itemTypes VALUES (29,'tvBroadcast',NULL,1);
INSERT INTO itemTypes VALUES (30,'radioBroadcast',NULL,1);
INSERT INTO itemTypes VALUES (31,'podcast',NULL,1);
INSERT INTO itemTypes VALUES (32,'computerProgram',NULL,1);
INSERT INTO itemTypes VALUES (33,'conferencePaper',NULL,1);
INSERT INTO itemTypes VALUES (34,'document',NULL,2);
INSERT INTO itemTypes VALUES (35,'encyclopediaArticle',NULL,1);
INSERT INTO itemTypes VALUES (36,'dictionaryEntry',NULL,1);
INSERT INTO itemTypes VALUES (1261,'gazette',NULL,1);
INSERT INTO itemTypes VALUES (1262,'treaty',NULL,1);
INSERT INTO itemTypes VALUES (1263,'regulation',NULL,1);
INSERT INTO itemTypes VALUES (1264,'classic',NULL,1);
INSERT INTO itemTypes VALUES (1265,'periodical',NULL,1);

INSERT INTO fields VALUES (1,'url',NULL);
INSERT INTO fields VALUES (2,'rights',NULL);
INSERT INTO fields VALUES (3,'series',NULL);
INSERT INTO fields VALUES (4,'volume',NULL);
INSERT INTO fields VALUES (5,'issue',NULL);
INSERT INTO fields VALUES (6,'edition',NULL);
INSERT INTO fields VALUES (7,'place',NULL);
INSERT INTO fields VALUES (8,'publisher',NULL);
INSERT INTO fields VALUES (10,'pages',NULL);
INSERT INTO fields VALUES (11,'ISBN',NULL);
INSERT INTO fields VALUES (12,'publicationTitle',NULL);
INSERT INTO fields VALUES (13,'ISSN',NULL);
INSERT INTO fields VALUES (14,'date',NULL);
INSERT INTO fields VALUES (15,'section',NULL);
INSERT INTO fields VALUES (18,'callNumber',NULL);
INSERT INTO fields VALUES (19,'archiveLocation',NULL);
INSERT INTO fields VALUES (21,'distributor',NULL);
INSERT INTO fields VALUES (22,'extra',NULL);
INSERT INTO fields VALUES (25,'journalAbbreviation',NULL);
INSERT INTO fields VALUES (26,'DOI',NULL);
INSERT INTO fields VALUES (27,'accessDate',NULL);
INSERT INTO fields VALUES (28,'seriesTitle',NULL);
INSERT INTO fields VALUES (29,'seriesText',NULL);
INSERT INTO fields VALUES (30,'seriesNumber',NULL);
INSERT INTO fields VALUES (31,'institution',NULL);
INSERT INTO fields VALUES (32,'reportType',NULL);
INSERT INTO fields VALUES (36,'code',NULL);
INSERT INTO fields VALUES (40,'session',NULL);
INSERT INTO fields VALUES (41,'legislativeBody',NULL);
INSERT INTO fields VALUES (42,'history',NULL);
INSERT INTO fields VALUES (43,'reporter',NULL);
INSERT INTO fields VALUES (44,'court',NULL);
INSERT INTO fields VALUES (45,'numberOfVolumes',NULL);
INSERT INTO fields VALUES (46,'committee',NULL);
INSERT INTO fields VALUES (48,'assignee',NULL);
INSERT INTO fields VALUES (50,'patentNumber',NULL);
INSERT INTO fields VALUES (51,'priorityNumbers',NULL);
INSERT INTO fields VALUES (52,'issueDate',NULL);
INSERT INTO fields VALUES (53,'references',NULL);
INSERT INTO fields VALUES (54,'legalStatus',NULL);
INSERT INTO fields VALUES (55,'codeNumber',NULL);
INSERT INTO fields VALUES (59,'artworkMedium',NULL);
INSERT INTO fields VALUES (60,'number',NULL);
INSERT INTO fields VALUES (61,'artworkSize',NULL);
INSERT INTO fields VALUES (62,'libraryCatalog',NULL);
INSERT INTO fields VALUES (63,'videoRecordingFormat',NULL);
INSERT INTO fields VALUES (64,'interviewMedium',NULL);
INSERT INTO fields VALUES (65,'letterType',NULL);
INSERT INTO fields VALUES (66,'manuscriptType',NULL);
INSERT INTO fields VALUES (67,'mapType',NULL);
INSERT INTO fields VALUES (68,'scale',NULL);
INSERT INTO fields VALUES (69,'thesisType',NULL);
INSERT INTO fields VALUES (70,'websiteType',NULL);
INSERT INTO fields VALUES (71,'audioRecordingFormat',NULL);
INSERT INTO fields VALUES (72,'label',NULL);
INSERT INTO fields VALUES (74,'presentationType',NULL);
INSERT INTO fields VALUES (75,'meetingName',NULL);
INSERT INTO fields VALUES (76,'studio',NULL);
INSERT INTO fields VALUES (77,'runningTime',NULL);
INSERT INTO fields VALUES (78,'network',NULL);
INSERT INTO fields VALUES (79,'postType',NULL);
INSERT INTO fields VALUES (80,'audioFileType',NULL);
INSERT INTO fields VALUES (81,'version',NULL);
INSERT INTO fields VALUES (82,'system',NULL);
INSERT INTO fields VALUES (83,'company',NULL);
INSERT INTO fields VALUES (84,'conferenceName',NULL);
INSERT INTO fields VALUES (85,'encyclopediaTitle',NULL);
INSERT INTO fields VALUES (86,'dictionaryTitle',NULL);
INSERT INTO fields VALUES (87,'language',NULL);
INSERT INTO fields VALUES (88,'programmingLanguage',NULL);
INSERT INTO fields VALUES (89,'university',NULL);
INSERT INTO fields VALUES (90,'abstractNote',NULL);
INSERT INTO fields VALUES (91,'websiteTitle',NULL);
INSERT INTO fields VALUES (92,'reportNumber',NULL);
INSERT INTO fields VALUES (93,'billNumber',NULL);
INSERT INTO fields VALUES (94,'codeVolume',NULL);
INSERT INTO fields VALUES (95,'codePages',NULL);
INSERT INTO fields VALUES (96,'dateDecided',NULL);
INSERT INTO fields VALUES (97,'reporterVolume',NULL);
INSERT INTO fields VALUES (98,'firstPage',NULL);
INSERT INTO fields VALUES (99,'documentNumber',NULL);
INSERT INTO fields VALUES (100,'dateEnacted',NULL);
INSERT INTO fields VALUES (101,'publicLawNumber',NULL);
INSERT INTO fields VALUES (102,'country',NULL);
INSERT INTO fields VALUES (103,'applicationNumber',NULL);
INSERT INTO fields VALUES (104,'forumTitle',NULL);
INSERT INTO fields VALUES (105,'episodeNumber',NULL);
INSERT INTO fields VALUES (107,'blogTitle',NULL);
INSERT INTO fields VALUES (108,'type',NULL);
INSERT INTO fields VALUES (109,'medium',NULL);
INSERT INTO fields VALUES (110,'title',NULL);
INSERT INTO fields VALUES (111,'caseName',NULL);
INSERT INTO fields VALUES (112,'nameOfAct',NULL);
INSERT INTO fields VALUES (113,'subject',NULL);
INSERT INTO fields VALUES (114,'proceedingsTitle',NULL);
INSERT INTO fields VALUES (115,'bookTitle',NULL);
INSERT INTO fields VALUES (116,'shortTitle',NULL);
INSERT INTO fields VALUES (117,'docketNumber',NULL);
INSERT INTO fields VALUES (118,'numPages',NULL);
INSERT INTO fields VALUES (119,'programTitle',NULL);
INSERT INTO fields VALUES (120,'issuingAuthority',NULL);
INSERT INTO fields VALUES (121,'filingDate',NULL);
INSERT INTO fields VALUES (122,'genre',NULL);
INSERT INTO fields VALUES (123,'archive',NULL);
INSERT INTO fields VALUES (1261,'jurisdiction',NULL);
INSERT INTO fields VALUES (1262,'assemblyNumber',NULL);
INSERT INTO fields VALUES (1263,'resolutionLabel',NULL);
INSERT INTO fields VALUES (1264,'sessionType',NULL);
INSERT INTO fields VALUES (1265,'newsCaseDate',NULL);
INSERT INTO fields VALUES (1266,'priorityDate',NULL);
INSERT INTO fields VALUES (1267,'yearAsVolume',NULL);
INSERT INTO fields VALUES (1268,'publicationDate',NULL);
INSERT INTO fields VALUES (1269,'reign',NULL);
INSERT INTO fields VALUES (1270,'regnalYear',NULL);
INSERT INTO fields VALUES (1271,'supplementName',NULL);
INSERT INTO fields VALUES (1272,'originalDate',NULL);
INSERT INTO fields VALUES (1273,'album',NULL);
INSERT INTO fields VALUES (1274,'opus',NULL);
INSERT INTO fields VALUES (1275,'meetingNumber',NULL);
INSERT INTO fields VALUES (1276,'committeeFullname',NULL);
INSERT INTO fields VALUES (1277,'signingDate',NULL);
INSERT INTO fields VALUES (1278,'openingDate',NULL);
INSERT INTO fields VALUES (1279,'adoptionDate',NULL);

-- book
INSERT INTO itemTypeFields VALUES (2, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (2, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (2, 3, NULL, 3);
INSERT INTO itemTypeFields VALUES (2, 30, NULL, 4);
INSERT INTO itemTypeFields VALUES (2, 4, NULL, 5);
INSERT INTO itemTypeFields VALUES (2, 45, NULL, 6);
INSERT INTO itemTypeFields VALUES (2, 6, NULL, 7);
INSERT INTO itemTypeFields VALUES (2, 7, NULL, 8);
INSERT INTO itemTypeFields VALUES (2, 8, NULL, 9);
INSERT INTO itemTypeFields VALUES (2, 14, NULL, 10);
INSERT INTO itemTypeFields VALUES (2, 118, NULL, 11);
INSERT INTO itemTypeFields VALUES (2, 87, NULL, 12);
INSERT INTO itemTypeFields VALUES (2, 11, NULL, 13);
INSERT INTO itemTypeFields VALUES (2, 116, NULL, 14);
INSERT INTO itemTypeFields VALUES (2, 1, NULL, 15);
INSERT INTO itemTypeFields VALUES (2, 27, NULL, 16);
INSERT INTO itemTypeFields VALUES (2, 123, NULL, 17);
INSERT INTO itemTypeFields VALUES (2, 19, NULL, 18);
INSERT INTO itemTypeFields VALUES (2, 62, NULL, 19);
INSERT INTO itemTypeFields VALUES (2, 18, NULL, 20);
INSERT INTO itemTypeFields VALUES (2, 2, NULL, 21);
INSERT INTO itemTypeFields VALUES (2, 22, NULL, 22);

INSERT INTO itemTypeFields VALUES (3, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (3, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (3, 115, NULL, 3);
INSERT INTO itemTypeFields VALUES (3, 3, NULL, 4);
INSERT INTO itemTypeFields VALUES (3, 30, NULL, 5);
INSERT INTO itemTypeFields VALUES (3, 4, NULL, 6);
INSERT INTO itemTypeFields VALUES (3, 45, NULL, 7);
INSERT INTO itemTypeFields VALUES (3, 6, NULL, 8);
INSERT INTO itemTypeFields VALUES (3, 7, NULL, 9);
INSERT INTO itemTypeFields VALUES (3, 8, NULL, 10);
INSERT INTO itemTypeFields VALUES (3, 14, NULL, 11);
INSERT INTO itemTypeFields VALUES (3, 10, NULL, 12);
INSERT INTO itemTypeFields VALUES (3, 87, NULL, 13);
INSERT INTO itemTypeFields VALUES (3, 11, NULL, 14);
INSERT INTO itemTypeFields VALUES (3, 116, NULL, 15);
INSERT INTO itemTypeFields VALUES (3, 1, NULL, 16);
INSERT INTO itemTypeFields VALUES (3, 27, NULL, 17);
INSERT INTO itemTypeFields VALUES (3, 123, NULL, 18);
INSERT INTO itemTypeFields VALUES (3, 19, NULL, 19);
INSERT INTO itemTypeFields VALUES (3, 62, NULL, 20);
INSERT INTO itemTypeFields VALUES (3, 18, NULL, 21);
INSERT INTO itemTypeFields VALUES (3, 2, NULL, 22);
INSERT INTO itemTypeFields VALUES (3, 22, NULL, 23);

INSERT INTO itemTypeFields VALUES (4, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (4, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (4, 12, NULL, 3);
INSERT INTO itemTypeFields VALUES (4, 4, NULL, 4);
INSERT INTO itemTypeFields VALUES (4, 5, NULL, 5);
INSERT INTO itemTypeFields VALUES (4, 10, NULL, 6);
INSERT INTO itemTypeFields VALUES (4, 14, NULL, 7);
INSERT INTO itemTypeFields VALUES (4, 3, NULL, 8);
INSERT INTO itemTypeFields VALUES (4, 28, NULL, 9);
INSERT INTO itemTypeFields VALUES (4, 29, NULL, 10);
INSERT INTO itemTypeFields VALUES (4, 25, NULL, 11);
INSERT INTO itemTypeFields VALUES (4, 87, NULL, 12);
INSERT INTO itemTypeFields VALUES (4, 26, NULL, 13);
INSERT INTO itemTypeFields VALUES (4, 13, NULL, 14);
INSERT INTO itemTypeFields VALUES (4, 116, NULL, 15);
INSERT INTO itemTypeFields VALUES (4, 1, NULL, 16);
INSERT INTO itemTypeFields VALUES (4, 27, NULL, 17);
INSERT INTO itemTypeFields VALUES (4, 123, NULL, 18);
INSERT INTO itemTypeFields VALUES (4, 19, NULL, 19);
INSERT INTO itemTypeFields VALUES (4, 62, NULL, 20);
INSERT INTO itemTypeFields VALUES (4, 18, NULL, 21);
INSERT INTO itemTypeFields VALUES (4, 2, NULL, 22);
INSERT INTO itemTypeFields VALUES (4, 22, NULL, 23);

INSERT INTO itemTypeFields VALUES (5, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (5, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (5, 12, NULL, 3);
INSERT INTO itemTypeFields VALUES (5, 4, NULL, 4);
INSERT INTO itemTypeFields VALUES (5, 5, NULL, 5);
INSERT INTO itemTypeFields VALUES (5, 14, NULL, 6);
INSERT INTO itemTypeFields VALUES (5, 10, NULL, 7);
INSERT INTO itemTypeFields VALUES (5, 87, NULL, 8);
INSERT INTO itemTypeFields VALUES (5, 13, NULL, 9);
INSERT INTO itemTypeFields VALUES (5, 116, NULL, 10);
INSERT INTO itemTypeFields VALUES (5, 1, NULL, 11);
INSERT INTO itemTypeFields VALUES (5, 27, NULL, 12);
INSERT INTO itemTypeFields VALUES (5, 123, NULL, 13);
INSERT INTO itemTypeFields VALUES (5, 19, NULL, 14);
INSERT INTO itemTypeFields VALUES (5, 62, NULL, 15);
INSERT INTO itemTypeFields VALUES (5, 18, NULL, 16);
INSERT INTO itemTypeFields VALUES (5, 2, NULL, 17);
INSERT INTO itemTypeFields VALUES (5, 22, NULL, 18);

-- journalArticle
INSERT INTO itemTypeFields VALUES (6, 110, NULL, 1);   -- title
INSERT INTO itemTypeFields VALUES (6, 90, NULL, 2);    -- abstract
INSERT INTO itemTypeFields VALUES (6, 12, NULL, 3);    -- publicationTitle
INSERT INTO itemTypeFields VALUES (6, 14, NULL, 4);    -- date (-> issued)
INSERT INTO itemTypeFields VALUES (6, 7, NULL, 5);     -- place
INSERT INTO itemTypeFields VALUES (6, 6, NULL, 6);     -- issue
INSERT INTO itemTypeFields VALUES (6, 15, NULL, 7);    -- section
INSERT INTO itemTypeFields VALUES (6, 10, NULL, 8);    -- pages
INSERT INTO itemTypeFields VALUES (6, 87, NULL, 9);    -- language
INSERT INTO itemTypeFields VALUES (6, 116, NULL, 10);  -- shortTitle
INSERT INTO itemTypeFields VALUES (6, 1261, NULL, 11); -- jurisdiction
INSERT INTO itemTypeFields VALUES (6, 44, NULL, 12);   -- court
INSERT INTO itemTypeFields VALUES (6, 1265, NULL, 13); -- newsCaseDate (-> original-date)
INSERT INTO itemTypeFields VALUES (6, 13, NULL, 14);   -- ISSN
INSERT INTO itemTypeFields VALUES (6, 1, NULL, 15);    -- url
INSERT INTO itemTypeFields VALUES (6, 27, NULL, 16);   -- accessed
INSERT INTO itemTypeFields VALUES (6, 123, NULL, 17);  -- archive
INSERT INTO itemTypeFields VALUES (6, 19, NULL, 18);   -- archive location
INSERT INTO itemTypeFields VALUES (6, 62, NULL, 19);   -- library catalog
INSERT INTO itemTypeFields VALUES (6, 18, NULL, 20);   -- call number
INSERT INTO itemTypeFields VALUES (6, 2, NULL, 21);    -- rights
INSERT INTO itemTypeFields VALUES (6, 22, NULL, 22);   -- extra

INSERT INTO itemTypeFields VALUES (7, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (7, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (7, 69, NULL, 3);
INSERT INTO itemTypeFields VALUES (7, 89, NULL, 4);
INSERT INTO itemTypeFields VALUES (7, 7, NULL, 5);
INSERT INTO itemTypeFields VALUES (7, 14, NULL, 6);
INSERT INTO itemTypeFields VALUES (7, 118, NULL, 7);
INSERT INTO itemTypeFields VALUES (7, 87, NULL, 8);
INSERT INTO itemTypeFields VALUES (7, 116, NULL, 9);
INSERT INTO itemTypeFields VALUES (7, 1, NULL, 10);
INSERT INTO itemTypeFields VALUES (7, 27, NULL, 11);
INSERT INTO itemTypeFields VALUES (7, 123, NULL, 12);
INSERT INTO itemTypeFields VALUES (7, 19, NULL, 13);
INSERT INTO itemTypeFields VALUES (7, 62, NULL, 14);
INSERT INTO itemTypeFields VALUES (7, 18, NULL, 15);
INSERT INTO itemTypeFields VALUES (7, 2, NULL, 16);
INSERT INTO itemTypeFields VALUES (7, 22, NULL, 17);

-- letter
INSERT INTO itemTypeFields VALUES (8, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (8, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (8, 65, NULL, 3);
INSERT INTO itemTypeFields VALUES (8, 14, NULL, 4);
INSERT INTO itemTypeFields VALUES (8, 87, NULL, 5);
INSERT INTO itemTypeFields VALUES (8, 116, NULL, 6);
INSERT INTO itemTypeFields VALUES (8, 1, NULL, 7);
INSERT INTO itemTypeFields VALUES (8, 27, NULL, 8);
INSERT INTO itemTypeFields VALUES (8, 123, NULL, 9);
INSERT INTO itemTypeFields VALUES (8, 19, NULL, 10);
INSERT INTO itemTypeFields VALUES (8, 62, NULL, 11);
INSERT INTO itemTypeFields VALUES (8, 18, NULL, 12);
INSERT INTO itemTypeFields VALUES (8, 2, NULL, 13);
INSERT INTO itemTypeFields VALUES (8, 22, NULL, 14);


INSERT INTO itemTypeFields VALUES (9, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (9, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (9, 66, NULL, 3);
INSERT INTO itemTypeFields VALUES (9, 7, NULL, 4);
INSERT INTO itemTypeFields VALUES (9, 14, NULL, 5);
INSERT INTO itemTypeFields VALUES (9, 118, NULL, 6);
INSERT INTO itemTypeFields VALUES (9, 87, NULL, 7);
INSERT INTO itemTypeFields VALUES (9, 116, NULL, 8);
INSERT INTO itemTypeFields VALUES (9, 1, NULL, 9);
INSERT INTO itemTypeFields VALUES (9, 27, NULL, 10);
INSERT INTO itemTypeFields VALUES (9, 123, NULL, 11);
INSERT INTO itemTypeFields VALUES (9, 19, NULL, 12);
INSERT INTO itemTypeFields VALUES (9, 62, NULL, 13);
INSERT INTO itemTypeFields VALUES (9, 18, NULL, 14);
INSERT INTO itemTypeFields VALUES (9, 2, NULL, 15);
INSERT INTO itemTypeFields VALUES (9, 22, NULL, 16);

INSERT INTO itemTypeFields VALUES (10, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (10, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (10, 14, NULL, 3);
INSERT INTO itemTypeFields VALUES (10, 64, NULL, 4);
INSERT INTO itemTypeFields VALUES (10, 87, NULL, 5);
INSERT INTO itemTypeFields VALUES (10, 116, NULL, 6);
INSERT INTO itemTypeFields VALUES (10, 1, NULL, 7);
INSERT INTO itemTypeFields VALUES (10, 27, NULL, 8);
INSERT INTO itemTypeFields VALUES (10, 123, NULL, 9);
INSERT INTO itemTypeFields VALUES (10, 19, NULL, 10);
INSERT INTO itemTypeFields VALUES (10, 62, NULL, 11);
INSERT INTO itemTypeFields VALUES (10, 18, NULL, 12);
INSERT INTO itemTypeFields VALUES (10, 2, NULL, 13);
INSERT INTO itemTypeFields VALUES (10, 22, NULL, 14);

INSERT INTO itemTypeFields VALUES (11, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (11, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (11, 21, NULL, 3);
INSERT INTO itemTypeFields VALUES (11, 14, NULL, 4);
INSERT INTO itemTypeFields VALUES (11, 122, NULL, 5);
INSERT INTO itemTypeFields VALUES (11, 63, NULL, 6);
INSERT INTO itemTypeFields VALUES (11, 77, NULL, 7);
INSERT INTO itemTypeFields VALUES (11, 87, NULL, 8);
INSERT INTO itemTypeFields VALUES (11, 116, NULL, 9);
INSERT INTO itemTypeFields VALUES (11, 1, NULL, 10);
INSERT INTO itemTypeFields VALUES (11, 27, NULL, 11);
INSERT INTO itemTypeFields VALUES (11, 123, NULL, 12);
INSERT INTO itemTypeFields VALUES (11, 19, NULL, 13);
INSERT INTO itemTypeFields VALUES (11, 62, NULL, 14);
INSERT INTO itemTypeFields VALUES (11, 18, NULL, 15);
INSERT INTO itemTypeFields VALUES (11, 2, NULL, 16);
INSERT INTO itemTypeFields VALUES (11, 22, NULL, 17);

-- artwork
INSERT INTO itemTypeFields VALUES (12, 110, NULL, 1); -- title
INSERT INTO itemTypeFields VALUES (12, 90, NULL, 2);  -- abstract
INSERT INTO itemTypeFields VALUES (12, 59, NULL, 3);  -- artworkMedium
INSERT INTO itemTypeFields VALUES (12, 61, NULL, 4);  -- artworkSize
INSERT INTO itemTypeFields VALUES (12, 91, NULL, 5);  -- websiteTitle
INSERT INTO itemTypeFields VALUES (12, 14, NULL, 6);  -- date
INSERT INTO itemTypeFields VALUES (12, 87, NULL, 7);  -- language
INSERT INTO itemTypeFields VALUES (12, 116, NULL, 8); -- shortTitle
INSERT INTO itemTypeFields VALUES (12, 123, NULL, 9); -- archive
INSERT INTO itemTypeFields VALUES (12, 19, NULL, 10);  -- archiveLocation
INSERT INTO itemTypeFields VALUES (12, 62, NULL, 11); -- library catalog
INSERT INTO itemTypeFields VALUES (12, 18, NULL, 12); -- call number
INSERT INTO itemTypeFields VALUES (12, 1, NULL, 13);  -- url
INSERT INTO itemTypeFields VALUES (12, 27, NULL, 14); -- accessed
INSERT INTO itemTypeFields VALUES (12, 2, NULL, 15);  -- rights 
INSERT INTO itemTypeFields VALUES (12, 22, NULL, 16); -- extra

INSERT INTO itemTypeFields VALUES (13, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (13, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (13, 91, NULL, 3);
INSERT INTO itemTypeFields VALUES (13, 70, NULL, 4);
INSERT INTO itemTypeFields VALUES (13, 14, NULL, 5);
INSERT INTO itemTypeFields VALUES (13, 116, NULL, 6);
INSERT INTO itemTypeFields VALUES (13, 1, NULL, 7);
INSERT INTO itemTypeFields VALUES (13, 27, NULL, 8);
INSERT INTO itemTypeFields VALUES (13, 87, NULL, 9);
INSERT INTO itemTypeFields VALUES (13, 2, NULL, 10);
INSERT INTO itemTypeFields VALUES (13, 22, NULL, 11);
INSERT INTO itemTypeFields VALUES (14, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (14, 27, NULL, 2);
INSERT INTO itemTypeFields VALUES (14, 1, NULL, 3);

-- report
INSERT INTO itemTypeFields VALUES (15, 110, NULL, 1);   -- title
INSERT INTO itemTypeFields VALUES (15, 90, NULL, 2);    -- abstract
INSERT INTO itemTypeFields VALUES (15, 92, NULL, 3);    -- reportNumber
INSERT INTO itemTypeFields VALUES (15, 32, NULL, 4);    -- reportType
INSERT INTO itemTypeFields VALUES (15, 28, NULL, 5);    -- seriesTitle
INSERT INTO itemTypeFields VALUES (15, 7, NULL, 6);     -- edition
INSERT INTO itemTypeFields VALUES (15, 31, NULL, 7);    -- place
INSERT INTO itemTypeFields VALUES (15, 14, NULL, 8);    -- date
INSERT INTO itemTypeFields VALUES (15, 10, NULL, 9);    -- pages
INSERT INTO itemTypeFields VALUES (15, 87, NULL, 10);   -- language
INSERT INTO itemTypeFields VALUES (15, 116, NULL, 11);  -- shortTitle
INSERT INTO itemTypeFields VALUES (15, 1261, NULL, 12); -- jurisdiction
INSERT INTO itemTypeFields VALUES (15, 1, NULL, 13);    -- url
INSERT INTO itemTypeFields VALUES (15, 27, NULL, 14);   -- accessed
INSERT INTO itemTypeFields VALUES (15, 123, NULL, 15);  -- archive
INSERT INTO itemTypeFields VALUES (15, 19, NULL, 16);   -- archiveLocation
INSERT INTO itemTypeFields VALUES (15, 62, NULL, 17);   -- libraryCatalog
INSERT INTO itemTypeFields VALUES (15, 18, NULL, 18);   -- callNumber
INSERT INTO itemTypeFields VALUES (15, 2, NULL, 19);    -- rights
INSERT INTO itemTypeFields VALUES (15, 22, NULL, 20);   -- extra

-- bill
INSERT INTO itemTypeFields VALUES (16, 110, NULL, 1);  -- title
INSERT INTO itemTypeFields VALUES (16, 90, NULL, 2);   -- abstract
INSERT INTO itemTypeFields VALUES (16, 1261, NULL, 3); -- jurisdiction
INSERT INTO itemTypeFields VALUES (16, 116, NULL, 4);  -- short title
INSERT INTO itemTypeFields VALUES (16, 41, NULL, 5);   -- legislativeBody
INSERT INTO itemTypeFields VALUES (16, 1263, NULL, 6); -- resolution label
INSERT INTO itemTypeFields VALUES (16, 1262, NULL, 7); -- assembly number
INSERT INTO itemTypeFields VALUES (16, 1264, NULL, 8); -- session type
INSERT INTO itemTypeFields VALUES (16, 40, NULL, 9);   -- session
INSERT INTO itemTypeFields VALUES (16, 93, NULL, 10);  -- bill number
INSERT INTO itemTypeFields VALUES (16, 14, NULL, 11);  -- date
INSERT INTO itemTypeFields VALUES (16, 15, NULL, 12);  -- section
INSERT INTO itemTypeFields VALUES (16, 19, NULL, 13);  -- archive locator
INSERT INTO itemTypeFields VALUES (16, 43, NULL, 14);  -- reporter
INSERT INTO itemTypeFields VALUES (16, 87, NULL, 15);  -- language
INSERT INTO itemTypeFields VALUES (16, 1, NULL, 16);   -- url
INSERT INTO itemTypeFields VALUES (16, 27, NULL, 17);  -- access date
INSERT INTO itemTypeFields VALUES (16, 2, NULL, 18);   -- rights
INSERT INTO itemTypeFields VALUES (16, 22, NULL, 19);  -- extra

-- case
INSERT INTO itemTypeFields VALUES (17, 111, NULL, 1);   -- caseName
INSERT INTO itemTypeFields VALUES (17, 90, NULL, 2);    -- abstract
INSERT INTO itemTypeFields VALUES (17, 1261, NULL, 3);  -- jurisdiction
INSERT INTO itemTypeFields VALUES (17, 116, NULL, 4);   -- shortTitle
INSERT INTO itemTypeFields VALUES (17, 44, NULL, 5);    -- court
INSERT INTO itemTypeFields VALUES (17, 7, NULL, 6);     -- place
INSERT INTO itemTypeFields VALUES (17, 117, NULL, 7);   -- docketNumber
INSERT INTO itemTypeFields VALUES (17, 43, NULL, 8);    -- reporter
INSERT INTO itemTypeFields VALUES (17, 1267, NULL, 9);  -- yearAsVolume
INSERT INTO itemTypeFields VALUES (17, 97, NULL, 10);   -- reporterVolume
INSERT INTO itemTypeFields VALUES (17, 98, NULL, 11);   -- firstPage
INSERT INTO itemTypeFields VALUES (17, 96, NULL, 12);   -- dateDecided
INSERT INTO itemTypeFields VALUES (17, 8, NULL, 13);    -- publisher
INSERT INTO itemTypeFields VALUES (17, 1268, NULL, 14); -- publicationDate
INSERT INTO itemTypeFields VALUES (17, 1271, NULL, 15); -- supplementName
INSERT INTO itemTypeFields VALUES (17, 5, NULL, 16);    -- issue
INSERT INTO itemTypeFields VALUES (17, 123, NULL, 17);  -- archive
INSERT INTO itemTypeFields VALUES (17, 19, NULL, 18);   -- archiveLocation
INSERT INTO itemTypeFields VALUES (17, 87, NULL, 19);   -- language
INSERT INTO itemTypeFields VALUES (17, 1, NULL, 20);    -- url
INSERT INTO itemTypeFields VALUES (17, 27, NULL, 21);   -- accessed
INSERT INTO itemTypeFields VALUES (17, 42, NULL, 22);   -- history
INSERT INTO itemTypeFields VALUES (17, 2, NULL, 23);    -- rights
INSERT INTO itemTypeFields VALUES (17, 22, NULL, 24);   -- extra

-- hearing
INSERT INTO itemTypeFields VALUES (18, 110, NULL, 1);  -- title
INSERT INTO itemTypeFields VALUES (18, 90, NULL, 2);   -- abstract
INSERT INTO itemTypeFields VALUES (18, 1261, NULL, 3); -- jurisdiction      [ADDED]
INSERT INTO itemTypeFields VALUES (18, 116, NULL, 4);  -- shortTitle
INSERT INTO itemTypeFields VALUES (18, 1276, NULL, 5); -- committeeFullname [ADDED]
INSERT INTO itemTypeFields VALUES (18, 1275, NULL, 6); -- meetingNumber     [ADDED]
INSERT INTO itemTypeFields VALUES (18, 1263, NULL, 7); -- resolutionLabel   [ADDED]
INSERT INTO itemTypeFields VALUES (18, 1262, NULL, 8); -- assemblyNumber    [ADDED]
INSERT INTO itemTypeFields VALUES (18, 1264, NULL, 9); -- session type      [ADDED]
INSERT INTO itemTypeFields VALUES (18, 40, NULL, 10);  -- session
INSERT INTO itemTypeFields VALUES (18, 14, NULL, 11);  -- date
INSERT INTO itemTypeFields VALUES (18, 10, NULL, 12);  -- pages
INSERT INTO itemTypeFields VALUES (18, 19, NULL, 13);  -- archiveLocation
INSERT INTO itemTypeFields VALUES (18, 43, NULL, 14);  -- reporter
INSERT INTO itemTypeFields VALUES (18, 8, NULL, 15);   -- publisher
INSERT INTO itemTypeFields VALUES (18, 87, NULL, 16);  -- language
INSERT INTO itemTypeFields VALUES (18, 1, NULL, 17);   -- url
INSERT INTO itemTypeFields VALUES (18, 27, NULL, 18);  -- accessed
INSERT INTO itemTypeFields VALUES (18, 45, NULL, 19);  -- numberOfVolumes   Deprecated
INSERT INTO itemTypeFields VALUES (18, 42, NULL, 20);  -- history           Deprecated
INSERT INTO itemTypeFields VALUES (18, 7, NULL, 21);   -- place             Deprecated
INSERT INTO itemTypeFields VALUES (18, 41, NULL, 22);  -- legislativeBody   Deprecated
INSERT INTO itemTypeFields VALUES (18, 46, NULL, 23);  -- committee         Deprecated
INSERT INTO itemTypeFields VALUES (18, 99, NULL, 24);  -- documentNumber    Deprecated
INSERT INTO itemTypeFields VALUES (18, 2, NULL, 25);   -- rights
INSERT INTO itemTypeFields VALUES (18, 22, NULL, 26);  -- extra

-- patent
INSERT INTO itemTypeFields VALUES (19, 110, NULL, 1);   -- title
INSERT INTO itemTypeFields VALUES (19, 90, NULL, 2);    -- abstract
INSERT INTO itemTypeFields VALUES (19, 1261, NULL, 3);  -- Jurisdiction        [ADDED]
INSERT INTO itemTypeFields VALUES (19, 120, NULL, 18);  -- Issuing Authority
INSERT INTO itemTypeFields VALUES (19, 7, NULL, 16);    -- Place
INSERT INTO itemTypeFields VALUES (19, 50, NULL, 4);    -- Patent number
INSERT INTO itemTypeFields VALUES (19, 52, NULL, 5);    -- issueDate
INSERT INTO itemTypeFields VALUES (19, 103, NULL, 6);   -- Application Number
INSERT INTO itemTypeFields VALUES (19, 121, NULL, 7);   -- Filing Date                 (submitted)
INSERT INTO itemTypeFields VALUES (19, 51, NULL, 8);    -- Priority Numbers
INSERT INTO itemTypeFields VALUES (19, 1266, NULL, 9);  -- Priority Date       [ADDED] (original-date)
INSERT INTO itemTypeFields VALUES (19, 10, NULL, 10);   -- Pages
INSERT INTO itemTypeFields VALUES (19, 54, NULL, 20);   -- Legal Status
INSERT INTO itemTypeFields VALUES (19, 87, NULL, 11);   -- language
INSERT INTO itemTypeFields VALUES (19, 116, NULL, 12);  -- shortTitle
INSERT INTO itemTypeFields VALUES (19, 1, NULL, 13);    -- url
INSERT INTO itemTypeFields VALUES (19, 27, NULL, 14);   -- accessed
INSERT INTO itemTypeFields VALUES (19, 48, NULL, 15);   -- Assignee             Deprecated
INSERT INTO itemTypeFields VALUES (19, 102, NULL, 17);  -- Country              Deprecated
INSERT INTO itemTypeFields VALUES (19, 53, NULL, 19);   -- References           Deprecated
INSERT INTO itemTypeFields VALUES (19, 2, NULL, 21);    -- rights
INSERT INTO itemTypeFields VALUES (19, 22, NULL, 22);   -- extra



-- statute
INSERT INTO itemTypeFields VALUES (20, 112, NULL, 1);   -- nameOfAct
INSERT INTO itemTypeFields VALUES (20, 90, NULL, 2);    -- abstract
INSERT INTO itemTypeFields VALUES (20, 1261, NULL, 3);  -- jurisdiction     [ADDED]
INSERT INTO itemTypeFields VALUES (20, 116, NULL, 4);   -- shortTitle
INSERT INTO itemTypeFields VALUES (20, 36, NULL, 5);    -- code
INSERT INTO itemTypeFields VALUES (20, 55, NULL, 6);    -- codeNumber (volume)
INSERT INTO itemTypeFields VALUES (20, 10, NULL, 7);    -- pages
INSERT INTO itemTypeFields VALUES (20, 100, NULL, 8);   -- dateEnacted
INSERT INTO itemTypeFields VALUES (20, 15, NULL, 9);    -- section
INSERT INTO itemTypeFields VALUES (20, 1269, NULL, 10); -- reign            [ADDED]
INSERT INTO itemTypeFields VALUES (20, 1270, NULL, 11); -- regnalYear       [ADDED]
INSERT INTO itemTypeFields VALUES (20, 8, NULL, 12);    -- publisher        [ADDED]
INSERT INTO itemTypeFields VALUES (20, 1268, NULL, 13); -- publicationDate  [ADDED]
INSERT INTO itemTypeFields VALUES (20, 87, NULL, 14);   -- language
INSERT INTO itemTypeFields VALUES (20, 1, NULL, 15);    -- url
INSERT INTO itemTypeFields VALUES (20, 27, NULL, 16);   -- accessed
INSERT INTO itemTypeFields VALUES (20, 101, NULL, 17);  -- publicLawNumber  Deprecated
INSERT INTO itemTypeFields VALUES (20, 40, NULL, 18);   -- session          Deprecated
INSERT INTO itemTypeFields VALUES (20, 42, NULL, 19);   -- history          Deprecated
INSERT INTO itemTypeFields VALUES (20, 2, NULL, 20);    -- rights
INSERT INTO itemTypeFields VALUES (20, 22, NULL, 21);   -- extra

-- email
INSERT INTO itemTypeFields VALUES (21, 113, NULL, 1);  -- title
INSERT INTO itemTypeFields VALUES (21, 90, NULL, 2);   -- abstract
INSERT INTO itemTypeFields VALUES (21, 14, NULL, 3);   -- date
INSERT INTO itemTypeFields VALUES (21, 116, NULL, 4);  -- shortTitle
INSERT INTO itemTypeFields VALUES (21, 1, NULL, 5);    -- url
INSERT INTO itemTypeFields VALUES (21, 27, NULL, 6);   -- accessed
INSERT INTO itemTypeFields VALUES (21, 87, NULL, 7);   -- language
INSERT INTO itemTypeFields VALUES (21, 2, NULL, 8);    -- rights
INSERT INTO itemTypeFields VALUES (21, 22, NULL, 9);   -- extra

-- map
INSERT INTO itemTypeFields VALUES (22, 110, NULL, 1);   -- title
INSERT INTO itemTypeFields VALUES (22, 90, NULL, 2);    -- abstract
INSERT INTO itemTypeFields VALUES (22, 67, NULL, 3);    -- mapType
INSERT INTO itemTypeFields VALUES (22, 68, NULL, 4);    -- scale
INSERT INTO itemTypeFields VALUES (22, 28, NULL, 5);    -- seriesTitle
INSERT INTO itemTypeFields VALUES (22, 6, NULL, 6);     -- edition
INSERT INTO itemTypeFields VALUES (22, 7, NULL, 7);     -- place
INSERT INTO itemTypeFields VALUES (22, 8, NULL, 8);     -- publisher
INSERT INTO itemTypeFields VALUES (22, 14, NULL, 9);    -- date
INSERT INTO itemTypeFields VALUES (22, 87, NULL, 10);   -- language
INSERT INTO itemTypeFields VALUES (22, 11, NULL, 11);   -- ISBN
INSERT INTO itemTypeFields VALUES (22, 116, NULL, 12);  -- shortTitle
INSERT INTO itemTypeFields VALUES (22, 1, NULL, 13);    -- url
INSERT INTO itemTypeFields VALUES (22, 27, NULL, 14);   -- accessed
INSERT INTO itemTypeFields VALUES (22, 123, NULL, 15);  -- archive
INSERT INTO itemTypeFields VALUES (22, 19, NULL, 16);   -- archiveLocation
INSERT INTO itemTypeFields VALUES (22, 62, NULL, 17);   -- libraryCatalog
INSERT INTO itemTypeFields VALUES (22, 18, NULL, 18);   -- callNumber
INSERT INTO itemTypeFields VALUES (22, 2, NULL, 19);    -- rights
INSERT INTO itemTypeFields VALUES (22, 22, NULL, 20);   -- extra

INSERT INTO itemTypeFields VALUES (23, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (23, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (23, 107, NULL, 3);
INSERT INTO itemTypeFields VALUES (23, 70, NULL, 4);
INSERT INTO itemTypeFields VALUES (23, 14, NULL, 5);
INSERT INTO itemTypeFields VALUES (23, 1, NULL, 6);
INSERT INTO itemTypeFields VALUES (23, 27, NULL, 7);
INSERT INTO itemTypeFields VALUES (23, 87, NULL, 8);
INSERT INTO itemTypeFields VALUES (23, 116, NULL, 9);
INSERT INTO itemTypeFields VALUES (23, 2, NULL, 10);
INSERT INTO itemTypeFields VALUES (23, 22, NULL, 11);

-- instantMessage
INSERT INTO itemTypeFields VALUES (24, 110, NULL, 1); -- title
INSERT INTO itemTypeFields VALUES (24, 90, NULL, 2);  -- abstract
INSERT INTO itemTypeFields VALUES (24, 14, NULL, 3);  -- date
INSERT INTO itemTypeFields VALUES (24, 87, NULL, 4);  -- language
INSERT INTO itemTypeFields VALUES (24, 116, NULL, 5); -- shortTitle
INSERT INTO itemTypeFields VALUES (24, 1, NULL, 6);   -- url
INSERT INTO itemTypeFields VALUES (24, 27, NULL, 7);  -- accessed
INSERT INTO itemTypeFields VALUES (24, 2, NULL, 8);   -- rights
INSERT INTO itemTypeFields VALUES (24, 22, NULL, 9);  -- extra

-- forumPost
INSERT INTO itemTypeFields VALUES (25, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (25, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (25, 104, NULL, 3);
INSERT INTO itemTypeFields VALUES (25, 79, NULL, 4);
INSERT INTO itemTypeFields VALUES (25, 14, NULL, 5);
INSERT INTO itemTypeFields VALUES (25, 87, NULL, 6);
INSERT INTO itemTypeFields VALUES (25, 116, NULL, 7);
INSERT INTO itemTypeFields VALUES (25, 1, NULL, 8);
INSERT INTO itemTypeFields VALUES (25, 27, NULL, 9);
INSERT INTO itemTypeFields VALUES (25, 2, NULL, 10);
INSERT INTO itemTypeFields VALUES (25, 22, NULL, 11);

-- audioRecording
INSERT INTO itemTypeFields VALUES (26, 110, NULL, 1);   -- title
INSERT INTO itemTypeFields VALUES (26, 90, NULL, 2);    -- abstract
INSERT INTO itemTypeFields VALUES (26, 1273, NULL, 3);  -- album                [ADDED]
INSERT INTO itemTypeFields VALUES (26, 71, NULL, 4);    -- audioRecordingFormat
INSERT INTO itemTypeFields VALUES (26, 28, NULL, 5);    -- seriesTitle
INSERT INTO itemTypeFields VALUES (26, 4, NULL, 6);     -- volume
INSERT INTO itemTypeFields VALUES (26, 45, NULL, 7);    -- numberOfVolumes
INSERT INTO itemTypeFields VALUES (26, 7, NULL, 8);     -- place
INSERT INTO itemTypeFields VALUES (26, 72, NULL, 9);    -- label
INSERT INTO itemTypeFields VALUES (26, 14, NULL, 10);   -- date
INSERT INTO itemTypeFields VALUES (26, 1274, NULL, 11); -- opus                 [ADDED]
INSERT INTO itemTypeFields VALUES (26, 8, NULL, 12);    -- publisher            [ADDED]
INSERT INTO itemTypeFields VALUES (26, 1272, NULL, 12); -- originalDate         [ADDED]
INSERT INTO itemTypeFields VALUES (26, 77, NULL, 13);   -- runningTime
INSERT INTO itemTypeFields VALUES (26, 87, NULL, 14);   -- language
INSERT INTO itemTypeFields VALUES (26, 11, NULL, 15);   -- ISBN
INSERT INTO itemTypeFields VALUES (26, 116, NULL, 16);  -- shortTitle
INSERT INTO itemTypeFields VALUES (26, 123, NULL, 17);  -- archive
INSERT INTO itemTypeFields VALUES (26, 19, NULL, 18);   -- archiveLocation
INSERT INTO itemTypeFields VALUES (26, 62, NULL, 19);   -- libraryCatalog
INSERT INTO itemTypeFields VALUES (26, 18, NULL, 20);   -- callNumber
INSERT INTO itemTypeFields VALUES (26, 1, NULL, 21);    -- url
INSERT INTO itemTypeFields VALUES (26, 27, NULL, 22);   -- accessed
INSERT INTO itemTypeFields VALUES (26, 2, NULL, 23);    -- rights
INSERT INTO itemTypeFields VALUES (26, 22, NULL, 24);   -- extra

INSERT INTO itemTypeFields VALUES (27, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (27, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (27, 74, NULL, 3);
INSERT INTO itemTypeFields VALUES (27, 14, NULL, 4);
INSERT INTO itemTypeFields VALUES (27, 7, NULL, 5);
INSERT INTO itemTypeFields VALUES (27, 75, NULL, 6);
INSERT INTO itemTypeFields VALUES (27, 1, NULL, 7);
INSERT INTO itemTypeFields VALUES (27, 27, NULL, 8);
INSERT INTO itemTypeFields VALUES (27, 87, NULL, 9);
INSERT INTO itemTypeFields VALUES (27, 116, NULL, 10);
INSERT INTO itemTypeFields VALUES (27, 2, NULL, 11);
INSERT INTO itemTypeFields VALUES (27, 22, NULL, 12);

INSERT INTO itemTypeFields VALUES (28, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (28, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (28, 63, NULL, 3);
INSERT INTO itemTypeFields VALUES (28, 28, NULL, 4);
INSERT INTO itemTypeFields VALUES (28, 4, NULL, 5);
INSERT INTO itemTypeFields VALUES (28, 45, NULL, 6);
INSERT INTO itemTypeFields VALUES (28, 7, NULL, 7);
INSERT INTO itemTypeFields VALUES (28, 76, NULL, 8);
INSERT INTO itemTypeFields VALUES (28, 14, NULL, 9);
INSERT INTO itemTypeFields VALUES (28, 77, NULL, 10);
INSERT INTO itemTypeFields VALUES (28, 87, NULL, 11);
INSERT INTO itemTypeFields VALUES (28, 11, NULL, 12);
INSERT INTO itemTypeFields VALUES (28, 116, NULL, 13);
INSERT INTO itemTypeFields VALUES (28, 1, NULL, 14);
INSERT INTO itemTypeFields VALUES (28, 27, NULL, 15);
INSERT INTO itemTypeFields VALUES (28, 123, NULL, 16);
INSERT INTO itemTypeFields VALUES (28, 19, NULL, 17);
INSERT INTO itemTypeFields VALUES (28, 62, NULL, 18);
INSERT INTO itemTypeFields VALUES (28, 18, NULL, 19);
INSERT INTO itemTypeFields VALUES (28, 2, NULL, 20);
INSERT INTO itemTypeFields VALUES (28, 22, NULL, 21);

-- tvBroadcast
INSERT INTO itemTypeFields VALUES (29, 110, NULL, 1);  -- title
INSERT INTO itemTypeFields VALUES (29, 90, NULL, 2);   -- abstract
INSERT INTO itemTypeFields VALUES (29, 119, NULL, 3);  -- programTitle
INSERT INTO itemTypeFields VALUES (29, 105, NULL, 4);  -- episodeNumber
INSERT INTO itemTypeFields VALUES (29, 63, NULL, 5);   -- videoRecordingFormat
INSERT INTO itemTypeFields VALUES (29, 7, NULL, 6);    -- place
INSERT INTO itemTypeFields VALUES (29, 78, NULL, 7);   -- network
INSERT INTO itemTypeFields VALUES (29, 14, NULL, 8);   -- date
INSERT INTO itemTypeFields VALUES (29, 77, NULL, 9);   -- runningTime
INSERT INTO itemTypeFields VALUES (29, 87, NULL, 10);  -- language
INSERT INTO itemTypeFields VALUES (29, 116, NULL, 11); -- shortTitle
INSERT INTO itemTypeFields VALUES (29, 1, NULL, 12);   -- url
INSERT INTO itemTypeFields VALUES (29, 27, NULL, 13);  -- accessed
INSERT INTO itemTypeFields VALUES (29, 123, NULL, 14); -- archive
INSERT INTO itemTypeFields VALUES (29, 19, NULL, 15);  -- archiveLocation
INSERT INTO itemTypeFields VALUES (29, 62, NULL, 16);  -- libraryCatalog
INSERT INTO itemTypeFields VALUES (29, 18, NULL, 17);  -- call number
INSERT INTO itemTypeFields VALUES (29, 2, NULL, 18);   -- rights
INSERT INTO itemTypeFields VALUES (29, 22, NULL, 19);  -- extra

-- radio broadcast
INSERT INTO itemTypeFields VALUES (30, 110, NULL, 1);  -- title
INSERT INTO itemTypeFields VALUES (30, 90, NULL, 2);   -- abstract
INSERT INTO itemTypeFields VALUES (30, 119, NULL, 3);  -- programTitle
INSERT INTO itemTypeFields VALUES (30, 105, NULL, 4);  -- episodeNumber
INSERT INTO itemTypeFields VALUES (30, 71, NULL, 5);   -- audioRecordingFormat
INSERT INTO itemTypeFields VALUES (30, 7, NULL, 6);    -- place
INSERT INTO itemTypeFields VALUES (30, 78, NULL, 7);   -- network
INSERT INTO itemTypeFields VALUES (30, 14, NULL, 8);   -- date
INSERT INTO itemTypeFields VALUES (30, 77, NULL, 9);   -- runningTime
INSERT INTO itemTypeFields VALUES (30, 87, NULL, 10);  -- language
INSERT INTO itemTypeFields VALUES (30, 116, NULL, 11); -- shortTitle
INSERT INTO itemTypeFields VALUES (30, 1, NULL, 12);   -- url
INSERT INTO itemTypeFields VALUES (30, 27, NULL, 13);  -- accessed
INSERT INTO itemTypeFields VALUES (30, 123, NULL, 14); -- archive
INSERT INTO itemTypeFields VALUES (30, 19, NULL, 15);  -- archiveLocation
INSERT INTO itemTypeFields VALUES (30, 62, NULL, 16);  -- libraryCatalog
INSERT INTO itemTypeFields VALUES (30, 18, NULL, 17);  -- call number
INSERT INTO itemTypeFields VALUES (30, 2, NULL, 18);   -- rights
INSERT INTO itemTypeFields VALUES (30, 22, NULL, 19);  -- extra

-- podcast
INSERT INTO itemTypeFields VALUES (31, 110, NULL, 1);    -- title
INSERT INTO itemTypeFields VALUES (31, 90, NULL, 2);     -- abstract
INSERT INTO itemTypeFields VALUES (31, 28, NULL, 3);     -- seriesTitle
INSERT INTO itemTypeFields VALUES (31, 105, NULL, 4);    -- episodeNumber
INSERT INTO itemTypeFields VALUES (31, 14, NULL, 5);     -- date           [ADDED]
INSERT INTO itemTypeFields VALUES (31, 8, NULL, 6);      -- publisher      [ADDED]
INSERT INTO itemTypeFields VALUES (31, 80, NULL, 7);     -- audioFileType (medium)
INSERT INTO itemTypeFields VALUES (31, 77, NULL, 8);     -- runningTime
INSERT INTO itemTypeFields VALUES (31, 116, NULL, 9);    -- shortTitle
INSERT INTO itemTypeFields VALUES (31, 87, NULL, 10);    -- language
INSERT INTO itemTypeFields VALUES (31, 1, NULL, 11);     -- url
INSERT INTO itemTypeFields VALUES (31, 27, NULL, 12);    -- accessed
INSERT INTO itemTypeFields VALUES (31, 2, NULL, 13);     -- rights
INSERT INTO itemTypeFields VALUES (31, 22, NULL, 14);    -- extra

INSERT INTO itemTypeFields VALUES (32, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (32, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (32, 28, NULL, 3);
INSERT INTO itemTypeFields VALUES (32, 81, NULL, 4);
INSERT INTO itemTypeFields VALUES (32, 14, NULL, 5);
INSERT INTO itemTypeFields VALUES (32, 82, NULL, 6);
INSERT INTO itemTypeFields VALUES (32, 7, NULL, 7);
INSERT INTO itemTypeFields VALUES (32, 83, NULL, 8);
INSERT INTO itemTypeFields VALUES (32, 88, NULL, 9);
INSERT INTO itemTypeFields VALUES (32, 11, NULL, 10);
INSERT INTO itemTypeFields VALUES (32, 116, NULL, 11);
INSERT INTO itemTypeFields VALUES (32, 1, NULL, 12);
INSERT INTO itemTypeFields VALUES (32, 2, NULL, 13);
INSERT INTO itemTypeFields VALUES (32, 123, NULL, 14);
INSERT INTO itemTypeFields VALUES (32, 19, NULL, 15);
INSERT INTO itemTypeFields VALUES (32, 62, NULL, 16);
INSERT INTO itemTypeFields VALUES (32, 18, NULL, 17);
INSERT INTO itemTypeFields VALUES (32, 27, NULL, 18);
INSERT INTO itemTypeFields VALUES (32, 22, NULL, 19);

INSERT INTO itemTypeFields VALUES (33, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (33, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (33, 14, NULL, 3);
INSERT INTO itemTypeFields VALUES (33, 114, NULL, 4);
INSERT INTO itemTypeFields VALUES (33, 84, NULL, 5);
INSERT INTO itemTypeFields VALUES (33, 7, NULL, 6);
INSERT INTO itemTypeFields VALUES (33, 8, NULL, 7);
INSERT INTO itemTypeFields VALUES (33, 4, NULL, 8);
INSERT INTO itemTypeFields VALUES (33, 10, NULL, 9);
INSERT INTO itemTypeFields VALUES (33, 3, NULL, 10);
INSERT INTO itemTypeFields VALUES (33, 87, NULL, 11);
INSERT INTO itemTypeFields VALUES (33, 26, NULL, 12);
INSERT INTO itemTypeFields VALUES (33, 11, NULL, 13);
INSERT INTO itemTypeFields VALUES (33, 116, NULL, 14);
INSERT INTO itemTypeFields VALUES (33, 1, NULL, 15);
INSERT INTO itemTypeFields VALUES (33, 27, NULL, 16);
INSERT INTO itemTypeFields VALUES (33, 123, NULL, 17);
INSERT INTO itemTypeFields VALUES (33, 19, NULL, 18);
INSERT INTO itemTypeFields VALUES (33, 62, NULL, 19);
INSERT INTO itemTypeFields VALUES (33, 18, NULL, 20);
INSERT INTO itemTypeFields VALUES (33, 2, NULL, 21);
INSERT INTO itemTypeFields VALUES (33, 22, NULL, 22);

-- document
INSERT INTO itemTypeFields VALUES (34, 110, NULL, 1);  -- title
INSERT INTO itemTypeFields VALUES (34, 90, NULL, 2);   -- abstract
INSERT INTO itemTypeFields VALUES (34, 8, NULL, 3);    -- publisher
INSERT INTO itemTypeFields VALUES (34, 14, NULL, 4);   -- date
INSERT INTO itemTypeFields VALUES (34, 87, NULL, 5);   -- language
INSERT INTO itemTypeFields VALUES (34, 116, NULL, 6);  -- shortTitle
INSERT INTO itemTypeFields VALUES (34, 1, NULL, 7);    -- url
INSERT INTO itemTypeFields VALUES (34, 27, NULL, 8);   -- accessed
INSERT INTO itemTypeFields VALUES (34, 123, NULL, 9);  -- archive
INSERT INTO itemTypeFields VALUES (34, 19, NULL, 10);  -- archiveLocation
INSERT INTO itemTypeFields VALUES (34, 62, NULL, 11);  -- libraryCatalog
INSERT INTO itemTypeFields VALUES (34, 18, NULL, 12);  -- callNumber
INSERT INTO itemTypeFields VALUES (34, 2, NULL, 13);   -- rights
INSERT INTO itemTypeFields VALUES (34, 22, NULL, 14);  -- extra

INSERT INTO itemTypeFields VALUES (35, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (35, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (35, 85, NULL, 3);
INSERT INTO itemTypeFields VALUES (35, 3, NULL, 4);
INSERT INTO itemTypeFields VALUES (35, 30, NULL, 5);
INSERT INTO itemTypeFields VALUES (35, 4, NULL, 6);
INSERT INTO itemTypeFields VALUES (35, 45, NULL, 7);
INSERT INTO itemTypeFields VALUES (35, 6, NULL, 8);
INSERT INTO itemTypeFields VALUES (35, 7, NULL, 9);
INSERT INTO itemTypeFields VALUES (35, 8, NULL, 10);
INSERT INTO itemTypeFields VALUES (35, 14, NULL, 11);
INSERT INTO itemTypeFields VALUES (35, 10, NULL, 12);
INSERT INTO itemTypeFields VALUES (35, 11, NULL, 13);
INSERT INTO itemTypeFields VALUES (35, 116, NULL, 14);
INSERT INTO itemTypeFields VALUES (35, 1, NULL, 15);
INSERT INTO itemTypeFields VALUES (35, 27, NULL, 16);
INSERT INTO itemTypeFields VALUES (35, 87, NULL, 17);
INSERT INTO itemTypeFields VALUES (35, 123, NULL, 18);
INSERT INTO itemTypeFields VALUES (35, 19, NULL, 19);
INSERT INTO itemTypeFields VALUES (35, 62, NULL, 20);
INSERT INTO itemTypeFields VALUES (35, 18, NULL, 21);
INSERT INTO itemTypeFields VALUES (35, 2, NULL, 22);
INSERT INTO itemTypeFields VALUES (35, 22, NULL, 23);

INSERT INTO itemTypeFields VALUES (36, 110, NULL, 1);
INSERT INTO itemTypeFields VALUES (36, 90, NULL, 2);
INSERT INTO itemTypeFields VALUES (36, 86, NULL, 3);
INSERT INTO itemTypeFields VALUES (36, 3, NULL, 4);
INSERT INTO itemTypeFields VALUES (36, 30, NULL, 5);
INSERT INTO itemTypeFields VALUES (36, 4, NULL, 6);
INSERT INTO itemTypeFields VALUES (36, 45, NULL, 7);
INSERT INTO itemTypeFields VALUES (36, 6, NULL, 8);
INSERT INTO itemTypeFields VALUES (36, 7, NULL, 9);
INSERT INTO itemTypeFields VALUES (36, 8, NULL, 10);
INSERT INTO itemTypeFields VALUES (36, 14, NULL, 11);
INSERT INTO itemTypeFields VALUES (36, 10, NULL, 12);
INSERT INTO itemTypeFields VALUES (36, 87, NULL, 13);
INSERT INTO itemTypeFields VALUES (36, 11, NULL, 14);
INSERT INTO itemTypeFields VALUES (36, 116, NULL, 15);
INSERT INTO itemTypeFields VALUES (36, 1, NULL, 16);
INSERT INTO itemTypeFields VALUES (36, 27, NULL, 17);
INSERT INTO itemTypeFields VALUES (36, 123, NULL, 18);
INSERT INTO itemTypeFields VALUES (36, 19, NULL, 19);
INSERT INTO itemTypeFields VALUES (36, 62, NULL, 20);
INSERT INTO itemTypeFields VALUES (36, 18, NULL, 21);
INSERT INTO itemTypeFields VALUES (36, 2, NULL, 22);
INSERT INTO itemTypeFields VALUES (36, 22, NULL, 23);

-- [NEW] gazette (derived from statute)
INSERT INTO itemTypeFields VALUES (1261, 112, NULL, 1);   -- nameOfAct
INSERT INTO itemTypeFields VALUES (1261, 90, NULL, 2);    -- abstract
INSERT INTO itemTypeFields VALUES (1261, 1261, NULL, 3);  -- jurisdiction
INSERT INTO itemTypeFields VALUES (1261, 116, NULL, 4);   -- shortTitle
INSERT INTO itemTypeFields VALUES (1261, 101, NULL, 5);   -- publicLawNumber
INSERT INTO itemTypeFields VALUES (1261, 36, NULL, 6);    -- code       (reporter)
INSERT INTO itemTypeFields VALUES (1261, 55, NULL, 7);    -- codeNumber (volume)
INSERT INTO itemTypeFields VALUES (1261, 10, NULL, 8);    -- pages
INSERT INTO itemTypeFields VALUES (1261, 100, NULL, 9);   -- dateEnacted
INSERT INTO itemTypeFields VALUES (1261, 15, NULL, 10);   -- section
INSERT INTO itemTypeFields VALUES (1261, 87, NULL, 11);   -- language
INSERT INTO itemTypeFields VALUES (1261, 1, NULL, 12);    -- url
INSERT INTO itemTypeFields VALUES (1261, 27, NULL, 13);   -- accessed
INSERT INTO itemTypeFields VALUES (1261, 40, NULL, 14);   -- session        Deprecated
INSERT INTO itemTypeFields VALUES (1261, 42, NULL, 15);   -- history        Deprecated
INSERT INTO itemTypeFields VALUES (1261, 2, NULL, 20);    -- rights
INSERT INTO itemTypeFields VALUES (1261, 22, NULL, 21);   -- extra

-- [NEW] treaty (derived from document)
INSERT INTO itemTypeFields VALUES (1262, 110, NULL, 1);   -- title
INSERT INTO itemTypeFields VALUES (1262, 90, NULL, 2);    -- abstract
INSERT INTO itemTypeFields VALUES (1262, 116, NULL, 3);   -- shortTitle
INSERT INTO itemTypeFields VALUES (1262, 43, NULL, 4);    -- reporter         [ADDED]
INSERT INTO itemTypeFields VALUES (1262, 4, NULL, 5);     -- volume           [ADDED]
INSERT INTO itemTypeFields VALUES (1262, 10, NULL, 6);    -- pages            [ADDED]
INSERT INTO itemTypeFields VALUES (1262, 1278, NULL, 7);  -- openingDate      [ADDED]
INSERT INTO itemTypeFields VALUES (1262, 1279, NULL, 8);  -- adoptionDate     [ADDED]
INSERT INTO itemTypeFields VALUES (1262, 1277, NULL, 9);  -- signingDate      [ADDED]
INSERT INTO itemTypeFields VALUES (1262, 14, NULL, 10);   -- date (effective date)
INSERT INTO itemTypeFields VALUES (1262, 15, NULL, 11);   -- section          [ADDED]
INSERT INTO itemTypeFields VALUES (1262, 87, NULL, 12);   -- language
INSERT INTO itemTypeFields VALUES (1262, 1, NULL, 13);    -- url
INSERT INTO itemTypeFields VALUES (1262, 27, NULL, 14);   -- accessed
INSERT INTO itemTypeFields VALUES (1262, 123, NULL, 15);  -- archive
INSERT INTO itemTypeFields VALUES (1262, 19, NULL, 16);   -- archiveLocation
INSERT INTO itemTypeFields VALUES (1262, 62, NULL, 17);   -- libraryCatalog   Deprecated
INSERT INTO itemTypeFields VALUES (1262, 18, NULL, 18);   -- callNumber       Deprecated
INSERT INTO itemTypeFields VALUES (1262, 8, NULL, 19);    -- publisher        Deprecated
INSERT INTO itemTypeFields VALUES (1262, 2, NULL, 20);    -- rights
INSERT INTO itemTypeFields VALUES (1262, 22, NULL, 21);   -- extra

-- [NEW] regulation (clone of gazette)
INSERT INTO itemTypeFields VALUES (1263, 112, NULL, 1);   -- nameOfAct
INSERT INTO itemTypeFields VALUES (1263, 90, NULL, 2);    -- abstract
INSERT INTO itemTypeFields VALUES (1263, 1261, NULL, 3);  -- jurisdiction
INSERT INTO itemTypeFields VALUES (1263, 116, NULL, 4);   -- shortTitle
INSERT INTO itemTypeFields VALUES (1263, 101, NULL, 5);   -- publicLawNumber
INSERT INTO itemTypeFields VALUES (1263, 36, NULL, 6);    -- code           (for reporter)
INSERT INTO itemTypeFields VALUES (1263, 55, NULL, 7);    -- codeNumber     (for volume)
INSERT INTO itemTypeFields VALUES (1263, 10, NULL, 8);    -- pages
INSERT INTO itemTypeFields VALUES (1263, 100, NULL, 9);   -- dateEnacted
INSERT INTO itemTypeFields VALUES (1263, 15, NULL, 10);   -- section
INSERT INTO itemTypeFields VALUES (20, 8, NULL, 12);      -- publisher       [ADDED]
INSERT INTO itemTypeFields VALUES (20, 1268, NULL, 13);   -- publicationDate [ADDED]
INSERT INTO itemTypeFields VALUES (1263, 87, NULL, 11);   -- language
INSERT INTO itemTypeFields VALUES (1263, 1, NULL, 12);    -- url
INSERT INTO itemTypeFields VALUES (1263, 27, NULL, 13);   -- accessed
INSERT INTO itemTypeFields VALUES (1263, 40, NULL, 14);   -- session         Deprecated
INSERT INTO itemTypeFields VALUES (1263, 42, NULL, 15);   -- history         Deprecated
INSERT INTO itemTypeFields VALUES (1263, 2, NULL, 20);    -- rights
INSERT INTO itemTypeFields VALUES (1263, 22, NULL, 21);   -- extra

-- [NEW] classic (derived from manuscript)
INSERT INTO itemTypeFields VALUES (1264, 110, NULL, 1);  -- title
INSERT INTO itemTypeFields VALUES (1264, 90, NULL, 2);   -- abstract
INSERT INTO itemTypeFields VALUES (1264, 4, NULL, 3);    -- volume          [ADDED]
INSERT INTO itemTypeFields VALUES (1264, 14, NULL, 4);   -- date            
INSERT INTO itemTypeFields VALUES (1264, 118, NULL, 5);  -- numPages
INSERT INTO itemTypeFields VALUES (1264, 87, NULL, 6);   -- language
INSERT INTO itemTypeFields VALUES (1264, 116, NULL, 7);  -- shortTitle
INSERT INTO itemTypeFields VALUES (1264, 1, NULL, 8);    -- url
INSERT INTO itemTypeFields VALUES (1264, 27, NULL, 9);   -- accessed
INSERT INTO itemTypeFields VALUES (1264, 123, NULL, 10); -- archive
INSERT INTO itemTypeFields VALUES (1264, 19, NULL, 11);  -- archiveLocation
INSERT INTO itemTypeFields VALUES (1264, 62, NULL, 12);  -- libraryCatalog
INSERT INTO itemTypeFields VALUES (1264, 18, NULL, 13);  -- callNumber
INSERT INTO itemTypeFields VALUES (1264, 66, NULL, 14);  -- manuscriptType  Deprecated
INSERT INTO itemTypeFields VALUES (1264, 7, NULL, 15);   -- place           Deprecated
INSERT INTO itemTypeFields VALUES (1264, 2, NULL, 16);   -- rights
INSERT INTO itemTypeFields VALUES (1264, 22, NULL, 17);  -- extra

-- [NEW] periodical (clone of document)
INSERT INTO itemTypeFields VALUES (1265, 110, NULL, 1);  -- title
INSERT INTO itemTypeFields VALUES (1265, 90, NULL, 2);   -- abstract
INSERT INTO itemTypeFields VALUES (1265, 8, NULL, 3);    -- publisher
INSERT INTO itemTypeFields VALUES (1265, 14, NULL, 4);   -- date
INSERT INTO itemTypeFields VALUES (1265, 87, NULL, 5);   -- language
INSERT INTO itemTypeFields VALUES (1265, 116, NULL, 6);  -- shortTitle
INSERT INTO itemTypeFields VALUES (1265, 1, NULL, 7);    -- url
INSERT INTO itemTypeFields VALUES (1265, 27, NULL, 8);   -- accessed
INSERT INTO itemTypeFields VALUES (1265, 123, NULL, 9);  -- archive
INSERT INTO itemTypeFields VALUES (1265, 19, NULL, 10);  -- archiveLocation
INSERT INTO itemTypeFields VALUES (1265, 62, NULL, 11);  -- libraryCatalog
INSERT INTO itemTypeFields VALUES (1265, 18, NULL, 12);  -- callNumber
INSERT INTO itemTypeFields VALUES (1265, 2, NULL, 13);   -- rights
INSERT INTO itemTypeFields VALUES (1265, 22, NULL, 14);  -- extra

INSERT INTO baseFieldMappings VALUES (16, 4, 94); -- bill/volume/codeVolume
INSERT INTO baseFieldMappings VALUES (17, 4, 97); -- case/volume/reporterVolume
INSERT INTO baseFieldMappings VALUES (7, 8, 89); -- thesis/publisher/university
INSERT INTO baseFieldMappings VALUES (11, 8, 21); -- film/publisher/distributor
INSERT INTO baseFieldMappings VALUES (15, 8, 31); -- report/publisher/institution
INSERT INTO baseFieldMappings VALUES (26, 8, 72); -- audioRecording/publisher/label
INSERT INTO baseFieldMappings VALUES (28, 8, 76); -- videoRecording/publisher/studio
INSERT INTO baseFieldMappings VALUES (29, 8, 78); -- tvBroadcast/publisher/network
INSERT INTO baseFieldMappings VALUES (30, 8, 78); -- radioBroadcast/publisher/network
INSERT INTO baseFieldMappings VALUES (32, 8, 83); -- computerProgram/publisher/company
INSERT INTO baseFieldMappings VALUES (16, 10, 95); -- bill/pages/codePages
INSERT INTO baseFieldMappings VALUES (17, 10, 98); -- case/pages/firstPage
INSERT INTO baseFieldMappings VALUES (3, 12, 115); -- bookSection/publicationTitle/bookTitle
INSERT INTO baseFieldMappings VALUES (33, 12, 114); -- conferencePaper/publicationTitle/proceedingsTitle
INSERT INTO baseFieldMappings VALUES (13, 12, 91); -- webpage/publicationTitle/websiteTitle
INSERT INTO baseFieldMappings VALUES (23, 12, 107); -- blogPost/publicationTitle/blogTitle
INSERT INTO baseFieldMappings VALUES (25, 12, 104); -- forumPost/publicationTitle/forumTitle
INSERT INTO baseFieldMappings VALUES (29, 12, 119); -- tvBroadcast/publicationTitle/programTitle
INSERT INTO baseFieldMappings VALUES (30, 12, 119); -- radioBroadcast/publicationTitle/programTitle
INSERT INTO baseFieldMappings VALUES (35, 12, 85); -- encyclopediaEntry/publicationTitle/encyclopediaTitle
INSERT INTO baseFieldMappings VALUES (36, 12, 86); -- dictionaryEntry/publicationTitle/dictionaryTitle
INSERT INTO baseFieldMappings VALUES (16, 12, 43); -- bill/publicationTitle/reporter
INSERT INTO baseFieldMappings VALUES (17, 12, 43); -- case/publicationTitle/reporter
INSERT INTO baseFieldMappings VALUES (17, 14, 96); -- case/date/dateDecided
INSERT INTO baseFieldMappings VALUES (19, 14, 52); -- patent/date/issueDate
INSERT INTO baseFieldMappings VALUES (20, 14, 100); -- statute/date/dateEnacted
INSERT INTO baseFieldMappings VALUES (16, 30, 1262); -- bill/seriesNumber/assemblyNumber
INSERT INTO baseFieldMappings VALUES (15, 60, 92); -- report/number/reportNumber
INSERT INTO baseFieldMappings VALUES (16, 60, 93); -- bill/number/billNumber
INSERT INTO baseFieldMappings VALUES (17, 60, 117); -- case/number/docketNumber
INSERT INTO baseFieldMappings VALUES (18, 60, 99); -- hearing/number/documentNumber
INSERT INTO baseFieldMappings VALUES (19, 60, 50); -- patent/number/patentNumber
INSERT INTO baseFieldMappings VALUES (20, 60, 101); -- statute/number/publicLawNumber
INSERT INTO baseFieldMappings VALUES (29, 60, 105); -- tvBroadcast/number/episodeNumber
INSERT INTO baseFieldMappings VALUES (30, 60, 105); -- radioBroadcast/number/episodeNumber
INSERT INTO baseFieldMappings VALUES (31, 60, 105); -- podcast/number/episodeNumber
INSERT INTO baseFieldMappings VALUES (7, 108, 69); -- thesis/type/thesisType
INSERT INTO baseFieldMappings VALUES (8, 108, 65); -- letter/type/letterType
INSERT INTO baseFieldMappings VALUES (9, 108, 66); -- manuscript/type/manuscriptType
INSERT INTO baseFieldMappings VALUES (11, 108, 122); -- film/type/genre
INSERT INTO baseFieldMappings VALUES (13, 108, 70); -- webpage/type/websiteType
INSERT INTO baseFieldMappings VALUES (15, 108, 32); -- report/type/reportType
INSERT INTO baseFieldMappings VALUES (22, 108, 67); -- map/type/mapType
INSERT INTO baseFieldMappings VALUES (23, 108, 70); -- blogPost/type/websiteType
INSERT INTO baseFieldMappings VALUES (25, 108, 79); -- forumPost/type/postType
INSERT INTO baseFieldMappings VALUES (27, 108, 74); -- presentation/type/presentationType
INSERT INTO baseFieldMappings VALUES (16, 108, 1264); -- bill/type/sessionType
INSERT INTO baseFieldMappings VALUES (10, 109, 64); -- interview/medium/interviewMedium
INSERT INTO baseFieldMappings VALUES (11, 109, 63); -- film/medium/videoRecordingFormat
INSERT INTO baseFieldMappings VALUES (12, 109, 59); -- artwork/medium/artworkMedium
INSERT INTO baseFieldMappings VALUES (26, 109, 71); -- audioRecording/medium/audioRecordingFormat
INSERT INTO baseFieldMappings VALUES (28, 109, 63); -- videoRecording/medium/videoRecordingFormat
INSERT INTO baseFieldMappings VALUES (29, 109, 63); -- tvBroadcast/medium/videoRecodingMedium
INSERT INTO baseFieldMappings VALUES (30, 109, 71); -- radioBroadcast/medium/audioRecordingFormat
INSERT INTO baseFieldMappings VALUES (31, 109, 80); -- podcast/medium/audioFileType
INSERT INTO baseFieldMappings VALUES (17, 110, 111); -- case/title/caseName
INSERT INTO baseFieldMappings VALUES (20, 110, 112); -- statute/title/nameOfAct
INSERT INTO baseFieldMappings VALUES (21, 110, 113); -- email/title/subject

INSERT INTO creatorTypes VALUES(1, "author");
INSERT INTO creatorTypes VALUES(2, "contributor");
INSERT INTO creatorTypes VALUES(3, "editor");
INSERT INTO creatorTypes VALUES(4, "translator");
INSERT INTO creatorTypes VALUES(5, "seriesEditor");
INSERT INTO creatorTypes VALUES(6, "interviewee");
INSERT INTO creatorTypes VALUES(7, "interviewer");
INSERT INTO creatorTypes VALUES(8, "director");
INSERT INTO creatorTypes VALUES(9, "scriptwriter");
INSERT INTO creatorTypes VALUES(10, "producer");
INSERT INTO creatorTypes VALUES(11, "castMember");
INSERT INTO creatorTypes VALUES(12, "sponsor");
INSERT INTO creatorTypes VALUES(13, "counsel");
INSERT INTO creatorTypes VALUES(14, "inventor");
INSERT INTO creatorTypes VALUES(15, "attorneyAgent");
INSERT INTO creatorTypes VALUES(16, "recipient");
INSERT INTO creatorTypes VALUES(17, "performer");
INSERT INTO creatorTypes VALUES(18, "composer");
INSERT INTO creatorTypes VALUES(19, "wordsBy");
INSERT INTO creatorTypes VALUES(20, "cartographer");
INSERT INTO creatorTypes VALUES(21, "programmer");
INSERT INTO creatorTypes VALUES(22, "artist");
INSERT INTO creatorTypes VALUES(23, "commenter");
INSERT INTO creatorTypes VALUES(24, "presenter");
INSERT INTO creatorTypes VALUES(25, "guest");
INSERT INTO creatorTypes VALUES(26, "podcaster");
INSERT INTO creatorTypes VALUES(27, "reviewedAuthor");
INSERT INTO creatorTypes VALUES(28, "cosponsor");
INSERT INTO creatorTypes VALUES(29, "bookAuthor");

INSERT INTO itemTypeCreatorTypes VALUES(2,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(2,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(2,3,0);
INSERT INTO itemTypeCreatorTypes VALUES(2,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(2,5,0);
INSERT INTO itemTypeCreatorTypes VALUES(3,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(3,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(3,3,0);
INSERT INTO itemTypeCreatorTypes VALUES(3,29,0);
INSERT INTO itemTypeCreatorTypes VALUES(3,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(3,5,0);
INSERT INTO itemTypeCreatorTypes VALUES(4,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(4,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(4,3,0);
INSERT INTO itemTypeCreatorTypes VALUES(4,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(4,27,0);
INSERT INTO itemTypeCreatorTypes VALUES(5,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(5,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(5,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(5,27,0);
INSERT INTO itemTypeCreatorTypes VALUES(6,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(6,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(6,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(6,27,0);
INSERT INTO itemTypeCreatorTypes VALUES(7,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(7,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(8,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(8,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(8,16,0);
INSERT INTO itemTypeCreatorTypes VALUES(9,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(9,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(9,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(10,6,1);
INSERT INTO itemTypeCreatorTypes VALUES(10,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(10,7,0);
INSERT INTO itemTypeCreatorTypes VALUES(10,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(11,8,1);
INSERT INTO itemTypeCreatorTypes VALUES(11,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(11,9,0);
INSERT INTO itemTypeCreatorTypes VALUES(11,10,0);
INSERT INTO itemTypeCreatorTypes VALUES(12,22,1);
INSERT INTO itemTypeCreatorTypes VALUES(12,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(13,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(13,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(13,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(15,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(15,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(15,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(15,5,0);
INSERT INTO itemTypeCreatorTypes VALUES(16,12,1);
INSERT INTO itemTypeCreatorTypes VALUES(16,28,0);
INSERT INTO itemTypeCreatorTypes VALUES(16,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(17,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(17,13,0);
INSERT INTO itemTypeCreatorTypes VALUES(17,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(18,2,1);
INSERT INTO itemTypeCreatorTypes VALUES(19,14,1);
INSERT INTO itemTypeCreatorTypes VALUES(19,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(19,15,0);
INSERT INTO itemTypeCreatorTypes VALUES(19,16,0);
INSERT INTO itemTypeCreatorTypes VALUES(20,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(20,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(21,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(21,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(21,16,0);
INSERT INTO itemTypeCreatorTypes VALUES(22,20,1);
INSERT INTO itemTypeCreatorTypes VALUES(22,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(22,5,0);
INSERT INTO itemTypeCreatorTypes VALUES(23,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(23,23,0);
INSERT INTO itemTypeCreatorTypes VALUES(23,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(24,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(24,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(24,16,0);
INSERT INTO itemTypeCreatorTypes VALUES(25,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(25,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(26,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(26,17,1);
INSERT INTO itemTypeCreatorTypes VALUES(26,18,0);
INSERT INTO itemTypeCreatorTypes VALUES(26,19,0);
INSERT INTO itemTypeCreatorTypes VALUES(27,24,1);
INSERT INTO itemTypeCreatorTypes VALUES(27,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(28,8,1);
INSERT INTO itemTypeCreatorTypes VALUES(28,9,0);
INSERT INTO itemTypeCreatorTypes VALUES(28,10,0);
INSERT INTO itemTypeCreatorTypes VALUES(28,11,0);
INSERT INTO itemTypeCreatorTypes VALUES(28,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(29,8,1);
INSERT INTO itemTypeCreatorTypes VALUES(29,9,0);
INSERT INTO itemTypeCreatorTypes VALUES(29,10,0);
INSERT INTO itemTypeCreatorTypes VALUES(29,11,0);
INSERT INTO itemTypeCreatorTypes VALUES(29,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(29,25,0);
INSERT INTO itemTypeCreatorTypes VALUES(30,8,1);
INSERT INTO itemTypeCreatorTypes VALUES(30,9,0);
INSERT INTO itemTypeCreatorTypes VALUES(30,10,0);
INSERT INTO itemTypeCreatorTypes VALUES(30,11,0);
INSERT INTO itemTypeCreatorTypes VALUES(30,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(30,25,0);
INSERT INTO itemTypeCreatorTypes VALUES(31,26,1);
INSERT INTO itemTypeCreatorTypes VALUES(31,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(31,25,0);
INSERT INTO itemTypeCreatorTypes VALUES(32,21,1);
INSERT INTO itemTypeCreatorTypes VALUES(32,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(33, 1, 1);
INSERT INTO itemTypeCreatorTypes VALUES(33, 2, 0);
INSERT INTO itemTypeCreatorTypes VALUES(33, 3, 0);
INSERT INTO itemTypeCreatorTypes VALUES(33, 4, 0);
INSERT INTO itemTypeCreatorTypes VALUES(33, 5, 0);
INSERT INTO itemTypeCreatorTypes VALUES(34,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(34,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(34,3,0);
INSERT INTO itemTypeCreatorTypes VALUES(34,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(34,27,0);
INSERT INTO itemTypeCreatorTypes VALUES(35,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(35,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(35,3,0);
INSERT INTO itemTypeCreatorTypes VALUES(35,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(35,5,0);
INSERT INTO itemTypeCreatorTypes VALUES(36,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(36,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(36,3,0);
INSERT INTO itemTypeCreatorTypes VALUES(36,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(36,5,0);
-- For spoofed types, clone creator assignments from master type
-- gazette (statute)
INSERT INTO itemTypeCreatorTypes VALUES(1261,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(1261,2,0);
-- treaty (document)
INSERT INTO itemTypeCreatorTypes VALUES(1262,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(1262,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(1262,3,0);
INSERT INTO itemTypeCreatorTypes VALUES(1262,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(1262,27,0);
-- regulation (statute)
INSERT INTO itemTypeCreatorTypes VALUES(1263,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(1263,2,0);
-- classic (manuscript)
INSERT INTO itemTypeCreatorTypes VALUES(1264,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(1264,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(1264,4,0);
-- periodical (document)
INSERT INTO itemTypeCreatorTypes VALUES(1265,1,1);
INSERT INTO itemTypeCreatorTypes VALUES(1265,2,0);
INSERT INTO itemTypeCreatorTypes VALUES(1265,3,0);
INSERT INTO itemTypeCreatorTypes VALUES(1265,4,0);
INSERT INTO itemTypeCreatorTypes VALUES(1265,27,0);

INSERT INTO "fileTypes" VALUES(1, 'webpage');
INSERT INTO "fileTypes" VALUES(2, 'image');
INSERT INTO "fileTypes" VALUES(3, 'pdf');
INSERT INTO "fileTypes" VALUES(4, 'audio');
INSERT INTO "fileTypes" VALUES(5, 'video');
INSERT INTO "fileTypes" VALUES(6, 'document');
INSERT INTO "fileTypes" VALUES(7, 'presentation');

-- webpage
INSERT INTO "fileTypeMIMETypes" VALUES(1, 'text/html');
-- image
INSERT INTO "fileTypeMIMETypes" VALUES(2, 'image/');
INSERT INTO "fileTypeMIMETypes" VALUES(2, 'application/vnd.oasis.opendocument.graphics');
INSERT INTO "fileTypeMIMETypes" VALUES(2, 'application/vnd.oasis.opendocument.image');
-- pdf
INSERT INTO "fileTypeMIMETypes" VALUES(3, 'application/pdf');
-- audio
INSERT INTO "fileTypeMIMETypes" VALUES(4, 'audio/');
INSERT INTO "fileTypeMIMETypes" VALUES(4, 'x-pn-realaudio');
INSERT INTO "fileTypeMIMETypes" VALUES(4, 'application/ogg');
INSERT INTO "fileTypeMIMETypes" VALUES(4, 'application/x-killustrator');
-- video
INSERT INTO "fileTypeMIMETypes" VALUES(5, 'video/');
INSERT INTO "fileTypeMIMETypes" VALUES(5, 'application/x-shockwave-flash');
-- document
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'text/plain');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/rtf');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/msword');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'text/xml');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/postscript');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/wordperfect5.1');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/x-latex');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/x-tex');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/x-kword');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/x-kspread');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/x-kchart');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/vnd.oasis.opendocument.chart');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/vnd.oasis.opendocument.database');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/vnd.oasis.opendocument.formula');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/vnd.oasis.opendocument.spreadsheet');
INSERT INTO "fileTypeMIMETypes" VALUES(6, 'application/vnd.oasis.opendocument.text');
-- presentation
INSERT INTO "fileTypeMIMETypes" VALUES(7, 'application/powerpoint');
INSERT INTO "fileTypeMIMETypes" VALUES(7, 'application/vnd.oasis.opendocument.presentation');
INSERT INTO "fileTypeMIMETypes" VALUES(7, 'application/x-kpresenter');

INSERT INTO "charsets" VALUES(1, 'utf-8');
INSERT INTO "charsets" VALUES(2, 'ascii');
INSERT INTO "charsets" VALUES(3, 'windows-1250');
INSERT INTO "charsets" VALUES(4, 'windows-1251');
INSERT INTO "charsets" VALUES(5, 'windows-1252');
INSERT INTO "charsets" VALUES(6, 'windows-1253');
INSERT INTO "charsets" VALUES(7, 'windows-1254');
INSERT INTO "charsets" VALUES(8, 'windows-1257');
INSERT INTO "charsets" VALUES(9, 'us');
INSERT INTO "charsets" VALUES(10, 'us-ascii');
INSERT INTO "charsets" VALUES(11, 'utf-7');
INSERT INTO "charsets" VALUES(12, 'iso8859-1');
INSERT INTO "charsets" VALUES(13, 'iso8859-15');
INSERT INTO "charsets" VALUES(14, 'iso_646.irv:1991');
INSERT INTO "charsets" VALUES(15, 'iso_8859-1');
INSERT INTO "charsets" VALUES(16, 'iso_8859-1:1987');
INSERT INTO "charsets" VALUES(17, 'iso_8859-2');
INSERT INTO "charsets" VALUES(18, 'iso_8859-2:1987');
INSERT INTO "charsets" VALUES(19, 'iso_8859-4');
INSERT INTO "charsets" VALUES(20, 'iso_8859-4:1988');
INSERT INTO "charsets" VALUES(21, 'iso_8859-5');
INSERT INTO "charsets" VALUES(22, 'iso_8859-5:1988');
INSERT INTO "charsets" VALUES(23, 'iso_8859-7');
INSERT INTO "charsets" VALUES(24, 'iso_8859-7:1987');
INSERT INTO "charsets" VALUES(25, 'iso-8859-1');
INSERT INTO "charsets" VALUES(26, 'iso-8859-1-windows-3.0-latin-1');
INSERT INTO "charsets" VALUES(27, 'iso-8859-1-windows-3.1-latin-1');
INSERT INTO "charsets" VALUES(28, 'iso-8859-15');
INSERT INTO "charsets" VALUES(29, 'iso-8859-2');
INSERT INTO "charsets" VALUES(30, 'iso-8859-2-windows-latin-2');
INSERT INTO "charsets" VALUES(31, 'iso-8859-3');
INSERT INTO "charsets" VALUES(32, 'iso-8859-4');
INSERT INTO "charsets" VALUES(33, 'iso-8859-5');
INSERT INTO "charsets" VALUES(34, 'iso-8859-5-windows-latin-5');
INSERT INTO "charsets" VALUES(35, 'iso-8859-6');
INSERT INTO "charsets" VALUES(36, 'iso-8859-7');
INSERT INTO "charsets" VALUES(37, 'iso-8859-8');
INSERT INTO "charsets" VALUES(38, 'iso-8859-9');
INSERT INTO "charsets" VALUES(39, 'l1');
INSERT INTO "charsets" VALUES(40, 'l2');
INSERT INTO "charsets" VALUES(41, 'l4');
INSERT INTO "charsets" VALUES(42, 'latin1');
INSERT INTO "charsets" VALUES(43, 'latin2');
INSERT INTO "charsets" VALUES(44, 'latin4');
INSERT INTO "charsets" VALUES(45, 'x-mac-ce');
INSERT INTO "charsets" VALUES(46, 'x-mac-cyrillic');
INSERT INTO "charsets" VALUES(47, 'x-mac-greek');
INSERT INTO "charsets" VALUES(48, 'x-mac-roman');
INSERT INTO "charsets" VALUES(49, 'x-mac-turkish');
INSERT INTO "charsets" VALUES(50, 'adobe-symbol-encoding');
INSERT INTO "charsets" VALUES(51, 'ansi_x3.4-1968');
INSERT INTO "charsets" VALUES(52, 'ansi_x3.4-1986');
INSERT INTO "charsets" VALUES(53, 'big5');
INSERT INTO "charsets" VALUES(54, 'chinese');
INSERT INTO "charsets" VALUES(55, 'cn-big5');
INSERT INTO "charsets" VALUES(56, 'cn-gb');
INSERT INTO "charsets" VALUES(57, 'cn-gb-isoir165');
INSERT INTO "charsets" VALUES(58, 'cp367');
INSERT INTO "charsets" VALUES(59, 'cp819');
INSERT INTO "charsets" VALUES(60, 'cp850');
INSERT INTO "charsets" VALUES(61, 'cp852');
INSERT INTO "charsets" VALUES(62, 'cp855');
INSERT INTO "charsets" VALUES(63, 'cp857');
INSERT INTO "charsets" VALUES(64, 'cp862');
INSERT INTO "charsets" VALUES(65, 'cp864');
INSERT INTO "charsets" VALUES(66, 'cp866');
INSERT INTO "charsets" VALUES(67, 'csascii');
INSERT INTO "charsets" VALUES(68, 'csbig5');
INSERT INTO "charsets" VALUES(69, 'cseuckr');
INSERT INTO "charsets" VALUES(70, 'cseucpkdfmtjapanese');
INSERT INTO "charsets" VALUES(71, 'csgb2312');
INSERT INTO "charsets" VALUES(72, 'cshalfwidthkatakana');
INSERT INTO "charsets" VALUES(73, 'cshppsmath');
INSERT INTO "charsets" VALUES(74, 'csiso103t618bit');
INSERT INTO "charsets" VALUES(75, 'csiso159jisx02121990');
INSERT INTO "charsets" VALUES(76, 'csiso2022jp');
INSERT INTO "charsets" VALUES(77, 'csiso2022jp2');
INSERT INTO "charsets" VALUES(78, 'csiso2022kr');
INSERT INTO "charsets" VALUES(79, 'csiso58gb231280');
INSERT INTO "charsets" VALUES(80, 'csisolatin4');
INSERT INTO "charsets" VALUES(81, 'csisolatincyrillic');
INSERT INTO "charsets" VALUES(82, 'csisolatingreek');
INSERT INTO "charsets" VALUES(83, 'cskoi8r');
INSERT INTO "charsets" VALUES(84, 'csksc56011987');
INSERT INTO "charsets" VALUES(85, 'csshiftjis');
INSERT INTO "charsets" VALUES(86, 'csunicode11');
INSERT INTO "charsets" VALUES(87, 'csunicode11utf7');
INSERT INTO "charsets" VALUES(88, 'csunicodeascii');
INSERT INTO "charsets" VALUES(89, 'csunicodelatin1');
INSERT INTO "charsets" VALUES(90, 'cswindows31latin5');
INSERT INTO "charsets" VALUES(91, 'cyrillic');
INSERT INTO "charsets" VALUES(92, 'ecma-118');
INSERT INTO "charsets" VALUES(93, 'elot_928');
INSERT INTO "charsets" VALUES(94, 'euc-jp');
INSERT INTO "charsets" VALUES(95, 'euc-kr');
INSERT INTO "charsets" VALUES(96, 'extended_unix_code_packed_format_for_japanese');
INSERT INTO "charsets" VALUES(97, 'gb2312');
INSERT INTO "charsets" VALUES(98, 'gb_2312-80');
INSERT INTO "charsets" VALUES(99, 'greek');
INSERT INTO "charsets" VALUES(100, 'greek8');
INSERT INTO "charsets" VALUES(101, 'hz-gb-2312');
INSERT INTO "charsets" VALUES(102, 'ibm367');
INSERT INTO "charsets" VALUES(103, 'ibm819');
INSERT INTO "charsets" VALUES(104, 'ibm850');
INSERT INTO "charsets" VALUES(105, 'ibm852');
INSERT INTO "charsets" VALUES(106, 'ibm855');
INSERT INTO "charsets" VALUES(107, 'ibm857');
INSERT INTO "charsets" VALUES(108, 'ibm862');
INSERT INTO "charsets" VALUES(109, 'ibm864');
INSERT INTO "charsets" VALUES(110, 'ibm866');
INSERT INTO "charsets" VALUES(111, 'iso-10646');
INSERT INTO "charsets" VALUES(112, 'iso-10646-j-1');
INSERT INTO "charsets" VALUES(113, 'iso-10646-ucs-2');
INSERT INTO "charsets" VALUES(114, 'iso-10646-ucs-4');
INSERT INTO "charsets" VALUES(115, 'iso-10646-ucs-basic');
INSERT INTO "charsets" VALUES(116, 'iso-10646-unicode-latin1');
INSERT INTO "charsets" VALUES(117, 'iso-2022-jp');
INSERT INTO "charsets" VALUES(118, 'iso-2022-jp-2');
INSERT INTO "charsets" VALUES(119, 'iso-2022-kr');
INSERT INTO "charsets" VALUES(120, 'iso-ir-100');
INSERT INTO "charsets" VALUES(121, 'iso-ir-101');
INSERT INTO "charsets" VALUES(122, 'iso-ir-103');
INSERT INTO "charsets" VALUES(123, 'iso-ir-110');
INSERT INTO "charsets" VALUES(124, 'iso-ir-126');
INSERT INTO "charsets" VALUES(125, 'iso-ir-144');
INSERT INTO "charsets" VALUES(126, 'iso-ir-149');
INSERT INTO "charsets" VALUES(127, 'iso-ir-159');
INSERT INTO "charsets" VALUES(128, 'iso-ir-58');
INSERT INTO "charsets" VALUES(129, 'iso-ir-6');
INSERT INTO "charsets" VALUES(130, 'iso646-us');
INSERT INTO "charsets" VALUES(131, 'jis_x0201');
INSERT INTO "charsets" VALUES(132, 'jis_x0208-1983');
INSERT INTO "charsets" VALUES(133, 'jis_x0212-1990');
INSERT INTO "charsets" VALUES(134, 'koi8-r');
INSERT INTO "charsets" VALUES(135, 'korean');
INSERT INTO "charsets" VALUES(136, 'ks_c_5601');
INSERT INTO "charsets" VALUES(137, 'ks_c_5601-1987');
INSERT INTO "charsets" VALUES(138, 'ks_c_5601-1989');
INSERT INTO "charsets" VALUES(139, 'ksc5601');
INSERT INTO "charsets" VALUES(140, 'ksc_5601');
INSERT INTO "charsets" VALUES(141, 'ms_kanji');
INSERT INTO "charsets" VALUES(142, 'shift_jis');
INSERT INTO "charsets" VALUES(143, 't.61');
INSERT INTO "charsets" VALUES(144, 't.61-8bit');
INSERT INTO "charsets" VALUES(145, 'unicode-1-1-utf-7');
INSERT INTO "charsets" VALUES(146, 'unicode-1-1-utf-8');
INSERT INTO "charsets" VALUES(147, 'unicode-2-0-utf-7');
INSERT INTO "charsets" VALUES(148, 'windows-31j');
INSERT INTO "charsets" VALUES(149, 'x-cns11643-1');
INSERT INTO "charsets" VALUES(150, 'x-cns11643-1110');
INSERT INTO "charsets" VALUES(151, 'x-cns11643-2');
INSERT INTO "charsets" VALUES(152, 'x-cp1250');
INSERT INTO "charsets" VALUES(153, 'x-cp1251');
INSERT INTO "charsets" VALUES(154, 'x-cp1253');
INSERT INTO "charsets" VALUES(155, 'x-dectech');
INSERT INTO "charsets" VALUES(156, 'x-dingbats');
INSERT INTO "charsets" VALUES(157, 'x-euc-jp');
INSERT INTO "charsets" VALUES(158, 'x-euc-tw');
INSERT INTO "charsets" VALUES(159, 'x-gb2312-11');
INSERT INTO "charsets" VALUES(160, 'x-imap4-modified-utf7');
INSERT INTO "charsets" VALUES(161, 'x-jisx0208-11');
INSERT INTO "charsets" VALUES(162, 'x-ksc5601-11');
INSERT INTO "charsets" VALUES(163, 'x-sjis');
INSERT INTO "charsets" VALUES(164, 'x-tis620');
INSERT INTO "charsets" VALUES(165, 'x-unicode-2-0-utf-7');
INSERT INTO "charsets" VALUES(166, 'x-x-big5');
INSERT INTO "charsets" VALUES(167, 'x0201');
INSERT INTO "charsets" VALUES(168, 'x0212');

INSERT INTO "syncObjectTypes" VALUES(1, 'collection');
INSERT INTO "syncObjectTypes" VALUES(2, 'creator');
INSERT INTO "syncObjectTypes" VALUES(3, 'item');
INSERT INTO "syncObjectTypes" VALUES(4, 'search');
INSERT INTO "syncObjectTypes" VALUES(5, 'tag');
INSERT INTO "syncObjectTypes" VALUES(6, 'relation');
