{...}: {
  # Minimal kernel modules for VirtualBox guest
  boot.initrd.availableKernelModules = ["virtio_pci" "virtio_blk" "virtio_net" "xhci_pci"];
  boot.kernelModules = ["kvm" "kvm_intel" "virtio_pci" "virtio_blk" "virtio_net"];

  # Let nixos-generators decide the root filesystem (ext4 by default)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [];
}
