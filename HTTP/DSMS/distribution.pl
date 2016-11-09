#!/usr/bin/perl

use strict;

use DBI;
use POSIX qw(strftime);
use Net::SFTP::Foreign;
use Net::SSH::Expect;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $DB_Connection = DB_Connection();
my $MD5Sum = md5sum();
my $Cut = cut();
my $Sudoers_Location = Sudoers_Location();
	my $MD5_Checksum = `$MD5Sum $Sudoers_Location | $Cut -d ' ' -f 1`;
my $Distribution_Log_Location = Distribution_Log_Location();
my $Distribution_tmp_Location = Distribution_tmp_Location();
my $Green = "\e[0;32;10m";
my $Yellow = "\e[0;33;10m";
my $Red = "\e[0;31;10m";
my $Pink = "\e[1;35;10m";
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
				print "Another build or distribution process is running. Use --override to continue anyway. Exiting.\n";
				exit(1);
			}
		}
		else {
			$DB_Connection->do("UPDATE `lock` SET
				`sudoers-distribution` = '1',
				`last-sudoers-distribution-started` = NOW()");
		}

my $Select_Hosts = $DB_Connection->prepare("SELECT `id`, `hostname`
	FROM `hosts`
	LEFT OUTER JOIN `host_attributes`
		ON `hosts`.`id`=`host_attributes`.`host_id`
	WHERE `dsms` = 1
	ORDER BY `last_modified` DESC");

$Select_Hosts->execute();
my $Total = $Select_Hosts->rows();

if ($Verbose) {
	my $Time_Stamp = strftime "%H:%M:%S", localtime;
	print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found ${Blue}$Total${Green} host receivers${Clear}\n\n";
}
else {
	print "${Green}Found ${Blue}$Total${Green} host receivers${Clear}\n";
}

my $Current;
HOST: while ( my @Select_Hosts = $Select_Hosts->fetchrow_array() )
{
	$Current++;
	my $DBID = $Select_Hosts[0];
	my $Hostname = $Select_Hosts[1];

	my $Select_Parameters = $DB_Connection->prepare("SELECT `sftp_port`, `user`, `key_path`, `timeout`, `remote_sudoers_path`
		FROM `distribution`
		WHERE `host_id` = ?");

	$Select_Parameters->execute($DBID);

	my @Select_Parameters = $Select_Parameters->fetchrow_array();

		my $SFTP_Port = $Select_Parameters[0];
		my $User = $Select_Parameters[1];
		my $Key_Path = $Select_Parameters[2];
		my $Timeout = $Select_Parameters[3];
		my $Remote_Sudoers = $Select_Parameters[4];

		my ($Distribution_Default_SFTP_Port,
			$Distribution_Default_User,
			$Distribution_Default_Key_Path, 
			$Distribution_Default_Timeout,
			$Distribution_Default_Remote_Sudoers) = Distribution_Defaults();

		my $DB_Needs_A_Refresh;
		if (!$SFTP_Port) {$SFTP_Port = $Distribution_Default_SFTP_Port; $DB_Needs_A_Refresh = 1;};
		if (!$User) {$User = $Distribution_Default_User; $DB_Needs_A_Refresh = 1;};
		if (!$Key_Path) {$Key_Path = $Distribution_Default_Key_Path; $DB_Needs_A_Refresh = 1;};
		if (!$Timeout) {$Timeout = $Distribution_Default_Timeout; $DB_Needs_A_Refresh = 1;};
		if (!$Remote_Sudoers) {$Remote_Sudoers = $Distribution_Default_Remote_Sudoers; $DB_Needs_A_Refresh = 1;};
		
		if ($DB_Needs_A_Refresh) {
			my $Update_Parameters = $DB_Connection->prepare("INSERT INTO `distribution` (
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
			)
			ON DUPLICATE KEY UPDATE
				`sftp_port` = ?,
				`user` = ?,
				`key_path` = ?,
				`timeout` = ?,
				`remote_sudoers_path` = ?,
				`last_modified` = NOW(),
				`modified_by` = ?");

			$Update_Parameters->execute(
				# Ins
				$DBID,
				$SFTP_Port,
				$User,
				$Key_Path,
				$Timeout,
				$Remote_Sudoers,
				'System',
				# Dupe
				$SFTP_Port,
				$User,
				$Key_Path,
				$Timeout,
				$Remote_Sudoers,
				'System'
			);
		}

		my $Error;

		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Trying ${Yellow}$Hostname${Green} (ID: ${Blue}$DBID${Green}) [${Blue}$Current${Green}/${Blue}$Total${Green}]${Clear}\n";
		}
		else {
			print "${Yellow}$Hostname ${Clear}";
		}
		my $Host_or_Block = &fingerprint_verification($DBID);
		if ($Host_or_Block =~ /^Failed/) {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}Failed fingerprint verification for ${Yellow}$Hostname${Red} (ID: ${Blue}$DBID${Red}).${Clear}\n\n";
			}
			else {
				print "${Red}[Failed]${Clear}\n";
			}

			my $Update_Status = $DB_Connection->prepare("UPDATE `distribution` SET
				`status` = ?,
				`last_updated` = NOW()
				WHERE `host_id` = ?");
			$Update_Status->execute($Host_or_Block, $DBID);
			next HOST;
		}

		### Connection
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Attempting to connect to ${Yellow}$Hostname${Green} with ${Pink}$Host_or_Block${Green}, key ${Blue}$Key_Path${Green} and host key ${Blue}$Distribution_tmp_Location/$Host_or_Block${Green}.${Clear}\n";
		}

		open my $DevNull, '>', '/dev/null' or die "unable to open /dev/null";

		my $SFTP = Net::SFTP::Foreign->new(
			"$User\@$Host_or_Block",
			port => $SFTP_Port,
			key_path => $Key_Path,
			timeout => $Timeout,
			stderr_fh => $DevNull, # Suppress banners
			more => "-o UserKnownHostsFile=$Distribution_tmp_Location/$Host_or_Block"
		);
		$SFTP->error and $Error = "Connection Failed: " . $SFTP->error;

		if ($SFTP->status == 0) {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Connected to ${Yellow}$Hostname${Green} with ${Pink}$Host_or_Block${Green}, key ${Blue}$Key_Path${Green} and host key ${Blue}$Distribution_tmp_Location/$Host_or_Block${Green}.${Clear}\n";
			}
			else {
				print "${Green}[Connected] ${Clear}";
			}
		}
		else {

			if ($Error =~ /Connection to remote server stalled/) {
				$Error = $Error . " 
    Hints: 
    1) Check that the remote host's key fingerprint is stored in known_hosts
    2) Check for a route to the remote host
    3) Check that your $Timeout second Timeout value is high enough";
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}Connection to ${Yellow}$Hostname${Red} (ID: ${Blue}$DBID${Red}) stalled${Clear}\n\n";
				}
				else {
					print "${Red}[Connection Failed]${Clear}\n";
				}
			}
			elsif ($Error =~ /Connection to remote server is broken/) {
				$Error = $Error ." 
    Hints: 
    1) Check that the user name is correct
    2) Check that the IP address or port are correct
    3) Check that the key identity file exists
    4) Check that there are sufficient permissions to read the key identity file";
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}Connection to ${Yellow}$Hostname${Red} (ID: ${Blue}$DBID${Red}) broken${Clear}\n\n";
				}
				else {
					print "${Red}[Connection Failed]${Clear}\n";
				}
			}
			else {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}Connection to ${Yellow}$Hostname${Red} (ID: ${Blue}$DBID${Red}) failed ($Error).${Clear}\n\n";
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
			unlink "$Distribution_tmp_Location/$Host_or_Block";
			next HOST;
			undef $SFTP;
		}

		unlink "$Distribution_tmp_Location/$Host_or_Block";

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
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}File $Remote_Sudoers written successfully to ${Yellow}$Hostname${Green} (${Pink}$Host_or_Block:$SFTP_Port${Green}).${Clear}\n\n";
			}
			else {
				print "${Green}[Transfer Completed]${Clear}\n";
			}
			my $Status="OK: $Remote_Sudoers written successfully to $Hostname ($Host_or_Block). Sudoers MD5: $MD5_Checksum";
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
				$Error = $Error . " 
    Hints: 
    1) Check that $User can write to $Remote_Sudoers";
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Red}Permission denied writing file to ${Yellow}$Hostname${Red} (ID: ${Blue}$DBID${Red})${Clear}\n\n";
				}
				else {
					print "${Red}[Transfer Failed]${Clear}\n";
				}
			}

			elsif ($Error =~ /Couldn't open remote file/) {
				$Error = $Error . " 
    Hints: 
    1) Check that the remote path is correct
    2) If the Remote Server uses chroot, try making the path relative (i.e. path/sudoers instead of /path/sudoers)";
				if (!$Verbose) {
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

$DB_Connection->do("UPDATE `lock` SET 
		`sudoers-distribution` = '0',
		`last-sudoers-distribution-finished` = NOW()");


sub fingerprint_verification {

	my $nmap = nmap();
	my $grep = sudo_grep();

	my $Host_ID = $_[0];
	my $SSH;

	my $Select_Hosts = $DB_Connection->prepare("SELECT `hostname`, `dhcp`
		FROM `hosts`
		LEFT JOIN `host_attributes`
		ON `hosts`.`id`=`host_attributes`.`host_id`
		WHERE `id` = ?");

	$Select_Hosts->execute($Host_ID);

	HOST: while ( my @Select_Hosts = $Select_Hosts->fetchrow_array() )
	{
		my $Hostname = $Select_Hosts[0];
		my $DHCP = $Select_Hosts[1];
		my $Blocks = &block_discovery($Host_ID);

		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Discovering fingerprint data for ${Yellow}$Hostname${Green} (ID: ${Blue}$Host_ID${Green}).${Clear}\n";
		}

		my $Distribution_Transactional_File = "$Distribution_Log_Location/DSMS-Trans-$Hostname";

			my @Host_Connection_String;
			if ($DHCP) {
				@Host_Connection_String = $Hostname;
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}We'll be using the listed DNS address for ${Yellow}$Hostname${Green} (ID: ${Blue}$Host_ID${Green}).${Clear}\n";
				}
			}
			elsif ($Blocks) {
				@Host_Connection_String = split (',', $Blocks);
			}
			else {
				@Host_Connection_String = $Hostname;
			}
	
		my $Select_Parameters = $DB_Connection->prepare("SELECT `sftp_port`, `user`, `timeout`
			FROM `distribution`
			WHERE `host_id` = ?");
	
		$Select_Parameters->execute($Host_ID);
	
		while ( my @Select_Parameters = $Select_Parameters->fetchrow_array() )
		{

			my $SFTP_Port = $Select_Parameters[0];
			my $User_Name = $Select_Parameters[1];
			my $Connection_Timeout = $Select_Parameters[2];

			my $Private_Key;
			my $Attempts;

			my $Host_or_Block;
			if (!@Host_Connection_String) {@Host_Connection_String = $Hostname}
			SSH_CHECK: foreach my $Tested_Host_or_Block (@Host_Connection_String) {
				$Attempts = 0;
				while (1) {
					$Attempts++;
					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Testing connection to ${Pink}$Tested_Host_or_Block:$SFTP_Port${Green}.${Clear}\n";
					}
					my $SSH_Check=eval {`$nmap $Tested_Host_or_Block -PN -p $SFTP_Port 2>/dev/null | $grep -E 'open'`};
					if ($SSH_Check =~ /open/) {
						if ($Verbose) {
							my $Time_Stamp = strftime "%H:%M:%S", localtime;
							print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}SSH ready for ${Pink}$Tested_Host_or_Block:$SFTP_Port${Green}.${Clear}\n";
						}
						$Host_or_Block = $Tested_Host_or_Block;
						last SSH_CHECK;
					}
					elsif ($Attempts >= 3) {
						if ($Verbose) {
							my $Time_Stamp = strftime "%H:%M:%S", localtime;
							print "${Red}## Verbose (PID:$$) $Time_Stamp ## Could not resolve ${Yellow}$Hostname${Red} (${Pink}$Tested_Host_or_Block${Red}), no route to host or SSH not responding. Terminating the transfer.${Clear}\n";
						}
						if ($Tested_Host_or_Block eq $Host_Connection_String[-1]) {
							return "Failed: Could not resolve $Hostname ($Tested_Host_or_Block), no route to host or SSH not responding. Terminating the transfer.";
						}
						else {
							next SSH_CHECK;
						}
						
					}
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

				$SSH = Net::SSH::Expect->new (
					host => $Host_or_Block,
					port => $SFTP_Port,
					user => $User_Name,
					log_file => $Distribution_Transactional_File,
					timeout => $Connection_Timeout,
					raw_pty => 1,
					restart_timeout_upon_receive => 1,
					ssh_option => "-o UserKnownHostsFile=$Distribution_tmp_Location/$Host_or_Block"
				);
				eval { $SSH->run_ssh(); }; print "" if $@;

				# Fingerprint
				my $Line = $SSH->read_line();
				my $Fingerprint_Prompt = eval { $SSH->waitfor(".*key fingerprint is.*", $Connection_Timeout, '-re'); }; &failure("${Red}[Connection Timeout]${Clear}\n", "$Distribution_tmp_Location/$Host_or_Block") if $@;

				if (!$Verbose) {
					print "${Green}(${Pink}$Host_or_Block${Green}) ";
				}

				if ($Fingerprint_Prompt) {
					my $Discovered_Fingerprint = $SSH->match();
					$Discovered_Fingerprint =~ s/.*key fingerprint is (.*)\./$1/g;
					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found fingerprint ${Blue}$Discovered_Fingerprint${Clear}\n";
					}
					
					# Fingerprint validity check
					if (!$Previously_Recorded_Fingerprint) {
						if ($Verbose) {
							my $Time_Stamp = strftime "%H:%M:%S", localtime;
							print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Previous fingerprint not found for ${Blue}$Host_or_Block${Green}. Recording and proceeding.${Clear}\n";
						}
						else {
							print "${Blue}[Fingerprint] ${Clear}";
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
						#$Line = $SSH->read_line();
						eval { $SSH->waitfor(".*Last login.*", $Connection_Timeout, '-re'); }; &failure("${Red}[Connection Timeout]${Clear}\n", "$Distribution_tmp_Location/$Host_or_Block") if $@;
						$SSH->close();
						return $Host_or_Block;
					}
					elsif ($Discovered_Fingerprint eq $Previously_Recorded_Fingerprint) {

						if ($Verbose) {
							my $Time_Stamp = strftime "%H:%M:%S", localtime;
							print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Fingerprint matches records.${Clear}\n";
						}
						else {
							print "${Green}[Fingerprint] ${Clear}";
						}
						$SSH->send('yes');
						#$Line = $SSH->read_line();
						eval { $SSH->waitfor(".*Last login.*", $Connection_Timeout, '-re'); }; &failure("${Red}[Connection Timeout]${Clear}\n", "$Distribution_tmp_Location/$Host_or_Block") if $@;
						$SSH->close();
						return $Host_or_Block;
					}
					else {
						if ($Verbose) {
							my $Time_Stamp = strftime "%H:%M:%S", localtime;
							print "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint mismatch! Ejecting!${Clear}\n";
						}
						else {
							print "${Red}[Fingerprint] ${Clear}";
						}
						unlink "$Distribution_tmp_Location/$Host_or_Block";
						return "Failed: Fingerprint mismatch!";
					}
				}
				else {
					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## Fingerprint mismatch! Ejecting!${Clear}\n";
					}
					else {
						print "${Red}[Fingerprint] ${Clear}\n";
					}
					unlink "$Distribution_tmp_Location/$Host_or_Block";
					return "Failed: Fingerprint could not be discovered!";
				}
			}
		}
	}
} # sub fingerprint_verification

