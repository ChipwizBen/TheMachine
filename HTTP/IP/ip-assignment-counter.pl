#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);

use DBI;
use MIME::Lite;
use Net::IP::XS;

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $DB_Connection = DB_Connection();

&quick_loop;

sub quick_loop {

	my $Select_Block = $DB_Connection->prepare("SELECT `id`, `ip_block_name`, `ip_block`
	FROM `ipv4_blocks`");
	
	$Select_Block->execute();

	LOOP: while ( my @DB_Block_Output = $Select_Block->fetchrow_array() )
	{

		my $ID = $DB_Block_Output[0];
		my $IP_Block_Name = $DB_Block_Output[1];
		my $IP_Block = $DB_Block_Output[2];

		my $IP_Assignment_Limit_Collection = new Net::IP::XS ($IP_Block) or die(print Net::IP::XS::Error);
			my $IP_Block_Limit=$IP_Assignment_Limit_Collection->last_ip();
				my $IP_Assignment_Limit_Execution = new Net::IP::XS ($IP_Block_Limit) or die(print Net::IP::XS::Error);
					my $IP_Block_Limit_Integer = $IP_Assignment_Limit_Execution->intip();

		my $Out_Of_Range_Blocks=0;
		my $Error_Blocks=0;
		my $Used_Blocks=0;
		my $Total_Blocks=0;
		my $Overlap_Blocks=0;
		my $Matching_Blocks=0;

		my $CIDR_Input = $IP_Block;
			$CIDR_Input =~ s/(^.*\/)(..?$)/$2/;
			$Total_Blocks = cidr_check($CIDR_Input);

		$CIDR_Input = $IP_Block;
			$CIDR_Input =~ s/(^.*\/)(..?$)/$2/;

		my $IP_Assignment = new Net::IP::XS ($IP_Block) or die(print Net::IP::XS::Error);

		my $IP=$IP_Block;

		while ( $IP != $IP_Block_Limit_Integer ) {

			$IP =~ s/\/..?$//;
			$IP = $IP . "/" . $CIDR_Input;

			$IP_Assignment = new Net::IP::XS ($IP) or die(print Net::IP::XS::Error);

				my $Select_IP = $DB_Connection->prepare("SELECT `ip_block`
					FROM `ipv4_assignments`
					WHERE `ip_block` = '$IP'");

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

				$IP = $IP_Assignment->intip();
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
			
					my $Update_Percentages = $DB_Connection->prepare("UPDATE `ipv4_blocks` SET 
						`percent_used` =  ?
						WHERE  `id` = ?");
					$Update_Percentages->execute($Used_Blocks, $ID);
					
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
	my $CIDR_19='8192';
	my $CIDR_18='16384';
	my $CIDR_17='32768';
	my $CIDR_16='65536';
	my $CIDR_15='131072';
	my $CIDR_14='262144';
	my $CIDR_13='524288';
	my $CIDR_12='1048576';
	my $CIDR_11='2097152';
	my $CIDR_10='4194304';
	my $CIDR_9='8388608';
	my $CIDR_8='16777216';
	
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
	elsif ($CIDR_Input == 19) {
		$Add_CIDR_Loop=$CIDR_19;
	}
	elsif ($CIDR_Input == 18) {
		$Add_CIDR_Loop=$CIDR_18;
	}
	elsif ($CIDR_Input == 17) {
		$Add_CIDR_Loop=$CIDR_17;
	}
	elsif ($CIDR_Input == 16) {
		$Add_CIDR_Loop=$CIDR_16;
	}
	elsif ($CIDR_Input == 15) {
		$Add_CIDR_Loop=$CIDR_15;
	}
	elsif ($CIDR_Input == 14) {
		$Add_CIDR_Loop=$CIDR_14;
	}
	elsif ($CIDR_Input == 13) {
		$Add_CIDR_Loop=$CIDR_13;
	}
	elsif ($CIDR_Input == 12) {
		$Add_CIDR_Loop=$CIDR_12;
	}
	elsif ($CIDR_Input == 11) {
		$Add_CIDR_Loop=$CIDR_11;
	}
	elsif ($CIDR_Input == 10) {
		$Add_CIDR_Loop=$CIDR_10;
	}
	elsif ($CIDR_Input == 9) {
		$Add_CIDR_Loop=$CIDR_9;
	}
	elsif ($CIDR_Input == 8) {
		$Add_CIDR_Loop=$CIDR_8;
	}
	else {
		print "\n\n### Error in CIDR loop. CIDR is possibly bigger than /8 ###\n\n";
		exit(1);
	}

return $Add_CIDR_Loop;

} # sub cidr_check

