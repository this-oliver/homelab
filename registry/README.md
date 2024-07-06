# Private Registry

[DockerHub](https://hub.docker.com) is a great place to store and share docker images, but sometimes you need to store images privately which they limit to 1 private repository. To solve this problem, you can host your own private registry to restrict access to your images (and fully own your data).

The homelab uses [distribution](https://distribution.github.io/distribution/), an open-source docker registry, to store and manage docker images.

## Getting Started

Pre-requisites:

- Docker
- (Optional) Domain Name and SSL Certificate

For a basic setup:

```bash
docker compose up --detach
```

### Adding SSL

If you want to expose the registry to the internet, you'll need to setup SSL to encrypt the connection between the client and the registry. To do this, add an SSL certificate and private key to the `./certs` directory.

> [!WARNING]
> The docker compose below assumes that the certificate is named `domain.crt` and the private key is named `domain.key`. If you have different names, you'll need to update the [docker-compose.remote.yaml](./docker-compose.remote.yaml) file.

```bash
docker compose -f docker-compose.ssl.yaml up --detach
```

### Adding Authentication

> [!NOTE]
> You cannot authenticate over an insecure connection (i.e. HTTP). You must use
> HTTPS to authenticate with the registry which means you'll need to setup SSL first (see [adding ssl](#adding-ssl)).

By default, anyone can push and pull images from the registry. Authentication can be added to restrict access to the registry and mitigate against unauthorized access or certain denial-of-service attacks (i.e. filling up the registry with junk images).

To add authentication, you'll need to create a htpasswd file with the following command:

```bash
# create directory that will store the htpasswd file
mkdir -p ./auth

# create credentials for the registry
docker run --rm --entrypoint htpasswd httpd:2 -Bbn testuser testpassword > auth/htpasswd

# start the registry with authentication
docker compose -f docker-compose.ssl-auth.yaml up --detach
```
