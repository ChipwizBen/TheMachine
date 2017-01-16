#!/usr/bin/perl -T

## This script is meant to transfer your data from an old DSMS installation to a new deployment of The Machine.
## It does not include the audit or access log, distribution status or lock status.
## It will overwrite any duplicate DSMS entries in your Machine installation (including entries with a matching ID), so make sure it's a new install.
## In case you missed it - OVERWRITE. Take a backup, man! If you have configured the DSMS component of TheMachine, you may want to manually merge changes instead.
## You must configure the DB configurations for both DSMS and The Machine in the subroutines DB_DSMS and DB_TheMachine below.
## Run this one only. ONCE ONLY.

use strict;
use DBI;
my $DB_DSMS = &DB_DSMS;
my $DB_TheMachine = &DB_TheMachine;
my %Host_Group_Conversion_Tracker;

sub DB_DSMS {
	# This is your database's connection information for DSMS.

	use DBI;

	my $Host = 'localhost';
	my $Port = '3306';
	my $DB = 'Sudoers';
	my $User = 'Sudoers';
	my $Password = '';

	my $DB_DSMS = DBI->connect ("DBI:mysql:database=$DB:host=$Host:port=$Port",
		$User,
		$Password,
		{mysql_enable_utf8 => 1})
		or die "Can't connect to database: $DBI::errstr\n";
	return $DB_DSMS;
} # sub DB_DSMS

sub DB_TheMachine {
	# This is your database's connection information for TheMachine.

	use DBI;

	my $Host = 'localhost';
	my $Port = '3306';
	my $DB = 'TheMachine';
	my $User = 'TheMachine';
	my $Password = '';

	my $DB_TheMachine = DBI->connect ("DBI:mysql:database=$DB:host=$Host:port=$Port",
		$User,
		$Password,
		{mysql_enable_utf8 => 1})
		or die "Can't connect to database: $DBI::errstr\n";
	return $DB_TheMachine;
} # sub DB_TheMachine

#&set_the_machine_flags(1);
&notes;
&rules;
	&lnk_rules_to_command_groups;
	&lnk_rules_to_host_groups;
	&lnk_rules_to_user_groups;
	&lnk_rules_to_commands;
	&lnk_rules_to_hosts;
	&lnk_rules_to_users;
&lnk_command_groups_to_commands;
	&command_groups;
	&commands;
&lnk_user_groups_to_users;
	&user_groups;
	&users;
&lnk_host_groups_to_hosts;
	&host_groups; # Special exception to the overwrite rule. Results are re-mapped.
	&hosts; # Special exception to the overwrite rule. Results are re-mapped.
#&set_the_machine_flags(0);

sub set_the_machine_flags {

	my $Flag = $_[0];

	my $Column;
	if ($Flag == 1) {
		$Column = 'ADD COLUMN `tm` INT(1) NOT NULL DEFAULT 1';
	}
	else {
		$Column = 'DROP COLUMN `tm`';
	}

	$DB_TheMachine->do("ALTER TABLE `TheMachine`.`lnk_hosts_groups_to_hosts` $Column;");
	$DB_TheMachine->do("ALTER TABLE `TheMachine`.`lnk_hosts_to_ipv4_allocations` $Column;");

} # sub set_the_machine_flags

sub notes {

	print "\n\n### Notes ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `type_id`, `item_id`, `note`, `last_modified`, `modified_by`
		FROM `notes`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Type = $Attribute_Select[1];
		my $Item = $Attribute_Select[2];
		my $Note = $Attribute_Select[3];
		my $Last_Modified = $Attribute_Select[4];
		my $Modified_By = $Attribute_Select[5];

		print "\nAdding ID: [$ID]
		\r\tType: [$Type]
		\r\tItem: [$Item]
		\r\t$Note: [$Note]
		\r\tLast Modified: [$Last_Modified]
		\r\tModified By: [$Modified_By]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `notes` (
			`type_id`,
			`item_id`,
			`note`,
			`last_modified`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, ?
		)");
	
		$Attribute_Insert->execute($Type, $Item, $Note, $Last_Modified, $Modified_By);
	}

} # sub notes

