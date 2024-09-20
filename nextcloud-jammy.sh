#!/bin/bash
#####################################
#
# Nextcloud Install Script.
# By AchmadPR
#####################################

# Check if user is root or sudo
if ! [ $( id -u ) = 0 ]; then
echo -e "${RED}Please run the Nextcloud script as sudo or root user.${NC}"
exit 1
fi

# Output colors
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Log Location
LOG="/tmp/nextcloud-install.log"

# Initialize variable values
NCdomainName=""
NCIP=""
mysqlRootPwd=$(openssl rand -base64 24)
NCDbName=nextcloud
NCAdmin=ncadmin
NCPass=$(openssl rand -base64 18)
DbUser=nextcloud_dbadmin
DbPwd=$(openssl rand -base64 24)
OS=$(lsb_release -i | cut -f 2-)
PHP_VERSION="8.3"
PHP="/etc/php/${PHP_VERSION}/apache2/php.ini"

# Clean terminal
clear

echo -e "${YELLOW}Welcome to my Nextcloud install script.\nThe script will automatically setup:\n\n${BLUE} - SSL with a self-sign certificate.\n - Enable memcache APCu local caching.\n - Enable Redis for database transactional locking.\n - Setup Nextcloud PHP recommendations.\n - Enable Pretty URLs.\n - Setup Cron for background tasks.\n - Enable Brute Force Protection.\n${NC}"
echo ""

# Collect input
read -p "Enter Nextcloud Server's hostname - e.g. cloud.example.com: " NCdomainName
read -p "Enter your Server's IP Address: " NCIP

# Change hostname
sudo hostnamectl set-hostname "${NCdomainName}"

# Seed MySQL install values
debconf-set-selections <<< "mysql-server mysql-server/root_password password ${mysqlRootPwd}"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${mysqlRootPwd}"

# Update OS
echo -e "${YELLOW}Updating your ${OS} OS..${NC}"
export DEBIAN_FRONTEND=noninteractive
apt update -y && apt upgrade -y && apt dist-upgrade -y &>> ${LOG}
apt install -y wget &>> ${LOG}

# Clear command line
clear

# Add Ondřej Surý's PHP PPA and install PHP 8.3
echo -e "${YELLOW}Adding PHP PPA and installing PHP 8.3..${NC}"
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update -y
sudo apt install -y php${PHP_VERSION} php${PHP_VERSION}-apcu php${PHP_VERSION}-bcmath php${PHP_VERSION}-cli php${PHP_VERSION}-common php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-gmp php${PHP_VERSION}-imagick php${PHP_VERSION}-intl php${PHP_VERSION}-mbstring php${PHP_VERSION}-mysql php${PHP_VERSION}-zip php${PHP_VERSION}-xml php${PHP_VERSION}-redis &>> ${LOG}
if [ $? -ne 0 ]; then
echo -e "${RED}Failed to install PHP 8.3${NC}" 1>&2
exit 1
fi
echo -e "${GREEN}PHP 8.3 installed successfully${NC}"

#install cron
echo -e "${YELLOW}Installing Cron..${NC}"
sudo apt install cron

# Download Nextcloud
echo -e "${YELLOW}Downloading Nextcloud..${NC}"
wget https://download.nextcloud.com/server/releases/latest.zip
if [ $? -ne 0 ]; then
echo -e "${RED}Failed to download Nextcloud${NC}" 1>&2
exit 1
fi
echo -e "${GREEN}Downloaded Nextcloud${NC}"

# Install MariaDB
echo -e "${YELLOW}Installing Database...${NC}"
sudo apt install mariadb-server -y &>> ${LOG}
if [ $? -ne 0 ]; then
echo -e "${RED}Failed to install MariaDB server${NC}" 1>&2
exit 1
fi
echo -e "${GREEN}MariaDB Server installed successfully${NC}"

