#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);

use Net::SSH::Expect;
use POSIX qw(strftime);
use Getopt::Long qw(:config no_auto_abbrev no_ignore_case_always);

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Short_Name = System_Short_Name();
my $Verbose = Verbose();
my $Very_Verbose = Very_Verbose();
my $Paper_Trail = Paper_Trail();
my $Version = Version();
my $DB_Connection = DB_Connection();
my $DShell_Job_Log_Location = DShell_Job_Log_Location();
	my $Log_Retention;
my $DShell_tmp_Location = DShell_tmp_Location();
my $nmap = nmap();
my $grep = sudo_grep();
my $Override = 0;
my $No_Decode;
my $Wait_Timeout = DShell_WaitFor_Timeout();
my $DShell_Queue_Execution_Cap = DShell_Queue_Execution_Cap();
my $Retry_Count = 0;
my $Max_Retry_Count = 10;
my $Connection_Timeout = 5;
my $Reboot_Retry_Count = 0;
my $Reboot_Max_Retry_Count = 20;
my $Reboot_Connection_Timeout = 5;
my $Max_Attempts = 10;
my $Reboot_Max_Attempts = 1200;
my $System_Is_Windows;

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
	${Blue}-j, --job\t\t ${Green}Pass the Job ID to be executed
	${Blue}-p, --parent\t\t ${Green}Pass the Job ID of the highest parent (only used with dependencies)
	${Blue}-c, --command-set\t ${Green}Pass the Command Set ID for the dependent process (only used with dependencies)
	${Blue}-H, --host\t\t ${Green}Pass the Host ID for the dependent process (only used with dependencies)
	${Blue}-d, --dependency-chain\t ${Green}Pass the dependency chain ID (only used with dependencies)
	${Blue}-u, --user\t\t ${Green}Pass the user that'll execute the job on the remote system (only used without keys)
	${Blue}-k, --key\t\t ${Green}Pass the key ID used to connect to the server
	${Blue}-r, --runtime-variable ${Green}Pass a real time variable (e.g. -r MySQLPassword=bla -r IP=blabla)
	${Blue}-v, --verbose\t\t ${Green}Turns on verbose output (useful for debug)
	${Blue}-V, --very-verbose\t ${Green}Same as verbose, but also includes _LOTS_ of debug (I did warn you)
	${Blue}--override\t\t ${Green}Override the lock for Complete or Stopped jobs
	${Blue}--high-priority\t\t ${Green}Queues the Job but ignores the position and executes immediately
	${Blue}--no-colour\t\t ${Green}Strips colour from verbose output

${Green}Examples:
	${Green}## Run a job
	${Blue}$0 -j 643 -u ben${Clear}

	${Green}## Run a job dependency
	${Blue}$0 -p 643 -c 542 -H 435 -d 2 -u ben${Clear}\n\n";


if (!@ARGV) {
	print $Help;
	exit(0);
}

my $Predictable_Prompt = $System_Short_Name;
	$Predictable_Prompt =~ s/\s//g;
	$Predictable_Prompt = "%$Predictable_Prompt%";

my $Discovered_Job_ID;
my $Parent_ID;
my $Dependent_Command_Set_ID;
my $Dependent_Host_ID;
my $Dependency_Chain_ID;
my %Captured_Runtime_Variables;
	my %Runtime_Variables;
	my $Dependency_Runtime_Variables;
my $Captured_User_Name;
	my $User_Name = 'System';
my $Key_ID;
my $Captured_User_Password;
	my $User_Password;
my $Captured_Key;
my $Captured_Key_Lock;
	my $Key_Lock;
my $Captured_Key_Passphrase;
	my $Key_Passphrase;
my $High_Priority;
my $No_Colour;

GetOptions(
	'v' => \$Verbose,
	'verbose' => \$Verbose,
	'V' => \$Very_Verbose,
	'very-verbose' => \$Very_Verbose,
	'override' => \$Override,
	'D' => \$No_Decode,
	'no-dec' => \$No_Decode,
	'j=i' => \$Discovered_Job_ID,
	'job=i' => \$Discovered_Job_ID,
	'u:s' => \$Captured_User_Name,
	'user:s' => \$Captured_User_Name,
	'p:i' => \$Parent_ID,
	'parent:i' => \$Parent_ID,
	'c:i' => \$Dependent_Command_Set_ID,
	'command-set:i' => \$Dependent_Command_Set_ID,
	'H:i' => \$Dependent_Host_ID,
	'host:i' => \$Dependent_Host_ID,
	'd:i' => \$Dependency_Chain_ID,
	'dependency-chain:i' => \$Dependency_Chain_ID,
	'r=s%' => \%Captured_Runtime_Variables,
	'runtime-variable=s%' => \%Captured_Runtime_Variables,
	'P:s' => \$Captured_User_Password,
	'password:s' => \$Captured_User_Password,
	'k:i' => \$Captured_Key,
	'key:i' => \$Captured_Key,
	'L:s' => \$Captured_Key_Lock,
	'lock:s' => \$Captured_Key_Lock,
	'K:s' => \$Captured_Key_Passphrase,
	'passphrase:s' => \$Captured_Key_Passphrase,
	'high-priority' => \$High_Priority,
	'no-colour' => \$No_Colour
) or die("Fault with options: $@\n");

if ($No_Colour) {
	undef $Green;
	undef $Yellow;
	undef $Red;
	undef $Pink;
	undef $Blue;
	undef $Clear;
}

if ($Verbose) {
	if ($Verbose =~ /^([0-1]+)$/) {$Verbose = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Verbose, $User_Name);}
}
if ($Very_Verbose) {
	if ($Very_Verbose =~ /^([0-1]+)$/) {$Very_Verbose = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Very_Verbose, $User_Name);}
}
if ($Override) {
	if ($Override =~ /^([0-1]+)$/) {$Override = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Override, $User_Name);}
}
if ($No_Decode) {
	if ($No_Decode =~ /^([0-1])$/) {$No_Decode = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $No_Decode, $User_Name);}
}
if ($Discovered_Job_ID) {
	if ($Discovered_Job_ID =~ /^([0-9]+)$/) {$Discovered_Job_ID = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Discovered_Job_ID, $User_Name);}
}
if ($Captured_User_Name) {
	if ($Captured_User_Name =~ /^([0-9a-zA-Z\-\_\s]+)$/) {$Captured_User_Name = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_User_Name, $User_Name);}
}
if ($Parent_ID) {
	if ($Parent_ID =~ /^([0-9]+)$/) {$Parent_ID = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Parent_ID, $User_Name);}
}
if ($Dependent_Command_Set_ID) {
	if ($Dependent_Command_Set_ID =~ /^([0-9]+)$/) {$Dependent_Command_Set_ID = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Dependent_Command_Set_ID, $User_Name);}
}
if ($Dependent_Host_ID) {
	if ($Dependent_Host_ID =~ /^([0-9]+)$/) {$Dependent_Host_ID = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Dependent_Host_ID, $User_Name);}
}
if ($Dependency_Chain_ID) {
	if ($Dependency_Chain_ID =~ /^([0-9]+)$/) {$Dependency_Chain_ID = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Dependency_Chain_ID, $User_Name);}
}
if ($Captured_User_Password && !$No_Decode) {
	if ($Captured_User_Password =~ /^([0-9a-zA-Z=]+)$/) {$Captured_User_Password = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_User_Password, $User_Name);}
}
elsif ($Captured_User_Password && $No_Decode) {
	if ($Captured_User_Password =~ /^(.+)$/) {$Captured_User_Password = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_User_Password, $User_Name);}
}
if ($Captured_Key) {
	if ($Captured_Key =~ /^([0-9]+)$/) {$Captured_Key = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Key, $User_Name);}
}
if ($Captured_Key_Lock && !$No_Decode) {
	if ($Captured_Key_Lock =~ /^([0-9a-zA-Z=]+)$/) {$Captured_Key_Lock = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Key_Lock, $User_Name);}
}
elsif ($Captured_Key_Lock && $No_Decode) {
	if ($Captured_Key_Lock =~ /^(.+)$/) {$Captured_Key_Lock = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Key_Lock, $User_Name);}
}
if ($Captured_Key_Passphrase && !$No_Decode) {
	if ($Captured_Key_Passphrase =~ /^([0-9a-zA-Z=]+)$/) {$Captured_Key_Passphrase = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Key_Passphrase, $User_Name);}
}
elsif ($Captured_Key_Passphrase && $No_Decode) {
	if ($Captured_Key_Passphrase =~ /^(.+)$/) {$Captured_Key_Passphrase = $1;}
	else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Captured_Key_Passphrase, $User_Name);}
}


if ($Verbose) {
	print "${Red}## ${Green}Verbose is on (PID: $$).${Clear}\n";
}
if ($Very_Verbose) {$Verbose = 1; print "${Red}## ${Green}Very Verbose is on (PID: $$).${Clear}\n";};
if ($No_Decode) {print "${Red}## ${Green}Decode is off.${Clear}\n";}
if ($Override) {print "${Red}## ${Pink}Override is on.${Clear}\n";}
if ($Paper_Trail) {
	print "${Red}## ! ## Paper Trail is ON! 5 seconds to cancel ${Pink}(CTRL + C):${Clear}\n";
	print "${Pink}Logging all parameters (including credentials) in... 5${Clear}\r";
	sleep 1;
	print "${Red}Logging all parameters (including credentials) in... 4${Clear}\r";
	sleep 1;
	print "${Pink}Logging all parameters (including credentials) in... 3${Clear}\r";
	sleep 1;
	print "${Red}Logging all parameters (including credentials) in... 2${Clear}\r";
	sleep 1;
	print "${Pink}Logging all parameters (including credentials) in... 1${Clear}\r";
	sleep 1;
	print "${Red}## ! ## Logging all parameters (including credentials)!${Clear}\n";
}

if ($Captured_Key_Lock) {
	if (!$No_Decode) {$Key_Lock = dec($Captured_Key_Lock);} else {$Key_Lock = $Captured_Key_Lock;}
}
if ($Captured_Key_Passphrase) {
	if (!$No_Decode) {$Key_Passphrase = dec($Captured_Key_Passphrase);} else {$Key_Passphrase = $Captured_Key_Passphrase;}
}


if (%Captured_Runtime_Variables) {
	foreach my $Captured_Variable_Key (keys %Captured_Runtime_Variables) {

		my $Variable_Key = $Captured_Variable_Key;
		my $Variable_Value = $Captured_Runtime_Variables{$Captured_Variable_Key};

		if (!$No_Decode) {
			if ($Variable_Key =~ /^([0-9a-zA-Z\#\s]+)$/) {$Variable_Key = $1;}
			else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Variable_Key, $User_Name);}
			if ($Variable_Value =~ /^([0-9a-zA-Z\#\s]+)$/) {$Variable_Value = $1;}
			else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Variable_Value, $User_Name);}
		}
		else {
			if ($Variable_Key =~ /^(.+)$/) {$Variable_Key = $1;}
			else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Variable_Key, $User_Name);}
			if ($Variable_Value =~ /^(.+)$/) {$Variable_Value = $1;}
			else {Security_Notice('Input Data', $ENV{'REMOTE_ADDR'}, $0, $Variable_Value, $User_Name);}
		}

		$Dependency_Runtime_Variables = $Dependency_Runtime_Variables . " -r '${Variable_Key}'='${Variable_Value}'";

		if (!$No_Decode) {
			$Variable_Key =~ s/#Equals#/=/g;
			$Variable_Value =~ s/#Equals#/=/g;
			$Variable_Key = dec($Variable_Key);
			$Variable_Value = dec($Variable_Value);
		}

		$Runtime_Variables{$Variable_Key} = $Variable_Value;

	}
}

my $Top_Level_Job;
if (!$Parent_ID) {
	$Top_Level_Job = 1;
	$Parent_ID = $Discovered_Job_ID;
	$0 = "D-Shell [JobID $Parent_ID]";
}
if (!$Dependency_Chain_ID) {
	$Dependency_Chain_ID = 0;
}
else {
	$0 = "D-Shell [JobID $Parent_ID, ChainID $Dependency_Chain_ID]";
}

if (!$Discovered_Job_ID && !$Dependent_Command_Set_ID ) {
	print "Something went wrong. Did you pass a Job ID or a Command Set and a User Name?\n";
	exit(1);
}

if (!$Captured_User_Name && !$Captured_Key) {
	print "${Red}## User Name not caught. Exiting... (PID: $$).${Clear}\n";
	my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job->execute('8', $User_Name, $Parent_ID);
	exit(8);
}
else {
	$User_Name = $Captured_User_Name;
}

if ($Captured_User_Name && $Captured_Key) {
	print "${Red}## You cannot specify both interactive and key credentials, pick one. Exiting... (PID: $$).${Clear}\n";
	my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job->execute('16', $User_Name, $Parent_ID);
	exit(16);
}

if (!$Captured_User_Password && !$Captured_Key) {
	use Term::ReadKey;
	ReadMode 4; # noecho TTY mode
	print "Password for $User_Name:";
	$Captured_User_Password = <STDIN>;
	ReadMode 0; # Reset TTY mode
	$User_Password = $Captured_User_Password;
}
else {
	if (!$No_Decode) {
		$User_Password = dec($Captured_User_Password);
	}
	else {
		$User_Password = $Captured_User_Password;
	}
}

