#!/usr/bin/perl

use strict;
use Digest::SHA qw(sha512_hex);

require 'common.pl';
my $DB_Management = DB_Management();
my ($CGI, $Session, $Cookie) = CGI();

my $Message_Red;
my $Message_Green;

my $User_Name = $Session->param("User_Name");  

if ($User_Name eq '') {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Submit = $CGI->param("Submit");
my $Old_Password = $CGI->param("Old_Password");
my $New_Password = $CGI->param("New_Password");
my $Confirm_Password = $CGI->param("Confirm_Password");

if ($New_Password) {
	&change_password;
}
require "header.cgi";
&html_output;
require "footer.cgi";

sub change_password {

	### Password Complexity Check ###
	my $Complexity_Check = Password_Complexity_Check($New_Password);
	if ($Complexity_Check == 1) {
		my $Message_Red="Password does not meet minimum length requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /password-change.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 2) {
		my $Message_Red="Password does not meet the minimum upper case character requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /password-change.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 3) {
		my $Message_Red="Password does not meet the minimum lower case character requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /password-change.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 4) {
		my $Message_Red="Password does not meet minimum digit requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /password-change.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 5) {
		my $Message_Red="Password does not meet minimum special character requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /password-change.cgi\n\n";
		exit(0);
	}
	### / Password Complexity Check ###

	my $Select_User_Name = $DB_Management->prepare("SELECT `id`, `username`, `password`, `salt`, `email`
	FROM `credentials`
	WHERE `username` = ?
	");
	$Select_User_Name->execute($User_Name);

	while ( my ($ID, $User_Name, $Password, $Old_Salt, $Email) = $Select_User_Name->fetchrow_array( ) )
	{

		my $New_Salt = Salt(64);
		$Old_Password = $Old_Password . $Old_Salt;
		$New_Password = $New_Password .  $New_Salt;
		$Confirm_Password = $Confirm_Password . $New_Salt;

		$Old_Password = sha512_hex($Old_Password);
		$New_Password = sha512_hex($New_Password);
		$Confirm_Password = sha512_hex($Confirm_Password);

		if (($Submit ne '') && ($Password ne $Old_Password)) {
			$Message_Red="Old password does not match.";
		}
		elsif (($Submit ne '') && ($New_Password ne $Confirm_Password)) {
			$Message_Red="New passwords do not match.";
		}
		elsif (($Old_Password eq $Password) && ($New_Password ne '') && ($New_Password eq $Confirm_Password)) {

			# Audit Log
			my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
				`category`,
				`method`,
				`action`,
				`username`
			)
			VALUES (
				?, ?, ?, ?
			)");
		
			$Audit_Log_Submission->execute("Account Management", "Modify", "$User_Name changed their own password.", $User_Name);
			#/ Audit Log

			$Message_Green="Password successfully changed.";
		
			my $Change_Password = $DB_Management->prepare("UPDATE `credentials` SET
			`password` = ?,
			`salt` = ?,
			`last_modified` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
			$Change_Password->execute($New_Password, $New_Salt, $User_Name, $ID);

		}

	}

} #END sub change_password

sub html_output {

print <<ENDHTML;
<div id="body">

<div id ="tbmessagegreen">
	$Message_Green
</div> <!-- tbmessagegreen -->

<div id ="tbmessagered">
	$Message_Red
</div> <!-- tbmessagered -->

<div id="single-centre-block">
<h3>Change Login Password</h3>

<p>Note that this is your local password - if you authenticated using LDAP changing your password here will have no effect on your login.</p> 

<form action='password-change.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">User Name:</td>
		<td align = "left"><label> $User_Name</label></td>
	</tr>
	<tr>
		<td style="text-align: right;">Old Password:</td>
		<td style="text-align: right;"><input type='password' name='Old_Password' size='15' placeholder="Current Password" autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">New Password:</td>
		<td style="text-align: right;"><input type='password' name='New_Password' size='15' placeholder="New Password"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Confirm Password:</td>
		<td style="text-align: right;"><input type='password' name='Confirm_Password' size='15' placeholder="Confirm Password"></td>
	</tr>
</table>

<hr width="50%">
<input type='hidden' name='Submit' value='True'>
<div style="text-align: center"><input type=submit name='ok' value='Change Password'></div>
<br />

</form>
</div> <!-- single-centre-block -->

</div> <!-- body -->

ENDHTML

} #sub html_output end