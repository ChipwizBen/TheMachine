#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);
delete $ENV{PATH};
$ENV{PATH} = '/usr/bin';

&Maintenance_Mode;

sub Maintenance_Mode {

	# This is a system toggle to turn on or off Maintenance Mode. When Maintenance Mode is on, users are prevented from making system changes, or accessing the system.

	my $Maintenance_Mode = 'Off';

	my ($CGI, $Session, $Cookie) = CGI();
	if ($Maintenance_Mode =~ /on/i) {
		print $CGI->redirect("/maintenance.cgi");
		exit(0);
	}

} # sub Maintenance_Mode

sub System_Name {

	# This is the system's name, used for system identification during login, written to the sudoers file to identify which system owns the sudoers file, is used in password reset emails to identify the source, and other general uses.

	my $System_Name = 'The Machine';
	return $System_Name;

} # sub System_Name

sub System_Short_Name {

	# This is the system's shortened name, which is used in short descriptions. It can be the same as the full name in System_Name if you want, but it might get busy on some screens if your system name is long.
	# THERE SHOULD BE NO SPACES OR SPECIAL CHARACTERS. It's also encouraged to keep this short (less than 10 characters).

	my $System_Short_Name = 'TheMachine';
	return $System_Short_Name;

} # sub System_Short_Name

sub Verbose {

	# Turns on verbose mode without having to directly trigger this on individual components
	# Default is 0

	my $Verbose = 1;
	return $Verbose;

} # sub Verbose

sub Very_Verbose {

	# Turns on very verbose mode without having to directly trigger this on individual components
	# Very verbose means very verbose. You have been warned...
	# Default is 0 

	my $Very_Verbose = 0;
	return $Very_Verbose;

} # sub Very_Verbose

sub Paper_Trail {

	# Turns on the paper trail. This will log all parameters INCLUDING PASSWORDS. Should ONLY be used for debugging.
	# For extra safety, also requires verbose to be explicitly turned on.
	# Default is 0 

	my $Paper_Trail = 0;
	return $Paper_Trail;

} # sub Paper_Trail

sub System_Log_File {

	# This is the system log file. This is where some system log and paper trail entires go.

	my $System_Log_File = '/var/log/TheMachine/System.log';
	return $System_Log_File;

} # sub System_Log_File

sub Security_Notice {

	my $Notice = $_[0];
	my $Remote_Host = $_[1];
	my $Script = $_[2];
	my $Value = $_[3];
	my $User_Name = $_[4];

	# Audit Log
	my $DB_Connection = DB_Connection();
	my $Audit_Log_Submission = Audit_Log_Submission();

	$Audit_Log_Submission->execute("Security", $Notice, "Received tainted data ($Value) at $Script by $User_Name from $Remote_Host.", 'System');
	#/ Audit Log

	my ($CGI, $Session, $Cookie) = CGI();
	my $Message_Red="Not accepting '$Value' for that. Submit a bug report if you think this may be a valid input.";
	$Session->param('Message_Red', $Message_Red);
	$Session->flush();
	if ($ENV{HTTP_REFERER}) {print "Location: $ENV{HTTP_REFERER}\n\n";} else {print "Location: /index.cgi\n\n";}
	exit(0);
}

sub Header {

	my $Header;
	if (-f "./header.cgi") {$Header = "./header.cgi";} else {$Header = "../header.cgi";}
	return $Header;
	
} # sub Header

sub Footer {

	my $Footer;
	if (-f "./footer.cgi") {$Footer = "./footer.cgi";} else {$Footer = "../footer.cgi";}
	return $Footer;
	
} # sub Footer

sub DNS_Server {

	# By setting a DNS server here, it will override the operating system's DNS server when doing lookups
	
	my $DNS_Server = '';
	return $DNS_Server;

} # sub DNS_Server

