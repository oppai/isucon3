#! /bin/bash
git stash
git pull origin `git rev-parse --abbrev-ref HEAD`
git stash pop
