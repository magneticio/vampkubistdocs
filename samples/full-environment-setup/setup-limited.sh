#!/usr/bin/env bash

function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=10
  local delay=15
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done

}

retry kubectl apply -f ./namespace-setup1.yaml

retry vamp merge cluster cluster1 -f mergeCluster.yaml

sleep 30s

retry vamp create virtualcluster eu-ns --init
retry vamp config set -r eu-ns
retry vamp create gateway gw-1 -f gateway1.yaml
retry vamp create destination dest-shop-checkout-svc -f destination1-1.yaml
retry vamp create destination dest-shop-frontend-svc -f destination1-2.yaml
retry vamp create vampservice shop-checkout-svc -f vampservice1-1.yaml
retry vamp create vampservice shop-frontend-svc -f vampservice1-2.yaml


