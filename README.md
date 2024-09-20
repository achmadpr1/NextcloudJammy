# How to Config UFW Firewall VPS Neo Lite Pro
# Use ufw to manage firewall rules

Nextcloud requires ports 80 and 443 to work outside the local network. Both cannot use the same port. 
Ports 80, 8080, and 8443 can also be used to access the Nextcloud interface, but their security levels vary. 
To access Nextcloud from outside the network, you need to allow ports 80 and 443 and forward them to the device's IP address
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
Enjoy!
