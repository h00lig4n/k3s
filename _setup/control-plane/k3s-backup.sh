#!/bin/bash
set -e

BACKUP_DIR="/mnt/nfs-backups/k3s"
DATE=$(date +%F-%H%M)
TARGET="${BACKUP_DIR}/${DATE}"

echo "Stopping k3s..."
systemctl stop k3s

echo "Creating backup directory..."
mkdir -p "$TARGET"

echo "Backing up k3s server directory..."
cp -a /var/lib/rancher/k3s/server "$TARGET/"

echo "Starting k3s..."
systemctl start k3s

echo "Backup complete: $TARGET"