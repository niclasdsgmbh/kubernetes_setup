#!/bin/bash

# MOUNT VOLUME

    read -p "Wie lautet das Volume: " volume
    echo $var

    sudo mkfs.ext4 -F /dev/disk/by-id/$volume
    mount -o discard,defaults /dev/disk/by-id/$volume /mnt/MinIO
    echo "/dev/disk/by-id/$volume /mnt/MinIO ext4 discard,nofail,defaults 0 0" >> /etc/fstab

# INITIALISE KUBEADM

    kubeadm init \
        --pod-network-cidr=10.0.0.0/8 \
        --control-plane-endpoint=manager-1 \
        --skip-phases=addon/kube-proxy 

    read -p "Press any key to resume ..."

    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config

    kubectl apply -f https://raw.githubusercontent.com/minio/docs/master/source/extra/examples/minio-dev.yaml
    
    
    kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.6.5/install/kubernetes/quick-install.yaml
    kubectl apply -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-lb-ee.yaml
