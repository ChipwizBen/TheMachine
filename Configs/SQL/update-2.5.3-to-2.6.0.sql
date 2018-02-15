ALTER TABLE `TheMachine`.`rules` 
CHANGE COLUMN `last_approved` `last_approved` DATETIME NULL;

ALTER TABLE `TheMachine`.`rules` 
CHANGE COLUMN `approved_by` `approved_by` VARCHAR(128) NULL;

ALTER TABLE `TheMachine`.`credentials` 
CHANGE COLUMN `email` `email` VARCHAR(128) NULL ;

ALTER TABLE `TheMachine`.`host_attributes` 
ADD COLUMN `vm_name` VARCHAR(128) NULL AFTER `ro_community_string`;

CREATE TABLE `TheMachine`.`config_system` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `Recovery_Email_Address` VARCHAR(255) NULL,
  `DNS_Server` VARCHAR(15) NULL,
  `Verbose` INT(1) NULL DEFAULT 0,
  `md5sum` VARCHAR(255) NULL,
  `cut` VARCHAR(255) NULL,
  `visudo` VARCHAR(255) NULL,
  `cp` VARCHAR(255) NULL,
  `ls` VARCHAR(255) NULL,
  `sudo_grep` VARCHAR(255) NULL,
  `head` VARCHAR(255) NULL,
  `nmap` VARCHAR(255) NULL,
  `ps` VARCHAR(255) NULL,
  `wc` VARCHAR(255) NULL,
  `git` VARCHAR(255) NULL,
  `Enforce_Password_Complexity_Requirements` INT(1) NULL DEFAULT 0,
  `Password_Complexity_Minimum_Length` INT(3) NULL DEFAULT '8',
  `Password_Complexity_Minimum_Upper_Case_Characters` INT(3) NULL DEFAULT '2',
  `Password_Complexity_Minimum_Lower_Case_Characters` INT(3) NULL DEFAULT '2',
  `Password_Complexity_Minimum_Digits` INT(3) NULL DEFAULT '2',
  `Password_Complexity_Minimum_Special_Characters` INT(3) NULL DEFAULT '2',
  `Password_Complexity_Accepted_Special_Characters` VARCHAR(255) NULL DEFAULT '!@#$%^&*()[]{}-_+=/\,.<>" ',
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`config_sudoers` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `Sudoers_Owner` VARCHAR(255) NULL DEFAULT 'root',
  `Sudoers_Group` VARCHAR(255) NULL DEFAULT 'apache',
  `Sudoers_Location` VARCHAR(255) NULL DEFAULT '../sudoers',
  `Sudoers_Storage` VARCHAR(255) NULL DEFAULT '../Storage/DSMS/',
  `Distribution_SFTP_Port` INT(5) NOT NULL DEFAULT '22',
  `Distribution_User` VARCHAR(255) NULL DEFAULT 'transport',
  `Key_Path` VARCHAR(255) NULL DEFAULT '/root/.ssh/id_rsa',
  `Distribution_Timeout` INT(5) NOT NULL DEFAULT '15',
  `Remote_Sudoers` VARCHAR(255) NULL DEFAULT 'upload/sudoers',
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`config_dns` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `DNS_Owner` VARCHAR(255) NULL DEFAULT 'root',
  `DNS_Group` VARCHAR(255) NULL DEFAULT 'bind',
  `Zone_Master_File` VARCHAR(255) NULL DEFAULT '/etc/bind/named.conf.local',
  `DNS_Storage` VARCHAR(255) NULL DEFAULT '/opt/TheMachine/HTTP/Storage/DNS',
  `DNS_Internal_Location` VARCHAR(255) NULL DEFAULT '/etc/bind/master',
  `Internal_Email` VARCHAR(255) NULL DEFAULT 'postmaster@domain.com',
  `Internal_TTL` INT(16) NULL DEFAULT '86400',
  `Internal_Refresh` INT(16) NULL DEFAULT '10800',
  `Internal_Retry` INT(16) NULL DEFAULT '3600',
  `Internal_Expire` INT(16) NULL DEFAULT '2419200',
  `Internal_Minimum` INT(16) NULL DEFAULT '86400',
  `Internal_NS1` VARCHAR(255) NULL DEFAULT 'ns1.domain.local',
  `Internal_NS2` VARCHAR(255) NULL DEFAULT 'ns2.domain.local',
  `Internal_NS3` VARCHAR(255) NULL DEFAULT 'ns3.domain.local',
  `DNS_External_Location` VARCHAR(255) NULL DEFAULT '/etc/bind/master',
  `External_Email` VARCHAR(255) NULL DEFAULT 'postmaster@domain.com',
  `External_TTL` INT(16) NULL DEFAULT '86400',
  `External_Refresh` INT(16) NULL DEFAULT '10800',
  `External_Retry` INT(16) NULL DEFAULT '3600',
  `External_Expire` INT(16) NULL DEFAULT '2419200',
  `External_Minimum` INT(16) NULL DEFAULT '86400',
  `External_NS1` VARCHAR(255) NULL DEFAULT 'ns1.domain.com',
  `External_NS2` VARCHAR(255) NULL DEFAULT 'ns2.domain.com',
  `External_NS3` VARCHAR(255) NULL DEFAULT 'ns3.domain.com',
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`config_reverse_proxy` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `Reverse_Proxy_Location` VARCHAR(255) NULL DEFAULT '/opt/TheMachine/HTTP/Storage/tmp/ReverseProxy',
  `Proxy_Redirect_Location` VARCHAR(255) NULL DEFAULT '/opt/TheMachine/HTTP/Storage/tmp/ReverseProxy',
  `Reverse_Proxy_Storage` VARCHAR(255) NULL DEFAULT '/opt/TheMachine/HTTP/Storage/ReverseProxy',
  `Proxy_Redirect_Storage` VARCHAR(255) NULL DEFAULT '/opt/TheMachine/HTTP/Storage/ReverseProxy',
  `Reverse_Proxy_Transfer_Log_Path` VARCHAR(255) NULL DEFAULT '/var/log/httpd',
  `Reverse_Proxy_Error_Log_Path` VARCHAR(255) NULL DEFAULT '/var/log/httpd',
  `Proxy_Redirect_Transfer_Log_Path` VARCHAR(255) NULL DEFAULT '/var/log/httpd',
  `Proxy_Redirect_Error_Log_Path` VARCHAR(255) NULL DEFAULT '/var/log/httpd',
  `Reverse_Proxy_SSL_Certificate_File` VARCHAR(255) NULL DEFAULT '/etc/ssl/certs/wildcard.crt',
  `Reverse_Proxy_SSL_Certificate_Key_File` VARCHAR(255) NULL DEFAULT '/etc/ssl/certs/wildcard.key',
  `Reverse_Proxy_SSL_CA_Certificate_File` VARCHAR(255) NULL DEFAULT '/etc/ssl/certs/ca_bundle.pem',
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`config_ldap` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `LDAP_Enabled` INT(1) NOT NULL DEFAULT '0',
  `LDAP_Server` VARCHAR(255) NULL,
  `LDAP_Port` INT(5) NULL,
  `LDAP_Timeout` INT(5) NULL,
  `LDAP_User_Name_Prefix` VARCHAR(255) NULL,
  `LDAP_Filter` VARCHAR(255) NULL,
  `LDAP_Search_Base` VARCHAR(255) NULL,
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`config_dshell` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `DShell_WaitFor_Timeout` INT(8) NOT NULL DEFAULT '1800',
  `DShell_Queue_Execution_Cap` INT(5) NOT NULL DEFAULT '10',
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`config_git` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `Use_Git` INT(1) NOT NULL DEFAULT '0',
  `Git_Directory` VARCHAR(255) NOT NULL DEFAULT '/opt/TheMachine/HTTP/Storage/Git',
  `Git_Redirect` VARCHAR(255) NOT NULL DEFAULT 'Redirect',
  `Git_ReverseProxy` VARCHAR(255) NOT NULL DEFAULT 'ReverseProxy',
  `Git_CommandSets` VARCHAR(255) NOT NULL DEFAULT 'CommandSets',
  `Git_DSMS` VARCHAR(255) NOT NULL DEFAULT 'DSMS',
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`config_vmware` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `vSphere_Server` VARCHAR(255) NOT NULL,
  `vSphere_Username` VARCHAR(255) NOT NULL,
  `vSphere_Password` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`config_proxmox` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `Proxmox_Server` VARCHAR(255) NOT NULL,
  `Proxmox_Port` INT(5) NOT NULL DEFAULT '8006',
  `Proxmox_Username` VARCHAR(255) NOT NULL DEFAULT 'root@pam',
  `Proxmox_Password` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`));

CREATE TABLE `TheMachine`.`version` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `Version` VARCHAR(64) NULL,
  `Latest_Version` VARCHAR(64) NULL,
  `URL` VARCHAR(255) NULL,
  `Notification` VARCHAR(255) NULL,
  PRIMARY KEY (`id`));

