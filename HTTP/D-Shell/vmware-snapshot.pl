#!/usr/bin/perl

use strict;
use lib qw(/opt/TheMachine/Modules/);

use Parallel::ForkManager;
use POSIX qw(strftime);
use Getopt::Long qw(:config no_auto_abbrev no_ignore_case_always);

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Name = System_Name();
my $Version = Version();
my $DB_Connection = DB_Connection();
my $Final_Exit_Code = 0;

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
				threads matches the number of hosts provided. Setting it higher than this doesn't do anything, but setting it
				lower will help reduce load on VMware.
	${Blue}-H, --hosts\t\t${Green}A list of hosts, comma or space seperated.
	${Blue}-i, --host-ids\t\t${Green}A list of host IDs to snapshot, comma or space seperated.
	${Blue}-c, --count\t\t${Green}Counts the snapshots belonging to the VM, including those done by $System_Name.
	${Blue}-S, --show\t\t${Green}Shows a tree list of all snapshots taken of a VM, including those done by $System_Name.
	${Blue}-T, --tag\t\t${Green}Used with creating, deleting and reverting snapshots as a reference tag.
	${Blue}-s, --snapshot\t\t${Green}Takes a snapshot of the listed hosts. Combine with --tag to label the snapshot.
	${Blue}-d, --delete\t\t${Green}When supplied with --tag, removes the snapshot matching the tag, otherwise snapshots taken
				by The Machine that have no tag will be removed.
	${Blue}-e, --erase\t\t${Green}Removes ALL snapshots for listed hosts.
	${Blue}-R, --revert\t\t${Green}Combine with --tag to revert to a specific snapshot, otherwise the VM will be reverted to
				the current snapshot. Note that reverts are capped at one thread for safety, unless combined with --override.
	${Blue}--override\t\t${Green}Used for overriding the thread cap on reverts.
	${Blue}-v, --verbose\t\t${Green}Turns on verbose output (useful for debug).
	${Blue}-V, --very-verbose\t${Green}Same as verbose, but also includes thread data.
	${Blue}--no-colour\t\t ${Green}Strips colour from verbose output

${Green}Examples:
	${Green}## Snapshot server01 and tag it with 'My Snapshot' with verbose output turned on
	${Blue}$0 --snapshot -v -H server01 --tag 'My Snapshot'

	${Green}## Revert server01 to the snapshot tagged 'My Snapshot'
	${Blue}$0 --revert -H server01 --tag 'My Snapshot'

	${Green}## Delete the server01 snapshot tagged 'My Snapshot'
	${Blue}$0 --delete -H server01 --tag 'My Snapshot'

	${Green}## Remove ALL snapshots for server01/02/03
	${Blue}$0 --erase -H server01 server02 server03

	${Green}## Count the snapshots for servers with IDs 45, 698 and 322
	${Blue}$0 --count --host-ids 45 698 322 ${Clear}\n\n";


if (!@ARGV) {
	print $Help;
	exit(0);
}

my @Hosts;
my @Host_IDs;
my $Threads;
my $Verbose;
my $Very_Verbose;
my $Count;
my $Show;
my $Snapshot;
my $Remove;
my $Tag;
my $Erase;
my $Revert;
	my $Yes;
	my $Override;
my $Username;
my $No_Colour;

GetOptions(
	't:i' => \$Threads,
	'threads:i' => \$Threads,
	'H:s{1,}' => \@Hosts, # Set as string due to possibility of space seperation
	'hosts:s{1,}' => \@Hosts, # Set as string due to possibility of space seperation
	'i:s{1,}' => \@Host_IDs, # Set as string due to possibility of space seperation
	'host-ids:s{1,}' => \@Host_IDs, # Set as string due to possibility of space seperation
	'c' => \$Count,
	'count' => \$Count,
	'S' => \$Show,
	'show' => \$Show,
	's' => \$Snapshot,
	'snapshot' => \$Snapshot,
	'd' => \$Remove,
	'delete' => \$Remove,
	'T:s' => \$Tag,
	'tag:s' => \$Tag,
	'e' => \$Erase,
	'erase' => \$Erase,
	'R' => \$Revert,
	'revert' => \$Revert,
	'X:s' => \$Username,
	'username:s' => \$Username,
	'y' => \$Yes,
	'override' => \$Override,
	'v' => \$Verbose,
	'verbose' => \$Verbose,
	'V' => \$Very_Verbose,
	'very-verbose' => \$Very_Verbose,
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

@Hosts = split(/[\s,]+/,join(',' , @Hosts));
if (!$Threads) {$Threads = scalar(keys @Hosts);}
if ($Revert && !$Override) {$Threads = 1}

if ($Very_Verbose) {$Verbose = 1}
if ($Verbose) {
	my $Time_Stamp = strftime "%H:%M:%S", localtime;
	print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Verbose mode on.${Clear}\n";
	if ($Revert && !$Override) {
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Revert requested - threads capped at ${Yellow}$Threads${Green}.${Clear}\n";
	}
	elsif ($Revert && $Override) {
		print "${Red}##\n";
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}Revert thread override requested - thread cap set to ${Yellow}$Threads${Pink}.${Clear}\n";
		print "${Red}##${Clear}\n";
	}
	else {
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Threads set to ${Yellow}$Threads${Green}.${Clear}\n";
	}
}

