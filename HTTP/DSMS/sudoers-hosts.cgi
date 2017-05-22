#!/usr/bin/perl -T

use strict;
use lib qw(resources/modules);
use lib qw(../resources/modules);
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

my $Add_Host = $CGI->param("Add_Host");
my $Edit_Host = $CGI->param("Edit_Host");

my $Host_Name_Add = $CGI->param("Host_Name_Add");
	$Host_Name_Add =~ s/\s//g;
	$Host_Name_Add =~ s/[^a-zA-Z0-9\-\.]//g;
my $IP_Add = $CGI->param("IP_Add");
	$IP_Add =~ s/\s//g;
	$IP_Add =~ s/[^0-9\.]//g;
my $DHCP_Toggle_Add = $CGI->param("DHCP_Toggle_Add");
	if ($DHCP_Toggle_Add eq 'on') {
		$IP_Add = 'DHCP';
	}
my $Expires_Toggle_Add = $CGI->param("Expires_Toggle_Add");
my $Expires_Date_Add = $CGI->param("Expires_Date_Add");
	$Expires_Date_Add =~ s/\s//g;
	$Expires_Date_Add =~ s/[^0-9\-]//g;
my $Active_Add = $CGI->param("Active_Add");

my $Edit_Host_Post = $CGI->param("Edit_Host_Post");
my $Host_Name_Edit = $CGI->param("Host_Name_Edit");
	$Host_Name_Edit =~ s/\s//g;
	$Host_Name_Edit =~ s/[^a-zA-Z0-9\-\.]//g;
my $IP_Edit = $CGI->param("IP_Edit");
	$IP_Edit =~ s/\s//g;
	$IP_Edit =~ s/[^0-9\.]//g;
my $DHCP_Toggle_Edit = $CGI->param("DHCP_Toggle_Edit");
	if ($DHCP_Toggle_Edit eq 'on') {
		$IP_Edit = 'DHCP';
	}
my $Expires_Toggle_Edit = $CGI->param("Expires_Toggle_Edit");
my $Expires_Date_Edit = $CGI->param("Expires_Date_Edit");
	$Expires_Date_Edit =~ s/\s//g;
	$Expires_Date_Edit =~ s/[^0-9\-]//g;
my $Active_Edit = $CGI->param("Active_Edit");

my $Delete_Host = $CGI->param("Delete_Host");
my $Delete_Host_Confirm = $CGI->param("Delete_Host_Confirm");
my $Host_Name_Delete = $CGI->param("Host_Name_Delete");

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

