#!/bin/bash

while :; do curl http://pdb-service:80; echo -e ''; sleep 1; done

kubectl run -it --rm --image=curlimages/curl test -- sh
