🚀 How to Run
docker build -t pve-auto .


Install automatically:

docker run --rm -it -p 8006:8006 pve-auto


After install finishes, it shuts down (-no-reboot).
Now boot into installed PVE:

docker run --rm -it -p 8006:8006 pve-auto \
  qemu-system-x86_64 \
    -m 4096 \
    -smp 2 \
    -cpu max \
    -machine accel=tcg \
    -drive file=pve.qcow2,format=qcow2,if=virtio \
    -boot c \
    -nographic \
    -netdev user,id=n1,hostfwd=tcp::8006-:8006 \
    -device virtio-net,netdev=n1 \
    -serial mon:stdio

🌐 Access Proxmox

Open browser:

https://localhost:8006


Login:

Username: root@pam
Password: root

⚡ Want more automation?

I can add:

✅ Auto-create admin user
✅ Auto-configure storage, network, node name
✅ Auto-enable no-subscription repository
✅ Auto-install QEMU guest tools
✅ Auto-upload SSH key
✅ Build-ready PVE qcow2 image
