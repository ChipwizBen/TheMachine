#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);


use Net::IP::XS qw($IP_NO_OVERLAP $IP_PARTIAL_OVERLAP $IP_A_IN_B_OVERLAP $IP_B_IN_A_OVERLAP $IP_IDENTICAL);
use POSIX qw(strftime);
use HTML::Table;

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $Add_Block = $CGI->param("Add_Block");
my $Edit_Block = $CGI->param("Edit_Block");
my $Query_Block = $CGI->param("Query_Block");

my $Block_Name_Add = $CGI->param("Block_Name_Add");
my $Block_Description_Add = $CGI->param("Block_Description_Add");
my $Block_Network_Add = $CGI->param("Block_Network_Add");
	$Block_Network_Add =~ s/\s//g;
	$Block_Network_Add =~ s/[^0-9\.]//g;
my $Block_CIDR_Add = $CGI->param("Block_CIDR_Add");
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
my $DNS_1_Add = $CGI->param("DNS_1_Add");
	$DNS_1_Add =~ s/\s//g;
	$DNS_1_Add =~ s/[^0-9\.]//g;
my $DNS_2_Add = $CGI->param("DNS_2_Add");
	$DNS_2_Add =~ s/\s//g;
	$DNS_2_Add =~ s/[^0-9\.]//g;
my $NTP_1_Add = $CGI->param("NTP_1_Add");
	$NTP_1_Add =~ s/\s//g;
	$NTP_1_Add =~ s/[^0-9\.]//g;
my $NTP_2_Add = $CGI->param("NTP_2_Add");
	$NTP_2_Add =~ s/\s//g;
	$NTP_2_Add =~ s/[^0-9\.]//g;

my $Block_Edit = $CGI->param("Block_Edit");
my $Block_Name_Edit = $CGI->param("Block_Name_Edit");
my $Block_Description_Edit = $CGI->param("Block_Description_Edit");
my $Block_Network_Edit = $CGI->param("Block_Network_Edit");
	$Block_Network_Edit =~ s/\s//g;
	$Block_Network_Edit =~ s/[^0-9\.]//g;
my $Block_CIDR_Edit = $CGI->param("Block_CIDR_Edit");
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
my $DNS_1_Edit = $CGI->param("DNS_1_Edit");
	$DNS_1_Edit =~ s/\s//g;
	$DNS_1_Edit =~ s/[^0-9\.]//g;
my $DNS_2_Edit = $CGI->param("DNS_2_Edit");
	$DNS_2_Edit =~ s/\s//g;
	$DNS_2_Edit =~ s/[^0-9\.]//g;
my $NTP_1_Edit = $CGI->param("NTP_1_Edit");
	$NTP_1_Edit =~ s/\s//g;
	$NTP_1_Edit =~ s/[^0-9\.]//g;
my $NTP_2_Edit = $CGI->param("NTP_2_Edit");
	$NTP_2_Edit =~ s/\s//g;
	$NTP_2_Edit =~ s/[^0-9\.]//g;

my $Delete_Block = $CGI->param("Delete");
my $Delete_Block_Confirm = $CGI->param("Delete_Block_Confirm");
my $Block_Name_Delete = $CGI->param("Block_Name_Delete");

