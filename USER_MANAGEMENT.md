# User Management

Vamp Kubist allows you to create new users and associate different, customizable roles to them in order to control their rights to access resources.
It is recommended to use the root user only for the initial setup and rely on other users for everything else.

## Prerequisites

You should have completed the Installation and logged in as a user who has user create permission such as root user.
You should also have a second project, besides the default one.

## User creation

If you followed the [cluster setup](SETUP.md) section, you should have a project named project1 otherwise you should create it before continuing.
When the project has been created, set it as the default project and then you can proceed with creating a new user named user1.
In order to do so execute

```shell
vamp create user user1 -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/user1.yaml
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
vamp create role project-admin -f https://raw.githubusercontent.com/magneticio/vampkubistdocs/master/samples/project-admin-role.yaml
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

Now that we have defined a new role we can associate it to the previously create user1 user.
If you followed the [cluster setup](SETUP.md) section, you should have a project named project1 and you will be able to run the following command. 
 
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

so if you specified a --permission parameter with value r you would be only granting read access to the target resource, while if you specified rda you would be specifying read, delete and edit access rights to said resource, but no write access.