if ($Revert && !$Yes) {
	use Term::ReadKey;
	print "You are about to perform a snapshot REVERT operation. Confirm [y/n]: ";
	$Yes = <STDIN>;
		$Yes =~ s/\n//g;
		$Yes =~ s/\r//g;
	if ($Yes ne 'y') {print "Not without confirmation. Exiting.\n"; exit(0);};
}
if ($Revert && $Override) {
	print "Revert thread override detected. (CTRL + C to cancel)...\n\n";
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
	print "Reverting snapshots...\r";
}

my $Fork = new Parallel::ForkManager($Threads);
	$Fork->run_on_start(
    	sub { my ($PID, $Thread_Name)=@_;
    		if ($Very_Verbose) {
    			print "D-Shell Thread: $Thread_Name has started, PID: $PID.\n";
    		}
		}
	);
	$Fork->run_on_finish(
		sub {
			my ($PID, $Exit_Code, $Thread_Name, $Exit_Signal, $Core_Dump, $Return) = @_;

			if ($Very_Verbose) {
				print "D-Shell Thread: $Thread_Name (PID:$PID) has finished. Exit code: $Exit_Code.\n";
			}
			if ($Exit_Code ne 0) {$Final_Exit_Code = $Exit_Code}
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

		if ($Host =~ /^([0-9a-zA-Z\-\_\s\.]+)$/) {$Host = $1;}
		else {Security_Notice('Snapshot Input', $ENV{'REMOTE_ADDR'}, $0, $Host, 'System');}

		my $PID = $Fork->start ("Processing $Host") and next;

			if ($Count || (!$Show && !$Snapshot && !$Revert && !$Remove && !$Erase)) {
				&count_snapshot($Host);
			}
			if ($Show) {
				&show_snapshot($Host);
			}
			elsif ($Snapshot) {
				&take_snapshot($Host, $Tag);
			}
			elsif ($Revert) {
				&revert_snapshot($Host, $Tag);
			}
			elsif ($Remove) {
				&remove_snapshot($Host, $Tag);
			}
			elsif ($Erase) {
				&erase_all_snapshots($Host);
			}

		$Fork->finish(0);

	} # Hosts

	$Fork->wait_all_children;

sub remove_snapshot {

	my ($Host, $Snapshot_Tag) = @_;

	if (!$Snapshot_Tag) {$Snapshot_Tag = "$System_Name: $Host"} else {$Snapshot_Tag = "$System_Name: $Snapshot_Tag"}

	my $Time_Date_Stamp = strftime "%Y-%m-%d %H:%M:%S", localtime;

	my ($vSphere_Server, $vSphere_Username, $vSphere_Password) = VMware_Connection();
	Util::connect($vSphere_Server, $vSphere_Username, $vSphere_Password);

	my $Discovered_VM = Vim::find_entity_views(
		view_type => 'VirtualMachine',
		properties => ['summary', 'snapshot'],
		filter => { 'name' => "$Host" }
	);

	my $VM = @$Discovered_VM[0];

	if (!$VM) {print "Error: Could not find $Host.\n"; exit(20)}

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Trying to remove snapshots matching tag ${Yellow}$Snapshot_Tag${Green} for ${Blue}$Host${Green}.${Clear}\n";
	}

	my ($Snapshot_Reference, $Number_of_Matching_Snapshots);
	eval {($Snapshot_Reference, $Number_of_Matching_Snapshots) = discover_snapshot_reference($VM->snapshot->rootSnapshotList, $Snapshot_Tag);};

	if ($Number_of_Matching_Snapshots >= 1) {
		if ($Number_of_Matching_Snapshots > 1 && $Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}Found ${Blue}$Number_of_Matching_Snapshots${Pink} snapshots matching ${Yellow}$Snapshot_Tag${Pink} for ${Blue}$Host${Pink}. Removing just the most recent.${Clear}\n";
		}
		if (defined $Snapshot_Reference) {
			my $VM_Snapshot_to_Remove = Vim::get_view (mo_ref=>$Snapshot_Reference->snapshot);
			eval {$VM_Snapshot_to_Remove->RemoveSnapshot(removeChildren => 0);}
		}

		if ($@) {
			print "Something went wrong trying to delete $System_Name snapshots from $Host:\n $@\n";
			exit(21);
		}
		else {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Deleted a snapshot of ${Blue}$Host${Green} matching ${Yellow}$Snapshot_Tag${Green} successfully!${Clear}\n";
			}
			else {
				print "Deleted a snapshot of $Host matching '$Snapshot_Tag' successfully!\n";
			}
		}

	}
	else {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}There does not appear to be any snapshots matching ${Yellow}$Snapshot_Tag${Pink} for ${Blue}$Host${Pink}.${Clear}\n";
		}
		else {
			print "There does not appear to be any snapshots matching '$Snapshot_Tag' for $Host.\n";
		}
	}

	Util::disconnect();

} # sub remove_snapshot

