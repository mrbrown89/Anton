#!/bin/bash

MAIN(){
    SLACKCHANNEL="anton"
    SLACKUSERNAME="Anton"
    SLACKEMOJI=":nas:"
    SLACKWEBHOOK=https://hooks.slack.com/services/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

    ONLINE=$(zpool list -v Pool01 | grep -i ONLINE |wc -l)
    DEGRADED=$(zpool list -v Pool01 | grep -i DEGRADED |wc -l)
    FAULTED=$(zpool list -v Pool01 | grep -i FAULTED |wc -l)
    OFFLINE=$(zpool list -v Pool01 | grep -i OFFLINE |wc -l)
    UNAVAIL=$(zpool list -v Pool01 | grep -i UNAVAIL |wc -l)
    REMOVED=$(zpool list -v Pool01 | grep -i REMOVED |wc -l)
    SNAPSHOTS=$(zfs list -t snapshot | grep -i pool | wc -l)


    SLACKMESSAGE="Health Check:\n Disks online: $ONLINE\n Disks degraded $DEGRADED\n Disks faulted: $FAULTED\n Disks offline $OFFLINE\n Disks unavailable $UNAVAIL\n Disks removed: $REMOVED\n Number of snapshots $SNAPSHOTS"
    SLACKPAYLOAD="payload={\"channel\": \"$SLACKCHANNEL\", \"username\": \"$SLACKUSERNAME\", \"text\": \"$SLACKMESSAGE\", \"icon_emoji\": \"$SLACKEMOJI\"}"

    curl -X POST --data-urlencode "$SLACKPAYLOAD" "$SLACKWEBHOOK"
}

MAIN
