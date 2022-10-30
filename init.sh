# UPDATE & UPGRADE
apt update
apt dist-upgrade -qq -qq

# HOSTS
echo "10.0.0.3 manager" >> /etc/hosts
echo "10.0.0.4 worker-1" >> /etc/hosts 
echo "10.0.0.5 worker-2" >> /etc/hosts
echo "10.0.0.6 worker-3" >> /etc/hosts

# SWAP
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# KERNEL MODULES
echo "overlay" >> /etc/modules-load.d/containerd.conf
echo "br_netfilter" >> /etc/modules-load.d/containerd.conf
modprobe overlay
modprobe br_netfilter

# KERNEL PARAMETERS
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/kubernetes.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/kubernetes.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/kubernetes.conf
sysctl --system

# INSTALL CONTAINERD
apt install -qq \
  curl \
  gnupg2 \
  software-properties-common \
  apt-transport-https \
  ca-certificates

# ADD DOCKER REPO
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update && apt install -y containerd.io

# CONFIGURE CONTAINERD
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# ADD KUBERNETES REPO
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

# INSTALL KUBERNETES
apt update
apt install -qq \
  kubelet \
  kubeadm \
  kubectl
apt-mark hold \
  kubelet \
  kubeadm \
  kubectl
  
# AUTOCLEAN
apt get -qq autoclean
