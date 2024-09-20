# How to Config UFW Firewall VPS Neo Lite Pro
# Use ufw to manage firewall rules

```
sudo ufw allow 80/tcp
```
```
sudo ufw allow 443/tcp
```
```
sudo ufw reload
```

# 1. Nextcloud by snapd
```
apt install snapd
```
```
snap install nextcloud
```

add domain
```
```
nano /var/snap/nextcloud/current/nextcloud/config/config.php
```

# 2. NextcloudJammy
This is autoinstall Nextcloud For ubuntu version 22.04 (Jammy)

# Usage
```
sudo su
```
```
wget https://raw.githubusercontent.com/achmadpr1/NextcloudJammy/main/nextcloud-jammy.sh
```
```
chmod +x nextcloud-jammy.sh
```
```
sudo ./nextcloud-jammy.sh
```

Follow the prompts to enter information about your server as shown below:

Enter Database root password: Re-enter Database root password: Enter Nextcloud database name: nextcloud Enter Nextcloud database user: nextcloud Enter Nextcloud database user password: Re-enter Nextcloud database password: Enter Nextcloud Serever hostname - e.g cloud.example.com: cloud.achmadpr.com

Wait for installtion to complete!
Enjoy!
