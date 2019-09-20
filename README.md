# Kubernetes cluster
A [Vagrant](https://www.vagrantup.com/) script for setting up a barebones [Kubernetes](https://kubernetes.io/) cluster with a [load-balancer](https://metallb.universe.tf) and [dynamic provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs) using [Kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/).

### Pre-requisites

 * **[Vagrant 2.2.4+](https://www.vagrantup.com)**
 * **[Virtualbox 6+](https://www.virtualbox.org)**
 * **[Virtualbox Proprietary Extension Pack](https://download.virtualbox.org/virtualbox/6.0.12/Oracle_VM_VirtualBox_Extension_Pack-6.0.12.vbox-extpack)**

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
vagrant@k8s-head:~$ kubectl taint nodes k8s-nfs key=value:NoSchedule
node/k8s-nfs tainted
```

```bash
vagrant@k8s-head:~$ kubectl apply -f \
https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-helm-pvc.yaml
persistentvolume/nfs-provisioner-vol created
```

```bash
vagrant@k8s-head:~$ helm install -n nfs stable/nfs-server-provisioner \
-f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-helm-values.yaml
NAME:   nfs
LAST DEPLOYED: Mon Sep  9 12:59:26 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/ClusterRole
NAME                        AGE
nfs-nfs-server-provisioner  1s

==> v1/ClusterRoleBinding
NAME                        AGE
nfs-nfs-server-provisioner  1s

==> v1/Pod(related)
NAME                          READY  STATUS   RESTARTS  AGE
nfs-nfs-server-provisioner-0  0/1    Pending  0         1s

==> v1/Service
NAME                        TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)                                 AGE
nfs-nfs-server-provisioner  ClusterIP  10.105.237.23  <none>       2049/TCP,20048/TCP,51413/TCP,51413/UDP  1s

==> v1/ServiceAccount
NAME                        SECRETS  AGE
nfs-nfs-server-provisioner  1        1s

==> v1/StorageClass
NAME                   PROVISIONER            AGE
nfs-dynamic (default)  provisioner.local/nfs  1s

==> v1beta2/StatefulSet
NAME                        READY  AGE
nfs-nfs-server-provisioner  0/1    1s


NOTES:
The NFS Provisioner service has now been installed.

A storage class named 'nfs-dynamic' has now been created
and is available to provision dynamic volumes.

You can use this storageclass by creating a `PersistentVolumeClaim` with the
correct storageClassName attribute. For example:

    ---
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: test-dynamic-volume-claim
    spec:
      storageClassName: "nfs-dynamic"
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 100Mi
```

```bash
vagrant@k8s-head:~$ kubectl apply -f \
https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-class.yaml
storageclass.storage.k8s.io/nfs-dynamic configured
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
