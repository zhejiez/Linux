#!/bin/bash
sudo ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa -q
sudo yum install -y epel-release
sudo yum update -y
sudo yum -y install python-pip sshpass 
sudo pip install -r /opt/k3s/str/requirements.txt 
sudo cp -r /opt/k3s/str/ansible /etc  