sub discover_snapshot_reference {
	my ($Tree, $Snapshot_Name) = @_;
	my $Snapshot_Reference = undef;
	my $Snapshot_Count = 0;
	foreach my $Node (@$Tree) {
		if ($Node->name eq $Snapshot_Name) {
		$Snapshot_Reference = $Node;
		$Snapshot_Count++;
	}
	my ($subReference, $subCount) = discover_snapshot_reference($Node->childSnapshotList, $Snapshot_Name);
	$Snapshot_Count = $Snapshot_Count + $subCount;
	$Snapshot_Reference = $subReference if ($subCount);
	}
	return ($Snapshot_Reference, $Snapshot_Count);
} # sub discover_snapshot_reference

sub erase_all_snapshots {

	my ($Host) = $_[0];

	my $Time_Date_Stamp = strftime "%Y-%m-%d %H:%M:%S", localtime;

	my ($vSphere_Server, $vSphere_Username, $vSphere_Password) = VMware_Connection();
	Util::connect($vSphere_Server, $vSphere_Username, $vSphere_Password);

	my $Discovered_VM = Vim::find_entity_views(
		view_type => 'VirtualMachine',
		properties => ['summary', 'snapshot'],
		filter => { 'name' => "$Host" }
	);

	my $VM = @$Discovered_VM[0];

	if (!$VM) {print "Error: Could not find $Host.\n"; exit(20)}

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}Deleting ALL snapshots of ${Blue}$Host${Pink}.${Clear}\n";
	}

	eval {$VM->RemoveAllSnapshots();};


	if ($@) {
		print "Something went wrong trying to delete all snapshots from $Host:\n $@\n";
		exit(21);
	}
	else {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}All snapshots of ${Blue}$Host ${Green}deleted successfully!${Clear}\n";
		}
		printf("%-15s %-5s", "$Host:", "All snapshots deleted successfully!\n");
	}

	Util::disconnect();

} # sub erase_all_snapshots

