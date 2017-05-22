#!/usr/bin/perl -T

use strict;
use lib qw(resources/modules/);
use lib qw(../resources/modules/);
use Date::Parse qw(str2time);

require './common.pl';
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();
my $Header = Header();
my $Footer = Footer();

my $User_Name = $Session->param("User_Name");
my $User_Admin = $Session->param("User_Admin");
my $Release_Lock = $CGI->param("Release_Lock");

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

if ($Release_Lock eq 'DSMS') {

	$DB_Connection->do("UPDATE `lock` SET 
	`sudoers-build` = '0',
	`sudoers-distribution` = '0'");

	my $Message_Orange="Lock released";
	$Session->param('Message_Orange', $Message_Orange);
	$Session->flush();
	print "Location: /system-status.cgi\n\n";
	exit(0);
}
elsif ($Release_Lock eq 'ReverseProxy') {

	$DB_Connection->do("UPDATE `lock` SET 
	`reverse-proxy-build` = '0'");

	my $Message_Orange="Lock released";
	$Session->param('Message_Orange', $Message_Orange);
	$Session->flush();
	print "Location: /system-status.cgi\n\n";
	exit(0);
}

require $Header;
&html_output;
require $Footer;

sub html_output {

	my $Referer = $ENV{HTTP_REFERER};

	if ($Referer !~ /system-status.cgi/) {
		my $Audit_Log_Submission = Audit_Log_Submission();
	
		$Audit_Log_Submission->execute("System Status", "View", "$User_Name accessed System Status.", $User_Name);
	}

print <<ENDHTML;

<div id='full-page-block'>
<h2 style='text-align: center;'>System Configuration and Status</h2>
	<div id='blockrow1'>
		<div id='blocka1'>
ENDHTML

			&html_dsms_configuration;
			&html_dns_configuration;

print <<ENDHTML;
		</div> <!-- blocka1 -->

		<div id='blocka2'>
ENDHTML

			&html_system_configuration;

print <<ENDHTML;
		</div> <!-- blocka2 -->

		<div id='blocka3'>
ENDHTML

			&html_distribution_status;
			&html_reverse_proxy_configuration;

print <<ENDHTML;
		</div> <!-- blocka3 -->
	</div> <!-- blockrow1 -->
	<div id='blockrow2'>
		<div id='blockb1'>
ENDHTML

			

print <<ENDHTML;
		</div> <!-- blockb1 -->
		<div id='blocka4'>
ENDHTML

			

print <<ENDHTML;
		</div> <!-- blockb2 -->

</div> <!-- full-page-block -->
ENDHTML







} #sub html_output

sub html_system_configuration {

my $System_Name = System_Name();
my $System_Short_Name = System_Short_Name();
my $Recovery_Email_Address = Recovery_Email_Address();
my $DNS_Server = DNS_Server();
my $LDAP_Check = LDAP_Login('Status_Check');
my ($LDAP_Server,
	$LDAP_Port,
	$Timeout,
	$LDAP_User_Name_Prefix,
	$LDAP_Filter,
	$LDAP_Search_Base) = LDAP_Login('Parameters');
my ($Enforce_Complexity_Requirements,
	$Minimum_Length,
	$Minimum_Upper_Case_Characters,
	$Minimum_Lower_Case_Characters,
	$Minimum_Digits,
	$Minimum_Special_Characters,
	$Special_Characters) = Password_Complexity_Check('Wn&sCvaG%!nvz}pb|#.pNzMe~I76fRx9m;a1|9wPYNQw4$u"w^]YA5WXr2b>bzyZzNKczDt~K5VHuDe~kX5mm=Ke:U5M9#g9PylHiSO$ob2-/Oc;=j#-KHuQj&#5fA,K_k$J\sSZup3<22MpK<>J|Ptp.r"h6');
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
my $Random_Alpha_Numeric_Password_8 = Random_Alpha_Numeric_Password(8);
my $Random_Alpha_Numeric_Password_16 = Random_Alpha_Numeric_Password(16);
my $Random_Alpha_Numeric_Password_32 = Random_Alpha_Numeric_Password(32);
my $Salt = Salt();
	$Salt =~ s/&/&amp;/g;
	$Salt =~ s/</&lt;/g;
	$Salt =~ s/>/&gt;/g;
my $Salt_1 = Salt(1);
	$Salt_1 =~ s/&/&amp;/g;
	$Salt_1 =~ s/</&lt;/g;
	$Salt_1 =~ s/>/&gt;/g;

print <<ENDHTML;
	<h3 style="text-align: center;">Global Configuration</h3>
	<table align='center'>
		<tr>
			<td style="width: 50%; text-align: right;">System Name</td>
			<td style='width: 50%; color: #00FF00;'>$System_Name</td>
		</tr>
		<tr>
			<td style="text-align: right;">System Short Name</td>
			<td style='color: #00FF00;'>$System_Short_Name</td>
		</tr>
		<tr>
			<td style="text-align: right;">Recovery Email Address</td>
			<td style='color: #00FF00;'>$Recovery_Email_Address</td>
		</tr>
		<tr>
			<td style="text-align: right;">Failback DNS Server</td>
			<td style='color: #00FF00;'>$DNS_Server</td>
		</tr>		
		<tr>
			<td style="text-align: right;">LDAP Authentication</td>
			<td style='color: #00FF00;'>$LDAP_Check</td>
		</tr>
ENDHTML

if ($LDAP_Check eq 'On') {
	print <<ENDHTML;
		<tr>
			<td style="text-align: right;">LDAP Server</td>
			<td style='color: #00FF00;'>$LDAP_Server</td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP Port</td>
			<td style='color: #00FF00;'>$LDAP_Port</td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP Timeout</td>
			<td style='color: #00FF00;'>$Timeout</td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP User Prefix</td>
			<td style='color: #00FF00;'>$LDAP_User_Name_Prefix</td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP Filter</td>
			<td style='color: #00FF00;'>$LDAP_Filter</td>
		</tr>
		<tr>
			<td style="text-align: right;">LDAP Search Base</td>
			<td style='color: #00FF00;'>$LDAP_Search_Base</td>
		</tr>
ENDHTML
}

print <<ENDHTML;
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Header Location</td>
			<td style='color: #00FF00;'>$Header</td>
		</tr>
		<tr>
			<td style="text-align: right;">Footer Location</td>
			<td style='color: #00FF00;'>$Footer</td>
		</tr>
		<tr>
			<td style="text-align: right;">md5sum Location</td>
			<td style='color: #00FF00;'>$md5sum</td>
		</tr>
		<tr>
			<td style="text-align: right;">cut Location</td>
			<td style='color: #00FF00;'>$cut</td>
		</tr>
		<tr>
			<td style="text-align: right;">visudo Location</td>
			<td style='color: #00FF00;'>$visudo</td>
		</tr>
		<tr>
			<td style="text-align: right;">cp Location</td>
			<td style='color: #00FF00;'>$cp</td>
		</tr>
		<tr>
			<td style="text-align: right;">ls Location</td>
			<td style='color: #00FF00;'>$ls</td>
		</tr>
		<tr>
			<td style="text-align: right;">grep Location</td>
			<td style='color: #00FF00;'>$sudo_grep</td>
		</tr>
		<tr>
			<td style="text-align: right;">head Location</td>
			<td style='color: #00FF00;'>$head</td>
		</tr>
		<tr>
			<td style="text-align: right;">nmap Location</td>
			<td style='color: #00FF00;'>$nmap</td>
		</tr>
		<tr>
			<td style="text-align: right;">ps Location</td>
			<td style='color: #00FF00;'>$ps</td>
		</tr>
		<tr>
			<td style="text-align: right;">wc Location</td>
			<td style='color: #00FF00;'>$wc</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Requirements Enforced</td>
			<td style='color: #00FF00;'>$Enforce_Complexity_Requirements</td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Minimum Length</td>
			<td style='color: #00FF00;'>$Minimum_Length</td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Minimum Upper Case Characters</td>
			<td style='color: #00FF00;'>$Minimum_Upper_Case_Characters</td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Minimum Lower Case Characters</td>
			<td style='color: #00FF00;'>$Minimum_Lower_Case_Characters</td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Minimum Digits</td>
			<td style='color: #00FF00;'>$Minimum_Digits</td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Minimum Special Characters</td>
			<td style='color: #00FF00;'>$Minimum_Special_Characters</td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Complexity Accepted Special Characters</td>
			<td style='color: #00FF00;'>$Special_Characters</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Reset Generation Test (8 characters)</td>
			<td style='color: #00FF00;'>$Random_Alpha_Numeric_Password_8</td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Reset Generation Test (16 characters)</td>
			<td style='color: #00FF00;'>$Random_Alpha_Numeric_Password_16</td>
		</tr>
		<tr>
			<td style="text-align: right;">Password Reset Generation Test (32 characters)</td>
			<td style='color: #00FF00;'>$Random_Alpha_Numeric_Password_32</td>
		</tr>
		<tr>
			<td style="text-align: right;">Salt Generation Test</td>
			<td style='color: #00FF00;'>$Salt</td>
		</tr>
		<tr>
			<td style="text-align: right;">Salt Generation Test (Single Value)</td>
			<td style='color: #00FF00;'>$Salt_1</td>
		</tr>
	</table>
ENDHTML
} # sub html_system_configuration

sub html_distribution_status {

print <<ENDHTML;
	<h3 style="text-align: center;">Build and Distribution Status</h3>
	<table align='center'>

ENDHTML

	my $Select_Locks = $DB_Connection->prepare("SELECT `sudoers-build`, `sudoers-distribution`, `dns-build`, 
	`reverse-proxy-build`, `last-sudoers-build-started`, `last-sudoers-build-finished`, `last-sudoers-distribution-started`, 
	`last-sudoers-distribution-finished`, `last-dns-build-started`, `last-dns-build-finished`, 
	`last-reverse-proxy-build-started`, `last-reverse-proxy-build-finished`
	FROM `lock`");
	$Select_Locks->execute();

	while ( my @Locks = $Select_Locks->fetchrow_array() )
	{
		my $Sudoers_Build_Lock = $Locks[0];
		my $Sudoers_Distribution_Lock = $Locks[1];
		my $DNS_Lock = $Locks[2];
		my $Reverse_Proxy_Lock = $Locks[3];
		my $Sudoers_Last_Build_Start = $Locks[4];
		my $Sudoers_Last_Build_End = $Locks[5];
		my $Sudoers_Last_Distribution_Start = $Locks[6];
		my $Sudoers_Last_Distribution_End = $Locks[7];
		my $DNS_Last_Build_Start = $Locks[8];
		my $DNS_Last_Build_End = $Locks[9];
		my $Reverse_Proxy_Last_Build_Start = $Locks[10];
		my $Reverse_Proxy_Last_Build_End = $Locks[11];

		# Sudoers Build Lock
		print "<tr><td style='text-align: right;'>Sudoers Build Process</td>";
		if ($Sudoers_Build_Lock == 1) {
			print "<td style='color: #FFFF00;'>Locked (Currently Building)<br /><a href='system-status.cgi?Release_Lock=DSMS'><span style='color: #FF6C00;'>[Release Lock]</span></a></td>";
		}
		elsif ($Sudoers_Build_Lock == 2) {
			print "<td style='color: #FF6C00;'>Error (Last Build Failed Syntax Check)</td>";
		}
		elsif ($Sudoers_Build_Lock == 3) {
			print "<td style='color: #FFFF00;'>Stalled (Rules Waiting Approval)</td>";
		}
		else {
			print "<td style='color: #00FF00;'>Unlocked (Ready to Build)</td>";
		}
		print "</tr>";
		# / Sudoers Build Lock
		# Sudoers Build Time
		my $Sudoers_Build_Start = str2time($Sudoers_Last_Build_Start);
		my $Sudoers_Build_End = str2time($Sudoers_Last_Build_End);
		my $Sudoers_Total_Build_Time = $Sudoers_Build_End - $Sudoers_Build_Start;

		if ($Sudoers_Total_Build_Time < 0) {$Sudoers_Total_Build_Time = 'Running...';}
		elsif ($Sudoers_Total_Build_Time < 1) {$Sudoers_Total_Build_Time = 'Less than a second';}
		elsif ($Sudoers_Total_Build_Time == 1) {$Sudoers_Total_Build_Time = '1 second';}
		else {$Sudoers_Total_Build_Time = "$Sudoers_Total_Build_Time seconds";}

print <<ENDHTML;
		<tr>
			<td style="width: 50%; text-align: right;">Last Sudoers Build Started</td>
			<td style='width: 50%; color: #00FF00;'>$Sudoers_Last_Build_Start</td>
		</tr>
		<tr>
			<td style="text-align: right;">Last Sudoers Build Completed</td>
			<td style='color: #00FF00;'>$Sudoers_Last_Build_End</td>
		</tr>
		<tr>
			<td style="text-align: right;">Total Sudoers Build Time</td>
			<td style='color: #00FF00;'>$Sudoers_Total_Build_Time</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
ENDHTML
		# / Sudoers Build Time

		# Sudoers Distribution Lock
		print "<tr><td style='text-align: right;'>Sudoers Distribution Process</td>";
		if ($Sudoers_Distribution_Lock == 1) {
			print "<td style='color: #FFFF00;'>Locked (Currently Distributing)<br /><a href='system-status.cgi?Release_Lock=DSMS'><span style='color: #FF6C00;'>[Release Lock]</span></a></td>";
		}
		else {
			print "<td style='color: #00FF00;'>Unlocked (Ready to Deploy)</td>";
		}
		print "</tr>";
		# / Sudoers Distribution Lock

		# Sudoers Distribution Time
		my $Sudoers_Distribution_Start = str2time($Sudoers_Last_Distribution_Start);
		my $Sudoers_Distribution_End = str2time($Sudoers_Last_Distribution_End);
		my $Sudoers_Total_Distribution_Time = $Sudoers_Distribution_End - $Sudoers_Distribution_Start;
		
		if ($Sudoers_Total_Distribution_Time < 0) {$Sudoers_Total_Distribution_Time = 'Running...';}
		elsif ($Sudoers_Total_Distribution_Time < 1) {$Sudoers_Total_Distribution_Time = 'Less than a second';}
		elsif ($Sudoers_Total_Distribution_Time == 1) {$Sudoers_Total_Distribution_Time = '1 second';}
		else {$Sudoers_Total_Distribution_Time = "$Sudoers_Total_Distribution_Time seconds";}

print <<ENDHTML;
		<tr>
			<td style="text-align: right;">Last Sudoers Distribution Started</td>
			<td style='color: #00FF00;'>$Sudoers_Last_Distribution_Start</td>
		</tr>
		<tr>
			<td style="text-align: right;">Last Sudoers Distribution Completed</td>
			<td style='color: #00FF00;'>$Sudoers_Last_Distribution_End</td>
		</tr>
		<tr>
			<td style="text-align: right;">Total Sudoers Distribution Time</td>
			<td style='color: #00FF00;'>$Sudoers_Total_Distribution_Time</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
ENDHTML
		# / Sudoers Distribution Time

		# Sudoers Client Statues
		my $Select_Sudoers_Client_Status = $DB_Connection->prepare("SELECT `status` FROM `distribution`");
		$Select_Sudoers_Client_Status->execute( );
		my $Total_Sudoers_Clients = $Select_Sudoers_Client_Status->rows();
	
		my $OK_Sudoers_Clients;
		my $Broken_Sudoers_Clients;
		while ( my $Status = $Select_Sudoers_Client_Status->fetchrow_array() )
		{
			if ($Status =~ /^OK/) {$OK_Sudoers_Clients++;}
			else {$Broken_Sudoers_Clients++;}
		}
	
		if ($Broken_Sudoers_Clients == 0) {$Broken_Sudoers_Clients = "<span style='color: #00FF00;'>0</span>";}
		else {$Broken_Sudoers_Clients = "<span style='color: #FF6C00;'>$Broken_Sudoers_Clients</span>";}

print <<ENDHTML;
		<tr>
			<td style="text-align: right;">Total Sudoers Clients</td>
			<td style='color: #00FF00;'>$Total_Sudoers_Clients</td>
		</tr>
		<tr>
			<td style="text-align: right;">OK Sudoers Clients</td>
			<td style='color: #00FF00;'>$OK_Sudoers_Clients</td>
		</tr>
		<tr>
			<td style="text-align: right;">Broken Sudoers Clients</td>
			<td>$Broken_Sudoers_Clients</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
ENDHTML
		# / Sudoers Remote Host Statues

		# DNS Build Time
		my $DNS_Build_Start = str2time($DNS_Last_Build_Start);
		my $DNS_Build_End = str2time($DNS_Last_Build_End);
		my $DNS_Total_Build_Time = $DNS_Build_End - $DNS_Build_Start;

		if ($DNS_Total_Build_Time < 0) {$DNS_Total_Build_Time = 'Running...';}
		elsif ($DNS_Total_Build_Time < 1) {$DNS_Total_Build_Time = 'Less than a second';}
		elsif ($DNS_Total_Build_Time == 1) {$DNS_Total_Build_Time = '1 second';}
		else {$DNS_Total_Build_Time = "$DNS_Total_Build_Time seconds";}

print <<ENDHTML;
		<tr>
			<td style="width: 50%; text-align: right;">Last DNS Build Started</td>
			<td style='width: 50%; color: #00FF00;'>$DNS_Last_Build_Start</td>
		</tr>
		<tr>
			<td style="text-align: right;">Last DNS Build Completed</td>
			<td style='color: #00FF00;'>$DNS_Last_Build_End</td>
		</tr>
		<tr>
			<td style="text-align: right;">Total DNS Build Time</td>
			<td style='color: #00FF00;'>$DNS_Total_Build_Time</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
ENDHTML
		# / DNS Build Time

		# Reverse Proxy Build Time
		my $Reverse_Proxy_Build_Start = str2time($Reverse_Proxy_Last_Build_Start);
		my $Reverse_Proxy_Build_End = str2time($Reverse_Proxy_Last_Build_End);
		my $Reverse_Proxy_Total_Build_Time = $Reverse_Proxy_Build_End - $Reverse_Proxy_Build_Start;

		if ($Reverse_Proxy_Total_Build_Time < 0) {$Reverse_Proxy_Total_Build_Time = 'Running...';}
		elsif ($Reverse_Proxy_Total_Build_Time < 1) {$Reverse_Proxy_Total_Build_Time = 'Less than a second';}
		elsif ($Reverse_Proxy_Total_Build_Time == 1) {$Reverse_Proxy_Total_Build_Time = '1 second';}
		else {$Reverse_Proxy_Total_Build_Time = "$Reverse_Proxy_Total_Build_Time seconds";}

		# ReverseProxy Build Lock
		print "<tr><td style='text-align: right;'>ReverseProxy Build Process</td>";
		if ($Reverse_Proxy_Lock == 1) {
			print "<td style='color: #FFFF00;'>Locked (Currently Building)<br /><a href='system-status.cgi?Release_Lock=ReverseProxy'><span style='color: #FF6C00;'>[Release Lock]</span></a></td>";
		}
		elsif ($Reverse_Proxy_Lock == 2) {
			print "<td style='color: #FF6C00;'>Error (Last Build Failed Syntax Check)</td>";
		}
		else {
			print "<td style='color: #00FF00;'>Unlocked (Ready to Build)</td>";
		}
		print "</tr>";

print <<ENDHTML;
		<tr>
			<td style="width: 50%; text-align: right;">Last Reverse Proxy Build Started</td>
			<td style='width: 50%; color: #00FF00;'>$Reverse_Proxy_Last_Build_Start</td>
		</tr>
		<tr>
			<td style="text-align: right;">Last Reverse Proxy Build Completed</td>
			<td style='color: #00FF00;'>$Reverse_Proxy_Last_Build_End</td>
		</tr>
		<tr>
			<td style="text-align: right;">Total Reverse Proxy Build Time</td>
			<td style='color: #00FF00;'>$Reverse_Proxy_Total_Build_Time</td>
		</tr>
	</table>
ENDHTML
	# / Reverse Proxy Build Time
	}
} # sub html_distribution_status

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
<h3 style="text-align: center;">DSMS Configuration</h3>
	<table align='center'>
		<tr>
			<td style="text-align: right;">Sudoers Build File Ownership</td>
			<td style='color: #00FF00;'>$Sudoers_Owner ($Sudoers_Owner_ID)</td>
		</tr>
		<tr>
			<td style="text-align: right;">Sudoers Build File Group Ownership</td>
			<td style='color: #00FF00;'>$Sudoers_Group ($Sudoers_Group_ID)</td>
		</tr>
		<tr>
			<td style="text-align: right;">Sudoers Build File Location</td>
			<td style='color: #00FF00;'>$Sudoers_Location</td>
		</tr>
		<tr>
			<td style="text-align: right;">Legacy Sudoers Storage Directory Location</td>
			<td style='color: #00FF00;'>$Sudoers_Storage/</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default SFTP Distribution Port</td>
			<td style='color: #00FF00;'>$Distribution_SFTP_Port</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default SFTP Distribution User</td>
			<td style='color: #00FF00;'>$Distribution_User</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default SFTP Distribution Key Path</td>
			<td style='color: #00FF00;'>$Key_Path</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default SFTP Distribution Key Path</td>
			<td style='color: #00FF00;'>$Timeout seconds</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Remote Sudoers Drop Location</td>
			<td style='color: #00FF00;'>$Remote_Sudoers</td>
		</tr>
	</table>
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
<h3 style="text-align: center;">DNS Configuration</h3>
	<table align='center'>
		<tr>
			<td style="text-align: right;">DNS Build File Ownership</td>
			<td style='color: #00FF00;'>$DNS_Owner ($DNS_Owner_ID)</td>
		</tr>
		<tr>
			<td style="text-align: right;">DNS Build File Group Ownership</td>
			<td style='color: #00FF00;'>$DNS_Group ($DNS_Group_ID)</td>
		</tr>
		<tr>
			<td style="text-align: right;">Zone Master File Location</td>
			<td style='color: #00FF00;'>$Zone_Master_File</td>
		</tr>
		<tr>
			<td style="text-align: right;">Legacy DNS File Storage Location</td>
			<td style='color: #00FF00;'>$DNS_Storage</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal Config File Location</td>
			<td style='color: #00FF00;'>$DNS_Internal_Location</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA Email</td>
			<td style='color: #00FF00;'>$Internal_Email</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA TTL</td>
			<td style='color: #00FF00;'>$Internal_TTL</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA Serial (Current)</td>
			<td style='color: #00FF00;'>$Internal_Serial</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA Refresh</td>
			<td style='color: #00FF00;'>$Internal_Refresh</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA Retry</td>
			<td style='color: #00FF00;'>$Internal_Retry</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA Expire</td>
			<td style='color: #00FF00;'>$Internal_Expire</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA Minimum</td>
			<td style='color: #00FF00;'>$Internal_Minimum</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA NS1</td>
			<td style='color: #00FF00;'>$Internal_NS1</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA NS2</td>
			<td style='color: #00FF00;'>$Internal_NS2</td>
		</tr>
		<tr>
			<td style="text-align: right;">Internal SOA NS3</td>
			<td style='color: #00FF00;'>$Internal_NS3</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">External Config File Location</td>
			<td style='color: #00FF00;'>$DNS_External_Location</td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA Email</td>
			<td style='color: #00FF00;'>$External_Email</td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA TTL</td>
			<td style='color: #00FF00;'>$External_TTL</td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA Serial (Current)</td>
			<td style='color: #00FF00;'>$External_Serial</td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA Refresh</td>
			<td style='color: #00FF00;'>$External_Refresh</td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA Retry</td>
			<td style='color: #00FF00;'>$External_Retry</td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA Expire</td>
			<td style='color: #00FF00;'>$External_Expire</td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA Minimum</td>
			<td style='color: #00FF00;'>$External_Minimum</td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA NS1</td>
			<td style='color: #00FF00;'>$External_NS1</td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA NS2</td>
			<td style='color: #00FF00;'>$External_NS2</td>
		</tr>
		<tr>
			<td style="text-align: right;">External SOA NS3</td>
			<td style='color: #00FF00;'>$External_NS3</td>
		</tr>
</table>
ENDHTML

} # sub html_dns_configuration

sub html_reverse_proxy_configuration {

my $Reverse_Proxy_Location = Reverse_Proxy_Location();
my $Proxy_Redirect_Location = Proxy_Redirect_Location();
my $Reverse_Proxy_Storage = Reverse_Proxy_Storage();
my $Proxy_Redirect_Storage = Proxy_Redirect_Storage();
my ($Reverse_Proxy_Transfer_Log,
	$Reverse_Proxy_Error_Log,
	$Reverse_Proxy_SSL_Certificate_File,
	$Reverse_Proxy_SSL_Certificate_Key_File,
	$Reverse_Proxy_SSL_CA_Certificate_File) = Reverse_Proxy_Defaults();
my ($Redirect_Transfer_Log,
	$Redirect_Error_Log) = Redirect_Defaults();

print <<ENDHTML;
<h3 style="text-align: center;">Reverse Proxy Configuration</h3>
	<table align='center'>
		<tr>
			<td style="text-align: right;">Reverse Proxy File Location</td>
			<td style='color: #00FF00;'>$Reverse_Proxy_Location</td>
		</tr>
		<tr>
			<td style="text-align: right;">Proxy Redirect File Location</td>
			<td style='color: #00FF00;'>$Proxy_Redirect_Location</td>
		</tr>
		<tr>
			<td style="text-align: right;">Legacy Reverse Proxy File Storage Location</td>
			<td style='color: #00FF00;'>$Reverse_Proxy_Storage</td>
		</tr>
		<tr>
			<td style="text-align: right;">Legacy Proxy Rediret File Storage Location</td>
			<td style='color: #00FF00;'>$Proxy_Redirect_Storage</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Reverse Proxy Transfer Log</td>
			<td style='color: #00FF00;'>$Reverse_Proxy_Transfer_Log</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Reverse Proxy Error Log</td>
			<td style='color: #00FF00;'>$Reverse_Proxy_Error_Log</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Reverse Proxy Certificate File</td>
			<td style='color: #00FF00;'>$Reverse_Proxy_SSL_Certificate_File</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Reverse Proxy Certificate Key File</td>
			<td style='color: #00FF00;'>$Reverse_Proxy_SSL_Certificate_Key_File</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Reverse Proxy CA Certificate File</td>
			<td style='color: #00FF00;'>$Reverse_Proxy_SSL_CA_Certificate_File</td>
		</tr>
		<tr>
			<td>&nbsp;</td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Proxy Redirect Transfer Log</td>
			<td style='color: #00FF00;'>$Redirect_Transfer_Log</td>
		</tr>
		<tr>
			<td style="text-align: right;">Default Proxy Redirect Error Log</td>
			<td style='color: #00FF00;'>$Redirect_Error_Log</td>
		</tr>
</table>
ENDHTML

} # sub html_reverse_proxy_configuration