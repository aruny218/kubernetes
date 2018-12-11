#!/bin/bash

#Installing Kubernetes and setup network
LOG=/tmp/kubeinstall.log
rm -f $LOG


cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

setenforce 0

sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes &>>$LOG
Stat $? "Installing Kubelet Service"

systemctl enable kubelet  &>/dev/null
systemctl start kubelet &>>$LOG
Stat $? "Starting Kubelet Service"


cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

echo '[Ip_Forward]
net.ipv4.ip_forward = 1' > /etc/sysctl.conf

systemctl restart network
sysctl --system &>> $LOG
Stat $? "Updating Network Configuration"

sed -i "s/cgroup-driver=systemd/cgroup-driver=cgroupfs/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl daemon-reload &>/dev/null
systemctl restart kubelet &>>$LOG
Stat $? "Retarting Kubelet Service"