sub LDAP_Login {

	# These are the connection parameters for LDAP / Active Directory. If you disable this, the system will use internal authentication.

	my $LDAP_Enabled = 'Off'; # Set this to 'Off' to disable LDAP/AD authentication

	my $LDAP_Server = '';
	my $LDAP_Port = 389;
	my $LDAP_Timeout = 5;
	my $LDAP_User_Name_Prefix = '';
	my $LDAP_Filter = '';
	my $LDAP_Search_Base = '';

	# ---- Do not edit vaules below this line ---- #

	my $LDAP_Query = $_[0];
	if ($LDAP_Query eq 'Status_Check') {
		return $LDAP_Enabled;
		exit(0);
	}
	elsif ($LDAP_Query eq 'Parameters') {
		my @Parameters = ($LDAP_Server, $LDAP_Port, $LDAP_Timeout, $LDAP_User_Name_Prefix, $LDAP_Filter, $LDAP_Search_Base);
		return @Parameters;
		exit(0);
	}
	elsif ($LDAP_Enabled =~ /on/i) {

		my $LDAP_User_Name = $_[0];
			my $LDAP_User_Name_Prefixed = $LDAP_User_Name_Prefix.$LDAP_User_Name;
		my $LDAP_Password = $_[1];

		use Net::LDAP;
		my $LDAP_Connection = Net::LDAP->new(
			$LDAP_Server,
			port => $LDAP_Port,
			timeout => $LDAP_Timeout,
			start_tls => 1,
			#filter => $LDAP_Filter,
		) or return "Can't connect to LDAP server $LDAP_Server:$LDAP_Port with timeout $LDAP_Timeout seconds. $@";
		my $Bind = $LDAP_Connection->bind(
			$LDAP_User_Name_Prefixed,
			password => $LDAP_Password,
			);

		my $Authentication_Outcome = sprintf("%s",$Bind->error);

		if ( $Authentication_Outcome =~ /Success/ ) {

			 my $Get_User_Details = $LDAP_Connection->search(
			 	base   => $LDAP_Search_Base,
			 	filter => "(uid=$LDAP_User_Name)"
			 );

			die $Get_User_Details->error if $Get_User_Details->code;

			my $Display_Name;
			my $Email;
			foreach my $User_Values ($Get_User_Details->entries) {

				$Display_Name = $User_Values->get_value("displayName");
				$Email = $User_Values->get_value("mail");
			}

				$LDAP_Connection->unbind;
				return "Success,$Display_Name,$Email"; 

		}
		$LDAP_Connection->unbind;
	}
	else {
		return 'Off';
	}

} # sub LDAP_Login

sub Recovery_Email_Address {

	# This is the email address that the system will appear to send emails from during password recoveries. It may be a legitimate address (such as the system administrator's address) or it could be a blocking address, such as noreply@nwk1.com.

	my $Recovery_Email_Address = 'noreply@nwk1.com';
	return $Recovery_Email_Address;

} # sub System_Short_Name

sub Sudoers_Location {

	# This is not necessarily the location of the /etc/sudoers file. This is the path that the system writes the temporary sudoers file to. It could be /etc/sudoers, but you ought to consider the rights that Apache will need to overwrite that file, and the implications of giving Apache those rights. If you want to automate it end to end, you should consider writing a temporary sudoers file, then using a separate root cron job to overwrite /etc/sudoers, which is the recommended procedure, instead of directly writing to it. Of course, if you do not intend on using the DSMS system to manage /etc/sudoers on the local machine, then this should NOT be /etc/sudoers. For sudoers locations on remote machines, see Distribution_Defaults, or set individual remote sudoers locations through the web panel.

	my $Sudoers_Location = '../sudoers';
	return $Sudoers_Location;

} # sub Sudoers_Location

sub Sudoers_Storage {

	# This is the directory where replaced sudoers files are stored. You do not need a trailing slash.

	my $Sudoers_Storage = '../Storage/DSMS';
	return $Sudoers_Storage;

} # sub Sudoers_Storage

sub Sudoers_Owner_ID {

	# For changing the ownership of the sudoers file after it's created, we need to specify an owner. It is recommended to keep this as the default, which is ‘root’.

	my $Owner = 'root';

	if ($_[0] eq 'Full') {
		# To return ownership name for system status.
		return $Owner;
		exit(0);
	}

	my $Owner_ID = getpwnam $Owner;
	return $Owner_ID;

} # sub Sudoers_Owner_ID

sub Sudoers_Group_ID {

	# For chowning sudoers after it's created, perl's chown needs a group ID. I could've 
	# hard-coded this to use apache, but sometimes Apache Server doesn't run under apache 
	# (like when it runs as httpd), so here you can specify a different group user.

	my $Group = 'apache';

	if ($_[0] eq 'Full') {
		# To return group ownership name for system status.
		return $Group;
		exit(0);
	}

	my $Group_ID = getpwnam $Group;
	return $Group_ID;

} # sub Sudoers_Group_ID

sub Distribution_Log_Location {

	# This is the log location for the distribution system. You do not need a trailing slash.

	my $Distribution_Log_Location = '/var/log/TheMachine/Distribution.log';
	return $Distribution_Log_Location;

} # sub Distribution_Log_Location

sub Distribution_tmp_Location {

	# This is the directory where temporary files are are stored. You do not need a trailing slash.

	my $Distribution_tmp_Location = '../Storage/tmp/Distribution';
	return $Distribution_tmp_Location;

} # sub Distribution_tmp_Location

sub DNS_Zone_Master_File {

	# This is the zone master file use for defining zones.

	my $DNS_Zone_Master_File = '/etc/bind/named.conf.local';
	return $DNS_Zone_Master_File;

} # sub DNS_Zone_Master_File

sub DNS_Internal_Location {

	# This is the path that the system writes the temporary Internal DNS files to, before it is picked up by cron.
	# If this server is the master DNS server, this path could be the path to the DNS config.

	my $DNS_Internal_Location = '/etc/bind/master';
	return $DNS_Internal_Location;

} # sub DNS_Internal_Location

sub DNS_External_Location {

	# This is the path that the system writes the temporary External DNS files to, before it is picked up by cron.
	# If this server is the master DNS server, this path could be the path to the DNS config.

	my $DNS_External_Location = '/etc/bind/master';
	return $DNS_External_Location;

} # sub DNS_External_Location

