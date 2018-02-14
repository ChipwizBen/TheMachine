#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);

require './common.pl';
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();
my $Header = Header();
my $Footer = Footer();
my $System_Name = System_Name();

my $Me = 'configuration.cgi';

my $User_Name = $Session->param("User_Name");
my $User_Admin = $Session->param("User_Admin");

# System
my $Recovery_Email_Address = $CGI->param("Recovery_Email_Address");
my $DNS_Server = $CGI->param("DNS_Server");
my $Verbose = $CGI->param("Verbose");
my $md5sum = $CGI->param("md5sum");
my $cut = $CGI->param("cut");
my $visudo = $CGI->param("visudo");
my $cp = $CGI->param("cp");
my $ls = $CGI->param("ls");
my $sudo_grep = $CGI->param("sudo_grep");
my $head = $CGI->param("head");
my $nmap = $CGI->param("nmap");
my $ps = $CGI->param("ps");
my $wc = $CGI->param("wc");
my $Enforce_Password_Complexity_Requirements = $CGI->param("Enforce_Password_Complexity_Requirements");
my $Password_Complexity_Minimum_Length = $CGI->param("Password_Complexity_Minimum_Length");
my $Password_Complexity_Minimum_Upper_Case_Characters = $CGI->param("Password_Complexity_Minimum_Upper_Case_Characters");
my $Password_Complexity_Minimum_Lower_Case_Characters = $CGI->param("Password_Complexity_Minimum_Lower_Case_Characters");
my $Password_Complexity_Minimum_Digits = $CGI->param("Password_Complexity_Minimum_Digits");
my $Password_Complexity_Minimum_Special_Characters = $CGI->param("Password_Complexity_Minimum_Special_Characters");
my $Password_Complexity_Accepted_Special_Characters = $CGI->param("Password_Complexity_Accepted_Special_Characters");

# DSMS
my $Sudoers_Owner = $CGI->param("Sudoers_Owner");
my $Sudoers_Group = $CGI->param("Sudoers_Group");
my $Sudoers_Location = $CGI->param("Sudoers_Location");
my $Sudoers_Storage = $CGI->param("Sudoers_Storage");
my $Distribution_SFTP_Port = $CGI->param("Distribution_SFTP_Port");
my $Distribution_User = $CGI->param("Distribution_User");
my $Key_Path = $CGI->param("Key_Path");
my $Distribution_Timeout = $CGI->param("Distribution_Timeout");
my $Remote_Sudoers = $CGI->param("Remote_Sudoers");

# DNS
my $DNS_Owner = $CGI->param("DNS_Owner");
my $DNS_Group = $CGI->param("DNS_Group");
my $Zone_Master_File = $CGI->param("Zone_Master_File");
my $DNS_Storage = $CGI->param("DNS_Storage");

my $DNS_Internal_Location = $CGI->param("DNS_Internal_Location");
my $Internal_Email = $CGI->param("Internal_Email");
my $Internal_TTL = $CGI->param("Internal_TTL");
my $Internal_Refresh = $CGI->param("Internal_Refresh");
my $Internal_Retry = $CGI->param("Internal_Retry");
my $Internal_Expire = $CGI->param("Internal_Expire");
my $Internal_Minimum = $CGI->param("Internal_Minimum");
my $Internal_NS1 = $CGI->param("Internal_NS1");
my $Internal_NS2 = $CGI->param("Internal_NS2");
my $Internal_NS3 = $CGI->param("Internal_NS3");

my $DNS_External_Location = $CGI->param("DNS_External_Location");
my $External_Email = $CGI->param("External_Email");
my $External_TTL = $CGI->param("External_TTL");
my $External_Refresh = $CGI->param("External_Refresh");
my $External_Retry = $CGI->param("External_Retry");
my $External_Expire = $CGI->param("External_Expire");
my $External_Minimum = $CGI->param("External_Minimum");
my $External_NS1 = $CGI->param("External_NS1");
my $External_NS2 = $CGI->param("External_NS2");
my $External_NS3 = $CGI->param("External_NS3");

# Reverse Proxy
my $Reverse_Proxy_Location = $CGI->param("Reverse_Proxy_Location");
my $Proxy_Redirect_Location = $CGI->param("Proxy_Redirect_Location");
my $Reverse_Proxy_Storage = $CGI->param("Reverse_Proxy_Storage");
my $Proxy_Redirect_Storage = $CGI->param("Proxy_Redirect_Storage");
my $Reverse_Proxy_Transfer_Log_Path = $CGI->param("Reverse_Proxy_Transfer_Log_Path");
my $Reverse_Proxy_Error_Log_Path = $CGI->param("Reverse_Proxy_Error_Log_Path");
my $Proxy_Redirect_Transfer_Log_Path = $CGI->param("Proxy_Redirect_Transfer_Log_Path");
my $Proxy_Redirect_Error_Log_Path = $CGI->param("Proxy_Redirect_Error_Log_Path");
my $Reverse_Proxy_SSL_Certificate_File = $CGI->param("Reverse_Proxy_SSL_Certificate_File");
my $Reverse_Proxy_SSL_Certificate_Key_File = $CGI->param("Reverse_Proxy_SSL_Certificate_Key_File");
my $Reverse_Proxy_SSL_CA_Certificate_File = $CGI->param("Reverse_Proxy_SSL_CA_Certificate_File");

