#!/usr/bin/perl

use strict;
use Net::IP;
use Net::Ping::External qw(ping);
use Parallel::ForkManager;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $DB_Connection = DB_Connection();
my $DNS_Server = DNS_Server();
my $Fork_Count = 256;

my $IPv4_Block_Query = $DB_Connection->prepare("SELECT `id`, `ip_block_name`, `ip_block`
FROM `ipv4_blocks`
ORDER BY `ip_block_name`");

$IPv4_Block_Query->execute();

while ( my @IPv4_Block_Query_Output = $IPv4_Block_Query->fetchrow_array() )
{
	my $ID = $IPv4_Block_Query_Output[0];
	my $Block_Name = $IPv4_Block_Query_Output[1];
	my $Block_IP = $IPv4_Block_Query_Output[2];

	my $IP_Ping_Sweep = new Net::IP ($Block_IP);
	
	my $Range_Min = $IP_Ping_Sweep->ip();
	my $Range_Max = $IP_Ping_Sweep->last_ip();

	print "\n----------\n";
	print "Checking $Block_Name ($Block_IP). RMin: $Range_Min RMax: $Range_Max\n\n";

	my @IPs_To_Ping;
	do {
		my $IP_To_Ping = $IP_Ping_Sweep->ip();
		push @IPs_To_Ping, $IP_To_Ping;
	} while (++$IP_Ping_Sweep);

	my $Ping_Fork = new Parallel::ForkManager($Fork_Count);

	foreach my $IP_To_Ping (@IPs_To_Ping) {

		my $PID = $Ping_Fork->start and next;

		my $Ping_Result = ping(
			host => $IP_To_Ping,
			timeout => 2
		);

		#print "Checking $IP_To_Ping...\r";

		if (($Ping_Result) && ($IP_To_Ping ne $Range_Min) && ($IP_To_Ping ne $Range_Max)) {
			print "Got a response from $IP_To_Ping...\n";
			$DB_Connection = DB_Connection();
			my $DB_Check = $DB_Connection->prepare("SELECT `id`
				FROM `ipv4_allocations`
				WHERE `ip_block` = ?");
			$DB_Check->execute("$IP_To_Ping/32");
			my $Rows = $DB_Check->rows();

			if ($Rows == 0) {

				my $Block_Insert = $DB_Connection->prepare("INSERT INTO `ipv4_allocations` (
					`ip_block`,
					`parent_block`,
					`modified_by`
				)
				VALUES (
					?, ?, ?
				)");

				$Block_Insert->execute("$IP_To_Ping/32", $Block_IP, "System");

				my $Block_Insert_ID = $DB_Connection->{mysql_insertid};

				my $Host_Name_Resolution = `nslookup $IP_To_Ping $DNS_Server \| grep -v nameserver \| cut -f 2 \| grep name \| cut -f 2 -d '=' \| sed 's/ //' \| sed 's/\.\$//'`;
					$Host_Name_Resolution =~ s/\n.*//;
					$Host_Name_Resolution =~ s/\r.*//;

				my $Host_Rows;
				if ($Host_Name_Resolution) {

					my $Host_Exists_Check = $DB_Connection->prepare("SELECT `id`
						FROM `hosts`
						WHERE `hostname` = ?");
					$Host_Exists_Check->execute($Host_Name_Resolution);
					$Host_Rows = $Host_Exists_Check->rows();

					if ($Host_Rows > 0)	{

						my $Host_ID = $Host_Exists_Check->fetchrow_array();
						my $Host_Link_Insert = $DB_Connection->prepare("INSERT INTO `lnk_hosts_to_ipv4_allocations` (
							`host`,
							`ip`
						)
						VALUES (
							?, ?
						)");
						
						$Host_Link_Insert->execute($Host_ID, $Block_Insert_ID);
		
						print "Adding $Host_Name_Resolution ($IP_To_Ping), BID: $Block_Insert_ID HID: $Host_ID\n";

					}
					else {

						my $Host_Insert = $DB_Connection->prepare("INSERT INTO `hosts` (
							`hostname`,
							`modified_by`
						)
						VALUES (
							?, ?
						)");
					
						$Host_Insert->execute($Host_Name_Resolution, "System");
					
						my $Host_Insert_ID = $DB_Connection->{mysql_insertid};
		
						my $Host_Link_Insert = $DB_Connection->prepare("INSERT INTO `lnk_hosts_to_ipv4_allocations` (
							`host`,
							`ip`
						)
						VALUES (
							?, ?
						)");
						
						$Host_Link_Insert->execute($Host_Insert_ID, $Block_Insert_ID);
		
						print "Adding $Host_Name_Resolution ($IP_To_Ping), BID: $Block_Insert_ID HID: $Host_Insert_ID\n";

					}
				}
				else {
					print "Could not resolve $IP_To_Ping to a hostname.\n";
				}

				# Audit Log
				my $DB_Connection = DB_Connection();
				my $Audit_Log_Submission = $DB_Connection->prepare("INSERT INTO `audit_log` (
					`category`,
					`method`,
					`action`,
					`username`
				)
				VALUES (
					?, ?, ?, ?
				)");

				$Audit_Log_Submission->execute("IP", "Add", "$IP_To_Ping was found in 
				$Block_Name - $Block_IP (Block ID $ID) that was previously unregistered. It is assumed to be a /32. 
				The system assigned it Block ID $Block_Insert_ID.", 'System');

				if ($Host_Name_Resolution ne undef) {
					if ($Host_Rows > 0)	{
						$Audit_Log_Submission->execute("IP", "Modify", "$IP_To_Ping/32 has been attached to 
						$Host_Name_Resolution.", 'System');
					}
					else {
						$Audit_Log_Submission->execute("Hosts", "Add", "$Host_Name_Resolution was added and attached to 
						$IP_To_Ping/32.", 'System');
					}
				}


				# / Audit Log

			}
			else {
				print "Nope, already got $IP_To_Ping.\n";
			}
		}
    	$Ping_Fork->finish;
	}
	$Ping_Fork->wait_all_children;
}
