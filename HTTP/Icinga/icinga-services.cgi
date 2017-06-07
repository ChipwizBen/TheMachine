#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);

use HTML::Table;

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Service = $CGI->param("Add_Service");
my $Edit_Service = $CGI->param("Edit_Service");

my $Template_Add = $CGI->param("Template_Add");
my $Name_Add = $CGI->param("Name_Add");
my $Service_Group_Add = $CGI->param("Service_Group_Add");
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
my $Parallelize_Checks_Add = $CGI->param("Parallelize_Checks_Add");
my $Obsess_Over_Service_Add = $CGI->param("Obsess_Over_Service_Add");
my $Check_Freshness_Add = $CGI->param("Check_Freshness_Add");
my $Notifications_Add = $CGI->param("Notifications_Add");
my $Event_Handler_Add = $CGI->param("Event_Handler_Add");
my $Flap_Detection_Add = $CGI->param("Flap_Detection_Add");
my $Process_Performance_Data_Add = $CGI->param("Process_Performance_Data_Add");
my $Retain_Status_Information_Add = $CGI->param("Retain_Status_Information_Add");
my $Retain_NonStatus_Information_Add = $CGI->param("Retain_NonStatus_Information_Add");
my $Is_Volatile_Add = $CGI->param("Is_Volatile_Add");
my $Notification_Add_Inherit = $CGI->param("Notification_Add_Inherit");
	my $Notification_Add_C = $CGI->param("Notification_Add_C");
	my $Notification_Add_W = $CGI->param("Notification_Add_W");
	my $Notification_Add_U = $CGI->param("Notification_Add_U");
	my $Notification_Add_R = $CGI->param("Notification_Add_R");
	my $Notification_Add_F = $CGI->param("Notification_Add_F");
	my $Notification_Add_S = $CGI->param("Notification_Add_S");
my $Active_Add = $CGI->param("Active_Add");

my $Service_Edit_Post = $CGI->param("Service_Edit_Post");
my $Service_Name_Edit = $CGI->param("Service_Name_Edit");
my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Service = $CGI->param("Delete_Service");
my $Service_Delete_Post = $CGI->param("Service_Delete_Post");
my $Service_Delete = $CGI->param("Service_Delete");

my $Display_Config = $CGI->param("Display_Config");
my $Linked_Hosts = $CGI->param("Linked_Hosts");

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

