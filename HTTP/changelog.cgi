#!/usr/bin/perl

use strict;
use HTML::Table;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my ($CGI, $Session, $Cookie) = CGI();

my $User_Name = $Session->param("User_Name"); #Accessing User_Name session var

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

require $Header;
&html_output;

sub html_output {

	my $Table = new HTML::Table(
		-cols=>2,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);

	$Table->addRow( "Version", "Change" );
	$Table->setRowClass (1, 'tbrow1');

	
	## Version 1.0.0
	$Table->addRow('1.0.0', 'Initial release.');

$Table->setColAlign(1, 'center');

print <<ENDHTML;

<div id='full-page-block'>
<h2 style='text-align: center;'>System Changelog</h2>

$Table

</div>

ENDHTML

} #sub html_output

