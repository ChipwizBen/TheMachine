#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);

use HTML::Table;
use Date::Parse qw(str2time);
use POSIX qw(strftime);

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Service = $CGI->param("Add_Service");
my $Edit_Service = $CGI->param("Edit_Service");

my $User_Name_Add = $CGI->param("Service_Name_Add");
	$User_Name_Add =~ s/\s//g;
	$User_Name_Add =~ s/[^a-zA-Z0-9\-\.\_]//g;
my $Expires_Toggle_Add = $CGI->param("Expires_Toggle_Add");
my $Expires_Date_Add = $CGI->param("Expires_Date_Add");
	$Expires_Date_Add =~ s/\s//g;
	$Expires_Date_Add =~ s/[^0-9\-]//g;
my $Active_Add = $CGI->param("Active_Add");

my $Edit_Service_Post = $CGI->param("Edit_Service_Post");
my $User_Name_Edit = $CGI->param("Service_Name_Edit");
	$User_Name_Edit =~ s/\s//g;
	$User_Name_Edit =~ s/[^a-zA-Z0-9\-\.\_]//g;
my $Expires_Toggle_Edit = $CGI->param("Expires_Toggle_Edit");
my $Expires_Date_Edit = $CGI->param("Expires_Date_Edit");
	$Expires_Date_Edit =~ s/\s//g;
	$Expires_Date_Edit =~ s/[^0-9\-]//g;
my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Service = $CGI->param("Delete_Service");
my $Delete_Service_Confirm = $CGI->param("Delete_Service_Confirm");
my $User_Name_Delete = $CGI->param("Service_Name_Delete");

my $Show_Links = $CGI->param("Show_Links");
my $Show_Links_Name = $CGI->param("Show_Links_Name");

my $View_Notes = $CGI->param("View_Notes");
my $New_Note = $CGI->param("New_Note");
my $New_Note_ID = $CGI->param("New_Note_ID");

my $User_Name = $Session->param("User_Name");
my $User_IP_Admin = $Session->param("User_IP_Admin");

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

if ($Add_Service) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_add_service;
	}
}
elsif ($User_Name_Add) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
	else {
		my $Service_ID = &add_service;
		my $Message_Green="$User_Name_Add added successfully as ID $Service_ID";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
}
elsif ($Edit_Service) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_edit_service;
	}
}
elsif ($Edit_Service_Post) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
	else {
		&edit_service;
		my $Message_Green="$User_Name_Edit edited successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
}
elsif ($Delete_Service) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_delete_service;
	}
}
elsif ($Delete_Service_Confirm) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
	else {
		&delete_service;
		my $Message_Green="$User_Name_Delete deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
}
elsif ($Show_Links) {
	require $Header;
	&html_output;
	require $Footer;
	&html_show_links;
}
elsif ($View_Notes) {
	require $Header;
	&html_output;
	require $Footer;
	&html_notes;
}
elsif ($New_Note && $New_Note_ID) {
	&add_note;
	require $Header;
	&html_output;
	require $Footer;
	$View_Notes = $New_Note_ID;
	&html_notes;
}
else {
	require $Header;
	&html_output;
	require $Footer;
}



sub html_add_service {

my $Date = strftime "%Y-%m-%d", localtime;

print <<ENDHTML;
<div id="small-popup-box">
<a href="/IP/services.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Service</h3>

<SCRIPT LANGUAGE="JavaScript"><!--
function Expire_Toggle() {
	if(document.Add_Services.Expires_Toggle_Add.checked)
	{
		document.Add_Services.Expires_Date_Add.disabled=false;
	}
	else
	{
		document.Add_Services.Expires_Date_Add.disabled=true;
	}
}
//-->
</SCRIPT>

<form action='/IP/services.cgi' name='Add_Services' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Service Name:</td>
		<td colspan="2"><input type='text' name='Service_Name_Add' style="width:100%" maxlength='128' placeholder="Service Name" required autofocus></td>
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
<li>Service Names must be unique and POSIX compliant.</li>
<li>Services with an expiry set are automatically removed from sudoers at 23:59:59
(or the next sudoers refresh thereafter) on the day of expiry. Expired entries are functionally
equivalent to inactive entries. The date entry format is YYYY-MM-DD.</li>
<li>Active services are eligible for sudoers inclusion.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Service'></div>

</form>

ENDHTML

} #sub html_add_service

