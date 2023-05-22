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
    kubectl port-forward service/elasticsearch-es-http 9200
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