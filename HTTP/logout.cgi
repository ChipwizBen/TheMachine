#!/usr/bin/perl -T

use strict;
use lib qw(resources/modules/);
use lib qw(../resources/modules/);

require './common.pl';
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

print $CGI->redirect("/login.cgi");

$Session->delete();
$Session->flush();

exit(0);
