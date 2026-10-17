# Homelab Developer

> [!NOTE]
> This guide assumes that you have experience with command line tools, kubernetes and linux.

This guide shows you how to deploy an application to the homelab.

## What you end up with

- A dedicated namespace.
- An application deployed in the dedicated namespace
- Persistent storage for your application
- Reaching your application remotely via a hostname
- Accessing the dedicated namespace via the Homelab dashboard UI

## Getting Started

Pre-requisites:

- `kubectl` installed
- IP address to a provisioned Homelab Kubernetes instance (see the [admin guide](user-admin.md#getting-started))
- A provisioned `namespace` and token (see [Provisioning a namespace](user-admin.md#provisioning-a-namespace))


## Deploying an application

This section assumes that you have:

- configured your `kubectl` cli to reach your Homelab cluster using your (see [Accessing the Homelab cluster](user-admin.md#accessing-the-homelab-cluster))
- been provisioned a namespace (for the purpose of this guide, the `namespace` is called *demo*)

### Step 1. Creating a resource file

Create a `app.yaml` file with the following content:

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 0.5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  labels:
    app: demo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      securityContext:
        runAsUser: 1001
        runAsGroup: 1001
      containers:
        - name: simple-web
          image: ghcr.io/this-oliver/simple-web-app:v1.0.1@sha256:12f7dfc283ebf48f50284187bb56269b179b605f15a26a92baec8d836d9d0073
          securityContext:
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
          env:
            - name: LOGS_FILEPATH
              value: /app/logs/requests.txt
          ports:
            - containerPort: 3000
              name: demo-app-http
          volumeMounts:
            - name: storage
              mountPath: /app/logs
      volumes:
        - name: storage
          persistentVolumeClaim:
            claimName: demo-app-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app
spec:
  selector:
    app: demo-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: demo-app-http
---
apiVersion: v1
kind: Secret
metadata:
  name: demo-basic-auth
type: kubernetes.io/basic-auth
stringData:
  username: admin # required field for kubernetes.io/basic-auth
  password: password # required field for kubernetes.io/basic-auth
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: demo-middleware-auth
spec:
  basicAuth:
    secret: demo-basic-auth
---
# See: https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/ingress/
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-app
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: "websecure,web"
    traefik.ingress.kubernetes.io/router.middlewares: "default-demo-middleware-auth@kubernetescrd" # Note: middlewares should follow this format - <NAMESPACE>-<MIDDLEWARE_NAME>@kubernetescrd
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.tls.certresolver: "defaultCertResolver"
spec:
  ingressClassName: traefik
  rules:
  - host: demo.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: demo-app
            port:
              number: 80
```

The `app.yaml` file defines several resources:

- Persistent Volume Claim (`demo-app-pvc`) - stores persistent data
- Deployment (`demo-app`) - deploys your application
- Service (`demo-app`) - exposes your application within the cluster
- Secret (`demo-basic-auth`) and Middleware (`demo-middleware-auth`) - adds an authentication middleware to your application
- Ingress (`demo-app`) - exposes your application externally via `demo.example.com` and sends all requests to the Service

### Step 2. Depploy the resources

Once you have defined the resources in the `app.yaml` file, you can actually create the resources with:

```bash
kubectl apply -f app.yaml -n demo
```

### Step 3. Verify deployment

There are several way to verify that the app is deployed.

```bash
# try to reach the ingress
curl demo.example.com

# inspect the application's pods on the homelab cluster
kubectl get pods -n demo

# inspect the application's deployments on the homelab cluster
kubectl get deployments -n demo
```

## Next steps

- [admin](user-admin.md) — Setup Homelab cluster
- [docs/CONTRIBUTING.md](../CONTRIBUTING.md) — contributing to the project
- [docs/README.md](../README.md) — full documentation index
