#!/usr/bin/perl

use strict;
use Net::SSH::Expect;
use POSIX qw(strftime);

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Short_Name = System_Short_Name();
my $Version = Version();
my $DB_DShell = DB_DShell();
my $DShell_Job_Log_Location = DShell_Job_Log_Location();
my $DB_IP_Allocation = DB_IP_Allocation();
my $Override = 0;
my $Verbose = 0;
my $Very_Verbose = 0;
my $Ignore_Bad_Exit_Code = 0;
#my $Command_Timeout = 180;
my $Command_Timeout = 5;

$0 = 'D-Shell';
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
	${Blue}-p, --parent\t\t${Green}Pass the Job ID of the highest parent (only used with dependencies)
	${Blue}-c, --commandset\t${Green}Pass the Command Set ID for the dependent process (only used with dependencies)
	${Blue}-H, --host\t\t${Green}Pass the Host ID for the dependent process (only used with dependencies)
	${Blue}-d, --dependencychain\t${Green}Pass the dependency chain ID (only used with dependencies)
	${Blue}-u, --user\t\t${Green}Pass the user that'll execute the job on the remote system
	${Blue}-v, --verbose\t\t${Green}Turns on verbose output (useful for debug)
	${Blue}-V, --very-verbose\t${Green}Same as verbose, but also includes _LOTS_ of debug (I did warn you)
	${Blue}--override\t\t${Green}Override the lock for Complete or Stopped jobs

${Green}Examples:
	${Green}## Run a job
	${Blue}./d-shell.pl -j 643 -u ben${Clear}

	${Green}## Run a job dependency
	${Blue}./d-shell.pl -p 643 -c 542 -H 435 -d 2 -u ben${Clear}\n\n";


if (!@ARGV) {
	print $Help;
	exit(0);
}

my $Discovered_Job_ID;
my $Parent_ID;
my $Dependent_Command_Set_ID;
my $Dependent_Host_ID;
my $Dependency_Chain_ID;
my $User_Name;
my $User_Password;
foreach my $Parameter (@ARGV) {
	if ($Parameter eq '-v' || $Parameter eq '--verbose') {
		$Verbose = 1;
		print "${Red}## ${Green}Verbose is on (PID: $$).${Clear}\n";
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
		while ($Discovered_Job_ID = shift @Job) {
			if ($Discovered_Job_ID =~ /-j/ || $Discovered_Job_ID =~ /--job/) {
				$Discovered_Job_ID = shift @Job;
				last;
			}
		}
	}
	if ($Parameter eq '-u' || $Parameter eq '--user') {
		my @User = @ARGV;
		while ($User_Name = shift @User) {
			if ($User_Name =~ /-u/ || $User_Name =~ /--user/) {
				$User_Name = shift @User;
				last;
			}
		}
	}
	if ($Parameter eq '-p' || $Parameter eq '--parent') {
		my @Parent = @ARGV;
		while ($Parent_ID = shift @Parent) {
			if ($Parent_ID =~ /-p/ || $Parent_ID =~ /--parent/) {
				$Parent_ID = shift @Parent;
				last;
			}
		}
	}
	if ($Parameter eq '-c' || $Parameter eq '--commandset') {
		my @Dependent_Command_Set = @ARGV;
		while ($Dependent_Command_Set_ID = shift @Dependent_Command_Set) {
			if ($Dependent_Command_Set_ID =~ /-c/ || $Dependent_Command_Set_ID =~ /--commandset/) {
				$Dependent_Command_Set_ID = shift @Dependent_Command_Set;
				last;
			}
		}
	}
	if ($Parameter eq '-H' || $Parameter eq '--host') {
		my @Dependent_Host = @ARGV;
		while ($Dependent_Host_ID = shift @Dependent_Host) {
			if ($Dependent_Host_ID =~ /-H/ || $Dependent_Host_ID =~ /--host/) {
				$Dependent_Host_ID = shift @Dependent_Host;
				last;
			}
		}
	}
	if ($Parameter eq '-d' || $Parameter eq '--dependencychain') {
		my @Dependency_Chain = @ARGV;
		while ($Dependency_Chain_ID = shift @Dependency_Chain) {
			if ($Dependency_Chain_ID =~ /-d/ || $Dependency_Chain_ID =~ /--dependencychain/) {
				$Dependency_Chain_ID = shift @Dependency_Chain;
				last;
			}
		}
	}
	if ($Parameter eq '-P' || $Parameter eq '--password') {
		my @Password = @ARGV;
		while ($User_Password = shift @Password) {
			if ($User_Password =~ /-P/ || $User_Password =~ /--dependencychain/) {
				$User_Password = shift @Password;
				last;
			}
		}
	}
}

