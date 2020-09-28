# NCDataManagement

manage the data on T: and L: for the different NC data folders related to NC activities (raw run data, NextCloud, Projects)

# Integrated solution
* **NCDataMngr**: bash toolbox to collect and store info about Folders on the various shares (a shiny viewer is also included as a template for future developments)

## **NCDataMngr action scripts**
Action scripts are commands that perform simple actions, they are launched by the main script **NCDataMngr** with or without extra parameters. The current Actions can be divided in several categories:

### Housekeeping and developer actions

* ActionDemo
"Shows a simple example for passing variables to an Action script"

* CreateEmptyDB
"Creates a sqlite2 database based on the dump file"

* DBListFields
"Shows a list of all fields defined in the DB tables (non *View tables); adding '-p details' shows the table design details"

* ListOptions
"Shows the list of all variables defined in 'run_config.yaml'"

* ShareStatus
"Shows the current usage of the share"

### T:/0003_Runs Storage scanning actions

* AddGridIonFolders
"Browses the T:/0003_Runs share and adds database records for new GridIon Run folders (identified by their name eg. YYYYMMDD_HHMM_DevicePOS_FlowcellID_Code)"

* AddIlluminaFolders
"Browses the T:/0003_Runs share and adds database records for new Illumina Run folders (identified by their name eg. 190807_7001450_0488_AH3HVFBCX3_exp3209)"

* AddPacbioFolders
"Browses the T:/0003_Runs share and adds database records for new Pacbio Run folders (identified by their name: r54094_YYYYMMDD_HHMMSS)"

### Storage modifying actions

* ArchiveFolder
"Creates a tgz archive of a Folder to prepare it for delivery"

* ArchiveSAV
"Extracts the SAV data from an Illumina Run-folder and archives it in IlluminaSavData"

* TransferFolder
"Moves a Folder from its current location to a new location on the Share provided as -p newloc=<full_share_path>"

* PreTrashFolder
"Moves a folder arrived at End Of Life into PreTrash where it will be deleted by a super-user"

### Database editing actions

* ChangeProtection
"Changes the protection status of a Folder record (value can be 0 for unprotected or 1 for protected)"

* UpdateFolderSize
"Adds or changes the size of a folder based on the data present in the DUC database"

* UpdateStatus
"Changes the status of a Folder record with one of the choices from 'allowed_status.yaml'"

# Utilities

Besides the integrated tools, additional utilities put here help admins and IT to manage our Storage.

* **getProjectsInfo**: script to collect date and size from folders on L:/Projects
