#!/usr/bin/perl

use strict;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

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
#		<li>/li>
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

1;
