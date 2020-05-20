#!/bin/bash

BASEDIR='/etc/acme'
LE_DIR="${BASEDIR}/LetsEncrypt"
LE_ACC_KEY="${LE_DIR}/account.key"
HAPROXY_DIR="${BASEDIR}/haproxy/"


if [ -z $LIVEIP ] ; then
	echo "<-- Missing LIVEIP ENV -->"
	exit
fi

if [ -z $DNSSERVER ] ; then
	echo "<-- Missing DNSSERVER ENV -->"
	exit
fi


if [[ -f /tmp/acme.running ]] ; then
    exit
fi
#touch /tmp/acme.running

if ! [ -d $LE_DIR ] ; then 
	mkdir $LE_DIR
fi
if ! [ -d $HAPROXY_DIR ] ; then 
	mkdir $HAPROXY_DIR 
fi

if ! [ -f $LE_ACC_KEY ] ; then
	echo "Creating missing LE account key $LE_ACC_KEY"
	openssl genrsa 4096 > $LE_ACC_KEY
fi

ALLDOMAINS=()

for DOMAIN in $DOMAINS ; do
	ALLDOMAINS+=" $DOMAIN"
	ALLDOMAINS+=" www."$DOMAIN
done


for domain in $ALLDOMAINS; do
	echo "< -----$domain ----- >"
	DIR="$LE_DIR/$domain"
	CSR="$DIR/$domain.csr"
	KEY="$DIR/$domain.key"
	SIGNED="$DIR/$domain.crt"
	# We need a better IP Check
	DOMAIN_IP=$(dig $domain @1.1.1.1 +short |grep [0-9])

	if ! [ "$DOMAIN_IP" = "$LIVEIP" ] ; then
		echo " ==> $domain ($DOMAIN_IP) Does not point to this server ($LIVEIP)."
		continue
	fi

	if ! [ -d $DIR ] ; then mkdir $DIR; fi
	if ! [ -f $KEY ] ; then
		openssl genrsa 4096 > $KEY
		openssl req -new -sha256 -key $KEY -subj "/CN=$domain" > $CSR
	fi
	if ! [ -f $SIGNED ] ; then 
		acme-tiny $STAGEING --account-key $LE_ACC_KEY --csr $CSR --acme-dir /var/www/challenges/ > $SIGNED
	else
		if openssl x509 -checkend 86400 -noout -in $HAPROXY_DIR/$domain.pem > /dev/null 2>&1; then
  			echo " ==> Certificate ($domain) is good."
		else
  			echo "Certificate ($domain) needs to be renewed."
  			rm -f $SIGNED
		fi
	fi
	# Check cert before adding to haproxy
	if openssl x509 -modulus -noout -in $SIGNED > /dev/null 2>&1  ; then
		echo " ==> $SIGNED is signed" 
		cat $KEY $SIGNED > $HAPROXY_DIR/$domain.pem
	else
		echo " ==> $SIGNED is not signed by LE"
		rm -f $SIGNED
		rm -f $HAPROXY_DIR/$domain.pem
	fi
	echo ""
done 

rm -f /tmp/acme.running