my $Top_Level_Job;
if (!$Parent_ID) {
	$Top_Level_Job = 1;
	$Parent_ID = $Discovered_Job_ID;
}
if (!$Dependency_Chain_ID) {
	$Dependency_Chain_ID = 0;
}
my $DShell_Job_Log_File = "$DShell_Job_Log_Location/$Parent_ID-$Dependency_Chain_ID";

if ((!$Discovered_Job_ID && !$Dependent_Command_Set_ID) || !$User_Name) {
	print "Something went wrong. Did you pass a Job ID or a Command Set and a User Name?\n";
	exit(1);
}
if (!defined $User_Password) {
	use Term::ReadKey;
	ReadMode 4; # noecho TTY mode
	print "Password for $User_Name:";
	$User_Password = <STDIN>;
	ReadMode 0; # Reset TTY mode
}

if (!defined $User_Name) {
	print "${Red}## User Name not caught. Exiting... (PID: $$).${Clear}\n";
	my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job->execute( '8', $User_Name, $Parent_ID);
	exit(1);
}
if (!defined $User_Password) {
	print "${Red}## Password not caught (User Name was $User_Name). Exiting... (PID: $$).${Clear}\n";
	my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job->execute( '9', $User_Name, $Parent_ID);
	exit(1);
}

if (!$Dependent_Command_Set_ID && $Discovered_Job_ID) {
	print "\n${Green}Starting Job ID ${Blue}$Discovered_Job_ID${Green} as User ${Blue}$User_Name${Green}...${Clear}\n";
	print "${Red}## ${Green}Discovered Job ID ${Blue}$Discovered_Job_ID${Green} (PID: $$).${Clear}\n";
	my ($Host_ID, $Command_Set_ID) = &job_discovery($Discovered_Job_ID);
	print "${Red}## ${Green}Discovered Host ID ${Blue}$Host_ID${Green} and Command Set ID ${Blue}$Command_Set_ID${Green} (PID: $$).${Clear}\n";
	my $Host = &host_discovery($Host_ID);
	print "${Red}## ${Green}Discovered Host ${Blue}$Host${Green} (PID: $$).${Clear}\n";
	my $Connected_Host = &host_connection($Host);
	my $Job_Processor = &processor($Host_ID, $Connected_Host, $Command_Set_ID);
	
}
elsif (!$Discovered_Job_ID && $Dependent_Command_Set_ID) {
	print "\n${Green}Starting dependent Command Set ID ${Blue}$Dependent_Command_Set_ID${Green} as User ${Blue}$User_Name${Green}...${Clear}\n";
	print "${Red}## ${Green}Discovered Host ID ${Blue}$Dependent_Host_ID${Green} and Command Set ID ${Blue}$Dependent_Command_Set_ID${Green} (Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green}, PID: $$).${Clear}\n";
	my $Host = &host_discovery($Dependent_Host_ID);
	print "${Red}## ${Green}Discovered Host ${Blue}$Host${Green} (Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green}, PID: $$).${Clear}\n";
	my $Connected_Host = &host_connection($Host);
	my $Dependency_Processor = &processor($Dependent_Host_ID, $Connected_Host, $Dependent_Command_Set_ID);
}
else {
	print "${Red}## Did you read the manual or help? Shitting pants and exiting (PID: $$).${Clear}\n";
	exit(1);
}
	

