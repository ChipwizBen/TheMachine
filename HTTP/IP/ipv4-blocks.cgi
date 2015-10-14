#!/usr/bin/perl

use strict;

use Net::Ping::External qw(ping);
use Net::IP::XS qw($IP_NO_OVERLAP $IP_PARTIAL_OVERLAP $IP_A_IN_B_OVERLAP $IP_B_IN_A_OVERLAP $IP_IDENTICAL);
use POSIX qw(strftime);
use HTML::Table;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $DB_IP_Allocation = DB_IP_Allocation();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Block = $CGI->param("Add_Block");
my $Edit_Block = $CGI->param("Edit_Block");

my $Block_Name_Add = $CGI->param("Block_Name_Add");
my $Block_Description_Add = $CGI->param("Block_Description_Add");
my $Block_Add = $CGI->param("Block_Add");
	$Block_Add =~ s/\s//g;
	$Block_Add =~ s/[^0-9\.]//g;
my $Gateway_Add = $CGI->param("Gateway_Add");
	$Gateway_Add =~ s/\s//g;
	$Gateway_Add =~ s/[^0-9\.]//g;
my $Range_For_Use_Begin_Add = $CGI->param("Range_For_Use_Begin_Add");
	$Range_For_Use_Begin_Add =~ s/\s//g;
	$Range_For_Use_Begin_Add =~ s/[^0-9\.]//g;
my $Range_For_Use_End_Add = $CGI->param("Range_For_Use_End_Add");
	$Range_For_Use_End_Add =~ s/\s//g;
	$Range_For_Use_End_Add =~ s/[^0-9\.]//g;
my $Range_For_Use_Subnet_Add = $CGI->param("Range_For_Use_Subnet_Add");
	$Range_For_Use_Subnet_Add =~ s/\s//g;
	$Range_For_Use_Subnet_Add =~ s/[^0-9\.]//g;

my $Block_Name_Edit = $CGI->param("Block_Name_Edit");
my $Block_Description_Edit = $CGI->param("Block_Description_Edit");
my $Block_Edit = $CGI->param("Block_Edit");
	$Block_Edit =~ s/\s//g;
	$Block_Edit =~ s/[^0-9\.]//g;
my $Gateway_Edit = $CGI->param("Gateway_Edit");
	$Gateway_Edit =~ s/\s//g;
	$Gateway_Edit =~ s/[^0-9\.]//g;
my $Range_For_Use_Begin_Edit = $CGI->param("Range_For_Use_Begin_Edit");
	$Range_For_Use_Begin_Edit =~ s/\s//g;
	$Range_For_Use_Begin_Edit =~ s/[^0-9\.]//g;
my $Range_For_Use_End_Edit = $CGI->param("Range_For_Use_End_Edit");
	$Range_For_Use_End_Edit =~ s/\s//g;
	$Range_For_Use_End_Edit =~ s/[^0-9\.]//g;
my $Range_For_Use_Subnet_Edit = $CGI->param("Range_For_Use_Subnet_Edit");
	$Range_For_Use_Subnet_Edit =~ s/\s//g;
	$Range_For_Use_Subnet_Edit =~ s/[^0-9\.]//g;

my $Filter = $CGI->param("Filter");
my $User_Name = $Session->param("User_Name");
my $User_IP_Admin = $Session->param("User_IP_Admin");

my $Rows_Returned = $CGI->param("Rows_Returned");
	if ($Rows_Returned eq '') {
		$Rows_Returned='100';
	}

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

if ($User_IP_Admin != 1) {
	my $Message_Red = 'You do not have sufficient privileges to access that page.';
	$Session->param('Message_Red', $Message_Red);
	print "Location: /index.cgi\n\n";
	exit(0);
}

