# INIT KUBEADM
kubeadm init --control-plane-endpoint=manager
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
