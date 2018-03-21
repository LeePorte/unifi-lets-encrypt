#!/bin/bash
# Modified script from here: https://github.com/FarsetLabs/letsencrypt-helper-scripts/blob/master/letsencrypt-unifi.sh
# Modified by: Brielle Bruns <bruns@2mbit.com>
# Download URL: https://source.sosdg.org/brielle/lets-encrypt-scripts
# Version: 1.5
# Last Changed: 02/04/2018

#!/usr/bin/env bash
# Modified script from here: https://github.com/FarsetLabs/letsencrypt-helper-scripts/blob/master/letsencrypt-unifi.sh
# Modified by: Brielle Bruns <bruns@2mbit.com>
# Download URL: https://source.sosdg.org/brielle/lets-encrypt-scripts
# Version: 1.5
# Last Changed: 02/04/2018
# 02/02/2016: Fixed some errors with key export/import, removed lame docker requirements
# 02/27/2016: More verbose progress report
# 03/08/2016: Add renew option, reformat code, command line options
# 03/24/2016: More sanity checking, embedding cert
# 10/23/2017: Apparently don't need the ace.jar parts, so disable them
# 02/04/2018: LE disabled tls-sni-01, so switch to just tls-sni, as certbot 0.22 and later automatically fall back to http/80 for auth

if [[ -z ${MAINDOMAIN} ]]; then
	echo "Error: At least one -d argument is required"
	exit 1
fi

if `md5sum -c /opt/unifi/${MAINDOMAIN}/${MAINDOMAIN}.cer.md5 &>/dev/null`; then
	echo "Cert has not changed, not updating controller."
	exit 0
else
	TEMPFILE=$(mktemp)
	CATEMPFILE=$(mktemp)

	# Identrust cross-signed CA cert needed by the java keystore for import.
	# Can get original here: https://www.identrust.com/certificates/trustid/root-download-x3.html
	cat > "${CATEMPFILE}" <<'_EOF'
-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
-----END CERTIFICATE-----
_EOF

	echo "Cert has changed, updating controller..."
	md5sum /opt/unifi/${MAINDOMAIN}/${MAINDOMAIN}.cer > /opt/unifi/${MAINDOMAIN}/${MAINDOMAIN}.pem.md5
	echo "Using openssl to prepare certificate..."
	cat /opt/unifi/${MAINDOMAIN}/fullchain.cer >> "${CATEMPFILE}"
	openssl pkcs12 -export  -passout pass:aircontrolenterprise \
    	-in /opt/unifi/${MAINDOMAIN}/${MAINDOMAIN}.cer \
    	-inkey /opt/unifi/${MAINDOMAIN}/${MAINDOMAIN}.key \
    	-out "${TEMPFILE}" -name unifi \
    	-CAfile "${CATEMPFILE}" -caname root
	echo "Stopping Unifi controller..."
	service unifi stop
	echo "Removing existing certificate from Unifi protected keystore..."
	keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore \
		-deststorepass aircontrolenterprise
	echo "Inserting certificate into Unifi keystore..."
	keytool -trustcacerts -importkeystore \
		-deststorepass aircontrolenterprise \
		-destkeypass aircontrolenterprise \
    	-destkeystore /usr/lib/unifi/data/keystore.tmp \
    	-deststoretype PKCS12 \
    	-srckeystore "${TEMPFILE}" -srcstoretype PKCS12 \
    	-srcstorepass aircontrolenterprise \
    	-alias unifi
	rm -f "${TEMPFILE}" "${CATEMPFILE}"
	rm -f /usr/lib/unifi/data/keystore
	mv /usr/lib/unifi/data/keystore.tmp /usr/lib/unifi/data/keystore
	rm /usr/lib/unifi/data/keystore.tmp
	echo "Starting Unifi controller..."
	service unifi start
	echo "Done!"
fi
