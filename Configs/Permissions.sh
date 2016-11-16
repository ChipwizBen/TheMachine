#!/bin/bash

DIR='/opt/TheMachine'
User='apache'

mkdir -p $DIR/http/Storage/D-Shell/Job-Log
mkdir -p $DIR/http/Storage/D-Shell/tmp
chown root:apache $DIR/
chmod g+x $DIR/
chown -R root:apache $DIR/http/
chmod 550 $DIR/http/
chmod 650 $DIR/http/*.cgi
chmod 650 $DIR/http/*/*.cgi
chmod 650 $DIR/http/*/*/*.cgi
chmod 500 $DIR/http/*.pl
chmod 500 $DIR/http/*/*.pl
chown root:apache $DIR/http/common.pl $DIR/http/register.pl $DIR/http/checkin.pl
chmod 650 $DIR/http/common.pl $DIR/http/register.pl $DIR/http/checkin.pl
chown root:root $DIR/http/DSMS/sudoers-build.pl $DIR/http/DSMS/distribution.pl
chmod 100 $DIR/http/DSMS/sudoers-build.pl $DIR/http/DSMS/distribution.pl
chown root:apache $DIR/http/DSMS/environmental-defaults
chmod 640 $DIR/http/DSMS/environmental-defaults
chown -R root:apache $DIR/http/format.css $DIR/http/favicon.ico $DIR/http/resources/
chmod -R 440 $DIR/http/format.css $DIR/http/favicon.ico $DIR/http/resources/
chmod 550 $DIR/http/resources/ $DIR/http/resources/imgs/ $DIR/http/resources/imgs/buttons/
chown -R root:root $DIR/http/Storage/
chmod -R 711 $DIR/http/Storage/
chown $User. $DIR/http/Storage/D-Shell/Job-Log
chmod 711 $DIR/http/Storage/D-Shell/Job-Log
chown $User. $DIR/http/Storage/D-Shell/tmp
chmod 711 $DIR/http/Storage/D-Shell/tmp
chmod 750 $DIR/http/D-Shell/*.cgi
chmod 750 $DIR/http/D-Shell/*.pl
mkdir -p /var/log/httpd/TheMachine/
ln -s /var/log/httpd/TheMachine/ $DIR/logs

semanage fcontext -a -t httpd_sys_script_exec_t "$DIR/http(/.*)?"
restorecon -RFv $DIR
