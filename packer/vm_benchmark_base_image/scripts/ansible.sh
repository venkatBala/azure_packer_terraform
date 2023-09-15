#!/bin/bash

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible