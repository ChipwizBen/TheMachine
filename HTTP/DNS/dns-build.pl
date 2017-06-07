#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);

use POSIX qw(strftime);

require '../common.pl';
my $DB_Connection = DB_Connection();
my $DNS_Internal_Location = DNS_Internal_Location();
my $DNS_External_Location = DNS_External_Location();
my $DNS_Storage = DNS_Storage();
my $System_Name = System_Name();
my $Version = Version();
my $md5sum = md5sum();
my $cut = cut();
my $cp = cp();
my $grep = sudo_grep();
my $head = head();
my $Owner = DNS_Owner_ID();
my $Group = DNS_Group_ID();

my $Date = strftime "%Y-%m-%d", localtime;

$| = 1;
my $Override;

foreach my $Parameter (@ARGV) {
	if ($Parameter eq '--override') {$Override = 1}
	if ($Parameter eq '-h' || $Parameter eq '--help') {
		print "\nOptions are:\n\t--override\tOverrides any database lock\n\n";
		exit(0);
	}
}

# Safety check for other running build processes

	my $Select_Locks = $DB_Connection->prepare("SELECT `dns-build` FROM `lock`");
	$Select_Locks->execute();

	my ($DNS_Build_Lock, $DNS_Distribution_Lock) = $Select_Locks->fetchrow_array();

		if ($DNS_Build_Lock == 1 || $DNS_Distribution_Lock == 1) {
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
				`dns-build` = '1',
				`last-dns-build-started` = NOW()");
		}

# / Safety check for other running build processes

&write_zone_master;

