!/bin/bash

kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default
kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/metallb/metallb.yaml
kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/metallb/layer-2.yaml
kubectl label nodes k8s-node1 role=nfs
kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-class.yaml
kubectl patch storageclass nfs-dynamic -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
curl -LO https://git.io/get_helm.sh
chmod +x get_helm.sh
./get_helm.sh --version v2.13.1
kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/qseok/rbac-config.yaml
helm init --service-account tiller
helm repo add qlik https://qlik.bintray.com/stable
wget https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/qseok/qseok-values.yaml
helm install -n qliksense-init qlik/qliksense-init
helm install -n qliksense qlik/qliksense -f ./qseok-values.yaml
vim ./qseok-values.yaml
helm upgrade --install qliksense qlik/qliksense -f ./qseok-values.yaml

