#!/usr/bin/perl

use strict;
use DBI;
use MIME::Lite;
use Net::IP::XS;

require '../common.pl';
my $DB_IP_Allocation = DB_IP_Allocation();

my $Select_Block = $DB_IP_Allocation->prepare("SELECT `id`, `ip_block_name`, `ip_block`
FROM `ipv4_address_blocks`");

$Select_Block->execute();

&quick_loop;

sub quick_loop {

	LOOP: while ( my @DB_Block_Output = $Select_Block->fetchrow_array() )
	{

		my $ID = $DB_Block_Output[0];
		my $IP_Block_Name = $DB_Block_Output[1];
		my $IP_Block = $DB_Block_Output[2];

		my $IP_Allocation_Limit_Collection = new Net::IP::XS ($IP_Block) or die(print Net::IP::XS::Error);
			my $IP_Block_Limit=$IP_Allocation_Limit_Collection->last_ip();
				my $IP_Allocation_Limit_Execution = new Net::IP::XS ($IP_Block_Limit) or die(print Net::IP::XS::Error);
					my $IP_Block_Limit_Integer = $IP_Allocation_Limit_Execution->intip();

		my $Out_Of_Range_Blocks=0;
		my $Error_Blocks=0;
		my $Used_Blocks=0;
		my $Total_Blocks=0;
		my $Overlap_Blocks=0;
		my $Matching_Blocks=0;

		my $CIDR_Input = $IP_Block;
			$CIDR_Input =~ s/(^.*\/)(..$)/$2/;
			$Total_Blocks = cidr_check($CIDR_Input);

		$CIDR_Input = $IP_Block;
			$CIDR_Input =~ s/(^.*\/)(..$)/$2/;

		my $IP_Allocation = new Net::IP::XS ($IP_Block) or die(print Net::IP::XS::Error);

		my $IP=$IP_Block;

		while ( $IP != $IP_Block_Limit_Integer ) {

			$IP =~ s/\/..$//;
			$IP = $IP . "/" . $CIDR_Input;

			$IP_Allocation = new Net::IP::XS ($IP) or die(print Net::IP::XS::Error);

				my $Select_IP = $DB_IP_Allocation->prepare("SELECT `network_block`
				FROM `ipv4_allocations`
				WHERE `network_block` LIKE '$IP'");

				$Select_IP->execute();
				my $Rows = $Select_IP->rows();


				my $Add_CIDR_Loop = cidr_check($CIDR_Input);

				if ($Rows == 1) {
					$Matching_Blocks++;
					$Used_Blocks=$Used_Blocks+$Add_CIDR_Loop;
				}
				elsif ($Rows > 1) {
					$Error_Blocks++;
				}
				else {
					$Out_Of_Range_Blocks++;
				}

				$IP = $IP_Allocation->intip();
				$IP = $IP+$Add_CIDR_Loop;
			
				if (($IP > $IP_Block_Limit_Integer) && ($CIDR_Input < 32)) {
			
					print "In $IP_Block_Name ($IP_Block), there are $Matching_Blocks /$CIDR_Input"."'s used\n";
			
					$CIDR_Input++;
					$IP=$IP_Block;
			
					$Out_Of_Range_Blocks=0;
					$Error_Blocks=0;
					$Overlap_Blocks=0;
					$Matching_Blocks=0;
			
				}
				elsif (($IP > $IP_Block_Limit_Integer) && ($CIDR_Input = 32)) {
					print "In $IP_Block_Name ($IP_Block), there are $Matching_Blocks /$CIDR_Input"."'s used\n";
			
					print "Total: $Total_Blocks\n";
					print "Used: $Used_Blocks\n";
			
					$Used_Blocks = $Used_Blocks/$Total_Blocks*100;
			
					print "Percent Used: $Used_Blocks%\n\n";
			
					$DB_IP_Allocation->do("UPDATE `ipv4_address_blocks` SET 
					`percent_used` =  '$Used_Blocks'
					WHERE  `ipv4_address_blocks`.`id` = '$ID';");
					
					next LOOP;
				}
				else {
					my $Octet1=($IP/16777216)%256;
					my $Octet2=($IP/65536)%256;
					my $Octet3=($IP/256)%256;
					my $Octet4=$IP%256;
					$IP = $Octet1 . "." . $Octet2 . "." . $Octet3 . "." . $Octet4;
					$IP = $IP . "/" . $CIDR_Input;
				}

		}

	} # LOOP

} # sub quick_loop

sub cidr_check {

	my $CIDR_32='1';
	my $CIDR_31='2';
	my $CIDR_30='4';
	my $CIDR_29='8';
	my $CIDR_28='16';
	my $CIDR_27='32';
	my $CIDR_26='64';
	my $CIDR_25='128';
	my $CIDR_24='256';
	my $CIDR_23='512';
	my $CIDR_22='1024';
	my $CIDR_21='2048';
	my $CIDR_20='4096';
	
	my $CIDR_Input = shift(@_);
	my $Add_CIDR_Loop;

	if ($CIDR_Input == 32) {
		$Add_CIDR_Loop=$CIDR_32;
	}
	elsif ($CIDR_Input == 31) {
		$Add_CIDR_Loop=$CIDR_31;
	}
	elsif ($CIDR_Input == 30) {
		$Add_CIDR_Loop=$CIDR_30;
	}
	elsif ($CIDR_Input == 29) {
		$Add_CIDR_Loop=$CIDR_29;
	}
	elsif ($CIDR_Input == 28) {
		$Add_CIDR_Loop=$CIDR_28;
	}
	elsif ($CIDR_Input == 27) {
		$Add_CIDR_Loop=$CIDR_27;
	}
	elsif ($CIDR_Input == 26) {
		$Add_CIDR_Loop=$CIDR_26;
	}
	elsif ($CIDR_Input == 25) {
		$Add_CIDR_Loop=$CIDR_25;
	}
	elsif ($CIDR_Input == 24) {
		$Add_CIDR_Loop=$CIDR_24;
	}
	elsif ($CIDR_Input == 23) {
		$Add_CIDR_Loop=$CIDR_23;
	}
	elsif ($CIDR_Input == 22) {
		$Add_CIDR_Loop=$CIDR_22;
	}
	elsif ($CIDR_Input == 21) {
		$Add_CIDR_Loop=$CIDR_21;
	}
	elsif ($CIDR_Input == 20) {
		$Add_CIDR_Loop=$CIDR_20;
	}

return $Add_CIDR_Loop;

} # sub cidr_check

sub increase_octets {

	my ($IP, $IP_Allocation, $Add_CIDR_Loop, $IP_Block_Limit_Integer,
	$CIDR_Input, $IP_Block_Name, $IP_Block, $Out_Of_Range_Blocks, $Error_Blocks, 
	$Overlap_Blocks, $Matching_Blocks, $Total_Blocks, $Used_Blocks, $ID) = @_;

	$IP = $IP_Allocation->intip();
	$IP = $IP+$Add_CIDR_Loop;

	if (($IP > $IP_Block_Limit_Integer) && ($CIDR_Input < 32)) {

		print "In $IP_Block_Name ($IP_Block), there are $Matching_Blocks /$CIDR_Input"."'s used\n";

		$CIDR_Input++;
		$IP=$IP_Block;

		$Out_Of_Range_Blocks=0;
		$Error_Blocks=0;
		$Overlap_Blocks=0;
		$Matching_Blocks=0;

	}
	elsif (($IP > $IP_Block_Limit_Integer) && ($CIDR_Input = 32)) {
		print "In $IP_Block_Name ($IP_Block), there are $Matching_Blocks /$CIDR_Input"."'s used\n";

		print "Total: $Total_Blocks\n";
		print "Used: $Used_Blocks\n";

		$Used_Blocks = $Used_Blocks/$Total_Blocks*100;

		print "Percent Used: $Used_Blocks%\n\n";

		$DB_IP_Allocation->do("UPDATE `ipv4_address_blocks` SET 
		`percent_used` =  '$Used_Blocks'
		WHERE  `ipv4_address_blocks`.`id` = '$ID';");
		
		next OUTER;
	}
	else {
		my $Octet1=($IP/16777216)%256;
		my $Octet2=($IP/65536)%256;
		my $Octet3=($IP/256)%256;
		my $Octet4=$IP%256;
		$IP = $Octet1 . "." . $Octet2 . "." . $Octet3 . "." . $Octet4;
		$IP = $IP . "/" . $CIDR_Input;
	}


}	#increase_octets
