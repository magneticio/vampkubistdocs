# Basic Tutorial

In this tutorial we will present all the steps required to use the canary releasing features of Vamp Kubist.
We will do that by setting up a canary release over two different versions of the same service which will be exposed outside the cluster.

## Requirements

In order to perform a canary release you need to have an application with at least two deployments installed in the cluster.
On top of that you will also need a destination, defining at least two subsets, a vamp service, directing the traffic to one of the subsets, and a gateway, to expose the service.
To get such a setup running quickly feel free to follow the [basic tutorial section](BASIC_TUTORIAL.md). For the rest of this section we will assume you did just that and use the same names used in that tutorial for all resources.

## Canary release types

Vamp Kubist offers the ability to setting up different types of canary releases through the use of [policies](POLICIES_AND_EXECUTORS.md).
Currently four types of canary release are available.
- **Time based canary release**
- **Health based canary release**
- **Metric based canary release**
- **Custom canary release**

In this section we will explain and test each one of them

### Time based canary release

The time based canary release is the simplest form of canary release, in which the only variable that matters is time. 
Simply put, the weights will shift from the current configuration to desired target over time, increasing by the specificied step at each interval.
Assuming you have a vamp service with the following configuration

```yaml
gateways:
  - gw-1
hosts:
  - kubist-demo.democluster.net
routes:
  - protocol: http
    weights:
      - destination: dest-1
        port: 9191
        version: subset1
        weight: 100
      - destination: dest-1
        port: 9191
        version: subset2
        weight: 0
exposeInternally: true
```

you can set up the canary release by running

```shell
vamp create canaryrelease -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/canary.yaml
```

or more simply

```shell
vamp release vs-1 --destination dest-1
```

This will create a canary release entity with target dest-1 that will shift weights from subset1 to subset2 over time with increments of 10% every 30 seconds.
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
In the status section uou can see tree flags that give you some insight ont he current status of the canary release.
- isCanaryReleaseOver: a flag that is true if the target has been reached for this canary release and false otherwise.
- isDestinationSetUp: a flag that is true if the destination referred to in the specificaiton is set up correctly.
- isVampServiceSetUp: a flag that is true if the destination referred to in the specificaiton is set up correctly.

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
     port: 9191
     version: subset1
     weight: 100
   - destination: dest-1
     port: 9191
     version: subset2
     weight: 0
   - destination: dest-1
     port: 9191
     version: subset3
     weight: 0     
exposeInternally: true
```

Vamp Kubist would check the creation timestamps of deployments corresponding to subset2 and subset3 and move towards the most recently deployed one.
let's now try adding a third deployment to demo-app by running

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
In order to test this type of canary release we need to first deploy an application with two deployments and, then, after the canary release has been running for a while, we need to update one of the deployments to faulty version that will start returning errors.
To do that we will first apply the following script

```shell
kubectl apply -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/example-app-setup.yaml
```

this will create two deployments deployment4 and deployment5 grouped in applicaiton demo-app2 inside virtual cluster kubist-demo.
Now create a destination, gateway and vamp service using the three samples below, but taking care to replace the hostname being used with one of your own.

**Destination dest-2:**

```yaml
application: demo-app
ports:
  - name: http
    port: 9090
    targetPort: 9090
    protocol: TCP
subsets:
  subset1:
    labels:
      deployment: deployment4
  subset2:
    labels:
      deployment: deployment5
```

**Gateway gw-2:**

```yaml
servers:
  - port: 80
    protocol: http
    hosts:
      - kubist-demo2.democluster.net
```

**Vamp Service vs-2:**

```yaml
gateways:
  - gw-2
hosts:
  - kubist-demo2.democluster.net
routes:
  - protocol: http
    weights:
      - destination: dest-2
        port: 9090
        version: subset1
        weight: 100
      - destination: dest-2
        port: 9090
        version: subset2
        weight: 0
