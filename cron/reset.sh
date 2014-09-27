#!/bin/sh

mysql -uroot -proot isucon < /home/isucon/isucon3/qualifier/webapp/config/schema.sql
echo "flush_all" | nc 127.0.0.1 11211
