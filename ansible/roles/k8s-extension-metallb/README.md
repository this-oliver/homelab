# MetalLB

How do you reach a service from outside the cluster?

Most cloud providers spin up an IP address and hook it up to your service or, better yet, your loadbalancer.

There is a lot of magic that goes into setting up the IP addresses and hooking them to services which self-hosted instances do not get out-of-the-box. This is where MetalLB comes into the picture and helps you expose specified services outside of your cluster to the external world so long as you give it a range of IP addresses.

## Getting Started

PrerequisiteS:

- [Microk8s (Kubernetes)](../k8s-base-microk8s) installed
- IP Address range (at least one IP address)

## Usage

> [!TIP]
> For more MetalLB examples, visit [MetalLB addon](https://canonical.com/microk8s/docs/addon-metallb)

1. Install MetalLB.

2. Create a `LoadBalancer` service and MetalLB will assign it an IP address within the given range and expose the `port` provided (i.e. 8080).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: headlamp-lb
  namespace: kube-system
spec:
  ports:
  - nodePort: 32023
    port: 8080
    protocol: TCP
    targetPort: http
  selector:
    k8s-app: headlamp
  type: LoadBalancer
```
