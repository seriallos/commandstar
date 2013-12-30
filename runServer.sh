#!/bin/bash

# Make sure we cd to the commandstar directory

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

# make sure node_modules are up to date
# don't install dev dependencies by default
# only report errors
echo "Installing/updating dependencies..."
npm install --production --loglevel error

# run the server using the local coffee-script
./node_modules/coffee-script/bin/coffee lib/commandstar.coffee
