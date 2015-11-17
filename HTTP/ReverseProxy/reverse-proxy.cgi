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
	my $Reverse_Proxy_Add = $CGI->param("Reverse_Proxy_Add");
		$Reverse_Proxy_Add =~ s/\s//g;

my $Edit_Reverse_Proxy = $CGI->param("Edit_Reverse_Proxy");
my $Edit_Reverse_Proxy_Post = $CGI->param("Edit_Reverse_Proxy_Post");
	my $Reverse_Proxy_Edit = $CGI->param("Reverse_Proxy_Edit");
		$Reverse_Proxy_Edit =~ s/\s//g;

my $Delete_Reverse_Proxy = $CGI->param("Delete_Reverse_Proxy");
my $Delete_Reverse_Proxy_Confirm = $CGI->param("Delete_Reverse_Proxy_Confirm");
my $Reverse_Proxy_Delete = $CGI->param("Reverse_Proxy_Delete");

my $User_Name = $Session->param("User_Name");
my $User_Admin = $Session->param("User_Admin");

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
	require $Header;
	&html_output;
	require $Footer;
	&html_add_reverse_proxy;
}
elsif ($Reverse_Proxy_Add) {
	my $Reverse_Proxy_ID = &add_reverse_proxy;
	my $Message_Green="$Reverse_Proxy_Add added successfully as ID $Reverse_Proxy_ID";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
	exit(0);
}
elsif ($Edit_Reverse_Proxy) {
	require $Header;
	&html_output;
	require $Footer;
	&html_edit_reverse_proxy;
}
elsif ($Edit_Reverse_Proxy_Post) {
	&edit_reverse_proxy;
	my $Message_Green="$Reverse_Proxy_Edit edited successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
	exit(0);
}
elsif ($Delete_Reverse_Proxy) {
	require $Header;
	&html_output;
	require $Footer;
	&html_delete_reverse_proxy;
}
elsif ($Delete_Reverse_Proxy_Confirm) {
	&delete_reverse_proxy;
	my $Message_Green="$Reverse_Proxy_Delete deleted successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /ReverseProxy/reverse-proxy.cgi\n\n";
	exit(0);
}
else {
	require $Header; ## no critic
	&html_output;
	require $Footer;
}



sub html_add_reverse_proxy {

my $Date = strftime "%Y-%m-%d", localtime;

print <<ENDHTML;

<div id="small-popup-box">
<a href="/ReverseProxy/reverse-proxy.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Reverse Proxy</h3>

<form action='/ReverseProxy/reverse-proxy.cgi' name='Add_Reverse_Proxy' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Reverse Proxy:</td>
		<td colspan="2"><input type='text' name='Reverse_Proxy_Add' style="width:100%" maxlength='128' placeholder="domain.co.nz" required autofocus></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Reverse Proxy must be unique and fully qualified.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Reverse Proxy'></div>

</form>

ENDHTML

} #sub html_add_reverse_proxy

sub add_reverse_proxy {

	my $Reverse_Proxy_Insert = $DB_Reverse_Proxy->prepare("INSERT INTO `reverse_proxy` (
		`domain`,
		`modified_by`
	)
	VALUES (
		?, ?
	)");

	$Reverse_Proxy_Insert->execute($Reverse_Proxy_Add, $User_Name);

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
	
	$Audit_Log_Submission->execute("Reverse Proxy", "Add", "$User_Name added $Reverse_Proxy_Add. The system assigned it Reverse Proxy ID $Reverse_Proxy_Insert_ID.", $User_Name);
	# / Audit Log

	return($Reverse_Proxy_Insert_ID);

} # sub add_reverse_proxy

