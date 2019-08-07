#!/bin/bash
cat /opt/k3s/k3s.sh | K3S_URL=https://主节点ip:6443 K3S_TOKEN=k3s_token INSTALL_K3S_EXEC="--docker" sh -