#!/usr/bin/perl

use strict;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my ($CGI, $Session, $Cookie) = CGI();

&html_footer;

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