# LDAP
my $LDAP_Enabled = $CGI->param("LDAP_Enabled");
my $LDAP_Server = $CGI->param("LDAP_Server");
my $LDAP_Port = $CGI->param("LDAP_Port");
my $LDAP_Timeout = $CGI->param("LDAP_Timeout");
my $LDAP_User_Name_Prefix = $CGI->param("LDAP_User_Name_Prefix");
my $LDAP_User_Name_Suffix = $CGI->param("LDAP_User_Name_Suffix");
my $LDAP_Filter = $CGI->param("LDAP_Filter");
my $LDAP_Search_Base = $CGI->param("LDAP_Search_Base");

# Git
my $Use_Git = $CGI->param("Use_Git");
my $Git_Directory = $CGI->param("Git_Directory");
my $Git_Redirect = $CGI->param("Git_Redirect");
my $Git_ReverseProxy = $CGI->param("Git_ReverseProxy");
my $Git_CommandSets = $CGI->param("Git_CommandSets");
my $Git_DSMS = $CGI->param("Git_DSMS");

# VMware API
my $vSphere_Server = $CGI->param("vSphere_Server");
my $vSphere_Username = $CGI->param("vSphere_Username");
my $vSphere_Password = $CGI->param("vSphere_Password");

# Proxmox API
my $Proxmox_Server = $CGI->param("Proxmox_Server");
my $Proxmox_Server_Port = $CGI->param("Proxmox_Server_Port");
my $Proxmox_Username = $CGI->param("Proxmox_Username");
my $Proxmox_Password = $CGI->param("Proxmox_Password");

# D-Shell
my $DShell_WaitFor_Timeout = $CGI->param("DShell_WaitFor_Timeout");
my $DShell_Queue_Execution_Cap = $CGI->param("DShell_Queue_Execution_Cap");


if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

if ($User_Admin != 1 && $User_Admin != 2) {
	my $Message_Red = 'You do not have sufficient privileges to access that page.';
	$Session->param('Message_Red', $Message_Red);
	$Session->flush();
	print "Location: /index.cgi\n\n";
	exit(0);
}


if (defined $Enforce_Password_Complexity_Requirements) {&write_configuration}


require $Header;
&html_output;
require $Footer;

sub html_output {

	my $Referer = $ENV{HTTP_REFERER};

	if ($Referer !~ /$Me/) {
		my $Audit_Log_Submission = Audit_Log_Submission();
	
		$Audit_Log_Submission->execute("Configuration", "View", "$User_Name accessed Configuration.", $User_Name);
	}

print <<ENDHTML;
<form action='$Me' method='post'>
<div id='full-page-block'>
<h2 style='text-align: center;'>System Configuration</h2>
<p align='center'><input type=submit name='ok' value='Write All Config'></p>
	<div id='blockrow1'>
		<div id='blocka1'>
ENDHTML
			&html_dsms_configuration;
			&html_dns_configuration;
			&html_dshell_configuration;
print <<ENDHTML;
		</div> <!-- blocka1 -->

		<div id='blocka2'>
ENDHTML
			&html_system_configuration;
			&html_git_configuration;
			&html_vmware_configuration;
			
print <<ENDHTML;
		</div> <!-- blocka2 -->

		<div id='blocka3'>
ENDHTML
			&html_ldap_configuration;
			&html_reverse_proxy_configuration;
			&html_proxmox_configuration;
print <<ENDHTML;
		</div> <!-- blocka3 -->
	</div> <!-- blockrow1 -->
	<div id='blockrow2'>
		<div id='blockb1'>
ENDHTML
			
print <<ENDHTML;
		</div> <!-- blockb1 -->
		<div id='blockb2'>
ENDHTML
			
print <<ENDHTML;
		</div> <!-- blockb2 -->
		<div id='blockb3'>
ENDHTML
			
print <<ENDHTML;
		</div> <!-- blockb3 -->
</div> <!-- full-page-block -->
</form>
ENDHTML


} #sub html_output

