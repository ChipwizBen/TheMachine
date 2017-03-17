#!/usr/bin/perl -T

use strict;
use HTML::Table;

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $Header = Header();
my ($CGI, $Session, $Cookie) = CGI();

my $User_Name = $Session->param("User_Name");  

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

require $Header;
&html_output;

sub html_output {

	my $Table = new HTML::Table(
		-cols=>2,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'100%',
		-spacing=>0,
		-padding=>1
	);

	$Table->addRow( "Version", "Change" );
	$Table->setRowClass (1, 'tbrow1');

	## Version 2.3.0
	$Table->addRow('2.3.0', 'Fixed a bug where the D-Shell process would die if the SSH connection suddenly closed 
          after previously being open during the initial connection phase, including during a controlled reboot.');
	$Table->addRow('', 'Fixed an issue where a random SSH termination wasn\'t correctly handled by the CDSF distribution process.');
	$Table->addRow('', 'Restored the previous Command Set ownership model from before 2.0.2 as the main reason for hidden commands 
          (possible embedded private data in a Command Set) has been superseded by the functions provided by *VAR.');
	$Table->addRow('', 'Added better handing for mid-login errors during D-Shell SSH initialisation.');
	$Table->addRow('', 'Changed the naming of IP allocations to IP assignments for compatibility with RIPE definitions..');
	$Table->addRow('', 'Reduced value length from 45 to 18 for IP blocks in assignment DB.');
	$Table->addRow('', 'Introduced IPv6 assignment system.');
	$Table->addRow('', 'Changed snapshot delete CLI tag from -r to -d to reduce the risk of mixing up with -R (restore).');

	## Version 2.2.1
	$Table->addRow('2.2.1', 'Fixed an issue with the IP assignment system reporting the wrong block when full.');
	$Table->addRow('', 'Removed taint requirement from locally executed only scripts.');
	$Table->addRow('', 'Fixed missing formatting for variables in Command Sets.');
	$Table->addRow('', 'Added minor username tag for snapshot tracking.');
	$Table->addRow('', 'Fixed a bug related to correctly capturing hashes where the key or value ended in \'=\'.');
	$Table->addRow('', 'Fixed filter retention across pages.');
	$Table->addRow('', 'Fixed some block size display issues for /32 blocks. (now correctly uses parent block for some values).');
	$Table->addRow('', 'Fixed an issue passing multi-line variables when using a Windows based browser.');
	$Table->addRow('', 'Added some logic to determine if a system is a VM before performing a snapshot operation.');
	$Table->addRow('', 'Fixed some missing audit colours and standardised CSS colour names.');
	$Table->addRow('', 'Fixed a bug where commands with HTML in them would display as HTML instead of raw commands.');
	$Table->addRow('', 'Fixed an issue where temporary files were not cleaned up if hosts did not recover from a controlled reboot.');
	$Table->addRow('', 'Adjusted the Command Set Git push mechanism to substitute the *SUDO tag with a useful shell command.');
	$Table->addRow('', 'Fixed a greedy glob in the Command Set Dump process that was stripping spaces in some circumstances.');
	$Table->addRow('', 'Added a missing view mode for Redirects.');
	$Table->addRow('', 'Fixed some persistent filters for better usability when dealing with large numbers of redirects / reverse proxy entries.');
	$Table->addRow('', 'Modified some logic to find server names within aliases when bundling redirects together.');

	## Version 2.2.0
	$Table->addRow('2.2.0', 'Added handler for incorrect use of *WAITFOR and *SEND together in the same command.');
	$Table->addRow('', 'Added the ability to pause a Job indefinitely from within a Command Set.');
	$Table->addRow('', 'Changed the licence from GPLv3 to AGPLv3.');
	$Table->addRow('', 'Added the ability to pause all running or resume all paused Jobs.');
	$Table->addRow('', 'Fixed an issue with variables not being highlighted correctly.');
	$Table->addRow('', 'Fixed an issue that displayed resolved variables in commands which could include sensitive data.');
	$Table->addRow('', 'Generated Command Set dumps now include owner tags.');
	$Table->addRow('', 'Fixed a bug where if a Command Set owner was deleted the Command Set was not reassigned (now reassigned to System).');
	$Table->addRow('', 'Enforced Taint Mode. Several changes made to support this.');
	$Table->addRow('', 'Added option to Job Receiver to output IDs of queued Jobs.');
	$Table->addRow('', 'Fixed help output of Job Receiver.');
	$Table->addRow('', 'Fixed a fault with Jobs triggering as public key auth if the decoder tried to decode an unencoded password.');
	$Table->addRow('', 'Rewrote the snapshot system to use VMware\'s API. Added the ability to do restores and show snapshot trees.');
	$Table->addRow('<hr />', '');

	## Version 2.1.1
	$Table->addRow('2.1.0', 'Fixed formatting on command line help outputs on job receiver and executor.');
	$Table->addRow('---', '');

	## Version 2.1.0
	$Table->addRow('2.1.0', 'Fixed dropdown in Command Sets that didn\'t adhere to new owner display system.');
	$Table->addRow('', 'Changed a few icons for clarity.');
	$Table->addRow('', 'Squashed a race condition that caused Jobs to register as unexpectedly terminated when they had successfully finished.');
	$Table->addRow('', 'Fixed a bug where the Job receiver would die if a Job was queued but not run.');
	$Table->addRow('', 'Added ability to inject variables at runtime (triggered by *VAR{VarNameHere}).');
	$Table->addRow('<hr />', '');

	## Version 2.0.2
	$Table->addRow('2.0.2', 'Two Reboot checks merged into one for quicker response in Job Processor.');
	$Table->addRow('', 'Added ability to release build/distribution lock in System Status.');
	$Table->addRow('', 'Changed randomness to be blocking CSPRNG based for generated passwords and salts.');
	$Table->addRow('', 'Fixed fault in RNG display for salts.');
	$Table->addRow('', 'Fixed an issue where the first host type was selected when editing a host instead of the actual type.');
	$Table->addRow('', 'Performance improvements in both the DB and a handful of pages.');
	$Table->addRow('', 'Fixed an issue with highlighting being the same colour as the text for matching server aliases in ReverseProxy.');
	$Table->addRow('', 'Deleted configs are now correctly purged from Git.');
	$Table->addRow('', 'Configs are now handled individually when committing to Git to stop processes committing each others files.');
	$Table->addRow('', 'Fixed Command Set owner filter and improved user control of private Command Sets.');
	$Table->addRow('', 'Remembered to include checksums :).');
	$Table->addRow('---', '');

	## Version 2.0.1
	$Table->addRow('2.0.1', 'Clarified RMin/RMax (Range) in IP Sweep.');
	$Table->addRow('', 'Fixed an issue with Redirects overruling each other.');
	$Table->addRow('', 'Dropped legacy IP entry in Distribution Status.');
	$Table->addRow('', 'Fixed an issue where hosts without blocks still had () appear in Rules.');
	$Table->addRow('', 'Correctly handled broken fingerprint probe in D-Shell.');
	$Table->addRow('', 'Moved block discovery to common functions. Added block discovery to Jobs.');
	$Table->addRow('', 'Fixed a bug that prevented ID filtered hosts showing their blocks.');
	$Table->addRow('', 'Blocks for Hosts in a Host Group are now displayed, floating Blocks are flagged as a risk.');
	$Table->addRow('', 'Fixed an issue with the Jobs filter not working.');
	$Table->addRow('---', '');

	## Version 2.0.0
	$Table->addRow('2.0.0', 'DSMS repurposed as The Machine. Now includes IP assignment, DNS management, reverse proxy 
          management, sudoers management and Icinga management.');
	$Table->addRow('<hr />', '');

	## Version 1.10.0
	$Table->addRow('1.10.0', 'Added feedback system for hosts writing their own sudoers files (Last Successful Deployment).');
	$Table->addRow('', 'Banners are now suppressed during distribution to make stdout clearer.');
	$Table->addRow('<hr />', '');

	## Version 1.9.0
	$Table->addRow('1.9.0', 'Added host auto-registration process.');
	$Table->addRow('', 'Added \'Last Successful Transfer\' to Distribution Status.');
	$Table->addRow('', 'Added the ability to use DHCP clients.');
	$Table->addRow('', 'Fixed an alignment bug in Hosts and Sudo Users.');
	$Table->addRow('<hr />', '');

	## Version 1.8.1
	$Table->addRow('1.8.1', 'Correctly escaped special sudoers characters (:,=) when the sudoers file is built.');
	$Table->addRow('', 'Prevent escapes being added to commands.');
	$Table->addRow('', 'Fixed an issue with account modification time not being updated on change.');
	$Table->addRow('---', '');

	## Version 1.8.0
	$Table->addRow('1.8.0', 'Better error handling for failed SFTP connections.');
	$Table->addRow('', 'Formatting fixes for Groups and Rules.');
	$Table->addRow('', 'Command Alias accepted characters are now clearly defined in line with Hosts and Users.');
	$Table->addRow('', 'Password complexity requirements are now configurable in common.pl.');
	$Table->addRow('', 'System Status page implemented, which gives an overview of system settings and processes in 
          progress.');
	$Table->addRow('', 'New distribution locking mechanism prevents two distribution processes running at the same time. 
          Distribution lock is in addition to the existing build process lock.');
	$Table->addRow('', 'Items without notes now do not show an empty note table.');
	$Table->addRow('<hr />', '');

	## Version 1.7.0
	$Table->addRow('1.7.0', 'Added Automated DSMS System deployment process.');
	$Table->addRow('', 'Added the ability to allow some users read-only administrative rights.');
	$Table->addRow('', 'Made the Account Password Reset email use admin usernames and email addresses pulled from the 
          database, instead of using static values.');
	$Table->addRow('', 'Added the ability to specify a sending email address for password recovery emails.');
	$Table->addRow('<hr />', '');

	## Version 1.6.0
	$Table->addRow('1.6.0', 'Fixed a bug that stripped hyphens from hostnames. Also allowed user names to contain hyphens,
          periods and underscores to match POSIX requirements.');
	$Table->addRow('', 'Fixed a bug which allowed empty Groups to be added to the CDSF.');
	$Table->addRow('', 'Added an automated sudoers build locking mechanism to the DSMS System to prevent two build 
          processes running at the same time.');
	$Table->addRow('', 'Added ability to specify SFTP distribution port.');
	$Table->addRow('', 'Added Noting System.');
	$Table->addRow('<hr />', '');

	## Version 1.5.0
	$Table->addRow('1.5.0', 'Added MD5 checksum to Distribution Status for easier comparison with sudoers checksums 
          currently on different systems.');
	$Table->addRow('', 'Added option to specify port in DB connection string in \'common.pl\'.');
	$Table->addRow('', 'Added the ability to specify Unix System Groups (in addition the the existing Sudo Groups) 
          which are usually defined in /etc/group.');
	$Table->addRow('', 'Added display highlighting to differentiate between Sudo Groups and System Groups across 
          various screens.');
	$Table->addRow('', 'Made the sudoers special host \'ALL\' (meaning all hosts) a selectable option for Host Groups 
          and Hosts when attaching to a Rule.');
	$Table->addRow('', 'Made it possible to search for Rules using the Global Search tool.');
	$Table->addRow('', 'Made Expired Users/Hosts/Commands/Rules display as Expired instead of only Active/Inactive 
          in the Global Search tool.');
	$Table->addRow('', 'Fixed an array assignment bug where Commands searched for through the Global Search tool 
          always returned as Active.');
    $Table->addRow('', 'Tidied up formatting for descriptions below Add and Edit boxes - unordered lists and padding 
          is now standard across all input boxes with multi-line descriptions. 2pc left and right 
          padding is now 5px to better suit smaller screens.');
    $Table->addRow('', 'Added Upgrade.sql file to facilitate database upgrading from 1.4.1 to 1.5.0 without needing 
          to overwrite with the Full_Schema.sql');
    $Table->addRow('', 'Added Default_Users.sql file to simplify MySQL installation process.');
    $Table->addRow('', 'Changed environmental-variables to environmental-defaults to avoid confusion with shell 
          environmental variables.');
    $Table->addRow('', 'Changed Defaults Specification in environmential-variables to use the Red Hat Defaults.');
    $Table->addRow('', 'Added an additional \'Section Ends\' comment to the end of each type section to make them 
          clearer in very large sudoers files.');
    $Table->addRow('', 'Updated the syntax highlighting on \'index.cgi\' to clearly mark each section\'s start and end.');
    $Table->addRow('', 'New deployments will be shipped as .tar.gz files, as tar is installed on most Linux systems 
          by default, but unzip is not.');
    $Table->addRow('', 'README file has been dropped in favor of new full system installation and management 
          documentation.');
	$Table->addRow('', '$Remote_Sudoers default value in \'./common.pl\' updated with new path to reflect new SFTP chroot 
          recommendations, plus added option for relative paths.');
	$Table->addRow('', 'Added an extra error handler for distribution file push failures.');
	$Table->addRow('', 'Dropped sha1sum from system, as it duplicated tasks already performed by md5sum.');
	$Table->addRow('', 'Global Search now correctly displays 0 returned results when no matches are found.');
	$Table->addRow('', 'Added Rule approval auto-revocation when any attached items are modified or deleted.');
	$Table->addRow('', 'Added a Maintenance Mode to facilitate installations and upgrades. Maintenance Mode is 
          controlled through common.pl.');
	$Table->addRow('<hr />', '');

	## Version 1.4.1
	$Table->addRow('1.4.1', 'Offloaded the resolution of application paths to \'./common.pl\' through `which` or manual 
          override to make it more system independent.');
	$Table->addRow('', 'Bundled required non-core modules with package (for easier installation in offline 
          environments).');
	$Table->addRow('', 'Added recommended permissions (as a script) for files in README.');
	$Table->addRow('', 'Adjusted the way new hosts send audit messages when they\'re added to make it clearer that 
          they\'ve been added to the distribution list.');
	$Table->addRow('', 'Added fail-safe automatic restore for broken sudoers files with the latest stored valid one.');
	$Table->addRow('---', '');

	## Version 1.4.0
	$Table->addRow('1.4.0', 'Sudoers Distribution system is now in place through \'distribution.pl\'. Individual private 
          keys, timeouts, users and remote sudoers file paths can now be specified per host.');
	$Table->addRow('', 'Fail-safe Distribution default values are stored in \'./common.pl\' so that non-administrative 
          users cannot specify a remote host and overwrite an existing sudoers file, or SFTP to a 
          server using an existing key (depending on the defaults set).');
	$Table->addRow('', 'A new Distribution Status page is available to administrative users at 
          \'distribution-status.cgi\'. Here, you can also manually edit a host\'s custom connection 
          parameters and override the defaults.');
	$Table->addRow('', 'Newly created hosts are now added to the new distribution table and default fail-safe 
          parameters are set.');
	$Table->addRow('', 'Moved \'changelog.cgi\' out of the Management menu, because it isn\'t a management tool.');
	$Table->addRow('<hr />', '');

	## Version 1.3.1
	$Table->addRow('1.3.1', 'Fixed a bug in the audit section of the \'sudoers-build.pl\' file where each time the system 
          generated a new sudoers file it would log the successful build to the Audit Log. If 
          \'sudoers-build.pl\' was run from cron, a new audit entry would be created even if no changes 
          had been made to the system. Now, the system compares the checksum of the old and new files 
          and determines if a change has taken place before logging changes to the Audit Log.');
	$Table->addRow('', 'Added storage system for old sudoers files, appended by their checksum for easier 
          identification through the Audit Log.');
	$Table->addRow('', 'Added \'changelog.cgi\' so that this changelog can be viewed in the web panel.');
	$Table->addRow('', 'Fixed a bug in \'account-management.cgi\' where it logged an audit message that an edited 
          account was locked out, even if it wasn\'t.');
	$Table->addRow('---', '');

	## Version 1.3.0
	$Table->addRow('1.3.0', 'Added full Audit Log \'audit-log.cgi\'. Nearly all files 
	      have been modified to integrate with the new audit system.');
	$Table->addRow('', 'Added a password salting system to increase password security (against rainbow attacks) beyond the 
	      current SHA-512 hashing process to SHA-512 + 64 character salt.');
	$Table->addRow('', 'Some general interface changes to make things a bit tidier (particularly tables).');
	$Table->addRow('', 'Added MD5 and SHA1 checksum to sudoers file.');
	$Table->addRow('', 'Adjusted \'Sudoers Not Found\' to include links to referenced pages.');
	$Table->addRow('', 'Added helpful descriptions to \'./common.pl\' components.');
	$Table->addRow('', 'Renamed \'user-management.cgi\' to \'account-management.cgi\' to avoid confusing system users with 
	      sudo users. Updated \'header.cgi\' to reflect name change.');
	$Table->addRow('', 'Enforced the reservation of the \'System\' user name.');
	$Table->addRow('', 'Updated account requirements description to include notice of reserved \'System\' user name.');
	$Table->addRow('', 'Added better error handling of duplicate user name and email rejections for new and edited users.');
	$Table->addRow('', 'Fixed a bug where linked Hosts, Users and Commands were not correctly dropped from the link 
          table if they were deleted but still belonged to a Group or Rule.');
	$Table->addRow('', 'Fixed a bug where linked groups were not correctly dropped from the Rule to Group link table.');
	$Table->addRow('', 'Fixed a bug in \'account-management.cgi\' where an Admin that modified their own rights had their 
	      access stripped for the current session only and could not reach any administrative page without first logging out and back in.');
	$Table->addRow('', 'Added syntax highlighting for potentially dangerous commands (like *).');
	$Table->addRow('', 'Adjusted expiry column to fixed width because it was being squashed in Chrome (but not Firefox).');
	$Table->addRow('<hr />', '');

	## Version 1.2.2
	$Table->addRow('1.2.2', 'System now uses \'time\' epoch instead of \'localtime\' string for calculating expiry as the \'localtime\'
          output string varied and was unreliable for calculations. \'localtime\' remains in use for variables
          where a string time is specified (such as "$Date = strftime "%Y-%m-%d", localtime;").');
	$Table->addRow('---', '');
	## Version 1.2.1
	$Table->addRow('1.2.1', 'Reduced Date::Parse module requirement from Date::Parse to Date::Parse qw(str2time).');
	$Table->addRow('---', '');
	## Version 1.2.0
	$Table->addRow('1.2.0', 'Added expiry system. Hosts, Users, Commands, Groups and Rules 
	      can now be set to expire. Added Date::Parse to requirement list (see README).');
	$Table->addRow('<hr />', '');

	## Version 1.1.1
	$Table->addRow('1.1.1', 'Trimmed legacy files.');
	$Table->addRow('---', '');
	## Version 1.1.0
	$Table->addRow('1.1.0', 'Moved environmental variables from \'sudoers-build.pl\' to 
	      dedicated plain text \'environmental-variables\' file so users don\'t need to edit the sudoers-build.pl script.');
	$Table->addRow('<hr />', '');

	## Version 1.0.3
	$Table->addRow('1.0.3', 'Renamed from Sudoers Build System to Distributed Sudoers Management System to better describe 
	      the system\'s purpose.');
	$Table->addRow('', 'Modified \'login.cgi\', \'lockout.cgi\', \'header.cgi\' to pull name from new subroutine in \'./common.pl\' 
	      so the name can be easily edited to fit more easily into different customer environments.');
	$Table->addRow('', 'Added a short name (DSMS) subroutine to \'./common.pl\'.');
	$Table->addRow('---', '');
	## Version 1.0.2
	$Table->addRow('1.0.2', 'Added version numbering system to this file (hello!) and to \'./common.pl\'.');
	$Table->addRow('', 'Modified \'index.cgi\' to display version number.');
	$Table->addRow('---', '');
	## Version 1.0.1
	$Table->addRow('1.0.1', 'Fixed SQL bug in \'sudoers-commands.cgi\' which prevented Commands from being deleted.');
	$Table->addRow('---', '');
	## Version 1.0.0
	$Table->addRow('1.0.0', 'Initial release.');

$Table->setColAlign(1, 'center');

print <<ENDHTML;

<div id='full-page-block'>
<h2 style='text-align: center;'>System Changelog</h2>

$Table

</div>

ENDHTML

} #sub html_output

