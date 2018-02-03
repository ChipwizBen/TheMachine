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
my $System_Short_Name = System_Short_Name();
	$System_Short_Name =~  s/\W/_/g;
my $Version = Version();
my $DB_Connection = DB_Connection();
my ($Proxmox_Node, $Proxmox_Node_Port, $Proxmox_Username, $Proxmox_Password) = Proxmox_Connection();
my $Verbose = Verbose();
my $Very_Verbose = Very_Verbose();
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
				lower will help reduce load on Proxmox.
	${Blue}-H, --hosts\t\t${Green}A list of hosts, comma or space seperated.
	${Blue}-i, --host-ids\t\t${Green}A list of (Machine) host IDs to snapshot, comma or space seperated.
	${Blue}-S, --show\t\t${Green}Shows a tree list of all snapshots taken of a VM, including those done by $System_Name.
	${Blue}-T, --tag\t\t${Green}Used with creating, deleting and reverting snapshots as a reference tag.
	${Blue}-s, --snapshot\t\t${Green}Takes a snapshot of the listed hosts. Combine with --tag to label the snapshot.
	${Blue}-d, --delete\t\t${Green}When supplied with --tag, removes the snapshot matching the tag, otherwise snapshots taken
				by The Machine that have no tag will be removed.
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

	${Green}## Count the snapshots for servers with IDs 45, 698 and 322
	${Blue}$0 --count --host-ids 45 698 322 ${Clear}\n\n";


if (!@ARGV) {
	print $Help;
	exit(0);
}

my @Hosts;
my @Host_IDs;
my $Threads;
my $Show;
my $Snapshot;
my $Remove;
my $Tag;
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
	'S' => \$Show,
	'show' => \$Show,
	's' => \$Snapshot,
	'snapshot' => \$Snapshot,
	'd' => \$Remove,
	'delete' => \$Remove,
	'T:s' => \$Tag,
	'tag:s' => \$Tag,
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

if ($Verbose) {
	print "${Red}## ${Green}Verbose is on (PID: $$).${Clear}\n";
}
if ($Very_Verbose) {
	$Verbose = 1;
	print "${Red}## ${Pink}Very Verbose mode is on (PID: $$).${Clear}\n";
}

if (!$Tag && ($Snapshot || $Remove || $Revert)) {
	print "You must suppy a tag when creating, removing or reverting a snapshot.\n";
	exit(21);
}

$Tag =~ s/\W/_/g;

my $Proxmox_Auth_Data = `curl --connect-timeout 10 --max-time 60 -k -sS --data "username=$Proxmox_Username&password=$Proxmox_Password"  https://$Proxmox_Node:$Proxmox_Node_Port/api2/json/access/ticket`;
if ($Very_Verbose) {
	my $Time_Stamp = strftime "%H:%M:%S", localtime;
	print "${Red}## Verbose (PID:$$) $Time_Stamp ## Auth Data: ${Yellow}$Proxmox_Auth_Data${Clear}\n";
}

if ($Proxmox_Auth_Data =~ /"data":null/) {print "Proxmox authentication failure. Aborting.\n"; exit 21;}
if ($?) {print "Proxmox authentication failure. Aborting.\n"; exit 21;}

my $Proxmox_Auth_Token = $Proxmox_Auth_Data;
	$Proxmox_Auth_Token =~ s/.*ticket":"(.*?)".*/PVEAuthCookie=$1/;
my $Proxmox_Auth_CSRF_Preservation_Token = $Proxmox_Auth_Data;
	$Proxmox_Auth_CSRF_Preservation_Token =~ s/.*CSRFPreventionToken":"(.*?)".*/CSRFPreventionToken:$1/;

my $Curl = qq/curl --connect-timeout 10 --max-time 60 -k -sS --cookie "$Proxmox_Auth_Token" --header "$Proxmox_Auth_CSRF_Preservation_Token"/;
my $API = $Curl . " https://$Proxmox_Node:$Proxmox_Node_Port/api2/json";

if ($Very_Verbose) {
	my $Time_Stamp = strftime "%H:%M:%S", localtime;
	print "${Red}## Verbose (PID:$$) $Time_Stamp ## API Link: ${Yellow}$API${Clear}\n";
}

@Hosts = split(/[\s,]+/,join(',' , @Hosts));
if (!$Threads) {$Threads = scalar(keys @Hosts);}
if ($Revert && !$Override) {$Threads = 1}

