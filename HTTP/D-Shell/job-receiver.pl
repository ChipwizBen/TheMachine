#!/usr/bin/perl

use strict;
use HTML::Table;
use Date::Parse qw(str2time);
use POSIX qw(strftime);

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Short_Name = System_Short_Name();
my $Version = Version();
my $DB_Management = DB_Management();
my $DB_DShell = DB_DShell();
my $DB_IP_Allocation = DB_IP_Allocation();

$| = 1;
my $Green = "\e[0;32;10m";
my $Yellow = "\e[0;33;10m";
my $Red = "\e[0;31;10m";
my $Pink = "\e[1;35;10m";
my $Blue = "\e[1;34;10m";
my $Clear = "\e[0m";

my $Help = "
${Green}$System_Short_Name version $Version

Hello there, intrepid random file executer! If you're reading this, you're probably lost. This file is only useful as part of the wider system, so you're going to struggle without all the bits. But here are the options anyway for you to break stuff, you crazy fool:

Options are:
	${Blue}-u, --username\t\t${Green}Username for the remote host(s). Will also trigger the job.
	${Blue}-P, --password\t\t${Green}Password for the remote host(s)
	${Blue}-f, --failure\t\t${Green}Specify the on-failure behaviour (0 is continue, 1 is die)
	${Blue}-c, --command-set\t${Green}The ID of the command set
	${Blue}-H, --hosts\t\t${Green}A comma sperated list of host IDs (no spaces!) [e.g.: -H 302,5943,2140]

${Green}Examples:
	${Green}## Ha! Yeah right. You shouldn't even BE here! Oh go on then, just this once, but only because I like you.
	${Blue}$0 -c 76 -H 294,5883,345${Clear}\n\n";


if (!@ARGV) {
	print $Help;
	exit(0);
}

my @Hosts;
my $Command_Set;
my $Trigger_Job;
my $User_Trigger;
my $Captured_User_Name;
my $Captured_Password;
my $On_Failure;
foreach my $Parameter (@ARGV) {
	if ($Parameter eq '-H' || $Parameter eq '--hosts') {
		my @Discovered_Hosts = @ARGV;
		while (my $Discovered_Host = shift @Discovered_Hosts) {
			if ($Discovered_Host =~ /-H/ || $Discovered_Host =~ /--hosts/) {
				$Discovered_Host = shift @Discovered_Hosts;
				@Hosts = split(',', $Discovered_Host);
				last;
			}
		}
	}
	if ($Parameter eq '-c' || $Parameter eq '--command-set') {
		my @Command_Sets = @ARGV;
		while ($Command_Set = shift @Command_Sets) {
			if ($Command_Set =~ /-c/ || $Command_Set =~ /--command-set/) {
				$Command_Set = shift @Command_Sets;
				last;
			}
		}
	}
	if ($Parameter eq '-X') {
		my @User_Triggers = @ARGV;
		while ($User_Trigger = shift @User_Triggers) {
			if ($User_Trigger =~ /-X/) {
				$User_Trigger = shift @User_Triggers;
				$User_Trigger =~ s/MagicTagSpace/ /g;
				last;
			}
		}
	}
	if ($Parameter eq '-u' || $Parameter eq '--username') {
		my @Captured_User_Names = @ARGV;
		while ($Captured_User_Name = shift @Captured_User_Names) {
			if ($Captured_User_Name =~ /-u/ || $Captured_User_Name =~ /--username/) {
				$Captured_User_Name = shift @Captured_User_Names;
				last;
			}
		}
	}
	if ($Parameter eq '-P' || $Parameter eq '--password') {
		my @Captured_Passwords = @ARGV;
		while ($Captured_Password = shift @Captured_Passwords) {
			if ($Captured_Password =~ /-P/ || $Captured_Password =~ /--password/) {
				$Captured_Password = shift @Captured_Passwords;
				last;
			}
		}
	}
	if ($Parameter eq '-f' || $Parameter eq '--failure') {
		my @On_Failures = @ARGV;
		while ($On_Failure = shift @On_Failures) {
			if ($On_Failure =~ /-f/ || $On_Failure =~ /--failure/) {
				$On_Failure = shift @On_Failures;
				last;
			}
		}
	}
	if ($Parameter eq '-h' || $Parameter eq '--help') {
		print $Help;
		exit(0);
	}
}

if ($Command_Set && @Hosts) {

	foreach my $Host (@Hosts) {

		my $Job_Submission = $DB_DShell->prepare("INSERT INTO `jobs` (
		`host_id`,
		`command_set_id`,
		`on_failure`,
		`status`,
		`modified_by`
		)
		VALUES (
			?, ?, ?, ?, ?
		)");

		if (!$On_Failure) {$On_Failure = 0};
		$Job_Submission->execute($Host, $Command_Set, $On_Failure, "4", "System");
		my $Command_Insert_ID = $DB_DShell->{mysql_insertid};

		my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
		)
		VALUES (
			?, ?, ?, ?
		)");

		$Audit_Log_Submission->execute("D-Shell", "Receive", "The job scheduler received a job to run command set ID $Command_Set on host ID $Host.", "System");

		if ($Command_Insert_ID && $Captured_User_Name) {
			# Audit Log
			my $DB_Management = DB_Management();
			my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
				`category`,
				`method`,
				`action`,
				`username`
			)
			VALUES (
				?, ?, ?, ?
			)");
		
			$Audit_Log_Submission->execute("D-Shell", "Run", "$User_Trigger started Job ID $Command_Insert_ID with username $Captured_User_Name.", $User_Trigger);
			# / Audit Log

			my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
				`status` = ?,
				`modified_by` = ?
				WHERE `id` = ?");
			$Update_Job->execute( '10', $User_Trigger, $Command_Insert_ID);

			$SIG{CHLD} = 'IGNORE';
			my $PID = fork();
			if (defined $PID && $PID == 0) {
				exec "./d-shell.pl -j $Command_Insert_ID -u $Captured_User_Name -P $Captured_Password >> /tmp/output 2>&1 &";
				exit(0);
			}
		}
	}

	exit(0);

}
else {
	print $Help;
	exit(0);
}

1;