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
my $DB_Reverse_Proxy = DB_Reverse_Proxy();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Reverse_Proxy = $CGI->param("Add_Reverse_Proxy");
	my $Server_Name_Add = $CGI->param("Server_Name_Add");
		$Server_Name_Add =~ s/\s//g;
	my $Source_Add = $CGI->param("Source_Add");
		$Source_Add =~ s/\s//g;
	my $Destination_Add = $CGI->param("Destination_Add");
		$Destination_Add =~ s/\s//g;
	my $Transfer_Log_Add = $CGI->param("Transfer_Log_Add");
		$Transfer_Log_Add =~ s/\s//g;
	my $Error_Log_Add = $CGI->param("Error_Log_Add");
		$Error_Log_Add =~ s/\s//g;
	my $SSL_Toggle_Add = $CGI->param("SSL_Toggle_Add");
		my $Certificate_Add = $CGI->param("Certificate_Add");
			$Certificate_Add =~ s/\s//g;
		my $Certificate_Key_Add = $CGI->param("Certificate_Key_Add");
			$Certificate_Key_Add =~ s/\s//g;
		my $CA_Certificate_Add = $CGI->param("CA_Certificate_Add");
			$CA_Certificate_Add =~ s/\s//g;
		if ($SSL_Toggle_Add ne 'On') {
			$Certificate_Add = '';
			$Certificate_Key_Add = '';
			$CA_Certificate_Add = '';
		}

my $Edit_Reverse_Proxy = $CGI->param("Edit_Reverse_Proxy");
	my $Server_Name_Edit = $CGI->param("Server_Name_Edit");
		$Server_Name_Edit =~ s/\s//g;
	my $Source_Edit = $CGI->param("Source_Edit");
		$Source_Edit =~ s/\s//g;
	my $Destination_Edit = $CGI->param("Destination_Edit");
		$Destination_Edit =~ s/\s//g;
	my $Transfer_Log_Edit = $CGI->param("Transfer_Log_Edit");
		$Transfer_Log_Edit =~ s/\s//g;
	my $Error_Log_Edit = $CGI->param("Error_Log_Edit");
		$Error_Log_Edit =~ s/\s//g;
	my $SSL_Toggle_Edit = $CGI->param("SSL_Toggle_Edit");
		my $Certificate_Edit = $CGI->param("Certificate_Edit");
			$Certificate_Edit =~ s/\s//g;
		my $Certificate_Key_Edit = $CGI->param("Certificate_Key_Edit");
			$Certificate_Key_Edit =~ s/\s//g;
		my $CA_Certificate_Edit = $CGI->param("CA_Certificate_Edit");
			$CA_Certificate_Edit =~ s/\s//g;
		if ($SSL_Toggle_Edit ne 'On') {
			$Certificate_Edit = '';
			$Certificate_Key_Edit = '';
			$CA_Certificate_Edit = '';
		}
my $Edit_Reverse_Proxy_Post = $CGI->param("Edit_Reverse_Proxy_Post");

my $Delete_Reverse_Proxy = $CGI->param("Delete_Reverse_Proxy");
my $Delete_Reverse_Proxy_Confirm = $CGI->param("Delete_Reverse_Proxy_Confirm");
my $Reverse_Proxy_Delete = $CGI->param("Reverse_Proxy_Delete");

my $User_Name = $Session->param("User_Name");
my $User_Reverse_Proxy_Admin = $Session->param("User_Reverse_Proxy_Admin");

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $Filter = $CGI->param("Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}

if ($Add_Reverse_Proxy) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_add_reverse_proxy;
	}
}
elsif ($Server_Name_Add && $Source_Add && $Destination_Add) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
		exit(0);
	}
	else {
		my $Reverse_Proxy_ID = &add_reverse_proxy;
		my $Message_Green="Reverse proxy entry for $Server_Name_Add added successfully as ID $Reverse_Proxy_ID";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
		exit(0);
	}
}
elsif ($Edit_Reverse_Proxy) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_edit_reverse_proxy;
	}
}
elsif ($Edit_Reverse_Proxy_Post) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
		exit(0);
	}
	else {
		&edit_reverse_proxy;
		my $Message_Green="The Reverse Proxy entry for $Server_Name_Edit (ID $Edit_Reverse_Proxy_Post) was edited successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
		exit(0);
	}
}
elsif ($Delete_Reverse_Proxy) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_delete_reverse_proxy;
	}
}
elsif ($Delete_Reverse_Proxy_Confirm) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
		exit(0);
	}
	else {
		&delete_reverse_proxy;
		my $Message_Green="The reverse proxy entry for $Reverse_Proxy_Delete was deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
		exit(0);
	}
}
else {
	require $Header;
	&html_output;
	require $Footer;
}