if ($Add_Service) {
	require $Header;
	&html_output;
	&html_add_service;
}
elsif ($Name_Add) {
	&add_service;
	if ($Active_Add) {
		my $Message_Green="$Name_Add added successfully and set active";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
	}
	else {
		my $Message_Orange="$Name_Add added successfully but set inactive";
		$Session->param('Message_Orange', $Message_Orange);
		$Session->flush();
	}
	
	print "Location: /Icinga/icinga-services.cgi\n\n";
	exit(0);
}
elsif ($Edit_Service) {
	require $Header;
	&html_output;
	&html_edit_service;
}
elsif ($Service_Edit_Post) {
	&edit_service;
	my $Message_Green="$Service_Name_Edit edited successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /Icinga/icinga-services.cgi\n\n";
	exit(0);
}
elsif ($Delete_Service) {
	require $Header;
	&html_output;
	&html_delete_service;
}
elsif ($Service_Delete_Post) {
	&delete_service;
	my $Message_Green="$Service_Delete deleted successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /Icinga/icinga-services.cgi\n\n";
	exit(0);
}
elsif ($Linked_Hosts) {
	require $Header;
	&html_output;
	&html_linked_hosts;
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



sub html_add_service {

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/Icinga/icinga-services.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Service</h3>

<form action='/Icinga/icinga-services.cgi' method='post' >

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
		
		
							my $Select_Templates = $DB_Connection->prepare("SELECT `id`, `template_name`
							FROM `icinga2_servicetemplate`
							WHERE `active` = '1'
							ORDER BY `template_name` ASC");
							$Select_Templates->execute();
					
							while ( my @DB_Service = $Select_Templates->fetchrow_array() )
							{
								my $ID_Extract = $DB_Service[0];
								my $Name_Extract = $DB_Service[1];
								print "<option value='$ID_Extract'>$Name_Extract</option>";
							}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Name:</td>
					<td colspan="3"><input type='text' name='Name_Add' style="width: 200px" maxlength='255' placeholder="Name" required autofocus></td>
				</tr>
				<tr>
					<td style="text-align: right;">Service Group:</td>
					<td colspan="3">
						<select name='Service_Group_Add' style="width: 200px">
							<option value='0'>-- Inherit Service Group --</option>
ENDHTML
		
		
							my $Select_Service_Groups = $DB_Connection->prepare("SELECT `id`, `servicegroup_name`
							FROM `icinga2_servicegroup`
							WHERE `active` = '1'
							ORDER BY `servicegroup_name` ASC");
							$Select_Service_Groups->execute();
					
							while ( my @DB_Service = $Select_Service_Groups->fetchrow_array() )
							{
								my $ID_Extract = $DB_Service[0];
								my $Name_Extract = $DB_Service[1];
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
		
		
							my $Select_Check_Periods = $DB_Connection->prepare("SELECT `id`, `timeperiod_name`, `alias`
							FROM `icinga2_timeperiod`
							WHERE `active` = '1'
							ORDER BY `timeperiod_name` ASC");
							$Select_Check_Periods->execute();
					
							while ( my @DB_Service = $Select_Check_Periods->fetchrow_array() )
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
		
		
							my $Select_Notification_Periods = $DB_Connection->prepare("SELECT `id`, `timeperiod_name`, `alias`
							FROM `icinga2_timeperiod`
							WHERE `active` = '1'
							ORDER BY `timeperiod_name` ASC");
							$Select_Notification_Periods->execute();
					
							while ( my @DB_Service = $Select_Notification_Periods->fetchrow_array() )
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
					<td style="text-align: right;">Contact:</td>
					<td colspan="3">
						<select name='Contact_Add' style="width: 200px">
							<option value='0'>-- Inherit Contact --</option>
ENDHTML
		
		
							my $Select_Contacts = $DB_Connection->prepare("SELECT `id`, `contact_name`, `alias`
							FROM `icinga2_contact`
							WHERE `active` = '1'
							ORDER BY `contact_name` ASC");
							$Select_Contacts->execute();
					
							while ( my @DB_Service = $Select_Contacts->fetchrow_array() )
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
					<td style="text-align: right;">Contact Group:</td>
					<td colspan="3">
						<select name='Contact_Group_Add' style="width: 200px">
							<option value='0'>-- Inherit Contact Group --</option>
ENDHTML
		
		
							my $Select_Contact_Groups = $DB_Connection->prepare("SELECT `id`, `contactgroup_name`, `alias`
							FROM `icinga2_contactgroup`
							WHERE `active` = '1'
							ORDER BY `contactgroup_name` ASC");
							$Select_Contact_Groups->execute();
					
							while ( my @DB_Service = $Select_Contact_Groups->fetchrow_array() )
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
			
			
						my $Select_Check_Commands = $DB_Connection->prepare("SELECT `id`, `command_name`
						FROM `icinga2_command`
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
					<td style="text-align: right;">Parallelize Checks:</td>
					<td style='text-align: left;'><input type="radio" name="Parallelize_Checks_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Parallelize_Checks_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Parallelize_Checks_Add" value="2" checked> Inherit</td>
				</tr>
				<tr>
					<td style="text-align: right;">Obsess Over Service:</td>
					<td style='text-align: left;'><input type="radio" name="Obsess_Over_Service_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Obsess_Over_Service_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Obsess_Over_Service_Add" value="2" checked> Inherit</td>
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
				<tr>
					<td style="text-align: right;">Is Volatile:</td>
					<td style='text-align: left;'><input type="radio" name="Is_Volatile_Add" value="1"> Yes</td>
					<td style='text-align: left;'><input type="radio" name="Is_Volatile_Add" value="0"> No</td>
					<td style='text-align: left;'><input type="radio" name="Is_Volatile_Add" value="2" checked> Inherit</td>
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
					<td style='color: #FF0000; text-align: left;'><input type="checkbox" name="Notification_Add_C" value="c" checked>Critical</td>
					<td style='color: #FF8800; text-align: left;'><input type="checkbox" name="Notification_Add_W" value="w" checked>Warning</td>
				</tr>
				<tr>
					<td style='color: #AAAAAA; text-align: left;'><input type="checkbox" name="Notification_Add_U" value="u" checked>Unknown</td>
					<td style='color: #00FF00; text-align: left;'><input type="checkbox" name="Notification_Add_R" value="r" checked>Recovery</td>
				</tr>
				<tr>
					<td style='color: #FFFF00; text-align: left;'><input type="checkbox" name="Notification_Add_F" value="f" checked>Flapping</td>
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
<div style="text-align: center"><input type=submit name='ok' value='Add Service'></div>
</form>

</div>

ENDHTML

} #sub html_add_service

sub add_service {

	if ($Max_Check_Attempts_Add_Inherit eq 2) {$Max_Check_Attempts_Add = undef};
	if ($Normal_Check_Interval_Add_Inherit eq 2) {$Normal_Check_Interval_Add = undef};
	if ($Retry_Check_Interval_Add_Inherit eq 2) {$Retry_Check_Interval_Add = undef};
	if ($Notification_Interval_Add_Inherit eq 2) {$Notification_Interval_Add = undef};

	if ($Check_Command_Options) {$Check_Command_Add = $Check_Command_Add."!".$Check_Command_Options};
		$Check_Command_Add =~ s/!!/!/g;

	my $Notification_Options_Add;
	if ($Notification_Add_C) {$Notification_Options_Add = "$Notification_Add_C,$Notification_Options_Add"}
	if ($Notification_Add_W) {$Notification_Options_Add = "$Notification_Add_W,$Notification_Options_Add"}
	if ($Notification_Add_U) {$Notification_Options_Add = "$Notification_Add_U,$Notification_Options_Add"}
	if ($Notification_Add_R) {$Notification_Options_Add = "$Notification_Add_R,$Notification_Options_Add"}
	if ($Notification_Add_F) {$Notification_Options_Add = "$Notification_Add_F,$Notification_Options_Add"}
	if ($Notification_Add_S) {$Notification_Options_Add = "$Notification_Add_S,$Notification_Options_Add"}
	$Notification_Options_Add =~ s/,$//g;
	if ($Notification_Add_Inherit eq 2) {$Notification_Options_Add = undef};

	my $Service_Insert = $DB_Connection->prepare("INSERT INTO `icinga2_service` (
		`id`, `service_description`, `active_checks_enabled`, `check_freshness`, `check_period`, `event_handler_enabled`, `flap_detection_enabled`,
		`check_command`, `is_volatile`, `max_check_attempts`, `check_interval`, `notification_interval`, `notification_options`, `notification_period`,
		`notifications_enabled`, `obsess_over_service`, `parallelize_check`, `passive_checks_enabled`, `process_perf_data`,
		`retain_nonstatus_information`, `retain_status_information`, `retry_interval`, `active`, `last_modified`, `modified_by`
	)
	VALUES (
		NULL, ?, ?, ?, ?, ?, ?,
		?, ?, ?, ?, ?, ?, ?,
		?, ?, ?, ?, ?,
		?, ?, ?, ?,	NOW(), '$Username'
	)");

	$Service_Insert->execute($Name_Add, $Active_Checks_Add, $Check_Freshness_Add, $Check_Period_Add, $Event_Handler_Add, $Flap_Detection_Add,
	$Check_Command_Add, $Is_Volatile_Add, $Max_Check_Attempts_Add, $Normal_Check_Interval_Add, $Notification_Interval_Add, $Notification_Options_Add, $Notification_Period_Add,
	$Notifications_Add, $Obsess_Over_Service_Add, $Parallelize_Checks_Add, $Passive_Checks_Add, $Process_Performance_Data_Add,
	$Retain_NonStatus_Information_Add, $Retain_Status_Information_Add, $Retry_Check_Interval_Add, $Active_Add);

	my $Service_Insert_ID = $DB_Connection->{mysql_insertid};


	if ($Template_Add) {

		my $Template_Insert = $DB_Connection->prepare("INSERT INTO `icinga2_lnkServiceToServicetemplate` (
		`idMaster`, `idSlave`
		)
		VALUES (
		?, ?
		)");

		$Template_Insert->execute($Service_Insert_ID, $Template_Add);

	}

	if ($Contact_Add) {

		my $Contact_Insert = $DB_Connection->prepare("INSERT INTO `icinga2_lnkServiceToContact` (
		`idMaster`, `idSlave`
		)
		VALUES (
		?, ?
		)");

		$Contact_Insert->execute($Service_Insert_ID, $Contact_Add);

	}

	if ($Contact_Group_Add) {

		my $Contact_Group_Insert = $DB_Connection->prepare("INSERT INTO `icinga2_lnkServiceToContactgroup` (
		`idMaster`, `idSlave`
		)
		VALUES (
		?, ?
		)");

		$Contact_Group_Insert->execute($Service_Insert_ID, $Contact_Group_Add);

	}

	if ($Service_Group_Add) {

		my $Contact_Group_Insert = $DB_Connection->prepare("INSERT INTO `icinga2_lnkServiceToServicegroup` (
		`idMaster`, `idSlave`
		)
		VALUES (
		?, ?
		)");

		$Contact_Group_Insert->execute($Service_Insert_ID, $Service_Group_Add);

	}

} # sub add_service

sub html_edit_service {

	my $Select_Service = $DB_Connection->prepare("SELECT `config_name`, `service_description`, `active`
	FROM `icinga2_service`
	WHERE `id` = '$Edit_Service'");
	$Select_Service->execute( );
	
	while ( my @DB_Service = $Select_Service->fetchrow_array() )
	{
	
		my $Service_Extract = $DB_Service[0];
		my $Service_Name_Extract = $DB_Service[1];
		my $Active_Extract = $DB_Service[2];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/Icinga/icinga-services.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Editing Service <span style="color: #00FF00;">$Service_Extract</span></h3>

<form action='/Icinga/icinga-services.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Name:</td>
		<td colspan="2"><input type='text' name='Service_Name_Edit' value='$Service_Name_Extract' size='15' maxlength='100' placeholder="Service Name" required></td>
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

<input type='hidden' name='Service_Edit_Post' value='$Edit_Service'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Service'></div>

</form>

ENDHTML

	}
} # sub html_edit_service

sub edit_service {

	my $Service_Insert_Check = $DB_Connection->prepare("SELECT `id`, `service_description`
	FROM `icinga2_service`
	WHERE `config_name` = '$Service_Name_Edit'
	AND `id` != '$Service_Edit_Post'");

	$Service_Insert_Check->execute( );
	my $Service_Rows = $Service_Insert_Check->rows();

	if ($Service_Rows) {
		while ( my @DB_Service = $Service_Insert_Check->fetchrow_array() )
			{

			my $ID_Extract = $DB_Service[0];
			my $Service_Name_Extract = $DB_Service[1];

			my $Message_Red="$Service_Name_Edit already exists - Conflicting Service ID (This entry): $Service_Edit_Post, Existing Service ID: $ID_Extract, Existing Service Description: $Service_Name_Extract";
			$Session->param('Message_Red', $Message_Red);
			$Session->flush();
			print "Location: /Icinga/icinga-services.cgi\n\n";
			exit(0);

		}
	}
	else {

		my $Service_Update = $DB_Connection->prepare("UPDATE `icinga2_service` SET
			`config_name` = ?,
			`active` = ?,
			`last_modified` = NOW(),
			`modified_by` = '$Username'
			WHERE `id` = ?"
		);
		
		$Service_Update->execute($Service_Name_Edit, $Active_Edit, $Service_Edit_Post)
	}

} # sub edit_service

sub html_delete_service {

	my $Select_Service = $DB_Connection->prepare("SELECT `id`, `service_description`
	FROM `icinga2_service`
	WHERE `id` = '$Delete_Service'");
	$Select_Service->execute( );
	
	while ( my @DB_Service = $Select_Service->fetchrow_array() )
	{

		my $Service_ID_Extract = $DB_Service[0];
		my $Service_Name_Extract = $DB_Service[1];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/Icinga/icinga-services.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Service</h3>

<form action='/Icinga/icinga-services.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this service group?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Service ID:</td>
		<td style="text-align: left; color: #00FF00;">$Service_ID_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Service Description:</td>
		<td style="text-align: left; color: #00FF00;">$Service_Name_Extract</td>
	</tr>
</table>

<input type='hidden' name='Service_Delete_Post' value='$Delete_Service'>
<input type='hidden' name='Service_Delete' value='$Service_Name_Extract'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Service'></div>

</form>

</div>

ENDHTML

	}
} # sub html_delete_service

sub delete_service {

	my $Delete = $DB_Connection->prepare("DELETE from `icinga2_service`
				WHERE `id` = ?");
	$Delete->execute($Service_Delete_Post);

	$Delete = $DB_Connection->prepare("DELETE from `icinga2_lnkServiceToServicetemplate`
				WHERE `idMaster` = ?");
	$Delete->execute($Service_Delete_Post);

	$Delete = $DB_Connection->prepare("DELETE from `icinga2_lnkServiceToContact`
				WHERE `idMaster` = ?");
	$Delete->execute($Service_Delete_Post);

	$Delete = $DB_Connection->prepare("DELETE from `icinga2_lnkServiceToContactgroup`
				WHERE `idMaster` = ?");
	$Delete->execute($Service_Delete_Post);

	$Delete = $DB_Connection->prepare("DELETE from `icinga2_lnkServiceToServicegroup`
				WHERE `idMaster` = ?");
	$Delete->execute($Service_Delete_Post);

} # sub delete_service

sub html_display_config {

	my $Select_Service = $DB_Connection->prepare("SELECT `service_description`, `active_checks_enabled`, `check_freshness`, 
	`check_period`, `event_handler_enabled`, `flap_detection_enabled`, `check_command`, `is_volatile`, `max_check_attempts`,
	`check_interval`, `notification_interval`, `notification_options`, `notification_period`, `notifications_enabled`,
	`obsess_over_service`, `parallelize_check`, `passive_checks_enabled`, `process_perf_data`, `retain_nonstatus_information`,
	`retain_status_information`, `retry_interval`, `active`, `last_modified`, `modified_by`
	FROM `icinga2_service`
	WHERE `id` = ?");
	$Select_Service->execute($Display_Config);
	
	while ( my @DB_Service = $Select_Service->fetchrow_array() )
	{
	
		my $Service_Name_Extract = $DB_Service[0];
		my $Active_Checks_Enabled_Extract = $DB_Service[1];
		my $Check_Freshness_Extract = $DB_Service[2];
		my $Check_Period_Extract = $DB_Service[3];
		my $Event_Handler_Enabled_Extract = $DB_Service[4];
		my $Flap_Detection_Enabled_Extract = $DB_Service[5];
		my $Check_Command_Extract = $DB_Service[6];
		my $Is_Volatile_Extract = $DB_Service[7];
		my $Max_Check_Attempts_Extract = $DB_Service[8];
		my $Normal_Check_Interval_Extract = $DB_Service[9];
		my $Notification_Interval_Extract = $DB_Service[10];
		my $Notification_Options_Extract = $DB_Service[11];
		my $Notification_Period_Extract = $DB_Service[12];
		my $Notifications_Enabled_Extract = $DB_Service[13];
		my $Obsess_Over_Service_Extract = $DB_Service[14];
		my $Parallelize_Check_Extract = $DB_Service[15];
		my $Passive_Checks_Enabled_Extract = $DB_Service[16];
		my $Process_Perf_Data_Extract = $DB_Service[17];
		my $Retain_NonStatus_Information_Extract = $DB_Service[18];
		my $Retain_Status_Information_Extract = $DB_Service[19];
		my $Retry_Check_Interval_Extract = $DB_Service[20];
		my $Active_Extract = $DB_Service[21];
		my $Last_Modified_Extract = $DB_Service[22];
		my $Modified_By_Extract = $DB_Service[23];


		## Host Name Collection
		my $Host_Names;
		my $Select_Host_Name_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServiceToHost`
		WHERE `idMaster` = ?");
		$Select_Host_Name_Link->execute($Display_Config);
	
		while ( my @DB_Host_Link = $Select_Host_Name_Link->fetchrow_array() )
		{

			my $Host_ID = $DB_Host_Link[0];

			my $Select_Host_Name = $DB_Connection->prepare("SELECT `host_name`
			FROM `icinga2_host`
			WHERE `id` = '$Host_ID'
			AND `active` = '1'");
			$Select_Host_Name->execute();

			while ( my @DB_Host = $Select_Host_Name->fetchrow_array() )
			{
				my $Host_Name = $DB_Host[0];
				$Host_Names = "$Host_Name,$Host_Names";
			}
		}

		## / Host Name Collection

		## Service Group Collection
			my $Service_Group_Names;
			my $Select_Service_Group_Link = $DB_Connection->prepare("SELECT `idSlave`
			FROM `icinga2_lnkServiceToServicegroup`
			WHERE `idMaster` = ?");
			$Select_Service_Group_Link->execute($Display_Config);
		
			while ( my @DB_Service_Link = $Select_Service_Group_Link->fetchrow_array() )
			{
	
				my $Service_ID = $DB_Service_Link[0];
	
				my $Select_Service_Group_Name = $DB_Connection->prepare("SELECT `servicegroup_name`
				FROM `icinga2_servicegroup`
				WHERE `id` = '$Service_ID'
				AND `active` = '1'");
				$Select_Service_Group_Name->execute();
	
				while ( my @DB_Service_Group = $Select_Service_Group_Name->fetchrow_array() )
				{
					my $Service_Group_Name = $DB_Service_Group[0];
					$Service_Group_Names = "$Service_Group_Name,$Service_Group_Names";
				}
			}
		## / Service Group Collection

		## Contact Link Collection
		my $Contacts;
		my $Select_Contact_Name_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServiceToContact`
		WHERE `idMaster` = ?");
		$Select_Contact_Name_Link->execute($Display_Config);
	
		while ( my @DB_Contact_Link = $Select_Contact_Name_Link->fetchrow_array() )
		{

			my $Contact_ID = $DB_Contact_Link[0];

			my $Select_Contact_Name = $DB_Connection->prepare("SELECT `contact_name`
			FROM `icinga2_contact`
			WHERE `id` = '$Contact_ID'
			AND `active` = '1'");
			$Select_Contact_Name->execute();

			while ( my @DB_Contact = $Select_Contact_Name->fetchrow_array() )
			{
				my $Contact_Name = $DB_Contact[0];
				$Contacts = "$Contact_Name,$Contacts";
			}
		}

		## / Contact Link Collection

		## Contact Group Link Collection
		my $Contact_Groups;
		my $Select_Group_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServiceToContactgroup`
		WHERE `idMaster` = ?");
		$Select_Group_Link->execute($Display_Config);
	
		while ( my @DB_Contact_Link = $Select_Group_Link->fetchrow_array() )
		{

			my $Contact_ID = $DB_Contact_Link[0];

			my $Select_Group = $DB_Connection->prepare("SELECT `contactgroup_name`
			FROM `icinga2_contactgroup`
			WHERE `id` = '$Contact_ID'
			AND `active` = '1'");
			$Select_Group->execute();

			while ( my @DB_Contact = $Select_Group->fetchrow_array() )
			{
				my $Contact_Group = $DB_Contact[0];
				$Contact_Groups = "$Contact_Group,$Contact_Groups";
			}
		}

		## / Contact Group Link Collection


		## Service Template Values

		my $Service_Template_ID;
		my $Service_Name_Extract_Template;
		my $Last_Modified_Extract_Template;
		my $Modified_By_Extract_Template;
		my $Check_Period_Extract_Template;
		my $Notification_Period_Extract_Template;
		my $Check_Command_Extract_Template;
		my $Select_Service_Template_ID = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServiceToServicetemplate`
		WHERE `idMaster` = ?");
		$Select_Service_Template_ID->execute($Display_Config);
		
		while ( my @DB_Service_Template_ID = $Select_Service_Template_ID->fetchrow_array() )
		{

			$Service_Template_ID = $DB_Service_Template_ID[0];

			my $Select_Service_Template = $DB_Connection->prepare("SELECT `template_name`, `active_checks_enabled`, `check_freshness`, 
			`check_period`, `event_handler_enabled`, `flap_detection_enabled`, `check_command`, `is_volatile`, `max_check_attempts`, `check_interval`,
			`notification_interval`, `notification_options`, `notification_period`, `notifications_enabled`, `obsess_over_service`,
			`parallelize_check`, `passive_checks_enabled`, `process_perf_data`, `retain_nonstatus_information`, `retain_status_information`,
			`retry_interval`, `active`, `last_modified`, `modified_by`
			FROM `icinga2_servicetemplate`
			WHERE `id` = ?");
			$Select_Service_Template->execute($Service_Template_ID);
			
			while ( my @DB_Service_Template = $Select_Service_Template->fetchrow_array() )
			{
	
				$Service_Name_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[0]</span>";
				my $Active_Checks_Enabled_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[1]</span>";
				my $Check_Freshness_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[2]</span>";
				$Check_Period_Extract_Template = $DB_Service_Template[3];
				my $Event_Handler_Enabled_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[4]</span>";
				my $Flap_Detection_Enabled_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[5]</span>";
				$Check_Command_Extract_Template = $DB_Service_Template[6];
				my $Is_Volatile_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[7]</span>";
				my $Max_Check_Attempts_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[8]</span>";
				my $Normal_Check_Interval_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[9]</span>";
				my $Notification_Interval_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[10]</span>";
				my $Notification_Options_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[11]</span>";
				$Notification_Period_Extract_Template = $DB_Service_Template[12];
				my $Notifications_Enabled_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[13]</span>";
				my $Obsess_Over_Service_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[14]</span>";
				my $Parallelize_Check_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[15]</span>";
				my $Passive_Checks_Enabled_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[16]</span>";
				my $Process_Perf_Data_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[17]</span>";
				my $Retain_NonStatus_Information_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[18]</span>";
				my $Retain_Status_Information_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[19]</span>";
				my $Retry_Check_Interval_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[20]</span>";
				my $Active_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[21]</span>";
				$Last_Modified_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[22]</span>";
				$Modified_By_Extract_Template = "<span style='color: #FF8800;'>$DB_Service_Template[23]</span>";

				if ($Active_Checks_Enabled_Extract eq 2) {$Active_Checks_Enabled_Extract = $Active_Checks_Enabled_Extract_Template};
				if ($Check_Freshness_Extract eq 2) {$Check_Freshness_Extract = $Check_Freshness_Extract_Template};
				if ($Event_Handler_Enabled_Extract eq '' || $Event_Handler_Enabled_Extract eq 2) {$Event_Handler_Enabled_Extract = $Event_Handler_Enabled_Extract_Template};
				if ($Flap_Detection_Enabled_Extract eq '' || $Flap_Detection_Enabled_Extract eq 2) {$Flap_Detection_Enabled_Extract = $Flap_Detection_Enabled_Extract_Template};
				if ($Is_Volatile_Extract eq '' || $Is_Volatile_Extract eq 2) {$Is_Volatile_Extract = $Is_Volatile_Extract_Template};
				if ($Max_Check_Attempts_Extract eq '') {$Max_Check_Attempts_Extract = $Max_Check_Attempts_Extract_Template};
				if ($Normal_Check_Interval_Extract eq '') {$Normal_Check_Interval_Extract = $Normal_Check_Interval_Extract_Template};
				if ($Notification_Interval_Extract eq '') {$Notification_Interval_Extract = $Notification_Interval_Extract_Template};
				if (!$Notification_Options_Extract || $Notification_Options_Extract eq '') {$Notification_Options_Extract = $Notification_Options_Extract_Template};
				if ($Notifications_Enabled_Extract eq '' || $Notifications_Enabled_Extract eq 2) {$Notifications_Enabled_Extract = $Notifications_Enabled_Extract_Template};
				if ($Obsess_Over_Service_Extract eq '' || $Obsess_Over_Service_Extract eq 2) {$Obsess_Over_Service_Extract = $Obsess_Over_Service_Extract_Template};
				if ($Parallelize_Check_Extract eq '' || $Parallelize_Check_Extract eq 2) {$Parallelize_Check_Extract = $Parallelize_Check_Extract_Template};
				if ($Passive_Checks_Enabled_Extract eq '' || $Passive_Checks_Enabled_Extract eq 2) {$Passive_Checks_Enabled_Extract = $Passive_Checks_Enabled_Extract_Template};
				if ($Process_Perf_Data_Extract eq '' || $Process_Perf_Data_Extract eq 2) {$Process_Perf_Data_Extract = $Process_Perf_Data_Extract_Template};
				if ($Retain_NonStatus_Information_Extract eq '' || $Retain_NonStatus_Information_Extract eq 2) {$Retain_NonStatus_Information_Extract = $Retain_NonStatus_Information_Extract_Template};
				if ($Retain_Status_Information_Extract eq '' || $Retain_Status_Information_Extract eq 2) {$Retain_Status_Information_Extract = $Retain_Status_Information_Extract_Template};
				if ($Retry_Check_Interval_Extract eq '' || $Retry_Check_Interval_Extract eq 2) {$Retry_Check_Interval_Extract = $Retry_Check_Interval_Extract_Template};


				## Template Hostname collection
		
				my $Select_Host_Name_Link = $DB_Connection->prepare("SELECT `idSlave`
				FROM `icinga2_lnkServicetemplateToHost`
				WHERE `idMaster` = ?");
				$Select_Host_Name_Link->execute($Service_Template_ID);
			
				while ( my @DB_Host_Link = $Select_Host_Name_Link->fetchrow_array() )
				{
		
					my $Host_ID = $DB_Host_Link[0];
		
					my $Select_Host_Name = $DB_Connection->prepare("SELECT `host_name`
					FROM `icinga2_host`
					WHERE `id` = '$Host_ID'
					AND `active` = '1'");
					$Select_Host_Name->execute();
		
					while ( my @DB_Host = $Select_Host_Name->fetchrow_array() )
					{
						my $Host_Name = $DB_Host[0];
						$Host_Names = "<span style='color: #FF8800;'>$Host_Name</span>,$Host_Names";
					}
				}


				## / Template Hostname collection

				## Template Service Group Collection
					if ($Service_Group_Names eq undef) {
						my $Select_Service_Group_Link = $DB_Connection->prepare("SELECT `idSlave`
						FROM `icinga2_lnkServiceToServicegroup`
						WHERE `idMaster` = ?");
						$Select_Service_Group_Link->execute($Service_Template_ID);
					
						while ( my @DB_Service_Link = $Select_Service_Group_Link->fetchrow_array() )
						{
				
							my $Service_ID = $DB_Service_Link[0];
				
							my $Select_Service_Group_Name = $DB_Connection->prepare("SELECT `servicegroup_name`
							FROM `icinga2_servicegroup`
							WHERE `id` = '$Service_ID'
							AND `active` = '1'");
							$Select_Service_Group_Name->execute();
				
							while ( my @DB_Service_Group = $Select_Service_Group_Name->fetchrow_array() )
							{
								my $Service_Group_Name = $DB_Service_Group[0];
								$Service_Group_Names = "<span style='color: #FF8800;'>$Service_Group_Name</span>,$Service_Group_Names";
							}
						}
					}
				## / Template Service Group Collection

			}

			## Template Contact Link Collection
		
				my $Select_Contact_Link = $DB_Connection->prepare("SELECT `idSlave`
				FROM `icinga2_lnkServicetemplateToContact`
				WHERE `idMaster` = ?");
				$Select_Contact_Link->execute($Service_Template_ID);
			
				while ( my @DB_Host_Link = $Select_Contact_Link->fetchrow_array() )
				{
		
					my $Host_ID = $DB_Host_Link[0];
		
					my $Select_Contact = $DB_Connection->prepare("SELECT `contact_name`
					FROM `icinga2_contact`
					WHERE `id` = '$Host_ID'
					AND `active` = '1'");
					$Select_Contact->execute();
		
					while ( my @DB_Host = $Select_Contact->fetchrow_array() )
					{
						my $Contact = $DB_Host[0];
						$Contacts = "<span style='color: #FF8800;'>$Contact</span>,$Contacts";
					}
				}
	
			
			## / Template Contact Link Collection
			
	
			## Template Contact Group Link Collection
			
				my $Select_Contact_Group_Link = $DB_Connection->prepare("SELECT `idSlave`
				FROM `icinga2_lnkServicetemplateToContactgroup`
				WHERE `idMaster` = ?");
				$Select_Contact_Group_Link->execute($Service_Template_ID);
			
				while ( my @DB_Host_Link = $Select_Contact_Group_Link->fetchrow_array() )
				{
		
					my $Host_ID = $DB_Host_Link[0];
		
					my $Select_Contact = $DB_Connection->prepare("SELECT `contactgroup_name`
					FROM `icinga2_contactgroup`
					WHERE `id` = '$Host_ID'
					AND `active` = '1'");
					$Select_Contact->execute();
		
					while ( my @DB_Host = $Select_Contact->fetchrow_array() )
					{
						my $Contact_Group = $DB_Host[0];
						$Contact_Groups = "<span style='color: #FF8800;'>$Contact_Group</span>,$Contact_Groups";
					}
				}
			
			## / Template Contact Group Link Collection

		}

		## / Service Template Values

		## Service Template's Template Values

		my $Service_Templates_Template_ID;
		my $Service_Name_Extract_Templates_Template;
		my $Last_Modified_Extract_Templates_Template;
		my $Modified_By_Extract_Templates_Template;
		my $Check_Period_Extract_Templates_Template;
		my $Notification_Period_Extract_Templates_Template;
		my $Check_Command_Extract_Templates_Template;
		
		my $Select_Service_Templates_Template_ID = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServicetemplateToServicetemplate`
		WHERE `idMaster` = ?");
		$Select_Service_Templates_Template_ID->execute($Service_Template_ID);
		
		while ( my @DB_Service_Templates_Template_ID = $Select_Service_Templates_Template_ID->fetchrow_array() )
		{

			$Service_Templates_Template_ID = $DB_Service_Templates_Template_ID[0];

			my $Select_Service_Templates_Template = $DB_Connection->prepare("SELECT `template_name`, `active_checks_enabled`, `check_freshness`, 
			`check_period`, `event_handler_enabled`, `flap_detection_enabled`, `check_command`, `is_volatile`, `max_check_attempts`, `check_interval`,
			`notification_interval`, `notification_options`, `notification_period`, `notifications_enabled`, `obsess_over_service`,
			`parallelize_check`, `passive_checks_enabled`, `process_perf_data`, `retain_nonstatus_information`, `retain_status_information`,
			`retry_interval`, `active`, `last_modified`, `modified_by`
			FROM `icinga2_servicetemplate`
			WHERE `id` = ?");
			$Select_Service_Templates_Template->execute($Service_Templates_Template_ID);
			
			while ( my @DB_Service_Templates_Template = $Select_Service_Templates_Template->fetchrow_array() )
			{
	
				$Service_Name_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[0]</span>";
				my $Active_Checks_Enabled_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[1]</span>";
				my $Check_Freshness_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[2]</span>";
				$Check_Period_Extract_Templates_Template = $DB_Service_Templates_Template[3];
				my $Event_Handler_Enabled_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[4]</span>";
				my $Flap_Detection_Enabled_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[5]</span>";
				$Check_Command_Extract_Templates_Template = $DB_Service_Templates_Template[6];
				my $Is_Volatile_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[7]</span>";
				my $Max_Check_Attempts_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[8]</span>";
				my $Normal_Check_Interval_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[9]</span>";
				my $Notification_Interval_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[10]</span>";
				my $Notification_Options_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[11]</span>";
				$Notification_Period_Extract_Templates_Template = $DB_Service_Templates_Template[12];
				my $Notifications_Enabled_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[13]</span>";
				my $Obsess_Over_Service_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[14]</span>";
				my $Parallelize_Check_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[15]</span>";
				my $Passive_Checks_Enabled_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[16]</span>";
				my $Process_Perf_Data_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[17]</span>";
				my $Retain_NonStatus_Information_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[18]</span>";
				my $Retain_Status_Information_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[19]</span>";
				my $Retry_Check_Interval_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[20]</span>";
				my $Active_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[21]</span>";
				$Last_Modified_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[22]</span>";
				$Modified_By_Extract_Templates_Template = "<span style='color: #FF00FF;'>$DB_Service_Templates_Template[23]</span>";

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
				if ($Obsess_Over_Service_Extract eq "<span style='color: #FF8800;'></span>" || $Obsess_Over_Service_Extract eq "<span style='color: #FF8800;'>2</span>") {
					$Obsess_Over_Service_Extract = $Obsess_Over_Service_Extract_Templates_Template;
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

		## / Service Template's Template Values


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

		my $Select_Check_Period = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
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

		my $Select_Notification_Period = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
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
		if ($Check_Command_Extract eq undef) {
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
		my $Select_Check_Command = $DB_Connection->prepare("SELECT `command_name`
		FROM `icinga2_command`
		WHERE `id` = '$Check_Command_Where_ID_Extract'");
		$Select_Check_Command->execute();

			while ( my @DB_Command = $Select_Check_Command->fetchrow_array() )
			{

				$Check_Command = $DB_Command[0];
				$Check_Command = $Check_Command.$Check_Command_Where_Remaining;

				if ($Check_Command_Extract eq undef) {
					$Check_Command = "<span style='color: #FF8800;'>$Check_Command</span>";
				}

			}

		## / Check Command Partial Conversion


		$Host_Names =~ s/,$//g;
			if ($Host_Names eq 0) {$Host_Names = ''};
		$Service_Group_Names =~ s/,$//g;
			if ($Service_Group_Names eq 0) {$Service_Group_Names = ''};
		$Contacts =~ s/,$//g;
		$Contact_Groups =~ s/,$//g;

		$Service_Template_ID = "<span style='color: #FF8800;'>$Service_Template_ID</span>";
		$Service_Templates_Template_ID = "<span style='color: #FF00FF;'>$Service_Templates_Template_ID</span>";

		if ($Host_Names eq undef) {$Host_Names = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Check_Command =~ m/></) {$Check_Command = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Active_Checks_Enabled_Extract =~ m/></ || $Active_Checks_Enabled_Extract =~ m/>2</) {$Active_Checks_Enabled_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Passive_Checks_Enabled_Extract =~ m/></ || $Passive_Checks_Enabled_Extract =~ m/>2</) {$Passive_Checks_Enabled_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Parallelize_Check_Extract =~ m/></ || $Parallelize_Check_Extract =~ m/>2</) {$Parallelize_Check_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Obsess_Over_Service_Extract =~ m/></ || $Obsess_Over_Service_Extract =~ m/>2</) {$Obsess_Over_Service_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Check_Freshness_Extract =~ m/></ || $Check_Freshness_Extract =~ m/>2</) {$Check_Freshness_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Notifications_Enabled_Extract =~ m/></ || $Notifications_Enabled_Extract =~ m/>2</) {$Notifications_Enabled_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Event_Handler_Enabled_Extract =~ m/></ || $Event_Handler_Enabled_Extract =~ m/>2</) {$Event_Handler_Enabled_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Flap_Detection_Enabled_Extract =~ m/></ || $Flap_Detection_Enabled_Extract =~ m/>2</) {$Flap_Detection_Enabled_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Process_Perf_Data_Extract =~ m/></ || $Process_Perf_Data_Extract =~ m/>2</) {$Process_Perf_Data_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Retain_Status_Information_Extract =~ m/></ || $Retain_Status_Information_Extract =~ m/>2</) {$Retain_Status_Information_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Retain_NonStatus_Information_Extract =~ m/></ || $Retain_NonStatus_Information_Extract =~ m/>2</) {$Retain_NonStatus_Information_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Is_Volatile_Extract =~ m/></ || $Is_Volatile_Extract eq 2) {$Is_Volatile_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Check_Period =~ m/></) {$Check_Period = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Max_Check_Attempts_Extract =~ m/></) {$Max_Check_Attempts_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Normal_Check_Interval_Extract =~ m/></) {$Normal_Check_Interval_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Retry_Check_Interval_Extract =~ m/></) {$Retry_Check_Interval_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Contacts eq undef) {$Contacts = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Contact_Groups eq undef) {$Contact_Groups = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Notification_Options_Extract =~ m/></ || $Notification_Options_Extract eq 2) {$Notification_Options_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Notification_Interval_Extract =~ m/></) {$Notification_Interval_Extract = "<span style='color: #FF0000;'>UNDEFINED</span>";}
		if ($Notification_Period =~ m/></) {$Notification_Period = "<span style='color: #FF0000;'>UNDEFINED</span>";}

		if (!$Active_Extract) {
			$Active_Extract="<span style='color: #FF8A00;'>
			This service is not active, so this config will not be written. 
			Make this service active to use it in Icinga.</span>";
		}
		else {
			$Active_Extract="";
		}

print <<ENDHTML;
<div id="full-width-popup-box">
<a href="/Icinga/icinga-services.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Live Config for <span style="color: #00FF00;">$Service_Name_Extract</span></h3>
<p>This config is automatically applied regularly. The config below illustrates how this service's config will be written.<br />
ENDHTML

if ($Service_Template_ID !~ /></) {
	print 'The values in <span style="color: #FF8800;">orange</span> are undefined in this service, and are therefore inherited from this service\'s template.<br />';
}
if ($Service_Templates_Template_ID !~ /></) {
	print 'The values in <span style="color: #FF00FF;">purple</span> are not defined in this service, nor this service\'s template, so are collected from the service template\'s template.';
}

print <<ENDHTML;

</p>
<p>$Active_Extract</p>
<div style="text-align: left;">
<code>
<table align = "center">
	<tr>
		<td colspan='3'>## Service ID: $Display_Config</td>
	</tr>
	<tr>
		<td colspan='3'>## Service Modified $Last_Modified_Extract by $Modified_By_Extract</td>
	</tr>
ENDHTML

if ($Service_Template_ID !~ /></) {
	print <<ENDHTML;
	<tr>
		<td colspan='3'>## Template ID: $Service_Template_ID</td>
	</tr>
	<tr>
		<td colspan='3'>## Template Name: $Service_Name_Extract_Template</td>
	</tr>
	<tr>
		<td colspan='3'>## Template Modified: $Last_Modified_Extract_Template by $Modified_By_Extract_Template</td>
	</tr>

ENDHTML
}
if ($Service_Templates_Template_ID !~ /></) {
	print <<ENDHTML;

	<tr>
		<td colspan='3'>## Template's Template ID: $Service_Templates_Template_ID</td>
	</tr>
	<tr>
		<td colspan='3'>## Template's Template Name: $Service_Name_Extract_Templates_Template</td>
	</tr>
	<tr>
		<td colspan='3'>## Template's Template Modified: $Last_Modified_Extract_Templates_Template by $Modified_By_Extract_Templates_Template</td>
	</tr>

ENDHTML
}

print <<ENDHTML;
	<tr>
		<td colspan='3'>define service {</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>use</td>
		<td style='padding-left: 2em;'>$Service_Name_Extract_Template</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>service_description</td>
		<td style='padding-left: 2em;'>$Service_Name_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>host_name</td>
		<td style='padding-left: 2em;'>$Host_Names</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>servicegroups</td>
		<td style='padding-left: 2em;'>$Service_Group_Names</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>check_command</td>
		<td style='padding-left: 2em;'>$Check_Command</td>
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
		<td style='padding-left: 2em;'>parallelize_check</td>
		<td style='padding-left: 2em;'>$Parallelize_Check_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>obsess_over_service</td>
		<td style='padding-left: 2em;'>$Obsess_Over_Service_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>check_freshness</td>
		<td style='padding-left: 2em;'>$Check_Freshness_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>notifications_enabled</td>
		<td style='padding-left: 2em;'>$Notifications_Enabled_Extract</td>
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
		<td style='padding-left: 2em;'>process_perf_data</td>
		<td style='padding-left: 2em;'>$Process_Perf_Data_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>retain_status_information</td>
		<td style='padding-left: 2em;'>$Retain_Status_Information_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>retain_nonstatus_information</td>
		<td style='padding-left: 2em;'>$Retain_NonStatus_Information_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>is_volatile</td>
		<td style='padding-left: 2em;'>$Is_Volatile_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>check_period</td>
		<td style='padding-left: 2em;'>$Check_Period</td>
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
		<td style='padding-left: 2em;'>contacts</td>
		<td style='padding-left: 2em;'>$Contacts</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>contact_groups</td>
		<td style='padding-left: 2em;'>$Contact_Groups</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>notification_options</td>
		<td style='padding-left: 2em;'>$Notification_Options_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>notification_interval</td>
		<td style='padding-left: 2em;'>$Notification_Interval_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>notification_period</td>
		<td style='padding-left: 2em;'>$Notification_Period</td>
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

sub html_linked_hosts {

	my $Service_Name;
	my $Service_Description;
	my $Select_Service_Name = $DB_Connection->prepare("SELECT `service_description`
	FROM `icinga2_service`
	WHERE `id` = ?");
	
		$Select_Service_Name->execute($Linked_Hosts);
		
		while ( my @DB_Service_Name = $Select_Service_Name->fetchrow_array() )
		{
			$Service_Description = $DB_Service_Name[0];
		}

	my $Table = new HTML::Table(
                            -cols=>4,
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

	$Table->addRow ( "Host ID", "Name", "Active Host?", "View Host" );
	$Table->setRowClass (1, 'tbrow1');

	my $Select_Host_Name_Link = $DB_Connection->prepare("SELECT `idSlave`
	FROM `icinga2_lnkServiceToHost`
	WHERE `idMaster` = '$Linked_Hosts'");
	$Select_Host_Name_Link->execute();

		while ( my @DB_Host_Link = $Select_Host_Name_Link->fetchrow_array() )
		{

			my $Host_ID = $DB_Host_Link[0];

			my $Select_Host_Name = $DB_Connection->prepare("SELECT `host_name`, `active`
			FROM `icinga2_host`
			WHERE `id` = '$Host_ID'");
			$Select_Host_Name->execute();

			while ( my @DB_Host = $Select_Host_Name->fetchrow_array() )
			{

				my $Host_Name = $DB_Host[0];
				my $Host_Active = $DB_Host[1];

					if ($Host_Active) {$Host_Active = "<span style='color: #00FF00;'>Yes</span>"}
					else {$Host_Active = "<span style='color: #FF0000;'>No</span>"}

					my $View_Host = "<a href='/Icinga/icinga-hosts.cgi?Filter=$Host_Name'><img src=\"/Resources/Images/forward.png\" alt=\"View Host $Host_Name\" ></a>";

				$Table->addRow ( "$Host_ID", "$Host_Name", "$Host_Active", "$View_Host" );

			}

		}

		if ($Table->getTableRows == 1) {$Table = '<p>This service has no attached hosts</p>'}

print <<ENDHTML;
<div id="small-popup-box">
<a href="/Icinga/icinga-services.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Linked Hosts for <span style="color: #00FF00;">$Service_Description</span></h3>

$Table

</div>

ENDHTML

} # sub html_linked_hosts


sub html_output {

	my $Table = new HTML::Table(
		-cols=>13,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);

	$Table->addRow ( "ID", "Name", "Description", "Check Command", "Service Groups", "Service Templates", "Active",
		"Last Modified", "Modified By", "Linked Hosts", "View Config", "Edit (todo)", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Select_Services_Count = $DB_Connection->prepare("SELECT `id` FROM `icinga2_service`");
		$Select_Services_Count->execute( );
		my $Total_Rows = $Select_Services_Count->rows();

	my $Select_Services = $DB_Connection->prepare("SELECT `id`, `config_name`, `service_description`, `check_command`,
	`active`, `last_modified`, `modified_by`
	FROM `icinga2_service`
	WHERE (`id` LIKE '%$Filter%'
	OR `config_name` LIKE '%$Filter%'
	OR `service_description` LIKE '%$Filter%')
	ORDER BY `config_name` ASC
	LIMIT ?, ?");

	$Select_Services->execute(0, $Rows_Returned);
	my $Rows = $Select_Services->rows();

	$Table->setRowClass(1, 'tbrow1');

	my $User_Row_Count=1;
	while ( my @DB_Service = $Select_Services->fetchrow_array() )
	{
	
		$User_Row_Count++;

		my $ID_Extract = $DB_Service[0];
			my $ID_Extract_Display = $ID_Extract;
			$ID_Extract_Display =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Service_Name_Extract = $DB_Service[1];
			my $Service_Name = $Service_Name_Extract;
			$Service_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Service_Description_Extract = $DB_Service[2];
			$Service_Description_Extract =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Check_Command_Extract = $DB_Service[3];
		my $Active_Extract = $DB_Service[4];
		my $Last_Modified_Extract = $DB_Service[5];
		my $Modified_By_Extract = $DB_Service[6];

		if ($Active_Extract) {$Active_Extract='Yes';} else {$Active_Extract='No';}


		## Service Template Conversion
		my $Service_Templates;
		my $Select_Service_Template_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServiceToServicetemplate`
		WHERE `idMaster` = '$ID_Extract'");
		$Select_Service_Template_Link->execute();

			while ( my @DB_Template_Link = $Select_Service_Template_Link->fetchrow_array() )
			{

				my $Service_Template_Link = $DB_Template_Link[0];

				my $Select_Service_Template = $DB_Connection->prepare("SELECT `template_name`
				FROM `icinga2_servicetemplate`
				WHERE `id` = '$Service_Template_Link'");
				$Select_Service_Template->execute();

				while ( my @DB_Template = $Select_Service_Template->fetchrow_array() )
				{

					my $Service_Template = $DB_Template[0];
					$Service_Templates = "<a href='/Icinga/icinga-service-templates.cgi?Filter=$Service_Template'>$Service_Template</a><br />".$Service_Templates;

				}

			}
		## / Service Template Conversion


		## Service Group Conversion
		my $Service_Groups;
		my $Select_Service_Group_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServiceToServicegroup`
		WHERE `idMaster` = '$ID_Extract'");
		$Select_Service_Group_Link->execute();

			while ( my @DB_Group_Link = $Select_Service_Group_Link->fetchrow_array() )
			{

				my $Service_Group_Link = $DB_Group_Link[0];

				my $Select_Service_Group = $DB_Connection->prepare("SELECT `servicegroup_name`
				FROM `icinga2_servicegroup`
				WHERE `id` = '$Service_Group_Link'");
				$Select_Service_Group->execute();

				while ( my @DB_Group = $Select_Service_Group->fetchrow_array() )
				{

					my $Service_Group = $DB_Group[0];
					$Service_Groups = "<a href='/Icinga/icinga-service-groups.cgi?Filter=$Service_Group'>$Service_Group</a><br />".$Service_Groups;

				}

			}
		## / Service Group Conversion


		## Check Command Partial Conversion

		my $Check_Command_Extract_Command_ID_Extract = $Check_Command_Extract;
			$Check_Command_Extract_Command_ID_Extract =~ s/^(\d*).*/$1/g;
		my $Check_Command_Extract_Command_Remaining = $Check_Command_Extract;
			$Check_Command_Extract_Command_Remaining =~ s/^\d*(.*)/$1/g;

		my $Check_Command;
		my $Select_Check_Command = $DB_Connection->prepare("SELECT `command_name`
		FROM `icinga2_command`
		WHERE `id` = ?");
		$Select_Check_Command->execute($Check_Command_Extract_Command_ID_Extract);

			while ( my @DB_Command = $Select_Check_Command->fetchrow_array() )
			{

				$Check_Command = $DB_Command[0];
				$Check_Command = "<a href='/Icinga/icinga-commands.cgi?Filter=$Check_Command'><span style='color: #FFFF00;'>$Check_Command</span></a>";
				$Check_Command = $Check_Command.$Check_Command_Extract_Command_Remaining;

			}

		## / Check Command Partial Conversion


		$Table->addRow(
			"<a href='/Icinga/icinga-services.cgi?Edit_Service=$ID_Extract'>$ID_Extract_Display</a>",
			$Service_Name,
			$Service_Description_Extract,
			$Check_Command,
			$Service_Groups,
			$Service_Templates,
			$Active_Extract,
			$Last_Modified_Extract,
			$Modified_By_Extract,
			"<a href='/Icinga/icinga-services.cgi?Linked_Hosts=$ID_Extract'><img src=\"/Resources/Images/linked.png\" alt=\"View Linked Hosts for $Service_Name_Extract\" ></a>",
			"<a href='/Icinga/icinga-services.cgi?Display_Config=$ID_Extract'><img src=\"/Resources/Images/view-notes.png\" alt=\"View Config for $Service_Name_Extract\" ></a>",
			"<a href='/Icinga/icinga-services.cgi?Edit_Service=$ID_Extract'><img src=\"/Resources/Images/edit.png\" alt=\"Edit $Service_Name_Extract\" ></a>",
			"<a href='/Icinga/icinga-services.cgi?Delete_Service=$ID_Extract'><img src=\"/Resources/Images/delete.png\" alt=\"Delete $Service_Name_Extract\" ></a>"
		);

		for (7 .. 13) {
			$Table->setColWidth($_, '1px');
			$Table->setColAlign($_, 'center');
		}

		if ($Active_Extract eq 'Yes') {
			$Table->setCellClass ($User_Row_Count, 7, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($User_Row_Count, 7, 'tbroworange');
		}

	}

print <<ENDHTML;

<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/Icinga/icinga-services.cgi' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Services" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/Icinga/icinga-services.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Service</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Service' value='Add Service'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/Icinga/icinga-services.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Service</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Service' value='Edit Service'></td>
					<td align="center">
						<select name='Edit_Service' style="width: 150px">
ENDHTML

						my $Service_List_Query = $DB_Connection->prepare("SELECT `id`, `config_name`
						FROM `icinga2_service`
						ORDER BY `config_name` ASC");
						$Service_List_Query->execute( );
						
						while ( (my $ID, my $Service_Name) = my @Service_List_Query = $Service_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Service_Name</option>";
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

<p style="font-size:14px; font-weight:bold;">Icinga Services | Services Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML

} #sub html_output end