if ($Verbose) {
	my $Time_Stamp = strftime "%H:%M:%S", localtime;
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

		my $Select_Host_Attributes = $DB_Connection->prepare("SELECT `vm_name`
		FROM `host_attributes`
		WHERE `host_id` = ?");
		$Select_Host_Attributes->execute($Host_ID);
	
		my $VM_Name = $Select_Host_Attributes->fetchrow_array();

		if (!$VM_Name) {
			my $Host_Name_Query = $DB_Connection->prepare("SELECT `hostname`
			FROM `hosts`
			WHERE `id` = ?");
			$Host_Name_Query->execute($Host_ID);
			$VM_Name = $Host_Name_Query->fetchrow_array();
		}
		push @Hosts, $VM_Name;
	}

	foreach my $Host (@Hosts) {

		if ($Host =~ /^([0-9a-zA-Z\-\_\s\.]+)$/) {$Host = $1;}
		else {Security_Notice('Snapshot Input', $ENV{'REMOTE_ADDR'}, $0, $Host, 'System');}

		my $PID = $Fork->start ("Processing $Host") and next;

			if ($Show || ((!$Show && !$Snapshot && !$Revert && !$Remove))) {
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

		$Fork->finish(0);

	} # Hosts

	$Fork->wait_all_children;

sub remove_snapshot {

	my ($Host, $Snapshot_Tag) = @_;
	my ($VM_ID, $VM_Node, $VM_Type) = &cluster_details($Host);

	if (!$VM_ID || !$VM_Node || !$VM_Type) {return 1};

	#if (!$Snapshot_Tag) {$Snapshot_Tag = "$System_Short_Name_$Host"} else {$Snapshot_Tag = "$System_Short_Name_$Snapshot_Tag"}

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Trying to remove snapshots matching tag ${Yellow}$Snapshot_Tag${Green} for ${Blue}$Host${Green}.${Clear}\n";
	}

	my $Snapshot_Exists = &check_snapshot($Host, $Snapshot_Tag, $VM_ID, $VM_Node, $VM_Type);
	if ($Snapshot_Exists) {
	
		&check_locks($Host, $VM_ID, $VM_Node, $VM_Type);

		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Deleting snapshot matching tag ${Yellow}$Snapshot_Tag${Green} for ${Blue}$Host${Green}.${Clear}\n";
		}

		my $Delete_Snapshot = `$API/nodes/$VM_Node/$VM_Type/$VM_ID/snapshot/$Snapshot_Tag -X DELETE`;
		if ($?) {
			print "Something went wrong trying to delete $System_Name snapshots for $Host on node $VM_Node:\n $@\n";
			exit(21);
		}
		my $Snapshot_Exists = &check_snapshot($Host, $Snapshot_Tag, $VM_ID, $VM_Node, $VM_Type);
		if (!$Snapshot_Exists) {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Deleted a snapshot of ${Blue}$Host${Green} matching ${Yellow}$Snapshot_Tag${Green} successfully!${Clear}\n";
			}
			else {
				print "Deleted a snapshot of $Host matching '$Snapshot_Tag' successfully!\n";
			}
		}
		else {
			print "Something went wrong trying to delete $System_Name snapshots for $Host on node $VM_Node:\n $@\n";
			exit(21);
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
		exit(21);
	}

} # sub remove_snapshot

sub take_snapshot {

	my ($Host, $Snapshot_Tag) = @_;
	my ($VM_ID, $VM_Node, $VM_Type) = &cluster_details($Host);

	if (!$VM_ID || !$VM_Node || !$VM_Type) {return 1};

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Taking a snapshot of ${Blue}$Host${Green} with the tag ${Yellow}$Snapshot_Tag${Green}.${Clear}\n";
	}

	&check_locks($Host, $VM_ID, $VM_Node, $VM_Type);

	my $Snapshot_Exists = &check_snapshot($Host, $Snapshot_Tag, $VM_ID, $VM_Node, $VM_Type);
	if ($Snapshot_Exists) {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}A snapshot of ${Blue}$Host${Pink} matching ${Yellow}$Snapshot_Tag${Pink} already exists!${Clear}\n";
			exit(21);
		}
		else {
			print "A snapshot of $Host matching '$Snapshot_Tag' already exists!\n";
			exit(21);
		}
	}
	else {

		my $Snapshot_Description;
		my $Time_Date_Stamp = strftime "%Y-%m-%d %H:%M:%S", localtime;
		if ($Username) {
			$Snapshot_Description = "The Machine: Snapshot taken ($VM_Type) of $Host on $VM_Node by $Username at $Time_Date_Stamp.";
		}
		else {
			$Snapshot_Description = "The Machine: Snapshot taken ($VM_Type) of $Host on $VM_Node at $Time_Date_Stamp.";
		}

		my $Take_Snapshot = `$API/nodes/$VM_Node/$VM_Type/$VM_ID/snapshot -X POST \\
		--data snapname="$Snapshot_Tag" \\
		--data description="The Machine: Snapshot taken ($VM_Type) of $Host on $VM_Node by $Username at $Time_Date_Stamp." \\
		--data vmstate=1`;
		if ($?) {print "Error taking a snapshot of VMID $VM_ID: Curl Error $?\n"; exit(21);}
	}

	$Snapshot_Exists = &check_snapshot($Host, $Snapshot_Tag,  $VM_ID, $VM_Node, $VM_Type);
	if ($Snapshot_Exists) {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}A snapshot of ${Blue}$Host${Green} matching ${Yellow}$Snapshot_Tag${Green} was successfully created.${Clear}\n";
		}
		else {
			print "A snapshot of $Host matching '$Snapshot_Tag' was successfully created.\n";
		}
	}
	else {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}Something went wrong trying to snapshot ${Blue}$Host${Pink}.${Clear}\n";
			exit(21);
		}
		else {
			print "Something went wrong trying to snapshot $Host.\n";
			exit(21);
		}
	}

} # sub take_snapshot

