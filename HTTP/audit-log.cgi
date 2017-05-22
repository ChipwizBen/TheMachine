#!/usr/bin/perl -T

use strict;
use lib qw(resources/modules/);
use lib qw(../resources/modules/);
use HTML::Table;

require './common.pl';
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $User_Name = $Session->param("User_Name"); #Auditing User_Name session var
my $User_Admin = $Session->param("User_Admin"); #Auditing User_Admin session var

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

if ($User_Admin != 1 && $User_Admin != 2) {
	my $Message_Red = 'You do not have sufficient privileges to access that page.';
	$Session->param('Message_Red', $Message_Red);
	$Session->flush();
	print "Location: /index.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $User_Name_Filter = $CGI->param("User_Name_Filter");
my $Category_Filter = $CGI->param("Category_Filter");
my $Method_Filter = $CGI->param("Method_Filter");
my $Filter = $CGI->param("Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}
if ($User_Name_Filter eq '' || $User_Name_Filter eq 'All') {
	$User_Name_Filter='_';
}


require "./header.cgi";
&html_output;
require "./footer.cgi";

sub html_output {

	my $Referer = $ENV{HTTP_REFERER};

	if ($Referer !~ /audit-log.cgi/) {
		my $Audit_Log_Submission = Audit_Log_Submission();
	
		$Audit_Log_Submission->execute("Audit Log", "View", "$User_Name accessed the Audit Log.", $User_Name);
	}

	my $Table = new HTML::Table(
		-cols=>6,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);


	my $Select_Logs = $DB_Connection->prepare("SELECT `id`, `category`, `method`, `action`, `time`, `username`
		FROM `audit_log`
		WHERE `username` LIKE ?
		AND `category` LIKE ?
		AND `method` LIKE ?
		AND (
			`id` LIKE ?
			OR `category` LIKE ?
			OR `method` LIKE ?
			OR `action` LIKE ?
			OR `time` LIKE ?
			OR `username` LIKE ?
			)
		ORDER BY `id` DESC
		LIMIT ?, ?");

	$Select_Logs->execute("%$User_Name_Filter%", "%$Category_Filter%", "%$Method_Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", 0, $Rows_Returned);

	my $Rows = $Select_Logs->rows();

	my $Select_Logs_Count = $DB_Connection->prepare("SELECT `id` FROM `audit_log`");
		$Select_Logs_Count->execute( );
		my $Total_Rows = $Select_Logs_Count->rows();

	$Table->addRow( "ID", "Category", "Method", "Action", "Time", "User" );
	$Table->setRowClass (1, 'tbrow1');

	while ( my @Select_Logs = $Select_Logs->fetchrow_array() )
	{
	
		my $DBID = $Select_Logs[0];
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Category = $Select_Logs[1];
			$Category =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Method = $Select_Logs[2];
			my $Method_Clean = $Method;
			$Method =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Action = $Select_Logs[3];
			$Action =~ s/</&lt;/g;
			$Action =~ s/>/&gt;/g;
			$Action =~ s/  /&nbsp;&nbsp;/g;
			$Action =~ s/\r/<br \/>/g;
			$Action =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $User = $Select_Logs[4];
			$User =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Time = $Select_Logs[5];
			$Time =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	

		$Table->addRow( $DBID, $Category, $Method, $Action, $User, $Time );

		if ($Method_Clean eq 'Add') {
			$Table->setCellClass (-1, 3, 'tbrowgreen');
		}
		elsif ($Method_Clean eq 'Delete') {
			$Table->setCellClass (-1, 3, 'tbrowred');
		}
		elsif ($Method_Clean eq 'Modify') {
			$Table->setCellClass (-1, 3, 'tbroworange');
		}
		elsif ($Method_Clean eq 'View') {
			$Table->setCellClass (-1, 3, 'tbrowdarkgrey');
		}
		elsif ($Method_Clean eq 'Deployment Succeeded') {
			$Table->setCellClass (-1, 3, 'tbrowgreen');
		}
		elsif ($Method_Clean eq 'Deployment Failed') {
			$Table->setCellClass (-1, 3, 'tbrowred');
		}
		elsif ($Method_Clean eq 'Approve') {
			$Table->setCellClass (-1, 3, 'tbrowdarkgreen');
		}
		elsif ($Method_Clean eq 'Revoke') {
			$Table->setCellClass (-1, 3, 'tbrowred');
		}
		elsif ($Method_Clean eq 'Run') {
			$Table->setCellClass (-1, 3, 'tbrowgreen');
		}
		elsif ($Method_Clean eq 'Receive') {
			$Table->setCellClass (-1, 3, 'tbrowpurple');
		}
		elsif ($Method_Clean eq 'Queue') {
			$Table->setCellClass (-1, 3, 'tbrowyellow');
		}
		elsif ($Method_Clean eq 'Pause') {
			$Table->setCellClass (-1, 3, 'tbrowyellow');
		}
		elsif ($Method_Clean eq 'Resume') {
			$Table->setCellClass (-1, 3, 'tbrowgreen');
		}
		elsif ($Method_Clean eq 'Stop') {
			$Table->setCellClass (-1, 3, 'tbrowred');
		}
		elsif ($Method_Clean eq 'Prioritise') {
			$Table->setCellClass (-1, 3, 'tbroworange');
		}
	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(5, '110px');
	$Table->setColWidth(6, '110px');

	$Table->setColAlign(1, 'center');
	$Table->setColAlign(2, 'center');
	$Table->setColAlign(3, 'center');
	$Table->setColAlign(5, 'center');
	$Table->setColAlign(6, 'center');

print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='audit-log.cgi' method='post' >
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
						Filter:
					</td>
					<td style="text-align: right;">
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Record" placeholder="Search">
					</td>
				</tr>
			</table>
		</td>
		<td>
			<table align='right'>
				<tr>
					<td style="text-align: right;">
						User:
					</td>
					<td style="text-align: right;">
						<select name='User_Name_Filter' onchange='this.form.submit()' style="width: 150px">
							<option value=''>All</option>
ENDHTML

my $User_Name_Retreive = $DB_Connection->prepare("SELECT `username`
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
						Category:
					</td>
					<td style="text-align: right;">
						<select name='Category_Filter' onchange='this.form.submit()' style="width: 150px">
							<option value=''>All</option>
ENDHTML

my $Category_Retreive = $DB_Connection->prepare("SELECT DISTINCT `category`
FROM `audit_log`
ORDER BY `category` ASC");
$Category_Retreive->execute( );

while ( (my $Category) = my @Category_Retreive = $Category_Retreive->fetchrow_array() )
{
	if ($Category_Filter eq $Category) {
		print "<option selected>$Category</option>";
	}
	else {
		print "<option>$Category</option>";
	}
}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">
						Method:
					</td>
					<td style="text-align: right;">
						<select name='Method_Filter' onchange='this.form.submit()' style="width: 150px">
							<option value=''>All</option>
ENDHTML

my $Method_Retreive = $DB_Connection->prepare("SELECT DISTINCT `method`
FROM `audit_log`
ORDER BY `method` ASC");
$Method_Retreive->execute( );

while ( (my $Method) = my @Method_Retreive = $Method_Retreive->fetchrow_array() )
{
	if ($Method_Filter eq $Method) {
		print "<option selected>$Method</option>";
	}
	else {
		print "<option>$Method</option>";
	}
}

print <<ENDHTML;
						</select>
					</td>
				</tr>
			</form>
			</table>
		</td>
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">Audit Log | Logs Displayed: $Rows of $Total_Rows</p>

$Table
ENDHTML
} # sub html_output