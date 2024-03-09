#!/bin/bash

VERSION=0.1.1
INSTALL_DIR=/opt/hiveos-exporter
SYSTEMD_SVC_DIR=/etc/systemd/system

cd /tmp
wget -q https://github.com/heaje/hiveos-exporter/archive/refs/tags/${VERSION}.tar.gz -O - | tar -xzf -
cd hiveos-exporter-${VERSION}
apt update -y
apt install -y python3-prometheus-client python3-requests-cache

install -d -g root -o root -m 755 ${INSTALL_DIR}/bin ${INSTALL_DIR}/etc ${INSTALL_DIR}/pool
install -g root -o root -m 755 bin/* ${INSTALL_DIR}/bin/
install -g root -o root -m 640 etc/* ${INSTALL_DIR}/etc/
install -g root -o root -m 644 pool/* ${INSTALL_DIR}/pool/
install -g root -o root -m 644 systemd/* ${SYSTEMD_SVC_DIR}/

systemctl enable hiveos-exporter
cd /
rm -rf /tmp/hiveos-exporter*

