#! /bin/bash

eval `ssh-agent`
ssh-add ~/.ssh/isucon_rsa
git pull oppai master