exposeInternally: true
```

Once everything is setup (which you can verify by accessing your host) just create a new canary release with 

```shell
vamp release vs-2 --destination dest-2 --type health
```

The canary release will start to gradually shift traffic towards dest-2.
After a while you can then run the following command to starte reurning errors on subset2.

```shell
kubectl apply -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/faulty-service-setup.yaml
```

A subset is considered unhealthy if the ration of failed requests over the total numner of requests towards the subset exceeds 30%.
Thus, in order to test this, you will have to generate some traffic towards the endpoint.
You can do that either manually or by... TODO explaining how to use the docker image to egnerate traffic

Over time you will see the weights shifting back to their original value as the health based canary release rolls back. 
If you were to update again the deployment to not return errors the canary release woudl resume and complete normally.












TODO the part below is still old


### Metric based canary release

A metric based canary release is driven by a condition based on a single metric or an aggregation metrics.
In this example we will use a metric based canary release to reproduce the behaviour observed with the health based canary release.

![](../images/screen21.png)

As you can see besides changing the type of Policy you also need to specify the **metric** parameter which will tell Vamp Kubist which metric or combination of metrics to use.
Since an aggregated metric can be rather complex it is not possible to pass it as an inline parameter, so, to create this new canary release you will have to send a yaml file with its definition.
To apply this canary release configuration you can rely on the resources created in the previous example and run

```shell
vamp create canaryrelease -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/metric-canary.yaml
```

where the content of metric-canary.yaml is

```yaml
vampService: vs-1
destination: dest-1
port: 9090
subset: subset2
updatePeriod: 30000
updateStep: 10
policies:
  - name: MetricCanaryReleasePolicy
  parameters:
    - metric: internal_upstream_rq_2xx / upstream_rq_total
```

As you can see the specification now explicitly mentions the appropriated policy to be run and also contains the metric parameter with value 

```shell
internal_upstream_rq_2xx / upstream_rq_total
```

This aggreagted metric calculates the ratio of successful responses over the total number of requests.
Metrics names are loosely based on Prometheus metrics names stored by Envoy (they are usually the last part of the metric name).
Some of the available metrics are:

- **internal_upstream_rq_200**
- **internal_upstream_rq_2xx**
- **internal_upstream_rq_500**
- **internal_upstream_rq_503**
- **internal_upstream_rq_5xx**
- **upstream_rq_total**

You can test the outcome the same way you tested the health based canary release, that is by generating traffic towards the service.
This type of canary release, however, comes with a limitation: you can only specify one condition, that is "select the version with the best metric".
To get around this limitation you will have to use a custom canary release

### Custom canary release

To do that you would have to use the last type of Policy available at the moment and configure the Gateway as shown below,
by specifying the condition

````
if ( ( metric "vamp-tutorial-service" 9090 "subset1" "internal_upstream_rq_2xx" / metric "vamp-tutorial-service" 9090 "subset1" "upstream_rq_total" ) > ( metric "vamp-tutorial-service" 9090 "subset2" "internal_upstream_rq_2xx" / metric "vamp-tutorial-service" 9090 "subset2" "upstream_rq_total" ) ) { result = "vamp-tutorial-service 9090 subset1"; } else if ( ( metric "vamp-tutorial-service" 9090 "subset1" "internal_upstream_rq_2xx" / metric "vamp-tutorial-service" 9090 "subset1" "upstream_rq_total" ) < ( metric "vamp-tutorial-service" 9090 "subset2" "internal_upstream_rq_2xx" / metric "vamp-tutorial-service" 9090 "subset2" "upstream_rq_total" ) ) { result = "vamp-tutorial-service 9090 subset2"; } else { result = nil; } result
````

in the value field for the metric parameter

![](../images/screen22.png)

As you can probably understand by looking at the expression above, this Policy will again replicate the behaviour of the previous Policies, but it will allow for much greater flexibility.
You will now be able to specify different versions based on the conditions you are verifying and also to return no version at all (by returning nil) when you want the Policy to not apply any change.

You can now keep on experimenting with the Virtual Service, trying new things. Keep in mind that if you want to return the deployments to the previous state (in which no errors are returned) you can do that by executing

```shell
kubectl replace -f deployments.yaml
```


