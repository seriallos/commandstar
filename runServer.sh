#!/bin/sh

# make sure node_modules are up to date
# don't install dev dependencies by default
npm install --production

# run the server using the local coffee-script
./node_modules/coffee-script/bin/coffee server.coffee
