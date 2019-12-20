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

retry kubectl apply -f ./namespace-setup8.yaml

sleep 30s

retry vamp create virtualcluster ca-ns --init
retry vamp config set -r ca-ns
retry vamp create gateway gw-5 -f gateway5.yaml
retry vamp create destination dest-shop-checkout-svc -f destination5-1.yaml
retry vamp create destination dest-shop-frontend-svc -f destination5-2.yaml
retry vamp create vampservice shop-checkout-svc -f vampservice5-1.yaml
retry vamp create vampservice shop-frontend-svc -f vampservice5-2.yaml


