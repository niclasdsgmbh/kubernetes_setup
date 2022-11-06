#!/bin/bash

# INITIALISE KUBEADM

    kubeadm init \
        --pod-network-cidr=10.0.0.0/8 \
        --control-plane-endpoint=manager-1 \
        --skip-phases=addon/kube-proxy 

    read -p "Press any key to resume ..."

    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config

    CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
    CLI_ARCH=amd64
    if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
    sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
    rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
    cilium install

    kubectl create -f minio-sc.yml
    kubectl create -f minio-pv.yml
    kubectl create -f minio-pvc.yml
    kubectl create -f minio-dep.yml
    kubectl create -f minio-svc.yml


    
  
    kubectl apply -f https://raw.githubusercontent.com/minio/docs/master/source/extra/examples/minio-dev.yaml
    
    kubectl apply -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-lb-ee.yaml
