#! /bin/bash
cd /home/isucon/isucon3
/usr/bin/git stash
/usr/bin/git pull origin `/usr/bin/git rev-parse --abbrev-ref HEAD`
/usr/bin/git stash pop
