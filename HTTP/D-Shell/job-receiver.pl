#!/usr/bin/perl -T

use strict;
use Getopt::Long qw(:config no_ignore_case);

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Short_Name = System_Short_Name();
my $Version = Version();
my $DB_Connection = DB_Connection();

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
	${Blue}-c, --command-set\t ${Green}The ID of the command set
	${Blue}-H, --hosts\t\t ${Green}A space seperated list of host IDs [e.g.: -H 302 5943 2140]
	${Blue}-u, --username\t\t ${Green}Username for the remote host(s). Will also trigger the job.
	${Blue}-P, --password\t\t ${Green}Password for the remote host(s)
	${Blue}-k, --key\t\t ${Green}Pass the key ID used to connect to the server
	${Blue}-f, --failure\t\t ${Green}Specify the on-failure behaviour (0 is continue, 1 is die)
	${Blue}-r, --runtime-variable ${Green}Pass a real time variable (e.g. -r MySQLPassword=bla -r IP=blabla)
	${Blue}-J, --get-job-id\t ${Green}Spits out the Job ID of the just submitted job(s).
	${Blue}--high-priority\t\t ${Green}Queues the Job but ignores the position and executes immediately (assuming you've also passed parameters to run)

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
my %Captured_Runtime_Variables;
	my $Runtime_Variables;
my $On_Failure;
my $Output_Job_ID;
my $No_Decode;
my $High_Priority;

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
	'r=s%' => \%Captured_Runtime_Variables,
	'runtime-variable=s%' => \%Captured_Runtime_Variables,
	'f:s' => \$On_Failure,
	'failure:s' => \$On_Failure,
	'J' => \$Output_Job_ID,
	'get-job-id' => \$Output_Job_ID,
	'D' => \$No_Decode,
	'no-dec' => \$No_Decode,
	'high-priority' => \$High_Priority
) or die("Fault with options: $@\n");

$User_Trigger =~ s/MagicTagSpace/ /g;
if (!$User_Trigger) {$User_Trigger = 'System'}


if ($Command_Set) {
	if ($Command_Set =~ /^([0-9]+)$/) {$Command_Set = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Command_Set, $User_Trigger);}
}
if ($User_Trigger) {
	if ($User_Trigger =~ /^([0-9a-zA-Z\-\_\s]+)$/) {$User_Trigger = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $User_Trigger, $User_Trigger);}
}
if ($Captured_User_Name) {
	if ($Captured_User_Name =~ /^([0-9a-zA-Z\-\_\s]+)$/) {$Captured_User_Name = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_User_Name, $User_Trigger);}
}
if ($No_Decode ne '') {
	if ($No_Decode =~ /^([0-1])$/) {$No_Decode = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $No_Decode, $User_Trigger);}
}
if ($Captured_Password && !$No_Decode) {
	if ($Captured_Password =~ /^([0-9a-zA-Z=]+)$/) {$Captured_Password = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Password, $User_Trigger);}
}
elsif ($Captured_Password && $No_Decode) {
	if ($Captured_Password =~ /^(.+)$/) {$Captured_Password = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Password, $User_Trigger);}
}
if ($Captured_Key) {
	if ($Captured_Key =~ /^([0-9]+)$/) {$Captured_Key = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Key, $User_Trigger);}
}
if ($Captured_Key_Lock && !$No_Decode) {
	if ($Captured_Key_Lock =~ /^([0-9a-zA-Z=]+)$/) {$Captured_Key_Lock = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Key_Lock, $User_Trigger);}
}
elsif ($Captured_Key_Lock && $No_Decode) {
	if ($Captured_Key_Lock =~ /^(.+)$/) {$Captured_Key_Lock = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Key_Lock, $User_Trigger);}
}
if ($Captured_Key_Passphrase && !$No_Decode) {
	if ($Captured_Key_Passphrase =~ /^([0-9a-zA-Z=]+)$/) {$Captured_Key_Passphrase = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Key_Passphrase, $User_Trigger);}
}
elsif ($Captured_Key_Passphrase && $No_Decode) {
	if ($Captured_Key_Passphrase =~ /^(.+)$/) {$Captured_Key_Passphrase = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Key_Passphrase, $User_Trigger);}
}
if ($On_Failure ne '') {
	if ($On_Failure =~ /^([0-9]+$)/) {$On_Failure = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $On_Failure, $User_Trigger);}
}
if ($Output_Job_ID ne '') {
	if ($Output_Job_ID =~ /^([0-1])$/) {$Output_Job_ID = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Output_Job_ID, $User_Trigger);}
}
if ($High_Priority ne '') {
	if ($High_Priority =~ /^([0-1])$/) {$High_Priority = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $High_Priority, $User_Trigger);}
}

my @Hosts = split(/[\s,]+/,join(',' , @Hosts_List));

