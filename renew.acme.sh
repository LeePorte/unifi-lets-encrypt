#!/bin/bash

export ACMEHOME=/opt/unifi

usage() {
    echo "Usage: $0 -d <mydomain.com> [-d <additionaldomain.com>] -n <dns service>" \
         "[-i set insecure flag] [-v enable acme verbose]" \
         "-t <tag> [-t <additional tag>] -k <key> [-k <additional key>]" 1>&2; exit 1;
}

log() {
    if [ -z "$2" ]
    then
        printf -- "%s %s\n" "[$(date)]" "$1"
    fi
}

INSECURE_FLAG=""
VERBOSE_FLAG=""

# first parse our options
while getopts ":hivd:n:t:k:" opt; do
    case $opt in
        d) DOMAINS+=("$OPTARG") ;;
        i) INSECURE_FLAG="--insecure" ;;
        n) DNS=$OPTARG ;;
        t) TAGS+=("$OPTARG") ;;
        k) KEYS+=("$OPTARG") ;;
        v) VERBOSE_FLAG="--debug 2" ;;
        h | *)
          usage
          ;;
    esac
done
shift $((OPTIND -1))

# check for required parameters
if [ ${#DOMAINS[@]} -eq 0 ] || [ -z ${DNS+x} ] \
        || [ ${#TAGS[@]} -eq 0 ] || [ ${#KEYS[@]} -eq 0 ] || [ ${#TAGS[@]} -ne ${#KEYS[@]} ]; then
    usage
fi

# prepare flags for acme.sh
for val in "${DOMAINS[@]}"; do
     DOMAINARG+="-d $val "
done
DNSARG="--dns $DNS"

export MAINDOMAIN=${DOMAINS[0]}

# prepare environment
for i in "${!TAGS[@]}"; do 
    export ${TAGS[$i]}="${KEYS[$i]}"
done

log "Executing acme.sh."
$ACMEHOME/acme.sh --issue $DNSARG $DOMAINARG --home $ACMEHOME \
    --keypath /opt/unifi/${MAINDOMAIN}/server.key --fullchainpath /opt/unifi/${MAINDOMAIN}/full.cer \
    --reloadcmd $ACMEHOME/gen-unifi-cert.sh \
    $INSECURE_FLAG $VERBOSE_FLAG

