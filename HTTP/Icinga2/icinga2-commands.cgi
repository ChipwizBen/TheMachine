#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);

use HTML::Table;

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Command = $CGI->param("Add_Command");
my $Edit_Command = $CGI->param("Edit_Command");

my $Command_Add = $CGI->param("Command_Add");
my $Command_Line_Add = $CGI->param("Command_Line_Add");
my $Active_Add = $CGI->param("Active_Add");

my $Command_Edit_Post = $CGI->param("Command_Edit_Post");
my $Command_Edit = $CGI->param("Command_Edit");
my $Command_Line_Edit = $CGI->param("Command_Line_Edit");
my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Command = $CGI->param("Delete_Command");
my $Command_Delete_Post = $CGI->param("Command_Delete_Post");
my $Command_Delete = $CGI->param("Command_Delete");

my $Display_Config = $CGI->param("Display_Config");
my $Show_Linked = $CGI->param("Show_Linked");

my $Filter = $CGI->param("Filter");

my $User_Name = $Session->param("User_Name");
my $User_Admin = $Session->param("User_Admin");

my $Rows_Returned = $CGI->param("Rows_Returned");
	if ($Rows_Returned eq '') {
		$Rows_Returned='100';
	}

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

if ($User_Admin ne '1') {
	my $Message_Red = 'You do not have sufficient privileges to access that page.';
	$Session->param('Message_Red', $Message_Red);
	$Session->flush();
	print "Location: /index.cgi\n\n";
	exit(0);
}

if ($Add_Command) {
	require $Header;
	&html_output;
	&html_add_command;
}
elsif ($Command_Add && $Command_Add) {
	&add_command;
	if ($Active_Add) {
		my $Message_Green="$Command_Add ($Command_Add) added successfully and set active";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
	}
	else {
		my $Message_Orange="$Command_Add ($Command_Add) added successfully but set inactive";
		$Session->param('Message_Orange', $Message_Orange);
		$Session->flush();
	}
	
	print "Location: /Icinga/icinga2-commands.cgi\n\n";
	exit(0);
}
elsif ($Edit_Command) {
	require $Header;
	&html_output;
	require $Footer;
	&html_edit_command;
}
elsif ($Command_Edit_Post) {
	&edit_command;
	my $Message_Green="$Command_Edit ($Command_Edit) edited successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /Icinga/icinga2-commands.cgi\n\n";
	exit(0);
}
elsif ($Delete_Command) {
	require $Header;
	&html_output;
	require $Footer;
	&html_delete_command;
}
elsif ($Command_Delete_Post) {
	&delete_command;
	my $Message_Green="$Command_Delete deleted successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /Icinga/icinga2-commands.cgi\n\n";
	exit(0);
}
elsif ($Display_Config) {
	require $Header;
	&html_output;
	require $Footer;
	&html_display_config;
}
elsif ($Show_Linked) {
	require $Header;
	&html_output;
	require $Footer;
	&html_show_linked;
}
else {
	require $Header;
	&html_output;
	require $Footer;
}



sub html_add_command {

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/Icinga/icinga2-commands.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Command</h3>

<form action='/Icinga/icinga2-commands.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Command Name (Unique):</td>
		<td colspan="2"><input type='text' name='Command_Add' style="width: 400px;" maxlength='45' placeholder="Command Name" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Command:</td>
		<td colspan="2">
			<textarea name='Command_Line_Add' style="width: 400px;" maxlength='1000' placeholder="Command - Drag the bottom right of the box if you need more visual writing area"></textarea>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Active?:</td>
		<td style="text-align: left;"><input type="radio" name="Active_Add" value="1"> Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Add" value="0" checked> No</td>
	</tr>
</table>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Command'></div>
<br />
</form>

</div>

ENDHTML

} #sub html_add_command