if ($Add_Block) {
	require $Header;
	&html_output;
	&html_add_block;
}
elsif ($Block_Add) {
	my $Block_ID = &add_block;
	my $Message_Green="$Block_Name_Add ($Block_Add) added successfully as ID $Block_ID";
	$Session->param('Message_Green', $Message_Green);
	print "Location: /IP/ipv4-blocks.cgi\n\n";
	exit(0);
}
elsif ($Edit_Block) {
	require $Header;
	&html_output;
	&html_edit_block;
}
elsif ($Block_Edit) {
	my $Block_ID = &edit_block;
	my $Message_Green="$Block_Name_Edit ($Block_Edit) edited successfully.";
	$Session->param('Message_Green', $Message_Green);
	print "Location: /IP/ipv4-blocks.cgi\n\n";
	exit(0);
}
else {
	require $Header;
	&html_output;	
}


sub html_add_block {

my $Date = strftime "%Y-%m-%d", localtime;

print <<ENDHTML;

<div id="wide-popup-box">
<a href="/IP/ipv4_blocks.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New Block</h3>

<form action='/IP/ipv4-blocks.cgi' name='Add_Hosts' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Block Name:</td>
		<td colspan="3"><input type='text' name='Block_Name_Add' style="width:100%" maxlength='128' placeholder="Block Name" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Block Description:</td>
		<td colspan="3"><input type='text' name='Block_Description_Add' style="width:100%" maxlength='128' placeholder="Block for IT test systems"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Block:</td>
		<td colspan="3"><input type='text' name='Block_Add' style="width:100%" maxlength='18' placeholder="192.168.0.0/21" required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Block Gateway:</td>
		<td colspan="3"><input type='text' name='Gateway_Add' style="width:100%" maxlength='15' placeholder="192.168.7.254"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Range for Use:</td>
		<td><input type='text' name='Range_For_Use_Begin_Add' style="width:100%" maxlength='15' placeholder="192.168.0.10"></td>
		<td>&nbsp;&nbsp;-&nbsp;&nbsp;</td>
		<td><input type='text' name='Range_For_Use_End_Add' style="width:100%" maxlength='15' placeholder="192.168.7.200"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Range for Use Subnet:</td>
		<td colspan="3"><input type='text' name='Range_For_Use_Subnet_Add' style="width:100%" maxlength='15' placeholder="255.255.248.0"></td>
	</tr>

</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Block names must be unique.</li>
<li>Gateway and Range data are optional fields, although defining a Gateway is useful for later allocation automation.</li>
<li>By setting a Range for Use, you can disclude IP addresses in a block from being allocated. For example, you may
wish to reserve the first 10 IP addresses in a block to reserve the block's network address (the first IP address in the 
block) and to manually allocate the first parts of a block to network devices, or you may wish to reserve the broadcast 
address (the last IP address in a block). It really depends on what you intend to do with the block - allocate 
individual addresses from the block, or breaking the block down into smaller blocks with individual network and 
broadcast addresses.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Host'></div>

</form>

ENDHTML

} #sub html_add_block

sub add_block {
	
} # sub add_block

sub html_output {

my $Table = new HTML::Table(
	-cols=>8,
	-align=>'center',
	-border=>0,
	-rules=>'cols',
	-evenrowclass=>'tbeven',
	-oddrowclass=>'tbodd',
	-width=>'100%',
	-spacing=>0,
	-padding=>1
);
$Table->addRow ( "Block Name", "Block Description", "IPv4 Block", "Gateway", "Range for Use", "Range for Use Subnet", "Used", "Delete" );
$Table->setRowClass (1, 'tbrow1');
$Table->setRowStyle(1, "background-color:#293E77;");

my $IPv4_Block_Query = $DB_IP_Allocation->prepare("SELECT `id`, `ip_block_name`, `ip_block_description`, `ip_block`, `gateway`, `range_for_use`, `range_for_use_subnet`, `percent_used`
FROM `ipv4_address_blocks`
WHERE `ip_block` LIKE ?
	OR `ip_block_name` LIKE ?
	OR `ip_block_description` LIKE ?
	OR `range_for_use` LIKE ?
	OR `range_for_use_subnet` LIKE ?
	OR `percent_used` LIKE ?
ORDER BY
	SUBSTRING_INDEX(`ip_block`,'.',1)+0,
    SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-3),'.',1)+0,
    SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-2),'.',1)+0,
    SUBSTRING_INDEX(`ip_block`,'.',-1)+0 ASC");
