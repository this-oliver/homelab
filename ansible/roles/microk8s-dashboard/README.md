# Dashboard

This role sets up a dashboard for the MicroK8s instance uisng [Headlamp](https://headlamp.dev/).

## Usage

> [!NOTE]
> A ServiceAccount called `headlamp-admin` is created in the `kube-system` namespace with the necessary role to access the dashboard. Find out more at [/files/headlamp/auth.yaml]()

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
