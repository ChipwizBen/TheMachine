#!/usr/bin/perl -T

use strict;
use Digest::SHA qw(sha512_hex);

require './common.pl';
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $Message_Red;
my $Message_Green;

my $User_Name = $Session->param("User_Name");  

if ($User_Name eq '') {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Old_Password = $CGI->param("Old_Password");
my $New_Password = $CGI->param("New_Password");
my $Confirm_Password = $CGI->param("Confirm_Password");

my $Key_Name = $CGI->param("Key_Name");
my $Key_Lock = $CGI->param("Key_Lock");
	if ($Key_Lock) {
		if ($Key_Lock =~ /^(.+)$/) {$Key_Lock = $1;}
		else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Key_Lock, $User_Name);}
	}
my $Key_User_Name = $CGI->param("Key_User_Name");
my $Key_Passphrase = $CGI->param("Key_Passphrase");
my $Private_Key = $CGI->param("Private_Key");
my $Default_Key = $CGI->param("Default_Key");
my $Delete_Key = $CGI->param("Delete_Key");


if ($New_Password) {
	&change_password;
}
elsif ($Key_Name && $Key_Lock && $Private_Key) {
	&add_key;
}
elsif ($Delete_Key) {
	&delete_key;
}
elsif ($Default_Key) {
	&default_key;
}

require "./header.cgi";
&html_output;
require "./footer.cgi";