sub take_snapshot {

	my ($Host, $Snapshot_Tag) = @_;

	if (!$Snapshot_Tag) {$Snapshot_Tag = "$System_Name: $Host"} else {$Snapshot_Tag = "$System_Name: $Snapshot_Tag"}

	my $Time_Date_Stamp = strftime "%Y-%m-%d %H:%M:%S", localtime;
	my $Snapshot_Description;
	if ($Username) {
		$Snapshot_Description = "Snapshot taken of $Host by $Username on $System_Name at $Time_Date_Stamp.";
	}
	else {
		$Snapshot_Description = "Snapshot taken of $Host by $System_Name at $Time_Date_Stamp.";
	}

	my ($vSphere_Server, $vSphere_Username, $vSphere_Password) = VMware_Connection();
	Util::connect($vSphere_Server, $vSphere_Username, $vSphere_Password);

	my $Discovered_VM = Vim::find_entity_views(
		view_type => 'VirtualMachine',
		properties => ['summary', 'snapshot'],
		filter => { 'name' => "$Host" }
	);

	my $VM = @$Discovered_VM[0];

	if (!$VM) {print "Error: Could not find $Host.\n"; exit(20)}

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Snapshot tag for ${Blue}$Host${Green} will be '${Yellow}$Snapshot_Tag${Green}'.${Clear}\n";
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Trying to memory snapshot ${Blue}$Host${Green}.${Clear}\n";
	}

	eval {$VM->CreateSnapshot(
			name => "$Snapshot_Tag",
			description => "This is a memory snapshot. $Snapshot_Description",
			memory => 1,
			quiesce => 0);
	};

	if ($@) {
		if ($@ =~ /MemorySnapshotOnIndependentDisk/) {
	
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Memory snapshot of ${Blue}$Host ${Red}failed! ${Green}Trying disk snapshot instead.${Clear}\n";
			}

			eval {$VM->CreateSnapshot(
					name => "$Snapshot_Tag",
					description => "This is a disk only snapshot. $Snapshot_Description",
					memory => 0,
					quiesce => 1);
			};
			if ($@) {
				print "Something went wrong trying to snapshot $Host:\n $@\n";
				exit(21);
			}
			else {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Disk snapshot of ${Blue}$Host ${Green}completed successfully!${Clear}\n";
				}
				printf("%-15s %-5s", "$Host:", "Disk snapshot created successfully with tag '$Snapshot_Tag'.\n");
			}
		}
		else {
			print "Something went wrong trying to snapshot $Host:\n $@\n";
			exit(21);
		}
	}
	else {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Memory snapshot of ${Blue}$Host ${Green}completed successfully!${Clear}\n";
		}
		printf("%-15s %-5s", "$Host:", "Memory snapshot created successfully with tag '$Snapshot_Tag'.\n");
	}

	Util::disconnect();

} # sub take_snapshot

sub count_snapshot {

	my ($Host) = $_[0];

	my $Time_Date_Stamp = strftime "%H:%M:%S %d/%m/%Y", localtime;

	my ($vSphere_Server, $vSphere_Username, $vSphere_Password) = VMware_Connection();
	Util::connect($vSphere_Server, $vSphere_Username, $vSphere_Password);

	my $Discovered_VM = Vim::find_entity_views(
		view_type => 'VirtualMachine',
		properties => ['summary', 'snapshot'],
		filter => { 'name' => "$Host" }
	);

	my $VM = @$Discovered_VM[0];

	if (!$VM) {print "Error: Could not find $Host.\n"; exit(20)}

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking for snapshots on ${Blue}$Host${Green}.${Clear}\n";
	}

   if ($VM->snapshot) {
		my ($Count, $Count_Machine) = count_snapshot_tree($Host, $VM->snapshot->rootSnapshotList);
		printf("%-15s %-5s", "$Host:", "$Count snapshots, $Count_Machine of which were created by $System_Name.\n");
	}
	else {
		print "$Host has no snapshots.\n";
	}

	Util::disconnect();

} # sub count_snapshot

sub count_snapshot_tree {

	my ($Host, $Tree, $Snapshot_Count, $Machine_Snapshot_Count) = @_;
	if (!$Snapshot_Count) {$Snapshot_Count=0}
	if (!$Machine_Snapshot_Count) {$Machine_Snapshot_Count=0}

	foreach my $Node (@$Tree) {

		($Snapshot_Count, $Machine_Snapshot_Count) = count_snapshot_tree($Host, $Node->childSnapshotList, $Snapshot_Count, $Machine_Snapshot_Count);

		my $Snapshot_Name = $Node->name;
		if ($Snapshot_Name =~ /$System_Name: /) {$Machine_Snapshot_Count += 1}
		$Snapshot_Count += 1;
	}

	return ($Snapshot_Count, $Machine_Snapshot_Count);

} # sub count_snapshot_tree

sub show_snapshot {

	my ($Host) = $_[0];

	my $Time_Date_Stamp = strftime "%H:%M:%S %d/%m/%Y", localtime;

	my ($vSphere_Server, $vSphere_Username, $vSphere_Password) = VMware_Connection();
	Util::connect($vSphere_Server, $vSphere_Username, $vSphere_Password);

	my $Discovered_VM = Vim::find_entity_views(
		view_type => 'VirtualMachine',
		properties => ['summary', 'snapshot'],
		filter => { 'name' => "$Host" }
	);

	my $VM = @$Discovered_VM[0];

	if (!$VM) {print "Error: Could not find $Host.\n"; exit(20)}

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking for snapshots on ${Blue}$Host${Green}.${Clear}\n";
	}

   if ($VM->snapshot) {
   		print "\n$Host\n";
		show_snapshot_tree($Host, $VM->snapshot->rootSnapshotList);
	}
	else {
		print "$Host has no snapshots.\n";
	}

	Util::disconnect();

} # sub show_snapshot

