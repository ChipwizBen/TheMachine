#!/usr/bin/perl

use strict;
use HTML::Table;

require '../common.pl';
my $DB_Icinga = DB_Icinga();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Time = $CGI->param("Add_Time");
my $Edit_Time = $CGI->param("Edit_Time");

my $Time_Add = $CGI->param("Time_Add");
my $Alias_Add = $CGI->param("Alias_Add");
my $Sunday_Add = $CGI->param("Sunday_Add");
my $Monday_Add = $CGI->param("Monday_Add");
my $Tuesday_Add = $CGI->param("Tuesday_Add");
my $Wednesday_Add = $CGI->param("Wednesday_Add");
my $Thursday_Add = $CGI->param("Thursday_Add");
my $Friday_Add = $CGI->param("Friday_Add");
my $Saturday_Add = $CGI->param("Saturday_Add");
my $Active_Add = $CGI->param("Active_Add");

my $Time_Edit_Post = $CGI->param("Time_Edit_Post");
my $Time_Edit = $CGI->param("Time_Edit");
my $Alias_Edit = $CGI->param("Alias_Edit");
my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Time = $CGI->param("Delete_Time");
my $Time_Delete_Post = $CGI->param("Time_Delete_Post");
my $Time_Delete = $CGI->param("Time_Delete");

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

if ($Add_Time) {
	require "header.cgi";
	&html_output;
	&html_add_time_period;
}
elsif ($Time_Add && $Alias_Add) {
	&add_time_period;
	if ($Active_Add) {
		my $Message_Green="$Time_Add ($Alias_Add) added successfully and set active";
		$Session->param('Message_Green', $Message_Green);
	}
	else {
		my $Message_Orange="$Time_Add ($Alias_Add) added successfully but set inactive";
		$Session->param('Message_Orange', $Message_Orange);
	}
	
	print "Location: nagios-time-periods.cgi\n\n";
	exit(0);
}
elsif ($Edit_Time) {
	require "header.cgi";
	&html_output;
	&html_edit_time_period;
}
elsif ($Time_Edit_Post) {
	&edit_time_period;
	my $Message_Green="$Time_Edit ($Alias_Edit) edited successfully";
	$Session->param('Message_Green', $Message_Green); #Posting Message_Green session var
	print "Location: nagios-time-periods.cgi\n\n";
	exit(0);
}
elsif ($Delete_Time) {
	require "header.cgi";
	&html_output;
	&html_delete_time_period;
}
elsif ($Time_Delete_Post) {
	&delete_time_period;
	my $Message_Green="$Time_Delete deleted successfully";
	$Session->param('Message_Green', $Message_Green); #Posting Message_Green session var
	print "Location: nagios-time-periods.cgi\n\n";
	exit(0);
}
elsif ($Display_Config) {
	require "header.cgi";
	&html_output;
	&html_display_config;
}
else {
	require "header.cgi";
	&html_output;
}



sub html_add_time_period {

print <<ENDHTML;
<div id="small-popup-box">
<a href="Icinga/icinga-time-periods.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Time</h3>

<form action='Icinga/icinga-time-periods.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Time Name (Unique):</td>
		<td colspan="2"><input type='text' name='Time_Add' size='15' maxlength='45' placeholder="Time Name" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Alias/Description:</td>
		<td colspan="2"><input type='text' name='Alias_Add' size='15' maxlength='45' placeholder="Description" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Sunday:</td>
		<td align="left" colspan="2"><input type='text' name='Sunday_Add' size='7' placeholder="03:00-15:00"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Monday:</td>
		<td align="left" colspan="2"><input type='text' name='Monday_Add' size='7' placeholder="03:00-15:00"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Tuesday:</td>
		<td align="left" colspan="2"><input type='text' name='Tuesday_Add' size='7' placeholder="03:00-15:00"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Wednesday:</td>
		<td align="left" colspan="2"><input type='text' name='Wednesday_Add' size='7' placeholder="03:00-15:00"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Thursday:</td>
		<td align="left" colspan="2"><input type='text' name='Thursday_Add' size='7' placeholder="03:00-15:00"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Friday:</td>
		<td align="left" colspan="2"><input type='text' name='Friday_Add' size='7' placeholder="03:00-15:00"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Saturday:</td>
		<td align="left" colspan="2"><input type='text' name='Saturday_Add' size='7' placeholder="03:00-15:00"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Active?:</td>
		<td style="text-align: left;"><input type="radio" name="Active_Add" value="1"> Yes</td>
		<td style="text-align: left;"><input type="radio" name="Active_Add" value="0" checked> No</td>
	</tr>
</table>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Time'></div>

</form>

</div>

ENDHTML

} #sub html_add_time_period

