#!/usr/bin/perl

use strict;
use POSIX qw(strftime);

require '../common.pl';
my $DB_Management = DB_Management();
my $DB_DNS = DB_DNS();
my $DNS_Location = DNS_Location();
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

# Safety check for unapproved Rules

	my $Select_Rules = $DB_DNS->prepare("SELECT `id`
		FROM `rules`
		WHERE `active` = '1'
		AND `approved` = '0'"
	);

	$Select_Rules->execute();
	my $Rows = $Select_Rules->rows();

	if ($Rows > 0) {
		$DB_Management->do("UPDATE `lock` SET 
		`dns-build` = '3',
		`last-dns-build-finished` = NOW()");
		print "You have Rules pending approval. Please either approve or delete unapproved Rules before continuing. Exiting...\n";
		exit(1);
	}

# / Safety check for unapproved Rules

&write_internal;
&write_external;


my $DNS_Check = ` -c -f $DNS_Location`;

if ($DNS_Check =~ m/$DNS_Location:\sparsed\sOK/) {
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

	open( FILE, ">$DNS_Location" ) or die "Can't open $DNS_Location";

	print FILE "#########################################################################\n";
	print FILE "## $System_Name\n";
	print FILE "## Version: $Version\n";
	print FILE "## AUTO GENERATED SCRIPT\n";
	print FILE "## Please do not edit by hand\n";
	print FILE "## This file is part of a wider system and is automatically overwritten often\n";
	print FILE "## View the changelog or README files for more information.\n";
	print FILE "#########################################################################\n";
	print FILE "\n\n";


	print FILE "### Environmental Defaults Section Begins ###\n\n";

	open( ENVIRONMENTALS, "environmental-defaults" ) or die "Can't open environmental-defaults file.";

	LINE: foreach my $Line (<ENVIRONMENTALS>) {

		if ($Line =~ /^###/) {next LINE};
		print FILE "$Line";

	}

	print FILE "\n### Environmental Defaults Section Ends ###\n";

	close ENVIRONMENTALS;

	print FILE "\n";
	close FILE;

} # sub write_internal

sub write_external {
	
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

	my $MD5_New_Checksum = `$md5sum $DNS_Location | $cut -d ' ' -f 1`;
		$MD5_New_Checksum =~ s/\s//g;
	my $MD5_Existing_DNS = `$md5sum $DNS_Storage/sudoers_$MD5_New_Checksum | $cut -d ' ' -f 1`;
		$MD5_Existing_DNS =~ s/\s//g;

	if ($Result eq 'PASSED' && $MD5_New_Checksum ne $MD5_Existing_DNS) {
		my $New_DNS_Location = "$DNS_Storage/sudoers_$MD5_New_Checksum";
		`$cp -dp $DNS_Location $New_DNS_Location`; # Backing up sudoers
		chown $Owner, $Group, $New_DNS_Location;
		chmod 0640, $New_DNS_Location;
		$MD5_New_Checksum = "MD5: " . $MD5_New_Checksum;
		$Audit_Log_Submission->execute("DNS", "Deployment Succeeded", "Configuration changes were detected and a new sudoers file was built, passed visudo validation, and MD5 checksums as follows: $MD5_New_Checksum. A copy of this sudoers has been stored at '$New_DNS_Location' for future reference.", 'System');
	}
	elsif ($Result eq 'FAILED') {
		my $Latest_Good_DNS = `$ls -t $DNS_Storage | $grep 'sudoers_' | $head -1`;
			$Latest_Good_DNS =~ s/\n//;
		my $Latest_Good_DNS_MD5 = `$md5sum $DNS_Storage/$Latest_Good_DNS | $cut -d ' ' -f 1`;
			$Latest_Good_DNS_MD5 =~ s/\s//;
		my $Check_For_Existing_Bad_DNS = `$ls -t $DNS_Storage/broken_$MD5_New_Checksum`;
		if (!$Check_For_Existing_Bad_DNS) {
			$Audit_Log_Submission->execute("DNS", "Deployment Failed", "Configuration changes were detected and a new sudoers file was built, but failed visudo validation. Deployment aborted, latest valid sudoers (MD5: $Latest_Good_DNS_MD5) has been restored. The broken sudoers file has been stored at $DNS_Storage/broken_$MD5_New_Checksum for manual inspection - please report this error to your manager.", 'System');
			`$cp -dp $DNS_Location $DNS_Storage/broken_$MD5_New_Checksum`; # Backing up broken sudoers
			chown $Owner, $Group, "$DNS_Storage/broken_$MD5_New_Checksum";
			chmod 0640, "$DNS_Storage/broken_$MD5_New_Checksum";
		}
		`$cp -dp $DNS_Storage/$Latest_Good_DNS $DNS_Location`; # Restoring latest working sudoers
		chown $Owner, $Group, $DNS_Location;
		chmod 0640, $DNS_Location;
	}
	else {
		print "New sudoers matches old sudoers. Not replacing.\n";
	}


	# / Audit Log

} # sub record_audit

