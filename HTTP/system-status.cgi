#!/usr/bin/perl

use strict;
use Date::Parse qw(str2time);

require 'common.pl';
my $DB_Management = DB_Management();
my $DB_Sudoers = DB_Sudoers();
my ($CGI, $Session, $Cookie) = CGI();

my $User_Name = $Session->param("User_Name");
my $User_Admin = $Session->param("User_Admin");

if (!$User_Name) {
	print "Location: logout.cgi\n\n";
	exit(0);
}

if ($User_Admin != 1 && $User_Admin != 2) {
	my $Message_Red = 'You do not have sufficient privileges to access that page.';
	$Session->param('Message_Red', $Message_Red);
	print "Location: index.cgi\n\n";
	exit(0);
}

require "header.cgi";
&html_output;
&html_configuration;
&html_status;
&html_end;
require "footer.cgi";

sub html_output {

	my $Referer = $ENV{HTTP_REFERER};

	if ($Referer !~ /system-status.cgi/) {
		my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
			`category`,
			`method`,
			`action`,
			`username`
		)
		VALUES (
			?, ?, ?, ?
		)");
	
		$Audit_Log_Submission->execute("System Status", "View", "$User_Name accessed System Status.", $User_Name);
	}

print <<ENDHTML;

<div id='full-page-block'>
<h2 style='text-align: center;'>System Status</h2>

<table width='100%'>
	<tr>

ENDHTML

} #sub html_output

