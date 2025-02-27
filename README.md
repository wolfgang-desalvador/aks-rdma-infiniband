# AKS RDMA/Infiniband Support
To support running HPC workloads using RDMA/Infiniband on AKS, this repo provides a daemonset to install the necessary RDMA drivers and device plugins on HPC-series VMs. 

## Prerequisites
This installation assumes you have the following setup:
- AKS cluster with Infiniband feature flag enabled:
    - enable flag: `az feature register --name AKSInfinibandSupport --namespace Microsoft.ContainerService`
    - check status: `az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKSInfinibandSupport')].{Name:name,State:properties.state}"`
    - register when ready: `az provider register --namespace Microsoft.ContainerService`
- AKS nodepool with RDMA-capable skus:
    - Refer to the HPC docs: https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-hpc
    - Sample command to create AKS nodepool with HPC-sku (assuming aks resource group and cluster already created): 
        - `az aks nodepool add --resource-group <resource group name> --cluster-name <cluster name> --name rdmanp --node-count 2 --node-vm-size Standard_HB120rs_v2`
        - Note: VM size names are case-sensitive
    
## Configuration
Depending on intended usage there are alterations that can be made to the `shared-hca-images/configMap.yaml`:
- if you only intended to assign a single pod to each node, keep the `rdmaHcaMax` parameter as 1
- if you want to run parallel workloads with multiple pods per node, modify `rdmaHcaMax` to be how many pods you want on a single node
    - Note: this will affect the latency, since the pods will be sharing the bandwidth

## Quickstart
1. Clone repository
2. Build & push image (this image will later be available on mcr):
    - build image locally specifying target AKS Ubuntu version: `docker build --build-arg UBUNTU_VERSION=18.04 --build-arg MELLANOX_VERSION=5.6-2.0.9.0 -t <image-name> .` or `docker build --build-arg UBUNTU_VERSION=22.04 --build-arg MELLANOX_VERSION=5.8-2.0.3.0 -t <image-name> .`
    - push image to ACR or other registry: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli
        - https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-kubernetes#create-an-image-pull-secret
    - replace image name in `shared-hca-images/driver-installation.yml` with your image name
3. Deploy manifests:
    - `kubectl apply -k shared-hca-images/.`
4. Check installation logs to confirm driver installation 
    -  `kubectl get pods`
    -  `kubectl logs <name of installation pod>`
    -  Wait until you see message indicating installation completed successfully
5. Deploy MPI workload (refer to example test pods, `test-rdma-pods.yaml`, specifically the resources section to see how to pull resources)
    -  `kubectl apply -f <rdma workload>`


** This solution is modelled after: https://github.com/alexeldeib/aks-fpga **

## Enabling IPoIB (EXPERIMENTAL)

### DO NOT TEST THIS ON PRODUCTION CLUSTERS - EXPERIMENTAL FEATURE

In order to enable IPoIB, the `ib0` network card needs to be attached to the Pods.

In order to realize this, one of the most common ways is to use [Multus CNI plugin](https://github.com/k8snetworkplumbingwg/multus-cni).

Azure Kubernetes Service does not officially support Multus CNI or multiple network cards, so please use at your own risk.

In order to install Multus CNI on the AKS cluster use the followjng command from a `kubectl` enabled shell:

```bash
git clone https://github.com/k8snetworkplumbingwg/multus-cni.git
cd multus-cni
cat ./deployments/multus-daemonset-thick.yml | kubectl apply -f -
```

In order to attach `ib0` network card to a Pod, the following annotation should be added to the Pod spec:

```yml
    ...
    metadata:
       annotations:
           k8s.v1.cni.cncf.io/networks: ib0@ib0
    ...
```

This will allow to expose `ib0` inside the Pod namespace.

Please be aware that current approach uses a `host-device` type this implies that `ib0` while Pods are running on a node will be removed from host namespace and moved completely to Pod namespace.

This has also security implications since the `ib0` adapter will bypass AKS network layer and be directly attached to the Pod.

For more details, refer to: https://www.cni.dev/plugins/current/main/host-device/

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
