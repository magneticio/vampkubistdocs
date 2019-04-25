## Table of Contents

* [Prerequisites](#prerequisites)
* [Installation steps](#installation-steps)

## Prerequisites
* An existing kubernetes cluster with Kubernetes version 1.9 or above installed.
* The current version has been tested only on Google Cloud, so it's recommended that you use that as well, in order to avoid issues.
* Kubectl should be installed on the local computer with authorizations to access the cluster.
* Curl should be installed locally.


## Installation steps

To install the client on Mac or Linux, run the following command:

```shell
base=https://github.com/magneticio/vampkubistcli/releases/download/0.0.14 &&
  curl -L $base/vamp-$(uname -s)-$(uname -m) >/usr/local/bin/vamp &&
  chmod +x /usr/local/bin/vamp
```

Now you can check if your client is installed correctly by running version check:

```shell
vamp version
```

## Fresh Cluster installation

It is possible to install Vamp Kubist on a new cluster, with command line client. 
this requires, however, setting up correctly the client configuration file.

You can see below and example of the Vamp Kubist config.yaml file.

```yaml
rootPassword: root12
databaseUrl:
databaseName: vamp
repoUsername: dockerhubrepousername
repoPassword: dockerhubrepopassword
vampVersion: 0.7.0
mode: IN_CLUSTER
```

Only rootPassword, repoUsername, repoPassword are mandatory fields, so the minimum configuration file would look like this:

```yaml
rootPassword: root12
repoUsername: dockerhubrepousername
repoPassword: dockerhubrepopassword
```

Let's now go through all the configuration parameters to better understand what each one means.

**rootPassword:** is the root user password for the installation.  Mind the fact that the password should be at least 6 characters long.

**databaseUrl:** is a comma separated list of MongoDB Urls in the form of mongo://host:port. You can leave it empty for deploying a new installation in your cluster.

**databaseName:** is the database name in the MongoDB.

**repoUsername:** is your docker hub username which has access to vamp kubist repository. **Ask us about it!**

**repoPassword:** is your docker hub password which has access to vamp kubist repository. **Ask us about it!**

**vampVersion:** is the version of the vamp kubist installation. This will be useful for updating the current installation.

**mode:** is the mode of the Vamp Kubist installation. This option gives vamp kubist hints about the environment that it is installed on. Valid values are in IN_CLUSTER and OUT_CLUSTER, depending on whether you want to install Vamp Kubist inside a kubernetes cluster or not. Inside a kubernetes cluster, vamp kubist will look for the service account credentials.

Assuming a valid config.yml file is available on your the folder, you can run:

```shell
vamp install --configuration ./config.yml --certificate-output-path ./cert.crt
```

It will print the installation steps and also the login command to login as root.
The **vamp install** command is reentrant and it can be run many times if the first installation fails for any reason. Don't worry about making mistakes.
Upon execution the command will also write the generated certificate in the path specified with the --certificate-output-path parameter, so that you can later use it to login.

When the installation has been completed the command will end with the following output:

```shell
...
Vamp Service Installed.
Login with:
vamp login --url https://ip:port --user root --cert ./cert.crt
```

Copy paste the recommended command and execute it to login as root. You will be asked for the password that has been specifyied in the configuration file. Also, it is recommended to keep the certificate file. It is possible to get the certificate file by running the install command again.

Congratulations, basic setup is complete!
