kubectl create -f "https://download.elastic.co/downloads/eck/2.7.0/crds.yaml"
kubectl apply -f "https://download.elastic.co/downloads/eck/2.7.0/operator.yaml"
kubectl wait --timeout=60s --for=condition=ready pod --selector='control-plane=elastic-operator' --namespace=elastic-system


Write-Host "Applying elasticsearch.yaml ..."
kubectl apply -f elasticsearch.yaml 

Start-Sleep -Seconds 10

Write-Host "Deploying elasticsearch..."
$attempts = 0
$ES_Status_Command = "kubectl get  elasticsearch elasticsearch -o=jsonpath='{.status.health}'"
do {
    $attempts++
    Start-Sleep -Seconds 20
    Write-Host "..."
} until ((Invoke-Expression $ES_Status_Command) -eq "green" -or $attempts -eq 60)

Write-Host "Applying kibana.yaml ..."
kubectl apply -f kibana.yaml

Start-Sleep -Seconds 2

Write-Host "Deploying Kibana..."
$ATTEMPTS = 0
$KB_STATUS_CMD = "kubectl get  kibana kibana -o='jsonpath={.status.health}'"
do {
    $ATTEMPTS++
    Start-Sleep -Seconds 20
    Write-Host "..."
} until ((Invoke-Expression $KB_STATUS_CMD) -eq "green" -or $ATTEMPTS -eq 60)

Start-Job -ScriptBlock {
    kubectl port-forward service/elasticsearch-es-http 9200 --address='0.0.0.0'
}

$PASSWORD_JSON = kubectl get secret elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}'
$PASSWORD = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($PASSWORD_JSON))

Write-Host "Password for elasticsearch: $PASSWORD"
Write-Host "----"
Write-Host "Connect to Elasticsearch with:"
Write-Host "curl -u `"elastic:$PASSWORD`" -k `"https://localhost:9200`""
Write-Host "----"

Start-Job -ScriptBlock {
    kubectl port-forward service/kibana-kb-http 5601
}

Write-Host "----"
Write-Host "Connect to Kibana at: `"https://localhost:5601`""
Write-Host "----"


Write-Host "Applying heartbeat.yaml ..."
kubectl apply -f "heartbeat.yaml"

Write-Host "Adding a Fleet server"
kubectl apply -f "fleet-server.yml"


Start-Job -ScriptBlock {
    kubectl port-forward service/fleet-server-agent-http 8220 --address='0.0.0.0'
}

Write-Host "----"
Write-Host "Connect to Fleet Server at: `"https://localhost:8220`""
Write-Host "----"


Write-Host "Adding Kubernetes dashboard"
kubectl apply -f "kubernetes-dashboard.yml"

kubectl patch deployment kubernetes-dashboard -n kubernetes-dashboard --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-skip-login"}]'

Write-Host "Adding resource usage metrics"
kubectl apply -f "metrics.yaml"

kubectl patch deployment metrics-server -n kube-system --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'


$TOKEN_DASHBOARD_ENCODED = kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath="{.data.token}"
$TOKEN_DASHBOARD = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($TOKEN_DASHBOARD_ENCODED))

Write-Host "Token for Kubernetes Dashboard: $TOKEN_DASHBOARD"

Start-Job -ScriptBlock {
    kubectl port-forward service/kubernetes-dashboard -n kubernetes-dashboard 8443:443
}

Write-Host "----"
Write-Host "Connect to dashboard at: `"https://localhost:8443`""
Write-Host "----"