# Running Qemu Weston

Start Qemu

```sh
qemu-system-x86_64 \
  -M pc \
  -m 1024 \
  -enable-kvm \
  -kernel bzImage \
  -append "rootwait root=/dev/vda console=ttyS0" \
  -drive file=rootfs.ext2,if=virtio,format=raw \
  -serial mon:stdio \
  -net nic,model=virtio \
  -net user -display none \
  -vnc 0.0.0.0:0 \
  -device VGA \
  -device usb-ehci \
  -device usb-kbd \
  -device usb-tablet
```

Then connect vnc client

```sh
vncviewer 127.0.0.1:5900
```
