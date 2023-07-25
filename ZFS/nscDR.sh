#!/bin/bash

#NSC DR Install Script
#Installs software and preps ZFS

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
    echo "Building pool01"
    zpool create pool01 raidz2 /dev/sdc /dev/sdd /dev/sde /dev/sdg #Put disks in /dev/sda /dev/sdab /dev/sde /dev/sdf
    echo "Building metadata pool"
    zpool add pool01 -f special mirror /dev/sdf #Put disks in here /dev/sdc /dev/sdb
    zfs set dedup=off pool01
    echo "Building dataset NSCC"
    zfs create pool01/NSCC
    echo "pool01 built, see output below..."
    echo "Building dataset vmBackup with 10TB quota"
    zfs create pool01/vmBackup
    zfs set quota=10T pool01/vmBackup
    mkdir /pool01/NSCC/01
    sleep 1
    zpool list -v pool01
    #zfs set acltype=posixacl pool01/NSCC
    #zfs set xattr=sa pool01/NSCC
    #zfs set aclinherit=passthrough pool01/NSCC
    #zfs set acltype=posixacl pool01/vmBackup
    #zfs set xattr=sa pool01/vmBackup
    #zfs set aclinherit=passthrough pool01/vmBackup
    echo ' '
}


SAMBA() {

#NOTE - if running this is test mode please change the netbios name in the below config

    echo -e '\e[34m Installing Samba...\e[0m'
	apt-get install winbind libpam-winbind libnss-winbind krb5-config samba-dsdb-modules samba-vfs-modules samba -y > /dev/null 2>&1
	mv /etc/samba/smb.conf /etc/samba/smb.conf.Backup
    echo "Building smb.conf file"
    echo "[global]" > /etc/samba/smb.conf
    echo "kerberos method = secrets and keytab" >> /etc/samba/smb.conf
    echo "realm = SPACECENTRE.LOCAL" >> /etc/samba/smb.conf
    echo "workgroup = SPACECENTRE" >> /etc/samba/smb.conf
    echo "netbios name = nsccdr" >> /etc/samba/smb.conf
    echo "security = ads" >> /etc/samba/smb.conf
    echo "template shell = /bin/bash" >> /etc/samba/smb.conf
    echo "kerberos method = secrets only" >> /etc/samba/smb.conf
    echo "winbind use default domain = true" >> /etc/samba/smb.conf
    echo "idmap config * : rangesize = 1000000" >> /etc/samba/smb.conf
    echo "idmap config * : range = 1000000-19999999" >> /etc/samba/smb.conf
    echo "idmap config * : backend = autorid" >> /etc/samba/smb.conf
    echo "vfs objects = fruit streams_xattr acl_xattr" >> /etc/samba/smb.conf
    echo "fruit:metadata = stream" >> /etc/samba/smb.conf
    echo "fruit:model = MacSamba" >> /etc/samba/smb.conf
    echo "fruit:posix_rename = yes" >> /etc/samba/smb.conf
    echo "fruit:veto_appledouble = no" >> /etc/samba/smb.conf
    echo "fruit:nfs_aces = no" >> /etc/samba/smb.conf
    echo "fruit:wipe_intentionally_left_blank_rfork = yes" >> /etc/samba/smb.conf
    echo "fruit:delete_empty_adfiles = yes" >> /etc/samba/smb.conf
    echo " " >> /etc/samba/smb.conf
    echo " " >> /etc/samba/smb.conf
    echo " " >> /etc/samba/smb.conf
    echo " " >> /etc/samba/smb.conf
    echo " " >> /etc/samba/smb.conf
    echo "[01]" >> /etc/samba/smb.conf
    echo "path = /pool01/NSCC/01" >> /etc/samba/smb.conf
    echo "read only = no" >> /etc/samba/smb.conf
    echo "guest only = no" >> /etc/samba/smb.conf
    echo "guest ok = no" >> /etc/samba/smb.conf
    echo "printable = no" >> /etc/samba/smb.conf
    echo "browseable = yes" >> /etc/samba/smb.conf
    echo "force create mode = 0666" >> /etc/samba/smb.conf
    echo "force directory mode = 0666" >> /etc/samba/smb.conf


    sed -i 's/passwd:         files systemd/passwd:         files systemd winbind/' /etc/nsswitch.conf
    sed -i 's/group:          files systemd/group:          files systemd winbind/' /etc/nsswitch.conf
    systemctl enable winbind > /dev/null 2>&1
    echo -e '\e[34mJoining the domain SPACECENTRE.LOCAL\e[0m'
    net ads join -U mattb.da spacecentre.local
    systemctl restart winbind
    chown mattb.da:'production group' /pool01/NSCC/01
    chmod 770 /pool01/NSCC/01
    systemctl restart smbd
		setfacl -M /root/acl.txt /pool01/NSCC/01
    echo ' '

}

