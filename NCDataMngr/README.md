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
  "Creates a sqlite2 database based on the dump file defined in 'run_config.yaml' as '${CONF_database_dump}'"

* DBListFields
  "Shows a list of all fields defined in the DB tables (non *View tables); adding '-p details' shows the table design details"

* ListFunctions
  "list custom functions in shared/*_functions.sh files"

* ListOptions
  "Shows the list of all variables defined in 'run_config.yaml'"

### T:/0003_Runs Storage scanning actions

* ShareStatus
  "Shows the current usage of the share defined in 'run_config.yaml' as '${CONF_mount_point}/${CONF_mount_path}'; adding '-p <subfolder>' allows going deeper (eg -p NovaSeq6000)"

* AddGridIonFolders
  "Browses '${CONF_mount_point}/${CONF_mount_path}' and adds database records for new GridIon Run folders (identified by their name eg. YYYYMMDD_HHMM_DevicePOS_FlowcellID_Code_expXXXX)"

* AddIlluminaFolders
  "Browses '${CONF_mount_point}/${CONF_mount_path}' and adds database records for new Illumina Run folders (identified by their name eg. 190807_7001450_0488_AH3HVFBCX3_exp3209)"

* AddPacbioFolders
  "Browses '${CONF_mount_point}/${CONF_mount_path}' and adds database records for new Pacbio Run folders (identified by their name: r54094_YYYYMMDD_HHMMSS_expXXXX)"

* UpdateAllFolderSizes
  "Scans all folderpath/foldername from DB in DUC and adapt their size in DB if changed"

### Storage modifying actions

* Folder2archive
  "Creates a tgz archive of a complete Folder into '${CONF_mount_archivepath}' defined in 'run_config.yaml' to prepare it for delivery"

* SAV2archive
  "Extracts the SAV data from an Illumina Run-folder and archives it in '${CONF_mount_savpath}' defined in 'run_config.yaml'"

### Database editing actions

* SetDeliveryDate
  "Sets the Delivery Date for a Folder (the folder was provided to the customer)"

* SetFolderStatus
  "Changes the status of a Folder record with one of the choices from 'allowed_status.yaml'"

* SetProjectNumber
  "Sets the ProjectNumber(s) associated with a Folder (if more than one, use '-' eg. 'exp1234-exp1245')"

* SetProtection
  "Changes the protection status of a Folder record (value can be 0 for unprotected or 1 for protected)"

# Utilities

Besides the integrated tools, additional utilities put here help admins and IT to manage our Storage.

* **getProjectsInfo**: script to collect date and size from folders on L:/Projects