$DB_Connection->do("UPDATE `lock` SET 
`dns-build` = '0',
`last-dns-build-finished` = NOW()");
exit(0);


sub write_zone_master {

	my $DNS_Zone_Master_File = DNS_Zone_Master_File();
	open( Zone_Master, ">$DNS_Zone_Master_File" ) or die "Can't open $DNS_Zone_Master_File";

	print Zone_Master "/////////////////////////////////////////////////////////////////////////\n";
	print Zone_Master "// $System_Name\n";
	print Zone_Master "// Version: $Version\n";
	print Zone_Master "// AUTO GENERATED SCRIPT\n";
	print Zone_Master "// Please do not edit by hand\n";
	print Zone_Master "// This file is part of a wider system and is automatically overwritten often\n";
	print Zone_Master "// View the changelog or README files for more information.\n";
	print Zone_Master "/////////////////////////////////////////////////////////////////////////\n\n";

	my $Domain_Query = $DB_Connection->prepare("SELECT `id`, `domain`, `last_modified`, `modified_by`
	FROM `domains`");
	$Domain_Query->execute( );

	while ( my ($Domain_ID, $Domain, $Last_Modified, $Modified_By) = $Domain_Query->fetchrow_array() )
	{

		# Internal Zone
		my $Internal_Record_Query = $DB_Connection->prepare("SELECT COUNT(`id`)
		FROM `zone_records`
		WHERE `domain` = ?
		AND (`zone` = 0
			OR `zone` = 2)
		ORDER BY `target` ASC");
		$Internal_Record_Query->execute($Domain_ID);
		
		my $Internal_Count = $Internal_Record_Query->fetchrow_array();
		
		if ($Internal_Count > 0) {
			print Zone_Master <<EOF;
// Domain ID $Domain_ID, Last modified $Last_Modified by $Modified_By
    zone "$Domain" {
        type master;
        notify yes;
        file "$DNS_Internal_Location/$Domain-int";
    }; \n\n 
EOF
			&write_internal ($Domain_ID, $Domain);
		}

		#External Zone
		my $External_Record_Query = $DB_Connection->prepare("SELECT COUNT(`id`)
		FROM `zone_records`
		WHERE `domain` = ?
		AND (`zone` = 1
			OR `zone` = 2)
		ORDER BY `target` ASC");
		$External_Record_Query->execute($Domain_ID);

		my $External_Count = $External_Record_Query->fetchrow_array();

		if ($External_Count > 0) {
			print Zone_Master <<EOF;
// Domain ID $Domain_ID, Last modified $Last_Modified by $Modified_By
    zone "$Domain" {
        type master;
        notify yes;
        file "$DNS_Internal_Location/$Domain-ext";
        allow-query { any; };
    }; \n\n
EOF
			&write_external ($Domain_ID, $Domain);
		}
	}
close Zone_Master;

} # sub write_zone_master

sub write_internal {

	my ($Domain_ID, $Domain) = @_;

	my $DNS_Internal_SOA = DNS_Internal_SOA();
		my $Domain_SOA = $DNS_Internal_SOA;
			$Domain_SOA =~ s/\<DOMAIN\>/$Domain/g;
	
		open( Domain_Config, ">$DNS_Internal_Location/$Domain-int" ) or die "Can't open $DNS_Internal_Location/$Domain-int";
	
		print Domain_Config ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n";
		print Domain_Config ";; $System_Name\n";
		print Domain_Config ";; Version: $Version\n";
		print Domain_Config ";; AUTO GENERATED SCRIPT\n";
		print Domain_Config ";; Please do not edit by hand\n";
		print Domain_Config ";; This file is part of a wider system and is automatically overwritten often\n";
		print Domain_Config ";; View the changelog or README files for more information.\n";
		print Domain_Config ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n";
		print Domain_Config "\n\n";

		print Domain_Config ";;; This file is for $Domain internal records ;;;\n\n";
		print Domain_Config "$Domain_SOA\n";

		my $Record_Query = $DB_Connection->prepare("SELECT `id`, `source`, `time_to_live`, `type`, `options`, `target`, `last_modified`, `modified_by`
		FROM `zone_records`
		WHERE `domain` = ?
		AND `active` = '1'
		AND (`expires` >= '$Date'
			OR `expires` = '0000-00-00')
		AND (`zone` = '0'
			OR `zone` = '2')
		ORDER BY `target` ASC");
		$Record_Query->execute($Domain_ID);

		while ( my ($Record_ID, $Source, $TTL, $Type, $Options, $Target, $Last_Modified, $Modified_By) = $Record_Query->fetchrow_array() )
		{
			
			if ($TTL <= 0) {$TTL = '86400'}
			print Domain_Config "$Source	$TTL	IN	$Type	$Options	$Target		; Record ID: $Record_ID. Last modified $Last_Modified by $Modified_By.\n"
		
		}

	print Domain_Config "\n";
	close Domain_Config;

#nsupdate << EOF
#server $Server
#update delete $Hostname A
#update add $Hostname 86400 A $IP
#send
#EOF


} # sub write_internal

sub write_external {

	my ($Domain_ID, $Domain) = @_;

	my $DNS_External_SOA = DNS_External_SOA();
		my $Domain_SOA = $DNS_External_SOA;
			$Domain_SOA =~ s/\<DOMAIN\>/$Domain/g;
	
		open( Domain_Config, ">$DNS_External_Location/$Domain-ext" ) or die "Can't open $DNS_External_Location/$Domain-ext";
	
		print Domain_Config ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n";
		print Domain_Config ";; $System_Name\n";
		print Domain_Config ";; Version: $Version\n";
		print Domain_Config ";; AUTO GENERATED SCRIPT\n";
		print Domain_Config ";; Please do not edit by hand\n";
		print Domain_Config ";; This file is part of a wider system and is automatically overwritten often\n";
		print Domain_Config ";; View the changelog or README files for more information.\n";
		print Domain_Config ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n";
		print Domain_Config "\n\n";

		print Domain_Config ";;; This file is for $Domain external records ;;;\n\n";
		print Domain_Config "$Domain_SOA\n";

		my $Record_Query = $DB_Connection->prepare("SELECT `id`, `source`, `time_to_live`, `type`, `options`, `target`, `last_modified`, `modified_by`
		FROM `zone_records`
		WHERE `domain` = ?
		AND `active` = '1'
		AND (`expires` >= '$Date'
			OR `expires` = '0000-00-00')
		AND (`zone` = '1'
			OR `zone` = '2')
		ORDER BY `target` ASC");
		$Record_Query->execute($Domain_ID);

		while ( my ($Record_ID, $Source, $TTL, $Type, $Options, $Target, $Last_Modified, $Modified_By) = $Record_Query->fetchrow_array() )
		{
			
			if ($TTL <= 0) {$TTL = '86400'}
			print Domain_Config "$Source	$TTL	IN	$Type	$Options	$Target		; Record ID: $Record_ID. Last modified $Last_Modified by $Modified_By.\n"
		
		}

	print Domain_Config "\n";
	close Domain_Config;
	
} # sub write_external

