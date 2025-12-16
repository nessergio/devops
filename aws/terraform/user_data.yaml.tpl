#cloud-config

groups:
  - docker

users:
  - name: demo
    groups: users, docker
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - ${ssh_key_pub}

#package_update: true
#package_upgrade: true
packages:
  - git
  - python3-pip
  - docker.io
  - docker-compose-v2
  - ruby-full
  - wget

write_files:
  - path: /etc/profile
    content: |
      export REGISTRY="${registry}"
      export ENVIRONMENT="${env}"
      export AWS_REGION="${region}"
      %{ if prometheus_ips != null }
      export PROMETHEUS_HOSTS="%{ for addr in prometheus_ips }server ${addr}:9090\n%{ endfor }"
      export GRAFANA_HOSTS="%{ for addr in prometheus_ips }server ${addr}:3000\n%{ endfor }"
      %{ endif }
    append: true

  - path: /etc/docker/daemon.json
    content: |
      {
        "metrics-addr": "0.0.0.0:9323"
      }

  - path: /home/demo/.ssh/cloudinit
    permissions: 0600
    content: |
      ${ssh_key_private}

  - path: /home/demo/.ssh/config
    content: |
      Host github.com
        Hostname github.com
        IdentityFile ~/.ssh/cloudinit

  - path: /home/demo/init.sh
    content: |
      #!/bin/bash
      mkdir ~/demo && cd ~/demo       
      git init && git config core.sparseCheckout true
      git remote add -f origin git@github.com:nessergio/demo.git      
      echo "${app_stack}" >> .git/info/sparse-checkout
      ssh-keyscan github.com >> ~/.ssh/known_hosts
      git pull origin main
      cd ${app_stack} && sh start.sh

runcmd:
  - |
    # install AWS CLI
    snap install aws-cli --classic
    aws configure --region ${region}

    # bugs.launchpad.net/ubuntu/+source/systemd/+bug/1774632 [Local DNS]
    rm -f /etc/resolv.conf
    ln -sv /run/systemd/resolve/resolv.conf /etc/resolv.conf

    # install code deploy agent
    wget https://aws-codedeploy-${region}.s3.${region}.amazonaws.com/latest/install    
    sudo sh ./install auto > /home/demo/codedeploy-install.log

    # folders were created by root user
    chown -R demo:demo /home/demo
    su - demo -c "sh ~/init.sh"
