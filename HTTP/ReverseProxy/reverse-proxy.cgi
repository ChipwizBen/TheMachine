#!/usr/bin/perl -T

use strict;
use HTML::Table;

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();
my $Me = '/ReverseProxy/reverse-proxy.cgi';

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
		my $PFS_Add = $CGI->param("PFS_Add");
		my $RC4_Add = $CGI->param("RC4_Add");
		my $Enforce_SSL_Add = $CGI->param("Enforce_SSL_Add");
			my $HSTS_Add = $CGI->param("HSTS_Add");
	my $X_Frame_Options_Add = $CGI->param("X_Frame_Options_Add");
	my $X_XSS_Protection_Add = $CGI->param("X_XSS_Protection_Add");
	my $X_Content_Type_Options_Add = $CGI->param("X_Content_Type_Options_Add");
	my $Content_Security_Policy_Add = $CGI->param("Content_Security_Policy_Add");
	my $X_Permitted_Cross_Domain_Policies_Add = $CGI->param("X_Permitted_Cross_Domain_Policies_Add");
	my $X_Powered_By_Add = $CGI->param("X_Powered_By_Add");
	my $Custom_Attributes_Add = $CGI->param("Custom_Attributes_Add");

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
		my $PFS_Edit = $CGI->param("PFS_Edit");
		my $RC4_Edit = $CGI->param("RC4_Edit");
		my $Enforce_SSL_Edit = $CGI->param("Enforce_SSL_Edit");
			my $HSTS_Edit = $CGI->param("HSTS_Edit");
	my $X_Frame_Options_Edit = $CGI->param("X_Frame_Options_Edit");
	my $X_XSS_Protection_Edit = $CGI->param("X_XSS_Protection_Edit");
	my $X_Content_Type_Options_Edit = $CGI->param("X_Content_Type_Options_Edit");
	my $Content_Security_Policy_Edit = $CGI->param("Content_Security_Policy_Edit");
	my $X_Permitted_Cross_Domain_Policies_Edit = $CGI->param("X_Permitted_Cross_Domain_Policies_Edit");
	my $X_Powered_By_Edit = $CGI->param("X_Powered_By_Edit");
	my $Custom_Attributes_Edit = $CGI->param("Custom_Attributes_Edit");
my $Edit_Reverse_Proxy_Post = $CGI->param("Edit_Reverse_Proxy_Post");

my $Delete_Reverse_Proxy = $CGI->param("Delete_Reverse_Proxy");
my $Delete_Reverse_Proxy_Confirm = $CGI->param("Delete_Reverse_Proxy_Confirm");
my $Reverse_Proxy_Delete = $CGI->param("Reverse_Proxy_Delete");

my $View_Reverse_Proxy = $CGI->param("View_Reverse_Proxy");

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

if ($Add_Reverse_Proxy) {
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
		&html_add_reverse_proxy;
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
		my $Reverse_Proxy_ID = &add_reverse_proxy;
		my $Message_Green="Reverse proxy entry for $Server_Name_Add added successfully as ID $Reverse_Proxy_ID";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
}
elsif ($Edit_Reverse_Proxy) {
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
		&html_edit_reverse_proxy;
	}
}
elsif ($Edit_Reverse_Proxy_Post) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
	else {
		&edit_reverse_proxy;
		my $Message_Green="The Reverse Proxy entry for $Server_Name_Edit (ID $Edit_Reverse_Proxy_Post) was edited successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
}
elsif ($Delete_Reverse_Proxy) {
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
		&html_delete_reverse_proxy;
	}
}
elsif ($Delete_Reverse_Proxy_Confirm) {
	if ($User_Reverse_Proxy_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
	else {
		&delete_reverse_proxy;
		my $Message_Green="The reverse proxy entry for $Reverse_Proxy_Delete was deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: $Me\n\n";
		exit(0);
	}
}
elsif ($View_Reverse_Proxy) {
		require $Header;
		&html_output;
		require $Footer;
		&html_view_reverse_proxy;
}
else {
	require $Header;
	&html_output;
	require $Footer;
}



sub html_add_reverse_proxy {

print <<ENDHTML;

<div id="wide-popup-box">
<a href="$Me">
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
		document.getElementById('Enforce').style.display='table-row';
		document.getElementById('PFS').style.display='table-row';
		document.getElementById('RC4').style.display='table-row';
	}
	else if(value=="Off") {
		document.getElementById('Cert').style.display='none';
		document.getElementById('Key').style.display='none';
		document.getElementById('CA').style.display='none';
		document.getElementById('Enforce').style.display='none';
		document.getElementById('PFS').style.display='none';
		document.getElementById('RC4').style.display='none';
	}
	else {
		document.getElementById('Cert').style.display='none';
		document.getElementById('Key').style.display='none';
		document.getElementById('CA').style.display='none';
		document.getElementById('Enforce').style.display='none';
		document.getElementById('PFS').style.display='none';
		document.getElementById('RC4').style.display='none';
	}
}
function Enforce_SSL_Toggle(value) {
	if(value=="1"){
		document.getElementById('HSTS').style.display='table-row';
	}
	else if(value=="0"){
		document.getElementById('HSTS').style.display='none';
	}
	else {
		document.getElementById('HSTS').style.display='none';
	}
}
//-->
</SCRIPT>

