#!/bin/bash

k run tmp01 --image=tutum/dnsutils -- sleep infinity

k exec tmp01 -it -- /bin/sh


nslookup regular-svc


nslookup headless-svc
