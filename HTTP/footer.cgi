#!/usr/bin/perl

use strict;

require 'common.pl';
my ($CGI, $Session, $Cookie) = CGI();

&reset_variables;
&html_footer;

sub reset_variables {

	my $Message_Green = undef;
		$Session->param('Message_Green', $Message_Green);
	my $Message_Orange = undef;
		$Session->param('Message_Orange', $Message_Orange);
	my $Message_Red = undef;
		$Session->param('Message_Red', $Message_Red);

	$Session->clear(["Message_Green", "Message_Orange", "Message_Red"]);

}

sub html_footer {

print <<ENDHTML;

	<!-- Link Footer & Name -->

<br />
<br />

<hr id="footerhr"></hr>

	<div id="footer">

	<div id="footerblocka1">
ENDHTML
#DSMS
#	<ul>
#		<li><a href="https://www.one.com/community/Distributed-Developed%20Tools%20%28DDT%29/SitePages/DSMS%20-%20Distributed%20Sudoers%20Management%20System.aspx" target="_blank">DSMS DDT Page</a></li>
#		<li><a href="https://udm-sudoers-01.alabs.nwk1.com/" target="_blank">DSMS Test System</a></li>
#	</ul>
print <<ENDHTML;
	</div> <!-- footerblocka1 -->

	<div id="footerblocka2">
	</div> <!-- footerblocka2 -->

	<div id="footerblocka3">
	</div> <!-- footerblocka3 -->

	<div id="footerblocka4">
	</div> <!-- footerblocka4 -->

	<div id="footerblocka5">
	</div> <!-- footerblocka5 -->

	</div> <!-- footer -->
</div> <!-- body -->
</div> <!-- strip -->
</body>
</html>
ENDHTML

} #sub html_footer
