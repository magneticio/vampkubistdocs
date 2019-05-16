# Basic Tutorial

In this tutorial we will present all the steps required to use the canary releasing features of Vamp Kubist.
We will do that by setting up a canary release over two different versions of the same service which will be exposed outside the cluster.

## Requirements

In order to perform a canary release you need to have an application with at least two deployments installed in the cluster.
On top of that you will also need a destination, defining at least two subsets, a vamp service, directing the traffic to one of the subsets, and a gateway, to expose the service.
To quickly get such an environment, you can follow the [setup section](SETUP.md).

## Canary release types

Vamp Kubist offers the ability to setting up different types of canary releases through the use of [policies](EXECUTORS_AND_POLICIES.md).
Currently four types of canary release are available.
- **Time based canary release**
- **Health based canary release**
- **Metric based canary release**
- **Custom canary release**

In this section we will explain and test each one of them

### Time based canary release

The time based canary release is the simplest form of canary release, in which the only variable that matters is time. 
Simply put, the weights will shift from the current configuration to desired target over time, increasing by the specificied step at each interval.
Let's first move all the weight in the vamp service to subset2.
You can do this by editing the vamp service and setting the weight for subset1 to 100 and the weight for subset2 to 0.

```shell
vamp edit vampservice vs-1
```

You can now set up the canary release by running

```shell
vamp create canaryrelease vs-1 -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/canary.yaml
```

or more simply

```shell
vamp release vs-1 --destination dest-1 --type time
```

This will create a time based canary release entity with target dest-1 that will shift weights from subset1 to subset2 over time with increments of 10% every 30 seconds.
To verify that everything has been set up completely you can run

```shell
vamp get canaryrelease vs-1
```

which will return a response like the following

```yaml
name: vs-1-dest-1
projectName: project1
specification:
  destination: dest-1
  metadata: {}
  policies: []
  subsetLabels: {}
  updatePeriod: 30000
  updateStep: 10
  vampService: vs-1
status:
  currentSpecification:
    destination: dest-1
    metadata: {}
    policies: []
    subsetLabels: {}
    updatePeriod: 30000
    updateStep: 10
    vampService: vs-1
  isCanaryReleaseOver: false
  isDestinationSetUp: true
  isVampServiceSetUp: true
virtualClusterName: kubist-demo
```

As you can see destination has been set to dest-1, vampService is the target vamp service and all other fields are empty or have their default values.
In the status section you can see tree flags that give you some insight on the current status of the canary release.
- isCanaryReleaseOver: a flag that is true if the target has been reached for this canary release and false otherwise.
- isDestinationSetUp: a flag that is true if the destination referred to in the specification is set up correctly.
- isVampServiceSetUp: a flag that is true if the destination referred to in the specification is set up correctly.

You can now periodically run 

```shell
vamp get vampservice vs-1
```

to check progress on the canary release.     
You will see weights shifting gradually towards subset2. in steps of 10.    
If you had more than two subsets available, i.e. if your configuration were like this

```yaml
gateways:
- gw-1
hosts:
  - kubist-demo.democluster.net
routes:
  - protocol: http
  weights:
    - destination: dest-1
     port: 9090
     version: subset1
     weight: 100
    - destination: dest-1
     port: 9090
     version: subset2
     weight: 0
    - destination: dest-1
     port: 9090
     version: subset3
     weight: 0     
exposeInternally: true
```

Vamp Kubist would check the creation timestamps of deployments corresponding to subset2 and subset3 and move towards the most recently deployed one.
Let's now try adding a third deployment to demo-app2 by running

```shell
kubectl apply -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/third-deployment.yaml
```

Now if if you wanted to have a canary release again to move to subset3 you would have to first update the destination to include the new subset and then run again the command used previously.
However there's an easier way to achieve the same result, that is by running

```shell
vamp delete canaryrelease vs-1

vamp release vs-1 --destination dest-1 --port 9191 --subset subset3 -l deployment=deployment3
```

By doing that, not only the canary release will be created with the new target subset3, but also the destination will be update to include subset3 identified by the label deployment: deployment3 as specified by the -l flag.
You might have noticed that nowhere in these examples we ever specified the type of canary release. The reason for that is that time based canary release is the default type.
We can however specify it explicity, if we so wish, by adding the --type timed flag to the command.
In this case, however, it wouldn't affect the outcome.

### Health based canary release

Health based canary releasing is very similar to the time based approach but it also checks the health of the target subsets and will perform a rollback in case it starts detecting errors.
Before proceeding reset the initial state of the demo-app2 application by running

```shell
vamp delete canaryrelease vs-1

kubectl delete deploy deployment3 -n=kubist-demo
```

And updating the vamp service to its original configuration.
Now, to create a health based canary release run

```shell
vamp release vs-1  --destination dest-1 --type health
```

or you can also run 

```shell
vamp release vs-1 --destination dest-1
```

Since health is the default type.
The canary release will start to gradually shift traffic towards dest-1.
You could now want to test if the health of the subset is being checked. 
To do that, you can execute the following command, which will configure deployment2 to return errors on 50% of the requests.

```shell
kubectl apply -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/faulty-service-setup.yaml
```

You will notice that nothing really changed. This is due to the fact that a subset is considered unhealthy if the ratio of failed requests over the total numner of requests towards the subset exceeds 30%.
Thus, in order to test this, you will have to generate some traffic towards the endpoint.
You can do that either manually or by running the following command:

```shell
docker run -it -e URL_LANDING_PAGE=http://kubist-demo.democluster.net -e NUMBER_OF_AGENTS=10 magneticio/experiment-tester:0.0.3
```