$IPv4_Block_Query->execute("%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%");

my $Rows = $IPv4_Block_Query->rows();
my $IP_Block_Total_Count = $DB_IP_Allocation->prepare("SELECT `id` FROM `ipv4_address_blocks`");
	$IP_Block_Total_Count->execute( );
	my $Total_Rows = $IP_Block_Total_Count->rows();

my $Row_Count=1;
while ( my @IPv4_Block_Query_Output = $IPv4_Block_Query->fetchrow_array() )
{

	$Row_Count++;
	
	my $ID =$IPv4_Block_Query_Output[0];
	my $Block_Name = $IPv4_Block_Query_Output[1];
		$Block_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Block_Description = $IPv4_Block_Query_Output[2];
		$Block_Description =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Block_Extract = $IPv4_Block_Query_Output[3];
		my $Block = $Block_Extract;
		$Block =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Gateway_Extract = $IPv4_Block_Query_Output[4];
	my $Range_For_Use = $IPv4_Block_Query_Output[5];
		$Range_For_Use =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Range_For_Use_Subnet = $IPv4_Block_Query_Output[6];
		$Range_For_Use_Subnet =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Percent_Used = $IPv4_Block_Query_Output[7];
		$Percent_Used = sprintf("%.2f", $Percent_Used);
		$Percent_Used =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	
	
	$Table->addRow( $Block_Name, $Block_Description, $Block, $Gateway_Extract,
		$Range_For_Use, $Range_For_Use_Subnet, $Percent_Used."%", 
		"<a href='/IP/ipv4-blocks.cgi?Delete=$ID'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Block $Block_Extract\" ></a>");
	$Table->setColClass (8, 'tbenablecolumn');
	
	if ($Percent_Used <= 50) {
		$Table->setCellClass ($Row_Count, 7, 'tbrowgreen');
	}
	elsif ($Percent_Used <= 75) {
		$Table->setCellClass ($Row_Count, 7, 'tbrowyellow');
	}
	elsif ($Percent_Used <= 90) {
		$Table->setCellClass ($Row_Count, 7, 'tbrowwarning');
	}
	elsif ($Percent_Used > 90) {
		$Table->setCellClass ($Row_Count, 7, 'tbrowerror');
	}
}

	$Table->setColWidth(8, '1px');
	$Table->setColAlign(7, 'center');
	$Table->setColAlign(8, 'center');

print <<ENDHTML;

<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/IP/ipv4-blocks.cgi' method='post' >
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
						<input type='search' name='Filter' style="width: 150px" maxlength='100' value="$Filter" title="Search Blocks" placeholder="Search">
					</td>
				</tr>
			</form>
			</table>
		</td>
		<td align="center">
			<form action='/IP/ipv4-blocks.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Block</span></td>
				</tr>
				<tr>
					<td align="center"><input type='submit' name='Add_Block' value='Add Block'></td>
				</tr>
			</table>
			</form>
		</td>
		<td align="right">
			<form action='/IP/ipv4-blocks.cgi' method='post' >
			<table>
				<tr>
					<td colspan="2" align="center"><span style="font-size: 18px; color: #FFC600;">Edit Block</span></td>
				</tr>
				<tr>
					<td style="text-align: right;"><input type=submit name='Edit Block' value='Edit Block'></td>
					<td align="center">
						<select name='Edit_Block' style="width: 150px">
ENDHTML

						my $Block_List_Query = $DB_IP_Allocation->prepare("SELECT `id`, `ip_block_name`, `ip_block`
						FROM `ipv4_address_blocks`
						ORDER BY `ip_block_name` ASC");
						$Block_List_Query->execute( );
						
						while ( my ($ID, $Block_Name, $Block) = my @Block_List_Query = $Block_List_Query->fetchrow_array() )
						{
							print "<option value='$ID'>$Block_Name ($Block)</option>";
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

<p style="font-size:14px; font-weight:bold;">IPv4 Blocks | Blocks Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML
} #sub html_output end