<form action='$Me' name='Add_Reverse_Proxy' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Server Name:</td>
		<td colspan="2"><input type='text' name='Server_Name_Add' style="width:100%" maxlength='1024' placeholder="FQDN,Alias1,Alias2" required autofocus></td>
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
	<tr style="display: none;" id="PFS">
		<td style="text-align: right;">PFS (Perfect Forward Secrecy):</td>
		<td colspan="2" style="text-align: left;">
			<select name='PFS_Add'">
				<option value='1'>On</option>
				<option value='0'>Off</option>
			</select>
		</td>
	</tr>
	<tr style="display: none;" id="RC4">
		<td style="text-align: right;">Legacy RC4 Support:</td>
		<td colspan="2" style="text-align: left;">
			<select name='RC4_Add'">
				<option value='0'>Off (Recommended)</option>
				<option value='1'>On (Not Safe)</option>
			</select>
		</td>
	</tr>
	<tr style="display: none;" id="Enforce">
		<td style="text-align: right;">Enforce SSL:</td>
		<td colspan="2" style="text-align: left;">
			<select name='Enforce_SSL_Add' onchange="Enforce_SSL_Toggle(this.value);">
				<option value='0'>No</option>
				<option value='1'>Yes</option>
			</select>
		</td>
	</tr>
	<tr style="display: none;" id="HSTS">
		<td style="text-align: right;">HSTS (HTTP Strict Transport Security):</td>
		<td colspan="2" style="text-align: left;">
			<select name='HSTS_Add'">
				<option value='1'>On</option>
				<option value='0'>Off</option>
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">X-Frame-Options:</td>
		<td colspan="2" style="text-align: left;">
			<select name='X_Frame_Options_Add'">
				<option value='0' selected>Default</option>
				<option value='1'>Deny</option>
				<option value='2'>SameOrigin</option>
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">X-XSS-Protection:</td>
		<td colspan="2" style="text-align: left;">
			<select name='X_XSS_Protection_Add'">
				<option value='0' selected>Default</option>
				<option value='1'>1; mode=block</option>
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">X-Content-Type-Options:</td>
		<td colspan="2" style="text-align: left;">
			<select name='X_Content_Type_Options_Add'">
				<option value='0' selected>Default</option>
				<option value='1'>nosniff</option>
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Content-Security-Policy:</td>
		<td colspan="2" style="text-align: left;">
			<select name='Content_Security_Policy_Add'">
				<option value='0' selected>Default</option>
				<option value='1'>default-src 'self'</option>
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">X-Permitted-Cross-Domain-Policies:</td>
		<td colspan="2" style="text-align: left;">
			<select name='X_Permitted_Cross_Domain_Policies_Add'">
				<option value='0' selected>Default</option>
				<option value='1'>none</option>
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">X-Powered-By:</td>
		<td colspan="2" style="text-align: left;">
			<select name='X_Powered_By_Add'">
				<option value='0' selected>Default</option>
				<option value='1'>unset</option>
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Custom Attributes:</td>
		<td colspan="2" style="text-align: left;">
			<textarea name='Custom_Attributes_Add' placeholder='&lt;Location "/admin"&gt;Require ip 192.168.0.0/16&lt;/Location&gt;'></textarea>
		</td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Server, Source and Destination must be defined. You can defined aliases by comma seperating several server names.</li>
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

	if ($SSL_Toggle_Add ne 'On') {
		$Certificate_Add = '';
		$Certificate_Key_Add = '';
		$CA_Certificate_Add = '';
		$PFS_Add = 0;
		$RC4_Add = 0;
		$Enforce_SSL_Add = 0;
		$HSTS_Add = 0;
	}

	if (!$Transfer_Log_Add) {$Transfer_Log_Add = $Default_Transfer_Log;}
	if (!$Error_Log_Add) {$Error_Log_Add = $Default_Error_Log;}
	if ($Enforce_SSL_Add == 0) {$HSTS_Add = '0'};

	my $Reverse_Proxy_Insert = $DB_Connection->prepare("INSERT INTO `reverse_proxy` (
		`server_name`,
		`proxy_pass_source`,
		`proxy_pass_destination`,
		`transfer_log`,
		`error_log`,
		`ssl_certificate_file`,
		`ssl_certificate_key_file`,
		`ssl_ca_certificate_file`,
		`pfs`,
		`rc4`,
		`enforce_ssl`,
		`hsts`,
		`frame_options`,
		`xss_protection`,
		`content_type_options`,
		`content_security_policy`,
		`permitted_cross_domain_policies`,
		`powered_by`,
		`custom_attributes`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?,
		?, ?, ?, ?,
		?, ?, ?, ?,
		?, ?, ?, ?,
		?, ?, ?, ?
	)");

	$Reverse_Proxy_Insert->execute($Server_Name_Add, $Source_Add, $Destination_Add, $Transfer_Log_Add, 
	$Error_Log_Add, $Certificate_Add, $Certificate_Key_Add, $CA_Certificate_Add, 
	$PFS_Add, $RC4_Add, $Enforce_SSL_Add, $HSTS_Add, 
	$X_Frame_Options_Add, $X_XSS_Protection_Add, $X_Content_Type_Options_Add, $Content_Security_Policy_Add,
	$X_Permitted_Cross_Domain_Policies_Add, $X_Powered_By_Add, $Custom_Attributes_Add, $User_Name);

	my $Reverse_Proxy_Insert_ID = $DB_Connection->{mysql_insertid};

	# Audit Log
	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();
	
	$Audit_Log_Submission->execute("Reverse Proxy", "Add", "$User_Name added an entry from $Source_Add to $Destination_Add for $Server_Name_Add. The system assigned it Reverse Proxy ID $Reverse_Proxy_Insert_ID.", $User_Name);
	# / Audit Log

	return($Reverse_Proxy_Insert_ID);

} # sub add_reverse_proxy

