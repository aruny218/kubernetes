#!/bin/bash

#Kubernetes Cluster Initialization

#Log File
LOG=/tmp/kubeclusterini.log
rm -f $LOG

## Source Common Functions
curl -s "https://raw.githubusercontent.com/linuxautomations/scripts/master/common-functions.sh" >/tmp/common-functions.sh
source /tmp/common-functions.sh


sleep 30
i=120
while true ; do
kubectl get pods  --all-namespaces | grep kube-system | awk '{print $4}' | grep -v Running &>>$LOG
#kubectl get pods
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
