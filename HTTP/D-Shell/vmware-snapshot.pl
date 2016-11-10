#!/usr/bin/perl

use strict;
use Net::SSH::Expect;
use Parallel::ForkManager;
use POSIX qw(strftime);

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Name = System_Name();
my $System_Short_Name = System_Short_Name();
my $Version = Version();
my $DB_Connection = DB_Connection();
my $Note = "If you've got another snapshot/remove process running for this VM, VMWare won't let you do two at a time. This can also happen if you specify to remove snapshots and take a new one - VMWare sometimes can't delete them fast enough (and there's no way to see what's processing on the command line :-[ ) Try again in 10 minutes.";
my %Hosts_Found = ();

$| = 1;
my $Green = "\e[0;32;10m";
my $Yellow = "\e[0;33;10m";
my $Red = "\e[0;31;10m";
my $Pink = "\e[1;35;10m";
my $Blue = "\e[1;34;10m";
my $Clear = "\e[0m";

my $Help = "
${Green}$System_Name version $Version

Options are:
	${Blue}-t, --threads\t\t${Green}Sets the number of threads to use for connecting to nodes. By default the number of 
				threads matches the number of nodes. Setting it more than this is a BAD idea (for load).
	${Blue}-H, --hosts\t\t${Green}A list of hosts to snapshot, comma seperated (no spaces!) [e.g.: -H host01,host02,host03]
	${Blue}-i, --host-ids\t\t${Green}A list of host IDs to snapshot, comma seperated (no spaces!) [e.g.: -H 4587,155,2341]
	${Blue}-c, --count\t\t${Green}Counts the snapshots belonging to the VM, including those done by $System_Name
	${Blue}-s, --snapshot\t\t${Green}Takes a snapshot of the listed hosts
	${Blue}-r, --remove\t\t${Green}Removes snapshots for listed hosts that were created by $System_Name
	${Blue}-e, --erase\t\t${Green}Removes ALL snapshots for listed hosts
	${Blue}-v, --verbose\t\t${Green}Turns on verbose output (useful for debug)
	${Blue}-V, --very-verbose\t${Green}Same as verbose, but also includes thread data

${Green}Examples:
	${Green}## Snapshot server01
	${Blue}$0 -s -H server01

	${Green}## Remove all snapshots for server01/02/03, then takes a snapshot of each, with verbose turned on
	${Blue}$0 -v -e -s -H server01,server02,server03

	${Green}## Count the snapshots for server01/02 only (verbose needed for counting output) with 5 threads
	${Blue}$0 -v -H server01,server02 -t 5${Clear}\n\n";


if (!@ARGV) {
	print $Help;
	exit(0);
}

my @Hosts;
my @Host_IDs;
my @Nodes;

my $Threads = scalar(keys @Nodes);
my $Verbose = 0;
my $Very_Verbose = 0;
my $Command_Timeout = 5;

