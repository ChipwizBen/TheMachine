#!/usr/bin/perl

use strict;
use lib qw(/opt/TheMachine/Modules/);
use POSIX qw(strftime);

my $DIR = '/opt/TheMachine/HTTP';

require "$DIR/common.pl";

my $Date = strftime "%Y-%m-%d", localtime;
my $Common_Old = "$DIR/common.pl-upgrade-backup-$Date";


system("sed -i -e 's/sub /sub Old_/' $Common_Old");
system("sed -i -e 's/\&Maintenance_Mode;//' $Common_Old");
system("sed -i -e 's/use VMware/#use VMware/' $Common_Old");
system("sed -i -e 's/my \$CGI.*/my \$CGI;/' $Common_Old");
system("sed -i -e 's/use Sys::Hostname/#use Sys::Hostname/' $Common_Old");



require "$Common_Old";

my $DB_Connection = DB_Connection();

my $Recovery_Email_Address = Old_Recovery_Email_Address();
my $DNS_Server = Old_DNS_Server();
my $Verbose = Old_Verbose();
my ($Enforce_Password_Complexity_Requirements,
	$Password_Complexity_Minimum_Length,
	$Password_Complexity_Minimum_Upper_Case_Characters,
	$Password_Complexity_Minimum_Lower_Case_Characters,
	$Password_Complexity_Minimum_Digits,
	$Password_Complexity_Minimum_Special_Characters,
	$Password_Complexity_Accepted_Special_Characters) = Old_Password_Complexity_Check('Wn&sCvaG%!nvz}pb|#.pNzMe~I76fRx9m;a1|9wPYNQw4$u"w^]YA5WXr2b>bzyZzNKczDt~K5VHuDe~kX5mm=Ke:U5M9#g9PylHiSO$ob2-/Oc;=j#-KHuQj&#5fA,K_k$J\sSZup3<22MpK<>J|Ptp.r"h6');
my $md5sum = Old_md5sum();
my $cut = Old_cut();
my $visudo = Old_visudo();
my $cp = Old_cp();
my $ls = Old_ls();
my $sudo_grep = Old_sudo_grep();
my $head = Old_head();
my $nmap = Old_nmap();
my $ps = Old_ps();
my $wc = Old_wc();

my $Sudoers_Owner = Old_Sudoers_Owner_ID('Full');
my $Sudoers_Owner_ID = Old_Sudoers_Owner_ID();
my $Sudoers_Group = Old_Sudoers_Group_ID('Full');
my $Sudoers_Group_ID = Old_Sudoers_Group_ID();
my $Sudoers_Location = Old_Sudoers_Location();
my $Sudoers_Storage = Old_Sudoers_Storage();
my ($Distribution_SFTP_Port,
	$Distribution_User,
	$Key_Path,
	$Distribution_Timeout,
	$Remote_Sudoers) = Old_Distribution_Defaults();

my $DNS_Owner = Old_DNS_Owner_ID('Full');
my $DNS_Owner_ID = Old_DNS_Owner_ID();
my $DNS_Group = Old_DNS_Group_ID('Full');
my $DNS_Group_ID = Old_DNS_Group_ID();
my $Zone_Master_File = Old_DNS_Zone_Master_File();
my $DNS_Internal_Location = Old_DNS_Internal_Location();
my $DNS_External_Location = Old_DNS_External_Location();
my $DNS_Storage = Old_DNS_Storage();
my ($Internal_Email,
	$Internal_TTL,
	$Internal_Serial,
	$Internal_Refresh,
	$Internal_Retry,
	$Internal_Expire,
	$Internal_Minimum,
	$Internal_NS1,
	$Internal_NS2,
	$Internal_NS3) = Old_DNS_Internal_SOA('Parameters');
my ($External_Email,
	$External_TTL,
	$External_Serial,
	$External_Refresh,
	$External_Retry,
	$External_Expire,
	$External_Minimum,
	$External_NS1,
	$External_NS2,
	$External_NS3) = Old_DNS_External_SOA('Parameters');

my $Reverse_Proxy_Location = Old_Reverse_Proxy_Location();
my $Proxy_Redirect_Location = Old_Proxy_Redirect_Location();
my $Reverse_Proxy_Storage = Old_Reverse_Proxy_Storage();
my $Proxy_Redirect_Storage = Old_Proxy_Redirect_Storage();
my ($Reverse_Proxy_Transfer_Log_Path,
	$Reverse_Proxy_Error_Log_Path,
	$Reverse_Proxy_SSL_Certificate_File,
	$Reverse_Proxy_SSL_Certificate_Key_File,
	$Reverse_Proxy_SSL_CA_Certificate_File) = Old_Reverse_Proxy_Defaults();
my ($Proxy_Redirect_Transfer_Log_Path,
	$Proxy_Redirect_Error_Log_Path) = Old_Redirect_Defaults();

