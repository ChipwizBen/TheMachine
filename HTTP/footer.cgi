#!/usr/bin/perl -T

use strict;
use lib qw(/opt/TheMachine/Modules/);


my $Common_Config;
if (-f './common.pl') {$Common_Config = './common.pl';} else {$Common_Config = '../common.pl';}
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

		<div id="blocka1">
ENDHTML
#DSMS
#	<ul>
#		<li>/li>
#	</ul>
print <<ENDHTML;
		</div> <!-- blocka1 -->

		<div id="blocka2">
		</div> <!-- blocka2 -->

		<div id="blocka3">
		</div> <!-- blocka3 -->


		</div> <!-- footer -->

		</div> <!-- strip -->
	</body>
</html>
ENDHTML

} #sub html_footer

1;
