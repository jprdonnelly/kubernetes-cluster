# -*- mode: ruby -*-
# vi: set ft=ruby :

servers = [
  {
    :name => "k8s-master",
    :type => "master",
    :box => "jprdonnelly/ubuntu-1804",
    :eth1 => "192.168.205.10",
    :mem => "3200",
    :cpu => "2"
  },
  {
    :name => "k8s-nfs",
    :type => "nfs",
    :box => "jprdonnelly/ubuntu-1804",
    :eth1 => "192.168.205.14",
    :mem => "2176",
    :cpu => "2"
  },
  {
    :name => "k8s-node1",
    :type => "node",
    :box => "jprdonnelly/ubuntu-1804",
    :eth1 => "192.168.205.11",
    :mem => "4224",
    :cpu => "2",
  },
  {
    :name => "k8s-node2",
    :type => "node",
    :box => "jprdonnelly/ubuntu-1804",
    :eth1 => "192.168.205.12",
    :mem => "4224",
    :cpu => "2",
  },
# Uncomment section below to enable a 3rd worker node.
  #{
  #  :name => "k8s-node3",
  #  :type => "node",
  #  :box => "jprdonnelly/ubuntu-1804",
  #  :eth1 => "192.168.205.13",
  #  :mem => "8320",
  #  :cpu => "4",
  #}
]

$configureBox = <<-SCRIPT
  # Set time to ensure IdP works
  sudo ntpdate pool.ntp.org 

  # kubelet requires swap off
  sudo swapoff -a

  # keep swap off after reboot
  sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

  # ip of this box
  IP_ADDR=`ifconfig eth1 | grep mask | awk '{print $2}'| cut -f2 -d:`
  # set node-ip
  sudo echo "KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDR" >> /etc/default/kubelet
  echo "source <(kubectl completion bash)" >> /home/vagrant/.bashrc
  echo "echo" >> /home/vagrant/.bashrc
  echo "echo" >> /home/vagrant/.bashrc
  echo "/usr/bin/neofetch" >> /home/vagrant/.bashrc
  echo "echo" >> /home/vagrant/.bashrc
  echo "echo" >> /home/vagrant/.bashrc
SCRIPT

$configureMaster = <<-SCRIPT
    echo "################################################################"
    echo "Configuring as master node"
    echo "################################################################"
    # ip of this box
    IP_ADDR=`ifconfig eth1 | grep mask | awk '{print $2}'| cut -f2 -d:`

    # install k8s master node
    HOST_NAME=$(hostname -s)
    kubeadm init --apiserver-advertise-address=$IP_ADDR --apiserver-cert-extra-sans=$IP_ADDR  --node-name $HOST_NAME --pod-network-cidr=172.16.0.0/16 --ignore-preflight-errors=SystemVerification

    #copying credentials to regular user - vagrant
    sudo --user=vagrant mkdir -p /home/vagrant/.kube
    cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
    chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config
    export KUBECONFIG=/etc/kubernetes/admin.conf

    # Install CNI cilium
    kubectl create -f https://raw.githubusercontent.com/cilium/cilium/1.6.1/install/kubernetes/quick-install.yaml

    # Apply Calico RBAC
    # kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/calico/rbac-kdd.yaml
    
    # Install CNI Calico
    # kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/calico/calico.yaml

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
    echo "Apply RBAC settings for tiller"
    echo "################################################################"
    kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/base/rbac-config.yaml

    echo "################################################################"
    echo "Deploying Metrics-Server to kube-system Namespace"
    echo "################################################################"
    kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/base/metrics-server.yaml

#    echo "################################################################"
#    echo "Deploying Helm and Init Tiller"
#    echo "################################################################"
#    curl -o /home/vagrant/get_helm.sh -LO https://git.io/get_helm.sh
#    chmod +x /home/vagrant/get_helm.sh
#    /home/vagrant/get_helm.sh --version v2.14.3
#    sleep 5
#    /usr/local/bin/helm init --service-account tiller --wait
#    /usr/local/bin/helm version

    # required for setting up password less ssh between guest VMs
    sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
    sudo sed -i "s/^.*TCPKeepAlive.*$/TCPKeepAlive yes/" /etc/ssh/sshd_config
    sudo sed -i "s/^.*ClientAliveInterval.*$/ClientAliveInterval 600/" /etc/ssh/sshd_config
    sudo sed -i "s/^.*ClientAliveCountMax.*$/ClientAliveCountMax 10/" /etc/ssh/sshd_config
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
    sudo mkfs.xfs -f /dev/sdb
    sudo mount /dev/sdb /storage/dynamic
    sudo chown vagrant:vagrant /storage/dynamic
    sudo chmod -R 777 /storage/dynamic

    # echo "################################################################"
    # echo " Deploy nfs-provisioner in k8s cluster
    # echo " using dedicated disk attached to dedicated node k8s-nfs"
    # echo "################################################################"
    # # Pull and apply the nfs-provisioner
    # sleep 60
    # kubectl taint nodes k8s-nfs key=value:NoSchedule
    # kubectl apply -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-helm-pvc.yaml
    # helm install -n nfs stable/nfs-server-provisioner --namespace nfs -f https://raw.githubusercontent.com/jprdonnelly/kubernetes-cluster/master/nfs-provisioner/nfs-helm-values.yaml
SCRIPT

# Insanely broken - barely fit for testing
# $configureIngress = <<-SCRIPT
#   kubectl apply --namespace ingress-nginx -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
#   kubectl apply --namespace ingress-nginx -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud-generic.yaml
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
      config.ssh.forward_x11 = true
      config.ssh.keep_alive = true

      config.vm.provider "virtualbox" do |nfs|
        if opts[:type] == "nfs"
          disk = 'nfsdisk.vmdk'
          if !File.exist?(disk)
            nfs.customize [ "createmedium", "disk", "--filename", "nfsdisk.vmdk", "--format", "vmdk", "--size", "103424" ]
            nfs.customize [ "storagectl", :id, "--name", "SATA Controller", "--controller", "IntelAhci", "--portcount", "2", "--hostiocache", "on", "--bootable", "on" ]
            nfs.customize [ "storageattach", :id , "--storagectl", "SATA Controller", "--port", "1", "--device", "0", "--type", "hdd", "--medium", "nfsdisk.vmdk" ]
          else
            nfs.customize [ "storageattach", :id , "--storagectl", "SATA Controller", "--port", "1", "--device", "0", "--type", "hdd", "--medium", "nfsdisk.vmdk" ]
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
