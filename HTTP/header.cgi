#!/usr/bin/perl

use strict;
use POSIX qw(strftime);

require 'common.pl';
my $System_Name = System_Name();
my $System_Short_Name = System_Short_Name();
my $Version = Version();
my $DB_Management = DB_Management();
my ($CGI, $Session, $Cookie) = CGI();
my $Server_Hostname = Server_Hostname();

my $Username = $Session->param("User_Name"); #Accessing User_Name session var
my $User_Admin = $Session->param("User_Admin"); #Accessing User_Admin session var

if (!$Username) {
	print "Location: logout.cgi\n\n";
	exit(0);
}

my $Message_Green = $Session->param("Message_Green");
my $Message_Orange = $Session->param("Message_Orange");
my $Message_Red = $Session->param("Message_Red");

&access_post;
&html_header;
&reset_variables;

sub access_post {

	$DB_Management->do("UPDATE `credentials` SET `last_active` = NOW() WHERE `username` = '$Username'");
	
	my $Access_Time = strftime "%Y-%m-%d %H:%M:%S", localtime;
	my $HTTPS=$ENV{HTTPS};
		if (!$HTTPS) {$HTTPS='off';}
	
	
	$DB_Management->do("INSERT INTO `access_log` (
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
		'$Username',
		'$Access_Time'
	)");

} # sub access_post

sub html_header {

print $CGI->header(-cookie=>$Cookie);

print <<ENDHTML;
<!DOCTYPE html>
<html>
<head>
	<title>$System_Name</title>
	<link rel="stylesheet" type="text/css" href="format.css" media= "screen" title ="$System_Name CSS"/>
	<!--[if IE]>
		<META HTTP-EQUIV=REFRESH CONTENT="0; URL=http://getfirefox.com">
	<![endif]-->
</head>
<body>
	<!-- Strip/Buttons/White BKG -->
<div id="strip">

	<div id="loginlink">

		<div id="loginlinkleft">
			$System_Short_Name version <span style="color: #00FF00;">$Version</span> on <span style="color: #00FF00;">$Server_Hostname</span> | Welcome <a href="password-change.cgi">$Username</a> <span id="logoutlink"><a href="logout.cgi">[ Logout ]</a></span>
		</div> <!-- loginlinkleft -->

			<form action='search.cgi' method='post' >
				<input name="Search" type="search" results="5" placeholder="Search">
			</form>

	</div> <!-- loginlink -->

	<div id="strip-image"></div>

	<div id="buttons">
		<ul id="navigation">
			<li><a href="index.cgi"><span>&nbsp; Home</span></a>
				<ul>
					<li><a href="password-change.cgi">Change Password</a></li>
					<li><a href="#">Management <b style="float:right;">></b></a>
						<ul>
							<li><a href="account-management.cgi">Account Management</a></li>
							<li><a href="distribution-status.cgi">Distribution Status</a></li>
							<li><a href="system-status.cgi">System Status</a></li>
							<li><a href="access-log.cgi">Access Log</a></li>
							<li><a href="audit-log.cgi">Audit Log</a></li>
						</ul>
					</li>
					<li><a href="changelog.cgi">System Changelog</a></li>
					<li><a href="resources/Sudoers_Management_System_Manual.pdf">System Manual</a></li>
				</ul>
			</li>
			<li><a href="#"><span>&nbsp; IP</span></a>
				<ul>
					<li><a href="IP/ipv4-allocation.cgi">IPv4 Allocation</a></li>
					<li><a href="IP/ipv6-allocation.cgi">#IPv6 Allocation</a></li>
					<li><a href="IP/ip-allocation-log.cgi">IPv4 Allocation</a></li>
				</ul>
			</li>
			<li><a href="#"><span>&nbsp; Icinga</span></a>
				<ul>
					<li><a href="#"><span>&nbsp; Icinga</span></a>
				</ul>
			</li>
			<li><a href="#"><span>&nbsp; BIND</span></a>
				<ul>
					<li><a href="#"><span>&nbsp; BIND</span></a>
				</ul>
			</li>
			<li><a href="#"><span>&nbsp; DSMS</span></a>
				<ul>
					<li><a href="#"><span>&nbsp; Groups</span></a>
						<ul>
							<li><a href="DSMS/sudoers-host-groups.cgi">Host Groups</a></li>
							<li><a href="DSMS/sudoers-user-groups.cgi">User Groups</a></li>
							<li><a href="DSMS/sudoers-command-groups.cgi">Command Groups</a></li>
						</ul>
					</li>
					<li><a href="DSMS/sudoers-hosts.cgi"><span>&nbsp; Hosts</span></a>
		
					</li>
					<li><a href="DSMS/sudoers-users.cgi"><span>&nbsp; Sudo Users</span></a>
					
					</li>
					<li><a href="DSMS/sudoers-commands.cgi"><span>&nbsp; Commands</span></a>
					
					</li>
					<li><a href="DSMS/sudoers-rules.cgi"><span>&nbsp; Rules</span></a>
		
					</li>
				</ul>
			</li>
		</ul>
	</div> <!-- buttons -->
<br/>

<div id="body">

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

} #sub html_header end

sub reset_variables {

	$Message_Green = undef;
		$Session->param('Message_Green', $Message_Green);
	$Message_Orange = undef;
		$Session->param('Message_Orange', $Message_Orange);
	$Message_Red = undef;
		$Session->param('Message_Red', $Message_Red);

	$Session->clear(["Message_Green", "Message_Orange", "Message_Red"]);

}

1;