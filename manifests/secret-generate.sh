#!/bin/sh
CERT_FILE="./nginx-certs/nginx-ingress.crt"
KEY_FILE="./nginx-certs/nginx-ingress.key"
CERT_NAME="nginx-ingress-tls"
NS="default"

kubectl create secret tls ${CERT_NAME} \
  --cert=${CERT_FILE} \
  --key=${KEY_FILE} \
  --namespace=${NS} 