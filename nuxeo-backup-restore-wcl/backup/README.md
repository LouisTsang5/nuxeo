#Nuxeo Docker Backup Script

This is a shell script that performs a backup of a nuxeo instance in a container and outputs a backup package. 
There are two components in this script, a shell script (***nuxeo-backup.sh***) and a config file (***nuxeo-backup.conf***)

The backup of a nuxeo instance takes two steps:
1. Backup of database
2. Backup of file storage

This shell script aims to perform the above actions automatically.

##Shell Script

The shell script runs on bash. Once called, the script performs the below actions:
1. Check and validate the config file
2. Backup the nuxeo database using ***mysqldump***
3. Make a copy of the file storage
4. Compress the database and file storage backup into one ***tar.gz*** backup package

The backup package produced can be used for automatic restoration.

##Config File

The config file stores settings of the nuxeo instance.
* The directory that stores the data files
* Information on the nuxeo database

##Script Execution

###Prerequisites

Please make sure the below conditions are met before running the script
* The nuxeo application is not running
* The database container is up and running

###Calling the Script

To call the script, run the below command
```shell
./nuxeo-backup.sh
```

Alternatively, if config file is located in another location, run the below command to specify the config file location.

Substitute ***<config_file>*** with the actual location of the config file
```shell
./nuxeo-backup.sh <config_file>
```

For example:
```shell
./nuxeo-backup.sh ~/nuxeo-backup.conf
```

###Script Output

After the script has executed successfully. 
A ***.tar.gz*** file should be created at the current directory.
A screen output similar to below should also be visible.
```shell
[05/10/2021 09:45:03] No configuration file specified
[05/10/2021 09:45:03] Reading /home/ubuntu/wcl-backup-restore/backup/nuxeo-backup.conf
[05/10/2021 09:45:03] Creating temp directory nuxeo-backup-20211005094503
[05/10/2021 09:45:03] Backing up database
mysqldump: [Warning] Using a password on the command line interface can be insecure.
[05/10/2021 09:45:04] Backing up data files
[05/10/2021 09:45:05] Compressing backup
[05/10/2021 09:45:07] Removing temp directory nuxeo-backup-20211005094503
[05/10/2021 09:45:07] Backup file nuxeo-backup-20211005094503.tar.gz created
[05/10/2021 09:45:07] Exiting script with code 0
```