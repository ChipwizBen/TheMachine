#!/usr/bin/perl

use strict;
use Net::SSH::Expect;
use POSIX qw(strftime);

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Short_Name = System_Short_Name();
my $Version = Version();
my $DB_Management = DB_Management();
my $DB_DShell = DB_DShell();
my $DShell_Job_Log_Location = DShell_Job_Log_Location();
my $DShell_tmp_Location = DShell_tmp_Location();
my $DB_IP_Allocation = DB_IP_Allocation();
my $nmap = nmap();
my $grep = sudo_grep();
my $Override = 0;
my $Verbose = 0;
my $Very_Verbose = 0;
my $Ignore_Bad_Exit_Code = 0;
my $Decode = 1;
my $Wait_Timeout = 120;
my $Retry_Count = 0;
my $Max_Retry_Count = 10;
my $Connection_Timeout = 20;

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
	${Blue}-u, --user\t\t${Green}Pass the user that'll execute the job on the remote system (only used without keys)
	${Blue}-k, --key\t\t${Green}Pass the key ID used to connect to the server
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

my $Predictable_Prompt = $System_Short_Name;
	$Predictable_Prompt =~ s/\s//g;
	$Predictable_Prompt = "%$Predictable_Prompt%";

my $Discovered_Job_ID;
my $Parent_ID;
my $Dependent_Command_Set_ID;
my $Dependent_Host_ID;
my $Dependency_Chain_ID;
my $User_Name;
my $Key_ID;
my $Captured_User_Password;
	my $User_Password;
my $Captured_Key;
my $Captured_Key_Lock;
	my $Key_Lock;
