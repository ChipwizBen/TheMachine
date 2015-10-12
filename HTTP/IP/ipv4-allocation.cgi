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

my $User_Name = $Session->param("User_Name"); #Accessing User_Name session var

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Location_Input = $CGI->param("Location_Input");
my $CIDR_Input = $CGI->param("CIDR_Input");
my $Reset = $CGI->param("Reset");
my $Manual_Override = $CGI->param("Manual_Override");

if ($Reset eq '1') {
	$Location_Input='';
	$Session->param('Location_Input', $Location_Input); #Posting Location_Input session var
	$CIDR_Input='';
	$Session->param('CIDR_Input', $CIDR_Input); #Posting CIDR_Input session var
	print "Location: /IP/ipv4-allocation.cgi\n\n";
	exit(0);
}
elsif ($Location_Input) {
	my ($IP_Block_Name, $Final_Allocated_IP) = &allocation;
	require $Header;
	&html_output ($IP_Block_Name, $Final_Allocated_IP);
}
else {
	if ($Manual_Override eq '1') {
		require $Header;
		&html_output_manual;
	}
	else {
		require $Header;
		&html_output;
	}
}


sub allocation {

	my $Discover_Allocatable_Blocks = $DB_IP_Allocation->prepare("SELECT `ip_block_name`, `ip_block`, `ip_block_description`, `range_for_use`, `range_for_use_subnet`
	FROM `ipv4_address_blocks`
	WHERE `id` = ?");

	$Discover_Allocatable_Blocks->execute($Location_Input);

	while ( my @DB_Output = $Discover_Allocatable_Blocks->fetchrow_array() ) {
		my $IP_Block_Name = $DB_Output[0];
		my $IP_Block = $DB_Output[1];
		my $IP_Block_Description = $DB_Output[2];
		my $Range_For_Use = $DB_Output[3];
		my $Range_For_Use_Subnet = $DB_Output[4];

		if ($Range_For_Use ne '') {
			$IP_Block=$Range_For_Use;
		}

		my $IP_Allocation_Limit_Collection = new Net::IP::XS ($IP_Block) or die(&allocation_error(Net::IP::XS::Error, $IP_Block));
			my $IP_Block_Limit=$IP_Allocation_Limit_Collection->last_ip();
				my $IP_Allocation_Limit_Execution = new Net::IP::XS ($IP_Block_Limit) or die(&allocation_error(Net::IP::XS::Error, $IP_Block_Limit));
					my $IP_Block_Limit_Integer = $IP_Allocation_Limit_Execution->intip();

		my $Final_Block;
		my $Rows=1;
		my $Counter=0;
		LOOP: while ($Counter != $Rows) {
			
			$IP_Block =~ s/\/..//;
			my $IP_Block_Truncate = $IP_Block;
				$IP_Block_Truncate =~ s/^(\d*\.\d*\.).*$/$1/;

			my $IP_Block_Check_Cycle = $DB_IP_Allocation->prepare("SELECT `network_block`
				FROM `ipv4_allocations`
				WHERE `network_block` LIKE ?
				ORDER BY `network_block` ASC");
			$IP_Block_Check_Cycle->execute("$IP_Block_Truncate%");
			$Rows = $IP_Block_Check_Cycle->rows();

			while ( my @Block_DB_Output = $IP_Block_Check_Cycle->fetchrow_array() )
			{

				my $Network_Block = $Block_DB_Output[0];

				my $IP_Block_For_Allocation="$IP_Block$CIDR_Input";

				my $IP_Allocation = new Net::IP::XS ($IP_Block_For_Allocation) or die(&allocation_error(Net::IP::XS::Error, $IP_Block_For_Allocation));
				my $IP_Allocation_Check = new Net::IP::XS($Network_Block) or die(&allocation_error(Net::IP::XS::Error, $Network_Block));

				my $Overlap_Check = $IP_Allocation->overlaps($IP_Allocation_Check);

				if (not defined($Overlap_Check))
				{
					my $Message_Red="Problem with IP range $Overlap_Check, it is not properly defined.";
					$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
					print "Location: /IP/ipv4-allocation.cgi?Reset=1\n\n";
					exit(0);
				}
				elsif ( $Overlap_Check == $IP_IDENTICAL )
				{
					$Counter='0';
					$Final_Block='';
					$IP_Block = &increase_octets($IP_Block);
					goto LOOP;
				}
				elsif ( $Overlap_Check == $IP_A_IN_B_OVERLAP )
				{
					$Counter='0';
					$Final_Block='';
					$IP_Block = &increase_octets($IP_Block);
					goto LOOP;
				}
				elsif ( $Overlap_Check == $IP_B_IN_A_OVERLAP )
				{			
					$Counter='0';
					$Final_Block='';
					$IP_Block = &increase_octets($IP_Block);
					goto LOOP;
				}
				elsif ( $Overlap_Check == $IP_PARTIAL_OVERLAP )
				{
					$Counter='0';
					$Final_Block='';
					$IP_Block = &increase_octets($IP_Block);
					goto LOOP;
				}
				elsif ( $Overlap_Check == $IP_NO_OVERLAP )
				{
					$Counter++;
					$Final_Block=$IP_Block_For_Allocation;
				}
			}
		};


		my $Final_IP_Allocation = new Net::IP::XS ($Final_Block) or die(&allocation_error(Net::IP::XS::Error, $Final_Block));
			my $IP_Block_Limit_Final=$Final_IP_Allocation->last_ip();
				my $IP_Allocation_Limit_Final = new Net::IP::XS ($IP_Block_Limit_Final) or die(&allocation_error(Net::IP::XS::Error, $IP_Block_Limit_Final));
					my $IP_Block_Limit_Integer_Final = $IP_Allocation_Limit_Final->intip();

		if ($IP_Block_Limit_Integer < $IP_Block_Limit_Integer_Final) {
			my $Message_Red="There are no more available blocks in $IP_Block for a $CIDR_Input notation. Either reduce the block size or use a different block";
			$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
			print "Location: /IP/ipv4-allocation.cgi?Reset=1\n\n";
			exit(0);
		}

		my $Usable_Addresses=$Final_IP_Allocation->size();
			$Usable_Addresses=$Usable_Addresses-2;
		my $Block_Subnet = $Final_IP_Allocation->mask();
		my  $Range_Min=$Final_IP_Allocation->ip();
		my $Range_Max=$Final_IP_Allocation->last_ip();

		if ($Range_For_Use) {
			$Block_Subnet = $Range_For_Use_Subnet;
		}

		my @Final_Allocation = ($IP_Block_Name, $Final_Block);
		return @Final_Allocation;
		
		#$Session->param('IP_Block', $IP_Block); #Posting IP_Block session var
		#$Session->param('IP_Block_Name', $IP_Block_Name); #Posting IP_Block_Description session var
		#$Session->param('Final_Block', $Final_Block); #Posting IP_Block session var
		#$Session->param('Block_Subnet', $Block_Subnet); #Posting Block_Subnet session var

	}

} # sub allocation

sub increase_octets {

my ($IP_Block) = @_;

my $Add_CIDR_Loop;
if ($CIDR_Input eq '/32') {$Add_CIDR_Loop = 1};
if ($CIDR_Input eq '/31') {$Add_CIDR_Loop = 2};
if ($CIDR_Input eq '/30') {$Add_CIDR_Loop = 4};
if ($CIDR_Input eq '/29') {$Add_CIDR_Loop = 8};
if ($CIDR_Input eq '/28') {$Add_CIDR_Loop = 16};
if ($CIDR_Input eq '/27') {$Add_CIDR_Loop = 32};
if ($CIDR_Input eq '/26') {$Add_CIDR_Loop = 64};
if ($CIDR_Input eq '/25') {$Add_CIDR_Loop = 128};
if ($CIDR_Input eq '/24') {$Add_CIDR_Loop = 256};

my $IP_Allocation = new Net::IP::XS ($IP_Block) or die(&allocation_error(Net::IP::XS::Error, $IP_Block));

	$IP_Block = $IP_Allocation->intip();
	$IP_Block = $IP_Block+$Add_CIDR_Loop;
	
		my $Octet1=($IP_Block/16777216)%256;
		my $Octet2=($IP_Block/65536)%256;
		my $Octet3=($IP_Block/256)%256;
		my $Octet4=$IP_Block%256;
		$IP_Block = $Octet1 . "." . $Octet2 . "." . $Octet3 . "." . $Octet4;

	return $IP_Block;

} # sub increase_octets

sub allocation_error {

my ($Allocation_Range_Error, $IP_Block) = @_;

	my $Message_Red="CRITICAL ERROR: You specified a CIDR that spills over the edge of the boundary<br/>
	Error Details: $Allocation_Range_Error<br/>
	--------------- You must select a CIDR that fits within the boundaries of $IP_Block ---------------";
	$Session->param('Message_Red', $Message_Red); #Posting Message_Red session var
	print "Location: /IP/ipv4-allocation.cgi?Reset=1\n\n";
	exit(0);
} # sub allocation_error

sub html_output {

my ($IP_Block_Name, $Final_Allocated_IP) = @_;

my $Final_Usable_Addresses;
my $Final_Block_Subnet;
my $Final_Range_Min;
my $Final_Range_Max;

if ($Final_Allocated_IP) {
	my $Final_IP_Allocation = new Net::IP::XS ($Final_Allocated_IP) or die(&allocation_error(Net::IP::XS::Error, $Final_Allocated_IP));
		$Final_Usable_Addresses=$Final_IP_Allocation->size();
			$Final_Usable_Addresses=$Final_Usable_Addresses-2;
		$Final_Block_Subnet=$Final_IP_Allocation->mask();
		$Final_Range_Min=$Final_IP_Allocation->ip();
		$Final_Range_Max=$Final_IP_Allocation->last_ip();
}


print <<ENDHTML;

<div id="full-page-block">
<p><b>IPv4 Allocation</b></p>

	<a href="ipv4-allocation.cgi?Manual_Override=1">Switch to Manual Allocation</a>
	
	<form action='ipv4-allocation.cgi' method='post'>
		<p>Block:</p>		
		<select name='Location_Input'>
ENDHTML

		my $Location_Retreive = $DB_IP_Allocation->prepare("SELECT `id`, `ip_block_name`, `ip_block_description`
		FROM `ipv4_address_blocks`
		WHERE `status` = '1'
		ORDER BY `ip_block_name`");
		
		$Location_Retreive->execute( );
		
		while ( my @DB_Output = $Location_Retreive->fetchrow_array() )
		{
			my $IP_Block_ID = $DB_Output[0];
			my $IP_Block_Name = $DB_Output[1];
			my $IP_Block_Description = $DB_Output[2];
		
			print "<option value='$IP_Block_ID'>$IP_Block_Name ($IP_Block_Description)</option>";
		
		}
print <<ENDHTML;
		</select>

		<select name='CIDR_Input'>
			<option value='/32' selected>/32</option>
			<option value='/31'>/31</option>
			<option value='/30'>/30</option>
			<option value='/29'>/29</option>
			<option value='/28'>/28</option>
			<option value='/27'>/27</option>
			<option value='/26'>/26</option>
			<option value='/25'>/25</option>
			<option value='/24'>/24</option>
			<option value='/23'>/23</option>
		</select>

		<input type=submit name='ok' value='Find Free IP'>
ENDHTML
if ($Final_Allocated_IP) {
print <<ENDHTML
		<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
			<tr>
				<td style='font-size: 20px;'>
					Parent Block Name
				</td>
			</tr>
			<tr>
				<td style='font-size: 15px; color: #00FF00;'>
					$IP_Block_Name
				</td>
			</tr>
		</table>
		<table>
			<tr>
				<td>
					Free Block:
				</td>
				<td>
					$Final_Allocated_IP
				</td>
			</tr>
			<tr>
				<td>
					Network:
				</td>
				<td>
					$Final_Range_Min
				</td>

				<td>
					<p>Broadcast:</p>
				</td>
				<td>
					<p>$Final_Range_Max</p>
				</td>
			</tr>
			<tr>
				<td>
					<p>Block Subnet:</p>
				</td>
				<td>
					<p>$Final_Block_Subnet</p>
				</td>
			</tr>
			<tr>
				<td>
					<p>Usable Addresses:</p>
				</td>
				<td>
					<p>$Final_Usable_Addresses</p>
				</td>
			</tr>
		</table>
	</form>

	<form action='customer-ipv4-allocation-submission.cgi' method='post'>

		<input type= name='Allocate' value='Allocate'>
		<input type=submit name='Allocate' value='Allocate'>

	</form>

ENDHTML
}

} #sub html_output end

sub html_output_manual {

print <<ENDHTML;

<div id="full-page-block">
<br/>
<p><b>IPv4 Allocation</b></p>

<a href='ipv4-allocation.cgi'>Switch to Automatic Allocation</a>

<form action='customer-ipv4-allocation-submission.cgi' method='post'>
<table align = "center">
	<tr>
		<td style="font-size: 16px; text-align: center; color: #FF0000;">
			USE EXTREME CAUTION!
		</td>
	</tr>
	<tr>
		<td style="font-size: 16px; text-align: center; color: #FF0000; ">
			IT IS POSSIBLE TO CREATE DUPLICATE ALLOCATIONS MANUALLY
		</td>
	</tr>
	<tr>
		<td style="font-size: 16px; text-align: center; color: #FF0000; ">
			IT IS ALSO POSSIBLE TO CREATE ALLOCATIONS OUTSIDE OF THE DEFINED RANGES
		</td>
	</tr>
</table>

<table align = "center">
	<tr>
		<td>
			Usable Block:
		</td>
		<td>
			<input type='text' name='Final_Block_Manual'>
		</td>
	</tr>
</table>

<table align="center">
	<tr>
		<td>
			<div style="text-align: center"><input type=submit name='Internal' value='Submit Internally Only'></div>
		</td>
	</tr>
</table>
<input type='hidden' name='Manual' value='yes'>
</form>

</div> <!-- full-page-block -->
ENDHTML

} #sub html_output_manual end

