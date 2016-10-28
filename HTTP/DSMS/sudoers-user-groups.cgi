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
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Group = $CGI->param("Add_Group");
my $Add_Group_Final = $CGI->param("Add_Group_Final");
my $Add_User_Temp_New = $CGI->param("Add_User_Temp_New");
my $Add_User_Temp_Existing = $CGI->param("Add_User_Temp_Existing");
my $Group_Name_Add = $CGI->param("Group_Name_Add");
	$Group_Name_Add =~ s/[^a-zA-Z0-9\-\.\_]//g;
my $System_Group_Toggle_Add = $CGI->param("System_Group_Toggle_Add");
my $Expires_Toggle_Add = $CGI->param("Expires_Toggle_Add");
my $Expires_Date_Add = $CGI->param("Expires_Date_Add");
	$Expires_Date_Add =~ s/\s//g;
	$Expires_Date_Add =~ s/[^0-9\-]//g;
my $Active_Add = $CGI->param("Active_Add");

my $Edit_Group = $CGI->param("Edit_Group");
my $Edit_Group_Final = $CGI->param("Edit_Group_Final");
my $Edit_User_Temp_New = $CGI->param("Edit_User_Temp_New");
my $Edit_User_Temp_Existing = $CGI->param("Edit_User_Temp_Existing");
my $Group_Name_Edit = $CGI->param("Group_Name_Edit");
	$Group_Name_Edit =~ s/[^a-zA-Z0-9\-\.\_]//g;
my $System_Group_Toggle_Edit = $CGI->param("System_Group_Toggle_Edit");
my $Expires_Toggle_Edit = $CGI->param("Expires_Toggle_Edit");
my $Expires_Date_Edit = $CGI->param("Expires_Date_Edit");
	$Expires_Date_Edit =~ s/\s//g;
	$Expires_Date_Edit =~ s/[^0-9\-]//g;
my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Group = $CGI->param("Delete_Group");
my $Delete_Group_Confirm = $CGI->param("Delete_Group_Confirm");
my $Group_Name_Delete = $CGI->param("Group_Name_Delete");

my $Delete_User_ID = $CGI->param("Delete_User_ID");
my $Delete_User_From_Group_ID = $CGI->param("Delete_User_From_Group_ID");
my $Delete_User_Name = $CGI->param("Delete_User_Name");
my $Delete_User_From_Group_Name = $CGI->param("Delete_User_From_Group_Name");

my $Show_Links = $CGI->param("Show_Links");
my $Show_Links_Name = $CGI->param("Show_Links_Name");

my $View_Notes = $CGI->param("View_Notes");
my $New_Note = $CGI->param("New_Note");
my $New_Note_ID = $CGI->param("New_Note_ID");

my $User_Name = $Session->param("User_Name");
my $User_DSMS_Admin = $Session->param("User_DSMS_Admin");
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

