#!/bin/bash

kubectl taint nodes ip-10-0-0-124.ec2.internal dedicated=Kafka:NoSchedule

k  taint nodes prod-worker dedicated=Kafka:NoSchedule
k  taint nodes prod-worker2 dedicated=Kafka:NoSchedule
k  taint nodes prod-worker3 dedicated=Kafka:NoSchedule


kubectl taint node <Node_Name> <key=value:TAINT_EFFECT>
NoSchedule
PreferNoSchedule
NoExecute



To Apply taints
----------------
k  taint nodes demo1-worker  size=large:NoSchedule


k  taint nodes demo1-worker  size=large:PreferNoSchedule


k  taint nodes demo2-worker  size=large:NoExecute


To remove Taints
---------------------
k  taint nodes demo1-worker  size-


k describe node demo1-worker|grep Taint

