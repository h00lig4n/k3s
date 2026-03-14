# Control Plane DR

[Calico K3S](https://docs.tigera.io/calico/latest/getting-started/kubernetes/k3s/quickstart)

Install script installs Calico. It expects a token and domain name. You can override version.

```bash
export K3S_TOKEN="my-token"
./install-k3s-calico-safe.sh mydomain.com v3.28.0
```

## Backup

### Items Needed

/usr/local/bin/k3s-backup.sh
/etc/systemd/system/backup.service
/etc/systemd/system/backup.timer

### Procedure

NFS Mount for backup location. Update fstab with the following line and mount:

```bash
nas:/data1/nfs/backup /mnt/nfs-backups nfs defaults,_netdev,noatime,vers=4,x-systemd.automount  0  0
```

```bash
sudo nano /etc/fstab
sudo mount -a
mount | grep nfs
```

Create the following script, copy contents from k3s-backup.sh.

```bash
sudo nano /usr/local/bin/k3s-backup.sh
```

Make executable:

```bash
sudo chmod +x /usr/local/bin/k3s-backup.sh
```

Create backup service:

```bash
sudo nano /etc/systemd/system/backup.service
```

```bash
[Unit]
Description=Nightly k3s Backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/k3s-backup.sh
```

Create systemd timer:

```bash
sudo nano /etc/systemd/system/backup.timer
```

```bash
[Unit]
Description=Run k3s backup nightly

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable backup.timer
sudo systemctl start backup.timer
```

Manual test:

```bash
sudo systemctl start backup.service
journalctl -u backup.service -f
ls /mnt/nfs-backups/k3s
```

## Restore

```bash
systemctl stop k3s
rm -rf /var/lib/rancher/k3s/server
cp -a BACKUP/server /var/lib/rancher/k3s/
systemctl start k3s
```