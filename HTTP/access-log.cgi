#!/usr/bin/perl

use strict;
use HTML::Table;

require 'common.pl';
my $DB_Management = DB_Management();
my ($CGI, $Session, $Cookie) = CGI();

my $User_Name = $Session->param("User_Name"); #Accessing User_Name session var
my $User_Admin = $Session->param("User_Admin"); #Accessing User_Admin session var

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

if ($User_Admin != 1 && $User_Admin != 2) {
	my $Message_Red = 'You do not have sufficient privileges to access that page.';
	$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
	print "Location: /index.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $User_Name_Filter = $CGI->param("User_Name_Filter");
my $Filter = $CGI->param("Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}
if ($User_Name_Filter eq '' || $User_Name_Filter eq 'All') {
	$User_Name_Filter='_';
}


require "header.cgi"; ## no critic
&html_output;
require "footer.cgi";

sub html_output {

	my $Referer = $ENV{HTTP_REFERER};

	if ($Referer !~ /access-log.cgi/) {
		my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
			`category`,
			`method`,
			`action`,
			`username`
		)
		VALUES (
			?, ?, ?, ?
		)");
	
		$Audit_Log_Submission->execute("Access Log", "View", "$User_Name accessed the Access Log.", $User_Name);
	}

	my $Table = new HTML::Table(
		-cols=>11,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);


	my $Select_Logs = $DB_Management->prepare("SELECT `id`, `ip`, `hostname`, `user_agent`, `script`, `referer`, `query`, `request_method`, `https`, `username`, `time`
		FROM `access_log`
		WHERE `username` LIKE ?
		AND (
			`id` LIKE ?
			OR `ip` LIKE ?
			OR `hostname` LIKE ?
			OR `user_agent` LIKE ?
			OR `script` LIKE ?
			OR `referer` LIKE ?
			OR `query` LIKE ?
			OR `request_method` LIKE ?
			OR `username` LIKE ?
			OR `time` LIKE ?
			)
		ORDER BY `time` DESC
		LIMIT 0 , $Rows_Returned");

	$Select_Logs->execute("%$User_Name_Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%",
		"%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%");
	
	my $Rows = $Select_Logs->rows();

	my $Select_Logs_Count = $DB_Management->prepare("SELECT `id` FROM `access_log`");
		$Select_Logs_Count->execute( );
		my $Total_Rows = $Select_Logs_Count->rows();

	$Table->addRow( "ID", "IP", "Hostname", "User Agent", "Script", "Referer", "Query", "Method", "HTTPS", "User Name", "Time" );
	$Table->setRowClass (1, 'tbrow1');
	
	my $Row_Count=1;
	
	while ( my @Select_Logs = $Select_Logs->fetchrow_array() )
	{

		$Row_Count++;
	
		my $DBID = $Select_Logs[0];
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $IP = $Select_Logs[1];
			$IP =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Hostname = $Select_Logs[2];
			$Hostname =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $User_Agent = $Select_Logs[3];
			$User_Agent =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Script = $Select_Logs[4];
			$Script =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Referer_Link = $Select_Logs[5];
			my $Referer = $Referer_Link;
			$Referer =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Query = $Select_Logs[6];
			$Query =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Request_Method = $Select_Logs[7];
			$Request_Method =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $HTTPS = $Select_Logs[8];
		my $Access_User_Name = $Select_Logs[9];
			$Access_User_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Access_Time = $Select_Logs[10];
			$Access_Time =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	
		if ($HTTPS eq 'on') {
			$HTTPS='On';
		}
		else {
			$HTTPS='Off';
		}

		$Table->addRow( $DBID, $IP, $Hostname, $User_Agent, $Script, "<a href=\"$Referer_Link\">$Referer</a>",
		$Query, $Request_Method, $HTTPS, $Access_User_Name, $Access_Time );
	
		if ($HTTPS eq 'On') {
			$Table->setCellClass ($Row_Count, 9, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($Row_Count, 9, 'tbrowerror');
		}

	$Table->setColWidth(1, '1px');
		$Table->setColWidth(10, '110px');
		$Table->setColWidth(11, '110px');

		$Table->setColAlign(8, 'center');
		$Table->setColAlign(9, 'center');
		$Table->setColAlign(10, 'center');
		$Table->setColAlign(11, 'center');

	}

print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='access-log.cgi' method='post' >
				<tr>
					<td style="text-align: right;">Returned Rows:</td>
					<td style="text-align: right;">
						<select name='Rows_Returned' onchange='this.form.submit()' style="width: 150px">
ENDHTML

if ($Rows_Returned == 100) {print "<option value=100 selected>100</option>";} else {print "<option value=100>100</option>";}
if ($Rows_Returned == 250) {print "<option value=250 selected>250</option>";} else {print "<option value=250>250</option>";}
if ($Rows_Returned == 500) {print "<option value=500 selected>500</option>";} else {print "<option value=500>500</option>";}
if ($Rows_Returned == 1000) {print "<option value=1000 selected>1000</option>";} else {print "<option value=1000>1000</option>";}
if ($Rows_Returned == 2500) {print "<option value=2500 selected>2500</option>";} else {print "<option value=2500>2500</option>";}
if ($Rows_Returned == 5000) {print "<option value=5000 selected>5000</option>";} else {print "<option value=5000>5000</option>";}
if ($Rows_Returned == 18446744073709551615) {print "<option value=18446744073709551615 selected>All</option>";} else {print "<option value=18446744073709551615>All</option>";}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">
						User:
					</td>
					<td style="text-align: right;">
						<select name='User_Name_Filter' onchange='this.form.submit()' style="width: 150px">
							<option value=''>All</option>
ENDHTML

my $User_Name_Retreive = $DB_Management->prepare("SELECT `username`
FROM `credentials`");
$User_Name_Retreive->execute( );

while ( (my $DB_User_Name) = my @User_Name_Retreive = $User_Name_Retreive->fetchrow_array() )
{
	if ($User_Name_Filter eq $DB_User_Name) {
		print "<option selected>$DB_User_Name</option>";
	}
	else {
		print "<option>$DB_User_Name</option>";
	}
}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">
						Filter:
					</td>
					<td style="text-align: right;">
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Record" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">User Access Log | Logs Displayed: $Rows of $Total_Rows</p>

$Table
ENDHTML
} # sub html_output