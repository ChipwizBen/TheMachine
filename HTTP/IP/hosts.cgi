#!/usr/bin/perl

use strict;
use HTML::Table;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_IP_Allocation = DB_IP_Allocation();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Host = $CGI->param("Add_Host");
my $Edit_Host = $CGI->param("Edit_Host");

my $Host_Name_Add = $CGI->param("Host_Name_Add");
	$Host_Name_Add =~ s/\s//g;
	$Host_Name_Add =~ s/[^a-zA-Z0-9\-\.]//g;
my $Host_Type_Add = $CGI->param("Host_Type_Add");

my $Edit_Host_Post = $CGI->param("Edit_Host_Post");
my $Host_Name_Edit = $CGI->param("Host_Name_Edit");
	$Host_Name_Edit =~ s/\s//g;
	$Host_Name_Edit =~ s/[^a-zA-Z0-9\-\.]//g;
my $Host_Type_Edit = $CGI->param("Host_Type_Edit");

my $Delete_Host = $CGI->param("Delete_Host");
my $Delete_Host_Confirm = $CGI->param("Delete_Host_Confirm");
my $Host_Name_Delete = $CGI->param("Host_Name_Delete");

my $User_Name = $Session->param("User_Name");
my $User_Admin = $Session->param("User_Admin");
my $User_Approver = $Session->param("User_Approver");

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $Filter = $CGI->param("Filter");
my $ID_Filter = $CGI->param("ID_Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}

if ($Add_Host) {
	require $Header;
	&html_output;
	require $Footer;
	&html_add_host;
}
elsif ($Host_Name_Add && $Host_Type_Add) {
	my $Host_ID = &add_host;
	my $Message_Green="$Host_Name_Add added successfully as ID $Host_ID";
	$Session->param('Message_Green', $Message_Green);
	print "Location: /IP/hosts.cgi\n\n";
	exit(0);
}
elsif ($Edit_Host) {
	require $Header;
	&html_output;
	require $Footer;
	&html_edit_host;
}
elsif ($Host_Name_Edit && $Host_Type_Edit) {
	&edit_host;
	my $Message_Green="$Host_Name_Edit edited successfully";
	$Session->param('Message_Green', $Message_Green);
	print "Location: /IP/hosts.cgi\n\n";
	exit(0);
}
elsif ($Delete_Host) {
	require $Header;
	&html_output;
	require $Footer;
	&html_delete_host;
}
elsif ($Delete_Host_Confirm) {
	&delete_host;
	my $Message_Green="$Host_Name_Delete deleted successfully";
	$Session->param('Message_Green', $Message_Green);
	print "Location: /IP/hosts.cgi\n\n";
	exit(0);
}
else {
	require $Header;
	&html_output;
	require $Footer;
}



sub html_add_host {

print <<ENDHTML;

<div id="small-popup-box">
<a href="/IP/hosts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Host</h3>

<form action='/IP/hosts.cgi' name='Add_Hosts' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Host Name:</td>
		<td><input type='text' name='Host_Name_Add' style="width:100%" maxlength='128' placeholder="Host Name" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Host Type:</td>
		<td style="text-align: left;">
			<select name='Host_Type_Add' style="width: 300px">
ENDHTML

	my $Host_Type_Query = $DB_IP_Allocation->prepare("SELECT `id`, `name`
	FROM `host_type`
	ORDER BY `name` ASC");
	$Host_Type_Query->execute( );

	while ( (my $ID, my $Type) = my @Type_Query = $Host_Type_Query->fetchrow_array() )
	{
		print "<option value='$ID'>$Type</option>";
	}

print <<ENDHTML
			</select>
		</td>
	</tr>
	<tr>
		<td>Add to DSMS?</td>
		<td><input type='checkbox' name='Host_Sudoers_Add'></td>
	</tr>
	<tr>
		<td>Add to BIND?</td>
		<td><input type='checkbox' name='Host_BIND_Add'></td>
	</tr>
	<tr>
		<td>Add to Icinga?</td>
		<td><input type='checkbox' name='Host_Icinga_Add'></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Host Names must be unique and POSIX compliant.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Host'></div>

</form>

ENDHTML

} #sub html_add_host

sub add_host {

	### Existing Host_Name Check
	my $Existing_Host_Name_Check = $DB_IP_Allocation->prepare("SELECT `id`
		FROM `hosts`
		WHERE `hostname` = ?");
		$Existing_Host_Name_Check->execute($Host_Name_Add);
		my $Existing_Hosts = $Existing_Host_Name_Check->rows();

	if ($Existing_Hosts > 0)  {
		my $Existing_ID;
		while ( my @Select_Host_Names = $Existing_Host_Name_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Host_Names[0];
		}
		my $Message_Red="Host Name: $Host_Name_Add already exists as ID: $Existing_ID";
		$Session->param('Message_Red', $Message_Red);
		print "Location: /IP/hosts.cgi\n\n";
		exit(0);
	}
	### / Existing Host_Name Check

	my $Host_Insert = $DB_IP_Allocation->prepare("INSERT INTO `hosts` (
		`hostname`,
		`type`,
		`modified_by`
	)
	VALUES (
		?, ?, ?
	)");

	$Host_Insert->execute($Host_Name_Add, $Host_Type_Add, $User_Name);

	my $Host_Insert_ID = $DB_IP_Allocation->{mysql_insertid};


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
	
	$Audit_Log_Submission->execute("Hosts", "Add", "$User_Name added $Host_Name_Add. The system assigned it Host ID $Host_Insert_ID.", $User_Name);

	# / Audit Log

	return($Host_Insert_ID);

} # sub add_host

sub html_edit_host {

	my $Select_Host = $DB_IP_Allocation->prepare("SELECT `hostname`, `type`
	FROM `hosts`
	WHERE `id` = ?");
	$Select_Host->execute($Edit_Host);

	while ( my @DB_Host = $Select_Host->fetchrow_array() )
	{

		my $Host_Name_Extract = $DB_Host[0];
		my $Type_Extract = $DB_Host[1];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/IP/hosts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Host</h3>

<form action='/IP/hosts.cgi' name='Edit_Hosts' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Host Name:</td>
		<td colspan="2"><input type='text' name='Host_Name_Edit' style="width:100%" value='$Host_Name_Extract' maxlength='128' placeholder="$Host_Name_Extract" required autofocus></td>
	</tr>
		<td style="text-align: right;">Host Type:</td>
		<td style="text-align: left;">
			<select name='Host_Type_Edit' style="width: 300px">
ENDHTML



	my $Host_Type_Query = $DB_IP_Allocation->prepare("SELECT `id`, `name`
	FROM `host_type`
	ORDER BY `name` ASC");
	$Host_Type_Query->execute( );

	while ( (my $ID, my $Type) = my @Type_Query = $Host_Type_Query->fetchrow_array() )
	{
		if ($ID == $Type_Extract) {
			print "<option style='color: #00FF00;' value='$ID'>$Type</option>";
		}
		else {
			print "<option value='$ID'>$Type</option>";
		}
	}

print <<ENDHTML;
			</select>
		</td>
	</tr>
</table>

<input type='hidden' name='Edit_Host_Post' value='$Edit_Host'>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Host Names must be unique and POSIX compliant.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Host'></div>

</form>

ENDHTML

	}
} # sub html_edit_host

sub edit_host {

	### Existing Host_Name Check
	my $Existing_Host_Name_Check = $DB_IP_Allocation->prepare("SELECT `id`
		FROM `hosts`
		WHERE `hostname` = ?
		AND `id` != ?");
		$Existing_Host_Name_Check->execute($Host_Name_Edit, $Edit_Host_Post);
		my $Existing_Hosts = $Existing_Host_Name_Check->rows();

	if ($Existing_Hosts > 0)  {
		my $Existing_ID;
		while ( my @Select_Host_Names = $Existing_Host_Name_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Host_Names[0];
		}
		my $Message_Red="Host Name: $Host_Name_Edit already exists as ID: $Existing_ID";
		$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
		print "Location: /IP/hosts.cgi\n\n";
		exit(0);
	}
	### / Existing Host_Name Check

	my $Update_Host = $DB_IP_Allocation->prepare("UPDATE `hosts` SET
		`hostname` = ?,
		`type` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		
	$Update_Host->execute($Host_Name_Edit, $Host_Type_Edit, $User_Name, $Edit_Host_Post);

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

	$Audit_Log_Submission->execute("Hosts", "Modify", "$User_Name modified Host ID $Edit_Host_Post. The new entry is recorded as $Host_Name_Edit.", $User_Name);
	# / Audit Log

} # sub edit_host

sub html_delete_host {

	my $Select_Host = $DB_IP_Allocation->prepare("SELECT `hostname`
	FROM `hosts`
	WHERE `id` = ?");

	$Select_Host->execute($Delete_Host);
	
	while ( my @DB_Host = $Select_Host->fetchrow_array() )
	{
	
		my $Host_Name_Extract = $DB_Host[0];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/IP/hosts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Host</h3>

<form action='/IP/hosts.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this host?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Host Name:</td>
		<td style="text-align: left; color: #00FF00;">$Host_Name_Extract</td>
	</tr>
</table>

<input type='hidden' name='Delete_Host_Confirm' value='$Delete_Host'>
<input type='hidden' name='Host_Name_Delete' value='$Host_Name_Extract'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Host'></div>

</form>

ENDHTML

	}
} # sub html_delete_host

sub delete_host {

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


	$Audit_Log_Submission->execute("Hosts", "Delete", "$User_Name deleted Host $Host_Name_Delete, ID $Delete_Host_Confirm.", $User_Name);

	# / Audit Log

	my $Delete_Host = $DB_IP_Allocation->prepare("DELETE from `hosts`
		WHERE `id` = ?");
	
	$Delete_Host->execute($Delete_Host_Confirm);

} # sub delete_host

sub html_output {

	my $Table = new HTML::Table(
		-cols=>7,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);

	my $Select_Host_Count = $DB_IP_Allocation->prepare("SELECT `id` FROM `hosts`");
		$Select_Host_Count->execute( );
		my $Total_Rows = $Select_Host_Count->rows();


	my $Select_Hosts = $DB_IP_Allocation->prepare("SELECT `id`, `hostname`, `type`, `last_modified`, `modified_by`
		FROM `hosts`
			WHERE `id` LIKE ?
			OR `hostname` LIKE ?
		ORDER BY `hostname` ASC
		LIMIT 0 , $Rows_Returned"
	);

	if ($ID_Filter) {
		$Select_Hosts->execute($ID_Filter, '');
	}
	else {
		$Select_Hosts->execute("%$Filter%", "%$Filter%");
	}

	my $Rows = $Select_Hosts->rows();

	$Table->addRow( "ID", "Host Name", "Type", "Assigned Blocks", "Last Modified", "Modified By", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Host_Row_Count=1;

	while ( my @Select_Hosts = $Select_Hosts->fetchrow_array() ) {

		$Host_Row_Count++;

		my $DBID = $Select_Hosts[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($ID_Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Host_Name = $Select_Hosts[1];
			my $Host_Name_Clean = $Host_Name;
			$Host_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Host_Type = $Select_Hosts[2];
		my $Last_Modified = $Select_Hosts[3];
		my $Modified_By = $Select_Hosts[4];

		my $Select_Type = $DB_IP_Allocation->prepare("SELECT `id`, `name`
			FROM `host_type`
			WHERE `id` LIKE ?");
		$Select_Type->execute($Host_Type);
		my $Type = $Select_Type->fetchrow_array();

		my $Select_Block_Links = $DB_IP_Allocation->prepare("SELECT `ip`
			FROM `lnk_hosts_to_ipv4_allocations`
			WHERE `host` = ?");
		$Select_Block_Links->execute($DBID);

		my $Blocks;
		while (my $Block_ID = $Select_Block_Links->fetchrow_array() ) {

			my $Select_Blocks = $DB_IP_Allocation->prepare("SELECT `ip_block`
				FROM `ipv4_allocations`
				WHERE `id` = ?");
			$Select_Blocks->execute($Block_ID);

			while (my $Block = $Select_Blocks->fetchrow_array() ) {

				my $Count_Block_Allocations = $DB_IP_Allocation->prepare("SELECT `id`
					FROM `lnk_hosts_to_ipv4_allocations`
					WHERE `ip` = ?");
				$Count_Block_Allocations->execute($Block_ID);
				my $Total_Block_Allocations = $Count_Block_Allocations->rows();

				if ($Total_Block_Allocations > 1) {
					$Block = "<a href='/IP/ipv4-allocations.cgi?Filter=$Block'><span style='color: #FF6C00;'>$Block</span></a>";
				}
				else {
					$Block = "<a href='/IP/ipv4-allocations.cgi?Filter=$Block'>$Block</a>";
				}
				$Blocks = $Block. ",&nbsp;" . $Blocks;
				
			}
		}

		$Blocks =~ s/,&nbsp;$//;

		$Table->addRow(
			"$DBID",
			"$Host_Name",
			"$Type",
			"$Blocks",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/IP/hosts.cgi?Edit_Host=$DBID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Host ID $DBID_Clean\" ></a>",
			"<a href='/IP/hosts.cgi?Delete_Host=$DBID_Clean'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Host ID $DBID_Clean\" ></a>"
		);

	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(5, '110px');
	$Table->setColWidth(6, '110px');
	$Table->setColWidth(7, '1px');
	$Table->setColWidth(8, '1px');

	$Table->setColAlign(1, 'center');
	for (5..8) {
		$Table->setColAlign($_, 'center');
	}



print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/IP/hosts.cgi' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Hosts" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/IP/hosts.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Host</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Host' value='Add Host'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/IP/hosts.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Host</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Host' value='Edit Host'></td>
					<td align="center">
						<select name='Edit_Host' style="width: 150px">
ENDHTML

						my $Host_List_Query = $DB_IP_Allocation->prepare("SELECT `id`, `hostname`
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
</table>

<p style="font-size:14px; font-weight:bold;">Hosts | Hosts Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output