#!/usr/bin/perl -T

use strict;
use lib qw(resources/modules/);
use lib qw(../resources/modules/);
use POSIX qw(strftime);

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;
my $DB_Connection = DB_Connection();
my $System_Name = System_Name();
my $Version = Version();

my $Date_Time = strftime "%Y-%m-%d %H:%M:%S", localtime;
my $Config_Path = '/etc/icinga2/conf.d'; # No trailing slash

#&write_time_periods;
#&write_contact_groups;
#&write_host_groups;
#&write_service_groups;
##&write_contact_templates; # Omitted for now (not used)
&write_host_templates;
&write_service_templates;
#&write_contacts;
&write_hosts;
&write_services;
&write_commands;

sub write_time_periods {

	my $Icinga_Config_File = "$Config_Path/timeperiods.conf";
	open( FILE, ">$Icinga_Config_File" ) or die "Can't open $Icinga_Config_File";

	my $Select_Time = $DB_Connection->prepare("SELECT `id`, `timeperiod_name`, `alias`, `last_modified`, `modified_by`
	FROM `icinga2_timeperiod`
	WHERE `active` = '1'");
	
	$Select_Time->execute();
	my $Rows = $Select_Time->rows();

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED FILE\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "## Time periods defined in file: $Rows\n";
	print FILE "########################################\n";
	print FILE "\n\n";

	while ( my @DB_Time = $Select_Time->fetchrow_array() )
	{
	
		my $Time_ID_Extract = $DB_Time[0];
		my $Time_Name_Extract = $DB_Time[1];
		my $Alias_Extract = $DB_Time[2];
		my $Last_Modified_Extract = $DB_Time[3];
		my $Modified_By_Extract = $DB_Time[4];

		my $Select_Definitions = $DB_Connection->prepare("SELECT `definition`, `range`
		FROM `icinga2_timedefinition`
		WHERE `tipId` LIKE ?");
		
		$Select_Definitions->execute($Time_ID_Extract);
		
		my ($Sunday, $Monday, $Tuesday, $Wednesday, $Thursday, $Friday, $Saturday); 
		while ( my @DB_Time_Definition = $Select_Definitions->fetchrow_array() )
		{

			my $Day = $DB_Time_Definition[0];
			my $Range = $DB_Time_Definition[1];

			if ($Day =~ m/su/) {$Sunday = $Range};
			if ($Day =~ m/mo/) {$Monday = $Range};
			if ($Day =~ m/tu/) {$Tuesday = $Range};
			if ($Day =~ m/we/) {$Wednesday = $Range};
			if ($Day =~ m/th/) {$Thursday = $Range};
			if ($Day =~ m/fr/) {$Friday = $Range};
			if ($Day =~ m/sa/) {$Saturday = $Range};

		}

		print FILE "## Time Period ID: $Time_ID_Extract\n";
		print FILE "## Modified $Last_Modified_Extract by $Modified_By_Extract\n";
		print FILE "define timeperiod {\n";
		print FILE "	timeperiod_name	$Time_Name_Extract\n";
		print FILE "	alias		$Alias_Extract\n";

		if ($Sunday) {
			print FILE "	sunday		$Sunday\n";
		}
		if ($Monday) {
			print FILE "	monday		$Monday\n";
		}
		if ($Tuesday) {
			print FILE "	tuesday		$Tuesday\n";
		}
		if ($Wednesday) {
			print FILE "	wednesday	$Wednesday\n";
		}
		if ($Thursday) {
			print FILE "	thursday	$Thursday\n";
		}
		if ($Friday) {
			print FILE "	friday		$Friday\n";
		}
		if ($Saturday) {
			print FILE "	saturday	$Saturday\n";
		}

		print FILE "}\n\n";

	}

} #sub write_time_periods

sub write_host_groups {

	my $Icinga_Config_File = "$Config_Path/hostgroups.conf";
	open( FILE, ">$Icinga_Config_File" ) or die "Can't open $Icinga_Config_File";

	my $Select_Group = $DB_Connection->prepare("SELECT `id`, `hostgroup_name`, `alias`, `last_modified`, `modified_by`
	FROM `icinga2_hostgroup`
	WHERE `active` = '1'
	ORDER BY `hostgroup_name` ASC");

	$Select_Group->execute( );
	my $Rows = $Select_Group->rows();

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED FILE\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "## Host groups defined in file: $Rows\n";
	print FILE "########################################\n";
	print FILE "\n\n";



	while ( my @DB_Group = $Select_Group->fetchrow_array() )
	{
	
		my $ID_Extract = $DB_Group[0];
		my $Group_Extract = $DB_Group[1];
		my $Alias_Extract = $DB_Group[2];
		my $Last_Modified_Extract = $DB_Group[3];
		my $Modified_By_Extract = $DB_Group[4];

		my $Select_Members = $DB_Connection->prepare("SELECT `idMaster`
		FROM `icinga2_lnkHostToHostgroup`
		WHERE `idSlave` = ?");
		$Select_Members->execute($ID_Extract);

		my $Members;
		while ( my @DB_Members = $Select_Members->fetchrow_array() )
		{
			my $idMaster = $DB_Members[0];
			
			my $Select_Member_Names = $DB_Connection->prepare("SELECT `host_name`, `active`
			FROM `icinga2_host`
			WHERE `id` = ?");
			$Select_Member_Names->execute($idMaster);

			while ( my @DB_Member_Names = $Select_Member_Names->fetchrow_array() )
			{
				my $Member = $DB_Member_Names[0];
				my $Active = $DB_Member_Names[1];
				if ($Active) {$Members = $Member.", ".$Members;}
			}
		}

		$Members =~ s/,\ $//g;

		if ($Members) {
			print FILE "## Host Group ID: $ID_Extract\n";
			print FILE "## Modified $Last_Modified_Extract by $Modified_By_Extract\n";
			print FILE "define hostgroup {\n";
			print FILE "	hostgroup_name	$Group_Extract\n";
			print FILE "	alias		$Alias_Extract\n";
			print FILE "	members		$Members\n";
			print FILE "}\n\n";
		}

	}

} # sub write_host_groups

sub write_service_groups {

	my $Icinga_Config_File = "$Config_Path/servicegroups.conf";
	open( FILE, ">$Icinga_Config_File" ) or die "Can't open $Icinga_Config_File";

	my $Select_Group = $DB_Connection->prepare("SELECT `id`, `servicegroup_name`, `alias`, `last_modified`, `modified_by`
	FROM `icinga2_servicegroup`
	WHERE `active` = '1'
	ORDER BY `servicegroup_name` ASC");

	$Select_Group->execute( );
	my $Rows = $Select_Group->rows();

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED FILE\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "## Service groups defined in file: $Rows\n";
	print FILE "########################################\n";
	print FILE "\n\n";



	while ( my @DB_Group = $Select_Group->fetchrow_array() )
	{
	
		my $ID_Extract = $DB_Group[0];
		my $Group_Extract = $DB_Group[1];
		my $Alias_Extract = $DB_Group[2];
		my $Last_Modified_Extract = $DB_Group[3];
		my $Modified_By_Extract = $DB_Group[4];


		print FILE "## Service Group ID: $ID_Extract\n";
		print FILE "## Modified $Last_Modified_Extract by $Modified_By_Extract\n";
		print FILE "define servicegroup {\n";
		print FILE "	servicegroup_name	$Group_Extract\n";
		print FILE "	alias			$Alias_Extract\n";
		print FILE "}\n";
		print FILE "\n";

	}

} # sub write_service_groups

sub write_contact_groups {

	my $Icinga_Config_File = "$Config_Path/contactgroups.conf";
	open( FILE, ">$Icinga_Config_File" ) or die "Can't open $Icinga_Config_File";

	my $Select_Group = $DB_Connection->prepare("SELECT `id`, `contactgroup_name`, `alias`, `last_modified`, `modified_by`
	FROM `icinga2_contactgroup`
	WHERE `active` = '1'
	ORDER BY `contactgroup_name` ASC");

	$Select_Group->execute( );
	my $Rows = $Select_Group->rows();

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED FILE\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "## Contact groups defined in file: $Rows\n";
	print FILE "########################################\n";
	print FILE "\n\n";


	while ( my @DB_Group = $Select_Group->fetchrow_array() )
	{
	
		my $ID_Extract = $DB_Group[0];
		my $Group_Extract = $DB_Group[1];
		my $Alias_Extract = $DB_Group[2];
		my $Last_Modified_Extract = $DB_Group[3];
		my $Modified_By_Extract = $DB_Group[4];

		my $Select_Members = $DB_Connection->prepare("SELECT `idMaster`
		FROM `icinga2_lnkContactToContactgroup`
		WHERE `idSlave` = ?");
		$Select_Members->execute($ID_Extract);

		my $Members;
		while ( my @DB_Members = $Select_Members->fetchrow_array() )
		{
			my $idMaster = $DB_Members[0];
			
			my $Select_Member_Names = $DB_Connection->prepare("SELECT `contact_name`
			FROM `icinga2_contact`
			WHERE `id` = ?");
			$Select_Member_Names->execute($idMaster);

			while ( my @DB_Member_Names = $Select_Member_Names->fetchrow_array() )
			{
				my $Member = $DB_Member_Names[0];
				$Members = $Member.", ".$Members;
			}
		}

		$Members =~ s/, $//g;

		if ($Members) {
			print FILE "## Contact Group ID: $ID_Extract\n";
			print FILE "## Modified $Last_Modified_Extract by $Modified_By_Extract\n";
			print FILE "define contactgroup {\n";
			print FILE "	contactgroup_name	$Group_Extract\n";
			print FILE "	alias			$Alias_Extract\n";
			print FILE "	members			$Members\n";
			print FILE "}\n";
			print FILE "\n";
		}

	}

} # sub write_contact_groups

sub write_host_templates {

	my $Icinga_Config_File = "$Config_Path/hosttemplates.conf";
	open( FILE, ">$Icinga_Config_File" ) or die "Can't open $Icinga_Config_File";

	my $Select_Host_Template = $DB_Connection->prepare("SELECT `id`, `template_name`, `active_checks_enabled`, `check_freshness`, 
	`check_period`, `event_handler_enabled`, `flap_detection_enabled`, `check_command`, `max_check_attempts`,
	`check_interval`, `notification_interval`, `notification_options`, `notification_period`, `notifications_enabled`,
	`obsess_over_host`, `passive_checks_enabled`, `process_perf_data`, `retain_nonstatus_information`,
	`retain_status_information`, `retry_interval`, `notes`, `last_modified`, `modified_by`
	FROM `icinga2_hosttemplate`
	WHERE `active` = '1'
	ORDER BY `template_name` ASC");
	
	$Select_Host_Template->execute();
	my $Rows = $Select_Host_Template->rows();

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED FILE\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "## Templates defined in file: $Rows\n";
	print FILE "########################################\n";
	print FILE "\n\n";

	
	while ( my @DB_Host_Template = $Select_Host_Template->fetchrow_array() )
	{
	
		my $ID_Extract = $DB_Host_Template[0];
		my $Template_Extract = $DB_Host_Template[1];
		my $Active_Checks_Enabled_Extract = $DB_Host_Template[2];
		my $Check_Freshness_Extract = $DB_Host_Template[3];
		my $Check_Period_Extract = $DB_Host_Template[4];
		my $Event_Handler_Enabled_Extract = $DB_Host_Template[5];
		my $Flap_Detection_Enabled_Extract = $DB_Host_Template[6];
		my $Check_Command_Extract = $DB_Host_Template[7];
		my $Max_Check_Attempts_Extract = $DB_Host_Template[8];
		my $Normal_Check_Interval_Extract = $DB_Host_Template[9];
		my $Notification_Interval_Extract = $DB_Host_Template[10];
		my $Notification_Options_Extract = $DB_Host_Template[11];
		my $Notification_Period_Extract = $DB_Host_Template[12];
		my $Notifications_Enabled_Extract = $DB_Host_Template[13];
		my $Obsess_Over_Host_Extract = $DB_Host_Template[14];
		my $Passive_Checks_Enabled_Extract = $DB_Host_Template[15];
		my $Process_Perf_Data_Extract = $DB_Host_Template[16];
		my $Retain_NonStatus_Information_Extract = $DB_Host_Template[17];
		my $Retain_Status_Information_Extract = $DB_Host_Template[18];
		my $Retry_Check_Interval_Extract = $DB_Host_Template[19];
		my $Template_Notes_Extract = $DB_Host_Template[20];
		my $Last_Modified_Extract = $DB_Host_Template[21];
		my $Modified_By_Extract = $DB_Host_Template[22];


		## Host Parent Resolution

		my $Host_Parents;
		my $Select_Host_Template_Parent_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkHosttemplateToHost`
		WHERE (`idMaster` = ?)");
		$Select_Host_Template_Parent_Link->execute($ID_Extract);

			while ( my @DB_Parent_Link = $Select_Host_Template_Parent_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Parent_Link[0];

				my $Select_Host_Template = $DB_Connection->prepare("SELECT `host_name`
				FROM `icinga2_host`
				WHERE `id` = ?");
				$Select_Host_Template->execute($Host_Link);

				while ( my @DB_Parent = $Select_Host_Template->fetchrow_array() )
				{

					my $Host_Parent = $DB_Parent[0];
					$Host_Parents = $Host_Parent.", ".$Host_Parents;

				}
			}

		## / Host Parent Resolution

		## Host Template Resolution

		my $Host_Templates;
		my $Select_Host_Template_Template_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkHosttemplateToHosttemplate`
		WHERE (`idMaster` = ?)");
		$Select_Host_Template_Template_Link->execute($ID_Extract);

			while ( my @DB_Template_Link = $Select_Host_Template_Template_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Template_Link[0];

				my $Select_Host_Template = $DB_Connection->prepare("SELECT `template_name`
				FROM `icinga2_hosttemplate`
				WHERE `id` = ?");
				$Select_Host_Template->execute($Host_Link);

				while ( my @DB_Template = $Select_Host_Template->fetchrow_array() )
				{

					my $Host_Template = $DB_Template[0];
					$Host_Templates = $Host_Template.", ".$Host_Templates;

				}
			}

		## / Host Template Resolution

		## Host Contact Group Resolution

		my $Host_Contact_Groups;
		my $Select_Host_Template_Contact_Group_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkHosttemplateToContactgroup`
		WHERE (`idMaster` = ?)");
		$Select_Host_Template_Contact_Group_Link->execute($ID_Extract);

			while ( my @DB_Contact_Group_Link = $Select_Host_Template_Contact_Group_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Contact_Group_Link[0];

				my $Select_Host_Template = $DB_Connection->prepare("SELECT `contactgroup_name`
				FROM `icinga2_contactgroup`
				WHERE `id` = ?");
				$Select_Host_Template->execute($Host_Link);

				while ( my @DB_Contact_Group = $Select_Host_Template->fetchrow_array() )
				{

					my $Host_Contact_Group = $DB_Contact_Group[0];
					$Host_Contact_Groups = $Host_Contact_Group.", ".$Host_Contact_Groups;

				}
			}

		## / Host Contact Group Resolution

		## Host Template's Template Values

		my $Host_Template_ID;
		my $Description_Extract_Template;
		my $Last_Modified_Extract_Template;
		my $Modified_By_Extract_Template;
		my $Notes_Extract_Template;
		my $Check_Period_Extract_Template;
		my $Notification_Period_Extract_Template;
		my $Check_Command_Extract_Template;
		my $Select_Host_Template_Template_ID = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkHosttemplateToHosttemplate`
		WHERE `idMaster` = ?");
		$Select_Host_Template_Template_ID->execute($ID_Extract);
		
		while ( my @DB_Host_Template_Template_ID = $Select_Host_Template_Template_ID->fetchrow_array() )
		{

			$Host_Template_ID = $DB_Host_Template_Template_ID[0];

			my $Select_Host_Template_Template = $DB_Connection->prepare("SELECT `template_name`, `active_checks_enabled`, `check_freshness`, 
			`check_period`, `event_handler_enabled`, `flap_detection_enabled`, `check_command`, `max_check_attempts`, `check_interval`,
			`notification_interval`, `notification_options`, `notification_period`, `notifications_enabled`, `obsess_over_host`,
			`passive_checks_enabled`, `process_perf_data`, `retain_nonstatus_information`, `retain_status_information`,
			`retry_interval`, `notes`, `last_modified`, `modified_by`
			FROM `icinga2_hosttemplate`
			WHERE `id` = ?");
			$Select_Host_Template_Template->execute($Host_Template_ID);
			
			while ( my @DB_Host_Template_Template = $Select_Host_Template_Template->fetchrow_array() )
			{
	
				$Description_Extract_Template = $DB_Host_Template_Template[0];
				my $Active_Checks_Enabled_Extract_Template = $DB_Host_Template_Template[1];
				my $Check_Freshness_Extract_Template = $DB_Host_Template_Template[2];
				$Check_Period_Extract_Template = $DB_Host_Template_Template[3];
				my $Event_Handler_Enabled_Extract_Template = $DB_Host_Template_Template[4];
				my $Flap_Detection_Enabled_Extract_Template = $DB_Host_Template_Template[5];
				$Check_Command_Extract_Template = $DB_Host_Template_Template[6];
				my $Max_Check_Attempts_Extract_Template = $DB_Host_Template_Template[7];
				my $Normal_Check_Interval_Extract_Template = $DB_Host_Template_Template[8];
				my $Notification_Interval_Extract_Template = $DB_Host_Template_Template[9];
				my $Notification_Options_Extract_Template = $DB_Host_Template_Template[10];
				$Notification_Period_Extract_Template = $DB_Host_Template_Template[11];
				my $Notifications_Enabled_Extract_Template = $DB_Host_Template_Template[12];
				my $Obsess_Over_Host_Extract_Template = $DB_Host_Template_Template[13];
				my $Passive_Checks_Enabled_Extract_Template = $DB_Host_Template_Template[14];
				my $Process_Perf_Data_Extract_Template = $DB_Host_Template_Template[15];
				my $Retain_NonStatus_Information_Extract_Template = $DB_Host_Template_Template[16];
				my $Retain_Status_Information_Extract_Template = $DB_Host_Template_Template[17];
				my $Retry_Check_Interval_Extract_Template = $DB_Host_Template_Template[18];
				$Notes_Extract_Template = $DB_Host_Template_Template[19];
				$Last_Modified_Extract_Template = $DB_Host_Template_Template[20];
				$Modified_By_Extract_Template = $DB_Host_Template_Template[21];

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

		## / Template's Template Values

		## Check Period Link Collection

		my $Check_Period;

		if ($Check_Period_Extract) {
			$Check_Period = $Check_Period_Extract;
		}
		elsif ($Check_Period_Extract_Template != 0) {
			$Check_Period = $Check_Period_Extract_Template;
		}

		my $Select_Check_Period = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = ?");
		$Select_Check_Period->execute($Check_Period);
		
		while ( my @DB_Time_Period = $Select_Check_Period->fetchrow_array() )
		{
			$Check_Period = $DB_Time_Period[0];


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

		my $Select_Notification_Period = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = ?");
		$Select_Notification_Period->execute($Notification_Period);
		
		while ( my @DB_Time_Period = $Select_Notification_Period->fetchrow_array() )
		{
			$Notification_Period = $DB_Time_Period[0];

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
		my $Select_Check_Command = $DB_Connection->prepare("SELECT `command_name`
		FROM `icinga2_command`
		WHERE `id` = ?");
		$Select_Check_Command->execute($Check_Command_Where_ID_Extract);

			while ( my @DB_Command = $Select_Check_Command->fetchrow_array() )
			{

				$Check_Command = $DB_Command[0];
				$Check_Command = $Check_Command.$Check_Command_Where_Remaining;

			}

		## / Check Command Partial Conversion

		$Host_Parents =~ s/, $//g;
		$Host_Templates =~ s/, $//g;
		$Host_Contact_Groups =~ s/, $//g;

		print FILE "## Host Template ID: $ID_Extract\n";
		print FILE "## Modified $Last_Modified_Extract by $Modified_By_Extract\n";
		print FILE "## Host Template Notes: $Template_Notes_Extract\n";

		if ($Host_Template_ID) {
		
			print FILE "## Template's Template ID: $Host_Template_ID\n";
			print FILE "## Template's Template Name: $Description_Extract_Template\n";
			print FILE "## Template's Template Modified: $Last_Modified_Extract_Template by $Modified_By_Extract_Template\n";
			print FILE "## Template's Template Notes: $Notes_Extract_Template\n";
		}

		print FILE "template Host \"$Template_Extract\" {\n";

#		if ($Host_Templates) {
#			print FILE "	use				$Host_Templates\n";
#		}


#		if ($Notification_Interval_Extract) {
#			print FILE "	notification_interval = $Notification_Interval_Extract\n";
#		}
		if ($Max_Check_Attempts_Extract) {
			print FILE "	max_check_attempts = $Max_Check_Attempts_Extract\n";
		}
#		if ($Notification_Period) {
#			print FILE "	notification_period = \"$Notification_Period\"\n";
#		}
#		if ($Notification_Options_Extract) {
#			print FILE "	notification_options = \"$Notification_Options_Extract\"\n";
#		}
#		if ($Check_Period) {
#			print FILE "	check_period = \"$Check_Period\"\n";
#		}
#		if ($Host_Contact_Groups) {
#			print FILE "	contact_groups = \"$Host_Contact_Groups\"\n";
#		}
		if ($Check_Command) {
			$Check_Command =~ s/\"/\\"/g;
			print FILE "	check_command = \"$Check_Command\"\n";
		}
		if ($Normal_Check_Interval_Extract) {
			print FILE "	check_interval = \"$Normal_Check_Interval_Extract\"\n";
		}
		if ($Retry_Check_Interval_Extract) {
			print FILE "	retry_interval = \"$Retry_Check_Interval_Extract\"\n";
		}
		if ($Active_Checks_Enabled_Extract ne 2) {
			print FILE "	active_checks_enabled = \"$Active_Checks_Enabled_Extract\"\n";
		}
		if ($Passive_Checks_Enabled_Extract ne 2) {
			print FILE "	passive_checks_enabled = \"$Passive_Checks_Enabled_Extract\"\n";
		}
		if ($Obsess_Over_Host_Extract ne 2) {
			print FILE "	obsess_over_host = \"$Obsess_Over_Host_Extract\"\n";
		}
		if ($Check_Freshness_Extract ne 2) {
			print FILE "	check_freshness = \"$Check_Freshness_Extract\"\n";
		}
#		if ($Event_Handler_Enabled_Extract ne 2) {
#			print FILE "	event_handler_enabled = \"$Event_Handler_Enabled_Extract\"\n";
#		}
#		if ($Flap_Detection_Enabled_Extract ne 2) {
#			print FILE "	flap_detection_enabled = \"$Flap_Detection_Enabled_Extract\"\n";
#		}
#		if ($Notifications_Enabled_Extract ne 2) {
#			print FILE "	notifications_enabled = \"$Notifications_Enabled_Extract\"\n";
#		}
#		if ($Process_Perf_Data_Extract ne 2) {
#			print FILE "	process_perf_data = \"$Process_Perf_Data_Extract\"\n";
#		}
#		if ($Retain_NonStatus_Information_Extract ne 2) {
#			print FILE "	retain_nonstatus_information = \"$Retain_NonStatus_Information_Extract\"\n";
#		}
#		if ($Retain_Status_Information_Extract ne 2) {
#			print FILE "	retain_status_information = \"$Retain_Status_Information_Extract\"\n";
#		}
#		if ($Host_Parents) {
#			print FILE "	parents = \"$Host_Parents\"\n";
#		}
		
		#print FILE "	register			0\n";
		print FILE "}\n";
		print FILE "\n";

	}

} # sub write_host_templates

sub write_service_templates {

	my $Icinga_Config_File = "$Config_Path/servicetemplates.conf";
	open( FILE, ">$Icinga_Config_File" ) or die "Can't open $Icinga_Config_File";

	my $Select_Service = $DB_Connection->prepare("SELECT `id`, `template_name`, `active_checks_enabled`, `check_freshness`, 
	`check_period`, `event_handler_enabled`, `flap_detection_enabled`, `check_command`, `is_volatile`, `max_check_attempts`,
	`check_interval`, `notification_interval`, `notification_options`, `notification_period`, `notifications_enabled`,
	`obsess_over_service`, `parallelize_check`, `passive_checks_enabled`, `process_perf_data`, `retain_nonstatus_information`,
	`retain_status_information`, `retry_interval`, `last_modified`, `modified_by`
	FROM `icinga2_servicetemplate`
	WHERE `active` = '1'
	ORDER BY `template_name` ASC");

	$Select_Service->execute( );
	my $Rows = $Select_Service->rows();

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED FILE\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "## Templates defined in file: $Rows\n";
	print FILE "########################################\n";
	print FILE "\n\n";

	
	while ( my @DB_Service = $Select_Service->fetchrow_array() )
	{

		my $Template_ID_Extract = $DB_Service[0];
		my $Template_Name_Extract = $DB_Service[1];
		my $Active_Checks_Enabled_Extract = $DB_Service[2];
		my $Check_Freshness_Extract = $DB_Service[3];
		my $Check_Period_Extract = $DB_Service[4];
		my $Event_Handler_Enabled_Extract = $DB_Service[5];
		my $Flap_Detection_Enabled_Extract = $DB_Service[6];
		my $Check_Command_Extract = $DB_Service[7];
		my $Is_Volatile_Extract = $DB_Service[8];
		my $Max_Check_Attempts_Extract = $DB_Service[9];
		my $Normal_Check_Interval_Extract = $DB_Service[10];
		my $Notification_Interval_Extract = $DB_Service[11];
		my $Notification_Options_Extract = $DB_Service[12];
		my $Notification_Period_Extract = $DB_Service[13];
		my $Notifications_Enabled_Extract = $DB_Service[14];
		my $Obsess_Over_Service_Extract = $DB_Service[15];
		my $Parallelize_Check_Extract = $DB_Service[16];
		my $Passive_Checks_Enabled_Extract = $DB_Service[17];
		my $Process_Perf_Data_Extract = $DB_Service[18];
		my $Retain_NonStatus_Information_Extract = $DB_Service[19];
		my $Retain_Status_Information_Extract = $DB_Service[20];
		my $Retry_Check_Interval_Extract = $DB_Service[21];
		my $Last_Modified_Extract = $DB_Service[22];
		my $Modified_By_Extract = $DB_Service[23];


		## Service Template's Template Values

		my $Service_Templates_Template_ID;
		my $Service_Description_Extract_Templates_Template;
		my $Last_Modified_Extract_Templates_Template;
		my $Modified_By_Extract_Templates_Template;
		my $Check_Period_Extract_Templates_Template;
		my $Notification_Period_Extract_Templates_Template;
		my $Check_Command_Extract_Templates_Template;
		my $Select_Service_Templates_Template_ID = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServicetemplateToServicetemplate`
		WHERE `idMaster` = ?");
		$Select_Service_Templates_Template_ID->execute($Template_ID_Extract);
		
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
	
				$Service_Description_Extract_Templates_Template = $DB_Service_Templates_Template[0];
				my $Active_Checks_Enabled_Extract_Templates_Template = $DB_Service_Templates_Template[1];
				my $Check_Freshness_Extract_Templates_Template = $DB_Service_Templates_Template[2];
				$Check_Period_Extract_Templates_Template = $DB_Service_Templates_Template[3];
				my $Event_Handler_Enabled_Extract_Templates_Template = $DB_Service_Templates_Template[4];
				my $Flap_Detection_Enabled_Extract_Templates_Template = $DB_Service_Templates_Template[5];
				$Check_Command_Extract_Templates_Template = $DB_Service_Templates_Template[6];
				my $Is_Volatile_Extract_Templates_Template = $DB_Service_Templates_Template[7];
				my $Max_Check_Attempts_Extract_Templates_Template = $DB_Service_Templates_Template[8];
				my $Normal_Check_Interval_Extract_Templates_Template = $DB_Service_Templates_Template[9];
				my $Notification_Interval_Extract_Templates_Template = $DB_Service_Templates_Template[10];
				my $Notification_Options_Extract_Templates_Template = $DB_Service_Templates_Template[11];
				$Notification_Period_Extract_Templates_Template = $DB_Service_Templates_Template[12];
				my $Notifications_Enabled_Extract_Templates_Template = $DB_Service_Templates_Template[13];
				my $Obsess_Over_Service_Extract_Templates_Template = $DB_Service_Templates_Template[14];
				my $Parallelize_Check_Extract_Templates_Template = $DB_Service_Templates_Template[15];
				my $Passive_Checks_Enabled_Extract_Templates_Template = $DB_Service_Templates_Template[16];
				my $Process_Perf_Data_Extract_Templates_Template = $DB_Service_Templates_Template[17];
				my $Retain_NonStatus_Information_Extract_Templates_Template = $DB_Service_Templates_Template[18];
				my $Retain_Status_Information_Extract_Templates_Template = $DB_Service_Templates_Template[19];
				my $Retry_Check_Interval_Extract_Templates_Template = $DB_Service_Templates_Template[20];
				my $Active_Extract_Templates_Template = $DB_Service_Templates_Template[21];
				$Last_Modified_Extract_Templates_Template = $DB_Service_Templates_Template[22];
				$Modified_By_Extract_Templates_Template = $DB_Service_Templates_Template[23];

				if ($Active_Checks_Enabled_Extract eq undef || $Active_Checks_Enabled_Extract eq 2) {
					$Active_Checks_Enabled_Extract = $Active_Checks_Enabled_Extract_Templates_Template;
				}
				if ($Check_Freshness_Extract eq undef || $Check_Freshness_Extract eq 2) {
					$Check_Freshness_Extract = $Check_Freshness_Extract_Templates_Template;
				}
				if ($Event_Handler_Enabled_Extract eq undef || $Event_Handler_Enabled_Extract eq 2) {
					$Event_Handler_Enabled_Extract = $Event_Handler_Enabled_Extract_Templates_Template;
				}
				if ($Flap_Detection_Enabled_Extract eq undef || $Flap_Detection_Enabled_Extract eq 2) {
					$Flap_Detection_Enabled_Extract = $Flap_Detection_Enabled_Extract_Templates_Template;
				}
				if ($Max_Check_Attempts_Extract eq undef || $Max_Check_Attempts_Extract eq 2) {
					$Max_Check_Attempts_Extract = $Max_Check_Attempts_Extract_Templates_Template;
				}
				if ($Normal_Check_Interval_Extract eq undef) {
					$Normal_Check_Interval_Extract = $Normal_Check_Interval_Extract_Templates_Template;
				}
				if ($Notification_Interval_Extract eq undef) {
					$Notification_Interval_Extract = $Notification_Interval_Extract_Templates_Template;
				}
				if ($Notification_Options_Extract eq undef || $Notification_Options_Extract eq 2) {
					$Notification_Options_Extract = $Notification_Options_Extract_Templates_Template;
				}
				if ($Notifications_Enabled_Extract eq undef || $Notifications_Enabled_Extract eq 2) {
					$Notifications_Enabled_Extract = $Notifications_Enabled_Extract_Templates_Template;
					if ($Notifications_Enabled_Extract eq 2) {$Notifications_Enabled_Extract = undef}
				}
				if ($Obsess_Over_Service_Extract eq undef || $Obsess_Over_Service_Extract eq 2) {
					$Obsess_Over_Service_Extract = $Obsess_Over_Service_Extract_Templates_Template;
				}
				if ($Passive_Checks_Enabled_Extract eq undef || $Passive_Checks_Enabled_Extract eq 2) {
					$Passive_Checks_Enabled_Extract = $Passive_Checks_Enabled_Extract_Templates_Template;
				}
				if ($Process_Perf_Data_Extract eq undef || $Process_Perf_Data_Extract eq 2) {
					$Process_Perf_Data_Extract = $Process_Perf_Data_Extract_Templates_Template;
				}
				if ($Retain_NonStatus_Information_Extract eq undef || $Retain_NonStatus_Information_Extract eq 2) {
					$Retain_NonStatus_Information_Extract = $Retain_NonStatus_Information_Extract_Templates_Template;
				}
				if ($Retain_Status_Information_Extract eq undef || $Retain_Status_Information_Extract eq 2) {
					$Retain_Status_Information_Extract = $Retain_Status_Information_Extract_Templates_Template;
				}
				if ($Retry_Check_Interval_Extract eq undef) {
					$Retry_Check_Interval_Extract = $Retry_Check_Interval_Extract_Templates_Template;
				}
				if ($Is_Volatile_Extract eq undef || $Is_Volatile_Extract eq 2) {
					$Is_Volatile_Extract = $Is_Volatile_Extract_Templates_Template;
				}
				if ($Check_Period_Extract eq undef || $Check_Period_Extract eq 2) {
					$Check_Period_Extract = $Check_Period_Extract_Templates_Template;
				}
				if ($Parallelize_Check_Extract eq undef || $Parallelize_Check_Extract eq 2) {
					$Parallelize_Check_Extract = $Parallelize_Check_Extract_Templates_Template;
				}

			}
		}

			## / Service Template's Template Values
	
			# Host Name Collection
			my $Host_Names;
			my $Select_Host_Name_Link = $DB_Connection->prepare("SELECT `idSlave`
			FROM `icinga2_lnkServicetemplateToHost`
			WHERE `idMaster` = ?");
			$Select_Host_Name_Link->execute($Template_ID_Extract);
		
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
					$Host_Names = "$Host_Name, $Host_Names";
				}
			}
	
			# / Host Name Collection
	
			# Host Group Collection
				my $Host_Group_Names;
				my $Select_Host_Group_Link = $DB_Connection->prepare("SELECT `idSlave`
				FROM `icinga2_lnkServicetemplateToHostgroup`
				WHERE `idMaster` = ?");
				$Select_Host_Group_Link->execute($Template_ID_Extract);
			
				while ( my @DB_Host_Link = $Select_Host_Group_Link->fetchrow_array() )
				{
		
					my $Host_ID = $DB_Host_Link[0];
		
					my $Select_Host_Group_Name = $DB_Connection->prepare("SELECT `hostgroup_name`
					FROM `icinga2_hostgroup`
					WHERE `id` = '$Host_ID'
					AND `active` = '1'");
					$Select_Host_Group_Name->execute();
		
					while ( my @DB_Host_Group = $Select_Host_Group_Name->fetchrow_array() )
					{
						my $Host_Group_Name = $DB_Host_Group[0];
						$Host_Group_Names = "$Host_Group_Name, $Host_Group_Names";
					}
				}
	
			# / Host Group Collection
	
			# Contact Link Collection
			my $Contacts;
			my $Select_Contact_Name_Link = $DB_Connection->prepare("SELECT `idSlave`
			FROM `icinga2_lnkServicetemplateToContact`
			WHERE `idMaster` = ?");
			$Select_Contact_Name_Link->execute($Template_ID_Extract);
		
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
					$Contacts = "$Contact_Name, $Contacts";
				}
			}
	
			# / Contact Link Collection
	
			# Contact Group Link Collection
			my $Contact_Groups;
			my $Select_Group_Link = $DB_Connection->prepare("SELECT `idSlave`
			FROM `icinga2_lnkServicetemplateToContactgroup`
			WHERE `idMaster` = ?");
			$Select_Group_Link->execute($Template_ID_Extract);
		
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
					$Contact_Groups = "$Contact_Group, $Contact_Groups";
				}
			}
	
			# / Contact Group Link Collection
	
		## Check Period Link Collection

		my $Select_Check_Period = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = ?");
		$Select_Check_Period->execute($Check_Period_Extract);
		
		while ( my @DB_Time_Period = $Select_Check_Period->fetchrow_array() )
		{
			$Check_Period_Extract = $DB_Time_Period[0];
		}

		## / Check Period Link Collection

		## Notification Period Link Collection

		my $Select_Notification_Period = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = ?");
		$Select_Notification_Period->execute($Notification_Period_Extract);
		
		while ( my @DB_Time_Period = $Select_Notification_Period->fetchrow_array() )
		{
			$Notification_Period_Extract = $DB_Time_Period[0];
		}

		## / Notification Period Link Collection

	
	
			## Check Command Partial Conversion
	
			my $Check_Command_Extract_ID_Extract = $Check_Command_Extract;
				$Check_Command_Extract_ID_Extract =~ s/^(\d*).*/$1/g;
			my $Check_Command_Extract_Remaining = $Check_Command_Extract;
				$Check_Command_Extract_Remaining =~ s/^\d*(.*)/$1/g;
			my $Check_Command;
			my $Select_Check_Command = $DB_Connection->prepare("SELECT `command_name`
			FROM `icinga2_command`
			WHERE `id` = '$Check_Command_Extract_ID_Extract'");
			$Select_Check_Command->execute();
	
				while ( my @DB_Command = $Select_Check_Command->fetchrow_array() )
				{
	
					$Check_Command = $DB_Command[0];
					$Check_Command = $Check_Command.$Check_Command_Extract_Remaining;
	
				}
	
			## / Check Command Partial Conversion
	
	
			$Host_Names =~ s/, $//g;
				if ($Host_Names eq 0) {$Host_Names = ''};
			$Host_Group_Names =~ s/, $//g;
				if ($Host_Group_Names eq 0) {$Host_Group_Names = ''};
			$Contacts =~ s/, $//g;
			$Contact_Groups =~ s/, $//g;


			print FILE "## Service Template ID: $Template_ID_Extract\n";
			print FILE "## Modified $Last_Modified_Extract by $Modified_By_Extract\n";

			if ($Service_Templates_Template_ID) {
				print FILE "## Template's Template ID: $Service_Templates_Template_ID\n";
				print FILE "## Template's Template Name: $Service_Description_Extract_Templates_Template\n";
				print FILE "## Template's Template Modified: $Last_Modified_Extract_Templates_Template by $Modified_By_Extract_Templates_Template\n";
			}

			print FILE "template Service \"$Template_Name_Extract\" {\n";

			if ($Service_Description_Extract_Templates_Template) {
				print FILE "	import \"$Service_Description_Extract_Templates_Template\"\n";
			}

#			if ($Host_Names) {
#				print FILE "	host_name			$Host_Names\n";
#			}
#			if ($Host_Group_Names) {
#				print FILE "	hostgroup_name			$Host_Group_Names\n";
#			}
			if ($Check_Command) {
				$Check_Command =~ s/\"/\\"/g;
				print FILE "	check_command = \"$Check_Command\"\n";
			}
#			if ($Active_Checks_Enabled_Extract) {
#				print FILE "	active_checks_enabled = \"$Active_Checks_Enabled_Extract\"\n";
#			}
#			if ($Passive_Checks_Enabled_Extract) {
#				print FILE "	passive_checks_enabled = \"$Passive_Checks_Enabled_Extract\"\n";
#			}
#			if ($Parallelize_Check_Extract) {
#				print FILE "	parallelize_check = \"$Parallelize_Check_Extract\"\n";
#			}
#			if ($Obsess_Over_Service_Extract) {
#				print FILE "	obsess_over_service = \"$Obsess_Over_Service_Extract\"\n";
#			}
#			if ($Check_Freshness_Extract) {
#				print FILE "	check_freshness = \"$Check_Freshness_Extract\"\n";
#			}
#			if ($Notifications_Enabled_Extract) {
#				print FILE "	notifications_enabled = \"$Notifications_Enabled_Extract\"\n";
#			}
#			if ($Event_Handler_Enabled_Extract) {
#				print FILE "	event_handler_enabled = \"$Event_Handler_Enabled_Extract\"\n";
#			}
#			if ($Flap_Detection_Enabled_Extract) {
#				print FILE "	flap_detection_enabled = \"$Flap_Detection_Enabled_Extract\"\n";
#			}
#			if ($Process_Perf_Data_Extract) {
#				print FILE "	process_perf_data = \"$Process_Perf_Data_Extract\"\n";
#			}
#			if ($Retain_Status_Information_Extract) {
#				print FILE "	retain_status_information = \"$Retain_Status_Information_Extract\"\n";
#			}
#			if ($Retain_NonStatus_Information_Extract) {
#				print FILE "	retain_nonstatus_information = \"$Retain_NonStatus_Information_Extract\"\n";
#			}
#			if ($Is_Volatile_Extract) {
#				print FILE "	is_volatile = \"$Is_Volatile_Extract\"\n";
#			}
			if ($Check_Period_Extract) {
				print FILE "	check_period = \"$Check_Period_Extract\"\n";
			}
			if ($Max_Check_Attempts_Extract) {
				print FILE "	max_check_attempts = \"$Max_Check_Attempts_Extract\"\n";
			}
#			if ($Normal_Check_Interval_Extract) {
#				print FILE "	normal_check_interval = \"$Normal_Check_Interval_Extract\"\n";
#			}
#			if ($Retry_Check_Interval_Extract) {
#				print FILE "	retry_check_interval = \"$Retry_Check_Interval_Extract\"\n";
#			}
			if ($Contacts) {
				print FILE "	contacts = \"$Contacts\"\n";
			}
#			if ($Contact_Groups) {
#				print FILE "	contact_groups = \"$Contact_Groups\"\n";
#			}
#			if ($Notification_Options_Extract) {
#				print FILE "	notification_options = \"$Notification_Options_Extract\"\n";
#			}
#			if ($Notification_Interval_Extract) {
#				print FILE "	notification_interval = \"$Notification_Interval_Extract\"\n";
#			}
#			if ($Notification_Period_Extract) {
#				print FILE "	notification_period = \"$Notification_Period_Extract\"\n";
#			}
	
#			print FILE "	register		0\n";
			print FILE "}\n\n";

	}

} # sub write_service_templates

sub write_contacts {

	my $Icinga_Config_File = "$Config_Path/contacts.conf";
	open( FILE, ">$Icinga_Config_File" ) or die "Can't open $Icinga_Config_File";

	my $Select_Contact = $DB_Connection->prepare("SELECT `id`, `contact_name`, `alias`, `host_notification_period`,
	`service_notification_period`, `host_notification_options`, `service_notification_options`, `email`,
	`last_modified`, `modified_by`
	FROM `icinga2_contact`
	WHERE `active` = '1'
	ORDER BY `contact_name` ASC");

	$Select_Contact->execute( );
	my $Rows = $Select_Contact->rows();

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED FILE\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "## Contacts defined in file: $Rows\n";
	print FILE "########################################\n";
	print FILE "\n\n";


	
	while ( my @DB_Contact = $Select_Contact->fetchrow_array() )
	{

		my $ID_Extract = $DB_Contact[0];
		my $Name_Extract = $DB_Contact[1];
		my $Alias_Extract = $DB_Contact[2];
		my $Host_Notification_Period_Extract = $DB_Contact[3];
		my $Service_Notification_Period_Extract = $DB_Contact[4];
		my $Host_Notification_Options_Extract = $DB_Contact[5];
		my $Service_Notification_Options_Extract = $DB_Contact[6];
		my $Email_Extract = $DB_Contact[7];
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
		$Select_Host_Command_Link->execute($ID_Extract);

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
		$Select_Service_Command_Link->execute($ID_Extract);

			my $Service_Notification_Command_Conversion;
			while ( my @DB_Service_Command_Link = $Select_Service_Command_Link->fetchrow_array() )
			{
				my $Service_Notification_Command_ID = $DB_Service_Command_Link[0];

				my $Select_Service_Command_Name = $DB_Connection->prepare("SELECT `command_name`
				FROM `icinga2_command`
				WHERE `id` = '$Service_Notification_Command_ID'");
				$Select_Service_Command_Name->execute();

				while ( my @DB_Service_Command_Conversion = $Select_Service_Command_Name->fetchrow_array() )
				{
					$Service_Notification_Command_Conversion = $DB_Service_Command_Conversion[0].", ".$Service_Notification_Command_Conversion;
				}
			}

		$Host_Notification_Command_Conversion =~ s/,\ $//g;
		$Service_Notification_Command_Conversion =~ s/,\ $//g;
		### / Command Conversion

		$Email_Extract =~ s/,/,\ /g;

		print FILE "## Contact ID: $ID_Extract\n";
		print FILE "## Modified $Last_Modified_Extract by $Modified_By_Extract\n";
		print FILE "define contact {\n";
		print FILE "	contact_name			$Name_Extract\n";
		print FILE "	alias				$Alias_Extract\n";
		print FILE "	email				$Email_Extract\n";
		print FILE "	host_notification_commands	$Host_Notification_Command_Conversion\n";
		print FILE "	host_notification_options	$Host_Notification_Options_Extract\n";
		print FILE "	host_notification_period	$Host_Notification_Period_Conversion\n";
		print FILE "	service_notification_commands	$Service_Notification_Command_Conversion\n";
		print FILE "	service_notification_options	$Service_Notification_Options_Extract\n";
		print FILE "	service_notification_period	$Service_Notification_Period_Conversion\n";
		print FILE "}\n";
		print FILE "\n";

	}

} # sub write_contacts

sub write_hosts {

	my $Icinga_Config_File = "$Config_Path/hosts.conf";
	open( FILE, ">$Icinga_Config_File" ) or die "Can't open $Icinga_Config_File";

	my $Select_Host = $DB_Connection->prepare("SELECT `id`, `host_name`, `alias`, `address`, `active_checks_enabled`, `check_freshness`, 
	`check_period`, `event_handler_enabled`, `flap_detection_enabled`, `check_command`, `max_check_attempts`,
	`check_interval`, `notification_interval`, `notification_options`, `notification_period`, `notifications_enabled`,
	`obsess_over_host`, `passive_checks_enabled`, `process_perf_data`, `retain_nonstatus_information`,
	`retain_status_information`, `retry_interval`, `notes`, `last_modified`, `modified_by`
	FROM `icinga2_host`
	WHERE `active` = '1'
	ORDER BY `host_name` ASC");

	$Select_Host->execute( );
	my $Rows = $Select_Host->rows();

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED FILE\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "## Hosts defined in file: $Rows\n";
	print FILE "########################################\n";
	print FILE "\n\n";

	
	while ( my @DB_Host = $Select_Host->fetchrow_array() )
	{
	
		my $ID_Extract = $DB_Host[0];
		my $Host_Extract = $DB_Host[1];
		my $Alias_Extract = $DB_Host[2];
		my $IP_Extract = $DB_Host[3];
		my $Active_Checks_Enabled_Extract = $DB_Host[4];
		my $Check_Freshness_Extract = $DB_Host[5];
		my $Check_Period_Extract = $DB_Host[6];
		my $Event_Handler_Enabled_Extract = $DB_Host[7];
		my $Flap_Detection_Enabled_Extract = $DB_Host[8];
		my $Check_Command_Extract = $DB_Host[9];
		my $Max_Check_Attempts_Extract = $DB_Host[10];
		my $Normal_Check_Interval_Extract = $DB_Host[11];
		my $Notification_Interval_Extract = $DB_Host[12];
		my $Notification_Options_Extract = $DB_Host[13];
		my $Notification_Period_Extract = $DB_Host[14];
		my $Notifications_Enabled_Extract = $DB_Host[15];
		my $Obsess_Over_Host_Extract = $DB_Host[16];
		my $Passive_Checks_Enabled_Extract = $DB_Host[17];
		my $Process_Perf_Data_Extract = $DB_Host[18];
		my $Retain_NonStatus_Information_Extract = $DB_Host[19];
		my $Retain_Status_Information_Extract = $DB_Host[20];
		my $Retry_Check_Interval_Extract = $DB_Host[21];
		my $Host_Notes_Extract = $DB_Host[22];
		my $Last_Modified_Extract = $DB_Host[23];
		my $Modified_By_Extract = $DB_Host[24];


		## Host Parent Resolution

		my $Host_Parents;
		my $Select_Host_Parent_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkHostToHost`
		WHERE `idMaster` = ?");
		$Select_Host_Parent_Link->execute($ID_Extract);

			while ( my @DB_Parent_Link = $Select_Host_Parent_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Parent_Link[0];

				my $Select_Host = $DB_Connection->prepare("SELECT `host_name`
				FROM `icinga2_host`
				WHERE `id` = ?");
				$Select_Host->execute($Host_Link);

				while ( my @DB_Parent = $Select_Host->fetchrow_array() )
				{

					my $Host_Parent = $DB_Parent[0];
					$Host_Parents = $Host_Parent.", ".$Host_Parents;

				}
			}

		## / Host Parent Resolution

		## Host Template Resolution

		my $Host_Templates;
		my $Select_Host_Template_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkHostToHosttemplate`
		WHERE (`idMaster` = ?)");
		$Select_Host_Template_Link->execute($ID_Extract);

			while ( my @DB_Template_Link = $Select_Host_Template_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Template_Link[0];

				my $Select_Host = $DB_Connection->prepare("SELECT `template_name`
				FROM `icinga2_hosttemplate`
				WHERE `id` = ?");
				$Select_Host->execute($Host_Link);

				while ( my @DB_Template = $Select_Host->fetchrow_array() )
				{

					my $Host_Template = $DB_Template[0];
					$Host_Templates = $Host_Template.", ".$Host_Templates;

				}
			}

		## / Host Template Resolution

		## Host Contact Group Resolution

		my $Host_Contact_Groups;
		my $Select_Host_Contact_Group_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkHostToContactgroup`
		WHERE `idMaster` = ?");
		$Select_Host_Contact_Group_Link->execute($ID_Extract);

			while ( my @DB_Contact_Group_Link = $Select_Host_Contact_Group_Link->fetchrow_array() )
			{

				my $Host_Link = $DB_Contact_Group_Link[0];

				my $Select_Host = $DB_Connection->prepare("SELECT `contactgroup_name`
				FROM `icinga2_contactgroup`
				WHERE `id` = ?");
				$Select_Host->execute($Host_Link);

				while ( my @DB_Contact_Group = $Select_Host->fetchrow_array() )
				{

					my $Host_Contact_Group = $DB_Contact_Group[0];
					$Host_Contact_Groups = $Host_Contact_Group.", ".$Host_Contact_Groups;

				}
			}

		## / Host Contact Group Resolution

		## Host Template Values

		my $Host_Template_ID;
		my $Host_Description_Extract_Template;
		my $Last_Modified_Extract_Template;
		my $Notes_Extract_Template;
		my $Modified_By_Extract_Template;
		my $Select_Host_Template_ID = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkHostToHosttemplate`
		WHERE `idMaster` = ?");
		$Select_Host_Template_ID->execute($ID_Extract);
		
		while ( my @DB_Host_Template_ID = $Select_Host_Template_ID->fetchrow_array() )
		{

			$Host_Template_ID = $DB_Host_Template_ID[0];

			my $Select_Host_Template = $DB_Connection->prepare("SELECT `template_name`, `notes`, `last_modified`, `modified_by`
			FROM `icinga2_hosttemplate`
			WHERE `id` = ?");
			$Select_Host_Template->execute($Host_Template_ID);
			
			while ( my @DB_Host_Template = $Select_Host_Template->fetchrow_array() )
			{
	
				$Host_Description_Extract_Template = $DB_Host_Template[0];
				$Notes_Extract_Template = $DB_Host_Template[1];
				$Last_Modified_Extract_Template = $DB_Host_Template[2];
				$Modified_By_Extract_Template = $DB_Host_Template[3];
			}
		}

		## / Host Template Values
		
		## Check Period Link Collection


		my $Select_Check_Period = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = ?");
		$Select_Check_Period->execute($Check_Period_Extract);
		
		while ( my @DB_Time_Period = $Select_Check_Period->fetchrow_array() )
		{
			$Check_Period_Extract = $DB_Time_Period[0];
		}

		## / Check Period Link Collection

		## Notification Period Link Collection

		my $Select_Notification_Period = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = ?");
		$Select_Notification_Period->execute($Notification_Period_Extract);
		
		while ( my @DB_Time_Period = $Select_Notification_Period->fetchrow_array() )
		{
			$Notification_Period_Extract = $DB_Time_Period[0];
		}

		## / Notification Period Link Collection


		## Check Command Partial Conversion


		my $Check_Command_Where_ID_Extract = $Check_Command_Extract;
			$Check_Command_Where_ID_Extract =~ s/^(\d*).*/$1/g;
		my $Check_Command_Where_Remaining = $Check_Command_Extract;
			$Check_Command_Where_Remaining =~ s/^\d*(.*)/$1/g;

		my $Select_Check_Command = $DB_Connection->prepare("SELECT `command_name`
		FROM `icinga2_command`
		WHERE `id` = ?");
		$Select_Check_Command->execute($Check_Command_Where_ID_Extract);

			while ( my @DB_Command = $Select_Check_Command->fetchrow_array() )
			{

				$Check_Command_Extract = $DB_Command[0];
				$Check_Command_Extract = $Check_Command_Extract.$Check_Command_Where_Remaining;
			}

		## / Check Command Partial Conversion

		$Host_Parents =~ s/, $//g;
		$Host_Templates =~ s/, $//g;
		$Host_Contact_Groups =~ s/, $//g;

		print FILE "## Host ID: $ID_Extract\n";
		print FILE "## Modified $Last_Modified_Extract by $Modified_By_Extract\n";
		print FILE "## Host Notes: $Host_Notes_Extract\n";
		
		if ($Host_Template_ID) {
			print FILE "## Template ID: $Host_Template_ID\n";
			print FILE "## Template Name: $Host_Description_Extract_Template\n";
			print FILE "## Template Modified: $Last_Modified_Extract_Template by $Modified_By_Extract_Template\n";
			print FILE "## Template's Notes: $Notes_Extract_Template\n";
		}

		print FILE "object Host \"$Host_Extract\" {\n";
	
			if ($Host_Template_ID) {
				print FILE "	import \"$Host_Templates\"\n";
			}
	
		print FILE "	display_name = \"$Alias_Extract\"\n";
		print FILE "	address	= \"$IP_Extract\"\n";


#		if ($Notification_Interval_Extract) {
#			print FILE "	notification_interval		$Notification_Interval_Extract\n";
#		}
#		if ($Max_Check_Attempts_Extract) {
#			print FILE "	max_check_attempts		$Max_Check_Attempts_Extract\n";
#		}
#		if ($Notification_Period_Extract) {
#			print FILE "	notification_period		$Notification_Period_Extract\n";
#		}
#		if ($Notification_Options_Extract) {
#			print FILE "	notification_options		$Notification_Options_Extract\n";
#		}
#		if ($Check_Period_Extract) {
#			print FILE "	check_period			$Check_Period_Extract\n";
#		}
#		if ($Host_Contact_Groups) {
#			print FILE "	contact_groups			$Host_Contact_Groups\n";
#		}
#		if ($Check_Command_Extract) {
#			print FILE "	check_command = \"$Check_Command_Extract\"\n";
#		}
#		else {
			print FILE "	check_command = \"hostalive\"\n";
#		}
#		if ($Normal_Check_Interval_Extract) {
#			print FILE "	normal_check_interval		$Normal_Check_Interval_Extract\n";
#		}
#		if ($Retry_Check_Interval_Extract) {
#			print FILE "	retry_check_interval		$Retry_Check_Interval_Extract\n";
#		}
#		if ($Active_Checks_Enabled_Extract ne 2) {
#			print FILE "	active_checks_enabled	$Active_Checks_Enabled_Extract\n";
#		}
#		if ($Passive_Checks_Enabled_Extract ne 2) {
#			print FILE "	passive_checks_enabled	$Passive_Checks_Enabled_Extract\n";
#		}
#		if ($Obsess_Over_Host_Extract ne 2) {
#			print FILE "	obsess_over_host	$Obsess_Over_Host_Extract\n";
#		}
#		if ($Check_Freshness_Extract ne 2) {
#			print FILE "	check_freshness	$Check_Freshness_Extract\n";
#		}
#		if ($Event_Handler_Enabled_Extract ne 2) {
#			print FILE "	event_handler_enabled		$Event_Handler_Enabled_Extract\n";
#		}
#		if ($Flap_Detection_Enabled_Extract ne 2) {
#			print FILE "	flap_detection_enabled		$Flap_Detection_Enabled_Extract\n";
#		}
#		if ($Notifications_Enabled_Extract ne 2) {
#			print FILE "	notifications_enabled		$Notifications_Enabled_Extract\n";
#		}
#		if ($Process_Perf_Data_Extract ne 2) {
#			print FILE "	process_perf_data		$Process_Perf_Data_Extract\n";
#		}
#		if ($Retain_NonStatus_Information_Extract ne 2) {
#			print FILE "	retain_nonstatus_information	$Retain_NonStatus_Information_Extract\n";
#		}
#		if ($Retain_Status_Information_Extract ne 2) {
#			print FILE "	retain_status_information	$Retain_Status_Information_Extract\n";
#		}
#		if ($Host_Parents) {
#			print FILE "	parents				$Host_Parents\n";
#		}
#		
#		print FILE "	register			1\n";
		print FILE "}\n";
		print FILE "\n";

	}

} # sub write_hosts

sub write_services {

	my $Icinga_Config_File = "$Config_Path/services.conf";
	open( FILE, ">$Icinga_Config_File" ) or die "Can't open $Icinga_Config_File";

	my $Select_Service = $DB_Connection->prepare("SELECT `id`, `service_description`, `active_checks_enabled`, `check_freshness`, 
	`check_period`, `event_handler_enabled`, `flap_detection_enabled`, `check_command`, `is_volatile`, `max_check_attempts`,
	`check_interval`, `notification_interval`, `notification_options`, `notification_period`, `notifications_enabled`,
	`obsess_over_service`, `parallelize_check`, `passive_checks_enabled`, `process_perf_data`, `retain_nonstatus_information`,
	`retain_status_information`, `retry_interval`, `active`, `last_modified`, `modified_by`
	FROM `icinga2_service`
	WHERE `active` = '1'
	ORDER BY 'service_description ASC'");

	$Select_Service->execute( );
	my $Rows = $Select_Service->rows();

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED FILE\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "## Services defined in file: $Rows\n";
	print FILE "########################################\n";
	print FILE "\n\n";


	while ( my @DB_Service = $Select_Service->fetchrow_array() )
	{
	
		my $Service_ID_Extract = $DB_Service[0];
		my $Service_Description_Extract = $DB_Service[1];
		my $Active_Checks_Enabled_Extract = $DB_Service[2];
		my $Check_Freshness_Extract = $DB_Service[3];
		my $Check_Period_Extract = $DB_Service[4];
		my $Event_Handler_Enabled_Extract = $DB_Service[5];
		my $Flap_Detection_Enabled_Extract = $DB_Service[6];
		my $Check_Command_Extract = $DB_Service[7];
		my $Is_Volatile_Extract = $DB_Service[8];
		my $Max_Check_Attempts_Extract = $DB_Service[9];
		my $Normal_Check_Interval_Extract = $DB_Service[10];
		my $Notification_Interval_Extract = $DB_Service[11];
		my $Notification_Options_Extract = $DB_Service[12];
		my $Notification_Period_Extract = $DB_Service[13];
		my $Notifications_Enabled_Extract = $DB_Service[14];
		my $Obsess_Over_Service_Extract = $DB_Service[15];
		my $Parallelize_Check_Extract = $DB_Service[16];
		my $Passive_Checks_Enabled_Extract = $DB_Service[17];
		my $Process_Perf_Data_Extract = $DB_Service[18];
		my $Retain_NonStatus_Information_Extract = $DB_Service[19];
		my $Retain_Status_Information_Extract = $DB_Service[20];
		my $Retry_Check_Interval_Extract = $DB_Service[21];
		my $Active_Extract = $DB_Service[22];
		my $Last_Modified_Extract = $DB_Service[23];
		my $Modified_By_Extract = $DB_Service[24];


		## Host Name Collection
		my $Host_Names;
		my $Select_Host_Name_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServiceToHost`
		WHERE `idMaster` = ?");
		$Select_Host_Name_Link->execute($Service_ID_Extract);
	
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
				$Host_Names = "$Host_Name, $Host_Names";
			}
		}

		## / Host Name Collection

		## Service Group Collection
			my $Service_Group_Names;
			my $Select_Service_Group_Link = $DB_Connection->prepare("SELECT `idSlave`
			FROM `icinga2_lnkServiceToServicegroup`
			WHERE `idMaster` = ?");
			$Select_Service_Group_Link->execute($Service_ID_Extract);
		
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
					$Service_Group_Names = "$Service_Group_Name, $Service_Group_Names";
				}
			}
		## / Service Group Collection

		## Contact Link Collection
		my $Contacts;
		my $Select_Contact_Name_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServiceToContact`
		WHERE `idMaster` = ?");
		$Select_Contact_Name_Link->execute($Service_ID_Extract);
	
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
				$Contacts = "$Contact_Name, $Contacts";
			}
		}

		## / Contact Link Collection

		## Contact Group Link Collection
		my $Contact_Groups;
		my $Select_Group_Link = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServiceToContactgroup`
		WHERE `idMaster` = ?");
		$Select_Group_Link->execute($Service_ID_Extract);
	
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
				$Contact_Groups = "$Contact_Group, $Contact_Groups";
			}
		}

		## / Contact Group Link Collection


		## Service Template Values

		my $Service_Template_ID;
		my $Service_Description_Extract_Template;
		my $Last_Modified_Extract_Template;
		my $Modified_By_Extract_Template;
		my $Select_Service_Template_ID = $DB_Connection->prepare("SELECT `idSlave`
		FROM `icinga2_lnkServiceToServicetemplate`
		WHERE `idMaster` = ?");
		$Select_Service_Template_ID->execute($Service_ID_Extract);
		
		while ( my @DB_Service_Template_ID = $Select_Service_Template_ID->fetchrow_array() )
		{

			$Service_Template_ID = $DB_Service_Template_ID[0];

			my $Select_Service_Template = $DB_Connection->prepare("SELECT `template_name`, `last_modified`, `modified_by`
			FROM `icinga2_servicetemplate`
			WHERE `id` = ?");
			$Select_Service_Template->execute($Service_Template_ID);
			
			while ( my @DB_Service_Template = $Select_Service_Template->fetchrow_array() )
			{
	
				$Service_Description_Extract_Template = $DB_Service_Template[0];
				$Last_Modified_Extract_Template = $DB_Service_Template[1];
				$Modified_By_Extract_Template = $DB_Service_Template[2];
			}
		}			

		## Check Period Link Collection


		my $Select_Check_Period = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = ?");
		$Select_Check_Period->execute($Check_Period_Extract);
		
		while ( my @DB_Time_Period = $Select_Check_Period->fetchrow_array() )
		{
			$Check_Period_Extract = $DB_Time_Period[0];
		}

		## / Check Period Link Collection

		## Notification Period Link Collection


		my $Select_Notification_Period = $DB_Connection->prepare("SELECT `timeperiod_name`
		FROM `icinga2_timeperiod`
		WHERE `id` = ?");
		$Select_Notification_Period->execute($Notification_Period_Extract);
		
		while ( my @DB_Time_Period = $Select_Notification_Period->fetchrow_array() )
		{
			$Notification_Period_Extract = $DB_Time_Period[0];
		}

		## / Notification Period Link Collection


		## Check Command Partial Conversion

		my $Check_Command_Where_ID_Extract = $Check_Command_Extract;
			$Check_Command_Where_ID_Extract =~ s/^(\d*).*/$1/g;
		my $Check_Command_Where_Remaining = $Check_Command_Extract;
			$Check_Command_Where_Remaining =~ s/^\d*(.*)/$1/g;

		my $Select_Check_Command = $DB_Connection->prepare("SELECT `command_name`
		FROM `icinga2_command`
		WHERE `id` = ?");
		$Select_Check_Command->execute($Check_Command_Where_ID_Extract);

			while ( my @DB_Command = $Select_Check_Command->fetchrow_array() )
			{

				$Check_Command_Extract = $DB_Command[0];
				$Check_Command_Extract = $Check_Command_Extract.$Check_Command_Where_Remaining;

			}

		## / Check Command Partial Conversion


		$Host_Names =~ s/, $//g;
			if ($Host_Names eq 0) {$Host_Names = ''};
		$Service_Group_Names =~ s/, $//g;
			if ($Service_Group_Names eq 0) {$Service_Group_Names = ''};
		$Contacts =~ s/, $//g;
		$Contact_Groups =~ s/, $//g;

			print FILE "## Service ID: $Service_ID_Extract\n";
			print FILE "## Modified $Last_Modified_Extract by $Modified_By_Extract\n";

			if ($Service_Template_ID) {
				print FILE "## Service Template ID: $Service_Template_ID\n";
				print FILE "## Modified $Last_Modified_Extract by $Modified_By_Extract\n";
			}

			if ($Service_Description_Extract) {
				print FILE "object Service \"$Service_Description_Extract\" {\n";
			}
			else {
				print FILE "object Service \"$Service_ID_Extract\" {\n";
				
			}

#			if ($Service_Description_Extract) {
#				print FILE "	service_description $Service_Description_Extract\n";
#			}

			if ($Service_Description_Extract_Template) {
				print FILE "	import \"$Service_Description_Extract_Template\"\n";
			}

			if ($Host_Names) {
				print FILE "	host_name = \"$Host_Names\"\n";
			}
#			if ($Service_Group_Names) {
#				print FILE "	servicegroups $Service_Group_Names\n";
#			}
			if ($Check_Command_Extract) {
				$Check_Command_Extract =~ s/\"/\\"/g;
				print FILE "	check_command = \"$Check_Command_Extract\"\n";
			}
#			if ($Active_Checks_Enabled_Extract && $Active_Checks_Enabled_Extract ne 2) {
#				print FILE "	active_checks_enabled $Active_Checks_Enabled_Extract\n";
#			}
#			if ($Passive_Checks_Enabled_Extract && $Passive_Checks_Enabled_Extract ne 2) {
#				print FILE "	passive_checks_enabled $Passive_Checks_Enabled_Extract\n";
#			}
#			if ($Parallelize_Check_Extract && $Parallelize_Check_Extract ne 2) {
#				print FILE "	parallelize_check $Parallelize_Check_Extract\n";
#			}
#			if ($Obsess_Over_Service_Extract && $Obsess_Over_Service_Extract ne 2) {
#				print FILE "	obsess_over_service		$Obsess_Over_Service_Extract\n";
#			}
#			if ($Check_Freshness_Extract && $Check_Freshness_Extract ne 2) {
#				print FILE "	check_freshness			$Check_Freshness_Extract\n";
#			}
#			if ($Notifications_Enabled_Extract && $Notifications_Enabled_Extract ne 2) {
#				print FILE "	notifications_enabled		$Notifications_Enabled_Extract\n";
#			}
#			if ($Event_Handler_Enabled_Extract && $Event_Handler_Enabled_Extract ne 2) {
#				print FILE "	event_handler_enabled		$Event_Handler_Enabled_Extract\n";
#			}
#			if ($Flap_Detection_Enabled_Extract && $Flap_Detection_Enabled_Extract ne 2) {
#				print FILE "	flap_detection_enabled		$Flap_Detection_Enabled_Extract\n";
#			}
#			if ($Process_Perf_Data_Extract && $Process_Perf_Data_Extract ne 2) {
#				print FILE "	process_perf_data		$Process_Perf_Data_Extract\n";
#			}
#			if ($Retain_Status_Information_Extract && $Retain_Status_Information_Extract ne 2) {
#				print FILE "	retain_status_information	$Retain_Status_Information_Extract\n";
#			}
#			if ($Retain_NonStatus_Information_Extract && $Retain_NonStatus_Information_Extract ne 2) {
#				print FILE "	retain_nonstatus_information	$Retain_NonStatus_Information_Extract\n";
#			}
#			if ($Is_Volatile_Extract && $Is_Volatile_Extract ne 2) {
#				print FILE "	is_volatile			$Is_Volatile_Extract\n";
#			}
#			if ($Check_Period_Extract) {
#				print FILE "	check_period			$Check_Period_Extract\n";
#			}
#			if ($Max_Check_Attempts_Extract) {
#				print FILE "	max_check_attempts		$Max_Check_Attempts_Extract\n";
#			}
#			if ($Normal_Check_Interval_Extract) {
#				print FILE "	normal_check_interval		$Normal_Check_Interval_Extract\n";
#			}
#			if ($Retry_Check_Interval_Extract) {
#				print FILE "	retry_check_interval		$Retry_Check_Interval_Extract\n";
#			}
#			if ($Contacts) {
#				print FILE "	contacts			$Contacts\n";
#			}
#			if ($Contact_Groups) {
#				print FILE "	contact_groups			$Contact_Groups\n";
#			}
#			if ($Notification_Options_Extract) {
#				print FILE "	notification_options		$Notification_Options_Extract\n";
#			}
#			if ($Notification_Interval_Extract) {
#				print FILE "	notification_interval		$Notification_Interval_Extract\n";
#			}
#			if ($Notification_Period_Extract) {
#				print FILE "	notification_period		$Notification_Period_Extract\n";
#			}
	
#			print FILE "	register			1\n";
			print FILE "}\n\n";
	}

} # sub write_services

sub write_commands {

	my $Icinga_Config_File = "$Config_Path/commands.conf";
	open( FILE, ">$Icinga_Config_File" ) or die "Can't open $Icinga_Config_File";

	my $Select_Command = $DB_Connection->prepare("SELECT `id`, `command_name`, `command_line`, `last_modified`, `modified_by`
	FROM `icinga2_command`
	WHERE `active` = '1'");

	$Select_Command->execute();
	my $Rows = $Select_Command->rows();

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED FILE\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "## Commands defined in file: $Rows\n";
	print FILE "########################################\n";
	print FILE "\n\n";

	while ( my @DB_Command = $Select_Command->fetchrow_array() )
	{

		my $Command_ID_Extract = $DB_Command[0];
		my $Command_Extract = $DB_Command[1];
		my $Command_Line_Extract = $DB_Command[2];
		my $Last_Modified_Extract = $DB_Command[3];
		my $Modified_By_Extract = $DB_Command[4];

		print FILE "## Command ID: $Command_ID_Extract\n";
		print FILE "## Modified $Last_Modified_Extract by $Modified_By_Extract\n";
		print FILE "object CheckCommand \"$Command_Extract\" {\n";
		print FILE "command = \[ SysconfDir \+ \"$Command_Line_Extract\"\]\n";
		print FILE "}\n\n";

	}

} # sub write_commands
