#!/bin/bash

# Kubernetes Master Setup

LOG=/tmp/kube-master.log
rm -f $LOG

## Source Common Functions
curl -s "https://raw.githubusercontent.com/linuxautomations/scripts/master/common-functions.sh" >/tmp/common-functions.sh
source /tmp/common-functions.sh

## Checking Root User or not.
CheckRoot

## Checking SELINUX Enabled or not.
CheckSELinux

## Checking Firewall on the Server.
CheckFirewall

## Setting Up Docker Repository.
DockerCERepo

## Installing Docker
yum install bind-utils http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.74-1.el7.noarch.rpm -y &>/dev/null
yum install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-18.06.1.ce-3.el7.x86_64.rpm  -y &>/dev/null

if [ $? -eq 0 ]; then
success "Installed Docker-CE Successfully"
else
error "Installing Docker-CE Failure"
exit 1
fi

## Create /etc/docker directory.
mkdir /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {
"max-size": "100m"
},
"storage-driver": "overlay2",
"storage-opts": [
"overlay2.override_kernel_check=true"
]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

## Starting Docker Service
systemctl enable docker &>/dev/null
systemctl restart docker &>/dev/null
if [ $? -eq 0 ]; then
success "Started Docker Engine Successfully"
else
error "Starting Docker Engine Failed"
exit 1
fi

#yum install docker -y &>>$LOG
#systemctl enable docker &>>$LOG
#systemctl start docker

