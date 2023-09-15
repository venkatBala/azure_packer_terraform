#!/bin/bash

set -euo

sudo apt update -y && sudo apt upgrade -y
sudo apt install -y software-properties-common \
    build-essential \
    cmake \
    make \
    git \
    htop \
    bmon \
    python3 \
    python3-dev
sudo apt autoremove -y