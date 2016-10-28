#!/usr/bin/perl

use strict;

require 'common.pl';
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

print $CGI->redirect("/login.cgi");

$Session->delete();
$Session->flush();

exit(0);