if ($Add_Group && !$Add_Group_Final) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_add_group;
	}
}
elsif ($Add_Group_Final) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
	else {
		my ($Group_ID, $User_Count) = &add_group;
		my $Message_Green="$Group_Name_Add added successfully as ID $Group_ID with $User_Count attached users";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
}
elsif ($Edit_Group && !$Edit_Group_Final) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_edit_group;
	}
}
elsif ($Edit_Group_Final) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
	else {
		my ($User_Count) = &edit_group;
		my $Message_Green="$Group_Name_Edit edited successfully with $User_Count newly attached users";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
}
elsif ($Delete_Group) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_delete_group;
	}
}
elsif ($Delete_Group_Confirm) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
	else {
		&delete_group;
		my $Message_Green="$Group_Name_Delete deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
}
elsif ($Delete_User_ID && $Delete_User_From_Group_ID) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
	else {
		&delete_user;
		my $Message_Green="$Delete_User_Name removed from $Delete_User_From_Group_Name successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
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



sub html_add_group {

if ($Add_User_Temp_New) {
	if ($Add_User_Temp_Existing !~ m/^$Add_User_Temp_New,/g &&
	$Add_User_Temp_Existing !~ m/,$Add_User_Temp_New$/g &&
	$Add_User_Temp_Existing !~ m/,$Add_User_Temp_New,/g) {
			$Add_User_Temp_Existing = $Add_User_Temp_Existing . $Add_User_Temp_New . ",";
		}
}

my $Users;
my @Users = split(',', $Add_User_Temp_Existing);

foreach my $User (@Users) {

	my $User_Query = $DB_Connection->prepare("SELECT `username`, `expires`, `active`
		FROM `users`
		WHERE `id` = ? ");
	$User_Query->execute($User);

	while ( (my $User_Name, my $Expires, my $Active) = my @User_Query = $User_Query->fetchrow_array() )
	{

		my $User_Name_Character_Limited = substr( $User_Name, 0, 40 );
			if ($User_Name_Character_Limited ne $User_Name) {
				$User_Name_Character_Limited = $User_Name_Character_Limited . '...';
			}

		my $Expires_Epoch;
		my $Today_Epoch = time;
		if ($Expires =~ /^0000-00-00$/) {
			$Expires = 'Never';
		}
		else {
			$Expires_Epoch = str2time("$Expires"."T23:59:59");
		}

		if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
			$Users = $Users . "<tr><td align='left' style='color: #B1B1B1'>$User_Name_Character_Limited</td></tr>";
		}
		elsif ($Active) {
			$Users = $Users . "<tr><td align='left' style='color: #00FF00'>$User_Name_Character_Limited</td></tr>";
		}
		else {
			$Users = $Users . "<tr><td align='left' style='color: #FF0000'>$User_Name_Character_Limited</td></tr>";
		}
		
	}

}

my $Date = strftime "%Y-%m-%d", localtime;

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/DSMS/sudoers-user-groups.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Group</h3>

<SCRIPT LANGUAGE="JavaScript"><!--
function Expire_Toggle() {
	if(document.Add_Group.Expires_Toggle_Add.checked)
	{
		document.Add_Group.Expires_Date_Add.disabled=false;
	}
	else
	{
		document.Add_Group.Expires_Date_Add.disabled=true;
	}
}
function System_Group_Toggle() {
	if(document.Add_Group.System_Group_Toggle_Add.checked)
	{
		document.Add_Group.Add_User_Temp_New.disabled=true;
	}
	else
	{
		document.Add_Group.Add_User_Temp_New.disabled=false;
	}
}
//-->
</SCRIPT>

<form action='/DSMS/sudoers-user-groups.cgi' name='Add_Group' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Group Name:</td>
		<td></td>
		<td colspan='3'><input type='text' name='Group_Name_Add' style="width: 300px" maxlength='128' value="$Group_Name_Add" placeholder="Group Name" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">System Group:</td>
		<td><input type="checkbox" onclick="System_Group_Toggle()" name="System_Group_Toggle_Add"></td>
		<td colspan='3' align="left">(See the specific definition below)</td>
	</tr>
	<tr>
		<td style="text-align: right;">Add User:</td>
		<td></td>
		<td colspan='3'>
			<select name='Add_User_Temp_New' onchange='this.form.submit()' style="width: 300px">
ENDHTML

				my $User_List_Query = $DB_Connection->prepare("SELECT `id`, `username`, `expires`, `active`
				FROM `users`
				ORDER BY `username` ASC");
				$User_List_Query->execute( );
				
				print "<option value='' selected>--Select a User--</option>";
				
				while ( (my $ID, my $User_Name, my $Expires, my $Active) = my @User_List_Query = $User_List_Query->fetchrow_array() )
				{

					my $User_Name_Character_Limited = substr( $User_Name, 0, 40 );
						if ($User_Name_Character_Limited ne $User_Name) {
							$User_Name_Character_Limited = $User_Name_Character_Limited . '...';
						}

					my $Expires_Epoch;
					my $Today_Epoch = time;
					if ($Expires =~ /^0000-00-00$/) {
						$Expires = 'Never';
					}
					else {
						$Expires_Epoch = str2time("$Expires"."T23:59:59");
					}

					if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
						print "<option style='color: #B1B1B1;' value='$ID'>$User_Name_Character_Limited [Expired]</option>";
					}
					elsif ($Active) {
						print "<option value='$ID'>$User_Name_Character_Limited</option>";
					}
					else {
						print "<option style='color: #FF0000;' value='$ID'>$User_Name_Character_Limited [Inactive]</option>";
					}
					
				}

print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Attached Users:</td>
		<td></td>
		<td colspan='3' style="text-align: left;">
ENDHTML

if ($Users) {
print <<ENDHTML;
			<table>
				<tr>
					<td>User Name</td>
				</tr>
				$Users
			</table>
ENDHTML
}
else {
	print "<span style='text-align: left; color: #FFC600;'>None</span>";
}


print <<ENDHTML;
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Expires:</td>
		<td><input type="checkbox" onclick="Expire_Toggle()" name="Expires_Toggle_Add"></td>
		<td colspan='3'><input type="text" style="width: 300px" name="Expires_Date_Add" value="$Date" placeholder="YYYY-MM-DD" disabled></td>
	</tr>
	<tr>
		<td style="text-align: right;">Active:</td>
		<td></td>
		<td style="text-align: left;"><input type="radio" name="Active_Add" value="1" checked>Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Add" value="0">No</td>
		<td></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Group Names must be unique and contain only a-z, A-Z, 0-9 and _ characters.</li>
<li>A <b>System Group</b> refers to the user group on a host, usually defined in /etc/group, and 
represented by a prefixed '%' in a traditional sudoers file. If selected, you cannot attach sudo 
users to this group here because the group's users will be determined by the host. Leave this 
unchecked to treat this group as a <b>Sudoers Group</b>, which is a group of users independent of 
any groups in /etc/group, and will therefore be treated as a sudoers group on <i>any</i> host.</li>
<li>Groups with an expiry set are automatically removed from sudoers at 23:59:59
(or the next sudoers refresh thereafter) on the day of expiry. Expired entries are functionally
equivalent to inactive entries. The date entry format is YYYY-MM-DD.</li>
<li>Active Groups are eligible for sudoers inclusion.</li>
</ul>

<input type='hidden' name='Add_Group' value='1'>
<input type='hidden' name='Add_User_Temp_Existing' value='$Add_User_Temp_Existing'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='Add_Group_Final' value='Add Group'></div>

</form>

ENDHTML

} #sub html_add_group

sub add_group {

	### Existing Group_Name Check
	my $Existing_Group_Name_Check = $DB_Connection->prepare("SELECT `id`
		FROM `user_groups`
		WHERE `groupname` = ?");
		$Existing_Group_Name_Check->execute($Group_Name_Add);
		my $Existing_Groups = $Existing_Group_Name_Check->rows();

	if ($Existing_Groups > 0)  {
		my $Existing_ID;
		while ( my @Select_Group_Names = $Existing_Group_Name_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Group_Names[0];
		}
		my $Message_Red="Group Name: $Group_Name_Add already exists as ID: $Existing_ID";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
	### / Existing Group_Name Check

	if ($System_Group_Toggle_Add eq 'on') {
		$System_Group_Toggle_Add = 1;
		$Add_User_Temp_Existing = '';
	}
	else {
		$System_Group_Toggle_Add = 0;
	}
	if ($Expires_Toggle_Add ne 'on') {
		$Expires_Date_Add = '0000-00-00';
	}

	my $Group_Insert = $DB_Connection->prepare("INSERT INTO `user_groups` (
		`id`,
		`groupname`,
		`system_group`,
		`expires`,
		`active`,
		`modified_by`
	)
	VALUES (
		NULL,
		?, ?, ?, ?, ?
	)");

	$Group_Insert->execute($Group_Name_Add, $System_Group_Toggle_Add, $Expires_Date_Add, $Active_Add, $User_Name);

	my $Group_Insert_ID = $DB_Connection->{mysql_insertid};

	$Add_User_Temp_Existing =~ s/,$//;
	my @Users = split(',', $Add_User_Temp_Existing);
	my $User_Count=0;

	foreach my $User (@Users) {

		$User_Count++;

		my $User_Insert = $DB_Connection->prepare("INSERT INTO `lnk_user_groups_to_users` (
			`id`,
			`group`,
			`user`
		)
		VALUES (
			NULL,
			?,
			?
		)");
		
		$User_Insert->execute($Group_Insert_ID, $User);

	}

	# Audit Log
	if ($System_Group_Toggle_Add) {$System_Group_Toggle_Add = 'System'} else {$System_Group_Toggle_Add = 'Sudoers'}

	if ($Expires_Date_Add eq '0000-00-00') {
		$Expires_Date_Add = 'not expire';
	}
	else {
		$Expires_Date_Add = "expire on " . $Expires_Date_Add;
	}

	if ($Active_Add) {$Active_Add = 'Active'} else {$Active_Add = 'Inactive'}

	my $Users_Attached;
	foreach my $User (@Users) {

		my $Select_Users = $DB_Connection->prepare("SELECT `username`
			FROM `users`
			WHERE `id` = ?"
		);
		$Select_Users->execute($User);

		while ((my $User_Name) = $Select_Users->fetchrow_array() )
		{
			$Users_Attached = $User_Name . ", " . $Users_Attached;
		}

	$Users_Attached =~ s/,\s$//;
	}

	if ($Users_Attached) {
		$Users_Attached = ": " . $Users_Attached;
	}
	else {
		$Users_Attached = '';
	}

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
	
	$Audit_Log_Submission->execute("DSMS User Groups", "Add", "$User_Name added $Group_Name_Add as a $System_Group_Toggle_Add Group, set it $Active_Add and to $Expires_Date_Add. $User_Count users were attached$Users_Attached. The system assigned it User Group ID $Group_Insert_ID.", $User_Name);
	# / Audit Log

	return($Group_Insert_ID, $User_Count);

} # sub add_group

sub html_edit_group {

### Currently Attached Users Retrieval and Conversion

my $Users;
my $Select_Links = $DB_Connection->prepare("SELECT `user`
	FROM `lnk_user_groups_to_users`
	WHERE `group` = ? "
);
$Select_Links->execute($Edit_Group);

while ( my @Select_Links = $Select_Links->fetchrow_array() )
{
	my $Link = $Select_Links[0];

	my $User_Query = $DB_Connection->prepare("SELECT `username`, `expires`, `active`
		FROM `users`
		WHERE `id` = ? ");
	$User_Query->execute($Link);

	while ( (my $User_Name, my $Expires, my $Active) = my @User_Query = $User_Query->fetchrow_array() )
	{

		my $User_Name_Character_Limited = substr( $User_Name, 0, 40 );
			if ($User_Name_Character_Limited ne $User_Name) {
				$User_Name_Character_Limited = $User_Name_Character_Limited . '...';
			}

		my $Expires_Epoch;
		my $Today_Epoch = time;
		if ($Expires =~ /^0000-00-00$/) {
			$Expires = 'Never';
		}
		else {
			$Expires_Epoch = str2time("$Expires"."T23:59:59");
		}

		if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
			$Users = $Users . "<tr><td align='left' style='color: #B1B1B1'>$User_Name_Character_Limited</td></tr>";
		}
		elsif ($Active) {
			$Users = $Users . "<tr><td align='left' style='color: #00FF00'>$User_Name_Character_Limited</td></tr>";
		}
		else {
			$Users = $Users . "<tr><td align='left' style='color: #FF0000'>$User_Name_Character_Limited</td></tr>";
		}
	}
}

### / Currently Attached Users Retrieval and Conversion

### Newly Attached Users Retrieval and Conversion

if ($Edit_User_Temp_New) {

	if ($Edit_User_Temp_Existing !~ m/^$Edit_User_Temp_New,/g &&
	$Edit_User_Temp_Existing !~ m/,$Edit_User_Temp_New$/g &&
	$Edit_User_Temp_Existing !~ m/,$Edit_User_Temp_New,/g) {
		
		### Check to see if new link is already attached to this group
		my $Select_Links = $DB_Connection->prepare("SELECT `id`
			FROM `lnk_user_groups_to_users`
			WHERE `user` = ?
			AND `group` = ? "
		);
		$Select_Links->execute($Edit_User_Temp_New, $Edit_Group);

		my $Matched_Rows = $Select_Links->rows();

		if ($Matched_Rows == 0) {
			$Edit_User_Temp_Existing = $Edit_User_Temp_Existing . $Edit_User_Temp_New . ",";
		}
	}
}

my $Users_New;
my @Users = split(',', $Edit_User_Temp_Existing);

foreach my $User (@Users) {

	my $User_Query = $DB_Connection->prepare("SELECT `username`, `expires`, `active`
		FROM `users`
		WHERE `id` = ? ");
	$User_Query->execute($User);
		
	while ( (my $User_Name, my $Expires, my $Active) = my @User_Query = $User_Query->fetchrow_array() )
	{

		my $User_Name_Character_Limited = substr( $User_Name, 0, 40 );
			if ($User_Name_Character_Limited ne $User_Name) {
				$User_Name_Character_Limited = $User_Name_Character_Limited . '...';
			}

		my $Expires_Epoch;
		my $Today_Epoch = time;
		if ($Expires =~ /^0000-00-00$/) {
			$Expires = 'Never';
		}
		else {
			$Expires_Epoch = str2time("$Expires"."T23:59:59");
		}

		if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
			$Users_New = $Users_New . "<tr><td align='left' style='color: #B1B1B1'>$User_Name_Character_Limited</td></tr>";
		}
		elsif ($Active) {
			$Users_New = $Users_New . "<tr><td align='left' style='color: #00FF00'>$User_Name_Character_Limited</td></tr>";
		}
		else {
			$Users_New = $Users_New . "<tr><td align='left' style='color: #FF0000'>$User_Name_Character_Limited</td></tr>";
		}
	}
}

### / Newly Attached Users Retrieval and Conversion

### Group Details Retrieval

if (!$Group_Name_Edit) {
	my $Select_Group_Details = $DB_Connection->prepare("SELECT `groupname`, `system_group`, `expires`, `active`
		FROM `user_groups`
		WHERE `id` = ? "
	);
	$Select_Group_Details->execute($Edit_Group);

	while ( my @Select_Details = $Select_Group_Details->fetchrow_array() )
	{
		$Group_Name_Edit = $Select_Details[0];
		$System_Group_Toggle_Edit = $Select_Details[1];
		$Expires_Date_Edit = $Select_Details[2];
		$Active_Edit = $Select_Details[3];
	}
}

	my $System_Group_Checked;
	my $System_Group_Disabled;
	if ($System_Group_Toggle_Edit == 1) {
		$System_Group_Checked = 'checked';
		$System_Group_Disabled = 'disabled';
	}
	else {
		$System_Group_Checked = '';
		$System_Group_Disabled = '';
	}

	my $Expires_Checked;
	my $Expires_Disabled;
	if ($Expires_Date_Edit eq '0000-00-00' || !$Expires_Date_Edit) {
		$Expires_Checked = '';
		$Expires_Disabled = 'disabled';
		$Expires_Date_Edit = strftime "%Y-%m-%d", localtime;
	}
	else {
		$Expires_Checked = 'checked';
		$Expires_Disabled = '';
	}

### / Group Details Retrieval

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/DSMS/sudoers-user-groups.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Group</h3>

<SCRIPT LANGUAGE="JavaScript"><!--
function Expire_Toggle() {
	if(document.Edit_Group.Expires_Toggle_Edit.checked)
	{
		document.Edit_Group.Expires_Date_Edit.disabled=false;
	}
	else
	{
		document.Edit_Group.Expires_Date_Edit.disabled=true;
	}
}
function System_Group_Toggle() {
	if(document.Edit_Group.System_Group_Toggle_Edit.checked)
	{
		document.Edit_Group.Edit_User_Temp_New.disabled=true;
	}
	else
	{
		document.Edit_Group.Edit_User_Temp_New.disabled=false;
	}
}
//-->
</SCRIPT>

<form action='/DSMS/sudoers-user-groups.cgi' name='Edit_Group' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Group Name:</td>
		<td></td>
		<td colspan='3'><input type='text' name='Group_Name_Edit' style="width: 300px" maxlength='128' value="$Group_Name_Edit" placeholder="Group Name" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">System Group:</td>
		<td><input type="checkbox" onclick="System_Group_Toggle()" name="System_Group_Toggle_Edit" $System_Group_Checked></td>
		<td colspan='3' align="left">(See the specific definition below)</td>
	</tr>
	<tr>
		<td style="text-align: right;">Add User:</td>
		<td></td>
		<td colspan='3'>
			<select name='Edit_User_Temp_New' onchange='this.form.submit()' style="width: 300px" $System_Group_Disabled>
ENDHTML

				my $User_List_Query = $DB_Connection->prepare("SELECT `id`, `username`, `expires`, `active`
				FROM `users`
				ORDER BY `username` ASC");
				$User_List_Query->execute( );
				
				print "<option value='' selected>--Select a User--</option>";
				
				while ( (my $ID, my $User_Name, my $Expires, my $Active) = my @User_List_Query = $User_List_Query->fetchrow_array() )
				{

					my $User_Name_Character_Limited = substr( $User_Name, 0, 40 );
						if ($User_Name_Character_Limited ne $User_Name) {
							$User_Name_Character_Limited = $User_Name_Character_Limited . '...';
						}

					my $Expires_Epoch;
					my $Today_Epoch = time;
					if ($Expires =~ /^0000-00-00$/) {
						$Expires = 'Never';
					}
					else {
						$Expires_Epoch = str2time("$Expires"."T23:59:59");
					}
			
					if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
						print "<option style='color: #B1B1B1;' value='$ID'>$User_Name_Character_Limited [Expired]</option>";
					}
					elsif ($Active) {
						print "<option value='$ID'>$User_Name_Character_Limited</option>";
					}
					else {
						print "<option style='color: #FF0000;' value='$ID'>$User_Name_Character_Limited [Inactive]</option>";
					}
					
				}

print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Existing Users:</td>
		<td></td>
		<td colspan='3' style="text-align: left;">
ENDHTML

if ($Users) {
print <<ENDHTML;
			<table>
				<tr>
					<td>User Name</td>
				</tr>
				$Users
			</table>
ENDHTML
}
else {
	print "<span style='text-align: left; color: #FFC600;'>None</span>";
}


print <<ENDHTML;
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">New Users:</td>
		<td></td>
		<td colspan='3' style="text-align: left;">
ENDHTML

if ($Users_New) {
print <<ENDHTML;
			<table>
				<tr>
					<td>User Name</td>
				</tr>
				$Users_New
			</table>
ENDHTML
}
else {
	print "<span style='text-align: left; color: #FFC600;'>None</span>";
}


print <<ENDHTML;
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Expires:</td>
		<td><input type="checkbox" onclick="Expire_Toggle()" name="Expires_Toggle_Edit" $Expires_Checked></td>
		<td colspan='3'><input type="text" style="width: 300px" name="Expires_Date_Edit" value="$Expires_Date_Edit" placeholder="$Expires_Date_Edit" $Expires_Disabled></td>
	</tr>
	<tr>
		<td style="text-align: right;">Active:</td>
		<td></td>
ENDHTML

if ($Active_Edit == 1) {
print <<ENDHTML;
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="1" checked>Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="0">No</td>
		<td></td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="1">Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Edit" value="0" checked>No</td>
		<td></td>
ENDHTML
}

print <<ENDHTML;
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Group Names must be unique and contain only a-z, A-Z, 0-9 and _ characters.</li>
<li>A <b>System Group</b> refers to the user group on a host, usually defined in /etc/group, and 
represented by a prefixed '%' in a traditional sudoers file. If selected, you cannot attach sudo 
users to this group here because the group's users will be determined by the host. Leave this 
unchecked to treat this group as a <b>Sudoers Group</b>, which is a group of users independent of 
any groups in /etc/group, and will therefore be treated as a sudoers group on <i>any</i> host.</li>
<li>You can only activate a modified command if you are an Approver.
If you are not an Approver and you modify this entry, it will automatically be set to Inactive.</li>
<li>Groups with an expiry set are automatically removed from sudoers at 23:59:59
(or the next sudoers refresh thereafter) on the day of expiry. Expired entries are functionally
equivalent to inactive entries. The date entry format is YYYY-MM-DD.</li>
<li>Active Groups are eligible for sudoers inclusion.</li>
</ul>

<input type='hidden' name='Edit_Group' value='$Edit_Group'>
<input type='hidden' name='Edit_User_Temp_Existing' value='$Edit_User_Temp_Existing'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='Edit_Group_Final' value='Edit Group'></div>

</form>

ENDHTML

} #sub html_edit_group

sub edit_group {

	### Existing Group_Name Check
	my $Existing_Group_Name_Check = $DB_Connection->prepare("SELECT `id`
		FROM `user_groups`
		WHERE `groupname` = ?
		AND `id` != ?");
		$Existing_Group_Name_Check->execute($Group_Name_Edit, $Edit_Group);
		my $Existing_Groups = $Existing_Group_Name_Check->rows();

	if ($Existing_Groups > 0)  {
		my $Existing_ID;
		while ( my @Select_Group_Names = $Existing_Group_Name_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Group_Names[0];
		}
		my $Message_Red="Group Name: $Group_Name_Edit already exists as ID: $Existing_ID";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-user-groups.cgi\n\n";
		exit(0);
	}
	### / Existing Group_Name Check

	### Revoke Rule Approval ###

	my $Update_Rule = $DB_Connection->prepare("UPDATE `rules`
	INNER JOIN `lnk_rules_to_user_groups`
	ON `rules`.`id` = `lnk_rules_to_user_groups`.`rule`
	SET
	`modified_by` = '$User_Name',
	`approved` = '0',
	`approved_by` = 'Approval Revoked by $User_Name when modifying User Group ID $Edit_Group'
	WHERE `lnk_rules_to_user_groups`.`user_group` = ?");

	my $Rules_Revoked = $Update_Rule->execute($Edit_Group);

	if ($Rules_Revoked eq '0E0') {$Rules_Revoked = 0}

	### / Revoke Rule Approval ###

	if ($System_Group_Toggle_Edit eq 'on') {
		$System_Group_Toggle_Edit = 1;
		$Edit_User_Temp_Existing = '';
		my $Delete_Users_From_System_Group = $DB_Connection->prepare("DELETE from `lnk_user_groups_to_users`
			WHERE `group` = ?");
		$Delete_Users_From_System_Group->execute($Edit_Group);
	}
	else {
		$System_Group_Toggle_Edit = 0;
	}

	if ($Expires_Toggle_Edit ne 'on') {
		$Expires_Date_Edit = '0000-00-00';
	}

	my $Update_Group = $DB_Connection->prepare("UPDATE `user_groups` SET
		`groupname` = ?,
		`system_group` = ?,
		`expires` = ?,
		`active` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	$Update_Group->execute($Group_Name_Edit, $System_Group_Toggle_Edit, $Expires_Date_Edit, $Active_Edit, $User_Name, $Edit_Group);

	$Edit_User_Temp_Existing =~ s/,$//;
	my @Users = split(',', $Edit_User_Temp_Existing);
	my $User_Count=0;

	foreach my $User (@Users) {

		$User_Count++;

		my $User_Insert = $DB_Connection->prepare("INSERT INTO `lnk_user_groups_to_users` (
			`id`,
			`group`,
			`user`
		)
		VALUES (
			NULL,
			?,
			?
		)");
		
		$User_Insert->execute($Edit_Group, $User);

	}

	# Audit Log
	if ($System_Group_Toggle_Edit) {$System_Group_Toggle_Edit = 'System'} else {$System_Group_Toggle_Edit = 'Sudoers'}

	if ($Expires_Date_Edit eq '0000-00-00') {
		$Expires_Date_Edit = 'does not expire';
	}
	else {
		$Expires_Date_Edit = "expires on " . $Expires_Date_Edit;
	}

	if ($Active_Edit) {$Active_Edit = 'Active'} else {$Active_Edit = 'Inactive'}

	my $Users_Attached;
	foreach my $User (@Users) {

		my $Select_Users = $DB_Connection->prepare("SELECT `username`
			FROM `users`
			WHERE `id` = ?"
		);
		$Select_Users->execute($User);

		while ((my $User_Name) = $Select_Users->fetchrow_array() )
		{
			$Users_Attached = $User_Name . ", " . $Users_Attached;
		}

	$Users_Attached =~ s/,\s$//;
	}

	if ($Users_Attached) {
		$Users_Attached = ": " . $Users_Attached;
	}
	else {
		$Users_Attached = '';
	}

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

	if ($Rules_Revoked > 0) {
		$Audit_Log_Submission->execute("Rules", "Revoke", "$User_Name modified User Group ID $Edit_Group, which caused the revocation of $Rules_Revoked Rules to protect the integrity of remote systems.", $User_Name);
	}
	$Audit_Log_Submission->execute("DSMS User Groups", "Modify", "$User_Name modified User Group ID $Edit_Group. The new entry is recorded as $System_Group_Toggle_Edit Group $Group_Name_Edit, set $Active_Edit and $Expires_Date_Edit. $User_Count new users were attached$Users_Attached.", $User_Name);
	# / Audit Log

	return($User_Count);

} # sub edit_group

sub html_delete_group {

	my $Select_Group = $DB_Connection->prepare("SELECT `groupname`
	FROM `user_groups`
	WHERE `id` = ?");

	$Select_Group->execute($Delete_Group);
	
	while ( my @DB_Group = $Select_Group->fetchrow_array() )
	{
	
		my $Group_Name_Extract = $DB_Group[0];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/DSMS/sudoers-user-groups.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Group</h3>

<form action='/DSMS/sudoers-user-groups.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this group?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Group Name:</td>
		<td style="text-align: left; color: #00FF00;">$Group_Name_Extract</td>
	</tr>
</table>

<input type='hidden' name='Delete_Group_Confirm' value='$Delete_Group'>
<input type='hidden' name='Group_Name_Delete' value='$Group_Name_Extract'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Group'></div>

</form>

ENDHTML

	}
} # sub html_delete_group

sub delete_group {

	### Revoke Rule Approval ###

	my $Update_Rule = $DB_Connection->prepare("UPDATE `rules`
	INNER JOIN `lnk_rules_to_user_groups`
	ON `rules`.`id` = `lnk_rules_to_user_groups`.`rule`
	SET
	`modified_by` = '$User_Name',
	`approved` = '0',
	`approved_by` = 'Approval Revoked by $User_Name when deleting User Group ID $Delete_Group_Confirm'
	WHERE `lnk_rules_to_user_groups`.`user_group` = ?");

	my $Rules_Revoked = $Update_Rule->execute($Delete_Group_Confirm);

	if ($Rules_Revoked eq '0E0') {$Rules_Revoked = 0}

	### / Revoke Rule Approval ###

	# Audit Log
	my $Select_Links = $DB_Connection->prepare("SELECT `user`
		FROM `lnk_user_groups_to_users`
		WHERE `group` = ?"
	);
	$Select_Links->execute($Delete_Group_Confirm);

	my $Users_Attached;
	while (( my $User_ID ) = $Select_Links->fetchrow_array() )
	{

		my $Select_Users = $DB_Connection->prepare("SELECT `username`
			FROM `users`
			WHERE `id` = ?"
		);
		$Select_Users->execute($User_ID);

		while (( my $User ) = $Select_Users->fetchrow_array() )
		{
			$Users_Attached = $User . ", " . $Users_Attached;
		}
	}

	my $Select_Users = $DB_Connection->prepare("SELECT `groupname`, `expires`, `active`
		FROM `user_groups`
		WHERE `id` = ?");

	$Select_Users->execute($Delete_Group_Confirm);

	while (( my $Group_Name, my $Expires, my $Active ) = $Select_Users->fetchrow_array() )
	{

		if ($Expires eq '0000-00-00') {
			$Expires = 'does not expire';
		}
		else {
			$Expires = "expires on " . $Expires;
		}
	
		if ($Active) {$Active = 'Active'} else {$Active = 'Inactive'}
		$Users_Attached =~ s/,\s$//;

		if ($Users_Attached) {
			$Users_Attached = "the following users attached: " . $Users_Attached . ".";
		}
		else {
			$Users_Attached = 'no users attached.';
		}

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

		if ($Rules_Revoked > 0) {
			$Audit_Log_Submission->execute("Rules", "Revoke", "$User_Name deleted User Group ID $Delete_Group_Confirm, which caused the revocation of $Rules_Revoked Rules to protect the integrity of remote systems.", $User_Name);
		}
		$Audit_Log_Submission->execute("DSMS User Groups", "Delete", "$User_Name deleted User Group ID $Delete_Group_Confirm. The deleted entry's last values were $Group_Name, set $Active and $Expires. It had $Users_Attached", $User_Name);

	}
	# / Audit Log

	my $Delete_Group = $DB_Connection->prepare("DELETE from `user_groups`
		WHERE `id` = ?");
	
	$Delete_Group->execute($Delete_Group_Confirm);

 	my $Delete_User = $DB_Connection->prepare("DELETE from `lnk_user_groups_to_users`
		WHERE `group` = ?");
	
	$Delete_User->execute($Delete_Group_Confirm);

 	my $Delete_Rule_Links = $DB_Connection->prepare("DELETE from `lnk_rules_to_user_groups`
		WHERE `user_group` = ?");
	
	$Delete_Rule_Links->execute($Delete_Group_Confirm);

} # sub delete_group

sub delete_user {

	### Revoke Rule Approval ###

	my $Update_Rule = $DB_Connection->prepare("UPDATE `rules`
	INNER JOIN `lnk_rules_to_user_groups`
	ON `rules`.`id` = `lnk_rules_to_user_groups`.`rule`
	SET
	`modified_by` = '$User_Name',
	`approved` = '0',
	`approved_by` = 'Approval Revoked by $User_Name when modifying User Group ID $Delete_User_From_Group_ID'
	WHERE `lnk_rules_to_user_groups`.`user_group` = ?");

	my $Rules_Revoked = $Update_Rule->execute($Delete_User_From_Group_ID);

	if ($Rules_Revoked eq '0E0') {$Rules_Revoked = 0}

	### / Revoke Rule Approval ###

	# Audit Log
	my $Select_Users = $DB_Connection->prepare("SELECT `username`
		FROM `users`
		WHERE `id` = ?");

	$Select_Users->execute($Delete_User_ID);

	while (( my $Username ) = $Select_Users->fetchrow_array() )
	{
	
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

		if ($Rules_Revoked > 0) {
			$Audit_Log_Submission->execute("Rules", "Revoke", "$User_Name deleted User ID $Delete_User_ID from User Group ID $Delete_User_From_Group_ID, which caused the revocation of $Rules_Revoked Rules to protect the integrity of remote systems.", $User_Name);
		}
		$Audit_Log_Submission->execute("DSMS User Groups", "Delete", "$User_Name removed $Username [User ID $Delete_User_ID] from User Group $Delete_User_From_Group_Name [User Group ID $Delete_User_From_Group_ID].", $User_Name);

	}
	# / Audit Log

	my $Delete_User = $DB_Connection->prepare("DELETE from `lnk_user_groups_to_users`
		WHERE `group` = ?
		AND `user` = ?");

	$Delete_User->execute($Delete_User_From_Group_ID, $Delete_User_ID);

}

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

	### Users

	my $Select_User_Links = $DB_Connection->prepare("SELECT `user`
		FROM `lnk_user_groups_to_users`
		WHERE `group` = ?"
	);
	$Select_User_Links->execute($Show_Links);

	while ( my @Select_Links = $Select_User_Links->fetchrow_array() )
	{
		
		my $User_ID = $Select_Links[0];

		my $Select_Users = $DB_Connection->prepare("SELECT `username`, `active`
			FROM `users`
			WHERE `id` = ?"
		);
		$Select_Users->execute($User_ID);

		while ( my @Select_User_Array = $Select_Users->fetchrow_array() )
		{

			my $User = $Select_User_Array[0];
			my $Active = $Select_User_Array[1];

			if ($Active) {$Active = "Active"} else {$Active = "<span style='color: #FF0000'>Inactive</span>"}

			$Counter++;

			$Table->addRow(
			"$Counter",
			"User",
			"$User",
			"$Active",
			"<a href='/DSMS/sudoers-users.cgi?ID_Filter=$User_ID'><img src=\"/resources/imgs/forward.png\" alt=\"View $User\" ></a>"
			);
		}
	}

	### Rules

	my $Select_Rule_Links = $DB_Connection->prepare("SELECT `rule`
		FROM `lnk_rules_to_user_groups`
		WHERE `user_group` = ?"
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
			"<a href='/DSMS/sudoers-rules.cgi?ID_Filter=$Rule_ID'><img src=\"/resources/imgs/forward.png\" alt=\"View $Name\" ></a>"
			);
		}
	}

if ($Counter eq undef) {$Counter = 0};

print <<ENDHTML;

<div id="wide-popup-box">
<a href="/DSMS/sudoers-user-groups.cgi">
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

	### Discover Group Name
	my $Group_Name;
	my $Select_Group_Name = $DB_Connection->prepare("SELECT `groupname`
	FROM `user_groups`
	WHERE `id` = ?");

	$Select_Group_Name->execute($View_Notes);
	$Group_Name = $Select_Group_Name->fetchrow_array();
	### / Discover Group Name

	### Discover Note Count
	my $Select_Note_Count = $DB_Connection->prepare("SELECT COUNT(*)
		FROM `notes`
		WHERE `type_id` = '04'
		AND `item_id` = ?"
	);
	$Select_Note_Count->execute($View_Notes);
	my $Note_Count = $Select_Note_Count->fetchrow_array();
	### / Discover Note Count

	my $Select_Notes = $DB_Connection->prepare("SELECT `note`, `last_modified`, `modified_by`
	FROM `notes`
	WHERE `type_id` = '04'
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
<a href="/DSMS/sudoers-user-groups.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Notes for $Group_Name</h3>
<form action='/DSMS/sudoers-user-groups.cgi' method='post'>

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
	$Note_Submission->execute(04, $New_Note_ID, $New_Note, $User_Name);

} # sub add_note

sub html_output {

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


	my $Select_Group_Count = $DB_Connection->prepare("SELECT `id` FROM `user_groups`");
		$Select_Group_Count->execute( );
		my $Total_Rows = $Select_Group_Count->rows();


	my $Select_Groups = $DB_Connection->prepare("SELECT `id`, `groupname`, `system_group`, `expires`, `active`, `last_modified`, `modified_by`
		FROM `user_groups`
		WHERE `id` LIKE ?
		OR `groupname` LIKE ?
		OR `expires` LIKE ?
		ORDER BY `groupname` ASC
		LIMIT 0 , $Rows_Returned"
	);

	if ($ID_Filter) {
		$Select_Groups->execute($ID_Filter, '', '');
	}
	else {
		$Select_Groups->execute("%$Filter%", "%$Filter%", "%$Filter%");
	}
	
	my $Rows = $Select_Groups->rows();

	$Table->addRow( "ID", "Group Name", "Connected Users", "Expires", "Active", "Last Modified", "Modified By", "Links", "Notes", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Group_Row_Count=1;

	while ( my @Select_Groups = $Select_Groups->fetchrow_array() )
	{

		$Group_Row_Count++;
		my $Users;

		my $DBID = $Select_Groups[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($ID_Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Group_Name = $Select_Groups[1];
		my $Group_Name_Clean = $Group_Name;
			$Group_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $System_Group = $Select_Groups[2];
		my $Group_Expires = $Select_Groups[3];
		my $Group_Expires_Clean = $Group_Expires;
			$Group_Expires =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Active = $Select_Groups[4];
			if ($Active == 1) {$Active = "Yes"} else {$Active = "No"};
		my $Last_Modified = $Select_Groups[5];
		my $Modified_By = $Select_Groups[6];

		### Discover Note Count

		my $Select_Note_Count = $DB_Connection->prepare("SELECT COUNT(*)
			FROM `notes`
			WHERE `type_id` = '04'
			AND `item_id` = ?"
		);
		$Select_Note_Count->execute($DBID_Clean);
		my $Note_Count = $Select_Note_Count->fetchrow_array();

		### / Discover Note Count

		my $Select_Links = $DB_Connection->prepare("SELECT `user`
			FROM `lnk_user_groups_to_users`
			WHERE `group` = ?"
		);
		$Select_Links->execute($DBID_Clean);

		while ( my @Select_Links = $Select_Links->fetchrow_array() )
		{

			my $User_ID = $Select_Links[0];

			my $Select_Users = $DB_Connection->prepare("SELECT `username`, `expires`, `active`
				FROM `users`
				WHERE `id` = ?"
			);
			$Select_Users->execute($User_ID);

			while ( my @Select_Users = $Select_Users->fetchrow_array() )
			{

				my $User = $Select_Users[0];
					my $User_Clean = $User;
				my $Expires = $Select_Users[1];
				my $Active = $Select_Users[2];

				my $Expires_Epoch;
				my $Today_Epoch = time;
				if ($Expires =~ /^0000-00-00$/) {
					$Expires = 'Never';
				}
				else {
					$Expires_Epoch = str2time("$Expires"."T23:59:59");
				}


				if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
					$User = "<a href='/DSMS/sudoers-users.cgi?ID_Filter=$User_ID'><span style='color: #B1B1B1'>$User</span></a>"
				}
				elsif ($Active == 1) {
					$User = "<a href='/DSMS/sudoers-users.cgi?ID_Filter=$User_ID'><span style='color: #00FF00'>$User</span></a>"
				}
				else {
					$User = "<a href='/DSMS/sudoers-users.cgi?ID_Filter=$User_ID'><span style='color: #FF0000'>$User</span></a>"
				};
				$Users = $Users . $User . "&nbsp;&nbsp;&nbsp;" . "<a href='/DSMS/sudoers-user-groups.cgi?Delete_User_ID=$User_ID&Delete_User_From_Group_ID=$DBID_Clean&Delete_User_Name=$User_Clean&Delete_User_From_Group_Name=$Group_Name_Clean'><span style='color: #FFC600'>[Remove]</span></a>" . "<br />";

			}
		}

		my $Group_Expires_Epoch;
		my $Today_Epoch = time;
		if ($Group_Expires_Clean =~ /^0000-00-00$/) {
			$Group_Expires = 'Never';
		}
		else {
			$Group_Expires_Epoch = str2time("$Group_Expires_Clean"."T23:59:59");
		}
		if ($System_Group) {
			$Group_Name = '%' . $Group_Name;
			$Users = '<div style="text-align: center;">[This is a System Group. Users are defined by the host\'s /etc/group file.]</div>'
		}

		$Table->addRow(
			"$DBID",
			"$Group_Name",
			"$Users",
			"$Group_Expires",
			"$Active",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/DSMS/sudoers-user-groups.cgi?Show_Links=$DBID_Clean&Show_Links_Name=$Group_Name_Clean'><img src=\"/resources/imgs/linked.png\" alt=\"Linked Objects to Group ID $DBID_Clean\" ></a>",
			"<a href='/DSMS/sudoers-user-groups.cgi?View_Notes=$DBID_Clean'>
				<div style='position: relative; background: url(\"/resources/imgs/view-notes.png\") no-repeat; width: 22px; height: 22px;'> 
					<p style='position: absolute; width: 22px; text-align: center; font-weight: bold; color: #FF0000;'>
						$Note_Count
					</p>
				</div>
			</a>",
			"<a href='/DSMS/sudoers-user-groups.cgi?Edit_Group=$DBID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Group ID $DBID_Clean\" ></a>",
			"<a href='/DSMS/sudoers-user-groups.cgi?Delete_Group=$DBID_Clean'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Group ID $DBID_Clean\" ></a>"
		);


		if ($Active eq 'Yes') {
			$Table->setCellClass ($Group_Row_Count, 5, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($Group_Row_Count, 5, 'tbrowred');
		}

		if ($Group_Expires ne 'Never' && $Group_Expires_Epoch < $Today_Epoch) {
			$Table->setCellClass ($Group_Row_Count, 4, 'tbrowdisabled');
		}

	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(4, '60px');
	$Table->setColWidth(5, '1px');
	$Table->setColWidth(6, '110px');
	$Table->setColWidth(7, '110px');
	$Table->setColWidth(8, '1px');
	$Table->setColWidth(9, '1px');
	$Table->setColWidth(10, '1px');
	$Table->setColWidth(11, '1px');

	$Table->setColAlign(1, 'center');
	for (4 .. 11) {
		$Table->setColAlign($_, 'center');
	}


print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/DSMS/sudoers-user-groups.cgi' method='post' >
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
						Filter Groups:
					</td>
					<td style="text-align: right;">
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Groups" placeholder="Search">
					</td>
				</tr>
				<tr>
					<td colspan='2' style="text-align: left;">
						Users highlighted <span style="color: #00FF00;">green</span> are Active<br />
						Users highlighted <span style="color: #FF0000;">red</span> are Inactive<br />
						Users highlighted <span style="color: #B1B1B1;">grey</span> have expired<br />
						Click a User to view it in the Users table<br />
						Click <span style='color: #FFC600'>[Remove]</span> to remove a user from the group
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/DSMS/sudoers-user-groups.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Group</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Group' value='Add Group'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/DSMS/sudoers-user-groups.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Group</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Group' value='Edit Group'></td>
					<td align="center">
						<select name='Edit_Group' style="width: 150px">
ENDHTML

						my $Group_List_Query = $DB_Connection->prepare("SELECT `id`, `groupname`
						FROM `user_groups`
						ORDER BY `groupname` ASC");
						$Group_List_Query->execute( );

						while ( (my $ID, my $Group_Name) = my @Group_List_Query = $Group_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Group_Name</option>";
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

<p style="font-size:14px; font-weight:bold;">User Groups | Groups Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output