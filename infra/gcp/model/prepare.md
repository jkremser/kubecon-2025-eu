#!/bin/bash
```
source ../.secret
source ../.env-model
```
# download the models
based on https://cloud.google.com/blog/products/ai-machine-learning/how-to-deploy-llama-3-2-1b-instruct-model-with-google-cloud-run

```
huggingface-cli login --token ${HF_TOKEN}
huggingface-cli download ${MODEL} --exclude "*.bin" "*.pth" "*.gguf" ".gitattributes" --local-dir llama3
```

I the previous command hits the rate limiter, you can also copy the model to pv manually.


# now use either gsutil to upload it to s3 bucket for packer
```
gsutil -o GSUtil:parallel_composite_upload_threshold=150M -m cp -e -r llama3 ${GCS_BUCKET}
```

# or store it in the cluster in the shared PV
```
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "models-pvc"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
EOF
```

```
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pvc-access
spec:
  containers:
    - name: main
      #image: shaowenchen/huggingface-cli
      image: ubuntu
      command: ["/bin/sh", "-ec", "sleep 15000"]
      volumeMounts:
        - name: models
          mountPath: /mnt/models
  volumes:
    - name: models
      persistentVolumeClaim:
        claimName: models-pvc
EOF
```

```
k exec -ti pvc-access -- bash
# + use commands above to download the model into /mnt/models
huggingface-cli login --token ${HF_TOKEN}
huggingface-cli download meta-llama/meta-llama-3-8b-instruct --exclude "*.bin" "*.pth" "*.gguf" ".gitattributes" --local-dir llama3
```
# or just copy from the host
k cp llama3 pvc-access:/mnt/models

```
kubectl apply -f - <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: models-pvc-clone
spec:
  dataSource:
    name: models-pvc
    kind: PersistentVolumeClaim
  accessModes:
    - ReadOnlyMany
  storageClassName: csi-gce-pd
  resources:
    requests:
      storage: 20Gi
kind: PersistentVolumeClaim
EOF
```
