#!/usr/bin/perl

use strict;
use HTML::Table;

require 'common.pl';
my $DB_Sudoers = DB_Sudoers();
my ($CGI, $Session, $Cookie) = CGI();

my $User_Name = $Session->param("User_Name");

if (!$User_Name) {
	print "Location: logout.cgi\n\n";
	exit(0);
}
                 
my $Search = $CGI->param("Search");
my $Referer = $ENV{HTTP_REFERER};
	$Referer =~ s/^.*\/(.*\.cgi)/$1/i; # Removes string before filename
	$Referer =~ s/(.*\.cgi)?.*/$1/i; # Removes arguments after ?

if (($Referer eq '') || ($Referer eq 'search.cgi')) {
	$Referer="index.cgi";
}

if ($Search eq '') {
	my $Message_Red="You did not provide a search input";
	$Session->param('Message_Red', $Message_Red);
	print "Location: $Referer\n\n";
	exit(0);
}

if ($Search) {
	
	require "header.cgi";
	&html_output;
	require "$Referer";

}

sub html_output {

	my $Counter = 0;

	my $Table = new HTML::Table(
		-cols=>4,
		-align=>'center',
		-border=>0,
		-rules=>'cols',
		-evenrowclass=>'tbeven',
		-oddrowclass=>'tbodd',
		-width=>'90%',
		-spacing=>0,
		-padding=>1
	);

	$Table->addRow( "#", "Category", "Name", "Status", "View" );
	$Table->setRowClass (1, 'tbrow1');

print <<ENDHTML;

<div id="search-popup-box">
<a href="$Referer">
<div id="blockclosebutton">
</div>
</a>

<h2 style="text-align: center; font-weight: bold;">Search Results for <span style="color: #00FF00;">$Search</span></h2>
ENDHTML

### Host Groups

	my $Search_DB = $DB_Sudoers->prepare("SELECT `id`, `groupname`, `expires`, `active`
		FROM `host_groups`
		WHERE `id` LIKE ?
		OR `groupname` LIKE ?
	");
	
	$Search_DB->execute("%$Search%", "%$Search%");

while ( my @Search = $Search_DB->fetchrow_array() ) {
	my $ID = $Search[0];
	my $Name = $Search[1];
		$Name =~ s/(.*)($Search)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Expires = $Search[2];
	my $Active = $Search[3];

	my $Expires_Epoch;
	my $Today_Epoch = time;
	if ($Expires ne '0000-00-00' && $Expires_Epoch < $Today_Epoch) {
		$Expires = '<br /><span style=\'color: #BDBDBD\'>Expired</span>';
	}
	else {
		$Expires = '';
	}

	if ($Active) {$Active = "<span style='color: #00FF00'>Active</span>"} else {$Active = "Inactive"}

	$Counter++;

	$Table->addRow(
	"$Counter",
	"Host Group",
	"$Name",
	"$Active$Expires",
	"<a href='sudoers-host-groups.cgi?ID_Filter=$ID'><img src=\"resources/imgs/forward.png\" alt=\"View $Name\" ></a>"
	);
}

### User Groups

	my $Search_DB = $DB_Sudoers->prepare("SELECT `id`, `groupname`, `system_group`, `expires`, `active`
		FROM `user_groups`
		WHERE `id` LIKE ?
		OR `groupname` LIKE ?
	");
	
	$Search_DB->execute("%$Search%", "%$Search%");

while ( my @Search = $Search_DB->fetchrow_array() ) {
	my $ID = $Search[0];
	my $Name = $Search[1];
		$Name =~ s/(.*)($Search)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $System_Group = $Search[2];
	my $Expires = $Search[3];
	my $Active = $Search[4];

	my $Expires_Epoch;
	my $Today_Epoch = time;
	if ($Expires ne '0000-00-00' && $Expires_Epoch < $Today_Epoch) {
		$Expires = '<br /><span style=\'color: #BDBDBD\'>Expired</span>';
	}
	else {
		$Expires = '';
	}

	if ($System_Group) {$Name = '%' . $Name . ' [System Group]'}
	if ($Active) {$Active = "<span style='color: #00FF00'>Active</span>"} else {$Active = "Inactive"}

	$Counter++;

	$Table->addRow(
	"$Counter",
	"User Group",
	"$Name",
	"$Active$Expires",
	"<a href='sudoers-user-groups.cgi?ID_Filter=$ID'><img src=\"resources/imgs/forward.png\" alt=\"View $Name\" ></a>"
	);
}

### Command Groups

	my $Search_DB = $DB_Sudoers->prepare("SELECT `id`, `groupname`, `expires`, `active`
		FROM `command_groups`
		WHERE `id` LIKE ?
		OR `groupname` LIKE ?
	");
	
	$Search_DB->execute("%$Search%", "%$Search%");

while ( my @Search = $Search_DB->fetchrow_array() ) {
	my $ID = $Search[0];
	my $Name = $Search[1];
		$Name =~ s/(.*)($Search)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Active = $Search[2];
	my $Expires = $Search[2];
	my $Active = $Search[3];

	my $Expires_Epoch;
	my $Today_Epoch = time;
	if ($Expires ne '0000-00-00' && $Expires_Epoch < $Today_Epoch) {
		$Expires = '<br /><span style=\'color: #BDBDBD\'>Expired</span>';
	}
	else {
		$Expires = '';
	}

	if ($Active) {$Active = "<span style='color: #00FF00'>Active</span>"} else {$Active = "Inactive"}

	$Counter++;

	$Table->addRow(
	"$Counter",
	"Command Group",
	"$Name",
	"$Active$Expires",
	"<a href='sudoers-command-groups.cgi?ID_Filter=$ID'><img src=\"resources/imgs/forward.png\" alt=\"View $Name\" ></a>"
	);
}

### Hosts

	my $Search_DB = $DB_Sudoers->prepare("SELECT `id`, `hostname`, `ip`, `expires`, `active`
		FROM `hosts`
		WHERE `id` LIKE ?
		OR `hostname` LIKE ?
		OR `ip` LIKE ?
	");
	
	$Search_DB->execute("%$Search%", "%$Search%", "%$Search%");

while ( my @Search = $Search_DB->fetchrow_array() ) {
	my $ID = $Search[0];
	my $Name = $Search[1];
		$Name =~ s/(.*)($Search)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $IP = $Search[2];
		$IP =~ s/(.*)($Search)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Expires = $Search[3];
	my $Active = $Search[4];

	my $Expires_Epoch;
	my $Today_Epoch = time;
	if ($Expires ne '0000-00-00' && $Expires_Epoch < $Today_Epoch) {
		$Expires = '<br /><span style=\'color: #BDBDBD\'>Expired</span>';
	}
	else {
		$Expires = '';
	}

	if ($Active) {$Active = "<span style='color: #00FF00'>Active</span>"} else {$Active = "<span style='color: #FF0000'>Inactive</span>"}

	$Counter++;

	$Table->addRow(
	"$Counter",
	"Host",
	"$Name ($IP)",
	"$Active$Expires",
	"<a href='sudoers-hosts.cgi?ID_Filter=$ID'><img src=\"resources/imgs/forward.png\" alt=\"View $Name\" ></a>"
	);
}

### Users

	my $Search_DB = $DB_Sudoers->prepare("SELECT `id`, `username`, `expires`, `active`
		FROM `users`
		WHERE `id` LIKE ?
		OR `username` LIKE ?
	");
	
	$Search_DB->execute("%$Search%", "%$Search%");

while ( my @Search = $Search_DB->fetchrow_array() ) {
	my $ID = $Search[0];
	my $Name = $Search[1];
		$Name =~ s/(.*)($Search)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Expires = $Search[2];
	my $Active = $Search[3];

	my $Expires_Epoch;
	my $Today_Epoch = time;
	if ($Expires ne '0000-00-00' && $Expires_Epoch < $Today_Epoch) {
		$Expires = '<br /><span style=\'color: #BDBDBD\'>Expired</span>';
	}
	else {
		$Expires = '';
	}

	if ($Active) {$Active = "<span style='color: #00FF00'>Active</span>"} else {$Active = "<span style='color: #FF0000'>Inactive</span>"}

	$Counter++;

	$Table->addRow(
	"$Counter",
	"User",
	"$Name",
	"$Active$Expires",
	"<a href='sudoers-users.cgi?ID_Filter=$ID'><img src=\"resources/imgs/forward.png\" alt=\"View $Name\" ></a>"
	);
}

### Commands

	my $Search_DB = $DB_Sudoers->prepare("SELECT `id`, `command_alias`, `command`, `expires`, `active`
		FROM `commands`
		WHERE `id` LIKE ?
		OR `command_alias` LIKE ?
		OR `command` LIKE ?
	");
	
	$Search_DB->execute("%$Search%", "%$Search%", "%$Search%");

while ( my @Search = $Search_DB->fetchrow_array() ) {
	my $ID = $Search[0];
	my $Name = $Search[1];
		$Name =~ s/(.*)($Search)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Command = $Search[2];
		$Command =~ s/(.*)($Search)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Expires = $Search[3];
	my $Active = $Search[4];

	my $Expires_Epoch;
	my $Today_Epoch = time;
	if ($Expires ne '0000-00-00' && $Expires_Epoch < $Today_Epoch) {
		$Expires = '<br /><span style=\'color: #BDBDBD\'>Expired</span>';
	}
	else {
		$Expires = '';
	}

	if ($Active) {$Active = "<span style='color: #00FF00'>Active</span>"} else {$Active = "<span style='color: #FF0000'>Inactive</span>"}

	$Counter++;

	$Table->addRow(
	"$Counter",
	"Command",
	"$Name ($Command)",
	"$Active$Expires",
	"<a href='sudoers-commands.cgi?ID_Filter=$ID'><img src=\"resources/imgs/forward.png\" alt=\"View $Name\" ></a>"
	);
}

### Rules

	my $Search_DB = $DB_Sudoers->prepare("SELECT `id`, `name`, `expires`, `active`, `approved`
		FROM `rules`
		WHERE `name` LIKE ?
	");
	
	$Search_DB->execute("%$Search%");

while ( my @Search = $Search_DB->fetchrow_array() ) {
	my $ID = $Search[0];
	my $Name = $Search[1];
		$Name =~ s/(.*)($Search)(.*)/$1<span style='background-color: #B6B600'>$2<\/span>$3/gi;
	my $Expires = $Search[2];
	my $Active = $Search[3];
	my $Approved = $Search[4];

	my $Expires_Epoch;
	my $Today_Epoch = time;
	if ($Expires ne '0000-00-00' && $Expires_Epoch < $Today_Epoch) {
		$Expires = '<br /><span style=\'color: #BDBDBD\'>Expired</span>';
	}
	else {
		$Expires = '';
	}

	if ($Active) {$Active = "<span style='color: #00FF00'>Active</span>"} else {$Active = "<span style='color: #FF0000'>Inactive</span>"}
	if ($Approved) {$Approved = "<span style='color: #00FF00'>Approved</span>"} else {$Approved = "<span style='color: #FF0000'>Unapproved</span>"}

	$Counter++;

	$Table->addRow(
	"$Counter",
	"Rule",
	"$Name",
	"$Active$Expires<br/>$Approved",
	"<a href='sudoers-rules.cgi?ID_Filter=$ID'><img src=\"resources/imgs/forward.png\" alt=\"View $Name\" ></a>"
	);
}

print <<ENDHTML;

<p><span style="color: #00FF00;">$Counter</span> matching results.</p>

$Table

</div> <!-- full-width-popup-box -->
ENDHTML

} #sub html_output

