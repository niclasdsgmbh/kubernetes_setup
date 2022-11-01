#!/bin/bash

cat > pool1.yaml <<EOF
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: pool1
spec:
  cidr: 10.1.0.0/16
  ipipMode: Never
  natOutgoing: true
  disabled: false
  nodeSelector: all()
EOF

cat > pool2.yaml <<EOF
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: pool2
spec:
  cidr: 10.2.0.0/16
  ipipMode: Never
  natOutgoing: true
  disabled: false
  nodeSelector: all()
EOF

cat > pool3.yaml <<EOF
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: pool3
spec:
  cidr: 10.3.0.0/16
  ipipMode: Never
  natOutgoing: true
  disabled: false
  nodeSelector: all()
EOF

calicoctl create -f pool1.yaml
calicoctl create -f pool2.yaml
calicoctl create -f pool3.yaml