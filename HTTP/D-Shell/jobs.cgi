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
my $Job_Log = $CGI->param("Job_Log");

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
		&run_job;
		my $Message_Green = "Job ID $Run_Job started.";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /D-Shell/jobs.cgi\n\n";
		exit(0);
	}
}
elsif ($Job_Log) {
		require $Header;
		&html_output;
		require $Footer;
		&html_job_log;
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

	system("./d-shell.pl -j $Run_Job");

}

sub html_job_log {

	my $Table = new HTML::Table(
		-cols=>7,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'95%',
		-spacing=>0,
		-padding=>1
	);

	$Table->addRow( "#", "Command", "Output", "Exit Code", "Started", "Ended", "User");
	$Table->setRowClass (1, 'tbrow1');

	my $Select_Log_Entries = $DB_DShell->prepare("SELECT `command`, `exit_code`, `output`, `task_started`, `task_ended`, `modified_by`
	FROM `job_status`
	WHERE `job_id` = ?
	ORDER BY `id` ASC");

	$Select_Log_Entries->execute($Job_Log);

	my $Row_Count;
	while ( my @Entries = $Select_Log_Entries->fetchrow_array() )
	{
		$Row_Count++;
		my $Command = $Entries[0];
		my $Exit_Code = $Entries[1];
		my $Output = $Entries[2];
		my $Task_Started = $Entries[3];
		my $Task_Ended = $Entries[4];
		my $Modified_By = $Entries[5];

		if ($Exit_Code == 0) {
			$Exit_Code = "<span style='color: #00FF00;'>$Exit_Code</span>"; 
			$Output = "<span style='color: #00FF00;'>$Output</span>";
		}
		else {
			$Exit_Code = "<span style='color: #FF0000;'>$Exit_Code</span>";
			$Output = "<span style='color: #FF0000;'>$Output</span>";
		}

		$Table->addRow($Row_Count, $Command, $Output, $Exit_Code, $Task_Started, $Task_Ended, $Modified_By);
	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(4, '1px');
	for (5..7) {
		$Table->setColWidth($_, '110px');
	}

	$Table->setColAlign(1, 'center');
	for (4..7) {
		$Table->setColAlign($_, 'center');
	}

	my $Entry_Count = $Row_Count;
	if ($Row_Count == 0) {
		undef $Table;
		undef $Row_Count;
	}
	else {
		$Entry_Count = "$Entry_Count status entires found, latest first."
	}

print <<ENDHTML;
<div id="full-width-popup-box">
<a href="/D-Shell/jobs.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Log entries for Job ID $Job_Log</h3>

<p>$Entry_Count</p>

$Table

ENDHTML

} # sub html_job_log

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


	my $Select_Jobs = $DB_DShell->prepare("SELECT `id`, `host_id`, `command_set_id`, `status`, `last_modified`, `modified_by`
		FROM `jobs`
		ORDER BY `id` DESC
		LIMIT 0 , $Rows_Returned"
	);

	$Select_Jobs->execute();

	my $Rows = $Select_Jobs->rows();

	$Table->addRow( "ID", "Host", "Command Set", "Currently Running Command", "Status", "Last Modified", "Modified By", "Log", "Control", "Kill" );
	$Table->setRowClass (1, 'tbrow1');

	my $Job_Row_Count=1;

	while ( my @Jobs = $Select_Jobs->fetchrow_array() )
	{

		$Job_Row_Count++;

		my $DBID = $Jobs[0];
		my $Host_ID = $Jobs[1];
		my $Command_Set_ID = $Jobs[2];
		my $Status = $Jobs[3];
		my $Last_Modified = $Jobs[4];
		my $Modified_By = $Jobs[5];

		my $Host_Query = $DB_IP_Allocation->prepare("SELECT `hostname`
		FROM `hosts`
		WHERE `id` = ?");
		$Host_Query->execute($Host_ID);
		my $Host_Name = $Host_Query->fetchrow_array();

		my $Command_Query = $DB_DShell->prepare("SELECT `name`
		FROM `command_sets`
		WHERE `id` = ?");
		$Command_Query->execute($Command_Set_ID);
		my $Command_Name = $Command_Query->fetchrow_array();
		$Command_Name = "<a href='/D-Shell/command-sets.cgi?ID_Filter=$Command_Set_ID'>$Command_Name</a>";

		## Gather dependency data
		my $Command_Set_Dependencies;
		my $Select_Command_Set_Dependencies = $DB_DShell->prepare("SELECT `dependent_command_set_id`
			FROM `command_set_dependency`
			WHERE `command_set_id` = ?
			ORDER BY `order` ASC"
		);
		$Select_Command_Set_Dependencies->execute($Command_Set_ID);
	
		while ( my @Dependencies = $Select_Command_Set_Dependencies->fetchrow_array() )
		{
			my $Dependent_Command_Set_ID = $Dependencies[0];

			my $Select_Dependency_Name = $DB_DShell->prepare("SELECT `name`, `description`
				FROM `command_sets`
				WHERE `id` = ?"
			);
			$Select_Dependency_Name->execute($Dependent_Command_Set_ID);
			my ($Dependency_Name, $Dependency_Description) = $Select_Dependency_Name->fetchrow_array();

			$Dependency_Description =~ s/(.{40}[^\s]*)\s+/$1\n/g; # Takes the first 40 chars, then breaks at next linespace

			$Command_Set_Dependencies = $Command_Set_Dependencies . 
			"<a href='/D-Shell/command-sets.cgi?ID_Filter=$Dependent_Command_Set_ID' class='tooltip' text=\"$Dependency_Description\">$Dependency_Name</a>, ";
		}
		if ($Command_Set_Dependencies) {
			$Command_Set_Dependencies =~ s/,\s$//;
			$Command_Set_Dependencies = '[Dependencies: ' . $Command_Set_Dependencies . ']';
		}
		## / Gather dependency data

		### Discover Status Count

		my $Select_Log_Count = $DB_DShell->prepare("SELECT COUNT(*)
			FROM `job_status`
			WHERE `job_id` = ?"
		);
		$Select_Log_Count->execute($DBID);
		my $Log_Count = $Select_Log_Count->fetchrow_array();

		### / Discover Status Count

		### Discover Currently Running Command

		my $Running_Command;
		my $Select_Currently_Running_Command = $DB_DShell->prepare("SELECT `command`
			FROM `job_status`
			WHERE `job_id` = ?
			ORDER BY `id` DESC
			LIMIT 1"
		);
		$Select_Currently_Running_Command->execute($DBID);
		my $Held_Running_Command = $Select_Currently_Running_Command->fetchrow_array();

		### / Discover Currently Running Command

		my $Button;
		if ($Status == 0) {
			$Running_Command = 'None, Job Complete.';
			$Status = 'Job Complete';
			$Button = '<img src="/resources/imgs/confirm.png" alt="Job Complete" >';
			$Table->setCellClass ($Job_Row_Count, 9, 'tbrowdarkgreen');
		}
		elsif ($Status == 1) {
			$Running_Command = $Held_Running_Command;
			$Status = 'Running';
			$Button = "<a href='/D-Shell/jobs.cgi?Pause_Job=$DBID'><img src=\"/resources/imgs/pause.png\" alt=\"Pause Job ID $DBID\" ></a>";
		}
		elsif ($Status == 2) {
			$Running_Command = 'None, Processing Paused...';
			$Status = 'Paused';
			$Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
		}
		elsif ($Status == 3) {$Status = 'Stopped';}
		elsif ($Status == 4) {
			$Running_Command = 'None, Job Killed.';
			$Status = 'Pending';
			$Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
		}
		else {$Status = 'Error';}

		$Table->addRow(
			$DBID,
			$Host_Name,
			"$Command_Name $Command_Set_Dependencies",
			$Running_Command,
			$Status,
			$Last_Modified,
			$Modified_By,
			"<a href='/D-Shell/jobs.cgi?Job_Log=$DBID'>
				<div style='position: relative; background: url(\"/resources/imgs/view-notes.png\") no-repeat; width: 22px; height: 22px;'> 
					<p style='position: absolute; width: 22px; text-align: center; font-weight: bold; color: #FF0000;'>
						$Log_Count
					</p>
				</div>
			</a>",
			$Button,
			"<a href='/D-Shell/jobs.cgi?Stop_Job=$DBID'><img src=\"/resources/imgs/red.png\" alt=\"Stop Job ID $DBID\" ></a>"
		);

		if ($Status eq 'Job Complete') {$Table->setCellClass ($Job_Row_Count, 5, 'tbrowdarkgreen');}
		if ($Status eq 'Running') {$Table->setCellClass ($Job_Row_Count, 5, 'tbrowgreen');}
		if ($Status eq 'Paused') {$Table->setCellClass ($Job_Row_Count, 5, 'tbroworange');}
		if ($Status eq 'Pending') {$Table->setCellClass ($Job_Row_Count, 5, 'tbrowgrey');}
		if ($Status eq 'Error') {$Table->setCellClass ($Job_Row_Count, 5, 'tbrowerror');}

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