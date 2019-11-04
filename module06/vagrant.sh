#!/bin/bash

firewall-cmd --zone=public --add-service=ssh
firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-service=https
firewall-cmd --runtime-to-permanent

setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

#service user
useradd -m -r todoapp && passwd -l todoapp

#application setup as todo user
runuser -l todoapp -c "mkdir app"
git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todoapp/app

/bin/cp -rf /home/admin/nginx.conf /etc/nginx/nginx.conf
/bin/cp -rf /home/admin/database.js /home/todoapp/app/config/database.js
/bin/cp -rf /home/admin/todoapp.service /lib/systemd/system/todoapp.service
npm install --prefix /home/todoapp/app
chmod -R 755 /home/todoapp/
nginx -s reload

systemctl daemon-reload
systemctl enable mongod && systemctl restart mongod
systemctl enable todoapp && systemctl restart todoapp
systemctl enable nginx && systemctl restart nginx