my $Enabled_Up_Arrow = '&#9650;';
my $Disabled_Up_Arrow = '&#9651;';
my $Enabled_Down_Arrow = '&#9660;';
my $Disabled_Down_Arrow = '&#9661;';
my ($Block_Name_Arrow, $Block_IP_Arrow, $Block_Used_Arrow, $Order_By_Block_Name, $Order_By_Block, $Order_By_Percent_Used);
my $Order_By_SQL;
my $Order_By = $CGI->param("Order_By");
	if ($Order_By eq 'Block-Name-ASC') {
		$Order_By_SQL = "`ip_block_name` ASC";
		$Block_Name_Arrow = $Enabled_Up_Arrow;
		$Block_IP_Arrow = $Disabled_Up_Arrow;
		$Block_Used_Arrow = $Disabled_Up_Arrow;
		$Order_By_Block_Name = 'Block-Name-DESC';
		$Order_By_Block = 'IP-ASC';
		$Order_By_Percent_Used = 'Used-ASC';
	}
	elsif ($Order_By eq 'Block-Name-DESC') {
		$Order_By_SQL = "`ip_block_name` DESC";
		$Block_Name_Arrow = $Enabled_Down_Arrow;
		$Block_IP_Arrow = $Disabled_Up_Arrow;
		$Block_Used_Arrow = $Disabled_Up_Arrow;
		$Order_By_Block_Name = 'Block-Name-ASC';
		$Order_By_Block = 'IP-ASC';
		$Order_By_Percent_Used = 'Used-ASC';
	}
	elsif ($Order_By eq 'IP-ASC') {
		$Order_By_SQL = "SUBSTRING_INDEX(`ip_block`,'.',1)+0 ASC,
			SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-3),'.',1)+0 ASC,
			SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-2),'.',1)+0 ASC,
			SUBSTRING_INDEX(`ip_block`,'.',-1)+0 ASC";
		$Block_Name_Arrow = $Disabled_Up_Arrow;
		$Block_IP_Arrow = $Enabled_Up_Arrow;
		$Block_Used_Arrow = $Disabled_Up_Arrow;
		$Order_By_Block_Name = 'Block-Name-ASC';
		$Order_By_Block = 'IP-DESC';
		$Order_By_Percent_Used = 'Used-ASC';
	}
	elsif ($Order_By eq 'IP-DESC') {
		$Order_By_SQL = "SUBSTRING_INDEX(`ip_block`,'.',1)+0 DESC,
			SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-3),'.',1)+0 DESC,
			SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-2),'.',1)+0 DESC,
			SUBSTRING_INDEX(`ip_block`,'.',-1)+0 DESC";
		$Block_Name_Arrow = $Disabled_Up_Arrow;
		$Block_IP_Arrow = $Enabled_Down_Arrow;
		$Block_Used_Arrow = $Disabled_Up_Arrow;
		$Order_By_Block_Name = 'Block-Name-ASC';
		$Order_By_Block = 'IP-ASC';
		$Order_By_Percent_Used = 'Used-ASC';
	}
	elsif ($Order_By eq 'Used-ASC') {
		$Order_By_SQL = "`percent_used` + 0 ASC";
		$Block_Name_Arrow = $Disabled_Up_Arrow;
		$Block_IP_Arrow = $Disabled_Up_Arrow;
		$Block_Used_Arrow = $Enabled_Up_Arrow;
		$Order_By_Block_Name = 'Block-Name-ASC';
		$Order_By_Block = 'IP-ASC';
		$Order_By_Percent_Used = 'Used-DESC';
	}
	elsif ($Order_By eq 'Used-DESC') {
		$Order_By_SQL = "`percent_used` + 0 DESC";
		$Block_Name_Arrow = $Disabled_Up_Arrow;
		$Block_IP_Arrow = $Disabled_Up_Arrow;
		$Block_Used_Arrow = $Enabled_Down_Arrow;
		$Order_By_Block_Name = 'Block-Name-ASC';
		$Order_By_Block = 'IP-ASC';
		$Order_By_Percent_Used = 'Used-ASC';
	}
	else {
		$Order_By_SQL = "`ip_block_name` ASC";
		$Block_Name_Arrow = $Enabled_Up_Arrow;
		$Block_IP_Arrow = $Disabled_Up_Arrow;
		$Block_Used_Arrow = $Disabled_Up_Arrow;
		$Order_By_Block_Name = 'Block-Name-DESC';
		$Order_By_Block = 'IP-ASC';
		$Order_By_Percent_Used = 'Used-ASC';
	}

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
	$Session->flush();
	print "Location: /index.cgi\n\n";
	exit(0);
}

if ($Add_Block) {
	require $Header;
	&html_output;
	require $Footer;
	&html_add_block;
}
elsif ($Block_Network_Add) {
	my $Block_ID = &add_block;
	my $Message_Green="$Block_Name_Add ($Block_Network_Add$Block_CIDR_Add) added successfully as ID $Block_ID";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /IP/ipv4-blocks.cgi\n\n";
	exit(0);
}
elsif ($Edit_Block) {
	require $Header;
	&html_output;
	require $Footer;
	&html_edit_block;
}
elsif ($Block_Edit && $Block_Network_Edit) {
	&edit_block;
	my $Message_Green="$Block_Name_Edit ($Block_Network_Edit) edited successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /IP/ipv4-blocks.cgi\n\n";
	exit(0);
}
elsif ($Delete_Block) {
	require $Header;
	&html_output;
	require $Footer;
	&html_delete_block;
}
elsif ($Delete_Block_Confirm) {
	&delete_block;
	my $Message_Green="$Block_Name_Delete deleted successfully";
	$Session->param('Message_Green', $Message_Green);
	$Session->flush();
	print "Location: /IP/ipv4-blocks.cgi\n\n";
	exit(0);
}
elsif ($Query_Block) {
	require $Header;
	&html_output;
	require $Footer;
	&html_query_block($Query_Block);
}
else {
	require $Header;
	&html_output;
	require $Footer;
}


