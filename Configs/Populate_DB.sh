#!/bin/bash

DIR='/opt/TheMachine'
User='apache'
Group='apache'

Random_Password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

if [ -e $DIR/HTTP/common.pl ]; then

        cp /opt/TheMachine/HTTP/common.pl /opt/TheMachine/HTTP/common.pl-upgrade-backup-$(date '+%Y-%m-%d')
        chown root:root /opt/TheMachine/HTTP/common.pl-upgrade-backup-$(date '+%Y-%m-%d')
        chmod 700 /opt/TheMachine/HTTP/common.pl-upgrade-backup-$(date '+%Y-%m-%d')

fi

echo "Please provide MariaDB root password for DB setup. This will CLEAR any existing Machine database. If you do not have a root password set for MariaDB (such as if this is a new server build) then press return at each password prompt. CTRL+C to abort:"
echo -n "Password: "
read -s MariaDB_Root_Password

echo -e "\nPopulating DB..."
mysql -u root -p$MariaDB_Root_Password < $DIR/Configs/SQL/FullSchema.sql

echo "Creating TheMachine user..."
mysql -u root -p$MariaDB_Root_Password << _EOF_
CREATE USER 'TheMachine'@'localhost';
FLUSH PRIVILEGES;
_EOF_

echo "Setting TheMachine's privileges..."
mysql -u root -p$MariaDB_Root_Password << _EOF_
GRANT ALL PRIVILEGES ON \`TheMachine\`.* TO 'TheMachine'@'localhost';
SET PASSWORD FOR 'TheMachine'@'localhost' = PASSWORD('$Random_Password');
FLUSH PRIVILEGES;
_EOF_

echo "Creating starter account (Username/Password: admin/admin)..."
mysql -u root -p$MariaDB_Root_Password << _EOF_
INSERT INTO \`TheMachine\`.\`credentials\` (\`username\`, \`password\`, \`admin\`, \`ip_admin\`, \`icinga_admin\`, \`dshell_admin\`, \`dns_admin\`, \`reverse_proxy_admin\`, \`dsms_admin\`, \`approver\`, \`requires_approval\`) VALUES ('admin', 'c7ad44cbad762a5da0a452f9e854fdc1e0e7a52a38015f23f3eab1d80b931dd472634dfac71cd34ebc35d16ab7fb8a90c81f975113d6c7538dc69dd8de9077ec', '1', '1', '1', '1', '1', '1', '1', '1', '0');
_EOF_

echo "Populating $DIR/HTTP/common.pl..."
sed -i "s/\$DB_Host = '.*'/\$DB_Host = 'localhost'/" $DIR/HTTP/common.pl
sed -i "s/\$DB_Port = '.*'/\$DB_Port = '3306'/" $DIR/HTTP/common.pl
sed -i "s/\$DB_Name = '.*'/\$DB_Name = 'TheMachine'/" $DIR/HTTP/common.pl
sed -i "s/\$DB_User = '.*'/\$DB_User = 'TheMachine'/" $DIR/HTTP/common.pl
sed -i "s/\$DB_Password = '.*'/\$DB_Password = '$Random_Password'/" $DIR/HTTP/common.pl

