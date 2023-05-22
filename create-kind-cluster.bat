# delete cluster if it exists
kind delete cluster --name elastic

# create cluster
kind create cluster --config kind-config.yaml --name elastic

