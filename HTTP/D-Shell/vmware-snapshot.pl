#!/usr/bin/perl

use strict;
use Net::SSH::Expect;
use Parallel::ForkManager;
use POSIX qw(strftime);

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $DB_DShell = DB_DShell();
my $Fork_Count = 1;
my $Debug = 1;

$| = 1;
my $Green = "\e[0;32;40m";
my $Yellow = "\e[0;33;40m";
my $Red = "\e[0;31;40m";
my $Clear = "\e[0m";

my @Hosts = (
#	'wellshiny',
#	'pgdb2',
	'schofieldbj'
);
my @Nodes = (
	'vhost1.nwk1.com',
	'vhost2.nwk1.com',
	'vhost7.nwk1.com'
);

#my @Hosts = ( 'schofieldbj');

my $SSH_Fork = new Parallel::ForkManager($Fork_Count);
	$SSH_Fork->run_on_start(
    	sub { my ($PID, $Host)=@_;
			print "D-Shell: $Host has started, PID: $PID.\n";
		}
	);
	$SSH_Fork->run_on_finish(
		sub {
			my ($PID, $Exit_Code, $Host) = @_;
			my $Notes;
			if ($Exit_Code == 1) {$Notes = ' (Regular command failure)'}
			if (($Exit_Code == 1000) || $Exit_Code == 232) {$Notes = ' (Failed on WAITFOR - probably no match found)'}
			if ($Exit_Code == 233) {$Notes = ' (Probably SSH authentication failure)'}
			if ($Exit_Code == 255) {$Notes = ' (SSH session died)'}
			print "D-Shell: $Host (PID:$PID) has finished. Exit code: $Exit_Code${Notes}.\n";
		}
	);

		foreach my $Host (@Hosts) {

			foreach my $Node (@Nodes) {

				my $PID = $SSH_Fork->start ("$Node ($Host)") and next;

				my $Log_File = "/tmp/$Node";
				my $Start_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
				system("echo 'Job started at $Start_Time.' >> $Log_File");

				my $SSH = Net::SSH::Expect->new (
					host => "$Node",
					password=> '<Password>',
					user => 'root', 
					log_file => "$Log_File",
					timeout => 1,
					exp_internal => 0,
					exp_debug => 0,
					raw_pty => 0
				);

				my $Login = $SSH->login(1);
#				if ($Login !~ /VMWare/) {
#					print "Could not login to $Node. Output was: $Login\n";
#					$SSH_Fork->finish(233);
#				}

				#while ( defined (my $Line = $SSH->read_all()) ) {print $Line} # Keeps the text flowing

				my $Discovery_Command = 'vim-cmd vmsvc/getallvms';
				if ($Debug == 1) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					system("echo '${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Discovery_Command ${Green}on node $Node, looking for $Host${Clear}\n' >> $Log_File");
					print "${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Discovery_Command ${Green}on node $Node, looking for $Host${Clear}\n";
				}
				my $Command_Timeout = '3';
				# Get all VM IDs
				$SSH->send($Discovery_Command);
				my $VM_On_Node;
				my $Node_VM_ID;
				while ( defined (my $Line = $SSH->read_line()) ) {

					my $VM_ID = $Line;
						$VM_ID =~ s/^(\d*)\s*(\w*)\s*\[.*/$1/;
					my $VM_Name = $Line;
						$VM_Name =~ s/^(\d*)\s*(\w*)\s*\[.*/$2/;

					if ($VM_Name =~ /$Host/) {
						$VM_On_Node = 'Yes';
						$Node_VM_ID = $VM_ID;
					}
				}
				if ($VM_On_Node eq 'Yes') {
					if ($Debug == 1) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						system("echo '${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}$Host found on node $Node (VMID $Node_VM_ID)${Clear}\n' >> $Log_File");
						print "${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}$Host found on node $Node (VMID $Node_VM_ID)${Clear}\n";
					}
				}
				else {
					if ($Debug == 1) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						system("echo '${Red}## Debug (PID:$$) $Time_Stamp ## ${Yellow}$Host not found on node $Node, closing the SSH session on $Node${Clear}\n' >> $Log_File");
						print "${Red}## Debug (PID:$$) $Time_Stamp ## ${Yellow}$Host not found on node $Node, closing the SSH session on $Node${Clear}\n";
					}
					$SSH->close();
					$SSH_Fork->finish;
				}

#				my $Time_Date_Stamp = strftime "%H:%M:%S %d/%m/%Y", localtime;
#				my $Snapshot_Name = "'TheMachine: VMID $Node_VM_ID'";
#				my $Snapshot_Description = "'Snapshot taken by The Machine at $Time_Date_Stamp.'";
#				my $Include_Memory = 1;
				if ($Debug == 1) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					system("echo '${Red}## Debug (PID:$$) $Time_Stamp ## ${Yellow}Removing snapshot for $Host on node $Node${Clear}\n' >> $Log_File");
					print "${Red}## Debug (PID:$$) $Time_Stamp ## ${Yellow}Removing snapshot for $Host on node $Node${Clear}\n";
				}
				my $Remove_Snapshot_Command = "vim-cmd vmsvc/snapshot.removeall $Node_VM_ID";
				$SSH->exec($Remove_Snapshot_Command, $Command_Timeout);

#vim-cmd vmsvc/snapshot.remove 25 [TheMachine:*]

				my $Time_Date_Stamp = strftime "%H:%M:%S %d/%m/%Y", localtime;
				my $Snapshot_Name = "TheMachine: VMID $Node_VM_ID";
				my $Snapshot_Description = "Snapshot taken by The Machine at $Time_Date_Stamp.";
				my $Include_Memory = 1;
				my $Snapshot_Command = "vim-cmd vmsvc/snapshot.create $Node_VM_ID '$Snapshot_Name' '$Snapshot_Description' $Include_Memory 0";
				$SSH->exec($Snapshot_Command, $Command_Timeout);
				
				
				my $EC = $SSH->exec('echo $?', $Command_Timeout);
					print "Exit code for $Snapshot_Command: $EC\n";

				my $End_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
				system("echo 'Job ended at $End_Time.' >> $Log_File");

				$SSH->close();
				$SSH_Fork->finish;

			}

		}
	
		$SSH_Fork->wait_all_children;
		print "All servers have completed their tasks!\n";

	
1;