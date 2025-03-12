#!/usr/bin/env bash

kubectl config use-context shou73@inference-dev-01-pw

kubectl delete -f config/llama-vllm/003-scaledobject.yaml
kubectl delete -f config/llama-vllm/002-deployment.yaml
kubectl delete -f config/llama-vllm/001-sidecarotel.yaml
kubectl delete -f config/llama-vllm/002-isvc.yaml

kubectl get pod -n s-dsplatform |grep autoscaling-llama-3-1-70b-instruct-vllm
kubectl get deploy -n s-dsplatform |grep autoscaling-llama-3-1-70b-instruct-vllm
kubectl get isvc -n s-dsplatform |grep autoscaling-llama-3-1-70b-instruct-vllm
kubectl get hpa -n s-dsplatform |grep autoscaling-llama-3-1-70b-instruct-vllm
