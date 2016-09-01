#!/usr/bin/perl

use strict;
use HTML::Table;
use Date::Parse qw(str2time);
use POSIX qw(strftime);
use Getopt::Long qw(:config no_ignore_case);

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
	${Blue}-c, --command-set\t${Green}The ID of the command set
	${Blue}-H, --hosts\t\t${Green}A space seperated list of host IDs [e.g.: -H 302 5943 2140]
	${Blue}-u, --username\t\t${Green}Username for the remote host(s). Will also trigger the job.
	${Blue}-P, --password\t\t${Green}Password for the remote host(s)
	${Blue}-k, --key\t\t${Green}Pass the key ID used to connect to the server
	${Blue}-f, --failure\t\t${Green}Specify the on-failure behaviour (0 is continue, 1 is die)

${Green}Examples:
	${Green}## Ha! Yeah right. You shouldn't even BE here! Oh go on then, just this once, but only because I like you.
	${Blue}$0 -c 76 -H 294 5883 345${Clear}\n\n";


if (!@ARGV) {
	print $Help;
	exit(0);
}

my @Hosts_List;
my $Command_Set;
my $Trigger_Job;
my $User_Trigger;
my $Captured_User_Name;
my $Captured_Password;
my $Captured_Key;
my $Captured_Key_Lock;
my $Captured_Key_Passphrase;
my $On_Failure;

GetOptions(
	'H:s{1,}' => \@Hosts_List, # Set as string due to possibility of space seperation
	'hosts:s{1,}' => \@Hosts_List, # Set as string due to possibility of space seperation
	'c:i' => \$Command_Set,
	'command-set:i' => \$Command_Set,
	'X:s' => \$User_Trigger,
	'u:s' => \$Captured_User_Name,
	'username:s' => \$Captured_User_Name,
	'P:s' => \$Captured_Password,
	'password:s' => \$Captured_Password,
	'k:s' => \$Captured_Key,
	'key:s' => \$Captured_Key,
	'L:s' => \$Captured_Key_Lock,
	'lock:s' => \$Captured_Key_Lock,
	'K:s' => \$Captured_Key_Passphrase,
	'passphrase:s' => \$Captured_Key_Passphrase,
	'f:s' => \$On_Failure,
	'failure:s' => \$On_Failure,
) or die("Option capture badness: $@\n");

$User_Trigger =~ s/MagicTagSpace/ /g;
if (!$User_Trigger) {$User_Trigger = 'System'}

my @Hosts = split(/[\s,]+/,join(',' , @Hosts_List));

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
		$Job_Submission->execute($Host, $Command_Set, $On_Failure, "4", $User_Trigger);
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

		$Audit_Log_Submission->execute("D-Shell", "Receive", "The job scheduler received a job to run command set ID $Command_Set on host ID $Host.", $User_Trigger);

		if ($Command_Insert_ID) {
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
		
			$Audit_Log_Submission->execute("D-Shell", "Run", "$User_Trigger started Job ID $Command_Insert_ID.", $User_Trigger);
			# / Audit Log

			my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
				`status` = ?,
				`modified_by` = ?
				WHERE `id` = ?");
			$Update_Job->execute( '10', $User_Trigger, $Command_Insert_ID);

			$SIG{CHLD} = 'IGNORE';
			my $PID = fork();
			if (defined $PID && $PID == 0) {
				my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
					`category`,
					`method`,
					`action`,
					`username`
				)
				VALUES (
					?, ?, ?, ?
				)");
				if ($Captured_User_Name && $Captured_Password) {
					$Audit_Log_Submission->execute("D-Shell", "Run", "Job ID $Command_Insert_ID triggered with username $Captured_User_Name.", $User_Trigger);
					exec "./d-shell.pl -j $Command_Insert_ID -u $Captured_User_Name -P $Captured_Password >> /dev/null 2>&1 &";
				}
				elsif ($Captured_Key && $Captured_Key_Lock) {
					if ($Captured_Key_Passphrase) {
						$Audit_Log_Submission->execute("D-Shell", "Run", "Job ID $Command_Insert_ID triggered with key.", $User_Trigger);
						exec "./d-shell.pl -j $Command_Insert_ID -k $Captured_Key -L $Captured_Key_Lock -K $Captured_Key_Passphrase >> /dev/null 2>&1 &";
						exit(0);
					}
					else {
						$Audit_Log_Submission->execute("D-Shell", "Run", "Job ID $Command_Insert_ID triggered with key.", $User_Trigger);
						exec "./d-shell.pl -j $Command_Insert_ID -k $Captured_Key -L $Captured_Key_Lock >> /dev/null 2>&1 &";
						exit(0);						
					}

				}
				else {
					print "Didn't get what I expected. Dying.";
					exit(1);
				}
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