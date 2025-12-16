#!/bin/bash

echo "STARTING UNSEALING"

until timeout 1 bash -c 'curl --fail http://localhost:8200'; do
  # vault is unavailable - sleeping
  sleep 1
done

echo "VAULT READY"

while IFS= read -r key; do
    curl -s --request PUT --data "{\"key\": \"$key\"}" http://localhost:8200/v1/sys/unseal
done < /keys.txt

echo "UNSEALED"
