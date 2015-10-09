#!/usr/bin/perl

use strict;
use HTML::Table;

require '../common.pl';
my $DB_Icinga = DB_Icinga();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Group = $CGI->param("Add_Group");
my $Edit_Group = $CGI->param("Edit_Group");

my $Group_Add = $CGI->param("Group_Add");
my $Alias_Add = $CGI->param("Alias_Add");
my $Active_Add = $CGI->param("Active_Add");

my $Group_Edit_Post = $CGI->param("Group_Edit_Post");
my $Group_Edit = $CGI->param("Group_Edit");
my $Alias_Edit = $CGI->param("Alias_Edit");
my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Group = $CGI->param("Delete_Group");
my $Group_Delete_Post = $CGI->param("Group_Delete_Post");
my $Group_Delete = $CGI->param("Group_Delete");

my $Display_Config = $CGI->param("Display_Config");

my $Filter = $CGI->param("Filter");

my $Username = $Session->param("User_Name");
my $User_Admin = $Session->param("User_Admin");

my $Rows_Returned = $CGI->param("Rows_Returned");
	if ($Rows_Returned eq '') {
		$Rows_Returned='100';
	}

if (!$Username) {
	print "Location: logout.cgi\n\n";
	exit(0);
}

if ($User_Admin ne '1') {
	my $Message_Red = 'You do not have sufficient privileges to access that page.';
	$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
	print "Location: index.cgi\n\n";
	exit(0);
}

if ($Add_Group) {
	require "../header.cgi";
	&html_output;
	&html_add_group;
}
elsif ($Group_Add && $Alias_Add) {
	&add_group;
	if ($Active_Add) {
		my $Message_Green="$Group_Add ($Alias_Add) added successfully and set active";
		$Session->param('Message_Green', $Message_Green);
	}
	else {
		my $Message_Orange="$Group_Add ($Alias_Add) added successfully but set inactive";
		$Session->param('Message_Orange', $Message_Orange);
	}
	
	print "Location: nagios-contact-groups.cgi\n\n";
	exit(0);
}
elsif ($Edit_Group) {
	require "../header.cgi";
	&html_output;
	&html_edit_group;
}
elsif ($Group_Edit_Post) {
	&edit_group;
	my $Message_Green="$Group_Edit ($Alias_Edit) edited successfully";
	$Session->param('Message_Green', $Message_Green); #Posting Message_Green session var
	print "Location: nagios-contact-groups.cgi\n\n";
	exit(0);
}
elsif ($Delete_Group) {
	require "../header.cgi";
	&html_output;
	&html_delete_group;
}
elsif ($Group_Delete_Post) {
	&delete_group;
	my $Message_Green="$Group_Delete deleted successfully";
	$Session->param('Message_Green', $Message_Green); #Posting Message_Green session var
	print "Location: nagios-contact-groups.cgi\n\n";
	exit(0);
}
elsif ($Display_Config) {
	require "../header.cgi";
	&html_output;
	&html_display_config;
}
else {
	require "../header.cgi";
	&html_output;
}



sub html_add_group {

print <<ENDHTML;
<div id="small-popup-box">
<a href="Icinga/icinga-contact-groups.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Group</h3>

<form action='Icinga/icinga-contact-groups.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Group Name (Unique):</td>
		<td colspan="2"><input type='text' name='Group_Add' size='15' maxlength='255' placeholder="Group Name" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Alias/Description:</td>
		<td colspan="2"><input type='text' name='Alias_Add' size='15' maxlength='255' placeholder="Description" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Active?:</td>
		<td style="text-align: left;"><input type="radio" name="Active_Add" value="1"> Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Add" value="0" checked> No</td>
	</tr>
</table>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Group'></div>

</form>

</div>

ENDHTML

} #sub html_add_group

