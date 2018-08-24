#!/bin/sh

while true
do
  kubectl get --namespace=kube-deploy --watch=true --output=json $1
done