my $Count;
my $Snapshot;
my $Remove;
my $Erase;
foreach my $Parameter (@ARGV) {
	if ($Parameter eq '-v' || $Parameter eq '--verbose') {
		$Verbose = 1;
		print "${Red}## ${Green}Verbose is on. ${Yellow}Hosts${Green}, ${Blue}Nodes${Green}, ${Pink}Commands${Green}.${Clear}\n";
	}
	if ($Parameter eq '-V' || $Parameter eq '--very-verbose') {
		$Verbose = 1;
		$Very_Verbose = 1;
		print "${Red}## ${Green}Very Verbose is on. ${Yellow}Hosts${Green}, ${Blue}Nodes${Green}, ${Pink}Commands${Green}.${Clear}\n";
	}
	if ($Parameter eq '-H' || $Parameter eq '--hosts') {
		my @Discovered_Hosts = @ARGV;
		while (my $Discovered_Host = shift @Discovered_Hosts) {
			if ($Discovered_Host =~ /-H/ || $Discovered_Host =~ /--hosts/) {
				$Discovered_Host = shift @Discovered_Hosts;
				@Hosts = split(',', $Discovered_Host);
				last;
			}
		}
		if ($Verbose) {
			foreach my $Host_Input_Check (@Hosts) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found host ${Yellow}$Host_Input_Check ${Green}in parameter list${Clear}\n";
			}
			sleep 2;
		}
	}
	if ($Parameter eq '-i' || $Parameter eq '--host-ids') {
		my @Discovered_Host_IDs = @ARGV;
		while (my $Discovered_Host_ID = shift @Discovered_Host_IDs) {
			if ($Discovered_Host_ID =~ /-i/ || $Discovered_Host_ID =~ /--host-ids/) {
				$Discovered_Host_ID = shift @Discovered_Host_IDs;
				@Host_IDs = split(',', $Discovered_Host_ID);
				last;
			}
		}
		if ($Verbose) {
			foreach my $Host_ID_Input_Check (@Host_IDs) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found host ID ${Yellow}$Host_ID_Input_Check ${Green}in parameter list${Clear}\n";
			}
			sleep 2;
		}
	}
	if ($Parameter eq '-c' || $Parameter eq '--count') {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Listed hosts will be snapshotted${Clear}\n";
		}
		$Count = 1;
	}
	if ($Parameter eq '-s' || $Parameter eq '--snapshot') {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Listed hosts will be snapshotted${Clear}\n";
		}
		$Snapshot = 1;
	}
	if ($Parameter eq '-r' || $Parameter eq '--remove') {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Snapshots will be removed for listed hosts that were created by $System_Name${Clear}\n";
		}
		$Remove = 1;
	}
	elsif ($Parameter eq '-e' || $Parameter eq '--erase') {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}ALL snapshots will be removed for listed hosts${Clear}\n";
		}
		$Erase = 1;
	}
	if ($Parameter eq '-t' || $Parameter eq '--threads') {
		my @Threads = @ARGV;
		while (my $Thread = shift @Threads) {
			if ($Thread =~ /-t/ || $Thread =~ /--threads/) {
				$Thread = shift @Threads;
				$Threads = $Thread;
				last;
			}
		}
	}
	if ($Parameter eq '-h' || $Parameter eq '--help') {
		print $Help;
		exit(0);
	}
}


if ($Verbose) {
	my $Time_Stamp = strftime "%H:%M:%S", localtime;
	print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Threads set to $Threads${Clear}\n";
}