sub add_group {

	my $Group_Insert_Check = $DB_Icinga->prepare("SELECT `id`, `alias`
	FROM `nagios_contactgroup`
	WHERE `contactgroup_name` = '$Group_Add'");

	$Group_Insert_Check->execute( );
	my $Group_Rows = $Group_Insert_Check->rows();

	if ($Group_Rows) {
		while ( my @DB_Group = $Group_Insert_Check->fetchrow_array() )
			{

			my $ID_Extract = $DB_Group[0];
			my $Alias_Extract = $DB_Group[1];

			my $Message_Red="$Group_Add already exists (ID: $ID_Extract, Alias: $Alias_Extract)";
			$Session->param('Message_Red', $Message_Red);
			print "Location: nagios-contact-groups.cgi\n\n";
			exit(0);

		}
	}
	else {
		my $Group_Insert = $DB_Icinga->prepare("INSERT INTO `nagios_contactgroup` (
			`id`,
			`contactgroup_name`,
			`alias`,
			`active`,
			`last_modified`,
			`modified_by`
		)
		VALUES (
			NULL,
			?,
			?,
			?,
			NOW(),
			'$Username'
		)");

		$Group_Insert->execute($Group_Add, $Alias_Add, $Active_Add);
	}

} # sub add_group

sub html_edit_group {

	my $Select_Group = $DB_Icinga->prepare("SELECT `contactgroup_name`, `alias`, `active`
	FROM `nagios_contactgroup`
	WHERE `id` = '$Edit_Group'");
	$Select_Group->execute( );
	
	while ( my @DB_Group = $Select_Group->fetchrow_array() )
	{
	
		my $Group_Extract = $DB_Group[0];
		my $Alias_Extract = $DB_Group[1];
		my $Active_Extract = $DB_Group[2];

print <<ENDHTML;
<div id="small-popup-box">
<a href="Icinga/icinga-contact-groups.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Editing Group <span style="color: #00FF00;">$Group_Extract</span></h3>

<form action='Icinga/icinga-contact-groups.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Group Name:</td>
		<td colspan="2"><input type='text' name='Group_Edit' value='$Group_Extract' size='15' maxlength='255' placeholder="Group Name" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Alias/Description:</td>
		<td colspan="2"><input type='text' name='Alias_Edit' value='$Alias_Extract' size='15' maxlength='255' placeholder="Description" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Active?:</td>
ENDHTML

if ($Active_Extract == 1) {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Active_Edit" value="1" checked> Yes</td>
		<td style="text-align: right;"><input type="radio" name="Active_Edit" value="0"> No</td>
ENDHTML
}
else {
print <<ENDHTML;
		<td style="text-align: right;"><input type="radio" name="Active_Edit" value="1"> Yes</td>
		<td style="text-align: right;"><input type="radio" name="Active_Edit" value="0" checked> No</td>
ENDHTML
}


print <<ENDHTML;
	</tr>
</table>

<input type='hidden' name='Group_Edit_Post' value='$Edit_Group'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Group'></div>

</form>

ENDHTML

	}
} # sub html_edit_group

sub edit_group {

	my $Group_Insert_Check = $DB_Icinga->prepare("SELECT `id`, `alias`
	FROM `nagios_contactgroup`
	WHERE `contactgroup_name` = '$Group_Edit'
	AND `id` != '$Group_Edit_Post'");

	$Group_Insert_Check->execute( );
	my $Group_Rows = $Group_Insert_Check->rows();

	if ($Group_Rows) {
		while ( my @DB_Group = $Group_Insert_Check->fetchrow_array() )
			{

			my $ID_Extract = $DB_Group[0];
			my $Alias_Extract = $DB_Group[1];

			my $Message_Red="$Group_Edit already exists - Conflicting Group ID (This entry): $Group_Edit_Post, Existing Group ID: $ID_Extract, Existing Group Alias: $Alias_Extract";
			$Session->param('Message_Red', $Message_Red);
			print "Location: nagios-contact-groups.cgi\n\n";
			exit(0);

		}
	}
	else {

		my $Group_Update = $DB_Icinga->prepare("UPDATE `nagios_contactgroup` SET
			`contactgroup_name` = ?,
			`alias` = ?,
			`active` = ?,
			`last_modified` = NOW(),
			`modified_by` = '$Username'
			WHERE `id` = ?"
		);
		
		$Group_Update->execute($Group_Edit, $Alias_Edit, $Active_Edit, $Group_Edit_Post)
	}

} # sub edit_group

sub html_delete_group {

	my $Select_Group = $DB_Icinga->prepare("SELECT `contactgroup_name`, `alias`
	FROM `nagios_contactgroup`
	WHERE `id` = '$Delete_Group'");
	$Select_Group->execute( );
	
	while ( my @DB_Group = $Select_Group->fetchrow_array() )
	{
	
		my $Group_Extract = $DB_Group[0];
		my $Alias_Extract = $DB_Group[1];

print <<ENDHTML;
<div id="small-popup-box">
<a href="Icinga/icinga-contact-groups.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Group</h3>

<form action='Icinga/icinga-contact-groups.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this service group?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Group Name:</td>
		<td style="text-align: left; color: #00FF00;">$Group_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Group Alias:</td>
		<td style="text-align: left; color: #00FF00;">$Alias_Extract</td>
	</tr>
</table>

<input type='hidden' name='Group_Delete_Post' value='$Delete_Group'>
<input type='hidden' name='Group_Delete' value='$Group_Extract'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Group'></div>

</form>

</div>

ENDHTML

	}
} # sub html_delete_group

sub delete_group {

	$DB_Icinga->do("DELETE from `nagios_contactgroup`
				WHERE `id` = '$Group_Delete_Post'");

} # sub delete_group

sub html_display_config {

	my $Members;
	my $Select_Group = $DB_Icinga->prepare("SELECT `contactgroup_name`, `alias`, `active`, `last_modified`, `modified_by`
	FROM `nagios_contactgroup`
	WHERE `id` = ?");
	$Select_Group->execute($Display_Config);
	
	while ( my @DB_Group = $Select_Group->fetchrow_array() )
	{
	
		my $Group_Extract = $DB_Group[0];
		my $Alias_Extract = $DB_Group[1];
		my $Active_Extract = $DB_Group[2];
		my $Last_Modified_Extract = $DB_Group[3];
		my $Modified_By_Extract = $DB_Group[4];

		my $Select_Members = $DB_Icinga->prepare("SELECT `idMaster`
		FROM `nagios_lnkContactToContactgroup`
		WHERE `idSlave` = ?");
		$Select_Members->execute($Display_Config);
		
		while ( my @DB_Members = $Select_Members->fetchrow_array() )
		{
			my $idMaster = $DB_Members[0];
			
			my $Select_Member_Names = $DB_Icinga->prepare("SELECT `contact_name`
			FROM `nagios_contact`
			WHERE `id` = ?");
			$Select_Member_Names->execute($idMaster);

			while ( my @DB_Member_Names = $Select_Member_Names->fetchrow_array() )
			{
				my $Member = $DB_Member_Names[0];
				$Members = $Member.", ".$Members;
			}
		}

		$Members =~ s/, $//g;

		if (!$Active_Extract) {
			$Active_Extract="<span style='color: #FF8A00;'>
			This contact group is not active, so this config will not be written. 
			Make this contact group active to use it in Icinga.</span>";
		}
		else {
			$Active_Extract="";
		}

print <<ENDHTML;
<div id="small-popup-box">
<a href="Icinga/icinga-contact-groups.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Live Config for <span style="color: #00FF00;">$Group_Extract</span></h3>

<p>This config is automatically applied regularly. The config below illustrates how this contact group's config will be written.</p>
<p>$Active_Extract</p>
<div style="text-align: left;">
<code>
<table align = "center">
	<tr>
		<td colspan='3'>## Contact Group ID: $Display_Config</td>
	</tr>
	<tr>
		<td colspan='3'>## Modified $Last_Modified_Extract by $Modified_By_Extract</td>
	</tr>
	<tr>
		<td colspan='3'>define contactgroup {</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>contactgroup_name</td>
		<td style='padding-left: 2em;'>$Group_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>alias</td>
		<td style='padding-left: 2em;'>$Alias_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>members</td>
		<td style='padding-left: 2em;'>$Members</td>
	</tr>
	<tr>
		<td colspan='3'>}</td>
	</tr>
</table>

</code>
</div>
<br />

</div>

ENDHTML

	}
} # sub html_display_config

sub html_output {

	my $Table = new HTML::Table(
                            -cols=>9,
                            -align=>'center',
                            -rules=>'all',
                            -border=>0,
                            -bgcolor=>'25aae1',
                            -evenrowclass=>'tbeven',
                            -oddrowclass=>'tbodd',
                            -class=>'statustable',
                            -width=>'100%',
                            -spacing=>0,
                            -padding=>1 );


	$Table->addRow ( "ID", "Name", "Alias", "Active", "Last Modified", "Modified By", "View Config", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Select_Groups_Count = $DB_Icinga->prepare("SELECT `id` FROM `nagios_contactgroup`");
		$Select_Groups_Count->execute( );
		my $Total_Rows = $Select_Groups_Count->rows();

	my $Select_Groups = $DB_Icinga->prepare("SELECT `id`, `contactgroup_name`, `alias`, `active`, `last_modified`, `modified_by`
	FROM `nagios_contactgroup`
	WHERE (`id` LIKE '%$Filter%'
	OR `contactgroup_name` LIKE '%$Filter%'
	OR `alias` LIKE '%$Filter%')
	ORDER BY `contactgroup_name` ASC
	LIMIT 0 , $Rows_Returned");

	$Select_Groups->execute( );
	my $Rows = $Select_Groups->rows();
	
	$Table->setRowClass(1, 'tbrow1');

	my $User_Row_Count=1;
	while ( my @DB_Group = $Select_Groups->fetchrow_array() )
	{
	
		$User_Row_Count++;

		my $ID_Extract = $DB_Group[0];
			my $ID_Extract_Display = $ID_Extract;
			$ID_Extract_Display =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Name_Extract = $DB_Group[1];
			$Name_Extract =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Alias_Extract = $DB_Group[2];
			$Alias_Extract =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Active_Extract = $DB_Group[3];
		my $Last_Modified_Extract = $DB_Group[4];
		my $Modified_By_Extract = $DB_Group[5];

		if ($Active_Extract) {$Active_Extract='Yes';} else {$Active_Extract='No';}

		$Table->addRow(
			"<a href='Icinga/icinga-contact-groups.cgi?Edit_Group=$ID_Extract'>$ID_Extract_Display</a>",
			"<a href='Icinga/icinga-contact-groups.cgi?Edit_Group=$ID_Extract'>$Name_Extract</a>",
			$Alias_Extract,
			$Active_Extract,
			$Last_Modified_Extract,
			$Modified_By_Extract,
			"<a href='Icinga/icinga-contact-groups.cgi?Display_Config=$ID_Extract'><img src=\"resorcs/imgs/view-notes.png\" alt=\"View Config for $Name_Extract\" ></a>",
			"<a href='Icinga/icinga-contact-groups.cgi?Edit_Group=$ID_Extract'><img src=\"resorcs/imgs/edit.png\" alt=\"Edit $Name_Extract\" ></a>",
			"<a href='Icinga/icinga-contact-groups.cgi?Delete_Group=$ID_Extract'><img src=\"resorcs/imgs/delete.png\" alt=\"Delete $Name_Extract\" ></a>"
		);

		for (4 .. 9) {
			$Table->setColWidth($_, '1px');
			$Table->setColAlign($_, 'center');
		}

		if ($Active_Extract eq 'Yes') {
			$Table->setCellClass ($User_Row_Count, 4, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($User_Row_Count, 4, 'tbroworange');
		}

	}

print <<ENDHTML;

<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='Icinga/icinga-contact-groups.cgi' method='post' >
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
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">Search:</td>
					<td style="text-align: right;"><input type='search' style="width: 150px" name='Filter' maxlength='100' value="$Filter" title="Search" placeholder="Search"></td>
				</tr>
				</form>
			</table>
		</td>
		<td align="right">
			<form action='Icinga/icinga-contact-groups.cgi' method='post' >
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
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">Icinga Contact Groups | Groups Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML

} #sub html_output end
