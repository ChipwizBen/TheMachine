#!/usr/bin/perl

use strict;
use Parallel::ForkManager;
use POSIX qw(strftime);
use Getopt::Long qw(:config no_ignore_case);

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Name = System_Name();
my $System_Short_Name = System_Short_Name();
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
	${Blue}-H, --hosts\t\t${Green}A list of hosts, comma or space seperated [e.g.: -H host01,host02,host03]
	${Blue}-i, --host-ids\t\t${Green}A list of host IDs to snapshot, comma or space seperated [e.g.: -H 4587,155,2341]
	${Blue}-c, --count\t\t${Green}Counts the snapshots belonging to the VM, including those done by $System_Name
	${Blue}-S, --show\t\t${Green}Shows a tree list of all snapshots taken of a VM, including those done by $System_Name
	${Blue}-s, --snapshot\t\t${Green}Takes a snapshot of the listed hosts
	${Blue}-r, --remove\t\t${Green}Removes snapshots for listed hosts that were created by $System_Name
	${Blue}-e, --erase\t\t${Green}Removes ALL snapshots for listed hosts
	${Blue}-R, --restore-latest\t${Green}Restores the most recently taken snapshot of a VM
	${Blue}-v, --verbose\t\t${Green}Turns on verbose output (useful for debug)
	${Blue}-V, --very-verbose\t${Green}Same as verbose, but also includes thread data

${Green}Examples:
	${Green}## Snapshot server01
	${Blue}$0 -s -H server01

	${Green}## Remove ALL snapshots for server01/02/03, then takes a snapshot of each, with verbose turned on
	${Blue}$0 -v -e -H server01,server02,server03

	${Green}## Count the snapshots for servers with IDs 45, 698 and 322
	${Blue}$0 -c -i 45,698,322 ${Clear}\n\n";


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
my $Erase;
my $Restore_Latest;

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
	'r' => \$Remove,
	'remove' => \$Remove,
	'e' => \$Erase,
	'erase' => \$Erase,
	'R' => \$Restore_Latest,
	'restore-latest' => \$Restore_Latest,
	'v' => \$Verbose,
	'verbose' => \$Verbose,
	'V' => \$Very_Verbose,
	'very-verbose' => \$Very_Verbose,
) or die("Fault with options: $@\n");

@Hosts = split(/[\s,]+/,join(',' , @Hosts));
if (!$Threads) {$Threads = scalar(keys @Hosts);}

if ($Very_Verbose) {$Verbose = 1}
if ($Verbose) {
	my $Time_Stamp = strftime "%H:%M:%S", localtime;
	print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Verbose mode on${Clear}\n";
	print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Threads set to $Threads${Clear}\n";
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

			if ($Count || (!$Show && !$Snapshot && !$Restore_Latest && !$Remove && !$Erase)) {
				&count_snapshot($Host);
			}
			if ($Show) {
				&show_snapshot($Host);
			}
			elsif ($Snapshot) {
				&take_snapshot($Host);
				&count_snapshot($Host);
			}
			elsif ($Restore_Latest) {
				&restore_latest_snapshot($Host);
			}
			elsif ($Remove) {
				&remove_snapshots($Host);
			}
			elsif ($Erase) {
				&erase_all_snapshots($Host);
			}

		$Fork->finish(0);

	} # Hosts

	$Fork->wait_all_children;

sub remove_snapshots {



} # sub remove_snapshots

sub erase_all_snapshots {


} # sub erase_all_snapshots

sub take_snapshot {

	my ($Host) = $_[0];

	my $Time_Date_Stamp = strftime "%Y-%m-%d %H:%M:%S", localtime;
	my $Snapshot_Name = "$System_Short_Name: $Host";
	my $Snapshot_Description = "Snapshot taken of $Host by $System_Name at $Time_Date_Stamp.";
	my $Include_Memory = 1;

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
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Trying to memory snapshot ${Blue}$Host${Clear}\n";
	}

	eval {$VM->CreateSnapshot(
			name => "$Snapshot_Name",
			description => "This is a memory snapshot. $Snapshot_Description",
			memory => $Include_Memory,
			quiesce => 0);
	};

	if ($@) {
		if ($@ =~ /MemorySnapshotOnIndependentDisk/) {
	
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Memory snapshot of ${Blue}$Host ${Red}failed! ${Green}Trying disk snapshot instead.${Clear}\n";
			}

			eval {$VM->CreateSnapshot(
					name => "$Snapshot_Name",
					description => "This is a disk only snapshot. $Snapshot_Description",
					memory => 0,
					quiesce => 1);
			};
			if ($@) {
				print "Something went wrong trying to snapshot $Host\n: $@\n";
				exit(21);
			}
			else {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Disk snapshot of ${Blue}$Host ${Green}completed successfully!${Clear}\n";
				}
			}
		}
		else {
			print "Something went wrong trying to snapshot $Host\n: $@\n";
			exit(21);
		}
	}
	else {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Memory snapshot of ${Blue}$Host ${Green}completed successfully!${Clear}\n";
		}
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
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking for snapshots on ${Blue}$Host${Clear}\n";
	}

   if ($VM->snapshot) {
		my ($Count, $Count_Machine) = count_snapshot_tree($Host, $VM->snapshot->rootSnapshotList);
		printf("%-15s %-5s", "$Host:", "$Count snapshots, $Count_Machine of which were created by $System_Name\n");
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
		if ($Snapshot_Name eq "$System_Short_Name: $Host") {$Machine_Snapshot_Count += 1}
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
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking for snapshots on ${Blue}$Host${Clear}\n";
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

exit($Final_Exit_Code);
