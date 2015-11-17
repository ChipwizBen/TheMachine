#!/usr/bin/perl

use strict;
use HTML::Table;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_Management = DB_Management();
my $DB_Sudoers = DB_Sudoers();
my ($CGI, $Session, $Cookie) = CGI();
my ($Distribution_Default_SFTP_Port,
	$Distribution_Default_User,
	$Distribution_Default_Key_Path, 
	$Distribution_Default_Timeout,
	$Distribution_Default_Remote_Sudoers) = Distribution_Defaults();
my $Sudoers_Location = Sudoers_Location();
my $md5sum = md5sum();
my $cut = cut();

my $Edit_Host_Parameters = $CGI->param("Edit_Host_Parameters");

my $Edit_Host_Parameters_Post = $CGI->param("Edit_Host_Parameters_Post");
	my $SFTP_Port_Edit = $CGI->param("SFTP_Port_Edit");
		$SFTP_Port_Edit =~ s/\s//g;
		$SFTP_Port_Edit =~ s/[^0-9]//g;
	my $User_Edit = $CGI->param("User_Edit");
		$User_Edit =~ s/\s//g;
		$User_Edit =~ s/[^a-zA-Z0-9\-\.\_]//g;
	my $Key_Path_Edit = $CGI->param("Key_Path_Edit");
	my $Timeout_Edit = $CGI->param("Timeout_Edit");
		$Timeout_Edit =~ s/\s//g;
		$Timeout_Edit =~ s/[^0-9]//g;
	my $Remote_Sudoers_Path_Edit = $CGI->param("Remote_Sudoers_Path_Edit");
	my $Host_Name_Edit = $CGI->param("Host_Name_Edit");
	my $IP_Edit = $CGI->param("IP_Edit");

my $User_Name = $Session->param("User_Name");
my $User_Admin = $Session->param("User_Admin");

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

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}

if ($Edit_Host_Parameters) {
	if ($User_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to edit that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /distribution-status.cgi\n\n";
		exit(0);
	}
	require $Header;
	&html_output;
	require $Footer;
	&html_edit_host_parameters;
}
elsif ($Edit_Host_Parameters_Post) {
	if ($User_Admin != 1) {
		my $Message_Red = 'Nice try.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /distribution-status.cgi\n\n";
		exit(0);
	}
	&edit_host_parameters;
	my $Message_Green="$Host_Name_Edit ($IP_Edit) distribution parameters edited successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /distribution-status.cgi\n\n";
	exit(0);
}
else {
	require $Header;
	&html_output;
	require $Footer;	
}

