#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);

use DBI;

require './common.pl';

my $DB_Connection = DB_Connection();
my ($Version, $Latest_Version, $URL, $Notification) = Version('Version_Check');

if (!$URL) {print "No URL to check! You should manually add a URL to the 'version' table in the database.\n"; exit(1);}

print "Checking version and notifications from $URL...\n";

my $Returned = `curl -sS $URL 2>&1`;

if ($Returned =~ /URL/) {
	$Latest_Version = $Returned;
		$Latest_Version =~ s/.*Version='(.*?)'.*/$1/gs;
	$Notification = $Returned;
		$Notification =~ s/.*Notification='(.*?)'.*/$1/gs;
	$URL = $Returned;
		$URL =~ s/.*URL='(.*?)'.*/$1/gs;

	if (!$Version && $Latest_Version) {
		$Version = $Latest_Version;
		my $Version_Check = $DB_Connection->prepare("UPDATE `version` SET
		`Version` = ?
		WHERE 1=1");
		$Version_Check->execute($Version);
	}

	if ($Version eq $Latest_Version) {
		print "Installed Version:\t$Version\n";
		print "Latest Version:\t\t$Latest_Version\n";
		print "You are using the latest version\n";
	}
	else {
		print "Installed Version:\t$Version\n";
		print "Latest Version:\t\t$Latest_Version\n";
		print "An update is available!\n";
	}
	if ($Notification) {
		print "Notification: $Notification\n";
	}

	my $DB_Update = $DB_Connection->prepare("UPDATE `version` SET
		`Latest_Version` = ?,
		`URL` = ?,
		`Notification` = ?
		WHERE 1=1");
	$DB_Update->execute($Latest_Version, $URL, $Notification);
	exit(0);
}
else {
	print "Something went wrong. This is what we got:\n$Returned\n";
	exit(1);
}


1;
