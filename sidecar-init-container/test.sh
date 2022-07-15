#!/bin/bash

kubectl run -it --rm --image=curlimages/curl sidecar -- sh

curl http://elasticsearch:9200


curl -k https://elasticsearch:9200


k logs pods <es> -c <proxy> |grep curl
