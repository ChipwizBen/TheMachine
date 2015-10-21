#!/usr/bin/perl

use strict;
use HTML::Table;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_Icinga = DB_Icinga();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Host = $CGI->param("Add_Host");
my $Edit_Host = $CGI->param("Edit_Host");

my $Host_Name_Add = $CGI->param("Host_Name_Add");
my $Template_Add = $CGI->param("Template_Add");
my $Alias_Add = $CGI->param("Alias_Add");
my $Address_Add = $CGI->param("Address_Add");
my $Parent_Add = $CGI->param("Parent_Add");
my $Host_Group_Add = $CGI->param("Host_Group_Add");
my $Contact_Add = $CGI->param("Contact_Add");
my $Contact_Group_Add = $CGI->param("Contact_Group_Add");
my $Check_Period_Add = $CGI->param("Check_Period_Add");
my $Max_Check_Attempts_Add = $CGI->param("Max_Check_Attempts_Add");
	my $Max_Check_Attempts_Add_Inherit = $CGI->param("Max_Check_Attempts_Add_Inherit");
my $Normal_Check_Interval_Add = $CGI->param("Normal_Check_Interval_Add");
	my $Normal_Check_Interval_Add_Inherit = $CGI->param("Normal_Check_Interval_Add_Inherit");
my $Retry_Check_Interval_Add = $CGI->param("Retry_Check_Interval_Add");
	my $Retry_Check_Interval_Add_Inherit = $CGI->param("Retry_Check_Interval_Add_Inherit");
my $Notification_Interval_Add = $CGI->param("Notification_Interval_Add");
	my $Notification_Interval_Add_Inherit = $CGI->param("Notification_Interval_Add_Inherit");
my $Notification_Period_Add = $CGI->param("Notification_Period_Add");
my $Check_Command_Add = $CGI->param("Check_Command_Add");
my $Check_Command_Options = $CGI->param("Check_Command_Options");
my $Active_Checks_Add = $CGI->param("Active_Checks_Add");
my $Passive_Checks_Add = $CGI->param("Passive_Checks_Add");
my $Obsess_Over_Host_Add = $CGI->param("Obsess_Over_Host_Add");
my $Check_Freshness_Add = $CGI->param("Check_Freshness_Add");
my $Notifications_Add = $CGI->param("Notifications_Add");
my $Event_Handler_Add = $CGI->param("Event_Handler_Add");
my $Flap_Detection_Add = $CGI->param("Flap_Detection_Add");
my $Process_Performance_Data_Add = $CGI->param("Process_Performance_Data_Add");
my $Retain_Status_Information_Add = $CGI->param("Retain_Status_Information_Add");
my $Retain_NonStatus_Information_Add = $CGI->param("Retain_NonStatus_Information_Add");
my $Notification_Add_Inherit = $CGI->param("Notification_Add_Inherit");
my $Notification_Add_D = $CGI->param("Notification_Add_D");
my $Notification_Add_U = $CGI->param("Notification_Add_U");
my $Notification_Add_R = $CGI->param("Notification_Add_R");
my $Notification_Add_F = $CGI->param("Notification_Add_F");
my $Notification_Add_S = $CGI->param("Notification_Add_S");
my $Active_Add = $CGI->param("Active_Add");

my $Host_Edit_Post = $CGI->param("Host_Edit_Post");
my $Host_Edit = $CGI->param("Host_Edit");
my $Alias_Edit = $CGI->param("Alias_Edit");
my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Host = $CGI->param("Delete_Host");
my $Host_Delete_Post = $CGI->param("Host_Delete_Post");
my $Host_Delete = $CGI->param("Host_Delete");

my $Host_Notes = $CGI->param("Host_Notes");
my $Host_Note_Update = $CGI->param("Host_Note_Update");
my $Host_Note_Update_ID = $CGI->param("Host_Note_Update_ID");

my $Display_Config = $CGI->param("Display_Config");

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
	$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
	print "Location: /index.cgi\n\n";
	exit(0);
}

if ($Add_Host) {
	require $Header;
	&html_output;
	&html_add_host;
}
elsif ($Host_Name_Add && $Address_Add) {
	&add_host;
	if ($Active_Add) {
		my $Message_Green="$Host_Name_Add ($Address_Add) added successfully and set active";
		$Session->param('Message_Green', $Message_Green);
	}
	else {
		my $Message_Orange="$Host_Name_Add ($Address_Add) added successfully but set inactive";
		$Session->param('Message_Orange', $Message_Orange);
	}
	
	print "Location: /Icinga/icinga-hosts.cgi\n\n";
	exit(0);
}
elsif ($Edit_Host) {
	require $Header;
	&html_output;
	&html_edit_host;
}
elsif ($Host_Edit_Post) {
	&edit_host;
	my $Message_Green="$Host_Edit ($Alias_Edit) edited successfully";
	$Session->param('Message_Green', $Message_Green); #Posting Message_Green session var
	print "Location: /Icinga/icinga-hosts.cgi\n\n";
	exit(0);
}
elsif ($Delete_Host) {
	require $Header;
	&html_output;
	require $Footer;
	&html_delete_host;
}
elsif ($Host_Delete_Post) {
	&delete_host;
	my $Message_Green="$Host_Delete deleted successfully";
	$Session->param('Message_Green', $Message_Green); #Posting Message_Green session var
	print "Location: /Icinga/icinga-hosts.cgi\n\n";
	exit(0);
}
elsif ($Display_Config) {
	require $Header;
	&html_output;
	&html_display_config;
}
elsif ($Host_Notes) {
	require $Header;
	&html_output;
	&html_display_notes;
}
elsif ($Host_Note_Update && $Host_Note_Update_ID) {
	&update_notes;
	my $Message_Green="Notes updated successfully";
	$Session->param('Message_Green', $Message_Green);
	print "Location: /Icinga/icinga-hosts.cgi\n\n";
	exit(0);
}
else {
	require $Header;
	&html_output;
}