sub DNS_Internal_SOA {

	# This is the SOA data that's written at the top of the Internal DNS file. 
	# It's recommended to keep the serial as is. Do not remove the <DOMAIN> tag.

	my $Email = 'postmaster@nwk1.com';
	my $TTL = '86400';			# 1 day
	my $Serial = `date +%s`; 	# Epoch
		$Serial =~ s/\n//;
	my $Refresh = '10800'; 		# 3 hours
	my $Retry = '3600'; 		# 1 hour
	my $Expire = '2419200'; 	# 4 weeks
	my $Minimum = '86400'; 		# 1 day
	my $NS1 = 'ns1.nwk1.com';
	my $NS2 = 'ns2.nwk1.com';
	my $NS3 = 'ns3.nwk1.com';

	# Do not edit anything below this line #

	my $SOA_Query = $_[0];
	if ($SOA_Query eq 'Parameters') {
		my @Parameters = ($Email, $TTL, $Serial, $Refresh, $Retry, $Expire, $Minimum, $NS1, $NS2, $NS3);
		return @Parameters;
		exit(0);
	}
	else {
		my ($N1, $N2, $N3);
		if ($NS1) {$N1 = "@	IN	NS	$NS1."}
		if ($NS2) {$N2 = "@	IN	NS	$NS2."}
		if ($NS3) {$N3 = "@	IN	NS	$NS3."}

		my $DNS_Internal_SOA = <<SOA;
\$TTL $TTL
@	IN	SOA	$NS1.	$Email. (
			$Serial
			$Refresh
			$Retry
			$Expire
			$Minimum
		)
$N1
$N2
$N3

SOA
		return $DNS_Internal_SOA;
	}

} # sub DNS_Internal_SOA

sub DNS_External_SOA {

	# This is the SOA data that's written at the top of the External DNS file.
	# It's recommended to keep the serial as is. Do not remove the <DOMAIN> tag.

	my $Email = 'postmaster@nwk1.com';
	my $TTL = '86400';			# 1 day
	my $Serial = `date +%s`; 	# Epoch
		$Serial =~ s/\n//;
	my $Refresh = '10800'; 		# 3 hours
	my $Retry = '3600'; 		# 1 hour
	my $Expire = '2419200'; 	# 4 weeks
	my $Minimum = '86400'; 		# 1 day
	my $NS1 = 'ns1.nwk1.com';
	my $NS2 = 'ns2.nwk1.com';
	my $NS3 = 'ns3.nwk1.com';
	
	# Do not edit anything below this line #

	my $SOA_Query = $_[0];
	if ($SOA_Query eq 'Parameters') {
		my @Parameters = ($Email, $TTL, $Serial, $Refresh, $Retry, $Expire, $Minimum, $NS1, $NS2, $NS3);
		return @Parameters;
		exit(0);
	}
	else {

		my ($N1, $N2, $N3);
		if ($NS1) {$N1 = "@	IN	NS	$NS1."}
		if ($NS2) {$N2 = "@	IN	NS	$NS2."}
		if ($NS3) {$N3 = "@	IN	NS	$NS3."}
	
		my $DNS_External_SOA = <<SOA;
\$TTL $TTL
@	IN	SOA	$NS1.	$Email. (
			$Serial
			$Refresh
			$Retry
			$Expire
			$Minimum
		)
$N1
$N2
$N3

SOA
		return $DNS_External_SOA;
	}

} # sub DNS_External_SOA

sub DNS_Storage {

	# This is the directory where replaced DNS files are stored. You do not need a trailing slash.

	my $DNS_Storage = '../Storage/DNS';
	return $DNS_Storage;

} # sub DNS_Storage

sub DNS_Owner_ID {

	# For changing the ownership of the DNS file after it's created, we need to specify an owner. It is recommended to keep this as the default, which is ‘root’.

	my $Owner = 'root';

	if ($_[0] eq 'Full') {
		# To return ownership name for system status.
		return $Owner;
		exit(0);
	}

	my $Owner_ID = getpwnam $Owner;
	return $Owner_ID;

} # sub DNS_Owner_ID

sub DNS_Group_ID {

	# For chowning DNS after it's created, perl's chown needs a group ID.

	my $Group = 'bind';

	if ($_[0] eq 'Full') {
		# To return group ownership name for system status.
		return $Group;
		exit(0);
	}

	my $Group_ID = getpwnam $Group;
	return $Group_ID;

} # sub DNS_Group_ID

sub Reverse_Proxy_Location {

	# This is the path that the system writes the temporary reverse proxy files to, before it is picked up by cron.
	# If this server is the master reverse proxy server, this path could be the path to the reverse proxy config.

	my $Reverse_Proxy_Location = '../Storage/tmp/ReverseProxy';
	return $Reverse_Proxy_Location;

} # sub Reverse_Proxy_Location

