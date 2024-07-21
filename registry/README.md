# Private Registry

[DockerHub](https://hub.docker.com) is a great place to store and share docker images, but sometimes you need to store images privately which they limit to 1 private repository. To solve this problem, you can host your own private registry to restrict access to your images (and fully own your data).

The homelab uses [distribution](https://distribution.github.io/distribution/), an open-source docker registry, to store and manage docker images.

## Usage

Pre-requisites:

- Docker
- (Optional) Domain Name and SSL Certificate (in `/certs` as `domain.pem` and `domain.key`)

For a basic setup:

```bash
bash entrypoint.sh start

# with SSL
bash entrypoint.sh start --ssl

# with SSL and authentication
bash entrypoint.sh start --ssl --auth
```

To stop the registry:

```bash
bash entrypoint.sh stop
```

### Using an image from the registry in Kubernetes

```yaml
...
spec:
  containers:
    - name: my-app
      image: registry.example.net/app:latest
...
```

## Configuration

Most of these configurations are automatically set by the `entrypoint.sh` script, but you can customize them by modifying the `docker-compose.yaml` file.

### Adding SSL

> [!WARNING]
> The `entrypoint.sh` script assumes that the certificate is named `domain.pem` and the private key is named `domain.key`. If you have different names, you'll need to update the script.

If you want to expose the registry to the internet, you'll need to setup SSL to encrypt the connection between the client and the registry. To do this, add an SSL certificate and private key to the `./certs` directory.

### Adding Authentication

> [!NOTE]
> You cannot authenticate over an insecure connection (i.e. HTTP). You must use
> HTTPS to authenticate with the registry which means you'll need to setup SSL first (see [adding ssl](#adding-ssl)).

By default, anyone can push and pull images from the registry. Authentication can be added to restrict access to the registry and mitigate against unauthorized access or certain denial-of-service attacks (i.e. filling up the registry with junk images).

To add authentication, you can run the `entrypoint.sh` script with the `--auth` flag. This will start the registry with basic authentication. The default username and password are `admin` and `admin`. Under the hood, the script creates a htpasswd file with the username and password you specify using the `htpasswd` docker image:


```bash
# create credentials for the registry
docker run --rm --entrypoint htpasswd httpd:2 -Bbn testuser testpassword > auth/htpasswd
```