# Secure MariaDB
echo -e "${YELLOW}Securing your Database..${NC}"
echo > mysql_secure_installation.sql << EOF
UPDATE mysql.user SET Password=PASSWORD('${mysqlRootPwd}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
mysql < mysql_secure_installation.sql &>> ${LOG}
if [ $? -ne 0 ]; then
echo -e "${RED}Failed to secure database${NC}" 1>&2
exit 1
fi
echo -e "${GREEN}Database secured successfully${NC}"

# Create database & user and set permissions
CODE="
DROP DATABASE IF EXISTS ${NCDbName};
CREATE DATABASE IF NOT EXISTS ${NCDbName};
CREATE USER IF NOT EXISTS '${DbUser}'@'localhost' IDENTIFIED BY \"${DbPwd}\";
GRANT ALL PRIVILEGES ON ${NCDbName}.* TO '${DbUser}'@'localhost';
FLUSH PRIVILEGES;"

echo -e "${YELLOW}Creating and setting up your Nextcloud Database${NC}"
echo ${CODE} | mysql -u root -p${mysqlRootPwd}
if [ $? -ne 0 ]; then
echo -e "${RED}Failed to create and setup Nextcloud database${NC}" 1>&2
exit 1
fi
echo -e "${GREEN}Nextcloud database setup completed successfully${NC}"

# Install required packages
echo -e "${YELLOW}Installing required Nextcloud packages in the background, this may take a while...${NC}"
sudo apt install apache2 unzip redis -y &>> ${LOG}
if [ $? -ne 0 ]; then
echo -e "${RED}Failed to install required packages${NC}" 1>&2
exit 1
fi
echo -e "${GREEN}Required packages installed successfully${NC}"

# Configure PHP extensions
sudo phpenmod bcmath gmp imagick intl -y &>> ${LOG}
if [ $? -ne 0 ]; then
echo -e "${RED}Failed to set up PHP extensions${NC}" 1>&2
exit 1
fi
echo -e "${GREEN}PHP extensions setup successfully completed${NC}"

# Setup Nextcloud
echo -e "${YELLOW}Setting up Apache and Nextcloud files... This may take some time.${NC}"
unzip latest.zip > /dev/null 2>&1

# Rename Nextcloud directory
mv nextcloud ${NCdomainName}

# Set folder permissions
sudo chown -R www-data:www-data ${NCdomainName}

# Move Nextcloud folder to Apache directory
sudo mv ${NCdomainName} /var/www

# Disable default Apache site
sudo a2dissite 000-default.conf > /dev/null 2>&1 &>> ${LOG}

# Create host config file
cat > /etc/apache2/sites-available/${NCdomainName}.conf << EOF
<VirtualHost *:80>
DocumentRoot /var/www/${NCdomainName}/
ServerName ${NCdomainName}

<Directory /var/www/${NCdomainName}/>
Require all granted
AllowOverride All
Options FollowSymLinks MultiViews

<IfModule mod_dav.c>
Dav off
</IfModule>
</Directory>
</VirtualHost>
<VirtualHost *:443>
DocumentRoot "/var/www/${NCdomainName}"

Header add Strict-Transport-Security: "max-age=15552000;includeSubdomains"

ServerAdmin admin@${NCdomainName}
ServerName ${NCdomainName}

<Directory "/var/www/${NCdomainName}/">
Options Indexes FollowSymLinks
AllowOverride None
Require all granted
Satisfy Any

Include /var/www/${NCdomainName}/.htaccess
</Directory>

<Directory /var/www/${NCdomainName}/data>
Require all denied
</Directory>

<Directory /var/www/${NCdomainName}/config/>
Require all denied
</Directory>

<IfModule mod_dav.c>
Dav off
</IfModule>

<Files ".ht*">
Require all denied
</Files>

SetEnv HOME /var/www/${NCdomainName}
SetEnv HTTP_HOME /var/www/${NCdomainName}

TraceEnable off
RewriteEngine On
RewriteCond %{REQUEST_METHOD} ^TRACK
RewriteRule .* - [R=405,L]

# Avoid "Sabre\DAV\Exception\BadRequest: expected filesize XXXX got XXXX"
<IfModule mod_reqtimeout.c>
RequestReadTimeout body=0
</IfModule>

# Avoid zero byte files (only works in Ubuntu 22.04 -->>)
SetEnv proxy-sendcl 1

TransferLog /var/log/apache2/${NCdomainName}.log
ErrorLog /var/log/apache2/${NCdomainName}.error.log

SSLEngine on
SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
</VirtualHost>
EOF

# Enable Apache modules and site
sudo a2enmod rewrite headers ssl &>> ${LOG}
sudo a2ensite ${NCdomainName}.conf &>> ${LOG}
sudo systemctl restart apache2 &>> ${LOG}

# Finalize Nextcloud installation
echo -e "${YELLOW}Finalizing Nextcloud installation...${NC}"
sudo -u www-data php /var/www/${NCdomainName}/occ maintenance:install \
--database "mysql" \
--database-name "${NCDbName}" \
--database-user "${DbUser}" \
--database-pass "${DbPwd}" \
--admin-user "${NCAdmin}" \
--admin-pass "${NCPass}" \
--data-dir "/var/www/${NCdomainName}/data" &>> ${LOG}

# Set Nextcloud to use cron instead of Ajax
sudo crontab -u www-data -l | { cat; echo "*/5 * * * * php -f /var/www/${NCdomainName}/cron.php > /dev/null 2>&1"; } | sudo crontab -u www-data -

# Update cron
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set maintenance_window_start --value="15"

# Enable pretty URLs
echo -e "${YELLOW}Enabling pretty URLs.${NC}"
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set htaccess.RewriteBase --value="/"
sudo -u www-data php /var/www/${NCdomainName}/occ maintenance:update:htaccess

# Securing web UI from brute force
echo -e "${YELLOW}Enabling brute force protection.${NC}"
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set auth.bruteforce.protection.enabled --value="true"

# Set trusted domains
echo -e "${YELLOW}Enabling trusted domains.${NC}"
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set trusted_domains 1 --value="${NCdomainName}"
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set trusted_domains 2 --value="${NCIP}"

# Fix directory issue for Nextcloud 29.0.1
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set overwritehost --value="${NCIP}"
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set overwriteprotocol --value="https"
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set overwrite.cli.url --value="https://${NCdomainName}"

# Set PHP recommended configurations
echo -e "${YELLOW}Enabling PHP recommendations for Nextcloud.${NC}"
sudo sed -i "s:memory_limit = .*:memory_limit = 512M:" $PHP
sudo sed -i "s:upload_max_filesize = .*:upload_max_filesize = 200M:" $PHP
sudo sed -i "s:max_execution_time = .*:max_execution_time = 360:" $PHP
sudo sed -i "s:post_max_size = .*:post_max_size = 200M:" $PHP
sudo sed -i "s:;opcache.interned_strings_buffer=.*:opcache.interned_strings_buffer=16:" $PHP
sudo sed -i "s:;opcache.max_accelerated_files=.*:opcache.max_accelerated_files=10000:" $PHP
sudo sed -i "s:;opcache.memory_consumption=.*:opcache.memory_consumption=128:" $PHP
sudo sed -i "s:;opcache.save_comments=.*:opcache.save_comments=1:" $PHP
sudo sed -i "s:;opcache.revalidate_freq=.*:opcache.revalidate_freq=1:" $PHP

# Add and fix for memcache local
sudo sed -i -e $'$a\\[nextcloud]' /etc/php/*/mods-available/apcu.ini
sudo sed -i -e $'$a\\apc.enable_cli = 1' /etc/php/*/mods-available/apcu.ini
sudo sed -i -e $'$a\\memory_limit = 512M' /etc/php/*/mods-available/apcu.ini

#fix mime types
sudo -u www-data php /var/www/${NCdomainName}/occ maintenance:repair --include-expensive
sleep 5

#fix database and add missing indeces
sudo -u www-data php /var/www/${NCdomainName}/occ db:add-missing-indices

# Setup caching
echo -e "${YELLOW}Setting up caching..${NC}"
sudo usermod -a -G redis www-data
sleep 5
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set filelocking.enabled --value="true"
sleep 5
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set memcache.local --value="\OC\Memcache\APCu"
sleep 5
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set memcache.locking --value="\OC\Memcache\Redis"
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set memcache.distributed --value="\OC\Memcache\Redis"
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set redis host --value="localhost"
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set redis port --value="6379"
sudo -u www-data php /var/www/${NCdomainName}/occ config:system:set redis timeout --value="0.0"

# Configure theming
sudo -u www-data php /var/www/${NCdomainName}/occ theming:config name ${NCdomainName}
sudo -u www-data php /var/www/${NCdomainName}/occ theming:config url https://${NCdomainName}

# Final messages
echo -e "${GREEN}Nextcloud Installation is complete!${NC}"
echo -e "Access Nextcloud at: https://${NCdomainName}"
echo -e "Admin credentials: ${NCAdmin} / ${NCPass}"
echo -e "Database credentials: ${DbUser} / ${DbPwd}"
echo -e "By AchmadPR"

exit 0