sub html_add_reverse_proxy {

print <<ENDHTML;

<div id="small-popup-box">
<a href="/ReverseProxy/reverse-proxy.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Reverse Proxy</h3>

<SCRIPT LANGUAGE="JavaScript"><!--
function SSL_Toggle(value) {
	if(value=="On"){
		document.getElementById('Cert').style.display='table-row';
		document.getElementById('Key').style.display='table-row';
		document.getElementById('CA').style.display='table-row';
	}
	else if(value=="Off"){
		document.getElementById('Cert').style.display='none';
		document.getElementById('Key').style.display='none';
		document.getElementById('CA').style.display='none';
	}
	else {
		document.getElementById('Cert').style.display='none';
		document.getElementById('Key').style.display='none';
		document.getElementById('CA').style.display='none';
	}
}
//-->
</SCRIPT>

<form action='/ReverseProxy/reverse-proxy.cgi' name='Add_Reverse_Proxy' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Server Name:</td>
		<td colspan="2"><input type='text' name='Server_Name_Add' style="width:100%" maxlength='128' placeholder="FQDN" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Source:</td>
		<td colspan="2"><input type='text' name='Source_Add' style="width:100%" placeholder="/mail" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Destination:</td>
		<td colspan="2"><input type='text' name='Destination_Add' style="width:100%" placeholder="http://mail.domain.com/" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Transfer Log:</td>
		<td colspan="2"><input type='text' name='Transfer_Log_Add' style="width:100%" placeholder="/var/log/domain-access.log"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Error Log:</td>
		<td colspan="2"><input type='text' name='Error_Log_Add' style="width:100%" placeholder="/var/log/domain-error.log"></td>
	</tr>
	<tr>
		<td style="text-align: right;">SSL:</td>
		<td colspan="2" style="text-align: left;">
			<select name='SSL_Toggle_Add' onchange="SSL_Toggle(this.value);">
				<option value='Off'>Off</option>
				<option value='On'>On</option>
			</select>
		</td>
	</tr>
	<tr style="display: none;" id="Cert">
		<td style="text-align: right;">Certificate File:</td>
		<td colspan="2"><input type='text' name='Certificate_Add' style="width:100%" placeholder="/etc/ssl/domain.crt"></td>
	</tr>
	<tr style="display: none;" id="Key">
		<td style="text-align: right;">Certificate Key File:</td>
		<td colspan="2"><input type='text' name='Certificate_Key_Add' style="width:100%" placeholder="/etc/ssl/domain.key"></td>
	</tr>
	<tr style="display: none;" id="CA">
		<td style="text-align: right;">CA Certificate File:</td>
		<td colspan="2"><input type='text' name='CA_Certificate_Add' style="width:100%" placeholder="/etc/ssl/CA-Bundle.pem"></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Server, Source and Destination must be defined.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Reverse Proxy'></div>

</form>

ENDHTML

} #sub html_add_reverse_proxy

sub add_reverse_proxy {

	my ($Default_Transfer_Log,
		$Default_Error_Log,
		$Default_SSL_Certificate_File,
		$Default_SSL_Certificate_Key_File,
		$Default_SSL_CA_Certificate_File) = Reverse_Proxy_Defaults();

	if (!$Transfer_Log_Add) {$Transfer_Log_Add = $Default_Transfer_Log;}
	if (!$Error_Log_Add) {$Error_Log_Add = $Default_Error_Log;}

	my $Reverse_Proxy_Insert = $DB_Reverse_Proxy->prepare("INSERT INTO `reverse_proxy` (
		`server_name`,
		`proxy_pass_source`,
		`proxy_pass_destination`,
		`transfer_log`,
		`error_log`,
		`ssl_certificate_file`,
		`ssl_certificate_key_file`,
		`ssl_ca_certificate_file`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?,
		?, ?, ?, ?, ?
	)");

	$Reverse_Proxy_Insert->execute($Server_Name_Add, $Source_Add, $Destination_Add, $Transfer_Log_Add, 
	$Error_Log_Add, $Certificate_Add, $Certificate_Key_Add, $CA_Certificate_Add, $User_Name);

	my $Reverse_Proxy_Insert_ID = $DB_Reverse_Proxy->{mysql_insertid};

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
	
	$Audit_Log_Submission->execute("Reverse Proxy", "Add", "$User_Name added an entry from $Source_Add to $Destination_Add for $Server_Name_Add. The system assigned it Reverse Proxy ID $Reverse_Proxy_Insert_ID.", $User_Name);
	# / Audit Log

	return($Reverse_Proxy_Insert_ID);

} # sub add_reverse_proxy

