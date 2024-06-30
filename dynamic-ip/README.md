# Handeling Dynamic IP Addresses

## Installations

```bash
# clone the inadyn repository
git clone https://github.com/troglobit/inadyn

# change directory to inadyn
cd inadyn

# build the docker image
docker build -t inadyn:latest .
```

## Getting Started

> [!Tip]
> (Cloudflare 2024) The username is the domain name and the password is the API key.

Configure the inadyn.conf file with the following content:

```bash
echo "
provider cloudflare.com:1 {
    username = example.com
    password = *****
    hostname = dynamic.example.com # the hostname you want to update
    proxied  = true
}
" > inadyn.conf
```

Once you have configured the inadyn.conf file and built the inadyn image, you can run the following commands:

```bash
# create a cache file
mkdir -p cache

# open the crontab editor
crontab -e

# past the output of the following command in the crontab editor
echo "0 * * * * docker run --rm -v '$PWD/inadyn.conf:/etc/inadyn.conf' -v '$PWD/cache:/var/cache/inadyn' inadyn:latest -1 --cache-dir=/var/cache/inadyn > /dev/null 2>&1"
```