sub rules {

	print "\n\n### Rules ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT 
		`id`, `name`, `all_hosts`, `run_as`, `nopasswd`, `noexec`, `expires`, 
		`active`, `approved`, `last_approved`, `approved_by`, `last_modified`, `modified_by`
		FROM `rules`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Name = $Attribute_Select[1];
		my $All_Hosts = $Attribute_Select[2];
		my $Run_As = $Attribute_Select[3];
		my $NoPasswd = $Attribute_Select[4];
		my $NoExec = $Attribute_Select[5];
		my $Expires = $Attribute_Select[6];
		my $Active = $Attribute_Select[7];
		my $Approved = $Attribute_Select[8];
		my $Last_Approved = $Attribute_Select[9];
		my $Approved_By = $Attribute_Select[10];
		my $Last_Modified = $Attribute_Select[11];
		my $Modified_By = $Attribute_Select[12];

		print "\nAdding ID: [$ID]
		\r\tName: [$Name]
		\r\tAll Hosts: [$All_Hosts]
		\r\tRun As: [$Run_As]
		\r\tNoPasswd: [$NoPasswd]
		\r\tNoExec: [$NoExec]
		\r\tExpires: [$Expires]
		\r\tActive: [$Active]
		\r\tApproved: [$Approved]
		\r\tLast Approved: [$Last_Approved]
		\r\tLast Modified: [$Last_Modified]
		\r\tModified By: [$Modified_By]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `rules` (
			`id`,
			`name`,
			`all_hosts`,
			`run_as`,
			`nopasswd`,
			`noexec`,
			`expires`,
			`active`,
			`approved`,
			`last_approved`,
			`approved_by`,
			`last_modified`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
		)
		ON DUPLICATE KEY UPDATE
			`id` = ?,
			`name` = ?,
			`all_hosts` = ?,
			`run_as` = ?,
			`nopasswd` = ?,
			`noexec` = ?,
			`expires` = ?,
			`active` = ?,
			`approved` = ?,
			`last_approved` = ?,
			`approved_by` = ?,
			`last_modified` = ?,
			`modified_by` = ?
		");



		$Attribute_Insert->execute(
			$ID, $Name, $All_Hosts, $Run_As, $NoPasswd, $NoExec, $Expires, $Active, $Approved, $Last_Approved, $Approved_By, $Last_Modified, $Modified_By,
			$ID, $Name, $All_Hosts, $Run_As, $NoPasswd, $NoExec, $Expires, $Active, $Approved, $Last_Approved, $Approved_By, $Last_Modified, $Modified_By);

	}

} # sub rules

sub lnk_rules_to_command_groups {

	print "\n\n### Link Rules to Command Groups ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `rule`, `command_group`
		FROM `lnk_rules_to_command_groups`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Rule = $Attribute_Select[1];
		my $Command_Group = $Attribute_Select[2];

		print "\nAdding ID: [$ID]
		\r\tRule: [$Rule]
		\r\tCommand Group: [$Command_Group]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `lnk_rules_to_command_groups` (
			`id`,
			`rule`,
			`command_group`
		)
		VALUES (
			?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `rule` = ?, `command_group` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Rule, $Command_Group,
			$ID, $Rule, $Command_Group);
	}

} # sub lnk_rules_to_command_groups

sub lnk_rules_to_host_groups {

	print "\n\n### Link Rules to Host Groups ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `rule`, `host_group`
		FROM `lnk_rules_to_host_groups`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Rule = $Attribute_Select[1];
		my $Host_Group = $Attribute_Select[2];

		print "\nAdding ID: [$ID]
		\r\tRule: [$Rule]
		\r\tHost Group: [$Host_Group]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `lnk_rules_to_host_groups` (
			`id`,
			`rule`,
			`host_group`
		)
		VALUES (
			?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `rule` = ?, `host_group` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Rule, $Host_Group,
			$ID, $Rule, $Host_Group);
	}

} # sub lnk_rules_to_host_groups