sub show_snapshot {

	my ($Host) = $_[0];
	my ($VM_ID, $VM_Node, $VM_Type) = &cluster_details($Host);

	if (!$VM_ID || !$VM_Node || !$VM_Type) {return 1};

	&check_locks($Host, $VM_ID, $VM_Node, $VM_Type);

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking for snapshots on ${Blue}$Host${Green}.${Clear}\n";
	}

	my $Snapshot_Details = `$API/nodes/$VM_Node/$VM_Type/$VM_ID/snapshot`;
	if ($?) {print "Error showing snapshots for VMID $VM_ID: Curl Error $?\n"; exit(21);}

   if (!$Snapshot_Details || $Snapshot_Details !~ /"vmstate":/) {
   		print "$Host has no snapshots.\n";
	}
	else {
		
		my @Snapshots = split '{', $Snapshot_Details;
		
		foreach (@Snapshots) {

			if ($_ =~ /snaptime/) {
				my $Snapshot_Name = $_;
					$Snapshot_Name =~ s/.*"name":"(.*?)".*/$1/g;
				my $Snapshot_Time = $_;
					$Snapshot_Time =~ s/.*"snaptime":(\d+),.*/$1/g;
					$Snapshot_Time = strftime '%Y/%m/%d %H:%M:%S', localtime $Snapshot_Time;
				my $Snapshot_Parent;
				if ($_ =~ /parent/) {
					$Snapshot_Parent = $_;
					$Snapshot_Parent =~ s/.*"parent":"(.*?)".*/$1/g;
				}
				print "Host:\t$Host\nName:\t$Snapshot_Name\nTime:\t$Snapshot_Time\nParent:\t$Snapshot_Parent\n\n";
			}
		}
	}

} # sub show_snapshot

sub revert_snapshot {

	my ($Host, $Snapshot_Tag) = @_;
	my ($VM_ID, $VM_Node, $VM_Type) = &cluster_details($Host);

	if (!$VM_ID || !$VM_Node || !$VM_Type) {return 1};

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Reverting to snapshot ${Yellow}$Snapshot_Tag${Green} for host ${Blue}$Host${Green}.${Clear}\n";
	}

	&check_locks($Host, $VM_ID, $VM_Node, $VM_Type);

	my $Snapshot_Exists = &check_snapshot($Host, $Snapshot_Tag,  $VM_ID, $VM_Node, $VM_Type);
	if ($Snapshot_Exists) {
		my $Rollback_Snapshot = `$API/nodes/$VM_Node/$VM_Type/$VM_ID/snapshot/$Snapshot_Tag/rollback -X POST`;
		if ($?) {print "Error reverting to snapshot $Snapshot_Tag on VMID $VM_ID: Curl Error $?\n"; exit 21;}
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Rollback to tag ${Yellow}$Snapshot_Tag${Green} initiated for host ${Blue}$Host${Pink}.${Clear}\n";
		}
	}
	else {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Pink}The tag ${Yellow}$Snapshot_Tag${Pink} could not be found for host ${Blue}$Host${Pink}.${Clear}\n";
			exit(21);
		}
		else {
			print "The tag '$Snapshot_Tag' could not be found for host $Host.\n";
			exit(21);
		}
	}
} # sub revert_snapshot

