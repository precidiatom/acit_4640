#!/bin/bash -x

vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

NAT_NAME="net_4640"
VBOX_NAME="VM_ACIT4640"

#Create the VM shells
create_VM() {
	vbmg createvm --name $VBOX_NAME --ostype "RedHat_64" --register
	vbmg modifyvm $VBOX_NAME --memory 1024 --cpus 1 --audio none --nic1 natnetwork --nat-network1 $NAT_NAME
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
	vbmg storagectl $VBOX_NAME --name "IDE" --add ide --controller PIIX4
	echo "Controllers created"
}

attach_controller() {
	vbmg storageattach $VBOX_NAME --storagectl "IDE" --medium 'C:\Users\Precidia\Downloads\CentOS-7-x86_64-Minimal-1810.iso' --port 1 --device 0 --type dvddrive 
	vbmg storageattach $VBOX_NAME --storagectl "SATA" --medium "$VM_DIR/$VBOX_NAME.vdi" --port 0 --device 0 --type hdd 
	echo "Controllers attached"
	}

create_VM
create_VDI
create_controller
attach_controller
