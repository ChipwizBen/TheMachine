#!/usr/bin/perl

use strict;
use Net::SSH::Expect;
use Parallel::ForkManager;
use POSIX qw(strftime);

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Short_Name = System_Short_Name();
my $Version = Version();
my $DB_DShell = DB_DShell();
my $DB_IP_Allocation = DB_IP_Allocation();
my $Fork_Count = 10;
my $Override = 0;
my $Verbose = 0;
my $Very_Verbose = 0;
my $Ignore_Bad_Exit_Code = 0;
my $Command_Timeout = 3;

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
	${Blue}-j, --job\t\t${Green}Pass the Job ID to be executed
	${Blue}-v, --verbose\t\t${Green}Turns on verbose output (useful for debug)
	${Blue}-V, --very-verbose\t${Green}Same as verbose, but also includes _LOTS_ of debug (I did warn you)
	${Blue}--override\t\t${Green}Override the lock for Complete or Stopped jobs


${Green}Examples:
	${Green}## This script is too easy - you only have one proper option!
	${Blue}$0 -j 643${Clear}\n\n";


if (!@ARGV) {
	print $Help;
	exit(0);
}

my $Job_ID;
foreach my $Parameter (@ARGV) {
	if ($Parameter eq '-v' || $Parameter eq '--verbose') {
		$Verbose = 1;
		print "${Red}## ${Green}Verbose is on.${Clear}\n";
	}
	if ($Parameter eq '-V' || $Parameter eq '--very-verbose') {
		$Verbose = 1;
		$Very_Verbose = 1;
		print "${Red}## ${Green}Very Verbose is on.${Clear}\n";
	}
	if ($Parameter eq '--override') {
		$Override = 1;
		print "${Red}## ${Pink}Override is on.${Clear}\n";
	}
	if ($Parameter eq '-i' || $Parameter eq '--ignore') {
		$Ignore_Bad_Exit_Code = 1;
		print "${Red}## ${Pink}Ignoring bad exit statues!${Clear}\n";
	}
	if ($Parameter eq '-j' || $Parameter eq '--job') {
		my @Job = @ARGV;
		while ($Job_ID = shift @Job) {
			if ($Job_ID =~ /-j/ || $Job_ID =~ /--job/) {
				$Job_ID = shift @Job;
				last;
			}
		}
	}
}

if (!$Job_ID) {
	print "Something went wrong. Did you pass a Job ID?\n";
	exit(1);
}
else {
	print "${Green}Starting Job ID ${Blue}$Job_ID${Green}...${Clear}\n";
}



