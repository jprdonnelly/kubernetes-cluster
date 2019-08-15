# -*- mode: ruby -*-
# vi: set ft=ruby :

servers = [
    {
        :name => "k8s-head",
        :type => "master",
        :box => "ubuntu/bionic64",
        :eth1 => "192.168.205.10",
        :mem => "3200",
        :cpu => "2"
    },
    {
        :name => "k8s-node1",
        :type => "node",
        :box => "ubuntu/bionic64",
        :eth1 => "192.168.205.11",
        :mem => "4224",
        :cpu => "2",
        # :nfs => "true"
    },
    {
        :name => "k8s-node2",
        :type => "node",
        :box => "ubuntu/bionic64",
        :eth1 => "192.168.205.12",
        :mem => "4224",
        :cpu => "2",
    },
    {
      :name => "k8s-nfs",
      :type => "nfs",
      :box => "ubuntu/bionic64",
      :eth1 => "192.168.205.14",
      :mem => "2176",
      :cpu => "1"
    },
# Uncomment section below to enable a 3rd worker node.
    # {
    #   :name => "k8s-node3",
    #   :type => "node",
    #   :box => "ubuntu/bionic64",
    #   :eth1 => "192.168.205.13",
    #   :mem => "4224",
    #   :cpu => "2",
    # }
]

$configureBox = <<-SCRIPT
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  sudo bash -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
  deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF'

export VERSION=18.09 && curl -sSL get.docker.com | sh

# Setup daemon.
  sudo bash -c 'cat <<EOF> /etc/docker/daemon.json 
  {
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
      "max-size": "100m"
  },
  "storage-driver": "overlay2"
  }
EOF'

    # sudo snap install --classic kubelet
    # sudo snap install --classic kubeadm
    # sudo snap install --classic kubectl

    sudo mkdir -p /etc/systemd/system/docker.service.d

    # Restart docker.
    sudo systemctl daemon-reload
    sudo systemctl restart docker

    # run docker commands as vagrant user (sudo not required)
    sudo usermod -aG docker vagrant

    # Set time to ensure IdP works
    sudo ntpdate pool.ntp.org 

    # kubelet requires swap off
    sudo swapoff -a

    # keep swap off after reboot
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

    echo "libssl1.1 libssl1.1/restart-services boolean true" | sudo debconf-set-selections

    sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
    sudo apt install -y ntpdate nmap netcat neofetch socat apt-transport-https ca-certificates curl software-properties-common nfs-common sshpass kubelet kubeadm kubectl kubernetes-cni

    # ip of this box
    IP_ADDR=`ifconfig enp0s8 | grep mask | awk '{print $2}'| cut -f2 -d:`
    # set node-ip
    sudo echo "KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDR" >> /etc/default/kubelet
    echo "source <(kubectl completion bash)" >> /home/vagrant/.bashrc
    echo "echo" >> /home/vagrant/.bashrc
    echo "echo" >> /home/vagrant/.bashrc
    echo "/usr/bin/neofetch" >> /home/vagrant/.bashrc
    echo "echo" >> /home/vagrant/.bashrc
    echo "echo" >> /home/vagrant/.bashrc

    # # Update apt sources to avoid 404s, do so non-interactively to deal with libssl
    # # 
    # echo "libssl1.1 libssl1.1/restart-services boolean true" | sudo debconf-set-selections
    # sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    # # sudo DEBIAN_FRONTEND=noninteractive sudo dpkg-reconfigure -a
SCRIPT

$configureMaster = <<-SCRIPT
    echo "################################################################"
    echo "Configuring as master node"
    echo "################################################################"
    # ip of this box
    IP_ADDR=`ifconfig enp0s8 | grep mask | awk '{print $2}'| cut -f2 -d:`

    # install k8s master node
    HOST_NAME=$(hostname -s)
    kubeadm init --apiserver-advertise-address=$IP_ADDR --apiserver-cert-extra-sans=$IP_ADDR  --node-name $HOST_NAME --pod-network-cidr=172.16.0.0/16 --ignore-preflight-errors=SystemVerification

    #copying credentials to regular user - vagrant
    sudo --user=vagrant mkdir -p /home/vagrant/.kube
    cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config

    # install Calico pod network addon
    export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/calico/rbac-kdd.yaml
    
    # Install CNI Calico (deprecated?).
    kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/calico/calico.yaml
    
    # Install CNI Flannel
    # kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

    kubeadm token create --print-join-command >> /etc/kubeadm_join_cmd.sh
    chmod +x /etc/kubeadm_join_cmd.sh

    # # Set the default service account as an admin
    kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default

    echo "################################################################"
    echo "Install MetalLB as Load Balancer"
    echo "################################################################"
    # # Pull and apply the MetalLB load-balancer service, hardcoded to serve private IPs in our host-only network
    kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/metallb/metallb.yaml
    kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/metallb/layer-2.yaml

    echo "################################################################"
    echo " Apply RBAC settings for tiller"
    echo "################################################################"
    kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/qseok/rbac-config.yaml

    # required for setting up password less ssh between guest VMs
    sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
    sudo service sshd restart
