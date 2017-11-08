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

my $Date = strftime "%Y-%m-%d", localtime;

my $Add_Service = $CGI->param("Add_Service");
	my $Add_Service_Final = $CGI->param("Add_Service_Final");
	my $Add_Service_Dependency_Temp_New = $CGI->param("Add_Service_Dependency_Temp_New");
	my $Add_Service_Dependency_Temp_Existing = $CGI->param("Add_Service_Dependency_Temp_Existing");
	my $Delete_Service_Add_Entry_ID = $CGI->param("Delete_Service_Add_Entry_ID");

my $Service_Name_Add = $CGI->param("Service_Name_Add");
my $Expires_Toggle_Add = $CGI->param("Expires_Toggle_Add");
my $Expires_Date_Add = $CGI->param("Expires_Date_Add");
	$Expires_Date_Add =~ s/\s//g;
	$Expires_Date_Add =~ s/[^0-9\-]//g;
my $Active_Add = $CGI->param("Active_Add");

my $Edit_Service = $CGI->param("Edit_Service");
	my $Edit_Service_Final = $CGI->param("Edit_Service_Final");
	my $Edit_Service_Dependency_Temp_New = $CGI->param("Edit_Service_Dependency_Temp_New");
	my $Edit_Service_Dependency_Temp_Existing = $CGI->param("Edit_Service_Dependency_Temp_Existing");
	my $Delete_Service_Edit_Entry_ID = $CGI->param("Delete_Service_Edit_Entry_ID");

my $Service_Name_Edit = $CGI->param("Service_Name_Edit");
my $Expires_Toggle_Edit = $CGI->param("Expires_Toggle_Edit");
my $Expires_Date_Edit = $CGI->param("Expires_Date_Edit");
	$Expires_Date_Edit =~ s/\s//g;
	$Expires_Date_Edit =~ s/[^0-9\-]//g;
my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Service = $CGI->param("Delete_Service");
my $Delete_Service_Confirm = $CGI->param("Delete_Service_Confirm");
my $Service_Name_Delete = $CGI->param("Service_Name_Delete");

my $Show_Links = $CGI->param("Show_Links");
my $Show_Links_Name = $CGI->param("Show_Links_Name");

my $Show_Chart = $CGI->param("Show_Chart");

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

