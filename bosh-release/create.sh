#!/bin/bash

set -e

echo "Creating WSO2 API-M bosh release..."
bosh -e vbox create-release --force
