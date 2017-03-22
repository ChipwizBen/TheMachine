#!/usr/bin/perl -T

use strict;
use Net::IP::XS qw($IP_NO_OVERLAP
                   $IP_PARTIAL_OVERLAP
                   $IP_A_IN_B_OVERLAP
                   $IP_B_IN_A_OVERLAP
                   $IP_IDENTICAL);
use Net::Ping::External qw(ping);
use Parallel::ForkManager;
use POSIX qw(strftime);
use Getopt::Long qw(:config no_ignore_case);

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $DB_Connection = DB_Connection();
my $DNS_Server = DNS_Server();
my $System_Name = System_Name();
my $Version = Version();

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
	${Blue}-t, --threads\t\t${Green}Sets the number of threads to use for sweeping. Default is 256.
	${Blue}-b, --block-ids\t\t${Green}A list of block IDs to sweep, comma or space seperated.
	${Blue}-v, --verbose\t\t${Green}Turns on verbose output (useful for debug).

${Green}Examples:
	${Green}## Sweep block IDs 4, 12 and 6
	${Blue}$0 -b 4 12 6

	${Green}## Sweep all blocks with verbose output on, limit to 20 threads
	${Blue}$0 -v -t 20${Clear}\n\n";


if (!@ARGV) {
	print $Help;
	exit(0);
}

my @Block_IDs;
my $Threads;
my $Verbose;

GetOptions(
	't:i' => \$Threads,
	'threads:i' => \$Threads,
	'b:s{1,}' => \@Block_IDs, # Set as string due to possibility of space seperation
	'block-ids:s{1,}' => \@Block_IDs, # Set as string due to possibility of space seperation
	'v' => \$Verbose,
	'verbose' => \$Verbose,
) or die("Fault with options: $@\n");


if (!$Threads) {$Threads = 256}
if ($Verbose) {
	my $Time_Stamp = strftime "%H:%M:%S", localtime;
	print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Verbose mode on.${Clear}\n";
	print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Threads set to $Threads.${Clear}\n";
}

