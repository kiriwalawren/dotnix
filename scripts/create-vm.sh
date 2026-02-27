#!/usr/bin/env bash
set -euo pipefail

# VM Configuration
VM_NAME="homelab"
ISO_PATH="/home/walawren/Downloads/nixos-minimal-25.11.20251015.544961d-x86_64-linux.iso"
IMAGE_DIR="/var/lib/libvirt/images"
OS_DISK="$IMAGE_DIR/homelab.qcow2"
DATA_DISK_1="$IMAGE_DIR/homelab-data-1.qcow2"
DATA_DISK_2="$IMAGE_DIR/homelab-data-2.qcow2"

# Disk sizes
OS_SIZE="50G"
DATA_SIZE="700G"

# VM Resources
MEMORY="24576" # 32GB in MiB (virt-install default unit)
VCPUS="18"

# Parse arguments
RECREATE=false
if [[ ${1:-} == "--recreate" ]]; then
  RECREATE=true
fi

# Function to create disk if it doesn't exist
create_disk_if_needed() {
  local disk_path="$1"
  local disk_size="$2"

  if [[ $RECREATE == "true" ]] && [[ -f $disk_path ]]; then
    echo "Removing existing disk: $disk_path"
    sudo rm -f "$disk_path"
  fi

  if [[ ! -f $disk_path ]]; then
    echo "Creating disk: $disk_path ($disk_size)"
    sudo qemu-img create -f qcow2 "$disk_path" "$disk_size"
  else
    echo "Disk already exists: $disk_path"
  fi
}

# Check if VM exists
if virsh -c qemu:///system list --all --name | grep -q "^${VM_NAME}$"; then
  if [[ $RECREATE == "true" ]]; then
    echo "Undefining existing VM: $VM_NAME"
    virsh -c qemu:///system destroy "$VM_NAME" 2>/dev/null || true
    virsh -c qemu:///system undefine "$VM_NAME" --nvram || true
  else
    echo "VM '$VM_NAME' already exists. Use --recreate to destroy and recreate."
    exit 1
  fi
fi

# Clean up leftover NVRAM files from failed creations
if [[ $RECREATE == "true" ]]; then
  NVRAM_FILE="/var/lib/libvirt/qemu/nvram/${VM_NAME}_VARS.fd"
  if [[ -f $NVRAM_FILE ]]; then
    echo "Removing leftover NVRAM file: $NVRAM_FILE"
    sudo rm -f "$NVRAM_FILE"
  fi
fi

# Create disk images
echo "Creating disk images..."
create_disk_if_needed "$OS_DISK" "$OS_SIZE"
create_disk_if_needed "$DATA_DISK_1" "$DATA_SIZE"
create_disk_if_needed "$DATA_DISK_2" "$DATA_SIZE"

# Create VM using virt-install
echo "Creating VM with virt-install..."
sudo virt-install \
  --connect qemu:///system \
  --name "$VM_NAME" \
  --memory "$MEMORY" \
  --vcpus "$VCPUS" \
  --cpu host-passthrough \
  --machine q35 \
  --disk path="$OS_DISK",format=qcow2,bus=virtio \
  --disk path="$DATA_DISK_1",format=qcow2,bus=virtio \
  --disk path="$DATA_DISK_2",format=qcow2,bus=virtio \
  --cdrom "$ISO_PATH" \
  --network network=default,model=virtio \
  --network network=hostonly,model=virtio \
  --graphics spice \
  --video qxl \
  --channel unix,target.type=virtio,target.name=org.qemu.guest_agent.0 \
  --channel spicevmc,target.type=virtio,target.name=com.redhat.spice.0 \
  --console pty,target.type=serial \
  --sound ich9 \
  --rng /dev/urandom \
  --tpm backend.type=emulator,backend.version=2.0,model=tpm-crb \
  --boot uefi \
  --features smm.state=on \
  --osinfo nixos-unstable \
  --noautoconsole \
  --wait=-1

echo ""
echo "VM '$VM_NAME' created successfully!"
echo "Start it with: virsh -c qemu:///system start $VM_NAME"
echo "Connect with virt-manager or: virt-viewer -c qemu:///system $VM_NAME"
