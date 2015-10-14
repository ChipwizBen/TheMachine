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
	$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
	print "Location: /index.cgi\n\n";
	exit(0);
}

require $Header;
&html_output;

sub html_output {

my $Table = new HTML::Table(
	-cols=>7,
	-align=>'center',
	-border=>0,
	-rules=>'cols',
	-evenrowclass=>'tbeven',
	-oddrowclass=>'tbodd',
	-width=>'100%',
	-spacing=>0,
	-padding=>1
);
$Table->addRow ( "IP Block", "Block Name", "Block Description", "Range for Use", "Range for Use Subnet", "Used", "Delete" );
$Table->setRowClass (1, 'tbrow1');
$Table->setRowStyle(1, "background-color:#293E77;");

my $IPv4_Block_Query = $DB_IP_Allocation->prepare("SELECT `id`, `ip_block`, `ip_block_name`, `ip_block_description`, `range_for_use`, `range_for_use_subnet`, `percent_used`
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
	my $IPv4_Block_Extract = $IPv4_Block_Query_Output[1];
		my $IPv4_Block = $IPv4_Block_Extract;
		$IPv4_Block =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $IPv4_Block_Name = $IPv4_Block_Query_Output[2];
		$IPv4_Block_Name =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $IPv4_Block_Description = $IPv4_Block_Query_Output[3];
		$IPv4_Block_Description =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $IPv4_Range_For_Use = $IPv4_Block_Query_Output[4];
		$IPv4_Range_For_Use =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $IPv4_Range_For_Use_Subnet = $IPv4_Block_Query_Output[5];
		$IPv4_Range_For_Use_Subnet =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $IPv4_Percent_Used = $IPv4_Block_Query_Output[6];
		$IPv4_Percent_Used = sprintf("%.2f", $IPv4_Percent_Used);
		$IPv4_Percent_Used =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	
	
	$Table->addRow( $IPv4_Block, $IPv4_Block_Name, $IPv4_Block_Description, $IPv4_Range_For_Use, 
		$IPv4_Range_For_Use_Subnet, $IPv4_Percent_Used."%", 
		"<a href='/IP/ipv4-blocks.cgi?Delete=$ID'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Block $IPv4_Block_Extract\" ></a>");
	$Table->setColClass (7, 'tbenablecolumn');
	
	if ($IPv4_Percent_Used <= 50) {
		$Table->setCellClass ($Row_Count, 6, 'tbrowgreen');
	}
	elsif ($IPv4_Percent_Used <= 75) {
		$Table->setCellClass ($Row_Count, 6, 'tbrowyellow');
	}
	elsif ($IPv4_Percent_Used <= 90) {
		$Table->setCellClass ($Row_Count, 6, 'tbrowwarning');
	}
	elsif ($IPv4_Percent_Used > 90) {
		$Table->setCellClass ($Row_Count, 6, 'tbrowerror');
	}
}

	$Table->setColWidth(7, '1px');
	$Table->setColAlign(6, 'center');
	$Table->setColAlign(7, 'center');

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


