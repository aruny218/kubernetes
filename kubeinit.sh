#!/bin/bash

#Kubernetes Cluster Initialization

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
sleep 30
i=120
while true ; do
kubectl get pods  --all-namespaces | grep kube-system | awk '{print $4}' | grep -v Running &>/dev/null
if [ $? -ne 0 ]; then
Stat 0 "Network Configuration Completed"
break
else
i=$(($i-1))
if [ $i -lt 0 ]; then
Stat 1 "Network Configuration Failed"
fi
continue
fi
done
hint "Join the nodes using the following command"
cat $LOG | /bin/grep join