my $SSH_Fork = new Parallel::ForkManager($Threads);
	$SSH_Fork->run_on_start(
    	sub { my ($PID, $Thread_Name)=@_;
    		if ($Very_Verbose) {
    			print "D-Shell Thread: $Thread_Name has started, PID: $PID.\n";
    		}
		}
	);
	$SSH_Fork->run_on_finish(
		sub {
			my ($PID, $Exit_Code, $Thread_Name, $Exit_Signal, $Core_Dump, $Return) = @_;
			my $Notes;
			if ($Exit_Code == 1) {$Notes = ' (Regular command failure)'}
			if (($Exit_Code == 1000) || $Exit_Code == 232) {$Notes = ' (Failed on WAITFOR - probably no match found)'}
			if ($Exit_Code == 233) {$Notes = ' (Probably SSH authentication failure)'}
			if ($Exit_Code == 255) {$Notes = ' (SSH session died)'}

			my $Host = $Thread_Name;
				$Host =~ s/.*\(processing (.*)\.*\)/$1/;

			my $Output = ${$Return}; # Return is a scalar reference, not the scalar itself

			if ($Output ne 'X') {
				$Hosts_Found{$Host} = $Output;
			}

			if ($Very_Verbose) {
				print "D-Shell Thread: $Thread_Name (PID:$PID) has finished. Exit code: $Exit_Code${Notes}.\n";
			}
		}
	);

	foreach my $Host_ID (@Host_IDs) {
		my $Host_Query = $DB_Connection->prepare("SELECT `hostname`
		FROM `hosts`
		WHERE `id` = ?");
		$Host_Query->execute($Host_ID);
		my $Host_Name = $Host_Query->fetchrow_array();
		$Host_Name =~ s/^(.*?)\..*/$1/;
		push @Hosts, $Host_Name;
	}

	foreach my $Host (@Hosts) {

		$Hosts_Found{$Host} = 'X';

		foreach my $Check_Node (@Nodes) {

			my $PID = $SSH_Fork->start ("$Check_Node (processing $Host)") and next;

			my $Log_File = "/tmp/$Check_Node";
			my $Start_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
			system("echo 'Job started at $Start_Time.' >> $Log_File");

			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Connecting to node ${Blue}$Check_Node${Clear}\n";
			}

			my $Retry_Count = 0;
			my $Max_Retry_Count = 10;
			my $Connection_Timeout = 2;
			my $SSH = Net::SSH::Expect->new (
				host => $Check_Node,
				password=> '<Password>',
				user => 'root',
				log_file => $Log_File,
				timeout => $Connection_Timeout,
				exp_internal => 0,
				exp_debug => 0,
				raw_pty => 0
			);

			while (1) {
				my $Hello = eval{$SSH->login();};
			
				last if defined $Hello;
				last if $Retry_Count >= $Max_Retry_Count;
				$Retry_Count++;
			
				my $Connection_Timeout_Plus = $Connection_Timeout;
				$Connection_Timeout_Plus += 2;
				if ($Verbose) {
					print "Tried to connect to $Check_Node with $Connection_Timeout second timeout but failed. Timeout increased to $Connection_Timeout_Plus, trying again (attempt $Retry_Count of $Max_Retry_Count)...\n";
				}
				$Connection_Timeout = $Connection_Timeout_Plus;
			
				$SSH = Net::SSH::Expect->new (
					host => $Check_Node,
					password=> '<Password>',
					user => 'root',
					log_file => $Log_File,
					timeout => $Connection_Timeout,
					exp_internal => 0,
					exp_debug => 0,
					raw_pty => 0
				);
				sleep 1;
			}

			if ($Retry_Count == $Max_Retry_Count) {
				print "Couldn't connect to $Check_Node after $Retry_Count attempts. Terminating the job.\n";
				exit(1);
			}

			#while ( defined (my $Line = $SSH->read_all()) ) {print $Line} # Keeps the text flowing

			my ($Node_VM_ID, $Node) = &find_vm($Host, $Check_Node, $SSH, $Command_Timeout, $Log_File);
			if ($Node_VM_ID && $Node_VM_ID ne 'X' && $Node) {
				if ($Count || (!$Remove && !$Erase && !$Snapshot)) {
					&count_snapshot($Host, $Node, $Node_VM_ID, $SSH, $Command_Timeout, $Log_File);
				}
				if ($Remove) {
					&remove_snapshots($Host, $Node, $Node_VM_ID, $SSH, $Command_Timeout, $Log_File);
				}
				elsif ($Erase) {
					&erase_all_snapshots($Host, $Node, $Node_VM_ID, $SSH, $Command_Timeout, $Log_File);
				}
				if ($Snapshot) {
					&take_snapshot($Host, $Node, $Node_VM_ID, $SSH, $Command_Timeout, $Log_File);
				}
			}

			my $End_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
			system("echo 'Job ($Host) ended at $End_Time.' >> $Log_File");

			my $Return;
			if ($Node_VM_ID eq 'X') {
				$Return = 'X';
			}
			else {
				$Return = 'Y';
			}

			$SSH->close();
			$SSH_Fork->finish(0, \$Return); # Return is a scalar reference, not the scalar itself

		} # Nodes

	} # Hosts

	$SSH_Fork->wait_all_children;

	my @Host_Results = keys %Hosts_Found;
	my $Error;
	for my $Host (@Host_Results) {
		if ($Hosts_Found{$Host} eq 'X') {
			if (@Host_IDs) {
				print "$Host was not found on any node, or a node had problems returning results\n";
			}
			else {
				print "${Yellow}$Host ${Red}was not found on any node, or a node had problems returning results${Clear}\n";
			}
			$Error = 1;
		}
	}


	if ($Error) {
		if (@Host_IDs) {
			print "All tasks are complete, but there were some errors (listed immediately above).\n";
			exit(1);
		}
		else {
			print "${Green}All tasks are complete, ${Red}but there were some errors ${Green}(listed immediately above).${Clear}\n";
			exit(1);
		}
	}
	else {
		if (@Host_IDs) {
			exit(0);
		}
		else {
			print "${Green}All tasks completed without errors!${Clear}\n";
			exit(0);
		}
	}

