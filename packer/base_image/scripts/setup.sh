#!/bin/bash

set -euo

# Update repo cache
sudo apt update -y && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y \
    software-properties-common \
    build-essential \
    cmake \
    make \
    git \
    htop \
    bmon \
    python3 \
    python3-dev \
    tcl \
    tcl-dev

# Add ansible PPA
sudo apt-add-repository --yes --update ppa:ansible/ansible

# Install ansible
sudo apt-get install -y ansible