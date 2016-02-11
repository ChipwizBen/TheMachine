#!/usr/bin/perl

use strict;
use HTML::Table;
use Date::Parse qw(str2time);
use POSIX qw(strftime);

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_DShell = DB_DShell();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Command = $CGI->param("Add_Command");
	my $Command_Name_Add = $CGI->param("Command_Name_Add");
	my $Command_Add = $CGI->param("Command_Add");
	my $Description_Add = $CGI->param("Description_Add");

my $Edit_Command = $CGI->param("Edit_Command");
my $Edit_Command_Post = $CGI->param("Edit_Command_Post");
	my $Command_Name_Edit = $CGI->param("Command_Name_Edit");
	my $Command_Edit = $CGI->param("Command_Edit");
	my $Description_Edit = $CGI->param("Description_Edit");

my $Delete_Command = $CGI->param("Delete_Command");
my $Delete_Command_Confirm = $CGI->param("Delete_Command_Confirm");
my $Command_Delete = $CGI->param("Command_Delete");

my $User_Name = $Session->param("User_Name");
my $User_DShell_Admin = $Session->param("User_DShell_Admin");

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $Filter = $CGI->param("Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}

if ($Add_Command) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_add_command;
	}
}
elsif ($Command_Add) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		my $Command_ID = &add_command;
		my $Message_Green="$Command_Add added successfully as ID $Command_ID";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
}
elsif ($Edit_Command) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
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
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		&edit_command;
		my $Message_Green="$Command_Edit edited successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
}
elsif ($Delete_Command) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
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
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
	else {
		&delete_command;
		my $Message_Green="$Command_Delete deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /D-Shell/command-sets.cgi\n\n";
		exit(0);
	}
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
<a href="/D-Shell/command-sets.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Command</h3>

<form action='/D-Shell/command-sets.cgi' name='Add_Command' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Name:</td>
		<td colspan="2"><input type='text' name='Command_Name_Add' style="width:100%" maxlength='128' placeholder="Update Command" required autofocus></td>
	<tr>
		<td style="text-align: right;">Command:</td>
		<td colspan="2"><textarea name="Command_Add" style="width: 300px; height: 150px" placeholder="Command Set" required=""></textarea></td>
	</tr>
	<tr>
		<td style="text-align: right;">Description:</td>
		<td colspan="2"><input type='text' name='Description_Add' style="width:100%" maxlength='1024' placeholder=""></td>
	<tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	You can give the processor special instructions by using these tags:
	<li><span style='color: #00FF00;'><#WAIT xx#></span> - Waits for xx seconds before processing the next command (e.g. <#WAIT 60#> to wait 60 seconds). Useful for waiting for machines to reboot.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Command'></div>

</form>

ENDHTML

} #sub html_add_command

sub add_command {

	my $Command_Insert = $DB_DShell->prepare("INSERT INTO `command_sets` (
		`name`,
		`command`,
		`description`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?
	)");

	$Command_Insert->execute($Command_Name_Add, $Command_Add, $Description_Add, $User_Name);

	my $Command_Insert_ID = $DB_DShell->{mysql_insertid};

	# Audit Log
	my $DB_Management = DB_Management();
	my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");
	
	$Audit_Log_Submission->execute("D-Shell", "Add", "$User_Name added $Command_Add. The system assigned it Command ID $Command_Insert_ID.", $User_Name);
	# / Audit Log

	return($Command_Insert_ID);

} # sub add_command

