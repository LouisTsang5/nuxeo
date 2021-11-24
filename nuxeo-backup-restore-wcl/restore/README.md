#Nuxeo Docker Restore Script

This is a shell script the performs a restoration of a nuxeo instance with a provided backup package.
There are two components in this scrip, a shell script (***nuxeo-restore.sh***) and a config file (***nuxeo-restore.conf***)

The restoration of a nuxeo instance takes three steps:
1. Restoration of database
2. Restoration of file storage
3. Reindex with elasticsearch

The shell script aims to perform the above actions automatically.

The script is designed to run from the backup storage machine. The script pushes the backup data into the nuxeo instance via ssh.

##Shell Script

The shell script runs on bash.
Once called, the script performs the below actions:
1. Check and validate the config file
2. Unpack the provided backup package
3. Restore the database using the ***.sql*** file within the backup package
4. Delete the current file storage directory
5. Copy and paste the backup file storage to the file storage directory

**Once the script has finished executing, the nuxeo server should be started and a reindex HTTP request should be sent to the nuxeo instance.**

##Config File

The config file stores settings for the restoration procedure.
* The nuxeo application URL
* The file storage directory
* The nuxeo database information
* The setting of the backup package (No need to be changed)
* General setting of the restoration procedure (No need to be changed)

##Script Execution

###Prerequisites

Please make sure the below conditions are met before running the script
* The nuxeo application is not running
* The database container is up and running
* The backup package is ready (a ***.tar*** file)
* ***mysql*** is installed in the nuxeo server
* The ssh port is open in the nuxeo server
* The nuxeo application can be reached via ***HTTP*** (i.e. ***http://localhost:8080***)

###Calling the script
To call the script, run the below command and substitute ***<backup_package>*** with the actual backup package
```shell
sudo ./nuxeo-restore.sh -b <backup_package>
```

For example:
```shell
sudo ./nuxeo-restore.sh -b nuxeo-backup-20211005075204.tar.gz
```

Alternatively, if the config file is located in another location, run the below command to specify the config file location. 

Substitute ***<backup_package>*** with the actual backup package and ***<config_file>*** with the actual location of the config file
```shell
sudo ./nuxeo-restore.sh -b <backup_package> -c <config_file>
```

For example:
```shell
sudo ./nuxeo-restore.sh -b nuxeo-backup-20211005075204.tar.gz -c ~/nuxeo-restore.conf
```

###Script Output

After the script has executed successfully.
A screen output similar to below should also be visible.
```shell
[24/11/2021 17:26:38] No configuration file specified
[24/11/2021 17:26:38] Reading /media/ubuntu/MyPassport/IntranetNuxeoBackup/restore/nuxeo-restore.conf
[24/11/2021 17:26:38] Database: 127.0.0.1:3306
[24/11/2021 17:26:38] File Storage: /home/ubuntu/docker-build-openjdk-wcl/data/
[24/11/2021 17:26:38] Directory /home/ubuntu/docker-build-openjdk-wcl/data/ exists
[24/11/2021 17:26:39] Database can be reached
[24/11/2021 17:26:39] Unpacking backup
[24/11/2021 17:26:42] Restoring database
mysql: [Warning] Using a password on the command line interface can be insecure.
[24/11/2021 17:27:18] Database restoration Completed
[24/11/2021 17:27:18] Restoring data files
[24/11/2021 17:27:18] Removing current file data
[24/11/2021 17:27:18] Unpacking new file data
BulkBucket-0xCC59A5FF2725F7AF.avsc                                                                 100%  308   244.5KB/s   00:00
BulkCommand-0xD302D0A636171185.avsc                                                                100% 1028   714.1KB/s   00:00
...
20211101.cq4                                                                                       100% 5120KB 128.6MB/s   00:00
metadata.cq4t                                                                                      100%   64KB  45.1MB/s   00:00
[24/11/2021 17:27:27] File storage restoration completed
[24/11/2021 17:27:27] removing temp files
[24/11/2021 17:27:27] Nuxeo restoration completed. Please run the below command to regenerate elastic search index when nuxeo is up
[24/11/2021 17:27:27] curl -X POST "http://132.148.160.186:8080/nuxeo/site/automation/Elasticsearch.Index" -u Administrator:Administrator -H 'content-type: application/json' -d '{"params":{},"context":{}}'                                                               ator -H 'content-type: application/json' -d '{"params":{},"context":{}}'
[24/11/2021 17:27:27] Exiting script with code 0
```