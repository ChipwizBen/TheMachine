#!/usr/bin/perl

use strict;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Name = System_Name();
my $Version = Version();
my $DB_Connection = DB_Connection();

my $Git_Check = Git_Link('Status_Check');
if ($Git_Check !~ /Yes/i) {print "Git disabled so exiting gracefully. Nothing was changed.\n"; exit 0;}

my $Select_Command_Sets = $DB_Connection->prepare("SELECT `id`, `name`, `command`, `description`, `owner_id`, `revision`, `revision_parent`, `last_modified`, `modified_by`
	FROM `command_sets`"
);
$Select_Command_Sets->execute();

my $Git_Directory = Git_Locations('CommandSets');
	unlink glob "$Git_Directory/*.sh" or warn "Could not unlink $Git_Directory/*.sh";	

my $Rows;
COMMAND_SET: while ( my @Select_Command_Sets = $Select_Command_Sets->fetchrow_array() )
{
	$Rows++;
	my $DBID = $Select_Command_Sets[0];
	my $Command_Name = $Select_Command_Sets[1];
	my $Command = $Select_Command_Sets[2];
	my $Command_Description = $Select_Command_Sets[3];
	my $Command_Owner_ID = $Select_Command_Sets[4];
	my $Command_Revision = $Select_Command_Sets[5];
	my $Command_Revision_Parent = $Select_Command_Sets[6];
	my $Last_Modified = $Select_Command_Sets[7];
	my $Modified_By = $Select_Command_Sets[8];

	## Latest revision filter
	my $Select_Child = $DB_Connection->prepare("SELECT `id` FROM `command_sets` WHERE `revision_parent` = ?");
	$Select_Child->execute($DBID);
	my $Children = $Select_Child->rows();
	if ($Children > 0) {
		$Rows--;
		next COMMAND_SET;
	}

	## Gather dependency data
	my $Command_Set_Dependencies;
	my $Select_Command_Set_Dependencies = $DB_Connection->prepare("SELECT `dependent_command_set_id`
		FROM `command_set_dependency`
		WHERE `command_set_id` = ?
		ORDER BY `order` ASC"
	);
	$Select_Command_Set_Dependencies->execute($DBID);

	while ( my @Dependencies = $Select_Command_Set_Dependencies->fetchrow_array() )
	{
		my $Dependent_Command_Set_ID = $Dependencies[0];

		my $Select_Dependency_Name = $DB_Connection->prepare("SELECT `name`, `description`, `revision`
			FROM `command_sets`
			WHERE `id` = ?"
		);
		$Select_Dependency_Name->execute($Dependent_Command_Set_ID);
		my ($Dependency_Name, $Dependency_Description, $Dependency_Revision) = $Select_Dependency_Name->fetchrow_array();
		$Command_Set_Dependencies = $Command_Set_Dependencies . "\n## $Dependency_Name (ID: $Dependent_Command_Set_ID) [Rev. $Dependency_Revision] - $Dependency_Description";
	}
	## / Gather dependency data

	## Discover owner

	my $Command_Owner;
	if ($Command_Owner_ID == 0) {
		$Command_Owner = 'System';
	}
	else {
		my $Discover_Owner = $DB_Connection->prepare("SELECT `username`
			FROM `credentials`
			WHERE `id` = ?"
		);
		$Discover_Owner->execute($Command_Owner_ID);
		$Command_Owner = $Discover_Owner->fetchrow_array();

		if ($Command_Owner eq '') {
			my $Update_Owner = $DB_Connection->prepare("UPDATE `command_sets` SET
				`owner_id` = ?,
				`modified_by` = ?
				WHERE `owner_id` = ?");
			$Update_Owner->execute( '0', 'System', $Command_Owner_ID);

			# Audit Log
			my $Audit_Log_Submission = $DB_Connection->prepare("INSERT INTO `audit_log` (
				`category`,
				`method`,
				`action`,
				`username`
			)
			VALUES (
				?, ?, ?, ?
			)");
			$Audit_Log_Submission->execute("D-Shell", "Modify", "The system claimed Command Sets belonging to Owner ID $Command_Owner_ID because they appear to have been deleted.", 'System');
		}
	}

	## / Discover owner

	if (!$Command_Set_Dependencies) {
		$Command_Set_Dependencies = 'None.';
	}

	$Command =~ s/\*SEND\s*//gi;
	$Command =~ s/\*REBOOT/reboot/gi;
	$Command =~ s/\*PAUSE/sleep/gi;

	open( FILE, ">$Git_Directory/$Command_Name.sh" ) or die "Can't open $Git_Directory/$Command_Name.sh";
	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED SCRIPT\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "#########################################################################\n";
	print FILE "## $Command_Name [Command Set ID $DBID].\n";
	print FILE "## Revision $Command_Revision.\n";
	print FILE "## Owned by $Command_Owner.\n";
	print FILE "## Modified $Last_Modified by $Modified_By.\n";
	print FILE "##\n";
	print FILE "## Has dependencies: $Command_Set_Dependencies\n";
	print FILE "#########################################################################\n";
	print FILE "\n";
	print FILE "$Command";
	close FILE;
	&Git_Commit("$Git_Directory/$Command_Name.sh", "Command Set $Command_Name (ID: $DBID), [Rev. $Command_Revision], created $Last_Modified by $Modified_By.", $Last_Modified, $Modified_By);
}

&Git_Commit("$Git_Directory/*", "Cleared old configs.");
&Git_Commit('Push');
