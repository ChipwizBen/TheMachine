#!/usr/bin/perl

use strict;
use POSIX qw(strftime);

require '../common.pl';
my $DB_Management = DB_Management();
my $DB_Sudoers = DB_Sudoers();
my $Sudoers_Location = Sudoers_Location();
my $Sudoers_Storage = Sudoers_Storage();
my $System_Name = System_Name();
my $Version = Version();
my $md5sum = md5sum();
my $cut = cut();
my $visudo = visudo();
my $cp = cp();
my $ls = ls();
my $grep = sudo_grep();
my $head = head();
my $Owner = Owner_ID();
my $Group = Group_ID();

my $Date = strftime "%Y-%m-%d", localtime;

# Safety check for other running build processes

	my $Select_Locks = $DB_Management->prepare("SELECT `sudoers-build` FROM `lock`");
	$Select_Locks->execute();

	my ($Sudoers_Build_Lock, $Sudoers_Distribution_Lock) = $Select_Locks->fetchrow_array();

		if ($Sudoers_Build_Lock == 1 || $Sudoers_Distribution_Lock == 1) {
			print "Another build or distribution process is running. Exiting...\n";
			exit(1);
		}
		else {
			$DB_Management->do("UPDATE `lock` SET
				`sudoers-build` = '1',
				`last-sudoers-build-started` = NOW()");
		}

# / Safety check for other running build processes

# Safety check for unapproved Rules

	my $Select_Rules = $DB_Sudoers->prepare("SELECT `id`
		FROM `rules`
		WHERE `active` = '1'
		AND `approved` = '0'"
	);

	$Select_Rules->execute();
	my $Rows = $Select_Rules->rows();

	if ($Rows > 0) {
		$DB_Management->do("UPDATE `lock` SET 
		`sudoers-build` = '3',
		`last-sudoers-build-finished` = NOW()");
		print "You have Rules pending approval. Please either approve or delete unapproved Rules before continuing. Exiting...\n";
		exit(1);
	}

# / Safety check for unapproved Rules

&write_environmentals;
&write_host_groups;
&write_user_groups;
&write_command_groups;
&write_commands;
&write_rules;

my $Sudoers_Check = `$visudo -c -f $Sudoers_Location`;

if ($Sudoers_Check =~ m/$Sudoers_Location:\sparsed\sOK/) {
	$Sudoers_Check = "Sudoers check passed!\n";
	$DB_Management->do("UPDATE `lock` SET 
	`sudoers-build` = '0',
	`last-sudoers-build-finished` = NOW()");
	&record_audit('PASSED');
	print $Sudoers_Check;
	exit(0);
}
else {
	$Sudoers_Check = "Sudoers check failed, no changes made. Latest working sudoers file restored.\n";
	$DB_Management->do("UPDATE `lock` SET 
	`sudoers-build` = '2',
	`last-sudoers-build-finished` = NOW()");
	&record_audit('FAILED');
	print $Sudoers_Check;
	exit(1);
}

sub write_environmentals {

	open( FILE, ">$Sudoers_Location" ) or die "Can't open $Sudoers_Location";

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED SCRIPT\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "#########################################################################\n";
	print FILE "\n\n";


	print FILE "### Environmental Defaults Section Begins ###\n\n";

	open( ENVIRONMENTALS, "environmental-defaults" ) or die "Can't open environmental-defaults file.";

	LINE: foreach my $Line (<ENVIRONMENTALS>) {

		if ($Line =~ /^###/) {next LINE};
		print FILE "$Line";

	}

	print FILE "\n### Environmental Defaults Section Ends ###\n";

	close ENVIRONMENTALS;

	print FILE "\n";
	close FILE;

} # write_environmentals

sub write_host_groups {

	open( FILE, ">>$Sudoers_Location" ) or die "Can't open $Sudoers_Location";

	print FILE "\n### Host Group Section Begins ###\n\n";

	my $Select_Groups = $DB_Sudoers->prepare("SELECT `id`, `groupname`, `expires`, `last_modified`, `modified_by`
		FROM `host_groups`
		WHERE `active` = '1'
		AND (`expires` >= '$Date'
			OR `expires` = '0000-00-00')
		ORDER BY `groupname` ASC"
	);
	$Select_Groups->execute();

	while ( my @Select_Groups = $Select_Groups->fetchrow_array() )
	{

		my $DBID = $Select_Groups[0];
		my $Host_Group_Name = $Select_Groups[1];
		my $Expires = $Select_Groups[2];
		my $Last_Modified = $Select_Groups[3];
		my $Modified_By = $Select_Groups[4];

			if ($Expires eq '0000-00-00') {
				$Expires = 'does not expire';
			}
			else {
				$Expires = "expires on " . $Expires;
			}

		print FILE "## $Host_Group_Name (ID: $DBID), $Expires, last modified $Last_Modified by $Modified_By\n";

		my $Hosts;
		my $Select_Links = $DB_Sudoers->prepare("SELECT `host`
			FROM `lnk_host_groups_to_hosts`
			WHERE `group` = ?"
		);
		$Select_Links->execute($DBID);

		while ( my @Select_Links = $Select_Links->fetchrow_array() )
		{
			
			my $Host_ID = $Select_Links[0];

			my $Select_Hosts = $DB_Sudoers->prepare("SELECT `hostname`, `ip`
				FROM `hosts`
				WHERE `id` = ?
				AND `active` = '1'
				AND (`expires` >= '$Date'
					OR `expires` = '0000-00-00')"
			);
			$Select_Hosts->execute($Host_ID);

			while ( my @Select_Hosts = $Select_Hosts->fetchrow_array() )
			{

				my $Host = $Select_Hosts[0];
				my $IP = $Select_Hosts[1];

				if ($IP eq 'DHCP') {
					$Hosts = $Hosts . "$Host, ";
				}
				else {
					$Hosts = $Hosts . "$Host, $IP, ";
				}

			}
		}

		$Host_Group_Name = uc($Host_Group_Name); # Turn to uppercase so that sudo can read it correctly
		$Hosts =~ s/,\s$//; # Remove trailing comma
		if ($Hosts) {
			print FILE "Host_Alias	HOST_GROUP_$Host_Group_Name = $Hosts\n\n";
		}
		else {
			print FILE "#######\n";
			print FILE "####### $Host_Group_Name (ID: $DBID) was not included because it does not have any attached Hosts. #######\n";
			print FILE "#######\n\n";
		}
	}

print FILE "### Host Group Section Ends ###\n\n";

close FILE;

} #sub write_host_groups

sub write_user_groups {

	open( FILE, ">>$Sudoers_Location" ) or die "Can't open $Sudoers_Location";

	print FILE "\n### User Group Section Begins ###\n\n";

	my $Select_Groups = $DB_Sudoers->prepare("SELECT `id`, `groupname`, `system_group`, `expires`, `last_modified`, `modified_by`
		FROM `user_groups`
		WHERE `active` = '1'
		AND (`expires` >= '$Date'
			OR `expires` = '0000-00-00')
		ORDER BY `groupname` ASC"
	);
	$Select_Groups->execute();

	while ( my @Select_Groups = $Select_Groups->fetchrow_array() )
	{

		my $DBID = $Select_Groups[0];
		my $User_Group_Name = $Select_Groups[1];
		my $System_Group = $Select_Groups[2];
		my $Expires = $Select_Groups[3];
		my $Last_Modified = $Select_Groups[4];
		my $Modified_By = $Select_Groups[5];

		if ($Expires eq '0000-00-00') {
			$Expires = 'does not expire';
		}
		else {
			$Expires = "expires on " . $Expires;
		}

		print FILE "## $User_Group_Name (ID: $DBID), $Expires, last modified $Last_Modified by $Modified_By\n";

		my $Users;
		my $Select_Links = $DB_Sudoers->prepare("SELECT `user`
			FROM `lnk_user_groups_to_users`
			WHERE `group` = ?"
		);
		$Select_Links->execute($DBID);

		while ( my @Select_Links = $Select_Links->fetchrow_array() )
		{
			
			my $User_ID = $Select_Links[0];

			my $Select_Users = $DB_Sudoers->prepare("SELECT `username`
				FROM `users`
				WHERE `id` = ?
				AND `active` = '1'
				AND (`expires` >= '$Date'
					OR `expires` = '0000-00-00')"
			);
			$Select_Users->execute($User_ID);

			while ( my @Select_Users = $Select_Users->fetchrow_array() )
			{

				my $User = $Select_Users[0];

				$Users = $Users . "$User, ";

			}
		}

		if ($System_Group) {$Users = "%" . $User_Group_Name}

		$User_Group_Name = uc($User_Group_Name); # Turn to uppercase so that sudo can read it correctly
		$User_Group_Name =~ s/[^A-Z0-9]/_/g;
		$Users =~ s/,\s$//; # Remove trailing comma
		if ($Users) {
			print FILE "User_Alias	USER_GROUP_$User_Group_Name = $Users\n\n";
		}
		else {
			print FILE "#######\n";
			print FILE "####### $User_Group_Name (ID: $DBID) was not included because it does not have any attached Users. #######\n";
			print FILE "#######\n\n";
		}
	}

print FILE "### User Group Section Ends ###\n\n";
close FILE;

} #sub write_user_groups

sub write_command_groups {

	open( FILE, ">>$Sudoers_Location" ) or die "Can't open $Sudoers_Location";

	print FILE "\n### Command Group Section Begins ###\n\n";

	my $Select_Groups = $DB_Sudoers->prepare("SELECT `id`, `groupname`, `expires`, `last_modified`, `modified_by`
		FROM `command_groups`
		WHERE `active` = '1'
		AND (`expires` >= '$Date'
			OR `expires` = '0000-00-00')
		ORDER BY `groupname` ASC"
	);
	$Select_Groups->execute();

	while ( my @Select_Groups = $Select_Groups->fetchrow_array() )
	{

		my $DBID = $Select_Groups[0];
		my $Command_Group_Name = $Select_Groups[1];
		my $Expires = $Select_Groups[2];
		my $Last_Modified = $Select_Groups[3];
		my $Modified_By = $Select_Groups[4];

		if ($Expires eq '0000-00-00') {
			$Expires = 'does not expire';
		}
		else {
			$Expires = "expires on " . $Expires;
		}

		print FILE "## $Command_Group_Name (ID: $DBID), $Expires, last modified $Last_Modified by $Modified_By\n";

		my $Commands;
		my $Select_Links = $DB_Sudoers->prepare("SELECT `command`
			FROM `lnk_command_groups_to_commands`
			WHERE `group` = ?"
		);
		$Select_Links->execute($DBID);

		while ( my @Select_Links = $Select_Links->fetchrow_array() )
		{
			
			my $Command_ID = $Select_Links[0];

			my $Select_Commands = $DB_Sudoers->prepare("SELECT `command_alias`
				FROM `commands`
				WHERE `id` = ?
				AND `active` = '1'
				AND (`expires` >= '$Date'
					OR `expires` = '0000-00-00')"
			);
			$Select_Commands->execute($Command_ID);

			while ( my @Select_Commands = $Select_Commands->fetchrow_array() )
			{

				my $Command_Alias = $Select_Commands[0];

				$Commands = $Commands . "COMMAND_$Command_Alias, ";

			}
		}

		$Command_Group_Name = uc($Command_Group_Name); # Turn to uppercase so that sudo can read it correctly
		$Commands = uc($Commands); # Turn to uppercase so that sudo can read it correctly
		$Commands =~ s/,\s$//; # Remove trailing comma
		if ($Commands) {
			print FILE "Cmnd_Alias	COMMAND_GROUP_$Command_Group_Name = $Commands\n\n";
		}
		else {
			print FILE "#######\n";
			print FILE "####### $Command_Group_Name (ID: $DBID) was not included because it does not have any attached Commands. #######\n";
			print FILE "#######\n\n";
		}
	}

print FILE "### Command Group Section Ends ###\n\n";
close FILE;

} #sub write_command_groups

sub write_commands {

	open( FILE, ">>$Sudoers_Location" ) or die "Can't open $Sudoers_Location";

	print FILE "\n### Command Section Begins ###\n\n";

	my $Select_Commands = $DB_Sudoers->prepare("SELECT `id`, `command_alias`, `command`, `expires`, `last_modified`, `modified_by`
		FROM `commands`
		WHERE `active` = '1'
		AND (`expires` >= '$Date'
			OR `expires` = '0000-00-00')
		ORDER BY `command_alias` ASC"
	);
	$Select_Commands->execute();

	while ( my @Select_Commands = $Select_Commands->fetchrow_array() )
	{

		my $DBID = $Select_Commands[0];
		my $Command_Alias = $Select_Commands[1];
		my $Command = $Select_Commands[2];
		my $Expires = $Select_Commands[3];
		my $Last_Modified = $Select_Commands[4];
		my $Modified_By = $Select_Commands[5];

		if ($Expires eq '0000-00-00') {
			$Expires = 'does not expire';
		}
		else {
			$Expires = "expires on " . $Expires;
		}

		print FILE "## $Command_Alias (ID: $DBID), $Expires, last modified $Last_Modified by $Modified_By\n";
		$Command_Alias = uc($Command_Alias); # Turn to uppercase so that sudo can read it correctly
		$Command =~ s/,\s$//; # Remove trailing comma
		$Command =~ s/\\/\\\\/; # Escape the escape!
		$Command =~ s/:/\\:/; # Escape semicolon
		$Command =~ s/,/\\,/; # Escape commas
		$Command =~ s/=/\\=/; # Escape equals
		print FILE "Cmnd_Alias	COMMAND_$Command_Alias = $Command\n\n";

	}

print FILE "### Command Section Ends ###\n\n";
close FILE;

} #sub write_commands

sub create_host_rule_groups {

	my $Rule_ID = $_[0];
	my $Group_to_Return;
	
		### Host Groups
		my $Select_Host_Group_Links = $DB_Sudoers->prepare("SELECT `host_group`
			FROM `lnk_rules_to_host_groups`
			WHERE `rule` = ?"
		);
		$Select_Host_Group_Links->execute($Rule_ID);

		while ( my @Select_Links = $Select_Host_Group_Links->fetchrow_array() )
		{
			
			my $Group_ID = $Select_Links[0];

			my $Select_Groups = $DB_Sudoers->prepare("SELECT `groupname`
				FROM `host_groups`
				WHERE `id` = ?
				AND `active` = '1'
				AND (`expires` >= '$Date'
					OR `expires` = '0000-00-00')"
			);
			$Select_Groups->execute($Group_ID);

			while ( my @Select_Group_Array = $Select_Groups->fetchrow_array() )
			{
				my $Host_Group_Name = $Select_Group_Array[0];
				$Host_Group_Name = uc($Host_Group_Name); # Turn to uppercase so that sudo can read it correctly
				$Group_to_Return = $Group_to_Return . 'HOST_GROUP_' . $Host_Group_Name . ', ';
			}
		}
		
		### Hosts
		my $Select_Host_Links = $DB_Sudoers->prepare("SELECT `host`
			FROM `lnk_rules_to_hosts`
			WHERE `rule` = ?"
		);
		$Select_Host_Links->execute($Rule_ID);

		while ( my @Select_Links = $Select_Host_Links->fetchrow_array() )
		{
			
			my $Host_ID = $Select_Links[0];

			my $Select_Hosts = $DB_Sudoers->prepare("SELECT `hostname`
				FROM `hosts`
				WHERE `id` = ?
				AND `active` = '1'
				AND (`expires` >= '$Date'
					OR `expires` = '0000-00-00')"
			);
			$Select_Hosts->execute($Host_ID);

			while ( my @Select_Hosts_Array = $Select_Hosts->fetchrow_array() )
			{
				my $Host_Name = $Select_Hosts_Array[0];
				$Group_to_Return = $Group_to_Return . $Host_Name . ', ';
			}
		}

	$Group_to_Return =~ s/,\s$//; # Remove trailing comma
	return $Group_to_Return;

} # sub create_host_rule_groups

sub create_user_rule_groups {

	my $Rule_ID = $_[0];
	my $Group_to_Return;
	
		### User Groups
		my $Select_User_Group_Links = $DB_Sudoers->prepare("SELECT `user_group`
			FROM `lnk_rules_to_user_groups`
			WHERE `rule` = ?"
		);
		$Select_User_Group_Links->execute($Rule_ID);

		while ( my @Select_Links = $Select_User_Group_Links->fetchrow_array() )
		{
			
			my $Group_ID = $Select_Links[0];

			my $Select_Groups = $DB_Sudoers->prepare("SELECT `groupname`
				FROM `user_groups`
				WHERE `id` = ?
				AND `active` = '1'
				AND (`expires` >= '$Date'
					OR `expires` = '0000-00-00')"
			);
			$Select_Groups->execute($Group_ID);

			while ( my @Select_Group_Array = $Select_Groups->fetchrow_array() )
			{
				my $User_Group_Name = $Select_Group_Array[0];
				$User_Group_Name = uc($User_Group_Name); # Turn to uppercase so that sudo can read it correctly
				$User_Group_Name =~ s/[^A-Z0-9]/_/g;
				$Group_to_Return = $Group_to_Return . 'USER_GROUP_' . $User_Group_Name . ', ';
			}
		}
		
		### Users
		my $Select_User_Links = $DB_Sudoers->prepare("SELECT `user`
			FROM `lnk_rules_to_users`
			WHERE `rule` = ?"
		);
		$Select_User_Links->execute($Rule_ID);

		while ( my @Select_Links = $Select_User_Links->fetchrow_array() )
		{
			
			my $User_ID = $Select_Links[0];

			my $Select_Users = $DB_Sudoers->prepare("SELECT `username`
				FROM `users`
				WHERE `id` = ?
				AND `active` = '1'
				AND (`expires` >= '$Date'
					OR `expires` = '0000-00-00')"
			);
			$Select_Users->execute($User_ID);

			while ( my @Select_Users_Array = $Select_Users->fetchrow_array() )
			{
				my $User_Name = $Select_Users_Array[0];
				$Group_to_Return = $Group_to_Return . $User_Name . ', ';
			}
		}


	$Group_to_Return =~ s/,\s$//; # Remove trailing comma
	return $Group_to_Return;

} # sub create_user_rule_groups

sub create_command_rule_groups {

	my $Rule_ID = $_[0];
	my $Group_to_Return;
	
		### Command Groups
		my $Select_Command_Group_Links = $DB_Sudoers->prepare("SELECT `command_group`
			FROM `lnk_rules_to_command_groups`
			WHERE `rule` = ?"
		);
		$Select_Command_Group_Links->execute($Rule_ID);

		while ( my @Select_Links = $Select_Command_Group_Links->fetchrow_array() )
		{
			
			my $Group_ID = $Select_Links[0];

			my $Select_Groups = $DB_Sudoers->prepare("SELECT `groupname`
				FROM `command_groups`
				WHERE `id` = ?
				AND `active` = '1'
				AND (`expires` >= '$Date'
					OR `expires` = '0000-00-00')"
			);
			$Select_Groups->execute($Group_ID);

			while ( my @Select_Group_Array = $Select_Groups->fetchrow_array() )
			{
				my $Commnand_Group = $Select_Group_Array[0];
				$Commnand_Group = uc($Commnand_Group); # Turn to uppercase so that sudo can read it correctly
				$Group_to_Return = $Group_to_Return . 'COMMAND_GROUP_' . $Commnand_Group . ', ';
			}
		}
		
		### Commands
		my $Select_Command_Links = $DB_Sudoers->prepare("SELECT `command`
			FROM `lnk_rules_to_commands`
			WHERE `rule` = ?"
		);
		$Select_Command_Links->execute($Rule_ID);

		while ( my @Select_Links = $Select_Command_Links->fetchrow_array() )
		{
			
			my $Command_ID = $Select_Links[0];

			my $Select_Commands = $DB_Sudoers->prepare("SELECT `command_alias`
				FROM `commands`
				WHERE `id` = ?
				AND `active` = '1'
				AND (`expires` >= '$Date'
					OR `expires` = '0000-00-00')"
			);
			$Select_Commands->execute($Command_ID);

			while ( my @Select_Commands_Array = $Select_Commands->fetchrow_array() )
			{
				my $Command_Alias = $Select_Commands_Array[0];
				$Command_Alias = uc($Command_Alias); # Turn to uppercase so that sudo can read it correctly
				$Group_to_Return = $Group_to_Return . 'COMMAND_' . $Command_Alias . ', ';
			}
		}


	$Group_to_Return =~ s/,\s$//; # Remove trailing comma
	return $Group_to_Return;

} # sub create_command_rule_groups

sub write_rules {

	open( FILE, ">>$Sudoers_Location" ) or die "Can't open $Sudoers_Location";

	print FILE "\n### Rule Section Begins ###\n\n";

	my $Select_Rules = $DB_Sudoers->prepare("SELECT `id`, `name`, `all_hosts`, `run_as`, `nopasswd`, `noexec`, `expires`, `last_approved`, `approved_by`, `last_modified`, `modified_by`
		FROM `rules`
		WHERE `active` = '1'
		AND `approved` = '1'
		AND (`expires` >= '$Date'
			OR `expires` = '0000-00-00')
		ORDER BY `id` ASC"
	);

	$Select_Rules->execute();

	while ( my @Select_Rules = $Select_Rules->fetchrow_array() )
	{

		my $DBID = $Select_Rules[0];
		my $DB_Rule_Name = $Select_Rules[1];
		my $ALL_Hosts = $Select_Rules[2];
		my $Run_As = $Select_Rules[3];
		my $NOPASSWD = $Select_Rules[4];
			if ($NOPASSWD == 1) {$NOPASSWD = 'NOPASSWD'} else {$NOPASSWD = 'PASSWD'};
		my $NOEXEC = $Select_Rules[5];
			if ($NOEXEC == 1) {$NOEXEC = 'NOEXEC'} else {$NOEXEC = 'EXEC'};
		my $Expires = $Select_Rules[6];
		my $Last_Approved = $Select_Rules[7];
		my $Approved_By = $Select_Rules[8];
		my $Last_Modified = $Select_Rules[9];
		my $Modified_By = $Select_Rules[10];

		my $Returned_Host_Group = &create_host_rule_groups($DBID);
		my $Returned_User_Group = &create_user_rule_groups($DBID);
		my $Returned_Command_Group = &create_command_rule_groups($DBID);

		if ($ALL_Hosts) {
			$Returned_Host_Group = 'ALL';
		}

		if ($Expires eq '0000-00-00') {
			$Expires = 'does not expire';
		}
		else {
			$Expires = "expires on " . $Expires;
		}

		if ($Returned_Host_Group && $Returned_User_Group && $Returned_Command_Group) {
			print FILE "## $DB_Rule_Name (ID: $DBID), $Expires, last modified $Last_Modified by $Modified_By, last approved $Last_Approved by $Approved_By\n";
			print FILE "Host_Alias	HOST_RULE_GROUP_$DBID = $Returned_Host_Group\n";
			print FILE "User_Alias	USER_RULE_GROUP_$DBID = $Returned_User_Group\n";
			print FILE "Cmnd_Alias	COMMAND_RULE_GROUP_$DBID = $Returned_Command_Group\n";
			print FILE "USER_RULE_GROUP_$DBID	HOST_RULE_GROUP_$DBID = ($Run_As) $NOPASSWD:$NOEXEC: COMMAND_RULE_GROUP_$DBID\n\n";
		}
		else {
			print FILE "#######\n";
			print FILE "####### $DB_Rule_Name (ID: $DBID) was not written because the rule is not complete. It lacks defined Hosts, Users or Commands. #######\n";
			print FILE "#######\n\n";
		}
	}

print FILE "### Rule Section Ends ###\n\n";
close FILE;

} #sub write_rules

sub record_audit {

	my $Result = $_[0];

	my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");

	my $MD5_New_Checksum = `$md5sum $Sudoers_Location | $cut -d ' ' -f 1`;
		$MD5_New_Checksum =~ s/\s//g;
	my $MD5_Existing_Sudoers = `$md5sum $Sudoers_Storage/sudoers_$MD5_New_Checksum | $cut -d ' ' -f 1`;
		$MD5_Existing_Sudoers =~ s/\s//g;

	if ($Result eq 'PASSED' && $MD5_New_Checksum ne $MD5_Existing_Sudoers) {
		my $New_Sudoers_Location = "$Sudoers_Storage/sudoers_$MD5_New_Checksum";
		`$cp -dp $Sudoers_Location $New_Sudoers_Location`; # Backing up sudoers
		chown $Owner, $Group, $New_Sudoers_Location;
		chmod 0640, $New_Sudoers_Location;
		$MD5_New_Checksum = "MD5: " . $MD5_New_Checksum;
		$Audit_Log_Submission->execute("Sudoers", "Deployment Succeeded", "Configuration changes were detected and a new sudoers file was built, passed visudo validation, and MD5 checksums as follows: $MD5_New_Checksum. A copy of this sudoers has been stored at '$New_Sudoers_Location' for future reference.", 'System');
	}
	elsif ($Result eq 'FAILED') {
		my $Latest_Good_Sudoers = `$ls -t $Sudoers_Storage | $grep 'sudoers_' | $head -1`;
			$Latest_Good_Sudoers =~ s/\n//;
		my $Latest_Good_Sudoers_MD5 = `$md5sum $Sudoers_Storage/$Latest_Good_Sudoers | $cut -d ' ' -f 1`;
			$Latest_Good_Sudoers_MD5 =~ s/\s//;
		my $Check_For_Existing_Bad_Sudoers = `$ls -t $Sudoers_Storage/broken_$MD5_New_Checksum`;
		if (!$Check_For_Existing_Bad_Sudoers) {
			$Audit_Log_Submission->execute("Sudoers", "Deployment Failed", "Configuration changes were detected and a new sudoers file was built, but failed visudo validation. Deployment aborted, latest valid sudoers (MD5: $Latest_Good_Sudoers_MD5) has been restored. The broken sudoers file has been stored at $Sudoers_Storage/broken_$MD5_New_Checksum for manual inspection - please report this error to your manager.", 'System');
			`$cp -dp $Sudoers_Location $Sudoers_Storage/broken_$MD5_New_Checksum`; # Backing up broken sudoers
			chown $Owner, $Group, "$Sudoers_Storage/broken_$MD5_New_Checksum";
			chmod 0640, "$Sudoers_Storage/broken_$MD5_New_Checksum";
		}
		`$cp -dp $Sudoers_Storage/$Latest_Good_Sudoers $Sudoers_Location`; # Restoring latest working sudoers
		chown $Owner, $Group, $Sudoers_Location;
		chmod 0640, $Sudoers_Location;
	}
	else {
		print "New sudoers matches old sudoers. Not replacing.\n";
	}


	# / Audit Log

} #sub record_audit