sub html_system_configuration {

my $Recovery_Email_Address = Recovery_Email_Address();
my $DNS_Server = DNS_Server();
my $Verbose = Verbose();
	my ($Verbose_Yes, $Verbose_No);
	if ($Verbose) {$Verbose_Yes = 'checked'} else {$Verbose_No = 'checked'}
my ($Enforce_Complexity_Requirements,
	$Minimum_Length,
	$Minimum_Upper_Case_Characters,
	$Minimum_Lower_Case_Characters,
	$Minimum_Digits,
	$Minimum_Special_Characters,
	$Special_Characters) = Password_Complexity_Check('Wn&sCvaG%!nvz}pb|#.pNzMe~I76fRx9m;a1|9wPYNQw4$u"w^]YA5WXr2b>bzyZzNKczDt~K5VHuDe~kX5mm=Ke:U5M9#g9PylHiSO$ob2-/Oc;=j#-KHuQj&#5fA,K_k$J\sSZup3<22MpK<>J|Ptp.r"h6');
	my ($Enforce_Complexity_Requirements_Yes, $Enforce_Complexity_Requirements_No);
	if ($Enforce_Complexity_Requirements) {$Enforce_Complexity_Requirements_Yes = 'checked'} else {$Enforce_Complexity_Requirements_No = 'checked'}
my $md5sum = md5sum();
my $cut = cut();
my $visudo = visudo();
my $cp = cp();
my $ls = ls();
my $sudo_grep = sudo_grep();
my $head = head();
my $nmap = nmap();
my $ps = ps();
my $wc = wc();

print <<ENDHTML;
<details>
<summary style="text-align: center; font-weight: bold; font-size: 1.5em;">Global Configuration</summary>
	<table align='center'>
		<tr>
			<td style="text-align: right;">Recovery Email Address:</td>
			<td style="text-align: left;"><input type='email' name='Recovery_Email_Address' maxlength='255' value="$Recovery_Email_Address" placeholder="$Recovery_Email_Address"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Failback DNS Server:</td>
			<td style="text-align: left;"><input type='text' name='DNS_Server' maxlength='15' value="$DNS_Server" placeholder="$DNS_Server"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Verbose Logging:</td>
			<td style="text-align: left;"><input type="radio" name="Verbose" value="0" $Verbose_No>No <input type="radio" name="Verbose" value="1" $Verbose_Yes>Yes</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Enforce Password Complexity Requirements:</td>
			<td style="text-align: left;"><input type="radio" name="Enforce_Password_Complexity_Requirements" value="0" $Enforce_Complexity_Requirements_No>No <input type="radio" name="Enforce_Password_Complexity_Requirements" value="1" $Enforce_Complexity_Requirements_Yes>Yes</td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Minimum Length:</td>
			<td style="text-align: left;"><input type='number' name='Password_Complexity_Minimum_Length' maxlength='3' value="$Minimum_Length" placeholder="$Minimum_Length"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Upper Case Characters:</td>
			<td style="text-align: left;"><input type='number' name='Password_Complexity_Minimum_Upper_Case_Characters' maxlength='3' value="$Minimum_Upper_Case_Characters" placeholder="$Minimum_Upper_Case_Characters"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Lower Case Characters:</td>
			<td style="text-align: left;"><input type='number' name='Password_Complexity_Minimum_Lower_Case_Characters' maxlength='3' value="$Minimum_Lower_Case_Characters" placeholder="$Minimum_Lower_Case_Characters"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Minimum Digits:</td>
			<td style="text-align: left;"><input type='number' name='Password_Complexity_Minimum_Digits' maxlength='3' value="$Minimum_Digits" placeholder="$Minimum_Digits"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Minimum Special_Characters:</td>
			<td style="text-align: left;"><input type='number' name='Password_Complexity_Minimum_Special_Characters' maxlength='3' value="$Minimum_Special_Characters" placeholder="$Minimum_Special_Characters"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Accepted Special Characters:</td>
			<td style="text-align: left;"><input type='text' name='Password_Complexity_Accepted_Special_Characters' maxlength='255' value="$Special_Characters" placeholder="$Special_Characters"></td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">md5sum Location:</td>
			<td style="text-align: left;"><input type='text' name='md5sum' maxlength='255' value="$md5sum" placeholder="$md5sum"></td>
		</tr>
		<tr>
			<td style="text-align: right;">cut Location:</td>
			<td style="text-align: left;"><input type='text' name='cut' maxlength='255' value="$cut" placeholder="$cut"></td>
		</tr>
		<tr>
			<td style="text-align: right;">visudo Location:</td>
			<td style="text-align: left;"><input type='text' name='visudo' maxlength='255' value="$visudo" placeholder="$visudo"></td>
		</tr>
		<tr>
			<td style="text-align: right;">cp Location:</td>
			<td style="text-align: left;"><input type='text' name='cp' maxlength='255' value="$cp" placeholder="$cp"></td>
		</tr>
		<tr>
			<td style="text-align: right;">ls Location:</td>
			<td style="text-align: left;"><input type='text' name='ls' maxlength='255' value="$ls" placeholder="$ls"></td>
		</tr>
		<tr>
			<td style="text-align: right;">grep Location:</td>
			<td style="text-align: left;"><input type='text' name='sudo_grep' maxlength='255' value="$sudo_grep" placeholder="$sudo_grep"></td>
		</tr>
		<tr>
			<td style="text-align: right;">head Location:</td>
			<td style="text-align: left;"><input type='text' name='head' maxlength='255' value="$head" placeholder="$head"></td>
		</tr>
		<tr>
			<td style="text-align: right;">nmap Location:</td>
			<td style="text-align: left;"><input type='text' name='nmap' maxlength='255' value="$nmap" placeholder="$nmap"></td>
		</tr>
		<tr>
			<td style="text-align: right;">ps Location:</td>
			<td style="text-align: left;"><input type='text' name='ps' maxlength='255' value="$ps" placeholder="$ps"></td>
		</tr>
		<tr>
			<td style="text-align: right;">wc Location:</td>
			<td style="text-align: left;"><input type='text' name='wc' maxlength='255' value="$wc" placeholder="$wc"></td>
		</tr>
	</table>
	</details>
ENDHTML
} # sub html_system_configuration

