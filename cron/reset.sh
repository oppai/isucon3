#!/bin/sh

echo "flush_all" | nc 127.0.0.1 11211
sudo supervisorctl restart isucon_ruby
