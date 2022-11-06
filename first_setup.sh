#!/bin/bash

# ADD HOSTS

cat <<'EOF' >> /etc/hosts
192.168.1.1  worker-1     
192.168.1.2  worker-2      
192.168.1.3  worker-3      
192.168.1.4  worker-4    
192.168.1.5  worker-5      
192.168.1.6  worker-6      
192.168.1.7  worker-7      
192.168.1.8  worker-8      
192.168.1.9  worker-9      
192.168.1.10 loadbalancer  
192.168.1.11 manager-1     
192.168.1.12 manager-2     
192.168.1.13 manager-3     
192.168.1.14 manager-4     
EOF

# DISABLE SWAP

swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# CONFIGURE KERNEL

echo "overlay"      >> /etc/modules-load.d/containerd.conf
echo "br_netfilter" >> /etc/modules-load.d/containerd.conf

modprobe overlay
modprobe br_netfilter

echo "net.bridge.bridge-nf-call-ip6tables = 1"  >> /etc/sysctl.d/kubernetes.conf
echo "net.bridge.bridge-nf-call-iptables = 1"   >> /etc/sysctl.d/kubernetes.conf
echo "net.ipv4.ip_forward = 1"                  >> /etc/sysctl.d/kubernetes.conf

sysctl --system

# PREINSTALL ARCHIVES

apt -yq install \
    curl \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-add-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main"

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

apt update

# INSTALL CONTAINERD
    
apt install -yq containerd.io
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# INSTALL KUBERNETES

apt install -yq \
    kubelet \
    kubeadm \
    kubectl
apt-mark hold \
    kubelet \
    kubeadm \
    kubectl

# INSTALL HELM

apt install -yq \
    helm
    
    
# MOUNT VOLUME

    read -p "Wie lautet die Volume-ID: " volume
    echo "/dev/disk/by-id/scsi-0HC_Volume_$volume /mnt/storage ext4 discard,nofail,defaults 0 0" >> /etc/fstab
    chcon -Rt svirt_sandbox_file_t /mnt/storage
    chmod 777 /mnt/storage