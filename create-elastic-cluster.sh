#!/bin/bash

echo "Applying crds.yaml and operator.yaml ..."
kubectl create -f "https://download.elastic.co/downloads/eck/2.9.0/crds.yaml"
kubectl apply -f "https://download.elastic.co/downloads/eck/2.9.0/operator.yaml"
kubectl wait --timeout=60s --for=condition=ready pod --selector='control-plane=elastic-operator' --namespace=elastic-system

echo "Applying elasticsearch.yaml ..."
kubectl apply -f elasticsearch.yaml 

sleep 10

echo "Deploying elasticsearch..."
attempts=0
ES_Status_Command="kubectl get  elasticsearch elasticsearch -o=jsonpath='{.status.health}'"
while [[ $(eval $ES_Status_Command) != "green" && $attempts -lt 60 ]]; do
    attempts=$((attempts+1))
    sleep 20
    echo "..."
done

echo "Applying kibana.yaml ..."
kubectl apply -f kibana.yaml

sleep 2

echo "Deploying Kibana..."
attempts=0
KB_STATUS_CMD="kubectl get  kibana kibana -o='jsonpath={.status.health}'"
while [[ $(eval $KB_STATUS_CMD) != "green" && $attempts -lt 60 ]]; do
    attempts=$((attempts+1))
    sleep 20
    echo "..."
done

kubectl port-forward service/elasticsearch-es-http 9200 --address='0.0.0.0' &

PASSWORD_JSON=$(kubectl get secret elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}')
PASSWORD=$(echo $PASSWORD_JSON | base64 --decode)

echo "Password for elasticsearch: $PASSWORD"
echo "----"
echo "Connect to Elasticsearch with:"
echo "curl -u \"elastic:$PASSWORD\" -k \"https://localhost:9200\""
echo "----"

kubectl port-forward service/kibana-kb-http 5601 &

echo "----"
echo "Connect to Kibana at: \"https://localhost:5601\""
echo "----"

#echo "Applying heartbeat.yaml ..."
kubectl apply -f "heartbeat.yaml"

echo "Adding a Fleet server"
kubectl apply -f "fleet-server.yml"

kubectl port-forward service/fleet-server-agent-http 8220 --address='0.0.0.0' &

echo "----"
echo "Connect to Fleet Server at: \"https://localhost:8220\""
echo "----"

#echo "Adding Kubernetes dashboard"
#kubectl apply -f "kubernetes-dashboard.yml"

#kubectl patch deployment kubernetes-dashboard -n kubernetes-dashboard --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-skip-login"}]'

#echo "Adding resource usage metrics"
#kubectl apply -f "metrics.yaml"

#kubectl patch deployment metrics-server -n kube-system --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

#TOKEN_DASHBOARD_ENCODED=$(kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath="{.data.token}")
#TOKEN_DASHBOARD=$(echo $TOKEN_DASHBOARD_ENCODED | base64 --decode)

#echo "Token for Kubernetes Dashboard: $TOKEN_DASHBOARD"

#kubectl port-forward service/kubernetes-dashboard -n kubernetes-dashboard 8443:443 &

#echo "----"
#echo "Connect to dashboard at: \"https://localhost:8443\""
#echo "----"