my $Captured_Key_Passphrase;
	my $Key_Passphrase;
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
	if ($Parameter eq '-D' || $Parameter eq '--no-dec') {
		$Decode = 0;
		print "${Red}## ${Green}Decode is off (PID: $$).${Clear}\n";
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
	if ($Parameter eq '-k' || $Parameter eq '--key') {
		my @Key = @ARGV;
		while ($Key_ID = shift @Key) {
			if ($Key_ID =~ /-k/ || $Key_ID =~ /--key/) {
				$Key_ID = shift @Key;
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
		while ($Captured_User_Password = shift @Password) {
			if ($Captured_User_Password =~ /-P/ || $Captured_User_Password =~ /--dependencychain/) {
				$Captured_User_Password = shift @Password;
				last;
			}
		}
	}
	if ($Parameter eq '-k' || $Parameter eq '--key') {
		my @Captured_Keys = @ARGV;
		while ($Captured_Key = shift @Captured_Keys) {
			if ($Captured_Key =~ /-k/ || $Captured_Key =~ /--key/) {
				$Captured_Key = shift @Captured_Keys;
				last;
			}
		}
	}
	if ($Parameter eq '-L' || $Parameter eq '--lock') {
		my @Captured_Key_Locks = @ARGV;
		while ($Captured_Key_Lock = shift @Captured_Key_Locks) {
			if ($Captured_Key_Lock =~ /-L/ || $Captured_Key_Lock =~ /--lock/) {
				$Captured_Key_Lock = shift @Captured_Key_Locks;
				if ($Decode) {
					$Key_Lock = dec($Captured_Key_Lock);
				}
				else {
					$Key_Lock = $Captured_Key_Lock;
				}
				last;
			}
		}
	}
	if ($Parameter eq '-K' || $Parameter eq '--passphrase') {
		my @Captured_Key_Passphrases = @ARGV;
		while ($Captured_Key_Passphrase = shift @Captured_Key_Passphrases) {
			if ($Captured_Key_Passphrase =~ /-K/ || $Captured_Key_Passphrase =~ /--passphrase/) {
				$Captured_Key_Passphrase = shift @Captured_Key_Passphrases;
				if ($Decode) {
					$Key_Passphrase = dec($Captured_Key_Passphrase);
				}
				else {
					$Key_Passphrase = $Captured_Key_Passphrase;
				}
				last;
			}
		}
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

if (!defined $Captured_User_Password && !$Captured_Key) {
	use Term::ReadKey;
	ReadMode 4; # noecho TTY mode
	print "Password for $User_Name:";
	$Captured_User_Password = <STDIN>;
	ReadMode 0; # Reset TTY mode
	$User_Password = $Captured_User_Password;
}
else {
	$User_Password = dec($Captured_User_Password);
}

if (!defined $User_Name && !$Captured_Key) {
	print "${Red}## User Name not caught. Exiting... (PID: $$).${Clear}\n";
	my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job->execute('8', $User_Name, $Parent_ID);
	exit(1);
}
if (!defined $User_Password && !$Captured_Key) {
	print "${Red}## Password not caught (User Name was $User_Name). Exiting... (PID: $$).${Clear}\n";
	my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job->execute('9', $User_Name, $Parent_ID);
	exit(1);
}

my $Host;
my $DShell_Job_Log_File = "$DShell_Job_Log_Location/$Parent_ID-$Dependency_Chain_ID";
my $DShell_Transactional_File = "$DShell_Job_Log_Location/$Parent_ID-$Dependency_Chain_ID-Transactions";
open( LOG, ">$DShell_Job_Log_File" ) or die "Can't open $DShell_Job_Log_File";
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
	my $Connected_Host = &host_connection($Host);
	my $Job_Processor = &processor($Host_ID, $Connected_Host, $Command_Set_ID);
	
}
elsif (!$Discovered_Job_ID && $Dependent_Command_Set_ID) {
	print "\n${Green}Starting dependent Command Set ID ${Blue}$Dependent_Command_Set_ID${Green}...${Clear}\n";
		print LOG "\n${Green}Starting dependent Command Set ID ${Blue}$Dependent_Command_Set_ID${Green}...${Clear}\n";
	print "${Red}## ${Green}Discovered Host ID ${Blue}$Dependent_Host_ID${Green} and Command Set ID ${Blue}$Dependent_Command_Set_ID${Green} (Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green}, PID: $$).${Clear}\n";
		print LOG "${Red}## ${Green}Discovered Host ID ${Blue}$Dependent_Host_ID${Green} and Command Set ID ${Blue}$Dependent_Command_Set_ID${Green} (Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green}, PID: $$).${Clear}\n";
	$Host = &host_discovery($Dependent_Host_ID);
	print "${Red}## ${Green}Discovered Host ${Blue}$Host${Green} (Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green}, PID: $$).${Clear}\n";
	my $Connected_Host = &host_connection($Host);
	my $Dependency_Processor = &processor($Dependent_Host_ID, $Connected_Host, $Dependent_Command_Set_ID);
}
else {
	print "${Red}## Did you read the manual or help text? Shitting pants and exiting (PID: $$).${Clear}\n";
	print LOG "${Red}## Did you read the manual or help text? Shitting pants and exiting (PID: $$).${Clear}\n";
	exit(1);
}
close LOG;
system("sed -i 's/$Predictable_Prompt//g' $DShell_Transactional_File");

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
		print LOG "${Yellow}Job ID ${Blue}$Job_ID${Yellow} was not found.${Clear}\n";
		exit(0);
	}
	if ($Status == 0) {
		if ($Override) {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed. Override is enabled, so we're running it again!${Clear}\n";
			print LOG "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed. Override is enabled, so we're running it again!${Clear}\n";
			my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
				`status` = ?,
				`modified_by` = ?
				WHERE `id` = ?");
			$Update_Job->execute('1', $User_Name, $Parent_ID);
		}
		else {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed. Override is NOT enabled, so we won't run it again! Exiting...${Clear}\n";
			print LOG "${Yellow}Job ID ${Blue}$Job_ID${Yellow} has already completed. Override is NOT enabled, so we won't run it again! Exiting...${Clear}\n";
			exit(0);
		}
	}
	if ($Status == 1) {
		if ($Override) {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running. Override is enabled, so we're running a second copy!${Clear}\n";
			print LOG "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running. Override is enabled, so we're running a second copy!${Clear}\n";
			my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
				`status` = ?,
				`modified_by` = ?
				WHERE `id` = ?");
			$Update_Job->execute('1', $User_Name, $Parent_ID);
		}
		else {
			print "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running. Override is NOT enabled, so we won't run a second copy! Exiting...${Clear}\n";
			print LOG "${Yellow}Job ID ${Blue}$Job_ID${Yellow} is already running. Override is NOT enabled, so we won't run a second copy! Exiting...${Clear}\n";
			exit(0);
		}
	}
	if ($Status == 2) {
		print "${Green}Job ID ${Blue}$Job_ID${Green} is paused. Continuing job from the last ran command...${Clear}\n";
		print LOG "${Green}Job ID ${Blue}$Job_ID${Green} is paused. Continuing job from the last ran command...${Clear}\n";
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute('1', $User_Name, $Parent_ID);
	}
	if ($Status == 4 || $Status == 10) {
		print "${Green}Job ID ${Blue}$Job_ID${Green} is pending. Starting job...${Clear}\n";
		print LOG "${Green}Job ID ${Blue}$Job_ID${Green} is pending. Starting job...${Clear}\n";
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute('1', $User_Name, $Parent_ID);
	}
	if ($Status == 3 || $Status == 5 || $Status == 6 || $Status == 7 || $Status == 8 || $Status == 9 || $Status == 11) {
		print "${Green}Job ID ${Blue}$Job_ID${Green} was stopped. Restarting job...${Clear}\n";
		print LOG "${Green}Job ID ${Blue}$Job_ID${Green} was stopped. Restarting job...${Clear}\n";
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
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

	my $Private_Key;
	if ($Captured_Key) {

		my $Select_Keys = $DB_Management->prepare("SELECT `key_name`, `salt`, `key`, `key_username`
			FROM `auth`
			WHERE `id` = ?");

		$Select_Keys->execute($Captured_Key);

		while ( my @Keys = $Select_Keys->fetchrow_array() )
		{
			my $Key_Name = $Keys[0];
			my $Salt = $Keys[1];
			my $Encrypted_Key = $Keys[2];
			$User_Name = $Keys[3];

			if ($Verbose == 1) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key $Key_Name [$User_Name]${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key $Key_Name [$User_Name]${Clear}\n";
			}

			my $Key_Unlock = $Key_Lock . $Salt;

			use Crypt::CBC;
			my $Cipher_One = Crypt::CBC->new(
				-key=>$Key_Unlock,
				-cipher=>'DES',
				-salt   => 1
			);

			my $Cipher_Two = Crypt::CBC->new(
				-key    =>  $Key_Unlock,
				-cipher => 'Rijndael',
				-salt   => 1
			);
			
			eval { $Encrypted_Key = $Cipher_Two->decrypt($Encrypted_Key); }; &epic_failure('Cipher Two Decrypt', $@) if $@;
			eval { $Private_Key = $Cipher_One->decrypt($Encrypted_Key); }; &epic_failure('Cipher One Decrypt', $@) if $@;

			open( FILE, ">$DShell_tmp_Location/tmp.$Discovered_Job_ID" ) or die "Can't open $DShell_tmp_Location/tmp.$Discovered_Job_ID";
			print FILE "$Private_Key";
			close FILE;
			chmod 0600, "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
		}
	}

	my $SSH_Check;
	my $Attempts;
	while ($SSH_Check !~ /open/) {
	
		$Attempts++;
	
		$SSH_Check=`$nmap $Host -PN -p ssh | $grep -E 'open|closed|filtered'`;
		sleep 1;
	
		if ($Attempts >= 10) {
			print "Unresolved host, no route to host or SSH not responding. Terminating the job.\n";
			print LOG "Unresolved host, no route to host or SSH not responding. Terminating the job.\n";
			my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
			$Update_Job->execute('5', $User_Name, $Parent_ID);
			unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
			exit(1);
		}

	}

	my $Hello;
	while (1) {

		if ($User_Name && $User_Password) {
			if ($Verbose == 1) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting password login${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting password login${Clear}\n";
			}
			$SSH = Net::SSH::Expect->new (
				host => $Host,
				user => $User_Name,
				password=> $User_Password,
				log_file => $DShell_Transactional_File,
				timeout => $Connection_Timeout,
				exp_internal => $Very_Verbose,
				exp_debug => 0,
				raw_pty => 1,
				restart_timeout_upon_receive => 1
			);
			eval { $SSH->login(); }; &epic_failure('Login (Password)', $@) if $@;

			my $Fingerprint = $SSH->waitfor("Are you sure you want to continue connecting", '5', '-re');
			if ($Fingerprint) {
				if ($Verbose == 1) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint prompt, accepting{Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint prompt, accepting{Clear}\n";
				}
				$SSH->send('yes');
			}
		}
		else {
			if ($Verbose == 1) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting key login${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting key login${Clear}\n";
			}
			$SSH = Net::SSH::Expect->new (
				host => $Host,
				user => $User_Name,
				log_file => $DShell_Transactional_File,
				timeout => $Connection_Timeout,
				exp_internal => $Very_Verbose,
				exp_debug => 0,
				raw_pty => 1,
				restart_timeout_upon_receive => 1,
				ssh_option => "-i $DShell_tmp_Location/tmp.$Discovered_Job_ID"
			);
			eval { $SSH->run_ssh(); }; &epic_failure('Login (Key)', $@) if $@;

			my $Fingerprint = $SSH->waitfor("Are you sure you want to continue connecting", '5', '-re');
			if ($Fingerprint) {
				if ($Verbose == 1) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint prompt, accepting{Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint prompt, accepting{Clear}\n";
				}
				$SSH->send('yes');
			}
			my $Key_Passphase_Trap = $SSH->waitfor("Enter passphrase for key", '5', '-re');
			if ($Key_Passphase_Trap) {
				if ($Verbose == 1) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key passphrase prompt, sending passphrase${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key passphrase prompt, sending passphrase${Clear}\n";
				}
				$SSH->send($Key_Passphrase);
			}
			else {
				if ($Verbose == 1) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Key passphrase prompt not found - perhaps this key doesn't have a passphrase${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Key passphrase prompt not found - perhaps this key doesn't have a passphrase${Clear}\n";
				}
			}
		}

		sleep 1;

		my $Test_Command = 'id';
		my $ID_Command_Timeout = 1;
		$Hello = $SSH->exec($Test_Command, $ID_Command_Timeout);
	
		last if $Hello =~ m/uid/;
		last if $Retry_Count >= $Max_Retry_Count;
		if ($Hello =~ m/Permission denied/) {
			print "Supplied credentials failed. Terminating the job.\n";
			print LOG "Supplied credentials failed. Terminating the job.\n";
			my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
			$Update_Job->execute('6', $User_Name, $Parent_ID);
			unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
			exit(1);
		}
	
		my $Connection_Timeout_Plus = $Connection_Timeout;
		if ($Verbose && $Retry_Count > 0) {
			print "Tried to connect to $Host with $Connection_Timeout second timeout but failed. Timeout increased to $Connection_Timeout_Plus, trying again (attempt $Retry_Count of $Max_Retry_Count)...\n";
			print LOG "Tried to connect to $Host with $Connection_Timeout second timeout but failed. Timeout increased to $Connection_Timeout_Plus, trying again (attempt $Retry_Count of $Max_Retry_Count)...\n";
		}
		$Retry_Count++;
		$Connection_Timeout_Plus += 2;
		$Connection_Timeout = $Connection_Timeout_Plus;
	
	}
	
	if ($Retry_Count >= $Max_Retry_Count) {
		print "Couldn't connect to $Host after $Retry_Count attempts. Terminating the job.\n";
		print LOG "Couldn't connect to $Host after $Retry_Count attempts. Terminating the job.\n";
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		$Update_Job->execute('5', $User_Name, $Parent_ID);
		unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
		exit(1);
	}

	#$SSH->exec("stty raw -echo");
	$SSH->timeout(5);

	unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";

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
		my ($Verbose_Switch, $Very_Verbose_Switch, $Decode_Switch);
		if ($Verbose) {$Verbose_Switch = '-v '}
		if ($Very_Verbose) {$Very_Verbose_Switch = '-V '}
		if (!$Decode) {$Decode_Switch = '-D '}
		print "${Green}I've discovered that Command Set ID ${Blue}$Process_Command_Set_ID${Green} is dependent on Command Set ID ${Blue}$Command_Set_Dependency_ID${Green}. Processing Command Set ID ${Blue}$Command_Set_Dependency_ID${Green} as dependency ${Blue}$Dependency_Chain_ID${Green}. ${Clear}\n";
			print LOG "${Green}I've discovered that Command Set ID ${Blue}$Process_Command_Set_ID${Green} is dependent on Command Set ID ${Blue}$Command_Set_Dependency_ID${Green}. Processing Command Set ID ${Blue}$Command_Set_Dependency_ID${Green} as dependency ${Blue}$Dependency_Chain_ID${Green}. ${Clear}\n";
		print "${Green}Executing: ${Blue}./d-shell.pl ${Verbose_Switch}${Very_Verbose_Switch}-p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -u $User_Name${Clear}\n";
			print LOG "${Green}Executing: ${Blue}./d-shell.pl ${Verbose_Switch}${Very_Verbose_Switch}-p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -u $User_Name${Clear}\n";
		if ($User_Name && $User_Password) {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Triggering dependency as: ${Blue}./d-shell.pl ${Verbose_Switch}${Very_Verbose_Switch}${Decode_Switch} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -u $User_Name -P $Captured_User_Password${Clear}\n";
			}
			my $System_Exit_Code = system "./d-shell.pl ${Verbose_Switch}${Very_Verbose_Switch}${Decode_Switch} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -u $User_Name -P $Captured_User_Password";
			if ($System_Exit_Code == 0) {
				print "${Green}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green} execution complete. Exit code was $System_Exit_Code.${Clear}\n";
				print LOG "${Green}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green} execution complete. Exit code was $System_Exit_Code.${Clear}\n";
			}
			else {
				print "${Red}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Red} execution complete. Exit code was $System_Exit_Code. Exiting :-(${Clear}\n";
				print LOG "${Red}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Red} execution complete. Exit code was $System_Exit_Code. Exiting :-(${Clear}\n";
				exit(1);
			}
		}
		else {
			my $System_Exit_Code;
			if ($Captured_Key_Passphrase) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Triggering dependency as: ${Blue}./d-shell.pl ${Verbose_Switch}${Very_Verbose_Switch}${Decode_Switch} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -k $Captured_Key -L $Captured_Key_Lock -K $Captured_Key_Passphrase${Clear}\n";
				}
				$System_Exit_Code = system "./d-shell.pl ${Verbose_Switch}${Very_Verbose_Switch}${Decode_Switch} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -k $Captured_Key -L $Captured_Key_Lock -K $Captured_Key_Passphrase";
			}
			else {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Triggering dependency as: ${Blue}./d-shell.pl ${Verbose_Switch}${Very_Verbose_Switch}${Decode_Switch} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -k $Captured_Key -L $Captured_Key_Lock${Clear}\n";
				}
				$System_Exit_Code = system "./d-shell.pl ${Verbose_Switch}${Very_Verbose_Switch}${Decode_Switch} -p $Parent_ID -c $Command_Set_Dependency_ID -H $Host_ID -d $Dependency_Chain_ID -k $Captured_Key -L $Captured_Key_Lock";
			}
			if ($System_Exit_Code == 0) {
				print "${Green}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green} execution complete. Exit code was $System_Exit_Code.${Clear}\n";
				print LOG "${Green}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Green} execution complete. Exit code was $System_Exit_Code.${Clear}\n";
			}
			else {
				print "${Red}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Red} execution complete. Exit code was $System_Exit_Code. Exiting :-(${Clear}\n";
				print LOG "${Red}Dependency Chain ID ${Blue}$Dependency_Chain_ID${Red} execution complete. Exit code was $System_Exit_Code. Exiting :-(${Clear}\n";
				exit(1);
			}
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
		print LOG "Job started at $Start_Time.";
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
		print LOG "Dependency Set $Dependency_Chain_ID, $Command_Name, started at $Start_Time.";
	}



	my @Commands = split('\r', $Commands);
	my $Command_Count = $#Commands;
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
				print LOG "${Green}Job paused by $Query_Modified_By.${Clear}\n";
				$Job_Paused = 'Yes';
			}
			else {
				$Job_Paused = 'No';
			}
			if ($Query_Status == 3) {
				print "${Red}Job killed by $Query_Modified_By. Terminating job.${Clear}\n";
				print LOG "${Red}Job killed by $Query_Modified_By. Terminating job.${Clear}\n";
				my $End_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
				print LOG "Job killed at $End_Time by $Query_Modified_By.";
				exit(0);
			}
		}

		my $Set_Predictable_Prompt = "PS1=$Predictable_Prompt";

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
		my $Exit_Code;
		if (($Command =~ /^#/) || ($Command eq undef)) {
			if ($Verbose == 1) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Skipping comment/empty line ${Blue}$Command${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Skipping comment/empty line ${Blue}$Command${Clear}\n";
			}
			$Command_Output = 'Skipped comment / empty line.';
			$Exit_Code = 0;
		}
		elsif ($Command =~ /^\*PAUSE.*/) {
			my $Pause = $Command;
			$Pause =~ s/\*PAUSE (.*)/$1/;
			if ($Verbose == 1) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Pausing for ${Blue}$Pause ${Green}seconds${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Pausing for ${Blue}$Pause ${Green}seconds${Clear}\n";
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
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Performing a snapshot operation${Clear}\n";
			}
			elsif ($Snapshot eq 'COUNT') {
				if ($Verbose == 1) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Counting snapshots${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Counting snapshots${Clear}\n";
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
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Taking a snapshot${Clear}\n";
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
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing $System_Short_Name snapshots${Clear}\n";
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
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing ALL snapshots${Clear}\n";
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
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Waiting for the prompt ${Yellow}$Wait ${Green}for ${Blue}$Wait_Timeout ${Green}seconds${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Waiting for the prompt ${Yellow}$Wait ${Green}for ${Blue}$Wait_Timeout ${Green}seconds${Clear}\n";
			}
			my $Match;
			LINEFEED: while ( defined (my $Line = $Connected_Host->read_line()) ) {
				$Match = $Connected_Host->waitfor(".*$Wait.*", $Wait_Timeout, '-re');
				if ($Match) {
					if ($Verbose == 1) {
						$Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found match for ${Yellow}$Wait${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found match for ${Yellow}$Wait${Clear}\n";
					}
					$Command_Output = "$Wait Match Found!";
					$Exit_Code = 0;
				}
				else {
					print "${Red}No match for '$Wait' after $Wait_Timeout seconds. Closing the SSH session.${Clear}\n";
					print LOG "${Red}No match for '$Wait' after $Wait_Timeout seconds. Closing the SSH session.${Clear}\n";
					$Command_Output = "$Wait Match NOT Found! Last line was: $Line. Full job log at $DShell_Job_Log_Location/$.";
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
				print LOG "${Red}No match for '$Wait' after $Wait_Timeout seconds. Bailing out!${Clear}\n";
				$Connected_Host->close();
				exit(1);
			}
		}
		elsif ($Command =~ /^\*SEND.*/) {
			my $Send = $Command;
			$Send =~ s/\*SEND (.*)/$1/;
			if ($Verbose == 1) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Sending '${Yellow}$Send${Green}'${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Sending '${Yellow}$Send${Green}'${Clear}\n";
			}
			if ($Send eq '') {$Send = ' '}
			$Connected_Host->send($Send);
			$Command_Output = "'$Send' sent.";
			$Exit_Code = 0;
		}
		else {

			my $Reboot_Required;
			if ($Command =~ /.*\*REBOOT.*/) {
				$Reboot_Required = 1;
			}

			if ($Verbose == 1) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Command${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Command${Clear}\n";
				if ($Reboot_Required) {
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Spotted ${Yellow}*REBOOT ${Green}tag, expecting host to die shortly.${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Spotted ${Yellow}*REBOOT ${Green}tag, expecting host to die shortly.${Clear}\n";
				}
			}

			my $Set_Prompt_Timeout = 1;
			# Stop system from polluting history file
			$Connected_Host->exec(' export HISTFILE=/dev/null', 1);
		
			# Set a prompt that we can handle
			$Connected_Host->exec($Set_Predictable_Prompt, $Set_Prompt_Timeout);

			$Command =~ s/\*REBOOT/reboot/g;
			$Connected_Host->send($Command);

			if ($Reboot_Required) {		
				eval { $Command_Output = $Connected_Host->read_all(); }; $Connected_Host = &reboot_control($Host) if $@;
			}
			else {
				eval { $Command_Output = $Connected_Host->read_all(); }; &epic_failure('PrePrompt Command Output', $@, $Command_Output, $Job_Status_Update_ID) if $@;
				$Connected_Host->send(' Command_Exit=`echo $?`');
				$Connected_Host->send(" $Set_Predictable_Prompt");
				$Connected_Host->send(' echo $PS1');
			}

			my $Match;
			if ($Reboot_Required) {
				eval { $Match = $Connected_Host->waitfor($Predictable_Prompt, $Wait_Timeout, '-ex'); }; $Connected_Host = &reboot_control($Host) if $@;
				eval { $Command_Output = $Command_Output . $Connected_Host->before(); }; $Connected_Host = &reboot_control($Host, $Job_Status_Update_ID) if $@;
			}
			else {
				eval { $Match = $Connected_Host->waitfor($Predictable_Prompt, $Wait_Timeout, '-ex'); };  &epic_failure('Wait Command Output', $@, $Command_Output, $Job_Status_Update_ID) if $@;
				eval { $Command_Output = $Command_Output . $Connected_Host->before(); }; &epic_failure('PostPrompt Command Output', $@, $Command_Output, $Job_Status_Update_ID) if $@;
			}

				
			$Command_Output =~ s/\n\e.*//g; # Clears newlines, escapes (ESC)
			$Command_Output =~ s/\e.*//g;
			$Command_Output =~ s/^\Q$Command\E//; # Escaping any potential regex in $Command
			$Command_Output =~ s/.*\r//g;
			$Command_Output =~ s/\Q$Predictable_Prompt\E//g;
	
			if ($Match) {
			 	if ($Verbose == 1) {
					$Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Prompt '$Predictable_Prompt' found. Continuing... ${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Prompt '$Predictable_Prompt' found. Continuing... ${Clear}\n";
				}
			}
			elsif (!$Match && !$Reboot_Required) {
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}Prompt '$Predictable_Prompt' lost while waiting $Wait_Timeout seconds for ${Yellow}$Command${Clear}\n";
				print LOG "${Red}Prompt '$Predictable_Prompt' lost while waiting $Wait_Timeout seconds for ${Yellow}$Command${Clear}\n";
				$Command_Output = "Prompt lost. Command Timeout? Output was:\n\n$Command_Output\n\n Full job log at $DShell_Job_Log_File.";
				$Exit_Code = 12;
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
				$Update_Job_Status->execute($Parent_ID, "### Lost the remote prompt. Command timeout, perhaps?", '', 'System');
				my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
					`status` = ?,
					`modified_by` = ?
					WHERE `id` = ?");
				$Update_Job->execute( $Exit_Code, $User_Name, $Parent_ID);
				exit($Exit_Code);
			}

			if (!$Reboot_Required) {
				my $Exit_Code_Timeout = 1;
				$Exit_Code = $Connected_Host->exec('echo $Command_Exit', $Exit_Code_Timeout);
				$Exit_Code =~ s/.*\]//g;
				$Exit_Code =~ s/[^0-9+]//g;
				if ($Exit_Code != 0) {
					if ($Verbose) {
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## Exit code for ${Yellow}$Command${Red}: ${Blue}$Exit_Code${Clear}\n";
						print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## Exit code for ${Yellow}$Command${Red}: ${Blue}$Exit_Code${Clear}\n";
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
						$Update_Job->execute('11', $User_Name, $Parent_ID);
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
		$Update_Job->execute('0', $User_Name, $Parent_ID);
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
		print LOG "Job completed at $End_Time.";
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
		print LOG "Dependency Set ID $Dependency_Chain_ID, $Command_Name, ended at $End_Time.";
	}

} # sub processor

sub epic_failure {
	my ($Location, $Error, $Command_Output, $Job_Status_Update_ID) = @_;
	my $Exit_Code;

	if ($Command_Output =~ /closed by remote host/) {
		$Exit_Code = 12;

		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);

		my $Update_Job_Status = $DB_DShell->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);

		$Update_Job_Status = $DB_DShell->prepare("INSERT INTO `job_status` (
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
		$Update_Job_Status->execute($Parent_ID, "### SSH connection closed at $Location. $Command_Output", $Exit_Code, $Error, 'System');
		print "SSH connection closed at $Location.\n";
		print LOG "SSH connection closed at $Location.\n";
	}
	elsif ($Error =~ /SSHProcessError/) {
		$Exit_Code = 12;
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);

		my $Update_Job_Status = $DB_DShell->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);

		$Update_Job_Status = $DB_DShell->prepare("INSERT INTO `job_status` (
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
		$Update_Job_Status->execute($Parent_ID, "### Job died with SSHProcessError at $Location.", $Exit_Code, $Error, 'System');
		print "Job died with SSHProcessError at $Location.\n";
		print LOG "Job died with SSHProcessError at $Location.\n";
	}
	elsif ($Error =~ /SSHConnectionAborted/) {
		$Exit_Code = 12;
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);

		my $Update_Job_Status = $DB_DShell->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);

		$Update_Job_Status = $DB_DShell->prepare("INSERT INTO `job_status` (
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
		$Update_Job_Status->execute($Parent_ID, "### Job died with SSHConnectionAborted at $Location.", $Exit_Code, $Error, 'System');
		print "Job died with SSHConnectionAborted at $Location.\n";
		print LOG "Job died with SSHConnectionAborted at $Location.\n";
	}
	elsif ($Error =~ /Ciphertext/) {
		$Exit_Code = 15;
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);

		my $Update_Job_Status = $DB_DShell->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);

		$Update_Job_Status = $DB_DShell->prepare("INSERT INTO `job_status` (
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
		$Update_Job_Status->execute($Parent_ID, "### Job died with SSH Key error at $Location.", $Exit_Code, $Error, 'System');
		print "Job died with SSH Key error at $Location.\n";
		print LOG "Job died with SSH Key error at $Location.\n";
	}
	else {
		$Exit_Code = 99;
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job->execute($Exit_Code, $User_Name, $Parent_ID);

		my $Update_Job_Status = $DB_DShell->prepare("UPDATE `job_status` SET
			`exit_code` = ?,
			`output` = ?,
			`task_ended` = NOW(),
			`modified_by` = ?
			WHERE `id` = ?");
		$Update_Job_Status->execute($Exit_Code, $Command_Output, $User_Name, $Job_Status_Update_ID);

		$Update_Job_Status = $DB_DShell->prepare("INSERT INTO `job_status` (
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
		$Update_Job_Status->execute($Parent_ID, "### Job died in unhandled circumstance at $Location.", $Exit_Code, $Error, 'System');
		print "Job died in unhandled circumstance at $Location.\n";
		print LOG "Job died in unhandled circumstance at $Location.\n";
	}

	exit($Exit_Code);

} # sub epic_failure

sub reboot_control {

	my $Reboot_Host = $_[0];
	my $SSH;

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting to reconnect to ${Yellow}$Reboot_Host ${Green}... ${Clear}\n";
		print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting to reconnect to ${Yellow}$Reboot_Host ${Green}... ${Clear}\n";
	}

	my $Private_Key;
	if ($Captured_Key) {

		my $Select_Keys = $DB_Management->prepare("SELECT `key_name`, `salt`, `key`, `key_username`
			FROM `auth`
			WHERE `id` = ?");

		$Select_Keys->execute($Captured_Key);

		while ( my @Keys = $Select_Keys->fetchrow_array() )
		{
			my $Key_Name = $Keys[0];
			my $Salt = $Keys[1];
			my $Encrypted_Key = $Keys[2];
			$User_Name = $Keys[3];

			if ($Verbose == 1) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key $Key_Name [$User_Name]${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key $Key_Name [$User_Name]${Clear}\n";
			}

			my $Key_Unlock = $Key_Lock . $Salt;

			use Crypt::CBC;
			my $Cipher_One = Crypt::CBC->new(
				-key=>$Key_Unlock,
				-cipher=>'DES',
				-salt   => 1
			);

			my $Cipher_Two = Crypt::CBC->new(
				-key    =>  $Key_Unlock,
				-cipher => 'Rijndael',
				-salt   => 1
			);
			
			eval { $Encrypted_Key = $Cipher_Two->decrypt($Encrypted_Key); }; &epic_failure('Cipher Two Decrypt', $@) if $@;
			eval { $Private_Key = $Cipher_One->decrypt($Encrypted_Key); }; &epic_failure('Cipher One Decrypt', $@) if $@;

			open( FILE, ">$DShell_tmp_Location/tmp.$Discovered_Job_ID" ) or die "Can't open $DShell_tmp_Location/tmp.$Discovered_Job_ID";
			print FILE "$Private_Key";
			close FILE;
			chmod 0600, "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
		}
	}

	my $SSH_Check;
	my $Attempts;
	while ($SSH_Check !~ /open/) {
	
		$Attempts++;
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempt ${Yellow}$Attempts${Green} at restarting SSH session... ${Clear}\n";
			print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempt ${Yellow}$Attempts${Green} at restarting SSH session... ${Clear}\n";
		}
		$SSH_Check=`$nmap $Reboot_Host -PN -p ssh | $grep -E 'open|closed|filtered'`;
		sleep 1;
	
		if ($Attempts >= 1200) {
			print "Host did not recover after a reboot. Terminating the job.\n";
			print LOG "Host did not recover after a reboot. Terminating the job.\n";
			my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
			$Update_Job->execute('14', $User_Name, $Parent_ID);
			exit(1);
		}
	
	}

	my $Hello;
	while (1) {

		if ($User_Name && $User_Password) {
			if ($Verbose == 1) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting password login${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting password login${Clear}\n";
			}
			$SSH = Net::SSH::Expect->new (
				host => $Host,
				user => $User_Name,
				password=> $User_Password,
				log_file => $DShell_Transactional_File,
				timeout => $Connection_Timeout,
				exp_internal => $Very_Verbose,
				exp_debug => 0,
				raw_pty => 1,
				restart_timeout_upon_receive => 1
			);
			eval { $SSH->login(); }; &epic_failure('Reboot Login (Password)', $@) if $@;

			my $Fingerprint = $SSH->waitfor("Are you sure you want to continue connecting", '5', '-re');
			if ($Fingerprint) {
				if ($Verbose == 1) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint prompt, accepting{Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint prompt, accepting{Clear}\n";
				}
				$SSH->send('yes');
			}
		}
		else {
			if ($Verbose == 1) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting key login${Clear}\n";
				print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting key login${Clear}\n";
			}
			$SSH = Net::SSH::Expect->new (
				host => $Host,
				user => $User_Name,
				log_file => $DShell_Transactional_File,
				timeout => $Connection_Timeout,
				exp_internal => $Very_Verbose,
				exp_debug => 0,
				raw_pty => 1,
				restart_timeout_upon_receive => 1,
				ssh_option => "-i $DShell_tmp_Location/tmp.$Discovered_Job_ID"
			);
			eval { $SSH->run_ssh(); }; &epic_failure('Reboot Login (Key)', $@) if $@;

			my $Fingerprint = $SSH->waitfor("Are you sure you want to continue connecting", '5', '-re');
			if ($Fingerprint) {
				if ($Verbose == 1) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint prompt, accepting{Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint prompt, accepting{Clear}\n";
				}
				$SSH->send('yes');
			}
			my $Key_Passphase_Trap = $SSH->waitfor("Enter passphrase for key", $Wait_Timeout, '-re');
			if ($Key_Passphase_Trap) {
				if ($Verbose == 1) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key passphrase prompt, sending passphrase${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found key passphrase prompt, sending passphrase${Clear}\n";
				}
				$SSH->send($Key_Passphrase);
			}
			else {
				if ($Verbose == 1) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Key passphrase prompt not found - perhaps this key doesn't have a passphrase${Clear}\n";
					print LOG "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Key passphrase prompt not found - perhaps this key doesn't have a passphrase${Clear}\n";
				}
			}
		}

		sleep 1;

		my $Test_Command = 'id';
		my $ID_Command_Timeout = 1;
		$Hello = $SSH->exec($Test_Command, $ID_Command_Timeout);
	
		last if $Hello =~ m/uid/;
		last if $Retry_Count >= $Max_Retry_Count;
		if ($Hello =~ m/Permission denied/) {
			print "Supplied credentials failed. Terminating the job.\n";
			print LOG "Supplied credentials failed. Terminating the job.\n";
			my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
			`status` = ?,
			`modified_by` = ?
			WHERE `id` = ?");
			$Update_Job->execute('6', $User_Name, $Parent_ID);
			unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
			exit(1);
		}
	
		my $Connection_Timeout_Plus = $Connection_Timeout;
		if ($Verbose && $Retry_Count > 0) {
			print "Tried to connect to $Reboot_Host with $Connection_Timeout second timeout but failed. Timeout increased to $Connection_Timeout_Plus, trying again (attempt $Retry_Count of $Max_Retry_Count)...\n";
			print LOG "Tried to connect to $Reboot_Host with $Connection_Timeout second timeout but failed. Timeout increased to $Connection_Timeout_Plus, trying again (attempt $Retry_Count of $Max_Retry_Count)...\n";
		}
		$Retry_Count++;
		$Connection_Timeout_Plus += 2;
		$Connection_Timeout = $Connection_Timeout_Plus;
	
	}
	
	if ($Retry_Count >= $Max_Retry_Count) {
		print "Couldn't connect to $Reboot_Host after $Retry_Count attempts. Terminating the job.\n";
		print LOG "Couldn't connect to $Reboot_Host after $Retry_Count attempts. Terminating the job.\n";
		my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		$Update_Job->execute('5', $User_Name, $Parent_ID);
		unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";
		exit(1);
	}

	#$SSH->exec("stty raw -echo");
	$SSH->timeout(5);

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
	$Update_Job_Status->execute($Parent_ID, "### System rebooted successfully. Will continue processing momentarily.", '', 'System');

	unlink "$DShell_tmp_Location/tmp.$Discovered_Job_ID";

	my $Set_Predictable_Prompt = "PS1=$Predictable_Prompt";
	$SSH->send(" $Set_Predictable_Prompt");
	$SSH->send(' echo $PS1');

	return $SSH;

} # sub reboot_control

1;