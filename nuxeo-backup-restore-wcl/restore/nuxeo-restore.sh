#!/bin/bash

#Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" #The absolution directory path of the script
BACKUP_FILE=$1
BACKUP_DIR=${BACKUP_FILE%%.*}
RESTORE_CONF=$2
DEFAULT_RESTORE_CONF=$SCRIPT_DIR/nuxeo-restore.conf

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

#Check if backup file is specified
if [ -z "$BACKUP_FILE" ]
  then
    log "No backup file specified"
    exit1
fi

#Check if backup file can be found
if [ ! -f "$BACKUP_FILE" ]
  then
    log "Backup file $BACKUP_FILE does not exist"
    exit1
fi

#Check if config file is specified
if [ -z "$2" ]
  then
    log "No configuration file specified"
    RESTORE_CONF=$DEFAULT_RESTORE_CONF
  else
    log "Configuration file $RESTORE_CONF is specified"
fi

#Check if config file can be found
if [ ! -f "$RESTORE_CONF" ]
  then
    log "Configuration file $RESTORE_CONF does not exist"
    exit1
fi

#Read config file
log "Reading $RESTORE_CONF"
source $RESTORE_CONF

#Check if nuxeo data directory exists
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

#Unzip backup file
log "Decompressing backup file"
tar -zxf $BACKUP_FILE

#Restore database
log "Restoring database"
cat $BACKUP_DIR/$backup_database_file | ssh $database_ssh_username@$database_ssh_host docker exec -i $database_container /usr/bin/mysql -u $database_username --password=$database_password $database_name
log "Database restoration Completed"

#Restore data files
log "Restoring data files"
log "Sending file data to storage"
scp -r $BACKUP_DIR/$backup_nuxeo_data_package $file_storage_username@$file_storage_host:${file_storage_dir%/}/..
log "Removing current file data"
ssh $file_storage_username@$file_storage_host rm -r $file_storage_dir/*
log "Unpacking new file data"
ssh $file_storage_username@$file_storage_host tar -zxvf ${file_storage_dir%/}/../$backup_nuxeo_data_package -C ${file_storage_dir%/}/..
log "Removing package"
ssh $file_storage_username@$file_storage_host rm ${file_storage_dir%/}/../$backup_nuxeo_data_package
log "File storage restoration completed"

#Start nuxeo docker-compose to regen index
log "Starting nuxeo docker compose"
ssh -q $file_storage_username@$file_storage_host "cd $(dirname $nuxeo_docker_compose) && docker-compose up -d"
log "Nuxeo docker compose started"

#Try to connect to nuxeo
TRY_START_SEC=$SECONDS
log "Trying to connect to nuxeo"
until $(curl --output /dev/null --silent --head --fail $nuxeo_host_url); do
  #If timed out. Ask the user to manual reindex
  if [ $(($SECONDS - $TRY_START_SEC)) -gt $reindex_trial_timeout ]
    then
      log "Failed to connect to nuxeo. Please run the below command to regenerate elastic search index when nuxeo is up"
      log "curl -X POST \"$nuxeo_host_url/nuxeo/site/automation/Elasticsearch.Index\" -u $nuxeo_admin_username:$nuxeo_admin_password -H 'content-type: application/json' -d '{\"params\":{},\"context\":{}}'"
      exit1
  fi

  log "Connection failed ($(($reindex_trial_timeout - $(($SECONDS - $TRY_START_SEC)))) seconds before timeout)"
  sleep $reindex_trial_interval
done
log "Connection established"

#Regeneration Elastic Search Index
log "Sending request to regenerate elasticsearch index"
curl -X POST "$nuxeo_host_url/nuxeo/site/automation/Elasticsearch.Index" -u $nuxeo_admin_username:$nuxeo_admin_password -H 'content-type: application/json' -d '{"params":{},"context":{}}'
log "Done"

#Completed
log "Nuxeo restoration completed. Nuxeo can be stopped once the elasticsearch index has been regenerated"
exit0