sub html_dsms_configuration {

my $Sudoers_Owner = Sudoers_Owner_ID('Full');
my $Sudoers_Owner_ID = Sudoers_Owner_ID();
my $Sudoers_Group = Sudoers_Group_ID('Full');
my $Sudoers_Group_ID = Sudoers_Group_ID();
my $Sudoers_Location = Sudoers_Location();
my $Sudoers_Storage = Sudoers_Storage();
my ($Distribution_SFTP_Port,
	$Distribution_User,
	$Key_Path,
	$Timeout,
	$Remote_Sudoers) = Distribution_Defaults();

print <<ENDHTML;
	<details>
	<summary style="text-align: center; font-weight: bold; font-size: 1.5em;">Sudoers Configuration</summary>
	<table align='center'>
		<tr>
			<td style="text-align: right;">Sudoers Build File Ownership:</td>
			<td style="text-align: left;"><input type='text' name='Sudoers_Owner' maxlength='255' value="$Sudoers_Owner" placeholder="$Sudoers_Owner"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Sudoers Build File Group Ownership:</td>
			<td style="text-align: left;"><input type='text' name='Sudoers_Group' maxlength='255' value="$Sudoers_Group" placeholder="$Sudoers_Group"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Sudoers Build File Location:</td>
			<td style="text-align: left;"><input type='text' name='Sudoers_Location' maxlength='255' value="$Sudoers_Location" placeholder="$Sudoers_Location"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Archived Sudoers Storage Directory Location:</td>
			<td style="text-align: left;"><input type='text' name='Sudoers_Storage' maxlength='255' value="$Sudoers_Storage" placeholder="$Sudoers_Storage"></td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default SFTP Distribution Port:</td>
			<td style="text-align: left;"><input type='number' name='Distribution_SFTP_Port' maxlength='5' value="$Distribution_SFTP_Port" placeholder="$Distribution_SFTP_Port"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Default SFTP Distribution User:</td>
			<td style="text-align: left;"><input type='text' name='Distribution_User' maxlength='255' value="$Distribution_User" placeholder="$Distribution_User"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Default SFTP Distribution Key Path:</td>
			<td style="text-align: left;"><input type='text' name='Key_Path' maxlength='255' value="$Key_Path" placeholder="$Key_Path"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Default SFTP Distribution Timeout (seconds):</td>
			<td style="text-align: left;"><input type='number' name='Distribution_Timeout' maxlength='5' value="$Timeout" placeholder="$Timeout"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Remote Sudoers Drop Location:</td>
			<td style="text-align: left;"><input type='text' name='Remote_Sudoers' maxlength='255' value="$Remote_Sudoers" placeholder="$Remote_Sudoers"></td>
		</tr>
	</table>
	</details>
ENDHTML

} # sub html_dsms_configuration