sub find_vm {

my ($Host, $Check_Node, $SSH, $Command_Timeout, $Log_File) = @_;

	my $Discovery_Command = 'vim-cmd vmsvc/getallvms';
	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Pink}$Discovery_Command ${Green}on node ${Blue}$Check_Node${Green}, looking for ${Yellow}$Host${Clear}\n' >> $Log_File");
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Pink}$Discovery_Command ${Green}on node ${Blue}$Check_Node${Green}, looking for ${Yellow}$Host${Clear}\n";
	}

	# Get all VM IDs
	$SSH->send($Discovery_Command);
	my $VM_On_Node;
	my $Node_VM_ID;
	while ( defined (my $Line = $SSH->read_line()) ) {

		my $VM_ID = $Line;
			$VM_ID =~ s/^(\d*)\s*([a-zA-Z0-9\-\_]*)\s*\[.*/$1/;
		my $VM_Name = $Line;
			$VM_Name =~ s/^(\d*)\s*([a-zA-Z0-9\-\_]*)\s*\[.*/$2/;

		if ($VM_Name =~ /^$Host$/) {
			$VM_On_Node = 'Yes';
			$Node_VM_ID = $VM_ID;
		}
	}
	if ($VM_On_Node eq 'Yes') {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}$Host ${Green}found on node ${Blue}$Check_Node ${Green}(VMID $Node_VM_ID)${Clear}\n' >> $Log_File");
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}$Host ${Green}found on node ${Blue}$Check_Node ${Green}(VMID $Node_VM_ID)${Clear}\n";
			
		}
		my @VM = ($Node_VM_ID, $Check_Node);
		return @VM;
	}
	else {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}$Host ${Red}not found ${Green}on node ${Blue}$Check_Node${Green}, closing the SSH session${Clear}\n' >> $Log_File");
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}$Host ${Red}not found ${Green}on node ${Blue}$Check_Node${Green}, closing the SSH session${Clear}\n";
		}
		$Node_VM_ID = 'X';
		my @VM = ($Node_VM_ID, $Check_Node);
		return @VM;
		$SSH->close();
	}
} # sub find_vm

