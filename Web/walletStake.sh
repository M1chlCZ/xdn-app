#!/bin/bash

# Exit if /tmp/lock.file exists
[ -f $HOME/.locks/stx.file ] && exit

# Create lock file, sleep 1 sec and verify lock
echo $$ > $HOME/.locks/stx.file 
sleep 1
[ "x$(cat $HOME/.locks/stx.file)" == "x"$$ ] || exit

# Do stuff
cd /home/someDude69/api/
node notifyStake.js

# Remove lock file
rm $HOME/.locks/mss.file

