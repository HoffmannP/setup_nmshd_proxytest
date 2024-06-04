#!/usr/bin/zsh
set -e

kubectl apply -f Secret.yaml

kubectl apply -f Deployment_Squid.yaml
kubectl apply -f Service_Squid.yaml
echo -n "Waiting for Deployment_Squid "; kubectl wait --timeout=1m -f Deployment_Squid.yaml --for=condition=available
kubectl port-forward service/squid 3128:3128 &
sleep 2s

kubectl apply -f Deployment_Mongo.yaml
kubectl apply -f Service_Mongo.yaml
echo -n "Waiting for Deployment_Mongo "; kubectl wait --timeout=1m -f Deployment_Mongo.yaml --for=condition=available

kubectl apply -f Deployment_Connector.yaml
kubectl apply -f Service_Connector.yaml
echo -n "Waiting for Deployment_Connector "; kubectl wait --timeout=1m -f Deployment_Connector.yaml --for=condition=available
kubectl port-forward service/connector 8080:80 &
sleep 2s

echo "Continue"; read

kubectl logs -f deployment/squid > direct_request_squid.log &
https_proxy=http://localhost:3128 curl -v https://nmshd-bkb.demo.meinbildungsraum.de/health > direct_request_curl.log 2>&1
kill %2

kubectl logs -f deployment/squid > connector_request_squid.log &
kubectl logs -f deployment/connector > connector_request_connector.log &
curl -v http://localhost:8080/health > connector_request_curl.log 2>&1

kill %4
kill %3
kill %2
kill %1

kubectl delete secret nmshd
kubectl delete deployment squid mongo connector
kubectl delete service squid mongo connector kubernetes
killall kubectl
