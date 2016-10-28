#!/usr/bin/perl

use strict;

use DBI;
use POSIX qw(strftime);
use Net::SFTP::Foreign;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Date = strftime "%Y-%m-%d", localtime;
my $DB_Connection = DB_Connection();
my $MD5Sum = md5sum();
my $Cut = cut();
my $Sudoers_Location = Sudoers_Location();
	my $MD5_Checksum = `$MD5Sum $Sudoers_Location | $Cut -d ' ' -f 1`;
my $Distribution_Log_Location = Distribution_Log_Location();
my $Distribution_tmp_Location = Distribution_tmp_Location();
my $Green = "\e[0;32;40m";
my $Red = "\e[0;31;40m";
my $Blue = "\e[1;34;10m";
my $Clear = "\e[0m";

$| = 1;
my $Override;
my $Verbose;

foreach my $Parameter (@ARGV) {
	if ($Parameter eq '--override') {$Override = 1}
	if ($Parameter eq '--verbose' || $Parameter eq '-v') {$Verbose = 1}
	if ($Parameter eq '-h' || $Parameter eq '--help') {
		print "\nOptions are:\n\t--override\tOverrides any database lock\n\t-v, --verbose\tTurns on verbose output\n\n";
		exit(0);
	}
}

# Safety check for other running distribution processes

	my $Select_Locks = $DB_Connection->prepare("SELECT `sudoers-build`, `sudoers-distribution` FROM `lock`");
	$Select_Locks->execute();

	my ($Sudoers_Build_Lock, $Sudoers_Distribution_Lock) = $Select_Locks->fetchrow_array();

		if ($Sudoers_Build_Lock == 1 || $Sudoers_Distribution_Lock == 1) {
			if ($Override) {
				print "Override detected. (CTRL + C to cancel)...\n\n";
				print "Continuing in... 5\r";
				sleep 1;
				print "Continuing in... 4\r";
				sleep 1;
				print "Continuing in... 3\r";
				sleep 1;
				print "Continuing in... 2\r";
				sleep 1;
				print "Continuing in... 1\r";
				sleep 1;
			}
			else {
				print "Another build or distribution process is running. Use --override to continue anyway. Exiting...\n";
				exit(1);
			}
		}
		else {
			$DB_Connection->do("UPDATE `lock` SET
				`sudoers-distribution` = '1',
				`last-sudoers-distribution-started` = NOW()");
		}

my $Select_Hosts = $DB_Connection->prepare("SELECT `id`, `hostname`, `ip`
	FROM `hosts`
	ORDER BY `last_modified` DESC");

$Select_Hosts->execute();

HOST: while ( my @Select_Hosts = $Select_Hosts->fetchrow_array() )
{

	my $DBID = $Select_Hosts[0];
	my $Hostname = $Select_Hosts[1];
	my $IP = $Select_Hosts[2];

		my $Host_String;
		if ($IP eq 'DHCP') {
			$Host_String = $Hostname;
		}
		else {
			$Host_String = $IP;
		}

	my $Select_Parameters = $DB_Connection->prepare("SELECT `sftp_port`, `user`, `key_path`, `timeout`, `remote_sudoers_path`
		FROM `distribution`
		WHERE `host_id` = ?");

	$Select_Parameters->execute($DBID);

	while ( my @Select_Parameters = $Select_Parameters->fetchrow_array() )
	{

		my $SFTP_Port = $Select_Parameters[0];
		my $User = $Select_Parameters[1];
		my $Key_Path = $Select_Parameters[2];
		my $Timeout = $Select_Parameters[3];
		my $Remote_Sudoers = $Select_Parameters[4];

		my $Error;


		### Connection
		if ($Verbose) {
			print "Attempting to connect to $Hostname with $User\@$Host_String:$SFTP_Port and key $Key_Path...\n";
		}
		else {
			print "$Hostname\t";
		}

		open my $DevNull, '>', '/dev/null' or die "unable to open /dev/null";

		my $SFTP = Net::SFTP::Foreign->new(
			"$User\@$Host_String",
			port => $SFTP_Port,
			key_path => $Key_Path,
			timeout => $Timeout,
			stderr_fh => $DevNull # Suppress banners
		);
		$SFTP->error and $Error = "Connection Failed: " . $SFTP->error;

		if ($SFTP->status == 0) {
			if ($Verbose) {
				print "Connected successfully to $Hostname ($IP) on port $SFTP_Port.\n";
			}
			else {
				print "${Green}[Connected]${Clear}\t";
			}
		}
		else {

			if ($Error =~ /Connection to remote server stalled/) {
				if ($Verbose) {
					$Error = $Error . " 
    Hints: 
    1) Check that the remote host's key fingerprint is stored in known_hosts
    2) Check for a route to the remote host
    3) Check that your $Timeout second Timeout value is high enough"
				}
				else {
					print "${Red}[Connection Failed]${Clear}\n";
				}
			}

			elsif ($Error =~ /Connection to remote server is broken/) {
				if ($Verbose) {
					$Error = $Error ." 
    Hints: 
    1) Check that the remote host's key fingerprint is stored in known_hosts
    2) Check that the user name is correct
    3) Check that the IP address or port are correct
    4) Check that the key identity file exists
    5) Check that there are sufficient permissions to read the key identity file";

					print "$Error\n\n";
				}
				else {
					print "${Red}[Connection Failed]${Clear}\n";
				}
			}

			my $Update_Status = $DB_Connection->prepare("UPDATE `distribution` SET
				`status` = ?,
				`last_updated` = NOW()
				WHERE `host_id` = ?");
			$Update_Status->execute($Error, $DBID);
			next HOST;
			undef $SFTP;
		}

		### / Connection

		### Sudoers Push
		$SFTP->put(
			"$Sudoers_Location",
			"$Remote_Sudoers",
			best_effort => 1, # Not fatal if unable to set permissions and timestamp
			copy_time => 1, # Timestamp remote sudoers
			copy_perm => 0, # Do not copy permissions
			atomic => 1) # Transfer to temp file first, then overwrite $Remote_Sudoers
			or $Error = "Push Failed: " . $SFTP->error;

		if ($SFTP->status == 0) {
			if ($Verbose) {
				print "$Remote_Sudoers written successfully to $Hostname ($IP).\n\n";
			}
			else {
				print "${Green}[Transfer Completed]${Clear}\n";
			}
			my $Status="OK: $Remote_Sudoers written successfully to $Hostname ($IP). Sudoers MD5: $MD5_Checksum";
			my $Update_Status = $DB_Connection->prepare("UPDATE `distribution` SET
				`status` = ?,
				`last_updated` = NOW(),
				`last_successful_transfer` = NOW()
				WHERE `host_id` = ?");
			$Update_Status->execute($Status, $DBID);
			undef $SFTP;
		}
		else {

			if ($Error =~ /Permission\sdenied/) {
				if ($Verbose) {
					$Error = $Error . " 
    Hints: 
    1) Check that $User can write to $Remote_Sudoers"
				}
				else {
					print "${Red}[Transfer Failed]${Clear}\n";
				}
			}

			elsif ($Error =~ /Couldn't open remote file/) {
				if ($Verbose) {
					$Error = $Error . " 
    Hints: 
    1) Check that the remote path is correct
    2) If the Remote Server uses chroot, try making the path relative (i.e. path/sudoers instead of /path/sudoers)";
    				print "$Error\n\n";
				}
				else {
					print "${Red}[Transfer Failed]${Clear}\n";
				}
			}

			my $Update_Status = $DB_Connection->prepare("UPDATE `distribution` SET
				`status` = ?,
				`last_updated` = NOW()
				WHERE `host_id` = ?");
			$Update_Status->execute($Error, $DBID);
			undef $SFTP;
		}

		### / Sudoers Push

	}
}

