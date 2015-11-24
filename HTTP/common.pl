#!/usr/bin/perl

use strict;

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

	my $System_Name = 'System Harmony and Integration Tool';
	return $System_Name;

} # sub System_Name

sub System_Short_Name {

	# This is the system's shortened name, which is used in short descriptions. It can be the same as the full name in System_Name if you want, but it might get busy on some screens if your system name is long. It's encouraged to keep this short (less than 10 characters).

	my $System_Short_Name = 'S.H.I.T';
	return $System_Short_Name;

} # sub System_Short_Name

sub Header {

	my $Header;
	if (-f 'header.cgi') {$Header = 'header.cgi';} else {$Header = '../header.cgi';}
	return $Header;
	
} # sub Header

sub Footer {

	my $Footer;
	if (-f 'footer.cgi') {$Footer = 'footer.cgi';} else {$Footer = '../footer.cgi';}
	return $Footer;
	
} # sub Footer

sub DNS_Server {

	# By setting a DNS server here, it will override the operating system's DNS server when doing lookups
	
	my $DNS_Server = '192.168.16.10';
	return $DNS_Server;

} # sub DNS_Server

sub LDAP_Login {

	# These are the connection paremeters for LDAP / Active Directory. If you disable this, the system will use internal authentication.

	my $LDAP_Enabled = 'On'; # Set this to 'Off' to disable LDAP/AD authentication

	my $LDAP_Server = '192.168.59.235';
	my $LDAP_Port = 389;
	my $Timeout = 5;
	my $LDAP_User_Name_Prefix = '\\';
	my $LDAP_Filter = '(&(objectClass=inetOrgPerson)(memberOf=cn=LibreNMS_Users,ou=Application Groups,ou=Groups,dc=,dc=local))';
	my $LDAP_Search_Base = "ou=User Accounts,dc=,dc=local";

	# ---- Do not edit vaules below this line ---- #

	my $LDAP_Query = $_[0];
	if ($LDAP_Query eq 'Status_Check') {
		return $LDAP_Enabled;
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
			timeout => $Timeout,
			#filter => $LDAP_Filter,
		) or die "Can't connect to LDAP server: $@";
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

	# This is not necessarily the location of the /etc/sudoers file. This is the path that the system writes the temporary sudoers file to. It could be /etc/sudoers, but you ought to consider the rights that Apache will need to overwrite that file, and the implications of giving Apache those rights. If you want to automate it end to end, you should consider writing a temporary sudoers file, then using a separate root cron job to overwrite /etc/sudoers, which is the recommended procedure, instead of directly writing to it. Of course, if you do not intend on using the DSMS system to manage /etc/sudoers on the local machine, then this should NOT be /etc/sudoers. For sudoers locations on remote machines, see DSMS_Distribution_Defaults, or set individual remote sudoers locations through the web panel.

	my $Sudoers_Location = '/var/www/html/sudoers';
	return $Sudoers_Location;

} # sub Sudoers_Location

sub Sudoers_Storage {

	# This is the directory where replaced sudoers files are stored. You do not need a trailing slash.

	my $Sudoers_Storage = '/var/www/html/Storage/Sudoers';
	return $Sudoers_Storage;

} # sub Sudoers_Storage

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

} # sub DNS_External_SOA

sub DNS_Storage {

	# This is the directory where replaced DNS files are stored. You do not need a trailing slash.

	my $DNS_Storage = '/var/www/html/Storage/DNS';
	return $DNS_Storage;

} # sub DNS_Storage

sub DB_Management {

	# This is your management database's connection information. This could be the same database as the database in the DB_Sudoers because the two schemas have different table names to facilitate a combination. However, the management data (System Accounts, Access Log, Audit Log, etc) contain sensitive information that normal users should not be allowed access to. This access control should also be applicable to database administrators, which is why this data is stored in a separate database by default to simplify access control.

	use DBI;

	my $Host = 'localhost';
	my $Port = '3306';
	my $DB = 'Management';
	my $User = 'Management';
	my $Password = '<Password>';

	my $DB_Management = DBI->connect ("DBI:mysql:database=$DB:host=$Host:port=$Port",
		$User,
		$Password)
		or die "Can't connect to database: $DBI::errstr\n";
	return $DB_Management;

} # sub DB_Management

sub DB_Sudoers {

	#  This is your Sudoers database's connection information. This is where your sudoers data is stored.

	use DBI;

	my $Host = 'localhost';
	my $Port = '3306';
	my $DB = 'Sudoers';
	my $User = 'Sudoers';
	my $Password = '<Password>';

	my $DB_Sudoers = DBI->connect ("DBI:mysql:database=$DB:host=$Host:port=$Port",
		$User,
		$Password)
		or die "Can't connect to database: $DBI::errstr\n";
	return $DB_Sudoers;

} # sub DB_Sudoers

