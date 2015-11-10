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
my $DB_IP_Allocation = DB_IP_Allocation();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Host_Type = $CGI->param("Add_Host Type");
	my $Host_Type_Add = $CGI->param("Host_Type_Add");

my $Edit_Host_Type = $CGI->param("Edit_Host Type");
my $Edit_Host_Type_Post = $CGI->param("Edit_Host_Type_Post");
	my $Host_Type_Edit = $CGI->param("Host_Type_Edit");

my $Delete_Host_Type = $CGI->param("Delete_Host Type");
my $Delete_Host_Type_Confirm = $CGI->param("Delete_Host_Type_Confirm");
my $Host_Type_Delete = $CGI->param("Host_Type_Delete");

my $User_Name = $Session->param("User_Name");
my $User_Admin = $Session->param("User_Admin");

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $Filter = $CGI->param("Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}

if ($Add_Host_Type) {
	require $Header;
	&html_output;
	require $Footer;
	&html_add_host_type;
}
elsif ($Host_Type_Add) {
	my $Host_Type_ID = &add_host_type;
	my $Message_Green="$Host_Type_Add added successfully as ID $Host_Type_ID";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /IP/host-types.cgi\n\n";
	exit(0);
}
elsif ($Edit_Host_Type) {
	require $Header;
	&html_output;
	require $Footer;
	&html_edit_host_type;
}
elsif ($Edit_Host_Type_Post) {
	&edit_host_type;
	my $Message_Green="$Host_Type_Edit edited successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /IP/host-types.cgi\n\n";
	exit(0);
}
elsif ($Delete_Host_Type) {
	require $Header;
	&html_output;
	require $Footer;
	&html_delete_host_type;
}
elsif ($Delete_Host_Type_Confirm) {
	&delete_host_type;
	my $Message_Green="$Host_Type_Delete deleted successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /IP/host-types.cgi\n\n";
	exit(0);
}
else {
	require $Header; ## no critic
	&html_output;
	require $Footer;
}



sub html_add_host_type {

my $Date = strftime "%Y-%m-%d", localtime;

print <<ENDHTML;

<div id="small-popup-box">
<a href="/IP/host-types.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Host Type</h3>

<form action='/IP/host-types.cgi' name='Add_Host Type' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Host Type:</td>
		<td colspan="2"><input type='text' name='Host_Type_Add' style="width:100%" maxlength='128' placeholder="CentOS Linux 7" required autofocus></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Host Types must be unique.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Host Type'></div>

</form>

ENDHTML

} #sub html_add_host_type

sub add_host_type {

	my $Host_Type_Insert = $DB_IP_Allocation->prepare("INSERT INTO `host_types` (
		`type`,
		`modified_by`
	)
	VALUES (
		?, ?
	)");

	$Host_Type_Insert->execute($Host_Type_Add, $User_Name);

	my $Host_Type_Insert_ID = $DB_IP_Allocation->{mysql_insertid};

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
	
	$Audit_Log_Submission->execute("Host Types", "Add", "$User_Name added $Host_Type_Add. The system assigned it Host Type ID $Host_Type_Insert_ID.", $User_Name);
	# / Audit Log

	return($Host_Type_Insert_ID);

} # sub add_host_type

sub html_edit_host_type {

	my $Select_Host_Type = $DB_IP_Allocation->prepare("SELECT `type`
	FROM `host_types`
	WHERE `id` = ?");
	$Select_Host_Type->execute($Edit_Host_Type);

	while ( my $Host_Type_Extract = $Select_Host_Type->fetchrow_array() )
	{


print <<ENDHTML;

<div id="small-popup-box">
<a href="/IP/host-types.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Host Type</h3>

<form action='/IP/host-types.cgi' name='Edit_Host Types' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Host Type:</td>
		<td colspan="2"><input type='text' name='Host_Type_Edit' value='$Host_Type_Extract' style="width:100%" maxlength='128' placeholder="$Host_Type_Extract" required autofocus></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Host Types must be unique.</li>
</ul>

<hr width="50%">
<input type='hidden' name='Edit_Host_Type_Post' value='$Edit_Host_Type'>
<div style="text-align: center"><input type=submit name='ok' value='Edit Host Type'></div>

</form>

ENDHTML

	}
} # sub html_edit_host_type

sub edit_host_type {


	my $Update_Host_Type = $DB_IP_Allocation->prepare("UPDATE `host_types` SET
		`type` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		
	$Update_Host_Type->execute($Host_Type_Edit, $User_Name, $Edit_Host_Type_Post);

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

	$Audit_Log_Submission->execute("Host Types", "Modify", "$User_Name modified domain ID $Edit_Host_Type_Post. It is now recorded as $Host_Type_Edit.", $User_Name);
	# / Audit Log

} # sub edit_host_type

sub html_delete_host_type {

	my $Select_Host_Type = $DB_IP_Allocation->prepare("SELECT `type`
	FROM `host_types`
	WHERE `id` = ?");

	$Select_Host_Type->execute($Delete_Host_Type);
	
	while ( my $Host_Type_Extract = $Select_Host_Type->fetchrow_array() )
	{


print <<ENDHTML;
<div id="small-popup-box">
<a href="/IP/host-types.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Host Type</h3>

<form action='/IP/host-types.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this domain?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Host Type:</td>
		<td style="text-align: left; color: #00FF00;">$Host_Type_Extract</td>
	</tr>
</table>

<input type='hidden' name='Delete_Host_Type_Confirm' value='$Delete_Host_Type'>
<input type='hidden' name='Host_Type_Delete' value='$Host_Type_Extract'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Host Type'></div>

</form>

ENDHTML

	}
} # sub html_delete_host_type

sub delete_host_type {

	# Audit Log
	my $Select_Host_Types = $DB_IP_Allocation->prepare("SELECT `type`
		FROM `host_types`
		WHERE `id` = ?");

	$Select_Host_Types->execute($Delete_Host_Type_Confirm);

	while ( my $Host_Type_Extract = $Select_Host_Types->fetchrow_array() )
	{


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

		$Audit_Log_Submission->execute("Host Types", "Delete", "$User_Name deleted host type $Host_Type_Extract, ID $Delete_Host_Type_Confirm.", $User_Name);

	}
	# / Audit Log

	my $Delete_Host_Type = $DB_IP_Allocation->prepare("DELETE from `host_types`
		WHERE `id` = ?");
	
	$Delete_Host_Type->execute($Delete_Host_Type_Confirm);

} # sub delete_host_type

sub html_output {

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


	my $Select_Host_Type_Count = $DB_IP_Allocation->prepare("SELECT `id` FROM `host_types`");
		$Select_Host_Type_Count->execute( );
		my $Total_Rows = $Select_Host_Type_Count->rows();


	my $Select_Host_Types = $DB_IP_Allocation->prepare("SELECT `id`, `type`, `last_modified`, `modified_by`
		FROM `host_types`
		WHERE `id` LIKE ?
		OR `type` LIKE ?
		ORDER BY `type` ASC
		LIMIT 0 , $Rows_Returned"
	);

	$Select_Host_Types->execute("%$Filter%", "%$Filter%");

	my $Rows = $Select_Host_Types->rows();

	$Table->addRow( "ID", "Host Type", "Last Modified", "Modified By", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Host_Type_Row_Count=1;

	while ( my @Select_Host_Types = $Select_Host_Types->fetchrow_array() )
	{

		$Host_Type_Row_Count++;

		my $DBID = $Select_Host_Types[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Host_Type = $Select_Host_Types[1];
			$Host_Type =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Last_Modified = $Select_Host_Types[2];
		my $Modified_By = $Select_Host_Types[3];

		$Table->addRow(
			"$DBID",
			"$Host_Type",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/IP/host-types.cgi?Edit_Host Type=$DBID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Host Type ID $DBID_Clean\" ></a>",
			"<a href='/IP/host-types.cgi?Delete_Host Type=$DBID_Clean'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Host Type ID $DBID_Clean\" ></a>"
		);

	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(3, '110px');
	$Table->setColWidth(4, '110px');
	$Table->setColWidth(5, '1px');
	$Table->setColWidth(6, '1px');

	$Table->setColAlign(1, 'center');
	for (3..6) {
		$Table->setColAlign($_, 'center');
	}



print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/IP/host-types.cgi' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Host Types" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/IP/host-types.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Host Type</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Host Type' value='Add Host Type'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/IP/host-types.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Host Type</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Host Type' value='Edit Host Type'></td>
					<td align="center">
						<select name='Edit_Host Type' style="width: 150px">
ENDHTML

						my $Host_Type_List_Query = $DB_IP_Allocation->prepare("SELECT `id`, `type`
						FROM `host_types`
						ORDER BY `type` ASC");
						$Host_Type_List_Query->execute( );
						
						while ( my ($ID, $Host_Type) = my @Host_Type_List_Query = $Host_Type_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Host_Type</option>";
						}

print <<ENDHTML;
						</select>
					</td>
				</tr>
			</table>
			</form>
		</td>
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">Host Types | Host Types Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output