my $Host;
my $Host_Connection_IP_or_Hostname;
my $DShell_Job_Log_File = "$DShell_Job_Log_Location/$Parent_ID-$Dependency_Chain_ID-Log";
my $DShell_Transactional_File = "$DShell_Job_Log_Location/$Parent_ID-$Dependency_Chain_ID-Transactions";
open( LOG, ">$DShell_Job_Log_File" ) or die "Can't open $DShell_Job_Log_File";
if ($Verbose) {
	my $Immediate_Flush = select LOG;
	$| = 1;
	select $Immediate_Flush;
}

if ($Verbose && $Paper_Trail) {
	if ($Discovered_Job_ID) {print "${Red}## ${Green}Caught Job ID ${Yellow}$Discovered_Job_ID${Clear}\n"}
	if ($Captured_User_Name) {print "${Red}## ${Green}Caught User Name ${Yellow}$Captured_User_Name${Clear}\n"}
	if ($Parent_ID) {print "${Red}## ${Green}Caught Parent ID ${Yellow}$Parent_ID${Clear}\n"}
	if ($Dependent_Command_Set_ID) {print "${Red}## ${Green}Caught Dependent Command Set ID ${Yellow}$Dependent_Command_Set_ID${Clear}\n"}
	if ($Dependent_Host_ID) {print "${Red}## ${Green}Caught Dependent Host ID ${Yellow}$Dependent_Host_ID${Clear}\n"}
	if ($Dependency_Chain_ID) {print "${Red}## ${Green}Caught Dependency Chain ID ${Yellow}$Dependency_Chain_ID${Clear}\n"}
	if ($Captured_User_Password) {print "${Red}## ${Green}Caught User Password ${Yellow}$Captured_User_Password${Clear}\n"}
	if ($Captured_Key) {print "${Red}## ${Green}Caught Key ID ${Yellow}$Captured_Key${Clear}\n"}
	if ($Captured_Key_Lock) {print "${Red}## ${Green}Caught Key Lock ${Yellow}$Captured_Key_Lock${Clear}\n"}
	if ($Captured_Key_Passphrase) {print "${Red}## ${Green}Caught Key Passphrase ${Yellow}$Captured_Key_Passphrase${Clear}\n"}
	if (%Captured_Runtime_Variables) {
		my $CRTVs = scalar(keys %Captured_Runtime_Variables);
		print "${Red}## ${Green}Caught $CRTVs Captured Runtime Variables:${Clear}\n\n";
		foreach my $Variable_Key (keys %Captured_Runtime_Variables) {
			print "${Green}CRTV: ${Yellow}$Variable_Key${Clear}\n"; 
			print "${Green}Value: ${Yellow}" . $Captured_Runtime_Variables{$Variable_Key} . "${Clear}\n\n";
		}
	}
	if (%Runtime_Variables) {
		my $RTVs = scalar(keys %Runtime_Variables);
		print "${Red}## ${Green}Caught $RTVs Runtime Variables:${Clear}\n\n";
		foreach my $Variable_Key (keys %Runtime_Variables) {
			print "${Green}RTV: ${Yellow}$Variable_Key${Clear}\n"; 
			print "${Green}Value: ${Yellow}" . $Runtime_Variables{$Variable_Key} . "${Clear}\n\n";
		}
	}

	if ($Discovered_Job_ID) {print LOG "${Red}## ${Green}Caught Job ID ${Yellow}$Discovered_Job_ID${Clear}\n"}
	if ($Captured_User_Name) {print LOG "${Red}## ${Green}Caught User Name ${Yellow}$Captured_User_Name${Clear}\n"}
	if ($Parent_ID) {print LOG "${Red}## ${Green}Caught Parent ID ${Yellow}$Parent_ID${Clear}\n"}
	if ($Dependent_Command_Set_ID) {print LOG "${Red}## ${Green}Caught Dependent Command Set ID ${Yellow}$Dependent_Command_Set_ID${Clear}\n"}
	if ($Dependent_Host_ID) {print LOG "${Red}## ${Green}Caught Dependent Host ID ${Yellow}$Dependent_Host_ID${Clear}\n"}
	if ($Dependency_Chain_ID) {print LOG "${Red}## ${Green}Caught Dependency Chain ID ${Yellow}$Dependency_Chain_ID${Clear}\n"}
	if ($Captured_User_Password) {print LOG "${Red}## ${Green}Caught User Password ${Yellow}$Captured_User_Password${Clear}\n"}
	if ($Captured_Key) {print LOG "${Red}## ${Green}Caught Key ID ${Yellow}$Captured_Key${Clear}\n"}
	if ($Captured_Key_Lock) {print LOG "${Red}## ${Green}Caught Key Lock ${Yellow}$Captured_Key_Lock${Clear}\n"}
	if ($Captured_Key_Passphrase) {print LOG "${Red}## ${Green}Caught Key Passphrase ${Yellow}$Captured_Key_Passphrase${Clear}\n"}
	if (%Captured_Runtime_Variables) {
		my $CRTVs = scalar(keys %Captured_Runtime_Variables);
		print LOG "\n${Red}## ${Green}Caught $CRTVs Runtime Variables:${Clear}\n\n";
		foreach my $Variable_Key (keys %Captured_Runtime_Variables) {
			print LOG "${Green}CRTV: ${Yellow}$Variable_Key${Clear}\n"; 
			print LOG "${Green}Value: ${Yellow}" . $Captured_Runtime_Variables{$Variable_Key} . "${Clear}\n\n";
		}
	}
	if (%Runtime_Variables) {
		my $RTVs = scalar(keys %Runtime_Variables);
		print LOG "${Red}## ${Green}Resolved $RTVs Runtime Variables:${Clear}\n\n";
		foreach my $Variable_Key (keys %Runtime_Variables) {
			print LOG "${Green}RTV: ${Yellow}$Variable_Key${Clear}\n"; 
			print LOG "${Green}Value: ${Yellow}" . $Runtime_Variables{$Variable_Key} . "${Clear}\n\n";
		}
	}
}

if ($Verbose) {
	my $Time_Stamp = strftime "%H:%M:%S", localtime;
	print "\n${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Queuing myself for execution. Execution cap is ${Yellow}$DShell_Queue_Execution_Cap${Green} concurrent jobs.${Clear}\n";
	print LOG "\n${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Queuing myself for execution. Execution cap is ${Yellow}$DShell_Queue_Execution_Cap${Green} concurrent jobs.${Clear}\n";
}

if (!$High_Priority) {$High_Priority = 0}
my $Queue_Submission = $DB_Connection->prepare("REPLACE INTO `job_queue` (
	`job_id`,
	`override`
)
VALUES (
	?, ?
)");
$Queue_Submission->execute($Parent_ID, $High_Priority);

my $Execution_Ready;
while ($Execution_Ready ne 'GO') {
	my $Queue_Query = $DB_Connection->prepare("SELECT `job_id`, `override`
		FROM `job_queue`
		ORDER BY `last_modified`,`job_id` ASC");
	$Queue_Query->execute();
	my $Total_Queued_Jobs = $Queue_Query->rows();

	sleep 3; # Fix for race condition when queuing many jobs at once and more jobs execute than the limit allows

	my $Queue_Position_Count = 0;
	while (my ($Queue_Job_ID, $Queue_Override) = $Queue_Query->fetchrow_array()) {
		$Queue_Position_Count++;
		if ($Queue_Job_ID eq $Parent_ID) {
			if ($Queue_Override) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}High Priority job - executing now.${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}High Priority job - executing now.${Clear}\n";
				}
				my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?
					WHERE `id` = ?");
				$Update_Job->execute('10', $Parent_ID);
				$Execution_Ready = 'GO';
				last;
			}
			if ($Queue_Position_Count <= $DShell_Queue_Execution_Cap) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}I am position ${Yellow}$Queue_Position_Count${Green} of ${Yellow}$Total_Queued_Jobs${Green} in the queue - executing now.${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}I am position ${Yellow}$Queue_Position_Count${Green} of ${Yellow}$Total_Queued_Jobs${Green} in the queue - executing now.${Clear}\n";
				}
				my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?
					WHERE `id` = ?");
				$Update_Job->execute('10', $Parent_ID);
				$Execution_Ready = 'GO';
				last;
			}
			else {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}I am position ${Yellow}$Queue_Position_Count${Green} of ${Yellow}$Total_Queued_Jobs${Green} in the queue. Waiting for my turn...${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}I am position ${Yellow}$Queue_Position_Count${Green} of ${Yellow}$Total_Queued_Jobs${Green} in the queue. Waiting for my turn...${Clear}\n";
				}
				my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?
					WHERE `id` = ?");
				$Update_Job->execute('22', $Parent_ID);
				sleep 3;
				last;
			}
		}
	}
}

if (!$Dependent_Command_Set_ID && $Discovered_Job_ID) {
	print "\n${Green}Starting Job ID ${Blue}$Discovered_Job_ID${Green}...${Clear}\n";
		print LOG "\n${Green}Starting Job ID ${Blue}$Discovered_Job_ID${Green}...${Clear}\n";
	print "${Red}## ${Green}Discovered Job ID ${Blue}$Discovered_Job_ID${Green} (PID: $$).${Clear}\n";
		print LOG "${Red}## ${Green}Discovered Job ID ${Blue}$Discovered_Job_ID${Green} (PID: $$).${Clear}\n";
	my ($Host_ID, $Command_Set_ID) = &job_discovery($Discovered_Job_ID);
	print "${Red}## ${Green}Discovered Host ID ${Blue}$Host_ID${Green} and Command Set ID ${Blue}$Command_Set_ID${Green} (PID: $$).${Clear}\n";
		print LOG "${Red}## ${Green}Discovered Host ID ${Blue}$Host_ID${Green} and Command Set ID ${Blue}$Command_Set_ID${Green} (PID: $$).${Clear}\n";
	$Host = &host_discovery($Host_ID);
	print "${Red}## ${Green}Discovered Host ${Blue}$Host${Green} (PID: $$).${Clear}\n";
		print LOG "${Red}## ${Green}Discovered Host ${Blue}$Host${Green} (PID: $$).${Clear}\n";
	my $Job_Processor = &processor($Host_ID, $Command_Set_ID);
	
}
elsif ($Dependent_Command_Set_ID && !$Discovered_Job_ID) {
	print "\n${Green}Starting dependent Command Set ID ${Blue}$Dependent_Command_Set_ID${Green}...${Clear}\n";
		print LOG "\n${Green}Starting dependent Command Set ID ${Blue}$Dependent_Command_Set_ID${Green}...${Clear}\n";
	print "${Red}## ${Green}Discovered Host ID ${Blue}$Dependent_Host_ID${Green} and Command Set ID ${Blue}$Dependent_Command_Set_ID${Green} (Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green}, PID: $$).${Clear}\n";
		print LOG "${Red}## ${Green}Discovered Host ID ${Blue}$Dependent_Host_ID${Green} and Command Set ID ${Blue}$Dependent_Command_Set_ID${Green} (Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green}, PID: $$).${Clear}\n";
	$Host = &host_discovery($Dependent_Host_ID);
	print "${Red}## ${Green}Discovered Host ${Blue}$Host${Green} (Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green}, PID: $$).${Clear}\n";
		print LOG "${Red}## ${Green}Discovered Host ${Blue}$Host${Green} (Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green}, PID: $$).${Clear}\n";
	my $Dependency_Processor = &processor($Dependent_Host_ID, $Dependent_Command_Set_ID);
}
else {
	print "${Red}## Did you read the manual or help text? Shitting pants and exiting (PID: $$).${Clear}\n";
	print LOG "${Red}## Did you read the manual or help text? Shitting pants and exiting (PID: $$).${Clear}\n";
	my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
	$Delete_Queue_Entry->execute($Discovered_Job_ID);
	exit(1);
}

close LOG;

if ($Verbose) {
	my $Time_Stamp = strftime "%H:%M:%S", localtime;
	print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Tidying up transaction log ${Yellow}$DShell_Transactional_File${Clear}\n";
}
#system("sed -i 's/$Predictable_Prompt\n//g' $DShell_Transactional_File");
#system("sed -i 's/$Predictable_Prompt//g' $DShell_Transactional_File");

open( Transaction_Log, "<$DShell_Transactional_File" ) or die "Can't open $DShell_Transactional_File";
    local $/ = undef;
	my $Log_Content = <Transaction_Log>;
		#$Log_Content =~ s/$Predictable_Prompt/\n$Predictable_Prompt/g;
		$Log_Content =~ s/$Predictable_Prompt//g;
close Transaction_Log;

open( Transaction_Log, ">$DShell_Transactional_File" ) or die "Can't open $DShell_Transactional_File";
print Transaction_Log $Log_Retention . $Log_Content;
close Transaction_Log;


