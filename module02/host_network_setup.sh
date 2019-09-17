#!/bin/bash -x

vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

NAT_NAME="net_4640"

#Create the network and port forwarding rules
vbmg natnetwork add --netname $NAT_NAME --network "192.168.250.0/24" --enable --dhcp off --ipv6 off
vbmg natnetwork modify --netname $NAT_NAME --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443"

