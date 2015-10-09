#!/usr/bin/perl

use strict;


&html_output;

sub html_output {

print "Content-type: text/html\n\n";

print <<ENDHTML;
<!DOCTYPE html>
<html>
<head>
	<title>Maintenance Mode</title>
	<link rel="stylesheet" type="text/css" href="format.css" media= "screen" title ="Default CSS"/>
</head>

<body style="background-color: #575757;">
<div id="login">
<div id="loginform">
<h3>Maintenance Mode</h3>
<br />
<p>Your system is currently undergoing maintenance.</p>
<p>If this message persists, contact your system administrator.</p>

</div> <!-- loginform -->
</div> <!-- login -->

</div> <!-- body -->

</body>
</html>

ENDHTML

}