sub job_discovery {

	my $Job_ID = $_[0];

	my $Select_Job = $DB_Connection->prepare("SELECT `host_id`, `command_set_id`, `status`
		FROM `jobs`
		WHERE `id` = ?
	");
	$Select_Job->execute($Job_ID);
	my ($Host_ID, $Command_Set_ID, $Status) = $Select_Job->fetchrow_array();
	my $Job_Exists = $Select_Job->rows();

	if ($Job_Exists == 0) {
		print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} was not found.${Clear}\n";
		print LOG "${Yellow}Job ID ${Blue}$Job_ID${Yellow} was not found.${Clear}\n";
		my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
		$Delete_Queue_Entry->execute($Discovered_Job_ID);
		exit(0);
	}
	if ($Status == 10) {
		print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} was caught starting (Status $Status). Setting this to running.${Clear}\n";
		print LOG "${Yellow}Job ID ${Blue}$Job_ID${Yellow} was caught starting (Status $Status). Setting this to running.${Clear}\n";
		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute('1', $User_Name, $Parent_ID);
	}
	elsif ($Status == 0) {
		if ($Override) {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed (Status $Status). Override is enabled, so we're running it again!${Clear}\n";
			print LOG "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed (Status $Status). Override is enabled, so we're running it again!${Clear}\n";
			my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
				`status` = ?,
				`modified_by` = ?
				WHERE `id` = ?");
			$Update_Job->execute('1', $User_Name, $Parent_ID);
		}
		else {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed (Status $Status). Override is NOT enabled, so we won't run it again! Exiting...${Clear}\n";
			print LOG "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed (Status $Status). Override is NOT enabled, so we won't run it again! Exiting...${Clear}\n";
			my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
			$Delete_Queue_Entry->execute($Discovered_Job_ID);
			exit(0);
		}
	}
	elsif ($Status == 1 || $Status == 10) {
		if ($Override) {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running (Status $Status). Override is enabled, so we're running a second copy!${Clear}\n";
			print LOG "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running (Status $Status). Override is enabled, so we're running a second copy!${Clear}\n";
			my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
				`status` = ?,
				`modified_by` = ?
				WHERE `id` = ?");
			$Update_Job->execute('1', $User_Name, $Parent_ID);
		}
		else {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running (Status $Status). Override is NOT enabled, so we won't run a second copy! Exiting...${Clear}\n";
			print LOG "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running (Status $Status). Override is NOT enabled, so we won't run a second copy! Exiting...${Clear}\n";
			my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
			$Delete_Queue_Entry->execute($Discovered_Job_ID);
			exit(0);
		}
	}
	elsif ($Status == 2) {
		print "${Green}Job ID ${Blue}$Job_ID${Green} is paused (Status $Status). Continuing job from the last ran command...${Clear}\n";
		print LOG "${Green}Job ID ${Blue}$Job_ID${Green} is paused (Status $Status). Continuing job from the last ran command...${Clear}\n";
		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute('1', $User_Name, $Parent_ID);
	}
	elsif ($Status == 4) {
		print "${Green}Job ID ${Blue}$Job_ID${Green} is pending (Status $Status). Starting job...${Clear}\n";
		print LOG "${Green}Job ID ${Blue}$Job_ID${Green} is pending (Status $Status). Starting job...${Clear}\n";
		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute('1', $User_Name, $Parent_ID);
	}
	else {
		print "${Green}Job ID ${Blue}$Job_ID${Green} was stopped (Status $Status). Restarting job...${Clear}\n";
		print LOG "${Green}Job ID ${Blue}$Job_ID${Green} was stopped (Status $Status). Restarting job...${Clear}\n";
		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute('1', $User_Name, $Parent_ID);
	}

	my @Job_Data = ($Host_ID, $Command_Set_ID);
	return @Job_Data;

} # sub job_discovery

sub host_discovery {

	my $Host_ID = $_[0];

	my $Select_Host = $DB_Connection->prepare("SELECT `hostname`
		FROM `hosts`
		WHERE `id` = ?
	");
	$Select_Host->execute($Host_ID);
	my ($Host) = $Select_Host->fetchrow_array();

	return $Host;

} # sub host_discovery

sub host_connection {

	my $Host = $_[0];
	my $Host_ID = $_[1];
	my $SSH;

	# Discover if IP is available instead of hostname
	my $Host_Connection_String;
	## IPv4
	my $Select_IPv4_Block_Links = $DB_Connection->prepare("SELECT `ip`
		FROM `lnk_hosts_to_ipv4_assignments`
		WHERE `host` = ?");
	$Select_IPv4_Block_Links->execute($Host_ID);
	
	my $IPv4_Blocks;
	my $IPv4_Counts = 0;
	my $IPv4_Block;
	while (my $Block_ID = $Select_IPv4_Block_Links->fetchrow_array() ) {

		$IPv4_Counts++;
		my $Select_Blocks = $DB_Connection->prepare("SELECT `ip_block`
			FROM `ipv4_assignments`
			WHERE `id` = ?");
		$Select_Blocks->execute($Block_ID);
	
		$IPv4_Block = $Select_Blocks->fetchrow_array();
	}

	## IPv6
	my $Select_IPv6_Block_Links = $DB_Connection->prepare("SELECT `ip`
		FROM `lnk_hosts_to_ipv6_assignments`
		WHERE `host` = ?");
	$Select_IPv6_Block_Links->execute($Host_ID);
	
	my $IPv6_Blocks;
	my $IPv6_Counts = 0;
	my $IPv6_Block;
	while (my $Block_ID = $Select_IPv6_Block_Links->fetchrow_array() ) {

		$IPv6_Counts++;
		my $Select_Blocks = $DB_Connection->prepare("SELECT `ip_block`
			FROM `ipv6_assignments`
			WHERE `id` = ?");
		$Select_Blocks->execute($Block_ID);
	
		$IPv6_Block = $Select_Blocks->fetchrow_array();
	}

	if ($IPv6_Counts == 1) {
		$Host_Connection_String = $IPv6_Block;
		$Host_Connection_String =~ s/\/.*//;
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Connecting to ${Blue}$Host${Green} using IPv6 address ${Yellow}$Host_Connection_String${Clear}\n";
			print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Connecting to ${Blue}$Host${Green} using IPv6 address ${Yellow}$Host_Connection_String${Clear}\n";
		}
	}
	elsif ($IPv4_Counts == 1) {
		$Host_Connection_String = $IPv4_Block;
		$Host_Connection_String =~ s/\/.*//;
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Connecting to ${Blue}$Host${Green} using IPv4 address ${Yellow}$Host_Connection_String${Clear}\n";
			print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Connecting to ${Blue}$Host${Green} using IPv4 address ${Yellow}$Host_Connection_String${Clear}\n";
		}
	}
	elsif ($IPv4_Counts > 1 || $IPv6_Counts > 1) {
		$Host_Connection_String = $Host;
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}There are several possible IP addresses to connect to. Connecting to ${Blue}$Host${Green} using IP provided by DNS${Clear}\n";
			print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}There are several possible IP addresses to connect to. Connecting to ${Blue}$Host${Green} using IP provided by DNS${Clear}\n";
		}
	}
	else {
		$Host_Connection_String = $Host;
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}No listed IP addresses to connect to. Connecting to ${Blue}$Host${Green} using IP provided by DNS${Clear}\n";
			print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}No listed IP addresses to connect to. Connecting to ${Blue}$Host${Green} using IP provided by DNS${Clear}\n";
		}
	}
	# / Discover if IP is available instead of hostname


	my $Private_Key;
	if ($Captured_Key) {

		my $Select_Keys = $DB_Connection->prepare("SELECT `key_name`, `salt`, `key`, `key_username`
			FROM `auth`
			WHERE `id` = ?");

		$Select_Keys->execute($Captured_Key);

		while ( my @Keys = $Select_Keys->fetchrow_array() )
		{
			my $Key_Name = $Keys[0];
			my $Salt = $Keys[1];
			my $Encrypted_Key = $Keys[2];
			$User_Name = $Keys[3];

			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key $Key_Name [$User_Name]${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key $Key_Name [$User_Name]${Clear}\n";
			}

			$Key_Lock =~ s/\n//g;
			my $Key_Unlock = $Key_Lock . $Salt;
			if ($Paper_Trail) {
				print "${Red}## ${Green}Lock ${Yellow}$Key_Lock${Clear}\n";
				print "${Red}## ${Green}Salt ${Yellow}$Salt${Clear}\n";
				print "${Red}## ${Green}Key Code ${Yellow}$Key_Unlock${Clear}\n";
				print LOG "${Red}## ${Green}Lock ${Yellow}$Key_Lock${Clear}\n";
				print LOG "${Red}## ${Green}Salt ${Yellow}$Salt${Clear}\n";
				print LOG "${Red}## ${Green}Key Code ${Yellow}$Key_Unlock${Clear}\n";
			}

			use Crypt::CBC;
			my $Cipher_One = Crypt::CBC->new(
				-key	=>	$Key_Unlock,
				-cipher	=>	'DES',
				-salt	=>	1
			);

			my $Cipher_Two = Crypt::CBC->new(
				-key	=>	$Key_Unlock,
				-cipher	=>	'Rijndael',
				-salt	=>	1
			);

			eval { $Encrypted_Key = $Cipher_Two->decrypt($Encrypted_Key); }; &epic_failure('Cipher Two Decrypt', $@) if $@;
			eval { $Private_Key = $Cipher_One->decrypt($Encrypted_Key); }; &epic_failure('Cipher One Decrypt', $@) if $@;

			open( FILE, ">$DShell_tmp_Location/tmp.$Discovered_Job_ID" ); &epic_failure('Key Write', $@) if $@;
			print FILE "$Private_Key";
			close FILE;
			chmod 0600, "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
		}
	}

	my ($SSH_Check, $Attempts);
	($SSH_Check, $Attempts) = &connection_discovery($Host_Connection_String, $Attempts);

	# Fingerprint check/discovery
	my $Find_Fingerprint = $DB_Connection->prepare("SELECT `fingerprint`
		FROM `host_attributes`
		WHERE `host_id` = ?");
	$Find_Fingerprint->execute($Host_ID);
	my $Previously_Recorded_Fingerprint = $Find_Fingerprint->fetchrow_array();


	my $Hello;
	while (1) {

		if ($User_Name && $User_Password) {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting password login${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting password login${Clear}\n";
			}
			$SSH = Net::SSH::Expect->new (
				host => $Host_Connection_String,
				user => $User_Name,
				log_file => $DShell_Transactional_File,
				timeout => $Connection_Timeout,
				exp_internal => $Very_Verbose,
				exp_debug => $Very_Verbose,
				raw_pty => 1,
				restart_timeout_upon_receive => 1,
				ssh_option => "-o UserKnownHostsFile=/dev/null"
			);

			#eval {$SSH->login();}; &epic_failure('Login (Password)', $@) if $@; # Disabled login as it circumvents fingerprint verification, which is bad
			eval {$SSH->run_ssh();}; &epic_failure('Login (Password)', $@) if $@;

			# Fingerprint
			my $Line = $SSH->read_line();
			my $Fingerprint_Prompt = eval { $SSH->waitfor(".*key fingerprint is.*", $Connection_Timeout, '-re'); };
			if ($@) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to discover fingerprint. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Max_Attempts${Yellow})...${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to discover fingerprint. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Max_Attempts${Yellow})...${Clear}\n";
				}
				($SSH_Check, $Attempts) = &connection_discovery($Host_Connection_String, $Attempts);
			}

			if ($Fingerprint_Prompt) {

				my $Discovered_Fingerprint = $SSH->match();
				$Discovered_Fingerprint =~ s/.*key fingerprint is (.*)\./$1/g;
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint ${Blue}$Discovered_Fingerprint${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint ${Blue}$Discovered_Fingerprint${Clear}\n";
				}
				
				# Fingerprint validity check
				if (!$Previously_Recorded_Fingerprint) {

					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Previous fingerprint not found for ${Blue}$Host${Green}. Recording and proceeding...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Previous fingerprint not found for ${Blue}$Host${Green}. Recording and proceeding...${Clear}\n";
					}
					my $Update_Fingerprint = $DB_Connection->prepare("INSERT INTO `host_attributes` (
						`host_id`,
						`fingerprint`
					)
					VALUES (
						?, ?
					)ON DUPLICATE KEY UPDATE `fingerprint` = ?");
					$Update_Fingerprint->execute($Host_ID, $Discovered_Fingerprint, $Discovered_Fingerprint);
					$SSH->send('yes');

				}
				elsif ($Discovered_Fingerprint eq $Previously_Recorded_Fingerprint) {

					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Fingerprint matches records, connecting...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Fingerprint matches records, connecting...${Clear}\n";
					}
					$SSH->send('yes');

				}
				elsif ($Discovered_Fingerprint eq $Previously_Recorded_Fingerprint) {

					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint mismatch! Ejecting!${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint mismatch! Ejecting!${Clear}\n";

					my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
					$Update_Job->execute('17', $User_Name, $Parent_ID);
					my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
					$Delete_Queue_Entry->execute($Discovered_Job_ID);
					exit(17);
				}
				else {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint not found! Connection timeout, network or host resolution problems are the most likely causes.${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint not found! Connection timeout, network or host resolution problems are the most likely causes.${Clear}\n";

					my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
					$Update_Job->execute('5', $User_Name, $Parent_ID);
					my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
					$Delete_Queue_Entry->execute($Discovered_Job_ID);
					exit(5);
				}

			}
			else {
				print "${Red}Fingerprint prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
				print LOG "${Red}Fingerprint prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
			}

			# Login (password)
			$Line = $SSH->read_line();
			my $Password_Prompt = $SSH->waitfor(".*password.*", $Connection_Timeout, '-re');
			if ($Password_Prompt) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found password prompt ${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found password prompt ${Clear}\n";
				}
#				if ($System_Is_Windows) {
#					$SSH->send("$User_Password");
#				}
#				else {
					$SSH->send("$User_Password");
#				}
			}
			else {
				print "${Red}Password prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
				print LOG "${Red}Password prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
			}
		}
		else {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting key login${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting key login${Clear}\n";
			}
			$SSH = Net::SSH::Expect->new (
				host => $Host_Connection_String,
				user => $User_Name,
				log_file => $DShell_Transactional_File,
				timeout => $Connection_Timeout,
				exp_internal => $Very_Verbose,
				exp_debug => $Very_Verbose,
				raw_pty => 1,
				restart_timeout_upon_receive => 1,
				ssh_option => "-i $DShell_tmp_Location/tmp.$Discovered_Job_ID"
			);
			eval { $SSH->run_ssh(); }; &epic_failure('Login (Key)', $@) if $@;

			# Fingerprint
			my $Line = $SSH->read_line();
			my $Fingerprint_Prompt = eval { $SSH->waitfor(".*key fingerprint is.*", $Connection_Timeout, '-re'); };
			if ($@) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to discover fingerprint. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Max_Attempts${Yellow})...${Clear}\n";
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to discover fingerprint. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Max_Attempts${Yellow})...${Clear}\n";
				}
				($SSH_Check, $Attempts) = &connection_discovery($Host_Connection_String, $Attempts);
			}

			if ($Fingerprint_Prompt) {

				my $Discovered_Fingerprint = $SSH->match();
				$Discovered_Fingerprint =~ s/.*key fingerprint is (.*)\./$1/g;
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint ${Blue}$Discovered_Fingerprint${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint ${Blue}$Discovered_Fingerprint${Clear}\n";
				}
				
				# Fingerprint validity check
				if (!$Previously_Recorded_Fingerprint) {
					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Previous fingerprint not found for ${Blue}$Host${Green}. Recording and proceeding...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Previous fingerprint not found for ${Blue}$Host${Green}. Recording and proceeding...${Clear}\n";
					}
					my $Update_Fingerprint = $DB_Connection->prepare("INSERT INTO `host_attributes` (
						`host_id`,
						`fingerprint`
					)
					VALUES (
						?, ?
					)ON DUPLICATE KEY UPDATE `fingerprint` = ?");
					$Update_Fingerprint->execute($Host_ID, $Discovered_Fingerprint, $Discovered_Fingerprint);
					$SSH->send('yes');
				}
				elsif ($Discovered_Fingerprint eq $Previously_Recorded_Fingerprint) {

					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Fingerprint matches records, connecting...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Fingerprint matches records, connecting...${Clear}\n";
					}
					$SSH->send('yes');

				}
				else {

					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint mismatch! Ejecting!${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint mismatch! Ejecting!${Clear}\n";

					my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
					$Update_Job->execute('17', $User_Name, $Parent_ID);
					unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
					my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
					$Delete_Queue_Entry->execute($Discovered_Job_ID);
					exit(17);
				}

			}
			else {
				print "${Red}Fingerprint prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
				print LOG "${Red}Fingerprint prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
			}

			my $Key_Passphase_Trap = $SSH->waitfor("Enter passphrase for key", $Connection_Timeout, '-re');
			if ($Key_Passphase_Trap) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key passphrase prompt, sending passphrase${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key passphrase prompt, sending passphrase${Clear}\n";
				}
				$SSH->send($Key_Passphrase);
			}
			else {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Key passphrase prompt not found - perhaps this key doesn't have a passphrase${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Key passphrase prompt not found - perhaps this key doesn't have a passphrase${Clear}\n";
				}
			}
		}

		my $Test_Command = 'echo TheMachine';
		$SSH->send($Test_Command);
		#$Hello = eval { $SSH->exec($Test_Command, $Connection_Timeout); };
		#eval { $Hello = $SSH->waitfor("\033", 10); };
		eval { $Hello = $SSH->waitfor("Microsoft", $Connection_Timeout, '-re'); };

		if ($Hello) {
			$System_Is_Windows = 1;
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Windows detected, setting control mode to 'Money for Old Rope'...${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Windows detected, setting control mode to 'Money for Old Rope'...${Clear}\n";
			}
		}
		else {
			$Hello = eval { $SSH->exec($Test_Command, $Connection_Timeout); };
		}

		if ($@) {
			print "Error: $@n";
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to confirm login. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Max_Attempts${Yellow})...${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to confirm login. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Max_Attempts${Yellow})...${Clear}\n";
			}
			($SSH_Check, $Attempts) = &connection_discovery($Host_Connection_String, $Attempts);
		}

		last if $Hello =~ m/TheMachine/;
		last if $System_Is_Windows == 1;
		last if $Retry_Count >= $Max_Retry_Count;

		if ($Hello =~ m/Permission denied/) {
			print "Supplied credentials failed. Terminating the job.\n";
			print LOG "Supplied credentials failed. Terminating the job.\n";
			my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
			$Update_Job->execute('6', $User_Name, $Parent_ID);
			unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
			my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
			$Delete_Queue_Entry->execute($Discovered_Job_ID);
			exit(6);
		}

		my $Connection_Timeout_Plus = $Connection_Timeout;
		$Retry_Count++;
		$Connection_Timeout_Plus += 5;
		
		if ($Verbose && $Retry_Count > 0) {
			print "Tried to connect to $Host with $Connection_Timeout second timeout but failed. Timeout increased to $Connection_Timeout_Plus, trying again (attempt $Retry_Count of $Max_Retry_Count)...\n";
			print LOG "Tried to connect to $Host with $Connection_Timeout second timeout but failed. Timeout increased to $Connection_Timeout_Plus, trying again (attempt $Retry_Count of $Max_Retry_Count)...\n";
		}
		
		$Connection_Timeout = $Connection_Timeout_Plus;
	
	}
	
	if ($Retry_Count >= $Max_Retry_Count) {
		print "Couldn't connect to $Host after $Retry_Count attempts. Terminating the job.\n";
		print LOG "Couldn't connect to $Host after $Retry_Count attempts. Terminating the job.\n";
		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		$Update_Job->execute('5', $User_Name, $Parent_ID);
		unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
		my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
		$Delete_Queue_Entry->execute($Discovered_Job_ID);
		exit(5);
	}

	#$SSH->exec("stty raw -echo");
	$SSH->timeout(1);

	unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";

	return $SSH;

} # sub host_connection

