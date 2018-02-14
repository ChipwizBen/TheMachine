#!/usr/bin/perl

use strict;
use POSIX qw(strftime);
use Getopt::Long qw(:config no_auto_abbrev no_ignore_case_always);

my $Date = strftime "%Y-%m-%d", localtime;

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';}
if (-f '../common.pl') {$Common_Config = '../common.pl';}
if (-f '../HTTP/common.pl') {$Common_Config = '../HTTP/common.pl';}
if (-f '/opt/TheMachine/HTTP/common.pl') {$Common_Config = '/opt/TheMachine/HTTP/common.pl';}
require $Common_Config;

my $DB_Connection = DB_Connection();
my $System_Short_Name = System_Short_Name();
my $Version = Version();
$| = 1;
my $Green = "\e[0;32;10m";
my $Yellow = "\e[0;33;10m";
my $Red = "\e[0;31;10m";
my $Pink = "\e[1;35;10m";
my $Blue = "\e[1;34;10m";
my $Clear = "\e[0m";
my $Me = 'ldap-reset.pl';

my $Help = "
${Green}$System_Short_Name version $Version

Reset LDAP authentication by using the options below.

Options are:
	${Blue}--enable\t ${Green}Enable or disable LDAP. 1 to enable, 0 to disable.
	${Blue}--server\t ${Green}IP or hostname of the LDAP server.
	${Blue}--port\t\t ${Green}LDAP server port (Default is 389).
	${Blue}--timeout\t ${Green}LDAP response timeout (Default is 10 seconds).
	${Blue}--user-prefix\t ${Green}Prefix of the username to make up the DN (e.g. 'uid=').
	${Blue}--user-suffix\t ${Green}Suffix of the username to make up the DN (e.g. 'ou=People,dc=nwk1,dc=local').
	${Blue}--filter\t ${Green}LDAP user filter (e.g. 'uid=').
	${Blue}--search-base\t ${Green}LDAP search base (e.g. 'dc=nwk1,dc=local').


${Green}Example:
	${Green}## Add an 8 hour booking to Ben's annual leave total
	${Blue}$0 ---enable 1 --server ${Clear}\n\n";


if (!@ARGV) {
	print $Help;
	exit(0);
}

my ($LDAP_Enabled, $LDAP_Server, $LDAP_Port, $LDAP_Timeout, $LDAP_User_Name_Prefix, $LDAP_User_Name_Suffix, $LDAP_Filter, $LDAP_Search_Base);

GetOptions(
	'enable' => \$LDAP_Enabled,
	'server=s' => \$LDAP_Server,
	'port=s' => \$LDAP_Port,
	'timeout=i' => \$LDAP_Timeout,
	'user-prefix=s' => \$LDAP_User_Name_Prefix,
	'user-suffix=s' => \$LDAP_User_Name_Suffix,
	'filter=s' => \$LDAP_Filter,
	'search-base=s' => \$LDAP_Search_Base,

) or die("Fault with options: $@\n");

my $LDAP_Toggle;
if ($LDAP_Enabled) {
	$LDAP_Enabled = 1;
	$LDAP_Toggle = "${Green}LDAP on${Clear}";
}
else {
	$LDAP_Enabled = 0;
	$LDAP_Toggle = "${Red}LDAP off${Clear}";
}


print "
Setting the following:

Status:\t\t$LDAP_Toggle
Server:\t\t$LDAP_Server
Port:\t\t$LDAP_Port
Timeout:\t$LDAP_Timeout
UserPrefix:\t$LDAP_User_Name_Prefix
UserSuffix:\t$LDAP_User_Name_Suffix
Filter:\t\t$LDAP_Filter
SearchBase:\t$LDAP_Search_Base\n";

	# LDAP
	my $LDAP_Config = $DB_Connection->do("DELETE FROM `config_ldap` WHERE 1=1");
	$LDAP_Config = $DB_Connection->prepare("INSERT INTO `config_ldap` (
		`LDAP_Enabled`,
		`LDAP_Server`,
		`LDAP_Port`,
		`LDAP_Timeout`,
		`LDAP_User_Name_Prefix`,
		`LDAP_User_Name_Suffix`,
		`LDAP_Filter`,
		`LDAP_Search_Base`
	)
	VALUES (
		?, ?, ?, ?, ?, ?, ?, ?
	)");

	$LDAP_Config->execute($LDAP_Enabled, $LDAP_Server, $LDAP_Port, $LDAP_Timeout, $LDAP_User_Name_Prefix, $LDAP_User_Name_Suffix, $LDAP_Filter, $LDAP_Search_Base);
