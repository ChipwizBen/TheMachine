#!/usr/bin/perl -T

use strict;
use lib qw(resources/modules/);
use lib qw(../resources/modules/);
use HTML::Table;

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Contact = $CGI->param("Add_Contact");
my $Edit_Contact = $CGI->param("Edit_Contact");

my $Contact_Add = $CGI->param("Contact_Add");
my $Alias_Add = $CGI->param("Alias_Add");
my $Email_Add = $CGI->param("Email_Add");
my $Host_Notification_Period_Add = $CGI->param("Host_Notification_Period_Add");
my $Service_Notification_Period_Add = $CGI->param("Service_Notification_Period_Add");
my $Host_Notification_Add_D = $CGI->param("Host_Notification_Add_D");
my $Host_Notification_Add_U = $CGI->param("Host_Notification_Add_U");
my $Host_Notification_Add_R = $CGI->param("Host_Notification_Add_R");
my $Host_Notification_Add_F = $CGI->param("Host_Notification_Add_F");
my $Host_Notification_Add_S = $CGI->param("Host_Notification_Add_S");
my $Service_Notification_Add_C = $CGI->param("Service_Notification_Add_C");
my $Service_Notification_Add_W = $CGI->param("Service_Notification_Add_W");
my $Service_Notification_Add_U = $CGI->param("Service_Notification_Add_U");
my $Service_Notification_Add_R = $CGI->param("Service_Notification_Add_R");
my $Service_Notification_Add_F = $CGI->param("Service_Notification_Add_F");
my $Service_Notification_Add_S = $CGI->param("Service_Notification_Add_S");
my $Host_Notification_Command_Add = $CGI->param("Host_Notification_Command_Add");
my $Service_Notification_Command_Add = $CGI->param("Service_Notification_Command_Add");
my $Active_Add = $CGI->param("Active_Add");

my $Contact_Edit_Post = $CGI->param("Contact_Edit_Post");
my $Contact_Edit = $CGI->param("Contact_Edit");
my $Alias_Edit = $CGI->param("Alias_Edit");
my $Email_Edit = $CGI->param("Email_Edit");
my $Host_Notification_Period_Edit = $CGI->param("Host_Notification_Period_Edit");
my $Service_Notification_Period_Edit = $CGI->param("Service_Notification_Period_Edit");
my $Host_Notification_Edit_D = $CGI->param("Host_Notification_Edit_D");
my $Host_Notification_Edit_U = $CGI->param("Host_Notification_Edit_U");
my $Host_Notification_Edit_R = $CGI->param("Host_Notification_Edit_R");
my $Host_Notification_Edit_F = $CGI->param("Host_Notification_Edit_F");
my $Host_Notification_Edit_S = $CGI->param("Host_Notification_Edit_S");
my $Service_Notification_Edit_C = $CGI->param("Service_Notification_Edit_C");
my $Service_Notification_Edit_W = $CGI->param("Service_Notification_Edit_W");
my $Service_Notification_Edit_U = $CGI->param("Service_Notification_Edit_U");
my $Service_Notification_Edit_R = $CGI->param("Service_Notification_Edit_R");
my $Service_Notification_Edit_F = $CGI->param("Service_Notification_Edit_F");
my $Service_Notification_Edit_S = $CGI->param("Service_Notification_Edit_S");
my $Host_Notification_Command_Edit = $CGI->param("Host_Notification_Command_Edit");
my $Service_Notification_Command_Edit = $CGI->param("Service_Notification_Command_Edit");
my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Contact = $CGI->param("Delete_Contact");
my $Contact_Delete_Post = $CGI->param("Contact_Delete_Post");
my $Contact_Delete = $CGI->param("Contact_Delete");

my $Display_Config = $CGI->param("Display_Config");

my $Filter = $CGI->param("Filter");

my $Username = $Session->param("User_Name");
my $User_Admin = $Session->param("User_Admin");

my $Rows_Returned = $CGI->param("Rows_Returned");
	if ($Rows_Returned eq '') {
		$Rows_Returned='100';
	}

