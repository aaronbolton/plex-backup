# plex-backup
Plex Backup Script based on plex running in a docker conatiner

Add to Cron for a daily backup e.g.

0 0 * * * root /mnt/backups/scripts/plex-backup-script.sh >/dev/null 2>&1
