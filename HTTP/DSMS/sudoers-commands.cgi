#!/usr/bin/perl -T

use strict;
use HTML::Table;
use Date::Parse qw(str2time);
use POSIX qw(strftime);

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Command = $CGI->param("Add_Command");
my $Edit_Command = $CGI->param("Edit_Command");

my $Command_Alias_Add = $CGI->param("Command_Alias_Add");
	$Command_Alias_Add =~ s/\W//g;
my $Command_Add = $CGI->param("Command_Add");
	$Command_Add =~ s/\n//g;
	$Command_Add =~ s/\r//g;
	$Command_Add =~ s/\\//g;
my $Expires_Toggle_Add = $CGI->param("Expires_Toggle_Add");
my $Expires_Date_Add = $CGI->param("Expires_Date_Add");
	$Expires_Date_Add =~ s/\s//g;
	$Expires_Date_Add =~ s/[^0-9\-]//g;
my $Active_Add = $CGI->param("Active_Add");

my $Edit_Command_Post = $CGI->param("Edit_Command_Post");
my $Command_Alias_Edit = $CGI->param("Command_Alias_Edit");
	$Command_Alias_Edit =~ s/\W//g;
my $Command_Edit = $CGI->param("Command_Edit");
	$Command_Edit =~ s/\n//g;
	$Command_Edit =~ s/\r//g;
	$Command_Edit =~ s/\\//g;
my $Expires_Toggle_Edit = $CGI->param("Expires_Toggle_Edit");
my $Expires_Date_Edit = $CGI->param("Expires_Date_Edit");
	$Expires_Date_Edit =~ s/\s//g;
	$Expires_Date_Edit =~ s/[^0-9\-]//g;
my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Command = $CGI->param("Delete_Command");
my $Delete_Command_Confirm = $CGI->param("Delete_Command_Confirm");
my $Command_Alias_Delete = $CGI->param("Command_Alias_Delete");

my $Show_Links = $CGI->param("Show_Links");
my $Show_Links_Name = $CGI->param("Show_Links_Name");

my $View_Notes = $CGI->param("View_Notes");
my $New_Note = $CGI->param("New_Note");
my $New_Note_ID = $CGI->param("New_Note_ID");

my $User_Name = $Session->param("User_Name");
my $User_DSMS_Admin = $Session->param("User_DSMS_Admin");
my $User_Approver = $Session->param("User_Approver");

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $Filter = $CGI->param("Filter");
my $ID_Filter = $CGI->param("ID_Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}

if ($Add_Command) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_add_command;
	}
}
elsif ($Command_Alias_Add && $Command_Add) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
	else {
		if ($Command_Add !~ m/^\//) {
			my $Message_Red="Your command did not contain a full path. Command not added.";
			$Session->param('Message_Red', $Message_Red);
			$Session->flush();
		}
		else {
			my $Command_ID = &add_command;
			my $Message_Green="$Command_Alias_Add ($Command_Add) added successfully as ID $Command_ID";
			$Session->param('Message_Green', $Message_Green);
			$Session->flush();
		}
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
}
elsif ($Edit_Command) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_edit_command;
	}
}
elsif ($Edit_Command_Post) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
	else {
		if ($Command_Edit !~ m/^\//) {
			my $Message_Red="Your command did not contact a full path. Command not edited.";
			$Session->param('Message_Red', $Message_Red);
			$Session->flush();
		}
		else {
			&edit_command;
			my $Message_Green="$Command_Alias_Edit ($Command_Edit) edited successfully";
			$Session->param('Message_Green', $Message_Green);
			$Session->flush();
		}
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
}
elsif ($Delete_Command) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_delete_command;
	}
}
elsif ($Delete_Command_Confirm) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
	else {
		&delete_command;
		my $Message_Green="$Command_Alias_Delete deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
}
elsif ($Show_Links) {
	require $Header;
	&html_output;
	require $Footer;
	&html_show_links;
}
elsif ($View_Notes) {
	require $Header;
	&html_output;
	require $Footer;
	&html_notes;
}
elsif ($New_Note && $New_Note_ID) {
	&add_note;
	require $Header;
	&html_output;
	require $Footer;
	$View_Notes = $New_Note_ID;
	&html_notes;
}
else {
	require $Header;
	&html_output;
	require $Footer;
}