sub check_snapshot {

	my ($Host, $Snapshot_Tag, $VM_ID, $VM_Node, $VM_Type) = @_;

	if (!$VM_ID || !$VM_Node || !$VM_Type) {return 1};

	&check_locks($Host, $VM_ID, $VM_Node, $VM_Type);

	if ($Verbose) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Checking for snapshots on ${Blue}$Host${Green} matching tag ${Yellow}$Snapshot_Tag${Green}.${Clear}\n";
	}

	my $Snapshot_Details = `$API/nodes/$VM_Node/$VM_Type/$VM_ID/snapshot`;
	if ($?) {print "Error checking snapshots for VMID $VM_ID: Curl Error $?\n"; exit 21;}

	my $Return = 0;
	if (!$Snapshot_Details || $Snapshot_Details !~ /"vmstate":/) {
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Blue}$Host${Green} has no snapshots.${Clear}\n";
		}
		return 0;
	}
	else {

		my @Snapshots = split '{', $Snapshot_Details;

		foreach (@Snapshots) {
			my $Snapshot_Name = $_;
				$Snapshot_Name =~ s/.*"name":"(.*?)".*/$1/g;
			my $Snapshot_Time = $_;
				$Snapshot_Time =~ s/.*"snaptime":(\d+),.*/$1/g;
				$Snapshot_Time = strftime '%Y/%m/%d %H:%M:%S', localtime $Snapshot_Time;
			my $Snapshot_Parent;
			if ($_ =~ /parent/) {
				$Snapshot_Parent = $_;
				$Snapshot_Parent =~ s/.*"parent":"(.*?)".*/$1/g;
			}
			if ($_ =~ /"snaptime":/ && $Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Found snapshot for ${Blue}$Host${Green}: ${Yellow}$Snapshot_Name${Green}.${Clear}\n";
			}
			if ($Snapshot_Name eq $Snapshot_Tag) {
				if ($Verbose) {
					my $Time_Stamp = strftime "%H:%M:%S", localtime;
					print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Blue}$Host${Green} has a snapshot matching tag ${Yellow}$Snapshot_Tag${Green}.${Clear}\n";
				}
				$Return = 1;
				last;
			}
		}
	}

	return $Return;

} # sub check_snapshot

sub check_locks {

	my $VM_Name = $_[0];
	my $VM_ID = $_[1];
	my $VM_Node = $_[2];
	my $VM_Type = $_[3];
	my $Was_Locked;

	sleep 5; # Allow Proxmox time to lock VM
	my $VM_Lock_Status = `$API/nodes/$VM_Node/$VM_Type/$VM_ID/config`;
	if ($?) {print "Error gathering lock details for VMID $VM_ID: Curl Error $?\n"; exit 21;}
		if ($VM_Lock_Status !~ '"lock":"') {undef $VM_Lock_Status}
		$VM_Lock_Status =~ s/.*"lock":"(.*?)".*/$1/;
	
	while ($VM_Lock_Status) {
		$Was_Locked = 1;
		sleep 5;
		$VM_Lock_Status = `$API/nodes/$VM_Node/$VM_Type/$VM_ID/config`;
		if ($?) {print "Error gathering lock details for VMID $VM_ID: Curl Error $?\n"; exit 21;}
			if ($VM_Lock_Status !~ '"lock":"') {undef $VM_Lock_Status}
			$VM_Lock_Status =~ s/.*"lock":"(.*?)".*/$1/;
		if ($Verbose && $VM_Lock_Status) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}VM ${Blue}$VM_Name${Yellow} is currently locked. Status is: ${Pink}$VM_Lock_Status${Yellow}.${Clear}\n";
		}
	}

	if ($Verbose && $Was_Locked) {
		my $Time_Stamp = strftime "%H:%M:%S", localtime;
		print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}VM lock for ${Blue}$VM_Name${Green} has released.${Clear}\n";
	}

} # sub check_locks

sub cluster_details {

	my $VM_Name = $_[0];

	my ($VM_ID, $VM_Node, $VM_Type);
	my $Cluster_Details = `$API/cluster/resources`;
	if ($Very_Verbose) {print "Cluser Details:\n$Cluster_Details\n"}
	if ($?) {print "Error gathering cluster details (Credentials correct?): Curl Error $?\n"; exit 21;}

	if ($Cluster_Details =~ /"name":"$VM_Name"/) {
		$Cluster_Details =~ s/.*{(.*$VM_Name.*?)}.*/$1/;
		$VM_ID = $Cluster_Details;
		$VM_ID =~ s/.*"vmid":"?(\d+)"?,?.*/$1/; 
		$VM_Node = $Cluster_Details;
		$VM_Node =~ s/.*"node":"(.*?)".*/$1/;
		$VM_Type = $Cluster_Details;
		$VM_Type =~ s/.*"type":"(.*?)".*/$1/;	
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Details for ${Blue}$VM_Name${Green}:\n\t${Blue}VMID: ${Yellow}$VM_ID\n\t${Blue}VM Node: ${Yellow}$VM_Node\n\t${Blue}VM Type: ${Yellow}$VM_Type${Clear}\n";
		}
		return($VM_ID, $VM_Node, $VM_Type);
	}
	else {
		print "Error: $VM_Name not found on any online node.\n";
		exit(21);
	}
} # sub cluster_details

exit($Final_Exit_Code);