sub connection_discovery {

	my $Host_Connection_String = $_[0];
	my $Attempts = $_[1];
	my $SSH_Check;

	while ($SSH_Check !~ /open/) {

		$Attempts++;

		$SSH_Check=`$nmap $Host_Connection_String -PN -p ssh | $grep -E 'open'`;
		sleep 1;
	
		if ($Attempts >= $Max_Attempts) {
			print "Unresolved host, no route to host or SSH not responding correctly. Was trying '$Host_Connection_String'. Terminating the job.\n";
			print LOG "Unresolved host, no route to host or SSH not responding correctly. Was trying '$Host_Connection_String'. Terminating the job.\n";
			my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
			$Update_Job->execute('5', $User_Name, $Parent_ID);
			unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
			my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
			$Delete_Queue_Entry->execute($Discovered_Job_ID);
			exit(5);
		}
	}
	return ($SSH_Check, $Attempts);
} # sub connection_discovery

sub reboot_discovery {

	my $Host_Connection_String = $_[0];
	my $Attempts = $_[1];
	my $SSH_Check;

	while ($SSH_Check !~ /open/) {
	
		$Attempts++;
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempt ${Yellow}$Attempts${Green} at restarting SSH session... ${Clear}\n";
			print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempt ${Yellow}$Attempts${Green} at restarting SSH session... ${Clear}\n";
		}
		$SSH_Check=`$nmap $Host_Connection_String -PN -p ssh | $grep -E 'open'`;
		sleep 1;
	
		if ($Attempts >= $Reboot_Max_Attempts) {
			print "Host connection did not recover. Was trying '$Host_Connection_String'. Terminating the job.\n";
			print LOG "Host connection did not recover. Was trying '$Host_Connection_String'. Terminating the job.\n";
			my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
			$Update_Job->execute('14', $User_Name, $Parent_ID);
			unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
			my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
			$Delete_Queue_Entry->execute($Discovered_Job_ID);
			exit(14);
		}
	}
	return ($SSH_Check, $Attempts);

} # sub reboot_discovery

