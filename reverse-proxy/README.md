# Reverse Proxy

The homelab may have a number of services (i.e. [kubernetes](../kubernetes/README.md), [private registry](../registry/README.md)) that need to use the same ports (e.g. HTTP/80 and HTTPS/443) to communicate with the Internet. A reverse proxy is a server that sits between the ports that clients talk to and services running on the homelab. It forwards client requests to the appropriate services and then returns the service's response to the client.

## Usage

The `entrypoint.sh` script sets up a docker container with the Nginx server that listens to port 80 and. The Nginx server is configured to redirect requests from the `registry.oliverrr.net` origin to the `registry` service and all other requests to the `kubernetes` service.

```bash
bash entrypoint.sh
```
