# Basic Tutorial

In this tutorial we will show how to create a new service and expose it to the outside.
We will achieve that by combining destinations, vamp services and gateways.

## Prerequisites

A running cluster containing a single virtual cluster and an application with 3 deployments.
You also need access to Google Cloud DNS, in order to expose your service.

## Destination creation

We will assume for this tutorial that you have a cluster similar to the one described in the [cluster setup](SETUP.md) section, but anything similar will also work.
The first step in order to expose a service is to create a destination.
A destination is a grouping of a kubernetes service and a istio destination rule.
First of all make sure that you set your defaults so that kubist-demo is the default virtual cluster.

```shell
vamp config set -p project1 -c cluster1 -r kubist-demo
```

With that out of the way let's create the destination.

```shell
vamp create destination dest-1 -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/destination.yaml
```

Let's now take a look at the destination.yaml.

```yaml
application: kubist-demo
ports:
  - name: http
    port: 9191
    targetPort: 9191
    protocol: TCP
subsets:
  subset1:
    labels:
      deployment: deployment1
  subset2:
    labels:
      deployment: deployment2
```

As you can see we are referencing application kubist-demo to tell Vamp Kubist that that is the target of this destination.
Then we are defining which ports we want to be available, in this case we are interested only in port 9191.
Lastly we define 2 subsets, one for each deployment, using the deployment label to identify them. 
If you don't have a deployment label you can use any other one or a combination of different labels.
The purpose of subsets is basically to identify different versions of the deployment in order to be able, at a later stage, to route traffic to them.
You can now verify that the destination has been created by running 

```shell
vamp list destination
```

To get a cleare picture of what happened on the cluster you can use kubectl and run 

```shell
vamp get service dest1 -n=kubist-demo -o yaml
kubectl get destinationrule dest1 -n=kubist-demo -o yaml
```

As you can see a service and destinationrule have been created using the values defined in the destination yaml.
More specifically the port has been used to set up the service, while the subsets have been used to create the destinationrule specification.

## Gateway creation

