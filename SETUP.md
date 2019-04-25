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
vamp create project project1 -f https://github.com/magneticio/vampkubistdocs/samples/project.yaml
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
vamp set project project1
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

## User creation

At this point you might want to create a user for your new project, instead of using the admin user.
In order to do so, first of all set the current project to project1 if you haven't already done that in the previous section, and then execute

```shell
vamp create user user1 -f https://github.com/magneticio/vampkubistdocs/samples/user1.yaml
```

where the yaml content is the user definition, which, in this case, is just the user's password

```yaml
password: pass12
```
 
The newly created user1 will now show up in the user's list, but, if you try to login using its credentials you will see that you are not able to perform any action at all.
The reason for that is that you still need to associate a role and/or a set of permissions to the user.

## User's authorization

### Role creation

The first step in granting access to a new user is to associate it with a new role.
If you run 

```shell
vamp list roles
```

you will notice that there's currently just one role named admin. This is of course the role associated with the default root user.
Let's now create a new role to associate with the new user by running the command

```shell
vamp create role project-admin https://github.com/magneticio/vampkubistdocs/samples/project-admin-role.yaml
```

where project-admin-role.yaml content is

```
permissions:
  project:
    read: true
    write: false
    delete: false
    editAccess: true
  cluster:
    read: true
    write: true
    delete: true
    editAccess: true
  virtualCluster:
    read: true
    write: true
    delete: true
    editAccess: true
  deployment:
    read: true
    write: true
    delete: true
    editAccess: true
  application:
    read: true
    write: true
    delete: true
    editAccess: true
  destination:
    read: true
    write: true
    delete: true
    editAccess: true
  vampService:
    read: true
    write: true
    delete: true
    editAccess: true
  gateway:
    read: true
    write: true
    delete: true
    editAccess: true
  serviceEntry:
    read: true
    write: true
    delete: true
    editAccess: true
  canaryRelease:
    read: true
    write: true
    delete: true
    editAccess: true
  experiment:
    read: true
    write: true
    delete: true
    editAccess: true
```

As you can see the role definition contains a list of permissions, that is a set of flags defining the ability of the user to read, write, delete and edit the access to a specific kind of resource.
In this case, the project-admin role grant full access to any resource inside a project, but only allows the user to change access permissions on the project and nothing else.

### Granting a role to a user 

Now that we have defined a new role we can associate it to the previously create user1 user through the following command.

```shell
vamp grant --user user1 --role project-admin -p project1
```

If you now run 

```shell
vamp get user user1
```

you will get the following result

```yaml
name: user1
roleKeys:
  root=root,project=default: project-admin
```

as you can see the new role project-admin has been added to the user for project=project1.
Keep in mind that, while we associated the user role to a project in this example you can also do the same at the Cluster or Virtual Cluster level with the following commands:

```shell
vamp grant --user user1 --role project-admin -p project1 -c cluster1
```

```shell
vamp grant --user user1 --role project-admin -p project1 -c cluster1 -r virtualcluster1
```

You will now be able to login with 

```shell
vamp login --url https://ip:port --user user1 --cert ./cert.crt
```

Once you did that you will be able to get the project specification for project1 and, then, continue with creating resources in iside it.
At any time you can revoke a user's role with the command

```shell
vamp revoke --user user1 --role project-admin -p project1
```


## Granting permissiosn to a user

What, however, if we wanted to grant a user access to a very specific resource, rather than an entire project?
That can be done by granting permissions.
You can grant a permission on any resource by specifying the permissions read/write/delete/editAcess flags with the following command

```shell
vamp grant --user user1 --permission rwda -p project1 -c cluster1 -r vc1 -a app1 --kind deployment1 --name deploymentname
```

More specifically this command will grant user1 permissions to read, write, delete and edit the access to a deployment1 in application app1which resides in virtual cluster vc1 on cluster cluster1 inside project project1.
Of course if you execute noew this command it will failm since the target resource does not exist, but we can still try this by creating a new project, project2 and then running


```shell
vamp grant --user user1 --permission rwda -p project2
```

You will notice that now user1 is able to view and also delete project2 if it s wishes.
Permissions flags are specifcied with a up to 4 characters pattern following this logic:

r = read
w = write
d - delete
a = edit access

so if you specified a --permission parameter wiht value r you would be only granting read access to the target resource, while if you specified rda you would be specifying read, delete and edit access rights to said resource, but no write access.

## Cluster creation


After setting up and selecting the new Project, it's time to do the same for the Cluster.
This unfortunately still requires some manual operation.
First of all you need to initialise the cluster by creating a namespace and Service Account that would grant Vamp Lamia the authorisations it requires to manage the Cluster itself, and then retrieve the Cluster url and the service account token and certificate.
This may seem complex but you can just run 

```
./initialise-cluster.sh
```

and all the required operations will be performed, returning as an output the url, certificate and token.
Once you have these values you can click on create Cluster in Vamp Lamia and fill out the form as shown below:

![](../images/screen42.png)

Once you submit the Cluster will be imported in Lamia

## Istio setup

Lamia will automatically check for Istio on each cluster it is connected to.
Lamia expects to find the following resources inside the istio-system namesapce:

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

and the following int he logging namespace

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

If any of these resources are missing, Lamia will try to install Istio.

**Keep in mind that if you have pre-existing deployments, then, after the installation is complete, you will need to restart them or trigger a rolling update in order for the Istio Sidecar to be injected.**
