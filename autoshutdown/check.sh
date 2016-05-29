#!/bin/bash
cnt=60;
while [[ $cnt > 0 ]]; do
    cnt=$(($cnt-1));
    if [[ $(ps aux | grep "$1" | grep -v "grep" | grep -v "$0") ]]; then exit; fi;
    sleep 1;
done;

if [[ $(ps aux | grep "$1" | grep -v "grep" | grep -v "$0") ]]; then exit; fi;

sudo shutdown now; 
