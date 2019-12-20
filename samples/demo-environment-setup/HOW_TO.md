# Vamp Kubist Demo setup

Below the list of operations to perform:

- run 
    kubectl apply -f namespace-setup1.yaml
- delete previously created (non system) namespaces from the cluster 
- copy and run the login url from the ui
- copy and run the boostrap cluster command
- copy and run the create virtual cluster command specifying eu-ns as the name
- make sure that dns credentials have been set in the cluster by running 
    vamp merge cluster cluster1 -f mergeCluster.yaml
  credentials can be retrieved from google cloud. Unfortunately the yaml must be created by running
    vamp get cluster cluster1
  and manually editing the file
- before creating the canary release run
    kubectl apply -f single-deployment-setup.yaml
- when you want to deploy a failing version run
    kubectl apply -f failing-deployment-setup
    
Other files can be used to setup additional applications and services or to add more versions


