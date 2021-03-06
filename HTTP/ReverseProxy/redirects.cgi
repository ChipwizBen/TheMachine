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
my $Me = '/ReverseProxy/redirects.cgi';

my $Add_Redirect = $CGI->param("Add_Redirect");
	my $Server_Name_Add = $CGI->param("Server_Name_Add");
		$Server_Name_Add =~ s/\s//g;
	my $Port_Add = $CGI->param("Port_Add");
	my $Source_Add = $CGI->param("Source_Add");
		$Source_Add =~ s/\s//g;
	my $Destination_Add = $CGI->param("Destination_Add");
		$Destination_Add =~ s/\s//g;
	my $Transfer_Log_Add = $CGI->param("Transfer_Log_Add");
		$Transfer_Log_Add =~ s/\s//g;
	my $Error_Log_Add = $CGI->param("Error_Log_Add");
		$Error_Log_Add =~ s/\s//g;

my $Edit_Redirect = $CGI->param("Edit_Redirect");
	my $Server_Name_Edit = $CGI->param("Server_Name_Edit");
		$Server_Name_Edit =~ s/\s//g;
	my $Port_Edit = $CGI->param("Port_Edit");
	my $Source_Edit = $CGI->param("Source_Edit");
		$Source_Edit =~ s/\s//g;
	my $Destination_Edit = $CGI->param("Destination_Edit");
		$Destination_Edit =~ s/\s//g;
	my $Transfer_Log_Edit = $CGI->param("Transfer_Log_Edit");
		$Transfer_Log_Edit =~ s/\s//g;
	my $Error_Log_Edit = $CGI->param("Error_Log_Edit");
		$Error_Log_Edit =~ s/\s//g;
my $Edit_Redirect_Post = $CGI->param("Edit_Redirect_Post");

my $Delete_Redirect = $CGI->param("Delete_Redirect");
my $Delete_Redirect_Confirm = $CGI->param("Delete_Redirect_Confirm");
my $Redirect_Delete = $CGI->param("Redirect_Delete");

my $View_Redirect = $CGI->param("View_Redirect");

my $User_Name = $Session->param("User_Name");
my $User_Reverse_Proxy_Admin = $Session->param("User_Reverse_Proxy_Admin");

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

if ($Add_Redirect) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_add_redirect;
	}
}
elsif ($Server_Name_Add && $Source_Add && $Destination_Add) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
	else {
		my $Redirect_ID = &add_redirect;
		my $Message_Green="Redirect entry for $Server_Name_Add added successfully as ID $Redirect_ID";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
}
elsif ($Edit_Redirect) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_edit_redirect;
	}
}
elsif ($Edit_Redirect_Post) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
	else {
		&edit_redirect;
		my $Message_Green="The Redirect entry for $Server_Name_Edit (ID $Edit_Redirect_Post) was edited successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
}
elsif ($Delete_Redirect) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_delete_redirect;
	}
}
elsif ($Delete_Redirect_Confirm) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
	else {
		&delete_redirect;
		my $Message_Green="The redirect entry for $Redirect_Delete was deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
}
elsif ($View_Redirect) {
		require $Header;
		&html_output;
		require $Footer;
		&html_view_redirect;
}
else {
	require $Header;
	&html_output;
	require $Footer;
}



sub html_add_redirect {

	my ($Default_Transfer_Log_Path,
		$Default_Error_Log_Path) = Redirect_Defaults();

print <<ENDHTML;

<div id="wide-popup-box">
<a href="$Me">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Redirect</h3>

<form action='$Me' name='Add_Redirect' method='post' >

<table align="center" width='90%'>
	<tr>
		<td style="text-align: right;">Server Name:</td>
		<td><input type='text' name='Server_Name_Add' style="width:100%" maxlength='1024' placeholder="FQDN,Alias1,Alias2" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Port:</td>
		<td align="left"><input type='text' name='Port_Add' style="width:50%" maxlength='5' placeholder="80" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Source:</td>
		<td><input type='text' name='Source_Add' style="width:100%" placeholder="/mail" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Destination:</td>
		<td><input type='text' name='Destination_Add' style="width:100%" placeholder="http://mail.domain.com/" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Transfer Log:</td>
		<td><input type='text' name='Transfer_Log_Add' style="width:100%" placeholder="$Default_Transfer_Log_Path/<domain>.log"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Error Log:</td>
		<td><input type='text' name='Error_Log_Add' style="width:100%" placeholder="$Default_Transfer_Log_Path/<domain>.error"></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Server, Source and Destination must be defined. You can defined aliases by comma seperating several server names.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Redirect'></div>

</form>

ENDHTML

} #sub html_add_redirect

