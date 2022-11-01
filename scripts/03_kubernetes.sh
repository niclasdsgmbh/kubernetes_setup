#!/bin/bash

cat <<'EOF' >> /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-add-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main"

apt update
apt install -yq \
  kubelet \
  kubeadm \
  kubectl
apt-mark hold \
  kubelet \
  kubeadm \
  kubectl

