#!/bin/bash
# Use this for your user data (script from the top to the bottom)
# install httpd (Linux 2 version)
yum update -y
yum install httpd -y 
systemctl start httpd
systemctl enable httpd
mkdir /var/www/html/target2
echo "<h1>Hello word from target_2 $(hostname -f)<h1>" > /var/www/html/target2/index.html