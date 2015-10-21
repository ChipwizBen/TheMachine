#!/usr/bin/perl

use strict;

require 'common.pl';
my $DB_Management = DB_Management();
my ($CGI, $Session, $Cookie) = CGI();

print $CGI->redirect("/login.cgi");

$Session->delete();

exit(0);
