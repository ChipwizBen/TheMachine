#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;

# load per modules
use DBI;
use Data::Dumper;
use POSIX qw(strftime);
use Net::Telnet ();
use Net::Ping;
$SNMP::use_sprint_value = 1;
$SNMP::use_numeric = 1;
use SNMP;
use HTML::Table;
use Time::HiRes qw/usleep/;
use CGI;
use CGI::Carp qw/fatalsToBrowser/;
use CGI::Session qw/-ip-match/;

#definition of variables
#my $arghost = $ARGV[0], or die "You need to input an argument containing the device IP. e.g. '/infinet-history-extract-eth0.pl 10.10.33.18'";
my $db="metronet";
my $host="localhost";
my $user="mml";
my $password="mmladmin";  # the root password
my $dbtable="ip-allocation-log";
my $datetime = strftime "%Y-%m-%d %H:%M:%S", gmtime;
my $rowcount="0";
my $id="0";
my $USERNAME='';
my $cookie;
my %FORM;
my $tb;
my $DEVICE_NAME;
my $sth;
my @DBOUTPUT;
my $ROWSRETURNED;
my $TABLEENTRYNUMBER;

my $cgi = new CGI;
		my $session = new CGI::Session(undef, $cgi, {Directory=>'/tmp/Metronet-Sessions'});
		$session->expire('+12h');
		$cookie = $cgi->cookie(CGISESSID => $session->id );

$USERNAME = $session->param("USER_NAME"); #Accessing USERNAME session var

if ($USERNAME eq '') {

print "Location: login.cgi\n\n";
exit(0);
}

$ROWSRETURNED = $cgi->param("ROWSRETURNED");

if ($ROWSRETURNED eq '') {
	$ROWSRETURNED='100';
}

#connect to MySQL database
my $dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host",
                           $user,
                           $password)
                           or die "Can't connect to database: $DBI::errstr\n";


#Create the main table
$tb = new HTML::Table(
                            -cols=>7,
                            -align=>'center',
                            -rules=>'all',
                            -border=>0,
                            -evenrowclass=>'tbeven',
                            -oddrowclass=>'tbodd',
                            -width=>'100%',
                            -spacing=>0,
                            -padding=>1 );


$tb->addRow ( "Line Number", "Database ID", "Allocated IP/Block", "Subnet", "Allocatable Block", "Allocation Time", "Allocated By", );

$tb->setRowClass (1, 'tbrow1');

$sth = $dbh->prepare("SELECT `id`, `ip`, `subnet`, `block`, `allocated-at`, `allocated-by`
FROM `$dbtable`
ORDER BY `allocated-at` DESC
LIMIT 0 , $ROWSRETURNED");
$sth->execute( );

while ( ($id) =
@DBOUTPUT = $sth->fetchrow_array() )
{

#-------------------------------------------

$TABLEENTRYNUMBER++;

		my $DATABASE_ID = "$DBOUTPUT[0]";
		my $IP = "$DBOUTPUT[1]";
		my $SUBNET = "$DBOUTPUT[2]";
		my $BLOCK = "$DBOUTPUT[3]";
		my $ALLOCATED_AT = "$DBOUTPUT[4]";
		my $ALLOCATED_BY = "$DBOUTPUT[5]";


#-------------------------------------------

	$tb->addRow( ${TABLEENTRYNUMBER}, ${DATABASE_ID}, ${IP}, ${SUBNET}, ${BLOCK}, ${ALLOCATED_AT}, ${ALLOCATED_BY});
	$rowcount++;

#-------------------------------------------

}

	my $rows = $sth->rows();

require "header.cgi"; ## no critic
&html_output;

sub html_output {

print <<ENDHTML;
<div id="body">

<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
<td>
<table cellpadding="3px">
<tr>
<td>Returned rows:</td>
		<form action='ip-allocation-log.cgi' method='post' >
<td>
	<select name='ROWSRETURNED' style="width: 150px">
	<option value=100>100</option>
	<option value=250>250</option>
	<option value=500>500</option>
	<option value=1000>1000</option>
	<option value=2500>2500</option>
	<option value=5000>5000</option>
	<option value=9999999999999999999>All</option>
</select>
</td>
<td><input type=submit name='ok' value='Refresh'><br/></td>
</form>
</table>
</td>
</table>

<p style="font-size:14px; font-weight:bold;">Recent IP Allocations | Total Number of Rows: $rows</p>

<div id="tbmain">
$tb<br />
</div> <!-- tbmain -->
<br />

</div> <!-- strip -->
</body>
</html>

ENDHTML

} #sub html_output end

# output any db query problems
warn "Problem in retrieving results", $sth->errstr( ), "\n"
        if $sth->err( );
exit;

# clean db exit
$dbh->disconnect;
