#!/bin/bash

# Exit if /tmp/lock.file exists
[ -f $HOME/.locks/mss.file ] && exit

# Create lock file, sleep 1 sec and verify lock
echo $$ > $HOME/.locks/mss.file 
sleep 1
[ "x$(cat $HOME/.locks/mss.file)" == "x"$$ ] || exit

# Do stuff
cd /home/1verifizieren1/api/
node notifyMessage.js

# Remove lock file
rm $HOME/.locks/mss.file