if (%Captured_Runtime_Variables && !$No_Decode) {
	foreach my $Variable_Key (keys %Captured_Runtime_Variables) {
		if ($Variable_Key =~ /^([0-9a-zA-Z#]+)$/) {$Variable_Key = $1;}
		else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Variable_Key, $User_Trigger);}
		my $Variable = $Captured_Runtime_Variables{$Variable_Key};
		if ($Variable =~ /^([0-9a-zA-Z#]+)$/) {$Variable = $1;}
		else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Variable, $User_Trigger);}
		$Variable_Key =~ s/=/#Equals#/g;
		$Variable =~ s/=/#Equals#/g;
		$Runtime_Variables = $Runtime_Variables . " -r '${Variable_Key}'='${Variable}'";
	}
}
if (%Captured_Runtime_Variables && $No_Decode) {
	foreach my $Variable_Key (keys %Captured_Runtime_Variables) {
		if ($Variable_Key =~ /^(.+)$/) {$Variable_Key = $1;}
		else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Variable_Key, $User_Trigger);}
		my $Variable = $Captured_Runtime_Variables{$Variable_Key};
		if ($Variable =~ /^(.+)$/) {$Variable = $1;}
		else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Variable, $User_Trigger);}
		$Variable_Key =~ s/=/#Equals#/g;
		$Variable =~ s/=/#Equals#/g;
		$Runtime_Variables = $Runtime_Variables . " -r '${Variable_Key}'='${Variable}'";
	}
}

if ($No_Decode) {$No_Decode = '-D'} else {$No_Decode = ''}
if ($High_Priority) {$High_Priority = '--high-priority'} else {$High_Priority = ''}

	my $Verbose = Verbose();
	my $Paper_Trail = Paper_Trail();
	if ($Verbose && $Paper_Trail) {
		my $Subroutine = (caller(0))[3];
		if ($User_Trigger) {&System_Logger($Subroutine, "User_Trigger=$User_Trigger");}
		if ($Command_Set) {&System_Logger($Subroutine, "Command_Set=$Command_Set");}
		if ($Captured_User_Name) {&System_Logger($Subroutine, "Captured_User_Name=$Captured_User_Name");}
		if ($Captured_Password) {&System_Logger($Subroutine, "Captured_Password=$Captured_Password");}
		if ($Captured_Key) {&System_Logger($Subroutine, "Captured_Key=$Captured_Key");}
		if ($Captured_Key_Lock) {&System_Logger($Subroutine, "Captured_Key_Lock=$Captured_Key_Lock");}
		if ($Captured_Key_Passphrase) {&System_Logger($Subroutine, "Captured_Key_Passphrase=$Captured_Key_Passphrase");}
		if ($High_Priority) {&System_Logger($Subroutine, "High_Priority=$High_Priority");}
		if (%Captured_Runtime_Variables) {
			my $CRTVs = scalar(keys %Captured_Runtime_Variables);
			{&System_Logger($Subroutine, "### Captured Runtime Variables Follows...");}
			foreach my $Variable_Key (keys %Captured_Runtime_Variables) {
				&System_Logger($Subroutine, "Variable_Key=$Variable_Key");
				&System_Logger($Subroutine, "Value=".$Captured_Runtime_Variables{$Variable_Key});
			}
		}
	}

if ($Command_Set && @Hosts) {

	foreach my $Host (@Hosts) {

		if ($Host =~ /^([0-9]+)$/) {$Host = $1;}
		else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Host, $User_Trigger);}

		my $Job_Submission = $DB_Connection->prepare("INSERT INTO `jobs` (
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
		my $Command_Insert_ID = $DB_Connection->{mysql_insertid};

		my $Audit_Log_Submission = Audit_Log_Submission();

		$Audit_Log_Submission->execute("D-Shell", "Receive", "The job scheduler received a job to run command set ID $Command_Set on host ID $Host.", $User_Trigger);

		if ($Command_Insert_ID) {
			# Audit Log
			my $DB_Connection = DB_Connection();
			my $Audit_Log_Submission = Audit_Log_Submission();
		
			$Audit_Log_Submission->execute("D-Shell", "Run", "$User_Trigger started Job ID $Command_Insert_ID.", $User_Trigger);
			# / Audit Log

			if ($Output_Job_ID) {print "$Command_Insert_ID\n"}

			$SIG{CHLD} = 'IGNORE';
			my $PID = fork();
			if (defined $PID && $PID == 0) {
				$DB_Connection = DB_Connection();
				my $Audit_Log_Submission = Audit_Log_Submission();
				if ($Captured_User_Name && $Captured_Password) {
					$Audit_Log_Submission->execute("D-Shell", "Run", "Job ID $Command_Insert_ID triggered with username $Captured_User_Name.", $User_Trigger);
					exec "./d-shell.pl -j $Command_Insert_ID $No_Decode $High_Priority -u $Captured_User_Name -P $Captured_Password $Runtime_Variables >> /dev/null 2>&1 &";
					exit(0);
				}
				elsif ($Captured_Key && $Captured_Key_Lock) {
					if ($Captured_Key_Passphrase) {
						$Audit_Log_Submission->execute("D-Shell", "Run", "Job ID $Command_Insert_ID triggered with key.", $User_Trigger);
						exec "./d-shell.pl -j $Command_Insert_ID $No_Decode $High_Priority -k $Captured_Key -L $Captured_Key_Lock -K $Captured_Key_Passphrase $Runtime_Variables >> /dev/null 2>&1 &";
						exit(0);
					}
					else {
						$Audit_Log_Submission->execute("D-Shell", "Run", "Job ID $Command_Insert_ID triggered with key.", $User_Trigger);
						exec "./d-shell.pl -j $Command_Insert_ID $No_Decode $High_Priority -k $Captured_Key -L $Captured_Key_Lock $Runtime_Variables >> /dev/null 2>&1 &";
						exit(0);						
					}

				}
				else {
					$Audit_Log_Submission->execute("D-Shell", "Queue", "Job ID $Command_Insert_ID queued.", $User_Trigger);
					exit(0);
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