SCRIPT

$configureNode = <<-SCRIPT
    echo "This is a worker node"
    sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@192.168.205.10:/etc/kubeadm_join_cmd.sh .
    sudo sh ./kubeadm_join_cmd.sh
SCRIPT

$configureNFS = <<-SCRIPT
    echo "################################################################"
    echo " Configuring NFS Provisioner Pre-Work"
    echo "################################################################"
    sudo mkdir -p /storage/dynamic
    sudo mkdir -p /export
    sudo mkfs.xfs -f /dev/nvme0n1
    sudo mount /dev/nvme0n1 /storage/dynamic
    sudo chown vagrant:vagrant /storage/dynamic
    sudo chmod -R 777 /storage/dynamic

    # Label the node that will host NFS pvs
    # kubectl label nodes k8s-nfs role=nfs
    # kubectl taint nodes k8s-nfs key=value:NoSchedule

    # echo "################################################################"
    # echo " Deploy nfs-provisioner in k8s cluster
    # echo " using dedicated disk attached to  k8s-node1"
    # echo "################################################################"
    # # Pull and apply the nfs-provisioner
    # kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-deployment.yaml
    # kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-class.yaml

    # # Define the new storage class as default
    # kubectl patch storageclass nfs-dynamic -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
SCRIPT

# Insanely broken - barely fit for testing
# $configureIngress = <<-SCRIPT
#   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
#   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud-generic.yaml
# SCRIPT

Vagrant.configure("2") do |config|

  required_plugins = %w( vagrant-vbguest vagrant-scp )
	_retry = false
	required_plugins.each do |plugin|
		unless Vagrant.has_plugin? plugin
			system "vagrant plugin install #{plugin}"
			_retry=true
		end
	end

	if (_retry)
		exec "vagrant " + ARGV.join(' ')
  end
    
  servers.each do |opts|
    config.vm.define opts[:name] do |config|
      config.vm.box = opts[:box]
      config.vm.box_version = opts[:box_version]
      config.vm.hostname = opts[:name]
      config.vm.network :private_network, ip: opts[:eth1]

      config.vm.provider "virtualbox" do |vb|
        vb.name = opts[:name]
        vb.linked_clone = true
        vb.customize ["modifyvm", :id, "--groups", "/QSEoK"]
        vb.customize ["modifyvm", :id, "--memory", opts[:mem]]
        vb.customize ["modifyvm", :id, "--cpus", opts[:cpu]]
      end # VB

      config.vm.provision "shell", inline: $configureBox

      config.vm.provider "virtualbox" do |nfs|
        if opts[:type] == "nfs"
          disk = 'nfsdisk.vmdk'
          if !File.exist?(disk)
            nfs.customize [ "createmedium", "disk", "--filename", "nfsdisk.vmdk", "--format", "vmdk", "--size", "42240" ]
            nfs.customize [ "storagectl", :id, "--name", "nvme", "--add", "pcie", "--controller", "nvme", "--portcount", "1", "--hostiocache", "on", "--bootable", "off" ]
            nfs.customize [ "storageattach", :id , "--storagectl", "nvme", "--port", "0", "--device", "0", "--type", "hdd", "--medium", "nfsdisk.vmdk" ]
            # config.vm.provision "shell", inline: $configureNFS
          else
            # nfs.customize [ "storagectl", :id, "--name", "nvme", "--add", "pcie", "--controller", "nvme", "--portcount", "1", "--hostiocache", "on", "--bootable", "off" ]
            nfs.customize [ "storageattach", :id , "--storagectl", "nvme", "--port", "0", "--device", "0", "--type", "hdd", "--medium", "nfsdisk.vmdk" ]
            # config.vm.provision "shell", inline: $configureNFS
          end
        end # End if NFS
      end # config NFS

      if opts[:type] == "master"
        config.vm.provision "shell", inline: $configureMaster
      elsif opts[:type] == "nfs"
        config.vm.provision "shell", inline: $configureNode
        config.vm.provision "shell", inline: $configureNFS
      else
        config.vm.provision "shell", inline: $configureNode  
      end # End type loop

    end
  end #End opts
end
