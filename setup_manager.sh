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

calicoctl --allow-version-mismatch create -f ./files/calico_ippool_1.yml
calicoctl --allow-version-mismatch create -f ./files/calico_ippool_2.yml
calicoctl --allow-version-mismatch create -f ./files/calico_ippool_3.yml

openssl req -newkey rsa:4096 \
           -keyout cni.key \
           -nodes \
           -out cni.csr \
           -subj "/CN=calico-cni"

sudo openssl x509 -req -in cni.csr \
                  -CA /etc/kubernetes/pki/ca.crt \
                  -CAkey /etc/kubernetes/pki/ca.key \
                  -CAcreateserial \
                  -out cni.crt \
                  -days 365

sudo chown $(id -u):$(id -g) cni.crt

APISERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')

kubectl config set-cluster kubernetes \
    --certificate-authority=/etc/kubernetes/pki/ca.crt \
    --embed-certs=true \
    --server=$APISERVER \
    --kubeconfig=cni.kubeconfig

kubectl config set-credentials calico-cni \
    --client-certificate=cni.crt \
    --client-key=cni.key \
    --embed-certs=true \
    --kubeconfig=cni.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes \
    --user=calico-cni \
    --kubeconfig=cni.kubeconfig

kubectl config use-context default --kubeconfig=cni.kubeconfig

kubectl apply -f ./files/calico_cluster_role.yml
kubectl create clusterrolebinding calico-cni --clusterrole=calico-cni --user=calico-cni

curl -L -o /opt/cni/bin/calico https://github.com/projectcalico/cni-plugin/releases/download/v3.14.0/calico-amd64
chmod 755 /opt/cni/bin/calico
curl -L -o /opt/cni/bin/calico-ipam https://github.com/projectcalico/cni-plugin/releases/download/v3.14.0/calico-ipam-amd64
chmod 755 /opt/cni/bin/calico-ipam

mkdir -p /etc/cni/net.d/

cp cni.kubeconfig /etc/cni/net.d/calico-kubeconfig
chmod 600 /etc/cni/net.d/calico-kubeconfig

cp ./files/calico.conflist /etc/cni/net.d/10-calico.conflist

##############################
# TYPHA                      #
##############################

openssl req -x509 -newkey rsa:4096 \
                  -keyout typhaca.key \
                  -nodes \
                  -out typhaca.crt \
                  -subj "/CN=Calico Typha CA" \
                  -days 365

kubectl create configmap -n kube-system calico-typha-ca --from-file=typhaca.crt

openssl req -newkey rsa:4096 \
           -keyout typha.key \
           -nodes \
           -out typha.csr \
           -subj "/CN=calico-typha"

openssl x509 -req -in typha.csr \
                  -CA typhaca.crt \
                  -CAkey typhaca.key \
                  -CAcreateserial \
                  -out typha.crt \
                  -days 365

kubectl create secret generic -n kube-system calico-typha-certs --from-file=typha.key --from-file=typha.crt

kubectl create serviceaccount -n kube-system calico-typha

kubectl apply -f ./files/calico_typha.yml
kubectl create clusterrolebinding calico-typha --clusterrole=calico-typha --serviceaccount=kube-system:calico-typha
kubectl apply -f ./files/calico_typha_deployment.yml

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