This will start a docker container that will continuously generate traffic towards the specified host, allowing you to see the canary release in action.
You can change the NUMBER_OF_AGENTS variable to increase or decrease traffic.
As always, be mindful to change the URL_LANDING_PAGE value so that it matches the hostname you specified.

Over time you will see the weights shifting back to their original value as the health based canary release rolls back. 
If you were to update again the deployment to not return errors the canary release would resume and complete normally.

### Metric based canary release

A metric based canary release is driven by a condition based on a single metric or an aggregation metric.
In this example we will use a metric based canary release to reproduce the behaviour observed with the health based canary release.
Since an aggregated metric can be rather complex it is not possible to pass it as an inline parameter, so, to create this new canary release you will have to send a yaml file with its definition.
To apply this canary release configuration you can rely on the resources created in the previous example and run
After removing the previous canary release and restoring the deployments to their original statuses, run the following command to evenly split the weights on vamp service vs-1

```shell
vamp update vampservice vs-1 -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/vampservice2.yaml
```

This is necessary because with this kind of canary release you cannot specify a target, but rather the target is identified by the result in evaluating the related metrics. For this reason, both subsets must be initally reachable.
Once this has been done, you can apply the metric based canary release by running

```shell
vamp create canaryrelease vs-1 -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/metric-canary.yaml
```

As you can see, this time we are not using the inline notation, but we are instead specifying a yaml file that contains the canary release definition.
The reason for doing that is that we need to provide the metric parameter, which can prove to be rather complex.
Below you can see the specification of the canary release that we just set up in Vamp Kubist

```yaml
vampService: vs-1
updatePeriod: 30000
updateStep: 10
policies:
  - name: MetricCanaryReleasePolicy
    parameters:
      metric: internal_upstream_rq_2xx / upstream_rq_total
```

As you can see the specification now explicitly mentions the appropriate policy to be run and also contains the metric parameter with value 

```shell
internal_upstream_rq_2xx / upstream_rq_total
```

This aggregated metric calculates the ratio of successful responses over the total number of requests.
Metrics names are loosely based on Prometheus metrics names stored by Envoy (they are usually the last part of the metric name).
Some of the available metrics are:

- **internal_upstream_rq_200**
- **internal_upstream_rq_2xx**
- **internal_upstream_rq_500**
- **internal_upstream_rq_503**
- **internal_upstream_rq_5xx**
- **upstream_rq_total**

Destination, port and subset are not specified in this new yaml, because the target is now dynamically determined by the policy itself as it evaluates the metric.
You can test the outcome of this canary release the same way you tested the health based one, that is by generating traffic towards the service.
This type of canary release, however, comes with a limitation: you can only specify one condition, that is "select the version with the best metric".
To specify more complex conditions you will have to use a custom canary release.

### Custom canary release

A custom canary release allows you to specify a rather complex condition to identify the target subset using one or more metrics.
In this example we will again reproduce the previous example, but this time using a custom condition that achieves the same result.
Take care of resetting the initial status of the vamp service so that the weights are split evenly. As stated earlier you can do it by running

```shell
vamp update vampservice vs-1 -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/vampservice2.yaml
```

Now, to create such a canary release, you can run

```shell
vamp create canaryrelease vs-1 -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/custom-canary.yaml
```

where the content of the yaml is

```yaml
vampService: vs-1
updatePeriod: 30000
updateStep: 10
policies:
  - name: CustomCanaryReleasePolicy
    parameters:
      metric: if ( ( metric "dest-1" 9090 "subset1" "internal_upstream_rq_2xx" / metric "dest-1" 9090 "subset1" "upstream_rq_total" ) > ( metric "dest-1" 9090 "subset2" "internal_upstream_rq_2xx" / metric "dest-1" 9090 "subset2" "upstream_rq_total" ) ) { result = "dest-1 9090 subset1"; } else if ( ( metric "dest-1" 9090 "subset1" "internal_upstream_rq_2xx" / metric "dest-1" 9090 "subset1" "upstream_rq_total" ) < ( metric "dest-1" 9090 "subset2" "internal_upstream_rq_2xx" / metric "dest-1" 9090 "subset2" "upstream_rq_total" ) ) { result = "dest-1 9090 subset2"; } else { result = nil; } result
```

As you can see we are specifying a CustomCanaryReleasePolicy with a metric parameter. 
Below you can find the condition we are specifying in a more readable format.

```shell
if ( ( metric "dest-1" 9090 "subset1" "internal_upstream_rq_2xx" / 
       metric "dest-1" 9090 "subset1" "upstream_rq_total" ) 
       > 
      ( metric "dest-1" 9090 "subset2" "internal_upstream_rq_2xx" / 
        metric "dest-1" 9090 "subset2" "upstream_rq_total" ) ) { 
        result = "dest-1 9090 subset1"; 
      } 
else if ( ( 
      metric "dest-1" 9090 "subset1" "internal_upstream_rq_2xx" / 
      metric "dest-1" 9090 "subset1" "upstream_rq_total" ) < 
      ( metric "dest-1" 9090 "subset2" "internal_upstream_rq_2xx" / 
      metric "dest-1" 9090 "subset2" "upstream_rq_total" ) ) { 
      result = "dest-1 9090 subset2"; 
      } 
else 
    { result = nil; } result
```


The metric keyword tells the condition parsers that the following values will identify a specific metric. 
In this case a metric definition is given by

```shell
metric destination-name port subset-name metric-name
```

so for example if we want to get the number of 200 responses for destination dest-1, port 9090 and subset subset1, the metric definition will be

```shell
metric "dest-1" 9090 "subset1" "internal_upstream_rq_2xx"
```

Now, by looking at this condition we can understand that it is simply telling Vamp Kubist to shift the weights towards the version that has the highest ratio of 200 over the total number of requests.


