# NextcloudJammy
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

# How to Config UFW Firewall VPS Neo Lite Pro
# Use ufw to manage firewall rules, add/delete/restore/reset ufw rules.
```
sudo ufw allow 80
```
```
sudo ufw allow 443
```
```
sudo ufw allow 8080
```
```
sudo ufw allow 8443
```
```
sudo ufw enable
```
```
sudo ufw status
```


Enjoy!
