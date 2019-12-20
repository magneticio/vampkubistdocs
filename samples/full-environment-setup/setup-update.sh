#!/usr/bin/env bash

function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=5
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

sleep 10s

retry vamp config set -r eu-ns
retry vamp update gateway gw-1 -f gateway1.yaml
retry vamp update destination dest-shop-checkout-svc -f destination1-1.yaml
retry vamp update destination dest-shop-frontend-svc -f destination1-2.yaml
retry vamp update vampservice dest-shop-checkout-svc -f vampservice1-1.yaml
retry vamp update vampservice dest-shop-frontend-svc -f vampservice1-2.yaml

retry vamp config set -r jp-ns
retry vamp update gateway gw-2 -f gateway2.yaml
retry vamp update destination dest-shop-deluxe-svc -f destination2-1.yaml
retry vamp update vampservice shop-deluxe-svc -f vampservice2-1.yaml

retry vamp config set -r uk-ns
retry vamp update gateway gw-3 -f gateway3.yaml
retry vamp update destination dest-shop-checkout-svc -f destination3-1.yaml
retry vamp update destination shop-deluxe-svc -f destination3-2.yaml
retry vamp update vampservice dest-shop-checkout-svc -f vampservice3-1.yaml
retry vamp update vampservice shop-deluxe-svc -f vampservice3-2.yaml

retry vamp config set -r au-ns
retry vamp update gateway gw-4 -f gateway4.yaml
retry vamp update destination dest-shop-checkout-svc -f destination4-1.yaml
retry vamp update destination shop-deluxe-svc -f destination4-2.yaml
retry vamp update vampservice dest-shop-checkout-svc -f vampservice4-1.yaml
retry vamp update vampservice shop-deluxe-svc -f vampservice4-2.yaml


