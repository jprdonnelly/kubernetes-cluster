# Kubernetes cluster
A [Vagrant](https://www.vagrantup.com/) script for setting up a barebones [Kubernetes](https://kubernetes.io/) cluster with a [load-balancer](https://metallb.universe.tf) and [dynamic provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs) using [Kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/).

### Pre-requisites

 * **[Vagrant 2.1.4+](https://www.vagrantup.com)**
 * **[Virtualbox 5.2.18+](https://www.virtualbox.org)**

### Start the Base Cluster

Run the following command using CMD/Powershell in the dir where your [Vagrantfile](https://github.com/jprdonnelly/kubernetes-cluster/blob/master/Vagrantfile "Vagrantfile") lives.

```bash
vagrant up
```

* *When this command finishes you will have (4) running VMs joined together as a K8s cluster.*
* If more than three worker nodes are required, you can edit the servers array in the Vagrantfile

```ruby
servers = [
    {
        :name => "k8s-node3",
        :type => "node",
        :box => "ubuntu/bionic64",
        :eth1 => "192.168.205.13",
        :mem => "2048",
        :cpu => "2"
    }
]
 ```
 
* As you can see above, you can also configure a static IP address, memory and CPU in the servers array. 

### Check Cluster Health

```pwsh
PS> vagrant ssh k8s-head
Welcome to Ubuntu 18.04.1 LTS (GNU/Linux 4.15.0-38-generic x86_64)
 
<snip output>
```

```bash
vagrant@k8s-head:~$ kubectl cluster-info
Kubernetes master is running at https://192.168.205.10:6443
KubeDNS is running at https://192.168.205.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
 
To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
 
vagrant@k8s-head:~$ kubectl get nodes
NAME        STATUS   ROLES    AGE   VERSION
k8s-head    Ready    master   68m   v1.15.2
k8s-nfs     Ready    <none>   53m   v1.15.2
k8s-node1   Ready    <none>   65m   v1.15.2
k8s-node2   Ready    <none>   61m   v1.15.2
```
### Install NFS Provisioner

```bash
vagrant@k8s-head:~$ kubectl label nodes k8s-nfs role=nfs
node/k8s-nfs labeled
 
vagrant@k8s-head:~$ kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-deployment.yaml
service/nfs-provisioner created
deployment.apps/nfs-provisioner created
 
vagrant@k8s-head:~$ kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-class.yaml
storageclass.storage.k8s.io/nfs-dynamic created
vagrant@k8s-head:~$ kubectl get svc
NAME              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                              AGE
kubernetes        ClusterIP   10.96.0.1        <none>        443/TCP                              18m
nfs-provisioner   ClusterIP   10.109.234.184   <none>        2049/TCP,20048/TCP,111/TCP,111/UDP   11s
 
vagrant@k8s-head:~$ kubectl patch storageclass nfs-dynamic -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
storageclass.storage.k8s.io/nfs-dynamic patched
 
```

### Clean-up

Execute the following command to remove the virtual machines created for the Kubernetes cluster.

```bash
vagrant destroy -f
```

You can destroy individual machines by 

```bash
vagrant destroy k8s-node3 -f
```

##### Licensing

[Apache License, Version 2.0](http://opensource.org/licenses/Apache-2.0).
