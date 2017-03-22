#!/usr/bin/perl -T

use strict;

use Net::IP::XS qw($IP_NO_OVERLAP $IP_PARTIAL_OVERLAP $IP_A_IN_B_OVERLAP $IP_B_IN_A_OVERLAP $IP_IDENTICAL);
use HTML::Table;

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my $Footer = Footer();
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $Location_Input = $CGI->param("Location_Input");
my $CIDR_Input = $CGI->param("CIDR_Input");
my $Reset = $CGI->param("Reset");
my $Manual_Override = $CGI->param("Manual_Override");

my $Final_Assignment = $CGI->param("Final_Assignment");
	my $Add_Host_Temp_New = $CGI->param("Add_Host_Temp_New");
	my $Add_Host_Temp_Existing = $CGI->param("Add_Host_Temp_Existing");
my $Final_Parent = $CGI->param("Final_Parent");
my $Submit_Assignment = $CGI->param("Submit_Assignment");

my $Final_Block_Manual = $CGI->param("Final_Block_Manual");
my $Location_Input_Manual = $CGI->param("Location_Input_Manual");

my $Edit_Block = $CGI->param("Edit_Block");
my $Block_Edit = $CGI->param("Block_Edit");
	my $Block_Edit_Block = $CGI->param("Block_Edit_Block");
	my $Edit_Host_Temp_New = $CGI->param("Edit_Host_Temp_New");
	my $Edit_Host_Temp_Existing = $CGI->param("Edit_Host_Temp_Existing");

my $Delete_Block = $CGI->param("Delete");
my $Delete_Block_Confirm = $CGI->param("Delete_Block_Confirm");
my $Block_Delete = $CGI->param("Block_Delete");

my $Query_Block = $CGI->param("Query_Block");
my $Query_Parent = $CGI->param("Query_Parent");

my $User_Name = $Session->param("User_Name");
my $User_IP_Admin = $Session->param("User_IP_Admin");

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

my $Rows_Returned = $CGI->param("Rows_Returned");
my $ID_Filter  = $CGI->param("ID_Filter");
my $Filter = $CGI->param("Filter");

if ($Rows_Returned eq '') {
	$Rows_Returned='100';
}


my $Enabled_Up_Arrow = '&#9650;';
my $Disabled_Up_Arrow = '&#9651;';
my $Enabled_Down_Arrow = '&#9660;';
my $Disabled_Down_Arrow = '&#9661;';
my ($Block_Name_Arrow, $Block_IP_Arrow, $Block_Used_Arrow, $Order_By_Block);
my $Order_By_SQL;
my $Order_By = $CGI->param("Order_By");
	if ($Order_By eq 'IP-ASC') {
		$Order_By_SQL = "SUBSTRING_INDEX(`ip_block`,'.',1)+0 ASC,
			SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-3),'.',1)+0 ASC,
			SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-2),'.',1)+0 ASC,
			SUBSTRING_INDEX(`ip_block`,'.',-1)+0 ASC";
		$Block_IP_Arrow = $Enabled_Up_Arrow;
		$Order_By_Block = 'IP-DESC';
	}
	elsif ($Order_By eq 'IP-DESC') {
		$Order_By_SQL = "SUBSTRING_INDEX(`ip_block`,'.',1)+0 DESC,
			SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-3),'.',1)+0 DESC,
			SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-2),'.',1)+0 DESC,
			SUBSTRING_INDEX(`ip_block`,'.',-1)+0 DESC";
		$Block_IP_Arrow = $Enabled_Down_Arrow;
		$Order_By_Block = 'IP-ASC';
	}
	else {
		$Order_By_SQL = "SUBSTRING_INDEX(`ip_block`,'.',1)+0 ASC,
			SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-3),'.',1)+0 ASC,
			SUBSTRING_INDEX(SUBSTRING_INDEX(`ip_block`,'.',-2),'.',1)+0 ASC,
			SUBSTRING_INDEX(`ip_block`,'.',-1)+0 ASC";
		$Block_IP_Arrow = $Enabled_Up_Arrow;
		$Order_By_Block = 'IP-DESC';
	}