sub html_dns_configuration {

my $DNS_Owner = DNS_Owner_ID('Full');
my $DNS_Owner_ID = DNS_Owner_ID();
my $DNS_Group = DNS_Group_ID('Full');
my $DNS_Group_ID = DNS_Group_ID();
my $Zone_Master_File = DNS_Zone_Master_File();
my $DNS_Internal_Location = DNS_Internal_Location();
my $DNS_External_Location = DNS_External_Location();
my $DNS_Storage = DNS_Storage();
my ($Internal_Email,
	$Internal_TTL,
	$Internal_Serial,
	$Internal_Refresh,
	$Internal_Retry,
	$Internal_Expire,
	$Internal_Minimum,
	$Internal_NS1,
	$Internal_NS2,
	$Internal_NS3) = DNS_Internal_SOA('Parameters');
my ($External_Email,
	$External_TTL,
	$External_Serial,
	$External_Refresh,
	$External_Retry,
	$External_Expire,
	$External_Minimum,
	$External_NS1,
	$External_NS2,
	$External_NS3) = DNS_External_SOA('Parameters');

print <<ENDHTML;
<details>
<summary style="text-align: center; font-weight: bold; font-size: 1.5em;">DNS Configuration</summary>
	<table align='center'>
		<tr>
			<td style="text-align: right;">DNS Build File Ownership:</td>
			<td style="text-align: left;"><input type='text' name='DNS_Owner' maxlength='255' value="$DNS_Owner" placeholder="$DNS_Owner"></td>
		</tr>
		<tr>
			<td style="text-align: right;">DNS Build File Group Ownership:</td>
			<td style="text-align: left;"><input type='text' name='DNS_Group' maxlength='255' value="$DNS_Group" placeholder="$DNS_Group"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Zone Master File Location:</td>
			<td style="text-align: left;"><input type='text' name='Zone_Master_File' maxlength='255' value="$Zone_Master_File" placeholder="$Zone_Master_File"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Archived DNS File Storage Location:</td>
			<td style="text-align: left;"><input type='text' name='DNS_Storage' maxlength='255' value="$DNS_Storage" placeholder="$DNS_Storage"></td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal Config File Location:</td>
			<td style="text-align: left;"><input type='text' name='DNS_Internal_Location' maxlength='255' value="$DNS_Internal_Location" placeholder="$DNS_Internal_Location"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA Email:</td>
			<td style="text-align: left;"><input type='email' name='Internal_Email' maxlength='255' value="$Internal_Email" placeholder="$Internal_Email"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA TTL:</td>
			<td style="text-align: left;"><input type='number' name='Internal_TTL' maxlength='16' value="$Internal_TTL" placeholder="$Internal_TTL"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA Refresh:</td>
			<td style="text-align: left;"><input type='number' name='Internal_Refresh' maxlength='16' value="$Internal_Refresh" placeholder="$Internal_Refresh"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA Retry:</td>
			<td style="text-align: left;"><input type='number' name='Internal_Retry' maxlength='16' value="$Internal_Retry" placeholder="$Internal_Retry"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA Expire:</td>
			<td style="text-align: left;"><input type='number' name='Internal_Expire' maxlength='16' value="$Internal_Expire" placeholder="$Internal_Expire"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA Minimum:</td>
			<td style="text-align: left;"><input type='number' name='Internal_Minimum' maxlength='16' value="$Internal_Minimum" placeholder="$Internal_Minimum"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA NS1:</td>
			<td style="text-align: left;"><input type='text' name='Internal_NS1' maxlength='255' value="$Internal_NS1" placeholder="$Internal_NS1"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA NS2:</td>
			<td style="text-align: left;"><input type='text' name='Internal_NS2' maxlength='255' value="$Internal_NS2" placeholder="$Internal_NS2"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA NS3:</td>
			<td style="text-align: left;"><input type='text' name='Internal_NS3' maxlength='255' value="$Internal_NS3" placeholder="$Internal_NS3"></td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">External Config File Location:</td>
			<td style="text-align: left;"><input type='text' name='DNS_External_Location' maxlength='255' value="$DNS_External_Location" placeholder="$DNS_External_Location"></td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA Email:</td>
			<td style="text-align: left;"><input type='email' name='External_Email' maxlength='255' value="$External_Email" placeholder="$External_Email"></td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA TTL:</td>
			<td style="text-align: left;"><input type='number' name='External_TTL' maxlength='16' value="$External_TTL" placeholder="$External_TTL"></td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA Refresh:</td>
			<td style="text-align: left;"><input type='number' name='External_Refresh' maxlength='16' value="$External_Refresh" placeholder="$External_Refresh"></td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA Retry:</td>
			<td style="text-align: left;"><input type='number' name='External_Retry' maxlength='16' value="$External_Retry" placeholder="$External_Retry"></td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA Expire:</td>
			<td style="text-align: left;"><input type='number' name='External_Expire' maxlength='16' value="$External_Expire" placeholder="$External_Expire"></td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA Minimum:</td>
			<td style="text-align: left;"><input type='number' name='External_Minimum' maxlength='16' value="$External_Minimum" placeholder="$External_Minimum"></td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA NS1:</td>
			<td style="text-align: left;"><input type='text' name='External_NS1' maxlength='255' value="$External_NS1" placeholder="$External_NS1"></td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA NS2:</td>
			<td style="text-align: left;"><input type='text' name='External_NS2' maxlength='255' value="$External_NS2" placeholder="$External_NS2"></td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA NS3:</td>
			<td style="text-align: left;"><input type='text' name='External_NS3' maxlength='255' value="$External_NS3" placeholder="$External_NS3"></td>
		</tr>
	</table>
</details>
ENDHTML

} # sub html_dns_configuration

