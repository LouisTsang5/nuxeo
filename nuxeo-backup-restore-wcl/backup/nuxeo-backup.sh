#!/bin/bash

#Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" #The absolution directory path of the script
BACKUP_CONF=$1
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

#Check if nuxeo data directory does not exists
if ssh $file_storage_username@$file_storage_host [ ! -d $file_storage_dir ]
  then
    log "Directory $file_storage_dir does not exist"
    exit1
fi

#Check if database container exists
if [ -z "$(ssh $database_ssh_username@$database_ssh_host docker container ls -a | grep $database_container)" ]
  then
    log "Database container $database_container does not exist"
    exit1
fi

#Check if database container is running
if [ $(ssh $database_ssh_username@$database_ssh_host docker container inspect -f '{{.State.Running}}' $database_container) != "true" ]
  then
    log "Database container $database_container is not running"
    exit1
fi

#create temp directory
log "Creating temp directory $BACKUP_FILE_NAME"
mkdir $BACKUP_FILE_NAME

#backup database
log "Backing up database"
ssh $database_ssh_username@$database_ssh_host docker exec $database_container /usr/bin/mysqldump $database_name --single-transaction --quick --lock-tables=false -u $database_username --password=$database_password > $BACKUP_FILE_NAME/backup.sql
log "Database backup completed"

#backup data files
log "Backing up file storage"
log "Packing files"
ssh $file_storage_username@$file_storage_host "cd ${file_storage_dir%/}/.. && tar -zcvf $(basename $file_storage_dir).tar.gz $(basename $file_storage_dir)"
log "Copying packed files"
scp -r $file_storage_username@$file_storage_host:${file_storage_dir%/}.tar.gz $BACKUP_FILE_NAME
log "Removing file package from server"
ssh $file_storage_username@$file_storage_host rm ${file_storage_dir%/}.tar.gz
log "File storage backup completed"

#pack the backup files
log "Compressing backup"
tar -zcf $BACKUP_FILE_NAME.tar.gz $BACKUP_FILE_NAME

#remove the temp directory
log "Removing temp directory $BACKUP_FILE_NAME"
rm -r $BACKUP_FILE_NAME

#Completed
log "Backup file $BACKUP_FILE_NAME.tar.gz created"
exit0
