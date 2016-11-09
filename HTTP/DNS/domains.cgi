#!/usr/bin/perl

use strict;
use HTML::Table;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Domain = $CGI->param("Add_Domain");
	my $Domain_Add = $CGI->param("Domain_Add");
		$Domain_Add =~ s/\s//g;

my $Edit_Domain = $CGI->param("Edit_Domain");
my $Edit_Domain_Post = $CGI->param("Edit_Domain_Post");
	my $Domain_Edit = $CGI->param("Domain_Edit");
		$Domain_Edit =~ s/\s//g;

my $Delete_Domain = $CGI->param("Delete_Domain");
my $Delete_Domain_Confirm = $CGI->param("Delete_Domain_Confirm");
my $Domain_Delete = $CGI->param("Domain_Delete");

my $User_Name = $Session->param("User_Name");
my $User_DNS_Admin = $Session->param("User_DNS_Admin");

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $Filter = $CGI->param("Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}

if ($Add_Domain) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/domains.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_add_domain;
	}
}
elsif ($Domain_Add) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/domains.cgi\n\n";
		exit(0);
	}
	else {
		my $Domain_ID = &add_domain;
		my $Message_Green="$Domain_Add added successfully as ID $Domain_ID";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DNS/domains.cgi\n\n";
		exit(0);
	}
}
elsif ($Edit_Domain) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/domains.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_edit_domain;
	}
}
elsif ($Edit_Domain_Post) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/domains.cgi\n\n";
		exit(0);
	}
	else {
		&edit_domain;
		my $Message_Green="$Domain_Edit edited successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DNS/domains.cgi\n\n";
		exit(0);
	}
}
elsif ($Delete_Domain) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/domains.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_delete_domain;
	}
}
elsif ($Delete_Domain_Confirm) {
	if ($User_DNS_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /DNS/domains.cgi\n\n";
		exit(0);
	}
	else {
		&delete_domain;
		my $Message_Green="$Domain_Delete deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /DNS/domains.cgi\n\n";
		exit(0);
	}
}
else {
	require $Header;
	&html_output;
	require $Footer;
}



sub html_add_domain {

print <<ENDHTML;

<div id="small-popup-box">
<a href="/DNS/domains.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Domain</h3>

<form action='/DNS/domains.cgi' name='Add_Domain' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Domain:</td>
		<td colspan="2"><input type='text' name='Domain_Add' style="width:100%" maxlength='128' placeholder="domain.co.nz" required autofocus></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Domains must be unique and fully qualified.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Domain'></div>

</form>

ENDHTML

} #sub html_add_domain

sub add_domain {

	my $Domain_Insert = $DB_Connection->prepare("INSERT INTO `domains` (
		`domain`,
		`modified_by`
	)
	VALUES (
		?, ?
	)");

	$Domain_Insert->execute($Domain_Add, $User_Name);

	my $Domain_Insert_ID = $DB_Connection->{mysql_insertid};

	# Audit Log
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
	
	$Audit_Log_Submission->execute("Domains", "Add", "$User_Name added $Domain_Add. The system assigned it Domain ID $Domain_Insert_ID.", $User_Name);
	# / Audit Log

	return($Domain_Insert_ID);

} # sub add_domain

