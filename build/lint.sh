#!/bin/bash

echo "Running coffeelint..."

find . -name "*.coffee" -not -path "./node_modules/*" \
  | xargs -I % \
    -P 4 \
    ./node_modules/coffeelint/bin/coffeelint \
    --quiet \
    %
