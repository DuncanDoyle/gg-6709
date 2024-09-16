#!/bin/sh

pushd ..

# Create namespaces if they do not yet exist
kubectl create namespace ingress-gw --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace httpbin --dry-run=client -o yaml | kubectl apply -f -

# Deploy the HTTPBin application
printf "\nDeploy HTTPBin application ...\n"
kubectl apply -f apis/httpbin.yaml

# VirtualServices
printf "\nDeploy VirtualServices ...\n"
kubectl apply -f virtualservices/api-example-com-vs.yaml

# K8S Gateway API ingress-gw
printf "\nDeploy K8S Gateway API ingress-gw ...\n"
kubectl apply -f gateways/gw.yaml

# Reference Grant
printf "\nDeploy reference grants ...\n"
kubectl apply -f referencegrants/httpbin-ns/httproute-service-httpbin-ns-rg.yaml

# HTTPRoute
printf "\nDeploy HTTPRoute ...\n"
kubectl apply -f httproute/api-example-com-httproute.yaml

popd