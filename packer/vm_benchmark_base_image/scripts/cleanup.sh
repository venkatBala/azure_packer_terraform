#!/bin/bash

set -eou

sudo rm -rf /tmp/*

sudo /usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync