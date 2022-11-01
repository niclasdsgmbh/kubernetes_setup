#!/bin/bash

calicoctl --allow-version-mismatch apply -f - <<EOF
apiVersion: projectcalico.org/v3
kind: Node
metadata:
  annotations:
    projectcalico.org/kube-labels: '{"beta.kubernetes.io/arch":"amd64","beta.kubernetes.io/os":"linux","kubernetes.io/arch":"amd64","kubernetes.io/hostname":"worker-1","kubernetes.io/os":"linux"}'
  creationTimestamp: null
  labels:
    beta.kubernetes.io/arch: amd64
    beta.kubernetes.io/os: linux
    kubernetes.io/arch: amd64
    kubernetes.io/hostname: worker-1
    kubernetes.io/os: linux
    calico-route-reflector: ""
  name: worker-1
spec:
  addresses:
  - address: 192.168.1.1
    type: InternalIP
  orchRefs:
  - nodeName: worker-1
    orchestrator: k8s
  bgp:
    routeReflectorClusterID: 224.0.0.1
status:
  podCIDRs:
  - 10.0.1.0/24
EOF

calicoctl --allow-version-mismatch apply -f - <<EOF
apiVersion: projectcalico.org/v3
kind: Node
metadata:
  annotations:
    projectcalico.org/kube-labels: '{"beta.kubernetes.io/arch":"amd64","beta.kubernetes.io/os":"linux","kubernetes.io/arch":"amd64","kubernetes.io/hostname":"worker-1","kubernetes.io/os":"linux"}'
  creationTimestamp: null
  labels:
    beta.kubernetes.io/arch: amd64
    beta.kubernetes.io/os: linux
    kubernetes.io/arch: amd64
    kubernetes.io/hostname: worker-2
    kubernetes.io/os: linux
    calico-route-reflector: ""
  name: worker-2
spec:
  addresses:
  - address: 192.168.1.2
    type: InternalIP
  orchRefs:
  - nodeName: worker-2
    orchestrator: k8s
  bgp:
    routeReflectorClusterID: 224.0.0.1
status:
  podCIDRs:
  - 10.0.2.0/24
EOF

calicoctl --allow-version-mismatch apply -f - <<EOF
apiVersion: projectcalico.org/v3
kind: Node
metadata:
  annotations:
    projectcalico.org/kube-labels: '{"beta.kubernetes.io/arch":"amd64","beta.kubernetes.io/os":"linux","kubernetes.io/arch":"amd64","kubernetes.io/hostname":"worker-1","kubernetes.io/os":"linux"}'
  creationTimestamp: null
  labels:
    beta.kubernetes.io/arch: amd64
    beta.kubernetes.io/os: linux
    kubernetes.io/arch: amd64
    kubernetes.io/hostname: worker-3
    kubernetes.io/os: linux
    calico-route-reflector: ""
  name: worker-3
spec:
  addresses:
  - address: 192.168.1.3
    type: InternalIP
  orchRefs:
  - nodeName: worker-3
    orchestrator: k8s
  bgp:
    routeReflectorClusterID: 224.0.0.1
status:
  podCIDRs:
  - 10.0.3.0/24
EOF

calicoctl --allow-version-mismatch apply -f - <<EOF
kind: BGPPeer
apiVersion: projectcalico.org/v3
metadata:
  name: peer-to-rrs
spec:
  nodeSelector: "!has(calico-route-reflector)"
  peerSelector: has(calico-route-reflector)
EOF

calicoctl --allow-version-mismatch apply -f - <<EOF
kind: BGPPeer
apiVersion: projectcalico.org/v3
metadata:
  name: rrs-to-rrs
spec:
  nodeSelector: has(calico-route-reflector)
  peerSelector: has(calico-route-reflector)
EOF

calicoctl --allow-version-mismatch create -f - <<EOF
 apiVersion: projectcalico.org/v3
 kind: BGPConfiguration
 metadata:
   name: default
 spec:
   nodeToNodeMeshEnabled: false
   asNumber: 64512
EOF