sub html_reverse_proxy_configuration {

my $Reverse_Proxy_Location = Reverse_Proxy_Location();
my $Proxy_Redirect_Location = Proxy_Redirect_Location();
my $Reverse_Proxy_Storage = Reverse_Proxy_Storage();
my $Proxy_Redirect_Storage = Proxy_Redirect_Storage();
my ($Reverse_Proxy_Transfer_Log_Path,
	$Reverse_Proxy_Error_Log_Path,
	$Reverse_Proxy_SSL_Certificate_File,
	$Reverse_Proxy_SSL_Certificate_Key_File,
	$Reverse_Proxy_SSL_CA_Certificate_File) = Reverse_Proxy_Defaults();
my ($Proxy_Redirect_Transfer_Log_Path,
	$Proxy_Redirect_Error_Log_Path) = Redirect_Defaults();

print <<ENDHTML;
<details>
<summary style="text-align: center; font-weight: bold; font-size: 1.5em;">Reverse Proxy Configuration</summary>
	<table align='center'>
		<tr>
			<td style="text-align: right;">Reverse Proxy File Location:</td>
			<td style="text-align: left;"><input type='text' name='Reverse_Proxy_Location' maxlength='255' value="$Reverse_Proxy_Location" placeholder="$Reverse_Proxy_Location"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Proxy Redirect File Location:</td>
			<td style="text-align: left;"><input type='text' name='Proxy_Redirect_Location' maxlength='255' value="$Proxy_Redirect_Location" placeholder="$Proxy_Redirect_Location"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Archived Reverse Proxy File Storage Location:</td>
			<td style="text-align: left;"><input type='text' name='Reverse_Proxy_Storage' maxlength='255' value="$Reverse_Proxy_Storage" placeholder="$Reverse_Proxy_Storage"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Archived Proxy Redirect File Storage Location:</td>
			<td style="text-align: left;"><input type='text' name='Proxy_Redirect_Storage' maxlength='255' value="$Proxy_Redirect_Storage" placeholder="$Proxy_Redirect_Storage"></td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Reverse Proxy Transfer Log Path:</td>
			<td style="text-align: left;"><input type='text' name='Reverse_Proxy_Transfer_Log_Path' maxlength='255' value="$Reverse_Proxy_Transfer_Log_Path" placeholder="$Reverse_Proxy_Transfer_Log_Path"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Reverse Proxy Error Log Path:</td>
			<td style="text-align: left;"><input type='text' name='Reverse_Proxy_Error_Log_Path' maxlength='255' value="$Reverse_Proxy_Error_Log_Path" placeholder="$Reverse_Proxy_Error_Log_Path"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Reverse Proxy Certificate File:</td>
			<td style="text-align: left;"><input type='text' name='Reverse_Proxy_SSL_Certificate_File' maxlength='255' value="$Reverse_Proxy_SSL_Certificate_File" placeholder="$Reverse_Proxy_SSL_Certificate_File"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Reverse Proxy Certificate Key File:</td>
			<td style="text-align: left;"><input type='text' name='Reverse_Proxy_SSL_Certificate_Key_File' maxlength='255' value="$Reverse_Proxy_SSL_Certificate_Key_File" placeholder="$Reverse_Proxy_SSL_Certificate_Key_File"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Reverse Proxy CA Certificate File:</td>
			<td style="text-align: left;"><input type='text' name='Reverse_Proxy_SSL_CA_Certificate_File' maxlength='255' value="$Reverse_Proxy_SSL_CA_Certificate_File" placeholder="$Reverse_Proxy_SSL_CA_Certificate_File"></td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Proxy Redirect Transfer Log:</td>
			<td style="text-align: left;"><input type='text' name='Proxy_Redirect_Transfer_Log_Path' maxlength='255' value="$Proxy_Redirect_Transfer_Log_Path" placeholder="$Proxy_Redirect_Transfer_Log_Path"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Proxy Redirect Error Log:</td>
			<td style="text-align: left;"><input type='text' name='Proxy_Redirect_Error_Log_Path' maxlength='255' value="$Proxy_Redirect_Error_Log_Path" placeholder="$Proxy_Redirect_Error_Log_Path"></td>
		</tr>
	</table>
</details>
ENDHTML

} # sub html_reverse_proxy_configuration

sub html_ldap_configuration {

my $LDAP_Enabled = LDAP_Login('Status_Check');
my ($LDAP_Server,
	$LDAP_Port,
	$LDAP_Timeout,
	$LDAP_User_Name_Prefix,
	$LDAP_User_Name_Suffix,
	$LDAP_Filter,
	$LDAP_Search_Base) = LDAP_Login('Parameters');

	$LDAP_User_Name_Prefix =~ s/=*$//;
	$LDAP_User_Name_Suffix =~ s/^,*//;

	my $LDAP_User_Name_DN = $LDAP_User_Name_Prefix . '=<i>username</i>,' . $LDAP_User_Name_Suffix;

	my ($LDAP_Yes, $LDAP_No);
	if ($LDAP_Enabled) {$LDAP_Yes = 'checked'} else {$LDAP_No = 'checked'}

	print <<ENDHTML;
<details>
<summary style="text-align: center; font-weight: bold; font-size: 1.5em;">LDAP Configuration</summary>
Note: Depending on your LDAP/AD implementation, you may need to set <b>LDAP Filter</b> to <i>uid</i>, <i>sAMAccountName</i>, or another value unique to your organisation.<br />
Use the DN prefix and suffix to define the DN to authenticate with; e.g. a prefix: of<br />
<b>uid=</b><br />
...and a suffix of...<br />
<b>ou=People,dc=nwk1,dc=local</b><br />
the DN submitted would be:<br />
<b>uid=<i>username</i>,ou=People,dc=nwk1,dc=local</b>
ENDHTML

	if ($LDAP_Enabled) {
		print "<p>Current DN based on saved values in the DB:<br /><b>$LDAP_User_Name_DN</b></p>";
	}

	print <<ENDHTML;
	<table align='center'>
		<tr>
			<td style="text-align: right;">LDAP Enabled:</td>
			<td style="text-align: left;"><input type="radio" name="LDAP_Enabled" value="0" $LDAP_No>No <input type="radio" name="LDAP_Enabled" value="1" $LDAP_Yes>Yes</td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP Server:</td>
			<td style="text-align: left;"><input type='text' name='LDAP_Server' maxlength='255' value="$LDAP_Server" placeholder="$LDAP_Server"></td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP Port:</td>
			<td style="text-align: left;"><input type='number' name='LDAP_Port' maxlength='5' value="$LDAP_Port" placeholder="$LDAP_Port"></td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP Timeout:</td>
			<td style="text-align: left;"><input type='number' name='LDAP_Timeout' maxlength='5' value="$LDAP_Timeout" placeholder="$LDAP_Timeout"></td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP User Prefix (DN):</td>
			<td style="text-align: left;"><input type='text' name='LDAP_User_Name_Prefix' maxlength='255' value="$LDAP_User_Name_Prefix" placeholder="$LDAP_User_Name_Prefix"></td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP User Suffix (DN):</td>
			<td style="text-align: left;"><input type='text' name='LDAP_User_Name_Suffix' maxlength='255' value="$LDAP_User_Name_Suffix" placeholder="$LDAP_User_Name_Suffix"></td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP Filter:</td>
			<td style="text-align: left;"><input type='text' name='LDAP_Filter' maxlength='255' value="$LDAP_Filter" placeholder="$LDAP_Filter"></td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP Search Base:</td>
			<td style="text-align: left;"><input type='text' name='LDAP_Search_Base' maxlength='255' value="$LDAP_Search_Base" placeholder="$LDAP_Search_Base"></td>
		</tr>
	</table>
</details>
ENDHTML

} # sub html_ldap_configuration

