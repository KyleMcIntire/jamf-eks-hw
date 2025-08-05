#!/bin/bash

# WordPress Load Test Script for HPA Demo
# This script creates load testing pods to demonstrate HPA scaling

set -e

NAMESPACE="wordpress-demo"
LOAD_PODS=2

start_load_test() {
    echo "🚀 Starting load test with $LOAD_PODS pods..."
    
    for i in $(seq 1 $LOAD_PODS); do
        kubectl run load-test-$i \
            --image=busybox \
            --restart=Never \
            --namespace=$NAMESPACE \
            -- /bin/sh -c "while true; do wget -q -O- http://wordpress.wordpress-demo.svc.cluster.local; sleep 0.01; done" &
    done
    
    echo "✅ Load test started! Pods generating traffic to WordPress..."
    echo "📊 Monitor scaling with: kubectl get hpa -n $NAMESPACE -w"
    echo "🔍 Check pod count with: kubectl get pods -n $NAMESPACE | grep wordpress | grep -v mysql | wc -l"
}

stop_load_test() {
    echo "🛑 Stopping load test..."
    
    for i in $(seq 1 $LOAD_PODS); do
        kubectl delete pod load-test-$i -n $NAMESPACE --ignore-not-found=true
    done
    
    echo "✅ Load test stopped!"
    echo "📉 HPA will scale down after ~5 minutes of low usage"
    echo "📊 Monitor scaling with: kubectl get hpa -n $NAMESPACE -w"
}

status() {
    echo "📊 Current HPA Status:"
    kubectl get hpa -n $NAMESPACE
    echo ""
    echo "🏃 Current WordPress Pods:"
    kubectl get pods -n $NAMESPACE | grep wordpress | grep -v mysql
    echo ""
    echo "📈 Resource Usage:"
    kubectl top pods -n $NAMESPACE | grep wordpress | grep -v mysql
}

case "$1" in
    start)
        start_load_test
        ;;
    stop)
        stop_load_test
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        echo ""
        echo "Commands:"
        echo "  start   - Start load test (scales UP)"
        echo "  stop    - Stop load test (scales DOWN after ~5min)"
        echo "  status  - Show current HPA and pod status"
        echo ""
        echo "Example demo flow:"
        echo "  1. ./load-test-demo.sh status    # Show baseline"
        echo "  2. ./load-test-demo.sh start     # Generate load"
        echo "  3. kubectl get hpa -n $NAMESPACE -w  # Watch scaling"
        echo "  4. ./load-test-demo.sh stop      # Remove load"
        echo "  5. kubectl get hpa -n $NAMESPACE -w  # Watch scale-down"
        exit 1
        ;;
esac