sub Proxy_Redirect_Location {

	# This is the path that the system writes the temporary proxy redirect files to, before it is picked up by cron.
	# If this server is the master reverse proxy server, this path could be the path to the proxy redirect config.

	my $Proxy_Redirect_Location = '../Storage/tmp/ReverseProxy';
	return $Proxy_Redirect_Location;

} # sub Proxy_Redirect_Location

sub Reverse_Proxy_Storage {

	# This is the directory where replaced reverse proxy files are stored. You do not need a trailing slash.

	my $Reverse_Proxy_Storage = '../Storage/ReverseProxy';
	return $Reverse_Proxy_Storage;

} # sub Reverse_Proxy_Storage

sub Proxy_Redirect_Storage {

	# This is the directory where replaced proxy redirect files are stored. You do not need a trailing slash.

	my $Proxy_Redirect_Storage = '../Storage/ReverseProxy';
	return $Proxy_Redirect_Storage;

} # sub Proxy_Redirect_Storage

sub DShell_Job_Log_Location {

	# This is the directory where job logs are stored. You do not need a trailing slash.

	my $DShell_Job_Log_Location = '../Storage/D-Shell/Job-Log';
	return $DShell_Job_Log_Location;

} # sub DShell_Job_Log_Location

sub DShell_tmp_Location {

	# This is the directory where temporary files are are stored. You do not need a trailing slash.

	my $DShell_tmp_Location = '../Storage/D-Shell/tmp';
	return $DShell_tmp_Location;

} # sub DShell_tmp_Location

sub DShell_WaitFor_Timeout {

	# The default time that a *WAITFOR statement will wait before bailing out. Can be overridden manually by issuing *WAITFORnn, where nn is the timeout in seconds. nn can be any number.

	my $DShell_WaitFor_Timeout = 1800; # 30 minutes
	return $DShell_WaitFor_Timeout;

} # sub DShell_WaitFor_Timeout

sub DShell_Queue_Execution_Cap {

	# The default number of threads available to D-Shell. If more jobs are submitted than this they will be queued until previous jobs have finished processing. The queue is first in, first out.

	my $DShell_Queue_Execution_Cap = 10;
	return $DShell_Queue_Execution_Cap;

} # sub DShell_Queue_Execution_Cap

sub DB_Connection {

	# This is your database's connection information.

	use DBI;

	my $DB_Host = '';
	my $DB_Port = '';
	my $DB_Name = '';
	my $DB_User = '';
	my $DB_Password = '';

	my $DB_Connection = DBI->connect("DBI:mysql:database=$DB_Name:host=$DB_Host:port=$DB_Port",
		$DB_User,
		$DB_Password,
		{mysql_enable_utf8 => 1})
		or die "Can't connect to database: $DBI::errstr\n";
	return $DB_Connection;

} # sub DB_Connection

sub Git_Link {

	# This is where you configure your link to Git, if required.

	my $Use_Git = 'No'; # If you wish to use Git, set this to yes.

	my $Git_Bin_Path = git(); # This is the binary to Git on your system (typically /usr/bin/git).
	my $Git_Directory = '../Storage/Git'; # This is the local repo location. You do not need a trailing slash.

	# Do not edit below this line.

	my $Git_Query = $_[0];
	if ($Git_Query eq 'Status_Check') {
		return $Use_Git;
	}
	elsif ($Git_Query eq 'Directory') {
		return $Git_Directory;
	}

	if ($Use_Git !~ /Yes/i) {
		return 0;
	}

	use Git::Wrapper;
	eval {
		my $Git_Connection = Git::Wrapper->new({
			dir => $Git_Directory,
			git_binary => $Git_Bin_Path
		});
	}
} # sub Git_Link

sub Git_Locations {

	my $Redirect = 'Redirect';
	my $ReverseProxy = 'ReverseProxy';
	my $CommandSets = 'CommandSets';
	my $DSMS = 'DSMS';

	## Do not edit below here

	my $Git_Query = $_[0];

	my $Git_Directory = Git_Link('Directory');

	if ($Git_Query eq 'Redirect') {
		$Git_Directory = "$Git_Directory/$Redirect";
		return $Git_Directory;
	}
	elsif ($Git_Query eq 'ReverseProxy') {
		$Git_Directory = "$Git_Directory/$ReverseProxy";
		return $Git_Directory;
	}
	elsif ($Git_Query eq 'CommandSets') {
		$Git_Directory = "$Git_Directory/$CommandSets";
		return $Git_Directory;
	}
	elsif ($Git_Query eq 'DSMS') {
		$Git_Directory = "$Git_Directory/$DSMS";
		return $Git_Directory;
	}

} # sub Git_Locations