sub html_add_host {

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/Icinga/icinga-hosts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Host</h3>

<form action='/Icinga/icinga-hosts.cgi' method='post' >

<table align = "center">
	<tr>
		<td>
			<table>
				<tr>
					<td style="text-align: right;">Template:</td>
					<td colspan="3">
						<select name='Template_Add' style="width: 200px">
							<option value='0'>-- No Template --</option>
ENDHTML
		
		
							my $Select_Templates = $DB_Icinga->prepare("SELECT `id`, `template_name`
							FROM `nagios_hosttemplate`
							WHERE `active` = '1'
							ORDER BY `template_name` ASC");
							$Select_Templates->execute();
					
							while ( my @DB_Host = $Select_Templates->fetchrow_array() )
							{
								my $ID_Extract = $DB_Host[0];
								my $Name_Extract = $DB_Host[1];
								print "<option value='$ID_Extract'>$Name_Extract</option>";
							}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Host Name:</td>
					<td colspan="3"><input type='text' name='Host_Name_Add' style="width: 200px" maxlength='255' placeholder="Host Name" required autofocus></td>
				</tr>
				<tr>
					<td style="text-align: right;">Alias:</td>
					<td colspan="3"><input type='text' name='Alias_Add' style="width: 200px" maxlength='255' placeholder="Alias"></td>
				</tr>
				<tr>
					<td style="text-align: right;">IP:</td>
					<td colspan="3"><input type='text' name='Address_Add' style="width: 200px" maxlength='255' placeholder="www.xxx.yyy.zzz" required></td>
				</tr>
				<tr>
					<td style="text-align: right;">Parent:</td>
					<td colspan="3">
						<select name='Parent_Add' style="width: 200px">
							<option value='0'>-- No Parent --</option>
ENDHTML
		
							my $Select_Hosts = $DB_Icinga->prepare("SELECT `id`, `host_name`
							FROM `nagios_host`
							WHERE `active` = '1'
							ORDER BY `host_name` ASC");
							$Select_Hosts->execute();
					
							while ( my @DB_Host = $Select_Hosts->fetchrow_array() )
							{
								my $ID_Extract = $DB_Host[0];
								my $Name_Extract = $DB_Host[1];
								print "<option value='$ID_Extract'>$Name_Extract</option>";
							}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Host Group:</td>
					<td colspan="3">
						<select name='Host_Group_Add' style="width: 200px">
							<option value='0'>-- Inherit Host Group --</option>
ENDHTML

							my $Select_Host_Groups = $DB_Icinga->prepare("SELECT `id`, `hostgroup_name`
							FROM `nagios_hostgroup`
							WHERE `active` = '1'
							ORDER BY `hostgroup_name` ASC");
							$Select_Host_Groups->execute();
					
							while ( my @DB_Host = $Select_Host_Groups->fetchrow_array() )
							{
								my $ID_Extract = $DB_Host[0];
								my $Name_Extract = $DB_Host[1];
								print "<option value='$ID_Extract'>$Name_Extract</option>";
							}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Check Period:</td>
					<td colspan="3">
						<select name='Check_Period_Add' style="width: 200px">
							<option value='0'>-- Inherit Check Period --</option>
ENDHTML
		
		
							my $Select_Check_Period = $DB_Icinga->prepare("SELECT `id`, `timeperiod_name`, `alias`
							FROM `nagios_timeperiod`
							WHERE `active` = '1'
							ORDER BY `timeperiod_name` ASC");
							$Select_Check_Period->execute();
					
							while ( my @DB_Service = $Select_Check_Period->fetchrow_array() )
							{
								my $ID_Extract = $DB_Service[0];
								my $Name_Extract = $DB_Service[1];
								my $Alias_Extract = $DB_Service[2];
								print "<option value='$ID_Extract'>$Name_Extract ($Alias_Extract)</option>";
							}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Notification Period:</td>
					<td colspan="3">
						<select name='Notification_Period_Add' style="width: 200px">
							<option value='0'>-- Inherit Notification Period --</option>
ENDHTML
		
		
							my $Select_Notification_Period = $DB_Icinga->prepare("SELECT `id`, `timeperiod_name`, `alias`
							FROM `nagios_timeperiod`
							WHERE `active` = '1'
							ORDER BY `timeperiod_name` ASC");
							$Select_Notification_Period->execute();
					
							while ( my @DB_Host = $Select_Notification_Period->fetchrow_array() )
							{
								my $ID_Extract = $DB_Host[0];
								my $Name_Extract = $DB_Host[1];
								my $Alias_Extract = $DB_Host[2];
								print "<option value='$ID_Extract'>$Name_Extract ($Alias_Extract)</option>";
							}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Contact:</td>
					<td colspan="3">
						<select name='Contact_Add' style="width: 200px">
							<option value='0'>-- Inherit Contact --</option>
ENDHTML
		
		
							my $Select_Contacts = $DB_Icinga->prepare("SELECT `id`, `contact_name`, `alias`
							FROM `nagios_contact`
							WHERE `active` = '1'
							ORDER BY `contact_name` ASC");
							$Select_Contacts->execute();
					
							while ( my @DB_Host = $Select_Contacts->fetchrow_array() )
							{
								my $ID_Extract = $DB_Host[0];
								my $Name_Extract = $DB_Host[1];
								my $Alias_Extract = $DB_Host[2];
								print "<option value='$ID_Extract'>$Name_Extract ($Alias_Extract)</option>";
							}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Contact Group:</td>
					<td colspan="3">
						<select name='Contact_Group_Add' style="width: 200px">
							<option value='0'>-- Inherit Contact Group --</option>
ENDHTML
		
		
							my $Select_Contact_Groups = $DB_Icinga->prepare("SELECT `id`, `contactgroup_name`, `alias`
							FROM `nagios_contactgroup`
							WHERE `active` = '1'
							ORDER BY `contactgroup_name` ASC");
							$Select_Contact_Groups->execute();
					
							while ( my @DB_Host = $Select_Contact_Groups->fetchrow_array() )
							{
								my $ID_Extract = $DB_Host[0];
								my $Name_Extract = $DB_Host[1];
								my $Alias_Extract = $DB_Host[2];
								print "<option value='$ID_Extract'>$Name_Extract ($Alias_Extract)</option>";
							}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Max Check Attempts:</td>
					<td style='text-align: left;'><input type='text' name='Max_Check_Attempts_Add' style="width: 40px" maxlength='11' value="5" placeholder="5"></td>
					<td style='text-align: left;'><input type="radio" name="Max_Check_Attempts_Add_Inherit" value="0" checked> Defined</td>
					<td style='text-align: left;'><input type="radio" name="Max_Check_Attempts_Add_Inherit" value="2"> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Normal Check Interval:</td>
					<td style='text-align: left;'><input type='text' name='Normal_Check_Interval_Add' style="width: 40px" maxlength='11' value="5" placeholder="5"></td>
					<td style='text-align: left;'><input type="radio" name="Normal_Check_Interval_Add_Inherit" value="0" checked> Defined</td>
					<td style='text-align: left;'><input type="radio" name="Normal_Check_Interval_Add_Inherit" value="2"> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Retry Check Interval:</td>
					<td style='text-align: left;'><input type='text' name='Retry_Check_Interval_Add' style="width: 40px" maxlength='11' value="5" placeholder="5"></td>
					<td style='text-align: left;'><input type="radio" name="Retry_Check_Interval_Add_Inherit" value="0" checked> Defined</td>
					<td style='text-align: left;'><input type="radio" name="Retry_Check_Interval_Add_Inherit" value="2"> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Notification Interval:</td>
					<td style='text-align: left;'><input type='text' name='Notification_Interval_Add' style="width: 40px" maxlength='11' value="5" placeholder="5"></td>
					<td style='text-align: left;'><input type="radio" name="Notification_Interval_Add_Inherit" value="0" checked> Defined</td>
					<td style='text-align: left;'><input type="radio" name="Notification_Interval_Add_Inherit" value="2"> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Check Command:</td>
					<td colspan="3"><select name='Check_Command_Add' style="width: 200px">
						<option value='0'>-- Inherit Check Command --</option>
ENDHTML
			
			
						my $Select_Check_Commands = $DB_Icinga->prepare("SELECT `id`, `command_name`
						FROM `nagios_command`
						ORDER BY `command_name` ASC");
						$Select_Check_Commands->execute();
				
						while ( my @DB_Check_Commands = $Select_Check_Commands->fetchrow_array() )
						{
							my $Command_ID = $DB_Check_Commands[0];
							my $Command_Name = $DB_Check_Commands[1];
							print "<option value='$Command_ID'>$Command_Name</option>";
						}
				
							print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Check Command Options:</td>
					<td colspan="3">
						<input type='text' name='Check_Command_Options' style="width: 200px" placeholder="e.g.: 1500.0,50%!2000.0,60%">
					</td>
				</tr>
			</table>
		</td>
		<td style='padding-left: 30px;'>
			<table>
				<tr>
					<td style="text-align: right;">Active Checks:</td>
					<td style='text-align: left;'><input type="radio" name="Active_Checks_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Active_Checks_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Active_Checks_Add" value="2" checked> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Passive Checks:</td>
					<td style='text-align: left;'><input type="radio" name="Passive_Checks_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Passive_Checks_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Passive_Checks_Add" value="2" checked> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Obsess Over Host:</td>
					<td style='text-align: left;'><input type="radio" name="Obsess_Over_Host_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Obsess_Over_Host_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Obsess_Over_Host_Add" value="2" checked> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Check Freshness:</td>
					<td style='text-align: left;'><input type="radio" name="Check_Freshness_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Check_Freshness_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Check_Freshness_Add" value="2" checked> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Notifications:</td>
					<td style='text-align: left;'><input type="radio" name="Notifications_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Notifications_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Notifications_Add" value="2" checked> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Event Handler:</td>
					<td style='text-align: left;'><input type="radio" name="Event_Handler_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Event_Handler_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Event_Handler_Add" value="2" checked> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Flap Detection:</td>
					<td style='text-align: left;'><input type="radio" name="Flap_Detection_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Flap_Detection_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Flap_Detection_Add" value="2" checked> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Process Performance Data:</td>
					<td style='text-align: left;'><input type="radio" name="Process_Performance_Data_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Process_Performance_Data_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Process_Performance_Data_Add" value="2" checked> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Retain Status Information:</td>
					<td style='text-align: left;'><input type="radio" name="Retain_Status_Information_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Retain_Status_Information_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Retain_Status_Information_Add" value="2" checked> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Retain NonStatus Information:</td>
					<td style='text-align: left;'><input type="radio" name="Retain_NonStatus_Information_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Retain_NonStatus_Information_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Retain_NonStatus_Information_Add" value="2" checked> Inherit</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td colspan="2" align="center">
		<hr width="25%">
			<table>
				<tr>
					<td colspan="2">Notification Options</td>
				</tr>
				<tr>
					<td style='text-align: left;'><input type="radio" name="Notification_Add_Inherit" value="0" checked> Defined</td>
					<td style='text-align: left;'><input type="radio" name="Notification_Add_Inherit" value="2"> Inherit</td>
				</tr>
				<tr>
					<td style='color: #FF0000; text-align: left;'><input type="checkbox" name="Notification_Add_D" value="d" checked>Down</td>
					<td style='color: #FF8800; text-align: left;'><input type="checkbox" name="Notification_Add_U" value="u" checked>Unreachable</td>
				</tr>
				<tr>
					<td style='color: #00FF00; text-align: left;'><input type="checkbox" name="Notification_Add_R" value="r" checked>Recovery</td>
					<td style='color: #FFFF00; text-align: left;'><input type="checkbox" name="Notification_Add_F" value="f" checked>Flapping</td>
				</tr>
				<tr>
					<td style='color: #FF0088; text-align: left;'><input type="checkbox" name="Notification_Add_S" value="s" checked>SchdDnTime</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr>
		<td colspan="2" align="center">
		<hr width="25%">
			<table>
				<tr>
					<td style="text-align: right;">Active?:</td>
					<td style='text-align: left;'><input type="radio" name="Active_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Active_Add" value="0" checked> No</td>
				</tr>
			</table>
		</td>
	</tr>
</table>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Host'></div>
</form>

ENDHTML


} #sub html_add_host

sub add_host {

	my $Select_Host = $DB_Icinga->prepare("SELECT `host_name`
	FROM `nagios_host`
	WHERE `host_name` = ?");
	$Select_Host->execute($Host_Name_Add);
	my $Rows = $Select_Host->rows();

	if ($Rows > 0) {
		my $Message_Red="Host name $Host_Name_Add already exists. Host not added.";
		$Session->param('Message_Red', $Message_Red);
		print "Location: /Icinga/icinga-hosts.cgi\n\n";
		exit(0);
	}

	if ($Max_Check_Attempts_Add_Inherit eq 2) {$Max_Check_Attempts_Add = undef};
	if ($Normal_Check_Interval_Add_Inherit eq 2) {$Normal_Check_Interval_Add = undef};
	if ($Retry_Check_Interval_Add_Inherit eq 2) {$Retry_Check_Interval_Add = undef};
	if ($Notification_Interval_Add_Inherit eq 2) {$Notification_Interval_Add = undef};

	if ($Check_Command_Options) {$Check_Command_Add = $Check_Command_Add."!".$Check_Command_Options};
		$Check_Command_Add =~ s/!!/!/g;

	my $Notification_Options_Add;
	if ($Notification_Add_D) {$Notification_Options_Add = "$Notification_Add_D,$Notification_Options_Add"}
	if ($Notification_Add_U) {$Notification_Options_Add = "$Notification_Add_U,$Notification_Options_Add"}
	if ($Notification_Add_R) {$Notification_Options_Add = "$Notification_Add_R,$Notification_Options_Add"}
	if ($Notification_Add_F) {$Notification_Options_Add = "$Notification_Add_F,$Notification_Options_Add"}
	if ($Notification_Add_S) {$Notification_Options_Add = "$Notification_Add_S,$Notification_Options_Add"}
	$Notification_Options_Add =~ s/,$//g;
	if ($Notification_Add_Inherit eq 2) {$Notification_Options_Add = undef};

	my $Host_Insert = $DB_Icinga->prepare("INSERT INTO `nagios_host` (
		`host_name`, `alias`, `address`, `active_checks_enabled`, `check_freshness`, `check_period`, `event_handler_enabled`,
		`flap_detection_enabled`, `check_command`, `max_check_attempts`, `check_interval`, `notification_interval`, `notification_options`,
		`notification_period`, `notifications_enabled`, `obsess_over_host`, `passive_checks_enabled`, `process_perf_data`,
		`retain_nonstatus_information`, `retain_status_information`, `retry_interval`, `active`, `last_modified`, `modified_by`
	)
	VALUES (
		?, ?, ?, ?, ?, ?, ?,
		?, ?, ?, ?, ?, ?,
		?, ?, ?, ?, ?,
		?, ?, ?, ?,	NOW(), ?
	)");

	$Host_Insert->execute($Host_Name_Add, $Alias_Add, $Address_Add, $Active_Checks_Add, $Check_Freshness_Add, $Check_Period_Add, $Event_Handler_Add,
	$Flap_Detection_Add, $Check_Command_Add, $Max_Check_Attempts_Add, $Normal_Check_Interval_Add, $Notification_Interval_Add, $Notification_Options_Add,
	$Notification_Period_Add, $Notifications_Add, $Obsess_Over_Host_Add, $Passive_Checks_Add, $Process_Performance_Data_Add,
	$Retain_NonStatus_Information_Add, $Retain_Status_Information_Add, $Retry_Check_Interval_Add, $Active_Add, $User_Name);

	my $Host_Insert_ID = $DB_Icinga->{mysql_insertid};


	if ($Template_Add) {

		my $Template_Insert = $DB_Icinga->prepare("INSERT INTO `nagios_lnkHostToHosttemplate` (
		`idMaster`, `idSlave`
		)
		VALUES (
		?, ?
		)");

		$Template_Insert->execute($Host_Insert_ID, $Template_Add);

	}

	if ($Contact_Add) {

		my $Contact_Insert = $DB_Icinga->prepare("INSERT INTO `nagios_lnkHostToContact` (
		`idMaster`, `idSlave`
		)
		VALUES (
		?, ?
		)");

		$Contact_Insert->execute($Host_Insert_ID, $Contact_Add);

	}

	if ($Contact_Group_Add) {

		my $Contact_Group_Insert = $DB_Icinga->prepare("INSERT INTO `nagios_lnkHostToContactgroup` (
		`idMaster`, `idSlave`
		)
		VALUES (
		?, ?
		)");

		$Contact_Group_Insert->execute($Host_Insert_ID, $Contact_Group_Add);

	}

	if ($Host_Group_Add) {

		my $Contact_Group_Insert = $DB_Icinga->prepare("INSERT INTO `nagios_lnkHostToHostgroup` (
		`idMaster`, `idSlave`
		)
		VALUES (
		?, ?
		)");

		$Contact_Group_Insert->execute($Host_Insert_ID, $Host_Group_Add);

	}

	if ($Parent_Add) {

		my $Parent_Insert = $DB_Icinga->prepare("INSERT INTO `nagios_lnkHostToHost` (
		`idMaster`, `idSlave`
		)
		VALUES (
		?, ?
		)");

		$Parent_Insert->execute($Host_Insert_ID, $Parent_Add);

	}

} # sub add_host

sub html_edit_host {

	my $Select_Host = $DB_Icinga->prepare("SELECT `host_name`, `alias`, `active`
	FROM `nagios_host`
	WHERE `id` = '$Edit_Host'");
	$Select_Host->execute( );
	
	while ( my @DB_Host = $Select_Host->fetchrow_array() )
	{
	
		my $Host_Extract = $DB_Host[0];
		my $Alias_Extract = $DB_Host[1];
		my $Active_Extract = $DB_Host[2];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/Icinga/icinga-hosts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Editing Host <span style="color: #00FF00;">$Host_Extract</span></h3>

<form action='/Icinga/icinga-hosts.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Host Name:</td>
		<td colspan="2"><input type='text' name='Host_Edit' value='$Host_Extract' size='15' maxlength='100' placeholder="Host Name" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Alias/Description:</td>
		<td colspan="2"><input type='text' name='Alias_Edit' value='$Alias_Extract' size='15' maxlength='100' placeholder="Description" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Active?:</td>
ENDHTML

if ($Active_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Active_Edit" value="1" checked> Yes</td>
		<td style="text-align: right;"><input type="radio" name="Active_Edit" value="0"> No</td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Active_Edit" value="1"> Yes</td>
		<td style="text-align: right;"><input type="radio" name="Active_Edit" value="0" checked> No</td>
ENDHTML
}


print <<ENDHTML;
	</tr>
</table>

<input type='hidden' name='Host_Edit_Post' value='$Edit_Host'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Host'></div>

</form>

ENDHTML

	}
} # sub html_edit_host

sub edit_host {

	my $Host_Insert_Check = $DB_Icinga->prepare("SELECT `id`, `alias`
	FROM `nagios_host`
	WHERE `host_name` = '$Host_Edit'
	AND `id` != ?");

	$Host_Insert_Check->execute($Host_Edit_Post);
	my $Host_Rows = $Host_Insert_Check->rows();

	if ($Host_Rows) {
		while ( my @DB_Host = $Host_Insert_Check->fetchrow_array() )
			{

			my $ID_Extract = $DB_Host[0];
			my $Alias_Extract = $DB_Host[1];

			my $Message_Red="$Host_Edit already exists - Conflicting Host ID (This entry): $Host_Edit_Post, Existing Host ID: $ID_Extract, Existing Host Alias: $Alias_Extract";
			$Session->param('Message_Red', $Message_Red);
			print "Location: /Icinga/icinga-hosts.cgi\n\n";
			exit(0);

		}
	}
	else {

		my $Host_Update = $DB_Icinga->prepare("UPDATE `nagios_host` SET
			`host_name` = ?,
			`alias` = ?,
			`active` = ?,
			`last_modified` = NOW(),
			`modified_by` = '$User_Name'
			WHERE `id` = ?"
		);
		
		$Host_Update->execute($Host_Edit, $Alias_Edit, $Active_Edit, $Host_Edit_Post)
	}

} # sub edit_host

sub html_delete_host {

	my $Select_Host = $DB_Icinga->prepare("SELECT `host_name`, `alias`
	FROM `nagios_host`
	WHERE `id` = ?");
	$Select_Host->execute($Delete_Host);
	
	while ( my @DB_Host = $Select_Host->fetchrow_array() )
	{
	
		my $Host_Extract = $DB_Host[0];
		my $Alias_Extract = $DB_Host[1];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/Icinga/icinga-hosts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Host</h3>

<form action='/Icinga/icinga-hosts.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this host?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Host Name:</td>
		<td style="text-align: left; color: #00FF00;">$Host_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Host Alias:</td>
		<td style="text-align: left; color: #00FF00;">$Alias_Extract</td>
	</tr>
</table>

<input type='hidden' name='Host_Delete_Post' value='$Delete_Host'>
<input type='hidden' name='Host_Delete' value='$Host_Extract'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Host'></div>

</form>

</div>

ENDHTML

	}
} # sub html_delete_host

sub delete_host {

	my $Delete = $DB_Icinga->prepare("DELETE from `nagios_host`
				WHERE `id` = ?");
	$Delete->execute($Host_Delete_Post);

	$Delete = $DB_Icinga->prepare("DELETE from `nagios_lnkHostToHosttemplate`
				WHERE `idMaster` = ?");
	$Delete->execute($Host_Delete_Post);

	$Delete = $DB_Icinga->prepare("DELETE from `nagios_lnkHostToContact`
				WHERE `idMaster` = ?");
	$Delete->execute($Host_Delete_Post);

	$Delete = $DB_Icinga->prepare("DELETE from `nagios_lnkHostToContactgroup`
				WHERE `idMaster` = ?");
	$Delete->execute($Host_Delete_Post);

	$Delete = $DB_Icinga->prepare("DELETE from `nagios_lnkHostToHostgroup`
				WHERE `idMaster` = ?");
	$Delete->execute($Host_Delete_Post);

} # sub delete_host

sub html_display_config {

	my $Select_Host = $DB_Icinga->prepare("SELECT `host_name`, `alias`, `address`, `active_checks_enabled`, `check_freshness`, 
	`check_period`, `event_handler_enabled`, `flap_detection_enabled`, `check_command`, `max_check_attempts`,
	`check_interval`, `notification_interval`, `notification_options`, `notification_period`, `notifications_enabled`,
	`obsess_over_host`, `passive_checks_enabled`, `process_perf_data`, `retain_nonstatus_information`,
	`retain_status_information`, `retry_interval`, `active`, `notes`, `last_modified`, `modified_by`
	FROM `nagios_host`
	WHERE `id` = ?");
	$Select_Host->execute($Display_Config);
	
	while ( my @DB_Host = $Select_Host->fetchrow_array() )
	{
	
		my $Host_Extract = $DB_Host[0];
		my $Alias_Extract = $DB_Host[1];
		my $IP_Extract = $DB_Host[2];
		my $Active_Checks_Enabled_Extract = $DB_Host[3];
		my $Check_Freshness_Extract = $DB_Host[4];
		my $Check_Period_Extract = $DB_Host[5];
		my $Event_Handler_Enabled_Extract = $DB_Host[6];
		my $Flap_Detection_Enabled_Extract = $DB_Host[7];
		my $Check_Command_Extract = $DB_Host[8];
		my $Max_Check_Attempts_Extract = $DB_Host[9];
		my $Normal_Check_Interval_Extract = $DB_Host[10];
		my $Notification_Interval_Extract = $DB_Host[11];
		my $Notification_Options_Extract = $DB_Host[12];
		my $Notification_Period_Extract = $DB_Host[13];
		my $Notifications_Enabled_Extract = $DB_Host[14];
		my $Obsess_Over_Host_Extract = $DB_Host[15];
		my $Passive_Checks_Enabled_Extract = $DB_Host[16];
		my $Process_Perf_Data_Extract = $DB_Host[17];
		my $Retain_NonStatus_Information_Extract = $DB_Host[18];
		my $Retain_Status_Information_Extract = $DB_Host[19];
		my $Retry_Check_Interval_Extract = $DB_Host[20];
		my $Active_Extract = $DB_Host[21];
		my $Host_Notes_Extract = $DB_Host[22];
		my $Last_Modified_Extract = $DB_Host[23];
		my $Modified_By_Extract = $DB_Host[24];


		## Host Parent Resolution

		my $Host_Parents;
		my $Select_Host_Parent_Link = $DB_Icinga->prepare("SELECT `idSlave`
		FROM `nagios_lnkHostToHost`
		WHERE (`idMaster` = ?)");
		$Select_Host_Parent_Link->execute($Display_Config);

			while ( my @DB_Parent_Link = $Select_Host_Parent_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Parent_Link[0];

				my $Select_Host = $DB_Icinga->prepare("SELECT `host_name`
				FROM `nagios_host`
				WHERE `id` = ?");
				$Select_Host->execute($Host_Link);

				while ( my @DB_Parent = $Select_Host->fetchrow_array() )
				{

					my $Host_Parent = $DB_Parent[0];
					$Host_Parents = $Host_Parent.",".$Host_Parents;

				}
			}

		## / Host Parent Resolution

		## Host Template Resolution

		my $Host_Templates;
		my $Select_Host_Template_Link = $DB_Icinga->prepare("SELECT `idSlave`
		FROM `nagios_lnkHostToHosttemplate`
		WHERE (`idMaster` = ?)");
		$Select_Host_Template_Link->execute($Display_Config);

			while ( my @DB_Template_Link = $Select_Host_Template_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Template_Link[0];

				my $Select_Host = $DB_Icinga->prepare("SELECT `template_name`
				FROM `nagios_hosttemplate`
				WHERE `id` = ?");
				$Select_Host->execute($Host_Link);

				while ( my @DB_Template = $Select_Host->fetchrow_array() )
				{

					my $Host_Template = $DB_Template[0];
					$Host_Templates = $Host_Template.",".$Host_Templates;

				}
			}

		## / Host Template Resolution

		## Host Contact Group Resolution

		my $Host_Contact_Groups;
		my $Select_Host_Contact_Group_Link = $DB_Icinga->prepare("SELECT `idSlave`
		FROM `nagios_lnkHostToContactgroup`
		WHERE (`idMaster` = ?)");
		$Select_Host_Contact_Group_Link->execute($Display_Config);

			while ( my @DB_Contact_Group_Link = $Select_Host_Contact_Group_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Contact_Group_Link[0];

				my $Select_Host = $DB_Icinga->prepare("SELECT `contactgroup_name`
				FROM `nagios_contactgroup`
				WHERE `id` = ?");
				$Select_Host->execute($Host_Link);

				while ( my @DB_Contact_Group = $Select_Host->fetchrow_array() )
				{

					my $Host_Contact_Group = $DB_Contact_Group[0];
					$Host_Contact_Groups = $Host_Contact_Group.",".$Host_Contact_Groups;

				}
			}

		## / Host Contact Group Resolution

		## Host Template Values

		my $Host_Template_ID;
		my $Host_Description_Extract_Template;
		my $Last_Modified_Extract_Template;
		my $Modified_By_Extract_Template;
		my $Check_Period_Extract_Template;
		my $Notification_Period_Extract_Template;
		my $Check_Command_Extract_Template;
		my $Select_Host_Template_ID = $DB_Icinga->prepare("SELECT `idSlave`
		FROM `nagios_lnkHostToHosttemplate`
		WHERE `idMaster` = ?");
		$Select_Host_Template_ID->execute($Display_Config);
		
		while ( my @DB_Host_Template_ID = $Select_Host_Template_ID->fetchrow_array() )
		{

			$Host_Template_ID = $DB_Host_Template_ID[0];

			my $Select_Host_Template = $DB_Icinga->prepare("SELECT `template_name`, `active_checks_enabled`, `check_freshness`, 
			`check_period`, `event_handler_enabled`, `flap_detection_enabled`, `check_command`, `max_check_attempts`, `check_interval`,
			`notification_interval`, `notification_options`, `notification_period`, `notifications_enabled`, `obsess_over_host`,
			`passive_checks_enabled`, `process_perf_data`, `retain_nonstatus_information`, `retain_status_information`,
			`retry_interval`, `active`, `last_modified`, `modified_by`
			FROM `nagios_hosttemplate`
			WHERE `id` = ?");
			$Select_Host_Template->execute($Host_Template_ID);
			
			while ( my @DB_Host_Template = $Select_Host_Template->fetchrow_array() )
			{
	
				$Host_Description_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[0]</span>";
				my $Active_Checks_Enabled_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[1]</span>";
				my $Check_Freshness_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[2]</span>";
				$Check_Period_Extract_Template = $DB_Host_Template[3];
				my $Event_Handler_Enabled_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[4]</span>";
				my $Flap_Detection_Enabled_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[5]</span>";
				$Check_Command_Extract_Template = $DB_Host_Template[6];
				my $Max_Check_Attempts_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[7]</span>";
				my $Normal_Check_Interval_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[8]</span>";
				my $Notification_Interval_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[9]</span>";
				my $Notification_Options_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[10]</span>";
				$Notification_Period_Extract_Template = $DB_Host_Template[11];
				my $Notifications_Enabled_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[12]</span>";
				my $Obsess_Over_Host_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[13]</span>";
				my $Passive_Checks_Enabled_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[14]</span>";
				my $Process_Perf_Data_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[15]</span>";
				my $Retain_NonStatus_Information_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[16]</span>";
				my $Retain_Status_Information_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[17]</span>";
				my $Retry_Check_Interval_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[18]</span>";
				my $Active_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[19]</span>";
				$Last_Modified_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[20]</span>";
				$Modified_By_Extract_Template = "<span style='color: #FF8800;'>$DB_Host_Template[21]</span>";

				if ($Active_Checks_Enabled_Extract eq 2) {$Active_Checks_Enabled_Extract = $Active_Checks_Enabled_Extract_Template};
				if ($Check_Freshness_Extract eq 2) {$Check_Freshness_Extract = $Check_Freshness_Extract_Template};
				if ($Event_Handler_Enabled_Extract eq '' || $Event_Handler_Enabled_Extract eq 2) {$Event_Handler_Enabled_Extract = $Event_Handler_Enabled_Extract_Template};
				if ($Flap_Detection_Enabled_Extract eq '' || $Flap_Detection_Enabled_Extract eq 2) {$Flap_Detection_Enabled_Extract = $Flap_Detection_Enabled_Extract_Template};
				if ($Max_Check_Attempts_Extract eq '') {$Max_Check_Attempts_Extract = $Max_Check_Attempts_Extract_Template};
				if ($Normal_Check_Interval_Extract eq '') {$Normal_Check_Interval_Extract = $Normal_Check_Interval_Extract_Template};
				if ($Notification_Interval_Extract eq '') {$Notification_Interval_Extract = $Notification_Interval_Extract_Template};
				if (!$Notification_Options_Extract) {$Notification_Options_Extract = $Notification_Options_Extract_Template};
				if ($Notifications_Enabled_Extract eq '' || $Notifications_Enabled_Extract eq 2) {$Notifications_Enabled_Extract = $Notifications_Enabled_Extract_Template};
				if ($Obsess_Over_Host_Extract eq '' || $Obsess_Over_Host_Extract eq 2) {$Obsess_Over_Host_Extract = $Obsess_Over_Host_Extract_Template};
				if ($Passive_Checks_Enabled_Extract eq '' || $Passive_Checks_Enabled_Extract eq 2) {$Passive_Checks_Enabled_Extract = $Passive_Checks_Enabled_Extract_Template};
				if ($Process_Perf_Data_Extract eq '' || $Process_Perf_Data_Extract eq 2) {$Process_Perf_Data_Extract = $Process_Perf_Data_Extract_Template};
				if ($Retain_NonStatus_Information_Extract eq '' || $Retain_NonStatus_Information_Extract eq 2) {$Retain_NonStatus_Information_Extract = $Retain_NonStatus_Information_Extract_Template};
				if ($Retain_Status_Information_Extract eq '' || $Retain_Status_Information_Extract eq 2) {$Retain_Status_Information_Extract = $Retain_Status_Information_Extract_Template};
				if ($Retry_Check_Interval_Extract eq '' || $Retry_Check_Interval_Extract eq 2) {$Retry_Check_Interval_Extract = $Retry_Check_Interval_Extract_Template};
			}
		}

		## / Host Template Values
		
		## Host Template's Template Values

		my $Host_Templates_Template_ID;
		my $Host_Description_Extract_Templates_Template;
		my $Last_Modified_Extract_Templates_Template;
		my $Modified_By_Extract_Templates_Template;
		my $Check_Period_Extract_Templates_Template;
		my $Notification_Period_Extract_Templates_Template;
		my $Check_Command_Extract_Templates_Template;
		
		my $Select_Host_Templates_Template_ID = $DB_Icinga->prepare("SELECT `idSlave`
		FROM `nagios_lnkHosttemplateToHosttemplate`
		WHERE `idMaster` = ?");
		$Select_Host_Templates_Template_ID->execute($Host_Template_ID);
		
		while ( my @DB_Host_Templates_Template_ID = $Select_Host_Templates_Template_ID->fetchrow_array() )
		{

			$Host_Templates_Template_ID = $DB_Host_Templates_Template_ID[0];

			my $Select_Host_Templates_Template = $DB_Icinga->prepare("SELECT `template_name`, `active_checks_enabled`, `check_freshness`, 
			`check_period`, `event_handler_enabled`, `flap_detection_enabled`, `check_command`, `max_check_attempts`, `check_interval`,
			`notification_interval`, `notification_options`, `notification_period`, `notifications_enabled`, `obsess_over_host`,
			`passive_checks_enabled`, `process_perf_data`, `retain_nonstatus_information`, `retain_status_information`,
			`retry_interval`, `active`, `last_modified`, `modified_by`
			FROM `nagios_hosttemplate`
			WHERE `id` = ?");
			$Select_Host_Templates_Template->execute($Host_Templates_Template_ID);
			
			while ( my @DB_Host_Templates_Template = $Select_Host_Templates_Template->fetchrow_array() )
			{
	
				$Host_Description_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[0]</span>";
				my $Active_Checks_Enabled_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[1]</span>";
				my $Check_Freshness_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[2]</span>";
				$Check_Period_Extract_Templates_Template = $DB_Host_Templates_Template[3];
				my $Event_Handler_Enabled_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[4]</span>";
				my $Flap_Detection_Enabled_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[5]</span>";
				$Check_Command_Extract_Templates_Template = $DB_Host_Templates_Template[6];
				my $Max_Check_Attempts_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[7]</span>";
				my $Normal_Check_Interval_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[8]</span>";
				my $Notification_Interval_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[9]</span>";
				my $Notification_Options_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[10]</span>";
				$Notification_Period_Extract_Templates_Template = $DB_Host_Templates_Template[11];
				my $Notifications_Enabled_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[12]</span>";
				my $Obsess_Over_Host_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[13]</span>";
				my $Passive_Checks_Enabled_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[14]</span>";
				my $Process_Perf_Data_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[15]</span>";
				my $Retain_NonStatus_Information_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[16]</span>";
				my $Retain_Status_Information_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[17]</span>";
				my $Retry_Check_Interval_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[18]</span>";
				my $Active_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[19]</span>";
				$Last_Modified_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[20]</span>";
				$Modified_By_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Host_Templates_Template[21]</span>";

				if ($Active_Checks_Enabled_Extract eq "<span style='color: #FF8800;'></span>" || $Active_Checks_Enabled_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Active_Checks_Enabled_Extract = $Active_Checks_Enabled_Extract_Templates_Template;
				}
				if ($Check_Freshness_Extract eq "<span style='color: #FF8800;'></span>" || $Check_Freshness_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Check_Freshness_Extract = $Check_Freshness_Extract_Templates_Template;
				}
				if ($Event_Handler_Enabled_Extract eq "<span style='color: #FF8800;'></span>" || $Event_Handler_Enabled_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Event_Handler_Enabled_Extract = $Event_Handler_Enabled_Extract_Templates_Template;
				}
				if ($Flap_Detection_Enabled_Extract eq "<span style='color: #FF8800;'></span>" || $Flap_Detection_Enabled_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Flap_Detection_Enabled_Extract = $Flap_Detection_Enabled_Extract_Templates_Template;
				}
				if ($Max_Check_Attempts_Extract eq "<span style='color: #FF8800;'></span>" || $Max_Check_Attempts_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Max_Check_Attempts_Extract = $Max_Check_Attempts_Extract_Templates_Template;
				}
				if ($Normal_Check_Interval_Extract eq "<span style='color: #FF8800;'></span>" || $Normal_Check_Interval_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Normal_Check_Interval_Extract = $Normal_Check_Interval_Extract_Templates_Template;
				}
				if ($Notification_Interval_Extract eq "<span style='color: #FF8800;'></span>" || $Notification_Interval_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Notification_Interval_Extract = $Notification_Interval_Extract_Templates_Template;
				}
				if ($Notification_Options_Extract eq "<span style='color: #FF8800;'></span>" || $Notification_Options_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Notification_Options_Extract = $Notification_Options_Extract_Templates_Template;
				}
				if ($Notifications_Enabled_Extract eq "<span style='color: #FF8800;'></span>" || $Notifications_Enabled_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Notifications_Enabled_Extract = $Notifications_Enabled_Extract_Templates_Template;
				}
				if ($Obsess_Over_Host_Extract eq "<span style='color: #FF8800;'></span>" || $Obsess_Over_Host_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Obsess_Over_Host_Extract = $Obsess_Over_Host_Extract_Templates_Template;
				}
				if ($Passive_Checks_Enabled_Extract eq "<span style='color: #FF8800;'></span>" || $Passive_Checks_Enabled_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Passive_Checks_Enabled_Extract = $Passive_Checks_Enabled_Extract_Templates_Template;
				}
				if ($Process_Perf_Data_Extract eq "<span style='color: #FF8800;'></span>" || $Process_Perf_Data_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Process_Perf_Data_Extract = $Process_Perf_Data_Extract_Templates_Template;
				}
				if ($Retain_NonStatus_Information_Extract eq "<span style='color: #FF8800;'></span>" || $Retain_NonStatus_Information_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Retain_NonStatus_Information_Extract = $Retain_NonStatus_Information_Extract_Templates_Template;
				}
				if ($Retain_Status_Information_Extract eq "<span style='color: #FF8800;'></span>" || $Retain_Status_Information_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Retain_Status_Information_Extract = $Retain_Status_Information_Extract_Templates_Template;
				}
				if ($Retry_Check_Interval_Extract eq "<span style='color: #FF8800;'></span>" || $Retry_Check_Interval_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Retry_Check_Interval_Extract = $Retry_Check_Interval_Extract_Templates_Template;
				}
			}
		}

		## / Host Template's Template Values

		## Check Period Link Collection

		my $Check_Period;

		if ($Check_Period_Extract) {
			$Check_Period = $Check_Period_Extract;
		}
		elsif ($Check_Period_Extract_Template != 0) {
			$Check_Period = $Check_Period_Extract_Template;
		}
		elsif ($Check_Period_Extract_Templates_Template != 0) {
			$Check_Period = $Check_Period_Extract_Templates_Template;
		}

		my $Select_Check_Period = $DB_Icinga->prepare("SELECT `timeperiod_name`
		FROM `nagios_timeperiod`
		WHERE `id` = ?");
		$Select_Check_Period->execute($Check_Period);
		
		while ( my @DB_Time_Period = $Select_Check_Period->fetchrow_array() )
		{
			my $DB_Check_Period = $DB_Time_Period[0];

			if ($Check_Period_Extract_Templates_Template != 0) {
				$Check_Period = "<span style='color: #FF00FF;'>$DB_Check_Period</span>";
			}
			if ($Check_Period_Extract_Template != 0) {
				$Check_Period = "<span style='color: #FF8800;'>$DB_Check_Period</span>";
			}
			if ($Check_Period_Extract  != 0) {
				$Check_Period = $DB_Check_Period;
			}

		}

		## / Check Period Link Collection

		## Notification Period Link Collection

		my $Notification_Period;

		if ($Notification_Period_Extract) {
			$Notification_Period = $Notification_Period_Extract;
		}
		elsif ($Notification_Period_Extract_Template != 0) {
			$Notification_Period = $Notification_Period_Extract_Template;
		}
		elsif ($Notification_Period_Extract_Templates_Template != 0) {
			$Notification_Period = $Notification_Period_Extract_Templates_Template;
		}

		my $Select_Notification_Period = $DB_Icinga->prepare("SELECT `timeperiod_name`
		FROM `nagios_timeperiod`
		WHERE `id` = ?");
		$Select_Notification_Period->execute($Notification_Period);
		
		while ( my @DB_Time_Period = $Select_Notification_Period->fetchrow_array() )
		{
			my $DB_Notification_Period = $DB_Time_Period[0];

			if ($Notification_Period_Extract_Templates_Template != 0) {
				$Notification_Period = "<span style='color: #FF00FF;'>$DB_Notification_Period</span>";
			}
			if ($Notification_Period_Extract_Template != 0) {
				$Notification_Period = "<span style='color: #FF8800;'>$DB_Notification_Period</span>";
			}
			if ($Notification_Period_Extract  != 0) {
				$Notification_Period = $DB_Notification_Period;
			}

		}

		## / Notification Period Link Collection


		## Check Command Partial Conversion

		my $Check_Command_Where;
		if (!$Check_Command_Extract || $Check_Command_Extract eq '') {
			$Check_Command_Where = $Check_Command_Extract_Template;
		}
		else {
			$Check_Command_Where = $Check_Command_Extract;
		}

		my $Check_Command_Where_ID_Extract = $Check_Command_Where;
			$Check_Command_Where_ID_Extract =~ s/^(\d*).*/$1/g;
		my $Check_Command_Where_Remaining = $Check_Command_Where;
			$Check_Command_Where_Remaining =~ s/^\d*(.*)/$1/g;

		my $Check_Command;
		my $Select_Check_Command = $DB_Icinga->prepare("SELECT `command_name`
		FROM `nagios_command`
		WHERE `id` = '$Check_Command_Where_ID_Extract'");
		$Select_Check_Command->execute();

			while ( my @DB_Command = $Select_Check_Command->fetchrow_array() )
			{

				$Check_Command = $DB_Command[0];
				$Check_Command = $Check_Command.$Check_Command_Where_Remaining;

				if (!$Check_Command_Extract || $Check_Command_Extract eq '') {
					$Check_Command = "<span style='color: #FF8800;'>$Check_Command</span>";
				}

			}

		## / Check Command Partial Conversion

		$Host_Parents =~ s/,$//g;
		$Host_Templates =~ s/,$//g;
		$Host_Contact_Groups =~ s/,$//g;
		$Host_Template_ID = "<span style='color: #FF8800;'>$Host_Template_ID</span>";
		$Host_Templates_Template_ID = "<span style='color: #FF00FF;'>$Host_Templates_Template_ID</span>";
		
		if (!$Host_Contact_Groups) {$Host_Contact_Groups = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if (!$Check_Period) {$Check_Period = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Max_Check_Attempts_Extract =~ m/></) {$Max_Check_Attempts_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Active_Checks_Enabled_Extract =~ m/>2</) {$Active_Checks_Enabled_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Passive_Checks_Enabled_Extract =~ m/>2</) {$Passive_Checks_Enabled_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Obsess_Over_Host_Extract =~ m/>2</) {$Obsess_Over_Host_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Check_Freshness_Extract =~ m/>2</) {$Check_Freshness_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Event_Handler_Enabled_Extract =~ m/>2</) {$Event_Handler_Enabled_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Flap_Detection_Enabled_Extract =~ m/>2</) {$Flap_Detection_Enabled_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Notifications_Enabled_Extract =~ m/>2</) {$Notifications_Enabled_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Process_Perf_Data_Extract =~ m/>2</) {$Notifications_Enabled_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Retain_NonStatus_Information_Extract =~ m/>2</) {$Retain_NonStatus_Information_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Retain_Status_Information_Extract =~ m/>2</) {$Retain_Status_Information_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if (!$Check_Command) {$Check_Command = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Normal_Check_Interval_Extract =~ m/></) {$Normal_Check_Interval_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Retry_Check_Interval_Extract =~ m/></) {$Retry_Check_Interval_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if (!$Host_Parents) {$Host_Parents = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		


		if (!$Active_Extract) {
			$Active_Extract="<span style='color: #FF8A00;'>
			This host is not active, so this config will not be written. 
			Make this host active to use it in Icinga.</span>";
		}
		else {
			$Active_Extract="";
		}

print <<ENDHTML;
<div id="full-width-popup-box">
<a href="/Icinga/icinga-hosts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Live Config for <span style="color: #00FF00;">$Host_Extract</span></h3>

<p>This config is automatically applied regularly. The config below illustrates how this host's config will be written.<br />
ENDHTML

if ($Host_Template_ID !~ /></) {
	print 'The values in <span style="color: #FF8800;">orange</span> are undefined in this host, and are therefore inherited from this host\'s template.<br />';
}
if ($Host_Templates_Template_ID !~ /></) {
	print 'The values in <span style="color: #FF00FF;">purple</span> are not defined in this host, nor this host\'s template, so are collected from the host template\'s template.';
}

print <<ENDHTML;

</p>

<p>$Active_Extract</p>
<div style="text-align: left;">
<code>
<table align = "center">
	<tr>
		<td colspan='3'>## Host ID: $Display_Config</td>
	</tr>
	<tr>
		<td colspan='3'>## Host Modified $Last_Modified_Extract by $Modified_By_Extract</td>
	</tr>
	<tr>
		<td colspan='3'>## Host Notes: $Host_Notes_Extract</td>
	</tr>
ENDHTML

if ($Host_Template_ID !~ /></) {
	print <<ENDHTML;
	<tr>
		<td colspan='3'>## Template ID: $Host_Template_ID</td>
	</tr>
	<tr>
		<td colspan='3'>## Template Name: $Host_Description_Extract_Template</td>
	</tr>
	<tr>
		<td colspan='3'>## Template Modified: $Last_Modified_Extract_Template by $Modified_By_Extract_Template</td>
	</tr>

ENDHTML
}
if ($Host_Templates_Template_ID !~ /></) {
	print <<ENDHTML;
	<tr>
		<td colspan='3'>## Template's Template ID: $Host_Templates_Template_ID</td>
	</tr>
	<tr>
		<td colspan='3'>## Template's Template Name: $Host_Description_Extract_Templates_Template</td>
	</tr>
	<tr>
		<td colspan='3'>## Template's Template Modified: $Last_Modified_Extract_Templates_Template by $Modified_By_Extract_Templates_Template</td>
	</tr>

ENDHTML
}

print <<ENDHTML;
	<tr>
		<td colspan='3'>define host {</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>use</td>
		<td style='padding-left: 2em;'>$Host_Templates</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>host_name</td>
		<td style='padding-left: 2em;'>$Host_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>alias</td>
		<td style='padding-left: 2em;'>$Alias_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>address</td>
		<td style='padding-left: 2em;'>$IP_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>contact_groups</td>
		<td style='padding-left: 2em;'>$Host_Contact_Groups</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>active_checks_enabled</td>
		<td style='padding-left: 2em;'>$Active_Checks_Enabled_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>passive_checks_enabled</td>
		<td style='padding-left: 2em;'>$Passive_Checks_Enabled_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>check_period</td>
		<td style='padding-left: 2em;'>$Check_Period</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>obsess_over_host</td>
		<td style='padding-left: 2em;'>$Obsess_Over_Host_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>check_freshness</td>
		<td style='padding-left: 2em;'>$Check_Freshness_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>event_handler_enabled</td>
		<td style='padding-left: 2em;'>$Event_Handler_Enabled_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>flap_detection_enabled</td>
		<td style='padding-left: 2em;'>$Flap_Detection_Enabled_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>check_command</td>
		<td style='padding-left: 2em;'>$Check_Command</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>notification_interval</td>
		<td style='padding-left: 2em;'>$Notification_Interval_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>max_check_attempts</td>
		<td style='padding-left: 2em;'>$Max_Check_Attempts_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>normal_check_interval</td>
		<td style='padding-left: 2em;'>$Normal_Check_Interval_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>retry_check_interval</td>
		<td style='padding-left: 2em;'>$Retry_Check_Interval_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>notification_period</td>
		<td style='padding-left: 2em;'>$Notification_Period</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>notification_options</td>
		<td style='padding-left: 2em;'>$Notification_Options_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>notifications_enabled</td>
		<td style='padding-left: 2em;'>$Notifications_Enabled_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>process_perf_data</td>
		<td style='padding-left: 2em;'>$Process_Perf_Data_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>retain_nonstatus_information</td>
		<td style='padding-left: 2em;'>$Retain_NonStatus_Information_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>retain_status_information</td>
		<td style='padding-left: 2em;'>$Retain_Status_Information_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>parents</td>
		<td style='padding-left: 2em;'>$Host_Parents</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>register</td>
		<td style='padding-left: 2em;'>1</td>
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

sub html_display_notes {

	my $Select_Notes = $DB_Icinga->prepare("SELECT `host_name`, `alias`, `address`, `notes`
	FROM `nagios_host`
	WHERE `id` = ?");
	$Select_Notes->execute($Host_Notes);
	
	while ( my @DB_Notes = $Select_Notes->fetchrow_array() )
	{
	
		my $Host_Extract = $DB_Notes[0];
		my $Alias_Extract = $DB_Notes[1];
		my $IP_Extract = $DB_Notes[2];
		my $Notes_Extract = $DB_Notes[3];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/Icinga/icinga-hosts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Update Notes</h3>

<table align="center">
	<tr>
		<td>Hostname:</td>
		<td style='color: #00FF00; text-align: left;'>$Host_Extract</td>
	</tr>
	<tr>
		<td>Alias:</td>
		<td style='color: #00FF00; text-align: left;'>$Alias_Extract</td>
	</tr>
	<tr>
		<td>IP:</td>
		<td style='color: #00FF00; text-align: left;'>$IP_Extract</td>
	</tr>
</table>

<form action='/Icinga/icinga-hosts.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Notes:</td>
		<td><textarea rows='4' cols='50' maxlength='255' name='Host_Note_Update' placeholder="$Notes_Extract" autofocus>$Notes_Extract</textarea></td>
	</tr>
</table>

<input type='hidden' name='Host_Note_Update_ID' value='$Host_Notes'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Update Notes'></div>

</form>

</div>

ENDHTML

	}

} #sub html_display_notes

sub update_notes {

		my $Host_Update = $DB_Icinga->prepare("UPDATE `nagios_host` SET
			`notes` = ?,
			`last_modified` = NOW(),
			`modified_by` = '$User_Name'
			WHERE `id` = ?"
		);

		$Host_Update->execute($Host_Note_Update, $Host_Note_Update_ID)

} # sub update_notes

sub html_output {

	my $Table = new HTML::Table(
		-cols=>16,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);


	$Table->addRow ( "ID", "Name", "Alias", "IP", "Host Groups", "Parent", "Children", "Host Templates", "Contact Groups", "Active",
	"Last Modified", "Modified By", "Host Notes", "View Config", "Edit (todo)", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Select_Hosts_Count = $DB_Icinga->prepare("SELECT `id` FROM `nagios_host`");
		$Select_Hosts_Count->execute( );
		my $Total_Rows = $Select_Hosts_Count->rows();

	my $Select_Hosts = $DB_Icinga->prepare("SELECT `id`, `host_name`, `alias`, `address`, `active`, `last_modified`, `modified_by`
	FROM `nagios_host`
	WHERE (`id` LIKE '%$Filter%'
	OR `host_name` LIKE '%$Filter%'
	OR `alias` LIKE '%$Filter%'
	OR `address` LIKE '%$Filter%')
	ORDER BY `host_name` ASC
	LIMIT 0 , $Rows_Returned");

	$Select_Hosts->execute( );
	my $Rows = $Select_Hosts->rows();
	
	$Table->setRowClass(1, 'tbrow1');

	my $User_Row_Count=1;
	while ( my @DB_Host = $Select_Hosts->fetchrow_array() )
	{
	
		$User_Row_Count++;
	
		my $ID_Extract = $DB_Host[0];
			my $ID_Extract_Display = $ID_Extract;
			$ID_Extract_Display =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Name_Extract = $DB_Host[1];
			my $Name = $Name_Extract;
			$Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Alias_Extract = $DB_Host[2];
			$Alias_Extract =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $IP_Extract = $DB_Host[3];
			$IP_Extract =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Active_Extract = $DB_Host[4];
		my $Last_Modified_Extract = $DB_Host[5];
		my $Modified_By_Extract = $DB_Host[6];


		## Host to Host Group

		my $Host_Groups;
		my $Select_Host_Group_Link = $DB_Icinga->prepare("SELECT `idSlave`
		FROM `nagios_lnkHostToHostgroup`
		WHERE (`idMaster` = '$ID_Extract')");
		$Select_Host_Group_Link->execute();

			while ( my @DB_Group_Link = $Select_Host_Group_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Group_Link[0];

				my $Select_Host = $DB_Icinga->prepare("SELECT `hostgroup_name`
				FROM `nagios_hostgroup`
				WHERE `id` = '$Host_Link'");
				$Select_Host->execute();

				while ( my @DB_Group = $Select_Host->fetchrow_array() )
				{

					my $Host_Group = $DB_Group[0];
					$Host_Groups = "<a href='/Icinga/icinga-host-groups.cgi?Filter=$Host_Group'>$Host_Group</a><br />".$Host_Groups;

				}
			}

		## / Host to Host Group

		## Host Parent Resolution

		my $Host_Parents;
		my $Select_Host_Parent_Link = $DB_Icinga->prepare("SELECT `idSlave`
		FROM `nagios_lnkHostToHost`
		WHERE (`idMaster` = '$ID_Extract')");
		$Select_Host_Parent_Link->execute();

			while ( my @DB_Parent_Link = $Select_Host_Parent_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Parent_Link[0];

				my $Select_Host = $DB_Icinga->prepare("SELECT `host_name`
				FROM `nagios_host`
				WHERE `id` = '$Host_Link'");
				$Select_Host->execute();

				while ( my @DB_Parent = $Select_Host->fetchrow_array() )
				{

					my $Host_Parent = $DB_Parent[0];
					$Host_Parents = "<a href='/Icinga/icinga-hosts.cgi?Filter=$Host_Parent'>$Host_Parent</a><br />".$Host_Parents;

				}
			}

		## / Host Parent Resolution

		## Host Children Resolution

		my $Host_Children;
		my $Select_Host_Child_Link = $DB_Icinga->prepare("SELECT `idMaster`
		FROM `nagios_lnkHostToHost`
		WHERE (`idSlave` = '$ID_Extract')");
		$Select_Host_Child_Link->execute();

			while ( my @DB_Child_Link = $Select_Host_Child_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Child_Link[0];

				my $Select_Host = $DB_Icinga->prepare("SELECT `host_name`
				FROM `nagios_host`
				WHERE `id` = '$Host_Link'");
				$Select_Host->execute();

				while ( my @DB_Child = $Select_Host->fetchrow_array() )
				{

					my $Host_Child = $DB_Child[0];
					$Host_Children = "<a href='/Icinga/icinga-hosts.cgi?Filter=$Host_Child'>$Host_Child</a><br />".$Host_Children;

				}
			}

		## / Host Children Resolution

		## Host Template Resolution

		my $Host_Templates;
		my $Select_Host_Template_Link = $DB_Icinga->prepare("SELECT `idSlave`
		FROM `nagios_lnkHostToHosttemplate`
		WHERE (`idMaster` = '$ID_Extract')");
		$Select_Host_Template_Link->execute();

			while ( my @DB_Template_Link = $Select_Host_Template_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Template_Link[0];

				my $Select_Host = $DB_Icinga->prepare("SELECT `template_name`
				FROM `nagios_hosttemplate`
				WHERE `id` = '$Host_Link'");
				$Select_Host->execute();

				while ( my @DB_Template = $Select_Host->fetchrow_array() )
				{

					my $Host_Template = $DB_Template[0];
					$Host_Templates = "<a href='/Icinga/icinga-host-templates.cgi?Filter=$Host_Template'>$Host_Template</a><br />".$Host_Templates;

				}
			}

		## / Host Template Resolution

		## Host Contact Group Resolution

		my $Host_Contact_Groups;
		my $Select_Host_Contact_Group_Link = $DB_Icinga->prepare("SELECT `idSlave`
		FROM `nagios_lnkHostToContactgroup`
		WHERE (`idMaster` = '$ID_Extract')");
		$Select_Host_Contact_Group_Link->execute();

			while ( my @DB_Contact_Group_Link = $Select_Host_Contact_Group_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Contact_Group_Link[0];

				my $Select_Host = $DB_Icinga->prepare("SELECT `contactgroup_name`
				FROM `nagios_contactgroup`
				WHERE `id` = '$Host_Link'");
				$Select_Host->execute();

				while ( my @DB_Contact_Group = $Select_Host->fetchrow_array() )
				{

					my $Host_Contact_Group = $DB_Contact_Group[0];
					$Host_Contact_Groups = "<a href='/Icinga/icinga-contact-groups.cgi?Filter=$Host_Contact_Group'>$Host_Contact_Group</a><br />".$Host_Contact_Groups;

				}
			}

		## / Host Contact Group Resolution


		$Host_Groups =~ s/,$//g;
		$Host_Parents =~ s/,$//g;
		$Host_Children =~ s/,$//g;
		$Host_Templates =~ s/,$//g;

		if ($Active_Extract) {$Active_Extract='Yes';} else {$Active_Extract='No';}

		$Table->addRow(
			"<a href='/Icinga/icinga-hosts.cgi?Edit_Host=$ID_Extract'>$ID_Extract_Display</a>",
			"<a href='/Icinga/icinga-hosts.cgi?Edit_Host=$ID_Extract'>$Name</a>",
			$Alias_Extract,
			$IP_Extract,
			$Host_Groups,
			$Host_Parents,
			$Host_Children,
			$Host_Templates,
			$Host_Contact_Groups,
			$Active_Extract,
			$Last_Modified_Extract,
			$Modified_By_Extract,
			"<a href='/Icinga/icinga-hosts.cgi?Host_Notes=$ID_Extract'><img src=\"/resources/imgs/add-note.png\" alt=\"View/Edit Notes for $Name_Extract\" ></a>",
			"<a href='/Icinga/icinga-hosts.cgi?Display_Config=$ID_Extract'><img src=\"/resources/imgs/view-notes.png\" alt=\"View Config for $Name_Extract\" ></a>",
			"<a href='/Icinga/icinga-hosts.cgi?Edit_Host=$ID_Extract'><img src=\"/resources/imgs/edit.png\" alt=\"Edit $Name_Extract\" ></a>",
			"<a href='/Icinga/icinga-hosts.cgi?Delete_Host=$ID_Extract'><img src=\"/resources/imgs/delete.png\" alt=\"Delete $Name_Extract\" ></a>"
		);

		for (10 .. 16) {
			$Table->setColWidth($_, '1px');
			$Table->setColAlign($_, 'center');
		}

		if ($Active_Extract eq 'Yes') {
			$Table->setCellClass ($User_Row_Count, 10, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($User_Row_Count, 10, 'tbroworange');
		}

	}

print <<ENDHTML;

<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/Icinga/icinga-hosts.cgi' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Hosts" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/Icinga/icinga-hosts.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Host</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Host' value='Add Host'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/Icinga/icinga-hosts.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Host</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Host' value='Edit Host'></td>
					<td align="center">
						<select name='Edit_Host' style="width: 150px">
ENDHTML

						my $Host_List_Query = $DB_Icinga->prepare("SELECT `id`, `host_name`
						FROM `nagios_host`
						ORDER BY `host_name` ASC");
						$Host_List_Query->execute( );
						
						while ( (my $ID, my $Host_Name) = my @Host_List_Query = $Host_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Host_Name</option>";
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

<p style="font-size:14px; font-weight:bold;">Icinga Hosts | Hosts Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML

} #sub html_output end
