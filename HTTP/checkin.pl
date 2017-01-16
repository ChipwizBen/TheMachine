#!/usr/bin/perl -T

use strict;

use DBI;

require './common.pl';

my $CGI = CGI->new;
print "Content-Type: text/html\n\n";

my $Host_Name = $CGI->param("Host_Name");
	$Host_Name =~ s/\s//g;
	$Host_Name =~ s/[^a-zA-Z0-9\-\.]//g;

if (!$Host_Name) {
	print "You must specify a hostname\n";
	exit(1);
}

&checkin;

sub checkin {

	my $DB_Connection = DB_Connection();
	my $Find_Host = $DB_Connection->prepare("SELECT `id` FROM `hosts`
		WHERE `hostname` = ?");
		
	$Find_Host->execute($Host_Name);

	while ( my @Discovered_Host = $Find_Host->fetchrow_array() )
	{

		my $Host_ID = $Discovered_Host[0];

		# Updating sudoers distribution database with latest checkin
		my $DB_Connection = DB_Connection();
		my $Distribution_Checkin = $DB_Connection->prepare("UPDATE `distribution` SET
		`last_checkin` = NOW()
		WHERE `host_id` = ?");

		$Distribution_Checkin->execute($Host_ID);

		print "Successfully checked in $Host_Name\n";

	}
}

1;
