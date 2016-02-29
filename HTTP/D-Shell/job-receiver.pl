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
	${Blue}-k, --key\t\t${Green}Private key ID for the remote host
	${Blue}-Q, --passphrase\t${Green}Password for the private key (you DO have a passphrase on it, don't you? Tut tut.)
	${Blue}-p, --password\t\t${Green}Password for the remote host
	${Blue}-c, --command-set\t${Green}The ID of the command set
	${Blue}-H, --hosts\t\t${Green}A comma sperated list of host IDs (no spaces!) [e.g.: -H 302,5943,2140]

${Green}Examples:
	${Green}## Ha! Yeah right. You shouldn't even BE here! Oh go on then, just this once, but only because I like you.
	${Blue}$0 -c 76 -k 14 -H 294,5883,345${Clear}\n\n";

my @Hosts;
my $Command_Set;

if (!@ARGV) {
	print $Help;
	exit(0);
}

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
		`status`,
		`modified_by`
		)
		VALUES (
			?, ?, ?, ?
		)");

		$Job_Submission->execute("$Host", "$Command_Set", "4", "System");

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
	}

	exit(0);

}
else {
	print $Help;
	exit(0);
}

1;