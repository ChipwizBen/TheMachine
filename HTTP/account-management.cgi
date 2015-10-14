#!/usr/bin/perl

use strict;
use Digest::SHA qw(sha512_hex);
use HTML::Table;

require 'common.pl';
my $DB_Management = DB_Management();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_User = $CGI->param("Add_User");
my $Edit_User = $CGI->param("Edit_User");

my $User_Name_Add = $CGI->param("User_Name_Add");
my $Password_Add = $CGI->param("Password_Add");
my $Email_Add = $CGI->param("Email_Add");
	$Email_Add =~ s/\s//g;
	$Email_Add =~ s/[^a-zA-Z0-9\-\.\_\+\@]//g;
my $Admin_Add = $CGI->param("Admin_Add");
my $IP_Admin_Add = $CGI->param("IP_Admin_Add");
my $Icinga_Admin_Add = $CGI->param("Icinga_Admin_Add");
my $BIND_Admin_Add = $CGI->param("BIND_Admin_Add");
my $Approver_Add = $CGI->param("Approver_Add");
my $Requires_Approval_Add = $CGI->param("Requires_Approval_Add");
my $Lockout_Add = $CGI->param("Lockout_Add");

my $Edit_User_Post = $CGI->param("Edit_User_Post");
my $User_Name_Edit = $CGI->param("User_Name_Edit");
my $Password_Edit = $CGI->param("Password_Edit");
my $Email_Edit = $CGI->param("Email_Edit");
	$Email_Edit =~ s/\s//g;
	$Email_Edit =~ s/[^a-zA-Z0-9\-\.\_\+\@]//g;
my $Admin_Edit = $CGI->param("Admin_Edit");
my $IP_Admin_Edit = $CGI->param("IP_Admin_Edit");
my $Icinga_Admin_Edit = $CGI->param("Icinga_Admin_Edit");
my $BIND_Admin_Edit = $CGI->param("BIND_Admin_Edit");
my $Approver_Edit = $CGI->param("Approver_Edit");
my $Requires_Approval_Edit = $CGI->param("Requires_Approval_Edit");
my $Lockout_Edit = $CGI->param("Lockout_Edit");

my $Delete_User = $CGI->param("Delete_User");
my $Delete_User_Confirm = $CGI->param("Delete_User_Confirm");
my $User_Name_Delete = $CGI->param("User_Name_Delete");

my $User_Name = $Session->param("User_Name"); #Accessing User_Name session var
my $User_Admin = $Session->param("User_Admin"); #Accessing User_Admin session var

my $Rows_Returned = $CGI->param("Rows_Returned");
	if ($Rows_Returned eq '') {
		$Rows_Returned='100';
	}

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

if ($User_Admin != 1) {
	my $Message_Red = 'You do not have sufficient privileges to access that page.';
	$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
	print "Location: /index.cgi\n\n";
	exit(0);
}

if ($Add_User) {
	require "header.cgi";
	&html_output;
	require "footer.cgi";
	&html_add_user;
}
elsif ($User_Name_Add && $Password_Add && $Email_Add) {
	&add_user;
	my $Message_Green="$User_Name_Add ($Email_Add) added successfully";
	$Session->param('Message_Green', $Message_Green); #Posting Message_Green session var
	print "Location: /account-management.cgi\n\n";
	exit(0);
}
elsif ($Edit_User) {
	require "header.cgi";
	&html_output;
	require "footer.cgi";
	&html_edit_user;
}
elsif ($Edit_User_Post) {
	&edit_user;
	my $Message_Green="$User_Name_Edit ($Email_Edit) edited successfully";
	$Session->param('Message_Green', $Message_Green); #Posting Message_Green session var
	print "Location: /account-management.cgi\n\n";
	exit(0);
}
elsif ($Delete_User) {
	require "header.cgi";
	&html_output;
	require "footer.cgi";
	&html_delete_user;
}
elsif ($Delete_User_Confirm) {
	&delete_user;
	my $Message_Green="$User_Name_Delete deleted successfully";
	$Session->param('Message_Green', $Message_Green); #Posting Message_Green session var
	print "Location: /account-management.cgi\n\n";
	exit(0);
}
else {
	require "header.cgi";
	&html_output;
	require "footer.cgi";
	exit(0);
}



