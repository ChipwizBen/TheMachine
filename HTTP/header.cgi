#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);

use POSIX qw(strftime);
use HTML::Table;

my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Name = System_Name();
my $System_Short_Name = System_Short_Name();
my ($Version, $Latest_Version, $URL, $Notification) = Version('Version_Check');
my $Version_Display;

if ($Version && $Latest_Version && $Version ne $Latest_Version) {
	$Version_Display = " | <span style='color: #FC44FF'>New version available: $Latest_Version </span>";
}
	if ($Version) {$Version = " version <span style=color: #00FF00;'>$Version</span>"};

if ($Notification) {$Notification = " | <span style='color: #FF8A00'>Notification: $Notification </span>"}

my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();
my $Server_Hostname = Server_Hostname();

my $User_Name = $Session->param("User_Name");
my $User_Admin = $Session->param("User_Admin");

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

if (!$User_Admin) {
	undef $Latest_Version;
	undef $URL;
	undef $Notification;
	undef $Version_Display;
}

my $Message_Green = $Session->param("Message_Green");
my $Message_Orange = $Session->param("Message_Orange");
my $Message_Red = $Session->param("Message_Red");

&access_post;
&html_header;
&reset_signals;

sub access_post {

	$DB_Connection->do("UPDATE `credentials` SET `last_active` = NOW() WHERE `username` = '$User_Name'");
	
	my $Access_Time = strftime "%Y-%m-%d %H:%M:%S", localtime;
	my $HTTPS=$ENV{HTTPS};
		if (!$HTTPS) {$HTTPS='off';}
	
	
	$DB_Connection->do("INSERT INTO `access_log` (
		`id`,
		`ip`,
		`hostname`,
		`user_agent`,
		`script`,
		`referer`,
		`query`,
		`request_method`,
		`https`,
		`server_name`,
		`server_port`,
		`username`,
		`time`
	)
	VALUES (
		NULL,
		'$ENV{REMOTE_ADDR}',
		'$ENV{REMOTE_HOST}',
		'$ENV{HTTP_USER_AGENT}',
		'$ENV{SCRIPT_NAME}',
		'$ENV{HTTP_REFERER}',
		'$ENV{QUERY_STRING}',
		'$ENV{REQUEST_METHOD}',
		'$HTTPS',
		'$ENV{SERVER_NAME}',
		'$ENV{SERVER_PORT}',
		'$User_Name',
		'$Access_Time'
	)");

} # sub access_post