sub add_redirect {

	my ($Default_Transfer_Log_Path,
		$Default_Error_Log_Path) = Redirect_Defaults();

	if (!$Transfer_Log_Add) {$Transfer_Log_Add = $Default_Transfer_Log_Path . "/$Server_Name_Add.log";}
	if (!$Error_Log_Add) {$Error_Log_Add = $Default_Error_Log_Path . "/$Server_Name_Add.error";}

	my $Redirect_Insert = $DB_Connection->prepare("INSERT INTO `redirect` (
		`server_name`,
		`port`,
		`redirect_source`,
		`redirect_destination`,
		`transfer_log`,
		`error_log`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?, ?, ?, ?
	)");

	$Redirect_Insert->execute($Server_Name_Add, $Port_Add, $Source_Add, $Destination_Add, $Transfer_Log_Add, $Error_Log_Add, $User_Name);

	my $Redirect_Insert_ID = $DB_Connection->{mysql_insertid};

	# Audit Log
	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();
	
	$Audit_Log_Submission->execute("Redirect", "Add", "$User_Name added an entry from $Source_Add to $Destination_Add for $Server_Name_Add on port $Port_Add. The system assigned it Redirect ID $Redirect_Insert_ID.", $User_Name);
	# / Audit Log

	return($Redirect_Insert_ID);

} # sub add_redirect