sub processor {

	my ($Host_ID, $Process_Command_Set_ID) = @_;

	## Discover dependencies
	my $Discover_Dependencies = $DB_Connection->prepare("SELECT `dependent_command_set_id`
		FROM `command_set_dependency`
		WHERE `command_set_id` = ?
		ORDER BY `order` ASC
	");
	$Discover_Dependencies->execute($Process_Command_Set_ID);
	
	while ( my $Command_Set_Dependency_ID = $Discover_Dependencies->fetchrow_array() ) {
		$Dependency_Chain_ID++;
		my ($Control_Switches, $Verbose_Switch, $Very_Verbose_Switch, $Decode_Switch, $No_Colour_Switch);
		if ($Verbose) {$Verbose_Switch = '-v '; $Control_Switches = $Control_Switches . $Verbose_Switch;}
		if ($Very_Verbose) {$Very_Verbose_Switch = '-V '; $Control_Switches = $Control_Switches . $Very_Verbose_Switch;}
		if ($No_Decode) {$Decode_Switch = '-D '; $Control_Switches = $Control_Switches . $Decode_Switch;}
		if ($No_Colour) {$No_Colour_Switch = '--no-colour '; $Control_Switches = $Control_Switches . $No_Colour_Switch;}
		print "${Green}I've discovered that Command Set ID ${Blue}$Process_Command_Set_ID${Green} is dependent on Command Set ID ${Blue}$Command_Set_Dependency_ID${Green}. Processing Command Set ID ${Blue}$Command_Set_Dependency_ID${Green} as dependency ${Blue}$Dependency_Chain_ID${Green}. ${Clear}\n";
			print LOG "${Green}I've discovered that Command Set ID ${Blue}$Process_Command_Set_ID${Green} is dependent on Command Set ID ${Blue}$Command_Set_Dependency_ID${Green}. Processing Command Set ID ${Blue}$Command_Set_Dependency_ID${Green} as dependency ${Blue}$Dependency_Chain_ID${Green}. ${Clear}\n";

		if ($User_Name && $User_Password) {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Triggering dependency as: ${Blue}./d-shell.pl ${Control_Switches} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -u $User_Name -P $Captured_User_Password${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Triggering dependency as: ${Blue}./d-shell.pl ${Control_Switches} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -u $User_Name -P $Captured_User_Password${Clear}\n";
			}
			my $System_Exit_Code = system "./d-shell.pl ${Control_Switches} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -u $User_Name -P $Captured_User_Password $Dependency_Runtime_Variables";
			if ($System_Exit_Code == 0) {
				print "${Green}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green} execution complete. Exit code was $System_Exit_Code.${Clear}\n";
				print LOG "${Green}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green} execution complete. Exit code was $System_Exit_Code.${Clear}\n";
			}
			else {
				print "${Red}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Red} execution complete. Exit code was $System_Exit_Code. Exiting :-(${Clear}\n";
				print LOG "${Red}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Red} execution complete. Exit code was $System_Exit_Code. Exiting :-()${Clear}\n";
				my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
				$Delete_Queue_Entry->execute($Discovered_Job_ID);
				exit(1);
			}
		}
		else {
			my $System_Exit_Code;
			if ($Captured_Key_Passphrase) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Triggering dependency as: ${Blue}./d-shell.pl ${Control_Switches} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -k $Captured_Key -L $Captured_Key_Lock -K $Captured_Key_Passphrase${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Triggering dependency as: ${Blue}./d-shell.pl ${Control_Switches} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -k $Captured_Key -L $Captured_Key_Lock -K $Captured_Key_Passphrase${Clear}\n";
				}
				$System_Exit_Code = system "./d-shell.pl ${Control_Switches} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -k $Captured_Key -L $Captured_Key_Lock -K $Captured_Key_Passphrase $Dependency_Runtime_Variables";
			}
			else {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Triggering dependency as: ${Blue}./d-shell.pl ${Control_Switches} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -k $Captured_Key -L $Captured_Key_Lock${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Triggering dependency as: ${Blue}./d-shell.pl ${Control_Switches} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -k $Captured_Key -L $Captured_Key_Lock${Clear}\n";
				}
				$System_Exit_Code = system "./d-shell.pl ${Control_Switches} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -k $Captured_Key -L $Captured_Key_Lock $Dependency_Runtime_Variables";
			}
			if ($System_Exit_Code == 0) {
				print "${Green}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green} execution complete. Exit code was $System_Exit_Code.${Clear}\n";
				print LOG "${Green}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green} execution complete. Exit code was $System_Exit_Code.${Clear}\n";
			}
			else {
				print "${Red}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Red} execution failed. Exit code was $System_Exit_Code. Exiting :-(${Clear}\n";
				print LOG "${Red}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Red} execution failed. Exit code was $System_Exit_Code. Exiting :-(${Clear}\n";
				my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
				$Delete_Queue_Entry->execute($Discovered_Job_ID);
				exit(1);
			}
		}
	}

	my $Connected_Host = &host_connection($Host, $Host_ID);

	## Discover Commands
	my $Select_Commands = $DB_Connection->prepare("SELECT `name`, `command`
		FROM `command_sets`
		WHERE `id` = ?
	");
	$Select_Commands->execute($Process_Command_Set_ID);
	my ($Command_Name, $Commands) = $Select_Commands->fetchrow_array();

	if ($Top_Level_Job) {
		my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`output`,
			`task_started`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, NOW(), ?
		)");
	
		$Update_Job_Status->execute($Parent_ID, "### Main job ($Command_Name) started.\n", '', $User_Name);
		my $Start_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
		print LOG "Job started at $Start_Time.\n";
	}
	else {
		my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`output`,
			`task_started`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, NOW(), ?
		)");
	
		$Update_Job_Status->execute($Parent_ID, "### Dependency set ($Command_Name) started.\n", '', $User_Name);
		my $Start_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
		print LOG "Dependency set $Command_Name started at $Start_Time.\n";
	}

	my @Commands = split('\r', $Commands);
	my $Command_Count = $#Commands;
	foreach my $Command (@Commands) {
		$Command =~ s/\n//;
		$Command =~ s/\r//;
		my $Command_Clean = $Command;

		while ($Command =~ m/\*VAR/) {

			my $Machine_Variable = $Command;
			$Machine_Variable =~ s/.*\*VAR\{(.*?)\}.*/$1/g;

			my $Variable_Value = $Runtime_Variables{$Machine_Variable};
			$Variable_Value =~ s/\r\n/\n/g;
			$Command =~ s/\*VAR\{$Machine_Variable\}/$Variable_Value/;

			if (!$Command && $Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}Found a Machine variable '$Machine_Variable' that has no value. Proceeding, but may have unexpected results.${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}Found a Machine variable '$Machine_Variable' that has no value. Proceeding, but may have unexpected results.${Clear}\n";
			}

		}

		my $Job_Paused;
		while ($Job_Paused ne 'No') {
			my $Query_Control_Status = $DB_Connection->prepare("SELECT `status`, `modified_by`
				FROM `jobs`
				WHERE `id` = ?
			");
			$Query_Control_Status->execute($Parent_ID);

			my ($Query_Status, $Query_Modified_By) = $Query_Control_Status->fetchrow_array();
			if ($Query_Status == 2) {
				if ($Job_Paused ne 'Yes') {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Green}Job paused by $Query_Modified_By at $Time_Stamp.${Clear}\n";
					print LOG "${Green}Job paused by $Query_Modified_By at $Time_Stamp.${Clear}\n";
				}
				$Job_Paused = 'Yes';
				sleep 2;
			}
			else {
				$Job_Paused = 'No';
			}
			if ($Query_Status == 3) {
				print "${Red}Job killed by $Query_Modified_By. Terminating job.${Clear}\n";
				print LOG "${Red}Job killed by $Query_Modified_By. Terminating job.${Clear}\n";
				my $End_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
				print LOG "Job killed at $End_Time by $Query_Modified_By.";
				my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
				$Delete_Queue_Entry->execute($Discovered_Job_ID);
				exit(3);
			}
		}

		my $Set_Predictable_Prompt;
		if ($System_Is_Windows) {
			$Set_Predictable_Prompt = "set PROMPT=$Predictable_Prompt";
		}
		else {
			$Set_Predictable_Prompt = "PS1=$Predictable_Prompt";
		}

		my $Time_Stamp = strftime "%H:%M:%S", localtime;

		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute('1', $User_Name, $Parent_ID);

		my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`output`,
			`task_started`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, NOW(), ?
		)");
	
		$Update_Job_Status->execute($Parent_ID, $Command_Clean, 'Currently Running...', $User_Name);
		my $Job_Status_Update_ID = $DB_Connection->{mysql_insertid};
	
		my $Command_Output;
		my $Exit_Code;
		if (($Command =~ /^#/) || ($Command eq undef)) {
			if ($Verbose) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Skipping comment/empty line ${Blue}$Command${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Skipping comment/empty line ${Blue}$Command${Clear}\n";
			}
			$Command_Output = 'Skipped comment / empty line.';
			$Exit_Code = 0;
		} # / COMMENT
		elsif ($Command =~ /\*SEND.*/ && $Command =~ /\*WAITFOR.*/) {
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}Incorrect use of *WAITFOR and *SEND together.${Clear}\n";
			print LOG "${Red}Incorrect use of *WAITFOR and *SEND together.\n";
			$Command_Output = "Incorrect use of *WAITFOR and *SEND together.";
			$Exit_Code = 19;
			$Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
				`exit_code` = ?,
				`output` = ?,
				`task_ended` = NOW(),
				`modified_by` = ?
				WHERE `id` = ?");
			$Command_Output =~ s/$Predictable_Prompt//g;
			$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);
			my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
				`job_id`,
				`command`,
				`output`,
				`task_ended`,
				`modified_by`
			)
			VALUES (
				?, ?, ?, NOW(), ?
			)");
			$Update_Job_Status->execute($Parent_ID, "### Incorrect use of *WAITFOR and *SEND together.", '', $User_Name);
			my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
				`status` = ?,
				`modified_by` = ?
				WHERE `id` = ?");
			$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);
			my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
			$Delete_Queue_Entry->execute($Discovered_Job_ID);
			exit($Exit_Code);
		} # / SEND or WAITFOR fail
		elsif ($Command =~ /^\*PAUSE.*/) {

			my $Pause = $Command;
			$Pause =~ s/\*PAUSE (.*)/$1/;

			if ($Pause !~ /^\d*$/) {

				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Paused the Job indefinitely. You should manually resume this to continue.${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Paused the Job indefinitely. You should manually resume this to continue.${Clear}\n";
				}
	
				my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
					`job_id`,
					`command`,
					`output`,
					`task_ended`,
					`modified_by`
				)
				VALUES (
					?, ?, ?, NOW(), ?
				)");
				$Update_Job_Status->execute($Parent_ID, "### Paused the Job indefinitely. You should manually resume this to continue.", '', $User_Name);

				my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
				$Update_Job->execute( '2', $User_Name, $Parent_ID);

			}
			else {

				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Pausing for ${Blue}$Pause ${Green}seconds${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Pausing for ${Blue}$Pause ${Green}seconds${Clear}\n";
				}
				sleep $Pause;
				$Command_Output = "Paused for $Pause seconds.";
				$Exit_Code = 0;

			}
		} # / PAUSE
		elsif ($Command =~ /^\*VSNAPSHOT.*/) {
			my $Snapshot = $Command;
			$Snapshot =~ s/\*VSNAPSHOT (.*)/$1/;

		 	if ($Verbose) {
				$Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking that the system resides on VMware before performing a snapshot operation${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking that the system resides on VMware before performing a snapshot operation${Clear}\n";
			}

			if ($System_Is_Windows) {
				$Connected_Host->send(" $Set_Predictable_Prompt");
				$Connected_Host->send(' echo %PROMPT%');
				$Command_Output = $Connected_Host->read_all();
			}
			else {
				$Connected_Host->send(' export HISTFILE=/dev/null');
				$Connected_Host->send(" $Set_Predictable_Prompt");
				$Connected_Host->send(' echo $PS1');
				$Command_Output = $Connected_Host->read_all();
				$Connected_Host->send(' cat /sys/class/dmi/id/sys_vendor');
			}
			eval { $Command_Output = $Connected_Host->read_all(); }; &epic_failure('VMware Detection Fault', $@, $Command_Output, $Job_Status_Update_ID) if $@;
			$Command_Output =~ s/\e.*//g;
			$Command_Output =~ s/\r//g;
			$Command_Output =~ s/\n//g;
			$Command_Output =~ s/\Q$Predictable_Prompt\E//g;
			$Command_Output =~ s/\s*cat\s\/sys\/class\/dmi\/id\/sys_vendor//g;

			if ($Command_Output eq 'VMware, Inc.') {
				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System appears to be a VMware VM${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System appears to be a VMware VM${Clear}\n";
				}
			}
			else {
				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System IS NOT a VMware VM, it is a $Command_Output system. Skipping snapshot operations.${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System IS NOT a VMware VM, it is a $Command_Output system. Skipping snapshot operations.${Clear}\n";
				}
				$Snapshot = 'NOTVMWARE';
			}
			
			if ($Verbose && $Snapshot ne 'NOTVMWARE') {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Performing a snapshot operation${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Performing a snapshot operation${Clear}\n";
			}
			if ($Snapshot eq 'COUNT') {
				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Counting snapshots${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Counting snapshots${Clear}\n";
				}
				$Command_Output = `./vmware-snapshot.pl -c -i $Host_ID`;
				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error counting snapshots.";
				}
			}
			elsif ($Snapshot eq 'SHOW') {
				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Showing snapshot tree${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Showing snapshot tree${Clear}\n";
				}
				$Command_Output = `./vmware-snapshot.pl -S -i $Host_ID`;
				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error showing the snapshot tree.";
				}
			}
			elsif ($Snapshot =~ /^TAKE/) {

				my $Snapshot_Tag = $Snapshot;
					if ($Snapshot_Tag =~ /^TAKE /) {
						$Snapshot_Tag =~ s/^TAKE (.*)/$1/;
					}
					else {
						$Snapshot_Tag = '';
					}

				if ($Snapshot_Tag) {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Taking a snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Taking a snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
					}
					$Command_Output = `./vmware-snapshot.pl -s -i $Host_ID -T '${Snapshot_Tag}' -X '${User_Name}'`;
				}
				else {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Taking a snapshot${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Taking a snapshot${Clear}\n";
					}
					$Command_Output = `./vmware-snapshot.pl -s -i $Host_ID -X '${User_Name}'`;
				}
				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error taking a snapshot.";
				}
			}
			elsif ($Snapshot =~ /^REVERT/) {

				my $Snapshot_Tag = $Snapshot;
					if ($Snapshot_Tag =~ /^REVERT /) {
						$Snapshot_Tag =~ s/^REVERT (.*)/$1/;
					}
					else {
						$Snapshot_Tag = '';
					}

				if ($Snapshot_Tag) {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Reverting a snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Reverting a snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
					}
					$Command_Output = `./vmware-snapshot.pl -R -y -i $Host_ID -T '${Snapshot_Tag}'`;
				}
				else {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Reverting to the current snapshot${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Reverting to the current snapshot${Clear}\n";
					}
					$Command_Output = `./vmware-snapshot.pl -R -y -i $Host_ID`;
				}
				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error reverting a snapshot.";
				}
				else {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Host appears to have reverted to a previous snapshot. Establishing session again...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Host appears to have reverted to a previous snapshot. Establishing session again...${Clear}\n";
					}
					my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
						`job_id`,
						`command`,
						`task_started`,
						`modified_by`
					)
					VALUES (
						?, ?, NOW(), ?
					)");
				
					$Update_Job_Status->execute($Parent_ID, '### Host appears to have reverted to a previous snapshot. Establishing session again...', $User_Name);
					my $Reboot_Type = 1;
					$Connected_Host = &reboot_control($Host, $Host_ID, $Reboot_Type);
				}
			}
			elsif($Snapshot =~ /^REMOVE/) {

				my $Snapshot_Tag = $Snapshot;
					if ($Snapshot_Tag =~ /^REMOVE /) {
						$Snapshot_Tag =~ s/^REMOVE (.*)/$1/;
					}
					else {
						$Snapshot_Tag = '';
					}

				if ($Snapshot_Tag) {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing $System_Short_Name snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing $System_Short_Name snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
					}
					$Command_Output = `./vmware-snapshot.pl -d -i $Host_ID -T '${Snapshot_Tag}'`;
				}
				else {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing current snapshot taken by $System_Short_Name${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing current snapshot taken by $System_Short_Name${Clear}\n";
					}
					$Command_Output = `./vmware-snapshot.pl -d -i $Host_ID`;
				}

				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error removing $System_Short_Name snapshots.";
				}
			}
			elsif($Snapshot eq 'REMOVEALL') {
				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing ALL snapshots${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing ALL snapshots${Clear}\n";
				}
				$Command_Output = `./vmware-snapshot.pl -e -i $Host_ID`;
				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error removing all snapshots.";
				}
			}
			elsif($Snapshot eq 'NOTVMWARE') {
				$Command_Output = "This is not a VMware VM.";
				$Exit_Code = 0;
			}
			else {
				$Command_Output = "Found that you wanted to perform a snapshot operation. Couldn't determine exactly what. Perhaps you misspelt an option.";
				$Exit_Code = 1;
			}

			my $Select_Failure_Action = $DB_Connection->prepare("SELECT `on_failure`
				FROM `jobs`
				WHERE `id` = ?
			");
			$Select_Failure_Action->execute($Parent_ID);
			my ($On_Failure) = $Select_Failure_Action->fetchrow_array();

			if ($Exit_Code != 0 && $On_Failure) {
				my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
				$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);
				my $Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
					`exit_code` = ?,
					`output` = ?,
					`task_ended` = NOW(),
					`modified_by` = ?
					WHERE `id` = ?");
				$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);
				print "${Red}Snapshot operation failed.${Clear}\n";
				print LOG "${Red}Snapshot operation failed.${Clear}\n";
				$Connected_Host->close();
				my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
				$Delete_Queue_Entry->execute($Discovered_Job_ID);
				exit($Exit_Code);
			}
		} # / VSNAPSHOT
		elsif ($Command =~ /^\*PSNAPSHOT.*/) {
			my $Snapshot = $Command;
			$Snapshot =~ s/\*PSNAPSHOT (.*)/$1/;

		 	if ($Verbose) {
				$Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking that the system resides on Proxmox/KVM before performing a snapshot operation${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking that the system resides on Proxmox/KVM before performing a snapshot operation${Clear}\n";
			}

			if ($System_Is_Windows) {
				$Connected_Host->send(" $Set_Predictable_Prompt");
				$Connected_Host->send(' echo %PROMPT%');
				$Command_Output = $Connected_Host->read_all();
			}
			else {
				$Connected_Host->send(' export HISTFILE=/dev/null');
				$Connected_Host->send(" $Set_Predictable_Prompt");
				$Connected_Host->send(' echo $PS1');
				$Command_Output = $Connected_Host->read_all();
				$Connected_Host->send(' cat /sys/class/dmi/id/sys_vendor');
			}
			eval { $Command_Output = $Connected_Host->read_all(); }; &epic_failure('Proxmox/KVM Detection Fault', $@, $Command_Output, $Job_Status_Update_ID) if $@;
			$Command_Output =~ s/\e.*//g;
			$Command_Output =~ s/\r//g;
			$Command_Output =~ s/\n//g;
			$Command_Output =~ s/\Q$Predictable_Prompt\E//g;
			$Command_Output =~ s/\s*cat\s\/sys\/class\/dmi\/id\/sys_vendor//g;

			if ($Command_Output eq 'QEMU') {
				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System appears to be a Proxmox/KVM VM${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System appears to be a Proxmox/KVM VM${Clear}\n";
				}
			}
			else {
				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System IS NOT a Proxmox/KVM VM, it is a $Command_Output system. Skipping snapshot operations.${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System IS NOT a Proxmox/KVM VM, it is a $Command_Output system. Skipping snapshot operations.${Clear}\n";
				}
				$Snapshot = 'NOTKVM';
			}
			
			if ($Verbose && $Snapshot ne 'NOTKVM') {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Performing a snapshot operation${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Performing a snapshot operation${Clear}\n";
			}
			if ($Snapshot eq 'SHOW') {
				if ($Verbose) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Showing snapshots${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Showing snapshots${Clear}\n";
				}
				$Command_Output = `./proxmox-snapshot.pl -S -i $Host_ID`;
				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error showing the snapshots: $Command_Output ($Exit_Code)";
					$Exit_Code = 21;
				}
			}
			elsif ($Snapshot =~ /^TAKE/) {

				my $Snapshot_Tag = $Snapshot;
					if ($Snapshot_Tag =~ /^TAKE /) {
						$Snapshot_Tag =~ s/^TAKE (.*)/$1/;
					}
					else {
						$Snapshot_Tag = '';
					}

				if ($Snapshot_Tag) {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Taking a snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Taking a snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
					}
					$Command_Output = `./proxmox-snapshot.pl -s -i $Host_ID -T '${Snapshot_Tag}' -X '${User_Name}'`;
				}
				else {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}You must provide a snapshot tag when taking snapshots${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}You must provide a snapshot tag when taking snapshots${Clear}\n";
					}
					print "Error: You must provide a snapshot tag when taking snapshots\n";
					$Exit_Code = 21;
				}
				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error taking a snapshot: $Command_Output ($Exit_Code)";
					$Exit_Code = 21;
				}
			}
			elsif ($Snapshot =~ /^REVERT/) {

				my $Snapshot_Tag = $Snapshot;
					if ($Snapshot_Tag =~ /^REVERT /) {
						$Snapshot_Tag =~ s/^REVERT (.*)/$1/;
					}
					else {
						$Snapshot_Tag = '';
					}

				if ($Snapshot_Tag) {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Reverting a snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Reverting a snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
					}
					$Command_Output = `./proxmox-snapshot.pl -R -y -i $Host_ID -T '${Snapshot_Tag}'`;
					$Exit_Code = ${^CHILD_ERROR_NATIVE};
				}
				else {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}You must provide a snapshot tag when reverting snapshots${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}You must provide a snapshot tag when reverting snapshots${Clear}\n";
					}
					print "Error: You must provide a snapshot tag when reverting snapshots\n";
					$Exit_Code = 21;
				}
				
				if ($Exit_Code) {
					$Command_Output = "There was an error reverting a snapshot: $Command_Output ($Exit_Code)";
					$Exit_Code = 21;
				}
				else {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Host appears to have reverted to a previous snapshot. Establishing session again...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Host appears to have reverted to a previous snapshot. Establishing session again...${Clear}\n";
					}
					my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
						`job_id`,
						`command`,
						`task_started`,
						`modified_by`
					)
					VALUES (
						?, ?, NOW(), ?
					)");
				
					$Update_Job_Status->execute($Parent_ID, '### Host appears to have reverted to a previous snapshot. Establishing session again...', $User_Name);
					my $Reboot_Type = 1;
					$Connected_Host = &reboot_control($Host, $Host_ID, $Reboot_Type);
				}
			}
			elsif($Snapshot =~ /^REMOVE/) {

				my $Snapshot_Tag = $Snapshot;
					if ($Snapshot_Tag =~ /^REMOVE /) {
						$Snapshot_Tag =~ s/^REMOVE (.*)/$1/;
					}
					else {
						$Snapshot_Tag = '';
					}

				if ($Snapshot_Tag) {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing $System_Short_Name snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing $System_Short_Name snapshot with tag ${Yellow}$Snapshot_Tag${Clear}\n";
					}
					$Command_Output = `./proxmox-snapshot.pl -d -i $Host_ID -T '${Snapshot_Tag}'`;
				}
				else {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}You must provide a snapshot tag when removing snapshots${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}You must provide a snapshot tag when removing snapshots${Clear}\n";
					}
					print "Error: You must provide a snapshot tag when removing snapshots\n";
					$Exit_Code = 21;
				}

				$Exit_Code = ${^CHILD_ERROR_NATIVE};
				if ($Exit_Code) {
					$Command_Output = "There was an error removing $System_Short_Name snapshots: $Command_Output ($Exit_Code)";
					$Exit_Code = 21;
				}
			}
			elsif($Snapshot eq 'NOTKVM') {
				$Command_Output = "This is not a Proxmox/KVM VM.";
				$Exit_Code = 0;
			}
			else {
				$Command_Output = "Found that you wanted to perform a snapshot operation. Couldn't determine exactly what. Perhaps you misspelt an option.";
				$Exit_Code = 1;
			}

			my $Select_Failure_Action = $DB_Connection->prepare("SELECT `on_failure`
				FROM `jobs`
				WHERE `id` = ?
			");
			$Select_Failure_Action->execute($Parent_ID);
			my ($On_Failure) = $Select_Failure_Action->fetchrow_array();

			if ($Exit_Code != 0 && $On_Failure) {
				my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
				$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);
				my $Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
					`exit_code` = ?,
					`output` = ?,
					`task_ended` = NOW(),
					`modified_by` = ?
					WHERE `id` = ?");
				$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);
				print "${Red}Snapshot operation failed.${Clear}\n";
				print LOG "${Red}Snapshot operation failed.${Clear}\n";
				$Connected_Host->close();
				my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
				$Delete_Queue_Entry->execute($Discovered_Job_ID);
				exit($Exit_Code);
			}
		} # / PSNAPSHOT
		elsif ($Command =~ /^\*WAITFOR.*/) {
			my $Wait_For_String = $Command;
			my $Wait_Timeout_Override;
			if ($Wait_For_String =~ m/^\*WAITFOR\d/) {
				$Wait_Timeout_Override = $Wait_For_String;
				$Wait_Timeout_Override =~ s/^\*WAITFOR(\d*) (.*)/$1/;
				$Wait_For_String =~ s/^\*WAITFOR(\d*) (.*)/$2/;
			}
			else {
				$Wait_For_String =~ s/\*WAITFOR (.*)/$1/;
			}

			if (!$Wait_Timeout_Override) {$Wait_Timeout_Override = $Wait_Timeout}

			if ($Verbose) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Waiting for the prompt ${Yellow}$Wait_For_String ${Green}for ${Blue}$Wait_Timeout_Override ${Green}seconds${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Waiting for the prompt ${Yellow}$Wait_For_String ${Green}for ${Blue}$Wait_Timeout_Override ${Green}seconds${Clear}\n";
			}
			my $Match;

				my $Line = $Connected_Host->read_line();
				$Match = $Connected_Host->waitfor(".*$Wait_For_String.*", $Wait_Timeout_Override, '-re');
				if ($Match) {
					if ($Verbose) {
						$Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found match for ${Yellow}$Wait_For_String${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found match for ${Yellow}$Wait_For_String${Clear}\n";
					}

					$Command_Output = $Connected_Host->before() . $Connected_Host->match();
					$Command_Output =~ s/\n\e.*//g; # Clears newlines, escapes (ESC)
					$Command_Output =~ s/\e.*//g;
					$Command_Output =~ s/^\Q$Command\E//; # Escaping any potential regex in $Command
					$Command_Output =~ s/.*\r//g;
					$Command_Output =~ s/\Q$Predictable_Prompt\E//g;
					$Command_Output =~ s/^\n//g;
					$Command_Output = 'Matched on: "' . $Command_Output . '"';
					$Exit_Code = 0;
				}
				else {
					print "${Red}No match for '$Wait_For_String' after $Wait_Timeout_Override seconds. Closing the SSH session.${Clear}\n";
					print LOG "${Red}No match for '$Wait_For_String' after $Wait_Timeout_Override seconds. Closing the SSH session.${Clear}\n";
					$Command_Output = "$Wait_For_String Match NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$.";
					$Exit_Code = 7;
				}

			if ($Exit_Code != 0) {
				my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
				$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);
				my $Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
					`exit_code` = ?,
					`output` = ?,
					`task_ended` = NOW(),
					`modified_by` = ?
					WHERE `id` = ?");
				$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);
				print "${Red}No match for '$Wait_For_String' after $Wait_Timeout_Override seconds. Bailing out!${Clear}\n";
				print LOG "${Red}No match for '$Wait_For_String' after $Wait_Timeout_Override seconds. Bailing out!${Clear}\n";
				$Connected_Host->close();
				my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
				$Delete_Queue_Entry->execute($Discovered_Job_ID);
				exit($Exit_Code);
			}
		} # / WAITFOR
		elsif ($Command =~ /^\*SEND.*/) {
			my $Send = $Command;
			$Send =~ s/\*SEND(.*)/$1/;
			$Send =~ s/^\s//;
			if ($Verbose) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Sending '${Yellow}$Send${Green}'${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Sending '${Yellow}$Send${Green}'${Clear}\n";
			}
			$Command_Clean =~ s/\*SEND(.*)/$1/;
			$Command_Clean =~ s/^\s//;
			$Command_Output = "'$Command_Clean' sent.";
			$Connected_Host->send($Send);
			$Exit_Code = 0;
		} # / SEND
		else {

			my $Reboot_Required;
			if ($Command =~ /.*\*REBOOT.*/) {
				$Reboot_Required = 1;
			}
			
			if ($Command =~ /^\*SUDO/) {
				$Command = "if [[ `id -u` -eq 0 ]]; then echo 'Already root'; else sudo su -; fi";
			}

			if ($Verbose) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Command${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Command${Clear}\n";
				if ($Reboot_Required) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Spotted ${Yellow}*REBOOT ${Green}tag, expecting host to disconnect shortly.${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Spotted ${Yellow}*REBOOT ${Green}tag, expecting host to disconnect shortly.${Clear}\n";
				}
			}

			if (!$System_Is_Windows) {
				eval { $Connected_Host->exec("stty raw -echo"); }; &epic_failure('TTY Set', $@, $Command_Output, $Job_Status_Update_ID) if $@;
			}

			my $Prompt = $Connected_Host->peek(0);
			if ($Prompt ne $Predictable_Prompt) {
				my $Set_Prompt_Timeout = 1;
				# Stop system from polluting history file
				$Connected_Host->send(' export HISTFILE=/dev/null');
				# Set a prompt that we can handle
				$Connected_Host->send(" $Set_Predictable_Prompt");
				# Trigger prompt display
				$Connected_Host->send(' echo $PS1');
				$Command_Output = $Connected_Host->read_all();
			}

			$Command =~ s/\*REBOOT/shutdown -r 1 'The Machine is rebooting this host in 1 minute.'/g;
			$Connected_Host->send($Command);

			my $Match;
			if ($Reboot_Required) {
			 	if ($Verbose) {
					$Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Pausing for a moment to watch for potential reboot...${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Pausing for a moment to watch for potential reboot...${Clear}\n";
				}
				
				eval { $Match = $Connected_Host->waitfor("The Machine is rebooting this host.*\|.*Shutdown scheduled for.*\|.*The system is going.*", 90, '-re'); };
				eval { $Command_Output = $Connected_Host->read_all(); }; $Connected_Host = &reboot_control($Host, $Host_ID) if $@;
			}
			else {
				eval { $Command_Output = $Connected_Host->read_all(); }; &epic_failure('PrePrompt Command Output', $@, $Command_Output, $Job_Status_Update_ID) if $@;
			}

			$Connected_Host->send(' Command_Exit=`echo $?`');
			$Connected_Host->send(" $Set_Predictable_Prompt");
			$Connected_Host->send(' echo $PS1');

			if ($Reboot_Required) {
				if ($Match) {
				 	if ($Verbose) {
						$Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System is rebooting...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System is rebooting...${Clear}\n";
					}

					my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
						`job_id`,
						`command`,
						`task_started`,
						`modified_by`
					)
					VALUES (
						?, ?, NOW(), ?
					)");
				
					$Update_Job_Status->execute($Parent_ID, 'System is rebooting...', $User_Name);

					eval { $Command_Output = $Command_Output . $Connected_Host->before(); };
					sleep 120;
					$Connected_Host = &reboot_control($Host, $Host_ID);
				}
				else {
				 	if ($Verbose) {
						$Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System does not seem to be rebooting. Continuing...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}System does not seem to be rebooting. Continuing...${Clear}\n";
						eval { $Match = $Connected_Host->waitfor($Predictable_Prompt, $Wait_Timeout, '-ex'); }; &epic_failure('Wait (Reboot) Command Output', $@, $Command_Output, $Job_Status_Update_ID) if $@;
						eval { $Command_Output = $Command_Output . $Connected_Host->before(); }; &epic_failure('PostPrompt (Reboot) Command Output', $@, $Command_Output, $Job_Status_Update_ID) if $@;
					}
				}
			}
			else {
				eval { $Match = $Connected_Host->waitfor($Predictable_Prompt, $Wait_Timeout, '-ex'); }; &epic_failure('Wait Command Output', $@, $Command_Output, $Job_Status_Update_ID) if $@;
				eval { $Command_Output = $Command_Output . $Connected_Host->before(); }; &epic_failure('PostPrompt Command Output', $@, $Command_Output, $Job_Status_Update_ID) if $@;
			}

			$Command_Output =~ s/\n\e//g; # Clears newlines, escapes (ESC)
			$Command_Output =~ s/\e.*?\[K//g; # Strips escapes (mostly escapes for colours)
			$Command_Output =~ s/^\Q$Command\E//; # Escaping any potential regex in $Command
			$Command_Output =~ s/.*\r//g;
			$Command_Output =~ s/\Q$Predictable_Prompt\E//g;
			$Command_Output =~ s/^\n//g;

			if ($Match) {
			 	if ($Verbose) {
					$Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found prompt. Continuing... ${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found prompt. Continuing... ${Clear}\n";
				}
			}
			elsif (!$Match && !$Reboot_Required) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}Prompt '$Predictable_Prompt' lost while waiting $Wait_Timeout seconds for ${Yellow}$Command${Clear}\n";
				print LOG "${Red}Prompt '$Predictable_Prompt' lost while waiting $Wait_Timeout seconds for ${Yellow}$Command${Clear}\n";
				$Command_Output = "Prompt lost. Command Timeout? Output was:\n\n$Command_Output\n\n Full job log at $DShell_Job_Log_File.";
				$Exit_Code = 12;
				$Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
					`exit_code` = ?,
					`output` = ?,
					`task_ended` = NOW(),
					`modified_by` = ?
					WHERE `id` = ?");
				$Command_Output =~ s/$Predictable_Prompt//g;
				$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);
				my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
					`job_id`,
					`command`,
					`output`,
					`task_ended`,
					`modified_by`
				)
				VALUES (
					?, ?, ?, NOW(), ?
				)");
				$Update_Job_Status->execute($Parent_ID, "### Lost the remote prompt. Command timeout, perhaps?", '', $User_Name);
				my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
				$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);
				my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
				$Delete_Queue_Entry->execute($Discovered_Job_ID);
				exit($Exit_Code);
			}

			if (!$Reboot_Required) {
				my $Exit_Code_Timeout = 1;
				$Connected_Host->read_all();
				$Exit_Code = $Connected_Host->exec('echo $Command_Exit', $Exit_Code_Timeout);
				$Exit_Code =~ s/.*\]//g;
				$Exit_Code =~ s/[^0-9+]//g;
				if ($Exit_Code != 0) {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## Exit code for ${Yellow}$Command${Red}: ${Blue}$Exit_Code${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## Exit code for ${Yellow}$Command${Red}: ${Blue}$Exit_Code${Clear}\n";
					}
					my $Select_Failure_Action = $DB_Connection->prepare("SELECT `on_failure`
						FROM `jobs`
						WHERE `id` = ?
					");
					$Select_Failure_Action->execute($Parent_ID);
					my ($On_Failure) = $Select_Failure_Action->fetchrow_array();
	
					if ($On_Failure) {
						$Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
							`exit_code` = ?,
							`output` = ?,
							`task_ended` = NOW(),
							`modified_by` = ?
							WHERE `id` = ?");
						$Command_Output =~ s/$Predictable_Prompt//g;
						$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);
						my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
							`job_id`,
							`command`,
							`output`,
							`task_ended`,
							`modified_by`
						)
						VALUES (
							?, ?, ?, NOW(), ?
						)");
						$Update_Job_Status->execute($Parent_ID, "### Last action failed. On failure set to kill. Killing job.", '', $User_Name);
						my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
							`status` = ?,
							`modified_by` = ?
							WHERE `id` = ?");
						$Update_Job->execute('11', $User_Name, $Parent_ID);
						my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
						$Delete_Queue_Entry->execute($Discovered_Job_ID);
						exit($Exit_Code);
					}
				}
				else {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Exit code for ${Yellow}$Command${Green}: ${Blue}$Exit_Code${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Exit code for ${Yellow}$Command${Green}: ${Blue}$Exit_Code${Clear}\n";
					}
				}
			}
		}

		$Command_Output =~ s/$Predictable_Prompt//g;
		$Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);
	}

	$Connected_Host->close();

	if ($Top_Level_Job) {
		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute('0', $User_Name, $Parent_ID);
		my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`output`,
			`task_ended`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, NOW(), ?
		)");
	
		$Update_Job_Status->execute($Parent_ID, "### Main job ($Command_Name) complete.\n", '', $User_Name);
		my $End_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
		print LOG "Job completed at $End_Time.\n";
		my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
		$Delete_Queue_Entry->execute($Discovered_Job_ID);
	}
	else {
		my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`output`,
			`task_ended`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, NOW(), ?
		)");

		$Update_Job_Status->execute($Parent_ID, "### Dependency set ($Command_Name) complete.\n", '', $User_Name);
		my $End_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
		print LOG "Dependency set $Command_Name ended at $End_Time.\n";
	}

} # sub processor

