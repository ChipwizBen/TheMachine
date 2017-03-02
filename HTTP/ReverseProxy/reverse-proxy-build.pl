#!/usr/bin/perl

use strict;
use POSIX qw(strftime);
use Tie::File;

require '../common.pl';
my $System_Name = System_Name();
my $System_Short_Name = System_Short_Name();
my $Version = Version();
my $DB_Connection = DB_Connection();
my $Reverse_Proxy_Location = Reverse_Proxy_Location();
	unlink glob "$Reverse_Proxy_Location/*.conf" or warn "Could not unlink $Reverse_Proxy_Location/*.conf";
my $Proxy_Redirect_Location = Proxy_Redirect_Location();
	unlink glob "$Proxy_Redirect_Location/*.conf" or warn "Could not unlink $Proxy_Redirect_Location/*.conf";

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

	my $Select_Locks = $DB_Connection->prepare("SELECT `reverse-proxy-build` FROM `lock`");
	$Select_Locks->execute();

	my ($Reverse_Proxy_Build_Lock) = $Select_Locks->fetchrow_array();

		if ($Reverse_Proxy_Build_Lock == 1) {
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
				print "Another build process is running. Use --override to continue anyway. Exiting...\n";
				exit(1);
			}
		}
		else {
			$DB_Connection->do("UPDATE `lock` SET
				`reverse-proxy-build` = '1',
				`last-reverse-proxy-build-started` = NOW()");
		}

# / Safety check for other running build processes

my $Git_Check = Git_Link('Status_Check');
if ($Git_Check =~ /Yes/i) {
	my $ReverseProxy_Git_Directory = Git_Locations('ReverseProxy');
		unlink glob "$ReverseProxy_Git_Directory/*.conf" or warn "Could not unlink $ReverseProxy_Git_Directory/*.conf";	
	my $Redirect_Git_Directory = Git_Locations('Redirect');
		unlink glob "$Redirect_Git_Directory/*.conf" or warn "Could not unlink $Redirect_Git_Directory/*.conf";	
}

&write_reverse_proxy;
print "Reverse proxy configuration written to $Reverse_Proxy_Location/\n";
&write_redirect;
print "Redirect configuration written to $Proxy_Redirect_Location/\n";

if ($Git_Check =~ /Yes/i) {
	my $ReverseProxy_Git_Directory = Git_Locations('ReverseProxy');
		&Git_Commit("$ReverseProxy_Git_Directory/*", "Cleared old configs.");
	my $Redirect_Git_Directory = Git_Locations('Redirect');
		&Git_Commit("$Redirect_Git_Directory/*", "Cleared old configs.");
	&Git_Commit('Push');
}

$DB_Connection->do("UPDATE `lock` SET 
`reverse-proxy-build` = '0',
`last-reverse-proxy-build-finished` = NOW()");
exit(0);


sub write_reverse_proxy {

	my ($Default_Transfer_Log,
		$Default_Error_Log,
		$Default_SSL_Certificate_File,
		$Default_SSL_Certificate_Key_File,
		$Default_SSL_CA_Certificate_File) = Reverse_Proxy_Defaults();

	my $Record_Query = $DB_Connection->prepare("SELECT `id`, `server_name`, `proxy_pass_source`, `proxy_pass_destination`, 
	`transfer_log`, `error_log`, `ssl_certificate_file`, `ssl_certificate_key_file`, `ssl_ca_certificate_file`,
	`pfs`, `rc4`, `enforce_ssl`, `hsts`, `frame_options`, `xss_protection`, `content_type_options`,	`content_security_policy`, 
	`permitted_cross_domain_policies`, `powered_by`, `custom_attributes`, `last_modified`, `modified_by`
	FROM `reverse_proxy`
	WHERE `active` = '1'
	ORDER BY `server_name` ASC");
	$Record_Query->execute();

	unlink "$Reverse_Proxy_Location/*";

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

		my $Config_Name = "httpd.rp-$Server_Name.conf";
		my $Config_File = "$Reverse_Proxy_Location/$Config_Name";

		if ($Verbose) {print "\nRP-SN: $Server_Name\n    RPID: $ID\n    Config: $Config_File\n"}
				
		if ($Verbose) {print "    Found existing config, appending.\n"}
		
		if (-f $Config_File) {
			open( Reverse_Proxy_Config, ">>$Config_File" ) or die "Can't open $Config_File";
		}
		else {
			open( Reverse_Proxy_Config, ">$Config_File" ) or die "Can't open $Config_File";
			print Reverse_Proxy_Config "#########################################################################\n";
			print Reverse_Proxy_Config "## $System_Name\n";
			print Reverse_Proxy_Config "## Version: $Version\n";
			print Reverse_Proxy_Config "## AUTO GENERATED FILE\n";
			print Reverse_Proxy_Config "## Please do not edit by hand\n";
			print Reverse_Proxy_Config "## This file is part of a wider system and is automatically overwritten often\n";
			print Reverse_Proxy_Config "## View the changelog or README files for more information.\n";
			print Reverse_Proxy_Config "#########################################################################\n";
			print Reverse_Proxy_Config "\n";
			print Reverse_Proxy_Config "## Reverse Proxy ID $ID, last modified $Last_Modified by $Modified_By\n";		
			print Reverse_Proxy_Config "\n";
		}



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
				#$HSTS_Header = 'Header always set		Strict-Transport-Security "max-age=31536000; includeSubDomains"';
				$HSTS_Header = 'Header always set		Strict-Transport-Security "max-age=31536000"';
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
    #SSLProxyCheckPeerCN	off
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

		my $Git_Check = Git_Link('Status_Check');
		if ($Git_Check =~ /Yes/i) {
			my $Git_Directory = Git_Locations('ReverseProxy');
			use File::Copy;
			copy("$Config_File","$Git_Directory/$Config_Name") or die "Copy failed of $Config_File to $Git_Directory/$Config_Name: $!";
			&Git_Commit("$Git_Directory/$Config_Name", "Reverse Proxy $Server_Name ($ID), last modified $Last_Modified by $Modified_By", $Last_Modified, $Modified_By)
		}
	}

} # sub write_reverse_proxy

sub write_redirect {

	my ($Default_Transfer_Log,
		$Default_Error_Log) = Redirect_Defaults();

	my $Server_Group_Query = $DB_Connection->prepare("SELECT `server_name`, `port`, `transfer_log`, `error_log`, `last_modified`, `modified_by`
	FROM `redirect`
	WHERE `active` = '1'
	GROUP BY `server_name`, `port` ASC");
	$Server_Group_Query->execute();

	unlink "$Reverse_Proxy_Location/*";

	while ( my @Server_Entry = $Server_Group_Query->fetchrow_array() )
	{
		my $Server_Name = $Server_Entry[0];
		my $Port = $Server_Entry[1];
		my $Transfer_Log = $Server_Entry[2];
		my $Error_Log = $Server_Entry[3];
		my $Last_Modified = $Server_Entry[4];
		my $Modified_By = $Server_Entry[5];

		my $ServerAliases;
		my @ServerAliases = split(',', $Server_Name);
		my $Server_Name_Single = shift @ServerAliases;
		foreach my $Alias (@ServerAliases) {
			$ServerAliases = $ServerAliases . "	\n    ServerAlias			$Alias";
		}
		my $Server_Names = "ServerName			" . $Server_Name_Single . $ServerAliases;

		my $Config_Name = "httpd.rd-$Port-$Server_Name_Single.conf";
		my $Config_File = "$Proxy_Redirect_Location/$Config_Name";

		if (!$Transfer_Log) {$Transfer_Log = $Default_Transfer_Log}
		if (!$Error_Log) {$Error_Log = $Default_Error_Log}

		open( Redirect_Config, ">$Config_File" ) or die "Can't open $Config_File";
		print Redirect_Config "#########################################################################\n";
		print Redirect_Config "## $System_Name\n";
		print Redirect_Config "## Version: $Version\n";
		print Redirect_Config "## AUTO GENERATED FILE\n";
		print Redirect_Config "## Please do not edit by hand\n";
		print Redirect_Config "## This file is part of a wider system and is automatically overwritten often\n";
		print Redirect_Config "## View the changelog or README files for more information.\n";
		print Redirect_Config "#########################################################################\n";
		print Redirect_Config "\n";
		print Redirect_Config "<VirtualHost *:$Port>\n";
		print Redirect_Config "    $Server_Names\n";

		my $Server_Attribute_Query = $DB_Connection->prepare("SELECT `id`, `redirect_source`, `redirect_destination`, `last_modified`, `modified_by`
		FROM `redirect`
		WHERE (`server_name` LIKE ?
			OR `server_name` LIKE ?
			OR `server_name` LIKE ?
			OR `server_name` LIKE ?
			)
		AND `port` = ?
		ORDER BY `redirect_source` DESC");
		$Server_Attribute_Query->execute($Server_Name, "$Server_Name,%", "%,$Server_Name", "%,$Server_Name,%", $Port);

		my $ID_Group;
		while ( my @Redirect_Entry = $Server_Attribute_Query->fetchrow_array() )
		{
			my $ID = $Redirect_Entry[0];
				$ID_Group = $ID_Group . $ID . ', '; 
			my $Source = $Redirect_Entry[1];
			my $Destination = $Redirect_Entry[2];
			$Last_Modified = $Redirect_Entry[3];
			$Modified_By = $Redirect_Entry[4];
			
			if ($Verbose) {print "\nRD-SN: $Server_Name\n    RDID: $ID\n    Config: $Config_File\n"}
	
	        print Redirect_Config "\n    ## Redirect ID $ID, last modified $Last_Modified by $Modified_By\n";
	        print Redirect_Config "    Redirect			$Source	$Destination\n";
		}

		print Redirect_Config "\n    TransferLog			$Transfer_Log\n";
		print Redirect_Config "    ErrorLog			$Error_Log\n";
		print Redirect_Config "</VirtualHost>\n";
		print Redirect_Config "\n";

		close Redirect_Config;
		$ID_Group =~ s/,\s$//g;

		my $Git_Check = Git_Link('Status_Check');
		if ($Git_Check =~ /Yes/i) {
			my $Git_Directory = Git_Locations('Redirect');
			use File::Copy;
			copy("$Config_File","$Git_Directory/$Config_Name") or die "Copy failed of $Config_File to $Git_Directory/$Config_Name: $!";
			&Git_Commit("$Git_Directory/$Config_Name", "Redirect $Server_Name_Single ($ID_Group), last modified $Last_Modified by $Modified_By", $Last_Modified, $Modified_By)
		}
	}
} # sub write_redirect