sub change_password {

	### Password Complexity Check ###
	my $Complexity_Check = Password_Complexity_Check($New_Password);
	if ($Complexity_Check == 1) {
		my $Message_Red="Password does not meet minimum length requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /account.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 2) {
		my $Message_Red="Password does not meet the minimum upper case character requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /account.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 3) {
		my $Message_Red="Password does not meet the minimum lower case character requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /account.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 4) {
		my $Message_Red="Password does not meet minimum digit requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /account.cgi\n\n";
		exit(0);
	}
	elsif ($Complexity_Check == 5) {
		my $Message_Red="Password does not meet minimum special character requirements. 
		Password requirements are show on the <a href='system-status.cgi'>System Status</a> page.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /account.cgi\n\n";
		exit(0);
	}
	### / Password Complexity Check ###

	my $Select_User_Name = $DB_Connection->prepare("SELECT `id`, `username`, `password`, `salt`, `email`
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

		if ($Password ne $Old_Password) {
			$Message_Red="Old password does not match.";
		}
		elsif ($New_Password ne $Confirm_Password) {
			$Message_Red="New passwords do not match.";
		}
		elsif (($Old_Password eq $Password) && ($New_Password ne '') && ($New_Password eq $Confirm_Password)) {

			# Audit Log
			my $Audit_Log_Submission = Audit_Log_Submission();
		
			$Audit_Log_Submission->execute("Account Management", "Modify", "$User_Name changed their own password.", $User_Name);
			#/ Audit Log

			$Message_Green="Password successfully changed.";
		
			my $Change_Password = $DB_Connection->prepare("UPDATE `credentials` SET
			`password` = ?,
			`salt` = ?,
			`last_modified` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
			$Change_Password->execute($New_Password, $New_Salt, $User_Name, $ID);

		}

	}

} #sub change_password

sub add_key {

	my $New_Salt;
	while (length $Key_Lock < 256) {
		my $Salt = Salt(1);
		$Salt =~ /(.*)/;
		if ($Salt =~ /^(.+)$/) {$Salt = $1;}
		$New_Salt = $New_Salt . $Salt;
		$Key_Lock =~ s/\s//g;
		$Key_Lock = $Key_Lock . $Salt;
	}

	$Private_Key =~ s/\r//g;

	use Crypt::CBC;

	my $Cipher_One = Crypt::CBC->new(
		-key	=> $Key_Lock,
		-cipher	=> 'DES',
		-salt	=> 1
	);

	my $Cipher_Two = Crypt::CBC->new(
		-key	=> $Key_Lock,
		-cipher	=> 'Rijndael',
		-salt	=> 1
	);

	my $Encrypted_Key = $Cipher_One->encrypt($Private_Key);
		$Encrypted_Key = $Cipher_Two->encrypt($Encrypted_Key);

	if ($Key_Passphrase eq 'on') {$Key_Passphrase = 1} else {$Key_Passphrase = 0}

	my $Submit_Key = $DB_Connection->prepare("INSERT INTO `auth` (
	`key_owner`,
	`key_name`,
	`salt`,
	`key`,
	`key_username`,
	`key_passphrase`
	)
	VALUES (
		?, ?, ?, ?, ?, ?
	)");

	$Submit_Key->execute($User_Name, $Key_Name, $New_Salt, $Encrypted_Key, $Key_User_Name, $Key_Passphrase);

} # add_key

sub delete_key {

	my $Select_Key = $DB_Connection->prepare("SELECT `key_owner`
	FROM `auth`
	WHERE `id` = ?");

	$Select_Key->execute($Delete_Key);

	my $User_Name_Extract = $Select_Key->fetchrow_array();

	if ($User_Name_Extract eq '') {$User_Name_Extract = 'nobody'}
	if ($User_Name_Extract ne $User_Name) {

		my $Audit_Log_Submission = Audit_Log_Submission();
	
		$Audit_Log_Submission->execute("Account Management", "Delete", "$User_Name tried to delete a key belonging to $User_Name_Extract. You've been rumbled.", 'System');

		my $Message_Red="Nice try.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /account.cgi\n\n";
		exit(0);
	}
	else {
		my $Delete = $DB_Connection->prepare("DELETE from `auth`
			WHERE `id` = ?");
		
		$Delete->execute($Delete_Key);
	}

} # delete_key

sub default_key {

	my $Select_Key = $DB_Connection->prepare("SELECT `key_owner`
	FROM `auth`
	WHERE `id` = ?");

	$Select_Key->execute($Default_Key);

	my $User_Name_Extract = $Select_Key->fetchrow_array();

	if ($User_Name_Extract eq '') {$User_Name_Extract = 'nobody'}
	if ($User_Name_Extract ne $User_Name) {

		my $Audit_Log_Submission = Audit_Log_Submission();
	
		$Audit_Log_Submission->execute("Account Management", "Modify", "$User_Name tried to default a key belonging to $User_Name_Extract. You've been rumbled.", 'System');

		my $Message_Red="Nice try.";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /account.cgi\n\n";
		exit(0);
	}
	else {
		my $Clear_Defaults = $DB_Connection->prepare("UPDATE `auth` SET
				`default` = 0
				WHERE `key_owner` = ?");
		$Clear_Defaults->execute($User_Name);
	
		my $Default = $DB_Connection->prepare("UPDATE `auth` SET
				`default` = 1
				WHERE `id` = ?");
		$Default->execute($Default_Key);
	}

} # default_key

sub html_output {

	### Permissions Table

	my $Permissions_Table = new HTML::Table(
		-cols=>9,
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

	$Permissions_Table->addRow ("System Admin", "IP Admin", "Icinga Admin", 
		"D-Shell Admin", "DNS Admin", "Rev. Proxy Admin", "DSMS Admin", "Approver", "Requires Approval");
	$Permissions_Table->setRowClass (1, 'tbrow1');
	
	my $Select_Users = $DB_Connection->prepare("SELECT `email`, `last_login`, `last_active`,  `admin`, 
	`ip_admin`, `icinga_admin`, `dshell_admin`, `dns_admin`, `reverse_proxy_admin`, `dsms_admin`, `approver`, `requires_approval`, 
	`last_modified`
	FROM `credentials`
	WHERE `username` = ?");
	$Select_Users->execute($User_Name);
	$Permissions_Table->setRowClass(1, 'tbrow1');
	
	my $User_Row_Count=1;
	my $Email_Extract;
	my $Last_Login_Extract;
	my $Last_Active_Extract;
	my $Last_Modified_Extract;	
	while ( my @DB_User = $Select_Users->fetchrow_array() )
	{
	
		$User_Row_Count++;
	
		$Email_Extract = $DB_User[0];
		$Last_Login_Extract = $DB_User[1];
		$Last_Active_Extract = $DB_User[2];
		my $Admin_Extract = $DB_User[3];
		my $IP_Admin_Extract = $DB_User[4];
		my $Icinga_Admin_Extract = $DB_User[5];
		my $DShell_Admin_Extract = $DB_User[6];
		my $DNS_Admin_Extract = $DB_User[7];
		my $Reverse_Proxy_Admin_Extract = $DB_User[8];
		my $DSMS_Admin_Extract = $DB_User[9];
		my $Approver_Extract = $DB_User[10];
		my $Requires_Approval_Extract = $DB_User[11];
		$Last_Modified_Extract = $DB_User[12];
		
	
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
		if ($DShell_Admin_Extract == 1) {$DShell_Admin_Extract = "Yes";} else {$DShell_Admin_Extract = "No";}
		if ($DNS_Admin_Extract == 1) {$DNS_Admin_Extract = "Yes";} else {$DNS_Admin_Extract = "No";}
		if ($Reverse_Proxy_Admin_Extract == 1) {$Reverse_Proxy_Admin_Extract = "Yes";} else {$Reverse_Proxy_Admin_Extract = "No";}
		if ($DSMS_Admin_Extract == 1) {$DSMS_Admin_Extract = "Yes";} else {$DSMS_Admin_Extract = "No";}
		if ($Approver_Extract == 1) {$Approver_Extract = "Yes";} else {$Approver_Extract = "No";}
		if ($Requires_Approval_Extract == 1) {$Requires_Approval_Extract = "Yes";} else {$Requires_Approval_Extract = "No";}
		if ($Last_Login_Extract eq '0000-00-00 00:00:00') {$Last_Login_Extract = 'Never';}
		if ($Last_Active_Extract eq '0000-00-00 00:00:00') {$Last_Active_Extract = 'Never';}
	
		$Permissions_Table->addRow (
			$Admin_Extract,
			$IP_Admin_Extract,
			$Icinga_Admin_Extract,
			$DShell_Admin_Extract,
			$DNS_Admin_Extract,
			$Reverse_Proxy_Admin_Extract,
			$DSMS_Admin_Extract,
			$Approver_Extract,
			$Requires_Approval_Extract
		);
	
		if ($Admin_Extract eq 'Read-only') {
			$Permissions_Table->setCellClass ($User_Row_Count, 1, 'tbroworange');
		}
		elsif ($Admin_Extract eq 'Yes') {
			$Permissions_Table->setCellClass ($User_Row_Count, 1, 'tbrowred');
		}
	
		if ($IP_Admin_Extract eq 'Yes') {$Permissions_Table->setCellClass ($User_Row_Count, 2, 'tbroworange');}
		if ($Icinga_Admin_Extract eq 'Yes') {$Permissions_Table->setCellClass ($User_Row_Count, 3, 'tbroworange');}
		if ($DShell_Admin_Extract eq 'Yes') {$Permissions_Table->setCellClass ($User_Row_Count, 4, 'tbroworange');}
		if ($DNS_Admin_Extract eq 'Yes') {$Permissions_Table->setCellClass ($User_Row_Count, 5, 'tbroworange');}
		if ($Reverse_Proxy_Admin_Extract eq 'Yes') {$Permissions_Table->setCellClass ($User_Row_Count, 6, 'tbroworange');}
		if ($DSMS_Admin_Extract eq 'Yes') {$Permissions_Table->setCellClass ($User_Row_Count, 7, 'tbroworange');}
	
		if ($Approver_Extract eq 'Yes') {$Permissions_Table->setCellClass ($User_Row_Count, 8, 'tbrowpurple');}
	
		if ($Requires_Approval_Extract eq 'Yes') {
			$Permissions_Table->setCellClass ($User_Row_Count, 9, 'tbrowgreen');
		}
		else {
			$Permissions_Table->setCellClass ($User_Row_Count, 9, 'tbrowred');
		}
		
		for (1 .. 9) {
			$Permissions_Table->setColWidth($_, '1px');
		}
	
		for (1 .. 9) {
			$Permissions_Table->setColAlign($_, 'center');
		}
	
	
	}

	### Audit Table

	my $Audit_Table = new HTML::Table(
		-cols=>5,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);


	my $Select_Logs = $DB_Connection->prepare("SELECT `category`, `method`, `action`, `time`, `username`
		FROM `audit_log`
		WHERE `username` LIKE ?
		ORDER BY `id` DESC
		LIMIT 0 , 30");

	$Select_Logs->execute($User_Name);

	$Audit_Table->addRow( "Category", "Method", "Action", "Time", "User" );
	$Audit_Table->setRowClass (1, 'tbrow1');

	while ( my @Select_Logs = $Select_Logs->fetchrow_array() )
	{
	
		my $Category = $Select_Logs[0];
		my $Method = $Select_Logs[1];
			my $Method_Clean = $Method;
		my $Action = $Select_Logs[2];
			$Action =~ s/</&lt;/g;
			$Action =~ s/>/&gt;/g;
			$Action =~ s/  /&nbsp;&nbsp;/g;
			$Action =~ s/\r/<br \/>/g;
		my $User = $Select_Logs[3];
		my $Time = $Select_Logs[4];	

		$Audit_Table->addRow( $Category, $Method, $Action, $User, $Time );

		if ($Method_Clean eq 'Add') {
			$Audit_Table->setCellClass (-1, 2, 'tbrowgreen');
		}
		elsif ($Method_Clean eq 'Delete') {
			$Audit_Table->setCellClass (-1, 2, 'tbrowred');
		}
		elsif ($Method_Clean eq 'Modify') {
			$Audit_Table->setCellClass (-1, 2, 'tbroworange');
		}
		elsif ($Method_Clean eq 'Deployment Succeeded') {
			$Audit_Table->setCellClass (-1, 2, 'tbrowgreen');
		}
		elsif ($Method_Clean eq 'Deployment Failed') {
			$Audit_Table->setCellClass (-1, 2, 'tbrowred');
		}
		elsif ($Method_Clean eq 'Approve') {
			$Audit_Table->setCellClass (-1, 2, 'tbrowdarkgreen');
		}
		elsif ($Method_Clean eq 'Revoke') {
			$Audit_Table->setCellClass (-1, 2, 'tbrowred');
		}
		elsif ($Method_Clean eq 'Run') {
			$Audit_Table->setCellClass (-1, 2, 'tbrowgreen');
		}
		elsif ($Method_Clean eq 'Receive') {
			$Audit_Table->setCellClass (-1, 2, 'tbrowpurple');
		}
		elsif ($Method_Clean eq 'Queue') {
			$Audit_Table->setCellClass (-1, 2, 'tbrowyellow');
		}
		elsif ($Method_Clean eq 'Stop') {
			$Audit_Table->setCellClass (-1, 2, 'tbrowred');
		}

		$Audit_Table->setColWidth(4, '110px');
		$Audit_Table->setColWidth(5, '110px');

		$Audit_Table->setColAlign(1, 'center');
		$Audit_Table->setColAlign(2, 'center');
		$Audit_Table->setColAlign(4, 'center');
		$Audit_Table->setColAlign(5, 'center');


	}

	### Key Table

	my $Key_Table = new HTML::Table(
		-cols=>6,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);

	my $Select_Keys = $DB_Connection->prepare("SELECT `id`, `key_name`, `default`, `key_username`, `key_passphrase`, `last_modified`
		FROM `auth`
		WHERE `key_owner` LIKE ?
		ORDER BY `id` ASC");

	$Select_Keys->execute($User_Name);

	$Key_Table->addRow( "Name", "Username", "Passphrase", "Added", "Default", "Delete" );
	$Key_Table->setRowClass (1, 'tbrow1');

	my $Key_Count=0;
	while ( my @Keys = $Select_Keys->fetchrow_array() )
	{
		$Key_Count++;
		my $Key_ID = $Keys[0];
		my $Key_Name = $Keys[1];
		my $Key_Default = $Keys[2];
		my $Key_User_Name = $Keys[3];
		my $Passphrase = $Keys[4];
			if ($Passphrase) {$Passphrase = 'Set';}	else {$Passphrase = 'Not Set';}
		my $Last_Modified = $Keys[5];

		if ($Key_Default) {
			$Key_Default = "<img src=\"resources/imgs/green.png\" alt=\"Default Key\" >";
		}
		else {
			$Key_Default = "<a href='account.cgi?Default_Key=$Key_ID'><img src=\"resources/imgs/grey.png\" alt=\"Make Key Default\" ></a>";
		}

		$Key_Table->addRow(
			$Key_Name,
			$Key_User_Name,
			$Passphrase,
			$Last_Modified,
			$Key_Default,
			"<a href='account.cgi?Delete_Key=$Key_ID'><img src=\"resources/imgs/delete.png\" alt=\"Delete Key\" ></a>");

		if ($Passphrase eq 'Set') {
			$Key_Table->setCellClass (-1, 3, 'tbrowgreen');
		}
		else {
			$Key_Table->setCellClass (-1, 3, 'tbrowred');
		}
	}

		$Key_Table->setColWidth(3, '20px');
		$Key_Table->setColWidth(4, '110px');
		$Key_Table->setColWidth(5, '1px');
		$Key_Table->setColWidth(6, '1px');
			
		$Key_Table->setColAlign(3, 'center');
		$Key_Table->setColAlign(4, 'center');
		$Key_Table->setColAlign(5, 'center');
		$Key_Table->setColAlign(6, 'center');

	if ($Key_Count == 0) {$Key_Table = '<p align="center">You have no keys defined. Add some below.</p>'}

print <<ENDHTML;

<div class="block-nest">

	<div id="main-block">

		<p style="font-size:20px; font-weight:bold; text-align: center;">My Account</p>
			<table align="center">
				<tr>
					<td align="center" style="padding-left:10px; padding-right: 10px;">Email Address</td>
					<td align="center" style="padding-left:10px; padding-right: 10px;">Last Login</td>
					<td align="center" style="padding-left:10px; padding-right: 10px;">Last Active</td>
					<td align="center" style="padding-left:10px; padding-right: 10px;">Last Modified</td>
				</tr>
				<tr>
					<td align="center" style="padding-left:10px; padding-right: 10px;"><a href='mailto:$Email_Extract'>$Email_Extract</a></td>
					<td align="center" style="padding-left:10px; padding-right: 10px;">$Last_Login_Extract</td>
					<td align="center" style="padding-left:10px; padding-right: 10px;">$Last_Active_Extract</td>
					<td align="center" style="padding-left:10px; padding-right: 10px;">$Last_Modified_Extract</td>
				</tr>
			</table>
			<br />
		<p style="font-size:15px; font-weight:bold;">My Permissions</p>
			$Permissions_Table
			<br />
		<p style="font-size:15px; font-weight:bold;">My Latest Actions</p>
			$Audit_Table

		<br />

	</div> <!-- main-block -->

	<div class="vertical-nest">

		<div id="blue-block">
			<h3 align = "center">Change Login Password</h3>
			
			<p>Note that this is your local password - if you authenticated using LDAP changing your password here will have no effect on your login.</p> 
			
			<form action='account.cgi' method='post' >
			
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
			<div style="text-align: center"><input type=submit name='ok' value='Change Password'></div>
			<br />
			
			</form>
		</div> <!-- blue-block -->

		<div id="blue-block">
			
			<h3 align = "center">SSH Keys</h3>

			<h4 align = "center">Active Keys</h4>
			$Key_Table

			<hr width="50%">

			<h4 align = "center">Add New Key</h4>

			<form action='account.cgi' method='post' >
			
			<table align = "center">
				<tr>
					<td style="text-align: right;">Key Name:</td>
					<td style="text-align: left;"><input type='text' name='Key_Name' size='15' placeholder="Magic Key" required></td>
				</tr>
				<tr>
					<td style="text-align: right;">Key password (DB at rest encryption):</td>
					<td style="text-align: left;"><input type='password' name='Key_Lock' size='15' placeholder="" required></td>
				</tr>
				<tr>
					<td style="text-align: right;">Key username:</td>
					<td style="text-align: left;"><input type='text' name='Key_User_Name' size='15' placeholder="$User_Name" required></td>
				</tr>
				<tr>
					<td style="text-align: right;">Has passphrase on key:</td>
					<td style="text-align: left;"><input type='checkbox' name='Key_Passphrase'></td>
				</tr>
				<tr>
					<td style="text-align: right;">Private Key:</td>
					<td style="text-align: left;"><textarea name='Private_Key' required></textarea></td>
				</tr>
			</table>

			<hr width="50%">

			<div style="text-align: center"><input type=submit name='ok' value='Add New Key'></div>
			<br />
			
			</form>
		</div> <!-- blue-block -->

	</div> <!-- vertical-nest -->

</div> <!-- block-nest -->

ENDHTML

} #sub html_output