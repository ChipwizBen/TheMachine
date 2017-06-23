#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);


use DBI;

require './common.pl';

my $DB_Connection = DB_Connection();

my $CGI = CGI->new;
print "Content-Type: text/html\n\n";

my $Host_Name_Add = $CGI->param("Host_Name_Add");
	$Host_Name_Add =~ s/\s//g;
	$Host_Name_Add =~ s/[^a-zA-Z0-9\-\.]//g;
my $User_Name = 'System';

if (!$Host_Name_Add) {
	print "You must specify a hostname\n";
	exit(1);
}


&duplicate_check;

sub duplicate_check {

	### Existing Host Check

	my $Existing_Host_Name_Check = $DB_Connection->prepare("SELECT `id`
		FROM `hosts`
		WHERE `hostname` = ?");
		$Existing_Host_Name_Check->execute($Host_Name_Add);
		my $Existing_Hosts = $Existing_Host_Name_Check->rows();


	if ($Existing_Hosts > 0)  {
		print "Failed to add host. Duplicate detected.\n";
		exit(1);
	}
	else {
		&add_host;
	}

	### / Existing Host Check
} # duplicate_check

sub add_host {
	my $Host_Insert = $DB_Connection->prepare("INSERT INTO `hosts` (
		`hostname`,
		`active`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?
	)");

	$Host_Insert->execute($Host_Name_Add, '1', $User_Name);

	my $Host_Insert_ID = $DB_Connection->{mysql_insertid};

	my $Host_Attribute_Insert = $DB_Connection->prepare("INSERT INTO `host_attributes` (
		`host_id`,
		`dsms`
	)
	VALUES (
		?, ?
	)
	ON DUPLICATE KEY UPDATE `dsms` = ?");
	
	$Host_Attribute_Insert->execute($Host_Insert_ID, '1', '1');


	# Adding to sudoers distribution database with defaults
	my $DB_Connection = DB_Connection();

	my ($Distribution_Default_SFTP_Port,
		$Distribution_Default_User,
		$Distribution_Default_Key_Path, 
		$Distribution_Default_Timeout,
		$Distribution_Default_Remote_Sudoers) = Distribution_Defaults();

		my $Distribution_Insert = $DB_Connection->prepare("INSERT INTO `distribution` (
			`host_id`,
			`sftp_port`,
			`user`,
			`key_path`,
			`timeout`,
			`remote_sudoers_path`,
			`last_modified`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, ?, ?, NOW(), ?
		)");


		$Distribution_Insert->execute($Host_Insert_ID, $Distribution_Default_SFTP_Port, $Distribution_Default_User, $Distribution_Default_Key_Path, 
		$Distribution_Default_Timeout, $Distribution_Default_Remote_Sudoers, $User_Name);

	# / Adding to sudoers distribution database with defaults

	# Audit Log

	my $Audit_Log_Submission = Audit_Log_Submission();
	
	$Audit_Log_Submission->execute("Hosts", "Add", "The auto-registration system added $Host_Name_Add, set it Active and to not expire. The system assigned it Host ID $Host_Insert_ID.", $User_Name);
	$Audit_Log_Submission->execute("Distribution", "Add", "The auto-registration system added $Host_Name_Add [Host ID $Host_Insert_ID] to the sudoers distribution system and assigned it default parameters.", $User_Name);

	# / Audit Log

	print "Successfully added $Host_Name_Add to DSMS as Host ID $Host_Insert_ID\n";

} # add_host

1;
