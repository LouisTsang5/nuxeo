#Nuxeo Docker Restore Script

This is a shell script the performs a restoration of a nuxeo instance in a container with a provided backup package.
There are two components in this scrip, a shell script (***nuxeo-restore.sh***) and a config file (***nuxeo-restore.conf***)

The restoration of a nuxeo instance takes three steps:
1. Restoration of database
2. Restoration of file storage
3. Reindex with elasticsearch

The shell script aims to perform the above actions automatically.

##Shell Script

The shell script runs on bash.
Once called, the script performs the below actions:
1. Check and validate the config file
2. Unzip the provided backup package
3. Restore the database using the ***.sql*** file within the backup package
4. Delete the current file storage directory
5. Copy and paste the backup file storage to the file storage directory
6. Turn on the nuxeo instance via ***docker-compose***
7. Send an ***HTTP*** request to the nuxeo instance to regenerate the elasticsearch index

The nuxeo instance can be turned off once the elasticsearch index is generated.

##Config File

The config file stores settings for the restoration procedure.
* The nuxeo application URL
* The login credentials of the nuxeo instance
* The docker-compose file location
* The file storage directory
* The nuxeo database information
* The setting of the backup package (No need to be changed)
* General setting of the restoration procedure (No need to be changed)

##Script Execution

###Prerequisites

Please make sure the below conditions are met before running the script
* The nuxeo application is not running
* The database container is up and running
* The backup package is ready (a ***.tar.gz*** file)
* The nuxeo application can be reached via ***HTTP*** (i.e. ***http://localhost:8080***)

###Calling the script
To call the script, run the below command and substitute ***<backup_package>*** with the actual backup package
```shell
./nuxeo-restore.sh <backup_package>
```

For example:
```shell
./nuxeo-restore.sh nuxeo-backup-20211005075204.tar.gz
```

Alternatively, if the config file is located in another location, run the below command to specify the config file location. 

Substitute ***<backup_package>*** with the actual backup package and ***<config_file>*** with the actual location of the config file
```shell
./nuxeo-restore.sh <backup_package> <config_file>
```

For example:
```shell
./nuxeo-restore.sh nuxeo-backup-20211005075204.tar.gz ~/nuxeo-restore.conf
```

###Script Output

After the script has executed successfully.
A screen output similar to below should also be visible.
```shell
[05/10/2021 09:51:45] No configuration file specified
[05/10/2021 09:51:45] Reading /home/ubuntu/wcl-backup-restore/restore/nuxeo-restore.conf
[05/10/2021 09:51:45] Decompressing backup file
[05/10/2021 09:51:46] Restoring database
mysql: [Warning] Using a password on the command line interface can be insecure.
[05/10/2021 09:52:09] Restoring data files
[05/10/2021 09:52:09] Starting nuxeo docker compose
mysql is up-to-date
Starting docker-build-openjdk-wcl_multitool_1 ... done
Starting nuxeo                                ... done
Starting mailhog                              ... done
Starting elasticsearch                        ... done
[05/10/2021 09:52:11] Trying to connect to nuxeo
[05/10/2021 09:52:11] Connection failed (100 seconds before timeout)
[05/10/2021 09:52:13] Connection failed (98 seconds before timeout)
[05/10/2021 09:52:15] Connection failed (96 seconds before timeout)
[05/10/2021 09:52:17] Connection failed (94 seconds before timeout)
[05/10/2021 09:52:19] Connection failed (92 seconds before timeout)
[05/10/2021 09:52:21] Connection failed (90 seconds before timeout)
[05/10/2021 09:52:23] Connection failed (88 seconds before timeout)
[05/10/2021 09:52:25] Connection failed (86 seconds before timeout)
[05/10/2021 09:52:27] Connection failed (84 seconds before timeout)
[05/10/2021 09:52:29] Connection failed (82 seconds before timeout)
[05/10/2021 09:52:31] Connection failed (80 seconds before timeout)
[05/10/2021 09:52:33] Connection failed (78 seconds before timeout)
[05/10/2021 09:52:35] Connection failed (76 seconds before timeout)
[05/10/2021 09:52:37] Connection failed (74 seconds before timeout)
[05/10/2021 09:53:10] Connection established
[05/10/2021 09:53:10] Sending request to regenerate elasticsearch index
[05/10/2021 09:53:12] Done
[05/10/2021 09:53:12] Nuxeo restoration completed. Nuxeo can be stopped once the elasticsearch index has been regenerated
[05/10/2021 09:53:12] Exiting script with code 0
```