sub html_add_block {

print <<ENDHTML;

<div id="wide-popup-box">
<a href="/IP/ipv4-blocks.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Add New IPv4 Block</h3>

<form action='/IP/ipv4-blocks.cgi' method='post' >

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
		<td style="text-align: right;">Block Network:</td>
		<td><input type='text' name='Block_Network_Add' style="width:100%" maxlength='15' placeholder="192.168.0.0" required></td>
		<td colspan="2" style="text-align: left;">
			<select name='Block_CIDR_Add'>
				<option value='/30'>/30</option>
				<option value='/29'>/29</option>
				<option value='/28'>/28</option>
				<option value='/27'>/27</option>
				<option value='/26'>/26</option>
				<option value='/25'>/25</option>
				<option value='/24' selected>/24</option>
				<option value='/23'>/23</option>
				<option value='/22'>/22</option>
				<option value='/21'>/21</option>
				<option value='/20'>/20</option>
				<option value='/19'>/19</option>
				<option value='/18'>/18</option>
				<option value='/17'>/17</option>
				<option value='/16'>/16</option>
				<option value='/15'>/15</option>
				<option value='/14'>/14</option>
				<option value='/13'>/13</option>
				<option value='/12'>/12</option>
				<option value='/11'>/11</option>
				<option value='/10'>/10</option>
				<option value='/9'>/9</option>
				<option value='/8'>/8</option>
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Block Gateway:</td>
		<td><input type='text' name='Gateway_Add' style="width:100%" maxlength='15' placeholder="192.168.0.1"></td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td colspan="4"><hr style="width: 50%;"/></td>
	</tr>
	<tr>
		<td style="text-align: right;">Range for Use:</td>
		<td><input type='text' name='Range_For_Use_Begin_Add' style="width:100%" maxlength='15' placeholder="192.168.0.10"></td>
		<td>&nbsp;&nbsp;to&nbsp;&nbsp;</td>
		<td><input type='text' name='Range_For_Use_End_Add' style="width:100%" maxlength='15' placeholder="192.168.7.200"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Range for Use Subnet:</td>
		<td><input type='text' name='Range_For_Use_Subnet_Add' style="width:100%" maxlength='15' placeholder="255.255.248.0"></td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td colspan="4"><hr style="width: 50%;"/></td>
	</tr>
	<tr>
		<td style="text-align: right;">Nearest DNS Server:</td>
		<td><input type='text' name='DNS_1_Add' style="width:100%" maxlength='15' placeholder="192.168.0.2"></td>
		<td>&nbsp;DNS2:</td>
		<td><input type='text' name='DNS_2_Add' style="width:100%" maxlength='15' placeholder="192.168.0.3"></td>
	</tr>
	<tr>
		<td style="text-align: right;"> Nearest NTP Server:</td>
		<td><input type='text' name='NTP_1_Add' style="width:100%" maxlength='15' placeholder="192.168.0.4"></td>
		<td>&nbsp;NTP2:</td>
		<td><input type='text' name='NTP_2_Add' style="width:100%" maxlength='15' placeholder="192.168.0.5"></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Block Names must be unique.</li>
<li>Range data, Gateway, DNS and NTP records are optional, although defining the correct Gateway, DNS and NTP servers 
for the block will be useful for later automation.</li>
<li>By setting a Range for Use, you can disclude IP addresses in a block from being allocated. For example, you may
wish to reserve the first 10 IP addresses in a block to reserve the block's network address (the first IP address in the 
block) and to manually allocate the first parts of a block to network devices, or you may wish to reserve the broadcast 
address (the last IP address in a block). It really depends on what you intend to do with the block - allocate 
individual addresses from the block, or breaking the block down into smaller blocks with individual network and 
broadcast addresses.</li>
</ul>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Add Block'></div>

</form>

ENDHTML

} #sub html_add_block

