#!/bin/bash

#Use this script to rebuild Anton in the event the OS disk fails
#First buidl the Linux server out and make sure the JBOD is connected
#and all metadata disks and cache disks are connected


RED='\033[0;31m'
NOCOLOUR='\033[0m'

UPDATE() {
    echo "Running base updates..."
    apt-get update > /dev/null 2>&1
    apt-get upgrade -y > /dev/null 2>&1

}


BASICSOFTWARE() {
    apt-get install screen wget curl acl pip ifenslave nfs-kernel-server rpcbind mailutils smartmontools -y > /dev/null 2>&1
    #pip install pyzsnap > /dev/null 2>&1 <- testing


}

ZFSDEBIAN() {
    echo "Adding ZFS Repo"
    #codename=$(lsb_release -cs);echo "deb http://deb.debian.org/debian $codename-backports main contrib non-free"|sudo tee -a /etc/apt/sources.list
    echo "deb http://deb.debian.org/debian bullseye-backports main contrib non-free" | tee -a /etc/apt/sources.list > /dev/null 2>&1
    apt-get update -y > /dev/null 2>&1
    echo "Installing kernal headers"
    apt-get install linux-headers-amd64 -y > /dev/null 2>&1
    echo "Installing ZFS. This will take a few mins"
    sleep 3
    apt-get install -t bullseye-backports zfsutils-linux zfs-zed -y
    echo ' '
    echo ' '
    echo ' '
    echo -e '\e[34m ZFS installed. Installing some ZFS extras.\e[0m'
    echo ' '
    echo ' '
    echo ' '
    apt-get install zfs-zed zfsnap -y > /dev/null 2>&1
    echo "Importing Pool01"
    zfs import -f Pool01
    }
    
SAMBA(){
        echo -e '\e[34m Installing Samba...\e[0m'
    apt-get install winbind libpam-winbind libnss-winbind krb5-config samba-dsdb-modules samba-vfs-modules samba -y > /dev/null 2>&1
    mv /etc/samba/smb.conf /etc/samba/smb.conf.Backup
    cp /Pool01/Configs/samba/smb.conf /etc/samba/
    sed -i 's/passwd:         files systemd/passwd:         files systemd winbind/' /etc/nsswitch.conf
    sed -i 's/group:          files systemd/group:          files systemd winbind/' /etc/nsswitch.conf
    systemctl enable winbind > /dev/null 2>&1
    echo -e '\e[34mJoining the domain SPACECENTRE.LOCAL\e[0m'
    net ads join -U mattb.da spacecentre.local
    systemctl restart winbind
    systemctl restart smbd
    echo ''
    }
    
    