my $LDAP_Enabled = Old_LDAP_Login('Status_Check');
my ($LDAP_Server,
	$LDAP_Port,
	$LDAP_Timeout,
	$LDAP_User_Name_Prefix,
	$LDAP_Filter,
	$LDAP_Search_Base) = Old_LDAP_Login('Parameters');

my $DShell_WaitFor_Timeout = Old_DShell_WaitFor_Timeout();
my $DShell_Queue_Execution_Cap = Old_DShell_Queue_Execution_Cap();

my $Use_Git = Old_Git_Link('Status_Check');
	my $Git_Directory = Old_Git_Link('Directory');
	my $Git_Redirect = Old_Git_Locations('Redirect');
		$Git_Redirect =~ s/$Git_Directory\///;
	my $Git_ReverseProxy = Old_Git_Locations('ReverseProxy');
		$Git_ReverseProxy =~ s/$Git_Directory\///;
	my $Git_CommandSets = Old_Git_Locations('CommandSets');
		$Git_CommandSets =~ s/$Git_Directory\///;
	my $Git_DSMS = Old_Git_Locations('DSMS');
		$Git_DSMS =~ s/$Git_Directory\///;

my ($vSphere_Server, $vSphere_Username, $vSphere_Password) = Old_VMware_Connection();


my $Audit_Log_Submission = Audit_Log_Submission();
$Audit_Log_Submission->execute("Configuration", "Add", "The system configuration has been imported from common.pl to the database by the update process.", 'System');

# System
print "Migrating System configuration to DB...\n";
my $System_Config = $DB_Connection->do("DELETE FROM `config_system` WHERE 1=1");
$System_Config = $DB_Connection->prepare("INSERT INTO `config_system` (
	`Recovery_Email_Address`,
	`DNS_Server`,
	`Verbose`,
	`md5sum`,
	`cut`,
	`visudo`,
	`cp`,
	`ls`,
	`sudo_grep`,
	`head`,
	`nmap`,
	`ps`,
	`wc`,
	`Enforce_Password_Complexity_Requirements`,
	`Password_Complexity_Minimum_Length`,
	`Password_Complexity_Minimum_Upper_Case_Characters`,
	`Password_Complexity_Minimum_Lower_Case_Characters`,
	`Password_Complexity_Minimum_Digits`,
	`Password_Complexity_Minimum_Special_Characters`,
	`Password_Complexity_Accepted_Special_Characters`
)
VALUES (
	?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
	?, ?, ?,
	?, ?,
	?, ?
)");

$System_Config->execute($Recovery_Email_Address, $DNS_Server, $Verbose, $md5sum, $cut, $visudo, $cp, $ls, $sudo_grep, $head, $nmap, $ps, $wc,
$Enforce_Password_Complexity_Requirements, $Password_Complexity_Minimum_Length, $Password_Complexity_Minimum_Upper_Case_Characters,
$Password_Complexity_Minimum_Lower_Case_Characters, $Password_Complexity_Minimum_Digits,
$Password_Complexity_Minimum_Special_Characters, $Password_Complexity_Accepted_Special_Characters);


# DSMS
print "Migrating Sudo configuration to DB...\n";
my $DSMS_Config = $DB_Connection->do("DELETE FROM `config_sudoers` WHERE 1=1");
$DSMS_Config = $DB_Connection->prepare("INSERT INTO `config_sudoers` (
	`Sudoers_Owner`,
	`Sudoers_Group`,
	`Sudoers_Location`,
	`Sudoers_Storage`,
	`Distribution_SFTP_Port`,
	`Distribution_User`,
	`Key_Path`,
	`Distribution_Timeout`,
	`Remote_Sudoers`
)
VALUES (
	?, ?, ?, ?, ?,
	?, ?, ?, ?
)");

$DSMS_Config->execute($Sudoers_Owner, $Sudoers_Group, $Sudoers_Location, $Sudoers_Storage, $Distribution_SFTP_Port,
$Distribution_User, $Key_Path, $Distribution_Timeout, $Remote_Sudoers);


# DNS
print "Migrating DNS configuration to DB...\n";
my $DNS_Config = $DB_Connection->do("DELETE FROM `config_dns` WHERE 1=1");
$DNS_Config = $DB_Connection->prepare("INSERT INTO `config_dns` (
	`DNS_Owner`,
	`DNS_Group`,
	`Zone_Master_File`,
	`DNS_Storage`,
	`DNS_Internal_Location`,
	`Internal_Email`,
	`Internal_TTL`,
	`Internal_Refresh`,
	`Internal_Retry`,
	`Internal_Expire`,
	`Internal_Minimum`,
	`Internal_NS1`,
	`Internal_NS2`,
	`Internal_NS3`,
	`DNS_External_Location`,
	`External_Email`,
	`External_TTL`,
	`External_Refresh`,
	`External_Retry`,
	`External_Expire`,
	`External_Minimum`,
	`External_NS1`,
	`External_NS2`,
	`External_NS3`
)
VALUES (
	?, ?, ?, ?, ?, ?, ?,
	?, ?, ?, ?, ?, ?, ?, ?,
	?, ?, ?, ?, ?, ?, ?, ?,
	?
)");