sub add_time_period {

	my $Time_Insert_Check = $DB_Icinga->prepare("SELECT `id`, `alias`
	FROM `nagios_timeperiod`
	WHERE `timeperiod_name` = '$Time_Add'");

	$Time_Insert_Check->execute( );
	my $Time_Rows = $Time_Insert_Check->rows();

	if ($Time_Rows) {
		while ( my @DB_Time = $Time_Insert_Check->fetchrow_array() )
			{

			my $ID_Extract = $DB_Time[0];
			my $Alias_Extract = $DB_Time[1];

			my $Message_Red="$Time_Add already exists (ID: $ID_Extract, Alias: $Alias_Extract), time period not added";
			$Session->param('Message_Red', $Message_Red);
			print "Location: nagios-time-periods.cgi\n\n";
			exit(0);

		}
	}
	else {
		my $Time_Insert = $DB_Icinga->prepare("INSERT INTO `nagios_timeperiod` (
			`id`,
			`timeperiod_name`,
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

		$Time_Insert->execute($Time_Add, $Alias_Add, $Active_Add);

		my $Time_Insert_ID = $DB_Icinga->{mysql_insertid};
		my @Time_Definitions = ($Sunday_Add, $Monday_Add, $Tuesday_Add, $Wednesday_Add, $Thursday_Add, $Friday_Add, $Saturday_Add);

		my $Day_Count;
		foreach (@Time_Definitions) {
			
			my $Day;
			$Day_Count++;
			if ($Day_Count eq 1) {$Day = 'sunday'};
			if ($Day_Count eq 2) {$Day = 'monday'};
			if ($Day_Count eq 3) {$Day = 'tuesday'};
			if ($Day_Count eq 4) {$Day = 'wednesday'};
			if ($Day_Count eq 5) {$Day = 'thursday'};
			if ($Day_Count eq 6) {$Day = 'friday'};
			if ($Day_Count eq 7) {$Day = 'saturday'};
			if ($_ ne undef) {
				my $Time_Definition_Insert = $DB_Icinga->prepare("INSERT INTO `nagios_timedefinition` (
					`id`,
					`tipId`,
					`definition`,
					`range`,
					`last_modified`
				)
				VALUES (
					NULL,
					?,
					?,
					?,
					NOW()
				)");
			
				$Time_Definition_Insert->execute($Time_Insert_ID, $Day, $_);
			}
		}

		

	}

} # sub add_time_period

sub html_edit_time_period {

	my $Select_Time = $DB_Icinga->prepare("SELECT `timeperiod_name`, `alias`, `active`
	FROM `nagios_timeperiod`
	WHERE `id` = '$Edit_Time'");
	$Select_Time->execute( );
	
	while ( my @DB_Time = $Select_Time->fetchrow_array() )
	{
	
		my $Time_Extract = $DB_Time[0];
		my $Alias_Extract = $DB_Time[1];
		my $Active_Extract = $DB_Time[2];

print <<ENDHTML;
<div id="small-popup-box">
<a href="Icinga/icinga-time-periods.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Editing Time <span style="color: #00FF00;">$Time_Extract</span></h3>

<form action='Icinga/icinga-time-periods.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Time Name:</td>
		<td colspan="2"><input type='text' name='Time_Edit' value='$Time_Extract' size='15' maxlength='100' placeholder="Time Name" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Alias/Description:</td>
		<td colspan="2"><input type='text' name='Alias_Edit' value='$Alias_Extract' size='15' maxlength='100' placeholder="Description" required></td>
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

<input type='hidden' name='Time_Edit_Post' value='$Edit_Time'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Time'></div>

</form>

ENDHTML

	}
} # sub html_edit_time_period

sub edit_time_period {

	my $Time_Insert_Check = $DB_Icinga->prepare("SELECT `id`, `alias`
	FROM `nagios_timeperiod`
	WHERE `timeperiod_name` = '$Time_Edit'
	AND `id` != '$Time_Edit_Post'");

	$Time_Insert_Check->execute( );
	my $Time_Rows = $Time_Insert_Check->rows();

	if ($Time_Rows) {
		while ( my @DB_Time = $Time_Insert_Check->fetchrow_array() )
			{

			my $ID_Extract = $DB_Time[0];
			my $Alias_Extract = $DB_Time[1];

			my $Message_Red="$Time_Edit already exists - Conflicting Time ID (This entry): $Time_Edit_Post, Existing Time ID: $ID_Extract, Existing Time Alias: $Alias_Extract";
			$Session->param('Message_Red', $Message_Red);
			print "Location: nagios-time-periods.cgi\n\n";
			exit(0);

		}
	}
	else {

		my $Time_Update = $DB_Icinga->prepare("UPDATE `nagios_timeperiod` SET
			`timeperiod_name` = ?,
			`alias` = ?,
			`active` = ?,
			`last_modified` = NOW(),
			`modified_by` = '$Username'
			WHERE `id` = ?"
		);
		
		$Time_Update->execute($Time_Edit, $Alias_Edit, $Active_Edit, $Time_Edit_Post)
	}

} # sub edit_time_period

sub html_delete_time_period {

	my $Select_Time = $DB_Icinga->prepare("SELECT `timeperiod_name`, `alias`
	FROM `nagios_timeperiod`
	WHERE `id` = '$Delete_Time'");
	$Select_Time->execute( );
	
	while ( my @DB_Time = $Select_Time->fetchrow_array() )
	{
	
		my $Time_Extract = $DB_Time[0];
		my $Alias_Extract = $DB_Time[1];

print <<ENDHTML;
<div id="small-popup-box">
<a href="Icinga/icinga-time-periods.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Time</h3>

<form action='Icinga/icinga-time-periods.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this service group?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Time Name:</td>
		<td style="text-align: left; color: #00FF00;">$Time_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Time Alias:</td>
		<td style="text-align: left; color: #00FF00;">$Alias_Extract</td>
	</tr>
</table>

<input type='hidden' name='Time_Delete_Post' value='$Delete_Time'>
<input type='hidden' name='Time_Delete' value='$Time_Extract'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Time'></div>

</form>

</div>

ENDHTML

	}
} # sub html_delete_time_period

sub delete_time_period {

	my $Delete = $DB_Icinga->prepare("DELETE from `nagios_timeperiod` WHERE `id` = ?");
		$Delete->execute($Time_Delete_Post);
	my $Delete = $DB_Icinga->prepare("DELETE from `nagios_timedefinition` WHERE `tipId` = ?");
		$Delete->execute($Time_Delete_Post);

} # sub delete_time_period

sub html_display_config {

	my $Select_Time = $DB_Icinga->prepare("SELECT `id`, `timeperiod_name`, `alias`, `active`, `last_modified`, `modified_by`
	FROM `nagios_timeperiod`
	WHERE `id` = ?");
	$Select_Time->execute($Display_Config);
	
	while ( my @DB_Time = $Select_Time->fetchrow_array() )
	{
	
		my $Time_ID_Extract = $DB_Time[0];
		my $Time_Name_Extract = $DB_Time[1];
		my $Alias_Extract = $DB_Time[2];
		my $Active_Extract = $DB_Time[3];
		my $Last_Modified_Extract = $DB_Time[4];
		my $Modified_By_Extract = $DB_Time[5];

		my $Select_Definitions = $DB_Icinga->prepare("SELECT `definition`, `range`
		FROM `nagios_timedefinition`
		WHERE `tipId` LIKE ?");
		
		$Select_Definitions->execute($Time_ID_Extract);
		
		my ($Sunday, $Monday, $Tuesday, $Wednesday, $Thursday, $Friday, $Saturday); 
		while ( my @DB_Time_Definition = $Select_Definitions->fetchrow_array() )
		{

			my $Day = $DB_Time_Definition[0];
			my $Range = $DB_Time_Definition[1];

			if ($Day =~ m/su/) {$Sunday = $Range};
			if ($Day =~ m/mo/) {$Monday = $Range};
			if ($Day =~ m/tu/) {$Tuesday = $Range};
			if ($Day =~ m/we/) {$Wednesday = $Range};
			if ($Day =~ m/th/) {$Thursday = $Range};
			if ($Day =~ m/fr/) {$Friday = $Range};
			if ($Day =~ m/sa/) {$Saturday = $Range};

		}

		if (!$Active_Extract) {
			$Active_Extract="<span style='color: #FF8A00;'>
			This time period is not active, so this config will not be written. 
			Make this time period active to use it in Icinga.</span>";
		}
		else {
			$Active_Extract="";
		}

print <<ENDHTML;
<div id="wide-popup-box">
<a href="Icinga/icinga-time-periods.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Live Config for <span style="color: #00FF00;">$Time_Name_Extract</span></h3>

<p>This config is automatically applied regularly. The config below illustrates how this contact group's config will be written.</p>
<p>$Active_Extract</p>
<div style="text-align: left;">
<code>
<table align = "center">
	<tr>
		<td colspan='3'>## Time Period ID: $Display_Config</td>
	</tr>
	<tr>
		<td colspan='3'>## Modified $Last_Modified_Extract by $Modified_By_Extract</td>
	</tr>
	<tr>
		<td colspan='3'>define timeperiod {</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>timeperiod_name</td>
		<td style='padding-left: 2em;'>$Time_Name_Extract</td>
	</tr>
	<tr>
		<td style='padding-left: 2em;'>alias</td>
		<td style='padding-left: 2em;'>$Alias_Extract</td>
	</tr>
ENDHTML

if ($Sunday) {
	print <<ENDHTML;
	<tr>
		<td style='padding-left: 2em;'>sunday</td>
		<td style='padding-left: 2em;'>$Sunday</td>
	</tr>
ENDHTML
		}

if ($Monday) {
	print <<ENDHTML;
	<tr>
		<td style='padding-left: 2em;'>monday</td>
		<td style='padding-left: 2em;'>$Monday</td>
	</tr>
ENDHTML
		}

if ($Tuesday) {
	print <<ENDHTML;
	<tr>
		<td style='padding-left: 2em;'>tuesday</td>
		<td style='padding-left: 2em;'>$Tuesday</td>
	</tr>
ENDHTML
		}

if ($Wednesday) {
	print <<ENDHTML;
	<tr>
		<td style='padding-left: 2em;'>wednesday</td>
		<td style='padding-left: 2em;'>$Wednesday</td>
	</tr>
ENDHTML
		}

if ($Thursday) {
	print <<ENDHTML;
	<tr>
		<td style='padding-left: 2em;'>thursday</td>
		<td style='padding-left: 2em;'>$Thursday</td>
	</tr>
ENDHTML
		}

if ($Friday) {
	print <<ENDHTML;
	<tr>
		<td style='padding-left: 2em;'>friday</td>
		<td style='padding-left: 2em;'>$Friday</td>
	</tr>
ENDHTML
		}

if ($Saturday) {
	print <<ENDHTML;
	<tr>
		<td style='padding-left: 2em;'>saturday</td>
		<td style='padding-left: 2em;'>$Saturday</td>
	</tr>
ENDHTML
		}

print <<ENDHTML;
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
                            -cols=>16,
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


	$Table->addRow ( "ID", "Name", "Alias", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Active", "Last Modified", "Modified By", "View Config", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Select_Times_Count = $DB_Icinga->prepare("SELECT `id` FROM `nagios_timeperiod`");
		$Select_Times_Count->execute( );
		my $Total_Rows = $Select_Times_Count->rows();

	my $Select_Times = $DB_Icinga->prepare("SELECT `id`, `timeperiod_name`, `alias`, `active`, `last_modified`, `modified_by`
	FROM `nagios_timeperiod`
	WHERE (`id` LIKE '%$Filter%'
	OR `timeperiod_name` LIKE '%$Filter%'
	OR `alias` LIKE '%$Filter%')
	ORDER BY `timeperiod_name` ASC
	LIMIT 0 , $Rows_Returned");

	$Select_Times->execute( );
	my $Rows = $Select_Times->rows();
	
	$Table->setRowClass(1, 'tbrow1');

	my $User_Row_Count=1;
	while ( my @DB_Time = $Select_Times->fetchrow_array() )
	{
	
		$User_Row_Count++;

		my $ID_Extract = $DB_Time[0];
			my $ID_Extract_Display = $ID_Extract;
			$ID_Extract_Display =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Name_Extract = $DB_Time[1];
			$Name_Extract =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Alias_Extract = $DB_Time[2];
			$Alias_Extract =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Active_Extract = $DB_Time[3];
		my $Last_Modified_Extract = $DB_Time[4];
		my $Modified_By_Extract = $DB_Time[5];

		my $Select_Definitions = $DB_Icinga->prepare("SELECT `definition`, `range`
		FROM `nagios_timedefinition`
		WHERE `tipId` LIKE ?");
		
		$Select_Definitions->execute($ID_Extract);
		
		my ($Sunday, $Monday, $Tuesday, $Wednesday, $Thursday, $Friday, $Saturday); 
		while ( my @DB_Time_Definition = $Select_Definitions->fetchrow_array() )
		{

			my $Day = $DB_Time_Definition[0];
			my $Range = $DB_Time_Definition[1];
				$Range =~ s/,/\<br \/\>/g;

			if ($Day =~ m/su/) {$Sunday = $Range};
			if ($Day =~ m/mo/) {$Monday = $Range};
			if ($Day =~ m/tu/) {$Tuesday = $Range};
			if ($Day =~ m/we/) {$Wednesday = $Range};
			if ($Day =~ m/th/) {$Thursday = $Range};
			if ($Day =~ m/fr/) {$Friday = $Range};
			if ($Day =~ m/sa/) {$Saturday = $Range};

		}

		if ($Active_Extract) {$Active_Extract='Yes';} else {$Active_Extract='No';}

		$Table->addRow(
			"<a href='Icinga/icinga-time-periods.cgi?Edit_Time=$ID_Extract'>$ID_Extract_Display</a>",
			"<a href='Icinga/icinga-time-periods.cgi?Edit_Time=$ID_Extract'>$Name_Extract</a>",
			$Alias_Extract,
			$Sunday,
			$Monday,
			$Tuesday,
			$Wednesday,
			$Thursday,
			$Friday,
			$Saturday,
			$Active_Extract,
			$Last_Modified_Extract,
			$Modified_By_Extract,
			"<a href='Icinga/icinga-time-periods.cgi?Display_Config=$ID_Extract'><img src=\"resorcs/imgs/view-notes.png\" alt=\"View Config for $Name_Extract\" ></a>",
			"<a href='Icinga/icinga-time-periods.cgi?Edit_Time=$ID_Extract'><img src=\"resorcs/imgs/edit.png\" alt=\"Edit $Name_Extract\" ></a>",
			"<a href='Icinga/icinga-time-periods.cgi?Delete_Time=$ID_Extract'><img src=\"resorcs/imgs/delete.png\" alt=\"Delete $Name_Extract\" ></a>"
		);

		if ($Sunday eq undef) {$Table->setCellClass ($User_Row_Count, 4, 'tbroworange')}
		if ($Monday eq undef) {$Table->setCellClass ($User_Row_Count, 5, 'tbroworange')}
		if ($Tuesday eq undef) {$Table->setCellClass ($User_Row_Count, 6, 'tbroworange')}
		if ($Wednesday eq undef) {$Table->setCellClass ($User_Row_Count, 7, 'tbroworange')}
		if ($Thursday eq undef) {$Table->setCellClass ($User_Row_Count, 8, 'tbroworange')}
		if ($Friday eq undef) {$Table->setCellClass ($User_Row_Count, 9, 'tbroworange')}
		if ($Saturday eq undef) {$Table->setCellClass ($User_Row_Count, 10, 'tbroworange')}

		for (4 .. 16) {
			$Table->setColWidth($_, '1px');
			$Table->setColAlign($_, 'center');
		}

		if ($Active_Extract eq 'Yes') {
			$Table->setCellClass ($User_Row_Count, 11, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($User_Row_Count, 11, 'tbroworange');
		}

	}

print <<ENDHTML;

<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='Icinga/icinga-time-periods.cgi' method='post' >
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
			<form action='Icinga/icinga-time-periods.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Time Period</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Time' value='Add Time Period'></td>
				</tr>
			</table>
			</form>
		</td>
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">Icinga Time Periods | Times Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML

} #sub html_output end