sub lnk_rules_to_user_groups {

	print "\n\n### Link Rules to User Groups ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `rule`, `user_group`
		FROM `lnk_rules_to_user_groups`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Rule = $Attribute_Select[1];
		my $User_Group = $Attribute_Select[2];

		print "\nAdding ID: [$ID]
		\r\tRule: [$Rule]
		\r\tUser Group: [$User_Group]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `lnk_rules_to_user_groups` (
			`id`,
			`rule`,
			`user_group`
		)
		VALUES (
			?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `rule` = ?, `user_group` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Rule, $User_Group,
			$ID, $Rule, $User_Group);
	}

} # sub lnk_rules_to_user_groups

sub lnk_rules_to_commands {

	print "\n\n### Link Rules to Commands ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `rule`, `command`
		FROM `lnk_rules_to_commands`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Rule = $Attribute_Select[1];
		my $Command = $Attribute_Select[2];

		print "\nAdding ID: [$ID]
		\r\tRule: [$Rule]
		\r\tCommand: [$Command]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `lnk_rules_to_commands` (
			`id`,
			`rule`,
			`command`
		)
		VALUES (
			?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `rule` = ?, `command` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Rule, $Command,
			$ID, $Rule, $Command);
	}

} # sub lnk_rules_to_commands

sub lnk_rules_to_hosts {

	print "\n\n### Link Rules to Hosts ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `rule`, `host`
		FROM `lnk_rules_to_hosts`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Rule = $Attribute_Select[1];
		my $Host = $Attribute_Select[2];

		print "\nAdding ID: [$ID]
		\r\tRule: [$Rule]
		\r\tHost: [$Host]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `lnk_rules_to_hosts` (
			`id`,
			`rule`,
			`host`
		)
		VALUES (
			?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `rule` = ?, `host` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Rule, $Host,
			$ID, $Rule, $Host);
	}

} # sub lnk_rules_to_hosts

sub lnk_rules_to_users {

	print "\n\n### Link Rules to Users ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `rule`, `user`
		FROM `lnk_rules_to_users`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Rule = $Attribute_Select[1];
		my $User = $Attribute_Select[2];

		print "\nAdding ID: [$ID]
		\r\tRule: [$Rule]
		\r\tUser: [$User]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `lnk_rules_to_users` (
			`id`,
			`rule`,
			`user`
		)
		VALUES (
			?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `rule` = ?, `user` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Rule, $User,
			$ID, $Rule, $User);
	}

} # sub lnk_rules_to_users

sub lnk_command_groups_to_commands {

	print "\n\n### Link Command Groups to Commands ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `group`, `command`
		FROM `lnk_command_groups_to_commands`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Group = $Attribute_Select[1];
		my $Command = $Attribute_Select[2];

		print "\nAdding ID: [$ID]
		\r\tGroup: [$Group]
		\r\tCommand: [$Command]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `lnk_command_groups_to_commands` (
			`id`,
			`group`,
			`command`
		)
		VALUES (
			?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `group` = ?, `command` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Group, $Command,
			$ID, $Group, $Command);
	}

} # sub lnk_command_groups_to_commands

sub command_groups {

	print "\n\n### Command Groups ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `groupname`, `expires`, `active`, `last_modified`, `modified_by`
		FROM `command_groups`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Group = $Attribute_Select[1];
		my $Expires = $Attribute_Select[2];
		my $Active = $Attribute_Select[3];
		my $Last_Modified = $Attribute_Select[4];
		my $Modified_By = $Attribute_Select[5];

		print "\nAdding ID: [$ID]
		\r\tGroup: [$Group]
		\r\tExpires: [$Expires]
		\r\tActive: [$Active]
		\r\tLast Modified: [$Last_Modified]
		\r\tModified By: [$Modified_By]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `command_groups` (
			`id`,
			`groupname`,
			`expires`,
			`active`,
			`last_modified`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `groupname` = ?, `expires` = ?, `active` = ?, `last_modified` = ?, `modified_by` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Group, $Expires, $Active, $Last_Modified, $Modified_By,
			$ID, $Group, $Expires, $Active, $Last_Modified, $Modified_By);
	}
} # sub command_groups

