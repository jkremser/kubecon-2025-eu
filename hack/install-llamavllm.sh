#!/usr/bin/env bash

kubectl config use-context shou73@inference-dev-01-pw

kubectl apply -f config/llama-vllm/001-sidecarotel.yaml
kubectl apply -f config/llama-vllm/002-deployment.yaml
kubectl apply -f config/llama-vllm/003-scaledobject.yaml


kubectl apply -f config/llama-vllm/001-sidecarotel.yaml
kubectl apply -f config/llama-vllm/002-isvc.yaml
kubectl apply -f config/llama-vllm/003-scaledobject.yaml

# kubectl apply -f config/llama-vllm/002-isvc.yaml

# Edit the deploy of kserve by setting replicas to 0.
# k edit deploy -n kserve kserve-controller-manager
# Remove the HPA for the isvc.

#kubectl scale --replicas=0 deployment/kserve-controller-manager -n kserve
#kubectl delete hpa -n s-dsplatform autoscaling-llama-3-1-70b-instruct-vllm-predictor
#kubectl scale --replicas=1 deployment/kserve-controller-manager -n kserve

# Edit the deploy of kserve by setting replicas to 1.

kubectl get pod -n s-dsplatform |grep autoscaling-llama-3-1-70b-instruct-vllm
kubectl get deploy -n s-dsplatform |grep autoscaling-llama-3-1-70b-instruct-vllm
kubectl get isvc -n s-dsplatform |grep autoscaling-llama-3-1-70b-instruct-vllm
kubectl get hpa -n s-dsplatform |grep autoscaling-llama-3-1-70b-instruct-vllm

k port-forward deploy/autoscaling-llama-3-1-70b-instruct-vllm-predictor -n s-dsplatform 1234:1234
k port-forward deploy/autoscaling-llama-3-1-70b-instruct-vllm-predictor -n s-dsplatform 8080:8080
http://127.0.0.1:1234/metrics
http://127.0.0.1:8080/metrics
