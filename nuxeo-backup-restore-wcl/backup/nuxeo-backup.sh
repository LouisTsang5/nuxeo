#!/bin/bash

# exit when any command fails
set -e
set -o pipefail

while getopts 'c:' OPT; do
    case $OPT in
        c) BACKUP_CONF="$OPTARG";;
    esac
done

#Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" #The absolution directory path of the script
DEFAULT_BACKUP_CONF="$SCRIPT_DIR/nuxeo-backup.conf"
TIMESTAMP=$(date '+%Y%m%d%H%M%S')
BACKUP_FILE_NAME=nuxeo-backup-$TIMESTAMP

#log function
log() {
  DATETIME=$(date '+%d/%m/%Y %H:%M:%S')
  echo "[$DATETIME] $1"
}

#exit function with message
exit1() {
  log "Exiting script with code 1"
  exit 1
}

exit0() {
  log "Exiting script with code 0"
  exit 0
}

#Check if config file is specified
if [ -z "$1" ]
  then
    log "No configuration file specified"
    BACKUP_CONF=$DEFAULT_BACKUP_CONF
  else
    log "Configuration file $BACKUP_CONF is specified"
fi

#Check if config file can be found
if [ ! -f "$BACKUP_CONF" ]
  then
    log "Configuration file $BACKUP_CONF does not exist"
    exit1
fi

#Read config file
log "Reading $BACKUP_CONF"
source $BACKUP_CONF
log "Database: $database_host:$database_port"
log "File Storage: $file_storage_dir"

#Check if nuxeo data directory exists
if [ -d $file_storage_dir ]
  then
    log "Directory $file_storage_dir exists"
  else
    log "Directory $file_storage_dir DOES NOT exist"
    exit1
fi

#Check if app server can reach database
if nc -z $database_host $database_port
  then
    log "Database can be reached"
  else
    log "Database CANNOT be reached"
    exit1
fi

#Check if backup server directory can be reached
if ssh $backup_server_user@$backup_server_host [ -d $backup_server_location ]
  then
    log "Backup server directory $backup_server_location exists"
  else
    log "Backup server directory $backup_server_location DOES NOT exist"
    exit1
fi

#backup database
log "Backing up database"
backup_server_location=${backup_server_location%/} #The dir location of backup server without the trailing "/"
TEMP_DB_BAK=$backup_server_location/$backup_database_file
mysqldump $database_name -h $database_host --port $database_port --single-transaction --quick --lock-tables=false -u $database_username --password=$database_password | ssh $backup_server_user@$backup_server_host "cat > $TEMP_DB_BAK"
log "Database backup completed"

#backup data files
log "Backing up file storage"
TEMP_FILE_BAK=$backup_server_location/$(basename $file_storage_dir)
scp -Cr $file_storage_dir $backup_server_user@$backup_server_host:$backup_server_location
log "File storage backup completed"

#pack the backup files
log "Packing backup"
BACKUP_PACK=$backup_server_location/$BACKUP_FILE_NAME$backup_pack_extension
ssh $backup_server_user@$backup_server_host tar -cf $BACKUP_PACK -C $backup_server_location $(basename $TEMP_DB_BAK) $(basename $TEMP_FILE_BAK)
ssh $backup_server_user@$backup_server_host rm $TEMP_DB_BAK
ssh $backup_server_user@$backup_server_host rm -r $TEMP_FILE_BAK

#Completed
log "Backup file $BACKUP_PACK created in backup server $backup_server_host"
exit0
