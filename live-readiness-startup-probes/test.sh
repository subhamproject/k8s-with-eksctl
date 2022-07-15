#!/bin/bash

while :; do curl http://lrs-service:80; echo -e ''; sleep 1; done

kubectl run -it --rm --image=curlimages/curl lrs -- sh

