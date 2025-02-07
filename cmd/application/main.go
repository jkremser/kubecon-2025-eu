package main

import (
	"io"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func init() {
	_ = godotenv.Load()
}

var httpRequestCounter = prometheus.NewCounterVec(prometheus.CounterOpts{
	Name: "http_requests_total",
	Help: "Total number of HTTP requests received",
}, []string{"status", "path", "method"})

var activeRequestsGauge = prometheus.NewGauge(
	prometheus.GaugeOpts{
		Name: "http_active_requests",
		Help: "Number of active connections to the service",
	},
)

var latencyHistogram = prometheus.NewHistogramVec(prometheus.HistogramOpts{
	Name:    "http_request_duration_seconds",
	Help:    "Duration of HTTP requests",
	Buckets: []float64{0.1, 0.5, 1, 2.5, 5, 10},
}, []string{"status", "path", "method"})

var postsLatencySummary = prometheus.NewSummary(prometheus.SummaryOpts{
	Name: "post_request_duration_seconds",
	Help: "Duration of requests to https://jsonplaceholder.typicode.com/posts",
	Objectives: map[float64]float64{
		0.5:  0.05,  // Median (50th percentile) with a 5% tolerance
		0.9:  0.01,  // 90th percentile with a 1% tolerance
		0.99: 0.001, // 99th percentile with a 0.1% tolerance
	},
})

// Middleware to count HTTP requests
func prometheusMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		now := time.Now()
		delay := time.Duration(rand.Intn(900)) * time.Millisecond
		time.Sleep(delay)

		activeRequestsGauge.Inc()
		// Wrap the ResponseWriter to capture the status code
		recorder := &statusRecorder{
			ResponseWriter: w,
			statusCode:     http.StatusOK,
		}

		time.Sleep(1 * time.Second)

		// Process the request
		next.ServeHTTP(recorder, r)
		activeRequestsGauge.Dec()
		method := r.Method
		path := r.URL.Path // Path can be adjusted for aggregation (e.g., `/users/:id` → `/users/{id}`)
		status := strconv.Itoa(recorder.statusCode)

		latencyHistogram.With(prometheus.Labels{
			"method": method, "path": path, "status": status,
		}).Observe(time.Since(now).Seconds())

		// Increment the counter
		httpRequestCounter.WithLabelValues(status, path, method).Inc()
	})
}

// Helper to capture HTTP status codes
type statusRecorder struct {
	http.ResponseWriter
	statusCode int
}

func (rec *statusRecorder) WriteHeader(code int) {
	rec.statusCode = code
	rec.ResponseWriter.WriteHeader(code)
}

func main() {
	mux := http.NewServeMux()
	reg := prometheus.NewRegistry()
	reg.MustRegister(httpRequestCounter)
	reg.MustRegister(activeRequestsGauge)
	reg.MustRegister(latencyHistogram)
	reg.MustRegister(postsLatencySummary)

	handler := promhttp.HandlerFor(
		reg,
		promhttp.HandlerOpts{})

	mux.Handle("/metrics", handler)
	mux.HandleFunc("/posts", func(w http.ResponseWriter, r *http.Request) {
		url := "https://jsonplaceholder.typicode.com/posts"
		now := time.Now()
		resp, err := http.Get(url)

		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		postsLatencySummary.Observe(time.Since(now).Seconds())
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			http.Error(w, "request failed", resp.StatusCode)
			return
		}

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write(body)
	})

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Hello world!"))
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8000"
	}

	promHandler := prometheusMiddleware(mux)
	log.Println("Starting HTTP server on port", port)
	if err := http.ListenAndServe(":"+port, promHandler); err != nil {
		log.Fatal("Server failed to start:", err)
	}
}
