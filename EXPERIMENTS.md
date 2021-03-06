# Experiments

Experiments are a Vamp Kubist feature that quickly allows users to run A/B testing over a service.
This is achieved by setting up a specific policy that interacts with a target vamp service.

## Table of contents

* [Prerequisites](#prerequisites)
* [Creating an Experiment](#creating-an-experiment)
* [Setting up a custom data source](#setting-up-a-custom-data-source)

## Prerequisites

In order to perform a experiment you need to have an application with at least two deployments installed in the cluster.
On top of that you will also need a destination, defining at least two subsets, a vamp service, directing the traffic to one of the subsets, and a gateway, to expose the service.
To quickly get such an environment, you can follow the [setup section](SETUP.md).

## Creating an Experiment

In order to create an experiment you can execute

```shell
vamp create experiment ex-1 -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/experiment.yaml
```

where the yaml file's content is

```yaml
vampServiceName: vs-1
period: 1
step: 10
destinations:
  - destination: dest-1
    tags:
      - test1
    port: 9191
    subset: subset1
    target: /endpoint1
  - destination: dest-1
    tags:
      - test2
    port: 9191
    subset: subset2
    target: /endpoint1
```

To clarify what is going to happen when you execute this command, let's first go through the purpose of each field:

- **Vamp Service Name**: the name of the Vamp Service on which you want to run the A/B testing.
- **Period in minutes**: the time interval in minutes after which periodic updates to the configuration will happen.
- **Step**: the amount by which the route's weights will shift at each update.
- **Tags**: a descriptive value for a specific version of the service.
- **Subset**: the subset of the service.
- **Target**: the url that we want the users to reach to consider the test a success.

When the command is executed the Experiment will update the vamp service with a new configuration, which you will be able to observe by running

```shell
vamp get vampservice vs-1
```

and looking at the currentSpecification field in the response.
What you will see will look like this:

```yaml
experiment: ex-1
exposeInternally: true
gateways:
- gw-1
- mesh
hosts:
- kubist-demo.democluster.net
- vs-1.kubist-demo.svc.cluster.local
labels: {}
metadata: {}
policies: []
routes:
- condition: ' ( cookie "ex-1" exact "dest-1-9191-subset1" ) '
  protocol: http
  weights:
  - destination: dest-1
    port: 9191
    version: subset1
    weight: 100
- condition: ' ( cookie "ex-1" exact "dest-1-9191-subset2" ) '
  protocol: http
  weights:
  - destination: dest-1
    port: 9191
    version: subset2
    weight: 100
- protocol: http
  weights:
  - destination: ex-1
    port: 9191
    version: dest-1-9191-subset1
    weight: 50
  - destination: ex-1
    port: 9191
    version: dest-1-9191-subset2
    weight: 50
virtualServiceStatuses:
- destination: dest-1
port: 9191
status: true
subset: subset1
- destination: dest-1
port: 9191
status: true
subset: subset2
- destination: ex-1
port: 9191
status: true
subset: dest-1-9191-subset1
- destination: ex-1
port: 9191
status: true
subset: dest-1-9191-subset2
virtualClusterName: kubist-demo
```

As you can see the specification is significantly changed. 
The vamp service defines three routes. The first two are easy to understand: they each lead to one of the deployed versions. The third one is evenly load balancing between two versions of a cookie server.
The purpose of this configuration is to direct new visitors towards the cookie server which will then set cookies identifying them as a specific user and assigning them to one of the configured subsets.
Once this is done, the cookie server redirects the user back to the original url, sending him back through the vamp service. This time, however, having a subset cookie, one of the conditions set on the first two routes applies and the user is forwarded to a specific version of the landing page. This is seamless in browsers, so users don't experience any interruption, and adds a neglectable overhead, since it affect only one call per user .
Thanks to our reliance on cookies, we are able to provide users with a consistent experience while continuing our test, meaning that subsequent requests coming from the same user in a short period of time will always go to the same version.
Depending on the test results, the policy defined on the vamp service will then move more users to more successful version, i.e. versions with a better ratio of users that reached the target over total number of users that reached the landing page.
This is of course achieved by changing the weights of the cookie servers routes according to the step value defined in the experiment configuration.
To handle all of this the experiment created an extra destination ex-1 and two deployments ex-1-dest-1-9191-subset1 and ex-1-dest-1-9191-subset2 which are running the cookie servers for each cookie value.

You can test the experiment by using the tester docker image shown in the [canary release section](CANARY_RELEASE.md).
To do that execute

```shell
docker run -it -e EXPERIMENT_NAME="ex-1" -e EXPERIMENT_BIAS=0.7 -e EXPERIMENT_BIASED_COOKIE="ex-1=dest-1-9191-subset1" -e EXPERIMENT_COOKIE="ex-1" -e URL_LANDING_PAGE=http://kubist-demo.democluster.net -e URL_TARGET_PAGE=http://kubist-demo.democluster.net/cart?variant_id=1 -e NUMBER_OF_AGENTS=100 magneticio/experiment-tester:0.0.3
```

This will start an application that will generate traffic towards the specified hostname.
For a more detailed explanation of what we are trying to accomplish let's look at all the environment variables we are setting and at their meaning

- EXPERIMENT_NAME: the experiment name
- EXPERIMENT_COOKIE: the experiment cookie name
- URL_LANDING_PAGE: the landing page url. This is the page to which all requests will go.
- URL_TARGET_PAGE: the target page url, that is the page that is used by the experiment logic to assess the success rate of a specific subset. Only a subset of the total users will go this url after visiting the landing page.
- EXPERIMENT_BIASED_COOKIE: the cookie value towards which we want to bias the traffic that is going to be generated. This basically indicates the subset that we want to see prevailing in the experiment. Take care of noticing that a subset is identified in this case by the combination of destination, port and subset, so that in the example the value is dest-1-9191-subset1.
- EXPERIMENT_BIAS: the bias ratio of the traffic. This tells the tester application by how much requests with the biased cookie should be more likely to reach the target.

After looking at the environment variables it should be clear that we are generating the traffic in a way that will substantially favor subset1 over subset2.
So, while running this test you will see the weights in the vamp service gradually shifting towards subset1, until the point were subset2 will become unavailable, thus effectively completing the A/B testing.

## Setting up a custom data source

The previous example relies on Elasticsearch in order to obtain the data required to shift the Virtual Service's configuration as desired.
But what if one wanted to use some other data source or, rather, to use entirely different types of data?
That is also achievable through Vamp Kubist thanks to its support for custom data sources.
Vamp Kubist has been developed with the clear goal of making it as modular as possible. For this reason its architecture is based on the usage of drivers, that is components that can be easily replaced for each of the entities that Vamp Kubist is managing. 
In this specific case you would want to replace the driver responsible for gathering metrics from Elasticsearch with another one that can interface with a custom data source.
That can be very easily done, provided the data source meets some requirements. 
For the sake of simplicity we are providing a simple nodejs webservice that will return random values at each requests.
Everything that is required of this webservice is that it exposes a "/stats" endpoint that will respond to a request of the kind "/stats?subset=subset1" with the data pertaining to subset1 presented in json format. 
You can see below an example of such a json.

```json
{
  "average" : 1.2,
  "standardDeviation" : 0.8,
  "numberOfElements" : 3875
}
```

In this sample the number of elements is the number of users that got to the landing page of the service we are testing, while the average and standard deviation are calculated over the number of successful interactions of each user, i.e. the interactions that reached the specified target.
To deploy our sample data source run

```shell
kubectl apply -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/data-source.yaml
```

After the command completes you will be able to see, by either using the client or kubectl, that a new deployment datasource has been created inside a new datasource-app application.
Now you need to expose the data source to the outside world.
The reason for this is that it should be reachable by Vamp Kubist, which, in the environment we created in the [setup section](SETUP.md), is running on the default cluster, while we are currently working on cluster1.
As shown before, in order to achieve this, you will need to create a destination, gateway and vamp service.
The following three files, provide the definition for such resources, you should just take care to replace the host name with a new one that you deem appropriate.

```shell
https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/data-source-destination.yaml

https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/data-source-gateway.yaml

https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/data-source-vampservice.yaml
```

Now you can use Vamp Kubist client to check that all resources have been set up correctly and also query the stats endpoint of the newly deployed service to verify that it is reachable.
Once you are comfortable with proceeding, all you need to do is set up the experiment by running

```shell
vamp update experiment -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/experiment-custom-data-source.yaml
```

which will apply the following configuration to experiment ex-1

```yaml
vampServiceName: vs-1
period: 1
step: 10
destinations:
  - destination: dest-1
    tags:
      - test1
    port: 9191
    subset: subset1
    target: /cart?variant_id=1
  - destination: dest-1
    tags:
      - test2
    port: 9191
    subset: subset2
    target: /cart?variant_id=1
metadata:
  complexmetricsdriver: custom
dataSourcePath: http://kubist-demo-datasource.democluster.net/stats
```

Compared to the configuration used in the previous example the notable differences are that in this case you will be specifying a data source path with value **http://kubist-datasource.kubist-demo.svc.cluster.local:9191/stats**, to tell Vamp Kubist to use the data source exposed by that service, and you will also add a new metadata with key **complexmetricsdriver** and value **custom** in order to have Vamp Kubist use the custom implementation of the metrics driver. 
Once the experiment has been set up, it will behave in the same way as the previous one, but using the newly defined data source.
