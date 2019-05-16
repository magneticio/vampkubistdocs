# Cluster setup

If Vamp Kubist has been installed inside a Cluster it will automatically create a default Project and Cluster.
If you are instead running Vamp Kubist outside a Cluster there are a few extra steps you need to take.

# Table of contents

* [Project creation](#project-creation)
* [User creation](#user-creation)
* [Cluster creation](#cluster-creation)
* [Istio setup](#istio-setup)

## Project creation

First of all you need to create a Project.
A Vamp Kubist Project is simply an abstraction grouping one of more Clusters.
You can create a new project, named project1, by running the following command:

```shell
vamp create project project1 -f ./samples/project.yaml
```

Where project.yaml contains the project configuration. 

```yaml
metadata:
  key1: value1
  key2: value2
```

If you don't have files locally you can also load them from a remote location. 
Resources for this readme are also located at https://github.com/magneticio/vampkubistdocs so the above command can also be rewitten as

```shell
vamp create project project1 -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/project.yaml
```

The client allows you to pass a specifications as a json, yaml and either as a string or from a file. This command reads the input as json and passes the empty json object as configuration. 
A Project doesn't have any mandatory fields, so an empty json is still valid.
In case you want to just specify an empty definition you can add the init parameter, as shown below:

```shell
vamp create project project1 --init
```

This will just specify an empty definition for the new project.
Once the Project has been created it can be selected as the current project by running:

```shell
vamp config set -p project1
```

At any time you can list the available projects by running 

```shell
vamp list projects
```

or retrieve the project definition by running

```shell
vamp get project project1
```

If you want to delete a project simply run

```shell
vamp delete project project1
```

Mind the fact that, doing that, will trigger the deletion of every resource in that project save for clusters, virtual clusters and deployments.
Create, list, get and delete commands are available for all other Vamp Kubist resources so we will refer to them only when needed in the continuation of this document.


## Cluster creation

After setting the current project to project1, granting user user1 the appropriate role and logging in with its credentials, you can proceed with adding and bootstrapping a new cluster.
First make sure you have installed kubectl and authenticated to the cluster you want to be managed by vamp Kubist. 
The command line client will set up a service account user in your cluster and set up credentials to connect to your cluster in vamp.
For this example, it is recommended that you have a cluster of at least 5 nodes, 2 CPU and 8 GB Ram per node. Otherwise you can have pending pods and initialisation will not finish.
If everything is set, just run 

```
vamp bootstrap cluster cluster1
```

A simple cluster configuration requires;
* a url
* a cacertdata
* a serviceaccount_token

You can check if your cluster is properly configured by running a get to the cluster.

```shell
vamp get cluster cluster1
```

with kubectl you can check the namespaces of vamp-system and istio-system and logging is created.
Vamp Kubist will run a job in vamp-system namespace to make sure that everything is properly installed and continue running this job until it is finished. Make sure that you have enough resources and there are no pending pods or pods in Crash Loop.

If you have the watch command installed, we recommended running it to see installation process in action. You can do so with

```shell
watch kubectl get pods --all-namespaces
```

You can also use kubectl to check whether there are pending pods, which is a common issue when there are not enough resources:

```shell
kubectl get pods --all-namespaces | grep Pending
```

If there are pending pods after some a few minutes, it is recommended to diagnose the issue, and if it is a resource issue, scale up the cluster.
While working on the same cluster it is recommended to set it as default by:

```shell
vamp config set -c cluster1
```

### Istio setup

As we said, when bootstrapping a cluster, a job will run inside the vamp-system namespace to install istio.
This job is triggered if Vamp Kubist finds that any of these resources, making up the default istio installation, is missing on the cluster inside the istio-system namespace.

**Deployments:**

- grafana                   
- istio-citadel             
- istio-egressgateway       
- istio-ingressgateway      
- istio-pilot               
- istio-policy              
- istio-sidecar-injector    
- istio-statsd-prom-bridge  
- istio-telemetry           
- istio-tracing             
- prometheus                
- servicegraph      

**Services:**

- grafana                   
- istio-citadel             
- istio-egressgateway       
- istio-ingressgateway      
- istio-pilot               
- istio-policy              
- istio-sidecar-injector    
- istio-statsd-prom-bridge  
- istio-telemetry           
- prometheus                
- prometheus-external       
- servicegraph              
- tracing                   
- zipkin                    

**Service Accounts:**

- default
- istio-citadel-service-account          
- istio-cleanup-old-ca-service-account   
- istio-egressgateway-service-account    
- istio-ingressgateway-service-account   
- istio-mixer-post-install-account       
- istio-mixer-service-account            
- istio-pilot-service-account            
- istio-sidecar-injector-service-account 
- prometheus   

**ConfigMaps:**

- istio                                   
- istio-ingress-controller-leader-istio   
- istio-mixer-custom-resources            
- istio-sidecar-injector                  
- istio-statsd-prom-bridge                
- prometheus                              

Besides these resources there are also some others that are required to handle metrics.
These are located inside the logging namespace.

**Deployments:**

- elasticsearch  
- fluentd-es     
- kibana         

**Services:**

- elasticsearch         
- elasticsearch-external
- fluentd-es            
- kibana                             

**ConfigMaps:**

- fluentd-es-config
- mapping-config

If any of these resources are missing, Vamp Kubist will try to install Istio.

**Keep in mind that if you have pre-existing deployments, then, after the installation is complete, you will need to restart them or trigger a rolling update in order for the Istio Sidecar to be injected.**


## Creating namespaces and deployments

Now that we have Vamp Kubist running in a cluster and managing both its own cluster and another one we can think about creating a namespace and some deployments within it.
Vamp Kubist currently doesn't manage the creation of namespaces and deployments, but simply detects and import them.
To showcase that we will use kubectl to create a few sample deployments.
You can do so by running

```shell
kubectl apply -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/namespace-setup.yaml
```

This will create a namespace named kubist-demo and two deployments named deployment1 and deployment2.
We can now tell Vamp Kubist to import the kubist-demo namespace by running the command

```shell
vamp create virtual_cluster kubist-demo --init
```

This will prompt Vamp Kubist to add the following labels to the kubist-demo namespace on kubernetes:

```yaml
vamp-managed: enabled
istio-injection: enabled
```

The vamp-managed flag tells Vamp Kubist to import the namespace and its content by creating a new virtual cluster with the same name.
A virtual cluster is nothing more than a wrapper of a kubernetes namespace and it is used by Vamp Kubist to keep track of its content and, optionally, to associate some metadata with it.
In our example we have no need for such metadata, hence why we are specifying the --init flag instead of providing a yaml file reference with -f.
On the other hand, the istio-injection flag enables istio sidecar automatic injection in the pods inside the virtual cluster.
Mind the fact that, since we are importing a virtual cluster with pre-existing deployments, those deployments will need to be restarted in order for the pod to be injected.
Vamp Kubist will take care of that without the need for the user to do anything.
You can now list the virtualclusters to verify that everything is in order.

```shell
vamp list virtual_clusters
```

The output of this command should be a single element list like the one below.

```shell
- kubist-demo```
```

Now set the kubist-demo virtual cluster as the default one.

```shell
vamp config set -r kubist-demo
```

The deployments inside this virtual-cluster share a common label app: demo-app. This tells Vamp Kubist that all these deployments are actually different versions of the same application.
Hence Vamp Kubist will import them grouped in a single application entity.
You can see it by running 

```shell
vamp list applications
```

which will return a single result list containing the demo-app application.
If you now get the details of this application by running

```shell
vamp get application demo-app
```

you will be presented with the following:

```yaml
clusterName: cluster1
name: application
projectName: default
specification:
  metadata: {}
  policies: []
status:
  deployments:
  - deployment1
  - deployment2
virtualClusterName: kubist-demo
```

as you can see inside the application status there is a list of the deployments belonging to this application.
You can now get a deployment specification by running.

```shell
vamp get deployment deployment1 -a demo-app
```

At this point you have a set of deployments grouped into an application inside a virtual cluster. 
But what can you do with all that you set up? To delve into that you can take a look at..
