# Providing LLM autoscaling solution with OpenTelemetry and KEDA

This repository is used to facilitate the Kubecon EU 2025 session [Optimizing Metrics Collection & Serving When Autoscaling LLM Workloads](https://kccnceu2025.sched.com/event/1txI4/optimizing-metrics-collection-serving-when-autoscaling-llm-workloads-vincent-hou-bloomberg-jiri-kremser-kedifyio?iframe=no).

You can access the slides [here](https://docs.google.com/presentation/d/12Q5tOHEwWmsnOQNstCj3aHYx-SfI1odc/edit#slide=id.p1).

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

<!-- ```
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.117.0/opentelemetry-operator.yaml
``` -->

```
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm install my-opentelemetry-operator open-telemetry/opentelemetry-operator -nopentelemetry-operator --create-namespace\
  --set "manager.collectorImage.repository=otel/opentelemetry-collector-contrib"
```

# KEDA & KEDA OTel Scaler
Install KEDA

```
helm repo add kedacore https://kedacore.github.io/charts
helm repo update kedacore
helm upgrade -i keda kedacore/keda -nkeda --create-namespace
```

Install the KEDA OTel addon

```
helm upgrade -i kedify-otel oci://ghcr.io/kedify/charts/otel-add-on -nkeda \
  --version=v0.0.5 \
  --set opentelemetry-collector.enabled=false
```

# How to collect the metrics

There are two modes as we leverage OpenTelemetry to collect the metrics of the workload:

- [Standalone](#standalone-mode)
- [Sidecar](#sidecar-mode)

## Standalone mode

TBD.

## Sidecar mode

Install everything with:

> [!TIP]
> You may want to configure `ko` with `export KO_DOCKER_REPO=docker.io/${USER}/` first.

```
ko apply -f config/sidecar
```

Create the namespace:

```
kubectl apply -f config/sidecar/000-namespace.yaml
```

Install the sidecar mode for OpenTelemetry:

```
kubectl apply -f config/sidecar/001-sidecarotel.yaml
```

Create the deployment and service:

```
ko apply -f config/sidecar/002-deployment.yaml
```

The example application exposes a couple of metrics at port `8000` and co-located OTel collector scrapes them and sends to grpc endpoint - `keda-otel-scaler.keda.svc:4317`.

To verify that metrics have reached the scaler, you can try:

```
(k port-forward svc/keda-otel-scaler -n keda 19090:9090)&
curl -s http://localhost:19090/memstore/names | jq .
[
  "up",
  "scrape_duration_seconds",
  "scrape_samples_post_metric_relabeling",
  "http_active_requests",
  "http_requests_total",
  "scrape_series_added",
  "scrape_samples_scraped",
  "http_request_duration_seconds_count"
]
```

# Create a Scaled Object

// todo this