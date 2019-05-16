# Executors and Policies

## Executors

Vamp Kubist manages all kinds of resources through the use of executor and policies.
Executors are procedures that run on each individual resource and, generally speaking, keep their desired state and current state aligned.
Different resources can also have their executors perform other tasks. 
For example the default executor for clusters is also responsible for verifying the status of Istio installation on the cluster and, if needed, for installing it.
In addition to that every executor, upon running, will also trigger all executors for the children resources associated with it.
For example, the root executor will trigger the executors for all projects, which, in turn, will trigger the executors for all clusters and so on, until the whole heirarchy has been traversed.
As part of theirprocessing executors also sequentially run all policies defined for their associated resource.

## Policies

Policies are procedures which, in some way, are very similar to executors. The are responsible for implementing specific behaviours, like different approaches to canary releasing and experiments.
Although there's no example of that currently in Vamp Kubist, resources can be associated with more than one policy and, in that case, they will be run sequentially and each one of them will take the output of the previous one as its input.

## Customizing Executors and Policies

Both executors and policies can be customized allowing for profound changes in Vamp Kubist behaviour.
In order to do so, one can specify the executor and/or policies that should be used in the resource yaml, as shown below

```yaml
executor:
    name: SomeExecutor
    parameters:
      someParam: someValue1
policies:
  - name: SomePolicy1
    parameters:
      someParam: someValue2
  - name: SomePolicy2
    parameters:
      someParam: someValue 3    
```

As you can see, besides specifying a different executor and policy, it is also possible to further customize Vamp Kubist behaviour by passing additional parameters.
**At this time only predefined executors and policies are supported, but our goal is to eventually allow for entirely custom policies to be defined by the users.**