sub job_discovery {

	my $Job_ID = $_[0];

	my $Select_Job = $DB_DShell->prepare("SELECT `host_id`, `command_set_id`, `status`
		FROM `jobs`
		WHERE `id` = ?
	");
	$Select_Job->execute($Job_ID);
	my ($Host_ID, $Command_Set_ID, $Status) = $Select_Job->fetchrow_array();
	my $Job_Exists = $Select_Job->rows();

	if ($Job_Exists == 0) {
		print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} was not found.${Clear}\n";
		exit(0);
	}
	if ($Status == 0) {
		if ($Override) {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed. Override is enabled, so we're running it again!${Clear}\n";
			my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
				`status` = ?,
				`modified_by` = ?
				WHERE `id` = ?");
			$Update_Job->execute( '1', $User_Name, $Parent_ID);
		}
		else {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed. Override is NOT enabled, so we won't run it again! Exiting...${Clear}\n";
			exit(0);
		}
	}
	if ($Status == 1) {
		if ($Override) {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running. Override is enabled, so we're running a second copy!${Clear}\n";
			my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
				`status` = ?,
				`modified_by` = ?
				WHERE `id` = ?");
			$Update_Job->execute( '1', $User_Name, $Parent_ID);
		}
		else {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running. Override is NOT enabled, so we won't run a second copy! Exiting...${Clear}\n";
			exit(0);
		}
	}
	if ($Status == 2) {
		print "${Green}Job ID ${Blue}$Job_ID${Green} is paused. Continuing job from the last ran command...${Clear}\n";
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute( '1', $User_Name, $Parent_ID);
	}
	if ($Status == 4 || $Status == 10) {
		print "${Green}Job ID ${Blue}$Job_ID${Green} is pending. Starting job...${Clear}\n";
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute( '1', $User_Name, $Parent_ID);
	}
	if ($Status == 3 || $Status == 5 || $Status == 6 || $Status == 7 || $Status == 8 || $Status == 9 || $Status == 11) {
		print "${Green}Job ID ${Blue}$Job_ID${Green} was stopped. Restarting job...${Clear}\n";
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute( '1', $User_Name, $Parent_ID);
	}

	my @Job_Data = ($Host_ID, $Command_Set_ID);
	return @Job_Data;

} # sub job_discovery

