# Nginx - Reverse Proxy

```bash
docker run -d -p 80:80 -p 443:443 --name reverse-proxy -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro nginx
```

## Explanation

The `nginx.conf` file is the configuration file for the Nginx server. It has the following rules:

1. requests from port 443 with the origin `registry.oliverrr.net` are redirected to the `registry` service on port `5999`
2. all other requests are redirected to the `kubernetes` service on port `8443`
