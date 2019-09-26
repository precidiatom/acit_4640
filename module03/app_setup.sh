#this script will run on the VM
#installs and makes sure everything is ocuring in Virtual machine setup
#run as root user
#note to self, yum update then save snapshot

#!/bin/bash -x

#create user
useradd admin -G wheel
echo "P@ssw0rd" | passwd --stdin admin

#create shh folder if no exist 
mkdir ~admin/.ssh/authorized_keys
chown admin:wheel /home/admin/.ssh/authorized_keys/acit_admin_id_rsa.pub

#create SSH key
yum -y install wget
wget -P ~admin/.ssh/authorized_keys "https://acit4640.y.vu/docs/module02/resources/acit_admin_id_rsa.pub"

sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers

yum -y install epel-release vim git tcpdump curl net-tools bzip2
yum -y update

firewall-cmd --zone=public --add-service=ssh
firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-service=https
firewall-cmd --runtime-to-permanent

setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

#service user
useradd -m -r todo-app && passwd -l todo-app
yum -y install nodejs npm
yum -y install mongodb-server
systemctl enable mongod && systemctl start mongod

#application setup as todo user
su - todo-app
mkdir app
cd app
git clone https://github.com/timoguic/ACIT4640-todo-app.git .
npm install
chmod
#CHANGE APP FOLDER TO CHMOD 755
#edit config/database.js
#sed somehtingsomething
#or copy the file over
#or somehow edit the file lmao

#install nginx NEED TO BE ROOT - SO REARRANGE THE SCRIPT TO YUM INSTALL EVERYTHING FIRST
yum -y install nginx
#enable nginxs 
systemctl enable nginx && systemctl start ngnix

#create custom daemon
#systemctl enable todoapp
#systemctl start todoapp