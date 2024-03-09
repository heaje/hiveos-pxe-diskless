#!/bin/bash

apt update -y
apt install -y prometheus-node-exporter
apt clean
systemctl enable prometheus-node-exporter
