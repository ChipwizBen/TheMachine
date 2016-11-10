#!/usr/bin/perl

use strict;
use Digest::SHA qw(sha512_hex);
use MIME::Lite;

my $Common_Config;
if (-f 'common.pl') {$Common_Config = 'common.pl';} else {$Common_Config = '../common.pl';}
require $Common_Config;

my $System_Name = System_Name();
my $DB_Connection = DB_Connection();
my ($CGI, $Session, $Cookie) = CGI();
my $LDAP_Check = LDAP_Login('Status_Check');
my $Recovery_Email_Address = Recovery_Email_Address();

my $Referer = $Session->param("Referer");

if ( $ENV{HTTP_REFERER} !~ m/.login./ && $ENV{HTTP_REFERER} !~ m/.search./ ) {
	$Referer = $ENV{HTTP_REFERER};
	$Session->param('Referer', $Referer);
	$Session->flush();
}

my $User_Name_Form = $CGI->param("Username_Form");
my $User_Password_Form = $CGI->param("Password_Form");

my $Login_Message;

if ($User_Name_Form && $LDAP_Check !~ /on/i) {
	&login_user;
}
elsif ($User_Name_Form && $LDAP_Check =~ /on/i) {
	&ldap_login;
}
&html_output;
exit(0);

sub ldap_login {

	my $LDAP_Login = LDAP_Login($User_Name_Form, $User_Password_Form);

	if ($LDAP_Login =~ /^Success/) {

		my @LDAP_Details = split(/\,/, $LDAP_Login);
			my $LDAP_User_Name = $LDAP_Details[1];
			my $LDAP_Email = $LDAP_Details[2];

		$Session->param('User_Name', $LDAP_User_Name);
		$Session->flush();

		my $Details_Update = $DB_Connection->prepare("INSERT INTO `credentials` (
			`username`,
			`email`,
			`last_login`,
			`last_modified`,
			`modified_by`
		)
		VALUES (
			?, ?,
			NOW(),
			NOW(),
			'LDAP'
		)
		ON DUPLICATE KEY UPDATE
    		`username` = ?,
    		`email` = ?,
    		`last_login` = NOW(),
    		`lockout_counter` = 0");
    	$Details_Update->execute($LDAP_User_Name, $LDAP_Email, $LDAP_User_Name, $LDAP_Email);

		my $Permissions_Query = $DB_Connection->prepare("SELECT `id`, `admin`, `ip_admin`, `icinga_admin`, `dshell_admin`, `dns_admin`, `reverse_proxy_admin`, `dsms_admin`, `approver`, `requires_approval`, `lockout`
		FROM `credentials`
		WHERE `username` = ?");
		$Permissions_Query->execute($LDAP_User_Name);

		my $User_Admin;
		while ( my @DB_Query = $Permissions_Query->fetchrow_array( ) )
		{
			my $DB_User_ID = $DB_Query[0];
			my $DB_Admin = $DB_Query[1];
			my $DB_IP_Admin = $DB_Query[2];
			my $DB_Icinga_Admin = $DB_Query[3];
			my $DB_DShell_Admin = $DB_Query[4];
			my $DB_DNS_Admin = $DB_Query[5];
			my $DB_Reverse_Proxy_Admin = $DB_Query[6];
			my $DB_DSMS_Admin = $DB_Query[7];
			my $DB_Approver = $DB_Query[8];
			my $DB_Requires_Approval = $DB_Query[9];
			my $DB_Lockout = $DB_Query[10];

			if ($DB_Lockout == 1) {
				$Login_Message = "Your account is locked out.<br/>Please contact your administrator.";
				&html_output;
				exit(0);
			}
			$Session->param('User_ID', $DB_User_ID);
			$Session->param('User_Admin', $DB_Admin);
			$Session->param('User_IP_Admin', $DB_Admin);
			$Session->param('User_Icinga_Admin', $DB_Icinga_Admin);
			$Session->param('User_DShell_Admin', $DB_DShell_Admin);
			$Session->param('User_DNS_Admin', $DB_DNS_Admin);
			$Session->param('User_Reverse_Proxy_Admin', $DB_Reverse_Proxy_Admin);
			$Session->param('User_DSMS_Admin', $DB_DSMS_Admin);
			$Session->param('User_Approver', $DB_Approver);
			$Session->param('User_Requires_Approval', $DB_Requires_Approval);
			$Session->flush();
	    }
	    if ($Referer ne '' && $Referer !~ /logout/) {
			print "Location: $Referer\n\n";
			exit(0);
		}
		else {
			print "Location: /index.cgi\n\n";
			exit(0);
		}
	}
	else {
		$Login_Message = "Login Failed";
	}
}

sub login_user {
	my $Login_DB_Query = $DB_Connection->prepare("SELECT `id`, `password`, `salt`, `email`, `admin`, `ip_admin`, `icinga_admin`, 
	`dshell_admin`, `dns_admin`, `reverse_proxy_admin`, `dsms_admin`, `approver`, `requires_approval`, `lockout`
	FROM `credentials`
	WHERE `username` = ?");
	$Login_DB_Query->execute($User_Name_Form);

	my $User_Admin;
	while ( my @DB_Query = $Login_DB_Query->fetchrow_array( ) )
	{
		my $DB_User_ID = $DB_Query[0];
		my $DB_Password = $DB_Query[1];
		my $DB_Salt = $DB_Query[2];
		my $DB_Email = $DB_Query[3];
		my $DB_Admin = $DB_Query[4];
		my $DB_IP_Admin = $DB_Query[5];
		my $DB_Icinga_Admin = $DB_Query[6];
		my $DB_DShell_Admin = $DB_Query[7];
		my $DB_DNS_Admin = $DB_Query[8];
		my $DB_Reverse_Proxy_Admin = $DB_Query[9];
		my $DB_DSMS_Admin = $DB_Query[10];
		my $DB_Approver = $DB_Query[11];
		my $DB_Requires_Approval = $DB_Query[12];
		my $DB_Lockout = $DB_Query[13];

		$User_Password_Form = $User_Password_Form . $DB_Salt;
			$User_Password_Form = sha512_hex($User_Password_Form);

		my $Email_Password;
		if ($DB_Lockout == 1) {
			&email_user_password_reset(12);
			$Login_Message = "Your account is locked out.<br/>Please check your email for instructions.";
		}
		elsif ("$DB_Password" ne "$User_Password_Form")
		{

			my $Lockout_Counter_Query = $DB_Connection->prepare("SELECT `lockout_counter`
				FROM `credentials`
				WHERE `username` = ?");

			$Lockout_Counter_Query->execute($User_Name_Form);
			
			while ( (my $Lockout_Counter) = my @Lockout_Counter_Query = $Lockout_Counter_Query->fetchrow_array() )
			{
				$Lockout_Counter++;
				my $Lockout_Increase = $DB_Connection->prepare("UPDATE `credentials`
					SET `lockout_counter` = '$Lockout_Counter'
					WHERE `username` = ?");

				$Lockout_Increase->execute($User_Name_Form);

					if ($Lockout_Counter >= 5) {
						my $Lockout_User = $DB_Connection->prepare("UPDATE `credentials`
							SET `lockout` = '1'
							WHERE `username` = ?");
						$Lockout_User->execute($User_Name_Form);
					}

					$Lockout_Counter = 5 - $Lockout_Counter;
					$Login_Message = "You have entered an incorrect password.<br/>Attempts remaining: $Lockout_Counter";
			}
		}
		elsif ("$DB_Password" eq "$User_Password_Form") {

			$Session->param('User_ID', $DB_User_ID);
			$Session->param('User_Name', $User_Name_Form);
			$Session->param('User_Email', $DB_Email);
			$Session->param('User_Admin', $DB_Admin);
			$Session->param('User_IP_Admin', $DB_Admin);
			$Session->param('User_Icinga_Admin', $DB_Icinga_Admin);
			$Session->param('User_DShell_Admin', $DB_DShell_Admin);
			$Session->param('User_DNS_Admin', $DB_DNS_Admin);
			$Session->param('User_Reverse_Proxy_Admin', $DB_Reverse_Proxy_Admin);
			$Session->param('User_DSMS_Admin', $DB_DSMS_Admin);
			$Session->param('User_Approver', $DB_Approver);
			$Session->param('User_Requires_Approval', $DB_Requires_Approval);
			$Session->flush();

			my $Login_User = $DB_Connection->prepare("UPDATE `credentials`
			SET `lockout_counter` = '0',
			`last_login` = NOW()
			WHERE `username` = ?");
			
			$Login_User->execute($User_Name_Form);

			if ($Referer ne '' && $Referer !~ /logout/) {
				print "Location: $Referer\n\n";
				exit(0);
			}
			else {
				print "Location: /index.cgi\n\n";
				exit(0);
			}

		}
	}

} #sub login_user

sub email_user_password_reset {

	my $Password_Length = $_[0];
	my $Random_Alpha_Numeric_Password = Random_Alpha_Numeric_Password($Password_Length);
	my $Server_Hostname = Server_Hostname();

	## Grabbing administration details
	my $Administrator_Email_Address_Query = $DB_Connection->prepare("SELECT `username`, `email`
	FROM `credentials`
	WHERE `admin` = '1'
	AND `lockout` = '0'");
	$Administrator_Email_Address_Query->execute();

	my $Administrators;
	while ( my ($Administrator_Username, $Administrator_Email) = my @Administrator_Email_Address_Query = $Administrator_Email_Address_Query->fetchrow_array() )
	{
		$Administrators = "$Administrator_Username (<a href='mailto:$Administrator_Email>$Administrator_Email</a>)<br />";
	}
	## / Grabbing administration details

	my $User_Email_Address_Query = $DB_Connection->prepare("SELECT `email` FROM `credentials`
	WHERE `username` = ?");
	$User_Email_Address_Query->execute($User_Name_Form);

	while ( my $DB_Email = my @User_Email_Address_Query = $User_Email_Address_Query->fetchrow_array() )
	{
	
			my $Email_Body="Dear $User_Name_Form,<br/>
<br/>
Somebody has tried to access your account with an incorrect password. Your account is now locked. Below are the client's details: <br/>
<br/>
Hostname: $ENV{REMOTE_HOST}<br/>
IP: $ENV{REMOTE_ADDR}<br/>
Useragent: $ENV{HTTP_USER_AGENT}<br/>
<br/>
To unlock your account, please visit <a href='https://$Server_Hostname/lockout.cgi?Username=$User_Name_Form'>https://$Server_Hostname/lockout.cgi?User_Name=$User_Name_Form</a><br/>
<br/>
You will need to know the below unlock code, which has been randomly generated:<br/>
<br/>
Unlock code: $Random_Alpha_Numeric_Password<br/>
<br/>
If you are still having problems logging in, you should contact an administrator. Administrators are:<br/>
<br/>
$Administrators<br/>
<br/>
Regards,<br/>
$System_Name<br/>

";

			my $Send_Email = MIME::Lite->new(
			From	=> "$Recovery_Email_Address",
			To		=> "$DB_Email",
			Subject	=> "Password Reset",
			Type	=> "text/html",
			Data	=> "$Email_Body");

			$Random_Alpha_Numeric_Password = sha512_hex($Random_Alpha_Numeric_Password);
				my $Perform_Lockout_Password_Set = $DB_Connection->prepare("UPDATE `credentials`
					SET `lockout_reset` = '$Random_Alpha_Numeric_Password'
					WHERE `username` = ?");
				
				$Perform_Lockout_Password_Set->execute($User_Name_Form);

			$Send_Email->send;

	}
} # sub email_user_password_reset

sub html_output {

	my $HTTPS=$ENV{HTTPS};

	print $CGI->header(-cookie=>$Cookie);

	if (!$Login_Message && $HTTPS ne 'on') {
		$Login_Message='<span style="color:#FF0000">You are not using HTTPS!</span>';
	}

print <<ENDHTML;
<html>
<head>
	<title>$System_Name</title>
	<link rel="stylesheet" type="text/css" href="format.css" media= "screen,print" title ="$System_Name CSS"/>
	<!--[if IE]>
		<META HTTP-EQUIV=REFRESH CONTENT="0; URL=http://getfirefox.com">
	<![endif]-->
</head>

<body style="background-color: #575757;">
<div id="login">
<div id="loginform">
<h3>$System_Name</h3>
<form action='login.cgi' method='post' >
<div style="text-align: center;">

<table align = "center">
	<tr>
		<td style="text-align: right;">Username:</td>
		<td style="text-align: right;"><input type='text' name='Username_Form' size='15' maxlength='128' placeholder="Username" autofocus required></td>
	</tr>
	<tr>
		<td style="text-align: right;">Password:</td>
		<td style="text-align: right;"><input type='password' name='Password_Form' size='15' placeholder="Password" required></td>
	</tr>
</table>
$Login_Message<br />
<br />
<input type=submit name='ok' value='Login'></div>
</form>
</div> <!-- loginform -->
</div> <!-- login -->

ENDHTML

if ($Referer ne '' && $Referer !~ /logout/) {
print <<ENDHTML;
<div id ="loginreferer">
You will be redirected to $Referer after you login
</div> <!-- loginreferer -->
ENDHTML
}
print <<ENDHTML;

</div> <!-- body -->

</body>
</html>

ENDHTML

} #sub html_output end
