FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /root

# Install QEMU + tools
RUN apt update && apt install -y \
    qemu-system-x86 \
    wget \
    xorriso \
    curl \
    && apt clean

# Download PVE ISO
RUN wget -q https://enterprise.proxmox.com/iso/proxmox-ve_9.1-1.iso -O pve.iso

# Create autoinstall config (preseed)
RUN mkdir /root/pve-auto && \
    cat > /root/pve-auto/preseed.cfg << 'EOF'
# Auto-install Proxmox VE 9.x

# Accept EULA
d-i pve-accept-eula boolean true

# Set hostname
d-i netcfg/hostname string pve-auto

# Use DHCP
d-i netcfg/disable_autoconfig boolean false

# Root password
d-i passwd/root-password password root
d-i passwd/root-password-again password root

# Timezone
d-i time/zone string UTC

# Auto partition entire disk
d-i partman-auto/disk string /dev/vda
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/confirm_write_new_label boolean true

# Skip interactive installer
d-i finish-install/reboot_in_progress note
EOF

# Build modified ISO booting with automatic preseed
RUN mkdir /root/iso && \
    xorriso -osirrox on -indev pve.iso -extract / /root/iso && \
    sed -i 's|append initrd=initrd.gz.*|append initrd=initrd.gz preseed/file=/cdrom/preseed.cfg auto=true priority=critical|' /root/iso/boot/grub/grub.cfg && \
    cp /root/pve-auto/preseed.cfg /root/iso/preseed.cfg && \
    xorriso -as mkisofs -o pve-auto.iso -isohybrid-mbr /root/iso/boot/isolinux/isohdpfx.bin \
      -c boot.cat -b boot/grub/i386-pc/eltorito.img \
      -no-emul-boot -boot-load-size 4 -boot-info-table /root/iso

# Create disk for installation
RUN qemu-img create -f qcow2 pve.qcow2 40G

# Expose PVE Web UI (8006)
EXPOSE 8006

CMD qemu-system-x86_64 \
    -m 4096 \
    -smp 2 \
    -cpu max \
    -machine accel=tcg \
    -drive file=pve.qcow2,format=qcow2,if=virtio \
    -cdrom pve-auto.iso \
    -boot d \
    -nographic \
    -netdev user,id=n1,hostfwd=tcp::8006-:8006 \
    -device virtio-net,netdev=n1 \
    -serial mon:stdio \
    -no-reboot
