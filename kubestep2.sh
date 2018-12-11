#!/bin/bash

#Installing Kubernetes and setup network

#Log File
LOG=/tmp/kubeinstall.log
rm -f $LOG

## Source Common Functions
curl -s "https://raw.githubusercontent.com/linuxautomations/scripts/master/common-functions.sh" >/tmp/common-functions.sh
source /tmp/common-functions.sh

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

kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU &>$LOG
cat $LOG | /bin/grep join
STAT=$?
Stat $? "Initializing Kubernetes Cluster"

mkdir -p $HOME/.kube
rm $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml &>/dev/null
Stat $? "Setting Up Flanneld Network"