sub epic_failure {
	my ($Location, $Error, $Command_Output, $Job_Status_Update_ID) = @_;
	my $Exit_Code;

	if ($Command_Output =~ /closed by remote host/) {
		$Exit_Code = 12;

		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);

		my $Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);

		$Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`exit_code`,
			`output`,
			`task_ended`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, NOW(), ?
		)");
		$Update_Job_Status->execute($Parent_ID, "### SSH connection closed at $Location. $Command_Output", $Exit_Code, $Error, $User_Name);
		print "SSH connection closed at $Location.\n";
		print LOG "SSH connection closed at $Location.\n";
	}
	elsif ($Error =~ /SSHProcessError/) {
		$Exit_Code = 12;
		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);

		my $Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);

		$Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`exit_code`,
			`output`,
			`task_ended`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, NOW(), ?
		)");
		$Update_Job_Status->execute($Parent_ID, "### Job died with SSHProcessError at $Location.", $Exit_Code, $Error, $User_Name);
		print "Job died with SSHProcessError at $Location.\n";
		print LOG "Job died with SSHProcessError at $Location.\n";
	}
	elsif ($Error =~ /SSHConnectionAborted/) {
		$Exit_Code = 12;
		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);

		my $Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);

		$Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`exit_code`,
			`output`,
			`task_ended`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, NOW(), ?
		)");
		$Update_Job_Status->execute($Parent_ID, "### Job died with SSHConnectionAborted at $Location.", $Exit_Code, $Error, $User_Name);
		print "Job died with SSHConnectionAborted at $Location.\n";
		print LOG "Job died with SSHConnectionAborted at $Location.\n";
	}
	elsif ($Error =~ /Ciphertext/) {
		$Exit_Code = 15;
		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);

		my $Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);

		$Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`exit_code`,
			`output`,
			`task_ended`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, NOW(), ?
		)");
		$Update_Job_Status->execute($Parent_ID, "### Job died with SSH Key error at $Location.", $Exit_Code, $Error, $User_Name);
		print "Job died with SSH Key error at $Location.\n";
		print LOG "Job died with SSH Key error at $Location.\n";
	}
	else {
		$Exit_Code = 99;
		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);

		my $Update_Job_Status = $DB_Connection->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);

		$Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
			`job_id`,
			`command`,
			`exit_code`,
			`output`,
			`task_ended`,
			`modified_by`
		)
		VALUES (
			?, ?, ?, ?, NOW(), ?
		)");
		$Update_Job_Status->execute($Parent_ID, "### Job died in unhandled circumstance at $Location.", $Exit_Code, $Error, $User_Name);
		print "Job died in unhandled circumstance at $Location.\n";
		print LOG "Job died in unhandled circumstance at $Location.\n";
	}

	my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
	$Delete_Queue_Entry->execute($Discovered_Job_ID);
	exit($Exit_Code);

} # sub epic_failure

