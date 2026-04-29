#!/bin/bash

# For RHEL 9.x
export distro=rhel9
export arch=x86_64

# package
dnf install -y \
    git \
    curl \
    wget \
    vim \
    pip \
    unzip \

curl -LsSf https://astral.sh/uv/install.sh | sh

# Driver
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y 
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-$distro.repo
dnf clean expire-cache
dnf module enable nvidia-driver:latest-dkms -y
dnf install cuda-drivers -y

# CDI
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.17.8-1
sudo dnf install -y \
    nvidia-container-toolkit-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
    nvidia-container-toolkit-base-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
    libnvidia-container-tools-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
    libnvidia-container1-${NVIDIA_CONTAINER_TOOLKIT_VERSION}
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

/sbin/reboot