my $Select_Job = $DB_DShell->prepare("SELECT `host_id`, `command_set_id`, `status`
	FROM `jobs`
	WHERE `id` = ?
");
$Select_Job->execute($Job_ID);
my ($Host_ID, $Command_Set_ID, $Status) = $Select_Job->fetchrow_array();

my $Select_Host = $DB_IP_Allocation->prepare("SELECT `hostname`
	FROM `hosts`
	WHERE `id` = ?
");
$Select_Host->execute($Host_ID);
my ($Host) = $Select_Host->fetchrow_array();

my $Select_Commands = $DB_DShell->prepare("SELECT `name`, `command`
	FROM `command_sets`
	WHERE `id` = ?
");
$Select_Commands->execute($Command_Set_ID);
my ($Command_Name, $Commands) = $Select_Commands->fetchrow_array();

if ($Verbose) {
	print "${Green}Looking at Job ID ${Blue}$Job_ID${Green}, I've discovered:\n${Yellow}Host: ${Blue}$Host\n${Yellow}Status ID: ${Blue}$Status\n${Yellow}Command Set Name: ${Blue}$Command_Name\n${Yellow}${Red}### ${Yellow}Commands Start ${Red}###\n${Blue}$Commands\n${Red}### ${Yellow}Commands End ${Red}###${Clear}\n";
}


if ($Status == 0) {
	if ($Override) {
		print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed. Override is enabled, so we're running it again!${Clear}\n";
	}
	else {
		print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed. Override is NOT enabled, so we won't run it again! Exiting...${Clear}\n";
		exit(1);
	}
}
if ($Status == 1) {
	if ($Override) {
		print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running. Override is enabled, so we're running a second copy!${Clear}\n";
	}
	else {
		print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running. Override is NOT enabled, so we won't run a second copy! Exiting...${Clear}\n";
		exit(1);
	}
}
if ($Status == 2) {
	print "${Green}Job ID ${Blue}$Job_ID${Green} is paused. Continuing job from the last ran command...${Clear}\n";
}
if ($Status == 3) {
	if ($Override) {
		print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has been stopped manually. Override is enabled, so we're starting it again!${Clear}\n";
	}
	else {
		print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has been stopped manually. Override is NOT enabled, so we won't start it again! Exiting...${Clear}\n";
		exit(1);
	}
}
if ($Status == 4) {
	print "${Green}Job ID ${Blue}$Job_ID${Green} is pending. Starting job...${Clear}\n";
}

	my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job->execute( '1', 'System', $Job_ID);
	
my $Log_File = "/tmp/$Job_ID";
$Host = 'schofieldbj';

my $SSH = Net::SSH::Expect->new (
	host => $Host,
	user => 'schofieldbj',
	password=> 'qwePOI123!',
	log_file => $Log_File,
	timeout => 1,
	exp_internal => $Very_Verbose,
	exp_debug => 0,
	raw_pty => 1
);

my $Login = $SSH->login(10);
if ($Login !~ /Last/) {
	print "Could not login to $Host. Output was: $Login\n";
}

#$SSH->exec("stty raw -echo"); # Shows all remote command outputs on local console
$SSH->timeout(1);

	my $Start_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
	system("echo 'Job ended at $Start_Time.' >> $Log_File");

my @Commands = split('\r', $Commands);

foreach my $Command (@Commands) {
	$Command =~ s/\n//;
	$Command =~ s/\r//;

	my $Time_Stamp = strftime "%H:%M:%S", localtime;

	my $Job_Status_Update = $DB_DShell->prepare("INSERT INTO `job_status` (
		`job_id`,
		`command`,
		`output`,
		`task_started`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, NOW(), ?
	)");

	$Job_Status_Update->execute($Job_ID, $Command, 'Currently Running...', 'System');
	my $Job_Status_Update_ID = $DB_DShell->{mysql_insertid};		

	while ( defined (my $Line = $SSH->read_all()) ) {
		# Do nothing! Clearing the input stream for the next command
	} 

	my $Command_Output;
	my $Exit_Code;
	if (($Command =~ /^#/) || ($Command eq undef)) {
		if ($Verbose == 1) {
			#system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Skipping comment/empty line ${Blue}$Command${Clear}\n' >> $Log_File");
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Skipping comment/empty line ${Blue}$Command${Clear}\n";
		}
		$Command_Output = 'Skipped comment / empty line.';
		$Exit_Code = 0;
	}
	elsif ($Command =~ /^\*PAUSE.*/) {
		my $Pause = $Command;
		$Pause =~ s/\*PAUSE (.*)/$1/;
		if ($Verbose == 1) {
			#system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Pausing for ${Blue}$Pause ${Green}seconds on $Host${Clear}\n' >> $Log_File");
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Pausing for ${Blue}$Pause ${Green}seconds on $Host${Clear}\n";
			}
		sleep $Pause;
		$Command_Output = "Paused for $Pause seconds.";
		$Exit_Code = 0;
	}
	elsif ($Command =~ /^\*WAITFOR.*/) {
		my $Wait_Timeout = 600;
		my $Wait = $Command;
		if ($Wait =~ m/^\*WAITFOR\d/) {
			$Wait_Timeout = $Wait;
			$Wait_Timeout =~ s/^\*WAITFOR(\d*) (.*)/$1/;
			$Wait =~ s/^\*WAITFOR(\d*) (.*)/$2/;
		}
		else {
			$Wait =~ s/\*WAITFOR (.*)/$1/;
		}

		if ($Verbose == 1) {
			#system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Waiting for the prompt ${Yellow}$Wait ${Green}for ${Blue}$Wait_Timeout ${Green}seconds on $Host${Clear}\n' >> $Log_File");
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Waiting for the prompt ${Yellow}$Wait ${Green}for ${Blue}$Wait_Timeout ${Green}seconds on $Host${Clear}\n";
		}
		my $Match;
		while ( defined (my $Line = $SSH->read_line()) ) {
			$Match = $SSH->waitfor(".*$Wait.*", $Wait_Timeout, '-re');
			if ($Match) {
				if ($Verbose == 1) {
					$Time_Stamp = strftime "%H:%M:%S", localtime;
					#system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found match for ${Yellow}$Wait ${Green}on $Host${Clear}\n' >> $Log_File");
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found match for ${Yellow}$Wait ${Green}on $Host${Clear}\n";
				}
				$Command_Output = "$Wait Match Found!";
				$Exit_Code = 0;
			}
			else {
				#system("echo '${Red}No match for '$Wait' after $Wait_Timeout seconds. Closing the SSH session for $Host.${Clear}\n' >> $Log_File");
				print "${Red}No match for '$Wait' after $Wait_Timeout seconds. Closing the SSH session for $Host.${Clear}\n";
				$Command_Output = "$Wait Match NOT Found!";
				$Exit_Code = 1;
				$SSH->close();
			}
		}
	}
	elsif ($Command =~ /^\*SEND.*/) {
		my $Send = $Command;
		$Send =~ s/\*SEND (.*)/$1/;
		if ($Verbose == 1) {
			#system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Sending ${Yellow}$Send ${Green}to $Host${Clear}\n' >> $Log_File");
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Sending ${Yellow}$Send ${Green}to $Host${Clear}\n";
		}
		$SSH->send($Send);
		$Command_Output = "$Send sent.";
		$Exit_Code = 0;

	}
	else {
		if ($Verbose == 1) {
			#system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Command ${Green}on $Host${Clear}\n' >> $Log_File");
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Command ${Green}on $Host${Clear}\n";
		}

		$Command_Output = $SSH->exec($Command, $Command_Timeout);
		$Command_Output=~ s/\n\e.*//g;
		$Command_Output=~ s/\e.*//g;
		$Exit_Code = $SSH->exec('echo $?', $Command_Timeout);
		$Exit_Code =~ s/[^0-9+]//g;
		$Exit_Code =~ s/.$//;
		if ($Exit_Code) {
			if ($Verbose) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## Exit code for ${Yellow}$Command${Red}: ${Blue}$Exit_Code${Clear}\n";
			}
		}
		else {
			if ($Verbose) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Exit code for ${Yellow}$Command${Green}: ${Blue}$Exit_Code${Clear}\n";
			}
		}
	}

	my $Update_Job_Status = $DB_DShell->prepare("UPDATE `job_status` SET
		`exit_code` = ?,
		`output` = ?,
		`task_ended` = NOW(),
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job_Status->execute($Exit_Code, $Command_Output, 'System', $Job_Status_Update_ID);



}
			
$SSH->close();

$Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
	`status` = ?,
	`modified_by` = ?
	WHERE `id` = ?");
$Update_Job->execute( '0', 'System', $Job_ID);

my $End_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
system("echo 'Job ended at $End_Time.' >> $Log_File");
	
1;