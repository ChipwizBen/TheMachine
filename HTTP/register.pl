#!/usr/bin/perl

use strict;

use DBI;

require 'common.pl';

my $DB_Connection = DB_Connection();

my $CGI = CGI->new;
print "Content-Type: text/html\n\n";

my $Host_Name_Add = $CGI->param("Host_Name_Add");
	$Host_Name_Add =~ s/\s//g;
	$Host_Name_Add =~ s/[^a-zA-Z0-9\-\.]//g;
my $IP_Add = $CGI->param("IP_Add");
	$IP_Add =~ s/\s//g;
	$IP_Add =~ s/[^0-9\.]//g;
my $User_Name = 'System';

if (!$Host_Name_Add || !$IP_Add) {
	print "You must specify both a hostname and IP address\n";
	exit(1);
}


&duplicate_check;

sub duplicate_check {

	### Existing Host and IP Check

	my $Existing_Host_Name_Check = $DB_Connection->prepare("SELECT `id`, `ip`
		FROM `hosts`
		WHERE `hostname` = ?");
		$Existing_Host_Name_Check->execute($Host_Name_Add);
		my $Existing_Hosts = $Existing_Host_Name_Check->rows();

	my $Existing_IP_Check = $DB_Connection->prepare("SELECT `id`, `hostname`
		FROM `hosts`
		WHERE `ip` = ?");
		$Existing_IP_Check->execute($IP_Add);
		my $Existing_IPs = $Existing_IP_Check->rows();

	if ($Existing_Hosts > 0 || $Existing_IPs > 0)  {
		print "Failed to add host. Duplicate detected.\n";
		exit(1);
	}
	else {
		&add_host;
	}

	### / Existing Host and IP Check
} # duplicate_check

sub add_host {
	my $Host_Insert = $DB_Connection->prepare("INSERT INTO `hosts` (
		`hostname`,
		`ip`,
		`expires`,
		`active`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?, ?
	)");

	$Host_Insert->execute($Host_Name_Add, $IP_Add, '0000-00-00', '1', $User_Name);

	my $Host_Insert_ID = $DB_Connection->{mysql_insertid};

	# Adding to sudoers distribution database with defaults
	my $DB_Connection = DB_Connection();

	my ($Distribution_Default_SFTP_Port,
		$Distribution_Default_User,
		$Distribution_Default_Key_Path, 
		$Distribution_Default_Timeout,
		$Distribution_Default_Remote_Sudoers) = DSMS_Distribution_Defaults();

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

	my $Audit_Log_Submission = $DB_Connection->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");
	
	$Audit_Log_Submission->execute("Hosts", "Add", "The auto-registration system added $Host_Name_Add ($IP_Add), set it Active and to not expire. The system assigned it Host ID $Host_Insert_ID.", $User_Name);
	$Audit_Log_Submission->execute("Distribution", "Add", "The auto-registration system added $Host_Name_Add ($IP_Add) [Host ID $Host_Insert_ID] to the sudoers distribution system and assigned it default parameters.", $User_Name);

	# / Audit Log

	print "Successfully added $Host_Name_Add to DSMS as Host ID $Host_Insert_ID\n";

} # add_host

1;
