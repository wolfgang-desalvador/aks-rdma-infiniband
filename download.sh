#!/usr/bin/env bash

apt update && apt install -y curl

curl -L https://content.mellanox.com/ofed/MLNX_OFED-<mellanox_version>/MLNX_OFED_LINUX-<mellanox_version>-ubuntu<ubuntu_version>-x86_64.iso -o MLNX_OFED_LINUX-<mellanox_version>-ubuntu<ubuntu_version>-x86_64.iso