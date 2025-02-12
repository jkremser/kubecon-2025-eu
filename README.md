# Providing LLM autoscaling solution with OpenTelemetry and KEDA

This repository is used to facilitate the Kubecon EU 2025 session [Optimizing Metrics Collection & Serving When Autoscaling LLM Workloads](https://kccnceu2025.sched.com/event/1txI4/optimizing-metrics-collection-serving-when-autoscaling-llm-workloads-vincent-hou-bloomberg-jiri-kremser-kedifyio?iframe=no).

## Prerequisites:

Install ko:

```
brew install ko
```

Install wrk with the command:

```
brew install wrk
```

Install cert-manager:

```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.0/cert-manager.yaml
```

## OpenTelemetry Operator

Run the following command to install OpenTelemetry Operator:

```
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.117.0/opentelemetry-operator.yaml
```

Install everything with:

```
ko apply -f config/
```

Create the namespace:

```
kubectl apply -f config/000-namespace.yaml
```

Install the sidecar mode for OpenTelemetry:

```
kubectl apply -f config/001-sidecarotel.yaml
```

Create the deployment and service:

```
ko apply -f config/002-deployment.yaml
```