sub html_dshell_configuration {

	my $DShell_WaitFor_Timeout = DShell_WaitFor_Timeout();
	my $DShell_Queue_Execution_Cap = DShell_Queue_Execution_Cap();

	print <<ENDHTML;
<details>
<summary style="text-align: center; font-weight: bold; font-size: 1.5em;">D-Shell Configuration</summary>
	<table align='center'>
		<tr>
			<td style="text-align: right;">DShell *WAITFOR Timeout:</td>
			<td style="text-align: left;"><input type='number' name='DShell_WaitFor_Timeout' maxlength='8' value="$DShell_WaitFor_Timeout" placeholder="$DShell_WaitFor_Timeout"></td>
		</tr>
		<tr>
			<td style="text-align: right;">DShell Concurrent Job Execution Limit:</td>
			<td style="text-align: left;"><input type='number' name='DShell_Queue_Execution_Cap' maxlength='5' value="$DShell_Queue_Execution_Cap" placeholder="$DShell_Queue_Execution_Cap"></td>
		</tr>
	</table>
</details>
ENDHTML

} # sub html_dshell_configuration

sub html_git_configuration {

	my $Use_Git = Git_Link('Status_Check');
		my ($Git_Yes, $Git_No);
		if ($Use_Git) {$Git_Yes = 'checked'} else {$Git_No = 'checked'}
	my $Git_Directory = Git_Link('Directory');
	my $Git_Redirect = Git_Locations('Redirect');
		$Git_Redirect =~ s/$Git_Directory\///;
	my $Git_ReverseProxy = Git_Locations('ReverseProxy');
		$Git_ReverseProxy =~ s/$Git_Directory\///;
	my $Git_CommandSets = Git_Locations('CommandSets');
		$Git_CommandSets =~ s/$Git_Directory\///;
	my $Git_DSMS = Git_Locations('DSMS');
		$Git_DSMS =~ s/$Git_Directory\///;

	print <<ENDHTML;
<details>
<summary style="text-align: center; font-weight: bold; font-size: 1.5em;">Git Configuration</summary>
	<table align='center'>
		<tr>
			<td style="text-align: right;">Enable Git:</td>
			<td style="text-align: left;"><input type="radio" name="Use_Git" value="0" $Git_No>No <input type="radio" name="Use_Git" value="1" $Git_Yes>Yes</td>
		</tr>
		<tr>
			<td style="text-align: right;">Git Main Storage Directory:</td>
			<td style="text-align: left;"><input type='text' name='Git_Directory' maxlength='255' value="$Git_Directory" placeholder="$Git_Directory"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Git Proxy Redirect Directory:</td>
			<td style="text-align: left;"><input type='text' name='Git_Redirect' maxlength='255' value="$Git_Redirect" placeholder="$Git_Redirect"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Git Reverse Proxy Directory:</td>
			<td style="text-align: left;"><input type='text' name='Git_ReverseProxy' maxlength='255' value="$Git_ReverseProxy" placeholder="$Git_ReverseProxy"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Git Command Set Directory:</td>
			<td style="text-align: left;"><input type='text' name='Git_CommandSets' maxlength='255' value="$Git_CommandSets" placeholder="$Git_CommandSets"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Git DSMS Directory:</td>
			<td style="text-align: left;"><input type='text' name='Git_DSMS' maxlength='255' value="$Git_DSMS" placeholder="$Git_DSMS"></td>
		</tr>
	</table>
</details>
ENDHTML

} # sub html_git_configuration

