#!/bin/bash
kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default
#
kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/metallb/metallb.yaml
#
kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/metallb/layer-2.yaml
#
kubectl label nodes k8s-node1 role=nfs
#
kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-deployment.yaml
#
kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-class.yaml
#
kubectl patch storageclass nfs-dynamic -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
#
kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/qseok/nfs-vol-pvc.yaml
#
rm -f /tmp/get_helm.sh
wget -O /tmp/get_helm.sh https://git.io/get_helm.sh
chmod +x /tmp/get_helm.sh
/tmp/get_helm.sh --version v2.13.1
#
kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/qseok/rbac-config.yaml
#
#
helm init --service-account tiller
sleep 20
helm repo add qlik https://qlik.bintray.com/stable
helm install -n qliksense-init qlik/qliksense-init
#
# wget https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/qseok/qseok-values.yaml
#
echo
echo "*** Please ensure to edit qseok-values.yaml to match your IdP configuration. ***"
echo
helm install -n qseok qlik/qliksense -f ./qseok-values.yaml
#