sub html_add_user {

print <<ENDHTML;
<div id="wide-popup-box">
<a href="account-management.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Account</h3>

<form action='account-management.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">User Name:</td>
		<td colspan="6"><input type='text' name='User_Name_Add' style='width:250px;' maxlength='128' placeholder="First Last" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Password:</td>
		<td colspan="6"><input type='Password' name='Password_Add' style='width:250px;' required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Email:</td>
		<td colspan="6"><input type='Email' name='Email_Add' style='width:250px;' maxlength='128' placeholder="email\@domain.co.nz" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">System Administrator Privileges:</td>
		<td style="text-align: right;"><input type="radio" name="Admin_Add" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Admin_Add" value="0" checked></td>
		<td>No</td>
		<td style="text-align: right;"><input type="radio" name="Admin_Add" value="2"></td>
		<td>Read-only</td>
	</tr>
	<tr>
		<td style="text-align: right;">Can assign and unassign IP addresses:</td>
		<td style="text-align: right;"><input type="radio" name="IP_Admin_Add" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="IP_Admin_Add" value="0" checked></td>
		<td>No</td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td style="text-align: right;">Can modify Icinga:</td>
		<td style="text-align: right;"><input type="radio" name="Icinga_Admin_Add" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Icinga_Admin_Add" value="0" checked></td>
		<td>No</td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td style="text-align: right;">Can modify BIND:</td>
		<td style="text-align: right;"><input type="radio" name="BIND_Admin_Add" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="BIND_Admin_Add" value="0" checked></td>
		<td>No</td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td style="text-align: right;">Can Approve Rule Changes:</td>
		<td style="text-align: right;"><input type="radio" name="Approver_Add" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Approver_Add" value="0" checked></td>
		<td>No</td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td style="text-align: right;">Requires Rule Change Approval:</td>
		<td style="text-align: right;"><input type="radio" name="Requires_Approval_Add" value="1" checked></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Requires_Approval_Add" value="0"></td>
		<td>No</td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td style="text-align: right;">Locked Out:</td>
		<td style="text-align: right;"><input type="radio" name="Lockout_Add" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Lockout_Add" value="0" checked></td>
		<td>No</td>
		<td></td>
		<td></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>User Names and email addresses must be unique.</li>
	<li>View the minimum password requirements for this system on the <a href="system-status.cgi">System Status</a> 
		page.
	</li>
	<li>
		<i>System Administrator Privileges</i> allow a user to modify users and permissions, including their own, and view 
		the <b><a href='access-log.cgi'>Access Log</a></b>. Read-only Administrators can view Administrative 
		pages except the Account Management page, but cannot make any changes.
	</li>
	<li>
		<b>Note:</b> Setting <i>Can Approve Rule Changes</i> to <b>Yes</b> and setting <i>Requires Rule Change 
		Approval</i> to <b>Yes</b> means that rules created or modified by this user must also be approved by 
		another Approver.  A user that has <i>Can Approve Rule Changes</i> set to <b>Yes</b> and <i>Requires 
		Rule Change Approval</i> set to <b>No</b> have their changes automatically approved. Nobody can approve 
		their own rule changes if <i>Requires Rule Change Approval</i> is set to <b>Yes</b>. The user name 
		<i>System</i> is reserved and cannot be used.
	</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Account'></div>

</form>

ENDHTML

} #sub html_add_user

