#!/bin/bash

start_m=`date +%M`
start_s=`date +%S`
echo "Script start: $start_m:$start_s"

now=$(date +"%m_%d_%Y-%H_%M")
plex_library_dir="/mnt/containers/media/plex/Library"
backup_dir="/mnt/backups/plexbackups"
num_backups_to_keep=28
emailaddress="touser@domain.com"
fromaddress="fromuser@domain.com"

docker stop plex
echo "Stopping plex"

sleep 30

plex_running=`docker inspect -f '{{.State.Running}}' plex`
echo "Plex running: $plex_running"

fail_counter=0
while [ "$plex_running" = "true" ];
do
    fail_counter=$((fail_counter+1))
    docker stop plex
    echo "Stopping Plex attempt #$fail_counter"
    sleep 30
    plex_running=`docker inspect -f '{{.State.Running}}' plex`
    # Exit with an error code if the container won't stop
    # Restart plex and report a warning to the Unraid GUI
    if (($fail_counter == 5));
    then
        echo "Plex failed to stop. Restarting container and exiting"
        docker start plex
         /usr/bin/echo "Plex Backup failed. Failed to stop container for backup." | /usr/sbin/sendmail -F "Plex Backup (Failed)" -f $fromaddress  $emailaddress
        exit 1
    fi
done

if [ "$plex_running" = "false" ]
then
    echo "Compressing and backing up Plex"
    cd $plex_library_dir
    tar -czf - Application\ Support/ -P | pv -s $(du -sb Application\ Support/ | awk '{print $1}') | gzip > $backup_dir/plex_backup_$now.tar.gz
    echo "Starting Plex"
    docker start plex
fi


num_files=`ls $backup_dir/plex_backup_*.tar.gz | wc -l`
echo "Number of files in directory: $num_files"
oldest_file=`ls -t $backup_dir/plex_backup_*.tar.gz | tail -1`
echo $oldest_file


if (($num_files > $num_backups_to_keep));
then
    echo "Removing file: $oldest_file"
    rm $oldest_file
fi

end_m=`date +%M`
end_s=`date +%S`
echo "Script end: $end_m:$end_s"

runtime_m=$((end_m-start_m))
runtime_s=$((end_s-start_s))
echo "Script runtime: $runtime_m:$runtime_s"
if [[ $? -eq 0 ]]; then
/usr/bin/echo "Plex Backup completed in $runtime_m:$runtime_s" | /usr/sbin/sendmail -F "Plex Backup (Success)" -f $fromaddress  $emailaddress
else
/usr/bin/echo "Plex Backup failed. See log for more details." | /usr/sbin/sendmail -F "Plex Backup (Failed)" -f $fromaddress  $emailaddress
fi
