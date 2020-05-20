#!/bin/bash 
nginx -q 
sleep 10

while true ; do 

/srv/acme_run.sh
echo "sleeping"
sleep 600

done 

