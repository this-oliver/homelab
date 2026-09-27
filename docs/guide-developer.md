# Introduction

This guide shows you how to deploy an application to the homelab. At a high level, this guide walks you through how to:

1. access the homelab with kubectl
2. deploy an application in the homelab

## What you end up with

- A namespace for your app
- A deployment, service and volume for your application
- A ingress route configured to route to your app

## Pre-requisites

- a running homelab (see the [guide for admins](guide-admin.md))
- access to the homelab
- `kubectl` installed

## Getting Started

### Accessing homelab with kubectl

> [!NOTE]
> The `controller` host is the machine that the homelab is running on.

In order to access the homelab cluster from another host, you need to extract the kubeconfig contents and add them to your local `kubectl` setup.

1. In your `controller` host, extract the kubeconfig content:

```bash
# WARNING: The --raw flag displays sensistive info.
# Do not run this command on a machine you do not trust
# and do not share the output with anyone or anywhere
# unless you want to grant full admin access to your
# cluster.
kubectl config view --raw
```

2. In your `local` host, update the kubeconfig file with the extracted contents. The file is usually found in `~/.kube/config`

```bash
# Update the config file with the contents you extracted and save.
nano ~/.kube/config
```

3. Set the context of your `kubectl` to the appropriate cluster. The homelab context is usually `microk8s`.

```bash
kubectl config use-context HOMELAB_CONTEXT
```
