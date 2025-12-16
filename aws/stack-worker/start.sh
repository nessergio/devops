#!/bin/bash
aws ecr get-login-password | docker login --username AWS --password-stdin $REGISTRY
docker compose pull && docker compose up -d