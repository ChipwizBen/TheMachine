#!/usr/bin/perl

use strict;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../../../common.pl';}
require $Common_Config;

my ($CGI, $Session, $Cookie) = CGI();

my $Message_Red = "Ain't nobody got taam fo' dat.";
$Session->param('Message_Red', $Message_Red);
$Session->flush();
print "Location: /index.cgi\n\n";
exit(0);