my @IPv4_Block_Query_Output;
if (@Block_IDs) {
	foreach my $Block_ID (@Block_IDs) {
		my $IPv4_Block_Query = $DB_Connection->prepare("SELECT `id`, `ip_block_name`, `ip_block`
		FROM `ipv4_blocks`
		ORDER BY `ip_block_name`
		WHERE `id` = ?");
		$IPv4_Block_Query->execute($Block_ID);
		push @IPv4_Block_Query_Output, $IPv4_Block_Query->fetchrow_array();
	}
}
else {
	my $IPv4_Block_Query = $DB_Connection->prepare("SELECT `id`, `ip_block_name`, `ip_block`
	FROM `ipv4_blocks`
	ORDER BY `ip_block_name`");
	$IPv4_Block_Query->execute();
	@IPv4_Block_Query_Output = $IPv4_Block_Query->fetchrow_array();
}


while (@IPv4_Block_Query_Output) {
	my $Parent_Block_ID = $IPv4_Block_Query_Output[0];
	my $Parent_Block_Name = $IPv4_Block_Query_Output[1];
	my $Parent_Block_IP = $IPv4_Block_Query_Output[2];

	my $IP_Ping_Sweep = new Net::IP::XS ($Parent_Block_IP);

	my $Range_Min = $IP_Ping_Sweep->ip();
	my $Range_Max = $IP_Ping_Sweep->last_ip();

	print "\n----------\n";
	print "Checking $Parent_Block_Name ($Parent_Block_IP) [ID: $Parent_Block_ID]. RangeMin: $Range_Min RangeMax: $Range_Max\n\n";

	my @IPs_To_Ping;
	do {
		my $IP_To_Ping = $IP_Ping_Sweep->ip();
		push @IPs_To_Ping, $IP_To_Ping;
	} while (++$IP_Ping_Sweep);

	my $Ping_Fork = new Parallel::ForkManager($Threads);

	foreach my $IP_To_Ping (@IPs_To_Ping) {

		my $PID = $Ping_Fork->start and next;

		my $Ping_Result = ping(
			host => $IP_To_Ping,
			timeout => 2
		);

		#print "Checking $IP_To_Ping...\n";

		if (($Ping_Result) && ($IP_To_Ping ne $Range_Min) && ($IP_To_Ping ne $Range_Max)) {
			if ($Verbose) {
				my $Time_Stamp = strftime "%H:%M:%S", localtime;
				print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Got a response from ${Blue}$IP_To_Ping${Green}.${Clear}\n";
			}
			$DB_Connection = DB_Connection();
			my $DB_Check = $DB_Connection->prepare("SELECT `id`
				FROM `ipv4_assignments`
				WHERE `ip_block` = ?");
			$DB_Check->execute("$IP_To_Ping/32");
			my $Assignment_ID = $DB_Check->fetchrow_array();
			my $Rows = $DB_Check->rows();

			if ($Rows == 0) {

				my ($Overlap_Notice) = &overlap_check("$IP_To_Ping/32", $Parent_Block_ID);

				if ($Overlap_Notice) {
					print "$Overlap_Notice";
				}
				else {
					my $Host_Name_Resolution = &dns_lookup($IP_To_Ping);
					my $DHCP = &dhcp_lookup($Host_Name_Resolution);
					if ($DHCP) {
						if ($Verbose) {
							my $Time_Stamp = strftime "%H:%M:%S", localtime;
							print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Host ${Yellow}$Host_Name_Resolution${Green} has IP ${Blue}$IP_To_Ping${Green} but is registered as DHCP. Ignoring response.${Clear}\n";
						}
					}
					else {
						my $Block_Insert_ID = &block_insert($IP_To_Ping, $Parent_Block_IP);
						&host_insert($Block_Insert_ID, $Host_Name_Resolution);
					}
				}
			}
			else {
				my $Host_Name_Resolution = &dns_lookup($IP_To_Ping);
				my $DHCP = &dhcp_lookup($Host_Name_Resolution);
				if ($DHCP) {

					my $Delete_Block = $DB_Connection->prepare("DELETE from `ipv4_assignments`
						WHERE `id` = ?");
					$Delete_Block->execute($Assignment_ID);

					my $Delete_Associations = $DB_Connection->prepare("DELETE from `lnk_hosts_to_ipv4_assignments`
						WHERE `ip` = ?");
					$Delete_Associations->execute($Assignment_ID);

					if ($Verbose) {
						my $Time_Stamp = strftime "%H:%M:%S", localtime;
						print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Deleted ${Blue}$IP_To_Ping${Green} becuase ${Yellow}$Host_Name_Resolution${Green} is listed as a DHCP host.${Clear}\n";
					}
					my $Audit_Log_Submission = Audit_Log_Submission();
					$Audit_Log_Submission->execute("IP", "Delete", "System deleted $IP_To_Ping (ID: $Assignment_ID) because $Host_Name_Resolution is listed as a DHCP host.", 'System');
				}
				else {

					my $Changed_Assignment_Check_Link = $DB_Connection->prepare("SELECT `host`
					FROM `lnk_hosts_to_ipv4_assignments`
					WHERE `ip` = ?");
					$Changed_Assignment_Check_Link->execute($Assignment_ID);
					my $Existing_Database_Host_ID = $Changed_Assignment_Check_Link->fetchrow_array();

					my $Changed_Assignment_Check_Hostname = $DB_Connection->prepare("SELECT `hostname`
					FROM `hosts`
					WHERE `id` = ?");
					$Changed_Assignment_Check_Hostname->execute($Existing_Database_Host_ID);
					my $Existing_Database_Host = $Changed_Assignment_Check_Hostname->fetchrow_array();

					if ($Existing_Database_Host ne $Host_Name_Resolution) {

						my $Delete_Old_Associations = $DB_Connection->prepare("DELETE from `lnk_hosts_to_ipv4_assignments`
						WHERE `ip` = ?");
						$Delete_Old_Associations->execute($Assignment_ID);

						if ($Verbose) {
							my $Time_Stamp = strftime "%H:%M:%S", localtime;
							print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Green}Changed the association of ${Blue}$IP_To_Ping${Green} from ${Yellow}$Existing_Database_Host${Green} to ${Yellow}$Host_Name_Resolution${Green}.${Clear}\n";
						}
						my $Audit_Log_Submission = Audit_Log_Submission();
						$Audit_Log_Submission->execute("IP", "Modify", "System changed the association of $IP_To_Ping from $Existing_Database_Host to $Host_Name_Resolution.", 'System');


					}
				}
			}
		}
    	$Ping_Fork->finish;
	}
	$Ping_Fork->wait_all_children;
}


sub block_insert {

	my ($Block, $Parent) = @_;

	my $Block_Insert = $DB_Connection->prepare("INSERT INTO `ipv4_assignments` (
		`ip_block`,
		`parent_block`,
		`modified_by`
	)
	VALUES (
		?, ?, ?
	)");

	$Block_Insert->execute("$Block/32", $Parent, "System");
	my $Block_Insert_ID = $DB_Connection->{mysql_insertid};

	# Audit Log
	my $Audit_Log_Submission = Audit_Log_Submission();
	
	$Audit_Log_Submission->execute("IP", "Add", "$Block was found and was previously unregistered. It is assumed to be a /32. The system assigned it Block ID $Block_Insert_ID.", 'System');

	return $Block_Insert_ID;

} # sub block_insert

sub host_insert {

	my ($Block_Insert_ID, $Host_Name_Resolution) = @_;

	my $Host_Exists_Check = $DB_Connection->prepare("SELECT `id`
		FROM `hosts`
		WHERE `hostname` = ?");
	$Host_Exists_Check->execute($Host_Name_Resolution);
	my $Host_Rows = $Host_Exists_Check->rows();

	if ($Host_Rows > 0)	{

		my $Host_ID = $Host_Exists_Check->fetchrow_array();
		my $Host_Link_Insert = $DB_Connection->prepare("INSERT INTO `lnk_hosts_to_ipv4_assignments` (
			`host`,
			`ip`
		)
		VALUES (
			?, ?
		)");
		
		$Host_Link_Insert->execute($Host_ID, $Block_Insert_ID);

		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Blue}$IP_To_Ping/32${Green} was attached to ${Yellow}$Host_Name_Resolution${Green}.${Clear}\n";
		}
		my $Audit_Log_Submission = Audit_Log_Submission();
		$Audit_Log_Submission->execute("IP", "Modify", "$IP_To_Ping/32 was attached to $Host_Name_Resolution.", 'System');

		print "Adding $Host_Name_Resolution ($IP_To_Ping), BID: $Block_Insert_ID HID: $Host_ID\n";

	}
	elsif ($Host_Name_Resolution) {

		my $Host_Insert = $DB_Connection->prepare("INSERT INTO `hosts` (
			`hostname`,
			`modified_by`
		)
		VALUES (
			?, ?
		)");
	
		$Host_Insert->execute($Host_Name_Resolution, "System");
	
		my $Host_Insert_ID = $DB_Connection->{mysql_insertid};

		my $Host_Link_Insert = $DB_Connection->prepare("INSERT INTO `lnk_hosts_to_ipv4_assignments` (
			`host`,
			`ip`
		)
		VALUES (
			?, ?
		)");
		
		$Host_Link_Insert->execute($Host_Insert_ID, $Block_Insert_ID);
		if ($Verbose) {
			my $Time_Stamp = strftime "%H:%M:%S", localtime;
			print "${Red}## Verbose (PID:$$) $Time_Stamp ## ${Yellow}$Host_Name_Resolution${Green} (ID: ${Pink}$Host_Insert_ID${Green}) was added and attached to ${Blue}$IP_To_Ping/32${Green}.${Clear}\n";
		}
		my $Audit_Log_Submission = Audit_Log_Submission();
		$Audit_Log_Submission->execute("Hosts", "Add", "$Host_Name_Resolution (ID: $Host_Insert_ID) was added and attached to $IP_To_Ping/32.", 'System');

		print "Adding $Host_Name_Resolution ($IP_To_Ping), BID: $Block_Insert_ID HID: $Host_Insert_ID\n";

	}

} # sub host_insert

sub dns_lookup {

	my $IP_To_Ping = $_[0];
	my $Host_Name_Resolution = `nslookup $IP_To_Ping $DNS_Server \| grep -v nameserver \| cut -f 2 \| grep name \| cut -f 2 -d '=' \| sed 's/ //' \| sed 's/\.\$//'`;
		$Host_Name_Resolution =~ s/\n.*//;
		$Host_Name_Resolution =~ s/\r.*//;
	return $Host_Name_Resolution;

} # sub dns_lookup

sub dhcp_lookup {

	my $Host = $_[0];

		my $Host_ID_Check = $DB_Connection->prepare("SELECT `id`
			FROM `hosts`
			WHERE `hostname` = ?");
		$Host_ID_Check->execute($Host);
		my $Host_ID = $Host_ID_Check->fetchrow_array();
	
		my $Host_DHCP_Check = $DB_Connection->prepare("SELECT `dhcp`
			FROM `host_attributes`
			WHERE `id` = ?");
		$Host_DHCP_Check->execute($Host_ID);
		my $Host_DHCP = $Host_ID_Check->fetchrow_array();

	return $Host_DHCP;

} # sub dhcp_lookup

sub overlap_check {

	my ($Block_to_Check, $Parent_Block_ID) = @_;
	
	my $Rows = 1;
	my $Counter = 0;
	LOOP: while ($Counter != $Rows) {

		my $IP_Block_Check_Cycle = $DB_Connection->prepare("SELECT `ip_block`
			FROM `ipv4_assignments`
			WHERE `parent_block` = ?
			ORDER BY `ip_block` ASC");
		$IP_Block_Check_Cycle->execute($Parent_Block_ID);
		$Rows = $IP_Block_Check_Cycle->rows();

		while ( my $Existing_Block_for_Overlap_Check = $IP_Block_Check_Cycle->fetchrow_array() )
		{

			my $IP_Assignment = new Net::IP::XS($Block_to_Check) or die("Problem with $Block_to_Check");
			my $IP_Assignment_Check = new Net::IP::XS($Existing_Block_for_Overlap_Check) or die("Problem with $Existing_Block_for_Overlap_Check");

			my $Overlap_Check = $IP_Assignment->overlaps($IP_Assignment_Check);

			if (not defined($Overlap_Check))
			{
				return "Problem with IP range $Overlap_Check - it is not properly defined.\n";
			}
			elsif ( $Overlap_Check == $IP_IDENTICAL )
			{
				return "IPs are identical.\n";
			}
			elsif ( $Overlap_Check == $IP_A_IN_B_OVERLAP )
			{
				return "$Block_to_Check is inside $Existing_Block_for_Overlap_Check.\n";
			}
			elsif ( $Overlap_Check == $IP_B_IN_A_OVERLAP )
			{
				return "$Existing_Block_for_Overlap_Check is inside $Block_to_Check.\n";
			}
			elsif ( $Overlap_Check == $IP_PARTIAL_OVERLAP )
			{
				return "$Block_to_Check partially overlaps $Existing_Block_for_Overlap_Check.\n";
			}
			elsif ( $Overlap_Check == $IP_NO_OVERLAP )
			{
				$Counter++;
			}
		}
	};

	return 0;

} # sub overlap_check
