#!/bin/bash

# Exit if /tmp/lock.file exists
[ -f $HOME/.locks/tx.file ] && exit

# Create lock file, sleep 1 sec and verify lock
echo $$ > $HOME/.locks/tx.file 
sleep 1
[ "x$(cat $HOME/.locks/tx.file)" == "x"$$ ] || exit

# Do stuff
cd /home/1verifizieren1/api/
node notify.js

# Remove lock file
rm $HOME/.locks/tx.file