sub block_discovery {

	my $DBID = $_[0];
	my $Select_Block_Links = $DB_Connection->prepare("SELECT `ip`
		FROM `lnk_hosts_to_ipv4_allocations`
		WHERE `host` = ?");
	$Select_Block_Links->execute($DBID);

	my $Blocks;
	while (my $Block_ID = $Select_Block_Links->fetchrow_array() ) {

		my $Select_Blocks = $DB_Connection->prepare("SELECT `ip_block`
			FROM `ipv4_allocations`
			WHERE `id` = ?");
		$Select_Blocks->execute($Block_ID);

		while (my $Block = $Select_Blocks->fetchrow_array() ) {

			my $Count_Block_Allocations = $DB_Connection->prepare("SELECT `id`
				FROM `lnk_hosts_to_ipv4_allocations`
				WHERE `ip` = ?");
			$Count_Block_Allocations->execute($Block_ID);
			my $Total_Block_Allocations = $Count_Block_Allocations->rows();

			if ($Block =~ /\/32$/) {
				$Block =~ s/(.*)\/32$/$1/;
				$Blocks = $Block. "," . $Blocks;
			}
		}
	}

	$Blocks =~ s/,$//;
	return $Blocks;

} # sub block_discovery

sub failure {

	my ($Message, $Host_Key) = @_;

	print $Message;
	unlink $Host_Key;

} # sub failure

1;