sub html_edit_reverse_proxy {

	my $Filter_URL;
	if ($Filter) {$Filter_URL = "?Filter=$Filter"}
	if ($ID_Filter) {$Filter_URL = "?ID_Filter=$ID_Filter"}

	my $Select_Reverse_Proxy = $DB_Connection->prepare("SELECT `server_name`, `proxy_pass_source`,
		`proxy_pass_destination`, `transfer_log`, `error_log`, `ssl_certificate_file`, `ssl_certificate_key_file`, 
		`ssl_ca_certificate_file`, `pfs`, `rc4`, `enforce_ssl`, `hsts`, `frame_options`, `xss_protection`, `content_type_options`,
		`content_security_policy`, `permitted_cross_domain_policies`, `powered_by`, `custom_attributes`
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
		my $PFS = $Reverse_Proxy_Values[8];
		my $RC4 = $Reverse_Proxy_Values[9];
		my $Enforce_SSL = $Reverse_Proxy_Values[10];
		my $HSTS = $Reverse_Proxy_Values[11];
		my $X_Frame_Options = $Reverse_Proxy_Values[12];
		my $X_XSS_Protection = $Reverse_Proxy_Values[13];
		my $X_Content_Type_Options = $Reverse_Proxy_Values[14];
		my $Content_Security_Policy = $Reverse_Proxy_Values[15];
		my $X_Permitted_Cross_Domain_Policies = $Reverse_Proxy_Values[16];
		my $X_Powered_By = $Reverse_Proxy_Values[17];
		my $Custom_Attributes = $Reverse_Proxy_Values[18];

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

		my $Enforce_SSL_Display;
		my $Enforce_SSL_Toggle;
		if ($Enforce_SSL) {
			$Enforce_SSL_Toggle = "<option value='0'>No</option>
				<option value='1' selected>Yes</option>";
			$Enforce_SSL_Display = 'table-row';
		}
		else {
			$Enforce_SSL_Toggle = "<option value='0' selected>No</option>
				<option value='1'>Yes</option>";
			$Enforce_SSL_Display = 'none';
		}

print <<ENDHTML;

<div id="wide-popup-box">
<a href="$Me$Filter_URL">
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
		document.getElementById('Enforce').style.display='table-row';
		document.getElementById('PFS').style.display='table-row';
		document.getElementById('RC4').style.display='table-row';
	}
	else if(value=="Off") {
		document.getElementById('Cert').style.display='none';
		document.getElementById('Key').style.display='none';
		document.getElementById('CA').style.display='none';
		document.getElementById('Enforce').style.display='none';
		document.getElementById('PFS').style.display='none';
		document.getElementById('RC4').style.display='none';
	}
	else {
		document.getElementById('Cert').style.display='$SSL_Display';
		document.getElementById('Key').style.display='$SSL_Display';
		document.getElementById('CA').style.display='$SSL_Display';
		document.getElementById('Enforce').style.display='$SSL_Display';
		document.getElementById('PFS').style.display='$Enforce_SSL_Display';
		document.getElementById('RC4').style.display='$Enforce_SSL_Display';
	}
}
function Enforce_SSL_Toggle(value) {
	if(value=="1"){
		document.getElementById('HSTS').style.display='table-row';
	}
	else if(value=="0"){
		document.getElementById('HSTS').style.display='none';
	}
	else {
		document.getElementById('HSTS').style.display='none';
	}
}
//-->
</SCRIPT>

<form action='$Me' name='Edit_Reverse_Proxy' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Server Name:</td>
		<td colspan="2"><input type='text' name='Server_Name_Edit' value='$Server_Name' style="width:100%" maxlength='1024' placeholder="$Server_Name" required autofocus></td>
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
	<tr style="display: $SSL_Display;" id="PFS">
		<td style="text-align: right;">PFS (Perfect Forward Secrecy):</td>
		<td colspan="2" style="text-align: left;">
			<select name='PFS_Edit'">
ENDHTML

	if ($PFS) {
		print "<option value='1' selected>On</option>
				<option value='0'>Off</option>";
	}
	else {
		print "<option value='1'>On</option>
				<option value='0' selected>Off</option>";
	}

print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr style="display: $SSL_Display;" id="RC4">
		<td style="text-align: right;">Legacy RC4 Support:</td>
		<td colspan="2" style="text-align: left;">
			<select name='RC4_Edit'">
ENDHTML

	if (!$RC4) {
		print "<option value='0' selected>Off (Recommended)</option>
				<option value='1'>On (Not Safe)</option>";
	}
	else {
		print "<option value='0'>Off (Recommended)</option>
				<option value='1' selected>On (Not Safe)</option>";
	}

print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr style="display: $SSL_Display;" id="Enforce">
		<td style="text-align: right;">Enforce SSL:</td>
		<td colspan="2" style="text-align: left;">
			<select name='Enforce_SSL_Edit' onchange="Enforce_SSL_Toggle(this.value);">
				$Enforce_SSL_Toggle
			</select>
		</td>
	</tr>
	<tr style="display: $Enforce_SSL_Display;" id="HSTS">
		<td style="text-align: right;">HSTS (HTTP Strict Transport Security):</td>
		<td colspan="2" style="text-align: left;">
			<select name='HSTS_Edit'">
ENDHTML

	if ($HSTS) {
		print "<option value='1' selected>On</option>
				<option value='0'>Off</option>";
	}
	else {
		print "<option value='1'>On</option>
				<option value='0' selected>Off</option>";
	}

print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">X-Frame-Options:</td>
		<td colspan="2" style="text-align: left;">
			<select name='X_Frame_Options_Edit'">
ENDHTML

	if ($X_Frame_Options == 1) {
		print "<option value='0'>Default</option>
		<option value='1' selected>Deny</option>
		<option value='2'>SameOrigin</option>";
	}
	elsif ($X_Frame_Options == 2) {
		print "<option value='0'>Default</option>
		<option value='1'>Deny</option>
		<option value='2' selected>SameOrigin</option>";
	}
	else {
		print "<option value='0' selected>Default</option>
		<option value='1'>Deny</option>
		<option value='2'>SameOrigin</option>";
	}

print <<ENDHTML;

			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">X-XSS-Protection:</td>
		<td colspan="2" style="text-align: left;">
			<select name='X_XSS_Protection_Edit'">
ENDHTML

	if ($X_XSS_Protection) {
		$X_XSS_Protection = 'Header always set X-XSS-Protection "1; mode=block"';
		print "<option value='0'>Default</option>
		<option value='1' selected>1; mode=block</option>";
	}
	else {
		print "<option value='0' selected>Default</option>
		<option value='1'>1; mode=block</option>";
	}

print <<ENDHTML;

			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">X-Content-Type-Options:</td>
		<td colspan="2" style="text-align: left;">
			<select name='X_Content_Type_Options_Edit'">

ENDHTML

	if ($X_Content_Type_Options) {
		print "<option value='0'>Default</option>
		<option value='1' selected>nosniff</option>";
	}
	else {
		print "<option value='0' selected>Default</option>
		<option value='1'>nosniff</option>";
	}

print <<ENDHTML;

			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Content-Security-Policy:</td>
		<td colspan="2" style="text-align: left;">
			<select name='Content_Security_Policy_Edit'">
ENDHTML

	if ($Content_Security_Policy) {
		print "<option value='0'>Default</option>
		<option value='1' selected>default-src 'self'</option>";
	}
	else {
		print "<option value='0' selected>Default</option>
		<option value='1'>default-src 'self'</option>";
	}

print <<ENDHTML;

			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">X-Permitted-Cross-Domain-Policies:</td>
		<td colspan="2" style="text-align: left;">
			<select name='X_Permitted_Cross_Domain_Policies_Edit'">
