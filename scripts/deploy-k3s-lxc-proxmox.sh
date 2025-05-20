#!/bin/bash

# Configs
SERVER_ID=123
AGENT_ID=124
MEMORY=2048
DISK=20
TEMPLATE="local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst" #pveam list local
#pveam available
#pveam download XYZ

echo "[+] Creating K3s Server container (ID: $SERVER_ID)"
pct create $SERVER_ID $TEMPLATE \
  --hostname k3s-server \
  --cores 2 \
  --memory $MEMORY \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1 \
  --features nesting=1,keyctl=1 \
  --rootfs local-lvm:${DISK} \
  --start 1

echo "[+] Creating K3s Agent container (ID: $AGENT_ID)"
pct create $AGENT_ID $TEMPLATE \
  --hostname k3s-agent \
  --cores 2 \
  --memory $MEMORY \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --unprivileged 1 \
  --features nesting=1,keyctl=1 \
  --rootfs local-lvm:${DISK} \
  --start 1

sleep 5

# Relax security
for ID in $SERVER_ID $AGENT_ID; do
  echo "[+] Relaxing container $ID (unconfined apparmor, extra capabilities, mounts)"
  echo "lxc.apparmor.profile: unconfined" >> /etc/pve/lxc/$ID.conf
  echo "lxc.cap.drop:" >> /etc/pve/lxc/$ID.conf
  echo "lxc.cgroup2.devices.allow: a" >> /etc/pve/lxc/$ID.conf
  echo "lxc.mount.auto: cgroup:rw" >> /etc/pve/lxc/$ID.conf
  echo "lxc.autodev: 1" >> /etc/pve/lxc/$ID.conf
  echo "lxc.mount.entry: /dev/fuse dev/fuse none bind,create=file 0 0" >> /etc/pve/lxc/$ID.conf
  #echo "lxc.mount.entry: /lib/modules lib/modules none bind,ro 0 0" >> /etc/pve/lxc/$ID.conf
  pct reboot $ID
done

echo "[*] Waiting for containers to come up..."
sleep 10

# Install K3s on server
echo "[+] Installing K3s server"
pct exec $SERVER_ID -- sh -c "apt update && apt install -y curl"
pct exec $SERVER_ID -- sh -c "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--kubelet-arg=feature-gates=KubeletInUserNamespace=true' sh -"

echo "[*] Fetching K3s server IP and token"
SERVER_IP=$(pct exec $SERVER_ID -- ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
TOKEN=$(pct exec $SERVER_ID -- cat /var/lib/rancher/k3s/server/node-token)

echo "[+] Installing K3s agent"
pct exec $AGENT_ID -- sh -c "apt update && apt upgrade -y"
pct exec $AGENT_ID -- sh -c "apt update && apt install -y curl"
pct exec $AGENT_ID -- sh -c "curl -sfL https://get.k3s.io | K3S_URL='https://$SERVER_IP:6443' K3S_TOKEN='$TOKEN' INSTALL_K3S_EXEC='--kubelet-arg=feature-gates=KubeletInUserNamespace=true' sh -"

echo "[✅] K3s cluster deployed! Run this to check nodes:"
echo "pct exec $SERVER_ID -- kubectl get nodes"

# ---
# [Manual step required on Proxmox host before running this script:]
# Ensure these kernel modules are loaded and persist across reboots:
#   echo -e "overlay\nbr_netfilter" >> /etc/modules
#   modprobe overlay
#   modprobe br_netfilter
#
# Enable cgroup features in /etc/default/grub:
#   GRUB_CMDLINE_LINUX="... systemd.unified_cgroup_hierarchy=1 cgroup_enable=memory swapaccount=1"
#   update-grub && reboot
# ---
