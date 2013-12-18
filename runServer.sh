#!/bin/sh

# make sure node_modules are up to date
npm install

# run the server using the local coffee-script
./node_modules/coffee-script/bin/coffee server.coffee