sub Git_Commit {

	# Nothing for you to configure in here.

	my $Use_Git = Git_Link('Status_Check');
	if ($Use_Git !~ /Yes/i) {
		return 0;
	}

	my $Commit_All;
	my $File = $_[0];
		if ($File =~ /^..\/Storage/) {$File =~ s/^..\/Storage\/Git\///;}
		if ($File =~ m/\*$/) {
			$File =~ s/(.*)\*$/$1/;
			$Commit_All = 1;
		};
	my $Message = $_[1];
	my $Date = $_[2];
	my $Author = $_[3];

	my $Git_Link = Git_Link();

	if ($File eq 'Push') {
		eval {$Git_Link->push();}; print "Broke at git push: $@\n" if $@;
	}
	else {
		my $DB_Connection = DB_Connection();
		my $Select_User = $DB_Connection->prepare("SELECT  `email`
		FROM `credentials`
		WHERE `username` = ?");
		$Select_User->execute($Author);
		my $Email = $Select_User->fetchrow_array();

		if (!$Date) {
			use POSIX qw(strftime);
			$Date = strftime "%Y-%m-%d %H:%M:%S", localtime;
		}
		if (!$Author) {
			$Author = 'The Machine';
		}

		eval { $Git_Link->add($File); }; #print "Broke at git add $File: $@\n" if $@;
		eval { $Git_Link->commit(qw/ --message /, "$Message", qw/ --author /, "$Author <$Email>", qw/ --date /, "$Date", qw/ -- /, "$File"); }; #print "Broke at git commit $File: $@\n" if $@;


#		my $Audit_Log_Submission = Audit_Log_Submission();
#		$Audit_Log_Submission->execute("Git", "Commit", "Committed $Message", "$Author");

	}

	return 0;

} # sub Git_Commit

sub VMware_Connection {

	# These are the credentials used to connect to VMware's API. The usual SDK API address format is 
	# https://vcenter-hostname/sdkvimService.wsdl but you can just supply https://vcenter-hostname and 
	# the rest normally is calculated.

	# If you are using the VMware API to control snapshots, uncomment the next line.
	#use VMware::VIRuntime;
	
	my $vSphere_Server = '';
	my $vSphere_Username = '';
	my $vSphere_Password = '';

	my @VMware_Connection = ($vSphere_Server, $vSphere_Username, $vSphere_Password);
	return @VMware_Connection;

} # sub VMware_Connection

sub Reverse_Proxy_Defaults {

	# These are the default reverse proxy values for entries without custom parameters.

	my $Transfer_Log = '/var/log/httpd/access.log';
	my $Error_Log = '/var/log/httpd/error.log';
	my $SSL_Certificate_File = '/etc/ssl/ssl-wildcard/wildcard.crt';
	my $SSL_Certificate_Key_File = '/etc/ssl/ssl-wildcard/wildcard.key';
	my $SSL_CA_Certificate_File = '/etc/ssl/ssl-wildcard/CA_Bundle.pem';

	my @Reverse_Proxy_Defaults = ($Transfer_Log, $Error_Log, $SSL_Certificate_File, $SSL_Certificate_Key_File, $SSL_CA_Certificate_File);

} # sub Reverse_Proxy_Defaults

sub Redirect_Defaults {

	# These are the default proxy redirect values for entries without custom parameters.

	my $Transfer_Log = '/var/log/httpd/access.log';
	my $Error_Log = '/var/log/httpd/error.log';

	my @Redirect_Defaults = ($Transfer_Log, $Error_Log);

} # sub Redirect_Defaults

sub Distribution_Defaults {

	# These are the default sudoers distribution settings for new hosts. Keep in mind that any active host is automatically tried for sudoers pushes with their distribution settings. Unless you are confident that all new hosts will have the same settings, you might want to set fail-safe defaults here and manually override each host individually on the Distribution Status page.
	# A good fail-safe strategy would be to set $Key_Path to be /dev/null so that login to the Remote Server becomes impossible. Alternatively, another good method would be to set $Remote_Sudoers to /sudoers/sudoers (which reflects the chroot recommendations), so that you could accurately test remote login, but not affect the existing sudoers file at /etc/sudoers. This is also dependent on your Cron Configuration on the Remote Server.


	my $Distribution_SFTP_Port = '22'; # Default SFTP port
	my $Distribution_User = 'transport'; # Default SFTP user
	my $Key_Path = '/root/.ssh/id_rsa'; # Default private key path
	my $Timeout = '15'; # Default stalled connection Timeout in seconds
	my $Remote_Sudoers = 'upload/sudoers'; # Default sudoers file location on remote systems, if using chroot use a relative path

	my @Distribution_Defaults = ($Distribution_SFTP_Port, $Distribution_User, $Key_Path, $Timeout, $Remote_Sudoers);
	return @Distribution_Defaults;

} # sub Distribution_Defaults

sub Password_Complexity_Check {

	# Here you can set minimum requirements for password complexity and control whether password complexity is enforced. Take particular care with the special character section if you choose to define a single quote (') as a special character as this may prematurely close the value definition. To define a single quote, you must use the character escape, backslash (\), which should result in the single quote special character definition like this (\'), less the brackets. The space character is pre-defined by default at the end of the string and does not need escaping.

	my $Enforce_Complexity_Requirements = 'Yes'; # Set to Yes to enforce complexity requirements, or No to turn complexity requirements off for passwords
	my $Minimum_Length = 8; # Minimuim password length
	my $Minimum_Upper_Case_Characters = 2; # Minimum upper case characters required (can be 0)
	my $Minimum_Lower_Case_Characters = 2; # Minimum lower case characters required (can be 0)
	my $Minimum_Digits = 2; # Minimum digits required (can be 0)
	my $Minimum_Special_Characters = 2; # Minimum special characters (can be 0)
	my $Special_Characters = '!@#$%^&*()[]{}-_+=/\,.<>" '; # Define special characters (you can define a single quote as a special character, but escape it with \')

	# Do not edit Password_Complexity_Check beyond here

	if ($Enforce_Complexity_Requirements !~ /Yes/i) {
		return 0;
	}

	my $Password = $_[0];


	my $Length = length($Password);
	if ($Length < $Minimum_Length) {
		return 1;
	}

	my $Upper_Case_Count = 0;
	my $Lower_Case_Count = 0;
	my $Digit_Count = 0;
	my $Special_Count = 0;

	if ($Password eq 'Wn&sCvaG%!nvz}pb|#.pNzMe~I76fRx9m;a1|9wPYNQw4$u"w^]YA5WXr2b>bzyZzNKczDt~K5VHuDe~kX5mm=Ke:U5M9#g9PylHiSO$ob2-/Oc;=j#-KHuQj&#5fA,K_k$J\sSZup3<22MpK<>J|Ptp.r"h6') {
		# This section is to specifically reply to polls for complexity requirement information for system status.
		my @Password_Requirements = (
			$Enforce_Complexity_Requirements,
			$Minimum_Length,
			$Minimum_Upper_Case_Characters,
			$Minimum_Lower_Case_Characters,
			$Minimum_Digits,
			$Minimum_Special_Characters,
			$Special_Characters);
		return @Password_Requirements;
		exit(0);
	}

	my @Password = split('',$Password);
	
	my @Required_Special_Characters = split('',$Special_Characters);
	
	foreach my $Password_Character (@Password) {
		if ($Password_Character =~ /[A-Z]/) {$Upper_Case_Count++;}
		elsif ($Password_Character =~ /[a-z]/) {$Lower_Case_Count++;}
		elsif ($Password_Character =~ /[0-9]/) {$Digit_Count++;}
		else {
			foreach my $Special_Character (@Required_Special_Characters)
			{
				if ($Password_Character =~ /\Q$Special_Character/) {$Special_Count++;}
			}
		}
	}

	if ($Upper_Case_Count < $Minimum_Upper_Case_Characters) {return 2;}
	if ($Lower_Case_Count < $Minimum_Lower_Case_Characters) {return 3;}
	if ($Digit_Count < $Minimum_Digits) {return 4;}
	if ($Special_Count < $Minimum_Special_Characters) {return 5;}
	
	return 0;

} # Password_Complexity_Check

sub CGI {

	# This contains the CGI Session parameters. The session files are stored in the specified $Session_Directory. The $Session_Expiry is the time that clients must be inactive before they are logged off automatically.  It's unwise to change either of these values whilst the system is in use. Doing so could cause user sessions to expire prematurely and any changes they were working on will probably be lost. 
	#
	# +-----------+---------------+
    # |   Session Expiry Values   |
	# +-----------+---------------+
    # |   Alias   |  Definition   |
	# +-----------+---------------+
	# |     s     |   Seconds     |
	# |     m     |   Minutes     |
	# |     h     |   Hours       |
	# |     d     |   Days        |
	# |     w     |   Weeks       |
	# |     M     |   Months      |
	# |     y     |   Years       |
	# +-----------+---------------+
	# 
    # '+1h';  # Set to +1h to expire after 1 hour (default)
    # '+15m'; # Set to +15m to expire after 15 minutes
    # '+30s'; # Set to +30s to expire after 30 seconds
	# '+5s';  # Set to +5s if you're Chuck Norris

	my $Session_In_Database = 'Yes'; # Set this to 'Yes' to store cookies in the DB, otherwise they are stored on disk defined in $Session_Directory
	my $Session_Expiry = '+1d';
	my $Session_Directory = '/tmp/CGI-Sessions'; # This will be used if you do not intend on using the DB to store session cookies


	# Do not change values below this point

	use CGI;
	use CGI::Carp qw(fatalsToBrowser);
	use CGI::Session qw(-ip-match);

	my $CGI = new CGI;
		my $Session;
		if ($Session_In_Database =~ /Yes/) {
			my $DB_Connection = DB_Connection();
			$Session = new CGI::Session('driver:MySQL', $CGI, {
				TableName=>'cgi_sessions',
				IdColName=>'id',
				DataColName=>'session_data',
				Handle=>$DB_Connection,
				secure=>1,
				Taint=>1
			});
			$Session->flush();
		}
		else {
			$Session = new CGI::Session(undef, $CGI, {Directory=>$Session_Directory});
		}
		
		$Session->expire($Session_Expiry); # Sets expiry.
		my $Cookie = $CGI->cookie(CGISESSID => $Session->id ); # Sets cookie. Nom nom nom.

	my @CGI_Session = ($CGI, $Session, $Cookie);
	return @CGI_Session;

} # sub CGI

sub md5sum {

	# Set the path to `md5sum` here.

	my $md5sum;
	if (-f '/bin/md5sum') {$md5sum = '/bin/md5sum';} else {$md5sum = '/usr/bin/md5sum';}
	return $md5sum;

} # sub md5sum

sub cut {

	# Set the path to `cut` here.

	my $cut;
	if (-f '/bin/cut') {$cut = '/bin/cut';} else {$cut = '/usr/bin/cut';}
	return $cut;

} # sub cut

sub visudo {

	# Set the path to `visudo` here.

	my $visudo;
	if (-f '/sbin/visudo') {$visudo = '/sbin/visudo';} else {$visudo = '/usr/sbin/visudo';}
	return $visudo;

} # sub visudo

sub cp {

	# Set the path to `cp` here.

	my $cp;
	if (-f '/bin/cp') {$cp = '/bin/cp';} else {$cp = '/usr/bin/cp';}
	return $cp;

} # sub cp

sub ls {

	# Set the path to `ls` here.

	my $ls;
	if (-f '/bin/ls') {$ls = '/bin/ls';} else {$ls = '/usr/bin/ls';}
	return $ls;

} # sub ls

sub sudo_grep {

	# Set the path to `grep` here.

	my $grep;
	if (-f '/bin/grep') {$grep = '/bin/grep';} else {$grep = '/usr/bin/grep';}
	return $grep;

} # sub sudo_grep

sub head {

	# Set the path to `head` here.

	my $head;
	if (-f '/bin/head') {$head = '/bin/head';} else {$head = '/usr/bin/head';}
	return $head;

} # sub head

sub nmap {

	# Set the path to `nmap` here.

	my $nmap;
	if (-f '/bin/nmap') {$nmap = '/bin/nmap';} else {$nmap = '/usr/bin/nmap';}
	return $nmap;

} # sub nmap

sub ps {

	# Set the path to `ps` here.

	my $ps;
	if (-f '/bin/ps') {$ps = '/bin/ps';} else {$ps = '/usr/bin/ps';}
	return $ps;

} # sub ps

sub wc {

	# Set the path to `wc` here.

	my $wc;
	if (-f '/bin/wc') {$wc = '/bin/wc';} else {$wc = '/usr/bin/wc';}
	return $wc;

} # sub wc

sub git {

	# Set the path to `git` here.

	my $git;
	if (-f '/bin/git') {$git = '/bin/git';} else {$git = '/usr/bin/git';}
	return $git;

} # sub git

############################################################################################
########### The settings beyond this point are advanced, or shouldn't be changed ###########
############################################################################################

sub Version {

	# This is where the system discovers its version number, which assists with both manual and automated Upgrading, among other things. You should not modify this value.

	my $Version = '2.5.2';
	return $Version;

} # sub Version

sub Server_Hostname {

	# Don't touch this unless you want to trick the system into believing it isn't who it thinks 
	# it is. Only useful in load balanced situations.

	use Sys::Hostname;
	my $Hostname = hostname;
	return $Hostname;

} # sub Server_Hostname

sub Audit_Log_Submission {

	my $DB_Connection = DB_Connection;
	my $Audit_Log_Submission = $DB_Connection->prepare("INSERT INTO `audit_log` (
		`category`,
		`method`,
		`action`,
		`username`
	)
	VALUES (
		?, ?, ?, ?
	)");

	return $Audit_Log_Submission;
	
} # sub Audit_Log_Submission

sub Block_Discovery {

	my $Host_ID = $_[0];
	my $HTML = $_[1];
	my $DB_Connection = DB_Connection;

	my $Select_Block_Links = $DB_Connection->prepare("SELECT `ip`
		FROM `lnk_hosts_to_ipv4_assignments`
		WHERE `host` = ?");
	$Select_Block_Links->execute($Host_ID);
	
	my $Blocks;
	while (my $Block_ID = $Select_Block_Links->fetchrow_array() ) {
	
		my $Select_Blocks = $DB_Connection->prepare("SELECT `ip_block`
			FROM `ipv4_assignments`
			WHERE `id` = ?");
		$Select_Blocks->execute($Block_ID);
	
		while (my $Block = $Select_Blocks->fetchrow_array() ) {
	
			my $Count_Block_Assignments = $DB_Connection->prepare("SELECT `id`
				FROM `lnk_hosts_to_ipv4_assignments`
				WHERE `ip` = ?");
			$Count_Block_Assignments->execute($Block_ID);
			my $Total_Block_Assignments = $Count_Block_Assignments->rows();

			if ($HTML) {
				if ($Total_Block_Assignments > 1) {
					$Block = "$Block [floating]";
				}
				$Blocks = $Block. ",&nbsp;" . $Blocks;
			}
			else {
				if ($Block =~ /\/32$/) {
					$Block =~ s/(.*)\/32$/$1/;
					$Blocks = $Block. "," . $Blocks;
				}
			}
		}
	}
	
	$Blocks =~ s/,&nbsp;$//;
	
	return $Blocks;


} # sub Block_Discovery

sub Random_Alpha_Numeric_Password {

	# Don't touch this.

	my $Random_Value;
	my $Password_Length = $_[0];

	if (!$Password_Length) {
		$Password_Length = 10;
	}

	my $Chars =
	"a b c d e f g h i j
	 k l m n o p q r s t
	 u v w x y z A B C D
	 E F G H I J K L M N
	 O P Q R S T U V W X
	 Y Z 0 1 2 3 4 5 6 7
	 8 9";
	$Chars =~ s/\s//g;
	$Chars =~ s/\t//g;
	$Chars =~ s/\n//g;

	use Bytes::Random::Secure qw(random_string_from);
	my $CSPRNG = Bytes::Random::Secure->new(NonBlocking => 0);
	my $Random_Password = $CSPRNG->string_from($Chars, $Password_Length);

	return $Random_Password;

} # sub Random_Alpha_Numeric_Password

sub System_Logger {

	# This is the system logging function.

	use POSIX qw(strftime);
	my $Time_Stamp = strftime "%Y-%m-%d %H:%M:%S", localtime;
	my $Paper_Trail = &Paper_Trail;
	my $System_Log_File = &System_Log_File;
	my $Filename = (caller(0))[1];
	my $Line = (caller(0))[2];
	my $Subroutine = $_[0];
	my $Log_Entry = $_[1];
	
	if ($Paper_Trail) {
		open( SysLog, ">>$System_Log_File" ) or die "Can't open $System_Log_File";
		print SysLog "$Time_Stamp - $Filename $Subroutine $Line\t$Log_Entry\n";
		close SysLog;
	}

} # sub System_Logger

sub enc {

	use MIME::Base64;
	my $Query = $_[0];
	my $Length = $_[1];
		my @Chars;
		if (!$Length) {
			@Chars = split(" ", "5 6 7 8 9");
		}
		else {
			@Chars = split(" ", "$Length $Length $Length $Length $Length");
		} 
	my $Salt1 = Salt(10);
	my $Salt2 = Salt(10);
	$Query = "$Salt1$Query$Salt2";

	my $Subroutine = (caller(0))[3];
	&System_Logger($Subroutine, "Query=$Query Salt1=$Salt1 Salt2=$Salt2");

	srand;

	my $Random_Value;
	my $Enc_Length = 1;
	my $Loop_Limit;
	for (my $i=1; $i <= $Enc_Length; $i++) {
		$Random_Value = int(rand 5);
		$Loop_Limit .= $Chars[$Random_Value];
	}

	my $Loop=0;
	while ($Loop != $Loop_Limit) {
		$Loop++;
		$Query = encode_base64($Query);
		$Query =~ s/\n//g;
	}

	$Query =~ s/(.*)(...)$/$1T${Loop_Limit}m$2/g;
	&System_Logger($Subroutine, "Return=$Query");
	return $Query;

} # sub enc

sub dec {

	use MIME::Base64;
	my $Query = $_[0];

	my $Subroutine = (caller(0))[3];
	&System_Logger($Subroutine, "Query1=$Query");

	my $Enc_Length = $Query;
		$Enc_Length =~ s/.*T([0-9*])m...$/$1/;
		$Query =~ s/(.*)T([0-9*])m(...)$/$1$3/;
	&System_Logger($Subroutine, "Enc_Length=$Enc_Length; Query2=$Query");


	for (my $i=1; $i <= $Enc_Length; $i++) {
		$Query =~ s/\n//g;
		$Query = decode_base64($Query);
	}
	&System_Logger($Subroutine, "Query3=$Query");


	$Query =~ s/^.{10}//;
	$Query =~ s/.{10}$//;
	&System_Logger($Subroutine, "Return=$Query");

	return $Query;

} # sub dec

sub Salt {

	#Do not touch this. DO. NOT. TOUCH. THIS.

	my $Random_Value;
	my $Salt_Length = $_[0];

	if (!$Salt_Length) {
		$Salt_Length = 64;
	}

	if ($Salt_Length < 0) {
		$Salt_Length = 4;
	}

	my $Chars =
	"a b c d e f g h i j
	 k l m n o p q r s t
	 u v w x y z A B C D
	 E F G H I J K L M N
	 O P Q R S T U V W X
	 Y Z 0 1 2 3 4 5 6 7
	 8 9 - _ ! @ # ^ ? =
	 & * ( ) _ + { } | :
	 < > / \ . , ; $ %";
	$Chars =~ s/\s//g;
	$Chars =~ s/\t//g;
	$Chars =~ s/\n//g;

	use Bytes::Random::Secure qw(random_string_from);
	my $CSPRNG = Bytes::Random::Secure->new(NonBlocking => 0);
	my $Random_Salt = $CSPRNG->string_from($Chars, $Salt_Length);

	return $Random_Salt;

} # sub Salt

1;