sub remove_snapshots {

my ($Host, $Node, $Node_VM_ID, $SSH, $Command_Timeout, $Log_File) = @_;

	if (@Host_IDs) {
		print "Removing $System_Name snapshots for $Host on node $Node\n";
	}
	else {
		print "${Green}Removing $System_Name snapshots for ${Yellow}$Host${Green} on node ${Blue}$Node${Clear}\n";
	}
	my $Count_Our_Snapshots = "vim-cmd vmsvc/snapshot.get $Node_VM_ID | grep -A1 $System_Short_Name | grep Id | wc -l";
		my $Our_Snapshot_Count = $SSH->exec($Count_Our_Snapshots, $Command_Timeout);
			$Our_Snapshot_Count =~ s/.*wc -l(.*)/$1/;
			$Our_Snapshot_Count =~ s/[^0-9+]//g;
	my $Get_Our_Snapshots = "vim-cmd vmsvc/snapshot.get $Node_VM_ID | grep -A1 $System_Short_Name | grep Id";
		my $Our_Snapshots = $SSH->exec($Get_Our_Snapshots, $Command_Timeout);

	if ($Our_Snapshot_Count ne '' && $Our_Snapshot_Count > 0) {

		my @Our_Snapshots = split('\n', $Our_Snapshots);
	
	  	while (my $Our_Snapshot = shift @Our_Snapshots) {
	  		$Our_Snapshot =~ s/.*grep Id(.*)/$1/;
	  		$Our_Snapshot =~ s/[^0-9+]//g;
			my $Remove_Snapshot_Command = "vim-cmd vmsvc/snapshot.remove $Node_VM_ID $Our_Snapshot";
	
			if ($Verbose && $Our_Snapshot) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing $System_Name snapshot ID $Our_Snapshot for ${Yellow}$Host on node ${Blue}$Node${Clear}\n' >> $Log_File");
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing $System_Name snapshot ID $Our_Snapshot for ${Yellow}$Host ${Green}on node ${Blue}$Node${Clear}\n";
				system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Pink}$Remove_Snapshot_Command ${Green}for host ${Yellow}$Host ${Green}on node ${Blue}$Node${Green}${Clear}\n' >> $Log_File");
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Pink}$Remove_Snapshot_Command ${Green}for host ${Yellow}$Host ${Green}on node ${Blue}$Node${Green}${Clear}\n";
			}
			if ($Our_Snapshot) {
				$SSH->exec($Remove_Snapshot_Command, $Command_Timeout);
				if (@Host_IDs) {
					print "Removing $System_Name snapshot ID $Our_Snapshot for $Host on node $Node\n";
				}
				else {
					print "${Green}Removing $System_Name snapshot ID $Our_Snapshot for ${Yellow}$Host ${Green}on node ${Blue}$Node${Clear}\n";
				}
			}
			my $EC = $SSH->exec('echo $?', $Command_Timeout);
			$EC =~ s/[^0-9+]//g;
			if ($EC) {
				my $Error = "\n\tHost: $Host (VMID $Node_VM_ID)\n\tNode: $Node\n\tCommand: $Remove_Snapshot_Command\n\tExit Status: $EC\n\tNote: $Note";
				print "\nError ocurred: $Error\n\n";
			}
			if ($EC == 0) {
				$EC = "${Green}$EC";
			}
			else {
				$EC = "${Red}$EC";
			}
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Exit code for ${Yellow}$Host ${Green}remove snapshot ID $Our_Snapshot on ${Blue}$Node${Green}: $EC${Clear}\n";
				system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Exit code for ${Yellow}$Host ${Green}remove snapshot ID $Our_Snapshot on ${Blue}$Node${Green}: $EC${Clear}\n' >> $Log_File");
			}

	  	}
	}
	else {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Could not find any snapshots created by $System_Name that we could remove for ${Yellow}$Host ${Green}on node ${Blue}$Node${Clear}\n' >> $Log_File");
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Could not find any snapshots created by $System_Name that we could remove for ${Yellow}$Host ${Green}on node ${Blue}$Node${Clear}\n";
		}
	}

} # sub remove_snapshots

