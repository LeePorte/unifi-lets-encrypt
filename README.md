### Unifi controller with added Let's Encrypt

This repo is a method to use DNS verification to gain Let's Encrypt certificates for a Ubiquiti Unifi controller.

It does not require the installation of the let's encrypt client.

Contained within this repo is a copy of acme.sh and dns_he.sh taken from https://github.com/Neilpang/acme.sh

Any of the DNS provders from https://github.com/Neilpang/acme.sh will work with this script


### Usage

1. C1one this repo to a location of your choosing on the machine where the controller is running
1. Update `ACMEHOME` in renew.acme.sh
1. Change `SETPASSWORD` in gen-unifi.sh
1. Run `chmod +x *.sh`
1. If you are using Hurricane Electric's DNS execute the following

```aidl
./renew.acme.sh -d <UNIFI_DOMAIN_NAME> -n dns_he -t "HE_Username" -t "HE_Password" -k "<USERNAME>" -k "<PASSWORD>"
```

If you are not using Hurricane Electric please visit https://github.com/Neilpang/acme.sh and download the appropriate provider and adjust the instruction for that provider.

Finally set up a cron job to run this once a month to keep your certs updated.

### Thanks to

- Brielle Bruns <bruns@2mbit.com>
- Neil Pang <https://twitter.com/neilpangxa>