sub commands {

	print "\n\n### Commands ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `command_alias`, `command`, `expires`, `active`, `last_modified`, `modified_by`
		FROM `commands`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Command_Alias = $Attribute_Select[1];
		my $Command = $Attribute_Select[2];
		my $Expires = $Attribute_Select[3];
		my $Active = $Attribute_Select[4];
		my $Last_Modified = $Attribute_Select[5];
		my $Modified_By = $Attribute_Select[6];

		print "\nAdding ID: [$ID]
		\r\tCommand Alias: [$Command_Alias]
		\r\tCommand: [$Command]
		\r\tExpires: [$Expires]
		\r\tActive: [$Active]
		\r\tLast Modified: [$Last_Modified]
		\r\tModified By: [$Modified_By]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `commands` (
			`id`,
			`command_alias`,
			`command`,
			`expires`,
			`active`,
			`last_modified`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, ?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `command_alias` = ?, `command` = ?, `expires` = ?, `active` = ?, `last_modified` = ?, `modified_by` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Command_Alias, $Command, $Expires, $Active, $Last_Modified, $Modified_By,
			$ID, $Command_Alias, $Command, $Expires, $Active, $Last_Modified, $Modified_By);
	}
} # sub commands

sub lnk_user_groups_to_users {

	print "\n\n### Link User Groups to Users ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `group`, `user`
		FROM `lnk_user_groups_to_users`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Group = $Attribute_Select[1];
		my $User = $Attribute_Select[2];

		print "\nAdding ID: [$ID]
		\r\tGroup: [$Group]
		\r\tUser: [$User]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `lnk_user_groups_to_users` (
			`id`,
			`group`,
			`user`
		)
		VALUES (
			?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `group` = ?, `user` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Group, $User,
			$ID, $Group, $User);
	}

} # sub lnk_user_groups_to_users

sub user_groups {

	print "\n\n### User Groups ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `groupname`, `system_group`, `expires`, `active`, `last_modified`, `modified_by`
		FROM `user_groups`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Group = $Attribute_Select[1];
		my $System_Group = $Attribute_Select[2];
		my $Expires = $Attribute_Select[3];
		my $Active = $Attribute_Select[4];
		my $Last_Modified = $Attribute_Select[5];
		my $Modified_By = $Attribute_Select[6];

		print "\nAdding ID: [$ID]
		\r\tGroup: [$Group]
		\r\tSystem Group: [$System_Group]
		\r\tExpires: [$Expires]
		\r\tActive: [$Active]
		\r\tLast Modified: [$Last_Modified]
		\r\tModified By [$Modified_By]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `user_groups` (
			`id`,
			`groupname`,
			`system_group`,
			`expires`,
			`active`,
			`last_modified`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, ?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `groupname` = ?, `system_group` = ?, `expires` = ?, `active` = ?, `last_modified` = ?, `modified_by` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Group, $System_Group, $Expires, $Active, $Last_Modified, $Modified_By,
			$ID, $Group, $System_Group, $Expires, $Active, $Last_Modified, $Modified_By);
	}
} # sub user_groups

sub users {

	print "\n\n### Users ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `username`, `expires`, `active`, `last_modified`, `modified_by`
		FROM `users`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $User = $Attribute_Select[1];
		my $Expires = $Attribute_Select[2];
		my $Active = $Attribute_Select[3];
		my $Last_Modified = $Attribute_Select[4];
		my $Modified_By = $Attribute_Select[5];

		print "\nAdding ID: [$ID]
		\r\tUser: [$User]
		\r\tExpires: [$Expires]
		\r\tActive: [$Active]
		\r\tLast Modified: [$Last_Modified]
		\r\tModified By: [$Modified_By]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `users` (
			`id`,
			`username`,
			`expires`,
			`active`,
			`last_modified`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `username` = ?, `expires` = ?, `active` = ?, `last_modified` = ?, `modified_by` = ?");
	
		$Attribute_Insert->execute(
			$ID, $User, $Expires, $Active, $Last_Modified, $Modified_By,
			$ID, $User, $Expires, $Active, $Last_Modified, $Modified_By);
	}
} # sub users

