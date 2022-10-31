##############################
# UPDATE & UPGRADE           #
##############################

export DEBIAN_FRONTEND=noninteractive
apt update
apt upgrade -yq

##############################
# HOSTS                      #
##############################

echo hosts.list  >> /etc/hosts

##############################
# SWAP                       #
##############################

swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

##############################
# KERNEL MODULES             #
##############################

echo "overlay" >> /etc/modules-load.d/containerd.conf
echo "br_netfilter" >> /etc/modules-load.d/containerd.conf
modprobe overlay
modprobe br_netfilter

##############################
# KERNEL PARAMETERS          #
##############################

echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/kubernetes.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/kubernetes.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/kubernetes.conf
sysctl --system

##############################
# INSTALL CONTAINERD         #
##############################

apt -yq install \
  curl \
  gnupg2 \
  software-properties-common \
  apt-transport-https \
  ca-certificates

##############################
# ADD DOCKER REPO            #
##############################

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

##############################
# CONFIGURE CONTAINERD       #
##############################

apt update
apt install -yq containerd.io
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

##############################
# ADD KUBERNETES REPO        #
##############################

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-add-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main"

##############################
# INSTALL KUBERNETES         #
##############################

apt update -yq
apt install -yq \
  kubelet \
  kubeadm \
  kubectl
apt-mark hold \
  kubelet \
  kubeadm \
  kubectl

##############################
# CONFIG KUBERNETES          #
##############################

kubeadm init --control-plane-endpoint=manager
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

##############################
# CONFIG FLANNEL             #
##############################

kubectl apply -f /git/cni.yml
kubectl apply -f /git/storageclass.yml

##############################
# CONFIG STORAGECLASS        #
##############################

kubectl patch storageclass gluster -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

##############################
# AUTOCLEAN                  #
##############################

apt autoclean -y

##############################
# DEPLOY MINIO               #
##############################

docker run \
   -p 9000:9000 \
   -p 9090:9090 \
   --name minio \
   -v /mnt/storage/:/data \
   -e "MINIO_ROOT_USER=dodspot" \
   -e "MINIO_ROOT_PASSWORD=dodspot" \
   quay.io/minio/minio server /data --console-address ":9090"

##############################
# DEPLOY PORTAINER           #
##############################

docker run -d -p 9443:9443 --name=portainer --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /portainer_data:/data \
    portainer/portainer-ee:latest
