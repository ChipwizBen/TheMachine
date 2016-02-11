#!/usr/bin/perl

use strict;
use Net::SSH::Expect;
use Parallel::ForkManager;
use POSIX qw(strftime);

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $DB_DShell = DB_DShell();
my $Fork_Count = 10;
my $Debug = 1;

$| = 1;
my $Green = "\e[0;32;40m";
my $Yellow = "\e[0;33;40m";
my $Red = "\e[0;31;40m";
my $Clear = "\e[0m";

my @Hosts = ('wellshiny',  'schofieldbj');
#my @Hosts = ( 'schofieldbj');

my $SSH_Fork = new Parallel::ForkManager($Fork_Count);
	$SSH_Fork->run_on_start(
    	sub { my ($PID, $Host)=@_;
			print "D-Shell: $Host has started, PID: $PID.\n";
		}
	);
	$SSH_Fork->run_on_finish(
		sub {
			my ($PID, $Exit_Code, $Host) = @_;
			my $Notes;
			if ($Exit_Code == 1) {$Notes = ' (Regular command failure)'}
			if (($Exit_Code == 1000) || $Exit_Code == 232) {$Notes = ' (Failed on WAITFOR - probably no match found)'}
			if ($Exit_Code == 233) {$Notes = ' (Probably SSH authentication failure)'}
			if ($Exit_Code == 255) {$Notes = ' (SSH session died)'}
			print "D-Shell: $Host (PID:$PID) has finished. Exit code: $Exit_Code${Notes}.\n";
		}
	);

	my $Select_Commands = $DB_DShell->prepare("SELECT `id`, `name`, `command`
		FROM `command_sets`
		ORDER BY `name` ASC
	");

	$Select_Commands->execute();

	while ( my @Select_Commands = $Select_Commands->fetchrow_array() )
	{

		my $DBID = $Select_Commands[0];
		my $Command_Name = $Select_Commands[1];
		my $Commands = $Select_Commands[2];

		my @Commands = split('\r', $Commands);

		foreach my $Host (@Hosts) {

			my $Log_File = "/tmp/$Host";
			#my $PID = $SSH_Fork->start and next;
			my $PID = $SSH_Fork->start ($Host) and next;

			my $SSH = Net::SSH::Expect->new (
				host => "$Host",
				password=> '',
				user => 'schofieldbj', 
				log_file => "$Log_File",
				timeout => 1,
				exp_internal => 0,
				exp_debug => 0,
				raw_pty => 1
			);

			my $Login = $SSH->login(1);
			if ($Login !~ /Last/) {
				print "Could not login to $Host. Output was: $Login\n";
				$SSH_Fork->finish(233);
			}
			#$SSH->exec("stty raw -echo"); # Shows all remote command outputs on local console
			#$SSH->exec("stty -echo");

			my $Start_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
			system("echo 'Job started at $Start_Time.' >> $Log_File");

			COMMAND: foreach my $Command (@Commands) {
				$Command =~ s/\n//;
				$Command =~ s/\r//;
				my $Time_Stamp = strftime "%H:%M:%S", localtime;

				#while ( defined (my $Line = $SSH->read_all()) ) {print $Line} # Keeps the text flowing

				if (($Command =~ /^#/) || ($Command eq undef)) {
					if ($Debug == 1) {
						system("echo '${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Skipping comment/empty line $Command${Clear}\n' >> $Log_File");
						print "${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Skipping comment/empty line $Command${Clear}\n";
        			}
					next;
				}
				elsif ($Command =~ /^\*PAUSE.*/) {
					my $Pause = $Command;
					$Pause =~ s/\*PAUSE (.*)/$1/;
					if ($Debug == 1) {
						system("echo '${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Pausing for ${Yellow}$Pause ${Green}seconds on $Host${Clear}\n' >> $Log_File");
						print "${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Pausing for ${Yellow}$Pause ${Green}seconds on $Host${Clear}\n";
					}
					sleep $Pause;
				}
				elsif ($Command =~ /^\*WAITFOR.*/) {
					my $Wait_Timeout = 120;
					my $Wait = $Command;
					if ($Wait =~ m/^\*WAITFOR\d/) {
						$Wait_Timeout = $Wait;
						$Wait_Timeout =~ s/^\*WAITFOR(\d*) (.*)/$1/;
						$Wait =~ s/^\*WAITFOR(\d*) (.*)/$2/;
					}
					else {
						$Wait =~ s/\*WAITFOR (.*)/$1/;
					}
					
					if ($Debug == 1) {
						system("echo '${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Waiting for the prompt ${Yellow}$Wait ${Green}for ${Yellow}$Wait_Timeout ${Green}seconds on $Host${Clear}\n' >> $Log_File");
						print "${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Waiting for the prompt ${Yellow}$Wait ${Green}for ${Yellow}$Wait_Timeout ${Green}seconds on $Host${Clear}\n";
					}
					my $Match;
					while ( defined (my $Line = $SSH->read_line()) ) {
						$Match = $SSH->waitfor(".*$Wait.*", $Wait_Timeout, '-re');
						if ($Match) {
							if ($Debug == 1) {
								$Time_Stamp = strftime "%H:%M:%S", localtime;
								system("echo '${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Found match for ${Yellow}$Wait ${Green}on $Host${Clear}\n' >> $Log_File");
								print "${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Found match for ${Yellow}$Wait ${Green}on $Host${Clear}\n";
							}
							next COMMAND;
						}
						else {
							system("echo '${Red}No match for '$Wait' after $Wait_Timeout seconds. Closing the SSH session for $Host.${Clear}\n' >> $Log_File");
							print "${Red}No match for '$Wait' after $Wait_Timeout seconds. Closing the SSH session for $Host.${Clear}\n";
							$SSH->close();
							$SSH_Fork->finish(1000);
						}
					}
				}
				elsif ($Command =~ /^\*SEND.*/) {
					my $Send = $Command;
					$Send =~ s/\*SEND (.*)/$1/;
					if ($Debug == 1) {
						system("echo '${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Sending ${Yellow}$Send ${Green}to $Host${Clear}\n' >> $Log_File");
						print "${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Sending ${Yellow}$Send ${Green}to $Host${Clear}\n";
					}
					$SSH->send($Send);
				}
				else {
					if ($Debug == 1) {
						system("echo '${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Command ${Green}on $Host${Clear}\n' >> $Log_File");
						print "${Red}## Debug (PID:$$) $Time_Stamp ## ${Green}Running ${Yellow}$Command ${Green}on $Host${Clear}\n";
					}
					my $Command_Timeout = '3';
					$SSH->exec($Command, $Command_Timeout);
					my $EC = $SSH->exec('echo $?', $Command_Timeout);
						print "Exit code for $Command: $EC\n";
				}

			}
			
			$SSH->close();
			$SSH_Fork->finish;

			my $End_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;
			system("echo 'Job ended at $End_Time.' >> $Log_File");
		}
		
		$SSH_Fork->wait_all_children;
		print "All servers have completed their tasks!\n";
	}
	
1;