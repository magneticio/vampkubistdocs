# Container resources optimizer

## Table of contents

* [Optimizers](#the-optimizer)
* [Enabling optimization](#enabling-optimization)

## The Optimizer

Vamp Kubist allow to deploy an optimizer alongside deployments.
The Optimizer is a lightweight application that will continuously apply bayesian optimization to the resources request and limit configured on the deployment containers,
in order to reduce its resources consumption without affecting performances.

## Enabling optimization

Enabling a deployment optimization is as simple as updating a deployment definition with a new Policy Executor, as shown in the example below:

```yaml
imagePullSecret: []
labels: {}
metadata: {}
pod:
  containers:
    - environmentVariables:
        GET_FEEDBACK: "no"
        SHOP_VERSION: "1"
        VAMP_ELASTICSEARCH_URL: http://es-service:9200
      healthChecks: []
      image: magneticio/simpleservice:2.0.12
      metadata: {}
      ports:
        - containerPort: 9191
          hostPort: 0
      readyChecks: []
  metadata: {}
policies: []
replicas: 1
selectors:
  deployment: deployment1
policyExecutor:
  name: OptimizedDeploymentPolicyExecutor
  parameters:
    optimizer-config:
      MIN_CPU: 400
      MAX_CPU: 1000
      MIN_MEMORY: 10000000
      MAX_MEMORY: 200000000000
      OBSERVATION_MINUTES: 2
      INITIAL_POINTS: 3
```

You can apply the above yaml by running 

```shell script
vamp update deployment deployment1 -a demo-app -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/optimized-deployment.yaml
```

As you can see this will add to the deployment the OptimizedDeploymentPolicyExecutor. 
This Executor will create a new deployment for the Optimizer inside the vamp-system namespace on your cluster.
You can check that the optimizer has been deployed with kubectl by running

```shell script
kubectl get deployment cro-kubist-demo-deployment1 -n=vamp-system -o yaml
```

As you can see from the provided yaml, the Executor allows for the configuration of a handful of parameters.
More in detail MIN_CPU, MAX_CPU, MIN_MEMORY and MAX_MEMORY allow for configuring the boundaries for the tuning of cpu and memory requests and limits.
OBSERVATION_MINUTES allows to specify the length of time the optimizer will observe the deployment behaviour before applying changes and INITIAL_POINTS allows to configure the number trial points before the algorithm actually starts working. 

A container optimizer is entirey dependant to its associated deployment, so, should the deployment be deleted, Vmap Kubist will take care of also deleting the optimizer.