sub host_discovery {

	my $Host_ID = $_[0];

	my $Select_Host = $DB_IP_Allocation->prepare("SELECT `hostname`
		FROM `hosts`
		WHERE `id` = ?
	");
	$Select_Host->execute($Host_ID);
	my ($Host) = $Select_Host->fetchrow_array();

	return $Host;

} # sub host_discovery

sub host_connection {

	my $Host = $_[0];
	my $SSH;
	my $Retry_Count = 0;
	my $Max_Retry_Count = 10;
	my $Connection_Timeout = 2;

	my $Hello;
	while (1) {

		$SSH = Net::SSH::Expect->new (
			host => $Host,
			user => $User_Name,
			password=> $User_Password,
			log_file => $DShell_Job_Log_File,
			timeout => $Connection_Timeout,
			exp_internal => $Very_Verbose,
			exp_debug => 0,
			raw_pty => 1,
			restart_timeout_upon_receive => 1
		);
		$SSH->login();
		sleep 1;


		#my $Hello = eval{$SSH->login();};
		my $Test_Command = 'id';
		my $ID_Command_Timeout = 1;
		$Hello = $SSH->exec($Test_Command, $ID_Command_Timeout);
	
		last if $Hello =~ m/uid/;
		last if $Retry_Count >= $Max_Retry_Count;
		if ($Hello =~ m/Permission denied/) {
			print "Supplied credentials failed. Terminating the job.\n";
			my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
			$Update_Job->execute( '6', $User_Name, $Parent_ID);
			exit(1);
		}
	
		my $Connection_Timeout_Plus = $Connection_Timeout;
		if ($Verbose && $Retry_Count > 0) {
			print "Tried to connect to $Host with $Connection_Timeout second timeout but failed. Timeout increased to $Connection_Timeout_Plus, trying again (attempt $Retry_Count of $Max_Retry_Count)...\n";
		}
		$Retry_Count++;
		$Connection_Timeout_Plus += 2;
		$Connection_Timeout = $Connection_Timeout_Plus;
	
	}
	
	if ($Retry_Count >= $Max_Retry_Count) {
		print "Couldn't connect to $Host after $Retry_Count attempts. Terminating the job.\n";
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		$Update_Job->execute( '5', $User_Name, $Parent_ID);
		exit(1);
	}

	#$SSH->exec("stty raw -echo");
	$SSH->timeout(5);

	return $SSH;

} # sub host_connection

sub processor {

	my ($Host_ID, $Connected_Host, $Process_Command_Set_ID) = @_;

	## Discover dependencies
	my $Discover_Dependencies = $DB_DShell->prepare("SELECT `dependent_command_set_id`
		FROM `command_set_dependency`
		WHERE `command_set_id` = ?
		ORDER BY `order` ASC
	");
	$Discover_Dependencies->execute($Process_Command_Set_ID);
	
	while ( my $Command_Set_Dependency_ID = $Discover_Dependencies->fetchrow_array() ) {
		$Dependency_Chain_ID++;
		my ($Verbose_Switch, $Very_Verbose_Switch);
		if ($Verbose) {$Verbose_Switch = '-v '}
		if ($Very_Verbose) {$Very_Verbose_Switch = '-V '}
		print "${Green}I've discovered that Command Set ID ${Blue}$Process_Command_Set_ID${Green} is dependent on Command Set ID ${Blue}$Command_Set_Dependency_ID${Green}. Processing Command Set ID ${Blue}$Command_Set_Dependency_ID${Green} as dependency ${Blue}$Dependency_Chain_ID${Green}. ${Clear}\n";
		print "${Green}Executing: ${Blue}./d-shell.pl ${Verbose_Switch}${Very_Verbose_Switch}-p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -u $User_Name${Clear}\n";
		my $System_Exit_Code = system "./d-shell.pl ${Verbose_Switch}${Very_Verbose_Switch}-p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -u $User_Name -P $User_Password";
		if ($System_Exit_Code == 0) {
			print "${Green}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green} execution complete. Exit code was $System_Exit_Code.${Clear}\n";
		}
		else {
			print "${Red}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Red} execution complete. Exit code was $System_Exit_Code. Exiting :-(${Clear}\n";
			exit(1);
		}
	}

	## Discover Commands
	my $Select_Commands = $DB_DShell->prepare("SELECT `name`, `command`
		FROM `command_sets`
		WHERE `id` = ?
	");
	$Select_Commands->execute($Process_Command_Set_ID);
	my ($Command_Name, $Commands) = $Select_Commands->fetchrow_array();



	if ($Top_Level_Job) {
		my $Update_Job_Status = $DB_DShell->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`output`,
			`task_started`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, NOW(), ?
		)");
	
		$Update_Job_Status->execute($Parent_ID, "### Main job, $Command_Name, started.", '', 'System');
		my $Start_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
		system("echo 'Job started at $Start_Time.' >> $DShell_Job_Log_File");
	}
	else {
		my $Update_Job_Status = $DB_DShell->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`output`,
			`task_started`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, NOW(), ?
		)");
	
		$Update_Job_Status->execute($Parent_ID, "### Dependency Set $Dependency_Chain_ID, $Command_Name, started.", '', 'System');
		my $Start_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
		system("echo 'Dependency Set $Dependency_Chain_ID, $Command_Name, started at $Start_Time.' >> $DShell_Job_Log_File");
	}



	my @Commands = split('\r', $Commands);

	foreach my $Command (@Commands) {
		$Command =~ s/\n//;
		$Command =~ s/\r//;

		my $Job_Paused;
		while ($Job_Paused ne 'No') {
			my $Query_Control_Status = $DB_DShell->prepare("SELECT `status`, `modified_by`
				FROM `jobs`
				WHERE `id` = ?
			");
			$Query_Control_Status->execute($Parent_ID);

			my ($Query_Status, $Query_Modified_By) = $Query_Control_Status->fetchrow_array();
			if ($Query_Status == 2) {
				print "${Green}Job paused by $Query_Modified_By.${Clear}\n";
				$Job_Paused = 'Yes';
			}
			else {
				$Job_Paused = 'No';
			}
			if ($Query_Status == 3) {
				print "${Red}Job killed by $Query_Modified_By. Terminating job.${Clear}\n";
				my $End_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
				system("echo 'Job killed at $End_Time by $Query_Modified_By.' >> $DShell_Job_Log_File");
				exit(0);
			}
		}

		my $Predictable_Prompt = $System_Short_Name;
			$Predictable_Prompt =~ s/\s//g;
		my $Set_Predictable_Prompt = "PS1=[$Predictable_Prompt]";

		my $Time_Stamp = strftime "%H:%M:%S", localtime;
	
		my $Update_Job_Status = $DB_DShell->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`output`,
			`task_started`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, NOW(), ?
		)");
	
		$Update_Job_Status->execute($Parent_ID, $Command, 'Currently Running...', 'System');
		my $Job_Status_Update_ID = $DB_DShell->{mysql_insertid};		
	
#		while ( defined (my $Line = $SSH->read_all()) ) {
#			Do nothing! Clearing the input stream for the next command
#		} 
	
		my $Command_Output;
		my $Exit_Code = 7;
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
				#system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Pausing for ${Blue}$Pause ${Green}seconds on $Connected_Host${Clear}\n' >> $Log_File");
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Pausing for ${Blue}$Pause ${Green}seconds${Clear}\n";
			}
			sleep $Pause;
			$Command_Output = "Paused for $Pause seconds.";
			$Exit_Code = 0;
		}
		elsif ($Command =~ /^\*VSNAPSHOT.*/) {
			my $Snapshot = $Command;
			$Snapshot =~ s/\*VSNAPSHOT (.*)/$1/;
			if ($Verbose == 1) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Performing a snapshot operation${Clear}\n";
			}
			elsif ($Snapshot eq 'COUNT') {
				if ($Verbose == 1) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Counting snapshots${Clear}\n";
				}
				$Command_Output = `./vmware-snapshot.pl -c -i $Host_ID`;
				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error counting snapshots. $Exit_Code";
				}
			}
			elsif ($Snapshot eq 'TAKE') {
				if ($Verbose == 1) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Taking a snapshot${Clear}\n";
				}
				$Command_Output = `./vmware-snapshot.pl -s -i $Host_ID`;
				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error taking a snapshot. $Exit_Code";
				}
				sleep 300;
			}
			elsif($Snapshot eq 'REMOVE') {
				if ($Verbose == 1) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing $System_Short_Name snapshots${Clear}\n";
				}
				$Command_Output = `./vmware-snapshot.pl -r -i $Host_ID`;
				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error removing $System_Short_Name snapshots. $Exit_Code";
				}
			}
			elsif($Snapshot eq 'REMOVEALL') {
				if ($Verbose == 1) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing ALL snapshots${Clear}\n";
				}
				$Command_Output = `./vmware-snapshot.pl -e -i $Host_ID`;
				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error removing all snapshots. $Exit_Code";
				}
			}
			else {
				$Command_Output = "Found that you wanted to perform a snapshot operation. Couldn't determine exactly what. Perhaps you misspelt an option.";
				$Exit_Code = 1;
			}
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
				#system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Waiting for the prompt ${Yellow}$Wait ${Green}for ${Blue}$Wait_Timeout ${Green}seconds on $Connected_Host${Clear}\n' >> $Log_File");
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Waiting for the prompt ${Yellow}$Wait ${Green}for ${Blue}$Wait_Timeout ${Green}seconds${Clear}\n";
			}
			my $Match;
			LINEFEED: while ( defined (my $Line = $Connected_Host->read_line()) ) {
				$Match = $Connected_Host->waitfor(".*$Wait.*", $Wait_Timeout, '-re');
				if ($Match) {
					if ($Verbose == 1) {
						$Time_Stamp = strftime "%H:%M:%S", localtime;
						#system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found match for ${Yellow}$Wait ${Green}on $Connected_Host${Clear}\n' >> $Log_File");
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found match for ${Yellow}$Wait${Clear}\n";
					}
					$Command_Output = "$Wait Match Found!";
					$Exit_Code = 0;
				}
				else {
					system("echo '${Red}No match for '$Wait' after $Wait_Timeout seconds. Closing the SSH session.${Clear}\n' >> $DShell_Job_Log_File");
					print "${Red}No match for '$Wait' after $Wait_Timeout seconds. Closing the SSH session.${Clear}\n";
					$Command_Output = "$Wait Match NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_File.";
					$Exit_Code = 7;
					last LINEFEED;
				}
			}
			if ($Exit_Code != 0) {
				my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
				$Update_Job->execute( $Exit_Code, $User_Name, $Parent_ID);
				my $Update_Job_Status = $DB_DShell->prepare("UPDATE `job_status` SET
					`exit_code` = ?,
					`output` = ?,
					`task_ended` = NOW(),
					`modified_by` = ?
					WHERE `id` = ?");
				$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);
				print "${Red}No match for '$Wait' after $Wait_Timeout seconds. Bailing out!${Clear}\n"; 
				$Connected_Host->close();
				exit(1);
			}
		}
		elsif ($Command =~ /^\*SEND.*/) {
			my $Send = $Command;
			$Send =~ s/\*SEND (.*)/$1/;
			if ($Verbose == 1) {
				#system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Sending ${Yellow}$Send ${Green}to $Connected_Host${Clear}\n' >> $Log_File");
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Sending '${Yellow}$Send${Green}'${Clear}\n";
			}
			if ($Send eq '') {$Send = ' '}
			$Connected_Host->send($Send);
			$Command_Output = "'$Send' sent.";
			$Exit_Code = 0;
		}
		else {
			if ($Verbose == 1) {
				#system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Command ${Green}on $Connected_Host${Clear}\n' >> $Log_File");
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Command${Clear}\n";
			}
			while ( defined (my $Line = $Connected_Host->read_all()) ) {
				#Do nothing! Clearing the input stream for the next command
			} 
			# Set a predictable prompt every time so that we can filter it even if the remote system changes it after a command (such as switching user).

			my $Set_Prompt_Timeout = 1;
			$Connected_Host->exec($Set_Predictable_Prompt, $Set_Prompt_Timeout);

			$Command_Output = $Connected_Host->exec($Command, $Command_Timeout);
			$Command_Output =~ s/\n\e.*//g; # Clears newlines, escapes (ESC)
			$Command_Output =~ s/\e.*//g;
			$Command_Output =~ s/^$Command//;
			$Command_Output =~ s/.*\r//g;
			my $Exit_Code_Timeout = 1;
			$Exit_Code = $Connected_Host->exec('echo $?', $Exit_Code_Timeout);
			$Exit_Code =~ s/[^0-9+]//g;
			#$Exit_Code =~ s/.$//; # Uncomment this when running from command line
			if ($Exit_Code) {
				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## Exit code for ${Yellow}$Command${Red}: ${Blue}$Exit_Code${Clear}\n";
				}
				my $Select_Failure_Action = $DB_DShell->prepare("SELECT `on_failure`
					FROM `jobs`
					WHERE `id` = ?
				");
				$Select_Failure_Action->execute($Parent_ID);
				my ($On_Failure) = $Select_Failure_Action->fetchrow_array();

				if ($On_Failure) {
					$Update_Job_Status = $DB_DShell->prepare("UPDATE `job_status` SET
						`exit_code` = ?,
						`output` = ?,
						`task_ended` = NOW(),
						`modified_by` = ?
						WHERE `id` = ?");
					$Command_Output =~ s/\[$Predictable_Prompt\]//g;
					$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);
					my $Update_Job_Status = $DB_DShell->prepare("INSERT INTO `job_status` (
						`job_id`,
						`command`,
						`output`,
						`task_ended`,
						`modified_by`
					)
					VALUES (
						?, ?, ?, NOW(), ?
					)");
					$Update_Job_Status->execute($Parent_ID, "### Last action failed. On failure set to kill. Killing job.", '', 'System');
					my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
						`status` = ?,
						`modified_by` = ?
						WHERE `id` = ?");
					$Update_Job->execute( '11', $User_Name, $Parent_ID);
					exit($Exit_Code);
				}
			}
			else {
				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Exit code for ${Yellow}$Command${Green}: ${Blue}$Exit_Code${Clear}\n";
				}

			}
		}
	
		$Command_Output =~ s/\[$Predictable_Prompt\]//g;
		$Update_Job_Status = $DB_DShell->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);
	
	}

	$Connected_Host->close();

	if ($Top_Level_Job) {
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute( '0', $User_Name, $Parent_ID);
		my $Update_Job_Status = $DB_DShell->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`output`,
			`task_ended`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, NOW(), ?
		)");
	
		$Update_Job_Status->execute($Parent_ID, "### Main job, $Command_Name, complete.", '', 'System');
		my $End_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
		system("echo 'Job completed at $End_Time.' >> $DShell_Job_Log_File");
	}
	else {
		my $Update_Job_Status = $DB_DShell->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`output`,
			`task_ended`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, NOW(), ?
		)");

		$Update_Job_Status->execute($Parent_ID, "### Dependency Set $Dependency_Chain_ID, $Command_Name, complete.", '', 'System');
		my $End_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
		system("echo 'Dependency Set ID $Dependency_Chain_ID, $Command_Name, ended at $End_Time.' >> $DShell_Job_Log_File");
	}


} # sub processor

1;