sub add_command {

	my $Command_Insert_Check = $DB_Connection->prepare("SELECT `id`, `command_line`
	FROM `icinga2_command`
	WHERE `command_name` = ?");

	$Command_Insert_Check->execute($Command_Add);
	my $Command_Rows = $Command_Insert_Check->rows();

	if ($Command_Rows) {
		while ( my @DB_Command = $Command_Insert_Check->fetchrow_array() )
			{

			my $ID_Extract = $DB_Command[0];
			my $Command_Extract = $DB_Command[1];

			my $Message_Red="$Command_Add already exists (ID: $ID_Extract, Command: $Command_Extract)";
			$Session->param('Message_Red', $Message_Red);
			$Session->flush();
			print "Location: /Icinga/icinga2-commands.cgi\n\n";
			exit(0);

		}
	}
	else {
		my $Command_Insert = $DB_Connection->prepare("INSERT INTO `icinga2_command` (
			`id`,
			`command_name`,
			`command_line`,
			`active`,
			`last_modified`,
			`modified_by`
		)
		VALUES (
			NULL,
			?,
			?,
			?,
			NOW(),
			?
		)");

		$Command_Insert->execute($Command_Add, $Command_Line_Add, $Active_Add, $User_Name);
	}

} # sub add_command

sub html_edit_command {

	my $Select_Command = $DB_Connection->prepare("SELECT `command_name`, `command_line`, `active`
	FROM `icinga2_command`
	WHERE `id` = ?");
	$Select_Command->execute($Edit_Command);
	
	while ( my @DB_Command = $Select_Command->fetchrow_array() )
	{
	
		my $Command_Extract = $DB_Command[0];
		my $Command_Line_Extract = $DB_Command[1];
		my $Active_Extract = $DB_Command[2];

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/Icinga/icinga2-commands.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Editing Command <span style="color: #00FF00;">$Command_Extract</span></h3>

<form action='/Icinga/icinga2-commands.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Command Name:</td>
		<td colspan="2"><input type='text' name='Command_Edit' value='$Command_Extract' style="width: 400px;" maxlength='100' placeholder="Command Name" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Command:</td>
		<td colspan="2">
			<textarea name='Command_Line_Edit' style="width: 400px;" maxlength='1000' placeholder="Command - Drag the bottom right of the box if you need more visual writing area" required>$Command_Line_Extract</textarea>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Active?:</td>
ENDHTML

if ($Active_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="1" checked> Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="0"> No</td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="1"> Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="0" checked> No</td>
ENDHTML
}


print <<ENDHTML;
	</tr>
</table>

<input type='hidden' name='Command_Edit_Post' value='$Edit_Command'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Command'></div>

</form>

ENDHTML

	}
} # sub html_edit_command

sub edit_command {

	my $Command_Insert_Check = $DB_Connection->prepare("SELECT `id`, `command_line`
	FROM `icinga2_command`
	WHERE `command_name` = ?
	AND `id` != ?");

	$Command_Insert_Check->execute($Command_Edit, $Command_Edit_Post);
	my $Command_Rows = $Command_Insert_Check->rows();

	if ($Command_Rows) {
		while ( my @DB_Command = $Command_Insert_Check->fetchrow_array() )
			{

			my $ID_Extract = $DB_Command[0];
			my $Command_Extract = $DB_Command[1];

			my $Message_Red="$Command_Edit already exists - Conflicting Command ID (This entry): $Command_Edit_Post, Existing Command ID: $ID_Extract, Existing Command Command: $Command_Extract";
			$Session->param('Message_Red', $Message_Red);
			$Session->flush();
			print "Location: /Icinga/icinga2-commands.cgi\n\n";
			exit(0);

		}
	}
	else {

		my $Command_Update = $DB_Connection->prepare("UPDATE `icinga2_command` SET
			`command_name` = ?,
			`command_line` = ?,
			`active` = ?,
			`last_modified` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?"
		);
		
		$Command_Update->execute($Command_Edit, $Command_Line_Edit, $Active_Edit, $Command_Edit_Post, $User_Name)
	}

} # sub edit_command

sub html_delete_command {

	my $Select_Command = $DB_Connection->prepare("SELECT `command_name`, `command_line`
	FROM `icinga2_command`
	WHERE `id` = ?");
	$Select_Command->execute($Delete_Command);

	while ( my @DB_Command = $Select_Command->fetchrow_array() )
	{

		my $Command_Extract = $DB_Command[0];
		my $Command_Line_Extract = $DB_Command[1];

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/Icinga/icinga2-commands.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Command</h3>

<form action='/Icinga/icinga2-commands.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this command?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Command Name:</td>
		<td style="text-align: left; color: #00FF00;">$Command_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Command:</td>
		<td style="text-align: left; color: #00FF00;">$Command_Line_Extract</td>
	</tr>
</table>

<input type='hidden' name='Command_Delete_Post' value='$Delete_Command'>
<input type='hidden' name='Command_Delete' value='$Command_Extract'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Command'></div>

</form>

</div>

ENDHTML

	}
} # sub html_delete_command

sub delete_command {

	my $Delete = $DB_Connection->prepare("DELETE from `icinga2_command`
	WHERE `id` = ?");
	
	$Delete->execute($Command_Delete_Post);

} # sub delete_command

sub html_display_config {

	my $Select_Command = $DB_Connection->prepare("SELECT `command_name`, `command_line`, `active`, `last_modified`, `modified_by`
	FROM `icinga2_command`
	WHERE `id` = ?");
	$Select_Command->execute($Display_Config);
	
	while ( my @DB_Command = $Select_Command->fetchrow_array() )
	{
	
		my $Command_Extract = $DB_Command[0];
		my $Command_Line_Extract = $DB_Command[1];
		my $Active_Extract = $DB_Command[2];
		my $Last_Modified_Extract = $DB_Command[3];
		my $Modified_By_Extract = $DB_Command[4];

		if (!$Active_Extract) {
			$Active_Extract="<span style='color: #FF8A00;'>
			This command is not active, so this config will not be written. 
			Make this command active to use it in Icinga.</span>";
		}
		else {
			$Active_Extract="";
		}

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/Icinga/icinga2-commands.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Live Config for <span style="color: #00FF00;">$Command_Extract</span></h3>

<p>This config is automatically applied regularly. The config below illustrates how this command's config will be written.</p>
<p>$Active_Extract</p>
<div style="text-align: left;">
<code>
<table align = "center">
	<tr>
		<td colspan='3'>## Command ID: $Display_Config</td>
	</tr>
	<tr>
		<td colspan='3'>## Modified $Last_Modified_Extract by $Modified_By_Extract</td>
	</tr>
	<tr>
		<td colspan='3'>define command {</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>command_name</td>
		<td style='padding-left: 2em;'>$Command_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>command_line</td>
		<td style='padding-left: 2em;'>$Command_Line_Extract</td>
	</tr>
	<tr>
		<td colspan='3'>}</td>
	</tr>
</table>

</code>
</div>
<br />

</div>

ENDHTML

	}
} # sub html_display_config

sub html_show_linked {

	my $Command_Name;
	my $Command_Description;
	my $Select_Command_Name = $DB_Connection->prepare("SELECT `command_name`
	FROM `icinga2_command`
	WHERE `id` = ?");
	
		$Select_Command_Name->execute($Show_Linked);
		
		while ( my @DB_Command_Name = $Select_Command_Name->fetchrow_array() )
		{
			$Command_Description = $DB_Command_Name[0];
		}

	my $Table = new HTML::Table(
		-cols=>5,
		-align=>'center',
		-rules=>'all',
		-border=>0,
		-bgcolor=>'25aae1',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-class=>'statustable',
		-width=>'80%',
		-spacing=>0,
		-padding=>1 );

	$Table->addRow ( "Service ID", "Name", "Description", "Active Service?", "View Service" );
	$Table->setRowClass (1, 'tbrow1');

	my $Select_Service_Name = $DB_Connection->prepare("SELECT `id`, `config_name`, `service_description`, `active`
	FROM `icinga_service`
	WHERE `check_command` LIKE ?");
	$Select_Service_Name->execute("$Show_Linked!%");

		while ( my @DB_Service = $Select_Service_Name->fetchrow_array() )
		{

			my $Service_ID = $DB_Service[0];
			my $Service_Name = $DB_Service[1];
			my $Service_Description = $DB_Service[2];
			my $Service_Active = $DB_Service[3];

			if ($Service_Active) {$Service_Active = "<span style='color: #00FF00;'>Yes</span>"}
			else {$Service_Active = "<span style='color: #FF0000;'>No</span>"}

			my $View_Service = "<a href='/Icinga/icinga2-services.cgi?Filter=$Service_ID'><img src=\"/Resources/Images/forward.png\" alt=\"View Service $Service_Description\" ></a>";

			$Table->addRow ( "$Service_ID", "$Service_Name", "$Service_Description", "$Service_Active", "$View_Service" );

		}

		if ($Table->getTableRows == 1) {$Table = '<p>This command is not attached to any services</p>'}

print <<ENDHTML;
<div id="small-popup-box">
<a href="/Icinga/icinga2-commands.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Linked Services for <span style="color: #00FF00;">$Command_Description</span></h3>

$Table

</div>

ENDHTML

} # sub html_show_linked

sub html_output {

	my $Table = new HTML::Table(
		-cols=>10,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);


	$Table->addRow ( "ID", "Name", "Command", "Active", "Last Modified", "Modified By", "Linked", "View Config", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Select_Commands_Count = $DB_Connection->prepare("SELECT `id` FROM `icinga2_command`");
		$Select_Commands_Count->execute( );
		my $Total_Rows = $Select_Commands_Count->rows();	

	my $Select_Commands = $DB_Connection->prepare("SELECT `id`, `command_name`, `command_line`, `active`, `last_modified`, `modified_by`
	FROM `icinga2_command`
	WHERE (`id` LIKE ?
	OR `command_name` LIKE ?
	OR `command_line` LIKE ?)
	ORDER BY `command_name` ASC
	LIMIT ?, ?");

	$Select_Commands->execute("%$Filter%", "%$Filter%", "%$Filter%", 0, $Rows_Returned);
	my $Rows = $Select_Commands->rows();
	
	$Table->setRowClass(1, 'tbrow1');

	my $User_Row_Count=1;
	while ( my @DB_Command = $Select_Commands->fetchrow_array() )
	{
	
		$User_Row_Count++;
	
		my $ID_Extract = $DB_Command[0];
			my $ID_Extract_Display = $ID_Extract;
			$ID_Extract_Display =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Name_Extract = $DB_Command[1];
			my $Name = $Name_Extract;
			$Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Command_Extract = $DB_Command[2];
			$Command_Extract =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Active_Extract = $DB_Command[3];
		my $Last_Modified_Extract = $DB_Command[4];
		my $Modified_By_Extract = $DB_Command[5];

		if ($Active_Extract) {$Active_Extract='Yes';} else {$Active_Extract='No';}

		$Table->addRow(
			$ID_Extract_Display,
			$Name,
			$Command_Extract,
			$Active_Extract,
			$Last_Modified_Extract,
			$Modified_By_Extract,
			"<a href='/Icinga/icinga2-commands.cgi?Show_Linked=$ID_Extract'><img src='/Resources/Images/linked.png' alt='Show Linked Hosts/Services for $Name_Extract'></a>",
			"<a href='/Icinga/icinga2-commands.cgi?Display_Config=$ID_Extract'><img src='/Resources/Images/view-notes.png' alt='View Config for $Name_Extract'></a>",
			"<a href='/Icinga/icinga2-commands.cgi?Edit_Command=$ID_Extract'><img src='/Resources/Images/edit.png' alt='Edit $Name_Extract'></a>",
			"<a href='/Icinga/icinga2-commands.cgi?Delete_Command=$ID_Extract'><img src='/Resources/Images/delete.png' alt='Delete $Name_Extract'></a>"
		);

		for (4 .. 10) {
			$Table->setColWidth($_, '1px');
			$Table->setColAlign($_, 'center');
		}

		if ($Active_Extract eq 'Yes') {
			$Table->setCellClass ($User_Row_Count, 4, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($User_Row_Count, 4, 'tbroworange');
		}

	}

print <<ENDHTML;

<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/Icinga/icinga2-commands.cgi' method='post' >
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
			<form action='/Icinga/icinga2-commands.cgi' method='post' >
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
			<form action='/Icinga/icinga2-commands.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Command</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type='submit' name='Edit Command' value='Edit Command'></td>
					<td align="center">
						<select name='Edit_Command' style="width: 150px">
ENDHTML

						my $Command_List_Query = $DB_Connection->prepare("SELECT `id`, `command_name`
						FROM `icinga2_command`
						ORDER BY `command_name` ASC");
						$Command_List_Query->execute( );
						
						while ( (my $ID, my $DB_Command_Name) = my @Command_List_Query = $Command_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$DB_Command_Name</option>";
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

<p style="font-size:14px; font-weight:bold;">Icinga Commands | Commands Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML

} #sub html_output end
