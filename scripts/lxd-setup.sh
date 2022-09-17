#!/bin/bash

set -e

if [ -d "/snap/lxd" ];
then
    echo "lxd already installed. Skipping install.."
else
    sudo snap install lxd;
fi
# install snapcraft @ candidate channel
if [ -d "/snap/snapcraft" ];
then
    echo "snapcraft already installed. Skipping install.."
else
    sudo snap install snapcraft --classic --channel=candidate;
fi

sudo lxd init --auto

#check if this returns the default storage pool to see if it's been initted
var=$(lxc storage list |grep default)
if ! [ "$var" ];
then
        # create group for lxd permissions
	sudo usermod -a -G lxd "$USER"
	echo "renewing session... "
        newgrp lxd
fi