SYNCTHING() {
    echo "Installing syncthing"
    apt-get install curl -y > /dev/null 2>&1
    curl -o /usr/share/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | tee /etc/apt/sources.list.d/syncthing.list
    apt-get update > /dev/null 2>&1
    apt-get install syncthing -y > /dev/null 2>&1
    echo "[Unit]" >> /etc/systemd/system/syncthing@.service
    echo "Description=Syncthing - Open Source Continuous File Synchronization for %I" >> /etc/systemd/system/syncthing@.service
    echo "Documentation=man:syncthing(1)" >> /etc/systemd/system/syncthing@.service
    echo "After=network.target" >> /etc/systemd/system/syncthing@.service
    echo "" >> /etc/systemd/system/syncthing@.service
    echo "[Service]" >> /etc/systemd/system/syncthing@.service
    echo "User=%i" >> /etc/systemd/system/syncthing@.service
    echo "ExecStart=/usr/bin/syncthing -no-browser -gui-address="0.0.0.0:8384" -no-restart -logflags=0" >> /etc/systemd/system/syncthing@.service
    echo "Restart=on-failure" >> /etc/systemd/system/syncthing@.service
    echo "SuccessExitStatus=3 4" >> /etc/systemd/system/syncthing@.service
    echo "RestartForceExitStatus=3 4" >> /etc/systemd/system/syncthing@.service
    echo "" >> /etc/systemd/system/syncthing@.service
    echo "[Install]" >> /etc/systemd/system/syncthing@.service
    echo "WantedBy=multi-user.target" >> /etc/systemd/system/syncthing@.service
    systemctl daemon-reload
    systemctl start syncthing@root
    systemctl enable syncthing@root.service
}

POSTFIX() {
    apt-get install postfix
    pt-get install sasl2-bin mailutils bsd-mailx -y
    mv /etc/postfix/main.cf /etc/postfix/main.cf.backup
    cp /root/main.cf /etc/postfix/

}

KVM() {
    echo -e '\e[34m Installing KVM...\e[0m'
    echo "This will take awhile!"
    apt-get install qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils libguestfs-tools genisoimage virtinst libosinfo-bin virt-manager libvirt-daemon -y > /dev/null 2>&1


    echo ''
}

ICINGA() {
    echo -e '\e[34m Installing Icinga...\e[0m'
    apt-get install apache2 mariadb-server php libapache2-mod-php php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip php-cli php-mysql php-common php-opcache php-pgsql php-gmp php-imagick -y > /dev/null 2>&1
        sed -i 's/;date.timezone =/date.timezone = Europe/London/' /etc/php/7.4/apache2/php.ini
        sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/7.4/apache2/php.ini
        systemctl restart apache2
        mysql_secure_installation
        apt-get install icinga2 monitoring-plugins -y > /dev/null 2>&1
        echo 'Starting Icinga'
        systemctl enable icinga2 > /dev/null 2>&1
        systemctl start icinga2
        apt-get install icinga2-ido-mysql -y
        icinga2 feature enable ido-mysql
        systemctl restart icinga2
        apt-get install icingaweb2 icingacli -y > /dev/null 2>&1
        #mysql -u root -p --execute="CREATE DATABASE icingaweb2;GRANT ALL PRIVILEGES ON icingaweb2.* TO icingaweb2@localhost IDENTIFIED BY '$password';"
}

ZABBIX() {
    echo ''
    echo 'Installing Zabbix'
    echo 'Some user input needed in a sec...'
    echo ''
    apt-get install apache2 php php-mysql php-mysqlnd php-ldap php-bcmath php-mbstring php-gd php-pdo php-xml libapache2-mod-php -y > /dev/null 2>&1
    apt-get install mariadb-server mariadb-client -y > /dev/null 2>&1
    echo 'Follow doc here - https://markontech.com/linux/install-zabbix-on-debian/'
    mysql_secure_installation
    
    
    
    wget https://repo.zabbix.com/zabbix/5.4/debian/pool/main/z/zabbix-release/zabbix-release_5.4-1+debian11_all.deb
    dpkg -i zab*.deb > /dev/null 2>&1
    apt-get update > /dev/null 2>&1
    apt-get install zabbix-server-mysql zabbix-frontend-php zabbix-agent -y > /dev/null 2>&1
    zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -u zabbix -p zabbix
    

}




CLEANUP() {
	echo "All done!"

}


MAIN() {

    #read -sp 'Enter DA User: ' DA
    echo -e '\e[33m
███╗   ██╗███████╗ ██████╗    ██████╗ ██████╗     ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗
████╗  ██║██╔════╝██╔════╝    ██╔══██╗██╔══██╗    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║
██╔██╗ ██║███████╗██║         ██║  ██║██████╔╝    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║
██║╚██╗██║╚════██║██║         ██║  ██║██╔══██╗    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║
██║ ╚████║███████║╚██████╗    ██████╔╝██║  ██║    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
╚═╝  ╚═══╝╚══════╝ ╚═════╝    ╚═════╝ ╚═╝  ╚═╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
\e[0m'

   UPDATE #Working
   BASICSOFTWARE #Working
   ZFSDEBIAN #Needs testing again
   SAMBA # Working
   #POSTFIX
   #KVM
   #ICINGA NOT WORKING - maybe take this out to do it manually?
   #ZABBIX #Needs testing
   CLEANUP

}

MAIN

#EOF

#NOTES:
#
#Once set up drop into root and chnage the owner on the NSCC dir with chown mattb:'production group' /pool01/NSCC. Then update ACLs with chmod 776 /pool01/NSCC/

TODO:

Cron up a scrub job at 2am on a sunday morning once a week



