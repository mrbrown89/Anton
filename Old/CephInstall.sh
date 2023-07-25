#!/bin/bash

UPDATE() {
    echo "Running base updates..."
    apt-get update > /dev/null 2>&1
    apt-get upgrade -y > /dev/null 2>&1
    apt-get install curl wget screen > /dev/null 2>&1
}

CEPHINSTALL() {
    sudo apt-get install ceph ceph-mds -y > /dev/null 2>&1
    curl --silent --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm
}




MAIN() {
    UPDATE
    
}



MAIN