$DNS_Config->execute($DNS_Owner, $DNS_Group, $Zone_Master_File, $DNS_Storage, $DNS_Internal_Location, $Internal_Email, $Internal_TTL, 
$Internal_Refresh, $Internal_Retry, $Internal_Expire, $Internal_Minimum, $Internal_NS1, $Internal_NS2, $Internal_NS3, $DNS_External_Location, 
$External_Email, $External_TTL, $External_Refresh, $External_Retry, $External_Expire, $External_Minimum, $External_NS1, $External_NS2, 
$External_NS3);


# Reverse Proxy
print "Migrating Reverse Proxy configuration to DB...\n";
my $RP_Config = $DB_Connection->do("DELETE FROM `config_reverse_proxy` WHERE 1=1");
$RP_Config = $DB_Connection->prepare("INSERT INTO `config_reverse_proxy` (
	`Reverse_Proxy_Location`,
	`Proxy_Redirect_Location`,
	`Reverse_Proxy_Storage`,
	`Proxy_Redirect_Storage`,
	`Reverse_Proxy_Transfer_Log_Path`,
	`Reverse_Proxy_Error_Log_Path`,
	`Proxy_Redirect_Transfer_Log_Path`,
	`Proxy_Redirect_Error_Log_Path`,
	`Reverse_Proxy_SSL_Certificate_File`,
	`Reverse_Proxy_SSL_Certificate_Key_File`,
	`Reverse_Proxy_SSL_CA_Certificate_File`
)
VALUES (
	?, ?, ?, ?,
	?, ?, ?, ?,
	?, ?, ?
)");

$RP_Config->execute($Reverse_Proxy_Location, $Proxy_Redirect_Location, $Reverse_Proxy_Storage, $Proxy_Redirect_Storage,
$Reverse_Proxy_Transfer_Log_Path, $Reverse_Proxy_Error_Log_Path, $Proxy_Redirect_Transfer_Log_Path, $Proxy_Redirect_Error_Log_Path,
$Reverse_Proxy_SSL_Certificate_File, $Reverse_Proxy_SSL_Certificate_Key_File, $Reverse_Proxy_SSL_CA_Certificate_File);


# LDAP
print "Migrating LDAP configuration to DB...\n";
my $LDAP_Config = $DB_Connection->do("DELETE FROM `config_ldap` WHERE 1=1");
$LDAP_Config = $DB_Connection->prepare("INSERT INTO `config_ldap` (
	`LDAP_Enabled`,
	`LDAP_Server`,
	`LDAP_Port`,
	`LDAP_Timeout`,
	`LDAP_User_Name_Prefix`,
	`LDAP_Filter`,
	`LDAP_Search_Base`
)
VALUES (
	?, ?, ?, ?, ?, ?, ?
)");

$LDAP_Config->execute($LDAP_Enabled, $LDAP_Server, $LDAP_Port, $LDAP_Timeout, $LDAP_User_Name_Prefix, $LDAP_Filter, $LDAP_Search_Base);


# Git
print "Migrating Git configuration to DB...\n";
my $Git_Config = $DB_Connection->do("DELETE FROM `config_git` WHERE 1=1");
$Git_Config = $DB_Connection->prepare("INSERT INTO `config_git` (
	`Use_Git`,
	`Git_Directory`,
	`Git_Redirect`,
	`Git_ReverseProxy`,
	`Git_CommandSets`,
	`Git_DSMS`
)
VALUES (
	?, ?, ?, ?, ?, ?
)");

$Git_Config->execute($Use_Git, $Git_Directory, $Git_Redirect, $Git_ReverseProxy, $Git_CommandSets, $Git_DSMS);


# VMWare
print "Migrating VMware configuration to DB...\n";
if ($vSphere_Password) {
	my $VMWare_Config = $DB_Connection->do("DELETE FROM `config_vmware` WHERE 1=1");
	$VMWare_Config = $DB_Connection->prepare("INSERT INTO `config_vmware` (
		`vSphere_Server`,
		`vSphere_Username`,
		`vSphere_Password`
	)
	VALUES (
		?, ?, ?
	)");

	$VMWare_Config->execute($vSphere_Server, $vSphere_Username, $vSphere_Password);
}


# D-Shell
print "Migrating D-Shell configuration to DB...\n";
my $DShell_Config = $DB_Connection->do("DELETE FROM `config_dshell` WHERE 1=1");
$DShell_Config = $DB_Connection->prepare("INSERT INTO `config_dshell` (
	`DShell_WaitFor_Timeout`,
	`DShell_Queue_Execution_Cap`
)
VALUES (
	?, ?
)");

$DShell_Config->execute($DShell_WaitFor_Timeout, $DShell_Queue_Execution_Cap);

