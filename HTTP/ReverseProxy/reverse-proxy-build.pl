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


my $Date = strftime "%Y-%m-%d", localtime;

# Safety check for other running build processes

	my $Select_Locks = $DB_Management->prepare("SELECT `reverse-proxy-build` FROM `lock`");
	$Select_Locks->execute();

	my ($Reverse_Proxy_Build_Lock, $Reverse_Proxy_Distribution_Lock) = $Select_Locks->fetchrow_array();

		if ($Reverse_Proxy_Build_Lock == 1 || $Reverse_Proxy_Distribution_Lock == 1) {
			print "Another build or distribution process is running. Exiting...\n";
			exit(1);
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

	open( Reverse_Proxy_Config, ">$Reverse_Proxy_Location/httpd.$System_Short_Name-reverse.conf" ) or die "Can't open $Reverse_Proxy_Location/httpd.$System_Short_Name-reverse.conf";

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
	`transfer_log`, `error_log`, `ssl_certificate_file`, `ssl_certificate_key_file`, `ssl_ca_certificate_file`, `last_modified`, `modified_by`
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
		my $Last_Modified = $Proxy_Entry[9];
		my $Modified_By = $Proxy_Entry[10];

		if (!$Transfer_Log) {$Transfer_Log = $Default_Transfer_Log}
		if (!$Error_Log) {$Error_Log = $Default_Error_Log}

		if ($SSL_Certificate_File && $SSL_Certificate_Key_File && $SSL_CA_Certificate_File) {
			if (!$SSL_Certificate_File) {$SSL_Certificate_File = $Default_SSL_Certificate_File}
			if (!$SSL_Certificate_Key_File) {$SSL_Certificate_Key_File = $Default_SSL_Certificate_Key_File}
			if (!$SSL_CA_Certificate_File) {$SSL_CA_Certificate_File = $Default_SSL_CA_Certificate_File}

			print Reverse_Proxy_Config <<RP_EOF;
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName              $Server_Name
    ProxyRequests           Off
    ProxyPreserveHost       On
    ProxyPass               $Source    $Destination
    ProxyPassReverse        $Source    $Destination

    SSLEngine               On
    SSLProtocol             ALL -SSLv2 -SSLv3
    SSLCipherSuite          HIGH:!SSLv2:!ADH:!aNULL:!eNULL:!NULL

    SSLCertificateFile      $SSL_Certificate_File
    SSLCertificateKeyFile   $SSL_Certificate_Key_File
    SSLCACertificateFile    $SSL_CA_Certificate_File

    TransferLog             $Transfer_Log
    ErrorLog                $Error_Log
</VirtualHost>
</IfModule>

RP_EOF
		}
		else {
			print Reverse_Proxy_Config <<RP_EOF;
<VirtualHost *:80>
    ServerName              $Server_Name
    ProxyRequests           Off
    ProxyPreserveHost       On
    ProxyPass               $Source    $Destination
    ProxyPassReverse        $Source    $Destination
    TransferLog             $Transfer_Log
    ErrorLog                $Error_Log
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

	open( Redirect_Config, ">$Proxy_Redirect_Location/httpd.$System_Short_Name-redirect.conf" ) or die "Can't open $Proxy_Redirect_Location/httpd.$System_Short_Name-redirect.conf";

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


	my $Record_Query = $DB_Reverse_Proxy->prepare("SELECT `id`, `server_name`, `redirect_source`, `redirect_destination`, 
	`transfer_log`, `error_log`, `last_modified`, `modified_by`
	FROM `redirect`
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
		my $Last_Modified = $Proxy_Entry[6];
		my $Modified_By = $Proxy_Entry[7];

		if (!$Transfer_Log) {$Transfer_Log = $Default_Transfer_Log}
		if (!$Error_Log) {$Error_Log = $Default_Error_Log}


		print Redirect_Config <<RP_EOF;
<VirtualHost *:80>
    ServerName               $Server_Name
    RedirectPermanent        $Source       $Destination
    TransferLog              $Transfer_Log
    ErrorLog                 $Error_Log
    <Location /*>
        Order deny,allow
        Allow from all
    </Location>
</VirtualHost>

RP_EOF
	}

print Redirect_Config "\n";
close Redirect_Config;
	
} # sub write_redirect

