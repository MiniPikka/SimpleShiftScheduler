#!/bin/bash
# setup-harmony-vm.sh — Create KVM/QEMU Windows VM for HarmonyOS development
#
# Prerequisites:
#   1. Reboot host (kernel was updated but not restarted, bridge module missing)
#   2. Download Windows 10 ISO to ~/Downloads/Win10_22H2.iso
#      → https://www.microsoft.com/software-download/windows10
#   3. Download DevEco Studio to ~/Downloads/deveco-studio.zip
#      → https://developer.huawei.com/consumer/cn/deveco-studio/
#
# Usage:
#   chmod +x setup-harmony-vm.sh
#   ./setup-harmony-vm.sh
#
set -euo pipefail

VM_NAME="harmony-dev"
RAM_MB=6144        # 6GB (DevEco needs 8GB recommended, 6GB is safe with 15GB host)
CPUS=4
DISK_GB=80
ISO_DIR="$HOME/Downloads"
WIN_ISO="$ISO_DIR/Win10_22H2.iso"
VIRTIO_ISO="$ISO_DIR/virtio-win.iso"

echo "=== HarmonyOS Dev VM Setup ==="
echo ""

# Check prerequisites
echo "[1/5] Checking prerequisites..."
if [ ! -f "$WIN_ISO" ]; then
  echo "ERROR: Windows ISO not found at $WIN_ISO"
  echo "  Download from: https://www.microsoft.com/software-download/windows10"
  echo "  Save as: $WIN_ISO"
  exit 1
fi
echo "  ✓ Windows ISO found: $(du -h "$WIN_ISO" | cut -f1)"

# Check libvirtd
if ! systemctl is-active libvirtd >/dev/null 2>&1; then
  echo "  Starting libvirtd..."
  sudo systemctl start libvirtd
fi
echo "  ✓ libvirtd running"

# Try to start default network, fall back to user networking
if sudo virsh net-start default 2>/dev/null; then
  sudo virsh net-autostart default 2>/dev/null || true
  NETWORK_TYPE="network=default"
  echo "  ✓ libvirt default network started"
else
  NETWORK_TYPE="user"
  echo "  ⚠ default network unavailable, using QEMU user networking (no bridge)"
  echo "    (This is fine — user networking provides NAT without bridge module)"
fi

# Download VirtIO drivers if not present
if [ ! -f "$VIRTIO_ISO" ]; then
  echo ""
  echo "[2/5] Downloading VirtIO drivers..."
  VIRTIO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct/latest-virtio/virtio-win.iso"
  echo "  URL: $VIRTIO_URL"
  echo "  (If slow, manually download from https://github.com/virtio-win/virtio-win-pkg-driver-direct)"
  curl -L -o "$VIRTIO_ISO" "$VIRTIO_URL" || {
    echo "  ⚠ Download failed. VM will use default drivers (slower disk/network)."
    echo "    You can manually download later and attach to VM."
    VIRTIO_ISO=""
  }
else
  echo "[2/5] ✓ VirtIO drivers found: $(du -h "$VIRTIO_ISO" | cut -f1)"
fi

# Create VM
echo ""
echo "[3/5] Creating VM '$VM_NAME'..."

# Delete existing VM if present
sudo virsh destroy "$VM_NAME" 2>/dev/null || true
sudo virsh undefine "$VM_NAME" --nvram 2>/dev/null || true

DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
sudo rm -f "$DISK_PATH"

VIRTIO_ARGS=""
if [ -n "$VIRTIO_ISO" ]; then
  VIRTIO_ARGS="--cdrom $VIRTIO_ISO"
fi

sudo virt-install \
  --name "$VM_NAME" \
  --ram $RAM_MB \
  --vcpus $CPUS \
  --disk path="$DISK_PATH",size=$DISK_GB,bus=virtio,format=qcow2 \
  --cdrom "$WIN_ISO" \
  $VIRTIO_ARGS \
  --network "$NETWORK_TYPE" \
  --os-variant win10 \
  --boot firmware=efi \
  --graphics spice \
  --video virtio \
  --channel spicevmc \
  --noautoconsole \
  --console pty,target_type=serial

echo "  ✓ VM created and booting from Windows ISO"

# Show connection info
echo ""
echo "[4/5] VM Connection Info"
echo "  VM Name:    $VM_NAME"
echo "  RAM:        ${RAM_MB}MB"
echo "  CPUs:       $CPUS"
echo "  Disk:       ${DISK_GB}GB ($DISK_PATH)"
echo "  Network:    $NETWORK_TYPE"
echo ""
echo "  Connect to VM:"
echo "    virt-viewer $VM_NAME"
echo "    or: virt-manager (GUI)"
echo ""
echo "  Management:"
echo "    sudo virsh start $VM_NAME       # Start"
echo "    sudo virsh shutdown $VM_NAME    # Shutdown"
echo "    sudo virsh destroy $VM_NAME     # Force off"
echo "    sudo virsh list --all           # List VMs"

echo ""
echo "[5/5] Next Steps (inside Windows VM)"
echo "  1. Install Windows (select VirtIO disk — load driver from virtio-win ISO)"
echo "  2. Install VirtIO drivers (guest tools, Balloon, NetKVM, vioscsi)"
echo "  3. Download & install DevEco Studio:"
echo "     https://developer.huawei.com/consumer/cn/deveco-studio/"
echo "  4. In DevEco: File → Open → \\\\vboxsrv\\SimpleShiftScheduler (or shared folder)"
echo "  5. Build → Build Hap(s)"
echo ""
echo "Done! VM is booting. Run 'virt-viewer $VM_NAME' to see Windows installer."
