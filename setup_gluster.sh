##############################
# HOSTS                      #
##############################

cat hosts.list  >> /etc/hosts

##############################
# MOUNT VOLUMES              #
##############################

mkdir /mnt/minio
mount -o discard,defaults /dev/disk/by-id/scsi-0HC_Volume_24190670 /mnt/minio
echo "/dev/disk/by-id/scsi-0HC_Volume_24190670 /mnt/minio ext4 discard,nofail,defaults 0 0" >> /etc/fstab

##############################
# CONFIG MINIO               #
##############################

mkdir /etc/minio
chown minio:minio /etc/minio

cp ./minio/minio /etc/default/minio
cp ./minio/minio.service  /etc/systemd/system/

systemctl start minio
systemctl enable minio