if ($Reset eq '1') {
	$Location_Input='';
	$Session->param('Location_Input', $Location_Input);
	$CIDR_Input='';
	$Session->param('CIDR_Input', $CIDR_Input);
	$Session->flush();
	print "Location: /IP/ipv6-assignments.cgi\n\n";
	exit(0);
}
elsif ($Location_Input && !$Submit_Assignment) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
	else {
		my ($IP_Block_Name, $Parent_Block, $Final_Assignd_IP) = &assignment;
		require $Header;
		&html_output;
		require $Footer;
		&html_auto_block ($IP_Block_Name, $Parent_Block, $Final_Assignd_IP);
	}
}
elsif ($Submit_Assignment) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
	else {
		my ($Assignment_ID, $Assigned_Address) = &add_block($Final_Assignment);
		my $Message_Green="$Assigned_Address successfully assigned as IPv6 Assignment ID $Assignment_ID.";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
}
elsif ($Final_Block_Manual && $Location_Input_Manual) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
	else {
		my ($Assignment_ID, $Assigned_Address) = &add_block($Final_Block_Manual);
		my $Message_Orange="$Final_Assignment successfully assigned manually. No sanity checks were done.";
		$Session->param('Message_Orange', $Message_Orange);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
}
elsif ($Edit_Block) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_edit_block;
	}
}
elsif ($Block_Edit) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
	else {
		my $Host_Counter = &edit_block;
		my $Message_Green="$Host_Counter hosts added to Block $Block_Edit_Block (ID $Block_Edit).";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
}
elsif ($Delete_Block) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
		&html_delete_block;
	}
}
elsif ($Delete_Block_Confirm) {
	if ($User_IP_Admin != 1) {
		my $Message_Red = 'You do not have sufficient privileges to do that.';
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
	else {
		&delete_block;
		my $Message_Green="$Block_Delete deleted successfully";
		$Session->param('Message_Green', $Message_Green);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
}
elsif ($Query_Block) {
	require $Header;
	&html_output;
	require $Footer;
	&html_query_block($Query_Block, $Query_Parent);
}
else {
	if ($Manual_Override eq '1') {
		require $Header;
		&html_output_manual;
		require $Footer;
	}
	else {
		require $Header;
		&html_output;
		require $Footer;
	}
}


sub assignment {

	my $Discover_Allocatable_Blocks = $DB_Connection->prepare("SELECT `ip_block_name`, `ip_block`, `ip_block_description`, `range_for_use`, `range_for_use_subnet`
	FROM `ipv6_blocks`
	WHERE `id` = ?");

	$Discover_Allocatable_Blocks->execute($Location_Input);

	while ( my @DB_Output = $Discover_Allocatable_Blocks->fetchrow_array() ) {
		my $IP_Block_Name = $DB_Output[0];
		my $IP_Block = $DB_Output[1];
			my $Parent_Block = $IP_Block;
		my $IP_Block_Description = $DB_Output[2];
		my $Range_For_Use = $DB_Output[3];
		my $Range_For_Use_Subnet = $DB_Output[4];

		if ($Range_For_Use ne '') {
			$IP_Block = $Range_For_Use;
		}

		my $IP_Assignment_Limit_Collection = new Net::IP::XS ($IP_Block) or die(&assignment_error(Net::IP::XS::Error, $IP_Block));
			my $IP_Block_Network = $IP_Assignment_Limit_Collection->ip();
			my $IP_Block_Limit = $IP_Assignment_Limit_Collection->last_ip();
				my $IP_Assignment_Limit_Execution = new Net::IP::XS ($IP_Block_Limit) or die(&assignment_error(Net::IP::XS::Error, $IP_Block_Limit));
					my $IP_Block_Limit_Integer = $IP_Assignment_Limit_Execution->intip();

		my $Final_Block;
		my $Rows = 1;
		my $Counter = 0;
		LOOP: while ($Counter != $Rows) {
			
			$IP_Block =~ s/\/..?.?//;

			my $IP_Block_Check_Cycle = $DB_Connection->prepare("SELECT `ip_block`
				FROM `ipv6_assignments`
				ORDER BY `ip_block` ASC");
			$IP_Block_Check_Cycle->execute();
			$Rows = $IP_Block_Check_Cycle->rows();

			if (!$Rows) {
				$Final_Block = "$IP_Block$CIDR_Input";
			}
			else {
				
				while ( my @Block_DB_Output = $IP_Block_Check_Cycle->fetchrow_array() )
				{
	
					my $Network_Block = $Block_DB_Output[0];
	
					my $IP_Block_For_Assignment = "$IP_Block$CIDR_Input";
					if ($Range_For_Use ne '') {
						$IP_Block_For_Assignment = $IP_Block;
					}

					# Have to use Net::IPv6Addr to determine the network, as Net::IP is too strict to take arbitrary IP values
					use Net::IPv6Addr;
					my ($Arbitary_Network_Block, $Arbitary_Network_Block_Mask) = Net::IPv6Addr::ipv6_parse($IP_Block_For_Assignment);
	
	my $IP_Assignment = new Net::IP::XS ($Arbitary_Network_Block.'/'.$Arbitary_Network_Block_Mask) || die (Net::IP::XS::Error);
	#my $Int_IP = $Block_Query->intip() or die(&assignment_error("Block Integer Generation ( $Block ):".Net::IP::XS::Error));

					#my $IP_Assignment = new Net::IP::XS($IP_Block_For_Assignment) or die(&assignment_error("Proposed Assignment ( $IP_Block_For_Assignment ):".Net::IP::XS::Error));
						my $Proposed_IP = $IP_Assignment->ip();
					my $IP_Assignment_Check = new Net::IP::XS($Network_Block) or die(&assignment_error("Existing Assignment Check ( $Network_Block ):".Net::IP::XS::Error));
	
					my $Overlap_Check = $IP_Assignment->overlaps($IP_Assignment_Check);
	
					if (not defined($Overlap_Check))
					{
						my $Message_Red="Problem with IP range $Overlap_Check, it is not properly defined.";
						$Session->param('Message_Red', $Message_Red);
						$Session->flush();
						print "Location: /IP/ipv6-assignments.cgi?Reset=1\n\n";
						exit(0);
					}
					elsif ($Proposed_IP eq $IP_Block_Network || $Proposed_IP eq $IP_Block_Limit) {
						$Counter = '0';
						$Final_Block = '';
						$IP_Block = &increase_octets($IP_Block);
						goto LOOP;
					}
					elsif ( $Overlap_Check == $IP_IDENTICAL )
					{
						$Counter = '0';
						$Final_Block = '';
						$IP_Block = &increase_octets($IP_Block);
						goto LOOP;
					}
					elsif ( $Overlap_Check == $IP_A_IN_B_OVERLAP )
					{
						$Counter = '0';
						$Final_Block = '';
						$IP_Block = &increase_octets($IP_Block);
						goto LOOP;
					}
					elsif ( $Overlap_Check == $IP_B_IN_A_OVERLAP )
					{			
						$Counter = '0';
						$Final_Block = '';
						$IP_Block = &increase_octets($IP_Block);
						goto LOOP;
					}
					elsif ( $Overlap_Check == $IP_PARTIAL_OVERLAP )
					{
						$Counter = '0';
						$Final_Block = '';
						$IP_Block = &increase_octets($IP_Block);
						goto LOOP;
					}
					elsif ( $Overlap_Check == $IP_NO_OVERLAP )
					{
						$Counter++;
						$Final_Block = $IP_Block_For_Assignment;
					}
				}
			};
		}

		my $Final_IP_Assignment = new Net::IP::XS ($Final_Block) or die(&assignment_error("Final IP Assignment Check ( $Final_Block ):".Net::IP::XS::Error));
			my $IP_Block_Limit_Final = $Final_IP_Assignment->last_ip();
				my $IP_Assignment_Limit_Final = new Net::IP::XS ($IP_Block_Limit_Final) or die(&assignment_error("Final IP Limit Check ( $Final_Block ):".Net::IP::XS::Error));
					my $IP_Block_Limit_Integer_Final = $IP_Assignment_Limit_Final->intip();

		if ($IP_Block_Limit_Integer < $IP_Block_Limit_Integer_Final) {
			my $Message_Red="There are no more available blocks in $IP_Block_Network for a $CIDR_Input notation. Either reduce the block size or use a different block";
			$Session->param('Message_Red', $Message_Red);
			$Session->flush();
			print "Location: /IP/ipv6-assignments.cgi?Reset=1\n\n";
			exit(0);
		}

		my $Usable_Addresses = $Final_IP_Assignment->size();
			$Usable_Addresses = $Usable_Addresses-2;
		my $Block_Subnet = $Final_IP_Assignment->mask();
		my  $Range_Min = $Final_IP_Assignment->ip();
		my $Range_Max = $Final_IP_Assignment->last_ip();

		if ($Range_For_Use) {
			$Block_Subnet = $Range_For_Use_Subnet;
		}

		my @Final_Assignment = ($IP_Block_Name, $Parent_Block, $Final_Block);
		return @Final_Assignment;
		
	}

} # sub assignment

sub increase_octets {

	my ($Block) = @_;

	my ($Block_Prefix, $CIDR) = Net::IP::XS::ip_splitprefix("${Block}${CIDR_Input}") or die(&assignment_error("Initial Block Octet Parse ( ${Block}${CIDR_Input} ):".Net::IP::XS::Error));

	# Have to use Net::IPv6Addr to determine the network, as Net::IP is too strict to take arbitrary IP values
	use Net::IPv6Addr;
	my ($Network_Block, $Network_Block_Mask) = Net::IPv6Addr::ipv6_parse($Block_Prefix, $CIDR);
	
	my $Block_Query = new Net::IP::XS ($Network_Block.'/'.$Network_Block_Mask) || die (Net::IP::XS::Error);
	my $Int_IP = $Block_Query->intip() or die(&assignment_error("Block Integer Generation ( $Block ):".Net::IP::XS::Error));

	my $CIDR_Limit = 128;
	my $Total_IPs_In_Block = 1;

	my $CIDR_Value = $CIDR;
		$CIDR_Value =~ s/\\//;
	while ($CIDR_Value ne $CIDR_Limit) {
		
		if ($Total_IPs_In_Block eq 1) {
			$Total_IPs_In_Block++;
		}
		else {
			$Total_IPs_In_Block = $Total_IPs_In_Block * 2;
		}
		$CIDR_Limit--;
	}

	$Int_IP = $Int_IP + $Total_IPs_In_Block;

	my $Hex_IP = Math::BigInt->new("$Int_IP")->as_hex;

	$Hex_IP =~ s/^0x//;
	my @Hex_Array = ( $Hex_IP =~ m/..../g );
		my $Hex0 = "$Hex_Array[0]";
		my $Hex1 = "$Hex_Array[1]";
		my $Hex2 = "$Hex_Array[2]";
		my $Hex3 = "$Hex_Array[3]";
		my $Hex4 = "$Hex_Array[4]";
		my $Hex5 = "$Hex_Array[5]";
		my $Hex6 = "$Hex_Array[6]";
		my $Hex7 = "$Hex_Array[7]";
	my $Proposed_IP = $Hex0.":".$Hex1.":".$Hex2.":".$Hex3.":".$Hex4.":".$Hex5.":".$Hex6.":".$Hex7."/$CIDR";

#	$Proposed_IP = new Net::IP::XS ($Proposed_IP) or die(&assignment_error("Short Increase Octets ( $Proposed_IP ):".Net::IP::XS::Error));
	return $Proposed_IP;

} # sub increase_octets

sub assignment_error {

my ($Error, $IP_Block) = @_;
if ($IP_Block) {$IP_Block = "<br/>--------------- You must select a CIDR that fits within the boundaries of $IP_Block ---------------"}

	my $Message_Red="Error: You specified a CIDR that spills over the edge of the boundary<br/>
	Error Details: ${Error}${IP_Block}";
	$Session->param('Message_Red', $Message_Red);
	$Session->flush();
	print "Location: /IP/ipv6-assignments.cgi?Reset=1\n\n";
	exit(0);
} # sub assignment_error

sub html_auto_block {

print <<ENDHTML;

<div id="wide-popup-box">
<a href="/IP/ipv6-assignments.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">IPv6 Assignment</h3>

<h4 align="center">Block Info</h4>
ENDHTML

my ($IP_Block_Name, $Parent_Block, $Final_Assignd_IP) = @_;

my $Embedded = 1;
&html_query_block($Final_Assignd_IP, $Parent_Block, $Embedded);

if ($Add_Host_Temp_New) {
	if ($Add_Host_Temp_Existing !~ m/^$Add_Host_Temp_New,/g && $Add_Host_Temp_Existing !~ m/,$Add_Host_Temp_New$/g && $Add_Host_Temp_Existing !~ m/,$Add_Host_Temp_New,/g) {
		$Add_Host_Temp_Existing = $Add_Host_Temp_Existing . $Add_Host_Temp_New . ",";
	}
}

my $Hosts;
my @Hosts = split(',', $Add_Host_Temp_Existing);

foreach my $Host (@Hosts) {

	my $Host_Query = $DB_Connection->prepare("SELECT `hostname`
		FROM `hosts`
		WHERE `id` = ?");
	$Host_Query->execute($Host);
		
	while ( (my $Host_Name) = my @Host_Query = $Host_Query->fetchrow_array() )
	{
		my $Host_Name_Character_Limited = substr( $Host_Name, 0, 40 );
			if ($Host_Name_Character_Limited ne $Host_Name) {
				$Host_Name_Character_Limited = $Host_Name_Character_Limited . '...';
			}

			$Hosts = $Hosts . "<tr><td style='color: #00FF00;'>$Host_Name_Character_Limited</td></tr>";
	}
}


print <<ENDHTML;
<hr width="50%">
<h4 align="center">Host Assignment</h4>

<form action='ipv6-assignments.cgi' method='post'>
<table align="center" style="font-size: 12px;">
	<tr>
		<td>Assign to Host(s)</td>
	</tr>
	<tr>
		<td>
			<select name='Add_Host_Temp_New' onchange='this.form.submit()' style="width: 300px">
ENDHTML

my $Select_Hosts = $DB_Connection->prepare("SELECT `id`, `hostname`
	FROM `hosts`
	ORDER BY `hostname` ASC"
);

$Select_Hosts->execute();

print "<option value='' selected>--Select a Host--</option>";

while ( my ($Host_ID, $Host_Name) = $Select_Hosts->fetchrow_array() ) { 
	print "<option value='$Host_ID'>$Host_Name</option>";
}

print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td>&nbsp;</td>
	</tr>
	<tr>
		<td>Assigned Hosts</td>
	</tr>
ENDHTML

if ($Hosts) {
print <<ENDHTML;
	$Hosts
ENDHTML
}
else {
print <<ENDHTML;
	<tr>
		<td style='color: #FFC600;'>No Hosts Attached</td>
	</tr>
ENDHTML
}

print <<ENDHTML;
	</table>

<hr width="50%">

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>You can assign a block/IP to multiple hosts. These blocks/IPs are then assumed to be floating.</li>
</ul>
<br/>
	<input type='hidden' name='Add_Host_Temp_Existing' value='$Add_Host_Temp_Existing'>
	<input type='hidden' name='Location_Input' value='$Location_Input'>
	<input type='hidden' name='CIDR_Input' value='$CIDR_Input'>
</form>

<form action='ipv6-assignments.cgi' method='post'>
	<input type='hidden' name='Add_Host_Temp_Existing' value='$Add_Host_Temp_Existing'>
	<input type='hidden' name='Final_Assignment' value='$Final_Assignd_IP'>
	<input type='hidden' name='Final_Parent' value='$Parent_Block'>
	<input type='submit' name='Submit_Assignment' value='Assign Block'>
</form>

ENDHTML

} # sub html_auto_block

sub add_block {

	my $Assigned_Block = $_[0];
		my $Assigned_IP = $Assigned_Block;
			$Assigned_IP =~ s/^(.*)\/.*/$1/;
	my $Assigned_CIDR = $Assigned_Block;
			$Assigned_CIDR =~ s/^.*\/(..?.?)/$1/;
	my $Assigned_Address = Net::IP::XS::ip_compress_address($Assigned_IP, 6);
		$Assigned_Address = $Assigned_Address . '/' . $Assigned_CIDR;

	### Existing Block Check
	my $Existing_Block_Check = $DB_Connection->prepare("SELECT `id`
		FROM `ipv6_assignments`
		WHERE `ip_block` = ?");
		$Existing_Block_Check->execute($Assigned_Address);
		my $Existing_Blocks = $Existing_Block_Check->rows();

	if ($Existing_Blocks > 0)  {
		my $Existing_ID;
		while ( my @Select_Block = $Existing_Block_Check->fetchrow_array() )
		{
			$Existing_ID = $Select_Block[0];
		}
		my $Message_Red="Block: $Assigned_Address already exists as ID: $Existing_ID";
		$Session->param('Message_Red', $Message_Red);
		$Session->flush();
		print "Location: /IP/ipv6-assignments.cgi\n\n";
		exit(0);
	}
	### / Existing Block Check

	my $Block_Insert = $DB_Connection->prepare("INSERT INTO `ipv6_assignments` (
		`ip_block`,
		`parent_block`,
		`modified_by`
	)
	VALUES (
		?, ?, ?
	)");

	if ($Location_Input_Manual) {$Final_Parent = $Location_Input_Manual}

	$Block_Insert->execute($Assigned_Address, $Final_Parent, $User_Name);

	my $Block_Insert_ID = $DB_Connection->{mysql_insertid};

	$Add_Host_Temp_Existing =~ s/,$//;
	my @Host = split(',', $Add_Host_Temp_Existing);

	my $Host_Counter = 0;
	foreach my $Host (@Host) {
		$Host_Counter++;
		my $Host_Insert = $DB_Connection->prepare("INSERT INTO `lnk_hosts_to_ipv6_assignments` (
			`host`,
			`ip`
		)
		VALUES (
			?, ?
		)");
		
		$Host_Insert->execute($Host, $Block_Insert_ID);
	}

	# Audit Log
	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();

	if ($Final_Block_Manual) {$Final_Block_Manual = ' This was a manual assignment.'} 

	$Audit_Log_Submission->execute("IP", "Add", "$User_Name assigned $Assigned_Address. The system assigned it IPv6 Assignment ID $Block_Insert_ID. $Host_Counter hosts were assigned to the block.$Final_Block_Manual", $User_Name);

	# / Audit Log

	return($Block_Insert_ID, $Assigned_Address);

} # sub add_block

sub html_edit_block {

	my $Block_Query = $DB_Connection->prepare("SELECT `ip_block`, `parent_block`
	FROM `ipv6_assignments`
	WHERE `id` LIKE ?");

	$Block_Query->execute($Edit_Block);
	
	my ($Block_Extract, $Block_Parent_Extract) = $Block_Query->fetchrow_array();

	my $Associated_Host_Links = $DB_Connection->prepare("SELECT `host`
	FROM `lnk_hosts_to_ipv6_assignments`
	WHERE `ip` LIKE ?");

	$Associated_Host_Links->execute($Edit_Block);

	# Existing Hosts
	my $Existing_Hosts;
	while (my $Host = $Associated_Host_Links->fetchrow_array())
	{
		my $Host_Query = $DB_Connection->prepare("SELECT `hostname`
			FROM `hosts`
			WHERE `id` = ?");
		$Host_Query->execute($Host);
			
		while ( (my $Host_Name) = my @Host_Query = $Host_Query->fetchrow_array() )
		{
			my $Host_Name_Character_Limited = substr( $Host_Name, 0, 40 );
				if ($Host_Name_Character_Limited ne $Host_Name) {
					$Host_Name_Character_Limited = $Host_Name_Character_Limited . '...';
				}

				$Existing_Hosts = $Existing_Hosts . $Host_Name_Character_Limited . "<br/>";
		}
	}
	# / Existing Hosts

	# Newly attached hosts
	my $Hosts;
	if ($Edit_Host_Temp_New) {

		### Check to see if new link is already attached to this block
		if ($Edit_Host_Temp_Existing !~ m/^$Edit_Host_Temp_New,/g &&
		$Edit_Host_Temp_Existing !~ m/,$Edit_Host_Temp_New$/g &&
		$Edit_Host_Temp_Existing !~ m/,$Edit_Host_Temp_New,/g) {
	
			my $Select_Links = $DB_Connection->prepare("SELECT `id`
				FROM `lnk_hosts_to_ipv6_assignments`
				WHERE `ip` = ?
				AND `host` = ? "
			);
			$Select_Links->execute($Edit_Block, $Edit_Host_Temp_New);
	
			my $Matched_Rows = $Select_Links->rows();
	
			if ($Matched_Rows == 0) {
				$Edit_Host_Temp_Existing = $Edit_Host_Temp_Existing . $Edit_Host_Temp_New . ",";
			}
		}
	
		my @Hosts = split(',', $Edit_Host_Temp_Existing);
		
		foreach my $Host (@Hosts) {
		
			my $Host_Query = $DB_Connection->prepare("SELECT `hostname`
				FROM `hosts`
				WHERE `id` = ?");
			$Host_Query->execute($Host);
				
			while ( (my $Host_Name) = my @Host_Query = $Host_Query->fetchrow_array() )
			{
				my $Host_Name_Character_Limited = substr( $Host_Name, 0, 40 );
					if ($Host_Name_Character_Limited ne $Host_Name) {
						$Host_Name_Character_Limited = $Host_Name_Character_Limited . '...';
					}
		
					$Hosts = $Hosts . "<tr><td style='color: #00FF00;'>$Host_Name_Character_Limited</td></tr>";
			}
		}
	}
	# / Newly attached hosts


print <<ENDHTML;

<div id="wide-popup-box">
<a href="/IP/ipv6-assignments.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Edit IPv6 Assignment ID $Edit_Block</h3>
<h4 align="center">Existing Block Associations</h4>

<form action='/IP/ipv6-assignments.cgi' method='post' >

<table align = "center">
	<tr>
		<td style="text-align: right;">Block:</td>
		<td style="text-align: left; color: #00FF00;">$Block_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Parent:</td>
		<td style="text-align: left; color: #00FF00;">$Block_Parent_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Existing Associated Hosts:</td>
		<td style="text-align: left; color: #00FF00;">$Existing_Hosts</td>
	</tr>
</table>

<hr width="50%">

<h4 align="center">Associate More Hosts</h4>

<form action='ipv6-assignments.cgi' method='post'>
<table align="center" style="font-size: 12px;">
	<tr>
		<td>
			<select name='Edit_Host_Temp_New' onchange='this.form.submit()' style="width: 300px">
ENDHTML

my $Select_Hosts = $DB_Connection->prepare("SELECT `id`, `hostname`
	FROM `hosts`
	ORDER BY `hostname` ASC"
);

$Select_Hosts->execute();

print "<option value='' selected>--Select a Host--</option>";

while ( my ($Host_ID, $Host_Name) = $Select_Hosts->fetchrow_array() ) { 
	print "<option value='$Host_ID'>$Host_Name</option>";
}

print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td>&nbsp;</td>
	</tr>
	<tr>
		<td>Newly Associated Hosts</td>
	</tr>
ENDHTML

if ($Hosts) {
print <<ENDHTML;
	$Hosts
ENDHTML
}
else {
print <<ENDHTML;
	<tr>
		<td style='color: #FFC600;'>No Newly Associated Hosts</td>
	</tr>
ENDHTML
}

print <<ENDHTML;
	</table>

<hr width="50%">

<ul style='text-align: left; display: inline-block; padding-left: 40px; padding-right: 40px;'>
	<li>You can assign a block/IP to multiple hosts. These blocks/IPs are then assumed to be floating.</li>
</ul>
<br/>
	<input type='hidden' name='Edit_Host_Temp_Existing' value='$Edit_Host_Temp_Existing'>
	<input type='hidden' name='Edit_Block' value='$Edit_Block'>
</form>

<form action='ipv6-assignments.cgi' method='post'>
<input type='hidden' name='Block_Edit_Block' value='$Block_Extract'>
<input type='hidden' name='Edit_Host_Temp_Existing' value='$Edit_Host_Temp_Existing'>
<input type='hidden' name='Block_Edit' value="$Edit_Block">

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Edit Block'></div>

</form>

ENDHTML

} # sub html_edit_block

sub edit_block {

	$Edit_Host_Temp_Existing =~ s/,$//;
	my @Host = split(',', $Edit_Host_Temp_Existing);

	my $Host_Counter = 0;
	foreach my $Host (@Host) {
		$Host_Counter++;
		my $Host_Insert = $DB_Connection->prepare("INSERT INTO `lnk_hosts_to_ipv6_assignments` (
			`host`,
			`ip`
		)
		VALUES (
			?, ?
		)");
		
		$Host_Insert->execute($Host, $Block_Edit);
	}

	# Audit Log
	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();
	
	$Audit_Log_Submission->execute("IP", "Modify", "$User_Name added $Host_Counter new hosts to IPv6 Assignment ID $Block_Edit.", $User_Name);

	# / Audit Log

	return($Host_Counter);


} # sub edit_block

sub html_delete_block {
	my $Select_Block = $DB_Connection->prepare("SELECT `ip_block`, `parent_block`
	FROM `ipv6_assignments`
	WHERE `id` = ?");

	$Select_Block->execute($Delete_Block);
	
	while ( my @DB_Block = $Select_Block->fetchrow_array() )
	{
	
		my $Block_Extract = $DB_Block[0];
		my $Block_Parent_Extract = $DB_Block[1];

		my $Select_Block_Links = $DB_Connection->prepare("SELECT `host`
			FROM `lnk_hosts_to_ipv6_assignments`
			WHERE `ip` = ?");
		$Select_Block_Links->execute($Delete_Block);
	
		my $Hosts;
		while (my $Block_ID = $Select_Block_Links->fetchrow_array() ) {
			my $Select_Blocks = $DB_Connection->prepare("SELECT `hostname`
				FROM `hosts`
				WHERE `id` = ?");
			$Select_Blocks->execute($Block_ID);
	
			while (my $Host = $Select_Blocks->fetchrow_array() ) {
	
				$Host = "<a href='/IP/hosts.cgi?Filter=$Host'><span style='color: #00FF00;'>$Host</span></a>";
				$Hosts = $Host. ",&nbsp;" . $Hosts;
	
			}
			$Hosts =~ s/,&nbsp;$//;
		}

print <<ENDHTML;
<div id="small-popup-box">
<a href="/IP/ipv6-assignments.cgi">
<div id="blockclosebutton">
</div>
</a>

<h3 align="center">Delete Assignment</h3>

<form action='/IP/ipv6-assignments.cgi' method='post' >
<p>Are you sure you want to <span style="color:#FF0000">DELETE</span> this assignment?</p>
<p>The parent block and hosts associated with this block will not be deleted.</p>
<table align = "center">
	<tr>
		<td style="text-align: right;">Block:</td>
		<td style="text-align: left; color: #00FF00;">$Block_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Parent:</td>
		<td style="text-align: left; color: #00FF00;">$Block_Parent_Extract</td>
	</tr>
	<tr>
		<td style="text-align: right;">Associated Hosts:</td>
		<td style="text-align: left; color: #00FF00;">$Hosts</td>
	</tr>
</table>

<input type='hidden' name='Delete_Block_Confirm' value='$Delete_Block'>
<input type='hidden' name='Block_Delete' value='$Block_Extract'>

<hr width="50%">
<div style="text-align: center"><input type=submit name='ok' value='Delete Block'></div>

</form>

ENDHTML

	}
} # sub html_delete_block

sub delete_block {

	# Audit Log
	my $Select_Blocks = $DB_Connection->prepare("SELECT `ip_block`
		FROM `ipv6_assignments`
		WHERE `id` = ?");

	$Select_Blocks->execute($Delete_Block_Confirm);

	while ( my $Block = $Select_Blocks->fetchrow_array() ) {
		my $DB_Connection = DB_Connection();
		my $Audit_Log_Submission = Audit_Log_Submission();
		$Audit_Log_Submission->execute("IP", "Delete", "$User_Name deleted $Block (IPv6 Assignment ID $Delete_Block_Confirm).", $User_Name);
	}
	# / Audit Log

	my $Delete_Block = $DB_Connection->prepare("DELETE from `ipv6_assignments`
		WHERE `id` = ?");

	$Delete_Block->execute($Delete_Block_Confirm);

	my $Delete_Associations = $DB_Connection->prepare("DELETE from `lnk_hosts_to_ipv6_assignments`
		WHERE `ip` = ?");

	$Delete_Associations->execute($Delete_Block_Confirm);

} # sub delete_block

sub html_query_block {

	my ($Block, $Parent, $Embedded) = @_;

	my ($Block_Prefix, $Block_CIDR) = Net::IP::XS::ip_splitprefix($Block);

	my $Parent_Prefix;
	my $Parent_CIDR;
	if ($Parent) {
		($Parent_Prefix, $Parent_CIDR) = Net::IP::XS::ip_splitprefix($Parent);
	}

	my $CIDR;
	if ($Block_CIDR == 128 && $Parent) {$CIDR = $Parent_CIDR} else {$CIDR = $Block_CIDR}

	# Have to use Net::IPv6Addr to determine the network, as Net::IP is too strict to take arbitrary IP values
	use Net::IPv6Addr;
	my ($Network_Block, $Network_Block_Mask) = Net::IPv6Addr::ipv6_parse($Block) or die (&assignment_error("Query Block Normalise ( ${$Block_Prefix}${$CIDR} ):".Net::IP::XS::Error));

	my $Block_Query = new Net::IP::XS ($Network_Block.'/'.$Network_Block_Mask) || die (Net::IP::XS::Error);

	my $Block_Version = $Block_Query->version();
	my $Block_Type = $Block_Query->iptype();
	my $Short_Format = $Block_Query->short();
	my $Long_Format = $Block_Query->ip();
	my $Block_Addresses = $Block_Query->size();
		my $Usable_Addresses = $Block_Addresses-2;
			if ($Usable_Addresses < 1) {$Usable_Addresses = 'N/A'}
	my $Decimal_Subnet = $Block_Query->mask();
	my $Range_Min = $Block_Query->ip();
		my $Short_Range_Min = new Net::IP::XS ($Range_Min) || die (Net::IP::XS::Error);
		my $Range_Min_Short = $Short_Range_Min->short(); 
	my $Range_Max = $Block_Query->last_ip();
		my $Short_Range_Max = new Net::IP::XS ($Range_Max) || die (Net::IP::XS::Error);
		my $Range_Max_Short = $Short_Range_Max->short();
	my $Reverse_IP = $Block_Query->reverse_ip();
	my $Hex_IP = $Block_Query->hexip();
	my $Hex_Mask = $Block_Query->hexmask();

	if (!$Embedded) {
print <<ENDHTML;
<div id="small-popup-box">
<a href="ipv6-assignments.cgi">
<div id="blockclosebutton"> 
</div>
</a>
<h3>Block Query $Block_Prefix $CIDR</h3>
ENDHTML
	}

	if ($Block_CIDR == 128) {print "<p>This is a /128 block, so its block values are calculated from its parent.</p>";}

	print <<ENDHTML;
<table align="center" style="font-size: 12px;">
	<tr>
		<td style="text-align: right;">Block</td>
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
		<td style="text-align: right;">Long Format</td>
		<td style="text-align: left; color: #00FF00;">$Long_Format/$CIDR</td>
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
		<td style="text-align: right;">Short Network Address</td>
		<td style="text-align: left; color: #00FF00;">$Range_Min_Short</td>
	</tr>
	<tr>
		<td style="text-align: right;">Broadcast Address</td>
		<td style="text-align: left; color: #00FF00;">$Range_Max</td>
	</tr>
	<tr>
		<td style="text-align: right;">Short Broadcast Address</td>
		<td style="text-align: left; color: #00FF00;">$Range_Max_Short</td>
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

ENDHTML

	if (!$Embedded) {
		print '</div>';
	}

} # sub html_query_block

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

my $Select_Block_Count = $DB_Connection->prepare("SELECT COUNT(*)
	FROM `ipv6_assignments`");
	$Select_Block_Count->execute();
	my $Total_Rows = $Select_Block_Count->fetchrow_array();

my $Select_Blocks = $DB_Connection->prepare("SELECT `id`, `ip_block`, `parent_block`, `last_modified`, `modified_by`
	FROM `ipv6_assignments`
		WHERE `id` LIKE ?
		OR `ip_block` LIKE ?
		OR `parent_block` LIKE ?
	ORDER BY
		$Order_By_SQL
	LIMIT ?, ?");

if ($ID_Filter) {
	$Select_Blocks->execute("$ID_Filter", "", "", 0, $Rows_Returned);
}
else {
	$Select_Blocks->execute("%$Filter%", "%$Filter%", "%$Filter%", 0, $Rows_Returned);	
}
my $Rows = $Select_Blocks->rows();

$Table->addRow( "ID", 
"IP/Block<a href='/IP/ipv6-assignments.cgi?Order_By=$Order_By_Block&Filter=$Filter'>$Block_IP_Arrow</a>", 
"Associated Hosts", "Parent Block", "Floating", "Last Modified", "Modified By", "Edit", "Delete" );
$Table->setRowClass (1, 'tbrow1');

my $Row_Count = 1;

while ( my @Select_Blocks = $Select_Blocks->fetchrow_array() ) {

	$Row_Count++;

	my $ID = $Select_Blocks[0];
		my $ID_Clean = $ID;
		if ($ID_Filter) {$ID =~ s/(.*)($ID_Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;}
		if ($Filter) {$ID =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;}
	my $Block = $Select_Blocks[1];
		my $Block_Extract = $Block;
		$Block =~ s/\/32//;
		$Block =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Parent_Block = $Select_Blocks[2];
		my $Parent_Block_Extract = $Parent_Block;
		$Parent_Block =~ s/(.*)($Filter)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Last_Modified = $Select_Blocks[3];
	my $Modified_By = $Select_Blocks[4];

	my $Select_Host_Links = $DB_Connection->prepare("SELECT `host`
		FROM `lnk_hosts_to_ipv6_assignments`
		WHERE `ip` = ?");
	$Select_Host_Links->execute($ID);

	my $Hosts;
	my $Floating;
	while (my $Host_ID = $Select_Host_Links->fetchrow_array() ) {
		$Floating++;
		my $Select_Hosts = $DB_Connection->prepare("SELECT `hostname`
			FROM `hosts`
			WHERE `id` = ?");
		$Select_Hosts->execute($Host_ID);

		while (my $Host = $Select_Hosts->fetchrow_array() ) {

			$Host = "<a href='/IP/hosts.cgi?Filter=$Host'>$Host</a>";
			$Hosts = $Host. ",&nbsp;" . $Hosts;

		}
	}

	if ($Floating > 1) {$Floating = 'Yes'} else {$Floating = 'No'}
	$Hosts =~ s/,&nbsp;$//;
	$Table->addRow( $ID, 
	"<a href='/IP/ipv6-assignments.cgi?Query_Block=$Block_Extract&Query_Parent=$Parent_Block_Extract'>$Block</a>",
	$Hosts,
	"<a href='/IP/ipv6-blocks.cgi?Filter=$Parent_Block_Extract'>$Parent_Block</a>", 
	$Floating, $Last_Modified, $Modified_By,
	"<a href='/IP/ipv6-assignments.cgi?Edit_Block=$ID_Clean'><img src=\"/resources/imgs/edit.png\" alt=\"Edit Block $Block_Extract\" ></a>",
	"<a href='/IP/ipv6-assignments.cgi?Delete=$ID_Clean'><img src=\"/resources/imgs/delete.png\" alt=\"Delete Block $Block_Extract\" ></a>"
	);

	if ($Floating eq 'Yes') {
		$Table->setCellClass ($Row_Count, 5, 'tbroworange');
	}
	else {
		$Table->setCellClass ($Row_Count, 5, 'tbrowgreen');
	}

}
$Table->setColWidth(1, '1px');
$Table->setColWidth(5, '1px');
$Table->setColWidth(6, '110px');
$Table->setColWidth(7, '110px');
$Table->setColWidth(8, '1px');
$Table->setColWidth(9, '1px');

$Table->setColAlign(1, 'center');
$Table->setColAlign(2, 'center');
for (4..9) {
	$Table->setColAlign($_, 'center');
}
print <<ENDHTML;
<table style="width:100%; border: solid 2px; border-color:#293E77; background-color:#808080;">
	<tr>
		<td style="text-align: right;">
			<table cellpadding="3px">
			<form action='/IP/ipv6-assignments.cgi' method='post' >
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
			<form action='/IP/ipv6-assignments.cgi' method='post' >
			<table>
				<tr>
					<td align="center"><span style="font-size: 18px; color: #00FF00;">Add New Assignment</span></td>
				</tr>
				<tr>
					<td>
						<form action='ipv6-assignments.cgi' method='post'>	
							<select name='Location_Input'>
ENDHTML

		my $Location_Retreive = $DB_Connection->prepare("SELECT `id`, `ip_block_name`, `ip_block_description`, `ip_block`
		FROM `ipv6_blocks`
		ORDER BY `ip_block_name` ASC");

		$Location_Retreive->execute( );

		while ( my @DB_Output = $Location_Retreive->fetchrow_array() )
		{
			my $IP_Block_ID = $DB_Output[0];
			my $IP_Block_Name = $DB_Output[1];
			my $IP_Block_Description = $DB_Output[2];
			my $IP_Block = $DB_Output[3];

			print "<option value='$IP_Block_ID'>$IP_Block_Name [$IP_Block] $IP_Block_Description</option>";

		}
print <<ENDHTML;
							</select>

							<select name='CIDR_Input'>
ENDHTML

	for (my $i=128; $i >= 32; $i--) {
		if ($i == 128) {
			print "<option value='/$i' selected>/$i</option>";
		}
		else {
			print "<option value='/$i'>/$i</option>";
		}
	}

print <<ENDHTML;
							</select>

							<input type=submit name='ok' value='Assign Block'>
						</td>
					</tr>
				</table>
			</form>
		</td>
		<td align="right">
			<a href="ipv6-assignments.cgi?Manual_Override=1"><span style="color: #FF8A00;">Switch to Manual Assignment Mode</span></a>
		</td>
	</tr>
</table>

<p style="font-size:14px; font-weight:bold;">IPv6 Assignments | Blocks Displayed: $Rows of $Total_Rows</p>

$Table

ENDHTML


} #sub html_output end

sub html_output_manual {

print <<ENDHTML;

<div id="full-page-block">
<h2 style='text-align:center;'>IPv6 Manual Assignment</h2>

<form action='ipv6-assignments.cgi' method='post'>
<table align = "center">
	<tr>
		<td style="font-size: 16px; text-align: center; color: #FF0000;">
			EXTREME CAUTION! HERE BE DRAGONS!
		</td>
	</tr>
</table>

<h4 style='text-align:center; color: #00FF00;'><a href='ipv6-assignments.cgi'>Click here to switch back to Automatic Assignment Mode</a></h4>

<table align = "center">
	<tr>
		<td style="font-size: 16px; text-align: center; color: #FF0000;">
			It is possible to create duplicate or overlapping assignments if you're not careful.
		</td>
	</tr>
	<tr>
		<td style="font-size: 16px; text-align: center; color: #FF0000;">
			It is possible to create assignments outside of the defined ranges if you're not careful.
		</td>
	</tr>
	<tr>
		<td style="font-size: 16px; text-align: center; color: #FF0000;">
			There's also an audit log so everybody will know it was you that broke all the internets. You'll become a meme.
		</td>
	</tr>
</table>

<br/>

<table align = "center">
	<tr>
		<td>
			Parent Block:
		</td>
		<td>
			<select name='Location_Input_Manual'>
ENDHTML

		my $Location_Retreive = $DB_Connection->prepare("SELECT `id`, `ip_block_name`, `ip_block_description`, `ip_block`
		FROM `ipv6_blocks`
		ORDER BY `ip_block_name` ASC");
		
		$Location_Retreive->execute( );
		
		while ( my @DB_Output = $Location_Retreive->fetchrow_array() )
		{
			my $IP_Block_ID = $DB_Output[0];
			my $IP_Block_Name = $DB_Output[1];
			my $IP_Block_Description = $DB_Output[2];
			my $IP_Block = $DB_Output[3];
		
			print "<option value='$IP_Block'>$IP_Block_Name [$IP_Block] (ID: $IP_Block_ID) $IP_Block_Description</option>";
		
		}
print <<ENDHTML;
			</select>
		</td>
	</tr>
	<tr>
		<td>
			Usable CIDR Notated Block:
		</td>
		<td>
			<input type='text' name='Final_Block_Manual' placeholder='2001:2::123/128' required>
		</td>
	</tr>
</table>

<table align="center">
	<tr>
		<td>
			<div style="text-align: center"><input type=submit value='Submit'></div>
		</td>
	</tr>
</table>
<input type='hidden' name='Manual' value='yes'>
</form>

</div> <!-- full-page-block -->
ENDHTML

} #sub html_output_manual end

