#!/usr/bin/perl

use strict;
use HTML::Table;
use Date::Parse qw(str2time);
use POSIX qw(strftime);

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_DShell = DB_DShell();
my $DB_IP_Allocation = DB_IP_Allocation();
my ($CGI, $Session, $Cookie) = CGI();

my $Run_Job = $CGI->param("Run_Job");

my $User_Name = $Session->param("User_Name");
my $User_DShell_Admin = $Session->param("User_DShell_Admin");

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $Filter = $CGI->param("Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}


if ($Run_Job) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/jobs.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_add_command;
	}
}
else {
	require $Header;
	&html_output;
	require $Footer;
}

sub run_job {

	# Audit Log
	my $DB_Management = DB_Management();
	my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");
	
	$Audit_Log_Submission->execute("D-Shell", "Run", "$User_Name started Job ID $Run_Job.", $User_Name);
	# / Audit Log

	system("./dshell.pl -c $Run_Job");

}

sub html_output {

	my $Table = new HTML::Table(
		-cols=>10,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);


	my $Select_Job_Count = $DB_DShell->prepare("SELECT `id` FROM `jobs`");
		$Select_Job_Count->execute( );
		my $Total_Rows = $Select_Job_Count->rows();


	my $Select_Commands = $DB_DShell->prepare("SELECT `id`, `host_id`, `command_set_id`, `status`, `last_modified`, `modified_by`
		FROM `jobs`
		ORDER BY `id` DESC
		LIMIT 0 , $Rows_Returned"
	);

	$Select_Commands->execute();

	my $Rows = $Select_Commands->rows();

	$Table->addRow( "ID", "Host", "Command Set", "Currently Running Command", "Status", "Last Modified", "Modified By", "Log", "Control", "Kill" );
	$Table->setRowClass (1, 'tbrow1');

	my $Command_Row_Count=1;

	while ( my @Select_Commands = $Select_Commands->fetchrow_array() )
	{

		$Command_Row_Count++;

		my $DBID = $Select_Commands[0];
		my $Host_ID = $Select_Commands[1];
		my $Command_Set_ID = $Select_Commands[2];
		my $Status = $Select_Commands[3];
		my $Last_Modified = $Select_Commands[4];
		my $Modified_By = $Select_Commands[5];

		my $Host_Query = $DB_IP_Allocation->prepare("SELECT `hostname`
		FROM `hosts`
		WHERE `id` = ?");
		$Host_Query->execute($Host_ID);
		my $Host_Name = $Host_Query->fetchrow_array();

		my $Command_Query = $DB_DShell->prepare("SELECT `name`, `command`
		FROM `command_sets`
		WHERE `id` = ?");
		$Command_Query->execute($Command_Set_ID);
		my ($Command_Name, $Command) = $Command_Query->fetchrow_array();
		$Command_Name = "<a href='/D-Shell/command-sets.cgi?ID_Filter=$Command_Set_ID'>$Command_Name</a>";

		my $Button;
		if ($Status == 0) {
			$Status = 'Job Complete';
			$Button = '<img src="/resources/imgs/confirm.png" alt="Job Complete" >';
			$Table->setCellClass ($Command_Row_Count, 9, 'tbrowdarkgreen');
		}
		elsif ($Status == 1) {
			$Status = 'Running';
			$Button = "<a href='/D-Shell/jobs.cgi?Pause_Job=$DBID'><img src=\"/resources/imgs/pause.png\" alt=\"Pause Job ID $DBID\" ></a>";
		}
		elsif ($Status == 2) {
			$Status = 'Paused';
			$Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
		}
		elsif ($Status == 3) {$Status = 'Stopped';}
		elsif ($Status == 4) {
			$Status = 'Pending';
			$Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
		}
		else {$Status = 'Error';}

		$Table->addRow(
			"$DBID",
			"$Host_Name",
			"$Command_Name",
			"",
			"$Status",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/D-Shell/jobs.cgi?View_Job=$DBID'><img src=\"/resources/imgs/view-notes.png\" alt=\"View log for Job ID $DBID\" ></a>",
			"$Button",
			"<a href='/D-Shell/jobs.cgi?Stop_Job=$DBID'><img src=\"/resources/imgs/red.png\" alt=\"Stop Job ID $DBID\" ></a>"
		);

		if ($Status eq 'Job Complete') {$Table->setCellClass ($Command_Row_Count, 5, 'tbrowdarkgreen');}
		if ($Status eq 'Running') {$Table->setCellClass ($Command_Row_Count, 5, 'tbrowgreen');}
		if ($Status eq 'Paused') {$Table->setCellClass ($Command_Row_Count, 5, 'tbroworange');}
		if ($Status eq 'Pending') {$Table->setCellClass ($Command_Row_Count, 5, 'tbrowgrey');}
		if ($Status eq 'Error') {$Table->setCellClass ($Command_Row_Count, 5, 'tbrowerror');}

	}


	$Table->setColWidth(1, '1px');
	$Table->setColWidth(5, '90px');
	$Table->setColWidth(6, '110px');
	$Table->setColWidth(7, '110px');
	$Table->setColWidth(8, '1px');
	$Table->setColWidth(9, '1px');
	$Table->setColWidth(10, '1px');

	$Table->setColAlign(1, 'center');
	for (5..10) {
		$Table->setColAlign($_, 'center');
	}



print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/D-Shell/jobs.cgi' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Commands" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">

		</td>
		<td align="right">

		</td>
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">Jobs | Jobs Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output