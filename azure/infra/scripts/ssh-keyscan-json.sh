#!/usr/bin/env bash
# $1 = hostname

HOST="$1"

# Capture the ssh key
KEY=$(ssh-keyscan -t rsa "$HOST" 2>/dev/null | tr '\n' ' ' | sed 's/"/\\"/g')

# Output as JSON
echo "{\"host_key\": \"$KEY\"}"

