#!/usr/bin/perl

use strict;
use POSIX qw(strftime);
use Tie::File;

require '../common.pl';
my $System_Name = System_Name();
my $System_Short_Name = System_Short_Name();
my $Version = Version();
my $DB_Management = DB_Management();
my $DB_Reverse_Proxy = DB_Reverse_Proxy();
my $Reverse_Proxy_Location = Reverse_Proxy_Location();
	unlink glob "$Reverse_Proxy_Location/*.conf";
my $Proxy_Redirect_Location = Proxy_Redirect_Location();
	unlink glob "$Proxy_Redirect_Location/*.conf";
my $Reverse_Proxy_Storage = Reverse_Proxy_Storage();
my $Date_Time = strftime "%H:%M:%S %d/%m/%Y", localtime;

$| = 1;
my $Override;
my $Verbose;

foreach my $Parameter (@ARGV) {
	if ($Parameter eq '--override') {$Override = 1}
	if ($Parameter eq '-h' || $Parameter eq '--help') {
		print "\nOptions are:\n\t--override\tOverrides any database lock\n\n";
		exit(0);
	}
	if ($Parameter eq '-v' || $Parameter eq '--verbose') {
		print "Verbose mode on\n\n";
		$Verbose = 1;
	}
}

# Safety check for other running build processes

	my $Select_Locks = $DB_Management->prepare("SELECT `reverse-proxy-build` FROM `lock`");
	$Select_Locks->execute();

	my ($Reverse_Proxy_Build_Lock, $Reverse_Proxy_Distribution_Lock) = $Select_Locks->fetchrow_array();

		if ($Reverse_Proxy_Build_Lock == 1 || $Reverse_Proxy_Distribution_Lock == 1) {
			if ($Override) {
				print "Override detected. (CTRL + C to cancel)...\n\n";
				print "Continuing in... 5\r";
				sleep 1;
				print "Continuing in... 4\r";
				sleep 1;
				print "Continuing in... 3\r";
				sleep 1;
				print "Continuing in... 2\r";
				sleep 1;
				print "Continuing in... 1\r";
				sleep 1;	
			}
			else {
				print "Another build or distribution process is running. Use --override to continue anyway. Exiting...\n";
				exit(1);
			}
		}
		else {
			$DB_Management->do("UPDATE `lock` SET
				`reverse-proxy-build` = '1',
				`last-reverse-proxy-build-started` = NOW()");
		}

# / Safety check for other running build processes

&write_reverse_proxy;
print "Reverse proxy configuration written to $Reverse_Proxy_Location/\n";
&write_redirect;
print "Redirect configuration written to $Proxy_Redirect_Location/\n";

$DB_Management->do("UPDATE `lock` SET 
`reverse-proxy-build` = '0',
`last-reverse-proxy-build-finished` = NOW()");
exit(0);


sub write_reverse_proxy {

	my ($Default_Transfer_Log,
		$Default_Error_Log,
		$Default_SSL_Certificate_File,
		$Default_SSL_Certificate_Key_File,
		$Default_SSL_CA_Certificate_File) = Reverse_Proxy_Defaults();

	my $Record_Query = $DB_Reverse_Proxy->prepare("SELECT `id`, `server_name`, `proxy_pass_source`, `proxy_pass_destination`, 
	`transfer_log`, `error_log`, `ssl_certificate_file`, `ssl_certificate_key_file`, `ssl_ca_certificate_file`,
	`pfs`, `rc4`, `enforce_ssl`, `hsts`, `frame_options`, `xss_protection`, `content_type_options`,	`content_security_policy`, 
	`permitted_cross_domain_policies`, `powered_by`, `custom_attributes`, `last_modified`, `modified_by`
	FROM `reverse_proxy`
	WHERE `active` = '1'
	ORDER BY `server_name` ASC");
	$Record_Query->execute();

	while ( my @Proxy_Entry = $Record_Query->fetchrow_array() )
	{
		my $ID = $Proxy_Entry[0];
		my $Server_Name = $Proxy_Entry[1];
		my $Source = $Proxy_Entry[2];
		my $Destination = $Proxy_Entry[3];
		my $Transfer_Log = $Proxy_Entry[4];
		my $Error_Log = $Proxy_Entry[5];
		my $SSL_Certificate_File = $Proxy_Entry[6];
		my $SSL_Certificate_Key_File = $Proxy_Entry[7];
		my $SSL_CA_Certificate_File = $Proxy_Entry[8];
		my $PFS = $Proxy_Entry[9];
		my $RC4 = $Proxy_Entry[10];
		my $Enforce_SSL = $Proxy_Entry[11];
		my $HSTS = $Proxy_Entry[12];
		my $Frame_Options = $Proxy_Entry[13];
		my $XSS_Protection = $Proxy_Entry[14];
		my $Content_Type_Options = $Proxy_Entry[15];
		my $Content_Security_Policy = $Proxy_Entry[16];
		my $Permitted_Cross_Domain_Policies = $Proxy_Entry[17];
		my $Powered_By = $Proxy_Entry[18];
		my $Custom_Attributes = $Proxy_Entry[19];
			$Custom_Attributes =~ s/\n/\n    /g;
		my $Last_Modified = $Proxy_Entry[20];
		my $Modified_By = $Proxy_Entry[21];

		my $ServerAliases;
		my @ServerAliases = split(',', $Server_Name);
		$Server_Name = shift @ServerAliases;
		foreach my $Alias (@ServerAliases) {
			$ServerAliases = $ServerAliases . "	\n    ServerAlias			$Alias";
		}
		my $Server_Names = "ServerName			" . $Server_Name . $ServerAliases;

		my $Config_File = "$Reverse_Proxy_Location/httpd.rp-$Server_Name.conf";

		if ($Verbose) {print "\nRP-SN: $Server_Name\n    RPID: $ID\n    Config: $Config_File\n"}

		if (-f $Config_File) {
			tie my @File_Lines, 'Tie::File', $Config_File;
			my $Last_Written_Time = $File_Lines[3];
				$Last_Written_Time =~ s/^##\sWritten:\s//;
				
				if ($Verbose) {print "    Found existing config, appending.\n"}
			
			if ($Last_Written_Time eq $Date_Time) {
				open( Reverse_Proxy_Config, ">>$Config_File" ) or die "Can't open $Config_File";
			}
			else {
				open( Reverse_Proxy_Config, ">$Config_File" ) or die "Can't open $Config_File";
			}
		}
		else {
			open( Reverse_Proxy_Config, ">$Config_File" ) or die "Can't open $Config_File";
		}

		print Reverse_Proxy_Config "#########################################################################\n";
		print Reverse_Proxy_Config "## $System_Name\n";
		print Reverse_Proxy_Config "## Version: $Version\n";
		print Reverse_Proxy_Config "## Written: $Date_Time\n";
		print Reverse_Proxy_Config "## AUTO GENERATED FILE\n";
		print Reverse_Proxy_Config "## Please do not edit by hand\n";
		print Reverse_Proxy_Config "## This file is part of a wider system and is automatically overwritten often\n";
		print Reverse_Proxy_Config "## View the changelog or README files for more information.\n";
		print Reverse_Proxy_Config "#########################################################################\n";
		print Reverse_Proxy_Config "\n";
		print Reverse_Proxy_Config "## Reverse Proxy ID $ID, last modified $Last_Modified by $Modified_By\n";		
		print Reverse_Proxy_Config "\n";

		if (!$Transfer_Log) {$Transfer_Log = $Default_Transfer_Log}
		if (!$Error_Log) {$Error_Log = $Default_Error_Log}

		my $Headers;
		if ($Frame_Options == 1) {
			$Frame_Options = 'Header always set		X-Frame-Options deny';
			$Headers = $Headers . $Frame_Options . "\n    ";
		}
		elsif ($Frame_Options == 2) {
			$Frame_Options = 'Header always set		X-Frame-Options sameorigin';
			$Headers = $Headers . $Frame_Options . "\n    ";
		}
		if ($XSS_Protection) {
			$XSS_Protection = 'Header always set		X-XSS-Protection "1; mode=block"';
			$Headers = $Headers . $XSS_Protection . "\n    ";
		}
		if ($Content_Type_Options) {
			$Content_Type_Options = 'Header always set		X-Content-Type-Options nosniff';
			$Headers = $Headers . $Content_Type_Options . "\n    ";
		}
		if ($Content_Security_Policy) {
			$Content_Security_Policy = 'Header always set		Content-Security-Policy "default-src \'self\'"';
			$Headers = $Headers . $Content_Security_Policy . "\n    ";
		}
		if ($Permitted_Cross_Domain_Policies) {
			$Permitted_Cross_Domain_Policies = 'Header always set		X-Permitted-Cross-Domain-Policies none';
			$Headers = $Headers . $Permitted_Cross_Domain_Policies . "\n    ";
		}
		if ($Powered_By) {
			$Powered_By = 'Header unset		X-Powered-By';
			$Headers = $Headers . $Powered_By . "\n    ";
		}

		if ($SSL_Certificate_File && $SSL_Certificate_Key_File && $SSL_CA_Certificate_File) {
			if (!$SSL_Certificate_File) {$SSL_Certificate_File = $Default_SSL_Certificate_File}
			if (!$SSL_Certificate_Key_File) {$SSL_Certificate_Key_File = $Default_SSL_Certificate_Key_File}
			if (!$SSL_CA_Certificate_File) {$SSL_CA_Certificate_File = $Default_SSL_CA_Certificate_File}

			my $CipherOrder;
			my $CipherSuite;
			if ($PFS && $RC4) {
				$CipherOrder = 'SSLHonorCipherOrder	on';
				$CipherSuite = "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";
			}
			elsif ($PFS && !$RC4) {
				$CipherOrder = 'SSLHonorCipherOrder	on';
				$CipherSuite = "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS !RC4";
			}
			else {
				$CipherOrder = '';
				$CipherSuite = "HIGH:!SSLv2:!ADH:!aNULL:!eNULL:!NULL";
			}

			my $Enforce_SSL_Header;
			if ($Enforce_SSL) {
				$Enforce_SSL_Header = "
    <IfModule mod_rewrite.c>
        RewriteEngine		On
        RewriteCond		%{HTTPS} off
        RewriteRule		(.*)	https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
    </IfModule>
    <IfModule !mod_rewrite.c>
        Redirect		/	https://$Server_Name
    </IfModule>";
			}	
			 



			my $HSTS_Header;
			if ($HSTS) {
				$HSTS_Header = 'Header always set		Strict-Transport-Security "max-age=31536000; includeSubDomains"';
			}			

			print Reverse_Proxy_Config <<RP_EOF;
<VirtualHost *:80>
    $Server_Names
	$Enforce_SSL_Header
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost *:443>
    $Server_Names

    SSLProxyEngine		On
    #SSLProxyVerify		none
    #SSLProxyCheckPeerCN		off
    #SSLProxyCheckPeerName	off
    #SSLProxyCheckPeerExpire	off
    ProxyRequests		Off
    ProxyPreserveHost		On
    ProxyPass			$Source	$Destination
    ProxyPassReverse		$Source	$Destination

    SSLEngine			On
    $HSTS_Header
    $Headers
    SSLProtocol			ALL -SSLv2 -SSLv3
    $CipherOrder
    SSLCipherSuite		"$CipherSuite"
    SSLInsecureRenegotiation	Off

    SSLCertificateFile		$SSL_Certificate_File
    SSLCertificateKeyFile	$SSL_Certificate_Key_File
    SSLCACertificateFile	$SSL_CA_Certificate_File

    TransferLog			$Transfer_Log
    ErrorLog			$Error_Log
    $Custom_Attributes
</VirtualHost>
</IfModule>
RP_EOF
		}
		else {
			print Reverse_Proxy_Config <<RP_EOF;
<VirtualHost *:80>
    $Server_Names
    ProxyEngine			On
    ProxyRequests		Off
    ProxyPreserveHost		On
    ProxyPass			$Source	$Destination
    ProxyPassReverse		$Source	$Destination
    $Headers
    TransferLog			$Transfer_Log
    ErrorLog			$Error_Log
    $Custom_Attributes
</VirtualHost>
RP_EOF
		}

		print Reverse_Proxy_Config "\n";
		close Reverse_Proxy_Config;
	}

} # sub write_reverse_proxy

sub write_redirect {

	my ($Default_Transfer_Log,
		$Default_Error_Log) = Redirect_Defaults();

	my $Record_Query = $DB_Reverse_Proxy->prepare("SELECT `id`, `server_name`, `port`, `redirect_source`, `redirect_destination`, 
	`transfer_log`, `error_log`, `last_modified`, `modified_by`
	FROM `redirect`
	WHERE `active` = '1'
	ORDER BY `server_name` ASC");
	$Record_Query->execute();

	while ( my @Redirect_Entry = $Record_Query->fetchrow_array() )
	{
		my $ID = $Redirect_Entry[0];
		my $Server_Name = $Redirect_Entry[1];
		my $Port = $Redirect_Entry[2];
		my $Source = $Redirect_Entry[3];
		my $Destination = $Redirect_Entry[4];
		my $Transfer_Log = $Redirect_Entry[5];
		my $Error_Log = $Redirect_Entry[6];
		my $Last_Modified = $Redirect_Entry[7];
		my $Modified_By = $Redirect_Entry[8];

		if (!$Transfer_Log) {$Transfer_Log = $Default_Transfer_Log}
		if (!$Error_Log) {$Error_Log = $Default_Error_Log}

		my $ServerAliases;
		my @ServerAliases = split(',', $Server_Name);
		$Server_Name = shift @ServerAliases;
		foreach my $Alias (@ServerAliases) {
			$ServerAliases = $ServerAliases . "	\n    ServerAlias			$Alias";
		}
		my $Server_Names = "ServerName			" . $Server_Name . $ServerAliases;

		my $Config_File = "$Proxy_Redirect_Location/httpd.rd-$Port-$Server_Name.conf";
		
		if ($Verbose) {print "\nRD-SN: $Server_Name\n    RDID: $ID\n    Config: $Config_File\n"}
		
		if (-f $Config_File) {
			tie my @File_Lines, 'Tie::File', $Config_File;
			my $Last_Written_Time = $File_Lines[3];
				$Last_Written_Time =~ s/^##\sWritten:\s//;

				if ($Verbose) {print "    Found existing config, appending.\n"}

			if ($Last_Written_Time eq $Date_Time) {
				open(Redirect_Config_Read,"$Config_File") || die "Can't open $Config_File (read)\n"; 
				my @Config_File_Lines = <Redirect_Config_Read>;
				close(Redirect_Config_Read);

				open( Redirect_Config, ">$Config_File" ) or die "Can't open $Config_File (write)";
				foreach my $Line (@Config_File_Lines) {
					print Redirect_Config $Line;
				    if ($Line =~ /^## Redirect ID/) {
				        print Redirect_Config "## Redirect ID $ID, last modified $Last_Modified by $Modified_By\n\n";
				    }
				    if ($Line =~ /^\s\s\s\sRedirect/) {
				        print Redirect_Config "    Redirect			$Source	$Destination\n";
				    }
				}
			}
		}
		else {
			open( Redirect_Config, ">$Config_File" ) or die "Can't open $Config_File";
			print Redirect_Config "#########################################################################\n";
			print Redirect_Config "## $System_Name\n";
			print Redirect_Config "## Version: $Version\n";
			print Redirect_Config "## Written: $Date_Time\n";
			print Redirect_Config "## AUTO GENERATED FILE\n";
			print Redirect_Config "## Please do not edit by hand\n";
			print Redirect_Config "## This file is part of a wider system and is automatically overwritten often\n";
			print Redirect_Config "## View the changelog or README files for more information.\n";
			print Redirect_Config "#########################################################################\n";
			print Redirect_Config "\n";
			print Redirect_Config "## Redirect ID $ID, last modified $Last_Modified by $Modified_By";
			print Redirect_Config "\n";
			print Redirect_Config "<VirtualHost *:$Port>\n";
			print Redirect_Config "    $Server_Names\n";
			print Redirect_Config "    Redirect			$Source	$Destination\n";
			print Redirect_Config "    TransferLog			$Transfer_Log\n";
			print Redirect_Config "    ErrorLog			$Error_Log\n";
			print Redirect_Config "</VirtualHost>\n";
			print Redirect_Config "\n";
		}
		
		close Redirect_Config;
	}

} # sub write_redirect
