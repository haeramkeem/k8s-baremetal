#!/bin/bash

WORKDIR=$(dirname $0)
REG_DOMAIN="k8s-m1"
REG_IP="192.168.1.101"
REG_PORT="8443"

# COMMON scripts
# docker registry certificate path
CERTS=/etc/docker/certs.d/$REG_IP:$REG_PORT
mkdir -pv $CERTS

# CONTROLPLANE scripts
if [[ $1 == "controlplane" ]]; then
    # image saving dir
    mkdir -pv /registry-image

    # cert for server
    mkdir -pv /etc/docker/certs

    # modify `tls.csr`
    sed -i "s/\${DOMAIN}/$REG_DOMAIN/g" $WORKDIR/etcs/tls.csr
    sed -i "s/\${IPADDR}/$REG_IP/g" $WORKDIR/etcs/tls.csr

    # generate cert
    openssl req \
        -x509 \
        -config $WORKDIR/etcs/tls.csr \
        -nodes \
        -newkey rsa:4096 \
        -keyout tls.key \
        -out tls.crt \
        -days 365 \
        -extensions v3_req

    # copy cert
    cp -irv tls.crt $CERTS
    mv tls.* /etc/docker/certs

    # run registry
    docker load < $WORKDIR/images/registry.tar

    docker run -d \
        --restart=always \
        --name registry \
        -v /etc/docker/certs:/docker-in-certs:ro \
        -v /registry-image:/var/lib/registry \
        -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
        -e REGISTRY_HTTP_TLS_CERTIFICATE=/docker-in-certs/tls.crt \
        -e REGISTRY_HTTP_TLS_KEY=/docker-in-certs/tls.key \
        -p $REG_PORT:443 \
        registry:2

# WORKER scripts
else
    openssl s_client -showcerts -connect $REG_IP:$REG_PORT \
        </dev/null 2>/dev/null|openssl x509 -outform PEM >$CERTS/tls.crt
fi
