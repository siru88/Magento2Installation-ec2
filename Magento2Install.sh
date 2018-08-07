#!/bin/bash
#Install MySQL 5.7 service
yum install mysql57-server mysql57 -y

#Install PHP and HTTPD service
yum install php71-pdo php71-mcrypt php71-mbstring php71-mysqlnd php71-curl php71-intl php71-cli php71-gd php71-bcmath php71-soap php71 httpd24-devel httpd24-tools httpd24 -y

#Make HTTPD and MySQL service to start on boot.
chkconfig httpd on
chkconfig mysqld on

#Start HTTPD and MySQL service
/etc/init.d/httpd start
/etc/init.d/mysqld start

#Set up MySQL root password.
password=`/opt/aws/bin/ec2-metadata -i | awk '{print $2}'`
/usr/libexec/mysql57/mysqladmin -u root password $password
echo $password

#Setup new database and logins for Magento2 site.
DBNAME=`/opt/aws/bin/ec2-metadata -i | awk '{print $2}' | tail -c 3`
DBUSER=`/opt/aws/bin/ec2-metadata -i | awk '{print $2}' | head -c 3`
PASS=`openssl rand -base64 12`
NEWDBNAME=magento$DBNAME
echo $NEWDBNAME
NEWDBUSER=magento$DBUSER

mysql -u root -p$password -e "CREATE DATABASE ${NEWDBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -u root -p$password -e "CREATE USER '${NEWDBUSER}'@'localhost' IDENTIFIED BY '${PASS}';"
mysql -u root -p$password -e "GRANT ALL PRIVILEGES ON ${NEWDBNAME}.* TO '${NEWDBUSER}'@'localhost';"
mysql -u root -p$password -e "FLUSH PRIVILEGES;"
sudo -u ec2-user touch ~/dblogin.txt
echo dbname=$NEWDBNAME > /home/ec2-user/dblogin.txt
echo dbusername=$NEWDBUSER >> /home/ec2-user/dblogin.txt
echo dbpassword=$PASS >> /home/ec2-user/dblogin.txt
echo $PASS
echo [client] > /root/.my.cnf
echo user=root >> /root/.my.cnf
echo password="\"$password"\" >> /root/.my.cnf

#Installing Composer command
cd /tmp
sudo curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
#Install zip and unzip commands
yum install zip unzip git -y
#Downloading Magento2 files and placing it in /var/www/html Document Root
mv /var/www/html /var/www/html.bak
cd /var/www
git clone https://github.com/magento/magento2.git
mv magento2 /var/www/html
cd /var/www/html
/usr/local/bin/composer install
chown ec2-user:apache /var/www/html -R
chmod 2775 /var/www/html -R
