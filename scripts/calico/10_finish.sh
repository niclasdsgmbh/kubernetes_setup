#!/bin/bash

kubectl apply -f - <<EOF
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: calicoctl-user
rules:
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - clusterinformations
    verbs:
      - get
EOF

kubectl apply -f - <<EOF
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: network-admin
rules:
  - apiGroups: [""]
    resources:
      - pods
      - nodes
    verbs:
      - get
      - watch
      - list
      - update
  - apiGroups: [""]
    resources:
      - namespaces
      - serviceaccounts
    verbs:
      - get
      - watch
      - list
  - apiGroups: ["networking.k8s.io"]
    resources:
      - networkpolicies
    verbs: ["*"]
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - felixconfigurations
      - ipamblocks
      - blockaffinities
      - ipamhandles
      - ipamconfigs
      - bgppeers
      - bgpconfigurations
      - ippools
      - hostendpoints
      - clusterinformations
      - globalnetworkpolicies
      - globalnetworksets
      - networkpolicies
      - networksets
    verbs: ["*"]
EOF

openssl req -newkey rsa:4096 \
           -keyout nik.key \
           -nodes \
           -out nik.csr \
           -subj "/O=network-admins/CN=nik"

openssl x509 -req -in nik.csr \
        -CA /etc/kubernetes/pki/ca.crt \
        -CAkey /etc/kubernetes/pki/ca.key \
        -CAcreateserial \
        -out nik.crt \
        -days 365

chown $(id -u):$(id -g) nik.crt

APISERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')

kubectl config set-cluster kubernetes \
    --certificate-authority=/etc/kubernetes/pki/ca.crt \
    --embed-certs=true \
    --server=$APISERVER \
    --kubeconfig=nik.kubeconfig

kubectl config set-credentials nik \
    --client-certificate=nik.crt \
    --client-key=nik.key \
    --embed-certs=true \
    --kubeconfig=nik.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes \
    --user=nik \
    --kubeconfig=nik.kubeconfig

kubectl config use-context default --kubeconfig=nik.kubeconfig

kubectl create clusterrolebinding network-admins --clusterrole=network-admin --group=network-admins

KUBECONFIG=./nik.kubeconfig calicoctl apply -f - <<EOF
apiVersion: projectcalico.org/v3
kind: GlobalNetworkSet
metadata:
  name: niks-set
spec:
  nets:
  - 110.120.130.0/24
  - 210.220.230.0/24
EOF

kubectl apply -f - <<EOF
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: network-service-owner
rules:
  - apiGroups: ["networking.k8s.io"]
    resources:
      - networkpolicies
    verbs: ["*"]
  - apiGroups: ["crd.projectcalico.org"]
    resources:
      - networkpolicies
      - networksets
    verbs: ["*"]
EOF

openssl req -newkey rsa:4096 \
           -keyout sam.key \
           -nodes \
           -out sam.csr \
           -subj "/CN=sam"

openssl x509 -req -in sam.csr \
                  -CA /etc/kubernetes/pki/ca.crt \
                  -CAkey /etc/kubernetes/pki/ca.key \
                  -CAcreateserial \
                  -out sam.crt \
                  -days 365

chown $(id -u):$(id -g) sam.crt

APISERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')

kubectl config set-cluster kubernetes \
    --certificate-authority=/etc/kubernetes/pki/ca.crt \
    --embed-certs=true \
    --server=$APISERVER \
    --kubeconfig=sam.kubeconfig

kubectl config set-credentials sam \
    --client-certificate=sam.crt \
    --client-key=sam.key \
    --embed-certs=true \
    --kubeconfig=sam.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes \
    --user=sam \
    --kubeconfig=sam.kubeconfig

kubectl config use-context default --kubeconfig=sam.kubeconfig

kubectl create namespace sam

kubectl create rolebinding -n sam network-service-owner-sam --clusterrole=network-service-owner --user=sam

kubectl create clusterrolebinding calicoctl-user-sam --clusterrole=calicoctl-user --user=sam



