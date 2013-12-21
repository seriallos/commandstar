#!/bin/bash

# fail immediately
set -e

# lint .coffee files
build/lint.sh

# run mocha tests
node_modules/mocha/bin/mocha