sub add_service {

	### Existing Service_Name Check
	my $Existing_Service_Name_Check = $DB_Connection->prepare("SELECT `id`
		FROM `services`
		WHERE `service` = ?");
		$Existing_Service_Name_Check->execute($User_Name_Add);
		my $Existing_Services = $Existing_Service_Name_Check->rows();

	if ($Existing_Services > 0)  {
		my $Existing_ID;
		while ( my @Select_Service_Names = $Existing_Service_Name_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Service_Names[0];
		}
		my $Message_Red="Service_Name: $User_Name_Add already exists as ID: $Existing_ID";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
	### / Existing Service_Name Check

	if ($Expires_Toggle_Add ne 'on') {
		$Expires_Date_Add = undef;
	}

	my $Service_Insert = $DB_Connection->prepare("INSERT INTO `services` (
		`id`,
		`service`,
		`expires`,
		`active`,
		`modified_by`
	)
	VALUES (
		NULL,
		?,
		?,
		?,
		?
	)");

	$Service_Insert->execute($User_Name_Add, $Expires_Date_Add, $Active_Add, $User_Name);

	my $Service_Insert_ID = $DB_Connection->{mysql_insertid};

	# Audit Log
	if (!$Expires_Date_Add || $Expires_Date_Add eq '0000-00-00') {
		$Expires_Date_Add = 'not expire';
	}
	else {
		$Expires_Date_Add = "expire on " . $Expires_Date_Add;
	}

	if ($Active_Add) {$Active_Add = 'Active'} else {$Active_Add = 'Inactive'}

	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();
	
	$Audit_Log_Submission->execute("Services", "Add", "$User_Name added $User_Name_Add, set it $Active_Add and to $Expires_Date_Add. The system assigned it Service ID $Service_Insert_ID.", $User_Name);
	# / Audit Log

	return($Service_Insert_ID);

} # sub add_service

sub html_edit_service {

	my $Select_Service = $DB_Connection->prepare("SELECT `service`, `expires`, `active`
	FROM `services`
	WHERE `id` = ?");
	$Select_Service->execute($Edit_Service);
	
	while ( my @DB_Service = $Select_Service->fetchrow_array() )
	{
	
		my $User_Name_Extract = $DB_Service[0];
		my $Expires_Extract = $DB_Service[1];
		my $Active_Extract = $DB_Service[2];

		my $Checked;
		my $Disabled;
		if (!$Expires_Extract || $Expires_Extract eq '0000-00-00') {
			$Checked = '';
			$Disabled = 'disabled';
			$Expires_Extract = strftime "%Y-%m-%d", localtime;
		}
		else {
			$Checked = 'checked';
			$Disabled = '';
		}

print <<ENDHTML;
<div id="small-popup-box">
<a href="/IP/services.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Service</h3>

<SCRIPT LANGUAGE="JavaScript"><!--
function Expire_Toggle() {
	if(document.Edit_Services.Expires_Toggle_Edit.checked)
	{
		document.Edit_Services.Expires_Date_Edit.disabled=false;
	}
	else
	{
		document.Edit_Services.Expires_Date_Edit.disabled=true;
	}
}
//-->
</SCRIPT>

<form action='/IP/services.cgi' name='Edit_Services' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Service Name:</td>
		<td colspan="2"><input type='text' name='Service_Name_Edit' style="width:100%" value='$User_Name_Extract' maxlength='128' placeholder="$User_Name_Extract" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Expires:</td>
		<td><input type="checkbox" onclick="Expire_Toggle()" name="Expires_Toggle_Edit" $Checked></td>
		<td><input type="text" name="Expires_Date_Edit" style="width:100%" value="$Expires_Extract" placeholder="$Expires_Extract" $Disabled></td>
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

<input type='hidden' name='Edit_Service_Post' value='$Edit_Service'>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Service Names must be unique and POSIX compliant.</li>
<li>You can only activate a modified service if you are an Approver.
If you are not an Approver and you modify this entry, it will automatically be set to Inactive.</li>
<li>Services with an expiry set are automatically removed from sudoers at 23:59:59
(or the next sudoers refresh thereafter) on the day of expiry. Expired entries are functionally
equivalent to inactive entries. The date entry format is YYYY-MM-DD.</li>
<li>Active services are eligible for sudoers inclusion.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Service'></div>

</form>

ENDHTML

	}
} # sub html_edit_service

sub edit_service {

	### Existing Service_Name Check
	my $Existing_Service_Name_Check = $DB_Connection->prepare("SELECT `id`
		FROM `services`
		WHERE `service` = ?
		AND `id` != ?");
		$Existing_Service_Name_Check->execute($User_Name_Edit, $Edit_Service_Post);
		my $Existing_Services = $Existing_Service_Name_Check->rows();

	if ($Existing_Services > 0)  {
		my $Existing_ID;
		while ( my @Select_Service_Names = $Existing_Service_Name_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Service_Names[0];
		}
		my $Message_Red="Service_Name: $User_Name_Edit already exists as ID: $Existing_ID";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
	### / Existing Service_Name Check

	### Revoke Rule Approval ###

	my $Update_Rule = $DB_Connection->prepare("UPDATE `rules`
	INNER JOIN `lnk_rules_to_services`
	ON `rules`.`id` = `lnk_rules_to_services`.`rule`
	SET
	`modified_by` = '$User_Name',
	`approved` = '0',
	`approved_by` = 'Approval Revoked by $User_Name when modifying Service ID $Edit_Service_Post'
	WHERE `lnk_rules_to_services`.`service` = ?");

	my $Rules_Revoked = $Update_Rule->execute($Edit_Service_Post);

	if ($Rules_Revoked eq '0E0') {$Rules_Revoked = 0}

	### / Revoke Rule Approval ###

	if ($Expires_Toggle_Edit ne 'on') {
		$Expires_Date_Edit = undef;
	}

	my $Update_Service = $DB_Connection->prepare("UPDATE `services` SET
		`service` = ?,
		`expires` = ?,
		`active` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		
	$Update_Service->execute($User_Name_Edit, $Expires_Date_Edit, $Active_Edit, $User_Name, $Edit_Service_Post);

	# Audit Log
	if (!$Expires_Date_Edit || $Expires_Date_Edit eq '0000-00-00') {
		$Expires_Date_Edit = 'does not expire';
	}
	else {
		$Expires_Date_Edit = "expires on " . $Expires_Date_Edit;
	}

	if ($Active_Edit) {$Active_Edit = 'Active'} else {$Active_Edit = 'Inactive'}

	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();

	if ($Rules_Revoked > 0) {
		$Audit_Log_Submission->execute("Rules", "Revoke", "$User_Name modified Service ID $Edit_Service_Post, which caused the revocation of $Rules_Revoked Rules to protect the integrity of remote systems.", $User_Name);
	}
	$Audit_Log_Submission->execute("Services", "Modify", "$User_Name modified Service ID $Edit_Service_Post. The new entry is recorded as $User_Name_Edit, set $Active_Edit and $Expires_Date_Edit.", $User_Name);
	# / Audit Log

} # sub edit_service

sub html_delete_service {

	my $Select_Service = $DB_Connection->prepare("SELECT `service`
	FROM `services`
	WHERE `id` = ?");

	$Select_Service->execute($Delete_Service);
	
	while ( my @DB_Service = $Select_Service->fetchrow_array() )
	{
	
		my $User_Name_Extract = $DB_Service[0];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/IP/services.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Service</h3>

<form action='/IP/services.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this service?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Service Name:</td>
		<td style="text-align: left; color: #00FF00;">$User_Name_Extract</td>
	</tr>
</table>

<input type='hidden' name='Delete_Service_Confirm' value='$Delete_Service'>
<input type='hidden' name='Service_Name_Delete' value='$User_Name_Extract'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Service'></div>

</form>

ENDHTML

	}
} # sub html_delete_service

sub delete_service {

	### Revoke Rule Approval ###

	my $Update_Rule = $DB_Connection->prepare("UPDATE `rules`
	INNER JOIN `lnk_rules_to_services`
	ON `rules`.`id` = `lnk_rules_to_services`.`rule`
	SET
	`modified_by` = '$User_Name',
	`approved` = '0',
	`approved_by` = 'Approval Revoked by $User_Name when deleting Service ID $Delete_Service_Confirm'
	WHERE `lnk_rules_to_services`.`service` = ?");

	my $Rules_Revoked = $Update_Rule->execute($Delete_Service_Confirm);

	if ($Rules_Revoked eq '0E0') {$Rules_Revoked = 0}

	### / Revoke Rule Approval ###

	# Audit Log
	my $Select_Services = $DB_Connection->prepare("SELECT `service`, `expires`, `active`
		FROM `services`
		WHERE `id` = ?");

	$Select_Services->execute($Delete_Service_Confirm);

	while (( my $Servicename, my $Expires, my $Active ) = $Select_Services->fetchrow_array() )
	{

		if (!$Expires || $Expires eq '0000-00-00') {
			$Expires = 'does not expire';
		}
		else {
			$Expires = "expires on " . $Expires;
		}
	
		if ($Active) {$Active = 'Active'} else {$Active = 'Inactive'}
	
		my $DB_Connection = DB_Connection();
		my $Audit_Log_Submission = Audit_Log_Submission();

		if ($Rules_Revoked > 0) {
			$Audit_Log_Submission->execute("Rules", "Revoke", "$User_Name deleted Service ID $Delete_Service_Confirm, which caused the revocation of $Rules_Revoked Rules to protect the integrity of remote systems.", $User_Name);
		}

		$Audit_Log_Submission->execute("Services", "Delete", "$User_Name deleted Service ID $Delete_Service_Confirm. The deleted entry's last values were $Servicename, set $Active and $Expires.", $User_Name);

	}
	# / Audit Log

	my $Delete_Service = $DB_Connection->prepare("DELETE from `services`
		WHERE `id` = ?");
	
	$Delete_Service->execute($Delete_Service_Confirm);

	my $Delete_Service_From_Groups = $DB_Connection->prepare("DELETE from `lnk_service_groups_to_services`
			WHERE `service` = ?");
		
	$Delete_Service_From_Groups->execute($Delete_Service_Confirm);

	my $Delete_Service_From_Rules = $DB_Connection->prepare("DELETE from `lnk_rules_to_services`
			WHERE `service` = ?");
		
	$Delete_Service_From_Rules->execute($Delete_Service_Confirm);

} # sub delete_service

sub html_show_links {

	my $Counter;

	my $Table = new HTML::Table(
		-cols=>4,
                -align=>'center',
                -border=>0,
                -rules=>'cols',
                -evenrowclass=>'tbeven',
                -oddrowclass=>'tbodd',
                -width=>'90%',
                -spacing=>0,
                -padding=>1
	);

	$Table->addRow( "#", "Category", "Name", "Status", "View" );
	$Table->setRowClass (1, 'tbrow1');

	### Service Groups

	my $Select_Group_Links = $DB_Connection->prepare("SELECT `group`
		FROM `lnk_service_groups_to_services`
		WHERE `service` = ?"
	);
	$Select_Group_Links->execute($Show_Links);

	while ( my @Select_Links = $Select_Group_Links->fetchrow_array() )
	{
		
		my $Group_ID = $Select_Links[0];

		my $Select_Groups = $DB_Connection->prepare("SELECT `groupname`, `active`
			FROM `service_groups`
			WHERE `id` = ?"
		);
		$Select_Groups->execute($Group_ID);

		while ( my @Select_Group_Array = $Select_Groups->fetchrow_array() )
		{

			my $Group = $Select_Group_Array[0];
			my $Active = $Select_Group_Array[1];

			if ($Active) {$Active = "Active"} else {$Active = "<span style='color: #FF0000'>Inactive</span>"}

			$Counter++;

			$Table->addRow(
			"$Counter",
			"Service Group",
			"$Group",
			"$Active",
			"<a href='/IP/sudoers-service-groups.cgi?ID_Filter=$Group_ID'><img src=\"/Resources/Images/forward.png\" alt=\"View $Group\" ></a>"
			);
		}
	}

	### Rules

	my $Select_Rule_Links = $DB_Connection->prepare("SELECT `rule`
		FROM `lnk_rules_to_services`
		WHERE `service` = ?"
	);
	$Select_Rule_Links->execute($Show_Links);

	while ( my @Select_Links = $Select_Rule_Links->fetchrow_array() )
	{
		
		my $Rule_ID = $Select_Links[0];

		my $Select_Rules = $DB_Connection->prepare("SELECT `name`, `active`, `approved`
			FROM `rules`
			WHERE `id` = ?"
		);
		$Select_Rules->execute($Rule_ID);

		while ( my @Select_Rule_Array = $Select_Rules->fetchrow_array() )
		{

			my $Name = $Select_Rule_Array[0];
			my $Active = $Select_Rule_Array[1];
			my $Approved = $Select_Rule_Array[2];

			if ($Active) {$Active = "Active"} else {$Active = "<span style='color: #FF0000'>Inactive</span>"}
			if ($Approved) {$Approved = "Approved"} else {$Approved = "<span style='color: #FF0000'>Unapproved</span>"}

			$Counter++;

			$Table->addRow(
			"$Counter",
			"Rule",
			"$Name",
			"$Active<br />$Approved",
			"<a href='/IP/sudoers-rules.cgi?ID_Filter=$Rule_ID'><img src=\"/Resources/Images/forward.png\" alt=\"View $Name\" ></a>"
			);
		}
	}

if ($Counter eq undef) {$Counter = 0};

print <<ENDHTML;

<div id="wide-popup-box">
<a href="/IP/services.cgi">
<div id="blockclosebutton">
</div>
</a>

<h2 style="text-align: center; font-weight: bold;">Items linked to $Show_Links_Name</h2>

<p>There are <span style="color: #00FF00;">$Counter</span> items linked to $Show_Links_Name.</p>

$Table

ENDHTML

} # sub html_show_links

sub html_notes {

	my $Table = new HTML::Table(
		-cols=>4,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'90%',
		-spacing=>0,
		-padding=>1
	);

	$Table->addRow( "#", "Note", "Time", "Added By");
	$Table->setRowClass (1, 'tbrow1');

	### Discover Sudo Service Name
	my $Sudo_Service_Name;
	my $Select_Sudo_Service_Name = $DB_Connection->prepare("SELECT `service`
	FROM `services`
	WHERE `id` = ?");

	$Select_Sudo_Service_Name->execute($View_Notes);
	$Sudo_Service_Name = $Select_Sudo_Service_Name->fetchrow_array();
	### / Discover Sudo Service Name

	### Discover Note Count
	my $Select_Note_Count = $DB_Connection->prepare("SELECT COUNT(*)
		FROM `notes`
		WHERE `type_id` = '08'
		AND `item_id` = ?"
	);
	$Select_Note_Count->execute($View_Notes);
	my $Note_Count = $Select_Note_Count->fetchrow_array();
	### / Discover Note Count

	my $Select_Notes = $DB_Connection->prepare("SELECT `note`, `last_modified`, `modified_by`
	FROM `notes`
	WHERE `type_id` = '08'
	AND `item_id` = ?
	ORDER BY `last_modified` DESC");

	$Select_Notes->execute($View_Notes);

	my $Row_Count=$Note_Count;
	while ( my @Notes = $Select_Notes->fetchrow_array() )
	{
		my $Note = $Notes[0];
		my $Last_Modified = $Notes[1];
		my $Modified_By = $Notes[2];
		
		$Table->addRow($Row_Count, $Note, $Last_Modified, $Modified_By);
		$Row_Count--;
	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(3, '110px');
	$Table->setColWidth(4, '110px');

	$Table->setColAlign(1, 'center');
	$Table->setColAlign(3, 'center');
	$Table->setColAlign(4, 'center');

	if ($Note_Count == 0) {
		undef $Table;
		undef $Note_Count;
	}
	else {
		$Note_Count = "$Note_Count existing notes found, latest first."
	}

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/IP/services.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Notes for $Sudo_Service_Name</h3>
<form action='/IP/services.cgi' method='post'>

<table align='center'>
	<tr>
		<td><textarea name='New_Note' placeholder='Add a new note' autofocus></textarea></td>
	</tr>
	<tr>
		<td><div style="text-align: center"><input type='submit' name='Submit' value='Submit New Note'></div></td>
	</tr>
</table>

<hr width="50%">

<input type='hidden' name='New_Note_ID' value='$View_Notes'>
</form>

<p>$Note_Count</p>

$Table

ENDHTML

} # sub html_notes

sub add_note {

	my $Note_Submission = $DB_Connection->prepare("INSERT INTO `notes` (
		`type_id`,
		`item_id`,
		`note`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?
	)");
	$Note_Submission->execute('08', $New_Note_ID, $New_Note, $User_Name);

} # sub add_note

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

	my $Select_Service_Count = $DB_Connection->prepare("SELECT `id` FROM `services`");
		$Select_Service_Count->execute( );
		my $Total_Rows = $Select_Service_Count->rows();


	my $Select_Services = $DB_Connection->prepare("SELECT `id`, `service`, `expires`, `active`, `last_modified`, `modified_by`
		FROM `services`
			WHERE `id` LIKE ?
			OR `service` LIKE ?
			OR `expires` LIKE ?
		ORDER BY `service` ASC
		LIMIT ?, ?"
	);

	if ($ID_Filter) {
		$Select_Services->execute($ID_Filter, '', '', 0, $Rows_Returned);
	}
	else {
		$Select_Services->execute("%$Filter%", "%$Filter%", "%$Filter%", 0, $Rows_Returned);
	}

	my $Rows = $Select_Services->rows();

	$Table->addRow( "ID", "Service Name", "Expires", "Active", "Last Modified", "Modified By", "Show Links", "Notes", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Service_Row_Count=1;

	while ( my @Select_Services = $Select_Services->fetchrow_array() )
	{

		$Service_Row_Count++;

		my $DBID = $Select_Services[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($ID_Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $DB_Service_Name = $Select_Services[1];
			my $DB_Service_Name_Clean = $DB_Service_Name;
			$DB_Service_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Expires = $Select_Services[2];
			my $Expires_Clean = $Expires;
			$Expires =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Active = $Select_Services[3];
			if ($Active == 1) {$Active = "Yes"} else {$Active = "No"};
		my $Last_Modified = $Select_Services[4];
		my $Modified_By = $Select_Services[5];

		### Discover Note Count

		my $Select_Note_Count = $DB_Connection->prepare("SELECT COUNT(*)
			FROM `notes`
			WHERE `type_id` = '08'
			AND `item_id` = ?"
		);
		$Select_Note_Count->execute($DBID_Clean);
		my $Note_Count = $Select_Note_Count->fetchrow_array();

		### / Discover Note Count

		my $Expires_Epoch;
		my $Today_Epoch = time;
		if (!$Expires_Clean || $Expires_Clean =~ /^0000-00-00$/) {
			$Expires = 'Never';
		}
		else {
			$Expires_Epoch = str2time("$Expires_Clean"."T23:59:59");
		}

		$Table->addRow(
			"$DBID",
			"$DB_Service_Name",
			"$Expires",
			"$Active",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/IP/services.cgi?Show_Links=$DBID_Clean&Show_Links_Name=$DB_Service_Name_Clean'><img src=\"/Resources/Images/linked.png\" alt=\"Linked Objects to Service ID $DBID_Clean\" ></a>",
			"<a href='/IP/services.cgi?View_Notes=$DBID_Clean'>
				<div style='position: relative; background: url(\"/Resources/Images/view-notes.png\") no-repeat; width: 22px; height: 22px;'> 
					<p style='position: absolute; width: 22px; text-align: center; font-weight: bold; color: #FF0000;'>
						$Note_Count
					</p>
				</div>
			</a>",
			"<a href='/IP/services.cgi?Edit_Service=$DBID_Clean'><img src=\"/Resources/Images/edit.png\" alt=\"Edit Service ID $DBID_Clean\" ></a>",
			"<a href='/IP/services.cgi?Delete_Service=$DBID_Clean'><img src=\"/Resources/Images/delete.png\" alt=\"Delete Service ID $DBID_Clean\" ></a>"
		);


		if ($Active eq 'Yes') {
			$Table->setCellClass ($Service_Row_Count, 4, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($Service_Row_Count, 4, 'tbrowred');
		}

		if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
			$Table->setCellClass ($Service_Row_Count, 3, 'tbrowdarkgrey');
		}

	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(3, '60px');
	$Table->setColWidth(4, '1px');
	$Table->setColWidth(5, '110px');
	$Table->setColWidth(6, '110px');
	$Table->setColWidth(7, '1px');
	$Table->setColWidth(8, '1px');
	$Table->setColWidth(9, '1px');
	$Table->setColWidth(10, '1px');

	$Table->setColAlign(1, 'center');
	for (3..10) {
		$Table->setColAlign($_, 'center');
	}

print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/IP/services.cgi' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Services" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/IP/services.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Service</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Service' value='Add Service'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/IP/services.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Service</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Service' value='Edit Service'></td>
					<td align="center">
						<select name='Edit_Service' style="width: 150px">
ENDHTML

						my $Service_List_Query = $DB_Connection->prepare("SELECT `id`, `service`
						FROM `services`
						ORDER BY `service` ASC");
						$Service_List_Query->execute( );
						
						while ( (my $ID, my $DB_Service_Name) = my @Service_List_Query = $Service_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$DB_Service_Name</option>";
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

<p style="font-size:14px; font-weight:bold;">Services | Services Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output