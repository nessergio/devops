#cloud-config
autoinstall:
    version: 1
    early-commands:
      # minimal image hack
      - cat /cdrom/casper/install-sources.yaml | awk 'NR>1 && /^-/{exit};1' > /run/my-sources.yaml
      - mount -o ro,bind /run/my-sources.yaml /cdrom/casper/install-sources.yaml
      # workaround to stop ssh for packer as it thinks it timed out
      - sudo systemctl stop ssh
    update: no
    ssh:
      install-server: yes
    locale: en_US
    keyboard:
        layout: us
    source:
        id: ubuntu-server-minimal
    packages:
      - open-vm-tools
      - cloud-init
      - openvswitch-switch
      - openssh-server
      - net-tools
      - iputils-ping
      - dnsutils
      - iptables-persistent
      - curl
      - ifupdown
      - vim
      - zip
      - unzip
      - gnupg2
      - software-properties-common
      - apt-transport-https
      - ca-certificates
      - lsb-release
      - python3-pip
      - jq
    identity:
        hostname: ${hostname}
        username: ${username}
        password: "${password_hash}"
    ssh:
        install-server: yes
        allow-pw: yes
        authorized-keys:
            - ${ssh_authorized_key}
    storage:
        layout:
            name: direct
    user-data:
        disable_root: false
    late-commands:
        - echo '${username} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/ubuntu
        - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/ubuntu
