/*
 Database structure for NCDataMngr and BigData_viewer
 Author: Stéphane Plaisance - VIB-Nucleomics Core
 database version: 1.0 - 2020-09-11
 File Encoding         : utf-8
 REM: edit below if you change the database schema
 => INSERT INTO "version" (vnum, vdate) VALUES ("1.0", "2020-09-11");
*/

PRAGMA foreign_keys = false;

-- ----------------------------
--  Table structure for custom
-- ----------------------------
DROP TABLE IF EXISTS "Variables";
CREATE TABLE "Variables" (
	 "VarID" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	 "name" TEXT(255,0),
	 "value" TEXT(255,0)
);
INSERT INTO "main".sqlite_sequence (name, seq) VALUES ("Variables", '0');

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
INSERT INTO "main".sqlite_sequence (name, seq) VALUES ("Folders", '0');

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
	CONSTRAINT "Folders2Actions" FOREIGN KEY ("FolderID") REFERENCES "Folders" ("FolderID") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "main".sqlite_sequence (name, seq) VALUES ("Actions", '0');

-- ----------------------------
--  Table structure for version
-- ----------------------------
DROP TABLE IF EXISTS "version";
CREATE TABLE "version" (
	 "vnum" text,
	 "vdate" text
);
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
--  Indexes structure for table Folders
-- ----------------------------
CREATE UNIQUE INDEX "idx_Folders_FolderPath_FolderName" on Folders ( "FolderPath", "FolderName" );

-- ----------------------------
--  Indexes structure for table Actions
-- ----------------------------
CREATE INDEX "idx_Actions_FolderID" ON Actions ("FolderID" ASC);
CREATE UNIQUE INDEX "idx_Actions_FolderID_Creator" ON Actions ("FolderID" ASC, "Creator");

PRAGMA foreign_keys = true;