sub html_edit_command {

	my $Select_Command = $DB_DShell->prepare("SELECT `name`, `command`, `description`
	FROM `command_sets`
	WHERE `id` = ?");
	$Select_Command->execute($Edit_Command);

	while ( my @Commands = $Select_Command->fetchrow_array() )
	{
		my $Command_Name = $Commands[0];
		my $Command = $Commands[1];
		my $Description = $Commands[2];

print <<ENDHTML;

<div id="small-popup-box">
<a href="/D-Shell/command-sets.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Command</h3>

<form action='/D-Shell/command-sets.cgi' name='Edit_Commands' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Command:</td>
		<td colspan="2"><input type='text' name='Command_Name_Edit' value='$Command_Name' style="width:100%" maxlength='128' placeholder="$Command_Name" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Command:</td>
		<td colspan="2"><textarea name="Command_Edit" style="width: 300px; height: 150px" placeholder="$Command" required="">$Command</textarea></td>
	</tr>
	<tr>
		<td style="text-align: right;">Description:</td>
		<td colspan="2"><input type='text' name='Description_Edit' value='$Description' style="width:100%" maxlength='1024' placeholder="$Command_Name"></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	You can give the processor special instructions by using these tags:
	<li><span style='color: #00FF00;'><#WAIT xx#></span> - Waits for xx seconds before processing the next command (e.g. <#WAIT 60#> to wait 60 seconds). Useful for waiting for machines to reboot.</li>
</ul>

<hr width="50%">
<input type='hidden' name='Edit_Command_Post' value='$Edit_Command'>
<div style="text-align: center"><input type=submit name='ok' value='Edit Command'></div>

</form>

ENDHTML

	}
} # sub html_edit_command

sub edit_command {


	my $Update_Command = $DB_DShell->prepare("UPDATE `command_sets` SET
		`name` = ?,
		`command` = ?,
		`description` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		
	$Update_Command->execute($Command_Name_Edit, $Command_Edit, $Description_Edit, $User_Name, $Edit_Command_Post);

	# Audit Log
	my $DB_Management = DB_Management();
	my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");

	$Audit_Log_Submission->execute("D-Shell", "Modify", "$User_Name modified command ID $Edit_Command_Post. It is now recorded as $Command_Edit.", $User_Name);
	# / Audit Log

} # sub edit_command

sub html_delete_command {

	my $Select_Command = $DB_DShell->prepare("SELECT `command`
	FROM `command_sets`
	WHERE `id` = ?");

	$Select_Command->execute($Delete_Command);
	
	while ( my $Command_Extract = $Select_Command->fetchrow_array() )
	{


print <<ENDHTML;
<div id="small-popup-box">
<a href="/D-Shell/command-sets.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Command</h3>

<form action='/D-Shell/command-sets.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this command?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Command:</td>
		<td style="text-align: left; color: #00FF00;">$Command_Extract</td>
	</tr>
</table>

<input type='hidden' name='Delete_Command_Confirm' value='$Delete_Command'>
<input type='hidden' name='Command_Delete' value='$Command_Extract'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Command'></div>

</form>

ENDHTML

	}
} # sub html_delete_command

sub delete_command {

	# Audit Log
	my $Select_Commands = $DB_DShell->prepare("SELECT `command`
		FROM `command_sets`
		WHERE `id` = ?");

	$Select_Commands->execute($Delete_Command_Confirm);

	while ( my ( $Command_Extract ) = $Select_Commands->fetchrow_array() )
	{

		my $DB_Management = DB_Management();
		my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
			`category`,
			`method`,
			`action`,
			`username`
		)
		VALUES (
			?, ?, ?, ?
		)");

		$Audit_Log_Submission->execute("D-Shell", "Delete", "$User_Name deleted $Command_Extract, command ID $Delete_Command_Confirm.", $User_Name);

	}
	# / Audit Log

	my $Delete_Command = $DB_DShell->prepare("DELETE from `command_sets`
		WHERE `id` = ?");
	
	$Delete_Command->execute($Delete_Command_Confirm);

} # sub delete_command

sub html_output {

	my $Table = new HTML::Table(
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


	my $Select_Command_Count = $DB_DShell->prepare("SELECT `id` FROM `command_sets`");
		$Select_Command_Count->execute( );
		my $Total_Rows = $Select_Command_Count->rows();


	my $Select_Commands = $DB_DShell->prepare("SELECT `id`, `name`, `command`, `description`, `host_types`, `last_modified`, `modified_by`
		FROM `command_sets`
		WHERE `id` LIKE ?
		OR `name` LIKE ?
		OR `command` LIKE ?
		OR `description` LIKE ?
		ORDER BY `name` ASC
		LIMIT 0 , $Rows_Returned"
	);

	$Select_Commands->execute("%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%");

	my $Rows = $Select_Commands->rows();

	$Table->addRow( "ID", "Command Name", "Command", "Description", "Host Types", "Last Modified", "Modified By", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Command_Row_Count=1;

	while ( my @Select_Commands = $Select_Commands->fetchrow_array() )
	{

		$Command_Row_Count++;

		my $DBID = $Select_Commands[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Command_Name = $Select_Commands[1];
			$Command_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Command = $Select_Commands[2];
			$Command =~ s/\r/<br \/>/g;
			$Command =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Description = $Select_Commands[3];
			$Description =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Host_Types = $Select_Commands[4];
		my $Last_Modified = $Select_Commands[5];
		my $Modified_By = $Select_Commands[6];

		$Table->addRow(
			"$DBID",
			"$Command_Name",
			"$Command",
			"$Description",
			"$Host_Types",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/D-Shell/command-sets.cgi?Edit_Command=$DBID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Command ID $DBID_Clean\" ></a>",
			"<a href='/D-Shell/command-sets.cgi?Delete_Command=$DBID_Clean'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Command ID $DBID_Clean\" ></a>"
		);

	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(6, '110px');
	$Table->setColWidth(7, '110px');
	$Table->setColWidth(8, '1px');
	$Table->setColWidth(9, '1px');

	$Table->setColAlign(1, 'center');
	for (5..9) {
		$Table->setColAlign($_, 'center');
	}



print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/D-Shell/command-sets.cgi' method='post' >
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
			<form action='/D-Shell/command-sets.cgi' method='post' >
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
			<form action='/D-Shell/command-sets.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Command</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Command' value='Edit Command'></td>
					<td align="center">
						<select name='Edit_Command' style="width: 150px">
ENDHTML

						my $Command_List_Query = $DB_DShell->prepare("SELECT `id`, `command`
						FROM `command_sets`
						ORDER BY `command` ASC");
						$Command_List_Query->execute( );
						
						while ( my ($ID, $Command) = my @Command_List_Query = $Command_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Command</option>";
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

<p style="font-size:14px; font-weight:bold;">Command Sets | Commands Sets Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output