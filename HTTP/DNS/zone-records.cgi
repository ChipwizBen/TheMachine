#!/usr/bin/perl -T

use strict;
use HTML::Table;
use POSIX qw(strftime);

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Record = $CGI->param("Add_Record");
	my $Record_Source_Add = $CGI->param("Record_Source_Add");
		$Record_Source_Add =~ s/\s//g;
	my $Record_Domain_Add = $CGI->param("Record_Domain_Add");
	$Record_Domain_Add =~ s/\s//g;
	my $Record_TTL_Add = $CGI->param("Record_TTL_Add");
		$Record_TTL_Add =~ s/\s//g;
		if ($Record_TTL_Add <= 0) {$Record_TTL_Add = '86400'}
	my $Record_Type_Add = $CGI->param("Record_Type_Add");
		my $Record_Option_MX_Add = $CGI->param("Record_Option_MX_Add");
		my $Record_Option_SRV_Add = $CGI->param("Record_Option_SRV_Add");
	my $Record_Target_Add = $CGI->param("Record_Target_Add");
		$Record_Target_Add =~ s/\s//g;
	my $Record_Zone_Add = $CGI->param("Record_Zone_Add");
		$Record_Zone_Add =~ s/\s//g;
	my $Expires_Toggle_Add = $CGI->param("Expires_Toggle_Add");
	my $Expires_Date_Add = $CGI->param("Expires_Date_Add");
		$Expires_Date_Add =~ s/\s//g;
		$Expires_Date_Add =~ s/[^0-9\-]//g;
	my $Active_Add = $CGI->param("Active_Add");

my $Edit_Record = $CGI->param("Edit_Record");
my $Edit_Record_Post = $CGI->param("Edit_Record_Post");
	my $Record_Source_Edit = $CGI->param("Record_Source_Edit");
		$Record_Source_Edit =~ s/\s//g;
	my $Record_Domain_Edit = $CGI->param("Record_Domain_Edit");
	$Record_Domain_Edit =~ s/\s//g;
	my $Record_TTL_Edit = $CGI->param("Record_TTL_Edit");
		$Record_TTL_Edit =~ s/\s//g;
	my $Record_Type_Edit = $CGI->param("Record_Type_Edit");
		my $Record_Option_MX_Edit = $CGI->param("Record_Option_MX_Edit");
		my $Record_Option_SRV_Edit = $CGI->param("Record_Option_SRV_Edit");
	my $Record_Target_Edit = $CGI->param("Record_Target_Edit");
		$Record_Target_Edit =~ s/\s//g;
	my $Record_Zone_Edit = $CGI->param("Record_Zone_Edit");
		$Record_Zone_Edit =~ s/\s//g;
	my $Expires_Toggle_Edit = $CGI->param("Expires_Toggle_Edit");
	my $Expires_Date_Edit = $CGI->param("Expires_Date_Edit");
		$Expires_Date_Edit =~ s/\s//g;
		$Expires_Date_Edit =~ s/[^0-9\-]//g;
	my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Record = $CGI->param("Delete_Record");
my $Delete_Record_Confirm = $CGI->param("Delete_Record_Confirm");
my $Record_Name_Delete = $CGI->param("Record_Name_Delete");

my $User_Name = $Session->param("User_Name");
my $User_DNS_Admin = $Session->param("User_DNS_Admin");

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $Filter = $CGI->param("Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}

if ($Add_Record) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/zone-records.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_add_record;
	}
}
elsif ($Record_Source_Add && $Record_Target_Add) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/zone-records.cgi\n\n";
		exit(0);
	}
	else {
		my $Record_ID = &add_record;
		my $Message_Green="$Record_Type_Add record $Record_Source_Add to $Record_Target_Add added successfully as ID $Record_ID";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DNS/zone-records.cgi\n\n";
		exit(0);
	}
}
elsif ($Edit_Record) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/zone-records.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_edit_record;
	}
}
elsif ($Edit_Record_Post) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/zone-records.cgi\n\n";
		exit(0);
	}
	else {
		&edit_record;
		my $Message_Green="$Record_Type_Add record $Record_Source_Edit to $Record_Target_Edit edited successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DNS/zone-records.cgi\n\n";
		exit(0);
	}
}
elsif ($Delete_Record) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/zone-records.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_delete_record;
	}
}
elsif ($Delete_Record_Confirm) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/zone-records.cgi\n\n";
		exit(0);
	}
	else {
		&delete_record;
		my $Message_Green="$Record_Name_Delete record deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DNS/zone-records.cgi\n\n";
		exit(0);
	}
}
else {
	require $Header;
	&html_output;
	require $Footer;
}



