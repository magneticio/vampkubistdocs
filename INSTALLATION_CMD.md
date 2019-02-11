## Table of Contents

* [Prerequisites](#prerequisites)
* [Installation steps](#installation-steps)
 * [In cluster installation](#in-cluster-installation)
    * [External database](#external-database)
 * [Out of Cluster installation](#out-of-cluster-installation)

## Prerequisites
* An existing kubernetes cluster with Kubernetes version 1.9 or above installed.
* The current version has been tested only on Google Cloud, so it's recommended that you use that as well, in order to avoid issues.
* Kubectl should be installed on the local computer with authorizations to access the cluster.
* Curl is installed locally.


## Installation steps

Installation of command line client for Mac and Linux:
```shell
base=https://github.com/magneticio/vampkubistcli/releases/download/0.0.14 &&
  curl -L $base/vamp-$(uname -s)-$(uname -m) >/usr/local/bin/vamp &&
  chmod +x /usr/local/bin/vamp
```

Check if your client installed correctly by running version check:
```shell
vamp version
```

## Fresh Cluster installation

It is possible to install Vamp Kubist on a new cluster, with command line client. First, there are some settings for a fresh installation.

Example installation configuration file config.yaml

```yaml
rootPassword: root
databaseUrl:
databaseName: vamp
repoUsername: dockerhubrepousername
repoPassword: dockerhubrepopassword
vampVersion: 0.7.0
mode: IN_CLUSTER
```

**rootPassword:** is the root user password for the installation.
**databaseUrl:** is a comma separated list of MongoDB Urls in the form of mongo://host:port. You can leave it empty for deploying a new installation in your cluster.
**databaseName:** is the database name in the MongoDB.
**repoUsername:** is your docker hub username which has access to vamp kubist repository. **Ask us about it!**
**repoPassword:** is your docker hub password which has access to vamp kubist repository. **Ask us about it!**
**vampVersion:** is the version of the vamp kubist installation. This will be useful for updating the current installation.
**mode:** is the mode of vamp kubist installation. This option gives vamp kubist hints about the environment that it is installed on. Valid values are in IN_CLUSTER and OUT_CLUSTER, which means that if vamp kubist is installed inside a kubernetes cluster or not. Inside a kubernetes cluster, vamp kubist will look for service account credentials.