sub html_add_command {

my $Date = strftime "%Y-%m-%d", localtime;

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/DSMS/sudoers-commands.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Command</h3>

<SCRIPT LANGUAGE="JavaScript"><!--
function Expire_Toggle() {
	if(document.Add_Commands.Expires_Toggle_Add.checked)
	{
		document.Add_Commands.Expires_Date_Add.disabled=false;
	}
	else
	{
		document.Add_Commands.Expires_Date_Add.disabled=true;
	}
}
//-->
</SCRIPT>

<form action='/DSMS/sudoers-commands.cgi' name='Add_Commands' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Command Alias:</td>
		<td colspan="4"><input type='text' name='Command_Alias_Add' style="width: 300px" maxlength='128' placeholder="Command Alias" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Command:</td>
		<td colspan="4"><textarea name='Command_Add' style="width: 300px; height: 150px" maxlength='1000' placeholder="Command" required></textarea></td>
	</tr>
	<tr>
		<td style="text-align: right;">Expires:</td>
		<td><input type="checkbox" onclick="Expire_Toggle()" name="Expires_Toggle_Add"></td>
		<td colspan="3"><input type="text" style="width: 100%" name="Expires_Date_Add" value="$Date" placeholder="YYYY-MM-DD" disabled></td>
	</tr>
	<tr>
				<td style="text-align: right;">Active:</td>
		<td style="text-align: right;"><input type="radio" name="Active_Add" value="1" checked> Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Add" value="0"> No</td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Command Aliases must be unique and contain only a-z, A-Z, 0-9 and _ characters.</li>
<li>Commands must be unique.</li>
<li>Commands take only full paths (e.g. <i>/sbin/service</i> instead of just <i>service</i>).</li>
<li>Do not use spaces  or none alphanumeric characters in the Alias - they will be stripped.</li>
<li>Commands with an expiry set are automatically removed from sudoers at 23:59:59
(or the next sudoers refresh thereafter) on the day of expiry. Expired entries are functionally
equivalent to inactive entries. The date entry format is YYYY-MM-DD.</li>
<li>Active commands are eligible for sudoers inclusion.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Command'></div>

</form>

ENDHTML

} #sub html_add_command

