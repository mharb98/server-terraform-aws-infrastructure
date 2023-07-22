#!/bin/bash
# Use this for your user data (script from top to bottom)
yum update -y
yum -y install docker
service docker start
chmod 666 /var/run/docker.sock
docker pull marwanharb98/to-do-app
 
# install httpd (Linux 2 version)
# yum update -y
# yum install -y httpd
# systemctl start httpd
# systemctl enable httpd
# echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html