ENDHTML

	if ($X_Permitted_Cross_Domain_Policies) {
		print "<option value='0'>Default</option>
		<option value='1' selected>none</option>";
	}
	else {
		print "<option value='0' selected>Default</option>
		<option value='1'>none</option>";
	}

print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">X-Powered-By:</td>
		<td colspan="2" style="text-align: left;">
			<select name='X_Powered_By_Edit'">
ENDHTML

	if ($X_Powered_By) {
		print "<option value='0'>Default</option>
		<option value='1' selected>unset</option>";
	}
	else {
		print "<option value='0' selected>Default</option>
		<option value='1'>unset</option>";
	}

print <<ENDHTML;

			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Custom Attributes:</td>
		<td colspan="2" style="text-align: left;">
			<textarea name='Custom_Attributes_Edit'>$Custom_Attributes</textarea>
		</td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Server, Source and Destination must be defined. You can defined aliases by comma seperating several server names.</li>
</ul>

<hr width="50%">

<input type='hidden' name='Edit_Reverse_Proxy_Post' value='$Edit_Reverse_Proxy'>
<div style="text-align: center"><input type=submit name='ok' value='Edit Reverse Proxy'></div>

</form>


ENDHTML

	}
} # sub html_edit_reverse_proxy

sub edit_reverse_proxy {

	my ($Default_Transfer_Log,
		$Default_Error_Log,
		$Default_SSL_Certificate_File,
		$Default_SSL_Certificate_Key_File,
		$Default_SSL_CA_Certificate_File) = Reverse_Proxy_Defaults();

	if ($SSL_Toggle_Edit ne 'On') {
		$Certificate_Edit = '';
		$Certificate_Key_Edit = '';
		$CA_Certificate_Edit = '';
		$PFS_Edit = 0;
		$RC4_Edit = 0;
		$Enforce_SSL_Edit = 0;
		$HSTS_Edit = 0;
	}

	if (!$Transfer_Log_Edit) {$Transfer_Log_Edit = $Default_Transfer_Log;}
	if (!$Error_Log_Edit) {$Error_Log_Edit = $Default_Error_Log;}
	if ($Enforce_SSL_Edit == 0) {$HSTS_Edit = '0'};

	my $Update_Reverse_Proxy = $DB_Connection->prepare("UPDATE `reverse_proxy` SET
		`server_name` = ?,
		`proxy_pass_source` = ?,
		`proxy_pass_destination` = ?,
		`transfer_log` = ?,
		`error_log` = ?,
		`ssl_certificate_file` = ?,
		`ssl_certificate_key_file` = ?,
		`ssl_ca_certificate_file` = ?,
		`pfs` = ?,
		`rc4` = ?,
		`enforce_ssl` = ?,
		`hsts` = ?,
		`frame_options` = ?,
		`xss_protection` = ?,
		`content_type_options` = ?,
		`content_security_policy` = ?,
		`permitted_cross_domain_policies` = ?,
		`powered_by` = ?,
		`custom_attributes` = ?,
		`modified_by` = ?
		WHERE `id` = ?");

	$Update_Reverse_Proxy->execute($Server_Name_Edit, $Source_Edit, $Destination_Edit, $Transfer_Log_Edit, $Error_Log_Edit,
		$Certificate_Edit, $Certificate_Key_Edit, $CA_Certificate_Edit, $PFS_Edit, $RC4_Edit, $Enforce_SSL_Edit, $HSTS_Edit,
		$X_Frame_Options_Edit, $X_XSS_Protection_Edit, $X_Content_Type_Options_Edit, $Content_Security_Policy_Edit,
		$X_Permitted_Cross_Domain_Policies_Edit, $X_Powered_By_Edit, $Custom_Attributes_Edit, $User_Name, $Edit_Reverse_Proxy_Post);

	# Audit Log
	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();

	$Audit_Log_Submission->execute("Reverse Proxy", "Modify", "$User_Name modified Reverse Proxy ID $Edit_Reverse_Proxy_Post. 
	It is now recorded as server $Server_Name_Edit, with a source of $Source_Edit and destination of $Destination_Edit.", $User_Name);
	# / Audit Log

} # sub edit_reverse_proxy

sub html_delete_reverse_proxy {

	my $Filter_URL;
	if ($Filter) {$Filter_URL = "?Filter=$Filter"}
	if ($ID_Filter) {$Filter_URL = "?ID_Filter=$ID_Filter"}

	my $Select_Reverse_Proxy = $DB_Connection->prepare("SELECT `server_name`, `proxy_pass_source`, `proxy_pass_destination`
	FROM `reverse_proxy`
	WHERE `id` = ?");

	$Select_Reverse_Proxy->execute($Delete_Reverse_Proxy);
	
	while ( my ($Server_Name, $Proxy_Pass_Source, $Proxy_Pass_Destination) = $Select_Reverse_Proxy->fetchrow_array() )
	{


print <<ENDHTML;
<div id="small-popup-box">
<a href="$Me$Filter_URL">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Reverse Proxy</h3>

<form action='$Me' method='post' >
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
	my $Select_Reverse_Proxy = $DB_Connection->prepare("SELECT `server_name`, `proxy_pass_source`, `proxy_pass_destination`
	FROM `reverse_proxy`
	WHERE `id` = ?");

	$Select_Reverse_Proxy->execute($Delete_Reverse_Proxy_Confirm);
	
	while ( my ($Server_Name, $Proxy_Pass_Source, $Proxy_Pass_Destination) = $Select_Reverse_Proxy->fetchrow_array() )
	{

		my $DB_Connection = DB_Connection();
		my $Audit_Log_Submission = Audit_Log_Submission();

		$Audit_Log_Submission->execute("Reverse Proxy", "Delete", "$User_Name deleted the proxy entry for $Server_Name, 
		with a source of $Proxy_Pass_Source and destination of $Proxy_Pass_Destination. The Reverse Proxy ID was $Delete_Reverse_Proxy_Confirm.", $User_Name);

	}
	# / Audit Log

	my $Delete_Reverse_Proxy = $DB_Connection->prepare("DELETE from `reverse_proxy`
		WHERE `id` = ?");
	
	$Delete_Reverse_Proxy->execute($Delete_Reverse_Proxy_Confirm);

} # sub delete_reverse_proxy

sub html_view_reverse_proxy {

	my ($Default_Transfer_Log,
		$Default_Error_Log,
		$Default_SSL_Certificate_File,
		$Default_SSL_Certificate_Key_File,
		$Default_SSL_CA_Certificate_File) = Reverse_Proxy_Defaults();

	my $Record_Query = $DB_Connection->prepare("SELECT `server_name`, `proxy_pass_source`, `proxy_pass_destination`, 
	`transfer_log`, `error_log`, `ssl_certificate_file`, `ssl_certificate_key_file`, `ssl_ca_certificate_file`,
	`pfs`, `rc4`, `enforce_ssl`, `hsts`, `frame_options`, `xss_protection`, `content_type_options`,	`content_security_policy`, 
	`permitted_cross_domain_policies`, `powered_by`, `custom_attributes`, `last_modified`, `modified_by`
	FROM `reverse_proxy`
	WHERE `id` = ?");
	$Record_Query->execute($View_Reverse_Proxy);

	my $Reverse_Proxy_HTML;
	while ( my @Proxy_Entry = $Record_Query->fetchrow_array() )
	{
		my $Server_Name = $Proxy_Entry[0];
		my $Source = $Proxy_Entry[1];
		my $Destination = $Proxy_Entry[2];
		my $Transfer_Log = $Proxy_Entry[3];
		my $Error_Log = $Proxy_Entry[4];
		my $SSL_Certificate_File = $Proxy_Entry[5];
		my $SSL_Certificate_Key_File = $Proxy_Entry[6];
		my $SSL_CA_Certificate_File = $Proxy_Entry[7];
		my $PFS = $Proxy_Entry[8];
		my $RC4 = $Proxy_Entry[9];
		my $Enforce_SSL = $Proxy_Entry[10];
		my $HSTS = $Proxy_Entry[11];
		my $Frame_Options = $Proxy_Entry[12];
		my $XSS_Protection = $Proxy_Entry[13];
		my $Content_Type_Options = $Proxy_Entry[14];
		my $Content_Security_Policy = $Proxy_Entry[15];
		my $Permitted_Cross_Domain_Policies = $Proxy_Entry[16];
		my $Powered_By = $Proxy_Entry[17];
		my $Custom_Attributes = $Proxy_Entry[18];
			$Custom_Attributes =~ s/\n/\n    /g;
		my $Last_Modified = $Proxy_Entry[19];
		my $Modified_By = $Proxy_Entry[20];

		my $ServerAliases;
		my @ServerAliases = split(',', $Server_Name);
		$Server_Name = shift @ServerAliases;
		foreach my $Alias (@ServerAliases) {
			$ServerAliases = $ServerAliases . "\n    ServerAlias              $Alias";
		}
		my $Server_Names = "ServerName               " . $Server_Name . $ServerAliases;

		if (!$Transfer_Log) {$Transfer_Log = $Default_Transfer_Log}
		if (!$Error_Log) {$Error_Log = $Default_Error_Log}

		my $Headers;
		if ($Frame_Options == 1) {
			$Frame_Options = 'Header always set        X-Frame-Options deny';
			$Headers = $Headers . $Frame_Options . '\n    ';
		}
		elsif ($Frame_Options == 2) {
			$Frame_Options = 'Header always set        X-Frame-Options sameorigin';
			$Headers = $Headers . $Frame_Options . '\n    ';
		}
		if ($XSS_Protection) {
			$XSS_Protection = 'Header always set        X-XSS-Protection "1; mode=block"';
			$Headers = $Headers . $XSS_Protection . '\n    ';
		}
		if ($Content_Type_Options) {
			$Content_Type_Options = 'Header always set        X-Content-Type-Options nosniff';
			$Headers = $Headers . $Content_Type_Options . '\n    ';
		}
		if ($Content_Security_Policy) {
			$Content_Security_Policy = 'Header always set        Content-Security-Policy "default-src \'self\'"';
			$Headers = $Headers . $Content_Security_Policy . '\n    ';
		}
		if ($Permitted_Cross_Domain_Policies) {
			$Permitted_Cross_Domain_Policies = 'Header always set        X-Permitted-Cross-Domain-Policies none';
			$Headers = $Headers . $Permitted_Cross_Domain_Policies . '\n    ';
		}
		if ($Powered_By) {
			$Powered_By = 'Header unset             X-Powered-By';
			$Headers = $Headers . $Powered_By . '\n    ';
		}

		if ($SSL_Certificate_File && $SSL_Certificate_Key_File && $SSL_CA_Certificate_File) {
			if (!$SSL_Certificate_File) {$SSL_Certificate_File = $Default_SSL_Certificate_File}
			if (!$SSL_Certificate_Key_File) {$SSL_Certificate_Key_File = $Default_SSL_Certificate_Key_File}
			if (!$SSL_CA_Certificate_File) {$SSL_CA_Certificate_File = $Default_SSL_CA_Certificate_File}

			my $CipherOrder;
			my $CipherSuite;
			if ($PFS && $RC4) {
				$CipherOrder = 'SSLHonorCipherOrder on';
				$CipherSuite = "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";
			}
			elsif ($PFS && !$RC4) {
				$CipherOrder = 'SSLHonorCipherOrder on';
				$CipherSuite = "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS !RC4";
			}
			else {
				$CipherOrder = '';
				$CipherSuite = "HIGH:!SSLv2:!ADH:!aNULL:!eNULL:!NULL";
			}

			my $Enforce_SSL_Header;
			if ($Enforce_SSL) {
				$Enforce_SSL_Header = "
    <IfModule mod_rewrite.c>
        RewriteEngine       On
        RewriteCond         %{HTTPS}    off
        RewriteRule         (.*)    https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
    </IfModule>
    <IfModule !mod_rewrite.c>
        Redirect             /    https://$Server_Name
    </IfModule>";
			}	

			my $HSTS_Header;
			if ($HSTS) {
				#$HSTS_Header = 'Header always set		Strict-Transport-Security "max-age=31536000; includeSubDomains"';
				$HSTS_Header = 'Header always set		Strict-Transport-Security "max-age=31536000"';
			}

			$Reverse_Proxy_HTML = "
<VirtualHost *:80>
    $Server_Names
    $Enforce_SSL_Header
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost *:443>
    $Server_Names

    SSLProxyEngine           On
    ProxyRequests            Off
    ProxyPreserveHost        On
    ProxyPass                $Source    $Destination
    ProxyPassReverse         $Source    $Destination

    SSLEngine                On
    $HSTS_Header
    $Headers
    SSLProtocol              ALL -SSLv2 -SSLv3
    $CipherOrder
    SSLCipherSuite           \"$CipherSuite\"
    SSLInsecureRenegotiation Off

    SSLCertificateFile       $SSL_Certificate_File
    SSLCertificateKeyFile    $SSL_Certificate_Key_File
    SSLCACertificateFile     $SSL_CA_Certificate_File

    TransferLog              $Transfer_Log
    ErrorLog                 $Error_Log
    $Custom_Attributes
</VirtualHost>
</IfModule>
"
		}
		else {
			$Reverse_Proxy_HTML = "
<VirtualHost *:80>
    $Server_Names

    ProxyRequests            Off
    ProxyPreserveHost        On
    ProxyPass                $Source    $Destination
    ProxyPassReverse         $Source    $Destination
    $Headers
    TransferLog              $Transfer_Log
    ErrorLog                 $Error_Log
    $Custom_Attributes
</VirtualHost>

";
		}
	}

$Reverse_Proxy_HTML =~ s/</&lt;/g;
$Reverse_Proxy_HTML =~ s/>/&gt;/g;
$Reverse_Proxy_HTML =~ s/\\n/<br>/g;

my $Filter_URL;
if ($Filter) {$Filter_URL = "?Filter=$Filter"}
if ($ID_Filter) {$Filter_URL = "?ID_Filter=$ID_Filter"}


print <<ENDHTML;

<div id="wide-popup-box">
<a href="$Me$Filter_URL">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Config for Reverse Proxy ID $View_Reverse_Proxy</h3>

<pre style='text-align: left; padding-left:20px; white-space:pre-wrap; word-wrap:break-word;'><code>$Reverse_Proxy_HTML</code></pre>

</div>

ENDHTML

} #sub html_view_reverse_proxy

sub html_output {

	my ($Default_Transfer_Log,
		$Default_Error_Log,
		$Default_SSL_Certificate_File,
		$Default_SSL_Certificate_Key_File,
		$Default_SSL_CA_Certificate_File) = Reverse_Proxy_Defaults();

	my $Table = new HTML::Table(
		-cols=>15,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);

	my $Select_Reverse_Proxy_Count = $DB_Connection->prepare("SELECT `id` FROM `reverse_proxy`");
		$Select_Reverse_Proxy_Count->execute( );
		my $Total_Rows = $Select_Reverse_Proxy_Count->rows();


	my $Select_Reverse_Proxies = $DB_Connection->prepare("SELECT `id`, `server_name`, `proxy_pass_source`,
		`proxy_pass_destination`, `transfer_log`, `error_log`, `ssl_certificate_file`, `ssl_certificate_key_file`, 
		`ssl_ca_certificate_file`, `pfs`, `rc4`, `enforce_ssl`, `hsts`, `frame_options`, `xss_protection`, `content_type_options`,
		`content_security_policy`, `permitted_cross_domain_policies`, `powered_by`, `custom_attributes`, `last_modified`, `modified_by`
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
		LIMIT ?, ?"
	);

	if ($ID_Filter) {
		$Select_Reverse_Proxies->execute("%$ID_Filter%", "", "", "", "", "", 
		"", "", "", 0, $Rows_Returned);
	}
	else {
		$Select_Reverse_Proxies->execute("%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", 
		"%$Filter%", "%$Filter%", "%$Filter%", 0, $Rows_Returned);		
	}


	my $Rows = $Select_Reverse_Proxies->rows();

	$Table->addRow( "ID", "Server Name<br /><span style='color: #B6B600'>Server Alias</span>", "Source<br /><span style='color: #B6B600'>Destination</span>", 
	"Transfer Log<br /><span style='color: #B6B600'>Error Log</span>", "SSL Files", "", "Header Flags", 
	"Perfect Forward Secrecy", "Legacy RC4 Support", "Enforce SSL", "Custom Attributes", 
	"Last Modified<br /><span style='color: #B6B600'>Modified By</span>", "View", "Edit", "Delete" );
	$Table->setCellColSpan(1, 5, 2); # row_num, col_num, num_cells
	$Table->setRowClass (1, 'tbrow1');
	
	my $Reverse_Proxy_Row_Count=1;

	while ( my @Select_Reverse_Proxies = $Select_Reverse_Proxies->fetchrow_array() )
	{

		$Reverse_Proxy_Row_Count+=3;

		my $DBID = $Select_Reverse_Proxies[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Server_Name = $Select_Reverse_Proxies[1];
		my $Source = $Select_Reverse_Proxies[2];
			$Source =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Destination = $Select_Reverse_Proxies[3];
			$Destination =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #FFFFFF'>$2<\/span>$3/gi;
		my $Transfer_Log = $Select_Reverse_Proxies[4];
			my $Transfer_Log_Clean = $Transfer_Log;
			$Transfer_Log =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
				if (!$Transfer_Log_Clean) {$Transfer_Log = "$Default_Transfer_Log <span style=\"color: #FF8A00\">[Default]</span>"}
		my $Error_Log = $Select_Reverse_Proxies[5];
			my $Error_Log_Clean = $Error_Log;
			$Error_Log =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #FFFFFF'>$2<\/span>$3/gi;
				if (!$Error_Log_Clean) {$Error_Log = "$Default_Error_Log <span style=\"color: #FF8A00\">[Default]</span>"}
		my $SSL_Certificate_File = $Select_Reverse_Proxies[6];
			my $SSL_Certificate_File_Clean = $SSL_Certificate_File;
			$SSL_Certificate_File =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $SSL_Certificate_Key_File = $Select_Reverse_Proxies[7];
			my $SSL_Certificate_Key_File_Clean = $SSL_Certificate_Key_File;
			$SSL_Certificate_Key_File =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $SSL_CA_Certificate_File = $Select_Reverse_Proxies[8];
			my $SSL_CA_Certificate_File_Clean = $SSL_CA_Certificate_File;
			$SSL_CA_Certificate_File =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $PFS = $Select_Reverse_Proxies[9];
		my $RC4 = $Select_Reverse_Proxies[10];
		my $Enforce_SSL = $Select_Reverse_Proxies[11];
		my $HSTS = $Select_Reverse_Proxies[12];
		my $Frame_Options = $Select_Reverse_Proxies[13];
		my $XSS_Protection = $Select_Reverse_Proxies[14];
		my $Content_Type_Options = $Select_Reverse_Proxies[15];
		my $Content_Security_Policy = $Select_Reverse_Proxies[16];
		my $Permitted_Cross_Domain_Policies = $Select_Reverse_Proxies[17];
		my $Powered_By = $Select_Reverse_Proxies[18];
		my $Custom_Attributes = $Select_Reverse_Proxies[19];
		my $Last_Modified = $Select_Reverse_Proxies[20];
		my $Modified_By = $Select_Reverse_Proxies[21];

		my $ServerAliases;
		my @ServerAliases = split(',', $Server_Name);
		$Server_Name = shift @ServerAliases;
		$Server_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		foreach my $Alias (@ServerAliases) {
			$ServerAliases = $ServerAliases . "<br/>$Alias";
			$ServerAliases =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #FFFFFF'>$2<\/span>$3/gi;
		}

		if ($PFS) {$PFS = 'On'} else {$PFS = 'Off'};
		if ($RC4) {$RC4 = 'On'} else {$RC4 = 'Off'};
		if ($Enforce_SSL) {$Enforce_SSL = 'Yes'} else {$Enforce_SSL = 'No'};
		if ($HSTS) {$Enforce_SSL = 'Yes (HSTS)'};
		if ($Custom_Attributes) {$Custom_Attributes = 'Yes'} else {$Custom_Attributes = 'No'}

		my $Headers;
		if ($Frame_Options == 1) {$Frame_Options = 'X-Frame-Options: deny'; $Headers = $Headers . $Frame_Options . '<br />'}
			elsif ($Frame_Options == 2) {$Frame_Options = 'X-Frame-Options: sameorigin'; $Headers = $Headers . $Frame_Options . '<br />'}
		if ($XSS_Protection) {$XSS_Protection = 'X-XSS-Protection: 1; mode=block'; $Headers = $Headers . $XSS_Protection . '<br />'}
		if ($Content_Type_Options) {$Content_Type_Options = 'X-Content-Type-Options: nosniff'; $Headers = $Headers . $Content_Type_Options . '<br />'}
		if ($Content_Security_Policy) {$Content_Security_Policy = 'Content-Security-Policy: default-src \'self\''; $Headers = $Headers . $Content_Security_Policy . '<br />'}
		if ($Permitted_Cross_Domain_Policies) {$Permitted_Cross_Domain_Policies = 'X-Permitted-Cross-Domain-Policies: none'; $Headers = $Headers . $Permitted_Cross_Domain_Policies . '<br />'}
		if ($Powered_By) {$Powered_By = 'X-Powered-By: unset'; $Headers = $Headers . $Powered_By . '<br />'}

		my $View;
		my $Edit;
		my $Delete;
		if ($Filter || $ID_Filter) {
			my $Filter_URL;
			if ($Filter) {$Filter_URL = "Filter=$Filter"} else {$Filter_URL = "ID_Filter=$ID_Filter"}
			$View = "<a href='$Me?View_Reverse_Proxy=$DBID_Clean&$Filter_URL'><img src=\"/resources/imgs/view-notes.png\" alt=\"View Reverse Proxy ID $DBID_Clean\" ></a>";
			$Edit = "<a href='$Me?Edit_Reverse_Proxy=$DBID_Clean&$Filter_URL'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Reverse Proxy ID $DBID_Clean\" ></a>";
			$Delete = "<a href='$Me?Delete_Reverse_Proxy=$DBID_Clean&$Filter_URL'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Reverse Proxy ID $DBID_Clean\" ></a>";
		}
		else {
			$View = "<a href='$Me?View_Reverse_Proxy=$DBID_Clean'><img src=\"/resources/imgs/view-notes.png\" alt=\"View Reverse Proxy ID $DBID_Clean\" ></a>";
			$Edit = "<a href='$Me?Edit_Reverse_Proxy=$DBID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Reverse Proxy ID $DBID_Clean\" ></a>";
			$Delete = "<a href='$Me?Delete_Reverse_Proxy=$DBID_Clean'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Reverse Proxy ID $DBID_Clean\" ></a>";
		}

		$Table->addRow(
			"$DBID",
			"$Server_Name<span style='color: #B6B600'>$ServerAliases</span>",
			"$Source<br /><span style='color: #B6B600'>$Destination</span>",
			"$Transfer_Log<br /><span style='color: #B6B600'>$Error_Log</span>",
			"No SSL",
			"",
			"$Headers",
			"$PFS",
			"$RC4",
			"$Enforce_SSL",
			"$Custom_Attributes",
			"$Last_Modified<br /><span style='color: #B6B600'>$Modified_By</span>",
			$View,
			$Edit,
			$Delete
		);

		if ($SSL_Certificate_File_Clean || $SSL_Certificate_Key_File_Clean || $SSL_CA_Certificate_File_Clean) {

			if ($SSL_Certificate_File_Clean) {
				$Table->setCell($Reverse_Proxy_Row_Count-2, 5, "Cert."); # row_num, col_num, content
				$Table->setCell($Reverse_Proxy_Row_Count-2, 6, "$SSL_Certificate_File"); # row_num, col_num, content
				$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 5, 'tbrowgreen');
			}
			else {
				$Table->setCell($Reverse_Proxy_Row_Count-2, 5, "Cert."); # row_num, col_num, content
				$Table->setCell($Reverse_Proxy_Row_Count-2, 6, "$Default_SSL_Certificate_File <span style=\"color: #FF8A00\">[Default]</span>"); # row_num, col_num, content
				$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 5, 'tbroworange');
			}

			if ($SSL_Certificate_Key_File_Clean) {
				$Table->setCell($Reverse_Proxy_Row_Count-1, 5, "Key"); # row_num, col_num, content
				$Table->setCell($Reverse_Proxy_Row_Count-1, 6, "$SSL_Certificate_Key_File"); # row_num, col_num, content
				my $Row_Style = $Table->getCellStyle($Reverse_Proxy_Row_Count-2, 5);
					$Table->setCellStyle($Reverse_Proxy_Row_Count-1, 5, $Row_Style);
					$Table->setCellStyle($Reverse_Proxy_Row_Count-1, 6, $Row_Style);
				$Table->setCellClass ($Reverse_Proxy_Row_Count-1, 5, 'tbrowgreen');
			}
			else {
				$Table->setCell($Reverse_Proxy_Row_Count-1, 5, "Key"); # row_num, col_num, content
				my $Row_Style = $Table->getCellStyle($Reverse_Proxy_Row_Count-2, 5);
					$Table->setCellStyle($Reverse_Proxy_Row_Count-1, 5, $Row_Style);
					$Table->setCellStyle($Reverse_Proxy_Row_Count-1, 6, $Row_Style);
				$Table->setCell($Reverse_Proxy_Row_Count-1, 6, "$Default_SSL_Certificate_Key_File <span style=\"color: #FF8A00\">[Default]</span>"); # row_num, col_num, content
				$Table->setCellClass ($Reverse_Proxy_Row_Count-1, 5, 'tbroworange'); 
			}

			if ($SSL_CA_Certificate_File_Clean) {
				$Table->setCell($Reverse_Proxy_Row_Count, 5, "CA"); # row_num, col_num, content
				$Table->setCell($Reverse_Proxy_Row_Count, 6, "$SSL_CA_Certificate_File"); # row_num, col_num, content
				$Table->setCellClass ($Reverse_Proxy_Row_Count, 5, 'tbrowgreen');
			}
			else {
				$Table->setCell($Reverse_Proxy_Row_Count, 5, "CA"); # row_num, col_num, content
				$Table->setCell($Reverse_Proxy_Row_Count, 6, "$Default_SSL_CA_Certificate_File <span style=\"color: #FF8A00\">[Default]</span>"); # row_num, col_num, content
				$Table->setCellClass ($Reverse_Proxy_Row_Count, 5, 'tbroworange');
			}

		}
		else {
			$Table->setCellColSpan($Reverse_Proxy_Row_Count-2, 5, 2); # row_num, col_num, num_cells
			for (5..6) {
				$Table->setCellRowSpan($Reverse_Proxy_Row_Count-2, $_, 3); # row_num, col_num, num_cells
			}

			$PFS = 'N/A';
				$Table->setCell($Reverse_Proxy_Row_Count-2, 8, "$PFS"); # row_num, col_num, content
			$RC4 = 'N/A';
				$Table->setCell($Reverse_Proxy_Row_Count-2, 9, "$RC4"); # row_num, col_num, content
			$Enforce_SSL = 'N/A';
				$Table->setCell($Reverse_Proxy_Row_Count-2, 10, "$Enforce_SSL"); # row_num, col_num, content
		}


		if ($PFS eq 'On') {
			$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 8, 'tbrowgreen');
		}
		elsif ($PFS eq 'N/A') {
			$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 8, 'tbrowdarkgrey');
		}
		else {
			$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 8, 'tbrowred');
		}
		
		if ($RC4 eq 'Off') {
			$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 9, 'tbrowgreen');
		}
		elsif ($RC4 eq 'N/A') {
			$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 9, 'tbrowdarkgrey');
		}
		else {
			$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 9, 'tbrowred');
		}
		
		if ($Enforce_SSL eq 'Yes') {
			$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 10, 'tbroworange');
		}
		elsif ($Enforce_SSL =~ /HSTS/){
			$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 10, 'tbrowgreen');
		}
		elsif ($Enforce_SSL eq 'N/A') {
			$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 10, 'tbrowdarkgrey');
		}
		else {
			$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 10, 'tbrowred');
		}

		if ($Custom_Attributes eq 'Yes') {$Table->setCellClass ($Reverse_Proxy_Row_Count-2, 11, 'tbroworange');}

		for (1..4) {
			$Table->setCellRowSpan($Reverse_Proxy_Row_Count-2, $_, 3); # row_num, col_num, num_cells
		}
		for (7..15) {
			$Table->setCellRowSpan($Reverse_Proxy_Row_Count-2, $_, 3); # row_num, col_num, num_cells
		}

	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(8, '1px');
	$Table->setColWidth(9, '1px');
	$Table->setColWidth(10, '1px');
	$Table->setColWidth(11, '1px');
	$Table->setColWidth(12, '110px');
	$Table->setColWidth(13, '1px');
	$Table->setColWidth(14, '1px');
	$Table->setColWidth(15, '1px');

	$Table->setColAlign(1, 'center');
	for (5, 8..15) {
		$Table->setColAlign($_, 'center');
	}


