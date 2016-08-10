#!/usr/bin/perl

use strict;
use POSIX qw(strftime);

require '../common.pl';
my $DB_Management = DB_Management();
my $DB_Reverse_Proxy = DB_Reverse_Proxy();
my $Reverse_Proxy_Location = Reverse_Proxy_Location();
my $Proxy_Redirect_Location = Proxy_Redirect_Location();
my $Reverse_Proxy_Storage = Reverse_Proxy_Storage();
my $System_Name = System_Name();
my $System_Short_Name = System_Short_Name();
my $Version = Version();

$| = 1;
my $Override;

foreach my $Parameter (@ARGV) {
	if ($Parameter eq '--override') {$Override = 1}
	if ($Parameter eq '-h' || $Parameter eq '--help') {
		print "\nOptions are:\n\t--override\tOverrides any database lock\n\n";
		exit(0);
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
&write_redirect;

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

	open( Reverse_Proxy_Config, ">$Reverse_Proxy_Location/httpd.$System_Short_Name-reverse-proxy.conf" ) or die "Can't open $Reverse_Proxy_Location/httpd.$System_Short_Name-reverse-proxy.conf";

	print Reverse_Proxy_Config "#########################################################################\n";
	print Reverse_Proxy_Config "## $System_Name\n";
	print Reverse_Proxy_Config "## Version: $Version\n";
	print Reverse_Proxy_Config "## AUTO GENERATED SCRIPT\n";
	print Reverse_Proxy_Config "## Please do not edit by hand\n";
	print Reverse_Proxy_Config "## This file is part of a wider system and is automatically overwritten often\n";
	print Reverse_Proxy_Config "## View the changelog or README files for more information.\n";
	print Reverse_Proxy_Config "#########################################################################\n";
	print Reverse_Proxy_Config "\n\n";

	print Reverse_Proxy_Config "### This file is for reverse proxy entries ###\n\n";


	my $Record_Query = $DB_Reverse_Proxy->prepare("SELECT `id`, `server_name`, `proxy_pass_source`, `proxy_pass_destination`, 
	`transfer_log`, `error_log`, `ssl_certificate_file`, `ssl_certificate_key_file`, `ssl_ca_certificate_file`,
	`pfs`, `rc4`, `enforce_ssl`, `hsts`, `last_modified`, `modified_by`
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
		my $Last_Modified = $Proxy_Entry[13];
		my $Modified_By = $Proxy_Entry[14];

		my $ServerAliases;
		my @ServerAliases = split(',', $Server_Name);
		$Server_Name = shift @ServerAliases;
		foreach my $Alias (@ServerAliases) {
			$ServerAliases = $ServerAliases . "\n    ServerAlias			$Alias";
		}
		my $Server_Names = "ServerName			" . $Server_Name . $ServerAliases;

		if (!$Transfer_Log) {$Transfer_Log = $Default_Transfer_Log}
		if (!$Error_Log) {$Error_Log = $Default_Error_Log}

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
        RewriteEngine	On
        RewriteCond		%{HTTPS} off
        RewriteRule		(.*)	https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
    </IfModule>
    <IfModule !mod_rewrite.c>
        Redirect		/	https://$Server_Name
    </IfModule>";
			}	
			 



			my $HSTS_Header;
			if ($HSTS) {
				$HSTS_Header = 'Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"';
			}			

#Header always append X-Frame-Options SAMEORIGIN

			print Reverse_Proxy_Config <<RP_EOF;
## Reverse Proxy ID $ID, last modified $Last_Modified by $Modified_By
<VirtualHost *:80>
    $Server_Names
	$Enforce_SSL_Header
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost *:443>
    $Server_Names
    SSLProxyEngine		On
    SSLProxyVerify		none
    SSLProxyCheckPeerCN		off
    SSLProxyCheckPeerName	off
    SSLProxyCheckPeerExpire	off
    ProxyRequests		Off
    ProxyPreserveHost		On
    ProxyPass			$Source	$Destination
    ProxyPassReverse		$Source	$Destination

    SSLEngine			On
    $HSTS_Header
    SSLProtocol			ALL -SSLv2 -SSLv3
    $CipherOrder
    SSLCipherSuite		"$CipherSuite"
    SSLInsecureRenegotiation	Off

    SSLCertificateFile		$SSL_Certificate_File
    SSLCertificateKeyFile	$SSL_Certificate_Key_File
    SSLCACertificateFile	$SSL_CA_Certificate_File

    TransferLog			$Transfer_Log
    ErrorLog			$Error_Log
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
    TransferLog			$Transfer_Log
    ErrorLog			$Error_Log
</VirtualHost>

RP_EOF
		}
	}

print Reverse_Proxy_Config "\n";
close Reverse_Proxy_Config;

} # sub write_reverse_proxy

sub write_redirect {

	my ($Default_Transfer_Log,
		$Default_Error_Log) = Redirect_Defaults();

	open( Redirect_Config, ">$Proxy_Redirect_Location/httpd.$System_Short_Name-proxy-redirect.conf" ) or die "Can't open $Proxy_Redirect_Location/httpd.$System_Short_Name-proxy-redirect.conf";

	print Redirect_Config "#########################################################################\n";
	print Redirect_Config "## $System_Name\n";
	print Redirect_Config "## Version: $Version\n";
	print Redirect_Config "## AUTO GENERATED SCRIPT\n";
	print Redirect_Config "## Please do not edit by hand\n";
	print Redirect_Config "## This file is part of a wider system and is automatically overwritten often\n";
	print Redirect_Config "## View the changelog or README files for more information.\n";
	print Redirect_Config "#########################################################################\n";
	print Redirect_Config "\n\n";

	print Redirect_Config "### This file is for proxy redirect entries ###\n\n";


	my $Record_Query = $DB_Reverse_Proxy->prepare("SELECT `id`, `server_name`, `port`, `redirect_source`, `redirect_destination`, 
	`transfer_log`, `error_log`, `last_modified`, `modified_by`
	FROM `redirect`
	WHERE `active` = '1'
	ORDER BY `server_name` ASC");
	$Record_Query->execute();

	while ( my @Proxy_Entry = $Record_Query->fetchrow_array() )
	{
		my $ID = $Proxy_Entry[0];
		my $Server_Name = $Proxy_Entry[1];
		my $Port = $Proxy_Entry[2];
		my $Source = $Proxy_Entry[3];
		my $Destination = $Proxy_Entry[4];
		my $Transfer_Log = $Proxy_Entry[5];
		my $Error_Log = $Proxy_Entry[6];
		my $Last_Modified = $Proxy_Entry[7];
		my $Modified_By = $Proxy_Entry[8];

		if (!$Transfer_Log) {$Transfer_Log = $Default_Transfer_Log}
		if (!$Error_Log) {$Error_Log = $Default_Error_Log}

		my $ServerAliases;
		my @ServerAliases = split(',', $Server_Name);
		$Server_Name = shift @ServerAliases;
		foreach my $Alias (@ServerAliases) {
			$ServerAliases = $ServerAliases . "\n    ServerAlias			$Alias";
		}
		$Server_Name = "ServerName			$Server_Name";
		my $Server_Names = $Server_Name . $ServerAliases;

		print Redirect_Config <<RP_EOF;
## Redirect ID $ID, last modified $Last_Modified by $Modified_By
<VirtualHost *:$Port>
    $Server_Names
    Redirect			$Source	$Destination
    TransferLog			$Transfer_Log
    ErrorLog			$Error_Log
</VirtualHost>

RP_EOF
	}

print Redirect_Config "\n";
close Redirect_Config;

} # sub write_redirect

