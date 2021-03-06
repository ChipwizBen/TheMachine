CREATE DATABASE  IF NOT EXISTS `TheMachine` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `TheMachine`;
-- MySQL dump 10.13  Distrib 5.7.20, for Linux (x86_64)
--
-- Host: localhost    Database: TheMachine
-- ------------------------------------------------------
-- Server version	5.5.56-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `access_log`
--

DROP TABLE IF EXISTS `access_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `access_log` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `ip` varchar(15) NOT NULL,
  `hostname` varchar(30) DEFAULT NULL,
  `user_agent` varchar(128) DEFAULT NULL,
  `script` varchar(128) DEFAULT NULL,
  `referer` varchar(128) DEFAULT NULL,
  `query` varchar(128) DEFAULT NULL,
  `request_method` varchar(128) DEFAULT NULL,
  `https` varchar(3) NOT NULL,
  `server_name` varchar(128) DEFAULT NULL,
  `server_port` varchar(128) DEFAULT NULL,
  `username` varchar(128) DEFAULT NULL,
  `time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `audit_log`
--

DROP TABLE IF EXISTS `audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `audit_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category` varchar(255) NOT NULL,
  `method` varchar(45) NOT NULL,
  `action` text NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `username` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `auth`
--

DROP TABLE IF EXISTS `auth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key_owner` varchar(128) NOT NULL,
  `key_name` varchar(255) DEFAULT NULL,
  `default` int(1) NOT NULL DEFAULT '0',
  `salt` varchar(256) DEFAULT NULL,
  `key` blob NOT NULL,
  `key_username` varchar(128) NOT NULL,
  `key_passphrase` int(1) NOT NULL DEFAULT '0',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cgi_sessions`
--