sub html_edit_domain {

	my $Select_Domain = $DB_Connection->prepare("SELECT `domain`
	FROM `domains`
	WHERE `id` = ?");
	$Select_Domain->execute($Edit_Domain);

	while ( my $Domain_Extract = $Select_Domain->fetchrow_array() )
	{


print <<ENDHTML;

<div id="small-popup-box">
<a href="/DNS/domains.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit Domain</h3>

<form action='/DNS/domains.cgi' name='Edit_Domains' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Domain:</td>
		<td colspan="2"><input type='text' name='Domain_Edit' value='$Domain_Extract' style="width:100%" maxlength='128' placeholder="$Domain_Extract" required autofocus></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>Domains must be unique and fully qualified.</li>
</ul>

<hr width="50%">
<input type='hidden' name='Edit_Domain_Post' value='$Edit_Domain'>
<div style="text-align: center"><input type=submit name='ok' value='Edit Domain'></div>

</form>

ENDHTML

	}
} # sub html_edit_domain

sub edit_domain {


	my $Update_Domain = $DB_Connection->prepare("UPDATE `domains` SET
		`domain` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
		
	$Update_Domain->execute($Domain_Edit, $User_Name, $Edit_Domain_Post);

	# Audit Log
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

	$Audit_Log_Submission->execute("Domains", "Modify", "$User_Name modified domain ID $Edit_Domain_Post. It is now recorded as $Domain_Edit.", $User_Name);
	# / Audit Log

} # sub edit_domain

sub html_delete_domain {

	my $Select_Domain = $DB_Connection->prepare("SELECT `domain`
	FROM `domains`
	WHERE `id` = ?");

	$Select_Domain->execute($Delete_Domain);
	
	while ( my $Domain_Extract = $Select_Domain->fetchrow_array() )
	{


print <<ENDHTML;
<div id="small-popup-box">
<a href="/DNS/domains.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Domain</h3>

<form action='/DNS/domains.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this domain?</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Domain:</td>
		<td style="text-align: left; color: #00FF00;">$Domain_Extract</td>
	</tr>
</table>

<input type='hidden' name='Delete_Domain_Confirm' value='$Delete_Domain'>
<input type='hidden' name='Domain_Delete' value='$Domain_Extract'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Domain'></div>

</form>

ENDHTML

	}
} # sub html_delete_domain

sub delete_domain {

	# Audit Log
	my $Select_Domains = $DB_Connection->prepare("SELECT `domain`
		FROM `domains`
		WHERE `id` = ?");

	$Select_Domains->execute($Delete_Domain_Confirm);

	while ( my ( $Domain_Extract ) = $Select_Domains->fetchrow_array() )
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

		$Audit_Log_Submission->execute("Domains", "Delete", "$User_Name deleted $Domain_Extract, domain ID $Delete_Domain_Confirm.", $User_Name);

	}
	# / Audit Log

	my $Delete_Domain = $DB_Connection->prepare("DELETE from `domains`
		WHERE `id` = ?");
	
	$Delete_Domain->execute($Delete_Domain_Confirm);

} # sub delete_domain

sub html_output {

	my $Table = new HTML::Table(
		-cols=>6,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);


	my $Select_Domain_Count = $DB_Connection->prepare("SELECT `id` FROM `domains`");
		$Select_Domain_Count->execute( );
		my $Total_Rows = $Select_Domain_Count->rows();


	my $Select_Domains = $DB_Connection->prepare("SELECT `id`, `domain`, `last_modified`, `modified_by`
		FROM `domains`
		WHERE `id` LIKE ?
		OR `domain` LIKE ?
		ORDER BY `domain` ASC
		LIMIT ?, ?"
	);

	$Select_Domains->execute("%$Filter%", "%$Filter%", 0, $Rows_Returned);

	my $Rows = $Select_Domains->rows();

	$Table->addRow( "ID", "Domain", "Last Modified", "Modified By", "Edit", "Delete" );
	$Table->setRowClass (1, 'tbrow1');

	my $Domain_Row_Count=1;

	while ( my @Select_Domains = $Select_Domains->fetchrow_array() )
	{

		$Domain_Row_Count++;

		my $DBID = $Select_Domains[0];
			my $DBID_Clean = $DBID;
			$DBID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Domain = $Select_Domains[1];
			$Domain =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
		my $Last_Modified = $Select_Domains[2];
		my $Modified_By = $Select_Domains[3];

		$Table->addRow(
			"$DBID",
			"$Domain",
			"$Last_Modified",
			"$Modified_By",
			"<a href='/DNS/domains.cgi?Edit_Domain=$DBID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Domain ID $DBID_Clean\" ></a>",
			"<a href='/DNS/domains.cgi?Delete_Domain=$DBID_Clean'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Domain ID $DBID_Clean\" ></a>"
		);

	}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(3, '110px');
	$Table->setColWidth(4, '110px');
	$Table->setColWidth(5, '1px');
	$Table->setColWidth(6, '1px');

	$Table->setColAlign(1, 'center');
	for (3..6) {
		$Table->setColAlign($_, 'center');
	}



print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/DNS/domains.cgi' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Domains" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/DNS/domains.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Domain</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Domain' value='Add Domain'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/DNS/domains.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Domain</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Domain' value='Edit Domain'></td>
					<td align="center">
						<select name='Edit_Domain' style="width: 150px">
ENDHTML

						my $Domain_List_Query = $DB_Connection->prepare("SELECT `id`, `domain`
						FROM `domains`
						ORDER BY `domain` ASC");
						$Domain_List_Query->execute( );
						
						while ( my ($ID, $Domain) = my @Domain_List_Query = $Domain_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Domain</option>";
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

<p style="font-size:14px; font-weight:bold;">Domains | Domains Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} # sub html_output