sub html_vmware_configuration {

	my ($vSphere_Server, $vSphere_Username, $vSphere_Password) = VMware_Connection();
	my $vSphere_Password_Set;
	if ($vSphere_Password) {$vSphere_Password_Set = '<span style="color: #00FF00;"> [Set]</span>'}
		else {$vSphere_Password_Set = '<span style="color: #FF0000;"> [Not Set]</span>'}

	print <<ENDHTML;
<details>
<summary style="text-align: center; font-weight: bold; font-size: 1.5em;">VMware vSphere API Configuration</summary>
<p style="text-align: center;">Note: Due to licencing restrictions and differing requirements for each vSphere version, VMware's API module is not included by default. 
Installation instructions are available in $System_Name documentation, or via 
[<a href='https://www.vmware.com/support/developer/viperltoolkit/index.html'>vSphere SDK on vmware.com</a>]. Once installed and enabled, VMware functions 
in $System_Name should work automatically. To set any values here, you must also include the password.</p>
	<table align='center'>
		<tr>
			<td style="text-align: right;">vSphere Server URI:</td>
			<td style="text-align: left;"><input type='text' name='vSphere_Server' maxlength='255' value="$vSphere_Server" placeholder="$vSphere_Server"></td>
		</tr>
		<tr>
			<td style="text-align: right;">vSphere Username:</td>
			<td style="text-align: left;"><input type='text' name='vSphere_Username' maxlength='255' value="$vSphere_Username" placeholder="$vSphere_Username"></td>
		</tr>
		<tr>
			<td style="text-align: right;">vSphere Password:</td>
			<td style="text-align: left;"><input type='password' name='vSphere_Password' maxlength='255'>$vSphere_Password_Set</td>
		</tr>
	</table>
</details>
ENDHTML

} # sub html_vmware_configuration

sub html_proxmox_configuration {

	my ($Proxmox_Server, $Proxmox_Server_Port, $Proxmox_Username, $Proxmox_Password) = Proxmox_Connection();
	my $Proxmox_Password_Set;
	if ($Proxmox_Password) {$Proxmox_Password_Set = '<span style="color: #00FF00;"> [Set]</span>'}
		else {$Proxmox_Password_Set = '<span style="color: #FF0000;"> [Not Set]</span>'}

	print <<ENDHTML;
<details>
<summary style="text-align: center; font-weight: bold; font-size: 1.5em;">Proxmox API Configuration</summary>
<p style="text-align: center;">Note: Proxmox username must include realm (e.g. 'root\@pam'). To set any values here, you must also include the password.</p>
	<table align='center'>
		<tr>
			<td style="text-align: right;">Proxmox Server:</td>
			<td style="text-align: left;"><input type='text' name='Proxmox_Server' maxlength='255' value="$Proxmox_Server" placeholder="$Proxmox_Server"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Proxmox Server Port:</td>
			<td style="text-align: left;"><input type='number' name='Proxmox_Server_Port' maxlength='5' value="$Proxmox_Server_Port" placeholder="$Proxmox_Server_Port"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Proxmox Username:</td>
			<td style="text-align: left;"><input type='text' name='Proxmox_Username' maxlength='255' value="$Proxmox_Username" placeholder="$Proxmox_Username"></td>
		</tr>
		<tr>
			<td style="text-align: right;">Proxmox Password:</td>
			<td style="text-align: left;"><input type='password' name='Proxmox_Password' maxlength='255'>$Proxmox_Password_Set</td>
		</tr>
	</table>
</details>
ENDHTML

} # sub html_proxmox_configuration

sub write_configuration {

	my $Audit_Log_Submission = Audit_Log_Submission();
	$Audit_Log_Submission->execute("Configuration", "Modify", "$User_Name Modified the system's configuration.", '$User_Name');

	# System
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


	# Git
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


	# VMware
	if ($vSphere_Password) {
		my $VMware_Config = $DB_Connection->do("DELETE FROM `config_vmware` WHERE 1=1");
		$VMware_Config = $DB_Connection->prepare("INSERT INTO `config_vmware` (
			`vSphere_Server`,
			`vSphere_Username`,
			`vSphere_Password`
		)
		VALUES (
			?, ?, ?
		)");
	
		$VMware_Config->execute($vSphere_Server, $vSphere_Username, $vSphere_Password);
	}


	# Proxmox
	if ($Proxmox_Password) {
		my $Proxmox_Config = $DB_Connection->do("DELETE FROM `config_proxmox` WHERE 1=1");
		$Proxmox_Config = $DB_Connection->prepare("INSERT INTO `config_proxmox` (
			`Proxmox_Server`,
			`Proxmox_Port`,
			`Proxmox_Username`,
			`Proxmox_Password`
		)
		VALUES (
			?, ?, ?, ?
		)");

		$Proxmox_Config->execute($Proxmox_Server, $Proxmox_Server_Port, $Proxmox_Username, $Proxmox_Password);
	}


	# D-Shell
	my $DShell_Config = $DB_Connection->do("DELETE FROM `config_dshell` WHERE 1=1");
	$DShell_Config = $DB_Connection->prepare("INSERT INTO `config_dshell` (
		`DShell_WaitFor_Timeout`,
		`DShell_Queue_Execution_Cap`
	)
	VALUES (
		?, ?
	)");

	$DShell_Config->execute($DShell_WaitFor_Timeout, $DShell_Queue_Execution_Cap);

	my $Message_Green="Configuration written to the database.";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /$Me\n\n";
	exit(0);

} # sub write_configuration