sub html_status {

print <<ENDHTML;
		<td width='50%' valign='top' align='center'>
			<h2 style="text-align: center;">Build and Distribution Status</h2>
			<table>

ENDHTML

	my $Select_Locks = $DB_Management->prepare("SELECT `sudoers-build`, `sudoers-distribution`, 
	`last-build-started`, `last-build-finished`, `last-distribution-started`, `last-distribution-finished` 
	FROM `lock`");
	$Select_Locks->execute();

	while ( my ($Build_Lock, $Distribution_Lock, $Last_Build_Start, $Last_Build_End, 
	$Last_Distribution_Start, $Last_Distribution_End) = $Select_Locks->fetchrow_array() )
	{
		# Build Lock
		print "<tr><td style='text-align: right;'>Build Process</td>";
		if ($Build_Lock == 1) {
			print "<td style='color: #FFFF00;'>Locked (Currently Building CDSF)</td>";
		}
		elsif ($Build_Lock == 2) {
			print "<td style='color: #FF6C00;'>Error (Last Build Failed Syntax Check)</td>";
		}
		elsif ($Build_Lock == 3) {
			print "<td style='color: #FFFF00;'>Stalled (Rules Waiting Approval)</td>";
		}
		else {
			print "<td style='color: #00FF00;'>Unlocked (Ready to Build)</td>";
		}
		print "</tr>";
		# / Build Lock
		# Build Time
		my $Build_Start = str2time($Last_Build_Start);
		my $Build_End = str2time($Last_Build_End);
		my $Total_Build_Time = $Build_End - $Build_Start;

		if ($Total_Build_Time < 0) {$Total_Build_Time = 'Running...';}
		elsif ($Total_Build_Time < 1) {$Total_Build_Time = 'Less than a second';}
		elsif ($Total_Build_Time == 1) {$Total_Build_Time = '1 second';}
		else {$Total_Build_Time = "$Total_Build_Time seconds";}

print <<ENDHTML;
				<tr>
					<td style="width: 50%; text-align: right;">Last Build Started</td>
					<td style='width: 50%; color: #00FF00;'>$Last_Build_Start</td>
				</tr>
				<tr>
					<td style="text-align: right;">Last Build Completed</td>
					<td style='color: #00FF00;'>$Last_Build_End</td>
				</tr>
				<tr>
					<td style="text-align: right;">Total Build Time</td>
					<td style='color: #00FF00;'>$Total_Build_Time</td>
				</tr>
				<tr>
					<td>&nbsp;</td>
					<td>&nbsp;</td>
				</tr>
ENDHTML
		# / Build Time
		# Distribution Lock
		print "<tr><td style='text-align: right;'>Distribution Process</td>";
		if ($Distribution_Lock == 1) {
			print "<td style='color: #FFFF00;'>Locked (Currently Distributing CDSF)</td>";
		}
		else {
			print "<td style='color: #00FF00;'>Unlocked (Ready to Deploy)</td>";
		}
		print "</tr>";
		# / Distribution Lock
		# Distribution Time
		my $Distribution_Start = str2time($Last_Distribution_Start);
		my $Distribution_End = str2time($Last_Distribution_End);
		my $Total_Distribution_Time = $Distribution_End - $Distribution_Start;
		
		if ($Total_Distribution_Time < 0) {$Total_Distribution_Time = 'Running...';}
		elsif ($Total_Distribution_Time < 1) {$Total_Distribution_Time = 'Less than a second';}
		elsif ($Total_Distribution_Time == 1) {$Total_Distribution_Time = '1 second';}
		else {$Total_Distribution_Time = "$Total_Distribution_Time seconds";}

print <<ENDHTML;
				<tr>
					<td style="text-align: right;">Last Distribution Started</td>
					<td style='color: #00FF00;'>$Last_Distribution_Start</td>
				</tr>
				<tr>
					<td style="text-align: right;">Last Distribution Completed</td>
					<td style='color: #00FF00;'>$Last_Distribution_End</td>
				</tr>
				<tr>
					<td style="text-align: right;">Total Distribution Time</td>
					<td style='color: #00FF00;'>$Total_Distribution_Time</td>
				</tr>
ENDHTML
		# / Distribution Time
	}

	# Remote Host Statues
	my $Select_Host_Status = $DB_Management->prepare("SELECT `status` FROM `distribution`");
	$Select_Host_Status->execute( );
	my $Total_Hosts = $Select_Host_Status->rows();

	my $OK_Hosts;
	my $Broken_Hosts;
	while ( my $Status = $Select_Host_Status->fetchrow_array() )
	{
		if ($Status =~ /^OK/) {$OK_Hosts++;}
		else {$Broken_Hosts++;}
	}

	if ($Broken_Hosts == 0) {$Broken_Hosts = "<span style='color: #00FF00;'>0</span>";}
	else {$Broken_Hosts = "<span style='color: #FF6C00;'>$Broken_Hosts</span>";}

print <<ENDHTML;
				<tr>
					<td>&nbsp;</td>
					<td>&nbsp;</td>
				</tr>
				<tr>
					<td style="text-align: right;">Total Remote Hosts</td>
					<td style='color: #00FF00;'>$Total_Hosts</td>
				</tr>
				<tr>
					<td style="text-align: right;">OK Remote Hosts</td>
					<td style='color: #00FF00;'>$OK_Hosts</td>
				</tr>
				<tr>
					<td style="text-align: right;">Broken Remote Hosts</td>
					<td>$Broken_Hosts</td>
				</tr>
ENDHTML
	# / Remote Host Statues

print <<ENDHTML;
			</table>
		</td>
ENDHTML
} # html_status

sub html_configuration {

my $System_Name = System_Name();
my $System_Short_Name = System_Short_Name();
my $Recovery_Email_Address = Recovery_Email_Address();
my $Sudoers_Location = Sudoers_Location();
my $Sudoers_Storage = Sudoers_Storage();
my ($Distribution_SFTP_Port,
	$Distribution_User,
	$Key_Path,
	$Timeout,
	$Remote_Sudoers) = Distribution_Defaults();
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
my $Owner = Owner_ID('Full');
my $Owner_ID = Owner_ID();
my $Group = Group_ID('Full');
my $Group_ID = Group_ID();
my $Random_Alpha_Numeric_Password_8 = Random_Alpha_Numeric_Password(8);
my $Random_Alpha_Numeric_Password_16 = Random_Alpha_Numeric_Password(16);
my $Random_Alpha_Numeric_Password_32 = Random_Alpha_Numeric_Password(32);
my $Salt = Salt();

print <<ENDHTML;
		<td width='50%' valign='top' align='center'>
			<h2 style="text-align: center;">Configuration Status</h2>
			<table>
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
					<td>&nbsp;</td>
					<td>&nbsp;</td>
				</tr>
				<tr>
					<td style="text-align: right;">Sudoers Build File Ownership</td>
					<td style='color: #00FF00;'>$Owner ($Owner_ID)</td>
				</tr>
				<tr>
					<td style="text-align: right;">Sudoers Build File Group Ownership</td>
					<td style='color: #00FF00;'>$Group ($Group_ID)</td>
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
					<td style="text-align: right;">Password Salt Generation Test</td>
					<td style='color: #00FF00;'>$Salt</td>
				</tr>
			</table>
		</td>

ENDHTML
} # html_configuration

sub html_end {
print <<ENDHTML;
		</tr>
	</table>
ENDHTML
} # html_end
