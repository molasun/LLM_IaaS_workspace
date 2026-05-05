#!/bin/bash

sudo setsebool -P container_use_devices 1

sudo modprobe nvidia_uvm

DEVICE_ID=$(grep nvidia-uvm /proc/devices | awk '{print $1}')
sudo mknod -m 666 /dev/nvidia-uvm c $DEVICE_ID 0
sudo mknod -m 666 /dev/nvidia-uvm-tools c $DEVICE_ID 1

echo "$(ls -la /dev/nvidia-uvm*)"