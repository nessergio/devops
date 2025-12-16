 #!/bin/bash
aws ecr get-login-password | docker login --username AWS --password-stdin $REGISTRY
export EC2_INSTANCE_ID=$(ec2metadata --instance-id)
echo "admin:{PLAIN}$EC2_INSTANCE_ID" > htpasswd
docker compose pull && docker compose up -d