sub reboot_control {

	open( Transaction_Log, "<$DShell_Transactional_File" ) or die "Can't open $DShell_Transactional_File";
	    local $/ = undef;
		$Log_Retention = $Log_Retention . <Transaction_Log>;
			$Log_Retention =~ s/$Predictable_Prompt/\n$Predictable_Prompt/g;
			$Log_Retention =~ s/$Predictable_Prompt//g;
	close Transaction_Log;

	my ($Reboot_Host, $Host_ID) = @_;
	my $SSH;

	# Discover if IP is available instead of hostname
	my $Host_Connection_String;
	## IPv4
	my $Select_IPv4_Block_Links = $DB_Connection->prepare("SELECT `ip`
		FROM `lnk_hosts_to_ipv4_assignments`
		WHERE `host` = ?");
	$Select_IPv4_Block_Links->execute($Host_ID);
	
	my $IPv4_Blocks;
	my $IPv4_Counts = 0;
	my $IPv4_Block;
	while (my $Block_ID = $Select_IPv4_Block_Links->fetchrow_array() ) {

		$IPv4_Counts++;
		my $Select_Blocks = $DB_Connection->prepare("SELECT `ip_block`
			FROM `ipv4_assignments`
			WHERE `id` = ?");
		$Select_Blocks->execute($Block_ID);
	
		$IPv4_Block = $Select_Blocks->fetchrow_array();
	}

	## IPv6
	my $Select_IPv6_Block_Links = $DB_Connection->prepare("SELECT `ip`
		FROM `lnk_hosts_to_ipv6_assignments`
		WHERE `host` = ?");
	$Select_IPv6_Block_Links->execute($Host_ID);
	
	my $IPv6_Blocks;
	my $IPv6_Counts = 0;
	my $IPv6_Block;
	while (my $Block_ID = $Select_IPv6_Block_Links->fetchrow_array() ) {

		$IPv6_Counts++;
		my $Select_Blocks = $DB_Connection->prepare("SELECT `ip_block`
			FROM `ipv6_assignments`
			WHERE `id` = ?");
		$Select_Blocks->execute($Block_ID);
	
		$IPv6_Block = $Select_Blocks->fetchrow_array();
	}

	if ($IPv6_Counts == 1) {
		$Host_Connection_String = $IPv6_Block;
		$Host_Connection_String =~ s/\/.*//;
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Connecting to ${Blue}$Reboot_Host${Green} using IPv6 address ${Yellow}$Host_Connection_String${Clear}\n";
			print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Connecting to ${Blue}$Reboot_Host${Green} using IPv6 address ${Yellow}$Host_Connection_String${Clear}\n";
		}
	}
	elsif ($IPv4_Counts == 1) {
		$Host_Connection_String = $IPv4_Block;
		$Host_Connection_String =~ s/\/.*//;
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Connecting to ${Blue}$Reboot_Host${Green} using IPv4 address ${Yellow}$Host_Connection_String${Clear}\n";
			print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Connecting to ${Blue}$Reboot_Host${Green} using IPv4 address ${Yellow}$Host_Connection_String${Clear}\n";
		}
	}
	elsif ($IPv4_Counts > 1 || $IPv6_Counts > 1) {
		$Host_Connection_String = $Host;
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}There are several possible IP addresses to connect to. Connecting to ${Blue}$Reboot_Host${Green} using IP provided by DNS${Clear}\n";
			print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}There are several possible IP addresses to connect to. Connecting to ${Blue}$Reboot_Host${Green} using IP provided by DNS${Clear}\n";
		}
	}
	else {
		$Host_Connection_String = $Host;
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}No listed IP addresses to connect to. Connecting to ${Blue}$Reboot_Host${Green} using IP provided by DNS${Clear}\n";
			print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}No listed IP addresses to connect to. Connecting to ${Blue}$Reboot_Host${Green} using IP provided by DNS${Clear}\n";
		}
	}
	# / Discover if IP is available instead of hostname

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting to reconnect to ${Yellow}$Reboot_Host${Green}...${Clear}\n";
		print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting to reconnect to ${Yellow}$Reboot_Host${Green}...${Clear}\n";
	}

	my $Private_Key;
	if ($Captured_Key) {

		my $Select_Keys = $DB_Connection->prepare("SELECT `key_name`, `salt`, `key`, `key_username`
			FROM `auth`
			WHERE `id` = ?");

		$Select_Keys->execute($Captured_Key);

		while ( my @Keys = $Select_Keys->fetchrow_array() )
		{
			my $Key_Name = $Keys[0];
			my $Salt = $Keys[1];
			my $Encrypted_Key = $Keys[2];
			$User_Name = $Keys[3];

			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key $Key_Name [$User_Name]${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key $Key_Name [$User_Name]${Clear}\n";
			}

			$Key_Lock =~ s/\n//g;
			my $Key_Unlock = $Key_Lock . $Salt;
			if ($Paper_Trail) {
				print "${Red}## ${Green}Lock ${Yellow}$Key_Lock${Clear}\n";
				print "${Red}## ${Green}Salt ${Yellow}$Salt${Clear}\n";
				print "${Red}## ${Green}Key Code ${Yellow}$Key_Unlock${Clear}\n";
				print LOG "${Red}## ${Green}Lock ${Yellow}$Key_Lock${Clear}\n";
				print LOG "${Red}## ${Green}Salt ${Yellow}$Salt${Clear}\n";
				print LOG "${Red}## ${Green}Key Code ${Yellow}$Key_Unlock${Clear}\n";
			}

			use Crypt::CBC;
			my $Cipher_One = Crypt::CBC->new(
				-key	=>	$Key_Unlock,
				-cipher	=>	'DES',
				-salt	=>	1
			);

			my $Cipher_Two = Crypt::CBC->new(
				-key	=>	$Key_Unlock,
				-cipher	=>	'Rijndael',
				-salt	=>	1
			);
			
			eval { $Encrypted_Key = $Cipher_Two->decrypt($Encrypted_Key); }; &epic_failure('Reboot Cipher Two Decrypt', $@) if $@;
			eval { $Private_Key = $Cipher_One->decrypt($Encrypted_Key); }; &epic_failure('Reboot Cipher One Decrypt', $@) if $@;

			open( FILE, ">$DShell_tmp_Location/tmp.$Discovered_Job_ID" ) or die "Can't open $DShell_tmp_Location/tmp.$Discovered_Job_ID";
			print FILE "$Private_Key";
			close FILE;
			chmod 0600, "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
		}
	}

	my ($SSH_Check, $Attempts);
	($SSH_Check, $Attempts) = &reboot_discovery($Host_Connection_String, $Attempts);

	# Fingerprint check/discovery
	my $Find_Fingerprint = $DB_Connection->prepare("SELECT `fingerprint`
		FROM `host_attributes`
		WHERE `host_id` = ?");
	$Find_Fingerprint->execute($Host_ID);
	my $Previously_Recorded_Fingerprint = $Find_Fingerprint->fetchrow_array();

	my $Hello;
	while (1) {

		if ($User_Name && $User_Password) {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting password login${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting password login${Clear}\n";
			}
			$SSH = Net::SSH::Expect->new (
				host => $Host_Connection_String,
				user => $User_Name,
				password=> $User_Password,
				log_file => $DShell_Transactional_File,
				timeout => $Reboot_Connection_Timeout,
				exp_internal => $Very_Verbose,
				exp_debug => $Very_Verbose,
				raw_pty => 1,
				restart_timeout_upon_receive => 1
			);
			#eval { $SSH->login(); }; &epic_failure('Reboot Login (Password)', $@) if $@; # Disabled login as it circumvents fingerprint verification, which is bad
			eval { $SSH->run_ssh(); }; &epic_failure('Reboot Login (Password)', $@) if $@;

			# Fingerprint
			my $Line = $SSH->read_line();
			my $Fingerprint_Prompt = eval { $SSH->waitfor(".*key fingerprint is.*", $Reboot_Connection_Timeout, '-re'); };
			if ($@) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to discover fingerprint. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Reboot_Max_Attempts${Yellow})...${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to discover fingerprint. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Reboot_Max_Attempts${Yellow})...${Clear}\n";
					($SSH_Check, $Attempts) = &reboot_discovery($Host_Connection_String, $Attempts);
				}
			}

			if ($Fingerprint_Prompt) {

				my $Discovered_Fingerprint = $SSH->match();
				$Discovered_Fingerprint =~ s/.*key fingerprint is (.*)\./$1/g;
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint ${Blue}$Discovered_Fingerprint${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint ${Blue}$Discovered_Fingerprint${Clear}\n";
				}
				
				# Fingerprint validity check
				if (!$Previously_Recorded_Fingerprint) {
					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Previous fingerprint not found for ${Blue}$Host${Green}. Recording and proceeding...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Previous fingerprint not found for ${Blue}$Host${Green}. Recording and proceeding...${Clear}\n";
					}
					my $Update_Fingerprint = $DB_Connection->prepare("INSERT INTO `host_attributes` (
						`host_id`,
						`fingerprint`
					)
					VALUES (
						?, ?
					)ON DUPLICATE KEY UPDATE `fingerprint` = ?");
					$Update_Fingerprint->execute($Host_ID, $Discovered_Fingerprint, $Discovered_Fingerprint);
					$SSH->send('yes');
				}
				elsif ($Discovered_Fingerprint eq $Previously_Recorded_Fingerprint) {

					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Fingerprint matches records, connecting...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Fingerprint matches records, connecting...${Clear}\n";
					}
					$SSH->send('yes');

				}
				else {

					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint mismatch! Ejecting!${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint mismatch! Ejecting!${Clear}\n";

					my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
					$Update_Job->execute('17', $User_Name, $Parent_ID);
					unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
					my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
					$Delete_Queue_Entry->execute($Discovered_Job_ID);
					exit(17);
				}

			}
			else {
				print "${Red}Fingerprint prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
				print LOG "${Red}Fingerprint prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
			}

			# Login (password)
			$Line = $SSH->read_line();
			my $Password_Prompt = $SSH->waitfor(".*password.*", $Reboot_Connection_Timeout, '-re');
			if ($Password_Prompt) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found password prompt ${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found password prompt ${Clear}\n";
				}
				$SSH->send("$User_Password");
			}
			else {
				print "${Red}Password prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
				print LOG "${Red}Password prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
			}

		}
		else {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting key login${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting key login${Clear}\n";
			}
			$SSH = Net::SSH::Expect->new (
				host => $Host_Connection_String,
				user => $User_Name,
				log_file => $DShell_Transactional_File,
				timeout => $Reboot_Connection_Timeout,
				exp_internal => $Very_Verbose,
				exp_debug => $Very_Verbose,
				raw_pty => 1,
				restart_timeout_upon_receive => 1,
				ssh_option => "-i $DShell_tmp_Location/tmp.$Discovered_Job_ID"
			);
			eval { $SSH->run_ssh(); }; &epic_failure('Reboot Login (Key)', $@) if $@;

			# Fingerprint
			my $Line = $SSH->read_line();
			my $Fingerprint_Prompt = eval { $SSH->waitfor(".*key fingerprint is.*", $Reboot_Connection_Timeout, '-re'); };
			if ($@) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to discover fingerprint. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Reboot_Max_Attempts${Yellow})...${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to discover fingerprint. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Reboot_Max_Attempts${Yellow})...${Clear}\n";
					($SSH_Check, $Attempts) = &reboot_discovery($Host_Connection_String, $Attempts);
				}
			}

			if ($Fingerprint_Prompt) {

				my $Discovered_Fingerprint = $SSH->match();
				$Discovered_Fingerprint =~ s/.*key fingerprint is (.*)\./$1/g;
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint ${Blue}$Discovered_Fingerprint${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint ${Blue}$Discovered_Fingerprint${Clear}\n";
				}
				
				# Fingerprint validity check
				if (!$Previously_Recorded_Fingerprint) {
					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Previous fingerprint not found for ${Blue}$Host${Green}. Recording and proceeding...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Previous fingerprint not found for ${Blue}$Host${Green}. Recording and proceeding...${Clear}\n";
					}
					my $Update_Fingerprint = $DB_Connection->prepare("INSERT INTO `host_attributes` (
						`host_id`,
						`fingerprint`
					)
					VALUES (
						?, ?
					)ON DUPLICATE KEY UPDATE `fingerprint` = ?");
					$Update_Fingerprint->execute($Host_ID, $Discovered_Fingerprint, $Discovered_Fingerprint);
					$SSH->send('yes');
				}
				elsif ($Discovered_Fingerprint eq $Previously_Recorded_Fingerprint) {

					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Fingerprint matches records, connecting...${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Fingerprint matches records, connecting...${Clear}\n";
					}
					$SSH->send('yes');
				}
				else {

					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint mismatch! Ejecting!${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint mismatch! Ejecting!${Clear}\n";

					my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
					$Update_Job->execute('17', $User_Name, $Parent_ID);
					unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
					my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
					$Delete_Queue_Entry->execute($Discovered_Job_ID);
					exit(17);
				}
			}
			else {
				print "${Red}Fingerprint prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
				print LOG "${Red}Fingerprint prompt NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$Discovered_Job_ID${Clear}\n";
			}

			my $Key_Passphase_Trap = $SSH->waitfor("Enter passphrase for key", $Reboot_Connection_Timeout, '-re');
			if ($Key_Passphase_Trap) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key passphrase prompt, sending passphrase${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key passphrase prompt, sending passphrase${Clear}\n";
				}
				$SSH->send($Key_Passphrase);
			}
			else {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Key passphrase prompt not found - perhaps this key doesn't have a passphrase${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Key passphrase prompt not found - perhaps this key doesn't have a passphrase${Clear}\n";
				}
			}
		}

		my $Test_Command = 'echo TheMachine';
		$SSH->send($Test_Command);
		#$Hello = eval { $SSH->exec($Test_Command, $Reboot_Connection_Timeout); };
		#eval { $Hello = $SSH->waitfor("\033", 10); };
		eval { $Hello = $SSH->waitfor("Microsoft", $Reboot_Connection_Timeout, '-re'); };

		if ($Hello) {
			$System_Is_Windows = 1;
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Windows detected, setting control mode to 'Money for Old Rope'...${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Windows detected, setting control mode to 'Money for Old Rope'...${Clear}\n";
			}
		}
		else {
			$Hello = eval { $SSH->exec($Test_Command, $Reboot_Connection_Timeout); };
		}

		if ($@) {
			print "Error: $@n";
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to confirm login. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Reboot_Max_Attempts${Yellow})...${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}Connection died while trying to confirm login. Trying again (attempt ${Pink}$Attempts${Yellow} of ${Pink}$Reboot_Max_Attempts${Yellow})...${Clear}\n";
				($SSH_Check, $Attempts) = &reboot_discovery($Host_Connection_String, $Attempts);
			}
		}
		last if $Hello =~ m/TheMachine/;
		last if $System_Is_Windows == 1;
		last if $Reboot_Retry_Count >= $Reboot_Max_Retry_Count;
		if ($Hello =~ m/Permission denied/) {
			print "Supplied credentials failed. Terminating the job.\n";
			print LOG "Supplied credentials failed. Terminating the job.\n";
			my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
			$Update_Job->execute('6', $User_Name, $Parent_ID);
			unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
			my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
			$Delete_Queue_Entry->execute($Discovered_Job_ID);
			exit(6);
		}
	
		my $Connection_Timeout_Plus = $Reboot_Connection_Timeout;
		$Reboot_Retry_Count++;
		$Connection_Timeout_Plus += 10;
		
		if ($Verbose && $Reboot_Retry_Count > 0) {
			print "Tried to connect to $Reboot_Host with $Reboot_Connection_Timeout second timeout but failed. Timeout increased to $Connection_Timeout_Plus, trying again (attempt $Reboot_Retry_Count of $Reboot_Max_Retry_Count)...\n";
			print LOG "Tried to connect to $Reboot_Host with $Reboot_Connection_Timeout second timeout but failed. Timeout increased to $Connection_Timeout_Plus, trying again (attempt $Reboot_Retry_Count of $Reboot_Max_Retry_Count)...\n";
		}
		
		$Reboot_Connection_Timeout = $Connection_Timeout_Plus;
	
	}
	
	if ($Reboot_Retry_Count >= $Reboot_Max_Retry_Count) {
		print "Couldn't connect to $Reboot_Host after $Reboot_Retry_Count attempts. Terminating the job.\n";
		print LOG "Couldn't connect to $Reboot_Host after $Reboot_Retry_Count attempts. Terminating the job.\n";
		my $Update_Job = $DB_Connection->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		$Update_Job->execute('5', $User_Name, $Parent_ID);
		unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
		my $Delete_Queue_Entry = $DB_Connection->prepare("DELETE from `job_queue` WHERE `job_id` = ?");
		$Delete_Queue_Entry->execute($Discovered_Job_ID);
		exit(5);
	}

	$SSH->timeout(1);

	my $Update_Job_Status = $DB_Connection->prepare("INSERT INTO `job_status` (
		`job_id`,
		`command`,
		`output`,
		`task_started`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, NOW(), ?
	)");
	$Update_Job_Status->execute($Parent_ID, "### Connection re-established successfully. Will continue processing momentarily.", '', $User_Name);

	unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";

	my $Set_Predictable_Prompt = "PS1=$Predictable_Prompt";
	$SSH->send(" $Set_Predictable_Prompt");
	$SSH->send(' echo $PS1');

	return $SSH;

} # sub reboot_control

1;