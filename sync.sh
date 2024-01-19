#!/bin/bash
## One-way, immediate, continuous, recursive, directory synchronization
##  to a remote Rclone URL. ( S3, SFTP, FTP, WebDAV, Dropbox, etc. )
## Optional desktop notifications on sync events or errors.
## Useful only for syncing a SMALL number of files (< 8192).
##  (See note in `man inotifywait` under `--recursive` about raising this limit.)
## Think use-case: Synchronize Traefik TLS certificates file (acme.json)
## Think use-case: Synchronize Keepass (.kdbx) database file immediately on save.
## Think use-case: Live edit source code and push to remote server

## This is NOT a backup tool!
## It will not help you if you delete your files or if they become corrupted.
## If you need a backup tool, check out https://blog.rymcg.tech/blog/linux/restic_backup

## Setup: Install `rclone` and `inotify-tools` from package manager.
## Run: `rclone config` to setup the remote, including the full remote
##   subdirectory path to sync to.
## MAKE SURE that the remote (sub)directory is EMPTY
##   or else ALL CONTENTS WILL BE DELETED by rclone when it syncs.
## If unsure, add `--dry-run` to the RCLONE_CMD variable below,
##   to simulate what would be copied/deleted.
## Enable your user for Systemd Linger: sudo loginctl enable-linger $USER
## (Reference https://wiki.archlinux.org/title/Systemd/User#Automatic_start-up_of_systemd_user_instances)
## Copy this script any place on your filesystem, and make it executable: `chown +x sync.sh`
## Edit all the variables below, before running the script.
## Run: `./sync.sh systemd_setup` to create and enable systemd service.
## Run: `journalctl --user --unit rclone_sync.${RCLONE_REMOTE}` to view the logs.
## For desktop notifications, make sure you have installed a notification daemon (eg. dunst)

## Edit the variables below, according to your own environment:

# RCLONE_SYNC_PATH: The path to COPY FROM (files are not synced TO here):
RCLONE_SYNC_PATH="/data"

# RCLONE_CMD: The sync command and arguments:
## (This example is for one-way sync):
## (Consider using other modes like `bisync` or `move` [see `man rclone` for details]):
RCLONE_CMD="rclone ${RCLONE_CMD}"

# WATCH_EVENTS: The file events that inotifywait should watch for:
WATCH_EVENTS="modify,delete,create,move"

# SYNC_DELAY: Wait this many seconds after an event, before synchronizing:
SYNC_DELAY=${SYNC_DELAY}

# SYNC_INTERVAL: Wait this many seconds between forced synchronizations:
SYNC_INTERVAL=${SYNC_INTERVAL}

# NOTIFY_ENABLE: Enable Desktop notifications
NOTIFY_ENABLE=true

# SYNC_SCRIPT: dynamic reference to the current script path
SYNC_SCRIPT=$(realpath $0)

notify() {
    MESSAGE=$1
    if test ${NOTIFY_ENABLE} = "true"; then
        echo "rclone" "${MESSAGE}"
    fi
}

rclone_sync() {
    set -x
    # Do initial sync immediately:
    notify "Startup"
    ${RCLONE_CMD} /data ${DESTINATION}
    # Watch for file events and do continuous immediate syncing
    # and regular interval syncing:
    while [[ true ]] ; do
	inotifywait --recursive --timeout ${SYNC_INTERVAL} -e ${WATCH_EVENTS} \
		    ${RCLONE_SYNC_PATH} 2>/dev/null
	if [ $? -eq 0 ]; then
	    # File change detected, sync the files after waiting a few seconds:
	    sleep ${SYNC_DELAY} && ${RCLONE_CMD} /data ${DESTINATION} && \
		notify "Synchronized new file changes"
	elif [ $? -eq 1 ]; then
	    # inotify error occured
	    notify "inotifywait error exit code 1"
        sleep 10
	elif [ $? -eq 2 ]; then
	    # Do the sync now even though no changes were detected:
	    ${RCLONE_CMD} /data ${DESTINATION}
	fi
    done
}

rclone_sync