$DB_Connection->do("UPDATE `lock` SET 
		`sudoers-distribution` = '0',
		`last-sudoers-distribution-finished` = NOW()");


sub fingerprint_verification {

	my $nmap = nmap();
	my $grep = sudo_grep();

	my $Host = $_[0];
	my $Host_ID = $_[1];
	my $SSH;
	
	my $Select_Hosts = $DB_Connection->prepare("SELECT `id`, `hostname`, `ip`
		FROM `hosts`
		ORDER BY `last_modified` DESC");
	
	$Select_Hosts->execute();

	HOST: while ( my @Select_Hosts = $Select_Hosts->fetchrow_array() )
	{
	
		my $DBID = $Select_Hosts[0];
		my $Hostname = $Select_Hosts[1];
		my $IP = $Select_Hosts[2];

		my $Distribution_Transactional_File = "$Distribution_Log_Location/DSMS-Trans-$Hostname";

			my $Host_String;
			if ($IP eq 'DHCP') {
				$Host_String = $Hostname;
			}
			else {
				$Host_String = $IP;
			}
	
		my $Select_Parameters = $DB_Connection->prepare("SELECT `sftp_port`, `user`, `key_path`, `timeout`, `remote_sudoers_path`
			FROM `distribution`
			WHERE `host_id` = ?");
	
		$Select_Parameters->execute($DBID);
	
		while ( my @Select_Parameters = $Select_Parameters->fetchrow_array() )
		{

			my $SFTP_Port = $Select_Parameters[0];
			my $User_Name = $Select_Parameters[1];
			my $Key_Path = $Select_Parameters[2];
			my $Connection_Timeout = $Select_Parameters[3];
			my $Remote_Sudoers = $Select_Parameters[4];


			my $Private_Key;
			my $SSH_Check;
			my $Attempts;
			while ($SSH_Check !~ /open/) {
		
				$Attempts++;
		
				$SSH_Check=`$nmap $Host -PN -p ssh | $grep -E 'open'`;
				sleep 1;
			
				if ($Attempts >= 10) {
					print "Unresolved host, no route to host or SSH not responding. Terminating the transfer.\n";
					exit(1);
				}
			}
		
			# Fingerprint check/discovery
			my $Find_Fingerprint = $DB_Connection->prepare("SELECT `fingerprint`
				FROM `host_attributes`
				WHERE `host_id` = ?");
			$Find_Fingerprint->execute($Host_ID);
			my $Previously_Recorded_Fingerprint = $Find_Fingerprint->fetchrow_array();
		
		
			my $Hello;
			while (1) {
		
				if ($Verbose == 1) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting key login${Clear}\n";
				}
				$SSH = Net::SSH::Expect->new (
					host => $Host,
					user => $User_Name,
					log_file => $Distribution_Transactional_File,
					timeout => $Connection_Timeout,
					raw_pty => 1,
					restart_timeout_upon_receive => 1,
					ssh_option => "-i $Key_Path -o UserKnownHostsFile=$Distribution_tmp_Location/$Host"
				);
				eval { $SSH->run_ssh(); }; &epic_failure('Login (Key)', $@) if $@;
		
				# Fingerprint
				my $Line = $SSH->read_line();
				my $Fingerprint_Prompt = $SSH->waitfor(".*key fingerprint is.*", $Connection_Timeout, '-re');
		
				if ($Fingerprint_Prompt) {
		
					my $Discovered_Fingerprint = $SSH->match();
					$Discovered_Fingerprint =~ s/.*key fingerprint is (.*)\./$1/g;
					if ($Verbose == 1) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint ${Blue}$Discovered_Fingerprint${Clear}\n";
					}
					
					# Fingerprint validity check
					if (!$Previously_Recorded_Fingerprint) {
						if ($Verbose == 1) {
							my $Time_Stamp = strftime "%H:%M:%S", localtime;
							print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Previous fingerprint not found for ${Blue}$Host${Green}. Recording and proceeding...${Clear}\n";
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
		
						if ($Verbose == 1) {
							my $Time_Stamp = strftime "%H:%M:%S", localtime;
							print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Fingerprint matches records, connecting...${Clear}\n";
						}
						$SSH->send('yes');
		
					}
					else {
		
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint mismatch! Ejecting!${Clear}\n";
		
						unlink "$Distribution_tmp_Location/$Host";
						exit(17);
					}
				}
				else {
					print "${Red}Fingerprint prompt NOT Found! Last line was: $Line. Full job log at $Distribution_Transactional_File${Clear}\n";
				}

			}
			
			return $SSH;
		}
	}
} # sub fingerprint_verification

1;