if (!$Username) {
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

if ($Add_Contact) {
	require $Header;
	&html_output;
	&html_add_contact;
}
elsif ($Contact_Add && $Alias_Add) {
	&add_contact;
	if ($Active_Add) {
		my $Message_Green="$Contact_Add ($Alias_Add) added successfully and set active";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
	}
	else {
		my $Message_Orange="$Contact_Add ($Alias_Add) added successfully but set inactive";
		$Session->param('Message_Orange', $Message_Orange);
		$Session->flush();
	}
	
	print "Location: /Icinga/icinga-contacts.cgi\n\n";
	exit(0);
}
elsif ($Edit_Contact) {
	require $Header;
	&html_output;
	&html_edit_contact;
}
elsif ($Contact_Edit_Post) {
	&edit_contact;
	my $Message_Green="$Contact_Edit ($Alias_Edit) edited successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /Icinga/icinga-contacts.cgi\n\n";
	exit(0);
}
elsif ($Delete_Contact) {
	require $Header;
	&html_output;
	&html_delete_contact;
}
elsif ($Contact_Delete_Post) {
	&delete_contact;
	my $Message_Green="$Contact_Delete deleted successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /Icinga/icinga-contacts.cgi\n\n";
	exit(0);
}
elsif ($Display_Config) {
	require $Header;
	&html_output;
	&html_display_config;
}
else {
	require $Header;
	&html_output;
}



sub html_add_contact {

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/Icinga/icinga-contacts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Contact</h3>

<form action='/Icinga/icinga-contacts.cgi' method='post' >

<table align = "center">
	<tr>
		<td>
			<table>
				<tr>
					<td style="text-align: right;">Contact Name (Unique):</td>
					<td colspan="2"><input type='text' name='Contact_Add' style="width: 200px" maxlength='255' placeholder="Contact Name" required autofocus></td>
				</tr>
				<tr>
					<td style="text-align: right;">Alias/Description:</td>
					<td colspan="2"><input type='text' name='Alias_Add' style="width: 200px" maxlength='255' placeholder="Description" required></td>
				</tr>
				<tr>
					<td style="text-align: right;">Email (Comma separate multiple):</td>
					<td colspan="2"><input type='text' name='Email_Add' style="width: 200px" maxlength='255' placeholder="me\@nwk1.com,you\@nwk1.com" required></td>
				</tr>
				<tr>
					<td style="text-align: right;">Host Notification Command:</td>
					<td colspan="2">
						<select name='Host_Notification_Command_Add' style="width: 200px">
ENDHTML
		
						my $Select_Host_Commands = $DB_Connection->prepare("SELECT `id`, `command_name`
						FROM `icinga2_command`
						WHERE `command_name` LIKE '%notify%'
						OR `command_name` LIKE '%webops%'
						ORDER BY `command_name` ASC");
						$Select_Host_Commands->execute();
				
						while ( my @DB_Host_Commands = $Select_Host_Commands->fetchrow_array() )
						{
							my $Command_ID = $DB_Host_Commands[0];
							my $Command_Name = $DB_Host_Commands[1];
							print "<option value='$Command_ID'>$Command_Name</option>";
						}
				
							print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Service Notification Command:</td>
					<td colspan="2">
						<select name='Service_Notification_Command_Add' style="width: 200px">
ENDHTML
		
					my $Select_Service_Commands = $DB_Connection->prepare("SELECT `id`, `command_name`
					FROM `icinga2_command`
					WHERE `command_name` LIKE '%notify%'
					OR `command_name` LIKE '%webops%'
					ORDER BY `command_name` ASC");
					$Select_Service_Commands->execute();
			
					while ( my @DB_Service_Commands = $Select_Service_Commands->fetchrow_array() )
					{
						my $Command_ID = $DB_Service_Commands[0];
						my $Command_Name = $DB_Service_Commands[1];
						print "<option value='$Command_ID'>$Command_Name</option>";
					}
			
			print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Host Notification Period:</td>
					<td colspan="2">
						<select name='Host_Notification_Period_Add' style="width: 200px">
ENDHTML
		
		
					my $Select_Time_Periods = $DB_Connection->prepare("SELECT `id`, `timeperiod_name`, `alias`
					FROM `icinga2_timeperiod`
					WHERE `active` = '1'
					ORDER BY `timeperiod_name` ASC");
					$Select_Time_Periods->execute();
			
					while ( my @DB_Host_Notification_Period = $Select_Time_Periods->fetchrow_array() )
					{
						my $ID_Extract = $DB_Host_Notification_Period[0];
						my $Name_Extract = $DB_Host_Notification_Period[1];
						my $Alias_Extract = $DB_Host_Notification_Period[2];
						print "<option value='$ID_Extract'>$Name_Extract ($Alias_Extract)</option>";
					}
			
			print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Service Notification Period:</td>
					<td colspan="2">
						<select name='Service_Notification_Period_Add' style="width: 200px">
ENDHTML
		
		
							my $Select_Notification_Periods = $DB_Connection->prepare("SELECT `id`, `timeperiod_name`, `alias`
							FROM `icinga2_timeperiod`
							WHERE `active` = '1'
							ORDER BY `timeperiod_name` ASC");
							$Select_Notification_Periods->execute();
					
							while ( my @DB_Service_Notification_Period = $Select_Notification_Periods->fetchrow_array() )
							{
								my $ID_Extract = $DB_Service_Notification_Period[0];
								my $Name_Extract = $DB_Service_Notification_Period[1];
								my $Alias_Extract = $DB_Service_Notification_Period[2];
								print "<option value='$ID_Extract'>$Name_Extract ($Alias_Extract)</option>";
							}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Active?:</td>
					<td style='text-align: left;'><input type="radio" name="Active_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Active_Add" value="0" checked> No</td>
				</tr>
			</table>
		</td>
		<td style='padding-left: 30px;'>
			<table>
				<tr>
					<td colspan="2" style='text-align: left;'>Host Notification Options</td>
				</tr>
				<tr>
					<td style='color: #FF0000; text-align: left;'><input type="checkbox" name="Host_Notification_Add_D" value="d">Down</td>
					<td style='color: #FF8800; text-align: left;'><input type="checkbox" name="Host_Notification_Add_U" value="u">Unreachable</td>
				</tr>
				<tr>
					<td style='color: #00FF00; text-align: left;'><input type="checkbox" name="Host_Notification_Add_R" value="r">Recovery</td>
					<td style='color: #FFFF00; text-align: left;'><input type="checkbox" name="Host_Notification_Add_F" value="f">Flapping</td>
				</tr>
				<tr>
					<td style='color: #FF0088; text-align: left;'><input type="checkbox" name="Host_Notification_Add_S" value="s">SchdDnTime</td>
					<td style="text-align: right;"></td>
				</tr>
				<tr>
					<td colspan="2"><hr width="100%"></td>
				</tr>
				<tr>
					<td colspan="2" style='text-align: left;'>Service Notification Options</td>
				</tr>
				<tr>
					<td style='color: #FF0000; text-align: left;'><input type="checkbox" name="Service_Notification_Add_C" value="c">Critical</td>
					<td style='color: #FF8800; text-align: left;'><input type="checkbox" name="Service_Notification_Add_W" value="w">Warning</td>
				</tr>
				<tr>
					<td style='color: #AAAAAA; text-align: left;'><input type="checkbox" name="Service_Notification_Add_U" value="u">Unknown</td>
					<td style='color: #00FF00; text-align: left;'><input type="checkbox" name="Service_Notification_Add_R" value="r">Recovery</td>
				</tr>
				<tr>
					<td style='color: #FFFF00; text-align: left;'><input type="checkbox" name="Service_Notification_Add_F" value="f">Flapping</td>
					<td style='color: #FF0088; text-align: left;'><input type="checkbox" name="Service_Notification_Add_S" value="s">SchdDnTime</td>
				</tr>
			</table>
		</td>
	</tr>
</table>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Contact'></div>
</form>

</div>

ENDHTML

} #sub html_add_contact

sub add_contact {

	my $Contact_Insert_Check = $DB_Connection->prepare("SELECT `id`, `alias`
	FROM `icinga2_contact`
	WHERE `contact_name` = '$Contact_Add'");

	$Contact_Insert_Check->execute( );
	my $Contact_Rows = $Contact_Insert_Check->rows();

	if ($Contact_Rows) {
		while ( my @DB_Contact = $Contact_Insert_Check->fetchrow_array() )
			{

			my $ID_Extract = $DB_Contact[0];
			my $Alias_Extract = $DB_Contact[1];

			my $Message_Red="$Contact_Add already exists (ID: $ID_Extract, Alias: $Alias_Extract), new contact refused";
			$Session->param('Message_Red', $Message_Red);
			$Session->flush();
			print "Location: /Icinga/icinga-contacts.cgi\n\n";
			exit(0);

		}
	}
	else {

		my $Host_Notification_Add;
		if ($Host_Notification_Add_D) {$Host_Notification_Add = "$Host_Notification_Add_D,$Host_Notification_Add"}
		if ($Host_Notification_Add_U) {$Host_Notification_Add = "$Host_Notification_Add_U,$Host_Notification_Add"}
		if ($Host_Notification_Add_R) {$Host_Notification_Add = "$Host_Notification_Add_R,$Host_Notification_Add"}
		if ($Host_Notification_Add_F) {$Host_Notification_Add = "$Host_Notification_Add_F,$Host_Notification_Add"}
		if ($Host_Notification_Add_S) {$Host_Notification_Add = "$Host_Notification_Add_S,$Host_Notification_Add"}
		$Host_Notification_Add =~ s/,$//g;
	
		my $Service_Notification_Add;
		if ($Service_Notification_Add_C) {$Service_Notification_Add = "$Service_Notification_Add_C,$Service_Notification_Add"}
		if ($Service_Notification_Add_W) {$Service_Notification_Add = "$Service_Notification_Add_W,$Service_Notification_Add"}
		if ($Service_Notification_Add_U) {$Service_Notification_Add = "$Service_Notification_Add_U,$Service_Notification_Add"}
		if ($Service_Notification_Add_R) {$Service_Notification_Add = "$Service_Notification_Add_R,$Service_Notification_Add"}
		if ($Service_Notification_Add_F) {$Service_Notification_Add = "$Service_Notification_Add_F,$Service_Notification_Add"}
		if ($Service_Notification_Add_S) {$Service_Notification_Add = "$Service_Notification_Add_S,$Service_Notification_Add"}
		$Service_Notification_Add =~ s/,$//g;

		my $Contact_Insert = $DB_Connection->prepare("INSERT INTO `icinga2_contact` (
			`id`,
			`contact_name`,
			`alias`,
			`host_notification_period`,
			`service_notification_period`,
			`host_notification_options`,
			`service_notification_options`,
			`email`,
			`active`,
			`last_modified`,
			`modified_by`
		)
		VALUES (
			NULL,
			?, ?, ?, ?, ?, ?, ?, ?,
			NOW(),
			'$Username'
		)");

		$Contact_Insert->execute($Contact_Add, $Alias_Add, $Host_Notification_Period_Add, $Service_Notification_Period_Add,
		$Host_Notification_Add, $Service_Notification_Add, $Email_Add, $Active_Add);

		my $Contact_ID = $DB_Connection->{mysql_insertid};
		
		my $Host_Command_Insert = $DB_Connection->prepare("INSERT INTO `icinga2_lnkContactToCommandHost` (
			`idMaster`,
			`idSlave`
		)
		VALUES (
			?, ?
		)");

		$Host_Command_Insert->execute($Contact_ID, $Host_Notification_Command_Add);

		my $Service_Command_Insert = $DB_Connection->prepare("INSERT INTO `icinga2_lnkContactToCommandService` (
			`idMaster`,
			`idSlave`
		)
		VALUES (
			?, ?
		)");

		$Service_Command_Insert->execute($Contact_ID, $Service_Notification_Command_Add);

	}

} # sub add_contact

sub html_edit_contact {

	my $Select_Contacts = $DB_Connection->prepare("SELECT `contact_name`, `alias`, `host_notification_period`,
	`service_notification_period`, `host_notification_options`, `service_notification_options`,
	`email`, `active`
	FROM `icinga2_contact`
	WHERE `id` = ?");

	$Select_Contacts->execute($Edit_Contact);

	while ( my @DB_Contact = $Select_Contacts->fetchrow_array() )
	{

		my $Name_Extract = $DB_Contact[0];
		my $Alias_Extract = $DB_Contact[1];
		my $Host_Notification_Period_Extract = $DB_Contact[2];
		my $Service_Notification_Period_Extract = $DB_Contact[3];
		my $Host_Notification_Options_Extract = $DB_Contact[4];
		my $Service_Notification_Options_Extract = $DB_Contact[5];
		my $Email_Extract = $DB_Contact[6];
		my $Active_Extract = $DB_Contact[7];

		print <<ENDHTML;
		<div id="wide-popup-box">
		<a href="/Icinga/icinga-contacts.cgi">
		<div id="blockclosebutton">
		</div>
		</a>
		
		<h3 align="center">Editing Contact <span style="color: #00FF00;">$Name_Extract</span></h3>
		
		<form action='/Icinga/icinga-contacts.cgi' method='post' >
		
		<table align = "center">
			<tr>
				<td>
					<table>
						<tr>
							<td style="text-align: right;">Contact Name (Unique):</td>
							<td colspan="2"><input type='text' name='Contact_Edit' value='$Name_Extract' style="width: 200px" maxlength='255' placeholder="$Name_Extract" required autofocus></td>
						</tr>
						<tr>
							<td style="text-align: right;">Alias/Description:</td>
							<td colspan="2"><input type='text' name='Alias_Edit' value='$Alias_Extract' style="width: 200px" maxlength='255' placeholder="$Alias_Extract" required></td>
						</tr>
						<tr>
							<td style="text-align: right;">Email (Comma separate multiple):</td>
							<td colspan="2"><input type='text' name='Email_Edit' value='$Email_Extract' style="width: 200px" maxlength='255' placeholder="$Email_Extract" required></td>
						</tr>
						<tr>
							<td style="text-align: right;">Host Notification Command:</td>
							<td colspan="2">
								<select name='Host_Notification_Command_Edit' style="width: 200px">
ENDHTML
				
								my $Select_Host_Command_Link = $DB_Connection->prepare("SELECT `idSlave`
								FROM `icinga2_lnkContactToCommandHost`
								WHERE `idMaster` = '$Edit_Contact'");
								$Select_Host_Command_Link->execute();
						
								my $Host_Notification_Command_ID;
								while ( my @DB_Host_Command_Link = $Select_Host_Command_Link->fetchrow_array() )
								{
									$Host_Notification_Command_ID = $DB_Host_Command_Link[0];
								}
						
								my $Select_Host_Command_Name = $DB_Connection->prepare("SELECT `id`, `command_name`
								FROM `icinga2_command`
								WHERE `command_name` LIKE '%notify%'
								OR `command_name` LIKE '%webops%'");
								$Select_Host_Command_Name->execute();
				
								while ( my @DB_Host_Command_Conversion = $Select_Host_Command_Name->fetchrow_array() )
								{
									my $DB_Host_Command_ID = $DB_Host_Command_Conversion[0];
									my $DB_Host_Command_Name = $DB_Host_Command_Conversion[1];

									if ($DB_Host_Command_ID == $Host_Notification_Command_ID) {
										print "<option style='background-color: #009400;' value='$DB_Host_Command_ID' selected>$DB_Host_Command_Name</option>";
									}
									else {
										print "<option value='$DB_Host_Command_ID'>$DB_Host_Command_Name</option>";
									}
								}
						
								print <<ENDHTML;
								</select>
							</td>
						</tr>
						<tr>
							<td style="text-align: right;">Service Notification Command:</td>
							<td colspan="2">
								<select name='Service_Notification_Command_Edit' style="width: 200px">
ENDHTML
				
								my $Select_Service_Command_Link = $DB_Connection->prepare("SELECT `idSlave`
								FROM `icinga2_lnkContactToCommandService`
								WHERE `idMaster` = '$Edit_Contact'");
								$Select_Service_Command_Link->execute();
						
								my $Service_Notification_Command_ID;
								while ( my @DB_Service_Command_Link = $Select_Service_Command_Link->fetchrow_array() )
								{
									$Service_Notification_Command_ID = $DB_Service_Command_Link[0];
								}
						
								my $Select_Service_Command_Name = $DB_Connection->prepare("SELECT `id`, `command_name`
								FROM `icinga2_command`
								WHERE `command_name` LIKE '%notify%'
								OR `command_name` LIKE '%webops%'");
								$Select_Service_Command_Name->execute();
				
								while ( my @DB_Service_Command_Conversion = $Select_Service_Command_Name->fetchrow_array() )
								{
									my $DB_Service_Command_ID = $DB_Service_Command_Conversion[0];
									my $DB_Service_Command_Name = $DB_Service_Command_Conversion[1];

									if ($DB_Service_Command_ID == $Service_Notification_Command_ID) {
										print "<option style='background-color: #009400;' value='$DB_Service_Command_ID' selected>$DB_Service_Command_Name</option>";
									}
									else {
										print "<option value='$DB_Service_Command_ID'>$DB_Service_Command_Name</option>";
									}
								}
						
								print <<ENDHTML;
								</select>
							</td>
						</tr>
						<tr>
							<td style="text-align: right;">Host Notification Period:</td>
							<td colspan="2">
								<select name='Host_Notification_Period_Edit' style="width: 200px">
ENDHTML

							my $Select_Host_Notification_Periods = $DB_Connection->prepare("SELECT `id`, `timeperiod_name`, `alias`
							FROM `icinga2_timeperiod`
							WHERE `active` = '1'
							ORDER BY `timeperiod_name` ASC");
							$Select_Host_Notification_Periods->execute();
					
							while ( my @DB_Host_Notification_Period = $Select_Host_Notification_Periods->fetchrow_array() )
							{
								my $ID_Extract = $DB_Host_Notification_Period[0];
								my $Name_Extract = $DB_Host_Notification_Period[1];
								my $Alias_Extract = $DB_Host_Notification_Period[2];

								if ($ID_Extract == $Host_Notification_Period_Extract) {
									print "<option style='background-color: #009400;' value='$ID_Extract' selected>$Name_Extract ($Alias_Extract)</option>";
								}
								else {
									print "<option value='$ID_Extract'>$Name_Extract ($Alias_Extract)</option>";
								}
							}
					
							print <<ENDHTML;
								</select>
							</td>
						</tr>
						<tr>
							<td style="text-align: right;">Service Notification Period:</td>
							<td colspan="2">
								<select name='Service_Notification_Period_Edit' style="width: 200px">
ENDHTML

							my $Select_Service_Notification_Periods = $DB_Connection->prepare("SELECT `id`, `timeperiod_name`, `alias`
							FROM `icinga2_timeperiod`
							WHERE `active` = '1'
							ORDER BY `timeperiod_name` ASC");
							$Select_Service_Notification_Periods->execute();
					
							while ( my @DB_Service_Notification_Period = $Select_Service_Notification_Periods->fetchrow_array() )
							{
								my $ID_Extract = $DB_Service_Notification_Period[0];
								my $Name_Extract = $DB_Service_Notification_Period[1];
								my $Alias_Extract = $DB_Service_Notification_Period[2];

								if ($ID_Extract == $Service_Notification_Period_Extract) {
									print "<option style='background-color: #009400;' value='$ID_Extract' selected>$Name_Extract ($Alias_Extract)</option>";
								}
								else {
									print "<option value='$ID_Extract'>$Name_Extract ($Alias_Extract)</option>";
								}
							}
					
							print <<ENDHTML;
								</select>
							</td>
						</tr>
						<tr>
							<td style="text-align: right;">Active?:</td>
ENDHTML

							if ($Active_Extract) {
								print <<ENDHTML;
								<td style='text-align: left;'><input type="radio" name="Active_Edit" value="1" checked> Yes</td>
								<td style='text-align: left;'><input type="radio" name="Active_Edit" value="0"> No</td>
ENDHTML
							}
							else {
								print <<ENDHTML;
								<td style='text-align: left;'><input type="radio" name="Active_Edit" value="1"> Yes</td>
								<td style='text-align: left;'><input type="radio" name="Active_Edit" value="0" checked> No</td>
ENDHTML
							}


							print <<ENDHTML;
						</tr>
					</table>
				</td>
				<td style='padding-left: 30px;'>
					<table>
						<tr>
							<td colspan="2" style='text-align: left;'>Host Notification Options</td>
						</tr>
						<tr>
ENDHTML
							if ($Host_Notification_Options_Extract =~ m/d/) {
								print "<td style='color: #FF0000; text-align: left;'><input type='checkbox' name='Host_Notification_Edit_D' value='d' checked>Down</td>";
							}
							else {
								print "<td style='color: #FF0000; text-align: left;'><input type='checkbox' name='Host_Notification_Edit_D' value='d'>Down</td>";
							}

							if ($Host_Notification_Options_Extract =~ m/u/) {
								print "<td style='color: #FF8800; text-align: left;'><input type='checkbox' name='Host_Notification_Edit_U' value='u' checked>Unreachable</td>";
							}
							else {
								print "<td style='color: #FF8800; text-align: left;'><input type='checkbox' name='Host_Notification_Edit_U' value='u'>Unreachable</td>";
							}

							print <<ENDHTML;
						</tr>
						<tr>
ENDHTML
							if ($Host_Notification_Options_Extract =~ m/r/) {
								print "<td style='color: #00FF00; text-align: left;'><input type='checkbox' name='Host_Notification_Edit_R' value='r' checked>Recovery</td>";
							}
							else {
								print "<td style='color: #00FF00; text-align: left;'><input type='checkbox' name='Host_Notification_Edit_R' value='r'>Recovery</td>";
							}
							if ($Host_Notification_Options_Extract =~ m/f/) {
								print "<td style='color: #FFFF00; text-align: left;'><input type='checkbox' name='Host_Notification_Edit_F' value='f' checked>Flapping</td>";
							}
							else {
								print "<td style='color: #FFFF00; text-align: left;'><input type='checkbox' name='Host_Notification_Edit_F' value='f'>Flapping</td>";
							}

							print <<ENDHTML;
						</tr>
						<tr>
ENDHTML
							if ($Host_Notification_Options_Extract =~ m/s/) {
								print "<td style='color: #FF0088; text-align: left;'><input type='checkbox' name='Host_Notification_Edit_S' value='s' checked>SchdDnTime</td>";
							}
							else {
								print "<td style='color: #FF0088; text-align: left;'><input type='checkbox' name='Host_Notification_Edit_S' value='s'>SchdDnTime</td>";
							}

							print <<ENDHTML;
						</tr>
						<tr>
							<td colspan="2"><hr width="100%"></td>
						</tr>
						<tr>
							<td colspan="2" style='text-align: left;'>Service Notification Options</td>
						</tr>
						<tr>
ENDHTML
							if ($Service_Notification_Options_Extract =~ m/c/) {
								print "<td style='color: #FF0000; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_C' value='c' checked>Critical</td>";
							}
							else {
								print "<td style='color: #FF0000; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_C' value='c'>Critical</td>";
							}
							if ($Service_Notification_Options_Extract =~ m/w/) {
								print "<td style='color: #FF8800; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_W' value='w' checked>Warning</td>";
							}
							else {
								print "<td style='color: #FF8800; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_W' value='w'>Warning</td>";
							}

							print <<ENDHTML;
						</tr>
						<tr>
ENDHTML
							if ($Service_Notification_Options_Extract =~ m/u/) {
								print "<td style='color: #AAAAAA; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_U' value='u' checked>Unknown</td>";
							}
							else {
								print "<td style='color: #AAAAAA; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_U' value='u'>Unknown</td>";
							}
							if ($Service_Notification_Options_Extract =~ m/r/) {
								print "<td style='color: #00FF00; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_R' value='r' checked>Recovery</td>";
							}
							else {
								print "<td style='color: #00FF00; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_R' value='r'>Recovery</td>";
							}

							print <<ENDHTML;
						</tr>
						<tr>
ENDHTML
							if ($Service_Notification_Options_Extract =~ m/f/) {
								print "<td style='color: #FFFF00; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_F' value='f' checked>Flapping</td>";
							}
							else {
								print "<td style='color: #FFFF00; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_F' value='f'>Flapping</td>";
							}
							if ($Service_Notification_Options_Extract =~ m/s/) {
								print "<td style='color: #FF0088; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_S' value='s' checked>SchdDnTime</td>";
							}
							else {
								print "<td style='color: #FF0088; text-align: left;'><input type='checkbox' name='Service_Notification_Edit_S' value='s'>SchdDnTime</td>";
							}

							print <<ENDHTML;
						</tr>
					</table>
				</td>
			</tr>
		</table>
		
		<hr width="50%">
		<input type='hidden' name='Contact_Edit_Post' value='$Edit_Contact'>
		<div style="text-align: center"><input type=submit name='ok' value='Edit Contact'></div>
		</form>
		
		</div>

ENDHTML

	} # while ( my @DB_Contact = $Select_Contacts->fetchrow_array() )

} # sub html_edit_contact

sub edit_contact {

	my $Contact_Insert_Check = $DB_Connection->prepare("SELECT `id`, `alias`
	FROM `icinga2_contact`
	WHERE `contact_name` = '$Contact_Edit'
	AND `id` != '$Contact_Edit_Post'");

	$Contact_Insert_Check->execute( );
	my $Contact_Rows = $Contact_Insert_Check->rows();

	if ($Contact_Rows) {
		while ( my @DB_Contact = $Contact_Insert_Check->fetchrow_array() )
		{

			my $ID_Extract = $DB_Contact[0];
			my $Alias_Extract = $DB_Contact[1];

			my $Message_Red="$Contact_Edit already exists (ID: $ID_Extract, Alias: $Alias_Extract), edited contact refused";
			$Session->param('Message_Red', $Message_Red);
			$Session->flush();
			print "Location: /Icinga/icinga-contacts.cgi\n\n";
			exit(0);

		}
	}
	else {

		my $Host_Notification_Edit;
		if ($Host_Notification_Edit_D) {$Host_Notification_Edit = "$Host_Notification_Edit_D,$Host_Notification_Edit"}
		if ($Host_Notification_Edit_U) {$Host_Notification_Edit = "$Host_Notification_Edit_U,$Host_Notification_Edit"}
		if ($Host_Notification_Edit_R) {$Host_Notification_Edit = "$Host_Notification_Edit_R,$Host_Notification_Edit"}
		if ($Host_Notification_Edit_F) {$Host_Notification_Edit = "$Host_Notification_Edit_F,$Host_Notification_Edit"}
		if ($Host_Notification_Edit_S) {$Host_Notification_Edit = "$Host_Notification_Edit_S,$Host_Notification_Edit"}
		$Host_Notification_Edit =~ s/,$//g;
	
		my $Service_Notification_Edit;
		if ($Service_Notification_Edit_C) {$Service_Notification_Edit = "$Service_Notification_Edit_C,$Service_Notification_Edit"}
		if ($Service_Notification_Edit_W) {$Service_Notification_Edit = "$Service_Notification_Edit_W,$Service_Notification_Edit"}
		if ($Service_Notification_Edit_U) {$Service_Notification_Edit = "$Service_Notification_Edit_U,$Service_Notification_Edit"}
		if ($Service_Notification_Edit_R) {$Service_Notification_Edit = "$Service_Notification_Edit_R,$Service_Notification_Edit"}
		if ($Service_Notification_Edit_F) {$Service_Notification_Edit = "$Service_Notification_Edit_F,$Service_Notification_Edit"}
		if ($Service_Notification_Edit_S) {$Service_Notification_Edit = "$Service_Notification_Edit_S,$Service_Notification_Edit"}
		$Service_Notification_Edit =~ s/,$//g;

		my $Contact_Update = $DB_Connection->prepare("UPDATE `icinga2_contact` SET
			`contact_name` = ?,
			`alias` = ?,
			`host_notification_period` = ?,
			`service_notification_period` = ?,
			`host_notification_options` = ?,
			`service_notification_options` = ?,
			`email` = ?,
			`active` = ?,
			`last_modified` = NOW(),
			`modified_by` = '$Username'
			WHERE `id` = ?");
			
		$Contact_Update->execute($Contact_Edit, $Alias_Edit, $Host_Notification_Period_Edit, $Service_Notification_Period_Edit,
			$Host_Notification_Edit, $Service_Notification_Edit, $Email_Edit, $Active_Edit, $Contact_Edit_Post);


		my $Delete_Contact_Host = $DB_Connection->prepare("DELETE FROM `icinga2_lnkContactToCommandHost` WHERE `idMaster` = ?");
			$Delete_Contact_Host->execute($Contact_Edit_Post);
		my $Delete_Contact_Service = $DB_Connection->prepare("DELETE FROM `icinga2_lnkContactToCommandService` WHERE `idMaster` = ?");
			$Delete_Contact_Service->execute($Contact_Edit_Post);

		my $Host_Command_Insert = $DB_Connection->prepare("INSERT INTO `icinga2_lnkContactToCommandHost` (
			`idMaster`,
			`idSlave`
		)
		VALUES (
			?, ?
		)");

		$Host_Command_Insert->execute($Contact_Edit_Post, $Host_Notification_Command_Edit);

		my $Service_Command_Insert = $DB_Connection->prepare("INSERT INTO `icinga2_lnkContactToCommandService` (
			`idMaster`,
			`idSlave`
		)
		VALUES (
			?, ?
		)");

		$Service_Command_Insert->execute($Contact_Edit_Post, $Service_Notification_Command_Edit);

	}

} # sub edit_contact

sub html_delete_contact {

	my $Select_Contact = $DB_Connection->prepare("SELECT `contact_name`, `alias`
	FROM `icinga2_contact`
	WHERE `id` = '$Delete_Contact'");
	$Select_Contact->execute( );
	
	while ( my @DB_Contact = $Select_Contact->fetchrow_array() )
	{
	
		my $Contact_Extract = $DB_Contact[0];
		my $Alias_Extract = $DB_Contact[1];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/Icinga/icinga-contacts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Contact</h3>

<form action='/Icinga/icinga-contacts.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this service group?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Contact Name:</td>
		<td style="text-align: left; color: #00FF00;">$Contact_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Contact Alias:</td>
		<td style="text-align: left; color: #00FF00;">$Alias_Extract</td>
	</tr>
</table>

<input type='hidden' name='Contact_Delete_Post' value='$Delete_Contact'>
<input type='hidden' name='Contact_Delete' value='$Contact_Extract'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Contact'></div>

</form>

</div>

ENDHTML

	}
} # sub html_delete_contact

sub delete_contact {

	my $Delete = $DB_Connection->prepare("DELETE from `icinga2_contact`
		WHERE `id` = ?");
	$Delete->execute($Contact_Delete_Post);

	$Delete = $DB_Connection->prepare("DELETE from `icinga2_lnkContactToCommandHost`
		WHERE `idMaster` = ?");
	$Delete->execute($Contact_Delete_Post);

	$Delete = $DB_Connection->prepare("DELETE from `icinga2_lnkContactToCommandService`
		WHERE `idMaster` = ?");
	$Delete->execute($Contact_Delete_Post);

} # sub delete_contact

sub html_display_config {

	my $Select_Contact = $DB_Connection->prepare("SELECT `contact_name`, `alias`, `host_notification_period`,
	`service_notification_period`, `host_notification_options`, `service_notification_options`, `email`, `active`,
	`last_modified`, `modified_by`
	FROM `icinga2_contact`
	WHERE `id` = ?");
	$Select_Contact->execute($Display_Config);
	
	while ( my @DB_Contact = $Select_Contact->fetchrow_array() )
	{

		my $Name_Extract = $DB_Contact[0];
		my $Alias_Extract = $DB_Contact[1];
		my $Host_Notification_Period_Extract = $DB_Contact[2];
		my $Service_Notification_Period_Extract = $DB_Contact[3];
		my $Host_Notification_Options_Extract = $DB_Contact[4];
		my $Service_Notification_Options_Extract = $DB_Contact[5];
		my $Email_Extract = $DB_Contact[6];
		my $Active_Extract = $DB_Contact[7];
		my $Last_Modified_Extract = $DB_Contact[8];
		my $Modified_By_Extract = $DB_Contact[9];

		my $Select_Host_Time_Periods = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = ?");
		$Select_Host_Time_Periods->execute($Host_Notification_Period_Extract);

			my $Host_Notification_Period_Conversion;
			while ( my @DB_Host_Period = $Select_Host_Time_Periods->fetchrow_array() )
			{
				$Host_Notification_Period_Conversion = $DB_Host_Period[0];
			}

		my $Select_Service_Time_Periods = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = ?");
		$Select_Service_Time_Periods->execute($Service_Notification_Period_Extract);

			my $Service_Notification_Period_Conversion;
			while ( my @DB_Service_Period = $Select_Service_Time_Periods->fetchrow_array() )
			{
				$Service_Notification_Period_Conversion = $DB_Service_Period[0];
			}

		### Command Conversion
		my $Select_Host_Command_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkContactToCommandHost`
		WHERE `idMaster` = ?");
		$Select_Host_Command_Link->execute($Display_Config);

			my $Host_Notification_Command_Conversion;
			while ( my @DB_Host_Command_Link = $Select_Host_Command_Link->fetchrow_array() )
			{
				my $Host_Notification_Command_ID = $DB_Host_Command_Link[0];

				my $Select_Host_Command_Name = $DB_Connection->prepare("SELECT `command_name`
				FROM `icinga2_command`
				WHERE `id` = ?");
				$Select_Host_Command_Name->execute($Host_Notification_Command_ID);

				while ( my @DB_Host_Command_Conversion = $Select_Host_Command_Name->fetchrow_array() )
				{
					$Host_Notification_Command_Conversion = $DB_Host_Command_Conversion[0].", ".$Host_Notification_Command_Conversion;
				}
			}

		my $Select_Service_Command_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkContactToCommandService`
		WHERE `idMaster` = ?");
		$Select_Service_Command_Link->execute($Display_Config);

			my $Service_Notification_Command_Conversion;
			while ( my @DB_Service_Command_Link = $Select_Service_Command_Link->fetchrow_array() )
			{
				my $Service_Notification_Command_ID = $DB_Service_Command_Link[0];

				my $Select_Service_Command_Name = $DB_Connection->prepare("SELECT `command_name`
				FROM `icinga2_command`
				WHERE `id` = ?");
				$Select_Service_Command_Name->execute($Service_Notification_Command_ID);

				while ( my @DB_Service_Command_Conversion = $Select_Service_Command_Name->fetchrow_array() )
				{
					$Service_Notification_Command_Conversion = $DB_Service_Command_Conversion[0].", ".$Service_Notification_Command_Conversion;
				}
			}

		$Host_Notification_Command_Conversion =~ s/,\ $//g;
		$Service_Notification_Command_Conversion =~ s/,\ $//g;
		### / Command Conversion

		$Email_Extract =~ s/,/,\ /g;

		if (!$Active_Extract) {
			$Active_Extract="<span style='color: #FF8A00;'>
			This contact group is not active, so this config will not be written. 
			Make this contact group active to use it in Icinga.</span>";
		}
		else {
			$Active_Extract="";
		}

print <<ENDHTML;
<div id="full-width-popup-box">
<a href="/Icinga/icinga-contacts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Live Config for <span style="color: #00FF00;">$Name_Extract</span></h3>

<p>This config is automatically applied regularly. The config below illustrates how this contact's config will be written.</p>
<p>$Active_Extract</p>
<div style="text-align: left;">
<code>
<table align = "center">
	<tr>
		<td colspan='3'>## Contact ID: $Display_Config</td>
	</tr>
	<tr>
		<td colspan='3'>## Modified $Last_Modified_Extract by $Modified_By_Extract</td>
	</tr>
	<tr>
		<td colspan='3'>define contact {</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>contact_name</td>
		<td style='padding-left: 2em;'>$Name_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>alias</td>
		<td style='padding-left: 2em;'>$Alias_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>email</td>
		<td style='padding-left: 2em;'>$Email_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>host_notification_commands</td>
		<td style='padding-left: 2em;'>$Host_Notification_Command_Conversion</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>host_notification_options</td>
		<td style='padding-left: 2em;'>$Host_Notification_Options_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>host_notification_period</td>
		<td style='padding-left: 2em;'>$Host_Notification_Period_Conversion</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>service_notification_commands</td>
		<td style='padding-left: 2em;'>$Service_Notification_Command_Conversion</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>service_notification_options</td>
		<td style='padding-left: 2em;'>$Service_Notification_Options_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>service_notification_period</td>
		<td style='padding-left: 2em;'>$Service_Notification_Period_Conversion</td>
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

sub html_output {

	my $Table = new HTML::Table(
		-cols=>16,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbodd', # Reversed due to double header line
		-oddrowclass=>'tbeven', # Reversed due to double header line
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);

	$Table->addRow ( "ID", "Name", "Alias", "Notifications", "", "", "", "", "", "Email", "Active", "Last Modified",
	"Modified By", "View Config", "Edit", "Delete" );

	$Table->addRow ( "", "", "", "Host Period", "Service Period",
	"Host Options", "Service Options", "Host Commands", "Service Commands", "", "", "",
	"", "", "", "" );

	$Table->setRowClass(1, 'tbrow1');
	$Table->setRowClass(2, 'tbrow1');
		$Table->setCellRowSpan(1, 1, 2);
		$Table->setCellRowSpan(1, 2, 2);
		$Table->setCellRowSpan(1, 3, 2);
			$Table->setCellColSpan(1, 4, 6);
		$Table->setCellRowSpan(1, 10, 2);
		$Table->setCellRowSpan(1, 11, 2);
		$Table->setCellRowSpan(1, 12, 2);
		$Table->setCellRowSpan(1, 13, 2);
		$Table->setCellRowSpan(1, 14, 2);
		$Table->setCellRowSpan(1, 15, 2);
		$Table->setCellRowSpan(1, 16, 2);

	my $Select_Contacts_Count = $DB_Connection->prepare("SELECT `id` FROM `icinga2_contact`");
		$Select_Contacts_Count->execute( );
		my $Total_Rows = $Select_Contacts_Count->rows();

	my $Select_Contacts = $DB_Connection->prepare("SELECT `id`, `contact_name`, `alias`, `host_notification_period`,
	`service_notification_period`, `host_notification_options`, `service_notification_options`,
	`email`, `active`, `last_modified`, `modified_by`
	FROM `icinga2_contact`
	WHERE (`id` LIKE ?
	OR `contact_name` LIKE ?
	OR `alias` LIKE ?
	OR `email` LIKE ?)
	ORDER BY `contact_name` ASC
	LIMIT ?, ?");

	$Select_Contacts->execute($Filter, "%$Filter%", "%$Filter%", "%$Filter%", 0, $Rows_Returned);
	my $Rows = $Select_Contacts->rows();

	my $User_Row_Count=2;
	while ( my @DB_Contact = $Select_Contacts->fetchrow_array() )
	{
	
		$User_Row_Count++;

		my $ID_Extract = $DB_Contact[0];
			my $ID_Extract_Display = $ID_Extract;
			$ID_Extract_Display =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Name_Extract = $DB_Contact[1];
			$Name_Extract =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Alias_Extract = $DB_Contact[2];
			$Alias_Extract =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Host_Notification_Period_Extract = $DB_Contact[3];
		my $Service_Notification_Period_Extract = $DB_Contact[4];
		my $Host_Notification_Options_Extract = $DB_Contact[5];
		my $Service_Notification_Options_Extract = $DB_Contact[6];
		my $Email_Extract = $DB_Contact[7];
			$Email_Extract =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
			$Email_Extract =~ s/,/<br \/>/gi;
		my $Active_Extract = $DB_Contact[8];
		my $Last_Modified_Extract = $DB_Contact[9];
		my $Modified_By_Extract = $DB_Contact[10];

		if ($Active_Extract) {$Active_Extract='Yes';} else {$Active_Extract='No';}

		#### Converting time period ID to regular text (from icinga2_timeperiod table)
		my $Select_Host_Time_Periods = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = '$Host_Notification_Period_Extract'");
		$Select_Host_Time_Periods->execute();

			my $Host_Notification_Period_Conversion;
			while ( my @DB_Host_Period = $Select_Host_Time_Periods->fetchrow_array() )
			{
				$Host_Notification_Period_Conversion = $DB_Host_Period[0];
			}

		my $Select_Service_Time_Periods = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = '$Service_Notification_Period_Extract'");
		$Select_Service_Time_Periods->execute();

			my $Service_Notification_Period_Conversion;
			while ( my @DB_Service_Period = $Select_Service_Time_Periods->fetchrow_array() )
			{
				$Service_Notification_Period_Conversion = $DB_Service_Period[0];
			}
		#### / Converting time period ID to regular text (from icinga2_timeperiod table)

		#### Translating Icinga d,u,r etc values to regular text
		my $Host_Notification_Options_Display;
		my @Host_Notification_Options_Extract_Split = split( ',' ,$Host_Notification_Options_Extract);
		foreach (@Host_Notification_Options_Extract_Split) {
			if ($_ eq 'd') {$Host_Notification_Options_Display = "$Host_Notification_Options_Display<span style='color: #FF0000'>Down<br /></span>"}
			if ($_ eq 'u') {$Host_Notification_Options_Display = "$Host_Notification_Options_Display<span style='color: #FF8800'>Unreachable<br /></span>"}
			if ($_ eq 'r') {$Host_Notification_Options_Display = "$Host_Notification_Options_Display<span style='color: #00FF00'>Recovery<br /></span>"}
			if ($_ eq 'f') {$Host_Notification_Options_Display = "$Host_Notification_Options_Display<span style='color: #FFFF00'>Flapping<br /></span>"}
			if ($_ eq 's') {$Host_Notification_Options_Display = "$Host_Notification_Options_Display<span style='color: #FF0088'>SchdDnTime<br /></span>"}
		}

		my $Service_Notification_Options_Display;
		my @Service_Notification_Options_Extract_Split = split( ',' ,$Service_Notification_Options_Extract);
		foreach (@Service_Notification_Options_Extract_Split) {
			if ($_ eq 'c') {$Service_Notification_Options_Display = "$Service_Notification_Options_Display<span style='color: #FF0000'>Critical<br /></span>"}
			if ($_ eq 'w') {$Service_Notification_Options_Display = "$Service_Notification_Options_Display<span style='color: #FF8800'>Warning<br /></span>"}
			if ($_ eq 'u') {$Service_Notification_Options_Display = "$Service_Notification_Options_Display<span style='color: #AAAAAA'>Unknown<br /></span>"}
			if ($_ eq 'r') {$Service_Notification_Options_Display = "$Service_Notification_Options_Display<span style='color: #00FF00'>Recovery<br /></span>"}
			if ($_ eq 'f') {$Service_Notification_Options_Display = "$Service_Notification_Options_Display<span style='color: #FFFF00'>Flapping<br /></span>"}
			if ($_ eq 's') {$Service_Notification_Options_Display = "$Service_Notification_Options_Display<span style='color: #FF0088'>SchdDnTime<br /></span>"}
		}
		#### / Translating Icinga d,u,r etc values to regular text

		#### Converting command ID references to actual commands via link table (because host|service & command are many<->many)
		my $Select_Host_Command_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkContactToCommandHost`
		WHERE `idMaster` = '$ID_Extract'");
		$Select_Host_Command_Link->execute();

			my $Host_Notification_Command_ID;
			my $Host_Notification_Command_Conversion;
			while ( my @DB_Host_Command_Link = $Select_Host_Command_Link->fetchrow_array() )
			{
				$Host_Notification_Command_ID = $DB_Host_Command_Link[0];

				my $Select_Host_Command_Name = $DB_Connection->prepare("SELECT `command_name`
				FROM `icinga2_command`
				WHERE `id` = '$Host_Notification_Command_ID'");
				$Select_Host_Command_Name->execute();

				while ( my @DB_Host_Command_Conversion = $Select_Host_Command_Name->fetchrow_array() )
				{
					$Host_Notification_Command_Conversion = "$Host_Notification_Command_Conversion
						<a href='/Icinga/icinga-commands.cgi?Filter=$DB_Host_Command_Conversion[0]'>
							$DB_Host_Command_Conversion[0]
						</a>
						<br /><br />";
				}
			}

		my $Select_Service_Command_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkContactToCommandService`
		WHERE `idMaster` = '$ID_Extract'");
		$Select_Service_Command_Link->execute();
		
			my $Service_Notification_Command_ID;
			my $Service_Notification_Command_Conversion;
			while ( my @DB_Service_Command_Link = $Select_Service_Command_Link->fetchrow_array() )
			{
				$Service_Notification_Command_ID = $DB_Service_Command_Link[0];

				my $Select_Service_Command_Name = $DB_Connection->prepare("SELECT `command_name`
				FROM `icinga2_command`
				WHERE `id` = '$Service_Notification_Command_ID'");
				$Select_Service_Command_Name->execute();

				while ( my @DB_Service_Command_Conversion = $Select_Service_Command_Name->fetchrow_array() )
				{
					$Service_Notification_Command_Conversion = "$Service_Notification_Command_Conversion
						<a href='/Icinga/icinga-commands.cgi?Filter=$DB_Service_Command_Conversion[0]'>
							$DB_Service_Command_Conversion[0]
						</a>
						<br /><br />";
				}

			}
		#### / Converting command ID references to actual commands via link table (because host|service & command are many<->many)

		$Host_Notification_Command_Conversion =~ s/<br \/><br \/>$//g;
		$Service_Notification_Command_Conversion =~ s/<br \/><br \/>$//g;

		$Table->addRow(
			"<a href='/Icinga/icinga-contacts.cgi?Edit_Contact=$ID_Extract'>$ID_Extract_Display</a>",
			"<a href='/Icinga/icinga-contacts.cgi?Edit_Contact=$ID_Extract'>$Name_Extract</a>",
			$Alias_Extract,
			"<a href='/Icinga/icinga-time-periods.cgi?Filter=$Host_Notification_Period_Conversion'>$Host_Notification_Period_Conversion</a>",
			"<a href='/Icinga/icinga-time-periods.cgi?Filter=$Service_Notification_Period_Conversion'>$Service_Notification_Period_Conversion</a>",
			$Host_Notification_Options_Display,
			$Service_Notification_Options_Display,
			$Host_Notification_Command_Conversion,
			$Service_Notification_Command_Conversion,
			$Email_Extract,
			$Active_Extract,
			$Last_Modified_Extract,
			$Modified_By_Extract,
			"<a href='/Icinga/icinga-contacts.cgi?Display_Config=$ID_Extract'><img src=\"/resources/imgs/view-notes.png\" alt=\"View Config for $Name_Extract\" ></a>",
			"<a href='/Icinga/icinga-contacts.cgi?Edit_Contact=$ID_Extract'><img src=\"/resources/imgs/edit.png\" alt=\"Edit $Name_Extract\" ></a>",
			"<a href='/Icinga/icinga-contacts.cgi?Delete_Contact=$ID_Extract'><img src=\"/resources/imgs/delete.png\" alt=\"Delete $Name_Extract\" ></a>"
		);


		for (4 .. 7) {
			$Table->setColWidth($_, '1px');
			$Table->setColAlign($_, 'center');
		}
		for (11 .. 16) {
			$Table->setColAlign($_, 'center');
		}
		for (14 .. 16) {
			$Table->setColWidth($_, '1px');
		}

		$Table->setColWidth(9, '1px');
		$Table->setColAlign(8, 'center');
		$Table->setColAlign(9, 'center');


		if ($Active_Extract eq 'Yes') {
			$Table->setCellClass ($User_Row_Count, 11, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($User_Row_Count, 11, 'tbroworange');
		}

	}

print <<ENDHTML;

<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/Icinga/icinga-contacts.cgi' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Contacts" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/Icinga/icinga-contacts.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Contact</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Contact' value='Add Contact'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/Icinga/icinga-contacts.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Contact</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type='submit' name='Edit Contact' value='Edit Contact'></td>
					<td align="center">
						<select name='Edit_Contact' style="width: 150px">
ENDHTML

						my $Contact_List_Query = $DB_Connection->prepare("SELECT `id`, `contact_name`
						FROM `icinga2_contact`
						ORDER BY `contact_name` ASC");
						$Contact_List_Query->execute( );
						
						while ( (my $ID, my $DB_Contact_Name) = my @Contact_List_Query = $Contact_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$DB_Contact_Name</option>";
						}

print <<ENDHTML;
						</select>
					</td>
				</tr>
			</table>
		</td>
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">Icinga Contacts | Contacts Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML

} #sub html_output end
