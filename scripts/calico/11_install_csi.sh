#!/bin/bash

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.3/manifests/csi-driver.yaml
kubectl label namespace default istio-injection=enabled

