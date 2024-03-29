#!/bin/bash

install_apps() {
	yum -y install wget
	yum -y install epel-release vim git tcpdump curl net-tools bzip2
	yum -y install nodejs npm
	yum -y install mongodb-server
	yum -y install nginx
	yum -y update
}

setup_firewall() {
	firewall-cmd --zone=public --add-service=ssh
	firewall-cmd --zone=public --add-service=http
	firewall-cmd --zone=public --add-service=https
	firewall-cmd --runtime-to-permanent
}

enable_services() {
	systemctl enable mongod && systemctl start mongod
	systemctl enable todoapp && systemctl start todoapp
	systemctl enable nginx && systemctl start nginx

}
install_apps
setup_firewall

setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
git clone https://github.com/precidiatom/acit_4640.git .
#create user
useradd admin -G wheel
echo "P@ssw0rd" | passwd --stdin admin

#create shh folder if no exist 
mkdir /home/admin/.ssh/authorized_keys

#create SSH key
wget -P ~admin/.ssh/authorized_keys "https://acit4640.y.vu/docs/module02/resources/acit_admin_id_rsa.pub"
chown admin:wheel /home/admin/.ssh/authorized_keys/acit_admin_id_rsa.pub

sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers

#service user
useradd -m -r todo-app && passwd -l todo-app

#application setup as todo user
runuser -l todo-app -c "mkdir app"
git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app
npm install /home/todo-app/app
chmod -R 755 /home/todo-app/
/bin/cp -rf acit_4640/module03/files/database.js ~todo-app/app/config/database.js
/bin/cp -rf acit_4640/module03/files/nginx.conf /etc/nginx/nginx.conf
nginx -s reload

/bin/cp -rf acit_4640/module03/files/todoapp.service /lib/systemd/system/todoapp.service
systemctl daemon-reload

enable_services
