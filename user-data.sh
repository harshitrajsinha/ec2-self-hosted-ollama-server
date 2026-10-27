#!/bin/bash

set -euo pipefail

exec &> >(sudo tee -a /tmp/logfile.log)

export DEBIAN_FRONTEND=noninteractive
export HOME=/root

# Update and upgrade packages
sudo apt-get update
sudo apt-get upgrade -y

# Install ollama
curl -fsSL https://ollama.com/install.sh | sh

systemctl enable --now ollama

# wait for ollama server to be ready
sleep 60

# Download suitable model as per instance type
ollama pull gemma4:e4b

# Verify model is running
curl http://localhost:11434

# Verify the model installation
curl http://localhost:11434/api/tags