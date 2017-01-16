#!/usr/bin/perl -T

use strict;

require './common.pl';
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();

my $User_Name = $Session->param("User_Name");

my $Header = Header();
my $Footer = Footer();
my $Sudoers_Location = Sudoers_Location();
	$Sudoers_Location =~ s/\.\.\///;
	if ($Sudoers_Location =~ /^([0-9A-Za-z\-\_\/]+)$/) {$Sudoers_Location = $1;}
	else {Security_Notice('Path', $ENV{'REMOTE_ADDR'}, $0, $Sudoers_Location, $User_Name);}
my $md5sum = md5sum();
	if ($md5sum =~ /^([0-9a-z\/]+)$/) {$md5sum = $1;}
	else {Security_Notice('Path', $ENV{'REMOTE_ADDR'}, $0, $md5sum, $User_Name);}
my $cut = cut();
	if ($cut =~ /^([a-z\/]+)$/) {$cut = $1;}
	else {Security_Notice('Path', $ENV{'REMOTE_ADDR'}, $0, $cut, $User_Name);}

if (!$User_Name) {
	print "Location: /logout.cgi\n\n";
	exit(0);
}

require $Header;
&html_output;
require $Footer;

sub html_output {

my $Sudoers_Not_Found;
open(SUDOERS, $Sudoers_Location) or $Sudoers_Not_Found = "Sudoers file not found at $Sudoers_Location (or the HTTP server does not have permission to read the file).
Consider setting the sudoers file location in './common.pl' or generating a sudoers file by running 'sudoers-build.pl'.
If this is your first time running this system, first create some <a href='sudoers-hosts.cgi'>Hosts</a>, <a href='sudoers-users.cgi'>Users</a> and <a href='sudoers-commands.cgi'>Commands</a> and then attach those to <a href='sudoers-rules.cgi'>Rules</a> before running 'sudoers-build.pl'.";

my $MD5_Checksum;
my $MD5_HTML;
my $Built_HTML;
my $Sudoers_Modification_Stamp;
my $Sudoers_Modification_Time;
if (!$Sudoers_Not_Found) {
	$MD5_HTML = 'MD5:';
	$MD5_Checksum = `$md5sum $Sudoers_Location | $cut -d ' ' -f 1`;
	$Built_HTML = 'Built:';
	$Sudoers_Modification_Stamp = (stat($Sudoers_Location))[9];
	$Sudoers_Modification_Time  = localtime($Sudoers_Modification_Stamp);
}

my $Rules_Require_Approval;
my $Select_Rules = $DB_Connection->prepare("SELECT `id`
	FROM `rules`
	WHERE `active` = '1'
	AND `approved` = '0'"
);

$Select_Rules->execute();
my $Rows = $Select_Rules->rows();

if ($Rows > 0) {
	$Rules_Require_Approval ="<div style='background-color: #FF0000; width: 100%; font-size: 20px; text-align: center;'>
	You have Rules pending approval. Distribution is on hold.
	</div>
";
}
else {
	$Rules_Require_Approval = '';
}

print <<ENDHTML;

<div id='full-page-block'>
$Rules_Require_Approval
<h2 style='text-align: center;'>Currently Distributed Sudoers File</h2>
<table align="center" style='font-size: 14px;'>
	<tr>
		<td>
			$Built_HTML
		</td>
		<td style='color: #00FF00;'>
			$Sudoers_Modification_Time
		</td>
	</tr>
	<tr>
		<td>
			$MD5_HTML
		</td>
		<td style='color: #00FF00;'>
			$MD5_Checksum
		</td>
	</tr>
</table>
<br />
ENDHTML

	foreach my $Line (<SUDOERS>) {

		$Line =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
		$Line =~ s/^\s*(Defaults.*)/<span style='color: #00FF00;'>$1<\/span>/g; # Environmental highlighting
		$Line =~ s/(.*)(HOST_RULE_GROUP_\d*)(.*)/$1<span style='color: #FF8A00;'>$2<\/span>$3/g; # Host rule group highlighting
		$Line =~ s/^(USER_RULE_GROUP_\d*)(.*)/<span style='color: #FC44FF;'>$1<\/span>$2/g; # User rule group highlighting
		$Line =~ s/^(.*)(\%\w.*)(.*)/$1<span style='color: #25AAE1;'>$2<\/span>$3/g; # System User Group highlighting
		$Line =~ s/(.*)=\s\((root)\)(.*)/$1= (<span style='color: #FF0000;'>$2<\/span>)$3/g; # Run_AS root highlighting
		$Line =~ s/(.*)=\s\((ALL)\)(.*)/$1= (<span style='color: #FF0000;'>$2<\/span>)$3/g; # Run_As ALL highlighting
		$Line =~ s/(.*)=\s\((.*)\)(.*)/$1= (<span style='color: #009400;'>$2<\/span>)$3/g; # Run_As as other highlighting
		$Line =~ s/(.*)\s(PASSWD)(.*)/$1 <span style='color: #25AAE1;'>$2<\/span>$3/g; # PASSWD highlighting
		$Line =~ s/(.*)\s(NOPASSWD):(.*)/$1 <span style='color: #FF0000;'>$2<\/span>:$3/g; # NOPASSWD highlighting
		$Line =~ s/(.*):(EXEC)(.*)/$1:<span style='color: #FF0000;'>$2<\/span>$3/g; # EXEC highlighting
		$Line =~ s/(.*)(NOEXEC)(.*)/$1<span style='color: #25AAE1;'>$2<\/span>$3/g; # NOEXEC highlighting
		$Line =~ s/(.*)(COMMAND_RULE_GROUP_\d*)(.*)/$1<span style='color: #FFC600;'>$2<\/span>$3/g; # Command rule group highlighting
		$Line =~ s/(^#######\s)(.*)(\s#######$)/<span style='color: #FF0000;'>$1<\/span><span style='color: #00FFFF;'>$2<\/span><span style='color: #FF0000;'>$3<\/span>/g; # Failed rule text highlighting
		$Line =~ s/(^#######$)/<span style='color: #FF0000;'>$1<\/span>/g; # Failed rule tag highlighting
		$Line =~ s/(.*)\s=\s(ALL)(.*)/$1 = <span style='color: #FF0000;'>ALL<\/span>$3/g; # ALL highlighting
		$Line =~ s/^###\s(.*)\s###/<span style='color: #00FFFF;'>### $1 ###<\/span>/g; # Section highlighting

		if ($Line =~ m/^Host_Alias/) {
			print "<span style='color: #FF8A00;'>$Line</span>" . "<br />";
		}
		elsif ($Line =~ m/^User_Alias/) {
			print "<span style='color: #FC44FF;'>$Line</span>" . "<br />";
		}
		elsif ($Line =~ m/^Cmnd_Alias/) {
			print "<span style='color: #FFC600;'>$Line</span>" . "<br />";
		}
		else {
			print $Line . "<br />";
		}
	}

print <<ENDHTML;

$Sudoers_Not_Found

</div>

ENDHTML

} #sub html_output