sub add_user {

	### Reserved User Name Check ###
	if ($User_Name_Add eq 'System' || $User_Name_Add eq 'system') {
		my $Message_Red="User Name '$User_Name_Add' is reserved for system use. Please use a different name.";
		$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
		print "Location: /account-management.cgi\n\n";
		exit(0);
	}
	### / Reserved User Name Check ###

	### Existing User_Name Check ###
	my $Existing_User_Name_Check = $DB_Management->prepare("SELECT `id`, `email`
		FROM `credentials`
		WHERE `username` = ?");
		$Existing_User_Name_Check->execute($User_Name_Add);
		my $Existing_User_Name_Count = $Existing_User_Name_Check->rows();

	if ($Existing_User_Name_Count > 0)  {
		my $Existing_ID;
		my $Existing_Email;
		while ( my @Select_User_Names = $Existing_User_Name_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_User_Names[0];
			$Existing_Email = $Select_User_Names[1];
		}
		my $Message_Red="User Name $User_Name_Add already exists as ID $Existing_ID, with email address $Existing_Email";
		$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
		print "Location: /account-management.cgi\n\n";
		exit(0);
	}
	### / Existing User_Name Check ###

	### Existing Email Check ###
	my $Existing_Email_Check = $DB_Management->prepare("SELECT `id`, `username`
		FROM `credentials`
		WHERE `email` = ?");
		$Existing_Email_Check->execute($Email_Add);
		my $Existing_User_Email_Count = $Existing_Email_Check->rows();

	if ($Existing_User_Email_Count > 0)  {
		my $Existing_ID;
		my $Existing_User;
		while ( my @Select_User_Names = $Existing_Email_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_User_Names[0];
			$Existing_User = $Select_User_Names[1];
		}
		my $Message_Red="User Email $Email_Add already exists as ID $Existing_ID, User Name: $Existing_User";
		$Session->param('Message_Red', $Message_Red);
		print "Location: /account-management.cgi\n\n";
		exit(0);
	}
	### / Existing Email Check ###

	### Password Complexity Check ###
	my $Complexity_Check = Password_Complexity_Check($Password_Add);
	if ($Complexity_Check == 1) {
		my $Message_Red="Password does not meet minimum length requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		print "Location: /account-management.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 2) {
		my $Message_Red="Password does not meet the minimum upper case character requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		print "Location: /account-management.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 3) {
		my $Message_Red="Password does not meet the minimum lower case character requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		print "Location: /account-management.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 4) {
		my $Message_Red="Password does not meet minimum digit requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		print "Location: /account-management.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 5) {
		my $Message_Red="Password does not meet minimum special character requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		print "Location: /account-management.cgi\n\n";
		exit(0);
	}
	### / Password Complexity Check ###

	my $Salt = Salt(64);
	$Password_Add = $Password_Add . $Salt;
	$Password_Add = sha512_hex($Password_Add);

	my $User_Insert = $DB_Management->prepare("INSERT INTO `credentials` (
		`id`,
		`username`,
		`password`,
		`salt`,
		`email`,
		`admin`,
		`ip_admin`,
		`icinga_admin`,
		`bind_admin`,
		`approver`,
		`requires_approval`,
		`lockout`,
		`last_login`,
		`last_active`,
		`lockout_counter`,
		`lockout_reset`,
		`last_modified`,
		`modified_by`
	)
	VALUES (
		NULL,
		?, ?, ?, ?,
		?, ?, ?, ?,
		?, ?, ?,
		'0000-00-00 00:00:00',
		'0000-00-00 00:00:00',
		0, 0,
		NOW(),
		?
	)");

	$User_Insert->execute(
	$User_Name_Add, $Password_Add, $Salt, $Email_Add, 
	$Admin_Add, $IP_Admin_Add, $Icinga_Admin_Add, $BIND_Admin_Add,
	$Approver_Add, $Requires_Approval_Add, 
	$Lockout_Add, $User_Name);

	# Audit Log
	if ($Admin_Add == 1) {
		$Admin_Add = 'has System Administrator Privileges';
	}
	elsif ($Admin_Add == 2) {
		$Admin_Add = 'has read-only System Administrator Privileges';
	}
	else {
		$Admin_Add = 'has no System Administrator Privileges';
	}

	if ($IP_Admin_Add == 1) {$IP_Admin_Add = 'can allocate IP addresses'} else {$IP_Admin_Add = 'cannot allocate IP addresses'}
	if ($Icinga_Admin_Add == 1) {$Icinga_Admin_Add = 'can edit Icinga'} else {$Icinga_Admin_Add = 'cannot edit Icinga'}
	if ($BIND_Admin_Add == 1) {$BIND_Admin_Add = 'can edit BIND'} else {$BIND_Admin_Add = 'cannot edit BIND'}

	if ($Approver_Add == 1) {$Approver_Add = "$User_Name_Add can Approve the Rules created by others"} else {$Approver_Add = "$User_Name_Add can not Approve the Rules created by others"}
	if ($Requires_Approval_Add == 1) {$Requires_Approval_Add = "$User_Name_Add"."'s "."Rules require approval"} else {$Requires_Approval_Add = "$User_Name_Add"."'s "."Rules do not require approval"}
	if ($Lockout_Add == 1) {$Lockout_Add = "$User_Name_Add is locked out"} else {$Lockout_Add = "$User_Name_Add is not locked out"}

	my $Account_Insert_ID = $DB_Management->{mysql_insertid};

	my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");

	$Audit_Log_Submission->execute("Account Management", "Add",
		"$User_Name added a new system account as Account ID $Account_Insert_ID: $User_Name_Add ($Email_Add). $User_Name_Add $Admin_Add, $Approver_Add, $Requires_Approval_Add and $Lockout_Add. $User_Name_Add $IP_Admin_Add, $Icinga_Admin_Add, and $BIND_Admin_Add.", $User_Name);
	#/ Audit Log

} # sub add_user

sub html_edit_user {

	my $Select_User = $DB_Management->prepare("SELECT `username`, `admin`, `ip_admin`, `icinga_admin`, `bind_admin`, `approver`, `requires_approval`, `lockout`, `last_modified`, `modified_by`, `email`
	FROM `credentials`
	WHERE `id` = ?");
	$Select_User->execute($Edit_User);
	
	while ( my @DB_User = $Select_User->fetchrow_array() )
	{
	
		my $User_Name_Extract = $DB_User[0];
		my $Admin_Extract = $DB_User[1];
		my $IP_Admin_Extract = $DB_User[2];
		my $Icinga_Admin_Extract = $DB_User[3];
		my $BIND_Admin_Extract = $DB_User[4];
		my $Approver_Extract = $DB_User[5];
		my $Requires_Approval_Extract = $DB_User[6];
		my $Lockout_Extract = $DB_User[7];
		my $Last_Modified_Extract = $DB_User[8];
		my $Modified_By_Extract = $DB_User[9];
		my $Email_Extract = $DB_User[10];

print <<ENDHTML;
<div id="wide-popup-box">
<a href="account-management.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Account</h3>

<form action='account-management.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">User Name:</td>
		<td colspan="6"><input type='text' name='User_Name_Edit' value='$User_Name_Extract' style='width:250px;' maxlength='128' placeholder="$User_Name_Extract" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Password:</td>
		<td colspan="6"><input type='password' name='Password_Edit' style='width:250px;'></td>
	</tr>
	<tr>
		<td style="text-align: right;">Email:</td>
		<td colspan="6"><input type='email' name='Email_Edit' value='$Email_Extract' style='width:250px;' maxlength='128' placeholder="$Email_Extract" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">System Administrator Privileges:</td>
ENDHTML

if ($Admin_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Admin_Edit" value="1" checked></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Admin_Edit" value="0"></td>
		<td>No</td>
		<td style="text-align: right;"><input type="radio" name="Admin_Edit" value="2"></td>
		<td>Read-only</td>
ENDHTML
}
elsif ($Admin_Extract == 2) {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Admin_Edit" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Admin_Edit" value="0"></td>
		<td>No</td>
		<td style="text-align: right;"><input type="radio" name="Admin_Edit" value="2" checked></td>
		<td>Read-only</td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Admin_Edit" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Admin_Edit" value="0" checked></td>
		<td>No</td>
		<td style="text-align: right;"><input type="radio" name="Admin_Edit" value="2"></td>
		<td>Read-only</td>
ENDHTML
}

print <<ENDHTML;
	</tr>
	<tr>
		<td style="text-align: right;">Can assign and unassign IP addresses:</td>
ENDHTML

if ($IP_Admin_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="IP_Admin_Edit" value="1" checked></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="IP_Admin_Edit" value="0"></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="IP_Admin_Edit" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="IP_Admin_Edit" value="0" checked></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}

print <<ENDHTML;
	</tr>
	<tr>
		<td style="text-align: right;">Can modify Icinga:</td>
ENDHTML

if ($Icinga_Admin_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Icinga_Admin_Edit" value="1" checked></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Icinga_Admin_Edit" value="0"></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Icinga_Admin_Edit" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Icinga_Admin_Edit" value="0" checked></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}

print <<ENDHTML;
	</tr>
	<tr>
		<td style="text-align: right;">Can modify BIND:</td>
ENDHTML

if ($BIND_Admin_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="BIND_Admin_Edit" value="1" checked></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="BIND_Admin_Edit" value="0"></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="BIND_Admin_Edit" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="BIND_Admin_Edit" value="0" checked></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}

print <<ENDHTML;
	</tr>
	<tr>
		<td style="text-align: right;">Can Approve Rule Changes:</td>
ENDHTML

if ($Approver_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Approver_Edit" value="1" checked></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Approver_Edit" value="0"></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Approver_Edit" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Approver_Edit" value="0" checked></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}


print <<ENDHTML;
	</tr>
	<tr>
		<td style="text-align: right;">Requires Rule Change Approval:</td>
ENDHTML

if ($Requires_Approval_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Requires_Approval_Edit" value="1" checked></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Requires_Approval_Edit" value="0"></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Requires_Approval_Edit" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Requires_Approval_Edit" value="0" checked></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}


print <<ENDHTML;
	</tr>
	<tr>
		<td style="text-align: right;">Locked Out:</td>
ENDHTML

if ($Lockout_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Lockout_Edit" value="1" checked></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Lockout_Edit" value="0"></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Lockout_Edit" value="1"></td>
		<td>Yes</td>
		<td style="text-align: right;"><input type="radio" name="Lockout_Edit" value="0" checked></td>
		<td>No</td>
		<td></td>
		<td></td>
ENDHTML
}

print <<ENDHTML;
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>User Names and email addresses must be unique.</li>
	<li>View the minimum password requirements for this system on the <a href="system-status.cgi">System Status</a> 
		page.
	</li>
	<li>
		<i>System Administrator Privileges</i> allow a user to modify users and permissions, including their own, and view 
		the <b><a href='access-log.cgi'>Access Log</a></b>. Read-only Administrators can view Administrative 
		pages except the Account Management page, but cannot make any changes.
	</li>
	<li>
		<b>Note:</b> Setting <i>Can Approve Rule Changes</i> to <b>Yes</b> and setting <i>Requires Rule Change 
		Approval</i> to <b>Yes</b> means that rules created or modified by this user must also be approved by 
		another Approver.  A user that has <i>Can Approve Rule Changes</i> set to <b>Yes</b> and <i>Requires 
		Rule Change Approval</i> set to <b>No</b> have their changes automatically approved. Nobody can approve 
		their own rule changes if <i>Requires Rule Change Approval</i> is set to <b>Yes</b>. The user name 
		<i>System</i> is reserved and cannot be used.
	</li>
</ul>

<input type='hidden' name='Edit_User_Post' value='$Edit_User'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Account'></div>

</form>

ENDHTML

	}
} # sub html_edit_user

sub edit_user {

	### Reserved User Name Check ###
	if ($User_Name_Edit eq 'System' || $User_Name_Add eq 'system') {
		my $Message_Red="User Name '$User_Name_Edit' is reserved for system use. Please use a different name.";
		$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
		print "Location: /account-management.cgi\n\n";
		exit(0);
	}
	### / Reserved User Name Check ###

	### Existing User_Name Check ###
	my $Existing_User_Name_Check = $DB_Management->prepare("SELECT `id`, `email`
		FROM `credentials`
		WHERE `username` = ?
		AND `id` != ?");
		$Existing_User_Name_Check->execute($User_Name_Edit, $Edit_User_Post);
		my $Existing_User_Name_Count = $Existing_User_Name_Check->rows();

	if ($Existing_User_Name_Count > 0)  {
		my $Existing_ID;
		my $Existing_Email;
		while ( my @Select_User_Names = $Existing_User_Name_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_User_Names[0];
			$Existing_Email = $Select_User_Names[1];
		}
		my $Message_Red="User Name $User_Name_Edit already exists as ID $Existing_ID, with email address $Existing_Email";
		$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
		print "Location: /account-management.cgi\n\n";
		exit(0);
	}
	### / Existing User_Name Check ###

	### Existing Email Check ###
	my $Existing_Email_Check = $DB_Management->prepare("SELECT `id`, `username`
		FROM `credentials`
		WHERE `email` = ?
		AND `id` != ?");
		$Existing_Email_Check->execute($Email_Edit, $Edit_User_Post);
		my $Existing_User_Email_Count = $Existing_Email_Check->rows();

	if ($Existing_User_Email_Count > 0)  {
		my $Existing_ID;
		my $Existing_User;
		while ( my @Select_User_Names = $Existing_Email_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_User_Names[0];
			$Existing_User = $Select_User_Names[1];
		}
		my $Message_Red="User Email $Email_Edit already exists as ID $Existing_ID, User Name: $Existing_User";
		$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
		print "Location: /account-management.cgi\n\n";
		exit(0);
	}
	### / Existing Email Check ###

	if ($User_Name_Edit eq $User_Name) {
		$Session->param('User_Admin', $Admin_Edit);
		$Session->param('User_IP_Admin', $IP_Admin_Edit);
		$Session->param('User_Icinga_Admin', $Icinga_Admin_Edit);
		$Session->param('User_BIND_Admin', $BIND_Admin_Edit);
		$Session->param('User_Email', $Email_Edit);
		$Session->param('User_Approver', $Approver_Edit);
		$Session->param('User_Requires_Approval', $Requires_Approval_Edit);
	}

	if ($Password_Edit) {

		### Password Complexity Check ###
		my $Complexity_Check = Password_Complexity_Check($Password_Edit);
		if ($Complexity_Check == 1) {
			my $Message_Red="Password does not meet minimum length requirements. 
			Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
			$Session->param('Message_Red', $Message_Red);
			print "Location: /account-management.cgi\n\n";
			exit(0);
		}
		elsif ($Complexity_Check == 2) {
			my $Message_Red="Password does not meet the minimum upper case character requirements. 
			Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
			$Session->param('Message_Red', $Message_Red);
			print "Location: /account-management.cgi\n\n";
			exit(0);
		}
		elsif ($Complexity_Check == 3) {
			my $Message_Red="Password does not meet the minimum lower case character requirements. 
			Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
			$Session->param('Message_Red', $Message_Red);
			print "Location: /account-management.cgi\n\n";
			exit(0);
		}
		elsif ($Complexity_Check == 4) {
			my $Message_Red="Password does not meet minimum digit requirements. 
			Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
			$Session->param('Message_Red', $Message_Red);
			print "Location: /account-management.cgi\n\n";
			exit(0);
		}
		elsif ($Complexity_Check == 5) {
			my $Message_Red="Password does not meet minimum special character requirements. 
			Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
			$Session->param('Message_Red', $Message_Red);
			print "Location: /account-management.cgi\n\n";
			exit(0);
		}
		### / Password Complexity Check ###

		my $Salt =  Salt(64);
		$Password_Edit = $Password_Edit . $Salt;
		$Password_Edit = sha512_hex($Password_Edit);

		my $Update_Credentials = $DB_Management->prepare("UPDATE `credentials` SET
			`username` = ?,
			`password` = ?,
			`salt` = ?,
			`email` = ?,
			`admin` = ?,
			`ip_admin` = ?,
			`icinga_admin` = ?,
			`bind_admin` = ?,
			`approver` = ?,
			`requires_approval` = ?,
			`lockout` = ?,
			`last_modified` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");

		$Update_Credentials->execute($User_Name_Edit, $Password_Edit, $Salt, $Email_Edit, $Admin_Edit,
			$IP_Admin_Edit, $Icinga_Admin_Edit, $BIND_Admin_Edit, $Approver_Edit, $Requires_Approval_Edit, 
			$Lockout_Edit, $User_Name, $Edit_User_Post);

		# Audit Log
		if ($Admin_Edit == 1) {
			$Admin_Edit = 'has System Administrator Privileges';
		}
		elsif ($Admin_Edit == 2) {
			$Admin_Edit = 'has read-only System Administrator Privileges';
		}
		else {
			$Admin_Edit = 'has no System Administrator Privileges';
		}

		if ($IP_Admin_Edit == 1) {$IP_Admin_Edit = 'can allocate IP addresses'} else {$IP_Admin_Edit = 'cannot allocate IP addresses'}
		if ($Icinga_Admin_Edit == 1) {$Icinga_Admin_Edit = 'can edit Icinga'} else {$Icinga_Admin_Edit = 'cannot edit Icinga'}
		if ($BIND_Admin_Edit == 1) {$BIND_Admin_Edit = 'can edit BIND'} else {$BIND_Admin_Edit = 'cannot edit BIND'}

		if ($Approver_Edit == 1) {$Approver_Edit = "$User_Name_Edit can Approve the Rules created by others"} else {$Approver_Edit = "$User_Name_Edit can not Approve the Rules created by others"}
		if ($Requires_Approval_Edit == 1) {$Requires_Approval_Edit = "$User_Name_Edit"."'s "."Rules require approval"} else {$Requires_Approval_Edit = "$User_Name_Edit"."'s "."Rules do not require approval"}
		if ($Lockout_Edit == 1) {$Lockout_Edit = "$User_Name_Edit is locked out"} else {$Lockout_Edit = "$User_Name_Edit is not locked out"}

		my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
			`category`,
			`method`,
			`action`,
			`username`
		)
		VALUES (
			?, ?, ?, ?
		)");

		$Audit_Log_Submission->execute("Account Management", "Modify",
			"$User_Name edited a system account with Account ID $Edit_User_Post: $User_Name_Edit ($Email_Edit). $User_Name_Edit $Admin_Edit, $Approver_Edit, $Requires_Approval_Edit and $Lockout_Edit. $User_Name_Edit $IP_Admin_Edit, $Icinga_Admin_Edit, and $BIND_Admin_Edit. $User_Name also changed $User_Name_Edit"."'s "."password.", $User_Name);
		#/ Audit Log

	}
	else {

		my $Update_Credentials = $DB_Management->prepare("UPDATE `credentials` SET
			`username` = ?,
			`email` = ?,
			`admin` = ?,
			`ip_admin` = ?,
			`icinga_admin` = ?,
			`bind_admin` = ?,
			`approver` = ?,
			`requires_approval` = ?,
			`lockout` = ?,
			`last_modified` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");

		$Update_Credentials->execute($User_Name_Edit, $Email_Edit, $Admin_Edit, 
			$IP_Admin_Edit, $Icinga_Admin_Edit, $BIND_Admin_Edit, $Approver_Edit, $Requires_Approval_Edit, 
			$Lockout_Edit, $User_Name, $Edit_User_Post);

		# Audit Log
		if ($Admin_Edit == 1) {
			$Admin_Edit = 'has System Administrator Privileges';
		}
		elsif ($Admin_Edit == 2) {
			$Admin_Edit = 'has read-only System Administrator Privileges';
		}
		else {
			$Admin_Edit = 'has no System Administrator Privileges';
		}

		if ($IP_Admin_Edit == 1) {$IP_Admin_Edit = 'can allocate IP addresses'} else {$IP_Admin_Edit = 'cannot allocate IP addresses'}
		if ($Icinga_Admin_Edit == 1) {$Icinga_Admin_Edit = 'can edit Icinga'} else {$Icinga_Admin_Edit = 'cannot edit Icinga'}
		if ($BIND_Admin_Edit == 1) {$BIND_Admin_Edit = 'can edit BIND'} else {$BIND_Admin_Edit = 'cannot edit BIND'}

		if ($Approver_Edit == 1) {$Approver_Edit = "$User_Name_Edit can Approve the Rules created by others"} else {$Approver_Edit = "$User_Name_Edit can not Approve the Rules created by others"}
		if ($Requires_Approval_Edit == 1) {$Requires_Approval_Edit = "$User_Name_Edit"."'s "."Rules require approval"} else {$Requires_Approval_Edit = "$User_Name_Edit"."'s "."Rules do not require approval"}
		if ($Lockout_Edit == 1) {$Lockout_Edit = "$User_Name_Edit is locked out"} else {$Lockout_Edit = "$User_Name_Edit is not locked out"}

		my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
			`category`,
			`method`,
			`action`,
			`username`
		)
		VALUES (
			?, ?, ?, ?
		)");

		$Audit_Log_Submission->execute("Account Management", "Modify",
			"$User_Name edited a system account with Account ID $Edit_User_Post: $User_Name_Edit ($Email_Edit). $User_Name_Edit $Admin_Edit, $Approver_Edit, $Requires_Approval_Edit and $Lockout_Edit. $User_Name_Edit $IP_Admin_Edit, $Icinga_Admin_Edit, and $BIND_Admin_Edit. $User_Name_Edit"."'s "."password was not changed.", $User_Name);
		#/ Audit Log

	}

} # sub edit_user

sub html_delete_user {

	my $Select_User = $DB_Management->prepare("SELECT `username`, `last_active`, `email`
	FROM `credentials`
	WHERE `id` = ?");

	$Select_User->execute($Delete_User);
	
	while ( my @DB_User = $Select_User->fetchrow_array() )
	{
	
		my $User_Name_Extract = $DB_User[0];
		my $Last_Active_Extract = $DB_User[1];
		my $Email_Extract = $DB_User[2];

		if ($Last_Active_Extract eq '0000-00-00 00:00:00') {
			$Last_Active_Extract = 'Never';
		}

print <<ENDHTML;
<div id="small-popup-box">
<a href="account-management.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Account</h3>

<form action='account-management.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this account?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">User Name:</td>
		<td style="text-align: left; color: #00FF00;">$User_Name_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Email:</td>
		<td style="text-align: left; color: #00FF00;">$Email_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Last Active:</td>
		<td style="text-align: left; color: #00FF00;">$Last_Active_Extract</td>
	</tr>
</table>

<input type='hidden' name='Delete_User_Confirm' value='$Delete_User'>
<input type='hidden' name='User_Name_Delete' value='$User_Name_Extract'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Account'></div>

</form>

ENDHTML

	}
} # sub html_delete_user

sub delete_user {

	# Audit Log
	my $Select_User = $DB_Management->prepare("SELECT `username`, `email`, `last_login`, `last_active`,  `admin`, `approver`, `requires_approval`, `lockout`
	FROM `credentials`
	WHERE `id` = ?");

	$Select_User->execute($Delete_User_Confirm);
	
	while ( my @DB_User = $Select_User->fetchrow_array() )
	{
	
		my $User_Name_Extract = $DB_User[0];
		my $Email_Extract = $DB_User[1];
		my $Last_Login_Extract = $DB_User[2];
		my $Last_Active_Extract = $DB_User[3];
		my $Admin_Extract = $DB_User[4];
		my $Approver_Extract = $DB_User[5];
		my $Requires_Approval_Extract = $DB_User[6];
		my $Lockout_Extract = $DB_User[7];

		if ($Admin_Extract) {$Admin_Extract = 'had System Administrator Privileges'} else {$Admin_Extract = 'had no System Administrator Privileges'}
		if ($Approver_Extract) {$Approver_Extract = "$User_Name_Extract could Approve the Rules created by others"} else {$Approver_Extract = "$User_Name_Extract could not Approve the Rules created by others"}
		if ($Requires_Approval_Extract) {$Requires_Approval_Extract = "$User_Name_Extract"."'s "."Rules required approval"} else {$Requires_Approval_Extract = "$User_Name_Extract"."'s "."Rules did not require approval"}
		if ($Lockout_Extract) {$Lockout_Extract = "$User_Name_Extract was locked out"} else {$Lockout_Extract = "$User_Name_Extract was not locked out"}

		my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
			`category`,
			`method`,
			`action`,
			`username`
		)
		VALUES (
			?, ?, ?, ?
		)");
	
		$Audit_Log_Submission->execute("Account Management", "Delete", "$User_Name deleted a system account with Account ID $Delete_User_Confirm: $User_Name_Extract ($Email_Extract). $User_Name_Extract $Admin_Extract, $Approver_Extract, $Requires_Approval_Extract and $Lockout_Extract.", $User_Name);
	}
	#/ Audit Log

	my $Delete_User = $DB_Management->prepare("DELETE from `credentials`
		WHERE `id` = ?");
	
	$Delete_User->execute($Delete_User_Confirm);

} # sub delete_user

sub html_output {

	my $Referer = $ENV{HTTP_REFERER};

	if ($Referer !~ /account-management.cgi/) {
		my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
			`category`,
			`method`,
			`action`,
			`username`
		)
		VALUES (
			?, ?, ?, ?
		)");
		
		$Audit_Log_Submission->execute("Account Management", "View", "$User_Name accessed Account Management.", $User_Name);
	}

my $Table = new HTML::Table(
	-cols=>15,
	-align=>'center',
	-border=>0,
	-rules=>'cols',
	-bgcolor=>'25aae1',
	-evenrowclass=>'tbeven',
	-oddrowclass=>'tbodd',
	-class=>'statustable',
	-width=>'100%',
	-spacing=>0,
	-padding=>1 );


$Table->addRow ( "User Name", "Email Address", "Last Login", "Last Active", "System Admin", "IP Admin", "Icinga Admin", "BIND Admin", "Approver", "Requires Approval", "Lockout", "Last Modified", "Modified By", "Edit", "Delete" );
$Table->setRowClass (1, 'tbrow1');

my $Select_Users = $DB_Management->prepare("SELECT `id`, `username`, `email`, `last_login`, `last_active`,  `admin`, `ip_admin`, `icinga_admin`, `bind_admin`, `approver`, `requires_approval`, `lockout`, `last_modified`, `modified_by`
FROM `credentials`
ORDER BY `last_active` DESC
LIMIT 0 , $Rows_Returned");
$Select_Users->execute( );
$Table->setRowClass(1, 'tbrow1');

my $User_Row_Count=1;
while ( my @DB_User = $Select_Users->fetchrow_array() )
{

	$User_Row_Count++;

	my $ID_Extract = $DB_User[0];
	my $User_Name_Extract = $DB_User[1];
	my $Email_Extract = $DB_User[2];
	my $Last_Login_Extract = $DB_User[3];
	my $Last_Active_Extract = $DB_User[4];
	my $Admin_Extract = $DB_User[5];
	my $IP_Admin_Extract = $DB_User[6];
	my $Icinga_Admin_Extract = $DB_User[7];
	my $BIND_Admin_Extract = $DB_User[8];
	my $Approver_Extract = $DB_User[9];
	my $Requires_Approval_Extract = $DB_User[10];
	my $Lockout_Extract = $DB_User[11];
	my $Last_Modified_Extract = $DB_User[12];
	my $Modified_By_Extract = $DB_User[13];
	

	if ($Admin_Extract == 1) {
		$Admin_Extract = "Yes";
	}
	elsif ($Admin_Extract == 2) {
		$Admin_Extract = "Read-only";
	}
	else {
		$Admin_Extract = "No";
	}

	if ($IP_Admin_Extract == 1) {$IP_Admin_Extract = "Yes";} else {$IP_Admin_Extract = "No";}
	if ($Icinga_Admin_Extract == 1) {$Icinga_Admin_Extract = "Yes";} else {$Icinga_Admin_Extract = "No";}
	if ($BIND_Admin_Extract == 1) {$BIND_Admin_Extract = "Yes";} else {$BIND_Admin_Extract = "No";}
	if ($Approver_Extract == 1) {$Approver_Extract = "Yes";} else {$Approver_Extract = "No";}
	if ($Requires_Approval_Extract == 1) {$Requires_Approval_Extract = "Yes";} else {$Requires_Approval_Extract = "No";}
	if ($Lockout_Extract == 1) {$Lockout_Extract = "Yes";} else {$Lockout_Extract = "No";}
	if ($Last_Login_Extract eq '0000-00-00 00:00:00') {$Last_Login_Extract = 'Never';}
	if ($Last_Active_Extract eq '0000-00-00 00:00:00') {$Last_Active_Extract = 'Never';}

	$Table->addRow(
		"<a href='account-management.cgi?Edit_User=$ID_Extract'>$User_Name_Extract</a>",
		"<a href='mailto:$Email_Extract'>$Email_Extract</a>",
		$Last_Login_Extract,
		$Last_Active_Extract,
		$Admin_Extract,
		$IP_Admin_Extract,
		$Icinga_Admin_Extract,
		$BIND_Admin_Extract,
		$Approver_Extract,
		$Requires_Approval_Extract,
		$Lockout_Extract,
		$Last_Modified_Extract,
		$Modified_By_Extract,
		"<a href='account-management.cgi?Edit_User=$ID_Extract'><img src=\"resources/imgs/edit.png\" alt=\"Edit $User_Name_Extract\" ></a>",
		"<a href='account-management.cgi?Delete_User=$ID_Extract'><img src=\"resources/imgs/delete.png\" alt=\"Delete $User_Name_Extract\" ></a>"
	);

	if ($Admin_Extract eq 'Read-only') {
		$Table->setCellClass ($User_Row_Count, 5, 'tbroworange');
	}
	elsif ($Admin_Extract eq 'Yes') {
		$Table->setCellClass ($User_Row_Count, 5, 'tbrowerror');
	}

	if ($IP_Admin_Extract eq 'Yes') {$Table->setCellClass ($User_Row_Count, 6, 'tbroworange');}
	if ($Icinga_Admin_Extract eq 'Yes') {$Table->setCellClass ($User_Row_Count, 7, 'tbroworange');}
	if ($BIND_Admin_Extract eq 'Yes') {$Table->setCellClass ($User_Row_Count, 8, 'tbroworange');}

	if ($Approver_Extract eq 'Yes') {$Table->setCellClass ($User_Row_Count, 9, 'tbrowpurple');}

	if ($Requires_Approval_Extract eq 'Yes') {
		$Table->setCellClass ($User_Row_Count, 10, 'tbrowgreen');
	}
	else {
		$Table->setCellClass ($User_Row_Count, 10, 'tbrowerror');
	}

	if ($Lockout_Extract eq 'Yes') {$Table->setCellClass ($User_Row_Count, 11, 'tbrowerror');}
	
	for (5 .. 11) {
		$Table->setColWidth($_, '1px');
	}
	$Table->setColWidth(14, '1px');
	$Table->setColWidth(15, '1px');

	for (3 .. 15) {
		$Table->setColAlign($_, 'center');
	}


}

print <<ENDHTML;

<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
				<tr>
					<form action='account-management.cgi' method='post' >
					<td style="text-align: right;">Returned Rows:</td>
					<td style="text-align: right;">
						<select name='Rows_Returned' onchange='this.form.submit()' style="width: 150px">
ENDHTML

if ($Rows_Returned == 100) {print "<option value=100 selected>100</option>";} else {print "<option value=100>100</option>";}
if ($Rows_Returned == 250) {print "<option value=250 selected>250</option>";} else {print "<option value=250>250</option>";}
if ($Rows_Returned == 500) {print "<option value=500 selected>500</option>";} else {print "<option value=500>500</option>";}
if ($Rows_Returned == 1000) {print "<option value=1000 selected>1000</option>";} else {print "<option value=1000>1000</option>";}
if ($Rows_Returned == 2500) {print "<option value=2500 selected>2500</option>";} else {print "<option value=2500>2500</option>";}
if ($Rows_Returned == 5000) {print "<option value=5000 selected>5000</option>";} else {print "<option value=5000>5000</option>";}
if ($Rows_Returned == 18446744073709551615) {print "<option value=18446744073709551615 selected>All</option>";} else {print "<option value=18446744073709551615>All</option>";}

print <<ENDHTML;
					</td>
					</form>
				</tr>
			</table>
		</td>
		<td align="center">
			<form action='account-management.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Account</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_User' value='Add Account'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='account-management.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Account</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit User' value='Edit Account'></td>
					<td align="center">
						<select name='Edit_User' style="width: 150px">
ENDHTML

						my $User_List_Query = $DB_Management->prepare("SELECT `id`, `username`
						FROM `credentials`
						ORDER BY `username` ASC");
						$User_List_Query->execute( );

						my $Rows = $User_List_Query->rows();
						
						while ( (my $ID, my $User) = my @User_List_Query = $User_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$User</option>";
						}

print <<ENDHTML;
						</select>
					</td>
				</tr>
			</table>
			</form>
		</td>
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">Account Management | Total Number of Accounts: $Rows</p>

$Table

ENDHTML

} #sub html_output end
