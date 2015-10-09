#!/usr/bin/perl

use strict;

require 'common.pl';
my $DB_Management = DB_Management();
my ($CGI, $Session, $Cookie) = CGI();

$Session->delete();

print "Location: login.cgi\n\n";

exit(0);