print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='$Me' method='post' >
				<tr>
					<td style="text-align: right;">Returned Rows:</td>
					<td style="text-align: left;">
						<select name='Rows_Returned' onchange='this.form.submit()' style="width: 150px">
ENDHTML

if ($Rows_Returned == 100) {print "<option value=100 selected>100</option>";} else {print "<option value=100>100</option>";}
if ($Rows_Returned == 250) {print "<option value=250 selected>250</option>";} else {print "<option value=250>250</option>";}
if ($Rows_Returned == 500) {print "<option value=500 selected>500</option>";} else {print "<option value=500>500</option>";}
if ($Rows_Returned == 1000) {print "<option value=1000 selected>1000</option>";} else {print "<option value=1000>1000</option>";}
if ($Rows_Returned == 2500) {print "<option value=2500 selected>2500</option>";} else {print "<option value=2500>2500</option>";}
if ($Rows_Returned == 5000) {print "<option value=5000 selected>5000</option>";} else {print "<option value=5000>5000</option>";}
if ($Rows_Returned == 18446744073709551615) {print "<option value=18446744073709551615 selected>All</option>";} else {print "<option value=18446744073709551615>All</option>";}

my $Clear_Filter;
if ($Filter) {$Clear_Filter = "<a href='$Me?Filter='>[Clear]</a>"}

print <<ENDHTML;
						</select>
					</td>
				</tr>
				<tr>
					<td style="text-align: right;">
						Filter:
					</td>
					<td style="text-align: left;">
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Reverse Proxy" placeholder="Search"> $Clear_Filter
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='$Me' method='post' >
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
			<form action='$Me' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Reverse Proxy</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Reverse Proxy' value='Edit Reverse Proxy'></td>
					<td align="center">
						<select name='Edit_Reverse_Proxy' style="width: 150px">
ENDHTML

						my $Reverse_Proxy_List_Query = $DB_Connection->prepare("SELECT `id`, `server_name`, `proxy_pass_source`, `proxy_pass_destination`
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