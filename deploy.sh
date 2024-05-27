#!/usr/bin/zsh

minikube kubectl -- apply -f Secret.yaml
minikube kubectl -- create secret generic squidconf --from-file=debug.conf

minikube kubectl -- apply -f Deployment_Squid.yaml
minikube kubectl -- apply -f Service_Squid.yaml
minikube kubectl -- port-forward service/squid 3128:3128 &

minikube kubectl -- apply -f Deployment_DB.yaml
minikube kubectl -- apply -f Service_DB.yaml

minikube kubectl -- apply -f Deployment_Connector.yaml
minikube kubectl -- apply -f Service_Connector.yaml

minikube kubectl -- port-forward service/connector 8080:80 &

minikube kubectl -- logs -f deployment/squid > direct_request_squid.log &
https_proxy=http://localhost:3128 curl -v https://nmshd-bkb.demo.meinbildungsraum.de/health > direct_request_curl.log
kill %3

minikube kubectl -- logs -f deployment/squid > connector_request_squid.log &
minikube kubectl -- logs -f deployment/connector > connector_request_connector.log &
curl -v http://localhost:8080/health > connector_request_curl.log

kill %4
kill %3
kill %2
kill %1