DROP TABLE IF EXISTS `cgi_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cgi_sessions` (
  `id` char(32) NOT NULL,
  `session_data` text NOT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `command_groups`
--

DROP TABLE IF EXISTS `command_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `command_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `groupname` varchar(128) NOT NULL,
  `expires` date DEFAULT NULL,
  `active` int(1) NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `groupname_UNIQUE` (`groupname`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `command_set_dependency`
--

DROP TABLE IF EXISTS `command_set_dependency`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `command_set_dependency` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `command_set_id` int(11) NOT NULL,
  `dependent_command_set_id` int(11) NOT NULL,
  `order` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `command_sets`
--

DROP TABLE IF EXISTS `command_sets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `command_sets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `command` longtext NOT NULL,
  `description` varchar(1024) DEFAULT NULL,
  `owner_id` int(11) NOT NULL DEFAULT '0',
  `revision` int(11) NOT NULL DEFAULT '1',
  `revision_parent` int(11) DEFAULT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `commands`
--

DROP TABLE IF EXISTS `commands`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `commands` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `command_alias` varchar(128) NOT NULL,
  `command` text NOT NULL,
  `expires` date DEFAULT NULL,
  `active` int(1) NOT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `command_alias_UNIQUE` (`command_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config_dns`
--

DROP TABLE IF EXISTS `config_dns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config_dns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `DNS_Owner` varchar(255) DEFAULT 'root',
  `DNS_Group` varchar(255) DEFAULT 'bind',
  `Zone_Master_File` varchar(255) DEFAULT '/etc/bind/named.conf.local',
  `DNS_Storage` varchar(255) DEFAULT '/opt/TheMachine/HTTP/Storage/DNS',
  `DNS_Internal_Location` varchar(255) DEFAULT '/etc/bind/master',
  `Internal_Email` varchar(255) DEFAULT 'postmaster@domain.com',
  `Internal_TTL` int(16) DEFAULT '86400',
  `Internal_Refresh` int(16) DEFAULT '10800',
  `Internal_Retry` int(16) DEFAULT '3600',
  `Internal_Expire` int(16) DEFAULT '2419200',
  `Internal_Minimum` int(16) DEFAULT '86400',
  `Internal_NS1` varchar(255) DEFAULT 'ns1.domain.local',
  `Internal_NS2` varchar(255) DEFAULT 'ns2.domain.local',
  `Internal_NS3` varchar(255) DEFAULT 'ns3.domain.local',
  `DNS_External_Location` varchar(255) DEFAULT '/etc/bind/master',
  `External_Email` varchar(255) DEFAULT 'postmaster@domain.com',
  `External_TTL` int(16) DEFAULT '86400',
  `External_Refresh` int(16) DEFAULT '10800',
  `External_Retry` int(16) DEFAULT '3600',
  `External_Expire` int(16) DEFAULT '2419200',
  `External_Minimum` int(16) DEFAULT '86400',
  `External_NS1` varchar(255) DEFAULT 'ns1.domain.com',
  `External_NS2` varchar(255) DEFAULT 'ns2.domain.com',
  `External_NS3` varchar(255) DEFAULT 'ns3.domain.com',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config_dshell`
--

DROP TABLE IF EXISTS `config_dshell`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config_dshell` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `DShell_WaitFor_Timeout` int(8) NOT NULL DEFAULT '1800',
  `DShell_Queue_Execution_Cap` int(5) NOT NULL DEFAULT '10',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config_git`
--

DROP TABLE IF EXISTS `config_git`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config_git` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Use_Git` int(1) NOT NULL DEFAULT '0',
  `Git_Directory` varchar(255) NOT NULL DEFAULT '/opt/TheMachine/HTTP/Storage/Git',
  `Git_Redirect` varchar(255) NOT NULL DEFAULT 'Redirect',
  `Git_ReverseProxy` varchar(255) NOT NULL DEFAULT 'ReverseProxy',
  `Git_CommandSets` varchar(255) NOT NULL DEFAULT 'CommandSets',
  `Git_DSMS` varchar(255) NOT NULL DEFAULT 'DSMS',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config_ldap`
--

DROP TABLE IF EXISTS `config_ldap`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config_ldap` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `LDAP_Enabled` int(1) NOT NULL DEFAULT '0',
  `LDAP_Server` varchar(255) DEFAULT NULL,
  `LDAP_Port` int(5) DEFAULT NULL,
  `LDAP_Timeout` int(5) DEFAULT NULL,
  `LDAP_User_Name_Prefix` varchar(255) DEFAULT NULL,
  `LDAP_User_Name_Suffix` varchar(255) DEFAULT NULL,
  `LDAP_Filter` varchar(255) DEFAULT NULL,
  `LDAP_Search_Base` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config_proxmox`
--

DROP TABLE IF EXISTS `config_proxmox`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config_proxmox` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Proxmox_Server` varchar(255) NOT NULL,
  `Proxmox_Port` int(5) NOT NULL DEFAULT '8006',
  `Proxmox_Username` varchar(255) NOT NULL DEFAULT 'root@pam',
  `Proxmox_Password` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config_reverse_proxy`
--

DROP TABLE IF EXISTS `config_reverse_proxy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config_reverse_proxy` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Reverse_Proxy_Location` varchar(255) DEFAULT '/opt/TheMachine/HTTP/Storage/tmp/ReverseProxy',
  `Proxy_Redirect_Location` varchar(255) DEFAULT '/opt/TheMachine/HTTP/Storage/tmp/ReverseProxy',
  `Reverse_Proxy_Storage` varchar(255) DEFAULT '/opt/TheMachine/HTTP/Storage/ReverseProxy',
  `Proxy_Redirect_Storage` varchar(255) DEFAULT '/opt/TheMachine/HTTP/Storage/ReverseProxy',
  `Reverse_Proxy_Transfer_Log_Path` varchar(255) DEFAULT '/var/log/httpd',
  `Reverse_Proxy_Error_Log_Path` varchar(255) DEFAULT '/var/log/httpd',
  `Proxy_Redirect_Transfer_Log_Path` varchar(255) DEFAULT '/var/log/httpd',
  `Proxy_Redirect_Error_Log_Path` varchar(255) DEFAULT '/var/log/httpd',
  `Reverse_Proxy_SSL_Certificate_File` varchar(255) DEFAULT '/etc/ssl/certs/wildcard.crt',
  `Reverse_Proxy_SSL_Certificate_Key_File` varchar(255) DEFAULT '/etc/ssl/certs/wildcard.key',
  `Reverse_Proxy_SSL_CA_Certificate_File` varchar(255) DEFAULT '/etc/ssl/certs/ca_bundle.pem',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config_sudoers`
--

DROP TABLE IF EXISTS `config_sudoers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config_sudoers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Sudoers_Owner` varchar(255) DEFAULT 'root',
  `Sudoers_Group` varchar(255) DEFAULT 'apache',
  `Sudoers_Location` varchar(255) DEFAULT '../sudoers',
  `Sudoers_Storage` varchar(255) DEFAULT '../Storage/DSMS/',
  `Distribution_SFTP_Port` int(5) NOT NULL DEFAULT '22',
  `Distribution_User` varchar(255) DEFAULT 'transport',
  `Key_Path` varchar(255) DEFAULT '/root/.ssh/id_rsa',
  `Distribution_Timeout` int(5) NOT NULL DEFAULT '15',
  `Remote_Sudoers` varchar(255) DEFAULT 'upload/sudoers',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config_system`
--

DROP TABLE IF EXISTS `config_system`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config_system` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Recovery_Email_Address` varchar(255) DEFAULT NULL,
  `DNS_Server` varchar(15) DEFAULT NULL,
  `Verbose` int(1) DEFAULT '0',
  `md5sum` varchar(255) DEFAULT NULL,
  `cut` varchar(255) DEFAULT NULL,
  `visudo` varchar(255) DEFAULT NULL,
  `cp` varchar(255) DEFAULT NULL,
  `ls` varchar(255) DEFAULT NULL,
  `sudo_grep` varchar(255) DEFAULT NULL,
  `head` varchar(255) DEFAULT NULL,
  `nmap` varchar(255) DEFAULT NULL,
  `ps` varchar(255) DEFAULT NULL,
  `wc` varchar(255) DEFAULT NULL,
  `git` varchar(255) DEFAULT NULL,
  `Enforce_Password_Complexity_Requirements` int(1) DEFAULT '0',
  `Password_Complexity_Minimum_Length` int(3) DEFAULT '8',
  `Password_Complexity_Minimum_Upper_Case_Characters` int(3) DEFAULT '2',
  `Password_Complexity_Minimum_Lower_Case_Characters` int(3) DEFAULT '2',
  `Password_Complexity_Minimum_Digits` int(3) DEFAULT '2',
  `Password_Complexity_Minimum_Special_Characters` int(3) DEFAULT '2',
  `Password_Complexity_Accepted_Special_Characters` varchar(255) DEFAULT '!@#$%^&*()[]{}-_+=/,.<>" ',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `config_vmware`
--

DROP TABLE IF EXISTS `config_vmware`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `config_vmware` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vSphere_Server` varchar(255) NOT NULL,
  `vSphere_Username` varchar(255) NOT NULL,
  `vSphere_Password` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `credentials`
--

DROP TABLE IF EXISTS `credentials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `credentials` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `username` varchar(128) NOT NULL,
  `password` varchar(128) NOT NULL,
  `salt` varchar(64) NOT NULL,
  `email` varchar(128) DEFAULT NULL,
  `last_login` datetime DEFAULT NULL,
  `last_active` datetime DEFAULT NULL,
  `admin` int(1) NOT NULL DEFAULT '0',
  `ip_admin` int(1) NOT NULL DEFAULT '0',
  `icinga_admin` int(1) NOT NULL DEFAULT '0',
  `dshell_admin` int(1) NOT NULL DEFAULT '0',
  `dns_admin` int(1) NOT NULL DEFAULT '0',
  `reverse_proxy_admin` int(1) NOT NULL DEFAULT '0',
  `dsms_admin` int(1) NOT NULL DEFAULT '0',
  `approver` int(1) NOT NULL DEFAULT '0',
  `requires_approval` int(1) NOT NULL DEFAULT '1',
  `lockout` int(1) NOT NULL DEFAULT '0',
  `lockout_counter` int(1) NOT NULL DEFAULT '0',
  `lockout_reset` varchar(128) NOT NULL,
  `last_modified` timestamp NULL DEFAULT NULL,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username_UNIQUE` (`username`),
  UNIQUE KEY `email_UNIQUE` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `distribution`
--

DROP TABLE IF EXISTS `distribution`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `distribution` (
  `host_id` int(11) NOT NULL,
  `sftp_port` int(5) NOT NULL DEFAULT '22',
  `user` varchar(128) NOT NULL DEFAULT 'transport',
  `key_path` varchar(255) NOT NULL DEFAULT '/root/.ssh/id_rsa',
  `timeout` int(3) NOT NULL DEFAULT '15',
  `remote_sudoers_path` varchar(255) NOT NULL DEFAULT 'upload/sudoers',
  `status` varchar(1024) NOT NULL DEFAULT 'Not yet attempted connection.',
  `last_updated` datetime DEFAULT NULL,
  `last_successful_transfer` datetime DEFAULT NULL,
  `last_checkin` datetime DEFAULT NULL,
  `last_modified` datetime NOT NULL,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`host_id`),
  UNIQUE KEY `host_id_UNIQUE` (`host_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `domains`
--

DROP TABLE IF EXISTS `domains`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `domains` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain` varchar(255) DEFAULT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `name_UNIQUE` (`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `host_attributes`
--

DROP TABLE IF EXISTS `host_attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `host_attributes` (
  `host_id` int(11) NOT NULL,
  `fingerprint` varchar(50) DEFAULT NULL,
  `dsms` int(1) NOT NULL DEFAULT '0',
  `dhcp` int(1) NOT NULL DEFAULT '0',
  `ro_community_string` varchar(45) DEFAULT NULL,
  `vm_name` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`host_id`),
  UNIQUE KEY `host_id_UNIQUE` (`host_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `host_groups`
--

DROP TABLE IF EXISTS `host_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `host_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `groupname` varchar(128) NOT NULL,
  `expires` date DEFAULT NULL,
  `active` int(1) NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `groupname_UNIQUE` (`groupname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `host_types`
--

DROP TABLE IF EXISTS `host_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `host_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(128) NOT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `name_UNIQUE` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hosts`
--

DROP TABLE IF EXISTS `hosts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hosts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hostname` varchar(128) NOT NULL,
  `type` int(11) NOT NULL DEFAULT '0',
  `expires` date DEFAULT NULL,
  `active` int(1) NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`,`hostname`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `hostname_UNIQUE` (`hostname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_command`
--

DROP TABLE IF EXISTS `icinga2_command`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_command` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `command_name` varchar(255) NOT NULL,
  `command_line` text NOT NULL,
  `command_type` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(45) NOT NULL DEFAULT 'Build System',
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`command_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_contact`
--

DROP TABLE IF EXISTS `icinga2_contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_contact` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `contact_name` varchar(255) NOT NULL,
  `alias` varchar(255) NOT NULL,
  `contactgroups` int(10) unsigned NOT NULL DEFAULT '0',
  `contactgroups_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `host_notifications_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `service_notifications_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `host_notification_period` int(10) unsigned NOT NULL DEFAULT '0',
  `service_notification_period` int(10) unsigned NOT NULL DEFAULT '0',
  `host_notification_options` varchar(20) NOT NULL,
  `service_notification_options` varchar(20) NOT NULL,
  `host_notification_commands` int(10) unsigned NOT NULL DEFAULT '0',
  `host_notification_commands_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `service_notification_commands` int(10) unsigned NOT NULL DEFAULT '0',
  `service_notification_commands_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `can_submit_commands` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_status_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_nonstatus_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `email` varchar(255) DEFAULT NULL,
  `pager` varchar(255) DEFAULT NULL,
  `address1` varchar(255) DEFAULT NULL,
  `address2` varchar(255) DEFAULT NULL,
  `address3` varchar(255) DEFAULT NULL,
  `address4` varchar(255) DEFAULT NULL,
  `address5` varchar(255) DEFAULT NULL,
  `address6` varchar(255) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `use_variables` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `use_template` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `use_template_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(45) NOT NULL DEFAULT 'Build System',
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`contact_name`,`config_id`),
  UNIQUE KEY `contact_name_UNIQUE` (`contact_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_contactgroup`
--

DROP TABLE IF EXISTS `icinga2_contactgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_contactgroup` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `contactgroup_name` varchar(255) NOT NULL,
  `alias` varchar(255) NOT NULL,
  `members` int(10) unsigned NOT NULL DEFAULT '0',
  `contactgroup_members` int(10) unsigned NOT NULL,
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(45) NOT NULL DEFAULT 'Build System',
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`contactgroup_name`,`config_id`),
  UNIQUE KEY `contactgroup_name_UNIQUE` (`contactgroup_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_host`
--

DROP TABLE IF EXISTS `icinga2_host`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_host` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `host_name` varchar(255) NOT NULL,
  `alias` varchar(255) NOT NULL,
  `display_name` varchar(255) DEFAULT '',
  `address` varchar(255) NOT NULL,
  `parents` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `parents_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `hostgroups` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `hostgroups_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_command` text,
  `use_template` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `use_template_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `initial_state` varchar(20) DEFAULT '',
  `max_check_attempts` int(11) DEFAULT NULL,
  `check_interval` int(11) DEFAULT NULL,
  `retry_interval` int(11) DEFAULT NULL,
  `active_checks_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `passive_checks_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_period` int(11) NOT NULL DEFAULT '0',
  `obsess_over_host` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_freshness` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `freshness_threshold` int(11) DEFAULT NULL,
  `event_handler` int(11) NOT NULL DEFAULT '0',
  `event_handler_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `low_flap_threshold` int(11) DEFAULT NULL,
  `high_flap_threshold` int(11) DEFAULT NULL,
  `flap_detection_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `flap_detection_options` varchar(20) DEFAULT '',
  `process_perf_data` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_status_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_nonstatus_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `contacts` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contacts_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `contact_groups` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contact_groups_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `notification_interval` int(11) DEFAULT NULL,
  `notification_period` int(11) NOT NULL DEFAULT '0',
  `first_notification_delay` int(11) DEFAULT NULL,
  `notification_options` varchar(20) DEFAULT '',
  `notifications_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `stalking_options` varchar(20) DEFAULT '',
  `notes` varchar(255) DEFAULT '',
  `notes_url` varchar(255) DEFAULT '',
  `action_url` varchar(255) DEFAULT '',
  `icon_image` varchar(255) DEFAULT '',
  `icon_image_alt` varchar(255) DEFAULT '',
  `vrml_image` varchar(255) DEFAULT '',
  `statusmap_image` varchar(255) DEFAULT '',
  `2d_coords` varchar(255) DEFAULT '',
  `3d_coords` varchar(255) DEFAULT '',
  `use_variables` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL,
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(45) NOT NULL DEFAULT 'Build System',
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`host_name`,`config_id`),
  UNIQUE KEY `host_name_UNIQUE` (`host_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_hostgroup`
--

DROP TABLE IF EXISTS `icinga2_hostgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_hostgroup` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `hostgroup_name` varchar(255) NOT NULL,
  `alias` varchar(255) NOT NULL,
  `members` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `hostgroup_members` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `notes` varchar(255) DEFAULT NULL,
  `notes_url` varchar(255) DEFAULT NULL,
  `action_url` varchar(255) DEFAULT NULL,
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(45) NOT NULL DEFAULT 'Build System',
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`hostgroup_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_hosttemplate`
--

DROP TABLE IF EXISTS `icinga2_hosttemplate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_hosttemplate` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `template_name` varchar(255) NOT NULL,
  `alias` varchar(255) NOT NULL,
  `parents` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `parents_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `hostgroups` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `hostgroups_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_command` text,
  `use_template` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `use_template_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `initial_state` varchar(20) DEFAULT '',
  `max_check_attempts` int(11) DEFAULT NULL,
  `check_interval` int(11) DEFAULT NULL,
  `retry_interval` int(11) DEFAULT NULL,
  `active_checks_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `passive_checks_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_period` int(11) NOT NULL DEFAULT '0',
  `obsess_over_host` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_freshness` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `freshness_threshold` int(11) DEFAULT NULL,
  `event_handler` int(11) NOT NULL DEFAULT '0',
  `event_handler_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `low_flap_threshold` int(11) DEFAULT NULL,
  `high_flap_threshold` int(11) DEFAULT NULL,
  `flap_detection_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `flap_detection_options` varchar(20) DEFAULT '',
  `process_perf_data` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_status_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_nonstatus_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `contacts` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contacts_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `contact_groups` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contact_groups_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `notification_interval` int(11) DEFAULT NULL,
  `notification_period` int(11) NOT NULL DEFAULT '0',
  `first_notification_delay` int(11) DEFAULT NULL,
  `notification_options` varchar(20) DEFAULT '',
  `notifications_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `stalking_options` varchar(20) DEFAULT '',
  `notes` varchar(255) DEFAULT '',
  `notes_url` varchar(255) DEFAULT '',
  `action_url` varchar(255) DEFAULT '',
  `icon_image` varchar(255) DEFAULT '',
  `icon_image_alt` varchar(255) DEFAULT '',
  `vrml_image` varchar(255) DEFAULT '',
  `statusmap_image` varchar(255) DEFAULT '',
  `2d_coords` varchar(255) DEFAULT '',
  `3d_coords` varchar(255) DEFAULT '',
  `use_variables` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(45) NOT NULL DEFAULT 'Build System',
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`template_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkContactToCommandHost`
--

DROP TABLE IF EXISTS `icinga2_lnkContactToCommandHost`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkContactToCommandHost` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkContactToCommandService`
--

DROP TABLE IF EXISTS `icinga2_lnkContactToCommandService`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkContactToCommandService` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkHostToContactgroup`
--

DROP TABLE IF EXISTS `icinga2_lnkHostToContactgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkHostToContactgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkHostToHost`
--

DROP TABLE IF EXISTS `icinga2_lnkHostToHost`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkHostToHost` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkHostToHostgroup`
--

DROP TABLE IF EXISTS `icinga2_lnkHostToHostgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkHostToHostgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkHostToHosttemplate`
--

DROP TABLE IF EXISTS `icinga2_lnkHostToHosttemplate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkHostToHosttemplate` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  `idSort` int(11) NOT NULL,
  `idTable` tinyint(4) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`,`idTable`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkHosttemplateToContactgroup`
--

DROP TABLE IF EXISTS `icinga2_lnkHosttemplateToContactgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkHosttemplateToContactgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkHosttemplateToHost`
--

DROP TABLE IF EXISTS `icinga2_lnkHosttemplateToHost`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkHosttemplateToHost` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkHosttemplateToHosttemplate`
--

DROP TABLE IF EXISTS `icinga2_lnkHosttemplateToHosttemplate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkHosttemplateToHosttemplate` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  `idSort` int(11) NOT NULL,
  `idTable` tinyint(4) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`,`idTable`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkServiceToContact`
--

DROP TABLE IF EXISTS `icinga2_lnkServiceToContact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkServiceToContact` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkServiceToContactgroup`
--

DROP TABLE IF EXISTS `icinga2_lnkServiceToContactgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkServiceToContactgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkServiceToHost`
--

DROP TABLE IF EXISTS `icinga2_lnkServiceToHost`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkServiceToHost` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkServiceToServicegroup`
--

DROP TABLE IF EXISTS `icinga2_lnkServiceToServicegroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkServiceToServicegroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkServiceToServicetemplate`
--

DROP TABLE IF EXISTS `icinga2_lnkServiceToServicetemplate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkServiceToServicetemplate` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  `idSort` int(11) NOT NULL,
  `idTable` tinyint(4) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`,`idTable`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkServicetemplateToContact`
--

DROP TABLE IF EXISTS `icinga2_lnkServicetemplateToContact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkServicetemplateToContact` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkServicetemplateToContactgroup`
--

DROP TABLE IF EXISTS `icinga2_lnkServicetemplateToContactgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkServicetemplateToContactgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkServicetemplateToHost`
--

DROP TABLE IF EXISTS `icinga2_lnkServicetemplateToHost`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkServicetemplateToHost` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkServicetemplateToHostgroup`
--

DROP TABLE IF EXISTS `icinga2_lnkServicetemplateToHostgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkServicetemplateToHostgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkServicetemplateToServicegroup`
--

DROP TABLE IF EXISTS `icinga2_lnkServicetemplateToServicegroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkServicetemplateToServicegroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_lnkServicetemplateToServicetemplate`
--

DROP TABLE IF EXISTS `icinga2_lnkServicetemplateToServicetemplate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_lnkServicetemplateToServicetemplate` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  `idSort` int(11) NOT NULL,
  `idTable` tinyint(4) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`,`idTable`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_service`
--

DROP TABLE IF EXISTS `icinga2_service`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_service` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `config_name` varchar(255) NOT NULL DEFAULT 'Obsolete Field',
  `host_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `host_name_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `hostgroup_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `hostgroup_name_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `service_description` varchar(255) NOT NULL,
  `display_name` varchar(255) NOT NULL,
  `servicegroups` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `servicegroups_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `use_template` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `use_template_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_command` text NOT NULL,
  `is_volatile` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `initial_state` varchar(20) NOT NULL,
  `max_check_attempts` int(11) DEFAULT NULL,
  `check_interval` int(11) DEFAULT NULL,
  `retry_interval` int(11) DEFAULT NULL,
  `active_checks_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `passive_checks_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_period` int(11) NOT NULL DEFAULT '0',
  `parallelize_check` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `obsess_over_service` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_freshness` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `freshness_threshold` int(11) DEFAULT NULL,
  `event_handler` int(11) NOT NULL DEFAULT '0',
  `event_handler_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `low_flap_threshold` int(11) DEFAULT NULL,
  `high_flap_threshold` int(11) DEFAULT NULL,
  `flap_detection_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `flap_detection_options` varchar(20) NOT NULL,
  `process_perf_data` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_status_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_nonstatus_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `notification_interval` int(11) DEFAULT NULL,
  `first_notification_delay` int(11) DEFAULT NULL,
  `notification_period` int(11) NOT NULL DEFAULT '0',
  `notification_options` varchar(20) NOT NULL,
  `notifications_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `contacts` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contacts_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `contact_groups` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contact_groups_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `stalking_options` varchar(20) NOT NULL DEFAULT '',
  `notes` varchar(255) NOT NULL,
  `notes_url` varchar(255) NOT NULL,
  `action_url` varchar(255) NOT NULL,
  `icon_image` varchar(255) NOT NULL,
  `icon_image_alt` varchar(255) NOT NULL,
  `use_variables` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL DEFAULT '',
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(45) NOT NULL DEFAULT 'Build System',
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_servicegroup`
--

DROP TABLE IF EXISTS `icinga2_servicegroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_servicegroup` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `servicegroup_name` varchar(255) NOT NULL,
  `alias` varchar(255) NOT NULL,
  `members` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `servicegroup_members` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `notes` varchar(255) DEFAULT NULL,
  `notes_url` varchar(255) DEFAULT NULL,
  `action_url` varchar(255) DEFAULT NULL,
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(45) NOT NULL DEFAULT 'Build System',
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`servicegroup_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_servicetemplate`
--

DROP TABLE IF EXISTS `icinga2_servicetemplate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_servicetemplate` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `template_name` varchar(255) NOT NULL,
  `host_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `host_name_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `hostgroup_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `hostgroup_name_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `service_description` varchar(255) NOT NULL,
  `display_name` varchar(255) NOT NULL,
  `servicegroups` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `servicegroups_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `use_template` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `use_template_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_command` text NOT NULL,
  `is_volatile` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `initial_state` varchar(20) NOT NULL,
  `max_check_attempts` int(11) DEFAULT NULL,
  `check_interval` int(11) DEFAULT NULL,
  `retry_interval` int(11) DEFAULT NULL,
  `active_checks_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `passive_checks_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_period` int(11) NOT NULL DEFAULT '0',
  `parallelize_check` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `obsess_over_service` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `check_freshness` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `freshness_threshold` int(11) DEFAULT NULL,
  `event_handler` int(11) NOT NULL DEFAULT '0',
  `event_handler_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `low_flap_threshold` int(11) DEFAULT NULL,
  `high_flap_threshold` int(11) DEFAULT NULL,
  `flap_detection_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `flap_detection_options` varchar(20) NOT NULL,
  `process_perf_data` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_status_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_nonstatus_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `notification_interval` int(11) DEFAULT NULL,
  `first_notification_delay` int(11) DEFAULT NULL,
  `notification_period` int(11) NOT NULL DEFAULT '0',
  `notification_options` varchar(20) NOT NULL,
  `notifications_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `contacts` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contacts_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `contact_groups` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contact_groups_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `stalking_options` varchar(20) NOT NULL DEFAULT '',
  `notes` varchar(255) NOT NULL,
  `notes_url` varchar(255) NOT NULL,
  `action_url` varchar(255) NOT NULL,
  `icon_image` varchar(255) NOT NULL,
  `icon_image_alt` varchar(255) NOT NULL,
  `use_variables` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(45) NOT NULL DEFAULT 'Build System',
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`template_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_timedefinition`
--

DROP TABLE IF EXISTS `icinga2_timedefinition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_timedefinition` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tipId` int(10) unsigned NOT NULL,
  `definition` varchar(255) NOT NULL,
  `range` text NOT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `icinga2_timeperiod`
--

DROP TABLE IF EXISTS `icinga2_timeperiod`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `icinga2_timeperiod` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `timeperiod_name` varchar(255) NOT NULL DEFAULT '',
  `alias` varchar(255) NOT NULL DEFAULT '',
  `exclude` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `name` varchar(255) NOT NULL,
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(45) NOT NULL DEFAULT 'Build System',
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `timeperiod_name` (`timeperiod_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 PACK_KEYS=0;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ipv4_assignments`
--

DROP TABLE IF EXISTS `ipv4_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ipv4_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_block` varchar(18) NOT NULL,
  `parent_block` varchar(18) NOT NULL DEFAULT '',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`,`ip_block`,`parent_block`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ipv4_blocks`
--

DROP TABLE IF EXISTS `ipv4_blocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ipv4_blocks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_block_name` varchar(45) NOT NULL,
  `ip_block_description` varchar(128) DEFAULT NULL,
  `ip_block` varchar(18) NOT NULL,
  `gateway` varchar(15) DEFAULT NULL,
  `range_for_use` varchar(33) DEFAULT NULL,
  `range_for_use_subnet` varchar(15) DEFAULT NULL,
  `dns1` varchar(15) DEFAULT NULL,
  `dns2` varchar(15) DEFAULT NULL,
  `ntp1` varchar(15) DEFAULT NULL,
  `ntp2` varchar(15) DEFAULT NULL,
  `percent_used` varchar(5) DEFAULT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`,`ip_block_name`,`ip_block`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `ip_block_name_UNIQUE` (`ip_block_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ipv6_assignments`
--

DROP TABLE IF EXISTS `ipv6_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ipv6_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_block` varchar(43) NOT NULL,
  `parent_block` varchar(43) DEFAULT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`,`ip_block`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ipv6_blocks`
--

DROP TABLE IF EXISTS `ipv6_blocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ipv6_blocks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_block_name` varchar(45) NOT NULL,
  `ip_block_description` varchar(128) DEFAULT NULL,
  `ip_block` varchar(43) NOT NULL,
  `gateway` varchar(39) DEFAULT NULL,
  `range_for_use` varchar(81) DEFAULT NULL,
  `range_for_use_subnet` varchar(39) DEFAULT NULL,
  `dns1` varchar(39) DEFAULT NULL,
  `dns2` varchar(39) DEFAULT NULL,
  `ntp1` varchar(39) DEFAULT NULL,
  `ntp2` varchar(39) DEFAULT NULL,
  `percent_used` varchar(5) DEFAULT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`,`ip_block_name`,`ip_block`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `ip_block_name_UNIQUE` (`ip_block_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `job_queue`
--

DROP TABLE IF EXISTS `job_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `job_queue` (
  `job_id` int(11) NOT NULL,
  `override` int(1) NOT NULL DEFAULT '0',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`job_id`),
  UNIQUE KEY `job_id_UNIQUE` (`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `job_status`
--

DROP TABLE IF EXISTS `job_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `job_status` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_id` int(45) NOT NULL,
  `command` longtext NOT NULL,
  `exit_code` int(5) DEFAULT NULL,
  `output` mediumtext,
  `task_started` timestamp NULL DEFAULT NULL,
  `task_ended` timestamp NULL DEFAULT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`,`job_id`),
  KEY `idx_job_status_job_id` (`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `host_id` int(11) NOT NULL,
  `command_set_id` int(11) NOT NULL,
  `on_failure` int(1) NOT NULL DEFAULT '0',
  `status` int(1) NOT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL DEFAULT 'System',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_command_groups_to_commands`
--

DROP TABLE IF EXISTS `lnk_command_groups_to_commands`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_command_groups_to_commands` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group` int(11) NOT NULL,
  `command` int(11) NOT NULL,
  PRIMARY KEY (`id`,`command`,`group`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_host_groups_to_hosts`
--

DROP TABLE IF EXISTS `lnk_host_groups_to_hosts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_host_groups_to_hosts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group` int(11) NOT NULL,
  `host` int(11) NOT NULL,
  PRIMARY KEY (`id`,`host`,`group`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_hosts_to_ipv4_assignments`
--

DROP TABLE IF EXISTS `lnk_hosts_to_ipv4_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_hosts_to_ipv4_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `host` int(11) NOT NULL,
  `ip` int(11) NOT NULL,
  PRIMARY KEY (`id`,`ip`,`host`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_hosts_to_ipv6_assignments`
--

DROP TABLE IF EXISTS `lnk_hosts_to_ipv6_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_hosts_to_ipv6_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `host` int(11) NOT NULL,
  `ip` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_rules_to_command_groups`
--

DROP TABLE IF EXISTS `lnk_rules_to_command_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_rules_to_command_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule` int(11) NOT NULL,
  `command_group` int(11) NOT NULL,
  PRIMARY KEY (`id`,`command_group`,`rule`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_rules_to_commands`
--

DROP TABLE IF EXISTS `lnk_rules_to_commands`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_rules_to_commands` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule` int(11) NOT NULL,
  `command` int(11) NOT NULL,
  PRIMARY KEY (`id`,`command`,`rule`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_rules_to_host_groups`
--

DROP TABLE IF EXISTS `lnk_rules_to_host_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_rules_to_host_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule` int(11) NOT NULL,
  `host_group` int(11) NOT NULL,
  PRIMARY KEY (`id`,`host_group`,`rule`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_rules_to_hosts`
--

DROP TABLE IF EXISTS `lnk_rules_to_hosts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_rules_to_hosts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule` int(11) NOT NULL,
  `host` int(11) NOT NULL,
  PRIMARY KEY (`id`,`host`,`rule`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_rules_to_user_groups`
--

DROP TABLE IF EXISTS `lnk_rules_to_user_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_rules_to_user_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule` int(11) NOT NULL,
  `user_group` int(11) NOT NULL,
  PRIMARY KEY (`id`,`user_group`,`rule`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_rules_to_users`
--

DROP TABLE IF EXISTS `lnk_rules_to_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_rules_to_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule` int(11) NOT NULL,
  `user` int(11) NOT NULL,
  PRIMARY KEY (`id`,`user`,`rule`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_services_to_hosts`
--

DROP TABLE IF EXISTS `lnk_services_to_hosts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_services_to_hosts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service_id` int(11) NOT NULL,
  `host_id` int(11) NOT NULL,
  `type` int(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lnk_user_groups_to_users`
--

DROP TABLE IF EXISTS `lnk_user_groups_to_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lnk_user_groups_to_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group` int(11) NOT NULL,
  `user` int(11) NOT NULL,
  PRIMARY KEY (`id`,`user`,`group`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `lock`
--

DROP TABLE IF EXISTS `lock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `lock` (
  `sudoers-build` int(1) NOT NULL DEFAULT '0',
  `sudoers-distribution` int(1) NOT NULL DEFAULT '0',
  `dns-build` int(1) NOT NULL DEFAULT '0',
  `reverse-proxy-build` int(1) NOT NULL,
  `last-sudoers-build-started` datetime NOT NULL,
  `last-sudoers-build-finished` datetime NOT NULL,
  `last-sudoers-distribution-started` datetime NOT NULL,
  `last-sudoers-distribution-finished` datetime NOT NULL,
  `last-dns-build-started` datetime NOT NULL,
  `last-dns-build-finished` datetime NOT NULL,
  `last-reverse-proxy-build-started` datetime NOT NULL,
  `last-reverse-proxy-build-finished` datetime NOT NULL,
  PRIMARY KEY (`sudoers-build`,`sudoers-distribution`,`dns-build`,`last-sudoers-build-started`,`last-sudoers-build-finished`,`last-sudoers-distribution-started`,`last-sudoers-distribution-finished`,`last-dns-build-started`,`last-dns-build-finished`,`last-reverse-proxy-build-started`,`reverse-proxy-build`,`last-reverse-proxy-build-finished`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_contacttemplate`
--

DROP TABLE IF EXISTS `nagios_contacttemplate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_contacttemplate` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `template_name` varchar(255) NOT NULL,
  `alias` varchar(255) NOT NULL,
  `contactgroups` int(10) unsigned NOT NULL DEFAULT '0',
  `contactgroups_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `host_notifications_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `service_notifications_enabled` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `host_notification_period` int(11) NOT NULL DEFAULT '0',
  `service_notification_period` int(11) NOT NULL DEFAULT '0',
  `host_notification_options` varchar(20) NOT NULL,
  `service_notification_options` varchar(20) NOT NULL,
  `host_notification_commands` int(10) unsigned NOT NULL DEFAULT '0',
  `host_notification_commands_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `service_notification_commands` int(10) unsigned NOT NULL DEFAULT '0',
  `service_notification_commands_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `can_submit_commands` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_status_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `retain_nonstatus_information` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `email` varchar(255) DEFAULT NULL,
  `pager` varchar(255) DEFAULT NULL,
  `address1` varchar(255) DEFAULT NULL,
  `address2` varchar(255) DEFAULT NULL,
  `address3` varchar(255) DEFAULT NULL,
  `address4` varchar(255) DEFAULT NULL,
  `address5` varchar(255) DEFAULT NULL,
  `address6` varchar(255) DEFAULT NULL,
  `use_variables` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `use_template` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `use_template_tploptions` tinyint(3) unsigned NOT NULL DEFAULT '2',
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`template_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_domain`
--

DROP TABLE IF EXISTS `nagios_domain`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_domain` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `domain` varchar(255) NOT NULL,
  `alias` varchar(255) NOT NULL,
  `server` varchar(255) NOT NULL,
  `method` varchar(255) NOT NULL,
  `user` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `basedir` varchar(255) NOT NULL,
  `hostconfig` varchar(255) NOT NULL,
  `serviceconfig` varchar(255) NOT NULL,
  `backupdir` varchar(255) NOT NULL,
  `hostbackup` varchar(255) NOT NULL,
  `servicebackup` varchar(255) NOT NULL,
  `nagiosbasedir` varchar(255) NOT NULL,
  `importdir` varchar(255) NOT NULL,
  `commandfile` varchar(255) NOT NULL,
  `binaryfile` varchar(255) NOT NULL,
  `pidfile` varchar(255) NOT NULL,
  `version` tinyint(3) unsigned NOT NULL,
  `access_rights` varchar(255) NOT NULL,
  `active` enum('0','1') NOT NULL,
  `nodelete` enum('0','1') NOT NULL DEFAULT '0',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `domain` (`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_hostdependency`
--

DROP TABLE IF EXISTS `nagios_hostdependency`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_hostdependency` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `config_name` varchar(255) NOT NULL,
  `dependent_host_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `dependent_hostgroup_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `host_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `hostgroup_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `inherits_parent` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `execution_failure_criteria` varchar(20) DEFAULT '',
  `notification_failure_criteria` varchar(20) DEFAULT '',
  `dependency_period` int(11) NOT NULL DEFAULT '0',
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`config_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_hostescalation`
--

DROP TABLE IF EXISTS `nagios_hostescalation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_hostescalation` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `config_name` varchar(255) NOT NULL,
  `host_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `hostgroup_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contacts` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contact_groups` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `first_notification` int(11) DEFAULT NULL,
  `last_notification` int(11) DEFAULT NULL,
  `notification_interval` int(11) DEFAULT NULL,
  `escalation_period` int(11) NOT NULL DEFAULT '0',
  `escalation_options` varchar(20) DEFAULT '',
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`config_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_hostextinfo`
--

DROP TABLE IF EXISTS `nagios_hostextinfo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_hostextinfo` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `host_name` int(11) DEFAULT NULL,
  `notes` varchar(255) NOT NULL,
  `notes_url` varchar(255) NOT NULL,
  `action_url` varchar(255) NOT NULL,
  `statistik_url` varchar(255) NOT NULL,
  `icon_image` varchar(255) NOT NULL,
  `icon_image_alt` varchar(255) NOT NULL,
  `vrml_image` varchar(255) NOT NULL,
  `statusmap_image` varchar(255) NOT NULL,
  `2d_coords` varchar(255) NOT NULL,
  `3d_coords` varchar(255) NOT NULL,
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`host_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_info`
--

DROP TABLE IF EXISTS `nagios_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_info` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `key1` varchar(200) NOT NULL,
  `key2` varchar(200) NOT NULL,
  `version` varchar(50) NOT NULL,
  `language` varchar(50) NOT NULL,
  `infotext` text NOT NULL,
  PRIMARY KEY (`id`),
  KEY `keypair` (`key1`,`key2`,`version`,`language`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkContactToContactgroup`
--

DROP TABLE IF EXISTS `nagios_lnkContactToContactgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkContactToContactgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkContactToContacttemplate`
--

DROP TABLE IF EXISTS `nagios_lnkContactToContacttemplate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkContactToContacttemplate` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  `idSort` int(11) NOT NULL,
  `idTable` tinyint(4) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`,`idTable`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkContactToVariabledefinition`
--

DROP TABLE IF EXISTS `nagios_lnkContactToVariabledefinition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkContactToVariabledefinition` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkContactgroupToContact`
--

DROP TABLE IF EXISTS `nagios_lnkContactgroupToContact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkContactgroupToContact` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkContactgroupToContactgroup`
--

DROP TABLE IF EXISTS `nagios_lnkContactgroupToContactgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkContactgroupToContactgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkContacttemplateToCommandHost`
--

DROP TABLE IF EXISTS `nagios_lnkContacttemplateToCommandHost`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkContacttemplateToCommandHost` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkContacttemplateToCommandService`
--

DROP TABLE IF EXISTS `nagios_lnkContacttemplateToCommandService`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkContacttemplateToCommandService` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkContacttemplateToContactgroup`
--

DROP TABLE IF EXISTS `nagios_lnkContacttemplateToContactgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkContacttemplateToContactgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkContacttemplateToContacttemplate`
--

DROP TABLE IF EXISTS `nagios_lnkContacttemplateToContacttemplate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkContacttemplateToContacttemplate` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  `idSort` int(11) NOT NULL,
  `idTable` tinyint(4) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`,`idTable`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkContacttemplateToVariabledefinition`
--

DROP TABLE IF EXISTS `nagios_lnkContacttemplateToVariabledefinition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkContacttemplateToVariabledefinition` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostToContact`
--

DROP TABLE IF EXISTS `nagios_lnkHostToContact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostToContact` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostToVariabledefinition`
--

DROP TABLE IF EXISTS `nagios_lnkHostToVariabledefinition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostToVariabledefinition` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostdependencyToHost_DH`
--

DROP TABLE IF EXISTS `nagios_lnkHostdependencyToHost_DH`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostdependencyToHost_DH` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostdependencyToHost_H`
--

DROP TABLE IF EXISTS `nagios_lnkHostdependencyToHost_H`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostdependencyToHost_H` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostdependencyToHostgroup_DH`
--

DROP TABLE IF EXISTS `nagios_lnkHostdependencyToHostgroup_DH`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostdependencyToHostgroup_DH` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostdependencyToHostgroup_H`
--

DROP TABLE IF EXISTS `nagios_lnkHostdependencyToHostgroup_H`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostdependencyToHostgroup_H` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostescalationToContact`
--

DROP TABLE IF EXISTS `nagios_lnkHostescalationToContact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostescalationToContact` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostescalationToContactgroup`
--

DROP TABLE IF EXISTS `nagios_lnkHostescalationToContactgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostescalationToContactgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostescalationToHost`
--

DROP TABLE IF EXISTS `nagios_lnkHostescalationToHost`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostescalationToHost` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostescalationToHostgroup`
--

DROP TABLE IF EXISTS `nagios_lnkHostescalationToHostgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostescalationToHostgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostgroupToHost`
--

DROP TABLE IF EXISTS `nagios_lnkHostgroupToHost`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostgroupToHost` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHostgroupToHostgroup`
--

DROP TABLE IF EXISTS `nagios_lnkHostgroupToHostgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHostgroupToHostgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHosttemplateToContact`
--

DROP TABLE IF EXISTS `nagios_lnkHosttemplateToContact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHosttemplateToContact` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHosttemplateToHostgroup`
--

DROP TABLE IF EXISTS `nagios_lnkHosttemplateToHostgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHosttemplateToHostgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkHosttemplateToVariabledefinition`
--

DROP TABLE IF EXISTS `nagios_lnkHosttemplateToVariabledefinition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkHosttemplateToVariabledefinition` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServiceToHostgroup`
--

DROP TABLE IF EXISTS `nagios_lnkServiceToHostgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServiceToHostgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServiceToVariabledefinition`
--

DROP TABLE IF EXISTS `nagios_lnkServiceToVariabledefinition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServiceToVariabledefinition` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServicedependencyToHost_DH`
--

DROP TABLE IF EXISTS `nagios_lnkServicedependencyToHost_DH`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServicedependencyToHost_DH` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServicedependencyToHost_H`
--

DROP TABLE IF EXISTS `nagios_lnkServicedependencyToHost_H`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServicedependencyToHost_H` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServicedependencyToHostgroup_DH`
--

DROP TABLE IF EXISTS `nagios_lnkServicedependencyToHostgroup_DH`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServicedependencyToHostgroup_DH` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServicedependencyToHostgroup_H`
--

DROP TABLE IF EXISTS `nagios_lnkServicedependencyToHostgroup_H`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServicedependencyToHostgroup_H` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServicedependencyToService_DS`
--

DROP TABLE IF EXISTS `nagios_lnkServicedependencyToService_DS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServicedependencyToService_DS` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServicedependencyToService_S`
--

DROP TABLE IF EXISTS `nagios_lnkServicedependencyToService_S`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServicedependencyToService_S` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServiceescalationToContact`
--

DROP TABLE IF EXISTS `nagios_lnkServiceescalationToContact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServiceescalationToContact` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServiceescalationToContactgroup`
--

DROP TABLE IF EXISTS `nagios_lnkServiceescalationToContactgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServiceescalationToContactgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServiceescalationToHost`
--

DROP TABLE IF EXISTS `nagios_lnkServiceescalationToHost`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServiceescalationToHost` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServiceescalationToHostgroup`
--

DROP TABLE IF EXISTS `nagios_lnkServiceescalationToHostgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServiceescalationToHostgroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServiceescalationToService`
--

DROP TABLE IF EXISTS `nagios_lnkServiceescalationToService`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServiceescalationToService` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServicegroupToService`
--

DROP TABLE IF EXISTS `nagios_lnkServicegroupToService`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServicegroupToService` (
  `idMaster` int(11) NOT NULL,
  `idSlaveH` int(11) NOT NULL,
  `idSlaveHG` int(11) NOT NULL,
  `idSlaveS` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlaveH`,`idSlaveHG`,`idSlaveS`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServicegroupToServicegroup`
--

DROP TABLE IF EXISTS `nagios_lnkServicegroupToServicegroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServicegroupToServicegroup` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkServicetemplateToVariabledefinition`
--

DROP TABLE IF EXISTS `nagios_lnkServicetemplateToVariabledefinition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkServicetemplateToVariabledefinition` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_lnkTimeperiodToTimeperiod`
--

DROP TABLE IF EXISTS `nagios_lnkTimeperiodToTimeperiod`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_lnkTimeperiodToTimeperiod` (
  `idMaster` int(11) NOT NULL,
  `idSlave` int(11) NOT NULL,
  PRIMARY KEY (`idMaster`,`idSlave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_logbook`
--

DROP TABLE IF EXISTS `nagios_logbook`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_logbook` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `user` varchar(255) NOT NULL,
  `ipadress` varchar(255) NOT NULL,
  `domain` varchar(255) NOT NULL,
  `entry` tinytext CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_mainmenu`
--

DROP TABLE IF EXISTS `nagios_mainmenu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_mainmenu` (
  `id` tinyint(4) NOT NULL AUTO_INCREMENT,
  `order_id` tinyint(4) NOT NULL DEFAULT '0',
  `menu_id` tinyint(4) NOT NULL DEFAULT '0',
  `item` varchar(20) NOT NULL DEFAULT '',
  `link` varchar(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_servicedependency`
--

DROP TABLE IF EXISTS `nagios_servicedependency`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_servicedependency` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `config_name` varchar(255) NOT NULL,
  `dependent_host_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `dependent_hostgroup_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `dependent_service_description` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `host_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `hostgroup_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `service_description` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `inherits_parent` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `execution_failure_criteria` varchar(20) DEFAULT '',
  `notification_failure_criteria` varchar(20) DEFAULT '',
  `dependency_period` int(11) NOT NULL DEFAULT '0',
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`config_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_serviceescalation`
--

DROP TABLE IF EXISTS `nagios_serviceescalation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_serviceescalation` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `config_name` varchar(255) NOT NULL,
  `host_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `hostgroup_name` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `service_description` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contacts` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `contact_groups` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `first_notification` int(11) DEFAULT NULL,
  `last_notification` int(11) DEFAULT NULL,
  `notification_interval` int(11) DEFAULT NULL,
  `escalation_period` int(11) NOT NULL DEFAULT '0',
  `escalation_options` varchar(20) DEFAULT '',
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `config_name` (`config_name`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_serviceextinfo`
--

DROP TABLE IF EXISTS `nagios_serviceextinfo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_serviceextinfo` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `host_name` int(11) DEFAULT NULL,
  `service_description` int(11) NOT NULL,
  `notes` varchar(255) NOT NULL,
  `notes_url` varchar(255) NOT NULL,
  `action_url` varchar(255) NOT NULL,
  `statistic_url` varchar(255) NOT NULL,
  `icon_image` varchar(255) NOT NULL,
  `icon_image_alt` varchar(255) NOT NULL,
  `active` enum('0','1') NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `access_rights` varchar(8) DEFAULT NULL,
  `config_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_name` (`host_name`,`service_description`,`config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_settings`
--

DROP TABLE IF EXISTS `nagios_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_settings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `category` varchar(20) NOT NULL,
  `name` varchar(30) NOT NULL,
  `value` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_submenu`
--

DROP TABLE IF EXISTS `nagios_submenu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_submenu` (
  `id` tinyint(4) NOT NULL AUTO_INCREMENT,
  `id_main` tinyint(4) NOT NULL DEFAULT '0',
  `order_id` tinyint(4) NOT NULL DEFAULT '0',
  `item` varchar(20) NOT NULL DEFAULT '',
  `link` varchar(50) NOT NULL DEFAULT '',
  `access_rights` varchar(8) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_user`
--

DROP TABLE IF EXISTS `nagios_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_user` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(255) NOT NULL,
  `alias` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `access_rights` varchar(8) DEFAULT NULL,
  `wsauth` enum('0','1') NOT NULL DEFAULT '0',
  `active` enum('0','1') NOT NULL DEFAULT '0',
  `nodelete` enum('0','1') NOT NULL DEFAULT '0',
  `last_login` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_modified` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `locale` varchar(6) DEFAULT 'en_EN',
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nagios_variabledefinition`
--

DROP TABLE IF EXISTS `nagios_variabledefinition`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nagios_variabledefinition` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `value` varchar(255) NOT NULL,
  `last_modified` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notes`
--

DROP TABLE IF EXISTS `notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type_id` int(2) NOT NULL DEFAULT '0',
  `item_id` int(11) NOT NULL,
  `note` text NOT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `redirect`
--

DROP TABLE IF EXISTS `redirect`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `redirect` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_name` varchar(1024) NOT NULL,
  `port` int(5) NOT NULL DEFAULT '80',
  `redirect_source` text NOT NULL,
  `redirect_destination` text NOT NULL,
  `transfer_log` text,
  `error_log` text,
  `active` int(1) NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reverse_proxy`
--

DROP TABLE IF EXISTS `reverse_proxy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reverse_proxy` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `server_name` varchar(1024) NOT NULL,
  `proxy_pass_source` text NOT NULL,
  `proxy_pass_destination` text NOT NULL,
  `transfer_log` text,
  `error_log` text,
  `ssl_certificate_file` text,
  `ssl_certificate_key_file` text,
  `ssl_ca_certificate_file` text,
  `pfs` int(1) NOT NULL DEFAULT '0',
  `rc4` int(1) NOT NULL DEFAULT '0',
  `enforce_ssl` int(1) NOT NULL DEFAULT '0',
  `hsts` int(1) NOT NULL DEFAULT '0',
  `oscp_stapling` int(1) NOT NULL DEFAULT '0',
  `frame_options` int(1) NOT NULL DEFAULT '1',
  `xss_protection` int(1) NOT NULL DEFAULT '1',
  `content_type_options` int(1) NOT NULL DEFAULT '1',
  `content_security_policy` int(1) NOT NULL DEFAULT '1',
  `permitted_cross_domain_policies` int(1) NOT NULL DEFAULT '1',
  `powered_by` int(1) NOT NULL DEFAULT '1',
  `custom_attributes` text,
  `active` int(1) NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rules`
--

DROP TABLE IF EXISTS `rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `all_hosts` int(1) NOT NULL DEFAULT '0',
  `run_as` varchar(128) NOT NULL,
  `nopasswd` int(1) NOT NULL DEFAULT '0',
  `noexec` int(1) NOT NULL DEFAULT '1',
  `expires` date DEFAULT NULL,
  `active` int(1) NOT NULL DEFAULT '1',
  `approved` int(1) NOT NULL DEFAULT '0',
  `last_approved` datetime DEFAULT NULL,
  `approved_by` varchar(128) DEFAULT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `name_UNIQUE` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `service_dependency`
--

DROP TABLE IF EXISTS `service_dependency`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `service_dependency` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service_id` int(11) NOT NULL,
  `dependent_service_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `services`
--

DROP TABLE IF EXISTS `services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `services` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `service` varchar(255) DEFAULT NULL,
  `active` int(1) NOT NULL DEFAULT '1',
  `expires` date DEFAULT NULL,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_groups`
--

DROP TABLE IF EXISTS `user_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `groupname` varchar(128) NOT NULL,
  `system_group` int(1) NOT NULL DEFAULT '0',
  `expires` date DEFAULT NULL,
  `active` int(1) NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `groupname_UNIQUE` (`groupname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(128) NOT NULL,
  `expires` date DEFAULT NULL,
  `active` int(1) NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  UNIQUE KEY `username_UNIQUE` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `version`
--

DROP TABLE IF EXISTS `version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `version` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Latest_Version` varchar(64) DEFAULT NULL,
  `URL` varchar(255) DEFAULT NULL,
  `Notification` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `zone_records`
--

DROP TABLE IF EXISTS `zone_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `zone_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(128) NOT NULL,
  `domain` int(11) NOT NULL DEFAULT '1',
  `time_to_live` int(6) NOT NULL DEFAULT '86400',
  `type` varchar(5) NOT NULL DEFAULT 'A',
  `options` varchar(45) DEFAULT NULL,
  `target` varchar(128) NOT NULL,
  `zone` int(1) NOT NULL DEFAULT '0',
  `expires` date DEFAULT NULL,
  `active` int(1) NOT NULL DEFAULT '1',
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modified_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`,`source`,`target`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-02-03 21:04:46