sub DB_IP_Allocation {

	#  This is your IP Allocation database's connection information.

	use DBI;

	my $Host = 'localhost';
	my $Port = '3306';
	my $DB = 'IP_Allocation';
	my $User = 'Sudoers';
	my $Password = '<Password>';

	my $DB_IP_Allocation = DBI->connect ("DBI:mysql:database=$DB:host=$Host:port=$Port",
		$User,
		$Password)
		or die "Can't connect to database: $DBI::errstr\n";
	return $DB_IP_Allocation;

} # sub DB_IP_Allocation

sub DB_Icinga {

	#  This is your Icinga database's connection information. This is where your Icinga data is stored.

	use DBI;

	my $Host = 'localhost';
	my $Port = '3306';
	my $DB = 'Nagios';
	my $User = 'Sudoers';
	my $Password = '<Password>';

	my $DB_Icinga = DBI->connect ("DBI:mysql:database=$DB:host=$Host:port=$Port",
		$User,
		$Password)
		or die "Can't connect to database: $DBI::errstr\n";
	return $DB_Icinga;

} # sub DB_Icinga

sub DB_DNS {

	#  This is your DNS database's connection information. This is where your sudoers data is stored.

	use DBI;

	my $Host = 'localhost';
	my $Port = '3306';
	my $DB = 'DNS';
	my $User = 'Sudoers';
	my $Password = '<Password>';

	my $DB_DNS = DBI->connect ("DBI:mysql:database=$DB:host=$Host:port=$Port",
		$User,
		$Password)
		or die "Can't connect to database: $DBI::errstr\n";
	return $DB_DNS;

} # sub DB_DNS

sub DB_Reverse_Proxy {

	#  This is your Reverse Proxy database's connection information. This is where your sudoers data is stored.

	use DBI;

	my $Host = 'localhost';
	my $Port = '3306';
	my $DB = 'Reverse_Proxy';
	my $User = 'Sudoers';
	my $Password = '<Password>';

	my $DB_Reverse_Proxy = DBI->connect ("DBI:mysql:database=$DB:host=$Host:port=$Port",
		$User,
		$Password)
		or die "Can't connect to database: $DBI::errstr\n";
	return $DB_Reverse_Proxy;

} # sub DB_Reverse_Proxy

sub Reverse_Proxy_Defaults {

	# These are the default reverse proxy values for entires without custom parameters.

	my $Transfer_Log = '/var/log/apache/access.log';
	my $Error_Log = '/var/log/apache/error.log';
	my $SSL_Certificate_File = '/etc/ssl/ssl-wildcard/wildcard.nwk1.com.crt';
	my $SSL_Certificate_Key_File = '/etc/ssl/ssl-wildcard/wildcard.nwk1.com.key';
	my $SSL_CA_Certificate_File = '/etc/ssl/ssl-wildcard/SSL_CA_Bundle.pem';

	my @Reverse_Proxy_Defaults = ($Transfer_Log, $Error_Log, $SSL_Certificate_File, $SSL_Certificate_Key_File, $SSL_CA_Certificate_File);

} # sub Reverse_Proxy_Defaults

sub Redirect_Defaults {

	# These are the default proxy redirect values for entires without custom parameters.

	my $Transfer_Log = '/var/log/apache/access.log';
	my $Error_Log = '/var/log/apache/error.log';

	my @Redirect_Defaults = ($Transfer_Log, $Error_Log);

} # sub Redirect_Defaults