sub erase_all_snapshots {

my ($Host, $Node, $Node_VM_ID, $SSH, $Command_Timeout, $Log_File) = @_;

	if (@Host_IDs) {
		print "Removing ALL snapshots for $Host on node $Node\n";
	}
	else {
		print "${Green}Removing ALL snapshots for ${Yellow}$Host${Green} on node ${Blue}$Node${Clear}\n";
	}
	my $Remove_Snapshot_Command = "vim-cmd vmsvc/snapshot.removeall $Node_VM_ID";
	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing ALL snapshots for ${Yellow}$Host on node ${Blue}$Node${Clear}\n' >> $Log_File");
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Removing ALL snapshots for ${Yellow}$Host ${Green}on node ${Blue}$Node${Clear}\n";
		system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Pink}$Remove_Snapshot_Command ${Green}for host ${Yellow}$Host ${Green}on node ${Blue}$Node${Green}${Clear}\n' >> $Log_File");
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Pink}$Remove_Snapshot_Command ${Green}for host ${Yellow}$Host ${Green}on node ${Blue}$Node${Green}${Clear}\n";
	}
	$SSH->exec($Remove_Snapshot_Command, $Command_Timeout);

	my $EC = $SSH->exec('echo $?', $Command_Timeout);
	$EC =~ s/[^0-9+]//g;
	if ($EC) {
		my $Error = "\n\tHost: $Host (VMID $Node_VM_ID)\n\tNode: $Node\n\tCommand: $Remove_Snapshot_Command\n\tExit Status: $EC\n\tNote: $Note";
		print "\nError ocurred: $Error\n\n";
	}
	if ($EC == 0) {
		$EC = "${Green}$EC";
	}
	else {
		$EC = "${Red}$EC";
	}
	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Exit code for ${Yellow}$Host ${Green}remove all snapshots on ${Blue}$Node${Green}: $EC${Clear}\n";
		system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Exit code for ${Yellow}$Host ${Green}remove all snapshots on ${Blue}$Node${Green}: $EC${Clear}\n' >> $Log_File");
	}

} # sub erase_all_snapshots

sub take_snapshot {

my ($Host, $Node, $Node_VM_ID, $SSH, $Command_Timeout, $Log_File) = @_;

	my $Time_Date_Stamp = strftime "%H:%M:%S %d/%m/%Y", localtime;
	my $Snapshot_Name = "$System_Short_Name: $Host (VMID: $Node_VM_ID)";
	my $Snapshot_Description = "Snapshot taken of $Host by $System_Name on node $Node at $Time_Date_Stamp.";
	my $Include_Memory = 1;
	my $Snapshot_Command = "vim-cmd vmsvc/snapshot.create $Node_VM_ID '$Snapshot_Name' '$Snapshot_Description' $Include_Memory 0";

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		my $Snapshot_Command_Esc = $Snapshot_Command;
			$Snapshot_Command_Esc =~ s/'/"/g;
		system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Taking memory snapshot of ${Yellow}$Host ${Green}on node ${Blue}$Node${Clear}\n' >> $Log_File");
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Taking memory snapshot of ${Yellow}$Host ${Green}on node ${Blue}$Node${Clear}\n";
		system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Pink}${Snapshot_Command_Esc} ${Green}on node ${Blue}$Node${Clear}\n' >> $Log_File");
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Running ${Pink}${Snapshot_Command_Esc} ${Green}on node ${Blue}$Node${Clear}\n";
	}

	$SSH->exec($Snapshot_Command, $Command_Timeout);

	if (@Host_IDs) {
		print "Memory snapshot started of $Host on node $Node\n";
	}
	else {
		print "${Green}Memory snapshot started of ${Yellow}$Host ${Green}on node ${Blue}$Node${Clear}\n";
	}

	my $EC = $SSH->exec('echo $?', $Command_Timeout);
	$EC =~ s/[^0-9+]//g;
	if ($EC) {
		if (@Host_IDs) {
			print "Memory snapshot of $Host failed on node $Node - trying normal snapshot instead\n";
		}
		else {
			print "${Green}Memory snapshot of ${Yellow}$Host ${Red}failed ${Green}on node ${Blue}$Node ${Green}- trying normal snapshot instead${Clear}\n";
		}
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Memory snapshot of ${Yellow}$Host ${Green}on node ${Blue}$Node ${Red}failed${Green}. Trying normal snapshot.${Clear}\n' >> $Log_File");
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Memory snapshot of ${Yellow}$Host ${Green}on node ${Blue}$Node ${Red}failed${Green}. Trying normal snapshot.${Clear}\n";
		}
		my $Include_Memory = 0;
		my $Snapshot_Command = "vim-cmd vmsvc/snapshot.create $Node_VM_ID '$Snapshot_Name' '$Snapshot_Description' $Include_Memory 0";
	
		$SSH->exec($Snapshot_Command, $Command_Timeout);
	
		my $EC = $SSH->exec('echo $?', $Command_Timeout);
		$EC =~ s/[^0-9+]//g;
		if ($EC) {
			my $Error = "\n\tHost: $Host (VMID $Node_VM_ID)\n\tNode: $Node\n\tCommand: $Snapshot_Command\n\tExit Status: $EC\n\tNote: $Note";
			print "\nError ocurred: $Error\n\n";
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Normal snapshot of ${Yellow}$Host ${Green}on node ${Blue}$Node ${Red}also failed${Clear}\n' >> $Log_File");
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Normal snapshot of ${Yellow}$Host ${Green}on node ${Blue}$Node ${Red}also failed${Clear}\n";
			}
		}

		if ($EC == 0) {
			$EC = "${Green}$EC";
		}
		else {
			$EC = "${Red}$EC";
		}
	}
	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Exit code for ${Yellow}$Host ${Green}snapshot on ${Blue}$Node${Green}: $EC${Clear}\n";
		system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Exit code for ${Yellow}$Host ${Green}snapshot on ${Blue}$Node${Green}: $EC${Clear}\n' >> $Log_File");
	}

} # sub take_snapshot