sub html_edit_reverse_proxy {

	my $Select_Reverse_Proxy = $DB_Reverse_Proxy->prepare("SELECT `domain`
	FROM `reverse_proxy`
	WHERE `id` = ?");
	$Select_Reverse_Proxy->execute($Edit_Reverse_Proxy);

	while ( my $Reverse_Proxy_Extract = $Select_Reverse_Proxy->fetchrow_array() )
	{


print <<ENDHTML;

<div id="small-popup-box">
<a href="/ReverseProxy/reverse-proxy.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Reverse Proxy</h3>

<form action='/ReverseProxy/reverse-proxy.cgi' name='Edit_Reverse_Proxies' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Reverse Proxy:</td>
		<td colspan="2"><input type='text' name='Reverse_Proxy_Edit' value='$Reverse_Proxy_Extract' style="width:100%" maxlength='128' placeholder="$Reverse_Proxy_Extract" required autofocus></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Reverse Proxy must be unique and fully qualified.</li>
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
		`domain` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		
	$Update_Reverse_Proxy->execute($Reverse_Proxy_Edit, $User_Name, $Edit_Reverse_Proxy_Post);

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

	$Audit_Log_Submission->execute("Reverse Proxy", "Modify", "$User_Name modified domain ID $Edit_Reverse_Proxy_Post. It is now recorded as $Reverse_Proxy_Edit.", $User_Name);
	# / Audit Log

} # sub edit_reverse_proxy

sub html_delete_reverse_proxy {

	my $Select_Reverse_Proxy = $DB_Reverse_Proxy->prepare("SELECT `domain`
	FROM `reverse_proxy`
	WHERE `id` = ?");

	$Select_Reverse_Proxy->execute($Delete_Reverse_Proxy);
	
	while ( my $Reverse_Proxy_Extract = $Select_Reverse_Proxy->fetchrow_array() )
	{


print <<ENDHTML;
<div id="small-popup-box">
<a href="/ReverseProxy/reverse-proxy.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Reverse Proxy</h3>

<form action='/ReverseProxy/reverse-proxy.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this domain?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Reverse Proxy:</td>
		<td style="text-align: left; color: #00FF00;">$Reverse_Proxy_Extract</td>
	</tr>
</table>

<input type='hidden' name='Delete_Reverse_Proxy_Confirm' value='$Delete_Reverse_Proxy'>
<input type='hidden' name='Reverse_Proxy_Delete' value='$Reverse_Proxy_Extract'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Reverse Proxy'></div>

</form>

ENDHTML

	}
} # sub html_delete_reverse_proxy

sub delete_reverse_proxy {

	# Audit Log
	my $Select_Reverse_Proxies = $DB_Reverse_Proxy->prepare("SELECT `domain`
		FROM `reverse_proxy`
		WHERE `id` = ?");

	$Select_Reverse_Proxies->execute($Delete_Reverse_Proxy_Confirm);

	while ( my ( $Reverse_Proxy_Extract ) = $Select_Reverse_Proxies->fetchrow_array() )
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

		$Audit_Log_Submission->execute("Reverse Proxy", "Delete", "$User_Name deleted $Reverse_Proxy_Extract, domain ID $Delete_Reverse_Proxy_Confirm.", $User_Name);

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
				`echo "$Row_Style" >> /tmp/output`; 
			}
			else {
				$Table->setCell($Reverse_Proxy_Row_Count-1, 7, "Key"); # row_num, col_num, num_cells
				my $Row_Style = $Table->getCellStyle($Reverse_Proxy_Row_Count-2, 7);
					$Table->setCellStyle($Reverse_Proxy_Row_Count-1, 7, $Row_Style);
					$Table->setCellStyle($Reverse_Proxy_Row_Count-1, 8, $Row_Style);
				$Table->setCellClass ($Reverse_Proxy_Row_Count-1, 7, 'tbrowerror');
				`echo "$Row_Style" >> /tmp/output`; 
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

						my $Reverse_Proxy_List_Query = $DB_Reverse_Proxy->prepare("SELECT `id`, `domain`
						FROM `reverse_proxy`
						ORDER BY `domain` ASC");
						$Reverse_Proxy_List_Query->execute( );
						
						while ( my ($ID, $Reverse_Proxy) = my @Reverse_Proxy_List_Query = $Reverse_Proxy_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Reverse_Proxy</option>";
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