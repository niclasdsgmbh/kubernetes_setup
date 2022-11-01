#!/bin/bash

sudo chmod 777 /mnt/MinIO

kubectl create -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: my-local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

kubectl create -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-local-pv
spec:
  capacity:
    storage: 50Gi
  accessModes:
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: my-local-storage
  local:
    path: /mnt/MinIO
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - master-1
          - master-2
          - master-3
          - master-4
EOF

kubectl create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minio-pvc-claim
spec:
  storageClassName: my-local-storage
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
EOF

kubectl create -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
spec:
  selector:
    matchLabels:
      app: minio
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: minio
    spec:
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: minio-pvc-claim
      containers:
      - name: minio
        volumeMounts:
        - name: data 
          mountPath: /data
        image: minio/minio
        args:
        - server
        - /data
        env:
        - name: MINIO_ACCESS_KEY
          value: "dodspot"
        - name: MINIO_SECRET_KEY
          value: "dodspot#"
        ports:
        - containerPort: 9000
        readinessProbe:
          httpGet:
            path: /minio/health/ready
            port: 9000
          initialDelaySeconds: 120
          periodSeconds: 20
        livenessProbe:
          httpGet:
            path: /minio/health/live
            port: 9000
          initialDelaySeconds: 120
          periodSeconds: 20
EOF

kubectl create -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: minio-service
spec:
  type: LoadBalancer
  ports:
    - name: http
      port: 9000
      targetPort: 9000
      protocol: TCP
  selector:
    app: minio
EOF



kubectl apply -n calico -f    ./files/calico.yml
kubectl apply -n portainer -f ./files/portainer.yml