sub html_edit_host_parameters {

	my $Select_Parameters = $DB_Management->prepare("SELECT `sftp_port`, `user`, `key_path`, `timeout`, `remote_sudoers_path`
		FROM `distribution`
		WHERE `host_id` = ?");

	$Select_Parameters->execute($Edit_Host_Parameters);

	while ( my @DB_Parameters = $Select_Parameters->fetchrow_array() )
	{

		my $SFTP_Port = $DB_Parameters[0];
		my $User = $DB_Parameters[1];
		my $Key_Path = $DB_Parameters[2];
		my $Timeout = $DB_Parameters[3];
		my $Remote_Sudoers_Path = $DB_Parameters[4];

		my $Select_Host = $DB_Sudoers->prepare("SELECT `hostname`, `ip`, `expires`, `active`
		FROM `hosts`
		WHERE `id` = ?");
		$Select_Host->execute($Edit_Host_Parameters);
	
		while ( my @DB_Host = $Select_Host->fetchrow_array() )
		{
	
			my $Host_Name = $DB_Host[0];
			my $IP = $DB_Host[1];
			my $Expires = $DB_Host[2];
				if ($Expires eq '0000-00-00') {
					$Expires = 'Never';
				}
			my $Active = $DB_Host[3];


print <<ENDHTML;
<div id="wide-popup-box">
<a href="distribution-status.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Host Parameters</h3>


<form action='distribution-status.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Host Name:</td>
		<td style="text-align: left; color: #00FF00;">$Host_Name</td>
	</tr>
	<tr>
		<td style="text-align: right;">IP:</td>
		<td style="text-align: left; color: #00FF00;">$IP</td>
	</tr>
	<tr>
		<td style="text-align: right;">Expires:</td>
		<td style="text-align: left; color: #00FF00;">$Expires</td>
	</tr>
	<tr>
		<td style="text-align: right;">Active:</td>
ENDHTML

if ($Active == 1) {
print <<ENDHTML;
		<td style="text-align: left; color: #00FF00;">Yes</td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: left; color: #00FF00;">No</td>
ENDHTML
}

print <<ENDHTML;
	</tr>
	<tr>
		<td style="text-align: right;">SFTP Port:</td>
		<td style="text-align: left;" colspan="2"><input type='text' style='width: 50px;' name='SFTP_Port_Edit' value='$SFTP_Port' maxlength='128' placeholder="$SFTP_Port" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">User:</td>
		<td style="text-align: left;" colspan="2"><input type='text' style='width: 200px;' name='User_Edit' value='$User' maxlength='128' placeholder="$User" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Key Path:</td>
		<td style="text-align: left;" colspan="2"><input type='text' style='width: 300px;' name='Key_Path_Edit' value='$Key_Path' maxlength='255' placeholder="$Key_Path" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Timeout:</td>
		<td style="text-align: left;" colspan="2"><input type='number' style='width: 50px;' name='Timeout_Edit' value='$Timeout' maxlength='3' placeholder="$Timeout" required>&nbsp;&nbsp;seconds</td>
	</tr>
	<tr>
		<td style="text-align: right;">Remote Sudoers Path:</td>
		<td style="text-align: left;" colspan="2"><input type='text' style='width: 300px;' name='Remote_Sudoers_Path_Edit' value='$Remote_Sudoers_Path' maxlength='255' placeholder="$Remote_Sudoers_Path" required></td>
	</tr>
</table>


<input type='hidden' name='Host_Name_Edit' value='$Host_Name'>
<input type='hidden' name='IP_Edit' value='$IP'>
<input type='hidden' name='Edit_Host_Parameters_Post' value='$Edit_Host_Parameters'>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>User Names must be POSIX compliant.</li>
<li>The User is the SFTP subsystem user on the remote system. You should set up a dedicated user for this.</li>
<li>The Key Path is SSH private key path of the SFTP subsystem User. Use the full system path.</li>
<li>The Timeout is the connection timeout in seconds for stalled or unreachable hosts.</li>
<li>The Remote Sudoers Path is the full system path of the staging sudoers file on $Host_Name, which is picked up by the remote cron job.
If the Remote Server uses chroot, make the Remote Sudoers Path is relative to the chroot (i.e. upload/sudoers instead of /home/transport/upload/sudoers)</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Host Parameters'></div>

</form>

ENDHTML
		}
	}
} # sub html_edit_host_parameters

sub edit_host_parameters {

	my $Update_Parameters = $DB_Management->prepare("UPDATE `distribution` SET
		`sftp_port` = ?,
		`user` = ?,
		`key_path` = ?,
		`timeout` = ?,
		`remote_sudoers_path` = ?,
		`last_modified` = NOW(),
		`modified_by` = ?
		WHERE `host_id` = ?");
		
	$Update_Parameters->execute($SFTP_Port_Edit, $User_Edit, $Key_Path_Edit, $Timeout_Edit, $Remote_Sudoers_Path_Edit, $User_Name, $Edit_Host_Parameters_Post);

	# Audit Log
	my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");
	
	$Audit_Log_Submission->execute("Distribution", "Modify", "$User_Name modified Host ID $Edit_Host_Parameters_Post. The new entry is recorded as Port: $SFTP_Port_Edit, User: $User_Edit, Key Path: $Key_Path_Edit, Timeout: $Timeout_Edit seconds and Remote Sudoers Path: $Remote_Sudoers_Path_Edit.", $User_Name);
	# / Audit Log

} # sub edit_host_parameters

sub html_output {

	my $Referer = $ENV{HTTP_REFERER};

	if ($Referer !~ /distribution-status.cgi/) {
		my $Audit_Log_Submission = $DB_Management->prepare("INSERT INTO `audit_log` (
			`category`,
			`method`,
			`action`,
			`username`
		)
		VALUES (
			?, ?, ?, ?
		)");
	
		$Audit_Log_Submission->execute("Distribution", "View", "$User_Name accessed Distribution Status.", $User_Name);
	}

	my $Table = new HTML::Table(
		-cols=>15,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);

	$Table->addRow( "Host ID", "Host (IP)", "SFTP Port", "User", "Key Path", "Timeout", "Remote Sudoers Path", "Status Message", "Status", "Status Received", "Last Successful Transfer", "Last Successful Deployment", "Last Modified", "Modified By", "Edit" );
	$Table->setRowClass (1, 'tbrow1');

	my $Select_Host_Count = $DB_Sudoers->prepare("SELECT `id` FROM `hosts`");
		$Select_Host_Count->execute( );
		my $Total_Rows = $Select_Host_Count->rows();

	my $Select_Parameters = $DB_Management->prepare("SELECT `host_id`, `sftp_port`, `user`, `key_path`, `timeout`, `remote_sudoers_path`, `status`, `last_updated`, `last_successful_transfer`, `last_checkin`, `last_modified`, `modified_by`
		FROM `distribution`
		ORDER BY `last_updated` DESC
		LIMIT 0 , $Rows_Returned");

	$Select_Parameters->execute();
	my $Rows = $Select_Parameters->rows();

	while ( my @Select_Parameters = $Select_Parameters->fetchrow_array() )
	{

		my $Host_ID = $Select_Parameters[0];
		my $SFTP_Port = $Select_Parameters[1];
		my $User = $Select_Parameters[2];
		my $Key_Path = $Select_Parameters[3];
		my $Timeout = $Select_Parameters[4];
		my $Remote_Sudoers = $Select_Parameters[5];
		my $Status_Message = $Select_Parameters[6];
			my $Status_Light;
			if ($Status_Message =~ /^OK/) {$Status_Light = 'OK'} else {$Status_Light = 'Error'}
			$Status_Message =~ s/\n/<br \/>/g;
			$Status_Message =~ s/^OK:(.*)/<span style='color: #00FF00'>OK:<\/span>$1/g;
			$Status_Message =~ s/Sudoers MD5:(.*)/<br \/><span style='color: #00FF00'>Sudoers MD5:<\/span><span style='color: #BDBDBD'>$1<\/span>/g;
			$Status_Message =~ s/(.*)Failed:/<span style='color: #FF0000'>$1Failed: <\/span>/g;
			$Status_Message =~ s/Hints:(.*)/<span style='color: #FFC600'>Hints:<\/span><span style='color: #BDBDBD'>$1<\/span>/g;
			$Status_Message =~ s/\s(\d\))/<span style='color: #FFC600'>$1<\/span>/gm;
		my $Last_Updated = $Select_Parameters[7];
			if ($Last_Updated eq '0000-00-00 00:00:00') {$Last_Updated = 'Never';}
		my $Last_Successful_Transfer = $Select_Parameters[8];
			if ($Last_Successful_Transfer eq '0000-00-00 00:00:00') {$Last_Successful_Transfer = 'Never';}
		my $Last_Successful_Checkin = $Select_Parameters[9];
			if ($Last_Successful_Checkin eq '0000-00-00 00:00:00') {$Last_Successful_Checkin = 'Unknown';}
		my $Last_Modified = $Select_Parameters[10];
			if ($Last_Modified eq '0000-00-00 00:00:00') {$Last_Modified = 'Never';}
		my $Modified_By = $Select_Parameters[11];


		my $Select_Host = $DB_Sudoers->prepare("SELECT `hostname`, `ip`
			FROM `hosts`
			WHERE `id` = ?
		");
		$Select_Host->execute($Host_ID);

		while ( my ($Host_Name, $IP) = $Select_Host->fetchrow_array() )
		{

			$Table->addRow(
				$Host_ID,
				"<a href='sudoers-hosts.cgi?ID_Filter=$Host_ID'>$Host_Name ($IP)</a>",
				$SFTP_Port,
				$User,
				$Key_Path,
				$Timeout,
				$Remote_Sudoers,
				$Status_Message,
				$Status_Light,
				$Last_Updated,
				$Last_Successful_Transfer,
				$Last_Successful_Checkin,
				$Last_Modified,
				$Modified_By,
				"<a href='distribution-status.cgi?Edit_Host_Parameters=$Host_ID'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Host Parameters $Host_ID\" ></a>"
			);
		
			if ($Status_Light eq 'OK') {
				$Table->setCellClass (-1, 9, 'tbrowgreen');
			}
			else {
				$Table->setCellClass (-1, 9, 'tbrowerror');
			}
	
			$Table->setColWidth(1, '1px');
			$Table->setColWidth(10, '110px');
			$Table->setColWidth(11, '110px');
			$Table->setColWidth(12, '110px');
			$Table->setColWidth(13, '110px');
			$Table->setColWidth(14, '110px');
			$Table->setColWidth(15, '1px');
	
			$Table->setColAlign(1, 'center');
			$Table->setColAlign(3, 'center');
			$Table->setColAlign(6, 'center');
			$Table->setColAlign(9, 'center');
			$Table->setColAlign(10, 'center');
			$Table->setColAlign(11, 'center');
			$Table->setColAlign(12, 'center');
			$Table->setColAlign(13, 'center');
			$Table->setColAlign(14, 'center');
			$Table->setColAlign(15, 'center');
		}
	}

	my $MD5_Checksum = `$md5sum $Sudoers_Location | $cut -d ' ' -f 1`;
		$MD5_Checksum = "Current sudoers MD5 checksum: " . "<span style='color: #00FF00;'>$MD5_Checksum</span>";

print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: left;">
			<table cellpadding="3px">
			<form action='distribution-status.cgi' method='post' >
				<tr>
					<td colspan="3" align="left">
						<table width="100%">
							<tr>
								<td colspan="2" style='font-size: 15px;'>
									Distribution Defaults
								</td>
							</tr>
							<tr>
								<td style='width: 90px;'>SFTP Port:</td>
								<td style='color: #00FF00;'>$Distribution_Default_SFTP_Port</td>
							</tr>
							<tr>
								<td>User:</td>
								<td style='color: #00FF00;'>$Distribution_Default_User</td>
							</tr>
							<tr>
								<td>Key Path:</td>
								<td style='color: #00FF00;'>$Distribution_Default_Key_Path</td>
							</tr>
							<tr>
								<td>Timeout:</td>
								<td style='color: #00FF00;'>$Distribution_Default_Timeout</td>
							</tr>
							<tr>
								<td>Remote Sudoers:</td>
								<td style='text-align: left; color: #00FF00;'>$Distribution_Default_Remote_Sudoers</td>
							</tr>
							<tr>
								<td colspan="2">
									<br />Hosts are order with the latest Status Received message first.
								</td>
							</td>
						</table>
					</td>
				</tr>
				<tr>
					<td style="text-align: left;">Returned Rows:</td>
					<td colspan="2" style="text-align: left;">
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
			</form>
			</table>
		</td>
		<td align="right">
			<form action='distribution-status.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Host Parameters</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Host' value='Edit Host Parameters'></td>
					<td align="center">
						<select name='Edit_Host_Parameters' style="width: 150px">
ENDHTML

						my $Host_List_Query = $DB_Sudoers->prepare("SELECT `id`, `hostname`
						FROM `hosts`
						ORDER BY `hostname` ASC");
						$Host_List_Query->execute( );
						
						while ( (my $ID, my $Host_Name) = my @Host_List_Query = $Host_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Host_Name</option>";
						}

print <<ENDHTML;
						</select>
					</td>
				</tr>
			</table>
			</form>
		</td>
	</tr>
	<tr>
		<td  align="center" colspan="2">$MD5_Checksum</td>
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">Distribution Status | Hosts Displayed: $Rows of $Total_Rows</p>

$Table
ENDHTML
} # sub html_output