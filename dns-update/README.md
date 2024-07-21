# DNS Updater

Most internet service providers (ISPs) assign dynamic IP addresses to their customers which means that the IP address of your home network can change at any time. If you have a domain name pointing to your home network, this can be a problem because the IP address of your home network can become invalid without you knowing - rendering the applications hosted on your home network inaccessible.

To solve this problem, we use [in-a-dyn](https://github.com/troglobit/inadyn), a lightweight Dynamic DNS client, to update DNS providers (i.e. Cloudflare) with the latest IP address of your home network whenever it changes.

## Getting Started

Pre-requisites:

- Docker

Build the inadyn docker image:

```bash
# clone the inadyn repository
git clone https://github.com/troglobit/inadyn

# change directory to inadyn
cd inadyn

# build the docker image
docker build -t inadyn:latest .
```

Setup a `inadyn.conf` file with the configuration for the DNS provider you want to update

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

> [!Tip]
> As of 2024, the username is the domain name and the password is your Cloudflare Global API Key which you can find in your [Cloudflare account settings](https://dash.cloudflare.com/profile/api-tokens).

## Usage

To update the DNS provider with the latest IP address of your home network, run the following command:

```bash
bash entrypoint.sh start
```

To setup a cron job to run the update every 30 minutes, run the following command:

```bash
bash entrypoint.sh cron
```

> [!Tip]
> You can change the frequency of the cron job by modifying the function `start_crontab` in the `entrypoint.sh` script.