sub count_snapshot {

my ($Host, $Node, $Node_VM_ID, $SSH, $Command_Timeout, $Log_File) = @_;

	my $Check_Snapshot = "vim-cmd vmsvc/snapshot.get $Node_VM_ID | grep Id | wc -l";
	my $Check_Our_Snapshot = "vim-cmd vmsvc/snapshot.get $Node_VM_ID | grep Name | grep $System_Short_Name | wc -l";
	my $Check_Is_Currently_Snapshotting = "vim-cmd vmsvc/get.tasklist $Node_VM_ID | grep createSnapshot | wc -l";
	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		system("echo '${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking for snapshots of ${Yellow}$Host ${Green}on node ${Blue}$Node${Clear}\n' >> $Log_File");
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking for snapshots of ${Yellow}$Host ${Green}on node ${Blue}$Node${Clear}\n";
	}
	my $Snapshot_Count = $SSH->exec($Check_Snapshot, $Command_Timeout);
		$Snapshot_Count =~ s/.*wc -l(.*)/$1/;
		$Snapshot_Count =~ s/[^0-9+]//g;
	my $Our_Snapshot_Count = $SSH->exec($Check_Our_Snapshot, $Command_Timeout);
		$Our_Snapshot_Count =~ s/.*wc -l(.*)/$1/;
		$Our_Snapshot_Count =~ s/[^0-9+]//g;
	my $Is_Snapshotting = $SSH->exec($Check_Is_Currently_Snapshotting, $Command_Timeout);
		$Is_Snapshotting =~ s/.*wc -l(.*)/$1/;
		$Is_Snapshotting =~ s/[^0-9+]//g;

		if ($Is_Snapshotting > 0) {
			$Is_Snapshotting = 'and is currently creating a new snapshot';
		}
		else {
			undef $Is_Snapshotting;
		}

	system("echo '${Yellow}$Host ${Green}has ${Pink}$Snapshot_Count ${Green}snapshots, ${Pink}$Our_Snapshot_Count ${Green}of which were created by $System_Name, on node ${Blue}$Node ${Green}$Is_Snapshotting${Clear}\n' >> $Log_File");
	if (@Host_IDs) {
		print "$Host (VMID $Node_VM_ID) has $Snapshot_Count snapshots, $Our_Snapshot_Count of which were created by $System_Name, on node $Node $Is_Snapshotting\n";
	}
	else {
		print "${Yellow}$Host ${Green}(VMID $Node_VM_ID) has ${Pink}$Snapshot_Count ${Green}snapshots, ${Pink}$Our_Snapshot_Count ${Green}of which were created by $System_Name, on node ${Blue}$Node ${Green}$Is_Snapshotting${Clear}\n";
	}

} # sub count_snapshot

1;