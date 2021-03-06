# Terminology

The broader glossary for VAMP (including VampCloud, UI and Kubist) can be found and is maintained here: https://github.com/magneticio/vamp-design-docs/blob/master/01-concepts/01-glossary.md

To get a better understanding of how Kubist works you should keep in mind the meaning of the following terms.
Most of them overlap completely with Kubernetes or Istio entities, but some don't.

- **Project**: a project is a grouping of clusters. This will automatically be created by Lamia.
- **Cluster**: a cluster corresponds to a specific Kubernetes cluster. Just like the Project, this will automatically be created by Kubist.
- **Virtual Cluster**: a virtual cluster is a partition of a Cluster and is represented by a Namespace in Kubernetes.
- **Application**: a grouping of related deployments, defined by a shared label.
- **Deployment**: a Kubernetes deployment which represents a specific version of an Application
- **Destination**: a Vamp Kubist abstraction over a kubernetes service and an istio destination rule. It allows for quickly setting up a new service with its subsets.
- **Service Entry**: an Istio Service Entry, allowing to access external services.
- **Vamp Service**: a wrapper around an Istio virtual service. It manages traffic routing towards one or more destinations.
- **Gateway**: an Istio Gateway exposing an Application Service.
- **Canary Release**: an automated process managing several resources in order to perform canary releasing on a specific Vamp Service.
- **Experiment**: an automated process managing several resources in order to perform A/B testing on a specific Vamp Service.
- **Policy Executor**: an automated process associated to a single entity that periodically runs to perform different action, including running policies (see below). Can be overridden through the API.
- **Policy**: a process that can be triggered by the policy executor of an entity it allows to implement complex behaviour like canary releasing and experiments. For more details refer to the [Performing a canary release](CANARY_RELEASE.md#performing-a-canary-release) section. 

