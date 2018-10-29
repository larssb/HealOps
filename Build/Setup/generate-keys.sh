#!/usr/bin/env bash
: '
    - Helper script for generating the "communication" keys for ConcourseCI.
    They are used by workers and the web server.
'
set -e -u -x

# Create dirs for the keys
mkdir -p keys/web keys/worker

# Generate the keys
yes | ssh-keygen -t rsa -f ./keys/web/tsa_host_key -N ''
yes | ssh-keygen -t rsa -f ./keys/web/session_signing_key -N ''
yes | ssh-keygen -t rsa -f ./keys/worker/worker_key -N ''

# Copy files around so that the worker and the web infrastructure can "know eachother"
cp ./keys/worker/worker_key.pub ./keys/web/authorized_worker_keys
cp ./keys/web/tsa_host_key.pub ./keys/worker