sub add_block {

	### Existing Block Check
	my $Existing_Block_Check = $DB_Connection->prepare("SELECT `id`, `ip_block_name`
		FROM `ipv4_blocks`
		WHERE `ip_block_name` = ?");
		$Existing_Block_Check->execute($Block_Name_Add);
		my $Existing_Blocks = $Existing_Block_Check->rows();

	if ($Existing_Blocks > 0)  {
		my $Existing_ID;
		my $Existing_Block_Name;
		while ( my @Select_Blocks = $Existing_Block_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Blocks[0];
			$Existing_Block_Name = $Select_Blocks[1];
		}
		my $Message_Red="Block Name: $Existing_Block_Name already exists as ID: $Existing_ID";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/ipv4-blocks.cgi\n\n";
		exit(0);
	}
	### / Existing Block Check

	my $Block_Insert = $DB_Connection->prepare("INSERT INTO `ipv4_blocks` (
		`ip_block_name`,
		`ip_block_description`,
		`ip_block`,
		`gateway`,
		`range_for_use`,
		`range_for_use_subnet`,
		`dns1`,
		`dns2`,
		`ntp1`,
		`ntp2`,
		`modified_by`
	)
	VALUES (
		?, ?, ?, ?,
		?, ?, ?, ?,
		?, ?, ?
	)");

	my $Range_For_Use_Add;
	if ($Range_For_Use_Begin_Add && $Range_For_Use_End_Add) {
		$Range_For_Use_Add = $Range_For_Use_Begin_Add . " - " . $Range_For_Use_End_Add;
	}

	$Block_Insert->execute($Block_Name_Add, $Block_Description_Add, "$Block_Network_Add$Block_CIDR_Add", $Gateway_Add, 
		$Range_For_Use_Add, $Range_For_Use_Subnet_Add, $DNS_1_Add, $DNS_2_Add, 
		$NTP_1_Add, $NTP_2_Add, $User_Name);

	my $Block_Insert_ID = $DB_Connection->{mysql_insertid};

	my $Audit_Log_Submission = Audit_Log_Submission();
	
	$Audit_Log_Submission->execute("IP", "Add", "$User_Name added $Block_Name_Add ($Block_Network_Add$Block_CIDR_Add). The system assigned it IPv4 Block ID $Block_Insert_ID.", $User_Name);

	return ($Block_Insert_ID);
	
} # sub add_block

sub html_edit_block {

	my $IPv4_Block_Query = $DB_Connection->prepare("SELECT `ip_block_name`, `ip_block_description`, `ip_block`, `gateway`, `range_for_use`, `range_for_use_subnet`, `dns1`, `dns2`, `ntp1`, `ntp2`
	FROM `ipv4_blocks`
	WHERE `id` LIKE ?");

	$IPv4_Block_Query->execute($Edit_Block);
	
	my $Row_Count=1;
	while ( my @IPv4_Block_Query_Output = $IPv4_Block_Query->fetchrow_array() )
	{

		my $Block_Name = $IPv4_Block_Query_Output[0];
		my $Block_Description = $IPv4_Block_Query_Output[1];
		my $Block_Extract = $IPv4_Block_Query_Output[2];
			my $Block_Network = $Block_Extract;
				$Block_Network =~ s/(.*)\/.*/$1/;
			my $Block_CIDR = $Block_Extract;
				$Block_CIDR =~ s/.*(\/.*)/$1/;
		my $Gateway_Extract = $IPv4_Block_Query_Output[3];
		my $Range_For_Use = $IPv4_Block_Query_Output[4];
			my $Range_For_Use_Begin = $Range_For_Use;
				$Range_For_Use_Begin =~ s/(.*)\s-\s.*/$1/;
			my $Range_For_Use_End = $Range_For_Use;
				$Range_For_Use_End =~ s/.*\s-\s(.*)/$1/;
		my $Range_For_Use_Subnet = $IPv4_Block_Query_Output[5];
		my $DNS1 = $IPv4_Block_Query_Output[6];
		my $DNS2 = $IPv4_Block_Query_Output[7];
		my $NTP1 = $IPv4_Block_Query_Output[8];
		my $NTP2 = $IPv4_Block_Query_Output[9];


print <<ENDHTML;

<div id="wide-popup-box">
<a href="/IP/ipv4-blocks.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit IPv4 Block ID $Edit_Block</h3>

<form action='/IP/ipv4-blocks.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Block Name:</td>
		<td colspan="3"><input type='text' name='Block_Name_Edit' value="$Block_Name" style="width:100%" maxlength='128' placeholder="$Block_Name" required autofocus></td>
	</tr>
	<tr>
		<td style="text-align: right;">Block Description:</td>
		<td colspan="3"><input type='text' name='Block_Description_Edit' value="$Block_Description" style="width:100%" maxlength='128' placeholder="$Block_Description"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Block Network:</td>
		<td><input type='text' name='Block_Network_Edit' value="$Block_Network" style="width:100%" maxlength='15' placeholder="$Block_Network" required></td>
		<td colspan="2" style="text-align: left;">
			<select name='Block_CIDR_Edit'>
ENDHTML

if ($Block_CIDR eq '/30') {print "<option style='background-color: #009400;' value='/30' selected>/30</option>";} else {print "<option value='/30'>/30</option>";}
if ($Block_CIDR eq '/29') {print "<option style='background-color: #009400;' value='/29' selected>/29</option>";} else {print "<option value='/29'>/29</option>";}
if ($Block_CIDR eq '/28') {print "<option style='background-color: #009400;' value='/28' selected>/28</option>";} else {print "<option value='/28'>/28</option>";}
if ($Block_CIDR eq '/27') {print "<option style='background-color: #009400;' value='/27' selected>/27</option>";} else {print "<option value='/27'>/27</option>";}
if ($Block_CIDR eq '/26') {print "<option style='background-color: #009400;' value='/26' selected>/26</option>";} else {print "<option value='/26'>/26</option>";}
if ($Block_CIDR eq '/25') {print "<option style='background-color: #009400;' value='/25' selected>/25</option>";} else {print "<option value='/25'>/25</option>";}
if ($Block_CIDR eq '/24') {print "<option style='background-color: #009400;' value='/24' selected>/24</option>";} else {print "<option value='/24'>/24</option>";}
if ($Block_CIDR eq '/23') {print "<option style='background-color: #009400;' value='/23' selected>/23</option>";} else {print "<option value='/23'>/23</option>";}
if ($Block_CIDR eq '/22') {print "<option style='background-color: #009400;' value='/22' selected>/22</option>";} else {print "<option value='/22'>/22</option>";}
if ($Block_CIDR eq '/21') {print "<option style='background-color: #009400;' value='/21' selected>/21</option>";} else {print "<option value='/21'>/21</option>";}
if ($Block_CIDR eq '/20') {print "<option style='background-color: #009400;' value='/20' selected>/20</option>";} else {print "<option value='/20'>/20</option>";}
if ($Block_CIDR eq '/19') {print "<option style='background-color: #009400;' value='/19' selected>/19</option>";} else {print "<option value='/19'>/19</option>";}
if ($Block_CIDR eq '/18') {print "<option style='background-color: #009400;' value='/18' selected>/18</option>";} else {print "<option value='/18'>/18</option>";}
if ($Block_CIDR eq '/17') {print "<option style='background-color: #009400;' value='/17' selected>/17</option>";} else {print "<option value='/17'>/17</option>";}
if ($Block_CIDR eq '/16') {print "<option style='background-color: #009400;' value='/16' selected>/16</option>";} else {print "<option value='/16'>/16</option>";}
if ($Block_CIDR eq '/15') {print "<option style='background-color: #009400;' value='/15' selected>/15</option>";} else {print "<option value='/15'>/15</option>";}
if ($Block_CIDR eq '/14') {print "<option style='background-color: #009400;' value='/14' selected>/14</option>";} else {print "<option value='/14'>/14</option>";}
if ($Block_CIDR eq '/13') {print "<option style='background-color: #009400;' value='/13' selected>/13</option>";} else {print "<option value='/13'>/13</option>";}
if ($Block_CIDR eq '/12') {print "<option style='background-color: #009400;' value='/12' selected>/12</option>";} else {print "<option value='/12'>/12</option>";}
if ($Block_CIDR eq '/11') {print "<option style='background-color: #009400;' value='/11' selected>/11</option>";} else {print "<option value='/11'>/11</option>";}
if ($Block_CIDR eq '/10') {print "<option style='background-color: #009400;' value='/10' selected>/10</option>";} else {print "<option value='/10'>/10</option>";}
if ($Block_CIDR eq '/9') {print "<option style='background-color: #009400;' value='/9' selected>/9</option>";} else {print "<option value='/9'>/9</option>";}
if ($Block_CIDR eq '/8') {print "<option style='background-color: #009400;' value='/8' selected>/8</option>";} else {print "<option value='/8'>/8</option>";}

print <<ENDHTML
			</select>
		</td>
	</tr>
	<tr>
		<td style="text-align: right;">Block Gateway:</td>
		<td><input type='text' name='Gateway_Edit' value="$Gateway_Extract" style="width:100%" maxlength='15' placeholder="$Gateway_Extract"></td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td colspan="4"><hr style="width: 50%;"/></td>
	</tr>
	<tr>
		<td style="text-align: right;">Range for Use:</td>
		<td><input type='text' name='Range_For_Use_Begin_Edit' value="$Range_For_Use_Begin" style="width:100%" maxlength='15' placeholder="$Range_For_Use_Begin"></td>
		<td>&nbsp;&nbsp;to&nbsp;&nbsp;</td>
		<td><input type='text' name='Range_For_Use_End_Edit' value="$Range_For_Use_End" style="width:100%" maxlength='15' placeholder="$Range_For_Use_End"></td>
	</tr>
	<tr>
		<td style="text-align: right;">Range for Use Subnet:</td>
		<td><input type='text' name='Range_For_Use_Subnet_Edit' value="$Range_For_Use_Subnet" style="width:100%" maxlength='15' placeholder="$Range_For_Use_Subnet"></td>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td colspan="4"><hr style="width: 50%;"/></td>
	</tr>
	<tr>
		<td style="text-align: right;">Nearest DNS Server:</td>
		<td><input type='text' name='DNS_1_Edit' value="$DNS1" style="width:100%" maxlength='15' placeholder="$DNS1"></td>
		<td>&nbsp;DNS2:</td>
		<td><input type='text' name='DNS_2_Edit' value="$DNS2" style="width:100%" maxlength='15' placeholder="$DNS2"></td>
	</tr>
	<tr>
		<td style="text-align: right;"> Nearest NTP Server:</td>
		<td><input type='text' name='NTP_1_Edit' value="$NTP1" style="width:100%" maxlength='15' placeholder="$NTP1"></td>
		<td>&nbsp;NTP2:</td>
		<td><input type='text' name='NTP_2_Edit' value="$NTP2" style="width:100%" maxlength='15' placeholder="$NTP2"></td>
	</tr>
</table>

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
<li>Block Names must be unique.</li>
<li>Range data, Gateway, DNS and NTP records are optional, although defining the correct Gateway, DNS and NTP servers 
for the block will be useful for later automation.</li>
<li>By setting a Range for Use, you can disclude IP addresses in a block from being allocated. For example, you may
wish to reserve the first 10 IP addresses in a block to reserve the block's network address (the first IP address in the 
block) and to manually allocate the first parts of a block to network devices, or you may wish to reserve the broadcast 
address (the last IP address in a block). It really depends on what you intend to do with the block - allocate 
individual addresses from the block, or breaking the block down into smaller blocks with individual network and 
broadcast addresses.</li>
</ul>

<input type='hidden' name='Block_Edit' value="$Edit_Block">

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Block'></div>

</form>

ENDHTML

	}

} # sub html_edit_block

sub edit_block {

	### Existing Block Check
	my $Existing_Block_Check = $DB_Connection->prepare("SELECT `id`, `ip_block_name`, `ip_block`
		FROM `ipv4_blocks`
		WHERE `ip_block_name` = ?
		AND `id` != ?");
		$Existing_Block_Check->execute($Block_Name_Edit, $Block_Edit);
		my $Existing_Blocks = $Existing_Block_Check->rows();

	if ($Existing_Blocks > 0)  {
		my $Existing_ID;
		my $Existing_Block_Name;
		my $Existing_Block_IP;
		while ( my @Select_Blocks = $Existing_Block_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Blocks[0];
			$Existing_Block_Name = $Select_Blocks[1];
			$Existing_Block_IP = $Select_Blocks[2];
		}
		my $Message_Red="Block Name: $Existing_Block_Name already exists as ID: $Existing_ID, Block: $Existing_Block_IP";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/ipv4-blocks.cgi\n\n";
		exit(0);
	}
	### / Existing Block Check

	my $Range_For_Use;
	if ($Range_For_Use_Begin_Edit && $Range_For_Use_End_Edit) {
		$Range_For_Use = $Range_For_Use_Begin_Edit . " - " . $Range_For_Use_End_Edit;
	}

	my $Update_Block = $DB_Connection->prepare("UPDATE `ipv4_blocks` SET
		`ip_block_name` = ?,
		`ip_block_description` = ?,
		`ip_block` = ?,
		`gateway` = ?,
		`range_for_use` = ?,
		`range_for_use_subnet` = ?,
		`dns1` = ?,
		`dns2` = ?,
		`ntp1` = ?,
		`ntp2` = ?,
		`modified_by` = ?
		WHERE `id` = ?");
	
	$Update_Block->execute($Block_Name_Edit, $Block_Description_Edit, "$Block_Network_Edit$Block_CIDR_Edit", 
		$Gateway_Edit, $Range_For_Use, $Range_For_Use_Subnet_Edit, $DNS_1_Edit, $DNS_2_Edit, $NTP_1_Edit, 
		$NTP_2_Edit, $User_Name, $Block_Edit);

	my $Audit_Log_Submission = Audit_Log_Submission();
	
	$Audit_Log_Submission->execute("IP", "Modify", "$User_Name modified $Block_Name_Edit ($Block_Network_Edit$Block_CIDR_Edit).", $User_Name);

} # sub edit_block

sub html_delete_block {

	my $Select_Block = $DB_Connection->prepare("SELECT `ip_block_name`, `ip_block`
	FROM `ipv4_blocks`
	WHERE `id` = ?");

	$Select_Block->execute($Delete_Block);
	
	while ( my @DB_Block = $Select_Block->fetchrow_array() )
	{
	
		my $Block_Name_Extract = $DB_Block[0];
		my $Block_Extract = $DB_Block[1];

print <<ENDHTML;
<div id="small-popup-box">
<a href="/IP/ipv4-blocks.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete IPv4 Block</h3>

<form action='/IP/ipv4-blocks.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this block? Assignments made from this block will still exist.</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Block Name:</td>
		<td style="text-align: left; color: #00FF00;">$Block_Name_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Block:</td>
		<td style="text-align: left; color: #00FF00;">$Block_Extract</td>
	</tr>
</table>

<input type='hidden' name='Delete_Block_Confirm' value='$Delete_Block'>
<input type='hidden' name='Block_Name_Delete' value='$Block_Name_Extract'>


<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Block'></div>

</form>

ENDHTML

	}
} # sub html_delete_block

sub delete_block {

	# Audit Log
	my $Select_Blocks = $DB_Connection->prepare("SELECT `ip_block_name`, `ip_block`
		FROM `ipv4_blocks`
		WHERE `id` = ?");

	$Select_Blocks->execute($Delete_Block_Confirm);

	while (( my $Block_Name, my $IP ) = $Select_Blocks->fetchrow_array() )
	{
		my $DB_Connection = DB_Connection();
		my $Audit_Log_Submission = Audit_Log_Submission();
		$Audit_Log_Submission->execute("IP", "Delete", "$User_Name deleted $Block_Name (IPv4 Block ID $Delete_Block_Confirm).", $User_Name);
	}
	# / Audit Log

	my $Delete_Block = $DB_Connection->prepare("DELETE from `ipv4_blocks`
		WHERE `id` = ?");
	
	$Delete_Block->execute($Delete_Block_Confirm);

} # sub delete_block

sub html_query_block {

my ($Block) = @_;

my $Block_Query = new Net::IP::XS ($Block) || die (Net::IP::XS::Error);

	my ($Block_Prefix,$CIDR) = Net::IP::XS::ip_splitprefix($Block);
	my $Block_Version = $Block_Query->version();
	my $Block_Type = $Block_Query->iptype();
	my $Short_Format = $Block_Query->short();
	my $Block_Addresses = $Block_Query->size();
		my $Usable_Addresses = $Block_Addresses-2;
			if ($Usable_Addresses < 1) {$Usable_Addresses = 'N/A'}
	my $Decimal_Subnet = $Block_Query->mask();
	my $Range_Min = $Block_Query->ip();
	my $Range_Max = $Block_Query->last_ip();
	my $Reverse_IP = $Block_Query->reverse_ip();
	my $Hex_IP = $Block_Query->hexip();
	my $Hex_Mask = $Block_Query->hexmask();
	
	my $Usable_Range_Begin = $Block_Query->intip();
		$Usable_Range_Begin = $Usable_Range_Begin+1;
			my $Octet1 = ($Usable_Range_Begin/16777216)%256;
			my $Octet2 = ($Usable_Range_Begin/65536)%256;
			my $Octet3 = ($Usable_Range_Begin/256)%256;
			my $Octet4 = $Usable_Range_Begin%256;
			$Usable_Range_Begin = $Octet1 . "." . $Octet2 . "." . $Octet3 . "." . $Octet4;
	
	my $Usable_Range_End = $Block_Query->last_ip();
	my $Block_Query_End = new Net::IP::XS ($Usable_Range_End) || die (Net::IP::XS::Error);
		$Usable_Range_End = $Block_Query_End->intip();
		$Usable_Range_End = $Usable_Range_End-1;
			$Octet1 = ($Usable_Range_End/16777216)%256;
			$Octet2 = ($Usable_Range_End/65536)%256;
			$Octet3 = ($Usable_Range_End/256)%256;
			$Octet4 = $Usable_Range_End%256;
			$Usable_Range_End = $Octet1 . "." . $Octet2 . "." . $Octet3 . "." . $Octet4;

print <<ENDHTML;
<body>

<div id="small-popup-box">
<a href="ipv4-blocks.cgi">
<div id="blockclosebutton"> 
</div>
</a>
<h3>Block Query</h3>

<p>The data here relates to the overall block, and does not consider the enforced Range for Use, if applicable. 
During assignment, the Range for Use is enforced. The gateway address is already discounted from Usable Addresses.</p>

<table align="center" style="font-size: 12px;">
	<tr>
		<td style="text-align: right;">Queried Block</td>
		<td style="text-align: left; color: #00FF00;">$Block</td>
	</tr>
	<tr>
		<td style="text-align: right;">Block Version</td>
		<td style="text-align: left; color: #00FF00;">IPv$Block_Version</td>
	</tr>
	<tr>
		<td style="text-align: right;">Block Type</td>
		<td style="text-align: left; color: #00FF00;">$Block_Type</td>
	</tr>
	<tr>
		<td style="text-align: right;">Short Format</td>
		<td style="text-align: left; color: #00FF00;">$Short_Format/$CIDR</td>
	</tr>
	<tr>
		<td style="text-align: right;">Decimal Mask</td>
		<td style="text-align: left; color: #00FF00;">$Decimal_Subnet</td>
	</tr>
	<tr>
		<td style="text-align: right;">Network Address</td>
		<td style="text-align: left; color: #00FF00;">$Range_Min</td>
	</tr>
	<tr>
		<td style="text-align: right;">Broadcast Address</td>
		<td style="text-align: left; color: #00FF00;">$Range_Max</td>
	</tr>
	<tr>
		<td style="text-align: right;">Block Addresses</td>
		<td style="text-align: left; color: #00FF00;">$Block_Addresses</td>
	</tr>
	<tr>
		<td style="text-align: right;">Usable Addresses</td>
		<td style="text-align: left; color: #00FF00;">$Usable_Addresses</td>
	</tr>
	<tr>
		<td style="text-align: right;">Usable Range</td>
		<td style="text-align: left; color: #00FF00;">$Usable_Range_Begin to $Usable_Range_End</td>
	</tr>
	<tr>
		<td style="text-align: right;">Reverse</td>
		<td style="text-align: left; color: #00FF00;">$Reverse_IP</td>
	</tr>
	<tr>
		<td style="text-align: right;">Hex IP</td>
		<td style="text-align: left; color: #00FF00;">$Hex_IP</td>
	</tr>
	<tr>
		<td style="text-align: right;">Hex Mask</td>
		<td style="text-align: left; color: #00FF00;">$Hex_Mask</td>
	</tr>
</table>


</div>

ENDHTML

} # sub html_query_block

sub html_output {

my $Table = new HTML::Table(
	-cols=>14,
	-align=>'center',
	-border=>0,
	-rules=>'cols',
	-evenrowclass=>'tbeven',
	-oddrowclass=>'tbodd',
	-width=>'100%',
	-spacing=>0,
	-padding=>1
);
$Table->addRow ( "ID", 
"Block Name <a href='/IP/ipv4-blocks.cgi?Order_By=$Order_By_Block_Name&Filter=$Filter'>$Block_Name_Arrow</a>", 
"Block Description", 
"IPv4 Block <a href='/IP/ipv4-blocks.cgi?Order_By=$Order_By_Block&Filter=$Filter'>$Block_IP_Arrow</a>", 
"Gateway", "Range for Use",	"Range for Use Subnet", "DNS Servers", "NTP Servers", 
"Used <a href='/IP/ipv4-blocks.cgi?Order_By=$Order_By_Percent_Used&Filter=$Filter'>$Block_Used_Arrow</a>", 
"Last Modified", "Modified By", "Edit", "Delete" );
$Table->setRowClass (1, 'tbrow1');

my $IPv4_Block_Query = $DB_Connection->prepare("SELECT `id`, `ip_block_name`, `ip_block_description`, `ip_block`, 
`gateway`, `range_for_use`, `range_for_use_subnet`, `dns1`, `dns2`, `ntp1`, `ntp2`, `percent_used`, `last_modified`, `modified_by`
FROM `ipv4_blocks`
WHERE `ip_block` LIKE ?
	OR `ip_block_name` LIKE ?
	OR `ip_block_description` LIKE ?
	OR `range_for_use` LIKE ?
	OR `range_for_use_subnet` LIKE ?
	OR `percent_used` LIKE ?
	OR `dns1` LIKE ?
	OR `dns2` LIKE ?
	OR `ntp1` LIKE ?
	OR `ntp2` LIKE ?
ORDER BY
	$Order_By_SQL
LIMIT ?, ?");
$IPv4_Block_Query->execute("%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", 
	"%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", "%$Filter%", 0, $Rows_Returned);

my $Rows = $IPv4_Block_Query->rows();
my $IP_Block_Total_Count = $DB_Connection->prepare("SELECT `id` FROM `ipv4_blocks`");
	$IP_Block_Total_Count->execute( );
	my $Total_Rows = $IP_Block_Total_Count->rows();

my $Row_Count=1;
while ( my @IPv4_Block_Query_Output = $IPv4_Block_Query->fetchrow_array() )
{

	$Row_Count++;
	
	my $ID = $IPv4_Block_Query_Output[0];
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
	my $DNS1 = $IPv4_Block_Query_Output[7];
		$DNS1 =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $DNS2 = $IPv4_Block_Query_Output[8];
		$DNS2 =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $NTP1 = $IPv4_Block_Query_Output[9];
		$NTP1 =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $NTP2 = $IPv4_Block_Query_Output[10];
		$NTP2 =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Percent_Used = $IPv4_Block_Query_Output[11];
		$Percent_Used = sprintf("%.2f", $Percent_Used);
		$Percent_Used =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Last_Modified = $IPv4_Block_Query_Output[12];
	my $Modified_By = $IPv4_Block_Query_Output[13];
	
	$Table->addRow( $ID, $Block_Name, $Block_Description, 
		"<a href='/IP/ipv4-blocks.cgi?Query_Block=$Block_Extract'>$Block</a>", 
		$Gateway_Extract, $Range_For_Use, $Range_For_Use_Subnet, 
		"$DNS1<br />$DNS2", "$NTP1<br />$NTP2", $Percent_Used."%", $Last_Modified, $Modified_By,
		"<a href='/IP/ipv4-blocks.cgi?Edit_Block=$ID'><img src=\"/Resources/Images/edit.png\" alt=\"Edit Block $Block_Extract\" ></a>",
		"<a href='/IP/ipv4-blocks.cgi?Delete=$ID'><img src=\"/Resources/Images/delete.png\" alt=\"Delete Block $Block_Extract\" ></a>");
	
	if ($Percent_Used <= 50) {
		$Table->setCellClass ($Row_Count, 10, 'tbrowgreen');
	}
	elsif ($Percent_Used <= 75) {
		$Table->setCellClass ($Row_Count, 10, 'tbrowyellow');
	}
	elsif ($Percent_Used <= 90) {
		$Table->setCellClass ($Row_Count, 10, 'tbrowdarkorange');
	}
	elsif ($Percent_Used > 90) {
		$Table->setCellClass ($Row_Count, 10, 'tbrowred');
	}
}

	$Table->setColWidth(1, '1px');
	$Table->setColWidth(11, '110px');
	$Table->setColWidth(12, '110px');
	$Table->setColWidth(13, '1px');
	$Table->setColWidth(14, '1px');
	$Table->setColAlign(1, 'center');
	for (4 .. 14) {
		$Table->setColAlign($_, 'center');
	}

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
						<input type='hidden' name='Order_By' value='$Order_By'>
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

						my $Block_List_Query = $DB_Connection->prepare("SELECT `id`, `ip_block_name`, `ip_block`
						FROM `ipv4_blocks`
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