sub html_header {

my $CSS_Config;
if (-f $CSS_Config) {$CSS_Config = 'format.css';} else {$CSS_Config = '../format.css';}

print $CGI->header(-cookie=>$Cookie, -charset=>'utf-8');


print <<ENDHTML;
<!DOCTYPE html>
<head>
	<title>$System_Name</title>
	<link rel="stylesheet" type="text/css" href="$CSS_Config" media="screen" title ="$System_Name CSS"/>
	<!--[if IE]>
		<META HTTP-EQUIV=REFRESH CONTENT="0; URL=http://getfirefox.com">
	<![endif]-->
	<link rel="icon" href="/Resources/Images/cog-animation-small.gif">
</head>
<body>
	<!-- Strip/Buttons/White BKG -->
<div id="strip">

	<div id="loginlink">

		<div id="loginlinkleft">
			${System_Short_Name}${Version} on <span style="color: #00FF00;">$Server_Hostname</span> | Welcome <a href="account.cgi">$User_Name</a> <span id="logoutlink"><a href="/logout.cgi">[ Logout ]</a></span>${Version_Display}${Notification}
		</div> <!-- loginlinkleft -->

			<form action='/search.cgi' method='post' >
				<input name="Search" type="search" results="5" placeholder="Search">
			</form>

	</div> <!-- loginlink -->

	<div id="strip-image"></div>

	<div id="buttons">
		<ul id="navigation">
			<li><a href="/index.cgi"><span>Home</span></a>
				<ul>
					<li><a href="/account.cgi">My Account</a></li>
					<li><a href="/#">Management <b style="float:right;">></b></a>
						<ul>
							<li><a href="/account-management.cgi">Account Management</a></li>
							<li><a href="/configuration.cgi">Configuration</a>
							<li><a href="/system-status.cgi">System Status</a></li>
							<li><a href="/access-log.cgi">Access Log</a></li>
							<li><a href="/audit-log.cgi">Audit Log</a></li>
						</ul>
					</li>
					<li><a href="/changelog.cgi">System Changelog</a></li>
					<li><a href="/Resources/The_Machine_Manual.pdf">System Manual</a></li>
				</ul>
			</li>
			<li><a href="/#"><span>Hosts &amp; Services</span></a>
				<ul>
					<li><a href="/IP/host-types.cgi">Host Types</a></li>
					<li><a href="/IP/host-groups.cgi">Host Groups</a></li>
					<li><a href="/IP/hosts.cgi">Hosts</a></li>
					<li><a href="/IP/services.cgi">Services</a></li>
				</ul>
			</li>
			<li><a href="/#"><span>IP</span></a>
				<ul>
					<li><a href="/IP/ipv4-blocks.cgi">IPv4 Blocks</a></li>
					<li><a href="/IP/ipv6-blocks.cgi">IPv6 Blocks</a></li>
					<li><a href="/IP/ipv4-assignments.cgi">IPv4 Assignments</a></li>
					<li><a href="/IP/ipv6-assignments.cgi">IPv6 Assignments</a></li>
				</ul>
			</li>

			<li><a href="/#"><span>Icinga2 (beta)</span></a>
				<ul>
					<li><a href="/#">Groups <b style="float:right;">></b></a>
						<ul>
							<li><a href="/Icinga2/icinga2-host-groups.cgi">Host Groups</a></li>
							<li><a href="/Icinga2/icinga2-service-groups.cgi">Service Groups</a></li>
							<li><a href="/Icinga2/icinga2-contact-groups.cgi">Contact Groups</a></li>
						</ul>
					</li>
					<li><a href="/Icinga2/icinga2-hosts.cgi">Hosts</a></li>
					<li><a href="/Icinga2/icinga2-host-templates.cgi">Host Templates</a></li>
					<li><a href="/Icinga2/icinga2-services.cgi">Services</a></li>
					<li><a href="/Icinga2/icinga2-service-templates.cgi">Service Templates</a></li>
					<li><a href="/Icinga2/icinga2-commands.cgi">Commands</a></li>
					<li><a href="/Icinga2/icinga2-contacts.cgi">Contacts</a></li>
					<li><a href="/Icinga2/icinga2-time-periods.cgi">Time Periods</a></li>
				</ul>
			</li>

			<li><a href="/#"><span>D-Shell</span></a>
				<ul>
					<li><a href="/D-Shell/command-sets.cgi">Command Sets</a></li>
					<li><a href="/D-Shell/jobs.cgi">Jobs</a></li>
				</ul>
			</li>
			<li><a href="/#"><span>DNS</span></a>
				<ul>
					<li><a href="/DNS/domains.cgi">Domains</a></li>
					<li><a href="/DNS/zone-records.cgi">Zone Records</a></li>
				</ul>
			</li>
			<li><a href="/#"><span>Reverse Proxy</span></a>
				<ul>
					<li><a href="/ReverseProxy/reverse-proxy.cgi">Reverse Proxy</a></li>
					<li><a href="/ReverseProxy/redirects.cgi">Redirects</a></li>
				</ul>
			</li>
			<li><a href="/#"><span>Sudoers</span></a>
				<ul>
					<li><a href="/#">Groups <b style="float:right;">></b></a>
						<ul>
							<li><a href="/IP/host-groups.cgi">Global Host Groups</a></li>
							<li><a href="/DSMS/sudoers-user-groups.cgi">Sudo User Groups</a></li>
							<li><a href="/DSMS/sudoers-command-groups.cgi">Sudo Command Groups</a></li>
						</ul>
					</li>
					<li><a href="/DSMS/sudoers-hosts.cgi">Sudo Hosts</a></li>
					<li><a href="/DSMS/sudoers-users.cgi">Sudo Users</a></li>
					<li><a href="/DSMS/sudoers-commands.cgi">Sudo Commands</a></li>
					<li><a href="/DSMS/sudoers-rules.cgi">Sudo Rules</a></li>
					<li><a href="/DSMS/distribution-status.cgi">Distribution Status</a></li>
				</ul>
			</li>
		</ul>
	</div> <!-- Buttons -->
<br/>

<div id ="tbmessagegreen">
	$Message_Green
</div> <!-- tbmessagegreen -->

<div id ="tbmessageorange">
	$Message_Orange
</div> <!-- tbmessageorange -->

<div id ="tbmessagered">
	$Message_Red
</div> <!-- tbmessagered -->

ENDHTML

} #sub html_header

sub reset_signals {

	my $Message_Green = undef;
		$Session->param('Message_Green', $Message_Green);
	my $Message_Orange = undef;
		$Session->param('Message_Orange', $Message_Orange);
	my $Message_Red = undef;
		$Session->param('Message_Red', $Message_Red);
	$Session->clear(["Message_Green", "Message_Orange", "Message_Red"]);
	$Session->flush();

} # sub reset_signals

1;