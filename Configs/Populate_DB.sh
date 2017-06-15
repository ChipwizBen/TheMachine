#!/bin/bash

DIR='/opt/TheMachine'
Random_Password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

if [ -e $DIR/HTTP/common.pl ]; then
        if [ -e $DIR/version ]; then
                Old_Version=$(cat $DIR/version)
                echo "Old Version: $Old_Version"
                New_Version=$(grep '$Version\s=' $DIR/HTTP/common.pl | sed -r "s/.*'(.*)'.*/\1/")
                echo "New Version: $New_Version"
        else
                Old_Version='none'
        fi
fi


if [ "$Old_Version" = "none" ]; then
    echo "Previous installation not found. Please provide MariaDB root password for DB setup:"
    echo -n "Password: "
    read -s MariaDB_Root_Password

    mysql -u root -p$MariaDB_Root_Password < $DIR/Configs/SQL/FullSchema.sql
    mysql -u root -p$MariaDB_Root_Password << _EOF_
    CREATE USER 'TheMachine'@'localhost' IDENTIFIED BY '$Random_Password';
    GRANT ALL PRIVILEGES ON \`TheMachine\`.* TO 'TheMachine'@'localhost';
    FLUSH PRIVILEGES;
    INSERT INTO \`TheMachine\`.\`credentials\` (\`username\`, \`password\`, \`admin\`, \`ip_admin\`, \`icinga_admin\`, \`dshell_admin\`, \`dns_admin\`, \`reverse_proxy_admin\`, \`dsms_admin\`, \`approver\`, \`requires_approval\`) VALUES ('admin', 'c7ad44cbad762a5da0a452f9e854fdc1e0e7a52a38015f23f3eab1d80b931dd472634dfac71cd34ebc35d16ab7fb8a90c81f975113d6c7538dc69dd8de9077ec', '1', '1', '1', '1', '1', '1', '1', '1', '0');
_EOF_

        sed -i "s/\$DB_Host = '.*'/\$DB_Host = 'localhost'/" $DIR/HTTP/common.pl
        sed -i "s/\$DB_Port = '.*'/\$DB_Port = '3306'/" $DIR/HTTP/common.pl
        sed -i "s/\$DB_Name = '.*'/\$DB_Name = 'TheMachine'/" $DIR/HTTP/common.pl
        sed -i "s/\$DB_User = '.*'/\$DB_User = 'TheMachine'/" $DIR/HTTP/common.pl
        sed -i "s/\$DB_Password = '.*'/\$DB_Password = '$Random_Password'/" $DIR/HTTP/common.pl

else
        cp $DIR/HTTP/common.pl-upgrade-backup-$(date '+%Y-%m-%d') $DIR/HTTP/common.pl
        sed -i "s/\$DB_Password = '.*'/\$DB_Password = '$Random_Password'/" $DIR/HTTP/common.pl
        sed -i "s/\$Version = '.*'/\$Version = '$New_Version'/" $DIR/HTTP/common.pl
        chown root:$Group $DIR/HTTP/common.pl
        chmod 550 $DIR/HTTP/common.pl
fi

if [[ "$Old_Version" < 2.3 ]]; then
        echo "Upgrading DB to v2.3..."
        mysql -u root < $DIR/Configs/SQL/update-2.2.x-to-2.3.0.sql
fi
if [[ "$Old_Version" < 2.4 ]]; then
        echo "Upgrading DB to v2.4..."
        mysql -u root < $DIR/Configs/SQL/update-2.3.x-to-2.4.0.sql
fi

mysql -u root -p$MariaDB_Root_Password  << EOF
GRANT ALL PRIVILEGES ON \`TheMachine\`.* TO 'TheMachine'@'localhost';
SET PASSWORD FOR 'TheMachine'@'localhost' = PASSWORD('$Random_Password');
FLUSH PRIVILEGES;
EOF

rm -f $DIR/version
