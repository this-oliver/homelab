# Dynamic IP Updater

Most internet service providers (ISPs) assign dynamic IP addresses to their customers which means that the IP address of your home network can change at any time. If you have a domain name pointing to your home network, this can be a problem because the IP address of your home network can become invalid without you knowing - rendering the applications hosted on your home network inaccessible.

To solve this problem, we use [in-a-dyn](https://github.com/troglobit/inadyn), a lightweight Dynamic DNS client, to update DNS providers (i.e. Cloudflare) with the latest IP address of your home network whenever it changes.

## Getting Started

Pre-requisites:

- Docker

```bash
# clone the inadyn repository
git clone https://github.com/troglobit/inadyn

# change directory to inadyn
cd inadyn

# build the docker image
docker build -t inadyn:latest .
```

## Usage

> [!Tip]
> (Cloudflare 2024) The username is the domain name and the password is the API key.

Configure the inadyn.conf file with the following content:

```bash
touch inadyn.conf

echo "
provider cloudflare.com:1 {
    username = example.com
    password = *****
    hostname = dynamic.example.com # the hostname you want to update
    proxied  = true
}
" >> inadyn.conf

#echo "
#provider cloudflare.com:1 {
#    username = oliverrr.net
#    password = *****
#    hostname = foobar.oliverrr.net
#    proxied  = true
#}
#" >> inadyn.conf
```

Once you have configured the inadyn.conf file and built the inadyn image, you can run the following command to update the IP address once:

```bash
docker run --rm -v '$PWD/inadyn.conf:/etc/inadyn.conf' -v '$PWD/cache:/var/cache/inadyn' inadyn:latest -1 --cache-dir=/var/cache/inadyn > /dev/null 2>&1
```

Alternatively, you can run the following command (see [entrypoint.sh](./entrypoint.sh) for more details) to set a cronjob that updates the IP address every 30 minutes:

```bash
echo "*/30 * * * * bash $PWD/entrypoint.sh" | crontab -
```
