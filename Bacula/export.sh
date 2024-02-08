#!/bin/bash

#Script to tar ball the boot strap files and DB files to an exports folder and then export it somewhere


LOG=/Pool01/Bacula/Exports/logs/$(date +\%Y-\%m-\%d).log

MKDIR(){
    mkdir /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d)
}

COPY(){
    cp -r /opt/bacula/etc/ /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d)
    cp -r /Pool01/Bacula/BootStrap/* /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d)
    cp -r /Pool01/Bacula/Exports/dailyBackup/$(date +\%Y-\%m-\%d --date="1 days ago") /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d)
}

TAR(){
    tar -cvf /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d).tar.gz /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d) | tee -a $LOG
    CODE=${PIPESTATUS[0]}
    case $CODE in
    0) echo "TAR succsessful" | tee -a $LOG;;
    *) echo "TAR failed" | tee -a $LOG;;
    esac
    cp /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d).tar.gz /Pool01/WeeklyBackups/
    chown matt:'it group' /Pool01/WeeklyBackups/$(date +\%Y-\%m-\%d).tar.gz
}

EXPORT() {
    echo "Exporting $(date +\%Y-\%m-\%d --date="1 days ago")" | tee -a $LOG
    CODE=${PIPESTATUS[0]}
    case $CODE in
    0) SLACKMESSAGE="Weekly Export Successful.";;
    *) SLACKMESSAGE="Export Failed.";;
    esac
    SLACK
}

MAIN() {
    echo $(date +\%Y-\%m-\%d) | tee -a $LOG
    MKDIR
    COPY
    TAR
    #EXPORT
    echo "Export Complete for $(date +\%Y-\%m-\%d)" | tee -a $LOG
}

MAIN