if ($Add_Host) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-hosts.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_add_host;
	}
}
elsif ($Host_Name_Add && $IP_Add) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-hosts.cgi\n\n";
		exit(0);
	}
	else {
		my $Host_ID = &add_host;
		my $Message_Green="$Host_Name_Add ($IP_Add) added successfully as ID $Host_ID";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DSMS/sudoers-hosts.cgi\n\n";
		exit(0);
	}
}
elsif ($Edit_Host) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-hosts.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_edit_host;
	}
}
elsif ($Edit_Host_Post) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-hosts.cgi\n\n";
		exit(0);
	}
	else {
		&edit_host;
		my $Message_Green="$Host_Name_Edit ($IP_Edit) edited successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DSMS/sudoers-hosts.cgi\n\n";
		exit(0);
	}
}
elsif ($Delete_Host) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-hosts.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_delete_host;
	}
}
elsif ($Delete_Host_Confirm) {
	if ($User_DSMS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DSMS/sudoers-hosts.cgi\n\n";
		exit(0);
	}
	else {
		&delete_host;
		my $Message_Green="$Host_Name_Delete deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DSMS/sudoers-hosts.cgi\n\n";
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

	### Host Groups

	my $Select_Links = $DB_Connection->prepare("SELECT `group`
		FROM `lnk_host_groups_to_hosts`
		WHERE `host` = ?"
	);
	$Select_Links->execute($Show_Links);

	while ( my @Select_Links = $Select_Links->fetchrow_array() )
	{
		
		my $Group_ID = $Select_Links[0];

		my $Select_Groups = $DB_Connection->prepare("SELECT `groupname`, `active`
			FROM `host_groups`
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
			"Host Group",
			"$Group",
			"$Active",
			"<a href='/DSMS/sudoers-host-groups.cgi?ID_Filter=$Group_ID'><img src=\"/resources/imgs/forward.png\" alt=\"View $Group\" ></a>"
			);
		}
	}

	### Rules

	my $Select_Rule_Links = $DB_Connection->prepare("SELECT `rule`
		FROM `lnk_rules_to_hosts`
		WHERE `host` = ?"
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
<a href="/DSMS/sudoers-hosts.cgi">
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

	### Discover Host Name
	my $Host_Name;
	my $Select_Host_Name = $DB_Connection->prepare("SELECT `hostname`
	FROM `hosts`
	WHERE `id` = ?");

	$Select_Host_Name->execute($View_Notes);
	$Host_Name = $Select_Host_Name->fetchrow_array();
	### / Discover Host Name

	### Discover Note Count
	my $Select_Note_Count = $DB_Connection->prepare("SELECT COUNT(*)
		FROM `notes`
		WHERE `type_id` = '01'
		AND `item_id` = ?"
	);
	$Select_Note_Count->execute($View_Notes);
	my $Note_Count = $Select_Note_Count->fetchrow_array();
	### / Discover Note Count

	my $Select_Notes = $DB_Connection->prepare("SELECT `note`, `last_modified`, `modified_by`
	FROM `notes`
	WHERE `type_id` = '01'
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
<a href="/DSMS/sudoers-hosts.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Notes for $Host_Name</h3>
<form action='/DSMS/sudoers-hosts.cgi' method='post'>

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
	$Note_Submission->execute(01, $New_Note_ID, $New_Note, $User_Name);

} # sub add_note

sub html_output {

	my $Table = new HTML::Table(
		-cols=>9,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);


	my $Select_Host_Count = $DB_Connection->prepare("SELECT `dsms` FROM `host_attributes` WHERE `dsms` = 1");
		$Select_Host_Count->execute( );
		my $Total_Rows = $Select_Host_Count->rows();


	my $Select_Hosts = $DB_Connection->prepare("SELECT `id`, `hostname`, `active`, `last_modified`, `modified_by`
		FROM `hosts`
		LEFT JOIN `host_attributes`
		ON `hosts`.`id`=`host_attributes`.`host_id`
			WHERE (`id` LIKE ?
			OR `hostname` LIKE ?)
			AND `dsms` = 1
		ORDER BY `hostname` ASC
		LIMIT ?, ?"
	);

	if ($ID_Filter) {
		$Select_Hosts->execute($ID_Filter, '', 0, $Rows_Returned);
	}
	else {
		$Select_Hosts->execute("%$Filter%", "%$Filter%", 0, $Rows_Returned);
	}

	my $Rows = $Select_Hosts->rows();

	$Table->addRow( "ID", "Host Name", "IP Address", "Active", "Last Modified", "Modified By", "Show Links", "Notes", "Edit");
	$Table->setRowClass (1, 'tbrow1');

	my $Host_Row_Count=1;

	while ( my @Select_Hosts = $Select_Hosts->fetchrow_array() )
	{

		$Host_Row_Count++;

		my $DBID = $Select_Hosts[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($ID_Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Host_Name = $Select_Hosts[1];
			my $Host_Name_Clean = $Host_Name;
			$Host_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Active = $Select_Hosts[2];
			if ($Active == 1) {$Active = "Yes"} else {$Active = "No"};
		my $Last_Modified = $Select_Hosts[3];
		my $Modified_By = $Select_Hosts[4];

		### Discover Note Count

		my $Select_Note_Count = $DB_Connection->prepare("SELECT COUNT(*)
			FROM `notes`
			WHERE `type_id` = '01'
			AND `item_id` = ?"
		);
		$Select_Note_Count->execute($DBID_Clean);
		my $Note_Count = $Select_Note_Count->fetchrow_array();

		### / Discover Note Count

		### Block discovery

		my $Select_Block_Links = $DB_Connection->prepare("SELECT `ip`
			FROM `lnk_hosts_to_ipv4_assignments`
			WHERE `host` = ?");
		$Select_Block_Links->execute($DBID_Clean);

		my $Blocks;
		while (my $Block_ID = $Select_Block_Links->fetchrow_array() ) {

			my $Select_Blocks = $DB_Connection->prepare("SELECT `ip_block`
				FROM `ipv4_assignments`
				WHERE `id` = ?");
			$Select_Blocks->execute($Block_ID);

			while (my $Block = $Select_Blocks->fetchrow_array() ) {

				my $Count_Block_Assignments = $DB_Connection->prepare("SELECT `id`
					FROM `lnk_hosts_to_ipv4_assignments`
					WHERE `ip` = ?");
				$Count_Block_Assignments->execute($Block_ID);
				my $Total_Block_Assignments = $Count_Block_Assignments->rows();

				if ($Total_Block_Assignments > 1) {
					$Block = "<a href='/IP/ipv4-assignments.cgi?Filter=$Block'><span style='color: #FF6C00;'>$Block</span></a>";
				}
				else {
					$Block = "<a href='/IP/ipv4-assignments.cgi?Filter=$Block'>$Block</a>";
				}
				$Blocks = $Block. ",&nbsp;" . $Blocks;
			}
		}

		$Blocks =~ s/,&nbsp;$//;

		### / Block discovery

		$Table->addRow(
			"$DBID",
			"$Host_Name",
			"$Blocks",
			"$Active",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/DSMS/sudoers-hosts.cgi?Show_Links=$DBID_Clean&Show_Links_Name=$Host_Name_Clean'><img src=\"/resources/imgs/linked.png\" alt=\"Linked Objects to Host ID $DBID_Clean\" ></a>",
			"<a href='/DSMS/sudoers-hosts.cgi?View_Notes=$DBID_Clean'>
				<div style='position: relative; background: url(\"/resources/imgs/view-notes.png\") no-repeat; width: 22px; height: 22px;'> 
					<p style='position: absolute; width: 22px; text-align: center; font-weight: bold; color: #FF0000;'>
						$Note_Count
					</p>
				</div>
			</a>",
			"<a href='/IP/hosts.cgi?Edit_Host=$DBID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Host ID $DBID_Clean\" ></a>",
		);


		if ($Active eq 'Yes') {
			$Table->setCellClass ($Host_Row_Count, 4, 'tbrowgreen');
		}
		else {
			$Table->setCellClass ($Host_Row_Count, 4, 'tbrowred');
		}

	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(4, '1px');
	$Table->setColWidth(5, '110px');
	$Table->setColWidth(6, '110px');
	$Table->setColWidth(7, '1px');
	$Table->setColWidth(8, '1px');
	$Table->setColWidth(9, '1px');

	$Table->setColAlign(1, 'center');
	for (4..9) {
		$Table->setColAlign($_, 'center');
	}



print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/DSMS/sudoers-hosts.cgi' method='post' >
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
			
		</td>
		<td align="right">
			
		</td>
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">Sudo Hosts | Hosts Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output