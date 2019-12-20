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
retry kubectl apply -f ./namespace-setup2.yaml
retry kubectl apply -f ./namespace-setup3.yaml
retry kubectl apply -f ./namespace-setup4.yaml
retry kubectl apply -f ./namespace-setup5.yaml
retry kubectl apply -f ./namespace-setup6.yaml

retry vamp merge cluster cluster1 -f mergeCluster.yaml

sleep 30s

retry vamp create virtualcluster eu-ns --init
retry vamp config set -r eu-ns
retry vamp create gateway gw-1 -f gateway1.yaml
retry vamp create destination dest-shop-checkout-svc -f destination1-1.yaml
retry vamp create destination dest-shop-frontend-svc -f destination1-2.yaml
retry vamp create vampservice shop-checkout-svc -f vampservice1-1.yaml
retry vamp create vampservice shop-frontend-svc -f vampservice1-2.yaml

retry vamp create virtualcluster jp-ns --init
retry vamp config set -r jp-ns
retry vamp create gateway gw-2 -f gateway2.yaml
retry vamp create destination dest-shop-deluxe-svc -f destination2-1.yaml
retry vamp create vampservice shop-deluxe-svc -f vampservice2-1.yaml

retry vamp create virtualcluster uk-ns --init
retry vamp config set -r uk-ns
retry vamp create gateway gw-3 -f gateway3.yaml
retry vamp create destination dest-shop-checkout-svc -f destination3-1.yaml
retry vamp create destination dest-shop-deluxe-svc -f destination3-2.yaml
retry vamp create vampservice shop-checkout-svc -f vampservice3-1.yaml
retry vamp create vampservice shop-deluxe-svc -f vampservice3-2.yaml

retry vamp create virtualcluster au-ns --init
retry vamp config set -r au-ns
retry vamp create gateway gw-4 -f gateway4.yaml
retry vamp create destination dest-shop-checkout-svc -f destination4-1.yaml
retry vamp create destination dest-shop-deluxe-svc -f destination4-2.yaml
retry vamp create vampservice shop-checkout-svc -f vampservice4-1.yaml
retry vamp create vampservice shop-deluxe-svc -f vampservice4-2.yaml

retry vamp create virtualcluster kr-ns --init
retry vamp create virtualcluster tw-ns --init

