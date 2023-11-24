 # Rclone real-time sync

Thanks to https://blog.rymcg.tech/blog/linux/rclone_sync/
and obviously https://rclone.org/

## Geting started 

```
git clone https://github.com/nums/rclone-sync
cd rclone-sync && git clone https://github.com/rclone/rclone
docker build . -t nums/rclone-sync
mkdir config
touch ./config/rclone.conf
export RCLONE_ORIGIN=/my/path/on/host
export RCLONE_DESTINATION=MyStorage:MyBucket
```

Define your rclone.conf [see https://rclone.org/docs/] and then you're ready to run

```
docker-compose up -d
```