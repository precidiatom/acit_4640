#!/bin/bash

vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

NAT_NAME="net_4640"
VBOX_NAME="VM_ACIT4640"
PXE_NAME="PXE_4640"

clean_up() {
    vbmg natnetwork remove --netname $NAT_NAME
    vbmg unregistervm $VBOX_NAME --delete
	echo "GET RID OF $NAT_NAME and $VBOX_NAME IF IT EXISTS"
}
#Create the network and port forwarding rules
create_network(){
	vbmg natnetwork add --netname $NAT_NAME --network "192.168.250.0/24" --enable --dhcp off --ipv6 off
	vbmg natnetwork modify --netname $NAT_NAME --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
		--port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
		--port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443"\
		--port-forward-4 "ssh2:tcp:[]:50222:[192.168.250.200]:22"
	echo "CREATED THE NETWORK"
	}	
	
#Create the VM shells
create_VM() {
	vbmg createvm --name $VBOX_NAME --ostype "RedHat_64" --register
	vbmg modifyvm $VBOX_NAME --memory 1564 --cpus 1 --audio none \
	--nic1 natnetwork --nat-network1 $NAT_NAME --boot1 disk --boot2 net --boot3 none --boot4 none
	echo "VM created"
}


#Find the directory
create_VDI() {
	SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
	VBOX_FILE=$(vbmg showvminfo "$VBOX_NAME" | sed -ne "$SED_PROGRAM")
	VM_DIR=$(dirname "$VBOX_FILE")

	
	
#Create the vdi
	vbmg createmedium --filename "$VM_DIR/$VBOX_NAME.vdi" --format VDI --size 10000
	echo "$VM_DIR.vdi has been created at $VM_DIR"
}

create_controller () {
	vbmg storagectl $VBOX_NAME --name "SATA" --add sata --controller IntelAhci 
	#vbmg storagectl $VBOX_NAME --name "IDE" --add ide --controller PIIX4
	echo "Controllers created"
}

attach_controller() {
	#vbmg storageattach $VBOX_NAME --storagectl "IDE" --medium 'C:\Users\Precidia\Downloads\CentOS-7-x86_64-Minimal-1810.iso' --port 1 --device 0 --type dvddrive 
	vbmg storageattach $VBOX_NAME --storagectl "SATA" --medium "$VM_DIR/$VBOX_NAME.vdi" --port 0 --device 0 --type hdd 
	echo "Controllers attached"
	}
	
connect_pxe() {
	vbmg startvm $PXE_NAME
	while /bin/true; do
		ssh -i files/acit_admin_id_rsa -p 50222 -o ConnectTimeout=2 \
		-o StrictHostKeyChecking=no \
		-q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "PXE server is not up, sleeping..."
                sleep 2
        else
                break
        fi
		done
	echo "GIMMIE THE FILES"
}

copy_files(){
	ssh -i files/acit_admin_id_rsa -p 50222 admin@localhost "sudo chown admin /var/www/lighttpd/"
	ssh -i files/acit_admin_id_rsa -p 50222 admin@localhost "mkdir /var/www/lighttpd/files"
	scp -i files/acit_admin_id_rsa -P 50222 files/ks.cfg admin@localhost:/var/www/lighttpd/ks.cfg
	scp -i files/acit_admin_id_rsa -P 50222 files/acit_admin_id_rsa.pub admin@localhost:/var/www/lighttpd/files/acit_admin_id_rsa.pub
	scp -i files/acit_admin_id_rsa -P 50222 files/database.js admin@localhost:/var/www/lighttpd/files/database.js
	scp -i files/acit_admin_id_rsa -P 50222 files/nginx.conf admin@localhost:/var/www/lighttpd/files/nginx.conf
	scp -i files/acit_admin_id_rsa -P 50222 files/todoapp.service admin@localhost:/var/www/lighttpd/files/todoapp.service
	ssh -i files/acit_admin_id_rsa -p 50222 admin@localhost "sudo chmod 400 /var/www/lighttpd/files"
	ssh -i files/acit_admin_id_rsa -p 50222 admin@localhost "sudo chmod 755 /var/www/lighttpd/"

	echo "DONE COPYING FILES AND MODIFYING PERMISSIONS!!"

clean_up
create_network
create_VM
create_VDI
create_controller
attach_controller
/bin/chmod 400 files/acit_admin_id_rsa
connect_pxe
copy_files
vbmg startvm $VBOX_NAME
echo "CHECK OUT THE OS INSTALLATION ON $VBOX_NAME"
