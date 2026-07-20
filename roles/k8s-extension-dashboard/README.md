# Dashboard

This role sets up a dashboard for the Kubernetes (k8s) instance using [Headlamp](https://headlamp.dev/).

## Getting Started

> [!NOTE]
> A ServiceAccount called `headlamp-admin` is created in the `kube-system` namespace with the necessary role to access the dashboard. Find out more at [/files/headlamp/auth.yaml](./files/headlamp/auth.yaml)

PrerequisiteS:

- [Microk8s (Kubernetes)](../k8s-base-microk8s) installed
- [Helm](../k8s-base-helm) installed

1. Generate a token

```bash
kubectl create token headlamp-admin -n kube-system
```

2. Get the IP address and port for the dashboard

```bash
microk8s kubectl get services/headlamp-lb -n kube-system

# NAME          TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
# headlamp-lb   LoadBalancer   10.152.183.19   192.168.50.180   8080:32023/TCP   125m
```

In the example above, you can access the dashboard at [http://192.168.50.180:8080](http://192.168.50.180:8080).

## Usage

To access the dashboard, you'll need to find the service that is serving the dashboard:

```bash
microk8s kubectl get services/headlamp-lb -n kube-system

# NAME          TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
# headlamp-lb   LoadBalancer   10.152.183.19   192.168.50.180   8080:32023/TCP   125m
```

In the example above, you can see that the `headlamp-lb` service exposes the dashboard to the external IP 192.168.50.180 with port 8080. Using this information, it is possible to access the dashboard at [http://192.168.50.180:8080](http://192.168.50.180:8080).
