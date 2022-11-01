#!/bin/bash

kubeadm init --pod-network-cidr=10.0.0.0/8 --control-plane-endpoint=manager-1
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config