if ($Add_Service_Final) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
	else {
		my $Service_ID = &add_service;
		my $Message_Green="$Service_Name_Add added successfully as ID $Service_ID";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
}
elsif ($Add_Service) {
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
elsif ($Edit_Service_Final) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
	else {
		&edit_service;
		my $Message_Green="$Service_Name_Edit edited successfully";
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
		my $Message_Green="$Service_Name_Delete deleted successfully";
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
elsif ($Show_Chart) {
	require $Header;
	&html_output;
	require $Footer;
	&html_chart;
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

if ($Add_Service_Dependency_Temp_New) {
	if ($Add_Service_Dependency_Temp_Existing !~ m/^$Add_Service_Dependency_Temp_New,/g &&
	$Add_Service_Dependency_Temp_Existing !~ m/,$Add_Service_Dependency_Temp_New$/g &&
	$Add_Service_Dependency_Temp_Existing !~ m/,$Add_Service_Dependency_Temp_New,/g) {
			$Add_Service_Dependency_Temp_Existing = $Add_Service_Dependency_Temp_Existing . $Add_Service_Dependency_Temp_New . ",";
		}
}

if ($Delete_Service_Add_Entry_ID) {$Add_Service_Dependency_Temp_Existing =~ s/$Delete_Service_Add_Entry_ID//;}
$Add_Service_Dependency_Temp_Existing =~ s/,,/,/g;

my $Services;
my @Services = split(',', $Add_Service_Dependency_Temp_Existing);

foreach my $Service (@Services) {

	my $Service_Alias_Query = $DB_Connection->prepare("SELECT `service`, `expires`, `active`
		FROM `services`
		WHERE `id` = ? ");
	$Service_Alias_Query->execute($Service);

	while ( (my $Service_Name, my $Expires, my $Active) = my @Service_Query = $Service_Alias_Query->fetchrow_array() )
	{

		my $Service_Character_Limited = substr( $Service_Name, 0, 40 );
			if ($Service_Character_Limited ne $Service_Name) {
				$Service_Character_Limited = $Service_Character_Limited . '...';
			}


		my $Expires_Epoch;
		my $Today_Epoch = time;
		if (!$Expires || $Expires =~ /^0000-00-00$/) {
			$Expires = 'Never';
		}
		else {
			$Expires_Epoch = str2time("$Expires"."T23:59:59");
		}

		if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
			$Services = $Services . "<tr><td align='left' style='color: #B1B1B1'>$Service_Character_Limited</td><td><a href='/IP/services.cgi?Delete_Service_Add_Entry_ID=$Service&Add_Service_Dependency_Temp_Existing=$Add_Service_Dependency_Temp_Existing&Add_Service=1' class='tooltip' text=\"Remove $Service_Name from list\"><span style='color: #FFC600'>[Remove]</span></a></td></tr>";
		}
		elsif ($Active) {
			$Services = $Services . "<tr><td align='left' style='color: #00FF00'>$Service_Character_Limited</td><td><a href='/IP/services.cgi?Delete_Service_Add_Entry_ID=$Service&Add_Service_Dependency_Temp_Existing=$Add_Service_Dependency_Temp_Existing&Add_Service=1' class='tooltip' text=\"Remove $Service_Name from list\"><span style='color: #FFC600'>[Remove]</span></a></td></tr>";
		}
		else {
			$Services = $Services . "<tr><td align='left' style='color: #FF0000'>$Service_Character_Limited</td><td><a href='/IP/services.cgi?Delete_Service_Add_Entry_ID=$Service&Add_Service_Dependency_Temp_Existing=$Add_Service_Dependency_Temp_Existing&Add_Service=1' class='tooltip' text=\"Remove $Service_Name from list\"><span style='color: #FFC600'>[Remove]</span></a></td></tr>";
		}
		
	}

}


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
		<td colspan="2"><input type='text' name='Service_Name_Add' style="width:100%" maxlength='128' value='$Service_Name_Add' placeholder="Service Name" required autofocus></td>
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
	<tr>
		<td style="text-align: right;">Add Service:</td>
		<td></td>
		<td colspan='3'>
			<select name='Add_Service_Dependency_Temp_New' onchange='this.form.submit()' style="width: 200px">
ENDHTML

				my $Service_Alias_List_Query = $DB_Connection->prepare("SELECT `id`, `service`, `expires`, `active`
				FROM `services`
				ORDER BY `service` ASC");
				$Service_Alias_List_Query->execute( );
				
				print "<option value='' selected>--Select a Service--</option>";
				
				while ( (my $ID,my $Service, my $Expires, my $Active) = my @Service_List_Query = $Service_Alias_List_Query->fetchrow_array() )
				{

					my $Service_Character_Limited = substr( $Service, 0, 40 );
						if ($Service_Character_Limited ne $Service) {
							$Service_Character_Limited = $Service_Character_Limited . '...';
						}

					my $Expires_Epoch;
					my $Today_Epoch = time;
					if (!$Expires || $Expires =~ /^0000-00-00$/) {
						$Expires = 'Never';
					}
					else {
						$Expires_Epoch = str2time("$Expires"."T23:59:59");
					}

					if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
						print "<option style='color: #B1B1B1;' value='$ID'>$Service_Character_Limited [Expired]</option>";
					}
					elsif ($Active) {
						print "<option value='$ID'>$Service_Character_Limited</option>";
					}
					else {
						print "<option style='color: #FF0000;' value='$ID'>$Service_Character_Limited [Inactive]</option>";
					}
					
				}

print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Services Depended On:</td>
		<td></td>
		<td colspan='3' style="text-align: left;">
ENDHTML

if ($Services) {
print <<ENDHTML;
			<table>
				<tr>
					<td>Service</td>
				</tr>
				$Services
			</table>
ENDHTML
}
else {
	print "<span style='text-align: left; color: #FFC600;'>None</span>";
}

print <<ENDHTML;
		</td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
</ul>

<input type='hidden' name='Add_Service' value='1'>
<input type='hidden' name='Add_Service_Dependency_Temp_Existing' value='$Add_Service_Dependency_Temp_Existing'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='Add_Service_Final' value='Add Service'></div>

</form>

ENDHTML

} #sub html_add_service

sub add_service {

	### Existing Service_Name Check
	my $Existing_Service_Name_Check = $DB_Connection->prepare("SELECT `id`
		FROM `services`
		WHERE `service` = ?");
		$Existing_Service_Name_Check->execute($Service_Name_Add);
		my $Existing_Services = $Existing_Service_Name_Check->rows();

	if ($Existing_Services > 0)  {
		my $Existing_ID;
		while ( my @Select_Service_Names = $Existing_Service_Name_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Service_Names[0];
		}
		my $Message_Red="Service_Name: $Service_Name_Add already exists as ID: $Existing_ID";
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

	$Service_Insert->execute($Service_Name_Add, $Expires_Date_Add, $Active_Add, $User_Name);

	my $Service_Insert_ID = $DB_Connection->{mysql_insertid};

	$Add_Service_Dependency_Temp_Existing =~ s/,$//;
	my @Services = split(',', $Add_Service_Dependency_Temp_Existing);
	my $Service_Alias_Count=0;

	foreach my $Dependent_Service (@Services) {

		$Service_Alias_Count++;

		my $Service_Dependency_Insert = $DB_Connection->prepare("INSERT INTO `service_dependency` (
			`id`,
			`service_id`,
			`dependent_service_id`
		)
		VALUES (
			NULL,
			?,
			?
		)");
		
		$Service_Dependency_Insert->execute($Dependent_Service, $Service_Insert_ID);

	}

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
	
	$Audit_Log_Submission->execute("Services", "Add", "$User_Name edited $Service_Name_Edit (ID: $Edit_Service), set it $Active_Edit and to $Expires_Date_Edit.", $User_Name);
	# / Audit Log

	return($Service_Insert_ID);

} # sub add_service

sub html_edit_service {

	## Existing Service Dependencies

	my $Select_Service_Dependencies = $DB_Connection->prepare("SELECT `service_id`
		FROM `service_dependency`
		WHERE `dependent_service_id` LIKE ?");

	$Select_Service_Dependencies->execute($Edit_Service);

	my $Discovered_Existing_Dependencies;
	while ( my $Service_Dependencies = $Select_Service_Dependencies->fetchrow_array() ) {
		$Discovered_Existing_Dependencies = $Discovered_Existing_Dependencies . $Service_Dependencies . ',';
	}

	if (!$Edit_Service_Dependency_Temp_Existing) {
		$Edit_Service_Dependency_Temp_Existing = $Discovered_Existing_Dependencies;
	}

	## / Existing Service Dependencies

	my $Select_Service = $DB_Connection->prepare("SELECT `service`, `expires`, `active`
	FROM `services`
	WHERE `id` = ?");
	$Select_Service->execute($Edit_Service);
	
	while ( my @DB_Service = $Select_Service->fetchrow_array() )
	{
	
		my $Service_Name_Extract = $DB_Service[0];
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

		if ($Edit_Service_Dependency_Temp_New) {
			if ($Edit_Service_Dependency_Temp_Existing !~ m/^$Edit_Service_Dependency_Temp_New,/g &&
			$Edit_Service_Dependency_Temp_Existing !~ m/,$Edit_Service_Dependency_Temp_New$/g &&
			$Edit_Service_Dependency_Temp_Existing !~ m/,$Edit_Service_Dependency_Temp_New,/g) {
					$Edit_Service_Dependency_Temp_Existing = $Edit_Service_Dependency_Temp_Existing . $Edit_Service_Dependency_Temp_New . ",";
				}
		}
		
		if ($Delete_Service_Edit_Entry_ID) {$Edit_Service_Dependency_Temp_Existing =~ s/$Delete_Service_Edit_Entry_ID//;}
		$Edit_Service_Dependency_Temp_Existing =~ s/,,/,/g;
		
		my $Services;
		my @Services = split(',', $Edit_Service_Dependency_Temp_Existing);
		
		foreach my $Service (@Services) {
		
			my $Service_Alias_Query = $DB_Connection->prepare("SELECT `service`, `expires`, `active`
				FROM `services`
				WHERE `id` = ? ");
			$Service_Alias_Query->execute($Service);
		
			while ( (my $Service_Name, my $Expires, my $Active) = my @Service_Query = $Service_Alias_Query->fetchrow_array() )
			{
		
				my $Service_Character_Limited = substr( $Service_Name, 0, 40 );
					if ($Service_Character_Limited ne $Service_Name) {
						$Service_Character_Limited = $Service_Character_Limited . '...';
					}
		
		
				my $Expires_Epoch;
				my $Today_Epoch = time;
				if (!$Expires || $Expires =~ /^0000-00-00$/) {
					$Expires = 'Never';
				}
				else {
					$Expires_Epoch = str2time("$Expires"."T23:59:59");
				}
		
				if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
					$Services = $Services . "<tr><td align='left' style='color: #B1B1B1'>$Service_Character_Limited</td><td><a href='/IP/services.cgi?Delete_Service_Edit_Entry_ID=$Service&Edit_Service_Dependency_Temp_Existing=$Edit_Service_Dependency_Temp_Existing&Edit_Service=$Edit_Service' class='tooltip' text=\"Remove $Service_Name from list\"><span style='color: #FFC600'>[Remove]</span></a></td></tr>";
				}
				elsif ($Active) {
					$Services = $Services . "<tr><td align='left' style='color: #00FF00'>$Service_Character_Limited</td><td><a href='/IP/services.cgi?Delete_Service_Edit_Entry_ID=$Service&Edit_Service_Dependency_Temp_Existing=$Edit_Service_Dependency_Temp_Existing&Edit_Service=$Edit_Service' class='tooltip' text=\"Remove $Service_Name from list\"><span style='color: #FFC600'>[Remove]</span></a></td></tr>";
				}
				else {
					$Services = $Services . "<tr><td align='left' style='color: #FF0000'>$Service_Character_Limited</td><td><a href='/IP/services.cgi?Delete_Service_Edit_Entry_ID=$Service&Edit_Service_Dependency_Temp_Existing=$Edit_Service_Dependency_Temp_Existing&Edit_Service=$Edit_Service' class='tooltip' text=\"Remove $Service_Name from list\"><span style='color: #FFC600'>[Remove]</span></a></td></tr>";
				}
				
			}
		
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
		<td colspan="2"><input type='text' name='Service_Name_Edit' style="width:100%" maxlength='128' value='$Service_Name_Extract' placeholder="Service Name" required autofocus></td>
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
	<tr>
		<td style="text-align: right;">Edit Service:</td>
		<td></td>
		<td colspan='3'>
			<select name='Edit_Service_Dependency_Temp_New' onchange='this.form.submit()' style="width: 200px">
ENDHTML

				my $Service_Alias_List_Query = $DB_Connection->prepare("SELECT `id`, `service`, `expires`, `active`
				FROM `services`
				ORDER BY `service` ASC");
				$Service_Alias_List_Query->execute( );
				
				print "<option value='' selected>--Select a Service--</option>";
				
				while ( (my $ID,my $Service, my $Expires, my $Active) = my @Service_List_Query = $Service_Alias_List_Query->fetchrow_array() )
				{

					my $Service_Character_Limited = substr( $Service, 0, 40 );
						if ($Service_Character_Limited ne $Service) {
							$Service_Character_Limited = $Service_Character_Limited . '...';
						}

					my $Expires_Epoch;
					my $Today_Epoch = time;
					if (!$Expires || $Expires =~ /^0000-00-00$/) {
						$Expires = 'Never';
					}
					else {
						$Expires_Epoch = str2time("$Expires"."T23:59:59");
					}

					if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
						print "<option style='color: #B1B1B1;' value='$ID'>$Service_Character_Limited [Expired]</option>";
					}
					elsif ($Active) {
						print "<option value='$ID'>$Service_Character_Limited</option>";
					}
					else {
						print "<option style='color: #FF0000;' value='$ID'>$Service_Character_Limited [Inactive]</option>";
					}
					
				}

print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Services Depended On:</td>
		<td></td>
		<td colspan='3' style="text-align: left;">
ENDHTML

if ($Services) {
print <<ENDHTML;
			<table>
				<tr>
					<td>Service</td>
				</tr>
				$Services
			</table>
ENDHTML
}
else {
	print "<span style='text-align: left; color: #FFC600;'>None</span>";
}

print <<ENDHTML;
		</td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; pEditing-left: 40px; pEditing-right: 40px;'>
</ul>

<input type='hidden' name='Edit_Service' value='$Edit_Service'>
<input type='hidden' name='Edit_Service_Dependency_Temp_Existing' value='$Edit_Service_Dependency_Temp_Existing'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='Edit_Service_Final' value='Edit Service'></div>

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
		$Existing_Service_Name_Check->execute($Service_Name_Edit, $Edit_Service);
		my $Existing_Services = $Existing_Service_Name_Check->rows();

	if ($Existing_Services > 0)  {
		my $Existing_ID;
		while ( my @Select_Service_Names = $Existing_Service_Name_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Service_Names[0];
		}
		my $Message_Red="Service_Name: $Service_Name_Edit already exists as ID: $Existing_ID";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/services.cgi\n\n";
		exit(0);
	}
	### / Existing Service_Name Check

	if ($Expires_Toggle_Edit ne 'on') {
		$Expires_Date_Edit = undef;
	}

	my $Update_Service = $DB_Connection->prepare("UPDATE `services` SET
		`service` = ?,
		`expires` = ?,
		`active` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		
	$Update_Service->execute($Service_Name_Edit, $Expires_Date_Edit, $Active_Edit, $User_Name, $Edit_Service);

	$Edit_Service_Dependency_Temp_Existing =~ s/,$//;
	my @Services = split(',', $Edit_Service_Dependency_Temp_Existing);
	my $Service_Alias_Count=0;

	my $Service_Dependency_Delete = $DB_Connection->prepare("DELETE FROM `service_dependency`
		WHERE `dependent_service_id` = ?");

	$Service_Dependency_Delete->execute($Edit_Service);

	foreach my $Dependent_Service (@Services) {

		$Service_Alias_Count++;

		my $Service_Dependency_Insert = $DB_Connection->prepare("INSERT INTO `service_dependency` (
			`id`,
			`service_id`,
			`dependent_service_id`
		)
		VALUES (
			NULL,
			?,
			?
		)");
		
		$Service_Dependency_Insert->execute($Dependent_Service, $Edit_Service);

	}

	# Audit Log
	if (!$Expires_Date_Edit || $Expires_Date_Edit eq '0000-00-00') {
		$Expires_Date_Edit = 'not expire';
	}
	else {
		$Expires_Date_Edit = "expire on " . $Expires_Date_Edit;
	}

	if ($Active_Edit) {$Active_Edit = 'Active'} else {$Active_Edit = 'Inactive'}

	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();
	
	$Audit_Log_Submission->execute("Services", "Edit", "$User_Name edited $Service_Name_Edit (ID: $Edit_Service), set it $Active_Edit and to $Expires_Date_Edit.", $User_Name);
	# / Audit Log

	return($Edit_Service);

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
	my $Service_Name;
	my $Select_Service_Name = $DB_Connection->prepare("SELECT `service`
	FROM `services`
	WHERE `id` = ?");

	$Select_Service_Name->execute($View_Notes);
	$Service_Name = $Select_Service_Name->fetchrow_array();
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

<h3 align="center">Notes for $Service_Name</h3>
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

sub html_chart {

	my $Select_Service_Name = $DB_Connection->prepare("SELECT `service`
		FROM `services`
		WHERE `id` LIKE ?");
	$Select_Service_Name->execute($Show_Chart);
	my $Service_Name = $Select_Service_Name->fetchrow_array();

	use GraphViz;

	my $Graph = GraphViz->new(
		name => 'ServiceDependencies',
		layout => 'dot',
		rankdir => 'BT', # Bottom to Top
		edge   => {color => 'grey'},
		global => {directed => 1},
		graph  => {label => "$Service_Name Service Dependencies"},
		node   => {shape => 'oval'},);

	$Graph->add_node("$Service_Name", color => '#FF0000');

	my $Select_Service_Depends_On = $DB_Connection->prepare("SELECT `service_id`
		FROM `service_dependency`
			WHERE `dependent_service_id` LIKE ?");

	$Select_Service_Depends_On->execute($Show_Chart);

	my $All_Dependencies;
	while ( my @Service_Depends_On = $Select_Service_Depends_On->fetchrow_array() )
	{

		my $Dependency_Service_ID = $Service_Depends_On[0];

		my $Select_Dependent_Services = $DB_Connection->prepare("SELECT `service`
			FROM `services`
			WHERE `id` LIKE ?");
		$Select_Dependent_Services->execute($Dependency_Service_ID);

		while ( my @Dependencies = $Select_Dependent_Services->fetchrow_array() )
		{
			my $Dependency_Service_Name = $Dependencies[0];
  
  			# rank => 'top' # Nodes can be located in the same rank (that is, at the same level in the graph) 
  			# with the "rank" attribute. Nodes with the same rank value are ranked together.
			$Graph->add_node("$Dependency_Service_Name");
			$Graph->add_edge("$Service_Name" => "$Dependency_Service_Name", label => 'Depends On');
  
		}
	}

	my $SVG = $Graph->as_svg;
	$SVG = "<svg zoomAndPan='magnify' viewBox='0 0 800 500'>$SVG</svg>";

	#my $SVG = $Graph->as_png;
	#$SVG = "<img src='data:image/png;$SVG'></img>";

print <<ENDHTML;
<div id="wide-popup-box">
<a href="/IP/services.cgi">
<div id="blockclosebutton">
</div>
</a>

<p align=center>$SVG</p>

ENDHTML

} # html_chart

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

	$Table->addRow( "ID", "Service Name", "Depends On", "Expires", "Active", "Last Modified", "Modified By", "Show Chart", "Show Links", "Notes", "Edit", "Delete" );
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

		my $Select_Service_Depends_On = $DB_Connection->prepare("SELECT `service_id`
			FROM `service_dependency`
				WHERE `dependent_service_id` LIKE ?");

		$Select_Service_Depends_On->execute($DBID_Clean);

		my $All_Dependencies;
		while ( my @Service_Depends_On = $Select_Service_Depends_On->fetchrow_array() )
		{

			my $Dependency_Service_ID = $Service_Depends_On[0];

			my $Select_Dependent_Services = $DB_Connection->prepare("SELECT `service`, `expires`, `active`
				FROM `services`
				WHERE `id` LIKE ?");
			$Select_Dependent_Services->execute($Dependency_Service_ID);

			while ( my @Dependencies = $Select_Dependent_Services->fetchrow_array() )
			{
				my $Dependency_Service_Name = $Dependencies[0];
				my $Dependency_Expires = $Dependencies[1];
				my $Dependency_Active = $Dependencies[2];

				my $Dependency_Expires_Epoch;
				my $Today_Epoch = time;
				if (!$Dependency_Expires || $Dependency_Expires =~ /^0000-00-00$/) {
					$Dependency_Expires = 'Never';
				}
				else {
					$Dependency_Expires_Epoch = str2time("$Expires_Clean"."T23:59:59");
				}
		
				if ($Dependency_Expires ne 'Never' && $Dependency_Expires_Epoch < $Today_Epoch) {
					$Table->setCellClass ($Service_Row_Count, 3, 'tbrowdarkgrey');
					$Dependency_Service_Name = '<span style="color: #8F8F8F;">' . $Dependency_Service_Name . '</span>'
				}
				elsif (!$Dependency_Active) {
					$Dependency_Service_Name = '<span style="color: #FF0000;">' . $Dependency_Service_Name . '</span>'
				}

				$All_Dependencies = $All_Dependencies . $Dependency_Service_Name . ', ';
			}
		}
		$All_Dependencies =~ s/,\s$//;

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
			"$All_Dependencies",
			"$Expires",
			"$Active",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/IP/services.cgi?Show_Chart=$DBID_Clean'><img src=\"/Resources/Images/graph.png\" alt=\"Dependencies of Service ID $DBID_Clean\" ></a>",
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
			$Table->setCellClass ($Service_Row_Count, 5, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($Service_Row_Count, 5, 'tbrowred');
		}

		if ($Expires ne 'Never' && $Expires_Epoch < $Today_Epoch) {
			$Table->setCellClass ($Service_Row_Count, 4, 'tbrowdarkgrey');
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
	$Table->setColWidth(12, '1px');

	$Table->setColAlign(1, 'center');
	for (4..12) {
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