/*
 Database structure for NCDataMngr and BigData_viewer
 Authors: Stéphane Plaisance - VIB-Nucleomics Core
          Thomas Standaert - VIB-Nucleopmics Core
 database version: 1.0 - 2020-10-20
 File Encoding : utf-8
 REM: edit CreateEmptyDB when you change the database schema
 dbversion="1.1"
 dbcreatedate=$(date)
 last edit 2020-10-20; version 1.2
*/

PRAGMA foreign_keys = false;

-- ----------------------------
--  Table structure for Actions
-- ----------------------------
DROP TABLE IF EXISTS "Actions";
CREATE TABLE "Actions" (
	 "FolderID" INTEGER NOT NULL,
	 "ActionID" INTEGER NOT NULL PRIMARY KEY,
	 "Creator" TEXT(255,0),
	 "CreatorVersion" TEXT(255,0),
	 "ActionDate" TEXT,
	 "ActionName" TEXT(255,0),
	 "Comment" TEXT(255,0),
	CONSTRAINT "Folders2Actions" FOREIGN KEY ("FolderID") REFERENCES "Folders" ("FolderID") ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY("FolderID") REFERENCES "NextCloud_Folders"("FolderID") ON DELETE CASCADE ON UPDATE CASCADE
);

-- ----------------------------
--  Table structure for Folders
-- ----------------------------
DROP TABLE IF EXISTS "Folders";
CREATE TABLE "Folders" (
	 "FolderID" INTEGER NOT NULL PRIMARY KEY,
	 "Creator" TEXT(255,0),
	 "CreatorVersion" TEXT(255,0),
	 "DBAddDate" TEXT(255,0),
	 "FolderPath" TEXT(255,0) NOT NULL,
	 "FolderName" TEXT(255,0) NOT NULL,
	 "FolderSize" INTEGER(20,0),
	 "Protection" INTEGER(1,0),
	 "DeviceModel" TEXT(255,0),
	 "StartDate" TEXT(255,0),
	 "DeviceID" TEXT(255,0),
	 "RunNr" TEXT(255,0),
	 "FlowCellID" TEXT(255,0),
	 "ProjectNR" TEXT(255,0),
	 "CustomField1" TEXT(255,0),
	 "CustomField2" TEXT(255,0),
	 "Status" TEXT(255,0),
	 "DeliveryDate" TEXT(255,0),
	 "Comment" TEXT(255,0)
);

-- --------------------------------------
--  Table structure for NextCloud_Folders
-- --------------------------------------
DROP TABLE IF EXISTS "NextCloud_Folders";
CREATE TABLE "NextCloud_Folders" (
	"FolderID"	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"FolderName"	TEXT NOT NULL UNIQUE,
	"FolderType"	TEXT NOT NULL CHECK("FolderType" IN ("Runs", "RawFastq", "PpProjects", "PreTrash", "Undetermined")),
	"FolderSize"	INTEGER NOT NULL,
	"ProjectNumber"	TEXT NOT NULL DEFAULT 'N/A',
	"Protection"	INTEGER NOT NULL DEFAULT 0,
	"LastDate"	INTEGER
);

-- ------------------------------
--  Table structure for Variables
-- ------------------------------
DROP TABLE IF EXISTS "Variables";
CREATE TABLE "Variables" (
	 "VarID" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	 "name" TEXT(255,0),
	 "value" TEXT(255,0)
);


-- ----------------------------
--  Table structure for version
-- ----------------------------
DROP TABLE IF EXISTS "version";
CREATE TABLE "version" (
	 "vnum" text,
	 "vdate" text
);


-- ----------------------------
--  set key initial values     -
-- ----------------------------

INSERT INTO "main".sqlite_sequence (name, seq) VALUES ("Actions", '0');
INSERT INTO "main".sqlite_sequence (name, seq) VALUES ("Folders", '0');
INSERT INTO "main".sqlite_sequence (name, seq) VALUES ("NextCloud_Folders", '20000');
/*BEGIN TRANSACTION;
UPDATE sqlite_sequence SET seq = 20000 WHERE name = 'NextCloud_Folders';
INSERT INTO sqlite_sequence (name,seq) SELECT 'NextCloud_Folders', 20000 WHERE NOT EXISTS 
           (SELECT changes() AS change FROM sqlite_sequence WHERE change <> 0);
COMMIT;*/
INSERT INTO "main".sqlite_sequence (name, seq) VALUES ("Variables", '0');
INSERT INTO "main".sqlite_sequence (name, seq) VALUES ("version", '0');

-- ----------------------------
--  View structure for ActionView
-- ----------------------------
DROP VIEW IF EXISTS "ActionView";
CREATE VIEW "ActionView" AS SELECT
Actions.*,
Folders.FolderPath,
Folders.FolderName
FROM
Actions
INNER JOIN Folders ON Folders.FolderID = Actions.FolderID
ORDER BY
Actions.FolderID ASC,
Actions.ActionID ASC;

-- ----------------------------
--  View structure for FolderView
-- ----------------------------
DROP VIEW IF EXISTS "FolderView";
CREATE VIEW "FolderView" AS SELECT
Folders.*
FROM
Folders
ORDER BY
Folders.FolderID ASC;

-- ----------------------------
--  Indexes structure for table Actions
-- ----------------------------
CREATE INDEX "idx_Actions_FolderID" ON Actions ("FolderID" ASC);
CREATE UNIQUE INDEX "idx_Actions_FolderID_ActionName" ON Actions ("FolderID" ASC, "ActionName");

-- ----------------------------
--  Indexes structure for table Folders
-- ----------------------------
CREATE UNIQUE INDEX "idx_Folders_FolderPath_FolderName" on Folders ( "FolderPath", "FolderName" );


PRAGMA foreign_keys = true;