sub add_command {

	### Existing Command_Alias Check
	my $Existing_Command_Alias_Check = $DB_Connection->prepare("SELECT `id`, `command`
		FROM `commands`
		WHERE `command_alias` = ?");
		$Existing_Command_Alias_Check->execute($Command_Alias_Add);
		my $Existing_Commands = $Existing_Command_Alias_Check->rows();

	if ($Existing_Commands > 0)  {
		my $Existing_ID;
		my $Existing_Command;
		while ( my @Select_Command_Alias = $Existing_Command_Alias_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Command_Alias[0];
			$Existing_Command = $Select_Command_Alias[1];
		}
		my $Message_Red="Command Alias: $Command_Alias_Add already exists as ID: $Existing_ID, Command: $Existing_Command";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
	### / Existing Command_Alias Check

	### Existing Command Check
	my $Existing_Command_Check = $DB_Connection->prepare("SELECT `id`, `command_alias`
		FROM `commands`
		WHERE `command` = ?");
		$Existing_Command_Check->execute($Command_Add);
		my $Existing_Command_Alias = $Existing_Command_Check->rows();

	if ($Existing_Command_Alias > 0)  {
		my $Existing_ID;
		my $Existing_Command_Aliases;
		while ( my @Select_Commands = $Existing_Command_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Commands[0];
			$Existing_Command_Aliases = $Select_Commands[1];
		}
		my $Message_Red="Command: $Command_Add already exists as ID: $Existing_ID, Command Alias: $Existing_Command_Aliases";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
	### / Existing Command Check

	if ($Expires_Toggle_Add ne 'on') {
		$Expires_Date_Add = '0000-00-00';
	}

	my $Command_Insert = $DB_Connection->prepare("INSERT INTO `commands` (
		`id`,
		`command_alias`,
		`command`,
		`expires`,
		`active`,
		`modified_by`
	)
	VALUES (
		NULL,
		?,
		?,
		?,
		?,
		?
	)");

	$Command_Insert->execute($Command_Alias_Add, $Command_Add, $Expires_Date_Add, $Active_Add, $User_Name);

	my $Command_Insert_ID = $DB_Connection->{mysql_insertid};

	# Audit Log
	if ($Expires_Date_Add eq '0000-00-00') {
		$Expires_Date_Add = 'not expire';
	}
	else {
		$Expires_Date_Add = "expire on " . $Expires_Date_Add;
	}

	if ($Active_Add) {$Active_Add = 'Active'} else {$Active_Add = 'Inactive'}

	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();
	
	$Audit_Log_Submission->execute("Commands", "Add", "$User_Name added $Command_Alias_Add ($Command_Add), set it $Active_Add and to $Expires_Date_Add. The system assigned it Command ID $Command_Insert_ID.", $User_Name);
	# / Audit Log

	return($Command_Insert_ID);

} # sub add_command

sub html_edit_command {

	my $Select_Command = $DB_Connection->prepare("SELECT `command_alias`, `command`, `expires`, `active`
	FROM `commands`
	WHERE `id` = ?");
	$Select_Command->execute($Edit_Command);
	
	while ( my @DB_Command = $Select_Command->fetchrow_array() )
	{
	
		my $Command_Alias_Extract = $DB_Command[0];
		my $Command_Extract = $DB_Command[1];
		my $Expires_Extract = $DB_Command[2];
		my $Active_Extract = $DB_Command[3];

		my $Checked;
		my $Disabled;
		if ($Expires_Extract eq '0000-00-00') {
			$Checked = '';
			$Disabled = 'disabled';
			$Expires_Extract = strftime "%Y-%m-%d", localtime;
		}
		else {
			$Checked = 'checked';
			$Disabled = '';
		}

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/DSMS/sudoers-commands.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Command</h3>

<SCRIPT LANGUAGE="JavaScript"><!--
function Expire_Toggle() {
	if(document.Edit_Commands.Expires_Toggle_Edit.checked)
	{
		document.Edit_Commands.Expires_Date_Edit.disabled=false;
	}
	else
	{
		document.Edit_Commands.Expires_Date_Edit.disabled=true;
	}
}
//-->
</SCRIPT>

<form action='/DSMS/sudoers-commands.cgi' name='Edit_Commands' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Command Alias:</td>
		<td colspan="4"><input type='text' name='Command_Alias_Edit' value='$Command_Alias_Extract' style="width: 300px" maxlength='128' placeholder="$Command_Alias_Extract" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Command:</td>
		<td colspan="4"><textarea name='Command_Edit' style="width: 300px; height: 150px" maxlength='1000' placeholder="$Command_Extract" required>$Command_Extract</textarea></td>
	</tr>
	<tr>
		<td style="text-align: right;">Expires:</td>
		<td><input type="checkbox" onclick="Expire_Toggle()" name="Expires_Toggle_Edit" $Checked></td>
		<td colspan="3"><input type="text" style="width: 100%" name="Expires_Date_Edit" value="$Expires_Extract" placeholder="$Expires_Extract" $Disabled></td>
	</tr>
	<tr>
		<td style="text-align: right;">Active:</td>
ENDHTML

if ($Active_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="1" checked>Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="0">No</td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="1">Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="0" checked>No</td>
ENDHTML
}

print <<ENDHTML;
	</tr>
	</tr>
</table>

<input type='hidden' name='Edit_Command_Post' value='$Edit_Command'>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Command Aliases must be unique and contain only a-z, A-Z, 0-9 and _ characters.</li>
<li>Commands must be unique.</li>
<li>Commands take only full paths (e.g. <i>/sbin/service</i> instead of just <i>service</i>).</li>
<li>Do not use spaces  or none alphanumeric characters in the Alias - they will be stripped.</li>
<li>You can only activate a modified command if you are an Approver. If you are not an Approver and you modify this entry, it will automatically be set to Inactive.</li>
<li>Commands with an expiry set are automatically removed from sudoers at 23:59:59
(or the next sudoers refresh thereafter) on the day of expiry. Expired entries are functionally
equivalent to inactive entries. The date entry format is YYYY-MM-DD.</li>
<li>Active commands are eligible for sudoers inclusion.</li>
</ul>
<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Command'></div>

</form>

ENDHTML

	}
} # sub html_edit_command

sub edit_command {

	### Existing Command_Alias Check
	my $Existing_Command_Alias_Check = $DB_Connection->prepare("SELECT `id`, `command`
		FROM `commands`
		WHERE `command_alias` = ?
		AND `id` != ?");
		$Existing_Command_Alias_Check->execute($Command_Alias_Edit, $Edit_Command_Post);
		my $Existing_Commands = $Existing_Command_Alias_Check->rows();

	if ($Existing_Commands > 0)  {
		my $Existing_ID;
		my $Existing_Command;
		while ( my @Select_Command_Aliass = $Existing_Command_Alias_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Command_Aliass[0];
			$Existing_Command = $Select_Command_Aliass[1];
		}
		my $Message_Red="Command Alias: $Command_Alias_Edit already exists as ID: $Existing_ID, Command: $Existing_Command";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
	### / Existing Command_Alias Check

	### Existing Command Check
	my $Existing_Command_Check = $DB_Connection->prepare("SELECT `id`, `command_alias`
		FROM `commands`
		WHERE `command` = ?
		AND `id` != ?");
		$Existing_Command_Check->execute($Command_Edit, $Edit_Command_Post);
		my $Existing_Command_Alias = $Existing_Command_Check->rows();

	if ($Existing_Command_Alias > 0)  {
		my $Existing_ID;
		my $Existing_Command_Alias;
		while ( my @Select_Commands = $Existing_Command_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Commands[0];
			$Existing_Command_Alias = $Select_Commands[1];
		}
		my $Message_Red="Command: '$Command_Edit' already exists as ID: $Existing_ID, Command_Alias: $Existing_Command_Alias";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-commands.cgi\n\n";
		exit(0);
	}
	### / Existing Command Check

	### Revoke Rule Approval ###

	my $Update_Rule = $DB_Connection->prepare("UPDATE `rules`
	INNER JOIN `lnk_rules_to_commands`
	ON `rules`.`id` = `lnk_rules_to_commands`.`rule`
	SET
	`modified_by` = '$User_Name',
	`approved` = '0',
	`approved_by` = 'Approval Revoked by $User_Name when modifying Command ID $Edit_Command_Post'
	WHERE `lnk_rules_to_commands`.`command` = ?");

	my $Rules_Revoked = $Update_Rule->execute($Edit_Command_Post);

	if ($Rules_Revoked eq '0E0') {$Rules_Revoked = 0}

	### / Revoke Rule Approval ###

	if ($Expires_Toggle_Edit ne 'on') {
		$Expires_Date_Edit = '0000-00-00';
	}

	my $Update_Command = $DB_Connection->prepare("UPDATE `commands` SET
		`command_alias` = ?,
		`command` = ?,
		`expires` = ?,
		`active` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		
	$Update_Command->execute($Command_Alias_Edit, $Command_Edit, $Expires_Date_Edit, $Active_Edit, $User_Name, $Edit_Command_Post);

	# Audit Log
	if ($Expires_Date_Edit eq '0000-00-00') {
		$Expires_Date_Edit = 'does not expire';
	}
	else {
		$Expires_Date_Edit = "expires on " . $Expires_Date_Edit;
	}

	if ($Active_Edit) {$Active_Edit = 'Active'} else {$Active_Edit = 'Inactive'}

	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();

	if ($Rules_Revoked > 0) {
		$Audit_Log_Submission->execute("Rules", "Revoke", "$User_Name modified Command ID $Edit_Command_Post, which caused the revocation of $Rules_Revoked Rules to protect the integrity of remote systems.", $User_Name);
	}
	$Audit_Log_Submission->execute("Commands", "Modify", "$User_Name modified Command ID $Edit_Command_Post. The new entry is recorded as $Command_Alias_Edit ($Command_Edit), set $Active_Edit and $Expires_Date_Edit.", $User_Name);
	# / Audit Log

} # sub edit_command

sub html_delete_command {

	my $Select_Command = $DB_Connection->prepare("SELECT `command_alias`, `command`
	FROM `commands`
	WHERE `id` = ?");

	$Select_Command->execute($Delete_Command);
	
	while ( my @DB_Command = $Select_Command->fetchrow_array() )
	{
	
		my $Command_Alias_Extract = $DB_Command[0];
		my $Command_Extract = $DB_Command[1];

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/DSMS/sudoers-commands.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Command</h3>

<form action='/DSMS/sudoers-commands.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this command?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Command Alias:</td>
		<td style="text-align: left; color: #00FF00;">$Command_Alias_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Command:</td>
		<td style="text-align: left; color: #00FF00;">$Command_Extract</td>
	</tr>
</table>

<input type='hidden' name='Delete_Command_Confirm' value='$Delete_Command'>
<input type='hidden' name='Command_Alias_Delete' value='$Command_Alias_Extract'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Command'></div>

</form>

ENDHTML

	}
} # sub html_delete_command

sub delete_command {

	### Revoke Rule Approval ###

	my $Update_Rule = $DB_Connection->prepare("UPDATE `rules`
	INNER JOIN `lnk_rules_to_commands`
	ON `rules`.`id` = `lnk_rules_to_commands`.`rule`
	SET
	`modified_by` = '$User_Name',
	`approved` = '0',
	`approved_by` = 'Approval Revoked by $User_Name when deleting Command ID $Delete_Command_Confirm'
	WHERE `lnk_rules_to_commands`.`command` = ?");

	my $Rules_Revoked = $Update_Rule->execute($Delete_Command_Confirm);

	if ($Rules_Revoked eq '0E0') {$Rules_Revoked = 0}

	### / Revoke Rule Approval ###

	# Audit Log
	my $Select_Commands = $DB_Connection->prepare("SELECT `command_alias`, `command`, `expires`, `active`
		FROM `commands`
		WHERE `id` = ?");

	$Select_Commands->execute($Delete_Command_Confirm);

	while (( my $Command_Alias, my $Command, my $Expires, my $Active ) = $Select_Commands->fetchrow_array() )
	{

		if ($Expires eq '0000-00-00') {
			$Expires = 'does not expire';
		}
		else {
			$Expires = "expires on " . $Expires;
		}
	
		if ($Active) {$Active = 'Active'} else {$Active = 'Inactive'}
	
		my $DB_Connection = DB_Connection();
		my $Audit_Log_Submission = Audit_Log_Submission();

		if ($Rules_Revoked > 0) {
			$Audit_Log_Submission->execute("Rules", "Revoke", "$User_Name deleted Command ID $Delete_Command_Confirm, which caused the revocation of $Rules_Revoked Rules to protect the integrity of remote systems.", $User_Name);
		}
		$Audit_Log_Submission->execute("Commands", "Delete", "$User_Name deleted Command ID $Delete_Command_Confirm. The deleted entry's last values were $Command_Alias ($Command), set $Active and $Expires.", $User_Name);

	}
	# / Audit Log

	my $Delete_Command = $DB_Connection->prepare("DELETE from `commands`
		WHERE `id` = ?");
	
	$Delete_Command->execute($Delete_Command_Confirm);

	my $Delete_Command_From_Groups = $DB_Connection->prepare("DELETE from `lnk_command_groups_to_commands`
			WHERE `command` = ?");
		
	$Delete_Command_From_Groups->execute($Delete_Command_Confirm);

	my $Delete_Command_From_Rules = $DB_Connection->prepare("DELETE from `lnk_rules_to_commands`
			WHERE `command` = ?");
		
	$Delete_Command_From_Rules->execute($Delete_Command_Confirm);

} # sub delete_command

sub html_show_links {

	my $Counter;

	my $Table = new HTML::Table(
		-cols=>4,
                -align=>'center',
                -border=>0,
                -rules=>'cols',
                -evenrowclass=>'tbeven',
                -oddrowclass=>'tbodd',
                -width=>'90%',
                -spacing=>0,
                -padding=>1
	);

	$Table->addRow( "#", "Category", "Name", "Status", "View" );
	$Table->setRowClass (1, 'tbrow1');

	### Command Groups

	my $Select_Group_Links = $DB_Connection->prepare("SELECT `group`
		FROM `lnk_command_groups_to_commands`
		WHERE `command` = ?"
	);
	$Select_Group_Links->execute($Show_Links);

	while ( my @Select_Links = $Select_Group_Links->fetchrow_array() )
	{
		
		my $Group_ID = $Select_Links[0];

		my $Select_Groups = $DB_Connection->prepare("SELECT `groupname`, `active`
			FROM `command_groups`
			WHERE `id` = ?"
		);
		$Select_Groups->execute($Group_ID);

		while ( my @Select_Group_Array = $Select_Groups->fetchrow_array() )
		{

			my $Group = $Select_Group_Array[0];
			my $Active = $Select_Group_Array[1];

			if ($Active) {$Active = "Active"} else {$Active = "<span style='color: #FF0000'>Inactive</span>"}

			$Counter++;

			$Table->addRow(
			"$Counter",
			"Command Group",
			"$Group",
			"$Active",
			"<a href='/DSMS/sudoers-command-groups.cgi?ID_Filter=$Group_ID'><img src=\"/resources/imgs/forward.png\" alt=\"View $Group\" ></a>"
			);
		}
	}

	### Rules

	my $Select_Links = $DB_Connection->prepare("SELECT `rule`
		FROM `lnk_rules_to_commands`
		WHERE `command` = ?"
	);
	$Select_Links->execute($Show_Links);

	while ( my @Select_Links = $Select_Links->fetchrow_array() )
	{
		
		my $Rule_ID = $Select_Links[0];

		my $Select_Rules = $DB_Connection->prepare("SELECT `name`, `active`, `approved`
			FROM `rules`
			WHERE `id` = ?"
		);
		$Select_Rules->execute($Rule_ID);

		while ( my @Select_Rule_Array = $Select_Rules->fetchrow_array() )
		{

			my $Name = $Select_Rule_Array[0];
			my $Active = $Select_Rule_Array[1];
			my $Approved = $Select_Rule_Array[2];

			if ($Active) {$Active = "Active"} else {$Active = "<span style='color: #FF0000'>Inactive</span>"}
			if ($Approved) {$Approved = "Approved"} else {$Approved = "<span style='color: #FF0000'>Unapproved</span>"}

			$Counter++;

			$Table->addRow(
			"$Counter",
			"Rule",
			"$Name",
			"$Active<br />$Approved",
			"<a href='/DSMS/sudoers-rules.cgi?ID_Filter=$Rule_ID'><img src=\"/resources/imgs/forward.png\" alt=\"View $Name\" ></a>"
			);
		}
	}

if ($Counter eq undef) {$Counter = 0};

print <<ENDHTML;

<div id="wide-popup-box">
<a href="/DSMS/sudoers-commands.cgi">
<div id="blockclosebutton">
</div>
</a>

<h2 style="text-align: center; font-weight: bold;">Items linked to $Show_Links_Name</h2>

<p>There are <span style="color: #00FF00;">$Counter</span> items linked to $Show_Links_Name.</p>

$Table

ENDHTML

} # sub html_show_links

sub html_notes {

	my $Table = new HTML::Table(
		-cols=>4,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'90%',
		-spacing=>0,
		-padding=>1
	);

	$Table->addRow( "#", "Note", "Time", "Added By");
	$Table->setRowClass (1, 'tbrow1');

	### Discover Command Name
	my $Command_Name;
	my $Select_Command_Name = $DB_Connection->prepare("SELECT `command_alias`
	FROM `commands`
	WHERE `id` = ?");

	$Select_Command_Name->execute($View_Notes);
	$Command_Name = $Select_Command_Name->fetchrow_array();
	### / Discover Command Name

	### Discover Note Count
	my $Select_Note_Count = $DB_Connection->prepare("SELECT COUNT(*)
		FROM `notes`
		WHERE `type_id` = '05'
		AND `item_id` = ?"
	);
	$Select_Note_Count->execute($View_Notes);
	my $Note_Count = $Select_Note_Count->fetchrow_array();
	### / Discover Note Count

	my $Select_Notes = $DB_Connection->prepare("SELECT `note`, `last_modified`, `modified_by`
	FROM `notes`
	WHERE `type_id` = '05'
	AND `item_id` = ?
	ORDER BY `last_modified` DESC");

	$Select_Notes->execute($View_Notes);

	my $Row_Count=$Note_Count;
	while ( my @Notes = $Select_Notes->fetchrow_array() )
	{
		my $Note = $Notes[0];
		my $Last_Modified = $Notes[1];
		my $Modified_By = $Notes[2];
		
		$Table->addRow($Row_Count, $Note, $Last_Modified, $Modified_By);
		$Row_Count--;
	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(3, '110px');
	$Table->setColWidth(4, '110px');

	$Table->setColAlign(1, 'center');
	$Table->setColAlign(3, 'center');
	$Table->setColAlign(4, 'center');

	if ($Note_Count == 0) {
		undef $Table;
		undef $Note_Count;
	}
	else {
		$Note_Count = "$Note_Count existing notes found, latest first."
	}

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/DSMS/sudoers-commands.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Notes for $Command_Name</h3>
<form action='/DSMS/sudoers-commands.cgi' method='post'>

<table align='center'>
	<tr>
		<td><textarea name='New_Note' placeholder='Add a new note' autofocus></textarea></td>
	</tr>
	<tr>
		<td><div style="text-align: center"><input type='submit' name='Submit' value='Submit New Note'></div></td>
	</tr>
</table>

<hr width="50%">

<input type='hidden' name='New_Note_ID' value='$View_Notes'>
</form>

<p>$Note_Count</p>

$Table

ENDHTML

} # sub html_notes

sub add_note {

	my $Note_Submission = $DB_Connection->prepare("INSERT INTO `notes` (
		`type_id`,
		`item_id`,
		`note`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?
	)");
	$Note_Submission->execute(05, $New_Note_ID, $New_Note, $User_Name);

} # sub add_note

sub html_output {

	my $Table = new HTML::Table(
		-cols=>11,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);

	my $Select_Command_Count = $DB_Connection->prepare("SELECT `id` FROM `commands`");
		$Select_Command_Count->execute( );
		my $Total_Rows = $Select_Command_Count->rows();


	my $Select_Commands = $DB_Connection->prepare("SELECT `id`, `command_alias`, `command`, `expires`, `active`, `last_modified`, `modified_by`
		FROM `commands`
			WHERE `id` LIKE ?
			OR `command_alias` LIKE ?
			OR `command` LIKE ?
			OR `expires` LIKE ?
		ORDER BY `command_alias` ASC
		LIMIT ?, ?"
	);

	if ($ID_Filter) {
		$Select_Commands->execute($ID_Filter, '', '', '', 0, $Rows_Returned);
	}
	else {
		$Select_Commands->execute("%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", 0, $Rows_Returned);
	}

	my $Rows = $Select_Commands->rows();

	$Table->addRow( "ID", "Command Alias", "Command", "Expires", "Active", "Last Modified", "Modified By", "Show Links", "Notes", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Command_Row_Count=1;

	while ( my @Select_Commands = $Select_Commands->fetchrow_array() )
	{

		$Command_Row_Count++;

		my $DBID = $Select_Commands[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($ID_Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Command_Alias = $Select_Commands[1];
			my $Command_Alias_Clean = $Command_Alias;
			$Command_Alias =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Command = $Select_Commands[2];
			$Command =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
			$Command =~ s/(\*)/<span style='background-color: #FF0000'>$1<\/span>/gi;
		my $Expires = $Select_Commands[3];
			my $Expires_Clean = $Expires;
			$Expires =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Active = $Select_Commands[4];
			if ($Active == 1) {$Active = "Yes"} else {$Active = "No"};
		my $Last_Modified = $Select_Commands[5];
		my $Modified_By = $Select_Commands[6];

		### Discover Note Count

		my $Select_Note_Count = $DB_Connection->prepare("SELECT COUNT(*)
			FROM `notes`
			WHERE `type_id` = '05'
			AND `item_id` = ?"
		);
		$Select_Note_Count->execute($DBID_Clean);
		my $Note_Count = $Select_Note_Count->fetchrow_array();

		### / Discover Note Count

		my $Expires_Epoch;
		my $Today_Epoch = time;
		if ($Expires_Clean =~ /^0000-00-00$/) {
			$Expires = 'Never';
		}
		else {
			$Expires_Epoch = str2time("$Expires_Clean"."T23:59:59");
		}

		$Table->addRow(
			"$DBID",
			"$Command_Alias",
			"$Command",
			"$Expires",
			"$Active",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/DSMS/sudoers-commands.cgi?Show_Links=$DBID_Clean&Show_Links_Name=$Command_Alias_Clean'><img src=\"/resources/imgs/linked.png\" alt=\"Linked Objects to Command ID $DBID_Clean\" ></a>",
			"<a href='/DSMS/sudoers-commands.cgi?View_Notes=$DBID_Clean'>
				<div style='position: relative; background: url(\"/resources/imgs/view-notes.png\") no-repeat; width: 22px; height: 22px;'> 
					<p style='position: absolute; width: 22px; text-align: center; font-weight: bold; color: #FF0000;'>
						$Note_Count
					</p>
				</div>
			</a>",
			"<a href='/DSMS/sudoers-commands.cgi?Edit_Command=$DBID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Command ID $DBID_Clean\" ></a>",
			"<a href='/DSMS/sudoers-commands.cgi?Delete_Command=$DBID_Clean'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Command ID $DBID_Clean\" ></a>"
		);


		if ($Active eq 'Yes') {
			$Table->setCellClass ($Command_Row_Count, 5, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($Command_Row_Count, 5, 'tbrowred');
		}

		if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
			$Table->setCellClass ($Command_Row_Count, 4, 'tbrowdarkgrey');
		}

	}


	$Table->setColWidth(1, '1px');
	$Table->setColWidth(4, '60px');
	$Table->setColWidth(5, '1px');
	$Table->setColWidth(6, '110px');
	$Table->setColWidth(7, '110px');
	$Table->setColWidth(8, '1px');
	$Table->setColWidth(9, '1px');
	$Table->setColWidth(10, '1px');
	$Table->setColWidth(11, '1px');

	$Table->setColAlign(1, 'center');

	for (4 .. 11) {
		$Table->setColAlign($_, 'center');
	}


print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/DSMS/sudoers-commands.cgi' method='post' >
				<tr>
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
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">
						Filter:
					</td>
					<td style="text-align: right;">
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Commands" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/DSMS/sudoers-commands.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Command</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Command' value='Add Command'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/DSMS/sudoers-commands.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Command</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Command' value='Edit Command'></td>
					<td align="center">
						<select name='Edit_Command' style="width: 150px">
ENDHTML

						my $Command_List_Query = $DB_Connection->prepare("SELECT `id`, `command_alias`
						FROM `commands`
						ORDER BY `command_alias` ASC");
						$Command_List_Query->execute( );
						
						while ( (my $ID, my $Command_Alias) = my @Command_List_Query = $Command_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Command_Alias</option>";
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

<p style="font-size:14px; font-weight:bold;">Commands | Commands Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output