Let's now create a gateway to allow for our service to be exposed outside the cluster.
A Vamp Kubist gateway is a wrapper around a Istio gateway. 
Differently from Istio, however, upon creating a gateway, Vamp Kubist will also set up a load balancer service so as to allow you to quickly create multiple gateways instead of having to rely on a single one.
Vamp Kubist integrates with Let’s Encrypt in order to allow for getting SSL/TLS certificates.
The integration with Let's Encrypt is based on DNS so, before proceeding you should make sure that you have access to Google Cloud DNS.
After you made sure of that, the first step is the Zone domain creation, which is needed for name server redirection. 
Some name service providers have fixed name servers but Google Cloud DNS creates a set of 4 name servers per zone. You need to set these name servers as your name servers in your domain provider’s settings. This is a one time operation per domain.
For our tests we registered a domain democluster.net at [name.com](https://www.name.com/). This is an example name server configuration in name.com

![](images/screen1.png)

Check if your name server configuration is updated. It is cached over the internet and it may take up to 48 hours to actually update. In our case it took around 2 hours.
Note that Google DNS has multiple sets of nameservers so when a zone is created you should check the nameservers and update them. You can go to Google DNS page and open your zone, there will be the list of name servers under the type NS.

![](images/screen2.png)

When a gateway is created, Vamp Kubist will set up the zone record for you and subsequently list the name servers in the UI. Let’s Encrypt authentication requires the name servers to be updated.
At this point you need to tell Vamp Kubist to use Google Cloud DNS. You can do that by updating the cluster1 specification with two extra metadata fields: 
- google_project_id: which is of course you google project id
- google_service_account: which is the service account key in json format. You can easily obtain it by following [this](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) guide.

To update the cluster definition you can run

```shell
vamp edit cluster cluster1
```

And edit the specification by adding the two new parameters.
The new specification yaml for the cluster should then look like this:

```yaml
metadata:
  cacertdata: somecert
  serviceaccount_token: someserviceaccount
  url: https://0.0.0.1
  google_project_id: some project id
  google_service_account: >
                          "{
                             "type": "service_account",
                             "project_id": "some project id",
                             "private_key_id": "some private key id",
                             "private_key": "-----BEGIN PRIVATE KEY-----\nSome private ket\n-----END PRIVATE KEY-----\n",
                             "client_email": "email.com",
                             "client_id": "104717857076852671677",
                             "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                             "token_uri": "https://accounts.google.com/o/oauth2/token",
                             "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                             "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/dns-service-account%40vamp-177714.iam.gserviceaccount.com"
                          }"
```

you can just save it to a file and use it to perform the update by running:

```shell
vamp update cluster cluster1 -f yourfile.yaml
```

Alternatively, if you don't want to go through the trouble of manually editing the specification, you can specify the same values in the metadata of the enclosing project or on the virtual cluster itself.
Once that is done you can check that the update was successfull by getting the cluster specification with 
 
```shell
vamp get cluster cluster1
```
 
Assuming everything looks good you can now create a gateway. first of all download the [gateway specification](https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/gateway.yaml) and edit the hostname to the appropriate value.
Once that is done run

```shell
vamp create gateway gw-1 -f ./yougateway.yaml
```

where the gateway specification is

```shell
servers:
  - port: 80
    protocol: http
    hosts:
      - kubist-demo.democluster.net
```

As you can see we are specifying a hostname for the gateway. 
**Mind the fact that you should change this hostname to avoid conflicts.**
You can verify what happened on the cluster using kubectl with

```shell
kubectl get gateway -n=kubist-demo -o yaml
```

You will be able to see that a gateway named gw-1 has been created with the same specification provided in the yaml.
You can also check inside the istio-system namespace in order to take a look at the additional resources that have been created.
You should be able to find a deployment, a service and a horizontal pod autoscaler, all of them with the same name: gw1-gateway.

## Vamp Service creation

Even though we successfully created a gateway we are still unable to reach the service. 
To do that we need one final step, that is to create a vamp service in order to handle the routing of requests towards it.
A vamp service is a wrapper around an istio virtual service. Just like its istio counterpart it allows for the specification of different weights and conditions for each of its route.
A vamp service can potentially manage traffic coming from different gateways and directed towards different destinations, but for now we will limit ourselves to just one gateway and one destination.
To create the vamp service first download the [vamp service specification](https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/vampservice.yaml) and edit the hostname to whatever you specified for the gateway, then execute

```shell
vamp create vampservice vs1 -f ./yourvampservice.yaml
```

where the content of vampservice.yaml is 

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

Let's go through all the fields of the specification one by one:
- gateways: this is a list of all the gateways connected to the vampservice. In our case that would be only gw1.
- hosts: this is the list of hosts associated with this vamp service. In our example the only host is vamp-gw1.democluster.net (or whatever hostname you used in the gateway definition).
- routes: the list of routes. Each one of them is defined by:
    - protocol: the protocol for this route
    - weights: the list of destinations and corresponding weights. Each one is defined by:
        - destination: the destination name. In our case that would be dest-1.
        - port: the optional destination port. Looking at our destination definition it is easy to understand this should be 9191, but we can also leave it empty since that is the only port we defined.
        - version: the optional target subset. In our case we will use subset1 and subset2 in order to split traffic between the two.
        - weight: the actual weight, specifying the percentage of requests that will be directed towards each destination (meaning combination of destination, port and subset). In our case since we want only subset1 to be available we specified a weight of 100 for it and 0 for subset2. Mind the fact that the sum of weights in a single route should always be 100.
- exposeInternally: a flag that tells Vamp Kubist to expose the vamp service internally. When this flag is selected an extra kubernetes service will be created in order to expose the vamp service with its fully qualified name, that is vs1.kubist-demo.svc.cluster.local.

You can verify that the vamp service has been create with kubectl by running

```shell
kubectl get virtualservice vs1 -n=kubist-demo
```          

This will return the underlying virtual service.
If you exposed the service internally you can also verify that the kubernetes service has been created by running

```shell
kubectl get service vs1 -n=kubist-demo
```          

At this point you should be able to access the new service at the hostname you specified.
If everything works correctly this is the page you should be seeing.

![](images/screen3.png)

By running 

```shell
vamp edit vampservice vs-1 
```          

you can change the weights any way you like, as long as the total sum is 100.
If, for example, you were to set the weights to 50/50 you would be able to see alternating colouring for the background by hitting refresh repeatedly, thus proving that you are actually landing on different versions.
