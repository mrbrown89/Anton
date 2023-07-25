#!/bin/bash

#Script to tar ball the boot strap files and DB files to an exports folder and then export it somewhere


LOG=/Pool01/Bacula/Exports/logs/$(date +\%Y-\%m-\%d).log

SLACK() {
    SLACKCHANNEL="anton"
    SLACKUSERNAME="Anton"
    SLACKEMOJI=":nas:"
    SLACKWEBHOOK=https://hooks.slack.com/services/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
    SLACKPAYLOAD="payload={\"channel\": \"anton\", \"username\": \"$SLACKUSERNAME\", \"text\": \"$SLACKMESSAGE\", \"icon_emoji\": \"$SLACKEMOJI\"}"
    curl -X POST --data-urlencode "$SLACKPAYLOAD" "$SLACKWEBHOOK"
}

MKDIR(){
    mkdir /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d)
}

COPY(){
    cp -r /opt/bacula/etc/ /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d)
    cp /Pool01/Bacula/Exports/dailyBackup/$(date +\%Y-\%m-\%d --date="1 days ago") /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d)
}

TAR(){
    tar -cvf /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d).tar.gz /Pool01/Bacula/Exports/tar/$(date +\%Y-\%m-\%d) | tee -a $LOG
    CODE=${PIPESTATUS[0]}
    case $CODE in
    0) echo "TAR succsessful" | tee -a $LOG;;
    *) echo "TAR failed" | tee -a $LOG;;
    esac
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
    TAR
    EXPORT
    echo "Export Complete for $(date +\%Y-\%m-\%d)" | tee -a $LOG
}

MAIN
