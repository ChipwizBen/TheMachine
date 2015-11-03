#!/usr/bin/perl

use strict;
use POSIX qw(strftime);

require '../common.pl';
my $DB_Management = DB_Management();
my $DB_DNS = DB_DNS();
my $DNS_Internal_Location = DNS_Internal_Location();
my $DNS_External_Location = DNS_External_Location();
my $DNS_Storage = DNS_Storage();
my $System_Name = System_Name();
my $Version = Version();
my $md5sum = md5sum();
my $cut = cut();
my $cp = cp();
my $ls = ls();
my $grep = sudo_grep();
my $head = head();
my $Owner = Owner_ID();
my $Group = Group_ID();

my $Date = strftime "%Y-%m-%d", localtime;

# Safety check for other running build processes

	my $Select_Locks = $DB_Management->prepare("SELECT `dns-build` FROM `lock`");
	$Select_Locks->execute();

	my ($DNS_Build_Lock, $DNS_Distribution_Lock) = $Select_Locks->fetchrow_array();

		if ($DNS_Build_Lock == 1 || $DNS_Distribution_Lock == 1) {
			print "Another build or distribution process is running. Exiting...\n";
			exit(1);
		}
		else {
			$DB_Management->do("UPDATE `lock` SET
				`dns-build` = '1',
				`last-dns-build-started` = NOW()");
		}

# / Safety check for other running build processes

&write_internal;
&write_external;


my $DNS_Check = ` -c -f $DNS_Internal_Location`;

if ($DNS_Check =~ m/$DNS_Internal_Location:\sparsed\sOK/) {
	$DNS_Check = "DNS check passed!\n";
	$DB_Management->do("UPDATE `lock` SET 
	`dns-build` = '0',
	`last-dns-build-finished` = NOW()");
	&record_audit('PASSED');
	print $DNS_Check;
	exit(0);
}
else {
	$DNS_Check = "DNS check failed, no changes made. Latest working sudoers file restored.\n";
	$DB_Management->do("UPDATE `lock` SET 
	`dns-build` = '2',
	`last-dns-build-finished` = NOW()");
	&record_audit('FAILED');
	print $DNS_Check;
	exit(1);
}

sub write_internal {

	my $DNS_Internal_SOA = DNS_Internal_SOA();
	my $DNS_Zone_Master_File = DNS_Zone_Master_File();

	open( Zone_Master, ">$DNS_Zone_Master_File" ) or die "Can't open $DNS_Zone_Master_File";
		print Zone_Master "/////////////////////////////////////////////////////////////////////////\n";
		print Zone_Master "// $System_Name\n";
		print Zone_Master "// Version: $Version\n";
		print Zone_Master "// AUTO GENERATED SCRIPT\n";
		print Zone_Master "// Please do not edit by hand\n";
		print Zone_Master "// This file is part of a wider system and is automatically overwritten often\n";
		print Zone_Master "// View the changelog or README files for more information.\n";
		print Zone_Master "/////////////////////////////////////////////////////////////////////////\n";

	my $Domain_Query = $DB_DNS->prepare("SELECT `id`, `domain`
	FROM `domains`");
	$Domain_Query->execute( );

	while ( (my $Domain_ID, my $Domain)  = $Domain_Query->fetchrow_array() )
	{

		# Write domain to zone master
		print Zone_Master <<EOF;
        zone "$Domain" {
                type master;
                notify yes;
                file "$DNS_Internal_Location/$Domain-int";
        };

EOF
		

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

		my $Record_Query = $DB_DNS->prepare("SELECT `id`, `source`, `time_to_live`, `type`, `options`, `target`, `last_modified`, `modified_by`
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
	}

	print Domain_Config "\n";
	close Domain_Config;

	close Zone_Master;

} # sub write_internal

sub write_external {

	my $DNS_External_SOA = DNS_External_SOA();
	my $DNS_Zone_Master_File = DNS_Zone_Master_File();

	open( Zone_Master, ">$DNS_Zone_Master_File" ) or die "Can't open $DNS_Zone_Master_File";
		print Zone_Master "/////////////////////////////////////////////////////////////////////////\n";
		print Zone_Master "// $System_Name\n";
		print Zone_Master "// Version: $Version\n";
		print Zone_Master "// AUTO GENERATED SCRIPT\n";
		print Zone_Master "// Please do not edit by hand\n";
		print Zone_Master "// This file is part of a wider system and is automatically overwritten often\n";
		print Zone_Master "// View the changelog or README files for more information.\n";
		print Zone_Master "/////////////////////////////////////////////////////////////////////////\n";

	my $Domain_Query = $DB_DNS->prepare("SELECT `id`, `domain`
	FROM `domains`");
	$Domain_Query->execute( );

	while ( (my $Domain_ID, my $Domain)  = $Domain_Query->fetchrow_array() )
	{

		# Write domain to zone master
		print Zone_Master <<EOF;
        zone "$Domain" {
                type master;
                notify yes;
                file "$DNS_External_Location/$Domain-int";
        };

EOF
		

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

		my $Record_Query = $DB_DNS->prepare("SELECT `id`, `source`, `time_to_live`, `type`, `options`, `target`, `last_modified`, `modified_by`
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
	}

	print Domain_Config "\n";
	close Domain_Config;

	close Zone_Master;
	
} # sub write_external

sub record_audit {

	my $Result = $_[0];

	my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");

	my $MD5_New_Checksum = `$md5sum $DNS_Internal_Location | $cut -d ' ' -f 1`;
		$MD5_New_Checksum =~ s/\s//g;
	my $MD5_Existing_DNS = `$md5sum $DNS_Storage/sudoers_$MD5_New_Checksum | $cut -d ' ' -f 1`;
		$MD5_Existing_DNS =~ s/\s//g;

	if ($Result eq 'PASSED' && $MD5_New_Checksum ne $MD5_Existing_DNS) {
		my $New_DNS_Internal_Location = "$DNS_Storage/sudoers_$MD5_New_Checksum";
		`$cp -dp $DNS_Internal_Location $New_DNS_Internal_Location`; # Backing up sudoers
		chown $Owner, $Group, $New_DNS_Internal_Location;
		chmod 0640, $New_DNS_Internal_Location;
		$MD5_New_Checksum = "MD5: " . $MD5_New_Checksum;
		$Audit_Log_Submission->execute("DNS", "Deployment Succeeded", "Configuration changes were detected and a new sudoers file was built, passed visudo validation, and MD5 checksums as follows: $MD5_New_Checksum. A copy of this sudoers has been stored at '$New_DNS_Internal_Location' for future reference.", 'System');
	}
	elsif ($Result eq 'FAILED') {
		my $Latest_Good_DNS = `$ls -t $DNS_Storage | $grep 'sudoers_' | $head -1`;
			$Latest_Good_DNS =~ s/\n//;
		my $Latest_Good_DNS_MD5 = `$md5sum $DNS_Storage/$Latest_Good_DNS | $cut -d ' ' -f 1`;
			$Latest_Good_DNS_MD5 =~ s/\s//;
		my $Check_For_Existing_Bad_DNS = `$ls -t $DNS_Storage/broken_$MD5_New_Checksum`;
		if (!$Check_For_Existing_Bad_DNS) {
			$Audit_Log_Submission->execute("DNS", "Deployment Failed", "Configuration changes were detected and a new sudoers file was built, but failed visudo validation. Deployment aborted, latest valid sudoers (MD5: $Latest_Good_DNS_MD5) has been restored. The broken sudoers file has been stored at $DNS_Storage/broken_$MD5_New_Checksum for manual inspection - please report this error to your manager.", 'System');
			`$cp -dp $DNS_Internal_Location $DNS_Storage/broken_$MD5_New_Checksum`; # Backing up broken sudoers
			chown $Owner, $Group, "$DNS_Storage/broken_$MD5_New_Checksum";
			chmod 0640, "$DNS_Storage/broken_$MD5_New_Checksum";
		}
		`$cp -dp $DNS_Storage/$Latest_Good_DNS $DNS_Internal_Location`; # Restoring latest working sudoers
		chown $Owner, $Group, $DNS_Internal_Location;
		chmod 0640, $DNS_Internal_Location;
	}
	else {
		print "New sudoers matches old sudoers. Not replacing.\n";
	}


	# / Audit Log

} # sub record_audit

