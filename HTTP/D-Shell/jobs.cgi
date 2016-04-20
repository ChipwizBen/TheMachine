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
my $Trigger_Job = $CGI->param("Trigger_Job");
my $Captured_User_Name = $CGI->param("Captured_User_Name");
my $Captured_Password = $CGI->param("Captured_Password");

my $Pause_Job = $CGI->param("Pause_Job");
my $Stop_Job = $CGI->param("Stop_Job");
my $Resume_Job = $CGI->param("Resume_Job");

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


if ($Trigger_Job && $Captured_User_Name && $Captured_Password) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/jobs.cgi\n\n";
		exit(0);
	}
	else {
		my $PID = &run_job;
		my $Message_Green = "Job ID $Trigger_Job started as user $Captured_User_Name (PID: $PID).";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		undef $Trigger_Job;
		print $CGI->redirect(-url=>'/D-Shell/jobs.cgi');
		exit(0);
	}
}
elsif ($Run_Job) {
		require $Header;
		&html_output;
		require $Footer;
		&html_run_job;
}
elsif ($Pause_Job) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/jobs.cgi\n\n";
		exit(0);
	}
	else {
		&pause_job;
		my $Message_Orange = "Job ID $Pause_Job paused.";
		$Session->param('Message_Orange', $Message_Orange);
		$Session->flush();
		undef $Trigger_Job;
		print $CGI->redirect(-url=>'/D-Shell/jobs.cgi');
		exit(0);
	}
}
elsif ($Stop_Job) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/jobs.cgi\n\n";
		exit(0);
	}
	else {
		&stop_job;
		my $Message_Orange = "Job ID $Stop_Job stopped.";
		$Session->param('Message_Orange', $Message_Orange);
		$Session->flush();
		undef $Trigger_Job;
		print $CGI->redirect(-url=>'/D-Shell/jobs.cgi');
		exit(0);
	}
}
elsif ($Resume_Job) {
	if ($User_DShell_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /D-Shell/jobs.cgi\n\n";
		exit(0);
	}
	else {
		&resume_job;
		my $Message_Green = "Job ID $Resume_Job resumed.";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		undef $Trigger_Job;
		print $CGI->redirect(-url=>'/D-Shell/jobs.cgi');
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

sub html_run_job {

print <<ENDHTML;

<div id="small-popup-box">
<a href="/D-Shell/jobs.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Run Job ID $Run_Job</h3>

<form action='/D-Shell/jobs.cgi' name='Job_Trigger' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">SSH Username:</td>
		<td><input type='text' name='Captured_User_Name' style="width:100%" placeholder="SSH User Name" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">SSH Password:</td>
		<td><input type='password' name='Captured_Password' style="width:100%" placeholder="SSH Password" required></td>
	</tr>
</table>

<hr width="50%">

<input type='hidden' name='Trigger_Job' value='$Run_Job'>

<div style="text-align: center"><input type=submit name='Job_Trigger' value='Run Job'></div>

</form>
ENDHTML

}

sub pause_job {

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

	$Audit_Log_Submission->execute("D-Shell", "Pause", "$User_Name paused Job ID $Pause_Job.", $User_Name);
	# / Audit Log

	my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job->execute( '2', $User_Name, $Pause_Job);

} # sub pause_job

sub stop_job {

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

	$Audit_Log_Submission->execute("D-Shell", "Stop", "$User_Name killed Job ID $Stop_Job.", $User_Name);
	# / Audit Log

	my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job->execute( '3', $User_Name, $Stop_Job);

} # sub stop_job

sub resume_job {

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

	$Audit_Log_Submission->execute("D-Shell", "Resume", "$User_Name resumed Job ID $Resume_Job.", $User_Name);
	# / Audit Log

	my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job->execute( '1', $User_Name, $Resume_Job);

} # sub resume_job

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

	$Audit_Log_Submission->execute("D-Shell", "Run", "$User_Name started Job ID $Trigger_Job with username $Captured_User_Name.", $User_Name);
	# / Audit Log

	my $Update_Job = $DB_DShell->prepare("UPDATE `jobs` SET
		`status` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Job->execute( '10', $User_Name, $Trigger_Job);

	$SIG{CHLD} = 'IGNORE';
	my $PID = fork();
	if (defined $PID && $PID == 0) {
		exec "./d-shell.pl -j $Trigger_Job -u $Captured_User_Name -P $Captured_Password >> /tmp/output 2>&1 &";
		exit(0);
	}

	return $PID;

} # sub run_job

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
			$Command =~ s/</&lt;/g;
			$Command =~ s/>/&gt;/g;
			$Command =~ s/  /&nbsp;&nbsp;/g;
			$Command =~ s/\r/<br \/>/g;
			$Command =~ s/(#{1,}[\s\w'"`,.!\?\/\\]*)(.*)/<span style='color: #FFC600;'>$1<\/span>$2/g;
			$Command =~ s/(\*[A-Z0-9]*)(\s*.*)/<span style='color: #FC64FF;'>$1<\/span>$2/g;
			$Command =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Exit_Code = $Entries[1];
		my $Output = $Entries[2];
			$Output =~ s/</&lt;/g;
			$Output =~ s/>/&gt;/g;
			$Output =~ s/  /&nbsp;&nbsp;/g;
			$Output =~ s/^.*\r.*$//g;
			$Output =~ s/\r/<br \/>/g;
			$Output =~ s/\n/<br \/>/g;
			if ($Output =~ m/Skipped comment \/ empty line./) {
				$Output = "<span style='color: #FFC600;'>$Output</span>";
			}
			
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
	$Table->setColAlign(2, 'left');
	$Table->setColAlign(3, 'left');
	for (4..7) {
		$Table->setColAlign($_, 'center');
	}
	$Table->setCellAlign(1, 2, 'center');
	$Table->setCellAlign(1, 3, 'center');

	$Table->setColStyle (2, 'max-width: 500px; word-wrap: break-word;');
	$Table->setColStyle (3, 'max-width: 500px;');

	my $Entry_Count = $Row_Count;
	if ($Row_Count == 0) {
		undef $Table;
		undef $Row_Count;
		$Entry_Count = "No log entries for Job ID $Job_Log yet."
	}
	else {
		$Entry_Count = "$Entry_Count log entires found."
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

<br />

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


	my $Select_Jobs = $DB_DShell->prepare("SELECT `id`, `host_id`, `command_set_id`, `on_failure`, `status`, `last_modified`, `modified_by`
		FROM `jobs`
		ORDER BY `id` DESC
		LIMIT 0 , $Rows_Returned"
	);

	$Select_Jobs->execute();

	my $Rows = $Select_Jobs->rows();

	$Table->addRow( "ID", "Host", "Execution Sets", "Currently Running Command", "On Failure", "Status", "Last Modified", "Modified By", "Log", "Control", "Kill" );
	$Table->setRowClass (1, 'tbrow1');

	my $Job_Row_Count=1;

	while ( my @Jobs = $Select_Jobs->fetchrow_array() )
	{

		$Job_Row_Count++;

		my $DBID = $Jobs[0];
		my $Host_ID = $Jobs[1];
		my $Command_Set_ID = $Jobs[2];
		my $On_Failure = $Jobs[3];
		my $Status = $Jobs[4];
		my $Last_Modified = $Jobs[5];
		my $Modified_By = $Jobs[6];

		my $Host_Query = $DB_IP_Allocation->prepare("SELECT `hostname`
		FROM `hosts`
		WHERE `id` = ?");
		$Host_Query->execute($Host_ID);
		my $Host_Name = $Host_Query->fetchrow_array();

		my $Command_Query = $DB_DShell->prepare("SELECT `name`, `description`, `revision`
		FROM `command_sets`
		WHERE `id` = ?");
		$Command_Query->execute($Command_Set_ID);
		my ($Command_Name, $Command_Description, $Command_Revision) = $Command_Query->fetchrow_array();
		$Command_Name = "<a href='/D-Shell/command-sets.cgi?ID_Filter=$Command_Set_ID' class='tooltip' text=\"$Command_Description\"><span style='font-size: 15px; color: #FF8A00;'>$Command_Name</span> <span style='color: #00FF00;'>[Rev. $Command_Revision]</span></a>";

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

			my $Select_Dependency_Name = $DB_DShell->prepare("SELECT `name`, `description`, `revision`
				FROM `command_sets`
				WHERE `id` = ?"
			);
			$Select_Dependency_Name->execute($Dependent_Command_Set_ID);
			my ($Dependency_Name, $Dependency_Description, $Dependency_Revision) = $Select_Dependency_Name->fetchrow_array();

			$Dependency_Description =~ s/(.{40}[^\s]*)\s+/$1\n/g; # Takes the first 40 chars, then breaks at next linespace

			$Command_Set_Dependencies = $Command_Set_Dependencies . 
			"<a href='/D-Shell/command-sets.cgi?ID_Filter=$Dependent_Command_Set_ID' class='tooltip' text=\"$Dependency_Description\"><span style='color: #FF8A00;'>$Dependency_Name</span> <span style='color: #00FF00;'>[Rev. $Dependency_Revision]</span></a>, ";
		}
		if ($Command_Set_Dependencies) {
			$Command_Set_Dependencies =~ s/,\s$//;
			$Command_Set_Dependencies = '<br />Deps: ' . $Command_Set_Dependencies;
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
			$Held_Running_Command =~ s/(#{1,}[\s\w'"`,.!\?\/\\]*)(.*)/<span style='color: #FFC600;'>$1<\/span>$2/g;
			$Held_Running_Command =~ s/(\*[A-Z0-9]*)(\s*.*)/<span style='color: #FC64FF;'>$1<\/span>$2/g;

		### / Discover Currently Running Command

		my $Control_Button;
		my $Kill_Button;
		if ($Status == 0) {
			$Running_Command = 'None, Job Complete.';
			$Status = 'Job Complete';
			$Control_Button = '<img src="/resources/imgs/confirm.png" alt="Job Complete" >';
			$Kill_Button = "<img src=\"/resources/imgs/grey.png\" alt=\"Disabled\" >";
			$Table->setCellClass ($Job_Row_Count, 9, 'tbrowdarkgreen');
		}
		elsif ($Status == 1) {
			$Running_Command = $Held_Running_Command;
			$Status = 'Running';
			$Control_Button = "<a href='/D-Shell/jobs.cgi?Pause_Job=$DBID'><img src=\"/resources/imgs/pause.png\" alt=\"Pause Job ID $DBID\" ></a>";
			$Kill_Button = "<a href='/D-Shell/jobs.cgi?Stop_Job=$DBID'><img src=\"/resources/imgs/red.png\" alt=\"Stop Job ID $DBID\" ></a>";
		}
		elsif ($Status == 2) {
			$Running_Command = 'None, Processing Paused...';
			$Status = 'Paused';
			$Control_Button = "<a href='/D-Shell/jobs.cgi?Resume_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
			$Kill_Button = "<a href='/D-Shell/jobs.cgi?Stop_Job=$DBID'><img src=\"/resources/imgs/red.png\" alt=\"Stop Job ID $DBID\" ></a>";
		}
		elsif ($Status == 3) {
			$Running_Command = 'This job was killed manually.';
			$Status = 'Killed';
			$Control_Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
			$Kill_Button = "<img src=\"/resources/imgs/grey.png\" alt=\"Disabled\" >";
		}
		elsif ($Status == 4) {
			$Running_Command = 'None, Job Pending.';
			$Status = 'Pending';
			$Control_Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
			$Kill_Button = "<a href='/D-Shell/jobs.cgi?Stop_Job=$DBID'><img src=\"/resources/imgs/red.png\" alt=\"Stop Job ID $DBID\" ></a>";
		}
		elsif ($Status == 5) {
			$Running_Command = 'Job Failed! Connection timout, network or host resolution problems and an unwritable log file are the most likely causes. Try running it manually.';
			$Status = 'Error';
			$Control_Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
			$Kill_Button = "<img src=\"/resources/imgs/grey.png\" alt=\"Disabled\" >";
		}
		elsif ($Status == 6) {
			$Running_Command = 'Job Failed! Bad credentials are the most likely cause. Try running it manually.';
			$Status = 'Error';
			$Control_Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
			$Kill_Button = "<img src=\"/resources/imgs/grey.png\" alt=\"Disabled\" >";
		}
		elsif ($Status == 7) {
			$Running_Command = 'Job Failed! Bailed out on unmatched WAITFOR. Check the log for what appeared.';
			$Status = 'Error';
			$Control_Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
			$Kill_Button = "<img src=\"/resources/imgs/grey.png\" alt=\"Disabled\" >";
		}
		elsif ($Status == 8) {
			$Running_Command = 'Execution Failed! User Name not caught.';
			$Status = 'Error';
			$Control_Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
			$Kill_Button = "<img src=\"/resources/imgs/grey.png\" alt=\"Disabled\" >";
		}
		elsif ($Status == 9) {
			$Running_Command = 'Execution Failed! Password not caught.';
			$Status = 'Error';
			$Control_Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
			$Kill_Button = "<img src=\"/resources/imgs/grey.png\" alt=\"Disabled\" >";
		}
		elsif ($Status == 10) {
			$Running_Command = $Held_Running_Command;
			$Status = 'Starting...';
			$Control_Button = "<a href='/D-Shell/jobs.cgi?Pause_Job=$DBID'><img src=\"/resources/imgs/pause.png\" alt=\"Pause Job ID $DBID\" ></a>";
			$Kill_Button = "<a href='/D-Shell/jobs.cgi?Stop_Job=$DBID'><img src=\"/resources/imgs/red.png\" alt=\"Stop Job ID $DBID\" ></a>";
		}
		elsif ($Status == 11) {
			$Running_Command = 'On failure set to kill. Failure condition met - job killed.';
			$Status = 'Killed';
			$Control_Button = "<a href='/D-Shell/jobs.cgi?Run_Job=$DBID'><img src=\"/resources/imgs/forward.png\" alt=\"Run Job ID $DBID\" ></a>";
			$Kill_Button = "<img src=\"/resources/imgs/grey.png\" alt=\"Stop Job ID $DBID\" >";
		}
		else {
			$Running_Command = 'Unhandled exit code. This is not supposed to happen.';
			$Status = 'Error';
			$Control_Button = "<img src=\"/resources/imgs/delete.png\" alt=\"Something bad happened :(\" >";
			$Kill_Button = "<a href='/D-Shell/jobs.cgi?Stop_Job=$DBID'><img src=\"/resources/imgs/red.png\" alt=\"Stop Job ID $DBID\" ></a>";
		}

		if ($On_Failure) {
			$On_Failure = 'Kill Job';
		}
		else {
			$On_Failure = 'Continue Job';
		}

		$Table->addRow(
			$DBID,
			$Host_Name,
			"$Command_Name $Command_Set_Dependencies",
			$Running_Command,
			$On_Failure,
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
			$Control_Button,
			$Kill_Button
		);

		if ($Status eq 'Job Complete') {$Table->setCellClass ($Job_Row_Count, 6, 'tbrowdarkgreen');}
		if ($Status eq 'Running') {$Table->setCellClass ($Job_Row_Count, 6, 'tbrowgreen');}
		if ($Status eq 'Killed') {$Table->setCellClass ($Job_Row_Count, 6, 'tbrowerror');}
		if ($Status eq 'Starting...') {$Table->setCellClass ($Job_Row_Count, 6, 'tbrowgreen');}
		if ($Status eq 'Paused') {$Table->setCellClass ($Job_Row_Count, 6, 'tbroworange');}
		if ($Status eq 'Pending') {$Table->setCellClass ($Job_Row_Count, 6, 'tbrowgrey');}
		if ($Status eq 'Error') {$Table->setCellClass ($Job_Row_Count, 6, 'tbrowerror');}

	}


	$Table->setColWidth(1, '1px');
	$Table->setColWidth(5, '90px');
	$Table->setColWidth(6, '90px');
	$Table->setColWidth(7, '110px');
	$Table->setColWidth(8, '110px');
	$Table->setColWidth(9, '1px');
	$Table->setColWidth(10, '1px');
	$Table->setColWidth(11, '1px');

	$Table->setColAlign(1, 'center');
	for (5..11) {
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