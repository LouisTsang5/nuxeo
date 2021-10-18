#!/bin/bash

# exit when any command fails
set -e

while getopts 'b:c:k:' OPT; do
    case $OPT in
        b) BACKUP_FILE="$OPTARG";;
        k) DECRYPT_KEY="$OPTARG";;
        c) RESTORE_CONF="$OPTARG";;
    esac
done

#Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" #The absolution directory path of the script
BACKUP_DIR=${BACKUP_FILE%%.*}
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

#Check if decryption key is specified
if [ -z "$DECRYPT_KEY" ]
  then
    log "No decryption key specified"
    exit1
fi

#Check if decryption key can be found
if [ ! -f "$DECRYPT_KEY" ]
  then
    log "Decryption key $DECRYPT_KEY does not exist"
    exit1
fi

#Check if config file is specified
if [ -z "$RESTORE_CONF" ]
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
log "Database: $database_host:$database_port"
log "File Storage: $file_storage_dir"

#Check if nuxeo data directory exists
if ssh $nuxeo_app_user@$nuxeo_app_host [ -d $file_storage_dir ]
  then
    log "Directory $file_storage_dir exists"
  else
    log "Directory $file_storage_dir DOES NOT exist"
    exit1
fi

#Check if app server can reach database
if ssh $nuxeo_app_user@$nuxeo_app_host nc -z $database_host $database_port
  then
    log "Database can be reached"
  else
    log "Database CANNOT be reached"
    exit1
fi

#Unpackage backup
log "Unpacking backup"
BACKUP_FILE=$(realpath $BACKUP_FILE)
BACKUP_FILE_NAME=$(basename $BACKUP_FILE) #the base filename of the backup package e.g. nuxeo-backup-202110100000.tar.gz
BACKUP_FILE_TAG=${BACKUP_FILE_NAME%%.*} #The tag name of the backup e.g. nuxeo-backup-202110100000
TEMP_DIR=$BACKUP_FILE_TAG
mkdir $TEMP_DIR && tar -zxvf $BACKUP_FILE --directory $TEMP_DIR
TEMP_DIR=$(realpath $TEMP_DIR)

#Decrypt backup
log "Decrypting backup"
DECRYPT_KEY=$(realpath $DECRYPT_KEY)
ENC_KEY_ENC=$TEMP_DIR/$BACKUP_FILE_TAG$encrypted_key_extension              #The encrypted encryption key
ENC_KEY=$TEMP_DIR/$BACKUP_FILE_TAG$key_extension                            #The decrypted encryption key
BACKUP_PACK_ENC=$TEMP_DIR/$BACKUP_FILE_TAG$encrypted_backup_pack_extension  #The encrypted backup package
BACKUP_PACK=$TEMP_DIR/$BACKUP_FILE_TAG$backup_pack_extension                #The decrypted backup package
openssl rsautl -decrypt -in $ENC_KEY_ENC -out $ENC_KEY -inkey $DECRYPT_KEY
openssl enc -$backup_encryption_cipher -in $BACKUP_PACK_ENC -out $BACKUP_PACK -d -pass pass:$(cat $ENC_KEY) -pbkdf2

#Unzip backup file
log "Decompressing backup file"
tar -zxf $BACKUP_PACK --directory $TEMP_DIR

#Restore database
log "Restoring database"
cat $TEMP_DIR/$backup_database_file | ssh $nuxeo_app_user@$nuxeo_app_host mysql -h $database_host --port $database_port -u $database_username --password=$database_password $database_name
log "Database restoration Completed"

#Restore data files
log "Restoring data files"
log "Removing current file data"
ssh $nuxeo_app_user@$nuxeo_app_host rm -r ${file_storage_dir%/}/*
log "Unpacking new file data"
scp -Cr $TEMP_DIR/$backup_nuxeo_data_package/* $nuxeo_app_user@$nuxeo_app_host:${file_storage_dir%/}/
log "File storage restoration completed"

#Clean up temp files
log "removing temp files"
rm -r $TEMP_DIR

#Ask user to regenerate index
log "Nuxeo restoration completed. Please run the below command to regenerate elastic search index when nuxeo is up"
log "curl -X POST \"$nuxeo_app_url/nuxeo/site/automation/Elasticsearch.Index\" -u $nuxeo_app_admin_username:$nuxeo_app_admin_password -H 'content-type: application/json' -d '{\"params\":{},\"context\":{}}'"
exit0