sub html_add_record {

my $Date = strftime "%Y-%m-%d", localtime;

print <<ENDHTML;

<div id="small-popup-box">
<a href="/DNS/zone-records.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Record</h3>

<SCRIPT LANGUAGE="JavaScript"><!--
function Expire_Toggle() {
	if(document.Add_Records.Expires_Toggle_Add.checked)
	{
		document.Add_Records.Expires_Date_Add.disabled=false;
	}
	else
	{
		document.Add_Records.Expires_Date_Add.disabled=true;
	}
}
function Record_Options(value) {
	if(value=="MX"){
		document.getElementById('Record_Option_MX_Add').style.display='table-row';
		document.getElementById('Record_Option_SRV_Add').style.display='none';
	}
	else if(value=="SRV"){
		document.getElementById('Record_Option_MX_Add').style.display='none';
		document.getElementById('Record_Option_SRV_Add').style.display='table-row';
	}
	else {
		document.getElementById('Record_Option_MX_Add').style.display='none';
		document.getElementById('Record_Option_SRV_Add').style.display='none';
	}
}
//-->
</SCRIPT>

<form action='/DNS/zone-records.cgi' name='Add_Records' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Record Source:</td>
		<td colspan="2"><input type='text' name='Record_Source_Add' style="width:100%" maxlength='128' placeholder="Source" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Domain:</td>
		<td colspan="2">
			<select name='Record_Domain_Add' style="width: 100%">
ENDHTML

	my $Domain_Query = $DB_Connection->prepare("SELECT `id`, `domain`
	FROM `domains`
	ORDER BY `domain` ASC");
	$Domain_Query->execute( );

	while ( (my $ID, my $Domain)  = $Domain_Query->fetchrow_array() )
	{
		print "<option value='$ID'>$Domain</option>";
	}


print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Time to Live:</td>
		<td colspan="2"><input type='text' name='Record_TTL_Add' style="width:100%" maxlength='6' placeholder="86400"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Record Type:</td>
		<td colspan="2" style="text-align: left;">
			<select name='Record_Type_Add' onchange="Record_Options(this.value);">
				<option value='A'>A</option>
				<option value='AAAA'>AAAA</option>
				<option value='CNAME'>CNAME</option>
				<option value='MX'>MX</option>
				<option value='NS'>NS</option>
				<option value='PTR'>PTR</option>
				<option value='SRV'>SRV</option>
				<option value='TXT'>TXT</option>
			</select>
		</td>
	</tr>
	<tr style="display: none;" id="Record_Option_MX_Add">
		<td style="text-align: right;">MX Priority:</td>
		<td colspan="2"><input type='text' name='Record_Option_MX_Add' style="width:100%" maxlength='2' placeholder="10"></td>
	</tr>
	<tr style="display: none;" id="Record_Option_SRV_Add">
		<td style="text-align: right;">SRV Options:</td>
		<td colspan="2"><input type='text' name='Record_Option_SRV_Add' style="width:100%" maxlength='12' placeholder="10 20 65535"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Target:</td>
		<td colspan="2"><input type='text' name='Record_Target_Add' style="width:100%" maxlength='128' placeholder="Target" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Zone:</td>
		<td colspan="2" style="text-align: left;">
			<select name='Record_Zone_Add'>
				<option value='0'>Internal</option>
				<option value='1'>External</option>
				<option value='2'>Both</option>
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Expires:</td>
		<td><input type="checkbox" onclick="Expire_Toggle()" name="Expires_Toggle_Add"></td>
		<td><input type="text" name="Expires_Date_Add" style="width:100%" value="$Date" placeholder="YYYY-MM-DD" disabled></td>
	</tr>
	<tr>
		<td style="text-align: right;">Active:</td>
		<td style="text-align: right;"><input type="radio" name="Active_Add" value="1" checked> Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Add" value="0"> No</td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Record hostnames and IPs must be POSIX compliant.</li>
<li>Records with an expiry set are automatically removed from DNS at 23:59:59
(or the next DNS refresh thereafter) on the day of expiry. Expired entries are functionally
equivalent to inactive entries. The date entry format is YYYY-MM-DD.</li>
<li>Active records are eligible for DNS inclusion.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Record'></div>

</form>

ENDHTML

} #sub html_add_record

sub add_record {

	if ($Expires_Toggle_Add ne 'on') {
		$Expires_Date_Add = '0000-00-00';
	}

	my $Record_Options_Add;
	if ($Record_Option_MX_Add) {
		$Record_Options_Add = $Record_Option_MX_Add;
	}
	elsif ($Record_Option_SRV_Add) {
		$Record_Options_Add = $Record_Option_SRV_Add;
	}

	my $Record_Insert = $DB_Connection->prepare("INSERT INTO `zone_records` (
		`source`,
		`domain`,
		`time_to_live`,
		`type`,
		`options`,
		`target`,
		`zone`,
		`expires`,
		`active`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?, ?,
		?, ?, ?, ?, ?
	)");

	$Record_Insert->execute($Record_Source_Add, $Record_Domain_Add, $Record_TTL_Add, $Record_Type_Add, $Record_Options_Add, 
	$Record_Target_Add, $Record_Zone_Add, $Expires_Date_Add, $Active_Add, $User_Name);

	my $Record_Insert_ID = $DB_Connection->{mysql_insertid};

	# Audit Log
	if ($Expires_Date_Add eq '0000-00-00') {
		$Expires_Date_Add = 'not expire';
	}
	else {
		$Expires_Date_Add = "expire on " . $Expires_Date_Add;
	}

	if ($Active_Add) {$Active_Add = 'Active'} else {$Active_Add = 'Inactive'}

	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = $DB_Connection->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");
	
	$Audit_Log_Submission->execute("Records", "Add", "$User_Name added $Record_Type_Add record for $Record_Source_Add to $Record_Target_Add, set it $Active_Add and to $Expires_Date_Add. The system assigned it Record ID $Record_Insert_ID.", $User_Name);
	# / Audit Log

	return($Record_Insert_ID);

} # sub add_record

sub html_edit_record {

	my $Select_Record = $DB_Connection->prepare("SELECT `source`, `domain`, `time_to_live`, `type`, `options`, `target`, `zone`,	`expires`, `active`
	FROM `zone_records`
	WHERE `id` = ?");
	$Select_Record->execute($Edit_Record);

	while ( my @DB_Record = $Select_Record->fetchrow_array() )
	{

		my $Source_Extract = $DB_Record[0];
		my $Domain_Extract = $DB_Record[1];
		my $Time_To_Live_Extract = $DB_Record[2];
		my $Type_Extract = $DB_Record[3];
		my $Options_Extract = $DB_Record[4];
		my $Target_Extract = $DB_Record[5];
		my $Zone_Extract = $DB_Record[6];
		my $Expires_Extract = $DB_Record[7];
		my $Active_Extract = $DB_Record[8];

		my $Expires_Checked;
		my $Expires_Disabled;
		if ($Expires_Extract eq '0000-00-00') {
			$Expires_Checked = '';
			$Expires_Disabled = 'disabled';
			$Expires_Extract = strftime "%Y-%m-%d", localtime;
		}
		else {
			$Expires_Checked = 'checked';
			$Expires_Disabled = '';
		}


print <<ENDHTML;

<div id="small-popup-box">
<a href="/DNS/zone-records.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Record</h3>

<SCRIPT LANGUAGE="JavaScript"><!--
function Expire_Toggle() {
	if(document.Edit_Records.Expires_Toggle_Edit.checked)
	{
		document.Edit_Records.Expires_Date_Edit.disabled=false;
	}
	else
	{
		document.Edit_Records.Expires_Date_Edit.disabled=true;
	}
}
function Record_Options(value) {
	if(value=="MX"){
		document.getElementById('Record_Option_MX_Edit').style.display='table-row';
		document.getElementById('Record_Option_SRV_Edit').style.display='none';
	}
	else if(value=="SRV"){
		document.getElementById('Record_Option_MX_Edit').style.display='none';
		document.getElementById('Record_Option_SRV_Edit').style.display='table-row';
	}
	else {
		document.getElementById('Record_Option_MX_Edit').style.display='none';
		document.getElementById('Record_Option_SRV_Edit').style.display='none';
	}
}
//-->
</SCRIPT>

<form action='/DNS/zone-records.cgi' name='Edit_Records' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Record Source:</td>
		<td colspan="2"><input type='text' name='Record_Source_Edit' value='$Source_Extract' style="width:100%" maxlength='128' placeholder="$Source_Extract" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Domain:</td>
		<td colspan="2">
			<select name='Record_Domain_Edit' style="width: 100%">
ENDHTML

	my $Domain_Query = $DB_Connection->prepare("SELECT `id`, `domain`
	FROM `domains`
	ORDER BY `domain` ASC");
	$Domain_Query->execute( );

	while ( (my $ID, my $Domain)  = $Domain_Query->fetchrow_array() )
	{
		if ($Domain_Extract eq $ID) {
			print "<option style='background-color: #009400;' value='$ID' selected>$Domain</option>";
		}
		else {
			print "<option value='$ID'>$Domain</option>";
		}
	}


print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Time to Live:</td>
		<td colspan="2"><input type='text' name='Record_TTL_Edit' value='$Time_To_Live_Extract' style="width:100%" maxlength='6' placeholder="$Time_To_Live_Extract"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Record Type:</td>
		<td colspan="2" style="text-align: left;">
			<select name='Record_Type_Edit' onchange="Record_Options(this.value);">
ENDHTML

if ($Type_Extract eq 'A') {print "<option style='background-color: #009400;' value='A' selected>A</option>"} else {print "<option value='A'>A</option>"}
if ($Type_Extract eq 'AAAA') {print "<option style='background-color: #009400;' value='AAAA' selected>AAAA</option>"} else {print "<option value='AAAA'>AAAA</option>"}
if ($Type_Extract eq 'CNAME') {print "<option style='background-color: #009400;' value='CNAME' selected>CNAME</option>"} else {print "<option value='CNAME'>CNAME</option>"}
if ($Type_Extract eq 'MX') {print "<option style='background-color: #009400;' value='MX' selected>MX</option>"} else {print "<option value='MX'>MX</option>"}
if ($Type_Extract eq 'NS') {print "<option style='background-color: #009400;' value='NS' selected>NS</option>"} else {print "<option value='NS'>NS</option>"}
if ($Type_Extract eq 'PTR') {print "<option style='background-color: #009400;' value='PTR' selected>PTR</option>"} else {print "<option value='PTR'>PTR</option>"}
if ($Type_Extract eq 'SRV') {print "<option style='background-color: #009400;' value='SRV' selected>SRV</option>"} else {print "<option value='SRV'>SRV</option>"}
if ($Type_Extract eq 'TXT') {print "<option style='background-color: #009400;' value='TXT' selected>TXT</option>"} else {print "<option value='TXT'>TXT</option>"}

print <<ENDHTML;
			</select>
		</td>
	</tr>
ENDHTML
if ($Type_Extract eq 'MX') {
	print '<tr style="display: table-row;" id="Record_Option_MX_Edit">';
	print '<td style="text-align: right;">MX Priority:</td>';
	print "<td colspan='2'><input type='text' name='Record_Option_MX_Edit' value='$Options_Extract' style='width:100%;' maxlength='2' placeholder='$Options_Extract'></td>";
}
else {
	print '<tr style="display: none;" id="Record_Option_MX_Edit">';
	print '<td style="text-align: right;">MX Priority:</td>';
	print "<td colspan='2'><input type='text' name='Record_Option_MX_Edit' style='width:100%' maxlength='2' placeholder='10'></td>";
}
		
print <<ENDHTML;
	</tr>
ENDHTML
if ($Type_Extract eq 'SRV') {
	print '<tr style="display: table-row;" id="Record_Option_SRV_Edit">';
	print '<td style="text-align: right;">SRV Options:</td>';
	print "<td colspan='2'><input type='text' name='Record_Option_SRV_Edit' value='$Options_Extract' style='width:100%;' maxlength='12' placeholder='$Options_Extract'></td>";
}
else {
	print '<tr style="display: none;" id="Record_Option_SRV_Edit">';
	print '<td style="text-align: right;">SRV Options:</td>';
	print "<td colspan='2'><input type='text' name='Record_Option_SRV_Edit' style='width:100%' maxlength='12' placeholder='10 20 65535'></td>";
}
		
print <<ENDHTML;
	</tr>
	<tr>
		<td style="text-align: right;">Target:</td>
		<td colspan="2"><input type='text' name='Record_Target_Edit' value='$Target_Extract' style="width:100%" maxlength='128' placeholder="$Target_Extract" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Zone:</td>
		<td colspan="2" style="text-align: left;">
			<select name='Record_Zone_Edit'>
ENDHTML
if ($Zone_Extract == 0) {print "<option style='background-color: #009400;' value='0' selected>Internal</option>"} else {print "<option value='0'>Internal</option>"}
if ($Zone_Extract == 1) {print "<option style='background-color: #009400;' value='1' selected>External</option>"} else {print "<option value='1'>External</option>"}
if ($Zone_Extract == 2) {print "<option style='background-color: #009400;' value='2' selected>Both</option>"} else {print "<option value='2'>Both</option>"}
print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Expires:</td>
		<td><input type="checkbox" onclick="Expire_Toggle()" name="Expires_Toggle_Edit" $Expires_Checked></td>
		<td><input type="text" name="Expires_Date_Edit" style="width:100%" value="$Expires_Extract" placeholder="$Expires_Extract" $Expires_Disabled></td>
	</tr>
	<tr>
		<td style="text-align: right;">Active:</td>
ENDHTML
if ($Active_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="1" checked>Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="0">No</td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="1">Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="0" checked>No</td>
ENDHTML
}
print <<ENDHTML;
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Record hostnames and IPs must be POSIX compliant.</li>
<li>Records with an expiry set are automatically removed from DNS at 23:59:59
(or the next DNS refresh thereafter) on the day of expiry. Expired entries are functionally
equivalent to inactive entries. The date entry format is YYYY-MM-DD.</li>
<li>Active records are eligible for DNS inclusion.</li>
</ul>

<hr width="50%">
<input type='hidden' name='Edit_Record_Post' value='$Edit_Record'>
<div style="text-align: center"><input type=submit name='ok' value='Edit Record'></div>

</form>

ENDHTML

	}
} # sub html_edit_record

sub edit_record {

	if ($Expires_Toggle_Edit ne 'on') {
		$Expires_Date_Edit = '0000-00-00';
	}

	my $Record_Options_Edit;
	if ($Record_Option_MX_Edit && $Record_Type_Edit eq 'MX') {
		$Record_Options_Edit = $Record_Option_MX_Edit;
	}
	elsif ($Record_Option_SRV_Edit && $Record_Type_Edit eq 'SRV') {
		$Record_Options_Edit = $Record_Option_SRV_Edit;
	}

	my $Update_Record = $DB_Connection->prepare("UPDATE `zone_records` SET
		`source` = ?,
		`domain` = ?,
		`time_to_live` = ?,
		`type` = ?,
		`options` = ?,
		`target` = ?,
		`zone` = ?,
		`expires` = ?,
		`active` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		
	$Update_Record->execute($Record_Source_Edit, $Record_Domain_Edit, $Record_TTL_Edit, $Record_Type_Edit, $Record_Options_Edit, 
	$Record_Target_Edit, $Record_Zone_Edit, $Expires_Date_Edit, $Active_Edit, $User_Name, $Edit_Record_Post);

	# Audit Log
	if ($Expires_Date_Edit eq '0000-00-00') {
		$Expires_Date_Edit = 'does not expire';
	}
	else {
		$Expires_Date_Edit = "expires on " . $Expires_Date_Edit;
	}

	if ($Active_Edit) {$Active_Edit = 'Active'} else {$Active_Edit = 'Inactive'}

	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = $DB_Connection->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");

	$Audit_Log_Submission->execute("Records", "Modify", "$User_Name modified record ID $Edit_Record_Post, $Record_Type_Add record for $Record_Source_Edit to $Record_Target_Edit, set it $Active_Edit and to $Expires_Date_Edit.", $User_Name);
	# / Audit Log

} # sub edit_record

sub html_delete_record {

	my $Select_Record = $DB_Connection->prepare("SELECT `source`, `type`, `target`
	FROM `zone_records`
	WHERE `id` = ?");

	$Select_Record->execute($Delete_Record);
	
	while ( my @DB_Record = $Select_Record->fetchrow_array() )
	{
	
		my $Source_Extract = $DB_Record[0];
		my $Type_Extract = $DB_Record[1];
		my $Target_Extract = $DB_Record[2];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/DNS/zone-records.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Record</h3>

<form action='/DNS/zone-records.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this record?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Type:</td>
		<td style="text-align: left; color: #00FF00;">$Type_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Source:</td>
		<td style="text-align: left; color: #00FF00;">$Source_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Target:</td>
		<td style="text-align: left; color: #00FF00;">$Target_Extract</td>
	</tr>
</table>

<input type='hidden' name='Delete_Record_Confirm' value='$Delete_Record'>
<input type='hidden' name='Record_Name_Delete' value='$Type_Extract'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Record'></div>

</form>

ENDHTML

	}
} # sub html_delete_record

sub delete_record {

	# Audit Log
	my $Select_Records = $DB_Connection->prepare("SELECT `source`, `type`, `target`, `expires`, `active`
		FROM `zone_records`
		WHERE `id` = ?");

	$Select_Records->execute($Delete_Record_Confirm);

	while ( my ( $Source, $Type, $Target, $Expires, $Active ) = $Select_Records->fetchrow_array() )
	{

		if ($Expires eq '0000-00-00') {
			$Expires = 'does not expire';
		}
		else {
			$Expires = "expires on " . $Expires;
		}
	
		if ($Active) {$Active = 'Active'} else {$Active = 'Inactive'}

		my $DB_Connection = DB_Connection();
		my $Audit_Log_Submission = $DB_Connection->prepare("INSERT INTO `audit_log` (
			`category`,
			`method`,
			`action`,
			`username`
		)
		VALUES (
			?, ?, ?, ?
		)");

		$Audit_Log_Submission->execute("Records", "Delete", "$User_Name deleted record ID $Delete_Record_Confirm. The deleted entry's last values were Type: $Type, Source: $Source, Target: $Target, set $Active and $Expires.", $User_Name);

	}
	# / Audit Log

	my $Delete_Record = $DB_Connection->prepare("DELETE from `zone_records`
		WHERE `id` = ?");
	
	$Delete_Record->execute($Delete_Record_Confirm);

} # sub delete_record

sub html_output {

	my $Table = new HTML::Table(
		-cols=>14,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);


	my $Select_Record_Count = $DB_Connection->prepare("SELECT `id` FROM `zone_records`");
		$Select_Record_Count->execute( );
		my $Total_Rows = $Select_Record_Count->rows();


	my $Select_Records = $DB_Connection->prepare("SELECT `id`, `source`, `domain`, `time_to_live`, `type`, `options`, 
	`target`, `zone`, `expires`, `active`, `last_modified`, `modified_by`
		FROM `zone_records`
			WHERE `id` LIKE ?
			OR `source` LIKE ?
			OR `time_to_live` LIKE ?
			OR `type` LIKE ?
			OR `target` LIKE ?
			OR `expires` LIKE ?
		ORDER BY `source` ASC
		LIMIT ?, ?"
	);

	$Select_Records->execute("%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", 0, $Rows_Returned);

	my $Rows = $Select_Records->rows();

	$Table->addRow( "ID", "Source", "Domain", "TTL", "Type", "Options", "Target", "Zone", "Expires", "Active", "Last Modified", "Modified By", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Record_Row_Count=1;

	while ( my @Select_Records = $Select_Records->fetchrow_array() )
	{

		$Record_Row_Count++;

		my $DBID = $Select_Records[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Source = $Select_Records[1];
			my $Source_Clean = $Source;
			$Source =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Domain = $Select_Records[2];
		my $TTL = $Select_Records[3];
			$TTL =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Type = $Select_Records[4];
			$Type =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Options = $Select_Records[5];
		my $Target = $Select_Records[6];
			$Target =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Zone = $Select_Records[7];
		my $Expires = $Select_Records[8];
			my $Expires_Clean = $Expires;
			$Expires =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Active = $Select_Records[9];
			if ($Active == 1) {$Active = "Yes"} else {$Active = "No"};
		my $Last_Modified = $Select_Records[10];
		my $Modified_By = $Select_Records[11];

		my $Resolve_Domain = $DB_Connection->prepare("SELECT `domain`
			FROM `domains`
			WHERE `id` LIKE ?"
		);

		$Resolve_Domain->execute($Domain);
		$Domain = $Resolve_Domain->fetchrow_array();

		my $Expires_Epoch;
		my $Today_Epoch = time;
		if ($Expires_Clean =~ /^0000-00-00$/) {
			$Expires = 'Never';
		}
		else {
			$Expires_Epoch = str2time("$Expires_Clean"."T23:59:59");
		}

		if ($Zone == 0) {
			$Zone = 'Internal';
		}
		elsif ($Zone == 1) {
			$Zone = 'External';
		}
		elsif ($Zone == 2) {
			$Zone = 'Both';
		}

		$Table->addRow(
			"$DBID",
			"$Source",
			"$Domain",
			"$TTL",
			"$Type",
			"$Options",
			"$Target",
			"$Zone",
			"$Expires",
			"$Active",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/DNS/zone-records.cgi?Edit_Record=$DBID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Record ID $DBID_Clean\" ></a>",
			"<a href='/DNS/zone-records.cgi?Delete_Record=$DBID_Clean'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Record ID $DBID_Clean\" ></a>"
		);

		if ($Zone eq 'Internal') {
			$Table->setCellClass ($Record_Row_Count, 8, 'tbrowgreen');
		}
		elsif ($Zone eq 'External') {
			$Table->setCellClass ($Record_Row_Count, 8, 'tbroworange');
		}
		elsif ($Zone eq 'Both') {
			$Table->setCellClass ($Record_Row_Count, 8, 'tbrowpurple');
		}
		else {
			$Table->setCellClass ($Record_Row_Count, 8, 'tbrowred');
		}

		if ($Active eq 'Yes') {
			$Table->setCellClass ($Record_Row_Count, 10, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($Record_Row_Count, 10, 'tbrowred');
		}

		if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
			$Table->setCellClass ($Record_Row_Count, 9, 'tbrowdisabled');
		}

	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(4, '1px');
	$Table->setColWidth(5, '1px');
	$Table->setColWidth(6, '70px');
	$Table->setColWidth(8, '60px');
	$Table->setColWidth(9, '60px');
	$Table->setColWidth(10, '1px');
	$Table->setColWidth(11, '110px');
	$Table->setColWidth(12, '110px');
	$Table->setColWidth(13, '1px');
	$Table->setColWidth(14, '1px');

	$Table->setColAlign(1, 'center');
	$Table->setColAlign(4, 'center');
	$Table->setColAlign(5, 'center');
	$Table->setColAlign(6, 'center');
	for (8..14) {
		$Table->setColAlign($_, 'center');
	}



print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/DNS/zone-records.cgi' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Records" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/DNS/zone-records.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Record</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Record' value='Add Record'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/DNS/zone-records.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Record</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Record' value='Edit Record'></td>
					<td align="center">
						<select name='Edit_Record' style="width: 150px">
ENDHTML

						my $Record_List_Query = $DB_Connection->prepare("SELECT `id`, `source`, `type`, `target`
						FROM `zone_records`
						ORDER BY `source` ASC");
						$Record_List_Query->execute( );
						
						while ( my ($ID, $Record_Source, $Record_Type, $Record_Target) = my @Record_List_Query = $Record_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Record_Source ($Record_Type) $Record_Target</option>";
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

<p style="font-size:14px; font-weight:bold;">Records | Records Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output