sub lnk_host_groups_to_hosts {

	print "\n\n### Link Host Groups to Hosts ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `group`, `host`
		FROM `lnk_host_groups_to_hosts`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Group = $Attribute_Select[1];
		my $Host = $Attribute_Select[2];

		print "\nAdding ID: [$ID]
		\r\tGroup: [$Group]
		\r\tHost: [$Host]\n";

		my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `lnk_host_groups_to_hosts` (
			`id`,
			`group`,
			`host`
		)
		VALUES (
			?, ?, ?
		)
		ON DUPLICATE KEY UPDATE `id` = ?, `group` = ?, `host` = ?");
	
		$Attribute_Insert->execute(
			$ID, $Group, $Host,
			$ID, $Group, $Host);
	}

} # sub lnk_host_groups_to_hosts

sub host_groups {

	print "\n\n### Host Groups ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `groupname`, `expires`, `active`, `last_modified`, `modified_by`
		FROM `host_groups`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Host_Group = $Attribute_Select[1];
		my $Expires = $Attribute_Select[2];
		my $Active = $Attribute_Select[3];
		my $Last_Modified = $Attribute_Select[4];
		my $Modified_By = $Attribute_Select[5];

		my $Machine_Attribute_Select = $DB_TheMachine->prepare("SELECT `id`, `groupname`, `expires`, `active`, `last_modified`, `modified_by`
			FROM `host_groups`
			WHERE `groupname` = '$Host_Group'
			OR `id` = '$ID'
		");
		
		$Machine_Attribute_Select->execute();
		my $Total_Rows = $Machine_Attribute_Select->rows();
	
		while ( my @Machine_Attribute_Select = $Machine_Attribute_Select->fetchrow_array() ) {
	
			my $Machine_ID = $Machine_Attribute_Select[0];
			my $Machine_Host_Group = $Machine_Attribute_Select[1];
			my $Machine_Expires = $Machine_Attribute_Select[2];
			my $Machine_Active = $Machine_Attribute_Select[3];
			my $Machine_Last_Modified = $Machine_Attribute_Select[4];
			my $Machine_Modified_By = $Machine_Attribute_Select[5];


			if ($ID eq $Machine_ID && $Host_Group eq $Machine_Host_Group) {
				print "\n\nHmmm, $Host_Group [$ID] and $Machine_Host_Group [$Machine_ID] appear to be the same. I'll leave this one.\n\n";
			}
			elsif ($ID ne $Machine_ID && $Host_Group eq $Machine_Host_Group) {
				print "\nDuplicate Host Group Found!: [$ID] - [$Machine_ID]
				\r\tHost Group: [$Host_Group] - [$Machine_Host_Group]
				\r\tExpires: [$Expires] - [$Machine_Expires]
				\r\tActive: [$Active] - [$Machine_Active]
				\r\tLast Modified: [$Last_Modified] - [$Machine_Last_Modified]
				\r\tModified By: [$Modified_By] - [$Machine_Modified_By]\n";
				&update_host_group_ids($ID, $Machine_ID, $Host_Group);
				&flush_old_id($ID, $Host_Group);
			}
			elsif ($ID eq $Machine_ID && $Host_Group ne $Machine_Host_Group) {
				print "\nDuplicate ID Found!: [$ID] - [$Machine_ID]
				\r\tHost Group: [$Host_Group] - [$Machine_Host_Group]
				\r\tExpires: [$Expires] - [$Machine_Expires]
				\r\tActive: [$Active] - [$Machine_Active]
				\r\tLast Modified: [$Last_Modified] - [$Machine_Last_Modified]
				\r\tModified By: [$Modified_By] - [$Machine_Modified_By]\n";

				my $Machine_ID_Select = $DB_TheMachine->prepare("SELECT `id`
				FROM `host_groups`
				WHERE `groupname` = '$Host_Group'
				");

				$Machine_ID_Select->execute();
				my $Host_Group_ID = $Machine_ID_Select->fetchrow_array();

				if ($Host_Group_ID) {
					print "\nAdding Host: [$Host_Group]
					\r\tExpires: [$Expires]
					\r\tActive: [$Active]
					\r\tLast Modified: [$Last_Modified]
					\r\tModified By: [$Modified_By]\n";
					&update_host_group_ids($ID, $Host_Group_ID, $Host_Group);
				}
				else {
					print "\nAdding Host Group: [$Host_Group]
					\r\tExpires: [$Expires]
					\r\tActive: [$Active]
					\r\tLast Modified: [$Last_Modified]
					\r\tModified By: [$Modified_By]\n";

					my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `host_groups` (
						`groupname`,
						`expires`,
						`active`,
						`last_modified`,
						`modified_by`
					)
					VALUES (
						?, ?, ?, ?, ?
					)");

					$Attribute_Insert->execute($Host_Group, $Expires, $Active, $Last_Modified, $Modified_By);
					my $Machine_New_ID = $DB_TheMachine->{mysql_insertid};
					print "\tID: [$Machine_New_ID]\n";
					&update_host_group_ids($ID, $Machine_New_ID, $Host_Group);
					#&flush_old_id($ID, $Host_Group);
				}
			}
			else {
				print "\n\nI dunno boss, somethin' went wrong!\n\n";
			}
		}

		if (!$Total_Rows) {

			print "\nAdding ID: [$ID]
			\r\tHost Group: [$Host_Group]
			\r\tExpires: [$Expires]
			\r\tActive: [$Active]
			\r\tLast Modified: [$Last_Modified]
			\r\tModified By: [$Modified_By]\n";

			my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `host_groups` (
				`id`,
				`groupname`,
				`expires`,
				`active`,
				`last_modified`,
				`modified_by`
			)
			VALUES (
				?, ?, ?, ?, ?, ?
			)");
			$Attribute_Insert->execute($ID, $Host_Group, $Expires, $Active, $Last_Modified, $Modified_By);

		}
	}
} # sub host_groups

sub hosts {

	print "\n\n### Hosts ###\n\n";

	my $Attribute_Select = $DB_DSMS->prepare("SELECT `id`, `hostname`, `ip`, `expires`, `active`, `last_modified`, `modified_by`
		FROM `hosts`
	");

	$Attribute_Select->execute();

	while ( my @Attribute_Select = $Attribute_Select->fetchrow_array() ) {

		my $ID = $Attribute_Select[0];
		my $Host = $Attribute_Select[1];
		my $IP = $Attribute_Select[2];
		my $Expires = $Attribute_Select[3];
		my $Active = $Attribute_Select[4];
		my $Last_Modified = $Attribute_Select[5];
		my $Modified_By = $Attribute_Select[6];

		my $Machine_Attribute_Select = $DB_TheMachine->prepare("SELECT `id`, `hostname`, `expires`, `active`, `last_modified`, `modified_by`
			FROM `hosts`
			WHERE `hostname` = '$Host'
			OR `id` = '$ID'
		");
		
		$Machine_Attribute_Select->execute();
		my $Total_Rows = $Machine_Attribute_Select->rows();
	
		while ( my @Machine_Attribute_Select = $Machine_Attribute_Select->fetchrow_array() ) {
	
			my $Machine_ID = $Machine_Attribute_Select[0];
			my $Machine_Host = $Machine_Attribute_Select[1];
			my $Machine_Expires = $Machine_Attribute_Select[2];
			my $Machine_Active = $Machine_Attribute_Select[3];
			my $Machine_Last_Modified = $Machine_Attribute_Select[4];
			my $Machine_Modified_By = $Machine_Attribute_Select[5];


			if ($ID eq $Machine_ID && $Host eq $Machine_Host) {
				print "\n\nHmmm, $Host [$ID] and $Machine_Host [$Machine_ID] appear to be the same. I'll leave this one.\n\n";
			}
			elsif ($ID ne $Machine_ID && $Host eq $Machine_Host) {
				print "\nDuplicate Hostname Found!: [$ID] - [$Machine_ID]
				\r\tHost: [$Host] - [$Machine_Host]
				\r\tExpires: [$Expires] - [$Machine_Expires]
				\r\tActive: [$Active] - [$Machine_Active]
				\r\tLast Modified: [$Last_Modified] - [$Machine_Last_Modified]
				\r\tModified By: [$Modified_By] - [$Machine_Modified_By]\n";
				&spin_host_group($ID);
				&update_host_ids($ID, $Machine_ID, $Host, $IP);
				&flush_old_id($ID, $Host);
			}
			elsif ($ID eq $Machine_ID && $Host ne $Machine_Host) {
				print "\nDuplicate ID Found!: [$ID] - [$Machine_ID]
				\r\tHost: [$Host] - [$Machine_Host]
				\r\tExpires: [$Expires] - [$Machine_Expires]
				\r\tActive: [$Active] - [$Machine_Active]
				\r\tLast Modified: [$Last_Modified] - [$Machine_Last_Modified]
				\r\tModified By: [$Modified_By] - [$Machine_Modified_By]\n";

				my $Machine_ID_Select = $DB_TheMachine->prepare("SELECT `id`
				FROM `hosts`
				WHERE `hostname` = '$Host'
				");

				$Machine_ID_Select->execute();
				my $Host_ID = $Machine_ID_Select->fetchrow_array();

				if ($Host_ID) {
					print "\nAdding Host: [$Host]
					\r\tExpires: [$Expires]
					\r\tActive: [$Active]
					\r\tLast Modified: [$Last_Modified]
					\r\tModified By: [$Modified_By]\n";
					&spin_host_group($ID);
					&update_host_ids($ID, $Host_ID, $Host, $IP);
					#&flush_old_id($ID, $Host);
				}
				else {
					print "\nAdding Host: [$Host]
					\r\tExpires: [$Expires]
					\r\tActive: [$Active]
					\r\tLast Modified: [$Last_Modified]
					\r\tModified By: [$Modified_By]\n";

					my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `hosts` (
						`hostname`,
						`expires`,
						`active`,
						`last_modified`,
						`modified_by`
					)
					VALUES (
						?, ?, ?, ?, ?
					)");

					$Attribute_Insert->execute($Host, $Expires, $Active, $Last_Modified, $Modified_By);
					my $Machine_New_ID = $DB_TheMachine->{mysql_insertid};
					print "\tID: [$Machine_New_ID]\n";
					&spin_host_group($ID);
					&update_host_ids($ID, $Machine_New_ID, $Host, $IP);
				}
			}
			else {
				print "\n\nI dunno boss, somethin' went wrong!\n\n";
			}
		}

		if (!$Total_Rows) {

			print "\nAdding ID: [$ID]
			\r\tHost: [$Host]
			\r\tExpires: [$Expires]
			\r\tActive: [$Active]
			\r\tLast Modified: [$Last_Modified]
			\r\tModified By: [$Modified_By]\n";

			my $Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `hosts` (
				`id`,
				`hostname`,
				`expires`,
				`active`,
				`last_modified`,
				`modified_by`
			)
			VALUES (
				?, ?, ?, ?, ?, ?
			)");
			
			$Attribute_Insert->execute($ID, $Host, $Expires, $Active, $Last_Modified, $Modified_By);
			my $Host_Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `host_attributes` (
				`host_id`,
				`dhcp`,
				`dsms`
			)
			VALUES (
				?, ?, ?
			)
			ON DUPLICATE KEY UPDATE `dhcp` = ?, `dsms` = ?");
			
			if ($IP eq 'DHCP') {
				$Host_Attribute_Insert->execute($ID, '1', '1', '1', '1');
			}
			else {
				$Host_Attribute_Insert->execute($ID, '0', '1', '0', '1');
			}

		}
	}
} # sub hosts

sub update_host_ids {

	my $Old_ID = $_[0];
	my $Machine_ID = $_[1];
	my $Hostname = $_[2];
	my $IP = $_[3];

	print "\nSwapping out host ID $Old_ID with $Machine_ID.\n";

	my $Update_Host_Groups_to_Hosts = $DB_TheMachine->prepare("UPDATE `lnk_host_groups_to_hosts` SET
		`host` = ?
		WHERE `host` = ?");
	$Update_Host_Groups_to_Hosts->execute($Machine_ID, $Old_ID);

	my $Update_Rules_to_Hosts = $DB_TheMachine->prepare("UPDATE `lnk_rules_to_hosts` SET
		`host` = ?
		WHERE `host` = ?");
	$Update_Rules_to_Hosts->execute($Machine_ID, $Old_ID);

	my $Update_Notes = $DB_TheMachine->prepare("UPDATE `notes` SET
		`item_id` = ?
		WHERE `item_id` = ?
		AND `type_id` = '1'");
	$Update_Notes->execute($Machine_ID, $Old_ID);

	my $Host_Attribute_Insert = $DB_TheMachine->prepare("INSERT INTO `host_attributes` (
		`host_id`,
		`dhcp`,
		`dsms`
	)
	VALUES (
		?, ?, ?
	)
	ON DUPLICATE KEY UPDATE `dhcp` = ?, `dsms` = ?");

	if ($IP eq 'DHCP') {
		$Host_Attribute_Insert->execute($Machine_ID, '1', '1', '1', '1');
	}
	else {
		$Host_Attribute_Insert->execute($Machine_ID, '0', '1', '0', '1');
	}

} # sub update_host_ids

sub update_host_group_ids {

	my $Old_ID = $_[0];
	my $Machine_ID = $_[1];
	my $Host_Group = $_[2];

	print "\nSwapping out Host Group $Host_Group ID $Old_ID with $Machine_ID.\n";

	$Host_Group_Conversion_Tracker{$Old_ID} = $Machine_ID;

	my $Update_Rules_to_Hosts = $DB_TheMachine->prepare("UPDATE `lnk_rules_to_host_groups` SET
		`host_group` = ?
		WHERE `host_group` = ?");
	$Update_Rules_to_Hosts->execute($Machine_ID, $Old_ID);

	my $Update_Notes = $DB_TheMachine->prepare("UPDATE `notes` SET
		`item_id` = ?
		WHERE `item_id` = ?
		AND `type_id` = '2'");
	$Update_Notes->execute($Machine_ID, $Old_ID);

} # sub update_host_group_ids

sub spin_host_group {

	my $Old_ID = $_[0];

	my $Group_Spin = $DB_TheMachine->prepare("SELECT `group`
	FROM `lnk_host_groups_to_hosts`
	WHERE `host` = ?");
	$Group_Spin->execute($Old_ID);

	while ( my $Old_Group_ID = $Group_Spin->fetchrow_array() )
	{
		my $New_Group_ID = $Host_Group_Conversion_Tracker{$Old_Group_ID};
		print "\nSpinning Host Group ID $Old_Group_ID with $New_Group_ID for Host ID $Old_ID.\n";
		my $Update_Hosts_Hosts_Group = $DB_TheMachine->prepare("UPDATE `lnk_host_groups_to_hosts` SET
			`group` = ?
			WHERE `host` = ?
			AND `group` = ?");
		$Update_Hosts_Hosts_Group->execute($New_Group_ID, $Old_ID, $Old_Group_ID);
	}

} # sub spin_host_group

sub flush_old_id {

	my $Old_ID = $_[0];
	my $Hostname = $_[1];
	print "Flushing $Hostname [$Old_ID].\n";

	my $Delete_Old_Host = $DB_DSMS->prepare("DELETE FROM `hosts`
		WHERE `id` = ?
		AND `hostname` = ?");
	$Delete_Old_Host->execute($Old_ID, $Hostname);

}