sub DSMS_Distribution_Defaults {

	# These are the default sudoers distribution settings for new hosts. Keep in mind that any active host is automatically tried for sudoers pushes with their distribution settings. Unless you are confident that all new hosts will have the same settings, you might want to set fail-safe defaults here and manually override each host individually on the Distribution Status page.
	# A good fail-safe strategy would be to set $Key_Path to be /dev/null so that login to the Remote Server becomes impossible. Alternatively, another good method would be to set $Remote_Sudoers to /sudoers/sudoers (which reflects the chroot recommendations), so that you could accurately test remote login, but not affect the existing sudoers file at /etc/sudoers. This is also dependent on your Cron Configuration on the Remote Server.


	my $Distribution_SFTP_Port = '22'; # Default SFTP port
	my $Distribution_User = 'transport'; # Default SFTP user
	my $Key_Path = '/root/.ssh/id_rsa'; # Default private key path
	my $Timeout = '15'; # Default stalled connection Timeout in seconds
	my $Remote_Sudoers = 'upload/sudoers'; # Default sudoers file location on remote systems, if using chroot use a relative path

	my @Distribution_Defaults = ($Distribution_SFTP_Port, $Distribution_User, $Key_Path, $Timeout, $Remote_Sudoers);
	return @Distribution_Defaults;

} # sub DSMS_Distribution_Defaults

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
		my @Password_Requirements = ($Enforce_Complexity_Requirements,
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
	my $Session_Expiry = '+1w';
	my $Session_Directory = '/tmp/CGI-Sessions'; # Set this if you do not intend on using the DB to store session cookies


	# Do not change values below this point

	use CGI;
	use CGI::Carp qw(fatalsToBrowser);
	use CGI::Session qw(-ip-match);

	my $CGI = new CGI;
		my $Session;
		if ($Session_In_Database =~ /Yes/) {
			my $DB_Management = DB_Management();
			$Session = new CGI::Session('driver:MySQL', $CGI, {
				TableName=>'cgi_sessions',
				IdColName=>'id',
				DataColName=>'session_data',
				Handle=>$DB_Management
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

	# Manually set the path to `md5sum` here, or just leave this as default and the system 
	# will try to determine its location through `which md5sum --skip-alias`

	my $md5sum = `which md5sum --skip-alias`;

	$md5sum =~ s/\n//g;
	return $md5sum;

} # sub md5sum

sub cut {

	# Manually set the path to `cut` here, or just leave this as default and the system 
	# will try to determine its location through `which cut --skip-alias`

	my $cut = `which cut --skip-alias`;

	$cut =~ s/\n//g;
	return $cut;

} # sub cut

sub visudo {

	# Manually set the path to `visudo` here, or just leave this as default and the system 
	# will try to determine its location through `which visudo --skip-alias`

	my $visudo = `which visudo --skip-alias`;

	$visudo =~ s/\n//g;
	return $visudo;

} # sub visudo

sub cp {

	# Manually set the path to `cp` here, or just leave this as default and the system 
	# will try to determine its location through `which cp --skip-alias`

	my $cp = `which cp --skip-alias`;

	$cp =~ s/\n//g;
	return $cp;

} # sub cp

sub ls {

	# Manually set the path to `ls` here, or just leave this as default and the system 
	# will try to determine its location through `which ls --skip-alias`

	my $ls = `which ls --skip-alias`;

	$ls =~ s/\n//g;
	return $ls;

} # sub ls

sub sudo_grep {

	# Manually set the path to `grep` here, or just leave this as default and the system 
	# will try to determine its location through `which grep --skip-alias`
	#
	# Why sudo_grep and not grep? - grep is a function inside perl, but it doesn't give us 
	# what we need, so we need to use the system's grep instead. If I name this subroutine 
	# 'grep' it makes perl unhappy when I try to call it as grep().

	my $grep = `which grep --skip-alias`;

	$grep =~ s/\n//g;
	return $grep;

} # sub sudo_grep

sub head {

	# Manually set the path to `head` here, or just leave this as default and the system 
	# will try to determine its location through `which head --skip-alias`

	my $head = `which head --skip-alias`;

	$head =~ s/\n//g;
	return $head;

} # sub head

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

############################################################################################
########### The settings beyond this point are advanced, or shouldn't be changed ###########
############################################################################################

sub Version {

	# This is where the system discovers its version number, which assists with both manual and automated Upgrading, among other things. You should not modify this value.

	my $Version = '2.0.0';
	return $Version;

} # sub Version

sub Server_Hostname {

	# Don't touch this unless you want to trick the system into believing it isn't who it thinks 
	# it is.

	my $Hostname = `hostname`;
	return $Hostname;

} # sub Server_Hostname

sub Random_Alpha_Numeric_Password {

	# Don't touch this.

	my $Random_Value;
	my $Password_Length = $_[0];

	if (!$Password_Length) {
		$Password_Length = 10;
	}

	my @Chars = split(" ",
		"a b c d e f g h i j
		 k l m n o p q r s t
		 u v w x y z A B C D
		 E F G H I J K L M N
		 O P Q R S T U V W X
		 Y Z 0 1 2 3 4 5 6 7
		 8 9");

	srand;

	my $Random_Password;
	for (my $i=0; $i <= $Password_Length ;$i++) {
		$Random_Value = int(rand 62);
		$Random_Password .= $Chars[$Random_Value];
	}

	return $Random_Password;
	
} # sub Random_Alpha_Numeric_Password

sub Salt {

	#Do not touch this. DO. NOT. TOUCH. THIS.

	my $Random_Value;
	my $Salt_Length = $_[0];

	if (!$Salt_Length) {
		$Salt_Length = 64;
	}

	my @Chars = split(" ",
		"a b c d e f g h i j
		 k l m n o p q r s t
		 u v w x y z A B C D
		 E F G H I J K L M N
		 O P Q R S T U V W X
		 Y Z 0 1 2 3 4 5 6 7
		 8 9 - _ ! @ # ^ ? =
		 & * ( ) _ + { } | :
		 < > / \ . , ; $ %");

	srand;

	my $Random_Salt;
	for (my $i=0; $i <= $Salt_Length ;$i++) {
		$Random_Value = int(rand 89);
		$Random_Salt .= $Chars[$Random_Value];
	}

	return $Random_Salt;
	
} # sub Salt

1;