#/bin/bash

wget https://raw.githubusercontent.com/projectcalico/calico/v3.24.3/manifests/crds.yaml
kubectl apply -f crds.yaml

wget https://github.com/projectcalico/calicoctl/releases/download/v3.20.0/calicoctl
chmod +x calicoctl
mv calicoctl /usr/local/bin/

export KUBECONFIG=~/.kube/config
export DATASTORE_TYPE=kubernetes