#!/bin/bash

DIR='/opt/TheMachine'
User='apache'
Group='apache'

chown root:$Group $DIR/
chmod g+x $DIR/
chown -R root:$Group $DIR/HTTP/
chmod -R 550 $DIR/HTTP/
chmod 550 $DIR/HTTP/*.cgi
chmod 550 $DIR/HTTP/*/*.cgi
chmod 550 $DIR/HTTP/*/*/*.cgi
chmod 500 $DIR/HTTP/*.pl
chmod 500 $DIR/HTTP/*/*.pl
chown root:$Group $DIR/HTTP/common.pl $DIR/HTTP/register.pl $DIR/HTTP/checkin.pl
chmod 550 $DIR/HTTP/common.pl $DIR/HTTP/register.pl $DIR/HTTP/checkin.pl
chown root:root $DIR/HTTP/DSMS/sudoers-build.pl $DIR/HTTP/DSMS/distribution.pl
chmod 100 $DIR/HTTP/DSMS/sudoers-build.pl $DIR/HTTP/DSMS/distribution.pl
chown root:$Group $DIR/HTTP/DSMS/environmental-defaults
chmod 640 $DIR/HTTP/DSMS/environmental-defaults
chown -R root:$Group $DIR/HTTP/format.css $DIR/HTTP/Resources/
chmod -R 440 $DIR/HTTP/format.css $DIR/HTTP/Resources/
find $DIR/HTTP/ -type d -exec chmod 550 {} \;
chown -R root:root $DIR/HTTP/Storage/
chmod -R 711 $DIR/HTTP/Storage/
chown -R $User. $DIR/HTTP/Storage/D-Shell/Job-Log
chmod -R 711 $DIR/HTTP/Storage/D-Shell/Job-Log
chown $User. $DIR/HTTP/Storage/D-Shell/tmp
chmod 711 $DIR/HTTP/Storage/D-Shell/tmp
chmod 550 $DIR/HTTP/D-Shell/*.cgi
chmod 550 $DIR/HTTP/D-Shell/*.pl

chown $User:$Group /var/log/TheMachine

# API use only
chmod 755 $DIR/HTTP/
chmod 755 $DIR/HTTP/D-Shell/
chmod 755 $DIR/HTTP/Storage/D-Shell
chmod 777 $DIR/HTTP/Storage/D-Shell/Job-Log
chmod 777 $DIR/HTTP/Storage/D-Shell/tmp
chmod 555 $DIR/HTTP/D-Shell/job-receiver.pl
chmod 555 $DIR/HTTP/D-Shell/d-shell.pl
chmod 555 $DIR/HTTP/common.pl
# / API use only

# SELinux
setsebool -P httpd_can_sendmail 1 # Allows apache to send emails
setsebool -P httpd_enable_cgi 1 # Allows apache to run CGI
setsebool -P httpd_can_network_connect 1 # Allows apache to connect to network
setsebool -P httpd_can_connect_ldap 1 # Allows apache to connect to AD to auth

# Allows apache to exec files
semanage fcontext -a -t httpd_sys_script_exec_t "$DIR/HTTP(/.*)?"
# Allows apache to write System logs
semanage fcontext -a -t httpd_cache_t "/var/log/TheMachine(/.*)?"
# Allows apache to write D-Shell config/logs
semanage fcontext -a -t httpd_cache_t "$DIR/HTTP/Storage/D-Shell(/.*)?"
# Allows apache to write DNS config
semanage fcontext -a -t httpd_cache_t "$DIR/HTTP/Storage/DNS(/.*)?"
# Allows apache to write Sudoers config
semanage fcontext -a -t httpd_cache_t "$DIR/HTTP/Storage/Sudoers(/.*)?"

if [[ $(semodule --list | grep TheMachine) ]]; then
	semodule -r TheMachine
fi

cat <<_EOF_> /tmp/TheMachine.te
module TheMachine 1.0.0;
require {
        type unconfined_t;
        type init_t;
        type auditd_t;
        type mysqld_t;
        type syslogd_t;
        type tty_device_t;
        type unconfined_service_t;
        type setroubleshootd_t;
        type irqbalance_t;
        type tuned_t;
        type snmpd_t;
        type user_devpts_t;
        type rhsmcertd_t;
        type httpd_cache_t;
        type system_dbusd_t;
        type system_cronjob_t;
        type rpm_t;
        type devpts_t;
        type kernel_t;
        type httpd_sys_script_t;
        type firewalld_t;
        type systemd_logind_t;
        type httpd_t;
        type audisp_t;
        type policykit_t;
        type puppetagent_t;
        type sssd_t;
        type udev_t;
        type mysqld_safe_t;
        type sendmail_t;
        type sshd_t;
        type crond_t;
        type getty_t;
        type ptmx_t;
        type lvm_t;
        type ntpd_t;
        class chr_file { read write getattr open ioctl };
        class dir { getattr search write getattr search add_name remove_name };
        class file { read write create rename unlink getattr setattr ioctl open append};
        class filesystem getattr;
}
#============= httpd_sys_script_t ==============
allow httpd_sys_script_t audisp_t:dir { getattr search };
allow httpd_sys_script_t audisp_t:file { read open };
allow httpd_sys_script_t auditd_t:dir { getattr search };
allow httpd_sys_script_t auditd_t:file { read open };
allow httpd_sys_script_t crond_t:dir { getattr search };
allow httpd_sys_script_t crond_t:file { read open };
allow httpd_sys_script_t devpts_t:chr_file { read write getattr open ioctl };
allow httpd_sys_script_t devpts_t:dir { getattr search };
allow httpd_sys_script_t devpts_t:filesystem getattr;
allow httpd_sys_script_t firewalld_t:dir { getattr search };
allow httpd_sys_script_t firewalld_t:file { read open };
allow httpd_sys_script_t getty_t:dir { getattr search };
allow httpd_sys_script_t getty_t:file { read open };
allow httpd_sys_script_t httpd_cache_t:dir { write search add_name remove_name };
allow httpd_sys_script_t httpd_cache_t:file { read write getattr setattr create open ioctl append rename unlink };
allow httpd_sys_script_t httpd_t:dir { getattr search };
allow httpd_sys_script_t httpd_t:file { read open };
allow httpd_sys_script_t init_t:dir { getattr search };
allow httpd_sys_script_t init_t:file { read open };
allow httpd_sys_script_t irqbalance_t:dir { getattr search };
allow httpd_sys_script_t irqbalance_t:file { read open };
allow httpd_sys_script_t kernel_t:dir { getattr search };
allow httpd_sys_script_t kernel_t:file { read open };
allow httpd_sys_script_t lvm_t:dir { getattr search };
allow httpd_sys_script_t lvm_t:file { read open };
allow httpd_sys_script_t mysqld_safe_t:dir { getattr search };
allow httpd_sys_script_t mysqld_safe_t:file { read open };
allow httpd_sys_script_t mysqld_t:dir { getattr search };
allow httpd_sys_script_t mysqld_t:file { read open };
allow httpd_sys_script_t ntpd_t:dir { getattr search };
allow httpd_sys_script_t ntpd_t:file { read open };
allow httpd_sys_script_t policykit_t:dir { getattr search };
allow httpd_sys_script_t policykit_t:file { read open };
allow httpd_sys_script_t ptmx_t:chr_file { read write ioctl open getattr };
allow httpd_sys_script_t puppetagent_t:dir { getattr search };
allow httpd_sys_script_t puppetagent_t:file { read open };
allow httpd_sys_script_t rhsmcertd_t:dir { getattr search };
allow httpd_sys_script_t rhsmcertd_t:file { read open };
allow httpd_sys_script_t rpm_t:dir getattr;
allow httpd_sys_script_t sendmail_t:dir { getattr search };
allow httpd_sys_script_t sendmail_t:file { read open };
allow httpd_sys_script_t setroubleshootd_t:dir { getattr search };
allow httpd_sys_script_t setroubleshootd_t:file { read open };
allow httpd_sys_script_t snmpd_t:dir { getattr search };
allow httpd_sys_script_t snmpd_t:file { read open };
allow httpd_sys_script_t sshd_t:dir { getattr search };
allow httpd_sys_script_t sshd_t:file { read open };
allow httpd_sys_script_t sssd_t:dir { getattr search };
allow httpd_sys_script_t sssd_t:file { read open };
allow httpd_sys_script_t syslogd_t:dir { getattr search };
allow httpd_sys_script_t syslogd_t:file { read open };
allow httpd_sys_script_t system_cronjob_t:dir getattr;
allow httpd_sys_script_t system_dbusd_t:dir { getattr search };
allow httpd_sys_script_t system_dbusd_t:file { read open };
allow httpd_sys_script_t systemd_logind_t:dir { getattr search };
allow httpd_sys_script_t systemd_logind_t:file { read open };
allow httpd_sys_script_t tty_device_t:chr_file getattr;
allow httpd_sys_script_t tuned_t:dir { getattr search };
allow httpd_sys_script_t tuned_t:file { read open };
allow httpd_sys_script_t udev_t:dir { getattr search };
allow httpd_sys_script_t udev_t:file { read open };
allow httpd_sys_script_t unconfined_service_t:dir { getattr search };
allow httpd_sys_script_t unconfined_service_t:file { read open };
allow httpd_sys_script_t unconfined_t:dir { getattr search };
allow httpd_sys_script_t unconfined_t:file { read open };
allow httpd_sys_script_t user_devpts_t:chr_file getattr;
_EOF_
checkmodule -M -m -o /tmp/TheMachine.mod /tmp/TheMachine.te
semodule_package -m /tmp/TheMachine.mod -o /tmp/TheMachine.pp
semodule -i /tmp/TheMachine.pp > /dev/null 2>&1
rm -f /tmp/TheMachine.pp /tmp/TheMachine.mod /tmp/TheMachine.te
restorecon -RF $DIR
