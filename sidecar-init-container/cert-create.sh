#!/bin/bash

openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=IN/ST=TS/L=HYD/O=Moosapet/CN=tls" \
    -keyout tls.key  -out tls.crt


kubectl create secret generic elasticsearch-tls --from-file=tls.key --from-file tls.crt

kubectl describe secret elasticsearch-tls

kubectl get secret elasticsearch-tls -o yaml
