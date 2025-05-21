# Reverse Proxy

The homelab may have a number of services (i.e. [kubernetes](../kubernetes/README.md), [private registry](../registry/README.md)) that need to use the same ports (e.g. HTTP/80 and HTTPS/443) to communicate with the Internet. A reverse proxy is a server that sits between the ports that clients talk to and services running on the homelab. It forwards client requests to the appropriate services and then returns the service's response to the client.