sub html_edit_redirect {

	my ($Default_Transfer_Log_Path,
		$Default_Error_Log_Path) = Redirect_Defaults();

	my $Filter_URL;
	if ($Filter) {$Filter_URL = "?Filter=$Filter"}
	if ($ID_Filter) {$Filter_URL = "?ID_Filter=$ID_Filter"}

	my $Select_Redirect = $DB_Connection->prepare("SELECT `server_name`, `port`, `redirect_source`,
		`redirect_destination`, `transfer_log`, `error_log`
		FROM `redirect`
		WHERE `id` = ?");
	$Select_Redirect->execute($Edit_Redirect);

	while ( my @Redirect_Values = $Select_Redirect->fetchrow_array() )
	{

		my $Server_Name = $Redirect_Values[0];
		my $Port = $Redirect_Values[1];
		my $Source = $Redirect_Values[2];
		my $Destination = $Redirect_Values[3];
		my $Transfer_Log = $Redirect_Values[4];
		my $Error_Log = $Redirect_Values[5];

		if (!$Transfer_Log) {$Transfer_Log = $Default_Transfer_Log_Path . "/$Server_Name.log";}
		if (!$Error_Log) {$Error_Log = $Default_Error_Log_Path . "/$Server_Name.error";} 

print <<ENDHTML;

<div id="wide-popup-box">
<a href="$Me$Filter_URL">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Redirect</h3>

<form action='$Me' name='Edit_Redirect' method='post' >

<table align="center" width='90%'>
	<tr>
		<td style="text-align: right;">Server Name:</td>
		<td><input type='text' name='Server_Name_Edit' value='$Server_Name' style="width:100%" maxlength='1024' placeholder="$Server_Name" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Port:</td>
		<td align="left"><input type='text' name='Port_Edit' value='$Port' style="width:50%" maxlength='5' placeholder="$Port" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Source:</td>
		<td><input type='text' name='Source_Edit' value='$Source' style="width:100%" placeholder="$Source" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Destination:</td>
		<td><input type='text' name='Destination_Edit' value='$Destination' style="width:100%" placeholder="$Destination" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Transfer Log:</td>
		<td><input type='text' name='Transfer_Log_Edit' value='$Transfer_Log' style="width:100%" placeholder="$Transfer_Log"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Error Log:</td>
		<td><input type='text' name='Error_Log_Edit' value='$Error_Log' style="width:100%" placeholder="$Error_Log"></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Server, Source and Destination must be defined. You can defined aliases by comma seperating several server names.</li>
</ul>

<hr width="50%">

<input type='hidden' name='Edit_Redirect_Post' value='$Edit_Redirect'>
<div style="text-align: center"><input type=submit name='ok' value='Edit Redirect'></div>

</form>


ENDHTML

	}
} # sub html_edit_redirect

sub edit_redirect {

	my ($Default_Transfer_Log_Path,
		$Default_Error_Log_Path) = Redirect_Defaults();

	if (!$Transfer_Log_Edit) {$Transfer_Log_Edit = $Default_Transfer_Log_Path . "/$Server_Name_Edit.log";}
	if (!$Error_Log_Edit) {$Error_Log_Edit = $Default_Error_Log_Path . "/$Server_Name_Edit.error";}

	my $Update_Redirect = $DB_Connection->prepare("UPDATE `redirect` SET
		`server_name` = ?,
		`port` = ?,
		`redirect_source` = ?,
		`redirect_destination` = ?,
		`transfer_log` = ?,
		`error_log` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		
	$Update_Redirect->execute($Server_Name_Edit, $Port_Edit, $Source_Edit, $Destination_Edit, $Transfer_Log_Edit, $Error_Log_Edit,
	$User_Name, $Edit_Redirect_Post);

	# Audit Log
	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();

	$Audit_Log_Submission->execute("Redirect", "Modify", "$User_Name modified Redirect ID $Edit_Redirect_Post. 
	It is now recorded as server $Server_Name_Edit (port $Port_Edit), with a source of $Source_Edit and destination of $Destination_Edit.", $User_Name);
	# / Audit Log

} # sub edit_redirect

sub html_delete_redirect {

	my $Filter_URL;
	if ($Filter) {$Filter_URL = "?Filter=$Filter"}
	if ($ID_Filter) {$Filter_URL = "?ID_Filter=$ID_Filter"}

	my $Select_Redirect = $DB_Connection->prepare("SELECT `server_name`, `port`, `redirect_source`, `redirect_destination`
	FROM `redirect`
	WHERE `id` = ?");

	$Select_Redirect->execute($Delete_Redirect);
	
	while ( my ($Server_Name, $Port, $Redirect_Source, $Redirect_Destination) = $Select_Redirect->fetchrow_array() )
	{


print <<ENDHTML;
<div id="small-popup-box">
<a href="$Me$Filter_URL">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Redirect</h3>

<form action='$Me' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this redirect entry?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Server:</td>
		<td style="text-align: left; color: #00FF00;">$Server_Name:$Port</td>
	</tr>
	<tr>
		<td style="text-align: right;">Source:</td>
		<td style="text-align: left; color: #00FF00;">$Redirect_Source</td>
	</tr>
	<tr>
		<td style="text-align: right;">Destination:</td>
		<td style="text-align: left; color: #00FF00;">$Redirect_Destination</td>
	</tr>
</table>

<input type='hidden' name='Delete_Redirect_Confirm' value='$Delete_Redirect'>
<input type='hidden' name='Redirect_Delete' value='$Server_Name'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Redirect'></div>

</form>

ENDHTML

	}
} # sub html_delete_redirect

sub delete_redirect {

	# Audit Log
	my $Select_Redirect = $DB_Connection->prepare("SELECT `server_name`, `redirect_source`, `redirect_destination`
	FROM `redirect`
	WHERE `id` = ?");

	$Select_Redirect->execute($Delete_Redirect_Confirm);
	
	while ( my ($Server_Name, $Redirect_Source, $Redirect_Destination) = $Select_Redirect->fetchrow_array() )
	{

		my $DB_Connection = DB_Connection();
		my $Audit_Log_Submission = Audit_Log_Submission();

		$Audit_Log_Submission->execute("Redirect", "Delete", "$User_Name deleted the redirect entry for $Server_Name, 
		with a source of $Redirect_Source and destination of $Redirect_Destination. The Redirect ID was $Delete_Redirect_Confirm.", $User_Name);

	}
	# / Audit Log

	my $Delete_Redirect = $DB_Connection->prepare("DELETE from `redirect`
		WHERE `id` = ?");
	
	$Delete_Redirect->execute($Delete_Redirect_Confirm);

} # sub delete_redirect

sub html_view_redirect {

	my ($Default_Transfer_Log_Path,
		$Default_Error_Log_Path) = Redirect_Defaults();

	my $Server_Group_Query = $DB_Connection->prepare("SELECT `server_name`, `port`, `transfer_log`, `error_log`, `last_modified`, `modified_by`
	FROM `redirect`
	WHERE `id` = ?");
	$Server_Group_Query->execute($View_Redirect);

	while ( my @Server_Entry = $Server_Group_Query->fetchrow_array() )
	{
		my $Server_Name = $Server_Entry[0];
		my $Port = $Server_Entry[1];
		my $Transfer_Log = $Server_Entry[2];
		my $Error_Log = $Server_Entry[3];
		my $Last_Modified = $Server_Entry[4];
		my $Modified_By = $Server_Entry[5];

		if (!$Transfer_Log) {$Transfer_Log = $Default_Transfer_Log_Path . "/$Server_Name.log"}
		if (!$Error_Log) {$Error_Log = $Default_Error_Log_Path . "/$Server_Name.error"}

		my $ServerAliases;
		my @ServerAliases = split(',', $Server_Name);
		$Server_Name = shift @ServerAliases;
		foreach my $Alias (@ServerAliases) {
			$ServerAliases = $ServerAliases . "\n    ServerAlias              $Alias";
		}
		my $Server_Names = "ServerName               " . $Server_Name . $ServerAliases;

		my $Server_Attribute_Query = $DB_Connection->prepare("SELECT `id`, `redirect_source`, `redirect_destination`, `last_modified`, `modified_by`
		FROM `redirect`
		WHERE (`server_name` LIKE ?
			OR `server_name` LIKE ?
			OR `server_name` LIKE ?
			OR `server_name` LIKE ?
			)
		AND `port` = ?
		ORDER BY `redirect_source` DESC");
		$Server_Attribute_Query->execute($Server_Name, "$Server_Name,%", "%,$Server_Name", "%,$Server_Name,%", $Port);

		my $ID_Group;
		my $Redirect_Config;
		while ( my @Redirect_Entry = $Server_Attribute_Query->fetchrow_array() )
		{
			my $ID = $Redirect_Entry[0];
				$ID_Group = $ID_Group . $ID . ', '; 
			my $Source = $Redirect_Entry[1];
			my $Destination = $Redirect_Entry[2];
			$Last_Modified = $Redirect_Entry[3];
			$Modified_By = $Redirect_Entry[4];
			
	        $Redirect_Config = $Redirect_Config . "\n    ## Redirect ID $ID, last modified $Last_Modified by $Modified_By\n";
	        $Redirect_Config = $Redirect_Config . "    Redirect                 $Source	$Destination\n";
		}

		my $Redirect_HTML = "
<VirtualHost *:$Port>
    $Server_Names
$Redirect_Config
    TransferLog              $Transfer_Log
    ErrorLog                 $Error_Log
</VirtualHost>
";

$Redirect_HTML =~ s/</&lt;/g;
$Redirect_HTML =~ s/>/&gt;/g;
$Redirect_HTML =~ s/\\n/<br>/g;

my $Filter_URL;
if ($Filter) {$Filter_URL = "?Filter=$Filter"}
if ($ID_Filter) {$Filter_URL = "?ID_Filter=$ID_Filter"}


print <<ENDHTML;

<div id="wide-popup-box">
<a href="$Me$Filter_URL">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Config for Redirect ID $View_Redirect</h3>

<pre style='text-align: left; padding-left:20px; white-space:pre-wrap; word-wrap:break-word;'><code>$Redirect_HTML</code></pre>

</div>

ENDHTML
	}
} #sub html_view_redirect

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


	my $Select_Redirect_Count = $DB_Connection->prepare("SELECT `id` FROM `redirect`");
		$Select_Redirect_Count->execute( );
		my $Total_Rows = $Select_Redirect_Count->rows();


	my $Select_Redirects = $DB_Connection->prepare("SELECT `id`, `server_name`, `port`, `redirect_source`,
		`redirect_destination`, `transfer_log`, `error_log`, `last_modified`, `modified_by`
		FROM `redirect`
		WHERE `id` LIKE ?
		OR `server_name` LIKE ?
		OR `port` LIKE ?
		OR `redirect_source` LIKE ?
		OR `redirect_destination` LIKE ?
		OR `transfer_log` LIKE ?
		OR `error_log` LIKE ?
		ORDER BY `server_name` ASC
		LIMIT ?, ?"
	);

	if ($ID_Filter) {
		$Select_Redirects->execute($ID_Filter, "", "", "",  
		"", "", "", 0, $Rows_Returned);
	}
	else {
		$Select_Redirects->execute("%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%",  
		"%$Filter%", "%$Filter%", "%$Filter%", 0, $Rows_Returned);
	}

	my $Rows = $Select_Redirects->rows();

	$Table->addRow( "ID", "Server Name<br /><span style='color: #B6B600'>Server Alias</span>", "Port", "Source", "Destination", "Transfer Log", "Error Log", "Last Modified", "Modified By", "View", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	while ( my @Select_Redirects = $Select_Redirects->fetchrow_array() )
	{

		my $DBID = $Select_Redirects[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Server_Name = $Select_Redirects[1];
			$Server_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Port = $Select_Redirects[2];
			$Port =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Source = $Select_Redirects[3];
			$Source =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Destination = $Select_Redirects[4];
			$Destination =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Transfer_Log = $Select_Redirects[5];
			$Transfer_Log =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Error_Log = $Select_Redirects[6];
			$Error_Log =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Last_Modified = $Select_Redirects[7];
		my $Modified_By = $Select_Redirects[8];

		my $ServerAliases;
		my @ServerAliases = split(',', $Server_Name);
		$Server_Name = shift @ServerAliases;
		foreach my $Alias (@ServerAliases) {
			$ServerAliases = $ServerAliases . "<br/>$Alias";
		}

		my $View;
		my $Edit;
		my $Delete;
		if ($Filter || $ID_Filter) {
			my $Filter_URL;
			if ($Filter) {$Filter_URL = "Filter=$Filter"} else {$Filter_URL = "ID_Filter=$ID_Filter"}
			$View = "<a href='$Me?View_Redirect=$DBID_Clean&$Filter_URL'><img src=\"/Resources/Images/view-notes.png\" alt=\"View Redirect ID $DBID_Clean\" ></a>";
			$Edit = "<a href='$Me?Edit_Redirect=$DBID_Clean&$Filter_URL'><img src=\"/Resources/Images/edit.png\" alt=\"Edit Redirect ID $DBID_Clean\" ></a>";
			$Delete = "<a href='$Me?Delete_Redirect=$DBID_Clean&$Filter_URL'><img src=\"/Resources/Images/delete.png\" alt=\"Delete Redirect ID $DBID_Clean\" ></a>";
		}
		else {
			$View = "<a href='$Me?View_Redirect=$DBID_Clean'><img src=\"/Resources/Images/view-notes.png\" alt=\"View Redirect ID $DBID_Clean\" ></a>";
			$Edit = "<a href='$Me?Edit_Redirect=$DBID_Clean'><img src=\"/Resources/Images/edit.png\" alt=\"Edit Redirect ID $DBID_Clean\" ></a>";
			$Delete = "<a href='$Me?Delete_Redirect=$DBID_Clean'><img src=\"/Resources/Images/delete.png\" alt=\"Delete Redirect ID $DBID_Clean\" ></a>";
		}

		$Table->addRow(
			"$DBID",
			"$Server_Name<span style='color: #B6B600'>$ServerAliases</span>",
			"$Port",
			"$Source",
			"$Destination",
			"$Transfer_Log",
			"$Error_Log",
			"$Last_Modified",
			"$Modified_By",
			$View,
			$Edit,
			$Delete
		);


	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(8, '110px');
	$Table->setColWidth(9, '110px');
	$Table->setColWidth(10, '1px');
	$Table->setColWidth(11, '1px');
	$Table->setColWidth(12, '1px');

	$Table->setColAlign(1, 'center');
	for (8..12) {
		$Table->setColAlign($_, 'center');
	}

my $Clear_Filter;
if ($Filter) {$Clear_Filter = "<a href='$Me?Filter='>[Clear]</a>"}

print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='$Me' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Redirect" placeholder="Search"> $Clear_Filter
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='$Me' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Redirect</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Redirect' value='Add Redirect'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='$Me' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Redirect</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Redirect' value='Edit Redirect'></td>
					<td align="center">
						<select name='Edit_Redirect' style="width: 150px">
ENDHTML

						my $Redirect_List_Query = $DB_Connection->prepare("SELECT `id`, `server_name`, `redirect_source`, `redirect_destination`
						FROM `redirect`
						ORDER BY `server_name` ASC");
						$Redirect_List_Query->execute( );
						
						while ( my ($ID, $Server_Name, $Source, $Destination) = my @Redirect_List_Query = $Redirect_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Server_Name [$Source -> $Destination]</option>";
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

<p style="font-size:14px; font-weight:bold;">Redirect | Redirects Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output