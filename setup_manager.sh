##############################
# HOSTS                      #
##############################

cat ./files/hosts.list  >> /etc/hosts

##############################
# SWAP                       #
##############################

swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

##############################
# KERNEL MODULES             #
##############################

cat ./files/containerd.conf >> /etc/modules-load.d/containerd.conf
modprobe overlay
modprobe br_netfilter

##############################
# KERNEL PARAMETERS          #
##############################

cat ./files/kubernetes.conf >> /etc/sysctl.d/kubernetes.conf
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

apt update
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

kubeadm init --pod-network-cidr=10.0.0.0/8 --control-plane-endpoint=manager-1
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

##############################
# CALICO                     #
##############################

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.3/manifests/crds.yaml
wget https://github.com/projectcalico/calicoctl/releases/download/v3.24.3/calicoctl
chmod +x calicoctl
sudo mv calicoctl /usr/local/bin/

export DATASTORE_TYPE=kubernetes
export KUBECONFIG=~/.kube/config

calicoctl create -f ./files/calico_ippool_1.yml
calicoctl create -f ./files/calico_ippool_2.yml
calicoctl create -f ./files/calico_ippool_3.yml

##############################
# MinIO                      #
##############################

sudo chmod 777 /mnt/MinIO
kubectl create -f ./files/storageclass.conf
kubectl create -f minio-pv.yml
kubectl create -f minio-pvc.yml
kubectl create -f minio-dep.yml
kubectl create -f minio-svc.yml

kubectl apply -n calico -f    ./files/calico.yml
kubectl apply -n portainer -f ./files/portainer.yml

##############################
# CREATE TOKEN               #
##############################

kubeadm token create --print-join-command