sub html_edit_reverse_proxy {

	my $Select_Reverse_Proxy = $DB_Reverse_Proxy->prepare("SELECT `server_name`, `proxy_pass_source`,
		`proxy_pass_destination`, `transfer_log`, `error_log`, `ssl_certificate_file`, `ssl_certificate_key_file`, 
		`ssl_ca_certificate_file`
		FROM `reverse_proxy`
		WHERE `id` = ?");
	$Select_Reverse_Proxy->execute($Edit_Reverse_Proxy);

	while ( my @Reverse_Proxy_Values = $Select_Reverse_Proxy->fetchrow_array() )
	{

		my $Server_Name = $Reverse_Proxy_Values[0];
		my $Source = $Reverse_Proxy_Values[1];
		my $Destination = $Reverse_Proxy_Values[2];
		my $Transfer_Log = $Reverse_Proxy_Values[3];
		my $Error_Log = $Reverse_Proxy_Values[4];
		my $SSL_Certificate_File = $Reverse_Proxy_Values[5];
		my $SSL_Certificate_Key_File = $Reverse_Proxy_Values[6];
		my $SSL_CA_Certificate_File = $Reverse_Proxy_Values[7];

		my $SSL_Display;
		my $SSL_Toggle;
		if ($SSL_Certificate_File || $SSL_Certificate_Key_File || $SSL_CA_Certificate_File)
		{
			$SSL_Toggle = "<option value='Off'>Off</option>
				<option value='On' selected>On</option>";
			$SSL_Display = 'table-row';
		}
		else {
			$SSL_Toggle = "<option value='Off' selected>Off</option>
				<option value='On'>On</option>";
			$SSL_Display = 'none';
		}

print <<ENDHTML;

<div id="small-popup-box">
<a href="/ReverseProxy/reverse-proxy.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Reverse Proxy</h3>

<SCRIPT LANGUAGE="JavaScript"><!--
function SSL_Toggle(value) {
	if(value=="On"){
		document.getElementById('Cert').style.display='table-row';
		document.getElementById('Key').style.display='table-row';
		document.getElementById('CA').style.display='table-row';
	}
	else if(value=="Off"){
		document.getElementById('Cert').style.display='none';
		document.getElementById('Key').style.display='none';
		document.getElementById('CA').style.display='none';
	}
	else {
		document.getElementById('Cert').style.display='$SSL_Display';
		document.getElementById('Key').style.display='$SSL_Display';
		document.getElementById('CA').style.display='$SSL_Display';
	}
}
//-->
</SCRIPT>

<form action='/ReverseProxy/reverse-proxy.cgi' name='Edit_Reverse_Proxy' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Server Name:</td>
		<td colspan="2"><input type='text' name='Server_Name_Edit' value='$Server_Name' style="width:100%" maxlength='128' placeholder="$Server_Name" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Source:</td>
		<td colspan="2"><input type='text' name='Source_Edit' value='$Source' style="width:100%" placeholder="$Source" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Destination:</td>
		<td colspan="2"><input type='text' name='Destination_Edit' value='$Destination' style="width:100%" placeholder="$Destination" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Transfer Log:</td>
		<td colspan="2"><input type='text' name='Transfer_Log_Edit' value='$Transfer_Log' style="width:100%" placeholder="$Transfer_Log"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Error Log:</td>
		<td colspan="2"><input type='text' name='Error_Log_Edit' value='$Error_Log' style="width:100%" placeholder="$Error_Log"></td>
	</tr>
	<tr>
		<td style="text-align: right;">SSL:</td>
		<td colspan="2" style="text-align: left;">
			<select name='SSL_Toggle_Edit' onchange="SSL_Toggle(this.value);">
				$SSL_Toggle
			</select>
		</td>
	</tr>
	<tr style="display: $SSL_Display;" id="Cert">
		<td style="text-align: right;">Certificate File:</td>
		<td colspan="2"><input type='text' name='Certificate_Edit' value='$SSL_Certificate_File' style="width:100%" placeholder="$SSL_Certificate_File"></td>
	</tr>
	<tr style="display: $SSL_Display;" id="Key">
		<td style="text-align: right;">Certificate Key File:</td>
		<td colspan="2"><input type='text' name='Certificate_Key_Edit' value='$SSL_Certificate_Key_File' style="width:100%" placeholder="$SSL_Certificate_Key_File"></td>
	</tr>
	<tr style="display: $SSL_Display;" id="CA">
		<td style="text-align: right;">CA Certificate File:</td>
		<td colspan="2"><input type='text' name='CA_Certificate_Edit' value='$SSL_CA_Certificate_File' style="width:100%" placeholder="$SSL_CA_Certificate_File"></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Server, Source and Destination must be defined.</li>
</ul>

<hr width="50%">

<input type='hidden' name='Edit_Reverse_Proxy_Post' value='$Edit_Reverse_Proxy'>
<div style="text-align: center"><input type=submit name='ok' value='Edit Reverse Proxy'></div>

</form>


ENDHTML

	}
} # sub html_edit_reverse_proxy

sub edit_reverse_proxy {

	my $Update_Reverse_Proxy = $DB_Reverse_Proxy->prepare("UPDATE `reverse_proxy` SET
		`server_name` = ?,
		`proxy_pass_source` = ?,
		`proxy_pass_destination` = ?,
		`transfer_log` = ?,
		`error_log` = ?,
		`ssl_certificate_file` = ?,
		`ssl_certificate_key_file` = ?,
		`ssl_ca_certificate_file` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		
	$Update_Reverse_Proxy->execute($Server_Name_Edit, $Source_Edit, $Destination_Edit, $Transfer_Log_Edit, $Error_Log_Edit,
	$Certificate_Edit, $Certificate_Key_Edit, $CA_Certificate_Edit, $User_Name, $Edit_Reverse_Proxy_Post);

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

	$Audit_Log_Submission->execute("Reverse Proxy", "Modify", "$User_Name modified Reverse Proxy ID $Edit_Reverse_Proxy_Post. 
	It is now recorded as server $Server_Name_Edit, with a source of $Source_Edit and destination of $Destination_Edit.", $User_Name);
	# / Audit Log

} # sub edit_reverse_proxy

sub html_delete_reverse_proxy {

	my $Select_Reverse_Proxy = $DB_Reverse_Proxy->prepare("SELECT `server_name`, `proxy_pass_source`, `proxy_pass_destination`
	FROM `reverse_proxy`
	WHERE `id` = ?");

	$Select_Reverse_Proxy->execute($Delete_Reverse_Proxy);
	
	while ( my ($Server_Name, $Proxy_Pass_Source, $Proxy_Pass_Destination) = $Select_Reverse_Proxy->fetchrow_array() )
	{


print <<ENDHTML;
<div id="small-popup-box">
<a href="/ReverseProxy/reverse-proxy.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Reverse Proxy</h3>

<form action='/ReverseProxy/reverse-proxy.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this reverse proxy entry?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Server:</td>
		<td style="text-align: left; color: #00FF00;">$Server_Name</td>
	</tr>
	<tr>
		<td style="text-align: right;">Source:</td>
		<td style="text-align: left; color: #00FF00;">$Proxy_Pass_Source</td>
	</tr>
	<tr>
		<td style="text-align: right;">Destination:</td>
		<td style="text-align: left; color: #00FF00;">$Proxy_Pass_Destination</td>
	</tr>
</table>

<input type='hidden' name='Delete_Reverse_Proxy_Confirm' value='$Delete_Reverse_Proxy'>
<input type='hidden' name='Reverse_Proxy_Delete' value='$Server_Name'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Reverse Proxy'></div>

</form>

ENDHTML

	}
} # sub html_delete_reverse_proxy

sub delete_reverse_proxy {

	# Audit Log
	my $Select_Reverse_Proxy = $DB_Reverse_Proxy->prepare("SELECT `server_name`, `proxy_pass_source`, `proxy_pass_destination`
	FROM `reverse_proxy`
	WHERE `id` = ?");

	$Select_Reverse_Proxy->execute($Delete_Reverse_Proxy_Confirm);
	
	while ( my ($Server_Name, $Proxy_Pass_Source, $Proxy_Pass_Destination) = $Select_Reverse_Proxy->fetchrow_array() )
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

		$Audit_Log_Submission->execute("Reverse Proxy", "Delete", "$User_Name deleted the proxy entry for $Server_Name, 
		with a source of $Proxy_Pass_Source and destination of $Proxy_Pass_Destination. The Reverse Proxy ID was $Delete_Reverse_Proxy_Confirm.", $User_Name);

	}
	# / Audit Log

	my $Delete_Reverse_Proxy = $DB_Reverse_Proxy->prepare("DELETE from `reverse_proxy`
		WHERE `id` = ?");
	
	$Delete_Reverse_Proxy->execute($Delete_Reverse_Proxy_Confirm);

} # sub delete_reverse_proxy

sub html_output {

	my $Table = new HTML::Table(
		-cols=>12,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);


	my $Select_Reverse_Proxy_Count = $DB_Reverse_Proxy->prepare("SELECT `id` FROM `reverse_proxy`");
		$Select_Reverse_Proxy_Count->execute( );
		my $Total_Rows = $Select_Reverse_Proxy_Count->rows();


	my $Select_Reverse_Proxies = $DB_Reverse_Proxy->prepare("SELECT `id`, `server_name`, `proxy_pass_source`,
		`proxy_pass_destination`, `transfer_log`, `error_log`, `ssl_certificate_file`, `ssl_certificate_key_file`, 
		`ssl_ca_certificate_file`, `last_modified`, `modified_by`
		FROM `reverse_proxy`
		WHERE `id` LIKE ?
		OR `server_name` LIKE ?
		OR `proxy_pass_source` LIKE ?
		OR `proxy_pass_destination` LIKE ?
		OR `transfer_log` LIKE ?
		OR `error_log` LIKE ?
		OR `ssl_certificate_file` LIKE ?
		OR `ssl_certificate_key_file` LIKE ?
		OR `ssl_ca_certificate_file` LIKE ?
		ORDER BY `server_name` ASC
		LIMIT 0 , $Rows_Returned"
	);

	$Select_Reverse_Proxies->execute("%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", 
		"%$Filter%", "%$Filter%", "%$Filter%");

	my $Rows = $Select_Reverse_Proxies->rows();

	$Table->addRow( "ID", "Server Name", "Source", "Destination", "Transfer Log", "Error Log", "SSL", "", 
		"Last Modified", "Modified By", "Edit", "Delete" );
	$Table->setCellColSpan(1, 7, 2); # row_num, col_num, num_cells
	$Table->setRowClass (1, 'tbrow1');
	
	my $Reverse_Proxy_Row_Count=1;

	while ( my @Select_Reverse_Proxies = $Select_Reverse_Proxies->fetchrow_array() )
	{

		$Reverse_Proxy_Row_Count+=3;

		my $DBID = $Select_Reverse_Proxies[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Server_Name = $Select_Reverse_Proxies[1];
			$Server_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Source = $Select_Reverse_Proxies[2];
			$Source =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Destination = $Select_Reverse_Proxies[3];
			$Destination =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Transfer_Log = $Select_Reverse_Proxies[4];
			$Transfer_Log =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Error_Log = $Select_Reverse_Proxies[5];
			$Error_Log =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $SSL_Certificate_File = $Select_Reverse_Proxies[6];
			my $SSL_Certificate_File_Clean = $SSL_Certificate_File;
			$SSL_Certificate_File =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $SSL_Certificate_Key_File = $Select_Reverse_Proxies[7];
			my $SSL_Certificate_Key_File_Clean = $SSL_Certificate_Key_File;
			$SSL_Certificate_Key_File =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $SSL_CA_Certificate_File = $Select_Reverse_Proxies[8];
			my $SSL_CA_Certificate_File_Clean = $SSL_CA_Certificate_File;
			$SSL_CA_Certificate_File =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Last_Modified = $Select_Reverse_Proxies[9];
		my $Modified_By = $Select_Reverse_Proxies[10];

		$Table->addRow(
			"$DBID",
			"$Server_Name",
			"$Source",
			"$Destination",
			"$Transfer_Log",
			"$Error_Log",
			"No SSL",
			"",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/ReverseProxy/reverse-proxy.cgi?Edit_Reverse_Proxy=$DBID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Reverse Proxy ID $DBID_Clean\" ></a>",
			"<a href='/ReverseProxy/reverse-proxy.cgi?Delete_Reverse_Proxy=$DBID_Clean'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Reverse Proxy ID $DBID_Clean\" ></a>"
		);

		if ($SSL_Certificate_File_Clean || $SSL_Certificate_Key_File_Clean || $SSL_CA_Certificate_File_Clean) {

			if ($SSL_Certificate_File_Clean) {
				$Table->setCell($Reverse_Proxy_Row_Count-2, 7, "Cert."); # row_num, col_num, num_cells
				$Table->setCell($Reverse_Proxy_Row_Count-2, 8, "$SSL_Certificate_File"); # row_num, col_num, num_cells
				$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 7, 'tbrowgreen');
			}
			else {
				$Table->setCell($Reverse_Proxy_Row_Count-2, 7, "Cert."); # row_num, col_num, num_cells
				$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 7, 'tbrowerror');
			}

			if ($SSL_Certificate_Key_File_Clean) {
				$Table->setCell($Reverse_Proxy_Row_Count-1, 7, "Key"); # row_num, col_num, num_cells
				$Table->setCell($Reverse_Proxy_Row_Count-1, 8, "$SSL_Certificate_Key_File"); # row_num, col_num, num_cells
				my $Row_Style = $Table->getCellStyle($Reverse_Proxy_Row_Count-2, 7);
					$Table->setCellStyle($Reverse_Proxy_Row_Count-1, 7, $Row_Style);
					$Table->setCellStyle($Reverse_Proxy_Row_Count-1, 8, $Row_Style);
				$Table->setCellClass ($Reverse_Proxy_Row_Count-1, 7, 'tbrowgreen');
			}
			else {
				$Table->setCell($Reverse_Proxy_Row_Count-1, 7, "Key"); # row_num, col_num, num_cells
				my $Row_Style = $Table->getCellStyle($Reverse_Proxy_Row_Count-2, 7);
					$Table->setCellStyle($Reverse_Proxy_Row_Count-1, 7, $Row_Style);
					$Table->setCellStyle($Reverse_Proxy_Row_Count-1, 8, $Row_Style);
				$Table->setCellClass ($Reverse_Proxy_Row_Count-1, 7, 'tbrowerror'); 
			}

			if ($SSL_CA_Certificate_File_Clean) {
				$Table->setCell($Reverse_Proxy_Row_Count, 7, "CA"); # row_num, col_num, num_cells
				$Table->setCell($Reverse_Proxy_Row_Count, 8, "$SSL_CA_Certificate_File"); # row_num, col_num, num_cells
				$Table->setCellClass ($Reverse_Proxy_Row_Count, 7, 'tbrowgreen');
			}
			else {
				$Table->setCell($Reverse_Proxy_Row_Count, 7, "CA"); # row_num, col_num, num_cells
				$Table->setCellClass ($Reverse_Proxy_Row_Count, 7, 'tbrowerror');
			}

		}
		else {
			$Table->setCellColSpan($Reverse_Proxy_Row_Count-2, 7, 2); # row_num, col_num, num_cells
			for (7..8) {
				$Table->setCellRowSpan($Reverse_Proxy_Row_Count-2, $_, 3); # row_num, col_num, num_cells
			}
		}

		for (1..6) {
			$Table->setCellRowSpan($Reverse_Proxy_Row_Count-2, $_, 3); # row_num, col_num, num_cells
		}
		for (9..12) {
			$Table->setCellRowSpan($Reverse_Proxy_Row_Count-2, $_, 3); # row_num, col_num, num_cells
		}

	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(9, '110px');
	$Table->setColWidth(10, '110px');
	$Table->setColWidth(11, '1px');
	$Table->setColWidth(12, '1px');

	$Table->setColAlign(1, 'center');
	for (7, 9..12) {
		$Table->setColAlign($_, 'center');
	}



print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/ReverseProxy/reverse-proxy.cgi' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Reverse Proxy" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/ReverseProxy/reverse-proxy.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Reverse Proxy</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Reverse_Proxy' value='Add Reverse Proxy'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/ReverseProxy/reverse-proxy.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Reverse Proxy</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Reverse Proxy' value='Edit Reverse Proxy'></td>
					<td align="center">
						<select name='Edit_Reverse_Proxy' style="width: 150px">
ENDHTML

						my $Reverse_Proxy_List_Query = $DB_Reverse_Proxy->prepare("SELECT `id`, `server_name`, `proxy_pass_source`, `proxy_pass_destination`
						FROM `reverse_proxy`
						ORDER BY `server_name` ASC");
						$Reverse_Proxy_List_Query->execute( );
						
						while ( my ($ID, $Server_Name, $Source, $Destination) = my @Reverse_Proxy_List_Query = $Reverse_Proxy_List_Query->fetchrow_array() )
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

<p style="font-size:14px; font-weight:bold;">Reverse Proxy | Reverse Proxies Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output