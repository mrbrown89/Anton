#!/bin/bash

TODAY=$(date +%d-%m-%y)

for i in $(zfs list -H -o name -t snapshot)
    if #snapshot is older than 10 days. How to work that out?
        do zfs destroy $i;
done





#!/bin/bash

keep=10
num_snaps=$(zfs list -t snapshot -o name -S creation | grep -Po '@autozsys_[a-zA-Z0-9]+$' | uniq | wc -l)
printf "Found %d autosys versions. Configured to keep %d.\n" $num_snaps $keep
if [[ $num_snaps -le $keep ]]; then
    printf "no need to prune.\n"
    exit 0
fi

num_to_prune=$(( num_snaps - keep ))
printf "Pruning %d zsys versions.\n" $num_to_prune
if [[ $num_to_prune -le 0 ]]; then
    printf "Error - no snapshots to prune.\n"
    exit 127
fi

if [[ $num_to_prune -ge $num_snaps ]]; then
    printf "Error - won't remove all snapshots.\n"
    exit 127
fi


for zsys_snap in $(zfs list -t snapshot -o name -S creation | grep -Po '@autozsys_[a-zA-Z0-9]+$' | uniq | tail -n $num_to_prune); do
    printf "Removing $zsys_snap\n"
    zfs list -t snapshot -o name | grep "${zsys_snap}$" | xargs -n 1 zfs destroy -vr
done

