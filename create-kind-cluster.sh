#!/bin/bash

kind delete cluster --name elastic
kind create cluster --config kind-config.yaml --name elastic
kind load docker-image docker.elastic.co/eck/eck-operator:2.9.0 --name elastic