sub show_snapshot_tree {

	my ($Host, $Tree, $Indentation) = @_;
	$Indentation+=3;

	foreach my $Node (@$Tree) {
		my $Quiesced = $Node->quiesced;
		if ($Quiesced) {$Quiesced = 'Yes'} else {$Quiesced = 'No'}

		print " " x $Indentation . "|\n" 
		. " " x $Indentation . "|- " . "Name:        " . $Node->name . "\n"
		. " " x ($Indentation + 3)   . "Created:     " . $Node->createTime . "\n"
		. " " x ($Indentation + 3)   . "State:       " . $Node->state->val . "\n"
		. " " x ($Indentation + 3)   . "Description: " . $Node->description . "\n"
		. " " x ($Indentation + 3)   . "Quiesced:    " . $Quiesced . "\n";

		show_snapshot_tree($Host, $Node->childSnapshotList, $Indentation);
	}
} # sub show_snapshot_tree

sub revert_snapshot {

	my ($Host, $Snapshot_Tag) = @_;

	if (!$Snapshot_Tag) {$Snapshot_Tag = ""} else {$Snapshot_Tag = "$System_Name: $Snapshot_Tag"}

	my $Time_Date_Stamp = strftime "%Y-%m-%d %H:%M:%S", localtime;

	my ($vSphere_Server, $vSphere_Username, $vSphere_Password) = VMware_Connection();
	Util::connect($vSphere_Server, $vSphere_Username, $vSphere_Password);

	my $Discovered_VM = Vim::find_entity_views(
		view_type => 'VirtualMachine',
		properties => ['summary', 'snapshot'],
		filter => { 'name' => "$Host" }
	);

	my $VM = @$Discovered_VM[0];

	if (!$VM) {print "Error: Could not find $Host.\n"; exit(20)}

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		if ($Snapshot_Tag) {
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Trying to revert to the snapshot matching tag ${Yellow}$Snapshot_Tag${Green} for ${Blue}$Host${Green}.${Clear}\n";
		}
		else {
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Trying to revert to the current snapshot for ${Blue}$Host${Green}.${Clear}\n";
		}
	}

	if ($Snapshot_Tag) {
		my ($Snapshot_Reference, $Number_of_Matching_Snapshots);
		eval {($Snapshot_Reference, $Number_of_Matching_Snapshots) = discover_snapshot_reference($VM->snapshot->rootSnapshotList, $Snapshot_Tag);};
	
		if ($Number_of_Matching_Snapshots >= 1) {
			if ($Number_of_Matching_Snapshots > 1 && $Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}Found ${Blue}$Number_of_Matching_Snapshots${Pink} snapshots matching ${Yellow}$Snapshot_Tag${Pink} for ${Blue}$Host${Pink}. Removing just the most recent.${Clear}\n";
			}
			if (defined $Snapshot_Reference) {
				my $VM_Snapshot_to_Remove = Vim::get_view (mo_ref=>$Snapshot_Reference->snapshot);
				eval {$VM_Snapshot_to_Remove->RevertToSnapshot();};
			}
	
			if ($@) {
				print "Something went wrong trying to revert to the snapshot tagged $Snapshot_Tag for $Host:\n $@\n";
				exit(21);
			}
			else {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Reverted ${Blue}$Host${Green} to the snapshot matching tag ${Yellow}$Snapshot_Tag${Green} successfully!${Clear}\n";
				}
				printf("%-15s %-5s", "$Host:", "Reverted successfully to the snapshot matching tag '$Snapshot_Tag'.\n");
			}
		}
		else {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}There does not appear to be any snapshots matching ${Yellow}$Snapshot_Tag${Pink} for ${Blue}$Host${Pink}.${Clear}\n";
			}
			printf("%-15s %-5s", "$Host:", "There does not appear to be any snapshots matching '$Snapshot_Tag'.\n");
		}
	}
	else {
		eval {$VM->RevertToCurrentSnapshot();};

		if ($@) {
			print "Something went wrong trying to revert to the latest snapshot for $Host:\n $@\n";
			exit(21);
		}
		else {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Reverted ${Blue}$Host${Green} to the current snapshot successfully!${Clear}\n";
			}
			printf("%-15s %-5s", "$Host:", "Reverted to the current snapshot successfully!\n");
		}
	}

	Util::disconnect();


} # sub revert_snapshot


exit($Final_Exit_Code);
